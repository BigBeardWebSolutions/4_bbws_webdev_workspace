#!/bin/bash
##############################################################################
# Direct-to-SIT Migration Orchestrator
#
# Purpose: 7-step orchestrated migration of a WordPress tenant directly
#          from local files (Xneelo export) to SIT environment.
#          Unlike promote_dev_to_sit.sh, this does NOT require a running
#          DEV environment — it takes local SQL + raw wp-content dir as input.
#
# Usage:   ./migrate_to_sit.sh <tenant-name> --sql-file <path>
#              --wp-content-dir <path> --source-domain <domain> [OPTIONS]
#
# Steps:
#   1. Validate local files (SQL + wp-content directory)
#   2. Terraform SIT provisioning (manual, with guidance)
#   3. Prepare database (deactivate problematic plugins)
#   4. Package & upload to S3 (tar.gz wp-content, upload both to S3)
#   5. Database import with URL replacement + Yoast updates
#   6. File import with chown 33:33 + ECS force redeploy
#   7. Post-promotion validation (calls post_promotion_validate.sh)
#
# Mandatory Constraints:
#   - SSM only (never SSH)
#   - Bastion-only DB operations
#   - Size-based transfer recommendation (<500MB direct, >=500MB S3)
#   - Refuses 'prod' as target
##############################################################################

set -uo pipefail

# ---------------------------------------------------------------------------
# Colors & formatting
# ---------------------------------------------------------------------------
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ---------------------------------------------------------------------------
# Script location
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"

# ---------------------------------------------------------------------------
# Usage
# ---------------------------------------------------------------------------
usage() {
    cat <<EOF
${BOLD}Direct-to-SIT Migration Orchestrator${NC}

Migrates a WordPress tenant directly from local files (e.g., Xneelo export)
to the SIT environment, bypassing DEV entirely.

Usage:
  $(basename "$0") <tenant-name> --sql-file <path> --wp-content-dir <path> --source-domain <domain> [OPTIONS]

Arguments:
  tenant-name              Tenant identifier (e.g., caseforward, jeanique)

Required Flags:
  --sql-file <path>        Path to WordPress database SQL dump (local file)
  --wp-content-dir <path>  Path to raw wp-content/ directory (from Xneelo export)
  --source-domain <domain> Original source domain for URL replacement
                           (e.g., cliplok.co.za, jeanique.co.za)

Options:
  --skip-terraform         Skip Step 2 (SIT infrastructure already provisioned)
  --skip-prepare           Skip Step 3 (SQL already preprocessed)
  --skip-transfer          Skip Step 4 (files already on S3/bastion)
  --skip-import            Skip Steps 5-6 (database + files already imported)
  --dry-run                Show what would be done without executing
  --auto-approve           Skip confirmation prompts
  --verbose                Show detailed output
  --help                   Show this help message

Environment Variables:
  SIT_BASTION_ID           SIT bastion instance ID (auto-detected if not set)
  S3_STAGING_BUCKET        S3 bucket for staging (default: wordpress-migration-temp-20250903)

Examples:
  # Biocurcumin — small site, raw Xneelo export
  $(basename "$0") biocurcumin \\
    --sql-file "/path/to/biocurcumin/dedi232_cpt3_host-h_net (1).sql" \\
    --wp-content-dir /path/to/biocurcumin/wp-content \\
    --source-domain biocurcumin.co.za \\
    --verbose

  # CaseForward — from migration folder structure
  $(basename "$0") caseforward \\
    --sql-file ./CaseForward/database/wordpress-db-fixed.sql \\
    --wp-content-dir ./CaseForward/site/wp-content \\
    --source-domain caseforward.org

  # Jeanique — skip terraform if already provisioned
  $(basename "$0") jeanique \\
    --sql-file ./Jeanique/database/wordpress-db-fixed.sql \\
    --wp-content-dir ./Jeanique/site/wp-content \\
    --source-domain jeanique.co.za \\
    --skip-terraform --verbose

  # NorthPineBaptist — skip prepare if DB already fixed
  $(basename "$0") northpinebaptist \\
    --sql-file ./NorthPineBaptist/database/wordpress-db-fixed.sql \\
    --wp-content-dir ./NorthPineBaptist/site/wp-content \\
    --source-domain northpinebaptist.co.za \\
    --skip-prepare --auto-approve

Mandatory Constraints:
  - Target environment is ALWAYS SIT (this script refuses 'prod')
  - Bastion access via SSM ONLY (no SSH keys exist)
  - Database operations from bastion ONLY
  - Source domain is used for URL replacement (not a DEV domain)
  - prepare-wordpress-for-migration.sh requires PHP
  - wp-content-dir must be a raw directory (script handles tar.gz creation)
EOF
    exit 0
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
if [[ $# -lt 1 ]] || [[ "$1" == "--help" ]]; then
    usage
fi

TENANT="$1"
shift

SQL_FILE=""
WP_CONTENT_DIR=""
SOURCE_DOMAIN=""
SKIP_TERRAFORM=false
SKIP_PREPARE=false
SKIP_TRANSFER=false
SKIP_IMPORT=false
DRY_RUN=false
AUTO_APPROVE=false
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --sql-file)
            SQL_FILE="$2"
            shift
            ;;
        --wp-content-dir)
            WP_CONTENT_DIR="$2"
            shift
            ;;
        --source-domain)
            SOURCE_DOMAIN="$2"
            shift
            ;;
        --skip-terraform) SKIP_TERRAFORM=true ;;
        --skip-prepare)   SKIP_PREPARE=true ;;
        --skip-transfer)  SKIP_TRANSFER=true ;;
        --skip-import)    SKIP_IMPORT=true ;;
        --dry-run)        DRY_RUN=true ;;
        --auto-approve)   AUTO_APPROVE=true ;;
        --verbose)        VERBOSE=true ;;
        --help)           usage ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            usage
            ;;
    esac
    shift
