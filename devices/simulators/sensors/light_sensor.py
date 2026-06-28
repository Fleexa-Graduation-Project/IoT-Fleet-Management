import random, math, time
from datetime import datetime
from typing import Dict, Any
import logging
from devices.simulators.base_device import BaseDevice, DeviceConfig

logger = logging.getLogger(__name__)

class LightSensor(BaseDevice):
    """Ambient Light Sensor — 0 to 1000 Lux simulation"""

    def __init__(self, config: DeviceConfig):
        super().__init__(config)
        self.light_level = 0.0
        self.state = {"light_level": 0, "is_dark": True, "brightness_percent": 0}

    def _get_time_of_day(self) -> float:
        """Return current local hour as fractional float, e.g. 14.5 = 14:30."""
        now = datetime.now()
        return now.hour + now.minute / 60.0 + now.second / 3600.0

    def _simulate_light_cycle(self, time_of_day: float):
        """Simulate lux based on real wall-clock time of day."""
        hour_norm = (time_of_day - 6) / 12 if 6 <= time_of_day <= 18 else 0
        base_light = 800 * math.sin(math.pi * hour_norm) if hour_norm > 0 else 0
        noise = random.uniform(-30, 30)
        self.light_level = max(0, min(1000, base_light + noise))

    def _check_and_publish_alerts(self):
        if self.light_level < 10:
            self.publish_alert("COMPLETE_DARKNESS", "WARNING",
                               {"lux": self.light_level, "location": self.config.location})
        elif self.light_level > 900:
            self.publish_alert("EXCESSIVE_BRIGHTNESS", "WARNING",
                               {"lux": self.light_level, "threshold": 900})

    def generate_telemetry(self) -> Dict[str, Any]:
        time_of_day = self._get_time_of_day()
        self._simulate_light_cycle(time_of_day)
        is_dark = self.light_level < 50
        self.state.update({
            "light_level": round(self.light_level, 1),
            "is_dark": is_dark,
            "brightness_percent": int(self.light_level / 1000 * 100),
        })
        self._check_and_publish_alerts()
        # Real HH:MM — updates every minute visibly
        time_str = datetime.now().strftime("%H:%M")
        return {
            "sensor_type": "light_sensor",
            "light_level": round(self.light_level, 1),
            "is_dark": is_dark,
            "brightness_percent": int(self.light_level / 1000 * 100),
            "time_of_day": time_str,
        }

    def handle_command(self, command: Dict[str, Any]):
        action = command.get("action", "").upper()
        logger.info(f"[{self.config.device_id}] CMD {action}")
        if action == "CALIBRATE":
            self.light_level = 0.0
            logger.info(f"[{self.config.device_id}] Calibrated to zero lux")