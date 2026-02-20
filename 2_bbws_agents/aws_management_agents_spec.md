# AWS Management Agents Specification

**Version**: 1.0
**Date**: 2025-12-14
**Status**: Draft - Pending Approval
**Author**: Agentic Architect

---

## Document Purpose

This specification defines four AWS Management Agents for the BBWS Multi-Tenant WordPress Platform:

1. **AWS Backup Manager Agent** - Backup creation, restoration, and cross-region replication
2. **AWS DR Manager Agent** - Disaster recovery failover and failback operations
3. **AWS Cost Manager Agent** - Cost reporting, budget forecasting, and budget actions
4. **AWS Infra + Tenant Monitoring Agent** - Infrastructure and tenant health monitoring

Each agent follows the Claude Code agent pattern with embedded skills and Python CLI utilities.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     AWS Management Agents Layer                          │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐       │
│  │  Backup Manager  │  │   DR Manager     │  │  Cost Manager    │       │
│  │      Agent       │  │     Agent        │  │     Agent        │       │
│  └────────┬─────────┘  └────────┬─────────┘  └────────┬─────────┘       │
│           │                     │                     │                  │
│  ┌────────┴─────────────────────┴─────────────────────┴────────┐        │
│  │                   Monitoring Agent                            │        │
│  │         (Infra + Tenant Health & Alerting)                   │        │
│  └──────────────────────────────────────────────────────────────┘        │
│                                                                          │
├─────────────────────────────────────────────────────────────────────────┤
│                      Python CLI Utilities Layer                          │
│                      (.claude/utils/aws_mgmt/)                           │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  backup_cli.py    dr_cli.py    cost_cli.py    monitoring_cli.py         │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                          AWS Services                                    │
├─────────────────────────────────────────────────────────────────────────┤
│ AWS Backup │ RDS Snapshots │ EFS Backup │ S3 Replication │ Route53     │
│ CloudWatch │ SNS │ Cost Explorer │ Budgets │ Health Dashboard           │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Environment Configuration

All agents operate across three AWS environments with built-in account validation:

| Environment | AWS Account ID | Primary Region | DR Region |
|-------------|---------------|----------------|-----------|
| **DEV** | 536580886816 | af-south-1 | eu-west-1 |
| **SIT** | 815856636111 | af-south-1 | eu-west-1 |
| **PROD** | 093646564004 | af-south-1 | eu-west-1 |

**Critical Safety Rule**: All agents MUST validate AWS account ID matches intended environment before any operation.

---

# Agent 1: AWS Backup Manager Agent

## 1.1 Identity and Purpose

```
Agent Name: AWS Backup Manager Agent (BBWS Multi-Tenant WordPress)

Primary Purpose:
This agent manages all backup operations for the BBWS multi-tenant WordPress platform.
It creates, validates, restores, and replicates backups across regions for RDS databases,
EFS file systems, and Secrets Manager secrets. The agent ensures data protection and
enables rapid recovery from data loss incidents.

Value Provided:
- Automated backup creation with configurable retention policies
- Cross-region replication to DR site (eu-west-1)
- Backup validation and integrity verification
- Point-in-time recovery for databases
- Tenant-specific backup and restore operations
- Compliance with RPO requirements (1 hour)
```

## 1.2 Core Capabilities (Skills)

### Skill: backup_create
**Description**: Create backups for RDS, EFS, and Secrets Manager resources

**Operations**:
```yaml
backup_create:
  rds_snapshot:
    - Create manual RDS snapshot with timestamp
    - Tag snapshot with environment, tenant, backup_type
    - Verify snapshot completion
    - Copy snapshot to DR region (eu-west-1)

  efs_backup:
    - Initiate AWS Backup job for EFS
    - Tag backup with environment, tenant
    - Verify backup completion
    - Replicate to DR vault in eu-west-1

  secrets_backup:
    - Export secrets to encrypted S3 bucket
    - Replicate to DR region S3 bucket
    - Maintain secret version history

  full_platform_backup:
    - Orchestrate RDS + EFS + Secrets backup
    - Create backup manifest in DynamoDB
    - Verify all components completed
    - Send completion notification via SNS
```

**CLI Command**: `python .claude/utils/aws_mgmt/backup_cli.py create [--type rds|efs|secrets|full] [--tenant <tenant_id>]`

### Skill: backup_restore
**Description**: Restore resources from backups

**Operations**:
```yaml
backup_restore:
  rds_restore:
    - List available snapshots (by tenant/date)
    - Restore to new RDS instance (test) or replace existing
    - Validate restored database connectivity
    - Update Secrets Manager with new endpoint if needed

  efs_restore:
    - List available EFS recovery points
    - Restore to new EFS or specific access point
    - Validate file system mount
    - Verify tenant data integrity

  pitr_restore:
    - Point-in-time recovery for RDS
    - Specify exact timestamp for recovery
    - Create new instance from PITR
    - Validate and swap if requested

  full_platform_restore:
    - Restore RDS from snapshot
    - Restore EFS from backup
    - Restore secrets from S3 backup
    - Update ECS task definitions with new endpoints
    - Validate end-to-end connectivity
```

**CLI Command**: `python .claude/utils/aws_mgmt/backup_cli.py restore [--type rds|efs|pitr|full] [--snapshot-id <id>] [--target-time <timestamp>]`

### Skill: backup_validate
**Description**: Validate backup integrity and recoverability

