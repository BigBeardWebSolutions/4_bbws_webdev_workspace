# Known Issues Registry — WordPress Tenant Migrations

**Version:** 1.0
**Created:** 2026-02-06
**ID Scheme:** MI-001 through MI-030 (Migration Issue)
**Sources:** Manufacturing-Websites errors, AuPairHive retrospective, wordpress_migration_playbook_automated.md troubleshooting

---

## Quick-Reference Summary

| MI-ID | Category | Severity | Title | Prevention Script Check |
|-------|----------|----------|-------|------------------------|
| MI-001 | Configuration | HIGH | S3 Bucket Access Denied (403) | `pre_promotion_validate.sh` — AWS auth |
| MI-002 | Configuration | MEDIUM | SSM Command Quoting Failures | Manual — use file-based SQL |
| MI-003 | Database | MEDIUM | UTF-8 Encoding Artifacts | `pre_promotion_validate.sh` — DB charset |
| MI-004 | Infrastructure | LOW | ECS Exec SessionManagerPlugin Missing | `pre_promotion_validate.sh` — AWS auth |
| MI-005 | Files/EFS | HIGH | EFS File Permissions (root instead of 33:33) | `post_promotion_validate.sh` — EFS mount |
| MI-006 | Files/EFS | CRITICAL | Homepage Empty / EFS Not Mounted | `post_promotion_validate.sh` — HTTP status + content size |
| MI-007 | Files/EFS | CRITICAL | Static Files Returning 404 | `post_promotion_validate.sh` — theme CSS check |
| MI-008 | Plugins/Themes | HIGH | Elementor Templates in Draft Status | `post_promotion_validate.sh` — content size |
| MI-009 | Database | MEDIUM | Incomplete URL Replacement (Yoast tables) | `post_promotion_validate.sh` — canonical URL |
| MI-010 | Networking/SSL | HIGH | CloudFront Basic Auth Blocking Access | `pre_promotion_validate.sh` — HTTP status |
| MI-011 | Configuration | HIGH | WordPress Admin Password Unknown | Manual — reset via SQL |
| MI-012 | Plugins/Themes | MEDIUM | reCAPTCHA Validation Failing (domain mismatch) | `post_promotion_validate.sh` — form endpoint |
| MI-013 | Plugins/Themes | HIGH | Wrong Theme Active After Migration | `pre_promotion_validate.sh` — active theme |
| MI-014 | Networking/SSL | CRITICAL | Mixed Content (HTTP URLs on HTTPS) | `post_promotion_validate.sh` — mixed content |
| MI-015 | Plugins/Themes | MEDIUM | PHP Deprecation Warnings Visible | `post_promotion_validate.sh` — visible PHP errors |
| MI-016 | Performance | LOW | Multiple CloudFront Invalidation Cycles | Manual — single invalidation at end |
| MI-017 | Configuration | LOW | AWS SSO Token Expiration During Migration | `pre_promotion_validate.sh` — AWS auth |
| MI-018 | Networking/SSL | CRITICAL | HTTPS Redirect Loop (301 forever) | `post_promotion_validate.sh` — HTTP status |
| MI-019 | Infrastructure | HIGH | Target Group Unhealthy Targets (502/503) | `post_promotion_validate.sh` — ECS target health |
| MI-020 | Infrastructure | HIGH | ECS Task ResourceInitializationError (EFS IAM) | `pre_promotion_validate.sh` — ECS service health |
| MI-021 | Infrastructure | HIGH | Secrets Manager AccessDeniedException | `pre_promotion_validate.sh` — ECS service health |
| MI-022 | Files/EFS | HIGH | EFS Access Point Path Wrong (/tenant vs /tenant/wp-content) | `pre_promotion_validate.sh` — ECS service health |
| MI-023 | Configuration | MEDIUM | Old Xneelo Credentials in wp-config.php | Manual — use env vars in task def |
| MI-024 | Plugins/Themes | HIGH | Really Simple SSL Causing Redirect Loops | Pre-import: prepare-wordpress-for-migration.sh |
| MI-025 | Plugins/Themes | MEDIUM | Wordfence Blocking CloudFront IPs | Pre-import: prepare-wordpress-for-migration.sh |
| MI-026 | Performance | MEDIUM | EFS Upload Timeout for Large Sites (>500MB) | `pre_promotion_validate.sh` — site size check |
| MI-027 | Infrastructure | MEDIUM | SSM/SSH Connection Drops During Long Ops | Manual — use nohup or screen |
| MI-028 | Plugins/Themes | MEDIUM | Uncode Theme Shortcodes as Raw Text | Manual — increase PHP limits |
| MI-029 | Plugins/Themes | MEDIUM | Divi Builder CSS Not Generating | Manual — clear et-cache |
| MI-030 | Database | HIGH | Database Charset Mismatch on Import | `pre_promotion_validate.sh` — DB charset |

---

## Category Index

