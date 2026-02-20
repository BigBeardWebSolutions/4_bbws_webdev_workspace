# Bastion Host Operations Guide for WordPress Migrations

## Table of Contents

1. [Overview](#overview)
2. [Why Bastion Instead of ECS Exec](#why-bastion-instead-of-ecs-exec)
3. [Getting Started](#getting-started)
4. [Basic Operations](#basic-operations)
5. [Migration Workflows](#migration-workflows)
6. [Helper Scripts Reference](#helper-scripts-reference)
7. [Troubleshooting](#troubleshooting)
8. [Best Practices](#best-practices)
9. [Cost Management](#cost-management)
10. [FAQ](#faq)

---

## Overview

The bastion host is a dedicated EC2 instance specifically designed for WordPress tenant migrations. It provides reliable, cost-effective access to AWS resources (RDS, EFS) for migration operations.

### Key Features

- **Pre-installed Tools:** WP-CLI, MySQL client, AWS CLI, PHP CLI
- **Secure Access:** AWS SSM Session Manager (no SSH keys)
- **Auto-Shutdown:** Stops after 30 minutes of idle time
- **Cost-Effective:** ~$1.70/month vs $8.50/month always-on
- **Audit Trail:** All actions logged to CloudWatch
- **Helper Scripts:** Simplified EFS mounting and RDS connections

### When to Use the Bastion

- WordPress tenant migrations from Xneelo to AWS
- Database operations (imports, search-replace, queries)
- EFS file operations (rsync, permissions, wp-content management)
- WP-CLI commands (plugin management, URL updates, cache clearing)
- MU-plugin deployment
- Migration troubleshooting and verification

---

## Why Bastion Instead of ECS Exec

### ECS Exec Issues (Documented from Au Pair Hive Migration)

1. **Session Timeouts:**
   - Sessions timeout after 20-30 minutes despite SSM timeout increases
   - "Cannot perform start session: EOF" errors
   - Required constant reconnection during 8-hour migration

2. **Heredoc Syntax Failures:**
   - Multi-line SQL scripts failed with syntax errors
   - Required splitting scripts into single-line commands
   - Increased complexity and error potential

3. **Unreliability:**
   - Random disconnections mid-operation
   - Lost progress on long-running operations
   - Difficulty debugging failed operations

### Bastion Advantages

1. **100% Reliability:** No EOF errors, no timeout issues
2. **Persistent Sessions:** Work for hours without interruption
3. **Better Performance:** Direct EC2 performance vs containerized environment
4. **Easier Debugging:** Full access to logs, system tools
5. **Cost-Effective:** Auto-shutdown minimizes running costs
6. **Better Audit Trail:** CloudWatch logs all operations

---

## Getting Started

### Prerequisites

1. **AWS CLI Configured:**
   ```bash
   aws sts get-caller-identity --profile Tebogo-dev
   ```

2. **SSM Plugin Installed:**
   ```bash
   # macOS
   brew install --cask session-manager-plugin

   # Linux
   # Follow: https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html

   # Verify installation
   session-manager-plugin --version
   ```

3. **Helper Scripts:**
   Located in: `/Users/tebogotseka/Documents/agentic_work/2_bbws_agents/tenant/scripts/bastion/`
   - `start-bastion.sh`
   - `stop-bastion.sh`
   - `connect-bastion.sh`

### First-Time Setup

1. **Navigate to scripts directory:**
   ```bash
   cd /Users/tebogotseka/Documents/agentic_work/2_bbws_agents/tenant/scripts/bastion/
   ```

2. **Verify scripts are executable:**
   ```bash
   ls -la
   # Should show -rwxr-xr-x permissions
   ```

3. **Test connection to DEV:**
   ```bash
   ./start-bastion.sh dev
   ./connect-bastion.sh dev
   ```

4. **Verify tools installed:**
   ```bash
   wp --version
   mysql --version
   aws --version
   php --version
   ```

5. **Exit and stop:**
   ```bash
   exit
   ./stop-bastion.sh dev
   ```

---

## Basic Operations

### Starting the Bastion

```bash
# Start bastion for specific environment
./start-bastion.sh dev   # or sit, prod

# Expected output:
# ✅ Found bastion: i-1234567890abcdef0
# 🚀 Starting bastion instance...
# ⏳ Waiting for bastion to be running...
# ✅ Bastion started successfully
#
# Connect via SSM:
#   aws ssm start-session --target i-1234567890abcdef0 --profile Tebogo-dev
```

**What it does:**
- Finds bastion instance by name tag
- Starts instance if stopped
- Waits until instance is fully running
- Displays connection instructions

### Connecting to the Bastion

```bash
# Connect via helper script (recommended)
./connect-bastion.sh dev

# Or manually via AWS CLI
aws ssm start-session \
  --target i-1234567890abcdef0 \
  --profile Tebogo-dev \
  --region eu-west-1
```

**On connection, you'll see:**
```
================================================================================
  WordPress Migration Bastion
================================================================================

Environment: dev
Region: eu-west-1

INSTALLED TOOLS:
  - WP-CLI:      /usr/local/bin/wp --info
  - MySQL Client: mysql --version
  - AWS CLI:     aws --version
  - PHP CLI:     php --version

HELPER SCRIPTS:
  - Mount EFS:     /usr/local/bin/migration-helpers/mount-efs.sh
  - Connect RDS:   /usr/local/bin/migration-helpers/connect-rds.sh

...
================================================================================
```

### Stopping the Bastion

```bash
# Stop manually when migration complete
./stop-bastion.sh dev

# Expected output:
# ✅ Found bastion: i-1234567890abcdef0
# 🔍 Checking for active SSM sessions...
# ✅ No active SSM sessions
# 🛑 Stopping bastion instance...
# ✅ Bastion stopped successfully
#
# 💰 Bastion stopped to minimize costs
# 📊 You're only charged for EBS storage while stopped (~$1.60/month)
```

**Notes:**
- Warns if active SSM sessions detected
- Prompts for confirmation before stopping with active sessions
- Auto-shutdown will stop after 30 minutes idle anyway

---

## Migration Workflows

### Workflow 1: Complete WordPress Site Migration

```bash
# 1. Start bastion
./start-bastion.sh dev
./connect-bastion.sh dev

# 2. Mount EFS
/usr/local/bin/migration-helpers/mount-efs.sh
# Output: ✅ EFS mounted successfully at /mnt/efs

# 3. Create tenant directory
sudo mkdir -p /mnt/efs/tenant-name
cd /mnt/efs/tenant-name

# 4. Download migration files from S3
aws s3 sync s3://bbws-migration-artifacts-dev/tenant-name/ /tmp/migration/

# 5. Copy wp-content files to EFS
sudo rsync -avz --progress /tmp/migration/wp-content/ /mnt/efs/tenant-name/

# 6. Fix permissions
sudo chown -R 33:33 /mnt/efs/tenant-name  # www-data user

# 7. Import database
/usr/local/bin/migration-helpers/connect-rds.sh
# In MySQL session:
CREATE DATABASE tenant_name_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE tenant_name_db;
SOURCE /tmp/migration/database.sql;
EXIT;

# 8. Run WP-CLI search-replace
wp --path=/mnt/efs/tenant-name search-replace 'oldsite.com' 'newsite.com' --dry-run
wp --path=/mnt/efs/tenant-name search-replace 'oldsite.com' 'newsite.com'

# 9. Verify migration
wp --path=/mnt/efs/tenant-name core version
wp --path=/mnt/efs/tenant-name plugin list
wp --path=/mnt/efs/tenant-name theme list

# 10. Exit and stop bastion
exit
./stop-bastion.sh dev
```

### Workflow 2: Database-Only Operations

```bash
# 1. Start and connect
./start-bastion.sh dev
./connect-bastion.sh dev

# 2. Connect to RDS
/usr/local/bin/migration-helpers/connect-rds.sh

# 3. Run SQL queries
USE tenant_db;
SELECT COUNT(*) FROM wp_posts WHERE post_status='publish';
UPDATE wp_options SET option_value='https://newsite.com' WHERE option_name='siteurl';

# 4. Export database
mysqldump -h <rds-endpoint> -u <user> -p tenant_db > /tmp/backup.sql

# 5. Exit
EXIT;
exit
./stop-bastion.sh dev
```

### Workflow 3: WP-CLI Batch Operations

```bash
# 1. Start and connect
./start-bastion.sh dev
./connect-bastion.sh dev

# 2. Mount EFS
/usr/local/bin/migration-helpers/mount-efs.sh

# 3. Navigate to tenant directory
cd /mnt/efs/tenant-name

# 4. Run WP-CLI commands
# Update plugins
wp plugin update --all --path=/mnt/efs/tenant-name

# Clear cache
wp cache flush --path=/mnt/efs/tenant-name

# Regenerate permalinks
wp rewrite flush --path=/mnt/efs/tenant-name

# Export database
wp db export /tmp/tenant-backup.sql --path=/mnt/efs/tenant-name

# 5. Upload backup to S3
aws s3 cp /tmp/tenant-backup.sql s3://bbws-migration-artifacts-dev/backups/

# 6. Exit
exit
./stop-bastion.sh dev
```

### Workflow 4: MU-Plugin Deployment

```bash
# 1. Start and connect
./start-bastion.sh dev
./connect-bastion.sh dev

# 2. Mount EFS
/usr/local/bin/migration-helpers/mount-efs.sh

# 3. Download MU-plugin from S3
aws s3 sync s3://bbws-migration-artifacts-dev/mu-plugins/ /tmp/mu-plugins/

# 4. Copy to all tenants
for tenant in /mnt/efs/*/; do
    sudo cp -r /tmp/mu-plugins/* "$tenant/mu-plugins/"
    echo "Deployed to: $tenant"
done

# 5. Verify deployment
for tenant in /mnt/efs/*/; do
    echo "Tenant: $tenant"
    ls -la "$tenant/mu-plugins/"
done

# 6. Exit
exit
./stop-bastion.sh dev
```

---

## Helper Scripts Reference

### Mount EFS: `/usr/local/bin/migration-helpers/mount-efs.sh`

**Purpose:** Mount EFS file system to access WordPress wp-content directories.

**Usage:**
```bash
/usr/local/bin/migration-helpers/mount-efs.sh
```

**Output:**
```
Mounting EFS: fs-1234567890abcdef0
EFS mounted successfully at /mnt/efs
drwxr-xr-x 10 root     root     6144 Jan 15 10:30 tenant1
drwxr-xr-x  8 root     root     6144 Jan 15 10:30 tenant2
```

**What it does:**
- Mounts EFS with TLS encryption
- Verifies mount success
- Lists tenant directories

**Troubleshooting:**
- "ERROR: EFS_ID not configured" - Check user_data.sh configuration
- "Mount failed" - Check security group allows NFS (2049) from bastion

### Connect RDS: `/usr/local/bin/migration-helpers/connect-rds.sh`

**Purpose:** Connect to RDS MySQL with credentials from Secrets Manager.

**Usage:**
```bash
/usr/local/bin/migration-helpers/connect-rds.sh
```

**Output:**
```
Fetching RDS credentials from Secrets Manager...
Connecting to RDS: rds-dev.xxxxx.eu-west-1.rds.amazonaws.com:3306 as admin
Welcome to the MySQL monitor...
mysql>
```

**What it does:**
- Retrieves RDS credentials from Secrets Manager
- Parses JSON credentials
- Connects to MySQL automatically

**Troubleshooting:**
- "ERROR: Failed to retrieve RDS credentials" - Check IAM role has secretsmanager:GetSecretValue
- "Access denied" - Verify security group allows MySQL (3306) from bastion

---

## Troubleshooting

### Issue: Cannot connect via SSM

**Symptoms:**
```
An error occurred (TargetNotConnected) when calling the StartSession operation:
i-1234567890abcdef0 is not connected.
```

**Solutions:**
1. **Check instance is running:**
   ```bash
   ./start-bastion.sh dev
   ```

2. **Verify SSM agent status:**
   ```bash
   aws ssm describe-instance-information \
     --instance-id i-1234567890abcdef0 \
     --profile Tebogo-dev
   ```

3. **Check IAM instance profile:**
   ```bash
   aws ec2 describe-instances \
     --instance-ids i-1234567890abcdef0 \
     --query 'Reservations[0].Instances[0].IamInstanceProfile'
   ```

4. **Review CloudWatch logs:**
   ```bash
   aws logs tail /aws/ec2/bastion-dev --follow
   ```

### Issue: EFS mount fails

**Symptoms:**
```
mount.nfs: Connection timed out
ERROR: Failed to mount EFS
```

**Solutions:**
1. **Verify security group allows NFS:**
   ```bash
   aws ec2 describe-security-groups \
     --filters "Name=group-name,Values=*efs*" \
     --query 'SecurityGroups[].IpPermissions'
   ```

2. **Check EFS mount targets:**
   ```bash
   aws efs describe-mount-targets \
     --file-system-id fs-1234567890abcdef0
   ```

3. **Test connectivity:**
   ```bash
   telnet <efs-mount-target-ip> 2049
   ```

4. **Manual mount:**
   ```bash
   sudo mount -t efs -o tls fs-1234567890abcdef0 /mnt/efs
   ```

### Issue: RDS connection refused

**Symptoms:**
```
ERROR 2003 (HY000): Can't connect to MySQL server on 'rds-endpoint' (111)
```

**Solutions:**
1. **Verify security group allows MySQL:**
   ```bash
   aws ec2 describe-security-groups \
     --filters "Name=group-name,Values=*rds*" \
     --query 'SecurityGroups[].IpPermissions'
   ```

2. **Test connectivity:**
   ```bash
   telnet <rds-endpoint> 3306
   ```

3. **Check RDS endpoint:**
   ```bash
   aws rds describe-db-instances \
     --query 'DBInstances[].Endpoint'
   ```

4. **Verify Secrets Manager:**
   ```bash
   aws secretsmanager get-secret-value \
     --secret-id /dev/rds/credentials
   ```

### Issue: Bastion not auto-stopping

**Symptoms:**
- Bastion remains running after 30+ minutes idle
- No SNS notification received

**Solutions:**
1. **Check Lambda function:**
   ```bash
   aws lambda get-function \
     --function-name dev-bastion-auto-shutdown
   ```

2. **Review Lambda logs:**
   ```bash
   aws logs tail /aws/lambda/dev-bastion-auto-shutdown --follow
   ```

3. **Check EventBridge rule:**
   ```bash
   aws events describe-rule \
     --name dev-bastion-auto-shutdown-check
   ```

4. **Verify instance tags:**
   ```bash
   aws ec2 describe-tags \
     --filters "Name=resource-id,Values=i-1234567890abcdef0"
   ```

   Should include:
   - `ManagedBy: bastion-auto-shutdown`
   - `Environment: dev`

### Issue: WP-CLI command fails

**Symptoms:**
```
Error: This does not seem to be a WordPress installation.
```

**Solutions:**
1. **Verify wp-config.php exists:**
   ```bash
   ls -la /mnt/efs/tenant-name/wp-config.php
   ```

2. **Check file permissions:**
   ```bash
   ls -la /mnt/efs/tenant-name/
   # Should show www-data (33:33) ownership
   ```

3. **Verify path:**
   ```bash
   wp --path=/mnt/efs/tenant-name core version
   ```

4. **Check database connectivity:**
   ```bash
   wp --path=/mnt/efs/tenant-name db check
   ```

---

## Best Practices

### 1. Always Use Helper Scripts

**Good:**
```bash
./start-bastion.sh dev
./connect-bastion.sh dev
```

**Avoid:**
```bash
# Manual instance lookup and connection
INSTANCE_ID=$(aws ec2...)  # Use helper scripts instead
```

### 2. Stop Bastion When Done

**Good:**
```bash
# After completing migration
exit
./stop-bastion.sh dev
```

**Avoid:**
```bash
# Leaving bastion running
# Relying only on auto-shutdown
```

### 3. Use S3 for Large Files

**Good:**
```bash
# Upload to S3 first
aws s3 cp large-database.sql s3://bbws-migration-artifacts-dev/tenant/

# Download on bastion
aws s3 cp s3://bbws-migration-artifacts-dev/tenant/large-database.sql /tmp/
```

**Avoid:**
```bash
# Trying to transfer via local machine
# Using scp (bastion doesn't allow SSH)
```

### 4. Verify Before Modifying

**Good:**
```bash
# Dry-run first
wp search-replace 'old.com' 'new.com' --dry-run

# Then execute
wp search-replace 'old.com' 'new.com'
```

**Avoid:**
```bash
# Running directly without dry-run
wp search-replace 'old.com' 'new.com'  # Risky!
```

### 5. Document Your Operations

**Good:**
```bash
# Keep a log of commands run
echo "$(date): Started migration for tenant-name" >> /tmp/migration.log
# Run commands
echo "$(date): Completed migration for tenant-name" >> /tmp/migration.log

# Upload log to S3
aws s3 cp /tmp/migration.log s3://bbws-migration-artifacts-dev/logs/
```

### 6. Use Screen for Long Operations

**Good:**
```bash
# Start screen session
screen -S migration

# Run long operation
wp search-replace 'old.com' 'new.com' --path=/mnt/efs/tenant-name

# Detach: Ctrl+A, D
# Reattach: screen -r migration
```

---

## Cost Management

### Understanding Costs

**Bastion Running (t3a.medium - RECOMMENDED):**
- Hourly rate: $0.0188/hour
- Daily cost (24 hours): $0.45/day
- Monthly cost (24/7): $13.72/month
- RAM: 4GB (prevents OOM during large transfers)

**Note:** t3a.micro (1GB) caused SSM disconnects during file transfers due to OOM.
Upgrade script: `./upgrade-bastion.sh dev t3a.medium`

**Bastion Stopped:**
- EBS storage (20GB GP3): $1.60/month
- No compute charges

**Auto-Shutdown Savings:**
- Typical usage: 8 hours/month
- Compute cost: $0.08/month
- Storage cost: $1.60/month
- **Total: $1.68/month**
- **Savings: 76% vs always-on**

### Cost Optimization Tips

1. **Stop immediately after use:**
   ```bash
   exit
   ./stop-bastion.sh dev
   ```

2. **Monitor usage:**
   ```bash
   aws ce get-cost-and-usage \
     --time-period Start=2024-01-01,End=2024-01-31 \
     --granularity MONTHLY \
     --filter file://filter.json \
     --metrics UnblendedCost
   ```

3. **Check running time:**
   ```bash
   aws ec2 describe-instances \
     --instance-ids i-1234567890abcdef0 \
     --query 'Reservations[0].Instances[0].LaunchTime'
   ```

4. **Review auto-shutdown logs:**
   ```bash
   aws logs filter-log-events \
     --log-group-name /aws/lambda/dev-bastion-auto-shutdown \
     --filter-pattern "stopped"
   ```

---

## FAQ

### Q: How long does bastion take to start?

**A:** Typically 2-3 minutes from stopped state to fully running and SSM-ready.

### Q: Can I use SSH instead of SSM?

**A:** No. SSH is intentionally disabled. SSM provides better security and audit trail.

### Q: What happens if I lose connection during a long operation?

**A:** SSM sessions are resilient. You can reconnect and check process status:
```bash
# Reconnect
./connect-bastion.sh dev

# Check running processes
ps aux | grep wp-cli
ps aux | grep mysql
```

### Q: Can multiple people use bastion simultaneously?

**A:** Yes. SSM supports multiple concurrent sessions. Each user gets their own session.

### Q: How do I know if auto-shutdown is working?

**A:** Check SNS notifications (email) and CloudWatch logs:
```bash
aws logs tail /aws/lambda/dev-bastion-auto-shutdown --follow
```

### Q: What if I need bastion for more than 30 minutes?

**A:** Auto-shutdown only triggers if IDLE for 30 minutes. Active operations keep it running. If you need longer idle time, adjust the Lambda timeout variable.

### Q: Can I disable auto-shutdown temporarily?

**A:** Yes:
```bash
aws events disable-rule \
  --name dev-bastion-auto-shutdown-check \
  --profile Tebogo-dev

# Re-enable later
aws events enable-rule \
  --name dev-bastion-auto-shutdown-check \
  --profile Tebogo-dev
```

### Q: Where are bastion logs stored?

**A:** CloudWatch Log Groups:
- Bootstrap: `/aws/ec2/bastion-dev` → `user-data.log`
- System: `/aws/ec2/bastion-dev` → `messages`
- Security: `/aws/ec2/bastion-dev` → `secure`

### Q: How do I update bastion software (WP-CLI, MySQL client)?

**A:** Bastion bootstrap runs once at launch. To update:
```bash
# Connect to bastion
./connect-bastion.sh dev

# Update WP-CLI
sudo curl -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
sudo chmod +x /usr/local/bin/wp

# Update system packages
sudo dnf update -y
```

---

## Related Documentation

- [WordPress Migration Playbook](wordpress_migration_playbook_automated.md)
- [Bastion Terraform Module README](../../2_bbws_ecs_terraform/terraform/modules/bastion/README.md)
- [Lambda Auto-Shutdown README](../../2_bbws_bastion_auto_shutdown/README.md)
- [AWS SSM Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html)
- [WP-CLI Documentation](https://wp-cli.org/)

---

## Support

For issues or questions:
1. Check CloudWatch logs: `/aws/ec2/bastion-{environment}`
2. Review this operations guide
3. Check bastion module README
4. Contact DevOps team

---

**Last Updated:** 2024-01-15
**Version:** 1.0.0
**Maintained By:** DevOps Team
