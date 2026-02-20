# Xneelo Export Instructions for Au Pair Hive
## Complete WordPress Site Backup Guide

**Site**: aupairhive.com
**Platform**: Xneelo Shared Hosting
**Estimated Time**: 30-45 minutes
**Date**: 2026-01-09

---

## Prerequisites

Before you begin, ensure you have:
- [x] Xneelo cPanel login credentials
- [x] Sufficient disk space on your local computer (at least 5 GB free)
- [x] Stable internet connection
- [x] Note-taking tool for documenting settings

---

## Method 1: Complete Export via cPanel (RECOMMENDED)

This is the most comprehensive and reliable method.

### Step 1: Login to Xneelo cPanel

1. Go to your Xneelo control panel login page
   - Usually: https://www.xneelo.co.za/cpanel or via your hosting dashboard
2. Enter your cPanel username and password
3. Navigate to the main cPanel dashboard

### Step 2: Export WordPress Database

**2.1 Access phpMyAdmin**
1. In cPanel, scroll to the **"Databases"** section
2. Click on **"phpMyAdmin"**
3. phpMyAdmin will open in a new window/tab

**2.2 Select Your Database**
1. In the left sidebar, look for your WordPress database
   - Usually named something like: `username_wp123` or `username_wordpress`
   - If multiple databases exist, check your wp-config.php to confirm the correct one
2. Click on the database name to select it

**2.3 Export Database**
1. Click the **"Export"** tab at the top
2. Select **"Custom"** export method (not Quick)
3. Configure export settings:
   - **Format**: SQL
   - **Tables**: Select all tables (should all be checked)
   - **Output**: Save output to a file
   - **Format-specific options**:
     - ✅ Add DROP TABLE / VIEW / PROCEDURE / FUNCTION / EVENT / TRIGGER statement
     - ✅ Add CREATE TABLE statement
     - ✅ Enclose table and column names with backquotes
   - **Data dump options**:
     - ✅ Complete inserts
     - ✅ Extended inserts
   - **Compression**: None (or gzip if file is very large >100MB)
4. Click **"Go"** button at the bottom
5. Save the file to your computer as: `aupairhive_database_YYYYMMDD.sql`
   - Example: `aupairhive_database_20260109.sql`
6. **VERIFY**: Check the file size - should be at least a few MB

**2.4 Document Database Information**
Create a text file `database_info.txt` with:
```
Database Name: [your_database_name]
Database User: [your_database_user]
Database Host: localhost
Character Set: utf8mb4
Collation: utf8mb4_unicode_ci
Export Date: 2026-01-09
File Name: aupairhive_database_20260109.sql
File Size: [size in MB]
```

### Step 3: Export WordPress Files

You have two options: File Manager (easier) or FTP (more reliable for large sites)

#### Option A: Using cPanel File Manager (Recommended for beginners)

**3.1 Access File Manager**
1. Return to cPanel main dashboard
2. In the **"Files"** section, click **"File Manager"**
3. File Manager will open in a new window

**3.2 Navigate to WordPress Directory**
1. In the left sidebar, navigate to your WordPress installation
   - Usually: `/public_html/` or `/public_html/aupairhive.com/`
   - Look for files like `wp-config.php`, `wp-content/`, `wp-admin/`
2. If WordPress is in a subdirectory, navigate to it

**3.3 Create Archive**
1. Select the WordPress root folder (or select all files/folders in it)
   - Important files/folders to include:
     - `wp-admin/`
     - `wp-content/` (CRITICAL - contains themes, plugins, uploads)
     - `wp-includes/`
     - `wp-config.php` (CRITICAL - for reference)
     - `.htaccess` (if present)
     - All other WordPress core files
2. Click **"Compress"** in the top toolbar
3. Choose compression type:
   - **Zip Archive** (recommended, works on all systems)
   - Alternative: Tar.gz (smaller but may need special tools to extract)
4. Name the archive: `aupairhive_files_20260109.zip`
5. Click **"Compress File(s)"**
6. Wait for compression to complete (may take 5-15 minutes for large sites)

**3.4 Download Archive**
1. Once compression is complete, find the `.zip` file in File Manager
2. Right-click (or select) the archive file
3. Click **"Download"**
4. Save to your computer in a dedicated folder (e.g., `AuPairHive_Backup/`)
5. **VERIFY**: Check the downloaded file size matches what's shown in File Manager
6. **VERIFY**: Extract a small portion to test the archive is not corrupted

**3.5 Cleanup (Optional)**
1. After successful download and verification
2. Delete the archive from the server to free up space
3. Right-click the .zip file → Delete

#### Option B: Using FTP (Recommended for large sites or slow cPanel)

**3.1 Get FTP Credentials**
1. In cPanel, go to **"Files"** → **"FTP Accounts"**
2. Find your main FTP account or create a new one
3. Note down:
   - FTP Server/Host: `ftp.aupairhive.com` or IP address
   - FTP Username: Usually your cPanel username
   - FTP Password: Your cPanel password or specific FTP password
   - Port: 21 (standard FTP) or 22 (SFTP/SSH)

