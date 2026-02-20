# Big Beard Static Site Migration - Project Plan

**Document Version**: 1.0
**Created**: 2026-01-26
**Author**: Project Manager Agent
**Status**: Draft - Awaiting Approval

---

## 1. Executive Summary

### 1.1 Project Overview

The bigbeard.co.za website was recently migrated from WordPress (hosted on xneelo) to a static site hosted on AWS S3 with CloudFront CDN. While the migration successfully preserved the site content and functionality, a post-migration analysis has identified several critical, high, and medium priority issues that require remediation.

This project plan outlines a structured approach to address these issues across five implementation phases, prioritized by business impact and technical complexity.

### 1.2 Project Objectives

| Objective | Target Metric | Current State |
|-----------|---------------|---------------|
| Enable search engine crawling | robots.txt returns 200 OK | 403 Forbidden |
| Enable sitemap discovery | sitemap.xml returns 200 OK | 403 Forbidden |
| Clean URL structure | No index.html in URLs | index.html visible in all links |
| Improve page load performance | TTFB < 300ms | 500-1000ms |
| Reduce HTML document size | < 100KB per page | 145-454KB per page |
| Implement security headers | All OWASP headers present | No security headers |
| Consolidate tracking scripts | Single instance per service | Duplicate GA and FB Pixel |

### 1.3 Project Scope

**In Scope:**
- DEV environment fixes (bigbeard-migrated-site-dev S3 bucket)
- SEO file creation (robots.txt, sitemap.xml)
- URL structure remediation
- Security headers configuration
- Performance optimization (quick wins)
- Documentation and verification

**Out of Scope:**
- Full site rebuild with modern static site generator
- SIT and PROD environment deployment (future phases)
- New feature development
- Domain DNS management (requires DNS provider access)

### 1.4 Success Criteria

| Criteria | Measurement Method |
|----------|-------------------|
| SEO files accessible | HTTP 200 response for robots.txt and sitemap.xml |
| Clean URLs | No index.html visible in browser address bar after navigation |
| Security headers present | curl -I shows X-Frame-Options, HSTS, X-Content-Type-Options |
| Performance improved | Lighthouse score increase of 10+ points |
| Zero broken links | Full site crawl returns 0 broken internal links |

---

## 2. Project Background

### 2.1 Current State Architecture

| Component | Value |
|-----------|-------|
| **Hosting** | AWS S3 (static website hosting) |
| **CDN** | Amazon CloudFront |
| **DEV CloudFront URL** | https://d3puvv0zkbx1pd.cloudfront.net |
| **S3 Bucket** | bigbeard-migrated-site-dev |
| **Site Folder** | bigbeard/ |
| **Total Files** | 1,072 objects |
| **Total Size** | 250 MB |
| **SSL** | Enabled via CloudFront |
| **Origin Access** | CloudFront OAC (public access blocked) |

### 2.2 Issues Summary

The post-migration analysis identified 17 distinct issues categorized as follows:

| Severity | Count | Categories |
|----------|-------|------------|
| **Critical** | 4 | SEO (2), Performance (2) |
| **High** | 5 | URL Structure (2), Performance (2), Security (1) |
| **Medium** | 5 | Performance (3), SEO (1), Infrastructure (1) |
| **Low** | 3 | WordPress artifacts, unused resources |

### 2.3 Root Cause Analysis

The issues stem from the WordPress-to-static conversion process:

1. **HTTrack/wget export** - Preserved WordPress output verbatim including bloated HTML, inline styles, and JavaScript configurations
2. **Link structure** - Export tool converted relative links to explicit index.html references
3. **Missing files** - robots.txt and sitemap.xml were not included in the export
4. **No post-processing** - Exported files were uploaded directly without optimization

---

## 3. Phased Implementation Approach

### 3.1 Phase Overview

