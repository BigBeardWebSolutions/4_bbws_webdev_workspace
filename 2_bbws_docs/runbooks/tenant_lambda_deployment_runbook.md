# Tenant Lambda Deployment Runbook

**Service**: Tenant and Instance Management Lambda API
**Repository**: https://github.com/BigBeardWebSolutions/2_bbws_tenants_instances_lambda
**Last Updated**: 2026-01-25
**Related LLDs**: [2.5 Tenant Management](../LLDs/2.5_LLD_Tenant_Management.md), [2.7 WordPress Instance Management](../LLDs/2.7_LLD_WordPress_Instance_Management.md)

---

## 1. Overview

This runbook covers deployment procedures for the **Tenant and Instance Management Lambda** service across all environments (DEV, SIT, PROD).

### 1.1 Service Description

The Tenant and Instance Management Lambda is a serverless API service that provides:

- **Tenant Management** (LLD 2.5): Organization CRUD, hierarchy management, user assignments, tenant lifecycle (park/unpark)
- **Instance Management** (LLD 2.7): WordPress instance provisioning, lifecycle management, scaling, backup/restore
- **Invitation Management**: User invitations to organizations and teams
- **User Management**: User-tenant assignments, role management

### 1.2 Lambda Functions

| Function | Endpoint | Description |
|----------|----------|-------------|
| api-router | All routes | Main API router (single Lambda with routing) |
| create-tenant | POST /tenants | Create new tenant |
| get-tenant | GET /tenants/{id} | Get tenant details |
| list-tenants | GET /tenants | List all tenants |
| update-tenant | PUT /tenants/{id} | Update tenant |
| delete-tenant | DELETE /tenants/{id} | Soft delete tenant |
| tenant-park | POST /tenants/{id}/park | Park tenant (suspend resources) |
| tenant-unpark | POST /tenants/{id}/unpark | Unpark tenant (resume resources) |
| create-instance | POST /tenants/{id}/instances | Create WordPress instance |
| get-instance | GET /instances/{id} | Get instance details |
| list-instances | GET /tenants/{id}/instances | List tenant instances |
| update-instance | PUT /instances/{id} | Update instance |
| delete-instance | DELETE /instances/{id} | Delete instance |
| scale-instance | PUT /instances/{id}/size | Scale instance resources |
| instance-suspend | POST /instances/{id}/suspend | Suspend instance |
| instance-resume | POST /instances/{id}/resume | Resume instance |
| instance-backup | POST /instances/{id}/backup | Create instance backup |
| instance-restore | POST /instances/{id}/restore | Restore from backup |
| invitation-create | POST /invitations | Create user invitation |
| invitation-list | GET /invitations | List invitations |
| invitation-get | GET /invitations/{id} | Get invitation details |
| invitation-cancel | DELETE /invitations/{id} | Cancel invitation |
| invitation-resend | POST /invitations/{id}/resend | Resend invitation email |
| user-assign | POST /tenants/{id}/users | Assign user to tenant |
| user-list | GET /tenants/{id}/users | List tenant users |
| user-remove | DELETE /tenants/{id}/users/{userId} | Remove user from tenant |
| hierarchy-manage | PUT /tenants/{id}/hierarchy | Manage organization hierarchy |

### 1.3 Architecture

```
CloudFront → API Gateway → Lambda (bbws-tenant-instance-management-{env})
                             │
                             ├── DynamoDB (bbws-tenants-{env})
                             ├── DynamoDB (bbws-instances-{env})
                             ├── DynamoDB (bbws-invitations-{env})
                             ├── EventBridge (tenant-events-{env})
                             ├── SNS (tenant-notifications-{env})
                             └── Cognito (bbws-user-pool-{env})
```

---

## 2. Prerequisites

### 2.1 Required Access

| Access Type | Description | How to Request |
|-------------|-------------|----------------|
| GitHub Repository | Push access to `2_bbws_tenants_instances_lambda` | Request via GitHub org admin |
| AWS Console (DEV) | Account 536580886816 | Request via IAM admin |
| AWS Console (SIT) | Account 815856636111 | Request via IAM admin |
| AWS Console (PROD) | Account 093646564004 (read-only for operations) | Request via IAM admin |
| GitHub Actions | Workflow trigger permissions | Repository admin grant |

