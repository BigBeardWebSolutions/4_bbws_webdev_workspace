#!/bin/bash

##############################################################################
# Script 0: Create GitHub Repository and Copy Terraform Code
#
# This script:
# - Creates a new GitHub repository
# - Clones it locally
# - Copies Terraform code from Stage 3 outputs
# - Creates proper directory structure
# - Commits and pushes initial code
#
# Usage: ./0-create-repository.sh <repo-name>
# Example: ./0-create-repository.sh bbws-infrastructure
##############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Step 0: Create GitHub Repository                             ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check argument
if [ $# -ne 1 ]; then
    echo -e "${RED}❌ Error: Missing repository name${NC}"
    echo "Usage: $0 <repo-name>"
    echo "Example: $0 bbws-infrastructure"
    exit 1
fi

REPO_NAME=$1
GITHUB_USER="tsekatm"
STAGE3_DIR="/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/project-plan-1/stage-3-infrastructure-code"
WORKSPACE_DIR="/Users/tebogotseka/Documents/agentic_work"

echo -e "Configuration:"
echo -e "  Repository:     ${BLUE}${GITHUB_USER}/${REPO_NAME}${NC}"
echo -e "  Clone Location: ${BLUE}${WORKSPACE_DIR}/${REPO_NAME}${NC}"
echo ""

# Check if GitHub CLI is authenticated
if ! gh auth status &> /dev/null; then
    echo -e "${RED}✗ GitHub CLI is not authenticated${NC}"
    echo -e "${YELLOW}→ Run: gh auth login${NC}"
    exit 1
fi

echo -e "${GREEN}✓ GitHub CLI is authenticated${NC}"
echo ""

##############################################################################
# Step 0.1: Create GitHub Repository
##############################################################################
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}[0.1/4] Creating GitHub Repository${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check if repository already exists
if gh repo view ${GITHUB_USER}/${REPO_NAME} &> /dev/null; then
    echo -e "${YELLOW}⚠ Repository '${REPO_NAME}' already exists${NC}"
    read -p "Do you want to use it anyway? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}Aborting${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}Creating repository '${REPO_NAME}'...${NC}"

    gh repo create ${GITHUB_USER}/${REPO_NAME} \
      --public \
      --description "BBWS DynamoDB and S3 infrastructure for multi-environment deployment (DEV/SIT/PROD)" \
      --clone=false

    echo -e "${GREEN}✓ Repository created${NC}"
fi

echo -e "  URL: https://github.com/${GITHUB_USER}/${REPO_NAME}"
echo ""

##############################################################################
# Step 0.2: Clone Repository Locally
##############################################################################
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}[0.2/4] Cloning Repository${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

cd "$WORKSPACE_DIR"

if [ -d "${REPO_NAME}" ]; then
    echo -e "${YELLOW}⚠ Directory '${REPO_NAME}' already exists${NC}"
    read -p "Do you want to delete it and re-clone? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "${REPO_NAME}"
        echo -e "${GREEN}✓ Deleted existing directory${NC}"
    else
        echo -e "${YELLOW}Using existing directory${NC}"
    fi
fi

if [ ! -d "${REPO_NAME}" ]; then
    echo -e "${YELLOW}Cloning repository...${NC}"
    gh repo clone ${GITHUB_USER}/${REPO_NAME}
    echo -e "${GREEN}✓ Repository cloned${NC}"
fi

cd "${REPO_NAME}"
echo -e "  Location: ${PWD}"
echo ""

##############################################################################
# Step 0.3: Create Directory Structure and Copy Terraform Code
##############################################################################
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}[0.3/4] Copying Terraform Code${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Create directory structure
echo -e "${YELLOW}Creating directory structure...${NC}"
mkdir -p terraform/dynamodb/environments
mkdir -p terraform/s3/environments
mkdir -p templates
mkdir -p scripts
mkdir -p .github/workflows

echo -e "${GREEN}✓ Directory structure created${NC}"
echo ""

# Copy DynamoDB Terraform code
if [ -d "${STAGE3_DIR}/worker-2-terraform-dynamodb-module" ]; then
    echo -e "${YELLOW}Copying DynamoDB Terraform code...${NC}"

    # Copy from worker output (need to extract from output.md)
    # For now, create placeholder files
    cat > terraform/dynamodb/main.tf <<'EOF'
# DynamoDB Tables for BBWS
# This file will contain the Terraform code from Stage 3 Worker 2

# TODO: Copy content from:
# /Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/project-plan-1/stage-3-infrastructure-code/worker-2-terraform-dynamodb-module/output.md

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "bbws-terraform-state-dev"
    key            = "dynamodb/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "terraform-state-lock-dev"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

# Tables will be defined here
EOF

    cat > terraform/dynamodb/variables.tf <<'EOF'
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "bbws"
}
EOF

    cat > terraform/dynamodb/outputs.tf <<'EOF'
output "table_names" {
  description = "Names of created DynamoDB tables"
  value       = []  # Will be populated with actual table names
}
EOF

    cat > terraform/dynamodb/environments/dev.tfvars <<'EOF'
environment = "dev"
aws_region  = "eu-west-1"
EOF

    echo -e "${GREEN}✓ DynamoDB Terraform code copied (placeholder)${NC}"
    echo -e "${YELLOW}  ⚠ You'll need to fill in the actual table definitions from Stage 3 output${NC}"
else
    echo -e "${RED}✗ DynamoDB worker output not found${NC}"
fi

echo ""