| Category | Count | MI-IDs |
|----------|-------|--------|
| Configuration | 6 | MI-001, MI-002, MI-011, MI-017, MI-023, MI-030 |
| Database | 3 | MI-003, MI-009, MI-030 |
| Files/EFS | 4 | MI-005, MI-006, MI-007, MI-022 |
| Networking/SSL | 3 | MI-010, MI-014, MI-018 |
| Plugins/Themes | 8 | MI-008, MI-012, MI-013, MI-015, MI-024, MI-025, MI-028, MI-029 |
| Infrastructure | 4 | MI-004, MI-019, MI-020, MI-021 |
| Performance | 3 | MI-016, MI-026, MI-027 |

---

## Detailed Entries

---

### MI-001 — S3 Bucket Access Denied (403 Forbidden)

| Field | Value |
|-------|-------|
| **Category** | Configuration |
| **Severity** | HIGH |
| **Source Migration** | Manufacturing-Websites (Error C1) |
| **Phase** | Pre-Migration / Setup |

**Description:**
Bastion host cannot access the S3 migration bucket. `aws s3 ls` returns 403 Forbidden because the bastion's IAM role is not included in the S3 bucket policy.

**Root Cause:**
S3 bucket policy only allows specific IAM roles. New bastion roles or cross-account roles are not automatically included.

**Resolution:**
```json
{
    "Effect": "Allow",
    "Principal": {
        "AWS": "arn:aws:iam::536580886816:role/bastion-host-role"
    },
    "Action": ["s3:GetObject", "s3:ListBucket"],
    "Resource": [
        "arn:aws:s3:::wordpress-migration-temp-20250903",
        "arn:aws:s3:::wordpress-migration-temp-20250903/*"
    ]
}
```

**Prevention Rule:**
Before starting any migration, verify S3 access from the bastion: `aws s3 ls s3://bucket/tenant/ --summarize`

**Validation Script:** `pre_promotion_validate.sh` — Check 1 (AWS authentication)

---

### MI-002 — SSM Command Quoting Failures with Complex SQL

| Field | Value |
|-------|-------|
| **Category** | Configuration |
| **Severity** | MEDIUM |
| **Source Migration** | Manufacturing-Websites (Error C2) |
| **Phase** | Database Migration |

**Description:**
SSM Run Command fails with syntax errors when passing SQL containing quotes, backticks, or heredocs through the `--parameters` flag.

**Root Cause:**
SSM parameter strings require careful escaping of single quotes, double quotes, and backticks. Complex SQL with nested quoting breaks.

**Resolution:**
Use file-based approach — upload SQL to bastion, then execute locally:
```bash
# Upload SQL file to S3
aws s3 cp complex-query.sql s3://bucket/temp/
# Execute from bastion filesystem
aws ssm send-command --instance-ids "$BASTION_ID" \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=["aws s3 cp s3://bucket/temp/query.sql /tmp/ && mysql -h HOST -u USER -pPASS DB < /tmp/query.sql"]'
```
Alternative: Base64-encode complex queries for inline execution.

**Prevention Rule:**
Never pass SQL with special characters directly in SSM `--parameters`. Always use file-based execution for anything beyond simple SELECT/UPDATE.

**Validation Script:** N/A — manual practice

---

### MI-003 — UTF-8 Encoding Artifacts in Content

| Field | Value |
|-------|-------|
| **Category** | Database |
| **Severity** | MEDIUM |
| **Source Migration** | Manufacturing-Websites (Error C3), AuPairHive (Issue 4) |
| **Phase** | Database Migration |

**Description:**
Special characters display incorrectly after migration: apostrophes show as `â€™`, em dashes as `â€"`, ellipses as `â€¦`. Content appears corrupted.

**Root Cause:**
Double-encoding: source database exported without `--default-character-set=utf8mb4`, or import process misinterpreted existing UTF-8 as Latin-1.

**Resolution:**
```sql
-- Fix smart quotes
UPDATE wp_posts SET post_content = REPLACE(post_content, 'â€™', ''') WHERE post_content LIKE '%â€™%';
UPDATE wp_posts SET post_content = REPLACE(post_content, 'â€œ', '"') WHERE post_content LIKE '%â€œ%';
UPDATE wp_posts SET post_content = REPLACE(post_content, 'â€', '"') WHERE post_content LIKE '%â€%';
-- Fix dashes and special characters
UPDATE wp_posts SET post_content = REPLACE(post_content, 'â€"', '—') WHERE post_content LIKE '%â€"%';
UPDATE wp_posts SET post_content = REPLACE(post_content, 'â€¦', '…') WHERE post_content LIKE '%â€¦%';
-- Also fix postmeta
UPDATE wp_postmeta SET meta_value = REPLACE(meta_value, 'â€™', ''') WHERE meta_value LIKE '%â€™%';
```

**Prevention Rule:**
ALWAYS use `mysqldump --default-character-set=utf8mb4` for export AND `mysql --default-character-set=utf8mb4` for import.

**Validation Script:** `pre_promotion_validate.sh` — Check 8 (DB charset), `post_promotion_validate.sh` — Check 4 (encoding artifacts)

---

