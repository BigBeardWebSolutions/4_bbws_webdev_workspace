# Emergency Rollback Runbook: S3 & DynamoDB Deployments

**Document Version**: 1.0
**Last Updated**: 2025-12-25
**Author**: Infrastructure Operations Team
**Environment**: DEV, SIT, PROD
**Severity**: CRITICAL

---

## 1. Overview

This runbook provides step-by-step procedures for rolling back failed S3 and DynamoDB deployments across the BBWS platform. Rollback decisions must balance stability (reverting to known-good state) against business continuity (attempting fix-forward approaches).

### When to Rollback vs. Fix Forward

**Rollback When:**
- Critical business functionality is unavailable (P0/P1)
- Data integrity is at risk
- Rollback can be completed faster than fix-forward
- Deployment corruption is evident
- Root cause cannot be immediately identified

**Fix Forward When:**
- Issue is isolated to a specific component (P2/P3)
- Rollback would cause data loss
- Current state is partially functional
- Root cause is identified and fix is validated
- Rollback would be more disruptive than the current issue

---

## 2. Rollback Decision Matrix

| Priority | Severity | Response Time | Decision | Approvers Required |
|----------|----------|----------------|----------|-------------------|
| **P0** | Critical Outage | Immediate (< 5 min) | EMERGENCY ROLLBACK | 2 (On-call + Manager) |
| **P1** | Major Feature Down | Within 15 minutes | EMERGENCY ROLLBACK | 2 (Technical Lead + Manager) |
| **P2** | Partial Degradation | Within 1 hour | ASSESS (Rollback or Fix) | 2 (Technical Lead + Lead Eng) |
| **P3** | Minor Issue | Within 4 hours | ASSESS (Rollback or Fix) | 1 (Technical Lead) |

### Decision Tree

```
Issue Detected
├─ Is business-critical functionality affected? (P0/P1)
│  ├─ YES → EMERGENCY ROLLBACK
│  │  └─ Proceed to Section 4: Emergency Rollback Procedure
│  └─ NO → Proceed to next check
├─ Can issue be fixed in < 30 minutes with validated solution?
│  ├─ YES → FIX FORWARD (create incident ticket)
│  └─ NO → STANDARD ROLLBACK
│     └─ Proceed to Section 5: Standard Rollback Procedure
```

---

## 3. Prerequisites

### 3.1 Git Tag Selection

All production-bound deployments must have Git tags following this format:
```
[environment]-[component]-[date]-[version]
# Examples:
# dev-lambda-2025-12-25-v1.2.3
# sit-dynamodb-2025-12-25-v1.2.3
# prod-s3-2025-12-25-v1.2.3
```

**Tag Selection Criteria for Rollback:**
- Use previous stable tag (usually N-1 release)
- Verify tag in Git history: `git log --oneline --graph --all | grep [tag-name]`
- Never skip tags in sequence (always go to immediately previous version)
- Document tag selection in incident ticket

### 3.2 Approval Requirements

**Emergency Rollback** requires:
1. On-call Engineer OR Technical Lead (immediate authorization)
2. Engineering Manager (notification and record)
3. Slack message in #incidents channel (timestamped)

**Standard Rollback** requires:
1. Technical Lead (primary approval)
2. One additional approved engineer (secondary verification)
3. Change ticket in tracking system

### 3.3 Pre-Rollback Communication

Before initiating rollback:
1. Notify Slack #incidents channel with INCIDENT tag
2. Create/update incident ticket with severity, component, and rollback plan
3. Identify stakeholders (product, support, customers if applicable)
4. Estimate rollback duration and expected downtime

---

## 4. Emergency Rollback Procedure

**Use this procedure for P0/P1 issues requiring immediate action.**

### Step 1: Declare Emergency (< 1 minute)

```bash
# 1a. Slack notification (mandatory)
# Message format: [INCIDENT] Component: [NAME] | Severity: P0 | Action: EMERGENCY ROLLBACK
# Mention: @on-call-team @engineering-manager

# 1b. Open incident ticket
# - Title: "EMERGENCY ROLLBACK: [Component] - [Brief Description]"
# - Labels: emergency, p0, rollback
# - Assign to: On-call engineer + manager
```

### Step 2: Identify Last Good Deployment (< 2 minutes)

