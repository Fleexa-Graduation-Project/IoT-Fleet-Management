"""
AWS Integration Tests for Fleexa IoT Fleet Management.
Verifies real AWS infrastructure provisioned by Terraform.

Run:  python -m pytest devices/tests/integration/ -m integration -v
Requires: AWS credentials exported in terminal (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
"""

import os
import ssl
import json
import time
import pytest
import boto3
from boto3.dynamodb.conditions import Key

# ── Config — matches exact Terraform variable defaults ─────────────────────
AWS_REGION         = os.environ.get("AWS_REGION", "us-east-1")
TELEMETRY_TABLE    = os.environ.get("TELEMETRY_TABLE",    "iot-fleet-dev-telemetry")
DEVICE_STATE_TABLE = os.environ.get("DEVICE_STATE_TABLE", "iot-fleet-dev-device-state")
ALERTS_TABLE       = os.environ.get("ALERTS_TABLE",       "iot-fleet-dev-alerts")
COMMANDS_TABLE     = os.environ.get("COMMANDS_TABLE",     "iot-fleet-dev-commands")
LAMBDA_NAME        = os.environ.get("LAMBDA_NAME",        "processing_main_lambda")
API_SERVICE_NAME   = os.environ.get("API_SERVICE_NAME",   "iot-fleet-dev-api-service")
MQTT_ENDPOINT      = os.environ.get("MQTT_ENDPOINT",      "")
CA_CERT            = os.environ.get("CA_CERT_PATH",       "certs/AmazonRootCA1.pem")
CLIENT_CERT        = os.environ.get("CLIENT_CERT_PATH",   "")
CLIENT_KEY         = os.environ.get("CLIENT_KEY_PATH",    "")
TEST_DEVICE_ID     = "integration-test-device-01"

# IoT rule name pattern: project_name with dashes replaced → iot_fleet
TELEMETRY_RULE_NAME = "iot_fleet_telemetry_processor"
ALERT_RULE_NAME     = "iot_fleet_alert_processor"


# ── Fixtures ───────────────────────────────────────────────────────────────

@pytest.fixture(scope="module")
def ddb():
    return boto3.resource("dynamodb", region_name=AWS_REGION)

@pytest.fixture(scope="module")
def lambda_client():
    return boto3.client("lambda", region_name=AWS_REGION)

@pytest.fixture(scope="module")
def iot_client():
    return boto3.client("iot", region_name=AWS_REGION)


# ── 1. Infrastructure Existence Tests ─────────────────────────────────────
# These are pure read-only AWS API calls. No certs needed. Always safe to run.

@pytest.mark.integration
class TestInfrastructureExists:

    def test_dynamodb_telemetry_table_active(self, ddb):
        table = ddb.Table(TELEMETRY_TABLE)
        assert table.table_status in ("ACTIVE", "UPDATING"), \
            f"Table '{TELEMETRY_TABLE}' not ACTIVE — got: {table.table_status}"

    def test_dynamodb_device_state_table_active(self, ddb):
        table = ddb.Table(DEVICE_STATE_TABLE)
        assert table.table_status in ("ACTIVE", "UPDATING"), \
            f"Table '{DEVICE_STATE_TABLE}' not ACTIVE — got: {table.table_status}"

    def test_dynamodb_alerts_table_active(self, ddb):
        table = ddb.Table(ALERTS_TABLE)
        assert table.table_status in ("ACTIVE", "UPDATING"), \
            f"Table '{ALERTS_TABLE}' not ACTIVE — got: {table.table_status}"

    def test_dynamodb_commands_table_active(self, ddb):
        table = ddb.Table(COMMANDS_TABLE)
        assert table.table_status in ("ACTIVE", "UPDATING"), \
            f"Table '{COMMANDS_TABLE}' not ACTIVE — got: {table.table_status}"

    def test_lambda_ingestion_exists_and_active(self, lambda_client):
        resp = lambda_client.get_function(FunctionName=LAMBDA_NAME)
        state = resp["Configuration"]["State"]
        assert state == "Active", \
            f"Lambda '{LAMBDA_NAME}' exists but state is: {state}"

    def test_lambda_api_service_exists_and_active(self, lambda_client):
        resp = lambda_client.get_function(FunctionName=API_SERVICE_NAME)
        state = resp["Configuration"]["State"]
        assert state == "Active", \
            f"Lambda '{API_SERVICE_NAME}' exists but state is: {state}"

    def test_lambda_ingestion_runtime_is_go(self, lambda_client):
        resp = lambda_client.get_function(FunctionName=LAMBDA_NAME)
        runtime = resp["Configuration"]["Runtime"]
        assert "provided" in runtime, \
            f"Expected Go runtime (provided.al2/al2023), got: {runtime}"

    def test_iot_telemetry_rule_exists_and_enabled(self, iot_client):
        resp = iot_client.get_topic_rule(ruleName=TELEMETRY_RULE_NAME)
        rule = resp["rule"]
        assert rule["ruleDisabled"] is False, \
            f"Rule '{TELEMETRY_RULE_NAME}' exists but is DISABLED"

    def test_iot_alert_rule_exists_and_enabled(self, iot_client):
        resp = iot_client.get_topic_rule(ruleName=ALERT_RULE_NAME)
        rule = resp["rule"]
        assert rule["ruleDisabled"] is False, \
            f"Rule '{ALERT_RULE_NAME}' exists but is DISABLED"

    def test_iot_telemetry_rule_sql_correct(self, iot_client):
        resp = iot_client.get_topic_rule(ruleName=TELEMETRY_RULE_NAME)
        sql = resp["rule"]["sql"]
        assert "devices/+/telemetry" in sql, \
            f"Telemetry rule SQL wrong — got: {sql}"

    def test_iot_ca_certificate_active(self, iot_client):
        certs = iot_client.list_ca_certificates()["certificates"]
        assert len(certs) > 0, "No CA certificates registered in AWS IoT Core"
        active = [c for c in certs if c["status"] == "ACTIVE"]
        assert len(active) > 0, \
            f"CA certificate exists but is NOT ACTIVE — status: {certs[0]['status']}"