### 2.2 Tools Required

| Tool | Version | Purpose |
|------|---------|---------|
| Git | >= 2.30 | Source control |
| Python | 3.12 | Lambda runtime |
| AWS CLI | >= 2.0 | AWS operations |
| Terraform | >= 1.5.0 | Infrastructure (manual only) |
| jq | >= 1.6 | JSON processing |

### 2.3 Infrastructure Requirements

The following infrastructure must exist before deployment:

| Resource | Naming Convention | Description |
|----------|-------------------|-------------|
| Lambda Function | `bbws-tenant-instance-management-{env}` | Main Lambda function |
| API Gateway | `bbws-tenant-api-{env}` | REST API endpoint |
| DynamoDB Tables | `bbws-tenants-{env}`, `bbws-instances-{env}`, `bbws-invitations-{env}` | Data storage |
| DynamoDB Table | `bbws-deployments-{env}` | Deployment metadata tracking |
| Cognito User Pool | `bbws-user-pool-{env}` | User authentication |
| IAM Role | `bbws-github-actions-role-{env}` | GitHub Actions OIDC role |
| S3 Bucket | `bbws-terraform-state-{env}` | Terraform state backend |
| CloudWatch Log Group | `/aws/lambda/bbws-tenant-instance-management-{env}` | Lambda logs |

---

## 3. Pre-deployment Checklist

Before deploying to any environment, verify:

### 3.1 Code Quality

- [ ] All unit tests pass locally: `pytest tests/unit/`
- [ ] All integration tests pass: `pytest tests/integration/`
- [ ] Code linting passes: `ruff check src/`
- [ ] Type checking passes: `mypy src/`
- [ ] Security scan passes: `bandit -r src/`
- [ ] Test coverage >= 80%: `pytest --cov=src --cov-fail-under=80`

### 3.2 Dependencies

- [ ] `requirements.txt` is up to date
- [ ] No known security vulnerabilities in dependencies
- [ ] Lambda layer dependencies are current

### 3.3 Configuration

- [ ] Environment variables are parameterized (no hardcoded values)
- [ ] API Gateway OpenAPI spec is valid
- [ ] DynamoDB table schemas match code expectations
- [ ] Cognito user pool configuration is correct

### 3.4 Documentation

- [ ] CHANGELOG.md is updated
- [ ] API documentation reflects changes
- [ ] Breaking changes are documented

---

## 4. DEV Deployment Steps

### 4.1 Automated Deployment (Recommended)

DEV deploys automatically on push to `main` branch via GitHub Actions workflow `deploy-dev.yml`.

**Step 1: Commit and Push Changes**
```bash
# Ensure you're on main branch
git checkout main
git pull origin main

# Stage and commit changes
git add .
git commit -m "feat: your descriptive commit message"

# Push to trigger deployment
git push origin main
```

**Step 2: Monitor GitHub Actions**
```bash
# Open GitHub Actions in browser
open https://github.com/BigBeardWebSolutions/2_bbws_tenants_instances_lambda/actions

# Or use gh CLI
gh run list --workflow=deploy-dev.yml
gh run watch
```

**Step 3: Wait for Completion**
- Quality Gates job: ~5-7 minutes (linting, unit tests, integration tests, security scan)
- Deploy job: ~3-5 minutes (package, upload, update Lambda)
- Verify job: ~2-3 minutes (health check, smoke tests, metrics check)

**Expected Output:**
```
Quality Gates      ✓ Passed
Deploy to DEV      ✓ Deployed version 42
Verify             ✓ Health check passed
Summary            ✓ Deployment successful
```

### 4.2 Manual Workflow Trigger

For emergency deployments or re-runs:

```bash
# Trigger via GitHub CLI
gh workflow run deploy-dev.yml

# With skip_tests option (emergency only)
gh workflow run deploy-dev.yml -f skip_tests=true
```

