# Phase 2: Xneelo Data Export

**Phase**: 2 of 10
**Duration**: 1.5 days (12 hours)
**Responsible**: Site Owner + Technical Lead
**Environment**: Xneelo
**Dependencies**: Phase 1 (Environment Setup) Complete
**Status**: ✅ COMPLETE

---

## Phase Objectives

- Export complete WordPress database from Xneelo phpMyAdmin
- Download all WordPress files from Xneelo hosting
- Document all configuration settings and credentials
- Verify export integrity (no data loss or corruption)
- Document premium plugin licenses and API keys
- Take baseline screenshots for comparison
- Create organized backup package ready for import

---

## Prerequisites

- [ ] Xneelo cPanel credentials available
- [ ] Sufficient local disk space (minimum 5 GB)
- [ ] Stable internet connection
- [ ] FTP client installed (FileZilla, Cyberduck, or similar)
- [ ] Text editor for documentation (VS Code, Notepad++, or similar)
- [ ] Screenshot tool ready
- [ ] Reference: `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/training/xneelo_export_instructions.md`

---

## Detailed Tasks

### Task 2.1: Access Xneelo cPanel

**Duration**: 15 minutes
**Responsible**: Site Owner

**Steps**:

1. **Navigate to Xneelo Control Panel**:
   - Go to https://www.xneelo.co.za/cpanel
   - Or access via email link from Xneelo

2. **Login with credentials**:
   - Username: [from Xneelo account]
   - Password: [from Xneelo account]

3. **Verify access**:
   - Confirm you can see cPanel dashboard
   - Note cPanel version and features available

4. **Document cPanel details**:
```
Xneelo Account Details
---
cPanel URL: __________________
Username: __________________
Server: __________________
Primary Domain: aupairhive.com
```

**Troubleshooting**:
- **Issue**: Cannot find cPanel login URL
  - **Solution**: Check Xneelo welcome email or contact Xneelo support

- **Issue**: Forgotten password
  - **Solution**: Use "Forgot Password" link or contact Xneelo support

**Verification**:
- [ ] Successfully logged into cPanel
- [ ] cPanel details documented

---

### Task 2.2: Export WordPress Database

**Duration**: 1 hour
**Responsible**: Site Owner (with Technical Lead support)

**Steps**:

1. **Access phpMyAdmin**:
   - In cPanel, scroll to "Databases" section
   - Click "phpMyAdmin"
   - phpMyAdmin opens in new tab

2. **Identify WordPress database**:
   - Look in left sidebar for database name
   - Usually named: `username_wp###` or similar
   - If unsure, check wp-config.php in File Manager

3. **Select database**:
   - Click database name in left sidebar
   - Verify tables start with `wp_` prefix

4. **Export database**:
   - Click "Export" tab at top
   - Select **"Custom"** export method (NOT Quick)
   
   **Configure export settings**:
   - Format: SQL
   - Tables: Select all (should be ~12-20 tables)
   - Output: "Save output to a file"
   - Format-specific options:
     - ✅ Add DROP TABLE statement
     - ✅ Add CREATE TABLE statement
     - ✅ Enclose table and column names with backquotes
   - Data dump options:
     - ✅ Complete inserts
     - ✅ Extended inserts
   - Compression: None (unless database >100 MB, then use gzip)

5. **Download export**:
   - Click "Go" at bottom
   - Save file as: `aupairhive_database_YYYYMMDD.sql`
   - Example: `aupairhive_database_20260109.sql`

6. **Verify export**:
   - Check file size (should be at least 1-5 MB)
   - Open in text editor and verify it starts with SQL comments
   - Check for `CREATE TABLE` and `INSERT INTO` statements

7. **Document database info**:
```
Database Information
---
Database Name: ___________________
Database User: ___________________
Database Host: localhost
Character Set: utf8mb4
Collation: utf8mb4_unicode_ci
Export File: aupairhive_database_20260109.sql
File Size: ___________ MB
Table Count: _____ (count tables in phpMyAdmin)
```

**Troubleshooting**:
- **Issue**: Export times out
  - **Solution**: Use "Quick" export instead, or export tables in batches

- **Issue**: Cannot find database name
  - **Solution**: Go to File Manager → public_html → wp-config.php → look for DB_NAME

- **Issue**: Downloaded file is corrupted (0 bytes or incomplete)
  - **Solution**: Try export again, use compression if large

**Verification**:
- [ ] Database export file downloaded
- [ ] File size is reasonable (1-5 MB expected)
- [ ] File contains SQL statements (verified by opening in text editor)
- [ ] Database info documented

