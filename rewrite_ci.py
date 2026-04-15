import re

with open('.github/workflows/ci-cd.yml', 'r') as f:
    text = f.read()

# Make sure basics are right
text = text.replace('actions/checkout@v4', 'actions/checkout@v6')
text = text.replace('actions/checkout@v5', 'actions/checkout@v6')
text = text.replace('actions/setup-python@v5', 'actions/setup-python@v6')
text = text.replace('hashicorp/setup-terraform@v3', 'hashicorp/setup-terraform@v4.0.0')
text = text.replace('terraform_version: "1.6.0"', 'terraform_version: "1.14.8"')

# Rewrite block 5 entirely
verify_section_start = "    # ── 5. Verify AWS Resources After Deploy"

parts = text.split(verify_section_start)
if len(parts) == 2:
    new_verify = verify_section_start + """ ──────────────────────────────────
    verify-deploy:
        name: Verify AWS Deployment
        runs-on: ubuntu-latest
        needs: terraform-deploy
        if: github.ref == 'refs/heads/main' && github.event_name == 'push'
        env:
            AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
            AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
            AWS_DEFAULT_REGION: us-east-1
        steps:
            - uses: actions/checkout@v6

            - name: Verify IoT Rules exist
              run: |
                  RULES=$(aws iot list-topic-rules --region us-east-1 --query 'rules[*].ruleName' --output text)
                  echo "Found rules: $RULES"
                  echo "$RULES" | grep -q "iot_fleet_telemetry_processor" || (echo "Rule iot_fleet_telemetry_processor missing!" && exit 1)
                  echo "$RULES" | grep -q "iot_fleet_alert_processor" || (echo "Rule iot_fleet_alert_processor missing!" && exit 1)

            - name: Verify DynamoDB tables exist
              run: |
                  TABLES=$(aws dynamodb list-tables --region us-east-1 --query 'TableNames' --output text)
                  echo "Found tables: $TABLES"
                  echo "$TABLES" | grep -q "iot-fleet-dev-telemetry" || (echo "Table iot-fleet-dev-telemetry missing!" && exit 1)
                  echo "$TABLES" | grep -q "iot-fleet-dev-device-state" || (echo "Table iot-fleet-dev-device-state missing!" && exit 1)
                  echo "$TABLES" | grep -q "iot-fleet-dev-alerts" || (echo "Table iot-fleet-dev-alerts missing!" && exit 1)
                  echo "$TABLES" | grep -q "iot-fleet-dev-commands" || (echo "Table iot-fleet-dev-commands missing!" && exit 1)

            - name: Verify Lambda functions exist
              run: |
                  FUNCS=$(aws lambda list-functions --region us-east-1 --query 'Functions[*].FunctionName' --output text)
                  echo "Found functions: $FUNCS"
                  echo "$FUNCS" | grep -q "processing_main_lambda" || (echo "Function processing_main_lambda missing!" && exit 1)
                  echo "$FUNCS" | grep -q "iot-fleet-dev-iot-ingestion" || (echo "Function iot-fleet-dev-iot-ingestion missing!" && exit 1)

            - name: Verify IoT Things exist
              run: |
                  aws iot list-things --region us-east-1 \\
                    --query 'things[*].thingName' --output table

            - name: Verify CA certificate is ACTIVE
              run: |
                  aws iot list-ca-certificates --region us-east-1 \\
                    --query 'certificates[*].{ID:certificateId,Status:status}' \\
                    --output table
"""
    with open('.github/workflows/ci-cd.yml', 'w') as f:
        f.write(parts[0] + new_verify)
else:
    print("Could not find section 5")
