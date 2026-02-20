# Tenant Migration Utility - User Guide

Comprehensive guide for using the tenant migration utility with rollback support.

## Overview

The `tenant_migration.py` utility provides a general-purpose framework for migrating WordPress tenants between configurations with automatic rollback on failure.

**Key Features:**
- ✅ Multi-step migration with validation
- ✅ Automatic rollback on failure
- ✅ State tracking and logging
- ✅ Dry-run mode for testing
- ✅ Batch migration support
- ✅ Environment-agnostic (dev/sit/prod)

## Installation

### Prerequisites

```bash
# Python 3.7+
python3 --version

# AWS CLI configured with profiles
aws configure list-profiles

# Required Python packages
pip install boto3
```

### Setup

```bash
# Make script executable
chmod +x utils/tenant_migration.py

# Verify installation
python3 utils/tenant_migration.py --help
```

## Configuration Files

Migration behavior is controlled by JSON configuration files.

### Configuration Structure

```json
{
  "alb_listener_arn": "arn:aws:elasticloadbalancing:...",
  "alb_rule_priority": 10,
  "old_host_header": "tenant1.old-domain.com",
  "new_host_header": "tenant1.new-domain.com",
  "cluster": "dev-cluster",
  "service_prefix": "dev",
  "task_definition_updates": {
    "ENVIRONMENT_VARIABLE": "new_value"
  },
  "route53_zone_id": "Z0123456789ABC",
  "old_dns_record": "tenant1.old-domain.com",
  "new_dns_record": "tenant1.new-domain.com",
  "dns_target": "d111111abcdef8.cloudfront.net",
  "region": "eu-west-1",
  "aws_profile": "Tebogo-dev"
}
```

### Configuration Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `alb_listener_arn` | string | No | ALB listener ARN for routing rules |
| `alb_rule_priority` | integer | No | Priority of ALB listener rule |
| `old_host_header` | string | No | Current host header value |
| `new_host_header` | string | No | New host header value |
| `cluster` | string | No | ECS cluster name |
| `service_prefix` | string | No | ECS service name prefix |
| `task_definition_updates` | object | No | Environment variables to update |
| `route53_zone_id` | string | No | Route53 hosted zone ID |
| `old_dns_record` | string | No | Current DNS record name |
| `new_dns_record` | string | No | New DNS record name |
| `dns_target` | string | No | DNS record target (CloudFront/ALB) |
| `region` | string | Yes | AWS region |
| `aws_profile` | string | No | AWS CLI profile name |

## Usage

### Basic Migration

Migrate a single tenant:

```bash
python3 utils/tenant_migration.py migrate \
  --tenant goldencrust \
  --from-config examples/migration_config_old.json \
  --to-config examples/migration_config_new.json
```

### Dry Run

Test migration without making changes:

```bash
python3 utils/tenant_migration.py migrate \
  --tenant goldencrust \
  --from-config examples/migration_config_old.json \
  --to-config examples/migration_config_new.json \
  --dry-run
```

### Batch Migration

Migrate multiple tenants:

```bash
python3 utils/tenant_migration.py migrate-batch \
  --tenants tenant1,tenant2,goldencrust \
  --from-config examples/migration_config_old.json \
  --to-config examples/migration_config_new.json
```

### Rollback

Rollback a failed migration:

```bash
python3 utils/tenant_migration.py rollback \
  --migration-id migration-goldencrust-abc12345
```

## Migration Steps

The utility executes the following steps in order:

1. **Validation** - Verify all prerequisites exist
2. **Backup** - Save current state for rollback
3. **ALB Update** - Update ALB listener rule with new host header
4. **Task Definition Update** - Update ECS task definition with new environment variables
5. **Service Update** - Deploy new task definition to ECS service
6. **DNS Update** - Update Route53 DNS records
7. **Verification** - Verify migration success

If any step fails, automatic rollback is initiated.

## Common Use Cases

### Use Case 1: DNS Migration (nip.io → wpdev.kimmyai.io)

**Scenario:** Migrate tenant from nip.io wildcard DNS to proper subdomain

