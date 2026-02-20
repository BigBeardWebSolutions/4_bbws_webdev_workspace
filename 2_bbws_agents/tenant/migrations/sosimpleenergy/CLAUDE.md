# sosimpleenergy - WordPress Migration

## Project Purpose

Migrate sosimpleenergy.co.za WordPress site to the BBWS multi-tenant AWS hosting platform.

## Migration Status: In Progress

**Current Phase:** File Upload to S3 (slow connection, may need direct bastion)

---

## Site Profile

| Property | Value |
|----------|-------|
| **Production Domain** | https://sosimpleenergy.co.za |
| **Alternative Domain** | https://www.sosimpleenergy.co.za |
| **DEV Domain** | sosimpleenergy.wpdev.kimmyai.io |
| **Database File** | sosimpleenergy-fixed.sql (49MB) |
| **wp-content** | wp-content.tar.gz (1.0GB) |
| **Table Prefix** | wp_ |
| **Total Size** | 2.6GB |
| **Transfer Method** | S3 Staging (> 500MB) or Direct Bastion |
| **Theme** | hello-elementor (Elementor site) |

## Plugins

### Deactivated by Migration Script
- `really-simple-ssl` - redirect loop prevention
- `wordfence` - firewall issues

### Active Plugins
- elementor + elementor-pro (Page builder - CRITICAL)
- gravityforms + gravityformsrecaptcha (Forms)
- wordpress-seo (Yoast SEO)
- complianz-gdpr (GDPR compliance)
- chaty-pro, chatway-live-chat (Chat widgets)
- wp-mail-smtp (Email)
- wp-fastest-cache (Caching)
- wp-security-audit-log (Audit logs)
- advanced-custom-fields (ACF)

## Prepared Files

Located in this folder:
- `database/sosimpleenergy-fixed.sql` - Prepared database (plugins deactivated)
- `site/wp-content.tar.gz` - Packaged wp-content (1.0GB)

## S3 Staging

```
s3://wordpress-migration-temp-20250903/sosimpleenergy/
```

## Transfer Options

### Option A: S3 Upload (if connection stable)
```bash
aws s3 cp database/sosimpleenergy-fixed.sql s3://wordpress-migration-temp-20250903/sosimpleenergy/ --profile dev
aws s3 cp site/wp-content.tar.gz s3://wordpress-migration-temp-20250903/sosimpleenergy/ --profile dev
```

### Option B: Direct Bastion (if S3 times out)
```bash
# Step 1: Get bastion instance ID
BASTION_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=*bastion*" "Name=instance-state-name,Values=running" --query 'Reservations[0].Instances[0].InstanceId' --output text --profile dev)

# Step 2: Start SSM port forwarding
aws ssm start-session --target $BASTION_ID \
  --document-name AWS-StartPortForwardingSession \
  --parameters '{"portNumber":["22"],"localPortNumber":["2222"]}' \
  --profile dev

# Step 3: In another terminal, SCP files to bastion
scp -P 2222 database/sosimpleenergy-fixed.sql ssm-user@localhost:/tmp/
scp -P 2222 site/wp-content.tar.gz ssm-user@localhost:/tmp/
```

## URL Replacement SQL

```sql
-- Update siteurl and home
UPDATE wp_options SET option_value = 'https://sosimpleenergy.wpdev.kimmyai.io' WHERE option_name IN ('siteurl', 'home');

-- Replace domain in all tables
UPDATE wp_options SET option_value = REPLACE(option_value, 'sosimpleenergy.co.za', 'sosimpleenergy.wpdev.kimmyai.io') WHERE option_value LIKE '%sosimpleenergy.co.za%';
UPDATE wp_posts SET post_content = REPLACE(post_content, 'sosimpleenergy.co.za', 'sosimpleenergy.wpdev.kimmyai.io') WHERE post_content LIKE '%sosimpleenergy.co.za%';
UPDATE wp_posts SET guid = REPLACE(guid, 'sosimpleenergy.co.za', 'sosimpleenergy.wpdev.kimmyai.io') WHERE guid LIKE '%sosimpleenergy.co.za%';
UPDATE wp_postmeta SET meta_value = REPLACE(meta_value, 'sosimpleenergy.co.za', 'sosimpleenergy.wpdev.kimmyai.io') WHERE meta_value LIKE '%sosimpleenergy.co.za%';

-- Also replace www version
UPDATE wp_options SET option_value = REPLACE(option_value, 'www.sosimpleenergy.co.za', 'sosimpleenergy.wpdev.kimmyai.io') WHERE option_value LIKE '%www.sosimpleenergy.co.za%';
UPDATE wp_posts SET post_content = REPLACE(post_content, 'www.sosimpleenergy.co.za', 'sosimpleenergy.wpdev.kimmyai.io') WHERE post_content LIKE '%www.sosimpleenergy.co.za%';
UPDATE wp_posts SET guid = REPLACE(guid, 'www.sosimpleenergy.co.za', 'sosimpleenergy.wpdev.kimmyai.io') WHERE guid LIKE '%www.sosimpleenergy.co.za%';
UPDATE wp_postmeta SET meta_value = REPLACE(meta_value, 'www.sosimpleenergy.co.za', 'sosimpleenergy.wpdev.kimmyai.io') WHERE meta_value LIKE '%www.sosimpleenergy.co.za%';

-- Yoast SEO tables
UPDATE wp_yoast_indexable SET permalink = REPLACE(permalink, 'sosimpleenergy.co.za', 'sosimpleenergy.wpdev.kimmyai.io') WHERE permalink LIKE '%sosimpleenergy.co.za%';
UPDATE wp_yoast_seo_links SET url = REPLACE(url, 'sosimpleenergy.co.za', 'sosimpleenergy.wpdev.kimmyai.io') WHERE url LIKE '%sosimpleenergy.co.za%';
```

## Special Considerations

1. **Elementor site** - Must verify templates are published post-migration
2. **Gravity Forms with reCAPTCHA** - Will need new keys for DEV domain
3. **GDPR plugin (Complianz)** - May need reconfiguration for new domain
4. **Subdomain folder** (cthingcloud.sosimpleenergy.co.za) - Static HTML only, not migrated

---

## Root Workflow Inheritance

This project inherits TBT mechanism and all workflow standards from the parent CLAUDE.md:

{{include:../CLAUDE.md}}
