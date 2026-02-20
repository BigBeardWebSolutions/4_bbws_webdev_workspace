# CaseForward Migration - Project Overview

## Site Information

| Property | Value |
|----------|-------|
| **Tenant Name** | CaseForward |
| **Source Domain** | caseforward.org |
| **Target Domain (DEV)** | caseforward.wpdev.kimmyai.io |
| **Target Domain (SIT)** | caseforward.wpsit.kimmyai.io |
| **Source Hosting** | Xneelo (dedi111.cpt3.host-h.net) |
| **CloudFront Status** | Pending |
| **Certificate Status** | Pending |

## Site Profile (Phase 0 Discovery)

| Property | Value |
|----------|-------|
| **Site Title** | CaseForward |
| **Theme** | hello-elementor (child: hello-theme-child-master) |
| **Page Builder** | Elementor Pro |
| **Table Prefix** | wp_ |
| **Database Size** | 21MB |
| **Total Site Size** | 452MB |
| **Transfer Method** | Direct bastion (< 500MB) |

### Active Plugins

| Plugin | Risk Level | Migration Action |
|--------|------------|------------------|
| `really-simple-ssl` | **HIGH** | DEACTIVATE (causes redirect loop) |
| `wordfence` | **HIGH** | DEACTIVATE (causes issues) |
| `elementor` | Low | Keep active |
| `elementor-pro` | Low | Keep active |
| `gravityforms` | Medium | Reconfigure reCAPTCHA for DEV domain |
| `gravityformsrecaptcha` | Medium | Reconfigure for DEV domain |
| `advanced-custom-fields` | Low | Keep active |
| `complianz-gdpr` | Low | Keep active |
| `duplicate-post` | Low | Keep active |
| `wordpress-seo` | Low | Keep active |
| `wp-fastest-cache` | Low | Clear cache post-migration |
| `wp-mail-smtp` | Medium | Redirect emails to tebogo@bigbeard.co.za |
| `wp-security-audit-log` | Low | Keep active |

### Installed Themes

- hello-elementor
- hello-theme-child-master
- twentytwentyfive
- twentytwentyfour
- twentytwentythree

## Migration Status

- [x] **Phase 0: Export** - Database and files exported from Xneelo (2026-01-23)
- [x] **Phase 0.5: Fix Database** - Pending (prepare-wordpress-for-migration.sh)
- [ ] **Phase 1: Provision Tenant** - ECS service, ALB target group, RDS database
- [ ] **Phase 2: Direct Upload** - Upload via bastion (< 500MB, direct method)
- [ ] **Phase 3: Import Database** - Import fixed SQL to RDS
- [ ] **Phase 4: Configure** - MU-plugin, URL replacement
- [ ] **Phase 5: Validation** - Test site loads without redirect loop

## Files Location

| Type | Location |
|------|----------|
| **Site Files (Source)** | `/Users/sithembisomjoko/Documents/Friday-Migration-Sites-23012026/caseforward/wp-content/` |
| **Database (Original)** | `database/wordpress-db-20260123_145109.sql` |
| **Database (Fixed)** | `database/wordpress-db-fixed.sql` (pending) |
| **Export Notes** | `database/EXPORT-NOTES-20260123_145109.txt` |

## Migration Approach

**Direct Bastion Upload** - Site is 452MB (under 500MB threshold).

Files will be:
1. Tarred from source wp-content directory
2. Copied to bastion via SSM Session Manager port forwarding
3. Transferred to EFS from bastion
4. Database imported directly to RDS from bastion

## Special Considerations

- Uses Elementor Pro - check template status post-migration
- GravityForms with reCAPTCHA - needs domain-specific reconfiguration
- Really Simple SSL and Wordfence must be deactivated before import
- wp-fastest-cache should be cleared after migration
- wp-mail-smtp should redirect to test email

## Root Workflow Inheritance

This project inherits TBT mechanism from parent CLAUDE.md:

{{include:../CLAUDE.md}}
