# Website Testing Skill

**Version**: 1.0
**Created**: 2025-12-21
**Purpose**: Comprehensive website quality assurance through sitemap validation, link checking, resource optimization analysis, automated testing, and detailed reporting

---

## Skill Identity

**Name**: Website Testing
**Type**: Quality assurance and testing skill
**Domain**: Website testing, link validation, resource optimization, accessibility testing, performance analysis, SEO validation, and comprehensive quality assurance reporting

---

## Purpose

The Website Testing skill provides comprehensive website quality assurance capabilities for WordPress sites, static sites, and SPAs. This skill systematically validates website integrity through automated testing workflows that identify broken links, unused resources, accessibility issues, performance bottlenecks, and SEO problems.

**Core Testing Capabilities**:
- **Sitemap Validation**: XML sitemap verification, completeness checking, Google Search Console validation
- **Page Inventory**: Comprehensive page listing, orphan page detection, missing page identification
- **Hyperlink Validation**: Internal link checking, external link validation, broken link detection, redirect chain analysis
- **Link Reporting**: Detailed reports of valid/invalid links, 404 errors, redirect issues, anchor errors
- **Unused Page Detection**: Identify pages not linked from navigation or content (orphan pages)
- **Unused Resource Analysis**: Find JavaScript files, CSS files, and images not referenced by any page
- **Automated Page Testing**: Accessibility (WCAG compliance), performance (Core Web Vitals), SEO validation
- **Assertion-Based Testing**: Custom test cases, validation rules, regression testing
- **Comprehensive Reporting**: Detailed test findings, actionable recommendations, metrics dashboards

**Value Provided**:
- **Quality Assurance**: Catch issues before they impact users or search rankings
- **SEO Optimization**: Ensure all pages are discoverable and properly indexed
- **Performance Improvement**: Identify and remove unused resources to reduce page weight
- **Accessibility Compliance**: Validate WCAG 2.1 AA/AAA compliance for inclusive design
- **Technical Debt Reduction**: Find and eliminate orphan pages and unused assets
- **Pre-Launch Validation**: Comprehensive site testing before going live
- **Maintenance Audits**: Regular health checks for ongoing site quality

---

## Testing Workflow (9-Step Process)

### Step 1: Validate Sitemap

**Purpose**: Verify XML sitemap exists, is valid, and includes all discoverable pages

**Actions**:
1. Check if XML sitemap exists (`/sitemap.xml`, `/sitemap_index.xml`)
2. Parse XML sitemap and validate structure against sitemap protocol
3. Verify all URLs in sitemap are accessible (HTTP 200)
4. Check for sitemap errors (malformed URLs, incorrect date formats)
5. Validate sitemap submission to search engines (Google Search Console, Bing Webmaster)
6. Compare sitemap URLs against actual site pages (missing pages, extra pages)
7. Check sitemap last modification date and update frequency

**Tools Used**:
- XML parser for sitemap validation
- HTTP client for URL accessibility checks
- Sitemap protocol validator
- Google Search Console API (if credentials provided)

**Output**: Sitemap validation report with findings and recommendations

---

### Step 2: List Pages

**Purpose**: Create comprehensive inventory of all pages on the website

**Actions**:
1. Crawl website starting from homepage using breadth-first search
2. Extract all internal page URLs (HTML pages, not assets)
3. Categorize pages by type (pages, posts, archives, custom post types)
4. Identify page hierarchy (parent pages, child pages, depth level)
5. Extract page metadata (title, meta description, canonical URL)
6. Detect orphan pages (pages not linked from any other page)
7. Find pages missing from sitemap but accessible via crawl
8. Identify pages in sitemap but not discoverable via crawl

**Tools Used**:
- Web crawler (Scrapy, Puppeteer, or custom crawler)
- HTML parser (BeautifulSoup, Cheerio)
- URL normalizer (handle trailing slashes, query parameters)

**Output**: Complete page inventory with categorization, hierarchy, and discoverability status