**3.2 Install FTP Client**
Download and install one of these free FTP clients:
- **FileZilla** (recommended): https://filezilla-project.org/
- **WinSCP** (Windows): https://winscp.net/
- **Cyberduck** (Mac/Windows): https://cyberduck.io/

**3.3 Connect to Server**
1. Open your FTP client
2. Enter connection details:
   - Host: ftp.aupairhive.com
   - Username: [your FTP username]
   - Password: [your FTP password]
   - Port: 21
3. Click **"Connect"** or **"Quickconnect"**

**3.4 Download WordPress Files**
1. In the FTP client, navigate to your WordPress directory
   - Remote side (server): `/public_html/` or `/public_html/aupairhive.com/`
2. On your local computer, create a folder: `AuPairHive_Backup/files/`
3. Select all WordPress files and folders on the server
4. Right-click → **"Download"** (or drag to local folder)
5. Wait for download to complete (may take 30-60 minutes depending on size)
6. **VERIFY**: Check file count and total size match between local and remote

**3.5 Compress Files Locally (Optional)**
1. After download, zip the files on your local computer
2. This makes them easier to upload to AWS later
3. Create: `aupairhive_files_20260109.zip`

### Step 4: Export Additional Data

**4.1 Gravity Forms Entries (If Applicable)**
1. Login to WordPress admin: http://aupairhive.com/wp-admin
2. Go to **Forms** → **Import/Export**
3. Select all forms
4. Click **"Export"**
5. Save the export file: `aupairhive_gravity_forms_20260109.json`

**4.2 Document Plugin Licenses & API Keys**
Create a file: `licenses_and_keys.txt`

```
=== PREMIUM THEME/PLUGIN LICENSES ===

Divi Theme:
- License Key: [YOUR_LICENSE_KEY]
- Purchase Email: [email]
- License Type: Developer/Personal/Lifetime
- Download URL: https://www.elegantthemes.com/members-area/

Gravity Forms:
- License Key: [YOUR_LICENSE_KEY]
- Purchase Email: [email]
- License Type: Basic/Pro/Elite
- Download URL: https://www.gravityforms.com/my-account/

=== API KEYS & INTEGRATIONS ===

Google reCAPTCHA:
- Site Key: [found in plugin settings]
- Secret Key: [found in plugin settings]
- Dashboard: https://www.google.com/recaptcha/admin

Facebook Pixel:
- Pixel ID: [found in theme/plugin settings]
- Dashboard: https://business.facebook.com/

=== SMTP/EMAIL SETTINGS ===
[If using WP Mail SMTP or similar]
- SMTP Host: [host]
- SMTP Port: [port]
- Username: [username]
- Password: [password] (DO NOT share this publicly)

=== OTHER INTEGRATIONS ===
[List any other integrations, API keys, or service connections]
```

**4.3 Screenshot Current Site**
1. Take screenshots of:
   - Homepage (desktop view)
   - Homepage (mobile view - use browser dev tools)
   - Key pages (About, Services, Contact)
   - Blog listing page
   - Sample blog post
   - Contact form
   - WordPress admin dashboard
2. Save as: `aupairhive_screenshots_[date]/`
3. These help verify the migrated site looks identical

**4.4 Export WordPress Settings (Advanced)**
1. In WordPress admin, go to **Tools** → **Export**
2. Select **"All content"**
3. Click **"Download Export File"**
4. Save as: `aupairhive_wp_export_20260109.xml`
5. This is a backup export in WordPress format (useful for content-only migration if needed)

### Step 5: Document Current Configuration

Create a file: `current_configuration.txt`

```
=== WORDPRESS CONFIGURATION ===
WordPress Version: [check in wp-admin → Updates]
PHP Version: [check in cPanel or wp-admin → Site Health]
MySQL Version: [check in phpMyAdmin]
Active Theme: Divi [version]
Site URL: http://aupairhive.com
Home URL: http://aupairhive.com

=== ACTIVE PLUGINS ===
[Go to Plugins → Installed Plugins and list all active ones with versions]
1. Gravity Forms - 2.x.x
2. Cookie Law Info - x.x.x
3. [etc.]

=== SERVER SETTINGS ===
PHP Memory Limit: [check wp-admin → Site Health → Info → Server]
Max Upload Size: [check Media → Add New]
Max Execution Time: [check Site Health]
Post Max Size: [check Site Health]

=== CURRENT PERFORMANCE ===
Homepage Load Time: [use gtmetrix.com or similar]
Database Size: [check in phpMyAdmin]
Total Files Size: [check in cPanel → Disk Usage]

=== DNS SETTINGS ===
[Go to your domain registrar and document current DNS records]
- A Record: [IP address]
- CNAME Records: [list all]
- MX Records: [mail server records]
- TXT Records: [SPF, DKIM, etc.]
- Nameservers: [current nameservers]
```

