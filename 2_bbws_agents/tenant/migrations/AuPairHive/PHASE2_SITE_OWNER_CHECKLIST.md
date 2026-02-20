# Phase 2: Site Owner Checklist - Xneelo Data Export

**For**: Au Pair Hive Site Owner
**Site**: aupairhive.com
**Date**: 2026-01-09
**Estimated Time**: 4-6 hours (can be spread across multiple sessions)

---

## What You'll Need

Before starting, make sure you have:

- [ ] **Xneelo cPanel credentials** (username and password)
- [ ] **WordPress admin credentials** (wp-admin username and password)
- [ ] **5 GB of free disk space** on your computer
- [ ] **Stable internet connection**
- [ ] **Text editor** (Notepad, TextEdit, or any text editor)
- [ ] **Web browser** (Chrome, Firefox, or Safari)

---

## Quick Start Guide

This phase is about **EXPORTING** data from Xneelo. We're making a complete backup of your website before moving it to AWS. Think of it as packing everything before moving to a new house.

**Important**: This phase does NOT make any changes to your live website. It's 100% safe!

---

## Step-by-Step Tasks

### ☐ STEP 1: Create Local Backup Folder (5 minutes)

1. On your computer, create a new folder called: `AuPairHive_Backup`
2. Inside it, create a subfolder called: `screenshots`
3. Open a text file to take notes

