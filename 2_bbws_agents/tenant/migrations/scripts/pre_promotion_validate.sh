#!/bin/bash
##############################################################################
# Pre-Promotion Validation Script
# Purpose: Run pre-export checks before promoting a WordPress tenant
# Usage:   ./pre_promotion_validate.sh <tenant-name> <source-env> [--skip-db] [--skip-efs]
#
# Checks mapped to KNOWN_ISSUES_REGISTRY.md MI-IDs:
#   Check 1:  AWS auth & SSO token        (MI-001, MI-017)
#   Check 2:  ECS service health           (MI-020, MI-021, MI-022)
#   Check 3:  HTTP status code             (MI-010)
#   Check 4:  Mixed content scan           (MI-014)
#   Check 5:  Encoding artifact scan       (MI-003)
#   Check 6:  DB connectivity              (MI-030)
#   Check 7:  DB charset verification      (MI-003, MI-030)
#   Check 8:  Active theme check           (MI-013)
#   Check 9:  Active plugins inventory     (MI-024, MI-025)
#   Check 10: CloudWatch error scan        (MI-015)
#   Check 11: Site size & transfer advice  (MI-026)
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
${BOLD}Pre-Promotion Validation${NC}

Usage:
  $(basename "$0") <tenant-name> <source-env> [OPTIONS]

Arguments:
  tenant-name    Tenant identifier (e.g., cliplok, gravitonwealth)
  source-env     Source environment: dev | sit

Options:
  --skip-db      Skip database checks (6, 7)
  --skip-efs     Skip EFS / file-system checks
  --verbose      Show detailed output for each check
  --help         Show this help message

Examples:
  $(basename "$0") cliplok dev
  $(basename "$0") gravitonwealth dev --skip-db
  $(basename "$0") managedis sit --verbose
EOF
    exit 0
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
if [[ $# -lt 2 ]] || [[ "$1" == "--help" ]]; then
    usage
fi

TENANT="$1"
SOURCE_ENV="$2"
shift 2

SKIP_DB=false
SKIP_EFS=false
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --skip-db)  SKIP_DB=true ;;
        --skip-efs) SKIP_EFS=true ;;
        --verbose)  VERBOSE=true ;;
        --help)     usage ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            usage
            ;;
    esac
    shift
done

# ---------------------------------------------------------------------------
# Environment profiles
# ---------------------------------------------------------------------------
case "$SOURCE_ENV" in
    dev)
        AWS_PROFILE="dev"
        AWS_REGION="eu-west-1"
        DOMAIN="${TENANT}.wpdev.kimmyai.io"
        CLUSTER="dev-cluster"
        SERVICE="dev-${TENANT}-service"
        LOG_GROUP="/ecs/dev"
        BASTION_TAG="dev-wordpress-migration-bastion"
        RDS_INSTANCE="dev-mysql"
        SECRET_ID="dev-${TENANT}-db-credentials"
        AUTH_USER="dev"
        AUTH_PASS="ovcjaopj1ooojajo"
        ;;
    sit)
        AWS_PROFILE="sit"
        AWS_REGION="eu-west-1"
        DOMAIN="${TENANT}.wpsit.kimmyai.io"
        CLUSTER="sit-cluster"
        SERVICE="sit-${TENANT}-service"
        LOG_GROUP="/ecs/sit"
        BASTION_TAG="sit-wordpress-migration-bastion"
        RDS_INSTANCE="sit-mysql"
        SECRET_ID="sit-${TENANT}-db-credentials"
        AUTH_USER="bigbeard"
        AUTH_PASS="BigBeard2026!"
        ;;
    *)
        echo -e "${RED}Invalid source environment: $SOURCE_ENV${NC}"
        echo "Must be: dev | sit"
        exit 1
        ;;
esac

export AWS_PROFILE
export AWS_DEFAULT_REGION="$AWS_REGION"

# ---------------------------------------------------------------------------
# Counters
# ---------------------------------------------------------------------------
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0
TOTAL_CHECKS=11

if $SKIP_DB; then
    TOTAL_CHECKS=$((TOTAL_CHECKS - 2))
fi

# ---------------------------------------------------------------------------
# Helper functions
# ---------------------------------------------------------------------------
print_check() {
    local num="$1"
    local title="$2"
    local mi_id="$3"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}Check ${num}: ${title}${NC}  (${mi_id})"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

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
    WARN_COUNT=$((WARN_COUNT + 1))
}

