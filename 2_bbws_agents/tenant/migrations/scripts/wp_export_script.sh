#!/bin/bash
#
# Au Pair Hive WordPress Export Script
# Uses WP-CLI to export all site data
#
# Usage:
#   1. SSH into aupairhive.com server
#   2. Navigate to WordPress root directory
#   3. Run: bash wp_export_script.sh
#

set -e  # Exit on error

# Configuration
EXPORT_DATE=$(date +%Y%m%d_%H%M%S)
EXPORT_DIR="aupairhive_export_${EXPORT_DATE}"
SITE_URL="aupairhive.com"

echo "=========================================="
echo "Au Pair Hive WordPress Export"
echo "Date: $(date)"
echo "=========================================="
echo ""

# Create export directory
echo "Creating export directory: ${EXPORT_DIR}"
mkdir -p "${EXPORT_DIR}"
cd "${EXPORT_DIR}"

# 1. EXPORT DATABASE
echo ""
echo "=========================================="
echo "1. Exporting Database..."
echo "=========================================="
wp db export aupairhive_database_${EXPORT_DATE}.sql --path=../ --allow-root
echo "✅ Database exported: aupairhive_database_${EXPORT_DATE}.sql"
DB_SIZE=$(du -h aupairhive_database_${EXPORT_DATE}.sql | cut -f1)
echo "   Size: ${DB_SIZE}"

# 2. GET WORDPRESS INFO
echo ""
echo "=========================================="
echo "2. Collecting WordPress Information..."
echo "=========================================="

# WordPress version
WP_VERSION=$(wp core version --path=../ --allow-root)
echo "WordPress Version: ${WP_VERSION}" > wordpress_info.txt

# Site URL
SITE_URL=$(wp option get siteurl --path=../ --allow-root)
echo "Site URL: ${SITE_URL}" >> wordpress_info.txt

# Home URL
HOME_URL=$(wp option get home --path=../ --allow-root)
echo "Home URL: ${HOME_URL}" >> wordpress_info.txt

# Permalink structure
PERMALINK=$(wp option get permalink_structure --path=../ --allow-root)
echo "Permalink Structure: ${PERMALINK}" >> wordpress_info.txt

# PHP version
PHP_VERSION=$(php -v | head -n 1)
echo "PHP Version: ${PHP_VERSION}" >> wordpress_info.txt

echo "✅ WordPress info saved: wordpress_info.txt"

# 3. EXPORT PLUGIN LIST
echo ""
echo "=========================================="
echo "3. Exporting Plugin List..."
echo "=========================================="
wp plugin list --format=json --path=../ --allow-root > plugins.json
wp plugin list --format=table --path=../ --allow-root > plugins.txt
PLUGIN_COUNT=$(wp plugin list --format=count --status=active --path=../ --allow-root)
echo "✅ Active plugins: ${PLUGIN_COUNT}"
echo "   Saved to: plugins.json, plugins.txt"

# 4. EXPORT THEME INFO
echo ""
echo "=========================================="
echo "4. Exporting Theme Information..."
echo "=========================================="
wp theme list --format=json --path=../ --allow-root > themes.json
wp theme list --format=table --path=../ --allow-root > themes.txt
ACTIVE_THEME=$(wp theme list --status=active --field=name --path=../ --allow-root)
echo "✅ Active theme: ${ACTIVE_THEME}"
echo "   Saved to: themes.json, themes.txt"

# 5. EXPORT USERS
echo ""
echo "=========================================="
echo "5. Exporting User List..."
echo "=========================================="
wp user list --format=json --path=../ --allow-root > users.json
wp user list --format=table --path=../ --allow-root > users.txt
USER_COUNT=$(wp user list --format=count --path=../ --allow-root)
echo "✅ Total users: ${USER_COUNT}"
echo "   Saved to: users.json, users.txt"

# 6. EXPORT POSTS/PAGES COUNT
echo ""
echo "=========================================="
echo "6. Collecting Content Statistics..."
echo "=========================================="
POST_COUNT=$(wp post list --post_type=post --format=count --path=../ --allow-root)
PAGE_COUNT=$(wp post list --post_type=page --format=count --path=../ --allow-root)
echo "Posts: ${POST_COUNT}" > content_stats.txt
echo "Pages: ${PAGE_COUNT}" >> content_stats.txt
echo "✅ Posts: ${POST_COUNT}, Pages: ${PAGE_COUNT}"