---

### Task 2.3: Download WordPress Files

**Duration**: 2-3 hours (depending on file size and connection speed)
**Responsible**: Site Owner

**Method A: Using cPanel File Manager** (Recommended):

1. **Access File Manager**:
   - In cPanel, go to "Files" section
   - Click "File Manager"

2. **Navigate to WordPress directory**:
   - Usually: `/public_html/`
   - Verify you see: wp-admin/, wp-content/, wp-includes/, wp-config.php

3. **Create archive**:
   - Select all files and folders in public_html
   - Click "Compress" in toolbar
   - Choose "Zip Archive"
   - Name: `aupairhive_files_20260109.zip`
   - Click "Compress File(s)"
   - Wait for compression to complete (5-15 minutes)

4. **Download archive**:
   - Find the .zip file in File Manager
   - Right-click → Download
   - Save to local computer in dedicated folder: `AuPairHive_Backup/`
   - Wait for download (may take 30-60 minutes for large sites)

5. **Verify download**:
   - Check file size matches what's shown in File Manager
   - Extract a small portion to test archive is not corrupted

6. **Clean up** (Optional):
   - Delete the .zip file from server to free space

**Method B: Using FTP** (If File Manager fails):

1. **Get FTP credentials**:
   - In cPanel → Files → FTP Accounts
   - Note: FTP Server, Username, Password

2. **Connect with FTP client** (FileZilla):
   - Host: ftp.aupairhive.com
   - Username: [from cPanel]
   - Password: [from cPanel]
   - Port: 21
   - Click "Quickconnect"

3. **Navigate and download**:
   - Remote site: /public_html/
   - Local site: Create folder `AuPairHive_Backup/files/`
   - Select all files/folders
   - Right-click → Download
   - Wait for transfer to complete

4. **Verify download**:
   - Check file count matches between local and remote
   - Verify total size is similar

**Troubleshooting**:
- **Issue**: Compression fails (file too large)
  - **Solution**: Compress subdirectories separately (wp-content, wp-admin, etc.)

- **Issue**: Download fails or times out
  - **Solution**: Use FTP Method B, or download in smaller chunks

- **Issue**: Slow download speed
  - **Solution**: Use download during off-peak hours, or use FTP resume capability

**Verification**:
- [ ] WordPress files archived (zip file created)
- [ ] Files downloaded to local computer
- [ ] Download verified (file size matches, archive extracts successfully)
- [ ] Folder structure preserved (wp-admin, wp-content, wp-includes present)

---

### Task 2.4: Document Plugin Licenses and API Keys

**Duration**: 30 minutes
**Responsible**: Site Owner

**Steps**:

1. **Login to WordPress admin**:
   - Go to: http://aupairhive.com/wp-admin
   - Username: [admin username]
   - Password: [admin password]

2. **Document Divi Theme License**:
   - Go to Divi → Theme Options → Updates
   - Note: License Key, Username, API Key
   ```
   Divi Theme License
   ---
   License Key: ______________________________
   Username: ______________________________
   Purchase Email: ______________________________
   License Type: Developer/Personal/Lifetime
   Download URL: https://www.elegantthemes.com/members-area/
   ```

3. **Document Gravity Forms License**:
   - Go to Forms → Settings → License
   - Note: License Key
   ```
   Gravity Forms License
   ---
   License Key: ______________________________
   Purchase Email: ______________________________
   License Type: Basic/Pro/Elite
   Download URL: https://www.gravityforms.com/my-account/
   ```

4. **Document reCAPTCHA Keys**:
   - Go to Settings → reCAPTCHA (or check Gravity Forms → Settings → reCAPTCHA)
   - Note: Site Key and Secret Key
   ```
   Google reCAPTCHA
   ---
   Site Key: ______________________________
   Secret Key: ______________________________
   reCAPTCHA Version: v2 / v3
   Dashboard: https://www.google.com/recaptcha/admin
   ```

5. **Document Facebook Pixel**:
   - View page source of any page
   - Search for "fbq" or "Facebook Pixel"
   - Note: Pixel ID
   ```
   Facebook Pixel
   ---
   Pixel ID: ______________________________
   Dashboard: https://business.facebook.com/events_manager
   ```

6. **Document other integrations** (if any):
   - Analytics (Google Analytics ID)
   - Email services (SMTP settings)
   - Social media connections
   - Payment gateways

7. **Save to file**: `licenses_and_keys.txt`