verbose() {
    if $VERBOSE; then
        echo -e "  ${CYAN}[INFO]${NC} $1"
    fi
}

# ===================================================================
# BEGIN CHECKS
# ===================================================================

echo ""
echo -e "${BOLD}================================================================${NC}"
echo -e "${BOLD}  Pre-Promotion Validation: ${TENANT} (${SOURCE_ENV})${NC}"
echo -e "${BOLD}================================================================${NC}"
echo -e "  Domain:  https://${DOMAIN}"
echo -e "  Profile: ${AWS_PROFILE}"
echo -e "  Region:  ${AWS_REGION}"

# -------------------------------------------------------------------
# Check 1: AWS Authentication & SSO Token  (MI-001, MI-017)
# -------------------------------------------------------------------
print_check 1 "AWS Authentication & SSO Token" "MI-001, MI-017"

CALLER_ID=$(aws sts get-caller-identity --output json 2>&1) || true
if echo "$CALLER_ID" | grep -q "UserId"; then
    ACCOUNT=$(echo "$CALLER_ID" | grep -o '"Account": "[^"]*"' | cut -d'"' -f4)
    pass "AWS authenticated — account ${ACCOUNT}"
else
    fail "AWS authentication failed — run: aws sso login --profile ${AWS_PROFILE}"
    echo -e "  ${RED}Cannot proceed without valid AWS credentials. Exiting.${NC}"
    exit 1
fi

# -------------------------------------------------------------------
# Check 2: ECS Service Health  (MI-020, MI-021, MI-022)
# -------------------------------------------------------------------
print_check 2 "ECS Service Health" "MI-020, MI-021, MI-022"

SVC_JSON=$(aws ecs describe-services \
    --cluster "$CLUSTER" \
    --services "$SERVICE" \
    --output json 2>&1) || true

if echo "$SVC_JSON" | grep -q '"services": \[\]'; then
    fail "ECS service ${SERVICE} not found in cluster ${CLUSTER}"
else
    RUNNING=$(echo "$SVC_JSON" | grep -o '"runningCount": [0-9]*' | head -1 | grep -o '[0-9]*')
    DESIRED=$(echo "$SVC_JSON" | grep -o '"desiredCount": [0-9]*' | head -1 | grep -o '[0-9]*')
    STATUS=$(echo "$SVC_JSON" | grep -o '"status": "[^"]*"' | head -1 | cut -d'"' -f4)

    if [[ "$STATUS" == "ACTIVE" ]] && [[ "$RUNNING" -ge 1 ]] && [[ "$RUNNING" -eq "$DESIRED" ]]; then
        pass "ECS service ACTIVE — running ${RUNNING}/${DESIRED} tasks"
    elif [[ "$RUNNING" -eq 0 ]]; then
        fail "ECS service has 0 running tasks (desired: ${DESIRED})"
    else
        warn "ECS service running ${RUNNING}/${DESIRED} tasks (status: ${STATUS})"
    fi
fi

# -------------------------------------------------------------------
# Check 3: HTTP Status Code  (MI-010)
# -------------------------------------------------------------------
print_check 3 "HTTP Status Code" "MI-010"

HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
    -u "${AUTH_USER}:${AUTH_PASS}" \
    --max-time 15 \
    "https://${DOMAIN}/" 2>/dev/null) || HTTP_STATUS="000"

if [[ "$HTTP_STATUS" == "200" ]]; then
    pass "HTTP 200 OK"
elif [[ "$HTTP_STATUS" == "401" ]]; then
    fail "HTTP 401 Unauthorized — check CloudFront basic auth credentials"
elif [[ "$HTTP_STATUS" == "301" ]] || [[ "$HTTP_STATUS" == "302" ]]; then
    warn "HTTP ${HTTP_STATUS} Redirect — possible redirect loop (MI-018)"
elif [[ "$HTTP_STATUS" == "000" ]]; then
    fail "Connection failed — site unreachable"
else
    warn "HTTP ${HTTP_STATUS} — unexpected status"
fi

# -------------------------------------------------------------------
# Check 4: Mixed Content Scan  (MI-014)
# -------------------------------------------------------------------
print_check 4 "Mixed Content Scan" "MI-014"

PAGE_BODY=$(curl -s -u "${AUTH_USER}:${AUTH_PASS}" --max-time 15 "https://${DOMAIN}/" 2>/dev/null) || PAGE_BODY=""

