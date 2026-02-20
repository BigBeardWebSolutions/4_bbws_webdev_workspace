# AWS Infrastructure and Tenant Monitoring Agent

## Agent Identity

**Name**: AWS Infra + Tenant Monitoring Agent
**Version**: 1.0
**Purpose**: Comprehensive monitoring for BBWS Multi-Tenant WordPress Platform

## Description

This agent provides real-time infrastructure and tenant-level health monitoring, CloudWatch alarm management, dashboard creation, incident response automation, and SLA reporting for the BBWS platform.

## When to Use This Agent

- Daily health checks of infrastructure components
- Investigating performance issues or incidents
- Setting up or managing CloudWatch alarms
- Creating monitoring dashboards
- Generating SLA and health reports
- Responding to alerts and incidents

## Skills

### Skill: monitor_infra_health

**Description**: Check health of infrastructure components (ECS, RDS, EFS, ALB, Network)

**CLI Command**:
```bash
python utils/aws_mgmt/monitoring_cli.py  # TODO: Implement -e {environment} infra-health [options]
```

**Options**:
- `--all` - Check all components
- `--ecs` - Check ECS cluster only
- `--rds` - Check RDS instance only
- `--efs` - Check EFS file system only
- `--alb` - Check Application Load Balancer only
- `--network` - Check VPC and network only

**Example Usage**:
```bash
# Check all infrastructure
python utils/aws_mgmt/monitoring_cli.py  # TODO: Implement -e dev infra-health --all

# Check only database and storage
python utils/aws_mgmt/monitoring_cli.py  # TODO: Implement -e prod infra-health --rds --efs
```

**Output**: Health status for each component with metrics and issues

---

### Skill: monitor_tenant_health

**Description**: Check health of individual tenant WordPress instances

**CLI Command**:
```bash
python utils/aws_mgmt/monitoring_cli.py  # TODO: Implement -e {environment} tenant-health [options]
```

**Options**:
- `--tenant <id>` - Check specific tenant
- `--all` - Check all tenants
- `--availability` - Check availability only
- `--performance` - Check performance only

**Example Usage**:
```bash
# Check specific tenant
python utils/aws_mgmt/monitoring_cli.py  # TODO: Implement -e dev tenant-health --tenant tenant-1

# Check all tenants
python utils/aws_mgmt/monitoring_cli.py  # TODO: Implement -e prod tenant-health --all
```

**Output**: Tenant availability, response times, resource usage

---

### Skill: alarm_manage

**Description**: Create and manage CloudWatch alarms

**CLI Command**:
```bash
python utils/aws_mgmt/monitoring_cli.py  # TODO: Implement -e {environment} alarm [options]
```

**Options**:
- `--create` - Create new alarm
- `--status` - List all alarms and their states
- `--suppress` - Temporarily suppress alarm
- `--name <name>` - Alarm name

**Example Usage**:
```bash
# List all alarms
python utils/aws_mgmt/monitoring_cli.py  # TODO: Implement -e dev alarm --status

# Suppress alarm for maintenance
python utils/aws_mgmt/monitoring_cli.py  # TODO: Implement -e dev alarm --suppress --name "RDS-CPU-High"
```

**Output**: Alarm list with states, or confirmation of action

---

### Skill: dashboard_manage

**Description**: Create and manage CloudWatch dashboards

**CLI Command**:
```bash
python utils/aws_mgmt/monitoring_cli.py  # TODO: Implement -e {environment} dashboard [options]
```

**Options**:
- `--create` - Create new dashboard
- `--template <name>` - Use dashboard template (platform, tenant, cost, security)
- `--update` - Update existing dashboard
- `--share` - Generate shareable link

**Example Usage**:
```bash
# Create platform overview dashboard
python utils/aws_mgmt/monitoring_cli.py  # TODO: Implement -e dev dashboard --template platform
```

---

### Skill: incident_respond

**Description**: Automated incident response and remediation

**CLI Command**:
```bash
python utils/aws_mgmt/monitoring_cli.py  # TODO: Implement -e {environment} incident [options]
```

**Options**:
- `--remediate` - Execute auto-remediation
- `--escalate` - Trigger escalation
- `--log` - Log incident
- `--report <id>` - Generate incident report

**Auto-Remediation Actions**:
- ECS task unhealthy → Force new deployment
- EFS burst credits low → Alert (manual switch to provisioned)
- RDS connections high → Connection pooling warning
- ALB 5XX spike → Check target health

---

### Skill: report_generate

**Description**: Generate monitoring and SLA reports

**CLI Command**:
```bash
python utils/aws_mgmt/monitoring_cli.py  # TODO: Implement -e {environment} report [options]
```

**Options**:
- `--daily` - Daily health report
- `--weekly` - Weekly SLA report
- `--monthly` - Monthly executive report
- `--tenant <id>` - Tenant-specific report
- `--format <type>` - Output format (markdown, json, csv)

**Example Usage**:
```bash
# Generate daily report
python utils/aws_mgmt/monitoring_cli.py  # TODO: Implement -e dev report --daily

# Generate tenant report
python utils/aws_mgmt/monitoring_cli.py  # TODO: Implement -e prod report --tenant tenant-1 --format json
```

---

## Alarm Thresholds

| Component | Metric | DEV | SIT | PROD |
|-----------|--------|-----|-----|------|
| ECS | CPU % | 90 | 85 | 80 |
| ECS | Memory % | 90 | 85 | 80 |
| RDS | CPU % | 85 | 80 | 75 |
| RDS | Storage GB | 3 | 5 | 10 |
| RDS | Connections | 50 | 80 | 100 |
| EFS | Burst Credits GB | 50 | 80 | 100 |
| ALB | 5XX Count | 20 | 15 | 10 |
| ALB | Latency (sec) | 3 | 2 | 1 |

## Escalation Matrix

| Severity | Response Time | Actions |
|----------|---------------|---------|
| P1 Critical | 5 min | SNS + PagerDuty + Phone |
| P2 High | 15 min | SNS + PagerDuty |
| P3 Medium | 1 hour | SNS + Email |
| P4 Low | 24 hours | Log only |

## Environment Configuration

- **DEV** (536580886816): Relaxed thresholds, minimal retention
- **SIT** (815856636111): Standard thresholds, moderate retention
- **PROD** (093646564004): Strict thresholds, extended retention, read-only

## Prerequisites

- AWS credentials configured for target environment
- boto3 installed (`pip install boto3`)
- CloudWatch, SNS access permissions
- DynamoDB table for state management (optional)

## Related Agents

- **Backup Manager Agent**: For backup-related health checks
- **Cost Manager Agent**: For cost-related monitoring
- **DR Manager Agent**: For DR health and replication status

## Related Repositories

| Repository | Path | Purpose |
|------------|------|---------|
| Infrastructure | `../2_bbws_ecs_terraform/` | Terraform for CloudWatch resources |
| Operations | `../2_bbws_ecs_operations/` | Dashboards, alerts, runbooks |
| Tests | `../2_bbws_ecs_tests/` | Monitoring integration tests |
| Documentation | `../2_bbws_docs/` | Monitoring specs, HLDs |

## CLI Utilities Status

> **TODO**: The following CLI utilities are referenced but not yet implemented:
> - `utils/aws_mgmt/monitoring_cli.py` - Monitoring operations CLI
>
> Current available utilities in `utils/`:
> - `list_databases.sh` - Database health listing
> - `verify_tenant_isolation.sh` - Tenant isolation verification
