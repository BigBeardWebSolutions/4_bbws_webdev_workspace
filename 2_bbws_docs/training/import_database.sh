#!/bin/bash

##############################################################################
# Database Import Script for Au Pair Hive Migration
# Purpose: Import WordPress database with URL replacement
# Usage: ./import_database.sh <sql_file> <environment> <tenant_id>
##############################################################################

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="${SCRIPT_DIR}/import_${TIMESTAMP}.log"

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
Usage: $0 <sql_file> <environment> <tenant_id>

Arguments:
    sql_file     - Path to the SQL dump file from Xneelo
    environment  - Target environment (dev, sit, prod)
    tenant_id    - Tenant identifier (e.g., aupairhive)

Examples:
    $0 aupairhive_database_20260109.sql dev aupairhive
    $0 backup.sql sit aupairhive

Environment-Specific Target URLs:
    dev  → https://aupairhive.wpdev.kimmyai.io
    sit  → https://aupairhive.wpsit.kimmyai.io
    prod → https://aupairhive.wp.kimmyai.io

Prerequisites:
    - AWS CLI configured with appropriate profile
    - Tenant already provisioned in target environment
    - SQL file from Xneelo export
    - mysql client installed (or access via ECS task)

EOF
    exit 1
}

validate_inputs() {
    log "Validating inputs..."

    # Check arguments
    if [[ $# -ne 3 ]]; then
        log_error "Invalid number of arguments"
        usage
    fi

    SQL_FILE="$1"
    ENVIRONMENT="$2"
    TENANT_ID="$3"

    # Validate SQL file exists
    if [[ ! -f "$SQL_FILE" ]]; then
        log_error "SQL file not found: $SQL_FILE"
        exit 1
    fi

    # Validate environment
    if [[ ! "$ENVIRONMENT" =~ ^(dev|sit|prod)$ ]]; then
        log_error "Invalid environment: $ENVIRONMENT (must be dev, sit, or prod)"
        exit 1
    fi

    # Validate tenant ID
    if [[ -z "$TENANT_ID" ]]; then
        log_error "Tenant ID cannot be empty"
        exit 1
    fi

    log_success "Input validation passed"
}

set_environment_config() {
    log "Setting environment configuration for: $ENVIRONMENT"

    case "$ENVIRONMENT" in
        dev)
            AWS_PROFILE="Tebogo-dev"
            AWS_ACCOUNT="536580886816"
            AWS_REGION="eu-west-1"
            DOMAIN_SUFFIX="wpdev.kimmyai.io"
            ;;
        sit)
            AWS_PROFILE="Tebogo-sit"
            AWS_ACCOUNT="815856636111"
            AWS_REGION="eu-west-1"
            DOMAIN_SUFFIX="wpsit.kimmyai.io"
            ;;
        prod)
            AWS_PROFILE="Tebogo-prod"
            AWS_ACCOUNT="093646564004"
            AWS_REGION="af-south-1"
            DOMAIN_SUFFIX="wp.kimmyai.io"
            ;;
    esac

    TARGET_URL="https://${TENANT_ID}.${DOMAIN_SUFFIX}"
    DB_NAME="tenant_${TENANT_ID}_db"
    DB_USER="tenant_${TENANT_ID}_user"
    SECRET_NAME="bbws/${ENVIRONMENT}/${TENANT_ID}/database"

    export AWS_PROFILE
    export AWS_DEFAULT_REGION="$AWS_REGION"

    log_success "Environment: $ENVIRONMENT"
    log "  AWS Account: $AWS_ACCOUNT"
    log "  AWS Profile: $AWS_PROFILE"
    log "  AWS Region: $AWS_REGION"
    log "  Target URL: $TARGET_URL"
    log "  Database: $DB_NAME"
}

verify_aws_credentials() {
    log "Verifying AWS credentials..."

    CURRENT_ACCOUNT=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "FAILED")

    if [[ "$CURRENT_ACCOUNT" == "FAILED" ]]; then
        log_error "Failed to get AWS account ID. Check your AWS CLI configuration."
        exit 1
    fi

    if [[ "$CURRENT_ACCOUNT" != "$AWS_ACCOUNT" ]]; then
        log_error "AWS account mismatch!"
        log_error "  Expected: $AWS_ACCOUNT ($ENVIRONMENT)"
        log_error "  Current:  $CURRENT_ACCOUNT"
        log_error "  Please set AWS_PROFILE=$AWS_PROFILE or switch AWS credentials"
        exit 1
    fi

    log_success "AWS credentials verified: $CURRENT_ACCOUNT ($ENVIRONMENT)"
}

