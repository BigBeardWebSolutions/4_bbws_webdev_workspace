# PROD Site Analysis: TheTransitionThinkTank

**Site**: The Transition Think Tank
**Domain**: https://thetransitionthinktank.org
**Analysis Date**: 2026-01-29
**Analyst**: Claude (AI Agent)
**Scope**: Production site review - baseline for BBWS migration QA
**Environment**: PROD (Xneelo source hosting)

---

## Executive Summary

| Category | Severity | Issue Count |
|----------|----------|-------------|
| Performance | HIGH | 2 |
| URL Structure | LOW | 0 |
| SEO | MEDIUM | 2 |
| Security | HIGH | 5 |
| Infrastructure | LOW | 1 |

**Overall Assessment**: CONDITIONAL PASS - Site functions correctly but has performance and security gaps that the migration should address, not replicate.

---

## 1. Infrastructure Overview

### 1.1 Current Architecture

| Component | Expected | Actual | Status |
|-----------|----------|--------|--------|
| Hosting | Xneelo (source) | Apache on 197.221.10.19 | PASS |
| CDN | N/A (source is traditional hosting) | None detected | N/A |
| SSL | Enabled (HTTPS) | HTTP/2 200 | PASS |
| Server | Apache | Apache (header exposed) | PASS |
| Compression | gzip/brotli | **NOT DETECTED** | FAIL |

### 1.2 DNS Configuration

| Domain | Status | Target | Notes |
|--------|--------|--------|-------|
| thetransitionthinktank.org (apex) | Active | 197.221.10.19 | Direct IP (Xneelo) |
| www.thetransitionthinktank.org | Active | 197.221.10.19 | Same IP as apex |

### 1.3 SSL Certificate

| Check | Status | Details |
|-------|--------|---------|
| Certificate Valid | PASS | Expires: Apr 26, 2026 |
| Certificate Issuer | PASS | Let's Encrypt R12 |
| Domain Coverage | PASS | CN=thetransitionthinktank.org |
| HTTP→HTTPS Redirect | PASS | 301 redirect from HTTP to HTTPS |

---

## 2. Performance Analysis

### 2.1 Page Load Metrics

| Page | Size (bytes) | Size (KB) | TTFB (s) | HTTP | Assessment |
|------|-------------|-----------|-----------|------|------------|
| Homepage `/` | 364,984 | 356 KB | 1.32s | 200 | **HIGH** |
| About Us `/about-us/` | 535,536 | 523 KB | 1.06s | 200 | **HIGH** |
| Our Research `/our-research/` | 284,170 | 277 KB | 1.02s | **404** | **CRITICAL** |
| Contact Us `/contact-us/` | 400,367 | 391 KB | 1.03s | 200 | **HIGH** |
| Blog `/blog/` | 284,170 | 277 KB | 0.96s | **404** | **CRITICAL** |

### 2.2 Performance Benchmarks

| Metric | Current | Target | Status |
|--------|---------|--------|--------|
| TTFB (Time to First Byte) | 0.96 - 1.32s | < 200ms | **FAIL** |
| HTML Document Size (Homepage) | 356 KB | < 50 KB | **FAIL** |
| Compression | None detected | gzip/brotli | **FAIL** |

> **Note**: TTFB ~1s is expected for South Africa-hosted origin (197.221.10.19) accessed from outside Africa. After migration to AWS, TTFB should improve significantly with CloudFront CDN.

### 2.3 Key Pages Status (All Navigation)

| Page | HTTP Status |
|------|------------|
| `/about-us/` | 200 |
| `/our-offerings/` | 200 |
| `/contact-us/` | 200 |
| `/careers/` | 200 |
| `/gallery/` | 200 |
| `/media-portal/` | 200 |
| `/green-economy/` | 200 |
| `/transition-planning/` | 200 |
| `/value-management/` | 200 |
| `/privacy-policy/` | 200 |
| `/category/blog/` | 200 |
| `/category/events/` | 200 |
| `/our-research/` | **404** |
| `/blog/` | **404** |

### 2.4 JavaScript Dependencies

