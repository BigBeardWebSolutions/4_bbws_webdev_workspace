/Users/sithembisomjoko/Downloads/AGENTIC_WORK/2_bbws_agents/tenant/migrations# WordPress Tenant Migration Playbook - Automated Process

**Version:** 2.4 (FallenCovidHeroes Migration Lessons - Mandatory Constraints Added)
**Last Updated:** 2026-01-24
**Target:** Zero-touch, repeatable WordPress migrations to AWS ECS/Fargate

---

## Executive Summary

This playbook defines the **automated, standardized process** for migrating WordPress tenants to the BBWS multi-tenant hosting platform. The focus is on **reusability, consistency, and minimal human intervention**.

**Key Principles:**
- ✅ **Automation First** - Scripts handle 95% of the migration
- ✅ **Reusable Components** - MU-plugins, templates, validation scripts
- ✅ **Safe Testing** - Mock external services to prevent business impact
- ✅ **Zero Downtime** - Migrate to DEV/SIT before cutover
- ✅ **Rollback Ready** - One-command rollback capability

**Migration Time:**
- **Manual (Old Way):** 8-10 hours with troubleshooting
- **Automated (New Way):** 45-60 minutes end-to-end

---

## MANDATORY CONSTRAINTS - READ FIRST

**These rules are NON-NEGOTIABLE. Violating them will cause failures.**

### 1. Bastion Access: SSM ONLY

| Rule | Details |
|------|---------|
| **Access Method** | SSM Session Manager ONLY |
| **SSH Keys** | DO NOT EXIST - Never attempt SSH |
| **Connection** | `aws ssm start-session --target <instance-id>` |

**WRONG:**
```bash
ssh ec2-user@bastion-ip  # WILL FAIL - No SSH key
scp file.sql ec2-user@bastion:/tmp/  # WILL FAIL
```

**CORRECT:**
```bash
# Connect via SSM
aws ssm start-session --target i-xxxxxxxxx --profile dev

# File transfer via SSM port forwarding
aws ssm start-session --target i-xxxxxxxxx \
  --document-name AWS-StartPortForwardingSession \
  --parameters '{"portNumber":["22"],"localPortNumber":["2222"]}' \
  --profile dev
# Then: scp -P 2222 file.sql ssm-user@localhost:/tmp/
```

### 2. File Transfer: Size-Based Decision

| File Size | Method | Reason |
|-----------|--------|--------|
| **< 500MB** | Direct bastion upload | Faster, simpler, no S3 timeout issues |
| **> 500MB** | S3 staging | Avoids local connection timeouts |

**For small migrations (< 500MB total):**
```bash
# Step 1: Start SSM port forwarding
aws ssm start-session --target <bastion-id> \
  --document-name AWS-StartPortForwardingSession \
  --parameters '{"portNumber":["22"],"localPortNumber":["2222"]}' \
  --profile dev

# Step 2: SCP files directly to bastion
scp -P 2222 database.sql ssm-user@localhost:/tmp/
scp -P 2222 wp-content.tar.gz ssm-user@localhost:/tmp/

# Step 3: From bastion, copy to EFS/import to RDS
```

**NEVER do this for small files:**
```bash
# WRONG - S3 upload times out for slow connections
aws s3 cp large-file.tar.gz s3://bucket/path  # Connection timeout
```

### 3. Database Import: From Bastion Only

| Rule | Details |
|------|---------|
| **Import Location** | Always from bastion host |
| **Never** | Inline SQL via SSM Run Command |
| **Never** | Direct local-to-RDS connection |

**CORRECT:**
```bash
# From bastion
mysql -h rds-endpoint -u user -p database < /tmp/database.sql
```

### 4. HTTPS Redirect Fix: MANDATORY Before Import

| Rule | Details |
|------|---------|
| **Script** | `prepare-wordpress-for-migration.sh` |
| **When** | BEFORE importing database |
| **What** | Deactivates really-simple-ssl, wordfence, etc. |

