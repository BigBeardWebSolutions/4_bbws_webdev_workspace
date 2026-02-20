#!/bin/bash
# =============================================================================
# list_cognito_pools.sh
# List all Cognito User Pools for BBWS WordPress tenants
# =============================================================================

set -e

# Configuration
AWS_REGION="${AWS_REGION:-af-south-1}"
AWS_PROFILE="${AWS_PROFILE:-Tebogo-dev}"

echo "=============================================="
echo "  BBWS Cognito User Pools"
echo "=============================================="
echo ""
echo "Region:  $AWS_REGION"
echo "Profile: $AWS_PROFILE"
echo ""

# Get account ID
ACCOUNT_ID=$(aws sts get-caller-identity --profile "$AWS_PROFILE" --query 'Account' --output text 2>/dev/null)
echo "Account: $ACCOUNT_ID"
echo ""
echo "----------------------------------------------"

# List all user pools
POOLS=$(aws cognito-idp list-user-pools \
    --max-results 60 \
    --profile "$AWS_PROFILE" \
    --region "$AWS_REGION" \
    --query 'UserPools[?starts_with(Name, `bbws-`)]' \
    --output json 2>/dev/null)

if [ -z "$POOLS" ] || [ "$POOLS" == "[]" ]; then
    echo ""
    echo "No BBWS Cognito User Pools found."
    echo ""
    exit 0
fi

# Parse and display pools
echo ""
printf "%-35s %-25s %-15s\n" "POOL NAME" "POOL ID" "CREATED"
printf "%-35s %-25s %-15s\n" "-----------------------------------" "-------------------------" "---------------"

echo "$POOLS" | jq -r '.[] | "\(.Name)\t\(.Id)\t\(.CreationDate)"' | while IFS=$'\t' read -r name id created; do
    created_date=$(echo "$created" | cut -d'T' -f1)
    printf "%-35s %-25s %-15s\n" "$name" "$id" "$created_date"
done

echo ""
echo "----------------------------------------------"
echo "Total pools: $(echo "$POOLS" | jq length)"
echo ""

# Show detailed info for each pool
if [ "$1" == "-v" ] || [ "$1" == "--verbose" ]; then
    echo "=============================================="
    echo "  Detailed Pool Information"
    echo "=============================================="

    echo "$POOLS" | jq -r '.[].Id' | while read -r pool_id; do
        echo ""
        echo "Pool ID: $pool_id"
        echo "----------------------------------------------"

        # Get pool details
        aws cognito-idp describe-user-pool \
            --user-pool-id "$pool_id" \
            --profile "$AWS_PROFILE" \
            --region "$AWS_REGION" \
            --query 'UserPool.{Name:Name,Domain:Domain,Status:Status,MfaConfiguration:MfaConfiguration}' \
            --output table 2>/dev/null

        # Get app clients
        echo ""
        echo "App Clients:"
        aws cognito-idp list-user-pool-clients \
            --user-pool-id "$pool_id" \
            --profile "$AWS_PROFILE" \
            --region "$AWS_REGION" \
            --query 'UserPoolClients[].{ClientName:ClientName,ClientId:ClientId}' \
            --output table 2>/dev/null
    done
fi