| Script | Type | Version |
|--------|------|---------|
| jQuery | Core | 3.7.1 |
| jQuery Migrate | Core | 3.4.1 |
| jQuery UI Core | Core | 1.13.3 |
| Elementor Frontend | Page Builder | 3.32.2 |
| Elementor Pro Frontend | Page Builder | 3.32.1 |
| Elementor webpack runtime | Page Builder | 3.32.2 |
| Elementor Pro webpack runtime | Page Builder | 3.32.1 |
| Elementor frontend-modules | Page Builder | 3.32.2 |
| Elementor Pro elements-handlers | Page Builder | 3.32.1 |
| SmartMenus jQuery | Navigation | 1.2.1 |
| jQuery Sticky | UI | 3.32.1 |
| imagesloaded | UI | 5.0.0 |
| WP hooks | Core | dd5603f |
| WP i18n | Core | c26c3dc |
| Hello Elementor theme JS | Theme | 3.4.4 |
| Ajax Search Lite | Plugin | 4.13.3 (build 4778) |
| Complianz GDPR | Plugin | 1756979860 |
| Gravity Forms reCAPTCHA | Plugin | 2.0.0 |
| Google reCAPTCHA Enterprise | External | - |
| Google Tag Manager/gtag | Tracking | G-YB6L23547D |

### 2.5 Tracking Scripts

| # | Service | Loaded | Mentions |
|---|---------|--------|----------|
| 1 | Google Tag Manager | Yes | 5 |
| 2 | gtag (Google Analytics 4) | Yes | 5 (ID: G-YB6L23547D) |
| 3 | LinkedIn Insight Tag | Yes | 3 |
| 4 | Google reCAPTCHA Enterprise | Yes | 1 (via Gravity Forms) |
| 5 | Facebook Pixel | No | 0 |
| 6 | Microsoft Clarity | No | 0 |
| 7 | Hotjar | No | 0 |

---

## 3. URL Structure Analysis

### 3.1 Internal Link Format

| Check | Status | Details |
|-------|--------|---------|
| Clean URLs (no index.html) | PASS | No index.html links found |
| Consistent link format | PASS | All use clean permalink structure |
| Trailing slash consistency | PASS | All URLs end with `/` |
| No broken internal links | FAIL | `/our-research/` and `/blog/` return 404 |

### 3.2 URL Patterns Found

Clean WordPress permalink structure used throughout:
- Category pages: `/category/blog/`, `/category/events/`, `/category/press-releases/`, `/category/case-studies/`
- Date-based posts: `/2025/09/02/restructuring-the-electricity-supply-market/`
- Anchor links: `/about-us/#our-team`, `/about-us/#our-values`

---

## 4. SEO Analysis

### 4.1 Critical SEO Files

| File | HTTP Status | Content-Type | Status |
|------|-------------|-------------|--------|
| robots.txt | 200 | text/html (!) | **FAIL** (wrong content-type, but content is correct) |
| sitemap_index.xml | 200 | text/xml | PASS |
| sitemap.xml | 301 → sitemap_index.xml | - | PASS (Yoast redirect) |
| favicon.ico | 200 | text/html (!) | **FAIL** (wrong content-type) |

**robots.txt Content (Yoast SEO)**:
```
User-agent: *
Disallow:
Sitemap: https://thetransitionthinktank.org/sitemap_index.xml
```

### 4.2 Meta Tags Assessment

| Element | Present? | Value / Notes |
|---------|----------|---------------|
| Title Tag | Yes | `Home - The Transition Think Tank` |
| Meta Description | Yes | `The Transition Think Tank (4T) — an independent, interdisciplinary organization dedicated to advancing climate resilient, low-carbon` |
| Canonical URL | Yes | `https://thetransitionthinktank.org/` |
| og:title | Yes | `The Transition Think Tank` |
| og:description | Yes | Full description present |
| og:image | Yes | `wp-content/uploads/2025/07/adobestock_standard_1135528990-1.jpg` (835x586) |
| og:type | Yes | `website` |
| og:locale | Yes | `en_US` |
| Twitter Card | Yes | `summary_large_image` |
| Twitter Title | Yes | `The Transition Think Tank` |
| Twitter Image | Yes | Same as og:image |
| Viewport | Yes | `width=device-width, initial-scale=1` |
| Language | Yes | `en-ZA` (South African English) |
| Structured Data (ld+json) | Yes | 1 block |
| Yoast SEO | Yes | 3 references |

