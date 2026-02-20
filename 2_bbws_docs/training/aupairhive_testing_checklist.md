# Au Pair Hive Testing Checklist
## Post-Migration Validation for Each Environment

**Site**: aupairhive.com
**Version**: 1.0
**Last Updated**: 2026-01-09

---

## Testing Overview

This checklist must be completed for each environment:
- ✅ DEV (aupairhive.wpdev.kimmyai.io)
- ✅ SIT (aupairhive.wpsit.kimmyai.io)
- ✅ PROD (aupairhive.wp.kimmyai.io)
- ✅ PROD with live domain (aupairhive.com) - Final validation

---

## Phase 1: Infrastructure Validation

### 1.1 Container Health
- [ ] ECS tasks running (check desired count matches running count)
- [ ] No task restart loops (check stopped task count = 0)
- [ ] CloudWatch logs showing normal startup messages
- [ ] No error messages in container logs

### 1.2 Database Connectivity
- [ ] WordPress can connect to database
- [ ] Database credentials from Secrets Manager working
- [ ] Database character set is utf8mb4
- [ ] All WordPress tables present (wp_posts, wp_users, wp_options, etc.)
- [ ] Table row counts match source database

### 1.3 File Storage (EFS)
- [ ] EFS access point mounted correctly
- [ ] wp-content directory accessible
- [ ] File permissions correct (wp-config.php: 600, wp-content: 755)
- [ ] Images directory accessible (wp-content/uploads)
- [ ] Plugins directory accessible (wp-content/plugins)
- [ ] Themes directory accessible (wp-content/themes)

### 1.4 Load Balancer & DNS
- [ ] ALB target group has healthy targets
- [ ] ALB listener rule routing correctly (host-based routing)
- [ ] DNS record resolves correctly (dig/nslookup)
- [ ] CloudFront distribution serving content
- [ ] SSL certificate valid and trusted
- [ ] HTTP redirects to HTTPS

### 1.5 WordPress Core
- [ ] WordPress version matches source (or is safely updated)
- [ ] PHP version compatible with all plugins
- [ ] Site URL correct (Settings → General)
- [ ] Home URL correct (Settings → General)
- [ ] Permalink structure preserved
- [ ] .htaccess rules applied (if using Apache-style permalinks)

---

## Phase 2: Functional Testing

### 2.1 Homepage
- [ ] Homepage loads without errors
- [ ] All sections display correctly
- [ ] Divi theme rendering properly
- [ ] Hero/slider images load
- [ ] Navigation menu displays
- [ ] Footer displays with all links
- [ ] Social media icons present and linked
- [ ] No broken images (check browser console)
- [ ] No JavaScript errors (check browser console)
- [ ] Page load time <3 seconds (desktop)
- [ ] Page load time <5 seconds (mobile)

### 2.2 Navigation & Pages
Test all main navigation links:
- [ ] Home page
- [ ] For Families page (or equivalent)
- [ ] For Au Pairs page (or equivalent)
- [ ] About page
- [ ] Services page
- [ ] Blog/Resources page
- [ ] Contact page
- [ ] All dropdown menu items (if any)

For each page, verify:
- [ ] Page loads without errors (no 404, 500)
- [ ] Content displays correctly
- [ ] Images load
- [ ] Layout matches original site
- [ ] Divi modules/sections render properly

### 2.3 Blog Functionality
- [ ] Blog listing page loads
- [ ] All blog posts present (check post count)
- [ ] Featured images display on listing
- [ ] Post excerpts display correctly
- [ ] Pagination works (if applicable)
- [ ] Categories display correctly
- [ ] Tags display correctly
- [ ] Click individual blog post → opens correctly
- [ ] Blog post content displays fully
- [ ] Blog post images load
- [ ] Comments section displays (if enabled)
- [ ] Share buttons work (if present)
- [ ] Recent posts widget works (if present)
- [ ] Search functionality works (if present)

### 2.4 Forms (CRITICAL - Gravity Forms)

**Family Application Form**:
- [ ] Form displays on page
- [ ] All form fields render correctly
- [ ] Required field validation works
- [ ] Email field validation works
- [ ] Phone number field validation works
- [ ] File upload works (if applicable)
- [ ] reCAPTCHA displays and validates
- [ ] Form submits successfully
- [ ] Confirmation message displays after submit
- [ ] Form entry saved in Gravity Forms dashboard
- [ ] Email notification sent to admin email
- [ ] Auto-responder sent to user (if configured)

**Au Pair Application Form**:
- [ ] Form displays on page
- [ ] All form fields render correctly
- [ ] Required field validation works
- [ ] Form submits successfully
- [ ] Confirmation message displays
- [ ] Form entry saved in dashboard
- [ ] Email notifications sent

