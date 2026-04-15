import re

with open('.github/workflows/ci-cd.yml', 'r') as f:
    text = f.read()

text = text.replace('actions/checkout@v4', 'actions/checkout@v6')
text = text.replace('actions/setup-python@v5', 'actions/setup-python@v6')
text = text.replace('hashicorp/setup-terraform@v3', 'hashicorp/setup-terraform@v4')
text = text.replace('terraform_version: "1.6.0"', 'terraform_version: "1.14.8"')

# Also update the verify-deploy steps to check specific named resources
verify_iot_rules = r'''            - name: Verify IoT Rules exist
              run: |
                  aws iot list-topic-rules --region us-east-1 \\
                    --query 'rules[*].ruleName' --output table'''

new_verify_iot_rules = r'''            - name: Verify IoT Rules exist
              run: |
                  RULES=$(aws iot list-topic-rules --region us-east-1 --query 'rules[*].ruleName' --output text)
                  echo "$RULES"
                  echo "$RULES" | grep -q "iot_fleet_telemetry_processor" || (echo "Rule iot_fleet_telemetry_processor missing!" && exit 1)
                  echo "$RULES" | grep -q "iot_fleet_alert_processor" || (echo "Rule iot_fleet_alert_processor missing!" && exit 1)'''

text = text.replace(verify_iot_rules, new_verify_iot_rules)

verify_dynamodb = r'''            - name: Verify DynamoDB tables exist
              run: |
                  aws dynamodb list-tables --region us-east-1 \\
                    --query 'TableNames' --output table'''

new_verify_dynamodb = r'''            - name: Verify DynamoDB tables exist
              run: |
                  TABLES=$(aws dynamodb list-tables --region us-east-1 --query 'TableNames' --output text)
                  echo "$TABLES"
                  echo "$TABLES" | grep -q "iot-fleet-dev-telemetry" || (echo "Table iot-fleet-dev-telemetry missing!" && exit 1)
                  echo "$TABLES" | grep -q "iot-fleet-dev-device-state" || (echo "Table iot-fleet-dev-device-state missing!" && exit 1)
                  echo "$TABLES" | grep -q "iot-fleet-dev-alerts" || (echo "Table iot-fleet-dev-alerts missing!" && exit 1)
                  echo "$TABLES" | grep -q "iot-fleet-dev-commands" || (echo "Table iot-fleet-dev-commands missing!" && exit 1)'''

text = text.replace(verify_dynamodb, new_verify_dynamodb)

verify_lambda = r'''            - name: Verify Lambda functions exist
              run: |
                  aws lambda list-functions --region us-east-1 \\
                    --query 'Functions[*].FunctionName' --output table'''

new_verify_lambda = r'''            - name: Verify Lambda functions exist
              run: |
                  FUNCS=$(aws lambda list-functions --region us-east-1 --query 'Functions[*].FunctionName' --output text)
                  echo "$FUNCS"
                  echo "$FUNCS" | grep -q "processing_main_lambda" || (echo "Function processing_main_lambda missing!" && exit 1)
                  echo "$FUNCS" | grep -q "iot-fleet-dev-iot-ingestion" || (echo "Function iot-fleet-dev-iot-ingestion missing!" && exit 1)'''

text = text.replace(verify_lambda, new_verify_lambda)

with open('.github/workflows/ci-cd.yml', 'w') as f:
    f.write(text)

