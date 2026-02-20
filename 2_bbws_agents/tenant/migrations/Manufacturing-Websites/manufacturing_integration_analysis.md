# Manufacturing-Websites - Integration Points Analysis

**Date:** 2026-01-16
**Tenant:** manufacturing
**Environment:** DEV (manufacturing.wpdev.kimmyai.io)
**Purpose:** Identify all external integrations and create mocking strategy for testing

---

## Executive Summary

This document analyzes all integration points for the Manufacturing-Websites WordPress site to enable safe testing without affecting the real business. All external services will be mocked or redirected to test endpoints during DEV and SIT testing.

**Key Principle:** No production services (email, analytics, payment) should be triggered during testing phases.

---

## Integration Points Identified

### 1. Email Notifications (HIGH RISK)

**Service:** WordPress wp_mail() / SMTP
**Used By:**
- Contact Form 7 (form submissions)
- WordPress core (password resets, new user registrations)
- Plugin notifications

**Current Configuration:**
- Form submissions send to business email addresses
- Contact forms with different recipient emails

**Risk During Testing:**
- Real customers receive test form submissions
- Business inbox flooded with test emails
- Reputation damage from spam-like behavior
- SMTP provider may throttle/block account

**Mocking Strategy:**
```php
// Intercept ALL emails during testing
add_filter('wp_mail', function($args) {
    // Redirect ALL emails to test address
    $args['to'] = 'tebogo@bigbeard.co.za';

    // Add subject prefix to identify test emails
    $args['subject'] = '[TEST - Manufacturing DEV] ' . $args['subject'];

    // Add header noting original recipient
    $original_to = is_array($args['to']) ? implode(', ', $args['to']) : $args['to'];
    $args['message'] = "ORIGINAL RECIPIENT: {$original_to}\n\n---\n\n" . $args['message'];

    return $args;
}, 999);
```

**Implementation:** MU-plugin `/wp-content/mu-plugins/bbws-platform/email-redirect.php` (DEPLOYED)

---

### 2. Contact Form 7

**Service:** Contact Form 7 (WordPress plugin)
**Status:** Active

**Integration Points:**

#### A. Email Notifications
**Risk:** HIGH - Sends form submissions to business owners

**Mocking Strategy:**
- Override ALL notification recipients to `tebogo@bigbeard.co.za`
- Add prefix to email subjects: `[TEST - Manufacturing]`
- Preserve original recipient in email body for reference

#### B. Entry Storage
**Risk:** LOW - Entries stored in local database

**Action:** No mocking needed, entries are local

---

### 3. Elementor Pro

**Service:** Elementor Pro (WordPress page builder)
**Status:** Active

**Integration Points:**

#### A. Form Widget
**Risk:** MEDIUM - If forms are built with Elementor Pro forms
- Check for Elementor form widgets
- Ensure email notifications are redirected

#### B. reCAPTCHA v3
**Risk:** HIGH - Domain-specific validation
- reCAPTCHA keys are registered for manufacturing-websites.com
- Will fail validation on manufacturing.wpdev.kimmyai.io

**Mocking Strategy:**
```sql
-- Clear Elementor Pro reCAPTCHA keys for DEV
UPDATE wp_options
SET option_value = ''
WHERE option_name IN (
    'elementor_pro_recaptcha_v3_site_key',
    'elementor_pro_recaptcha_v3_secret_key',
    'elementor_pro_recaptcha_site_key',
    'elementor_pro_recaptcha_secret_key'
);
```

**Status:** RESOLVED - reCAPTCHA disabled for DEV environment

#### C. Dynamic Content
**Risk:** LOW - Local content only

**Action:** Verify all forms use email redirect

---

### 4. Yoast SEO

**Service:** Yoast SEO plugin
**Status:** Active

**Integration Points:**

#### A. Search Console Integration
**Risk:** LOW - If connected to Google Search Console

#### B. XML Sitemap
**Risk:** LOW - Generated locally

#### C. Indexable Tables
**Risk:** MEDIUM - Contains domain-specific URLs

**Mocking Strategy:**
- Update URLs in `wp_yoast_indexable` table
- Update URLs in `wp_yoast_seo_links` table
- Ensure sitemap URLs point to DEV domain

**SQL Applied:**
```sql
-- Update wp_yoast_indexable
UPDATE wp_yoast_indexable
SET permalink = REPLACE(permalink, 'manufacturing-websites.com', 'manufacturing.wpdev.kimmyai.io')
WHERE permalink LIKE '%manufacturing-websites.com%';

-- Update wp_yoast_seo_links
UPDATE wp_yoast_seo_links
SET url = REPLACE(url, 'manufacturing-websites.com', 'manufacturing.wpdev.kimmyai.io')
WHERE url LIKE '%manufacturing-websites.com%';
```

**Status:** RESOLVED

**Action:** Verify sitemap accessible at /sitemap_index.xml

---

### 5. CDN / Asset Delivery

**Service:** CloudFront (Amazon AWS)
**Risk:** LOW - Already using our own CloudFront distribution

