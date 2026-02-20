# ManagedIS Integration Analysis

**Site:** managedis.personalinvest.co.za
**Date:** 2026-01-22
**Status:** Analysis Complete
**Author:** Tenant Manager Agent

---

## Overview

This document analyzes the ManagedIS WordPress site's integrations, plugins, and configurations to identify migration considerations and potential issues.

---

## Plugin Analysis

### Active Plugins (17 Total)

#### Core Functionality Plugins

| Plugin | Version | Risk | Migration Notes |
|--------|---------|------|-----------------|
| **contact-form-7** | - | Low | Standard form plugin, should work without changes |
| **contact-form-7-honeypot** | - | Low | Anti-spam extension, compatible |
| **cookie-law-info** | - | Low | GDPR compliance, may need re-configuration |
| **duplicate-post** | - | Low | Content management, no migration issues |
| **redirection** | - | Low | URL redirects - review rules post-migration |

#### Theme-Related Plugins

| Plugin | Version | Risk | Migration Notes |
|--------|---------|------|-----------------|
| **uncode-core** | - | Low | Required for Uncode theme functionality |
| **uncode-js_composer** | - | Medium | Visual Composer bundled with Uncode |
| **vc_clipboard** | - | Low | VC extension for copy/paste |

#### SEO & Performance Plugins

| Plugin | Version | Risk | Migration Notes |
|--------|---------|------|-----------------|
| **smartcrawl-seo** | - | Low | WPMU DEV SEO plugin |
| **wordpress-seo** | - | Low | Yoast SEO - potential conflict with SmartCrawl |
| **hummingbird-performance** | - | Low | Caching - may need reconfiguration |
| **wp-smushit** | - | Low | Image optimization |

#### Security & Maintenance Plugins

| Plugin | Version | Risk | Migration Notes |
|--------|---------|------|-----------------|
| **wordfence** | - | Medium | Firewall rules may block new IPs |
| **mainwp-child** | - | Medium | Needs MainWP server reconfiguration |

#### High-Risk Plugins

| Plugin | Version | Risk | Migration Notes |
|--------|---------|------|-----------------|
| **ldap-login-for-intranet-sites** | - | **HIGH** | LDAP authentication will NOT work in AWS. Must deactivate. |
| **wp-mail-smtp** | - | Medium | Email configuration required for AWS SES |

#### Utility Plugins

| Plugin | Version | Risk | Migration Notes |
|--------|---------|------|-----------------|
| **favicon-by-realfavicongenerator** | - | Low | Static assets, no issues |
| **taxonomy-terms-order** | - | Low | Term ordering, no issues |
| **wpfront-notification-bar** | - | Low | UI notification, no issues |
| **graviton-post-importer** | - | Low | Custom content importer |

---

## Theme Analysis

### Active Theme: Uncode

| Property | Value |
|----------|-------|
| **Theme Name** | Uncode |
| **Child Theme** | uncode-child |
| **Page Builder** | Visual Composer/WPBakery (bundled) |
| **PHP Memory Requirement** | 512M minimum |
| **License Type** | Envato (ThemeForest) |

### Theme Considerations

1. **Memory Requirements**: Uncode is memory-intensive. Must set `memory_limit = 512M` in PHP configuration.

2. **Visual Composer Shortcodes**: May appear as raw shortcodes on archive/search pages. Common issue with VC-based themes.

3. **Child Theme**: Using `uncode-child` - customizations preserved in child theme.

4. **License Verification**: May require Envato Purchase Code for theme updates. Not critical for migration.

---

## Database Analysis

### Table Prefix
- **Prefix**: `wp_` (standard)

### Database Size
- **Total Size**: 13.6 MB

### Key Observations

1. **WooCommerce References**: 766 occurrences found in database
   - May be from deactivated WooCommerce installation
   - May be from imported content with WC shortcodes
   - **Action**: Monitor for errors, clean if needed

2. **Multiple Domain References**:
   - Primary: `https://managedis.personalinvest.co.za` (1924 occurrences)
   - HTTP version: `http://managedis.personalinvest.co.za` (581)
   - Admin domain: `http://managedis-adm.personalinvest.co.za` (515)
   - **Action**: Run search-replace for all variants

3. **Cross-Site References**:
   - gravitonperspectives.co.za (792 occurrences)
   - jblwealth.personalinvest.co.za (276 occurrences)
   - **Action**: These may be from shared plugins/templates, leave as-is

---

## External Integrations

### Email Configuration
- **Current**: wp-mail-smtp plugin installed
- **Target**: AWS SES or alternative SMTP
- **Test Email**: tebogo@bigbeard.co.za
- **Action Required**: Configure SMTP settings post-migration

### Authentication
- **Current**: LDAP Login for Intranet Sites
- **Target**: Standard WordPress authentication
- **Action Required**: Deactivate LDAP plugin, create local admin accounts

### CDN/Caching
- **Current**: Hummingbird Performance
- **Target**: CloudFront CDN
- **Action**: May need to reconfigure caching rules

### Monitoring
- **Current**: MainWP Child
- **Target**: Reconfigure or disable
- **Action**: Update MainWP server configuration or deactivate

---

## Pre-Migration Actions Required

### Must Do Before Migration

1. **Deactivate LDAP Plugin** (via database)
   ```sql
   UPDATE wp_options SET option_value = REPLACE(option_value, 'ldap-login-for-intranet-sites/wpldaplogin.php', '') WHERE option_name = 'active_plugins';
   ```

2. **Verify Admin Accounts** exist that don't rely on LDAP

3. **Note Current Settings** for wp-mail-smtp reconfiguration

### Post-Migration Configuration

1. Configure wp-mail-smtp with AWS SES credentials
2. Review Wordfence firewall settings
3. Test all contact forms
4. Verify redirection plugin rules
5. Clear all caches

---

## Risk Assessment Summary

| Category | Risk Level | Mitigation |
|----------|------------|------------|
| Authentication | **High** | Deactivate LDAP, verify local admins |
| Theme Compatibility | Medium | Set PHP memory 512M |
| Email Delivery | Medium | Configure SMTP early |
| Security Plugins | Medium | Review Wordfence rules |
| SEO | Low | Verify settings post-migration |
| Forms | Low | Test all forms |

---

## Recommended Migration Order

1. ✅ Complete discovery and documentation
2. Upload files to S3
3. Create tenant environment
4. Import database
5. **Deactivate LDAP plugin via database**
6. Run URL replacements
7. Sync files to EFS
8. Configure email (wp-mail-smtp)
9. Test authentication
10. Run full validation

---

**Document Version:** 1.0
**Last Updated:** 2026-01-22
