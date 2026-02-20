#!/bin/bash

##############################################################################
# WordPress Files Upload Script for Au Pair Hive Migration
# Purpose: Upload WordPress files to tenant EFS access point
# Usage: ./upload_wordpress_files.sh <files_archive> <environment> <tenant_id>
##############################################################################

set -euo pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Script variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="${SCRIPT_DIR}/upload_${TIMESTAMP}.log"
TEMP_DIR="${SCRIPT_DIR}/temp_extract_${TIMESTAMP}"

##############################################################################
# Functions
##############################################################################

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] ✓${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ✗${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] ⚠${NC} $1" | tee -a "$LOG_FILE"
}

usage() {
    cat <<EOF
Usage: $0 <files_archive> <environment> <tenant_id>

Arguments:
    files_archive - Path to WordPress files archive (.zip or .tar.gz)
    environment   - Target environment (dev, sit, prod)
    tenant_id     - Tenant identifier (e.g., aupairhive)

Examples:
    $0 aupairhive_files_20260109.zip dev aupairhive
    $0 wordpress_backup.tar.gz sit aupairhive

Methods:
    This script supports multiple upload methods:
    1. S3 + ECS Task (recommended for large files)
    2. Direct EFS mount (if local machine has EFS access)
    3. Manual instructions (if automated upload fails)

Prerequisites:
    - AWS CLI configured
    - Tenant provisioned in environment
    - WordPress files archive from Xneelo
    - unzip or tar command available

EOF
    exit 1
}

validate_inputs() {
    log "Validating inputs..."

    if [[ $# -ne 3 ]]; then
        log_error "Invalid number of arguments"
        usage
    fi

    FILES_ARCHIVE="$1"
    ENVIRONMENT="$2"
    TENANT_ID="$3"

    # Validate archive exists
    if [[ ! -f "$FILES_ARCHIVE" ]]; then
        log_error "Files archive not found: $FILES_ARCHIVE"
        exit 1
    fi

    # Validate environment
    if [[ ! "$ENVIRONMENT" =~ ^(dev|sit|prod)$ ]]; then
        log_error "Invalid environment: $ENVIRONMENT"
        exit 1
    fi

    # Validate tenant ID
    if [[ -z "$TENANT_ID" ]]; then
        log_error "Tenant ID cannot be empty"
        exit 1
    fi

    # Check file extension
    if [[ "$FILES_ARCHIVE" =~ \.zip$ ]]; then
        ARCHIVE_TYPE="zip"
    elif [[ "$FILES_ARCHIVE" =~ \.tar\.gz$ ]] || [[ "$FILES_ARCHIVE" =~ \.tgz$ ]]; then
        ARCHIVE_TYPE="tar"
    else
        log_error "Unsupported archive format. Use .zip or .tar.gz"
        exit 1
    fi

    log_success "Input validation passed"
}

set_environment_config() {
    log "Setting environment configuration..."

    case "$ENVIRONMENT" in
        dev)
            AWS_PROFILE="Tebogo-dev"
            AWS_ACCOUNT="536580886816"
            AWS_REGION="eu-west-1"
            DOMAIN_SUFFIX="wpdev.kimmyai.io"
            ECS_CLUSTER="dev-cluster"
            ;;
        sit)
            AWS_PROFILE="Tebogo-sit"
            AWS_ACCOUNT="815856636111"
            AWS_REGION="eu-west-1"
            DOMAIN_SUFFIX="wpsit.kimmyai.io"
            ECS_CLUSTER="sit-cluster"
            ;;
        prod)
            AWS_PROFILE="Tebogo-prod"
            AWS_ACCOUNT="093646564004"
            AWS_REGION="af-south-1"
            DOMAIN_SUFFIX="wp.kimmyai.io"
            ECS_CLUSTER="prod-cluster"
            ;;
    esac

    TARGET_URL="https://${TENANT_ID}.${DOMAIN_SUFFIX}"
    EFS_PATH="/tenant-${TENANT_ID}"
    S3_BUCKET="bbws-${ENVIRONMENT}-uploads"  # Adjust as needed
    S3_KEY="migrations/${TENANT_ID}/wordpress_files.zip"

    export AWS_PROFILE
    export AWS_DEFAULT_REGION="$AWS_REGION"

    log_success "Environment configured: $ENVIRONMENT"
    log "  Target URL: $TARGET_URL"
    log "  EFS Path: $EFS_PATH"
}