```bash
# ALWAYS run this before import
./prepare-wordpress-for-migration.sh input.sql output-fixed.sql
```

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Pre-Flight Checklist](#pre-flight-checklist) *(UPDATED - Southerncrossbeach Lessons)*
3. [ECS Task Definition Configuration](#ecs-task-definition-configuration-critical) *(NEW - CRITICAL)*
4. [Bastion Host for Migration Operations](#bastion-host-for-migration-operations)
5. [SSL/TLS Certificate Management](#ssltls-certificate-management)
6. [Security Hardening](#security-hardening)
7. [Migration Process Overview](#migration-process-overview)
8. [Phase 1: Pre-Migration Analysis](#phase-1-pre-migration-analysis)
9. [Phase 2: Automated Migration Execution](#phase-2-automated-migration-execution)
10. [Phase 3: Post-Migration Validation](#phase-3-post-migration-validation)
11. [Phase 4: Testing with Mocked Services](#phase-4-testing-with-mocked-services)
12. [WordPress Cron Configuration](#wordpress-cron-configuration)
13. [PHP Configuration & Resource Limits](#php-configuration--resource-limits)
14. [Phase 5: SIT Promotion](#phase-5-sit-promotion)
15. [Phase 6: Production Cutover](#phase-6-production-cutover)
16. [Monitoring & Alerting Setup](#monitoring--alerting-setup)
17. [Post-Migration Backup Strategy](#post-migration-backup-strategy)
18. [Email Deliverability & DNS Records](#email-deliverability--dns-records)
19. [Go-Live Checklist & Cutover Procedures](#go-live-checklist--cutover-procedures)
20. [Rollback Procedures](#rollback-procedures)
21. [Disaster Recovery Plan](#disaster-recovery-plan)
22. [Performance Optimization](#performance-optimization)
23. [Cost Tracking & Optimization](#cost-tracking--optimization)
24. [WordPress Multisite Considerations](#wordpress-multisite-considerations)
25. [Troubleshooting Guide](#troubleshooting-guide)
26. [Additional Troubleshooting](#additional-troubleshooting-from-manufacturing-migration) *(UPDATED)*
27. [Migration Performance & Workflow Optimization](#migration-performance--workflow-optimization) *(NEW - v2.3)*
28. [Common Theme-Specific Issues](#common-theme-specific-issues) *(NEW - v2.3)*

---

## Prerequisites

### Required Tools

| Tool | Version | Purpose |
|------|---------|---------|
| AWS CLI | v2.x | AWS resource management |
| WP-CLI | Latest | WordPress database operations |
| MySQL Client | 8.0+ | Database operations |
| jq | Latest | JSON parsing |
| curl | Latest | HTTP testing |
| bc | Latest | Performance calculations |

### AWS Access

| Environment | AWS Profile | AWS Account | Region |
|-------------|-------------|-------------|--------|
| DEV | Tebogo-dev | 536580886816 | eu-west-1 |
| SIT | Tebogo-sit | 815856636111 | eu-west-1 |
| PROD | Tebogo-prod | 093646564004 | af-south-1 |

### Required Permissions

- ECS: execute-command, describe-tasks, describe-services
- RDS: Secrets Manager access for database credentials
- EFS: File system access for wp-content storage
- CloudFront: Create invalidations

### CloudFront Basic Auth Credentials

All DEV and SIT environments are protected by CloudFront Basic Authentication. Use these credentials to access sites during migration and testing.

| Environment | Username | Password | Domain Pattern |
|-------------|----------|----------|----------------|
| **DEV** | `dev` | `ovcjaopj1ooojajo` | `{tenant}.wpdev.kimmyai.io` |
| **SIT** | `bigbeard` | `BigBeard2026!` | `{tenant}.wpsit.kimmyai.io` |
| **PROD** | N/A | N/A | Custom domains (no basic auth) |

**Usage Examples:**
```bash
# Test DEV site with Basic Auth
curl -u dev:ovcjaopj1ooojajo https://yoursite.wpdev.kimmyai.io

# Test SIT site with Basic Auth
curl -u bigbeard:BigBeard2026! https://yoursite.wpsit.kimmyai.io
```

**Browser Access:**
- When prompted, enter the credentials above
- Credentials are cached per browser session

---

## Pre-Flight Checklist

**CRITICAL:** Run this checklist BEFORE starting any migration to prevent common errors.

This checklist is derived from documented issues across multiple migrations. Completing these checks proactively will save hours of troubleshooting.

### Stage 1: Access & Infrastructure Verification

#### S3 Bucket Access (Prevents Error C1)
```bash
# Set variables
BUCKET="wordpress-migration-temp-20250903"
TENANT_FOLDER="manufacturing"  # Change per tenant
BASTION_ID="i-0a95b5e545ce3cb5f"

# Test S3 access from bastion BEFORE starting migration
aws ssm send-command \
  --instance-ids "$BASTION_ID" \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=["aws s3 ls s3://'"$BUCKET"'/'"$TENANT_FOLDER"'/ --summarize"]' \
  --output text --query "Command.CommandId"

# Expected: List of files with total count and size
# If 403 Forbidden: Update S3 bucket policy to include bastion IAM role
```

**If S3 Access Fails:**
```json
// Add to S3 bucket policy
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

#### Session Manager Plugin (Prevents Error C4)
```bash
# Verify Session Manager plugin is installed locally
session-manager-plugin --version

# If not installed (macOS):
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/mac/sessionmanager-bundle.zip" -o "sessionmanager-bundle.zip"
unzip sessionmanager-bundle.zip
sudo ./sessionmanager-bundle/install -i /usr/local/sessionmanagerplugin -b /usr/local/bin/session-manager-plugin

# Alternative: Use CloudWatch Logs for debugging
aws logs tail /ecs/dev-${TENANT}-task --follow
```

#### CloudFront Basic Auth Exclusion (Prevents Error 5)
```bash
# Add tenant to CloudFront exclusion list EARLY in migration
# Get current function code
aws cloudfront get-function \
  --name wpdev-basic-auth \
  --stage DEVELOPMENT \
  --region us-east-1 \
  --query 'FunctionCode' \
  --output text | base64 -d > /tmp/cf-function.js

# Verify tenant is in noAuthTenants array or add it:
# var noAuthTenants = [
#     'aupairhive.wpdev.kimmyai.io',
#     'manufacturing.wpdev.kimmyai.io',  // Add new tenant
#     'newtenant.wpdev.kimmyai.io'       // Add here
# ];

# Update and publish function if changes made
```

### Stage 2: Database Migration Checks

#### Character Encoding Verification (Prevents Error C3)
```bash
# BEFORE importing database, verify source encoding
head -n 50 /path/to/export.sql | grep -i "character_set\|charset"

# Expected: utf8mb4
# If different, add to import command:
mysql --default-character-set=utf8mb4 -h $RDS_HOST -u admin -p"$RDS_PASS" $DB_NAME < export.sql
```

#### Complex SQL Handling (Prevents Error C2)
```bash
# For complex SQL with quotes/special characters, use file-based approach:
# 1. Upload SQL file to bastion
aws s3 cp complex-query.sql s3://$BUCKET/temp/

# 2. Execute from bastion (not via SSM parameters)
aws ssm send-command \
  --instance-ids "$BASTION_ID" \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=[
    "aws s3 cp s3://'"$BUCKET"'/temp/complex-query.sql /tmp/",
    "mysql -h '"$RDS_HOST"' -u admin -p'"'"'$RDS_PASS'"'"' '"$DB_NAME"' < /tmp/complex-query.sql"
  ]'

# Alternative: Use base64 encoding for inline SQL
ENCODED=$(echo "SELECT * FROM table WHERE content LIKE '%\"quote\"%';" | base64)
# Then decode and execute on bastion
```

#### Encoding Fix SQL Ready (Prevents Error C3)
```sql
-- Have this SQL ready to run post-import if encoding artifacts appear:
-- Save as fix-encoding.sql

-- Fix smart quotes
UPDATE wp_posts SET post_content = REPLACE(post_content, 'â€™', ''') WHERE post_content LIKE '%â€™%';
UPDATE wp_posts SET post_content = REPLACE(post_content, 'â€œ', '"') WHERE post_content LIKE '%â€œ%';
UPDATE wp_posts SET post_content = REPLACE(post_content, 'â€', '"') WHERE post_content LIKE '%â€%';

-- Fix dashes
UPDATE wp_posts SET post_content = REPLACE(post_content, 'â€"', '—') WHERE post_content LIKE '%â€"%';
UPDATE wp_posts SET post_content = REPLACE(post_content, 'â€"', '–') WHERE post_content LIKE '%â€"%';

-- Fix ellipsis
UPDATE wp_posts SET post_content = REPLACE(post_content, 'â€¦', '…') WHERE post_content LIKE '%â€¦%';

-- Apply to postmeta
UPDATE wp_postmeta SET meta_value = REPLACE(meta_value, 'â€™', ''') WHERE meta_value LIKE '%â€™%';
```

### Stage 3: File Migration Checks

#### EFS Permissions Template (Prevents Error C5)
```bash
# ALWAYS run this immediately after copying files to EFS:
# www-data UID:GID is 33:33 in WordPress containers

# Mount EFS
sudo mount -t efs -o tls,accesspoint=$EFS_ACCESS_POINT $EFS_ID:/ /mnt/efs

# Fix ownership (CRITICAL - do this immediately after copy)
sudo chown -R 33:33 /mnt/efs/

# Fix directory permissions
sudo find /mnt/efs -type d -exec chmod 755 {} \;

# Fix file permissions
sudo find /mnt/efs -type f -exec chmod 644 {} \;

# Verify
ls -la /mnt/efs/themes/
# Expected: drwxr-xr-x 33 33 ...
```

### Stage 4: Configuration Checks

#### URL Replacement Checklist (Prevents Error 4)
```bash
# Complete URL replacement must include ALL these tables:

# Core WordPress tables
UPDATE wp_options SET option_value = REPLACE(option_value, 'OLD_DOMAIN', 'NEW_DOMAIN') WHERE option_value LIKE '%OLD_DOMAIN%';
UPDATE wp_posts SET post_content = REPLACE(post_content, 'OLD_DOMAIN', 'NEW_DOMAIN') WHERE post_content LIKE '%OLD_DOMAIN%';
UPDATE wp_posts SET guid = REPLACE(guid, 'OLD_DOMAIN', 'NEW_DOMAIN') WHERE guid LIKE '%OLD_DOMAIN%';
UPDATE wp_postmeta SET meta_value = REPLACE(meta_value, 'OLD_DOMAIN', 'NEW_DOMAIN') WHERE meta_value LIKE '%OLD_DOMAIN%';

# Yoast SEO tables (if installed)
UPDATE wp_yoast_indexable SET permalink = REPLACE(permalink, 'OLD_DOMAIN', 'NEW_DOMAIN') WHERE permalink LIKE '%OLD_DOMAIN%';
UPDATE wp_yoast_seo_links SET url = REPLACE(url, 'OLD_DOMAIN', 'NEW_DOMAIN') WHERE url LIKE '%OLD_DOMAIN%';

# Comments
UPDATE wp_comments SET comment_author_url = REPLACE(comment_author_url, 'OLD_DOMAIN', 'NEW_DOMAIN') WHERE comment_author_url LIKE '%OLD_DOMAIN%';
```

#### Third-Party Integration Inventory (Prevents Error 7)
```markdown
# Document these BEFORE migration and plan for domain-specific reconfiguration:

| Integration | Domain-Specific? | DEV Action | PROD Action |
|-------------|------------------|------------|-------------|
| reCAPTCHA | YES | Clear keys | Register new domain |
| Google Analytics | YES | Mock/disable | Update property |
| Facebook Pixel | YES | Disable | Update domain |
| Stripe | YES | Use test keys | Update webhook URLs |
| Mailchimp | NO | Redirect emails | Verify settings |
```

### Stage 5: Validation Checks

#### EFS Mount Verification (Prevents Errors 1, 2)
```bash
# After ECS deployment, verify EFS mount via HTTP (not just bastion)
# This catches the "EFS not mounted after container start" issue

# Test static file access
curl -s -o /dev/null -w "%{http_code}" "https://${TENANT}.wpdev.kimmyai.io/wp-content/themes/hello-elementor/style.css"
# Expected: 200
# If 404: Force ECS service redeployment

# Test theme CSS
curl -s -o /dev/null -w "%{http_code}" "https://${TENANT}.wpdev.kimmyai.io/wp-content/plugins/elementor/assets/css/frontend.min.css"
# Expected: 200

# If static files return 404 but bastion shows files exist:
aws ecs update-service \
  --cluster dev-cluster \
  --service dev-${TENANT}-service \
  --force-new-deployment
```

#### Elementor Template Status (Prevents Error 3)
```sql
-- Run this check for ALL Elementor sites after migration:
SELECT ID, post_title, post_status, post_type
FROM wp_posts
WHERE post_type = 'elementor_library'
AND post_status != 'publish';

-- If any templates are in draft status, publish them:
UPDATE wp_posts
SET post_status = 'publish'
WHERE post_type = 'elementor_library'
AND post_status = 'draft';
```

#### WordPress Credentials (Prevents Error 6)
```bash
# Document admin credentials during migration or reset:
# Option 1: Get existing user info
SELECT ID, user_login, user_email FROM wp_users WHERE ID = 1;

# Option 2: Reset password (use strong password)
UPDATE wp_users SET user_pass = MD5('NewSecurePassword123!') WHERE user_login = 'admin';

# Option 3: Create migration user
INSERT INTO wp_users (user_login, user_pass, user_email, user_registered, display_name)
VALUES ('migration_admin', MD5('MigrationTemp2026!'), 'migration@example.com', NOW(), 'Migration Admin');

# Document in migration notes - user should change password after first login
```

### Stage 6: Problematic Plugins Check (Prevents HTTPS Redirect Loops)

**CRITICAL:** Some plugins interfere with CloudFront/ALB SSL termination architecture.

#### AUTOMATED FIX (MANDATORY - Use This)

**Script Location:** `0_utilities/file_transfer/prepare-wordpress-for-migration.sh`

```bash
# MANDATORY: Run this on EVERY database export BEFORE importing to RDS
./prepare-wordpress-for-migration.sh input.sql output-fixed.sql

# Example:
./prepare-wordpress-for-migration.sh \
  wordpress-db-20260123.sql \
  wordpress-db-fixed.sql
```

**What the Script Does Automatically:**
1. Scans SQL for problematic plugins
2. Safely deactivates plugins from serialized `active_plugins` array
3. Clears Really Simple SSL settings
4. Disables Wordfence firewall
5. Disables iThemes Security SSL settings
6. Outputs clean SQL ready for import

**Plugins Automatically Deactivated:**

| Plugin | Issue |
|--------|-------|
| `really-simple-ssl` | **#1 cause of redirect loops** - detects HTTP, forces 301 |
| `wordfence` | Firewall blocks CloudFront IPs, login protection issues |
| `better-wp-security` / `ithemes-security` | SSL redirect rules |
| `wordpress-https` | Conflicts with CloudFront SSL termination |
| `ssl-insecure-content-fixer` | Same redirect issue |
| `ldap-login-for-intranet-sites` | Causes login failures after migration |
| `all-in-one-wp-security` | Firewall and security blocks |

**After Database Import - Deploy MU-Plugin:**

```bash
# MANDATORY: Deploy force-https.php MU-plugin to prevent redirect loops
# This MUST be done for EVERY migration - ALB terminates SSL, WordPress needs to know it's HTTPS

TENANT="tenant_name"
BASTION_ID="i-xxxxxxxxx"  # Get from AWS console or terraform output
AWS_PROFILE="dev"  # or sit, prod

# Step 1: Create mu-plugins directory on EFS (via SSM)
aws ssm send-command \
  --instance-ids "$BASTION_ID" \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=["sudo mkdir -p /mnt/efs/'$TENANT'/mu-plugins"]' \
  --profile $AWS_PROFILE

# Step 2: Create force-https.php directly on EFS (via SSM)
aws ssm send-command \
  --instance-ids "$BASTION_ID" \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=["sudo tee /mnt/efs/'$TENANT'/mu-plugins/force-https.php << '\''EOF'\''
<?php
/**
 * Plugin Name: Force HTTPS
 * Description: Forces HTTPS detection for WordPress behind ALB/CloudFront
 * Version: 1.0
 */

// Unconditionally set HTTPS for requests behind ALB
$_SERVER[\"HTTPS\"] = \"on\";
$_SERVER[\"REQUEST_SCHEME\"] = \"https\";
$_SERVER[\"SERVER_PORT\"] = \"443\";
EOF"]' \
  --profile $AWS_PROFILE

# Step 3: Verify deployment
aws ssm send-command \
  --instance-ids "$BASTION_ID" \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=["ls -la /mnt/efs/'$TENANT'/mu-plugins/"]' \
  --profile $AWS_PROFILE --output text
```

**WARNING:** Do NOT use SSH/SCP - bastion has no SSH keys. Always use SSM.

**The MU-Plugin Does:**
- Forces `$_SERVER['HTTPS'] = 'on'` when `X-Forwarded-Proto: https`
- Disables SSL plugin redirect actions
- Trusts CloudFront/ALB proxy headers
- Runs before all other plugins (MU-plugin priority)

#### Manual Verification (If Needed)

```bash
# Check for problematic plugins in SQL file
grep -c "really-simple-ssl" database.sql
grep -c "wordfence" database.sql
grep -c "better-wp-security\|ithemes-security" database.sql
```

```sql
-- Manual SQL check (run on source database):
SELECT option_value FROM wp_options WHERE option_name = 'active_plugins';

-- Look for these in the serialized array:
-- really-simple-ssl/rlrsssl-really-simple-ssl.php
-- wordfence/wordfence.php
-- better-wp-security/better-wp-security.php
```

**Why These Plugins Cause Issues:**
- CloudFront terminates SSL and sends HTTP to ALB origin
- These plugins detect HTTP and issue their own 301 redirects to HTTPS
- Creates infinite redirect loop: CloudFront → ALB → Plugin redirects → CloudFront follows → repeat

**Architecture (Cannot Change - Must Fix WordPress):**
```
User (HTTPS) → CloudFront → ALB (HTTP) → Container (HTTP)
                                              ↓
                 Plugin detects HTTP, redirects to HTTPS
                                              ↓
                 CloudFront follows redirect → INFINITE LOOP
```

### Stage 7: ALB Target Group Health Check Configuration

**CRITICAL:** Incorrect health check settings cause targets to be marked unhealthy.

```bash
# CORRECT health check configuration for WordPress:
TENANT="tenant_name"
TG_ARN=$(aws elbv2 describe-target-groups \
  --names "dev-${TENANT}-tg" \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text)

# Configure health check with correct settings
aws elbv2 modify-target-group \
  --target-group-arn "$TG_ARN" \
  --health-check-path "/" \
  --health-check-protocol HTTP \
  --health-check-interval-seconds 30 \
  --health-check-timeout-seconds 5 \
  --healthy-threshold-count 2 \
  --unhealthy-threshold-count 3 \
  --matcher HttpCode=200-302

echo "✅ Target group health check configured"

# Verify health check settings
aws elbv2 describe-target-groups \
  --target-group-arns "$TG_ARN" \
  --query 'TargetGroups[0].{Path:HealthCheckPath,Matcher:Matcher.HttpCode}'
```

**Common Health Check Mistakes:**
| Wrong Setting | Problem | Correct Setting |
|---------------|---------|-----------------|
| Path: `/wp-admin/admin-ajax.php` | Returns 400 Bad Request | Path: `/` |
| Matcher: `200` only | WordPress may return 301/302 | Matcher: `200-302` |
| Protocol: `HTTPS` | ALB→Container is HTTP | Protocol: `HTTP` |

### Stage 8: EFS Access Point Path Verification

**CRITICAL:** Wrong access point path causes files to be invisible to WordPress.

```bash
# CORRECT access point path format: /tenant_name/wp-content
# NOT: /tenant_name (missing /wp-content)

TENANT="tenant_name"
EFS_ID="fs-0e1cccd971a35db46"

# Create access point with CORRECT path
aws efs create-access-point \
  --file-system-id "$EFS_ID" \
  --root-directory "Path=/${TENANT}/wp-content,CreationInfo={OwnerUid=33,OwnerGid=33,Permissions=755}" \
  --posix-user "Uid=33,Gid=33" \
  --tags Key=Name,Value="${TENANT}-wp-content" Key=Environment,Value=dev

# VERIFY path before using in task definition
AP_ID=$(aws efs describe-access-points \
  --file-system-id "$EFS_ID" \
  --query "AccessPoints[?Tags[?Key=='Name' && Value=='${TENANT}-wp-content']].AccessPointId" \
  --output text)

aws efs describe-access-points \
  --access-point-id "$AP_ID" \
  --query 'AccessPoints[0].RootDirectory.Path'
# Expected output: "/tenant_name/wp-content"
# If output is "/tenant_name" - ACCESS POINT IS WRONG, recreate it
```

**Path Mapping:**
```
EFS Access Point Path: /tenant_name/wp-content
     ↓ mounted to ↓
Container Path: /var/www/html/wp-content
```

### Stage 9: IAM Permissions for EFS Access

**CRITICAL:** Missing IAM inline policy causes "failed to invoke EFS utils commands" error.

```bash
TENANT="tenant_name"
EFS_AP_ARN="arn:aws:elasticfilesystem:eu-west-1:536580886816:access-point/fsap-XXXXX"

# Add inline policy to ECS task role for tenant-specific EFS access
aws iam put-role-policy \
  --role-name dev-ecs-task-role \
  --policy-name "dev-ecs-efs-access-${TENANT}" \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite",
          "elasticfilesystem:ClientRootAccess"
        ],
        "Resource": "'"${EFS_AP_ARN}"'"
      }
    ]
  }'

echo "✅ IAM inline policy added for EFS access"

# Verify policy was added
aws iam get-role-policy \
  --role-name dev-ecs-task-role \
  --policy-name "dev-ecs-efs-access-${TENANT}"
```

### Stage 10: Secrets Manager Resource-Based Policy

**CRITICAL:** Missing resource-based policy causes "AccessDeniedException" for database credentials.

```bash
TENANT="tenant_name"
SECRET_ID="dev-${TENANT}-db-credentials"

# Add resource-based policy to allow ECS execution role to read secret
aws secretsmanager put-resource-policy \
  --secret-id "$SECRET_ID" \
  --resource-policy '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "AWS": "arn:aws:iam::536580886816:role/dev-ecs-task-execution-role"
        },
        "Action": "secretsmanager:GetSecretValue",
        "Resource": "*"
      }
    ]
  }'

echo "✅ Secrets Manager resource-based policy added"

# Verify policy
aws secretsmanager get-resource-policy --secret-id "$SECRET_ID"
```

### Pre-Flight Checklist Summary

Run through this checklist before each migration:

```markdown
## Pre-Migration Checklist: {TENANT_NAME}

### Infrastructure Access
- [ ] S3 bucket access verified from bastion
- [ ] Session Manager plugin installed (or CloudWatch Logs alternative ready)
- [ ] CloudFront basic auth exclusion added for tenant domain
- [ ] Bastion host started and accessible

### Database Preparation
- [ ] Source database encoding verified (utf8mb4)
- [ ] Encoding fix SQL script ready
- [ ] Complex SQL files uploaded to S3 (not inline via SSM)
- [ ] URL replacement SQL covers ALL tables (including Yoast)
- [ ] **Problematic plugins identified** (Really Simple SSL, etc.)

### Files Preparation
- [ ] EFS access point created for tenant
- [ ] **EFS access point path verified** (must be /tenant/wp-content)
- [ ] Permissions script ready (chown 33:33)
- [ ] File size estimated and EFS capacity verified

### IAM & Secrets (NEW)
- [ ] **IAM inline policy added** for tenant EFS access
- [ ] **Secrets Manager resource-based policy** added for DB credentials
- [ ] ECS task execution role can read secret

### ALB Configuration (NEW)
- [ ] Target group created
- [ ] **Health check path set to /** (not /wp-admin/admin-ajax.php)
- [ ] **Health check matcher set to 200-302**
- [ ] ALB listener rule created with correct priority

### ECS Task Definition (NEW)
- [ ] **WORDPRESS_CONFIG_EXTRA configured** with $_SERVER['HTTPS'] = 'on'
- [ ] WP_HOME and WP_SITEURL set to new domain
- [ ] WP_ENVIRONMENT_TYPE set (development/staging/production)
- [ ] Database credentials referenced from Secrets Manager

### Configuration
- [ ] Third-party integrations documented
- [ ] Domain-specific services identified (reCAPTCHA, analytics)
- [ ] WordPress admin credentials documented or reset plan ready
- [ ] **Problematic plugins scheduled for deactivation**

### Validation Preparation
- [ ] EFS HTTP verification commands ready
- [ ] Elementor template check SQL ready
- [ ] ECS redeployment command ready (for EFS mount issues)
- [ ] **HTTPS redirect loop test ready**
```

---

## ECS Task Definition Configuration (CRITICAL)

### Overview

**CRITICAL:** Incorrect task definition configuration is the #1 cause of HTTPS redirect loops. The `WORDPRESS_CONFIG_EXTRA` environment variable must be configured correctly.

### The HTTPS Redirect Loop Problem

**Architecture:**
```
User Browser (HTTPS) → CloudFront (SSL Termination) → ALB (HTTP) → ECS Container (HTTP)
```

**Problem:**
- CloudFront terminates SSL and sends HTTP to ALB
- WordPress detects HTTP from ALB and issues 301 redirect to HTTPS
- CloudFront follows redirect, sends HTTP again → infinite loop

**Solution:**
- Set `$_SERVER['HTTPS'] = 'on'` unconditionally in WORDPRESS_CONFIG_EXTRA
- This tells WordPress "treat all requests as HTTPS" regardless of actual protocol from ALB

### Task Definition Template

```json
{
  "family": "dev-{TENANT}",
  "taskRoleArn": "arn:aws:iam::536580886816:role/dev-ecs-task-role",
  "executionRoleArn": "arn:aws:iam::536580886816:role/dev-ecs-task-execution-role",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "containerDefinitions": [
    {
      "name": "wordpress",
      "image": "wordpress:latest",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 80,
          "hostPort": 80,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "WORDPRESS_DEBUG",
          "value": "0"
        },
        {
          "name": "WORDPRESS_DB_HOST",
          "value": "dev-mysql.c9ko42mci6mt.eu-west-1.rds.amazonaws.com:3306"
        },
        {
          "name": "WORDPRESS_DB_NAME",
          "value": "tenant_{TENANT}_db"
        },
        {
          "name": "WORDPRESS_CONFIG_EXTRA",
          "value": "$_SERVER['HTTPS'] = 'on';\ndefine('FORCE_SSL_ADMIN', false);\ndefine('WP_HOME', 'https://{TENANT}.wpdev.kimmyai.io');\ndefine('WP_SITEURL', 'https://{TENANT}.wpdev.kimmyai.io');\ndefine('WP_ENVIRONMENT_TYPE', 'development');"
        },
        {
          "name": "WORDPRESS_TABLE_PREFIX",
          "value": "wp_"
        }
      ],
      "secrets": [
        {
          "name": "WORDPRESS_DB_USER",
          "valueFrom": "arn:aws:secretsmanager:eu-west-1:536580886816:secret:dev-{TENANT}-db-credentials:username::"
        },
        {
          "name": "WORDPRESS_DB_PASSWORD",
          "valueFrom": "arn:aws:secretsmanager:eu-west-1:536580886816:secret:dev-{TENANT}-db-credentials:password::"
        }
      ],
      "mountPoints": [
        {
          "sourceVolume": "wp-content",
          "containerPath": "/var/www/html/wp-content",
          "readOnly": false
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/dev",
          "awslogs-region": "eu-west-1",
          "awslogs-stream-prefix": "{TENANT}"
        }
      }
    }
  ],
  "volumes": [
    {
      "name": "wp-content",
      "efsVolumeConfiguration": {
        "fileSystemId": "fs-0e1cccd971a35db46",
        "rootDirectory": "/",
        "transitEncryption": "ENABLED",
        "authorizationConfig": {
          "accessPointId": "fsap-XXXXXXXXXXXXX",
          "iam": "ENABLED"
        }
      }
    }
  ]
}
```

### WORDPRESS_CONFIG_EXTRA Explained

```php
// CRITICAL: Force WordPress to recognize HTTPS
// Without this: CloudFront → ALB → WordPress (detects HTTP) → redirects to HTTPS → loop
$_SERVER['HTTPS'] = 'on';

// Disable forced SSL for admin (CloudFront handles SSL)
define('FORCE_SSL_ADMIN', false);

// Set site URLs to HTTPS (prevents mixed content)
define('WP_HOME', 'https://tenant.wpdev.kimmyai.io');
define('WP_SITEURL', 'https://tenant.wpdev.kimmyai.io');

// Environment type for conditional behavior
define('WP_ENVIRONMENT_TYPE', 'development');
// Options: 'local', 'development', 'staging', 'production'
```

### Environment-Specific Values

| Environment | WP_ENVIRONMENT_TYPE | FORCE_SSL_ADMIN | Domain Pattern |
|-------------|---------------------|-----------------|----------------|
| DEV | development | false | tenant.wpdev.kimmyai.io |
| SIT | staging | false | tenant.wpsit.kimmyai.io |
| PROD | production | true | customdomain.com |

### Register Task Definition

```bash
TENANT="tenant_name"

# Replace placeholders in template
sed -e "s/{TENANT}/${TENANT}/g" \
    -e "s/fsap-XXXXXXXXXXXXX/fsap-actualid/g" \
    task-definition-template.json > "/tmp/dev-${TENANT}-task.json"

# Register task definition
aws ecs register-task-definition \
  --cli-input-json "file:///tmp/dev-${TENANT}-task.json"

echo "✅ Task definition registered"

# Update service to use new task definition
aws ecs update-service \
  --cluster dev-cluster \
  --service "dev-${TENANT}-service" \
  --task-definition "dev-${TENANT}"

echo "✅ Service updated with new task definition"
```

### Verification

```bash
# Test for HTTPS redirect loop (should return 200, not 301)
curl -s -o /dev/null -w "%{http_code}" -L "https://${TENANT}.wpdev.kimmyai.io/"
# Expected: 200

# Test without following redirects (check for redirect loop)
curl -s -o /dev/null -w "%{http_code}" "https://${TENANT}.wpdev.kimmyai.io/"
# Expected: 200
# If 301: HTTPS redirect loop exists - check WORDPRESS_CONFIG_EXTRA

# Check response headers for redirect
curl -sI "https://${TENANT}.wpdev.kimmyai.io/" | grep -i location
# Expected: No Location header (no redirect)
# If Location header present: redirect loop exists
```

---

## Bastion Host for Migration Operations

### Overview

**NEW APPROACH:** Use dedicated EC2 bastion host instead of ECS exec for all migration operations.

**Why the change?**
- ✅ **100% Reliability** - No session timeouts or EOF errors
- ✅ **Better Performance** - Native EC2 performance vs containerized
- ✅ **Easier Debugging** - Full system access and logs
- ✅ **Cost-Effective** - Auto-stops after 30 minutes idle (~$1.70/month)
- ✅ **Better Audit Trail** - CloudWatch logs all operations

### ECS Exec Issues (Lessons from Au Pair Hive Migration)

**Problems encountered:**
1. Session timeouts after 20-30 minutes (despite SSM timeout increases)
2. "Cannot perform start session: EOF" errors requiring constant reconnection
3. Heredoc syntax failures for multi-line SQL scripts
4. 8-10 hour migration time due to reliability issues

**Solution:** Dedicated bastion host with pre-installed tools and auto-shutdown

### Bastion Quick Start

**Helper Scripts Location:**
```
/2_bbws_agents/tenant/scripts/bastion/
├── start-bastion.sh     # Start bastion instance
├── stop-bastion.sh      # Stop bastion (manual)
└── connect-bastion.sh   # Connect via SSM
```

**Basic Usage:**
```bash
# Navigate to scripts directory
cd /Users/tebogotseka/Documents/agentic_work/2_bbws_agents/tenant/scripts/bastion/

# Start bastion for your environment
./start-bastion.sh dev   # or sit, prod

# Connect via SSM Session Manager
./connect-bastion.sh dev

# Stop when done to save costs
exit
./stop-bastion.sh dev
```

### Pre-installed Migration Tools

Once connected to bastion, you have access to:

| Tool | Version | Purpose |
|------|---------|---------|
| WP-CLI | Latest | WordPress operations (search-replace, plugin management) |
| MySQL Client | 8.0+ | Direct RDS database access |
| AWS CLI | v2 | S3, Secrets Manager, EFS operations |
| PHP CLI | 8.2 | Run PHP scripts |
| EFS Utils | Latest | Mount WordPress wp-content directories |
| CloudWatch Agent | Latest | Metrics and logging |

### Helper Scripts on Bastion

**Mount EFS:**
```bash
/usr/local/bin/migration-helpers/mount-efs.sh
# Output: ✅ EFS mounted successfully at /mnt/efs
```

**Connect to RDS:**
```bash
/usr/local/bin/migration-helpers/connect-rds.sh
# Automatically retrieves credentials from Secrets Manager
# Connects to MySQL shell
```

### Common Migration Operations via Bastion

**1. Database Operations:**
```bash
# Connect to bastion
./connect-bastion.sh dev

# Connect to RDS
/usr/local/bin/migration-helpers/connect-rds.sh

# Run SQL commands
CREATE DATABASE tenant_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE tenant_db;
SOURCE /tmp/migration/database.sql;
```

**2. File Operations:**
```bash
# Mount EFS
/usr/local/bin/migration-helpers/mount-efs.sh

# Download files from S3
aws s3 sync s3://bbws-migration-artifacts-dev/tenant/ /tmp/migration/

# Copy to EFS
sudo rsync -avz /tmp/migration/wp-content/ /mnt/efs/tenant/
sudo chown -R 33:33 /mnt/efs/tenant/  # www-data ownership
```

**3. WP-CLI Operations:**
```bash
# Mount EFS first
/usr/local/bin/migration-helpers/mount-efs.sh

# Navigate to tenant
cd /mnt/efs/tenant/

# Run WP-CLI commands
wp search-replace 'oldsite.com' 'newsite.com' --dry-run
wp search-replace 'oldsite.com' 'newsite.com'
wp plugin list
wp cache flush
```

### Auto-Shutdown Feature

**Behavior:**
- Bastion automatically stops after **30 minutes of idle time**
- Monitors: CPU usage, network I/O, SSM sessions
- SNS notification sent on auto-shutdown

**Manual Control:**
```bash
# Stop immediately after migration
./stop-bastion.sh dev

# Check status
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=dev-wordpress-migration-bastion" \
  --query 'Reservations[0].Instances[0].State.Name'
```

### Cost Comparison

| Scenario | Monthly Cost | Notes |
|----------|--------------|-------|
| Always-on bastion | $15.30 | t3a.medium 24/7 + storage (recommended) |
| With auto-shutdown | $1.80 | 8 hours/month usage + storage |
| Savings | **88%** | Auto-stops when idle |

**Note:** t3a.medium (4GB) recommended over t3a.micro (1GB) to prevent OOM/disconnects during large transfers.

### Bastion vs ECS Exec

| Feature | Bastion | ECS Exec |
|---------|---------|----------|
| Reliability | 100% | ~60% (timeout issues) |
| Session Duration | Unlimited | 20-30 min before timeout |
| Performance | Native EC2 | Containerized |
| Tool Pre-installation | Yes (all tools ready) | No (install each time) |
| Heredoc Support | Full support | Syntax errors |
| Cost (8 hrs/month) | $1.70 | $0 (but requires ECS running) |
| Audit Trail | CloudWatch logs | SSM logs |
| Debugging | Full system access | Limited |

### When to Use Bastion

✅ **Use bastion for:**
- Database imports and exports
- Large file transfers to/from EFS
- WP-CLI batch operations
- Multi-step migration workflows
- Debugging and troubleshooting
- Long-running operations (> 30 minutes)

⚠️ **Use ECS exec only for:**
- Quick checks (< 5 minutes)
- Emergency access when bastion unavailable
- Container-specific debugging

### Detailed Documentation

For comprehensive bastion usage, see:
- **[Bastion Operations Guide](bastion_operations_guide.md)** - Complete operational manual
- **[Bastion Terraform Module](../../2_bbws_ecs_terraform/terraform/modules/bastion/README.md)** - Infrastructure details
- **[Lambda Auto-Shutdown](../../2_bbws_bastion_auto_shutdown/README.md)** - Auto-shutdown mechanism

---

## SSL/TLS Certificate Management

### Overview

**CRITICAL:** Sites will not work without valid SSL certificates. This section covers certificate provisioning for all environments.

### Certificate Strategy

| Environment | Domain Pattern | Certificate Type | Provider |
|-------------|----------------|------------------|----------|
| DEV | `*.wpdev.kimmyai.io` | Wildcard | AWS ACM |
| SIT | `*.wpsit.kimmyai.io` | Wildcard | AWS ACM |
| PROD | `customdomain.com` | Single/Wildcard | AWS ACM |

### Certificate Request for New Custom Domain

**Script:** `/2_bbws_agents/tenant/scripts/request-ssl-certificate.sh`

```bash
#!/bin/bash
# Request SSL certificate for custom domain

DOMAIN="$1"
ENVIRONMENT="${2:-prod}"
EMAIL="${3:-admin@bigbeard.co.za}"

case $ENVIRONMENT in
    dev)
        AWS_PROFILE="Tebogo-dev"
        REGION="eu-west-1"
        ;;
    sit)
        AWS_PROFILE="Tebogo-sit"
        REGION="eu-west-1"
        ;;
    prod)
        AWS_PROFILE="Tebogo-prod"
        REGION="af-south-1"
        ;;
esac

echo "=========================================================================="
echo "Requesting SSL Certificate for: ${DOMAIN}"
echo "Environment: ${ENVIRONMENT}"
echo "=========================================================================="

# Request certificate with DNS validation
CERT_ARN=$(aws acm request-certificate \
    --domain-name "${DOMAIN}" \
    --subject-alternative-names "www.${DOMAIN}" \
    --validation-method DNS \
    --tags Key=Environment,Value=${ENVIRONMENT} Key=ManagedBy,Value=DevOps \
    --profile "${AWS_PROFILE}" \
    --region "${REGION}" \
    --query 'CertificateArn' \
    --output text)

echo "✅ Certificate requested: ${CERT_ARN}"
echo ""

# Wait for validation records
echo "⏳ Waiting for DNS validation records..."
sleep 10

# Get validation CNAME records
aws acm describe-certificate \
    --certificate-arn "${CERT_ARN}" \
    --profile "${AWS_PROFILE}" \
    --region "${REGION}" \
    --query 'Certificate.DomainValidationOptions[*].[DomainName,ResourceRecord.Name,ResourceRecord.Value]' \
    --output table

echo ""
echo "=========================================================================="
echo "⚠️  ACTION REQUIRED: Add DNS Validation Records"
echo "=========================================================================="
echo ""
echo "Add the CNAME records shown above to your DNS provider."
echo ""
echo "After adding records, monitor certificate status with:"
echo "  aws acm describe-certificate \\"
echo "    --certificate-arn ${CERT_ARN} \\"
echo "    --profile ${AWS_PROFILE} \\"
echo "    --region ${REGION} \\"
echo "    --query 'Certificate.Status'"
echo ""
echo "Status should change to: ISSUED (usually within 5-30 minutes)"
echo ""
```

### Certificate Validation Automation

**For Route 53 Managed Domains:**

```bash
#!/bin/bash
# Auto-validate certificate using Route 53

CERT_ARN="$1"
HOSTED_ZONE_ID="$2"
AWS_PROFILE="${3:-Tebogo-prod}"
REGION="${4:-af-south-1}"

# Get validation record
VALIDATION_RECORD=$(aws acm describe-certificate \
    --certificate-arn "${CERT_ARN}" \
    --profile "${AWS_PROFILE}" \
    --region "${REGION}" \
    --query 'Certificate.DomainValidationOptions[0].ResourceRecord' \
    --output json)

CNAME_NAME=$(echo "$VALIDATION_RECORD" | jq -r '.Name')
CNAME_VALUE=$(echo "$VALIDATION_RECORD" | jq -r '.Value')

# Create Route 53 change batch
cat > /tmp/cert-validation-batch.json << EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "${CNAME_NAME}",
      "Type": "CNAME",
      "TTL": 300,
      "ResourceRecords": [{"Value": "${CNAME_VALUE}"}]
    }
  }]
}
EOF

# Apply DNS change
aws route53 change-resource-record-sets \
    --hosted-zone-id "${HOSTED_ZONE_ID}" \
    --change-batch file:///tmp/cert-validation-batch.json \
    --profile "${AWS_PROFILE}"

echo "✅ DNS validation record added to Route 53"
echo "⏳ Waiting for certificate validation (5-30 minutes)..."

# Wait for certificate to be issued
aws acm wait certificate-validated \
    --certificate-arn "${CERT_ARN}" \
    --profile "${AWS_PROFILE}" \
    --region "${REGION}"

echo "✅ Certificate validated and issued!"
```

### Certificate Verification Checklist

Before migration, verify:

- [ ] Certificate status is `ISSUED`
- [ ] Certificate includes both apex and www subdomain
- [ ] Certificate is in correct region (CloudFront requires us-east-1)
- [ ] Certificate ARN is documented in tenant record
- [ ] Certificate renewal is automatic (ACM auto-renews)

### CloudFront Certificate Requirements

**IMPORTANT:** CloudFront distributions require certificates in **us-east-1** region.

```bash
# Request certificate in us-east-1 for CloudFront
aws acm request-certificate \
    --domain-name "customdomain.com" \
    --subject-alternative-names "www.customdomain.com" \
    --validation-method DNS \
    --region us-east-1 \
    --profile "${AWS_PROFILE}"
```

### Certificate Monitoring

Monitor certificate expiration (ACM auto-renews 60 days before expiry):

```bash
# Check certificate expiration
aws acm describe-certificate \
    --certificate-arn "${CERT_ARN}" \
    --profile "${AWS_PROFILE}" \
    --region "${REGION}" \
    --query 'Certificate.[DomainName,Status,NotAfter,RenewalEligibility]' \
    --output table
```

### Troubleshooting Certificate Issues

**Issue: Certificate stuck in "Pending Validation"**
- Verify DNS records are correct
- Check DNS propagation: `dig _validation.domain.com CNAME`
- Wait up to 72 hours for DNS propagation

**Issue: Certificate validation failed**
- DNS records must match exactly (including trailing dot)
- Remove old validation records first
- Retry with new certificate request

---

## Security Hardening

### Overview

Defense-in-depth security measures for WordPress on AWS infrastructure.

### IAM Least Privilege

**ECS Task Role Permissions (Minimum Required):**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::bbws-migration-artifacts-${environment}",
        "arn:aws:s3:::bbws-migration-artifacts-${environment}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": "arn:aws:secretsmanager:*:*:secret:rds/wordpress/${tenant}/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:log-group:/ecs/wordpress/*"
    }
  ]
}
```

### RDS Security

**1. Database Encryption:**
- ✅ Encryption at rest (enabled by default)
- ✅ Encryption in transit (force SSL connections)

**2. Network Isolation:**
```bash
# Verify RDS security group allows only ECS tasks
aws ec2 describe-security-groups \
    --group-ids "${RDS_SG_ID}" \
    --profile "${AWS_PROFILE}" \
    --query 'SecurityGroups[0].IpPermissions'
```

**Expected:** Only port 3306 from ECS security group, NO 0.0.0.0/0

**3. Credential Rotation:**
```bash
# Enable automatic credential rotation (30 days)
aws secretsmanager rotate-secret \
    --secret-id "rds/wordpress/${TENANT}/credentials" \
    --rotation-rules AutomaticallyAfterDays=30 \
    --profile "${AWS_PROFILE}"
```

### EFS Security

**1. Access Points (Tenant Isolation):**
```bash
# Verify each tenant has isolated access point
aws efs describe-access-points \
    --file-system-id "${EFS_ID}" \
    --profile "${AWS_PROFILE}" \
    --query 'AccessPoints[*].[AccessPointId,RootDirectory.Path,PosixUser]' \
    --output table
```

**2. Encryption:**
- ✅ Encryption at rest (enabled at EFS creation)
- ✅ Encryption in transit (mount with TLS)

**3. Mount Target Security:**
```bash
# Verify EFS security group allows only ECS tasks
aws ec2 describe-security-groups \
    --group-ids "${EFS_SG_ID}" \
    --profile "${AWS_PROFILE}" \
    --query 'SecurityGroups[0].IpPermissions'
```

### WordPress Hardening

**1. Disable File Editing in wp-admin:**

Add to `wp-config.php`:
```php
// Disable file editor
define('DISALLOW_FILE_EDIT', true);
define('DISALLOW_FILE_MODS', true); // Disable plugin/theme installation via admin
```

**2. Limit Login Attempts:**

Install MU-plugin: `limit-login-attempts.php`
```php
<?php
/**
 * Plugin Name: BBWS Platform - Limit Login Attempts
 * Description: Rate-limit wp-login.php requests
 */

add_filter('authenticate', function($user, $username, $password) {
    if (empty($username) || empty($password)) {
        return $user;
    }

    $transient_key = 'login_attempts_' . md5($username . $_SERVER['REMOTE_ADDR']);
    $attempts = get_transient($transient_key);

    if ($attempts >= 5) {
        return new WP_Error('too_many_attempts', 'Too many login attempts. Please try again in 15 minutes.');
    }

    if (is_wp_error($user)) {
        set_transient($transient_key, ($attempts ? $attempts + 1 : 1), 15 * MINUTE_IN_SECONDS);
    }

    return $user;
}, 30, 3);
```

**3. Security Headers via CloudFront:**

Add custom headers to CloudFront distribution:
```json
{
  "X-Content-Type-Options": "nosniff",
  "X-Frame-Options": "SAMEORIGIN",
  "X-XSS-Protection": "1; mode=block",
  "Strict-Transport-Security": "max-age=31536000; includeSubDomains",
  "Referrer-Policy": "strict-origin-when-cross-origin"
}
```

**4. WAF Rules:**

Create WAF Web ACL with:
- SQL injection protection
- XSS protection
- Rate-based rule (2000 requests per 5 minutes per IP)
- Geographic restrictions (if applicable)

```bash
# Associate WAF with CloudFront distribution
aws wafv2 associate-web-acl \
    --web-acl-arn "${WAF_ACL_ARN}" \
    --resource-arn "${CLOUDFRONT_ARN}" \
    --scope CLOUDFRONT \
    --profile "${AWS_PROFILE}" \
    --region us-east-1
```

### Security Monitoring

**CloudWatch Alarms:**

```bash
# Monitor failed login attempts
aws cloudwatch put-metric-alarm \
    --alarm-name "${TENANT}-failed-logins" \
    --alarm-description "Alert on excessive failed login attempts" \
    --metric-name FailedLoginAttempts \
    --namespace WordPress \
    --statistic Sum \
    --period 300 \
    --threshold 20 \
    --comparison-operator GreaterThanThreshold \
    --evaluation-periods 1 \
    --profile "${AWS_PROFILE}"
```

**GuardDuty:**
- Enable GuardDuty for threat detection
- Monitor for compromised credentials
- Alert on unusual API activity

---

## Migration Process Overview

```
┌──────────────────────────────────────────────────────────────┐
│                  PHASE 1: PRE-MIGRATION                      │
├──────────────────────────────────────────────────────────────┤
│  1. Analyze source WordPress site                            │
│  2. Identify integration points (email, tracking, APIs)      │
│  3. Check database charset (utf8mb4)                         │
│  4. Verify PHP compatibility (7.x → 8.x)                     │
│  5. Generate migration plan                                  │
└──────────────────────────────────────────────────────────────┘
                              ↓
┌──────────────────────────────────────────────────────────────┐
│                  PHASE 2: MIGRATION EXECUTION                │
├──────────────────────────────────────────────────────────────┤
│  1. Export database (mysqldump --default-character-set=utf8mb4) │
│  2. Export files (tar czf wp-content)                        │
│  3. Import database to RDS                                   │
│  4. Upload files to EFS                                      │
│  5. Deploy MU-plugins (HTTPS, email redirect, indicators)   │
│  6. Configure wp-config.php (WP_ENV, TEST_EMAIL_REDIRECT)   │
│  7. Update URLs (search-replace)                             │
│  8. Apply encoding fixes                                     │
│  9. Clear caches (WordPress, Divi, CloudFront)              │
└──────────────────────────────────────────────────────────────┘
                              ↓
┌──────────────────────────────────────────────────────────────┐
│                  PHASE 3: VALIDATION                         │
├──────────────────────────────────────────────────────────────┤
│  1. HTTP 200 status check                                    │
│  2. Mixed content detection (0 HTTP URLs)                    │
│  3. UTF-8 encoding validation                                │
│  4. PHP error detection                                      │
│  5. Performance testing (< 3s load time)                     │
│  6. CloudFront cache validation                              │
│  7. Environment indicator check                              │
│  8. WordPress health check                                   │
└──────────────────────────────────────────────────────────────┘
                              ↓
┌──────────────────────────────────────────────────────────────┐
│                  PHASE 4: TESTING                            │
├──────────────────────────────────────────────────────────────┤
│  1. Test form submissions (emails → tebogo@bigbeard.co.za)  │
│  2. Verify tracking scripts mocked                           │
│  3. Check reCAPTCHA functionality                            │
│  4. Test all major pages                                     │
│  5. Verify plugins functional                                │
│  6. Browser compatibility testing                            │
│  7. Mobile responsiveness testing                            │
└──────────────────────────────────────────────────────────────┘
                              ↓
┌──────────────────────────────────────────────────────────────┐
│                  PHASE 5: SIT PROMOTION                      │
├──────────────────────────────────────────────────────────────┤
│  1. Review DEV test results                                  │
│  2. Run automated migration to SIT                           │
│  3. User Acceptance Testing (UAT)                            │
│  4. Stakeholder sign-off                                     │
└──────────────────────────────────────────────────────────────┘
                              ↓
┌──────────────────────────────────────────────────────────────┐
│                  PHASE 6: PRODUCTION CUTOVER                 │
├──────────────────────────────────────────────────────────────┤
│  1. Remove test email redirect                               │
│  2. Restore real tracking scripts                            │
│  3. Update DNS                                               │
│  4. Monitor for 24 hours                                     │
└──────────────────────────────────────────────────────────────┘
```

---

## Phase 1: Pre-Migration Analysis

### Objective
Understand the source WordPress site configuration to anticipate and prevent issues.

### Script
```bash
./scripts/analyze-source-site.sh <source-host> <tenant-name>
```

### Manual Checks (if script unavailable)

**1. Check WordPress Version**
```bash
ssh user@source-host "cd /var/www/html && wp core version --allow-root"
```

**2. Check PHP Version**
```bash
ssh user@source-host "php -v | head -n 1"
```

**3. Check Active Theme**
```bash
ssh user@source-host "cd /var/www/html && wp theme list --status=active --allow-root"
```

**4. Check Active Plugins**
```bash
ssh user@source-host "cd /var/www/html && wp plugin list --status=active --allow-root"
```

**5. Check Database Charset**
```bash
ssh user@source-host "mysql -e \"SHOW VARIABLES LIKE 'character_set_database';\""
```

**Expected Result:** `utf8mb4`
**If NOT utf8mb4:** Migration will require encoding fix

**6. Check Site URLs**
```bash
ssh user@source-host "cd /var/www/html && wp option get siteurl --allow-root"
ssh user@source-host "cd /var/www/html && wp option get home --allow-root"
```

**7. Identify Integration Points**

Create checklist:
- [ ] Email notifications (forms, WordPress core)
- [ ] Google Analytics / GA4
- [ ] Facebook Pixel
- [ ] reCAPTCHA
- [ ] Payment gateways (Stripe, PayPal)
- [ ] CRM integrations (HubSpot, Salesforce)
- [ ] Marketing tools (Mailchimp, etc.)
- [ ] Custom APIs

### Analysis Report Template

```markdown
# Pre-Migration Analysis: {TENANT_NAME}

**Date:** {DATE}

## Source Site Configuration
- WordPress Version: {VERSION}
- PHP Version: {VERSION}
- Active Theme: {THEME_NAME}
- Active Plugins: {COUNT} plugins
- Database Charset: {CHARSET}
- Site URL: {URL}
- Home URL: {URL}

## Integration Points Identified
- Email Notifications: {YES/NO}
- Google Analytics: {YES/NO}
- Facebook Pixel: {YES/NO}
- reCAPTCHA: {YES/NO}
- Payment Gateway: {YES/NO}
- CRM Integration: {YES/NO}

## Potential Issues
- [ ] PHP version upgrade (7.x → 8.x): Test theme/plugin compatibility
- [ ] Database charset not utf8mb4: Encoding fix required
- [ ] SSL not enabled on source: May have HTTP URLs in database
- [ ] Custom .htaccess rules: Need Nginx conversion

## Estimated Migration Time
- Database Size: {SIZE}
- Files Size: {SIZE}
- Estimated Time: {MINUTES} minutes

## Next Steps
1. Obtain database credentials
2. Schedule migration window
3. Run automated migration script
```

---

## Phase 2: Automated Migration Execution

### Primary Method: Automated Script

**Script:** `/2_bbws_agents/tenant/scripts/migrate-wordpress-tenant.sh`

**Usage:**
```bash
./migrate-wordpress-tenant.sh {TENANT_NAME} \
  --source-host {SOURCE_HOST} \
  --source-db-host {DB_HOST} \
  --source-db-name {DB_NAME} \
  --source-db-user {DB_USER} \
  --source-db-pass '{DB_PASS}' \
  --source-wp-path /var/www/html \
  --environment dev \
  --test-email tebogo@bigbeard.co.za
```

**Example:**
```bash
./migrate-wordpress-tenant.sh aupairhive \
  --source-host aupairhive.com \
  --source-db-host localhost \
  --source-db-name wordpress_prod \
  --source-db-user dbuser \
  --source-db-pass 'SecurePass123!' \
  --source-wp-path /var/www/html \
  --environment dev
```

**What the Script Does Automatically:**

1. **Pre-Migration Validation**
   - Verifies AWS credentials
   - Checks required tools (wp, mysql, jq, etc.)
   - Analyzes source site configuration

2. **Database Migration**
   - Exports with `mysqldump --default-character-set=utf8mb4`
   - Verifies export file encoding
   - Imports to target RDS with proper charset
   - Applies UTF-8 encoding fixes

3. **Files Migration**
   - Exports wp-content directory
   - Uploads to EFS via ECS task
   - Sets correct permissions (www-data:www-data)

4. **Configuration**
   - Deploys MU-plugins:
     - `force-https.php` - HTTPS URL forcing
     - `test-email-redirect.php` - Email interception
     - `environment-indicator.php` - Visual environment badge
   - Configures wp-config.php:
     - `WP_ENV='dev'`
     - `TEST_EMAIL_REDIRECT='tebogo@bigbeard.co.za'`
     - HTTPS forcing
     - Error suppression
   - Updates URLs in database (search-replace)
   - Activates correct theme

5. **Post-Migration Tasks**
   - Clears WordPress cache
   - Clears Divi theme cache
   - Invalidates CloudFront distribution

6. **Validation**
   - Runs 10-point validation suite
   - Generates migration report

**Expected Output:**
```
======================================================================
Phase 1: Pre-Migration Validation
======================================================================
✅ Prerequisites validated
✅ Source site analysis complete

======================================================================
Phase 2: Database Migration
======================================================================
✅ Database exported: 45MB
✅ Database imported successfully
✅ Encoding fixes applied

======================================================================
Phase 3: Files Migration
======================================================================
✅ Files exported: 1.2GB
✅ Files uploaded to EFS

======================================================================
Phase 4: Configuration
======================================================================
✅ MU-plugins deployed
✅ wp-config.php configured
✅ URLs updated (1,904 replacements)
✅ Theme activated: Divi_Child

======================================================================
Phase 5: Post-Migration Tasks
======================================================================
✅ Caches cleared
✅ CloudFront invalidation: I123456789ABCD

======================================================================
Phase 6: Validation
======================================================================
✅ HTTP 200 OK
✅ No mixed content
✅ No encoding issues
✅ No PHP errors
✅ Load time: 0.63s
✅ CloudFront cache HIT
✅ Environment indicator present
✅ WordPress health OK

======================================================================
✅ Migration complete!
======================================================================

Site URL: https://{tenant}.wpdev.kimmyai.io
Test Email: tebogo@bigbeard.co.za

Next steps:
  1. Test form submissions
  2. Verify all pages render correctly
  3. Check plugin functionality
```

---

## Phase 3: Post-Migration Validation

### Automated Validation Script

**Script:** `/2_bbws_agents/tenant/scripts/validate-migration.sh`

**Usage:**
```bash
./validate-migration.sh https://{tenant}.wpdev.kimmyai.io
```

**Example:**
```bash
./validate-migration.sh https://aupairhive.wpdev.kimmyai.io
```

**Validation Tests:**

| Test # | Test Name | Pass Criteria |
|--------|-----------|---------------|
| 1 | HTTP Status Code | 200 OK |
| 2 | Mixed Content Detection | 0 HTTP URLs |
| 3 | UTF-8 Encoding | No artifacts (Â, â€™, etc.) |
| 4 | PHP Errors | No visible errors/warnings |
| 5 | SSL Certificate | Valid HTTPS certificate |
| 6 | Performance | Load time < 3 seconds |
| 7 | CloudFront Cache | X-Cache header present |
| 8 | Environment Indicator | Visible on page (dev/sit) |
| 9 | WordPress Health | wp-admin and wp-json accessible |
| 10 | Integration Points | Tracking scripts mocked (dev/sit) |

**Expected Output:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Test 1: HTTP Status Code
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ PASS: Site returns HTTP 200 OK

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Test 2: Mixed Content Detection
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ PASS: No HTTP URLs found for domain (all HTTPS)

...

======================================================================
Validation Summary
======================================================================

Site: https://aupairhive.wpdev.kimmyai.io
Tenant: aupairhive
Timestamp: 2026-01-11 08:00:00 UTC

Passed: 10
Failed: 0
Warnings: 0

✅ All critical tests passed!
======================================================================
```

---

## Phase 4: Testing with Mocked Services

### Objective
Test all functionality WITHOUT affecting real business operations.

### Test Email Configuration

**Status:** ✅ Automatic via MU-plugin

All emails in DEV/SIT are automatically redirected to: **tebogo@bigbeard.co.za**

**Email Subject Prefix:** `[TEST - DEV]` or `[TEST - SIT]`

**Email Body Prefix:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TEST EMAIL REDIRECT - DEV ENVIRONMENT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Original Recipient(s): owner@business.com
Redirected To: tebogo@bigbeard.co.za
Environment: DEV

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ORIGINAL MESSAGE BELOW:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Original email content...]
```

### Tracking Scripts Mocking

**Status:** ✅ Automatic via MU-plugin

- **Google Analytics:** Replaced with `console.log()` (no data sent)
- **Facebook Pixel:** Replaced with `console.log()` (no events sent)
- **Google Tag Manager:** Disabled in DEV/SIT

**Console Output:**
```javascript
🚧 DEV ENVIRONMENT - TRACKING MOCKED 🚧
All analytics and tracking scripts are mocked. No data is sent to production services.
Mocked services: Google Analytics, Facebook Pixel, Google Tag Manager
```

### Testing Checklist

#### 1. Forms Testing

**For each form:**
- [ ] Submit form with test data
- [ ] Verify email received at tebogo@bigbeard.co.za
- [ ] Check email subject has `[TEST - DEV]` prefix
- [ ] Verify original recipient shown in email body
- [ ] Confirm reCAPTCHA works (if applicable)
- [ ] Check form entry saved in database (wp_gf_entry)

**Forms to Test:**
- [ ] Contact Us form
- [ ] Application forms
- [ ] Newsletter signup
- [ ] Other forms

#### 2. Content Verification

- [ ] Homepage renders correctly
- [ ] All menu items load
- [ ] Blog posts display properly
- [ ] Media library images load
- [ ] Hero slider works (if applicable)
- [ ] No encoding artifacts (Â, â€™, etc.)

#### 3. Plugin Functionality

- [ ] Gravity Forms working
- [ ] Cookie banner displays
- [ ] All active plugins functional
- [ ] No JavaScript errors in console

#### 4. Performance Testing

- [ ] Homepage loads < 3 seconds
- [ ] CloudFront cache hitting (check X-Cache header)
- [ ] Images optimized
- [ ] CSS/JS minified

#### 5. Browser Compatibility

- [ ] Chrome (latest)
- [ ] Firefox (latest)
- [ ] Safari (latest)
- [ ] Edge (latest)

#### 6. Mobile Responsiveness

- [ ] iOS Safari
- [ ] Android Chrome
- [ ] Responsive design working
- [ ] Touch interactions working

#### 7. WordPress Admin

- [ ] Login to wp-admin
- [ ] Check dashboard
- [ ] Verify plugins active
- [ ] Test theme customizer
- [ ] Check users migrated

### Environment Indicator Verification

**Visual Confirmation:**

1. **Frontend Banner (Bottom of Page):**
   ```
   🚧 DEV ENVIRONMENT 🚧
   Testing Mode Active • Emails → tebogo@bigbeard.co.za • Analytics Mocked
   ```

2. **Admin Bar Badge:**
   - Red badge in WordPress admin bar: **"🚧 DEV ENVIRONMENT"**

3. **Admin Notice:**
   - Warning in wp-admin: **"⚠️ Email Redirect Active"**

4. **Console Message:**
   - Browser console shows: **"🚧 DEV ENVIRONMENT - TRACKING MOCKED 🚧"**

---

## WordPress Cron Configuration

### Overview

WordPress cron is critical for scheduled tasks (backups, updates, scheduled posts, etc.). By default, WordPress cron relies on site traffic, which is unreliable in containerized environments.

### Problem with Default WP-Cron

**Default behavior:**
- WordPress runs `wp-cron.php` on every page load
- Triggers scheduled tasks if due
- **Issues in our architecture:**
  - CloudFront caching reduces page loads
  - No guarantees cron will run on schedule
  - Wastes resources checking on every request

### Solution: ECS Scheduled Tasks with EventBridge

**Architecture:**
```
EventBridge Rule (every 15 min)
  ↓
ECS Task (wp-cli cron event run)
  ↓
WordPress database (processes scheduled tasks)
```

### Step 1: Disable Default WP-Cron

Add to `wp-config.php`:
```php
// Disable default WP-Cron (will use ECS scheduled tasks instead)
define('DISABLE_WP_CRON', true);
```

### Step 2: Create ECS Cron Task Definition

**File:** `/2_bbws_terraform/modules/ecs-cron/task-definition.tf`

```hcl
resource "aws_ecs_task_definition" "wordpress_cron" {
  family                   = "${var.tenant_name}-cron"
  requires_compatibilities = ["FARGATE"]
  network_mode            = "awsvpc"
  cpu                     = 256
  memory                  = 512
  execution_role_arn      = aws_iam_role.ecs_execution_role.arn
  task_role_arn           = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([{
    name      = "wordpress-cron"
    image     = "${var.ecr_repository}:${var.image_tag}"
    essential = true

    command = [
      "/bin/bash",
      "-c",
      "wp cron event run --due-now --allow-root --path=/var/www/html"
    ]

    environment = [
      {
        name  = "WP_ENV"
        value = var.environment
      },
      {
        name  = "DB_HOST"
        value = var.db_host
      },
      {
        name  = "DB_NAME"
        value = var.db_name
      }
    ]

    secrets = [
      {
        name      = "DB_USER"
        valueFrom = "${var.db_secret_arn}:username::"
      },
      {
        name      = "DB_PASSWORD"
        valueFrom = "${var.db_secret_arn}:password::"
      }
    ]

    mountPoints = [{
      sourceVolume  = "wordpress-content"
      containerPath = "/var/www/html/wp-content"
      readOnly      = false
    }]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/wordpress-cron/${var.tenant_name}"
        "awslogs-region"        = var.region
        "awslogs-stream-prefix" = "cron"
      }
    }
  }])

  volume {
    name = "wordpress-content"
    efs_volume_configuration {
      file_system_id     = var.efs_id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = var.efs_access_point_id
      }
    }
  }
}
```

### Step 3: Create EventBridge Rule

**File:** `/2_bbws_terraform/modules/ecs-cron/eventbridge.tf`

```hcl
resource "aws_cloudwatch_event_rule" "wordpress_cron" {
  name                = "${var.tenant_name}-wordpress-cron"
  description         = "Trigger WordPress cron every 15 minutes"
  schedule_expression = "rate(15 minutes)"
}

resource "aws_cloudwatch_event_target" "wordpress_cron" {
  rule      = aws_cloudwatch_event_rule.wordpress_cron.name
  target_id = "wordpress-cron-task"
  arn       = var.ecs_cluster_arn
  role_arn  = aws_iam_role.eventbridge_ecs_role.arn

  ecs_target {
    task_count          = 1
    task_definition_arn = aws_ecs_task_definition.wordpress_cron.arn
    launch_type         = "FARGATE"
    platform_version    = "LATEST"

    network_configuration {
      subnets          = var.private_subnet_ids
      security_groups  = [var.ecs_security_group_id]
      assign_public_ip = false
    }
  }
}
```

### Step 4: IAM Role for EventBridge

```hcl
resource "aws_iam_role" "eventbridge_ecs_role" {
  name = "${var.tenant_name}-eventbridge-ecs-cron"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "events.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "eventbridge_ecs_policy" {
  name = "eventbridge-ecs-task-execution"
  role = aws_iam_role.eventbridge_ecs_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ecs:RunTask"
      ]
      Resource = [
        aws_ecs_task_definition.wordpress_cron.arn
      ]
    },
    {
      Effect = "Allow"
      Action = [
        "iam:PassRole"
      ]
      Resource = [
        aws_iam_role.ecs_execution_role.arn,
        aws_iam_role.ecs_task_role.arn
      ]
    }]
  })
}
```

### Manual Setup Script (if not using Terraform)

```bash
#!/bin/bash
# setup-wordpress-cron.sh

TENANT_NAME="$1"
ENVIRONMENT="${2:-dev}"

case $ENVIRONMENT in
    dev)
        AWS_PROFILE="Tebogo-dev"
        REGION="eu-west-1"
        CLUSTER_NAME="bbws-wordpress-dev"
        ;;
    sit)
        AWS_PROFILE="Tebogo-sit"
        REGION="eu-west-1"
        CLUSTER_NAME="bbws-wordpress-sit"
        ;;
    prod)
        AWS_PROFILE="Tebogo-prod"
        REGION="af-south-1"
        CLUSTER_NAME="bbws-wordpress-prod"
        ;;
esac

# Get existing task definition
TASK_FAMILY="${TENANT_NAME}-web"

# Register cron task definition (reuse web task with different command)
aws ecs register-task-definition \
    --cli-input-json file://<(aws ecs describe-task-definition \
        --task-definition "${TASK_FAMILY}" \
        --profile "${AWS_PROFILE}" \
        --region "${REGION}" \
        --query 'taskDefinition' | \
        jq '.family = "'${TENANT_NAME}'-cron" |
            .containerDefinitions[0].command = ["/bin/bash", "-c", "wp cron event run --due-now --allow-root --path=/var/www/html"] |
            .containerDefinitions[0].name = "wordpress-cron" |
            del(.taskDefinitionArn, .revision, .status, .requiresAttributes, .compatibilities, .registeredAt, .registeredBy)') \
    --profile "${AWS_PROFILE}" \
    --region "${REGION}"

echo "✅ Cron task definition registered"

# Create EventBridge rule
aws events put-rule \
    --name "${TENANT_NAME}-wordpress-cron" \
    --description "Trigger WordPress cron every 15 minutes for ${TENANT_NAME}" \
    --schedule-expression "rate(15 minutes)" \
    --profile "${AWS_PROFILE}" \
    --region "${REGION}"

echo "✅ EventBridge rule created"

# Add ECS task target to rule
# (Requires additional IAM role creation - see Terraform example above)

echo "✅ WordPress cron configured for ${TENANT_NAME}"
```

### Verification

**1. Check EventBridge Rule:**
```bash
aws events describe-rule \
    --name "${TENANT_NAME}-wordpress-cron" \
    --profile "${AWS_PROFILE}" \
    --query '[Name,State,ScheduleExpression]' \
    --output table
```

**2. Monitor Cron Execution:**
```bash
# View CloudWatch logs
aws logs tail "/ecs/wordpress-cron/${TENANT_NAME}" \
    --follow \
    --profile "${AWS_PROFILE}"
```

**3. Test Cron Manually:**
```bash
# Run cron task manually
aws ecs run-task \
    --cluster "${CLUSTER_NAME}" \
    --task-definition "${TENANT_NAME}-cron" \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[${SUBNET_IDS}],securityGroups=[${SG_ID}],assignPublicIp=DISABLED}" \
    --profile "${AWS_PROFILE}"
```

### Troubleshooting

**Issue: Cron tasks not running**
```bash
# Check EventBridge rule state
aws events list-rules --name-prefix "${TENANT_NAME}" --profile "${AWS_PROFILE}"

# Check ECS task execution history
aws ecs list-tasks --cluster "${CLUSTER_NAME}" --family "${TENANT_NAME}-cron" --profile "${AWS_PROFILE}"
```

**Issue: Cron tasks failing**
```bash
# Check CloudWatch logs for errors
aws logs tail "/ecs/wordpress-cron/${TENANT_NAME}" --profile "${AWS_PROFILE}"
```

---

## PHP Configuration & Resource Limits

### Overview

Proper PHP configuration is critical for WordPress performance and functionality, especially for:
- Large file uploads (themes, plugins, media)
- WooCommerce orders with many line items
- Memory-intensive operations (image processing, exports)

### PHP Configuration Requirements

| Setting | Default | Recommended | WooCommerce |
|---------|---------|-------------|-------------|
| `memory_limit` | 128M | 256M | 512M |
| `upload_max_filesize` | 2M | 64M | 64M |
| `post_max_size` | 8M | 64M | 64M |
| `max_execution_time` | 30 | 120 | 300 |
| `max_input_vars` | 1000 | 3000 | 5000 |
| `max_input_time` | 60 | 120 | 300 |

### Method 1: Environment Variables (Docker)

**Recommended approach for containerized WordPress.**

Update ECS task definition environment variables:

```json
{
  "environment": [
    {
      "name": "PHP_MEMORY_LIMIT",
      "value": "256M"
    },
    {
      "name": "PHP_UPLOAD_MAX_FILESIZE",
      "value": "64M"
    },
    {
      "name": "PHP_POST_MAX_SIZE",
      "value": "64M"
    },
    {
      "name": "PHP_MAX_EXECUTION_TIME",
      "value": "120"
    },
    {
      "name": "PHP_MAX_INPUT_VARS",
      "value": "3000"
    },
    {
      "name": "PHP_MAX_INPUT_TIME",
      "value": "120"
    }
  ]
}
```

**Dockerfile must support these variables:**

```dockerfile
# In WordPress Dockerfile entrypoint script
if [ ! -z "$PHP_MEMORY_LIMIT" ]; then
    echo "memory_limit = $PHP_MEMORY_LIMIT" >> /usr/local/etc/php/conf.d/custom.ini
fi

if [ ! -z "$PHP_UPLOAD_MAX_FILESIZE" ]; then
    echo "upload_max_filesize = $PHP_UPLOAD_MAX_FILESIZE" >> /usr/local/etc/php/conf.d/custom.ini
fi

if [ ! -z "$PHP_POST_MAX_SIZE" ]; then
    echo "post_max_size = $PHP_POST_MAX_SIZE" >> /usr/local/etc/php/conf.d/custom.ini
fi

if [ ! -z "$PHP_MAX_EXECUTION_TIME" ]; then
    echo "max_execution_time = $PHP_MAX_EXECUTION_TIME" >> /usr/local/etc/php/conf.d/custom.ini
fi

if [ ! -z "$PHP_MAX_INPUT_VARS" ]; then
    echo "max_input_vars = $PHP_MAX_INPUT_VARS" >> /usr/local/etc/php/conf.d/custom.ini
fi

if [ ! -z "$PHP_MAX_INPUT_TIME" ]; then
    echo "max_input_time = $PHP_MAX_INPUT_TIME" >> /usr/local/etc/php/conf.d/custom.ini
fi
```

### Method 2: Custom php.ini File

**For non-containerized environments or custom overrides.**

Create `/var/www/html/php.ini`:

```ini
; WordPress PHP Configuration

; Memory
memory_limit = 256M

; Upload Limits
upload_max_filesize = 64M
post_max_size = 64M

; Execution Time
max_execution_time = 120
max_input_time = 120

; Input Variables (for large forms, Divi theme)
max_input_vars = 3000

; Error Handling
display_errors = Off
display_startup_errors = Off
log_errors = On
error_log = /var/log/php/error.log

; Security
expose_php = Off
allow_url_fopen = On
allow_url_include = Off

; Session
session.cookie_httponly = 1
session.cookie_secure = 1
session.use_strict_mode = 1

; OPcache (Performance)
opcache.enable = 1
opcache.memory_consumption = 128
opcache.interned_strings_buffer = 8
opcache.max_accelerated_files = 10000
opcache.revalidate_freq = 60
opcache.fast_shutdown = 1
```

### Method 3: .user.ini File

**For shared hosting or when php.ini modification isn't allowed.**

Create `/var/www/html/.user.ini`:

```ini
memory_limit = 256M
upload_max_filesize = 64M
post_max_size = 64M
max_execution_time = 120
max_input_vars = 3000
```

### Terraform Configuration

**File:** `/2_bbws_terraform/modules/ecs-wordpress/task-definition.tf`

```hcl
resource "aws_ecs_task_definition" "wordpress" {
  # ... other configuration ...

  container_definitions = jsonencode([{
    name  = "wordpress"
    image = "${var.ecr_repository}:${var.image_tag}"

    environment = [
      # WordPress configuration
      { name = "WP_ENV", value = var.environment },
      { name = "DB_HOST", value = var.db_host },
      { name = "DB_NAME", value = var.db_name },

      # PHP configuration
      { name = "PHP_MEMORY_LIMIT", value = var.php_memory_limit },
      { name = "PHP_UPLOAD_MAX_FILESIZE", value = var.php_upload_max_filesize },
      { name = "PHP_POST_MAX_SIZE", value = var.php_post_max_size },
      { name = "PHP_MAX_EXECUTION_TIME", value = var.php_max_execution_time },
      { name = "PHP_MAX_INPUT_VARS", value = var.php_max_input_vars },
      { name = "PHP_MAX_INPUT_TIME", value = var.php_max_input_time }
    ]
  }])
}

# Variables with defaults
variable "php_memory_limit" {
  description = "PHP memory limit"
  type        = string
  default     = "256M"
}

variable "php_upload_max_filesize" {
  description = "PHP max upload file size"
  type        = string
  default     = "64M"
}

variable "php_post_max_size" {
  description = "PHP max POST size"
  type        = string
  default     = "64M"
}

variable "php_max_execution_time" {
  description = "PHP max execution time in seconds"
  type        = string
  default     = "120"
}

variable "php_max_input_vars" {
  description = "PHP max input variables"
  type        = string
  default     = "3000"
}

variable "php_max_input_time" {
  description = "PHP max input time in seconds"
  type        = string
  default     = "120"
}
```

### ECS Task Resource Limits

**Match PHP memory limits to ECS task memory:**

```hcl
resource "aws_ecs_task_definition" "wordpress" {
  # ... other configuration ...

  cpu    = 512   # 0.5 vCPU
  memory = 1024  # 1GB (must be >= PHP memory_limit + overhead)

  # For WooCommerce or high-traffic sites:
  # cpu    = 1024  # 1 vCPU
  # memory = 2048  # 2GB
}
```

**Rule of thumb:** ECS memory should be at least 2x PHP `memory_limit` to account for:
- PHP process overhead
- Web server (Apache/Nginx)
- System processes

### Verification

**1. Check PHP Configuration:**

```bash
# Via ECS exec
aws ecs execute-command \
    --cluster "${CLUSTER_NAME}" \
    --task "${TASK_ID}" \
    --container wordpress \
    --command "php -i | grep -E '(memory_limit|upload_max|post_max|max_execution|max_input)'" \
    --interactive \
    --profile "${AWS_PROFILE}"
```

**2. Via WordPress Dashboard:**
- Login to wp-admin
- Tools → Site Health → Info → Server
- Check PHP configuration values

**3. Via phpinfo():**

Create temporary file (delete after checking):
```php
<?php phpinfo(); ?>
```

### Common Issues

**Issue: "Allowed memory size exhausted"**
- Increase `memory_limit` in PHP configuration
- Increase ECS task memory allocation

**Issue: "Maximum execution time exceeded"**
- Increase `max_execution_time`
- Check for plugin conflicts or slow database queries

**Issue: "File upload error"**
- Verify `upload_max_filesize` and `post_max_size` match
- Check EFS mount permissions (www-data:www-data)

**Issue: Divi theme settings not saving**
- Increase `max_input_vars` to 3000+
- Divi has many form fields that exceed default 1000 limit

---

## Phase 5: SIT Promotion

### When to Promote to SIT

- ✅ All DEV tests passed
- ✅ Forms working (emails redirected to test address)
- ✅ Content renders correctly
- ✅ Plugins functional
- ✅ Performance acceptable (< 3s)
- ✅ No encoding issues
- ✅ No PHP errors

### SIT Promotion Process

**1. Run Migration Script for SIT**
```bash
./migrate-wordpress-tenant.sh {TENANT_NAME} \
  --source-host {tenant}.wpdev.kimmyai.io \  # Use DEV as source
  --environment sit \
  --test-email tebogo@bigbeard.co.za
```

**2. Update wp-config.php for SIT**
```php
define('WP_ENV', 'sit');
define('TEST_EMAIL_REDIRECT', 'tebogo@bigbeard.co.za');
```

**3. Run Validation Script**
```bash
./validate-migration.sh https://{tenant}.wpsit.kimmyai.io
```

**4. User Acceptance Testing (UAT)**
- Share URL with stakeholders
- Provide UAT checklist
- Collect feedback

**5. Stakeholder Sign-Off**
- Document approval
- Schedule production cutover

---

## Phase 6: Production Cutover

### Pre-Cutover Checklist

- [ ] SIT testing complete
- [ ] Stakeholder sign-off obtained
- [ ] Cutover window scheduled
- [ ] Rollback plan documented
- [ ] Team notified

### Production Migration Steps

**1. Disable Test Mocking**

Remove or update `wp-config.php`:
```php
// Remove these lines for production:
// define('WP_ENV', 'dev');
// define('TEST_EMAIL_REDIRECT', 'tebogo@bigbeard.co.za');

// Set to production:
define('WP_ENV', 'prod');
```

**2. Remove Test MU-Plugins**

Keep only production-safe plugins:
```bash
# Keep: force-https.php
# Remove: test-email-redirect.php, environment-indicator.php

rm /var/www/html/wp-content/mu-plugins/bbws-platform/test-email-redirect.php
rm /var/www/html/wp-content/mu-plugins/bbws-platform/environment-indicator.php
```

**3. Restore Real Tracking Scripts**

- Verify Google Analytics tracking ID
- Verify Facebook Pixel ID
- Test tracking events in GA/FB Test Mode first

**4. Update DNS**

- Point domain to production CloudFront distribution
- TTL: 300 seconds (5 minutes) for quick rollback

**5. Monitor**

First 24 hours:
- [ ] CloudWatch logs (no errors)
- [ ] Form submissions (emails going to correct addresses)
- [ ] Analytics tracking (events appearing in GA/FB)
- [ ] Performance (load times)
- [ ] Error rate (zero)

---

## Monitoring & Alerting Setup

### Overview

Proactive monitoring prevents outages and ensures rapid incident response.

### Critical Metrics to Monitor

| Metric | Threshold | Alert Priority | Action |
|--------|-----------|----------------|--------|
| ECS CPU Utilization | > 80% for 5 min | HIGH | Scale up tasks |
| ECS Memory Utilization | > 85% for 5 min | HIGH | Increase task memory |
| RDS CPU Utilization | > 75% for 10 min | MEDIUM | Check slow queries |
| RDS Database Connections | > 90% of max | HIGH | Check connection leaks |
| ALB 5xx Error Rate | > 1% of requests | CRITICAL | Investigate immediately |
| ALB Response Time | > 3 seconds (p95) | MEDIUM | Performance optimization |
| EFS Throughput | > 80% of burst credits | MEDIUM | Monitor file operations |
| CloudFront 4xx/5xx Errors | > 5% of requests | HIGH | Check origin health |

### CloudWatch Alarms Setup Script

```bash
#!/bin/bash
# setup-cloudwatch-alarms.sh

TENANT_NAME="$1"
ENVIRONMENT="${2:-dev}"
SNS_TOPIC_ARN="${3}"  # SNS topic for alert notifications

case $ENVIRONMENT in
    dev)
        AWS_PROFILE="Tebogo-dev"
        REGION="eu-west-1"
        CLUSTER_NAME="bbws-wordpress-dev"
        ;;
    sit)
        AWS_PROFILE="Tebogo-sit"
        REGION="eu-west-1"
        CLUSTER_NAME="bbws-wordpress-sit"
        ;;
    prod)
        AWS_PROFILE="Tebogo-prod"
        REGION="af-south-1"
        CLUSTER_NAME="bbws-wordpress-prod"
        ;;
esac

echo "=========================================================================="
echo "Setting Up CloudWatch Alarms for: ${TENANT_NAME}"
echo "Environment: ${ENVIRONMENT}"
echo "=========================================================================="

# Get ECS service name
SERVICE_NAME="${TENANT_NAME}-web"

# 1. ECS CPU Utilization Alarm
aws cloudwatch put-metric-alarm \
    --alarm-name "${TENANT_NAME}-${ENVIRONMENT}-ecs-cpu-high" \
    --alarm-description "ECS CPU utilization above 80% for ${TENANT_NAME}" \
    --metric-name CPUUtilization \
    --namespace AWS/ECS \
    --statistic Average \
    --period 300 \
    --threshold 80 \
    --comparison-operator GreaterThanThreshold \
    --evaluation-periods 1 \
    --dimensions Name=ServiceName,Value="${SERVICE_NAME}" Name=ClusterName,Value="${CLUSTER_NAME}" \
    --alarm-actions "${SNS_TOPIC_ARN}" \
    --profile "${AWS_PROFILE}" \
    --region "${REGION}"

echo "✅ ECS CPU alarm created"

# 2. ECS Memory Utilization Alarm
aws cloudwatch put-metric-alarm \
    --alarm-name "${TENANT_NAME}-${ENVIRONMENT}-ecs-memory-high" \
    --alarm-description "ECS memory utilization above 85% for ${TENANT_NAME}" \
    --metric-name MemoryUtilization \
    --namespace AWS/ECS \
    --statistic Average \
    --period 300 \
    --threshold 85 \
    --comparison-operator GreaterThanThreshold \
    --evaluation-periods 1 \
    --dimensions Name=ServiceName,Value="${SERVICE_NAME}" Name=ClusterName,Value="${CLUSTER_NAME}" \
    --alarm-actions "${SNS_TOPIC_ARN}" \
    --profile "${AWS_PROFILE}" \
    --region "${REGION}"

echo "✅ ECS Memory alarm created"

# 3. RDS CPU Utilization Alarm
RDS_INSTANCE_ID=$(aws rds describe-db-instances \
    --profile "${AWS_PROFILE}" \
    --region "${REGION}" \
    --query "DBInstances[?contains(DBInstanceIdentifier,'${ENVIRONMENT}')].DBInstanceIdentifier" \
    --output text | head -n1)

if [ ! -z "$RDS_INSTANCE_ID" ]; then
    aws cloudwatch put-metric-alarm \
        --alarm-name "${TENANT_NAME}-${ENVIRONMENT}-rds-cpu-high" \
        --alarm-description "RDS CPU utilization above 75%" \
        --metric-name CPUUtilization \
        --namespace AWS/RDS \
        --statistic Average \
        --period 600 \
        --threshold 75 \
        --comparison-operator GreaterThanThreshold \
        --evaluation-periods 1 \
        --dimensions Name=DBInstanceIdentifier,Value="${RDS_INSTANCE_ID}" \
        --alarm-actions "${SNS_TOPIC_ARN}" \
        --profile "${AWS_PROFILE}" \
        --region "${REGION}"

    echo "✅ RDS CPU alarm created"
fi

# 4. RDS Database Connections Alarm
aws cloudwatch put-metric-alarm \
    --alarm-name "${TENANT_NAME}-${ENVIRONMENT}-rds-connections-high" \
    --alarm-description "RDS database connections above 90% of max" \
    --metric-name DatabaseConnections \
    --namespace AWS/RDS \
    --statistic Average \
    --period 300 \
    --threshold 90 \
    --comparison-operator GreaterThanThreshold \
    --evaluation-periods 1 \
    --dimensions Name=DBInstanceIdentifier,Value="${RDS_INSTANCE_ID}" \
    --alarm-actions "${SNS_TOPIC_ARN}" \
    --profile "${AWS_PROFILE}" \
    --region "${REGION}"

echo "✅ RDS Connections alarm created"

# 5. ALB 5xx Error Rate Alarm
ALB_ARN=$(aws elbv2 describe-load-balancers \
    --profile "${AWS_PROFILE}" \
    --region "${REGION}" \
    --query "LoadBalancers[?contains(LoadBalancerName,'${ENVIRONMENT}')].LoadBalancerArn" \
    --output text | head -n1)

ALB_NAME=$(basename "$ALB_ARN")

if [ ! -z "$ALB_ARN" ]; then
    aws cloudwatch put-metric-alarm \
        --alarm-name "${TENANT_NAME}-${ENVIRONMENT}-alb-5xx-errors" \
        --alarm-description "ALB 5xx error rate above 1%" \
        --metric-name HTTPCode_Target_5XX_Count \
        --namespace AWS/ApplicationELB \
        --statistic Sum \
        --period 300 \
        --threshold 10 \
        --comparison-operator GreaterThanThreshold \
        --evaluation-periods 1 \
        --dimensions Name=LoadBalancer,Value="${ALB_NAME}" \
        --alarm-actions "${SNS_TOPIC_ARN}" \
        --profile "${AWS_PROFILE}" \
        --region "${REGION}"

    echo "✅ ALB 5xx errors alarm created"
fi

# 6. ALB Response Time Alarm
aws cloudwatch put-metric-alarm \
    --alarm-name "${TENANT_NAME}-${ENVIRONMENT}-alb-response-time-high" \
    --alarm-description "ALB response time above 3 seconds" \
    --metric-name TargetResponseTime \
    --namespace AWS/ApplicationELB \
    --statistic Average \
    --period 300 \
    --threshold 3 \
    --comparison-operator GreaterThanThreshold \
    --evaluation-periods 2 \
    --dimensions Name=LoadBalancer,Value="${ALB_NAME}" \
    --alarm-actions "${SNS_TOPIC_ARN}" \
    --profile "${AWS_PROFILE}" \
    --region "${REGION}"

echo "✅ ALB response time alarm created"

echo ""
echo "=========================================================================="
echo "✅ CloudWatch Alarms Setup Complete!"
echo "=========================================================================="
echo ""
echo "Alarms Created:"
echo "  • ECS CPU Utilization (> 80%)"
echo "  • ECS Memory Utilization (> 85%)"
echo "  • RDS CPU Utilization (> 75%)"
echo "  • RDS Database Connections (> 90 connections)"
echo "  • ALB 5xx Errors (> 10 errors in 5 min)"
echo "  • ALB Response Time (> 3 seconds)"
echo ""
echo "Notifications will be sent to: ${SNS_TOPIC_ARN}"
echo ""
```

### SNS Topic for Alerts

**Create SNS topic and subscribe email:**

```bash
# Create SNS topic
SNS_TOPIC_ARN=$(aws sns create-topic \
    --name "wordpress-${ENVIRONMENT}-alerts" \
    --profile "${AWS_PROFILE}" \
    --region "${REGION}" \
    --query 'TopicArn' \
    --output text)

# Subscribe email address
aws sns subscribe \
    --topic-arn "${SNS_TOPIC_ARN}" \
    --protocol email \
    --notification-endpoint "alerts@bigbeard.co.za" \
    --profile "${AWS_PROFILE}" \
    --region "${REGION}"

echo "✅ SNS topic created: ${SNS_TOPIC_ARN}"
echo "⚠️  Check email and confirm subscription"
```

### CloudWatch Dashboard

**Create custom dashboard for tenant monitoring:**

```bash
#!/bin/bash
# create-tenant-dashboard.sh

TENANT_NAME="$1"
ENVIRONMENT="${2:-dev}"

cat > /tmp/dashboard-${TENANT_NAME}.json << EOF
{
  "widgets": [
    {
      "type": "metric",
      "properties": {
        "metrics": [
          [ "AWS/ECS", "CPUUtilization", { "stat": "Average" } ],
          [ ".", "MemoryUtilization", { "stat": "Average" } ]
        ],
        "period": 300,
        "stat": "Average",
        "region": "${REGION}",
        "title": "ECS Resource Utilization - ${TENANT_NAME}",
        "yAxis": {
          "left": { "min": 0, "max": 100 }
        }
      }
    },
    {
      "type": "metric",
      "properties": {
        "metrics": [
          [ "AWS/ApplicationELB", "TargetResponseTime", { "stat": "Average" } ],
          [ "...", { "stat": "p95" } ]
        ],
        "period": 300,
        "stat": "Average",
        "region": "${REGION}",
        "title": "ALB Response Time - ${TENANT_NAME}",
        "yAxis": {
          "left": { "min": 0 }
        }
      }
    },
    {
      "type": "metric",
      "properties": {
        "metrics": [
          [ "AWS/ApplicationELB", "HTTPCode_Target_2XX_Count", { "stat": "Sum", "color": "#2ca02c" } ],
          [ ".", "HTTPCode_Target_4XX_Count", { "stat": "Sum", "color": "#ff7f0e" } ],
          [ ".", "HTTPCode_Target_5XX_Count", { "stat": "Sum", "color": "#d62728" } ]
        ],
        "period": 300,
        "stat": "Sum",
        "region": "${REGION}",
        "title": "HTTP Response Codes - ${TENANT_NAME}",
        "yAxis": {
          "left": { "min": 0 }
        }
      }
    },
    {
      "type": "log",
      "properties": {
        "query": "SOURCE '/ecs/wordpress/${TENANT_NAME}'\n| fields @timestamp, @message\n| filter @message like /ERROR/\n| sort @timestamp desc\n| limit 20",
        "region": "${REGION}",
        "title": "Recent Errors - ${TENANT_NAME}",
        "stacked": false
      }
    }
  ]
}
EOF

# Create dashboard
aws cloudwatch put-dashboard \
    --dashboard-name "WordPress-${TENANT_NAME}-${ENVIRONMENT}" \
    --dashboard-body file:///tmp/dashboard-${TENANT_NAME}.json \
    --profile "${AWS_PROFILE}" \
    --region "${REGION}"

echo "✅ CloudWatch dashboard created: WordPress-${TENANT_NAME}-${ENVIRONMENT}"
```

### Log Insights Queries

**Save these queries for troubleshooting:**

**1. Find PHP Errors:**
```
fields @timestamp, @message
| filter @message like /PHP Fatal error/
| sort @timestamp desc
| limit 50
```

**2. Find Slow Requests (> 3 seconds):**
```
fields @timestamp, @message
| filter @message like /request_time/
| parse @message /request_time: (?<duration>\d+\.\d+)/
| filter duration > 3
| sort duration desc
| limit 20
```

**3. Find Failed Login Attempts:**
```
fields @timestamp, @message
| filter @message like /wp-login.php/ and @message like /failed/
| stats count() by bin(5m)
```

---

## Post-Migration Backup Strategy

### Overview

**CRITICAL:** Implement backups immediately after migration to prevent data loss.

### Backup Requirements

| Data Type | Frequency | Retention | Method |
|-----------|-----------|-----------|--------|
| Database | Daily | 30 days | AWS Backup / RDS Snapshots |
| EFS Files | Daily | 30 days | AWS Backup |
| Database (Pre-Change) | On-demand | 7 days | Manual snapshot |
| Configuration | On change | 90 days | Git repository |

### AWS Backup Plan (Automated)

**Script:** `/2_bbws_terraform/modules/backup/backup-plan.tf`

```hcl
resource "aws_backup_plan" "wordpress" {
  name = "wordpress-${var.environment}-backup-plan"

  rule {
    rule_name         = "daily_backup"
    target_vault_name = aws_backup_vault.wordpress.name
    schedule          = "cron(0 2 * * ? *)"  # 2 AM UTC daily

    lifecycle {
      delete_after = 30  # 30 days retention
    }

    recovery_point_tags = {
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }

  # Weekly backup with longer retention
  rule {
    rule_name         = "weekly_backup"
    target_vault_name = aws_backup_vault.wordpress.name
    schedule          = "cron(0 3 ? * SUN *)"  # 3 AM UTC every Sunday

    lifecycle {
      delete_after = 90  # 90 days retention
    }

    recovery_point_tags = {
      Environment = var.environment
      BackupType  = "Weekly"
      ManagedBy   = "Terraform"
    }
  }
}

resource "aws_backup_vault" "wordpress" {
  name = "wordpress-${var.environment}-vault"

  kms_key_arn = aws_kms_key.backup.arn

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_kms_key" "backup" {
  description             = "KMS key for WordPress backup encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = {
    Environment = var.environment
    Purpose     = "Backup Encryption"
  }
}

# Backup selection for RDS
resource "aws_backup_selection" "rds" {
  name         = "wordpress-rds-backup"
  plan_id      = aws_backup_plan.wordpress.id
  iam_role_arn = aws_iam_role.backup.arn

  selection_tag {
    type  = "STRINGEQUALS"
    key   = "Backup"
    value = "true"
  }

  resources = [
    var.rds_instance_arn
  ]
}

# Backup selection for EFS
resource "aws_backup_selection" "efs" {
  name         = "wordpress-efs-backup"
  plan_id      = aws_backup_plan.wordpress.id
  iam_role_arn = aws_iam_role.backup.arn

  resources = [
    var.efs_file_system_arn
  ]
}

# IAM role for AWS Backup
resource "aws_iam_role" "backup" {
  name = "wordpress-${var.environment}-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "backup.amazonaws.com"
      }
    }]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup",
    "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
  ]
}
```

### Manual Backup Scripts

**Database Backup:**

```bash
#!/bin/bash
# backup-database.sh

TENANT_NAME="$1"
ENVIRONMENT="${2:-dev}"
BACKUP_DIR="/tmp/backups/${TENANT_NAME}"

mkdir -p "${BACKUP_DIR}"

case $ENVIRONMENT in
    dev)
        AWS_PROFILE="Tebogo-dev"
        REGION="eu-west-1"
        ;;
    sit)
        AWS_PROFILE="Tebogo-sit"
        REGION="eu-west-1"
        ;;
    prod)
        AWS_PROFILE="Tebogo-prod"
        REGION="af-south-1"
        ;;
