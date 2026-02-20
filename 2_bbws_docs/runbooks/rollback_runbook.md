# Rollback Runbook

**Version:** 1.0
**Last Updated:** 2026-01-25
**Owner:** Platform Operations
**Severity Classification:** P1 (Critical)
**Document ID:** RB-003

---

## 1. Overview

This runbook provides comprehensive instructions for rolling back Lambda deployments, Terraform infrastructure, and DynamoDB data across the BBWS Customer Portal Private (CPP) platform. Rollbacks should be performed when a deployment introduces critical issues affecting service availability, data integrity, or user experience.

### 1.1 Scope

This runbook covers rollback procedures for:
- **Lambda Services**: `2_bbws_tenants_instances_lambda`, `2_bbws_wordpress_site_management_lambda`, `2_bbws_tenants_event_handler`
- **Terraform GitOps**: `2_bbws_tenants_instances_dev` (ECS WordPress instances)
- **DynamoDB Tables**: Point-in-time recovery procedures

### 1.2 When to Rollback

Rollback should be initiated when:
- Critical functionality is broken after deployment
- Error rates exceed defined thresholds
- Latency thresholds are breached
- Security vulnerabilities are discovered post-deployment
- Data corruption is detected
- Business stakeholders request immediate reversion

---

## 2. Rollback Decision Criteria

### 2.1 Error Rate Thresholds

| Severity | Error Rate | Action |
|----------|-----------|--------|
| Warning | 1-5% | Monitor closely, prepare rollback |
| Critical | 5-10% | Initiate rollback discussion |
| Emergency | >10% | Immediate rollback required |

### 2.2 Latency Thresholds

| Service | P95 Warning | P95 Critical | Action |
|---------|-------------|--------------|--------|
| API Gateway | >3s | >5s | Rollback if persists >5 min |
| Lambda | >10s | >25s | Immediate rollback |
| DynamoDB | >100ms | >500ms | Investigate, rollback if writes fail |

### 2.3 Business Impact Assessment

Before initiating rollback, assess:
- **User Impact**: Number of affected users/tenants
- **Revenue Impact**: Financial transactions affected
- **Data Integrity**: Risk of data loss or corruption
- **Regulatory Compliance**: POPIA/GDPR implications
- **Downtime Duration**: Estimated recovery time

### 2.4 Rollback Decision Matrix

| Impact Level | Affected Users | Revenue Impact | Decision |
|--------------|---------------|----------------|----------|
| Low | <10 | None | Monitor, fix forward |
| Medium | 10-100 | Minimal | Prepare rollback, notify stakeholders |
| High | 100-1000 | Moderate | Initiate rollback |
| Critical | >1000 | Significant | Immediate rollback, incident declared |

---

## 3. Environment Configuration

### 3.1 AWS Account Details

| Environment | AWS Account ID | Region | IAM Role |
|-------------|---------------|--------|----------|
| DEV | 536580886816 | af-south-1 / eu-west-1 | bbws-github-actions-role-dev |
| SIT | 815856636111 | af-south-1 / eu-west-1 | bbws-github-actions-role-sit |
| PROD | 093646564004 | af-south-1 | bbws-github-actions-role-prod |

### 3.2 Lambda Function Names

| Repository | DEV Function | SIT Function | PROD Function |
|------------|-------------|--------------|---------------|
| 2_bbws_tenants_instances_lambda | bbws-tenant-instance-management-dev | bbws-tenant-instance-management-sit | bbws-tenant-instance-management-prod |
| 2_bbws_wordpress_site_management_lambda | bbws-site-management-dev | bbws-site-management-sit | bbws-site-management-prod |
| 2_bbws_tenants_event_handler | bbws-ecs-event-handler-dev | bbws-ecs-event-handler-sit | bbws-ecs-event-handler-prod |

### 3.3 Terraform State Locations

| Repository | State Bucket | State Key |
|------------|--------------|-----------|
| 2_bbws_tenants_instances_dev | bbws-terraform-state-{env} | tenants/{tenant_id}/terraform.tfstate |
| 2_bbws_tenants_instances_lambda | bbws-terraform-state-{env} | tenant-instances-lambda/{env}/terraform.tfstate |

