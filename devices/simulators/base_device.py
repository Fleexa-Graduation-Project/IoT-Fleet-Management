# simulators/base_device.py
import json
import time
import logging
from typing import Dict, Any, Optional, List
from datetime import datetime
from abc import ABC, abstractmethod
from dataclasses import dataclass, asdict
import paho.mqtt.client as mqtt
from enum import Enum

# NEW: Import schema validator
from simulators.schema_validator import get_validator

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class DeviceStatus(Enum):
    """Device operational status"""
    ACTIVE = "ACTIVE"
    INACTIVE = "INACTIVE"
    ERROR = "ERROR"
    OFFLINE = "OFFLINE"

@dataclass
class DeviceConfig:
    """Device Configuration - shared across all devices"""
    device_id: str                          # device-1, device-2, etc.
    device_name: str                        # "Temperature Sensor"
    device_type: str                        # "temperature_sensor"
    location: str                           # "Living Room"
    sensor_type: str                        # Same as device_type
    ca_cert: str                            # Path to CA certificate
    client_cert: str                        # Path to client certificate
    client_key: str                         # Path to client private key
    mqtt_broker: str = "iot.us-east-1.amazonaws.com"
    mqtt_port: int = 8883
    publish_interval: int = 5               # seconds between publishes
    
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
        
        # NEW: Initialize schema validator
        self.validator = get_validator()
        
        # Initialize MQTT client
        self._setup_mqtt_client()
        
        logger.info(f"✅ {self.config.device_id} initialized (type: {self.config.device_type})")
    
    def _setup_mqtt_client(self):
        """Configure MQTT client with TLS"""
        self.mqtt_client = mqtt.Client(
            client_id=self.config.device_id,
            protocol=mqtt.MQTTv311,
            transport="tcp"
        )
        
        # Set callbacks
        self.mqtt_client.on_connect = self._on_connect
        self.mqtt_client.on_disconnect = self._on_disconnect
        self.mqtt_client.on_message = self._on_message
        self.mqtt_client.on_publish = self._on_publish
        
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
            
            # Subscribe to command topic (Device Shadow)
            command_topic = f"$aws/things/{self.config.device_id}/shadow/update/delta"
            client.subscribe(command_topic, qos=1)
            logger.debug(f"📨 Subscribed to: {command_topic}")
        else:
            logger.error(f"❌ Connection failed with code {rc}")
            self.status = DeviceStatus.ERROR
            self.error_count += 1
    
    def _on_disconnect(self, client, userdata, rc):
        """Handle MQTT disconnection"""
        if rc != 0:
            logger.warning(f"⚠️  Unexpected disconnection (code: {rc})")
        self.is_connected = False
        self.status = DeviceStatus.OFFLINE
        logger.info(f"🔌 {self.config.device_id} disconnected")
    
    def _on_message(self, client, userdata, msg):
        """
        Handle incoming MQTT messages (commands/shadow updates)
        
        NEW: Expects command in format {request_id, action, parameters}
        """
        try:
            payload = json.loads(msg.payload.decode('utf-8'))
            logger.debug(f"📨 Message received on {msg.topic}: {payload}")
            
            # Extract desired state from shadow delta
            if "state" in payload:
                desired_state = payload["state"]
                
                # NEW: Validate command schema
                if self.validator.validate_command(desired_state):
                    self.handle_command(desired_state)
                else:
                    logger.error(f"❌ Invalid command format: {desired_state}")
        except json.JSONDecodeError as e:
            logger.error(f"❌ JSON decode error: {e}")
        except Exception as e:
            logger.error(f"❌ Message handling error: {e}")
    
    def _on_publish(self, client, userdata, mid):
        """Handle publish confirmation"""
        logger.debug(f"📤 Message published (msg_id: {mid})")
    
    def connect(self):
        """Establish MQTT connection to AWS IoT Core"""
        try:
            logger.info(f"🔗 Connecting {self.config.device_id}...")
            self.mqtt_client.connect(
                self.config.mqtt_broker,
                self.config.mqtt_port,
                keepalive=60
            )
            self.mqtt_client.loop_start()
            time.sleep(2)  # Wait for connection to establish
            
            if self.is_connected:
                logger.info(f"✅ {self.config.device_id} ready for telemetry")
            else:
                raise Exception("Connection failed after timeout")
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

#--------------------------------------

    def publish_telemetry(self, telemetry_payload: Dict[str, Any]):
        """
        Publish sensor/device telemetry to AWS IoT Core
        
        NEW: Schema-compliant format
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
            
            # NEW: Determine device type
            device_type = "sensor" if "sensor" in self.config.device_type else "actuator"
            
            # NEW: Build schema-compliant message
            message = {
                "device_id": self.config.device_id,
                "timestamp": int(time.time()),  # SECONDS (not milliseconds)
                "type": device_type,
                "payload": telemetry_payload
            }
            
            # NEW: Validate against schema
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
        Publish alert to separate alert topic
        
        NEW: Separate topic for alerts (devices/{device_id}/alerts)
        
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
            severity: "LOW", "MEDIUM", or "CRITICAL"
            additional_data: Optional extra alert data
        """
        try:
            topic = f"devices/{self.config.device_id}/alerts"
            
            # Determine device type
            device_type = "sensor" if "sensor" in self.config.device_type else "actuator"
            
            # Build alert payload
            alert_payload = {
                "status": alert_status,
                "severity": severity
            }
            
            # Add additional data if provided
            if additional_data:
                alert_payload.update(additional_data)
            
            # Build schema-compliant message
            message = {
                "device_id": self.config.device_id,
                "timestamp": int(time.time()),
                "type": device_type,
                "payload": alert_payload
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
        Update AWS IoT Device Shadow with reported (actual) state
        
        This tells AWS what the device currently looks like
        """
        try:
            shadow_update = {
                "state": {
                    "reported": reported_state
                }
            }
            
            topic = f"$aws/things/{self.config.device_id}/shadow/update"
            payload = json.dumps(shadow_update)
            
            self.mqtt_client.publish(topic, payload, qos=1)
            logger.debug(f"🔄 Shadow updated with state: {reported_state}")
        except Exception as e:
            logger.error(f"❌ Shadow update error: {e}")

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
        
        NEW: Command format (from Device Shadow desired state):
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
            "device_id": self.config.device_id,
            "device_type": self.config.device_type,
            "location": self.config.location,
            "status": self.status.value,
            "is_connected": self.is_connected,
            "error_count": self.error_count,
            "uptime_seconds": self.uptime_seconds,
            "state": self.state
        }
    
    def run(self, publish_interval: Optional[int] = None):
        """
        Main device loop - generates and publishes telemetry
        
        Args:
            publish_interval: Override config interval (seconds)
        """
        interval = publish_interval or self.config.publish_interval
        
        try:
            logger.info(f"🚀 {self.config.device_id} started (interval: {interval}s)")
            
            while self.is_connected:
                try:
                    # Generate device-specific telemetry
                    telemetry = self.generate_telemetry()
                    
                    # Publish to AWS IoT Core (schema-compliant)
                    self.publish_telemetry(telemetry)
                    
                    # Update device shadow with current state
                    self.update_shadow(self.state)
                    
                    # Sleep until next publish
                    time.sleep(interval)
                except Exception as e:
                    logger.error(f"❌ Error in main loop: {e}")
                    self.error_count += 1
                    time.sleep(interval)
        
        except KeyboardInterrupt:
            logger.info("⏹️  Shutdown signal received")
        except Exception as e:
            logger.error(f"❌ Fatal error: {e}")
        finally:
            self.disconnect()
            logger.info(f"✅ {self.config.device_id} stopped")
