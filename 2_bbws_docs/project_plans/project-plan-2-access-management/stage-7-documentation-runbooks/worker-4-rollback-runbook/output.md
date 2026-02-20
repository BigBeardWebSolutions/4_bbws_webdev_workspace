# Access Management - Rollback Runbook

**Document ID**: RUNBOOK-ACCESS-ROLLBACK-001
**Version**: 1.0
**Last Updated**: 2026-01-25
**Owner**: DevOps Team
**Review Frequency**: Quarterly

---

## 1. Overview

### 1.1 Purpose
This runbook provides step-by-step procedures for rolling back the Access Management system in case of deployment failures or critical issues.

### 1.2 Rollback Types

| Type | RTO | Use Case |
|------|-----|----------|
| Lambda Alias Rollback | < 5 min | Code bugs, performance issues |
| Terraform Rollback | < 15 min | Infrastructure misconfig |
| Database Restore | < 60 min | Data corruption |
| Full Service Rollback | < 30 min | Complete failure |

### 1.3 Decision Tree

```
Issue Detected
     │
     ▼
Is it code-related?
     │
     ├── YES → Lambda Alias Rollback
     │
     └── NO → Is it infrastructure?
                    │
                    ├── YES → Terraform Rollback
                    │
                    └── NO → Is it data corruption?
                                   │
                                   ├── YES → Database Restore
                                   │
                                   └── NO → Full Service Rollback
```

---

## 2. When to Rollback

### 2.1 Automatic Rollback Triggers

These conditions trigger automatic rollback:

| Condition | Threshold | Action |
|-----------|-----------|--------|
| Lambda Error Rate | > 5% for 2 min | Auto-rollback |
| Canary Health Fail | Any critical | Auto-rollback |
| Deployment Timeout | > 30 min | Auto-rollback |

### 2.2 Manual Rollback Criteria

Initiate manual rollback if:

- [ ] Critical functionality broken (authentication, authorization)
- [ ] Data integrity issues (incorrect data, data loss)
- [ ] Security vulnerability discovered
- [ ] Performance degradation > 3x baseline
- [ ] Customer-impacting issues reported by support
- [ ] Unexpected behavior affecting > 10% of users

### 2.3 Rollback Decision Matrix

| Severity | Impact | Decision | Approval |
|----------|--------|----------|----------|
| Critical | Service down | Immediate rollback | Post-hoc |
| High | Major feature broken | Rollback within 15 min | On-call lead |
| Medium | Minor feature affected | Assess fix vs rollback | Team decision |
| Low | Cosmetic issues | Do not rollback | N/A |

---

## 3. Lambda Alias Rollback

### 3.1 Overview

Lambda functions use aliases (`live`) pointing to specific versions. Rollback changes the alias to point to a previous version.

**Recovery Time**: < 5 minutes
**Data Impact**: None

### 3.2 Automated Rollback

```bash
# Trigger rollback workflow
gh workflow run rollback-lambda.yml \
  -f environment=prod \
  -f target_version=previous \
  -f services=all \
  -f reason="Post-deployment errors detected"

# Monitor rollback
gh run watch $(gh run list --workflow=rollback-lambda.yml --limit=1 --json databaseId -q '.[0].databaseId')
```

### 3.3 Manual Lambda Rollback

Use when automated rollback fails or for selective service rollback.

#### Step 1: Identify Current and Target Versions

```bash
export ENV=prod
export AWS_REGION=af-south-1

# Get current version for a function
aws lambda get-alias \
  --function-name bbws-access-$ENV-lambda-permission-create \
  --name live \
  --region $AWS_REGION \
  --query '[FunctionVersion, Description]'

# List available versions
aws lambda list-versions-by-function \
  --function-name bbws-access-$ENV-lambda-permission-create \
  --region $AWS_REGION \
  --query 'Versions[*].[Version, Description, LastModified]' \
  --output table
```

#### Step 2: Execute Rollback

