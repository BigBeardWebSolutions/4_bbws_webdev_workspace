# beautybuy - WordPress Migration

## Site Information

| Property | Value |
|----------|-------|
| **Tenant Name** | beautybuy |
| **Source Domain** | beautybuy.co.za |
| **Target Domain (DEV)** | beautybuy.wpdev.kimmyai.io |
| **Target Domain (SIT)** | beautybuy.wpsit.kimmyai.io |
| **Source Hosting** | Xneelo (dedi232.cpt3.host-h.net) |
| **CloudFront Status** | Pending |
| **Certificate Status** | Pending |

## Site Profile (Phase 0 Discovery)

| Property | Value |
|----------|-------|
| **Site Title** | BeautyBuy |
| **Theme** | Divi (beauty-buy child theme) |
| **Page Builder** | Divi Builder |
| **Table Prefix** | wp_ |
| **Database Size** | 2.7MB |
| **wp-content Size** | 293MB |
| **Total Site Size** | 355MB |
| **Transfer Method** | Direct bastion (< 500MB) |
| **WooCommerce** | Yes (active e-commerce) |

### Active Plugins

| Plugin | Risk Level | Migration Action |
|--------|------------|------------------|
| really-simple-ssl | **HIGH** | DEACTIVATE via prepare script |
| woocommerce | Low | Keep - core functionality |
| yoco-payment-gateway | Medium | Disable in DEV (payment gateway) |
| wordpress-seo (Yoast) | Low | Keep - URL replacement needed in yoast tables |
| ajax-search-for-woocommerce | Low | Keep |
| beautiful-taxonomy-filters | Low | Keep |
| better-search-replace | Low | Keep |
| custom-post-type-ui | Low | Keep |
| duplicate-post | Low | Keep |
| forms-for-campaign-monitor | Medium | Review in DEV |
| google-analytics-for-wordpress | Medium | Disable tracking in DEV |
| hummingbird-performance | Low | Keep |
| under-construction-page | Low | Deactivate in DEV |
| worker | Low | Keep (ManageWP) |
| wp-smushit | Low | Keep |

## Migration Status

- [x] **Phase 0: Discovery** - Site files analyzed, profile created
- [ ] **Phase 0.5: Fix Database** - Run prepare-wordpress-for-migration.sh
- [ ] **Phase 1: Provision Tenant** - ECS service, ALB, RDS database, EFS, Secrets
- [ ] **Phase 2: Direct Upload** - Upload via bastion (SSM port forwarding)
- [ ] **Phase 3: Import Database** - Import fixed SQL to RDS
- [ ] **Phase 4: Configure** - MU-plugins, URL replacement, Divi cache clear
- [ ] **Phase 5: Validation** - Test site loads, WooCommerce pages, no redirect loop

## Files Location

| Type | Location |
|------|----------|
| **Source Files** | `/Users/sithembisomjoko/Downloads/Friday-Migrated-Sites-06022026/beautybuy/` |
| **wp-content** | Source: `wp-content/` (full WordPress install, only wp-content needed) |
| **Database (Original)** | `database/dedi232_cpt3_host-h_net.sql` |
| **Database (Fixed)** | `database/beautybuy-db-fixed.sql` |

## Special Considerations

- **WooCommerce site** - needs higher ECS resources (1024 CPU / 2048 memory)
- **Divi theme** - needs `max_input_vars=3000+`, clear et-cache after migration
- **really-simple-ssl** - MUST deactivate before import to prevent redirect loop
- **yoco-payment-gateway** - South African payment gateway, disable in DEV
- **ai1wm-backups** in wp-content can be excluded from migration
- **et-cache** in wp-content can be excluded (will regenerate)
- **CloudFront cookie whitelist** must include `woocommerce_*` for cart/checkout

## Root Workflow Inheritance

This project inherits TBT mechanism and all workflow standards from the parent CLAUDE.md:

{{include:../../CLAUDE.md}}
