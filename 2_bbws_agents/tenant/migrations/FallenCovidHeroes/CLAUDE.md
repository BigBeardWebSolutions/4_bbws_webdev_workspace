# FallenCovidHeroes Migration - Project Overview

## Site Information

| Property | Value |
|----------|-------|
| **Tenant Name** | FallenCovidHeroes |
| **Source Domain** | fallencovidheroes.co.za |
| **Target Domain (DEV)** | fallencovidheroes.wpdev.kimmyai.io |
| **Source Hosting** | Xneelo (197.221.10.19) |
| **CloudFront Status** | Ready (E2PH07NKXVPN1C) |
| **Certificate Status** | ISSUED |

## Site Profile (Phase 0 Discovery)

| Property | Value |
|----------|-------|
| **Site Title** | Hospital Association South Africa |
| **Theme** | Divi (child theme: fallen-heroes) |
| **Table Prefix** | wp_ |
| **Database Size** | 3.7MB |
| **wp-content Size** | 248MB |
| **WooCommerce** | Minimal (4 references, not actively used) |

### Active Plugins (Post-Fix)

| Plugin | Status |
|--------|--------|
| `really-simple-ssl` | **DEACTIVATED** (causes redirect loop) |
| `ssl-insecure-content-fixer` | Active (monitor for issues) |
| `revslider` | Active |
| `wordpress-seo` | Active |
| `classic-editor` | Active |
| `duplicate-post` | Active |
| `better-search-replace` | Active |
| `all-in-one-wp-migration` | Active |

## Migration Status

**Current State: SUSPENDED** (ECS service desired count = 0)

- [x] **Phase 0: Export** - Database and files exported from Xneelo
- [x] **Phase 0.5: Fix Database** - Problematic plugins deactivated
- [x] **Phase 0.6: Fix RevSlider Shortcode** - URL-encoded shortcode characters decoded (39 occurrences)
- [x] **Phase 1: Provision Tenant** - ECS service, ALB target group, RDS database
- [x] **Phase 2: Direct Upload** - Upload via bastion
- [x] **Phase 3: Import Database** - Import fixed SQL to RDS
- [ ] **Phase 4: Configure** - MU-plugin, URL replacement (BLOCKED - redirect loop)
- [ ] **Phase 5: Validation** - Test site loads without redirect loop

### Suspension Details (2026-01-29)
- **Reason**: Redirect loop preventing site access
- **Action**: ECS service `dev-fallencovidheroes-service` set to desired count 0
- **Infrastructure preserved**: Service, target group, RDS database all intact
- **To resume**: Set desired count back to 1

## Files Location

| Type | Location |
|------|----------|
| **Site Files** | `/Users/sithembisomjoko/Documents/Friday-Migration-Sites-23012026/fallencovidheroes/wp-content/` |
| **Database (Original)** | `database/wordpress-db-20260123_143102.sql` |
| **Database (Fixed)** | `database/wordpress-db-properly-fixed.sql` ✅ |

## Migration Approach

**Direct Bastion Upload** (not S3) due to connection timeout issues with S3.

Files will be:
1. Copied to bastion via SSM Session Manager port forwarding
2. Transferred to EFS from bastion
3. Database imported directly to RDS from bastion

## Special Considerations

- Small site (~3.7MB database, 248MB files)
- Uses Really Simple SSL (deactivated in fixed database)
- Uses ssl-insecure-content-fixer (may need monitoring)
- Divi theme - standard WordPress migration
- Good test candidate for migration fix scripts
- **RevSlider shortcode fix applied** - URL-encoded characters (`%91`, `%93`, `%22`) decoded to proper shortcode brackets and quotes (39 occurrences fixed)

## Root Workflow Inheritance

This project inherits TBT mechanism from parent CLAUDE.md:

{{include:../CLAUDE.md}}
