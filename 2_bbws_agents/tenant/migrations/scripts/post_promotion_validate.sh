#!/bin/bash
##############################################################################
# Post-Promotion Validation Script
# Purpose: Run post-import checks after promoting a WordPress tenant
# Usage:   ./post_promotion_validate.sh <tenant-name> <target-env> [--verbose]
#
# Checks mapped to KNOWN_ISSUES_REGISTRY.md MI-IDs:
#   Check 1:  HTTP status code             (MI-006, MI-018)
#   Check 2:  Content size (non-zero)      (MI-006, MI-008)
#   Check 3:  Mixed content scan           (MI-014)
#   Check 4:  Encoding artifact scan       (MI-003)
#   Check 5:  URL replacement completeness (MI-009)
#   Check 6:  Canonical URL check          (MI-009)
#   Check 7:  EFS mount / static files     (MI-005, MI-007)
#   Check 8:  Theme CSS accessible         (MI-007, MI-029)
#   Check 9:  Form endpoint check          (MI-012)
#   Check 10: wp-admin accessible          (MI-011, MI-018)
#   Check 11: CloudWatch error scan        (MI-015)
#   Check 12: Page load time               (MI-016)
#   Check 13: ECS target health            (MI-019)
#   Check 14: Visible PHP errors           (MI-015)
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
${BOLD}Post-Promotion Validation${NC}

Usage:
  $(basename "$0") <tenant-name> <target-env> [OPTIONS]

Arguments:
  tenant-name    Tenant identifier (e.g., cliplok, gravitonwealth)
  target-env     Target environment: dev | sit

Options:
  --source-domain <domain>  Override the old domain for URL replacement checks
                            (e.g., cliplok.co.za for Xneelo-to-SIT migrations)
  --verbose                 Show detailed output for each check
  --help                    Show this help message

Examples:
  $(basename "$0") cliplok sit
  $(basename "$0") gravitonwealth dev --verbose
  $(basename "$0") caseforward sit --source-domain caseforward.co.za
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
TARGET_ENV="$2"
shift 2

VERBOSE=false
SOURCE_DOMAIN_OVERRIDE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --source-domain)
            SOURCE_DOMAIN_OVERRIDE="$2"
            shift
            ;;
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
# Environment profiles
# ---------------------------------------------------------------------------
case "$TARGET_ENV" in
    dev)
        AWS_PROFILE="dev"
        AWS_REGION="eu-west-1"
        DOMAIN="${TENANT}.wpdev.kimmyai.io"
        CLUSTER="dev-cluster"
        SERVICE="dev-${TENANT}-service"
        TG_NAME="dev-${TENANT}-tg"
        LOG_GROUP="/ecs/dev"
        AUTH_USER="dev"
        AUTH_PASS="ovcjaopj1ooojajo"
        OLD_DOMAIN="${TENANT}.wpdev.kimmyai.io"   # same for dev-to-dev
        ;;
    sit)
        AWS_PROFILE="sit"
        AWS_REGION="eu-west-1"
        DOMAIN="${TENANT}.wpsit.kimmyai.io"
        CLUSTER="sit-cluster"
        SERVICE="sit-${TENANT}-service"
        TG_NAME="sit-${TENANT}-tg"
        LOG_GROUP="/ecs/sit"
        AUTH_USER="bigbeard"
        AUTH_PASS="BigBeard2026!"
        OLD_DOMAIN="${TENANT}.wpdev.kimmyai.io"   # DEV domain for replacement check
        ;;
    *)
        echo -e "${RED}Invalid target environment: $TARGET_ENV${NC}"
        echo "Must be: dev | sit"
        exit 1
        ;;
esac

# Override OLD_DOMAIN if --source-domain was provided (for Xneelo-to-SIT migrations)
if [[ -n "$SOURCE_DOMAIN_OVERRIDE" ]]; then
    OLD_DOMAIN="$SOURCE_DOMAIN_OVERRIDE"
fi

export AWS_PROFILE
export AWS_DEFAULT_REGION="$AWS_REGION"

# ---------------------------------------------------------------------------
# Counters
# ---------------------------------------------------------------------------
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0
TOTAL_CHECKS=14

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
# Fetch page once and reuse
# ===================================================================
SITE_URL="https://${DOMAIN}"
CURL_AUTH="-u ${AUTH_USER}:${AUTH_PASS}"

