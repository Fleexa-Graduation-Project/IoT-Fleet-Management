<div align="center">
  <img src="../docs/assets/fleexa_letter_logo.svg" alt="Logo" width="120" height="120">
  <br></br>
  <h1 align="center">Fleexa Device Simulators</h1>

  <p align="center">
    <strong>Dockerized Python edge devices that speak to AWS IoT Core exactly like real hardware would.</strong>
    <br />
    <br />
    <a href="#about">About</a>
    ·
    <a href="#device-catalog">Device Catalog</a>
    ·
    <a href="#repository-structure">Structure</a>
    ·
    <a href="#getting-started">Getting Started</a>
    ·
    <a href="#testing">Testing</a>
  </p>
</div>

<div align="center">

[![Python](https://img.shields.io/badge/Python-3.11-3776AB.svg?style=flat-square&logo=python)](https://python.org/)
[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED.svg?style=flat-square&logo=docker&logoColor=white)](https://docs.docker.com/compose/)
[![AWS IoT Core](https://img.shields.io/badge/AWS-IoT_Core-232F3E.svg?style=flat-square&logo=amazon-aws)](https://aws.amazon.com/iot-core/)
[![paho-mqtt](https://img.shields.io/badge/paho--mqtt-2.1.0-660066.svg?style=flat-square)](https://pypi.org/project/paho-mqtt/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](../LICENSE)

</div>

---

## About

This directory contains the **edge layer** of the Fleexa platform: a set of Dockerized Python processes that stand in for physical IoT hardware. Each simulator authenticates to **AWS IoT Core** with its own X.509 client certificate over **Mutual TLS (mTLS)**, exactly as a real device would, and is restricted by an AWS IoT Policy scoped to its `ThingName`. From the cloud's perspective there is no difference between one of these containers and a physical sensor on the wire.

Rather than a single monolithic script, every device type is its own class built on a shared `BaseDevice` base (`simulators/base_device.py`) that owns the MQTT lifecycle: TLS setup, connect/reconnect with exponential backoff, staggered startup jitter, schema-validated telemetry and alert publishing, and command handling. Subclasses only implement `generate_telemetry()` and `handle_command()`.

A lightweight `orchestrator.py` at the repo root reads the container's environment variables, dynamically resolves which registered platform users this device instance should publish on behalf of (by scanning the `Users` DynamoDB table via `boto3`, falling back to the `USER_IDS` / `USER_ID` environment variables if AWS credentials aren't available), instantiates the matching device class, and runs it forever.

---

## Device Catalog

| Container | `DEVICE_TYPE` | Simulator | Behavior |
| :--- | :--- | :--- | :--- |
| **Temperature Sensor** | `temperature_sensor` | `simulators/sensors/temperature_sensor.py` | Publishes temperature, humidity, and battery readings; drifts into alert range over time. |
| **Gas Sensor** | `gas_sensor` | `simulators/sensors/gas_sensor.py` | Simulates CO2/CO/LPG levels with a random gradual-leak chance; escalates `WARNING` → `CRITICAL` gas alerts. |
| **Door Sensor** | `door_sensor` | `simulators/sensors/door_sensor.py` | Reports open/closed and locked/unlocked state; feeds the backend's door-left-open escalation rules. |
| **Light Sensor** | `light_sensor` | `simulators/sensors/light_sensor.py` | Publishes ambient lux levels correlated with time of day. |
| **Door Actuator** | `door_locker` | `simulators/actuators/door_locker.py` | Cloud-controllable lock; accepts `LOCK` / `UNLOCK` commands and republishes state immediately after acting. |
| **AC / Curtain Actuator** | `ac_curtain` (compose uses `ac-actuator`) | `simulators/actuators/ac_curtain_actuator.py` | Cloud-controllable relay for HVAC/curtain control, including timed auto-shutoff support. |

Every message — telemetry, alert, or command — is validated against the shared JSON schemas in `backend/docs/mqtt/schemas/` (via `simulators/schema_validator.py`) before it is published, so the simulators and the Go backend can never drift out of sync on wire format.

---

## Repository Structure

```text
devices/
├── certs/                          # X.509 mTLS credentials, one folder per Thing
│   ├── AmazonRootCA1.pem           # Shared Amazon Root CA
│   ├── temp-sensor-01/             # device.pem.crt, private.pem.key, public.pem.key, AmazonRootCA1.pem
│   ├── gas-sensor-01/
│   ├── door-sensor-01/
│   ├── light-sensor-01/
│   ├── door-actuator-01/
│   ├── ac-actuator-01/
│   └── ac-curtain-01/
├── simulators/
│   ├── base_device.py              # BaseDevice + DeviceConfig — MQTT lifecycle, publish/validate
│   ├── schema_validator.py         # Loads and validates against backend/docs/mqtt/schemas/*.json
│   ├── sensors/
│   │   ├── temperature_sensor.py
│   │   ├── gas_sensor.py
│   │   ├── door_sensor.py
│   │   └── light_sensor.py
│   └── actuators/
│       ├── door_locker.py
│       └── ac_curtain_actuator.py
├── tests/
│   ├── unit/                       # test_sensors.py, test_actuators.py, test_schemas.py, test_orchestrator.py
│   ├── integration/                # test_aws_integration.py — exercises real AWS resources
│   ├── conftest.py                 # Shared fixtures (mocked MQTT client, DeviceConfig, schema validator)
│   └── smoke_test.py               # Standalone post-deploy check for DynamoDB tables + IoT endpoint
├── logs/                            # Bind-mounted container log output (gitignored)
├── Dockerfile                       # python:3.11-slim image, runs orchestrator.py
├── docker-compose.yml               # One service per device + optional LocalStack profile
├── .env.example                     # Template for AWS credentials / broker overrides
├── mqtt_endpoint.txt                # Cached AWS IoT Core data-ATS endpoint for local reference
└── requirements.txt                 # paho-mqtt, jsonschema, boto3, pytest, pytest-cov, pytest-mock
```

The `orchestrator.py` entrypoint itself lives at the **repository root** (not inside `devices/`) so that its Docker build context (`context: ..` in `docker-compose.yml`) can also reach `backend/docs/mqtt/schemas/` for schema validation.

---

## How It Works

* **mTLS authentication** — `BaseDevice._setup_mqtt_client()` configures `paho-mqtt` with `tls_set()`, requiring the per-device `AmazonRootCA1.pem`, `device.pem.crt`, and `private.pem.key` mounted read-only from `certs/<device-id>/`. The MQTT `client_id` is set to the device's Thing Name because the AWS IoT Policy authorizes topics using the `${iot:Connection.Thing.ThingName}` policy variable.
* **Startup staggering** — each service in `docker-compose.yml` sets a deterministic `STARTUP_DELAY` (0s, 5s, 10s, 15s, 20s, 25s...) spacing containers roughly one connection per second, and `orchestrator.py` adds 0–2s of extra random jitter on top so that a mass restart never causes a thundering-herd reconnect burst against AWS IoT Core's connect-rate limit. `BaseDevice` additionally applies a per-device deterministic jitter (seeded from `device_id`, up to `connect_jitter_max` seconds) before its very first connect.
* **Dynamic user association** — instead of hardcoding which app user owns a simulated device, `orchestrator.py` scans the `iot-fleet_Users` DynamoDB table for all registered `user_id`s and publishes each telemetry/alert message once per resolved user (falling back to the `USER_IDS`/`USER_ID` environment variables when AWS credentials aren't configured). This lets any signed-up mobile app account see live data from the same shared simulator fleet.
* **Command handling** — each device subscribes to `devices/+/<device_id>/commands` on connect. When a valid command arrives it is dispatched to `handle_command()` and immediately followed by a fresh `generate_telemetry()` publish, so the mobile app sees the new state without waiting for the next scheduled interval.
* **Resilience** — MQTT reconnects use Paho's built-in exponential backoff (`reconnect_min_delay`/`reconnect_max_delay`), `clean_session=True` avoids replaying stale queued messages after a reconnect, and each container writes `/tmp/healthy` on successful connect for Docker's healthcheck to poll.

---

## Getting Started

### Prerequisites
* [Docker & Docker Compose](https://docs.docker.com/get-docker/)
* AWS credentials with permission to publish to AWS IoT Core and scan the `Users` DynamoDB table (provisioned by [`infra-iot-fleet/`](../infra-iot-fleet))
* [Python 3.11](https://www.python.org/downloads/) if you want to run or test simulators outside Docker

### 1. Configure environment

```bash
cd devices
cp .env.example .env
```

Edit `.env` with your AWS credentials so the simulators can dynamically resolve app users from DynamoDB:

```text
# devices/.env
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_REGION=us-east-1

# Optional overrides
# MQTT_BROKER=your-iot-core-endpoint.iot.us-east-1.amazonaws.com
# USER_IDS=uuid-1,uuid-2
```

`.env` is listed in `.gitignore` — never commit real credentials.

### 2. Build and run the fleet

From the `devices/` directory:

```bash
docker compose up --build -d
```

This builds the shared image (context is the repo root, so it can copy `backend/docs/mqtt/schemas/`) and starts one container per device: `temperature-sensor`, `gas-sensor`, `door-sensor`, `light-sensor`, `ac-curtain`, and `door-actuator`.

### 3. Watch it run

```bash
docker compose logs -f
```

### 4. Stop the fleet

```bash
docker compose down
```

> An optional `localstack` service is defined behind the `localstack` Compose profile for fully offline development (`docker compose --profile localstack up`), and a commented-out `simulator` service documents a retired boto3-based Lambda invoker that has been superseded by the real MQTT simulators above.

---

## Testing

```bash
cd devices
pip install -r requirements.txt
pytest tests/unit
```

* **`tests/unit/`** — fast, fully mocked tests for each sensor/actuator class, the schema validator, and `orchestrator.py`'s config-building logic (`conftest.py` mocks the Paho MQTT client and schema validator so no network or AWS calls are made).
* **`tests/integration/test_aws_integration.py`** — exercises real AWS resources (IoT Core / DynamoDB); requires valid AWS credentials and is not run as part of the default unit test pass.
* **`tests/smoke_test.py`** — a standalone post-deployment check confirming the expected DynamoDB tables and IoT Core Thing/endpoint exist; run manually after a Terraform apply.

---

## Security

* **No baked-in secrets** — the Dockerfile declares `certs/` as a `VOLUME` and never copies certificates into the image; they are mounted read-only at container start from the host's `devices/certs/`.
* **Least privilege per device** — each certificate is attached to an AWS IoT Policy scoped to that device's own topics via its Thing Name, so a compromised container can only act as itself.
* **Credentials stay local** — AWS credentials are passed through as environment variables or via a mounted `~/.aws` directory and are never written into the image or version control.

---

## License
Distributed under the MIT License. See [`LICENSE`](../LICENSE) for details.

<p align="right"><a href="#fleexa-device-simulators">Back to top</a></p>
