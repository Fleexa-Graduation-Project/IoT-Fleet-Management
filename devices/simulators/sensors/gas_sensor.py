import random
from typing import Dict, Any
import logging
from devices.simulators.base_device import BaseDevice, DeviceConfig

logger = logging.getLogger(__name__)

class GasSensor(BaseDevice):
    """Gas / Air Quality Sensor — CO2, CO, LPG simulation"""

    SAFE_CO2   = (400, 1000)   # ppm
    SAFE_CO    = (0, 9)        # ppm
    SAFE_LPG   = (0, 1000)     # ppm

    def __init__(self, config: DeviceConfig):
        super().__init__(config)
        self.co2_ppm  = 500.0
        self.co_ppm   = 2.0
        self.lpg_ppm  = 100.0
        self.alarm_triggered = False
        self.state = {"co2_ppm": self.co2_ppm, "co_ppm": self.co_ppm,
                      "lpg_ppm": self.lpg_ppm, "air_quality": "GOOD"}

    def _simulate_gas_levels(self):
        self.co2_ppm  += random.uniform(-15, 20)
        self.co_ppm   += random.uniform(-0.2, 0.3)
        self.lpg_ppm  += random.uniform(-10, 12)
        # Random dangerous spike (0.5% chance)
        if random.random() < 0.005:
            self.co_ppm  += random.uniform(20, 50)
            self.lpg_ppm += random.uniform(2000, 4000)
        self.co2_ppm  = round(max(350, min(5000, self.co2_ppm)), 1)
        self.co_ppm   = round(max(0, min(200, self.co_ppm)), 2)
        self.lpg_ppm  = round(max(0, min(10000, self.lpg_ppm)), 1)

    def _calculate_air_quality(self) -> str:
        if self.co_ppm > 35 or self.lpg_ppm > 5000:
            return "DANGEROUS"
        elif self.co2_ppm > 2000 or self.co_ppm > 9:
            return "POOR"
        elif self.co2_ppm > 1000:
            return "MODERATE"
        return "GOOD"

    def _check_and_publish_alerts(self):
        if self.co_ppm > 35:
            self.publish_alert("CO_DANGEROUS_LEVEL", "CRITICAL",
                               {"co_ppm": self.co_ppm, "threshold": 35})
        elif self.co_ppm > 9:
            self.publish_alert("CO_HIGH_LEVEL", "MEDIUM",
                               {"co_ppm": self.co_ppm, "threshold": 9})
        if self.lpg_ppm > 5000:
            self.publish_alert("LPG_LEAK_CRITICAL", "CRITICAL",
                               {"lpg_ppm": self.lpg_ppm, "threshold": 5000})
        if self.co2_ppm > 2000:
            self.publish_alert("HIGH_CO2_LEVEL", "MEDIUM",
                               {"co2_ppm": self.co2_ppm, "threshold": 2000})

    def generate_telemetry(self) -> Dict[str, Any]:
        self._simulate_gas_levels()
        air_quality = self._calculate_air_quality()
        self.state.update({
            "co2_ppm": self.co2_ppm,
            "co_ppm": self.co_ppm,
            "lpg_ppm": self.lpg_ppm,
            "air_quality": air_quality,
        })
        self._check_and_publish_alerts()
        return {
            "sensor_type": "gas_sensor",
            "co2_ppm": self.co2_ppm,
            "co_ppm": self.co_ppm,
            "lpg_ppm": self.lpg_ppm,
            "air_quality": air_quality,
        }

    def handle_command(self, command: Dict[str, Any]):
        action = command.get("action", "").upper()
        if action == "RESET":
            self.co2_ppm = 500.0
            self.co_ppm  = 2.0
            self.lpg_ppm = 100.0
            logger.info(f"[{self.config.device_id}] Gas sensor reset")
        elif action == "SILENCE_ALARM":
            self.alarm_triggered = False
            logger.info(f"[{self.config.device_id}] Alarm silenced")