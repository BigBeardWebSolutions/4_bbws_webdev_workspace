# S3 Upload Solution - Bypass Download Issues

## 🎯 Solution Overview

Instead of downloading from Xneelo to your Mac (which fails), upload directly from Xneelo server to S3, then download from S3 to your Mac.

```
Xneelo Server ──AWS CLI──▶ S3 ──AWS CLI──▶ Your Mac
```

This bypasses all the SCP/SFTP/HTTP issues!

---

## 📋 Prerequisites

### 1. Install AWS CLI on Xneelo Server

**In your SSH session on Xneelo server:**

```bash
# Check if AWS CLI is already installed
aws --version

# If not installed, install it:
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Or if no sudo access, install to home directory:
./aws/install -i ~/aws-cli -b ~/bin
export PATH=~/bin:$PATH
```

### 2. Configure AWS SSO on Server

**On Xneelo server:**

```bash
# Configure AWS SSO
aws configure sso

# You'll be prompted for:
# SSO session name: default
# SSO start URL: [Your SSO URL]
# SSO region: eu-west-1
# SSO registration scopes: sso:account:access
# CLI default client Region: eu-west-1
# CLI default output format: json
# CLI profile name: default

# Login to AWS SSO
aws sso login --profile default
```

**Note**: This will give you a URL and code. You'll need to open it in your browser on your local machine.

---

## 🚀 Quick Test - Upload to S3

### Step 1: Upload Script to Server

**On your Mac:**

```bash
cd ~/Downloads/AGENTIC_WORK/0_utilities/file_transfer

# Upload the S3 upload script to server
# (We'll try SSH cat method since SCP doesn't work)
cat upload-to-s3.sh | ssh -p 2222 manufkcxqw@197.221.10.19 'cat > upload-to-s3.sh'
```

### Step 2: Run Upload Script on Server

**On Xneelo server (SSH session):**

```bash
# Make executable
chmod +x upload-to-s3.sh

# Run the upload
./upload-to-s3.sh -w manufacturing -e ~/exports-manufacturing-20260113_075835
```

### Step 3: Download from S3 to Your Mac

**On your Mac:**

```bash
# Create download directory
mkdir -p ~/Downloads/wordpress-exports/manufacturing
cd ~/Downloads/wordpress-exports/manufacturing

# Download from S3
aws s3 sync s3://wordpress-migration-temp-20250903/manufacturing/ . --profile default --region eu-west-1

# Verify download
ls -lh

# Check checksums
sha256sum -c CHECKSUMS-*.txt
```

---

## 📖 Complete Workflow

### 1. On Xneelo Server

```bash
# Already done: Export WordPress
./local-wordpress-export.sh -w manufacturing
# ✓ Created: ~/exports-manufacturing-20260113_075835/

# Upload script to server (from your Mac)
# See "Upload Script to Server" below

# Make executable
chmod +x upload-to-s3.sh

# Upload to S3
./upload-to-s3.sh -w manufacturing -e ~/exports-manufacturing-20260113_075835

# Output shows:
# ✓ Upload completed successfully!
# Download command: aws s3 sync s3://wordpress-migration-temp-20250903/manufacturing/ . --profile default
```

### 2. On Your Mac

```bash
# Download from S3
mkdir -p ~/Downloads/wordpress-exports/manufacturing
cd ~/Downloads/wordpress-exports/manufacturing

aws s3 sync s3://wordpress-migration-temp-20250903/manufacturing/ . --profile default --region eu-west-1

# Verify
ls -lh
sha256sum -c CHECKSUMS-*.txt
```

### 3. Cleanup (After Successful Download)

```bash
# On your Mac - delete from S3 (to save costs)
aws s3 rm s3://wordpress-migration-temp-20250903/manufacturing/ --recursive --profile default --region eu-west-1

# On Xneelo server - delete local exports (to save space)
rm -rf ~/exports-manufacturing-*
```

---

## 🔧 Upload Script to Server (Alternative Methods)

Since SCP doesn't work, use one of these methods:

### Method 1: Cat Through SSH

**On your Mac:**

```bash
cd ~/Downloads/AGENTIC_WORK/0_utilities/file_transfer

cat upload-to-s3.sh | ssh -p 2222 manufkcxqw@197.221.10.19 'cat > upload-to-s3.sh'
```

### Method 2: Base64 Encode (If Method 1 Fails)

**On your Mac:**

```bash
base64 upload-to-s3.sh
# Copy the output
```

**On Xneelo server:**

```bash
nano upload-to-s3.sh
# Paste the base64 content
# Save: Ctrl+X, Y, Enter

# Decode
base64 -d upload-to-s3.sh > upload-to-s3-decoded.sh
mv upload-to-s3-decoded.sh upload-to-s3.sh
chmod +x upload-to-s3.sh
```

### Method 3: Manual Copy/Paste

**On your Mac:**

```bash
cat upload-to-s3.sh
# Copy the entire script
```

**On Xneelo server:**

```bash
nano upload-to-s3.sh
# Paste the script
# Save: Ctrl+X, Y, Enter
chmod +x upload-to-s3.sh
```

---

## 🎯 S3 Bucket Structure

```
s3://wordpress-migration-temp-20250903/
└── manufacturing/
    ├── wordpress-db-20260113_075835.sql
    ├── wordpress-files-20260113_075835.tar.gz
    ├── CHECKSUMS-20260113_075835.txt
    ├── EXPORT-NOTES-20260113_075835.txt
    └── exports-manufacturing-20260113_075835.tar.gz (if final package exists)
```

---

## ✅ Advantages of S3 Method

1. ✅ **Bypasses SCP/SFTP issues** - Uses AWS CLI instead
2. ✅ **Reliable transfer** - AWS handles retry and resume
3. ✅ **Fast downloads** - S3 to your Mac is fast
4. ✅ **Temporary storage** - Delete after download
5. ✅ **Works anywhere** - Download from any location later

---

## 🔍 Troubleshooting

### AWS CLI Not Installed on Server

```bash
# Install to home directory (no sudo needed)
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install -i ~/aws-cli -b ~/bin
export PATH=~/bin:$PATH
echo 'export PATH=~/bin:$PATH' >> ~/.bashrc
```

### AWS SSO Login Issues

```bash
# Re-login
aws sso login --profile default

# Or configure from scratch
aws configure sso --profile default
```

### Upload Fails - Credentials Expired

```bash
# Re-authenticate
aws sso login --profile default

# Then retry upload
./upload-to-s3.sh -w manufacturing -e ~/exports-manufacturing-20260113_075835
```

### Can't Upload Script to Server

Use the manual copy/paste method - always works!

---

## 📊 Script Usage

```bash
# Basic usage
./upload-to-s3.sh -w <website-name> -e <export-directory>

# With custom profile
./upload-to-s3.sh -w manufacturing -e ~/exports-manufacturing-20260113_075835 -p my-profile

# Show help
./upload-to-s3.sh --help
```

---

## 🎉 Success Criteria

When successful, you'll see:

```
✓ AWS CLI is installed
✓ Export directory exists
✓ AWS credentials are valid
✓ Upload completed successfully!
✓ Total uploaded: 92MB

Download to Local Machine:
  aws s3 sync s3://wordpress-migration-temp-20250903/manufacturing/ . --profile default --region eu-west-1
```

Then download on your Mac and you're done! 🚀