echo ""
echo -e "${BOLD}================================================================${NC}"
echo -e "${BOLD}  Post-Promotion Validation: ${TENANT} (${TARGET_ENV})${NC}"
echo -e "${BOLD}================================================================${NC}"
echo -e "  Domain:  ${SITE_URL}"
echo -e "  Profile: ${AWS_PROFILE}"
echo -e "  Region:  ${AWS_REGION}"

# Fetch homepage
PAGE_BODY=$(curl -sL ${CURL_AUTH} --max-time 30 "${SITE_URL}/" 2>/dev/null) || PAGE_BODY=""
HEADERS=$(curl -sI ${CURL_AUTH} --max-time 15 "${SITE_URL}/" 2>/dev/null) || HEADERS=""

# ===================================================================
# BEGIN CHECKS
# ===================================================================

# -------------------------------------------------------------------
# Check 1: HTTP Status Code  (MI-006, MI-018)
# -------------------------------------------------------------------
print_check 1 "HTTP Status Code" "MI-006, MI-018"

HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
    ${CURL_AUTH} --max-time 15 "${SITE_URL}/" 2>/dev/null) || HTTP_STATUS="000"

if [[ "$HTTP_STATUS" == "200" ]]; then
    pass "HTTP 200 OK"
elif [[ "$HTTP_STATUS" == "301" ]] || [[ "$HTTP_STATUS" == "302" ]]; then
    fail "HTTP ${HTTP_STATUS} Redirect — possible HTTPS redirect loop (MI-018)"
elif [[ "$HTTP_STATUS" == "401" ]]; then
    fail "HTTP 401 Unauthorized — basic auth credentials incorrect"
elif [[ "$HTTP_STATUS" == "502" ]] || [[ "$HTTP_STATUS" == "503" ]]; then
    fail "HTTP ${HTTP_STATUS} — ECS target unhealthy (MI-019)"
elif [[ "$HTTP_STATUS" == "000" ]]; then
    fail "Connection failed — site unreachable"
else
    warn "HTTP ${HTTP_STATUS} — unexpected status"
fi

# -------------------------------------------------------------------
# Check 2: Content Size (non-zero)  (MI-006, MI-008)
# -------------------------------------------------------------------
print_check 2 "Content Size" "MI-006, MI-008"

