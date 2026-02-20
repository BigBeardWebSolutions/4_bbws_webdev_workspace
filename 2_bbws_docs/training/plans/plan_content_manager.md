# Content Manager Training Plan

**Parent Plan**: [master_plan.md](./master_plan.md)
**Target Role**: WordPress Administrators, Content Teams, Site Managers
**Total Duration**: ~11.5 hours
**Status**: PENDING

---

## Overview

The Content Manager training module focuses on WordPress site administration, content management, plugin configuration, theme customization, data operations, and performance optimization within the multi-tenant ECS cluster environment.

---

## Submodule CM-01: WordPress Site Management Basics

**Duration**: 1.5 hours
**Status**: PENDING

### Learning Objectives
- Understand multi-tenant WordPress architecture
- Access WordPress admin across environments
- Navigate tenant-specific WordPress installations
- Perform basic site configuration

### Prerequisites
- WordPress basics (posts, pages, media)
- Access to tenant WordPress admin credentials
- Understanding of multi-tenant isolation

### Practical Exercises

#### Exercise CM-01-1: Access Tenant WordPress Admin
```bash
# Step 1: Get tenant URL
# DEV: tenant-1.wpdev.kimmyai.io
# SIT: tenant-1.wpsit.kimmyai.io
# PROD: tenant-1.wp.kimmyai.io

# Step 2: Access wp-admin
open "https://tenant-1.wpsit.kimmyai.io/wp-admin/"

# Step 3: Retrieve WordPress admin credentials
# (Stored in Secrets Manager or provided by tenant admin)
AWS_PROFILE=Tebogo-sit aws secretsmanager get-secret-value \
  --secret-id sit-tenant-1-wp-admin \
  --query 'SecretString' \
  --region eu-west-1
```

#### Exercise CM-01-2: Site Configuration
```markdown
## WordPress Settings Checklist

1. **General Settings** (/wp-admin/options-general.php)
   - [ ] Site Title configured
   - [ ] Tagline configured
   - [ ] WordPress Address (URL) correct
   - [ ] Site Address (URL) correct
   - [ ] Admin Email set
   - [ ] Timezone set

2. **Reading Settings** (/wp-admin/options-reading.php)
   - [ ] Homepage displays: Static page or Latest posts
   - [ ] Blog pages show: 10 posts
   - [ ] Search engine visibility: Unchecked (unless intentional)

3. **Permalink Settings** (/wp-admin/options-permalink.php)
   - [ ] SEO-friendly permalink structure: /%postname%/

4. **Discussion Settings** (/wp-admin/options-discussion.php)
   - [ ] Comment moderation configured
   - [ ] Spam protection enabled (Akismet)
```

#### Exercise CM-01-3: User Management
```markdown
## WordPress User Roles

| Role | Capabilities |
|------|-------------|
| Administrator | Full control, plugin/theme management |
| Editor | Publish/manage all posts, manage categories |
| Author | Publish/edit own posts |
| Contributor | Write/edit own posts (no publish) |
| Subscriber | Read content, manage profile |

## User Audit Commands (via WP-CLI)
```
# List all users
wp user list

# Check admin users
wp user list --role=administrator

# Last login audit
wp user list --fields=ID,user_login,user_email,user_registered
```

### Site Configuration Checklist
- [ ] Site title and tagline set
- [ ] Admin email configured
- [ ] Timezone correct
- [ ] Permalink structure is SEO-friendly
- [ ] Homepage configured
- [ ] All user roles reviewed

---

## Submodule CM-02: Data Import and Export Operations

**Duration**: 1.5 hours
**Status**: PENDING

### Learning Objectives
- Import content from XML/CSV
- Export site content
- Perform search-replace for migrations
- Handle large data imports

### Practical Exercises

#### Exercise CM-02-1: Export WordPress Content
```markdown
## Via WordPress Admin UI

1. Navigate to Tools > Export
2. Select content type:
   - All content
   - Posts only
   - Pages only
   - Media only
