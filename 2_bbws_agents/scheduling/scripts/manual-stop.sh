#!/usr/bin/env bash
set -euo pipefail

# Manual stop: invoke Lambda with stop action
# Usage: ./manual-stop.sh [dev|sit]

ENV="${1:-dev}"

case "$ENV" in
  dev)
    PROFILE="dev"
    CLUSTER="dev"
    FUNCTION="dev-ecs-scheduler"
    REGION="eu-west-1"
    ;;
  sit)
    PROFILE="Tebogo-sit"
    CLUSTER="sit"
    FUNCTION="sit-ecs-scheduler"
    REGION="eu-west-1"
    ;;
  *)
    echo "Usage: $0 [dev|sit]"
    exit 1
    ;;
esac

echo "Stopping all ECS services in ${ENV} cluster (${CLUSTER})..."
echo "Profile: ${PROFILE}"
echo ""

PAYLOAD="{\"action\": \"stop\", \"cluster_name\": \"${CLUSTER}\", \"region\": \"${REGION}\"}"

aws lambda invoke \
  --function-name "$FUNCTION" \
  --payload "$PAYLOAD" \
  --cli-binary-format raw-in-base64-out \
  --profile "$PROFILE" \
  --region "$REGION" \
  /dev/stdout

echo ""
echo "Stop command sent. Check SNS email for results."