### MI-004 — ECS Exec SessionManagerPlugin Not Found

| Field | Value |
|-------|-------|
| **Category** | Infrastructure |
| **Severity** | LOW |
| **Source Migration** | Manufacturing-Websites (Error C4) |
| **Phase** | Any (debugging) |

**Description:**
`aws ecs execute-command` fails with "SessionManagerPlugin is not found" error. Cannot establish interactive session to WordPress container.

**Root Cause:**
Session Manager Plugin not installed on the local workstation.

**Resolution:**
```bash
# macOS install
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/mac/sessionmanager-bundle.zip" -o "sessionmanager-bundle.zip"
unzip sessionmanager-bundle.zip
sudo ./sessionmanager-bundle/install -i /usr/local/sessionmanagerplugin -b /usr/local/bin/session-manager-plugin
```
**Workaround:** Use CloudWatch Logs: `aws logs tail /ecs/dev-tenant-task --follow`

**Prevention Rule:**
Install Session Manager plugin on all workstations used for migrations. Use bastion host as primary access method (not ECS Exec).

**Validation Script:** `pre_promotion_validate.sh` — Check 1 (AWS auth covers SSM availability)

---

### MI-005 — EFS File Permissions (root instead of www-data 33:33)

| Field | Value |
|-------|-------|
| **Category** | Files/EFS |
| **Severity** | HIGH |
| **Source Migration** | Manufacturing-Websites (Error C5) |
| **Phase** | Files Migration |

**Description:**
Files copied to EFS with root ownership. WordPress container runs as UID 33 (www-data) and cannot read/write to wp-content. Apache logs show "Permission denied".

**Root Cause:**
Files copied via `cp`, `rsync`, or `tar` default to root ownership. Must explicitly chown to 33:33.

**Resolution:**
```bash
# Fix ownership
sudo chown -R 33:33 /mnt/efs/
# Fix directory permissions
sudo find /mnt/efs -type d -exec chmod 755 {} \;
# Fix file permissions
sudo find /mnt/efs -type f -exec chmod 644 {} \;
```

**Prevention Rule:**
ALWAYS run `chown -R 33:33` immediately after any file copy to EFS. Include this as a mandatory step in the file import process.

**Validation Script:** `post_promotion_validate.sh` — Check 7 (EFS mount / static files)

---

### MI-006 — Homepage Returns Empty Content (0 bytes)

| Field | Value |
|-------|-------|
| **Category** | Files/EFS |
| **Severity** | CRITICAL |
| **Source Migration** | Manufacturing-Websites (Validation Error 1) |
| **Phase** | Post-Deployment |

**Description:**
Homepage returns HTTP 200 but with 0 bytes content. All frontend pages empty. wp-login.php and REST API work correctly because they don't depend on EFS-mounted wp-content.

**Root Cause:**
EFS volume not properly mounted after ECS task deployment. Container started before EFS mount completed.

**Resolution:**
```bash
# Force ECS service redeployment to refresh EFS mount
aws ecs update-service \
  --cluster dev-cluster \
  --service dev-tenant-service \
  --force-new-deployment
```

**Prevention Rule:**
After any ECS deployment, verify content size is non-zero: `curl -s -o /dev/null -w "%{size_download}" "https://tenant.domain/"`. If 0 bytes, force redeploy.

**Validation Script:** `post_promotion_validate.sh` — Check 1 (HTTP status) + Check 2 (content size)

---

### MI-007 — Static Files Returning 404

| Field | Value |
|-------|-------|
| **Category** | Files/EFS |
| **Severity** | CRITICAL |
| **Source Migration** | Manufacturing-Websites (Validation Error 2) |
| **Phase** | Post-Deployment |

**Description:**
Theme CSS, plugin assets, and uploaded media all return 404. Files exist on EFS (verified from bastion) but are inaccessible via HTTP.

**Root Cause:**
Same as MI-006 — EFS mount not active in the container. The WordPress core (copied into the container image) works, but the EFS-mounted `/var/www/html/wp-content` is empty.

**Resolution:**
Same as MI-006 — force ECS service redeployment.

**Prevention Rule:**
After deployment, always verify a known static file returns 200: `curl -s -o /dev/null -w "%{http_code}" "https://tenant.domain/wp-content/themes/theme-name/style.css"`.

**Validation Script:** `post_promotion_validate.sh` — Check 8 (theme CSS)

---

### MI-008 — Elementor Templates in Draft Status

| Field | Value |
|-------|-------|
| **Category** | Plugins/Themes |
| **Severity** | HIGH |
| **Source Migration** | Manufacturing-Websites (Validation Error 3) |
| **Phase** | Post-Import Configuration |

**Description:**
Homepage renders but shows no content. Elementor Theme Builder templates not loading because they are in "draft" status.

**Root Cause:**
Source site had templates in draft. Migration preserves the post status. Elementor Theme Builder requires templates to be "publish" to render.

