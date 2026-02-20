# Lynfin Migration - Execution Guide

## Status: READY TO EXECUTE

All migration files are uploaded to S3 and ready for execution on bastion.

### S3 Files Ready
| File | Size | Purpose |
|------|------|---------|
| `lynwoodwealth.sql` | 7MB | Database dump |
| `lynnwood-wealth.7z` | 401MB | WordPress files |
| `run-migration.sh` | 16KB | Migration script |

---

## Quick Start

### Option 1: AWS Console (Recommended)

1. Go to **EC2 Console** → **Instances**
2. Select bastion instance: `i-0ba86c12de4064b6b`
3. Click **Connect** → **Session Manager** → **Connect**
4. Run:
```bash
mkdir -p /tmp/migration-lynfin
cd /tmp/migration-lynfin
aws s3 cp s3://wordpress-migration-temp-20250903/Lynfin/run-migration.sh . --region eu-west-1
chmod +x run-migration.sh
./run-migration.sh
```

### Option 2: Install Session Manager Plugin Locally

```bash
# macOS
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/mac/sessionmanager-bundle.zip" -o "sessionmanager-bundle.zip"
unzip sessionmanager-bundle.zip
sudo ./sessionmanager-bundle/install -i /usr/local/sessionmanagerplugin -b /usr/local/bin/session-manager-plugin

# Then connect
aws ssm start-session --target i-0ba86c12de4064b6b --region eu-west-1
```

### Option 3: SSH (if key available)

```bash
ssh -i ~/.ssh/your-key.pem ec2-user@54.216.74.26
```

---

## Configuration

| Setting | Value |
|---------|-------|
| Tenant ID | lynfin |
| Target Domain | lynfin.wpdev.kimmyai.io |
| Original Domain | lynfin.personalinvest.co.za |
| Test Email | tebogo@bigbeard.co.za |
| S3 Source | s3://wordpress-migration-temp-20250903/Lynfin/ |
| RDS Host | dev-mysql.c9ko42mci6mt.eu-west-1.rds.amazonaws.com |
| Database | lynfin_db |
| EFS Path | /mnt/efs/lynfin |

---

## What the Script Does

### Phase 1: Download and Extract
- Downloads `lynwoodwealth.sql` (database dump)
- Downloads `lynnwood-wealth.7z` (WordPress files)
- Extracts 7z archive to find wp-content

### Phase 2: Database Migration
- Creates `lynfin_db` database with utf8mb4
- Creates `lynfin_user` with generated password
- Imports WordPress database
- Applies UTF-8 encoding fixes
- Updates URLs: `lynfin.personalinvest.co.za` → `lynfin.wpdev.kimmyai.io`

### Phase 3: Files Migration
- Mounts EFS at `/mnt/efs`
- Creates `/mnt/efs/lynfin` directory
- Copies wp-content files
- Sets www-data ownership (33:33)

### Phase 4: MU-Plugins
- Deploys `force-https.php`
- Deploys `test-email-redirect.php` (redirects to tebogo@bigbeard.co.za)
- Deploys `environment-indicator.php`

### Phase 5: Cache Clearing
- Clears WordPress transients and cache options

### Phase 6: Validation
- Shows published posts count
- Shows user count
- Verifies site URL

---

## After Migration

### Verify Site
```bash
curl -sI https://lynfin.wpdev.kimmyai.io | head -10
```

### Database Credentials
Saved to: `/tmp/migration-lynfin/credentials.txt`

### Next Steps
1. Test the site at https://lynfin.wpdev.kimmyai.io
2. Submit a form to verify email redirect works
3. Check all pages render correctly
4. Run validation suite (Stage 5 of Master Plan)

---

## Troubleshooting

### 7z not installed
```bash
sudo yum install -y p7zip p7zip-plugins
```

### EFS not mounting
```bash
# Get EFS ID
EFS_ID=$(aws efs describe-file-systems --query 'FileSystems[0].FileSystemId' --output text --region eu-west-1)

# Manual mount
sudo mkdir -p /mnt/efs
sudo mount -t efs ${EFS_ID}:/ /mnt/efs
```

### Database connection failed
```bash
# Test connection
mysql -h dev-mysql.c9ko42mci6mt.eu-west-1.rds.amazonaws.com -u admin -p
```

---

## Instance Details

| Resource | Value |
|----------|-------|
| Bastion Instance | i-0ba86c12de4064b6b |
| Bastion Status | Running |
| Public IP | 54.216.74.26 |
| Private IP | 10.1.2.74 |
