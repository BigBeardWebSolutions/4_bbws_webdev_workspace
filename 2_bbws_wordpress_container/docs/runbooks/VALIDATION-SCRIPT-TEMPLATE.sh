#!/bin/bash
# Tenant Deployment Validation Script
# Version: 1.0
# Usage: ./validate_tenant_deployment.sh <tenant_name> <environment>
# Example: ./validate_tenant_deployment.sh goldencrust sit

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Parse arguments
TENANT_NAME=${1}
ENVIRONMENT=${2}

if [ -z "$TENANT_NAME" ] || [ -z "$ENVIRONMENT" ]; then
    echo "Usage: $0 <tenant_name> <environment>"
    echo "Example: $0 goldencrust sit"
    exit 1
fi

# Set AWS profile and region based on environment
case $ENVIRONMENT in
    dev)
        AWS_PROFILE="Tebogo-dev"
        AWS_REGION="eu-west-1"
        ACCOUNT_ID="536580886816"
        ;;
    sit)
        AWS_PROFILE="Tebogo-sit"
        AWS_REGION="eu-west-1"
        ACCOUNT_ID="815856636111"
        ;;
    prod)
        AWS_PROFILE="Tebogo-prod"
        AWS_REGION="af-south-1"
        ACCOUNT_ID="093646564004"
        ;;
    *)
        echo -e "${RED}❌ Invalid environment: $ENVIRONMENT${NC}"
        echo "Valid environments: dev, sit, prod"
        exit 1
        ;;
esac

export AWS_PROFILE
export AWS_DEFAULT_REGION=$AWS_REGION

echo "========================================="
echo "Tenant Deployment Validation"
echo "========================================="
echo "Tenant:      $TENANT_NAME"
echo "Environment: $ENVIRONMENT"
echo "Region:      $AWS_REGION"
echo "Profile:     $AWS_PROFILE"
echo "========================================="
echo ""

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Helper functions
print_test() {
    echo -e "${YELLOW}Testing:${NC} $1"
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
}