**Resolution:**
```sql
-- Publish all Elementor library templates
UPDATE wp_posts SET post_status = 'publish'
WHERE post_type = 'elementor_library' AND post_status = 'draft';
-- Clear Elementor cache
DELETE FROM wp_options WHERE option_name LIKE '%elementor%cache%';
```

**Prevention Rule:**
After any migration involving Elementor, check: `SELECT ID, post_title, post_status FROM wp_posts WHERE post_type = 'elementor_library';`

**Validation Script:** `post_promotion_validate.sh` — Check 2 (content size detects empty pages)

---

### MI-009 — Incomplete URL Replacement (Yoast SEO Tables)

| Field | Value |
|-------|-------|
| **Category** | Database |
| **Severity** | MEDIUM |
| **Source Migration** | Manufacturing-Websites (Validation Error 4) |
| **Phase** | Post-Import Configuration |

**Description:**
Canonical URLs and Yoast SEO meta tags still point to the old domain after URL replacement. Standard WordPress tables updated but Yoast-specific tables missed.

**Root Cause:**
URL replacement only covered `wp_options`, `wp_posts`, `wp_postmeta`. Missed `wp_yoast_indexable` and `wp_yoast_seo_links`.

**Resolution:**
```sql
-- Update Yoast indexable table
UPDATE wp_yoast_indexable
SET permalink = REPLACE(permalink, 'old-domain.com', 'new-domain.com')
WHERE permalink LIKE '%old-domain.com%';
-- Update Yoast SEO links
UPDATE wp_yoast_seo_links
SET url = REPLACE(url, 'old-domain.com', 'new-domain.com')
WHERE url LIKE '%old-domain.com%';
```

**Prevention Rule:**
URL replacement SQL MUST include ALL tables: `wp_options`, `wp_posts`, `wp_postmeta`, `wp_comments`, `wp_yoast_indexable`, `wp_yoast_seo_links`. Use `sed` on the export SQL file for comprehensive replacement.

**Validation Script:** `post_promotion_validate.sh` — Check 6 (canonical URL)

---

### MI-010 — CloudFront Basic Auth Blocking Access

| Field | Value |
|-------|-------|
| **Category** | Networking/SSL |
| **Severity** | HIGH |
| **Source Migration** | Manufacturing-Websites (Validation Error 5) |
| **Phase** | Post-Deployment |

**Description:**
DEV/SIT sites protected by CloudFront basic auth function. Newly migrated tenant not in the exclusion list, requiring auth credentials for all access.

**Root Cause:**
CloudFront Function `wpdev-basic-auth` has a `noAuthTenants` array. New tenants must be added manually.

**Resolution:**
Add tenant to the CloudFront Function's `noAuthTenants` array:
```javascript
var noAuthTenants = [
    'aupairhive.wpdev.kimmyai.io',
    'newtenant.wpdev.kimmyai.io'  // Add new tenant
];
```
Then update and publish the function.

**Prevention Rule:**
Add tenant to CloudFront exclusion list BEFORE starting migration testing. Or use auth credentials: DEV=`dev:ovcjaopj1ooojajo`, SIT=`bigbeard:BigBeard2026!`.

**Validation Script:** `pre_promotion_validate.sh` — Check 3 (HTTP status includes auth check)

---

### MI-011 — WordPress Admin Password Unknown After Migration

| Field | Value |
|-------|-------|
| **Category** | Configuration |
| **Severity** | HIGH |
| **Source Migration** | Manufacturing-Websites (Validation Error 6) |
| **Phase** | Post-Import Configuration |

**Description:**
Cannot log into wp-admin. Original site password migrated as a hash — cannot be reversed.

**Root Cause:**
WordPress stores passwords as hashed values. Migration preserves the hash but the plaintext is unknown.

**Resolution:**
```sql
-- Reset password via database
UPDATE wp_users SET user_pass = MD5('TempPassword123!') WHERE user_login = 'admin';
```
User should change password after first login.

**Prevention Rule:**
During migration planning, document admin credentials or plan for a password reset step.

**Validation Script:** `post_promotion_validate.sh` — Check 10 (wp-admin accessibility)

---

### MI-012 — reCAPTCHA Validation Failing (Domain Mismatch)

| Field | Value |
|-------|-------|
| **Category** | Plugins/Themes |
| **Severity** | MEDIUM |
| **Source Migration** | Manufacturing-Websites (Validation Error 7) |
| **Phase** | Post-Import Configuration |

**Description:**
Form submissions fail with "reCAPTCHA V3 validation failed". Keys registered for the original domain do not work on the new domain.

**Root Cause:**
Google reCAPTCHA keys are domain-specific. Keys for `oldsite.com` reject requests from `tenant.wpdev.kimmyai.io`.

**Resolution:**
```sql
-- Clear reCAPTCHA keys for DEV/SIT
UPDATE wp_options SET option_value = ''
WHERE option_name IN (
    'elementor_pro_recaptcha_v3_site_key',
    'elementor_pro_recaptcha_v3_secret_key',
    'elementor_pro_recaptcha_site_key',
    'elementor_pro_recaptcha_secret_key'
);
-- Clear transient cache
DELETE FROM wp_options WHERE option_name LIKE '%_transient_%';
```
For PROD: Register new keys at https://www.google.com/recaptcha/admin.

