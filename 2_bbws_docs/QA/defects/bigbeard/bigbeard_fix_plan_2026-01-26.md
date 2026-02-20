# Big Beard Web Solutions - Fix Plan

**Site**: bigbeard.co.za
**S3 Bucket**: bigbeard-migrated-site-dev (DEV environment)
**Date**: 2026-01-26
**Status**: Plan Only - Awaiting Approval

---

## Executive Summary

This plan addresses the issues identified in the site analysis report. Fixes are organized by priority and effort level, with clear implementation steps for each.

### Infrastructure Context

| Component | Value |
|-----------|-------|
| S3 Bucket | bigbeard-migrated-site-dev |
| Site Folder | bigbeard/ |
| Objects | 1,072 files |
| Size | 250 MB |
| Website Config | index.html as default document |
| Public Access | Blocked (CloudFront OAC only) |
| CloudFront | Multiple distributions configured |

---

## Fix Categories

| Priority | Category | Issues | Effort |
|----------|----------|--------|--------|
| 1 | Critical SEO | robots.txt, sitemap.xml missing | Low |
| 2 | URL Structure | index.html in all links | Medium |
| 3 | Security | Missing headers | Low |
| 4 | Performance | Bloated HTML, heavy JS | High |
| 5 | Infrastructure | dev.bigbeard.co.za DNS | Low |

---

## Phase 1: Critical SEO Fixes (Immediate)

### 1.1 Create robots.txt

**Issue**: robots.txt returns 403 Access Denied
**Root Cause**: File does not exist in S3 bucket

**Fix**:
```bash
# Create robots.txt content
cat > /tmp/robots.txt << 'EOF'
User-agent: *
Allow: /

Sitemap: https://www.bigbeard.co.za/sitemap.xml
EOF

# Upload to S3
aws s3 cp /tmp/robots.txt s3://bigbeard-migrated-site-dev/bigbeard/robots.txt \
  --profile Tebogo-dev \
  --content-type "text/plain"
```

**Verification**:
```bash
curl -I https://www.bigbeard.co.za/robots.txt
# Expected: HTTP 200
```

---

### 1.2 Create sitemap.xml

**Issue**: sitemap.xml returns 403 Access Denied
**Root Cause**: File does not exist in S3 bucket

**Fix**:
```bash
# Create sitemap.xml with all pages
cat > /tmp/sitemap.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>https://www.bigbeard.co.za/</loc>
    <lastmod>2025-12-10</lastmod>
    <changefreq>weekly</changefreq>
    <priority>1.0</priority>
  </url>
  <url>
    <loc>https://www.bigbeard.co.za/about/</loc>
    <lastmod>2025-12-10</lastmod>
    <changefreq>monthly</changefreq>
    <priority>0.8</priority>
  </url>
  <url>
    <loc>https://www.bigbeard.co.za/services/</loc>
    <lastmod>2025-12-10</lastmod>
    <changefreq>monthly</changefreq>
    <priority>0.8</priority>
  </url>
  <url>
    <loc>https://www.bigbeard.co.za/services/web-design/</loc>
    <lastmod>2025-12-10</lastmod>
    <changefreq>monthly</changefreq>
    <priority>0.7</priority>
  </url>
  <url>
    <loc>https://www.bigbeard.co.za/services/web-development/</loc>
    <lastmod>2025-12-10</lastmod>
    <changefreq>monthly</changefreq>
    <priority>0.7</priority>
  </url>
  <url>
    <loc>https://www.bigbeard.co.za/services/web-support-maintenance/</loc>
    <lastmod>2025-12-10</lastmod>
    <changefreq>monthly</changefreq>
    <priority>0.7</priority>
  </url>
  <url>
    <loc>https://www.bigbeard.co.za/services/copywriting-seo/</loc>
    <lastmod>2025-12-10</lastmod>
    <changefreq>monthly</changefreq>
    <priority>0.7</priority>
  </url>
  <url>
    <loc>https://www.bigbeard.co.za/services/additional-services/</loc>
    <lastmod>2025-12-10</lastmod>
    <changefreq>monthly</changefreq>
    <priority>0.7</priority>
  </url>
  <url>
    <loc>https://www.bigbeard.co.za/services/graphic-design/</loc>
    <lastmod>2025-12-10</lastmod>
    <changefreq>monthly</changefreq>
    <priority>0.7</priority>
  </url>
  <url>
    <loc>https://www.bigbeard.co.za/projects/</loc>
    <lastmod>2025-12-10</lastmod>
    <changefreq>monthly</changefreq>
    <priority>0.8</priority>
  </url>
  <url>
    <loc>https://www.bigbeard.co.za/blog/</loc>
    <lastmod>2025-12-10</lastmod>
    <changefreq>weekly</changefreq>
    <priority>0.8</priority>
  </url>
  <url>
    <loc>https://www.bigbeard.co.za/contact/</loc>
    <lastmod>2025-12-10</lastmod>
    <changefreq>monthly</changefreq>
    <priority>0.8</priority>
  </url>
  <url>
    <loc>https://www.bigbeard.co.za/testimonials/</loc>
    <lastmod>2025-12-10</lastmod>
    <changefreq>monthly</changefreq>
    <priority>0.6</priority>
  </url>
  <url>
    <loc>https://www.bigbeard.co.za/privacy-policy/</loc>
    <lastmod>2025-12-10</lastmod>
    <changefreq>yearly</changefreq>
    <priority>0.3</priority>
  </url>
</urlset>
EOF

# Upload to S3
aws s3 cp /tmp/sitemap.xml s3://bigbeard-migrated-site-dev/bigbeard/sitemap.xml \
  --profile Tebogo-dev \
  --content-type "application/xml"
```