# 7. EXTRACT LICENSE KEYS (if stored in options)
echo ""
echo "=========================================="
echo "7. Extracting License Keys and API Keys..."
echo "=========================================="

# Divi license
echo "=== DIVI LICENSE ===" > licenses_and_keys.txt
wp option get et_automatic_updates_options --format=json --path=../ --allow-root >> licenses_and_keys.txt 2>/dev/null || echo "Not found in options table" >> licenses_and_keys.txt
echo "" >> licenses_and_keys.txt

# Gravity Forms license
echo "=== GRAVITY FORMS LICENSE ===" >> licenses_and_keys.txt
wp option get rg_gforms_key --path=../ --allow-root >> licenses_and_keys.txt 2>/dev/null || echo "Not found in options table" >> licenses_and_keys.txt
echo "" >> licenses_and_keys.txt

# reCAPTCHA keys
echo "=== RECAPTCHA KEYS ===" >> licenses_and_keys.txt
wp option get gf_recaptcha_keys --format=json --path=../ --allow-root >> licenses_and_keys.txt 2>/dev/null || echo "Check Gravity Forms settings manually" >> licenses_and_keys.txt
echo "" >> licenses_and_keys.txt

echo "✅ License keys extracted (verify manually): licenses_and_keys.txt"

# 8. EXPORT OPTIONS (critical settings)
echo ""
echo "=========================================="
echo "8. Exporting Critical Options..."
echo "=========================================="
wp option list --format=json --path=../ --allow-root > all_options.json
echo "✅ All options exported: all_options.json"

# 9. SITE HEALTH CHECK
echo ""
echo "=========================================="
echo "9. Running Site Health Check..."
echo "=========================================="
wp site health --format=json --path=../ --allow-root > site_health.json 2>/dev/null || echo "Site health check skipped (requires WP 5.2+)"

# 10. EXPORT UPLOADS DIRECTORY INFO
echo ""
echo "=========================================="
echo "10. Analyzing Uploads Directory..."
echo "=========================================="
if [ -d "../wp-content/uploads" ]; then
    UPLOAD_SIZE=$(du -sh ../wp-content/uploads | cut -f1)
    UPLOAD_COUNT=$(find ../wp-content/uploads -type f | wc -l)
    echo "Uploads Directory Size: ${UPLOAD_SIZE}" > uploads_info.txt
    echo "Total Files: ${UPLOAD_COUNT}" >> uploads_info.txt
    echo "✅ Uploads: ${UPLOAD_SIZE} (${UPLOAD_COUNT} files)"
else
    echo "No uploads directory found" > uploads_info.txt
fi

# 11. CREATE ARCHIVE OF UPLOADS (optional - can be large)
echo ""
echo "=========================================="
echo "11. Creating Uploads Archive..."
echo "=========================================="
if [ -d "../wp-content/uploads" ]; then
    echo "Creating tar.gz of uploads directory..."
    tar -czf aupairhive_uploads_${EXPORT_DATE}.tar.gz -C ../wp-content uploads/
    UPLOAD_ARCHIVE_SIZE=$(du -h aupairhive_uploads_${EXPORT_DATE}.tar.gz | cut -f1)
    echo "✅ Uploads archived: aupairhive_uploads_${EXPORT_DATE}.tar.gz (${UPLOAD_ARCHIVE_SIZE})"
else
    echo "⚠️  Uploads directory not found, skipping..."
fi

# 12. ARCHIVE THEMES (custom themes only)
echo ""
echo "=========================================="
echo "12. Archiving Custom Themes..."
echo "=========================================="
if [ -d "../wp-content/themes" ]; then
    tar -czf aupairhive_themes_${EXPORT_DATE}.tar.gz -C ../wp-content themes/
    THEMES_SIZE=$(du -h aupairhive_themes_${EXPORT_DATE}.tar.gz | cut -f1)
    echo "✅ Themes archived: aupairhive_themes_${EXPORT_DATE}.tar.gz (${THEMES_SIZE})"