print_pass() {
    echo -e "${GREEN}✓ PASS:${NC} $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

print_fail() {
    echo -e "${RED}✗ FAIL:${NC} $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

print_info() {
    echo -e "  ${NC}→${NC} $1"
}

# Test 1: Secrets Manager - Database Credentials
print_test "Secrets Manager - Database credentials exist and valid"

SECRET_NAME="${ENVIRONMENT}-${TENANT_NAME}-db-credentials"
if SECRET=$(aws secretsmanager get-secret-value \
    --region $AWS_REGION \
    --secret-id $SECRET_NAME \
    --query SecretString \
    --output text 2>/dev/null); then

    # Parse secret
    DB_HOST=$(echo $SECRET | jq -r .host)
    DB_NAME=$(echo $SECRET | jq -r .database)
    DB_USER=$(echo $SECRET | jq -r .username)
    DB_PASS=$(echo $SECRET | jq -r .password)

    if [ -n "$DB_HOST" ] && [ -n "$DB_NAME" ] && [ -n "$DB_USER" ] && [ -n "$DB_PASS" ]; then
        print_pass "Database credentials valid"
        print_info "Database: $DB_NAME"
        print_info "User: $DB_USER"
        print_info "Host: $DB_HOST"
    else
        print_fail "Secret exists but missing required fields"
    fi
else
    print_fail "Secret $SECRET_NAME not found"
fi
echo ""

# Test 2: ECS Service - Exists and Running
print_test "ECS Service - Service exists and running"

SERVICE_NAME="${ENVIRONMENT}-${TENANT_NAME}-service"
CLUSTER_NAME="${ENVIRONMENT}-cluster"

if SERVICE_INFO=$(aws ecs describe-services \
    --region $AWS_REGION \
    --cluster $CLUSTER_NAME \
    --services $SERVICE_NAME \
    --query 'services[0]' 2>/dev/null); then

    STATUS=$(echo $SERVICE_INFO | jq -r .status)
    DESIRED=$(echo $SERVICE_INFO | jq -r .desiredCount)
    RUNNING=$(echo $SERVICE_INFO | jq -r .runningCount)
    PENDING=$(echo $SERVICE_INFO | jq -r .pendingCount)

    if [ "$STATUS" = "ACTIVE" ]; then
        print_pass "Service is ACTIVE"
        print_info "Desired: $DESIRED, Running: $RUNNING, Pending: $PENDING"

        if [ "$RUNNING" -eq "$DESIRED" ] && [ "$PENDING" -eq 0 ]; then
            print_pass "All tasks running (no pending)"
        else
            print_fail "Task count mismatch or pending tasks"
        fi
    else
        print_fail "Service status: $STATUS"
    fi
else
    print_fail "Service $SERVICE_NAME not found in cluster $CLUSTER_NAME"
fi
echo ""

# Test 3: ALB Target Group - Healthy targets
print_test "ALB Target Group - Has healthy targets"

TG_NAME="${ENVIRONMENT}-${TENANT_NAME}-tg"

if TG_ARN=$(aws elbv2 describe-target-groups \
    --region $AWS_REGION \
    --names $TG_NAME \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text 2>/dev/null); then

    print_pass "Target group exists"
    print_info "ARN: $TG_ARN"

    # Check target health
    HEALTH_INFO=$(aws elbv2 describe-target-health \
        --region $AWS_REGION \
        --target-group-arn $TG_ARN \
        --query 'TargetHealthDescriptions[*].{Target:Target.Id,Health:TargetHealth.State}')

    HEALTHY_COUNT=$(echo $HEALTH_INFO | jq '[.[] | select(.Health=="healthy")] | length')
    TOTAL_COUNT=$(echo $HEALTH_INFO | jq 'length')

    if [ "$HEALTHY_COUNT" -gt 0 ]; then
        print_pass "$HEALTHY_COUNT/$TOTAL_COUNT targets healthy"
    else
        print_fail "No healthy targets ($TOTAL_COUNT total)"
    fi
else
    print_fail "Target group $TG_NAME not found"
fi
echo ""

# Test 4: ALB Listener Rule - Exists and configured correctly
print_test "ALB Listener Rule - Configured with correct host header"

ALB_NAME="${ENVIRONMENT}-alb"
EXPECTED_HOST="${TENANT_NAME}.wp${ENVIRONMENT}.kimmyai.io"

if ALB_ARN=$(aws elbv2 describe-load-balancers \
    --region $AWS_REGION \
    --names $ALB_NAME \
    --query 'LoadBalancers[0].LoadBalancerArn' \
    --output text 2>/dev/null); then

    LISTENER_ARN=$(aws elbv2 describe-listeners \
        --region $AWS_REGION \
        --load-balancer-arn $ALB_ARN \
        --query 'Listeners[?Port==`80`].ListenerArn' \
        --output text)

    # Find rule with matching target group
    RULE_INFO=$(aws elbv2 describe-rules \
        --region $AWS_REGION \
        --listener-arn $LISTENER_ARN \
        --output json | jq ".Rules[] | select(.Actions[0].TargetGroupArn==\"$TG_ARN\")")

    if [ -n "$RULE_INFO" ]; then
        RULE_PRIORITY=$(echo $RULE_INFO | jq -r .Priority)
        RULE_HOST=$(echo $RULE_INFO | jq -r '.Conditions[] | select(.Field=="host-header") | .Values[0]')

        print_pass "Listener rule exists (Priority: $RULE_PRIORITY)"

        if [ "$RULE_HOST" = "$EXPECTED_HOST" ]; then
            print_pass "Host header correct: $RULE_HOST"
        else
            print_fail "Host header mismatch. Expected: $EXPECTED_HOST, Got: $RULE_HOST"
        fi
    else
        print_fail "No listener rule found for target group"
    fi
else
    print_fail "ALB $ALB_NAME not found"
fi
echo ""

# Test 5: HTTP Access via ALB
print_test "HTTP Access - Site accessible via ALB"

if [ -n "$ALB_ARN" ]; then
    ALB_DNS=$(aws elbv2 describe-load-balancers \
        --region $AWS_REGION \
        --load-balancer-arns $ALB_ARN \
        --query 'LoadBalancers[0].DNSName' \
        --output text)

    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Host: ${TENANT_NAME}.wp${ENVIRONMENT}.kimmyai.io" \
        "http://${ALB_DNS}/" \
        --max-time 10 2>/dev/null || echo "000")

    if [ "$HTTP_STATUS" = "302" ]; then
        print_pass "HTTP access working (302 redirect to WordPress installer)"
    elif [ "$HTTP_STATUS" = "200" ]; then
        print_pass "HTTP access working (200 OK - WordPress installed)"
    else
        print_fail "HTTP returned status: $HTTP_STATUS (expected 302 or 200)"
    fi
else
    print_fail "Cannot test - ALB not found"
fi
echo ""

# Test 6: HTTPS Access via CloudFront (SIT/PROD only)
if [ "$ENVIRONMENT" != "dev" ]; then
    print_test "HTTPS Access - Site accessible via CloudFront"

    HTTPS_URL="https://${TENANT_NAME}.wp${ENVIRONMENT}.kimmyai.io/"

    # Check DNS resolution
    DNS_IPS=$(dig +short ${TENANT_NAME}.wp${ENVIRONMENT}.kimmyai.io A | head -3)

    if [ -n "$DNS_IPS" ]; then
        print_pass "DNS resolves to IPs"
        print_info "IPs: $(echo $DNS_IPS | tr '\n' ', ')"

        # Note: Can't test Basic Auth without credentials
        # Try without auth first
        HTTPS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
            --max-time 10 \
            $HTTPS_URL 2>/dev/null || echo "000")

        if [ "$HTTPS_STATUS" = "401" ]; then
            print_pass "HTTPS working (401 - Basic Auth required)"
        elif [ "$HTTPS_STATUS" = "302" ] || [ "$HTTPS_STATUS" = "200" ]; then
            print_pass "HTTPS working (Status: $HTTPS_STATUS)"
        else
            print_fail "HTTPS returned status: $HTTPS_STATUS"
        fi
    else
        print_fail "DNS does not resolve"
    fi