---

## 4. Lambda Version Rollback

### 4.1 Method 1: GitHub Actions (Recommended)

This is the preferred method as it provides automated verification and audit trails.

#### 4.1.1 Trigger Rollback Workflow

**Step 1**: Navigate to the repository's Actions tab on GitHub

**Step 2**: Select the "Rollback Lambda Deployment" workflow

**Step 3**: Click "Run workflow" and provide:
- **Environment**: Select `dev`, `sit`, or `prod`
- **Target Version**: Leave empty for previous version, or specify version number
- **Reason**: Document the reason for rollback (required)

**Step 4**: For PROD environment, wait for approval from designated reviewers

**Step 5**: Monitor workflow execution and verify post-rollback health checks

#### 4.1.2 GitHub CLI Method

```bash
# For 2_bbws_tenants_instances_lambda
gh workflow run rollback.yml \
  --repo BigBeardWebSolutions/2_bbws_tenants_instances_lambda \
  -f environment=dev \
  -f target_version="" \
  -f reason="High error rate after deployment - 15% 5xx errors"

# For 2_bbws_tenants_event_handler
gh workflow run rollback.yml \
  --repo BigBeardWebSolutions/2_bbws_tenants_event_handler \
  -f environment=dev \
  -f target_version="" \
  -f reason="Event processing failures after deployment"

# Monitor workflow status
gh run watch --repo BigBeardWebSolutions/2_bbws_tenants_instances_lambda
```

### 4.2 Method 2: AWS CLI (Direct)

Use this method when GitHub Actions is unavailable or for urgent rollbacks.

#### 4.2.1 List Available Versions

```bash
# Set environment variables
ENV="dev"  # Change to sit or prod as needed
REGION="af-south-1"
ACCOUNT_ID="536580886816"  # DEV account

# For SIT
# ACCOUNT_ID="815856636111"
# For PROD
# ACCOUNT_ID="093646564004"

# List Lambda versions
FUNCTION_NAME="bbws-tenant-instance-management-${ENV}"

aws lambda list-versions-by-function \
  --function-name $FUNCTION_NAME \
  --region $REGION \
  --query 'Versions[?Version!=`$LATEST`].{Version:Version,LastModified:LastModified,Description:Description}' \
  --output table
```

#### 4.2.2 List Available Aliases

```bash
# List aliases including backup aliases
aws lambda list-aliases \
  --function-name $FUNCTION_NAME \
  --region $REGION \
  --query 'Aliases[].{Name:Name,Version:FunctionVersion,Description:Description}' \
  --output table
```

#### 4.2.3 Get Current Alias Configuration

```bash
# Get current alias version
aws lambda get-alias \
  --function-name $FUNCTION_NAME \
  --name latest-${ENV} \
  --region $REGION \
  --query '{AliasArn:AliasArn,FunctionVersion:FunctionVersion,Description:Description}' \
  --output table
```

#### 4.2.4 Execute Rollback

```bash
# Determine target version (previous version)
TARGET_VERSION="5"  # Replace with actual target version

# Create checkpoint alias before rollback
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
CURRENT_VERSION=$(aws lambda get-alias \
  --function-name $FUNCTION_NAME \
  --name latest-${ENV} \
  --region $REGION \
  --query 'FunctionVersion' \
  --output text)

aws lambda create-alias \
  --function-name $FUNCTION_NAME \
  --name rollback-checkpoint-${TIMESTAMP} \
  --function-version $CURRENT_VERSION \
  --description "Checkpoint before rollback by $(whoami) at ${TIMESTAMP}" \
  --region $REGION

# Update alias to previous version
aws lambda update-alias \
  --function-name $FUNCTION_NAME \
  --name latest-${ENV} \
  --function-version $TARGET_VERSION \
  --description "Rollback to v${TARGET_VERSION} on $(date -u +%Y-%m-%d)" \
  --region $REGION

echo "Rollback executed: ${FUNCTION_NAME} alias latest-${ENV} now points to version ${TARGET_VERSION}"
```

