# SDET Test Report: BigBeard PROD Promotion (Phase 1+2 Performance Optimizations)

**Date:** 2026-01-27
**Environment:** PROD (www.bigbeard.co.za / d31125p5eewv1p.cloudfront.net)
**Tester:** SDET Agent (Automated)
**Promoted From:** SIT (djdsm227568gu.cloudfront.net)

---

## Test Summary

| Metric | Value |
|--------|-------|
| Total Test Cases | 11 |
| Passed | 11 |
| Failed | 0 |
| Defects Found | 0 |
| Pass Rate | **100%** |

---

## Rollback Strategy

| Item | Detail |
|------|--------|
| Backup Bucket | `bigbeard-migrated-site-prod-backup-20260127` (af-south-1) |
| Backup Files | 1,071 objects (pre-optimization PROD state) |
| Public Access | Blocked (all 4 settings) |
| Rollback Command | `aws s3 sync s3://bigbeard-migrated-site-prod-backup-20260127/bigbeard/ s3://bigbeard-migrated-site-prod-af-south-1/bigbeard/ --profile Tebogo-prod --region af-south-1 --delete` |
| Post-Rollback | Invalidate CloudFront: `aws cloudfront create-invalidation --distribution-id E1GZPJMKLN1ATO --paths "/*" --profile Tebogo-prod --region us-east-1` |

---

## Scope

Verification that all Phase 1+2 performance optimizations were correctly promoted from SIT to PROD:
- Preconnect resource hints (5 domains)
- Google Analytics script deferred (async -> defer)
- WordPress emoji script and CSS removed
- Lazy loading on below-fold images
- Facebook Pixel deferred and duplicate removed
- LinkedIn tracking deferred
- CloudFront Function for directory URL handling

---

## Test Cases and Results

### Category: Page Availability (www.bigbeard.co.za)

| ID | Test Case | Expected | Actual | Status |
|----|-----------|----------|--------|--------|
| TC-01 | Homepage returns 200 | HTTP 200 | HTTP 200 | PASS |
| TC-02 | About page returns 200 | HTTP 200 | HTTP 200 | PASS |
| TC-03 | Contact page returns 200 | HTTP 200 | HTTP 200 | PASS |
| TC-04 | Blog page returns 200 | HTTP 200 | HTTP 200 | PASS |
| TC-05 | Services page returns 200 | HTTP 200 | HTTP 200 | PASS |

### Category: Phase 1 - Preconnect & Script Optimization

| ID | Test Case | Expected | Actual | Status |
|----|-----------|----------|--------|--------|
| TC-06 | Preconnect hints present in `<head>` | 5 preconnect links | 5 found | PASS |
| TC-07 | GA script uses `defer` (not `async`) | defer=1 | defer=1 | PASS |
| TC-08 | WordPress emoji script removed | 0 references | 0 found | PASS |

### Category: Phase 2 - Tracking & Image Optimization

| ID | Test Case | Expected | Actual | Status |
|----|-----------|----------|--------|--------|
| TC-09 | Primary FB Pixel present (357572399941553) | >= 1 ref | 1 found | PASS |
| TC-10 | Duplicate FB Pixel removed (1318746479850751) | 0 references | 0 found | PASS |
| TC-11 | Lazy loading on below-fold images | >= 15 images | 17 lazy loaded | PASS |

---

## Infrastructure Verification

| Check | Expected | Actual | Status |
|-------|----------|--------|--------|
| PROD Distribution | E1GZPJMKLN1ATO | E1GZPJMKLN1ATO | OK |
| CloudFront Function | url-rewrite-prod (LIVE) | Attached to viewer-request | OK |
| Function Logic | Appends index.html to directory URIs | Confirmed | OK |
| S3 Bucket | bigbeard-migrated-site-prod-af-south-1 | 1,074 files synced | OK |
| Cache Invalidation | ITPBW2GLKKY6FC7AGIIXMITQJ | InProgress -> Complete | OK |

---

## Promotion Details

| Item | Value |
|------|-------|
| Source Environment | SIT |
| Source Bucket | bigbeard-site-sit-eu-west-1 (eu-west-1) |
| Source CloudFront | E36WVZTSUS7H75 (djdsm227568gu.cloudfront.net) |
| Target Environment | PROD |
| Target Bucket | bigbeard-migrated-site-prod-af-south-1 (af-south-1) |
| Target CloudFront | E1GZPJMKLN1ATO (d31125p5eewv1p.cloudfront.net / www.bigbeard.co.za) |
| Method | Local upload from SIT-verified files (cross-account) |
| Cache Invalidation | ITPBW2GLKKY6FC7AGIIXMITQJ |

---

## Environment Parity

| Optimization | DEV | SIT | PROD |
|-------------|-----|-----|------|
| Preconnect hints (5) | Yes | Yes | Yes |
| GA deferred | Yes | Yes | Yes |
| Emoji removed | Yes | Yes | Yes |
| FB Pixel deferred | Yes | Yes | Yes |
| Duplicate FB removed | Yes | Yes | Yes |
| LinkedIn deferred | Yes | Yes | Yes |
| Lazy loading (17/18) | Yes | Yes | Yes |
| CloudFront index rewrite | bigbeard-index-rewrite | bigbeard-index-rewrite | url-rewrite-prod |

---

## Sign-off

| Role | Name | Date | Status |
|------|------|------|--------|
| SDET | Claude (Automated) | 2026-01-27 | **All Tests Passed** |
| QA Lead | Pending | - | - |
| DevOps | Pending | - | - |
