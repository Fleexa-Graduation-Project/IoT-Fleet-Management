# Testing Strategy

This document describes how the Fleexa IoT Fleet Management platform is tested across
its three codebases — the Go backend, the Python device simulators, and the Flutter
mobile app — and how that maps onto the CI pipeline in
`.github/workflows/ci-cd.yml`.

---

## Go backend (`backend/`)

Per `backend/README.md`, the backend's Lambda functions (`api-service`, `iot-ingestion`,
`door-watch`, `ac-timer-watch`, `db-export`) are tested with the standard Go toolchain:

```bash
cd backend
go test ./...
```

CI runs this as `go test ./... -v` in the `test-go` job, immediately followed by
`go build ./...` to confirm every binary compiles. Both must pass on every push and pull
request.

Guidelines:

* Co-locate tests with the package they exercise (`<package>/<file>_test.go`), the
  standard Go convention — this keeps `internal/alerts`, `internal/rules`,
  `internal/devices`, etc. independently testable.
* Because the ingestion pipeline and rules engine are intentionally device-agnostic (see
  `backend/README.md`), prioritize test coverage in `internal/rules` and
  `internal/devices` when adding a new device type or alert condition — that's where the
  device-specific logic actually lives.
* Prefer table-driven tests for rule evaluation (e.g. temperature thresholds, escalating
  door-open alert windows) since these are naturally a set of input/expected-output cases.
* Mock the DynamoDB client (`pkg/db`) and IoT/Firebase clients at the package boundary so
  unit tests don't require real AWS credentials or network access — that's what keeps
  `go test ./...` runnable offline in CI.

---

## Python simulators (`devices/`)

Test configuration lives in the root `pytest.ini`:

```ini
[pytest]
testpaths = devices/tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*
markers =
    integration: marks tests requiring real AWS infrastructure
```

Tests are split into two tiers under `devices/tests/`:

### Unit tests (`devices/tests/unit/`)

Run offline, with MQTT and AWS clients mocked — no real infrastructure required:

* **`test_schemas.py`** — validates that the MQTT JSON schemas
  (`backend/docs/mqtt/schemas/telemetry.schema.json`, `alert.schema.json`,
  `command.schema.json`) exist and declare the expected `required` fields
  (`device_id`, `timestamp`, `payload`, etc.). This is the contract test between the
  Python simulators and the Go ingestion Lambda — if it fails, the two sides of the
  pipeline have drifted apart.
* **`test_sensors.py`** — instantiates each sensor simulator (`TemperatureSensor`,
  `LightSensor`, `GasSensor`, `DoorSensor`) against a mocked `paho-mqtt` client and checks
  basic behavior (instantiation, required telemetry fields).
* **`test_actuators.py`** — same pattern for `DoorLocker` and `ACCurtainActuator`.
* **`test_orchestrator.py`** — currently a placeholder pending the orchestrator's core
  logic being factored out into something directly testable; treat a real orchestrator
  test as owed here once that logic exists.

Run them locally with:

```bash
pip install -r devices/requirements.txt
pytest devices/tests/unit/ -v
```

CI runs these three files individually as separate steps in the `test` job (schema, then
sensors, then actuators), plus a standalone import check that all simulator modules import
cleanly from the project root — this catches path/packaging issues (e.g. a missing
`__init__.py` or a circular import) that per-file test runs might not surface.

### Integration tests (`devices/tests/integration/`)

* **`test_aws_integration.py`** — exercises real AWS infrastructure: DynamoDB tables
  (`iot-fleet-dev-telemetry`, `iot-fleet-dev-device-state`, `iot-fleet-dev-alerts`,
  `iot-fleet-dev-commands`), the IoT Core MQTT endpoint over mTLS, the deployed Lambda
  functions, and IoT topic rules. These are marked with the `integration` pytest marker
  and are **not** run in the standard CI `test` job — they require AWS credentials and a
  live, Terraform-provisioned environment.

Run integration tests manually against a provisioned environment:

```bash
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export AWS_REGION=us-east-1
python -m pytest devices/tests/integration/ -m integration -v
```

Use these before/after infrastructure changes (Terraform modules, IoT rules, table
schemas) to confirm the deployed environment actually matches what the simulators and
backend expect — they're the closest thing this repo has to an end-to-end smoke test.

### Code coverage

`pytest-cov` is included in `requirements-dev.txt`; run
`pytest devices/tests/unit/ --cov=devices/simulators` locally when you want a coverage
report for the simulator package. There's no enforced coverage gate in CI today — treat
untested new sensor/actuator behavior as a review flag rather than a hard blocker, but
add unit coverage for anything that affects telemetry shape or alert triggering.

---

## Flutter mobile app (`mobile/`)

The mobile app's test directory (`mobile/test/`) currently only contains the default
`flutter create` scaffold smoke test (`widget_test.dart`, a counter widget test left over
from project bootstrap) — there is no app-specific test coverage yet. Follow standard
Flutter testing conventions as the suite is built out:

* **Widget tests** for screens and reusable widgets under `lib/core/widgets/` and each
  feature's presentation layer — verify a widget renders the expected content for a given
  state, and that user interaction (e.g. tapping "unlock") dispatches the expected cubit
  event.
* **Unit tests** for `Cubit`/`Bloc` classes under each feature (e.g.
  `lib/features/devices/actuators/...`, `lib/features/overview/...`) — given a sequence of
  events, assert the expected sequence of emitted states. The `bloc_test` package is the
  standard tool for this pattern with `flutter_bloc`.
* **Mock the network layer** (`lib/core/network/`) and service locator (`get_it`)
  registrations in tests rather than hitting the real API Gateway/Cognito-backed backend,
  mirroring how the Python simulator tests mock MQTT.
* Run the suite with:
  ```bash
  cd mobile
  flutter test
  ```

Mirror the `lib/` structure in `test/` (`test/features/devices/...`,
`test/core/widgets/...`) so a given source file's test is easy to locate.

---

## Summary: what runs where

| Layer | Command | Requires AWS? | Run in CI? |
| :--- | :--- | :---: | :---: |
| Go backend | `go test ./...` (in `backend/`) | No | Yes — every push/PR |
| Python unit | `pytest devices/tests/unit/ -v` | No | Yes — every push/PR |
| Python integration | `pytest devices/tests/integration/ -m integration -v` | Yes | No — manual only |
| Docker image smoke test | `docker build` + import check | No | Yes — every push/PR |
| Flutter | `flutter test` (in `mobile/`) | No | Not yet wired into CI |
| Terraform | `terraform validate` / `terraform plan` | Yes (plan) | Yes — every push/PR |

When adding a new device type, alert rule, or API endpoint, add coverage at the
appropriate layer above before opening a PR — see `docs/team/pr_guidelines.md` for what
CI will enforce.