**Operations**:
```yaml
backup_validate:
  test_restore_to_dev:
    - Restore latest backup to DEV environment
    - Run connectivity tests
    - Execute sample queries
    - Verify data integrity checksums
    - Clean up test resources
    - Generate validation report

  backup_inventory:
    - List all backups by resource type
    - Check backup age and retention compliance
    - Identify missing or failed backups
    - Calculate storage costs

  replication_verify:
    - Verify cross-region replication status
    - Check DR region backup availability
    - Validate replication lag (RPO compliance)
    - Alert if replication behind threshold
```

**CLI Command**: `python .claude/utils/aws_mgmt/backup_cli.py validate [--test-restore] [--inventory] [--replication]`

### Skill: backup_schedule
**Description**: Manage backup schedules and retention policies

**Operations**:
```yaml
backup_schedule:
  configure_schedule:
    - Create/update AWS Backup plan
    - Set backup frequency (hourly, daily, weekly)
    - Configure retention period
    - Set replication rules to DR region

  retention_management:
    - Apply retention policies
    - Delete expired backups
    - Archive old backups to S3 Glacier
    - Generate retention compliance report

  list_schedules:
    - Show all backup plans
    - Display next scheduled backups
    - Show retention settings
    - Report on backup job history
```

**CLI Command**: `python .claude/utils/aws_mgmt/backup_cli.py schedule [--create|--update|--list] [--retention <days>]`

## 1.3 Input Requirements

```yaml
Required Inputs:
  environment:
    type: string
    values: [dev, sit, prod]
    required: true

  operation:
    type: string
    values: [create, restore, validate, schedule]
    required: true

  resource_type:
    type: string
    values: [rds, efs, secrets, full]
    required: false
    default: full

  tenant_id:
    type: string
    required: false
    description: Specific tenant to backup/restore (omit for all)

  snapshot_id:
    type: string
    required: false
    description: Specific snapshot ID for restore operations

  target_time:
    type: ISO8601 timestamp
    required: false
    description: Point-in-time for PITR restore

Preconditions:
  - AWS credentials configured with backup permissions
  - AWS Backup vault exists in both primary and DR regions
  - S3 buckets for cross-region replication exist
  - SNS topics for notifications configured
```

## 1.4 Output Specifications

```yaml
Backup Create Output:
  - Snapshot/backup ID
  - Backup ARN
  - Size and duration
  - Replication status
  - Cost estimate

Backup Restore Output:
  - Restored resource ID
  - New endpoint (if applicable)
  - Validation results
  - Time to restore

Backup Report Output (Markdown):
  - Executive summary
  - Backup inventory table
  - Retention compliance status
  - Replication lag metrics
  - Recommendations
```

## 1.5 Constraints and Guardrails

```yaml
Safety Constraints:
  - NEVER delete PROD backups without 2-person approval
  - NEVER restore to PROD without explicit confirmation
  - Always validate backup before marking complete
  - Maintain minimum 7 days retention in PROD
  - Cross-region replication mandatory for PROD

Operational Limits:
  - Maximum 1 concurrent restore per environment
  - Backup window: 2-5 AM local time (to avoid peak usage)
  - Retention: DEV=1 day, SIT=3 days, PROD=7-30 days

Environment Specific:
  - DEV: Quick backups, minimal retention, test restores allowed
  - SIT: Standard backups, moderate retention
  - PROD: Full backups, extended retention, approval required
```

## 1.6 Success Criteria

```yaml
Backup Success:
  - Backup completes without errors
  - Backup size > 0 bytes
  - Backup tagged correctly
  - Replication initiated (PROD)
  - Completion notification sent

Restore Success:
  - Resource created/restored
  - Connectivity validated
  - Data integrity verified
  - Endpoint updated (if needed)
  - Documentation generated

RPO Compliance:
  - Backup frequency meets 1-hour RPO
  - Replication lag < 1 hour
  - No missed backup windows
```

---

# Agent 2: AWS DR Manager Agent

## 2.1 Identity and Purpose

```
Agent Name: AWS DR Manager Agent (BBWS Multi-Tenant WordPress)

Primary Purpose:
This agent manages disaster recovery operations for the BBWS platform, including
failover from primary region (af-south-1) to DR region (eu-west-1) and failback
when the primary region recovers. It coordinates Route53 DNS changes, infrastructure
provisioning, and service validation during DR events.

Value Provided:
- Orchestrated failover with minimal manual intervention
- DNS-based traffic management via Route53
- Infrastructure provisioning in DR region
- Automated health checks during failover
- Documented failback procedures
- RTO compliance (< 4 hours)
```

## 2.2 Core Capabilities (Skills)

### Skill: dr_failover
**Description**: Execute disaster recovery failover to DR region

**Operations**:
```yaml
dr_failover:
  assess_situation:
    - Check primary region health
    - Verify DR region readiness
    - Assess latest backup availability
    - Calculate data loss (RPO impact)
    - Generate go/no-go recommendation

  provision_dr_infrastructure:
    - Terraform apply in eu-west-1
    - Restore RDS from latest snapshot
    - Restore EFS from backup
    - Deploy ECS cluster and services
    - Configure ALB and security groups

  dns_failover:
    - Update Route53 health check status
    - Switch DNS records to DR endpoints
    - Verify DNS propagation
    - Monitor traffic shift

  validate_failover:
    - Test all tenant WordPress sites
    - Verify database connectivity
    - Check EFS mounts
    - Validate CloudFront distributions
    - Generate failover report

  notify_stakeholders:
    - Send SNS notifications
    - Update status page
    - Log incident timeline
    - Notify operations team
```

**CLI Command**: `python .claude/utils/aws_mgmt/dr_cli.py failover [--assess-only] [--execute] [--validate]`

### Skill: dr_failback
**Description**: Execute failback to primary region after recovery

