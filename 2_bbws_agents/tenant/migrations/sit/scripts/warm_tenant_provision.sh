#!/bin/bash
##############################################################################
# Warm Tenant Provisioning Script
#
# Purpose: Pre-provision SIT infrastructure for a tenant before promotion
# Usage:   ./warm_tenant_provision.sh <tenant-name> --alb-priority <num> [OPTIONS]
#
# Steps:
#   1. Generate sit_{tenant}.tf from warm_tenant_template.tf.tpl
#   2. Terraform init + plan + apply (SIT backend)
#   3. Initialize database on SIT RDS via SSM bastion
#   4. Validate warm tenant state
#
# Mandatory Constraints:
#   - SSM only (never SSH)
#   - Bastion-only DB operations
#   - Target is ALWAYS SIT
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
TEMPLATE_DIR="${SCRIPT_DIR}/../terraform"
# Terraform root — relative to the migrations/sit folder
TERRAFORM_DIR="$(cd "${SCRIPT_DIR}/../../../../2_bbws_ecs_terraform/terraform" && pwd)"

# ---------------------------------------------------------------------------
# Usage
# ---------------------------------------------------------------------------
usage() {
    cat <<EOF
${BOLD}Warm Tenant Provisioning${NC}

Usage:
  $(basename "$0") <tenant-name> --alb-priority <num> [OPTIONS]

Arguments:
  tenant-name          Tenant identifier (e.g., cliplok, lynfin)

Required Options:
  --alb-priority <num> ALB listener rule priority (must be unique, e.g., 150)

Options:
  --dry-run            Show what would be done without executing
  --auto-approve       Skip confirmation prompts
  --verbose            Show detailed output
  --help               Show this help message

Environment Variables:
  SIT_BASTION_ID       SIT bastion instance ID (auto-detected if not set)

Examples:
  $(basename "$0") cliplok --alb-priority 150
  $(basename "$0") lynfin --alb-priority 160 --dry-run
  $(basename "$0") managedis --alb-priority 170 --auto-approve --verbose
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

ALB_PRIORITY=""
DRY_RUN=false
AUTO_APPROVE=false
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --alb-priority)
            ALB_PRIORITY="$2"
            shift
            ;;
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

if [[ -z "$ALB_PRIORITY" ]]; then
    echo -e "${RED}Error: --alb-priority is required${NC}"
    usage
fi

# ---------------------------------------------------------------------------
# Environment configuration
# ---------------------------------------------------------------------------
SIT_PROFILE="sit"
SIT_REGION="eu-west-1"
TIMESTAMP=$(date +%Y-%m-%d\ %H:%M:%S)

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
    aws ec2 describe-instances \
        --filters "Name=tag:Name,Values=sit-wordpress-migration-bastion" "Name=instance-state-name,Values=running" \
        --query 'Reservations[0].Instances[0].InstanceId' \
        --output text \
        --profile "$SIT_PROFILE" \
        --region "$SIT_REGION" 2>/dev/null || echo ""
}

# ===================================================================
# MAIN EXECUTION
# ===================================================================

echo ""
echo -e "${BOLD}================================================================${NC}"
echo -e "${BOLD}  Warm Tenant Provisioning: ${TENANT}${NC}"
echo -e "${BOLD}================================================================${NC}"
echo -e "  Target:       SIT (${TENANT}.wpsit.kimmyai.io)"
echo -e "  ALB Priority: ${ALB_PRIORITY}"
echo -e "  Timestamp:    ${TIMESTAMP}"
if $DRY_RUN; then
    echo -e "  ${YELLOW}MODE: DRY RUN — no changes will be made${NC}"
fi
echo ""

OVERALL_RESULT=0

# ===================================================================
# Step 1: Generate Terraform File from Template
# ===================================================================
step_header 1 "Generate Terraform File"

TEMPLATE_FILE="${TEMPLATE_DIR}/warm_tenant_template.tf.tpl"
OUTPUT_FILE="${TERRAFORM_DIR}/sit_${TENANT}.tf"