**Prevention Rule:**
Document all domain-specific third-party integrations before migration. Plan to clear/reconfigure reCAPTCHA, Analytics, Pixels.

**Validation Script:** `post_promotion_validate.sh` — Check 9 (form endpoint)

---

### MI-013 — Wrong Theme Active After Migration

| Field | Value |
|-------|-------|
| **Category** | Plugins/Themes |
| **Severity** | HIGH |
| **Source Migration** | AuPairHive (Issue 1) |
| **Phase** | Post-Import Configuration |

**Description:**
Site renders with incorrect styling. A backup or old theme is active in `wp_options` instead of the correct child theme.

**Root Cause:**
Source site's `wp_options` table had a backup theme set as active (e.g., `Divi_backup_old` instead of `Divi_Child`). No pre-migration check of active theme.

**Resolution:**
```sql
-- Check current active theme
SELECT option_value FROM wp_options WHERE option_name IN ('template', 'stylesheet', 'current_theme');
-- Activate correct theme
UPDATE wp_options SET option_value = 'Divi_Child' WHERE option_name = 'stylesheet';
UPDATE wp_options SET option_value = 'Divi' WHERE option_name = 'template';
```

**Prevention Rule:**
Before migration, query source database for active theme and verify it matches expected child theme.

**Validation Script:** `pre_promotion_validate.sh` — Check 9 (active theme)

---

### MI-014 — Mixed Content (HTTP URLs on HTTPS Site)

| Field | Value |
|-------|-------|
| **Category** | Networking/SSL |
| **Severity** | CRITICAL |
| **Source Migration** | AuPairHive (Issue 2) |
| **Phase** | Post-Deployment |

**Description:**
Site served via HTTPS but WordPress generates HTTP URLs for assets. Broken CSS, missing images, JavaScript errors. Site unusable.

**Root Cause:**
CloudFront terminates SSL and sends HTTP to ALB. WordPress's `is_ssl()` detects HTTP, generates HTTP URLs. The `force-https.php` MU-plugin was not deployed.

**Resolution:**
Deploy `force-https.php` MU-plugin that sets `$_SERVER['HTTPS'] = 'on'` unconditionally. Also ensure `WORDPRESS_CONFIG_EXTRA` in ECS task definition includes `$_SERVER['HTTPS'] = 'on';`.

**Prevention Rule:**
ALWAYS deploy the force-https.php MU-plugin BEFORE first site access. ALWAYS include `$_SERVER['HTTPS'] = 'on';` in WORDPRESS_CONFIG_EXTRA.

**Validation Script:** `post_promotion_validate.sh` — Check 3 (mixed content)

---

### MI-015 — PHP Deprecation Warnings Visible on Site

| Field | Value |
|-------|-------|
| **Category** | Plugins/Themes |
| **Severity** | MEDIUM |
| **Source Migration** | AuPairHive (Issue 3) |
| **Phase** | Post-Deployment |

**Description:**
Thousands of PHP 8.x deprecation warnings from legacy themes/plugins. Site output cluttered, performance impacted, unprofessional appearance.

**Root Cause:**
PHP version upgrade (7.x → 8.x) between source and target. Legacy code uses dynamic properties and deprecated functions.

**Resolution:**
Add to `WORDPRESS_CONFIG_EXTRA`:
```php
define('WP_DEBUG', false);
define('WP_DEBUG_LOG', false);
define('WP_DEBUG_DISPLAY', false);
@ini_set('display_errors', 0);
```
Or deploy error-suppression MU-plugin.

**Prevention Rule:**
Always set `WORDPRESS_DEBUG=0` in ECS task definition. Check PHP version compatibility before migration.

**Validation Script:** `post_promotion_validate.sh` — Check 14 (visible PHP errors)

---

### MI-016 — Multiple CloudFront Invalidation Cycles

| Field | Value |
|-------|-------|
| **Category** | Performance |
| **Severity** | LOW |
| **Source Migration** | AuPairHive (Issue 5) |
| **Phase** | Post-Migration |

**Description:**
Required 3-4 CloudFront invalidations throughout migration, each taking 5-10 minutes. Total delay: 30-45 minutes.

**Root Cause:**
Changes made iteratively without clearing caches between fixes. Both browser cache and CloudFront cache needed clearing.

**Resolution:**
Lower CloudFront TTL during migration (60 seconds). Make all fixes first, then run a single `/*` invalidation at the end.

**Prevention Rule:**
Do NOT invalidate CloudFront after each fix. Batch all changes, then perform a single invalidation as the final step.

**Validation Script:** N/A — process optimization

---

### MI-017 — AWS SSO Token Expiration During Migration

| Field | Value |
|-------|-------|
| **Category** | Configuration |
| **Severity** | LOW |
| **Source Migration** | AuPairHive (Issue 6) |
| **Phase** | Any |

**Description:**
AWS SSO tokens expire (typically 1 hour) during long troubleshooting sessions, interrupting workflows and requiring re-authentication.

