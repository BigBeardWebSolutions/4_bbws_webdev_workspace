#!/bin/bash

################################################################################
# WordPress Local Export Script - Run Directly on Xneelo Server
################################################################################
#
# Description:
#   Export WordPress website directly on the server (after you've SSH'd in).
#   This script runs ALL operations locally without SSH.
#
# Usage:
#   1. SSH into your Xneelo server:
#      ssh -p 2222 manufkcxqw@197.221.10.19
#
#   2. Upload this script to the server:
#      (On local machine): scp -P 2222 local-wordpress-export.sh manufkcxqw@197.221.10.19:~/
#
#   3. On the server, make it executable:
#      chmod +x local-wordpress-export.sh
#
#   4. Run the script:
#      ./local-wordpress-export.sh -w manufacturing
#
#   5. Download exports to your local machine:
#      (On local machine): scp -P 2222 manufkcxqw@197.221.10.19:~/exports-* .
#
# Parameters:
#   -w, --website-name NAME    Website name (for export folder naming)
#   -r, --wp-root PATH         WordPress root path (default: auto-detect)
#   --skip-archive             Skip tar.gz creation (faster)
#   --help                     Display this help message
#
# Author: BigBeard Web Solutions
# Date: 2026-01-13
# Version: 1.0
#
################################################################################

set -euo pipefail

################################################################################
# Configuration & Defaults
################################################################################

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Parameters (will be set by argument parsing)
WEBSITE_NAME=""
WP_ROOT=""
SKIP_ARCHIVE=true
FINAL_PACKAGE=""

################################################################################
# Color Output Functions
################################################################################

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

################################################################################
# Error Handling
################################################################################

error_exit() {
    print_error "$1"
    exit 1
}

################################################################################
# Help Function
################################################################################

show_help() {
    cat << EOF
WordPress Local Export Script - Run Directly on Xneelo Server

This script runs ON the server (after you've already SSH'd in).
No SSH operations - everything runs locally.

Usage:
  $0 -w <website-name> [OPTIONS]

Required Parameters:
  -w, --website-name NAME    Website name (for export folder naming)

Optional Parameters:
  -r, --wp-root PATH         WordPress root path (default: auto-detect)
  --skip-archive             Skip tar.gz creation (faster)
  --help                     Display this help message

Complete Workflow:
  # 1. SSH into Xneelo server (from your local machine)
  ssh -p 2222 manufkcxqw@197.221.10.19

  # 2. Upload this script to server (from your local machine in another terminal)
  scp -P 2222 local-wordpress-export.sh manufkcxqw@197.221.10.19:~/

  # 3. On the server, make executable and run
  chmod +x local-wordpress-export.sh
  ./local-wordpress-export.sh -w manufacturing

  # 4. Download exports (from your local machine)
  scp -P 2222 'manufkcxqw@197.221.10.19:~/exports-manufacturing-*.tar.gz' .

Examples:
  ./local-wordpress-export.sh -w manufacturing
  ./local-wordpress-export.sh -w clientsite -r public_html
  ./local-wordpress-export.sh -w mysite --skip-archive

Output:
  ~/exports-WEBSITE-TIMESTAMP/
  ├── wordpress-db-TIMESTAMP.sql
  ├── wordpress-files-TIMESTAMP.tar.gz (if not --skip-archive)
  ├── CHECKSUMS-TIMESTAMP.txt
  └── EXPORT-NOTES-TIMESTAMP.txt

  Final package: ~/exports-WEBSITE-TIMESTAMP.tar.gz

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
            --skip-archive)
                SKIP_ARCHIVE=true
                shift
                ;;
            --help)
                show_help
                ;;
            *)
                error_exit "Unknown option: $1\nUse --help for usage information."
                ;;
        esac
    done

    # Validate required parameters
    if [[ -z "$WEBSITE_NAME" ]]; then
        error_exit "Website name is required. Use -w or --website-name"
    fi
}

################################################################################
# WordPress Detection Functions
################################################################################

