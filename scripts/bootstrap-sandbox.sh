#!/bin/bash
#===============================================================================
# BBWS Web Development Team - Sandbox Environment Bootstrap Script
#
# This script creates the foundational AWS resources required for the sandbox
# environment before Terraform can be run.
#
# Prerequisites:
#   - AWS CLI v2 installed
#   - AWS SSO profile 'sandbox' configured with AWSAdministratorAccess
#   - Logged in: aws sso login --profile sandbox
#
# Usage:
#   ./bootstrap-sandbox.sh
#
# AWS Account: 417589271098
# Region: eu-west-1
#===============================================================================

set -e

# Configuration
AWS_PROFILE="sandbox"
AWS_REGION="eu-west-1"
AWS_ACCOUNT_ID="417589271098"

# Resource names
TERRAFORM_STATE_BUCKET="bbws-terraform-state-sandbox"
TERRAFORM_LOCK_TABLE="bbws-terraform-locks-sandbox"
MIGRATED_SITES_BUCKET="bigbeard-migrated-site-sandbox"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

echo_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

#-------------------------------------------------------------------------------
# Pre-flight checks
#-------------------------------------------------------------------------------
echo "=============================================="
echo "BBWS Sandbox Environment Bootstrap"
echo "=============================================="
echo ""

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    echo_error "AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check AWS profile and credentials
echo_info "Verifying AWS credentials..."
CALLER_IDENTITY=$(aws sts get-caller-identity --profile "$AWS_PROFILE" 2>&1) || {
    echo_error "Failed to verify AWS credentials. Please run: aws sso login --profile $AWS_PROFILE"
    exit 1
}

CURRENT_ACCOUNT=$(echo "$CALLER_IDENTITY" | grep -o '"Account": "[^"]*"' | cut -d'"' -f4)
if [ "$CURRENT_ACCOUNT" != "$AWS_ACCOUNT_ID" ]; then
    echo_error "Wrong AWS account. Expected: $AWS_ACCOUNT_ID, Got: $CURRENT_ACCOUNT"
    exit 1
fi

echo_info "Authenticated to account: $CURRENT_ACCOUNT"
echo ""

#-------------------------------------------------------------------------------
# Create Terraform State S3 Bucket
#-------------------------------------------------------------------------------
echo_info "Creating Terraform state bucket: $TERRAFORM_STATE_BUCKET"

if aws s3api head-bucket --bucket "$TERRAFORM_STATE_BUCKET" --profile "$AWS_PROFILE" 2>/dev/null; then
    echo_warn "Bucket $TERRAFORM_STATE_BUCKET already exists, skipping..."
else
    aws s3api create-bucket \
        --bucket "$TERRAFORM_STATE_BUCKET" \
        --region "$AWS_REGION" \
        --create-bucket-configuration LocationConstraint="$AWS_REGION" \
        --profile "$AWS_PROFILE"

    # Enable versioning
    aws s3api put-bucket-versioning \
        --bucket "$TERRAFORM_STATE_BUCKET" \
        --versioning-configuration Status=Enabled \
        --profile "$AWS_PROFILE"

    # Enable encryption
    aws s3api put-bucket-encryption \
        --bucket "$TERRAFORM_STATE_BUCKET" \
        --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}' \
        --profile "$AWS_PROFILE"

    # Block public access
    aws s3api put-public-access-block \
        --bucket "$TERRAFORM_STATE_BUCKET" \
        --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" \
        --profile "$AWS_PROFILE"

    echo_info "Bucket $TERRAFORM_STATE_BUCKET created successfully"
fi

#-------------------------------------------------------------------------------
# Create Terraform Lock DynamoDB Table
#-------------------------------------------------------------------------------
echo_info "Creating Terraform lock table: $TERRAFORM_LOCK_TABLE"

if aws dynamodb describe-table --table-name "$TERRAFORM_LOCK_TABLE" --region "$AWS_REGION" --profile "$AWS_PROFILE" 2>/dev/null; then
    echo_warn "Table $TERRAFORM_LOCK_TABLE already exists, skipping..."
else
    aws dynamodb create-table \
        --table-name "$TERRAFORM_LOCK_TABLE" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region "$AWS_REGION" \
        --profile "$AWS_PROFILE"

    # Wait for table to be active
    echo_info "Waiting for DynamoDB table to be active..."
    aws dynamodb wait table-exists \
        --table-name "$TERRAFORM_LOCK_TABLE" \
        --region "$AWS_REGION" \
        --profile "$AWS_PROFILE"

    echo_info "Table $TERRAFORM_LOCK_TABLE created successfully"
fi

#-------------------------------------------------------------------------------
# Create Migrated Sites S3 Bucket
#-------------------------------------------------------------------------------
echo_info "Creating migrated sites bucket: $MIGRATED_SITES_BUCKET"

if aws s3api head-bucket --bucket "$MIGRATED_SITES_BUCKET" --profile "$AWS_PROFILE" 2>/dev/null; then
    echo_warn "Bucket $MIGRATED_SITES_BUCKET already exists, skipping..."
else
    aws s3api create-bucket \
        --bucket "$MIGRATED_SITES_BUCKET" \
        --region "$AWS_REGION" \
        --create-bucket-configuration LocationConstraint="$AWS_REGION" \
        --profile "$AWS_PROFILE"

    # Enable versioning
    aws s3api put-bucket-versioning \
        --bucket "$MIGRATED_SITES_BUCKET" \
        --versioning-configuration Status=Enabled \
        --profile "$AWS_PROFILE"

    # Enable encryption
    aws s3api put-bucket-encryption \
        --bucket "$MIGRATED_SITES_BUCKET" \
        --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}' \
        --profile "$AWS_PROFILE"

    # Block public access (CloudFront OAC will be used)
    aws s3api put-public-access-block \
        --bucket "$MIGRATED_SITES_BUCKET" \
        --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" \
        --profile "$AWS_PROFILE"

    echo_info "Bucket $MIGRATED_SITES_BUCKET created successfully"
fi

#-------------------------------------------------------------------------------
# Summary
#-------------------------------------------------------------------------------
echo ""
echo "=============================================="
echo "Bootstrap Complete!"
echo "=============================================="
echo ""
echo "Resources created:"
echo "  - S3 Bucket: $TERRAFORM_STATE_BUCKET (Terraform state)"
echo "  - S3 Bucket: $MIGRATED_SITES_BUCKET (Migrated websites)"
echo "  - DynamoDB:  $TERRAFORM_LOCK_TABLE (Terraform locks)"
echo ""
echo "Next steps:"
echo "  1. Navigate to 2_bbws_ecs_terraform/terraform"
echo "  2. Run: terraform init -backend-config=\"../../4_bbws_webdev_workspace/terraform/environments/sandbox/backend-sandbox.hcl\" -backend-config=\"key=infrastructure/terraform.tfstate\""
echo "  3. Run: terraform plan -var-file=\"../../4_bbws_webdev_workspace/terraform/environments/sandbox/sandbox.tfvars\""
echo "  4. Run: terraform apply -var-file=\"../../4_bbws_webdev_workspace/terraform/environments/sandbox/sandbox.tfvars\""
echo ""
