# Access Management - Deployment Runbook

**Document ID**: RUNBOOK-ACCESS-DEPLOY-001
**Version**: 1.0
**Last Updated**: 2026-01-25
**Owner**: DevOps Team
**Review Frequency**: Quarterly

---

## 1. Overview

### 1.1 Purpose
This runbook provides step-by-step procedures for deploying the Access Management system to DEV, SIT, and PROD environments.

### 1.2 Scope
- Infrastructure deployment (Terraform)
- Lambda function deployment
- API Gateway configuration
- Post-deployment verification

### 1.3 Audience
- DevOps Engineers
- Platform Engineers
- On-call Support Engineers

---

## 2. Prerequisites

### 2.1 Access Requirements

| Resource | Access Level | How to Request |
|----------|--------------|----------------|
| AWS Console | PowerUser | ServiceNow ticket |
| GitHub Repository | Write | Team lead approval |
| Terraform State Bucket | Read/Write | AWS IAM team |
| Slack #deployments | Member | Self-join |

### 2.2 Tools Required

```bash
# Verify tool versions
terraform --version    # >= 1.6.0
aws --version          # >= 2.x
python --version       # >= 3.12
gh --version           # GitHub CLI
```

### 2.3 Environment Information

| Environment | AWS Account | Region | Branch |
|-------------|-------------|--------|--------|
| DEV | 536580886816 | eu-west-1 | develop |
| SIT | 815856636111 | eu-west-1 | release/* |
| PROD | 093646564004 | af-south-1 | main |

### 2.4 Required Secrets

Verify GitHub repository secrets are configured:
- AWS OIDC roles configured for each environment
- `SLACK_WEBHOOK_URL` for notifications

---

## 3. Pre-Deployment Checklist

### 3.1 Before Any Deployment

- [ ] Verify you have the correct AWS credentials configured
- [ ] Check for any active incidents in the target environment
- [ ] Verify no other deployments are in progress
- [ ] Review recent commits/changes to be deployed
- [ ] Notify team in #deployments Slack channel

### 3.2 DEV Deployment Checklist

- [ ] All unit tests pass locally
- [ ] PR merged to `develop` branch
- [ ] No blocking issues in DEV environment

### 3.3 SIT Deployment Checklist

- [ ] DEV deployment verified and stable (24+ hours)
- [ ] All integration tests pass in DEV
- [ ] Release branch created (`release/vX.Y.Z`)
- [ ] QA team notified for UAT

### 3.4 PROD Deployment Checklist

- [ ] SIT deployment verified and UAT complete
- [ ] Change request approved
- [ ] Rollback plan documented
- [ ] On-call engineer available
- [ ] Deployment window confirmed (off-peak hours)
- [ ] Stakeholders notified

---

## 4. Deployment Procedures

### 4.1 Automated Deployment (Recommended)

#### 4.1.1 DEV Deployment

DEV deploys automatically on push to `develop` branch.

```bash
# Trigger deployment by pushing to develop
git checkout develop
git pull origin develop
git merge feature/your-feature
git push origin develop

# Monitor deployment
gh run list --workflow=lambda-deploy-dev.yml
gh run watch <run-id>
```

**Expected Duration**: 5-10 minutes

#### 4.1.2 SIT Deployment

```bash
# Create release and promote to SIT
gh workflow run promote-to-sit.yml \
  -f version=v1.2.0 \
  -f skip_tests=false

# Monitor deployment
gh run list --workflow=promote-to-sit.yml
gh run watch <run-id>
```

**Expected Duration**: 15-20 minutes

#### 4.1.3 PROD Deployment

```bash
# Promote to PROD (requires approval)
gh workflow run promote-to-prod.yml \
  -f version=v1.2.0 \
  -f release_notes="Bug fixes and performance improvements"

# Approve in GitHub UI when prompted
# Monitor deployment
gh run list --workflow=promote-to-prod.yml
gh run watch <run-id>
```

**Expected Duration**: 20-30 minutes (including canary)

---

### 4.2 Manual Deployment

Use only when automated deployment fails.

#### 4.2.1 Infrastructure Deployment (Terraform)

```bash
# Set environment
export ENV=dev  # or sit, prod
export AWS_REGION=eu-west-1  # af-south-1 for prod

# Authenticate to AWS
aws sso login --profile bbws-$ENV

# Navigate to terraform directory
cd terraform

# Initialize Terraform
terraform init \
  -backend-config="bucket=bbws-access-$ENV-terraform-state" \
  -backend-config="key=access-management/terraform.tfstate" \
  -backend-config="region=$AWS_REGION"

# Review plan
terraform plan -var-file="environments/$ENV.tfvars" -out=tfplan

# Apply changes (review plan output first!)
terraform apply tfplan
```

**Verification**:
```bash
# Verify DynamoDB table
aws dynamodb describe-table \
  --table-name bbws-access-$ENV-ddb-access-management \
  --query 'Table.TableStatus'

# Expected output: "ACTIVE"
```

#### 4.2.2 Lambda Deployment

```bash
# Build Lambda packages
chmod +x scripts/build-lambdas.sh
./scripts/build-lambdas.sh

# Deploy to environment
chmod +x scripts/deploy-lambdas.sh
./scripts/deploy-lambdas.sh $ENV v1.2.0

# Update aliases
chmod +x scripts/update-aliases.sh
./scripts/update-aliases.sh $ENV live
```

**Verification**:
```bash
# Verify Lambda functions
aws lambda list-functions \
  --query "Functions[?starts_with(FunctionName, 'bbws-access-$ENV-lambda-')].FunctionName" \
  --output table

# Check function version
aws lambda get-alias \
  --function-name bbws-access-$ENV-lambda-permission-create \
  --name live
```

---

## 5. Post-Deployment Verification

### 5.1 Smoke Tests

```bash
# Run automated smoke tests
pytest tests/smoke/ -v \
  --environment=$ENV \
  --junitxml=smoke-results.xml

# Or use the script
chmod +x scripts/run-smoke-tests.sh
./scripts/run-smoke-tests.sh $ENV
```

### 5.2 Health Check Endpoints

```bash
# Get API Gateway URL
API_URL=$(aws apigateway get-rest-apis \
  --query "items[?name=='bbws-access-$ENV-apigw'].id" \
  --output text)

BASE_URL="https://$API_URL.execute-api.$AWS_REGION.amazonaws.com/$ENV"

# Test health endpoints
curl -s "$BASE_URL/health" | jq .

# Expected response:
# {
#   "status": "healthy",
#   "environment": "dev",
#   "version": "v1.2.0",
#   "timestamp": "2026-01-25T12:00:00Z"
# }
```

### 5.3 Service Verification Matrix

| Service | Endpoint | Expected Status |
|---------|----------|-----------------|
| Permission | GET /permissions | 200 |
| Role | GET /roles | 200 |
| Team | GET /teams | 200 |
| Invitation | GET /invitations | 200 |
| Audit | GET /audit/health | 200 |

```bash
# Verify each service (with valid auth token)
TOKEN="your-jwt-token"

curl -s -H "Authorization: Bearer $TOKEN" "$BASE_URL/permissions" | jq '.data | length'
curl -s -H "Authorization: Bearer $TOKEN" "$BASE_URL/roles" | jq '.data | length'
```

### 5.4 CloudWatch Verification

```bash
# Check for errors in last 15 minutes
aws logs filter-log-events \
  --log-group-name "/aws/lambda/bbws-access-$ENV-lambda-permission-create" \
  --start-time $(date -d '15 minutes ago' +%s000) \
  --filter-pattern "ERROR" \
  --query 'events[*].message'

# Check Lambda invocations
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Invocations \
  --dimensions Name=FunctionName,Value=bbws-access-$ENV-lambda-permission-create \
  --start-time $(date -u -d '15 minutes ago' +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 \
  --statistics Sum
```

### 5.5 Alarm Status Check

```bash
# Check all alarms are OK
aws cloudwatch describe-alarms \
  --alarm-name-prefix "bbws-access-$ENV" \
  --state-value ALARM \
  --query 'MetricAlarms[*].[AlarmName,StateValue]' \
  --output table

# Expected: No alarms in ALARM state
```

---

## 6. Deployment Verification Sign-Off

### 6.1 DEV Sign-Off

| Check | Status | Verified By | Time |
|-------|--------|-------------|------|
| Infrastructure deployed | ☐ | | |
| Lambda functions deployed | ☐ | | |
| Smoke tests pass | ☐ | | |
| No errors in logs | ☐ | | |
| Alarms in OK state | ☐ | | |

### 6.2 SIT Sign-Off

| Check | Status | Verified By | Time |
|-------|--------|-------------|------|
| All DEV checks pass | ☐ | | |
| Integration tests pass | ☐ | | |
| UAT test cases executed | ☐ | | |
| Performance acceptable | ☐ | | |
| QA approval received | ☐ | | |

### 6.3 PROD Sign-Off

| Check | Status | Verified By | Time |
|-------|--------|-------------|------|
| All SIT checks pass | ☐ | | |
| Canary deployment healthy | ☐ | | |
| Full traffic shifted | ☐ | | |
| Smoke tests pass | ☐ | | |
| Stakeholders notified | ☐ | | |
| Change request closed | ☐ | | |

---

## 7. Troubleshooting

### 7.1 Terraform Apply Fails

**Symptom**: Terraform apply returns error

**Resolution**:
```bash
# Check state lock
aws dynamodb scan \
  --table-name bbws-access-$ENV-terraform-lock \
  --query 'Items[*]'

# Force unlock if stuck (use with caution!)
terraform force-unlock <lock-id>

# Refresh state
terraform refresh -var-file="environments/$ENV.tfvars"
```

### 7.2 Lambda Deployment Fails

**Symptom**: Lambda update-function-code returns error

**Resolution**:
```bash
# Check package size (must be < 50MB zipped, < 250MB unzipped)
ls -lh dist/*.zip

# Verify function exists
aws lambda get-function --function-name bbws-access-$ENV-lambda-permission-create

# Check IAM permissions
aws sts get-caller-identity
```

### 7.3 Smoke Tests Fail

**Symptom**: Smoke tests return failures

**Resolution**:
1. Check CloudWatch logs for errors
2. Verify API Gateway deployment is active
3. Check Lambda function aliases point to correct version
4. Verify DynamoDB table is accessible

---

## 8. Rollback Procedure

If deployment fails verification, initiate rollback:

```bash
# Lambda rollback
gh workflow run rollback-lambda.yml \
  -f environment=$ENV \
  -f target_version=previous \
  -f services=all \
  -f reason="Deployment verification failed"

# Or use manual script
./scripts/rollback-service.sh $ENV all previous
```

See **Rollback Runbook** for detailed procedures.

---

## 9. Communication Templates

### 9.1 Pre-Deployment Notification

```
:rocket: **Access Management Deployment Starting**

Environment: [DEV/SIT/PROD]
Version: v1.2.0
Deployer: @username
ETA: 15 minutes

Changes:
- [List key changes]

Monitoring: [Dashboard link]
```

### 9.2 Post-Deployment Notification

```
:white_check_mark: **Access Management Deployment Complete**

Environment: [DEV/SIT/PROD]
Version: v1.2.0
Duration: 12 minutes
Status: SUCCESS

Verification:
- Smoke tests: PASS
- Health checks: PASS
- Alarms: OK
```

### 9.3 Deployment Failure Notification

```
:x: **Access Management Deployment Failed**

Environment: [DEV/SIT/PROD]
Version: v1.2.0
Error: [Brief error description]

Action Required:
- Rollback initiated
- Investigation in progress

Incident: [Ticket link]
```

---

## 10. Contacts

| Role | Name | Contact | Availability |
|------|------|---------|--------------|
| DevOps Lead | TBD | @devops-lead | Business hours |
| On-Call Engineer | Rotation | PagerDuty | 24/7 |
| Platform Team | Team | #platform-support | Business hours |
| Security Team | Team | #security | Business hours |

### Escalation Path

1. On-call engineer (PagerDuty)
2. DevOps Lead
3. Platform Team Lead
4. Engineering Manager

---

## 11. Appendix

### A. Environment Variables Reference

| Variable | DEV | SIT | PROD |
|----------|-----|-----|------|
| AWS_REGION | eu-west-1 | eu-west-1 | af-south-1 |
| AWS_ACCOUNT_ID | 536580886816 | 815856636111 | 093646564004 |
| STATE_BUCKET | bbws-access-dev-terraform-state | bbws-access-sit-terraform-state | bbws-access-prod-terraform-state |
| API_THROTTLE_RATE | 100 | 500 | 1000 |

### B. Lambda Functions Reference

| Service | Function Count | Memory | Timeout |
|---------|---------------|--------|---------|
| Permission | 6 | 512MB | 30s |
| Invitation | 8 | 512MB | 30s |
| Team | 14 | 512MB | 30s |
| Role | 8 | 512MB | 30s |
| Authorizer | 1 | 512MB | 10s |
| Audit | 6 | 1024MB | 300s |

---

**Document Control**

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-25 | DevOps Team | Initial version |
