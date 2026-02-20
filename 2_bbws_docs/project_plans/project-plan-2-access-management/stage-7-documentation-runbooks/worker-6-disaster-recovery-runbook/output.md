# Access Management - Disaster Recovery Runbook

**Document ID**: RUNBOOK-ACCESS-DR-001
**Version**: 1.0
**Last Updated**: 2026-01-25
**Owner**: DevOps Team
**Review Frequency**: Bi-annually
**Last DR Test**: TBD

---

## 1. Overview

### 1.1 Purpose
This runbook provides procedures for disaster recovery of the Access Management system, including failover from the primary region (af-south-1) to the DR region (eu-west-1) and failback procedures.

### 1.2 DR Strategy

**Strategy**: Multi-site Active/Passive

```
┌─────────────────────────────────────────────────────────────────┐
│                        NORMAL OPERATION                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   ┌─────────────────┐              ┌─────────────────┐         │
│   │   af-south-1    │              │   eu-west-1     │         │
│   │    (PRIMARY)    │              │      (DR)       │         │
│   │                 │              │                 │         │
│   │  ┌───────────┐  │   Replicate  │  ┌───────────┐  │         │
│   │  │ DynamoDB  │──┼──────────────┼─►│ DynamoDB  │  │         │
│   │  │ (Active)  │  │              │  │ (Replica) │  │         │
│   │  └───────────┘  │              │  └───────────┘  │         │
│   │                 │              │                 │         │
│   │  ┌───────────┐  │   Replicate  │  ┌───────────┐  │         │
│   │  │    S3     │──┼──────────────┼─►│    S3     │  │         │
│   │  │ (Primary) │  │              │  │ (Replica) │  │         │
│   │  └───────────┘  │              │  └───────────┘  │         │
│   │                 │              │                 │         │
│   │  ┌───────────┐  │              │  ┌───────────┐  │         │
│   │  │  Lambda   │  │              │  │  Lambda   │  │         │
│   │  │ (Active)  │  │              │  │ (Standby) │  │         │
│   │  └───────────┘  │              │  └───────────┘  │         │
│   │                 │              │                 │         │
│   └────────┬────────┘              └────────┬────────┘         │
│            │                                │                   │
│            ▼                                ▼                   │
│   ┌─────────────────────────────────────────────────┐          │
│   │              Route 53 (Weighted/Failover)       │          │
│   │                  100% → af-south-1              │          │
│   └─────────────────────────────────────────────────┘          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 1.3 Recovery Objectives

| Metric | Target | Measurement |
|--------|--------|-------------|
| **RTO** (Recovery Time Objective) | 30 minutes | Time to restore service |
| **RPO** (Recovery Point Objective) | 1 hour | Maximum data loss |
| **MTTR** (Mean Time to Recovery) | 45 minutes | Average recovery time |

---

## 2. DR Components

### 2.1 Data Replication

| Component | Replication Method | Frequency | RPO |
|-----------|-------------------|-----------|-----|
| DynamoDB | Global Tables | Real-time | ~1 second |
| S3 Audit Bucket | Cross-Region Replication | Near real-time | ~15 minutes |
| DynamoDB Backups | Point-in-Time Recovery | Continuous | 1 second |

### 2.2 Infrastructure

| Component | Primary (af-south-1) | DR (eu-west-1) |
|-----------|---------------------|----------------|
| API Gateway | Active | Deployed (standby) |
| Lambda Functions | Active | Deployed (standby) |
| DynamoDB | Read/Write | Read-only replica |
| S3 Buckets | Primary | Replica |
| CloudWatch | Active | Configured |
| Cognito | Primary | N/A (global) |

---

## 3. Failover Triggers

### 3.1 Automatic Failover Triggers

| Condition | Threshold | Action |
|-----------|-----------|--------|
| Region unavailable | > 5 min health check fail | Alert + manual failover |
| API error rate | > 50% for 10 min | Alert only |
| DynamoDB unavailable | > 5 min | Alert + manual failover |

### 3.2 Manual Failover Criteria

Initiate manual failover when:
- AWS declares af-south-1 region-wide outage
- Primary region service unavailable > 15 minutes
- Data center failure affecting multiple AZs
- Instructed by AWS support

### 3.3 Decision Authority

| Severity | Decision Maker | Approval Required |
|----------|----------------|-------------------|
| Region outage | On-call Lead | CTO notification |
| Partial outage | Engineering Director | CTO approval |
| DR drill | DR Coordinator | Planned maintenance |

---

## 4. Failover Procedure

### 4.1 Pre-Failover Checklist

- [ ] Confirm primary region is unavailable
- [ ] Verify DR region is healthy
- [ ] Notify stakeholders of pending failover
- [ ] Confirm authorization to proceed
- [ ] Start incident bridge/war room
- [ ] Document failover start time

### 4.2 Failover Steps

#### Step 1: Verify DR Region Health

```bash
export DR_REGION=eu-west-1