**Note**: A complete sitemap should also include:
- All blog posts (50+ pages)
- All project pages
- All category pages

**Generate Complete Sitemap Script**:
```bash
# List all index.html files and generate sitemap entries
aws s3 ls s3://bigbeard-migrated-site-dev/bigbeard/ --recursive --profile Tebogo-dev | \
  grep 'index.html$' | \
  awk '{print $4}' | \
  sed 's|bigbeard/||' | \
  sed 's|/index.html||' | \
  while read path; do
    echo "  <url>"
    echo "    <loc>https://www.bigbeard.co.za/${path}/</loc>"
    echo "    <changefreq>monthly</changefreq>"
    echo "  </url>"
  done
```

---

## Phase 2: URL Structure Fix (index.html Issue)

### 2.1 Problem Analysis

**Current State**:
- All internal links use explicit `index.html`: `href="about/index.html"`
- Both `/about/` and `/about/index.html` serve identical content (200 OK)
- Canonical tags correctly point to clean URLs (without index.html)

**Issues**:
1. User sees `index.html` in browser URL bar when clicking links
2. Potential duplicate content in search engines
3. Non-standard URL structure

### 2.2 Fix Options

#### Option A: Rewrite Links in HTML Files (Recommended)

**Approach**: Search and replace all `index.html` references in HTML files

**Script**:
```bash
#!/bin/bash
# fix_index_html_links.sh

BUCKET="bigbeard-migrated-site-dev"
PREFIX="bigbeard"
PROFILE="Tebogo-dev"
TEMP_DIR="/tmp/bigbeard_fix"

mkdir -p "$TEMP_DIR"

# Download all HTML files
aws s3 sync "s3://${BUCKET}/${PREFIX}/" "$TEMP_DIR/" \
  --profile "$PROFILE" \
  --exclude "*" \
  --include "*.html"

# Fix links in all HTML files
find "$TEMP_DIR" -name "*.html" -exec sed -i '' \
  -e 's|href="index\.html"|href="./"|g' \
  -e 's|href="\([^"]*\)/index\.html"|href="\1/"|g' \
  {} \;

# Upload fixed files back to S3
aws s3 sync "$TEMP_DIR/" "s3://${BUCKET}/${PREFIX}/" \
  --profile "$PROFILE" \
  --exclude "*" \
  --include "*.html"

# Cleanup
rm -rf "$TEMP_DIR"
```

**Specific Replacements**:
| Before | After |
|--------|-------|
| `href="index.html"` | `href="./"` |
| `href="about/index.html"` | `href="about/"` |
| `href="services/index.html"` | `href="services/"` |
| `href="services/web-design/index.html"` | `href="services/web-design/"` |
| `href="../index.html"` | `href="../"` |

#### Option B: CloudFront Function (URL Rewrite)

**Approach**: Use CloudFront Function to redirect `/*/index.html` to `/*/`

