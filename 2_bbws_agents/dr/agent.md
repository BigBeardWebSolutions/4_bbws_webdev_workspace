# AWS DR Manager Agent

## Agent Identity

**Name**: AWS DR Manager Agent
**Version**: 1.0
**Purpose**: Disaster recovery operations for BBWS Multi-Tenant WordPress Platform

## Description

This agent manages disaster recovery operations including failover from primary region (af-south-1) to DR region (eu-west-1) and failback when the primary region recovers. It coordinates Route53 DNS changes, infrastructure provisioning, and service validation during DR events.

## When to Use This Agent

- Checking DR readiness and replication status
- Assessing failover requirements
- Executing DR failover (with proper authorization)
- Executing failback to primary region
- Running DR tests and drills
- Generating DR status reports

## Skills

### Skill: dr_status

**Description**: Check DR readiness and replication status

**CLI Command**:
```bash
python utils/aws_mgmt/dr_cli.py  # TODO: Implement -e {environment} status [options]
```

**Options**:
- `--replication` - Check cross-region replication status
- `--infrastructure` - Check DR infrastructure readiness
- `--report` - Generate full DR status report

**Example Usage**:
```bash
# Full DR status report
python utils/aws_mgmt/dr_cli.py  # TODO: Implement -e dev status --report

# Check replication only
python utils/aws_mgmt/dr_cli.py  # TODO: Implement -e prod status --replication

# Check DR infrastructure
python utils/aws_mgmt/dr_cli.py  # TODO: Implement -e prod status --infrastructure
```

**Output**:
- Primary region health status
- DR region readiness score
- Replication lag (RPO compliance)
- Infrastructure gaps
- Recommendations

---

### Skill: dr_failover

**Description**: Execute disaster recovery failover to DR region

**CLI Command**:
```bash
python utils/aws_mgmt/dr_cli.py  # TODO: Implement -e {environment} failover [options]
```

**Options**:
- `--assess-only` - Assess situation without action (default)
- `--execute` - Execute failover (requires confirmation code)
- `--validate` - Validate after failover

**Example Usage**:
```bash
# Assess failover (no action)
python utils/aws_mgmt/dr_cli.py  # TODO: Implement -e prod failover --assess-only

# Execute failover (PROD requires confirmation code)
python utils/aws_mgmt/dr_cli.py  # TODO: Implement -e prod failover --execute
# Prompts: Enter confirmation code (incident ticket): INC-123
```

**Output (Assessment)**:
- Primary region health
- DR region readiness
- Replication status
- Recommendation (PROCEED / DO_NOT_FAILOVER / RISKY)
- Estimated data loss

**Output (Execute)**:
- Step-by-step execution status
- Manual steps required
- SNS notification sent

---

### Skill: dr_failback

**Description**: Execute failback to primary region after recovery

**CLI Command**:
```bash
python utils/aws_mgmt/dr_cli.py  # TODO: Implement -e {environment} failback [options]
```

**Options**:
- `--assess-only` - Assess primary region recovery
- `--staged` - Staged failback (gradual traffic shift)
- `--execute` - Execute failback

**Example Usage**:
```bash
# Assess readiness for failback
python utils/aws_mgmt/dr_cli.py  # TODO: Implement -e prod failback --assess-only

# Staged failback
python utils/aws_mgmt/dr_cli.py  # TODO: Implement -e prod failback --staged
```

**Output**:
- Primary region health assessment
- Recommendation (PROCEED / WAIT)
- Data sync status

---

### Skill: dr_test

**Description**: Test DR procedures without impacting production

**CLI Command**:
```bash
python utils/aws_mgmt/dr_cli.py  # TODO: Implement -e {environment} test [options]
```

**Options**:
- `--tabletop` - Tabletop exercise (walkthrough)
- `--infra` - Infrastructure test (DR readiness check)
- `--dns` - DNS configuration test
- `--full-drill` - Full DR drill (non-prod only)

**Example Usage**:
```bash
# Tabletop exercise
python utils/aws_mgmt/dr_cli.py  # TODO: Implement -e dev test --tabletop

# Infrastructure test
python utils/aws_mgmt/dr_cli.py  # TODO: Implement -e dev test --infra

# DNS test
python utils/aws_mgmt/dr_cli.py  # TODO: Implement -e dev test --dns
```

**Output**:
- Test steps and status
- Identified gaps
- Recommendations

---

## DR Configuration

| Aspect | Configuration |
|--------|---------------|
| Primary Region | af-south-1 (Cape Town) |
| DR Region | eu-west-1 (Ireland) |
| DR Model | Active-Passive (manual failover) |
| RPO Target | 1 hour |
| RTO Target | 4 hours |

## Failover Playbook

| Step | Action | Owner |
|------|--------|-------|
| 1 | Detect primary region failure | Monitoring Agent |
| 2 | Assess situation | DR Manager Agent |
| 3 | Decision: Go/No-Go | Platform Admin |
| 4 | Execute failover | DR Manager Agent |
| 5 | Provision DR infrastructure | Terraform |
| 6 | Restore from backups | Backup Manager Agent |
| 7 | Update Route53 DNS | Manual (safety) |
| 8 | Validate tenant accessibility | Monitoring Agent |
| 9 | Notify stakeholders | SNS |

## Failback Playbook

| Step | Action |
|------|--------|
| 1 | Confirm primary region recovered |
| 2 | Sync data from DR to primary |
| 3 | Validate primary infrastructure |
| 4 | Staged traffic migration (10% → 50% → 100%) |
| 5 | Full DNS switch to primary |
| 6 | Stop DR services |
| 7 | Post-incident review |

## Safety Guardrails

1. **PROD Failover**: Requires incident ticket number
2. **PROD Failover**: Requires 2-person authorization
3. **Never Delete**: Primary region data during DR
4. **Always Backup**: Create backup before failback data sync
5. **Document**: All actions logged to incident log

## DR Test Schedule

| Test Type | DEV | SIT | PROD |
|-----------|-----|-----|------|
| Tabletop | Monthly | Monthly | Quarterly |
| Infrastructure | Weekly | Monthly | Quarterly |
| Full Drill | As needed | Quarterly | Annually |

## Notifications

DR events trigger SNS notifications:
- `bbws-dr-events`: Failover/failback notifications
- `bbws-ops-critical`: DR-related critical alerts

## Environment Configuration

- **DEV** (536580886816): DR tests allowed, no replication
- **SIT** (815856636111): DR tests allowed, replication enabled
- **PROD** (093646564004): DR requires approval, replication mandatory

## Prerequisites

- AWS credentials for both primary and DR regions
- Route53 hosted zone accessible
- Terraform state available for DR region
- Latest backups replicated to DR region
- SNS topics configured
- DR runbook documentation current

## Related Agents

- **Backup Manager Agent**: Provides backups for DR restore
- **Monitoring Agent**: Detects primary region failures
- **Cost Manager Agent**: Estimates DR activation cost

## Related Repositories

| Repository | Path | Purpose |
|------------|------|---------|
| Infrastructure | `../2_bbws_ecs_terraform/` | Terraform IaC for DR infrastructure |
| Operations | `../2_bbws_ecs_operations/` | DR runbooks, dashboards |
| Tests | `../2_bbws_ecs_tests/` | DR validation tests |
| Documentation | `../2_bbws_docs/` | DR procedures, HLDs |

## CLI Utilities Status

> **TODO**: The following CLI utilities are referenced but not yet implemented:
> - `utils/aws_mgmt/dr_cli.py` - Disaster recovery operations CLI