**Operations**:
```yaml
dr_failback:
  assess_primary_recovery:
    - Check primary region health
    - Verify infrastructure availability
    - Assess data sync status
    - Generate failback recommendation

  sync_data_to_primary:
    - Sync RDS data from DR to primary
    - Sync EFS content to primary
    - Verify data integrity
    - Calculate delta and sync time

  staged_failback:
    - Redirect 10% traffic to primary (canary)
    - Monitor error rates
    - Increase traffic to 50%
    - Full traffic switch to primary

  dns_failback:
    - Update Route53 to primary endpoints
    - Verify DNS propagation
    - Monitor traffic return
    - Disable DR health check bypass

  cleanup_dr:
    - Terminate DR ECS services
    - Stop DR RDS instance (keep for future DR)
    - Archive DR logs
    - Generate failback report
```

**CLI Command**: `python .claude/utils/aws_mgmt/dr_cli.py failback [--assess-only] [--staged] [--execute]`

### Skill: dr_test
**Description**: Test DR procedures without impacting production

**Operations**:
```yaml
dr_test:
  tabletop_exercise:
    - Walk through failover runbook
    - Identify gaps in procedures
    - Validate contact lists
    - Document findings

  infrastructure_test:
    - Deploy DR infrastructure in isolation
    - Restore from latest backup
    - Validate all services operational
    - Measure RTO achievement
    - Tear down test infrastructure

  dns_test:
    - Create test DNS records
    - Simulate failover with test domain
    - Verify routing behavior
    - Clean up test records

  full_dr_drill:
    - Execute full failover (non-prod)
    - Measure actual RTO
    - Document lessons learned
    - Update runbook
```

**CLI Command**: `python .claude/utils/aws_mgmt/dr_cli.py test [--tabletop] [--infra] [--dns] [--full-drill]`

### Skill: dr_status
**Description**: Check DR readiness and replication status

**Operations**:
```yaml
dr_status:
  replication_check:
    - Check RDS snapshot replication lag
    - Check EFS backup replication status
    - Verify S3 cross-region replication
    - Calculate current RPO

  infrastructure_readiness:
    - Verify Terraform state for DR region
    - Check DR VPC and networking
    - Validate IAM roles exist
    - Confirm DR secrets available

  runbook_validation:
    - Verify runbook is current
    - Check contact lists updated
    - Validate escalation procedures
    - Confirm communication templates ready

  generate_report:
    - DR readiness score (0-100%)
    - Replication lag metrics
    - Infrastructure gaps
    - Recommendations
```

**CLI Command**: `python .claude/utils/aws_mgmt/dr_cli.py status [--replication] [--infrastructure] [--report]`

## 2.3 Input Requirements

```yaml
Required Inputs:
  environment:
    type: string
    values: [dev, sit, prod]
    required: true

  operation:
    type: string
    values: [failover, failback, test, status]
    required: true

  mode:
    type: string
    values: [assess-only, staged, execute]
    required: false
    default: assess-only

  confirmation_code:
    type: string
    required: true (for failover/failback execute)
    description: Unique code from incident ticket for audit

Preconditions:
  - AWS credentials for both primary and DR regions
  - Route53 hosted zone accessible
  - Terraform state available for DR region
  - Latest backups replicated to DR region
  - SNS topics for notifications configured
  - Runbook documentation current
```

## 2.4 Output Specifications

```yaml
Failover Output:
  - Failover start and end time
  - RTO achieved (vs target 4 hours)
  - RPO impact (data loss window)
  - Services restored list
  - DNS propagation status
  - Incident timeline

Failback Output:
  - Data sync duration
  - Traffic migration stages
  - Validation results
  - Cleanup summary

DR Status Report (Markdown):
  - DR readiness score
  - Replication lag table
  - Last DR test date
  - Infrastructure gaps
  - Recommended actions
```

## 2.5 Constraints and Guardrails

```yaml
Safety Constraints:
  - PROD failover requires incident ticket number
  - PROD failover requires 2-person authorization
  - Never delete primary region data during DR
  - Always create backup before failback data sync
  - Document all actions in incident log

Operational Limits:
  - RTO target: < 4 hours
  - RPO target: < 1 hour
  - DR tests: Monthly (SIT), Quarterly (PROD)
  - Failback staged rollout mandatory for PROD

Communication Requirements:
  - Notify stakeholders before failover execution
  - Update status page during DR event
  - Post-incident review within 48 hours
  - Update runbook with lessons learned
```

## 2.6 DR Runbook Reference

```yaml
Failover Playbook Steps:
  1. DETECT - Primary region failure detected
  2. ASSESS - Evaluate scope and impact
  3. DECIDE - Go/No-Go decision by Platform Admin
  4. NOTIFY - Alert stakeholders
  5. PROVISION - Deploy DR infrastructure
  6. RESTORE - Restore from latest backups
  7. SWITCH - Update DNS to DR endpoints
  8. VALIDATE - Verify all services operational
  9. MONITOR - Watch for issues
  10. DOCUMENT - Log incident timeline

Failback Playbook Steps:
  1. ASSESS - Confirm primary region recovered
  2. SYNC - Replicate data from DR to primary
  3. VALIDATE - Verify primary infrastructure
  4. STAGE - Gradual traffic migration
  5. SWITCH - Full DNS switch to primary
  6. CLEANUP - Stop DR services
  7. DOCUMENT - Post-incident review
```

---

# Agent 3: AWS Cost Manager Agent

## 3.1 Identity and Purpose

