# simulators/base_device.py
import json
import time
import logging
import os
from typing import Dict, Any, Optional, List
from datetime import datetime
from abc import ABC, abstractmethod
from dataclasses import dataclass, asdict
import paho.mqtt.client as mqtt
from enum import Enum
import signal
import threading


# Import schema validator
from devices.simulators.schema_validator import get_validator


logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

HEALTH_FILE = "/tmp/healthy"   # ← FIX: Docker healthcheck target


class DeviceStatus(Enum):
    """Device operational status"""
    ACTIVE   = "ACTIVE"
    INACTIVE = "INACTIVE"
    ERROR    = "ERROR"
    OFFLINE  = "OFFLINE"


@dataclass
class DeviceConfig:
    """Device Configuration - shared across all devices"""
    device_id:        str                   # device-1, device-2, etc.
    user_id:          str                   # Cognito sub 
    device_name:      str                   # "Temperature Sensor"
    device_type:      str                   # "temperature_sensor"
    location:         str                   # "Living Room"
    sensor_type:      str                   # Same as device_type
    ca_cert:          str                   # Path to CA certificate
    client_cert:      str                   # Path to client certificate
    client_key:       str                   # Path to client private key
    mqtt_broker:      str = "a3u4b8ieayojua-ats.iot.us-east-1.amazonaws.com"
    mqtt_port:        int = 8883
    publish_interval: int = 60              # seconds between publishes
    # ← FIX: reconnect/keepalive tuning — readable from env via orchestrator
    keepalive:             int = 30         # was hardcoded 60 in connect()
    reconnect_min_delay:   int = 1
    reconnect_max_delay:   int = 32
    clean_session:         bool = False     # persist shadow subscriptions across reconnect
    mqtt_client_id:        str = ""         # ← if empty, falls back to device_id


#------------------------------------------------------