**Via GitHub UI:**
1. Navigate to Actions tab
2. Select "Deploy to DEV" workflow
3. Click "Run workflow"
4. Optionally check "Skip quality gates (emergency only)"
5. Click "Run workflow"

### 4.3 Deployment Verification

After deployment completes, verify in AWS Console:

```bash
# Check Lambda function exists and is updated
aws lambda get-function-configuration \
  --function-name bbws-tenant-instance-management-dev \
  --region eu-west-1 \
  --query '{Version:Version,LastModified:LastModified,CodeSha256:CodeSha256}'

# Check Lambda alias points to new version
aws lambda get-alias \
  --function-name bbws-tenant-instance-management-dev \
  --name latest-dev \
  --region eu-west-1
```

---

## 5. Smoke Test Verification

After DEV deployment, perform smoke tests to verify functionality.

### 5.1 Health Check

```bash
# Direct Lambda invocation
aws lambda invoke \
  --function-name bbws-tenant-instance-management-dev \
  --payload '{"httpMethod":"GET","path":"/health","headers":{}}' \
  --region eu-west-1 \
  response.json

cat response.json
# Expected: {"statusCode": 200, "body": "{\"status\":\"healthy\",\"version\":\"...\"}"}
```

### 5.2 API Gateway Tests

```bash
# Set API endpoint
API_URL="https://o158f3j653.execute-api.eu-west-1.amazonaws.com"

# Health check
curl -s "$API_URL/health" | jq .

# List tenants (requires auth token)
TOKEN="<your-cognito-jwt-token>"
curl -s -H "Authorization: Bearer $TOKEN" "$API_URL/tenants" | jq .
```

### 5.3 Key Endpoint Tests

| Endpoint | Method | Test Command | Expected Result |
|----------|--------|--------------|-----------------|
| /health | GET | `curl -s $API_URL/health` | 200 OK with status: healthy |
| /tenants | GET | `curl -s -H "Authorization: Bearer $TOKEN" $API_URL/tenants` | 200 OK with tenant list |
| /tenants/{id} | GET | `curl -s -H "Authorization: Bearer $TOKEN" $API_URL/tenants/123` | 200 OK or 404 Not Found |
| /invitations | POST | See test script | 201 Created with invitation ID |
| /instances/{id}/size | PUT | See test script | 200 OK with updated instance |

### 5.4 Smoke Test Script

```bash
#!/bin/bash
# smoke-test-dev.sh

API_URL="https://o158f3j653.execute-api.eu-west-1.amazonaws.com"
TOKEN="${COGNITO_TOKEN:-}"

echo "=== Tenant Lambda Smoke Tests (DEV) ==="

# Test 1: Health check
echo -n "Health check... "
HEALTH=$(curl -s -w "%{http_code}" -o /tmp/health.json "$API_URL/health")
if [ "$HEALTH" == "200" ]; then
    echo "PASS"
else
    echo "FAIL (HTTP $HEALTH)"
fi

# Test 2: List tenants (if token provided)
if [ -n "$TOKEN" ]; then
    echo -n "List tenants... "
    TENANTS=$(curl -s -w "%{http_code}" -o /tmp/tenants.json \
        -H "Authorization: Bearer $TOKEN" "$API_URL/tenants")
    if [ "$TENANTS" == "200" ]; then
        echo "PASS"
    else
        echo "FAIL (HTTP $TENANTS)"
    fi
fi

echo "=== Smoke Tests Complete ==="
```

---

## 6. SIT Promotion Steps

SIT promotion is a manual process that copies the DEV Lambda package to SIT.

### 6.1 Pre-Promotion Checklist

- [ ] DEV deployment is successful and verified
- [ ] Smoke tests pass in DEV
- [ ] No high-severity errors in DEV CloudWatch logs (last 1 hour)
- [ ] Stakeholder approval obtained (if required)

### 6.2 Trigger SIT Promotion

**Via GitHub CLI:**
```bash
# Promote latest DEV version to SIT
gh workflow run promote-to-sit.yml

# Or specify a specific DEV version
gh workflow run promote-to-sit.yml -f dev_version=42
```