---

### Step 3: Validate Hyperlinks

**Purpose**: Check all links (internal and external) for validity and proper functionality

**Actions**:
1. Extract all hyperlinks from every page (`<a href="">` tags)
2. Categorize links (internal, external, anchors, mailto, tel)
3. Validate internal links (check if target page exists, returns HTTP 200)
4. Validate external links (check if external resource is accessible)
5. Check for broken links (HTTP 404, 500 errors)
6. Identify redirect chains (HTTP 301/302 redirects)
7. Validate anchor links (check if `#anchor` exists on target page)
8. Check for mixed content (HTTP links on HTTPS pages)
9. Identify suspicious links (javascript:void(0), malformed URLs)
10. Test link accessibility (check if links are keyboard-accessible)

**Tools Used**:
- Link extractor (parses HTML for all `<a>` tags)
- HTTP client for link validation (supports HEAD requests for efficiency)
- Redirect chain analyzer
- Anchor link validator

**Output**: Complete link inventory with validation status for each link

---

### Step 4: Generate Link Report (Valid and Invalid Links)

**Purpose**: Produce detailed report categorizing all links by status

**Report Sections**:

**4.1 Summary Statistics**:
- Total links found: 1,245
- Valid internal links: 987 (79.3%)
- Valid external links: 156 (12.5%)
- Broken links (404): 23 (1.8%)
- Server errors (5xx): 5 (0.4%)
- Redirect chains: 42 (3.4%)
- Anchor link errors: 12 (1.0%)
- Other errors: 20 (1.6%)

**4.2 Broken Links (HTTP 404)**:
| Page | Link | Status | Recommendation |
|------|------|--------|----------------|
| /about | /team/old-member | 404 | Remove or update link |
| /blog/post-1 | /images/missing.jpg | 404 | Fix image path |

**4.3 Server Errors (HTTP 5xx)**:
| Page | Link | Status | Recommendation |
|------|------|--------|----------------|
| /contact | /api/submit | 500 | Fix API endpoint |

**4.4 Redirect Chains**:
| Page | Link | Redirect Chain | Recommendation |
|------|------|----------------|----------------|
| /home | /old → /new → /latest | 3 hops | Update to final URL |

**4.5 External Link Issues**:
| Page | External Link | Status | Recommendation |
|------|---------------|--------|----------------|
| /resources | https://deadsite.com | DNS Error | Remove or replace |

**4.6 Anchor Link Errors**:
| Page | Anchor Link | Issue | Recommendation |
|------|-------------|-------|----------------|
| /faq | #section-5 | Anchor not found | Add anchor or fix link |

**Output**: Detailed link validation report with actionable recommendations

---

### Step 5: Identify Unused Pages

**Purpose**: Find pages that exist but are not linked from navigation or content (orphan pages)

**Actions**:
1. Compare page inventory (from Step 2) against all discovered links (from Step 3)
2. Identify pages with zero inbound internal links
3. Check if orphan pages are in sitemap (indexed but not linked)
4. Analyze orphan pages for business value (should they be deleted or linked?)
5. Check if orphan pages receive organic traffic (Google Analytics integration)
6. Identify pages only accessible via direct URL (not discoverable)

**Categories of Unused Pages**:
- **True Orphans**: No inbound links, not in navigation, not in sitemap
- **Sitemap-Only Pages**: In sitemap but no internal links
- **Old Content**: Pages from previous site versions never removed
- **Test Pages**: Development/staging pages accidentally published
- **Hidden Pages**: Intentionally unlinked (e.g., thank-you pages after form submission)

**Output**: List of unused pages with recommendation to delete, link, or keep

---

### Step 6: Identify Unused Resources (JavaScript, Images, CSS)

**Purpose**: Find assets (JS, CSS, images) that are loaded but never used, wasting bandwidth

**Actions**:

