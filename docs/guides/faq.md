# Frequently Asked Questions

### What is Fleexa?

Fleexa is a real-time IoT fleet management platform: a cloud backend that ingests telemetry from smart devices, evaluates it against safety and automation rules, stores it, and lets end users monitor and control their devices from a mobile app. It's built as a graduation project around a realistic serverless AWS architecture — IoT Core, Lambda, API Gateway, DynamoDB, S3, and Cognito — rather than a fixed set of hardcoded sensors, so the same pipeline can support any device type.

### Why serverless instead of a traditional server (or Kubernetes)?

Three reasons, in order of how much they mattered:

1. **Operational overhead.** A small team building a demonstration fleet management system doesn't want to run, patch, or scale a cluster. AWS Lambda, API Gateway, and DynamoDB scale automatically and require no servers to manage.
2. **Cost.** Serverless services bill per request/read/write, which is a much better fit for a project with bursty, low/medium traffic (a handful of simulated devices, not a production fleet of thousands) than paying for always-on compute.
3. **Natural fit for event-driven IoT.** MQTT messages, scheduled sweeps (door-left-open checks, AC timers), and HTTP API calls are all discrete events — exactly what Lambda is designed around. There's no long-running process that needs to hold state in memory between requests.

There is no Kubernetes anywhere in this project. The backend is five independent Lambda functions (`api-service`, `iot-ingestion`, `door-watch`, `ac-timer-watch`, `db-export`), each with a single trigger and a single responsibility — see [`backend/README.md#architecture`](../../backend/README.md#architecture).

### Why simulators instead of real hardware?

The `devices/` simulators are Dockerized Python processes that authenticate to AWS IoT Core with genuine per-device X.509 certificates over mutual TLS — from the cloud's point of view, a simulator container is indistinguishable from a real sensor on the wire. Real hardware was deliberately avoided because:

- It removes a hardware dependency for every contributor — anyone can clone the repo, run `docker compose up`, and immediately generate realistic telemetry without buying sensors.
- It makes edge cases reproducible on demand (e.g. forcing a gas leak curve, a door left open for 20 minutes, or a temperature spike) in a way that's impractical to trigger reliably with physical devices.
- The backend genuinely cannot tell the difference — it validates every message against the same JSON schemas ([`backend/docs/mqtt/schemas/`](../../backend/docs/mqtt/schemas/)) regardless of what's on the other end of the MQTT connection, so the simulators exercise the real ingestion and alerting code paths, not a mocked-out version of them.

### How does device-to-user mapping work?

Devices aren't hardcoded to a single user. `orchestrator.py` (the simulator entrypoint) dynamically scans the `Fleexa_Users` DynamoDB table via `boto3` for every registered app user, and publishes each simulator's telemetry/alert messages once per resolved user — falling back to the `USER_IDS` / `USER_ID` environment variables if AWS credentials aren't available. This means any account signed up through the mobile app immediately sees live data from the same shared simulator fleet, without any manual device-registration step. On the backend side, every DynamoDB table and every MQTT topic includes the user's ID, so data is scoped per-account and one user can never read or command another's devices.

### How do alerts escalate?

Some alert types don't fire once and go quiet — they escalate the longer the underlying condition persists. The clearest example is a door left open or unlocked: the `door-watch` Lambda runs on a 1-minute EventBridge schedule, scans the `OpenDoorsIndex` GSI on `Fleexa_Devices` for anything still open, and fires a `WARNING` at 1 minute, then `CRITICAL` alerts at 2, 4, 8, and 16 minutes (doubling each time, capped at 16) — see the comment in [`backend/internal/rules/door_rules.go`](../../backend/internal/rules/door_rules.go). Doubling the interval means the user gets notified quickly the first time, but isn't spammed every minute if they genuinely can't get to the door right away. A related but separate mechanism is the `ac-timer-watch` Lambda, which isn't an alert escalation at all: it just checks every minute for an AC unit whose sleep timer expired, publishes an MQTT OFF command, clears the timer, and sends a single one-time notification that the AC turned off automatically.

### Why Go for the backend instead of Python or Node.js?

Go compiles to a single static binary with fast cold starts, which matters directly for Lambda functions that need to react to MQTT messages and API requests with low latency. It also gives the rules/alerts engine strong typing across shared domain models (`backend/models/`) used identically by all five Lambda functions.

### Why Firebase Cloud Messaging for push notifications instead of AWS SNS?

FCM integrates directly with Flutter (`firebase_messaging`) and handles both foreground and background/terminated-app delivery on Android and iOS with a single client SDK, which made it the simpler choice for the mobile team compared to wiring up SNS platform endpoints per device.

### What happens to old telemetry — is anything deleted?

`Fleexa_Telemetry` and `Fleexa_Commands` use a 7-day DynamoDB TTL for cost control — see the [Data Tiering](../../backend/README.md#data-tiering) table in `backend/README.md`. Data isn't lost, though: before it ages out of the "hot" DynamoDB tier, it's aggregated and exported into a "cold" tier of pre-aggregated JSON in the S3 data lake (7-day and 1-month windows), which is what the `period=7d` / `period=1m` telemetry chart queries actually read from.

### Can I add a new device type?

Yes — the backend is intentionally decoupled from any specific device category. Per [`backend/README.md#about`](../../backend/README.md#about), adding a new device type is "a single entry in the rules engine, nothing else in the system needs to change." On the simulator side, you'd add a new class under `devices/simulators/` implementing `generate_telemetry()` / `handle_command()` on top of `BaseDevice`, plus a matching JSON schema in `backend/docs/mqtt/schemas/`.
