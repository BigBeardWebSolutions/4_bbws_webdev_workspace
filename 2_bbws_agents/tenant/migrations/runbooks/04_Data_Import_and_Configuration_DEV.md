# Phase 4: Data Import and Configuration (DEV Environment)

**Phase**: 4 of 10
**Duration**: 1 day (8 hours)
**Responsible**: Database Administrator + WordPress Developer
**Environment**: DEV
**Dependencies**: Phase 3 (DEV Environment Provisioning) must be complete
**Status**: ⏳ NOT STARTED

---

## Phase Objectives

- Import Au Pair Hive database from Xneelo export to DEV environment
- Replace all URLs from old domain to new DEV domain
- Upload WordPress files to EFS via S3 staging
- Configure wp-config.php with DEV database credentials
- Install and activate premium plugin licenses (Divi, Gravity Forms)
- Configure API keys and integrations
- Verify WordPress installation is functional
- Document all configuration changes

---

## Prerequisites

- [ ] Phase 3 completed: aupairhive tenant provisioned in DEV
- [ ] Database export file available: `aupairhive_database.sql`
- [ ] WordPress files archive available: `aupairhive_files.tar.gz`
- [ ] Divi Theme license key documented
- [ ] Gravity Forms license key documented
- [ ] reCAPTCHA API keys documented
- [ ] Facebook Pixel ID documented
- [ ] import_database.sh script tested and ready
- [ ] upload_wordpress_files.sh script tested and ready
- [ ] AWS CLI configured with Tebogo-dev profile

---

## Detailed Tasks

### Task 4.1: Prepare Import Environment

**Duration**: 30 minutes
**Responsible**: DevOps Engineer

**Steps**:

1. **Set environment variables**:
```bash
export AWS_PROFILE=Tebogo-dev
export AWS_REGION=eu-west-1
export ENVIRONMENT=dev
export TENANT_ID=aupairhive
export SOURCE_DOMAIN=aupairhive.com
export TARGET_DOMAIN=aupairhive.wpdev.kimmyai.io
```

2. **Verify tenant infrastructure is ready**:
```bash
# Check ECS service is running
aws ecs describe-services \
    --cluster dev-cluster \
    --services aupairhive-dev-service \
    --query 'services[0].[serviceName,status,runningCount,desiredCount]'
```

**Expected Output**:
```
[
    "aupairhive-dev-service",
    "ACTIVE",
    1,
    1
]
```

3. **Verify database exists and is accessible**:
```bash
# Get database credentials from Secrets Manager
DB_SECRET=$(aws secretsmanager get-secret-value \
    --secret-id bbws/dev/aupairhive/database \
    --query SecretString --output text)

DB_HOST=$(echo $DB_SECRET | jq -r '.host')
DB_USER=$(echo $DB_SECRET | jq -r '.username')
DB_PASS=$(echo $DB_SECRET | jq -r '.password')
DB_NAME=$(echo $DB_SECRET | jq -r '.dbname')

# Test connection
mysql -h $DB_HOST -u $DB_USER -p$DB_PASS -e "SHOW DATABASES LIKE 'tenant_aupairhive_db';"
```

**Expected Output**: Should show `tenant_aupairhive_db` database

4. **Verify EFS access point is mounted**:
```bash
aws efs describe-access-points \
    --file-system-id fs-xxxxxxxxx \
    --query "AccessPoints[?Name=='aupairhive'].Path"
```

**Expected Output**: `/tenant-aupairhive`

**Troubleshooting**:
- **Issue**: ECS service not running
  - **Solution**: Check Phase 3 tasks, redeploy ECS service

- **Issue**: Cannot connect to database
  - **Solution**: Verify security groups allow connection, check credentials in Secrets Manager

**Verification**:
- [ ] Environment variables set correctly
- [ ] ECS service is ACTIVE with 1 running task
- [ ] Database connection successful
- [ ] EFS access point exists

---

### Task 4.2: Import WordPress Database

**Duration**: 1.5 hours
**Responsible**: Database Administrator

**Steps**:

1. **Locate database export file**:
```bash
cd /path/to/xneelo-backup/aupairhive-backup-2026-01-09

# Verify database file exists
ls -lh aupairhive_database.sql

# Check file integrity (compare with documented checksum from Phase 2)
sha256sum aupairhive_database.sql
```

