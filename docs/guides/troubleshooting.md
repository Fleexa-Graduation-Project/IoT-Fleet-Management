# Troubleshooting

Common failures when working with Fleexa's infrastructure, backend, and device simulators, along with what actually causes them and how to fix them.

## AWS IoT Core / mTLS

### Simulator won't connect — TLS handshake failure or immediate disconnect

Each simulator authenticates to AWS IoT Core using its own per-device X.509 certificate mounted read-only from `devices/certs/<device-id>/` (`device.pem.crt`, `private.pem.key`, and the shared `AmazonRootCA1.pem`). If a container can't connect:

- **Certs not mounted** — confirm `devices/certs/<device-id>/` actually contains `device.pem.crt` and `private.pem.key` for that device. The Dockerfile declares `certs/` as a `VOLUME` and never bakes certificates into the image, so a missing host-side cert folder means the container has nothing to present.
- **Wrong `client_id`** — the AWS IoT Policy attached to each certificate authorizes topics using `${iot:Connection.Thing.ThingName}`. The simulator's MQTT `client_id` must exactly match the registered Thing Name, or the broker will reject the connection even with a valid certificate.
- **Certificate not ACTIVE** — a cert can exist but be deactivated or revoked in IoT Core. Check with:
  ```bash
  aws iot list-certificates --query 'certificates[?status!=`ACTIVE`]'
  ```
- **CA certificate not ACTIVE** — CI's `verify-deploy` job explicitly checks this (`aws iot list-ca-certificates`); if the registered CA is `INACTIVE`, no device certificate signed by it will be trusted, and every simulator fails to connect at once.
- **Connect-rate throttling** — AWS IoT Core rate-limits new connections. `docker-compose.yml` staggers each device's `STARTUP_DELAY` (0s, 5s, 10s...) and `orchestrator.py` adds random jitter on top specifically to avoid a thundering-herd reconnect burst; if you've added new devices or changed the compose file, make sure the stagger is still in place.

### Commands published to a device never take effect

Confirm the topic matches what the device actually subscribes to (`devices/+/<device_id>/commands`) and that the payload is unwrapped JSON (no envelope) per [`backend/docs/mqtt/topics.md`](../../backend/docs/mqtt/topics.md) — unlike telemetry/alerts, commands do not use the standard envelope.

## Terraform

### `terraform apply` fails with a state lock error

State is stored in S3 (`fleexa-s3-tfstate`) with locking via the `fleexa-dynamoDB-tflock` DynamoDB table. A stuck lock (from a killed `apply`, or a CI job that was cancelled mid-run) will block every subsequent apply with a `ConditionalCheckFailedException` / "already locked" error. Fix:
```bash
terraform force-unlock <LOCK_ID>
```
Only do this if you're sure no other apply is actually in progress.

### `terraform apply` hangs in CI with no output

This happened in practice with the `firebase_credentials_json` variable, which has no default and is `sensitive`: if the corresponding GitHub secret isn't set, Terraform silently prompts for input, which stalls forever in a non-interactive CI runner. It was fixed by giving the variable a safe default (`default = "{}"`) in `variables.tf`. If you add a new required variable, always give it a default or ensure it's threaded through as a `-var` / environment variable in the workflow — otherwise CI will hang rather than fail loudly.

### `terraform plan` shows unexpected changes to Lambda env vars or DynamoDB TTL attributes

The DynamoDB TTL attribute is named `ttl` specifically to avoid an `UpdateTimeToLive` conflict with an attribute of a different name — if you rename it in the Go struct tags without updating the Terraform table definition, expect a perpetual diff. Similarly, Lambda environment variables must be kept in sync between `infra-iot-fleet/terraform` and what the Go code in `backend/internal` actually reads via `os.Getenv` — a mismatch here shows up as either a Terraform diff on every plan or a runtime `nil`/empty-string config value.

### `terraform validate` / `fmt -check` fails in CI but not locally

Run `terraform fmt -recursive` before committing — CI's `terraform-plan` and local development can drift if modules were hand-edited without re-running `fmt`. This is enforced as a required step in `terraform-plan` before `validate` even runs.

## Firebase / Push Notifications

### Firebase app fails to initialize, or `project_id` comes back empty

The backend's `notifications.NewService` (`backend/internal/notifications/service.go`) accepts the Firebase service account either as a file path or as a raw JSON string (used when the credentials are injected via the `FIREBASE_CREDENTIALS` Lambda environment variable rather than a mounted file). This has broken in two specific, real ways:

1. **Raw newlines in the `private_key` field.** When Terraform passes the Firebase service account JSON through as an environment variable, it can unescape the `\n` sequences inside the PEM-encoded `private_key` into literal newlines, which breaks JSON parsing entirely. The fix sanitizes the string by re-escaping raw newlines back to `\n` (while being careful not to double-escape sequences that were already escaped) before parsing. If you regenerate Firebase credentials and push notifications suddenly stop working with a JSON parse error in the logs, this is the first thing to check.
2. **Missing `project_id` after parsing.** `firebase.NewApp` needs `ProjectID` set explicitly in its `Config` when credentials are supplied as raw JSON (it isn't always inferred). The service now extracts `project_id` from the parsed JSON and falls back to a hardcoded default project ID if extraction still comes up empty — treat that fallback firing as a signal your credentials JSON is malformed, not a real fix.

If you see `error initializing firebase app` in the Lambda logs, dump the raw value of `FIREBASE_CREDENTIALS` (redacting the private key) and check it's valid JSON with a non-empty `project_id` before assuming the Firebase project itself is misconfigured.

### Push notifications aren't arriving on a device

- Check `backend/internal/notifications/service.go`'s per-token error logging — it logs individual FCM send failures per token rather than failing the whole batch, so a single stale/uninstalled-app token won't block notifications to a user's other devices.
- Confirm the user's `hardware_id`-keyed FCM token map in the `Fleexa_Users` table actually has a current token for the device in question — tokens rotate and the mobile app must re-register them.
- Android 8.0+ requires a notification channel (`high_importance_channel`) to show heads-up alerts; if notifications arrive but are silent/collapsed, this is almost always a client-side channel configuration issue, not a backend one.

## Cognito Authentication (401s)

The API's auth middleware (`backend/internal/auth/middleware.go`) fetches Cognito's JWKS once at startup from:
```
https://cognito-idp.<AWS_REGION>.amazonaws.com/<COGNITO_USER_POOL_ID>/.well-known/jwks.json
```
and caches it (refreshing hourly). A `401 Unauthorized` from any protected route usually means one of:

- **`"missing authorization header"`** — the request didn't send `Authorization: Bearer <token>` at all.
- **`"unauthorized"`** — the JWT failed signature validation or parsing. Usually caused by `COGNITO_USER_POOL_ID` / `AWS_REGION` env vars pointing at the wrong pool (e.g. a stale value left over from a previous `terraform apply` that created a new pool), so the cached JWKS can't verify tokens issued by the pool the client actually authenticated against.
- **`"access token required"`** — the client sent Cognito's **ID token** instead of the **access token**. The middleware explicitly checks the `token_use` claim and rejects anything that isn't `"access"`, because the access token (not the ID token) carries the `sub` used as `user_id` downstream. This is the most common integration mistake when wiring up a new client against `/auth/signin`.
- **Expired token** — access tokens are short-lived; use `POST /auth/refresh` rather than re-parsing an old token.

If tokens were valid five minutes ago and suddenly aren't, check whether `terraform apply` recreated the Cognito user pool (pool IDs are not stable across a destroy/recreate) and whether the Lambda's `COGNITO_USER_POOL_ID` env var was updated to match.

## DynamoDB

### Throttling / `ProvisionedThroughputExceededException`

The core tables (`Fleexa_Telemetry`, `Fleexa_Alerts`, `Fleexa_Commands`, `Fleexa_Devices`) receive bursty writes — every simulator publishes on its own interval, and `iot-ingestion` fans out a write per user per message for devices with multiple associated app users. If you see throttling:

- Check whether the table is provisioned-capacity rather than on-demand in `infra-iot-fleet/terraform/modules/dynamodb`; a fixed provisioned throughput will throttle under a burst of simulator traffic (e.g. many devices starting up close together despite the `STARTUP_DELAY` stagger).
- The `door-watch` and `ac-timer-watch` Lambdas run on a 1-minute EventBridge schedule and `Scan`/`Query` the `OpenDoorsIndex` GSI — a GSI with its own separate (and easy to under-provision) capacity setting is a common throttling source that's easy to miss because the base table looks fine.
- `db-export` and the daily aggregator read a large portion of a table at once; scheduling them to run outside peak simulator activity, or switching the table to on-demand capacity, avoids contention with live ingestion traffic.

### Telemetry/alerts/commands "disappear" after 7 days

This is expected — `Fleexa_Telemetry` and `Fleexa_Commands` use a 7-day TTL (attribute named `ttl`, deliberately not `TimeToLiveSpecification`'s implicit default name, to avoid an `UpdateTimeToLive` conflict during earlier schema changes). Data older than the TTL window is only available via the S3 cold tier used for the `7d`/`1m` telemetry chart periods, not the live table.

## General

- **CI is green on `dev-branch` but a Terraform-related job never runs** — this is expected. `terraform-deploy` only runs on push to `main` or `Lambda-CI/CD-Implementation`; `dev-branch` pushes only get `terraform-plan`. See [`deployment.md`](./deployment.md).
- **Docker build succeeds locally but fails in CI** — make sure you're building with `-f devices/Dockerfile` from the **repository root** as the build context, not from inside `devices/`. The Dockerfile's `COPY backend/docs/mqtt/schemas/` step assumes that context.