done

# ---------------------------------------------------------------------------
# Validate required flags
# ---------------------------------------------------------------------------
MISSING_FLAGS=()
if [[ -z "$SQL_FILE" ]]; then
    MISSING_FLAGS+=("--sql-file")
fi
if [[ -z "$WP_CONTENT_DIR" ]]; then
    MISSING_FLAGS+=("--wp-content-dir")
fi
if [[ -z "$SOURCE_DOMAIN" ]]; then
    MISSING_FLAGS+=("--source-domain")
fi

if [[ ${#MISSING_FLAGS[@]} -gt 0 ]]; then
    echo -e "${RED}Error: Missing required flag(s): ${MISSING_FLAGS[*]}${NC}"
    echo ""
    echo "Usage: $(basename "$0") <tenant-name> --sql-file <path> --wp-content-dir <path> --source-domain <domain>"
    echo ""
    echo "Run with --help for full usage information."
    exit 1
fi

# ---------------------------------------------------------------------------
# Safety: NEVER target prod
# ---------------------------------------------------------------------------
TARGET_ENV="sit"
# This script is hard-coded to migrate directly to SIT only.
# Production migrations require a separate process with additional safeguards.

# ---------------------------------------------------------------------------
# Environment configuration — SIT only (no DEV needed)
# ---------------------------------------------------------------------------
SIT_PROFILE="sit"
SIT_REGION="eu-west-1"
SIT_DOMAIN="${TENANT}.wpsit.kimmyai.io"
SIT_CLUSTER="sit-cluster"
SIT_SERVICE="sit-${TENANT}-service"
SIT_DB_SECRET="sit-${TENANT}-db-credentials"

# Staging
S3_STAGING_BUCKET="${S3_STAGING_BUCKET:-wordpress-migration-temp-20250903}"
S3_PREFIX="${TENANT}/xneelo-to-sit"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Prepare script location
PREPARE_SCRIPT="${REPO_ROOT}/0_utilities/file_transfer/prepare-wordpress-for-migration.sh"

# ---------------------------------------------------------------------------
# Helper functions
# ---------------------------------------------------------------------------
TOTAL_STEPS=7

step_header() {
    local step_num="$1"
    local step_name="$2"
    echo ""
    echo -e "${BOLD}[${step_num}/${TOTAL_STEPS}] ${step_name}${NC}"
}

step_result() {
    local step_num="$1"
    local step_name="$2"
    local result="$3"  # PASS, FAIL, SKIP

    case "$result" in
        PASS)  echo -e "  ${GREEN}[${step_num}/${TOTAL_STEPS}] ${step_name} ............ [PASS]${NC}" ;;
        FAIL)  echo -e "  ${RED}[${step_num}/${TOTAL_STEPS}] ${step_name} ............ [FAIL]${NC}" ;;
        SKIP)  echo -e "  ${YELLOW}[${step_num}/${TOTAL_STEPS}] ${step_name} ............ [SKIP]${NC}" ;;
    esac
}

confirm() {
    if $AUTO_APPROVE; then
        return 0
    fi
    if $DRY_RUN; then
        echo -e "  ${YELLOW}[DRY-RUN] Would proceed here${NC}"
        return 1
    fi
    echo -e "  ${YELLOW}Proceed? [y/N]${NC} "
    read -r REPLY
    [[ "$REPLY" =~ ^[Yy]$ ]]
}

verbose() {
    if $VERBOSE; then
        echo -e "  ${CYAN}[INFO]${NC} $1"
    fi
}

detect_bastion() {
    local profile="$1"
    local tag="$2"
    aws ec2 describe-instances \
        --filters "Name=tag:Name,Values=${tag}" "Name=instance-state-name,Values=running" \
        --query 'Reservations[0].Instances[0].InstanceId' \
        --output text \
        --profile "$profile" \
        --region "$SIT_REGION" 2>/dev/null || echo ""
}

