#!/bin/bash

################################################################################
# WordPress Database Export Script - Run on Server
################################################################################
#
# Description:
#   Export WordPress database and generate metadata on the server.
#   Database only - no file copying.
#
# Usage:
#   1. Upload script: scp -P <port> rsync-wordpress-export.sh user@host:~/
#   2. SSH to server: ssh -p <port> user@host
#   3. Run: ./rsync-wordpress-export.sh -w <website-name>
#
# Examples:
#   ./rsync-wordpress-export.sh -w fallencovidheroes
#   ./rsync-wordpress-export.sh -w manufacturing -r public_html
#
# Author: BigBeard Web Solutions
# Date: 2026-01-23
# Version: 3.0
#
################################################################################

set -euo pipefail

################################################################################
# Configuration
################################################################################

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Parameters
WEBSITE_NAME=""
WP_ROOT=""
EXPORT_DIR=""

################################################################################
# Color Output Functions
################################################################################

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

error_exit() {
    print_error "$1"
    exit 1
}

################################################################################
# Help Function
################################################################################

show_help() {
    cat << EOF
WordPress Database Export Script - Run on Server

Exports WordPress database and generates metadata. No file copying.

Usage:
  $0 -w <website-name> [OPTIONS]

Required Parameters:
  -w, --website-name NAME    Website name (for export folder naming)

Optional Parameters:
  -r, --wp-root PATH         WordPress root path (default: auto-detect)
  --help                     Display this help message

Examples:
  $0 -w fallencovidheroes
  $0 -w manufacturing -r public_html

Workflow:
  1. Upload:  scp -P <port> rsync-wordpress-export.sh user@host:~/
  2. SSH:     ssh -p <port> user@host
  3. Run:     ./rsync-wordpress-export.sh -w <website-name>
  4. Download: scp -P <port> user@host:~/exports-<website>-*/* ./local-folder/

Output:
  ~/exports-WEBSITE-TIMESTAMP/
  ├── wordpress-db-TIMESTAMP.sql
  ├── CHECKSUMS-TIMESTAMP.txt
  └── EXPORT-NOTES-TIMESTAMP.txt

EOF
    exit 0
}

################################################################################
# Argument Parsing
################################################################################

parse_arguments() {
    if [[ $# -eq 0 ]]; then
        show_help
    fi

    while [[ $# -gt 0 ]]; do
        case $1 in
            -w|--website-name)
                WEBSITE_NAME="$2"
                shift 2
                ;;
            -r|--wp-root)
                WP_ROOT="$2"
                shift 2
                ;;
            --help)
                show_help
                ;;
            *)
                error_exit "Unknown option: $1\nUse --help for usage information."
                ;;
        esac
    done

    [[ -z "$WEBSITE_NAME" ]] && error_exit "Website name is required. Use -w or --website-name"
}

################################################################################
# WordPress Detection
################################################################################

find_wordpress_root() {
    print_header "Locating WordPress Installation"

    if [[ -n "$WP_ROOT" ]]; then
        print_info "Using specified path: $WP_ROOT"

        if [[ -f "${WP_ROOT}/wp-config.php" ]]; then
            print_success "WordPress found at ${WP_ROOT}"
            return 0
        elif [[ -f "${HOME}/${WP_ROOT}/wp-config.php" ]]; then
            WP_ROOT="${HOME}/${WP_ROOT}"
            print_success "WordPress found at ${WP_ROOT}"
            return 0
        else
            error_exit "WordPress not found at: ${WP_ROOT}"
        fi
    fi

    # Auto-detect
    print_info "Auto-detecting WordPress root..."

    local paths=("public_html" "httpdocs" "www" ".")
    for path in "${paths[@]}"; do
        local full="${HOME}/${path}"
        if [[ -f "${full}/wp-config.php" ]]; then
            WP_ROOT="$full"
            print_success "WordPress found at ${WP_ROOT}"
            return 0
        fi
    done

    error_exit "WordPress not found. Use -r to specify path."
}

################################################################################
# Database Export
################################################################################

extract_db_credentials() {
    print_header "Extracting Database Credentials"

    DB_NAME=$(grep -oP "define\s*\(\s*['\"]DB_NAME['\"]\s*,\s*['\"]\K[^'\"]+(?=['\"])" "${WP_ROOT}/wp-config.php" 2>/dev/null || \
              grep "DB_NAME" "${WP_ROOT}/wp-config.php" | sed -E "s/.*['\"]DB_NAME['\"].*[,].*['\"]([^'\"]+)['\"].*/\1/")

    DB_USER=$(grep -oP "define\s*\(\s*['\"]DB_USER['\"]\s*,\s*['\"]\K[^'\"]+(?=['\"])" "${WP_ROOT}/wp-config.php" 2>/dev/null || \
              grep "DB_USER" "${WP_ROOT}/wp-config.php" | sed -E "s/.*['\"]DB_USER['\"].*[,].*['\"]([^'\"]+)['\"].*/\1/")

    DB_PASSWORD=$(grep -oP "define\s*\(\s*['\"]DB_PASSWORD['\"]\s*,\s*['\"]\K[^'\"]+(?=['\"])" "${WP_ROOT}/wp-config.php" 2>/dev/null || \
                  grep "DB_PASSWORD" "${WP_ROOT}/wp-config.php" | sed -E "s/.*['\"]DB_PASSWORD['\"].*[,].*['\"]([^'\"]+)['\"].*/\1/")

    DB_HOST=$(grep -oP "define\s*\(\s*['\"]DB_HOST['\"]\s*,\s*['\"]\K[^'\"]+(?=['\"])" "${WP_ROOT}/wp-config.php" 2>/dev/null || \
              grep "DB_HOST" "${WP_ROOT}/wp-config.php" | sed -E "s/.*['\"]DB_HOST['\"].*[,].*['\"]([^'\"]+)['\"].*/\1/" || echo "localhost")

    TABLE_PREFIX=$(grep -oP "table_prefix\s*=\s*['\"]\\K[^'\"]+(?=['\"])" "${WP_ROOT}/wp-config.php" 2>/dev/null || \
                   grep "table_prefix" "${WP_ROOT}/wp-config.php" | sed -E "s/.*['\"]([^'\"]+)['\"].*/\1/" || echo "wp_")

    [[ -z "$DB_NAME" || -z "$DB_USER" ]] && error_exit "Failed to extract database credentials"

    print_success "Database: $DB_NAME"
    print_success "User: $DB_USER"
    print_success "Host: $DB_HOST"
    print_success "Table Prefix: $TABLE_PREFIX"
}

