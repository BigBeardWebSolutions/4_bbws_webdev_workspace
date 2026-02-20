#!/bin/bash
################################################################################
# SIT Soak Testing Automated Monitor
# Purpose: Run health checks and collect metrics for SIT environment
# Schedule: Every 6 hours via cron
################################################################################

set -e  # Exit on error

# Configuration
PROFILE="Tebogo-sit"
REGION="eu-west-1"
LOG_DIR="/Users/tebogotseka/Documents/agentic_work/.claude/logs"
CHECKPOINT_LOG="$LOG_DIR/soak_checkpoints.log"
METRICS_LOG="$LOG_DIR/soak_metrics.json"

# API Configuration
CAMPAIGNS_API_ID="u3lui292v4"
PRODUCT_API_ID="eq1b8j0sek"
ORDER_API_ID="sl0obihav8"
BACKEND_URL="https://sit.kimmyai.io"

# Lambda Functions
CAMPAIGNS_FUNCTIONS=(
  "2-1-bbws-campaigns-get-sit"
  "2-1-bbws-campaigns-list-sit"
  "2-1-bbws-campaigns-create-sit"
  "2-1-bbws-campaigns-update-sit"
  "2-1-bbws-campaigns-delete-sit"
)

PRODUCT_FUNCTIONS=(
  "2-1-bbws-tf-product-get-sit"
  "2-1-bbws-tf-product-list-sit"
  "2-1-bbws-tf-product-create-sit"
  "2-1-bbws-tf-product-update-sit"
  "2-1-bbws-tf-product-delete-sit"
)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Timestamp
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
CHECKPOINT_NUM=${1:-"auto"}

################################################################################
# Logging Functions
################################################################################

log_info() {
  echo -e "${GREEN}[INFO]${NC} [$TIMESTAMP] $1" | tee -a "$CHECKPOINT_LOG"
}

log_warn() {
  echo -e "${YELLOW}[WARN]${NC} [$TIMESTAMP] $1" | tee -a "$CHECKPOINT_LOG"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} [$TIMESTAMP] $1" | tee -a "$CHECKPOINT_LOG"
}

################################################################################
# Health Check Functions
################################################################################

check_api_health() {
  local api_name=$1
  local api_url=$2

  log_info "Checking $api_name health..."

  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X GET "$api_url" 2>&1 || echo "000")
  RESPONSE_TIME=$(curl -s -o /dev/null -w "%{time_total}" -X GET "$api_url" 2>&1 || echo "999")

  if [[ "$HTTP_CODE" == "403" ]] || [[ "$HTTP_CODE" == "401" ]] || [[ "$HTTP_CODE" == "200" ]]; then
    log_info "  ✅ $api_name: HTTP $HTTP_CODE, ${RESPONSE_TIME}s"
    echo "$HTTP_CODE"
  else
    log_error "  ❌ $api_name: HTTP $HTTP_CODE (FAILED)"
    echo "000"
  fi
}

check_lambda_status() {
  local function_name=$1

  STATE=$(AWS_PROFILE=$PROFILE aws lambda get-function \
    --function-name "$function_name" \
    --query 'Configuration.State' \
    --output text 2>&1 || echo "UNKNOWN")

  LAST_MODIFIED=$(AWS_PROFILE=$PROFILE aws lambda get-function \
    --function-name "$function_name" \
    --query 'Configuration.LastModified' \
    --output text 2>&1 || echo "UNKNOWN")

  if [[ "$STATE" == "Active" ]]; then
    echo "Active"
  else
    log_warn "  ⚠️  $function_name: State=$STATE"
    echo "$STATE"
  fi
}

################################################################################
# CloudWatch Metrics Functions
################################################################################