# ===================================================================
# MAIN EXECUTION
# ===================================================================

echo ""
echo -e "${BOLD}================================================================${NC}"
echo -e "${BOLD}  Direct-to-SIT Migration: ${TENANT}${NC}"
echo -e "${BOLD}================================================================${NC}"
echo -e "  Source:       Local files (${SOURCE_DOMAIN})"
echo -e "  Target:       SIT (${SIT_DOMAIN})"
echo -e "  SQL file:     ${SQL_FILE}"
echo -e "  wp-content:   ${WP_CONTENT_DIR}"
echo -e "  Timestamp:    ${TIMESTAMP}"
if $DRY_RUN; then
    echo -e "  ${YELLOW}MODE: DRY RUN — no changes will be made${NC}"
fi
echo ""

OVERALL_RESULT=0

# ===================================================================
# Step 1: Validate Local Files
# ===================================================================
step_header 1 "Validate Local Files"

STEP1_PASS=true

# Check SQL file
if [[ ! -f "$SQL_FILE" ]]; then
    echo -e "  ${RED}SQL file not found: ${SQL_FILE}${NC}"
    STEP1_PASS=false
elif [[ ! -r "$SQL_FILE" ]]; then
    echo -e "  ${RED}SQL file not readable: ${SQL_FILE}${NC}"
    STEP1_PASS=false
else
    SQL_SIZE=$(ls -lh "$SQL_FILE" | awk '{print $5}')
    SQL_SIZE_BYTES=$(wc -c < "$SQL_FILE" | tr -d ' ')
    echo -e "  ${GREEN}SQL file:${NC} ${SQL_FILE} (${SQL_SIZE})"
    verbose "SQL file size: ${SQL_SIZE_BYTES} bytes"

    # Basic SQL validation
    if head -50 "$SQL_FILE" | grep -qi "mysql\|MariaDB\|CREATE TABLE\|INSERT INTO\|DROP TABLE\|SQL_MODE\|phpMyAdmin"; then
        verbose "SQL file appears to contain valid MySQL statements"
    else
        echo -e "  ${YELLOW}WARNING: SQL file may not contain MySQL statements${NC}"
    fi
fi

# Check wp-content directory
if [[ ! -d "$WP_CONTENT_DIR" ]]; then
    echo -e "  ${RED}wp-content directory not found: ${WP_CONTENT_DIR}${NC}"
    STEP1_PASS=false
elif [[ ! -r "$WP_CONTENT_DIR" ]]; then
    echo -e "  ${RED}wp-content directory not readable: ${WP_CONTENT_DIR}${NC}"
    STEP1_PASS=false
else
    DIR_SIZE=$(du -sh "$WP_CONTENT_DIR" 2>/dev/null | awk '{print $1}')
    DIR_SIZE_BYTES=$(find "$WP_CONTENT_DIR" -type f -exec stat -f%z {} + 2>/dev/null | awk '{s+=$1} END {print s+0}' || echo "0")
    echo -e "  ${GREEN}wp-content:${NC} ${WP_CONTENT_DIR} (${DIR_SIZE})"
    verbose "wp-content size: ${DIR_SIZE_BYTES} bytes"

    # Check for expected subdirectories
    if [[ -d "${WP_CONTENT_DIR}/themes" ]]; then
        verbose "Found themes/ directory"
    else
        echo -e "  ${YELLOW}WARNING: No themes/ subdirectory found in wp-content${NC}"
    fi
    if [[ -d "${WP_CONTENT_DIR}/plugins" ]]; then
        verbose "Found plugins/ directory"
    else
        echo -e "  ${YELLOW}WARNING: No plugins/ subdirectory found in wp-content${NC}"
    fi
fi

# Size-based transfer recommendation
if $STEP1_PASS; then
    TOTAL_SIZE_BYTES=$(( ${SQL_SIZE_BYTES:-0} + ${DIR_SIZE_BYTES:-0} ))
    TOTAL_SIZE_MB=$(( TOTAL_SIZE_BYTES / 1048576 ))

    if [[ "$TOTAL_SIZE_MB" -lt 500 ]]; then
        echo -e "  ${GREEN}Total size: ~${TOTAL_SIZE_MB}MB — direct bastion transfer possible${NC}"
        verbose "Under 500MB threshold: SSM port forwarding recommended as alternative"
    else
        echo -e "  ${YELLOW}Total size: ~${TOTAL_SIZE_MB}MB — S3 staging recommended${NC}"
        verbose "Over 500MB threshold: S3 upload from local machine is the best approach"
    fi
fi

# Check prepare script
if [[ ! -f "$PREPARE_SCRIPT" ]] && ! $SKIP_PREPARE; then
    echo -e "  ${YELLOW}WARNING: prepare-wordpress-for-migration.sh not found at:${NC}"
    echo -e "  ${YELLOW}  ${PREPARE_SCRIPT}${NC}"
    echo -e "  ${YELLOW}  Use --skip-prepare if SQL is already preprocessed${NC}"
