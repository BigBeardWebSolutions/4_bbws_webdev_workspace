# Content Manager Knowledge Check Quiz

**Total Questions**: 15
**Passing Score**: 80% (12/15)
**Time Limit**: 1 hour
**Format**: Multiple choice + Practical demonstrations

---

## Section A: WordPress Site Management (4 questions)

### Question 1: WordPress Admin Access
**Which URL path accesses the WordPress admin dashboard?**

A) `/admin/`
B) `/wp-admin/`
C) `/wordpress/admin/`
D) `/dashboard/`

**Correct Answer**: B

---

### Question 2: Permalink Structure
**Which permalink structure is recommended for SEO?**

A) `/?p=123`
B) `/archives/123`
C) `/%postname%/`
D) `/%year%/%monthnum%/%day%/%postname%/`

**Correct Answer**: C

**Explanation**: `/%postname%/` provides clean, keyword-rich URLs without unnecessary date prefixes.

---

### Question 3: User Roles
**Which WordPress user role can publish and manage ALL posts, including others' posts?**

A) Author
B) Contributor
C) Editor
D) Subscriber

**Correct Answer**: C

---

### Question 4: Practical - Site Configuration
**DEMONSTRATE: Access WordPress Settings > General and verify the following are configured:**
- Site Title
- Tagline
- WordPress Address (URL)
- Site Address (URL)
- Admin Email

**Provide screenshot showing these settings.**

---

## Section B: Data Import/Export (3 questions)

### Question 5: Export Content
**Which WordPress tool is used to export content to XML format?**

A) Tools > Import
B) Tools > Export
C) Settings > Export
D) Plugins > Export

**Correct Answer**: B

---

### Question 6: Search-Replace Command
**Which WP-CLI command updates URLs in the database after migration?**

A) `wp db update-url 'old.com' 'new.com'`
B) `wp search-replace 'old.com' 'new.com' --all-tables`
C) `wp migrate 'old.com' 'new.com'`
D) `wp url change 'old.com' 'new.com'`

**Correct Answer**: B

---

### Question 7: Practical - Export Site
**DEMONSTRATE: Export all content from a WordPress site using Tools > Export.**

Steps:
1. Navigate to Tools > Export
2. Select "All content"
3. Click "Download Export File"

**Provide screenshot of the export page.**

---

## Section C: Plugin Configuration (4 questions)

### Question 8: BBWS Standard Plugins
**How many plugins are in the BBWS standard plugin suite?**

A) 10
B) 13
C) 15
D) 20

**Correct Answer**: B

**Explanation**: The BBWS standard includes 13 plugins: Yoast SEO, Gravity Forms, Wordfence, W3 Total Cache, Really Simple SSL, WP Mail SMTP, Akismet, Classic Editor, CookieYes, Hustle, WP Headers And Footers, Yoast Duplicate Post, and UpdraftPlus.

---

### Question 9: Plugin Installation Order
**Which plugin should be installed FIRST on a new site?**

A) Yoast SEO
B) Really Simple SSL
C) W3 Total Cache
D) Gravity Forms

**Correct Answer**: B

**Explanation**: SSL should be enabled first to ensure all subsequent configurations use HTTPS.

---

### Question 10: Wordfence Configuration
**After installing Wordfence, what should the firewall mode be set to initially?**

A) Disabled
B) Learning Mode
C) Enabled and Protecting
D) Monitoring Only

**Correct Answer**: B

**Explanation**: Start in Learning Mode to let Wordfence learn normal traffic patterns before blocking.

---

### Question 11: Practical - Plugin Configuration
**DEMONSTRATE: Configure W3 Total Cache with the following settings:**
- Page Cache: Enabled (Disk: Enhanced)
- Browser Cache: Enabled

**Provide screenshot of the General Settings page showing these options enabled.**

---

## Section D: Theme Management (2 questions)

### Question 12: Child Theme Purpose
**Why should you create a child theme for customizations?**

A) It's faster than modifying the parent theme
B) Customizations are preserved when parent theme updates
C) Child themes use less server resources
D) WordPress requires child themes for all sites

**Correct Answer**: B

---

### Question 13: Custom CSS Location
**Where is the RECOMMENDED place to add custom CSS in WordPress?**

A) Edit theme's style.css directly
B) Appearance > Customize > Additional CSS
C) Create a custom CSS plugin
D) Add inline styles to each page