3. Download XML file

## Via WP-CLI (ECS Exec)
```
# Export all content
wp export --dir=/tmp/exports/

# Export specific post type
wp export --post_type=page --dir=/tmp/exports/

# Export with filters
wp export --post_type=post --start_date=2025-01-01 --dir=/tmp/exports/
```

#### Exercise CM-02-2: Import WordPress Content
```markdown
## Via WordPress Admin UI

1. Navigate to Tools > Import
2. Install WordPress Importer plugin (if not installed)
3. Upload XML file
4. Map authors or create new
5. Import attachments option

## Via WP-CLI (ECS Exec)
```
# Import XML file
wp import /tmp/exports/tenant-export.xml --authors=create

# Import with verbose output
wp import /tmp/exports/export.xml --authors=mapping.csv --verbose
```

#### Exercise CM-02-3: Database Search-Replace
```bash
# CRITICAL: Always backup before search-replace!

# Via WP-CLI in ECS container
# Dry run (preview changes)
wp search-replace 'http://old-domain.com' 'https://new-domain.com' --dry-run

# Execute search-replace
wp search-replace 'http://old-domain.com' 'https://new-domain.com' --all-tables

# Search-replace for environment promotion
wp search-replace 'wpdev.kimmyai.io' 'wpsit.kimmyai.io' --all-tables
wp search-replace 'wpsit.kimmyai.io' 'wp.kimmyai.io' --all-tables
```

#### Exercise CM-02-4: Large Data Import (All-in-One WP Migration)
```markdown
## For Large Sites (>100MB)

1. Install All-in-One WP Migration plugin
2. On SOURCE site: Export as .wpress file
3. Upload .wpress to S3 bucket
4. On TARGET site:
   - Install plugin
   - Configure max upload size (php.ini)
   - Import from .wpress file
5. Run search-replace if needed
6. Flush permalinks
7. Clear all caches

## Upload Size Configuration
```
# In php.ini or .htaccess
upload_max_filesize = 512M
post_max_size = 512M
max_execution_time = 600
memory_limit = 512M
```

### Data Import/Export Checklist
- [ ] Created backup before import
- [ ] Exported content successfully
- [ ] Import completed without errors
- [ ] All images/media transferred
- [ ] URLs updated (search-replace)
- [ ] Permalinks flushed
- [ ] Internal links working

---

## Submodule CM-03: Plugin Installation and Configuration

**Duration**: 2 hours
**Status**: PENDING

### Learning Objectives
- Install BBWS standard plugins
- Configure each plugin correctly
- Troubleshoot plugin conflicts
- Manage plugin updates

### BBWS Standard Plugin Suite

| Plugin | Purpose | License |
|--------|---------|---------|
| Yoast SEO | Search engine optimization | Premium (optional) |
| Gravity Forms | Form builder | Premium |
| Wordfence Security | Security & firewall | Free/Premium |
| W3 Total Cache | Performance caching | Free |
| Really Simple SSL | HTTPS enforcement | Free |
| WP Mail SMTP | Email delivery | Free |
| Akismet Anti-Spam | Comment spam protection | Free (API key) |
| Classic Editor | Traditional editor | Free |
| CookieYes | GDPR cookie consent | Free |
| Hustle | Pop-ups & opt-ins | Free |
| WP Headers And Footers | Header/footer scripts | Free |
| Yoast Duplicate Post | Clone posts/pages | Free |
| UpdraftPlus | Backups | Free |

### Practical Exercises

