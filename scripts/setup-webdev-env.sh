#!/bin/bash
#===============================================================================
# BBWS Web Development Team - Environment Setup Script
#
# This script sets up a developer's local environment with all necessary tools
# and configurations for the sandbox environment.
#
# Usage:
#   ./setup-webdev-env.sh
#
# What this script does:
#   1. Checks/installs AWS CLI v2
#   2. Checks/installs Terraform
#   3. Checks/installs GitHub CLI
#   4. Configures AWS SSO profile
#   5. Installs VSCode extensions (if VSCode is installed)
#   6. Clones required repositories
#
# AWS Account: 417589271098
# Region: eu-west-1
#===============================================================================

set -e

# Configuration
AWS_ACCOUNT_ID="417589271098"
AWS_REGION="eu-west-1"
SSO_START_URL="https://d-9367a8daf2.awsapps.com/start/#"
SSO_REGION="eu-west-1"
GITHUB_ORG="BigBeardWebSolutions"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

echo_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

#-------------------------------------------------------------------------------
# Header
#-------------------------------------------------------------------------------
echo "=============================================="
echo "BBWS Web Development Team - Environment Setup"
echo "=============================================="
echo ""

#-------------------------------------------------------------------------------
# Check OS
#-------------------------------------------------------------------------------
OS="$(uname -s)"
case "$OS" in
    Darwin*)    OS_TYPE="macOS";;
    Linux*)     OS_TYPE="Linux";;
    *)          echo_error "Unsupported OS: $OS"; exit 1;;
esac
echo_info "Detected OS: $OS_TYPE"
echo ""

#-------------------------------------------------------------------------------
# Step 1: Check/Install Homebrew (macOS only)
#-------------------------------------------------------------------------------
if [ "$OS_TYPE" = "macOS" ]; then
    echo_step "Step 1: Checking Homebrew..."
    if ! command -v brew &> /dev/null; then
        echo_warn "Homebrew not found. Installing..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        echo_info "Homebrew is already installed"
    fi
    echo ""
fi

#-------------------------------------------------------------------------------
# Step 2: Check/Install AWS CLI v2
#-------------------------------------------------------------------------------
echo_step "Step 2: Checking AWS CLI..."
if ! command -v aws &> /dev/null; then
    echo_warn "AWS CLI not found. Installing..."
    if [ "$OS_TYPE" = "macOS" ]; then
        brew install awscli
    else
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        unzip awscliv2.zip
        sudo ./aws/install
        rm -rf awscliv2.zip aws
    fi
else
    echo_info "AWS CLI is already installed: $(aws --version)"
fi
echo ""

#-------------------------------------------------------------------------------
# Step 3: Check/Install Terraform
#-------------------------------------------------------------------------------
echo_step "Step 3: Checking Terraform..."
if ! command -v terraform &> /dev/null; then
    echo_warn "Terraform not found. Installing..."
    if [ "$OS_TYPE" = "macOS" ]; then
        brew install terraform
    else
        sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
        wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
        sudo apt-get update && sudo apt-get install terraform
    fi
else
    echo_info "Terraform is already installed: $(terraform version | head -n1)"
fi
echo ""

#-------------------------------------------------------------------------------
# Step 4: Check/Install GitHub CLI
#-------------------------------------------------------------------------------
echo_step "Step 4: Checking GitHub CLI..."
if ! command -v gh &> /dev/null; then
    echo_warn "GitHub CLI not found. Installing..."
    if [ "$OS_TYPE" = "macOS" ]; then
        brew install gh
    else
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        sudo apt update && sudo apt install gh
    fi
else
    echo_info "GitHub CLI is already installed: $(gh --version | head -n1)"
fi
echo ""

#-------------------------------------------------------------------------------
# Step 5: Configure AWS SSO Profile
#-------------------------------------------------------------------------------
echo_step "Step 5: Configuring AWS SSO profile..."

