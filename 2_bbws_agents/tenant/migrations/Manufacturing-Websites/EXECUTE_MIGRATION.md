# Manufacturing-Websites Migration - Execution Guide

## Current Status

| Item | Status | Notes |
|------|--------|-------|
| S3 Export Files | ✅ Verified | Database (~51MB), Files (~92MB) |
| Bastion Host | ✅ Running | i-0ba86c12de4064b6b |
| RDS Instance | ✅ Available | dev-mysql.c9ko42mci6mt.eu-west-1.rds.amazonaws.com |
| Tenant Credentials | ✅ Created | dev-manufacturing-db-credentials |
| Migration Script | ✅ Uploaded | s3://wordpress-migration-temp-20250903/manufacturing/run-migration.sh |

## Source Information

- **Old Domain**: `manufacturing-websites.com`
- **New Domain**: `manufacturing.wpdev.kimmyai.io`
- **Theme**: hello-elementor with hello-theme-child-master
- **Key Plugins**: Elementor Pro, Wordfence, Yoast SEO, Complianz GDPR

---

## Execute Migration

### Step 1: Connect to Bastion Host

```bash
# Option A: Use AWS CLI directly
aws ssm start-session --target i-0ba86c12de4064b6b --region eu-west-1

# Option B: Use bastion script (if using Tebogo-dev profile)
cd /Users/sithembisomjoko/Downloads/AGENTIC_WORK/2_bbws_agents/tenant/scripts/bastion
./connect-bastion.sh dev
```

### Step 2: Download and Run Migration Script

Once connected to the bastion, run:

```bash
# Download migration script from S3
aws s3 cp s3://wordpress-migration-temp-20250903/manufacturing/run-migration.sh /tmp/run-migration.sh --region eu-west-1

# Make executable
chmod +x /tmp/run-migration.sh

# Run migration
/tmp/run-migration.sh
```

### Step 3: Monitor Progress

The script will output progress for each phase:
- Phase 1: Download from S3
- Phase 2: Database Migration
- Phase 3: Files Migration
- Phase 4: Deploy MU-Plugins
- Phase 5: Clear Caches
- Phase 6: Validation

Expected completion time: ~10-15 minutes

---

## Post-Migration Validation

After migration completes, run validation:

```bash
# From bastion or local machine with curl
curl -s -o /dev/null -w "%{http_code}" https://manufacturing.wpdev.kimmyai.io
# Expected: 200

# Check for DEV environment indicator
curl -s https://manufacturing.wpdev.kimmyai.io | grep "DEV ENVIRONMENT"
# Expected: Shows environment banner
```

Or run the full validation script:

```bash
cd /Users/sithembisomjoko/Downloads/AGENTIC_WORK/2_bbws_agents/tenant/scripts
./validate-migration.sh https://manufacturing.wpdev.kimmyai.io
```

---

## Manual Testing Checklist

After migration, verify:

- [ ] Homepage loads at https://manufacturing.wpdev.kimmyai.io
- [ ] DEV environment banner visible at bottom of page
- [ ] Admin login works at /wp-admin/
- [ ] Images and media load correctly
- [ ] Contact form submission redirects to tebogo@bigbeard.co.za
- [ ] No mixed content warnings in browser
- [ ] No encoding artifacts (Â, â€™, etc.)

---

## Troubleshooting

### If bastion SSM session fails:
```bash
# Check bastion status
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=dev-wordpress-migration-bastion" \
  --query 'Reservations[0].Instances[0].State.Name' \
  --region eu-west-1

# If stopped, start it
aws ec2 start-instances --instance-ids i-0ba86c12de4064b6b --region eu-west-1
```

### If database connection fails:
```bash
# Verify RDS is accessible from bastion
mysql -h dev-mysql.c9ko42mci6mt.eu-west-1.rds.amazonaws.com -u admin -p -e "SELECT 1;"
```

### If EFS mount fails:
```bash
# Manual mount
sudo mount -t efs -o tls fs-0e1cccd971a35db46:/ /mnt/efs
```

---

## Configuration Reference

| Setting | Value |
|---------|-------|
| Tenant ID | manufacturing |
| Environment | dev |
| RDS Host | dev-mysql.c9ko42mci6mt.eu-west-1.rds.amazonaws.com |
| Database | manufacturing_db |
| DB User | manufacturing_user |
| EFS ID | fs-0e1cccd971a35db46 |
| EFS Path | /mnt/efs/manufacturing |
| Test Email | tebogo@bigbeard.co.za |

---

## Next Steps After DEV Validation

1. **Complete UAT in DEV**
2. **Promote to SIT** using same migration script with SIT parameters
3. **Production Cutover** (future - requires custom domain and SSL)
