# Site Management Lambda Deployment Runbook

**Service**: WordPress Site Management Lambda API
**Repository**: https://github.com/BigBeardWebSolutions/2_bbws_wordpress_site_management_lambda
**LLD Reference**: 2.6_LLD_WordPress_Site_Management.md
**Last Updated**: 2026-01-25
**Version**: 1.0

---

## 1. Overview

The WordPress Site Management Lambda service provides self-service capabilities for BBWS customers to create, configure, and manage their WordPress websites. This service comprises four distinct microservices operating as Lambda functions with a shared infrastructure.

### Service Components

| Service | Purpose | Lambda Functions |
|---------|---------|------------------|
| **sites-service** | Site CRUD operations, lifecycle management | `{env}-bbws-sites-service` |
| **templates-service** | Template marketplace and application | `{env}-bbws-templates-service` |
| **plugins-service** | Plugin management (security-vetted) | `{env}-bbws-plugins-service` |
| **async-processor** | SQS consumers for long-running operations | `{env}-bbws-async-processor` |

### API Endpoints

| Service | API Prefix | Key Operations |
|---------|------------|----------------|
| Sites | `/v1.0/tenants/{tenantId}/sites` | Create, List, Clone, Promote |
| Templates | `/v1.0/templates` | List, Get, Apply, Preview |
| Plugins | `/v1.0/tenants/{tenantId}/plugins` | Install, Uninstall, Configure |
| Operations | `/v1.0/operations` | Status tracking for async operations |

---

## 2. Prerequisites

### Required Access

| Access Type | Requirement |
|-------------|-------------|
| GitHub | Repository access to `2_bbws_wordpress_site_management_lambda` |
| AWS Console | Console access for target environment (DEV/SIT/PROD) |
| AWS CLI | Configured with appropriate credentials |
| Terraform CLI | Version >= 1.5.0 |
| Python | Version 3.12 |

### Infrastructure Requirements

Before deployment, verify the following infrastructure exists:

| Resource | DEV | SIT | PROD |
|----------|-----|-----|------|
| DynamoDB Table | `sites` | `sites` | `sites` |
| S3 Terraform State Bucket | `bbws-terraform-state-dev` | `bbws-terraform-state-sit` | `bbws-terraform-state-prod` |
| DynamoDB Lock Table | `terraform-state-lock-dev` | `terraform-state-lock-sit` | `terraform-state-lock-prod` |
| GitHub OIDC Role | `bbws-github-actions-role-dev` | `bbws-github-actions-role-sit` | `bbws-github-actions-role-prod` |
| SQS Queues | `bbws-wp-site-creation-dev` | `bbws-wp-site-creation-sit` | `bbws-wp-site-creation-prod` |
| SNS Topics | `bbws-wp-notifications-dev` | `bbws-wp-notifications-sit` | `bbws-wp-notifications-prod` |
| Internal ALB | `bbws-wp-internal-alb-dev` | `bbws-wp-internal-alb-sit` | `bbws-wp-internal-alb-prod` |
| VPC Endpoints | DynamoDB, Secrets Manager | DynamoDB, Secrets Manager | DynamoDB, Secrets Manager |

### Verify Prerequisites

```bash
# Check Terraform version
terraform version

# Check Python version
python3 --version

# Check AWS CLI access (replace with target account)
aws sts get-caller-identity

# Verify DynamoDB table exists
aws dynamodb describe-table --table-name sites --region af-south-1
```

---

## 3. Pre-deployment Checklist

### Code Quality Gates

| Check | Command | Required |
|-------|---------|----------|
| Unit Tests Pass | `pytest tests/ -v --cov=src --cov-fail-under=80` | Yes |
| Code Formatting | `black src/ tests/ --check` | Yes |
| Type Checking | `mypy src/` | Yes |
| Linting | `ruff check src/ tests/` | Yes |
| Dependencies Updated | `pip install -r requirements.txt` | Yes |

### Run Pre-deployment Checks