fi

if $STEP1_PASS; then
    step_result 1 "Validate Local Files" "PASS"
else
    step_result 1 "Validate Local Files" "FAIL"
    echo -e "  ${RED}Fix file issues before proceeding.${NC}"
    if ! $AUTO_APPROVE; then
        echo -e "  ${YELLOW}Continue anyway? This is NOT recommended. [y/N]${NC} "
        read -r REPLY
        if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        echo -e "  ${RED}Auto-approve enabled — continuing despite failures.${NC}"
    fi
    OVERALL_RESULT=1
fi

# ===================================================================
# Step 2: Terraform SIT Provisioning
# ===================================================================
step_header 2 "Terraform SIT Provisioning"

if $SKIP_TERRAFORM; then
    verbose "Skipped by --skip-terraform flag"
    step_result 2 "Terraform SIT Provisioning" "SKIP"
else
    echo "  Terraform provisioning for SIT tenant: ${TENANT}"
    echo ""
    echo "  Run the following commands manually:"
    echo ""
    echo "    cd 2_bbws_ecs_terraform/tenant"
    echo "    terraform init -backend-config=environments/sit/backend.hcl"
    echo "    terraform plan \\"
    echo "      -var-file=environments/sit/terraform.tfvars \\"
    echo "      -var=\"tenant_name=${TENANT}\" \\"
    echo "      -out=sit-${TENANT}.plan"
    echo "    terraform apply sit-${TENANT}.plan"
    echo ""

    if $DRY_RUN; then
        step_result 2 "Terraform SIT Provisioning" "SKIP"
    else
        if confirm; then
            echo -e "  ${YELLOW}Waiting for Terraform to complete...${NC}"
            echo -e "  ${YELLOW}Press Enter when Terraform apply is done.${NC}"
            read -r
            step_result 2 "Terraform SIT Provisioning" "PASS"
        else
            step_result 2 "Terraform SIT Provisioning" "SKIP"
        fi
    fi
fi

# ===================================================================
# Step 3: Prepare Database
# ===================================================================
step_header 3 "Prepare Database (Deactivate Problematic Plugins)"

if $SKIP_PREPARE; then
    verbose "Skipped by --skip-prepare flag"
    PREPARED_SQL="$SQL_FILE"
    step_result 3 "Prepare Database" "SKIP"
else
    PREPARED_SQL="/tmp/${TENANT}-fixed-${TIMESTAMP}.sql"

    echo "  Running: prepare-wordpress-for-migration.sh"
    echo "  Input:   ${SQL_FILE}"
    echo "  Output:  ${PREPARED_SQL}"
    echo ""

    if $DRY_RUN; then
        echo -e "  ${YELLOW}[DRY-RUN] Would run prepare-wordpress-for-migration.sh${NC}"
        PREPARED_SQL="$SQL_FILE"
        step_result 3 "Prepare Database" "SKIP"
    else
        if [[ -f "$PREPARE_SCRIPT" ]]; then
            verbose "Running: ${PREPARE_SCRIPT} ${SQL_FILE} ${PREPARED_SQL}"

            if "$PREPARE_SCRIPT" "$SQL_FILE" "$PREPARED_SQL"; then
                if [[ -f "$PREPARED_SQL" ]]; then
                    PREPARED_SIZE=$(ls -lh "$PREPARED_SQL" | awk '{print $5}')
                    echo -e "  ${GREEN}Prepared SQL: ${PREPARED_SQL} (${PREPARED_SIZE})${NC}"
                    step_result 3 "Prepare Database" "PASS"
                else
                    echo -e "  ${RED}Prepare script ran but output file not found${NC}"
                    PREPARED_SQL="$SQL_FILE"
                    step_result 3 "Prepare Database" "FAIL"
                    OVERALL_RESULT=1
                fi
            else
                echo -e "  ${RED}prepare-wordpress-for-migration.sh failed${NC}"
                echo -e "  ${YELLOW}Falling back to original SQL file${NC}"
                PREPARED_SQL="$SQL_FILE"
                step_result 3 "Prepare Database" "FAIL"
                OVERALL_RESULT=1
            fi
        else
            echo -e "  ${RED}prepare-wordpress-for-migration.sh not found at:${NC}"
            echo -e "  ${RED}  ${PREPARE_SCRIPT}${NC}"
            echo -e "  ${YELLOW}Using original SQL file (plugins NOT deactivated)${NC}"
            PREPARED_SQL="$SQL_FILE"
            step_result 3 "Prepare Database" "FAIL"
            OVERALL_RESULT=1
        fi
    fi
fi

# ===================================================================
# Step 4: Package & Upload to S3
# ===================================================================
step_header 4 "Package wp-content & Upload to S3"

