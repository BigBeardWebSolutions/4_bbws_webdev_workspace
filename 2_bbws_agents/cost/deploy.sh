#!/bin/bash

###############################################################################
# BBWS Automated Cost Reporting - Deployment Script
#
# Usage:
#   ./deploy.sh <environment> <email1,email2,email3>
#
# Examples:
#   ./deploy.sh dev "admin@example.com,finance@example.com"
#   ./deploy.sh sit "team@example.com"
#   ./deploy.sh prod "ceo@example.com,cfo@example.com,devops@example.com"
###############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Validate arguments
if [ "$#" -lt 2 ]; then
    log_error "Usage: $0 <environment> <email1,email2,email3>"
    log_info "Example: $0 dev \"admin@example.com,finance@example.com\""
    exit 1
fi

ENVIRONMENT=$1
EMAILS=$2

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|sit|prod)$ ]]; then
    log_error "Invalid environment: $ENVIRONMENT"
    log_info "Must be one of: dev, sit, prod"
    exit 1
fi

# Determine AWS profile and region
case $ENVIRONMENT in
    dev)
        AWS_PROFILE="Tebogo-dev"
        AWS_ACCOUNT="536580886816"
        AWS_REGION="eu-west-1"
        ;;
    sit)
        AWS_PROFILE="Tebogo-sit"
        AWS_ACCOUNT="815856636111"
        AWS_REGION="eu-west-1"
        ;;
    prod)
        AWS_PROFILE="Tebogo-prod"
        AWS_ACCOUNT="093646564004"
        AWS_REGION="af-south-1"
        ;;
esac

log_info "Starting deployment for environment: $ENVIRONMENT"
log_info "AWS Profile: $AWS_PROFILE"
log_info "AWS Account: $AWS_ACCOUNT"
log_info "AWS Region: $AWS_REGION"

# Check prerequisites
log_info "Checking prerequisites..."

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    log_error "AWS CLI not found. Please install it first."
    exit 1
fi
log_success "AWS CLI found"

# Check Terraform
if ! command -v terraform &> /dev/null; then
    log_error "Terraform not found. Please install it first."
    exit 1
fi
log_success "Terraform found"

# Check Python
if ! command -v python3 &> /dev/null; then
    log_error "Python 3 not found. Please install it first."
    exit 1
fi
log_success "Python 3 found"

# Verify AWS authentication
log_info "Verifying AWS authentication..."
export AWS_PROFILE=$AWS_PROFILE
if ! aws sts get-caller-identity &> /dev/null; then
    log_error "AWS authentication failed. Please configure AWS CLI."
    exit 1
fi

CURRENT_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
if [ "$CURRENT_ACCOUNT" != "$AWS_ACCOUNT" ]; then
    log_error "Wrong AWS account! Expected: $AWS_ACCOUNT, Got: $CURRENT_ACCOUNT"
    exit 1
fi
log_success "Authenticated to AWS account: $CURRENT_ACCOUNT"

# Navigate to terraform directory
cd "$(dirname "$0")/terraform"

# Convert comma-separated emails to Terraform list format
IFS=',' read -ra EMAIL_ARRAY <<< "$EMAILS"
TERRAFORM_EMAILS="["
for email in "${EMAIL_ARRAY[@]}"; do
    email=$(echo "$email" | xargs)  # Trim whitespace
    TERRAFORM_EMAILS+="\"$email\","
done
TERRAFORM_EMAILS="${TERRAFORM_EMAILS%,}]"  # Remove trailing comma

# Create terraform.tfvars
log_info "Creating terraform.tfvars..."
cat > terraform.tfvars <<EOF
environment = "$ENVIRONMENT"

aws_region = "$AWS_REGION"

notification_emails = $TERRAFORM_EMAILS

enable_daily_report  = true
enable_weekly_report = true

report_type = "daily"

log_retention_days = 7

