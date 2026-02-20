# WordPress DEV to SIT Promotion Prompt

**Version:** 2.0
**Date:** 2026-02-06
**Based On:**
- `2_bbws_agents/tenant/migrations/runbooks/MIGRATION_PROMPT_TEMPLATE.md`
- `2_bbws_agents/tenant/migrations/runbooks/wordpress_migration_playbook_automated.md` (Phase 5)

---

## Overview

This prompt initiates the promotion of WordPress tenant(s) from the DEV environment to SIT environment on the BBWS multi-tenant AWS hosting platform.

---

## Template Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `<tenant-name>` | The tenant/service name | cliplok, schroderandassociates |
| `<dev-domain>` | DEV environment URL | cliplok.wpdev.kimmyai.io |
| `<sit-domain>` | SIT environment URL | cliplok.wpsit.kimmyai.io |

---

## DEV to SIT Promotion Prompt

```
## WordPress DEV to SIT Promotion: <tenant-name>

**Source Environment:** DEV (AWS Account: 536580886816, eu-west-1)
**Target Environment:** SIT (AWS Account: 815856636111, eu-west-1)

**AWS Profiles:**
- DEV: `dev` or `Tebogo-dev`
- SIT: `sit` or `Tebogo-sit`

---

### MANDATORY PRE-PROMOTION CHECKLIST

Before proceeding, verify ALL criteria are met in DEV:

- [ ] **All DEV tests passed** - Site loads without errors
- [ ] **Forms working** - Emails redirected to tebogo@bigbeard.co.za
- [ ] **Content renders correctly** - All pages, posts, media display properly
- [ ] **Plugins functional** - No PHP errors or warnings
- [ ] **Performance acceptable** - Page load < 3 seconds
- [ ] **No encoding issues** - Special characters display correctly
- [ ] **No PHP errors** - Check CloudWatch logs for errors
- [ ] **SSL working** - HTTPS loads without mixed content warnings

**If ANY criteria is NOT met, DO NOT proceed. Fix issues in DEV first.**

---

### MANDATORY CONSTRAINTS - NEVER VIOLATE

#### 1. Bastion Access: SSM ONLY
**SSH DOES NOT WORK** - No SSH keys exist on bastion.

```bash
# CORRECT: SSM Session
aws ssm start-session --target <instance-id> --profile sit

# WRONG: SSH (WILL FAIL)
ssh ec2-user@bastion-ip  # NO SSH KEY EXISTS
```

#### 2. File Transfer: Size-Based Decision

| Total Size | Method | Reason |
|------------|--------|--------|
| **< 500MB** | Direct bastion via SSM port forwarding | Faster, no S3 timeout |
| **> 500MB** | S3 staging | Local connection too slow |

#### 3. Database Export/Import: From Bastion Only

```bash
# Export from DEV (on DEV bastion)
mysqldump -h <dev-rds-endpoint> -u <user> -p <database> > /tmp/tenant-export.sql

# Import to SIT (on SIT bastion)
mysql -h <sit-rds-endpoint> -u <user> -p <database> < /tmp/tenant-export.sql
```

#### 4. URL Replacement: MANDATORY

When promoting, update ALL URLs from DEV to SIT:
- `https://<tenant>.wpdev.kimmyai.io` -> `https://<tenant>.wpsit.kimmyai.io`

---

### KNOWN FAILURE MODES

The following are the top 10 issues encountered during past DEV-to-SIT promotions. Each has an MI-ID referencing the full entry in `runbooks/KNOWN_ISSUES_REGISTRY.md`.