| Phase | Name | Duration | Priority | Effort |
|-------|------|----------|----------|--------|
| 1 | Critical SEO Fixes | 1 day | P0 - Critical | Low |
| 2 | URL Structure Remediation | 2-3 days | P1 - High | Medium |
| 3 | Security Headers Implementation | 1 day | P1 - High | Low |
| 4 | Performance Optimization | 3-5 days | P2 - Medium | Medium-High |
| 5 | Infrastructure and Documentation | 1-2 days | P3 - Low | Low |

### 3.2 Phase Dependencies

```
Phase 1 (SEO) -----> Phase 5 (Documentation)
                          ^
Phase 2 (URLs) ----------+
                          |
Phase 3 (Security) ------+
                          |
Phase 4 (Performance) ---+
```

Phases 1-4 can run in parallel. Phase 5 depends on completion of all other phases.

---

## 4. Phase 1: Critical SEO Fixes

### 4.1 Objective

Enable search engines to properly crawl and index the bigbeard.co.za website by providing accessible robots.txt and sitemap.xml files.

### 4.2 Tasks

#### Task 1.1: Create robots.txt

| Attribute | Value |
|-----------|-------|
| **Description** | Create a robots.txt file allowing all crawlers with sitemap reference |
| **Owner** | DevOps Engineer |
| **Estimated Effort** | 30 minutes |
| **Dependencies** | None |

**Acceptance Criteria:**
- [ ] robots.txt uploaded to S3 at `bigbeard/robots.txt`
- [ ] Content-Type set to `text/plain`
- [ ] File accessible via CloudFront (HTTP 200)
- [ ] Contains sitemap reference pointing to www.bigbeard.co.za/sitemap.xml

**Implementation:**
```bash
# Create robots.txt
cat > /tmp/robots.txt << 'EOF'
# Big Beard Web Solutions - robots.txt
# Generated: 2026-01-26

User-agent: *
Allow: /

# Sitemap location
Sitemap: https://www.bigbeard.co.za/sitemap.xml

# Block WordPress artifacts (non-functional)
Disallow: /wp-json/
Disallow: /feed/
Disallow: /comments/
EOF

# Upload to S3
aws s3 cp /tmp/robots.txt s3://bigbeard-migrated-site-dev/bigbeard/robots.txt \
  --profile Tebogo-dev \
  --content-type "text/plain"
```

#### Task 1.2: Generate Complete Sitemap

| Attribute | Value |
|-----------|-------|
| **Description** | Generate sitemap.xml containing all accessible pages |
| **Owner** | DevOps Engineer |
| **Estimated Effort** | 1 hour |
| **Dependencies** | None |

**Acceptance Criteria:**
- [ ] sitemap.xml uploaded to S3 at `bigbeard/sitemap.xml`
- [ ] Content-Type set to `application/xml`
- [ ] File accessible via CloudFront (HTTP 200)
- [ ] Contains all pages with clean URLs (no index.html)
- [ ] Valid XML sitemap schema

**Implementation Approach:**
1. List all index.html files in S3 bucket
2. Transform paths to clean URLs
3. Generate XML sitemap with proper lastmod dates
4. Upload to S3

#### Task 1.3: Invalidate CloudFront Cache

| Attribute | Value |
|-----------|-------|
| **Description** | Create CloudFront invalidation for robots.txt and sitemap.xml |
| **Owner** | DevOps Engineer |
| **Estimated Effort** | 15 minutes |
| **Dependencies** | Tasks 1.1, 1.2 |

**Acceptance Criteria:**
- [ ] Invalidation created for `/robots.txt` and `/sitemap.xml`
- [ ] Invalidation completes successfully
- [ ] Files return fresh content (not cached 403)

#### Task 1.4: Verify and Submit to Search Console

| Attribute | Value |
|-----------|-------|
| **Description** | Verify robots.txt and sitemap.xml accessibility, submit sitemap to GSC |
| **Owner** | Content Manager |
| **Estimated Effort** | 30 minutes |
| **Dependencies** | Task 1.3 |

**Acceptance Criteria:**
- [ ] `curl -I https://www.bigbeard.co.za/robots.txt` returns HTTP 200
- [ ] `curl -I https://www.bigbeard.co.za/sitemap.xml` returns HTTP 200
- [ ] Sitemap submitted to Google Search Console
- [ ] Sitemap shows no errors in GSC