#### Exercise CM-03-1: Install and Configure Yoast SEO
```markdown
## Installation
1. Plugins > Add New > Search "Yoast SEO"
2. Install & Activate

## Configuration Checklist
- [ ] Run configuration wizard
- [ ] Set site representation (Organization)
- [ ] Configure knowledge graph (name, logo)
- [ ] Enable XML sitemaps
- [ ] Configure breadcrumbs
- [ ] Set up Open Graph defaults
- [ ] Configure schema settings

## Key Settings (/wp-admin/admin.php?page=wpseo_dashboard)
- Site Basics: Name, tagline, logo
- Site Representation: Person or Organization
- Social Profiles: Facebook, Twitter, LinkedIn
- Site Connections: Google Search Console

## SEO Analysis Target
- Green light on 80%+ of pages
- Focus keyword set on all pages
- Meta descriptions under 155 characters
```

#### Exercise CM-03-2: Install and Configure Wordfence
```markdown
## Installation
1. Plugins > Add New > Search "Wordfence"
2. Install & Activate
3. Enter license key (if premium)

## Configuration Checklist
- [ ] Run initial scan
- [ ] Configure firewall (Learning Mode → Enabled)
- [ ] Enable brute force protection
- [ ] Configure scan schedule (daily)
- [ ] Set up email alerts
- [ ] Enable two-factor authentication

## Key Settings (/wp-admin/admin.php?page=WordfenceSecOption)
- Firewall Options:
  - Firewall Mode: Enabled and Protecting
  - Rate Limiting: Enabled
- Scan Options:
  - General Options: Full scan
  - Schedule: Daily at 3:00 AM
- Login Security:
  - 2FA: Enabled for admins
  - Login attempt limit: 5 attempts
  - Lockout duration: 15 minutes
```

#### Exercise CM-03-3: Install and Configure W3 Total Cache
```markdown
## Installation
1. Plugins > Add New > Search "W3 Total Cache"
2. Install & Activate

## Configuration Checklist
- [ ] Enable Page Cache
- [ ] Enable Browser Cache
- [ ] Configure CDN (CloudFront)
- [ ] Enable Object Cache (optional)
- [ ] Test cache is working

## Key Settings (/wp-admin/admin.php?page=w3tc_general)
- Page Cache: Enabled (Disk: Enhanced)
- Browser Cache: Enabled
- CDN: CloudFront (enter distribution ID)

## Cache Exclusions
- /wp-admin/*
- /wp-login.php
- Logged-in users
- Cart/checkout pages (if WooCommerce)

## Verification
```bash
# Check for cache headers
curl -I https://tenant-1.wpsit.kimmyai.io/ | grep -i cache
# Expected: X-Cache: HIT from cloudfront
```

#### Exercise CM-03-4: Install and Configure Gravity Forms
```markdown
## Installation (Premium)
1. Download from gravityforms.com
2. Plugins > Add New > Upload Plugin
3. Install & Activate
4. Enter license key

## Configuration Checklist
- [ ] License activated
- [ ] reCAPTCHA configured
- [ ] Notification emails set
- [ ] Default form styling selected

## Creating a Contact Form
1. Forms > New Form
2. Add fields:
   - Name (required)
   - Email (required)
   - Phone
   - Message (paragraph)
3. Configure notifications:
   - Admin notification (to site owner)
   - User confirmation (to submitter)
4. Set confirmation message
5. Embed with shortcode: [gravityform id="1"]

## Testing
- Submit test form
- Verify admin receives notification
- Check entries in Forms > Entries
```

#### Exercise CM-03-5: Configure WP Mail SMTP for SES
```markdown
## Installation
1. Plugins > Add New > Search "WP Mail SMTP"
2. Install & Activate

## Configuration for Amazon SES
1. Navigate to WP Mail SMTP > Settings
2. Select Mailer: Amazon SES
3. Enter credentials:
   - Access Key ID: (from IAM)
   - Secret Access Key: (from IAM)
   - Region: eu-west-1
4. From Email: noreply@kimmyai.io
5. From Name: Site Name