if [[ ! -f "$TEMPLATE_FILE" ]]; then
    # Fallback to local template
    TEMPLATE_FILE="${SCRIPT_DIR}/../terraform/warm_tenant_template.tf.tpl"
fi

if [[ ! -f "$TEMPLATE_FILE" ]]; then
    echo -e "  ${RED}Template not found at ${TEMPLATE_FILE}${NC}"
    step_result 1 "Generate Terraform File" "FAIL"
    exit 1
fi

if [[ -f "$OUTPUT_FILE" ]]; then
    echo -e "  ${YELLOW}Warning: ${OUTPUT_FILE} already exists${NC}"
    echo -e "  ${YELLOW}Tenant may already be provisioned.${NC}"
    if ! confirm; then
        step_result 1 "Generate Terraform File" "SKIP"
    fi
fi

verbose "Template: ${TEMPLATE_FILE}"
verbose "Output:   ${OUTPUT_FILE}"

if $DRY_RUN; then
    echo -e "  ${YELLOW}[DRY-RUN] Would generate: ${OUTPUT_FILE}${NC}"
    echo -e "  ${YELLOW}[DRY-RUN] Replacements: __TENANT__=${TENANT}, __ALB_PRIORITY__=${ALB_PRIORITY}, __DATE__=${TIMESTAMP}${NC}"
    step_result 1 "Generate Terraform File" "SKIP"
else
    sed \
        -e "s/__TENANT__/${TENANT}/g" \
        -e "s/__ALB_PRIORITY__/${ALB_PRIORITY}/g" \
        -e "s/__DATE__/${TIMESTAMP}/g" \
        "$TEMPLATE_FILE" > "$OUTPUT_FILE"

    if [[ -f "$OUTPUT_FILE" ]]; then
        LINE_COUNT=$(wc -l < "$OUTPUT_FILE" | tr -d ' ')
        echo -e "  ${GREEN}Generated ${OUTPUT_FILE} (${LINE_COUNT} lines)${NC}"
        step_result 1 "Generate Terraform File" "PASS"
    else
        echo -e "  ${RED}Failed to generate Terraform file${NC}"
        step_result 1 "Generate Terraform File" "FAIL"
        OVERALL_RESULT=1
    fi
fi

# ===================================================================
# Step 2: Terraform Init + Plan + Apply
# ===================================================================
step_header 2 "Terraform Apply (SIT)"

echo "  Commands to run in ${TERRAFORM_DIR}:"
echo ""
echo "    cd ${TERRAFORM_DIR}"
echo "    terraform init -backend-config=environments/sit/backend.hcl"
echo "    terraform plan -var-file=environments/sit/sit.tfvars -out=sit-${TENANT}-warm.plan"
echo "    terraform apply sit-${TENANT}-warm.plan"
echo ""

if $DRY_RUN; then
    echo -e "  ${YELLOW}[DRY-RUN] Would apply Terraform for warm tenant${NC}"
    step_result 2 "Terraform Apply (SIT)" "SKIP"
else
    if confirm; then
        echo -e "  ${YELLOW}Run the Terraform commands above, then press Enter when done.${NC}"
        read -r
        step_result 2 "Terraform Apply (SIT)" "PASS"
    else
        step_result 2 "Terraform Apply (SIT)" "SKIP"
    fi
fi

# ===================================================================
# Step 3: Initialize Database on SIT RDS
# ===================================================================
step_header 3 "Initialize Database via Bastion"

if $DRY_RUN; then
    echo -e "  ${YELLOW}[DRY-RUN] Would create database ${TENANT}_db on SIT RDS via bastion${NC}"
    step_result 3 "Initialize Database" "SKIP"
