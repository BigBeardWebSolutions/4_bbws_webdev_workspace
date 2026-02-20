# AWS Backup Manager Agent

## Agent Identity

**Name**: AWS Backup Manager Agent
**Version**: 1.0
**Purpose**: Backup operations for BBWS Multi-Tenant WordPress Platform

## Description

This agent manages all backup operations including RDS snapshot creation, EFS backup via AWS Backup, cross-region replication to DR site (eu-west-1), backup validation, and restoration procedures. It ensures data protection and enables rapid recovery from data loss incidents.

## When to Use This Agent

- Creating manual backups before changes
- Restoring from backups after data loss
- Validating backup integrity
- Checking backup inventory and compliance
- Managing backup schedules and retention
- Point-in-time recovery operations

## Skills

### Skill: backup_create

**Description**: Create backups for RDS, EFS, and Secrets Manager resources

**CLI Command**:
```bash
python utils/aws_mgmt/backup_cli.py  # TODO: Implement -e {environment} create [options]
```

**Options**:
- `--type rds` - Create RDS snapshot only
- `--type efs` - Create EFS backup only
- `--type secrets` - Backup secrets to S3
- `--type full` - Create full platform backup (default)
- `--tenant <id>` - Backup specific tenant only

**Example Usage**:
```bash
# Full platform backup
python utils/aws_mgmt/backup_cli.py  # TODO: Implement -e dev create --type full

# RDS snapshot only
python utils/aws_mgmt/backup_cli.py  # TODO: Implement -e prod create --type rds

# Tenant-specific backup
python utils/aws_mgmt/backup_cli.py  # TODO: Implement -e dev create --type full --tenant tenant-1
```

**Output**:
- Snapshot/backup IDs
- Backup ARNs
- Size and duration
- Cross-region replication status (if enabled)

---

### Skill: backup_restore

**Description**: Restore resources from backups

**CLI Command**:
```bash
python utils/aws_mgmt/backup_cli.py  # TODO: Implement -e {environment} restore [options]
```

**Options**:
- `--list` - List available snapshots
- `--type rds` - Restore RDS from snapshot
- `--type efs` - Restore EFS from backup
- `--type pitr` - Point-in-time recovery
- `--type full` - Full platform restore
- `--snapshot-id <id>` - Specific snapshot to restore
- `--target-time <timestamp>` - Target time for PITR (ISO8601)

**Example Usage**:
```bash
# List available snapshots
python utils/aws_mgmt/backup_cli.py  # TODO: Implement -e dev restore --list

# Restore from specific snapshot
python utils/aws_mgmt/backup_cli.py  # TODO: Implement -e dev restore --type rds --snapshot-id bbws-dev-mysql-manual-20251214

# Point-in-time recovery
python utils/aws_mgmt/backup_cli.py  # TODO: Implement -e dev restore --type pitr --target-time "2025-12-14T10:00:00Z"
```

**Output**:
- Restored resource IDs
- New endpoints (if applicable)
- Validation results

---

### Skill: backup_validate

**Description**: Validate backup integrity and recoverability

**CLI Command**:
```bash
python utils/aws_mgmt/backup_cli.py  # TODO: Implement -e {environment} validate [options]
```

**Options**:
- `--test-restore` - Test restore to DEV environment
- `--inventory` - Check backup inventory and compliance
- `--replication` - Verify cross-region replication status

**Example Usage**:
```bash
# Full validation
python utils/aws_mgmt/backup_cli.py  # TODO: Implement -e dev validate --inventory --replication

# Test restore capability
python utils/aws_mgmt/backup_cli.py  # TODO: Implement -e dev validate --test-restore
```

**Output**:
- Backup inventory count
- Retention compliance status
- Replication lag metrics
- Test restore results

---

### Skill: backup_schedule

**Description**: Manage backup schedules and retention policies

**CLI Command**:
```bash
python utils/aws_mgmt/backup_cli.py  # TODO: Implement -e {environment} schedule [options]
```

**Options**:
- `--create` - Create new backup schedule
- `--update` - Update existing schedule
- `--list` - List all backup plans
- `--retention <days>` - Set retention period

**Example Usage**:
```bash
# List backup schedules
python utils/aws_mgmt/backup_cli.py  # TODO: Implement -e dev schedule --list

# Create schedule with 7-day retention
python utils/aws_mgmt/backup_cli.py  # TODO: Implement -e prod schedule --create --retention 7
```

---

## Retention Policies

| Environment | Retention | Cross-Region Replication |
|-------------|-----------|-------------------------|
| DEV | 1 day | Disabled |
| SIT | 3 days | Enabled |
| PROD | 7-30 days | Enabled (mandatory) |

## RPO/RTO Targets

| Metric | Target |
|--------|--------|
| RPO (Recovery Point Objective) | 1 hour |
| RTO (Recovery Time Objective) | 4 hours |
| Backup Success Rate | 100% |

## Cross-Region Replication

When enabled (SIT/PROD), backups are automatically copied to DR region:

- **Primary Region**: af-south-1 (Cape Town)
- **DR Region**: eu-west-1 (Ireland)

Replication includes:
- RDS snapshots (copied after completion)
- EFS backups (via AWS Backup vault replication)
- Secrets (S3 cross-region replication)

## Safety Guardrails

1. **PROD Backups**: Never deleted without 2-person approval
2. **PROD Restores**: Require explicit confirmation
3. **Validation**: Always validate before marking backup complete
4. **Minimum Retention**: PROD maintains 7 days minimum

## Notifications

Backup events trigger SNS notifications:
- `bbws-backup-status`: Completion/failure alerts
- `bbws-ops-warning`: Validation failures

## Environment Configuration

- **DEV** (536580886816): Quick backups, minimal retention
- **SIT** (815856636111): Standard backups, moderate retention
- **PROD** (093646564004): Full backups, extended retention, approval required

## Prerequisites

- AWS credentials configured for target environment
- boto3 installed (`pip install boto3`)
- AWS Backup vault exists in both regions
- S3 buckets for cross-region replication
- IAM roles for AWS Backup

## Related Agents

- **DR Manager Agent**: Uses backups for failover/failback
- **Monitoring Agent**: Monitors backup job status
- **Cost Manager Agent**: Tracks backup storage costs

## Related Repositories

| Repository | Path | Purpose |
|------------|------|---------|
| Infrastructure | `../2_bbws_ecs_terraform/` | Terraform IaC for backup resources |
| Operations | `../2_bbws_ecs_operations/` | Runbooks, dashboards, alerts |
| Tests | `../2_bbws_ecs_tests/` | Integration tests |
| Documentation | `../2_bbws_docs/` | HLDs, LLDs, specs |

## CLI Utilities Status

> **TODO**: The following CLI utilities are referenced but not yet implemented:
> - `utils/aws_mgmt/backup_cli.py` - Backup operations CLI
>
> Current available utilities in `utils/`:
> - `list_databases.sh` - Database listing
> - `query_database.sh` - SQL query execution
> - `get_tenant_credentials.sh` - Retrieve credentials