## Verification
1. Go to WP Mail SMTP > Tools > Email Test
2. Send test email
3. Check delivery in email inbox
4. Verify no spam folder delivery
```

### Plugin Configuration Matrix

| Plugin | Priority | Configure After | Dependencies |
|--------|----------|----------------|--------------|
| Really Simple SSL | 1 | SSL cert active | ACM certificate |
| Wordfence | 2 | SSL enabled | None |
| W3 Total Cache | 3 | Basic setup | CloudFront |
| Yoast SEO | 4 | Content added | None |
| WP Mail SMTP | 5 | Any time | SES configured |
| Gravity Forms | 6 | SMTP configured | WP Mail SMTP |
| Akismet | 7 | Any time | API key |
| CookieYes | 8 | Before go-live | None |

---

## Submodule CM-04: Theme Management and Customization

**Duration**: 1.5 hours
**Status**: PENDING

### Learning Objectives
- Install and activate themes
- Use the WordPress Customizer
- Create and use child themes
- Apply custom CSS

### Practical Exercises

#### Exercise CM-04-1: Install Theme
```markdown
## From WordPress.org
1. Appearance > Themes > Add New
2. Search for theme (e.g., "Astra", "GeneratePress")
3. Install & Activate

## From ZIP File (Premium Theme)
1. Appearance > Themes > Add New > Upload Theme
2. Select ZIP file
3. Install & Activate

## Recommended BBWS Themes
- Astra (lightweight, customizable)
- GeneratePress (performance-focused)
- Kadence (block-friendly)
- OceanWP (feature-rich)
```

#### Exercise CM-04-2: Customizer Configuration
```markdown
## Access: Appearance > Customize

### Site Identity
- [ ] Logo uploaded (recommended: 200x50px)
- [ ] Favicon uploaded (512x512px)
- [ ] Site title configured
- [ ] Tagline configured

### Colors
- [ ] Primary color set (brand color)
- [ ] Secondary color set
- [ ] Background color set
- [ ] Text colors readable (contrast check)

### Typography
- [ ] Heading font selected
- [ ] Body font selected
- [ ] Font sizes appropriate

### Menus
- [ ] Primary menu created
- [ ] Footer menu created
- [ ] Menu locations assigned

### Widgets
- [ ] Sidebar widgets configured
- [ ] Footer widgets configured

### Homepage
- [ ] Static page set (if applicable)
- [ ] Blog page set
```

#### Exercise CM-04-3: Create Child Theme
```bash
# Child theme structure
/wp-content/themes/parent-theme-child/
  ├── style.css
  ├── functions.php
  └── screenshot.png

# style.css content
/*
Theme Name: Parent Theme Child
Template: parent-theme
Description: Child theme for customizations
Version: 1.0
*/

/* Custom CSS goes here */

# functions.php content
<?php
add_action('wp_enqueue_scripts', 'child_theme_styles');
function child_theme_styles() {
    wp_enqueue_style('parent-style', get_template_directory_uri() . '/style.css');
    wp_enqueue_style('child-style', get_stylesheet_uri(), array('parent-style'));
}
```

#### Exercise CM-04-4: Add Custom CSS
```markdown
## Via Customizer (Recommended)
1. Appearance > Customize > Additional CSS
2. Add custom CSS
3. Preview changes
4. Publish

## Example Custom CSS
```css
/* Brand colors */
:root {
  --primary-color: #2563eb;
  --secondary-color: #1e40af;
}

/* Custom button style */
.wp-block-button__link {
  background-color: var(--primary-color);
  border-radius: 4px;
}

/* Custom header */
.site-header {
  background-color: #ffffff;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}
```

### Theme Customization Checklist
- [ ] Theme installed and activated
- [ ] Logo and favicon configured
- [ ] Brand colors applied
- [ ] Typography configured
- [ ] Menus created and assigned
- [ ] Homepage configured
- [ ] Child theme created (for custom modifications)
- [ ] Custom CSS applied (if needed)

---

## Submodule CM-05: Database Backup and Recovery

**Duration**: 1.5 hours
**Status**: PENDING