```bash
# Access Git history in deployment repository
cd /path/to/deployment-repo
git log --oneline --all | head -20

# Alternative: Check deployment history in AWS
# For S3: aws s3api list-object-versions --bucket [bucket-name] --max-items 10
# For DynamoDB: aws dynamodb describe-table --table-name [table-name]

# Identify version tag for last known-good deployment
# Document this tag: [environment]-[component]-YYYY-MM-DD-v[X.Y.Z]
```

### Step 3: Secure Approvals (Parallel with Step 2)

```bash
# Via Slack (on-call engineer as primary approver)
# Message: "@[Engineering Manager], emergency rollback approved. Executing rollback to tag: [TAG]"

# Required acknowledgments:
# ✓ On-call engineer: approval
# ✓ Engineering manager: acknowledgment
```

### Step 4: Execute Emergency Rollback

```bash
# 4a. Clone/pull latest deployment repository
cd /path/to/deployment-repo
git fetch --all --tags
git checkout [previous-good-tag]

# 4b. Execute rollback workflow
# Using GitHub Actions, GitLab CI, or local execution
bash scripts/rollback.sh \
  --environment [env] \
  --component [component-name] \
  --target-tag [good-tag] \
  --emergency \
  --force

# 4c. Monitor rollback progress (real-time)
# Watch CloudWatch Logs: /aws/lambda/[function-name]
# Monitor: S3 deployment status, DynamoDB replication status
tail -f cloudwatch-logs-rollback.txt
```

### Step 5: Immediate Validation (< 3 minutes after rollback)

```bash
# See Section 9 for detailed validation steps
# Quick validation:
# 1. Check service health endpoints return 200
# 2. Verify no error spikes in CloudWatch
# 3. Confirm critical Lambda functions executing successfully
# 4. Test basic user workflow (for CPP/Admin systems)
```

### Step 6: Communication (Parallel with validation)

```bash
# Update Slack #incidents channel:
# "ROLLBACK COMPLETE at [TIME]. Previous deployment [TAG] restored.
#  Validation in progress. Estimated service restoration: [TIME]"

# Notify stakeholders if customer-facing impact existed
```

**Expected Duration**: 5-10 minutes total (Emergency rollback)
**Expected Downtime**: 2-5 minutes (depending on component)

---

## 5. Standard Rollback Procedure

**Use this procedure for P2/P3 issues or when rollback decision is not emergency.**

### Step 1: Issue Assessment (< 15 minutes)

```bash
# 1a. Verify issue reproducibility
# - Test in DEV environment (if not originating from DEV)
# - Confirm issue patterns and scope
# - Document affected components

# 1b. Check logs and metrics
# CloudWatch Logs: /aws/lambda/[function-name]
# DynamoDB Metrics: ConsumedWriteCapacityUnits, ProvisionedWriteCapacityUnits
# S3 Metrics: 4XXError, 5XXError rates

# 1c. Identify root cause attempt
# Is there a clear, quick fix available?
# If YES and < 30 min fix time: proceed with fix-forward
# If NO or fix time > 30 min: proceed with rollback
```

### Step 2: Obtain Approval (< 10 minutes)

```bash
# 2a. Create change ticket
# - Title: "ROLLBACK: [Component] - [Reason]"
# - Current version: [tag/hash]
# - Target version: [previous-tag]
# - Estimated downtime: [X minutes]

# 2b. Request approvals from:
# - Technical Lead (primary review)
# - One additional engineer (peer review)
# Both must acknowledge in ticket or Slack thread

# 2c. Document decision rationale in ticket
# - Why rollback vs. fix-forward
# - Expected business impact
# - Rollback success criteria
```

### Step 3: Prepare Rollback (< 5 minutes)

```bash
# 3a. Verify target version stability
cd /path/to/deployment-repo
git log --oneline [previous-good-tag]..HEAD

# 3b. Review changes between current and target
git diff [previous-good-tag] HEAD

# 3c. Prepare rollback script
# Edit scripts/rollback.sh with:
# - Target tag: [previous-good-tag]
# - Environment: [dev/sit/prod]
# - Component: [name]
# - Validation: automatic

# 3d. Create backup of current state (for forensics)
bash scripts/backup-current-state.sh \
  --environment [env] \
  --component [component-name] \
  --backup-path /backups/forensics/[timestamp]/
```

### Step 4: Execute Rollback

