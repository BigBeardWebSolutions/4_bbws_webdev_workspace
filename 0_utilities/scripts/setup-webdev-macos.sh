#!/bin/bash
#===============================================================================
# Web Development Team - macOS Environment Setup Script
#===============================================================================
# Description: Installs and configures development tools for the web dev team
# Components:
#   - AWS CLI v2
#   - Visual Studio Code with extensions
#   - Claude Code CLI
#   - AWS Sandbox Profile (profile=sandbox)
#   - GitHub CLI and repository access
#   - Terraform
#   - Additional development tools
#
# Usage: ./setup-webdev-macos.sh
#
# Author: BigBeard Web Solutions
# Date: 2026-02-01
#===============================================================================

set -e

#-------------------------------------------------------------------------------
# Configuration
#-------------------------------------------------------------------------------
AWS_ACCOUNT_ID="417589271098"
AWS_REGION="eu-west-1"
AWS_PROFILE_NAME="sandbox"
AWS_SSO_ROLE="WebDevTeamRole"
AWS_SSO_START_URL="https://d-9367a8daf2.awsapps.com/start/#"
SSO_SESSION_NAME="BigBeard"

GITHUB_ORG="BigBeardWebSolutions"
WORKSPACE_DIR="/Users/sithembisomjoko/Downloads/AGENTIC_WORK/4_bbws_webdev_workspace"

# Repositories to clone
REPOS=(
    "0_utilities"
    "2_bbws_ecs_terraform"
    "2_bbws_ecs_operations"
    "2_bbws_wordpress_container"
)

# VS Code extensions to install
VSCODE_EXTENSIONS=(
    "amazonwebservices.aws-toolkit-vscode"
    "hashicorp.terraform"
    "ms-python.python"
    "ms-azuretools.vscode-docker"
    "eamodio.gitlens"
    "redhat.vscode-yaml"
    "ms-vscode.makefile-tools"
    "esbenp.prettier-vscode"
)

#-------------------------------------------------------------------------------
# Colors for output
#-------------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

#-------------------------------------------------------------------------------
# Helper Functions
#-------------------------------------------------------------------------------
print_header() {
    echo ""
    echo -e "${PURPLE}===============================================================================${NC}"
    echo -e "${PURPLE}  $1${NC}"
    echo -e "${PURPLE}===============================================================================${NC}"
    echo ""
}

print_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

#-------------------------------------------------------------------------------
# Pre-flight Checks
#-------------------------------------------------------------------------------
preflight_checks() {
    print_header "Pre-flight Checks"

    # Check macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_error "This script is designed for macOS only."
        exit 1
    fi
    print_success "Running on macOS"

    # Check macOS version
    OS_VERSION=$(sw_vers -productVersion)
    print_info "macOS version: $OS_VERSION"

    # Check internet connectivity
    print_step "Checking internet connectivity..."
    if ping -c 1 google.com &>/dev/null; then
        print_success "Internet connection available"
    else
        print_error "No internet connection. Please check your network."
        exit 1
    fi

    # Check for Xcode Command Line Tools
    print_step "Checking for Xcode Command Line Tools..."
    if xcode-select -p &>/dev/null; then
        print_success "Xcode Command Line Tools installed"
    else
        print_warning "Xcode Command Line Tools not found. Installing..."
        xcode-select --install
        print_info "Please complete the Xcode Command Line Tools installation and re-run this script."
        exit 0
    fi
}

#-------------------------------------------------------------------------------
# Install Homebrew
#-------------------------------------------------------------------------------
install_homebrew() {
    print_header "Homebrew Installation"

    if command_exists brew; then
        print_success "Homebrew already installed"
        print_step "Updating Homebrew..."
        brew update
    else
        print_step "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Add Homebrew to PATH for Apple Silicon Macs
        if [[ $(uname -m) == "arm64" ]]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
        print_success "Homebrew installed successfully"
    fi
}

#-------------------------------------------------------------------------------
# Install AWS CLI
#-------------------------------------------------------------------------------
install_aws_cli() {
    print_header "AWS CLI Installation"

    if command_exists aws; then
        AWS_VERSION=$(aws --version 2>&1 | cut -d' ' -f1 | cut -d'/' -f2)
        print_success "AWS CLI already installed (version: $AWS_VERSION)"
    else
        print_step "Installing AWS CLI v2..."
        brew install awscli
        print_success "AWS CLI installed successfully"
    fi

    # Verify installation
    aws --version
}