```bash
# Set target version (the version to rollback TO)
TARGET_VERSION=5  # Previous stable version

# Rollback all functions in a service
FUNCTIONS=$(aws lambda list-functions \
  --region $AWS_REGION \
  --query "Functions[?starts_with(FunctionName, 'bbws-access-$ENV-lambda-permission')].FunctionName" \
  --output text)

for func in $FUNCTIONS; do
  echo "Rolling back $func to version $TARGET_VERSION..."

  aws lambda update-alias \
    --function-name $func \
    --name live \
    --function-version $TARGET_VERSION \
    --region $AWS_REGION

  echo "Done: $func"
done
```

#### Step 3: Verify Rollback

```bash
# Verify alias points to correct version
for func in $FUNCTIONS; do
  VERSION=$(aws lambda get-alias \
    --function-name $func \
    --name live \
    --region $AWS_REGION \
    --query 'FunctionVersion' \
    --output text)
  echo "$func: $VERSION"
done

# Run smoke tests
pytest tests/smoke/ -v --environment=$ENV
```

### 3.4 Service-Specific Rollback

To rollback only specific services:

```bash
# Rollback only Permission service
gh workflow run rollback-lambda.yml \
  -f environment=prod \
  -f target_version=previous \
  -f services=permission_service \
  -f reason="Permission service errors"

# Rollback multiple services
gh workflow run rollback-lambda.yml \
  -f environment=prod \
  -f target_version=previous \
  -f services=permission_service,role_service \
  -f reason="Permission and Role service errors"
```

---

## 4. Terraform Rollback

### 4.1 Overview

Terraform rollback restores infrastructure to a previous state by applying configuration from a previous commit.

**Recovery Time**: < 15 minutes
**Data Impact**: Possible (depends on changes)

### 4.2 Automated Terraform Rollback

```bash
# Find target commit
git log --oneline terraform/ | head -10

# Trigger rollback workflow
gh workflow run rollback-terraform.yml \
  -f environment=prod \
  -f target_commit=abc1234 \
  -f reason="Infrastructure misconfiguration"

# Workflow will:
# 1. Generate plan
# 2. Require approval
# 3. Apply changes
```

### 4.3 Manual Terraform Rollback

#### Step 1: Identify Target State

```bash
export ENV=prod
export AWS_REGION=af-south-1

# Find commit with working config
git log --oneline terraform/ | head -20

# Checkout target commit
git checkout abc1234 -- terraform/
```

#### Step 2: Plan Rollback

```bash
cd terraform

# Initialize
terraform init \
  -backend-config="bucket=bbws-access-$ENV-terraform-state" \
  -backend-config="key=access-management/terraform.tfstate" \
  -backend-config="region=$AWS_REGION"

# Generate plan
terraform plan \
  -var-file="environments/$ENV.tfvars" \
  -out=rollback.tfplan

# REVIEW PLAN CAREFULLY
# Check for any resource destructions
```

#### Step 3: Apply Rollback

```bash
# Apply only after reviewing plan
terraform apply rollback.tfplan

# Verify state
terraform state list | wc -l
```

### 4.4 Terraform State Recovery

If state is corrupted:

```bash
# List state backups in S3
aws s3 ls s3://bbws-access-$ENV-terraform-state/access-management/ --recursive

# Download previous state
aws s3 cp s3://bbws-access-$ENV-terraform-state/access-management/terraform.tfstate.backup ./

# Force push recovered state (USE WITH EXTREME CAUTION)
terraform state push -force terraform.tfstate.backup
```

---

## 5. Database Rollback

### 5.1 Overview

DynamoDB uses Point-in-Time Recovery (PITR). Restore creates a new table that must be swapped.

**Recovery Time**: 30-60 minutes
**Data Impact**: Data loss since restore point

### 5.2 PITR Restore Procedure

#### Step 1: Determine Restore Point

