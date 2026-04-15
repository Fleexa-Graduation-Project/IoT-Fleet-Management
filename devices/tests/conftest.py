import pytest
from unittest.mock import MagicMock
from devices.simulators.base_device import DeviceConfig

@pytest.fixture
def mock_mqtt_client(mocker):
    # Mocking the Paho MQTT Client to prevent actual network calls during tests
    return mocker.patch('paho.mqtt.client.Client')

@pytest.fixture
def mock_device_config():
    return DeviceConfig(
        device_id="test-device-1",
        device_name="Test Device",
        device_type="sensor",
        location="Test Lab",
        sensor_type="test",
        ca_cert="dummy-ca.pem",
        client_cert="dummy-cert.pem",
        client_key="dummy-key.pem"
    )

@pytest.fixture
def mock_schema_validator(mocker):
    # Mock the schema validator to always return True for tests
    mock_sv = mocker.patch('devices.simulators.base_device.get_validator')
    mock_instance = MagicMock()
    mock_instance.validate_telemetry.return_value = True
    mock_instance.validate_alert.return_value = True
    mock_instance.validate_command.return_value = True
    mock_sv.return_value = mock_instance
    return mock_instance