```
Agent Name: AWS Cost Manager Agent (BBWS Multi-Tenant WordPress)

Primary Purpose:
This agent provides comprehensive cost management for the BBWS platform including
cost reporting, budget forecasting, budget alerts, and cost optimization recommendations.
It tracks per-tenant costs, generates billing reports, and implements cost control
actions to maintain the $25-$37/tenant/month target.

Value Provided:
- Detailed cost breakdown by tenant, service, and environment
- Monthly billing reports for chargeback
- Budget forecasting and anomaly detection
- Cost optimization recommendations
- Budget alerts and automated actions
- Savings plans and reserved capacity analysis
```

## 3.2 Core Capabilities (Skills)

### Skill: cost_report_generate
**Description**: Generate cost reports at various granularities

**Operations**:
```yaml
cost_report_generate:
  daily_report:
    - Query Cost Explorer for daily spend
    - Break down by service (ECS, RDS, EFS, etc.)
    - Compare to previous day
    - Identify anomalies (>20% change)
    - Send summary to cost-alerts SNS topic

  monthly_tenant_report:
    - Calculate per-tenant costs
    - Allocate shared costs (RDS, EFS, ALB)
    - Generate tenant invoice data
    - Compare to target ($25-$37/tenant)
    - Flag tenants over budget

  environment_report:
    - Aggregate costs by environment (dev, sit, prod)
    - Show resource utilization
    - Identify idle resources
    - Calculate environment efficiency

  executive_summary:
    - Total platform cost
    - Month-over-month trend
    - Forecast vs budget
    - Top 5 cost drivers
    - Optimization opportunities
```

**CLI Command**: `python .claude/utils/aws_mgmt/cost_cli.py report [--daily|--monthly|--tenant|--executive] [--format json|markdown|csv]`

### Skill: cost_budget_manage
**Description**: Create and manage AWS Budgets

**Operations**:
```yaml
cost_budget_manage:
  create_budget:
    - Create AWS Budget with threshold
    - Configure alert thresholds (50%, 80%, 100%)
    - Set up SNS notifications
    - Enable forecasted alerts

  update_budget:
    - Modify budget amount
    - Adjust alert thresholds
    - Update notification subscribers
    - Change budget period

  budget_status:
    - Current spend vs budget
    - Forecast end-of-month spend
    - Days remaining in period
    - Alert status

  budget_actions:
    - Configure automatic actions at thresholds
    - Stop non-essential ECS tasks at 100%
    - Scale down RDS at 90%
    - Send escalation at 110%
```

**CLI Command**: `python .claude/utils/aws_mgmt/cost_cli.py budget [--create|--update|--status|--actions] [--amount <USD>] [--period monthly]`

### Skill: cost_forecast
**Description**: Forecast costs and detect anomalies

**Operations**:
```yaml
cost_forecast:
  monthly_forecast:
    - Query Cost Explorer forecasting API
    - Project end-of-month spend
    - Calculate confidence intervals
    - Compare to budget allocation
    - Generate forecast report

  trend_analysis:
    - Analyze 3-month cost trends
    - Identify growth patterns
    - Project annual costs
    - Recommend budget adjustments

  anomaly_detection:
    - Enable Cost Anomaly Detection
    - Configure anomaly thresholds
    - Set up anomaly alerts
    - Review anomaly history

  what_if_analysis:
    - Model adding new tenants
    - Project scaling impact
    - Estimate DR activation cost
    - Calculate optimization savings
```

**CLI Command**: `python .claude/utils/aws_mgmt/cost_cli.py forecast [--monthly|--trend|--anomaly|--what-if] [--scenario <name>]`

### Skill: cost_optimize
**Description**: Identify and implement cost optimizations

**Operations**:
```yaml
cost_optimize:
  recommendations:
    - Query Cost Explorer recommendations
    - Analyze Compute Optimizer suggestions
    - Identify unused resources
    - Calculate potential savings

  rightsizing:
    - Analyze ECS task CPU/memory usage
    - Recommend task size adjustments
    - Identify over-provisioned RDS
    - Suggest EFS throughput changes

  savings_plans:
    - Analyze compute usage patterns
    - Recommend Savings Plans coverage
    - Calculate potential savings (up to 30%)
    - Generate purchase recommendation

  reserved_capacity:
    - Analyze RDS usage patterns
    - Recommend Reserved Instance purchases
    - Calculate break-even period
    - Generate RI recommendation

  cleanup:
    - Identify orphaned resources
    - Find unused EFS access points
    - Locate stale RDS snapshots
    - List idle NAT Gateway data
```

**CLI Command**: `python .claude/utils/aws_mgmt/cost_cli.py optimize [--recommendations|--rightsize|--savings-plans|--cleanup]`

### Skill: cost_allocate
**Description**: Allocate costs to tenants for chargeback

**Operations**:
```yaml
cost_allocate:
  tag_enforcement:
    - Verify all resources tagged with tenant_id
    - Report untagged resources
    - Auto-tag based on naming convention
    - Generate tagging compliance report

  shared_cost_allocation:
    - Define allocation rules (RDS, ALB, VPC)
    - Calculate per-tenant share
    - Apply allocation methodology
    - Document allocation logic

  chargeback_report:
    - Generate per-tenant invoice
    - Include shared cost allocation
    - Add markup/overhead if configured
    - Export to billing system format

  tenant_cost_history:
    - Show tenant cost over time
    - Compare tenants
    - Identify high-cost tenants
    - Generate usage report for tenant
```

**CLI Command**: `python .claude/utils/aws_mgmt/cost_cli.py allocate [--enforce-tags|--shared-costs|--chargeback|--history <tenant_id>]`

## 3.3 Input Requirements