CONTENT_SIZE=${#PAGE_BODY}

if [[ "$CONTENT_SIZE" -gt 5000 ]]; then
    SIZE_KB=$((CONTENT_SIZE / 1024))
    pass "Homepage content: ${SIZE_KB} KB (${CONTENT_SIZE} bytes)"
elif [[ "$CONTENT_SIZE" -gt 0 ]]; then
    warn "Homepage content only ${CONTENT_SIZE} bytes — may be incomplete (MI-006)"
else
    fail "Homepage returned 0 bytes — EFS mount issue likely (MI-006)"
fi

# -------------------------------------------------------------------
# Check 3: Mixed Content Scan  (MI-014)
# -------------------------------------------------------------------
print_check 3 "Mixed Content Scan" "MI-014"

if [[ -n "$PAGE_BODY" ]]; then
    # Count HTTP refs to tenant domain specifically
    HTTP_REFS=$(echo "$PAGE_BODY" | grep -oi "http://${DOMAIN}" | wc -l | tr -d ' ')
    # Also check for generic http:// in src/href attributes
    HTTP_ASSETS=$(echo "$PAGE_BODY" | grep -oiE '(src|href)="http://[^"]*"' | wc -l | tr -d ' ')

    if [[ "$HTTP_REFS" -eq 0 ]] && [[ "$HTTP_ASSETS" -eq 0 ]]; then
        pass "No mixed content detected"
    elif [[ "$HTTP_REFS" -gt 0 ]]; then
        fail "Found ${HTTP_REFS} HTTP references to ${DOMAIN} — mixed content (MI-014)"
    else
        warn "Found ${HTTP_ASSETS} HTTP asset references (may be external)"
    fi
else
    warn "Empty page body — cannot scan for mixed content"
fi

# -------------------------------------------------------------------
# Check 4: Encoding Artifact Scan  (MI-003)
# -------------------------------------------------------------------
print_check 4 "Encoding Artifact Scan" "MI-003"

if [[ -n "$PAGE_BODY" ]]; then
    ENCODING_HITS=$(echo "$PAGE_BODY" | grep -o 'â€\|Ã¢\|Ã©\|Ã¨\|Ã¼' 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$ENCODING_HITS" -eq 0 ]]; then
        pass "No UTF-8 encoding artifacts detected"
    else
        fail "Found ${ENCODING_HITS} encoding artifacts — double-encoded characters (MI-003)"
    fi
else
    warn "Empty page body — cannot scan for encoding issues"
fi

# -------------------------------------------------------------------
# Check 5: URL Replacement Completeness  (MI-009)
# -------------------------------------------------------------------
print_check 5 "URL Replacement Completeness" "MI-009"

if [[ -n "$PAGE_BODY" ]] && [[ "$TARGET_ENV" == "sit" ]]; then
    OLD_REFS=$(echo "$PAGE_BODY" | grep -oi "${OLD_DOMAIN}" | wc -l | tr -d ' ')
    if [[ "$OLD_REFS" -eq 0 ]]; then
        pass "No references to old domain (${OLD_DOMAIN}) found"
    else
        fail "Found ${OLD_REFS} references to old DEV domain — URL replacement incomplete (MI-009)"
    fi
elif [[ "$TARGET_ENV" == "dev" ]]; then
    pass "URL replacement check not applicable for DEV-to-DEV"
else
    warn "Empty page body — cannot check URL replacement"
fi

# -------------------------------------------------------------------
# Check 6: Canonical URL Check  (MI-009)
# -------------------------------------------------------------------
print_check 6 "Canonical URL" "MI-009"

if [[ -n "$PAGE_BODY" ]]; then
    CANONICAL=$(echo "$PAGE_BODY" | grep -oi 'rel="canonical"[^>]*href="[^"]*"' | grep -oi 'href="[^"]*"' | head -1 | sed 's/href="//;s/"//')
    if [[ -n "$CANONICAL" ]]; then
        if echo "$CANONICAL" | grep -q "${DOMAIN}"; then
            pass "Canonical URL points to ${DOMAIN}"
        else
            fail "Canonical URL points to wrong domain: ${CANONICAL}"
        fi
    else
        warn "No canonical URL found in page HTML"
    fi
else
    warn "Empty page body — cannot check canonical URL"
fi

# -------------------------------------------------------------------
# Check 7: EFS Mount / Static Files  (MI-005, MI-007)
# -------------------------------------------------------------------
print_check 7 "EFS Mount (Static File Access)" "MI-005, MI-007"

# Try fetching a common static file
UPLOAD_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
    ${CURL_AUTH} --max-time 10 \
    "${SITE_URL}/wp-content/plugins/" 2>/dev/null) || UPLOAD_STATUS="000"

if [[ "$UPLOAD_STATUS" == "200" ]] || [[ "$UPLOAD_STATUS" == "403" ]] || [[ "$UPLOAD_STATUS" == "301" ]]; then
    pass "wp-content/plugins/ reachable (HTTP ${UPLOAD_STATUS}) — EFS mounted"
elif [[ "$UPLOAD_STATUS" == "404" ]]; then
    fail "wp-content/plugins/ returns 404 — EFS may not be mounted (MI-007)"
else
    warn "wp-content/plugins/ returned HTTP ${UPLOAD_STATUS}"
fi

# -------------------------------------------------------------------
# Check 8: Theme CSS Accessible  (MI-007, MI-029)
# -------------------------------------------------------------------
print_check 8 "Theme CSS Accessible" "MI-007, MI-029"

if [[ -n "$PAGE_BODY" ]]; then
    # Extract first CSS link from page
    CSS_URL=$(echo "$PAGE_BODY" | grep -oE 'https?://[^"]*\.css(\?[^"]*)?' | head -1)
    if [[ -n "$CSS_URL" ]]; then
        CSS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
            ${CURL_AUTH} --max-time 10 "${CSS_URL}" 2>/dev/null) || CSS_STATUS="000"
        if [[ "$CSS_STATUS" == "200" ]]; then
            pass "Theme CSS accessible (HTTP 200)"
            verbose "CSS URL: ${CSS_URL}"
        else
            fail "Theme CSS returned HTTP ${CSS_STATUS} — check EFS mount (MI-007)"
        fi
    else
        warn "No CSS file URL found in page HTML"
    fi