2. **Run database import script**:
```bash
# Make script executable (if not already)
chmod +x /Users/tebogotseka/Documents/agentic_work/2_bbws_docs/training/import_database.sh

# Run import with environment-specific parameters
/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/training/import_database.sh \
    --environment dev \
    --tenant-id aupairhive \
    --sql-file aupairhive_database.sql \
    --source-url "https://aupairhive.com" \
    --target-url "https://aupairhive.wpdev.kimmyai.io"
```

**Expected Output**:
```
[INFO] Environment: dev
[INFO] Tenant ID: aupairhive
[INFO] Retrieving database credentials from Secrets Manager...
[INFO] Database credentials retrieved: bbws/dev/aupairhive/database
[INFO] Importing database from: aupairhive_database.sql
[INFO] Database import completed successfully
[INFO] Performing URL replacements...
[INFO] Replacing: https://aupairhive.com → https://aupairhive.wpdev.kimmyai.io
[INFO] Replacing: http://aupairhive.com → https://aupairhive.wpdev.kimmyai.io
[INFO] Replacing: https://www.aupairhive.com → https://aupairhive.wpdev.kimmyai.io
[INFO] Replacing: http://www.aupairhive.com → https://aupairhive.wpdev.kimmyai.io
[INFO] URL replacements completed
[INFO] Total rows affected: 1234
[INFO] Verifying database import...
[SUCCESS] Database import and URL replacement completed successfully
```

3. **Verify database tables imported**:
```bash
mysql -h $DB_HOST -u $DB_USER -p$DB_PASS $DB_NAME -e "SHOW TABLES;"
```

**Expected Output**: Should show WordPress tables (wp_posts, wp_options, wp_users, etc.)

4. **Verify URL replacements**:
```bash
# Check wp_options for site URL
mysql -h $DB_HOST -u $DB_USER -p$DB_PASS $DB_NAME -e \
    "SELECT option_name, option_value FROM wp_options WHERE option_name IN ('siteurl', 'home');"
```

**Expected Output**:
```
+--------------+----------------------------------------+
| option_name  | option_value                           |
+--------------+----------------------------------------+
| siteurl      | https://aupairhive.wpdev.kimmyai.io   |
| home         | https://aupairhive.wpdev.kimmyai.io   |
+--------------+----------------------------------------+
```

5. **Verify post content URLs updated**:
```bash
# Check for old URLs in post content (should return 0 results)
mysql -h $DB_HOST -u $DB_USER -p$DB_PASS $DB_NAME -e \
    "SELECT COUNT(*) as old_url_count FROM wp_posts WHERE post_content LIKE '%aupairhive.com%';"
```

**Expected Output**: `old_url_count: 0` (or very low if embedded in text content)

6. **Document row counts for verification**:
```bash
echo "=== Database Row Counts ===" > database_import_verification.txt
mysql -h $DB_HOST -u $DB_USER -p$DB_PASS $DB_NAME -e \
    "SELECT
        (SELECT COUNT(*) FROM wp_posts) as posts,
        (SELECT COUNT(*) FROM wp_users) as users,
        (SELECT COUNT(*) FROM wp_options) as options,
        (SELECT COUNT(*) FROM wp_postmeta) as postmeta;" \
    >> database_import_verification.txt

cat database_import_verification.txt
```

**Troubleshooting**:
- **Issue**: Import script fails with "Access Denied"
  - **Solution**: Verify database credentials in Secrets Manager, check user privileges

- **Issue**: URL replacement doesn't update all URLs
  - **Solution**: Run manual UPDATE queries for serialized data, check wp_postmeta table

- **Issue**: Database import is slow
  - **Solution**: Use --max_allowed_packet parameter, split large SQL file if needed

**Verification**:
- [ ] Database import completed without errors
- [ ] All WordPress tables exist (wp_posts, wp_users, wp_options, etc.)
- [ ] Site URL (wp_options) updated to DEV domain
- [ ] Post content URLs replaced
- [ ] Row counts documented and match source (if available)
- [ ] No old domain URLs found in critical tables

---

### Task 4.3: Upload WordPress Files to EFS

**Duration**: 2 hours
**Responsible**: WordPress Developer + DevOps Engineer

**Steps**:

1. **Locate WordPress files archive**:
```bash
cd /path/to/xneelo-backup/aupairhive-backup-2026-01-09

# Verify files archive exists
ls -lh aupairhive_files.tar.gz

# Check file integrity
sha256sum aupairhive_files.tar.gz
```

2. **Run file upload script**:
```bash
# Make script executable (if not already)
chmod +x /Users/tebogotseka/Documents/agentic_work/2_bbws_docs/training/upload_wordpress_files.sh

# Run upload with environment-specific parameters
/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/training/upload_wordpress_files.sh \
    --environment dev \
    --tenant-id aupairhive \
    --archive aupairhive_files.tar.gz
```

**Expected Output**:
```
[INFO] Environment: dev
[INFO] Tenant ID: aupairhive
[INFO] Archive: aupairhive_files.tar.gz
[INFO] Extracting WordPress files...
[INFO] Validating WordPress structure...
[INFO] Found wp-config.php, wp-content, wp-includes ✓
[INFO] Creating S3 staging bucket: bbws-dev-file-staging
[INFO] Uploading files to S3: s3://bbws-dev-file-staging/aupairhive/
[INFO] Files uploaded to S3 (1.2 GB)
[INFO] Starting ECS task to deploy files to EFS...
[INFO] ECS task started: arn:aws:ecs:eu-west-1:536580886816:task/dev-cluster/abc123...
[INFO] Waiting for task completion...
[INFO] Files deployed to EFS: /tenant-aupairhive
[INFO] Setting file permissions (755 for directories, 644 for files)
[INFO] Setting wp-config.php permissions to 600
[SUCCESS] WordPress files uploaded successfully
```

3. **Verify files uploaded to EFS**:
```bash
# Run a temporary ECS task to list files on EFS
aws ecs run-task \
    --cluster dev-cluster \
    --task-definition aupairhive-dev-task \
    --overrides '{
        "containerOverrides": [{
            "name": "wordpress",
            "command": ["sh", "-c", "ls -lah /var/www/html && du -sh /var/www/html"]
        }]
    }' \
    --launch-type FARGATE \
    --network-configuration '{
        "awsvpcConfiguration": {
            "subnets": ["subnet-xxxxx"],
            "securityGroups": ["sg-xxxxx"],
            "assignPublicIp": "ENABLED"
        }
    }'

# Wait 30 seconds, then check CloudWatch logs for output
aws logs tail /ecs/aupairhive-dev --follow
```

**Expected Output**: Should show WordPress files (wp-config.php, wp-content/, wp-includes/, etc.)

4. **Verify critical directories exist**:
```bash
# Check via CloudWatch logs from ECS task
# Should see:
# - wp-content/themes/Divi/
# - wp-content/plugins/gravityforms/
# - wp-content/uploads/
```

**Troubleshooting**:
- **Issue**: S3 upload fails with "Access Denied"
  - **Solution**: Verify AWS CLI profile has S3 permissions, check bucket policy

- **Issue**: ECS task fails to mount EFS
  - **Solution**: Verify EFS access point ID in task definition, check security groups

- **Issue**: Files not visible in EFS after upload
  - **Solution**: Check ECS task logs, verify mount path, check file permissions

**Verification**:
- [ ] WordPress files archive extracted successfully
- [ ] Files uploaded to S3 staging bucket
- [ ] ECS task deployed files to EFS
- [ ] WordPress core files exist (wp-config.php, wp-includes/, wp-admin/)
- [ ] wp-content directory exists with themes, plugins, uploads
- [ ] Divi theme directory exists
- [ ] Gravity Forms plugin directory exists
- [ ] File permissions set correctly (wp-config.php = 600)

---

### Task 4.4: Configure wp-config.php with DEV Credentials

**Duration**: 1 hour
**Responsible**: WordPress Developer

**Steps**:

1. **Access ECS container to edit wp-config.php**:
```bash
# Get running task ID
TASK_ARN=$(aws ecs list-tasks \
    --cluster dev-cluster \
    --service-name aupairhive-dev-service \
    --query 'taskArns[0]' --output text)

# Execute shell in container (if ECS Exec is enabled)
aws ecs execute-command \
    --cluster dev-cluster \
    --task $TASK_ARN \
    --container wordpress \
    --interactive \
    --command "/bin/bash"
```