class BaseDevice(ABC):
    """
    Abstract base class for all IoT devices (sensors and actuators).

    Features:
    - MQTT connection management
    - Schema-compliant telemetry publishing
    - Schema-compliant alert publishing
    - Device shadow updates
    - Command handling (shadow-based)
    - State persistence
    - Error recovery
    """

    def __init__(self, config: DeviceConfig):
        """Initialize device with configuration"""
        self.config = config
        self.is_connected = False
        self.status = DeviceStatus.INACTIVE
        self.state = {}
        self.last_published = {}
        self.last_heartbeat = time.time()
        self.error_count = 0
        self.uptime_seconds = 0

        # Initialize schema validator
        self.validator = get_validator()

        # Initialize MQTT client
        self._setup_mqtt_client()

        logger.info(f"✅ {self.config.device_id} initialized (type: {self.config.device_type})")

    def _setup_mqtt_client(self):
        """Configure MQTT client with TLS"""
        self.mqtt_client = mqtt.Client(
            client_id=self.config.mqtt_client_id or self.config.device_id,
            clean_session=self.config.clean_session,   # ← FIX: was hardcoded True
            protocol=mqtt.MQTTv311
        )

        # Set callbacks
        self.mqtt_client.on_connect    = self._on_connect
        self.mqtt_client.on_disconnect = self._on_disconnect
        self.mqtt_client.on_message    = self._on_message
        self.mqtt_client.on_publish    = self._on_publish

        # ← FIX: exponential backoff between reconnect attempts
        self.mqtt_client.reconnect_delay_set(
            min_delay=self.config.reconnect_min_delay,
            max_delay=self.config.reconnect_max_delay
        )

        # Configure TLS
        try:
            self.mqtt_client.tls_set(
                ca_certs=self.config.ca_cert,
                certfile=self.config.client_cert,
                keyfile=self.config.client_key,
                cert_reqs=mqtt.ssl.CERT_REQUIRED,
                tls_version=mqtt.ssl.PROTOCOL_TLSv1_2,
                ciphers=None
            )
            self.mqtt_client.tls_insecure = False
        except Exception as e:
            logger.error(f"❌ TLS setup failed: {e}")
            raise

    def _on_connect(self, client, userdata, flags, rc):
        """Handle MQTT connection"""
        if rc == 0:
            logger.info(f"✅ {self.config.device_id} connected to AWS IoT Core")
            self.is_connected = True
            self.status = DeviceStatus.ACTIVE
            self.error_count = 0

            # ← FIX: signal Docker healthcheck that we're healthy
            try:
                with open(HEALTH_FILE, "w") as f:
                    f.write("ok")
            except Exception:
                pass

            # Subscribe to command topic
            command_topic = f"devices/{self.config.user_id}/{self.config.device_id}/command"
            client.subscribe(command_topic, qos=1)
            logger.debug(f"📨 Subscribed to: {command_topic}")
        else:
            logger.error(f"❌ Connection failed with code {rc}")
            self.status = DeviceStatus.ERROR
            self.error_count += 1

    def _on_disconnect(self, client, userdata, rc):
        """Handle MQTT disconnection"""
        self.is_connected = False
        self.status = DeviceStatus.OFFLINE

        # ← FIX: remove health file so Docker knows we're offline
        try:
            os.remove(HEALTH_FILE)
        except FileNotFoundError:
            pass

        if rc != 0:
            logger.warning(
                f"⚠️  {self.config.device_id} unexpected disconnection (code: {rc}) "
                f"— run() loop will reconnect with backoff"
            )
        else:
            logger.info(f"🔌 {self.config.device_id} disconnected cleanly")

    def _on_message(self, client, userdata, msg):
        """
        Handle incoming MQTT messages (commands)

        Expects command in format {request_id, action, parameters}
        """
        try:
            payload = json.loads(msg.payload.decode('utf-8'))
            logger.debug(f"📨 Message received on {msg.topic}: {payload}")

            # Validate command schema
            if self.validator.validate_command(payload):
                self.handle_command(payload)
            else:
                logger.error(f"❌ Invalid command format: {payload}")
        except json.JSONDecodeError as e:
            logger.error(f"❌ JSON decode error: {e}")
        except Exception as e:
            logger.error(f"❌ Message handling error: {e}")

    def _on_publish(self, client, userdata, mid):
        """Handle publish confirmation"""
        logger.debug(f"📤 Message published (msg_id: {mid})")

    def connect(self, start_loop: bool = True):
        """Establish MQTT connection to AWS IoT Core"""
        try:
            logger.info(f"🔗 Connecting {self.config.device_id}...")

            connected_event = threading.Event()
            connect_error = [None]

            def _patched_on_connect(client, userdata, flags, rc):
                # Restore the real callback immediately so it handles future reconnects
                client.on_connect = self._on_connect
                if rc == 0:
                    connected_event.set()
                else:
                    connect_error[0] = rc
                    connected_event.set()
                # Now run the real handler
                self._on_connect(client, userdata, flags, rc)

            self.mqtt_client.on_connect = _patched_on_connect

            self.mqtt_client.connect(
                self.config.mqtt_broker,
                self.config.mqtt_port,
                keepalive=self.config.keepalive   # ← FIX: was hardcoded 60, now 30
            )
            
            # ← FIX: only start the loop thread ONCE on first connect
            if start_loop:
                self.mqtt_client.loop_start()

            if not connected_event.wait(timeout=10):
                raise Exception("Connection timed out - no CONNACK received")

            if connect_error[0] is not None:
                raise Exception(f"Connection refused by broker - rc={connect_error[0]}")

            # ← FIX: set is_connected HERE in the calling thread, guaranteed after CONNACK
            # Don't rely solely on the async callback thread timing
            self.is_connected = True
            self.status = DeviceStatus.ACTIVE

            logger.info(f"✅ {self.config.device_id} ready for telemetry")

        except Exception as e:
            logger.error(f"❌ Connection error: {e}")
            self.status = DeviceStatus.ERROR
            raise

    def disconnect(self):
        """Gracefully disconnect from MQTT broker"""
        try:
            self.mqtt_client.loop_stop()
            self.mqtt_client.disconnect()
            logger.info(f"🔌 {self.config.device_id} disconnected gracefully")
        except Exception as e:
            logger.error(f"❌ Disconnection error: {e}")

    def _reconnect(self):
        """Re-establish TCP connection only — loop thread is already running"""
        connected_event = threading.Event()
        connect_error = [None]

        def _patched_on_connect(client, userdata, flags, rc):
            client.on_connect = self._on_connect
            if rc == 0:
                connected_event.set()
            else:
                connect_error[0] = rc
                connected_event.set()
            self._on_connect(client, userdata, flags, rc)

        self.mqtt_client.on_connect = _patched_on_connect

        # reconnect() reuses existing socket/loop — does NOT spawn new thread
        self.mqtt_client.reconnect()

        if not connected_event.wait(timeout=10):
            raise Exception("Reconnect timed out - no CONNACK received")

        if connect_error[0] is not None:
            raise Exception(f"Reconnect refused by broker - rc={connect_error[0]}")

        self.is_connected = True
        self.status = DeviceStatus.ACTIVE