#-------------------------------------------------------------------------------
# Configure AWS Sandbox Profile
#-------------------------------------------------------------------------------
configure_aws_profile() {
    print_header "AWS Sandbox Profile Configuration"

    AWS_CONFIG_DIR="$HOME/.aws"
    AWS_CONFIG_FILE="$AWS_CONFIG_DIR/config"

    # Create .aws directory if it doesn't exist
    mkdir -p "$AWS_CONFIG_DIR"

    # Check if sandbox profile already exists
    if grep -q "\[profile $AWS_PROFILE_NAME\]" "$AWS_CONFIG_FILE" 2>/dev/null; then
        print_warning "Profile '$AWS_PROFILE_NAME' already exists in $AWS_CONFIG_FILE"
        read -p "Do you want to overwrite it? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Skipping AWS profile configuration"
            return
        fi
        # Remove existing profile
        sed -i '' "/\[profile $AWS_PROFILE_NAME\]/,/^\[/{ /^\[profile $AWS_PROFILE_NAME\]/d; /^\[/!d; }" "$AWS_CONFIG_FILE"
        sed -i '' "/\[sso-session $SSO_SESSION_NAME\]/,/^\[/{ /^\[sso-session $SSO_SESSION_NAME\]/d; /^\[/!d; }" "$AWS_CONFIG_FILE"
    fi

    print_step "Adding sandbox profile to AWS config..."

    # Add SSO session if not exists
    if ! grep -q "\[sso-session $SSO_SESSION_NAME\]" "$AWS_CONFIG_FILE" 2>/dev/null; then
        cat >> "$AWS_CONFIG_FILE" << EOF

[sso-session $SSO_SESSION_NAME]
sso_start_url = $AWS_SSO_START_URL
sso_region = $AWS_REGION
sso_registration_scopes = sso:account:access
EOF
    fi

    # Add sandbox profile
    cat >> "$AWS_CONFIG_FILE" << EOF

[profile $AWS_PROFILE_NAME]
sso_session = $SSO_SESSION_NAME
sso_account_id = $AWS_ACCOUNT_ID
sso_role_name = $AWS_SSO_ROLE
region = $AWS_REGION
output = json
EOF

    print_success "AWS sandbox profile configured"
    print_info "Profile details:"
    echo "  - Profile name: $AWS_PROFILE_NAME"
    echo "  - Account ID: $AWS_ACCOUNT_ID"
    echo "  - Region: $AWS_REGION"
    echo "  - Role: $AWS_SSO_ROLE"

    # Test SSO login
    print_step "Testing AWS SSO login..."
    print_info "A browser window will open for SSO authentication..."

    if aws sso login --profile "$AWS_PROFILE_NAME"; then
        print_success "AWS SSO login successful"

        # Verify identity
        print_step "Verifying AWS identity..."
        aws sts get-caller-identity --profile "$AWS_PROFILE_NAME"
    else
        print_warning "SSO login failed or was cancelled. You can login later with:"
        echo "  aws sso login --profile $AWS_PROFILE_NAME"
    fi
}

#-------------------------------------------------------------------------------
# Install Visual Studio Code
#-------------------------------------------------------------------------------
install_vscode() {
    print_header "Visual Studio Code Installation"

    if command_exists code; then
        print_success "VS Code already installed"
    else
        print_step "Installing Visual Studio Code..."
        brew install --cask visual-studio-code
        print_success "VS Code installed successfully"
    fi

    # Install extensions
    print_step "Installing VS Code extensions..."

    for ext in "${VSCODE_EXTENSIONS[@]}"; do
        print_info "Installing extension: $ext"
        code --install-extension "$ext" --force 2>/dev/null || print_warning "Failed to install $ext"
    done

    print_success "VS Code extensions installed"
}

