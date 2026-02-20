#!/bin/bash

##############################################################################
# OIDC and GitHub Actions Setup Diagnostic Script
#
# This script checks if all prerequisites are configured for the DEV pipeline:
# - AWS OIDC provider
# - IAM role for GitHub Actions
# - GitHub secrets
# - GitHub environment
# - Terraform state infrastructure
#
# Usage: ./check-setup.sh <github-owner> <github-repo>
# Example: ./check-setup.sh tebogotseka 2_1_bbws_dynamodb_schemas
##############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
AWS_PROFILE="dev"
AWS_ACCOUNT_ID="536580886816"
AWS_REGION="eu-west-1"
IAM_ROLE_NAME="bbws-terraform-deployer-dev"
STATE_BUCKET="bbws-terraform-state-dev"
LOCK_TABLE="terraform-state-lock-dev"

# Check arguments
if [ $# -ne 2 ]; then
    echo -e "${RED}❌ Error: Missing arguments${NC}"
    echo "Usage: $0 <github-owner> <github-repo>"
    echo "Example: $0 tebogotseka 2_1_bbws_dynamodb_schemas"
    exit 1
fi

GITHUB_OWNER=$1
GITHUB_REPO=$2

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  OIDC and GitHub Actions Setup Diagnostic                     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Configuration:${NC}"
echo -e "  AWS Account:    ${AWS_ACCOUNT_ID}"
echo -e "  AWS Region:     ${AWS_REGION}"
echo -e "  GitHub Owner:   ${GITHUB_OWNER}"
echo -e "  GitHub Repo:    ${GITHUB_REPO}"
echo ""

# Track overall status
ALL_CHECKS_PASSED=true

##############################################################################
# CHECK 1: AWS CLI Configuration
##############################################################################
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}[1/8] Checking AWS CLI Configuration${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if command -v aws &> /dev/null; then
    echo -e "${GREEN}✓${NC} AWS CLI is installed"

    # Check if profile is configured
    if aws configure get aws_access_key_id --profile $AWS_PROFILE &> /dev/null; then
        echo -e "${GREEN}✓${NC} AWS profile '${AWS_PROFILE}' is configured"

        # Verify account ID
        ACTUAL_ACCOUNT=$(aws sts get-caller-identity --profile $AWS_PROFILE --query 'Account' --output text 2>/dev/null)
        if [ "$ACTUAL_ACCOUNT" == "$AWS_ACCOUNT_ID" ]; then
            echo -e "${GREEN}✓${NC} Connected to correct AWS account: ${AWS_ACCOUNT_ID}"
        else
            echo -e "${RED}✗${NC} Connected to wrong AWS account: ${ACTUAL_ACCOUNT} (expected: ${AWS_ACCOUNT_ID})"
            ALL_CHECKS_PASSED=false
        fi
    else
        echo -e "${RED}✗${NC} AWS profile '${AWS_PROFILE}' is NOT configured"
        echo -e "${YELLOW}  → Run: aws configure --profile ${AWS_PROFILE}${NC}"
        ALL_CHECKS_PASSED=false
    fi
else
    echo -e "${RED}✗${NC} AWS CLI is NOT installed"
    echo -e "${YELLOW}  → Install: brew install awscli${NC}"
    ALL_CHECKS_PASSED=false
fi

echo ""

##############################################################################
# CHECK 2: GitHub CLI Configuration
##############################################################################
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}[2/8] Checking GitHub CLI Configuration${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if command -v gh &> /dev/null; then
    echo -e "${GREEN}✓${NC} GitHub CLI is installed"

    # Check if authenticated
    if gh auth status &> /dev/null; then
        echo -e "${GREEN}✓${NC} GitHub CLI is authenticated"
        GH_USER=$(gh api user -q .login 2>/dev/null)
        echo -e "  Authenticated as: ${GH_USER}"
    else
        echo -e "${RED}✗${NC} GitHub CLI is NOT authenticated"
        echo -e "${YELLOW}  → Run: gh auth login${NC}"
        ALL_CHECKS_PASSED=false
    fi
else
    echo -e "${RED}✗${NC} GitHub CLI is NOT installed"
    echo -e "${YELLOW}  → Install: brew install gh${NC}"
    ALL_CHECKS_PASSED=false
fi

echo ""

##############################################################################
# CHECK 3: AWS OIDC Provider
##############################################################################
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}[3/8] Checking AWS OIDC Provider${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

OIDC_PROVIDERS=$(aws iam list-open-id-connect-providers --profile $AWS_PROFILE --query 'OpenIDConnectProviderList[*].Arn' --output text 2>/dev/null)

if echo "$OIDC_PROVIDERS" | grep -q "token.actions.githubusercontent.com"; then
    OIDC_ARN=$(echo "$OIDC_PROVIDERS" | tr '\t' '\n' | grep "token.actions.githubusercontent.com")
    echo -e "${GREEN}✓${NC} OIDC provider for GitHub Actions exists"
    echo -e "  ARN: ${OIDC_ARN}"
else
    echo -e "${RED}✗${NC} OIDC provider for GitHub Actions does NOT exist"
    echo -e "${YELLOW}  → Create with:${NC}"
    echo -e "${YELLOW}     aws iam create-open-id-connect-provider \\${NC}"
    echo -e "${YELLOW}       --url https://token.actions.githubusercontent.com \\${NC}"
    echo -e "${YELLOW}       --client-id-list sts.amazonaws.com \\${NC}"
    echo -e "${YELLOW}       --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \\${NC}"
    echo -e "${YELLOW}       --profile ${AWS_PROFILE}${NC}"
    ALL_CHECKS_PASSED=false
fi

echo ""

##############################################################################
# CHECK 4: IAM Role for GitHub Actions
##############################################################################
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}[4/8] Checking IAM Role for GitHub Actions${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if aws iam get-role --role-name $IAM_ROLE_NAME --profile $AWS_PROFILE &> /dev/null; then
    echo -e "${GREEN}✓${NC} IAM role '${IAM_ROLE_NAME}' exists"

    ROLE_ARN=$(aws iam get-role --role-name $IAM_ROLE_NAME --profile $AWS_PROFILE --query 'Role.Arn' --output text)
    echo -e "  ARN: ${ROLE_ARN}"

    # Check trust policy
    TRUST_POLICY=$(aws iam get-role --role-name $IAM_ROLE_NAME --profile $AWS_PROFILE --query 'Role.AssumeRolePolicyDocument' 2>/dev/null)

    if echo "$TRUST_POLICY" | grep -q "token.actions.githubusercontent.com"; then
        echo -e "${GREEN}✓${NC} Role has OIDC trust policy"

        # Check if it includes the specific repo
        if echo "$TRUST_POLICY" | grep -q "$GITHUB_OWNER"; then
            echo -e "${GREEN}✓${NC} Trust policy includes GitHub owner: ${GITHUB_OWNER}"
        else
            echo -e "${YELLOW}⚠${NC} Trust policy may not include your GitHub owner: ${GITHUB_OWNER}"
            echo -e "${YELLOW}  → Verify trust policy allows: repo:${GITHUB_OWNER}/*:*${NC}"
        fi
    else
        echo -e "${RED}✗${NC} Role does NOT have OIDC trust policy"
        ALL_CHECKS_PASSED=false
    fi

    # Check attached policies
    ATTACHED_POLICIES=$(aws iam list-attached-role-policies --role-name $IAM_ROLE_NAME --profile $AWS_PROFILE --query 'AttachedPolicies[*].PolicyName' --output text 2>/dev/null)

    if [ -n "$ATTACHED_POLICIES" ]; then
        echo -e "${GREEN}✓${NC} Role has attached policies:"
        echo "$ATTACHED_POLICIES" | tr '\t' '\n' | sed 's/^/    - /'
    else
        echo -e "${YELLOW}⚠${NC} Role has NO attached policies"
    fi

else
    echo -e "${RED}✗${NC} IAM role '${IAM_ROLE_NAME}' does NOT exist"
    echo -e "${YELLOW}  → See: human-steps.md (Step 3) for creation instructions${NC}"
    ALL_CHECKS_PASSED=false
fi

echo ""

##############################################################################
# CHECK 5: Terraform State Infrastructure
##############################################################################
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}[5/8] Checking Terraform State Infrastructure${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Check S3 state bucket
if aws s3api head-bucket --bucket $STATE_BUCKET --profile $AWS_PROFILE 2>/dev/null; then
    echo -e "${GREEN}✓${NC} S3 state bucket '${STATE_BUCKET}' exists"

    # Check versioning
    VERSIONING=$(aws s3api get-bucket-versioning --bucket $STATE_BUCKET --profile $AWS_PROFILE --query 'Status' --output text 2>/dev/null)
    if [ "$VERSIONING" == "Enabled" ]; then
        echo -e "${GREEN}✓${NC} Bucket versioning is enabled"
    else
        echo -e "${YELLOW}⚠${NC} Bucket versioning is NOT enabled"
    fi

    # Check location
    BUCKET_REGION=$(aws s3api get-bucket-location --bucket $STATE_BUCKET --profile $AWS_PROFILE --query 'LocationConstraint' --output text 2>/dev/null)
    if [ "$BUCKET_REGION" == "$AWS_REGION" ] || ([ "$BUCKET_REGION" == "None" ] && [ "$AWS_REGION" == "us-east-1" ]); then
        echo -e "${GREEN}✓${NC} Bucket is in correct region: ${AWS_REGION}"
    else
        echo -e "${RED}✗${NC} Bucket is in wrong region: ${BUCKET_REGION} (expected: ${AWS_REGION})"
        ALL_CHECKS_PASSED=false
    fi
else
    echo -e "${RED}✗${NC} S3 state bucket '${STATE_BUCKET}' does NOT exist"
    echo -e "${YELLOW}  → See: human-steps.md (Step 2) for creation instructions${NC}"
    ALL_CHECKS_PASSED=false
fi

# Check DynamoDB lock table
if aws dynamodb describe-table --table-name $LOCK_TABLE --region $AWS_REGION --profile $AWS_PROFILE &> /dev/null; then
    echo -e "${GREEN}✓${NC} DynamoDB lock table '${LOCK_TABLE}' exists"

    BILLING_MODE=$(aws dynamodb describe-table --table-name $LOCK_TABLE --region $AWS_REGION --profile $AWS_PROFILE --query 'Table.BillingModeSummary.BillingMode' --output text 2>/dev/null)
    if [ "$BILLING_MODE" == "PAY_PER_REQUEST" ]; then
        echo -e "${GREEN}✓${NC} Table uses PAY_PER_REQUEST billing"
    else
        echo -e "${YELLOW}⚠${NC} Table uses ${BILLING_MODE} billing (expected: PAY_PER_REQUEST)"
    fi
else
    echo -e "${RED}✗${NC} DynamoDB lock table '${LOCK_TABLE}' does NOT exist"
    echo -e "${YELLOW}  → See: human-steps.md (Step 2) for creation instructions${NC}"
    ALL_CHECKS_PASSED=false
fi

echo ""

##############################################################################
# CHECK 6: GitHub Repository Secrets
##############################################################################
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}[6/8] Checking GitHub Repository Secrets${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if command -v gh &> /dev/null && gh auth status &> /dev/null; then
    SECRETS=$(gh secret list --repo $GITHUB_OWNER/$GITHUB_REPO 2>/dev/null)

    if [ $? -eq 0 ]; then
        if echo "$SECRETS" | grep -q "AWS_ROLE_DEV"; then
            echo -e "${GREEN}✓${NC} GitHub secret 'AWS_ROLE_DEV' exists"
        else
            echo -e "${RED}✗${NC} GitHub secret 'AWS_ROLE_DEV' does NOT exist"
            echo -e "${YELLOW}  → Add secret with value: arn:aws:iam::${AWS_ACCOUNT_ID}:role/${IAM_ROLE_NAME}${NC}"
            ALL_CHECKS_PASSED=false
        fi

        # List all secrets
        if [ -n "$SECRETS" ]; then
            echo -e "  All secrets:"
            echo "$SECRETS" | awk '{print "    - " $1}'
        fi
    else
        echo -e "${YELLOW}⚠${NC} Unable to check GitHub secrets (may not have permission)"
        echo -e "${YELLOW}  → Manually verify secret 'AWS_ROLE_DEV' exists in repo settings${NC}"
    fi
else
    echo -e "${YELLOW}⚠${NC} Cannot check GitHub secrets (GitHub CLI not available)"
fi

echo ""

##############################################################################
# CHECK 7: GitHub Environment
##############################################################################
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}[7/8] Checking GitHub Environment${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if command -v gh &> /dev/null && gh auth status &> /dev/null; then
    ENVIRONMENTS=$(gh api repos/$GITHUB_OWNER/$GITHUB_REPO/environments --jq '.environments[].name' 2>/dev/null)

    if [ $? -eq 0 ]; then
        if echo "$ENVIRONMENTS" | grep -q "^dev$"; then
            echo -e "${GREEN}✓${NC} GitHub environment 'dev' exists"
        else
            echo -e "${YELLOW}⚠${NC} GitHub environment 'dev' does NOT exist (optional for DEV)"
            echo -e "${YELLOW}  → Create environment in: Settings → Environments${NC}"
        fi

        # List all environments
        if [ -n "$ENVIRONMENTS" ]; then
            echo -e "  All environments:"
            echo "$ENVIRONMENTS" | sed 's/^/    - /'
        fi
    else
        echo -e "${YELLOW}⚠${NC} Unable to check GitHub environments (may not have permission)"
    fi
else
    echo -e "${YELLOW}⚠${NC} Cannot check GitHub environments (GitHub CLI not available)"
fi

echo ""

##############################################################################
# CHECK 8: GitHub Workflow File
##############################################################################
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}[8/8] Checking GitHub Workflow File${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if command -v gh &> /dev/null && gh auth status &> /dev/null; then
    # Try to get workflow file
    WORKFLOW_EXISTS=$(gh api repos/$GITHUB_OWNER/$GITHUB_REPO/contents/.github/workflows/deploy-dev.yml 2>/dev/null)

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} Workflow file '.github/workflows/deploy-dev.yml' exists in repository"

        # List all workflows
        WORKFLOWS=$(gh workflow list --repo $GITHUB_OWNER/$GITHUB_REPO 2>/dev/null)
        if [ -n "$WORKFLOWS" ]; then
            echo -e "  All workflows:"
            echo "$WORKFLOWS" | awk '{print "    - " $1}'
        fi
    else
        echo -e "${RED}✗${NC} Workflow file '.github/workflows/deploy-dev.yml' does NOT exist in repository"
        echo -e "${YELLOW}  → Copy workflow file from: github-workflows-ready-to-deploy/.github/workflows/${NC}"
        ALL_CHECKS_PASSED=false
    fi
else
    echo -e "${YELLOW}⚠${NC} Cannot check workflow file (GitHub CLI not available)"
fi

echo ""

##############################################################################
# SUMMARY
##############################################################################
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  DIAGNOSTIC SUMMARY                                            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ "$ALL_CHECKS_PASSED" = true ]; then
    echo -e "${GREEN}✅ ALL CHECKS PASSED!${NC}"
    echo ""
    echo -e "${GREEN}Your setup is complete and ready for deployment!${NC}"
    echo ""
    echo -e "Next steps:"
    echo -e "  1. Go to: https://github.com/${GITHUB_OWNER}/${GITHUB_REPO}/actions"
    echo -e "  2. Click: 'Deploy to DEV' workflow"
    echo -e "  3. Click: 'Run workflow' button"
    echo -e "  4. Select component and trigger deployment"
else
    echo -e "${YELLOW}⚠ SOME CHECKS FAILED${NC}"
    echo ""
    echo -e "Please review the errors above and complete the missing setup steps."
    echo -e "Refer to: ${BLUE}human-steps.md${NC} for detailed instructions."
fi

echo ""
