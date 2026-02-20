# Quick Start Guide - WordPress Export Script

## 🚀 5-Minute Setup

### Step 1: Create the Script (Choose One Method)

#### Method A: If You Have Git Repository
```bash
git clone <repository-url>
cd file_transfer
chmod +x wordpress-xneelo-export.sh
```

#### Method B: Create Manually
```bash
# Create working directory
mkdir -p ~/wordpress-exports && cd ~/wordpress-exports

# Create script file (paste content from wordpress-xneelo-export.sh)
nano wordpress-xneelo-export.sh
# Paste script content, save with Ctrl+X, Y, Enter

# Make executable
chmod +x wordpress-xneelo-export.sh
```

#### Method C: Download from URL
```bash
curl -o wordpress-xneelo-export.sh https://your-repo-url/wordpress-xneelo-export.sh
chmod +x wordpress-xneelo-export.sh
```

### Step 2: Setup SSH Key (Optional but Recommended)
```bash
# Generate key
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"

# Copy to Xneelo server (replace with your details)
ssh-copy-id -p 2222 aupaiqzaea@197.221.10.19

# Test connection
ssh -p 2222 aupaiqzaea@197.221.10.19
```

### Step 3: Run Your First Export
```bash
# Replace 'mywebsite' and 'aupaiqzaea' with your details
./wordpress-xneelo-export.sh -w mywebsite -u aupaiqzaea
```

---

## 📋 Common Commands

### Basic Export
```bash
./wordpress-xneelo-export.sh -w WEBSITE_NAME -u SSH_USERNAME
```

### Export from Specific Server
```bash
./wordpress-xneelo-export.sh -w WEBSITE_NAME -u USERNAME -h 197.221.12.211
```

### Fast Export (No Tar Archive)
```bash
./wordpress-xneelo-export.sh -w WEBSITE_NAME -u USERNAME --rsync-only
```

### Keep Files on Server (Debugging)
```bash
./wordpress-xneelo-export.sh -w WEBSITE_NAME -u USERNAME --skip-cleanup
```

---

## 📁 What You'll Get

```
exports/WEBSITE_NAME/
├── wordpress-db-TIMESTAMP.sql           # Database
├── wordpress-files-TIMESTAMP.tar.gz     # Complete backup
├── CHECKSUMS-TIMESTAMP.txt              # Verify integrity
├── EXPORT-NOTES-TIMESTAMP.txt           # Migration info
└── public_html/                         # All WordPress files
```

---

## ✅ Verify Export Success

```bash
# Navigate to export directory
cd exports/WEBSITE_NAME

# Verify checksums
sha256sum -c CHECKSUMS-*.txt

# Read export notes (has database credentials)
cat EXPORT-NOTES-*.txt

# Check files are present
ls -lh
```

---

## 🔧 Quick Troubleshooting

| Problem | Solution |
|---------|----------|
| Permission denied | `chmod +x wordpress-xneelo-export.sh` |
| Command not found | Install: `brew install rsync` (Mac) or `sudo apt install rsync` (Linux) |
| SSH connection fails | Test: `ssh -p 2222 username@197.221.10.19` |
| Password prompts | Setup SSH key (see Step 2 above) |
| WordPress not found | Add path: `-r public_html` or `-r httpdocs` |

---

## 📖 Full Documentation

See **SETUP_GUIDE.md** for complete instructions and troubleshooting.

---

## 🎯 Real Example

```bash
# Export "manufacturing" website from Xneelo server
./wordpress-xneelo-export.sh \
  -w manufacturing \
  -u manufkcxqw \
  -h 197.221.12.211

# Result: exports/manufacturing/ with all files
```

---

## ⚡ Next Steps After Export

1. ✅ Verify checksums: `sha256sum -c CHECKSUMS-*.txt`
2. ✅ Read export notes for database credentials
3. ✅ Prepare AWS environment (EC2/Lightsail)
4. ✅ Import database: `mysql -u user -p database < wordpress-db-*.sql`
5. ✅ Upload files to AWS
6. ✅ Update wp-config.php with new credentials
7. ✅ Test site
8. ✅ Update DNS