```bash
# Navigate to repository
cd /path/to/2_bbws_wordpress_site_management_lambda

# Run tests for each service
for service in sites-service templates-service plugins-service async-processor; do
  echo "=== Testing $service ==="
  cd $service
  pip install -r requirements.txt -r requirements-dev.txt
  pytest tests/ -v --cov=src --cov-report=term --cov-fail-under=80
  cd ..
done
```

### Verify Artifacts Build

```bash
# Build all Lambda packages
chmod +x ./scripts/build_all.sh
./scripts/build_all.sh

# Verify ZIP files created
ls -lh sites-service/dist/*.zip
ls -lh templates-service/dist/*.zip
ls -lh plugins-service/dist/*.zip
ls -lh async-processor/dist/*.zip
```

---

## 4. DEV Deployment Steps

### Method 1: Automated Deployment (Recommended)

DEV deployment is triggered automatically on push to main branch.

```bash
# 1. Commit and push changes to main branch
git add .
git commit -m "feat: your feature description"
git push origin main

# 2. Monitor GitHub Actions workflow
# Navigate to: https://github.com/BigBeardWebSolutions/2_bbws_wordpress_site_management_lambda/actions
# Select: "Deploy to DEV" workflow

# 3. Wait for workflow completion (~10-15 minutes)
```

### Workflow Stages

The `deploy-dev.yml` workflow executes:

1. **Test Stage**: Runs pytest for each service (templates-service, plugins-service, async-processor)
2. **Build Stage**: Creates Lambda ZIP packages
3. **Deploy Stage**: Terraform init, plan, apply
4. **Verify Stage**: Confirms Lambda functions are deployed and active
5. **Summary Stage**: Generates deployment summary

### Method 2: Manual Terraform Deployment (DEV Only)

```bash
# Navigate to terraform directory
cd /path/to/2_bbws_wordpress_site_management_lambda/terraform

# Initialize Terraform with DEV backend
terraform init \
  -backend-config="bucket=bbws-terraform-state-dev" \
  -backend-config="key=site-management-lambda/dev/terraform.tfstate" \
  -backend-config="region=af-south-1" \
  -backend-config="dynamodb_table=terraform-state-lock-dev" \
  -backend-config="encrypt=true"

# Review changes
terraform plan -var="environment=dev" -var-file=environments/dev/terraform.tfvars -out=tfplan

# Apply deployment
terraform apply tfplan

# Get API Gateway URL
terraform output api_gateway_url
```

---

## 5. Smoke Test Verification

### Post-DEV Deployment Verification

```bash
# Set environment variables
export AWS_REGION="af-south-1"
export ENV="dev"

# 1. Verify all Lambda functions exist and are active
echo "=== Verifying Lambda Functions ==="
for func in sites-service templates-service plugins-service async-processor; do
  aws lambda get-function --function-name ${ENV}-bbws-${func} --region $AWS_REGION
  echo "Lambda ${ENV}-bbws-${func}: OK"
done

# 2. Verify SQS queues
echo "=== Verifying SQS Queues ==="
aws sqs get-queue-url --queue-name bbws-wp-site-creation-${ENV} --region $AWS_REGION
aws sqs get-queue-url --queue-name bbws-wp-site-update-${ENV} --region $AWS_REGION
aws sqs get-queue-url --queue-name bbws-wp-site-deletion-${ENV} --region $AWS_REGION
echo "SQS Queues: OK"

# 3. Verify DynamoDB table
echo "=== Verifying DynamoDB Table ==="
aws dynamodb describe-table --table-name sites --region $AWS_REGION
echo "DynamoDB Table: OK"
```

### API Endpoint Smoke Tests