**CloudFront Function Code**:
```javascript
function handler(event) {
    var request = event.request;
    var uri = request.uri;

    // Redirect /path/index.html to /path/
    if (uri.endsWith('/index.html')) {
        var newUri = uri.slice(0, -10); // Remove 'index.html'
        if (newUri === '') newUri = '/';

        return {
            statusCode: 301,
            statusDescription: 'Moved Permanently',
            headers: {
                'location': { value: newUri }
            }
        };
    }

    return request;
}
```

**Pros/Cons**:
| Option | Pros | Cons |
|--------|------|------|
| A (HTML Rewrite) | Permanent fix, no redirects, better UX | Requires processing all HTML files |
| B (CloudFront) | Quick to implement, no file changes | Adds redirect latency, doesn't fix source |

**Recommendation**: Option A (HTML Rewrite) for permanent fix

---

## Phase 3: Security Headers (CloudFront)

### 3.1 Create Response Headers Policy

**Issue**: No security headers returned by CloudFront

**Fix**: Create CloudFront Response Headers Policy

```bash
# Create response headers policy
aws cloudfront create-response-headers-policy \
  --profile Tebogo-dev \
  --response-headers-policy-config '{
    "Name": "bigbeard-security-headers",
    "Comment": "Security headers for bigbeard.co.za",
    "SecurityHeadersConfig": {
      "XSSProtection": {
        "Override": true,
        "Protection": true,
        "ModeBlock": true
      },
      "FrameOptions": {
        "Override": true,
        "FrameOption": "DENY"
      },
      "ContentTypeOptions": {
        "Override": true
      },
      "StrictTransportSecurity": {
        "Override": true,
        "IncludeSubdomains": true,
        "Preload": true,
        "AccessControlMaxAgeSec": 31536000
      },
      "ReferrerPolicy": {
        "Override": true,
        "ReferrerPolicy": "strict-origin-when-cross-origin"
      },
      "ContentSecurityPolicy": {
        "Override": true,
        "ContentSecurityPolicy": "default-src '\''self'\''; script-src '\''self'\'' '\''unsafe-inline'\'' '\''unsafe-eval'\'' https://www.googletagmanager.com https://www.google-analytics.com https://connect.facebook.net https://www.clarity.ms https://static.hotjar.com; style-src '\''self'\'' '\''unsafe-inline'\'' https://fonts.googleapis.com; font-src '\''self'\'' https://fonts.gstatic.com; img-src '\''self'\'' data: https:; frame-src https://www.youtube.com https://player.vimeo.com;"
      }
    },
    "CustomHeadersConfig": {
      "Quantity": 1,
      "Items": [
        {
          "Header": "Permissions-Policy",
          "Value": "geolocation=(), microphone=(), camera=()",
          "Override": true
        }
      ]
    }
  }'
```

### 3.2 Attach Policy to Distribution

```bash
# Get current distribution config
DIST_ID="<distribution-id>"
aws cloudfront get-distribution-config --id $DIST_ID --profile Tebogo-dev > /tmp/dist-config.json

# Update with response headers policy ID
# Then update distribution
aws cloudfront update-distribution --id $DIST_ID --profile Tebogo-dev \
  --distribution-config file:///tmp/updated-config.json \
  --if-match <etag>
```

---

## Phase 4: Performance Optimization (High Effort)

### 4.1 Quick Wins

#### 4.1.1 Remove Duplicate Tracking Scripts

**Issue**: Google Analytics loaded twice, Facebook Pixel loaded twice

**Current**:
```html
<!-- GA loaded twice with different IDs -->
<script async src="https://www.googletagmanager.com/gtag/js?id=G-1Z64YK4X9D">
<script async src="https://www.googletagmanager.com/gtag/js?id=G-1BGQ9Z2Y0K">

<!-- Facebook Pixel loaded twice -->
<img src="https://www.facebook.com/tr?id=357572399941553...">
<img src="https://www.facebook.com/tr?id=1318746479850751...">
```

**Fix**: Remove duplicate tracking in all HTML files
```bash
# Remove duplicate GA tag (keep primary)
sed -i '' 's|<script async src="https://www.googletagmanager.com/gtag/js?id=G-1BGQ9Z2Y0K">.*</script>||g' *.html

# Consolidate to single GTM container
```

#### 4.1.2 Add Cache-Control Headers

**Fix**: Configure S3 object metadata for better caching