```bash
export ENV=prod
export TABLE_NAME=bbws-access-$ENV-ddb-access-management
export AWS_REGION=af-south-1

# Check PITR status
aws dynamodb describe-continuous-backups \
  --table-name $TABLE_NAME \
  --region $AWS_REGION \
  --query 'ContinuousBackupsDescription.PointInTimeRecoveryDescription'

# Earliest restore time is shown
```

#### Step 2: Restore to New Table

```bash
# Restore to a point in time
RESTORE_TIME="2026-01-25T10:00:00Z"  # ISO 8601 format

aws dynamodb restore-table-to-point-in-time \
  --source-table-name $TABLE_NAME \
  --target-table-name ${TABLE_NAME}-restored \
  --restore-date-time $RESTORE_TIME \
  --region $AWS_REGION

# Wait for restore (can take 30+ minutes)
aws dynamodb describe-table \
  --table-name ${TABLE_NAME}-restored \
  --region $AWS_REGION \
  --query 'Table.TableStatus'
```

#### Step 3: Swap Tables

```bash
# This requires application downtime

# 1. Stop all traffic (API Gateway throttle to 0)
aws apigateway update-stage \
  --rest-api-id <api-id> \
  --stage-name $ENV \
  --patch-operations op=replace,path=/throttling/rateLimit,value=0

# 2. Rename tables
aws dynamodb update-table \
  --table-name $TABLE_NAME \
  --table-name ${TABLE_NAME}-old

aws dynamodb update-table \
  --table-name ${TABLE_NAME}-restored \
  --table-name $TABLE_NAME

# 3. Restore traffic
aws apigateway update-stage \
  --rest-api-id <api-id> \
  --stage-name $ENV \
  --patch-operations op=replace,path=/throttling/rateLimit,value=1000
```

### 5.3 Data Verification

```bash
# Compare record counts
aws dynamodb scan \
  --table-name $TABLE_NAME \
  --select COUNT \
  --region $AWS_REGION

# Sample critical records
aws dynamodb query \
  --table-name $TABLE_NAME \
  --key-condition-expression "PK = :pk" \
  --expression-attribute-values '{":pk": {"S": "PERMISSION#perm_001"}}' \
  --region $AWS_REGION
```

---

## 6. Full Service Rollback

### 6.1 Overview

Complete rollback of all components when multiple systems are affected.

**Recovery Time**: < 30 minutes
**Impact**: Service temporarily unavailable

### 6.2 Procedure

#### Step 1: Notify Stakeholders

```
:rotating_light: **EMERGENCY ROLLBACK INITIATED**

Environment: PROD
Reason: [Brief description]
Expected Duration: 30 minutes
Initiated By: @username

Service will be temporarily unavailable.
```

#### Step 2: Execute Component Rollbacks

```bash
# 1. Rollback Lambda functions
gh workflow run rollback-lambda.yml \
  -f environment=prod \
  -f target_version=previous \
  -f services=all \
  -f reason="Full service rollback"

# Wait for completion
gh run watch <run-id>

# 2. Rollback Terraform (if needed)
gh workflow run rollback-terraform.yml \
  -f environment=prod \
  -f target_commit=<previous-commit> \
  -f reason="Full service rollback"

# Wait for completion
gh run watch <run-id>
```

#### Step 3: Verify Full System

```bash
# Run comprehensive tests
pytest tests/smoke/ tests/integration/ -v --environment=prod

# Verify all endpoints
./scripts/health-check.sh prod

# Check all alarms
aws cloudwatch describe-alarms \
  --alarm-name-prefix "bbws-access-prod" \
  --state-value ALARM \
  --region af-south-1
```

#### Step 4: Communicate Completion

```
:white_check_mark: **ROLLBACK COMPLETE**

Environment: PROD
Duration: 25 minutes
Status: Service restored

Previous version: v1.3.0
Rolled back to: v1.2.0

All health checks pass.
Incident ticket: INC-12345
```

---

## 7. Post-Rollback Actions

### 7.1 Immediate Actions

- [ ] Verify service health
- [ ] Update deployed version in SSM
- [ ] Notify stakeholders
- [ ] Create incident ticket