```bash
# Get API Gateway URL (from Terraform output or AWS Console)
export API_URL="https://xxxxx.execute-api.af-south-1.amazonaws.com/dev"

# Get valid JWT token from Cognito (replace with your auth mechanism)
export AUTH_TOKEN="Bearer eyJ..."

# Test Sites API
echo "=== Testing Sites API ==="

# List sites (GET /sites)
curl -s -X GET "${API_URL}/v1.0/tenants/tenant-123/sites" \
  -H "Authorization: ${AUTH_TOKEN}" \
  -H "Content-Type: application/json" | jq .

# Test Templates API
echo "=== Testing Templates API ==="

# List templates (GET /templates)
curl -s -X GET "${API_URL}/v1.0/templates" \
  -H "Authorization: ${AUTH_TOKEN}" \
  -H "Content-Type: application/json" | jq .

# Test Plugins API
echo "=== Testing Plugins API ==="

# List marketplace plugins (GET /plugins)
curl -s -X GET "${API_URL}/v1.0/plugins" \
  -H "Authorization: ${AUTH_TOKEN}" \
  -H "Content-Type: application/json" | jq .
```

### Key Endpoints to Verify

| Endpoint | Method | Expected Response |
|----------|--------|-------------------|
| `/v1.0/tenants/{tenantId}/sites` | GET | 200 OK with sites array |
| `/v1.0/tenants/{tenantId}/sites` | POST | 202 Accepted with siteId |
| `/v1.0/tenants/{tenantId}/sites/{siteId}/clone` | POST | 202 Accepted with operationId |
| `/v1.0/tenants/{tenantId}/sites/{siteId}/promote` | POST | 200 OK with promoted site |
| `/v1.0/templates` | GET | 200 OK with templates array |
| `/v1.0/tenants/{tenantId}/sites/{siteId}/plugins` | POST | 201 Created |

### CloudWatch Log Verification

```bash
# Check recent Lambda invocations
aws logs tail /aws/lambda/${ENV}-bbws-sites-service --since 10m --region $AWS_REGION

# Check for errors
aws logs filter-log-events \
  --log-group-name /aws/lambda/${ENV}-bbws-sites-service \
  --filter-pattern "ERROR" \
  --start-time $(date -d '1 hour ago' +%s)000 \
  --region $AWS_REGION
```

---

## 6. SIT Promotion Steps

### Prerequisites for SIT Promotion

1. DEV deployment successful and stable
2. All smoke tests passing in DEV
3. No critical errors in CloudWatch logs (last 24 hours)
4. Artifact version identified for promotion

### Promotion via GitHub Actions

```bash
# 1. Navigate to GitHub Actions
# URL: https://github.com/BigBeardWebSolutions/2_bbws_wordpress_site_management_lambda/actions

# 2. Select "Deploy to SIT" workflow

# 3. Click "Run workflow"

# 4. Enter required inputs:
#    - artifact_version: e.g., "v1.0.5"
#    - approve_deployment: true

# 5. Click "Run workflow" button

# 6. Wait for DEV health check to pass

# 7. Wait for tests to pass

# 8. Approve deployment in GitHub Actions UI (requires reviewer approval)
```

### SIT Workflow Stages

The `deploy-sit.yml` workflow executes:

1. **Check DEV Health**: Verifies all DEV Lambda functions are Active
2. **Test Stage**: Re-runs all service tests
3. **Deploy Stage** (requires approval):
   - Downloads artifacts from DEV release
   - Verifies MD5 checksums match DEV
   - Deploys via Terraform to SIT
4. **Smoke Tests**: Verifies Lambda functions in SIT

### Manual SIT Deployment (Fallback)

```bash
# Configure AWS credentials for SIT
export AWS_PROFILE=bbws-sit
export AWS_REGION=af-south-1

# Navigate to terraform directory
cd /path/to/2_bbws_wordpress_site_management_lambda/terraform

# Initialize with SIT backend
terraform init \
  -backend-config="bucket=bbws-terraform-state-sit" \
  -backend-config="key=site-management-lambda/sit/terraform.tfstate" \
  -backend-config="region=af-south-1" \
  -backend-config="dynamodb_table=terraform-state-lock-sit" \
  -backend-config="encrypt=true" \
  -reconfigure

# Plan and apply
terraform plan -var="environment=sit" -var-file=environments/sit/terraform.tfvars -out=tfplan
terraform apply tfplan
```

### SIT Verification

