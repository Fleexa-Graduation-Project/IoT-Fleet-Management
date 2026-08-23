# Docker Guide

Docker is used in Fleexa exclusively to run the **device simulator fleet** — the Python processes in [`devices/`](../../devices) that stand in for physical IoT hardware and speak to AWS IoT Core over MQTT/mTLS exactly as real devices would. There is no Docker usage for the Go backend (deployed as Lambda binaries via Terraform) or the Flutter mobile app.

## What Gets Built

[`devices/Dockerfile`](../../devices/Dockerfile) builds a single shared image used by every simulator container:

```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY devices/requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt
COPY devices/simulators/ ./devices/simulators/
COPY backend/docs/mqtt/schemas/ ./backend/docs/mqtt/schemas/
COPY orchestrator.py .
RUN mkdir -p logs
VOLUME ["/app/certs"]
CMD ["python", "-u", "orchestrator.py"]
```

Two things worth noting:
- **The build context is the repository root, not `devices/`.** `docker-compose.yml` sets `context: ..` and `dockerfile: devices/Dockerfile` so the image can also pull in `backend/docs/mqtt/schemas/` — the same JSON schemas the Go backend validates against — keeping simulators and backend from drifting on wire format.
- **Certificates are never baked into the image.** `certs/` is declared as a `VOLUME` and mounted read-only from the host at container start. This means device identity (and the ability to authenticate to AWS IoT Core) lives entirely outside the image.

## Services in `docker-compose.yml`

[`devices/docker-compose.yml`](../../devices/docker-compose.yml) defines one container per simulated device, all sharing the `device-common` anchor (build config, `iot-network` bridge network, AWS credential env vars, and JSON-file logging capped at 10 MB × 3 files):

| Service | `DEVICE_TYPE` | Publish interval | Startup delay |
| :--- | :--- | :--- | :--- |
| `temperature-sensor` | `temperature_sensor` | 30s | 0s |
| `gas-sensor` | `gas_sensor` | 60s | 5s |
| `door-sensor` | `door_sensor` | 10s | 10s |
| `light-sensor` | `light_sensor` | 60s | 15s |
| `ac-curtain` | `ac-actuator` | 30s | 20s |
| `door-actuator` | `door_locker` | 30s | 25s |

The staggered `STARTUP_DELAY` values (0s, 5s, 10s, 15s, 20s, 25s) are deliberate: they space container connections roughly one per second so the fleet doesn't exceed AWS IoT Core's connect-rate limit, and `orchestrator.py` layers 0–2s of random jitter on top to avoid a thundering-herd reconnect burst if the broker forces a mass disconnect.

An optional `localstack` service (LocalStack image, IoT/DynamoDB/Lambda/API Gateway/S3 emulated) sits behind the `localstack` Compose profile for fully offline development — it isn't started by a plain `docker compose up`. A commented-out `simulator` service documents a retired boto3-based Lambda invoker; it's intentionally disabled to avoid duplicating telemetry/alerts with the real MQTT simulators above.

## Running the Fleet

1. Copy the environment template and fill in AWS credentials (needed so simulators can dynamically resolve which app users to publish telemetry on behalf of, by scanning the `Fleexa_Users` DynamoDB table):
   ```bash
   cd devices
   cp .env.example .env
   ```
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

2. Build and start every device container:
   ```bash
   docker compose up --build -d
   ```

3. Tail the combined logs:
   ```bash
   docker compose logs -f
   ```
   Or a single device:
   ```bash
   docker compose logs -f door-sensor
   ```

4. Stop the fleet:
   ```bash
   docker compose down
   ```

### Running with LocalStack (offline)

To develop without touching real AWS resources:
```bash
docker compose --profile localstack up
```
This starts the `localstack` container (IoT, DynamoDB, Lambda, API Gateway, and S3 emulated on port 4566) alongside the simulator fleet.

## Common Gotchas

- **Missing certs.** If a container exits immediately or can't connect, confirm `devices/certs/<device-id>/` actually has `device.pem.crt` and `private.pem.key` for that device — see [`guides/troubleshooting.md`](../guides/troubleshooting.md#aws-iot-core--mtls).
- **Building from the wrong directory.** Always build/run from `devices/` (where `docker-compose.yml` lives) so the relative `context: ..` resolves to the repository root correctly.
- **Stale image after code changes.** `docker compose up --build -d` rebuilds the image before starting; a plain `docker compose up -d` will reuse a cached image and silently skip your simulator code changes.
