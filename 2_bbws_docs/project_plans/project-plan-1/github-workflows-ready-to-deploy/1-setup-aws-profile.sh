#!/bin/bash

##############################################################################
# Script 1: Configure AWS Profile for DEV Environment
#
# This script helps you configure the AWS CLI profile for DEV account.
# You'll need your AWS Access Key ID and Secret Access Key.
#
# Usage: ./1-setup-aws-profile.sh
##############################################################################

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Step 1: Configure AWS Profile for DEV                        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

AWS_PROFILE="dev"
AWS_ACCOUNT_ID="536580886816"
AWS_REGION="eu-west-1"

echo -e "${YELLOW}This script will configure your AWS CLI profile for the DEV environment.${NC}"
echo ""
echo -e "Configuration:"
echo -e "  Profile Name: ${BLUE}${AWS_PROFILE}${NC}"
echo -e "  AWS Account:  ${BLUE}${AWS_ACCOUNT_ID}${NC}"
echo -e "  Region:       ${BLUE}${AWS_REGION}${NC}"
echo ""

# Check if profile already exists
if aws configure get aws_access_key_id --profile $AWS_PROFILE &> /dev/null; then
    echo -e "${YELLOW}⚠ AWS profile '${AWS_PROFILE}' already exists.${NC}"
    read -p "Do you want to reconfigure it? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}✓ Keeping existing profile${NC}"
        exit 0
    fi
fi

echo ""
echo -e "${YELLOW}You'll need your AWS credentials for DEV account ${AWS_ACCOUNT_ID}${NC}"
echo ""
echo -e "To get your credentials:"
echo -e "  1. Go to AWS Console: https://console.aws.amazon.com/"
echo -e "  2. Switch to DEV account (${AWS_ACCOUNT_ID})"
echo -e "  3. Click your username → Security credentials"
echo -e "  4. Create access key if you don't have one"
echo ""

read -p "Press Enter when ready to configure..."
echo ""

# Configure AWS profile
echo -e "${BLUE}Configuring AWS profile '${AWS_PROFILE}'...${NC}"
echo ""

aws configure --profile $AWS_PROFILE << EOF
$AWS_ACCESS_KEY_ID
$AWS_SECRET_ACCESS_KEY
$AWS_REGION
json
EOF

# Alternative: Let AWS CLI prompt interactively
aws configure --profile $AWS_PROFILE

echo ""
echo -e "${BLUE}Verifying configuration...${NC}"

# Verify the profile
if aws sts get-caller-identity --profile $AWS_PROFILE &> /dev/null; then
    ACTUAL_ACCOUNT=$(aws sts get-caller-identity --profile $AWS_PROFILE --query 'Account' --output text)

    echo -e "${GREEN}✓ AWS profile configured successfully${NC}"
    echo ""
    echo -e "Profile details:"
    aws sts get-caller-identity --profile $AWS_PROFILE
    echo ""

    if [ "$ACTUAL_ACCOUNT" == "$AWS_ACCOUNT_ID" ]; then
        echo -e "${GREEN}✓ Connected to correct DEV account: ${AWS_ACCOUNT_ID}${NC}"
        echo ""
        echo -e "${GREEN}═════════════════════════════════════════════════════════════${NC}"
        echo -e "${GREEN}✅ Step 1 Complete!${NC}"
        echo -e "${GREEN}═════════════════════════════════════════════════════════════${NC}"
        echo ""
        echo -e "${YELLOW}Next step: Run ./2-setup-aws-infrastructure.sh${NC}"
    else
        echo -e "${YELLOW}⚠ Warning: Connected to account ${ACTUAL_ACCOUNT}${NC}"
        echo -e "${YELLOW}  Expected DEV account: ${AWS_ACCOUNT_ID}${NC}"
        echo ""
        echo -e "${YELLOW}Please verify you're using the correct credentials.${NC}"
        exit 1
    fi
else
    echo -e "${RED}✗ Failed to verify AWS credentials${NC}"
    echo -e "${RED}Please check your Access Key ID and Secret Access Key${NC}"
    exit 1
fi
