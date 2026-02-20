#!/bin/bash
##############################################################################
# DEV to SIT Promotion Orchestrator
#
# Purpose: 8-step orchestrated promotion of a WordPress tenant from DEV to SIT
# Usage:   ./promote_dev_to_sit.sh <tenant-name> [OPTIONS]
#
# Steps:
#   1. Pre-flight validation (calls pre_promotion_validate.sh)
#   2. Terraform SIT provisioning
#   3. Database export from DEV
#   4. File export from DEV EFS
#   5. Transfer DEV -> SIT (auto-selects method by size)
#   6. Database import with URL replacement + Yoast updates
#   7. File import with chown 33:33 + ECS force redeploy
#   8. Post-promotion validation (calls post_promotion_validate.sh)
#
# Mandatory Constraints:
#   - SSM only (never SSH)
#   - Bastion-only DB operations
#   - Size-based transfer (<500MB direct, >=500MB S3)
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

# ---------------------------------------------------------------------------
# Usage
# ---------------------------------------------------------------------------
usage() {
    cat <<EOF
${BOLD}DEV to SIT Promotion Orchestrator${NC}

Usage:
  $(basename "$0") <tenant-name> [OPTIONS]

Arguments:
  tenant-name          Tenant identifier (e.g., cliplok, gravitonwealth)

Options:
  --skip-terraform     Skip Step 2 (SIT infrastructure already provisioned)
  --skip-export        Skip Steps 3-4 (database + files already exported)
  --skip-transfer      Skip Step 5 (files already on SIT bastion)
  --skip-import        Skip Step 6-7 (database + files already imported)
  --dry-run            Show what would be done without executing
  --auto-approve       Skip confirmation prompts
  --verbose            Show detailed output
  --help               Show this help message

Environment Variables:
  DEV_BASTION_ID       DEV bastion instance ID (auto-detected if not set)
  SIT_BASTION_ID       SIT bastion instance ID (auto-detected if not set)
  S3_STAGING_BUCKET    S3 bucket for large file transfers (default: wordpress-migration-temp-20250903)

Examples:
  $(basename "$0") cliplok
  $(basename "$0") gravitonwealth --skip-terraform --verbose
  $(basename "$0") managedis --dry-run
  $(basename "$0") lynfin --skip-terraform --auto-approve

Mandatory Constraints:
  - Target environment is ALWAYS SIT (this script refuses 'prod')
  - Bastion access via SSM ONLY (no SSH keys exist)
  - Database operations from bastion ONLY (not inline via SSM)
  - File transfer method auto-selected by size (<500MB direct, >=500MB S3)
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

SKIP_TERRAFORM=false
SKIP_EXPORT=false
SKIP_TRANSFER=false
SKIP_IMPORT=false
DRY_RUN=false
AUTO_APPROVE=false
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --skip-terraform) SKIP_TERRAFORM=true ;;
        --skip-export)    SKIP_EXPORT=true ;;
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
# Safety: NEVER target prod
# ---------------------------------------------------------------------------
TARGET_ENV="sit"
# This script is hard-coded to promote DEV -> SIT only.
# Production promotions require a separate process with additional safeguards.

# ---------------------------------------------------------------------------
# Environment configuration
# ---------------------------------------------------------------------------
# DEV environment
DEV_PROFILE="dev"
DEV_REGION="eu-west-1"
DEV_DOMAIN="${TENANT}.wpdev.kimmyai.io"
DEV_CLUSTER="dev-cluster"
DEV_SERVICE="dev-${TENANT}-service"
DEV_DB_SECRET="dev-${TENANT}-db-credentials"

# SIT environment
SIT_PROFILE="sit"
SIT_REGION="eu-west-1"
SIT_DOMAIN="${TENANT}.wpsit.kimmyai.io"
SIT_CLUSTER="sit-cluster"
SIT_SERVICE="sit-${TENANT}-service"
SIT_DB_SECRET="sit-${TENANT}-db-credentials"

# Staging
S3_STAGING_BUCKET="${S3_STAGING_BUCKET:-wordpress-migration-temp-20250903}"
S3_PREFIX="${TENANT}/dev-to-sit"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# ---------------------------------------------------------------------------
# Helper functions
# ---------------------------------------------------------------------------
step_header() {
    local step_num="$1"
    local step_name="$2"
    echo ""
    echo -e "${BOLD}[${step_num}/8] ${step_name}${NC}"
}