**from-config.json:**
```json
{
  "alb_listener_arn": "arn:aws:elasticloadbalancing:eu-west-1:536580886816:listener/app/dev-alb/...",
  "alb_rule_priority": 10,
  "old_host_header": "tenant1.*.nip.io",
  "cluster": "dev-cluster",
  "service_prefix": "dev",
  "region": "eu-west-1",
  "aws_profile": "Tebogo-dev"
}
```

**to-config.json:**
```json
{
  "alb_listener_arn": "arn:aws:elasticloadbalancing:eu-west-1:536580886816:listener/app/dev-alb/...",
  "alb_rule_priority": 10,
  "new_host_header": "tenant1.wpdev.kimmyai.io",
  "cluster": "dev-cluster",
  "service_prefix": "dev",
  "task_definition_updates": {
    "WORDPRESS_CONFIG_EXTRA": "define('WP_HOME', 'https://tenant1.wpdev.kimmyai.io'); define('WP_SITEURL', 'https://tenant1.wpdev.kimmyai.io');"
  },
  "route53_zone_id": "Z0123456789ABC",
  "new_dns_record": "tenant1.wpdev.kimmyai.io",
  "dns_target": "d111111abcdef8.cloudfront.net",
  "region": "eu-west-1",
  "aws_profile": "Tebogo-dev"
}
```

**Command:**
```bash
python3 utils/tenant_migration.py migrate \
  --tenant tenant1 \
  --from-config from-config.json \
  --to-config to-config.json
```

### Use Case 2: Environment Promotion (DEV → SIT)

**Scenario:** Promote tenant from DEV to SIT environment

**from-config.json:**
```json
{
  "cluster": "dev-cluster",
  "service_prefix": "dev",
  "old_host_header": "tenant1.wpdev.kimmyai.io",
  "route53_zone_id": "Z0123456789ABC",
  "old_dns_record": "tenant1.wpdev.kimmyai.io",
  "region": "eu-west-1",
  "aws_profile": "Tebogo-dev"
}
```

**to-config.json:**
```json
{
  "alb_listener_arn": "arn:aws:elasticloadbalancing:eu-west-1:815856636111:listener/app/sit-alb/...",
  "alb_rule_priority": 10,
  "new_host_header": "tenant1.wpsit.kimmyai.io",
  "cluster": "sit-cluster",
  "service_prefix": "sit",
  "task_definition_updates": {
    "WORDPRESS_CONFIG_EXTRA": "define('WP_HOME', 'https://tenant1.wpsit.kimmyai.io'); define('WP_SITEURL', 'https://tenant1.wpsit.kimmyai.io');"
  },
  "route53_zone_id": "Z9876543210XYZ",
  "new_dns_record": "tenant1.wpsit.kimmyai.io",
  "dns_target": "d222222abcdef8.cloudfront.net",
  "region": "eu-west-1",
  "aws_profile": "Tebogo-sit"
}
```

**Command:**
```bash
# Test first with dry-run
python3 utils/tenant_migration.py migrate \
  --tenant tenant1 \
  --from-config from-config.json \
  --to-config to-config.json \
  --dry-run

# Execute migration
python3 utils/tenant_migration.py migrate \
  --tenant tenant1 \
  --from-config from-config.json \
  --to-config to-config.json
```

### Use Case 3: WordPress Configuration Update

**Scenario:** Update WordPress environment variables without DNS changes

**from-config.json:**
```json
{
  "cluster": "dev-cluster",
  "service_prefix": "dev",
  "region": "eu-west-1",
  "aws_profile": "Tebogo-dev"
}
```

**to-config.json:**
```json
{
  "cluster": "dev-cluster",
  "service_prefix": "dev",
  "task_definition_updates": {
    "WORDPRESS_DEBUG": "false",
    "WORDPRESS_CONFIG_EXTRA": "define('WP_MEMORY_LIMIT', '256M'); define('WP_MAX_MEMORY_LIMIT', '512M');"
  },
  "region": "eu-west-1",
  "aws_profile": "Tebogo-dev"
}
```

**Command:**
```bash
python3 utils/tenant_migration.py migrate \
  --tenant tenant1 \
  --from-config from-config.json \
  --to-config to-config.json
```

