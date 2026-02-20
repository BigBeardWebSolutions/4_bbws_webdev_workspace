# Stage 6: CI/CD Pipeline

**Stage ID**: stage-6-cicd-pipeline
**Project**: project-plan-2-access-management
**Status**: PENDING
**Workers**: 6 (parallel execution)

---

## Stage Objective

Create GitHub Actions workflows for automated testing, Terraform planning, Lambda deployment, environment promotion, rollback procedures, and monitoring/alerting setup.

---

## Stage Workers

| Worker | Task | Workflows | Status |
|--------|------|-----------|--------|
| worker-1-terraform-plan-workflow | Create Terraform plan/apply workflows | 2 | PENDING |
| worker-2-lambda-deploy-workflow | Create Lambda deployment workflows | 3 | PENDING |
| worker-3-test-automation-workflow | Create test automation workflows | 2 | PENDING |
| worker-4-environment-promotion-workflow | Create env promotion workflows | 2 | PENDING |
| worker-5-rollback-workflow | Create rollback workflows | 2 | PENDING |
| worker-6-monitoring-alerts-workflow | Create monitoring setup workflows | 2 | PENDING |

**Total**: 13 Workflow Files

---

## Stage Inputs

**From Stage 2**:
- Terraform modules

**From Stage 3**:
- Lambda function code

**From Stage 5**:
- Test suites

**Configuration**:
- AWS account IDs (DEV, SIT, PROD)
- Region configurations
- Secret names

---

## Environment Configuration

| Environment | AWS Account | Region | Branch |
|-------------|-------------|--------|--------|
| DEV | 536580886816 | eu-west-1 | develop |
| SIT | 815856636111 | eu-west-1 | release/* |
| PROD | 093646564004 | af-south-1 | main |

---

## Workflow Summary

### 1. Terraform Plan Workflow (worker-1)

**File**: `.github/workflows/terraform-plan.yml`
```yaml
Trigger: Pull Request to develop, release/*, main
Steps:
  - Checkout code
  - Setup Terraform
  - Terraform init
  - Terraform validate
  - Terraform plan
  - Post plan to PR
```

**File**: `.github/workflows/terraform-apply.yml`
```yaml
Trigger: Push to develop (DEV), release/* (SIT), main (PROD)
Steps:
  - Checkout code
  - Setup Terraform
  - Terraform init
  - Terraform apply -auto-approve
  - Post apply summary
```

### 2. Lambda Deploy Workflow (worker-2)

**File**: `.github/workflows/lambda-deploy-dev.yml`
**File**: `.github/workflows/lambda-deploy-sit.yml`
**File**: `.github/workflows/lambda-deploy-prod.yml`
```yaml
Trigger: Push to respective branch
Steps:
  - Checkout code
  - Setup Python 3.12
  - Install dependencies
  - Run unit tests
  - Package Lambda
  - Deploy to AWS
  - Run smoke tests
```

### 3. Test Automation Workflow (worker-3)

**File**: `.github/workflows/test-unit.yml`
```yaml
Trigger: Pull Request
Steps:
  - Checkout code
  - Setup Python
  - Install dependencies
  - Run unit tests
  - Generate coverage report
  - Post coverage to PR
```

**File**: `.github/workflows/test-integration.yml`
```yaml
Trigger: Push to develop
Steps:
  - Checkout code
  - Setup Python
  - Configure AWS credentials (DEV)
  - Run integration tests
  - Generate report
```

### 4. Environment Promotion Workflow (worker-4)

**File**: `.github/workflows/promote-to-sit.yml`
```yaml
Trigger: Manual (workflow_dispatch)
Input: Version tag
Steps:
  - Create release branch
  - Deploy to SIT
  - Run integration tests
  - Notify team
```

**File**: `.github/workflows/promote-to-prod.yml`
```yaml
Trigger: Manual (workflow_dispatch)
Input: Version tag, Approval
Steps:
  - Require approval
  - Merge to main
  - Deploy to PROD
  - Run smoke tests
  - Notify team
```

### 5. Rollback Workflow (worker-5)

**File**: `.github/workflows/rollback-lambda.yml`
```yaml
Trigger: Manual (workflow_dispatch)
Input: Environment, Version
Steps:
  - Get previous version
  - Rollback Lambda aliases
  - Run smoke tests
  - Notify team
```

**File**: `.github/workflows/rollback-terraform.yml`
```yaml
Trigger: Manual (workflow_dispatch)
Input: Environment, Commit SHA
Steps:
  - Checkout specific commit
  - Terraform plan
  - Require approval
  - Terraform apply
  - Verify rollback
```

### 6. Monitoring Alerts Workflow (worker-6)

**File**: `.github/workflows/setup-monitoring.yml`
```yaml
Trigger: Manual or post-deploy
Steps:
  - Deploy CloudWatch alarms
  - Configure SNS topics
  - Setup dashboards
  - Verify alerts
```

**File**: `.github/workflows/alert-notification.yml`
```yaml
Trigger: CloudWatch alarm via SNS
Steps:
  - Parse alarm details
  - Send Slack notification
  - Create incident ticket
```

---

## Stage Outputs

### Workflow Files
```
.github/workflows/
├── terraform-plan.yml
├── terraform-apply.yml
├── lambda-deploy-dev.yml
├── lambda-deploy-sit.yml
├── lambda-deploy-prod.yml
├── test-unit.yml
├── test-integration.yml
├── promote-to-sit.yml
├── promote-to-prod.yml
├── rollback-lambda.yml
├── rollback-terraform.yml
├── setup-monitoring.yml
└── alert-notification.yml
```

### Secrets Required
```
Repository Secrets:
├── AWS_ACCESS_KEY_ID_DEV
├── AWS_SECRET_ACCESS_KEY_DEV
├── AWS_ACCESS_KEY_ID_SIT
├── AWS_SECRET_ACCESS_KEY_SIT
├── AWS_ACCESS_KEY_ID_PROD
├── AWS_SECRET_ACCESS_KEY_PROD
├── SLACK_WEBHOOK_URL
└── TERRAFORM_STATE_BUCKET
```

---

## Success Criteria

- [ ] All 13 workflow files created
- [ ] Workflows pass validation
- [ ] Terraform plan works in DEV
- [ ] Lambda deploy works in DEV
- [ ] Unit tests run on PR
- [ ] Integration tests run on push
- [ ] Promotion workflow tested
- [ ] Rollback workflow tested
- [ ] Monitoring alerts configured
- [ ] All 6 workers completed
- [ ] Stage summary created

---

## Branch Strategy

```
main (PROD)
├── release/v1.0.0 (SIT)
│   └── develop (DEV)
│       ├── feature/permission-service
│       ├── feature/invitation-service
│       └── ...
```

---

## Deployment Order

1. **Infrastructure** (Terraform) - DynamoDB, IAM, S3
2. **Lambda Functions** - Permission, Invitation, Team, Role, Audit
3. **Authorizer** - Lambda Authorizer
4. **API Gateway** - Routes and integrations
5. **Monitoring** - Alarms and dashboards

---

## Dependencies

**Depends On**: Stage 5 (Testing & Validation)

**Blocks**: Stage 7 (Documentation & Runbooks)

---

## Security Considerations

- Use OIDC for AWS authentication (preferred)
- Separate credentials per environment
- Require approval for PROD deployments
- Audit all deployments
- Never expose secrets in logs

---

**Created**: 2026-01-23
