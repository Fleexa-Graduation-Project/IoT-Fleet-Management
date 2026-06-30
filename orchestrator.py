# orchestrator.py
import os
import time
import random

def build_config_from_env():
    from devices.simulators.base_device import DeviceConfig

    device_id = os.environ["DEVICE_ID"]

    # The AWS IoT policy uses the policy variable:
    #   ${iot:Connection.Thing.ThingName}
    # This means the MQTT client_id MUST exactly match the registered
    # Thing Name (e.g. "temp-sensor-01"). Any suffix or modification
    mqtt_client_id = device_id

    # Pick a random user_id
    # Attempt 1: Fetch from DynamoDB
    user_ids = []
    try:
        import boto3
        region = os.environ.get("AWS_REGION", "us-east-1")
        dynamodb = boto3.client("dynamodb", region_name=region)
        # Using a paginator just in case, though scan is fine for small tables
        paginator = dynamodb.get_paginator('scan')
        for page in paginator.paginate(TableName="iot-fleet_Users", ProjectionExpression="user_id"):
            for item in page.get('Items', []):
                if 'user_id' in item and 'S' in item['user_id']:
                    user_ids.append(item['user_id']['S'])
    except Exception as e:
        print(f"Warning: Failed to fetch users from DynamoDB ({e}). Falling back to env variables.")

    # Attempt 2: Fallback to USER_IDS from env
    if not user_ids:
        user_ids_str = os.environ.get("USER_IDS", "")
        if user_ids_str:
            user_ids = [uid.strip() for uid in user_ids_str.split(",") if uid.strip()]

    # Attempt 3: Fallback to single USER_ID
    if user_ids:
        user_id = random.choice(user_ids)
    else:
        user_id = os.environ.get("USER_ID", "")

    if not user_ids and not user_id:
        import sys
        print("❌ CRITICAL: No users fetched from DynamoDB and no fallback USER_IDS/USER_ID provided. Cannot start simulator.")
        sys.exit(1)

    return DeviceConfig(
        device_id        = device_id,
        user_id          = user_id,
        user_ids         = user_ids,
        device_name      = os.environ["DEVICE_NAME"],
        device_type      = os.environ["DEVICE_TYPE"],
        location         = os.environ.get("DEVICE_LOCATION", "Unknown"),
        sensor_type      = os.environ["DEVICE_TYPE"],
        ca_cert          = os.environ.get("CA_CERT",     f"/app/certs/{device_id}/AmazonRootCA1.pem"),
        client_cert      = os.environ.get("CLIENT_CERT", f"/app/certs/{device_id}/device.pem.crt"),
        client_key       = os.environ.get("CLIENT_KEY",  f"/app/certs/{device_id}/private.pem.key"),
        mqtt_broker      = os.environ.get("MQTT_BROKER", "localhost"),
        mqtt_port        = int(os.environ.get("MQTT_PORT", 8883)),
        publish_interval = int(os.environ.get("PUBLISH_INTERVAL", 30)),
        clean_session    = os.environ.get("MQTT_CLEAN_SESSION", "true").lower() == "true",
        keepalive        = int(os.environ.get("MQTT_KEEPALIVE", 30)),
        mqtt_client_id   = mqtt_client_id,
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
    elif device_type in ["ac_curtain", "ac-actuator"]:
        from devices.simulators.actuators.ac_curtain_actuator import ACCurtainActuator
        return ACCurtainActuator
    else:
        raise ValueError(f"Unknown DEVICE_TYPE: {device_type}")


if __name__ == "__main__":
    # Honour STARTUP_DELAY so containers don't all hammer AWS IoT Core
    # simultaneously at boot. Each device has a deterministic base delay
    # (set in docker-compose.yml) plus a small random jitter (0-2 s) to
    # avoid thundering-herd reconnect bursts after a broker-forced disconnect.
    startup_delay = int(os.environ.get("STARTUP_DELAY", 0))
    jitter        = random.uniform(0, 2)
    total_delay   = startup_delay + jitter

    if total_delay > 0:
        import logging
        logging.basicConfig(level=logging.INFO,
                            format='%(asctime)s - orchestrator - INFO - %(message)s')
        logging.getLogger(__name__).info(
            f"⏳ Startup delay {total_delay:.1f}s "
            f"(base={startup_delay}s + jitter={jitter:.1f}s)"
        )
        time.sleep(total_delay)

    config = build_config_from_env()
    DeviceClass = get_device_class(config.device_type)
    device = DeviceClass(config)
    device.connect()
    device.run()