**Troubleshooting**:
- **Issue**: Cannot find license keys
  - **Solution**: Check plugin settings pages, or retrieve from purchase emails

- **Issue**: License keys expired or invalid
  - **Solution**: Contact vendor support to renew before migration

**Verification**:
- [ ] Divi license key documented
- [ ] Gravity Forms license key documented
- [ ] reCAPTCHA keys documented
- [ ] Facebook Pixel ID documented
- [ ] All credentials saved to licenses_and_keys.txt

---

### Task 2.5: Take Baseline Screenshots

**Duration**: 30 minutes
**Responsible**: Site Owner or QA

**Steps**:

1. **Create screenshots folder**: `AuPairHive_Backup/screenshots/`

2. **Screenshot homepage**:
   - Desktop view (1920x1080)
   - Filename: `01_homepage_desktop.png`
   - Mobile view (use browser DevTools to simulate iPhone)
   - Filename: `02_homepage_mobile.png`

3. **Screenshot key pages**:
   - `03_about_page.png`
   - `04_services_page.png`
   - `05_blog_listing.png`
   - `06_blog_post_sample.png`
   - `07_contact_page.png`

4. **Screenshot forms**:
   - `08_family_application_form.png`
   - `09_aupair_application_form.png`
   - `10_contact_form.png`

5. **Screenshot WordPress admin**:
   - `11_wp_admin_dashboard.png`
   - `12_wp_admin_posts.png`
   - `13_wp_admin_plugins.png`

6. **Document current performance**:
   - Run GTmetrix test: https://gtmetrix.com
   - Save report PDF
   - Note: Page load time, TTFB, Performance score
   ```
   Baseline Performance (Xneelo)
   ---
   Homepage Load Time: _____ seconds
   Time to First Byte (TTFB): _____ seconds
   GTmetrix Performance Score: _____
   GTmetrix Structure Score: _____
   Page Size: _____ MB
   Requests: _____
   ```

**Verification**:
- [ ] At least 10 screenshots taken
- [ ] Screenshots cover homepage, key pages, forms, admin
- [ ] GTmetrix performance baseline documented
- [ ] All screenshots saved to screenshots/ folder

---

### Task 2.6: Document Current Configuration

**Duration**: 30 minutes
**Responsible**: Technical Lead

**Steps**:

1. **Create configuration document**: `current_configuration.txt`

2. **WordPress version and settings**:
```
WordPress Configuration
---
WordPress Version: _____ (check wp-admin → Dashboard → Updates)
PHP Version: _____ (check cPanel → PHP Version or Site Health)
MySQL Version: _____ (check phpMyAdmin → Server info)
Site URL: http://aupairhive.com
Home URL: http://aupairhive.com
Permalink Structure: _____ (Settings → Permalinks)
```

3. **Active plugins list**:
   - Go to wp-admin → Plugins
   - List all active plugins with versions:
   ```
   Active Plugins
   ---
   1. Divi Builder - 4.18.0
   2. Gravity Forms - 2.x.x
   3. Cookie Law Info - x.x.x
   4. [etc...]
   ```

4. **Active theme**:
   ```
   Active Theme
   ---
   Theme Name: Divi
   Version: 4.18.0
   Author: Elegant Themes
   Parent Theme: None (or specify if child theme)
   ```

5. **Server settings**:
   - Check wp-admin → Site Health → Info → Server
   ```
   Server Settings
   ---
   PHP Memory Limit: _____
   Max Upload Size: _____
   Max Execution Time: _____
   Post Max Size: _____
   ```

6. **DNS settings** (for reference):
   - Use `dig aupairhive.com` or online DNS lookup tool
   - Document current A record, CNAME, MX records

**Verification**:
- [ ] WordPress version documented
- [ ] All plugins listed with versions
- [ ] Theme details documented
- [ ] Server settings documented
- [ ] Current DNS records documented

---

### Task 2.7: Organize and Verify Backup Package

**Duration**: 30 minutes
**Responsible**: Technical Lead

**Steps**:

1. **Create backup folder structure**:
```
AuPairHive_Backup/
├── aupairhive_database_20260109.sql
├── aupairhive_files_20260109.zip
├── database_info.txt
├── licenses_and_keys.txt
├── current_configuration.txt
├── baseline_performance.txt
├── screenshots/
│   ├── 01_homepage_desktop.png
│   ├── 02_homepage_mobile.png
│   └── [etc...]
└── README.txt
```