**Location suggestion**:
- Windows: `C:\Users\YourName\Documents\AuPairHive_Backup\`
- Mac: `~/Documents/AuPairHive_Backup/`

---

### ☐ STEP 2: Access Xneelo cPanel (15 minutes)

1. Go to: https://www.xneelo.co.za/cpanel
   - Or check your Xneelo welcome email for the cPanel link

2. Login with your Xneelo credentials:
   - Username: ___________________________
   - Password: ___________________________

3. Once logged in, take a screenshot of the cPanel dashboard
   - Save as: `AuPairHive_Backup/screenshots/00_cpanel_dashboard.png`

4. **Document cPanel details** in a text file (`cpanel_info.txt`):
   ```
   cPanel URL: https://cpanel.xneelo.co.za (or your specific URL)
   Username: ___________________________
   Server: ___________________________ (shown in cPanel header)
   Primary Domain: aupairhive.com
   Access Date: 2026-01-09
   ```

**❓ Troubleshooting**:
- Can't find login URL? → Check Xneelo emails or contact support
- Forgot password? → Use "Forgot Password" link

---

### ☐ STEP 3: Export WordPress Database (1 hour)

**This is the most important step - your website content is in this database!**

1. **Find phpMyAdmin**:
   - In cPanel, scroll to the "Databases" section
   - Click on "phpMyAdmin" icon
   - A new tab opens

2. **Find your database**:
   - Look at the left sidebar for database names
   - It's usually named something like: `username_wp123`
   - **Don't know which one?** → Click "File Manager" in cPanel, go to `public_html/wp-config.php`, look for `DB_NAME`

3. **Export the database**:
   - Click on your database name in the left sidebar
   - Click the "Export" tab at the top
   - Choose **"Custom"** export method (not Quick!)

   **Settings**:
   - Format: SQL
   - Tables: Select All
   - Output: ✅ Save output to a file
   - Format options:
     - ✅ Add DROP TABLE
     - ✅ Add CREATE TABLE
     - ✅ Complete inserts
   - Compression: None (unless database is huge)

4. **Download**:
   - Click "Go" button at bottom
   - Save file as: `aupairhive_database_20260109.sql`
   - Save to: `AuPairHive_Backup/`

5. **Verify download**:
   - Check file size (should be 1-10 MB, not 0 bytes!)
   - Open file in text editor - should see SQL commands like `CREATE TABLE`

6. **Document database info** in `database_info.txt`:
   ```
   Database Name: ___________________________
   Database User: ___________________________
   Table Count: _____ (count in phpMyAdmin left sidebar)
   Export File: aupairhive_database_20260109.sql
   File Size: _____ MB
   Export Date: 2026-01-09
   ```

**✅ Success Check**:
- [ ] SQL file downloaded
- [ ] File size > 0 MB
- [ ] File opens and shows SQL commands

---

### ☐ STEP 4: Download All WordPress Files (2-3 hours)

**Now we need to download all your website files (pages, images, plugins, theme)**

**METHOD A: cPanel File Manager** (Easier):

1. **Access File Manager**:
   - In cPanel → Files section → Click "File Manager"

2. **Navigate to website folder**:
   - Click on `public_html` folder
   - You should see folders like: `wp-admin`, `wp-content`, `wp-includes`

3. **Create ZIP archive**:
   - Click "Select All" at top (selects all files/folders)
   - Click "Compress" button in toolbar
   - Choose "Zip Archive"
   - Name it: `aupairhive_files_20260109.zip`
   - Click "Compress File(s)"
   - **Wait** (this may take 5-15 minutes)

4. **Download the ZIP**:
   - Once compression is done, you'll see the .zip file
   - Right-click on `aupairhive_files_20260109.zip`
   - Select "Download"
   - Save to: `AuPairHive_Backup/`
   - **Wait** (this may take 30-60 minutes depending on size)

5. **Verify download**:
   - Check file size matches what cPanel shows
   - Try to extract/open the ZIP to make sure it's not corrupted

**METHOD B: If File Manager fails** - Use FTP:
- Contact me for FTP instructions if needed

**✅ Success Check**:
- [ ] ZIP file downloaded (size 100-500 MB expected)
- [ ] ZIP file opens/extracts successfully
- [ ] Can see wp-admin, wp-content folders inside

---

### ☐ STEP 5: Document Premium Licenses (30 minutes)

**We need your premium plugin license keys to activate them on the new server**

1. **Login to WordPress Admin**:
   - Go to: http://aupairhive.com/wp-admin
   - Username: ___________________________
   - Password: ___________________________

2. **Get Divi License**:
   - In WordPress admin: Divi → Theme Options → Updates tab
   - Copy the license key
   - Save to `licenses_and_keys.txt`:
   ```
   === DIVI THEME LICENSE ===
   License Key: ________________________________
   Username: ________________________________
   Purchase Email: ________________________________
   Download: https://www.elegantthemes.com/members-area/
   ```

3. **Get Gravity Forms License**:
   - In WordPress admin: Forms → Settings
   - Look for License tab or section
   - Copy the license key
   - Add to `licenses_and_keys.txt`:
   ```
   === GRAVITY FORMS LICENSE ===
   License Key: ________________________________
   Purchase Email: ________________________________
   Download: https://www.gravityforms.com/my-account/
   ```

4. **Get Google reCAPTCHA Keys**:
   - In WordPress admin: Forms → Settings → reCAPTCHA
   - Copy Site Key and Secret Key
   - Add to `licenses_and_keys.txt`:
   ```
   === GOOGLE reCAPTCHA ===
   Site Key: ________________________________
   Secret Key: ________________________________
   Version: v2 / v3
   ```

5. **Get Facebook Pixel ID** (if used):
   - View source of homepage (right-click → View Page Source)
   - Search for "fbq" or look in Divi theme settings
   - Add to `licenses_and_keys.txt`:
   ```
   === FACEBOOK PIXEL ===
   Pixel ID: ________________________________
   ```

**✅ Success Check**:
- [ ] All license keys saved to licenses_and_keys.txt
- [ ] File saved in AuPairHive_Backup folder

---

### ☐ STEP 6: Take Screenshots (30 minutes)

**We need "before" pictures to compare after migration**

Take full-page screenshots of:

1. **Homepage**:
   - Desktop view → Save as: `01_homepage_desktop.png`
   - Mobile view (use browser's mobile simulator) → `02_homepage_mobile.png`

2. **Key Pages**:
   - About page → `03_about.png`
   - Services page → `04_services.png`
   - Blog listing → `05_blog.png`
   - Contact page → `06_contact.png`

3. **Forms** (IMPORTANT!):
   - Family application form → `07_family_form.png`
   - Au Pair application form → `08_aupair_form.png`
   - Contact form → `09_contact_form.png`

4. **WordPress Admin**:
   - Dashboard → `10_admin_dashboard.png`
   - Plugins page → `11_admin_plugins.png`

**Save all to**: `AuPairHive_Backup/screenshots/`

**✅ Success Check**:
- [ ] At least 10 screenshots saved
- [ ] All forms screenshots captured

---

### ☐ STEP 7: Test Site Performance (15 minutes)

**Measure current performance to compare after migration**

1. Go to: https://gtmetrix.com
2. Enter: aupairhive.com
3. Click "Test your site"
4. Wait for results
5. Click "Download PDF Report"
6. Save as: `AuPairHive_Backup/gtmetrix_baseline.pdf`

7. Document in `baseline_performance.txt`:
   ```
   Current Performance (Xneelo)
   ---
   Homepage Load Time: _____ seconds
   Performance Score: _____ %
   Page Size: _____ MB
   Test Date: 2026-01-09
   ```

**✅ Success Check**:
- [ ] GTmetrix PDF saved
- [ ] Performance numbers documented

---

### ☐ STEP 8: Document Configuration (15 minutes)

Create file: `current_configuration.txt`

1. **WordPress Version**:
   - Go to: wp-admin → Dashboard → Updates
   - Document version number

2. **Plugin List**:
   - Go to: wp-admin → Plugins
   - List all ACTIVE plugins with version numbers

3. **Permalink Structure**:
   - Go to: wp-admin → Settings → Permalinks
   - Note which option is selected

Add all to `current_configuration.txt`:
```
WordPress Version: _____
PHP Version: _____ (check cPanel or Site Health)
Permalink Structure: _____