### 4.3 Phase 1 Deliverables

| Deliverable | Format | Location |
|-------------|--------|----------|
| robots.txt | Text file | s3://bigbeard-migrated-site-dev/bigbeard/robots.txt |
| sitemap.xml | XML file | s3://bigbeard-migrated-site-dev/bigbeard/sitemap.xml |
| Verification report | Markdown | analysis/phase1_verification.md |

### 4.4 Phase 1 Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| CloudFront caching stale 403 | Medium | Low | Full cache invalidation |
| Sitemap missing pages | Low | Medium | Automated generation from S3 listing |
| S3 permissions issue | Low | High | Verify OAC policy allows access |

---

## 5. Phase 2: URL Structure Remediation

### 5.1 Objective

Remove all explicit `index.html` references from internal links so users see clean URLs in their browser address bar.

### 5.2 Tasks

#### Task 2.1: Create Backup of Current State

| Attribute | Value |
|-----------|-------|
| **Description** | Create full backup of bigbeard/ folder before modifications |
| **Owner** | DevOps Engineer |
| **Estimated Effort** | 15 minutes |
| **Dependencies** | None |

**Acceptance Criteria:**
- [ ] Full sync to backup location completed
- [ ] Backup location documented
- [ ] File count matches original (1,072 objects)

**Implementation:**
```bash
aws s3 sync s3://bigbeard-migrated-site-dev/bigbeard/ \
  s3://bigbeard-migrated-site-dev/bigbeard-backup-20260126/ \
  --profile Tebogo-dev
```

#### Task 2.2: Download HTML Files for Processing

| Attribute | Value |
|-----------|-------|
| **Description** | Download all HTML files to local temp directory |
| **Owner** | DevOps Engineer |
| **Estimated Effort** | 30 minutes |
| **Dependencies** | Task 2.1 |

**Acceptance Criteria:**
- [ ] All .html files downloaded to /tmp/bigbeard_fix/
- [ ] File structure preserved
- [ ] Count verified against S3

#### Task 2.3: Execute Link Replacement Script

| Attribute | Value |
|-----------|-------|
| **Description** | Run sed script to replace all index.html link references |
| **Owner** | DevOps Engineer |
| **Estimated Effort** | 1 hour |
| **Dependencies** | Task 2.2 |

**Acceptance Criteria:**
- [ ] All `href="index.html"` replaced with `href="./"`
- [ ] All `href="path/index.html"` replaced with `href="path/"`
- [ ] All `href="../index.html"` replaced with `href="../"`
- [ ] No false positives (external links unchanged)
- [ ] Canonical tags unchanged (already correct)

**Replacement Patterns:**
| Pattern | Replacement | Example |
|---------|-------------|---------|
| `href="index.html"` | `href="./"` | Homepage links |
| `href="about/index.html"` | `href="about/"` | Nav links |
| `href="../index.html"` | `href="../"` | Relative parent links |
| `href="../../index.html"` | `href="../../"` | Deep relative links |

#### Task 2.4: Local Testing and Validation

| Attribute | Value |
|-----------|-------|
| **Description** | Serve files locally and test all navigation links |
| **Owner** | QA / DevOps Engineer |
| **Estimated Effort** | 2 hours |
| **Dependencies** | Task 2.3 |

**Acceptance Criteria:**
- [ ] Local web server running modified files
- [ ] All main navigation links tested
- [ ] All service page links tested
- [ ] All project page links tested
- [ ] All blog page links tested
- [ ] No broken links detected
- [ ] No index.html visible in any URL

#### Task 2.5: Upload Modified Files to S3

| Attribute | Value |
|-----------|-------|
| **Description** | Sync modified HTML files back to S3 |
| **Owner** | DevOps Engineer |
| **Estimated Effort** | 30 minutes |
| **Dependencies** | Task 2.4 |

**Acceptance Criteria:**
- [ ] All modified .html files uploaded
- [ ] Content-Type preserved as text/html
- [ ] File count unchanged