**6.1 JavaScript Analysis**:
1. Extract all `<script src="">` tags from all pages
2. Identify JavaScript files loaded on each page
3. Use browser DevTools Coverage API to measure JS usage
4. Flag JavaScript files with <20% usage (mostly unused)
5. Identify duplicate JavaScript libraries (multiple jQuery versions)
6. Check for unused npm packages in bundle analysis

**6.2 CSS Analysis**:
1. Extract all `<link rel="stylesheet">` and `<style>` tags
2. Identify CSS files loaded on each page
3. Use browser DevTools Coverage API to measure CSS usage
4. Flag CSS files with <30% usage (mostly unused)
5. Identify duplicate CSS (same styles defined multiple times)
6. Check for unused Tailwind CSS classes or Bootstrap components

**6.3 Image Analysis**:
1. Extract all `<img>`, `<picture>`, `background-image` references
2. Build inventory of all image files in `/uploads` or `/images` directories
3. Compare inventory against referenced images
4. Identify images in filesystem but not referenced by any page
5. Check for oversized images (>500KB) that should be optimized
6. Identify duplicate images (same image with different filenames)

**Tools Used**:
- Puppeteer with Coverage API for JS/CSS analysis
- Static file system scanner for asset inventory
- Image comparison tools for duplicate detection
- Webpack Bundle Analyzer or similar for bundle analysis

**Output**: Unused resource report with file sizes and recommendations for removal

---

### Step 7: Test All Pages and Links

**Purpose**: Automated testing of every page for accessibility, performance, and SEO

**Test Categories**:

**7.1 Accessibility Testing (WCAG 2.1 AA/AAA)**:
- Color contrast ratios (text vs background ≥4.5:1)
- Alt text for images (all images have descriptive alt text)
- Keyboard navigation (all interactive elements accessible via keyboard)
- ARIA labels and roles (proper semantic HTML)
- Form labels (all form inputs have associated labels)
- Heading hierarchy (proper H1 → H2 → H3 structure)
- Link text clarity (no "click here" or ambiguous link text)

**7.2 Performance Testing (Core Web Vitals)**:
- Largest Contentful Paint (LCP) <2.5s
- First Input Delay (FID) <100ms
- Cumulative Layout Shift (CLS) <0.1
- Time to First Byte (TTFB) <500ms
- Total page size <3MB
- Number of HTTP requests <50
- Image optimization (WebP format, lazy loading)

**7.3 SEO Testing**:
- Title tag present and unique (50-60 characters)
- Meta description present and compelling (150-160 characters)
- H1 tag present and unique (one per page)
- Canonical URL set correctly
- Open Graph tags for social sharing
- Structured data (Schema.org markup)
- Mobile-friendly (responsive design)
- SSL/HTTPS enabled

**7.4 Functional Testing**:
- Forms submit successfully
- Navigation menus work correctly
- Search functionality returns results
- Contact forms send emails
- Download links work
- Video/audio players load

**Tools Used**:
- Lighthouse for performance and SEO audits
- axe-core for accessibility testing
- Puppeteer for automated browser testing
- Google PageSpeed Insights API

**Output**: Per-page test results with scores and specific issues

---

### Step 8: Run Assertions (Custom Test Cases)

**Purpose**: Execute user-defined test assertions for regression testing and validation

**Assertion Types**:

**8.1 Content Assertions**:
```javascript
// Example assertions
assert.pageExists("/about")
assert.pageTitle("/about", contains: "About Us")
assert.elementExists("/about", selector: "h1")
assert.elementText("/about", selector: "h1", equals: "About Our Company")
assert.imageExists("/about", src: "/images/team-photo.jpg")
```

**8.2 Link Assertions**:
```javascript
assert.linkCount("/about", min: 5, max: 20)
assert.externalLinksHaveAttribute("/blog", attr: "rel=nofollow")
assert.noLinksTo("/deprecated-page")
assert.linkTargetExists("/resources", href: "/downloads/guide.pdf")
```

