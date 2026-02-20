#!/bin/bash

################################################################################
# WordPress Export to S3 Upload Script
################################################################################
#
# Description:
#   Uploads WordPress export files to AWS S3.
#   By default, uploads from current working directory.
#
# Prerequisites:
#   1. AWS CLI installed: https://aws.amazon.com/cli/
#   2. AWS credentials configured (profile or environment variables)
#
# Usage:
#   ./upload-to-s3.sh -w <website-name>
#
# Examples:
#   cd exports-manufacturing-20260113_075835
#   ./upload-to-s3.sh -w manufacturing
#
#   # Or specify directory explicitly:
#   ./upload-to-s3.sh -w manufacturing -e ~/exports-manufacturing-20260113_075835
#
################################################################################

set -euo pipefail

################################################################################
# S3 CONFIGURATION
################################################################################
# Configure your S3 bucket details here.

S3_BUCKET="wordpress-migration-temp-20250903"
S3_REGION="eu-west-1"

################################################################################
# AWS AUTHENTICATION CONFIGURATION
################################################################################
# Option 1: Use environment variables (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
# Option 2: Use AWS profile (set below)
# Option 3: Use IAM role (if running on EC2/Lambda)

# Default AWS profile to use (if not using environment variables)
DEFAULT_AWS_PROFILE="dev"

# Uncomment and set these to use hardcoded credentials (NOT RECOMMENDED)
# AWS_ACCESS_KEY_ID=""
# AWS_SECRET_ACCESS_KEY=""

################################################################################
# END OF CONFIGURATION
################################################################################

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

################################################################################
# Functions
################################################################################

print_header() {
    echo -e "\n${BLUE}======================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}======================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1" >&2
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

error_exit() {
    print_error "$1"
    exit 1
}

show_help() {
    cat << EOF
WordPress Export to S3 Upload Script

Uploads export files to AWS S3. By default, uploads from current directory.

Usage:
  $0 -w <website-name> [OPTIONS]

Required Parameters:
  -w, --website-name NAME    Website name (used as S3 folder name)

Optional Parameters:
  -e, --export-dir PATH      Directory to upload (default: current directory)
  -p, --profile NAME         AWS profile (default: ${DEFAULT_AWS_PROFILE})
  --help                     Display this help message

Examples:
  # Upload current directory
  cd exports-manufacturing-20260113_075835
  $0 -w manufacturing

  # Upload specific directory
  $0 -w manufacturing -e ./exports-manufacturing-20260113_075835

  # Use different AWS profile
  $0 -w manufacturing -p production

S3 Destination:
  Bucket: s3://${S3_BUCKET}
  Region: ${S3_REGION}
  Path: s3://${S3_BUCKET}/<website-name>/

Download from S3:
  aws s3 sync s3://${S3_BUCKET}/<website-name>/ . --profile ${DEFAULT_AWS_PROFILE}

EOF
    exit 0
}

################################################################################
# Argument Parsing
################################################################################

WEBSITE_NAME=""
EXPORT_DIR=""
AWS_PROFILE="$DEFAULT_AWS_PROFILE"

while [[ $# -gt 0 ]]; do
    case $1 in
        -w|--website-name)
            WEBSITE_NAME="$2"
            shift 2
            ;;
        -e|--export-dir)
            EXPORT_DIR="$2"
            shift 2
            ;;
        -p|--profile)
            AWS_PROFILE="$2"
            shift 2
            ;;
        --help)
            show_help
            ;;
        *)
            error_exit "Unknown option: $1\nUse --help for usage information."
            ;;
    esac
done

# Validate required parameters
if [[ -z "$WEBSITE_NAME" ]]; then
    error_exit "Website name is required. Use -w or --website-name"
fi

# Default to current directory if not specified
if [[ -z "$EXPORT_DIR" ]]; then
    EXPORT_DIR="$(pwd)"
    print_info "Using current directory: ${EXPORT_DIR}"
fi

################################################################################
# Main Script
################################################################################

print_header "WordPress Export S3 Upload"

echo -e "Website:       ${GREEN}${WEBSITE_NAME}${NC}"
echo -e "Export Dir:    ${GREEN}${EXPORT_DIR}${NC}"
echo -e "S3 Bucket:     ${GREEN}s3://${S3_BUCKET}${NC}"
echo -e "S3 Region:     ${GREEN}${S3_REGION}${NC}"
echo -e "S3 Path:       ${GREEN}s3://${S3_BUCKET}/${WEBSITE_NAME}/${NC}"
echo ""