# Check DynamoDB replica status
aws dynamodb describe-table \
  --table-name bbws-access-prod-ddb-access-management \
  --region $DR_REGION \
  --query 'Table.TableStatus'
# Expected: "ACTIVE"

# Check Lambda functions
aws lambda list-functions \
  --region $DR_REGION \
  --query "Functions[?starts_with(FunctionName, 'bbws-access-prod-lambda-')] | length(@)"
# Expected: 43

# Check API Gateway
aws apigateway get-rest-apis \
  --region $DR_REGION \
  --query "items[?name=='bbws-access-prod-apigw'].id"
```

#### Step 2: Promote DynamoDB Replica

DynamoDB Global Tables automatically handle failover. Verify write capability:

```bash
# Test write to DR region
aws dynamodb put-item \
  --table-name bbws-access-prod-ddb-access-management \
  --region $DR_REGION \
  --item '{
    "PK": {"S": "DR_TEST"},
    "SK": {"S": "FAILOVER_CHECK"},
    "timestamp": {"S": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}
  }'

# Verify write succeeded
aws dynamodb get-item \
  --table-name bbws-access-prod-ddb-access-management \
  --region $DR_REGION \
  --key '{"PK": {"S": "DR_TEST"}, "SK": {"S": "FAILOVER_CHECK"}}'

# Clean up test item
aws dynamodb delete-item \
  --table-name bbws-access-prod-ddb-access-management \
  --region $DR_REGION \
  --key '{"PK": {"S": "DR_TEST"}, "SK": {"S": "FAILOVER_CHECK"}}'
```

#### Step 3: Update Route 53

```bash
# Get hosted zone ID
HOSTED_ZONE_ID=$(aws route53 list-hosted-zones \
  --query "HostedZones[?Name=='example.com.'].Id" \
  --output text | cut -d'/' -f3)

# Update DNS to point to DR region
aws route53 change-resource-record-sets \
  --hosted-zone-id $HOSTED_ZONE_ID \
  --change-batch '{
    "Changes": [{
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "access-api.example.com",
        "Type": "A",
        "AliasTarget": {
          "HostedZoneId": "Z2FDTNDATAQYW2",
          "DNSName": "<dr-api-gateway-domain>.execute-api.eu-west-1.amazonaws.com",
          "EvaluateTargetHealth": true
        }
      }
    }]
  }'

# Verify DNS propagation (may take 60 seconds)
dig access-api.example.com +short
```

#### Step 4: Verify DR Service

```bash
# Run smoke tests against DR region
pytest tests/smoke/ -v --environment=prod-dr

# Test critical endpoints
DR_API_URL="https://access-api.example.com"

curl -s "$DR_API_URL/health" | jq .
# Expected: {"status": "healthy", "region": "eu-west-1"}
```

#### Step 5: Update SSM Parameters

```bash
# Record failover state
aws ssm put-parameter \
  --name "/bbws-access/prod/dr-state" \
  --value "FAILOVER_ACTIVE" \
  --type String \
  --overwrite \
  --region $DR_REGION

aws ssm put-parameter \
  --name "/bbws-access/prod/dr-failover-time" \
  --value "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --type String \
  --overwrite \
  --region $DR_REGION
```

### 4.3 Post-Failover Verification

```bash
# 1. Verify all services operational
./scripts/health-check.sh prod-dr