```bash
# 4a. Notify team (Slack #incidents)
# "ROLLBACK INITIATED: [Component] → [Target Tag]
#  Expected downtime: [X minutes]
#  Approvers: [names]"

# 4b. Execute rollback
bash scripts/rollback.sh \
  --environment [env] \
  --component [component-name] \
  --target-tag [previous-good-tag] \
  --validate \
  --notify-slack

# 4c. Monitor execution
tail -f /var/log/rollback-[timestamp].log
```

### Step 5: Post-Rollback Verification (< 10 minutes)

```bash
# Execute validation checklist (see Section 9)
bash scripts/validate-rollback.sh \
  --environment [env] \
  --component [component-name]

# Document validation results in change ticket
```

**Expected Duration**: 40-60 minutes total (Standard rollback)
**Expected Downtime**: 5-15 minutes

---

## 6. DEV Environment Rollback

**Procedure**: Simplified and expedited for development environment

### Prerequisites
- Rollback can proceed with 1 approval (Tech Lead)
- Downtime is acceptable
- No customer impact

### Procedure

```bash
# 6.1 Identify issue and previous good tag
git log --oneline --all -20

# 6.2 Single approval (Slack message)
# "@[Tech Lead], rolling back DEV [component] to [tag] - OK?"

# 6.3 Execute rollback
cd /path/to/deployment-repo
git checkout [previous-tag]
git pull origin main

# 6.4 Deploy rollback version
bash scripts/deploy.sh --environment dev --component [name]

# 6.5 Quick validation
bash scripts/quick-health-check.sh --environment dev

# 6.6 Log to incident tracking
# Note: DEV rollbacks can be documented retroactively if urgent

# 6.7 Notify team (post-rollback)
# Slack: "DEV [component] rolled back to [tag]. Service restored."
```

**Expected Duration**: 10-15 minutes
**Downtime Impact**: Development only, no customer impact

---

## 7. SIT Rollback

**Procedure**: Balanced approach with safety checks for staging environment

### Prerequisites
- 2 approvals required: Tech Lead + QA Lead
- Downtime should be minimized (SIT is used for testing)
- Testing cycle impact must be assessed

### Procedure

```bash
# 7.1 Assess testing impact
# - What tests are currently running?
# - How long until next test cycle?
# - Will rollback delay validation?

# 7.2 Secure dual approvals
# - Tech Lead approval: code/deployment safety
# - QA Lead approval: testing impact and continuity

# 7.3 Create change ticket in tracking system
# Include: current version, target version, reason, impact

# 7.4 Prepare environment-specific backup
aws s3 sync s3://[sit-bucket] s3://backups-sit/pre-rollback-[timestamp]/
aws dynamodb create-backup \
  --table-name [table-name] \
  --backup-name sit-pre-rollback-[timestamp]

# 7.5 Execute rollback workflow
bash scripts/rollback.sh \
  --environment sit \
  --component [name] \
  --target-tag [previous-good-tag] \
  --create-backup

# 7.6 Validate in SIT environment
# Run SIT validation suite
bash scripts/validate-rollback.sh --environment sit --full

# 7.7 Notify QA team
# Slack #sit-testing: "SIT [component] rolled back.
#       QA team: please restart testing suite."

# 7.8 Document in change ticket
# - Rollback start/completion time
# - Validation results
# - Testing restart plan
```

**Expected Duration**: 30-45 minutes
**Downtime Impact**: SIT environment only, testing delay possible

---

## 8. PROD Rollback

**Procedure**: Most stringent controls for production environment

### Prerequisites
- 2+ approvals required: On-call Lead + Engineering Manager + Director (if P0)
- Minimal acceptable downtime (customer-facing)
- Extensive pre-rollback and post-rollback validation
- Incident communication required

### Procedure