# Archive filename used by Steps 4 and 6
ARCHIVE_FILENAME="${TENANT}-wp-content-${TIMESTAMP}.tar.gz"

if $SKIP_TRANSFER; then
    verbose "Skipped by --skip-transfer flag"
    step_result 4 "Package & Upload to S3" "SKIP"
else
    SQL_FILENAME=$(basename "$PREPARED_SQL")

    echo "  S3 path: s3://${S3_STAGING_BUCKET}/${S3_PREFIX}/"
    echo ""
    echo "  Step 4a: Create tar.gz from ${WP_CONTENT_DIR}"
    echo "  Step 4b: Upload SQL + archive to S3"
    echo ""

    if $DRY_RUN; then
        echo -e "  ${YELLOW}[DRY-RUN] Would package wp-content and upload to S3${NC}"
        step_result 4 "Package & Upload to S3" "SKIP"
    else
        UPLOAD_OK=true

        # 4a: Create tar.gz from raw wp-content directory
        WP_CONTENT_PARENT=$(dirname "$WP_CONTENT_DIR")
        WP_CONTENT_BASENAME=$(basename "$WP_CONTENT_DIR")
        ARCHIVE_PATH="/tmp/${ARCHIVE_FILENAME}"

        echo -e "  ${CYAN}Packaging wp-content into ${ARCHIVE_FILENAME}...${NC}"
        if tar -czf "$ARCHIVE_PATH" -C "$WP_CONTENT_PARENT" "$WP_CONTENT_BASENAME"; then
            ARCHIVE_SIZE=$(ls -lh "$ARCHIVE_PATH" | awk '{print $5}')
            echo -e "  ${GREEN}Archive created: ${ARCHIVE_PATH} (${ARCHIVE_SIZE})${NC}"
        else
            echo -e "  ${RED}Failed to create tar.gz from wp-content directory${NC}"
            UPLOAD_OK=false
        fi

        # 4b: Upload to S3
        if $UPLOAD_OK; then
            echo -e "  ${CYAN}Uploading SQL file...${NC}"
            if aws s3 cp "$PREPARED_SQL" "s3://${S3_STAGING_BUCKET}/${S3_PREFIX}/${SQL_FILENAME}" \
                --profile "$SIT_PROFILE" 2>&1; then
                echo -e "  ${GREEN}SQL uploaded${NC}"
            else
                echo -e "  ${RED}SQL upload failed${NC}"
                UPLOAD_OK=false
            fi
        fi

        if $UPLOAD_OK; then
            echo -e "  ${CYAN}Uploading wp-content archive...${NC}"
            if aws s3 cp "$ARCHIVE_PATH" "s3://${S3_STAGING_BUCKET}/${S3_PREFIX}/${ARCHIVE_FILENAME}" \
                --profile "$SIT_PROFILE" 2>&1; then
                echo -e "  ${GREEN}Archive uploaded${NC}"
            else
                echo -e "  ${RED}Archive upload failed${NC}"
                UPLOAD_OK=false
            fi
        fi

        if $UPLOAD_OK; then
            verbose "Verifying S3 uploads..."
            aws s3 ls "s3://${S3_STAGING_BUCKET}/${S3_PREFIX}/" --profile "$SIT_PROFILE" 2>/dev/null || true
            step_result 4 "Package & Upload to S3" "PASS"
        else
            step_result 4 "Package & Upload to S3" "FAIL"
            OVERALL_RESULT=1
        fi
    fi
fi

# ===================================================================
# Step 5: Database Import with URL Replacement
# ===================================================================
step_header 5 "Database Import to SIT (with URL replacement)"

if $SKIP_IMPORT; then
    verbose "Skipped by --skip-import flag"
    step_result 5 "Database Import to SIT" "SKIP"