#### Task 2.6: CloudFront Invalidation and Verification

| Attribute | Value |
|-----------|-------|
| **Description** | Invalidate all HTML files and verify changes |
| **Owner** | DevOps Engineer |
| **Estimated Effort** | 1 hour |
| **Dependencies** | Task 2.5 |

**Acceptance Criteria:**
- [ ] Full invalidation created for `/*.html` and `/*/`
- [ ] Invalidation completes successfully
- [ ] Live site tested - no index.html in URLs
- [ ] All pages accessible via clean URLs

### 5.3 Phase 2 Deliverables

| Deliverable | Format | Location |
|-------------|--------|----------|
| Pre-modification backup | S3 folder | bigbeard-backup-20260126/ |
| Link replacement script | Bash script | scripts/fix_index_html_links.sh |
| Test report | Markdown | analysis/phase2_test_report.md |

### 5.4 Phase 2 Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Broken links after replacement | Medium | High | Full backup, local testing |
| External links modified | Low | Medium | Careful regex patterns |
| Missed edge cases | Medium | Low | Comprehensive link crawl |
| Performance regression | Low | Low | No change to file sizes |

---

## 6. Phase 3: Security Headers Implementation

### 6.1 Objective

Implement security headers via CloudFront Response Headers Policy to protect against common web vulnerabilities.

### 6.2 Tasks

#### Task 3.1: Create Response Headers Policy

| Attribute | Value |
|-----------|-------|
| **Description** | Create CloudFront Response Headers Policy with security headers |
| **Owner** | DevOps Engineer |
| **Estimated Effort** | 1 hour |
| **Dependencies** | None |

**Acceptance Criteria:**
- [ ] Policy created with name `bigbeard-security-headers-dev`
- [ ] X-Frame-Options: DENY
- [ ] X-Content-Type-Options: nosniff
- [ ] X-XSS-Protection: 1; mode=block
- [ ] Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
- [ ] Referrer-Policy: strict-origin-when-cross-origin
- [ ] Content-Security-Policy: Configured for site requirements
- [ ] Permissions-Policy: Restrictive defaults

**Required Headers:**
| Header | Value | Purpose |
|--------|-------|---------|
| X-Frame-Options | DENY | Prevent clickjacking |
| X-Content-Type-Options | nosniff | Prevent MIME sniffing |
| X-XSS-Protection | 1; mode=block | XSS filter (legacy) |
| Strict-Transport-Security | max-age=31536000; includeSubDomains | Force HTTPS |
| Referrer-Policy | strict-origin-when-cross-origin | Privacy |
| Permissions-Policy | geolocation=(), microphone=(), camera=() | Feature restrictions |

#### Task 3.2: Attach Policy to DEV Distribution

| Attribute | Value |
|-----------|-------|
| **Description** | Update CloudFront distribution to use response headers policy |
| **Owner** | DevOps Engineer |
| **Estimated Effort** | 30 minutes |
| **Dependencies** | Task 3.1 |

**Acceptance Criteria:**
- [ ] Policy attached to DEV CloudFront distribution (d3puvv0zkbx1pd)
- [ ] Distribution update deployed
- [ ] No distribution errors

#### Task 3.3: Verify Security Headers

| Attribute | Value |
|-----------|-------|
| **Description** | Verify all security headers are present in responses |
| **Owner** | QA / DevOps Engineer |
| **Estimated Effort** | 30 minutes |
| **Dependencies** | Task 3.2 |

**Acceptance Criteria:**
- [ ] curl -I shows all expected headers
- [ ] Security Headers tool (securityheaders.com) shows A or A+ grade
- [ ] No CSP violations in browser console for normal site usage

### 6.3 Phase 3 Deliverables

| Deliverable | Format | Location |
|-------------|--------|----------|
| Response Headers Policy | AWS Resource | CloudFront Policies |
| Security headers verification | Markdown | analysis/phase3_security_report.md |

