import random, time
from typing import Dict, Any
import logging
from devices.simulators.base_device import BaseDevice, DeviceConfig

logger = logging.getLogger(__name__)

class DoorSensor(BaseDevice):
    """Binary Door Sensor — OPEN/CLOSED"""

    def __init__(self, config: DeviceConfig):
        super().__init__(config)
        self.is_open = False
        self.open_duration = 0
        self.last_change = None
        self.intrusion_detected = False
        self.state = {"open": False, "duration_open_seconds": 0,
                      "last_change": None, "intrusion": False}

    def _check_and_publish_alerts(self):
        if self.battery_level < 10:
            self.publish_alert("LOW_BATTERY", "CRITICAL",
                               {"battery_level": self.battery_level, "threshold": 10})
        if self.intrusion_detected:
            self.publish_alert("INTRUSION_DETECTED", "CRITICAL", {})
        if self.is_open and self.open_duration >= 60:
            self.publish_alert("DOOR_LEFT_OPEN", "WARNING",
                               {"duration_open_seconds": self.open_duration})

    def generate_telemetry(self) -> Dict[str, Any]:
        if not hasattr(self, 'battery_level'):
            self.battery_level = 100.0
            
        # Drain battery slowly instead of randomly flipping door state
        self.battery_level = max(0.0, self.battery_level - (random.random() * 0.1))

        if self.is_open:
            self.open_duration += self.config.publish_interval
        else:
            self.open_duration = 0

        status = "OPEN" if self.is_open else "CLOSED"
        self.state.update({
            "open": self.is_open,
            "duration_open_seconds": self.open_duration,
            "last_change": self.last_change,
            "battery_level": round(self.battery_level, 1)
        })
        self._check_and_publish_alerts()
        return {
            "sensor_type": "door_sensor",
            "open": self.is_open,
            "duration_open_seconds": self.open_duration,
            "intrusion_detected": self.intrusion_detected,
            "last_change": self.last_change,
            "battery_level": round(self.battery_level, 1),
        }

    def handle_command(self, command: Dict[str, Any]):
        action = command.get("action", "").upper()
        request_id = command.get("request_id", "unknown")
        logger.info(f"[{self.config.device_id}] CMD {action} req={request_id}")
        if action == "FORCE_CLOSE":
            self.is_open = False
            self.open_duration = 0
        elif action == "RESET_INTRUSION":
            self.intrusion_detected = False