```bash
# 8.1 Verify P0/P1 severity
# Confirm that rollback is necessary (not fix-forward)
# - Check if issue is customer-facing (critical determination)
# - Verify business impact threshold

# 8.2 Secure multi-level approvals (critical decision gate)
# Required approvals via Slack or ticketing system:
# ✓ On-call Technical Lead
# ✓ Engineering Manager
# ✓ Director (if P0) or Lead Architect (if P1)
# All must acknowledge within [specified timeframe]

# 8.3 Incident notification
# Slack #incidents (broadcast)
# Message: "PROD ROLLBACK DECISION
#  Component: [name] | Severity: [P0/P1]
#  Target: [previous-good-tag] | Expected downtime: [X min]
#  Approvers: [names and roles]
#  Execution time: [specific timestamp - allow 5 min buffer]"

# 8.4 Customer notification (if applicable)
# Prepare Slack message for #customer-notifications
# Template: "We are performing scheduled maintenance on [service].
#  Expected downtime: [X-Y minutes]. Current status: [status]."
# Post when rollback begins

# 8.5 Create comprehensive backup before rollback
# S3 backup
aws s3 sync s3://[prod-bucket] s3://[backup-bucket]/pre-rollback-[timestamp]/ \
  --region af-south-1

# DynamoDB backup
aws dynamodb create-backup \
  --table-name [table-name] \
  --backup-name prod-pre-rollback-[timestamp] \
  --region af-south-1

# 8.6 Cross-region replication verification
# Verify DR region has up-to-date replicas before proceeding
aws s3api list-bucket-metrics-configurations --bucket [dr-bucket] --region eu-west-1
aws dynamodb describe-continuous-backups --table-name [dr-table] --region eu-west-1

# 8.7 Execute rollback with full monitoring
bash scripts/rollback.sh \
  --environment prod \
  --component [name] \
  --target-tag [previous-good-tag] \
  --create-backup \
  --validate \
  --monitor-dashboard \
  --notifications-enabled

# Real-time monitoring (CloudWatch dashboard)
# Watch for: error rates, latency, success rates, throttling

# 8.8 Comprehensive post-rollback validation
# Execute full validation suite (Section 9 - Extended checks)
bash scripts/validate-rollback-prod.sh \
  --environment prod \
  --component [name] \
  --full-test-suite
```

### PROD-Specific Validation Checklist

```
□ All Lambda functions invoking successfully (error rate < 0.1%)
□ DynamoDB read/write capacity normal
□ S3 operations completing within SLA
□ Cross-region replication in sync
□ No data inconsistency detected
□ All integration points operational
□ Business-critical workflows validated end-to-end
```

### Communication Timeline

```
T+0 min    : Incident declared, decision made
T+2 min    : Approvals secured, backup initiated
T+3 min    : Rollback execution begins, customer notification posted
T+5-7 min  : Rollback complete, validation begins
T+10-15 min: Validation complete, service confirmed operational
T+15 min   : Final status update to stakeholders
T+30 min   : Post-incident review scheduled (within 24 hours)
```

**Expected Duration**: 15-25 minutes total
**Expected Downtime**: 3-10 minutes (depending on component)
**Monitoring Duration**: 2 hours post-rollback minimum

---

## 9. Post-Rollback Validation

### 9.1 Immediate Validation (0-5 minutes)

```bash
# Health check endpoint
curl -s https://[api-endpoint]/health | jq .
# Expected: {"status": "healthy", "version": "[good-tag]"}

# Lambda function invocation
aws lambda invoke \
  --function-name [function-name] \
  --payload '{"test": true}' \
  --region af-south-1 \
  response.json
cat response.json | jq .

# DynamoDB connectivity
aws dynamodb scan \
  --table-name [table-name] \
  --limit 1 \
  --region af-south-1

# S3 bucket access
aws s3 ls s3://[bucket-name] --region af-south-1
```

### 9.2 Functional Validation (5-15 minutes)

```bash
# For CPP (Customer Portal Public):
# 1. Create new site creation request
# 2. Verify Lambda triggers and completes
# 3. Check site appears in DynamoDB
# 4. Validate CloudFront distribution is accessible

# For Admin Portal:
# 1. Login with test credentials
# 2. Create/modify test site
# 3. Verify state transitions in DynamoDB
# 4. Check audit logs recorded

# For Site Builder:
# 1. Upload site configuration
# 2. Verify template processing
# 3. Check content in S3 storage
# 4. Validate image processing pipeline

# Test command template:
bash scripts/smoke-tests.sh --environment [env] --component [name]
```

### 9.3 Data Integrity Checks (5-10 minutes)

```bash
# Compare record counts
# Before rollback: [count-before]
# After rollback: [count-after]
# Should match within acceptable tolerance (< 0.1% variance)

# DynamoDB data validation
aws dynamodb scan --table-name [table-name] --region af-south-1 \
  --filter-expression "attribute_exists(id)" \
  | jq '.Items | length'

# S3 object integrity check
aws s3 ls s3://[bucket-name] --recursive --region af-south-1 \
  | wc -l

# Check for orphaned records or data inconsistencies
bash scripts/validate-data-integrity.sh \
  --environment [env] \
  --component [name]
```