get_database_credentials() {
    log "Retrieving database credentials from Secrets Manager..."

    DB_CREDENTIALS=$(aws secretsmanager get-secret-value \
        --secret-id "$SECRET_NAME" \
        --query SecretString \
        --output text 2>/dev/null || echo "FAILED")

    if [[ "$DB_CREDENTIALS" == "FAILED" ]]; then
        log_error "Failed to retrieve database credentials from Secrets Manager"
        log_error "Secret name: $SECRET_NAME"
        exit 1
    fi

    DB_HOST=$(echo "$DB_CREDENTIALS" | jq -r '.host')
    DB_PASSWORD=$(echo "$DB_CREDENTIALS" | jq -r '.password')

    if [[ -z "$DB_HOST" ]] || [[ -z "$DB_PASSWORD" ]]; then
        log_error "Failed to parse database credentials"
        exit 1
    fi

    log_success "Database credentials retrieved"
    log "  Host: $DB_HOST"
    log "  Database: $DB_NAME"
    log "  User: $DB_USER"
}

prepare_sql_file() {
    log "Preparing SQL file with URL replacements..."

    TEMP_SQL="${SCRIPT_DIR}/temp_import_${TIMESTAMP}.sql"

    # Define source URLs (Xneelo)
    SOURCE_URLS=(
        "http://aupairhive.com"
        "https://aupairhive.com"
        "http://www.aupairhive.com"
        "https://www.aupairhive.com"
    )

    log "  Source URLs to replace:"
    for url in "${SOURCE_URLS[@]}"; do
        log "    - $url"
    done
    log "  Target URL: $TARGET_URL"

    # Copy original file
    cp "$SQL_FILE" "$TEMP_SQL"

    # Perform URL replacements using sed
    for source_url in "${SOURCE_URLS[@]}"; do
        # Escape special characters for sed
        source_escaped=$(echo "$source_url" | sed 's/[\/&]/\\&/g')
        target_escaped=$(echo "$TARGET_URL" | sed 's/[\/&]/\\&/g')

        # Replace in SQL file
        sed -i.bak "s|${source_escaped}|${target_escaped}|g" "$TEMP_SQL"

        # Count replacements
        count=$(grep -o "$TARGET_URL" "$TEMP_SQL" | wc -l || echo 0)
        log "    Replaced: $source_url → $TARGET_URL ($count occurrences)"
    done

    # Remove backup file
    rm -f "${TEMP_SQL}.bak"

    # Verify file is valid SQL
    if ! head -n 10 "$TEMP_SQL" | grep -q "MySQL dump\|-- MySQL"; then
        log_warning "File doesn't look like a MySQL dump. Proceeding anyway..."
    fi

    IMPORT_FILE="$TEMP_SQL"
    log_success "SQL file prepared: $IMPORT_FILE"
}

import_database() {
    log "Importing database to $DB_NAME..."

    log_warning "This will REPLACE all data in the database. Continue? (yes/no)"
    read -r confirmation

    if [[ "$confirmation" != "yes" ]]; then
        log_error "Import cancelled by user"
        exit 1
    fi

    # Method 1: Try local mysql client first (if available)
    if command -v mysql &> /dev/null; then
        log "Using local mysql client..."

        # Test connection
        if mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" -e "SELECT 1;" &>/dev/null; then
            log_success "Database connection successful"

            # Import SQL file
            log "Importing SQL file (this may take several minutes)..."

            mysql -h "$DB_HOST" \
                  -u "$DB_USER" \
                  -p"$DB_PASSWORD" \
                  "$DB_NAME" < "$IMPORT_FILE" 2>&1 | tee -a "$LOG_FILE"

            if [[ ${PIPESTATUS[0]} -eq 0 ]]; then
                log_success "Database import completed successfully"
            else
                log_error "Database import failed"
                exit 1
            fi
        else
            log_error "Cannot connect to database from local machine"
            log_warning "You may need to import via ECS task (see Method 2 below)"
            exit 1
        fi
    else
        log_warning "mysql client not found locally"
        log_warning "Manual import required via ECS task"
        echo ""
        echo "To import manually via ECS task:"
        echo "1. Upload SQL file to S3:"
        echo "   aws s3 cp $IMPORT_FILE s3://your-bucket/imports/"
        echo ""
        echo "2. Run ECS task with mysql client:"
        echo "   aws ecs run-task --cluster ${ENVIRONMENT}-cluster \\"
        echo "     --task-definition mysql-client-task \\"
        echo "     --launch-type FARGATE \\"
        echo "     --network-configuration ..."
        echo ""
        echo "3. In the task container:"
        echo "   aws s3 cp s3://your-bucket/imports/$(basename $IMPORT_FILE) /tmp/"
        echo "   mysql -h $DB_HOST -u $DB_USER -p'$DB_PASSWORD' $DB_NAME < /tmp/$(basename $IMPORT_FILE)"
        exit 1
    fi
}

