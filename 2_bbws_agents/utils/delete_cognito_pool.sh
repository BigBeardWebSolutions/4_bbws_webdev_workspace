#!/bin/bash
# =============================================================================
# delete_cognito_pool.sh
# Delete a Cognito User Pool for a BBWS tenant
# =============================================================================

set -e

# Configuration
AWS_REGION="${AWS_REGION:-af-south-1}"
AWS_PROFILE="${AWS_PROFILE:-Tebogo-dev}"
ENVIRONMENT="${ENVIRONMENT:-dev}"

# Usage
usage() {
    echo "Usage: $0 <tenant-id> [--force]"
    echo ""
    echo "Delete a Cognito User Pool for a BBWS tenant."
    echo ""
    echo "Arguments:"
    echo "  tenant-id    Tenant identifier (e.g., tenant-1, tenant-2)"
    echo "  --force      Skip confirmation prompt"
    echo ""
    echo "Environment Variables:"
    echo "  AWS_REGION   AWS region (default: af-south-1)"
    echo "  AWS_PROFILE  AWS profile (default: Tebogo-dev)"
    echo "  ENVIRONMENT  Environment name (default: dev)"
    echo ""
    echo "Examples:"
    echo "  $0 tenant-1"
    echo "  $0 tenant-2 --force"
    echo ""
    exit 1
}

# Check arguments
if [ -z "$1" ]; then
    usage
fi

TENANT_ID="$1"
FORCE_DELETE=false

if [ "$2" == "--force" ]; then
    FORCE_DELETE=true
fi

POOL_NAME="bbws-${TENANT_ID}-user-pool"
SECRET_NAME="bbws/${ENVIRONMENT}/${TENANT_ID}/cognito"

echo "=============================================="
echo "  BBWS Cognito User Pool Deletion"
echo "=============================================="
echo ""
echo "Tenant:      $TENANT_ID"
echo "Pool Name:   $POOL_NAME"
echo "Environment: $ENVIRONMENT"
echo "Region:      $AWS_REGION"
echo ""

# Find the user pool
echo "Searching for user pool..."
POOL_ID=$(aws cognito-idp list-user-pools \
    --max-results 60 \
    --profile "$AWS_PROFILE" \
    --region "$AWS_REGION" \
    --query "UserPools[?Name=='$POOL_NAME'].Id" \
    --output text 2>/dev/null)

if [ -z "$POOL_ID" ]; then
    echo ""
    echo "[INFO] User pool '$POOL_NAME' not found."
    echo ""
    exit 0
fi

echo "Found pool: $POOL_ID"
echo ""

# Get pool details
echo "Pool Details:"
echo "----------------------------------------------"
aws cognito-idp describe-user-pool \
    --user-pool-id "$POOL_ID" \
    --profile "$AWS_PROFILE" \
    --region "$AWS_REGION" \
    --query 'UserPool.{Name:Name,Domain:Domain,Status:Status,EstimatedUsers:EstimatedNumberOfUsers}' \
    --output table 2>/dev/null

# Get domain
DOMAIN=$(aws cognito-idp describe-user-pool \
    --user-pool-id "$POOL_ID" \
    --profile "$AWS_PROFILE" \
    --region "$AWS_REGION" \
    --query 'UserPool.Domain' \
    --output text 2>/dev/null)

echo ""

# Confirmation
if [ "$FORCE_DELETE" != true ]; then
    echo "----------------------------------------------"
    echo "[WARNING] This will permanently delete:"
    echo "  - User Pool: $POOL_ID"
    if [ -n "$DOMAIN" ] && [ "$DOMAIN" != "None" ]; then
        echo "  - Domain: $DOMAIN"
    fi
    echo "  - All users in this pool"
    echo "  - Secret: $SECRET_NAME"
    echo "----------------------------------------------"
    echo ""
    read -p "Are you sure you want to delete? (yes/no): " CONFIRM

    if [ "$CONFIRM" != "yes" ]; then
        echo ""
        echo "[ABORT] Deletion cancelled."
        echo ""
        exit 0
    fi
fi

echo ""
echo "Deleting resources..."
echo ""

# Delete domain first
if [ -n "$DOMAIN" ] && [ "$DOMAIN" != "None" ]; then
    echo "[1/3] Deleting domain: $DOMAIN"
    aws cognito-idp delete-user-pool-domain \
        --domain "$DOMAIN" \
        --user-pool-id "$POOL_ID" \
        --profile "$AWS_PROFILE" \
        --region "$AWS_REGION" 2>/dev/null || echo "  [WARN] Domain may already be deleted"
else
    echo "[1/3] No domain to delete"
fi

# Delete user pool
echo "[2/3] Deleting user pool: $POOL_ID"
aws cognito-idp delete-user-pool \
    --user-pool-id "$POOL_ID" \
    --profile "$AWS_PROFILE" \
    --region "$AWS_REGION" 2>/dev/null

# Delete secret
echo "[3/3] Deleting secret: $SECRET_NAME"
aws secretsmanager delete-secret \
    --secret-id "$SECRET_NAME" \
    --force-delete-without-recovery \
    --profile "$AWS_PROFILE" \
    --region "$AWS_REGION" 2>/dev/null || echo "  [WARN] Secret may not exist or already deleted"

echo ""
echo "=============================================="
echo "  Deletion Complete"
echo "=============================================="
echo ""
echo "Deleted:"
echo "  - User Pool: $POOL_ID"
if [ -n "$DOMAIN" ] && [ "$DOMAIN" != "None" ]; then
    echo "  - Domain: $DOMAIN"
fi
echo "  - Secret: $SECRET_NAME"
echo ""
