#!/bin/bash
# =============================================================================
# verify_cognito_setup.sh
# Verify Cognito User Pool setup for a BBWS tenant
# =============================================================================

set -e

# Configuration
AWS_REGION="${AWS_REGION:-af-south-1}"
AWS_PROFILE="${AWS_PROFILE:-Tebogo-dev}"
ENVIRONMENT="${ENVIRONMENT:-dev}"

# Usage
usage() {
    echo "Usage: $0 <tenant-id>"
    echo ""
    echo "Verify Cognito User Pool setup for a BBWS tenant."
    echo ""
    echo "Arguments:"
    echo "  tenant-id    Tenant identifier (e.g., tenant-1, tenant-2)"
    echo ""
    echo "Environment Variables:"
    echo "  AWS_REGION   AWS region (default: af-south-1)"
    echo "  AWS_PROFILE  AWS profile (default: Tebogo-dev)"
    echo "  ENVIRONMENT  Environment name (default: dev)"
    echo ""
    echo "Examples:"
    echo "  $0 tenant-1"
    echo "  ENVIRONMENT=sit $0 tenant-2"
    echo ""
    exit 1
}

# Check arguments
if [ -z "$1" ]; then
    usage
fi

TENANT_ID="$1"
POOL_NAME="bbws-${TENANT_ID}-user-pool"
SECRET_NAME="bbws/${ENVIRONMENT}/${TENANT_ID}/cognito"

echo "=============================================="
echo "  BBWS Cognito Setup Verification"
echo "=============================================="
echo ""
echo "Tenant:      $TENANT_ID"
echo "Pool Name:   $POOL_NAME"
echo "Environment: $ENVIRONMENT"
echo "Region:      $AWS_REGION"
echo ""

CHECKS_PASSED=0
CHECKS_FAILED=0

check_pass() {
    echo "[PASS] $1"
    ((CHECKS_PASSED++))
}

check_fail() {
    echo "[FAIL] $1"
    ((CHECKS_FAILED++))
}

check_warn() {
    echo "[WARN] $1"
}

echo "----------------------------------------------"
echo "Running verification checks..."
echo "----------------------------------------------"
echo ""

# Check 1: User Pool exists
echo "1. User Pool Existence"
POOL_ID=$(aws cognito-idp list-user-pools \
    --max-results 60 \
    --profile "$AWS_PROFILE" \
    --region "$AWS_REGION" \
    --query "UserPools[?Name=='$POOL_NAME'].Id" \
    --output text 2>/dev/null)

if [ -n "$POOL_ID" ]; then
    check_pass "User pool exists: $POOL_ID"
else
    check_fail "User pool not found: $POOL_NAME"
    echo ""
    echo "User pool does not exist. Run provision_cognito.py first."
    exit 1
fi

# Check 2: Pool Status
echo ""
echo "2. User Pool Status"
POOL_STATUS=$(aws cognito-idp describe-user-pool \
    --user-pool-id "$POOL_ID" \
    --profile "$AWS_PROFILE" \
    --region "$AWS_REGION" \
    --query 'UserPool.Status' \
    --output text 2>/dev/null)

if [ "$POOL_STATUS" == "Active" ]; then
    check_pass "Pool status: $POOL_STATUS"
else
    check_fail "Pool status: $POOL_STATUS (expected: Active)"
fi

# Check 3: Domain
echo ""
echo "3. Cognito Domain"
DOMAIN=$(aws cognito-idp describe-user-pool \
    --user-pool-id "$POOL_ID" \
    --profile "$AWS_PROFILE" \
    --region "$AWS_REGION" \
    --query 'UserPool.Domain' \
    --output text 2>/dev/null)

if [ -n "$DOMAIN" ] && [ "$DOMAIN" != "None" ]; then
    check_pass "Domain configured: $DOMAIN"

    # Test domain DNS
    DOMAIN_URL="${DOMAIN}.auth.${AWS_REGION}.amazoncognito.com"
    if curl -s -o /dev/null -w "%{http_code}" "https://${DOMAIN_URL}/.well-known/openid-configuration" | grep -q "200"; then
        check_pass "Domain DNS resolves and OIDC config accessible"
    else
        check_warn "Domain may not be fully propagated yet"
    fi
else
    check_fail "No domain configured"
fi