**Root Cause:**
Default SSO session duration is 1 hour. Long migrations exceed this window.

**Resolution:**
```bash
# Re-authenticate
aws sso login --profile dev
```

**Prevention Rule:**
Before starting migration, verify SSO token freshness. Use `aws sts get-caller-identity --profile dev` to confirm.

**Validation Script:** `pre_promotion_validate.sh` — Check 1 (AWS auth)

---

### MI-018 — HTTPS Redirect Loop (301 Forever)

| Field | Value |
|-------|-------|
| **Category** | Networking/SSL |
| **Severity** | CRITICAL |
| **Source Migration** | Playbook Troubleshooting |
| **Phase** | Post-Deployment |

**Description:**
Browser shows "too many redirects". WordPress detects HTTP from ALB and issues 301 to HTTPS. CloudFront follows redirect and sends HTTP again — infinite loop.

**Root Cause:**
Architecture: CloudFront (HTTPS) → ALB (HTTP) → Container (HTTP). WordPress or SSL plugins detect HTTP and redirect to HTTPS, but ALB always sends HTTP.

**Resolution:**
1. Set `$_SERVER['HTTPS'] = 'on';` in WORDPRESS_CONFIG_EXTRA
2. Deactivate redirect-causing plugins (Really Simple SSL, Wordfence, etc.)
3. Deploy force-https.php MU-plugin
4. Force ECS redeployment

**Prevention Rule:**
Run `prepare-wordpress-for-migration.sh` on EVERY database export BEFORE import. Always include HTTPS detection in task definition.

**Validation Script:** `post_promotion_validate.sh` — Check 1 (HTTP status — catches 301 loops)

---

### MI-019 — Target Group Shows Unhealthy Targets (502/503)

| Field | Value |
|-------|-------|
| **Category** | Infrastructure |
| **Severity** | HIGH |
| **Source Migration** | Playbook Troubleshooting |
| **Phase** | Post-Deployment |

**Description:**
Site returns 502/503 errors. ECS task is running but ALB target group shows "unhealthy". Container started successfully per CloudWatch logs.

**Root Cause:**
Health check misconfiguration: wrong path (e.g., `/wp-admin/admin-ajax.php` returns 400), wrong matcher (expects 200 only but WordPress returns 301/302), or wrong protocol (HTTPS instead of HTTP).

**Resolution:**
```bash
aws elbv2 modify-target-group \
  --target-group-arn "$TG_ARN" \
  --health-check-path "/" \
  --health-check-protocol HTTP \
  --matcher HttpCode=200-302
```

**Prevention Rule:**
Health check path MUST be `/`. Matcher MUST be `200-302`. Protocol MUST be `HTTP`.

**Validation Script:** `post_promotion_validate.sh` — Check 13 (ECS target health)

---

### MI-020 — ECS Task ResourceInitializationError (EFS IAM)

| Field | Value |
|-------|-------|
| **Category** | Infrastructure |
| **Severity** | HIGH |
| **Source Migration** | Playbook Troubleshooting |
| **Phase** | Infrastructure Provisioning |

**Description:**
ECS task fails immediately with "ResourceInitializationError: failed to invoke EFS utils commands". Task never reaches RUNNING state.

**Root Cause:**
Missing IAM inline policy on the ECS task role for the tenant-specific EFS access point.

**Resolution:**
```bash
aws iam put-role-policy \
  --role-name dev-ecs-task-role \
  --policy-name "dev-ecs-efs-access-tenant" \
  --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":["elasticfilesystem:ClientMount","elasticfilesystem:ClientWrite","elasticfilesystem:ClientRootAccess"],"Resource":"EFS_AP_ARN"}]}'
```

**Prevention Rule:**
After creating an EFS access point, ALWAYS add the IAM inline policy to the task role before deploying the ECS service.

**Validation Script:** `pre_promotion_validate.sh` — Check 2 (ECS service health)

---

### MI-021 — Secrets Manager AccessDeniedException

| Field | Value |
|-------|-------|
| **Category** | Infrastructure |
| **Severity** | HIGH |
| **Source Migration** | Playbook Troubleshooting |
| **Phase** | Infrastructure Provisioning |

**Description:**
ECS task fails during startup. Error mentions Secrets Manager access denied. Database connection never established.

**Root Cause:**
Missing resource-based policy on the Secrets Manager secret. ECS execution role cannot read the database credentials.

**Resolution:**
```bash
aws secretsmanager put-resource-policy \
  --secret-id dev-tenant-db-credentials \
  --resource-policy '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"AWS":"arn:aws:iam::536580886816:role/dev-ecs-task-execution-role"},"Action":"secretsmanager:GetSecretValue","Resource":"*"}]}'
```

**Prevention Rule:**
After creating a Secrets Manager secret for a new tenant, ALWAYS add the resource-based policy allowing the ECS execution role.

**Validation Script:** `pre_promotion_validate.sh` — Check 2 (ECS service health)

---