```bash
# Set cache headers for static assets
aws s3 cp s3://bigbeard-migrated-site-dev/bigbeard/wp-content/ \
  s3://bigbeard-migrated-site-dev/bigbeard/wp-content/ \
  --recursive \
  --metadata-directive REPLACE \
  --cache-control "public, max-age=31536000" \
  --profile Tebogo-dev \
  --exclude "*.html"

# Set shorter cache for HTML
aws s3 cp s3://bigbeard-migrated-site-dev/bigbeard/ \
  s3://bigbeard-migrated-site-dev/bigbeard/ \
  --recursive \
  --metadata-directive REPLACE \
  --cache-control "public, max-age=3600" \
  --profile Tebogo-dev \
  --exclude "*" \
  --include "*.html"
```

### 4.2 Medium Effort Optimizations

#### 4.2.1 HTML Minification

**Tool**: html-minifier-terser

```bash
npm install -g html-minifier-terser

# Minify all HTML files
find /tmp/bigbeard -name "*.html" -exec html-minifier-terser \
  --collapse-whitespace \
  --remove-comments \
  --remove-redundant-attributes \
  --minify-css true \
  --minify-js true \
  -o {} {} \;
```

**Expected Savings**: 20-30% reduction in HTML size

#### 4.2.2 Remove Unused WordPress Artifacts

**Files to Remove**:
```bash
# Remove WordPress JSON API references from HTML
# These return 403 anyway
sed -i '' 's|<link.*wp-json.*>||g' *.html

# Remove RSS feed links (not functional on static site)
sed -i '' 's|<link.*application/rss+xml.*>||g' *.html

# Remove WordPress emoji script (large, unnecessary)
# This requires careful editing of the inline script block
```

### 4.3 High Effort Optimizations (Future Consideration)

#### 4.3.1 Full Static Site Rebuild

**Recommendation**: Rebuild site using modern static site generator

**Options**:
| Framework | Pros | Effort |
|-----------|------|--------|
| Next.js | React-based, great performance, SSG | High |
| Astro | Content-focused, minimal JS | Medium |
| 11ty | Simple, fast builds | Medium |
| Hugo | Fastest builds, Go-based | Medium |

**Benefits**:
- 90% smaller HTML output
- No jQuery/Elementor dependencies
- Better Core Web Vitals
- Modern development workflow

#### 4.3.2 Image Optimization

**Current**: Mixed PNG/JPG/WebP
**Target**: All images in WebP with fallbacks

```bash
# Convert images to WebP (requires cwebp)
find /tmp/bigbeard/wp-content/uploads -name "*.png" -exec sh -c '
  cwebp -q 80 "$1" -o "${1%.png}.webp"
' _ {} \;
```

---

## Phase 5: Infrastructure Fixes

### 5.1 Configure dev.bigbeard.co.za DNS

**Issue**: dev.bigbeard.co.za returns NXDOMAIN

**Fix Options**:

#### Option A: Route 53 (if DNS is in Route 53)
```bash
# Create CNAME record pointing to CloudFront
aws route53 change-resource-record-sets \
  --hosted-zone-id <zone-id> \
  --change-batch '{
    "Changes": [{
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "dev.bigbeard.co.za",
        "Type": "CNAME",
        "TTL": 300,
        "ResourceRecords": [{"Value": "<cloudfront-distribution>.cloudfront.net"}]
      }
    }]
  }'
```

#### Option B: External DNS Provider
- Log into DNS provider (xneelo, Cloudflare, etc.)
- Create CNAME record: `dev` → CloudFront distribution domain

**Prerequisites**:
1. Create CloudFront distribution for dev environment
2. Configure S3 bucket as origin with `/bigbeard/` prefix
3. Add `dev.bigbeard.co.za` as alternate domain name (CNAME)
4. Request ACM certificate for dev.bigbeard.co.za

---

## Implementation Schedule

### Week 1: Critical Fixes (Phase 1)
| Day | Task | Owner | Status |
|-----|------|-------|--------|
| 1 | Create and upload robots.txt | - | ⏳ |
| 1 | Create and upload sitemap.xml | - | ⏳ |
| 1 | Invalidate CloudFront cache | - | ⏳ |
| 2 | Verify robots.txt accessible | - | ⏳ |
| 2 | Submit sitemap to Google Search Console | - | ⏳ |

