#!/bin/bash
##############################################################################
# Manufacturing-Websites Migration Script
# Purpose: Import WordPress from S3 exports to AWS ECS/Fargate platform
# Run this script ON THE BASTION HOST
#
# Source: s3://wordpress-migration-temp-20250903/manufacturing/
# Target: DEV environment (manufacturing.wpdev.kimmyai.io)
##############################################################################

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
TENANT_ID="manufacturing"
ENVIRONMENT="dev"
OLD_DOMAIN="manufacturing-websites.com"
NEW_DOMAIN="manufacturing.wpdev.kimmyai.io"
TEST_EMAIL="tebogo@bigbeard.co.za"
S3_BUCKET="s3://wordpress-migration-temp-20250903/manufacturing"
AWS_REGION="eu-west-1"

# RDS Configuration
RDS_HOST="dev-mysql.c9ko42mci6mt.eu-west-1.rds.amazonaws.com"
RDS_MASTER_USER="admin"
RDS_MASTER_PASS="LkuqJEVktoYvdWN9VVM0tPMbCXTJVo3y"

# Tenant Database
DB_NAME="manufacturing_db"
DB_USER="manufacturing_user"
DB_PASS="h8SwtMjSLBTRGVOGQbc4gDOX"

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
echo "  Manufacturing-Websites Migration to AWS"
echo "========================================================================"
echo "Tenant: $TENANT_ID"
echo "Environment: $ENVIRONMENT"
echo "Target URL: https://${NEW_DOMAIN}"
echo "Test Email: $TEST_EMAIL"
echo "========================================================================"
echo ""

##############################################################################
# PHASE 1: Download from S3
##############################################################################
echo "========================================================================"
echo "Phase 1: Download from S3"
echo "========================================================================"

log "Downloading database export..."
aws s3 cp ${S3_BUCKET}/wordpress-db-20260113_075835.sql ${WORK_DIR}/database.sql --region ${AWS_REGION}
ls -lh ${WORK_DIR}/database.sql

log "Downloading files archive..."
aws s3 cp ${S3_BUCKET}/wordpress-files-20260113_075835.tar.gz ${WORK_DIR}/files.tar.gz --region ${AWS_REGION}
ls -lh ${WORK_DIR}/files.tar.gz

echo -e "${GREEN}✅ Phase 1 complete - Files downloaded${NC}"
echo ""

##############################################################################
# PHASE 2: Database Migration
##############################################################################
echo "========================================================================"
echo "Phase 2: Database Migration"
echo "========================================================================"

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

log "Importing database (this may take a few minutes)..."
mysql -h "${RDS_HOST}" -u "${RDS_MASTER_USER}" -p"${RDS_MASTER_PASS}" "${DB_NAME}" < ${WORK_DIR}/database.sql

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

-- Update content URLs
UPDATE wp_posts SET post_content = REPLACE(post_content, 'http://${OLD_DOMAIN}', 'https://${NEW_DOMAIN}');
UPDATE wp_posts SET post_content = REPLACE(post_content, 'https://${OLD_DOMAIN}', 'https://${NEW_DOMAIN}');
UPDATE wp_posts SET guid = REPLACE(guid, 'http://${OLD_DOMAIN}', 'https://${NEW_DOMAIN}');
UPDATE wp_posts SET guid = REPLACE(guid, 'https://${OLD_DOMAIN}', 'https://${NEW_DOMAIN}');
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
    /usr/local/bin/migration-helpers/mount-efs.sh || true
fi

log "Creating tenant directory..."
sudo mkdir -p "${TENANT_PATH}"

log "Extracting files archive..."
cd ${WORK_DIR}
tar -xzf files.tar.gz

log "Copying files to EFS..."
# Handle different archive structures
if [ -d "wp-content" ]; then
    sudo rsync -avz wp-content/ ${TENANT_PATH}/
elif [ -d "public_html/wp-content" ]; then
    sudo rsync -avz public_html/wp-content/ ${TENANT_PATH}/
else
    # Find wp-content directory
    WP_CONTENT_DIR=$(find . -type d -name "wp-content" | head -1)
    if [ -n "$WP_CONTENT_DIR" ]; then
        sudo rsync -avz ${WP_CONTENT_DIR}/ ${TENANT_PATH}/
    else
        error "Could not find wp-content directory in archive"
    fi
fi

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
echo "Next Steps:"
echo "1. Test the site at https://${NEW_DOMAIN}"
echo "2. Submit forms to verify email redirect"
echo "3. Check all pages render correctly"
echo "4. Run validation script: ./validate-migration.sh https://${NEW_DOMAIN}"
echo ""

# Cleanup
log "Cleaning up temporary files..."
rm -rf ${WORK_DIR}

echo "Done!"
