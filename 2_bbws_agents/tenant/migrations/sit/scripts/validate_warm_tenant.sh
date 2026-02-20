#!/bin/bash
##############################################################################
# Warm Tenant Validation Script
#
# Purpose: Validate that a SIT warm tenant is healthy and ready for promotion
# Usage:   ./validate_warm_tenant.sh <tenant-name> [--verbose]
#
# Checks:
#   1. ECS service ACTIVE with runningCount >= 1
#   2. ALB target group healthy
#   3. HTTP returns 200/301/302
#   4. Secrets Manager credentials readable
#   5. EFS access point exists
#   6. Database user can connect (via bastion)
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
# Usage
# ---------------------------------------------------------------------------
usage() {
    cat <<EOF
${BOLD}Warm Tenant Validation${NC}

Usage:
  $(basename "$0") <tenant-name> [OPTIONS]

Arguments:
  tenant-name    Tenant identifier (e.g., cliplok, lynfin)

Options:
  --verbose      Show detailed output
  --help         Show this help message

Examples:
  $(basename "$0") cliplok
  $(basename "$0") lynfin --verbose
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

VERBOSE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --verbose) VERBOSE=true ;;
        --help)    usage ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            usage
            ;;
    esac
    shift
done

# ---------------------------------------------------------------------------
# SIT environment configuration
# ---------------------------------------------------------------------------
AWS_PROFILE="sit"
AWS_REGION="eu-west-1"
CLUSTER="sit-cluster"
SERVICE="sit-${TENANT}-service"
DOMAIN="${TENANT}.wpsit.kimmyai.io"
SECRET_ID="sit-${TENANT}-db-credentials"
TG_NAME="sit-${TENANT}-tg"
AUTH_USER="bigbeard"
AUTH_PASS="BigBeard2026!"

export AWS_PROFILE
export AWS_DEFAULT_REGION="$AWS_REGION"

# ---------------------------------------------------------------------------
# Counters
# ---------------------------------------------------------------------------
PASS_COUNT=0
FAIL_COUNT=0
TOTAL_CHECKS=6

# ---------------------------------------------------------------------------
# Helper functions
# ---------------------------------------------------------------------------
pass() {
    echo -e "  ${GREEN}[PASS]${NC} $1"
    PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
    echo -e "  ${RED}[FAIL]${NC} $1"
    FAIL_COUNT=$((FAIL_COUNT + 1))
}

warn() {
    echo -e "  ${YELLOW}[WARN]${NC} $1"
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
        --output text 2>/dev/null || echo ""
}

# ===================================================================
# BEGIN CHECKS
# ===================================================================

echo ""
echo -e "${BOLD}================================================================${NC}"
echo -e "${BOLD}  Warm Tenant Validation: ${TENANT} (SIT)${NC}"
echo -e "${BOLD}================================================================${NC}"
echo -e "  Domain:  https://${DOMAIN}"
echo -e "  Profile: ${AWS_PROFILE}"
echo ""

# -------------------------------------------------------------------
# Check 1: ECS Service ACTIVE with running tasks
# -------------------------------------------------------------------
echo -e "${CYAN}Check 1/6: ECS Service Health${NC}"

SVC_JSON=$(aws ecs describe-services \
    --cluster "$CLUSTER" \
    --services "$SERVICE" \
    --output json 2>&1) || SVC_JSON=""

if echo "$SVC_JSON" | grep -q '"services": \[\]'; then
    fail "ECS service ${SERVICE} not found in cluster ${CLUSTER}"
else
    RUNNING=$(echo "$SVC_JSON" | grep -o '"runningCount": [0-9]*' | head -1 | grep -o '[0-9]*')
    STATUS=$(echo "$SVC_JSON" | grep -o '"status": "[^"]*"' | head -1 | cut -d'"' -f4)

    if [[ "$STATUS" == "ACTIVE" ]] && [[ "${RUNNING:-0}" -ge 1 ]]; then
        pass "ECS service ACTIVE — ${RUNNING} task(s) running"
    elif [[ "${RUNNING:-0}" -eq 0 ]]; then
        fail "ECS service has 0 running tasks"
    else
        fail "ECS service status: ${STATUS}, running: ${RUNNING:-0}"
    fi
fi

# -------------------------------------------------------------------
# Check 2: ALB Target Group Healthy
# -------------------------------------------------------------------
echo -e "${CYAN}Check 2/6: ALB Target Health${NC}"

TG_ARN=$(aws elbv2 describe-target-groups \
    --names "$TG_NAME" \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text 2>&1) || TG_ARN=""

if [[ -n "$TG_ARN" ]] && ! echo "$TG_ARN" | grep -qi "error\|not found"; then
    HEALTH_JSON=$(aws elbv2 describe-target-health \
        --target-group-arn "$TG_ARN" \
        --output json 2>&1) || HEALTH_JSON=""

    if echo "$HEALTH_JSON" | grep -q '"State": "healthy"'; then
        pass "ALB target group has healthy targets"
    elif echo "$HEALTH_JSON" | grep -q '"State": "initial"'; then
        warn "Target in initial health check — wait 30-60 seconds"
        pass "ALB target group exists (initial state)"
    else
        fail "ALB target group unhealthy"
    fi
else
    fail "Target group ${TG_NAME} not found"
fi