get_lambda_metrics() {
  local function_name=$1
  local metric_name=$2
  local statistic=$3

  # Time range: last 6 hours
  START_TIME=$(date -u -v-6H '+%Y-%m-%dT%H:%M:%S')
  END_TIME=$(date -u '+%Y-%m-%dT%H:%M:%S')

  VALUE=$(AWS_PROFILE=$PROFILE aws cloudwatch get-metric-statistics \
    --namespace AWS/Lambda \
    --metric-name "$metric_name" \
    --dimensions Name=FunctionName,Value="$function_name" \
    --start-time "$START_TIME" \
    --end-time "$END_TIME" \
    --period 21600 \
    --statistics "$statistic" \
    --query 'Datapoints[0].'"$statistic" \
    --output text 2>&1 || echo "0")

  if [[ "$VALUE" == "None" ]] || [[ -z "$VALUE" ]]; then
    echo "0"
  else
    echo "$VALUE"
  fi
}

get_alarm_status() {
  ALARM_COUNT=$(AWS_PROFILE=$PROFILE aws cloudwatch describe-alarms \
    --state-value ALARM \
    --query 'length(MetricAlarms)' \
    --output text 2>&1 || echo "0")

  echo "$ALARM_COUNT"
}

################################################################################
# Main Checkpoint Execution
################################################################################