esac

# Get database credentials from Secrets Manager
DB_SECRET=$(aws secretsmanager get-secret-value \
    --secret-id "rds/wordpress/${TENANT_NAME}/credentials" \
    --profile "${AWS_PROFILE}" \
    --region "${REGION}" \
    --query 'SecretString' \
    --output text)

DB_HOST=$(echo "$DB_SECRET" | jq -r '.host')
DB_NAME=$(echo "$DB_SECRET" | jq -r '.dbname')
DB_USER=$(echo "$DB_SECRET" | jq -r '.username')
DB_PASS=$(echo "$DB_SECRET" | jq -r '.password')

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/${TENANT_NAME}_${TIMESTAMP}.sql.gz"

echo "=========================================================================="
echo "Backing up database: ${TENANT_NAME}"
echo "Environment: ${ENVIRONMENT}"
echo "=========================================================================="

# Create backup with compression
mysqldump \
    --default-character-set=utf8mb4 \
    --single-transaction \
    --routines \
    --triggers \
    --events \
    -h "${DB_HOST}" \
    -u "${DB_USER}" \
    -p"${DB_PASS}" \
    "${DB_NAME}" | gzip > "${BACKUP_FILE}"

if [ $? -eq 0 ]; then
    BACKUP_SIZE=$(du -h "${BACKUP_FILE}" | cut -f1)
    echo "✅ Backup successful: ${BACKUP_FILE} (${BACKUP_SIZE})"

    # Upload to S3 for long-term storage
    S3_BUCKET="bbws-backups-${ENVIRONMENT}"
    S3_KEY="databases/${TENANT_NAME}/${TENANT_NAME}_${TIMESTAMP}.sql.gz"

    aws s3 cp "${BACKUP_FILE}" "s3://${S3_BUCKET}/${S3_KEY}" \
        --profile "${AWS_PROFILE}" \
        --region "${REGION}" \
        --storage-class STANDARD_IA

    echo "✅ Backup uploaded to S3: s3://${S3_BUCKET}/${S3_KEY}"