### 4.3 Key SEO Plugins

- **Yoast SEO**: Active (manages robots.txt, sitemaps, meta tags, canonical URLs)
- **Complianz GDPR**: Active (cookie consent banner)

---

## 5. Security Analysis

### 5.1 Security Headers

| Header | Present? | Value | Status |
|--------|----------|-------|--------|
| X-Frame-Options | **No** | - | **FAIL** |
| X-Content-Type-Options | **No** | - | **FAIL** |
| X-XSS-Protection | **No** | - | **FAIL** |
| Strict-Transport-Security (HSTS) | **No** | - | **FAIL** |
| Content-Security-Policy | **No** | - | **FAIL** |
| Cache-Control | **No** (on homepage) | - | **FAIL** |
| Referrer-Policy | **No** | - | **FAIL** |
| Permissions-Policy | **No** | - | **FAIL** |
| Server | **Yes (Exposed)** | `Apache` | **FAIL** |

> **0 of 8 security headers present**. This is typical for Xneelo shared hosting without custom .htaccess hardening.

### 5.2 Exposed Information

| Exposure | Found? | Risk Level |
|----------|--------|------------|
| WordPress paths (wp-content/) | Yes | LOW (expected for WP) |
| WordPress paths (wp-includes/) | Yes | LOW (expected for WP) |
| wp-json API endpoint | Yes | MEDIUM |
| xmlrpc.php reference | Yes | MEDIUM |
| RSS Feed endpoints | Yes | LOW |
| Server version (Apache) | Yes | LOW |
| Wordfence references | No | N/A (cleaned from frontend) |

### 5.3 HTTPS & SSL

| Check | Status | Details |
|-------|--------|---------|
| HTTPS enforced | PASS | HTTP 301 → HTTPS |
| SSL certificate valid | PASS | Expires Apr 26, 2026 |
| Mixed content | PASS | No HTTP resources on HTTPS page |
| Compression | **FAIL** | No gzip/brotli detected |

---

## 6. WordPress Configuration (Relevant to Migration)

### 6.1 Active Theme

| Component | Value |
|-----------|-------|
| Parent Theme | `hello-elementor` v3.4.4 |
| Child Theme | `hello-theme-child-master` |
| Page Builder | Elementor v3.32.2 + Elementor Pro v3.32.1 |

### 6.2 Detected Plugins (from frontend assets)

| Plugin | Version | Purpose | Migration Note |
|--------|---------|---------|----------------|
| Elementor | 3.32.2 | Page builder | **CRITICAL** - Must be present |
| Elementor Pro | 3.32.1 | Page builder premium | **CRITICAL** - Needs license |
| Ajax Search Lite | 4.13.3 | Search functionality | Keep |
| Complianz GDPR | - | Cookie consent | Keep |
| Gravity Forms | - | Forms | Keep (license required) |
| Gravity Forms reCAPTCHA | 2.0.0 | Spam protection | Keep |
| Yoast SEO | - | SEO management | Keep |
| Wordfence | - | Security (in DB, not frontend) | **DEACTIVATE before import** |

### 6.3 External Service Dependencies

| Service | ID/Config | Action |
|---------|-----------|--------|
| Google Tag Manager | (via gtag) | Update if domain changes |
| Google Analytics 4 | G-YB6L23547D | Preserve GA tracking ID |
| Google reCAPTCHA Enterprise | 6LdcztUrAAAAAFYgIqQ-BD8-LbHv59XEJBdaoWPW | Verify site key works on new domain |
| LinkedIn Insight Tag | Present | Update allowed domains |
| Google Fonts | IBM Plex Sans, Roboto, Open Sans | Works automatically |
| Google Maps | maps.app.goo.gl link | Works automatically |

### 6.4 Font Dependencies

| Font | Source | Method |
|------|--------|--------|
| IBM Plex Sans | Google Fonts | CSS import |
| Roboto | Google Fonts | CSS import |
| Open Sans | Google Fonts | CSS import (loaded twice!) |

