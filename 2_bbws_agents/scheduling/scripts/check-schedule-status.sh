#!/usr/bin/env bash
set -euo pipefail

# Check desired_count of all ECS services in a cluster
# Usage: ./check-schedule-status.sh [dev|sit]

ENV="${1:-dev}"

case "$ENV" in
  dev)
    PROFILE="dev"
    CLUSTER="dev"
    REGION="eu-west-1"
    ;;
  sit)
    PROFILE="Tebogo-sit"
    CLUSTER="sit"
    REGION="eu-west-1"
    ;;
  *)
    echo "Usage: $0 [dev|sit]"
    exit 1
    ;;
esac

echo "ECS Service Status - ${ENV} (cluster: ${CLUSTER})"
echo "================================================"
echo ""

# List all services
SERVICE_ARNS=$(aws ecs list-services \
  --cluster "$CLUSTER" \
  --profile "$PROFILE" \
  --region "$REGION" \
  --query 'serviceArns[]' \
  --output text)

if [ -z "$SERVICE_ARNS" ]; then
  echo "No services found in cluster ${CLUSTER}"
  exit 0
fi

# Describe services (batch of up to 10)
ARNS_ARRAY=($SERVICE_ARNS)
TOTAL=${#ARNS_ARRAY[@]}
RUNNING=0
STOPPED=0

printf "%-40s %s\n" "SERVICE" "DESIRED COUNT"
printf "%-40s %s\n" "-------" "-------------"

for ((i=0; i<TOTAL; i+=10)); do
  BATCH="${ARNS_ARRAY[@]:i:10}"
  aws ecs describe-services \
    --cluster "$CLUSTER" \
    --services $BATCH \
    --profile "$PROFILE" \
    --region "$REGION" \
    --query 'services[].{name:serviceName,desired:desiredCount}' \
    --output text | while read -r COUNT NAME; do
      printf "%-40s %s\n" "$NAME" "$COUNT"
      if [ "$COUNT" -gt 0 ] 2>/dev/null; then
        ((RUNNING++)) || true
      else
        ((STOPPED++)) || true
      fi
    done
done

echo ""
echo "Total services: ${TOTAL}"

# Also check EventBridge rule states
echo ""
echo "EventBridge Schedule Rules:"
echo "---------------------------"
for RULE_NAME in "${ENV}-ecs-scheduler-stop" "${ENV}-ecs-scheduler-start"; do
  STATE=$(aws events describe-rule \
    --name "$RULE_NAME" \
    --profile "$PROFILE" \
    --region "$REGION" \
    --query 'State' \
    --output text 2>/dev/null || echo "NOT_FOUND")
  printf "%-40s %s\n" "$RULE_NAME" "$STATE"
done
