#!/bin/bash
##############################################################################
# Quick Promote Script (Warm Tenant)
#
# Purpose: Quickly promote a DEV tenant to an existing warm SIT tenant
# Usage:   ./quick_promote.sh <tenant-name> [OPTIONS]
#
# Steps:
#   1. Validate warm tenant exists and is healthy
#   2. Export data from DEV (DB dump + EFS tar.gz, upload to S3)
#   3. Import to SIT (download, URL replacement, DB import, file extract)
#   4. Force ECS redeploy + post-promotion validation
#
# Prerequisites:
#   - Warm tenant already provisioned via warm_tenant_provision.sh
#   - DEV and SIT bastions running
#   - S3 staging bucket accessible from both accounts
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
# Parent migrations scripts directory (for post_promotion_validate.sh)
MIGRATIONS_SCRIPT_DIR="$(cd "${SCRIPT_DIR}/../../scripts" && pwd)"

# ---------------------------------------------------------------------------
# Usage
# ---------------------------------------------------------------------------
usage() {
    cat <<EOF
${BOLD}Quick Promote (Warm Tenant)${NC}

Usage:
  $(basename "$0") <tenant-name> [OPTIONS]

Arguments:
  tenant-name          Tenant identifier (e.g., cliplok, lynfin)

Options:
  --skip-export        Skip Step 2 (DB + files already exported to S3)
  --skip-import        Skip Step 3 (data already imported)
  --dry-run            Show what would be done without executing
  --auto-approve       Skip confirmation prompts
  --verbose            Show detailed output
  --help               Show this help message

Environment Variables:
  DEV_BASTION_ID       DEV bastion instance ID (auto-detected if not set)
  SIT_BASTION_ID       SIT bastion instance ID (auto-detected if not set)
  S3_STAGING_BUCKET    S3 bucket for transfers (default: wordpress-migration-temp-20250903)

Examples:
  $(basename "$0") cliplok
  $(basename "$0") lynfin --skip-export --verbose
  $(basename "$0") managedis --dry-run
  $(basename "$0") gravitonwealth --auto-approve
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

SKIP_EXPORT=false
SKIP_IMPORT=false
DRY_RUN=false
AUTO_APPROVE=false
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --skip-export)   SKIP_EXPORT=true ;;
        --skip-import)   SKIP_IMPORT=true ;;
        --dry-run)       DRY_RUN=true ;;
        --auto-approve)  AUTO_APPROVE=true ;;
        --verbose)       VERBOSE=true ;;
        --help)          usage ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            usage
            ;;
    esac
    shift
done

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
    echo -e "${BOLD}[${step_num}/4] ${step_name}${NC}"
}

step_result() {
    local step_num="$1"
    local step_name="$2"
    local result="$3"

    case "$result" in
        PASS)  echo -e "  ${GREEN}[${step_num}/4] ${step_name} ............ [PASS]${NC}" ;;
        FAIL)  echo -e "  ${RED}[${step_num}/4] ${step_name} ............ [FAIL]${NC}" ;;
        SKIP)  echo -e "  ${YELLOW}[${step_num}/4] ${step_name} ............ [SKIP]${NC}" ;;
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
echo -e "${BOLD}  Quick Promote (Warm Tenant): ${TENANT}${NC}"
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
# Step 1: Validate Warm Tenant
# ===================================================================
step_header 1 "Validate Warm Tenant"

VALIDATE_SCRIPT="${SCRIPT_DIR}/validate_warm_tenant.sh"

if [[ -f "$VALIDATE_SCRIPT" ]]; then
    if $DRY_RUN; then
        echo -e "  ${YELLOW}[DRY-RUN] Would run validate_warm_tenant.sh${NC}"
        step_result 1 "Validate Warm Tenant" "SKIP"
    else
        VERBOSE_FLAG=""
        if $VERBOSE; then
            VERBOSE_FLAG="--verbose"
        fi

        if "$VALIDATE_SCRIPT" "$TENANT" $VERBOSE_FLAG; then
            step_result 1 "Validate Warm Tenant" "PASS"
        else
            step_result 1 "Validate Warm Tenant" "FAIL"
            echo -e "  ${RED}Warm tenant not ready. Provision first:${NC}"
            echo -e "  ${RED}  ./scripts/warm_tenant_provision.sh ${TENANT} --alb-priority <num>${NC}"
            if ! $AUTO_APPROVE; then
                echo -e "  ${YELLOW}Continue anyway? [y/N]${NC} "
                read -r REPLY
                if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
                    exit 1
                fi
            fi
            OVERALL_RESULT=1
        fi
    fi
else
    echo -e "  ${YELLOW}validate_warm_tenant.sh not found — skipping validation${NC}"
    step_result 1 "Validate Warm Tenant" "SKIP"