#-------------------------------------------------------------------------------
# Install Node.js and Claude Code
#-------------------------------------------------------------------------------
install_claude_code() {
    print_header "Claude Code Installation"

    # Check/Install Node.js
    if command_exists node; then
        NODE_VERSION=$(node --version)
        print_success "Node.js already installed (version: $NODE_VERSION)"
    else
        print_step "Installing Node.js..."
        brew install node
        print_success "Node.js installed"
    fi

    # Install Claude Code
    print_step "Installing Claude Code CLI..."

    if command_exists claude; then
        print_success "Claude Code already installed"
    else
        # Try npm install first
        if npm install -g @anthropic-ai/claude-code 2>/dev/null; then
            print_success "Claude Code installed via npm"
        else
            # Fallback to brew if available
            print_info "Trying Homebrew installation..."
            if brew install claude-code 2>/dev/null; then
                print_success "Claude Code installed via Homebrew"
            else
                print_warning "Claude Code installation requires manual setup."
                print_info "Visit: https://claude.ai/claude-code for installation instructions"
            fi
        fi
    fi

    # Verify installation
    if command_exists claude; then
        print_info "Claude Code is ready to use. Run 'claude' to start."
    fi
}

#-------------------------------------------------------------------------------
# Install GitHub CLI and Setup
#-------------------------------------------------------------------------------
setup_github() {
    print_header "GitHub CLI Installation and Setup"

    # Install GitHub CLI
    if command_exists gh; then
        print_success "GitHub CLI already installed"
    else
        print_step "Installing GitHub CLI..."
        brew install gh
        print_success "GitHub CLI installed"
    fi

    # Check authentication status
    print_step "Checking GitHub authentication..."

    if gh auth status &>/dev/null; then
        print_success "Already authenticated with GitHub"
    else
        print_info "Please authenticate with GitHub..."
        gh auth login
    fi

    # Create workspace directory
    print_step "Creating workspace directory..."
    mkdir -p "$WORKSPACE_DIR"
    print_success "Workspace directory: $WORKSPACE_DIR"

    # Clone repositories
    print_step "Cloning repositories..."

    cd "$WORKSPACE_DIR"

    for repo in "${REPOS[@]}"; do
        if [ -d "$repo" ]; then
            print_info "Repository '$repo' already exists. Pulling latest..."
            cd "$repo"
            git pull origin main 2>/dev/null || git pull origin master 2>/dev/null || print_warning "Could not pull latest for $repo"
            cd ..
        else
            print_info "Cloning $GITHUB_ORG/$repo..."
            if gh repo clone "$GITHUB_ORG/$repo" 2>/dev/null; then
                print_success "Cloned $repo"
            else
                print_warning "Failed to clone $repo (may not have access)"
            fi
        fi
    done

    print_success "GitHub setup complete"
}

#-------------------------------------------------------------------------------
# Install Additional Tools
#-------------------------------------------------------------------------------
install_additional_tools() {
    print_header "Additional Development Tools"

    # Terraform
    print_step "Installing Terraform..."
    if command_exists terraform; then
        TERRAFORM_VERSION=$(terraform version -json 2>/dev/null | grep -o '"terraform_version":"[^"]*"' | cut -d'"' -f4)
        print_success "Terraform already installed (version: $TERRAFORM_VERSION)"
    else
        brew install terraform
        print_success "Terraform installed"
    fi

    # jq (JSON processor)
    print_step "Installing jq..."
    if command_exists jq; then
        print_success "jq already installed"
    else
        brew install jq
        print_success "jq installed"
    fi

    # Docker Desktop prompt
    print_step "Checking Docker..."
    if command_exists docker; then
        print_success "Docker already installed"
    else
        print_warning "Docker Desktop is not installed."
        print_info "Docker Desktop requires manual installation."
        print_info "Download from: https://www.docker.com/products/docker-desktop"

        read -p "Would you like to open the Docker Desktop download page? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            open "https://www.docker.com/products/docker-desktop"
        fi
    fi
}

