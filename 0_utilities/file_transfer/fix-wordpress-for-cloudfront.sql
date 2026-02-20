-- ============================================================================
-- WordPress CloudFront/ALB Migration Fix Script
-- ============================================================================
--
-- PURPOSE: Prepare WordPress database for CloudFront/ALB architecture
-- RUN THIS: After importing database, BEFORE accessing the site
--
-- FIXES:
--   1. Disables SSL redirect plugins (Really Simple SSL, etc.)
--   2. Disables Wordfence firewall (can be re-enabled after migration)
--   3. Disables iThemes Security SSL settings
--   4. Removes hardcoded HTTPS redirects from options
--
-- USAGE:
--   mysql -u USER -p DATABASE < fix-wordpress-for-cloudfront.sql
--
-- ============================================================================

-- ----------------------------------------------------------------------------
-- STEP 1: Disable Really Simple SSL Plugin Settings
-- ----------------------------------------------------------------------------

-- Clear Really Simple SSL options (prevents redirect loop)
UPDATE wp_options SET option_value = '' WHERE option_name = 'rlrsssl_options';
UPDATE wp_options SET option_value = '0' WHERE option_name = 'rlrsssl_network_options';

-- Clear RSSSL redirect settings
DELETE FROM wp_options WHERE option_name LIKE 'rsssl_%';
DELETE FROM wp_options WHERE option_name LIKE 'rlrsssl_%';

-- ----------------------------------------------------------------------------
-- STEP 2: Disable Wordfence Firewall and Blocking Features
-- ----------------------------------------------------------------------------

-- Disable Wordfence firewall (if table exists)
-- Note: These will silently fail if Wordfence is not installed

UPDATE wp_wfconfig SET val = '0' WHERE name = 'firewallEnabled';
UPDATE wp_wfconfig SET val = '0' WHERE name = 'liveTrafficEnabled';
UPDATE wp_wfconfig SET val = '0' WHERE name = 'loginSecurityEnabled';
UPDATE wp_wfconfig SET val = '0' WHERE name = 'blockFakeBots';
UPDATE wp_wfconfig SET val = '0' WHERE name = 'bannedURLs';
UPDATE wp_wfconfig SET val = '0' WHERE name = 'other_blockBadPOST';
UPDATE wp_wfconfig SET val = '0' WHERE name = 'blockAdminReg';
UPDATE wp_wfconfig SET val = '0' WHERE name = 'neverBlockBG';

-- Clear Wordfence blocked IPs
TRUNCATE TABLE wp_wfblocks;
TRUNCATE TABLE wp_wfblocks7;
TRUNCATE TABLE wp_wfblockediplog;

-- ----------------------------------------------------------------------------
-- STEP 3: Disable iThemes Security (Better WP Security) SSL Settings
-- ----------------------------------------------------------------------------

-- Clear iThemes Security SSL redirect settings
UPDATE wp_options SET option_value = '' WHERE option_name = 'itsec-ssl';
UPDATE wp_options SET option_value = '' WHERE option_name = 'itsec_ssl';

-- Disable iThemes Security main settings that cause issues
UPDATE wp_options
SET option_value = REPLACE(option_value, '"ssl":1', '"ssl":0')
WHERE option_name = 'itsec_global';

-- ----------------------------------------------------------------------------
-- STEP 4: Disable Other SSL/HTTPS Plugins
-- ----------------------------------------------------------------------------

-- WordPress HTTPS plugin
DELETE FROM wp_options WHERE option_name = 'wordpress-https';
DELETE FROM wp_options WHERE option_name LIKE 'wordpress_https%';

-- SSL Insecure Content Fixer
DELETE FROM wp_options WHERE option_name LIKE 'ssl_insecure_content%';
DELETE FROM wp_options WHERE option_name LIKE 'sslfix_%';

-- WP Force SSL
DELETE FROM wp_options WHERE option_name LIKE 'wpfs_%';
DELETE FROM wp_options WHERE option_name = 'wp_force_ssl';

-- Easy HTTPS Redirection
DELETE FROM wp_options WHERE option_name LIKE 'ehrd_%';

-- ----------------------------------------------------------------------------
-- STEP 5: Remove Problematic Plugins from Active Plugins Array
-- ----------------------------------------------------------------------------

-- This is tricky because active_plugins is a serialized PHP array
-- We'll create a safe approach: backup and then use PHP to fix

-- First, backup the current active_plugins
INSERT INTO wp_options (option_name, option_value, autoload)
SELECT 'active_plugins_backup_migration', option_value, 'no'
FROM wp_options
WHERE option_name = 'active_plugins'
ON DUPLICATE KEY UPDATE option_value = VALUES(option_value);

-- ----------------------------------------------------------------------------
-- STEP 6: Disable .htaccess-based Redirects (stored in options)
-- ----------------------------------------------------------------------------

-- Some plugins store .htaccess rules in the database
UPDATE wp_options
SET option_value = ''
WHERE option_name = 'rewrite_rules'
AND option_value LIKE '%RewriteRule%https%';

-- ----------------------------------------------------------------------------
-- STEP 7: Fix Site URL Protocol (ensure consistency)
-- ----------------------------------------------------------------------------

-- These will be updated by the URL replacement step, but ensure no HTTP/HTTPS mismatch
-- Note: Do NOT change siteurl/home here - that's done in the migration URL update step

-- ----------------------------------------------------------------------------
-- VERIFICATION QUERIES - Run these to check the fixes
-- ----------------------------------------------------------------------------

-- Check if Really Simple SSL is still active
-- SELECT option_value FROM wp_options WHERE option_name = 'rlrsssl_options';

-- Check Wordfence firewall status (should be 0)
-- SELECT name, val FROM wp_wfconfig WHERE name = 'firewallEnabled';

-- Check active plugins (look for ssl/security plugins)
-- SELECT option_value FROM wp_options WHERE option_name = 'active_plugins';

-- ============================================================================
-- END OF SCRIPT
-- ============================================================================
