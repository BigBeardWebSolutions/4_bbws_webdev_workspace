# Manufacturing-Websites - Testing Verification Checklist

**Site:** manufacturing-websites.com → manufacturing.wpdev.kimmyai.io
**Environment:** DEV
**Test Date:** 2026-01-16
**Tester:** [Enter Name]
**Status:** In Progress

---

## Purpose

This document provides a comprehensive testing checklist for verifying the Manufacturing-Websites WordPress migration. All tests must pass before promotion to SIT environment.

---

## Test Categories Overview

| Category | Tests | Status |
|----------|-------|--------|
| 1. Infrastructure | 5 | Pending |
| 2. Site Access | 4 | Pending |
| 3. Admin Access | 6 | Pending |
| 4. Content | 7 | Pending |
| 5. Theme & Design | 5 | Pending |
| 6. Forms | 5 | Pending |
| 7. Plugins | 4 | Pending |
| 8. SEO | 5 | Pending |
| 9. Performance | 4 | Pending |
| 10. Security | 5 | Pending |
| 11. Mobile | 4 | Pending |
| 12. Browser Compatibility | 4 | Pending |
| **Total** | **58** | |

---

## Section 1: Infrastructure Verification

### 1.1 CloudFront Distribution
- [ ] Distribution ID: E2W27HE3T7FRW4
- [ ] Domain resolves: manufacturing.wpdev.kimmyai.io
- [ ] HTTPS working: Certificate valid
- [ ] X-Cache header present (after first request)
- [ ] Basic auth exclusion working (no auth required)

**Test Command:**
```bash
curl -sI https://manufacturing.wpdev.kimmyai.io/ | head -20
```

**Expected:** HTTP/2 200, X-Cache: Hit from cloudfront

### 1.2 DNS Resolution
- [ ] CNAME record exists
- [ ] Points to djooedduypbsr.cloudfront.net
- [ ] Propagation complete (all regions)

**Test Command:**
```bash
dig manufacturing.wpdev.kimmyai.io CNAME +short
```

**Expected:** djooedduypbsr.cloudfront.net

### 1.3 ALB Routing
- [ ] Listener rule exists (priority 153)
- [ ] Host header matching configured
- [ ] Target group registered

### 1.4 Target Group Health
- [ ] Targets registered
- [ ] Health check passing
- [ ] No unhealthy targets

**Test Command:**
```bash
aws elbv2 describe-target-health --target-group-arn "arn:aws:elasticloadbalancing:eu-west-1:536580886816:targetgroup/dev-manufacturing-tg/[ARN]"
```

**Expected:** "State": "healthy"

### 1.5 ECS Service
- [ ] Service running
- [ ] Desired count = Running count
- [ ] No failed deployments
- [ ] Task healthy

**Test Command:**
```bash
aws ecs describe-services --cluster dev-cluster --services dev-manufacturing-service --query 'services[0].{status:status,running:runningCount,desired:desiredCount}'
```

**Expected:** status: ACTIVE, running: 1, desired: 1

---

## Section 2: Site Access Verification

### 2.1 Homepage Access
- [ ] HTTPS redirect working
- [ ] Page loads completely
- [ ] No SSL warnings
- [ ] HTTP status 200

**Test Command:**
```bash
curl -s -o /dev/null -w "%{http_code}" https://manufacturing.wpdev.kimmyai.io/
```

**Expected:** 200

### 2.2 URL Configuration
- [ ] Site URL correct in database
- [ ] Home URL correct in database
- [ ] No old domain references in output

**Test Command:**
```bash
curl -s https://manufacturing.wpdev.kimmyai.io/ | grep -i "manufacturing-websites.com" | head -3
```

**Expected:** No output (no old domain references)

### 2.3 Environment Indicator
- [ ] DEV banner visible on frontend
- [ ] DEV indicator in admin bar
- [ ] Environment type set correctly