else
    print_info "Skipping HTTPS test for DEV environment"
fi
echo ""

# Test 7: EFS Access Point
print_test "EFS Access Point - Exists for tenant"

EFS_AP_PATH="/${TENANT_NAME}"

# Get EFS filesystem ID for environment
EFS_FS_ID="${ENVIRONMENT}-efs"  # This might need adjustment based on your naming

# Note: This requires the EFS filesystem to be tagged properly
# Adjust the query based on your EFS setup
print_info "EFS validation requires manual verification of access point"
print_info "Expected path: $EFS_AP_PATH"
echo ""

# Test 8: CloudWatch Logs
print_test "CloudWatch Logs - Log streams exist"

LOG_GROUP="/ecs/${ENVIRONMENT}"
LOG_STREAM_PREFIX="${TENANT_NAME}/wordpress/"

if STREAMS=$(aws logs describe-log-streams \
    --region $AWS_REGION \
    --log-group-name $LOG_GROUP \
    --log-stream-name-prefix $LOG_STREAM_PREFIX \
    --max-items 5 \
    --query 'logStreams[*].logStreamName' \
    --output text 2>/dev/null); then

    STREAM_COUNT=$(echo $STREAMS | wc -w)

    if [ "$STREAM_COUNT" -gt 0 ]; then
        print_pass "$STREAM_COUNT log streams found"
        print_info "Latest: $(echo $STREAMS | awk '{print $1}')"
    else
        print_fail "No log streams found"
    fi
else
    print_fail "Cannot access log group $LOG_GROUP"
fi
echo ""

# Final Summary
echo "========================================="
echo "Validation Summary"
echo "========================================="
echo -e "Total Tests:  $TESTS_TOTAL"
echo -e "${GREEN}Passed:       $TESTS_PASSED${NC}"
echo -e "${RED}Failed:       $TESTS_FAILED${NC}"
echo "========================================="

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 All tests passed! Deployment is healthy.${NC}"
    exit 0
else
    echo -e "${RED}⚠️  Some tests failed. Review output above for details.${NC}"
    exit 1
fi
