# Rand Club - Migration Project

## Project Purpose

Migrate the Rand Club WordPress website from Xneelo hosting to the BBWS multi-tenant AWS hosting platform.

## Site Profile

| Field | Value |
|-------|-------|
| **Production Domain** | `https://www.randclub.co.za` |
| **DEV Domain** | `randclub.wpdev.kimmyai.io` |
| **Table Prefix** | `wp_` |
| **Database File** | `database/randclub.sql` (~9MB) |
| **Fixed Database** | `database/randclub-fixed.sql` (~9MB) |
| **Site Files** | `site/randclub-wp-content.tar.gz` |
| **Total Size** | ~690MB (575MB wp-content + 9MB database) |
| **Transfer Method** | S3 staging (> 500MB) |
| **Theme** | `brixey` (with `brixey-core` plugin) |
| **Page Builder** | WPBakery (js_composer) |
| **Language** | Default (en-US) |

## Special Considerations

- **Wordfence WAF present** (`wordfence-waf.php` in root) - **DEACTIVATED in fixed SQL**
- **No Really Simple SSL** - not present in SQL or plugins
- **WPBakery Page Builder** (`js_composer`) - visual composer, may need license re-activation
- **LiteSpeed Cache** plugin present - will be deactivated (not needed on AWS)
- **Google Site Kit** - may need domain re-configuration
- **Contact Form 7** - test form submissions post-migration
- **PDF Embedder Premium** - verify functionality post-migration
- **PublishPress Authors** - verify author pages work
- **beta.randclub.co.za** - separate React app in source, NOT part of WordPress migration
- **Database charset note** - DB creation says `latin1` but tables use `utf8mb4`, import with `--default-character-set=utf8mb4`
- **Multiple SQL dump copies** - using `dedi111_cpt3_host-h_net.sql` (all copies identical)

## Source Information

- **Source Location:** `/Users/sithembisomjoko/Downloads/Monday-Migrated-Sites-09022026/randclub/`
- **Database Name (from export):** `randclub_new`
- **Original SQL File:** `dedi111_cpt3_host-h_net.sql`
- **Source Host:** `dedi111.cpt3.host-h.net`
- **Source siteurl:** `http://www.randclub.co.za`
- **Source home:** `http://www.randclub.co.za`

## Plugins Inventory

| Plugin | Status | Migration Notes |
|--------|--------|-----------------|
| `brixey-core` | Active | Theme companion plugin |
| `contact-form-7` | Active | Test forms post-migration |
| `duplicate-page` | Active | Admin utility |
| `google-site-kit` | Active | Needs domain reconfiguration |
| `insert-headers-and-footers` | Active | Check custom code |
| `js_composer` (WPBakery) | Active | May need license re-activation |
| `litespeed-cache` | Active | Deactivate - not needed on AWS |
| `pdfembedder-premium` | Active | Verify PDF display |
| `publishpress-authors` | Active | Verify author pages |
| `updraftplusX` | Active | Backup plugin - can deactivate |

## Directory Structure

```
randclub/
├── CLAUDE.md                              # This file
├── randclub_task_definition.json          # ECS task definition
├── randclub_preflight_checklist.md        # Pre-migration checklist
├── site/
│   └── randclub-wp-content.tar.gz         # WordPress wp-content archive
└── database/
    ├── randclub.sql                        # Original database (~9MB)
    ├── randclub-fixed.sql                  # Fixed database (wordfence deactivated)
    ├── url-replacement.sql                 # Domain replacement SQL
    └── fix-encoding.sql                    # Encoding artifact fix SQL
```

## Migration Status

| Phase | Status | Notes |
|-------|--------|-------|
| Export | DONE | Source files obtained from Xneelo |
| Database Fix | DONE | prepare-wordpress-for-migration.sh, removed PHP warning, CREATE DB lines |
| Pre-flight | DONE | Task definition, SQL scripts, S3 staging |
| S3 Upload | DONE | All files to `s3://sit-wordpress-migration-temp-20260202/randclub/` |
| Provision | DONE | DB, EFS access point, IAM, Secrets Manager, ALB rules, ECS |
| Import | DONE | DB import (33 tables, 1062 posts), URL replacement, wp-content to EFS |
| Configure | DONE | force-https.php MU-plugin, macOS `._*` files cleaned |
| Validate | DONE | HTTP 200, correct title, REST API works, no mixed content |
| Cutover | Pending | DNS switch to production |

## SIT Environment (Deployed 2026-02-09)

| Resource | Value |
|----------|-------|
| **SIT URL** | `https://randclub.wpsit.kimmyai.io` |
| **Basic Auth** | `bbws-sit` / `REPLACE_VIA_SECRETS` |
| **AWS Account** | `815856636111` |
| **Region** | `eu-west-1` |
| **ECS Service** | `sit-randclub-service` (cluster: `sit-cluster`) |
| **Task Definition** | `sit-randclub:1` |
| **Database** | `tenant_randclub_db` on `sit-mysql.cn6qqe8eu6b9.eu-west-1.rds.amazonaws.com` |
| **Secret** | `sit-randclub-db-credentials` |
| **EFS Access Point** | `fsap-009b7769d5e054cbb` (path: `/randclub/wp-content`) |
| **Target Group** | `sit-randclub-tg` (priority 117) |
| **ALB Listener Rules** | HTTPS priority 117, HTTP priority 117 |

## Issues Resolved During Migration

- **macOS `._*` resource fork files** in mu-plugins dir caused WordPress to output binary data; fixed by deleting all `._*` files
- **force-https.php shell escaping** - `!` character got backslash-escaped through SSM heredoc; fixed with printf
- **File ownership** - tar extraction preserved macOS uid 501; fixed with `chown -R 33:33`
- **DB import duplicate key error** - phpMyAdmin dump format caused `ERROR 1062` on ALTER TABLE; data imported correctly (33 tables)
- **Bastion /tmp space** - tmpfs only 1.9GB; fixed by streaming S3 directly to tar extract on EFS

## Root Workflow Inheritance

This project inherits TBT mechanism and all workflow standards from the parent CLAUDE.md:

{{include:../CLAUDE.md}}
