#!/usr/bin/env bash
# scripts/deploy.sh
#
# Real deployment happens two ways in this project (see root README.md,
# "Getting Started" / "CI/CD Pipeline Workflow"):
#   1. Automatically: pushing to `main` triggers
#      .github/workflows/ci-cd.yml's terraform-deploy job, which runs
#      `terraform apply` in infra-iot-fleet/terraform.
#   2. Manually: running `terraform apply` yourself from
#      infra-iot-fleet/terraform.
#
# This script is a thin wrapper around option 2 for local/manual use —
# it does not duplicate the CI/CD logic. Prefer pushing to main for
# anything that should go through the normal pipeline (tests, terraform
# plan review, verification steps).
#
# Usage:
#   ./scripts/deploy.sh          # terraform plan + prompt, then apply
#   ./scripts/deploy.sh --plan   # plan only, no apply

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="$REPO_ROOT/infra-iot-fleet/terraform"
AWS_REGION="${AWS_REGION:-us-east-1}"

command -v terraform >/dev/null 2>&1 || { echo "ERROR: terraform not found on PATH." >&2; exit 1; }

cd "$TF_DIR"

echo "==> terraform init"
terraform init

echo "==> terraform plan (region: ${AWS_REGION})"
terraform plan -var="aws_region=${AWS_REGION}" -out=tfplan

if [[ "${1:-}" == "--plan" ]]; then
    echo "==> --plan given, stopping after plan. Review tfplan with:"
    echo "    cd $TF_DIR && terraform show tfplan"
    exit 0
fi

read -r -p "Apply this plan to AWS (${AWS_REGION})? [y/N] " confirm
if [[ "$confirm" =~ ^[Yy]$ ]]; then
    echo "==> terraform apply tfplan"
    terraform apply tfplan
else
    echo "==> Aborted. No changes applied."
fi

echo ""
echo "NOTE: pushing to 'main' runs this same terraform apply automatically"
echo "      via .github/workflows/ci-cd.yml (terraform-deploy job)."