**Test Command:**
```bash
curl -s https://manufacturing.wpdev.kimmyai.io/ | grep -i "development\|DEV"
```

**Expected:** Environment indicator present

### 2.4 Static Assets
- [ ] CSS files loading (200 response)
- [ ] JS files loading (200 response)
- [ ] Images loading (200 response)
- [ ] Fonts loading (200 response)

**Test Command:**
```bash
curl -s -o /dev/null -w "%{http_code}" https://manufacturing.wpdev.kimmyai.io/wp-content/themes/hello-elementor/style.css
```

**Expected:** 200

---

## Section 3: Admin Access Verification

### 3.1 Login Page
- [ ] wp-login.php accessible
- [ ] Login form displays
- [ ] HTTPS on login page
- [ ] No redirect loops

**URL:** https://manufacturing.wpdev.kimmyai.io/wp-login.php

### 3.2 Admin Login
- [ ] Username: nigelbeard
- [ ] Password: MfgDev2026!
- [ ] Login successful
- [ ] Dashboard loads

### 3.3 Dashboard
- [ ] No PHP errors
- [ ] No critical warnings
- [ ] Site health accessible
- [ ] Updates visible

### 3.4 Admin Navigation
- [ ] Posts menu works
- [ ] Pages menu works
- [ ] Plugins menu works
- [ ] Settings menu works
- [ ] Elementor menu works

### 3.5 User Profile
- [ ] Profile page loads
- [ ] Email displayed correctly
- [ ] Can update profile

### 3.6 Media Library
- [ ] Media library loads
- [ ] Existing images visible
- [ ] Image URLs correct (new domain)
- [ ] Can upload new media

---

## Section 4: Content Verification

### 4.1 Homepage Content
- [ ] Hero section displays
- [ ] All sections render
- [ ] Images load
- [ ] Text content correct

### 4.2 Navigation Menu
- [ ] Primary menu displays
- [ ] All links work
- [ ] No broken links
- [ ] Correct pages load

### 4.3 Page Content
- [ ] About page loads
- [ ] Services page loads
- [ ] Contact page loads
- [ ] All custom pages load

### 4.4 Elementor Content
- [ ] Page builder sections render
- [ ] Widgets display correctly
- [ ] Animations work (if any)
- [ ] Templates load

### 4.5 Media/Images
- [ ] Featured images display
- [ ] Gallery images load
- [ ] Inline images render
- [ ] No broken image links

### 4.6 UTF-8 Characters
- [ ] No encoding artifacts (Â, â€™)
- [ ] Special characters display correctly
- [ ] Apostrophes render properly
- [ ] Em dashes display correctly

**Test Command:**
```bash
curl -s https://manufacturing.wpdev.kimmyai.io/ | grep -E "Â|â€™|â€œ|â€"" | head -3
```

**Expected:** No output (no encoding artifacts)

### 4.7 Internal Links
- [ ] All internal links use new domain
- [ ] No links to old domain
- [ ] Navigation links work
- [ ] Footer links work

---

## Section 5: Theme & Design Verification

### 5.1 Theme Activation
- [ ] Hello Elementor theme active
- [ ] Theme files loading
- [ ] No theme errors

### 5.2 Elementor Theme Builder
- [ ] Header template loads
- [ ] Footer template loads
- [ ] Archive templates work
- [ ] Single post template works

### 5.3 Responsive Design
- [ ] Desktop layout correct
- [ ] Tablet layout adapts
- [ ] Mobile layout adapts
- [ ] Breakpoints working

### 5.4 Typography
- [ ] Fonts loading
- [ ] Font sizes correct
- [ ] Line heights proper
- [ ] Headings styled

### 5.5 Colors & Branding
- [ ] Brand colors correct
- [ ] No color inconsistencies
- [ ] Buttons styled correctly
- [ ] Links styled correctly

---

## Section 6: Forms Verification