## Migration State Tracking

Migration state is saved to `/tmp/migration-{tenant}-{id}.json`:

```json
{
  "migration_id": "migration-goldencrust-abc12345",
  "tenant": "goldencrust",
  "status": "completed",
  "started_at": "2024-12-21T10:00:00",
  "completed_at": "2024-12-21T10:05:00",
  "steps_completed": [
    "validation",
    "backup",
    "alb_update",
    "task_definition_update",
    "service_update",
    "dns_update",
    "verification"
  ],
  "rollback_data": {
    "alb_rule": {...},
    "ecs_service": {...},
    "dns_record": {...}
  },
  "error_message": null
}
```

## Troubleshooting

### Migration Fails at Validation Step

**Error:** `Service dev-tenant1-service not found or not active`

**Solution:**
1. Verify service exists: `aws ecs describe-services --cluster dev-cluster --services dev-tenant1-service --profile Tebogo-dev`
2. Check service status is ACTIVE
3. Verify cluster name in configuration matches actual cluster

### Migration Fails at Service Update Step

**Error:** `Service did not stabilize within timeout`

**Solution:**
1. Check ECS task logs in CloudWatch
2. Verify task definition is valid
3. Check resource limits (CPU/memory)
4. Service may still be deploying - wait and check manually

### Rollback Fails

**Error:** `Rollback failed: manual intervention required`

**Solution:**
1. Check migration state file in `/tmp/migration-{tenant}-{id}.json`
2. Manually revert changes using saved `rollback_data`
3. For ALB: Restore old host header
4. For ECS: Redeploy old task definition
5. For DNS: Restore old DNS record

### Permission Errors

**Error:** `AccessDenied: User is not authorized to perform...`

**Solution:**
1. Verify AWS profile has necessary permissions
2. Check IAM policies for ECS, ELB, Route53 access
3. Ensure cross-account roles are configured for multi-environment migrations

## Best Practices

1. **Always Test with Dry Run First**
   ```bash
   python3 utils/tenant_migration.py migrate --tenant test --from-config old.json --to-config new.json --dry-run
   ```

2. **Migrate in Batches**
   - Start with 1-3 tenants as a pilot
   - Validate success before proceeding
   - Gradually increase batch size

3. **Monitor Service Health**
   ```bash
   # Check service status
   aws ecs describe-services --cluster dev-cluster --services dev-tenant1-service --profile Tebogo-dev

   # Check target health
   aws elbv2 describe-target-health --target-group-arn arn:aws:... --profile Tebogo-dev
   ```

4. **Backup Before Migration**
   - Database backup: `mysqldump`
   - File backup: EFS snapshot or S3 sync
   - Configuration backup: Export task definition and ALB rules

5. **Keep Migration Logs**
   ```bash
   python3 utils/tenant_migration.py migrate ... 2>&1 | tee migration-$(date +%Y%m%d-%H%M%S).log
   ```

6. **Verify After Migration**
   ```bash
   # Test tenant URL
   curl -I https://tenant1.wpdev.kimmyai.io

   # Check WordPress admin
   curl -I https://tenant1.wpdev.kimmyai.io/wp-admin
   ```

## Security Considerations

- **Credentials:** Never commit configuration files with ARNs/IDs to version control
- **AWS Profiles:** Use separate profiles with least-privilege IAM policies
- **State Files:** Migration state files may contain sensitive information
- **Logging:** Ensure logs don't expose credentials or secrets

## Support

For issues or questions:
1. Check migration state file: `/tmp/migration-{tenant}-{id}.json`
2. Review CloudWatch logs for ECS tasks
3. Examine ALB target health status
4. Contact DevOps team with migration ID for assistance

## Examples Directory

Pre-configured example files available in `utils/examples/`:
- `migration_config_example_old.json` - Source configuration template
- `migration_config_example_new.json` - Target configuration template
- `env_migration_dev_to_sit.json` - Environment promotion example

---

**Version:** 1.0.0
**Author:** Big Beard Web Solutions
**Last Updated:** December 2024
