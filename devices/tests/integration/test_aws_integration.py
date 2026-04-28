"""
AWS Integration Tests — run against real provisioned infrastructure.
Requires: AWS creds, IoT endpoint, certs in env/files.
Gated in CI by: pytest -m integration (only runs on main push after deploy)
"""
import pytest
import boto3
import json
import time
import os
import ssl
import paho.mqtt.client as mqtt

AWS_REGION        = os.environ.get("AWS_REGION", "us-east-1")
MQTT_ENDPOINT     = os.environ.get("MQTT_ENDPOINT", "")       # from terraform output
TELEMETRY_TABLE   = os.environ.get("TELEMETRY_TABLE", "iot-fleet-dev-telemetry")
DEVICE_STATE_TABLE= os.environ.get("DEVICE_STATE_TABLE", "iot-fleet-dev-device-state")
ALERTS_TABLE      = os.environ.get("ALERTS_TABLE", "iot-fleet-dev-alerts")
TEST_DEVICE_ID    = "integration-test-device-01"
CA_CERT           = os.environ.get("CA_CERT_PATH", "certs/AmazonRootCA1.pem")
CLIENT_CERT       = os.environ.get("CLIENT_CERT_PATH", "")
CLIENT_KEY        = os.environ.get("CLIENT_KEY_PATH", "")


# ── Fixtures ──────────────────────────────────────────────────────────────────

@pytest.fixture(scope="module")
def dynamodb():
    return boto3.resource("dynamodb", region_name=AWS_REGION)

@pytest.fixture(scope="module")
def iot_client():
    return boto3.client("iot", region_name=AWS_REGION)

@pytest.fixture(scope="module")
def iot_data_client():
    return boto3.client("iot-data", region_name=AWS_REGION,
                        endpoint_url=f"https://{MQTT_ENDPOINT}")


# ── Infrastructure Existence Tests ────────────────────────────────────────────

@pytest.mark.integration
class TestInfrastructureExists:
    """Verify all required AWS resources were created by Terraform."""

    def test_dynamodb_telemetry_table_exists(self, dynamodb):
        table = dynamodb.Table(TELEMETRY_TABLE)
        assert table.table_status in ("ACTIVE", "UPDATING"), \
            f"Telemetry table not ACTIVE — got: {table.table_status}"

    def test_dynamodb_device_state_table_exists(self, dynamodb):
        table = dynamodb.Table(DEVICE_STATE_TABLE)
        assert table.table_status in ("ACTIVE", "UPDATING")

    def test_dynamodb_alerts_table_exists(self, dynamodb):
        table = dynamodb.Table(ALERTS_TABLE)
        assert table.table_status in ("ACTIVE", "UPDATING")

    def test_iot_rules_exist(self, iot_client):
        rules = iot_client.list_topic_rules()["rules"]
        rule_names = [r["ruleName"] for r in rules]
        assert any("telemetry" in n.lower() for n in rule_names), \
            f"No telemetry IoT rule found. Rules: {rule_names}"

    def test_lambda_telemetry_processor_exists(self):
        lc = boto3.client("lambda", region_name=AWS_REGION)
        funcs = lc.list_functions()["Functions"]
        names = [f["FunctionName"] for f in funcs]
        assert any("telemetry" in n.lower() for n in names), \
            f"No telemetry Lambda found. Functions: {names}"

    def test_iot_policy_exists(self, iot_client):
        policies = iot_client.list_policies()["policies"]
        names = [p["policyName"] for p in policies]
        assert any("fleet" in n.lower() or "device" in n.lower() for n in names), \
            f"No device IoT policy found. Policies: {names}"


# ── End-to-End Data Flow Test ─────────────────────────────────────────────────

@pytest.mark.integration
@pytest.mark.skipif(
    not os.path.exists(CA_CERT) or not CLIENT_CERT or not CLIENT_KEY,
    reason="Cert files not available — skipping MQTT publish test"
)
class TestEndToEndDataFlow:
    """
    Publish real MQTT telemetry → verify it lands in DynamoDB.
    This is the full prod smoke test.
    """

    def test_publish_telemetry_reaches_dynamodb(self, dynamodb):
        timestamp = int(time.time())
        payload = {
            "device_id": TEST_DEVICE_ID,
            "timestamp": timestamp,
            "type": "sensor",
            "payload": {
                "temperature": 22.5,
                "humidity": 55,
                "unit": "celsius"
            }
        }

        # 1. Publish via MQTT
        connected = {"status": False}

        def on_connect(client, userdata, flags, rc):
            connected["status"] = (rc == 0)

        client = mqtt.Client(client_id=TEST_DEVICE_ID, protocol=mqtt.MQTTv311)
        client.tls_set(ca_certs=CA_CERT, certfile=CLIENT_CERT, keyfile=CLIENT_KEY,
                       cert_reqs=ssl.CERT_REQUIRED, tls_version=ssl.PROTOCOL_TLSv1_2)
        client.on_connect = on_connect
        client.connect(MQTT_ENDPOINT, 8883, keepalive=10)
        client.loop_start()
        time.sleep(3)

        assert connected["status"], "Failed to connect to AWS IoT Core via MQTT"

        topic = f"devices/{TEST_DEVICE_ID}/telemetry"
        client.publish(topic, json.dumps(payload), qos=1)
        time.sleep(5)  # allow IoT Rule → Lambda → DynamoDB pipeline to complete
        client.loop_stop()
        client.disconnect()

        # 2. Verify record appeared in DynamoDB
        table = dynamodb.Table(TELEMETRY_TABLE)
        response = table.get_item(Key={
            "device_id": TEST_DEVICE_ID,
            "timestamp": timestamp
        })
        assert "Item" in response, \
            f"Telemetry record not found in DynamoDB for device {TEST_DEVICE_ID} @ {timestamp}"

        item = response["Item"]
        assert item["device_id"] == TEST_DEVICE_ID
        assert "payload" in item

    def test_device_state_updated_after_publish(self, dynamodb):
        """After publish, device_state table should have latest state."""
        time.sleep(3)
        table = dynamodb.Table(DEVICE_STATE_TABLE)
        response = table.get_item(Key={"device_id": TEST_DEVICE_ID})
        assert "Item" in response, \
            f"Device state not found for {TEST_DEVICE_ID} — Lambda may not have updated it"
        assert response["Item"]["status"] == "ACTIVE"

    def test_alert_not_written_for_normal_telemetry(self, dynamodb):
        """Normal temperature (22.5°C) should NOT produce an alert."""
        table = dynamodb.Table(ALERTS_TABLE)
        response = table.query(
            KeyConditionExpression=boto3.dynamodb.conditions.Key("device_id").eq(TEST_DEVICE_ID)
        )
        # Should have zero or only pre-existing alerts — none from our normal-range publish
        for item in response.get("Items", []):
            assert item.get("status") != "HIGH_TEMP", \
                "Unexpected HIGH_TEMP alert for normal temperature value"