### Learning Objectives
- Create manual database backups
- Schedule automated backups
- Restore from backups
- Verify backup integrity

### Practical Exercises

#### Exercise CM-05-1: Manual Backup via Plugin (UpdraftPlus)
```markdown
## Installation
1. Plugins > Add New > Search "UpdraftPlus"
2. Install & Activate

## Create Manual Backup
1. Settings > UpdraftPlus Backups
2. Click "Backup Now"
3. Select components:
   - [x] Include database
   - [x] Include files
4. Wait for backup to complete
5. Download backup files

## Configure S3 Storage
1. Settings > UpdraftPlus > Settings
2. Remote Storage: Amazon S3
3. Enter credentials:
   - Access Key: (from IAM)
   - Secret Key: (from IAM)
   - S3 Bucket: bbws-backups-sit
   - S3 Path: tenant-1/
4. Test connection
5. Save settings
```

#### Exercise CM-05-2: Schedule Automated Backups
```markdown
## UpdraftPlus Schedule
1. Settings > UpdraftPlus > Settings
2. Files backup schedule: Daily, retain 7
3. Database backup schedule: Daily, retain 14
4. Remote storage: Amazon S3
5. Save settings

## Backup Retention Matrix

| Environment | Database | Files | Retention |
|-------------|----------|-------|-----------|
| DEV | Daily | Weekly | 7 days |
| SIT | Daily | Daily | 14 days |
| PROD | Every 6 hours | Daily | 30 days |
```

#### Exercise CM-05-3: Restore from Backup
```markdown
## Via UpdraftPlus
1. Settings > UpdraftPlus Backups
2. Find backup to restore (or upload)
3. Click "Restore"
4. Select components to restore:
   - [x] Database
   - [x] Plugins
   - [x] Themes
   - [x] Uploads
   - [x] Others
5. Confirm restore
6. Wait for completion
7. Verify site functionality

## Via WP-CLI (Database Only)
```bash
# Import database backup
wp db import /tmp/backup.sql

# Verify import
wp db check
```

#### Exercise CM-05-4: Verify Backup Integrity
```bash
# List S3 backups
AWS_PROFILE=Tebogo-sit aws s3 ls s3://bbws-backups-sit/tenant-1/ --recursive

# Download and verify
AWS_PROFILE=Tebogo-sit aws s3 cp s3://bbws-backups-sit/tenant-1/backup-db-2025-12-16.sql.gz ./

# Check file integrity
gunzip -t backup-db-2025-12-16.sql.gz
# Output: OK (if no output, file is valid)

# Check database content
gunzip -c backup-db-2025-12-16.sql.gz | head -100
# Should show SQL statements
```

### Backup Verification Checklist
- [ ] Backup completed successfully
- [ ] Backup files exist in S3
- [ ] Backup file size is reasonable (not 0 bytes)
- [ ] Database backup can be extracted
- [ ] Test restore in DEV environment successful

---

## Submodule CM-06: Content Troubleshooting

**Duration**: 2 hours
**Status**: PENDING

### Learning Objectives
- Troubleshoot common WordPress issues
- Debug plugin conflicts
- Fix broken media and links
- Resolve performance issues

### Common Issues and Solutions

#### Issue 1: White Screen of Death (WSOD)
```markdown
## Symptoms
- Blank white page
- No error message
- Cannot access wp-admin

## Diagnosis
1. Enable debug mode (add to wp-config.php):
   ```php
   define('WP_DEBUG', true);
   define('WP_DEBUG_LOG', true);
   define('WP_DEBUG_DISPLAY', false);
   ```
2. Check /wp-content/debug.log
3. Check CloudWatch logs

## Common Causes & Solutions
- Plugin conflict: Deactivate plugins via database
  ```sql
  UPDATE wp_options SET option_value = 'a:0:{}' WHERE option_name = 'active_plugins';
  ```