#### 4.2.5 Verify Rollback

```bash
# Verify alias update
aws lambda get-alias \
  --function-name $FUNCTION_NAME \
  --name latest-${ENV} \
  --region $REGION

# Invoke health check
aws lambda invoke \
  --function-name ${FUNCTION_NAME}:latest-${ENV} \
  --payload '{"httpMethod":"GET","path":"/health","headers":{}}' \
  --region $REGION \
  response.json

cat response.json | jq .
```

### 4.3 Method 3: AWS Console

Use this method for operators unfamiliar with CLI or for visual verification.

**Step 1**: Open AWS Lambda Console
- Navigate to: `https://${REGION}.console.aws.amazon.com/lambda/home?region=${REGION}#/functions`
- Sign in with appropriate IAM credentials

**Step 2**: Find the Lambda Function
- Search for `bbws-tenant-instance-management-${ENV}`
- Click on the function name

**Step 3**: Navigate to Aliases
- Click on "Aliases" tab
- Find the `latest-${ENV}` alias

**Step 4**: Edit Alias
- Click "Edit" on the alias
- Change the "Version" dropdown to the target version
- Update the description with rollback reason
- Click "Save"

**Step 5**: Verify
- Test the function using the Test tab
- Monitor CloudWatch Logs for errors

### 4.4 Rollback All Services Script

For coordinated rollback of all Lambda services:

```bash
#!/bin/bash
# rollback_all_services.sh
# Usage: ./rollback_all_services.sh <environment> <reason>

ENV=$1
REASON=$2
REGION="af-south-1"

if [ -z "$ENV" ] || [ -z "$REASON" ]; then
  echo "Usage: ./rollback_all_services.sh <env> <reason>"
  exit 1
fi

# Set account ID based on environment
case $ENV in
  dev) ACCOUNT_ID="536580886816" ;;
  sit) ACCOUNT_ID="815856636111" ;;
  prod) ACCOUNT_ID="093646564004" ;;
  *) echo "Invalid environment"; exit 1 ;;
esac

FUNCTIONS=(
  "bbws-tenant-instance-management-${ENV}"
  "bbws-site-management-${ENV}"
  "bbws-ecs-event-handler-${ENV}"
)

TIMESTAMP=$(date +%Y%m%d-%H%M%S)

for FUNCTION_NAME in "${FUNCTIONS[@]}"; do
  echo "Rolling back ${FUNCTION_NAME}..."

  # Get current version
  CURRENT_VERSION=$(aws lambda get-alias \
    --function-name $FUNCTION_NAME \
    --name latest-${ENV} \
    --region $REGION \
    --query 'FunctionVersion' \
    --output text 2>/dev/null)

  if [ "$CURRENT_VERSION" == "None" ] || [ -z "$CURRENT_VERSION" ]; then
    echo "Warning: Could not get current version for $FUNCTION_NAME, skipping..."
    continue
  fi

  # Find previous version
  PREVIOUS_VERSION=$(aws lambda list-versions-by-function \
    --function-name $FUNCTION_NAME \
    --region $REGION \
    --query 'Versions[?Version!=`$LATEST`].Version' \
    --output json | jq -r ".[-2] // empty")

  if [ -z "$PREVIOUS_VERSION" ]; then
    echo "Warning: No previous version found for $FUNCTION_NAME, skipping..."
    continue
  fi

  # Create checkpoint
  aws lambda create-alias \
    --function-name $FUNCTION_NAME \
    --name rollback-checkpoint-${TIMESTAMP} \
    --function-version $CURRENT_VERSION \
    --description "Checkpoint before bulk rollback: ${REASON}" \
    --region $REGION 2>/dev/null || true

  # Execute rollback
  aws lambda update-alias \
    --function-name $FUNCTION_NAME \
    --name latest-${ENV} \
    --function-version $PREVIOUS_VERSION \
    --description "Rollback to v${PREVIOUS_VERSION}: ${REASON}" \
    --region $REGION

  echo "Rolled back ${FUNCTION_NAME} from v${CURRENT_VERSION} to v${PREVIOUS_VERSION}"
done

echo "All services rolled back. Please verify functionality."
```