export_database() {
    print_header "Exporting Database"

    DB_FILE="${EXPORT_DIR}/wordpress-db-${TIMESTAMP}.sql"

    # Parse host:port
    if [[ "$DB_HOST" == *":"* ]]; then
        DB_HOST_ONLY="${DB_HOST%%:*}"
        DB_PORT="${DB_HOST##*:}"
    else
        DB_HOST_ONLY="$DB_HOST"
        DB_PORT="3306"
    fi

    print_info "Exporting to ${DB_FILE}..."

    if [[ -n "$DB_PASSWORD" ]]; then
        mysqldump -u "${DB_USER}" -p"${DB_PASSWORD}" -h "${DB_HOST_ONLY}" -P "${DB_PORT}" "${DB_NAME}" > "${DB_FILE}" 2>/dev/null || error_exit "Database export failed"
    else
        mysqldump -u "${DB_USER}" -h "${DB_HOST_ONLY}" -P "${DB_PORT}" "${DB_NAME}" > "${DB_FILE}" || error_exit "Database export failed"
    fi

    [[ ! -s "$DB_FILE" ]] && error_exit "Database export is empty"

    local db_size=$(ls -lh "$DB_FILE" | awk '{print $5}')
    print_success "Database exported (${db_size})"
}

################################################################################
# Checksums
################################################################################

generate_checksums() {
    print_header "Generating Checksums"

    CHECKSUM_FILE="${EXPORT_DIR}/CHECKSUMS-${TIMESTAMP}.txt"

    cd "${EXPORT_DIR}"

    if [[ -f "wordpress-db-${TIMESTAMP}.sql" ]]; then
        sha256sum "wordpress-db-${TIMESTAMP}.sql" > "${CHECKSUM_FILE}"
        print_success "Checksums: ${CHECKSUM_FILE}"
    fi

    cd - > /dev/null
}

################################################################################
# Export Notes with Plugins and Themes
################################################################################

