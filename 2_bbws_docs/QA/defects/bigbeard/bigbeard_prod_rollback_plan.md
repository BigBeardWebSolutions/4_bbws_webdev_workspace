# BigBeard PROD Rollback Plan

**Date:** 2026-01-26
**Change:** Promote index.html URL fix from SIT to PROD

## Backup Location

- **Bucket:** `s3://bigbeard-migrated-site-prod-backup-20260126/bigbeard/`
- **Region:** af-south-1
- **Size:** 238.5 MB
- **Profile:** Tebogo-prod

## Rollback Steps

If issues are detected after promotion, execute these commands:

### 1. Restore files from backup

```bash
aws s3 sync s3://bigbeard-migrated-site-prod-backup-20260126/bigbeard/ \
  s3://bigbeard-migrated-site-prod-af-south-1/bigbeard/ \
  --profile Tebogo-prod --delete
```

### 2. Invalidate CloudFront cache

```bash
aws cloudfront create-invalidation \
  --distribution-id E1GZPJMKLN1ATO \
  --paths "/*" \
  --profile Tebogo-prod
```

### 3. Verify rollback

```bash
curl -s https://www.bigbeard.co.za/ | head -20
curl -s -o /dev/null -w "%{http_code}" https://www.bigbeard.co.za/about/
```

## Cleanup (after successful promotion - 7 days)

Delete backup bucket after confirming stability:

```bash
aws s3 rb s3://bigbeard-migrated-site-prod-backup-20260126 --force --profile Tebogo-prod
```

## Change Details

- **What:** Remove `/index.html` from internal href links
- **Files affected:** 146 HTML files
- **Expected result:** URLs like `/about/` instead of `/about/index.html`
