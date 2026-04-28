import pytest
import sys
import os
from unittest.mock import patch, MagicMock
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../")))

from devices.simulators.sensors.temperature_sensor import TemperatureSensor
from devices.simulators.sensors.light_sensor import LightSensor
from devices.simulators.sensors.gas_sensor import GasSensor
from devices.simulators.sensors.door_sensor import DoorSensor
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
        
class TestTemperatureSensor:
    def test_instantiation(self):
        sensor = TemperatureSensor(make_config("temp-sensor-01", "temperature_sensor"))
        assert sensor is not None

    def test_generate_telemetry_returns_dict(self):
        sensor = TemperatureSensor(make_config("temp-sensor-01", "temperature_sensor"))
        telemetry = sensor.generate_telemetry()
        assert isinstance(telemetry, dict)

    def test_telemetry_has_required_fields(self):
        sensor = TemperatureSensor(make_config("temp-sensor-01", "temperature_sensor"))
        telemetry = sensor.generate_telemetry()
        assert "temp" in telemetry
        assert "humidity_percent" in telemetry
        assert "sensor_type" in telemetry

    def test_temperature_within_range(self):
        sensor = TemperatureSensor(make_config("temp-sensor-01", "temperature_sensor"))
        for _ in range(10):
            telemetry = sensor.generate_telemetry()
            assert -40 <= telemetry["temp"] <= 125

    def test_humidity_within_range(self):
        sensor = TemperatureSensor(make_config("temp-sensor-01", "temperature_sensor"))
        for _ in range(10):
            telemetry = sensor.generate_telemetry()
            assert 0 <= telemetry["humidity_percent"] <= 100

class TestLightSensor:
    def test_instantiation(self):
        sensor = LightSensor(make_config("light-sensor-01", "light_sensor"))
        assert sensor is not None

    def test_telemetry_has_required_fields(self):
        sensor = LightSensor(make_config("light-sensor-01", "light_sensor"))
        telemetry = sensor.generate_telemetry()
        assert "light_level" in telemetry
        assert "is_dark" in telemetry

    def test_lux_within_range(self):
        sensor = LightSensor(make_config("light-sensor-01", "light_sensor"))
        for _ in range(10):
            telemetry = sensor.generate_telemetry()
            assert 0 <= telemetry["light_level"] <= 1000

class TestGasSensor:
    def test_instantiation(self):
        sensor = GasSensor(make_config("gas-sensor-01", "gas_sensor"))
        assert sensor is not None

    def test_telemetry_has_required_fields(self):
        sensor = GasSensor(make_config("gas-sensor-01", "gas_sensor"))
        telemetry = sensor.generate_telemetry()
        assert "gas_level" in telemetry
        assert "co_ppm" in telemetry
        assert "lpg_ppm" in telemetry
        assert "status" in telemetry

    def test_air_quality_valid_value(self):
        sensor = GasSensor(make_config("gas-sensor-01", "gas_sensor"))
        valid = {"GOOD", "MODERATE", "POOR", "DANGEROUS"}
        for _ in range(10):
            telemetry = sensor.generate_telemetry()
            assert telemetry["status"] in valid

class TestDoorSensor:
    def test_instantiation(self):
        sensor = DoorSensor(make_config("door-sensor-01", "door_sensor"))
        assert sensor is not None

    def test_telemetry_has_required_fields(self):
        sensor = DoorSensor(make_config("door-sensor-01", "door_sensor"))
        telemetry = sensor.generate_telemetry()
        assert "open" in telemetry
        assert "intrusion_detected" in telemetry

    def test_door_status_valid_value(self):
        sensor = DoorSensor(make_config("door-sensor-01", "door_sensor"))
        for _ in range(10):
            telemetry = sensor.generate_telemetry()
            assert telemetry["open"] in {True, False}