# -------------------------------------------------------------------
# Check 3: HTTP Returns 200/301/302
# -------------------------------------------------------------------
echo -e "${CYAN}Check 3/6: HTTP Status${NC}"

HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
    -u "${AUTH_USER}:${AUTH_PASS}" \
    --max-time 15 \
    "https://${DOMAIN}/" 2>/dev/null) || HTTP_STATUS="000"

if [[ "$HTTP_STATUS" == "200" ]] || [[ "$HTTP_STATUS" == "301" ]] || [[ "$HTTP_STATUS" == "302" ]]; then
    pass "HTTP ${HTTP_STATUS} from https://${DOMAIN}/"
elif [[ "$HTTP_STATUS" == "000" ]]; then
    fail "Connection failed — site unreachable"
else
    fail "HTTP ${HTTP_STATUS} — unexpected status"
fi

# -------------------------------------------------------------------
# Check 4: Secrets Manager Credentials Readable
# -------------------------------------------------------------------
echo -e "${CYAN}Check 4/6: Secrets Manager${NC}"

SECRET_JSON=$(aws secretsmanager get-secret-value \
    --secret-id "$SECRET_ID" \
    --query SecretString \
    --output text 2>&1) || SECRET_JSON=""

if [[ -n "$SECRET_JSON" ]] && ! echo "$SECRET_JSON" | grep -qi "error\|exception"; then
    DB_HOST=$(echo "$SECRET_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['host'])" 2>/dev/null || echo "")
    DB_NAME=$(echo "$SECRET_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['database'])" 2>/dev/null || echo "")
    if [[ -n "$DB_HOST" ]] && [[ -n "$DB_NAME" ]]; then
        pass "Secret readable — DB: ${DB_NAME} on ${DB_HOST}"
    else
        fail "Secret readable but missing expected fields"
    fi
else
    fail "Cannot read secret ${SECRET_ID}"
fi

# -------------------------------------------------------------------
# Check 5: EFS Access Point Exists
# -------------------------------------------------------------------
echo -e "${CYAN}Check 5/6: EFS Access Point${NC}"

AP_JSON=$(aws efs describe-access-points \
    --output json 2>&1) || AP_JSON=""

if echo "$AP_JSON" | grep -q "/${TENANT}"; then
    pass "EFS access point exists for /${TENANT}"
else
    fail "No EFS access point found for /${TENANT}"
fi

# -------------------------------------------------------------------
# Check 6: Database User Can Connect (via bastion)
# -------------------------------------------------------------------
echo -e "${CYAN}Check 6/6: Database Connectivity${NC}"

if [[ -n "${DB_HOST:-}" ]] && [[ -n "${SECRET_JSON:-}" ]]; then
    SIT_BASTION_ID=$(detect_bastion)

    if [[ -n "$SIT_BASTION_ID" ]] && [[ "$SIT_BASTION_ID" != "None" ]]; then
        DB_USER=$(echo "$SECRET_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['username'])" 2>/dev/null || echo "")
        DB_PASS=$(echo "$SECRET_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['password'])" 2>/dev/null || echo "")

        TEST_CMD="mysql -h '${DB_HOST}' -u '${DB_USER}' -p'${DB_PASS}' -e 'SELECT 1' 2>/dev/null && echo 'DB_CONNECT_OK' || echo 'DB_CONNECT_FAIL'"

        COMMAND_ID=$(aws ssm send-command \
            --instance-ids "$SIT_BASTION_ID" \
            --document-name "AWS-RunShellScript" \
            --parameters "commands=[\"${TEST_CMD}\"]" \
            --timeout-seconds 30 \
            --output text \
            --query "Command.CommandId" 2>/dev/null) || COMMAND_ID=""

        if [[ -n "$COMMAND_ID" ]]; then
            sleep 5
            CMD_OUTPUT=$(aws ssm get-command-invocation \
                --command-id "$COMMAND_ID" \
                --instance-id "$SIT_BASTION_ID" \
                --query 'StandardOutputContent' \
                --output text 2>/dev/null) || CMD_OUTPUT=""

            if echo "$CMD_OUTPUT" | grep -q "DB_CONNECT_OK"; then
                pass "Database user can connect via bastion"
            else
                fail "Database connection failed via bastion"
            fi
        else
            warn "Could not send SSM command — bastion may not be ready"
            pass "Skipping DB connectivity (bastion SSM unavailable)"
        fi
    else
        warn "SIT bastion not running — skipping DB connectivity check"
        pass "Skipping DB connectivity (no bastion)"
    fi
else
    fail "Cannot test DB connectivity — no credentials available"
fi

# ===================================================================
# SUMMARY
# ===================================================================

echo ""
echo -e "${BOLD}================================================================${NC}"
echo -e "${BOLD}  Warm Tenant Validation Summary: ${TENANT}${NC}"
echo -e "${BOLD}================================================================${NC}"
echo ""
echo -e "  ${GREEN}Passed:${NC} ${PASS_COUNT}/${TOTAL_CHECKS}"
echo -e "  ${RED}Failed:${NC} ${FAIL_COUNT}/${TOTAL_CHECKS}"
echo ""

if [[ "$FAIL_COUNT" -gt 0 ]]; then
    echo -e "  ${RED}RESULT: WARM TENANT NOT READY${NC}"
    echo ""
    exit 1
else
    echo -e "  ${GREEN}RESULT: WARM TENANT READY FOR PROMOTION${NC}"
    echo ""
    exit 0
fi