verify_aws_credentials() {
    log "Verifying AWS credentials..."

    CURRENT_ACCOUNT=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "FAILED")

    if [[ "$CURRENT_ACCOUNT" == "FAILED" ]]; then
        log_error "Failed to verify AWS credentials"
        exit 1
    fi

    if [[ "$CURRENT_ACCOUNT" != "$AWS_ACCOUNT" ]]; then
        log_error "AWS account mismatch: Expected $AWS_ACCOUNT, got $CURRENT_ACCOUNT"
        exit 1
    fi

    log_success "AWS credentials verified"
}

extract_archive() {
    log "Extracting archive locally for validation..."

    mkdir -p "$TEMP_DIR"

    if [[ "$ARCHIVE_TYPE" == "zip" ]]; then
        log "  Extracting zip archive..."
        unzip -q "$FILES_ARCHIVE" -d "$TEMP_DIR" 2>&1 | tee -a "$LOG_FILE" || {
            log_error "Failed to extract zip archive"
            exit 1
        }
    elif [[ "$ARCHIVE_TYPE" == "tar" ]]; then
        log "  Extracting tar.gz archive..."
        tar -xzf "$FILES_ARCHIVE" -C "$TEMP_DIR" 2>&1 | tee -a "$LOG_FILE" || {
            log_error "Failed to extract tar archive"
            exit 1
        }
    fi

    log_success "Archive extracted to: $TEMP_DIR"

    # Find WordPress root directory in extracted files
    if [[ -f "$TEMP_DIR/wp-config.php" ]]; then
        WP_ROOT="$TEMP_DIR"
    elif [[ -d "$TEMP_DIR/public_html" ]] && [[ -f "$TEMP_DIR/public_html/wp-config.php" ]]; then
        WP_ROOT="$TEMP_DIR/public_html"
    else
        # Search for wp-config.php
        WP_CONFIG=$(find "$TEMP_DIR" -name "wp-config.php" -type f | head -n 1)
        if [[ -n "$WP_CONFIG" ]]; then
            WP_ROOT="$(dirname "$WP_CONFIG")"
        else
            log_error "Cannot find WordPress root directory (wp-config.php not found)"
            exit 1
        fi
    fi

    log_success "WordPress root found: $WP_ROOT"
}

validate_wordpress_files() {
    log "Validating WordPress files..."

    REQUIRED_FILES=(
        "wp-config.php"
        "wp-content"
        "wp-admin"
        "wp-includes"
    )

    for item in "${REQUIRED_FILES[@]}"; do
        if [[ -e "$WP_ROOT/$item" ]]; then
            log_success "  Found: $item"
        else
            log_error "  Missing: $item"
            exit 1
        fi
    done

    # Check critical directories
    if [[ -d "$WP_ROOT/wp-content/uploads" ]]; then
        UPLOADS_SIZE=$(du -sh "$WP_ROOT/wp-content/uploads" | cut -f1)
        log "  Uploads directory size: $UPLOADS_SIZE"
    else
        log_warning "  No uploads directory found"
    fi

    if [[ -d "$WP_ROOT/wp-content/themes" ]]; then
        THEMES_COUNT=$(find "$WP_ROOT/wp-content/themes" -mindepth 1 -maxdepth 1 -type d | wc -l)
        log "  Themes found: $THEMES_COUNT"
    fi

    if [[ -d "$WP_ROOT/wp-content/plugins" ]]; then
        PLUGINS_COUNT=$(find "$WP_ROOT/wp-content/plugins" -mindepth 1 -maxdepth 1 -type d | wc -l)
        log "  Plugins found: $PLUGINS_COUNT"
    fi

    log_success "WordPress files validation passed"
}

update_wp_config() {
    log "Preparing wp-config.php for new environment..."

    WP_CONFIG_FILE="$WP_ROOT/wp-config.php"
    WP_CONFIG_BACKUP="$WP_ROOT/wp-config.php.xneelo.bak"

    # Backup original
    cp "$WP_CONFIG_FILE" "$WP_CONFIG_BACKUP"
    log "  Backed up original: wp-config.php.xneelo.bak"

    # Note: Database credentials will be set by tenant provisioning
    # We just need to ensure the file doesn't have hardcoded Xneelo values

    log_warning "  wp-config.php will need database credentials update after upload"
    log_warning "  Database credentials are in Secrets Manager: bbws/${ENVIRONMENT}/${TENANT_ID}/database"

    # Create a note file
    cat > "$WP_ROOT/MIGRATION_README.txt" <<EOF
WordPress Migration for Au Pair Hive
Environment: $ENVIRONMENT
Tenant ID: $TENANT_ID
Target URL: $TARGET_URL
Migration Date: $(date)

IMPORTANT: After uploading files:
1. Update wp-config.php with database credentials from Secrets Manager
2. Regenerate WordPress salts: https://api.wordpress.org/secret-key/1.1/salt/
3. Set file permissions:
   - wp-config.php: 600
   - wp-content: 755
   - wp-content/uploads: 755
4. Test site: $TARGET_URL
5. Login: ${TARGET_URL}/wp-admin

Database credentials location:
AWS Secrets Manager: bbws/${ENVIRONMENT}/${TENANT_ID}/database

Original wp-config.php backed up as: wp-config.php.xneelo.bak
EOF

    log_success "Migration readme created"
}