AWS_CONFIG_FILE="$HOME/.aws/config"
mkdir -p "$HOME/.aws"

# Check if sandbox profile already exists
if grep -q "\[profile sandbox\]" "$AWS_CONFIG_FILE" 2>/dev/null; then
    echo_info "AWS profile 'sandbox' already exists"
else
    echo_info "Adding 'sandbox' profile to AWS config..."

    # Check if sso-session exists
    if ! grep -q "\[sso-session Sithembiso\]" "$AWS_CONFIG_FILE" 2>/dev/null; then
        cat >> "$AWS_CONFIG_FILE" << EOF

[sso-session Sithembiso]
sso_start_url = $SSO_START_URL
sso_region = $SSO_REGION
sso_registration_scopes = sso:account:access
EOF
    fi

    # Add sandbox profile
    cat >> "$AWS_CONFIG_FILE" << EOF

[profile sandbox]
sso_session = Sithembiso
sso_account_id = $AWS_ACCOUNT_ID
sso_role_name = AWSAdministratorAccess
region = $AWS_REGION
output = json
EOF

    echo_info "AWS profile 'sandbox' added successfully"
fi
echo ""

#-------------------------------------------------------------------------------
# Step 6: Install VSCode Extensions (if VSCode installed)
#-------------------------------------------------------------------------------
echo_step "Step 6: Checking VSCode extensions..."
if command -v code &> /dev/null; then
    EXTENSIONS=(
        "amazonwebservices.aws-toolkit-vscode"
        "hashicorp.terraform"
        "ms-python.python"
        "ms-azuretools.vscode-docker"
        "eamodio.gitlens"
        "redhat.vscode-yaml"
    )

    for ext in "${EXTENSIONS[@]}"; do
        if code --list-extensions | grep -q "$ext"; then
            echo_info "Extension $ext already installed"
        else
            echo_warn "Installing VSCode extension: $ext"
            code --install-extension "$ext" --force
        fi
    done
else
    echo_warn "VSCode CLI not found. Please install extensions manually:"
    echo "  - AWS Toolkit (amazonwebservices.aws-toolkit-vscode)"
    echo "  - HashiCorp Terraform (hashicorp.terraform)"
    echo "  - Python (ms-python.python)"
    echo "  - Docker (ms-azuretools.vscode-docker)"
    echo "  - GitLens (eamodio.gitlens)"
    echo "  - YAML (redhat.vscode-yaml)"
fi
echo ""

#-------------------------------------------------------------------------------
# Step 7: Check/Install Claude Code (optional)
#-------------------------------------------------------------------------------
echo_step "Step 7: Checking Claude Code..."
if command -v claude &> /dev/null; then
    echo_info "Claude Code is already installed"
else
    echo_warn "Claude Code not found."
    echo "  To install, run: npm install -g @anthropic-ai/claude-code"
    echo "  Or: brew install claude-code"
fi
echo ""

#-------------------------------------------------------------------------------
# Summary
#-------------------------------------------------------------------------------
echo "=============================================="
echo "Setup Complete!"
echo "=============================================="
echo ""
echo "Next steps:"
echo ""
echo "  1. Login to AWS SSO:"
echo "     aws sso login --profile sandbox"
echo ""
echo "  2. Verify access:"
echo "     aws sts get-caller-identity --profile sandbox"
echo ""
echo "  3. Login to GitHub (if not already):"
echo "     gh auth login"
echo ""
echo "  4. Clone repositories:"
echo "     gh repo clone $GITHUB_ORG/0_utilities"
echo "     gh repo clone $GITHUB_ORG/2_bbws_ecs_terraform"
echo "     gh repo clone $GITHUB_ORG/2_bbws_ecs_operations"
echo ""
echo "  5. Set default AWS profile (optional):"
echo "     export AWS_PROFILE=sandbox"
echo ""
echo "For questions, contact: development@bigbeard.co.za"
echo ""
