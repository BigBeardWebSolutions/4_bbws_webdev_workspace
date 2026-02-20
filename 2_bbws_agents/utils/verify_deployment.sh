#!/bin/bash
# Verify tenant deployment across all components
# Usage: ./verify_deployment.sh <tenant_name> <environment>

set -e

TENANT=$1
ENV=$2

if [[ -z "$TENANT" || -z "$ENV" ]]; then
  echo "Usage: $0 <tenant_name> <environment>"
  echo "Example: $0 myclient sit"
  exit 1
fi

case $ENV in
  dev)
    PROFILE="Tebogo-dev"
    REGION="eu-west-1"
    DOMAIN="wpdev"
    ;;
  sit)
    PROFILE="Tebogo-sit"
    REGION="eu-west-1"
    DOMAIN="wpsit"
    ;;
  prod)
    PROFILE="Tebogo-prod"
    REGION="af-south-1"
    DOMAIN="wp"
    ;;
  *)
    echo "Error: Invalid environment '$ENV'"
    exit 1
    ;;
esac

echo "========================================="
echo "  DEPLOYMENT VERIFICATION"
echo "========================================="
echo "Tenant:      $TENANT"
echo "Environment: $ENV"
echo "========================================="

PASS_COUNT=0
FAIL_COUNT=0

# Helper function for checks
check_pass() {
  echo "✅ PASS: $1"
  ((PASS_COUNT++))
}

check_fail() {
  echo "❌ FAIL: $1"
  ((FAIL_COUNT++))
}

check_warn() {
  echo "⚠️  WARN: $1"
}

# Check 1: Secrets Manager
echo ""
echo "[1/7] Checking Secrets Manager..."
SECRET_NAME="${ENV}-${TENANT}-db-credentials"
if aws secretsmanager describe-secret \
  --secret-id $SECRET_NAME \
  --region $REGION \
  --profile $PROFILE \
  --query 'Name' \
  --output text > /dev/null 2>&1; then
  check_pass "Secret exists: $SECRET_NAME"
else
  check_fail "Secret not found: $SECRET_NAME"
fi

# Check 2: ECS Service
echo ""
echo "[2/7] Checking ECS Service..."
SERVICE_NAME="${ENV}-${TENANT}-service"
SERVICE_INFO=$(aws ecs describe-services \
  --cluster ${ENV}-cluster \
  --services $SERVICE_NAME \
  --region $REGION \
  --profile $PROFILE \
  --query 'services[0].[status,desiredCount,runningCount,deployments[0].rolloutState]' \
  --output text 2>/dev/null || echo "")

if [[ -n "$SERVICE_INFO" ]]; then
  STATUS=$(echo "$SERVICE_INFO" | awk '{print $1}')
  DESIRED=$(echo "$SERVICE_INFO" | awk '{print $2}')
  RUNNING=$(echo "$SERVICE_INFO" | awk '{print $3}')
  ROLLOUT=$(echo "$SERVICE_INFO" | awk '{print $4}')

  echo "  Status: $STATUS"
  echo "  Desired: $DESIRED"
  echo "  Running: $RUNNING"
  echo "  Rollout: $ROLLOUT"

  if [[ "$STATUS" == "ACTIVE" ]]; then
    check_pass "ECS Service is ACTIVE"
  else
    check_fail "ECS Service status is $STATUS (expected ACTIVE)"
  fi

  if [[ "$RUNNING" -ge "$DESIRED" ]]; then
    check_pass "All tasks are running ($RUNNING/$DESIRED)"
  else
    check_warn "Tasks not fully running ($RUNNING/$DESIRED)"
  fi
else
  check_fail "ECS Service not found: $SERVICE_NAME"
fi

# Check 3: ECS Tasks
echo ""
echo "[3/7] Checking ECS Tasks..."
TASK_ARN=$(aws ecs list-tasks \
  --cluster ${ENV}-cluster \
  --service-name $SERVICE_NAME \
  --region $REGION \
  --profile $PROFILE \
  --query 'taskArns[0]' \
  --output text 2>/dev/null || echo "")

if [[ -n "$TASK_ARN" && "$TASK_ARN" != "None" ]]; then
  TASK_STATUS=$(aws ecs describe-tasks \
    --cluster ${ENV}-cluster \
    --tasks $TASK_ARN \
    --region $REGION \
    --profile $PROFILE \
    --query 'tasks[0].[lastStatus,healthStatus,stopCode,stoppedReason]' \
    --output text)

  LAST_STATUS=$(echo "$TASK_STATUS" | awk '{print $1}')
  HEALTH=$(echo "$TASK_STATUS" | awk '{print $2}')

  echo "  Task Status: $LAST_STATUS"
  echo "  Health: $HEALTH"

  if [[ "$LAST_STATUS" == "RUNNING" ]]; then
    check_pass "Task is RUNNING"
  else
    check_warn "Task status is $LAST_STATUS"
  fi
else
  check_warn "No tasks found for service"
fi

# Check 4: Target Group
echo ""
echo "[4/7] Checking Target Group..."
TG_NAME="${ENV}-${TENANT}-tg"
TG_ARN=$(aws elbv2 describe-target-groups \
  --names $TG_NAME \
  --region $REGION \
  --profile $PROFILE \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text 2>/dev/null || echo "")

