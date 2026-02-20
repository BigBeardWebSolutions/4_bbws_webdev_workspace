# TheTransitionThinkTank - Migration Project

## Project Purpose

Migrate the Transition Think Tank WordPress website from Xneelo hosting to the BBWS multi-tenant AWS hosting platform.

## Site Profile

| Field | Value |
|-------|-------|
| **Production Domain** | `https://thetransitionthinktank.org` |
| **DEV Domain** | `thetransitionthinktank.wpdev.kimmyai.io` |
| **Table Prefix** | `wp_` |
| **Database File** | `database/thetransitionthinktank.sql` (~134MB) |
| **Fixed Database** | `database/thetransitionthinktank-fixed.sql` (~134MB) |
| **Site Files** | `site/thetransitionthinktank-wp-content.tar.gz` (~209MB compressed) |
| **Total Size** | ~807MB |
| **Transfer Method** | S3 staging (> 500MB) |
| **Theme** | `hello-elementor` (parent) + `hello-theme-child-master` (child) |
| **Page Builder** | Elementor 3.32.2 + Elementor Pro 3.32.1 |
| **Language** | `en-ZA` (South African English) |

## Special Considerations

- **Wordfence WAF present** (`wordfence-waf.php` in root) - **DEACTIVATED in fixed SQL**
- **Large database** (~134MB) - ensure sufficient bastion memory for import
- **Full WordPress install** - includes wp-admin and wp-includes (only wp-content needed for migration)
- **ai1wm-backups** present in wp-content (excluded from migration tar.gz)
- **wflogs** present in wp-content (excluded from migration tar.gz)
- **Elementor Pro** - requires license re-activation on new domain
- **Gravity Forms** - requires license re-activation on new domain
- **Google reCAPTCHA Enterprise** - site key `6LdcztUr...` domain-locked, needs new domain added
- **Google Analytics 4** - tracking ID `G-YB6L23547D`
- **LinkedIn Insight Tag** - needs domain allowlisting
- **Complianz GDPR** - cookie consent, update domain in settings
- **Yoast SEO** - manages robots.txt, sitemaps, meta tags
- **Open Sans font loaded twice** - consider dequeuing duplicate post-migration

## Source Information

- **Source Location:** `/Users/sithembisomjoko/Documents/Monday - Migration - Sites 26012026/thetransitionthinktank/`
- **Database Name (from export):** `dedi232_cpt3_host-h_net`
- **Original SQL File:** `dedi232_cpt3_host-h_net (1).sql`

## Directory Structure

```
TheTransitionThinkTank/
├── CLAUDE.md                                    # This file
├── .claude/                                     # TBT workflow files
│   ├── logs/history.log
│   ├── plans/plan_1.md                          # Master migration plan
│   ├── plans/plan_2.md                          # PROD site analysis plan
│   ├── staging/staging_1/                       # Analysis report staging
│   └── snapshots/
├── thetransitionthinktank_task_definition.json  # ECS task definition
├── thetransitionthinktank_preflight_checklist.md # Pre-migration checklist
├── thetransitionthinktank_integration_inventory.md # Third-party integrations
├── thetransitionthinktank_site_analysis_2026-01-29.md # PROD site analysis
├── site/
│   └── thetransitionthinktank-wp-content.tar.gz # WordPress wp-content archive
└── database/
    ├── thetransitionthinktank.sql               # Original database (~134MB)
    ├── thetransitionthinktank-fixed.sql          # Fixed database (wordfence deactivated)
    ├── url-replacement.sql                       # Domain replacement SQL
    └── fix-encoding.sql                          # Encoding artifact fix SQL
```

## Migration Status

| Phase | Status | Notes |
|-------|--------|-------|
| Export | DONE | Source files obtained from Xneelo |
| Database Fix | DONE | `prepare-wordpress-for-migration.sh` executed, Wordfence deactivated |
| PROD Analysis | DONE | Baseline analysis completed 2026-01-29 |
| Pre-flight | DONE | Checklist, task definition, SQL scripts, integration inventory created |
| S3 Upload | DONE | Files uploaded to `s3://wordpress-migration-temp-20250903/thetransitionthinktank/` |
| Provision | DONE | DB, EFS (`fsap-0add53c62839e858e`), IAM, Secrets Manager, ALB, ECS all provisioned |
| Import | DONE | DB imported, URL replacement executed, wp-content on EFS |
| Configure | DONE | Full mu-plugin deployed, FORCE_SSL_ADMIN=false, CloudFront auth exclusion |
| Validate | DONE | All 12 pages HTTP 200, content parity with PROD (1-2KB variance) |
| Cutover | Pending | DNS switch to production |

## Migration Artifacts

| Artifact | File | Purpose |
|----------|------|---------|
| Task Definition | `thetransitionthinktank_task_definition.json` | ECS Fargate task definition for DEV |
| Pre-flight Checklist | `thetransitionthinktank_preflight_checklist.md` | Complete migration checklist with execution order |
| URL Replacement SQL | `database/url-replacement.sql` | Domain swap for all WP tables + Yoast + Elementor |
| Encoding Fix SQL | `database/fix-encoding.sql` | Fix UTF-8 encoding artifacts if they appear |
| Integration Inventory | `thetransitionthinktank_integration_inventory.md` | All third-party services and reconfiguration needs |
| PROD Analysis | `thetransitionthinktank_site_analysis_2026-01-29.md` | Baseline analysis of live production site |

## Target Environment

- **DEV:** `thetransitionthinktank.wpdev.kimmyai.io`
- **SIT:** `thetransitionthinktank.wpsit.kimmyai.io`

## Site Navigation Map (from PROD analysis)

```
Home (/)
├── About Us (/about-us/)
│   ├── #who-we-are
│   ├── #our-vision-and-mission
│   ├── #our-values
│   └── #our-team
├── Our Offerings (/our-offerings/)
│   ├── Transition Planning (/transition-planning/)
│   ├── Green Economy (/green-economy/)
│   └── Value Management (/value-management/)
├── Media Portal (/media-portal/)
│   ├── Blog (/category/blog/)
│   ├── Events (/category/events/)
│   ├── Press Releases (/category/press-releases/)
│   ├── Case Studies (/category/case-studies/)
│   └── Gallery (/gallery/)
├── Careers (/careers/)
├── Contact Us (/contact-us/)
└── Privacy Policy (/privacy-policy/)
```

## Root Workflow Inheritance

This project inherits TBT mechanism and all workflow standards from the parent CLAUDE.md:

{{include:../CLAUDE.md}}