2. **Create README.txt**:
```
Au Pair Hive - Xneelo Backup
Export Date: 2026-01-09
Exported By: [Your Name]

Contents:
- aupairhive_database_20260109.sql: Full WordPress database export
- aupairhive_files_20260109.zip: Complete WordPress file archive
- database_info.txt: Database configuration details
- licenses_and_keys.txt: Premium licenses and API keys
- current_configuration.txt: WordPress settings and plugins
- baseline_performance.txt: Performance metrics
- screenshots/: Visual baseline for comparison

Next Steps:
1. Verify all files are present and not corrupted
2. Proceed to Phase 3: DEV Environment Provisioning
3. Keep this backup safe until migration is complete and verified
```

3. **Verify all files present**:
   - [ ] Database SQL file
   - [ ] Files ZIP archive
   - [ ] All documentation files
   - [ ] Screenshots folder with images
   - [ ] README.txt

4. **Verify file integrity**:
   ```bash
   # Check SQL file
   head -n 20 aupairhive_database_20260109.sql
   
   # Check ZIP archive
   unzip -t aupairhive_files_20260109.zip | tail
   
   # Verify file sizes are reasonable
   ls -lh
   ```

5. **Create backup checksum** (for integrity verification):
   ```bash
   # On Mac/Linux
   md5 aupairhive_database_20260109.sql > checksums.txt
   md5 aupairhive_files_20260109.zip >> checksums.txt
   
   # On Windows
   certutil -hashfile aupairhive_database_20260109.sql MD5
   ```

6. **Create backup copy**:
   - Copy entire `AuPairHive_Backup/` folder to external drive or cloud storage
   - Label: "Au Pair Hive Backup - 2026-01-09 - DO NOT DELETE"

**Verification**:
- [ ] All required files present in backup folder
- [ ] File integrity verified (no corruption)
- [ ] Checksums generated
- [ ] Backup copy created in safe location
- [ ] Total backup size: ________ GB

---

## Verification Checklist

### Data Export
- [ ] WordPress database exported successfully
- [ ] Database file size is reasonable (1-5 MB)
- [ ] Database contains all tables (12-20 expected)
- [ ] WordPress files downloaded (zip archive)
- [ ] Files archive extracts successfully
- [ ] All WordPress directories present (wp-admin, wp-content, wp-includes)

### Documentation
- [ ] Database information documented
- [ ] Divi license key documented
- [ ] Gravity Forms license key documented
- [ ] reCAPTCHA keys documented
- [ ] Facebook Pixel ID documented
- [ ] Current configuration documented
- [ ] Active plugins list complete
- [ ] Server settings documented

### Quality Assurance
- [ ] Baseline screenshots taken (10+ images)
- [ ] Performance baseline documented (GTmetrix)
- [ ] Backup folder organized
- [ ] README created
- [ ] File checksums generated
- [ ] Backup copy created in safe location

### Readiness
- [ ] All files verified as not corrupted
- [ ] Total backup size documented
- [ ] Export completion date documented
- [ ] Ready to proceed to Phase 3

---

## Rollback Procedure

**This phase is export-only** - no changes to production site.

If export fails or is incomplete:
1. Repeat the failed task
2. Try alternative method (e.g., FTP instead of File Manager)
3. Contact Xneelo support if server issues
4. Do not proceed to Phase 3 until complete backup verified

---

## Success Criteria

- [ ] Complete WordPress database exported and verified
- [ ] All WordPress files downloaded and verified
- [ ] All licenses and API keys documented
- [ ] Baseline screenshots and performance metrics captured
- [ ] Current configuration fully documented
- [ ] Backup package organized and verified
- [ ] Backup integrity confirmed (no corruption)
- [ ] Backup copy stored safely
- [ ] Ready to import to DEV environment

**Definition of Done**:
Backup folder contains all required files, all files verified as not corrupted, documentation complete, and backup copy stored safely.

---

## Sign-Off

**Completed By**: _________________ Date: _________
**Verified By**: _________________ Date: _________
**Backup Size**: _________ GB
**Files Exported**: Database: ✅  Files: ✅  Docs: ✅  Screenshots: ✅
**Ready for Phase 3**: [ ] YES [ ] NO

---

## Notes and Observations

[Space for team to document findings]

**Issues Encountered**:
-
-

**Time Taken** (vs estimated 1.5 days):
- Actual: _____ hours
- Variance: _____

**Recommendations**:
-
-

---

**Next Phase**: Proceed to **Phase 3**: `03_DEV_Environment_Provisioning.md`
