#!/bin/bash
DEVICE_NAME=$1
DEVICE_ID=$2

openssl genrsa -out devices/${DEVICE_NAME}.key 2048
openssl req -new -key devices/${DEVICE_NAME}.key -out devices/${DEVICE_NAME}.csr \
  -subj "/C=US/ST=California/O=IoTFleet/CN=${DEVICE_NAME}"
openssl x509 -req -in devices/${DEVICE_NAME}.csr -CA ca/ca.crt -CAkey ca/ca.key \
  -CAcreateserial -out devices/${DEVICE_NAME}.crt -days 365
echo "Certificate generated for ${DEVICE_NAME}"