# Check 4: App Client
echo ""
echo "4. App Client"
CLIENT_COUNT=$(aws cognito-idp list-user-pool-clients \
    --user-pool-id "$POOL_ID" \
    --profile "$AWS_PROFILE" \
    --region "$AWS_REGION" \
    --query 'length(UserPoolClients)' \
    --output text 2>/dev/null)

if [ "$CLIENT_COUNT" -gt 0 ]; then
    check_pass "App client(s) configured: $CLIENT_COUNT"

    # Get first client details
    CLIENT_ID=$(aws cognito-idp list-user-pool-clients \
        --user-pool-id "$POOL_ID" \
        --profile "$AWS_PROFILE" \
        --region "$AWS_REGION" \
        --query 'UserPoolClients[0].ClientId' \
        --output text 2>/dev/null)

    # Check callback URLs
    CALLBACK_COUNT=$(aws cognito-idp describe-user-pool-client \
        --user-pool-id "$POOL_ID" \
        --client-id "$CLIENT_ID" \
        --profile "$AWS_PROFILE" \
        --region "$AWS_REGION" \
        --query 'length(UserPoolClient.CallbackURLs)' \
        --output text 2>/dev/null)

    if [ "$CALLBACK_COUNT" -gt 0 ]; then
        check_pass "Callback URLs configured: $CALLBACK_COUNT"
    else
        check_warn "No callback URLs configured"
    fi
else
    check_fail "No app clients configured"
fi

# Check 5: MFA Configuration
echo ""
echo "5. MFA Configuration"
MFA_CONFIG=$(aws cognito-idp describe-user-pool \
    --user-pool-id "$POOL_ID" \
    --profile "$AWS_PROFILE" \
    --region "$AWS_REGION" \
    --query 'UserPool.MfaConfiguration' \
    --output text 2>/dev/null)

check_pass "MFA configuration: $MFA_CONFIG"

# Check 6: Password Policy
echo ""
echo "6. Password Policy"
PASSWORD_POLICY=$(aws cognito-idp describe-user-pool \
    --user-pool-id "$POOL_ID" \
    --profile "$AWS_PROFILE" \
    --region "$AWS_REGION" \
    --query 'UserPool.Policies.PasswordPolicy' \
    --output json 2>/dev/null)

MIN_LENGTH=$(echo "$PASSWORD_POLICY" | jq -r '.MinimumLength')
if [ "$MIN_LENGTH" -ge 8 ]; then
    check_pass "Password minimum length: $MIN_LENGTH"
else
    check_warn "Password minimum length: $MIN_LENGTH (recommended: 8+)"
fi

# Check 7: Secrets Manager
echo ""
echo "7. Secrets Manager"
SECRET_EXISTS=$(aws secretsmanager describe-secret \
    --secret-id "$SECRET_NAME" \
    --profile "$AWS_PROFILE" \
    --region "$AWS_REGION" \
    --query 'Name' \
    --output text 2>/dev/null || echo "")

if [ -n "$SECRET_EXISTS" ]; then
    check_pass "Secret exists: $SECRET_NAME"
else
    check_fail "Secret not found: $SECRET_NAME"
fi

# Check 8: User Count
echo ""
echo "8. User Statistics"
USER_COUNT=$(aws cognito-idp describe-user-pool \
    --user-pool-id "$POOL_ID" \
    --profile "$AWS_PROFILE" \
    --region "$AWS_REGION" \
    --query 'UserPool.EstimatedNumberOfUsers' \
    --output text 2>/dev/null)

echo "   Estimated users: $USER_COUNT"

# Summary
echo ""
echo "=============================================="
echo "  Verification Summary"
echo "=============================================="
echo ""
echo "  Passed: $CHECKS_PASSED"
echo "  Failed: $CHECKS_FAILED"
echo ""

if [ "$CHECKS_FAILED" -eq 0 ]; then
    echo "  Status: ALL CHECKS PASSED"
    echo ""
    echo "  Cognito setup for $TENANT_ID is ready!"
    echo ""
    echo "  Next steps:"
    echo "  1. Install WordPress Cognito plugin"
    echo "  2. Run: ./get_cognito_credentials.sh $TENANT_ID"
    echo "  3. Configure plugin with credentials"
    echo "  4. Test login flow"
    exit 0
else
    echo "  Status: SOME CHECKS FAILED"
    echo ""
    echo "  Please review and fix the failed checks above."
    exit 1
fi
