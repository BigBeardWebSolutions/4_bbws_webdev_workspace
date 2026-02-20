# BigBeard Performance Optimization Plan

**Date:** 2026-01-26
**Environment:** DEV (d3puvv0zkbx1pd.cloudfront.net)
**Current State:** Homepage ~380KB, slow TTFB, render-blocking resources

---

## Backup Information

| Item | Details |
|------|---------|
| **Backup Bucket** | `s3://bigbeard-migrated-site-dev-backup-20260126` |
| **Region** | eu-west-1 |
| **Size** | 238.4 MB |
| **Profile** | Tebogo-dev |

### Rollback Command
```bash
aws s3 sync s3://bigbeard-migrated-site-dev-backup-20260126/bigbeard/ \
  s3://bigbeard-migrated-site-dev/bigbeard/ \
  --profile Tebogo-dev --delete

aws cloudfront create-invalidation \
  --distribution-id EGBAPLVHPBIF8 \
  --paths "/*" \
  --profile Tebogo-dev
```

---

## Current Performance Issues

### 1. Page Size Analysis
| Metric | Current | Target |
|--------|---------|--------|
| Homepage HTML | ~380 KB | < 100 KB |
| Total Page Weight | ~2.5 MB | < 1 MB |
| Requests | 50+ | < 30 |

### 2. Identified Issues

#### A. Tracking Scripts (Render-Blocking)
- Google Analytics (G-1Z64YK4X9D) - loads synchronously
- Facebook Pixel (357572399941553) - loads in head
- LinkedIn Insight Tag (8750705) - loads in head
- Google Tag Manager - additional overhead

#### B. External Resources
- Google Fonts (multiple weights)
- WordPress emoji script
- Multiple CSS files loaded synchronously
- jQuery loaded before DOM ready

#### C. Missing Optimizations
- No resource preconnect hints
- No lazy loading for images
- No deferred script loading
- No critical CSS inlining
- Images not optimized (WebP)

---

## Optimization Plan

### Phase 1: Quick Wins (Low Risk)

#### 1.1 Add Resource Hints
Add preconnect for external domains to reduce DNS/connection time.

**Changes to `<head>`:**
```html
<!-- Preconnect to external domains -->
<link rel="preconnect" href="https://www.googletagmanager.com" crossorigin>
<link rel="preconnect" href="https://www.google-analytics.com" crossorigin>
<link rel="preconnect" href="https://connect.facebook.net" crossorigin>
<link rel="preconnect" href="https://fonts.googleapis.com" crossorigin>
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
```

**Risk:** Low
**Impact:** Reduces connection time by 100-300ms per domain

#### 1.2 Defer Non-Critical JavaScript
Move tracking scripts to load after page content.

**Before:**
```html
<script async src="https://www.googletagmanager.com/gtag/js?id=G-1Z64YK4X9D"></script>
```

**After:**
```html
<script defer src="https://www.googletagmanager.com/gtag/js?id=G-1Z64YK4X9D"></script>
```

**Risk:** Low
**Impact:** Faster First Contentful Paint (FCP)

#### 1.3 Remove WordPress Emoji Script
WordPress loads emoji scripts by default which aren't needed.

**Remove these lines:**
```html
<script>window._wpemojiSettings = {...}</script>
<script src="/wp-includes/js/wp-emoji-release.min.js"></script>
```

**Risk:** Low (emojis will use system fonts)
**Impact:** Reduces ~15KB + 1 request

---

### Phase 2: Medium Impact (Medium Risk)

#### 2.1 Lazy Load Images
Add `loading="lazy"` to below-the-fold images.

**Before:**
```html
<img src="image.jpg" alt="...">
```

**After:**
```html
<img src="image.jpg" alt="..." loading="lazy">
```

**Risk:** Medium (older browsers don't support)
**Impact:** Reduces initial page load by 500KB-1MB

#### 2.2 Defer Facebook & LinkedIn Tracking
Load these scripts after page load.

**Implementation:**
```html
<script>
window.addEventListener('load', function() {
  // Facebook Pixel
  !function(f,b,e,v,n,t,s){...}(window, document,'script',
  'https://connect.facebook.net/en_US/fbevents.js');
  fbq('init', '357572399941553');
  fbq('track', 'PageView');

  // LinkedIn
  _linkedin_partner_id = "8750705";
  // ... rest of LinkedIn code
});
</script>
```

**Risk:** Medium (may affect tracking accuracy slightly)
**Impact:** Removes render-blocking scripts

#### 2.3 Optimize Font Loading
Use `font-display: swap` to prevent invisible text.

**Add to CSS:**
```css
@font-face {
  font-family: 'Roboto';
  font-display: swap;
  /* ... */
}
```

**Risk:** Low
**Impact:** Text visible immediately, swaps when font loads

---

### Phase 3: High Impact (Higher Risk)

#### 3.1 Inline Critical CSS
Extract above-the-fold CSS and inline it.

**Risk:** High (requires careful extraction)
**Impact:** Eliminates render-blocking CSS

#### 3.2 Safe HTML Minification
Minify HTML without breaking scripts (whitespace in tags only).

**Safe approach:**
- Remove HTML comments (except conditional)
- Remove whitespace between tags
- DO NOT remove whitespace inside `<script>`, `<pre>`, `<textarea>`
- DO NOT collapse spaces in text content

**Risk:** Medium (previous attempt broke site)
**Impact:** 20-30% HTML size reduction

#### 3.3 Image Optimization
Convert images to WebP format with fallbacks.

**Risk:** Medium (requires browser support check)
**Impact:** 30-50% image size reduction

---

## Implementation Order

| Order | Task | Risk | Impact | Est. Savings |
|-------|------|------|--------|--------------|
| 1 | Add preconnect hints | Low | Medium | 200-400ms |
| 2 | Defer GA script | Low | Medium | 100ms |
| 3 | Remove emoji script | Low | Low | 15KB |
| 4 | Lazy load images | Medium | High | 500KB-1MB |
| 5 | Defer FB/LinkedIn | Medium | Medium | 200ms |
| 6 | Font display swap | Low | Medium | 100ms |
| 7 | Safe HTML minification | Medium | Medium | 50-80KB |
| 8 | Image WebP conversion | Medium | High | 30-50% images |

---

## Testing Checklist

After each change:
- [ ] Visual inspection - site looks correct
- [ ] Console errors - no JavaScript errors
- [ ] Tracking verification - GA/FB events firing
- [ ] Mobile responsive - layout not broken
- [ ] Lighthouse score - performance improved

---

## Success Metrics

| Metric | Current | Target |
|--------|---------|--------|
| Lighthouse Performance | ~50 | > 80 |
| First Contentful Paint | ~3s | < 1.5s |
| Largest Contentful Paint | ~5s | < 2.5s |
| Total Blocking Time | ~500ms | < 200ms |
| Page Size | ~2.5MB | < 1MB |

---

## Rollback Triggers

Immediately rollback if:
- Site returns 4xx/5xx errors
- JavaScript console shows critical errors
- Visual layout is broken
- Tracking completely stops working

---

## Schedule

| Phase | Tasks | Status |
|-------|-------|--------|
| Phase 1 | Quick Wins (1.1-1.3) | Pending |
| Phase 2 | Medium Impact (2.1-2.3) | Pending |
| Phase 3 | High Impact (3.1-3.3) | Pending |

---

## Sign-off

| Role | Name | Date | Approval |
|------|------|------|----------|
| DevOps | Claude | 2026-01-26 | Plan Created |
| QA | Pending | - | - |
| Product Owner | Pending | - | - |