#-------------------------------------------------------------------------------
# Create Helper Scripts
#-------------------------------------------------------------------------------
create_helper_scripts() {
    print_header "Creating Helper Scripts"

    SCRIPTS_DIR="$WORKSPACE_DIR/scripts"
    mkdir -p "$SCRIPTS_DIR"

    # Create AWS SSO login helper
    cat > "$SCRIPTS_DIR/aws-sandbox-login.sh" << 'EOF'
#!/bin/bash
# Quick login to AWS Sandbox profile
aws sso login --profile sandbox
aws sts get-caller-identity --profile sandbox
export AWS_PROFILE=sandbox
echo "AWS_PROFILE set to 'sandbox'"
EOF
    chmod +x "$SCRIPTS_DIR/aws-sandbox-login.sh"

    # Create environment setup helper
    cat > "$SCRIPTS_DIR/set-sandbox-env.sh" << 'EOF'
#!/bin/bash
# Set environment for sandbox work
export AWS_PROFILE=sandbox
export AWS_REGION=eu-west-1
echo "Environment configured for sandbox:"
echo "  AWS_PROFILE=$AWS_PROFILE"
echo "  AWS_REGION=$AWS_REGION"
EOF
    chmod +x "$SCRIPTS_DIR/set-sandbox-env.sh"

    print_success "Helper scripts created in $SCRIPTS_DIR"
    print_info "  - aws-sandbox-login.sh: Login to AWS SSO"
    print_info "  - set-sandbox-env.sh: Set sandbox environment variables"
}

#-------------------------------------------------------------------------------
# Print Summary
#-------------------------------------------------------------------------------
print_summary() {
    print_header "Installation Summary"

    echo -e "${GREEN}Installation complete!${NC}"
    echo ""
    echo "Installed Components:"
    echo "---------------------"

    # Check each component
    if command_exists brew; then
        echo -e "  ${GREEN}[INSTALLED]${NC} Homebrew"
    fi

    if command_exists aws; then
        echo -e "  ${GREEN}[INSTALLED]${NC} AWS CLI ($(aws --version 2>&1 | cut -d' ' -f1))"
    fi

    if command_exists code; then
        echo -e "  ${GREEN}[INSTALLED]${NC} Visual Studio Code"
    fi

    if command_exists claude; then
        echo -e "  ${GREEN}[INSTALLED]${NC} Claude Code"
    else
        echo -e "  ${YELLOW}[PENDING]${NC} Claude Code (may require manual setup)"
    fi

    if command_exists gh; then
        echo -e "  ${GREEN}[INSTALLED]${NC} GitHub CLI"
    fi

    if command_exists terraform; then
        echo -e "  ${GREEN}[INSTALLED]${NC} Terraform"
    fi

    if command_exists docker; then
        echo -e "  ${GREEN}[INSTALLED]${NC} Docker"
    else
        echo -e "  ${YELLOW}[PENDING]${NC} Docker Desktop (manual installation required)"
    fi

    if command_exists jq; then
        echo -e "  ${GREEN}[INSTALLED]${NC} jq"
    fi

    echo ""
    echo "AWS Configuration:"
    echo "------------------"
    echo "  Profile: $AWS_PROFILE_NAME"
    echo "  Account: $AWS_ACCOUNT_ID"
    echo "  Region: $AWS_REGION"
    echo "  Role: $AWS_SSO_ROLE"
    echo ""
    echo "Workspace Location:"
    echo "-------------------"
    echo "  $WORKSPACE_DIR"
    echo ""
    echo "Quick Commands:"
    echo "---------------"
    echo "  aws sso login --profile sandbox    # Login to AWS"
    echo "  export AWS_PROFILE=sandbox         # Set default profile"
    echo "  gh auth status                     # Check GitHub auth"
    echo "  claude                             # Start Claude Code"
    echo ""
    echo "Helper Scripts:"
    echo "---------------"
    echo "  source $WORKSPACE_DIR/scripts/aws-sandbox-login.sh"
    echo "  source $WORKSPACE_DIR/scripts/set-sandbox-env.sh"
    echo ""
    print_success "Setup complete! Happy coding!"
}

#-------------------------------------------------------------------------------
# Main Execution
#-------------------------------------------------------------------------------
main() {
    clear
    print_header "Web Development Team - macOS Environment Setup"

    echo "This script will install and configure:"
    echo "  1. Homebrew (package manager)"
    echo "  2. AWS CLI v2"
    echo "  3. Visual Studio Code with extensions"
    echo "  4. Claude Code CLI"
    echo "  5. GitHub CLI and repository access"
    echo "  6. Terraform"
    echo "  7. AWS Sandbox profile configuration"
    echo ""

    read -p "Continue with installation? (Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        print_info "Installation cancelled."
        exit 0
    fi

    # Run installation steps
    preflight_checks
    install_homebrew
    install_aws_cli
    configure_aws_profile
    install_vscode
    install_claude_code
    setup_github
    install_additional_tools
    create_helper_scripts
    print_summary
}

# Run main function
main "$@"
