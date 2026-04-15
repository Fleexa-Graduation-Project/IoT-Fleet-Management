import random, time
from typing import Dict, Any
from enum import Enum
import logging
from devices.simulators.base_device import BaseDevice, DeviceConfig

logger = logging.getLogger(__name__)

class LockStatus(Enum):
    LOCKED   = "LOCKED"
    UNLOCKED = "UNLOCKED"
    JAMMED   = "JAMMED"

class DoorLocker(BaseDevice):
    """Smart Door Lock Actuator"""

    def __init__(self, config: DeviceConfig):
        super().__init__(config)
        self.lock_state  = LockStatus.LOCKED
        self.battery_level = 100.0
        self.is_jammed    = False
        self.lock_attempts = 0
        self.last_unlock_time = None
        self.state = {
            "lock_state": self.lock_state.value,
            "battery_level": self.battery_level,
            "is_jammed": False,
            "lock_attempts": 0,
        }

    def _drain_battery(self):
        self.battery_level -= random.uniform(0.01, 0.05)
        self.battery_level = max(0, round(self.battery_level, 2))

    def _check_jam(self):
        # 0.1% chance of jam per cycle
        if random.random() < 0.001:
            self.is_jammed = True

    def _check_and_publish_alerts(self):
        if self.battery_level < 10:
            self.publish_alert("LOW_BATTERY", "CRITICAL",
                               {"battery_level": self.battery_level, "threshold": 10})
        if self.is_jammed:
            self.publish_alert("JAM_DETECTED", "CRITICAL",
                               {"location": self.config.location})

    def _execute_lock(self) -> bool:
        if self.is_jammed:
            return False
        self.lock_state  = LockStatus.LOCKED
        self.lock_attempts += 1
        return True

    def _execute_unlock(self) -> bool:
        if self.is_jammed:
            return False
        self.lock_state = LockStatus.UNLOCKED
        self.last_unlock_time = int(time.time())
        self.lock_attempts += 1
        return True

    def generate_telemetry(self) -> Dict[str, Any]:
        self._drain_battery()
        self._check_jam()
        self.state.update({
            "lock_state": self.lock_state.value,
            "battery_level": self.battery_level,
            "is_jammed": self.is_jammed,
            "lock_attempts": self.lock_attempts,
        })
        self._check_and_publish_alerts()
        return {
            "sensor_type": "door_locker",
            "lock_state": self.lock_state.value,
            "battery_level": self.battery_level,
            "is_jammed": self.is_jammed,
            "lock_attempts": self.lock_attempts,
            "last_unlock": self.last_unlock_time,
        }

    def handle_command(self, command: Dict[str, Any]):
        action     = command.get("action", "").upper()
        parameters = command.get("parameters", {})
        request_id = command.get("request_id", "unknown")

        logger.info(f"[{self.config.device_id}] CMD {action} req={request_id}")

        if action == "LOCK":
            success = self._execute_lock()
            logger.info(f"Lock: {'OK' if success else 'FAILED'}")

        elif action == "UNLOCK":
            success = self._execute_unlock()
            logger.info(f"Unlock: {'OK' if success else 'FAILED'}")

        elif action == "EMERGENCY_UNLOCK":
            self.lock_state = LockStatus.UNLOCKED
            self.is_jammed   = False
            logger.warning(f"[{self.config.device_id}] EMERGENCY UNLOCK executed!")

        elif action == "CLEAR_JAM":
            self.is_jammed = False
            logger.info(f"[{self.config.device_id}] Jam cleared")

        elif action == "RESET_BATTERY":
            self.battery_level = 100.0