### 6.1 Contact Form Location
- [ ] Form visible on contact page
- [ ] All fields display
- [ ] Required fields marked

### 6.2 Form Submission
- [ ] Can fill out form
- [ ] Submit button works
- [ ] Success message shows
- [ ] No JavaScript errors

### 6.3 Email Redirect
- [ ] Email sent to tebogo@bigbeard.co.za
- [ ] Subject has [TEST - DEV] prefix
- [ ] Original recipient in body
- [ ] Content correct

### 6.4 Form Validation
- [ ] Required field validation works
- [ ] Email format validation works
- [ ] Error messages display

### 6.5 reCAPTCHA Status
- [ ] reCAPTCHA disabled for DEV
- [ ] Forms work without reCAPTCHA
- [ ] No reCAPTCHA errors

---

## Section 7: Plugin Verification

### 7.1 Elementor
- [ ] Elementor active
- [ ] Can edit pages
- [ ] Widgets available
- [ ] Templates accessible

### 7.2 Elementor Pro
- [ ] Pro features active
- [ ] Theme Builder works
- [ ] Pro widgets available

### 7.3 Yoast SEO
- [ ] Plugin active
- [ ] SEO meta visible
- [ ] Sitemap accessible
- [ ] No configuration errors

### 7.4 Contact Form 7
- [ ] Plugin active
- [ ] Forms editable
- [ ] Email integration working

---

## Section 8: SEO Verification

### 8.1 Meta Tags
- [ ] Title tag present
- [ ] Meta description present
- [ ] Canonical URL correct (new domain)

**Test Command:**
```bash
curl -s https://manufacturing.wpdev.kimmyai.io/ | grep -E "<title>|rel=\"canonical\"|name=\"description\"" | head -5
```

### 8.2 Open Graph
- [ ] og:title present
- [ ] og:description present
- [ ] og:image present
- [ ] og:url uses new domain

### 8.3 XML Sitemap
- [ ] Sitemap accessible at /sitemap_index.xml
- [ ] URLs use new domain
- [ ] No old domain references

**Test Command:**
```bash
curl -s https://manufacturing.wpdev.kimmyai.io/sitemap_index.xml | head -20
```

### 8.4 Robots.txt
- [ ] robots.txt accessible
- [ ] No blocking rules for DEV
- [ ] Sitemap reference correct

### 8.5 Schema Markup
- [ ] Structured data present (if any)
- [ ] No errors in markup
- [ ] URLs use new domain

---

## Section 9: Performance Verification

### 9.1 Page Load Time
- [ ] Homepage < 3 seconds
- [ ] Inner pages < 3 seconds
- [ ] No timeout errors

**Test Command:**
```bash
curl -s -o /dev/null -w "Time: %{time_total}s\n" https://manufacturing.wpdev.kimmyai.io/
```

**Expected:** < 3.0 seconds

### 9.2 CloudFront Caching
- [ ] Cache HIT on repeated requests
- [ ] Static assets cached
- [ ] Cache headers present

**Test Command:**
```bash
curl -sI https://manufacturing.wpdev.kimmyai.io/ | grep -i "x-cache"
```

**Expected:** X-Cache: Hit from cloudfront

### 9.3 Image Optimization
- [ ] Images appropriately sized
- [ ] No excessively large images
- [ ] Lazy loading working (if enabled)

### 9.4 Resource Loading
- [ ] No excessive HTTP requests
- [ ] CSS/JS minimized
- [ ] No 404 errors in console

---

## Section 10: Security Verification

### 10.1 SSL/TLS
- [ ] Valid SSL certificate
- [ ] Certificate not expired
- [ ] Strong encryption (TLS 1.2+)

**Test Command:**
```bash
curl -vI https://manufacturing.wpdev.kimmyai.io 2>&1 | grep -E "SSL certificate|subject:|expire"
```

