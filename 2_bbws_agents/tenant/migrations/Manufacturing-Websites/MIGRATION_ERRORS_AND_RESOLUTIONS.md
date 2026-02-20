# Manufacturing Website Migration - Errors and Resolutions

**Document Version:** 2.0
**Date:** 2026-01-15
**Migration:** manufacturing-websites.com → manufacturing.wpdev.kimmyai.io (DEV)
**Status:** Resolved
**Total Issues Documented:** 12 (5 Configuration + 7 Validation)

---

## Executive Summary

During the migration of the Manufacturing Websites WordPress site from Xneelo hosting to the BBWS AWS multi-tenant platform, several errors and blockers were encountered. This document details each issue, the investigation process, root cause analysis, and the resolution applied.

---

# Stage 1-4: Configuration Phase Issues

## Error C1: S3 Bucket Access Denied (403 Forbidden)

### Stage
Stage 1: Pre-Migration Setup

### Symptoms
- Bastion host could not access S3 bucket containing migration files
- `aws s3 ls s3://wordpress-migration-temp-20250903/manufacturing/` returned 403 Forbidden
- SSM Run Command failed when trying to download migration assets

### Investigation Steps
1. Verified S3 bucket exists and contains migration files
2. Checked bastion host IAM role permissions
3. Reviewed S3 bucket policy for allowed principals

### Root Cause
**Bastion host IAM role not included in S3 bucket policy.** The bucket policy only allowed specific IAM roles, and the bastion's instance role was not listed.

### Resolution
Updated S3 bucket policy to include the bastion host IAM role:
```json
{
    "Effect": "Allow",
    "Principal": {
        "AWS": "arn:aws:iam::536580886816:role/bastion-host-role"
    },
    "Action": [
        "s3:GetObject",
        "s3:ListBucket"
    ],
    "Resource": [
        "arn:aws:s3:::wordpress-migration-temp-20250903",
        "arn:aws:s3:::wordpress-migration-temp-20250903/*"
    ]
}
```

### Verification
```bash
# Verify access from bastion
aws s3 ls s3://wordpress-migration-temp-20250903/manufacturing/
# Result: Successfully listed files
```

---

## Error C2: SSM Command Quoting Issues with Complex SQL

### Stage
Stage 2: Database Migration

### Symptoms
- SSM Run Command failing with syntax errors
- SQL queries with special characters (quotes, backticks) not executing properly
- Heredoc syntax breaking in SSM command strings

### Investigation Steps
1. Tested simple SQL commands - worked correctly
2. Tested complex SQL with quotes - failed
3. Identified escaping requirements for SSM Run Command

### Root Cause
**Complex SQL queries require careful escaping when passed through SSM Run Command.** Single quotes, double quotes, and backticks all need proper escaping or alternative syntax.

### Resolution
Used alternative approaches for complex SQL:
1. **Base64 encoding** for complex queries:
```bash
# Encode SQL
ENCODED_SQL=$(echo "SELECT * FROM wp_posts WHERE post_content LIKE '%\"example\"%';" | base64)

# Execute via SSM
aws ssm send-command \
  --instance-ids "$BASTION_ID" \
  --document-name "AWS-RunShellScript" \
  --parameters "commands=[\"echo $ENCODED_SQL | base64 -d | mysql -h $RDS_HOST -u admin -p'$RDS_PASS' $DB_NAME\"]"
```

2. **Heredoc with escaped delimiters** for URL replacement:
```bash
--parameters "commands=[\"mysql -h $RDS_HOST -u admin -p'$RDS_PASS' $DB_NAME << 'EOSQL'\nUPDATE wp_options SET option_value = 'https://new-domain.com' WHERE option_name = 'siteurl';\nEOSQL\"]"
```

### Best Practice
For complex database operations, create SQL files on the bastion and execute locally rather than passing SQL through SSM parameters.

---

## Error C3: UTF-8 Encoding Artifacts in Content

### Stage
Stage 2: Database Migration

### Symptoms
- Special characters displaying incorrectly after migration
- Apostrophes showing as `â€™` instead of `'`
- Em dashes showing as `â€"` instead of `—`
- Ellipsis showing as `â€¦` instead of `…`