### 6.5 Image Analysis

| Format | Count | Notes |
|--------|-------|-------|
| .png | 11 | Most common format |
| .jpg | 7 | Photo content |
| .svg | 3 | Icons/logos |
| .webp | 2 | Modern format (limited use) |
| Lazy loading | 2 elements | Minimal lazy loading |

---

## 7. CDN/Cache Analysis

### 7.1 Current State (Source - Xneelo)

| Check | Status | Details |
|-------|--------|---------|
| CDN active | N/A | No CDN on source (direct Apache) |
| Cache-Control headers | FAIL | No cache headers on homepage |
| Compression | FAIL | No gzip/brotli encoding detected |
| ETag/Last-Modified | Not present on homepage | Only on feed |
| Error page (404) | Works | Returns proper 404 with `no-cache, must-revalidate` |

---

## 8. Feed & API Endpoints

| Endpoint | Status | Notes |
|----------|--------|-------|
| `/feed/` | 200 | RSS feed active, last modified 2025-11-21 |
| `/comments/feed/` | Referenced in HTML | Should work |
| `/wp-json/` | Active | WordPress REST API exposed |
| `/xmlrpc.php` | Referenced in HTML | Should be disabled post-migration |

---

## 9. Summary of Issues by Severity

### CRITICAL (Must Fix for Migration)

| # | Issue | Impact | Migration Action |
|---|-------|--------|------------------|
| 1 | Wordfence WAF in database | Will cause redirect loops post-migration | Run `prepare-wordpress-for-migration.sh` BEFORE import |
| 2 | Elementor Pro license | Will lose Pro features on new domain | Re-register license on new domain |
| 3 | Gravity Forms license | Forms will stop working | Re-register on new domain |
| 4 | Google reCAPTCHA site key | Bound to current domain | Add new domain to reCAPTCHA console |
| 5 | `siteurl` and `home` in wp_options | Must point to new domain | Search-replace in database |

### HIGH (Address During Migration)

| # | Issue | Impact | Migration Action |
|---|-------|--------|------------------|
| 1 | No compression (gzip/brotli) | 356KB uncompressed homepage | AWS ALB/CloudFront handles this automatically |
| 2 | TTFB > 1 second | Poor user experience | ECS + CloudFront will improve this |
| 3 | Zero security headers | Vulnerable to clickjacking, XSS | Add headers via CloudFront or .htaccess |
| 4 | `/our-research/` returns 404 | Broken navigation link (if linked) | Verify this is expected or fix post-migration |
| 5 | `/blog/` returns 404 | Blog content at `/category/blog/` instead | Verify URL structure is intentional |
| 6 | xmlrpc.php exposed | Brute-force attack vector | Block via mu-plugin or web server config |

### MEDIUM (Plan to Address)

| # | Issue | Impact | Migration Action |
|---|-------|--------|------------------|
| 1 | robots.txt returns `text/html` content-type | May confuse crawlers | WordPress dynamic robots.txt (normal WP behavior) |
| 2 | favicon.ico returns `text/html` content-type | Not a real favicon file | WordPress fallback behavior |
| 3 | Open Sans loaded twice | Wasted bandwidth | Dequeue duplicate in child theme |
| 4 | Minimal lazy loading (only 2 elements) | Slower perceived load | Enable WordPress native lazy loading |
| 5 | wp-json API fully exposed | Information disclosure | Consider restricting non-essential endpoints |
| 6 | Google Analytics ID exposed | Potential spam analytics | Standard for all GA implementations |
| 7 | LinkedIn Insight Tag | May need domain allowlisting | Update LinkedIn campaign settings |

### LOW (Consider Addressing)

| # | Issue | Impact | Migration Action |
|---|-------|--------|------------------|
| 1 | Server header exposes "Apache" | Minor info leak | Will change to AWS headers automatically |
| 2 | Feed last modified Nov 2025 | Stale content signal | Publish new content or update feed |
| 3 | Mostly PNG images (11 of 23) | Larger file sizes vs WebP | Consider WebP conversion |

---

## 10. Recommendations

### Quick Wins (Do During Migration)