find_wordpress_root() {
    print_header "Locating WordPress Installation"

    if [[ -n "$WP_ROOT" ]]; then
        print_info "Using specified WordPress root: $WP_ROOT"

        if [[ -f "${WP_ROOT}/wp-config.php" ]]; then
            print_success "WordPress found at ${WP_ROOT}"
            return 0
        else
            error_exit "WordPress not found at specified path: ${WP_ROOT}"
        fi
    fi

    # Auto-detect WordPress root
    print_info "Auto-detecting WordPress root..."

    local possible_paths=("public_html" "httpdocs" "www" "public_html/httpdocs" ".")

    for path in "${possible_paths[@]}"; do
        print_info "Checking ~/${path}..."
        if [[ -f "${path}/wp-config.php" ]]; then
            WP_ROOT="$path"
            print_success "WordPress found at ${WP_ROOT}"
            return 0
        fi
    done

    error_exit "WordPress installation not found. Please specify path with -r option."
}

verify_wordpress_installation() {
    print_header "Verifying WordPress Installation"

    print_info "Checking for wp-config.php..."
    if [[ -f "${WP_ROOT}/wp-config.php" ]]; then
        print_success "wp-config.php found"
    else
        error_exit "wp-config.php not found in ${WP_ROOT}"
    fi

    print_info "Checking for wp-content directory..."
    if [[ -d "${WP_ROOT}/wp-content" ]]; then
        print_success "wp-content directory found"
    else
        error_exit "wp-content directory not found in ${WP_ROOT}"
    fi
}

################################################################################
# Database Export Functions
################################################################################

extract_database_credentials() {
    print_header "Extracting Database Credentials"

    print_info "Reading wp-config.php..."

    DB_NAME=$(grep "define( *'DB_NAME'" "${WP_ROOT}/wp-config.php" | cut -d "'" -f 4)
    DB_USER=$(grep "define( *'DB_USER'" "${WP_ROOT}/wp-config.php" | cut -d "'" -f 4)
    DB_PASSWORD=$(grep "define( *'DB_PASSWORD'" "${WP_ROOT}/wp-config.php" | cut -d "'" -f 4)
    DB_HOST=$(grep "define( *'DB_HOST'" "${WP_ROOT}/wp-config.php" | cut -d "'" -f 4)

    if [[ -z "$DB_NAME" || -z "$DB_USER" ]]; then
        error_exit "Failed to extract database credentials from wp-config.php"
    fi

    print_success "Database: $DB_NAME"
    print_success "User: $DB_USER"
    print_success "Host: $DB_HOST"
}

export_database() {
    print_header "Exporting Database"

    DB_FILE="${EXPORT_DIR}/wordpress-db-${TIMESTAMP}.sql"
    print_info "Exporting database to ${DB_FILE}..."

    # Export database
    if [[ -n "$DB_PASSWORD" ]]; then
        mysqldump -u "${DB_USER}" -p"${DB_PASSWORD}" -h "${DB_HOST}" "${DB_NAME}" > "${DB_FILE}" 2>/dev/null || error_exit "Database export failed"
    else
        mysqldump -u "${DB_USER}" -h "${DB_HOST}" "${DB_NAME}" > "${DB_FILE}" || error_exit "Database export failed"
    fi

    # Verify export
    if [[ ! -f "$DB_FILE" ]] || [[ ! -s "$DB_FILE" ]]; then
        error_exit "Database export verification failed - file is missing or empty"
    fi

    local db_size=$(ls -lh "$DB_FILE" | awk '{print $5}')
    print_success "Database exported successfully (${db_size})"
}

################################################################################
# File Archive Functions
################################################################################

archive_wordpress_files() {
    if [[ "$SKIP_ARCHIVE" == true ]]; then
        print_warning "Skipping tar archive (--skip-archive mode)"
        ARCHIVE_FILE=""
        return 0
    fi

    print_header "Creating WordPress Files Archive"

    ARCHIVE_FILE="${EXPORT_DIR}/wordpress-files-${TIMESTAMP}.tar.gz"
    print_info "Creating archive ${ARCHIVE_FILE}..."
    print_warning "This may take several minutes for large sites..."

    # Create tar archive from WordPress root
    cd "${WP_ROOT}"
    tar -czf "${ARCHIVE_FILE}" . || error_exit "File archive creation failed"
    cd - > /dev/null

    # Verify archive
    if [[ ! -f "$ARCHIVE_FILE" ]] || [[ ! -s "$ARCHIVE_FILE" ]]; then
        error_exit "Archive verification failed - file is missing or empty"
    fi

    local archive_size=$(ls -lh "$ARCHIVE_FILE" | awk '{print $5}')
    print_success "Archive created successfully (${archive_size})"
}