fi

# ===================================================================
# Step 2: Export Data from DEV
# ===================================================================
step_header 2 "Export Data from DEV"

if $SKIP_EXPORT; then
    verbose "Skipped by --skip-export flag"
    step_result 2 "Export Data from DEV" "SKIP"
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
        step_result 2 "Export Data from DEV" "FAIL"
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
            step_result 2 "Export Data from DEV" "FAIL"
            OVERALL_RESULT=1
        else
            DB_HOST=$(echo "$DEV_SECRET" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('host', d.get('host','')))" 2>/dev/null)
            DB_NAME=$(echo "$DEV_SECRET" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('database', d.get('dbname','')))" 2>/dev/null)
            DB_USER=$(echo "$DEV_SECRET" | python3 -c "import sys,json; print(json.load(sys.stdin)['username'])" 2>/dev/null)
            DB_PASS=$(echo "$DEV_SECRET" | python3 -c "import sys,json; print(json.load(sys.stdin)['password'])" 2>/dev/null)

            EXPORT_FILE="/tmp/${TENANT}-dev-export-${TIMESTAMP}.sql"
            FILES_ARCHIVE="/tmp/${TENANT}-wp-content-${TIMESTAMP}.tar.gz"

            if $DRY_RUN; then
                echo -e "  ${YELLOW}[DRY-RUN] Would export DB and files from DEV, upload to S3${NC}"
                step_result 2 "Export Data from DEV" "SKIP"
            else
                echo "  Exporting database: ${DB_NAME}"
                echo "  Archiving files:    /mnt/efs/${TENANT}/wp-content/"
                echo "  Upload to:          s3://${S3_STAGING_BUCKET}/${S3_PREFIX}/"

                # Combined: DB export + file archive + S3 upload
                EXPORT_CMD="mysqldump --default-character-set=utf8mb4 --single-transaction --routines --triggers -h '${DB_HOST}' -u '${DB_USER}' -p'${DB_PASS}' '${DB_NAME}' > ${EXPORT_FILE} && echo 'DB_EXPORT_OK' && cd /mnt/efs/${TENANT} && tar -czf ${FILES_ARCHIVE} wp-content/ && echo 'FILE_ARCHIVE_OK' && aws s3 cp ${EXPORT_FILE} s3://${S3_STAGING_BUCKET}/${S3_PREFIX}/ && aws s3 cp ${FILES_ARCHIVE} s3://${S3_STAGING_BUCKET}/${S3_PREFIX}/ && echo 'S3_UPLOAD_OK'"

                COMMAND_ID=$(aws ssm send-command \
                    --instance-ids "$DEV_BASTION_ID" \
                    --document-name "AWS-RunShellScript" \
                    --parameters "commands=[\"${EXPORT_CMD}\"]" \
                    --timeout-seconds 1800 \
                    --output text \
                    --query "Command.CommandId" \
                    --profile "$DEV_PROFILE" 2>/dev/null) || COMMAND_ID=""

                if [[ -n "$COMMAND_ID" ]]; then
                    echo -e "  ${CYAN}SSM Command: ${COMMAND_ID}${NC}"
                    echo -e "  ${YELLOW}Exporting and uploading (this may take several minutes)...${NC}"

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
                        echo -e "  ${GREEN}DEV data exported and uploaded to S3${NC}"
                        step_result 2 "Export Data from DEV" "PASS"
                    else
                        echo -e "  ${RED}Export failed (status: ${CMD_STATUS})${NC}"
                        CMD_ERR=$(aws ssm get-command-invocation \
                            --command-id "$COMMAND_ID" \
                            --instance-id "$DEV_BASTION_ID" \
                            --query 'StandardErrorContent' \
                            --output text \
                            --profile "$DEV_PROFILE" 2>/dev/null) || CMD_ERR=""
                        verbose "Error: ${CMD_ERR}"
                        step_result 2 "Export Data from DEV" "FAIL"
                        OVERALL_RESULT=1
                    fi
                else
                    echo -e "  ${RED}Failed to send SSM command${NC}"
                    step_result 2 "Export Data from DEV" "FAIL"
                    OVERALL_RESULT=1
                fi
            fi
        fi
    fi
fi

# ===================================================================
# Step 3: Import Data to SIT
# ===================================================================
step_header 3 "Import Data to SIT"

if $SKIP_IMPORT; then
    verbose "Skipped by --skip-import flag"
    step_result 3 "Import Data to SIT" "SKIP"