2. **Edit wp-config.php with DEV database credentials**:
```bash
# Inside container
cd /var/www/html

# Backup original wp-config.php
cp wp-config.php wp-config.php.backup

# Edit wp-config.php (use vi or create new file)
cat > wp-config.php <<'EOPHP'
<?php
/**
 * WordPress Configuration - DEV Environment
 * Tenant: aupairhive
 * Environment: DEV (wpdev.kimmyai.io)
 */

// ** Database settings ** //
define('DB_NAME', getenv('WORDPRESS_DB_NAME') ?: 'tenant_aupairhive_db');
define('DB_USER', getenv('WORDPRESS_DB_USER') ?: 'tenant_aupairhive_user');
define('DB_PASSWORD', getenv('WORDPRESS_DB_PASSWORD') ?: 'FALLBACK_PASS');
define('DB_HOST', getenv('WORDPRESS_DB_HOST') ?: 'bbws-dev-mysql.xxxxx.eu-west-1.rds.amazonaws.com');
define('DB_CHARSET', 'utf8mb4');
define('DB_COLLATE', '');

// ** Authentication Unique Keys and Salts ** //
// IMPORTANT: Generate new salts for DEV environment
define('AUTH_KEY',         'put your unique phrase here');
define('SECURE_AUTH_KEY',  'put your unique phrase here');
define('LOGGED_IN_KEY',    'put your unique phrase here');
define('NONCE_KEY',        'put your unique phrase here');
define('AUTH_SALT',        'put your unique phrase here');
define('SECURE_AUTH_SALT', 'put your unique phrase here');
define('LOGGED_IN_SALT',   'put your unique phrase here');
define('NONCE_SALT',       'put your unique phrase here');

// ** WordPress Database Table prefix ** //
$table_prefix = 'wp_';

// ** Development Mode ** //
define('WP_DEBUG', true);
define('WP_DEBUG_LOG', true);
define('WP_DEBUG_DISPLAY', false);
define('SCRIPT_DEBUG', false);

// ** Environment Type ** //
define('WP_ENVIRONMENT_TYPE', 'development');

// ** URL Configuration ** //
define('WP_HOME', 'https://aupairhive.wpdev.kimmyai.io');
define('WP_SITEURL', 'https://aupairhive.wpdev.kimmyai.io');

// ** File System ** //
define('FS_METHOD', 'direct');

// ** Security ** //
define('DISALLOW_FILE_EDIT', false); // Allow file editing in DEV
define('FORCE_SSL_ADMIN', false); // DEV environment may not have SSL yet

// ** Memory Limits ** //
define('WP_MEMORY_LIMIT', '256M');
define('WP_MAX_MEMORY_LIMIT', '512M');

/* That's all, stop editing! Happy publishing. */

/** Absolute path to the WordPress directory. */
if (!defined('ABSPATH')) {
    define('ABSPATH', __DIR__ . '/');
}

/** Sets up WordPress vars and included files. */
require_once ABSPATH . 'wp-settings.php';
EOPHP
```

3. **Generate new security salts for DEV**:
```bash
# Fetch new salts from WordPress.org API
curl -s https://api.wordpress.org/secret-key/1.1/salt/

# Copy output and replace the 8 AUTH/SALT defines in wp-config.php
```

4. **Set correct file permissions**:
```bash
chmod 600 wp-config.php
chown www-data:www-data wp-config.php
```

5. **Verify wp-config.php syntax**:
```bash
php -l wp-config.php
```

**Expected Output**: `No syntax errors detected in wp-config.php`

**Alternative Method** (if ECS Exec not enabled):

Create wp-config.php locally and upload via S3:
```bash
# Create wp-config.php locally
cat > /tmp/wp-config.php <<'EOPHP'
[... same content as above ...]
EOPHP

# Upload to S3
aws s3 cp /tmp/wp-config.php s3://bbws-dev-file-staging/aupairhive/wp-config.php

# Trigger deployment via ECS task (modify upload script to deploy single file)
```

**Troubleshooting**:
- **Issue**: Cannot access ECS container
  - **Solution**: Enable ECS Exec on task definition, or use S3 upload method

- **Issue**: Database connection fails
  - **Solution**: Verify DB credentials from Secrets Manager, update wp-config.php

- **Issue**: PHP syntax error in wp-config.php
  - **Solution**: Check PHP syntax with `php -l`, fix closing tags