### Investigation Steps
1. Checked database character set (utf8mb4 - correct)
2. Checked MySQL connection character set
3. Compared raw content before and after migration

### Root Cause
**Original database export used different character encoding than import.** The source database was exported with UTF-8 but some content contained Windows-1252 encoded characters that were double-encoded during migration.

### Resolution
Applied encoding fix queries to convert common artifacts:
```sql
-- Fix smart quotes
UPDATE wp_posts SET post_content = REPLACE(post_content, 'â€™', ''');
UPDATE wp_posts SET post_content = REPLACE(post_content, 'â€œ', '"');
UPDATE wp_posts SET post_content = REPLACE(post_content, 'â€', '"');

-- Fix dashes and special characters
UPDATE wp_posts SET post_content = REPLACE(post_content, 'â€"', '—');
UPDATE wp_posts SET post_content = REPLACE(post_content, 'â€"', '–');
UPDATE wp_posts SET post_content = REPLACE(post_content, 'â€¦', '…');

-- Also apply to post excerpts and meta
UPDATE wp_postmeta SET meta_value = REPLACE(meta_value, 'â€™', ''') WHERE meta_value LIKE '%â€™%';
```

### Prevention
Ensure consistent UTF-8 encoding throughout the migration pipeline:
```bash
# Export with explicit encoding
mysqldump --default-character-set=utf8mb4 ...

# Import with explicit encoding
mysql --default-character-set=utf8mb4 ...
```

---

## Error C4: ECS Exec SessionManagerPlugin Not Found

### Stage
Stage 2-4: Various debugging operations

### Symptoms
- `aws ecs execute-command` failing with "SessionManagerPlugin is not found"
- Could not establish interactive session to WordPress container
- Needed to inspect container state during debugging

### Investigation Steps
1. Verified ECS Exec was enabled on the service
2. Checked local AWS CLI installation
3. Identified missing Session Manager plugin

### Root Cause
**Session Manager Plugin not installed locally.** The `aws ecs execute-command` requires the Session Manager plugin to be installed on the client machine.

### Workaround
Instead of using ECS Exec, used alternative approaches:
1. **CloudWatch Logs** for container output:
```bash
aws logs tail /ecs/dev-manufacturing-task --follow
```

2. **Bastion host** for database and file operations via SSM Run Command

3. **REST API and curl** for WordPress debugging:
```bash
curl -s "https://manufacturing.wpdev.kimmyai.io/wp-json/wp/v2/pages" | jq '.[0].content.rendered'
```

### Permanent Fix
Install Session Manager plugin for future use:
```bash
# macOS
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/mac/sessionmanager-bundle.zip" -o "sessionmanager-bundle.zip"
unzip sessionmanager-bundle.zip
sudo ./sessionmanager-bundle/install -i /usr/local/sessionmanagerplugin -b /usr/local/bin/session-manager-plugin
```

---

## Error C5: EFS File Permissions After Copy

### Stage
Stage 3: Files Migration

### Symptoms
- Files copied to EFS successfully
- WordPress unable to read/write to wp-content
- Permission denied errors in Apache logs

### Investigation Steps
1. Verified files existed on EFS via bastion
2. Checked file ownership and permissions
3. Compared with working tenant configuration

### Root Cause
**Files copied with root ownership instead of www-data (33:33).** WordPress runs as user ID 33 (www-data) inside the container, but files were copied with root ownership.

### Resolution
Fixed permissions on EFS via bastion:
```bash
# Connect to bastion and mount EFS
sudo mount -t efs -o tls,accesspoint=fsap-097b76280c7e75974 fs-0123456789abcdef0:/ /mnt/efs

# Fix ownership recursively
sudo chown -R 33:33 /mnt/efs/

# Fix directory permissions
sudo find /mnt/efs -type d -exec chmod 755 {} \;

# Fix file permissions
sudo find /mnt/efs -type f -exec chmod 644 {} \;

# Verify
ls -la /mnt/efs/
```

### Verification
```bash
# Check sample file ownership
stat /mnt/efs/themes/hello-elementor/style.css
# Result: Uid: 33, Gid: 33
```

---