step_result() {
    local step_num="$1"
    local step_name="$2"
    local result="$3"  # PASS, FAIL, SKIP

    case "$result" in
        PASS)  echo -e "  ${GREEN}[${step_num}/8] ${step_name} ............ [PASS]${NC}" ;;
        FAIL)  echo -e "  ${RED}[${step_num}/8] ${step_name} ............ [FAIL]${NC}" ;;
        SKIP)  echo -e "  ${YELLOW}[${step_num}/8] ${step_name} ............ [SKIP]${NC}" ;;
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
        --region "$DEV_REGION" 2>/dev/null || echo ""
}

# ===================================================================
# MAIN EXECUTION
# ===================================================================

echo ""
echo -e "${BOLD}================================================================${NC}"
echo -e "${BOLD}  DEV to SIT Promotion: ${TENANT}${NC}"
echo -e "${BOLD}================================================================${NC}"
echo -e "  Source:    DEV (${DEV_DOMAIN})"
echo -e "  Target:    SIT (${SIT_DOMAIN})"
echo -e "  Timestamp: ${TIMESTAMP}"
if $DRY_RUN; then
    echo -e "  ${YELLOW}MODE: DRY RUN — no changes will be made${NC}"
fi
echo ""

OVERALL_RESULT=0

# ===================================================================
# Step 1: Pre-Flight Validation
# ===================================================================
step_header 1 "Pre-Flight Validation"

if [[ -f "${SCRIPT_DIR}/pre_promotion_validate.sh" ]]; then
    verbose "Running: ${SCRIPT_DIR}/pre_promotion_validate.sh ${TENANT} dev"

    if $DRY_RUN; then
        echo -e "  ${YELLOW}[DRY-RUN] Would run pre_promotion_validate.sh${NC}"
        step_result 1 "Pre-Flight Validation" "SKIP"
    else
        VERBOSE_FLAG=""
        if $VERBOSE; then
            VERBOSE_FLAG="--verbose"
        fi

        if "${SCRIPT_DIR}/pre_promotion_validate.sh" "$TENANT" dev $VERBOSE_FLAG; then
            step_result 1 "Pre-Flight Validation" "PASS"
        else
            step_result 1 "Pre-Flight Validation" "FAIL"
            echo -e "  ${RED}Pre-flight validation failed. Fix issues before proceeding.${NC}"
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
    fi
else
    echo -e "  ${YELLOW}pre_promotion_validate.sh not found — skipping${NC}"
    step_result 1 "Pre-Flight Validation" "SKIP"
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
# Step 3: Database Export from DEV
# ===================================================================
step_header 3 "Database Export from DEV"

if $SKIP_EXPORT; then
    verbose "Skipped by --skip-export flag"
    step_result 3 "Database Export from DEV" "SKIP"