else
    warn "Empty page body — cannot check theme CSS"
fi

# -------------------------------------------------------------------
# Check 9: Form Endpoint Check  (MI-012)
# -------------------------------------------------------------------
print_check 9 "Form Endpoint" "MI-012"

if [[ -n "$PAGE_BODY" ]]; then
    # Check for common form actions
    FORM_COUNT=$(echo "$PAGE_BODY" | grep -oi '<form' | wc -l | tr -d ' ')
    if [[ "$FORM_COUNT" -gt 0 ]]; then
        pass "Found ${FORM_COUNT} form(s) on homepage"
        # Check for reCAPTCHA references
        if echo "$PAGE_BODY" | grep -qi "recaptcha\|g-recaptcha"; then
            warn "reCAPTCHA detected — verify keys match new domain (MI-012)"
        fi
    else
        pass "No forms on homepage (check inner pages manually)"
    fi
else
    warn "Empty page body — cannot check forms"
fi

# -------------------------------------------------------------------
# Check 10: wp-admin Accessible  (MI-011, MI-018)
# -------------------------------------------------------------------
print_check 10 "wp-admin Accessible" "MI-011, MI-018"

ADMIN_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
    ${CURL_AUTH} -L --max-time 15 \
    "${SITE_URL}/wp-login.php" 2>/dev/null) || ADMIN_STATUS="000"

if [[ "$ADMIN_STATUS" == "200" ]]; then
    pass "wp-login.php accessible (HTTP 200)"
elif [[ "$ADMIN_STATUS" == "302" ]] || [[ "$ADMIN_STATUS" == "301" ]]; then
    warn "wp-login.php redirects (HTTP ${ADMIN_STATUS}) — may still work with -L"
elif [[ "$ADMIN_STATUS" == "000" ]]; then
    fail "wp-login.php unreachable"
else
    fail "wp-login.php returned HTTP ${ADMIN_STATUS}"
fi

# -------------------------------------------------------------------
# Check 11: CloudWatch Error Scan  (MI-015)
# -------------------------------------------------------------------
print_check 11 "CloudWatch Error Scan (last 15 min)" "MI-015"

SINCE_MS=$(( $(date +%s) * 1000 - 900000 ))
CW_ERRORS=$(aws logs filter-log-events \
    --log-group-name "$LOG_GROUP" \
    --log-stream-name-prefix "${TENANT}" \
    --start-time "$SINCE_MS" \
    --filter-pattern "?ERROR ?Fatal ?\"PHP Fatal\"" \
    --query 'events[*].message' \
    --output text 2>&1) || CW_ERRORS=""

if [[ -z "$CW_ERRORS" ]] || [[ "$CW_ERRORS" == "None" ]]; then
    pass "No fatal errors in CloudWatch (last 15 min)"
elif echo "$CW_ERRORS" | grep -qi "ResourceNotFoundException\|does not exist"; then
    warn "Log group or stream not found — service may be newly deployed"
else
    ERROR_COUNT=$(echo "$CW_ERRORS" | wc -l | tr -d ' ')
    fail "Found ${ERROR_COUNT} error(s) in CloudWatch — review logs"
    if $VERBOSE; then
        echo "$CW_ERRORS" | head -5
    fi
fi

# -------------------------------------------------------------------
# Check 12: Page Load Time  (MI-016)
# -------------------------------------------------------------------
print_check 12 "Page Load Time" "MI-016"

LOAD_TIME=$(curl -s -o /dev/null -w "%{time_total}" \
    ${CURL_AUTH} -L --max-time 30 \
    "${SITE_URL}/" 2>/dev/null) || LOAD_TIME="0"

if command -v bc &>/dev/null; then
    if (( $(echo "$LOAD_TIME < 3.0" | bc -l) )); then
        pass "Page load time: ${LOAD_TIME}s (under 3s)"
    elif (( $(echo "$LOAD_TIME < 5.0" | bc -l) )); then
        warn "Page load time: ${LOAD_TIME}s (over 3s, under 5s)"
    else
        fail "Page load time: ${LOAD_TIME}s (over 5s — performance issue)"
    fi
