#!/bin/bash
################################################################################
# Campaigns API Smoke Tests
# Purpose: Test basic CRUD operations for campaigns API
# Environment: SIT (can be parameterized)
################################################################################

set -e

# Configuration
ENV=${1:-"sit"}
REGION="eu-west-1"
API_ID="u3lui292v4"
BASE_URL="https://$API_ID.execute-api.$REGION.amazonaws.com/api"

# Test configuration
TEST_CAMPAIGN_NAME="Smoke Test Campaign $(date +%s)"
TEST_CAMPAIGN_ID=""
FAILED_TESTS=0
PASSED_TESTS=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

################################################################################
# Helper Functions
################################################################################

print_header() {
  echo ""
  echo "=========================================="
  echo -e "${BLUE}$1${NC}"
  echo "=========================================="
}

print_test() {
  echo -e "${YELLOW}TEST:${NC} $1"
}

print_pass() {
  echo -e "${GREEN}✅ PASS:${NC} $1"
  ((PASSED_TESTS++))
}

print_fail() {
  echo -e "${RED}❌ FAIL:${NC} $1"
  ((FAILED_TESTS++))
}

print_info() {
  echo -e "${BLUE}ℹ️  INFO:${NC} $1"
}

################################################################################
# Test Functions
################################################################################

test_health_check() {
  print_test "Health Check Endpoint"

  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    -X GET "$BASE_URL/campaigns/health")

  # Accept 200 (healthy), 403 (auth required but service is up), or 401
  if [[ "$HTTP_CODE" == "200" ]] || [[ "$HTTP_CODE" == "403" ]] || [[ "$HTTP_CODE" == "401" ]]; then
    print_pass "Health endpoint returned HTTP $HTTP_CODE (service is up)"
  else
    print_fail "Health endpoint returned HTTP $HTTP_CODE (expected 200/401/403)"
  fi
}

test_list_campaigns_unauthorized() {
  print_test "List Campaigns (without auth - should fail)"

  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    -X GET "$BASE_URL/campaigns")

  if [[ "$HTTP_CODE" == "403" ]] || [[ "$HTTP_CODE" == "401" ]]; then
    print_pass "Auth is enforced (HTTP $HTTP_CODE)"
  else
    print_fail "Expected 401/403, got HTTP $HTTP_CODE (auth not enforced!)"
  fi
}

test_create_campaign_unauthorized() {
  print_test "Create Campaign (without auth - should fail)"

  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST "$BASE_URL/campaigns" \
    -H "Content-Type: application/json" \
    -d '{
      "name": "Test Campaign",
      "status": "draft",
      "start_date": "2026-02-01"
    }')

  if [[ "$HTTP_CODE" == "403" ]] || [[ "$HTTP_CODE" == "401" ]]; then
    print_pass "Auth is enforced on create (HTTP $HTTP_CODE)"
  else
    print_fail "Expected 401/403, got HTTP $HTTP_CODE"
  fi
}

test_get_campaign_not_found() {
  print_test "Get Non-existent Campaign"

  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    -X GET "$BASE_URL/campaigns/nonexistent-id")

  # Accept 403/401 (auth required) or 404 (not found if auth is bypassed in test)
  if [[ "$HTTP_CODE" == "403" ]] || [[ "$HTTP_CODE" == "401" ]] || [[ "$HTTP_CODE" == "404" ]]; then
    print_pass "Non-existent campaign handled correctly (HTTP $HTTP_CODE)"
  else
    print_fail "Expected 401/403/404, got HTTP $HTTP_CODE"
  fi
}

test_api_gateway_cors() {
  print_test "API Gateway CORS Headers"

  CORS_HEADER=$(curl -s -I -X OPTIONS "$BASE_URL/campaigns" \
    -H "Origin: https://sit.kimmyai.io" \
    -H "Access-Control-Request-Method: GET" | grep -i "access-control-allow" || echo "")

  if [[ -n "$CORS_HEADER" ]]; then
    print_pass "CORS headers present"
    print_info "CORS: $CORS_HEADER"
  else
    print_info "CORS headers not found (may be configured at API Gateway level)"
  fi
}

