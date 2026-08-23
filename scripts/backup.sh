#!/usr/bin/env bash
# scripts/backup.sh
#
# Exports the Fleexa DynamoDB tables to S3, on-demand, for backup / offline
# analysis. This is a manual CLI equivalent of the backend's `db-export`
# Lambda (backend/cmd/db-export, deployed as "${project_name}-${environment}
# -db-export" — see backend/README.md's "Data Tiering" section and
# infra-iot-fleet/terraform/modules/cron_export).
#
# Table names default to the logical names documented in backend/README.md
# (STATE_TABLE, TELEMETRY_TABLE, ALERTS_TABLE, COMMANDS_TABLE, USERS_TABLE).
# If your deployment uses the Terraform-generated names instead (e.g.
# iot-fleet-dev-telemetry), override the corresponding env var before running.
#
# Requires: AWS CLI v2, credentials with dynamodb:ExportTableToPointInTime
# and s3:PutObject on the destination bucket.
#
# Usage:
#   BACKUP_BUCKET=my-backup-bucket ./scripts/backup.sh
#   STATE_TABLE=iot-fleet-dev-device-state ./scripts/backup.sh

set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
BACKUP_BUCKET="${BACKUP_BUCKET:-fleexa-data-lake}"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"

STATE_TABLE="${STATE_TABLE:-Fleexa_Devices}"
TELEMETRY_TABLE="${TELEMETRY_TABLE:-Fleexa_Telemetry}"
ALERTS_TABLE="${ALERTS_TABLE:-Fleexa_Alerts}"
COMMANDS_TABLE="${COMMANDS_TABLE:-Fleexa_Commands}"
USERS_TABLE="${USERS_TABLE:-Fleexa_Users}"

TABLES=("$STATE_TABLE" "$TELEMETRY_TABLE" "$ALERTS_TABLE" "$COMMANDS_TABLE" "$USERS_TABLE")

command -v aws >/dev/null 2>&1 || { echo "ERROR: AWS CLI not found on PATH." >&2; exit 1; }

echo "==> Backing up DynamoDB tables to s3://${BACKUP_BUCKET}/backups/${TIMESTAMP}/ (region: ${AWS_REGION})"

for table in "${TABLES[@]}"; do
    ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
    TABLE_ARN="arn:aws:dynamodb:${AWS_REGION}:${ACCOUNT_ID}:table/${table}"
    DEST="s3://${BACKUP_BUCKET}/backups/${TIMESTAMP}/${table}"

    echo "----> Exporting ${table} -> ${DEST}"
    if ! aws dynamodb describe-table --table-name "$table" --region "$AWS_REGION" >/dev/null 2>&1; then
        echo "      WARNING: table ${table} not found in ${AWS_REGION}, skipping."
        continue
    fi

    aws dynamodb export-table-to-point-in-time \
        --table-arn "$TABLE_ARN" \
        --s3-bucket "$BACKUP_BUCKET" \
        --s3-prefix "backups/${TIMESTAMP}/${table}" \
        --export-format DYNAMODB_JSON \
        --region "$AWS_REGION"
done

echo "==> Backup export requests submitted. Check status with:"
echo "    aws dynamodb list-exports --table-arn <table-arn> --region ${AWS_REGION}"