# Cross-account role ARNs (leave empty for same-account deployment)
dev_account_role_arn  = ""
sit_account_role_arn  = ""
prod_account_role_arn = ""

cross_account_role_arns = []
EOF

log_success "terraform.tfvars created"

# Initialize Terraform with environment-specific state
log_info "Initializing Terraform..."
# Remove terraform artifacts for clean initialization
rm -rf .terraform terraform.tfstate* tfplan

# Initialize with "no" to state migration prompt
if ! echo "no" | terraform init -backend-config="path=terraform-${ENVIRONMENT}.tfstate"; then
    log_error "Terraform initialization failed"
    exit 1
fi
log_success "Terraform initialized"

# Generate plan
log_info "Generating Terraform plan..."
if ! terraform plan -out=tfplan; then
    log_error "Terraform plan failed"
    exit 1
fi
log_success "Terraform plan generated"

# Prompt for confirmation
echo ""
log_warning "About to deploy the following:"
log_info "  Environment: $ENVIRONMENT"
log_info "  AWS Account: $AWS_ACCOUNT ($AWS_PROFILE)"
log_info "  Email Recipients: ${EMAIL_ARRAY[@]}"
log_info "  Daily Reports: Enabled (7 AM UTC)"
log_info "  Weekly Reports: Enabled (Monday 8 AM UTC)"
echo ""
read -p "$(echo -e ${YELLOW}Do you want to proceed? [y/N]:${NC} )" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_warning "Deployment cancelled"
    exit 0
fi

# Apply Terraform
log_info "Deploying infrastructure..."
if ! terraform apply tfplan; then
    log_error "Terraform apply failed"
    exit 1
fi
log_success "Infrastructure deployed!"

# Get outputs
SNS_TOPIC_ARN=$(terraform output -raw sns_topic_arn)
LAMBDA_FUNCTION_NAME=$(terraform output -raw lambda_function_name)

echo ""
log_success "==================================================================="
log_success "Deployment completed successfully!"
log_success "==================================================================="
echo ""
log_info "Environment: $ENVIRONMENT"
log_info "Lambda Function: $LAMBDA_FUNCTION_NAME"
log_info "SNS Topic: $SNS_TOPIC_ARN"
echo ""
log_warning "IMPORTANT: Email Subscription Confirmation Required!"
log_info "Each recipient must confirm their email subscription:"
for email in "${EMAIL_ARRAY[@]}"; do
    log_info "  - $email"
done
echo ""
log_info "Check your inbox for subscription confirmation emails."
log_info "Click the confirmation link to start receiving reports."
echo ""

# Test the function
log_info "Testing Lambda function..."
read -p "$(echo -e ${YELLOW}Would you like to send a test report now? [y/N]:${NC} )" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_info "Triggering test daily report..."
    aws lambda invoke \
        --function-name $LAMBDA_FUNCTION_NAME \
        --payload '{"report_type": "daily"}' \
        --cli-binary-format raw-in-base64-out \
        response.json \
        > /dev/null 2>&1

    if [ $? -eq 0 ]; then
        log_success "Test report sent! Check your email."
        log_info "Response: $(cat response.json)"
        rm response.json
    else
        log_error "Test report failed. Check CloudWatch logs:"
        log_info "aws logs tail /aws/lambda/$LAMBDA_FUNCTION_NAME --follow"
    fi
fi

echo ""
log_success "==================================================================="
log_success "Next Steps:"
log_success "==================================================================="
echo ""
log_info "1. Confirm email subscriptions (check your inbox)"
log_info "2. Wait for scheduled reports:"
log_info "   - Daily: 7 AM UTC (9 AM CAT)"
log_info "   - Weekly: Mondays 8 AM UTC (10 AM CAT)"
log_info "3. Monitor Lambda execution:"
log_info "   aws logs tail /aws/lambda/$LAMBDA_FUNCTION_NAME --follow"
log_info "4. View CloudWatch metrics in AWS Console"
echo ""
log_success "Deployment script completed!"
echo ""
