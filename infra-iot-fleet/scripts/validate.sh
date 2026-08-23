#!/bin/bash
# Checks formatting and validity of the Fleexa Terraform configuration
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/../terraform"

echo ""
echo "━━━ Validating Fleexa infrastructure ━━━"
echo ""

cd "$TERRAFORM_DIR"

echo "── terraform init ──"
terraform init -backend=false -input=false

echo ""
echo "── terraform fmt -check ──"
if terraform fmt -check -recursive; then
  echo "  ✓ All files are formatted correctly"
else
  echo "  ✗ Some files need formatting. Run: terraform fmt -recursive"
  exit 1
fi

echo ""
echo "── terraform validate ──"
terraform validate
echo "  ✓ Configuration is syntactically valid"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Validation passed"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
