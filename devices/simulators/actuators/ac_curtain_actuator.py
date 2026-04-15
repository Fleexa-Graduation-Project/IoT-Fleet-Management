import random
from typing import Dict, Any
from enum import Enum
import logging
from devices.simulators.base_device import BaseDevice, DeviceConfig

logger = logging.getLogger(__name__)

class ACMode(Enum):
    OFF     = "OFF"
    COOL    = "COOL"
    HEAT    = "HEAT"
    FAN     = "FAN"
    AUTO    = "AUTO"

class ACCurtainActuator(BaseDevice):
    """Combined AC Unit + Motorized Curtain Actuator"""

    def __init__(self, config: DeviceConfig):
        super().__init__(config)
        # AC state
        self.mode         = ACMode.OFF
        self.ac_temp_setpoint = 22.0
        self.ac_fan_speed    = 0       # 0–3
        self.ac_power_watts  = 0.0
        # Curtain state
        self.curtain_position = 0      # 0=fully closed, 100=fully open
        self.curtain_moving   = False
        self.state = {
            "mode": self.mode.value,
            "target_temp": self.ac_temp_setpoint,
            "curtain_position": self.curtain_position,
        }

    def _calculate_ac_power(self) -> float:
        power_map = {ACMode.OFF: 0, ACMode.FAN: 50,
                     ACMode.COOL: 1200, ACMode.HEAT: 1000, ACMode.AUTO: 1100}
        base = power_map.get(self.mode, 0)
        return round(base + random.uniform(-20, 20), 1)

    def _check_and_publish_alerts(self):
        if self.ac_power_watts > 1400:
            self.publish_alert("AC_OVERCONSUMPTION", "MEDIUM",
                               {"power_watts": self.ac_power_watts, "threshold": 1400})

    def generate_telemetry(self) -> Dict[str, Any]:
        self.ac_power_watts = self._calculate_ac_power()
        self.state.update({
            "power_state": "OFF" if self.mode.value == "OFF" else "ON",
            "mode": self.mode.value,
            "target_temp": self.ac_temp_setpoint,
            "last_turned_on": 0,
            "timer_end_timestamp": 0,
            "ac_fan_speed": self.ac_fan_speed,
            "curtain_position": self.curtain_position,
            "ac_power_watts": self.ac_power_watts,
        })
        self._check_and_publish_alerts()
        return {
            "sensor_type": "ac_curtain",
            "power_state": "OFF" if self.mode.value == "OFF" else "ON",
            "mode": self.mode.value,
            "target_temp": self.ac_temp_setpoint,
            "last_turned_on": 0,
            "timer_end_timestamp": 0,
            "ac_fan_speed": self.ac_fan_speed,
            "ac_power_watts": self.ac_power_watts,
            "curtain_position_percent": self.curtain_position,
            "curtain_moving": self.curtain_moving,
        }

    def handle_command(self, command: Dict[str, Any]):
        action     = command.get("action", "").upper()
        parameters = command.get("parameters", {})
        request_id = command.get("request_id", "unknown")

        logger.info(f"[{self.config.device_id}] CMD {action} req={request_id}")


        if action == "SET_STATE":
            power = parameters.get("power", "").upper()
            if power == "OFF":
                self.mode = ACMode.OFF
            else:
                mode = parameters.get("mode", "").upper()
                if mode in ACMode.__members__:
                    self.mode = ACMode[mode]
                temp = parameters.get("target_temp")
                if temp and 16 <= temp <= 30:
                    self.ac_temp_setpoint = temp

        elif action == "SET_AC_MODE":
            mode = parameters.get("mode", "").upper()
            if mode in ACMode.__members__:
                self.mode = ACMode[mode]

        elif action == "SET_AC_TEMP":
            temp = parameters.get("temperature")
            if temp and 16 <= temp <= 30:
                self.ac_temp_setpoint = temp

        elif action == "SET_FAN_SPEED":
            speed = parameters.get("speed", 0)
            self.ac_fan_speed = max(0, min(3, int(speed)))

        elif action == "SET_CURTAIN":
            pos = parameters.get("position", 0)
            self.curtain_position = max(0, min(100, int(pos)))
            self.curtain_moving = True
            logger.info(f"[{self.config.device_id}] Curtain → {self.curtain_position}%")

        elif action == "OPEN_CURTAIN":
            self.curtain_position = 100

        elif action == "CLOSE_CURTAIN":
            self.curtain_position = 0