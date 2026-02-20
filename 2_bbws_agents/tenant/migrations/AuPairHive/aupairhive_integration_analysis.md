# Au Pair Hive - Integration Points Analysis

**Date:** 2026-01-11
**Tenant:** aupairhive
**Environment:** DEV (aupairhive.wpdev.kimmyai.io)
**Purpose:** Identify all external integrations and create mocking strategy for testing

---

## Executive Summary

This document analyzes all integration points for the Au Pair Hive WordPress site to enable safe testing without affecting the real business. All external services will be mocked or redirected to test endpoints during DEV and SIT testing.

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
- ❌ Real customers receive test form submissions
- ❌ Business inbox flooded with test emails
- ❌ Reputation damage from spam-like behavior
- ❌ SMTP provider may throttle/block account

**Mocking Strategy:**
```php
// Intercept ALL emails during testing
add_filter('wp_mail', function($args) {
    // Redirect ALL emails to test address
    $args['to'] = 'tebogo@bigbeard.co.za';

    // Add subject prefix to identify test emails
    $args['subject'] = '[TEST - Au Pair Hive DEV] ' . $args['subject'];

    // Add header noting original recipient
    $original_to = is_array($args['to']) ? implode(', ', $args['to']) : $args['to'];
    $args['message'] = "ORIGINAL RECIPIENT: {$original_to}\n\n---\n\n" . $args['message'];

    // Log email for debugging
    error_log("Test email redirected: " . json_encode($args));

    return $args;
}, 999);
```

**Implementation:** MU-plugin `/wp-content/mu-plugins/bbws-test-email-redirect.php`

---

### 2. Gravity Forms

**Service:** Gravity Forms (WordPress plugin)
**Version:** 2.6.7
**Forms Identified:**
1. **Contact Us** (Form ID: 6) - Page ID: 17
2. **Au Pair Application** - Page ID: 233
3. **Family Au Pair Application** - Page ID: 264

**Integration Points:**

#### A. Email Notifications
**Risk:** HIGH - Sends form submissions to business owners

**Current Recipients:**
- Unknown (need to query wp_gf_form_meta)

**Mocking Strategy:**
- Override ALL notification recipients to `tebogo@bigbeard.co.za`
- Add prefix to email subjects: `[TEST - Au Pair Hive]`
- Preserve original recipient in email body for reference

**Database Query to Identify Recipients:**
```sql
SELECT id, title, notifications
FROM wp_gf_form f
INNER JOIN wp_gf_form_meta m ON f.id = m.form_id
WHERE m.meta_key = 'notifications';
```

#### B. Entry Storage
**Risk:** LOW - Entries stored in local database (wp_gf_entry tables)

**Action:** No mocking needed, entries are local

#### C. reCAPTCHA Integration
**Risk:** MEDIUM - Uses Google reCAPTCHA service

**Current Configuration:**
- Plugin: Gravity Forms reCAPTCHA (v1.1)
- Likely has site key and secret key configured

**Mocking Strategy:**
- For DEV/SIT: Keep reCAPTCHA active but use TEST keys
- Google provides test keys that always pass: https://developers.google.com/recaptcha/docs/faq#id-like-to-run-automated-tests-with-recaptcha.-what-should-i-do
- Test site key: `6LeIxAcTAAAAAJcZVRqyHh71UMIEGNQ_MXjiZKhI`
- Test secret key: `6LeIxAcTAAAAAGG-vFI1TnRWxMZNFuojJ4WifJWe`

**Implementation:** Update via database or wp-config.php constants

---

### 3. Cookie Law Info (GDPR Cookie Banner)

**Service:** Cookie Law Info plugin
**Version:** 3.0.1

**Integration Points:**

#### A. Cookie Consent Tracking
**Risk:** LOW - Local cookie storage only

**Action:** No mocking needed

#### B. Analytics Integration (if configured)
**Risk:** MEDIUM - May send consent events to analytics

