import pytest
import json
import os

SCHEMA_DIR = "../backend/docs/mqtt/schemas"

class TestSchemas:
    def test_telemetry_schema_exists(self):
        assert os.path.exists(f"{SCHEMA_DIR}/telemetry.schema.json"), \
            "telemetry.schema.json not found"

    def test_alert_schema_exists(self):
        assert os.path.exists(f"{SCHEMA_DIR}/alert.schema.json"), \
            "alert.schema.json not found"

    def test_command_schema_exists(self):
        assert os.path.exists(f"{SCHEMA_DIR}/command.schema.json"), \
            "command.schema.json not found"

    def test_telemetry_schema_valid_json(self):
        with open(f"{SCHEMA_DIR}/telemetry.schema.json") as f:
            schema = json.load(f)
        assert "required" in schema
        assert "device_id" in schema["required"]
        assert "timestamp" in schema["required"]
        assert "payload" in schema["required"]

    def test_alert_schema_valid_json(self):
        with open(f"{SCHEMA_DIR}/alert.schema.json") as f:
            schema = json.load(f)
        assert "required" in schema

    def test_command_schema_valid_json(self):
        with open(f"{SCHEMA_DIR}/command.schema.json") as f:
            schema = json.load(f)
        assert "required" in schema
        assert "action" in schema["required"]