################################################################################
# Environment Information Functions
################################################################################

collect_environment_info() {
    print_header "Collecting Environment Information"

    NOTES_FILE="${EXPORT_DIR}/EXPORT-NOTES-${TIMESTAMP}.txt"

    print_info "Gathering environment details..."

    # Get PHP version
    PHP_VERSION=$(php -v 2>/dev/null | head -1 || echo 'PHP version not available')

    # Get table prefix
    TABLE_PREFIX=$(grep table_prefix "${WP_ROOT}/wp-config.php" || echo 'Could not extract table prefix')

    # Get plugins list
    PLUGINS_LIST=$(ls -1 "${WP_ROOT}/wp-content/plugins/" 2>/dev/null || echo 'Could not list plugins')

    # Get themes list
    THEMES_LIST=$(ls -1 "${WP_ROOT}/wp-content/themes/" 2>/dev/null || echo 'Could not list themes')

    # Create export notes
    cat > "${NOTES_FILE}" << EOF
================================================================================
WordPress Export Notes
================================================================================

Export Date: $(date)
Website: ${WEBSITE_NAME}
Server: $(hostname)
WordPress Path: ${WP_ROOT}
Current User: $(whoami)

================================================================================
Database Information
================================================================================

Database Name: ${DB_NAME}
Database User: ${DB_USER}
Database Host: ${DB_HOST}

================================================================================
Environment Information
================================================================================

PHP Version:
${PHP_VERSION}

WordPress Path: ${WP_ROOT}

Table Prefix:
${TABLE_PREFIX}

================================================================================
Installed Plugins
================================================================================

${PLUGINS_LIST}

================================================================================
Installed Themes
================================================================================

${THEMES_LIST}

================================================================================
Export Files
================================================================================

Database Export: wordpress-db-${TIMESTAMP}.sql
File Archive: ${ARCHIVE_FILE:-"N/A (skipped with --skip-archive)"}
Checksums: CHECKSUMS-${TIMESTAMP}.txt
Export Notes: EXPORT-NOTES-${TIMESTAMP}.txt

Export Directory: ${EXPORT_DIR}
Final Package: exports-${WEBSITE_NAME}-${TIMESTAMP}.tar.gz

================================================================================
Download Instructions
================================================================================

To download exports to your local machine, run this command on your LOCAL machine:

scp -P 2222 $(whoami)@$(hostname):~/exports-${WEBSITE_NAME}-${TIMESTAMP}.tar.gz .

Or download individual files:

scp -P 2222 $(whoami)@$(hostname):~/${EXPORT_DIR}/* .

================================================================================
Next Steps for AWS Migration
================================================================================

1. Download all export files to your local machine
2. Verify checksums for data integrity
3. Prepare AWS environment (EC2/Lightsail with LAMP/LEMP)
4. Import database to AWS MySQL:
   mysql -u new_user -p new_db < wordpress-db-${TIMESTAMP}.sql
5. Extract and upload files to AWS web server:
   tar -xzf wordpress-files-${TIMESTAMP}.tar.gz -C /var/www/html/
6. Update wp-config.php with new database credentials
7. Update site URLs in database if domain changed:
   UPDATE wp_options SET option_value='https://newdomain.com' WHERE option_name='siteurl';
   UPDATE wp_options SET option_value='https://newdomain.com' WHERE option_name='home';
8. Set proper file permissions on AWS
9. Test website functionality
10. Update DNS to point to AWS

================================================================================
EOF

    print_success "Export notes created: ${NOTES_FILE}"
}

################################################################################
# Checksum Functions
################################################################################

generate_checksums() {
    print_header "Generating Checksums"

    CHECKSUM_FILE="${EXPORT_DIR}/CHECKSUMS-${TIMESTAMP}.txt"
    print_info "Creating SHA256 checksums..."

    cd "${EXPORT_DIR}"

    # Generate checksums for all export files
    local files_to_checksum="wordpress-db-${TIMESTAMP}.sql"

    if [[ -n "$ARCHIVE_FILE" ]] && [[ -f "wordpress-files-${TIMESTAMP}.tar.gz" ]]; then
        files_to_checksum="${files_to_checksum} wordpress-files-${TIMESTAMP}.tar.gz"
    fi

    sha256sum ${files_to_checksum} > "${CHECKSUM_FILE}" || error_exit "Checksum generation failed"

    cd - > /dev/null

    print_success "Checksums generated: ${CHECKSUM_FILE}"
}

################################################################################
# Package Functions
################################################################################

create_final_package() {
    print_header "Creating Final Export Package"

    FINAL_PACKAGE="exports-${WEBSITE_NAME}-${TIMESTAMP}.tar.gz"
    print_info "Creating final package: ~/${FINAL_PACKAGE}..."

    cd ~
    tar -czf "${FINAL_PACKAGE}" "$(basename ${EXPORT_DIR})" || error_exit "Failed to create final package"

    local package_size=$(ls -lh ~/"${FINAL_PACKAGE}" | awk '{print $5}')
    print_success "Final package created: ~/${FINAL_PACKAGE} (${package_size})"

    cd - > /dev/null
}

################################################################################
# Final Report Functions
################################################################################

generate_final_report() {
    print_header "Export Complete"

    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  WordPress Export Successful!${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "Website: ${BLUE}${WEBSITE_NAME}${NC}"
    echo -e "Export Directory: ${BLUE}${EXPORT_DIR}${NC}"
    echo -e "Final Package: ${BLUE}~/${FINAL_PACKAGE}${NC}"
    echo ""
    echo -e "${YELLOW}Files Created:${NC}"
    echo -e "  • Database: wordpress-db-${TIMESTAMP}.sql"

    if [[ -n "$ARCHIVE_FILE" ]]; then
        echo -e "  • Archive: wordpress-files-${TIMESTAMP}.tar.gz"
    else
        echo -e "  • Archive: ${YELLOW}Skipped (--skip-archive mode)${NC}"
    fi

    echo -e "  • Checksums: CHECKSUMS-${TIMESTAMP}.txt"
    echo -e "  • Export Notes: EXPORT-NOTES-${TIMESTAMP}.txt"
    echo ""
    echo -e "${YELLOW}Download to Local Machine:${NC}"
    echo -e "  ${BLUE}scp -P 2222 $(whoami)@$(hostname -f 2>/dev/null || echo "$(hostname)"):~/${FINAL_PACKAGE} .${NC}"
    echo ""
    echo -e "${YELLOW}Or download individual files:${NC}"
    echo -e "  ${BLUE}scp -P 2222 $(whoami)@$(hostname -f 2>/dev/null || echo "$(hostname)"):~/${EXPORT_DIR}/* .${NC}"
    echo ""
    echo -e "${YELLOW}Verify Checksums (after download):${NC}"
    echo -e "  cd ${EXPORT_DIR}"
    echo -e "  sha256sum -c CHECKSUMS-${TIMESTAMP}.txt"
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo -e "  1. Download exports to your local machine (command above)"
    echo -e "  2. Verify checksums"
    echo -e "  3. Review export notes: cat ${EXPORT_DIR}/EXPORT-NOTES-${TIMESTAMP}.txt"
    echo -e "  4. Prepare AWS environment"
    echo -e "  5. Import database and upload files to AWS"
    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
}

################################################################################
# Main Execution
################################################################################

main() {
    clear

    echo -e "${BLUE}"
    cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║    WordPress Local Export - Run on Xneelo Server Directly   ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"

    # Parse command-line arguments
    parse_arguments "$@"

    # Display configuration
    print_header "Export Configuration"
    echo -e "Website Name:    ${GREEN}${WEBSITE_NAME}${NC}"
    echo -e "WordPress Root:  ${GREEN}${WP_ROOT:-"Auto-detect"}${NC}"
    echo -e "Skip Archive:    ${GREEN}${SKIP_ARCHIVE}${NC}"
    echo -e "Timestamp:       ${GREEN}${TIMESTAMP}${NC}"
    echo ""

    # Create export directory
    EXPORT_DIR="${HOME}/exports-${WEBSITE_NAME}-${TIMESTAMP}"
    mkdir -p "${EXPORT_DIR}"
    print_success "Created export directory: ${EXPORT_DIR}"

    # Execute export workflow
    find_wordpress_root
    verify_wordpress_installation
    extract_database_credentials
    export_database
    archive_wordpress_files
    collect_environment_info
    generate_checksums
    create_final_package
    generate_final_report

    exit 0
}

# Run main function with all arguments
main "$@"