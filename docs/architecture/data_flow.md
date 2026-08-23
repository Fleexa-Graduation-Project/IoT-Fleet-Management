# Data Flow

This document traces two concrete paths through the system end to end:

1. A telemetry reading, from a simulated sensor to the mobile app's dashboard.
2. A command, from the mobile app back down to a physical/simulated actuator.

It also covers the alert path, since in practice telemetry and alerts share almost the same pipeline. All code references are to `backend/` unless noted otherwise.

---

## Topic structure

Every MQTT topic used by the system is scoped by `user_id`, matching the per-user data isolation described in [`security_model.md`](./security_model.md). The topic shape actually enforced by the code (`internal/validation/validator.go:validateTopic`) is:

```
devices/{user_id}/{device_id}/{telemetry|alerts|commands}
```

`internal/validation` rejects any inbound topic that doesn't split into exactly four segments starting with `devices`, and rejects a message whose envelope `device_id` doesn't match the `device_id` segment in the topic it was published on. `backend/docs/mqtt/topics.md` describes a simplified two-segment form (`devices/[device-id]/telemetry`) for the conceptual envelope/payload contracts — the four-segment, user-scoped form above is what is actually validated and what the IoT Policies (`devices/*/${iot:Connection.Thing.ThingName}/...`) and IoT Rules (`devices/+/+/telemetry`, `devices/+/+/alerts`) are written against.

---

## Path 1 — Telemetry: device → mobile app

**1. Publish (device → IoT Core).**
A simulator (`devices/simulators/sensors/*.py`) publishes a JSON envelope to `devices/{user_id}/{device_id}/telemetry` over mTLS:

```json
{
  "user_id": "...",
  "device_id": "temp-sensor-01",
  "timestamp": 1702588123,
  "type": "temp-sensor",
  "payload": { "temp": 21.5, "status": "OK" }
}
```

The device's IoT Policy only allows it to publish under its own `ThingName`, so it physically cannot spoof another device's topic.

**2. Route (IoT Core Rule → Lambda).**
The `telemetry_processor` IoT Topic Rule (`SELECT topic() as topic, * as payload FROM 'devices/+/+/telemetry'`) matches the topic and synchronously invokes the `iot-ingestion` Lambda (`aws_iot_topic_rule.telemetry_processor` in `infra-iot-fleet/terraform/iotrules.tf`), passing the topic and raw payload as the Lambda event.

**3. Validate (`internal/validation`).**
`ingestion.Service.HandleRequest` (`internal/ingestion/handler.go`) calls `validation.ValidateMessage`, which:
- Confirms the event carries a `topic` and a `payload` (`validateEvent`).
- Parses `devices/{user_id}/{device_id}/telemetry` and confirms the message type is `telemetry` or `alerts` (`validateTopic`).
- Decodes the payload into a `models.MQTTEnvelope{UserID, DeviceID, Timestamp, Type, Payload}`, rejecting anything over 32 KB.
- Cross-checks `envelope.DeviceID` against the topic's device segment, rejects a timestamp more than 60s in the future, and rejects an empty payload (`validateEnvelope`).
- Runs device-type-specific structural checks (`ValidatePayload`) against the rules registered per device type in `internal/devices` — this is the practical equivalent of the JSON Schemas documented in `backend/docs/mqtt/schemas/{telemetry,alert,command}.schema.json`.
- Detects and unpacks batched telemetry (an `items` array in the payload) for simulators that buffer readings before publishing.

Any validation failure is logged with a specific reason (invalid envelope / payload / topic) and the Lambda returns an error without writing anything.

**4. Persist (`internal/telemetry`, `internal/devices`).**
On success, `handleTelemetry` builds a `models.Telemetry{UserID, DeviceID, Timestamp, Type, Payload}` and:
- Writes it to the `Fleexa_Telemetry` DynamoDB table via `TelemetryStore.SaveTelemetry` (or `SaveTelemetryBatch`), keyed by a composite `user_device_id` partition key (`userID#deviceID`) and `timestamp` sort key.
- Updates the device's latest-known state in `Fleexa_Devices` via `StateStore.UpdateFromTelemetry`, so dashboards can read current state without scanning telemetry history.

**5. Evaluate rules (`internal/rules`).**
Before persisting, if the reading's `type` is `gas-sensor`, `AlertEngine.HandleGas` (`internal/rules/gas_rules.go`) inspects `alarm_on`/`status`/`gas_level` in the payload. If the reading indicates `WARNING` or `CRITICAL`, it writes a row to `Fleexa_Alerts` and calls `AlertEngine.Notify`. Door and AC timer conditions are *not* evaluated inline on telemetry — they're evaluated on a schedule by the `door-watch` and `ac-timer-watch` Lambdas (see below), which read device state rather than reacting to each message.

**6. Notify (`internal/notifications`).**
`AlertEngine.Notify` looks up the user's FCM tokens (filtered by severity) via `internal/users`, and `notifications.Service.SendPushNotification` sends a Firebase Cloud Messaging multicast push (with Android high-priority / APNs config) directly to the user's phone(s) — independent of whether the mobile app is open.