### 6.4 Phase 3 Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| CSP blocks required scripts | Medium | High | Test CSP in report-only mode first |
| HSTS prevents HTTP access | Low | Low | Site already HTTPS-only |
| Third-party embed breakage | Medium | Medium | Whitelist required frame-src |

---

## 7. Phase 4: Performance Optimization

### 7.1 Objective

Improve page load performance through quick-win optimizations without requiring a full site rebuild.

### 7.2 Tasks

#### Task 4.1: Remove Duplicate Tracking Scripts

| Attribute | Value |
|-----------|-------|
| **Description** | Remove duplicate Google Analytics and Facebook Pixel scripts |
| **Owner** | DevOps Engineer |
| **Estimated Effort** | 2 hours |
| **Dependencies** | Phase 2 (URLs) - to avoid double-processing |

**Acceptance Criteria:**
- [ ] Only one Google Analytics script per page
- [ ] Only one Facebook Pixel per page
- [ ] All tracking still functional (verify in GA/FB dashboards)

**Current State:**
- Google Analytics: 2 instances (G-1Z64YK4X9D, G-1BGQ9Z2Y0K)
- Facebook Pixel: 2 instances (357572399941553, 1318746479850751)

**Action:** Confirm with stakeholder which IDs to keep.

#### Task 4.2: Set S3 Object Cache-Control Headers

| Attribute | Value |
|-----------|-------|
| **Description** | Configure cache-control metadata on S3 objects |
| **Owner** | DevOps Engineer |
| **Estimated Effort** | 1 hour |
| **Dependencies** | None |

**Acceptance Criteria:**
- [ ] HTML files: Cache-Control: public, max-age=3600 (1 hour)
- [ ] CSS/JS files: Cache-Control: public, max-age=31536000 (1 year)
- [ ] Images: Cache-Control: public, max-age=31536000 (1 year)
- [ ] CloudFront respects origin cache headers

**Cache Policy:**
| File Type | max-age | Rationale |
|-----------|---------|-----------|
| .html | 1 hour | Frequently updated content |
| .css, .js | 1 year | Versioned assets |
| .png, .jpg, .webp | 1 year | Static images |
| .woff, .woff2 | 1 year | Font files |

#### Task 4.3: HTML Minification

| Attribute | Value |
|-----------|-------|
| **Description** | Minify all HTML files to reduce document size |
| **Owner** | DevOps Engineer |
| **Estimated Effort** | 2 hours |
| **Dependencies** | Phase 2 (URLs) - to avoid double-processing |

**Acceptance Criteria:**
- [ ] All HTML files minified using html-minifier-terser
- [ ] Inline CSS minified
- [ ] Inline JS minified
- [ ] Comments removed
- [ ] Whitespace collapsed
- [ ] Site functionality unchanged
- [ ] 20-30% reduction in HTML file sizes

**Expected Results:**
| Page | Current Size | Target Size | Reduction |
|------|--------------|-------------|-----------|
| Homepage | 380 KB | <300 KB | 20%+ |
| Projects | 454 KB | <360 KB | 20%+ |
| About | 277 KB | <220 KB | 20%+ |

#### Task 4.4: Remove Unused WordPress Artifacts

| Attribute | Value |
|-----------|-------|
| **Description** | Remove references to non-functional WordPress endpoints |
| **Owner** | DevOps Engineer |
| **Estimated Effort** | 1 hour |
| **Dependencies** | Phase 2 (URLs) |

**Acceptance Criteria:**
- [ ] wp-json link tags removed from HTML head
- [ ] RSS feed link tags removed from HTML head
- [ ] oEmbed link tags removed from HTML head
- [ ] No 403 errors in browser console

**Elements to Remove:**
```html
<link rel="alternate" type="application/json+oembed" href="...wp-json/oembed...">
<link rel="alternate" type="text/xml+oembed" href="...wp-json/oembed...">
<link rel="alternate" type="application/rss+xml" href=".../feed/">
```

#### Task 4.5: Performance Verification