---

## 5. Terraform State Rollback

### 5.1 GitOps Repository Rollback (2_bbws_tenants_instances_dev)

For tenant WordPress instance infrastructure managed via GitOps.

#### 5.1.1 Identify Previous Known-Good State

```bash
# Clone the repository
git clone https://github.com/BigBeardWebSolutions/2_bbws_tenants_instances_dev.git
cd 2_bbws_tenants_instances_dev

# Find recent commits/tags
git log --oneline -20
git tag -l "deploy-*" --sort=-creatordate | head -10

# Find the last known-good deployment tag
GOOD_TAG=$(git tag -l "deploy-tenant-${TENANT_ID}-dev-*" --sort=-creatordate | sed -n '2p')
echo "Previous deployment tag: $GOOD_TAG"
```

#### 5.1.2 Rollback via GitHub Actions

**Step 1**: Navigate to Actions tab in the repository

**Step 2**: Find "Emergency Tenant Rollback" workflow (if available) or use manual steps

**Step 3**: Alternatively, create a revert commit:

```bash
# Checkout the repository
cd 2_bbws_tenants_instances_dev

# Find the problematic commit
git log --oneline tenants/${TENANT_ID}/

# Revert to previous state
git revert HEAD --no-edit

# Push to trigger deployment
git push origin main
```

#### 5.1.3 Manual Terraform Rollback

```bash
# Set variables
TENANT_ID="tenant-example"
ENV="dev"
REGION="af-south-1"
STATE_BUCKET="bbws-terraform-state-dev"
LOCK_TABLE="bbws-terraform-locks-dev"

# Navigate to tenant directory
cd 2_bbws_tenants_instances_dev/tenants/${TENANT_ID}

# Initialize Terraform
terraform init \
  -backend-config="bucket=${STATE_BUCKET}" \
  -backend-config="key=tenants/${TENANT_ID}/terraform.tfstate" \
  -backend-config="region=${REGION}" \
  -backend-config="dynamodb_table=${LOCK_TABLE}" \
  -backend-config="encrypt=true"

# Check current state
terraform show

# Checkout the previous known-good configuration
git checkout ${GOOD_TAG} -- .

# Plan the rollback
terraform plan -out=rollback.tfplan

# Review the plan carefully
terraform show rollback.tfplan

# Apply the rollback (requires confirmation)
terraform apply rollback.tfplan
```

### 5.2 Terraform State File Recovery

#### 5.2.1 List State File Versions

```bash
# List S3 versions for state file
aws s3api list-object-versions \
  --bucket ${STATE_BUCKET} \
  --prefix "tenants/${TENANT_ID}/terraform.tfstate" \
  --query 'Versions[].{VersionId:VersionId,LastModified:LastModified,IsLatest:IsLatest}' \
  --output table
```

#### 5.2.2 Restore Previous State Version

```bash
# Get specific version
VERSION_ID="abc123def456..."  # Replace with actual version ID

# Download previous state
aws s3api get-object \
  --bucket ${STATE_BUCKET} \
  --key "tenants/${TENANT_ID}/terraform.tfstate" \
  --version-id ${VERSION_ID} \
  previous-state.tfstate

# Review the state file
cat previous-state.tfstate | jq '.resources[].type'

# Backup current state
aws s3 cp \
  s3://${STATE_BUCKET}/tenants/${TENANT_ID}/terraform.tfstate \
  s3://${STATE_BUCKET}/tenants/${TENANT_ID}/terraform.tfstate.backup-$(date +%Y%m%d-%H%M%S)

# Restore previous state (CAUTION: This overwrites current state)
aws s3 cp previous-state.tfstate \
  s3://${STATE_BUCKET}/tenants/${TENANT_ID}/terraform.tfstate
```

### 5.3 Terraform State Lock Management