```bash
export ENV="sit"
export AWS_REGION="af-south-1"

# Verify Lambda functions
for func in sites-service templates-service plugins-service async-processor; do
  aws lambda get-function --function-name ${ENV}-bbws-${func} --region $AWS_REGION
  echo "SIT Lambda ${ENV}-bbws-${func}: Active"
done
```

---

## 7. PROD Promotion Steps

### Prerequisites for PROD Promotion

| Requirement | Verification |
|-------------|--------------|
| SIT deployment stable | Running for minimum 24 hours |
| SIT error rate | < 10 errors in last 24 hours |
| All smoke tests pass | API endpoints responding correctly |
| Business approval | Change request approved |
| Rollback plan ready | Previous version documented |

### PROD Deployment Environment

| Setting | Value |
|---------|-------|
| AWS Account | 093646564004 |
| Region | **af-south-1** (Cape Town - Primary) |
| DR Region | eu-west-1 (Ireland - Failover) |
| Access | Read-only via Claude Code |

### Promotion via GitHub Actions

```bash
# 1. Navigate to GitHub Actions
# URL: https://github.com/BigBeardWebSolutions/2_bbws_wordpress_site_management_lambda/actions

# 2. Select "Deploy to PROD" workflow

# 3. Click "Run workflow"

# 4. Enter required inputs:
#    - artifact_version: e.g., "v1.0.5" (MUST match SIT version)
#    - approve_deployment: true

# 5. Click "Run workflow" button

# 6. Workflow performs:
#    - SIT health check (all Lambdas active)
#    - SIT error rate check (< 10 errors in 24h)
#    - All service tests

# 7. Wait for approval gate:
#    - Required reviewers: Business Owner + Tech Lead (minimum 2)
#    - Wait timer: 10 minutes (allows time to cancel if needed)

# 8. Approve deployment in GitHub Actions UI
```

### PROD Workflow Stages

The `deploy-prod.yml` workflow executes:

1. **Check SIT Health**:
   - Verifies all SIT Lambda functions are Active
   - Checks SIT error rate (< 10 in 24 hours)
2. **Test Stage**: Re-runs all service tests
3. **Deploy Stage** (requires 2+ approvers):
   - Downloads SAME artifacts from SIT release
   - Verifies MD5 checksums match
   - Deploys via Terraform to PROD (af-south-1)
4. **Smoke Tests**: Verifies Lambda functions in PROD

### PROD Verification

```bash
export ENV="prod"
export AWS_REGION="af-south-1"

# Verify Lambda functions
for func in sites-service templates-service plugins-service async-processor; do
  aws lambda get-function --function-name ${ENV}-bbws-${func} --region $AWS_REGION
  echo "PROD Lambda ${ENV}-bbws-${func}: Active"
done

# Check CloudWatch for errors (first 30 minutes post-deploy)
aws logs filter-log-events \
  --log-group-name /aws/lambda/${ENV}-bbws-sites-service \
  --filter-pattern "ERROR" \
  --start-time $(date -d '30 minutes ago' +%s)000 \
  --region $AWS_REGION
```

---

## 8. Post-deployment Verification

### Health Check Commands

```bash
# Set environment (dev/sit/prod)
export ENV="dev"
export AWS_REGION="af-south-1"

# 1. Lambda Function Health
echo "=== Lambda Function Health ==="
for func in sites-service templates-service plugins-service async-processor; do
  STATE=$(aws lambda get-function \
    --function-name ${ENV}-bbws-${func} \
    --region $AWS_REGION \
    --query 'Configuration.State' \
    --output text)
  echo "${ENV}-bbws-${func}: $STATE"
done

# 2. SQS Queue Health
echo "=== SQS Queue Health ==="
for queue in creation update deletion; do
  APPROX_MESSAGES=$(aws sqs get-queue-attributes \
    --queue-url $(aws sqs get-queue-url --queue-name bbws-wp-site-${queue}-${ENV} --region $AWS_REGION --query 'QueueUrl' --output text) \
    --attribute-names ApproximateNumberOfMessages \
    --region $AWS_REGION \
    --query 'Attributes.ApproximateNumberOfMessages' \
    --output text)
  echo "bbws-wp-site-${queue}-${ENV}: ${APPROX_MESSAGES} messages"
done

# 3. DLQ Health
echo "=== DLQ Health ==="
DLQ_MESSAGES=$(aws sqs get-queue-attributes \
  --queue-url $(aws sqs get-queue-url --queue-name bbws-wp-site-operations-dlq-${ENV} --region $AWS_REGION --query 'QueueUrl' --output text) \
  --attribute-names ApproximateNumberOfMessages \
  --region $AWS_REGION \
  --query 'Attributes.ApproximateNumberOfMessages' \
  --output text)
echo "DLQ Messages: ${DLQ_MESSAGES}"
if [ "$DLQ_MESSAGES" -gt "0" ]; then
  echo "WARNING: DLQ has messages - investigate immediately"
fi

# 4. CloudWatch Alarms
echo "=== CloudWatch Alarms ==="
aws cloudwatch describe-alarms \
  --alarm-name-prefix "bbws-wp-" \
  --state-value ALARM \
  --region $AWS_REGION \
  --query 'MetricAlarms[*].[AlarmName,StateValue]' \
  --output table
```