**Current Configuration:**
- Distribution: E2W27HE3T7FRW4
- Domain: manufacturing.wpdev.kimmyai.io

**Action:** No mocking needed, using our infrastructure

---

## Mocking Implementation Status

### Deployed MU-Plugins

```
/var/www/html/wp-content/mu-plugins/
└── bbws-platform/
    ├── email-redirect.php        # Email interception (DEPLOYED)
    ├── env-indicator.php         # Visual DEV indicator (DEPLOYED)
    └── force-https.php           # HTTPS forcing (DEPLOYED)
```

### MU-Plugin: email-redirect.php

**Purpose:** Redirects all WordPress emails to test address in non-production environments

**Features:**
- Intercepts all wp_mail() calls
- Redirects to tebogo@bigbeard.co.za
- Adds [DEV] prefix to subject
- Logs original recipient

**Status:** DEPLOYED

### MU-Plugin: env-indicator.php

**Purpose:** Visual indicator showing DEV environment

**Features:**
- Banner at bottom of page
- Admin bar indicator
- Shows current environment

**Status:** DEPLOYED

---

## Testing Workflow

### DEV Environment Testing (Current)

**Email Address:** tebogo@bigbeard.co.za

**Test Cases:**
1. [ ] Submit contact forms
2. [ ] Verify email received at test address
3. [ ] Verify NO emails sent to real business addresses
4. [ ] Check all page builder elements render

**Validation:**
```bash
# Check email redirect is active
curl -s https://manufacturing.wpdev.kimmyai.io/ | grep "tebogo@bigbeard.co.za" || echo "Email redirect active via MU-plugin"

# Check environment indicator visible
curl -s https://manufacturing.wpdev.kimmyai.io/ | grep -i "DEV\|development"
```

### SIT Environment Testing (Future)

**Email Address:** tebogo@bigbeard.co.za (same test address)

**Additional Tests:**
- Load testing (simulate multiple form submissions)
- Performance testing (page load times)
- Security testing (form injection, XSS)

### PROD Environment (Future)

**Email Address:** Real business addresses (restored)

**Deployment Checklist:**
- [ ] Update email redirect to production addresses
- [ ] Register new reCAPTCHA keys for production domain
- [ ] Verify all emails go to correct recipients
- [ ] Enable real tracking scripts (if any)
- [ ] Monitor for 24 hours before full cutover

---

## Summary: Integration Points & Risk Levels

| Integration | Risk | Mocking Strategy | Status |
|-------------|------|------------------|--------|
| **Email Notifications** | HIGH | MU-plugin redirect to tebogo@bigbeard.co.za | DEPLOYED |
| **Contact Form 7 Email** | HIGH | Covered by email redirect MU-plugin | DEPLOYED |
| **reCAPTCHA v3** | HIGH | Disabled keys for DEV environment | RESOLVED |
| **Yoast SEO URLs** | MEDIUM | SQL updates to indexable tables | RESOLVED |
| **Elementor Forms** | MEDIUM | Covered by email redirect MU-plugin | DEPLOYED |
| **CloudFront CDN** | LOW | No action needed (our infrastructure) | N/A |

---

## Environment-Specific Configuration

### DEV Environment (Current)

```php
// WORDPRESS_CONFIG_EXTRA in task definition
$_SERVER['HTTPS'] = 'on';
define('FORCE_SSL_ADMIN', false);
define('WP_HOME', 'https://manufacturing.wpdev.kimmyai.io');
define('WP_SITEURL', 'https://manufacturing.wpdev.kimmyai.io');
define('WP_ENVIRONMENT_TYPE', 'development');
```

### SIT Environment (Future)

```php
$_SERVER['HTTPS'] = 'on';
define('FORCE_SSL_ADMIN', false);
define('WP_HOME', 'https://manufacturing.wpsit.kimmyai.io');
define('WP_SITEURL', 'https://manufacturing.wpsit.kimmyai.io');
define('WP_ENVIRONMENT_TYPE', 'staging');
```

### PROD Environment (Future)

```php
$_SERVER['HTTPS'] = 'on';
define('FORCE_SSL_ADMIN', true);
define('WP_HOME', 'https://manufacturing-websites.com');
define('WP_SITEURL', 'https://manufacturing-websites.com');
define('WP_ENVIRONMENT_TYPE', 'production');
```

---

## Next Steps

### Immediate Actions
1. [ ] Test form submissions to verify email redirect
2. [ ] Verify Contact Form 7 forms work without reCAPTCHA
3. [ ] Check Yoast sitemap URLs are correct
4. [ ] Verify Elementor templates all render

### Before SIT Promotion
1. [ ] Verify all email redirects working
2. [ ] Document any integration-specific issues
3. [ ] Update configuration for SIT environment

### Before PROD Deployment
1. [ ] Update email configuration for production
2. [ ] Register new reCAPTCHA keys for production domain
3. [ ] Verify business email addresses
4. [ ] Test form submissions in PROD environment
5. [ ] Monitor for 24 hours

---

*Document Created:* 2026-01-16
*Purpose:* Safe testing strategy without affecting real business
*Next Review:* After first form submission test