| MI-ID | Issue | Severity | Prevention Rule |
|-------|-------|----------|-----------------|
| MI-018 | HTTPS redirect loop (301 forever) | CRITICAL | Ensure `$_SERVER['HTTPS'] = 'on';` in WORDPRESS_CONFIG_EXTRA |
| MI-014 | Mixed content (HTTP on HTTPS page) | CRITICAL | Deploy force-https.php MU-plugin BEFORE first access |
| MI-006 | Homepage empty (0 bytes) | CRITICAL | Force ECS redeploy after file import; verify content size |
| MI-003 | UTF-8 encoding artifacts | MEDIUM | ALWAYS use `--default-character-set=utf8mb4` on export AND import |
| MI-005 | EFS permissions (root not 33:33) | HIGH | Run `chown -R 33:33` immediately after file copy to EFS |
| MI-009 | Incomplete URL replacement (Yoast) | MEDIUM | Include `wp_yoast_indexable` and `wp_yoast_seo_links` in URL replacement |
| MI-024 | Really Simple SSL redirect loops | HIGH | Run `prepare-wordpress-for-migration.sh` on SQL before import |
| MI-020 | ECS task ResourceInitializationError | HIGH | Add IAM inline policy for EFS access point before deploying service |
| MI-019 | Target group unhealthy (502/503) | HIGH | Health check path `/`, matcher `200-302`, protocol `HTTP` |
| MI-013 | Wrong theme active | HIGH | Verify active theme in wp_options before and after migration |

**Full registry:** `2_bbws_agents/tenant/migrations/runbooks/KNOWN_ISSUES_REGISTRY.md`

---

### PHASE 5: SIT PROMOTION PROCESS

#### Step 1: Verify DEV Environment Health

```bash
# Check DEV service status
aws ecs describe-services \
  --cluster dev-cluster \
  --services dev-<tenant-name>-service \
  --profile dev \
  --query 'services[0].{Status:status,Running:runningCount,Desired:desiredCount}'

# Validate DEV site accessibility
curl -sI https://<tenant-name>.wpdev.kimmyai.io | head -5
```

#### Step 2: Provision SIT Tenant Infrastructure

Use terraform to create SIT tenant:

```bash
cd 2_bbws_ecs_terraform/tenant

# Initialize for SIT
terraform init -backend-config=environments/sit/backend.hcl

# Plan SIT deployment
terraform plan \
  -var-file=environments/sit/terraform.tfvars \
  -var="tenant_name=<tenant-name>" \
  -out=sit-<tenant-name>.plan

# Apply (after review)
terraform apply sit-<tenant-name>.plan
```

#### Step 3: Export Data from DEV

**Database Export:**
```bash
# Connect to DEV bastion
aws ssm start-session --target <dev-bastion-id> --profile dev

# Export database
mysqldump -h <dev-rds-endpoint> \
  -u admin -p \
  --single-transaction \
  --routines \
  --triggers \
  <tenant-database> > /tmp/<tenant>-dev-export.sql
```

**Files Export:**
```bash
# From DEV EFS, create archive of wp-content
tar -czf /tmp/<tenant>-wp-content.tar.gz -C /mnt/efs/<tenant> wp-content
```

#### Step 4: Transfer to SIT

**Option A: Direct Transfer (< 500MB)**
```bash
# Start SSM port forwarding to DEV bastion
aws ssm start-session --target <dev-bastion-id> \
  --document-name AWS-StartPortForwardingSession \
  --parameters '{"portNumber":["22"],"localPortNumber":["2222"]}' \
  --profile dev

# Download from DEV
scp -P 2222 ssm-user@localhost:/tmp/<tenant>-dev-export.sql ./
scp -P 2222 ssm-user@localhost:/tmp/<tenant>-wp-content.tar.gz ./

# Start SSM port forwarding to SIT bastion
aws ssm start-session --target <sit-bastion-id> \
  --document-name AWS-StartPortForwardingSession \
  --parameters '{"portNumber":["22"],"localPortNumber":["2223"]}' \
  --profile sit

# Upload to SIT
scp -P 2223 <tenant>-dev-export.sql ssm-user@localhost:/tmp/
scp -P 2223 <tenant>-wp-content.tar.gz ssm-user@localhost:/tmp/
```

**Option B: S3 Staging (> 500MB)**
```bash
# Upload to S3 from DEV bastion
aws s3 cp /tmp/<tenant>-dev-export.sql s3://wordpress-migration-temp-20250903/<tenant>/sit/
aws s3 cp /tmp/<tenant>-wp-content.tar.gz s3://wordpress-migration-temp-20250903/<tenant>/sit/

# Download on SIT bastion
aws s3 cp s3://wordpress-migration-temp-20250903/<tenant>/sit/<tenant>-dev-export.sql /tmp/
aws s3 cp s3://wordpress-migration-temp-20250903/<tenant>/sit/<tenant>-wp-content.tar.gz /tmp/
```