**Mocking Strategy:**
- Verify if plugin integrates with Google Analytics
- If yes, ensure Google Analytics is mocked (see #6 below)

---

### 4. WP Headers and Footers

**Service:** WP Headers and Footers plugin
**Version:** 2.1.0

**Purpose:** Inject code into <head> and footer sections

**Integration Points:**

#### A. Tracking Scripts (Likely Facebook Pixel, Google Analytics)
**Risk:** HIGH - Sends real user events to production analytics

**Current Configuration:** Unknown (need to check plugin settings)

**Mocking Strategy:**
```php
// Disable all tracking scripts in DEV/SIT
add_filter('wpheaderandfooter_disable_frontend', function() {
    return (defined('WP_ENV') && in_array(WP_ENV, ['dev', 'sit']));
});
```

**Implementation:** Check wp_options for keys:
- `wp_headfoot_header_code`
- `wp_headfoot_footer_code`

---

### 5. Facebook Pixel (if configured)

**Service:** Facebook Analytics
**Risk:** HIGH - Sends page view and event data to Facebook

**Current Configuration:** Likely embedded via WP Headers and Footers

**Mocking Strategy:**

**Option 1: Disable in DEV/SIT**
```javascript
// Replace real Pixel ID with dummy
fbq('init', '000000000000000'); // Dummy ID that won't send data
```

**Option 2: Use Facebook Test Events**
- Facebook provides test event functionality
- Events sent with test_event_code parameter don't affect production

**Implementation:**
```php
// MU-plugin to modify Facebook Pixel code
add_filter('wpheaderandfooter_header_code', function($code) {
    if (defined('WP_ENV') && in_array(WP_ENV, ['dev', 'sit'])) {
        // Replace real pixel ID with test ID
        $code = str_replace(
            ["fbq('init',", "fbq('track',"],
            ["console.log('[TEST] fbq init',", "console.log('[TEST] fbq track',"],
            $code
        );
    }
    return $code;
});
```

---

### 6. Google Analytics (if configured)

**Service:** Google Analytics 4 or Universal Analytics
**Risk:** HIGH - Sends page views and events to production property

**Current Configuration:** Likely embedded via WP Headers and Footers

**Mocking Strategy:**

**Option 1: Use GA4 Debug Mode**
```javascript
// Enable debug mode for dev/sit
gtag('config', 'G-XXXXXXXXXX', {
    'debug_mode': true,
    'send_page_view': false  // Don't send page views
});
```

**Option 2: Replace with dummy tracking ID**
```php
add_filter('wpheaderandfooter_header_code', function($code) {
    if (defined('WP_ENV') && in_array(WP_ENV, ['dev', 'sit'])) {
        // Replace real GA ID with dummy
        $code = preg_replace('/G-[A-Z0-9]+/', 'G-TESTONLY', $code);
        $code = preg_replace('/UA-[0-9]+-[0-9]+/', 'UA-000000-01', $code);
    }
    return $code;
});
```

---

### 7. SMTP / Email Delivery Service

**Service:** WordPress wp_mail() or SMTP plugin (if configured)
**Risk:** HIGH - Actual email delivery to production addresses

**Current Configuration:** Need to check for SMTP plugins:
- WP Mail SMTP
- Easy WP SMTP
- Post SMTP
- Sendgrid/Mailgun/SES plugins

**Mocking Strategy:**

**Option 1: Use MailHog/Mailpit (Local Capture)**
```php
// wp-config.php for dev/sit
define('WPMS_ON', true);
define('WPMS_SMTP_HOST', 'mailhog.internal');
define('WPMS_SMTP_PORT', 1025);
define('WPMS_SMTP_AUTH', false);
```

**Option 2: Redirect via MU-plugin (Already covered in #1)**

---

### 8. CDN / Asset Delivery

**Service:** CloudFront (Amazon AWS)
**Risk:** LOW - Already using our own CloudFront distribution

**Current Configuration:**
- Distribution: E2W27HE3T7FRW4
- Domain: aupairhive.wpdev.kimmyai.io

**Action:** No mocking needed, using our infrastructure

---

### 9. External API Calls (if any)

**Service:** Unknown - need to scan codebase

**Check For:**
- Payment gateways (Stripe, PayPal)
- CRM integrations (HubSpot, Salesforce)
- Marketing tools (Mailchimp, ConvertKit)
- Background checks / verification services (for au pair screening)

**Mocking Strategy:**
- Identify all `wp_remote_post()`, `wp_remote_get()`, `curl` calls
- Create mock API responses
- Use WordPress filters to intercept HTTP requests:

```php
add_filter('pre_http_request', function($preempt, $args, $url) {
    if (defined('WP_ENV') && in_array(WP_ENV, ['dev', 'sit'])) {
        // Check if this is a production API call
        $production_domains = [
            'api.stripe.com',
            'api.mailchimp.com',
            'api.hubspot.com',
        ];

        foreach ($production_domains as $domain) {
            if (strpos($url, $domain) !== false) {
                // Return mock response
                return [
                    'response' => ['code' => 200],
                    'body' => json_encode(['status' => 'test_mode', 'message' => 'Mocked response'])
                ];
            }
        }
    }
    return $preempt;
}, 10, 3);
```

---

## Mocking Implementation Strategy

### Phase 1: Immediate (Before Testing)

**1. Create Test Email Redirect MU-Plugin**
```
/var/www/html/wp-content/mu-plugins/bbws-test-email-redirect.php
```

**2. Update Gravity Forms Notification Emails**
```sql
-- Will be done via script to update all form notifications
UPDATE wp_gf_form_meta
SET meta_value = REPLACE(meta_value, 'original@email.com', 'tebogo@bigbeard.co.za')
WHERE meta_key = 'notifications';
```

**3. Add Environment Constant to wp-config.php**
```php
define('WP_ENV', 'dev');  // or 'sit', 'prod'
```

### Phase 2: Tracking Script Management

**4. Audit WP Headers and Footers Content**
```sql
SELECT option_value
FROM wp_options
WHERE option_name IN ('wp_headfoot_header_code', 'wp_headfoot_footer_code');
```

**5. Create Tracking Script Mocker MU-Plugin**
```
/var/www/html/wp-content/mu-plugins/bbws-mock-tracking.php
```

### Phase 3: External Service Discovery

**6. Scan Codebase for External API Calls**
```bash
grep -r "wp_remote_\|curl_\|file_get_contents.*http" /var/www/html/wp-content/
```

**7. Create HTTP Request Interceptor MU-Plugin**
```
/var/www/html/wp-content/mu-plugins/bbws-mock-http-requests.php
```

---

## MU-Plugin Library Structure

All test mocking plugins will be organized in:

```
/var/www/html/wp-content/mu-plugins/
├── bbws-platform/
│   ├── force-https.php              # HTTPS forcing (already deployed)
│   ├── test-email-redirect.php      # Email interception for testing
│   ├── mock-tracking.php            # Disable/mock analytics in dev/sit
│   ├── mock-http-requests.php       # Intercept external API calls
│   └── environment-indicator.php    # Visual indicator for dev/sit
└── bbws-platform.php                # Loader (checks WP_ENV)
```

**bbws-platform.php** (Main loader):
```php
<?php
/**
 * Plugin Name: BBWS Platform - Test Environment Controls
 * Description: Manages test environment behavior for multi-tenant WordPress
 * Version: 1.0.0
 */

// Load environment-specific plugins
$wp_env = defined('WP_ENV') ? WP_ENV : 'prod';

if (in_array($wp_env, ['dev', 'sit'])) {
    // Only load test mocking in non-production
    require_once __DIR__ . '/bbws-platform/force-https.php';
    require_once __DIR__ . '/bbws-platform/test-email-redirect.php';
    require_once __DIR__ . '/bbws-platform/mock-tracking.php';
    require_once __DIR__ . '/bbws-platform/mock-http-requests.php';
    require_once __DIR__ . '/bbws-platform/environment-indicator.php';
} else {
    // Production only needs HTTPS forcing
    require_once __DIR__ . '/bbws-platform/force-https.php';
}
```

---

## Testing Workflow

### DEV Environment Testing (Current)

**Email Address:** tebogo@bigbeard.co.za

**Test Cases:**
1. ✅ Submit "Contact Us" form
2. ✅ Submit "Au Pair Application" form
3. ✅ Submit "Family Au Pair Application" form
4. ✅ Verify reCAPTCHA works
5. ✅ Check cookie banner displays
6. ✅ Verify NO emails sent to real business addresses
7. ✅ Verify NO events sent to production analytics

**Validation:**
```bash
# Check email redirect is active
wp eval "echo apply_filters('wp_mail', ['to' => 'test@example.com']);" --allow-root

# Check tracking scripts are mocked
curl -s https://aupairhive.wpdev.kimmyai.io | grep -E "fbq|gtag|ga\("

# Check environment indicator visible
curl -s https://aupairhive.wpdev.kimmyai.io | grep "WP_ENV.*dev"
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
- [ ] Remove test email redirect MU-plugin
- [ ] Remove tracking script mocker
- [ ] Restore real reCAPTCHA keys (if changed)
- [ ] Enable real tracking scripts
- [ ] Verify all emails go to correct recipients
- [ ] Monitor for 24 hours before full cutover

---

## Gravity Forms Email Configuration Update

### Current State (Unknown - Need to Query)

```sql
-- Get all forms and their notifications
SELECT
    f.id,
    f.title,
    m.meta_value as notifications
FROM wp_gf_form f
INNER JOIN wp_gf_form_meta m ON f.id = m.form_id
WHERE m.meta_key = 'notifications';
```

### Target State (DEV/SIT)

All notification emails → `tebogo@bigbeard.co.za`

### Update Script

```bash
#!/bin/bash
# update-gravity-forms-emails.sh

ENVIRONMENT=${1:-dev}
TEST_EMAIL="tebogo@bigbeard.co.za"

if [ "$ENVIRONMENT" != "prod" ]; then
    echo "Updating Gravity Forms notifications to test email: $TEST_EMAIL"

    # Backup current notifications
    wp db export /tmp/gf-notifications-backup-$(date +%Y%m%d).sql \
        --tables=wp_gf_form_meta \
        --allow-root

    # Update all notification emails
    # Note: meta_value is serialized PHP, need to be careful
    wp eval "
        \$forms = GFAPI::get_forms();
        foreach (\$forms as \$form) {
            foreach (\$form['notifications'] as \$id => \$notification) {
                \$form['notifications'][\$id]['to'] = '$TEST_EMAIL';
                \$form['notifications'][\$id]['subject'] = '[TEST - Au Pair Hive] ' . \$notification['subject'];
            }
            GFAPI::update_form(\$form);
        }
        echo 'Updated ' . count(\$forms) . ' forms';
    " --allow-root

    echo "✅ Gravity Forms notifications updated to test email"
else
    echo "❌ Cannot run in PROD environment. Exiting."
    exit 1
fi
```

---

## Environment Indicator (Visual Cue)

To prevent confusion about which environment you're testing:

```php
// bbws-platform/environment-indicator.php
<?php
/**
 * Visual environment indicator for dev/sit
 */

add_action('wp_footer', function() {
    $env = defined('WP_ENV') ? WP_ENV : 'unknown';

    if (in_array($env, ['dev', 'sit'])) {
        $color = $env === 'dev' ? '#ff6b6b' : '#ffa726';
        $label = strtoupper($env) . ' ENVIRONMENT';
        ?>
        <div style="position:fixed;bottom:0;left:0;right:0;background:<?php echo $color; ?>;color:#fff;text-align:center;padding:10px;font-weight:bold;z-index:999999;font-family:monospace;">
            🚧 <?php echo $label; ?> - Testing Mode Active - Emails redirect to: tebogo@bigbeard.co.za 🚧
        </div>
        <?php
    }
}, 999);

// Admin bar indicator
add_action('admin_bar_menu', function($wp_admin_bar) {
    $env = defined('WP_ENV') ? WP_ENV : 'unknown';

    if (in_array($env, ['dev', 'sit'])) {
        $wp_admin_bar->add_node([
            'id' => 'environment-indicator',
            'title' => '🚧 ' . strtoupper($env) . ' ENVIRONMENT',
            'meta' => [
                'style' => 'background: #d63638; color: #fff;'
            ]
        ]);
    }
}, 999);
```

---

## Summary: Integration Points & Risk Levels

| Integration | Risk | Mocking Strategy | Status |
|-------------|------|------------------|--------|
| **Email Notifications** | 🔴 HIGH | MU-plugin redirect to tebogo@bigbeard.co.za | Pending |
| **Gravity Forms Email** | 🔴 HIGH | Database update + MU-plugin intercept | Pending |
| **reCAPTCHA** | 🟡 MEDIUM | Use Google test keys | Pending |
| **Facebook Pixel** | 🔴 HIGH | Replace with console.log in dev/sit | Pending |
| **Google Analytics** | 🔴 HIGH | Replace with dummy tracking ID | Pending |
| **SMTP Service** | 🔴 HIGH | Covered by email redirect MU-plugin | Pending |
| **Cookie Banner** | 🟢 LOW | No action needed (local only) | N/A |
| **CloudFront CDN** | 🟢 LOW | No action needed (our infrastructure) | N/A |
| **External APIs** | 🟡 MEDIUM | Scan codebase + HTTP request interceptor | Pending |

---

## Next Steps

### Immediate Actions (Before Testing)
1. Query database to identify current Gravity Forms notification recipients
2. Create and deploy test email redirect MU-plugin
3. Update Gravity Forms notifications to tebogo@bigbeard.co.za
4. Add WP_ENV constant to wp-config.php
5. Deploy environment indicator MU-plugin

### Validation (After Deployment)
6. Test form submission → verify email goes to tebogo@bigbeard.co.za
7. Verify subject line has [TEST - Au Pair Hive] prefix
8. Check environment indicator displays on site
9. Verify no real business emails sent

### Documentation
10. Update migration automation scripts to include mocking setup
11. Create tenant testing checklist with integration validation
12. Document rollback procedure for production deployment

---

*Document Created:* 2026-01-11
*Purpose:* Safe testing strategy without affecting real business
*Next Review:* After first form submission test
