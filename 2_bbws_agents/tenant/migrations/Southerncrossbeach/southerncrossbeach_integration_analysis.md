# Southern Cross Beach House - Integration Points Analysis

**Date:** 2026-01-16
**Tenant:** southerncrossbeach
**Environment:** DEV (southerncrossbeach.wpdev.kimmyai.io)
**Purpose:** Identify all external integrations and create mocking strategy for testing

---

## Executive Summary

This document analyzes all integration points for the Southern Cross Beach House WordPress site to enable safe testing without affecting the real business. All external services will be mocked or redirected to test endpoints during DEV and SIT testing.

**Key Principle:** No production services (email, analytics, payment) should be triggered during testing phases.

---

## Integration Points Identified

### 1. Email Notifications (HIGH RISK)

**Service:** WordPress wp_mail() / SMTP
**Used By:**
- Gravity Forms (form submissions)
- WordPress core (password resets, new user registrations)
- Plugin notifications

**Current Configuration:**
- Form submissions send to business email addresses
- Multiple forms with different recipient emails

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
    $args['subject'] = '[TEST - Southern Cross Beach DEV] ' . $args['subject'];

    // Add header noting original recipient
    $original_to = is_array($args['to']) ? implode(', ', $args['to']) : $args['to'];
    $args['message'] = "ORIGINAL RECIPIENT: {$original_to}\n\n---\n\n" . $args['message'];

    return $args;
}, 999);
```

**Implementation:** MU-plugin `/wp-content/mu-plugins/bbws-platform/email-redirect.php` (DEPLOYED)

---

### 2. Gravity Forms

**Service:** Gravity Forms (WordPress plugin)
**Status:** Active

**Integration Points:**

#### A. Email Notifications
**Risk:** HIGH - Sends form submissions to business owners

**Mocking Strategy:**
- Override ALL notification recipients to `tebogo@bigbeard.co.za`
- Add prefix to email subjects: `[TEST - Southern Cross Beach]`
- Preserve original recipient in email body for reference

#### B. Entry Storage
**Risk:** LOW - Entries stored in local database (wp_gf_entry tables)

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

#### B. Dynamic Content
**Risk:** LOW - Local content only

**Action:** Verify all forms use email redirect

---

### 4. Instagram Feed

**Service:** Instagram Feed plugin
**Status:** Active

**Integration Points:**

#### A. Instagram API
**Risk:** MEDIUM - Connects to Instagram API for feed data

**Current Configuration:**
- Pulls photos from Instagram account
- Caches data locally

**Mocking Strategy:**
- For DEV/SIT: Allow API connection (read-only)
- No mocking needed as it only reads data
- If token expires, feed will show cached content

**Action:** Monitor for API errors, no action required

---

### 5. Widget Google Reviews

**Service:** Widget Google Reviews plugin
**Status:** Active

**Integration Points:**

#### A. Google Places API
**Risk:** LOW - Read-only API access

**Current Configuration:**
- Pulls reviews from Google Places
- Displays on website

**Mocking Strategy:**
- Allow API connection (read-only)
- No mocking needed

**Action:** Verify reviews display correctly

---

### 6. Wordfence Security

**Service:** Wordfence plugin
**Status:** Active

**Integration Points:**

#### A. Threat Intelligence Feed
**Risk:** LOW - Downloads security data

#### B. Email Alerts
**Risk:** MEDIUM - Sends security alerts

**Mocking Strategy:**
- Email alerts will be captured by email redirect MU-plugin
- Threat feed continues normally

**Action:** Verify alerts go to tebogo@bigbeard.co.za

---

### 7. Yoast SEO (WordPress SEO)

**Service:** Yoast SEO plugin
**Status:** Active

**Integration Points:**

#### A. Search Console Integration
**Risk:** LOW - If connected to Google Search Console

#### B. XML Sitemap
**Risk:** LOW - Generated locally

**Mocking Strategy:**
- Ensure sitemap URLs point to DEV domain
- No action needed for Search Console (read-only)

**Action:** Verify sitemap accessible at /sitemap_index.xml

---

### 8. Really Simple SSL (DISABLED)

**Service:** Really Simple SSL plugin
**Status:** DISABLED

**Reason for Disabling:**
- Plugin caused redirect loops with CloudFront SSL termination
- CloudFront handles HTTPS, plugin conflicts with this architecture

**Current State:**
- Plugin deactivated via database
- Site uses WORDPRESS_CONFIG_EXTRA for HTTPS handling

**Action:** Do not re-enable in DEV/SIT environments

---

### 9. CDN / Asset Delivery

**Service:** CloudFront (Amazon AWS)
**Risk:** LOW - Already using our own CloudFront distribution

**Current Configuration:**
- Distribution: E2W27HE3T7FRW4
- Domain: southerncrossbeach.wpdev.kimmyai.io

**Action:** No mocking needed, using our infrastructure

---

## Mocking Implementation Status

### Deployed MU-Plugins

```
/var/www/html/wp-content/mu-plugins/
└── bbws-platform/
    ├── email-redirect.php        # Email interception (DEPLOYED)
    └── env-indicator.php         # Visual DEV indicator (DEPLOYED)
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
1. [ ] Submit any contact/booking forms
2. [ ] Verify email received at test address
3. [ ] Check Instagram feed displays
4. [ ] Check Google reviews display
5. [ ] Verify NO emails sent to real business addresses
6. [ ] Verify Wordfence alerts redirected