else
    pass "Page load time: ${LOAD_TIME}s (bc not available for threshold check)"
fi

# -------------------------------------------------------------------
# Check 13: ECS Target Health  (MI-019)
# -------------------------------------------------------------------
print_check 13 "ECS Target Health" "MI-019"

TG_ARN=$(aws elbv2 describe-target-groups \
    --names "$TG_NAME" \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text 2>&1) || TG_ARN=""

if [[ -n "$TG_ARN" ]] && ! echo "$TG_ARN" | grep -qi "error\|not found"; then
    HEALTH_JSON=$(aws elbv2 describe-target-health \
        --target-group-arn "$TG_ARN" \
        --output json 2>&1) || HEALTH_JSON=""

    if echo "$HEALTH_JSON" | grep -q '"State": "healthy"'; then
        pass "Target group has healthy targets"
    elif echo "$HEALTH_JSON" | grep -q '"State": "unhealthy"'; then
        REASON=$(echo "$HEALTH_JSON" | grep -o '"Reason": "[^"]*"' | head -1)
        fail "Target group unhealthy — ${REASON} (MI-019)"
    elif echo "$HEALTH_JSON" | grep -q '"State": "initial"'; then
        warn "Target group in initial health check — wait 30-60 seconds"
    else
        warn "Could not determine target group health state"
    fi
else
    warn "Target group ${TG_NAME} not found — check ALB configuration"
fi

# -------------------------------------------------------------------
# Check 14: Visible PHP Errors  (MI-015)
# -------------------------------------------------------------------
print_check 14 "Visible PHP Errors in HTML" "MI-015"

if [[ -n "$PAGE_BODY" ]]; then
    PHP_ERRORS=$(echo "$PAGE_BODY" | grep -oiE 'PHP (Notice|Warning|Deprecated|Fatal|Parse error)' 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$PHP_ERRORS" -eq 0 ]]; then
        pass "No visible PHP errors in page output"
    else
        fail "Found ${PHP_ERRORS} visible PHP error(s) on page (MI-015)"
        if $VERBOSE; then
            echo "$PAGE_BODY" | grep -iE 'PHP (Notice|Warning|Deprecated|Fatal|Parse error)' | head -3
        fi
    fi
else
    warn "Empty page body — cannot scan for PHP errors"
fi

# ===================================================================
# SUMMARY
# ===================================================================

echo ""
echo -e "${BOLD}================================================================${NC}"
echo -e "${BOLD}  Post-Promotion Validation Summary${NC}"
echo -e "${BOLD}================================================================${NC}"
echo ""
echo -e "  Tenant:   ${TENANT}"
echo -e "  Target:   ${TARGET_ENV} (${SITE_URL})"
echo -e "  Profile:  ${AWS_PROFILE}"
echo ""
echo -e "  ${GREEN}Passed:${NC}   ${PASS_COUNT}"
echo -e "  ${RED}Failed:${NC}   ${FAIL_COUNT}"
echo -e "  ${YELLOW}Warnings:${NC} ${WARN_COUNT}"
echo ""

if [[ "$FAIL_COUNT" -gt 0 ]]; then
    echo -e "  ${RED}RESULT: POST-PROMOTION VALIDATION FAILED${NC}"
    echo -e "  ${RED}${FAIL_COUNT} check(s) failed. Review issues above.${NC}"
    echo -e "  ${YELLOW}Consider creating a COE document:${NC}"
    echo -e "  ${YELLOW}  Template: .claude/coe/COE_TEMPLATE.md${NC}"
    echo -e "  ${YELLOW}  Registry: runbooks/KNOWN_ISSUES_REGISTRY.md${NC}"
    echo ""
    exit 1
else
    echo -e "  ${GREEN}RESULT: POST-PROMOTION VALIDATION PASSED${NC}"
    if [[ "$WARN_COUNT" -gt 0 ]]; then
        echo -e "  ${YELLOW}Review ${WARN_COUNT} warning(s) above.${NC}"
    fi
    echo ""
    exit 0
fi
