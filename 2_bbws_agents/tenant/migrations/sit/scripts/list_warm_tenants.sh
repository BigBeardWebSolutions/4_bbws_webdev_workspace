#!/bin/bash
##############################################################################
# List Warm Tenants
#
# Purpose: List all SIT tenants provisioned with the warm tenant strategy
# Usage:   ./list_warm_tenants.sh [--all] [--verbose]
#
# Output shows status:
#   WARM     — Infrastructure ready, empty database (no wp_options table)
#   PROMOTED — Data imported, site has content
#   STOPPED  — Desired count = 0 (scaled down)
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
# Argument parsing
# ---------------------------------------------------------------------------
SHOW_ALL=false
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --all)     SHOW_ALL=true ;;
        --verbose) VERBOSE=true ;;
        --help)
            cat <<EOF
${BOLD}List Warm Tenants${NC}

Usage:
  $(basename "$0") [OPTIONS]

Options:
  --all        Show all SIT tenants, not just warm ones
  --verbose    Show detailed information per tenant
  --help       Show this help message
EOF
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
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

export AWS_PROFILE
export AWS_DEFAULT_REGION="$AWS_REGION"

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

echo ""
echo -e "${BOLD}================================================================${NC}"
echo -e "${BOLD}  SIT Warm Tenants${NC}"
echo -e "${BOLD}================================================================${NC}"
echo ""

# List all services in the SIT cluster
SERVICES_JSON=$(aws ecs list-services \
    --cluster "$CLUSTER" \
    --output json 2>&1) || SERVICES_JSON=""

if [[ -z "$SERVICES_JSON" ]] || echo "$SERVICES_JSON" | grep -qi "error"; then
    echo -e "${RED}Failed to list services in ${CLUSTER}${NC}"
    echo -e "${YELLOW}Ensure AWS SSO session is active: aws sso login --profile sit${NC}"
    exit 1
fi

SERVICE_ARNS=$(echo "$SERVICES_JSON" | grep -o '"arn:aws:ecs:[^"]*"' | tr -d '"')

if [[ -z "$SERVICE_ARNS" ]]; then
    echo -e "${YELLOW}No services found in ${CLUSTER}${NC}"
    exit 0
fi

# Describe all services
DESCRIBE_JSON=$(aws ecs describe-services \
    --cluster "$CLUSTER" \
    --services $SERVICE_ARNS \
    --output json 2>&1) || DESCRIBE_JSON=""

WARM_COUNT=0
PROMOTED_COUNT=0
STOPPED_COUNT=0

printf "  ${BOLD}%-25s %-10s %-8s %-8s %-12s${NC}\n" "TENANT" "STATUS" "RUNNING" "DESIRED" "WARM TAG"
printf "  %-25s %-10s %-8s %-8s %-12s\n" "-------------------------" "----------" "--------" "--------" "------------"

# Parse services
echo "$DESCRIBE_JSON" | python3 -c "
import sys, json

data = json.load(sys.stdin)
services = data.get('services', [])

for svc in sorted(services, key=lambda s: s['serviceName']):
    name = svc['serviceName']
    running = svc.get('runningCount', 0)
    desired = svc.get('desiredCount', 0)

    # Extract tenant name from service name (sit-{tenant}-service)
    parts = name.replace('sit-', '', 1).replace('-service', '')
    tenant = parts

    # Check for WarmTenant tag
    tags = {t['key']: t['value'] for t in svc.get('tags', [])}
    warm_tag = tags.get('WarmTenant', 'false')

    # Determine status
    if desired == 0:
        status = 'STOPPED'
    elif warm_tag == 'true' and running >= 1:
        status = 'WARM'
    elif running >= 1:
        status = 'PROMOTED'
    else:
        status = 'STARTING'

    show_all = ${SHOW_ALL} if '${SHOW_ALL}' == 'true' else False

    if show_all or warm_tag == 'true':
        print(f'  {tenant:<25s} {status:<10s} {running:<8d} {desired:<8d} {warm_tag:<12s}')
" 2>/dev/null || echo -e "  ${RED}Failed to parse service data${NC}"

echo ""

# Count summary
TOTAL=$(echo "$DESCRIBE_JSON" | python3 -c "
import sys, json
data = json.load(sys.stdin)
services = data.get('services', [])
warm = sum(1 for s in services if any(t.get('key') == 'WarmTenant' and t.get('value') == 'true' for t in s.get('tags', [])))
total = len(services)
print(f'{warm},{total}')
" 2>/dev/null || echo "0,0")

WARM_TOTAL=$(echo "$TOTAL" | cut -d',' -f1)
SVC_TOTAL=$(echo "$TOTAL" | cut -d',' -f2)

echo -e "  ${BOLD}Summary:${NC} ${WARM_TOTAL} warm tenant(s) out of ${SVC_TOTAL} total service(s)"
echo ""