fi

# 13. ARCHIVE PLUGINS
echo ""
echo "=========================================="
echo "13. Archiving Plugins..."
echo "=========================================="
if [ -d "../wp-content/plugins" ]; then
    tar -czf aupairhive_plugins_${EXPORT_DATE}.tar.gz -C ../wp-content plugins/
    PLUGINS_SIZE=$(du -h aupairhive_plugins_${EXPORT_DATE}.tar.gz | cut -f1)
    echo "✅ Plugins archived: aupairhive_plugins_${EXPORT_DATE}.tar.gz (${PLUGINS_SIZE})"
fi

# 14. COPY WP-CONFIG.PHP (for reference)
echo ""
echo "=========================================="
echo "14. Backing up wp-config.php..."
echo "=========================================="
if [ -f "../wp-config.php" ]; then
    cp ../wp-config.php wp-config.php.backup
    # Remove sensitive data for security
    sed -i.bak "s/define( 'DB_PASSWORD'.*/define( 'DB_PASSWORD', '***REDACTED***' );/" wp-config.php.backup
    echo "✅ wp-config.php backed up (passwords redacted)"
fi

# 15. CREATE EXPORT SUMMARY
echo ""
echo "=========================================="
echo "15. Creating Export Summary..."
echo "=========================================="

cat > EXPORT_SUMMARY.txt <<EOL
========================================
Au Pair Hive WordPress Export Summary
========================================
Export Date: $(date)
Export Directory: ${EXPORT_DIR}

WordPress Information:
- Version: ${WP_VERSION}
- Site URL: ${SITE_URL}
- Home URL: ${HOME_URL}
- Permalink: ${PERMALINK}

Content Statistics:
- Posts: ${POST_COUNT}
- Pages: ${PAGE_COUNT}
- Users: ${USER_COUNT}
- Active Plugins: ${PLUGIN_COUNT}
- Active Theme: ${ACTIVE_THEME}

Files Exported:
1. Database:
   - aupairhive_database_${EXPORT_DATE}.sql (${DB_SIZE})

2. Configuration Files:
   - wordpress_info.txt
   - plugins.json, plugins.txt
   - themes.json, themes.txt
   - users.json, users.txt
   - content_stats.txt
   - licenses_and_keys.txt
   - all_options.json
   - site_health.json
   - uploads_info.txt
   - wp-config.php.backup

3. Archive Files:
   - aupairhive_uploads_${EXPORT_DATE}.tar.gz (${UPLOAD_ARCHIVE_SIZE:-N/A})
   - aupairhive_themes_${EXPORT_DATE}.tar.gz (${THEMES_SIZE:-N/A})
   - aupairhive_plugins_${EXPORT_DATE}.tar.gz (${PLUGINS_SIZE:-N/A})

Next Steps:
1. Download this entire directory to your local machine
2. Verify all files are present and not corrupted
3. Proceed to Phase 3: DEV Environment Provisioning

========================================
EOL

echo "✅ Export summary created: EXPORT_SUMMARY.txt"

# 16. CALCULATE TOTAL SIZE
echo ""
echo "=========================================="
echo "16. Calculating Total Export Size..."
echo "=========================================="
cd ..
TOTAL_SIZE=$(du -sh "${EXPORT_DIR}" | cut -f1)
echo "✅ Total export size: ${TOTAL_SIZE}"

# Final summary
echo ""
echo "=========================================="
echo "EXPORT COMPLETE!"
echo "=========================================="
echo ""
echo "Export Directory: ${EXPORT_DIR}"
echo "Total Size: ${TOTAL_SIZE}"
echo ""
echo "Next Steps:"
echo "1. Download the entire '${EXPORT_DIR}' directory"
echo "2. Review EXPORT_SUMMARY.txt"
echo "3. Verify database and archives are not corrupted"
echo "4. Manually verify license keys in licenses_and_keys.txt"
echo "5. Take screenshots of live site for comparison"
echo ""
echo "To download, you can use:"
echo "  scp -r ${EXPORT_DIR} your-local-machine:/path/to/backup/"
echo "  OR use SFTP client to download the folder"
echo ""
echo "=========================================="
