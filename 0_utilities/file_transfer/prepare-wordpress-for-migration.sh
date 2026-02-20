#!/bin/bash

################################################################################
# WordPress Migration Preparation Script
################################################################################
#
# PURPOSE: Prepare WordPress database for CloudFront/ALB architecture
#          Prevents HTTPS redirect loops and security plugin blocking
#
# USAGE:
#   ./prepare-wordpress-for-migration.sh input.sql output.sql
#
# WHAT IT DOES:
#   1. Deactivates problematic plugins from the SQL dump
#   2. Disables Really Simple SSL settings
#   3. Disables Wordfence firewall
#   4. Disables iThemes Security SSL settings
#   5. Outputs fixed SQL file ready for import
#
# REQUIREMENTS:
#   - PHP 7.0+ installed
#   - Input SQL file from WordPress database export
#
################################################################################

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "\n${BLUE}======================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}======================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1" >&2
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

show_help() {
    cat << EOF
WordPress Migration Preparation Script

Prepares WordPress database for CloudFront/ALB architecture by:
- Deactivating SSL/security plugins that cause redirect loops
- Disabling Wordfence firewall
- Clearing Really Simple SSL settings

Usage:
  $0 <input.sql> <output.sql>
  $0 <input.sql>                    # Outputs to input-fixed.sql

Examples:
  $0 database.sql database-fixed.sql
  $0 wordpress-db.sql

Problematic Plugins Deactivated:
  - really-simple-ssl (causes HTTPS redirect loop)
  - wordpress-https (conflicts with CloudFront)
  - wordfence (firewall may block requests)
  - better-wp-security/ithemes-security
  - ldap-login-for-intranet-sites
  - all-in-one-wp-security

After Import:
  Copy force-https-cloudfront.php to:
  wp-content/mu-plugins/force-https-cloudfront.php

EOF
    exit 0
}

# Check arguments
if [[ $# -lt 1 ]] || [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    show_help
fi

INPUT_FILE="$1"
OUTPUT_FILE="${2:-${INPUT_FILE%.sql}-fixed.sql}"

# Validate input file
if [[ ! -f "$INPUT_FILE" ]]; then
    print_error "Input file not found: $INPUT_FILE"
    exit 1
fi

# Check for PHP
if ! command -v php &> /dev/null; then
    print_error "PHP is required but not installed"
    exit 1
fi

print_header "WordPress Migration Preparation"

echo -e "Input:  ${GREEN}${INPUT_FILE}${NC}"
echo -e "Output: ${GREEN}${OUTPUT_FILE}${NC}"
echo ""

# Get file sizes
INPUT_SIZE=$(ls -lh "$INPUT_FILE" | awk '{print $5}')
print_info "Input file size: $INPUT_SIZE"

print_header "Step 1: Analyzing Database"

# Check for problematic plugins
print_info "Checking for problematic plugins..."

PLUGINS_FOUND=()

if grep -q "really-simple-ssl" "$INPUT_FILE"; then
    PLUGINS_FOUND+=("really-simple-ssl")
    print_warning "Found: really-simple-ssl (causes redirect loops)"
fi

if grep -q "wordfence" "$INPUT_FILE"; then
    PLUGINS_FOUND+=("wordfence")
    print_warning "Found: wordfence (firewall may block requests)"
fi

if grep -q "better-wp-security\|ithemes-security" "$INPUT_FILE"; then
    PLUGINS_FOUND+=("ithemes-security")
    print_warning "Found: iThemes Security (may have SSL redirects)"
fi

if grep -q "ldap-login-for-intranet" "$INPUT_FILE"; then
    PLUGINS_FOUND+=("ldap-login")
    print_warning "Found: LDAP Login (may cause login issues)"
fi

if grep -q "all-in-one-wp-security" "$INPUT_FILE"; then
    PLUGINS_FOUND+=("all-in-one-wp-security")
    print_warning "Found: All-in-One WP Security"
fi

if [[ ${#PLUGINS_FOUND[@]} -eq 0 ]]; then
    print_success "No problematic plugins detected"
else
    print_info "Will deactivate ${#PLUGINS_FOUND[@]} problematic plugin(s)"
fi

print_header "Step 2: Processing Database"

# Check if PHP script exists
PHP_SCRIPT="${SCRIPT_DIR}/deactivate-problematic-plugins.php"

if [[ -f "$PHP_SCRIPT" ]]; then
    print_info "Using PHP script for safe plugin deactivation..."
    php "$PHP_SCRIPT" "$INPUT_FILE" > "$OUTPUT_FILE" 2>&1
else
    print_warning "PHP script not found, using sed-based fixes..."

    # Copy input to output
    cp "$INPUT_FILE" "$OUTPUT_FILE"

    # Apply fixes using sed
    print_info "Disabling Really Simple SSL..."
    sed -i.bak "s/rlrsssl_options','[^']*'/rlrsssl_options',''/g" "$OUTPUT_FILE"

    # Add SQL fixes at the end
    cat >> "$OUTPUT_FILE" << 'SQLEOF'

-- ============================================================================
-- AUTO-ADDED: CloudFront/ALB Migration Fixes
-- ============================================================================

-- Disable Really Simple SSL
UPDATE wp_options SET option_value = '' WHERE option_name = 'rlrsssl_options';
DELETE FROM wp_options WHERE option_name LIKE 'rsssl_%';

-- Disable Wordfence firewall
UPDATE wp_wfconfig SET val = '0' WHERE name = 'firewallEnabled';
UPDATE wp_wfconfig SET val = '0' WHERE name = 'liveTrafficEnabled';
UPDATE wp_wfconfig SET val = '0' WHERE name = 'loginSecurityEnabled';

-- Disable iThemes Security SSL
UPDATE wp_options SET option_value = '' WHERE option_name = 'itsec-ssl';

-- ============================================================================
SQLEOF

    # Remove backup
    rm -f "${OUTPUT_FILE}.bak"
fi

print_header "Step 3: Verification"

# Verify output file
if [[ -f "$OUTPUT_FILE" ]]; then
    OUTPUT_SIZE=$(ls -lh "$OUTPUT_FILE" | awk '{print $5}')
    print_success "Output file created: $OUTPUT_FILE ($OUTPUT_SIZE)"
else
    print_error "Failed to create output file"
    exit 1
fi

# Quick verification
if grep -q "CloudFront/ALB Migration Fixes" "$OUTPUT_FILE"; then
    print_success "CloudFront fixes added to SQL"
fi

print_header "Migration Preparation Complete"

echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Database Prepared for CloudFront/ALB Architecture${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "Fixed SQL file: ${BLUE}${OUTPUT_FILE}${NC}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo ""
echo -e "1. Import the fixed SQL file:"
echo -e "   ${BLUE}mysql -u USER -p DATABASE < ${OUTPUT_FILE}${NC}"
echo ""
echo -e "2. Copy MU-plugin to prevent future issues:"
echo -e "   ${BLUE}Copy: ${SCRIPT_DIR}/mu-plugins/force-https-cloudfront.php${NC}"
echo -e "   ${BLUE}To:   wp-content/mu-plugins/force-https-cloudfront.php${NC}"
echo ""
echo -e "3. Verify site loads without redirect loop:"
echo -e "   ${BLUE}curl -sI https://tenant.wpdev.kimmyai.io/ | head -5${NC}"
echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