# ── 2. Lambda Direct Invocation Test ──────────────────────────────────────
# Invokes the Lambda directly (bypasses MQTT) — no certs needed.
# Verifies the full Lambda → DynamoDB write chain works.

@pytest.mark.integration
class TestLambdaDirectInvocation:

    def test_lambda_processes_telemetry_event(self, lambda_client, ddb):
        """
        Directly invoke processing_main_lambda with a fake IoT telemetry event.
        Then confirm the record landed in DynamoDB.
        """
        timestamp = int(time.time())
        payload = {
            "topic": f"devices/{TEST_DEVICE_ID}/telemetry",
            "payload": {
                "device_id": TEST_DEVICE_ID,
                "timestamp": timestamp,
                "type":      "temp-sensor",
                "payload": {
                    "temp": 24.5,
                    "humidity":    58,
                    "unit":        "celsius"
                }
            }
        }

        resp = lambda_client.invoke(
            FunctionName=LAMBDA_NAME,
            InvocationType="RequestResponse",   # synchronous
            Payload=json.dumps(payload).encode()
        )

        # 1. Lambda must not crash
        assert resp["StatusCode"] == 200, \
            f"Lambda returned HTTP {resp['StatusCode']}"

        # 2. No function error
        assert "FunctionError" not in resp, \
            f"Lambda threw error: {resp.get('FunctionError')} — " \
            f"payload: {resp['Payload'].read().decode()}"

        # 3. Record must exist in DynamoDB within 3 seconds
        time.sleep(3)
        table = ddb.Table(TELEMETRY_TABLE)
        result = table.get_item(Key={
            "device_id": TEST_DEVICE_ID,
            "timestamp": timestamp
        })
        assert "Item" in result, \
            f"Lambda ran OK but telemetry record not found in DynamoDB " \
            f"for device={TEST_DEVICE_ID} timestamp={timestamp}"

    def test_lambda_updates_device_state(self, ddb):
        """After invocation above, device_state table must have this device."""
        time.sleep(2)
        table = ddb.Table(DEVICE_STATE_TABLE)
        result = table.get_item(Key={"device_id": TEST_DEVICE_ID})
        assert "Item" in result, \
            f"Device state not updated for {TEST_DEVICE_ID}"
        assert result["Item"]["status"] == "ONLINE"

    def test_lambda_writes_alert_on_high_temp(self, lambda_client, ddb):
        """
        Invoke Lambda with temperature=45 (above 40° threshold).
        Alert must appear in alerts table.
        """
        timestamp = int(time.time()) + 1
        payload = {
            "topic": f"devices/{TEST_DEVICE_ID}/alerts",
            "payload": {
                "device_id": TEST_DEVICE_ID,
                "timestamp": timestamp,
                "type":      "temp-sensor",
                "payload": {
                    "severity": "HIGH",
                    "temp": 45.0,
                    "unit":        "celsius"
                }
            }
        }

        resp = lambda_client.invoke(
            FunctionName=LAMBDA_NAME,
            InvocationType="RequestResponse",
            Payload=json.dumps(payload).encode()
        )
        
        raw = resp['Payload'].read().decode('utf-8')
        response_payload = json.loads(raw) if raw else None

        # Lambda returns null body on success — only fail if there's an actual error
        if response_payload and "errorMessage" in response_payload:
            pytest.fail(f"Lambda Error: {response_payload}")

        assert resp["StatusCode"] == 200
        assert "FunctionError" not in resp

        time.sleep(3)
        table = ddb.Table(ALERTS_TABLE)
        time.sleep(3) # Wait for dynamo index
        result = table.scan(
            FilterExpression=Key("device_id").eq(TEST_DEVICE_ID)
        )
        alerts = result.get("Items", [])
        high_temp_alerts = alerts
        assert len(high_temp_alerts) > 0, \
            f"Expected HIGH_TEMP alert in DynamoDB but found: {alerts}"

    def test_lambda_no_alert_on_normal_temp(self, lambda_client, ddb):
        """
        Invoke Lambda with normal temperature (22°C).
        No new HIGH_TEMP alert should be written for this timestamp.
        """
        timestamp = int(time.time()) + 2
        payload = {
            "topic": f"devices/{TEST_DEVICE_ID}/telemetry",
            "payload": {
                "device_id": TEST_DEVICE_ID,
                "timestamp": timestamp,
                "type":      "temp-sensor",
                "payload": {
                    "temp": 22.0,
                    "unit":        "celsius"
                }
            }
        }

        lambda_client.invoke(
            FunctionName=LAMBDA_NAME,
            InvocationType="RequestResponse",
            Payload=json.dumps(payload).encode()
        )
        time.sleep(3)

        table = ddb.Table(ALERTS_TABLE)
        result = table.scan(
            FilterExpression=Key("device_id").eq(TEST_DEVICE_ID) & Key("timestamp").eq(timestamp)
        )
        assert len(result.get("Items", [])) == 0, \
            "Unexpected alert written for normal temperature (22°C)"