- Theme issue: Rename active theme folder
- Memory limit: Increase WP_MEMORY_LIMIT
- PHP syntax error: Check error log for file/line
```

#### Issue 2: Plugin Conflicts
```markdown
## Diagnosis Steps
1. Deactivate all plugins
2. Activate one by one
3. Identify conflicting plugin
4. Check for alternative or update

## Safe Mode (via WP-CLI)
```bash
# Deactivate all plugins
wp plugin deactivate --all

# Activate one by one
wp plugin activate yoast-seo
wp plugin activate wordfence
# ... test after each
```

## Common Conflict Pairs
- Two caching plugins
- Two SEO plugins
- Security plugins blocking legitimate traffic
```

#### Issue 3: Broken Media/Images
```markdown
## Symptoms
- Images show as broken
- Media library empty
- Thumbnails not generating

## Diagnosis
```bash
# Check uploads directory
ls -la /var/www/html/wp-content/uploads/

# Check EFS mount
df -h | grep efs

# Check file permissions
stat /var/www/html/wp-content/uploads/
```

## Solutions
- Regenerate thumbnails: `wp media regenerate --yes`
- Fix permissions: `chmod -R 755 wp-content/uploads/`
- Verify EFS access point mounted
- Check for missing files after migration
```

#### Issue 4: Slow Page Load
```markdown
## Diagnosis
1. Test page speed: Google PageSpeed Insights
2. Enable Query Monitor plugin
3. Check for slow database queries

## Common Causes & Solutions
| Issue | Check | Solution |
|-------|-------|----------|
| No caching | X-Cache header | Enable W3 Total Cache |
| Large images | File sizes | Optimize with ShortPixel |
| Too many plugins | Plugin count | Deactivate unused |
| Slow queries | Query Monitor | Optimize database |
| External scripts | Network tab | Defer/async load |

## Quick Wins
```bash
# Clear cache
wp cache flush
wp w3-total-cache flush all

# Optimize database
wp db optimize

# Check autoload options (common bloat)
wp option list --autoload=yes --format=csv | awk -F',' '{print length($3), $1}' | sort -rn | head -20
```

#### Issue 5: 404 Errors After Migration
```markdown
## Symptoms
- Pages return 404
- Only homepage works
- Posts not accessible

## Solution
1. Flush permalinks:
   - Settings > Permalinks > Save Changes
   - Or: `wp rewrite flush`

2. Check .htaccess exists:
   ```bash
   cat /var/www/html/.htaccess
   ```

3. Regenerate .htaccess:
   ```bash
   wp rewrite flush --hard
   ```

4. Check nginx config (if using nginx)
```

### Troubleshooting Flowchart

```
Site Not Loading?
       │
       ▼
 Check if server responding
 (curl -I site-url)
       │
       ├─── No Response ──► Check ECS task status
       │                    Check ALB health
       │
       ▼
 Check error logs
 (CloudWatch /ecs/sit)
       │
       ├─── PHP Error ──► Fix code/plugin issue
       │
       ├─── Memory ──► Increase WP_MEMORY_LIMIT
       │
       ├─── Database ──► Check RDS connectivity
       │
       └─── 404 ──► Flush permalinks
```

---

## Submodule CM-07: Performance Optimization for Content

**Duration**: 1.5 hours
**Status**: PENDING

### Learning Objectives
- Optimize images for web
- Configure effective caching
- Reduce page weight
- Improve Core Web Vitals

### Practical Exercises

#### Exercise CM-07-1: Image Optimization
```markdown
## Manual Optimization
1. Resize images before upload (max 1920px width)
2. Use appropriate format:
   - Photos: WebP or JPEG
   - Graphics: PNG or SVG
   - Animated: GIF or WebP
3. Compress before upload (TinyPNG, Squoosh)

## Plugin-Based Optimization
1. Install ShortPixel or Smush
2. Configure:
   - Compression level: Lossy (smaller) or Lossless
   - Resize large images: Max 2048px
   - Convert to WebP: Enabled
3. Bulk optimize existing images

## Lazy Loading
- Native: Add loading="lazy" to images
- Plugin: Enable in W3 Total Cache
- Check: images below fold load on scroll
```