```yaml
Required Inputs:
  environment:
    type: string
    values: [dev, sit, prod, all]
    required: true

  operation:
    type: string
    values: [report, budget, forecast, optimize, allocate]
    required: true

  period:
    type: string
    values: [daily, weekly, monthly, quarterly]
    required: false
    default: monthly

  tenant_id:
    type: string
    required: false
    description: Filter reports to specific tenant

  format:
    type: string
    values: [json, markdown, csv, pdf]
    required: false
    default: markdown

Preconditions:
  - Cost Explorer enabled (24-hour activation delay)
  - Cost allocation tags activated
  - AWS Budgets access
  - SNS topics for notifications configured
  - S3 bucket for report storage
```

## 3.4 Output Specifications

```yaml
Cost Report Output (Markdown):
  sections:
    - Executive Summary (total spend, trend, forecast)
    - Cost by Service (ECS, RDS, EFS, ALB, etc.)
    - Cost by Environment (dev, sit, prod)
    - Cost by Tenant (with shared allocation)
    - Anomalies and Alerts
    - Optimization Recommendations

Budget Status Output:
  - Budget name and period
  - Budget amount (USD)
  - Current spend
  - Forecasted spend
  - Percentage used
  - Alert thresholds status

Forecast Output:
  - Forecasted end-of-period spend
  - Confidence interval (80%)
  - Comparison to budget
  - Trend direction

Optimization Output:
  - Recommendation list
  - Estimated monthly savings
  - Implementation difficulty
  - Risk assessment
```

## 3.5 Budget Thresholds and Actions

```yaml
Budget Configuration:
  dev_monthly_budget:
    amount: 200 USD
    alerts:
      - threshold: 50%
        action: SNS notification
      - threshold: 80%
        action: SNS warning
      - threshold: 100%
        action: Email escalation

  sit_monthly_budget:
    amount: 400 USD
    alerts:
      - threshold: 80%
        action: SNS notification
      - threshold: 100%
        action: SNS warning + email

  prod_monthly_budget:
    amount: 1000 USD
    alerts:
      - threshold: 80%
        action: SNS notification
      - threshold: 90%
        action: SNS warning + review meeting
      - threshold: 100%
        action: Executive escalation
      - threshold: 110%
        action: Cost containment review

Automated Actions:
  dev_over_budget:
    - Stop non-critical ECS tasks
    - Scale RDS to minimum size
    - Send immediate notification

  sit_over_budget:
    - Alert operations team
    - Recommend cost reduction actions
    - No automatic resource changes

  prod_over_budget:
    - Executive notification
    - No automatic changes (PROD read-only)
    - Schedule cost review meeting
```

## 3.6 Cost Allocation Model

```yaml
Per-Tenant Direct Costs:
  - ECS Fargate task (per tenant container)
  - EFS access point storage
  - CloudWatch logs (per tenant)
  - CloudFront distribution

Shared Costs (Allocated by tenant count):
  - RDS instance (split equally)
  - ALB (split equally)
  - VPC (NAT Gateway, data transfer)
  - Secrets Manager (split equally)
  - AWS Backup vault storage

Fixed Platform Costs:
  - Route53 hosted zone
  - ACM certificates
  - CloudWatch dashboards
  - IAM roles

Target Cost per Tenant: $25-$37/month
  - Base allocation: $15 (shared costs)
  - Variable (storage/compute): $10-$22
```

---

# Agent 4: AWS Infra + Tenant Monitoring Agent

## 4.1 Identity and Purpose

```
Agent Name: AWS Infrastructure and Tenant Monitoring Agent (BBWS Multi-Tenant WordPress)

Primary Purpose:
This agent provides comprehensive monitoring for both infrastructure-level and
tenant-level health. It manages CloudWatch alarms, dashboards, health checks,
and automated responses to incidents. The agent ensures platform reliability
through proactive monitoring and intelligent alerting.

Value Provided:
- Real-time infrastructure health monitoring
- Per-tenant performance and availability tracking
- Intelligent alerting with escalation
- Automated remediation for common issues
- Comprehensive dashboards and reporting
- SLA compliance tracking
```

## 4.2 Core Capabilities (Skills)

### Skill: monitor_infra_health
**Description**: Monitor infrastructure-level health metrics

**Operations**:
```yaml
monitor_infra_health:
  ecs_cluster_health:
    - Check cluster status (ACTIVE/INACTIVE)
    - Monitor running task count
    - Track CPU and memory reservation
    - Check container insights metrics
    - Alert on cluster degradation

  rds_health:
    - Monitor instance status
    - Track CPU utilization (<80%)
    - Check free storage space
    - Monitor connections count
    - Track replication lag (if Multi-AZ)
    - Alert on performance issues

  efs_health:
    - Check file system availability
    - Monitor throughput utilization
    - Track burst credits
    - Check mount target status
    - Alert on performance degradation

  alb_health:
    - Monitor ALB state
    - Track request count
    - Check 4XX/5XX error rates
    - Monitor latency (target <500ms)
    - Track healthy target count
    - Alert on elevated errors

  network_health:
    - Check VPC flow logs for anomalies
    - Monitor NAT Gateway throughput
    - Track data transfer metrics
    - Check security group changes
```

**CLI Command**: `python .claude/utils/aws_mgmt/monitoring_cli.py infra-health [--ecs|--rds|--efs|--alb|--network|--all]`

### Skill: monitor_tenant_health
**Description**: Monitor individual tenant WordPress instances