**Via GitHub UI:**
1. Navigate to Actions tab
2. Select "Promote to SIT" workflow
3. Click "Run workflow"
4. Optionally specify DEV Lambda version (leave empty for latest)
5. Click "Run workflow"
6. Wait for Environment approval gate (if configured)

### 6.3 Promotion Process

The `promote-to-sit.yml` workflow performs:

1. **Pre-flight Checks**
   - Verify DEV environment health (error rate < 10 in last hour)
   - Get DEV Lambda version and code SHA
   - Download Lambda package from DEV

2. **Deploy to SIT**
   - Create backup alias for rollback
   - Upload Lambda package to SIT
   - Verify code SHA matches DEV (integrity check)
   - Update `latest-sit` alias

3. **Post-Deployment Verification**
   - Lambda health check
   - Smoke tests
   - Monitor for immediate errors (30 seconds)

4. **Record Metadata**
   - Record deployment in `bbws-deployments-sit` DynamoDB table

### 6.4 SIT Verification

```bash
# Check SIT Lambda version
aws lambda get-alias \
  --function-name bbws-tenant-instance-management-sit \
  --name latest-sit \
  --region eu-west-1 \
  --profile sit

# Health check
aws lambda invoke \
  --function-name bbws-tenant-instance-management-sit \
  --payload '{"httpMethod":"GET","path":"/health","headers":{}}' \
  --region eu-west-1 \
  --profile sit \
  response.json

cat response.json
```

---

## 7. PROD Promotion Steps

PROD promotion requires explicit maintenance window confirmation and environment approval.

### 7.1 Pre-Promotion Checklist

- [ ] SIT deployment has been running for at least 24 hours
- [ ] SIT has near-zero errors (< 5 in last 24 hours)
- [ ] No throttles in SIT (last 24 hours)
- [ ] Change request approved (if required)
- [ ] Maintenance window approved
- [ ] Rollback plan reviewed
- [ ] On-call engineer notified

### 7.2 Trigger PROD Promotion

**Via GitHub CLI:**
```bash
# Promote latest SIT version to PROD
gh workflow run promote-to-prod.yml -f maintenance_window=true

# Or specify a specific SIT version
gh workflow run promote-to-prod.yml -f sit_version=35 -f maintenance_window=true
```

**Via GitHub UI:**
1. Navigate to Actions tab
2. Select "Promote to PROD" workflow
3. Click "Run workflow"
4. Check "Confirm deployment during approved maintenance window" (REQUIRED)
5. Optionally specify SIT Lambda version
6. Click "Run workflow"
7. Wait for Environment approval gate (requires 2+ approvers)

### 7.3 PROD Promotion Process

The `promote-to-prod.yml` workflow performs:

1. **Pre-flight Checks (Stricter)**
   - Verify maintenance window confirmation
   - Verify SIT stability (24-hour lookback)
   - Error rate < 5 in last 24 hours
   - No throttles in last 24 hours
   - Download Lambda package from SIT

2. **Quality Gates**
   - Re-run all tests against PROD config
   - Security scan
   - Cost estimation

3. **Deploy to PROD**
   - Create backup alias for rollback
   - Upload Lambda package to PROD
   - Verify code SHA matches SIT (integrity check)
   - Update `latest-prod` alias

4. **Post-Deployment Verification (Enhanced)**
   - Lambda health check
   - Read-only smoke tests
   - 5-minute error monitoring window
   - CloudFront distribution verification

5. **Record Metadata**
   - Record deployment in `bbws-deployments-prod` DynamoDB table

### 7.4 PROD Verification

```bash
# Check PROD Lambda version
aws lambda get-alias \
  --function-name bbws-tenant-instance-management-prod \
  --name latest-prod \
  --region af-south-1 \
  --profile prod

# Health check via CloudFront (production URL)
curl -s https://api.wp.kimmyai.io/health | jq .

# Direct Lambda health check
aws lambda invoke \
  --function-name bbws-tenant-instance-management-prod \
  --payload '{"httpMethod":"GET","path":"/health","headers":{}}' \
  --region af-south-1 \
  --profile prod \
  response.json

cat response.json
```

