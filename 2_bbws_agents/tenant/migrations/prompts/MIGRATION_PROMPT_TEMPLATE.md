# Standard WordPress Migration Prompt Template

**Version:** 2.0 - Generic Template
**Last Updated:** 2026-01-22

## Overview

This template provides a standardized prompt for initiating WordPress migrations to the BBWS multi-tenant AWS hosting platform. It supports both:
- **Local files** - Site files already downloaded to the migrations folder
- **S3-based files** - Site files available in the S3 migration bucket

---

## Template Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `<website-name>` | The folder name in migrations directory | GravitonWealth, JBLWealth |
| `<s3-bucket-path>` | S3 bucket path (if applicable) | gravitonwealth, jblwealth |
| `<production-domain>` | Current production URL | www.gravitonwealth.co.za |
| `<table-prefix>` | WordPress table prefix | wp_ |
| `<site-folder>` | Subfolder containing site files | gravitonwm, jblwealth |
| `<database-files>` | Database backup filenames | site.sql, backup.sql |

---

## Generic Migration Prompt

Use this prompt template for any website in the migrations folder:

```
## Standard WordPress Migration Prompt: <website-name>

**Working Directory:** `2_bbws_agents/tenant/migrations/<website-name>`

**Source Files Discovery:**
Before starting, analyze the migration folder to identify:
1. Site files location (check /site/ subdirectory and its contents)
2. Database backup files (check /database/ subdirectory)
3. Any existing CLAUDE.md with project-specific instructions

**Objective:** Migrate this WordPress site to the BBWS multi-tenant AWS hosting platform following the approved migration process.

**File Sources (choose applicable):**
- **Local Files:** Available in the `/site/` and `/database/` subdirectories
- **S3 Bucket:** `s3://wordpress-migration-temp-20250903/<s3-bucket-path>` (AWS Region: `eu-west-1`)

**Important Constraints:**
- Use the default AWS CLI profile for all AWS operations
- Follow the Turn-by-Turn (TBT) workflow for tracking
- Do not begin implementation until the Master Plan has been reviewed and approved

**Project Management:**
- Launch the Project Manager (PM) using the PM style defined in: `2_bbws_agents/agentic_architect/Agentic_Project_Manager.md`
- The Master Plan must include detailed sub-plans covering all migration phases
- Submit the Master Plan for approval before proceeding with execution

**Execution Guidance:**
- Follow the WordPress migration runbook: `2_bbws_agents/tenant/migrations/runbooks/wordpress_migration_playbook_automated.md`
- Review ECS execution options: `2_bbws_agents/tenant/migrations/ecs_exec_alternatives_analysis.md`
- Check the Pre-Flight Checklist before starting Phase 2

**Target Environment:**
- DEV Domain Pattern: `<website-name>.wpdev.kimmyai.io`
- SIT Domain Pattern: `<website-name>.wpsit.kimmyai.io`
- Test Email Redirect: `tebogo@bigbeard.co.za`

**CloudFront Basic Auth Credentials:**
- DEV: Username: `dev` | Password: `ovcjaopj1ooojajo`
- SIT: Username: `bigbeard` | Password: `BigBeard2026!`
```

---

## Auto-Discovery Prompt

For migrations where file structure is unknown, use this discovery-first approach:

```
## WordPress Migration Discovery: <website-name>

**Working Directory:** `2_bbws_agents/tenant/migrations/<website-name>`

**Phase 0: Discovery**
Before creating a migration plan, discover and document:

1. **Folder Structure Analysis:**
   - List contents of the migration folder
   - Identify site files location (typically /site/<subfolder>/)
   - Identify database backups (typically /database/*.sql)
   - Check for any configuration files or notes

2. **Source Database Analysis:**
   - Examine database backup file(s) to determine:
     - Original domain/URL
     - Table prefix
     - WordPress version
     - Active theme
     - Active plugins (especially problematic ones)
     - WooCommerce or e-commerce presence

3. **S3 Bucket Check (if applicable):**
   - Check if files exist in: `s3://wordpress-migration-temp-20250903/<website-name>/`
   - List available files in the S3 path

4. **Generate Site Profile:**
   Create a migration profile document with discovered information.

**After Discovery:**
Proceed with standard migration using the discovered parameters.

**Execution Guidance:**
- Follow the WordPress migration runbook: `2_bbws_agents/tenant/migrations/runbooks/wordpress_migration_playbook_automated.md`
```

---

## Quick Start Commands

### Check Migration Folder Contents
```bash
# List migration folder structure
ls -la 2_bbws_agents/tenant/migrations/<website-name>/
ls -la 2_bbws_agents/tenant/migrations/<website-name>/site/
ls -la 2_bbws_agents/tenant/migrations/<website-name>/database/
```

### Check S3 Bucket Contents
```bash
# List files in S3 migration bucket
aws s3 ls s3://wordpress-migration-temp-20250903/<website-name>/ --recursive --summarize
```

### Quick Database Analysis
```bash
# Find original domain in database backup
grep -o "https\?://[a-zA-Z0-9.-]*\.[a-zA-Z]\{2,\}" database/*.sql | sort | uniq -c | sort -rn | head -10

# Find table prefix
head -100 database/*.sql | grep "CREATE TABLE"

# Check for WooCommerce
grep -c "woocommerce" database/*.sql
```

---

## Website-Specific Prompts (Legacy Reference)

The following are pre-configured prompts for known migration projects. For new migrations, use the Generic Migration Prompt above.

---

### GravitonWealth (gravitonwealth.co.za)

```
## Standard WordPress Migration Prompt: GravitonWealth

**Working Directory:** `2_bbws_agents/tenant/migrations/GravitonWealth`

**Directory Structure:**
- Site files: `/site/gravitonwm`
- Database backups: `/database` (gravitonwealthmanagement.sql, gravitonp.sql)

**Site Details:**
- Production Domain: `https://www.gravitonwealth.co.za/`
- Original Domain: `https://www.gravitonperspectives.co.za/`
- Database Name: `WPSIMDEVGravitonWM`
- Database Host: `SIM-NonPRD-HA-BDC.sanlam.co.za`
- Table Prefix: `wp_`
- Theme: Uncode (requires Envato Purchase Code)
- Page Builder: Visual Composer/WPBakery

**S3 Bucket:** `s3://wordpress-migration-temp-20250903/gravitonwealth`

**Special Considerations:**
- Uncode theme requires PHP memory limit 512M
- Visual Composer shortcodes may appear on archive pages
- WooCommerce installed but not actively used (financial blog)

**Execution Guidance:**
- Follow runbook: `2_bbws_agents/tenant/migrations/runbooks/wordpress_migration_playbook_automated.md`
- See Theme-Specific Issues section for Uncode fixes
```

---

### JBLWealth (jblwealth.personalinvest.co.za)

```
## Standard WordPress Migration Prompt: JBLWealth

**Working Directory:** `2_bbws_agents/tenant/migrations/JBLWealth`

**Directory Structure:**
- Site files: `/site/jblwealth`
- Database backup: `/database` (jblwealth.sql)

**Site Details:**
- Production Domain: `http://jblwealth.personalinvest.co.za`
- Table Prefix: `wp_`

**S3 Bucket:** `s3://wordpress-migration-temp-20250903/jblwealth`

**Execution Guidance:**
- Follow runbook: `2_bbws_agents/tenant/migrations/runbooks/wordpress_migration_playbook_automated.md`
```

---

### Lynfin (lynfin.personalinvest.co.za)

```
## Standard WordPress Migration Prompt: Lynfin

**Working Directory:** `2_bbws_agents/tenant/migrations/Lynfin`

**Directory Structure:**
- Site files: `/site/lynnwood-wealth`
- Database backup: `/database` (lynwoodwealth.sql)

**Site Details:**
- Production Domain: `https://lynfin.personalinvest.co.za/`
- Database Name: `WPSIMDEVLynnwoodWealth`
- Database Host: `srv005907:3306`
- Table Prefix: `wp_`

**S3 Bucket:** `s3://wordpress-migration-temp-20250903/lynfin`

**Execution Guidance:**
- Follow runbook: `2_bbws_agents/tenant/migrations/runbooks/wordpress_migration_playbook_automated.md`
```

---

### ManagedIS (managedis.personalinvest.co.za)

```
## Standard WordPress Migration Prompt: ManagedIS

**Working Directory:** `2_bbws_agents/tenant/migrations/ManagedIS`

**Directory Structure:**
- Site files: `/site/mis`
- Database backup: `/database` (mis.sql)

**Site Details:**
- Production Domain: `https://managedis.personalinvest.co.za/`
- Database Name: `WPSIMDEVManagedis`
- Database Host: `srv005907:3306`
- Table Prefix: `wp_`

**S3 Bucket:** `s3://wordpress-migration-temp-20250903/managedis`

**Execution Guidance:**
- Follow runbook: `2_bbws_agents/tenant/migrations/runbooks/wordpress_migration_playbook_automated.md`
```

---

### WealthDesign (wealthdesign.personalinvest.co.za)

```
## Standard WordPress Migration Prompt: WealthDesign

**Working Directory:** `2_bbws_agents/tenant/migrations/WealthDesign`

**Directory Structure:**
- Site files: `/site/wealth-design`
- Database backup: `/database` (wealthdesign.sql)

**Site Details:**
- Production Domain: `https://wealthdesign.personalinvest.co.za/`
- Database Name: `WPSIMDEVWealthDesign`
- Database Host: `srv005907:3306`
- Table Prefix: `wp_`

**S3 Bucket:** `s3://wordpress-migration-temp-20250903/wealthdesign`

**Execution Guidance:**
- Follow runbook: `2_bbws_agents/tenant/migrations/runbooks/wordpress_migration_playbook_automated.md`
```

---

### ACSGroup (acsgroup-ppe.personalinvest.co.za)

```
## Standard WordPress Migration Prompt: ACSGroup

**Working Directory:** `2_bbws_agents/tenant/migrations/ACSGroup`

**Directory Structure:**
- Site files: `/site/acs`
- Database backup: `/database` (acs.sql)

**Site Details:**
- Production Domain: `https://acsgroup-ppe.personalinvest.co.za/`
- Table Prefix: `wp_`

**S3 Bucket:** `s3://wordpress-migration-temp-20250903/acsgroup`

**Execution Guidance:**
- Follow runbook: `2_bbws_agents/tenant/migrations/runbooks/wordpress_migration_playbook_automated.md`
```

---

### OctagonFinancial (octagonfinancial.co.za) - Database Only

```
## Standard WordPress Migration Prompt: OctagonFinancial

**Working Directory:** `2_bbws_agents/tenant/migrations/OctagonFinancial`

**Directory Structure:**
- Site files: **NOT AVAILABLE** (must be sourced separately)
- Database backup: `/database` (octagonfin.sql)

**Site Details:**
- Production Domain: `https://www.octagonfinancial.co.za`
- Table Prefix: `wp_`

**S3 Bucket:** `s3://wordpress-migration-temp-20250903/octagonfinancial`

**Special Considerations:**
- No website archive exists locally - only database backup
- Website files may need to be downloaded from source hosting or S3

**Execution Guidance:**
- Follow runbook: `2_bbws_agents/tenant/migrations/runbooks/wordpress_migration_playbook_automated.md`
- First step: Acquire website files before proceeding
```

---

## Quick Reference Table

| # | Folder | Domain | S3 Path | Site Files | Database Files |
|---|--------|--------|---------|------------|----------------|
| 1 | GravitonWealth | gravitonwealth.co.za | gravitonwealth | gravitonwm/ | gravitonwealthmanagement.sql, gravitonp.sql |
| 2 | JBLWealth | jblwealth.personalinvest.co.za | jblwealth | jblwealth/ | jblwealth.sql |
| 3 | Lynfin | lynfin.personalinvest.co.za | lynfin | lynnwood-wealth/ | lynwoodwealth.sql |
| 4 | ManagedIS | managedis.personalinvest.co.za | managedis | mis/ | mis.sql |
| 5 | WealthDesign | wealthdesign.personalinvest.co.za | wealthdesign | wealth-design/ | wealthdesign.sql |
| 6 | ACSGroup | acsgroup-ppe.personalinvest.co.za | acsgroup | acs/ | acs.sql |
| 7 | OctagonFinancial | octagonfinancial.co.za | octagonfinancial | *(none)* | octagonfin.sql |
| 8 | CaseForward | caseforward.org | caseforward | wp-content/ | wordpress-db-20260123_145109.sql |
| 9 | FallenCovidHeroes | fallencovidheroes.co.za | fallencovidheroes | wp-content/ | wordpress-db-fixed.sql |
| 10 | Jeanique | jeanique.co.za/jeanique | jeanique | wp-content/ | wordpress-db-20260123_145756.sql |
| 11 | NorthPineBaptist | www.northpinebaptist.co.za | northpinebaptist | wp-content/ | wordpress-db-20260123_150801.sql |
| 12 | TheTippingPoint | www.thetippingpoint.co.za | thetippingpoint | *(none - BLOCKED)* | thetippingpoint.sql |
| 13 | TheTransitionThinkTank | thetransitionthinktank.org | thetransitionthinktank | wp-content/ | thetransitionthinktank.sql |

---

## Website-Specific Prompts (New Migrations)

---

### TheTippingPoint (thetippingpoint.co.za) - BLOCKED

```
## Standard WordPress Migration Prompt: TheTippingPoint

**Working Directory:** `2_bbws_agents/tenant/migrations/TheTippingPoint`

**Directory Structure:**
- Site files: **NOT AVAILABLE** - WordPress files missing from source export
- Database backup: `/database/thetippingpoint.sql`

**Site Details:**
- Production Domain: `http://www.thetippingpoint.co.za`
- Table Prefix: `wp_`

**S3 Bucket:** `s3://wordpress-migration-temp-20250903/thetippingpoint`

**BLOCKING ISSUE:**
- Source export contains only a static HTML landing page (css/, js/, images/, fonts/)
- No wp-content, wp-admin, or wp-includes present
- WordPress site files must be re-exported from Xneelo before migration can proceed
- Database backup is available and valid (WordPress wp_ tables confirmed)

**Transfer Method:** Direct bastion (< 500MB - only ~19MB)

**Execution Guidance:**
- Follow runbook: `2_bbws_agents/tenant/migrations/runbooks/wordpress_migration_playbook_automated.md`
- First step: Acquire WordPress site files from source hosting before proceeding
```

---

### TheTransitionThinkTank (thetransitionthinktank.org)

```
## Standard WordPress Migration Prompt: TheTransitionThinkTank

**Working Directory:** `2_bbws_agents/tenant/migrations/TheTransitionThinkTank`

**Source Files Discovery:**
Before starting, analyze the migration folder to identify:
1. Site files location (check /site/ subdirectory and its contents)
2. Database backup files (check /database/ subdirectory)
3. Any existing CLAUDE.md with project-specific instructions

**Directory Structure:**
- Site files: Source WordPress install at `/Users/sithembisomjoko/Documents/Monday - Migration - Sites 26012026/thetransitionthinktank/wp-content/`
- Database backup: `/database/thetransitionthinktank.sql`

**Site Details:**
- Production Domain: `https://thetransitionthinktank.org`
- Table Prefix: `wp_`

**S3 Bucket:** `s3://wordpress-migration-temp-20250903/thetransitionthinktank`

**Special Considerations:**
- **Wordfence WAF present** - MANDATORY: Run prepare-wordpress-for-migration.sh before import
- **Large site** (~807MB total, ~134MB database) - Use S3 staging method
- **ai1wm-backups and wflogs** in wp-content can be excluded from migration
- Source is a full WordPress install - only wp-content/ is needed for migration

**Important Constraints:**
- Use the default AWS CLI profile for all AWS operations
- Follow the Turn-by-Turn (TBT) workflow for tracking
- Do not begin implementation until the Master Plan has been reviewed and approved

**Project Management:**
- Launch the Project Manager (PM) using the PM style defined in: `2_bbws_agents/agentic_architect/Agentic_Project_Manager.md`
- The Master Plan must include detailed sub-plans covering all migration phases
- Submit the Master Plan for approval before proceeding with execution

**Transfer Method:** S3 staging (> 500MB)

**Execution Guidance:**
- Follow the WordPress migration runbook: `2_bbws_agents/tenant/migrations/runbooks/wordpress_migration_playbook_automated.md`
- Review ECS execution options: `2_bbws_agents/tenant/migrations/ecs_exec_alternatives_analysis.md`
- Check the Pre-Flight Checklist before starting Phase 2

**Target Environment:**
- DEV Domain Pattern: `thetransitionthinktank.wpdev.kimmyai.io`
- SIT Domain Pattern: `thetransitionthinktank.wpsit.kimmyai.io`
- Test Email Redirect: `tebogo@bigbeard.co.za`
```

---

## Adding New Migrations

When adding a new website to the migrations folder:

1. **Create folder structure:**
   ```bash
   mkdir -p 2_bbws_agents/tenant/migrations/<website-name>/site
   mkdir -p 2_bbws_agents/tenant/migrations/<website-name>/database
   ```

2. **Add files:**
   - Copy website files to `/site/<subfolder>/`
   - Copy database backup(s) to `/database/`

3. **Use the Generic Migration Prompt** above with discovered parameters

4. **Optionally create a CLAUDE.md** in the migration folder with site-specific instructions

---

**Document Version:** 2.0 - Generic Template
**Last Updated:** 2026-01-22
**Maintained By:** DevOps Engineer Agent