Active Plugins:
1. Divi Builder - version _____
2. Gravity Forms - version _____
3. [list all active plugins]
```

**✅ Success Check**:
- [ ] Configuration file created
- [ ] All plugins listed

---

### ☐ STEP 9: Final Verification (30 minutes)

**Make sure everything is backed up correctly!**

Check your `AuPairHive_Backup` folder contains:

```
AuPairHive_Backup/
├── aupairhive_database_20260109.sql ✅
├── aupairhive_files_20260109.zip ✅
├── cpanel_info.txt ✅
├── database_info.txt ✅
├── licenses_and_keys.txt ✅
├── current_configuration.txt ✅
├── baseline_performance.txt ✅
├── gtmetrix_baseline.pdf ✅
└── screenshots/ (10+ images) ✅
```

**File size check**:
- Database SQL: 1-10 MB ✅
- Files ZIP: 100-500 MB ✅
- Total backup: _____ GB

**Integrity check**:
- [ ] SQL file opens in text editor and shows SQL commands
- [ ] ZIP file can be extracted/opened
- [ ] All text files contain data (not empty)
- [ ] All screenshots are viewable

---

## ✅ PHASE 2 COMPLETE!

Once all checkboxes above are ticked, you're done with Phase 2!

**Next Steps**:
1. **Create a backup copy** of the entire `AuPairHive_Backup` folder
   - Copy to external hard drive OR
   - Upload to Google Drive / Dropbox
   - **Label it**: "Au Pair Hive Backup 2026-01-09 - DO NOT DELETE"

2. **Notify the technical team** that export is complete

3. **Share the backup folder** with the technical team:
   - Option A: Share Google Drive / Dropbox link
   - Option B: Provide access to external drive
   - Option C: Upload to provided secure location

---

## Need Help?

**If you get stuck**:
- Take a screenshot of the issue
- Note which step number you're on
- Contact the technical team

**Common Issues**:
- "Export times out" → Try Quick export instead of Custom
- "Download fails" → Try again or use FTP method
- "Can't find license key" → Check purchase emails or vendor account

---

## Time Tracking

**Actual time taken**:
- Started: _____ (date/time)
- Completed: _____ (date/time)
- Total hours: _____ hours

**Notes**:
(Write any issues, challenges, or observations here)

---

**Great job! This is a critical milestone in the migration. Your website data is now safely backed up and ready to move to the new AWS platform!** 🎉