### MI-022 — EFS Access Point Path Wrong

| Field | Value |
|-------|-------|
| **Category** | Files/EFS |
| **Severity** | HIGH |
| **Source Migration** | Playbook Troubleshooting |
| **Phase** | Infrastructure Provisioning |

**Description:**
Files uploaded to EFS but WordPress cannot see them. Access point path is `/tenant` instead of `/tenant/wp-content`.

**Root Cause:**
EFS access point created with wrong root directory path. Container mounts at `/var/www/html/wp-content` but the access point resolves to the wrong EFS path.

**Resolution:**
Delete and recreate the access point with the correct path:
```bash
aws efs create-access-point \
  --file-system-id "$EFS_ID" \
  --root-directory "Path=/${TENANT}/wp-content,CreationInfo={OwnerUid=33,OwnerGid=33,Permissions=755}" \
  --posix-user "Uid=33,Gid=33"
```

**Prevention Rule:**
ALWAYS verify access point path after creation: `aws efs describe-access-points --access-point-id AP_ID --query 'AccessPoints[0].RootDirectory.Path'`. Must return `/{tenant}/wp-content`.

**Validation Script:** `pre_promotion_validate.sh` — Check 2 (ECS service health — catches container failures)

---

### MI-023 — Old Xneelo Credentials in wp-config.php

| Field | Value |
|-------|-------|
| **Category** | Configuration |
| **Severity** | MEDIUM |
| **Source Migration** | Playbook Troubleshooting |
| **Phase** | Files Migration |

**Description:**
wp-config.php contains old database host (e.g., `mysql.xneelo.co.za`) and old credentials. Site fails to connect to database.

**Root Cause:**
wp-config.php from the source site was copied to EFS. ECS container should generate wp-config.php from environment variables, but the copied file takes precedence.

**Resolution:**
Do NOT copy wp-config.php to EFS. Let the WordPress container image generate it from environment variables (`WORDPRESS_DB_HOST`, `WORDPRESS_DB_NAME`, etc.).

**Prevention Rule:**
When extracting wp-content from source site, exclude wp-config.php: `tar --exclude='wp-config.php'`.

**Validation Script:** N/A — manual file exclusion during export

---

### MI-024 — Really Simple SSL Plugin Causing Redirect Loops

| Field | Value |
|-------|-------|
| **Category** | Plugins/Themes |
| **Severity** | HIGH |
| **Source Migration** | Playbook — Problematic Plugins |
| **Phase** | Pre-Import |

**Description:**
Really Simple SSL plugin detects HTTP from ALB and issues 301 redirect to HTTPS. Combined with CloudFront SSL termination, this creates an infinite redirect loop.

**Root Cause:**
Plugin designed for traditional hosting where the web server handles SSL. In CloudFront → ALB → Container architecture, the origin connection is always HTTP.

**Resolution:**
Run `prepare-wordpress-for-migration.sh` on every SQL export before import. This deactivates Really Simple SSL from the serialized `active_plugins` array.

**Prevention Rule:**
MANDATORY: Run `prepare-wordpress-for-migration.sh input.sql output-fixed.sql` on EVERY database export before importing to RDS.

**Validation Script:** Pre-import script handles this automatically.

---

### MI-025 — Wordfence Blocking CloudFront IPs

| Field | Value |
|-------|-------|
| **Category** | Plugins/Themes |
| **Severity** | MEDIUM |
| **Source Migration** | Playbook — Problematic Plugins |
| **Phase** | Pre-Import |

**Description:**
Wordfence firewall blocks requests from CloudFront IP ranges, causing 403 errors or login protection issues.

**Root Cause:**
Wordfence sees all requests from CloudFront/ALB IP addresses (not the real client IP). Its security rules may rate-limit or block these IPs.

**Resolution:**
Deactivated by `prepare-wordpress-for-migration.sh`. For manual fix:
```sql
-- Disable Wordfence firewall
UPDATE wp_options SET option_value = '0' WHERE option_name = 'wordfence_wafStatus';
```

**Prevention Rule:**
Same as MI-024 — always run the prepare script before import.

**Validation Script:** Pre-import script handles this automatically.

---

### MI-026 — EFS Upload Timeout for Large Sites (>500MB)

| Field | Value |
|-------|-------|
| **Category** | Performance |
| **Severity** | MEDIUM |
| **Source Migration** | Playbook — Performance Optimization |
| **Phase** | Files Migration |

**Description:**
Direct upload to EFS via SSM session times out for sites with large media libraries (>500MB). Upload stalls or connection drops.

**Root Cause:**
SSM session timeout (20-30 minutes) and slow local-to-bastion transfer speed for large files.

**Resolution:**
For sites >500MB, use S3 staging instead of direct transfer:
```bash
# Upload to S3 (faster, resume-capable)
aws s3 cp wp-content.tar.gz s3://bucket/tenant/
# Download on bastion and extract to EFS (fast, within AWS)
```

**Prevention Rule:**
Check total wp-content size before transfer. If >500MB, use S3 staging. If <500MB, direct bastion upload.