# Check and install AWS CLI if needed
print_header "Checking Prerequisites"

# First, check for existing AWS CLI installation in common locations
AWS_CLI_PATHS=(
    "$HOME/aws-cli/v2/current/bin"
    "$HOME/bin"
    "/usr/local/bin"
    "/usr/bin"
    "/opt/homebrew/bin"
)

for aws_path in "${AWS_CLI_PATHS[@]}"; do
    if [[ -x "${aws_path}/aws" ]]; then
        export PATH="${aws_path}:$PATH"
        print_success "Found existing AWS CLI at ${aws_path}"
        break
    fi
done

if ! command -v aws &> /dev/null; then
    print_warning "AWS CLI is not installed"

    # Detect OS for appropriate install method
    if [[ "$OSTYPE" == "darwin"* ]]; then
        print_info "On macOS - please install AWS CLI via:"
        echo "  brew install awscli"
        echo "  OR"
        echo "  curl \"https://awscli.amazonaws.com/AWSCLIV2.pkg\" -o \"AWSCLIV2.pkg\" && sudo installer -pkg AWSCLIV2.pkg -target /"
        exit 1
    else
        print_info "Installing AWS CLI to ~/aws-cli..."

        # Download AWS CLI
        if ! curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"; then
            error_exit "Failed to download AWS CLI"
        fi

        # Unzip
        if ! unzip -q awscliv2.zip; then
            error_exit "Failed to unzip AWS CLI"
        fi

        # Install to home directory (no sudo needed)
        if [[ -d "$HOME/aws-cli" ]]; then
            ./aws/install -i ~/aws-cli -b ~/bin --update || error_exit "Failed to update AWS CLI"
        else
            ./aws/install -i ~/aws-cli -b ~/bin || error_exit "Failed to install AWS CLI"
        fi

        # Add to PATH
        export PATH=~/bin:~/aws-cli/v2/current/bin:$PATH

        # Add to bashrc for persistence
        if ! grep -q "aws-cli/v2/current/bin" ~/.bashrc 2>/dev/null; then
            echo 'export PATH=~/bin:~/aws-cli/v2/current/bin:$PATH' >> ~/.bashrc
        fi

        # Cleanup
        rm -rf aws awscliv2.zip

        print_success "AWS CLI installed successfully"
    fi
else
    print_success "AWS CLI is installed"
fi

# Check AWS CLI version
AWS_VERSION=$(aws --version 2>&1 | head -1)
print_info "AWS CLI version: ${AWS_VERSION}"

# Check if export directory exists
print_header "Verifying Export Directory"

if [[ ! -d "$EXPORT_DIR" ]]; then
    error_exit "Export directory not found: ${EXPORT_DIR}"
fi

print_success "Export directory exists: ${EXPORT_DIR}"

# List files to upload
print_info "Files to upload:"
ls -lh "$EXPORT_DIR"
echo ""

# Setup AWS authentication
print_header "Configuring AWS Authentication"

# Determine authentication method
if [[ -n "${AWS_ACCESS_KEY_ID:-}" ]] && [[ -n "${AWS_SECRET_ACCESS_KEY:-}" ]]; then
    export AWS_DEFAULT_REGION="$S3_REGION"
    print_success "Using environment variable credentials"
    AUTH_METHOD="env-vars"
else
    print_info "Using AWS profile: ${AWS_PROFILE}"
    AUTH_METHOD="profile"
fi

# Check AWS authentication
print_header "Verifying AWS Authentication"

if [[ "$AUTH_METHOD" == "env-vars" ]]; then
    if ! aws sts get-caller-identity --region "$S3_REGION" &> /dev/null; then
        print_error "Authentication failed with environment credentials"
        echo ""
        print_info "Please check your AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY"
        exit 1
    fi

    AWS_IDENTITY=$(aws sts get-caller-identity --region "$S3_REGION" --query 'Arn' --output text 2>/dev/null || echo "Unknown")
    print_success "Authenticated to AWS"
    print_info "Using: Environment credentials"
    print_info "Identity: ${AWS_IDENTITY}"
