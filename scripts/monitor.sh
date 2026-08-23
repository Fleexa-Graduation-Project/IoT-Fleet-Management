#!/usr/bin/env bash
# scripts/monitor.sh
#
# Quick CLI helper to tail or query CloudWatch Logs for the backend's five
# Lambda functions (see backend/README.md "Architecture" and the Terraform
# module wiring in infra-iot-fleet/terraform/main.tf and lambda_build.tf):
#
#   Logical name      Deployed function name
#   ----------------  --------------------------
#   api-service        iot-fleet-dev-api-service
#   iot-ingestion       processing_main_lambda
#   door-watch          door-watch-service
#   ac-timer-watch      ac-timer-watch-service
#   db-export           iot-fleet-dev-db-export
#
# Usage:
#   ./scripts/monitor.sh api-service           # tail (follow) logs
#   ./scripts/monitor.sh door-watch --since 1h # last 1 hour, no follow
#   ./scripts/monitor.sh --list                # show the mapping above

set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"

declare -A FUNCTIONS=(
    [api-service]="iot-fleet-dev-api-service"
    [iot-ingestion]="processing_main_lambda"
    [door-watch]="door-watch-service"
    [ac-timer-watch]="ac-timer-watch-service"
    [db-export]="iot-fleet-dev-db-export"
)

usage() {
    echo "Usage: $0 <api-service|iot-ingestion|door-watch|ac-timer-watch|db-export> [--since <duration>]"
    echo "       $0 --list"
    echo ""
    echo "Without --since, logs are tailed live (aws logs tail --follow)."
    echo "With --since <duration> (e.g. 1h, 30m), prints matching logs once and exits."
}

if [[ $# -eq 0 || "$1" == "-h" || "$1" == "--help" ]]; then
    usage
    exit 0
fi

if [[ "$1" == "--list" ]]; then
    for key in "${!FUNCTIONS[@]}"; do
        printf "  %-16s -> %s\n" "$key" "${FUNCTIONS[$key]}"
    done
    exit 0
fi

command -v aws >/dev/null 2>&1 || { echo "ERROR: AWS CLI not found on PATH." >&2; exit 1; }

NAME="$1"
shift
FUNCTION_NAME="${FUNCTIONS[$NAME]:-}"
if [[ -z "$FUNCTION_NAME" ]]; then
    echo "ERROR: unknown function '$NAME'." >&2
    usage
    exit 1
fi

SINCE=""
if [[ "${1:-}" == "--since" ]]; then
    SINCE="${2:-1h}"
fi

LOG_GROUP="/aws/lambda/${FUNCTION_NAME}"
echo "==> Log group: ${LOG_GROUP} (region: ${AWS_REGION})"

if [[ -n "$SINCE" ]]; then
    aws logs tail "$LOG_GROUP" --since "$SINCE" --region "$AWS_REGION"
else
    echo "==> Following live logs (Ctrl+C to stop)..."
    aws logs tail "$LOG_GROUP" --follow --region "$AWS_REGION"
fi