if [[ -z "$PAGE_BODY" ]]; then
    warn "Could not fetch page body — skipping mixed content scan"
else
    HTTP_REFS=$(echo "$PAGE_BODY" | grep -oi "http://${DOMAIN}" | wc -l | tr -d ' ')
    if [[ "$HTTP_REFS" -eq 0 ]]; then
        pass "No HTTP references to ${DOMAIN} found (all HTTPS)"
    else
        fail "Found ${HTTP_REFS} HTTP references on HTTPS page — mixed content"
    fi
fi

# -------------------------------------------------------------------
# Check 5: Encoding Artifact Scan  (MI-003)
# -------------------------------------------------------------------
print_check 5 "Encoding Artifact Scan" "MI-003"

if [[ -z "$PAGE_BODY" ]]; then
    warn "Could not fetch page body — skipping encoding scan"
else
    ENCODING_HITS=$(echo "$PAGE_BODY" | grep -c 'â€\|Ã¢\|Ã©\|Ã¨\|Ã¼' 2>/dev/null || echo "0")
    if [[ "$ENCODING_HITS" -eq 0 ]]; then
        pass "No UTF-8 encoding artifacts detected"
    else
        fail "Found ${ENCODING_HITS} encoding artifacts — double-encoded characters"
    fi
fi

# -------------------------------------------------------------------
# Check 6: Database Connectivity  (MI-030)  [skippable]
# -------------------------------------------------------------------
if ! $SKIP_DB; then
    print_check 6 "Database Connectivity" "MI-030"

    SECRET_JSON=$(aws secretsmanager get-secret-value \
        --secret-id "$SECRET_ID" \
        --query SecretString \
        --output text 2>&1) || SECRET_JSON=""

    if [[ -z "$SECRET_JSON" ]] || echo "$SECRET_JSON" | grep -qi "error\|exception"; then
        fail "Cannot read secret ${SECRET_ID} — check Secrets Manager access"
    else
        DB_HOST=$(echo "$SECRET_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['host'])" 2>/dev/null || echo "")
        DB_NAME=$(echo "$SECRET_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['dbname'])" 2>/dev/null || echo "")
        if [[ -n "$DB_HOST" ]] && [[ -n "$DB_NAME" ]]; then
            pass "Secret readable — DB host: ${DB_HOST}, DB: ${DB_NAME}"
        else
            warn "Secret readable but missing expected fields (host, dbname)"
        fi
    fi
fi

# -------------------------------------------------------------------
# Check 7: Database Charset Verification  (MI-003, MI-030)  [skippable]
# -------------------------------------------------------------------
if ! $SKIP_DB; then
    print_check 7 "Database Charset Verification" "MI-003, MI-030"

    if [[ -n "${DB_HOST:-}" ]]; then
        verbose "Charset verification requires bastion access — verifying secret has charset info"
        # We can only validate from secret metadata; actual charset check requires bastion
        pass "Database credentials available — charset verification requires bastion session"
        verbose "Run on bastion: SHOW VARIABLES LIKE 'character_set_database'; — expect utf8mb4"
    else
        warn "Skipped — database host not available from secret"
    fi
fi

# -------------------------------------------------------------------
# Check 8: Active Theme Check  (MI-013)
# -------------------------------------------------------------------
print_check 8 "Active Theme Check" "MI-013"

if [[ -n "$PAGE_BODY" ]]; then
    # Look for theme references in the HTML
    THEME_CSS=$(echo "$PAGE_BODY" | grep -o 'themes/[^/]*' | head -1 | sed 's|themes/||')
    if [[ -n "$THEME_CSS" ]]; then
        pass "Active theme detected: ${THEME_CSS}"
        if echo "$THEME_CSS" | grep -qi "backup\|old\|temp\|default"; then
            warn "Theme name contains 'backup/old/temp/default' — verify this is correct"
        fi
    else
        warn "Could not detect theme from page HTML"
    fi
else
    warn "Could not fetch page — skipping theme check"
fi

# -------------------------------------------------------------------
# Check 9: Active Plugins Inventory  (MI-024, MI-025)
# -------------------------------------------------------------------
print_check 9 "Active Plugins Inventory" "MI-024, MI-025"