| Attribute | Value |
|-----------|-------|
| **Description** | Run Lighthouse audit and document improvements |
| **Owner** | QA |
| **Estimated Effort** | 1 hour |
| **Dependencies** | Tasks 4.1-4.4 |

**Acceptance Criteria:**
- [ ] Lighthouse Performance score documented (before/after)
- [ ] TTFB improvement measured
- [ ] Total page size reduction documented
- [ ] Core Web Vitals improvements noted

### 7.3 Phase 4 Deliverables

| Deliverable | Format | Location |
|-------------|--------|----------|
| Minification script | Bash script | scripts/minify_html.sh |
| Performance report | Markdown | analysis/phase4_performance_report.md |
| Lighthouse reports | JSON/HTML | analysis/lighthouse/ |

### 7.4 Phase 4 Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Minification breaks JS | Low | High | Full testing, backup available |
| Tracking loss | Medium | Medium | Verify in analytics dashboards |
| Layout issues | Low | Medium | Visual regression testing |

---

## 8. Phase 5: Infrastructure and Documentation

### 8.1 Objective

Complete infrastructure tasks and document all changes for SIT/PROD promotion.

### 8.2 Tasks

#### Task 5.1: DNS Investigation for dev.bigbeard.co.za

| Attribute | Value |
|-----------|-------|
| **Description** | Investigate DNS requirements for dev subdomain |
| **Owner** | DevOps Engineer |
| **Estimated Effort** | 1 hour |
| **Dependencies** | None |

**Acceptance Criteria:**
- [ ] Current DNS provider identified
- [ ] Required DNS records documented
- [ ] ACM certificate requirements documented
- [ ] CloudFront alternate domain configuration documented

**Note:** This task is informational only. DNS changes require access to the DNS provider which may be external (xneelo, Cloudflare, etc.).

#### Task 5.2: Create Promotion Runbook

| Attribute | Value |
|-----------|-------|
| **Description** | Document steps to promote fixes from DEV to SIT to PROD |
| **Owner** | Project Manager |
| **Estimated Effort** | 2 hours |
| **Dependencies** | All phases complete |

**Acceptance Criteria:**
- [ ] Step-by-step promotion guide
- [ ] Environment-specific variables documented
- [ ] Verification steps for each environment
- [ ] Rollback procedures included

#### Task 5.3: Update Project Documentation

| Attribute | Value |
|-----------|-------|
| **Description** | Update all project documentation with changes made |
| **Owner** | Project Manager |
| **Estimated Effort** | 2 hours |
| **Dependencies** | All phases complete |

**Acceptance Criteria:**
- [ ] Analysis report updated with resolved issues
- [ ] Fix plan marked complete
- [ ] Lessons learned documented
- [ ] Future recommendations documented

### 8.3 Phase 5 Deliverables

| Deliverable | Format | Location |
|-------------|--------|----------|
| DNS documentation | Markdown | analysis/dns_requirements.md |
| Promotion runbook | Markdown | runbooks/bigbeard_promotion.md |
| Project closeout | Markdown | analysis/bigbeard_closeout.md |

---

## 9. Timeline

### 9.1 Gantt Chart

```
Week 1
-----------------------------------------------------------------------
| Day 1        | Day 2        | Day 3        | Day 4        | Day 5  |
-----------------------------------------------------------------------
| Phase 1      |              |              |              |        |
| SEO Fixes    |              |              |              |        |
|              | Phase 2      | Phase 2      |              |        |
|              | URL Fix      | Testing      |              |        |
|              |              | Phase 3      |              |        |
|              |              | Security     |              |        |
|              |              |              | Phase 4      | Phase 4|
|              |              |              | Performance  | Verify |
-----------------------------------------------------------------------

Week 2
-----------------------------------------------------------------------
| Day 1        | Day 2        |
|--------------|--------------|
| Phase 5      | Phase 5      |
| Docs         | Closeout     |
-----------------------------------------------------------------------
```

### 9.2 Estimated Duration

