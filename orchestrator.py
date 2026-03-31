import os
import time
import logging
import signal
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed
from typing import List

from devices.simulators.base_device import DeviceConfig
from devices.simulators.sensors.temperature_sensor import TemperatureSensor
from devices.simulators.sensors.light_sensor import LightSensor
from devices.simulators.sensors.gas_sensor import GasSensor
from devices.simulators.sensors.door_sensor import DoorSensor
from devices.simulators.actuators import DoorLocker, ACCurtainActuator

# ── Logging Setup ─────────────────────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s — %(message)s",
    handlers=[
        logging.StreamHandler(sys.stdout),
        logging.FileHandler("logs/orchestrator.log", mode="a"),
    ]
)
logger = logging.getLogger("orchestrator")

# ── Environment Config ────────────────────────────────────────────────────────
MQTT_BROKER    = os.getenv("MQTT_BROKER", "a3u4b8ieayojua-ats.iot.us-east-1.amazonaws.com")
MQTT_PORT      = int(os.getenv("MQTT_PORT", "8883"))
AWS_REGION     = os.getenv("AWS_REGION", "us-east-1")
USE_LOCALSTACK = os.getenv("USE_LOCALSTACK", "false").lower() == "true"
CERT_BASE      = os.getenv("CERT_BASE", "certs")
PUBLISH_INTERVAL = int(os.getenv("PUBLISH_INTERVAL", "5"))

# ── Device Registry ───────────────────────────────────────────────────────────
# (device_id, device_type, location, DeviceClass)
DEVICE_REGISTRY = [
    ("temp-sensor-01",  "temperature_sensor", "Living Room",  TemperatureSensor),
    ("light-sensor-01", "light_sensor",       "Living Room",  LightSensor),
    ("gas-sensor-01",   "gas_sensor",         "Kitchen",      GasSensor),
    ("door-sensor-01",  "door_sensor",        "Front Door",   DoorSensor),
    ("door-locker-01",  "actuator",           "Front Door",   DoorLocker),
    ("ac-curtain-01",   "actuator",           "Bedroom",      ACCurtainActuator),
]


# ── Config Builder ────────────────────────────────────────────────────────────
def build_config(device_id: str, device_type: str, location: str) -> DeviceConfig:
    if USE_LOCALSTACK:
        broker = "localhost"
        ca     = f"{CERT_BASE}/AmazonRootCA1.pem"
        cert   = f"{CERT_BASE}/devices/local-test.crt"
        key    = f"{CERT_BASE}/devices/local-test.key"
    else:
        broker = MQTT_BROKER
        ca     = f"{CERT_BASE}/AmazonRootCA1.pem"
        cert   = f"{CERT_BASE}/devices/{device_id}.crt"
        key    = f"{CERT_BASE}/devices/{device_id}.key"

    return DeviceConfig(
        device_id=device_id,
        device_name=device_id,
        device_type=device_type,
        location=location,
        sensor_type=device_type,
        ca_cert=ca,
        client_cert=cert,
        client_key=key,
        mqtt_broker=broker,
        mqtt_port=MQTT_PORT,
        publish_interval=PUBLISH_INTERVAL,
    )


# ── Device Runner ─────────────────────────────────────────────────────────────
def run_device(device) -> None:
    """Connect and run a single device — called inside a thread."""
    device_id = device.config.device_id
    try:
        logger.info(f"[{device_id}] Connecting to broker...")
        device.connect()
        logger.info(f"[{device_id}] Connected — starting telemetry loop")
        device.run()
    except Exception as e:
        logger.error(f"[{device_id}] Fatal error: {e}")
    finally:
        logger.info(f"[{device_id}] Shutting down")
        try:
            device.disconnect()
        except Exception:
            pass


# ── Orchestrator ──────────────────────────────────────────────────────────────
class IoTOrchestrator:
    def __init__(self):
        self.devices: List = []
        self.executor: ThreadPoolExecutor = None
        self._running = False
        self._setup_signal_handlers()

    def _setup_signal_handlers(self):
        """Graceful shutdown on Ctrl+C or SIGTERM."""
        signal.signal(signal.SIGINT,  self._handle_shutdown)
        signal.signal(signal.SIGTERM, self._handle_shutdown)

    def _handle_shutdown(self, signum, frame):
        logger.info("Shutdown signal received — stopping all devices...")
        self._running = False
        self.stop_all()
        sys.exit(0)

    def build_devices(self):
        """Instantiate all 6 devices from the registry."""
        for device_id, device_type, location, DeviceClass in DEVICE_REGISTRY:
            try:
                config = build_config(device_id, device_type, location)
                device = DeviceClass(config)
                self.devices.append(device)
                logger.info(f"Built device: {device_id} ({device_type}) @ {location}")
            except Exception as e:
                logger.error(f"Failed to build {device_id}: {e}")

    def start_all(self):
        """Connect all devices with staggered start, then run in threads."""
        if not self.devices:
            logger.error("No devices to start — run build_devices() first")
            return

        logger.info(f"Starting {len(self.devices)} devices (broker: {MQTT_BROKER})")
        logger.info(f"Region: {AWS_REGION} | LocalStack: {USE_LOCALSTACK}")
        logger.info(f"Publish interval: {PUBLISH_INTERVAL}s")

        self._running = True
        self.executor = ThreadPoolExecutor(
            max_workers=len(self.devices),
            thread_name_prefix="device"
        )

        futures = []
        for device in self.devices:
            future = self.executor.submit(run_device, device)
            futures.append((device.config.device_id, future))
            time.sleep(0.5)   # stagger connections to avoid broker flood

        return futures

    def stop_all(self):
        """Gracefully disconnect all devices."""
        logger.info("Stopping all devices...")
        for device in self.devices:
            try:
                device.disconnect()
                logger.info(f"[{device.config.device_id}] Disconnected")
            except Exception as e:
                logger.warning(f"[{device.config.device_id}] Error during disconnect: {e}")

        if self.executor:
            self.executor.shutdown(wait=True, cancel_futures=True)
            logger.info("Thread pool shut down")

    def status(self):
        """Print current status of all devices."""
        print("\n" + "="*60)
        print(f"{'DEVICE ID':<20} {'TYPE':<22} {'STATUS':<10} {'ERRORS'}")
        print("="*60)
        for device in self.devices:
            info = device.get_device_info()
            print(
                f"{info['device_id']:<20} "
                f"{info['device_type']:<22} "
                f"{info['status']:<10} "
                f"{info['error_count']}"
            )
        print("="*60 + "\n")


# ── Entry Point ───────────────────────────────────────────────────────────────
if __name__ == "__main__":
    # Ensure logs directory exists
    os.makedirs("logs", exist_ok=True)

    logger.info("="*60)
    logger.info("  Fleexa IoT Fleet — Orchestrator Starting")
    logger.info("="*60)

    orchestrator = IoTOrchestrator()
    orchestrator.build_devices()
    orchestrator.status()

    futures = orchestrator.start_all()

    # Keep main thread alive and print status every 60 seconds
    try:
        tick = 0
        while True:
            time.sleep(10)
            tick += 10
            if tick % 60 == 0:
                orchestrator.status()
    except KeyboardInterrupt:
        logger.info("KeyboardInterrupt — shutting down...")
        orchestrator.stop_all()
        logger.info("Fleexa orchestrator stopped cleanly.")