generate_notes() {
    print_header "Creating Export Notes"

    NOTES_FILE="${EXPORT_DIR}/EXPORT-NOTES-${TIMESTAMP}.txt"

    local PHP_VERSION=$(php -v 2>/dev/null | head -1 || echo 'N/A')
    local DB_SIZE=$(ls -lh "${EXPORT_DIR}/wordpress-db-${TIMESTAMP}.sql" 2>/dev/null | awk '{print $5}' || echo 'N/A')

    # Get plugins list
    local PLUGINS_LIST=""
    if [[ -d "${WP_ROOT}/wp-content/plugins" ]]; then
        PLUGINS_LIST=$(ls -1 "${WP_ROOT}/wp-content/plugins/" 2>/dev/null | grep -v "^index.php$" || echo "None found")
    else
        PLUGINS_LIST="Plugins directory not found"
    fi

    # Get themes list
    local THEMES_LIST=""
    if [[ -d "${WP_ROOT}/wp-content/themes" ]]; then
        THEMES_LIST=$(ls -1 "${WP_ROOT}/wp-content/themes/" 2>/dev/null | grep -v "^index.php$" || echo "None found")
    else
        THEMES_LIST="Themes directory not found"
    fi

    # Get active theme from database (if possible)
    local ACTIVE_THEME="Unknown"
    if [[ -n "$DB_PASSWORD" ]]; then
        ACTIVE_THEME=$(mysql -u "${DB_USER}" -p"${DB_PASSWORD}" -h "${DB_HOST_ONLY:-$DB_HOST}" -P "${DB_PORT:-3306}" "${DB_NAME}" -N -e "SELECT option_value FROM ${TABLE_PREFIX}options WHERE option_name='template';" 2>/dev/null || echo "Unknown")
    fi

    # Get site URL from database (if possible)
    local SITE_URL="Unknown"
    if [[ -n "$DB_PASSWORD" ]]; then
        SITE_URL=$(mysql -u "${DB_USER}" -p"${DB_PASSWORD}" -h "${DB_HOST_ONLY:-$DB_HOST}" -P "${DB_PORT:-3306}" "${DB_NAME}" -N -e "SELECT option_value FROM ${TABLE_PREFIX}options WHERE option_name='siteurl';" 2>/dev/null || echo "Unknown")
    fi

    # Count plugins
    local PLUGIN_COUNT=$(echo "$PLUGINS_LIST" | wc -l | tr -d ' ')

    # Count themes
    local THEME_COUNT=$(echo "$THEMES_LIST" | wc -l | tr -d ' ')

    cat > "${NOTES_FILE}" << EOF
================================================================================
WordPress Database Export - ${WEBSITE_NAME}
================================================================================

Export Date: $(date)
Server: $(hostname)
User: $(whoami)
Export Type: Database Only

================================================================================
Site Information
================================================================================

Site URL: ${SITE_URL}
WordPress Path: ${WP_ROOT}
Active Theme: ${ACTIVE_THEME}

================================================================================
Database Information
================================================================================

Database Name: ${DB_NAME:-N/A}
Database User: ${DB_USER:-N/A}
Database Host: ${DB_HOST:-N/A}
Table Prefix: ${TABLE_PREFIX:-wp_}
Export File: wordpress-db-${TIMESTAMP}.sql
Export Size: ${DB_SIZE}

================================================================================
Environment
================================================================================

PHP Version: ${PHP_VERSION}
Server: $(uname -a 2>/dev/null || echo 'N/A')

================================================================================
Installed Plugins (${PLUGIN_COUNT})
================================================================================

${PLUGINS_LIST}

================================================================================
Installed Themes (${THEME_COUNT})
================================================================================

${THEMES_LIST}

================================================================================
Export Contents
================================================================================

$(ls -lh "${EXPORT_DIR}")

================================================================================
Download Instructions
================================================================================

From your local machine, run:

  scp -P 2222 '$(whoami)@$(hostname):${EXPORT_DIR}/*' ./

Or use rsync:

  rsync -avz -e "ssh -p 2222" $(whoami)@$(hostname):${EXPORT_DIR}/ ./

================================================================================
EOF

    print_success "Notes: ${NOTES_FILE}"
}

################################################################################
# Final Report
################################################################################

final_report() {
    print_header "Export Complete"

    local TOTAL_SIZE=$(du -sh "${EXPORT_DIR}" | awk '{print $1}')

    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  WordPress Database Export Successful!${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "Website:     ${BLUE}${WEBSITE_NAME}${NC}"
    echo -e "Export Dir:  ${BLUE}${EXPORT_DIR}${NC}"
    echo -e "Total Size:  ${BLUE}${TOTAL_SIZE}${NC}"
    echo ""
    echo -e "${YELLOW}Contents:${NC}"
    ls -lh "${EXPORT_DIR}"
    echo ""
    echo -e "${YELLOW}Download to local machine:${NC}"
    echo -e "  ${BLUE}scp -P 2222 '$(whoami)@$(hostname):${EXPORT_DIR}/*' ./${NC}"
    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
}

################################################################################
# Main
################################################################################

main() {
    clear

    echo -e "${BLUE}"
    cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║       WordPress Database Export - Run on Server              ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"

    parse_arguments "$@"

    EXPORT_DIR="${HOME}/exports-${WEBSITE_NAME}-${TIMESTAMP}"
    mkdir -p "${EXPORT_DIR}"

    print_header "Configuration"
    echo -e "Website:    ${GREEN}${WEBSITE_NAME}${NC}"
    echo -e "WP Root:    ${GREEN}${WP_ROOT:-auto-detect}${NC}"
    echo -e "Export Dir: ${GREEN}${EXPORT_DIR}${NC}"
    echo ""

    find_wordpress_root
    extract_db_credentials
    export_database
    generate_checksums
    generate_notes
    final_report

    exit 0
}

main "$@"
