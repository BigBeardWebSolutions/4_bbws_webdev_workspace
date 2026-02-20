# Tenant Migrations - Project Overview

## Project Purpose

Central hub for WordPress tenant migration projects - migrating websites from Xneelo hosting to the BBWS multi-tenant AWS hosting platform.

## Migration Projects

### Pending Migrations

| Tenant | Status | Notes |
|--------|--------|-------|
| ACSGroup | Pending | |
| CaseForward | Ready for Migration | Has CLAUDE.md, DB fixed, 452MB direct bastion |
| FallenCovidHeroes | Ready for Migration | Has CLAUDE.md, DB fixed, 308MB direct bastion |
| GravitonWealth | Pending | 2 DB files |
| JBLWealth | Pending | |
| Jeanique | Ready for Migration | Has CLAUDE.md, DB fixed, 835MB S3 staging |
| Lynfin | Pending | Has CLAUDE.md |
| ManagedIS | Pending | |
| Manufacturing-Websites | In Progress | Has CLAUDE.md |
| NorthPineBaptist | Ready for Migration | Has CLAUDE.md, DB fixed, 2.1GB S3 staging |
| OctagonFinancial | Pending | |
| TheTippingPoint | Blocked | Has CLAUDE.md, 19MB, missing wp-content files |
| TheTransitionThinkTank | DEV Complete | Has CLAUDE.md, all phases done, DEV validated 2026-01-29, pending cutover |
| WealthDesign | Pending | |

### Completed Migrations

| Tenant | Status | Notes |
|--------|--------|-------|
| AuPairHive | Completed | |
| Southerncrossbeach | Completed | Has CLAUDE.md |
| runbooks | N/A | Standard procedures |
| scripts | N/A | Automation tools |
| site | Completed | |

## Migration Workflow

1. **Export** - Extract WordPress files and database from source (Xneelo)
2. **Staging** - Upload to S3 migration bucket
3. **Provision** - Create tenant in target environment
4. **Import** - Restore database and files
5. **Configure** - Update URLs, test functionality
6. **Validate** - Run migration validation checks
7. **Cutover** - DNS switch and go-live

## Standard Runbooks

| Runbook | Location |
|---------|----------|
| Migration Playbook | `runbooks/wordpress_migration_playbook_automated.md` |
| Export Script | `scripts/export-wordpress.sh` |

## Project-Specific Instructions

- Each tenant migration has its own subfolder with CLAUDE.md
- Use `runbooks/` for standard migration procedures
- Use `scripts/` for automation tools
- Follow TBT protocol for all migration operations
- Test emails redirect to: `tebogo@bigbeard.co.za`

## Target Environments

| Environment | Domain Pattern | AWS Account |
|-------------|----------------|-------------|
| DEV | {tenant}.wpdev.kimmyai.io | 536580886816 |
| SIT | {tenant}.wpsit.kimmyai.io | 815856636111 |
| PROD | Custom domain | 093646564004 |

---

## MANDATORY CONSTRAINTS - NEVER VIOLATE

### 1. Bastion Access: SSM ONLY

**SSH DOES NOT WORK** - No SSH keys exist on bastion. **ALWAYS use SSM**.

```bash
# CORRECT: SSM Session
aws ssm start-session --target <instance-id> --profile <profile>

# WRONG: SSH (WILL FAIL)
ssh ec2-user@bastion-ip  # NO SSH KEY EXISTS
```

### 2. File Transfer: Size-Based Decision

| Total Size | Method | Reason |
|------------|--------|--------|
| **< 500MB** | Direct bastion via SSM port forwarding | Faster, no S3 timeout |
| **> 500MB** | S3 staging | Local connection too slow |

**For small migrations (< 500MB):**
```bash
# Step 1: Start SSM port forwarding
aws ssm start-session --target <bastion-id> \
  --document-name AWS-StartPortForwardingSession \
  --parameters '{"portNumber":["22"],"localPortNumber":["2222"]}' \
  --profile dev

# Step 2: SCP files to bastion
scp -P 2222 database.sql ssm-user@localhost:/tmp/
scp -P 2222 wp-content.tar.gz ssm-user@localhost:/tmp/

# Step 3: From bastion, import to RDS / copy to EFS
```

**NEVER do this:**
```bash
aws s3 cp file.tar.gz s3://bucket/  # TIMES OUT for slow connections
```

### 3. Database Fix: MANDATORY Before Import

**ALWAYS run the prepare script before importing any database:**
```bash
# Location: 0_utilities/file_transfer/prepare-wordpress-for-migration.sh
./prepare-wordpress-for-migration.sh input.sql output-fixed.sql
```

This deactivates really-simple-ssl, wordfence, and other redirect-causing plugins.

### 4. Database Import: From Bastion Only

```bash
# CORRECT: From bastion
mysql -h rds-endpoint -u user -p database < /tmp/database.sql

# WRONG: Inline SQL via SSM (fails with complex queries)
# WRONG: Direct local-to-RDS connection (no network access)
```

### WordPress HTTPS/Redirect Troubleshooting Checklist

When a site returns HTTP 301 redirect loop:

1. **Check wp_options table first**:
   ```sql
   SELECT option_name, option_value FROM wp_options
   WHERE option_name IN ('siteurl', 'home');
   ```

2. **Deploy force-https.php mu-plugin** (unconditionally sets HTTPS):
   ```php
   $_SERVER["HTTPS"] = "on";
   $_SERVER["REQUEST_SCHEME"] = "https";
   $_SERVER["SERVER_PORT"] = "443";
   ```

3. **Check for problematic plugins** in wp_options:
   - `rsssl_options` (Really Simple SSL)
   - `redirection_options`
   - `wordfence_%` settings
   - `multiple-domain` plugin

4. **Check show_on_front setting**:
   ```sql
   SELECT option_value FROM wp_options WHERE option_name = 'show_on_front';
   ```
   - If `page` causes redirect but `posts` works, investigate theme static page handling

5. **Disable redirect-related plugins**:
   ```sql
   UPDATE wp_options SET option_value = 'a:0:{}'
   WHERE option_name = 'active_plugins';
   ```

6. **Check ECS task definition** - ensure WORDPRESS_CONFIG_EXTRA has HTTPS detection:
   ```php
   if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
       $_SERVER['HTTPS'] = 'on';
   }
   ```

### ECS Task Definition Updates

When updating task definitions:

1. **Export current definition** (remove read-only fields):
   ```bash
   aws ecs describe-task-definition --task-definition dev-<tenant> \
     --query 'taskDefinition' --output json > /tmp/task-def.json
   ```

2. **Remove these fields** before registering new revision:
   - `taskDefinitionArn`
   - `revision`
   - `status`
   - `requiresAttributes`
   - `compatibilities`
   - `registeredAt`
   - `registeredBy`

3. **Register new revision**:
   ```bash
   aws ecs register-task-definition --cli-input-json file:///tmp/new-task-def.json
   ```

4. **Update service**:
   ```bash
   aws ecs update-service --cluster dev --service dev-<tenant> \
     --task-definition dev-<tenant>:<new-revision> --force-new-deployment
   ```

### AWS Profile Management

Always set the correct profile before operations:

```bash
# DEV environment
export AWS_PROFILE=dev

# If token expired
aws sso login --profile dev
```

---

## Root Workflow Inheritance

This project inherits TBT mechanism and all workflow standards from the parent CLAUDE.md:

{{include:../../CLAUDE.md}}
