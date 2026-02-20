#!/bin/bash

##############################################################################
# Script 4: Trigger Deployment and Monitor Progress
#
# This script:
# - Triggers the GitHub Actions deployment workflow
# - Monitors deployment progress
# - Displays results
#
# Usage: ./4-trigger-deployment.sh <github-owner> <github-repo> <component>
# Example: ./4-trigger-deployment.sh tsekatm 2_1_bbws_dynamodb_schemas dynamodb
##############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Step 4: Trigger Deployment                                   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check arguments
if [ $# -lt 2 ]; then
    echo -e "${RED}❌ Error: Missing arguments${NC}"
    echo "Usage: $0 <github-owner> <github-repo> [component]"
    echo "Example: $0 tsekatm 2_1_bbws_dynamodb_schemas dynamodb"
    echo ""
    echo "Component options: dynamodb, s3, both"
    exit 1
fi

GITHUB_OWNER=$1
GITHUB_REPO=$2
COMPONENT=${3:-}

# Check if GitHub CLI is authenticated
if ! gh auth status &> /dev/null; then
    echo -e "${RED}✗ GitHub CLI is not authenticated${NC}"
    echo -e "${YELLOW}→ Run: gh auth login${NC}"
    exit 1
fi

echo -e "${GREEN}✓ GitHub CLI is authenticated${NC}"
echo ""

# If component not provided, ask user
if [ -z "$COMPONENT" ]; then
    echo -e "${YELLOW}Which component do you want to deploy?${NC}"
    echo -e "  1) DynamoDB only"
    echo -e "  2) S3 only"
    echo -e "  3) Both"
    echo ""

    read -p "Select (1/2/3): " -n 1 -r COMPONENT_CHOICE
    echo
    echo ""

    case $COMPONENT_CHOICE in
        1) COMPONENT="dynamodb" ;;
        2) COMPONENT="s3" ;;
        3) COMPONENT="both" ;;
        *)
            echo -e "${RED}✗ Invalid choice${NC}"
            exit 1
            ;;
    esac
fi

echo -e "Configuration:"
echo -e "  GitHub Owner: ${BLUE}${GITHUB_OWNER}${NC}"
echo -e "  GitHub Repo:  ${BLUE}${GITHUB_REPO}${NC}"
echo -e "  Component:    ${BLUE}${COMPONENT}${NC}"
echo ""

# Verify workflow exists
echo -e "${YELLOW}Checking if workflow exists...${NC}"

WORKFLOWS=$(gh workflow list --repo $GITHUB_OWNER/$GITHUB_REPO 2>/dev/null || echo "")

if [ -z "$WORKFLOWS" ]; then
    echo -e "${RED}✗ No workflows found in repository${NC}"
    echo -e "${YELLOW}→ Make sure you ran ./3-setup-github.sh and pushed the workflow file${NC}"
    exit 1
fi

if ! echo "$WORKFLOWS" | grep -q "Deploy to DEV"; then
    echo -e "${RED}✗ 'Deploy to DEV' workflow not found${NC}"
    echo -e "${YELLOW}→ Make sure deploy-dev.yml is pushed to the repository${NC}"
    echo ""
    echo -e "${YELLOW}Available workflows:${NC}"
    echo "$WORKFLOWS"
    exit 1
fi

echo -e "${GREEN}✓ Workflow 'Deploy to DEV' found${NC}"
echo ""