```bash
# Check for stuck locks
aws dynamodb scan \
  --table-name ${LOCK_TABLE} \
  --filter-expression "contains(LockID, :tenant)" \
  --expression-attribute-values '{":tenant":{"S":"'${TENANT_ID}'"}}' \
  --output table

# Force unlock if needed (CAUTION)
terraform force-unlock ${LOCK_ID}
```

---

## 6. DynamoDB Point-in-Time Recovery

### 6.1 When to Use PITR

Use DynamoDB PITR when:
- Data corruption occurred after deployment
- Accidental bulk delete or update
- Application bug caused invalid data writes
- Need to recover data from specific point in time

### 6.2 Prerequisites

```bash
# Verify PITR is enabled
aws dynamodb describe-continuous-backups \
  --table-name tenants-${ENV} \
  --region ${REGION} \
  --query 'ContinuousBackupsDescription.PointInTimeRecoveryDescription.PointInTimeRecoveryStatus'
```

### 6.3 Identify Recovery Point

```bash
# Get earliest and latest restore times
aws dynamodb describe-continuous-backups \
  --table-name tenants-${ENV} \
  --region ${REGION} \
  --query 'ContinuousBackupsDescription.PointInTimeRecoveryDescription.{EarliestRestorableDateTime:EarliestRestorableDateTime,LatestRestorableDateTime:LatestRestorableDateTime}'
```

### 6.4 Restore Table

```bash
# Set recovery time (before the issue occurred)
RESTORE_TIME="2026-01-25T10:00:00Z"
SOURCE_TABLE="tenants-${ENV}"
TARGET_TABLE="tenants-${ENV}-restored-$(date +%Y%m%d%H%M%S)"

# Restore to new table
aws dynamodb restore-table-to-point-in-time \
  --source-table-name ${SOURCE_TABLE} \
  --target-table-name ${TARGET_TABLE} \
  --restore-date-time ${RESTORE_TIME} \
  --region ${REGION}

# Monitor restore progress
aws dynamodb describe-table \
  --table-name ${TARGET_TABLE} \
  --region ${REGION} \
  --query 'Table.TableStatus'
```

### 6.5 Verify Restored Data

```bash
# Compare record counts
ORIGINAL_COUNT=$(aws dynamodb scan --table-name ${SOURCE_TABLE} --select "COUNT" --region ${REGION} --query 'Count')
RESTORED_COUNT=$(aws dynamodb scan --table-name ${TARGET_TABLE} --select "COUNT" --region ${REGION} --query 'Count')

echo "Original table count: $ORIGINAL_COUNT"
echo "Restored table count: $RESTORED_COUNT"

# Sample data comparison
aws dynamodb scan \
  --table-name ${TARGET_TABLE} \
  --max-items 10 \
  --region ${REGION}
```

### 6.6 Switch to Restored Table

**Option A: Update Lambda Environment Variables**

```bash
# Update all Lambda functions to use restored table
for FUNCTION_NAME in bbws-tenant-instance-management-${ENV} bbws-site-management-${ENV}; do
  aws lambda update-function-configuration \
    --function-name $FUNCTION_NAME \
    --environment Variables="{DYNAMODB_TABLE=${TARGET_TABLE},...}" \
    --region ${REGION}
done
```

**Option B: Rename Tables (Recommended for Production)**

```bash
# This requires careful orchestration:
# 1. Stop all writes (set Lambda concurrency to 0)
# 2. Rename original table to backup name
# 3. Rename restored table to original name
# 4. Resume writes

# Note: DynamoDB does not support table rename - you must:
# 1. Create new table with original name
# 2. Copy data from restored table
# 3. Delete old and restored tables
```

### 6.7 Tables Requiring PITR Configuration

| Table Name | Environment | PITR Status |
|------------|-------------|-------------|
| tenants-{env} | DEV/SIT/PROD | Required |
| users-{env} | DEV/SIT/PROD | Required |
| tenant-instances-{env} | DEV/SIT/PROD | Required |
| sites-{env} | DEV/SIT/PROD | Required |
| bbws-deployments-{env} | DEV/SIT/PROD | Recommended |

