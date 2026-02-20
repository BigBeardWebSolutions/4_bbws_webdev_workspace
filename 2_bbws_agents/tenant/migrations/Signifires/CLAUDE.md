# Signifires - WordPress Migration Project

## Project Overview

Migration of Signifires WordPress website from Xneelo hosting to BBWS multi-tenant AWS hosting platform.

## Site Profile

| Property | Value |
|----------|-------|
| **Site Name** | Signifires |
| **Production Domain** | https://signifires.com/staging |
| **New Domain** | signifires.com |
| **Table Prefix** | wp_ |
| **Transfer Method** | S3 staging (1.5GB total) |

## Directory Structure

```
Signifires/
├── CLAUDE.md              # This file
├── .claude/               # TBT tracking
│   ├── logs/
│   ├── plans/
│   └── snapshots/
├── site/
│   └── wp-content/        # WordPress content (1.4GB)
│       ├── plugins/
│       ├── themes/
│       ├── uploads/
│       └── mu-plugins/    # Includes force-https-cloudfront.php
└── database/
    ├── signifires.sql        # Original database (3.5MB)
    └── signifires-fixed.sql  # Prepared for migration
```

## Source Files

- **Original WordPress files**: `/Users/sithembisomjoko/Documents/Friday-Migration-30012026/signifires/web_backup_1753350718677/usr/www/users/signicnkkc/backup-2022-03-15/`
- **Original Database**: `dedi111_cpt3_host-h_net (5).sql`

## Special Considerations

### Plugins Detected
- **iThemes Security** - Deactivated in signifires-fixed.sql (SSL redirects)
- **Gravity Forms** - Active, forms need testing
- **W3 Total Cache** - Cache clearing required post-migration
- **EWWW Image Optimizer** - Image optimization plugin
- **Wordfence** (wflogs present) - Security plugin, may need config

### URL Changes Required
The original site uses `/staging` in the path:
- **Original**: `https://signifires.com/staging`
- **Target DEV**: `https://signifires.wpdev.kimmyai.io`
- **Target SIT**: `https://signifires.wpsit.kimmyai.io`

### CloudFront/HTTPS Configuration
- MU-plugin `force-https-cloudfront.php` has been added to handle HTTPS detection behind CloudFront/ALB

## Migration Checklist

### Phase 1: S3 Upload
- [ ] Create tar.gz of wp-content
- [ ] Upload to `s3://wordpress-migration-temp-20250903/signifires/`
- [ ] Upload signifires-fixed.sql to S3

### Phase 2: Infrastructure
- [ ] Create Terraform tenant configuration
- [ ] Run terraform plan
- [ ] Run terraform apply
- [ ] Verify resources created

### Phase 3: File Import
- [ ] Connect to bastion via SSM
- [ ] Download from S3 to bastion
- [ ] Extract to EFS mount
- [ ] Set permissions (www-data:www-data)

### Phase 4: Database Import
- [ ] Import signifires-fixed.sql to RDS
- [ ] Update siteurl to DEV domain
- [ ] Update home to DEV domain
- [ ] Clear W3TC cache tables

### Phase 5: Validation
- [ ] Site loads without redirect loop
- [ ] Admin login works
- [ ] Media/images display correctly
- [ ] Gravity Forms submissions work
- [ ] Test email redirects to tebogo@bigbeard.co.za

## SQL Commands Reference

```sql
-- Update URLs for DEV environment
UPDATE wp_options SET option_value = 'https://signifires.wpdev.kimmyai.io'
WHERE option_name IN ('siteurl', 'home');

-- Clear W3TC cache (if present)
TRUNCATE TABLE wp_w3tc_cdn_queue;

-- Verify settings
SELECT option_name, option_value FROM wp_options
WHERE option_name IN ('siteurl', 'home', 'blogname');
```

## AWS Resources

| Resource | Value |
|----------|-------|
| **S3 Bucket** | wordpress-migration-temp-20250903 |
| **S3 Path** | signifires/ |
| **AWS Profile DEV** | dev |
| **AWS Profile SIT** | sit |
| **Test Email** | tebogo@bigbeard.co.za |

## Target URLs

| Environment | URL |
|-------------|-----|
| DEV | https://signifires.wpdev.kimmyai.io |
| SIT | https://signifires.wpsit.kimmyai.io |
| PROD | https://signifires.com (after cutover) |

---

## Root Workflow Inheritance

This project inherits TBT mechanism and all workflow standards from the parent CLAUDE.md:

{{include:../CLAUDE.md}}
