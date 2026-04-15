import pytest
from unittest.mock import MagicMock
from devices.simulators.base_device import DeviceConfig
from devices.simulators.sensors.temperature_sensor import TemperatureSensor
from devices.simulators.sensors.door_sensor import DoorSensor

def test_temperature_sensor_initialization(mock_device_config, mock_mqtt_client, mock_schema_validator):
    sensor = TemperatureSensor(mock_device_config)
    assert sensor.config.device_id == "test-device-1"
    assert sensor.status.value == "INACTIVE"
    assert "temp" in sensor.state

def test_temperature_sensor_telemetry(mock_device_config, mock_mqtt_client, mock_schema_validator):
    sensor = TemperatureSensor(mock_device_config)
    telemetry = sensor.generate_telemetry()
    assert "temperature" in telemetry
    assert "humidity" in telemetry

def test_door_sensor_initialization(mock_device_config, mock_mqtt_client, mock_schema_validator):
    sensor = DoorSensor(mock_device_config)
    assert sensor.config.device_id == "test-device-1"
    assert "door_state" in sensor.state