**Operations**:
```yaml
monitor_tenant_health:
  tenant_availability:
    - HTTP health check per tenant
    - WordPress /wp-admin/ accessibility
    - Response time monitoring
    - SSL certificate validity
    - DNS resolution check

  tenant_performance:
    - Page load time
    - Database query latency
    - EFS read/write latency
    - CloudFront cache hit ratio
    - Error rate per tenant

  tenant_resources:
    - ECS task CPU usage
    - ECS task memory usage
    - Database storage per tenant
    - EFS storage per tenant
    - Log volume per tenant

  tenant_security:
    - Failed login attempts
    - WAF block events
    - Unusual traffic patterns
    - Plugin vulnerability alerts
```

**CLI Command**: `python .claude/utils/aws_mgmt/monitoring_cli.py tenant-health [--tenant <id>|--all] [--availability|--performance|--resources|--security]`

### Skill: alarm_manage
**Description**: Create and manage CloudWatch alarms

**Operations**:
```yaml
alarm_manage:
  create_alarm:
    - Define metric and threshold
    - Set evaluation period
    - Configure alarm actions (SNS)
    - Set OK actions
    - Tag with category and severity

  alarm_templates:
    - Apply standard alarm set for new tenant
    - Create infrastructure alarm baseline
    - Configure environment-specific thresholds
    - Enable composite alarms

  alarm_status:
    - List all alarms and states
    - Show alarms in ALARM state
    - Show recent state changes
    - Generate alarm summary

  alarm_suppress:
    - Temporarily disable alarm (maintenance)
    - Set suppression window
    - Log suppression reason
    - Auto-enable after window
```

**CLI Command**: `python .claude/utils/aws_mgmt/monitoring_cli.py alarm [--create|--templates|--status|--suppress] [--name <name>]`

### Skill: dashboard_manage
**Description**: Create and manage CloudWatch dashboards

**Operations**:
```yaml
dashboard_manage:
  create_dashboard:
    - Create CloudWatch dashboard
    - Add standard widgets
    - Configure auto-refresh
    - Set time range defaults

  dashboard_templates:
    - Platform overview dashboard
    - Per-tenant detail dashboard
    - Cost and usage dashboard
    - Security and compliance dashboard

  update_widgets:
    - Add new metric widgets
    - Modify existing widgets
    - Add text annotations
    - Configure widget layout

  share_dashboard:
    - Generate shareable link
    - Configure public dashboard (if allowed)
    - Set up dashboard embedding
```

**CLI Command**: `python .claude/utils/aws_mgmt/monitoring_cli.py dashboard [--create|--template <name>|--update|--share]`

### Skill: incident_respond
**Description**: Automated incident response and remediation

**Operations**:
```yaml
incident_respond:
  auto_remediate:
    - ECS task unhealthy → Force new deployment
    - EFS burst credits low → Switch to provisioned
    - RDS connections high → Enable connection pooling warning
    - ALB 5XX spike → Check target health
    - Container OOM → Increase memory recommendation

  escalation:
    - Tier 1: SNS notification (immediate)
    - Tier 2: PagerDuty/email (5 min no response)
    - Tier 3: Phone call (15 min critical)
    - Tier 4: Management escalation (30 min)

  incident_log:
    - Log incident detection time
    - Record actions taken
    - Track resolution time
    - Generate incident report

  post_incident:
    - Create incident timeline
    - Generate root cause analysis template
    - Update runbook with lessons
    - Schedule post-mortem
```

**CLI Command**: `python .claude/utils/aws_mgmt/monitoring_cli.py incident [--remediate|--escalate|--log|--report <incident_id>]`

### Skill: report_generate
**Description**: Generate monitoring and SLA reports

**Operations**:
```yaml
report_generate:
  daily_health:
    - Platform availability (last 24h)
    - Incident summary
    - Alarm activity
    - Performance metrics

  weekly_sla:
    - Uptime percentage (target 99.9%)
    - Performance against SLA
    - Incident count and MTTR
    - Tenant-specific SLA compliance

  monthly_executive:
    - Platform reliability summary
    - Capacity utilization trends
    - Cost per availability point
    - Recommendations

  tenant_report:
    - Individual tenant metrics
    - Usage statistics
    - Performance benchmarks
    - Improvement suggestions
```

**CLI Command**: `python .claude/utils/aws_mgmt/monitoring_cli.py report [--daily|--weekly|--monthly|--tenant <id>]`

## 4.3 Alarm Configuration

```yaml
Infrastructure Alarms:
  ecs_cluster:
    - Name: ECS-Cluster-CPU-High
      Metric: CPUReservation
      Threshold: >80%
      Period: 5 minutes
      Action: SNS-ops-alert

    - Name: ECS-Cluster-Memory-High
      Metric: MemoryReservation
      Threshold: >80%
      Period: 5 minutes
      Action: SNS-ops-alert

  rds:
    - Name: RDS-CPU-High
      Metric: CPUUtilization
      Threshold: >80%
      Period: 5 minutes
      Action: SNS-ops-warning

    - Name: RDS-Storage-Low
      Metric: FreeStorageSpace
      Threshold: <5GB
      Period: 5 minutes
      Action: SNS-ops-critical

    - Name: RDS-Connections-High
      Metric: DatabaseConnections
      Threshold: >100
      Period: 5 minutes
      Action: SNS-ops-warning

  efs:
    - Name: EFS-BurstCredits-Low
      Metric: BurstCreditBalance
      Threshold: <100GB
      Period: 15 minutes
      Action: SNS-ops-warning

  alb:
    - Name: ALB-5XX-High
      Metric: HTTPCode_ELB_5XX_Count
      Threshold: >10/minute
      Period: 1 minute
      Action: SNS-ops-critical

    - Name: ALB-Latency-High
      Metric: TargetResponseTime
      Threshold: >2 seconds
      Period: 5 minutes
      Action: SNS-ops-warning

Tenant Alarms (per tenant):
  availability:
    - Name: Tenant-{id}-Unhealthy
      Metric: HealthyHostCount
      Threshold: <1
      Period: 1 minute
      Action: SNS-ops-critical

  performance:
    - Name: Tenant-{id}-Response-Slow
      Metric: TargetResponseTime
      Threshold: >5 seconds
      Period: 5 minutes
      Action: SNS-ops-warning
```

