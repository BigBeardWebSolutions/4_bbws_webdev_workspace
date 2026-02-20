# Leadflow360 WordPress Migration

**Status:** Ready for Migration
**Created:** 2026-02-04
**Last Updated:** 2026-02-04

## Site Profile

| Property | Value |
|----------|-------|
| **Production Domain** | `http://leadflow360.co.za` |
| **DEV Target** | `leadflow360.wpdev.kimmyai.io` |
| **SIT Target** | `leadflow360.wpsit.kimmyai.io` |
| **Database File** | `leadflow360-fixed.sql` (53MB - prepared) |
| **wp-content Size** | 251MB |
| **Total Size** | ~304MB |
| **Table Prefix** | `wp_` |
| **Theme** | Hello Elementor (with child theme) |
| **Transfer Method** | **Direct bastion** (< 500MB) |

## Directory Structure

```
Leadflow360/
├── CLAUDE.md              # This file
├── .claude/               # TBT tracking
│   ├── logs/
│   ├── plans/
│   └── snapshots/
├── database/
│   ├── dedi111_cpt3_host-h_net.sql  # Original (DO NOT USE)
│   └── leadflow360-fixed.sql         # PREPARED - Use this!
└── site/
    └── wp-content/        # 251MB - ready for transfer
```

## Migration Preparation Completed

### Database Fix Applied
- **Script Used:** `0_utilities/file_transfer/prepare-wordpress-for-migration.sh`
- **Plugins Deactivated:**
  - `really-simple-ssl` - #1 cause of redirect loops
  - `wordfence` - Firewall blocks CloudFront IPs

### Installed Plugins (Active Post-Migration)
| Plugin | Notes |
|--------|-------|
| elementor | Page builder |
| elementor-pro | Pro features |
| gravityforms | Form handling |
| gravityformssurvey | Survey extension |
| gravity-form-with-google-spreadsheet | Sheets integration |
| complianz-gdpr | Cookie consent |
| duplicate-post | Content duplication |
| revslider | Slider Revolution |
| wordpress-seo | Yoast SEO |
| redirection | URL redirects (monitor for issues) |

### Themes
- **Active:** hello-elementor (hello-theme-child-master)
- **Installed:** twentytwentyfive, twentytwentyfour

## Migration Phase Checklist

### Phase 1: Pre-Migration [COMPLETED]
- [x] Source files discovered
- [x] Database analyzed (table prefix: wp_)
- [x] Original domain identified: leadflow360.co.za
- [x] Problematic plugins identified and deactivated
- [x] Database prepared: leadflow360-fixed.sql
- [x] wp-content copied to site/

### Phase 2: Infrastructure Setup [PENDING]
- [ ] Verify AWS SSO session active (`aws sso login --profile dev`)
- [ ] Get bastion instance ID
- [ ] Get EFS access point for leadflow360
- [ ] Provision tenant in DEV environment

### Phase 3: File Transfer [PENDING]
- [ ] Start SSM port forwarding to bastion
- [ ] Create tar.gz of wp-content (exclude ai1wm-backups, wflogs)
- [ ] Transfer database to bastion
- [ ] Transfer wp-content archive to bastion

### Phase 4: Database Import [PENDING]
- [ ] Import leadflow360-fixed.sql to RDS
- [ ] Update siteurl/home to DEV domain
- [ ] Run URL replacement across all tables
- [ ] Verify import successful

### Phase 5: EFS File Copy [PENDING]
- [ ] Mount EFS on bastion
- [ ] Extract wp-content to EFS
- [ ] Fix permissions (chown -R 33:33)
- [ ] Deploy force-https.php MU-plugin

### Phase 6: Validation [PENDING]
- [ ] Verify site loads without redirect loop
- [ ] Check Elementor templates published
- [ ] Test admin login
- [ ] Verify theme/styles loading
- [ ] Test contact forms (redirect to test email)

## Important Commands

### AWS SSO Login
```bash
aws sso login --profile dev
export AWS_PROFILE=dev
```

### Start SSM Port Forwarding
```bash
BASTION_ID="i-xxxxxxxxx"  # Get from AWS console
aws ssm start-session --target $BASTION_ID \
  --document-name AWS-StartPortForwardingSession \
  --parameters '{"portNumber":["22"],"localPortNumber":["2222"]}' \
  --profile dev
```

### Create Archive (Exclude Unnecessary Files)
```bash
cd /Users/sithembisomjoko/Downloads/AGENTIC_WORK/2_bbws_agents/tenant/migrations/Leadflow360/site
tar -czvf ../leadflow360-wp-content.tar.gz \
  --exclude='wp-content/ai1wm-backups' \
  --exclude='wp-content/wflogs' \
  --exclude='wp-content/cache' \
  --exclude='.DS_Store' \
  wp-content
```

### Transfer to Bastion (via SSM port forwarding)
```bash
# In another terminal while port forwarding is active
scp -P 2222 leadflow360-wp-content.tar.gz ssm-user@localhost:/tmp/
scp -P 2222 database/leadflow360-fixed.sql ssm-user@localhost:/tmp/
```

## Post-Migration Notes

### URL Replacement SQL
```sql
SET @old_domain = 'leadflow360.co.za';
SET @new_domain = 'leadflow360.wpdev.kimmyai.io';

UPDATE wp_options SET option_value = REPLACE(option_value, @old_domain, @new_domain) WHERE option_value LIKE CONCAT('%', @old_domain, '%');
UPDATE wp_posts SET post_content = REPLACE(post_content, @old_domain, @new_domain) WHERE post_content LIKE CONCAT('%', @old_domain, '%');
UPDATE wp_posts SET guid = REPLACE(guid, @old_domain, @new_domain) WHERE guid LIKE CONCAT('%', @old_domain, '%');
UPDATE wp_postmeta SET meta_value = REPLACE(meta_value, @old_domain, @new_domain) WHERE meta_value LIKE CONCAT('%', @old_domain, '%');
UPDATE wp_yoast_indexable SET permalink = REPLACE(permalink, @old_domain, @new_domain) WHERE permalink LIKE CONCAT('%', @old_domain, '%');
```

### Elementor Template Check
```sql
-- After migration, ensure templates are published
SELECT ID, post_title, post_status FROM wp_posts WHERE post_type = 'elementor_library';

-- Fix if needed
UPDATE wp_posts SET post_status = 'publish' WHERE post_type = 'elementor_library' AND post_status = 'draft';
```

## Special Considerations

1. **Gravity Forms** - May need license reactivation after migration
2. **Elementor Pro** - Verify license key works on new domain
3. **Revolution Slider** - Check slider content loads correctly
4. **Redirection Plugin** - Monitor for any redirect conflicts with CloudFront

## Root Workflow Inheritance

This project inherits TBT mechanism and all workflow standards from the parent CLAUDE.md:

{{include:../../CLAUDE.md}}
