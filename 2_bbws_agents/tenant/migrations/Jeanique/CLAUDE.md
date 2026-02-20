# Jeanique Migration - Project Overview

## Site Information

| Property | Value |
|----------|-------|
| **Tenant Name** | Jeanique |
| **Source Domain** | jeanique.co.za/jeanique |
| **Source Root Domain** | jeanique.co.za |
| **Target Domain (DEV)** | jeanique.wpdev.kimmyai.io |
| **Target Domain (SIT)** | jeanique.wpsit.kimmyai.io |
| **Source Hosting** | Xneelo (dedi111.cpt3.host-h.net) |
| **CloudFront Status** | Pending |
| **Certificate Status** | Pending |

## Site Profile (Phase 0 Discovery)

| Property | Value |
|----------|-------|
| **Site Title** | Jeanique |
| **Theme** | bridge (child: bridge-child) |
| **Page Builder** | Elementor Pro + Bridge Core |
| **Table Prefix** | wp_ |
| **Database Size** | 29MB |
| **Total Site Size** | 835MB |
| **Transfer Method** | S3 staging (> 500MB) |
| **DB Charset** | utf8mb4 |

### Active Plugins

| Plugin | Risk Level | Migration Action |
|--------|------------|------------------|
| `bridge-core` | Low | Keep active (theme dependency) |
| `classic-editor` | Low | Keep active |
| `classic-widgets` | Low | Keep active |
| `contact-form-7` | Low | Keep active |
| `duplicate-post` | Low | Keep active |
| `elementor` | Low | Keep active |
| `elementor-pro` | Low | Keep active |
| `envato-market` | Low | Keep active |
| `flamingo` | Low | Keep active |
| `revslider` | Medium | Keep active (may need license) |
| `wordpress-seo` | Low | Keep active |
| `worker` | Low | Keep active |

### Installed Themes

- bridge
- bridge-child

## Migration Status

- [x] **Phase 0: Export** - Database and files exported from Xneelo (2026-01-23)
- [ ] **Phase 0.5: Fix Database** - Run prepare-wordpress-for-migration.sh
- [ ] **Phase 1: Provision Tenant** - ECS service, ALB target group, RDS database
- [ ] **Phase 2: S3 Upload** - Upload via S3 staging (> 500MB)
- [ ] **Phase 3: Import Database** - Import fixed SQL to RDS
- [ ] **Phase 4: Configure** - MU-plugin, URL replacement
- [ ] **Phase 5: Validation** - Test site loads without redirect loop

## Files Location

| Type | Location |
|------|----------|
| **Site Files (Source)** | `/Users/sithembisomjoko/Documents/Friday-Migration-Sites-23012026/jeanique/wp-content/` |
| **Database (Original)** | `database/wordpress-db-20260123_145756.sql` |
| **Database (Fixed)** | `database/wordpress-db-fixed.sql` (pending) |
| **Export Notes** | `database/EXPORT-NOTES-20260123_145756.txt` |

## Migration Approach

**S3 Staging** - Site is 835MB (over 500MB threshold).

Files will be:
1. Tarred from source wp-content directory
2. Uploaded to S3 migration bucket: `s3://wordpress-migration-temp-20250903/jeanique/`
3. Downloaded from S3 to bastion
4. Transferred to EFS from bastion
5. Database imported directly to RDS from bastion

## Special Considerations

- **SUBPATH URL**: Original site uses `jeanique.co.za/jeanique` subpath
  - URL replacement must handle BOTH:
    - `jeanique.co.za/jeanique` → `jeanique.wpdev.kimmyai.io`
    - `jeanique.co.za` → `jeanique.wpdev.kimmyai.io`
  - Order matters: Replace subpath version FIRST, then root domain
- Bridge theme - premium theme, may require Envato purchase code
- RevSlider - may need license verification
- Uses utf8mb4 charset (ensure RDS supports it)
- No really-simple-ssl or wordfence installed (cleaner migration)

## Root Workflow Inheritance

This project inherits TBT mechanism from parent CLAUDE.md:

{{include:../CLAUDE.md}}