---

## 8. Post-deployment Verification

### 8.1 CloudWatch Metrics Check

```bash
# Check Lambda errors (last 5 minutes)
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Errors \
  --dimensions Name=FunctionName,Value=bbws-tenant-instance-management-{env} \
  --start-time $(date -u -d '5 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum \
  --region {region}

# Check invocation count
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Invocations \
  --dimensions Name=FunctionName,Value=bbws-tenant-instance-management-{env} \
  --start-time $(date -u -d '5 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum \
  --region {region}

# Check duration (latency)
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Duration \
  --dimensions Name=FunctionName,Value=bbws-tenant-instance-management-{env} \
  --start-time $(date -u -d '5 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average,Maximum \
  --region {region}
```

### 8.2 CloudWatch Logs Check

```bash
# Tail recent logs
aws logs tail /aws/lambda/bbws-tenant-instance-management-{env} \
  --follow \
  --region {region}

# Search for errors
aws logs filter-log-events \
  --log-group-name /aws/lambda/bbws-tenant-instance-management-{env} \
  --start-time $(date -u -d '10 minutes ago' +%s)000 \
  --filter-pattern "ERROR" \
  --region {region}
```

### 8.3 CloudWatch Alarms Check

```bash
# List alarms for the function
aws cloudwatch describe-alarms \
  --alarm-name-prefix bbws-tenant-instance-management-{env} \
  --region {region}

# Check alarm state
aws cloudwatch describe-alarm-history \
  --alarm-name bbws-tenant-instance-management-{env}-errors \
  --history-item-type StateUpdate \
  --region {region}
```

### 8.4 DynamoDB Health Check

```bash
# Check table status
aws dynamodb describe-table \
  --table-name bbws-tenants-{env} \
  --region {region} \
  --query 'Table.{Status:TableStatus,ItemCount:ItemCount}'

# Check recent writes
aws dynamodb query \
  --table-name bbws-tenants-{env} \
  --key-condition-expression "PK = :pk" \
  --expression-attribute-values '{":pk":{"S":"TENANT#"}}' \
  --limit 1 \
  --scan-index-forward false \
  --region {region}
```

---

## 9. Rollback Triggers

### 9.1 Automatic Rollback Triggers

The deployment workflow automatically triggers rollback when:

- Health check fails after deployment
- Error rate exceeds threshold in monitoring window (5 minutes for PROD)
- Lambda function update fails

### 9.2 Manual Rollback Triggers

Initiate manual rollback when:

| Condition | Severity | Action |
|-----------|----------|--------|
| Error rate > 10% | Critical | Immediate rollback |
| P99 latency > 10s | High | Rollback within 5 minutes |
| 5xx errors > 5/minute | High | Rollback within 5 minutes |
| Functional regression reported | High | Rollback after verification |
| Security vulnerability discovered | Critical | Immediate rollback |
| Data corruption detected | Critical | Immediate rollback + incident |

### 9.3 Rollback Procedure

**Via GitHub Actions (Recommended):**
```bash
# Rollback DEV
gh workflow run rollback.yml -f environment=dev -f reason="High error rate"

# Rollback SIT
gh workflow run rollback.yml -f environment=sit -f reason="Functional regression"

# Rollback PROD (requires approval)
gh workflow run rollback.yml -f environment=prod -f reason="Critical error in production"

# Rollback to specific version
gh workflow run rollback.yml -f environment=dev -f target_version=40 -f reason="Rollback to known good version"
```

**Via GitHub UI:**
1. Navigate to Actions tab
2. Select "Rollback Lambda Deployment" workflow
3. Click "Run workflow"
4. Select environment (dev/sit/prod)
5. Optionally specify target version
6. Enter reason for rollback (REQUIRED)
7. Click "Run workflow"

### 9.4 Manual AWS Console Rollback

If GitHub Actions is unavailable:

```bash
# 1. Find backup alias
aws lambda list-aliases \
  --function-name bbws-tenant-instance-management-{env} \
  --region {region} \
  --query 'Aliases[?starts_with(Name, `backup-`)].{Name:Name,Version:FunctionVersion}'

# 2. Update latest alias to backup version
aws lambda update-alias \
  --function-name bbws-tenant-instance-management-{env} \
  --name latest-{env} \
  --function-version {backup-version} \
  --region {region}

# 3. Verify rollback
aws lambda get-alias \
  --function-name bbws-tenant-instance-management-{env} \
  --name latest-{env} \
  --region {region}
```

---

## 10. Environment-Specific Details

| Environment | AWS Account | Region | Lambda Function | API Gateway | Auto-Deploy | Approval |
|-------------|-------------|--------|-----------------|-------------|-------------|----------|
| DEV | 536580886816 | eu-west-1 | bbws-tenant-instance-management-dev | o158f3j653 | Yes (on push) | No |
| SIT | 815856636111 | eu-west-1 | bbws-tenant-instance-management-sit | TBD | No (manual) | Yes |
| PROD | 093646564004 | af-south-1 | bbws-tenant-instance-management-prod | TBD | No (manual) | Yes (2+) |

### 10.1 Environment URLs

| Environment | API Gateway URL | CloudFront URL |
|-------------|-----------------|----------------|
| DEV | https://o158f3j653.execute-api.eu-west-1.amazonaws.com | N/A |
| SIT | https://api-sit.bbws.example.com | N/A |
| PROD | https://api.wp.kimmyai.io | https://api.wp.kimmyai.io |

### 10.2 IAM Roles

| Environment | GitHub Actions Role |
|-------------|---------------------|
| DEV | arn:aws:iam::536580886816:role/bbws-github-actions-role-dev |
| SIT | arn:aws:iam::815856636111:role/bbws-github-actions-role-sit |
| PROD | arn:aws:iam::093646564004:role/bbws-github-actions-role-prod |

---

## 11. Troubleshooting

### 11.1 Issue: Deployment Workflow Fails

**Symptom**: GitHub Actions workflow fails at quality gates or deploy step

**Solution**:
1. Check workflow logs in GitHub Actions
2. Common issues:
   - Test failures: Review test output, fix failing tests
   - Lint errors: Run `ruff check --fix src/`
   - Security scan: Review bandit output, fix vulnerabilities
   - AWS credentials: Verify OIDC role configuration

### 11.2 Issue: Lambda Update Fails

**Symptom**: `ResourceNotFoundException: Function not found`

**Solution**:
```bash
# Verify Lambda function exists
aws lambda get-function \
  --function-name bbws-tenant-instance-management-{env} \
  --region {region}

# If not exists, check Terraform state
cd terraform
terraform state list | grep lambda
```

### 11.3 Issue: Health Check Fails

**Symptom**: Post-deployment health check returns non-200 status

**Solution**:
1. Check Lambda logs for errors:
```bash
aws logs tail /aws/lambda/bbws-tenant-instance-management-{env} --follow --region {region}
```
2. Verify environment variables are set
3. Verify DynamoDB tables exist and are accessible
4. Verify Cognito user pool is configured

### 11.4 Issue: API Gateway 502 Bad Gateway

**Symptom**: API returns 502 error

**Solution**:
1. Check Lambda execution role has required permissions
2. Verify DynamoDB table exists:
```bash
aws dynamodb describe-table --table-name bbws-tenants-{env} --region {region}
```
3. Check Lambda timeout vs expected operation duration
4. Review Lambda CloudWatch logs

### 11.5 Issue: Terraform State Lock

**Symptom**: `Error acquiring the state lock`

**Solution**:
```bash
# Check lock status
aws dynamodb get-item \
  --table-name terraform-state-lock-{env} \
  --key '{"LockID": {"S": "bbws-terraform-state-{env}/tenant-lambda/{env}/terraform.tfstate"}}' \
  --region eu-west-1

# Force unlock (use with caution)
terraform force-unlock <LOCK_ID>
```

---

## 12. Related Resources

### 12.1 Documentation