| Phase | Duration | Start | End |
|-------|----------|-------|-----|
| Phase 1 | 1 day | Day 1 | Day 1 |
| Phase 2 | 2 days | Day 2 | Day 3 |
| Phase 3 | 1 day | Day 3 | Day 3 |
| Phase 4 | 2 days | Day 4 | Day 5 |
| Phase 5 | 2 days | Day 6 | Day 7 |
| **Total** | **7 working days** | | |

### 9.3 Milestones

| Milestone | Target Date | Criteria |
|-----------|-------------|----------|
| M1: SEO Fixed | Day 1 | robots.txt and sitemap.xml accessible |
| M2: URLs Fixed | Day 3 | No index.html in any URL |
| M3: Security Implemented | Day 3 | All security headers present |
| M4: Performance Improved | Day 5 | Lighthouse score improved |
| M5: Project Complete | Day 7 | All documentation complete |

---

## 10. Resource Requirements

### 10.1 Team Roles

| Role | Responsibilities | Allocation |
|------|------------------|------------|
| **Project Manager** | Planning, coordination, documentation | 20% |
| **DevOps Engineer** | Script development, S3/CloudFront operations | 60% |
| **QA Engineer** | Testing, verification, regression testing | 15% |
| **Content Manager** | GSC submission, stakeholder communication | 5% |

### 10.2 Technical Resources

| Resource | Purpose | Access Required |
|----------|---------|-----------------|
| AWS Account (DEV) | S3, CloudFront operations | Tebogo-dev profile |
| Local development environment | Script testing, file processing | Node.js, bash |
| Google Search Console | Sitemap submission | bigbeard.co.za property owner |
| DNS Provider | DNS investigation | Read-only access |

### 10.3 Tools

| Tool | Purpose | License |
|------|---------|---------|
| AWS CLI | S3 and CloudFront operations | Open source |
| html-minifier-terser | HTML minification | MIT |
| curl | HTTP testing | Open source |
| Lighthouse | Performance auditing | Open source |
| Security Headers Scanner | Header verification | Free online tool |

---

## 11. Risk Assessment

### 11.1 Risk Register

| ID | Risk | Category | Likelihood | Impact | Score | Mitigation | Owner |
|----|------|----------|------------|--------|-------|------------|-------|
| R1 | Broken links after URL fix | Technical | Medium | High | 6 | Full backup, local testing, staged rollout | DevOps |
| R2 | SEO ranking fluctuation | Business | Medium | Medium | 4 | Proper redirects, canonical tags verified | PM |
| R3 | CloudFront cache issues | Technical | Medium | Low | 2 | Full invalidation after changes | DevOps |
| R4 | CSP blocks third-party scripts | Technical | Medium | High | 6 | Test in report-only mode, whitelist required sources | DevOps |
| R5 | Minification breaks functionality | Technical | Low | High | 3 | Local testing, visual regression tests | QA |
| R6 | Tracking data loss | Business | Low | Medium | 2 | Verify in analytics before removing duplicates | PM |
| R7 | Scope creep | Project | Medium | Medium | 4 | Clear scope definition, change control | PM |

### 11.2 Risk Matrix

```
           IMPACT
           Low    Medium   High
         +------+--------+------+
 High    |      |  R7    | R1,R4|
Likelihood +------+--------+------+
 Medium  |  R3  |  R2,R6 |      |
         +------+--------+------+
 Low     |      |  R5    |      |
         +------+--------+------+
```

### 11.3 Contingency Plans

**R1/R4 - High Impact Risks:**
- Pre-change backup stored in separate S3 prefix
- Rollback script documented and tested
- Maximum 30-minute rollback time

**R2 - SEO Ranking:**
- Monitor Google Search Console daily for 2 weeks post-change
- 301 redirects available if needed via CloudFront Function
- Sitemap resubmission ready

---

## 12. Quality Assurance

### 12.1 Testing Strategy

| Test Type | Phase | Scope | Method |
|-----------|-------|-------|--------|
| Unit | 1-4 | Individual files | Manual inspection |
| Integration | 2-4 | Full site navigation | Browser testing |
| Regression | 2-4 | Visual appearance | Screenshot comparison |
| Performance | 4 | Page load metrics | Lighthouse |
| Security | 3 | Header verification | curl, online tools |