# 2. Check error rates
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Errors \
  --dimensions Name=FunctionName,Value=bbws-access-prod-lambda-* \
  --region $DR_REGION \
  --start-time $(date -u -d '10 minutes ago' +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 60 \
  --statistics Sum

# 3. Verify data integrity (sample check)
aws dynamodb scan \
  --table-name bbws-access-prod-ddb-access-management \
  --region $DR_REGION \
  --select COUNT
```

---

## 5. Failback Procedure

### 5.1 Pre-Failback Checklist

- [ ] Primary region (af-south-1) confirmed healthy
- [ ] Primary region infrastructure verified
- [ ] Data sync verified (no replication lag)
- [ ] Stakeholders notified
- [ ] Maintenance window scheduled
- [ ] Rollback plan ready

### 5.2 Failback Steps

#### Step 1: Verify Primary Region Recovery

```bash
export PRIMARY_REGION=af-south-1

# Check DynamoDB
aws dynamodb describe-table \
  --table-name bbws-access-prod-ddb-access-management \
  --region $PRIMARY_REGION \
  --query 'Table.TableStatus'

# Check Lambda functions
aws lambda list-functions \
  --region $PRIMARY_REGION \
  --query "Functions[?starts_with(FunctionName, 'bbws-access-prod-lambda-')] | length(@)"

# Check API Gateway
aws apigateway get-rest-apis \
  --region $PRIMARY_REGION \
  --query "items[?name=='bbws-access-prod-apigw'].id"
```

#### Step 2: Verify Data Sync

```bash
# Check Global Table replication status
aws dynamodb describe-table \
  --table-name bbws-access-prod-ddb-access-management \
  --region $PRIMARY_REGION \
  --query 'Table.Replicas[*].[RegionName,ReplicaStatus]'
# Expected: All regions show "ACTIVE"

# Compare record counts
DR_COUNT=$(aws dynamodb scan \
  --table-name bbws-access-prod-ddb-access-management \
  --region eu-west-1 \
  --select COUNT \
  --query 'Count' \
  --output text)

PRIMARY_COUNT=$(aws dynamodb scan \
  --table-name bbws-access-prod-ddb-access-management \
  --region af-south-1 \
  --select COUNT \
  --query 'Count' \
  --output text)

echo "DR: $DR_COUNT, Primary: $PRIMARY_COUNT"
# Counts should match
```

#### Step 3: Test Primary Region

```bash
# Run smoke tests against primary
pytest tests/smoke/ -v --environment=prod

# Verify health endpoint
curl -s "https://<primary-api>.execute-api.af-south-1.amazonaws.com/prod/health" | jq .
```

#### Step 4: Switch DNS Back to Primary

```bash
# Update Route 53 to point back to primary
aws route53 change-resource-record-sets \
  --hosted-zone-id $HOSTED_ZONE_ID \
  --change-batch '{
    "Changes": [{
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "access-api.example.com",
        "Type": "A",
        "AliasTarget": {
          "HostedZoneId": "<af-south-1-zone>",
          "DNSName": "<primary-api-gateway-domain>.execute-api.af-south-1.amazonaws.com",
          "EvaluateTargetHealth": true
        }
      }
    }]
  }'
```

#### Step 5: Update DR State

```bash
# Clear failover state
aws ssm put-parameter \
  --name "/bbws-access/prod/dr-state" \
  --value "NORMAL" \
  --type String \
  --overwrite \
  --region af-south-1

aws ssm put-parameter \
  --name "/bbws-access/prod/dr-failback-time" \
  --value "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --type String \
  --overwrite \
  --region af-south-1
```

---

## 6. DR Testing Schedule

### 6.1 Test Types

| Test Type | Frequency | Duration | Impact |
|-----------|-----------|----------|--------|
| Tabletop Exercise | Quarterly | 2 hours | None |
| Partial Failover | Semi-annually | 4 hours | None |
| Full Failover Drill | Annually | 8 hours | Planned downtime |

### 6.2 Test Procedure

```bash
# 1. Announce DR drill
# 2. Execute failover procedure
# 3. Run validation tests
# 4. Measure RTO/RPO
# 5. Execute failback
# 6. Document results

# DR drill script
./scripts/dr-drill.sh --type=full --dry-run=false
```

### 6.3 Success Criteria

| Metric | Target | Pass/Fail |
|--------|--------|-----------|
| Failover time | < 30 min | |
| Failback time | < 30 min | |
| Data loss | < 1 hour | |
| All services operational | 100% | |
| Smoke tests pass | 100% | |

---

## 7. Data Recovery Procedures

### 7.1 DynamoDB Point-in-Time Recovery

```bash
# Restore to specific point in time
RESTORE_TIME="2026-01-25T10:00:00Z"

