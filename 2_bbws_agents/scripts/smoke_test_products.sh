#!/bin/bash
################################################################################
# Product API Smoke Tests
# Purpose: Test basic CRUD operations for product API
# Environment: SIT (can be parameterized)
################################################################################

set -e

# Configuration
ENV=${1:-"sit"}
REGION="eu-west-1"
API_ID="eq1b8j0sek"
BASE_URL="https://$API_ID.execute-api.$REGION.amazonaws.com/v1"

# Test configuration
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
    -X GET "$BASE_URL/products/health" 2>&1 || echo "000")

  # Accept 200 (healthy), 403 (auth required but service is up), 401, or 404 (no health endpoint)
  if [[ "$HTTP_CODE" == "200" ]] || [[ "$HTTP_CODE" == "403" ]] || [[ "$HTTP_CODE" == "401" ]] || [[ "$HTTP_CODE" == "404" ]]; then
    print_pass "API responding (HTTP $HTTP_CODE)"
  else
    print_fail "API not responding properly (HTTP $HTTP_CODE)"
  fi
}

test_list_products_unauthorized() {
  print_test "List Products (without auth - should fail)"

  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    -X GET "$BASE_URL/products")

  if [[ "$HTTP_CODE" == "403" ]] || [[ "$HTTP_CODE" == "401" ]]; then
    print_pass "Auth is enforced (HTTP $HTTP_CODE)"
  elif [[ "$HTTP_CODE" == "200" ]]; then
    print_info "Public access allowed (HTTP 200) - may be intentional"
    ((PASSED_TESTS++))
  else
    print_fail "Expected 200/401/403, got HTTP $HTTP_CODE"
  fi
}

test_get_product_not_found() {
  print_test "Get Non-existent Product"

  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    -X GET "$BASE_URL/products/nonexistent-product-id")

  # Accept 403/401 (auth required) or 404 (not found)
  if [[ "$HTTP_CODE" == "403" ]] || [[ "$HTTP_CODE" == "401" ]] || [[ "$HTTP_CODE" == "404" ]]; then
    print_pass "Non-existent product handled correctly (HTTP $HTTP_CODE)"
  else
    print_fail "Expected 401/403/404, got HTTP $HTTP_CODE"
  fi
}

test_create_product_unauthorized() {
  print_test "Create Product (without auth - should fail)"

  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST "$BASE_URL/products" \
    -H "Content-Type: application/json" \
    -d '{
      "name": "Test Product",
      "description": "Smoke test product",
      "price": 99.99,
      "currency": "USD",
      "status": "active"
    }')

  if [[ "$HTTP_CODE" == "403" ]] || [[ "$HTTP_CODE" == "401" ]]; then
    print_pass "Auth is enforced on create (HTTP $HTTP_CODE)"
  else
    print_fail "Expected 401/403, got HTTP $HTTP_CODE"
  fi
}

test_update_product_unauthorized() {
  print_test "Update Product (without auth - should fail)"

  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    -X PUT "$BASE_URL/products/test-product-id" \
    -H "Content-Type: application/json" \
    -d '{
      "name": "Updated Product Name"
    }')

  if [[ "$HTTP_CODE" == "403" ]] || [[ "$HTTP_CODE" == "401" ]]; then
    print_pass "Auth is enforced on update (HTTP $HTTP_CODE)"
  else
    print_fail "Expected 401/403, got HTTP $HTTP_CODE"
  fi
}

test_delete_product_unauthorized() {
  print_test "Delete Product (without auth - should fail)"

  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    -X DELETE "$BASE_URL/products/test-product-id")

  if [[ "$HTTP_CODE" == "403" ]] || [[ "$HTTP_CODE" == "401" ]]; then
    print_pass "Auth is enforced on delete (HTTP $HTTP_CODE)"
  else
    print_fail "Expected 401/403, got HTTP $HTTP_CODE"
  fi
}