## 4.4 Dashboard Templates

```yaml
Platform Overview Dashboard:
  widgets:
    - ECS Cluster CPU/Memory (graph)
    - RDS CPU/Connections (graph)
    - ALB Request Count (graph)
    - Error Rate (single metric)
    - Active Tenants (number)
    - Alarm Status Summary (table)

Tenant Detail Dashboard:
  widgets:
    - Tenant Health Status (per tenant)
    - Response Time (per tenant)
    - Request Count (per tenant)
    - Error Rate (per tenant)
    - Resource Usage (per tenant)

Cost Dashboard:
  widgets:
    - Daily Spend (graph)
    - Spend by Service (pie)
    - Spend by Tenant (bar)
    - Forecast vs Budget (gauge)
    - Month-to-Date (number)

Security Dashboard:
  widgets:
    - WAF Blocked Requests (graph)
    - Failed Login Attempts (table)
    - Security Group Changes (log)
    - Unauthorized Access Attempts (log)
```

## 4.5 Escalation Matrix

```yaml
Severity Levels:
  P1_Critical:
    definition: Platform-wide outage or security breach
    response_time: 5 minutes
    escalation:
      - 0 min: SNS + PagerDuty
      - 5 min: Phone call to on-call
      - 15 min: Engineering manager
      - 30 min: VP Engineering
    auto_remediate: true

  P2_High:
    definition: Single tenant down or major degradation
    response_time: 15 minutes
    escalation:
      - 0 min: SNS notification
      - 15 min: PagerDuty
      - 30 min: Email escalation
    auto_remediate: true

  P3_Medium:
    definition: Performance degradation or warnings
    response_time: 1 hour
    escalation:
      - 0 min: SNS notification
      - 1 hour: Email reminder
    auto_remediate: false

  P4_Low:
    definition: Non-urgent issues or recommendations
    response_time: 24 hours
    escalation:
      - 0 min: Log only
      - 24 hours: Weekly report
    auto_remediate: false

Notification Channels:
  sns_ops_critical:
    arn: arn:aws:sns:{region}:{account}:bbws-ops-critical
    subscribers: [ops-team@company.com, pagerduty]

  sns_ops_warning:
    arn: arn:aws:sns:{region}:{account}:bbws-ops-warning
    subscribers: [ops-team@company.com]

  sns_cost_alert:
    arn: arn:aws:sns:{region}:{account}:bbws-cost-alert
    subscribers: [finance@company.com, ops-lead@company.com]
```

## 4.6 Auto-Remediation Actions

```yaml
Automated Responses:
  ecs_task_unhealthy:
    trigger: HealthyHostCount = 0 for 2 minutes
    action: Force new deployment of ECS service
    notification: SNS-ops-warning
    logging: CloudWatch Logs + DynamoDB incident table

  rds_connections_exhausted:
    trigger: DatabaseConnections > 95% of max
    action:
      - Log warning
      - Identify top connection consumers
      - Recommend connection pooling
    notification: SNS-ops-critical

  efs_performance_degraded:
    trigger: BurstCreditBalance < 10GB
    action:
      - Switch to provisioned throughput (if approved)
      - OR alert for manual intervention
    notification: SNS-ops-warning

  alb_target_unhealthy:
    trigger: UnHealthyHostCount > 0 for 5 minutes
    action:
      - Drain unhealthy target
      - Force ECS service deployment
      - Log incident
    notification: SNS-ops-critical

  cost_anomaly:
    trigger: 20% increase in daily spend
    action:
      - Send detailed cost breakdown
      - Identify cost driver
      - Recommend investigation
    notification: SNS-cost-alert
```

---

# Python CLI Utilities Structure

## Directory Layout

```
.claude/
└── utils/
    └── aws_mgmt/
        ├── __init__.py
        ├── base.py                 # Base classes and shared utilities
        ├── backup_cli.py           # Backup Manager CLI
        ├── dr_cli.py               # DR Manager CLI
        ├── cost_cli.py             # Cost Manager CLI
        ├── monitoring_cli.py       # Monitoring CLI
        ├── config.py               # Environment configuration
        └── README.md               # CLI documentation
```

## Common Features Across All CLIs

```python
# base.py - Shared base class

class AWSManagementCLI:
    """Base class for all AWS Management CLIs"""

    def __init__(self):
        self.session = None
        self.account_id = None
        self.environment = None
        self.region = None

    def validate_environment(self):
        """Validate AWS account matches intended environment"""
        expected_accounts = {
            'dev': '536580886816',
            'sit': '815856636111',
            'prod': '093646564004'
        }
        # Validate and fail-fast if mismatch

    def get_session(self, profile: str = None, region: str = 'af-south-1'):
        """Create boto3 session with validation"""

    def log_action(self, action: str, details: dict):
        """Log action to DynamoDB state table"""

    def send_notification(self, topic: str, message: str, subject: str):
        """Send SNS notification"""

    def generate_report(self, data: dict, format: str = 'markdown'):
        """Generate report in specified format"""
```

## CLI Command Examples