else
    if ! aws sts get-caller-identity --profile "$AWS_PROFILE" &> /dev/null; then
        print_error "Not authenticated to AWS with profile: ${AWS_PROFILE}"
        echo ""
        print_info "Please authenticate first:"
        echo ""
        echo -e "  ${BLUE}# Login with SSO:${NC}"
        echo -e "  aws sso login --profile ${AWS_PROFILE}"
        echo ""
        echo -e "  ${BLUE}# Or configure credentials:${NC}"
        echo -e "  aws configure --profile ${AWS_PROFILE}"
        echo ""
        echo -e "  ${BLUE}# Or use environment variables:${NC}"
        echo -e "  export AWS_ACCESS_KEY_ID=your_key"
        echo -e "  export AWS_SECRET_ACCESS_KEY=your_secret"
        echo ""
        exit 1
    fi

    AWS_IDENTITY=$(aws sts get-caller-identity --profile "$AWS_PROFILE" --query 'Arn' --output text 2>/dev/null || echo "Unknown")
    print_success "Authenticated to AWS"
    print_info "Using profile: ${AWS_PROFILE}"
    print_info "Identity: ${AWS_IDENTITY}"
fi

# Upload to S3
print_header "Uploading to S3"

S3_PATH="s3://${S3_BUCKET}/${WEBSITE_NAME}/"

print_info "Uploading to: ${S3_PATH}"
print_warning "This may take several minutes depending on file size and connection speed..."

# Sync export directory to S3
if [[ "$AUTH_METHOD" == "env-vars" ]]; then
    if aws s3 sync "$EXPORT_DIR" "$S3_PATH" \
        --region "$S3_REGION" \
        --no-progress; then
        print_success "Upload completed successfully!"
    else
        error_exit "Upload failed"
    fi
else
    if aws s3 sync "$EXPORT_DIR" "$S3_PATH" \
        --region "$S3_REGION" \
        --profile "$AWS_PROFILE" \
        --no-progress; then
        print_success "Upload completed successfully!"
    else
        error_exit "Upload failed"
    fi
fi

# Verify upload
print_header "Verifying Upload"

print_info "Files in S3:"
if [[ "$AUTH_METHOD" == "env-vars" ]]; then
    aws s3 ls "$S3_PATH" --region "$S3_REGION"
    TOTAL_SIZE=$(aws s3 ls "$S3_PATH" --recursive --summarize --region "$S3_REGION" 2>/dev/null | grep "Total Size" | awk '{print $3}')
else
    aws s3 ls "$S3_PATH" --profile "$AWS_PROFILE" --region "$S3_REGION"
    TOTAL_SIZE=$(aws s3 ls "$S3_PATH" --recursive --summarize --profile "$AWS_PROFILE" --region "$S3_REGION" 2>/dev/null | grep "Total Size" | awk '{print $3}')
fi

if [[ -n "${TOTAL_SIZE:-}" ]] && [[ "$TOTAL_SIZE" =~ ^[0-9]+$ ]]; then
    TOTAL_SIZE_MB=$((TOTAL_SIZE / 1024 / 1024))
    print_success "Total uploaded: ${TOTAL_SIZE_MB}MB"
fi

# Final report
print_header "Upload Complete"

echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  S3 Upload Successful!${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "S3 Location: ${BLUE}${S3_PATH}${NC}"
echo ""
echo -e "${YELLOW}Download to Local Machine:${NC}"
echo ""
echo -e "  ${BLUE}# Create download directory${NC}"
echo -e "  mkdir -p ~/Downloads/wordpress-exports/${WEBSITE_NAME}"
echo -e "  cd ~/Downloads/wordpress-exports/${WEBSITE_NAME}"
echo ""
echo -e "  ${BLUE}# Download from S3${NC}"
if [[ "$AUTH_METHOD" == "env-vars" ]]; then
    echo -e "  aws s3 sync ${S3_PATH} . --region ${S3_REGION}"
else
    echo -e "  aws s3 sync ${S3_PATH} . --profile ${AWS_PROFILE} --region ${S3_REGION}"
fi
echo ""
echo -e "${YELLOW}List S3 Contents:${NC}"
if [[ "$AUTH_METHOD" == "env-vars" ]]; then
    echo -e "  aws s3 ls ${S3_PATH} --region ${S3_REGION}"
else
    echo -e "  aws s3 ls ${S3_PATH} --profile ${AWS_PROFILE} --region ${S3_REGION}"
fi
echo ""
echo -e "${YELLOW}Delete from S3 (after download):${NC}"
if [[ "$AUTH_METHOD" == "env-vars" ]]; then
    echo -e "  aws s3 rm ${S3_PATH} --recursive --region ${S3_REGION}"
else
    echo -e "  aws s3 rm ${S3_PATH} --recursive --profile ${AWS_PROFILE} --region ${S3_REGION}"
fi
echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"

exit 0
