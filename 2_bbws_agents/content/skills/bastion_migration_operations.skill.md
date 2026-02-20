# Bastion Migration Operations Skill

## Skill Metadata

- **Skill Name:** bastion_migration_operations
- **Category:** Infrastructure & Operations
- **Complexity:** Intermediate
- **Prerequisites:** AWS CLI, Terraform, SSM Session Manager
- **Last Updated:** 2026-01-11
- **Version:** 1.0.0

## Overview

This skill encapsulates knowledge and procedures for using EC2 bastion hosts for WordPress migration operations, replacing the unreliable ECS exec approach with a robust, cost-effective solution.

## Problem Statement

**Original Challenge:**
WordPress migrations using ECS exec experienced:
- Session timeouts after 20-30 minutes
- "Cannot perform start session: EOF" errors
- Heredoc syntax failures for multi-line SQL scripts
- 8-10 hour migration times with constant troubleshooting

**Solution:**
Dedicated EC2 bastion host with:
- 100% reliability (no timeouts)
- Pre-installed migration tools
- Auto-shutdown after 30 minutes idle
- 80% cost reduction vs always-on

## When to Apply This Skill

✅ **Use this skill for:**
- WordPress tenant migrations to AWS ECS/Fargate
- Database import/export operations
- Large file transfers to/from EFS
- WP-CLI batch operations across multiple tenants
- Migration troubleshooting and debugging
- Long-running operations (> 30 minutes)

❌ **Don't use this skill for:**
- Quick ECS container checks (< 5 minutes)
- Container-specific debugging
- Application runtime troubleshooting

## Core Components

### 1. Infrastructure (Terraform)

**Bastion Module Location:** `2_bbws_ecs_terraform/terraform/modules/bastion/`

**Key Resources:**
- EC2 instance (t3a.micro) with Amazon Linux 2023
- IAM role with SSM, Secrets Manager, EFS, S3 permissions
- Security groups (egress only: MySQL 3306, NFS 2049, HTTPS 443)
- CloudWatch log group for audit trail
- User data script for tool installation

**Deployment:**
```hcl
module "bastion_host" {
  source = "./modules/bastion"

  environment          = var.environment
  vpc_id              = aws_vpc.main.id
  public_subnet_id    = aws_subnet.public[0].id
  instance_type       = "t3a.micro"
  idle_timeout_minutes = 30

  rds_security_group_id = aws_security_group.rds.id
  efs_security_group_id = aws_security_group.efs.id
  migration_artifacts_bucket = "bbws-migration-artifacts-${var.environment}"

  efs_id     = aws_efs_file_system.main.id
  aws_region = var.aws_region
  tags       = local.common_tags
}
```

### 2. Auto-Shutdown Lambda

**Purpose:** Stop bastion after idle timeout to minimize costs

**Logic:**
1. Triggered by EventBridge every 5 minutes
2. Finds bastion instances with tag `ManagedBy: bastion-auto-shutdown`
3. Checks metrics: CPU < 5%, network I/O < 1MB, no SSM sessions
4. If idle > 30 minutes: stop instance, update DynamoDB, send SNS
5. Logs all actions to CloudWatch

**Cost Impact:**
- Always-on: $8.50/month
- With auto-shutdown: $1.70/month (8 hours/month usage)
- **Savings: 80%**

### 3. Helper Scripts

**Location:** `2_bbws_agents/tenant/scripts/bastion/`

**Scripts:**
- `start-bastion.sh` - Start stopped bastion, wait until running
- `stop-bastion.sh` - Stop bastion with SSM session check
- `connect-bastion.sh` - Connect via SSM Session Manager

**Usage Pattern:**
```bash
./start-bastion.sh dev
./connect-bastion.sh dev
# ... perform migration operations ...
exit
./stop-bastion.sh dev
```

### 4. Pre-installed Tools

On bastion connection, you have:
- **WP-CLI:** WordPress command-line operations
- **MySQL Client 8.0:** Direct RDS database access
- **AWS CLI v2:** S3, Secrets Manager, EFS operations
- **PHP 8.2 CLI:** Run PHP migration scripts
- **EFS Utils:** Mount EFS file systems with TLS
- **CloudWatch Agent:** Metrics and logging

### 5. On-Bastion Helper Scripts

**Mount EFS:**
```bash
/usr/local/bin/migration-helpers/mount-efs.sh
# Mounts EFS at /mnt/efs with TLS encryption
```

**Connect RDS:**
```bash
/usr/local/bin/migration-helpers/connect-rds.sh
# Retrieves credentials from Secrets Manager, connects to MySQL
```

## Operational Workflows

### Workflow 1: Complete WordPress Migration