**7. Read (mobile app → REST API).**
The Flutter app calls `GET /devices/:id/telemetry` (with an optional `period=24h|7d|1m`) or `GET /devices/:id` on `api-service`. The handler resolves `user_id` from the Cognito JWT (see [`security_model.md`](./security_model.md)), and either queries `Fleexa_Telemetry`/`Fleexa_Devices` directly (hot tier, ≤24h) or reads pre-aggregated JSON from the S3 data lake (cold tier, 7d/1m) via `internal/iot/s3ProcessedData.go` — the client never needs to know which tier served the response.

### Alert-specific variant

An `alerts` message (e.g. a gas sensor publishing directly to `devices/{user_id}/{device_id}/alerts` for a critical event, matched by the `alert_processor` IoT Rule) follows the same validate step, then `handleAlert` in `internal/ingestion/handler.go`:
- Builds a `models.Alert{UserID, DeviceID, Timestamp, Type, Severity, Payload}`, generates an alert ID, and saves it to `Fleexa_Alerts` (`AlertStore.SaveAlert`).
- Calls `AlertEngine.Notify` to push to FCM.
- Updates the device's heartbeat in `Fleexa_Devices` (`StateStore.UpdateHeartbeat`).

### Scheduled evaluation (no inbound message required)

Two conditions are detected by polling device state on a 1-minute EventBridge schedule rather than reacting to a message:

- **Door left open/unlocked** (`door-watch` → `AlertEngine.CheckDoorTimeouts`, `internal/rules/door_rules.go`): scans `Fleexa_Devices` for open doors via the `OpenDoorsIndex` GSI, computes minutes since `last_unlock`/`last_change`, and fires a `WARNING` at 1 minute and a `CRITICAL` alert at 2, 4, 8, and 16 minutes (doubling, capped at 16) — each via the same `SaveAlert` + `Notify` path as telemetry-driven alerts.
- **AC sleep timer expiry** (`ac-timer-watch` → `handler` in `cmd/ac-timer-watch/main.go`): scans `Fleexa_Devices` for AC units whose `timer_end_timestamp` has passed (`StateStore.GetExpiredACTimers`), publishes an MQTT `set_power`/`OFF` command back to the device (see Path 2), and sends an informational `AlertEngine.NotifyACTimerExpired` push once the device is turned off.

---

## Path 2 — Command: mobile app → device

**1. Dispatch (mobile app → REST API).**
The Flutter app sends `POST /api/v1/devices/:id/commands` with a Cognito access token and a body like:

```json
{ "action": "UNLOCK", "parameters": {} }
```

`api-service`'s router (Gin, behind API Gateway) validates the JWT via `internal/auth` middleware, extracting `user_id` from the token's `sub` claim.

**2. Handle (`internal/api/handlers/device_handler.go: SendCommand`).**
The handler:
- Applies command-specific defaults (e.g. for `set_timer`, computes `timer_end_timestamp` from `duration_seconds`; for `set_power`/`set_state` with `power_state: "ON"`, stamps `last_turned_on`).
- Wraps the request into the MQTT command payload: `{"request_id": "cmd-<unix-nano>", "action": ..., "parameters": ...}`.
- Publishes it via `internal/iot.Publisher.Publish` to topic `devices/{user_id}/{device_id}/commands` using the IoT Data Plane `Publish` API (QoS 1).
- Optimistically updates the device's AC-related fields in `Fleexa_Devices` (`StateStore.UpdateACFields`) so the dashboard reflects the new state immediately, without waiting for the device to report back.
- Logs the command to `Fleexa_Commands` via `internal/commands` for history/audit (`GET /devices/:id/alerts`-style history, surfaced through the `DeviceHistoryIndex` GSI).

**3. Deliver (IoT Core → device).**
The device's IoT Policy grants it `iot:Subscribe`/`iot:Receive` only on `devices/*/${iot:Connection.Thing.ThingName}/commands`, so it receives exactly the commands addressed to it and nothing else. The simulator (`devices/simulators/actuators/*.py`) is subscribed to that topic and receives the raw JSON command payload — no envelope wrapper is used downstream, unlike the upstream telemetry/alert envelope.

**4. Act (device).**
The actuator simulator parses `action`/`parameters` (e.g. `LOCK`/`UNLOCK` for the door actuator, `SET_STATE` with `power`/`target_temp`/`mode` for the AC/curtain actuator) and updates its local simulated state, then resumes its normal telemetry publish cycle reflecting the new state — closing the loop back into Path 1.

### System-triggered commands

The same downstream path is used internally: `ac-timer-watch` publishes a `set_power`/`OFF` command to `devices/{user_id}/{device_id}/commands` directly via `internal/iot.Publisher`, without going through `api-service` or a user action — it is the cloud, not the mobile app, initiating the command in that case.

---

## Summary diagram

```text
Telemetry:  device --mTLS--> IoT Core --rule--> iot-ingestion Lambda
              --> validate --> rules engine --> DynamoDB (+ S3 via daily_aggregator)
              --> FCM push (on alert)
            mobile app <--REST (JWT)-- api-service Lambda <--DynamoDB / S3--

Command:    mobile app --REST (JWT)--> api-service Lambda
              --> Fleexa_Commands (audit) + optimistic Fleexa_Devices update
              --> IoT Data Plane Publish --> IoT Core --> device (mTLS)

Scheduled:  EventBridge (1 min) --> door-watch / ac-timer-watch Lambda
              --> Fleexa_Devices scan --> alert + (ac-timer-watch only) command publish
```
