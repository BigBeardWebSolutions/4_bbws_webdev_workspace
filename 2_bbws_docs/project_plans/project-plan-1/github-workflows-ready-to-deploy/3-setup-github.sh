#!/bin/bash

##############################################################################
# Script 3: Setup GitHub Repository for Deployment
#
# This script:
# - Creates GitHub secret AWS_ROLE_DEV
# - Creates GitHub environment 'dev' (optional)
# - Copies workflow files to repository
# - Commits and pushes changes
#
# Usage: ./3-setup-github.sh <github-owner> <github-repo>
# Example: ./3-setup-github.sh tsekatm 2_1_bbws_dynamodb_schemas
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
IAM_ROLE_NAME="bbws-terraform-deployer-dev"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Step 3: Setup GitHub Repository                              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check arguments
if [ $# -ne 2 ]; then
    echo -e "${RED}❌ Error: Missing arguments${NC}"
    echo "Usage: $0 <github-owner> <github-repo>"
    echo "Example: $0 tsekatm 2_1_bbws_dynamodb_schemas"
    exit 1
fi

GITHUB_OWNER=$1
GITHUB_REPO=$2

echo -e "Configuration:"
echo -e "  GitHub Owner: ${BLUE}${GITHUB_OWNER}${NC}"
echo -e "  GitHub Repo:  ${BLUE}${GITHUB_REPO}${NC}"
echo ""

# Check if GitHub CLI is authenticated
if ! gh auth status &> /dev/null; then
    echo -e "${RED}✗ GitHub CLI is not authenticated${NC}"
    echo -e "${YELLOW}→ Run: gh auth login${NC}"
    exit 1
fi

echo -e "${GREEN}✓ GitHub CLI is authenticated${NC}"
echo ""

# Get IAM role ARN
if ! aws iam get-role --role-name $IAM_ROLE_NAME --profile $AWS_PROFILE &> /dev/null; then
    echo -e "${RED}✗ IAM role '${IAM_ROLE_NAME}' does not exist${NC}"
    echo -e "${YELLOW}→ Run: ./2-setup-aws-infrastructure.sh ${GITHUB_OWNER} first${NC}"
    exit 1
fi

ROLE_ARN=$(aws iam get-role --role-name $IAM_ROLE_NAME --profile $AWS_PROFILE --query 'Role.Arn' --output text)

echo -e "${GREEN}✓ IAM role found:${NC} ${ROLE_ARN}"
echo ""

##############################################################################
# Step 3.1: Create GitHub Secret
##############################################################################
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}[3.1/3] Creating GitHub Secret${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check if secret already exists
EXISTING_SECRETS=$(gh secret list --repo $GITHUB_OWNER/$GITHUB_REPO 2>/dev/null || echo "")

if echo "$EXISTING_SECRETS" | grep -q "AWS_ROLE_DEV"; then
    echo -e "${YELLOW}⚠ GitHub secret 'AWS_ROLE_DEV' already exists${NC}"
    read -p "Do you want to update it? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}✓ Keeping existing secret${NC}"
    else
        echo -e "${YELLOW}Updating secret...${NC}"
        echo "$ROLE_ARN" | gh secret set AWS_ROLE_DEV --repo $GITHUB_OWNER/$GITHUB_REPO
        echo -e "${GREEN}✓ Secret updated${NC}"
    fi
else
    echo -e "${YELLOW}Creating secret 'AWS_ROLE_DEV'...${NC}"
    echo "$ROLE_ARN" | gh secret set AWS_ROLE_DEV --repo $GITHUB_OWNER/$GITHUB_REPO
    echo -e "${GREEN}✓ Secret created${NC}"
fi

echo -e "  Secret value: ${ROLE_ARN}"
echo ""

##############################################################################
# Step 3.2: Create GitHub Environment (Optional)
##############################################################################
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}[3.2/3] Creating GitHub Environment (Optional)${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${YELLOW}GitHub environments provide deployment protection rules.${NC}"
echo -e "${YELLOW}For DEV, this is optional (no approvers needed).${NC}"
echo ""

read -p "Do you want to create 'dev' environment? (y/n): " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Check if environment exists
    EXISTING_ENVS=$(gh api repos/$GITHUB_OWNER/$GITHUB_REPO/environments --jq '.environments[].name' 2>/dev/null || echo "")

    if echo "$EXISTING_ENVS" | grep -q "^dev$"; then
        echo -e "${GREEN}✓ Environment 'dev' already exists${NC}"
    else
        echo -e "${YELLOW}Creating environment 'dev'...${NC}"

        # Create environment (no protection rules for DEV)
        gh api -X PUT repos/$GITHUB_OWNER/$GITHUB_REPO/environments/dev

        echo -e "${GREEN}✓ Environment 'dev' created${NC}"
    fi
else
    echo -e "${YELLOW}⊘ Skipping environment creation${NC}"
fi

echo ""

##############################################################################
# Step 3.3: Copy Workflow Files to Repository
##############################################################################
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}[3.3/3] Copy Workflow Files to Repository${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Ask for repository path
echo -e "${YELLOW}Where is your repository located?${NC}"
echo -e "Examples:"
echo -e "  /Users/tebogotseka/Documents/repos/2_1_bbws_dynamodb_schemas"
echo -e "  ~/projects/2_1_bbws_dynamodb_schemas"
echo ""

read -p "Repository path: " REPO_PATH

# Expand ~ to home directory
REPO_PATH="${REPO_PATH/#\~/$HOME}"

# Verify repository exists
if [ ! -d "$REPO_PATH" ]; then
    echo -e "${RED}✗ Repository path does not exist: ${REPO_PATH}${NC}"
    exit 1
fi

if [ ! -d "$REPO_PATH/.git" ]; then
    echo -e "${RED}✗ Not a git repository: ${REPO_PATH}${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Repository found${NC}"
echo ""

# Determine component type
echo -e "${YELLOW}Which component is this repository for?${NC}"
echo -e "  1) DynamoDB"
echo -e "  2) S3"
echo -e "  3) Both"
echo ""

read -p "Select (1/2/3): " -n 1 -r COMPONENT_CHOICE
echo
echo ""

case $COMPONENT_CHOICE in
    1)
        COMPONENT_TYPE="dynamodb"
        VALIDATION_SCRIPT="validate_dynamodb_dev.py"
        ;;
    2)
        COMPONENT_TYPE="s3"
        VALIDATION_SCRIPT="validate_s3_dev.py"
        ;;
    3)
        COMPONENT_TYPE="both"
        VALIDATION_SCRIPT="validate_*.py"
        ;;
    *)
        echo -e "${RED}✗ Invalid choice${NC}"
        exit 1
        ;;