---

## 7. Post-Rollback Verification

### 7.1 Lambda Verification Checklist

```bash
# Set variables
ENV="dev"
REGION="af-south-1"

# 1. Verify alias configuration
for FUNC in bbws-tenant-instance-management bbws-site-management bbws-ecs-event-handler; do
  echo "=== ${FUNC}-${ENV} ==="
  aws lambda get-alias \
    --function-name ${FUNC}-${ENV} \
    --name latest-${ENV} \
    --region ${REGION} \
    --query '{Version:FunctionVersion,Description:Description}'
done

# 2. Health check invocation
aws lambda invoke \
  --function-name bbws-tenant-instance-management-${ENV}:latest-${ENV} \
  --payload '{"httpMethod":"GET","path":"/health","headers":{}}' \
  --region ${REGION} \
  health-response.json

cat health-response.json | jq .

# 3. Monitor error rates (5 minute window)
for FUNC in bbws-tenant-instance-management bbws-site-management bbws-ecs-event-handler; do
  ERRORS=$(aws cloudwatch get-metric-statistics \
    --namespace AWS/Lambda \
    --metric-name Errors \
    --dimensions Name=FunctionName,Value=${FUNC}-${ENV} \
    --start-time $(date -u -v-5M +%Y-%m-%dT%H:%M:%SZ) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
    --period 300 \
    --statistics Sum \
    --region ${REGION} \
    --query 'Datapoints[0].Sum' \
    --output text)
  echo "${FUNC}-${ENV}: Errors = ${ERRORS:-0}"
done

# 4. Check invocation count
for FUNC in bbws-tenant-instance-management bbws-site-management; do
  INVOCATIONS=$(aws cloudwatch get-metric-statistics \
    --namespace AWS/Lambda \
    --metric-name Invocations \
    --dimensions Name=FunctionName,Value=${FUNC}-${ENV} \
    --start-time $(date -u -v-5M +%Y-%m-%dT%H:%M:%SZ) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
    --period 300 \
    --statistics Sum \
    --region ${REGION} \
    --query 'Datapoints[0].Sum' \
    --output text)
  echo "${FUNC}-${ENV}: Invocations = ${INVOCATIONS:-0}"
done
```

### 7.2 API Endpoint Verification

```bash
# Get API Gateway URL
API_URL="https://api-${ENV}.bbws.example.com"

# Test tenant endpoints
curl -s ${API_URL}/v1/tenants | jq '.status'
curl -s ${API_URL}/v1/health | jq .
```

### 7.3 Infrastructure Verification (Terraform)

```bash
# Verify Terraform state
terraform state list

# Check for drift
terraform plan -detailed-exitcode

# Verify ECS service status (if applicable)
aws ecs describe-services \
  --cluster bbws-cluster-${ENV} \
  --services bbws-wordpress-${TENANT_ID} \
  --region ${REGION} \
  --query 'services[0].{Status:status,RunningCount:runningCount,DesiredCount:desiredCount}'
```

### 7.4 Verification Checklist

| Check | Command/Action | Expected Result |
|-------|---------------|-----------------|
| Lambda alias version | `aws lambda get-alias` | Points to rollback version |
| Health endpoint | `curl /health` | HTTP 200 |
| Error rate | CloudWatch metrics | < 1% |
| Latency P95 | CloudWatch metrics | < 3s |
| Log errors | CloudWatch Logs | No new errors |
| API responses | Sample API calls | Valid JSON responses |
| DynamoDB reads | Sample queries | Data accessible |
| ECS tasks (if applicable) | `aws ecs describe-tasks` | Running |

---

## 8. Incident Documentation Template

Use this template to document every rollback incident.

