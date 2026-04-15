import re

with open('.github/workflows/ci-cd.yml', 'r') as f:
    text = f.read()

# Fallback string replace just in case the multi-line exact match failed due to whitespace/newlines on Python read.
text = re.sub(
    pattern=r"aws iot list-topic-rules --region us-east-1\s*--query 'rules\[\*\].ruleName' --output table",
    repl=r"""RULES=$(aws iot list-topic-rules --region us-east-1 --query 'rules[*].ruleName' --output text)
                  echo "$RULES"
                  echo "$RULES" | grep -q "iot_fleet_telemetry_processor" || (echo "Rule iot_fleet_telemetry_processor missing!" && exit 1)
                  echo "$RULES" | grep -q "iot_fleet_alert_processor" || (echo "Rule iot_fleet_alert_processor missing!" && exit 1)""",
    string=text
)

text = re.sub(
    pattern=r"aws dynamodb list-tables --region us-east-1\s*--query 'TableNames' --output table",
    repl=r"""TABLES=$(aws dynamodb list-tables --region us-east-1 --query 'TableNames' --output text)
                  echo "$TABLES"
                  echo "$TABLES" | grep -q "iot-fleet-dev-telemetry" || (echo "Table iot-fleet-dev-telemetry missing!" && exit 1)
                  echo "$TABLES" | grep -q "iot-fleet-dev-device-state" || (echo "Table iot-fleet-dev-device-state missing!" && exit 1)
                  echo "$TABLES" | grep -q "iot-fleet-dev-alerts" || (echo "Table iot-fleet-dev-alerts missing!" && exit 1)
                  echo "$TABLES" | grep -q "iot-fleet-dev-commands" || (echo "Table iot-fleet-dev-commands missing!" && exit 1)""",
    string=text
)

text = re.sub(
    pattern=r"aws lambda list-functions --region us-east-1\s*--query 'Functions\[\*\].FunctionName' --output table",
    repl=r"""FUNCS=$(aws lambda list-functions --region us-east-1 --query 'Functions[*].FunctionName' --output text)
                  echo "$FUNCS"
                  echo "$FUNCS" | grep -q "processing_main_lambda" || (echo "Function processing_main_lambda missing!" && exit 1)
                  echo "$FUNCS" | grep -q "iot-fleet-dev-iot-ingestion" || (echo "Function iot-fleet-dev-iot-ingestion missing!" && exit 1)""",
    string=text
)

with open('.github/workflows/ci-cd.yml', 'w') as f:
    f.write(text)