esac

echo -e "${YELLOW}Component type: ${COMPONENT_TYPE}${NC}"
echo ""

# Copy workflow file
WORKFLOW_DIR="$REPO_PATH/.github/workflows"
mkdir -p "$WORKFLOW_DIR"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo -e "${YELLOW}Copying workflow file...${NC}"
cp "$SCRIPT_DIR/.github/workflows/deploy-dev.yml" "$WORKFLOW_DIR/"
echo -e "${GREEN}✓ Copied deploy-dev.yml${NC}"

# Copy validation scripts
SCRIPTS_DIR="$REPO_PATH/scripts"
mkdir -p "$SCRIPTS_DIR"

echo -e "${YELLOW}Copying validation scripts...${NC}"

if [ "$COMPONENT_TYPE" == "dynamodb" ] || [ "$COMPONENT_TYPE" == "both" ]; then
    cp "$SCRIPT_DIR/scripts/validate_dynamodb_dev.py" "$SCRIPTS_DIR/"
    echo -e "${GREEN}✓ Copied validate_dynamodb_dev.py${NC}"
fi

if [ "$COMPONENT_TYPE" == "s3" ] || [ "$COMPONENT_TYPE" == "both" ]; then
    cp "$SCRIPT_DIR/scripts/validate_s3_dev.py" "$SCRIPTS_DIR/"
    echo -e "${GREEN}✓ Copied validate_s3_dev.py${NC}"
fi

echo ""

# Git commit and push
echo -e "${YELLOW}Do you want to commit and push these changes now?${NC}"
read -p "(y/n): " -n 1 -r
echo
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    cd "$REPO_PATH"

    echo -e "${YELLOW}Staging changes...${NC}"
    git add .github/ scripts/

    echo -e "${YELLOW}Creating commit...${NC}"
    git commit -m "Add DEV deployment pipeline with GitHub Actions

- Add deploy-dev.yml workflow for automated deployment
- Add validation scripts for post-deployment checks
- Configure AWS OIDC authentication
- Support ${COMPONENT_TYPE} deployment"

    echo -e "${YELLOW}Pushing to GitHub...${NC}"
    git push origin main || git push origin master

    echo -e "${GREEN}✓ Changes committed and pushed${NC}"
else
    echo -e "${YELLOW}⊘ Skipping commit/push${NC}"
    echo -e "${YELLOW}  → You can manually commit later:${NC}"
    echo -e "${YELLOW}     cd ${REPO_PATH}${NC}"
    echo -e "${YELLOW}     git add .github/ scripts/${NC}"
    echo -e "${YELLOW}     git commit -m 'Add DEV deployment pipeline'${NC}"
    echo -e "${YELLOW}     git push origin main${NC}"
fi

echo ""

##############################################################################
# Summary
##############################################################################
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅ Step 3 Complete!                                           ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}GitHub Setup Summary:${NC}"
echo ""
echo -e "${GREEN}✓${NC} Secret 'AWS_ROLE_DEV' configured"
echo -e "${GREEN}✓${NC} Workflow file copied to repository"
echo -e "${GREEN}✓${NC} Validation scripts copied"
echo -e "${GREEN}✓${NC} Component type: ${COMPONENT_TYPE}"
echo ""
echo -e "${YELLOW}Next step: Run ./4-trigger-deployment.sh${NC}"
echo ""
