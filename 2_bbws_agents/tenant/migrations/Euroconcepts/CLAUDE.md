# Euroconcepts - WordPress Migration Project

## Project Purpose

WordPress migration project to move the Euroconcepts website from Xneelo hosting to the BBWS multi-tenant AWS hosting platform.

## Site Profile

| Item | Value |
|------|-------|
| Production Domain | https://euroconcepts.co.za |
| Database Name | eurocbbgdu_2018 |
| Database Host | dedi232.cpt3.host-h.net:3306 |
| Table Prefix | wp_ |
| WordPress Version | 6.x |
| Theme | Hello Elementor (with child theme) |
| Page Builder | Elementor + Elementor Pro |
| Total Size | ~2.3GB |
| Database Size | ~50MB |

## Source Files

| Item | Location |
|------|----------|
| Source Directory | /Users/sithembisomjoko/Documents/Monday - Migration - Sites 26012026/euroconcepts |
| Database Backup | dedi232_cpt3_host-h_net (2).sql (50MB - main backup) |
| wp-content | Source directory/wp-content/ |

## Key Plugins

| Plugin | Status | Notes |
|--------|--------|-------|
| elementor | Keep Active | Page builder core |
| elementor-pro | Keep Active | Page builder pro features |
| gravityforms | Keep Active | Forms (configure email redirect) |
| advanced-custom-fields | Keep Active | Custom fields |
| wordpress-seo | Keep Active | Yoast SEO |
| revslider | Keep Active | Revolution Slider |
| really-simple-ssl | **DISABLE** | Causes redirect loops |
| redirection | **DISABLE** | Causes redirect issues |
| wordfence | **DISABLE** | Security conflicts |
| duplicate-post | Optional | Can keep or disable |
| under-construction-page | Disable | Not needed |

## Target Environments

| Environment | Domain | Status |
|-------------|--------|--------|
| DEV | euroconcepts.wpdev.kimmyai.io | Pending |
| SIT | euroconcepts.wpsit.kimmyai.io | Pending |
| PROD | euroconcepts.co.za | Future |

## Project-Specific Instructions

- Use **default AWS CLI profile** for all operations
- **MANDATORY:** Run `prepare-wordpress-for-migration.sh` before database import
- Follow the migration runbook: `../runbooks/wordpress_migration_playbook_automated.md`
- Test emails redirect to: `tebogo@bigbeard.co.za`
- Use **S3 staging method** (site > 500MB at 2.3GB)

## Transfer Method

**S3 Staging** - Site is 2.3GB which exceeds the 500MB threshold for direct bastion transfer.

Steps:
1. Package wp-content (excluding ai1wm-backups, wflogs)
2. Upload to S3: `s3://wordpress-migration-temp-20250903/euroconcepts/`
3. Download from bastion to EFS

## Database Preparation

The following plugins MUST be deactivated before import:
- `really-simple-ssl` - Causes HTTPS redirect loops
- `redirection` - Causes redirect conflicts
- `wordfence` - WAF conflicts with CloudFront/ALB

Use the prepare script:
```bash
./0_utilities/file_transfer/prepare-wordpress-for-migration.sh \
  "source.sql" \
  "prepared.sql"
```

## AWS Configuration

| Setting | Value |
|---------|-------|
| Profile | default (DO NOT change) |
| Region | eu-west-1 |
| S3 Bucket | wordpress-migration-temp-20250903 |

## Current Project Plan

Location: `.claude/plans/plan_1.md`

## Folder Structure

```
Euroconcepts/
├── .claude/                    # TBT workflow files
│   ├── logs/history.log        # Command history
│   ├── plans/                  # Migration plans
│   ├── snapshots/              # Pre-change snapshots
│   └── staging/                # Intermediate files
├── site/                       # Site artifacts (symlink or copy)
├── database/                   # Database files
│   └── euroconcepts-prepared.sql  # Prepared database
└── CLAUDE.md                   # This file
```

## Special Considerations

1. **Elementor Page Builder** - Site uses Elementor, ensure proper rendering after migration
2. **Gravity Forms** - Configure email redirect to test email in DEV/SIT
3. **Revolution Slider** - May need license reactivation
4. **Large Site** - 2.3GB requires S3 staging, not direct bastion transfer

## Root Workflow Inheritance

This project inherits TBT mechanism and all workflow standards from the parent CLAUDE.md:

{{include:../../CLAUDE.md}}