**Verification**:
- [ ] wp-config.php edited with DEV credentials
- [ ] New security salts generated and applied
- [ ] File permissions set to 600
- [ ] PHP syntax validation passed
- [ ] WP_DEBUG enabled for development
- [ ] WP_HOME and WP_SITEURL set to DEV domain

---

### Task 4.5: Install and Activate Premium Licenses

**Duration**: 1.5 hours
**Responsible**: WordPress Developer

**Steps**:

1. **Access WordPress admin**:
```bash
# First, restart ECS task to pick up new wp-config.php
aws ecs update-service \
    --cluster dev-cluster \
    --service aupairhive-dev-service \
    --force-new-deployment

# Wait 2 minutes for new task to start
sleep 120

# Access WordPress admin
# URL: https://aupairhive.wpdev.kimmyai.io/wp-admin
```

2. **Login to WordPress**:
- Navigate to: https://aupairhive.wpdev.kimmyai.io/wp-admin
- Login with existing admin credentials (from Xneelo)
- If you don't have credentials, reset via database:
```bash
# Reset admin password via database
mysql -h $DB_HOST -u $DB_USER -p$DB_PASS $DB_NAME -e \
    "UPDATE wp_users SET user_pass=MD5('TempPassword123!') WHERE user_login='admin';"

# Login with: admin / TempPassword123!
# CHANGE PASSWORD IMMEDIATELY AFTER LOGIN
```

3. **Activate Divi Theme license**:
- Go to: Divi → Theme Options → Updates
- Enter Divi API Key: `[DIVI_LICENSE_KEY_FROM_PHASE_2]`
- Click "Save Changes"
- Verify: Should show "Elegant Themes Updates Enabled"

4. **Activate Gravity Forms license**:
- Go to: Forms → Settings
- Click "Gravity Forms License Key"
- Enter License Key: `[GRAVITY_FORMS_KEY_FROM_PHASE_2]`
- Click "Update License Key"
- Verify: Should show "Active" status

5. **Verify plugin updates available**:
```bash
# Check for plugin updates
wp plugin update --all --dry-run --path=/var/www/html

# If updates available, apply them (after backup)
wp plugin update --all --path=/var/www/html
```

6. **Test Divi Builder**:
- Go to: Pages → All Pages
- Click "Edit" on homepage
- Click "Use The Divi Builder"
- Verify: Divi Builder loads without errors

7. **Test Gravity Forms**:
- Go to: Forms → Forms
- Verify all forms listed (Contact, Application, Newsletter, etc.)
- Click "Preview" on Contact form
- Verify: Form displays correctly

**Troubleshooting**:
- **Issue**: Cannot access wp-admin (404 error)
  - **Solution**: Check ALB routing, verify DNS resolves, check ECS service status

- **Issue**: Divi license activation fails
  - **Solution**: Verify license key is valid, check if license is already used on another domain, contact Elegant Themes support

- **Issue**: Gravity Forms license invalid
  - **Solution**: Verify license key, check license expiration date, may need to purchase new license for new domain

- **Issue**: Infinite redirect loop
  - **Solution**: Clear browser cache, check wp-config.php URL settings, verify database siteurl/home values

**Verification**:
- [ ] WordPress admin accessible at /wp-admin
- [ ] Admin login successful
- [ ] Divi Theme license activated
- [ ] Gravity Forms license activated
- [ ] Divi Builder functional
- [ ] All Gravity Forms visible and functional
- [ ] No license expiration warnings

---

### Task 4.6: Configure API Keys and Integrations

**Duration**: 1 hour
**Responsible**: WordPress Developer

**Steps**:

1. **Configure reCAPTCHA for Gravity Forms**:
- Go to: Forms → Settings → reCAPTCHA
- Select reCAPTCHA Version: v2 Checkbox
- Enter Site Key: `[RECAPTCHA_SITE_KEY_FROM_PHASE_2]`
- Enter Secret Key: `[RECAPTCHA_SECRET_KEY_FROM_PHASE_2]`
- Click "Update Settings"

2. **Verify reCAPTCHA on forms**:
- Go to: Forms → Forms
- Edit each form with reCAPTCHA enabled
- Verify reCAPTCHA field exists
- Save form

3. **Configure Facebook Pixel** (if using plugin):
- Go to: Settings → Facebook Pixel
- Enter Pixel ID: `[FACEBOOK_PIXEL_ID_FROM_PHASE_2]`
- Enable tracking events
- Save settings