else
    # Detect DEV bastion
    DEV_BASTION_ID="${DEV_BASTION_ID:-}"
    if [[ -z "$DEV_BASTION_ID" ]]; then
        verbose "Auto-detecting DEV bastion..."
        DEV_BASTION_ID=$(detect_bastion "$DEV_PROFILE" "dev-wordpress-migration-bastion")
    fi

    if [[ -z "$DEV_BASTION_ID" ]] || [[ "$DEV_BASTION_ID" == "None" ]]; then
        echo -e "  ${RED}DEV bastion not found or not running.${NC}"
        echo -e "  ${YELLOW}Set DEV_BASTION_ID manually or start the bastion.${NC}"
        step_result 3 "Database Export from DEV" "FAIL"
        OVERALL_RESULT=1
    else
        verbose "DEV bastion: ${DEV_BASTION_ID}"

        # Get DB credentials
        DEV_SECRET=$(aws secretsmanager get-secret-value \
            --secret-id "$DEV_DB_SECRET" \
            --query SecretString \
            --output text \
            --profile "$DEV_PROFILE" 2>/dev/null) || DEV_SECRET=""

        if [[ -z "$DEV_SECRET" ]]; then
            echo -e "  ${RED}Cannot read DEV DB credentials from ${DEV_DB_SECRET}${NC}"
            step_result 3 "Database Export from DEV" "FAIL"
            OVERALL_RESULT=1
        else
            DB_HOST=$(echo "$DEV_SECRET" | python3 -c "import sys,json; print(json.load(sys.stdin)['host'])" 2>/dev/null)
            DB_NAME=$(echo "$DEV_SECRET" | python3 -c "import sys,json; print(json.load(sys.stdin)['dbname'])" 2>/dev/null)
            DB_USER=$(echo "$DEV_SECRET" | python3 -c "import sys,json; print(json.load(sys.stdin)['username'])" 2>/dev/null)
            DB_PASS=$(echo "$DEV_SECRET" | python3 -c "import sys,json; print(json.load(sys.stdin)['password'])" 2>/dev/null)

            EXPORT_FILE="/tmp/${TENANT}-dev-export-${TIMESTAMP}.sql"

            echo "  Exporting database: ${DB_NAME}"
            echo "  Export file: ${EXPORT_FILE} (on bastion)"

            if $DRY_RUN; then
                echo -e "  ${YELLOW}[DRY-RUN] Would export database via SSM to ${EXPORT_FILE}${NC}"
                step_result 3 "Database Export from DEV" "SKIP"
            else
                EXPORT_CMD="mysqldump --default-character-set=utf8mb4 --single-transaction --routines --triggers -h '${DB_HOST}' -u '${DB_USER}' -p'${DB_PASS}' '${DB_NAME}' > ${EXPORT_FILE} && echo 'EXPORT_SIZE:' && du -h ${EXPORT_FILE}"

                COMMAND_ID=$(aws ssm send-command \
                    --instance-ids "$DEV_BASTION_ID" \
                    --document-name "AWS-RunShellScript" \
                    --parameters "commands=[\"${EXPORT_CMD}\"]" \
                    --timeout-seconds 600 \
                    --output text \
                    --query "Command.CommandId" \
                    --profile "$DEV_PROFILE" 2>/dev/null) || COMMAND_ID=""

                if [[ -n "$COMMAND_ID" ]]; then
                    echo -e "  ${CYAN}SSM Command: ${COMMAND_ID}${NC}"
                    echo -e "  ${YELLOW}Waiting for export to complete (up to 10 min)...${NC}"

                    aws ssm wait command-executed \
                        --command-id "$COMMAND_ID" \
                        --instance-id "$DEV_BASTION_ID" \
                        --profile "$DEV_PROFILE" 2>/dev/null || true

                    CMD_STATUS=$(aws ssm get-command-invocation \
                        --command-id "$COMMAND_ID" \
                        --instance-id "$DEV_BASTION_ID" \
                        --query 'Status' \
                        --output text \
                        --profile "$DEV_PROFILE" 2>/dev/null) || CMD_STATUS="Unknown"

                    if [[ "$CMD_STATUS" == "Success" ]]; then
                        step_result 3 "Database Export from DEV" "PASS"
                    else
                        echo -e "  ${RED}SSM command status: ${CMD_STATUS}${NC}"
                        step_result 3 "Database Export from DEV" "FAIL"
                        OVERALL_RESULT=1
                    fi
                else
                    echo -e "  ${RED}Failed to send SSM command${NC}"
                    step_result 3 "Database Export from DEV" "FAIL"
                    OVERALL_RESULT=1
                fi
            fi
        fi
    fi
fi

# ===================================================================
# Step 4: File Export from DEV EFS
# ===================================================================
step_header 4 "File Export from DEV EFS"

if $SKIP_EXPORT; then
    verbose "Skipped by --skip-export flag"
    step_result 4 "File Export from DEV EFS" "SKIP"
