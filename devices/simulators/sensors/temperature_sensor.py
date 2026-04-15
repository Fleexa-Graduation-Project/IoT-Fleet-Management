import random, math, time
from typing import Dict, Any
import logging
from devices.simulators.base_device import BaseDevice, DeviceConfig

logger = logging.getLogger(__name__)

class TemperatureSensor(BaseDevice):
    """DHT22 Temperature & Humidity Sensor Simulation"""

    def __init__(self, config: DeviceConfig):
        super().__init__(config)
        self.current_temp = 22.0
        self.current_humidity = 50.0
        self.target_temp = 22.0
        self.hvmode = "OFF"   # OFF | HEATING | COOLING
        self.max_temp_today = self.current_temp
        self.min_temp_today = self.current_temp
        self.state = {
            "temp": self.current_temp,
            "humidity_percent": self.current_humidity,
            "status": self.hvmode,
            "target_temperature": self.target_temp,
        }

    def _apply_environmental_drift(self):
        self.current_temp += random.uniform(-0.5, 0.5)
        self.current_humidity += random.uniform(-1.0, 1.0)

    def _apply_hvac_effect(self):
        if self.hvmode == "COOLING" and self.current_temp > self.target_temp:
            self.current_temp -= 0.3
        elif self.hvmode == "HEATING" and self.current_temp < self.target_temp:
            self.current_temp += 0.3

    def _check_thermostat(self):
        if self.current_temp > self.target_temp + 2:
            self.hvmode = "COOLING"
        elif self.current_temp < self.target_temp - 2:
            self.hvmode = "HEATING"
        else:
            self.hvmode = "OFF"

    def _calculate_comfort(self) -> str:
        if 18 <= self.current_temp <= 26 and 30 <= self.current_humidity <= 60:
            return "COMFORTABLE"
        elif self.current_temp > 30 or self.current_humidity > 70:
            return "UNCOMFORTABLE_HOT"
        elif self.current_temp < 16:
            return "UNCOMFORTABLE_COLD"
        return "MODERATE"

    def _calculate_heat_index(self) -> float:
        T, R = self.current_temp, self.current_humidity
        return round(T + 0.33 * (R / 100 * 6.105 * math.exp(17.27 * T / (237.7 + T))) - 4.0, 2)

    def _check_and_publish_alerts(self):
        if self.current_temp >= 40:
            self.publish_alert("HIGH_TEMPERATURE_CRITICAL", "CRITICAL",
                               {"temp": self.current_temp, "threshold": 40})
        elif self.current_temp >= 35:
            self.publish_alert("HIGH_TEMPERATURE_WARNING", "MEDIUM",
                               {"temp": self.current_temp, "threshold": 35})
        if self.current_temp <= -20:
            self.publish_alert("LOW_TEMPERATURE_CRITICAL", "CRITICAL",
                               {"temp": self.current_temp, "threshold": -20})
        if self.current_humidity >= 90:
            self.publish_alert("HIGH_HUMIDITY_WARNING", "MEDIUM",
                               {"humidity_percent": self.current_humidity, "threshold": 90})

    def generate_telemetry(self) -> Dict[str, Any]:
        self._apply_environmental_drift()
        self._check_thermostat()
        self._apply_hvac_effect()
        self.current_temp = round(max(-40, min(125, self.current_temp)), 2)
        self.current_humidity = round(max(0, min(100, self.current_humidity)), 2)
        self.max_temp_today = max(self.max_temp_today, self.current_temp)
        self.min_temp_today = min(self.min_temp_today, self.current_temp)
        comfort = self._calculate_comfort()
        self.state.update({
            "temp": self.current_temp,
            "humidity_percent": self.current_humidity,
            "status": self.hvmode,
            "comfort_index": comfort,
        })
        self._check_and_publish_alerts()
        return {
            "sensor_type": "temperature_humidity",
            "temp": self.current_temp,
            "humidity_percent": self.current_humidity,
            "status": self.hvmode,
            "comfort_level": comfort,
            "heat_index": self._calculate_heat_index(),
            "max_temp_today": self.max_temp_today,
            "min_temp_today": self.min_temp_today,
        }

    def handle_command(self, command: Dict[str, Any]):
        action = command.get("action", "").upper()
        parameters = command.get("parameters", {})
        request_id = command.get("request_id", "unknown")
        logger.info(f"[{self.config.device_id}] CMD {action} | req={request_id}")
        if action == "SET_TARGET_TEMP":
            new_target = parameters.get("temperature")
            if new_target and -40 <= new_target <= 50:
                self.target_temp = new_target
        elif action == "SET_MODE":
            mode = parameters.get("mode", "").upper()
            if mode in ["HEATING", "COOLING", "OFF"]:
                self.hvmode = mode
        elif action == "RESET":
            self.current_temp = 22.0
            self.current_humidity = 50.0
            self.target_temp = 22.0