**Alternative**: If using header/footer injection:
```bash
# Edit theme header to include Facebook Pixel code
# Go to: Appearance → Theme Editor → header.php
# Or use Divi → Theme Options → Integration → Add code to <head>
```

4. **Configure SMTP settings** (if using WP Mail SMTP plugin):
- Go to: WP Mail SMTP → Settings
- Select Mailer: (Amazon SES, SendGrid, or other)
- Enter SMTP credentials
- Set "From Email": info@aupairhive.com
- Set "From Name": Au Pair Hive
- Click "Save Settings"

5. **Test email delivery**:
- Go to: WP Mail SMTP → Email Test
- Send test email to your email address
- Verify email received

6. **Update permalink structure** (if needed):
- Go to: Settings → Permalinks
- Verify structure: Post name (recommended)
- Click "Save Changes" (flushes rewrite rules)

7. **Clear all caches**:
```bash
# If using caching plugin (W3 Total Cache, WP Super Cache, etc.)
# Go to plugin settings and clear all caches

# Flush WordPress object cache
wp cache flush --path=/var/www/html

# Flush rewrite rules
wp rewrite flush --path=/var/www/html
```

**Troubleshooting**:
- **Issue**: reCAPTCHA not showing on forms
  - **Solution**: Verify API keys, check if domain is authorized in Google reCAPTCHA console

- **Issue**: Facebook Pixel not tracking
  - **Solution**: Verify Pixel ID, use Facebook Pixel Helper browser extension to debug

- **Issue**: Emails not sending
  - **Solution**: Check SMTP credentials, verify SPF/DKIM records, check email logs

**Verification**:
- [ ] reCAPTCHA configured with valid API keys
- [ ] reCAPTCHA visible on forms during preview
- [ ] Facebook Pixel configured (if applicable)
- [ ] SMTP settings configured for email delivery
- [ ] Test email sent and received successfully
- [ ] Permalink structure verified
- [ ] All caches cleared

---

### Task 4.7: Verify WordPress Installation Functional

**Duration**: 1 hour
**Responsible**: WordPress Developer + QA

**Steps**:

1. **Test homepage loads**:
```bash
curl -I https://aupairhive.wpdev.kimmyai.io
```

**Expected Output**:
```
HTTP/2 200
content-type: text/html; charset=UTF-8
```

2. **Visual verification checklist**:
- [ ] Homepage loads with Divi theme styling
- [ ] Header logo displays
- [ ] Navigation menu functional
- [ ] Hero section displays correctly
- [ ] Images load (check for broken images)
- [ ] Footer displays with contact info

3. **Test all pages**:
```bash
# Get list of all pages
mysql -h $DB_HOST -u $DB_USER -p$DB_PASS $DB_NAME -e \
    "SELECT ID, post_title, guid FROM wp_posts WHERE post_type='page' AND post_status='publish';"

# Test each page URL
curl -I https://aupairhive.wpdev.kimmyai.io/about/
curl -I https://aupairhive.wpdev.kimmyai.io/services/
curl -I https://aupairhive.wpdev.kimmyai.io/contact/
# etc.
```

4. **Test all forms**:
- Go to each page with a form
- Fill out and submit test form
- Verify form submission (check Gravity Forms → Entries)
- Verify email notifications (check inbox)

5. **Check for errors in browser console**:
- Open browser DevTools (F12)
- Navigate to homepage
- Check Console tab for JavaScript errors
- Check Network tab for failed requests (404s, 500s)

6. **Check PHP error logs**:
```bash
# Access container logs
aws logs tail /ecs/aupairhive-dev --follow

# Look for PHP warnings/errors
# Should see minimal errors (ignore deprecation notices for now)
```

7. **Test admin functionality**:
- [ ] Create new test page
- [ ] Edit existing page with Divi Builder
- [ ] Upload new image to Media Library
- [ ] Create new blog post
- [ ] Preview post before publishing

8. **Document known issues**:
Create file: `dev_import_issues.txt`
```
Known Issues After DEV Import:
- [List any issues found]
- [e.g., "Contact form not sending emails - SMTP not configured"]
- [e.g., "Some images broken - need to re-upload"]
```

**Troubleshooting**:
- **Issue**: Homepage shows "Error establishing database connection"
  - **Solution**: Verify wp-config.php credentials, check RDS security group