| Document | Location |
|----------|----------|
| LLD 2.5 Tenant Management | [2.5_LLD_Tenant_Management.md](../LLDs/2.5_LLD_Tenant_Management.md) |
| LLD 2.7 WordPress Instance Management | [2.7_LLD_WordPress_Instance_Management.md](../LLDs/2.7_LLD_WordPress_Instance_Management.md) |
| HLD 2.5 Tenant Management | [2.5_HLD_Tenant_Management.md](../HLDs/2.5_HLD_Tenant_Management.md) |
| HLD 2.7 WordPress Instance Management | [2.7_HLD_WordPress_Instance_Management.md](../HLDs/2.7_HLD_WordPress_Instance_Management.md) |
| BRS 2.5 Tenant Management | [2.5_BRS_Tenant_Management.md](../BRS/2.5_BRS_Tenant_Management.md) |
| BRS 2.7 WordPress Instance Management | [2.7_BRS_WordPress_Instance_Management.md](../BRS/2.7_BRS_WordPress_Instance_Management.md) |

### 12.2 Related Runbooks

| Runbook | Purpose |
|---------|---------|
| [RB-001 Tenant Provisioning](./RB-001_Tenant_Provisioning.md) | Tenant provisioning operations |
| [RB-002 Site Generation Troubleshooting](./RB-002_Site_Generation_Troubleshooting.md) | Site generation issues |
| [Product Lambda Deployment](./product_lambda_deployment.md) | Reference deployment runbook |
| [Product Lambda Operations](./product_lambda_operations.md) | Operational procedures |
| [Product Lambda Disaster Recovery](./product_lambda_disaster_recovery.md) | DR procedures |

### 12.3 Repositories

| Repository | Purpose |
|------------|---------|
| 2_bbws_tenants_instances_lambda | Main Lambda function code |
| 2_bbws_tenants_instances_dev | Tenant Terraform configs (DEV) |
| 2_bbws_tenants_instances_sit | Tenant Terraform configs (SIT) |
| 2_bbws_tenants_instances_prod | Tenant Terraform configs (PROD) |
| 2_bbws_tenants_event_handler | ECS event handler Lambda |
| 2_bbws_ecs_terraform | Platform infrastructure |

### 12.4 Dashboards and Monitoring

| Resource | URL |
|----------|-----|
| CloudWatch Dashboard (DEV) | AWS Console > CloudWatch > Dashboards > bbws-tenant-lambda-dev |
| CloudWatch Dashboard (SIT) | AWS Console > CloudWatch > Dashboards > bbws-tenant-lambda-sit |
| CloudWatch Dashboard (PROD) | AWS Console > CloudWatch > Dashboards > bbws-tenant-lambda-prod |
| GitHub Actions | https://github.com/BigBeardWebSolutions/2_bbws_tenants_instances_lambda/actions |

---

## 13. Support Contacts

| Role | Contact | Escalation |
|------|---------|------------|
| Platform Team | platform@bigbeard.io | Primary |
| DevOps Engineer | devops@bigbeard.io | Secondary |
| AWS Support | AWS Support Portal | Critical issues |

---

## 14. Appendix: Quick Reference

### 14.1 Common Commands

```bash
# DEV deployment (push to main)
git push origin main

# Promote to SIT
gh workflow run promote-to-sit.yml

# Promote to PROD
gh workflow run promote-to-prod.yml -f maintenance_window=true

# Rollback
gh workflow run rollback.yml -f environment={env} -f reason="reason"

# Check Lambda version
aws lambda get-alias --function-name bbws-tenant-instance-management-{env} --name latest-{env} --region {region}

# Tail logs
aws logs tail /aws/lambda/bbws-tenant-instance-management-{env} --follow --region {region}
```

### 14.2 Environment Variables

Replace placeholders in commands:

| Placeholder | DEV | SIT | PROD |
|-------------|-----|-----|------|
| `{env}` | dev | sit | prod |
| `{region}` | eu-west-1 | eu-west-1 | af-south-1 |
| `{account}` | 536580886816 | 815856636111 | 093646564004 |

---

**Version**: 1.0
**Status**: Active
**Last Reviewed**: 2026-01-25