### 12.2 Acceptance Testing Checklist

**Phase 1 - SEO:**
- [ ] robots.txt returns HTTP 200
- [ ] sitemap.xml returns HTTP 200
- [ ] sitemap.xml validates against schema
- [ ] Google Search Console accepts sitemap

**Phase 2 - URLs:**
- [ ] Homepage navigation - no index.html
- [ ] Service pages - no index.html
- [ ] Project pages - no index.html
- [ ] Blog pages - no index.html
- [ ] Footer links - no index.html
- [ ] No 404 errors on any link

**Phase 3 - Security:**
- [ ] X-Frame-Options present
- [ ] X-Content-Type-Options present
- [ ] Strict-Transport-Security present
- [ ] Content-Security-Policy present
- [ ] Site functions normally (no CSP blocks)

**Phase 4 - Performance:**
- [ ] HTML files reduced by 20%+
- [ ] No duplicate tracking scripts
- [ ] Lighthouse score improved
- [ ] Site loads without errors

---

## 13. Communication Plan

### 13.1 Stakeholders

| Stakeholder | Role | Communication | Frequency |
|-------------|------|---------------|-----------|
| Project Sponsor | Approval authority | Status reports | End of each phase |
| Technical Lead | Technical decisions | Daily standups | Daily |
| DevOps Team | Execution | Slack channel | Real-time |
| QA Team | Testing | Test reports | Per phase |

### 13.2 Communication Channels

| Channel | Purpose | Participants |
|---------|---------|--------------|
| Slack #bigbeard-fix | Day-to-day coordination | All team members |
| Email | Formal approvals, reports | Stakeholders |
| Confluence | Documentation | All |
| JIRA | Task tracking | Technical team |

### 13.3 Status Reporting

**Daily:** Brief Slack update on progress
**Per Phase:** Completion report with verification evidence
**Project End:** Final closeout report with lessons learned

---

## 14. Approval and Sign-off

### 14.1 Document Approval

| Role | Name | Signature | Date |
|------|------|-----------|------|
| Project Sponsor | | | |
| Technical Lead | | | |
| QA Lead | | | |

### 14.2 Phase Approvals

| Phase | Approval Required | Approver | Date |
|-------|-------------------|----------|------|
| Phase 1 | Go/No-Go | Technical Lead | |
| Phase 2 | Go/No-Go | Technical Lead | |
| Phase 3 | Go/No-Go | Technical Lead | |
| Phase 4 | Go/No-Go | Technical Lead | |
| Phase 5 | Project Closeout | Project Sponsor | |

---

## 15. Appendices

### Appendix A: File Inventory

| Location | File Count | Size | Content Type |
|----------|------------|------|--------------|
| bigbeard/ (root) | 6 | ~1 MB | HTML pages |
| about/ | 1 | 288 KB | HTML |
| services/ | 7 | ~1.5 MB | HTML |
| blog/ | 1 | 146 KB | HTML |
| projects/ | 1 | 465 KB | HTML |
| wp-content/uploads/ | 737 | 203 MB | Images |
| wp-content/plugins/ | ~200 | ~30 MB | JS/CSS |
| wp-includes/ | ~100 | ~15 MB | JS/CSS |
| **Total** | **1,072** | **250 MB** | |

### Appendix B: Reference Documents

| Document | Location | Purpose |
|----------|----------|---------|
| Site Analysis Report | analysis/bigbeard_site_analysis_2026-01-26.md | Detailed issue analysis |
| Technical Fix Plan | analysis/bigbeard_fix_plan_2026-01-26.md | Implementation scripts |
| BBWS Platform Architecture | ../docs/architecture.md | Platform context |

### Appendix C: Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-26 | Project Manager Agent | Initial document |

---

**Document Status**: Draft - Awaiting Approval
**Next Review**: Upon stakeholder feedback
**Environment**: DEV (bigbeard-migrated-site-dev)
