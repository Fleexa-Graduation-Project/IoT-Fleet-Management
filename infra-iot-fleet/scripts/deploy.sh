#!/bin/bash
# Applies the Fleexa Terraform stack for a given environment (dev/staging/prod)
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
echo "━━━ Deploying Fleexa infrastructure: $ENVIRONMENT ━━━"
echo ""

cd "$TERRAFORM_DIR"

echo "── terraform init ──"
terraform init -input=false

echo ""
echo "── terraform apply ──"

APPLY_ARGS=(-var-file="$TFVARS_FILE")

# Set AUTO_APPROVE=true to skip the interactive confirmation prompt (e.g. in CI).
if [ "${AUTO_APPROVE:-false}" = "true" ]; then
  APPLY_ARGS+=(-auto-approve)
fi

terraform apply "${APPLY_ARGS[@]}" "$@"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Deploy finished for environment: $ENVIRONMENT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