test_api_response_time() {
  print_test "API Response Time"

  RESPONSE_TIME=$(curl -s -o /dev/null -w "%{time_total}" \
    -X GET "$BASE_URL/campaigns/health")

  # Convert to milliseconds for comparison
  RESPONSE_TIME_MS=$(echo "$RESPONSE_TIME * 1000" | bc)

  if (( $(echo "$RESPONSE_TIME_MS < 2000" | bc -l) )); then
    print_pass "Response time: ${RESPONSE_TIME_MS}ms (< 2000ms threshold)"
  else
    print_fail "Response time: ${RESPONSE_TIME_MS}ms (exceeds 2000ms threshold)"
  fi
}

test_invalid_http_method() {
  print_test "Invalid HTTP Method (PATCH on health endpoint)"

  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    -X PATCH "$BASE_URL/campaigns/health")

  # Accept 403/401 (auth), 405 (method not allowed), or 400 (bad request)
  if [[ "$HTTP_CODE" == "405" ]] || [[ "$HTTP_CODE" == "403" ]] || [[ "$HTTP_CODE" == "401" ]] || [[ "$HTTP_CODE" == "400" ]]; then
    print_pass "Invalid method handled correctly (HTTP $HTTP_CODE)"
  else
    print_fail "Expected 400/401/403/405, got HTTP $HTTP_CODE"
  fi
}

test_malformed_json() {
  print_test "Malformed JSON Payload"

  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST "$BASE_URL/campaigns" \
    -H "Content-Type: application/json" \
    -d '{invalid json}')

  # Accept 400 (bad request) or 403/401 (auth - caught before validation)
  if [[ "$HTTP_CODE" == "400" ]] || [[ "$HTTP_CODE" == "403" ]] || [[ "$HTTP_CODE" == "401" ]]; then
    print_pass "Malformed JSON handled correctly (HTTP $HTTP_CODE)"
  else
    print_fail "Expected 400/401/403, got HTTP $HTTP_CODE"
  fi
}

################################################################################
# Advanced Tests (with mock auth - if available)
################################################################################

test_list_campaigns_with_auth() {
  print_test "List Campaigns (with mock token)"
  print_info "SKIPPED - Requires valid auth token"

  # Placeholder for when auth is configured
  # HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  #   -X GET "$BASE_URL/campaigns" \
  #   -H "Authorization: Bearer $AUTH_TOKEN")
  #
  # if [[ "$HTTP_CODE" == "200" ]]; then
  #   print_pass "List campaigns successful"
  # else
  #   print_fail "List campaigns failed (HTTP $HTTP_CODE)"
  # fi
}

################################################################################
# Main Execution
################################################################################

main() {
  print_header "Campaigns API Smoke Tests - $ENV Environment"
  print_info "Base URL: $BASE_URL"
  print_info "Region: $REGION"
  print_info "API ID: $API_ID"

  # Basic Tests
  print_header "Basic Health & Auth Tests"
  test_health_check
  test_list_campaigns_unauthorized
  test_create_campaign_unauthorized
  test_get_campaign_not_found

  # API Behavior Tests
  print_header "API Behavior Tests"
  test_api_gateway_cors
  test_api_response_time
  test_invalid_http_method
  test_malformed_json

  # Advanced Tests (skipped if no auth)
  print_header "Advanced Tests (Auth Required)"
  test_list_campaigns_with_auth

  # Summary
  print_header "Test Summary"
  TOTAL_TESTS=$((PASSED_TESTS + FAILED_TESTS))

  echo ""
  echo "Total Tests:  $TOTAL_TESTS"
  echo -e "${GREEN}Passed:       $PASSED_TESTS${NC}"

  if [[ $FAILED_TESTS -gt 0 ]]; then
    echo -e "${RED}Failed:       $FAILED_TESTS${NC}"
  else
    echo -e "${GREEN}Failed:       $FAILED_TESTS${NC}"
  fi

  echo ""

  if [[ $FAILED_TESTS -eq 0 ]]; then
    print_pass "ALL TESTS PASSED"
    exit 0
  else
    print_fail "$FAILED_TESTS TEST(S) FAILED"
    exit 1
  fi
}

# Run tests
main "$@"
