# Real-Time Updates

**There is no WebSocket API in this backend.** This page exists so that isn't a mystery to anyone
looking for one — real-time delivery is handled by **Firebase Cloud Messaging (FCM) push
notifications**, combined with REST polling for on-demand state, not by a persistent socket
connection.

## Why not WebSockets

The backend is intentionally serverless: every code path — `api-service`, `iot-ingestion`,
`door-watch`, `ac-timer-watch`, `db-export` — runs as a short-lived AWS Lambda function invoked by
API Gateway, AWS IoT Core, or EventBridge (see [`backend/README.md`](../../backend/README.md#architecture)).
Lambda functions don't hold open connections between invocations, so there's no natural place to
terminate a long-lived WebSocket without introducing an always-on component (e.g. API Gateway
WebSocket APIs plus a connection-tracking table) that this project doesn't run. Push notifications
sidestep the problem entirely: the mobile app doesn't need to stay connected to the backend at all
to receive an alert.

## How real-time updates actually work

1. **Device → cloud:** Simulated devices publish MQTT telemetry/alerts to AWS IoT Core over mTLS.
   IoT Core rules route each message to the `iot-ingestion` Lambda.
2. **Rule evaluation:** `iot-ingestion` (and the scheduled `door-watch` / `ac-timer-watch` Lambdas)
   evaluate the message against the rules engine in
   [`backend/internal/rules`](../../backend/internal/rules), decide whether it crosses a
   `WARNING`/`CRITICAL` threshold, and write an `Alert` record to the `Fleexa_Alerts` table.
3. **Push, not poll, for the alert itself:** When an alert fires, the rules engine
   (`internal/rules.AlertEngine.Notify`) looks up the owning user's registered FCM device tokens
   (`internal/users`) and calls `internal/notifications.Service.SendPushNotification`, which uses
   the Firebase Admin SDK's multicast send to deliver a notification directly to every phone the
   user has registered — no client request is involved, and delivery does not depend on the app
   being open.
4. **Mobile registration:** The Flutter app registers its FCM token via
   `PUT /users/preferences` (`hardware_id` + `fcm_token`), so the backend knows which device tokens
   belong to which user. Removing/rotating a token is the same call with an empty `fcm_token`.
5. **Everything else is REST polling:** Device state, telemetry history, and alert history are all
   read on demand via the REST endpoints described in [`endpoints.md`](./endpoints.md) — the
   mobile app calls these when a screen opens or on a refresh, rather than subscribing to a stream.

## See also

- [`endpoints.md`](./endpoints.md) — the REST routes used to fetch device state, telemetry, and
  alert history.
- [`../../backend/docs/api/api_spec.md`](../../backend/docs/api/api_spec.md) — section "Push
  Notifications (FCM)" for the exact notification payloads sent for gas alerts, door timeout
  escalation, and direct device alerts.
- [`../../backend/internal/notifications/service.go`](../../backend/internal/notifications/service.go)
  and [`../../backend/internal/rules`](../../backend/internal/rules) — the actual implementation.