**Validation Script:** `pre_promotion_validate.sh` — Check 11 (site size / transfer recommendation)

---

### MI-027 — SSM/SSH Connection Drops During Long Operations

| Field | Value |
|-------|-------|
| **Category** | Performance |
| **Severity** | MEDIUM |
| **Source Migration** | Playbook — Performance Optimization |
| **Phase** | Any long-running operation |

**Description:**
SSM sessions disconnect during long database imports or file transfers. Operations may complete but output is lost. Must check manually.

**Root Cause:**
Default SSM session timeout (20 minutes idle). Network instability. Client-side idle detection.

**Resolution:**
Use `nohup` or `screen` for long operations:
```bash
# Run in background
nohup mysql -h HOST -u USER -pPASS DB < /tmp/import.sql > /tmp/import.log 2>&1 &
# Or use screen
screen -S migration
# (run commands, detach with Ctrl+A+D, reconnect with screen -r migration)
```

**Prevention Rule:**
For any operation expected to take >15 minutes, use `nohup` or `screen`. Check results via CloudWatch logs or SSM Run Command.

**Validation Script:** N/A — operational practice

---

### MI-028 — Uncode Theme Shortcodes as Raw Text

| Field | Value |
|-------|-------|
| **Category** | Plugins/Themes |
| **Severity** | MEDIUM |
| **Source Migration** | Playbook — Theme-Specific Issues |
| **Phase** | Post-Import |

**Description:**
Visual Composer shortcodes appear as raw text (`[vc_row][vc_column]...`) on the frontend. Theme shows "not registered" warning.

**Root Cause:**
Uncode theme requires Envato Purchase Code for full functionality. Also needs higher PHP memory limits than default.

**Resolution:**
1. Increase PHP limits: `PHP_MEMORY_LIMIT=512M`, `PHP_MAX_INPUT_VARS=5000`
2. Enter Envato Purchase Code in Appearance → Uncode → Product License
3. Add `define('WP_MEMORY_LIMIT', '256M');` to WORDPRESS_CONFIG_EXTRA

**Prevention Rule:**
Check source theme before migration. If Uncode/Divi/Elementor Pro, ensure license keys are documented and PHP limits are adequate.

**Validation Script:** N/A — theme-specific manual check

---

### MI-029 — Divi Builder CSS Not Generating

| Field | Value |
|-------|-------|
| **Category** | Plugins/Themes |
| **Severity** | MEDIUM |
| **Source Migration** | Playbook — Theme-Specific Issues |
| **Phase** | Post-Import |

**Description:**
Divi Builder not loading, module content not rendering, CSS not generating.

**Root Cause:**
Divi cache (`et-cache`) from the old site is stale. Static CSS needs regeneration for the new domain.

**Resolution:**
```bash
# Clear Divi cache
rm -rf /mnt/efs/tenant/wp-content/et-cache/*
# Force CSS regeneration
# Add to WORDPRESS_CONFIG_EXTRA:
define('ET_BUILDER_ALWAYS_GENERATE_STATIC_CSS', true);
```

**Prevention Rule:**
After any Divi migration, clear the `et-cache` directory and force a redeploy.

**Validation Script:** `post_promotion_validate.sh` — Check 8 (theme CSS) catches missing CSS

---

### MI-030 — Database Charset Mismatch on Import

| Field | Value |
|-------|-------|
| **Category** | Database |
| **Severity** | HIGH |
| **Source Migration** | AuPairHive + Manufacturing-Websites (combined lesson) |
| **Phase** | Database Migration |

**Description:**
Target database created with different charset/collation than source. Import succeeds but data is corrupted — encoding artifacts appear throughout content.

**Root Cause:**
Source database uses `utf8mb4_unicode_ci` but target created with `utf8mb4_general_ci` or `latin1`. Character mapping mismatches.

**Resolution:**
```bash
# Verify source charset before export
mysql -h SOURCE -e "SHOW VARIABLES LIKE 'character_set_database';"
# Create target database with matching charset
CREATE DATABASE tenant_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
# Export and import with explicit charset
mysqldump --default-character-set=utf8mb4 ... > export.sql
mysql --default-character-set=utf8mb4 ... < export.sql
```

**Prevention Rule:**
ALWAYS verify source database charset. ALWAYS create target database with `utf8mb4 COLLATE utf8mb4_unicode_ci`. ALWAYS use `--default-character-set=utf8mb4` on both export and import.

**Validation Script:** `pre_promotion_validate.sh` — Check 7 (DB connectivity) + Check 8 (DB charset)

---

## Document Maintenance

When a new issue is discovered during a migration:

1. Check if it matches an existing MI-ID in this registry
2. If YES: Reference the MI-ID in the COE document and follow the documented resolution
3. If NO: Assign the next available MI-ID (MI-031, MI-032, etc.)
4. Add a full entry following the template above
5. Update the Quick-Reference Summary table
6. Update the Category Index

---

**Document Version:** 1.0
**Last Updated:** 2026-02-06
**Maintainer:** DevOps Agent
