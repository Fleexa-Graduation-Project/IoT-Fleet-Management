# Example: Sending a Command to an Actuator

`POST /devices/:id/commands` is the only write path to a physical device — it publishes a command
over MQTT to AWS IoT Core, which the device (or the simulator standing in for it) is subscribed
to. See [`backend/internal/api/handlers/device_handler.go`](../../../backend/internal/api/handlers/device_handler.go)
(`SendCommand`) and [`backend/models/command.go`](../../../backend/models/command.go).

## Request

```
POST /api/v1/devices/ac-actuator-01/commands
Authorization: Bearer <cognito-access-token>
Content-Type: application/json

{
  "action": "SET_STATE",
  "parameters": {
    "power_state": "ON",
    "target_temp": 24.0,
    "mode": "COOLING"
  }
}
```

Only `action` is required; `parameters` is a free-form object whose shape depends on the action
and device type. Actions the handler recognizes for the AC actuator include `SET_STATE` /
`SET_POWER` (power on/off), `SET_TEMPERATURE` / `SET_AC_TEMP`, `SET_MODE` / `SET_AC_MODE`, and
`SET_TIMER` (auto shutoff after `duration_seconds`). Door actuators use actions such as `LOCK` /
`UNLOCK`. Any other action/parameters pair is passed through to the device as-is — the API layer
does not hard-code a fixed action list.

## What happens on the backend

1. The handler builds a `request_id` (`cmd-<unix-nano>`) and wraps the request as an MQTT envelope
   matching [`backend/docs/mqtt/schemas/command.schema.json`](../../../backend/docs/mqtt/schemas/command.schema.json):

   ```json
   {
     "request_id": "cmd-1708434000123456789",
     "action": "SET_STATE",
     "parameters": { "power_state": "ON", "target_temp": 24.0, "mode": "COOLING" }
   }
   ```

2. It publishes that payload to the device's per-user, per-device command topic:

   ```
   devices/<user_id>/ac-actuator-01/commands
   ```

3. For AC actions specifically, the handler also writes an optimistic state update straight to
   `Fleexa_Devices` (e.g. `power_state`, `last_turned_on`) so the mobile app sees the new state on
   its next `GET /devices/:id` without waiting for the device to report back over MQTT.
4. The command is recorded in `Fleexa_Commands` as a `models.Command` for history/auditing, with a
   7-day TTL (`expires_at`).
5. If the IoT Core publish itself fails, the request fails with `500` and nothing is recorded. If
   only the history write fails, the command has already been dispatched — the failure is logged
   but not surfaced to the caller.

## Response

```
202 Accepted
```

```json
{
  "message": "Command dispatched successfully",
  "request_id": "cmd-1708434000123456789"
}
```

`request_id` doubles as the `command_id` sort-key value if you later look this command up in
`Fleexa_Commands`.

## Error responses

Missing or empty `action`:

```
400 Bad Request
```
```json
{ "error": "invalid command format! action is required." }
```

IoT Core publish failed (e.g. connectivity issue, malformed topic):

```
500 Internal Server Error
```
```json
{ "error": "Failed to communicate with device" }
```

## Another example — locking a door

```
POST /api/v1/devices/door-actuator-01/commands
Authorization: Bearer <cognito-access-token>
Content-Type: application/json

{
  "action": "LOCK",
  "parameters": {}
}
```

```json
{
  "message": "Command dispatched successfully",
  "request_id": "cmd-1713386822048110000"
}
```