### 9.4 Performance Baseline (10-20 minutes)

```bash
# CloudWatch metrics validation
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Duration \
  --dimensions Name=FunctionName,Value=[function-name] \
  --start-time [5-min-ago] \
  --end-time [now] \
  --period 60 \
  --statistics Average,Maximum

# Expected: Duration returns to baseline (within 10% of good version)

# Error rate check
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Errors \
  --dimensions Name=FunctionName,Value=[function-name] \
  --start-time [5-min-ago] \
  --end-time [now] \
  --period 60 \
  --statistics Sum

# Expected: Errors drop to < 0.5% of invocations
```

### 9.5 Integration Validation (Optional - 15 minutes)

```bash
# For critical integrations only:

# Cognito user authentication
aws cognito-idp admin-get-user \
  --user-pool-id [user-pool-id] \
  --username test-user@example.com

# SNS notifications (if applicable)
aws sns publish \
  --topic-arn arn:aws:sns:[region]:[account]:test-topic \
  --message "Validation test message" \
  --region af-south-1

# SQS queue processing (if applicable)
aws sqs send-message \
  --queue-url https://sqs.[region].amazonaws.com/[account]/[queue-name] \
  --message-body "Test message for validation"
```

### Validation Sign-Off

```bash
# Create validation report
cat > validation-report-[timestamp].txt << EOF
Component: [name]
Environment: [env]
Rollback Date/Time: [timestamp]
Target Version: [good-tag]
Source Version: [bad-tag]

Validation Results:
  ✓ Health Check: PASS
  ✓ Lambda Invocation: PASS
  ✓ DynamoDB Access: PASS
  ✓ S3 Access: PASS
  ✓ Functional Tests: PASS
  ✓ Data Integrity: PASS
  ✓ Performance Baseline: PASS
  ✓ Integration Tests: PASS (if applicable)

Signed by: [Engineer Name]
Time: [timestamp]
EOF

# Attach report to incident ticket
```

---

## 10. Root Cause Analysis (RCA) Template

**Complete within 24 hours of rollback. Schedule RCA meeting with stakeholders.**

### RCA Meeting Agenda (60 minutes)

```
1. Timeline Review (15 min)
2. Root Cause Discussion (20 min)
3. Contributing Factors (10 min)
4. Prevention Measures (10 min)
5. Action Items & Owners (5 min)
```

### RCA Report Template

```markdown
# Post-Incident Review: [Component] Rollback

**Date**: [date]
**Incident**: [brief description]
**Duration**: [start-time] to [end-time] (X minutes)
**Severity**: P0 | P1 | P2 | P3
**Participants**: [names and roles]

## Executive Summary
[1-2 sentences explaining what happened and impact]

## Timeline

| Time | Event | Owner |
|------|-------|-------|
| HH:MM | Issue detected | [name] |
| HH:MM | Incident declared | [name] |
| HH:MM | Rollback initiated | [name] |
| HH:MM | Rollback complete | [name] |
| HH:MM | Service validated | [name] |

## Root Cause

**Primary Cause**: [specific technical issue]

**Contributing Factors**:
- [Factor 1]
- [Factor 2]
- [Factor 3]

**Prevention**: [How to prevent this in future]

## Corrective Actions

| Action | Owner | Due Date | Status |
|--------|-------|----------|--------|
| Fix defect in code | [engineer] | [date] | PENDING |
| Add validation test | [engineer] | [date] | PENDING |
| Update runbook | [engineer] | [date] | PENDING |
| Code review training | [manager] | [date] | PENDING |

## Lessons Learned

**What Went Well**:
- [positive observation 1]
- [positive observation 2]

**What Could Improve**:
- [improvement 1]
- [improvement 2]

## Knowledge Base Articles

Links to internal documentation, runbooks, or fixes:
- [Link 1]
- [Link 2]
```

---

## 11. Communication Plan

### Pre-Rollback Communication

**Timing**: Before rollback authorization
**Channel**: Slack #incidents
**Audience**: Engineering team, on-call manager

```
Message:
"[INCIDENT] [Component] experiencing [brief issue].
Investigating for fix-forward vs. rollback decision.
Severity: [P0/P1/P2].
ETA on decision: [time].
Stay tuned for updates. @on-call-team"
```

### Rollback Initiation Announcement

