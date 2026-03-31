#!/bin/bash

# Step 1: Read inputs and static configuration.
DEVICE_ID=$1
REGION="us-east-1"
POLICY_NAME="iot-fleet-device-policy"

# Step 2: Validate required input.
if [ -z "$DEVICE_ID" ]; then
  echo "Usage: ./generate_device_cert.sh <device-id>"
  exit 1
fi

echo ">>> Generating cert for: $DEVICE_ID"

# Step 3: Generate the device private key.
openssl genrsa -out devices/${DEVICE_ID}.key 2048

# Step 4: Create a certificate signing request (CSR).
openssl req -new \
  -key devices/${DEVICE_ID}.key \
  -out devices/${DEVICE_ID}.csr \
  -subj "/C=US/ST=California/O=IoTFleet/CN=${DEVICE_ID}"

# Step 5: Sign the CSR with the local CA.
openssl x509 -req \
  -in devices/${DEVICE_ID}.csr \
  -CA ca/ca.crt \
  -CAkey ca/ca.key \
  -CAcreateserial \
  -out devices/${DEVICE_ID}.crt \
  -days 365

# Step 6: Register and activate the certificate in AWS IoT Core.
CERT_ARN=$(aws iot register-certificate \
  --certificate-pem file://devices/${DEVICE_ID}.crt \
  --ca-certificate-pem file://ca/ca.crt \
  --set-as-active \
  --region $REGION \
  --query certificateArn \
  --output text)

echo "Cert ARN: $CERT_ARN"

# Step 7: Stop if certificate registration failed.
if [ -z "$CERT_ARN" ] || [ "$CERT_ARN" == "None" ]; then
  echo "❌ Certificate registration FAILED for $DEVICE_ID — aborting"
  exit 1
fi

# Step 8: Create IoT thing (if it does not already exist).
aws iot create-thing \
  --thing-name "$DEVICE_ID" \
  --region $REGION 2>/dev/null || echo "Thing already exists, skipping"

# Step 9: Attach policy permissions to the certificate.
aws iot attach-policy \
  --policy-name "$POLICY_NAME" \
  --target "$CERT_ARN" \
  --region $REGION

# Step 10: Link the certificate principal to the IoT thing.
aws iot attach-thing-principal \
  --thing-name "$DEVICE_ID" \
  --principal "$CERT_ARN" \
  --region $REGION

echo "✅ $DEVICE_ID fully provisioned in $REGION!"