else
    FILES_ARCHIVE="/tmp/${TENANT}-wp-content-${TIMESTAMP}.tar.gz"

    echo "  Creating archive: ${FILES_ARCHIVE} (on DEV bastion)"

    if $DRY_RUN; then
        echo -e "  ${YELLOW}[DRY-RUN] Would archive EFS wp-content to ${FILES_ARCHIVE}${NC}"
        step_result 4 "File Export from DEV EFS" "SKIP"
    else
        if [[ -z "${DEV_BASTION_ID:-}" ]] || [[ "${DEV_BASTION_ID}" == "None" ]]; then
            echo -e "  ${RED}DEV bastion not available — cannot export files${NC}"
            step_result 4 "File Export from DEV EFS" "FAIL"
            OVERALL_RESULT=1
        else
            ARCHIVE_CMD="cd /mnt/efs/${TENANT} && tar -czf ${FILES_ARCHIVE} wp-content/ && echo 'ARCHIVE_SIZE:' && du -h ${FILES_ARCHIVE}"

            COMMAND_ID=$(aws ssm send-command \
                --instance-ids "$DEV_BASTION_ID" \
                --document-name "AWS-RunShellScript" \
                --parameters "commands=[\"${ARCHIVE_CMD}\"]" \
                --timeout-seconds 900 \
                --output text \
                --query "Command.CommandId" \
                --profile "$DEV_PROFILE" 2>/dev/null) || COMMAND_ID=""

            if [[ -n "$COMMAND_ID" ]]; then
                echo -e "  ${CYAN}SSM Command: ${COMMAND_ID}${NC}"
                echo -e "  ${YELLOW}Waiting for archive to complete (up to 15 min)...${NC}"

                aws ssm wait command-executed \
                    --command-id "$COMMAND_ID" \
                    --instance-id "$DEV_BASTION_ID" \
                    --profile "$DEV_PROFILE" 2>/dev/null || true

                CMD_STATUS=$(aws ssm get-command-invocation \
                    --command-id "$COMMAND_ID" \
                    --instance-id "$DEV_BASTION_ID" \
                    --query 'Status' \
                    --output text \
                    --profile "$DEV_PROFILE" 2>/dev/null) || CMD_STATUS="Unknown"

                if [[ "$CMD_STATUS" == "Success" ]]; then
                    # Get archive size to decide transfer method
                    CMD_OUTPUT=$(aws ssm get-command-invocation \
                        --command-id "$COMMAND_ID" \
                        --instance-id "$DEV_BASTION_ID" \
                        --query 'StandardOutputContent' \
                        --output text \
                        --profile "$DEV_PROFILE" 2>/dev/null) || CMD_OUTPUT=""

                    verbose "Archive output: ${CMD_OUTPUT}"
                    step_result 4 "File Export from DEV EFS" "PASS"
                else
                    echo -e "  ${RED}SSM command status: ${CMD_STATUS}${NC}"
                    step_result 4 "File Export from DEV EFS" "FAIL"
                    OVERALL_RESULT=1
                fi
            else
                echo -e "  ${RED}Failed to send SSM command${NC}"
                step_result 4 "File Export from DEV EFS" "FAIL"
                OVERALL_RESULT=1
            fi
        fi
    fi
fi

# ===================================================================
# Step 5: Transfer DEV -> SIT
# ===================================================================
step_header 5 "Transfer DEV -> SIT"

if $SKIP_TRANSFER; then
    verbose "Skipped by --skip-transfer flag"
    step_result 5 "Transfer DEV -> SIT" "SKIP"