**Timing**: When rollback is approved
**Channel**: Slack #incidents, #engineering
**Audience**: Engineering team, management

```
Message:
"[ROLLBACK INITIATED] [Component]
Issue: [Brief description of issue]
Action: Rolling back to [target-tag]
Expected duration: [X minutes]
Expected downtime: [X-Y minutes]
Approvers: [names]
Target completion: [HH:MM UTC]
Updates every 2 minutes in thread."
```

### Customer Notification (if applicable)

**Timing**: When customer-facing service is affected
**Channel**: Slack #customer-notifications, email (if needed)
**Audience**: Customers, customer success team

```
Message:
"🔧 MAINTENANCE IN PROGRESS

Service: [Service Name]
Start: [time UTC]
Expected duration: [X minutes]
Impact: [limited | moderate | major]
Status: [investigating | rolling back | validating]

We'll update you every 5 minutes. Thank you for your patience!"
```

### Rollback Complete Notification

**Timing**: When validation confirms success
**Channel**: Slack #incidents, #engineering
**Audience**: Engineering team, management, customers (if applicable)

```
Message:
"✅ ROLLBACK COMPLETE

Component: [name]
Time to restore: [X minutes]
Version restored: [good-tag]
Status: Service operational
Customer impact: [none | resolved]

Post-incident review scheduled: [date/time]
Action items: [link to ticket]"
```

### Post-Incident Communication

**Timing**: 24-48 hours after incident
**Channel**: Slack #engineering, team meeting
**Audience**: Engineering team, management, stakeholders

```
Message:
"📋 POST-INCIDENT REVIEW AVAILABLE

Incident: [name]
Root cause: [brief]
Action items: [count]
Prevention: [brief description]

Full report: [link]
RCA Meeting: [date/time]
Questions? Reply in thread."
```

### Communication Checklist

```
Pre-Rollback
□ Notify #incidents channel
□ Create incident ticket
□ Identify stakeholders
□ Prepare customer notification (if applicable)

During Rollback
□ Post rollback initiation in #incidents
□ Post customer notification (if applicable)
□ Provide updates every 2-3 minutes
□ Update Slack thread with progress

Post-Rollback
□ Post completion notification
□ Confirm service operational
□ Share validation results
□ Schedule RCA meeting

Follow-Up
□ Complete RCA report
□ Create action item tickets
□ Share lessons learned
□ Update runbook with findings
```

### Notification Templates

**Slack Message (Emergency Rollback Approved)**
```
@on-call-team @engineering-manager
EMERGENCY ROLLBACK APPROVED ✓

Component: [name]
Current: [bad-tag]
Target: [good-tag]
Reason: [brief]
Authorized by: [names]
Executing NOW.

ETA: [time] for completion
#incidents for updates
```

**Slack Message (Rollback In Progress)**
```
🔄 ROLLBACK IN PROGRESS

Component: [name]
Started: [HH:MM UTC]
Target: [good-tag]
Status: [step X of Y]

Updates every 2 minutes in thread 👇
#incidents
```

---

## Appendix: Command Reference

### Quick Rollback Commands

```bash
# List available tags
git tag -l "[environment]-*" --sort=-version:refname | head -5

# View differences between versions
git diff [good-tag] [bad-tag]

# Checkout previous version
git fetch --all --tags
git checkout [previous-good-tag]

# Check current version
git describe --tags --abbrev=0

# View deployment history
aws cloudformation describe-stacks --stack-name [stack-name]

# CloudWatch monitoring
aws logs tail --follow /aws/lambda/[function-name]

# DynamoDB point-in-time recovery (if enabled)
aws dynamodb describe-continuous-backups --table-name [name]
```

### Validation Commands

```bash
# Health checks
curl -s https://[api-endpoint]/health | jq .

# Lambda invocation test
aws lambda invoke --function-name [name] --payload '{}' response.json

# DynamoDB scan
aws dynamodb scan --table-name [name] --limit 1

# S3 list
aws s3 ls s3://[bucket-name]

# CloudWatch metrics
aws cloudwatch get-metric-statistics --namespace AWS/Lambda --metric-name Errors --dimensions Name=FunctionName,Value=[name] --start-time [time] --end-time [time] --period 60 --statistics Sum
```

---

**Document Control**

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2025-12-25 | Initial creation | Infrastructure Team |

**Approval Status**: Ready for review by Technical Lead and Engineering Manager