| # | Recommendation | Category |
|---|----------------|----------|
| 1 | Run `prepare-wordpress-for-migration.sh` to deactivate Wordfence, Really Simple SSL, redirects | Security/Migration |
| 2 | Search-replace `thetransitionthinktank.org` → new dev domain in database | Configuration |
| 3 | Deploy `force-https.php` mu-plugin for HTTPS behind ALB | Infrastructure |
| 4 | Verify Elementor Pro license transfers to new domain | Functionality |
| 5 | Add Google reCAPTCHA new domain to console | Functionality |

### Medium Effort (Post-Migration Hardening)

| # | Recommendation | Category |
|---|----------------|----------|
| 1 | Add security headers (X-Frame-Options, HSTS, CSP, etc.) via CloudFront | Security |
| 2 | Block xmlrpc.php via mu-plugin or nginx config | Security |
| 3 | Restrict wp-json API to authenticated users only | Security |
| 4 | Enable gzip/brotli compression (CloudFront default) | Performance |
| 5 | Fix duplicate Open Sans font loading | Performance |

### Post-Cutover (DNS and External Services)

| # | Recommendation | Category |
|---|----------------|----------|
| 1 | Update Google Analytics property domain settings | Tracking |
| 2 | Update LinkedIn Insight Tag allowed domains | Tracking |
| 3 | Re-verify Google reCAPTCHA for production domain | Forms |
| 4 | Update Yoast SEO sitemap URL in Google Search Console | SEO |
| 5 | Verify all OG images resolve on new domain | SEO |

---

## Appendix A: Raw Performance Data

```
Homepage (/):
  DNS:     0.001s
  Connect: 0.008s
  TTFB:    1.319s
  Total:   1.453s
  Size:    364,984 bytes (356 KB)

About Us (/about-us/):
  TTFB:    1.058s
  Size:    535,536 bytes (523 KB)

Contact Us (/contact-us/):
  TTFB:    1.028s
  Size:    400,367 bytes (391 KB)
```

## Appendix B: HTTP Response Headers

```
HTTP/2 200
link: <https://thetransitionthinktank.org/wp-json/>; rel="https://api.w.org/",
      <https://thetransitionthinktank.org/wp-json/wp/v2/pages/2>; rel="alternate"; title="JSON"; type="application/json",
      <https://thetransitionthinktank.org/>; rel=shortlink
content-type: text/html; charset=UTF-8
date: Thu, 29 Jan 2026 08:45:08 GMT
server: Apache
```

## Appendix C: Full Site Navigation Map

```
Home (/)
├── About Us (/about-us/)
│   ├── #who-we-are
│   ├── #our-vision-and-mission
│   ├── #our-values
│   └── #our-team
├── Our Offerings (/our-offerings/)
│   ├── Transition Planning (/transition-planning/)
│   ├── Green Economy (/green-economy/)
│   └── Value Management (/value-management/)
├── Media Portal (/media-portal/)
│   ├── Blog (/category/blog/)
│   ├── Events (/category/events/)
│   ├── Press Releases (/category/press-releases/)
│   ├── Case Studies (/category/case-studies/)
│   └── Gallery (/gallery/)
├── Careers (/careers/)
├── Contact Us (/contact-us/)
└── Privacy Policy (/privacy-policy/)
```

## Appendix D: Migration-Critical Plugin Matrix

| Plugin | Has License? | Domain-Locked? | Action Required |
|--------|-------------|----------------|-----------------|
| Elementor Pro | Yes (paid) | Yes | Re-activate on new domain |
| Gravity Forms | Yes (paid) | Yes | Re-activate on new domain |
| Gravity Forms reCAPTCHA | Addon | No (but reCAPTCHA key is domain-locked) | Update reCAPTCHA domains |
| Yoast SEO | Unknown (free or premium) | No | Works automatically |
| Complianz GDPR | Unknown | No | Update domain in settings |
| Ajax Search Lite | Unknown | No | Works automatically |
| Wordfence | Deactivate | N/A | **MUST deactivate before import** |

---

**Report Generated**: 2026-01-29
**Template Version**: 1.0
**Status**: ANALYSIS COMPLETE