#### Step 5: Import to SIT

**Database Import with URL Replacement:**
```bash
# On SIT bastion
# First, replace DEV URLs with SIT URLs
sed -i 's/<tenant>.wpdev.kimmyai.io/<tenant>.wpsit.kimmyai.io/g' /tmp/<tenant>-dev-export.sql

# Import to SIT RDS
mysql -h <sit-rds-endpoint> -u admin -p <tenant-database> < /tmp/<tenant>-dev-export.sql
```

**Files Import:**
```bash
# On SIT bastion
# Extract to SIT EFS
tar -xzf /tmp/<tenant>-wp-content.tar.gz -C /mnt/efs/<tenant>/

# Set permissions
chown -R www-data:www-data /mnt/efs/<tenant>/wp-content
```

#### Step 6: Update SIT Configuration

**Update wp-config.php for SIT:**
```php
define('WP_ENV', 'sit');
define('TEST_EMAIL_REDIRECT', 'tebogo@bigbeard.co.za');
define('WP_HOME', 'https://<tenant>.wpsit.kimmyai.io');
define('WP_SITEURL', 'https://<tenant>.wpsit.kimmyai.io');
define('WP_ENVIRONMENT_TYPE', 'staging');
```

**Update Task Definition for SIT:**
Ensure WORDPRESS_CONFIG_EXTRA includes:
```
$_SERVER['HTTPS'] = 'on';
define('FORCE_SSL_ADMIN', false);
define('WP_HOME', 'https://<tenant>.wpsit.kimmyai.io');
define('WP_SITEURL', 'https://<tenant>.wpsit.kimmyai.io');
define('WP_ENVIRONMENT_TYPE', 'staging');
```

#### Step 7: Force ECS Service Update

```bash
aws ecs update-service \
  --cluster sit-cluster \
  --service sit-<tenant-name>-service \
  --force-new-deployment \
  --profile sit
```

#### Step 8: Validate SIT Deployment

```bash
# Run validation script
./validate-migration.sh https://<tenant-name>.wpsit.kimmyai.io

# Manual checks
curl -sI https://<tenant-name>.wpsit.kimmyai.io | head -10

# Check for PHP errors in CloudWatch
aws logs filter-log-events \
  --log-group-name /ecs/sit-<tenant-name> \
  --filter-pattern "ERROR" \
  --profile sit
```

---

### AUTOMATION SCRIPTS

These scripts automate and validate the promotion process. Located in `2_bbws_agents/tenant/migrations/scripts/`.

**Full Orchestration (recommended):**
```bash
# Run the complete 8-step promotion
./scripts/promote_dev_to_sit.sh <tenant-name>

# With options
./scripts/promote_dev_to_sit.sh <tenant-name> --skip-terraform --verbose
./scripts/promote_dev_to_sit.sh <tenant-name> --dry-run
./scripts/promote_dev_to_sit.sh <tenant-name> --skip-terraform --auto-approve
```

**Individual Validation Scripts:**
```bash
# Pre-promotion checks (run before exporting from DEV)
./scripts/pre_promotion_validate.sh <tenant-name> dev
./scripts/pre_promotion_validate.sh <tenant-name> dev --verbose

# Post-promotion checks (run after importing to SIT)
./scripts/post_promotion_validate.sh <tenant-name> sit
./scripts/post_promotion_validate.sh <tenant-name> sit --verbose
```

**Script Capabilities:**
| Script | Checks | Exit Code |
|--------|--------|-----------|
| `pre_promotion_validate.sh` | 11 pre-export checks (AWS auth, ECS health, HTTP, encoding, DB) | 0=pass, 1=fail |
| `post_promotion_validate.sh` | 14 post-import checks (HTTP, content, mixed content, EFS, CSS, admin) | 0=pass, 1=fail |
| `promote_dev_to_sit.sh` | 8-step orchestration calling both validation scripts | 0=success, 1=issues |