else
    SIT_BASTION_ID="${SIT_BASTION_ID:-}"
    if [[ -z "$SIT_BASTION_ID" ]]; then
        verbose "Auto-detecting SIT bastion..."
        SIT_BASTION_ID=$(detect_bastion)
    fi

    if [[ -z "$SIT_BASTION_ID" ]] || [[ "$SIT_BASTION_ID" == "None" ]]; then
        echo -e "  ${YELLOW}SIT bastion not running — database init must be done manually${NC}"
        echo ""
        echo "  When bastion is available, run on bastion:"
        echo "    mysql -h <rds-endpoint> -u admin -p -e 'CREATE DATABASE IF NOT EXISTS ${TENANT}_db;'"
        echo ""
        step_result 3 "Initialize Database" "SKIP"
    else
        verbose "SIT bastion: ${SIT_BASTION_ID}"

        # Get RDS master credentials
        MASTER_SECRET=$(aws secretsmanager get-secret-value \
            --secret-id "sit-rds-master-credentials" \
            --query SecretString \
            --output text \
            --profile "$SIT_PROFILE" 2>/dev/null) || MASTER_SECRET=""

        if [[ -z "$MASTER_SECRET" ]]; then
            echo -e "  ${YELLOW}Cannot read RDS master credentials — database init must be done manually${NC}"
            step_result 3 "Initialize Database" "SKIP"
        else
            RDS_HOST=$(echo "$MASTER_SECRET" | python3 -c "import sys,json; print(json.load(sys.stdin)['host'])" 2>/dev/null || echo "")
            RDS_USER=$(echo "$MASTER_SECRET" | python3 -c "import sys,json; print(json.load(sys.stdin)['username'])" 2>/dev/null || echo "")
            RDS_PASS=$(echo "$MASTER_SECRET" | python3 -c "import sys,json; print(json.load(sys.stdin)['password'])" 2>/dev/null || echo "")

            # Also get the tenant DB credentials that Terraform just created
            TENANT_SECRET=$(aws secretsmanager get-secret-value \
                --secret-id "sit-${TENANT}-db-credentials" \
                --query SecretString \
                --output text \
                --profile "$SIT_PROFILE" 2>/dev/null) || TENANT_SECRET=""

            TENANT_DB_USER=$(echo "$TENANT_SECRET" | python3 -c "import sys,json; print(json.load(sys.stdin)['username'])" 2>/dev/null || echo "${TENANT}_user")
            TENANT_DB_PASS=$(echo "$TENANT_SECRET" | python3 -c "import sys,json; print(json.load(sys.stdin)['password'])" 2>/dev/null || echo "")

            if [[ -n "$RDS_HOST" ]] && [[ -n "$RDS_USER" ]]; then
                DB_INIT_CMD="mysql -h '${RDS_HOST}' -u '${RDS_USER}' -p'${RDS_PASS}' -e \"CREATE DATABASE IF NOT EXISTS ${TENANT}_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci; CREATE USER IF NOT EXISTS '${TENANT_DB_USER}'@'%' IDENTIFIED BY '${TENANT_DB_PASS}'; GRANT ALL PRIVILEGES ON ${TENANT}_db.* TO '${TENANT_DB_USER}'@'%'; FLUSH PRIVILEGES;\" && echo 'DB_INIT_OK'"

                echo "  Creating database: ${TENANT}_db"
                echo "  Creating user: ${TENANT_DB_USER}"

                COMMAND_ID=$(aws ssm send-command \
                    --instance-ids "$SIT_BASTION_ID" \
                    --document-name "AWS-RunShellScript" \
                    --parameters "commands=[\"${DB_INIT_CMD}\"]" \
                    --timeout-seconds 60 \
                    --output text \
                    --query "Command.CommandId" \
                    --profile "$SIT_PROFILE" 2>/dev/null) || COMMAND_ID=""

                if [[ -n "$COMMAND_ID" ]]; then
                    echo -e "  ${CYAN}SSM Command: ${COMMAND_ID}${NC}"
                    echo -e "  ${YELLOW}Waiting for DB init...${NC}"

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

                    CMD_OUTPUT=$(aws ssm get-command-invocation \
                        --command-id "$COMMAND_ID" \
                        --instance-id "$SIT_BASTION_ID" \
                        --query 'StandardOutputContent' \
                        --output text \
                        --profile "$SIT_PROFILE" 2>/dev/null) || CMD_OUTPUT=""

                    if [[ "$CMD_STATUS" == "Success" ]] && echo "$CMD_OUTPUT" | grep -q "DB_INIT_OK"; then
                        echo -e "  ${GREEN}Database and user created successfully${NC}"
                        step_result 3 "Initialize Database" "PASS"
                    else
                        echo -e "  ${RED}DB init status: ${CMD_STATUS}${NC}"
                        verbose "Output: ${CMD_OUTPUT}"
                        step_result 3 "Initialize Database" "FAIL"
                        OVERALL_RESULT=1
                    fi
                else
                    echo -e "  ${RED}Failed to send SSM command${NC}"
                    step_result 3 "Initialize Database" "FAIL"
                    OVERALL_RESULT=1
                fi
            else
                echo -e "  ${RED}Could not parse RDS credentials${NC}"
                step_result 3 "Initialize Database" "FAIL"
                OVERALL_RESULT=1
            fi
        fi
    fi
