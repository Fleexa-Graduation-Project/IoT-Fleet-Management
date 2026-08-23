# Local Development

How to build, run, and test each part of the Fleexa stack on your own machine.

## Go Backend

Prerequisite: [Go](https://golang.org/doc/install) >= 1.24.2, and an AWS account with DynamoDB, IoT Core, and Cognito provisioned (see [`setup/aws_setup.md`](./aws_setup.md)).

1. Download dependencies:
   ```bash
   cd backend
   go mod download
   ```

2. Set the environment variables the backend reads at startup (see [`backend/README.md#environment-variables`](../../backend/README.md#environment-variables) for where each value comes from):
   ```bash
   export STATE_TABLE=Fleexa_Devices
   export TELEMETRY_TABLE=Fleexa_Telemetry
   export ALERTS_TABLE=Fleexa_Alerts
   export COMMANDS_TABLE=Fleexa_Commands
   export USERS_TABLE=Fleexa_Users
   export BUCKET_NAME=fleexa-data-lake
   export FIREBASE_CREDENTIALS=./firebase-adminsdk.json
   export COGNITO_USER_POOL_ID=us-east-1_xxxxxxxxx
   export COGNITO_CLIENT_ID=xxxxxxxxxxxxxxxxxxxxxxxxxx
   export IOT_ENDPOINT=your-iot-endpoint.iot.us-east-1.amazonaws.com
   export AWS_REGION=us-east-1
   ```

3. Build the Lambda binaries you care about (each has its own `cmd/` entrypoint and can be built independently):
   ```bash
   go build -o bin/api ./cmd/api-service
   go build -o bin/ingestion ./cmd/iot-ingestion
   go build -o bin/door-watch ./cmd/door-watch
   go build -o bin/ac-timer-watch ./cmd/ac-timer-watch
   ```

4. Run the API service locally:
   ```bash
   ./bin/api
   ```
   `api-service` is the only one of the five Lambdas built around a plain HTTP server (a Gin router) that makes sense to run standalone this way; `iot-ingestion`, `door-watch`, and `ac-timer-watch` are event-driven (MQTT / EventBridge triggers) and are normally exercised through their Go tests rather than run directly outside Lambda.

5. Run the test suite:
   ```bash
   go test ./...
   ```
   `go build ./...` (build everything, not just the binaries above) and `go test ./... -v` are exactly what CI's `test-go` job runs on every push — see [`.github/workflows/ci-cd.yml`](../../.github/workflows/ci-cd.yml).

## Python Device Simulators

Prerequisite: [Python 3.11](https://www.python.org/downloads/).

You can run the simulators' test suite without any AWS credentials at all — the unit tests fully mock the MQTT client and schema validator.

1. From the **repository root** (imports are rooted there, e.g. `from devices.simulators.base_device import DeviceConfig`):
   ```bash
   pip install -r requirements-dev.txt
   ```
   `requirements-dev.txt` pulls in `requirements.txt` (which itself pulls in `devices/requirements.txt` for `paho-mqtt`, `jsonschema`, `boto3`, etc.) plus `pytest`, `pytest-cov`, `flake8`, `pylint`, `black`, and `responses`.

2. Run the tests. [`pytest.ini`](../../pytest.ini) at the repo root already points `testpaths` at `devices/tests`, so a bare `pytest` from the root works:
   ```bash
   pytest
   ```
   To mirror exactly what CI runs:
   ```bash
   python -m pytest devices/tests/unit/test_schemas.py -v
   python -m pytest devices/tests/unit/test_sensors.py -v
   python -m pytest devices/tests/unit/test_actuators.py -v
   ```
   Note the `integration` marker registered in `pytest.ini` — tests marked `@pytest.mark.integration` (in `devices/tests/integration/`) hit real AWS resources and are not part of the default run:
   ```bash
   pytest -m integration   # only if you have real AWS credentials configured
   ```

3. To actually run a simulator (not just test it) outside Docker, you'll need valid AWS IoT Core certificates for that device under `devices/certs/<device-id>/` and a reachable MQTT broker — this is normally easier to do through Docker Compose (see [`setup/docker_guide.md`](./docker_guide.md)) than by invoking `orchestrator.py` directly, since Compose already wires up the cert mounts and per-device environment variables.

## Flutter Mobile App

Prerequisite: [Flutter SDK](https://docs.flutter.dev/get-started/install) >= 3.0.0, and Android Studio or VS Code with the Flutter/Dart plugins, plus a physical device or emulator.

1. Install dependencies:
   ```bash
   cd mobile
   flutter pub get
   ```

2. Run the app:
   ```bash
   flutter run
   ```
   Once running, create a new account directly through the app's sign-up screen (backed by Cognito via the deployed API) and it will start showing live data from the shared simulator fleet.

3. Run the mobile test suite:
   ```bash
   flutter test
   ```
   Tests live under `mobile/test/`, mirroring the `lib/` feature structure (`core/`, `features/auth`, `features/devices`, etc. — see [`mobile/README.md`](../../mobile/README.md#deep-dive-directory-architecture)).

### Pointing the App at Your Backend

The mobile app needs the deployed API Gateway URL (`terraform output api_url` — see [`setup/aws_setup.md`](./aws_setup.md)) and matching Cognito pool/client configuration to authenticate. Update the app's network/service-locator configuration under `mobile/lib/core/network/` and `mobile/lib/core/setup/` accordingly before running against a real backend.

## Running Everything Together

A full local loop — simulators generating real telemetry, the backend processing it, and the mobile app displaying it — requires:
1. Infrastructure deployed via Terraform ([`setup/aws_setup.md`](./aws_setup.md)).
2. The backend Lambdas deployed (they run in AWS, not locally, once infrastructure is applied — see [`guides/deployment.md`](../guides/deployment.md)).
3. The simulator fleet running via Docker Compose ([`setup/docker_guide.md`](./docker_guide.md)), publishing to the real IoT Core endpoint.
4. The Flutter app running locally (`flutter run`) against the deployed API.

Only the mobile app and, optionally, `api-service` run purely "locally" in the traditional sense — the rest of the backend only really exists once deployed, since it's built around Lambda triggers (MQTT, EventBridge) that don't have a meaningful local equivalent.