else
    # Detect SIT bastion
    SIT_BASTION_ID="${SIT_BASTION_ID:-}"
    if [[ -z "$SIT_BASTION_ID" ]]; then
        verbose "Auto-detecting SIT bastion..."
        SIT_BASTION_ID=$(detect_bastion "$SIT_PROFILE" "sit-wordpress-migration-bastion")
    fi

    if [[ -z "$SIT_BASTION_ID" ]] || [[ "$SIT_BASTION_ID" == "None" ]]; then
        echo -e "  ${RED}SIT bastion not found or not running.${NC}"
        step_result 3 "Import Data to SIT" "FAIL"
        OVERALL_RESULT=1
    else
        verbose "SIT bastion: ${SIT_BASTION_ID}"

        if $DRY_RUN; then
            echo -e "  ${YELLOW}[DRY-RUN] Would download from S3, replace URLs, import DB + files${NC}"
            step_result 3 "Import Data to SIT" "SKIP"
        else
            # Get SIT DB credentials
            SIT_SECRET=$(aws secretsmanager get-secret-value \
                --secret-id "$SIT_DB_SECRET" \
                --query SecretString \
                --output text \
                --profile "$SIT_PROFILE" 2>/dev/null) || SIT_SECRET=""

            if [[ -z "$SIT_SECRET" ]]; then
                echo -e "  ${RED}Cannot read SIT DB credentials from ${SIT_DB_SECRET}${NC}"
                step_result 3 "Import Data to SIT" "FAIL"
                OVERALL_RESULT=1
            else
                SIT_DB_HOST=$(echo "$SIT_SECRET" | python3 -c "import sys,json; print(json.load(sys.stdin)['host'])" 2>/dev/null)
                SIT_DB_NAME=$(echo "$SIT_SECRET" | python3 -c "import sys,json; print(json.load(sys.stdin)['database'])" 2>/dev/null)
                SIT_DB_USER=$(echo "$SIT_SECRET" | python3 -c "import sys,json; print(json.load(sys.stdin)['username'])" 2>/dev/null)
                SIT_DB_PASS=$(echo "$SIT_SECRET" | python3 -c "import sys,json; print(json.load(sys.stdin)['password'])" 2>/dev/null)

                IMPORT_SQL="/tmp/${TENANT}-dev-export-${TIMESTAMP}.sql"
                FILES_ARCHIVE_NAME="${TENANT}-wp-content-${TIMESTAMP}.tar.gz"

                echo "  1. Downloading from S3 to SIT bastion"
                echo "  2. Replacing DEV URLs (wpdev → wpsit)"
                echo "  3. Importing database"
                echo "  4. Extracting files to EFS"
                echo "  5. Updating Yoast tables"

                # Combined: download + URL replace + DB import + file extract + Yoast update
                IMPORT_CMD="aws s3 cp s3://${S3_STAGING_BUCKET}/${S3_PREFIX}/${TENANT}-dev-export-${TIMESTAMP}.sql ${IMPORT_SQL} && aws s3 cp s3://${S3_STAGING_BUCKET}/${S3_PREFIX}/${FILES_ARCHIVE_NAME} /tmp/ && sed -i 's/${TENANT}.wpdev.kimmyai.io/${TENANT}.wpsit.kimmyai.io/g' ${IMPORT_SQL} && mysql --default-character-set=utf8mb4 -h '${SIT_DB_HOST}' -u '${SIT_DB_USER}' -p'${SIT_DB_PASS}' '${SIT_DB_NAME}' < ${IMPORT_SQL} && echo 'DB_IMPORT_OK' && tar -xzf /tmp/${FILES_ARCHIVE_NAME} -C /mnt/efs/${TENANT}/ && chown -R 33:33 /mnt/efs/${TENANT}/wp-content && find /mnt/efs/${TENANT}/wp-content -type d -exec chmod 755 {} \; && find /mnt/efs/${TENANT}/wp-content -type f -exec chmod 644 {} \; && echo 'FILE_IMPORT_OK'"

                COMMAND_ID=$(aws ssm send-command \
                    --instance-ids "$SIT_BASTION_ID" \
                    --document-name "AWS-RunShellScript" \
                    --parameters "commands=[\"${IMPORT_CMD}\"]" \
                    --timeout-seconds 1800 \
                    --output text \
                    --query "Command.CommandId" \
                    --profile "$SIT_PROFILE" 2>/dev/null) || COMMAND_ID=""

                if [[ -n "$COMMAND_ID" ]]; then
                    echo -e "  ${CYAN}SSM Command: ${COMMAND_ID}${NC}"
                    echo -e "  ${YELLOW}Importing data (this may take several minutes)...${NC}"

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
                        echo -e "  ${GREEN}Data imported with URL replacement${NC}"

                        # Update Yoast tables
                        verbose "Updating Yoast SEO tables..."
                        YOAST_CMD="mysql --default-character-set=utf8mb4 -h '${SIT_DB_HOST}' -u '${SIT_DB_USER}' -p'${SIT_DB_PASS}' '${SIT_DB_NAME}' -e \"UPDATE wp_yoast_indexable SET permalink = REPLACE(permalink, '${TENANT}.wpdev.kimmyai.io', '${TENANT}.wpsit.kimmyai.io') WHERE permalink LIKE '%${TENANT}.wpdev.kimmyai.io%'; UPDATE wp_yoast_seo_links SET url = REPLACE(url, '${TENANT}.wpdev.kimmyai.io', '${TENANT}.wpsit.kimmyai.io') WHERE url LIKE '%${TENANT}.wpdev.kimmyai.io%';\" 2>/dev/null || echo 'Yoast tables may not exist (OK)'"

                        aws ssm send-command \
                            --instance-ids "$SIT_BASTION_ID" \
                            --document-name "AWS-RunShellScript" \
                            --parameters "commands=[\"${YOAST_CMD}\"]" \
                            --timeout-seconds 120 \
                            --profile "$SIT_PROFILE" 2>/dev/null || true

                        step_result 3 "Import Data to SIT" "PASS"
                    else
                        echo -e "  ${RED}Import failed (status: ${CMD_STATUS})${NC}"
                        CMD_ERR=$(aws ssm get-command-invocation \
                            --command-id "$COMMAND_ID" \
                            --instance-id "$SIT_BASTION_ID" \
                            --query 'StandardErrorContent' \
                            --output text \
                            --profile "$SIT_PROFILE" 2>/dev/null) || CMD_ERR=""
                        verbose "Error: ${CMD_ERR}"
                        step_result 3 "Import Data to SIT" "FAIL"
                        OVERALL_RESULT=1
                    fi
                else
                    echo -e "  ${RED}Failed to send SSM command${NC}"
                    step_result 3 "Import Data to SIT" "FAIL"
                    OVERALL_RESULT=1
                fi
            fi
        fi
    fi