- **Issue**: Theme not loading (plain text display)
  - **Solution**: Verify wp-content/themes/ uploaded, activate theme in wp-admin

- **Issue**: 404 on all pages except homepage
  - **Solution**: Flush permalinks (Settings → Permalinks → Save Changes)

- **Issue**: Images broken (404)
  - **Solution**: Verify wp-content/uploads/ uploaded, check image URLs in database

**Verification**:
- [ ] Homepage loads successfully (HTTP 200)
- [ ] All pages accessible (no 404s)
- [ ] Divi theme styling applied
- [ ] Navigation menu functional
- [ ] Images display correctly
- [ ] Forms load and display
- [ ] Admin panel functional
- [ ] No critical PHP errors in logs
- [ ] Known issues documented

---

## Verification Checklist

### Database Import
- [ ] Database import script executed successfully
- [ ] All WordPress tables exist
- [ ] URL replacements completed (siteurl, home, post_content)
- [ ] Row counts match source (if documented)
- [ ] No old domain URLs in critical tables

### File Upload
- [ ] WordPress files uploaded to EFS
- [ ] Core files exist (wp-config.php, wp-includes, wp-admin)
- [ ] wp-content directory with themes, plugins, uploads
- [ ] Divi theme directory exists
- [ ] Gravity Forms plugin directory exists
- [ ] File permissions correct (wp-config.php = 600)

### Configuration
- [ ] wp-config.php configured with DEV credentials
- [ ] Security salts regenerated
- [ ] WP_DEBUG enabled
- [ ] WP_HOME and WP_SITEURL set to DEV domain

### Licenses and API Keys
- [ ] Divi Theme license activated
- [ ] Gravity Forms license activated
- [ ] reCAPTCHA configured and functional
- [ ] Facebook Pixel configured (if applicable)
- [ ] SMTP configured and tested

### Functionality
- [ ] WordPress homepage loads successfully
- [ ] All pages accessible
- [ ] Divi Builder functional
- [ ] Gravity Forms functional
- [ ] Admin panel accessible
- [ ] No critical errors in logs

---

## Rollback Procedure

If database import or file upload fails critically:

1. **Drop and recreate database**:
```bash
mysql -h $DB_HOST -u admin -p <<EOSQL
DROP DATABASE tenant_aupairhive_db;
CREATE DATABASE tenant_aupairhive_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
GRANT ALL PRIVILEGES ON tenant_aupairhive_db.* TO 'tenant_aupairhive_user'@'%';
FLUSH PRIVILEGES;
EOSQL
```

2. **Clear EFS directory**:
```bash
# Via ECS task
aws ecs run-task \
    --cluster dev-cluster \
    --task-definition aupairhive-dev-task \
    --overrides '{
        "containerOverrides": [{
            "name": "wordpress",
            "command": ["sh", "-c", "rm -rf /var/www/html/*"]
        }]
    }' \
    --launch-type FARGATE
```

3. **Restart from Task 4.1** with corrected export files

---

## Success Criteria

- [ ] Database imported with all tables and data
- [ ] URL replacements completed successfully
- [ ] WordPress files uploaded to EFS
- [ ] wp-config.php configured correctly
- [ ] Premium licenses activated (Divi, Gravity Forms)
- [ ] API keys configured (reCAPTCHA, Facebook Pixel)
- [ ] WordPress homepage loads successfully
- [ ] All pages accessible (no 404s)
- [ ] Forms functional (load and display)
- [ ] Admin panel accessible
- [ ] No critical errors in application or database
- [ ] Known issues documented
- [ ] Ready for Phase 5 (Testing and Validation)

**Definition of Done**:
WordPress site is fully functional in DEV environment with all content, themes, plugins, and configurations migrated from Xneelo.

---

## Sign-Off

**Completed By**: _________________ Date: _________
**Verified By**: _________________ Date: _________
**Database Rows Imported**: _________
**Files Uploaded (GB)**: _________
**Known Issues**: _________
**Ready for Phase 5**: [ ] YES [ ] NO

---

## Notes and Observations

[Space for team to document findings]

**Issues Encountered**:
-
-

**Configuration Changes**:
-
-

**Recommendations**:
-
-

---

**Next Phase**: Proceed to **Phase 5**: `05_Testing_and_Validation_DEV.md`