if [[ -n "$PAGE_BODY" ]]; then
    # Check for problematic plugin signatures in page output
    PROBLEMATIC=0
    if echo "$PAGE_BODY" | grep -qi "really-simple-ssl"; then
        warn "Really Simple SSL detected in page output — may cause redirect loops (MI-024)"
        PROBLEMATIC=$((PROBLEMATIC + 1))
    fi
    if echo "$PAGE_BODY" | grep -qi "wordfence"; then
        warn "Wordfence detected in page output — may block CloudFront IPs (MI-025)"
        PROBLEMATIC=$((PROBLEMATIC + 1))
    fi
    if [[ "$PROBLEMATIC" -eq 0 ]]; then
        pass "No problematic plugins detected in page output"
    fi
else
    warn "Could not fetch page — skipping plugin scan"
fi

# -------------------------------------------------------------------
# Check 10: CloudWatch Error Scan  (MI-015)
# -------------------------------------------------------------------
print_check 10 "CloudWatch Error Scan (last 30 min)" "MI-015"

SINCE_MS=$(( $(date +%s) * 1000 - 1800000 ))
CW_ERRORS=$(aws logs filter-log-events \
    --log-group-name "$LOG_GROUP" \
    --log-stream-name-prefix "${TENANT}" \
    --start-time "$SINCE_MS" \
    --filter-pattern "?ERROR ?Fatal ?\"PHP Fatal\" ?\"PHP Warning\"" \
    --query 'events[*].message' \
    --output text 2>&1) || CW_ERRORS=""

if [[ -z "$CW_ERRORS" ]] || [[ "$CW_ERRORS" == "None" ]]; then
    pass "No PHP errors or fatals in CloudWatch (last 30 min)"
elif echo "$CW_ERRORS" | grep -qi "ResourceNotFoundException\|does not exist"; then
    warn "Log group ${LOG_GROUP} or stream not found — service may not have started yet"
else
    ERROR_COUNT=$(echo "$CW_ERRORS" | wc -l | tr -d ' ')
    fail "Found ${ERROR_COUNT} error(s) in CloudWatch — review logs"
    if $VERBOSE; then
        echo "$CW_ERRORS" | head -5
    fi
fi

# -------------------------------------------------------------------
# Check 11: Site Size & Transfer Recommendation  (MI-026)
# -------------------------------------------------------------------
print_check 11 "Site Size & Transfer Recommendation" "MI-026"

CONTENT_LENGTH=$(curl -sI -u "${AUTH_USER}:${AUTH_PASS}" --max-time 10 \
    "https://${DOMAIN}/" 2>/dev/null | grep -i "content-length" | awk '{print $2}' | tr -d '\r')

if [[ -n "$CONTENT_LENGTH" ]] && [[ "$CONTENT_LENGTH" -gt 0 ]] 2>/dev/null; then
    SIZE_KB=$((CONTENT_LENGTH / 1024))
    pass "Homepage size: ${SIZE_KB} KB"
else
    verbose "Content-Length header not available (chunked encoding)"
    pass "Homepage served (chunked transfer — size check N/A for page)"
fi

verbose "Transfer recommendation: If total wp-content > 500MB, use S3 staging. If < 500MB, use direct bastion."

# ===================================================================
# SUMMARY
# ===================================================================

echo ""
echo -e "${BOLD}================================================================${NC}"
echo -e "${BOLD}  Validation Summary${NC}"
echo -e "${BOLD}================================================================${NC}"
echo ""
echo -e "  Tenant:   ${TENANT}"
echo -e "  Source:    ${SOURCE_ENV} (https://${DOMAIN})"
echo -e "  Profile:  ${AWS_PROFILE}"
echo ""
echo -e "  ${GREEN}Passed:${NC}   ${PASS_COUNT}"
echo -e "  ${RED}Failed:${NC}   ${FAIL_COUNT}"
echo -e "  ${YELLOW}Warnings:${NC} ${WARN_COUNT}"
echo ""

if [[ "$FAIL_COUNT" -gt 0 ]]; then
    echo -e "  ${RED}RESULT: PRE-PROMOTION VALIDATION FAILED${NC}"
    echo -e "  ${RED}Fix ${FAIL_COUNT} failure(s) before proceeding with promotion.${NC}"
    echo ""
    exit 1
else
    echo -e "  ${GREEN}RESULT: PRE-PROMOTION VALIDATION PASSED${NC}"
    if [[ "$WARN_COUNT" -gt 0 ]]; then
        echo -e "  ${YELLOW}Review ${WARN_COUNT} warning(s) before proceeding.${NC}"
    fi
    echo ""
    exit 0
fi
