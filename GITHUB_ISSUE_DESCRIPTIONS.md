# GitHub Issue Descriptions: Simulator Components

Here are ready-to-use component descriptions you can paste directly into your GitHub Issues or Pull Requests to summarize their purpose.

---

## 📄 File: `orchestrator.py`
**Title:** Implement Fleet Orchestrator (`orchestrator.py`)

**Description:**
The `orchestrator.py` file serves as the main entry point and runtime manager for our mock IoT device fleet. It acts as a central coordinator that builds, monitors, and simultaneously runs multiple sensor and actuator simulators on top of AWS IoT Core (or LocalStack).

**Key Responsibilities:**
- **Device Registry**: Contains a centralized `DEVICE_REGISTRY` that defines the fleet. It automatically constructs configurations (`DeviceConfig`) mapping them to their corresponding AWS IoT certificates and keys.
- **Environment & Routing**: Routes traffic to AWS infrastructure or an emulated LocalStack environment based on the `USE_LOCALSTACK` environment variable.
- **Multithreaded Execution**: Leverages Python's `ThreadPoolExecutor` to execute multiple device simulation loops concurrently, staggering startup to prevent overwhelming the MQTT broker.
- **Lifecycle Management**: Graceful shutdown handling on `SIGINT`/`SIGTERM` to ensure active loops pause and MQTT clients formally disconnect via `disconnect()`.
- **Fleet Monitoring**: Provides a continuous heartbeat outputting status, type, and error counts for all simulated devices to `logs/orchestrator.log`.

---

## 📄 File: `devices/simulators/base_device.py`
**Title:** Implement Abstract Base Device Class (`base_device.py`)

**Description:**
The `base_device.py` file establishes the foundational architecture and contract for all simulated IoT hardware in the project. It handles all the boilerplate operations, allowing individual sensors to focus purely on generating data.

**Key Responsibilities:**
- **Core Data Models**: Defines the shared `DeviceConfig` dataclass and `DeviceStatus` Enum to strictly type common attributes like device IDs, broker URLs, and cert paths.
- **MQTT Connectivity**: Wraps the `paho.mqtt` client to provide built-in `connect()`, `disconnect()`, and reconnect-handling using AWS TLS (mTLS) requirements.
- **Abstraction Contract (`ABC`)**: Employs Python's `abc` module to enforce implementation of specific methods (like data generation) on child sensors and actuators.
- **Standardized Payload**: Enforces a consistent envelope structure (adding timestamps, schemas, types) making sure all data sent to backend routers is standard.
- **Schema Validation Integration**: Hooks into our JSON schema validator immediately before payload publication to catch malformed messages locally before they hit the cloud broker.

---

## 📁 Directory: `devices/simulators/sensors/*.py`
**Title:** Implement Concrete Sensor Subclasses (`sensors/`)

**Description:**
This collection of files contains the concrete implementations of the abstract `BaseDevice` class. It encompasses `temperature_sensor.py`, `light_sensor.py`, `gas_sensor.py`, and `door_sensor.py`.

**Key Responsibilities:**
- **Realistic Telemetry Generation**: Simulates realistic hardware environments by employing standard math libraries (like `math` and `random`) to compute variances, fluctuations, or boolean toggles.
- **Unique State tracking**: Each sensor manages its unique internal states (e.g., Temperature tracks max/min and HVAC mode, whereas Gas tracks PPM levels and leak thresholds).
- **Inherited Execution Loop**: Overrides the base class's generation method such that, when `orchestrator.py` invokes the loop, these specific classes dictate the specific payload being formulated and published to the AWS IoT Core endpoint.

---

## � Directory: `devices/simulators/actuators/*.py`
**Title:** Implement Concrete Actuator Subclasses (`actuators/`)

**Description:**
This future implementation will provide concrete actuators (like `door_locker.py` and `ac_curtain_actuator.py`) serving as the command-receivers of our IoT mock fleet, complimenting the passive sensors.

**Key Responsibilities:**
- **MQTT Command Subscription**: Unlike sensors which simply publish, actuators will subscribe to specific device shadow or command topics on AWS IoT Core to listen for remote changes.
- **State Mutuation Simulation**: Will simulate physical changes in response to received commands (e.g., locking a door, opening a curtain, or toggling HVAC) and log those state changes.
- **Shadow Synchronization**: Will generate outbound acknowledgment payloads back to the cloud confirming whether a physical command was successfully applied or if it failed/errored out securely.

---

## 🐳 Component: Containerization
**Title:** Dockerize Fleet Orchestrator & Emulators

**Description:**
To ensure our simulation environment matches upstream production deployment strategies and runs consistently across all developer platforms, the orchestrator and all device simulators will be packaged into a scalable Docker configuration.

**Key Responsibilities:**
- **Isolated Execution (`Dockerfile`)**: Create a lightweight, multi-stage Python Docker image that packages the `orchestrator.py`, necessary `requirements.txt`, and runtime scripts without local system dependencies.
- **Volume Mounted Certificates**: Configure secure volume mapping internally so that X.509 certs aren't baked directly into the image but read at runtime.
- **Environment Parity (`docker-compose.yml`)**: Leverage Docker Compose to provide instant one-click spin-ups (`docker-compose up`) of the entire mock fleet, optionally side-loading LocalStack as an offline IoT hub. 
- **Networking Configuration**: Ensure Docker networking transparently maps to local MQTT broker ports or external IoT Endpoints without DNS abstraction issues.

---

## �📄 File: `certs/generate_device_cert.sh`
**Title:** Implement Certificate Generation & AWS IoT Registration Script

**Description:**
The `generate_device_cert.sh` script automates the tedious setup process required for secure mTLS (Mutual TLS) connection between your local mock devices and the AWS cloud. 

**Key Responsibilities:**
- **OpenSSL Keypair Generation**: Programmatically generates a 2048-bit RSA private key and creates a Certificate Signing Request (CSR) strictly scoped to a given `DEVICE_ID`.
- **Local CA Signing**: Interactively signs the newly generated device cert against the overarching Fleet local Certificate Authority (`ca.crt`/`ca.key`).
- **AWS IoT Provisioning**: Uses the AWS CLI to push the new certificate into AWS IoT Core (`register-certificate`) and activates it.
- **Thing & Policy Mapping**: Sets up the shadow device (`create-thing`), binds the IAM-like security boundary (`attach-policy` mapping to `iot-fleet-device-policy`), and connects the Thing seamlessly to its X.509 principal.
- **Failsafes**: Built-in validation constraints to abort the process securely if anything hangs during the AWS SDK calls or key provisioning.