# ── 3. Full E2E MQTT Test ──────────────────────────────────────────────────
# Requires cert files. Auto-skipped if certs are not present.
# This is the true prod smoke test: device → MQTT → IoT Core → Rule → Lambda → DynamoDB

@pytest.mark.integration
@pytest.mark.skipif(
    not os.path.exists(CA_CERT) or not CLIENT_CERT or not CLIENT_KEY,
    reason="Cert files not present — skipping MQTT E2E test. Set CA_CERT_PATH, CLIENT_CERT_PATH, CLIENT_KEY_PATH."
)
class TestEndToEndMQTTFlow:

    def test_mqtt_publish_reaches_dynamodb(self, ddb):
        try:
            import paho.mqtt.client as mqtt
        except ImportError:
            pytest.skip("paho-mqtt not installed — run: pip install paho-mqtt")

        timestamp = int(time.time())
        payload = {
            "device_id": TEST_DEVICE_ID,
            "timestamp": timestamp,
            "type":      "sensor",
            "payload":   {"temperature": 23.0, "humidity": 60, "unit": "celsius"}
        }

        connected = {"ok": False}
        published = {"ok": False}

        def on_connect(client, userdata, flags, rc):
            connected["ok"] = (rc == 0)

        def on_publish(client, userdata, mid):
            published["ok"] = True

        client = mqtt.Client(client_id=TEST_DEVICE_ID, protocol=mqtt.MQTTv311)
        client.tls_set(
            ca_certs=CA_CERT,
            certfile=CLIENT_CERT,
            keyfile=CLIENT_KEY,
            cert_reqs=ssl.CERT_REQUIRED,
            tls_version=ssl.PROTOCOL_TLSv1_2
        )
        client.on_connect = on_connect
        client.on_publish = on_publish
        client.connect(MQTT_ENDPOINT, 8883, keepalive=10)
        client.loop_start()
        time.sleep(3)

        assert connected["ok"], \
            f"Failed to connect to AWS IoT Core at {MQTT_ENDPOINT}:8883"

        topic = f"devices/{TEST_DEVICE_ID}/telemetry"
        client.publish(topic, json.dumps(payload), qos=1)
        time.sleep(8)  # allow full chain: IoT Rule → Lambda → DynamoDB
        client.loop_stop()
        client.disconnect()

        assert published["ok"], "MQTT publish did not complete"

        table = ddb.Table(TELEMETRY_TABLE)
        result = table.get_item(Key={
            "device_id": TEST_DEVICE_ID,
            "timestamp": timestamp
        })
        assert "Item" in result, \
            f"MQTT published but record NOT in DynamoDB — " \
            f"check IoT Rule is enabled and Lambda has correct DynamoDB permissions"