if [[ -n "$TG_ARN" && "$TG_ARN" != "None" ]]; then
  check_pass "Target Group exists: $TG_NAME"

  # Check target health
  TG_HEALTH=$(aws elbv2 describe-target-health \
    --target-group-arn $TG_ARN \
    --region $REGION \
    --profile $PROFILE \
    --query 'TargetHealthDescriptions[*].[Target.Id,TargetHealth.State,TargetHealth.Reason]' \
    --output text)

  if [[ -n "$TG_HEALTH" ]]; then
    echo "  Targets:"
    echo "$TG_HEALTH" | while read -r line; do
      TARGET_ID=$(echo "$line" | awk '{print $1}')
      STATE=$(echo "$line" | awk '{print $2}')
      REASON=$(echo "$line" | awk '{print $3}')

      echo "    • $TARGET_ID: $STATE $([ -n "$REASON" ] && echo "($REASON)" || echo "")"

      if [[ "$STATE" == "healthy" ]]; then
        check_pass "Target $TARGET_ID is healthy"
      elif [[ "$STATE" == "initial" || "$STATE" == "draining" ]]; then
        check_warn "Target $TARGET_ID is $STATE"
      else
        check_fail "Target $TARGET_ID is $STATE"
      fi
    done
  else
    check_warn "No targets registered yet"
  fi
else
  check_fail "Target Group not found: $TG_NAME"
fi

# Check 5: ALB Listener Rule
echo ""
echo "[5/7] Checking ALB Listener Rule..."
ALB_ARN=$(aws elbv2 describe-load-balancers \
  --names ${ENV}-alb \
  --region $REGION \
  --profile $PROFILE \
  --query 'LoadBalancers[0].LoadBalancerArn' \
  --output text 2>/dev/null || echo "")

if [[ -n "$ALB_ARN" ]]; then
  LISTENER_ARN=$(aws elbv2 describe-listeners \
    --load-balancer-arn $ALB_ARN \
    --region $REGION \
    --profile $PROFILE \
    --query 'Listeners[?Port==`80`].ListenerArn' \
    --output text)

  RULE_COUNT=$(aws elbv2 describe-rules \
    --listener-arn $LISTENER_ARN \
    --region $REGION \
    --profile $PROFILE \
    --query "length(Rules[?Conditions[?Field=='host-header' && Values[?contains(@, '${TENANT}')]]]])" \
    --output text)

  if [[ "$RULE_COUNT" -gt 0 ]]; then
    check_pass "ALB Listener Rule exists for ${TENANT}"
  else
    check_fail "ALB Listener Rule not found for ${TENANT}"
  fi
else
  check_fail "ALB not found: ${ENV}-alb"
fi

# Check 6: HTTP Endpoint
echo ""
echo "[6/7] Testing HTTP Endpoint..."
URL="http://${TENANT}.${DOMAIN}.kimmyai.io"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" $URL || echo "000")

echo "  URL: $URL"
echo "  Response: $HTTP_CODE"

case $HTTP_CODE in
  200)
    check_pass "HTTP endpoint returns 200 OK"
    ;;
  301|302)
    check_pass "HTTP endpoint returns $HTTP_CODE (redirect)"
    ;;
  503)
    check_warn "HTTP 503 - Service temporarily unavailable (targets may still be starting)"
    ;;
  500)
    check_fail "HTTP 500 - Internal server error (likely database connection issue)"
    ;;
  401)
    check_pass "HTTP 401 - Basic auth is working (expected for SIT/PROD)"
    ;;
  *)
    check_fail "HTTP $HTTP_CODE - Unexpected response"
    ;;
esac

# Check 7: Recent Logs
echo ""
echo "[7/7] Checking Recent Logs..."
RECENT_LOGS=$(aws logs tail /ecs/${ENV} \
  --since 5m \
  --filter-pattern "${TENANT}" \
  --format short \
  --region $REGION \
  --profile $PROFILE \
  2>/dev/null | tail -5 || echo "")

if [[ -n "$RECENT_LOGS" ]]; then
  echo "  Recent log entries:"
  echo "$RECENT_LOGS" | while read -r line; do
    echo "    $line"
  done

  # Check for errors in logs
  if echo "$RECENT_LOGS" | grep -qi "error\|failed\|exception"; then
    check_warn "Errors found in recent logs"
  else
    check_pass "No errors in recent logs"
  fi
else
  check_warn "No recent logs found (service may not have started yet)"
fi

# Final summary
echo ""
echo "========================================="
echo "  VERIFICATION SUMMARY"
echo "========================================="
echo "Passed:  $PASS_COUNT"
echo "Failed:  $FAIL_COUNT"
echo "========================================="

if [[ $FAIL_COUNT -eq 0 ]]; then
  echo "✅ All critical checks passed!"
  echo ""
  echo "Next steps:"
  echo "  1. Access WordPress: https://${TENANT}.${DOMAIN}.kimmyai.io"
  echo "  2. Complete setup: https://${TENANT}.${DOMAIN}.kimmyai.io/wp-admin/install.php"
  echo "  3. Monitor logs: aws logs tail /ecs/${ENV} --filter-pattern '${TENANT}' --follow"
  exit 0
else
  echo "⚠️  Some checks failed. Review issues above."
  echo ""
  echo "Troubleshooting:"
  echo "  • Check ECS service events:"
  echo "    aws ecs describe-services --cluster ${ENV}-cluster --services ${SERVICE_NAME}"
  echo "  • Check task logs:"
  echo "    aws logs tail /ecs/${ENV} --filter-pattern '${TENANT}' --follow"
  echo "  • Check target health:"
  echo "    aws elbv2 describe-target-health --target-group-arn $TG_ARN"
  exit 1
fi