### CloudWatch Metrics to Monitor

| Metric | Namespace | Threshold |
|--------|-----------|-----------|
| SiteCreated | BBWS/WPTechnical | Monitor count |
| SiteCreationFailed | BBWS/WPTechnical | < 5 per 15 min |
| SiteCreationDuration | BBWS/WPTechnical | < 600s (p95) |
| WordPressAPILatency | BBWS/WPTechnical | < 5000ms (p95) |
| DLQMessages | BBWS/WPTechnical | = 0 |
| LambdaErrors | AWS/Lambda | < 10 per 5 min |
| LambdaThrottles | AWS/Lambda | < 5 per 5 min |

### Dashboard URL

```
# DEV Dashboard
https://af-south-1.console.aws.amazon.com/cloudwatch/home?region=af-south-1#dashboards:name=bbws-wp-site-management-dev

# SIT Dashboard
https://af-south-1.console.aws.amazon.com/cloudwatch/home?region=af-south-1#dashboards:name=bbws-wp-site-management-sit

# PROD Dashboard
https://af-south-1.console.aws.amazon.com/cloudwatch/home?region=af-south-1#dashboards:name=bbws-wp-site-management-prod
```

---

## 9. Rollback Triggers

### Automatic Rollback Triggers

| Condition | Action |
|-----------|--------|
| Lambda errors > 50 in 5 minutes | Trigger rollback |
| API Gateway 5xx rate > 10% | Trigger rollback |
| SQS DLQ messages > 10 | Alert + manual decision |
| Site creation success rate < 95% | Alert + manual decision |
| WordPress API timeout rate > 5% | Alert + investigate |

### Manual Rollback Decision Criteria

| Severity | Criteria | Action |
|----------|----------|--------|
| **Critical** | Production down, no sites accessible | Immediate rollback |
| **High** | Site creation failing consistently | Rollback within 15 min |
| **Medium** | Intermittent failures, some operations failing | Investigate, rollback if not resolved in 1 hour |
| **Low** | Performance degradation, slow responses | Monitor, plan fix in next release |

### Rollback Procedure

#### Via GitHub (Recommended)

```bash
# 1. Identify last known good commit
git log --oneline -10

# 2. Revert to previous version
git revert <bad-commit-hash>
git push origin main

# 3. GitHub Actions will auto-deploy rollback to DEV
# 4. Follow normal promotion process to SIT/PROD if urgent
```

#### Via Terraform (Manual)

```bash
# 1. Navigate to terraform directory
cd /path/to/2_bbws_wordpress_site_management_lambda/terraform

# 2. Checkout previous working version
git checkout <previous-tag>

# 3. Re-initialize and apply
terraform init -backend-config=environments/${ENV}/backend.tfvars
terraform apply -var="environment=${ENV}" -var-file=environments/${ENV}/terraform.tfvars
```

#### Lambda Version Rollback (Fastest)

```bash
# If Lambda aliases are configured, rollback to previous version
aws lambda update-alias \
  --function-name ${ENV}-bbws-sites-service \
  --name live \
  --function-version <previous-version-number> \
  --region $AWS_REGION
```