**8.3 Performance Assertions**:
```javascript
assert.pageLoadTime("/home", maxMs: 3000)
assert.pageSizeKB("/home", maxKB: 2000)
assert.lighthouseScore("/home", metric: "performance", min: 90)
assert.coreWebVitals("/home", LCP: {max: 2500}, CLS: {max: 0.1})
```

**8.4 Accessibility Assertions**:
```javascript
assert.wcagCompliance("/contact", level: "AA")
assert.colorContrast("/home", min: 4.5)
assert.allImagesHaveAlt("/blog/post-1")
assert.keyboardAccessible("/navigation")
```

**8.5 SEO Assertions**:
```javascript
assert.metaTag("/about", name: "description", minLength: 120)
assert.canonicalUrl("/about", equals: "https://example.com/about")
assert.structuredData("/products/item-1", type: "Product")
assert.openGraphTags("/blog/post-1", required: ["og:title", "og:image"])
```

**Custom Assertion Framework**:
Users can define custom assertions in YAML or JSON format:

```yaml
assertions:
  - name: "Homepage has hero section"
    page: "/"
    selector: ".hero-section"
    exists: true

  - name: "All blog posts have featured images"
    pages: "/blog/*"
    selector: ".featured-image"
    count: ">= 1"

  - name: "Contact form exists"
    page: "/contact"
    selector: "form#contact-form"
    exists: true
    attributes:
      method: "POST"
      action: "/api/contact"
```

**Output**: Assertion test results (pass/fail) with detailed error messages

---

### Step 9: Generate Comprehensive Report

**Purpose**: Produce detailed, actionable quality assurance report with all findings

**Report Structure**:

---

## Website Testing Report

**Site**: https://example.com
**Test Date**: 2025-12-21 14:30 UTC
**Test Duration**: 18 minutes
**Total Pages Tested**: 127

---

### Executive Summary

**Overall Site Health**: 🟡 Needs Improvement (72/100)

| Category | Score | Status |
|----------|-------|--------|
| Sitemap Validity | 85/100 | 🟢 Good |
| Link Health | 68/100 | 🟡 Needs Work |
| Resource Optimization | 55/100 | 🔴 Poor |
| Accessibility | 78/100 | 🟡 Needs Work |
| Performance | 82/100 | 🟢 Good |
| SEO | 90/100 | 🟢 Excellent |

**Critical Issues**: 5
**High Priority Issues**: 23
**Medium Priority Issues**: 67
**Low Priority Issues**: 134

---

### 1. Sitemap Validation Results

**Status**: ✅ XML Sitemap Found
**URL**: https://example.com/sitemap.xml
**Last Modified**: 2025-12-20
**Total URLs**: 125

**Issues Found**:
- ⚠️ 2 URLs in sitemap return HTTP 404 (removed content)
- ⚠️ 3 pages missing from sitemap but discoverable via crawl
- ✅ All URLs use HTTPS protocol
- ✅ Sitemap submitted to Google Search Console

**Recommendations**:
1. Remove broken URLs from sitemap
2. Add missing pages to sitemap
3. Set up automated sitemap regeneration

---

### 2. Page Inventory (127 Total Pages)

**Page Distribution**:
- Homepage: 1
- Standard Pages: 23
- Blog Posts: 87
- Archive Pages: 12
- Custom Post Types: 4

**Orphan Pages Detected**: 8 pages
| Page | Last Modified | Traffic (30d) | Recommendation |
|------|---------------|---------------|----------------|
| /old-services | 2023-05-12 | 0 visits | DELETE |
| /test-page | 2025-11-01 | 0 visits | DELETE |
| /thank-you | 2025-12-10 | 45 visits | KEEP (form submission page) |

---

### 3. Link Validation Results

**Total Links**: 1,245
- ✅ Valid Internal Links: 987 (79.3%)
- ✅ Valid External Links: 156 (12.5%)
- ❌ Broken Links (404): 23 (1.8%)
- ⚠️ Server Errors (5xx): 5 (0.4%)
- ⚠️ Redirect Chains: 42 (3.4%)