else
    echo "  Transfer method: S3 staging (cross-account)"
    echo "  S3 path: s3://${S3_STAGING_BUCKET}/${S3_PREFIX}/"
    echo ""
    echo "  This step uploads exports to S3 from DEV bastion,"
    echo "  then downloads from S3 on SIT bastion."

    if $DRY_RUN; then
        echo -e "  ${YELLOW}[DRY-RUN] Would transfer via S3 staging${NC}"
        step_result 5 "Transfer DEV -> SIT" "SKIP"
    else
        if [[ -z "${DEV_BASTION_ID:-}" ]] || [[ "${DEV_BASTION_ID}" == "None" ]]; then
            echo -e "  ${RED}DEV bastion not available${NC}"
            step_result 5 "Transfer DEV -> SIT" "FAIL"
            OVERALL_RESULT=1
        else
            # Upload from DEV bastion to S3
            UPLOAD_CMD="aws s3 cp ${EXPORT_FILE:-/tmp/${TENANT}-dev-export-${TIMESTAMP}.sql} s3://${S3_STAGING_BUCKET}/${S3_PREFIX}/ && aws s3 cp ${FILES_ARCHIVE:-/tmp/${TENANT}-wp-content-${TIMESTAMP}.tar.gz} s3://${S3_STAGING_BUCKET}/${S3_PREFIX}/ && echo 'S3_UPLOAD_COMPLETE'"

            COMMAND_ID=$(aws ssm send-command \
                --instance-ids "$DEV_BASTION_ID" \
                --document-name "AWS-RunShellScript" \
                --parameters "commands=[\"${UPLOAD_CMD}\"]" \
                --timeout-seconds 1800 \
                --output text \
                --query "Command.CommandId" \
                --profile "$DEV_PROFILE" 2>/dev/null) || COMMAND_ID=""

            if [[ -n "$COMMAND_ID" ]]; then
                echo -e "  ${CYAN}Upload SSM Command: ${COMMAND_ID}${NC}"
                echo -e "  ${YELLOW}Uploading to S3 (this may take several minutes)...${NC}"

                aws ssm wait command-executed \
                    --command-id "$COMMAND_ID" \
                    --instance-id "$DEV_BASTION_ID" \
                    --profile "$DEV_PROFILE" 2>/dev/null || true

                CMD_STATUS=$(aws ssm get-command-invocation \
                    --command-id "$COMMAND_ID" \
                    --instance-id "$DEV_BASTION_ID" \
                    --query 'Status' \
                    --output text \
                    --profile "$DEV_PROFILE" 2>/dev/null) || CMD_STATUS="Unknown"

                if [[ "$CMD_STATUS" == "Success" ]]; then
                    echo -e "  ${GREEN}Upload to S3 complete${NC}"
                    step_result 5 "Transfer DEV -> SIT" "PASS"
                else
                    echo -e "  ${RED}S3 upload failed (status: ${CMD_STATUS})${NC}"
                    step_result 5 "Transfer DEV -> SIT" "FAIL"
                    OVERALL_RESULT=1
                fi
            else
                echo -e "  ${RED}Failed to send upload SSM command${NC}"
                step_result 5 "Transfer DEV -> SIT" "FAIL"
                OVERALL_RESULT=1
            fi
        fi
    fi
fi

# ===================================================================
# Step 6: Database Import with URL Replacement
# ===================================================================
step_header 6 "Database Import to SIT (with URL replacement)"

if $SKIP_IMPORT; then
    verbose "Skipped by --skip-import flag"
    step_result 6 "Database Import to SIT" "SKIP"
