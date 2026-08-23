#!/bin/bash
# Prints a Terraform plan for a given environment (dev/staging/prod) without applying it
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/../terraform"

ENVIRONMENT="${1:-dev}"
shift || true

TFVARS_FILE="environments/${ENVIRONMENT}.tfvars"

if [ ! -f "$TERRAFORM_DIR/$TFVARS_FILE" ]; then
  echo "❌ No tfvars file found for environment '$ENVIRONMENT' (expected $TFVARS_FILE)"
  echo "   Valid environments: dev, staging, prod"
  exit 1
fi

echo ""
echo "━━━ Planning Fleexa infrastructure: $ENVIRONMENT ━━━"
echo ""

cd "$TERRAFORM_DIR"

echo "── terraform init ──"
terraform init -input=false

echo ""
echo "── terraform plan ──"
terraform plan -var-file="$TFVARS_FILE" "$@"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Plan finished for environment: $ENVIRONMENT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