else
    # Detect SIT bastion
    SIT_BASTION_ID="${SIT_BASTION_ID:-}"
    if [[ -z "$SIT_BASTION_ID" ]]; then
        verbose "Auto-detecting SIT bastion..."
        SIT_BASTION_ID=$(detect_bastion "$SIT_PROFILE" "sit-wordpress-migration-bastion")
    fi

    if [[ -z "$SIT_BASTION_ID" ]] || [[ "$SIT_BASTION_ID" == "None" ]]; then
        echo -e "  ${RED}SIT bastion not found or not running.${NC}"
        echo -e "  ${YELLOW}Set SIT_BASTION_ID manually or start the bastion.${NC}"
        step_result 5 "Database Import to SIT" "FAIL"
        OVERALL_RESULT=1
    else
        verbose "SIT bastion: ${SIT_BASTION_ID}"

        SQL_FILENAME=$(basename "$PREPARED_SQL")
        IMPORT_SQL="/tmp/${SQL_FILENAME}"

        echo "  1. Downloading SQL from S3 to SIT bastion"
        echo "  2. Replacing source URLs: ${SOURCE_DOMAIN} → ${SIT_DOMAIN}"
        echo "  3. Importing to SIT RDS"
        echo "  4. Updating Yoast tables"

        if $DRY_RUN; then
            echo -e "  ${YELLOW}[DRY-RUN] Would import database with URL replacement${NC}"
            step_result 5 "Database Import to SIT" "SKIP"
        else
            # Get SIT DB credentials
            SIT_SECRET=$(aws secretsmanager get-secret-value \
                --secret-id "$SIT_DB_SECRET" \
                --query SecretString \
                --output text \
                --profile "$SIT_PROFILE" 2>/dev/null) || SIT_SECRET=""

            if [[ -z "$SIT_SECRET" ]]; then
                echo -e "  ${RED}Cannot read SIT DB credentials from ${SIT_DB_SECRET}${NC}"
                step_result 5 "Database Import to SIT" "FAIL"
                OVERALL_RESULT=1
            else
                SIT_DB_HOST=$(echo "$SIT_SECRET" | python3 -c "import sys,json; print(json.load(sys.stdin)['host'])" 2>/dev/null)
                SIT_DB_NAME=$(echo "$SIT_SECRET" | python3 -c "import sys,json; print(json.load(sys.stdin)['dbname'])" 2>/dev/null)
                SIT_DB_USER=$(echo "$SIT_SECRET" | python3 -c "import sys,json; print(json.load(sys.stdin)['username'])" 2>/dev/null)
                SIT_DB_PASS=$(echo "$SIT_SECRET" | python3 -c "import sys,json; print(json.load(sys.stdin)['password'])" 2>/dev/null)

                # Escape dots in source domain for sed
                SOURCE_DOMAIN_ESCAPED=$(echo "$SOURCE_DOMAIN" | sed 's/\./\\./g')

                IMPORT_CMD="aws s3 cp s3://${S3_STAGING_BUCKET}/${S3_PREFIX}/${SQL_FILENAME} ${IMPORT_SQL} && sed -i 's/${SOURCE_DOMAIN_ESCAPED}/${TENANT}.wpsit.kimmyai.io/g' ${IMPORT_SQL} && mysql --default-character-set=utf8mb4 -h '${SIT_DB_HOST}' -u '${SIT_DB_USER}' -p'${SIT_DB_PASS}' '${SIT_DB_NAME}' < ${IMPORT_SQL} && echo 'DB_IMPORT_COMPLETE'"

                COMMAND_ID=$(aws ssm send-command \
                    --instance-ids "$SIT_BASTION_ID" \
                    --document-name "AWS-RunShellScript" \
                    --parameters "commands=[\"${IMPORT_CMD}\"]" \
                    --timeout-seconds 900 \
                    --output text \
                    --query "Command.CommandId" \
                    --profile "$SIT_PROFILE" 2>/dev/null) || COMMAND_ID=""

                if [[ -n "$COMMAND_ID" ]]; then
                    echo -e "  ${CYAN}Import SSM Command: ${COMMAND_ID}${NC}"
                    echo -e "  ${YELLOW}Importing database (up to 15 min)...${NC}"

                    aws ssm wait command-executed \
                        --command-id "$COMMAND_ID" \
                        --instance-id "$SIT_BASTION_ID" \
                        --profile "$SIT_PROFILE" 2>/dev/null || true

                    CMD_STATUS=$(aws ssm get-command-invocation \
                        --command-id "$COMMAND_ID" \
                        --instance-id "$SIT_BASTION_ID" \
                        --query 'Status' \
                        --output text \
                        --profile "$SIT_PROFILE" 2>/dev/null) || CMD_STATUS="Unknown"

                    if [[ "$CMD_STATUS" == "Success" ]]; then
                        echo -e "  ${GREEN}Database imported with URL replacement${NC}"
                        echo -e "  ${GREEN}  ${SOURCE_DOMAIN} → ${SIT_DOMAIN}${NC}"

                        # Update Yoast tables
                        verbose "Updating Yoast SEO tables..."
                        YOAST_CMD="mysql --default-character-set=utf8mb4 -h '${SIT_DB_HOST}' -u '${SIT_DB_USER}' -p'${SIT_DB_PASS}' '${SIT_DB_NAME}' -e \"UPDATE wp_yoast_indexable SET permalink = REPLACE(permalink, '${SOURCE_DOMAIN}', '${TENANT}.wpsit.kimmyai.io') WHERE permalink LIKE '%${SOURCE_DOMAIN}%'; UPDATE wp_yoast_seo_links SET url = REPLACE(url, '${SOURCE_DOMAIN}', '${TENANT}.wpsit.kimmyai.io') WHERE url LIKE '%${SOURCE_DOMAIN}%';\" 2>/dev/null || echo 'Yoast tables may not exist (OK)'"

                        aws ssm send-command \
                            --instance-ids "$SIT_BASTION_ID" \
                            --document-name "AWS-RunShellScript" \
                            --parameters "commands=[\"${YOAST_CMD}\"]" \
                            --timeout-seconds 120 \
                            --profile "$SIT_PROFILE" 2>/dev/null || true

                        step_result 5 "Database Import to SIT" "PASS"
                    else
                        echo -e "  ${RED}Import failed (status: ${CMD_STATUS})${NC}"

                        # Try to get error output
                        CMD_OUTPUT=$(aws ssm get-command-invocation \
                            --command-id "$COMMAND_ID" \
                            --instance-id "$SIT_BASTION_ID" \
                            --query 'StandardErrorContent' \
                            --output text \
                            --profile "$SIT_PROFILE" 2>/dev/null) || CMD_OUTPUT=""

                        if [[ -n "$CMD_OUTPUT" ]] && [[ "$CMD_OUTPUT" != "None" ]]; then
                            verbose "Error output: ${CMD_OUTPUT}"
                        fi

                        step_result 5 "Database Import to SIT" "FAIL"
                        OVERALL_RESULT=1
                    fi
                else
                    echo -e "  ${RED}Failed to send import SSM command${NC}"
                    step_result 5 "Database Import to SIT" "FAIL"
                    OVERALL_RESULT=1
                fi
            fi
        fi
    fi
