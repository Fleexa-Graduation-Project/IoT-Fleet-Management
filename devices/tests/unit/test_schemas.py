import pytest
import json
import os

# Resolve schema dir relative to this file's location — always correct regardless of rootdir
BASE_DIR   = os.path.dirname(os.path.abspath(__file__))          # devices/tests/unit/
ROOT_DIR   = os.path.abspath(os.path.join(BASE_DIR, "../../../")) # project root
SCHEMA_DIR = os.path.join(ROOT_DIR, "backend", "docs", "mqtt", "schemas")

class TestSchemas:
    def test_telemetry_schema_exists(self):
        path = os.path.join(SCHEMA_DIR, "telemetry.schema.json")
        assert os.path.exists(path), f"telemetry.schema.json not found at {path}"

    def test_alert_schema_exists(self):
        path = os.path.join(SCHEMA_DIR, "alert.schema.json")
        assert os.path.exists(path), f"alert.schema.json not found at {path}"

    def test_command_schema_exists(self):
        path = os.path.join(SCHEMA_DIR, "command.schema.json")
        assert os.path.exists(path), f"command.schema.json not found at {path}"

    def test_telemetry_schema_valid_json(self):
        with open(os.path.join(SCHEMA_DIR, "telemetry.schema.json")) as f:
            schema = json.load(f)
        assert "required" in schema
        assert "device_id" in schema["required"]
        assert "timestamp" in schema["required"]
        assert "payload" in schema["required"]

    def test_alert_schema_valid_json(self):
        with open(os.path.join(SCHEMA_DIR, "alert.schema.json")) as f:
            schema = json.load(f)
        assert "required" in schema
        assert "device_id" in schema["required"]

    def test_command_schema_valid_json(self):
        with open(os.path.join(SCHEMA_DIR, "command.schema.json")) as f:
            schema = json.load(f)
        assert "required" in schema
        assert "action" in schema["required"]