---

## 10. Troubleshooting

### Issue: Terraform Lock Timeout

**Symptom**: `Error acquiring the state lock`

**Solution**:
```bash
# Check lock status
aws dynamodb get-item \
  --table-name terraform-state-lock-${ENV} \
  --key '{"LockID": {"S": "bbws-terraform-state-'${ENV}'/site-management-lambda/'${ENV}'/terraform.tfstate"}}' \
  --region $AWS_REGION

# Force unlock (use with caution - ensure no other apply in progress)
terraform force-unlock <LOCK_ID>
```

### Issue: Lambda Deployment Fails

**Symptom**: `ResourceNotFoundException: Function not found`

**Solution**:
1. Verify ZIP files exist: `ls -la */dist/*.zip`
2. Verify ZIP contents: `unzip -l sites-service/dist/lambda.zip`
3. Check IAM role permissions
4. Review CloudWatch logs for errors

### Issue: API Gateway 502 Bad Gateway

**Symptom**: API returns 502 error

**Solution**:
1. Check Lambda execution role has DynamoDB permissions
2. Verify DynamoDB table exists: `aws dynamodb describe-table --table-name sites`
3. Check Lambda environment variables
4. Check VPC configuration and security groups
5. Verify internal ALB is healthy

### Issue: Site Creation Stuck in PROVISIONING

**Symptom**: Site status remains PROVISIONING for > 15 minutes

**Solution**:
1. Check SQS queue for message backlog
2. Check DLQ for failed messages
3. Verify WordPress API connectivity via internal ALB
4. Check async-processor Lambda logs
5. Manually retry if transient failure

### Issue: WordPress API Connection Failures

**Symptom**: 502/504 errors from WordPress API calls

**Solution**:
1. Check internal ALB health checks
2. Verify ECS task is running
3. Check security group rules (Lambda -> ALB -> ECS)
4. Verify Secrets Manager credentials exist and are valid
5. Check VPC endpoint configuration

### Issue: Plugin Installation Fails with Security Error

**Symptom**: Plugin install returns 422 with security violation

**Solution**:
1. Check if plugin is on blocklist
2. Verify security scan results in logs
3. Plugin cannot be installed if security check fails
4. Escalate to security team if plugin is required

---

## 11. Environment-Specific Details

| Environment | AWS Account | Region | Auto-Deploy | Approval Required | Notes |
|-------------|-------------|--------|-------------|-------------------|-------|
| DEV | 536580886816 | af-south-1 | Yes (push to main) | No | Development and testing |
| SIT | 815856636111 | af-south-1 | No (manual trigger) | Yes (1 reviewer) | System Integration Testing |
| PROD | 093646564004 | af-south-1 | No (manual trigger) | Yes (2 reviewers + 10 min wait) | Production (read-only via Claude) |

### Lambda Function Naming

| Service | DEV | SIT | PROD |
|---------|-----|-----|------|
| Sites Service | `dev-bbws-sites-service` | `sit-bbws-sites-service` | `prod-bbws-sites-service` |
| Templates Service | `dev-bbws-templates-service` | `sit-bbws-templates-service` | `prod-bbws-templates-service` |
| Plugins Service | `dev-bbws-plugins-service` | `sit-bbws-plugins-service` | `prod-bbws-plugins-service` |
| Async Processor | `dev-bbws-async-processor` | `sit-bbws-async-processor` | `prod-bbws-async-processor` |

### SQS Queue Naming

| Queue Type | DEV | SIT | PROD |
|------------|-----|-----|------|
| Site Creation | `bbws-wp-site-creation-dev` | `bbws-wp-site-creation-sit` | `bbws-wp-site-creation-prod` |
| Site Update | `bbws-wp-site-update-dev` | `bbws-wp-site-update-sit` | `bbws-wp-site-update-prod` |
| Site Deletion | `bbws-wp-site-deletion-dev` | `bbws-wp-site-deletion-sit` | `bbws-wp-site-deletion-prod` |
| DLQ | `bbws-wp-site-operations-dlq-dev` | `bbws-wp-site-operations-dlq-sit` | `bbws-wp-site-operations-dlq-prod` |