##############################################################################
# Trigger Deployment
##############################################################################
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Triggering Deployment${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${YELLOW}Triggering workflow...${NC}"

# Trigger the workflow
gh workflow run deploy-dev.yml \
  --repo $GITHUB_OWNER/$GITHUB_REPO \
  -f component=$COMPONENT \
  -f skip_validation=false

echo -e "${GREEN}✓ Workflow triggered${NC}"
echo ""

# Wait a moment for the workflow to appear
echo -e "${YELLOW}Waiting for workflow to start...${NC}"
sleep 5

# Get the latest run
RUN_ID=$(gh run list \
  --repo $GITHUB_OWNER/$GITHUB_REPO \
  --workflow=deploy-dev.yml \
  --limit 1 \
  --json databaseId \
  --jq '.[0].databaseId')

if [ -z "$RUN_ID" ]; then
    echo -e "${RED}✗ Could not find workflow run${NC}"
    echo -e "${YELLOW}→ Check manually: https://github.com/${GITHUB_OWNER}/${GITHUB_REPO}/actions${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Workflow started${NC}"
echo -e "  Run ID: ${RUN_ID}"
echo -e "  URL: https://github.com/${GITHUB_OWNER}/${GITHUB_REPO}/actions/runs/${RUN_ID}"
echo ""

##############################################################################
# Monitor Deployment
##############################################################################
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Monitoring Deployment${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${YELLOW}Watching workflow progress...${NC}"
echo -e "${YELLOW}(This may take 4-6 minutes)${NC}"
echo ""

# Watch the workflow
gh run watch $RUN_ID --repo $GITHUB_OWNER/$GITHUB_REPO --exit-status || WORKFLOW_FAILED=true

echo ""

##############################################################################
# Display Results
##############################################################################
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Deployment Results${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Get run status
RUN_STATUS=$(gh run view $RUN_ID --repo $GITHUB_OWNER/$GITHUB_REPO --json status,conclusion --jq '{status: .status, conclusion: .conclusion}')

STATUS=$(echo "$RUN_STATUS" | jq -r '.status')
CONCLUSION=$(echo "$RUN_STATUS" | jq -r '.conclusion')

echo -e "Workflow Status: ${YELLOW}${STATUS}${NC}"
echo -e "Conclusion: ${YELLOW}${CONCLUSION}${NC}"
echo ""

if [ "$CONCLUSION" == "success" ]; then
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ✅ DEPLOYMENT SUCCESSFUL!                                     ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    echo -e "${GREEN}Next Steps:${NC}"
    echo ""

    if [ "$COMPONENT" == "dynamodb" ] || [ "$COMPONENT" == "both" ]; then
        echo -e "${YELLOW}1. Verify DynamoDB tables in AWS Console:${NC}"
        echo -e "   https://console.aws.amazon.com/dynamodbv2/home?region=eu-west-1#tables"
        echo ""
        echo -e "${YELLOW}2. Test DynamoDB access:${NC}"
        echo -e "   aws dynamodb list-tables --region eu-west-1 --profile dev"
        echo ""
    fi

    if [ "$COMPONENT" == "s3" ] || [ "$COMPONENT" == "both" ]; then
        echo -e "${YELLOW}3. Verify S3 bucket in AWS Console:${NC}"
        echo -e "   https://console.aws.amazon.com/s3/home?region=eu-west-1"
        echo ""
        echo -e "${YELLOW}4. Upload HTML templates (if needed):${NC}"
        echo -e "   aws s3 sync ./templates/ s3://bbws-templates-dev/templates/ --region eu-west-1 --profile dev"
        echo ""
    fi

    echo -e "${YELLOW}5. View workflow logs:${NC}"
    echo -e "   gh run view $RUN_ID --repo $GITHUB_OWNER/$GITHUB_REPO --log"
    echo ""

elif [ "$CONCLUSION" == "failure" ]; then
    echo -e "${RED}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  ❌ DEPLOYMENT FAILED                                          ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    echo -e "${YELLOW}Troubleshooting Steps:${NC}"
    echo ""

    echo -e "${YELLOW}1. View detailed logs:${NC}"
    echo -e "   gh run view $RUN_ID --repo $GITHUB_OWNER/$GITHUB_REPO --log"
    echo ""

    echo -e "${YELLOW}2. Common issues:${NC}"
    echo -e "   - AWS credentials: Verify AWS_ROLE_DEV secret is correct"
    echo -e "   - IAM permissions: Check role has DynamoDB/S3 permissions"
    echo -e "   - Terraform state: Verify state bucket exists in eu-west-1"
    echo -e "   - Region: Ensure region is set to eu-west-1"
    echo ""

    echo -e "${YELLOW}3. Re-run diagnostic:${NC}"
    echo -e "   ./check-setup.sh $GITHUB_OWNER $GITHUB_REPO"
    echo ""

    exit 1
else
    echo -e "${YELLOW}⚠ Workflow is ${STATUS} with conclusion: ${CONCLUSION}${NC}"
    echo ""
    echo -e "View workflow: https://github.com/${GITHUB_OWNER}/${GITHUB_REPO}/actions/runs/${RUN_ID}"
fi

echo ""