---

## Method 2: All-in-One Backup Plugin (ALTERNATIVE)

If you prefer a simpler approach using a plugin:

### Using UpdraftPlus (Free Plugin)

**Note**: This requires installing a plugin on your live site.

1. Login to WordPress admin
2. Go to **Plugins** → **Add New**
3. Search for **"UpdraftPlus"**
4. Install and activate UpdraftPlus WordPress Backup Plugin
5. Go to **Settings** → **UpdraftPlus Backups**
6. Click **"Backup Now"**
7. Check both boxes:
   - ✅ Include database in backup
   - ✅ Include files in backup
8. Click **"Backup Now"**
9. Wait for backup to complete (5-30 minutes)
10. Once complete, click **"Existing Backups"** tab
11. Download all backup files:
    - Database backup (.gz)
    - Plugins backup (.zip)
    - Themes backup (.zip)
    - Uploads backup (.zip)
    - Others backup (.zip)
12. Save all files to your computer

**Advantages**: Easy, all-in-one, includes restore functionality
**Disadvantages**: Requires installing plugin, may timeout on large sites

---

## Verification Checklist

Before considering your export complete, verify:

- [ ] Database SQL file downloaded and file size >1 MB
- [ ] WordPress files downloaded (via zip or FTP)
- [ ] wp-config.php included in backup (verify database credentials)
- [ ] wp-content folder included (themes, plugins, uploads)
- [ ] Gravity Forms entries exported (if applicable)
- [ ] Premium plugin/theme licenses documented
- [ ] API keys documented (reCAPTCHA, Facebook Pixel)
- [ ] Screenshots taken of current site
- [ ] Current configuration documented
- [ ] DNS settings documented
- [ ] All files stored in organized folder structure:
  ```
  AuPairHive_Backup/
  ├── aupairhive_database_20260109.sql
  ├── aupairhive_files_20260109.zip
  ├── aupairhive_gravity_forms_20260109.json
  ├── database_info.txt
  ├── licenses_and_keys.txt
  ├── current_configuration.txt
  ├── screenshots/
  │   ├── homepage_desktop.png
  │   ├── homepage_mobile.png
  │   └── [other screenshots]
  └── README.txt (this file)
  ```

---

## Testing Your Backup

**Test Database Export**:
1. Open the .sql file in a text editor (Notepad++, VS Code, etc.)
2. Check first few lines - should see:
   ```sql
   -- MySQL dump
   -- Host: localhost
   -- Database: your_database_name
   ```
3. Search for "wp_posts" - should find `CREATE TABLE` statements
4. File should NOT be empty or corrupted

**Test File Archive**:
1. Extract the zip file to a temporary folder
2. Verify folder structure looks correct:
   - wp-admin/
   - wp-content/
   - wp-includes/
   - wp-config.php
3. Check wp-content/uploads/ has your images
4. Check wp-content/themes/Divi/ exists
5. Check wp-content/plugins/ has all plugins

---

## Common Issues & Solutions

### Issue: phpMyAdmin times out during export
**Solution**:
- Use "Quick" export instead of "Custom"
- Export tables in smaller batches
- Ask Xneelo support to increase timeout limits
- Use WP-CLI via SSH if available: `wp db export backup.sql`

### Issue: File Manager compression fails
**Solution**:
- Try compressing smaller folders separately (wp-content, wp-admin, etc.)
- Use FTP method instead
- Ask Xneelo support for assistance

### Issue: Download fails or is corrupted
**Solution**:
- Try downloading again
- Use FTP for more reliable downloads
- Check your internet connection stability
- Download during off-peak hours

### Issue: Can't find database name
**Solution**:
- Check wp-config.php in File Manager
- Look for line: `define('DB_NAME', 'database_name');`
- Or ask Xneelo support

### Issue: Don't have cPanel access
**Solution**:
- Contact Xneelo support to provide credentials
- Or ask them to create a full backup for you

---

## Security Reminders

⚠️ **IMPORTANT SECURITY NOTES**:

1. **wp-config.php contains sensitive data**:
   - Database passwords
   - Security salts
   - Don't share this file publicly

2. **Store backups securely**:
   - Don't upload to public cloud storage without encryption
   - Use password-protected archives for sensitive data
   - Delete backups from Xneelo server after download

3. **API keys and licenses**:
   - Treat these as passwords
   - Don't commit to public repositories
   - Share only via secure channels

---

## Next Steps

After completing the export:

1. **Verify all files downloaded successfully**
2. **Organize files in the folder structure shown above**
3. **Share with migration team** (via secure method)
4. **Keep original backup** until migration is confirmed successful (30+ days)
5. **Proceed to DEV environment setup**

---

## Support

If you encounter issues during export:
- **Xneelo Support**: https://xneelo.co.za/help-centre/
- **Migration Team**: [contact information]

---

**Export Status**: PENDING
**Exported By**: [Site Owner Name]
**Export Date**: [Date]
**Verification**: [ ] COMPLETE