**Contact Form**:
- [ ] Form displays on contact page
- [ ] All fields render correctly
- [ ] reCAPTCHA validates
- [ ] Form submits successfully
- [ ] Confirmation message displays
- [ ] Email sent to admin

**Spam Protection**:
- [ ] reCAPTCHA prevents obvious bot submissions
- [ ] Honeypot fields working (if configured)
- [ ] Akismet active (if used)

### 2.5 Media Library
- [ ] Images display correctly on pages
- [ ] Image thumbnails generated
- [ ] Image URLs correct (no broken images)
- [ ] Lightbox/gallery functionality works (if used)
- [ ] Video embeds work (if present)
- [ ] PDF downloads work (if present)
- [ ] Lazy loading works (if enabled)

### 2.6 Search Functionality
- [ ] Search box displays in header/sidebar
- [ ] Search query returns results
- [ ] Search results page displays correctly
- [ ] Relevant results shown
- [ ] No results message displays when appropriate

---

## Phase 3: Theme & Plugin Validation

### 3.1 Divi Theme
- [ ] Divi theme activated
- [ ] License key validated (or site authorized)
- [ ] Divi Builder works in backend
- [ ] Divi Visual Builder loads (frontend editing)
- [ ] Divi modules render correctly:
  - [ ] Slider modules
  - [ ] Text modules
  - [ ] Button modules
  - [ ] Image modules
  - [ ] Contact form modules (if used instead of Gravity Forms)
  - [ ] Testimonial modules (if present)
  - [ ] Call-to-action modules
- [ ] Divi theme options accessible
- [ ] Divi customizer works
- [ ] Global theme settings preserved
- [ ] Color scheme matches original
- [ ] Fonts load correctly (Google Fonts, custom fonts)

### 3.2 Gravity Forms Plugin
- [ ] Gravity Forms activated
- [ ] License key valid
- [ ] All forms present in Forms list
- [ ] Form entries visible (if migrated)
- [ ] Form settings preserved:
  - [ ] Notifications
  - [ ] Confirmations
  - [ ] Conditional logic
  - [ ] Field mappings
- [ ] Form add-ons working (if any):
  - [ ] reCAPTCHA add-on
  - [ ] MailChimp add-on (if used)
  - [ ] PayPal add-on (if used)

### 3.3 Cookie Law Info (GDPR)
- [ ] Plugin activated
- [ ] Cookie banner displays on first visit
- [ ] Cookie settings configurable by user
- [ ] Accept/Reject buttons work
- [ ] Cookie policy page linked correctly
- [ ] GDPR compliance features working

### 3.4 Other Plugins
Test each active plugin:
- [ ] Plugin activated successfully
- [ ] No plugin conflicts (white screen, errors)
- [ ] Plugin settings preserved/reconfigured
- [ ] Plugin functionality works as expected

### 3.5 Plugin Updates
- [ ] Check for plugin updates available
- [ ] Note any security updates needed
- [ ] Test critical plugins in DEV before updating PROD

---

## Phase 4: Integrations & Tracking

### 4.1 Facebook Pixel
- [ ] Facebook Pixel code present in page source
- [ ] Pixel ID correct
- [ ] Page view events firing (verify in Facebook Events Manager)
- [ ] Custom events firing (if configured):
  - [ ] Form submissions
  - [ ] Button clicks
  - [ ] Page visits

### 4.2 Google Analytics (if present)
- [ ] GA tracking code present
- [ ] Real-time tracking shows visits
- [ ] Events tracking (if configured)

### 4.3 reCAPTCHA
- [ ] reCAPTCHA v2 or v3 working on forms
- [ ] Site key and secret key correct
- [ ] Domain authorized in Google reCAPTCHA admin
- [ ] reCAPTCHA badge displays (v3)
- [ ] Checkbox displays and validates (v2)

### 4.4 Social Media Integration
- [ ] Facebook link works → opens Facebook page
- [ ] Instagram link works → opens Instagram profile
- [ ] LinkedIn link works (if present)
- [ ] Social share buttons work (if present)
- [ ] Open Graph meta tags present (for link previews)
- [ ] Twitter Card meta tags present (if applicable)

### 4.5 Email Functionality
- [ ] WordPress can send emails (test via password reset)
- [ ] Form notification emails delivered
- [ ] No emails going to spam
- [ ] Email sender address correct
- [ ] Email headers correct (SPF, DKIM if configured)

---

## Phase 5: Performance Testing

### 5.1 Page Load Speed
Test with tools: GTmetrix, Google PageSpeed Insights, Pingdom

**Homepage**:
- [ ] Desktop load time: <3 seconds
- [ ] Mobile load time: <5 seconds
- [ ] Time to First Byte (TTFB): <1 second
- [ ] First Contentful Paint (FCP): <2 seconds
- [ ] Largest Contentful Paint (LCP): <3 seconds