---

### ERROR HANDLING — COE PROCESS

When an error occurs during promotion, follow this 5-step process:

1. **Identify** — Check the error against `runbooks/KNOWN_ISSUES_REGISTRY.md` using MI-IDs
2. **Document** — Copy `.claude/coe/COE_TEMPLATE.md` to `.claude/coe/active/coe_YYYY_MM_DD_<description>.md`
3. **Investigate** — Fill in root cause analysis, referencing the MI-ID if it matches a known issue
4. **Resolve** — Apply the documented resolution from the registry, or develop a new fix
5. **Close** — Move the COE to `.claude/coe/resolved/`, and if the issue is new, add it to the registry with the next MI-ID

**COE Template Location:** `.claude/coe/COE_TEMPLATE.md`
**Known Issues Registry:** `runbooks/KNOWN_ISSUES_REGISTRY.md`

**When to create a COE:**
- Any step in the promotion fails with an unexpected error
- Post-promotion validation reports failures
- The promotion takes >2 hours (indicating process gaps)
- A previously unseen issue is encountered

---

### POST-PROMOTION VERIFICATION

- [ ] SIT site loads at `https://<tenant>.wpsit.kimmyai.io`
- [ ] All pages render correctly
- [ ] Forms submit (check tebogo@bigbeard.co.za for test emails)
- [ ] Media/images display properly
- [ ] No mixed content warnings
- [ ] No PHP errors in CloudWatch logs
- [ ] Performance acceptable (< 3s load time)

---

### USER ACCEPTANCE TESTING (UAT)

After successful promotion:
1. Share SIT URL with stakeholders
2. Provide UAT checklist
3. Collect feedback
4. Document any issues found

---

### STAKEHOLDER SIGN-OFF

Before production cutover:
- [ ] UAT completed
- [ ] Business owner approval obtained
- [ ] Go-live date confirmed
- [ ] Rollback plan documented

---

**Execution Guidance:**
- Follow the WordPress migration runbook: `2_bbws_agents/tenant/migrations/runbooks/wordpress_migration_playbook_automated.md`
- Use TBT (Turn-by-Turn) workflow for tracking
- Do not proceed to PROD without SIT sign-off
```

---

## Quick Reference: Available DEV Services for Promotion

| Service Name | DEV Domain | Status |
|--------------|------------|--------|
| dev-cliplok-service | cliplok.wpdev.kimmyai.io | Ready |
| dev-schroderandassociates-service | schroderandassociates.wpdev.kimmyai.io | Ready |
| dev-plumruscare-service | plumruscare.wpdev.kimmyai.io | Ready |
| dev-gravitonwealth-service | gravitonwealth.wpdev.kimmyai.io | Ready |
| dev-northpinebaptist-service | northpinebaptist.wpdev.kimmyai.io | Ready |
| dev-lynfin-service | lynfin.wpdev.kimmyai.io | Ready |
| dev-fallencovidheroes-service | fallencovidheroes.wpdev.kimmyai.io | Ready |
| dev-thetransitionthinktank-service | thetransitionthinktank.wpdev.kimmyai.io | Ready |
| dev-managedis-service | managedis.wpdev.kimmyai.io | Ready |
| dev-wealthdesign-service | wealthdesign.wpdev.kimmyai.io | Ready |
| dev-yourfinancialflow-service | yourfinancialflow.wpdev.kimmyai.io | Ready |

---

## Example Usage

To promote `cliplok` to SIT, replace `<tenant-name>` with `cliplok`:

```
## WordPress DEV to SIT Promotion: cliplok

**Source:** cliplok.wpdev.kimmyai.io (DEV)
**Target:** cliplok.wpsit.kimmyai.io (SIT)

[Follow all steps above with tenant-name = cliplok]
```

---

**Document Version:** 2.0
**Last Updated:** 2026-02-06
**Source:** MIGRATION_PROMPT_TEMPLATE.md + wordpress_migration_playbook_automated.md Phase 5
**Added:** Known Failure Modes, Automation Scripts, Error Handling COE Process