else
    echo "❌ Backup failed!"
    exit 1
fi
```

**EFS Snapshot via AWS Backup:**

```bash
#!/bin/bash
# backup-efs.sh

TENANT_NAME="$1"
ENVIRONMENT="${2:-dev}"

case $ENVIRONMENT in
    dev)
        AWS_PROFILE="Tebogo-dev"
        REGION="eu-west-1"
        ;;
    sit)
        AWS_PROFILE="Tebogo-sit"
        REGION="eu-west-1"
        ;;
    prod)
        AWS_PROFILE="Tebogo-prod"
        REGION="af-south-1"
        ;;
esac

# Get EFS file system ID
EFS_ID=$(aws efs describe-file-systems \
    --profile "${AWS_PROFILE}" \
    --region "${REGION}" \
    --query "FileSystems[?Tags[?Key=='Environment' && Value=='${ENVIRONMENT}']].FileSystemId" \
    --output text | head -n1)

# Create on-demand backup
BACKUP_JOB_ID=$(aws backup start-backup-job \
    --backup-vault-name "wordpress-${ENVIRONMENT}-vault" \
    --resource-arn "arn:aws:elasticfilesystem:${REGION}:*:file-system/${EFS_ID}" \
    --iam-role-arn "arn:aws:iam::*:role/wordpress-${ENVIRONMENT}-backup-role" \
    --profile "${AWS_PROFILE}" \
    --region "${REGION}" \
    --query 'BackupJobId' \
    --output text)