---

## 12. Related Resources

### Documentation

| Document | Location |
|----------|----------|
| LLD 2.6 WordPress Site Management | `2_bbws_docs/LLDs/2.6_LLD_WordPress_Site_Management.md` |
| HLD 2.6 WordPress Site Management | `2_bbws_docs/HLDs/2.6_HLD_WordPress_Site_Management.md` |
| BRS 2.6 WordPress Site Management | `2_bbws_docs/BRS/2.6_BRS_WordPress_Site_Management.md` |
| OpenAPI Specification | `2_bbws_wordpress_site_management_lambda/openapi/` |
| Terraform README | `2_bbws_wordpress_site_management_lambda/terraform/README.md` |

### Related Runbooks

| Runbook | Purpose |
|---------|---------|
| `RB-001_Tenant_Provisioning.md` | Tenant infrastructure provisioning |
| `RB-002_Site_Generation_Troubleshooting.md` | Site creation troubleshooting |
| `product_lambda_disaster_recovery.md` | DR procedures reference |

### Related Repositories

| Repository | Purpose |
|------------|---------|
| `2_bbws_ecs_terraform` | Infrastructure as Code for ECS, ALB, VPC |
| `2_bbws_tenant_provisioner` | Tenant management CLI |
| `2_bbws_wordpress_container` | WordPress Docker image |
| `2_bbws_ecs_tests` | Integration tests |
| `2_bbws_ecs_operations` | Dashboards, alerts, runbooks |

---

## 13. Support Contacts

| Role | Contact | Escalation |
|------|---------|------------|
| Platform Team | platform-team@bbws.io | Slack: #bbws-platform |
| DevOps Team | devops@bbws.io | Slack: #bbws-devops |
| On-Call Engineer | PagerDuty | Escalate via PagerDuty |
| AWS Support | AWS Support Console | Business/Enterprise support |

---

## Appendix A: GitHub Actions Workflow Files

| Workflow | File | Purpose |
|----------|------|---------|
| Deploy to DEV | `.github/workflows/deploy-dev.yml` | Auto-deploy on push to main |
| Deploy to SIT | `.github/workflows/deploy-sit.yml` | Manual promotion from DEV |
| Deploy to PROD | `.github/workflows/deploy-prod.yml` | Manual promotion from SIT |
| Run Tests | `.github/workflows/test.yml` | PR validation tests |
| Release | `.github/workflows/release-and-test.yml` | Create versioned releases |

---

## Appendix B: Quick Reference Commands

```bash
# === COMMON COMMANDS ===

# Check Lambda status
aws lambda get-function --function-name ${ENV}-bbws-sites-service --region af-south-1 --query 'Configuration.State'

# Invoke Lambda manually (test)
aws lambda invoke --function-name ${ENV}-bbws-sites-service --payload '{}' response.json --region af-south-1

# Check SQS queue depth
aws sqs get-queue-attributes --queue-url $(aws sqs get-queue-url --queue-name bbws-wp-site-creation-${ENV} --query 'QueueUrl' --output text) --attribute-names All

# Check DLQ
aws sqs get-queue-attributes --queue-url $(aws sqs get-queue-url --queue-name bbws-wp-site-operations-dlq-${ENV} --query 'QueueUrl' --output text) --attribute-names ApproximateNumberOfMessages

# Tail Lambda logs
aws logs tail /aws/lambda/${ENV}-bbws-sites-service --follow --region af-south-1

# Check CloudWatch alarms
aws cloudwatch describe-alarms --alarm-name-prefix bbws-wp --state-value ALARM --region af-south-1

# Get API Gateway URL
aws apigatewayv2 get-apis --query "Items[?Name=='bbws-wp-site-management-${ENV}'].ApiEndpoint" --output text --region af-south-1
```

---

**Version**: 1.0
**Status**: Active
**Owner**: Platform Team
**Last Reviewed**: 2026-01-25
