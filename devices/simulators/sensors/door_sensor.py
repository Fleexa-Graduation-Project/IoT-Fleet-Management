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
        if self.open_duration >= 300:
            self.publish_alert("DOOR_OPEN_TOO_LONG", "MEDIUM",
                               {"duration_seconds": self.open_duration, "threshold": 300,
                                "location": self.config.location})
        if self.intrusion_detected:
            self.publish_alert("INTRUSION_DETECTED", "CRITICAL",
                               {"location": self.config.location})

    def generate_telemetry(self) -> Dict[str, Any]:
        # 5% chance of door state change per reading
        if random.random() < 0.05:
            self.is_open = not self.is_open
            self.last_change = int(time.time())
            if self.is_open:
                self.open_duration = 0
        if self.is_open:
            self.open_duration += self.config.publish_interval
        else:
            self.open_duration = 0
        # 0.2% chance of intrusion flag (simulates unexpected open at night)
        self.intrusion_detected = random.random() < 0.002 and self.is_open
        status = "OPEN" if self.is_open else "CLOSED"
        self.state.update({
            "open": self.is_open,
            "duration_open_seconds": self.open_duration,
            "last_change": self.last_change,
            "intrusion": self.intrusion_detected,
        })
        self._check_and_publish_alerts()
        return {
            "sensor_type": "door_sensor",
            "open": self.is_open,
            "duration_open_seconds": self.open_duration,
            "intrusion_detected": self.intrusion_detected,
            "last_change": self.last_change,
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