### 10.2 WordPress Security
- [ ] Admin URL protected
- [ ] No directory listing
- [ ] wp-config.php not accessible

### 10.3 Login Security
- [ ] Brute force protection (if any)
- [ ] Failed login handling
- [ ] Session management working

### 10.4 Mixed Content
- [ ] No HTTP resources on HTTPS pages
- [ ] All assets use HTTPS

**Test Command:**
```bash
curl -s https://manufacturing.wpdev.kimmyai.io/ | grep -i "http://" | grep -v "https://" | head -3
```

**Expected:** No output (no HTTP URLs)

### 10.5 Headers
- [ ] Security headers present
- [ ] X-Content-Type-Options
- [ ] X-Frame-Options

---

## Section 11: Mobile Verification

### 11.1 iOS Safari
- [ ] Site loads correctly
- [ ] Navigation works
- [ ] Forms functional
- [ ] Images display

### 11.2 Android Chrome
- [ ] Site loads correctly
- [ ] Navigation works
- [ ] Forms functional
- [ ] Images display

### 11.3 Responsive Breakpoints
- [ ] 320px (small mobile)
- [ ] 768px (tablet)
- [ ] 1024px (desktop)
- [ ] 1440px (large desktop)

### 11.4 Touch Interactions
- [ ] Touch scrolling works
- [ ] Tap targets appropriate size
- [ ] Swipe gestures work (if any)
- [ ] Mobile menu functional

---

## Section 12: Browser Compatibility

### 12.1 Chrome (Latest)
- [ ] Site renders correctly
- [ ] No console errors
- [ ] All features work
- [ ] Performance acceptable

### 12.2 Firefox (Latest)
- [ ] Site renders correctly
- [ ] No console errors
- [ ] All features work
- [ ] Performance acceptable

### 12.3 Safari (Latest)
- [ ] Site renders correctly
- [ ] No console errors
- [ ] All features work
- [ ] Performance acceptable

### 12.4 Edge (Latest)
- [ ] Site renders correctly
- [ ] No console errors
- [ ] All features work
- [ ] Performance acceptable

---

## Sign-Off Section

### Test Summary

| Category | Pass | Fail | N/A | Notes |
|----------|------|------|-----|-------|
| Infrastructure | | | | |
| Site Access | | | | |
| Admin Access | | | | |
| Content | | | | |
| Theme & Design | | | | |
| Forms | | | | |
| Plugins | | | | |
| SEO | | | | |
| Performance | | | | |
| Security | | | | |
| Mobile | | | | |
| Browser Compatibility | | | | |
| **TOTAL** | | | | |

### Issues Found

| # | Issue | Severity | Status | Resolution |
|---|-------|----------|--------|------------|
| 1 | | | | |
| 2 | | | | |
| 3 | | | | |

### Final Sign-Off

**DEV Environment Ready for SIT Promotion:** [ ] YES  [ ] NO

**Tested By:** _________________________

**Date:** _________________________

**Signature:** _________________________

---

### Stakeholder Approval

**Business Owner Approval:** [ ] YES  [ ] NO

**Approved By:** _________________________

**Date:** _________________________

**Comments:**
```
[Enter any comments or conditions]
```

---

## Quick Reference

### Test URLs
- **Homepage:** https://manufacturing.wpdev.kimmyai.io/
- **Admin:** https://manufacturing.wpdev.kimmyai.io/wp-admin/
- **Sitemap:** https://manufacturing.wpdev.kimmyai.io/sitemap_index.xml

### Credentials
- **Username:** nigelbeard
- **Password:** MfgDev2026!

### Test Email
- **Recipient:** tebogo@bigbeard.co.za
- **Subject Prefix:** [TEST - DEV]

### Support Contacts
- **Technical Issues:** DevOps Team
- **Content Issues:** Business Owner
- **Approval:** Project Manager

---

**Document Version:** 1.0
**Created:** 2026-01-16
**Last Updated:** 2026-01-16
