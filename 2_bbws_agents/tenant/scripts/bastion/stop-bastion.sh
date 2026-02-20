#!/bin/bash
################################################################################
# Stop Bastion Host to Save Costs
################################################################################
#
# Purpose: Manually stop bastion instance when migration complete
# Usage: ./stop-bastion.sh [dev|sit|prod]
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
echo "  Stopping Bastion Host - $ENVIRONMENT Environment"
echo "========================================================================"
echo ""
echo "AWS Profile: $AWS_PROFILE"
echo "AWS Region: $AWS_REGION"
echo ""

# Find bastion instance
echo "🔍 Finding bastion instance..."
INSTANCE_ID=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=${ENVIRONMENT}-wordpress-migration-bastion" \
              "Name=instance-state-name,Values=running,stopping,stopped" \
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
    stopped)
        echo -e "${YELLOW}⚠️  Bastion already stopped${NC}"
        echo ""
        echo "To start again:"
        echo "  ./start-bastion.sh $ENVIRONMENT"
        echo ""
        exit 0
        ;;
    running)
        # Check for active SSM sessions
        echo "🔍 Checking for active SSM sessions..."
        ACTIVE_SESSIONS=$(aws ssm describe-sessions \
            --state Active \
            --filters key=Target,value="$INSTANCE_ID" \
            --profile "$AWS_PROFILE" \
            --region "$AWS_REGION" \
            --query 'Sessions' \
            --output json 2>/dev/null)

        SESSION_COUNT=$(echo "$ACTIVE_SESSIONS" | jq 'length')

        if [ "$SESSION_COUNT" -gt 0 ]; then
            echo -e "${YELLOW}⚠️  Warning: $SESSION_COUNT active SSM session(s) detected${NC}"
            echo ""
            echo "Active sessions:"
            echo "$ACTIVE_SESSIONS" | jq -r '.[] | "  - Session ID: \(.SessionId), Owner: \(.Owner)"'
            echo ""
            read -p "Do you want to stop the bastion anyway? (y/N): " -n 1 -r
            echo ""
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo "Cancelled. Bastion remains running."
                exit 0
            fi
        else
            echo -e "${GREEN}✅ No active SSM sessions${NC}"
        fi
        echo ""

        echo "🛑 Stopping bastion instance..."
        aws ec2 stop-instances \
            --instance-ids "$INSTANCE_ID" \
            --profile "$AWS_PROFILE" \
            --region "$AWS_REGION" > /dev/null

        echo -e "${GREEN}✅ Bastion stop initiated${NC}"
        echo ""
        echo "⏳ Waiting for bastion to fully stop..."
        aws ec2 wait instance-stopped \
            --instance-ids "$INSTANCE_ID" \
            --profile "$AWS_PROFILE" \
            --region "$AWS_REGION"

        echo -e "${GREEN}✅ Bastion stopped successfully${NC}"
        ;;
    stopping)
        echo -e "${YELLOW}⏳ Bastion is already stopping. Waiting...${NC}"
        aws ec2 wait instance-stopped \
            --instance-ids "$INSTANCE_ID" \
            --profile "$AWS_PROFILE" \
            --region "$AWS_REGION"

        echo -e "${GREEN}✅ Bastion stopped${NC}"
        ;;
    pending)
        echo -e "${YELLOW}⚠️  Bastion is starting. Stopping...${NC}"
        aws ec2 wait instance-running \
            --instance-ids "$INSTANCE_ID" \
            --profile "$AWS_PROFILE" \
            --region "$AWS_REGION"

        echo "🛑 Stopping bastion instance..."
        aws ec2 stop-instances \
            --instance-ids "$INSTANCE_ID" \
            --profile "$AWS_PROFILE" \
            --region "$AWS_REGION" > /dev/null

        aws ec2 wait instance-stopped \
            --instance-ids "$INSTANCE_ID" \
            --profile "$AWS_PROFILE" \
            --region "$AWS_REGION"

        echo -e "${GREEN}✅ Bastion stopped${NC}"
        ;;
    *)
        echo -e "${RED}❌ Unexpected state: $CURRENT_STATE${NC}"
        exit 1
        ;;
esac

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Cost Savings"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "💰 Bastion stopped to minimize costs"
echo "📊 You're only charged for EBS storage while stopped (~\$1.60/month)"
echo "🔄 Auto-shutdown would have stopped it after 30 minutes of idle time"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Next Steps"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "To start again when needed:"
echo -e "${GREEN}  ./start-bastion.sh $ENVIRONMENT${NC}"
echo ""
echo "To check bastion status:"
echo "  aws ec2 describe-instances --instance-ids $INSTANCE_ID --profile $AWS_PROFILE --region $AWS_REGION"
echo ""
echo "========================================================================"
