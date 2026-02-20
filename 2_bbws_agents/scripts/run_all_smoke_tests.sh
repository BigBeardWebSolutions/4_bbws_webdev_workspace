#!/bin/bash
################################################################################
# Master Smoke Test Runner
# Purpose: Run all API smoke tests in parallel or sequentially
# Usage: ./run_all_smoke_tests.sh [sit|dev|prod] [parallel|sequential]
################################################################################

set -e

ENV=${1:-"sit"}
MODE=${2:-"sequential"}

SCRIPTS_DIR="/Users/tebogotseka/Documents/agentic_work/2_bbws_agents/scripts"
LOG_DIR="/Users/tebogotseka/Documents/agentic_work/.claude/logs"
TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
COMBINED_LOG="$LOG_DIR/smoke_tests_${ENV}_${TIMESTAMP}.log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo "=========================================="
echo -e "${BLUE}Running All Smoke Tests${NC}"
echo "=========================================="
echo "Environment: $ENV"
echo "Mode: $MODE"
echo "Log file: $COMBINED_LOG"
echo ""

# Create logs directory
mkdir -p "$LOG_DIR"

# Initialize counters
TOTAL_PASSED=0
TOTAL_FAILED=0
APIS_TESTED=0

run_test() {
  local test_name=$1
  local test_script=$2

  echo -e "${YELLOW}► Running $test_name tests...${NC}"

  if [[ "$MODE" == "parallel" ]]; then
    # Run in background for parallel execution
    "$test_script" "$ENV" >> "$COMBINED_LOG" 2>&1 &
    echo "  Started (PID: $!)"
  else
    # Run sequentially
    if "$test_script" "$ENV" | tee -a "$COMBINED_LOG"; then
      echo -e "${GREEN}  ✅ $test_name PASSED${NC}"
    else
      echo -e "${RED}  ❌ $test_name FAILED${NC}"
    fi
  fi

  ((APIS_TESTED++))
}

# Run all smoke tests
run_test "Campaigns API" "$SCRIPTS_DIR/smoke_test_campaigns.sh"
run_test "Product API" "$SCRIPTS_DIR/smoke_test_products.sh"
run_test "Order API" "$SCRIPTS_DIR/smoke_test_orders.sh"

if [[ "$MODE" == "parallel" ]]; then
  echo ""
  echo "Waiting for all tests to complete..."
  wait

  echo ""
  echo -e "${GREEN}All tests completed!${NC}"
  echo "Review the combined log: $COMBINED_LOG"
else
  echo ""
  echo -e "${GREEN}All sequential tests completed!${NC}"
fi

echo ""
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo "APIs Tested: $APIS_TESTED"
echo "Environment: $ENV"
echo "Log: $COMBINED_LOG"
echo ""

# Parse log for summary (if sequential)
if [[ "$MODE" == "sequential" ]]; then
  TOTAL_PASSED=$(grep -c "✅ PASS:" "$COMBINED_LOG" || echo "0")
  TOTAL_FAILED=$(grep -c "❌ FAIL:" "$COMBINED_LOG" || echo "0")

  echo "Total Passed: $TOTAL_PASSED"
  echo "Total Failed: $TOTAL_FAILED"
  echo ""

  if [[ "$TOTAL_FAILED" -eq 0 ]]; then
    echo -e "${GREEN}✅ ALL SMOKE TESTS PASSED!${NC}"
    exit 0
  else
    echo -e "${RED}❌ SOME TESTS FAILED - Review log for details${NC}"
    exit 1
  fi
fi