**Correct Answer**: B

**Explanation**: The Customizer's Additional CSS is preserved across theme updates and provides live preview.

---

## Section E: Backup and Troubleshooting (2 questions)

### Question 14: White Screen of Death
**A site shows a blank white screen. What is the FIRST troubleshooting step?**

A) Reinstall WordPress core
B) Enable WP_DEBUG in wp-config.php
C) Delete all plugins
D) Restore from backup

**Correct Answer**: B

**Explanation**: Enable debug mode first to see the actual error before taking action.

---

### Question 15: Practical - Backup Verification
**DEMONSTRATE: Create a database backup using UpdraftPlus and verify it was stored in S3.**

Steps:
1. Go to Settings > UpdraftPlus Backups
2. Click "Backup Now"
3. Select "Include database in backup"
4. Wait for completion
5. Verify S3 storage shows the backup

**Provide screenshots of:**
- Backup in progress
- Completed backup listing
- S3 bucket showing the backup file

---

## Scenario Questions

### Scenario: Plugin Conflict
**SCENARIO**: After activating a new plugin, the site shows a 500 error. The wp-admin is inaccessible.

**Question**: Describe the steps to resolve this issue without direct server access.

**Expected Answer Points**:
1. Access via WP-CLI through ECS exec (or FTP if available)
2. Run: `wp plugin deactivate --all`
3. Verify site loads
4. Reactivate plugins one by one to identify conflict
5. Check plugin compatibility with WordPress version
6. Contact plugin developer or find alternative

### Scenario: Site Migration
**SCENARIO**: You need to migrate a tenant site from DEV to SIT environment.

**Question**: List the complete steps for a successful migration.

**Expected Answer Points**:
1. Create full backup in DEV (database + files)
2. Export using All-in-One WP Migration or UpdraftPlus
3. Download/transfer export to SIT environment
4. Import in SIT environment
5. Run search-replace: `wp search-replace 'wpdev.kimmyai.io' 'wpsit.kimmyai.io' --all-tables`
6. Flush permalinks: `wp rewrite flush`
7. Clear all caches
8. Test all functionality (pages, forms, media)
9. Verify internal links work
10. Test on multiple devices

---

## Quiz Submission Requirements

### Practical Demonstration Evidence
Submit screenshots for:
- [ ] Question 4: Site Configuration Settings
- [ ] Question 7: Export Page
- [ ] Question 11: W3 Total Cache Settings
- [ ] Question 15: Backup to S3

### Scenario Responses
Submit written responses for:
- [ ] Plugin Conflict Scenario
- [ ] Site Migration Scenario

### Scoring
| Section | Questions | Points |
|---------|-----------|--------|
| Site Management | 4 | 28 |
| Data Import/Export | 3 | 20 |
| Plugin Configuration | 4 | 28 |
| Theme Management | 2 | 12 |
| Backup & Troubleshooting | 2 | 12 |
| **Total** | **15** | **100** |

### Passing Criteria
- Minimum 80% overall (12/15)
- All practical demonstrations must have valid screenshots
- Scenario responses must cover key points
- Plugin section cannot score below 50%

---

## Answer Key

| Q# | Answer |
|----|--------|
| 1 | B |
| 2 | C |
| 3 | C |
| 4 | Demo |
| 5 | B |
| 6 | B |
| 7 | Demo |
| 8 | B |
| 9 | B |
| 10 | B |
| 11 | Demo |
| 12 | B |
| 13 | B |
| 14 | B |
| 15 | Demo |

---

## Quick Reference: BBWS Standard Plugins

| Plugin | Purpose | Config Priority |
|--------|---------|-----------------|
| Really Simple SSL | HTTPS | 1 (First) |
| Wordfence | Security | 2 |
| W3 Total Cache | Performance | 3 |
| Yoast SEO | SEO | 4 |
| WP Mail SMTP | Email | 5 |
| Gravity Forms | Forms | 6 |
| Akismet | Anti-spam | 7 |
| CookieYes | GDPR | 8 |
| Classic Editor | Editor | Any |
| Hustle | Pop-ups | Any |
| WP Headers And Footers | Scripts | Any |
| Yoast Duplicate Post | Cloning | Any |
| UpdraftPlus | Backups | Early |

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-12-16 | Initial Content Manager quiz |