```bash
# Backup CLI
python .claude/utils/aws_mgmt/backup_cli.py create --type full --environment dev
python .claude/utils/aws_mgmt/backup_cli.py restore --type rds --snapshot-id snap-123
python .claude/utils/aws_mgmt/backup_cli.py validate --test-restore
python .claude/utils/aws_mgmt/backup_cli.py schedule --list

# DR CLI
python .claude/utils/aws_mgmt/dr_cli.py status --replication
python .claude/utils/aws_mgmt/dr_cli.py failover --assess-only
python .claude/utils/aws_mgmt/dr_cli.py failover --execute --confirmation-code INC-123
python .claude/utils/aws_mgmt/dr_cli.py test --infra

# Cost CLI
python .claude/utils/aws_mgmt/cost_cli.py report --monthly --format markdown
python .claude/utils/aws_mgmt/cost_cli.py report --tenant tenant-1 --format csv
python .claude/utils/aws_mgmt/cost_cli.py budget --status
python .claude/utils/aws_mgmt/cost_cli.py forecast --monthly
python .claude/utils/aws_mgmt/cost_cli.py optimize --recommendations

# Monitoring CLI
python .claude/utils/aws_mgmt/monitoring_cli.py infra-health --all
python .claude/utils/aws_mgmt/monitoring_cli.py tenant-health --tenant tenant-1
python .claude/utils/aws_mgmt/monitoring_cli.py alarm --status
python .claude/utils/aws_mgmt/monitoring_cli.py report --weekly
python .claude/utils/aws_mgmt/monitoring_cli.py incident --report INC-456
```

---

# DynamoDB State Management Table

All agents share a DynamoDB table for state management, transaction tracking, and audit logging.

```yaml
Table: bbws-platform-state
  Partition Key: pk (String)  # Entity type: BACKUP#, DR#, COST#, ALERT#
  Sort Key: sk (String)       # Entity ID or timestamp

  Attributes:
    - entity_type: backup | dr_event | cost_report | alert | incident
    - environment: dev | sit | prod
    - status: pending | in_progress | completed | failed
    - created_at: ISO8601 timestamp
    - updated_at: ISO8601 timestamp
    - created_by: agent name or user
    - details: JSON object with entity-specific data
    - ttl: Unix timestamp for auto-expiry (optional)

  Global Secondary Indexes:
    - GSI1: status-created_at-index (for querying by status)
    - GSI2: environment-entity_type-index (for querying by env)

  Stream: Enabled for DLQ and event processing

Example Records:
  # Backup record
  pk: "BACKUP#dev"
  sk: "2025-12-14T10:00:00Z"
  entity_type: "backup"
  status: "completed"
  details: {
    "type": "full",
    "rds_snapshot_id": "snap-xxx",
    "efs_backup_id": "backup-yyy",
    "duration_seconds": 300,
    "size_bytes": 1073741824
  }

  # Alert record
  pk: "ALERT#prod"
  sk: "ALB-5XX-High#2025-12-14T10:05:00Z"
  entity_type: "alert"
  status: "in_progress"
  details: {
    "alarm_name": "ALB-5XX-High",
    "alarm_state": "ALARM",
    "threshold": 10,
    "current_value": 25,
    "escalation_tier": 1
  }
```

---

# SNS Topics for Notifications

```yaml
Notification Topics:
  bbws-ops-critical:
    purpose: Critical platform alerts (P1)
    subscribers:
      - Email: ops-team@company.com
      - SMS: +27xxxxxxxxx (on-call)
      - Lambda: incident-responder-function

  bbws-ops-warning:
    purpose: Warning alerts (P2-P3)
    subscribers:
      - Email: ops-team@company.com

  bbws-cost-alert:
    purpose: Cost and budget alerts
    subscribers:
      - Email: finance@company.com
      - Email: ops-lead@company.com

  bbws-dr-events:
    purpose: DR failover/failback notifications
    subscribers:
      - Email: dr-team@company.com
      - Email: management@company.com
      - SMS: +27xxxxxxxxx (on-call)

  bbws-backup-status:
    purpose: Backup completion/failure notifications
    subscribers:
      - Email: ops-team@company.com
```

---

# Implementation Priority

| Phase | Agent | Priority | Dependencies |
|-------|-------|----------|--------------|
| 1 | Monitoring Agent | High | CloudWatch, SNS configured |
| 2 | Backup Manager Agent | High | AWS Backup, S3 cross-region |
| 3 | Cost Manager Agent | Medium | Cost Explorer enabled |
| 4 | DR Manager Agent | Medium | Backup agent operational |

---

# Success Criteria Summary

| Agent | Key Success Metrics |
|-------|---------------------|
| Backup Manager | 100% backup success rate, RPO < 1 hour, cross-region replication verified |
| DR Manager | RTO < 4 hours in drill, failover procedure validated quarterly |
| Cost Manager | Per-tenant cost within $25-$37, 0 budget overruns, monthly reports generated |
| Monitoring Agent | 99.9% uptime SLA, MTTR < 15 minutes, zero undetected incidents |

---

# Approval Section

**This specification requires approval before implementation.**

| Approver | Role | Status | Date |
|----------|------|--------|------|
| | Platform Owner | Pending | |
| | Security Review | Pending | |
| | DevOps Lead | Pending | |
| | Finance (Cost Agent) | Pending | |

---

## Next Steps After Approval

1. Create `.claude/utils/aws_mgmt/` directory structure
2. Implement `base.py` with common utilities
3. Implement each CLI in priority order
4. Create agent markdown files from this spec
5. Set up DynamoDB state table
6. Configure SNS topics
7. Test each agent with TDD approach
8. Document in runbooks