#### Exercise CM-07-2: Cache Configuration
```markdown
## W3 Total Cache Settings for Performance

### Page Cache
- Method: Disk: Enhanced
- Cache posts page: Enabled
- Cache feeds: Enabled
- Cache 404 pages: Disabled
- Cache logged-in users: Disabled

### Browser Cache
- Enable: Yes
- Cache-Control header: max-age=31536000
- Expires header: Enabled

### CDN (CloudFront)
- Enable: Yes
- CDN Type: CloudFront
- Distribution ID: [from terraform output]
- CNAMEs: [tenant-1.wpsit.kimmyai.io]

### Minification
- Enable: Yes
- HTML: Enabled
- JS: Enabled (combine, defer)
- CSS: Enabled (combine)
```

#### Exercise CM-07-3: Core Web Vitals Optimization
```markdown
## Key Metrics

| Metric | Good | Needs Improvement | Poor |
|--------|------|-------------------|------|
| LCP | <2.5s | 2.5s-4s | >4s |
| FID | <100ms | 100ms-300ms | >300ms |
| CLS | <0.1 | 0.1-0.25 | >0.25 |

## LCP (Largest Contentful Paint) Fixes
- Optimize hero images
- Preload critical assets
- Use CDN for images
- Remove render-blocking resources

## FID (First Input Delay) Fixes
- Defer non-critical JavaScript
- Reduce JavaScript execution time
- Break up long tasks

## CLS (Cumulative Layout Shift) Fixes
- Set dimensions on images/embeds
- Reserve space for ads
- Avoid inserting content above existing content

## Testing
- Google PageSpeed Insights
- Chrome DevTools Lighthouse
- Web Vitals Chrome extension
```

#### Exercise CM-07-4: Performance Audit Checklist
```markdown
## Pre-Launch Performance Checklist

### Images
- [ ] All images optimized (<200KB for hero images)
- [ ] WebP format enabled
- [ ] Lazy loading enabled
- [ ] Responsive images (srcset) used

### Caching
- [ ] Page cache enabled
- [ ] Browser cache configured (1 year for static)
- [ ] Object cache enabled (if high traffic)
- [ ] CDN configured (CloudFront)

### Code Optimization
- [ ] CSS minified
- [ ] JavaScript minified
- [ ] Unused CSS removed
- [ ] JavaScript deferred/async

### Database
- [ ] Post revisions limited
- [ ] Spam comments deleted
- [ ] Transients cleaned
- [ ] Database optimized

### Core Web Vitals
- [ ] LCP < 2.5s
- [ ] FID < 100ms
- [ ] CLS < 0.1

### Test Results
- PageSpeed Mobile Score: _____
- PageSpeed Desktop Score: _____
- GTmetrix Grade: _____
```

### Performance Targets by Site Type

| Site Type | Target Load Time | PageSpeed Score |
|-----------|------------------|-----------------|
| Brochure site | <2s | 90+ |
| Blog | <2.5s | 85+ |
| E-commerce | <3s | 75+ |
| Web application | <3.5s | 70+ |

---

## Completion Criteria

To complete the Content Manager training module:

1. Complete all 7 submodules (CM-01 to CM-07)
2. Submit screenshots for each exercise
3. Pass the Content Manager Knowledge Check Quiz (80%+)
4. Successfully configure all 13 standard plugins on a test site
5. Successfully import/export a WordPress site
6. Achieve PageSpeed score of 80+ on test site

---

## Next Steps

After completing Content Manager training:
1. Take the [Content Manager Quiz](../content_manager/quiz_content_manager.md)
2. Practice on multiple tenant sites
3. Learn Tenant Admin basics for escalation paths
4. Document site-specific configurations

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-12-16 | Initial Content Manager training plan |