```bash
# 1. Start bastion
./start-bastion.sh dev

# 2. Connect
./connect-bastion.sh dev

# 3. Mount EFS
/usr/local/bin/migration-helpers/mount-efs.sh

# 4. Create tenant directory
sudo mkdir -p /mnt/efs/tenant-name
cd /mnt/efs/tenant-name

# 5. Download migration files from S3
aws s3 sync s3://bbws-migration-artifacts-dev/tenant-name/ /tmp/migration/

# 6. Copy wp-content to EFS
sudo rsync -avz --progress /tmp/migration/wp-content/ /mnt/efs/tenant-name/

# 7. Fix permissions
sudo chown -R 33:33 /mnt/efs/tenant-name  # www-data

# 8. Import database
/usr/local/bin/migration-helpers/connect-rds.sh
# In MySQL:
CREATE DATABASE tenant_name_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE tenant_name_db;
SOURCE /tmp/migration/database.sql;
EXIT;

# 9. WP-CLI search-replace
wp --path=/mnt/efs/tenant-name search-replace 'oldsite.com' 'newsite.com' --dry-run
wp --path=/mnt/efs/tenant-name search-replace 'oldsite.com' 'newsite.com'

# 10. Verify
wp --path=/mnt/efs/tenant-name core version
wp --path=/mnt/efs/tenant-name plugin list

# 11. Exit and stop
exit
./stop-bastion.sh dev
```

### Workflow 2: Database-Only Operations

```bash
./start-bastion.sh dev
./connect-bastion.sh dev

/usr/local/bin/migration-helpers/connect-rds.sh

# Run SQL
USE tenant_db;
UPDATE wp_options SET option_value='https://newsite.com' WHERE option_name='siteurl';

# Export backup
mysqldump -h <endpoint> -u <user> -p tenant_db > /tmp/backup.sql
aws s3 cp /tmp/backup.sql s3://bbws-migration-artifacts-dev/backups/

EXIT;
exit
./stop-bastion.sh dev
```

### Workflow 3: WP-CLI Batch Operations

```bash
./start-bastion.sh dev
./connect-bastion.sh dev

/usr/local/bin/migration-helpers/mount-efs.sh

# Update all plugins across tenants
for tenant in /mnt/efs/*/; do
    echo "Updating: $tenant"
    wp plugin update --all --path="$tenant"
    wp cache flush --path="$tenant"
done

exit
./stop-bastion.sh dev
```

## Security Considerations

### 1. No SSH Access
- Bastion uses SSM Session Manager only
- No SSH keys to manage or rotate
- No port 22 exposed

### 2. Least-Privilege IAM
- Instance role has minimum required permissions
- Cannot modify infrastructure (only read RDS/EFS)
- Conditional policies limit scope

### 3. Security Group Isolation
- No inbound rules (all access via SSM outbound HTTPS)
- Egress only to specific targets: RDS, EFS, AWS APIs
- Cannot access internet except AWS endpoints

### 4. Audit Trail
- All SSM sessions logged to CloudWatch
- User data bootstrap logged
- CloudWatch agent captures system logs
- DynamoDB tracks session activity

### 5. Encryption
- EBS root volume encrypted at rest
- EFS mounted with TLS in-transit encryption
- Secrets Manager for RDS credentials

## Troubleshooting

### Issue: Cannot connect via SSM

**Symptoms:**
```
TargetNotConnected: i-1234567890abcdef0 is not connected
```

**Solutions:**
1. Check instance is running: `./start-bastion.sh dev`
2. Verify SSM agent: `aws ssm describe-instance-information --instance-id <id>`
3. Check IAM instance profile attached
4. Review CloudWatch logs: `/aws/ec2/bastion-dev`

### Issue: EFS mount fails

**Symptoms:**
```
mount.nfs: Connection timed out
```

**Solutions:**
1. Verify security group allows NFS (2049) from bastion
2. Check EFS mount targets exist in VPC
3. Test connectivity: `telnet <mount-target-ip> 2049`
4. Manual mount: `sudo mount -t efs -o tls <efs-id> /mnt/efs`

### Issue: RDS connection refused

**Symptoms:**
```
ERROR 2003: Can't connect to MySQL server
```

**Solutions:**
1. Verify security group allows MySQL (3306) from bastion
2. Check RDS endpoint resolves: `nslookup <rds-endpoint>`
3. Test connectivity: `telnet <rds-endpoint> 3306`
4. Verify Secrets Manager credentials

### Issue: Bastion not auto-stopping

**Solutions:**
1. Check Lambda function exists and enabled
2. Review Lambda logs: `/aws/lambda/dev-bastion-auto-shutdown`
3. Verify EventBridge rule active
4. Check instance tags: `ManagedBy: bastion-auto-shutdown`

## Cost Optimization

### Monthly Cost Breakdown

**Always-On Bastion:**
- EC2 (t3a.micro 24/7): $6.86
- EBS (20GB GP3): $1.60
- **Total: $8.46/month**

**With Auto-Shutdown (8 hrs/month):**
- EC2 (t3a.micro 8 hrs): $0.08
- EBS (20GB GP3): $1.60
- Lambda executions: $0.02
- **Total: $1.70/month**

**Savings: 80%**