fi

# ===================================================================
# Step 6: File Import + chown + ECS Redeploy
# ===================================================================
step_header 6 "File Import to SIT EFS + ECS Redeploy"

if $SKIP_IMPORT; then
    verbose "Skipped by --skip-import flag"
    step_result 6 "File Import + ECS Redeploy" "SKIP"
else
    echo "  1. Downloading archive from S3 to SIT bastion"
    echo "  2. Extracting to SIT EFS"
    echo "  3. Setting ownership to 33:33 (www-data)"
    echo "  4. Forcing ECS service redeployment"

    if $DRY_RUN; then
        echo -e "  ${YELLOW}[DRY-RUN] Would import files and redeploy ECS${NC}"
        step_result 6 "File Import + ECS Redeploy" "SKIP"
    else
        if [[ -z "${SIT_BASTION_ID:-}" ]] || [[ "${SIT_BASTION_ID}" == "None" ]]; then
            echo -e "  ${RED}SIT bastion not available${NC}"
            step_result 6 "File Import + ECS Redeploy" "FAIL"
            OVERALL_RESULT=1
        else
            # Archive contains wp-content/ at top level (created from parent dir)
            FILE_IMPORT_CMD="aws s3 cp s3://${S3_STAGING_BUCKET}/${S3_PREFIX}/${ARCHIVE_FILENAME} /tmp/ && mkdir -p /mnt/efs/${TENANT} && tar -xzf /tmp/${ARCHIVE_FILENAME} -C /mnt/efs/${TENANT}/ && chown -R 33:33 /mnt/efs/${TENANT}/wp-content && find /mnt/efs/${TENANT}/wp-content -type d -exec chmod 755 {} \; && find /mnt/efs/${TENANT}/wp-content -type f -exec chmod 644 {} \; && echo 'FILE_IMPORT_COMPLETE'"

            COMMAND_ID=$(aws ssm send-command \
                --instance-ids "$SIT_BASTION_ID" \
                --document-name "AWS-RunShellScript" \
                --parameters "commands=[\"${FILE_IMPORT_CMD}\"]" \
                --timeout-seconds 1800 \
                --output text \
                --query "Command.CommandId" \
                --profile "$SIT_PROFILE" 2>/dev/null) || COMMAND_ID=""

            if [[ -n "$COMMAND_ID" ]]; then
                echo -e "  ${CYAN}File import SSM Command: ${COMMAND_ID}${NC}"
                echo -e "  ${YELLOW}Importing files (this may take several minutes)...${NC}"

                aws ssm wait command-executed \
                    --command-id "$COMMAND_ID" \
                    --instance-id "$SIT_BASTION_ID" \
                    --profile "$SIT_PROFILE" 2>/dev/null || true

                CMD_STATUS=$(aws ssm get-command-invocation \
                    --command-id "$COMMAND_ID" \
                    --instance-id "$SIT_BASTION_ID" \
                    --query 'Status' \
                    --output text \
                    --profile "$SIT_PROFILE" 2>/dev/null) || CMD_STATUS="Unknown"

                if [[ "$CMD_STATUS" == "Success" ]]; then
                    echo -e "  ${GREEN}Files imported with correct permissions${NC}"

                    # Force ECS redeployment
                    verbose "Forcing ECS service redeployment..."
                    aws ecs update-service \
                        --cluster "$SIT_CLUSTER" \
                        --service "$SIT_SERVICE" \
                        --force-new-deployment \
                        --profile "$SIT_PROFILE" \
                        --region "$SIT_REGION" >/dev/null 2>&1 || true

                    echo -e "  ${GREEN}ECS redeployment triggered${NC}"
                    echo -e "  ${YELLOW}Waiting 60 seconds for deployment to stabilize...${NC}"
                    sleep 60

                    step_result 6 "File Import + ECS Redeploy" "PASS"
                else
                    echo -e "  ${RED}File import failed (status: ${CMD_STATUS})${NC}"

                    CMD_OUTPUT=$(aws ssm get-command-invocation \
                        --command-id "$COMMAND_ID" \
                        --instance-id "$SIT_BASTION_ID" \
                        --query 'StandardErrorContent' \
                        --output text \
                        --profile "$SIT_PROFILE" 2>/dev/null) || CMD_OUTPUT=""

                    if [[ -n "$CMD_OUTPUT" ]] && [[ "$CMD_OUTPUT" != "None" ]]; then
                        verbose "Error output: ${CMD_OUTPUT}"
                    fi

                    step_result 6 "File Import + ECS Redeploy" "FAIL"
                    OVERALL_RESULT=1
                fi
            else
                echo -e "  ${RED}Failed to send file import SSM command${NC}"
                step_result 6 "File Import + ECS Redeploy" "FAIL"
                OVERALL_RESULT=1
            fi
        fi
    fi