**Critical Broken Links** (User-Facing):
| Page | Broken Link | HTTP Status | Fix Priority |
|------|-------------|-------------|--------------|
| /home | /images/hero-banner.jpg | 404 | 🔴 CRITICAL |
| /about | /team/john-doe | 404 | 🟡 HIGH |
| /contact | /api/submit-form | 500 | 🔴 CRITICAL |

**External Link Issues**:
| Page | External URL | Issue | Recommendation |
|------|--------------|-------|----------------|
| /blog/post-12 | https://deadsite.com | DNS Error | Update or remove |
| /resources | http://insecure.com | Mixed Content | Update to HTTPS |

---

### 4. Unused Resource Analysis

**Total Wasted Bandwidth**: 3.2 MB (can be removed)

**Unused JavaScript**:
| File | Size | Usage | Recommendation |
|------|------|-------|----------------|
| /js/old-slider.js | 145 KB | 0% | DELETE |
| /js/analytics-backup.js | 23 KB | 0% | DELETE |
| /js/jquery-3.5.1.min.js | 89 KB | Duplicate | Use single jQuery version |

**Unused CSS**:
| File | Size | Usage | Recommendation |
|------|------|-------|----------------|
| /css/old-theme.css | 234 KB | 0% | DELETE |
| /css/unused-components.css | 67 KB | 12% | Audit and remove unused |

**Unused Images**:
| File | Size | Referenced By | Recommendation |
|------|------|---------------|----------------|
| /uploads/old-banner-1.jpg | 567 KB | None | DELETE |
| /uploads/unused-icon-set.png | 123 KB | None | DELETE |
| /uploads/duplicate-logo.png | 45 KB | Duplicate | Use original |

**Potential Savings**: 3.2 MB reduction in page weight

---

### 5. Accessibility Test Results

**Overall WCAG 2.1 AA Compliance**: 78/100

**Issues by Severity**:
- 🔴 Critical: 3 issues
- 🟡 Moderate: 12 issues
- 🟢 Minor: 23 issues

**Critical Accessibility Issues**:
| Page | Issue | WCAG Criterion | Fix |
|------|-------|----------------|-----|
| /home | Missing alt text on hero image | 1.1.1 | Add descriptive alt text |
| /contact | Form inputs missing labels | 3.3.2 | Add `<label>` tags |
| /navigation | Menu not keyboard accessible | 2.1.1 | Add keyboard navigation |

---

### 6. Performance Test Results

**Core Web Vitals Summary**:
| Metric | Average | Target | Status |
|--------|---------|--------|--------|
| LCP | 2.1s | <2.5s | ✅ GOOD |
| FID | 85ms | <100ms | ✅ GOOD |
| CLS | 0.15 | <0.1 | ❌ POOR |

**Pages with Performance Issues**:
| Page | LCP | CLS | Page Size | Recommendations |
|------|-----|-----|-----------|-----------------|
| /blog | 3.8s | 0.25 | 4.2 MB | Optimize images, lazy load |
| /products | 2.9s | 0.18 | 3.1 MB | Enable caching, minify JS |

---

### 7. SEO Test Results

**Overall SEO Score**: 90/100

**SEO Issues**:
| Page | Issue | Impact | Fix |
|------|-------|--------|-----|
| /services | Missing meta description | Medium | Add 150-160 char description |
| /blog/old-post | Duplicate H1 tags | Low | Use single H1 per page |
| /about | Title tag too long (78 chars) | Low | Shorten to 50-60 chars |

**Positive SEO Signals**:
- ✅ All pages have unique title tags
- ✅ XML sitemap submitted to search engines
- ✅ SSL/HTTPS enabled site-wide
- ✅ Mobile-friendly (responsive design)
- ✅ Structured data implemented (Schema.org)

---

### 8. Assertion Test Results