```markdown
# Rollback Incident Report

## Incident Summary
- **Incident ID**: INC-YYYYMMDD-XXX
- **Date/Time**: YYYY-MM-DD HH:MM UTC
- **Environment**: DEV / SIT / PROD
- **Severity**: P1 / P2 / P3
- **Duration**: X hours Y minutes

## Affected Services
- [ ] bbws-tenant-instance-management-{env}
- [ ] bbws-site-management-{env}
- [ ] bbws-ecs-event-handler-{env}
- [ ] Terraform infrastructure
- [ ] DynamoDB tables

## Timeline
| Time (UTC) | Event |
|------------|-------|
| HH:MM | Issue detected |
| HH:MM | Investigation started |
| HH:MM | Rollback decision made |
| HH:MM | Rollback initiated |
| HH:MM | Rollback completed |
| HH:MM | Verification completed |
| HH:MM | Incident resolved |

## Root Cause
[Describe what caused the issue requiring rollback]

## Impact
- **Users Affected**: X
- **Transactions Affected**: Y
- **Revenue Impact**: R ZAR
- **Data Impact**: [Describe any data loss or corruption]

## Rollback Details
- **Method Used**: GitHub Actions / AWS CLI / Console
- **Rolled Back From**: Version X
- **Rolled Back To**: Version Y
- **Workflow Run**: [Link to GitHub Actions run]

## Verification Results
| Check | Result |
|-------|--------|
| Lambda health | PASS / FAIL |
| API endpoints | PASS / FAIL |
| Error rate | X% |
| Data integrity | PASS / FAIL |

## Lessons Learned
1. [What could have prevented this?]
2. [What can be improved?]

## Action Items
| Action | Owner | Due Date | Status |
|--------|-------|----------|--------|
| [Action item] | [Name] | YYYY-MM-DD | Open |

## Approvals
- **Rollback Approved By**: [Name]
- **Incident Closed By**: [Name]
- **Post-Mortem Completed**: Yes / No
```

---

## 9. Communication Plan

### 9.1 Stakeholder Notification Matrix

| Stakeholder | Environment | Notification Method | Timing |
|-------------|-------------|---------------------|--------|
| Engineering Team | All | Slack #platform-alerts | Immediate |
| On-Call Manager | SIT/PROD | PagerDuty | Immediate |
| Product Team | PROD | Email/Slack | Within 15 min |
| Customer Support | PROD | Slack #support | Within 15 min |
| Executive Team | PROD (P1) | Email | Within 30 min |
| Affected Customers | PROD | Status Page | After verification |

### 9.2 Communication Templates

#### 9.2.1 Initial Notification (Internal)

```
ROLLBACK INITIATED - [ENVIRONMENT]

Service: [Lambda/Infrastructure/Database]
Environment: [DEV/SIT/PROD]
Reason: [Brief description]
Impact: [Affected functionality]
Initiated by: [Name]
ETA for completion: [Time]

Tracking: [Incident ticket link]
Workflow: [GitHub Actions run link]
```

#### 9.2.2 Rollback Complete (Internal)

```
ROLLBACK COMPLETED - [ENVIRONMENT]

Service: [Lambda/Infrastructure/Database]
Environment: [DEV/SIT/PROD]
Rolled back from: Version X
Rolled back to: Version Y
Duration: [X minutes]

Verification Status:
- Lambda health: [PASS/FAIL]
- API endpoints: [PASS/FAIL]
- Error rate: [X%]

Next Steps: [Post-mortem scheduled / Fix in progress]
```

#### 9.2.3 Customer-Facing (Status Page)

```
Investigating - We are currently investigating an issue affecting [service].

Update - We have identified the issue and are implementing a fix.

Resolved - The issue has been resolved. All services are operating normally.
We apologize for any inconvenience caused.
```

### 9.3 PROD Rollback Special Procedures

Before initiating PROD rollback:

1. **Notify stakeholders** using the matrix above
2. **Document the reason** for rollback with evidence
3. **Create an incident ticket** in the tracking system
4. **Obtain approval** from:
   - Engineering Lead (for technical sign-off)
   - Product Owner (for business impact assessment)
5. **Coordinate with Customer Support** for user communication
6. **Schedule post-mortem** within 48 hours

During PROD rollback:

1. **Maintain communication** via Slack #incident-[date]
2. **Document all actions** with timestamps
3. **Verify each step** before proceeding