aws dynamodb restore-table-to-point-in-time \
  --source-table-name bbws-access-prod-ddb-access-management \
  --target-table-name bbws-access-prod-ddb-access-management-restored \
  --restore-date-time $RESTORE_TIME \
  --region af-south-1

# Wait for restore to complete
aws dynamodb wait table-exists \
  --table-name bbws-access-prod-ddb-access-management-restored \
  --region af-south-1
```

### 7.2 S3 Data Recovery

```bash
# List object versions
aws s3api list-object-versions \
  --bucket bbws-access-prod-s3-audit-archive \
  --prefix audits/ \
  --max-keys 10

# Restore specific version
aws s3api get-object \
  --bucket bbws-access-prod-s3-audit-archive \
  --key audits/2026/01/audit-20260125.json.gz \
  --version-id <version-id> \
  restored-file.json.gz
```

---

## 8. Communication Plan

### 8.1 Notification Template - Failover Initiated

```
:rotating_light: **DR FAILOVER INITIATED**

Service: Access Management
Primary Region: af-south-1 (UNAVAILABLE)
DR Region: eu-west-1 (ACTIVATING)

Reason: [Region outage / Service degradation]
Started: [Timestamp]
Expected Duration: 30 minutes

Current Status: Failover in progress
Next Update: [Time]

Incident Commander: @[name]
War Room: [link]
```

### 8.2 Notification Template - Failover Complete

```
:white_check_mark: **DR FAILOVER COMPLETE**

Service: Access Management
Active Region: eu-west-1 (DR)
Status: OPERATIONAL

Failover Duration: [X minutes]
Data Loss: [None / X minutes]

All services verified operational.
Monitoring continues.

Next Steps:
- Monitor DR region performance
- Plan failback when primary recovers
```

### 8.3 Communication Channels

| Audience | Channel | Frequency |
|----------|---------|-----------|
| Engineering | Slack #incidents | Real-time |
| Leadership | Email + SMS | Key milestones |
| Customers | Status page | As needed |
| Support | Internal ticket | Continuous |

---

## 9. Contacts & Escalation

### 9.1 DR Team

| Role | Primary | Backup |
|------|---------|--------|
| Incident Commander | @devops-lead | @eng-director |
| Technical Lead | @platform-lead | @senior-engineer |
| Communications | @support-lead | @product-manager |
| Database | @dba-lead | @dba-oncall |

### 9.2 External Contacts

| Service | Contact | SLA |
|---------|---------|-----|
| AWS Support | Enterprise Support | 15 min response |
| DNS Provider | Support portal | 1 hour |
| Monitoring | PagerDuty | Immediate |

### 9.3 Escalation Matrix

| Time | Action |
|------|--------|
| 0 min | On-call engineer alerted |
| 5 min | Team lead notified |
| 15 min | Engineering director involved |
| 30 min | CTO briefed |
| 60 min | Executive team updated |

---

## 10. Appendix

### A. Region Information

| Region | Code | Use |
|--------|------|-----|
| Cape Town | af-south-1 | Primary (PROD) |
| Ireland | eu-west-1 | DR + DEV/SIT |

### B. DR Verification Commands

```bash
# Quick DR health check script
#!/bin/bash
DR_REGION=eu-west-1

echo "=== DynamoDB ==="
aws dynamodb describe-table \
  --table-name bbws-access-prod-ddb-access-management \
  --region $DR_REGION \
  --query 'Table.TableStatus'

echo "=== Lambda Count ==="
aws lambda list-functions \
  --region $DR_REGION \
  --query "Functions[?starts_with(FunctionName, 'bbws-access-prod-lambda-')] | length(@)"

echo "=== API Gateway ==="
aws apigateway get-rest-apis \
  --region $DR_REGION \
  --query "items[?name=='bbws-access-prod-apigw'].id"

echo "=== S3 Replication ==="
aws s3api head-bucket --bucket bbws-access-prod-s3-audit-archive-dr 2>&1
```

### C. DR Test Log Template

| Date | Test Type | RTO Achieved | RPO Achieved | Issues | Resolution |
|------|-----------|--------------|--------------|--------|------------|
| | | | | | |

---

**Document Control**

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-25 | DevOps Team | Initial version |