main() {
  echo ""
  echo "=========================================="
  echo "  SIT SOAK TESTING CHECKPOINT #$CHECKPOINT_NUM"
  echo "  Time: $TIMESTAMP"
  echo "=========================================="
  echo ""

  # Create logs directory if it doesn't exist
  mkdir -p "$LOG_DIR"

  log_info "Starting checkpoint #$CHECKPOINT_NUM"

  # 1. API Health Checks
  echo "=== 1. API Health Checks ==="
  CAMPAIGNS_STATUS=$(check_api_health "Campaigns API" "https://$CAMPAIGNS_API_ID.execute-api.$REGION.amazonaws.com/api/campaigns/health")
  PRODUCT_STATUS=$(check_api_health "Product API" "https://$PRODUCT_API_ID.execute-api.$REGION.amazonaws.com/v1/products/health")
  ORDER_STATUS=$(check_api_health "Order API" "https://$ORDER_API_ID.execute-api.$REGION.amazonaws.com/api/orders/health")
  BACKEND_STATUS=$(check_api_health "Backend Public" "$BACKEND_URL")
  echo ""

  # 2. Lambda Function Status
  echo "=== 2. Lambda Function Status ==="
  log_info "Checking Lambda functions..."

  ACTIVE_COUNT=0
  TOTAL_COUNT=0

  for func in "${CAMPAIGNS_FUNCTIONS[@]}"; do
    STATUS=$(check_lambda_status "$func")
    if [[ "$STATUS" == "Active" ]]; then
      ((ACTIVE_COUNT++))
    fi
    ((TOTAL_COUNT++))
  done

  for func in "${PRODUCT_FUNCTIONS[@]}"; do
    STATUS=$(check_lambda_status "$func")
    if [[ "$STATUS" == "Active" ]]; then
      ((ACTIVE_COUNT++))
    fi
    ((TOTAL_COUNT++))
  done

  log_info "  Lambda functions: $ACTIVE_COUNT/$TOTAL_COUNT active"
  echo ""

  # 3. CloudWatch Metrics (Campaigns Lambda only for summary)
  echo "=== 3. CloudWatch Metrics (Last 6 Hours) ==="
  log_info "Collecting CloudWatch metrics..."

  INVOCATIONS=$(get_lambda_metrics "2-1-bbws-campaigns-get-sit" "Invocations" "Sum")
  ERRORS=$(get_lambda_metrics "2-1-bbws-campaigns-get-sit" "Errors" "Sum")
  THROTTLES=$(get_lambda_metrics "2-1-bbws-campaigns-get-sit" "Throttles" "Sum")
  DURATION=$(get_lambda_metrics "2-1-bbws-campaigns-get-sit" "Duration" "Average")

  log_info "  Campaigns Lambda (get):"
  log_info "    Invocations: $INVOCATIONS"
  log_info "    Errors: $ERRORS"
  log_info "    Throttles: $THROTTLES"
  log_info "    Avg Duration: ${DURATION}ms"

  # Calculate error rate
  if (( $(echo "$INVOCATIONS > 0" | bc -l) )); then
    ERROR_RATE=$(echo "scale=2; ($ERRORS / $INVOCATIONS) * 100" | bc)
  else
    ERROR_RATE="0.00"
  fi
  echo ""

  # 4. CloudWatch Alarms
  echo "=== 4. CloudWatch Alarms ==="
  ALARM_COUNT=$(get_alarm_status)

  if [[ "$ALARM_COUNT" -eq 0 ]]; then
    log_info "  ✅ No alarms in ALARM state"
  else
    log_warn "  ⚠️  $ALARM_COUNT alarm(s) in ALARM state"

    # List alarms
    AWS_PROFILE=$PROFILE aws cloudwatch describe-alarms \
      --state-value ALARM \
      --query 'MetricAlarms[*].[AlarmName,StateReason]' \
      --output table | tee -a "$CHECKPOINT_LOG"
  fi
  echo ""

  # 5. DynamoDB Tables
  echo "=== 5. DynamoDB Tables ==="
  log_info "Checking DynamoDB tables..."

  for table in "campaigns" "products" "tenants"; do
    TABLE_STATUS=$(AWS_PROFILE=$PROFILE aws dynamodb describe-table \
      --table-name "$table" \
      --query 'Table.TableStatus' \
      --output text 2>&1 || echo "UNKNOWN")

    if [[ "$TABLE_STATUS" == "ACTIVE" ]]; then
      log_info "  ✅ $table: $TABLE_STATUS"
    else
      log_error "  ❌ $table: $TABLE_STATUS"
    fi
  done
  echo ""

  # Summary
  echo "=========================================="
  echo "  CHECKPOINT #$CHECKPOINT_NUM SUMMARY"
  echo "=========================================="
  log_info "API Health: Campaigns=$CAMPAIGNS_STATUS, Product=$PRODUCT_STATUS, Order=$ORDER_STATUS"
  log_info "Lambda Functions: $ACTIVE_COUNT/$TOTAL_COUNT active"
  log_info "Metrics: Invocations=$INVOCATIONS, Errors=$ERRORS (${ERROR_RATE}%), Throttles=$THROTTLES"
  log_info "Alarms: $ALARM_COUNT in ALARM state"

  # Pass/Fail Criteria
  PASS=true

  if [[ "$ACTIVE_COUNT" -ne "$TOTAL_COUNT" ]]; then
    log_error "FAIL: Not all Lambda functions are active"
    PASS=false
  fi

  if [[ "$ALARM_COUNT" -gt 1 ]]; then
    log_warn "WARNING: Multiple alarms in ALARM state"
  fi

  if (( $(echo "$ERROR_RATE > 0.1" | bc -l) )); then
    log_error "FAIL: Error rate ${ERROR_RATE}% exceeds threshold (0.1%)"
    PASS=false
  fi

  if [[ "$PASS" == true ]]; then
    log_info "✅ CHECKPOINT #$CHECKPOINT_NUM: PASSED"
  else
    log_error "❌ CHECKPOINT #$CHECKPOINT_NUM: FAILED"
  fi

  echo ""
  log_info "Checkpoint #$CHECKPOINT_NUM complete"
  echo ""

  # Save metrics to JSON
  cat > "$METRICS_LOG" <<EOF
{
  "checkpoint": "$CHECKPOINT_NUM",
  "timestamp": "$TIMESTAMP",
  "api_health": {
    "campaigns": $CAMPAIGNS_STATUS,
    "product": $PRODUCT_STATUS,
    "order": $ORDER_STATUS,
    "backend": $BACKEND_STATUS
  },
  "lambda_functions": {
    "active": $ACTIVE_COUNT,
    "total": $TOTAL_COUNT
  },
  "metrics": {
    "invocations": $INVOCATIONS,
    "errors": $ERRORS,
    "error_rate": $ERROR_RATE,
    "throttles": $THROTTLES,
    "duration_ms": $DURATION
  },
  "alarms": {
    "alarm_count": $ALARM_COUNT
  },
  "status": "$([ "$PASS" == true ] && echo "PASSED" || echo "FAILED")"
}
EOF

  log_info "Metrics saved to: $METRICS_LOG"
}

# Run main function
main "$@"
