# TheTippingPoint - Migration Project

## Project Purpose

Migrate the TheTippingPoint WordPress website from Xneelo hosting to the BBWS multi-tenant AWS hosting platform.

## Site Profile

| Field | Value |
|-------|-------|
| **Production Domain** | `http://www.thetippingpoint.co.za` |
| **Table Prefix** | `wp_` |
| **Database File** | `database/thetippingpoint.sql` (~2.9MB) |
| **Site Files** | **INCOMPLETE** - Static landing page only, NO wp-content |
| **Total Size** | ~19MB (without WordPress files) |
| **Transfer Method** | Direct bastion (< 500MB) |

## CRITICAL ISSUE: Missing WordPress Files

The source export from Xneelo contains ONLY:
- A static HTML/PHP landing page (css/, js/, images/, fonts/)
- Database backup (4 duplicate copies - only 1 kept)
- `.htaccess` file

**MISSING:**
- `wp-content/` (themes, plugins, uploads)
- `wp-admin/`
- `wp-includes/`
- `wp-config.php`

**Action Required:** WordPress site files must be re-exported from the source hosting before migration can proceed.

## Source Information

- **Source Location:** `/Users/sithembisomjoko/Documents/Monday - Migration - Sites 26012026/thetippingpoint/`
- **Database Name (from export):** `dedi232_cpt3_host-h_net`
- **Original SQL Files:** 4 duplicate copies of `dedi232_cpt3_host-h_net (1-4).sql`

## Directory Structure

```
TheTippingPoint/
├── CLAUDE.md           # This file
├── .claude/            # TBT workflow files
├── site/               # EMPTY - awaiting WordPress files
└── database/
    └── thetippingpoint.sql  # Database backup (~2.9MB)
```

## Migration Status

| Phase | Status |
|-------|--------|
| Export | **BLOCKED** - WordPress files missing |
| Database Fix | Pending |
| Staging | Pending |
| Provision | Pending |
| Import | Pending |
| Configure | Pending |
| Validate | Pending |
| Cutover | Pending |

## Target Environment

- **DEV:** `thetippingpoint.wpdev.kimmyai.io`
- **SIT:** `thetippingpoint.wpsit.kimmyai.io`

## Root Workflow Inheritance

This project inherits TBT mechanism and all workflow standards from the parent CLAUDE.md:

{{include:../CLAUDE.md}}