# Stage 5: Validation Phase Issues

## Error 1: Homepage Returning Empty Content

### Symptoms
- Homepage returned HTTP 200 but with 0 bytes content
- All frontend pages returned empty responses
- wp-login.php worked correctly (6,529 bytes)
- REST API returned valid data (page content: 9,638 characters)

### Investigation Steps
1. Verified database content via REST API - content existed
2. Checked ECS container logs - no PHP errors
3. Tested static files (CSS, JS, images) - all returned 404
4. Compared with working tenant (tenant-2) - same EFS config
5. Checked Apache logs - showed 447 bytes being served

### Root Cause
**EFS volume not properly mounted after task deployment.** The EFS access point was correctly configured, but the container's wp-content directory was not receiving the mounted files.

### Resolution
```bash
# Force ECS service redeployment to refresh EFS mount
aws ecs update-service \
  --cluster dev-cluster \
  --service dev-manufacturing-service \
  --force-new-deployment
```

### Post-Fix Verification
| Test | Before | After |
|------|--------|-------|
| Homepage | 0 bytes | 90,792 bytes |
| Theme CSS | 404 | 200 (1,215 bytes) |
| Cookie Policy | 0 bytes | 54,984 bytes |

---

## Error 2: Static Files Returning 404

### Symptoms
- `/wp-content/themes/hello-elementor/style.css` → 404
- `/wp-content/plugins/elementor/assets/css/frontend.min.css` → 404
- `/wp-content/uploads/*` → 404

### Investigation Steps
1. Verified files existed on EFS via bastion host
2. Confirmed EFS access point configuration was correct
3. Checked task definition mount points - correctly configured
4. Compared with working tenant - identical setup

### Root Cause
**Same as Error 1** - EFS volume mount issue after container startup. The WordPress core was copied correctly, but the EFS mount at `/var/www/html/wp-content` was not accessible.

### Resolution
Same as Error 1 - ECS service redeployment resolved the issue.

---

## Error 3: Elementor Template in Draft Status

### Symptoms
- Homepage rendered but showed no content
- Elementor Theme Builder templates not loading
- Page template set to `elementor_header_footer`

### Investigation Steps
```sql
-- Check Elementor library templates
SELECT ID, post_title, post_status
FROM wp_posts
WHERE post_type = 'elementor_library';
```

### Root Cause
**"Landing Page Header" template (ID 19) was in draft status** instead of published. Elementor Theme Builder requires templates to be published to render on the frontend.

### Resolution
```sql
-- Publish the header template
UPDATE wp_posts
SET post_status = 'publish'
WHERE ID = 19;
```

### Verification
```sql
-- Confirm all Elementor templates are published
SELECT ID, post_title, post_status
FROM wp_posts
WHERE post_type = 'elementor_library';

-- Result: All templates now show 'publish' status
```

---

## Error 4: Old Domain References in Database

### Symptoms
- Canonical URLs pointing to `manufacturing-websites.com`
- Yoast SEO meta tags showing old domain
- Some internal links using old domain

### Investigation Steps
1. Checked `wp_options` for old domain references
2. Checked `wp_postmeta` for old domain references
3. Checked `wp_yoast_indexable` table for Yoast-specific URLs

### Root Cause
**Incomplete URL replacement during migration.** Initial URL replacement covered main tables but missed Yoast SEO indexable tables.

### Resolution
```sql
-- Update wp_options
UPDATE wp_options
SET option_value = REPLACE(option_value, 'manufacturing-websites.com', 'manufacturing.wpdev.kimmyai.io')
WHERE option_value LIKE '%manufacturing-websites.com%';
-- Result: 3 rows updated

-- Update wp_yoast_indexable
UPDATE wp_yoast_indexable
SET permalink = REPLACE(permalink, 'manufacturing-websites.com', 'manufacturing.wpdev.kimmyai.io')
WHERE permalink LIKE '%manufacturing-websites.com%';
-- Result: 4 rows updated

-- Update wp_yoast_seo_links
UPDATE wp_yoast_seo_links
SET url = REPLACE(url, 'manufacturing-websites.com', 'manufacturing.wpdev.kimmyai.io')
WHERE url LIKE '%manufacturing-websites.com%';
-- Result: 10 rows updated
```