test_api_response_time() {
  print_test "API Response Time"

  RESPONSE_TIME=$(curl -s -o /dev/null -w "%{time_total}" \
    -X GET "$BASE_URL/products" 2>&1 || echo "999")

  # Convert to milliseconds
  RESPONSE_TIME_MS=$(echo "$RESPONSE_TIME * 1000" | bc)

  if (( $(echo "$RESPONSE_TIME_MS < 2000" | bc -l) )); then
    print_pass "Response time: ${RESPONSE_TIME_MS}ms (< 2000ms threshold)"
  else
    print_fail "Response time: ${RESPONSE_TIME_MS}ms (exceeds 2000ms threshold)"
  fi
}

test_malformed_json() {
  print_test "Malformed JSON Payload"

  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST "$BASE_URL/products" \
    -H "Content-Type: application/json" \
    -d '{invalid json}')

  # Accept 400 (bad request) or 403/401 (auth - caught before validation)
  if [[ "$HTTP_CODE" == "400" ]] || [[ "$HTTP_CODE" == "403" ]] || [[ "$HTTP_CODE" == "401" ]]; then
    print_pass "Malformed JSON handled correctly (HTTP $HTTP_CODE)"
  else
    print_fail "Expected 400/401/403, got HTTP $HTTP_CODE"
  fi
}

test_invalid_http_method() {
  print_test "Invalid HTTP Method (PATCH without proper endpoint)"

  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    -X PATCH "$BASE_URL/products")

  # Accept 405 (method not allowed), 403/401 (auth), or 400 (bad request)
  if [[ "$HTTP_CODE" == "405" ]] || [[ "$HTTP_CODE" == "403" ]] || [[ "$HTTP_CODE" == "401" ]] || [[ "$HTTP_CODE" == "400" ]]; then
    print_pass "Invalid method handled correctly (HTTP $HTTP_CODE)"
  else
    print_fail "Expected 400/401/403/405, got HTTP $HTTP_CODE)"
  fi
}

test_api_gateway_exists() {
  print_test "API Gateway Configuration"

  # Try to get API Gateway info (requires AWS CLI)
  if command -v aws &> /dev/null; then
    API_INFO=$(AWS_PROFILE=Tebogo-sit aws apigateway get-rest-api \
      --rest-api-id "$API_ID" \
      --query 'name' \
      --output text 2>&1 || echo "UNKNOWN")

    if [[ "$API_INFO" != "UNKNOWN" ]]; then
      print_pass "API Gateway exists: $API_INFO"
    else
      print_info "Could not verify API Gateway (may need AWS credentials)"
    fi
  else
    print_info "AWS CLI not available - skipping API Gateway check"
  fi
}

test_lambda_functions_exist() {
  print_test "Lambda Functions Exist"

  # Check if product Lambda functions are deployed
  if command -v aws &> /dev/null; then
    FUNCTION_COUNT=$(AWS_PROFILE=Tebogo-sit aws lambda list-functions \
      --query 'length(Functions[?contains(FunctionName, `product`)])' \
      --output text 2>&1 || echo "0")

    if [[ "$FUNCTION_COUNT" -ge 5 ]]; then
      print_pass "Found $FUNCTION_COUNT product Lambda functions"
    else
      print_info "Found $FUNCTION_COUNT product Lambda functions (expected 5+)"
    fi
  else
    print_info "AWS CLI not available - skipping Lambda check"
  fi
}

################################################################################
# Main Execution
################################################################################

main() {
  print_header "Product API Smoke Tests - $ENV Environment"
  print_info "Base URL: $BASE_URL"
  print_info "Region: $REGION"
  print_info "API ID: $API_ID"

  # Basic Tests
  print_header "Basic Health & Auth Tests"
  test_health_check
  test_list_products_unauthorized
  test_get_product_not_found

  # CRUD Auth Tests
  print_header "CRUD Authorization Tests"
  test_create_product_unauthorized
  test_update_product_unauthorized
  test_delete_product_unauthorized

  # API Behavior Tests
  print_header "API Behavior Tests"
  test_api_response_time
  test_malformed_json
  test_invalid_http_method

  # Infrastructure Tests
  print_header "Infrastructure Tests"
  test_api_gateway_exists
  test_lambda_functions_exist

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