fi

# ===================================================================
# Step 4: Validate Warm Tenant State
# ===================================================================
step_header 4 "Validate Warm Tenant"

if $DRY_RUN; then
    echo -e "  ${YELLOW}[DRY-RUN] Would run validate_warm_tenant.sh${NC}"
    step_result 4 "Validate Warm Tenant" "SKIP"
else
    VALIDATE_SCRIPT="${SCRIPT_DIR}/validate_warm_tenant.sh"
    if [[ -f "$VALIDATE_SCRIPT" ]]; then
        VERBOSE_FLAG=""
        if $VERBOSE; then
            VERBOSE_FLAG="--verbose"
        fi

        echo -e "  ${YELLOW}Waiting 30 seconds for services to stabilize...${NC}"
        sleep 30

        if "$VALIDATE_SCRIPT" "$TENANT" $VERBOSE_FLAG; then
            step_result 4 "Validate Warm Tenant" "PASS"
        else
            step_result 4 "Validate Warm Tenant" "FAIL"
            OVERALL_RESULT=1
        fi
    else
        echo -e "  ${YELLOW}validate_warm_tenant.sh not found — skipping${NC}"
        step_result 4 "Validate Warm Tenant" "SKIP"
    fi
fi

# ===================================================================
# FINAL SUMMARY
# ===================================================================

echo ""
echo -e "${BOLD}================================================================${NC}"
echo -e "${BOLD}  Warm Tenant Provisioning Summary: ${TENANT}${NC}"
echo -e "${BOLD}================================================================${NC}"
echo ""
echo -e "  Target:       SIT (${TENANT}.wpsit.kimmyai.io)"
echo -e "  ALB Priority: ${ALB_PRIORITY}"
echo -e "  TF File:      ${OUTPUT_FILE}"
echo ""

if [[ "$OVERALL_RESULT" -eq 0 ]]; then
    echo -e "  ${GREEN}RESULT: WARM TENANT PROVISIONED SUCCESSFULLY${NC}"
    echo ""
    echo -e "  ${BOLD}Next Steps:${NC}"
    echo "    1. When ready to promote, run:"
    echo "       ./scripts/quick_promote.sh ${TENANT}"
    echo "    2. Or check status:"
    echo "       ./scripts/list_warm_tenants.sh"
else
    echo -e "  ${RED}RESULT: PROVISIONING COMPLETED WITH ISSUES${NC}"
    echo ""
    echo -e "  ${BOLD}Troubleshooting:${NC}"
    echo "    1. Review failed steps above"
    echo "    2. Re-run validation: ./scripts/validate_warm_tenant.sh ${TENANT} --verbose"
    echo "    3. Check Terraform state: cd ${TERRAFORM_DIR} && terraform state list | grep ${TENANT}"
fi

echo ""
exit "$OVERALL_RESULT"
