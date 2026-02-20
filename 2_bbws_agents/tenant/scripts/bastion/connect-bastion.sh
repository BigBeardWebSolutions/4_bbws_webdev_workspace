#!/bin/bash
################################################################################
# Connect to Bastion Host via SSM Session Manager
################################################################################
#
# Purpose: Connect to bastion instance using AWS SSM (no SSH keys required)
# Usage: ./connect-bastion.sh [dev|sit|prod]
#
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default environment
ENVIRONMENT=${1:-dev}

# Environment configuration
case $ENVIRONMENT in
    dev)
        AWS_PROFILE="dev"
        AWS_REGION="eu-west-1"
        ;;
    sit)
        AWS_PROFILE="sit"
        AWS_REGION="eu-west-1"
        ;;
    prod)
        AWS_PROFILE="prod"
        AWS_REGION="af-south-1"
        ;;
    *)
        echo -e "${RED}❌ Invalid environment: $ENVIRONMENT${NC}"
        echo "Usage: $0 [dev|sit|prod]"
        exit 1
        ;;
esac

echo "========================================================================"
echo "  Connecting to Bastion Host - $ENVIRONMENT Environment"
echo "========================================================================"
echo ""
echo "AWS Profile: $AWS_PROFILE"
echo "AWS Region: $AWS_REGION"
echo ""

# Find bastion instance
echo "🔍 Finding bastion instance..."
INSTANCE_ID=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=${ENVIRONMENT}-wordpress-migration-bastion" \
              "Name=instance-state-name,Values=running,pending" \
    --query 'Reservations[0].Instances[0].InstanceId' \
    --output text \
    --profile "$AWS_PROFILE" \
    --region "$AWS_REGION" 2>/dev/null)

if [ "$INSTANCE_ID" = "None" ] || [ -z "$INSTANCE_ID" ]; then
    # Check if instance exists but is stopped
    STOPPED_INSTANCE=$(aws ec2 describe-instances \
        --filters "Name=tag:Name,Values=${ENVIRONMENT}-wordpress-migration-bastion" \
                  "Name=instance-state-name,Values=stopped" \
        --query 'Reservations[0].Instances[0].InstanceId' \
        --output text \
        --profile "$AWS_PROFILE" \
        --region "$AWS_REGION" 2>/dev/null)

    if [ "$STOPPED_INSTANCE" != "None" ] && [ -n "$STOPPED_INSTANCE" ]; then
        echo -e "${YELLOW}⚠️  Bastion is stopped${NC}"
        echo ""
        echo "Start it first:"
        echo -e "${GREEN}  ./start-bastion.sh $ENVIRONMENT${NC}"
        echo ""
        exit 1
    else
        echo -e "${RED}❌ Bastion instance not found in $ENVIRONMENT${NC}"
        echo ""
        echo "Expected instance name: ${ENVIRONMENT}-wordpress-migration-bastion"
        echo ""
        echo "Troubleshooting:"
        echo "  1. Verify instance exists in AWS Console"
        echo "  2. Check instance tags (Name, Environment)"
        echo "  3. Verify AWS credentials: aws sts get-caller-identity --profile $AWS_PROFILE"
        exit 1
    fi
fi

echo -e "${GREEN}✅ Found bastion: $INSTANCE_ID${NC}"
echo ""

# Check instance state
CURRENT_STATE=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --query 'Reservations[0].Instances[0].State.Name' \
    --output text \
    --profile "$AWS_PROFILE" \
    --region "$AWS_REGION")

if [ "$CURRENT_STATE" = "pending" ]; then
    echo "⏳ Bastion is starting. Waiting for it to be running..."
    aws ec2 wait instance-running \
        --instance-ids "$INSTANCE_ID" \
        --profile "$AWS_PROFILE" \
        --region "$AWS_REGION"
    echo -e "${GREEN}✅ Bastion running${NC}"
    echo ""
fi

# Check if SSM plugin is installed
if ! command -v session-manager-plugin &> /dev/null; then
    echo -e "${RED}❌ AWS SSM Session Manager plugin not installed${NC}"
    echo ""
    echo "Install instructions:"
    echo "  macOS:   brew install --cask session-manager-plugin"
    echo "  Linux:   https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html"
    echo "  Windows: https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html"
    echo ""
    exit 1
fi

# Display connection info
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Migration Tools Available"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Pre-installed tools:"
echo "  • WP-CLI:       /usr/local/bin/wp --info"
echo "  • MySQL Client: mysql --version"
echo "  • AWS CLI:      aws --version"
echo "  • PHP CLI:      php --version"
echo ""
echo "Helper scripts:"
echo "  • Mount EFS:    /usr/local/bin/migration-helpers/mount-efs.sh"
echo "  • Connect RDS:  /usr/local/bin/migration-helpers/connect-rds.sh"
echo ""
echo "Documentation:"
echo "  • View MOTD:    cat /etc/motd"
echo "  • Bootstrap log: tail -f /var/log/user-data.log"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Connecting via SSM Session Manager"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🔌 Establishing secure session..."
echo ""

# Connect to bastion
aws ssm start-session \
    --target "$INSTANCE_ID" \
    --profile "$AWS_PROFILE" \
    --region "$AWS_REGION"

# After session ends
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Session Ended"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Remember:"
echo "  • Bastion will auto-stop after 30 minutes of idle time"
echo "  • Stop manually to save costs: ./stop-bastion.sh $ENVIRONMENT"
echo "  • Reconnect anytime: ./connect-bastion.sh $ENVIRONMENT"
echo ""
echo "========================================================================"
