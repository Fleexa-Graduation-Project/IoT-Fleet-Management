#!/bin/bash
# Full device registration: creates Things, certs, attaches policy, saves certs locally
set -e

AWS_REGION="us-east-1"
POLICY_NAME="iot-fleet-device-policy"
THING_TYPE="iot-fleet-device-type"
CERTS_DIR="$(dirname "$0")/../../devices/certs"

mkdir -p "$CERTS_DIR"

# Download Amazon Root CA once
if [ ! -f "$CERTS_DIR/AmazonRootCA1.pem" ]; then
  echo "Downloading Amazon Root CA..."
  curl -s https://www.amazontrust.com/repository/AmazonRootCA1.pem \
    -o "$CERTS_DIR/AmazonRootCA1.pem"
fi

DEVICES=(
  "temp-sensor-01"
  "light-sensor-01"
  "gas-sensor-01"
  "door-sensor-01"
  "ac-curtain-01"
  "door-locker-01"
)

for DEVICE_ID in "${DEVICES[@]}"; do
  echo ""
  echo "━━━ Registering: $DEVICE_ID ━━━"

  # 1. Create Thing
  aws iot create-thing \
    --thing-name "$DEVICE_ID" \
    --thing-type-name "$THING_TYPE" \
    --attribute-payload '{"attributes":{"managedBy":"terraform-script","version":"1.0"}}' \
    --region "$AWS_REGION" \
    --output json > /dev/null 2>&1 && echo "  ✓ Thing created" || echo "  ℹ Thing already exists"

  # 2. Create cert + keys
  DEVICE_CERT_DIR="$CERTS_DIR/$DEVICE_ID"
  mkdir -p "$DEVICE_CERT_DIR"

  CERT_JSON=$(aws iot create-keys-and-certificate \
    --set-as-active \
    --region "$AWS_REGION" \
    --output json)

  CERT_ARN=$(echo "$CERT_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['certificateArn'])")
  CERT_ID=$(echo "$CERT_JSON"  | python3 -c "import sys,json; print(json.load(sys.stdin)['certificateId'])")

  echo "$CERT_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['certificatePem'])"          > "$DEVICE_CERT_DIR/device.pem.crt"
  echo "$CERT_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['keyPair']['PublicKey'])"    > "$DEVICE_CERT_DIR/public.pem.key"
  echo "$CERT_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['keyPair']['PrivateKey'])"   > "$DEVICE_CERT_DIR/private.pem.key"
  cp "$CERTS_DIR/AmazonRootCA1.pem" "$DEVICE_CERT_DIR/AmazonRootCA1.pem"

  echo "  ✓ Cert created: $CERT_ID"

  # 3. Attach policy to cert
  aws iot attach-policy \
    --policy-name "$POLICY_NAME" \
    --target "$CERT_ARN" \
    --region "$AWS_REGION"
  echo "  ✓ Policy attached"

  # 4. Attach cert to Thing
  aws iot attach-thing-principal \
    --thing-name "$DEVICE_ID" \
    --principal "$CERT_ARN" \
    --region "$AWS_REGION"
  echo "  ✓ Cert attached to Thing"

  echo "  📁 Certs saved to: $DEVICE_CERT_DIR/"
done

# Get MQTT endpoint
ENDPOINT=$(aws iot describe-endpoint \
  --endpoint-type iot:Data-ATS \
  --region "$AWS_REGION" \
  --query endpointAddress \
  --output text)

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ All 6 devices registered successfully!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "MQTT Endpoint: $ENDPOINT"
echo "Cert location: $CERTS_DIR/<device-id>/"
echo ""
echo "Add to your .env or export before running simulators:"
echo "  export MQTT_ENDPOINT=$ENDPOINT"