#--------------------------------------


    def publish_telemetry(self, telemetry_payload: Dict[str, Any]):
        """
        Publish sensor/device telemetry to AWS IoT Core

        Schema-compliant format:
        {
            "device_id": "device-1",
            "timestamp": 1701648000,       # SECONDS (not milliseconds)
            "type": "sensor",              # or "actuator"
            "payload": {...}               # Device-specific data
        }

        Args:
            telemetry_payload: Device-specific sensor data
        """
        try:
            topic = f"devices/{self.config.device_id}/telemetry"

            # Determine device type
            device_type = "sensor" if "sensor" in self.config.device_type else "actuator"
            # Build schema-compliant message
            message = {
                "user_id":   self.config.user_id,
                "device_id": self.config.device_id,
                "timestamp": int(time.time()),  # SECONDS (not milliseconds)
                "type":      device_type,
                "payload":   telemetry_payload
            }

            # Validate against schema
            if not self.validator.validate_telemetry(message):
                logger.error(f"❌ Telemetry validation failed for {self.config.device_id}")
                return

            # Publish
            payload_json = json.dumps(message)
            self.mqtt_client.publish(topic, payload_json, qos=1)

            self.last_published[topic] = datetime.now()
            self.last_heartbeat = time.time()
            self.uptime_seconds += self.config.publish_interval

            logger.debug(f"📤 Telemetry published: {topic}")
        except Exception as e:
            logger.error(f"❌ Publish error: {e}")
            self.error_count += 1

    def publish_alert(self, alert_status: str, severity: str, additional_data: Dict[str, Any] = None):
        """
        Publish alert to separate alert topic (devices/{device_id}/alerts)

        Schema:
        {
            "device_id": "gas-sensor-01",
            "timestamp": 1701648000,
            "type": "sensor",
            "payload": {
                "status": "FIRE_DETECTED",
                "severity": "CRITICAL",
                ...additional_data
            }
        }

        Args:
            alert_status: Alert type (e.g., "FIRE_DETECTED", "LOW_BATTERY")
            severity: "WARNING" or "CRITICAL"
            additional_data: Optional extra alert data
        """
        try:
            topic = f"devices/{self.config.device_id}/alerts"

            # Determine device type
            device_type = "sensor" if "sensor" in self.config.device_type else "actuator"
            # Build alert payload
            alert_payload = {
                "status":   alert_status,
                "severity": severity
            }

            # Add additional data if provided
            if additional_data:
                alert_payload.update(additional_data)

            # Build schema-compliant message
            message = {
                "user_id":   self.config.user_id,
                "device_id": self.config.device_id,
                "timestamp": int(time.time()),
                "type":      device_type,
                "payload":   alert_payload
            }

            # Validate against schema
            if not self.validator.validate_alert(message):
                logger.error(f"❌ Alert validation failed for {self.config.device_id}")
                return

            # Publish
            payload_json = json.dumps(message)
            self.mqtt_client.publish(topic, payload_json, qos=1)

            logger.info(f"🚨 Alert published: {alert_status} ({severity})")
        except Exception as e:
            logger.error(f"❌ Alert publish error: {e}")

    def update_shadow(self, reported_state: Dict[str, Any]):
        """
        Update AWS IoT Device Shadow with reported (actual) state.
        Skipped - our backend processes telemetry via rules and DB directly.
        """
        pass

    @abstractmethod
    def generate_telemetry(self) -> Dict[str, Any]:
        """
        Generate sensor data (implemented by subclasses)

        Returns:
            Dictionary with sensor-specific telemetry (the payload)
            Example: {"temperature": 22.5, "humidity": 45, "unit": "celsius"}
        """
        pass

    @abstractmethod
    def handle_command(self, command: Dict[str, Any]):
        """
        Handle incoming commands from AWS IoT Core

        Command format (from Device Shadow desired state):
        {
            "request_id": "cmd-12345",
            "action": "LOCK",
            "parameters": {"force": false}
        }

        Args:
            command: Dictionary with command details
        """
        pass

    def get_device_info(self) -> Dict[str, Any]:
        """Return device metadata and current state"""
        return {
            "device_id":      self.config.device_id,
            "device_type":    self.config.device_type,
            "location":       self.config.location,
            "status":         self.status.value,
            "is_connected":   self.is_connected,
            "error_count":    self.error_count,
            "uptime_seconds": self.uptime_seconds,
            "state":          self.state
        }

    def run(self, publish_interval: Optional[int] = None):
        """
        Main device loop - runs FOREVER until SIGTERM/SIGINT.
        Handles disconnects with automatic reconnection + exponential backoff.
        """
        interval = publish_interval or self.config.publish_interval
        self._stop_event = threading.Event()

        def _handle_signal(signum, frame):
            logger.info(f"🛑 {self.config.device_id} received signal {signum}, shutting down...")
            self._stop_event.set()

        signal.signal(signal.SIGTERM, _handle_signal)
        signal.signal(signal.SIGINT,  _handle_signal)

        logger.info(f"🚀 {self.config.device_id} started - publishing every {interval}s indefinitely")
        logger.info("   Stop with: docker compose stop OR kill -SIGTERM <pid>")

        backoff = 2  # initial reconnect delay in seconds

        try:
            while not self._stop_event.is_set():
                # ← FIX: small settle wait so _on_connect callback
                #   has time to set is_connected=True before we check it
                if not self.is_connected:
                    try:
                        logger.info(f"🔄 {self.config.device_id} reconnecting in {backoff}s...")
                        self._stop_event.wait(timeout=backoff)
                        if self._stop_event.is_set():
                            break
                        # ← FIX: use reconnect(), NOT connect() — loop already running
                        self._reconnect()
                        backoff = 2  # reset on successful reconnect
                    except Exception as e:
                        logger.error(f"❌ Reconnect failed: {e}")
                        backoff = min(backoff * 2, 60)  # cap at 60s
                        continue

                # ← FIX: only publish if actually connected after reconnect attempt
                if not self.is_connected:
                    continue

                try:
                    telemetry = self.generate_telemetry()
                    self.publish_telemetry(telemetry)
                    self.update_shadow(self.state)
                    self._stop_event.wait(timeout=interval)
                except Exception as e:
                    logger.error(f"❌ Loop error: {e}")
                    self.error_count += 1
                    self._stop_event.wait(timeout=min(interval, 5))
        finally:
            # Full shutdown — stop the loop thread here, only once
            self.disconnect()
            logger.info(f"✅ {self.config.device_id} stopped cleanly")