### Verification
```bash
curl -s "https://manufacturing.wpdev.kimmyai.io/" | grep -o 'rel="canonical"[^>]*>'
# Result: rel="canonical" href="https://manufacturing.wpdev.kimmyai.io/" />
```

---

## Error 5: CloudFront Basic Auth Blocking Access

### Symptoms
- Site inaccessible via browser without authentication
- Users couldn't access site even with bypass header in browser
- Required technical knowledge to add HTTP headers

### Investigation Steps
1. Identified CloudFront function `wpdev-basic-auth` protecting DEV sites
2. Found existing tenant exclusion for `aupairhive.wpdev.kimmyai.io`
3. Confirmed bypass header `X-Bypass-Auth: DevBypass2026` worked via curl

### Root Cause
**Manufacturing site not in the CloudFront function's exclusion list.** The DEV environment uses a CloudFront Function for basic authentication, and manufacturing was not excluded.

### Resolution
Updated CloudFront Function to add manufacturing to the exclusion list:

```javascript
// Tenants that DON'T need auth (during testing/migration/client preview)
var noAuthTenants = [
    'aupairhive.wpdev.kimmyai.io',
    'manufacturing.wpdev.kimmyai.io'  // Added
];
```

```bash
# Update and publish CloudFront function
aws cloudfront update-function \
  --name wpdev-basic-auth \
  --region us-east-1 \
  --function-config '{"Comment":"Smart basic auth with bypass header and tenant exclusions","Runtime":"cloudfront-js-2.0"}' \
  --function-code fileb:///tmp/wpdev-basic-auth-updated.js \
  --if-match "$CURRENT_ETAG"

aws cloudfront publish-function \
  --name wpdev-basic-auth \
  --region us-east-1 \
  --if-match "$NEW_ETAG"
```

### Verification
```bash
# Test without any auth headers
curl -s -o /dev/null -w "%{http_code}" "https://manufacturing.wpdev.kimmyai.io/"
# Result: 200
```

---

## Error 6: WordPress Admin Credentials Unknown

### Symptoms
- Could not log into wp-admin
- Original site password migrated (hashed, not retrievable)
- User `nigelbeard` existed but password unknown

### Investigation Steps
```sql
-- Get user information
SELECT ID, user_login, user_email FROM wp_users;
-- Result: nigelbeard, nigel@bigbeard.co.za
```

### Root Cause
**Password migrated from original site in hashed format.** WordPress stores passwords as hashed values which cannot be reversed.

### Resolution
Reset password via database:
```sql
UPDATE wp_users
SET user_pass = MD5('MfgDev2026!')
WHERE user_login = 'nigelbeard';
```

### New Credentials
| Field | Value |
|-------|-------|
| Username | `nigelbeard` |
| Password | `MfgDev2026!` |

**Note:** User should change password after first login via Users → Your Profile.

---

## Error 7: reCAPTCHA Validation Failing

### Symptoms
- Form submission error: "Invalid form, reCAPTCHA validation failed"
- Error: "reCAPTCHA V3 validation failed, suspected as abusive usage"
- Forms completely unusable

### Investigation Steps
```sql
-- Find reCAPTCHA configuration
SELECT option_name, option_value
FROM wp_options
WHERE option_name LIKE '%recaptcha%';
```

### Root Cause
**reCAPTCHA keys configured for original domain.** Google reCAPTCHA keys are domain-specific. The keys were registered for `manufacturing-websites.com` but the site is now on `manufacturing.wpdev.kimmyai.io`.

Affected settings:
- `elementor_pro_recaptcha_v3_site_key`
- `elementor_pro_recaptcha_v3_secret_key`

### Resolution
Disabled reCAPTCHA for DEV environment:
```sql
-- Clear Elementor Pro reCAPTCHA keys
UPDATE wp_options
SET option_value = ''
WHERE option_name IN (
    'elementor_pro_recaptcha_v3_site_key',
    'elementor_pro_recaptcha_v3_secret_key',
    'elementor_pro_recaptcha_site_key',
    'elementor_pro_recaptcha_secret_key'
);
-- Result: 2 rows updated

-- Clear WordPress cache
DELETE FROM wp_options
WHERE option_name LIKE '%_transient_%';
-- Result: 81 rows deleted
```