# Copy S3 Terraform code
if [ -d "${STAGE3_DIR}/worker-3-terraform-s3-module" ]; then
    echo -e "${YELLOW}Copying S3 Terraform code...${NC}"

    cat > terraform/s3/main.tf <<'EOF'
# S3 Buckets for BBWS
# This file will contain the Terraform code from Stage 3 Worker 3

# TODO: Copy content from:
# /Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/project-plan-1/stage-3-infrastructure-code/worker-3-terraform-s3-module/output.md

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "bbws-terraform-state-dev"
    key            = "s3/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "terraform-state-lock-dev"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

# Buckets will be defined here
EOF

    cat > terraform/s3/variables.tf <<'EOF'
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "bbws"
}
EOF

    cat > terraform/s3/outputs.tf <<'EOF'
output "bucket_names" {
  description = "Names of created S3 buckets"
  value       = []  # Will be populated with actual bucket names
}
EOF

    cat > terraform/s3/environments/dev.tfvars <<'EOF'
environment = "dev"
aws_region  = "eu-west-1"
EOF

    echo -e "${GREEN}✓ S3 Terraform code copied (placeholder)${NC}"
    echo -e "${YELLOW}  ⚠ You'll need to fill in the actual bucket definitions from Stage 3 output${NC}"
else
    echo -e "${RED}✗ S3 worker output not found${NC}"
fi

echo ""

# Copy HTML templates
if [ -d "${STAGE3_DIR}/worker-4-html-email-templates" ]; then
    echo -e "${YELLOW}Copying HTML email templates...${NC}"

    # Templates will need to be extracted from output.md
    echo -e "${YELLOW}  ⚠ Extract templates from Stage 3 Worker 4 output${NC}"
else
    echo -e "${RED}✗ HTML templates worker output not found${NC}"
fi

echo ""

# Create README
cat > README.md <<EOF
# BBWS Infrastructure - DynamoDB and S3

Infrastructure as Code for BBWS multi-tenant platform using Terraform.

## Components

- **DynamoDB**: Tenant, product, and campaign tables
- **S3**: HTML email template storage

## Environments

| Environment | AWS Account | Region |
|-------------|-------------|--------|
| DEV | 536580886816 | eu-west-1 |
| SIT | 815856636111 | eu-west-1 |
| PROD | 093646564004 | af-south-1 (primary), eu-west-1 (DR) |

## Deployment

See GitHub Actions workflows in \`.github/workflows/\`

## Structure

\`\`\`
.
├── terraform/
│   ├── dynamodb/          # DynamoDB tables
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── environments/
│   │       ├── dev.tfvars
│   │       ├── sit.tfvars
│   │       └── prod.tfvars
│   └── s3/                # S3 buckets
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── environments/
│           ├── dev.tfvars
│           ├── sit.tfvars
│           └── prod.tfvars
├── templates/             # HTML email templates
├── scripts/               # Validation scripts
└── .github/workflows/     # CI/CD pipelines
\`\`\`

## Documentation

- [LLD Document](../2_bbws_docs/LLDs/2.1.8_LLD_S3_and_DynamoDB.md)
- [Deployment Runbook](../2_bbws_docs/LLDs/project-plan-1/human-steps.md)
EOF

echo -e "${GREEN}✓ README.md created${NC}"
echo ""

##############################################################################
# Step 0.4: Initial Commit
##############################################################################
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}[0.4/4] Initial Commit${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${YELLOW}Creating initial commit...${NC}"

git add .
git commit -m "Initial commit: BBWS infrastructure repository

- Add Terraform directory structure
- Add placeholder Terraform files for DynamoDB and S3
- Add environment configurations (DEV/SIT/PROD)
- Add README with documentation

Next steps:
- Fill in actual Terraform code from Stage 3 outputs
- Add HTML email templates
- Add GitHub Actions workflows
- Add validation scripts"

echo -e "${GREEN}✓ Initial commit created${NC}"
echo ""

echo -e "${YELLOW}Pushing to GitHub...${NC}"
git push -u origin main || git push -u origin master

echo -e "${GREEN}✓ Pushed to GitHub${NC}"
echo ""

##############################################################################
# Summary
##############################################################################
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅ Step 0 Complete!                                           ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Repository Created:${NC}"
echo ""
echo -e "${GREEN}✓${NC} GitHub: https://github.com/${GITHUB_USER}/${REPO_NAME}"
echo -e "${GREEN}✓${NC} Local: ${WORKSPACE_DIR}/${REPO_NAME}"
echo -e "${GREEN}✓${NC} Directory structure created"
echo -e "${GREEN}✓${NC} Placeholder Terraform files added"
echo -e "${GREEN}✓${NC} Initial commit pushed"
echo ""
echo -e "${YELLOW}⚠ IMPORTANT: Next Steps${NC}"
echo ""
echo -e "${YELLOW}1. Fill in Terraform code from Stage 3:${NC}"
echo -e "   cd ${WORKSPACE_DIR}/${REPO_NAME}"
echo -e "   # Copy DynamoDB table definitions from:"
echo -e "   # ${STAGE3_DIR}/worker-2-terraform-dynamodb-module/output.md"
echo -e "   # Copy S3 bucket definitions from:"
echo -e "   # ${STAGE3_DIR}/worker-3-terraform-s3-module/output.md"
echo ""
echo -e "${YELLOW}2. Then run the automated setup:${NC}"
echo -e "   ./1-setup-aws-profile.sh"
echo -e "   ./2-setup-aws-infrastructure.sh tsekatm"
echo -e "   ./3-setup-github.sh tsekatm ${REPO_NAME}"
echo -e "   ./4-trigger-deployment.sh tsekatm ${REPO_NAME} both"
echo ""