**Blog Post Page**:
- [ ] Load time acceptable (<3-5s)
- [ ] Images optimized/lazy loaded

**Contact Page**:
- [ ] Form loads quickly
- [ ] reCAPTCHA doesn't slow page significantly

### 5.2 Database Performance
- [ ] Database queries <100ms average
- [ ] No slow query warnings in logs
- [ ] Database connection pool not exhausted
- [ ] Query Monitor plugin shows acceptable query counts (<50 per page)

### 5.3 CloudFront CDN
- [ ] Static assets served from CloudFront
- [ ] Images delivered via CDN
- [ ] CSS/JS files cached appropriately
- [ ] Cache hit ratio >80% (after warm-up period)
- [ ] Gzip compression enabled

### 5.4 Resource Utilization
Check in AWS CloudWatch:
- [ ] ECS task CPU utilization <70%
- [ ] ECS task memory utilization <80%
- [ ] No out-of-memory errors
- [ ] Container restarts = 0

---

## Phase 6: Security Validation

### 6.1 SSL/TLS
- [ ] HTTPS enabled (site forces HTTPS)
- [ ] SSL certificate valid and trusted
- [ ] Certificate covers domain and www subdomain
- [ ] No mixed content warnings (HTTP resources on HTTPS page)
- [ ] SSL Labs test: A or A+ rating (https://www.ssllabs.com/ssltest/)

### 6.2 WordPress Security
- [ ] WordPress core up-to-date (or scheduled update)
- [ ] All plugins up-to-date
- [ ] Theme up-to-date
- [ ] No known vulnerabilities (check WPScan)
- [ ] Login URL accessible (/wp-admin)
- [ ] Strong admin password set
- [ ] File editing disabled in wp-config.php
- [ ] Debug mode disabled (WP_DEBUG = false in PROD)
- [ ] Database prefix not default "wp_" (security through obscurity)
- [ ] Directory listing disabled
- [ ] XML-RPC disabled or protected (if not needed)

### 6.3 File Permissions
- [ ] wp-config.php: 600 (read/write owner only)
- [ ] .htaccess: 644 (if present)
- [ ] wp-content: 755 (directories)
- [ ] wp-content files: 644
- [ ] uploads directory: 755
- [ ] No world-writable files

### 6.4 Security Headers
Check with SecurityHeaders.com:
- [ ] X-Frame-Options: SAMEORIGIN
- [ ] X-Content-Type-Options: nosniff
- [ ] X-XSS-Protection: 1; mode=block
- [ ] Referrer-Policy: no-referrer-when-downgrade
- [ ] Content-Security-Policy: (if configured)

### 6.5 Backup & Recovery
- [ ] Database backup exists and is recent
- [ ] Files backup exists
- [ ] Backup restoration tested in DEV
- [ ] Backup schedule configured (automated)

---

## Phase 7: Mobile & Cross-Browser Testing

### 7.1 Responsive Design
Test on different screen sizes:

**Desktop (1920x1080)**:
- [ ] Layout correct
- [ ] No horizontal scrolling
- [ ] Images scale appropriately
- [ ] Navigation menu displays correctly

**Tablet (768x1024)**:
- [ ] Layout adapts correctly
- [ ] Mobile menu triggers at appropriate breakpoint
- [ ] Forms usable and readable
- [ ] Images responsive

**Mobile (375x667 - iPhone SE)**:
- [ ] Layout stacks correctly
- [ ] Text readable (not too small)
- [ ] Buttons tappable (not too small)
- [ ] Forms easy to fill on mobile
- [ ] Mobile menu works
- [ ] No elements cut off

### 7.2 Browser Compatibility
Test on major browsers:

**Chrome (latest)**:
- [ ] Site loads correctly
- [ ] All functionality works
- [ ] No console errors

**Firefox (latest)**:
- [ ] Site loads correctly
- [ ] All functionality works
- [ ] Forms submit correctly

**Safari (latest)**:
- [ ] Site loads correctly
- [ ] All functionality works
- [ ] iOS Safari specifically tested

**Edge (latest)**:
- [ ] Site loads correctly
- [ ] All functionality works

### 7.3 Device Testing
If possible, test on actual devices:
- [ ] iPhone (Safari)
- [ ] Android phone (Chrome)
- [ ] iPad (Safari)
- [ ] Android tablet
- [ ] Desktop PC (Windows)
- [ ] Desktop Mac (macOS)

---

## Phase 8: SEO Validation

### 8.1 URLs & Permalinks
- [ ] Permalink structure preserved (e.g., /post-name/)
- [ ] Old URLs redirect correctly (301 redirects)
- [ ] No broken internal links
- [ ] No 404 errors for previously indexed pages
- [ ] Sitemap.xml accessible
- [ ] Robots.txt configured correctly

### 8.2 On-Page SEO
- [ ] Page titles preserved
- [ ] Meta descriptions present
- [ ] H1 tags present and appropriate
- [ ] Images have alt text
- [ ] Schema markup preserved (if present)
- [ ] Open Graph tags for social sharing

### 8.3 Google Search Console
- [ ] Site submitted/verified in Search Console
- [ ] Sitemap submitted
- [ ] No crawl errors
- [ ] Mobile usability: No issues

---

## Phase 9: User Acceptance Testing (UAT)

### 9.1 Business Owner Testing
Site owner should test:
- [ ] Can login to wp-admin
- [ ] Can create/edit pages
- [ ] Can create/edit blog posts
- [ ] Can upload images
- [ ] Can view form submissions (Gravity Forms)
- [ ] Can update theme/plugin settings
- [ ] All custom workflows work as before

### 9.2 End User Testing
Simulate real user journeys:

**Family looking for au pair**:
- [ ] Land on homepage
- [ ] Navigate to "For Families" section
- [ ] Read about services
- [ ] Click "Apply" or "Contact"
- [ ] Fill and submit family application form
- [ ] Receive confirmation

**Au pair looking for placement**:
- [ ] Land on homepage
- [ ] Navigate to "For Au Pairs" section
- [ ] Read requirements and benefits
- [ ] Fill and submit au pair application form
- [ ] Receive confirmation

**Blog reader**:
- [ ] Find blog via navigation
- [ ] Read blog post
- [ ] Navigate to related posts
- [ ] Search for specific topic
- [ ] Share post on social media

---

## Phase 10: Final Production Validation

### 10.1 DNS Cutover Verification
After pointing domain to BBWS platform:
- [ ] aupairhive.com resolves to new site
- [ ] www.aupairhive.com resolves to new site
- [ ] Old domain (if different) redirects
- [ ] DNS propagation complete globally (check from multiple locations)
- [ ] No DNS errors or warnings

### 10.2 Email Deliverability
- [ ] Test form submission → email received
- [ ] Check email not marked as spam
- [ ] Verify sender domain reputation
- [ ] SPF/DKIM records correct (if configured)

### 10.3 Analytics Tracking
- [ ] Google Analytics showing traffic (if used)
- [ ] Facebook Pixel showing events
- [ ] Conversion tracking working
- [ ] All tracking scripts firing correctly

### 10.4 Monitoring & Alerts
- [ ] CloudWatch alarms configured
- [ ] Uptime monitoring active (if configured)
- [ ] Error logs being monitored
- [ ] Performance metrics tracked

---

## Issue Tracking Template

For any issues found during testing, document using this template:

```
ISSUE #[number]
Environment: DEV / SIT / PROD
Severity: Critical / High / Medium / Low
Date Found: YYYY-MM-DD
Tester: [Name]

Description:
[What is broken or not working as expected]

Steps to Reproduce:
1. [Step 1]
2. [Step 2]
3. [Expected result vs actual result]

Screenshots:
[Attach screenshots if applicable]

Console Errors:
[Any JavaScript or browser console errors]

Status: Open / In Progress / Resolved / Closed
Assigned To: [Name]
Resolution Notes:
[How it was fixed]
```

---

## Sign-Off Checklist

### DEV Environment Sign-Off
- [ ] All Phase 1-9 tests passed in DEV
- [ ] All critical issues resolved
- [ ] Performance acceptable
- [ ] Ready to promote to SIT

**Signed Off By**: _________________ Date: _________

### SIT Environment Sign-Off
- [ ] All Phase 1-9 tests passed in SIT
- [ ] UAT completed successfully
- [ ] Performance meets requirements
- [ ] Ready to promote to PROD

**Signed Off By**: _________________ Date: _________

### PROD Environment Sign-Off
- [ ] All Phase 1-10 tests passed in PROD
- [ ] Live domain pointing correctly
- [ ] No critical issues
- [ ] Monitoring active
- [ ] Migration complete and successful

**Signed Off By**: _________________ Date: _________

---

## Post-Migration Monitoring (First 48 Hours)

Monitor these metrics closely after go-live:

**Hour 1**:
- [ ] Site accessible via domain
- [ ] No 5xx errors
- [ ] Forms working
- [ ] No critical errors in logs

**Hour 6**:
- [ ] Performance stable
- [ ] No unusual errors
- [ ] Email delivery working
- [ ] Analytics tracking

**Hour 24**:
- [ ] Uptime: 99.9%+
- [ ] Average response time acceptable
- [ ] No user complaints
- [ ] Form submissions being processed

**Hour 48**:
- [ ] All systems stable
- [ ] Performance metrics good
- [ ] SEO rankings stable (may take days/weeks to fully settle)
- [ ] Migration considered successful

---

**Testing Version**: 1.0
**Last Updated**: 2026-01-09
**Status**: READY FOR USE