### Production Recommendation
For production deployment, either:
1. Add production domain to existing reCAPTCHA keys in [Google reCAPTCHA Admin](https://www.google.com/recaptcha/admin)
2. Generate new reCAPTCHA keys for the production domain

---

## Summary of All Issues

### Configuration Phase (Stages 1-4)

| # | Error | Stage | Root Cause | Resolution | Impact |
|---|-------|-------|------------|------------|--------|
| C1 | S3 403 Forbidden | 1 | Bastion role not in bucket policy | Updated bucket policy | High |
| C2 | SSM SQL quoting | 2 | Complex SQL escaping | Base64 encoding / heredoc | Medium |
| C3 | UTF-8 encoding artifacts | 2 | Double-encoded characters | SQL REPLACE queries | Medium |
| C4 | ECS Exec unavailable | 2-4 | Session Manager plugin missing | CloudWatch Logs workaround | Low |
| C5 | EFS permissions | 3 | Root ownership on files | chown -R 33:33 | High |

### Validation Phase (Stage 5)

| # | Error | Root Cause | Resolution | Impact |
|---|-------|------------|------------|--------|
| 1 | Empty homepage | EFS mount issue | ECS redeployment | Critical |
| 2 | Static files 404 | EFS mount issue | ECS redeployment | Critical |
| 3 | Template in draft | Elementor template status | SQL update | High |
| 4 | Old domain URLs | Incomplete URL replacement | SQL updates | Medium |
| 5 | Basic auth blocking | CloudFront function | Function update | High |
| 6 | Unknown password | Hashed password | Password reset | High |
| 7 | reCAPTCHA failing | Domain-specific keys | Cleared keys | Medium |

---

## Lessons Learned

### Configuration Phase Lessons

### 1. S3 Bucket Policy Planning
**Ensure bastion host IAM role is included in S3 bucket policies** before starting migration. Pre-verify access with a simple `aws s3 ls` command.

### 2. SSM Command Complexity
**Avoid passing complex SQL through SSM parameters.** Instead:
- Use SQL files on the bastion host
- Use base64 encoding for complex queries
- Break complex operations into simpler steps

### 3. Character Encoding Consistency
**Maintain UTF-8 encoding throughout the pipeline:**
- Use `--default-character-set=utf8mb4` on both export and import
- Test sample content with special characters after import
- Keep encoding fix queries ready for common artifacts

### 4. File Permissions on EFS
**Always set ownership to 33:33 (www-data) immediately after copying files** to EFS. WordPress containers run as this user and cannot access root-owned files.

### 5. Session Manager Plugin
**Install Session Manager plugin on workstations** used for WordPress migrations. ECS Exec is valuable for container debugging.

### Validation Phase Lessons

### 6. EFS Mount Verification
**Always verify EFS mount is working after deployment** by checking if wp-content files are accessible via HTTP, not just via the bastion host.

### 7. Complete URL Replacement
**Include all WordPress tables** in URL replacement:
- `wp_options`
- `wp_posts`
- `wp_postmeta`
- `wp_yoast_indexable` (if Yoast SEO installed)
- `wp_yoast_seo_links` (if Yoast SEO installed)

### 8. Elementor Template Status
**Verify Elementor Theme Builder templates are published** after migration:
```sql
SELECT ID, post_title, post_status
FROM wp_posts
WHERE post_type = 'elementor_library';
```

### 9. Third-Party Integrations
**Document and plan for domain-specific integrations:**
- reCAPTCHA keys
- Google Analytics
- Facebook Pixel
- Payment gateways
- Email service providers

### 10. CloudFront Tenant Exclusions
**Add migrating sites to CloudFront exclusion list early** to allow easy testing during migration.

---

## Related Documents

- Project Plan: `.claude/plans/project-plan-1/project_plan.md`
- History Log: `.claude/logs/history.log`
- Migration Runbook: `runbooks/wordpress_migration_playbook_automated.md`

---

**Document Status:** Complete
**Last Updated:** 2026-01-15
