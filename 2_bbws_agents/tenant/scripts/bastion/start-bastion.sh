#!/bin/bash
################################################################################
# Start Bastion Host for WordPress Migration
################################################################################
#
# Purpose: Start stopped bastion instance and wait until running
# Usage: ./start-bastion.sh [dev|sit|prod]
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
echo "  Starting Bastion Host - $ENVIRONMENT Environment"
echo "========================================================================"
echo ""
echo "AWS Profile: $AWS_PROFILE"
echo "AWS Region: $AWS_REGION"
echo ""

# Find bastion instance
echo "🔍 Finding bastion instance..."
INSTANCE_ID=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=${ENVIRONMENT}-wordpress-migration-bastion" \
              "Name=instance-state-name,Values=stopped,stopping,running" \
    --query 'Reservations[0].Instances[0].InstanceId' \
    --output text \
    --profile "$AWS_PROFILE" \
    --region "$AWS_REGION" 2>/dev/null)

if [ "$INSTANCE_ID" = "None" ] || [ -z "$INSTANCE_ID" ]; then
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

echo -e "${GREEN}✅ Found bastion: $INSTANCE_ID${NC}"
echo ""

# Check current state
CURRENT_STATE=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --query 'Reservations[0].Instances[0].State.Name' \
    --output text \
    --profile "$AWS_PROFILE" \
    --region "$AWS_REGION")

echo "Current state: $CURRENT_STATE"
echo ""

# Handle based on current state
case $CURRENT_STATE in
    running)
        echo -e "${YELLOW}⚠️  Bastion already running${NC}"
        ;;
    stopped)
        echo "🚀 Starting bastion instance..."
        aws ec2 start-instances \
            --instance-ids "$INSTANCE_ID" \
            --profile "$AWS_PROFILE" \
            --region "$AWS_REGION" > /dev/null

        echo "⏳ Waiting for bastion to be running..."
        aws ec2 wait instance-running \
            --instance-ids "$INSTANCE_ID" \
            --profile "$AWS_PROFILE" \
            --region "$AWS_REGION"

        echo -e "${GREEN}✅ Bastion started successfully${NC}"
        ;;
    stopping)
        echo -e "${YELLOW}⏳ Bastion is currently stopping. Waiting...${NC}"
        aws ec2 wait instance-stopped \
            --instance-ids "$INSTANCE_ID" \
            --profile "$AWS_PROFILE" \
            --region "$AWS_REGION"

        echo "🚀 Starting bastion instance..."
        aws ec2 start-instances \
            --instance-ids "$INSTANCE_ID" \
            --profile "$AWS_PROFILE" \
            --region "$AWS_REGION" > /dev/null

        echo "⏳ Waiting for bastion to be running..."
        aws ec2 wait instance-running \
            --instance-ids "$INSTANCE_ID" \
            --profile "$AWS_PROFILE" \
            --region "$AWS_REGION"

        echo -e "${GREEN}✅ Bastion started successfully${NC}"
        ;;
    pending)
        echo -e "${YELLOW}⏳ Bastion is starting. Waiting...${NC}"
        aws ec2 wait instance-running \
            --instance-ids "$INSTANCE_ID" \
            --profile "$AWS_PROFILE" \
            --region "$AWS_REGION"

        echo -e "${GREEN}✅ Bastion running${NC}"
        ;;
    *)
        echo -e "${RED}❌ Unexpected state: $CURRENT_STATE${NC}"
        exit 1
        ;;
esac

# Get instance details
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Bastion Instance Details"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

INSTANCE_INFO=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --query 'Reservations[0].Instances[0]' \
    --profile "$AWS_PROFILE" \
    --region "$AWS_REGION")

PUBLIC_IP=$(echo "$INSTANCE_INFO" | jq -r '.PublicIpAddress // "N/A"')
PRIVATE_IP=$(echo "$INSTANCE_INFO" | jq -r '.PrivateIpAddress // "N/A"')
INSTANCE_TYPE=$(echo "$INSTANCE_INFO" | jq -r '.InstanceType')
AZ=$(echo "$INSTANCE_INFO" | jq -r '.Placement.AvailabilityZone')

echo "Instance ID:  $INSTANCE_ID"
echo "State:        running"
echo "Type:         $INSTANCE_TYPE"
echo "Public IP:    $PUBLIC_IP"
echo "Private IP:   $PRIVATE_IP"
echo "AZ:           $AZ"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Connection Instructions"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Connect via SSM Session Manager:"
echo -e "${GREEN}  aws ssm start-session --target $INSTANCE_ID --profile $AWS_PROFILE --region $AWS_REGION${NC}"
echo ""
echo "Or use the connect script:"
echo -e "${GREEN}  ./connect-bastion.sh $ENVIRONMENT${NC}"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Auto-Shutdown Info"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "⏰ Bastion will auto-stop after 30 minutes of idle time"
echo "📊 Monitored: CPU usage, network I/O, SSM sessions"
echo "📧 Notification: SNS alert when auto-stopped"
echo ""
echo "To stop manually:"
echo "  ./stop-bastion.sh $ENVIRONMENT"
echo ""
echo "========================================================================"
