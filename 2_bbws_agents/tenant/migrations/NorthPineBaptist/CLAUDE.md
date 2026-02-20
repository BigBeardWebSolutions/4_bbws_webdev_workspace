# NorthPineBaptist Migration - Project Overview

## Site Information

| Property | Value |
|----------|-------|
| **Tenant Name** | NorthPineBaptist |
| **Source Domain** | www.northpinebaptist.co.za |
| **Target Domain (DEV)** | northpinebaptist.wpdev.kimmyai.io |
| **Target Domain (SIT)** | northpinebaptist.wpsit.kimmyai.io |
| **Source Hosting** | Xneelo (dedi111.cpt3.host-h.net) |
| **CloudFront Status** | Pending |
| **Certificate Status** | Pending |

## Site Profile (Phase 0 Discovery)

| Property | Value |
|----------|-------|
| **Site Title** | NorthPineBaptist |
| **Theme** | hello-elementor (child: hello-elementor-child) |
| **Page Builder** | Elementor Pro |
| **Table Prefix** | wp_ |
| **Database Size** | 29MB |
| **Total Site Size** | 2.1GB |
| **Transfer Method** | S3 staging (> 500MB) |

### Active Plugins

| Plugin | Risk Level | Migration Action |
|--------|------------|------------------|
| `really-simple-ssl` | **HIGH** | DEACTIVATE (causes redirect loop) |
| `wordfence` | **HIGH** | DEACTIVATE (causes issues) |
| `elementor` | Low | Keep active |
| `elementor-pro` | Low | Keep active |
| `gravityforms` | Medium | Reconfigure reCAPTCHA for DEV domain |
| `advanced-custom-fields` | Low | Keep active |
| `custom-post-type-ui` | Low | Keep active |
| `ele-custom-skin` | Low | Keep active |
| `classic-editor` | Low | Keep active |
| `duplicate-post` | Low | Keep active |
| `wordpress-seo` | Low | Keep active |
| `wp-fastest-cache` | Low | Clear cache post-migration |
| `under-construction-page` | Low | Deactivate post-migration |
| `all-in-one-wp-migration` | Low | Keep active |
| `all-in-one-wp-migration-pro` | Low | Keep active |

### Installed Themes

- hello-elementor
- hello-elementor-child
- twentytwentyfive
- twentytwentyfour

## Migration Status

- [x] **Phase 0: Export** - Database and files exported from Xneelo (2026-01-23)
- [ ] **Phase 0.5: Fix Database** - Run prepare-wordpress-for-migration.sh
- [ ] **Phase 1: Provision Tenant** - ECS service, ALB target group, RDS database
- [ ] **Phase 2: S3 Upload** - Upload via S3 staging (> 500MB, 2.1GB total)
- [ ] **Phase 3: Import Database** - Import fixed SQL to RDS
- [ ] **Phase 4: Configure** - MU-plugin, URL replacement
- [ ] **Phase 5: Validation** - Test site loads without redirect loop

## Files Location

| Type | Location |
|------|----------|
| **Site Files (Source)** | `/Users/sithembisomjoko/Documents/Friday-Migration-Sites-23012026/northpinebaptist/wp-content/` |
| **Database (Original)** | `database/wordpress-db-20260123_150801.sql` |
| **Database (Fixed)** | `database/wordpress-db-fixed.sql` (pending) |
| **Export Notes** | `database/EXPORT-NOTES-20260123_150801.txt` |

## Migration Approach

**S3 Staging** - Site is 2.1GB (well over 500MB threshold).

Files will be:
1. Tarred from source wp-content directory
2. Uploaded to S3 migration bucket: `s3://wordpress-migration-temp-20250903/northpinebaptist/`
3. Downloaded from S3 to bastion
4. Transferred to EFS from bastion
5. Database imported directly to RDS from bastion

## Special Considerations

- **Largest site** in this batch at 2.1GB - S3 upload may take significant time
- Really Simple SSL and Wordfence must be deactivated before import
- Has `wordfence-waf.php` in root - do NOT copy this to the migration
- Has existing DEV folder (`dev.northpinebaptist.co.za`) - reference only
- Uses `under-construction-page` plugin - should be deactivated post-migration
- GravityForms needs domain-specific reCAPTCHA reconfiguration
- wp-fastest-cache should be cleared after migration
- wp-content contains backup files (Archive.zip, Archive_zip_0, Archive_zip_1, Churchope-backups, ai1wm-backups) - exclude from migration to save space
- URL replacement must handle both `www.northpinebaptist.co.za` and `northpinebaptist.co.za`

## Root Workflow Inheritance

This project inherits TBT mechanism from parent CLAUDE.md:

{{include:../CLAUDE.md}}