**Total Assertions**: 45
**Passed**: 38 (84.4%)
**Failed**: 7 (15.6%)

**Failed Assertions**:
| Assertion | Expected | Actual | Page | Fix |
|-----------|----------|--------|------|-----|
| Hero section exists | true | false | /home | Add hero section element |
| Page load time <3s | <3000ms | 3800ms | /blog | Optimize performance |
| All images have alt text | 100% | 87% | /gallery | Add missing alt text |

---

### Priority Action Items

#### 🔴 Critical (Fix Immediately)
1. Fix broken hero banner image on homepage (/images/hero-banner.jpg - 404)
2. Repair contact form submission endpoint (500 error)
3. Add missing alt text to hero image (accessibility violation)
4. Fix keyboard navigation in main menu

#### 🟡 High Priority (Fix This Week)
1. Remove 23 broken internal links
2. Delete 8 orphan pages (or link them to navigation)
3. Remove 3.2 MB of unused JavaScript, CSS, images
4. Fix Cumulative Layout Shift (CLS) issues on key pages
5. Add meta descriptions to 12 pages missing them

#### 🟢 Medium Priority (Fix This Month)
1. Update 42 redirect chains to final URLs
2. Fix 12 moderate accessibility issues
3. Optimize images on blog archive (reduce from 4.2 MB)
4. Clean up duplicate jQuery libraries
5. Add missing pages to XML sitemap

---

### Next Steps

1. **Immediate Fixes** (Today): Address 5 critical issues
2. **Quick Wins** (This Week): Remove unused resources (3.2 MB savings)
3. **Ongoing Improvement** (Monthly): Schedule regular site audits
4. **Monitoring**: Set up automated link checking and performance monitoring

**Estimated Time to Fix All Issues**: 8-12 hours

**Projected Impact**:
- Performance: +15 points on Lighthouse score
- SEO: Better crawlability and indexing
- User Experience: Faster page loads, better accessibility
- Bandwidth Savings: 3.2 MB reduction per page load

---

**Report Generated By**: Website Testing Skill v1.0
**Next Audit Recommended**: 2026-01-21 (30 days)

---

**Output Format**: HTML report, PDF export, JSON data for CI/CD integration

---

## Tools and Technologies

### Testing Tools
- **Lighthouse**: Performance, SEO, accessibility audits
- **axe-core**: WCAG accessibility validation
- **Puppeteer**: Headless browser automation for testing
- **Playwright**: Cross-browser testing (Chrome, Firefox, Safari)
- **Screaming Frog**: Website crawler for link validation
- **Sitebulb**: Comprehensive site auditing
- **GTmetrix**: Performance analysis
- **Google PageSpeed Insights**: Core Web Vitals measurement

### Link Validation Tools
- **Broken Link Checker**: Command-line link validator
- **W3C Link Checker**: Standards-compliant link validation
- **Custom crawler**: Breadth-first search crawler for page discovery

### Resource Analysis Tools
- **Webpack Bundle Analyzer**: JavaScript bundle analysis
- **PurgeCSS**: Unused CSS detection
- **Coverage API** (Chrome DevTools): JS/CSS usage measurement
- **ImageOptim**: Image optimization analysis

### Assertion Frameworks
- **Jest**: JavaScript testing framework for custom assertions
- **Cypress**: End-to-end testing with assertion support
- **Custom YAML parser**: User-defined assertion validation

### Reporting Tools
- **Markdown/HTML report generator**: Human-readable reports
- **JSON export**: Machine-readable data for CI/CD
- **PDF generator**: Executive summary reports
- **Dashboard**: Real-time test results visualization

---

## Integration with Development Workflows

### CI/CD Integration

**Pre-Deployment Testing**:
```yaml
# GitHub Actions example
name: Website Quality Check
on: [pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Run Website Tests
        run: npm run test:website
      - name: Generate Report
        run: npm run test:report
      - name: Fail if critical issues
        run: npm run test:assert-quality
```