After PROD rollback:

1. **Perform comprehensive health check** (Section 7)
2. **Update status page** with resolution
3. **Send all-clear notification** to stakeholders
4. **Complete incident documentation** (Section 8)
5. **Conduct post-mortem** within 48 hours

---

## 10. Quick Reference Commands

### 10.1 DEV Environment

```bash
# Set DEV environment
export ENV="dev"
export REGION="af-south-1"
export ACCOUNT_ID="536580886816"

# List Lambda versions
aws lambda list-versions-by-function \
  --function-name bbws-tenant-instance-management-dev \
  --region af-south-1 \
  --query 'Versions[-5:].{Version:Version,Modified:LastModified}'

# Rollback Lambda alias
aws lambda update-alias \
  --function-name bbws-tenant-instance-management-dev \
  --name latest-dev \
  --function-version <TARGET_VERSION> \
  --region af-south-1

# Health check
aws lambda invoke \
  --function-name bbws-tenant-instance-management-dev:latest-dev \
  --payload '{"httpMethod":"GET","path":"/health","headers":{}}' \
  --region af-south-1 \
  response.json && cat response.json
```

### 10.2 SIT Environment

```bash
# Set SIT environment
export ENV="sit"
export REGION="af-south-1"
export ACCOUNT_ID="815856636111"

# List Lambda versions
aws lambda list-versions-by-function \
  --function-name bbws-tenant-instance-management-sit \
  --region af-south-1 \
  --query 'Versions[-5:].{Version:Version,Modified:LastModified}'

# Rollback Lambda alias
aws lambda update-alias \
  --function-name bbws-tenant-instance-management-sit \
  --name latest-sit \
  --function-version <TARGET_VERSION> \
  --region af-south-1

# Health check
aws lambda invoke \
  --function-name bbws-tenant-instance-management-sit:latest-sit \
  --payload '{"httpMethod":"GET","path":"/health","headers":{}}' \
  --region af-south-1 \
  response.json && cat response.json
```

### 10.3 PROD Environment

```bash
# Set PROD environment
export ENV="prod"
export REGION="af-south-1"
export ACCOUNT_ID="093646564004"

# IMPORTANT: PROD requires approval before rollback

# List Lambda versions
aws lambda list-versions-by-function \
  --function-name bbws-tenant-instance-management-prod \
  --region af-south-1 \
  --query 'Versions[-5:].{Version:Version,Modified:LastModified}'

# Rollback Lambda alias (REQUIRES APPROVAL)
aws lambda update-alias \
  --function-name bbws-tenant-instance-management-prod \
  --name latest-prod \
  --function-version <TARGET_VERSION> \
  --region af-south-1

# Health check
aws lambda invoke \
  --function-name bbws-tenant-instance-management-prod:latest-prod \
  --payload '{"httpMethod":"GET","path":"/health","headers":{}}' \
  --region af-south-1 \
  response.json && cat response.json
```

---

## 11. Escalation Contacts

| Role | Name/Team | Contact Method | When to Escalate |
|------|-----------|---------------|------------------|
| On-Call Engineer | Platform Team | PagerDuty | First responder |
| Engineering Lead | [Name] | Slack/Phone | P1/P2 incidents |
| DevOps Lead | [Name] | Slack/Phone | Infrastructure issues |
| Product Owner | [Name] | Slack/Email | Business impact decisions |
| Security Team | Security | security@company.com | Security concerns |
| AWS Support | Premium Support | AWS Console | AWS service issues |

---

## 12. Related Documents

| Document | Purpose |
|----------|---------|
| RB-001_Tenant_Provisioning.md | Tenant provisioning troubleshooting |
| RB-002_Site_Generation_Troubleshooting.md | Site generation issues |
| product_lambda_disaster_recovery.md | DR procedures |
| product_lambda_cicd_guide.md | CI/CD pipeline guide |
| CPP_DR_Runbook.md | Customer Portal DR |

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-25 | Platform Team | Initial version |

---

**End of Runbook**
