#!/bin/bash
################################################################################
# Upgrade Bastion Host Instance Type
################################################################################
#
# Purpose: Change bastion instance type (e.g., t3a.micro -> t3a.medium)
# Usage: ./upgrade-bastion.sh [dev|sit|prod] [new_instance_type]
#
# Example: ./upgrade-bastion.sh dev t3a.medium
#
# Why upgrade?
#   t3a.micro (1GB RAM) causes OOM errors during large file transfers
#   t3a.medium (4GB RAM) eliminates SSM disconnects and AWS CLI memory issues
#
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
ENVIRONMENT=${1:-dev}
NEW_INSTANCE_TYPE=${2:-t3a.medium}

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
        echo -e "${RED}Invalid environment: $ENVIRONMENT${NC}"
        echo "Usage: $0 [dev|sit|prod] [instance_type]"
        echo "Example: $0 dev t3a.medium"
        exit 1
        ;;
esac

echo "========================================================================"
echo "  Bastion Instance Type Upgrade - $ENVIRONMENT Environment"
echo "========================================================================"
echo ""
echo "AWS Profile:      $AWS_PROFILE"
echo "AWS Region:       $AWS_REGION"
echo "New Type:         $NEW_INSTANCE_TYPE"
echo ""

# Find bastion instance
echo "Finding bastion instance..."
INSTANCE_ID=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=${ENVIRONMENT}-wordpress-migration-bastion" \
              "Name=instance-state-name,Values=stopped,stopping,running,pending" \
    --query 'Reservations[0].Instances[0].InstanceId' \
    --output text \
    --profile "$AWS_PROFILE" \
    --region "$AWS_REGION" 2>/dev/null)

if [ "$INSTANCE_ID" = "None" ] || [ -z "$INSTANCE_ID" ]; then
    echo -e "${RED}Bastion instance not found in $ENVIRONMENT${NC}"
    exit 1
fi

# Get current instance type
CURRENT_TYPE=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --query 'Reservations[0].Instances[0].InstanceType' \
    --output text \
    --profile "$AWS_PROFILE" \
    --region "$AWS_REGION")

CURRENT_STATE=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --query 'Reservations[0].Instances[0].State.Name' \
    --output text \
    --profile "$AWS_PROFILE" \
    --region "$AWS_REGION")

echo -e "${GREEN}Found bastion: $INSTANCE_ID${NC}"
echo "Current Type:     $CURRENT_TYPE"
echo "Current State:    $CURRENT_STATE"
echo ""

# Check if already the target type
if [ "$CURRENT_TYPE" = "$NEW_INSTANCE_TYPE" ]; then
    echo -e "${YELLOW}Bastion is already $NEW_INSTANCE_TYPE. No change needed.${NC}"
    exit 0
fi

# Confirm upgrade
echo "========================================================================"
echo -e "${YELLOW}  UPGRADE SUMMARY${NC}"
echo "========================================================================"
echo ""
echo "  Instance:     $INSTANCE_ID"
echo "  From:         $CURRENT_TYPE ($([ "$CURRENT_TYPE" = "t3a.micro" ] && echo "1GB RAM" || echo "?")"
echo "  To:           $NEW_INSTANCE_TYPE ($([ "$NEW_INSTANCE_TYPE" = "t3a.medium" ] && echo "4GB RAM" || echo "?")"
echo ""
echo "  Cost impact:  +~\$15/month (if always-on)"
echo ""
echo -e "${BLUE}This will require stopping the instance temporarily.${NC}"
echo ""
read -p "Proceed with upgrade? (y/N): " CONFIRM

if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    echo "Upgrade cancelled."
    exit 0
fi

echo ""
echo "========================================================================"
echo "  Starting Upgrade Process"
echo "========================================================================"
echo ""

# Step 1: Stop the instance if running
if [ "$CURRENT_STATE" = "running" ]; then
    echo "[1/4] Stopping bastion instance..."
    aws ec2 stop-instances \
        --instance-ids "$INSTANCE_ID" \
        --profile "$AWS_PROFILE" \
        --region "$AWS_REGION" > /dev/null

    echo "      Waiting for instance to stop..."
    aws ec2 wait instance-stopped \
        --instance-ids "$INSTANCE_ID" \
        --profile "$AWS_PROFILE" \
        --region "$AWS_REGION"

    echo -e "      ${GREEN}Instance stopped${NC}"
elif [ "$CURRENT_STATE" = "stopping" ]; then
    echo "[1/4] Instance is stopping, waiting..."
    aws ec2 wait instance-stopped \
        --instance-ids "$INSTANCE_ID" \
        --profile "$AWS_PROFILE" \
        --region "$AWS_REGION"
    echo -e "      ${GREEN}Instance stopped${NC}"
else
    echo "[1/4] Instance already stopped"
fi

# Step 2: Modify instance type
echo "[2/4] Modifying instance type to $NEW_INSTANCE_TYPE..."
aws ec2 modify-instance-attribute \
    --instance-id "$INSTANCE_ID" \
    --instance-type "{\"Value\": \"$NEW_INSTANCE_TYPE\"}" \
    --profile "$AWS_PROFILE" \
    --region "$AWS_REGION"
echo -e "      ${GREEN}Instance type modified${NC}"

# Step 3: Start the instance
echo "[3/4] Starting bastion instance..."
aws ec2 start-instances \
    --instance-ids "$INSTANCE_ID" \
    --profile "$AWS_PROFILE" \
    --region "$AWS_REGION" > /dev/null

echo "      Waiting for instance to start..."
aws ec2 wait instance-running \
    --instance-ids "$INSTANCE_ID" \
    --profile "$AWS_PROFILE" \
    --region "$AWS_REGION"
echo -e "      ${GREEN}Instance started${NC}"

# Step 4: Verify
echo "[4/4] Verifying upgrade..."
VERIFIED_TYPE=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --query 'Reservations[0].Instances[0].InstanceType' \
    --output text \
    --profile "$AWS_PROFILE" \
    --region "$AWS_REGION")

echo ""
echo "========================================================================"
if [ "$VERIFIED_TYPE" = "$NEW_INSTANCE_TYPE" ]; then
    echo -e "  ${GREEN}UPGRADE SUCCESSFUL${NC}"
    echo "========================================================================"
    echo ""
    echo "  Instance:     $INSTANCE_ID"
    echo "  New Type:     $VERIFIED_TYPE"
    echo "  RAM:          $([ "$VERIFIED_TYPE" = "t3a.medium" ] && echo "4GB" || echo "?")"
    echo ""
    echo "  The bastion now has sufficient memory for:"
    echo "    - Large S3 sync operations"
    echo "    - AWS CLI with many files"
    echo "    - SSM sessions during heavy I/O"
    echo ""
    echo "  Connect with:"
    echo -e "    ${GREEN}./connect-bastion.sh $ENVIRONMENT${NC}"
else
    echo -e "  ${RED}UPGRADE VERIFICATION FAILED${NC}"
    echo "========================================================================"
    echo "  Expected: $NEW_INSTANCE_TYPE"
    echo "  Got:      $VERIFIED_TYPE"
    echo ""
    echo "  Please check AWS Console for instance status."
fi
echo ""
