# orchestrator.py
import os

def build_config_from_env():
    from devices.simulators.base_device import DeviceConfig

    device_id = os.environ["DEVICE_ID"]  # e.g. "temp-sensor-01"

    return DeviceConfig(
        device_id        = device_id,
        device_name      = os.environ["DEVICE_NAME"],
        device_type      = os.environ["DEVICE_TYPE"],
        location         = os.environ.get("DEVICE_LOCATION", "Unknown"),
        sensor_type      = os.environ["DEVICE_TYPE"],
        # Each device's certs live in their own subfolder — path passed via env
        ca_cert          = os.environ.get("CA_CERT",     f"/app/certs/{device_id}/AmazonRootCA1.pem"),
        client_cert      = os.environ.get("CLIENT_CERT", f"/app/certs/{device_id}/device.pem.crt"),
        client_key       = os.environ.get("CLIENT_KEY",  f"/app/certs/{device_id}/private.pem.key"),
        mqtt_broker      = os.environ.get("MQTT_BROKER", "localhost"),
        mqtt_port        = int(os.environ.get("MQTT_PORT", 8883)),
        publish_interval = int(os.environ.get("PUBLISH_INTERVAL", 30)),
    )

def get_device_class(device_type: str):
    if device_type == "temperature_sensor":
        from devices.simulators.sensors.temperature_sensor import TemperatureSensor
        return TemperatureSensor
    elif device_type == "gas_sensor":
        from devices.simulators.sensors.gas_sensor import GasSensor
        return GasSensor
    elif device_type == "door_sensor":
        from devices.simulators.sensors.door_sensor import DoorSensor
        return DoorSensor
    elif device_type == "light_sensor":
        from devices.simulators.sensors.light_sensor import LightSensor
        return LightSensor
    elif device_type == "door_locker":
        from devices.simulators.actuators.door_locker import DoorLocker
        return DoorLocker
    elif device_type == "ac_curtain":
        from devices.simulators.actuators.ac_curtain_actuator import ACCurtainActuator
        return ACCurtainActuator
    else:
        raise ValueError(f"Unknown DEVICE_TYPE: {device_type}")

if __name__ == "__main__":
    config = build_config_from_env()
    DeviceClass = get_device_class(config.device_type)
    device = DeviceClass(config)
    device.connect()
    device.run()