### Week 2: URL Structure Fix (Phase 2)
| Day | Task | Owner | Status |
|-----|------|-------|--------|
| 1 | Download all HTML files | - | ⏳ |
| 1 | Run sed replacement script | - | ⏳ |
| 2 | Test locally | - | ⏳ |
| 2 | Upload fixed files to S3 | - | ⏳ |
| 3 | Invalidate CloudFront cache | - | ⏳ |
| 3 | Verify all links work | - | ⏳ |

### Week 3: Security Headers (Phase 3)
| Day | Task | Owner | Status |
|-----|------|-------|--------|
| 1 | Create CloudFront response headers policy | - | ⏳ |
| 1 | Test policy on dev distribution | - | ⏳ |
| 2 | Apply to production distribution | - | ⏳ |
| 2 | Verify headers with curl | - | ⏳ |

### Week 4: Performance Quick Wins (Phase 4.1)
| Day | Task | Owner | Status |
|-----|------|-------|--------|
| 1 | Remove duplicate tracking scripts | - | ⏳ |
| 2 | Set cache-control headers on S3 objects | - | ⏳ |
| 3 | Minify HTML files | - | ⏳ |
| 4 | Run Lighthouse audit | - | ⏳ |

### Future: Full Rebuild (Phase 4.3)
| Task | Effort | Priority |
|------|--------|----------|
| Evaluate static site generators | 1 week | Medium |
| Design new site architecture | 2 weeks | Medium |
| Rebuild site | 4-6 weeks | Low |
| Testing and QA | 1 week | - |
| Migration and cutover | 1 week | - |

---

## Verification Checklist

### After Phase 1
- [ ] `curl -I https://www.bigbeard.co.za/robots.txt` returns 200
- [ ] `curl -I https://www.bigbeard.co.za/sitemap.xml` returns 200
- [ ] Sitemap submitted to Google Search Console
- [ ] Sitemap contains all pages

### After Phase 2
- [ ] Clicking any navigation link does NOT show `index.html` in URL
- [ ] All internal links work correctly
- [ ] No 404 errors on site
- [ ] Canonical tags still correct

### After Phase 3
- [ ] `curl -I https://www.bigbeard.co.za` shows security headers
- [ ] X-Frame-Options: DENY
- [ ] X-Content-Type-Options: nosniff
- [ ] Strict-Transport-Security present

### After Phase 4
- [ ] Lighthouse Performance score improved
- [ ] HTML file sizes reduced
- [ ] TTFB < 500ms

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Broken links after URL fix | Medium | High | Thorough testing, backup before changes |
| SEO ranking drop | Low | Medium | Keep canonical tags, submit sitemap |
| CloudFront cache issues | Medium | Low | Full invalidation after changes |
| Browser compatibility | Low | Low | Test on major browsers |

---

## Rollback Plan

### If URL Fix Causes Issues
```bash
# Restore from backup
aws s3 sync s3://bigbeard-migrated-site-dev/bigbeard-backup/ \
  s3://bigbeard-migrated-site-dev/bigbeard/ \
  --profile Tebogo-dev

# Invalidate CloudFront
aws cloudfront create-invalidation \
  --distribution-id <dist-id> \
  --paths "/*" \
  --profile Tebogo-dev
```

### Before Any Changes
```bash
# Create backup
aws s3 sync s3://bigbeard-migrated-site-dev/bigbeard/ \
  s3://bigbeard-migrated-site-dev/bigbeard-backup-$(date +%Y%m%d)/ \
  --profile Tebogo-dev
```

---

## Appendix: File Counts

| Folder | Files | Size |
|--------|-------|------|
| bigbeard/ (root) | 6 | ~1 MB |
| about/ | 1 | 288 KB |
| services/ | 7 | ~1.5 MB |
| blog/ | 1 | 146 KB |
| projects/ | 1 | 465 KB |
| wp-content/uploads/ | 737 | 203 MB |
| wp-content/plugins/ | ~200 | ~30 MB |
| wp-includes/ | ~100 | ~15 MB |
| **Total** | **1,072** | **250 MB** |

---

**Plan Created**: 2026-01-26
**Environment**: DEV (bigbeard-migrated-site-dev)
**Status**: Awaiting Approval

---

## Next Steps

1. Review this plan
2. Approve phases to implement
3. Schedule implementation windows
4. Execute Phase 1 (Critical SEO) first
5. Proceed with subsequent phases based on priority