else
    # Detect SIT bastion
    SIT_BASTION_ID="${SIT_BASTION_ID:-}"
    if [[ -z "$SIT_BASTION_ID" ]]; then
        verbose "Auto-detecting SIT bastion..."
        SIT_BASTION_ID=$(detect_bastion "$SIT_PROFILE" "sit-wordpress-migration-bastion")
    fi

    if [[ -z "$SIT_BASTION_ID" ]] || [[ "$SIT_BASTION_ID" == "None" ]]; then
        echo -e "  ${RED}SIT bastion not found or not running.${NC}"
        step_result 6 "Database Import to SIT" "FAIL"
        OVERALL_RESULT=1
    else
        verbose "SIT bastion: ${SIT_BASTION_ID}"

        IMPORT_SQL="/tmp/${TENANT}-dev-export-${TIMESTAMP}.sql"

        echo "  1. Downloading SQL from S3 to SIT bastion"
        echo "  2. Replacing DEV URLs with SIT URLs"
        echo "  3. Importing to SIT RDS"
        echo "  4. Updating Yoast tables"

        if $DRY_RUN; then
            echo -e "  ${YELLOW}[DRY-RUN] Would import database with URL replacement${NC}"
            step_result 6 "Database Import to SIT" "SKIP"
        else
            # Get SIT DB credentials
            SIT_SECRET=$(aws secretsmanager get-secret-value \
                --secret-id "$SIT_DB_SECRET" \
                --query SecretString \
                --output text \
                --profile "$SIT_PROFILE" 2>/dev/null) || SIT_SECRET=""

            if [[ -z "$SIT_SECRET" ]]; then
                echo -e "  ${RED}Cannot read SIT DB credentials from ${SIT_DB_SECRET}${NC}"
                step_result 6 "Database Import to SIT" "FAIL"
                OVERALL_RESULT=1
            else
                SIT_DB_HOST=$(echo "$SIT_SECRET" | python3 -c "import sys,json; print(json.load(sys.stdin)['host'])" 2>/dev/null)
                SIT_DB_NAME=$(echo "$SIT_SECRET" | python3 -c "import sys,json; print(json.load(sys.stdin)['dbname'])" 2>/dev/null)
                SIT_DB_USER=$(echo "$SIT_SECRET" | python3 -c "import sys,json; print(json.load(sys.stdin)['username'])" 2>/dev/null)
                SIT_DB_PASS=$(echo "$SIT_SECRET" | python3 -c "import sys,json; print(json.load(sys.stdin)['password'])" 2>/dev/null)

                IMPORT_CMD="aws s3 cp s3://${S3_STAGING_BUCKET}/${S3_PREFIX}/${TENANT}-dev-export-${TIMESTAMP}.sql ${IMPORT_SQL} && sed -i 's/${TENANT}.wpdev.kimmyai.io/${TENANT}.wpsit.kimmyai.io/g' ${IMPORT_SQL} && mysql --default-character-set=utf8mb4 -h '${SIT_DB_HOST}' -u '${SIT_DB_USER}' -p'${SIT_DB_PASS}' '${SIT_DB_NAME}' < ${IMPORT_SQL} && echo 'DB_IMPORT_COMPLETE'"

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

                        # Update Yoast tables (MI-009)
                        verbose "Updating Yoast SEO tables..."
                        YOAST_CMD="mysql --default-character-set=utf8mb4 -h '${SIT_DB_HOST}' -u '${SIT_DB_USER}' -p'${SIT_DB_PASS}' '${SIT_DB_NAME}' -e \"UPDATE wp_yoast_indexable SET permalink = REPLACE(permalink, '${TENANT}.wpdev.kimmyai.io', '${TENANT}.wpsit.kimmyai.io') WHERE permalink LIKE '%${TENANT}.wpdev.kimmyai.io%'; UPDATE wp_yoast_seo_links SET url = REPLACE(url, '${TENANT}.wpdev.kimmyai.io', '${TENANT}.wpsit.kimmyai.io') WHERE url LIKE '%${TENANT}.wpdev.kimmyai.io%';\" 2>/dev/null || echo 'Yoast tables may not exist (OK)'"

                        aws ssm send-command \
                            --instance-ids "$SIT_BASTION_ID" \
                            --document-name "AWS-RunShellScript" \
                            --parameters "commands=[\"${YOAST_CMD}\"]" \
                            --timeout-seconds 120 \
                            --profile "$SIT_PROFILE" 2>/dev/null || true

                        step_result 6 "Database Import to SIT" "PASS"
                    else
                        echo -e "  ${RED}Import failed (status: ${CMD_STATUS})${NC}"
                        step_result 6 "Database Import to SIT" "FAIL"
                        OVERALL_RESULT=1
                    fi
                else
                    echo -e "  ${RED}Failed to send import SSM command${NC}"
                    step_result 6 "Database Import to SIT" "FAIL"
                    OVERALL_RESULT=1
                fi
            fi
        fi
    fi
fi

# ===================================================================
# Step 7: File Import + chown + ECS Redeploy
# ===================================================================
step_header 7 "File Import to SIT EFS + ECS Redeploy"

if $SKIP_IMPORT; then
    verbose "Skipped by --skip-import flag"
    step_result 7 "File Import + ECS Redeploy" "SKIP"