verify_import() {
    log "Verifying database import..."

    if ! command -v mysql &> /dev/null; then
        log_warning "mysql client not available for verification"
        return 0
    fi

    # Check table count
    TABLE_COUNT=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" \
        -sN -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$DB_NAME';" 2>/dev/null || echo 0)

    log "  Tables in database: $TABLE_COUNT"

    if [[ $TABLE_COUNT -lt 10 ]]; then
        log_warning "Expected at least 10 WordPress tables, found $TABLE_COUNT"
    else
        log_success "Table count looks good"
    fi

    # Check for key WordPress tables
    REQUIRED_TABLES=("wp_posts" "wp_users" "wp_options" "wp_postmeta")

    for table in "${REQUIRED_TABLES[@]}"; do
        EXISTS=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" \
            -sN -e "SHOW TABLES LIKE '$table';" 2>/dev/null || echo "")

        if [[ -n "$EXISTS" ]]; then
            ROW_COUNT=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" \
                -sN -e "SELECT COUNT(*) FROM $table;" 2>/dev/null || echo 0)
            log_success "  Table $table exists ($ROW_COUNT rows)"
        else
            log_error "  Table $table is MISSING"
        fi
    done

    # Verify URL replacement
    log "Verifying URL replacements in wp_options..."
    SITE_URL=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" \
        -sN -e "SELECT option_value FROM wp_options WHERE option_name='siteurl';" 2>/dev/null || echo "")
    HOME_URL=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" \
        -sN -e "SELECT option_value FROM wp_options WHERE option_name='home';" 2>/dev/null || echo "")

    log "  siteurl: $SITE_URL"
    log "  home: $HOME_URL"

    if [[ "$SITE_URL" == "$TARGET_URL" ]] && [[ "$HOME_URL" == "$TARGET_URL" ]]; then
        log_success "WordPress URLs updated correctly"
    else
        log_warning "WordPress URLs may need manual update"
        log_warning "  Expected: $TARGET_URL"
        log_warning "  Run: UPDATE wp_options SET option_value='$TARGET_URL' WHERE option_name IN ('siteurl','home');"
    fi
}

cleanup() {
    log "Cleaning up temporary files..."

    if [[ -f "$TEMP_SQL" ]]; then
        rm -f "$TEMP_SQL"
        log_success "Removed temporary SQL file"
    fi
}

##############################################################################
# Main Script
##############################################################################

main() {
    log "=== Au Pair Hive Database Import ==="
    log "Started at: $(date)"
    echo ""

    # Validate and parse inputs
    validate_inputs "$@"

    # Configure environment
    set_environment_config

    # Verify AWS credentials
    verify_aws_credentials

    # Get database credentials
    get_database_credentials

    # Prepare SQL file with URL replacements
    prepare_sql_file

    # Import database
    import_database

    # Verify import
    verify_import

    # Cleanup
    cleanup

    echo ""
    log_success "=== Database Import Complete ==="
    log "Log file: $LOG_FILE"
    log ""
    log "Next Steps:"
    log "  1. Verify WordPress site loads: $TARGET_URL"
    log "  2. Login to wp-admin: ${TARGET_URL}/wp-admin"
    log "  3. Check Settings → General for correct URLs"
    log "  4. Run testing checklist"
    log ""
    log "If site doesn't load, check:"
    log "  - ECS tasks are running"
    log "  - Database credentials in wp-config.php match"
    log "  - File permissions are correct"
}

# Run main function
main "$@"
