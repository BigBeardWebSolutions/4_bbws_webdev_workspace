#!/bin/bash
# =============================================================================
# get_cognito_credentials.sh
# Retrieve Cognito credentials for a tenant from Secrets Manager
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
    echo "Retrieve Cognito credentials for a tenant from AWS Secrets Manager."
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
SECRET_NAME="bbws/${ENVIRONMENT}/${TENANT_ID}/cognito"

echo "=============================================="
echo "  BBWS Cognito Credentials"
echo "=============================================="
echo ""
echo "Tenant:      $TENANT_ID"
echo "Environment: $ENVIRONMENT"
echo "Secret:      $SECRET_NAME"
echo "Region:      $AWS_REGION"
echo ""
echo "----------------------------------------------"

# Retrieve secret
SECRET_VALUE=$(aws secretsmanager get-secret-value \
    --secret-id "$SECRET_NAME" \
    --profile "$AWS_PROFILE" \
    --region "$AWS_REGION" \
    --query 'SecretString' \
    --output text 2>/dev/null)

if [ -z "$SECRET_VALUE" ]; then
    echo ""
    echo "[ERROR] Secret not found: $SECRET_NAME"
    echo ""
    echo "Available secrets:"
    aws secretsmanager list-secrets \
        --profile "$AWS_PROFILE" \
        --region "$AWS_REGION" \
        --query 'SecretList[?starts_with(Name, `bbws/`)].Name' \
        --output table 2>/dev/null
    exit 1
fi

# Parse and display credentials
echo ""
echo "COGNITO CONFIGURATION:"
echo "----------------------------------------------"
echo ""

USER_POOL_ID=$(echo "$SECRET_VALUE" | jq -r '.user_pool_id')
APP_CLIENT_ID=$(echo "$SECRET_VALUE" | jq -r '.app_client_id')
APP_CLIENT_SECRET=$(echo "$SECRET_VALUE" | jq -r '.app_client_secret')
DOMAIN=$(echo "$SECRET_VALUE" | jq -r '.domain')
TENANT_DOMAIN=$(echo "$SECRET_VALUE" | jq -r '.tenant_domain')

echo "User Pool ID:      $USER_POOL_ID"
echo "App Client ID:     $APP_CLIENT_ID"
echo "App Client Secret: ${APP_CLIENT_SECRET:0:10}... (truncated)"
echo "Cognito Domain:    $DOMAIN"
echo "Tenant Domain:     $TENANT_DOMAIN"
echo ""

echo "----------------------------------------------"
echo "OAUTH 2.0 ENDPOINTS:"
echo "----------------------------------------------"
echo ""
echo "Authorization:"
echo "  https://$DOMAIN/oauth2/authorize"
echo ""
echo "Token:"
echo "  https://$DOMAIN/oauth2/token"
echo ""
echo "UserInfo:"
echo "  https://$DOMAIN/oauth2/userInfo"
echo ""
echo "Logout:"
echo "  https://$DOMAIN/logout"
echo ""
echo "JWKS:"
echo "  https://cognito-idp.$AWS_REGION.amazonaws.com/$USER_POOL_ID/.well-known/jwks.json"
echo ""

echo "----------------------------------------------"
echo "WORDPRESS PLUGIN SETTINGS:"
echo "----------------------------------------------"
echo ""
echo "Copy these values into your WordPress Cognito plugin:"
echo ""
echo "  User Pool ID:      $USER_POOL_ID"
echo "  App Client ID:     $APP_CLIENT_ID"
echo "  App Client Secret: (retrieve from Secrets Manager)"
echo "  Region:            $AWS_REGION"
echo "  Domain:            ${DOMAIN%.auth.*}"
echo ""

# Option to output as JSON
if [ "$2" == "--json" ]; then
    echo "----------------------------------------------"
    echo "JSON OUTPUT:"
    echo "----------------------------------------------"
    echo "$SECRET_VALUE" | jq .
fi
