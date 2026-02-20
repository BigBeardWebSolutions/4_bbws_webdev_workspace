#!/bin/bash

##############################################################################
# Script 2: Setup AWS Infrastructure for GitHub Actions
#
# This script creates:
# - OIDC provider for GitHub Actions
# - IAM role for GitHub Actions deployments
# - S3 bucket for Terraform state
# - DynamoDB table for state locking
#
# Usage: ./2-setup-aws-infrastructure.sh <github-owner>
# Example: ./2-setup-aws-infrastructure.sh tsekatm
##############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
AWS_PROFILE="dev"
AWS_ACCOUNT_ID="536580886816"
AWS_REGION="eu-west-1"
IAM_ROLE_NAME="bbws-terraform-deployer-dev"
STATE_BUCKET="bbws-terraform-state-dev"
LOCK_TABLE="terraform-state-lock-dev"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Step 2: Setup AWS Infrastructure for GitHub Actions          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check argument
if [ $# -ne 1 ]; then
    echo -e "${RED}❌ Error: Missing GitHub owner argument${NC}"
    echo "Usage: $0 <github-owner>"
    echo "Example: $0 tsekatm"
    exit 1
fi

GITHUB_OWNER=$1

echo -e "Configuration:"
echo -e "  AWS Account:    ${BLUE}${AWS_ACCOUNT_ID}${NC}"
echo -e "  AWS Region:     ${BLUE}${AWS_REGION}${NC}"
echo -e "  GitHub Owner:   ${BLUE}${GITHUB_OWNER}${NC}"
echo -e "  IAM Role:       ${BLUE}${IAM_ROLE_NAME}${NC}"
echo -e "  State Bucket:   ${BLUE}${STATE_BUCKET}${NC}"
echo -e "  Lock Table:     ${BLUE}${LOCK_TABLE}${NC}"
echo ""

# Verify AWS profile is configured
if ! aws sts get-caller-identity --profile $AWS_PROFILE &> /dev/null; then
    echo -e "${RED}✗ AWS profile '${AWS_PROFILE}' is not configured${NC}"
    echo -e "${YELLOW}→ Run: ./1-setup-aws-profile.sh first${NC}"
    exit 1
fi

ACTUAL_ACCOUNT=$(aws sts get-caller-identity --profile $AWS_PROFILE --query 'Account' --output text)
if [ "$ACTUAL_ACCOUNT" != "$AWS_ACCOUNT_ID" ]; then
    echo -e "${RED}✗ Connected to wrong AWS account: ${ACTUAL_ACCOUNT}${NC}"
    echo -e "${RED}  Expected: ${AWS_ACCOUNT_ID}${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Connected to DEV account: ${AWS_ACCOUNT_ID}${NC}"
echo ""

##############################################################################
# Step 2.1: Create OIDC Provider
##############################################################################
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}[2.1/4] Creating OIDC Provider${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check if OIDC provider already exists
OIDC_PROVIDERS=$(aws iam list-open-id-connect-providers --profile $AWS_PROFILE --query 'OpenIDConnectProviderList[*].Arn' --output text 2>/dev/null)

if echo "$OIDC_PROVIDERS" | grep -q "token.actions.githubusercontent.com"; then
    OIDC_ARN=$(echo "$OIDC_PROVIDERS" | tr '\t' '\n' | grep "token.actions.githubusercontent.com")
    echo -e "${GREEN}✓ OIDC provider already exists${NC}"
    echo -e "  ARN: ${OIDC_ARN}"
else
    echo -e "${YELLOW}Creating OIDC provider for GitHub Actions...${NC}"

    aws iam create-open-id-connect-provider \
      --url https://token.actions.githubusercontent.com \
      --client-id-list sts.amazonaws.com \
      --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
      --profile $AWS_PROFILE

    echo -e "${GREEN}✓ OIDC provider created successfully${NC}"

    # Get the ARN
    OIDC_PROVIDERS=$(aws iam list-open-id-connect-providers --profile $AWS_PROFILE --query 'OpenIDConnectProviderList[*].Arn' --output text)
    OIDC_ARN=$(echo "$OIDC_PROVIDERS" | tr '\t' '\n' | grep "token.actions.githubusercontent.com")
    echo -e "  ARN: ${OIDC_ARN}"
fi

echo ""

##############################################################################
# Step 2.2: Create IAM Role with Trust Policy
##############################################################################
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}[2.2/4] Creating IAM Role for GitHub Actions${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Create trust policy file
TRUST_POLICY_FILE="/tmp/trust-policy-${AWS_ACCOUNT_ID}.json"

cat > $TRUST_POLICY_FILE <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:${GITHUB_OWNER}/*:*"
        }
      }
    }
  ]
}
EOF

echo -e "${YELLOW}Trust policy created for GitHub owner: ${GITHUB_OWNER}${NC}"

# Check if role already exists
if aws iam get-role --role-name $IAM_ROLE_NAME --profile $AWS_PROFILE &> /dev/null; then
    echo -e "${GREEN}✓ IAM role '${IAM_ROLE_NAME}' already exists${NC}"

    # Update trust policy
    echo -e "${YELLOW}Updating trust policy...${NC}"
    aws iam update-assume-role-policy \
      --role-name $IAM_ROLE_NAME \
      --policy-document file://$TRUST_POLICY_FILE \
      --profile $AWS_PROFILE

    echo -e "${GREEN}✓ Trust policy updated${NC}"
else
    echo -e "${YELLOW}Creating IAM role...${NC}"

    aws iam create-role \
      --role-name $IAM_ROLE_NAME \
      --assume-role-policy-document file://$TRUST_POLICY_FILE \
      --description "GitHub Actions deployment role for BBWS DEV environment" \
      --profile $AWS_PROFILE

    echo -e "${GREEN}✓ IAM role created${NC}"
fi

ROLE_ARN=$(aws iam get-role --role-name $IAM_ROLE_NAME --profile $AWS_PROFILE --query 'Role.Arn' --output text)
echo -e "  ARN: ${ROLE_ARN}"

# Clean up trust policy file
rm -f $TRUST_POLICY_FILE

echo ""
echo -e "${YELLOW}Attaching policies to role...${NC}"

# Attach managed policies
POLICIES=(
    "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
    "arn:aws:iam::aws:policy/AmazonS3FullAccess"
    "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
)

for POLICY_ARN in "${POLICIES[@]}"; do
    POLICY_NAME=$(echo $POLICY_ARN | awk -F'/' '{print $NF}')

    # Check if already attached
    if aws iam list-attached-role-policies --role-name $IAM_ROLE_NAME --profile $AWS_PROFILE | grep -q "$POLICY_ARN"; then
        echo -e "${GREEN}  ✓ ${POLICY_NAME} already attached${NC}"
    else
        aws iam attach-role-policy \
          --role-name $IAM_ROLE_NAME \
          --policy-arn $POLICY_ARN \
          --profile $AWS_PROFILE

        echo -e "${GREEN}  ✓ Attached ${POLICY_NAME}${NC}"
    fi
done

echo ""

##############################################################################
# Step 2.3: Create S3 State Bucket
##############################################################################
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}[2.3/4] Creating S3 Bucket for Terraform State${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check if bucket already exists
if aws s3api head-bucket --bucket $STATE_BUCKET --profile $AWS_PROFILE 2>/dev/null; then
    echo -e "${GREEN}✓ S3 bucket '${STATE_BUCKET}' already exists${NC}"
else
    echo -e "${YELLOW}Creating S3 bucket...${NC}"

    aws s3api create-bucket \
      --bucket $STATE_BUCKET \
      --region $AWS_REGION \
      --create-bucket-configuration LocationConstraint=$AWS_REGION \
      --profile $AWS_PROFILE

    echo -e "${GREEN}✓ S3 bucket created${NC}"
fi

# Enable versioning
echo -e "${YELLOW}Enabling versioning...${NC}"
aws s3api put-bucket-versioning \
  --bucket $STATE_BUCKET \
  --versioning-configuration Status=Enabled \
  --profile $AWS_PROFILE

echo -e "${GREEN}✓ Versioning enabled${NC}"

# Enable encryption
echo -e "${YELLOW}Enabling encryption...${NC}"
aws s3api put-bucket-encryption \
  --bucket $STATE_BUCKET \
  --server-side-encryption-configuration '{
    "Rules": [
      {
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "AES256"
        },
        "BucketKeyEnabled": true
      }
    ]
  }' \
  --profile $AWS_PROFILE

echo -e "${GREEN}✓ Encryption enabled${NC}"

# Block public access
echo -e "${YELLOW}Blocking public access...${NC}"
aws s3api put-public-access-block \
  --bucket $STATE_BUCKET \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" \
  --profile $AWS_PROFILE

echo -e "${GREEN}✓ Public access blocked${NC}"
echo ""

##############################################################################
# Step 2.4: Create DynamoDB Lock Table
##############################################################################
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}[2.4/4] Creating DynamoDB Table for State Locking${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check if table already exists
if aws dynamodb describe-table --table-name $LOCK_TABLE --region $AWS_REGION --profile $AWS_PROFILE &> /dev/null; then
    echo -e "${GREEN}✓ DynamoDB table '${LOCK_TABLE}' already exists${NC}"
else
    echo -e "${YELLOW}Creating DynamoDB table...${NC}"

    aws dynamodb create-table \
      --table-name $LOCK_TABLE \
      --attribute-definitions AttributeName=LockID,AttributeType=S \
      --key-schema AttributeName=LockID,KeyType=HASH \
      --billing-mode PAY_PER_REQUEST \
      --region $AWS_REGION \
      --profile $AWS_PROFILE

    echo -e "${GREEN}✓ DynamoDB table created${NC}"

    # Wait for table to be active
    echo -e "${YELLOW}Waiting for table to be active...${NC}"
    aws dynamodb wait table-exists --table-name $LOCK_TABLE --region $AWS_REGION --profile $AWS_PROFILE
    echo -e "${GREEN}✓ Table is active${NC}"
fi

echo ""

##############################################################################
# Summary
##############################################################################
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅ Step 2 Complete!                                           ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}AWS Infrastructure Setup Summary:${NC}"
echo ""
echo -e "${GREEN}✓${NC} OIDC Provider:     ${OIDC_ARN}"
echo -e "${GREEN}✓${NC} IAM Role:          ${ROLE_ARN}"
echo -e "${GREEN}✓${NC} S3 State Bucket:   s3://${STATE_BUCKET} (${AWS_REGION})"
echo -e "${GREEN}✓${NC} DynamoDB Lock:     ${LOCK_TABLE} (${AWS_REGION})"
echo ""
echo -e "${YELLOW}Next step: Run ./3-setup-github.sh tsekatm 2_1_bbws_dynamodb_schemas${NC}"
echo ""