### Best Practices
1. Stop bastion immediately after migration
2. Use auto-shutdown (don't rely on manual stop)
3. Review CloudWatch logs monthly for usage patterns
4. Consider reducing idle timeout if migrations are quick

## Lessons Learned (Au Pair Hive Case Study)

### What Didn't Work (ECS Exec)
- ❌ 20-30 minute session timeouts (despite increasing SSM limits)
- ❌ Constant "EOF" errors requiring reconnection
- ❌ Heredoc syntax failures breaking multi-line SQL scripts
- ❌ 8-10 hour migration time with heavy troubleshooting
- ❌ Lost progress on long-running operations

### What Worked (Bastion)
- ✅ Zero session timeouts or EOF errors
- ✅ Full heredoc support for complex SQL scripts
- ✅ Persistent sessions for multi-hour operations
- ✅ Better performance (native EC2 vs containerized)
- ✅ Complete system access for debugging
- ✅ Comprehensive CloudWatch audit trail
- ✅ 80% cost reduction with auto-shutdown

## Integration Points

### With Migration Playbook
- Bastion replaces ECS exec in WordPress migration playbook
- Section 2 documents bastion usage
- All migration workflows updated to use bastion

### With Terraform Infrastructure
- Bastion module integrated in main.tf
- Security groups updated to allow bastion access
- Outputs expose connection commands

### With Lambda Auto-Shutdown
- DynamoDB tracks session state
- EventBridge triggers checks every 5 minutes
- SNS sends notifications on shutdown

### With Helper Scripts
- Start/stop/connect scripts in migrations repo
- On-bastion helpers for EFS and RDS
- Integration with S3 migration artifacts

## Testing & Validation

### Unit Tests (Lambda)
- Test idle detection logic
- Test DynamoDB session updates
- Test EC2 stop calls
- Test SNS notifications
- Test error handling

### Integration Tests
1. Start bastion → connect → mount EFS → verify
2. Idle timeout → auto-shutdown → notification
3. Active SSM session → prevents shutdown
4. High CPU → prevents shutdown

### Manual Testing
```bash
# Invoke Lambda manually
aws lambda invoke \
  --function-name dev-bastion-auto-shutdown \
  --region eu-west-1 \
  response.json

# Tail Lambda logs
aws logs tail /aws/lambda/dev-bastion-auto-shutdown --follow
```

## Documentation References

### Primary Docs
- **[Bastion Operations Guide](../../../tenant/migrations/runbooks/bastion_operations_guide.md)** - Complete operational manual
- **[WordPress Migration Playbook](../../../tenant/migrations/runbooks/wordpress_migration_playbook_automated.md)** - Integration with migrations
- **[Bastion Terraform Module README](../../../../2_bbws_ecs_terraform/terraform/modules/bastion/README.md)** - Infrastructure details
- **[Lambda Auto-Shutdown README](../../../../2_bbws_bastion_auto_shutdown/README.md)** - Auto-shutdown mechanism

### AWS Docs
- [SSM Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html)
- [EFS Mounting](https://docs.aws.amazon.com/efs/latest/ug/mounting-fs.html)
- [Secrets Manager](https://docs.aws.amazon.com/secretsmanager/)

### Tool Docs
- [WP-CLI](https://wp-cli.org/)
- [MySQL Client](https://dev.mysql.com/doc/refman/8.0/en/mysql.html)

## Skill Application Checklist

Before using this skill, ensure:
- [ ] AWS CLI configured with appropriate profiles
- [ ] SSM Session Manager plugin installed
- [ ] Terraform bastion module deployed
- [ ] Lambda auto-shutdown deployed
- [ ] Helper scripts are executable
- [ ] S3 migration artifacts bucket exists
- [ ] Bastion security groups configured
- [ ] CloudWatch log groups created

During application:
- [ ] Start bastion before migration
- [ ] Connect via SSM (not SSH)
- [ ] Use on-bastion helper scripts
- [ ] Stop bastion after completion
- [ ] Verify auto-shutdown configured
- [ ] Check CloudWatch logs for audit

## Success Metrics

Track these metrics to validate skill application:

1. **Reliability:** 100% migration success rate (no EOF errors)
2. **Performance:** Migration time < 60 minutes (vs 8-10 hours)
3. **Cost:** Monthly bastion cost < $2/month
4. **Security:** Zero unauthorized access attempts
5. **Automation:** Auto-shutdown triggers 95%+ of stops

## Next Steps for Skill Enhancement

1. **Port Forwarding:** Add SSM port forwarding for GUI tools
2. **Session Recording:** Enable SSM session recording for compliance
3. **Multi-Region:** Deploy bastion in PROD region (af-south-1)
4. **Terraform Testing:** Add automated tests for bastion module
5. **Monitoring Dashboard:** Create CloudWatch dashboard for bastion metrics

---

**Skill Status:** Production-Ready ✅
**Tested Environments:** DEV, SIT
**Production Deployments:** Pending first PROD migration
**Feedback:** Share lessons learned and improvements with DevOps team