fi

# ===================================================================
# Step 4: ECS Redeploy + Post-Promotion Validation
# ===================================================================
step_header 4 "ECS Redeploy + Validation"

if $DRY_RUN; then
    echo -e "  ${YELLOW}[DRY-RUN] Would force ECS redeploy and run post-promotion validation${NC}"
    step_result 4 "ECS Redeploy + Validation" "SKIP"
else
    # Force ECS redeployment
    echo "  Forcing ECS service redeployment..."
    aws ecs update-service \
        --cluster "$SIT_CLUSTER" \
        --service "$SIT_SERVICE" \
        --force-new-deployment \
        --profile "$SIT_PROFILE" \
        --region "$SIT_REGION" >/dev/null 2>&1 || true

    echo -e "  ${GREEN}ECS redeployment triggered${NC}"
    echo -e "  ${YELLOW}Waiting 60 seconds for deployment to stabilize...${NC}"
    sleep 60

    # Run post-promotion validation
    POST_VALIDATE="${MIGRATIONS_SCRIPT_DIR}/post_promotion_validate.sh"
    if [[ -f "$POST_VALIDATE" ]]; then
        VERBOSE_FLAG=""
        if $VERBOSE; then
            VERBOSE_FLAG="--verbose"
        fi

        if "$POST_VALIDATE" "$TENANT" sit $VERBOSE_FLAG; then
            step_result 4 "ECS Redeploy + Validation" "PASS"
        else
            step_result 4 "ECS Redeploy + Validation" "FAIL"
            OVERALL_RESULT=1
        fi
    else
        echo -e "  ${YELLOW}post_promotion_validate.sh not found at ${POST_VALIDATE}${NC}"
        echo -e "  ${YELLOW}Skipping post-promotion validation${NC}"
        step_result 4 "ECS Redeploy + Validation" "SKIP"
    fi
fi

# ===================================================================
# FINAL SUMMARY
# ===================================================================

echo ""
echo -e "${BOLD}================================================================${NC}"
echo -e "${BOLD}  Quick Promote Summary: ${TENANT}${NC}"
echo -e "${BOLD}================================================================${NC}"
echo ""
echo -e "  Source:    DEV (${DEV_DOMAIN})"
echo -e "  Target:    SIT (${SIT_DOMAIN})"
echo -e "  Timestamp: ${TIMESTAMP}"
echo ""

if [[ "$OVERALL_RESULT" -eq 0 ]]; then
    echo -e "  ${GREEN}RESULT: QUICK PROMOTION SUCCESSFUL${NC}"
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
    echo "    2. Re-run with --skip flags for completed steps"
    echo "    3. Check: ./scripts/validate_warm_tenant.sh ${TENANT} --verbose"
fi

echo ""
exit "$OVERALL_RESULT"