upload_to_s3() {
    log "Uploading files to S3..."

    # Create a clean archive from extracted WordPress root
    CLEAN_ARCHIVE="$TEMP_DIR/wordpress_files_clean.tar.gz"

    log "  Creating clean archive..."
    tar -czf "$CLEAN_ARCHIVE" -C "$(dirname "$WP_ROOT")" "$(basename "$WP_ROOT")" 2>&1 | tee -a "$LOG_FILE"

    ARCHIVE_SIZE=$(du -h "$CLEAN_ARCHIVE" | cut -f1)
    log "  Archive size: $ARCHIVE_SIZE"

    # Upload to S3
    log "  Uploading to s3://${S3_BUCKET}/${S3_KEY}..."

    aws s3 cp "$CLEAN_ARCHIVE" "s3://${S3_BUCKET}/${S3_KEY}" \
        --storage-class STANDARD \
        2>&1 | tee -a "$LOG_FILE" || {
        log_error "Failed to upload to S3"
        log_warning "You may need to create the S3 bucket first:"
        log_warning "  aws s3 mb s3://${S3_BUCKET}"
        return 1
    }

    log_success "Files uploaded to S3"
    S3_URL="s3://${S3_BUCKET}/${S3_KEY}"
}

deploy_files_via_ecs_task() {
    log "Deploying files to EFS via ECS task..."

    log_warning "Manual step required: Run ECS task to extract files to EFS"
    echo ""
    echo "Instructions:"
    echo "1. Create or use existing ECS task definition with:"
    echo "   - AWS CLI and tar installed"
    echo "   - EFS mount to $EFS_PATH"
    echo ""
    echo "2. Run the task:"
    echo "   aws ecs run-task \\"
    echo "     --cluster $ECS_CLUSTER \\"
    echo "     --task-definition file-deployment-task \\"
    echo "     --launch-type FARGATE \\"
    echo "     --network-configuration \"awsvpcConfiguration={subnets=[subnet-xxx],securityGroups=[sg-xxx]}\""
    echo ""
    echo "3. In the running task container, execute:"
    echo "   # Download from S3"
    echo "   aws s3 cp $S3_URL /tmp/wordpress.tar.gz"
    echo ""
    echo "   # Extract to EFS"
    echo "   cd $EFS_PATH"
    echo "   tar -xzf /tmp/wordpress.tar.gz --strip-components=1"
    echo ""
    echo "   # Set permissions"
    echo "   chmod 600 wp-config.php"
    echo "   chmod 755 wp-content"
    echo "   chmod 755 wp-content/uploads"
    echo "   chown -R www-data:www-data ."
    echo ""
    echo "   # Update wp-config.php with database credentials"
    echo "   # (Get from Secrets Manager: bbws/${ENVIRONMENT}/${TENANT_ID}/database)"
    echo ""
    echo "4. Restart tenant ECS service to pick up new files"
    echo ""
}

cleanup() {
    log "Cleaning up temporary files..."

    if [[ -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
        log_success "Removed temporary extraction directory"
    fi
}

##############################################################################
# Main Script
##############################################################################

main() {
    log "=== Au Pair Hive Files Upload ==="
    log "Started at: $(date)"
    echo ""

    # Validate inputs
    validate_inputs "$@"

    # Configure environment
    set_environment_config

    # Verify AWS credentials
    verify_aws_credentials

    # Extract archive
    extract_archive

    # Validate WordPress files
    validate_wordpress_files

    # Update wp-config.php
    update_wp_config

    # Upload to S3
    if upload_to_s3; then
        # Provide deployment instructions
        deploy_files_via_ecs_task
    else
        log_error "Upload failed - see manual deployment instructions"
    fi

    # Cleanup
    cleanup

    echo ""
    log_success "=== File Upload Process Complete ==="
    log "Log file: $LOG_FILE"
    log ""
    log "Next Steps:"
    log "  1. Deploy files from S3 to EFS (see instructions above)"
    log "  2. Update wp-config.php with database credentials"
    log "  3. Set correct file permissions"
    log "  4. Restart tenant ECS service"
    log "  5. Test site: $TARGET_URL"
    log ""
}

main "$@"