**Automated Monitoring**:
- Schedule daily link validation tests
- Alert on new broken links or accessibility violations
- Track performance metrics over time
- Generate weekly quality reports

### WordPress Integration

**WP-CLI Commands**:
```bash
# Run full website test suite
wp website-test run --report=html

# Test specific aspects
wp website-test links
wp website-test accessibility
wp website-test performance
wp website-test unused-resources

# Generate reports
wp website-test report --format=pdf --email=admin@example.com
```

### Staging Environment Testing

**Pre-Production Validation**:
1. Run full test suite on staging environment
2. Compare staging vs production results
3. Identify regressions before deployment
4. Validate fixes in staging before promoting to production

---

## Success Criteria

**Website Testing Success** (per audit):
- ✅ All critical issues identified and documented
- ✅ Actionable recommendations provided for each issue
- ✅ Comprehensive report generated within 20 minutes
- ✅ No false positives (>95% accuracy)
- ✅ Automated tests run successfully without manual intervention
- ✅ Reports are clear and understandable for non-technical stakeholders
- ✅ CI/CD integration works seamlessly

**Quality Metrics**:
- Link validation accuracy: >99%
- Accessibility issue detection: >95% (compared to manual audit)
- Performance metrics accuracy: >98%
- Unused resource detection: >90%
- Report generation time: <20 minutes for 100-page site

---

## Behavioral Guidelines

### Patient Approach
- Break testing into clear phases (sitemap → pages → links → resources → testing → assertions → report)
- Provide progress updates during long-running tests
- Allow users to pause and resume testing
- Offer to test specific sections first (e.g., "just check links" vs "full audit")

### Courteous Communication
- Explain findings in plain language (not just HTTP status codes)
- Prioritize issues by impact (critical → high → medium → low)
- Provide specific, actionable recommendations
- Celebrate improvements: "Great! Your site has zero broken links now."

### Technically Sound
- Use industry-standard testing tools (Lighthouse, axe-core)
- Follow WCAG 2.1 guidelines for accessibility
- Measure against Core Web Vitals for performance
- Validate against sitemap protocol standards
- Provide evidence for all findings (screenshots, HTTP responses)

---

## Example Usage

### Example 1: Pre-Launch Quality Assurance

**Input**:
```json
{
  "site_url": "https://staging.example.com",
  "test_type": "comprehensive",
  "include": ["sitemap", "links", "accessibility", "performance", "seo"],
  "report_format": "html"
}
```

**Processing**:
1. ⏳ Validating sitemap...
2. ⏳ Crawling site (127 pages discovered)...
3. ⏳ Validating 1,245 links...
4. ⏳ Analyzing unused resources...
5. ⏳ Running accessibility tests (WCAG 2.1 AA)...
6. ⏳ Running performance tests (Lighthouse)...
7. ⏳ Running SEO tests...
8. ⏳ Executing 45 custom assertions...
9. ✅ Generating comprehensive report...

**Output**: Comprehensive quality assurance report (as shown in Step 9)

---

### Example 2: Quick Link Validation

**Input**:
```json
{
  "site_url": "https://example.com",
  "test_type": "links_only",
  "report_format": "json"
}
```

**Processing**:
1. Crawling site to discover pages
2. Extracting all links (internal and external)
3. Validating link targets
4. Generating link report

**Output**:
```json
{
  "summary": {
    "total_links": 1245,
    "valid": 1143,
    "broken": 23,
    "redirects": 42,
    "server_errors": 5
  },
  "broken_links": [
    {
      "page": "/about",
      "link": "/team/old-member",
      "status": 404,
      "recommendation": "Remove or update link"
    }
  ]
}
```

---

## Version History

- **v1.0** (2025-12-21): Initial Website Testing skill with 9-step comprehensive testing workflow, sitemap validation, link checking, resource optimization analysis, accessibility testing, performance validation, SEO auditing, assertion framework, and detailed reporting capabilities
