import random, math, time
from typing import Dict, Any
import logging
from devices.simulators.base_device import BaseDevice, DeviceConfig

logger = logging.getLogger(__name__)

class LightSensor(BaseDevice):
    """Ambient Light Sensor — 0 to 1000 Lux simulation"""

    def __init__(self, config: DeviceConfig):
        super().__init__(config)
        self.time_of_day = 8.0  # Start at 8 AM
        self.light_level = 0.0
        self.state = {"light_level": 0, "is_dark": True, "brightness_percent": 0}

    def _simulate_light_cycle(self):
        self.time_of_day = (self.time_of_day + random.uniform(0.05, 0.15)) % 24
        hour_norm = (self.time_of_day - 6) / 12 if 6 <= self.time_of_day <= 18 else 0
        base_light = 800 * math.sin(math.pi * hour_norm) if hour_norm > 0 else 0
        noise = random.uniform(-30, 30)
        self.light_level = max(0, min(1000, base_light + noise))

    def _check_and_publish_alerts(self):
        if self.light_level < 10:
            self.publish_alert("COMPLETE_DARKNESS", "LOW",
                               {"lux": self.light_level, "location": self.config.location})
        elif self.light_level > 900:
            self.publish_alert("EXCESSIVE_BRIGHTNESS", "LOW",
                               {"lux": self.light_level, "threshold": 900})

    def generate_telemetry(self) -> Dict[str, Any]:
        self._simulate_light_cycle()
        is_dark = self.light_level < 50
        self.state.update({
            "light_level": round(self.light_level, 1),
            "is_dark": is_dark,
            "brightness_percent": int(self.light_level / 1000 * 100),
        })
        self._check_and_publish_alerts()
        return {
            "sensor_type": "light_sensor",
            "light_level": round(self.light_level, 1),
            "is_dark": is_dark,
            "brightness_percent": int(self.light_level / 1000 * 100),
            "time_of_day": f"{int(self.time_of_day):02d}:00",
        }

    def handle_command(self, command: Dict[str, Any]):
        action = command.get("action", "").upper()
        logger.info(f"[{self.config.device_id}] CMD {action}")
        # Light sensor is read-only; commands can trigger calibration
        if action == "CALIBRATE":
            self.light_level = 0.0
            logger.info(f"[{self.config.device_id}] Calibrated to zero lux")