# WordPress Export Script - Setup & Execution Guide

This guide shows you how to set up and run the `wordpress-xneelo-export.sh` script on your local machine or server to export WordPress sites from Xneelo.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Method 1: Download from GitHub/Repository](#method-1-download-from-githubrepository)
- [Method 2: Create Script Manually](#method-2-create-script-manually)
- [Method 3: Upload via SCP](#method-3-upload-via-scp)
- [SSH Key Setup (Recommended)](#ssh-key-setup-recommended)
- [Running the Script](#running-the-script)
- [Complete Examples](#complete-examples)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

### On Your Local Machine (Where You'll Run the Script)
```bash
# Check that you have required tools
which ssh      # Should return a path
which scp      # Should return a path
which rsync    # Should return a path

# If any are missing on macOS:
brew install rsync

# If any are missing on Linux:
sudo apt-get install rsync openssh-client  # Ubuntu/Debian
sudo yum install rsync openssh-clients     # CentOS/RHEL
```

### On Xneelo Server (Remote Server)
- SSH access enabled (port 2222)
- mysqldump available
- tar available
- WordPress installation in public_html or httpdocs

---

## Method 1: Download from GitHub/Repository

### If Script is in a Git Repository

```bash
# Clone the repository
git clone <repository-url>
cd file_transfer

# Make script executable
chmod +x wordpress-xneelo-export.sh

# Verify script is ready
./wordpress-xneelo-export.sh --help
```

---

## Method 2: Create Script Manually

### Step 1: Create the Script File

```bash
# Create a working directory
mkdir -p ~/wordpress-exports
cd ~/wordpress-exports

# Create the script file
nano wordpress-xneelo-export.sh
# or use vim:
# vim wordpress-xneelo-export.sh
# or use any text editor
```

### Step 2: Copy Script Content

**Option A: Download directly from source**
```bash
# If you have the script available at a URL
curl -o wordpress-xneelo-export.sh https://your-repo-url/wordpress-xneelo-export.sh

# Or using wget
wget -O wordpress-xneelo-export.sh https://your-repo-url/wordpress-xneelo-export.sh
```

**Option B: Paste content manually**
1. Open the script file in your editor
2. Copy the entire content from `wordpress-xneelo-export.sh`
3. Paste into the editor
4. Save the file:
   - In nano: Press `Ctrl+X`, then `Y`, then `Enter`
   - In vim: Press `Esc`, type `:wq`, press `Enter`

### Step 3: Make Script Executable

```bash
chmod +x wordpress-xneelo-export.sh
```

### Step 4: Verify Script Works

```bash
# Test the script help function
./wordpress-xneelo-export.sh --help

# You should see the help message with usage instructions
```

---

## Method 3: Upload via SCP

### If You Have the Script on Your Local Machine

```bash
# Upload script to your server
scp wordpress-xneelo-export.sh user@your-server.com:~/

# SSH into your server
ssh user@your-server.com

# Make it executable
chmod +x wordpress-xneelo-export.sh

# Verify
./wordpress-xneelo-export.sh --help
```

---

## SSH Key Setup (Recommended)

**Setting up SSH key authentication avoids password prompts during export.**

### Step 1: Generate SSH Key (if you don't have one)

```bash
# Generate SSH key on your local machine
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"

# Press Enter to accept default location (~/.ssh/id_rsa)
# Enter a passphrase (optional but recommended)
```

### Step 2: Copy SSH Key to Xneelo Server

```bash
# Copy your public key to Xneelo server
ssh-copy-id -p 2222 username@servername.xneelo.co.za

# Or if you know the server IP:
ssh-copy-id -p 2222 aupaiqzaea@197.221.10.19

# Enter your password when prompted
```

**Manual Method (if ssh-copy-id doesn't work):**
```bash
# Display your public key
cat ~/.ssh/id_rsa.pub

# SSH into Xneelo server
ssh -p 2222 username@servername.xneelo.co.za

# On Xneelo server, add the key
mkdir -p ~/.ssh
chmod 700 ~/.ssh
nano ~/.ssh/authorized_keys
# Paste your public key, save and exit

# Set correct permissions
chmod 600 ~/.ssh/authorized_keys
exit
```

### Step 3: Test SSH Connection

```bash
# Test connection (should NOT ask for password)
ssh -p 2222 username@servername.xneelo.co.za

# If successful, you should be logged in without password prompt
exit
```

---

## Running the Script

### Basic Command Structure

```bash
./wordpress-xneelo-export.sh -w <website-name> -u <ssh-username> [OPTIONS]
```

### Required Parameters
- `-w` or `--website-name`: Name of the website (used for local directory)
- `-u` or `--ssh-user`: SSH username for Xneelo server

### Optional Parameters
- `-h` or `--ssh-host`: Server hostname/IP (default: 197.221.10.19)
- `-p` or `--ssh-port`: SSH port (default: 2222)
- `-r` or `--wp-root`: WordPress root path (default: auto-detect)
- `--skip-cleanup`: Keep export files on server
- `--rsync-only`: Skip tar archive, only use rsync
- `--help`: Show help message

---

## Complete Examples

### Example 1: Basic Export with Default Settings

```bash
# Export WordPress site "mywebsite" from default Xneelo server
./wordpress-xneelo-export.sh -w mywebsite -u aupaiqzaea

# What happens:
# 1. Connects to 197.221.10.19:2222 as aupaiqzaea
# 2. Auto-detects WordPress root (public_html or httpdocs)
# 3. Exports database and files
# 4. Downloads to exports/mywebsite/
# 5. Cleans up server files
```

### Example 2: Export from Specific Xneelo Server

```bash
# If your site is on a different Xneelo server
./wordpress-xneelo-export.sh -w clientsite -u manufkcxqw -h 197.221.12.211

# Specifying server IP explicitly
```

### Example 3: Export with Custom WordPress Path

```bash
# If WordPress is in a subdirectory
./wordpress-xneelo-export.sh -w mysite -u username -r public_html/blog

# Or for subdomain setup
./wordpress-xneelo-export.sh -w mysite -u username -r public_html/subdomain
```

### Example 4: Export Without Server Cleanup (Debugging)

```bash
# Keep export files on server for verification
./wordpress-xneelo-export.sh -w mysite -u username --skip-cleanup

# Useful when:
# - Testing the export process
# - Want to verify files on server
# - Planning to download again later
```

### Example 5: Fast Export (Rsync Only)

```bash
# Skip tar archive creation for faster export
./wordpress-xneelo-export.sh -w largesite -u username --rsync-only

# Benefits:
# - Faster for large sites
# - Skips compression step
# - Still gets all files via rsync
```

### Example 6: Complete Export with All Options

```bash
./wordpress-xneelo-export.sh \
  -w "production-site" \
  -u "aupaiqzaea" \
  -h "197.221.10.19" \
  -p 2222 \
  -r "public_html" \
  --skip-cleanup
```

---

## Step-by-Step First Run

### Complete First-Time Setup and Execution

```bash
# Step 1: Navigate to your working directory
cd ~/wordpress-exports

# Step 2: Verify script is executable
ls -lah wordpress-xneelo-export.sh
# Should show: -rwxr-xr-x (x indicates executable)

# If not executable:
chmod +x wordpress-xneelo-export.sh

# Step 3: Test SSH connection to Xneelo (optional but recommended)
ssh -p 2222 aupaiqzaea@197.221.10.19
# Verify you can connect, then exit

# Step 4: Run the export
./wordpress-xneelo-export.sh -w my-first-export -u aupaiqzaea

# Step 5: Watch the progress
# You'll see color-coded output showing each step:
# - Blue: Section headers
# - Green: Success messages (✓)
# - Yellow: Warnings (⚠)
# - Red: Errors (✗)

# Step 6: Check results
ls -lah exports/my-first-export/
# You should see:
# - wordpress-db-TIMESTAMP.sql
# - wordpress-files-TIMESTAMP.tar.gz
# - CHECKSUMS-TIMESTAMP.txt
# - EXPORT-NOTES-TIMESTAMP.txt
# - public_html/ directory

# Step 7: Verify checksums (optional)
cd exports/my-first-export/
sha256sum -c CHECKSUMS-*.txt
# Should show: OK for each file

# Step 8: Review export notes
cat EXPORT-NOTES-*.txt
# Contains database info, plugins, themes, next steps
```

---

## What Happens During Export

### The Complete Process Flow

```
1. ╔══════════════════════════════════════════╗
   ║  Checking Prerequisites                  ║
   ╚══════════════════════════════════════════╝
   ✓ ssh is available
   ✓ scp is available
   ✓ rsync is available

2. ╔══════════════════════════════════════════╗
   ║  Testing SSH Connection                  ║
   ╚══════════════════════════════════════════╝
   ℹ Connecting to aupaiqzaea@197.221.10.19:2222...
   ✓ SSH connection successful

3. ╔══════════════════════════════════════════╗
   ║  Locating WordPress Installation         ║
   ╚══════════════════════════════════════════╝
   ℹ Auto-detecting WordPress root...
   ℹ Checking ~/public_html...
   ✓ WordPress found at ~/public_html

4. ╔══════════════════════════════════════════╗
   ║  Verifying WordPress Installation        ║
   ╚══════════════════════════════════════════╝
   ✓ wp-config.php found
   ✓ wp-content directory found

5. ╔══════════════════════════════════════════╗
   ║  Extracting Database Credentials         ║
   ╚══════════════════════════════════════════╝
   ✓ Database: wordpress_db
   ✓ User: wp_user
   ✓ Host: localhost

6. ╔══════════════════════════════════════════╗
   ║  Exporting Database                      ║
   ╚══════════════════════════════════════════╝
   ℹ Exporting database to ~/wordpress-db-20260113_120000.sql...
   ✓ Database exported successfully (15M)

7. ╔══════════════════════════════════════════╗
   ║  Creating File Archive                   ║
   ╚══════════════════════════════════════════╝
   ℹ Creating archive ~/wordpress-files-20260113_120000.tar.gz...
   ⚠ This may take several minutes for large sites...
   ✓ Archive created successfully (450M)

8. ╔══════════════════════════════════════════╗
   ║  Collecting Environment Information      ║
   ╚══════════════════════════════════════════╝
   ✓ Export notes created: EXPORT-NOTES-20260113_120000.txt

9. ╔══════════════════════════════════════════╗
   ║  Generating Checksums                    ║
   ╚══════════════════════════════════════════╝
   ✓ Checksums generated: CHECKSUMS-20260113_120000.txt

10. ╔═════════════════════════════════════════╗
    ║  Synchronizing WordPress Files          ║
    ╚═════════════════════════════════════════╝
    ℹ Syncing files to exports/mywebsite/public_html/...
    [rsync progress bars showing file transfers]
    ✓ Files synchronized successfully

11. ╔═════════════════════════════════════════╗
    ║  Downloading Export Files               ║
    ╚═════════════════════════════════════════╝
    ℹ Downloading database export...
    ✓ Database downloaded
    ℹ Downloading file archive...
    ✓ Archive downloaded
    ℹ Downloading checksums...
    ✓ Checksums downloaded
    ℹ Downloading export notes...
    ✓ Export notes downloaded

12. ╔═════════════════════════════════════════╗
    ║  Verifying Downloads                    ║
    ╚═════════════════════════════════════════╝
    ✓ Database file present (15M)
    ✓ Archive file present (450M)
    ✓ Checksum file present
    ✓ Export notes present
    ✓ WordPress files present in public_html/
    ✓ All downloads verified successfully

13. ╔═════════════════════════════════════════╗
    ║  Cleaning Up Server                     ║
    ╚═════════════════════════════════════════╝
    ℹ Removing export files from server...
    ✓ Server cleanup completed

════════════════════════════════════════════════════════
  WordPress Export Successful!
════════════════════════════════════════════════════════

Website: mywebsite
Export Directory: exports/mywebsite

Files Created:
  • Database: wordpress-db-20260113_120000.sql
  • Archive: wordpress-files-20260113_120000.tar.gz
  • Checksums: CHECKSUMS-20260113_120000.txt
  • Export Notes: EXPORT-NOTES-20260113_120000.txt
  • WordPress Files: public_html/

Next Steps:
  1. Review export notes: exports/mywebsite/EXPORT-NOTES-20260113_120000.txt
  2. Verify checksums: cd exports/mywebsite && sha256sum -c CHECKSUMS-20260113_120000.txt
  3. Prepare AWS environment
  4. Import database to AWS MySQL
  5. Upload files to AWS web server
  6. Update wp-config.php for new environment
  7. Test website functionality
  8. Update DNS to point to AWS
```

---

## Troubleshooting

### Issue: "Permission denied" when running script

```bash
# Solution: Make script executable
chmod +x wordpress-xneelo-export.sh
```

### Issue: "ssh: command not found"

```bash
# macOS: SSH should be pre-installed, check PATH
echo $PATH

# Linux Ubuntu/Debian:
sudo apt-get install openssh-client

# Linux CentOS/RHEL:
sudo yum install openssh-clients
```

### Issue: "rsync: command not found"

```bash
# macOS:
brew install rsync

# Linux Ubuntu/Debian:
sudo apt-get install rsync

# Linux CentOS/RHEL:
sudo yum install rsync
```

### Issue: "Connection timed out" or "Connection refused"

```bash
# Test SSH connection manually
ssh -p 2222 -v username@197.221.10.19

# Check if you can reach the server
ping 197.221.10.19

# Verify port is open
nc -zv 197.221.10.19 2222
# or
telnet 197.221.10.19 2222
```

### Issue: "WordPress installation not found"

```bash
# Specify WordPress root manually
./wordpress-xneelo-export.sh -w mysite -u username -r public_html

# Or try different paths:
./wordpress-xneelo-export.sh -w mysite -u username -r httpdocs
./wordpress-xneelo-export.sh -w mysite -u username -r public_html/httpdocs
```

### Issue: "Database export failed"

```bash
# SSH into server and test manually
ssh -p 2222 username@servername.xneelo.co.za
cd public_html
grep DB_ wp-config.php
# Note the database credentials

# Test mysqldump manually
mysqldump -u DB_USER -p DB_NAME > test.sql
# Enter password when prompted

# Check file size
ls -lh test.sql
```

### Issue: Script asks for password multiple times

```bash
# Set up SSH key authentication (see SSH Key Setup section above)
ssh-keygen -t rsa -b 4096
ssh-copy-id -p 2222 username@197.221.10.19
```

### Issue: "Disk space" errors

```bash
# Check local disk space
df -h .

# Check server disk space
ssh -p 2222 username@server 'df -h ~'

# Use --rsync-only to skip tar archive
./wordpress-xneelo-export.sh -w mysite -u username --rsync-only
```

---

## Quick Reference Commands

```bash
# View help
./wordpress-xneelo-export.sh --help

# Basic export
./wordpress-xneelo-export.sh -w SITENAME -u USERNAME

# Export from specific server
./wordpress-xneelo-export.sh -w SITENAME -u USERNAME -h SERVER_IP

# Export with custom WordPress path
./wordpress-xneelo-export.sh -w SITENAME -u USERNAME -r PATH

# Export without cleanup
./wordpress-xneelo-export.sh -w SITENAME -u USERNAME --skip-cleanup

# Fast export (rsync only)
./wordpress-xneelo-export.sh -w SITENAME -u USERNAME --rsync-only

# Verify checksums after export
cd exports/SITENAME
sha256sum -c CHECKSUMS-*.txt

# Read export notes
cat exports/SITENAME/EXPORT-NOTES-*.txt
```

---

## Directory Structure After Export

```
~/wordpress-exports/
├── wordpress-xneelo-export.sh          # The script
└── exports/                             # All exports go here
    ├── website1/                        # First export
    │   ├── wordpress-db-20260113_120000.sql
    │   ├── wordpress-files-20260113_120000.tar.gz
    │   ├── CHECKSUMS-20260113_120000.txt
    │   ├── EXPORT-NOTES-20260113_120000.txt
    │   └── public_html/
    │       ├── wp-admin/
    │       ├── wp-content/
    │       ├── wp-includes/
    │       └── wp-config.php
    ├── website2/                        # Second export
    │   └── ...
    └── website3/                        # Third export
        └── ...
```

---

## Tips for Success

1. **Set up SSH keys** - Saves time and avoids password prompts
2. **Test connection first** - SSH into server manually before running script
3. **Use meaningful website names** - Makes organizing exports easier
4. **Keep export notes** - Contains valuable migration information
5. **Verify checksums** - Ensures data integrity
6. **Use --rsync-only for large sites** - Faster, no compression overhead
7. **Keep server cleanup enabled** - Saves disk space on Xneelo server
8. **Review export notes** - Contains database credentials needed for AWS

---

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review export notes for details
3. Test individual components (SSH, rsync, etc.)
4. Check Xneelo server logs if accessible
