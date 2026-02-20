#!/bin/bash
##############################################################################
# Lynfin (Lynnwood Wealth) Migration Script
# Purpose: Import WordPress from S3 7z export to AWS ECS/Fargate platform
# Run this script ON THE BASTION HOST
#
# Source: s3://wordpress-migration-temp-20250903/Lynfin/lynnwood-wealth.7z
# Target: DEV environment (lynfin.wpdev.kimmyai.io)
##############################################################################

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
TENANT_ID="lynfin"
ENVIRONMENT="dev"
NEW_DOMAIN="lynfin.wpdev.kimmyai.io"
OLD_DOMAIN="lynfin.personalinvest.co.za"
TEST_EMAIL="tebogo@bigbeard.co.za"
S3_BUCKET="s3://wordpress-migration-temp-20250903/Lynfin"
S3_FILES_ARCHIVE="lynnwood-wealth.7z"
S3_SQL_FILE="lynwoodwealth.sql"
AWS_REGION="eu-west-1"

# RDS Configuration (from dev-rds-master-credentials)
RDS_HOST="dev-mysql.c9ko42mci6mt.eu-west-1.rds.amazonaws.com"
RDS_MASTER_USER="admin"
RDS_MASTER_PASS="LkuqJEVktoYvdWN9VVM0tPMbCXTJVo3y"

# Tenant Database
DB_NAME="lynfin_db"
DB_USER="lynfin_user"
DB_PASS="LynfinSecure2026$(openssl rand -hex 4)"

# EFS Mount
EFS_MOUNT="/mnt/efs"
TENANT_PATH="${EFS_MOUNT}/${TENANT_ID}"

# Working directory
WORK_DIR="/tmp/migration-${TENANT_ID}"
mkdir -p "$WORK_DIR"

log() { echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"; }
warn() { echo -e "${YELLOW}[$(date +'%H:%M:%S')] WARNING:${NC} $1"; }
error() { echo -e "${RED}[$(date +'%H:%M:%S')] ERROR:${NC} $1"; exit 1; }

echo "========================================================================"
echo "  Lynfin (Lynnwood Wealth) Migration to AWS"
echo "========================================================================"
echo "Tenant: $TENANT_ID"
echo "Environment: $ENVIRONMENT"
echo "Target URL: https://${NEW_DOMAIN}"
echo "Test Email: $TEST_EMAIL"
echo "========================================================================"
echo ""

##############################################################################
# PHASE 1: Download and Extract from S3
##############################################################################
echo "========================================================================"
echo "Phase 1: Download and Extract from S3"
echo "========================================================================"

log "Downloading SQL file from S3..."
aws s3 cp ${S3_BUCKET}/${S3_SQL_FILE} ${WORK_DIR}/${S3_SQL_FILE} --region ${AWS_REGION}
SQL_FILE="${WORK_DIR}/${S3_SQL_FILE}"
ls -lh ${SQL_FILE}

log "Downloading 7z files archive from S3..."
aws s3 cp ${S3_BUCKET}/${S3_FILES_ARCHIVE} ${WORK_DIR}/${S3_FILES_ARCHIVE} --region ${AWS_REGION}
ls -lh ${WORK_DIR}/${S3_FILES_ARCHIVE}

log "Installing 7z if needed..."
which 7z > /dev/null 2>&1 || sudo yum install -y p7zip p7zip-plugins || sudo apt-get install -y p7zip-full

log "Extracting 7z archive (this may take a few minutes)..."
cd ${WORK_DIR}
7z x ${S3_FILES_ARCHIVE} -o./extracted/ -y

log "Analyzing archive contents..."
echo ""
echo "=== Archive Structure ==="
ls -la ./extracted/
echo ""

# Find wp-content
log "Looking for wp-content..."
WP_CONTENT=$(find ./extracted -name "wp-content" -type d 2>/dev/null | head -1)
if [ -n "$WP_CONTENT" ]; then
    echo "Found wp-content: $WP_CONTENT"
    du -sh "$WP_CONTENT"
else
    warn "No wp-content found. Looking for uploads/themes..."
    find ./extracted -type d -name "uploads" -o -type d -name "themes" | head -5
fi

echo ""
echo "OLD_DOMAIN: $OLD_DOMAIN"
echo "NEW_DOMAIN: $NEW_DOMAIN"
echo ""

echo -e "${GREEN}✅ Phase 1 complete - Files extracted${NC}"
echo ""

##############################################################################
# PHASE 2: Database Migration
##############################################################################
echo "========================================================================"
echo "Phase 2: Database Migration"
echo "========================================================================"

log "Using SQL file: $SQL_FILE"

# Generate tenant DB password
DB_PASS="Lynfin$(openssl rand -hex 8 2>/dev/null || echo "Secure2026Pass")"
echo "Generated DB credentials:"
echo "  Database: $DB_NAME"
echo "  User: $DB_USER"
echo "  Password: $DB_PASS"
echo ""

log "Creating database and user..."
mysql -h "${RDS_HOST}" -u "${RDS_MASTER_USER}" -p"${RDS_MASTER_PASS}" <<EOSQL
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_520_ci;

CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'%';
FLUSH PRIVILEGES;

SELECT 'Database and user created successfully!' AS Status;
EOSQL

log "Importing database (this may take several minutes for large databases)..."
mysql -h "${RDS_HOST}" -u "${RDS_MASTER_USER}" -p"${RDS_MASTER_PASS}" "${DB_NAME}" < "$SQL_FILE"

log "Applying UTF-8 encoding fixes..."
mysql -h "${RDS_HOST}" -u "${DB_USER}" -p"${DB_PASS}" "${DB_NAME}" <<EOSQL
-- Fix common encoding artifacts
UPDATE wp_posts SET post_content = REPLACE(post_content, 'Â', '') WHERE post_content LIKE '%Â%';
UPDATE wp_posts SET post_content = REPLACE(post_content, 'â€™', "'") WHERE post_content LIKE '%â€™%';
UPDATE wp_posts SET post_content = REPLACE(post_content, 'â€œ', '"') WHERE post_content LIKE '%â€œ%';
UPDATE wp_posts SET post_content = REPLACE(post_content, 'â€', '"') WHERE post_content LIKE '%â€%';
UPDATE wp_posts SET post_content = REPLACE(post_content, 'â€"', '–') WHERE post_content LIKE '%â€"%';
UPDATE wp_posts SET post_title = REPLACE(post_title, 'Â', '') WHERE post_title LIKE '%Â%';
UPDATE wp_postmeta SET meta_value = REPLACE(meta_value, 'Â', '') WHERE meta_value LIKE '%Â%';

SELECT 'Encoding fixes applied!' AS Status;
EOSQL

log "Updating site URLs..."
mysql -h "${RDS_HOST}" -u "${DB_USER}" -p"${DB_PASS}" "${DB_NAME}" <<EOSQL
-- Update WordPress URLs
UPDATE wp_options SET option_value = 'https://${NEW_DOMAIN}' WHERE option_name = 'siteurl';
UPDATE wp_options SET option_value = 'https://${NEW_DOMAIN}' WHERE option_name = 'home';

-- Update content URLs (if OLD_DOMAIN is known)
UPDATE wp_posts SET post_content = REPLACE(post_content, 'http://${OLD_DOMAIN}', 'https://${NEW_DOMAIN}') WHERE post_content LIKE '%${OLD_DOMAIN}%';
UPDATE wp_posts SET post_content = REPLACE(post_content, 'https://${OLD_DOMAIN}', 'https://${NEW_DOMAIN}') WHERE post_content LIKE '%${OLD_DOMAIN}%';
UPDATE wp_posts SET guid = REPLACE(guid, 'http://${OLD_DOMAIN}', 'https://${NEW_DOMAIN}') WHERE guid LIKE '%${OLD_DOMAIN}%';
UPDATE wp_posts SET guid = REPLACE(guid, 'https://${OLD_DOMAIN}', 'https://${NEW_DOMAIN}') WHERE guid LIKE '%${OLD_DOMAIN}%';
UPDATE wp_postmeta SET meta_value = REPLACE(meta_value, 'http://${OLD_DOMAIN}', 'https://${NEW_DOMAIN}') WHERE meta_value LIKE '%${OLD_DOMAIN}%';
UPDATE wp_postmeta SET meta_value = REPLACE(meta_value, 'https://${OLD_DOMAIN}', 'https://${NEW_DOMAIN}') WHERE meta_value LIKE '%${OLD_DOMAIN}%';

-- Verify
SELECT option_name, option_value FROM wp_options WHERE option_name IN ('siteurl', 'home');
EOSQL

echo -e "${GREEN}✅ Phase 2 complete - Database migrated${NC}"
echo ""

##############################################################################
# PHASE 3: Files Migration
##############################################################################
echo "========================================================================"
echo "Phase 3: Files Migration"
echo "========================================================================"

log "Mounting EFS (if not already mounted)..."
if ! mountpoint -q "${EFS_MOUNT}"; then
    if [ -f "/usr/local/bin/migration-helpers/mount-efs.sh" ]; then
        /usr/local/bin/migration-helpers/mount-efs.sh || true
    else
        # Try manual mount
        EFS_ID=$(aws efs describe-file-systems --query 'FileSystems[0].FileSystemId' --output text --region ${AWS_REGION} 2>/dev/null || echo "")
        if [ -n "$EFS_ID" ] && [ "$EFS_ID" != "None" ]; then
            sudo mkdir -p ${EFS_MOUNT}
            sudo mount -t efs ${EFS_ID}:/ ${EFS_MOUNT} 2>/dev/null || \
            sudo mount -t nfs4 -o nfsvers=4.1 ${EFS_ID}.efs.${AWS_REGION}.amazonaws.com:/ ${EFS_MOUNT}
        fi
    fi
fi

if mountpoint -q "${EFS_MOUNT}"; then
    log "EFS mounted at ${EFS_MOUNT}"
else
    warn "EFS not mounted. Please mount manually and press Enter..."
    read -p "Press Enter when EFS is mounted at ${EFS_MOUNT}..."
fi

log "Creating tenant directory..."
sudo mkdir -p "${TENANT_PATH}"

log "Locating wp-content..."
if [ -z "$WP_CONTENT" ]; then
    WP_CONTENT=$(find ./extracted -name "wp-content" -type d 2>/dev/null | head -1)
fi

if [ -z "$WP_CONTENT" ]; then
    # Try alternative structures
    if [ -d "./extracted/public_html/wp-content" ]; then
        WP_CONTENT="./extracted/public_html/wp-content"
    elif [ -d "./extracted/htdocs/wp-content" ]; then
        WP_CONTENT="./extracted/htdocs/wp-content"
    elif [ -d "./extracted/www/wp-content" ]; then
        WP_CONTENT="./extracted/www/wp-content"
    fi
fi

if [ -z "$WP_CONTENT" ]; then
    error "Could not find wp-content directory. Please locate manually."
fi

log "Copying files from $WP_CONTENT to EFS..."
sudo rsync -avz "${WP_CONTENT}/" "${TENANT_PATH}/"

log "Setting permissions..."
sudo chown -R 33:33 ${TENANT_PATH}/
sudo find ${TENANT_PATH}/ -type d -exec chmod 755 {} \;
sudo find ${TENANT_PATH}/ -type f -exec chmod 644 {} \;

log "Verifying files..."
ls -la ${TENANT_PATH}/
du -sh ${TENANT_PATH}/

echo -e "${GREEN}✅ Phase 3 complete - Files uploaded to EFS${NC}"
echo ""

##############################################################################
# PHASE 4: Deploy MU-Plugins
##############################################################################
echo "========================================================================"
echo "Phase 4: Deploy MU-Plugins"
echo "========================================================================"

log "Creating mu-plugins directory..."
sudo mkdir -p ${TENANT_PATH}/mu-plugins

log "Deploying force-https.php..."
sudo cat > ${TENANT_PATH}/mu-plugins/force-https.php <<'EOPHP'
<?php
/**
 * Plugin Name: BBWS Platform - Force HTTPS
 * Description: Forces all URLs to use HTTPS
 */
add_filter('script_loader_src', 'bbws_force_https');
add_filter('style_loader_src', 'bbws_force_https');
add_filter('the_content', 'bbws_force_https_content');

function bbws_force_https($url) {
    return str_replace('http://', 'https://', $url);
}
function bbws_force_https_content($content) {
    return str_replace('http://', 'https://', $content);
}
EOPHP

log "Deploying test-email-redirect.php..."
sudo cat > ${TENANT_PATH}/mu-plugins/test-email-redirect.php <<EOPHP
<?php
/**
 * Plugin Name: BBWS Platform - Test Email Redirect
 * Description: Redirects all emails to test address in non-production
 */
if (!defined('WP_ENV') || WP_ENV !== 'production') {
    add_filter('wp_mail', 'bbws_redirect_test_emails');
}

function bbws_redirect_test_emails(\$args) {
    \$test_email = defined('TEST_EMAIL_REDIRECT') ? TEST_EMAIL_REDIRECT : '${TEST_EMAIL}';
    \$env = defined('WP_ENV') ? strtoupper(WP_ENV) : 'DEV';
    \$original_to = is_array(\$args['to']) ? implode(', ', \$args['to']) : \$args['to'];

    \$args['subject'] = "[TEST - {\$env}] " . \$args['subject'];
    \$args['message'] = "TEST EMAIL - {\$env} ENVIRONMENT\n" .
                       "Original Recipient: {\$original_to}\n" .
                       "Redirected To: {\$test_email}\n\n" .
                       "--- ORIGINAL MESSAGE ---\n\n" .
                       \$args['message'];
    \$args['to'] = \$test_email;
    return \$args;
}
EOPHP

log "Deploying environment-indicator.php..."
sudo cat > ${TENANT_PATH}/mu-plugins/environment-indicator.php <<'EOPHP'
<?php
/**
 * Plugin Name: BBWS Platform - Environment Indicator
 * Description: Shows environment indicator in admin bar and frontend
 */
if (!defined('WP_ENV') || WP_ENV !== 'production') {
    add_action('wp_footer', 'bbws_environment_banner');
    add_action('admin_bar_menu', 'bbws_admin_bar_indicator', 100);
    add_action('wp_head', 'bbws_console_message');
}

function bbws_environment_banner() {
    $env = defined('WP_ENV') ? strtoupper(WP_ENV) : 'DEV';
    $test_email = defined('TEST_EMAIL_REDIRECT') ? TEST_EMAIL_REDIRECT : 'tebogo@bigbeard.co.za';
    echo '<div style="position:fixed;bottom:0;left:0;right:0;background:#ff6b35;color:white;padding:10px;text-align:center;z-index:99999;font-family:sans-serif;">';
    echo "🚧 {$env} ENVIRONMENT 🚧 Testing Mode Active • Emails → {$test_email}";
    echo '</div>';
}

function bbws_admin_bar_indicator($wp_admin_bar) {
    $env = defined('WP_ENV') ? strtoupper(WP_ENV) : 'DEV';
    $wp_admin_bar->add_node(['id' => 'bbws-env-indicator', 'title' => "🚧 {$env} ENVIRONMENT"]);
}

function bbws_console_message() {
    $env = defined('WP_ENV') ? strtoupper(WP_ENV) : 'DEV';
    echo "<script>console.log('🚧 {$env} ENVIRONMENT - TRACKING MOCKED 🚧');</script>";
}
EOPHP

log "Setting MU-plugin permissions..."
sudo chown 33:33 ${TENANT_PATH}/mu-plugins/*.php
sudo chmod 644 ${TENANT_PATH}/mu-plugins/*.php

log "Verifying MU-plugins..."
ls -la ${TENANT_PATH}/mu-plugins/

echo -e "${GREEN}✅ Phase 4 complete - MU-plugins deployed${NC}"
echo ""

##############################################################################
# PHASE 5: Clear Caches
##############################################################################
echo "========================================================================"
echo "Phase 5: Clear Caches"
echo "========================================================================"

log "Clearing WordPress transients..."
mysql -h "${RDS_HOST}" -u "${DB_USER}" -p"${DB_PASS}" "${DB_NAME}" <<EOSQL
DELETE FROM wp_options WHERE option_name LIKE '%_transient_%';
DELETE FROM wp_options WHERE option_name LIKE '%_cache_%';
SELECT 'Transients cleared!' AS Status;
EOSQL

echo -e "${GREEN}✅ Phase 5 complete - Caches cleared${NC}"
echo ""

##############################################################################
# PHASE 6: Validation
##############################################################################
echo "========================================================================"
echo "Phase 6: Validation"
echo "========================================================================"

log "Verifying database..."
mysql -h "${RDS_HOST}" -u "${DB_USER}" -p"${DB_PASS}" "${DB_NAME}" <<EOSQL
SELECT
    (SELECT COUNT(*) FROM wp_posts WHERE post_status = 'publish') as published_posts,
    (SELECT COUNT(*) FROM wp_users) as users,
    (SELECT option_value FROM wp_options WHERE option_name = 'siteurl') as site_url;
EOSQL

log "Verifying EFS files..."
echo "Total size:"
du -sh ${TENANT_PATH}/
echo ""
echo "Directory structure:"
ls -la ${TENANT_PATH}/

echo ""
echo "========================================================================"
echo -e "${GREEN}✅ MIGRATION COMPLETE!${NC}"
echo "========================================================================"
echo ""
echo "Site URL: https://${NEW_DOMAIN}"
echo "Test Email: ${TEST_EMAIL}"
echo ""
echo "Database Credentials (save these!):"
echo "  Host: ${RDS_HOST}"
echo "  Database: ${DB_NAME}"
echo "  User: ${DB_USER}"
echo "  Password: ${DB_PASS}"
echo ""
echo "Next Steps:"
echo "1. Test the site at https://${NEW_DOMAIN}"
echo "2. Submit forms to verify email redirect"
echo "3. Check all pages render correctly"
echo "4. Run validation script"
echo ""

# Save credentials to file
cat > ${WORK_DIR}/credentials.txt <<EOF
Lynfin WordPress Migration - Database Credentials
=================================================
Generated: $(date)

RDS Host: ${RDS_HOST}
Database: ${DB_NAME}
Username: ${DB_USER}
Password: ${DB_PASS}

Site URL: https://${NEW_DOMAIN}
EOF

log "Credentials saved to: ${WORK_DIR}/credentials.txt"
echo ""

# Cleanup option
read -p "Clean up temporary files? (y/n): " CLEANUP
if [ "$CLEANUP" = "y" ] || [ "$CLEANUP" = "Y" ]; then
    log "Cleaning up temporary files..."
    rm -rf ${WORK_DIR}/extracted
    rm -f ${WORK_DIR}/${S3_FILES_ARCHIVE}
    rm -f ${WORK_DIR}/${S3_SQL_FILE}
    echo "Kept: ${WORK_DIR}/credentials.txt"
fi

echo ""
echo "Done!"