echo "✅ EFS backup started: ${BACKUP_JOB_ID}"
echo "Monitor status with:"
echo "  aws backup describe-backup-job --backup-job-id ${BACKUP_JOB_ID} --profile ${AWS_PROFILE}"
```

### Backup Verification

**Test restoration process quarterly:**

```bash
#!/bin/bash
# test-restore.sh

TENANT_NAME="$1"
BACKUP_FILE="$2"
TEST_DB_NAME="${TENANT_NAME}_restore_test"

# Restore to test database
mysql -h "${DB_HOST}" -u "${DB_USER}" -p"${DB_PASS}" \
    -e "CREATE DATABASE ${TEST_DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

zcat "${BACKUP_FILE}" | mysql -h "${DB_HOST}" -u "${DB_USER}" -p"${DB_PASS}" "${TEST_DB_NAME}"

if [ $? -eq 0 ]; then
    echo "✅ Backup restoration successful"

    # Verify table count
    TABLE_COUNT=$(mysql -h "${DB_HOST}" -u "${DB_USER}" -p"${DB_PASS}" \
        -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='${TEST_DB_NAME}';" \
        -sN)

    echo "✅ Restored ${TABLE_COUNT} tables"

    # Cleanup test database
    mysql -h "${DB_HOST}" -u "${DB_USER}" -p"${DB_PASS}" \
        -e "DROP DATABASE ${TEST_DB_NAME};"

    echo "✅ Test database cleaned up"
else
    echo "❌ Backup restoration failed!"
    exit 1
fi
```

### Backup Monitoring

**CloudWatch alarm for failed backups:**

```bash
aws cloudwatch put-metric-alarm \
    --alarm-name "wordpress-${ENVIRONMENT}-backup-failures" \
    --alarm-description "Alert on AWS Backup job failures" \
    --metric-name NumberOfBackupJobsFailed \
    --namespace AWS/Backup \
    --statistic Sum \
    --period 86400 \
    --threshold 1 \
    --comparison-operator GreaterThanOrEqualToThreshold \
    --evaluation-periods 1 \
    --alarm-actions "${SNS_TOPIC_ARN}" \
    --profile "${AWS_PROFILE}" \
    --region "${REGION}"
```

---

## Email Deliverability & DNS Records

### Overview

**IMPORTANT:** Without proper email configuration, WooCommerce order confirmations and form submissions won't reach customers.

### Email Delivery Options

| Method | Pros | Cons | Best For |
|--------|------|------|----------|
| Amazon SES | Reliable, scalable, cost-effective | Requires DNS setup | Production |
| WordPress SMTP Plugin | Easy setup, works with any provider | Depends on external SMTP | DEV/SIT |
| SendGrid / Mailgun | Feature-rich, good deliverability | Additional cost | High-volume sites |
| Default PHP mail() | No setup required | Poor deliverability, often blocked | Testing only |

### Recommended: Amazon SES

#### Step 1: Verify Domain in SES

```bash
#!/bin/bash
# setup-ses-domain.sh

DOMAIN="$1"
AWS_PROFILE="${2:-Tebogo-prod}"
REGION="${3:-af-south-1}"

echo "=========================================================================="
echo "Verifying domain in Amazon SES: ${DOMAIN}"
echo "=========================================================================="

# Verify domain
aws ses verify-domain-identity \
    --domain "${DOMAIN}" \
    --profile "${AWS_PROFILE}" \
    --region "${REGION}"

# Get verification token
VERIFICATION_TOKEN=$(aws ses verify-domain-identity \
    --domain "${DOMAIN}" \
    --profile "${AWS_PROFILE}" \
    --region "${REGION}" \
    --query 'VerificationToken' \
    --output text)

echo ""
echo "✅ Domain verification initiated"
echo ""
echo "=========================================================================="
echo "⚠️  ACTION REQUIRED: Add DNS TXT Record"
echo "=========================================================================="
echo ""
echo "Add the following TXT record to your DNS:"
echo ""
echo "  Name:  _amazonses.${DOMAIN}"
echo "  Type:  TXT"
echo "  Value: ${VERIFICATION_TOKEN}"
echo ""
echo "Verification usually completes within 72 hours."
echo ""
```

#### Step 2: Configure DKIM (Email Authentication)

```bash
# Enable DKIM signing
aws ses set-identity-dkim-enabled \
    --identity "${DOMAIN}" \
    --dkim-enabled \
    --profile "${AWS_PROFILE}" \
    --region "${REGION}"

# Get DKIM tokens
aws ses get-identity-dkim-attributes \
    --identities "${DOMAIN}" \
    --profile "${AWS_PROFILE}" \
    --region "${REGION}" \
    --query "DkimAttributes.\"${DOMAIN}\".DkimTokens" \
    --output table
```

**Add these CNAME records to DNS:**

```
{token1}._domainkey.example.com → {token1}.dkim.amazonses.com
{token2}._domainkey.example.com → {token2}.dkim.amazonses.com
{token3}._domainkey.example.com → {token3}.dkim.amazonses.com
```

#### Step 3: Configure SPF Record

**Add SPF TXT record to DNS:**

```
Name:  @  (or yourdomain.com)
Type:  TXT
Value: v=spf1 include:amazonses.com ~all
```

#### Step 4: Configure DMARC Record

**Add DMARC TXT record to DNS:**

```
Name:  _dmarc
Type:  TXT
Value: v=DMARC1; p=quarantine; rua=mailto:dmarc-reports@bigbeard.co.za
```

#### Step 5: Configure WordPress to Use SES

**Install WP Mail SMTP Plugin:**

```bash
# Via WP-CLI
wp plugin install wp-mail-smtp --activate --allow-root

# Configure plugin
wp option update wp_mail_smtp '{"mail":{"from_email":"noreply@example.com","from_name":"Example Site","mailer":"amazonses","return_path":true},"amazonses":{"region":"af-south-1","access_key_id":"AKIAIOSFODNN7EXAMPLE","secret_access_key":"wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"}}' --format=json --allow-root
```

**Alternative: Use IAM Role (Recommended):**

Add SES permissions to ECS task role:

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": [
      "ses:SendEmail",
      "ses:SendRawEmail"
    ],
    "Resource": "*"
  }]
}
```

### Email Testing Checklist

After SES setup, test:

- [ ] WordPress password reset email
- [ ] Contact form submission
- [ ] Gravity Forms notifications
- [ ] WooCommerce order confirmation
- [ ] WooCommerce shipping notification
- [ ] Admin notification emails

**Test command:**

```bash
# Test SES sending
aws ses send-email \
    --from "noreply@example.com" \
    --to "test@bigbeard.co.za" \
    --subject "SES Test Email" \
    --text "This is a test email from Amazon SES." \
    --profile "${AWS_PROFILE}" \
    --region "${REGION}"
```

### Monitoring Email Deliverability

**CloudWatch Metrics for SES:**

```bash
# Monitor bounce rate
aws cloudwatch get-metric-statistics \
    --namespace AWS/SES \
    --metric-name Reputation.BounceRate \
    --start-time $(date -u -d '1 day ago' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 86400 \
    --statistics Average \
    --profile "${AWS_PROFILE}" \
    --region "${REGION}"

# Monitor complaint rate
aws cloudwatch get-metric-statistics \
    --namespace AWS/SES \
    --metric-name Reputation.ComplaintRate \
    --start-time $(date -u -d '1 day ago' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 86400 \
    --statistics Average \
    --profile "${AWS_PROFILE}" \
    --region "${REGION}"
```

**Alarm on high bounce/complaint rates:**

```bash
aws cloudwatch put-metric-alarm \
    --alarm-name "ses-high-bounce-rate" \
    --alarm-description "SES bounce rate above 5%" \
    --metric-name Reputation.BounceRate \
    --namespace AWS/SES \
    --statistic Average \
    --period 86400 \
    --threshold 0.05 \
    --comparison-operator GreaterThanThreshold \
    --evaluation-periods 1 \
    --alarm-actions "${SNS_TOPIC_ARN}" \
    --profile "${AWS_PROFILE}" \
    --region "${REGION}"
```

---

## Go-Live Checklist & Cutover Procedures

### Overview

Structured go-live process prevents chaos and ensures smooth DNS cutover.

### Pre-Go-Live Checklist (Complete 48 Hours Before)

#### Technical Readiness

- [ ] **SSL Certificate:** Valid for production domain, installed in CloudFront
- [ ] **DNS Records:** Prepared but not switched (TTL lowered to 300s)
- [ ] **Email Configuration:** SES verified, DKIM/SPF/DMARC configured
- [ ] **Monitoring:** CloudWatch alarms configured, SNS notifications working
- [ ] **Backups:** Automated backups configured, restoration tested
- [ ] **Performance:** Load testing completed, < 3s page load time
- [ ] **Security:** WAF configured, security headers added, firewall rules set
- [ ] **Cron Jobs:** WordPress cron migrated to ECS scheduled tasks
- [ ] **PHP Configuration:** Memory limits, upload limits properly set
- [ ] **Database:** Connection pooling configured, slow query log enabled

#### Functional Testing

- [ ] **Homepage:** Renders correctly, all assets load
- [ ] **All Pages:** Spot-check 10-20 critical pages
- [ ] **Forms:** All forms submit successfully, emails received
- [ ] **E-commerce:** Cart, checkout, payment gateway working (if applicable)
- [ ] **User Login:** Authentication working, password reset functional
- [ ] **Admin Panel:** wp-admin accessible, all functions working
- [ ] **Mobile:** Responsive design verified on iOS/Android
- [ ] **Browsers:** Tested on Chrome, Firefox, Safari, Edge

#### Stakeholder Sign-Off

- [ ] **UAT Completed:** All user acceptance tests passed in SIT
- [ ] **Business Owner Approval:** Written sign-off obtained
- [ ] **Go-Live Date Confirmed:** Date/time agreed with stakeholders
- [ ] **Rollback Plan Documented:** Clear procedure for emergency rollback
- [ ] **Support Team Briefed:** Team aware of go-live, ready for issues

### Go-Live Day Timeline

#### T-24 Hours: Final Preparation

- [ ] Lower DNS TTL to 300 seconds (5 minutes)
- [ ] Take final backup of source site
- [ ] Verify CloudFront distribution healthy
- [ ] Verify ECS tasks running and stable
- [ ] Test restoration procedure

#### T-1 Hour: Pre-Cutover

- [ ] Enable maintenance mode on source site (if applicable)
- [ ] Take final database sync (if site still receiving traffic)
- [ ] Remove test MU-plugins (email-redirect, environment-indicator)
- [ ] Update wp-config.php: `WP_ENV='prod'`
- [ ] Verify real tracking scripts active (Analytics, Pixel)
- [ ] Clear all caches (WordPress, Divi, CloudFront)
- [ ] Verify production SSL certificate installed

#### T-0: DNS Cutover

**Cutover Script:**

```bash
#!/bin/bash
# go-live-cutover.sh

DOMAIN="$1"
CLOUDFRONT_DOMAIN="$2"  # e.g., d123456.cloudfront.net
HOSTED_ZONE_ID="$3"

AWS_PROFILE="Tebogo-prod"
REGION="af-south-1"

echo "=========================================================================="
echo "DNS CUTOVER: ${DOMAIN} → ${CLOUDFRONT_DOMAIN}"
echo "=========================================================================="
echo ""
echo "⚠️  WARNING: This will point production DNS to new infrastructure"
echo ""
read -p "Type 'GO-LIVE' to proceed: " CONFIRMATION

if [ "$CONFIRMATION" != "GO-LIVE" ]; then
    echo "❌ Cutover aborted"
    exit 1
fi

echo ""
echo "📝 Creating DNS change batch..."

cat > /tmp/dns-cutover.json << EOF
{
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "${DOMAIN}",
        "Type": "A",
        "AliasTarget": {
          "HostedZoneId": "Z2FDTNDATAQYW2",
          "DNSName": "${CLOUDFRONT_DOMAIN}",
          "EvaluateTargetHealth": false
        }
      }
    },
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "www.${DOMAIN}",
        "Type": "A",
        "AliasTarget": {
          "HostedZoneId": "Z2FDTNDATAQYW2",
          "DNSName": "${CLOUDFRONT_DOMAIN}",
          "EvaluateTargetHealth": false
        }
      }
    }
  ]
}
EOF

echo "✅ DNS change batch created"
echo ""

# Apply DNS changes
CHANGE_ID=$(aws route53 change-resource-record-sets \
    --hosted-zone-id "${HOSTED_ZONE_ID}" \
    --change-batch file:///tmp/dns-cutover.json \
    --profile "${AWS_PROFILE}" \
    --query 'ChangeInfo.Id' \
    --output text)

echo "✅ DNS change submitted: ${CHANGE_ID}"
echo ""
echo "⏳ Waiting for DNS propagation (this may take 5-15 minutes)..."
echo ""

# Wait for change to propagate
aws route53 wait resource-record-sets-changed \
    --id "${CHANGE_ID}" \
    --profile "${AWS_PROFILE}"

echo ""
echo "✅ DNS change COMPLETED"
echo ""
echo "=========================================================================="
echo "GO-LIVE SUCCESSFUL!"
echo "=========================================================================="
echo ""
echo "Timestamp: $(date -u +%Y-%m-%d %H:%M:%S UTC)"
echo ""
echo "Next Steps:"
echo "  1. Monitor CloudWatch logs for errors"
echo "  2. Test site from multiple locations"
echo "  3. Verify email delivery"
echo "  4. Monitor traffic in CloudFront"
echo "  5. Watch for alerts (first 24 hours)"
echo ""
```

#### T+15 Minutes: Immediate Verification

- [ ] Test site from external network (not your office)
- [ ] Verify SSL certificate shows as valid
- [ ] Check homepage loads correctly
- [ ] Test form submission → verify email received
- [ ] Check WordPress admin access
- [ ] Monitor CloudWatch logs for errors
- [ ] Verify CloudFront cache hitting

#### T+1 Hour: Extended Monitoring

- [ ] Check CloudWatch alarms (should be green)
- [ ] Monitor ECS task health
- [ ] Check RDS connections and CPU
- [ ] Verify no 5xx errors in ALB
- [ ] Test e-commerce checkout (if applicable)
- [ ] Confirm analytics tracking working

#### T+24 Hours: Post-Cutover Review

- [ ] Review CloudWatch metrics (errors, latency, traffic)
- [ ] Check email deliverability (no bounces/complaints)
- [ ] Verify backup jobs ran successfully
- [ ] Confirm no customer complaints
- [ ] Document any issues encountered
- [ ] Restore DNS TTL to 3600 (1 hour)

### Emergency Rollback Procedure

**If critical issues arise within first 4 hours:**

```bash
#!/bin/bash
# emergency-rollback.sh

DOMAIN="$1"
OLD_SERVER_IP="$2"  # IP of old server
HOSTED_ZONE_ID="$3"

echo "=========================================================================="
echo "⚠️  EMERGENCY ROLLBACK"
echo "=========================================================================="
echo ""
echo "Rolling back DNS for: ${DOMAIN}"
echo "Target: ${OLD_SERVER_IP}"
echo ""
read -p "Type 'ROLLBACK' to proceed: " CONFIRMATION

if [ "$CONFIRMATION" != "ROLLBACK" ]; then
    echo "❌ Rollback aborted"
    exit 1
fi

cat > /tmp/dns-rollback.json << EOF
{
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "${DOMAIN}",
        "Type": "A",
        "TTL": 300,
        "ResourceRecords": [{"Value": "${OLD_SERVER_IP}"}]
      }
    }
  ]
}
EOF

aws route53 change-resource-record-sets \
    --hosted-zone-id "${HOSTED_ZONE_ID}" \
    --change-batch file:///tmp/dns-rollback.json \
    --profile "Tebogo-prod"

echo "✅ DNS rolled back to old server"
echo "⏳ DNS propagation: 5-15 minutes"
```

---

## Rollback Procedures

### When to Rollback

- Critical bugs in production
- Database corruption
- Site completely down
- Major functionality broken

### Rollback Options

#### Option 1: DNS Rollback (Fastest - 5 minutes)

```bash
# Point DNS back to old server
aws route53 change-resource-record-sets \
  --hosted-zone-id {ZONE_ID} \
  --change-batch file://revert-dns.json
```

**Impact:** Users see old site immediately

#### Option 2: Database Rollback

```bash
# Restore from backup
mysql --default-character-set=utf8mb4 \
  -h {RDS_HOST} \
  -u {DB_USER} \
  -p{DB_PASS} \
  {DB_NAME} < backups/{TENANT}-backup-{DATE}.sql
```

**Impact:** Lose any changes made after backup

#### Option 3: Full Rollback Script

```bash
./scripts/rollback-migration.sh {TENANT_NAME} {BACKUP_DATE}
```

**What it does:**
- Restores database from backup
- Restores files from backup
- Reverts DNS
- Clears caches

---

## Disaster Recovery Plan

### Overview

Multi-region disaster recovery strategy for business continuity in case of regional AWS outages.

### DR Strategy: Multi-Site Active/Passive

**Primary Region:** af-south-1 (Cape Town) - Active
**DR Region:** eu-west-1 (Ireland) - Passive Standby

### Architecture

```
Primary (af-south-1)                      DR (eu-west-1)
├── ECS Fargate (Active)         ←──────  ECS Fargate (Standby - scaled to 0)
├── RDS (Active)                 ←──────  RDS Cross-Region Replica
├── EFS (Active)                 ←──────  EFS with AWS Backup Cross-Region Copy
└── CloudFront (Primary Origin)  ────→    CloudFront (Failover Origin)

Route 53 Health Check
  ↓
Automatic Failover to DR Region
```

### RDS Cross-Region Replication

**Setup:**

```bash
#!/bin/bash
# setup-rds-cross-region-replica.sh

PRIMARY_DB_INSTANCE="wordpress-prod"
DR_REGION="eu-west-1"
AWS_PROFILE="Tebogo-prod"

echo "=========================================================================="
echo "Creating RDS Cross-Region Read Replica for DR"
echo "=========================================================================="

# Create read replica in DR region
aws rds create-db-instance-read-replica \
    --db-instance-identifier "${PRIMARY_DB_INSTANCE}-dr-replica" \
    --source-db-instance-identifier "arn:aws:rds:af-south-1:093646564004:db:${PRIMARY_DB_INSTANCE}" \
    --db-instance-class db.t3.medium \
    --publicly-accessible false \
    --storage-encrypted \
    --kms-key-id "arn:aws:kms:eu-west-1:093646564004:key/dr-key-id" \
    --region "${DR_REGION}" \
    --profile "${AWS_PROFILE}"

echo "✅ RDS read replica creation initiated in ${DR_REGION}"
echo "⏳ Replication will take 30-60 minutes for initial sync"
```

**Monitoring Replica Lag:**

```bash
# Check replication lag
aws rds describe-db-instances \
    --db-instance-identifier "${PRIMARY_DB_INSTANCE}-dr-replica" \
    --region "${DR_REGION}" \
    --profile "${AWS_PROFILE}" \
    --query 'DBInstances[0].[ReplicaLag,DBInstanceStatus]' \
    --output table
```

### EFS Cross-Region Backup

**AWS Backup Plan with Cross-Region Copy:**

```hcl
resource "aws_backup_plan" "wordpress_dr" {
  name = "wordpress-prod-dr-backup-plan"

  rule {
    rule_name         = "daily_backup_with_cross_region_copy"
    target_vault_name = aws_backup_vault.primary.name
    schedule          = "cron(0 2 * * ? *)"  # 2 AM UTC daily

    lifecycle {
      delete_after = 30  # 30 days in primary region
    }

    copy_action {
      destination_vault_arn = aws_backup_vault.dr.arn

      lifecycle {
        delete_after = 30  # 30 days in DR region
      }
    }
  }
}

resource "aws_backup_vault" "primary" {
  name        = "wordpress-prod-primary-vault"
  kms_key_arn = aws_kms_key.primary.arn

  tags = {
    Environment = "prod"
    Region      = "af-south-1"
  }
}

resource "aws_backup_vault" "dr" {
  provider    = aws.dr_region
  name        = "wordpress-prod-dr-vault"
  kms_key_arn = aws_kms_key.dr.arn

  tags = {
    Environment = "prod"
    Region      = "eu-west-1"
    Purpose     = "DR"
  }
}
```

### CloudFront Failover Configuration

**Origin Groups for Automatic Failover:**

```json
{
  "Id": "wordpress-prod-origin-group",
  "FailoverCriteria": {
    "StatusCodes": {
      "Quantity": 3,
      "Items": [500, 502, 503]
    }
  },
  "Members": {
    "Quantity": 2,
    "Items": [
      {
        "OriginId": "primary-alb-af-south-1",
        "Priority": 0
      },
      {
        "OriginId": "dr-alb-eu-west-1",
        "Priority": 1
      }
    ]
  }
}
```

### Route 53 Health Checks

**Setup Health Check for Primary Region:**

```bash
#!/bin/bash
# setup-route53-health-check.sh

DOMAIN="example.com"
PRIMARY_ENDPOINT="https://${DOMAIN}/health-check"
AWS_PROFILE="Tebogo-prod"

# Create health check
HEALTH_CHECK_ID=$(aws route53 create-health-check \
    --caller-reference "$(date +%s)" \
    --health-check-config \
        Type=HTTPS,\
ResourcePath=/health-check,\
        FullyQualifiedDomainName="${DOMAIN}",\
        Port=443,\
        RequestInterval=30,\
        FailureThreshold=3 \
    --profile "${AWS_PROFILE}" \
    --query 'HealthCheck.Id' \
    --output text)

echo "✅ Health check created: ${HEALTH_CHECK_ID}"

# Add CloudWatch alarm for health check
aws cloudwatch put-metric-alarm \
    --alarm-name "route53-health-check-failed-${DOMAIN}" \
    --alarm-description "Route 53 health check failed for ${DOMAIN}" \
    --metric-name HealthCheckStatus \
    --namespace AWS/Route53 \
    --statistic Minimum \
    --period 60 \
    --threshold 1 \
    --comparison-operator LessThanThreshold \
    --evaluation-periods 2 \
    --dimensions Name=HealthCheckId,Value="${HEALTH_CHECK_ID}" \
    --alarm-actions "${SNS_TOPIC_ARN}" \
    --profile "${AWS_PROFILE}"

echo "✅ Health check alarm created"
```

### DR Activation Procedure

#### Automatic Failover (CloudFront Origin Groups)

**Triggers automatically when:**
- Primary ALB returns 500/502/503 errors
- CloudFront switches to DR origin within 30-60 seconds
- No manual intervention required

#### Manual DR Activation (Regional Outage)

**Step 1: Promote RDS Read Replica**

```bash
#!/bin/bash
# activate-dr-rds.sh

DR_DB_INSTANCE="${PRIMARY_DB_INSTANCE}-dr-replica"
DR_REGION="eu-west-1"
AWS_PROFILE="Tebogo-prod"

echo "=========================================================================="
echo "⚠️  ACTIVATING DISASTER RECOVERY - RDS"
echo "=========================================================================="
echo ""
read -p "Type 'ACTIVATE-DR' to proceed: " CONFIRMATION

if [ "$CONFIRMATION" != "ACTIVATE-DR" ]; then
    echo "❌ DR activation aborted"
    exit 1
fi

# Promote read replica to standalone instance
aws rds promote-read-replica \
    --db-instance-identifier "${DR_DB_INSTANCE}" \
    --backup-retention-period 7 \
    --region "${DR_REGION}" \
    --profile "${AWS_PROFILE}"

echo "✅ RDS read replica promotion initiated"
echo "⏳ Promotion takes 5-10 minutes"

# Wait for promotion to complete
aws rds wait db-instance-available \
    --db-instance-identifier "${DR_DB_INSTANCE}" \
    --region "${DR_REGION}" \
    --profile "${AWS_PROFILE}"

echo "✅ RDS promoted to primary in DR region"
```

**Step 2: Restore EFS from Backup**

```bash
#!/bin/bash
# activate-dr-efs.sh

DR_REGION="eu-west-1"
AWS_PROFILE="Tebogo-prod"

# Get latest EFS backup from DR vault
RECOVERY_POINT_ARN=$(aws backup list-recovery-points-by-backup-vault \
    --backup-vault-name "wordpress-prod-dr-vault" \
    --region "${DR_REGION}" \
    --profile "${AWS_PROFILE}" \
    --query 'RecoveryPoints | sort_by(@, &CreationDate) | [-1].RecoveryPointArn' \
    --output text)

echo "Latest backup: ${RECOVERY_POINT_ARN}"

# Restore EFS
aws backup start-restore-job \
    --recovery-point-arn "${RECOVERY_POINT_ARN}" \
    --metadata file-system-id="${DR_EFS_ID}" \
    --iam-role-arn "arn:aws:iam::093646564004:role/wordpress-prod-backup-role" \
    --region "${DR_REGION}" \
    --profile "${AWS_PROFILE}"

echo "✅ EFS restoration initiated in DR region"
```

**Step 3: Scale Up ECS Tasks in DR Region**

```bash
#!/bin/bash
# activate-dr-ecs.sh

DR_REGION="eu-west-1"
DR_CLUSTER="bbws-wordpress-prod-dr"
AWS_PROFILE="Tebogo-prod"

# Scale up ECS services
for tenant in $(cat /tmp/tenant-list.txt); do
    aws ecs update-service \
        --cluster "${DR_CLUSTER}" \
        --service "${tenant}-web" \
        --desired-count 2 \
        --region "${DR_REGION}" \
        --profile "${AWS_PROFILE}"

    echo "✅ Scaled up ${tenant} in DR region"
done

echo "✅ All ECS services scaled up in DR region"
```

**Step 4: Update Route 53 (if needed)**

```bash
# Only if CloudFront failover is not configured
./scripts/update-dns-to-dr-region.sh
```

### DR Testing

**Quarterly DR Drill (Non-Disruptive):**

```bash
#!/bin/bash
# dr-drill.sh

echo "=========================================================================="
echo "DR DRILL - Non-Disruptive Test"
echo "=========================================================================="

# 1. Verify RDS replication lag < 5 seconds
echo "1. Checking RDS replication lag..."
RDS_LAG=$(aws rds describe-db-instances \
    --db-instance-identifier "${PRIMARY_DB_INSTANCE}-dr-replica" \
    --region eu-west-1 \
    --profile Tebogo-prod \
    --query 'DBInstances[0].ReplicaLag' \
    --output text)

if [ "$RDS_LAG" -lt 5 ]; then
    echo "✅ RDS replication lag: ${RDS_LAG} seconds (PASS)"
else
    echo "❌ RDS replication lag: ${RDS_LAG} seconds (FAIL)"
fi

# 2. Verify latest EFS backup exists in DR region
echo "2. Checking EFS backup in DR region..."
LATEST_BACKUP=$(aws backup list-recovery-points-by-backup-vault \
    --backup-vault-name "wordpress-prod-dr-vault" \
    --region eu-west-1 \
    --profile Tebogo-prod \
    --query 'RecoveryPoints | sort_by(@, &CreationDate) | [-1].CreationDate' \
    --output text)

BACKUP_AGE_HOURS=$(( ($(date +%s) - $(date -d "$LATEST_BACKUP" +%s)) / 3600 ))

if [ "$BACKUP_AGE_HOURS" -lt 30 ]; then
    echo "✅ Latest EFS backup age: ${BACKUP_AGE_HOURS} hours (PASS)"
else
    echo "❌ Latest EFS backup age: ${BACKUP_AGE_HOURS} hours (FAIL)"
fi

# 3. Test DR region connectivity
echo "3. Testing DR region endpoint..."
DR_ALB="wordpress-prod-dr-alb.eu-west-1.elb.amazonaws.com"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "https://${DR_ALB}/health-check")

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ DR region health check: HTTP ${HTTP_CODE} (PASS)"
else
    echo "❌ DR region health check: HTTP ${HTTP_CODE} (FAIL)"
fi

# 4. Verify ECS task definitions exist in DR region
echo "4. Checking ECS task definitions in DR region..."
TASK_DEF_COUNT=$(aws ecs list-task-definitions \
    --region eu-west-1 \
    --profile Tebogo-prod \
    --query 'taskDefinitionArns | length(@)')

if [ "$TASK_DEF_COUNT" -gt 0 ]; then
    echo "✅ ECS task definitions in DR: ${TASK_DEF_COUNT} (PASS)"
else
    echo "❌ No ECS task definitions found in DR region (FAIL)"
fi

echo ""
echo "=========================================================================="
echo "DR DRILL COMPLETE"
echo "=========================================================================="
```

### Recovery Time Objective (RTO) & Recovery Point Objective (RPO)

| Metric | Target | Achieved Through |
|--------|--------|------------------|
| **RPO** (Data Loss) | < 5 minutes | RDS cross-region replication (near-realtime) |
| **RTO** (Downtime) | < 30 minutes | CloudFront failover + manual ECS/EFS activation |

**RTO Breakdown:**
- CloudFront failover: 1-2 minutes (automatic)
- RDS promotion: 5-10 minutes
- EFS restore: 10-15 minutes
- ECS scale-up: 2-5 minutes
- **Total: 18-32 minutes**

### DR Runbook

**Critical Contact Information:**
- Primary On-Call: [Name, Phone]
- AWS Support: Enterprise Support Ticket
- Stakeholder Notification: [Email Distribution List]

**Decision Tree:**

```
Is primary region accessible?
  ├─ YES → Use rollback procedures (not DR)
  └─ NO  → Is it a regional AWS outage?
            ├─ YES → Activate full DR (RDS + EFS + ECS)
            └─ NO  → Wait for CloudFront automatic failover
```

---

## Performance Optimization

### Overview

Post-migration performance tuning to achieve < 3 second page load times.

### Performance Metrics

| Metric | Target | Current | Status |
|--------|--------|---------|--------|
| Time to First Byte (TTFB) | < 500ms | __ ms | ⏱️ |
| Largest Contentful Paint (LCP) | < 2.5s | __ s | ⏱️ |
| First Input Delay (FID) | < 100ms | __ ms | ⏱️ |
| Cumulative Layout Shift (CLS) | < 0.1 | __ | ⏱️ |
| Total Page Load Time | < 3s | __ s | ⏱️ |

### CloudFront Optimization

**1. Cache Behavior Configuration:**

```json
{
  "MinTTL": 0,
  "DefaultTTL": 86400,
  "MaxTTL": 31536000,
  "Compress": true,
  "ViewerProtocolPolicy": "redirect-to-https",
  "CachePolicyId": "658327ea-f89d-4fab-a63d-7e88639e58f6",
  "OriginRequestPolicyId": "216adef6-5c7f-47e4-b989-5492eafa07d3"
}
```

**2. Cache Key Optimization:**

```bash
# Create custom cache policy
aws cloudfront create-cache-policy \
    --cache-policy-config '{
      "Name": "WordPress-Optimized-Cache-Policy",
      "MinTTL": 1,
      "DefaultTTL": 86400,
      "MaxTTL": 31536000,
      "ParametersInCacheKeyAndForwardedToOrigin": {
        "EnableAcceptEncodingGzip": true,
        "EnableAcceptEncodingBrotli": true,
        "HeadersConfig": {
          "HeaderBehavior": "whitelist",
          "Headers": {
            "Quantity": 2,
            "Items": ["Host", "CloudFront-Viewer-Country"]
          }
        },
        "CookiesConfig": {
          "CookieBehavior": "whitelist",
          "Cookies": {
            "Quantity": 2,
            "Items": ["wordpress_logged_in_*", "woocommerce_*"]
          }
        },
        "QueryStringsConfig": {
          "QueryStringBehavior": "none"
        }
      }
    }' \
    --profile Tebogo-prod
```

**3. Enable HTTP/2 and HTTP/3:**

```bash
aws cloudfront update-distribution \
    --id "${DISTRIBUTION_ID}" \
    --distribution-config '{
      "HttpVersion": "http2and3",
      "IsIPV6Enabled": true
    }' \
    --profile Tebogo-prod
```

### Database Optimization

**1. Enable RDS Performance Insights:**

```bash
aws rds modify-db-instance \
    --db-instance-identifier wordpress-prod \
    --enable-performance-insights \
    --performance-insights-retention-period 7 \
    --profile Tebogo-prod \
    --region af-south-1
```

**2. Optimize WordPress Database:**

```bash
#!/bin/bash
# optimize-wordpress-database.sh

TENANT_NAME="$1"

echo "=========================================================================="
echo "Optimizing WordPress Database: ${TENANT_NAME}"
echo "=========================================================================="

# Delete transients
wp transient delete --all --allow-root

echo "✅ Deleted expired transients"

# Optimize database tables
wp db optimize --allow-root

echo "✅ Optimized database tables"

# Delete post revisions (keep last 5)
wp post delete $(wp post list --post_type=revision --format=ids --allow-root) --force --allow-root

echo "✅ Cleaned up post revisions"

# Delete spam comments
wp comment delete $(wp comment list --status=spam --format=ids --allow-root) --force --allow-root

echo "✅ Deleted spam comments"

# Delete trashed posts
wp post delete $(wp post list --post_status=trash --format=ids --allow-root) --force --allow-root

echo "✅ Deleted trashed posts"

echo ""
echo "Database optimization complete!"
```

**3. Add Database Indexes:**

```sql
-- Add indexes for common WordPress queries
ALTER TABLE wp_posts ADD INDEX idx_post_type_status_date (post_type, post_status, post_date);
ALTER TABLE wp_postmeta ADD INDEX idx_meta_key_value (meta_key, meta_value(10));
ALTER TABLE wp_options ADD INDEX idx_autoload (autoload);
```

### WordPress Caching

**1. Enable Object Caching with Redis:**

```hcl
# Terraform: ElastiCache Redis for WordPress object cache
resource "aws_elasticache_cluster" "wordpress_redis" {
  cluster_id           = "wordpress-${var.environment}-redis"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = 6379
  security_group_ids   = [aws_security_group.redis.id]
  subnet_group_name    = aws_elasticache_subnet_group.redis.name

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
```

**Install Redis Object Cache Plugin:**

```bash
wp plugin install redis-cache --activate --allow-root
wp redis enable --allow-root
```

**2. Configure Divi Theme Caching:**

Add to `wp-config.php`:
```php
// Enable Divi static CSS generation
define('ET_BUILDER_ALWAYS_GENERATE_STATIC_CSS', true);
```

### Image Optimization

**1. Install Image Optimization Plugin:**

```bash
wp plugin install ewww-image-optimizer --activate --allow-root

# Configure for WebP conversion
wp option update ewww_image_optimizer_webp 1 --allow-root
wp option update ewww_image_optimizer_metadata_remove 1 --allow-root
```

**2. Lazy Load Images:**

Add to `functions.php` or MU-plugin:
```php
add_filter('wp_lazy_loading_enabled', '__return_true');
add_filter('wp_lazy_loading_enabled', function($default, $tag_name) {
    return $tag_name === 'img' || $tag_name === 'iframe' ? true : $default;
}, 10, 2);
```

### PHP OPcache Configuration

Already covered in "PHP Configuration & Resource Limits" section. Ensure:
- `opcache.enable = 1`
- `opcache.memory_consumption = 128`
- `opcache.max_accelerated_files = 10000`

### Performance Testing

**Load Testing with Artillery:**

```yaml
# load-test.yml
config:
  target: "https://example.com"
  phases:
    - duration: 60
      arrivalRate: 10
      name: "Warm up"
    - duration: 120
      arrivalRate: 50
      name: "Sustained load"
    - duration: 60
      arrivalRate: 100
      name: "Peak load"
scenarios:
  - name: "Homepage visit"
    flow:
      - get:
          url: "/"
      - think: 3
      - get:
          url: "/about"
```

```bash
# Run load test
artillery run load-test.yml --output report.json
artillery report report.json --output report.html
```

---

## Cost Tracking & Optimization

### Overview

Monitor and optimize AWS costs across all tenant environments.

### Cost Breakdown (Typical Tenant)

| Service | Monthly Cost | Percentage | Optimization Potential |
|---------|--------------|------------|----------------------|
| ECS Fargate | $50-80 | 35% | Medium (right-sizing) |
| RDS | $60-100 | 40% | Low (Reserved Instances) |
| EFS | $10-20 | 10% | Medium (Lifecycle policies) |
| CloudFront | $5-15 | 5% | Low |
| S3 | $2-5 | 2% | High (Lifecycle policies) |
| Backups | $5-10 | 3% | Medium |
| Other | $5-10 | 5% | Low |
| **Total** | **$137-240** | **100%** | |

### Cost Tagging Strategy

**Required Tags for All Resources:**

```bash
Environment=prod
Tenant=example-tenant
ManagedBy=Terraform
Project=WordPress-Hosting
CostCenter=IT
```

**Apply tags via Terraform:**

```hcl
locals {
  common_tags = {
    Environment = var.environment
    Tenant      = var.tenant_name
    ManagedBy   = "Terraform"
    Project     = "WordPress-Hosting"
    CostCenter  = "IT"
  }
}

resource "aws_ecs_service" "wordpress" {
  # ... configuration ...

  tags = local.common_tags
}
```

### AWS Cost Explorer Setup

**Create Cost Report for WordPress Tenants:**

```bash
#!/bin/bash
# generate-cost-report.sh

ENVIRONMENT="$1"
START_DATE=$(date -d "1 month ago" +%Y-%m-01)
END_DATE=$(date +%Y-%m-%d)

aws ce get-cost-and-usage \
    --time-period Start=${START_DATE},End=${END_DATE} \
    --granularity MONTHLY \
    --metrics "UnblendedCost" \
    --group-by Type=TAG,Key=Tenant \
    --filter '{
      "Tags": {
        "Key": "Environment",
        "Values": ["'${ENVIRONMENT}'"]
      }
    }' \
    --profile Tebogo-prod \
    --output table

echo ""
echo "Detailed breakdown by service:"

aws ce get-cost-and-usage \
    --time-period Start=${START_DATE},End=${END_DATE} \
    --granularity MONTHLY \
    --metrics "UnblendedCost" \
    --group-by Type=DIMENSION,Key=SERVICE \
    --filter '{
      "Tags": {
        "Key": "Environment",
        "Values": ["'${ENVIRONMENT}'"]
      }
    }' \
    --profile Tebogo-prod \
    --output table
```

### Cost Optimization Strategies

#### 1. ECS Fargate Right-Sizing

**Analyze CPU/Memory Usage:**

```bash
#!/bin/bash
# analyze-ecs-utilization.sh

TENANT_NAME="$1"
ENVIRONMENT="${2:-prod}"
SERVICE_NAME="${TENANT_NAME}-web"

# Get average CPU utilization (last 7 days)
AVG_CPU=$(aws cloudwatch get-metric-statistics \
    --namespace AWS/ECS \
    --metric-name CPUUtilization \
    --dimensions Name=ServiceName,Value="${SERVICE_NAME}" Name=ClusterName,Value="bbws-wordpress-${ENVIRONMENT}" \
    --start-time $(date -u -d '7 days ago' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 3600 \
    --statistics Average \
    --profile "Tebogo-${ENVIRONMENT}" \
    --query 'Datapoints[*].Average' \
    --output text | awk '{sum+=$1; count++} END {print sum/count}')

# Get average memory utilization
AVG_MEM=$(aws cloudwatch get-metric-statistics \
    --namespace AWS/ECS \
    --metric-name MemoryUtilization \
    --dimensions Name=ServiceName,Value="${SERVICE_NAME}" Name=ClusterName,Value="bbws-wordpress-${ENVIRONMENT}" \
    --start-time $(date -u -d '7 days ago' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 3600 \
    --statistics Average \
    --profile "Tebogo-${ENVIRONMENT}" \
    --query 'Datapoints[*].Average' \
    --output text | awk '{sum+=$1; count++} END {print sum/count}')

echo "=========================================================================="
echo "ECS Resource Utilization Analysis: ${TENANT_NAME}"
echo "=========================================================================="
echo ""
echo "Average CPU Utilization (7 days): ${AVG_CPU}%"
echo "Average Memory Utilization (7 days): ${AVG_MEM}%"
echo ""

# Recommendations
if (( $(echo "$AVG_CPU < 30" | bc -l) )); then
    echo "💡 RECOMMENDATION: CPU utilization is low. Consider downsizing from 512 to 256 vCPU"
    echo "   Potential savings: ~$25/month per tenant"
fi

if (( $(echo "$AVG_MEM < 40" | bc -l) )); then
    echo "💡 RECOMMENDATION: Memory utilization is low. Consider downsizing from 1024MB to 512MB"
    echo "   Potential savings: ~$15/month per tenant"
fi
```

#### 2. RDS Reserved Instances

**Calculate Savings:**

```bash
# Get RDS pricing for On-Demand vs Reserved (1-year, no upfront)
# On-Demand db.t3.medium: ~$0.068/hour = $50/month
# Reserved (1-year): ~$0.043/hour = $32/month
# Savings: $18/month (36% discount)

echo "RDS Reserved Instance Savings Calculator"
echo "========================================="
echo ""
echo "On-Demand Cost (db.t3.medium): $50/month"
echo "Reserved Cost (1-year, no upfront): $32/month"
echo "Savings: $18/month per instance"
echo ""
echo "For 40 tenants: $720/month savings ($8,640/year)"
```

**Purchase Reserved Instances:**

```bash
aws rds purchase-reserved-db-instances-offering \
    --reserved-db-instances-offering-id <offering-id> \
    --reserved-db-instance-id wordpress-prod-reserved-1 \
    --db-instance-count 5 \
    --profile Tebogo-prod
```

#### 3. S3 Lifecycle Policies

```hcl
resource "aws_s3_bucket_lifecycle_configuration" "wordpress_backups" {
  bucket = aws_s3_bucket.backups.id

  rule {
    id     = "transition-to-glacier"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "GLACIER"
    }

    transition {
      days          = 90
      storage_class = "DEEP_ARCHIVE"
    }

    expiration {
      days = 365
    }
  }
}
```

**Savings:** Reduce storage costs from $0.023/GB to $0.004/GB (83% savings)

#### 4. EFS Lifecycle Management

```bash
aws efs put-lifecycle-configuration \
    --file-system-id "${EFS_ID}" \
    --lifecycle-policies \
        TransitionToIA=AFTER_30_DAYS,\
        TransitionToPrimaryStorageClass=AFTER_1_ACCESS \
    --profile Tebogo-prod
```

**Savings:** Files not accessed for 30 days move to Infrequent Access (IA) storage (92% cheaper)

### Cost Alerts

**Set Up Budget Alerts:**

```bash
aws budgets create-budget \
    --account-id 093646564004 \
    --budget '{
      "BudgetName": "WordPress-Prod-Monthly-Budget",
      "BudgetLimit": {
        "Amount": "5000",
        "Unit": "USD"
      },
      "TimeUnit": "MONTHLY",
      "BudgetType": "COST",
      "CostFilters": {
        "TagKeyValue": ["Environment$prod", "Project$WordPress-Hosting"]
      }
    }' \
    --notifications-with-subscribers '[{
      "Notification": {
        "NotificationType": "ACTUAL",
        "ComparisonOperator": "GREATER_THAN",
        "Threshold": 80,
        "ThresholdType": "PERCENTAGE"
      },
      "Subscribers": [{
        "SubscriptionType": "EMAIL",
        "Address": "billing@bigbeard.co.za"
      }]
    }]' \
    --profile Tebogo-prod
```

---

## WordPress Multisite Considerations

### Overview

Special considerations for WordPress Multisite (network) migrations.

### Detection

**Check if source site is multisite:**

```bash
ssh user@source-host "cd /var/www/html && wp core is-installed --network --allow-root"
```

If exit code is 0, site is multisite.

### Multisite Architecture Differences

| Aspect | Single Site | Multisite |
|--------|-------------|-----------|
| **Database Tables** | 12 core tables | 12 core + N×9 per sub-site |
| **Uploads Directory** | `/wp-content/uploads/` | `/wp-content/uploads/sites/{site-id}/` |
| **Plugins** | Per-site activation | Network-wide + per-site |
| **Themes** | Per-site | Network-enabled, per-site activation |
| **Users** | Site-specific | Network-wide (shared) |

### Migration Adjustments for Multisite

#### 1. Database Export

**Export all sub-site tables:**

```bash
# Get list of all multisite tables
TABLES=$(ssh user@source-host "cd /var/www/html && wp db tables --network --allow-root --format=csv")

# Export with all multisite tables
mysqldump \
    --default-character-set=utf8mb4 \
    --single-transaction \
    --routines \
    --triggers \
    $TABLES \
    -h ${SOURCE_DB_HOST} \
    -u ${SOURCE_DB_USER} \
    -p${SOURCE_DB_PASS} \
    ${SOURCE_DB_NAME} | gzip > multisite-backup.sql.gz
```

#### 2. URL Replacement

**Update URLs for ALL sub-sites:**

```bash
#!/bin/bash
# multisite-url-replacement.sh

TENANT_NAME="$1"
OLD_DOMAIN="$2"
NEW_DOMAIN="${TENANT_NAME}.wpdev.kimmyai.io"

# Get list of all sub-sites
SITES=$(wp site list --field=url --allow-root)

for OLD_SITE_URL in $SITES; do
    # Extract sub-site path
    SITE_PATH=$(echo "$OLD_SITE_URL" | sed "s|${OLD_DOMAIN}||")
    NEW_SITE_URL="${NEW_DOMAIN}${SITE_PATH}"

    echo "Updating: ${OLD_SITE_URL} → ${NEW_SITE_URL}"

    wp search-replace "${OLD_SITE_URL}" "${NEW_SITE_URL}" \
        --network \
        --all-tables \
        --allow-root

    echo "✅ Updated ${OLD_SITE_URL}"
done

echo ""
echo "✅ All multisite URLs updated"
```

#### 3. Uploads Directory Structure

**Preserve multisite uploads structure:**

```bash
# Multisite uploads structure:
# /wp-content/uploads/sites/2/2024/01/image.jpg
# /wp-content/uploads/sites/3/2024/01/image.jpg

# Ensure structure is maintained during EFS upload
rsync -avz --progress \
    /tmp/wp-content/uploads/ \
    /efs-mount/wp-content/uploads/

echo "✅ Multisite uploads directory structure preserved"
```

#### 4. Domain Mapping

**If multisite uses domain mapping plugin:**

```bash
# Update domain mapping table
wp db query "UPDATE wp_domain_mapping SET domain = REPLACE(domain, 'old-domain.com', 'new-domain.com')" --allow-root

# List all mapped domains
wp db query "SELECT * FROM wp_domain_mapping" --allow-root
```

### Multisite-Specific Testing

**Test checklist for each sub-site:**

- [ ] Sub-site homepage loads
- [ ] Sub-site admin accessible
- [ ] Uploads working (test upload in each sub-site)
- [ ] Plugins activated correctly
- [ ] Theme activates correctly
- [ ] Users can log in
- [ ] Sub-site specific settings preserved

### Multisite Performance Considerations

**1. Shared Object Cache:**

Multisite benefits more from Redis object cache due to shared user table:

```php
// wp-config.php
define('WP_CACHE_KEY_SALT', 'multisite_' . $_SERVER['HTTP_HOST']);
```

**2. Separate EFS Access Points:**

For large multisite networks (> 10 sub-sites), consider separate EFS access points per sub-site:

```hcl
resource "aws_efs_access_point" "subsite" {
  for_each = var.subsites

  file_system_id = aws_efs_file_system.wordpress.id

  posix_user {
    gid = 33  # www-data
    uid = 33
  }

  root_directory {
    path = "/subsites/${each.value}"
    creation_info {
      owner_gid   = 33
      owner_uid   = 33
      permissions = "755"
    }
  }

  tags = {
    Name    = "subsite-${each.value}"
    Subsite = each.value
  }
}
```

---

## Troubleshooting Guide

### Issue: Mixed Content Warnings

**Symptoms:** HTTP resources on HTTPS page, broken CSS/images

**Solution:**
```bash
# Verify force-https.php MU-plugin is active
ls /var/www/html/wp-content/mu-plugins/bbws-platform/force-https.php

# Check wp-config.php has HTTPS forcing
grep "HTTPS" /var/www/html/wp-config.php

# Run validation
./validate-migration.sh {URL}
```

### Issue: UTF-8 Encoding Artifacts

**Symptoms:** Strange characters (Â, â€™, â€œ)

**Solution:**
```bash
# Apply encoding fix
wp db query < templates/fix-encoding.sql --allow-root

# Clear caches
wp cache flush --allow-root
rm -rf /var/www/html/wp-content/et-cache/*

# Invalidate CloudFront
aws cloudfront create-invalidation \
  --distribution-id {DISTRIBUTION_ID} \
  --paths "/*"
```

### Issue: PHP Warnings Visible

**Symptoms:** PHP deprecation warnings on page

**Solution:**
```bash
# Verify error suppression in wp-config.php
head -n 5 /var/www/html/wp-config.php

# Should show:
# error_reporting(E_ALL & ~E_DEPRECATED & ~E_STRICT);
# ini_set('display_errors', '0');
```

### Issue: Emails Going to Real Addresses

**Symptoms:** Customer receives test emails

**Solution:**
```bash
# Verify WP_ENV is set
wp eval "echo defined('WP_ENV') ? WP_ENV : 'not set';" --allow-root

# Should return: dev or sit

# Verify test-email-redirect.php exists
ls /var/www/html/wp-content/mu-plugins/bbws-platform/test-email-redirect.php

# Check MU-plugins are loading
wp plugin list --must-use --allow-root
```

### Issue: Environment Indicator Not Showing

**Symptoms:** No visual banner on site

**Solution:**
```bash
# Verify environment-indicator.php exists
ls /var/www/html/wp-content/mu-plugins/bbws-platform/environment-indicator.php

# Check WP_ENV constant
wp eval "echo defined('WP_ENV') ? WP_ENV : 'not set';" --allow-root

# Clear caches
wp cache flush --allow-root
```

---

## Additional Troubleshooting (From Manufacturing Migration)

### Issue: S3 Bucket Access Denied (403 Forbidden)

**Symptoms:** Bastion host cannot download migration files from S3

**Solution:**
```bash
# Check if bastion role is in bucket policy
aws s3api get-bucket-policy --bucket wordpress-migration-temp-20250903 --query Policy --output text | jq .

# Add bastion role to bucket policy if missing
# See Pre-Flight Checklist section for policy JSON
```

### Issue: SSM Command Fails with Complex SQL

**Symptoms:** SSM Run Command returns syntax errors for SQL with quotes

**Solution:**
```bash
# Use file-based approach instead of inline SQL
# 1. Upload SQL to S3
aws s3 cp query.sql s3://bucket/temp/

# 2. Execute from bastion file system
aws ssm send-command \
  --instance-ids "$BASTION_ID" \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=["aws s3 cp s3://bucket/temp/query.sql /tmp/ && mysql -h HOST -u USER -pPASS DB < /tmp/query.sql"]'
```

### Issue: ECS Exec "SessionManagerPlugin Not Found"

**Symptoms:** Cannot execute commands in ECS container

**Solution:**
```bash
# Install Session Manager plugin (macOS)
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/mac/sessionmanager-bundle.zip" -o "sessionmanager-bundle.zip"
unzip sessionmanager-bundle.zip
sudo ./sessionmanager-bundle/install -i /usr/local/sessionmanagerplugin -b /usr/local/bin/session-manager-plugin

# Alternative: Use CloudWatch Logs
aws logs tail /ecs/dev-tenant-task --follow --since 5m
```

### Issue: EFS Files Permission Denied

**Symptoms:** WordPress cannot read wp-content files, pages fail to load

**Solution:**
```bash
# Mount EFS on bastion
sudo mount -t efs -o tls,accesspoint=fsap-XXXXX fs-XXXXX:/ /mnt/efs

# Fix ownership (33:33 = www-data in WordPress container)
sudo chown -R 33:33 /mnt/efs/

# Fix permissions
sudo find /mnt/efs -type d -exec chmod 755 {} \;
sudo find /mnt/efs -type f -exec chmod 644 {} \;
```

### Issue: Homepage Returns Empty (0 Bytes)

**Symptoms:** HTTP 200 but no content, REST API works, static files return 404

**Root Cause:** EFS not properly mounted after container startup

**Solution:**
```bash
# Force ECS service redeployment to refresh EFS mount
aws ecs update-service \
  --cluster dev-cluster \
  --service dev-tenant-service \
  --force-new-deployment

# Wait for deployment and verify
curl -s -o /dev/null -w "%{http_code}:%{size_download}" "https://tenant.wpdev.kimmyai.io/"
# Expected: 200:XXXXX (non-zero size)
```

### Issue: Elementor Page Shows No Content

**Symptoms:** Page loads but Elementor content missing, Theme Builder templates not rendering

**Solution:**
```sql
-- Check Elementor library templates
SELECT ID, post_title, post_status FROM wp_posts WHERE post_type = 'elementor_library';

-- Publish any draft templates
UPDATE wp_posts SET post_status = 'publish' WHERE post_type = 'elementor_library' AND post_status = 'draft';

-- Clear Elementor cache
DELETE FROM wp_options WHERE option_name LIKE '%elementor%cache%';
```

### Issue: Old Domain in Canonical URLs / SEO Meta

**Symptoms:** Yoast shows old domain in canonical tags

**Solution:**
```sql
-- Update Yoast indexable table
UPDATE wp_yoast_indexable
SET permalink = REPLACE(permalink, 'old-domain.com', 'new-domain.com')
WHERE permalink LIKE '%old-domain.com%';

-- Update Yoast SEO links
UPDATE wp_yoast_seo_links
SET url = REPLACE(url, 'old-domain.com', 'new-domain.com')
WHERE url LIKE '%old-domain.com%';

-- Verify
SELECT permalink FROM wp_yoast_indexable WHERE object_type = 'post' LIMIT 5;
```

### Issue: CloudFront Basic Auth Blocking Site Access

**Symptoms:** Site requires authentication even for testing

**Solution:**
```bash
# Get current CloudFront function
aws cloudfront get-function \
  --name wpdev-basic-auth \
  --stage DEVELOPMENT \
  --region us-east-1 \
  --query 'FunctionCode' \
  --output text | base64 -d > /tmp/cf-function.js

# Edit to add tenant to noAuthTenants array
# var noAuthTenants = ['tenant.wpdev.kimmyai.io'];

# Update and publish function
aws cloudfront update-function --name wpdev-basic-auth --region us-east-1 \
  --function-config '{"Comment":"Updated","Runtime":"cloudfront-js-2.0"}' \
  --function-code fileb:///tmp/cf-function.js \
  --if-match "ETAG_HERE"

aws cloudfront publish-function --name wpdev-basic-auth --region us-east-1 \
  --if-match "NEW_ETAG"
```

### Issue: WordPress Admin Password Unknown

**Symptoms:** Cannot log into wp-admin after migration

**Solution:**
```sql
-- Get user info
SELECT ID, user_login, user_email FROM wp_users;

-- Reset password (MD5 for simplicity - user should change after login)
UPDATE wp_users SET user_pass = MD5('TempPassword123!') WHERE user_login = 'admin';

-- Or create migration admin user
INSERT INTO wp_users (user_login, user_pass, user_email, user_registered, display_name)
VALUES ('migration_admin', MD5('MigrationTemp!'), 'admin@example.com', NOW(), 'Migration Admin');

-- Grant admin role
INSERT INTO wp_usermeta (user_id, meta_key, meta_value)
VALUES (LAST_INSERT_ID(), 'wp_capabilities', 'a:1:{s:13:"administrator";b:1;}');
```

### Issue: reCAPTCHA Validation Failing on Forms

**Symptoms:** "reCAPTCHA V3 validation failed" error on form submission

**Root Cause:** reCAPTCHA keys registered for old domain

**Solution:**
```sql
-- Clear Elementor Pro reCAPTCHA keys
UPDATE wp_options SET option_value = ''
WHERE option_name IN (
    'elementor_pro_recaptcha_v3_site_key',
    'elementor_pro_recaptcha_v3_secret_key',
    'elementor_pro_recaptcha_site_key',
    'elementor_pro_recaptcha_secret_key'
);

-- Clear transient cache
DELETE FROM wp_options WHERE option_name LIKE '%_transient_%';

-- For PROD: Register new keys at https://www.google.com/recaptcha/admin
-- and add production domain
```

### Issue: HTTPS Redirect Loop (Site Returns 301 Forever)

**Symptoms:**
- Browser shows "too many redirects" error
- curl returns infinite 301 redirects
- Site accessible via curl with `-L` but never loads in browser

**Root Cause:** WordPress detects HTTP from ALB and redirects to HTTPS, CloudFront follows redirect and sends HTTP again → infinite loop

**Investigation:**
```bash
# Test for redirect loop
curl -sI "https://tenant.wpdev.kimmyai.io/" | head -10
# If you see "Location: https://tenant.wpdev.kimmyai.io/" - redirect loop confirmed

# Check number of redirects
curl -s -o /dev/null -w "%{redirect_url}\n" "https://tenant.wpdev.kimmyai.io/"
# If redirect URL is same as request URL - loop confirmed
```

**Solution 1: Fix via ECS Task Definition (Preferred)**
```bash
# Update WORDPRESS_CONFIG_EXTRA in task definition
# MUST include: $_SERVER['HTTPS'] = 'on';

# 1. Get current task definition
aws ecs describe-task-definition \
  --task-definition dev-tenant \
  --query 'taskDefinition' > /tmp/current-task.json

# 2. Edit WORDPRESS_CONFIG_EXTRA to include HTTPS fix
# Value should be:
# "$_SERVER['HTTPS'] = 'on';\ndefine('FORCE_SSL_ADMIN', false);\ndefine('WP_HOME', 'https://tenant.wpdev.kimmyai.io');\ndefine('WP_SITEURL', 'https://tenant.wpdev.kimmyai.io');\ndefine('WP_ENVIRONMENT_TYPE', 'development');"

# 3. Register new revision and update service
aws ecs register-task-definition --cli-input-json file:///tmp/updated-task.json
aws ecs update-service --cluster dev-cluster --service dev-tenant-service --task-definition dev-tenant
```

**Solution 2: Check for Problematic Plugins**
```sql
-- Check if Really Simple SSL or similar is active
SELECT option_value FROM wp_options WHERE option_name = 'active_plugins';

-- Look for:
-- really-simple-ssl
-- wordpress-https
-- ssl-insecure-content-fixer

-- Disable Really Simple SSL
UPDATE wp_options
SET option_value = ''
WHERE option_name = 'rlrsssl_options';

-- You may also need to manually edit active_plugins serialized array
-- Or deactivate via wp-admin after fixing the redirect loop
```

**Solution 3: Force ECS Redeployment**
```bash
# Sometimes the fix requires a clean redeployment
aws ecs update-service \
  --cluster dev-cluster \
  --service dev-tenant-service \
  --force-new-deployment

# Wait for new task to be running
aws ecs wait services-stable \
  --cluster dev-cluster \
  --services dev-tenant-service
```

**Verification:**
```bash
# Should return 200, not 301
curl -s -o /dev/null -w "%{http_code}" "https://tenant.wpdev.kimmyai.io/"

# Should show no Location header
curl -sI "https://tenant.wpdev.kimmyai.io/" | grep -i location
# Expected: No output
```

### Issue: Target Group Shows Unhealthy Targets

**Symptoms:**
- Site inaccessible (502/503 errors)
- ECS task running but target group shows "unhealthy"
- CloudWatch logs show container started successfully

**Root Cause:** Health check misconfiguration (wrong path, wrong matcher, wrong protocol)

**Investigation:**
```bash
# Check target health
TG_ARN=$(aws elbv2 describe-target-groups \
  --names "dev-tenant-tg" \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text)

aws elbv2 describe-target-health --target-group-arn "$TG_ARN"
# Look for "Reason" field in unhealthy targets

# Check health check configuration
aws elbv2 describe-target-groups \
  --target-group-arns "$TG_ARN" \
  --query 'TargetGroups[0].{Path:HealthCheckPath,Protocol:HealthCheckProtocol,Matcher:Matcher.HttpCode}'
```

**Common Problems & Solutions:**

| Reason | Problem | Solution |
|--------|---------|----------|
| `Target.ResponseCodeMismatch` | Health check expects 200, got 301/302 | Change matcher to `200-302` |
| `Target.ResponseCodeMismatch` | Health check path returns 400/404 | Change path to `/` |
| `Target.Timeout` | Container not responding | Check ECS task logs, verify port 80 |
| `Target.FailedHealthChecks` | Multiple failures | Check container health, restart task |

**Solution:**
```bash
# Fix health check configuration
aws elbv2 modify-target-group \
  --target-group-arn "$TG_ARN" \
  --health-check-path "/" \
  --health-check-protocol HTTP \
  --matcher HttpCode=200-302

# Wait for health check to pass
sleep 60

# Verify target is now healthy
aws elbv2 describe-target-health --target-group-arn "$TG_ARN"
```

### Issue: ECS Task Fails with "ResourceInitializationError"

**Symptoms:**
- ECS task starts but immediately fails
- Error: "ResourceInitializationError: failed to invoke EFS utils commands"
- Task never reaches RUNNING state

**Root Cause:** Missing IAM permissions for EFS access point

**Investigation:**
```bash
# Check task failure reason
aws ecs describe-tasks \
  --cluster dev-cluster \
  --tasks $(aws ecs list-tasks --cluster dev-cluster --service-name dev-tenant-service --query 'taskArns[0]' --output text) \
  --query 'tasks[0].stoppedReason'

# Check if IAM inline policy exists
aws iam list-role-policies --role-name dev-ecs-task-role
```

**Solution:**
```bash
# Add inline policy for EFS access
EFS_AP_ARN="arn:aws:elasticfilesystem:eu-west-1:536580886816:access-point/fsap-XXXXX"

aws iam put-role-policy \
  --role-name dev-ecs-task-role \
  --policy-name "dev-ecs-efs-access-tenant" \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Action": [
        "elasticfilesystem:ClientMount",
        "elasticfilesystem:ClientWrite",
        "elasticfilesystem:ClientRootAccess"
      ],
      "Resource": "'"${EFS_AP_ARN}"'"
    }]
  }'

# Force new deployment
aws ecs update-service \
  --cluster dev-cluster \
  --service dev-tenant-service \
  --force-new-deployment
```

### Issue: ECS Task Fails with "AccessDeniedException" for Secrets

**Symptoms:**
- ECS task fails during startup
- Error mentions Secrets Manager access denied
- Database connection never established

**Root Cause:** Missing resource-based policy on Secrets Manager secret

**Investigation:**
```bash
# Check if secret exists
aws secretsmanager describe-secret --secret-id dev-tenant-db-credentials

# Check resource policy
aws secretsmanager get-resource-policy --secret-id dev-tenant-db-credentials
# If empty or missing execution role: problem confirmed
```

**Solution:**
```bash
# Add resource-based policy
aws secretsmanager put-resource-policy \
  --secret-id dev-tenant-db-credentials \
  --resource-policy '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::536580886816:role/dev-ecs-task-execution-role"
      },
      "Action": "secretsmanager:GetSecretValue",
      "Resource": "*"
    }]
  }'

# Force new deployment
aws ecs update-service \
  --cluster dev-cluster \
  --service dev-tenant-service \
  --force-new-deployment
```

---

## Success Criteria

### DEV Environment
- ✅ Site accessible via HTTPS
- ✅ HTTP 200 response
- ✅ Zero mixed content
- ✅ Zero encoding issues
- ✅ No PHP errors
- ✅ Load time < 3 seconds
- ✅ Emails redirect to test address
- ✅ Tracking scripts mocked
- ✅ Environment indicator visible

### SIT Environment
- ✅ All DEV criteria met
- ✅ UAT completed
- ✅ Stakeholder sign-off obtained
- ✅ No regressions from DEV

### Production
- ✅ All SIT criteria met
- ✅ Real emails working
- ✅ Real tracking working
- ✅ No environment indicator
- ✅ DNS pointing to new infrastructure
- ✅ 24-hour monitoring clean

---

## Resources

### Documentation
- Integration Analysis: `/2_bbws_docs/migrations/aupairhive_integration_analysis.md`
- Retrospective: `/2_bbws_docs/migrations/aupairhive_migration_retrospective.md`
- Encoding Fix Guide: `/2_bbws_docs/migrations/aupairhive_encoding_fix.md`

### Scripts
- Migration: `/2_bbws_agents/tenant/scripts/migrate-wordpress-tenant.sh`
- Validation: `/2_bbws_agents/tenant/scripts/validate-migration.sh`
- MU-Plugin Deployment: `/2_bbws_agents/tenant/scripts/deploy-mu-plugins.sh`

### Templates
- MU-Plugins: `/2_bbws_agents/tenant/templates/mu-plugins/`
  - `force-https.php`
  - `test-email-redirect.php`
  - `environment-indicator.php`
  - `mock-tracking.php`
- SQL Fixes: `/2_bbws_agents/tenant/templates/fix-encoding.sql`

---

## Continuous Improvement

### After Each Migration

1. **Document Issues** - Add to troubleshooting guide
2. **Update Scripts** - Incorporate fixes into automation
3. **Measure Time** - Track actual vs. estimated time
4. **Collect Feedback** - From testers and stakeholders
5. **Iterate** - Improve process for next migration

### Metrics to Track

| Metric | Target | Actual |
|--------|--------|--------|
| Total Migration Time | 60 minutes | __ minutes |
| Validation Pass Rate | 100% | __% |
| Post-Migration Issues | 0 | __ issues |
| Rollback Needed | No | Yes/No |

---

## Migration Performance & Workflow Optimization

### Overview

This section addresses common workflow bottlenecks and performance issues observed during multi-tenant migrations (GravitonWealth, Manufacturing-Websites, etc.).

### Issue: EFS Upload Takes Too Long

**Symptoms:**
- wp-content sync to EFS takes 30+ minutes for large sites
- SSH/SSM session timeouts during upload
- Migration process stalls waiting for file transfer

**Root Cause:** Large media libraries (1GB+), slow sequential rsync, or EFS throughput mode limitations

**Solutions:**

**1. Use Parallel Upload with S3 Transfer Acceleration:**
```bash
# Instead of direct rsync to EFS, use S3 as staging
# Enable transfer acceleration on migration bucket
aws s3api put-bucket-accelerate-configuration \
  --bucket wordpress-migration-temp-20250903 \
  --accelerate-configuration Status=Enabled

# Upload files with acceleration and parallel threads
aws s3 cp ./wp-content s3://wordpress-migration-temp-20250903.s3-accelerate.amazonaws.com/${TENANT}/ \
  --recursive \
  --only-show-errors \
  --no-progress

# Then sync from S3 to EFS (faster within AWS)
aws s3 sync s3://wordpress-migration-temp-20250903/${TENANT}/ /mnt/efs/${TENANT}/wp-content/ \
  --only-show-errors
```

**2. Use EFS Provisioned Throughput for Large Migrations:**
```bash
# Temporarily increase EFS throughput during migration
aws efs update-file-system \
  --file-system-id fs-0e1cccd971a35db46 \
  --throughput-mode provisioned \
  --provisioned-throughput-in-mibps 100

# After migration, switch back to bursting
aws efs update-file-system \
  --file-system-id fs-0e1cccd971a35db46 \
  --throughput-mode bursting
```

**3. Compress and Transfer Archive:**
```bash
# Create tarball locally (faster than many small files)
tar -czf /tmp/${TENANT}-wp-content.tar.gz -C /path/to/source wp-content/

# Upload single file to S3
aws s3 cp /tmp/${TENANT}-wp-content.tar.gz s3://wordpress-migration-temp-20250903/${TENANT}/

# Extract on bastion directly to EFS
aws ssm send-command \
  --instance-ids "$BASTION_ID" \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=[
    "aws s3 cp s3://wordpress-migration-temp-20250903/'"${TENANT}"'/'"${TENANT}"'-wp-content.tar.gz /tmp/",
    "tar -xzf /tmp/'"${TENANT}"'-wp-content.tar.gz -C /mnt/efs/'"${TENANT}"'/",
    "chown -R 33:33 /mnt/efs/'"${TENANT}"'/wp-content"
  ]'
```

**4. Use DataSync for Very Large Sites (5GB+):**
```bash
# Create DataSync task for S3 to EFS transfer
aws datasync create-task \
  --source-location-arn "arn:aws:datasync:eu-west-1:536580886816:location/loc-s3bucket" \
  --destination-location-arn "arn:aws:datasync:eu-west-1:536580886816:location/loc-efs" \
  --name "${TENANT}-migration" \
  --options '{
    "VerifyMode": "ONLY_FILES_TRANSFERRED",
    "OverwriteMode": "ALWAYS",
    "Atime": "NONE",
    "Mtime": "PRESERVE",
    "Uid": "INT_VALUE",
    "Gid": "INT_VALUE",
    "PreserveDeletedFiles": "REMOVE"
  }'
```

### Issue: Too Many Approval Steps Slowing Migration

**Symptoms:**
- Migration requires 10+ manual approval points
- Most approvals are "yes" with no meaningful review
- Migration time extended by approval wait times

**Root Cause:** Conservative workflow designed for initial migrations, not optimized for repetitive tasks

**Solutions:**

**1. Use Batch Approval Mode:**
```bash
# Set environment variable to skip individual confirmations
export MIGRATION_AUTO_APPROVE=true
export MIGRATION_BATCH_MODE=true

# Script checks this variable and skips prompts for known-safe operations:
# - Database backup creation
# - S3 file copy
# - EFS mount operations
# - URL replacement SQL
# - CloudFront invalidation
```

**2. Create Pre-Approved Migration Profile:**
```yaml
# migration-profile-standard.yaml
profile_name: standard-wordpress
auto_approve:
  - database_backup
  - s3_copy
  - efs_mount
  - url_replacement
  - cache_invalidation
  - ecs_deployment
require_approval:
  - database_import  # One-time approval for bulk DB changes
  - dns_cutover      # Production DNS changes always require approval
  - production_go_live
```

**3. Consolidated Approval Points:**
```markdown
## Single-Approval Migration Workflow

Instead of approving each step, consolidate to:

1. **Pre-Flight Approval** - Review plan, approve all infrastructure changes
2. **Database Import Approval** - Confirm source database is correct
3. **Go-Live Approval** - Final confirmation before DNS cutover

All intermediate steps (file copy, cache clear, URL replace) run automatically.
```

### Issue: SSM/SSH Connection Drops During Long Operations

**Symptoms:**
- "Session is closed" or "EOF" errors mid-operation
- Operations complete but output lost
- Must restart operations from scratch

**Root Cause:**
- Default SSM session timeout (20 minutes)
- Network instability
- Client-side idle detection

**Solutions:**

**1. Increase SSM Session Timeout:**
```bash
# Set in SSM Session Manager preferences (AWS Console)
# Or via CLI:
aws ssm update-document \
  --name "SSM-SessionManagerRunShell" \
  --document-version '$LATEST' \
  --content '{
    "schemaVersion": "1.0",
    "description": "Custom Session Manager settings",
    "sessionType": "Standard_Stream",
    "inputs": {
      "idleSessionTimeout": "60",
      "maxSessionDuration": "120"
    }
  }'
```

**2. Use nohup for Long-Running Operations:**
```bash
# Run migration script with nohup to survive disconnections
aws ssm send-command \
  --instance-ids "$BASTION_ID" \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=[
    "nohup /usr/local/bin/migration-helpers/migrate-tenant.sh '"${TENANT}"' > /tmp/migration-'"${TENANT}"'.log 2>&1 &",
    "echo \"Migration started in background. Check logs at /tmp/migration-'"${TENANT}"'.log\""
  ]'

# Check progress later
aws ssm send-command \
  --instance-ids "$BASTION_ID" \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=["tail -100 /tmp/migration-'"${TENANT}"'.log"]'
```

**3. Use Screen/Tmux for Interactive Sessions:**
```bash
# Connect to bastion with screen
aws ssm start-session --target "$BASTION_ID"

# Inside session, start screen
screen -S migration

# Run your commands...
# If disconnected, reconnect and resume:
screen -r migration
```

**4. Run Operations via SSM Run Command (Not Sessions):**
```bash
# For non-interactive operations, use Run Command instead of interactive sessions
# Run Command is more reliable for long-running scripts

aws ssm send-command \
  --instance-ids "$BASTION_ID" \
  --document-name "AWS-RunShellScript" \
  --timeout-seconds 3600 \  # 1 hour timeout
  --parameters 'commands=[
    "/usr/local/bin/migration-helpers/full-migration.sh '"${TENANT}"'"
  ]' \
  --cloud-watch-output-config '{
    "CloudWatchLogGroupName": "/migration/'"${TENANT}"'",
    "CloudWatchOutputEnabled": true
  }'
```

### Issue: Old Xneelo Credentials in wp-config.php

**Symptoms:**
- wp-config.php contains old database host (e.g., `mysql.xneelo.co.za`)
- Old database credentials present
- Site fails to connect to database after migration

**Root Cause:** wp-config.php was not automatically generated by ECS, or old file copied to EFS

**Solutions:**

**1. Use WORDPRESS_CONFIG_EXTRA (Recommended):**
```json
// ECS Task Definition - environment variables override wp-config.php
{
  "name": "WORDPRESS_DB_HOST",
  "value": "dev-mysql.c9ko42mci6mt.eu-west-1.rds.amazonaws.com"
},
{
  "name": "WORDPRESS_DB_NAME",
  "value": "tenant_${TENANT}_db"
}
// These take precedence over wp-config.php hardcoded values
```

**2. Remove wp-config.php from EFS:**
```bash
# Let the WordPress container generate wp-config.php from environment variables
# Delete any copied wp-config.php from EFS

aws ssm send-command \
  --instance-ids "$BASTION_ID" \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=[
    "rm -f /mnt/efs/'"${TENANT}"'/wp-content/../wp-config.php",
    "echo \"wp-config.php removed - container will generate from env vars\""
  ]'
```

**3. Pre-Migration wp-config.php Sanitization:**
```bash
# Before copying files, check for hardcoded credentials
grep -E "(DB_HOST|DB_USER|DB_PASSWORD|DB_NAME)" /path/to/source/wp-config.php

# If found, DO NOT copy wp-config.php to EFS
# The container will create one from environment variables
```

### Issue: PHP Debug Notices Visible on Site

**Symptoms:**
- PHP deprecated function notices visible
- PHP strict standards warnings displayed
- Site appears unprofessional during testing

**Root Cause:** WORDPRESS_DEBUG enabled or error reporting not suppressed

**Solutions:**

**1. Disable Debug in Task Definition:**
```json
{
  "name": "WORDPRESS_DEBUG",
  "value": "0"
},
{
  "name": "WORDPRESS_CONFIG_EXTRA",
  "value": "$_SERVER['HTTPS'] = 'on';\ndefine('WP_DEBUG', false);\ndefine('WP_DEBUG_LOG', false);\ndefine('WP_DEBUG_DISPLAY', false);\n@ini_set('display_errors', 0);\n"
}
```

**2. Add Error Suppression MU-Plugin:**
```php
<?php
/**
 * Plugin Name: Error Display Suppression
 * Description: Suppress PHP errors/warnings on frontend
 */

// Only suppress display, still log to file
if (!defined('WP_DEBUG') || !WP_DEBUG) {
    @ini_set('display_errors', 0);
    error_reporting(E_ALL & ~E_DEPRECATED & ~E_STRICT & ~E_NOTICE);
}

// Suppress specific deprecation notices from older plugins
add_action('deprecated_function_run', '__return_false', 10, 3);
add_action('deprecated_argument_run', '__return_false', 10, 3);
```

### Issue: PHP Warnings from Incompatible Plugins

**Symptoms:**
- Warnings about deprecated functions
- "Creation of dynamic property" notices
- Return type declaration warnings

**Root Cause:** Plugins not yet updated for PHP 8.2/WordPress 6.7 compatibility

**Solutions:**

**1. Identify Problematic Plugins:**
```bash
# Check CloudWatch logs for plugin-specific errors
aws logs filter-log-events \
  --log-group-name "/ecs/dev" \
  --log-stream-name-prefix "${TENANT}" \
  --filter-pattern "PHP Warning" \
  --query 'events[*].message' \
  --output text | grep -oP 'plugins/[^/]+' | sort | uniq -c | sort -rn
```

**2. Disable Non-Critical Plugins:**
```sql
-- Get current active plugins
SELECT option_value FROM wp_options WHERE option_name = 'active_plugins';

-- For non-essential plugins with warnings, deactivate via SQL
-- First, back up the current value
-- Then update with the plugin removed from serialized array

-- Alternative: Use WP-CLI from bastion
wp plugin deactivate plugin-name --allow-root
```

**3. Add Plugin Compatibility MU-Plugin:**
```php
<?php
/**
 * Plugin Name: PHP 8.2 Compatibility Layer
 * Description: Suppress non-critical warnings from older plugins
 */

// Suppress dynamic property warnings (common in older plugins)
set_error_handler(function($errno, $errstr, $errfile) {
    if (strpos($errstr, 'Creation of dynamic property') !== false) {
        return true; // Suppress this specific warning
    }
    return false; // Let other errors through
}, E_DEPRECATED);
```

---

## Common Theme-Specific Issues

### Uncode Theme Issues

**Symptoms:**
- Visual Composer shortcodes appearing as raw text
- Theme "not registered" warning in wp-admin
- Low PHP memory limit warnings in System Status

**Solutions:**

**1. Increase PHP Limits for Uncode:**
```json
// Task Definition environment variables
{
  "name": "PHP_MEMORY_LIMIT",
  "value": "512M"
},
{
  "name": "PHP_MAX_INPUT_VARS",
  "value": "5000"
},
{
  "name": "PHP_MAX_EXECUTION_TIME",
  "value": "600"
},
{
  "name": "WORDPRESS_CONFIG_EXTRA",
  "value": "...\ndefine('WP_MEMORY_LIMIT', '256M');\ndefine('WP_MAX_MEMORY_LIMIT', '512M');\n@ini_set('max_input_vars', 5000);\n"
}
```

**2. Strip Shortcodes from Archives MU-Plugin:**
```php
<?php
/**
 * Plugin Name: Strip Shortcodes from Archives
 * Description: Removes Visual Composer shortcodes on archive pages
 */
function strip_shortcodes_start_buffer() {
    if (is_archive() || is_home() || is_search()) {
        ob_start('strip_shortcodes_from_output');
    }
}
function strip_shortcodes_from_output($content) {
    // Strip Visual Composer shortcodes
    $content = preg_replace('/\[vc_[^\]]*\]/', '', $content);
    $content = preg_replace('/\[\/vc_[^\]]*\]/', '', $content);
    // Strip other unclosed shortcodes
    $content = preg_replace('/\[\/?[a-zA-Z_][a-zA-Z0-9_]*(?:\s[^\]]*)?(?:\/\])?\]/', '', $content);
    return $content;
}
add_action('template_redirect', 'strip_shortcodes_start_buffer', 1);
```

**3. Envato Purchase Code:**
- Uncode requires Envato Purchase Code for full functionality
- Request from client or check Envato account
- Enter in Appearance → Uncode → Product License

### Divi Theme Issues

**Symptoms:**
- Divi Builder not loading
- Module content not rendering
- CSS not generating

**Solutions:**

**1. Clear Divi Cache:**
```bash
# Via WP-CLI
wp eval "et_fb_delete_builder_assets();" --allow-root

# Or delete cache directory
rm -rf /mnt/efs/${TENANT}/wp-content/et-cache/*
```

**2. Enable Static CSS Generation:**
```php
// Add to wp-config.php via WORDPRESS_CONFIG_EXTRA
define('ET_BUILDER_ALWAYS_GENERATE_STATIC_CSS', true);
```

### Elementor Theme Issues

**Symptoms:**
- Elementor widgets not loading
- Theme Builder templates missing
- "Regenerate CSS" needed

**Solutions:**

**1. Regenerate Elementor CSS:**
```bash
# Via WP-CLI
wp elementor flush_css --allow-root
```

**2. Publish Draft Templates:**
```sql
UPDATE wp_posts
SET post_status = 'publish'
WHERE post_type = 'elementor_library'
AND post_status = 'draft';
```

---

**Document Version:** 2.3 - GravitonWealth Lessons & Performance Optimization
**Last Updated:** 2026-01-22
**Next Review:** After next tenant migration
**Maintained By:** DevOps Engineer Agent

