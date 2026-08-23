# Code Standards

This document defines the coding conventions for the three languages used in the Fleexa
IoT Fleet Management platform: **Go** (`backend/`), **Python** (`devices/`), and
**Dart/Flutter** (`mobile/`). The goal is consistency across the codebase so that any
contributor can move between services without re-learning local conventions.

---

## Go (`backend/`)

The backend is a set of independently deployable AWS Lambda functions (`api-service`,
`iot-ingestion`, `door-watch`, `ac-timer-watch`, `db-export`) that share common packages.

### Formatting & vetting

* Run `gofmt` (or `go fmt ./...`) on every file before committing. Unformatted Go code
  should never be pushed — this is non-negotiable and is checked as part of code review.
* Run `go vet ./...` before opening a PR to catch suspicious constructs (unreachable code,
  incorrect `Printf` verbs, misused locks, etc.) that compile but are almost certainly bugs.
* CI runs `go build ./...` and `go test ./... -v` for every push and PR (see
  `.github/workflows/ci-cd.yml`, job `test-go`) — a change that doesn't build or format
  cleanly will fail the pipeline.

### Package layout

Follow the existing structure under `backend/`:

* `cmd/<function-name>/` — one entrypoint package per Lambda (`api-service`,
  `iot-ingestion`, `door-watch`, `ac-timer-watch`, `db-export`). Entrypoints should stay
  thin: wire up dependencies and delegate to `internal/`.
* `internal/` — the actual domain logic, split by responsibility (`alerts`, `api/handlers`,
  `auth`, `commands`, `devices`, `ingestion`, `iot`, `notifications`, `rules`, `telemetry`,
  `users`, `validation`). Because `internal/` is enforced by the Go compiler, none of this
  code is importable outside the `backend` module — this is intentional and keeps the
  domain logic from leaking into unrelated tools.
* `models/` — shared structs (`Device`, `Telemetry`, `Alert`, `Command`, `User`) used across
  packages. Keep these free of business logic; they are data shapes only.
* `pkg/` — small, dependency-light utilities meant to be safely reusable (`db` for the
  singleton DynamoDB client, `logger` for the structured JSON logger).

When adding a new device type or rule, prefer extending `internal/rules` and
`internal/devices` rather than special-casing logic in a handler — the ingestion pipeline
is intentionally device-agnostic (see `backend/README.md`), and new device support should
stay a data/config change, not a structural one.

### Style conventions

* Package names are short, lower-case, no underscores (standard Go convention).
* Exported identifiers get doc comments starting with the identifier name
  (`// AlertStore handles...`), matching what `go doc` and `golint`-style tooling expect.
* Errors are returned, not panicked, except at true startup-time invariants (e.g. missing
  required environment variables in a Lambda's `init()`/`main()`).
* Use the structured logger in `pkg/logger` rather than `fmt.Println`/`log.Println` so log
  output stays parseable in CloudWatch.
* Keep Lambda handlers small: validate input, call into `internal/`, translate the result
  to an HTTP/MQTT response. Business logic belongs in `internal/`, not in `cmd/`.

---

## Python (`devices/`)

The Python code simulates edge devices (sensors and actuators) that talk to AWS IoT Core
over MQTT with mTLS.

### Tooling

The dev toolchain is pinned in `requirements-dev.txt`:

* **flake8** — linting for style violations and obvious errors (unused imports, undefined
  names, line-length issues). Run `flake8` from the repository root before committing;
  configuration lives in the root `.flake8`.
* **pylint** — deeper static analysis (code smells, design issues, more aggressive checks
  than flake8). Configuration lives in the root `.pylintrc`. Treat new pylint warnings on
  code you touched as something to fix or consciously suppress with a comment explaining
  why, not silently ignore.
* **black** — the authoritative formatter. Run `black devices/` before committing so diffs
  stay limited to logical changes rather than whitespace churn. Don't hand-format Python
  code in a way that fights black's output.
* **pytest** / **pytest-cov** — see `docs/team/testing_strategy.md` for how the test suite
  itself is organized.

Recommended local workflow before opening a PR:

```bash
black devices/
flake8
pylint devices/simulators
pytest devices/tests/ -v
```

### Module layout

* `devices/simulators/base_device.py` — the shared `DeviceConfig` and base simulator
  behavior (MQTT connection, mTLS, publish loop). New device types should build on this
  rather than reimplementing connection handling.
* `devices/simulators/sensors/` — one module per sensor type (`temperature_sensor.py`,
  `light_sensor.py`, `gas_sensor.py`, `door_sensor.py`).
* `devices/simulators/actuators/` — one module per actuator type (`door_locker.py`,
  `ac_curtain_actuator.py`).
* `devices/simulators/schema_validator.py` — shared payload validation against the JSON
  schemas in `backend/docs/mqtt/schemas/`.
* `devices/tests/` — unit tests under `unit/`, AWS-dependent integration tests under
  `integration/` (see testing strategy doc).

### Style conventions

* Follow standard PEP 8 conventions as enforced by flake8/black — 4-space indentation,
  `snake_case` for functions and variables, `PascalCase` for classes.
* Type hints are encouraged for public functions/methods, especially in `base_device.py`
  and anything touching `DeviceConfig`, since that struct is shared across every simulator.
* Keep AWS/boto3 calls isolated (as in `devices/tests/integration/test_aws_integration.py`)
  so unit tests can mock MQTT/AWS clients instead of hitting real infrastructure.
* Prefer dataclasses (as used by `DeviceConfig`) for structured configuration over loose
  dicts or long positional argument lists.

---

## Dart / Flutter (`mobile/`)

The mobile app is the cross-platform client. It follows a domain-driven `core` + `features`
layout (see `mobile/README.md`).

### Tooling

* Run `flutter analyze` before committing — it enforces the effective Dart lint set and
  catches type errors, unused imports, and common Flutter anti-patterns.
* Run `dart format .` (or let your IDE format on save) to keep formatting consistent with
  standard Dart style: 2-space indentation, trailing commas in multi-line collections and
  widget trees, and `lowerCamelCase` for members.
* Prefer `const` constructors wherever a widget's inputs are compile-time constant — this
  is both an effective-Dart convention and a real performance win for a UI that renders
  frequently-updating telemetry.

### Project layout

Respect the existing separation:

* `lib/core/` — anything global and cross-feature: DI/service locator (`setup/`), the Dio
  network layer (`network/`), routing (`router/`), secure token storage (`storage/`),
  centralized error handling (`errors/`), and reusable widgets (`widgets/`). Code here must
  not depend on a specific feature.
* `lib/features/<feature>/` — self-contained feature modules (`auth`, `devices`,
  `on_boarding`, `overview`, `settings`, `splash`). Each feature owns its own screens,
  cubits, and models. Cross-feature imports should be rare and deliberate — if two features
  need to share a model or widget, consider whether it belongs in `core/` or in
  `features/devices/shared/` (as already done for device models/cubits).
* New device types belong under `lib/features/devices/sensors/` or
  `lib/features/devices/actuators/`, mirroring the simulator split in `devices/simulators/`.

### Style conventions

* State management is `flutter_bloc`/`Cubit` — emit new state objects rather than mutating
  existing ones, and keep cubits focused on one feature's state.
* Use the `AppRouter` (`go_router`) for navigation instead of ad-hoc `Navigator.push` calls,
  so routes stay declarative and testable.
* Resolve dependencies through the `ServiceLocator` (`get_it`) rather than constructing
  services (Dio clients, storage, push notification service) inline in widgets.
* Keep widgets declarative and side-effect free; trigger cubit methods from event handlers,
  not from inside `build()`.
