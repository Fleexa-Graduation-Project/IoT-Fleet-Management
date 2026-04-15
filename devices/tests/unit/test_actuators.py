import pytest
import sys
import os
from unittest.mock import patch, MagicMock
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../")))

from devices.simulators.actuators.door_locker import DoorLocker
from devices.simulators.actuators.ac_curtain_actuator import ACCurtainActuator
from devices.simulators.base_device import DeviceConfig

def make_config(device_id, device_type):
    return DeviceConfig(
        device_id=device_id,
        device_name=device_id,
        device_type=device_type,
        location="Test Room",
        sensor_type=device_type, 
        ca_cert="certs/AmazonRootCA1.pem",
        client_cert=f"certs/devices/{device_id}.crt",
        client_key=f"certs/devices/{device_id}.key",
        mqtt_broker="localhost",
        mqtt_port=8883,
        publish_interval=5,
    )

@pytest.fixture(autouse=True)
def mock_mqtt(mocker):
    with patch("devices.simulators.base_device.mqtt.Client") as mock_client:
        mock_instance = MagicMock()
        mock_client.return_value = mock_instance
        yield mock_instance
        
class TestDoorLocker:
    def test_instantiation(self):
        actuator = DoorLocker(make_config("door-locker-01", "actuator"))
        assert actuator is not None

    def test_telemetry_has_required_fields(self):
        actuator = DoorLocker(make_config("door-locker-01", "actuator"))
        telemetry = actuator.generate_telemetry()
        assert "lock_state" in telemetry
        assert "battery_level" in telemetry
        assert "is_jammed" in telemetry

    def test_initial_state_is_locked(self):
        actuator = DoorLocker(make_config("door-locker-01", "actuator"))
        telemetry = actuator.generate_telemetry()
        assert telemetry["lock_state"] == "LOCKED"

    def test_lock_command(self):
        actuator = DoorLocker(make_config("door-locker-01", "actuator"))
        actuator.handle_command({"request_id": "r1", "action": "UNLOCK", "parameters": {}})
        actuator.handle_command({"request_id": "r2", "action": "LOCK", "parameters": {}})
        telemetry = actuator.generate_telemetry()
        assert telemetry["lock_state"] == "LOCKED"

    def test_unlock_command(self):
        actuator = DoorLocker(make_config("door-locker-01", "actuator"))
        actuator.handle_command({"request_id": "r1", "action": "UNLOCK", "parameters": {}})
        telemetry = actuator.generate_telemetry()
        assert telemetry["lock_state"] == "UNLOCKED"

    def test_battery_drains_over_time(self):
        actuator = DoorLocker(make_config("door-locker-01", "actuator"))
        for _ in range(50):
            telemetry = actuator.generate_telemetry()
        assert telemetry["battery_level"] < 100.0

class TestACCurtainActuator:
    def test_instantiation(self):
        actuator = ACCurtainActuator(make_config("ac-curtain-01", "actuator"))
        assert actuator is not None

    def test_telemetry_has_required_fields(self):
        actuator = ACCurtainActuator(make_config("ac-curtain-01", "actuator"))
        telemetry = actuator.generate_telemetry()
        assert "mode" in telemetry
        assert "curtain_position_percent" in telemetry
        assert "ac_power_watts" in telemetry

    def test_set_ac_mode_command(self):
        actuator = ACCurtainActuator(make_config("ac-curtain-01", "actuator"))
        actuator.handle_command({
            "request_id": "r1",
            "action": "SET_AC_MODE",
            "parameters": {"mode": "COOL"}
        })
        telemetry = actuator.generate_telemetry()
        assert telemetry["mode"] == "COOL"

    def test_curtain_open_command(self):
        actuator = ACCurtainActuator(make_config("ac-curtain-01", "actuator"))
        actuator.handle_command({
            "request_id": "r1",
            "action": "OPEN_CURTAIN",
            "parameters": {}
        })
        telemetry = actuator.generate_telemetry()
        assert telemetry["curtain_position_percent"] == 100

    def test_curtain_close_command(self):
        actuator = ACCurtainActuator(make_config("ac-curtain-01", "actuator"))
        actuator.handle_command({
            "request_id": "r1",
            "action": "CLOSE_CURTAIN",
            "parameters": {}
        })
        telemetry = actuator.generate_telemetry()
        assert telemetry["curtain_position_percent"] == 0