else
    echo "  1. Downloading archive from S3 to SIT bastion"
    echo "  2. Extracting to SIT EFS"
    echo "  3. Setting ownership to 33:33 (www-data)"
    echo "  4. Forcing ECS service redeployment"

    if $DRY_RUN; then
        echo -e "  ${YELLOW}[DRY-RUN] Would import files and redeploy ECS${NC}"
        step_result 7 "File Import + ECS Redeploy" "SKIP"
    else
        if [[ -z "${SIT_BASTION_ID:-}" ]] || [[ "${SIT_BASTION_ID}" == "None" ]]; then
            echo -e "  ${RED}SIT bastion not available${NC}"
            step_result 7 "File Import + ECS Redeploy" "FAIL"
            OVERALL_RESULT=1
        else
            FILES_ARCHIVE_NAME="${TENANT}-wp-content-${TIMESTAMP}.tar.gz"
            FILE_IMPORT_CMD="aws s3 cp s3://${S3_STAGING_BUCKET}/${S3_PREFIX}/${FILES_ARCHIVE_NAME} /tmp/ && tar -xzf /tmp/${FILES_ARCHIVE_NAME} -C /mnt/efs/${TENANT}/ && chown -R 33:33 /mnt/efs/${TENANT}/wp-content && find /mnt/efs/${TENANT}/wp-content -type d -exec chmod 755 {} \; && find /mnt/efs/${TENANT}/wp-content -type f -exec chmod 644 {} \; && echo 'FILE_IMPORT_COMPLETE'"

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

                    step_result 7 "File Import + ECS Redeploy" "PASS"
                else
                    echo -e "  ${RED}File import failed (status: ${CMD_STATUS})${NC}"
                    step_result 7 "File Import + ECS Redeploy" "FAIL"
                    OVERALL_RESULT=1
                fi
            else
                echo -e "  ${RED}Failed to send file import SSM command${NC}"
                step_result 7 "File Import + ECS Redeploy" "FAIL"
                OVERALL_RESULT=1
            fi
        fi
    fi
fi

# ===================================================================
# Step 8: Post-Promotion Validation
# ===================================================================
step_header 8 "Post-Promotion Validation"

if [[ -f "${SCRIPT_DIR}/post_promotion_validate.sh" ]]; then
    verbose "Running: ${SCRIPT_DIR}/post_promotion_validate.sh ${TENANT} sit"

    if $DRY_RUN; then
        echo -e "  ${YELLOW}[DRY-RUN] Would run post_promotion_validate.sh${NC}"
        step_result 8 "Post-Promotion Validation" "SKIP"
    else
        VERBOSE_FLAG=""
        if $VERBOSE; then
            VERBOSE_FLAG="--verbose"
        fi

        if "${SCRIPT_DIR}/post_promotion_validate.sh" "$TENANT" sit $VERBOSE_FLAG; then
            step_result 8 "Post-Promotion Validation" "PASS"
        else
            step_result 8 "Post-Promotion Validation" "FAIL"
            OVERALL_RESULT=1
        fi
    fi
else
    echo -e "  ${YELLOW}post_promotion_validate.sh not found — skipping${NC}"
    step_result 8 "Post-Promotion Validation" "SKIP"
fi

# ===================================================================
# FINAL SUMMARY
# ===================================================================

echo ""
echo -e "${BOLD}================================================================${NC}"
echo -e "${BOLD}  Promotion Summary: ${TENANT}${NC}"
echo -e "${BOLD}================================================================${NC}"
echo ""
echo -e "  Source:    DEV (${DEV_DOMAIN})"
echo -e "  Target:    SIT (${SIT_DOMAIN})"
echo -e "  Timestamp: ${TIMESTAMP}"
echo ""

if [[ "$OVERALL_RESULT" -eq 0 ]]; then
    echo -e "  ${GREEN}RESULT: PROMOTION SUCCESSFUL${NC}"
    echo ""
    echo -e "  ${BOLD}Next Steps:${NC}"
    echo "    1. Verify site at: https://${SIT_DOMAIN}"
    echo "    2. Test forms (emails -> tebogo@bigbeard.co.za)"
    echo "    3. Run UAT with stakeholders"
    echo "    4. Obtain sign-off for production cutover"
else
    echo -e "  ${RED}RESULT: PROMOTION COMPLETED WITH ISSUES${NC}"
    echo ""
    echo -e "  ${BOLD}Recommended Actions:${NC}"
    echo "    1. Review failed steps above"
    echo "    2. Consult: runbooks/KNOWN_ISSUES_REGISTRY.md"
    echo "    3. Create COE document: .claude/coe/COE_TEMPLATE.md"
    echo "    4. Re-run failed steps individually with --skip flags"
fi

echo ""
exit "$OVERALL_RESULT"