### 7.2 Documentation

- [ ] Record rollback details
- [ ] Document root cause (if known)
- [ ] Note rollback duration
- [ ] Update change request

### 7.3 Follow-Up Actions

- [ ] Schedule post-mortem
- [ ] Identify root cause
- [ ] Create fix tickets
- [ ] Update runbook if needed
- [ ] Review monitoring/alerting

---

## 8. Communication Templates

### 8.1 Rollback Initiated

```
:rotating_light: **Rollback Initiated**

Environment: [ENV]
Type: [Lambda/Terraform/Full]
Reason: [Brief description]
ETA: [Estimated duration]
Initiated By: @[username]

Current Status: In Progress
Incident: [INC-XXXXX]
```

### 8.2 Rollback Complete

```
:white_check_mark: **Rollback Complete**

Environment: [ENV]
Duration: [X minutes]
Previous Version: [vX.Y.Z]
Rolled Back To: [vX.Y.Z]

Verification:
- Health checks: PASS
- Smoke tests: PASS
- Alarms: OK

Next Steps:
- Post-mortem scheduled
- Fix in progress

Incident: [INC-XXXXX]
```

### 8.3 Rollback Failed

```
:x: **Rollback Failed**

Environment: [ENV]
Error: [Error description]
Current Status: Service degraded

Escalating to: @[escalation-contact]
War room: [link]

Incident: [INC-XXXXX]
```

---

## 9. Troubleshooting

### 9.1 Lambda Rollback Fails

| Issue | Resolution |
|-------|------------|
| "Alias not found" | Create alias first: `aws lambda create-alias` |
| "Version not found" | List versions, use valid version number |
| "Permission denied" | Check IAM permissions |
| "Function not found" | Verify function name and region |

### 9.2 Terraform Rollback Fails

| Issue | Resolution |
|-------|------------|
| "State lock" | Force unlock: `terraform force-unlock <id>` |
| "Resource in use" | Wait for dependent operations |
| "Invalid config" | Check commit has valid Terraform |
| "State mismatch" | Run `terraform refresh` first |

### 9.3 Database Restore Fails

| Issue | Resolution |
|-------|------------|
| "PITR not enabled" | Use manual backup instead |
| "Restore time invalid" | Check earliest/latest restore time |
| "Table already exists" | Use different target table name |
| "Capacity issues" | Reduce restore throughput |

---

## 10. Contacts & Escalation

### Rollback Authorization

| Environment | Who Can Authorize |
|-------------|-------------------|
| DEV | Any engineer |
| SIT | Team lead + |
| PROD | On-call lead, DevOps lead |

### Escalation Path

1. **On-call Engineer** - First responder
2. **On-call Lead** - Authorize PROD rollback
3. **DevOps Lead** - Complex rollbacks
4. **Engineering Director** - Escalation for extended outages

### Emergency Contacts

| Role | Contact | Method |
|------|---------|--------|
| On-Call | Rotation | PagerDuty |
| DevOps Lead | @devops-lead | Slack/Phone |
| Engineering Director | @eng-director | Phone |

---

## 11. Appendix

### A. Version Tracking

Versions are tracked in AWS SSM Parameter Store:

```bash
# Get deployed version
aws ssm get-parameter \
  --name "/bbws-access/$ENV/deployed-version" \
  --query 'Parameter.Value' \
  --output text

# Get deployment timestamp
aws ssm get-parameter \
  --name "/bbws-access/$ENV/deployed-at" \
  --query 'Parameter.Value' \
  --output text
```

### B. Rollback History

Query rollback history from DynamoDB:

```bash
aws dynamodb query \
  --table-name bbws-access-$ENV-ddb-deployments \
  --index-name GSI1 \
  --key-condition-expression "GSI1PK = :pk" \
  --expression-attribute-values '{":pk": {"S": "ENV#'$ENV'"}}' \
  --scan-index-forward false \
  --limit 10
```

---

**Document Control**

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-25 | DevOps Team | Initial version |