fi

# ===================================================================
# Step 7: Post-Migration Validation
# ===================================================================
step_header 7 "Post-Migration Validation"

if [[ -f "${SCRIPT_DIR}/post_promotion_validate.sh" ]]; then
    verbose "Running: ${SCRIPT_DIR}/post_promotion_validate.sh ${TENANT} sit --source-domain ${SOURCE_DOMAIN}"

    if $DRY_RUN; then
        echo -e "  ${YELLOW}[DRY-RUN] Would run post_promotion_validate.sh${NC}"
        step_result 7 "Post-Migration Validation" "SKIP"
    else
        VERBOSE_FLAG=""
        if $VERBOSE; then
            VERBOSE_FLAG="--verbose"
        fi

        if "${SCRIPT_DIR}/post_promotion_validate.sh" "$TENANT" sit --source-domain "$SOURCE_DOMAIN" $VERBOSE_FLAG; then
            step_result 7 "Post-Migration Validation" "PASS"
        else
            step_result 7 "Post-Migration Validation" "FAIL"
            OVERALL_RESULT=1
        fi
    fi
else
    echo -e "  ${YELLOW}post_promotion_validate.sh not found — skipping${NC}"
    step_result 7 "Post-Migration Validation" "SKIP"
fi

# ===================================================================
# FINAL SUMMARY
# ===================================================================

echo ""
echo -e "${BOLD}================================================================${NC}"
echo -e "${BOLD}  Migration Summary: ${TENANT}${NC}"
echo -e "${BOLD}================================================================${NC}"
echo ""
echo -e "  Source:       Local files (${SOURCE_DOMAIN})"
echo -e "  Target:       SIT (${SIT_DOMAIN})"
echo -e "  SQL file:     ${SQL_FILE}"
echo -e "  wp-content:   ${WP_CONTENT_DIR}"
echo -e "  S3 prefix:    s3://${S3_STAGING_BUCKET}/${S3_PREFIX}/"
echo -e "  Timestamp:    ${TIMESTAMP}"
echo ""

if [[ "$OVERALL_RESULT" -eq 0 ]]; then
    echo -e "  ${GREEN}RESULT: MIGRATION SUCCESSFUL${NC}"
    echo ""
    echo -e "  ${BOLD}Next Steps:${NC}"
    echo "    1. Verify site at: https://${SIT_DOMAIN}"
    echo "    2. Test forms (emails -> tebogo@bigbeard.co.za)"
    echo "    3. Check wp-admin login at: https://${SIT_DOMAIN}/wp-admin"
    echo "    4. Run UAT with stakeholders"
    echo "    5. Obtain sign-off for production cutover"
else
    echo -e "  ${RED}RESULT: MIGRATION COMPLETED WITH ISSUES${NC}"
    echo ""
    echo -e "  ${BOLD}Recommended Actions:${NC}"
    echo "    1. Review failed steps above"
    echo "    2. Consult: runbooks/KNOWN_ISSUES_REGISTRY.md"
    echo "    3. Create COE document: .claude/coe/COE_TEMPLATE.md"
    echo "    4. Re-run failed steps individually with --skip flags"
    echo ""
    echo -e "  ${BOLD}Skip Flags for Re-running:${NC}"
    echo "    --skip-terraform  (Step 2 already done)"
    echo "    --skip-prepare    (Step 3 already done)"
    echo "    --skip-transfer   (Step 4 already done)"
    echo "    --skip-import     (Steps 5-6 already done)"
fi

echo ""
exit "$OVERALL_RESULT"
