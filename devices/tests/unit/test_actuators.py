import pytest
from unittest.mock import MagicMock
from devices.simulators.base_device import DeviceConfig
from devices.simulators.actuators.door_locker import DoorLocker

def test_door_locker_initialization(mock_device_config, mock_mqtt_client, mock_schema_validator):
    actuator = DoorLocker(mock_device_config)
    assert actuator.config.device_id == "test-device-1"
    assert actuator.status.value == "INACTIVE"
    assert "lock_state" in actuator.state
    assert actuator.state["lock_state"] == "LOCKED"

def test_door_locker_handle_command(mock_device_config, mock_mqtt_client, mock_schema_validator):
    actuator = DoorLocker(mock_device_config)
    # Simulate a command
    command = {"request_id": "test-req", "action": "UNLOCK"}
    actuator.handle_command(command)
    assert actuator.state["lock_state"] == "UNLOCKED"