**Validation:**
```bash
# Check email redirect is active
curl -s https://southerncrossbeach.wpdev.kimmyai.io/ | grep "tebogo@bigbeard.co.za" || echo "Email redirect active via MU-plugin"

# Check environment indicator visible
curl -s https://southerncrossbeach.wpdev.kimmyai.io/ | grep -i "DEV\|development"
```

### SIT Environment Testing (Future)

**Email Address:** tebogo@bigbeard.co.za (same test address)

**Additional Tests:**
- Load testing (simulate multiple form submissions)
- Performance testing (page load times)
- Security testing (form injection, XSS)

### PROD Environment (Read-Only Initially)

**Email Address:** Real business addresses (restored)

**Deployment Checklist:**
- [ ] Update email redirect to production addresses
- [ ] Verify all emails go to correct recipients
- [ ] Enable real tracking scripts (if any)
- [ ] Monitor for 24 hours before full cutover

---

## Summary: Integration Points & Risk Levels

| Integration | Risk | Mocking Strategy | Status |
|-------------|------|------------------|--------|
| **Email Notifications** | HIGH | MU-plugin redirect to tebogo@bigbeard.co.za | DEPLOYED |
| **Gravity Forms Email** | HIGH | Covered by email redirect MU-plugin | DEPLOYED |
| **Instagram Feed** | LOW | No action needed (read-only API) | N/A |
| **Google Reviews** | LOW | No action needed (read-only API) | N/A |
| **Wordfence Alerts** | MEDIUM | Covered by email redirect MU-plugin | DEPLOYED |
| **Yoast SEO** | LOW | Verify sitemap URLs | Pending |
| **Really Simple SSL** | N/A | DISABLED - causes conflicts | RESOLVED |
| **CloudFront CDN** | LOW | No action needed (our infrastructure) | N/A |

---

## Environment-Specific Configuration

### DEV Environment (Current)

```php
// WORDPRESS_CONFIG_EXTRA in task definition
$_SERVER['HTTPS'] = 'on';
define('FORCE_SSL_ADMIN', false);
define('WP_HOME', 'https://southerncrossbeach.wpdev.kimmyai.io');
define('WP_SITEURL', 'https://southerncrossbeach.wpdev.kimmyai.io');
define('WP_ENVIRONMENT_TYPE', 'development');
```

### SIT Environment (Future)

```php
$_SERVER['HTTPS'] = 'on';
define('FORCE_SSL_ADMIN', false);
define('WP_HOME', 'https://southerncrossbeach.wpsit.kimmyai.io');
define('WP_SITEURL', 'https://southerncrossbeach.wpsit.kimmyai.io');
define('WP_ENVIRONMENT_TYPE', 'staging');
```

### PROD Environment (Future)

```php
$_SERVER['HTTPS'] = 'on';
define('FORCE_SSL_ADMIN', true);
define('WP_HOME', 'https://southerncrossbeach.co.za');
define('WP_SITEURL', 'https://southerncrossbeach.co.za');
define('WP_ENVIRONMENT_TYPE', 'production');
```

---

## Next Steps

### Immediate Actions
1. [ ] Test form submissions to verify email redirect
2. [ ] Verify Instagram feed displays cached content
3. [ ] Verify Google reviews display
4. [ ] Check Wordfence is not sending alerts to business

### Before SIT Promotion
1. [ ] Verify all email redirects working
2. [ ] Document any integration-specific issues
3. [ ] Update configuration for SIT environment

### Before PROD Deployment
1. [ ] Update email configuration for production
2. [ ] Verify business email addresses
3. [ ] Test form submissions in PROD environment
4. [ ] Monitor for 24 hours

---

*Document Created:* 2026-01-16
*Purpose:* Safe testing strategy without affecting real business
*Next Review:* After first form submission test
