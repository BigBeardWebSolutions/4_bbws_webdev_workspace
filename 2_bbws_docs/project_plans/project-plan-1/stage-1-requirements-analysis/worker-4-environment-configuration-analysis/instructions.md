# Worker Instructions: Environment Configuration Analysis

**Worker ID**: worker-4-environment-configuration-analysis
**Stage**: Stage 1 - Requirements & Analysis
**Project**: project-plan-1

---

## Task

Analyze and document environment-specific configurations for DEV, SIT, and PROD environments including AWS accounts, regions, resource configurations, and deployment strategies.

---

## Inputs

**Primary Inputs**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/HLDs/2.1_BBWS_Customer_Portal_Public_HLD_V1.1.md`
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/specs/2.1.8_LLD_S3_and_DynamoDB_Spec.md`
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/CLAUDE.md`

**Supporting Inputs**:
- `~/.claude/CLAUDE.md` (global environment config)

---

## Deliverables

Create `output.md` with comprehensive environment configuration matrices:

### 1. Environment Overview Matrix

| Environment | AWS Account | Region | Purpose | Deployment Type |
|-------------|-------------|--------|---------|-----------------|
| DEV | 536580886816 | af-south-1 | Development & Testing | Auto-deploy after validation |
| SIT | 815856636111 | af-south-1 | System Integration Testing | Manual promotion from DEV |
| PROD | 093646564004 | af-south-1 | Production (Live) | Manual promotion from SIT |
| DR (PROD) | 093646564004 | eu-west-1 | Disaster Recovery | Separate pipeline (out of scope) |

### 2. DynamoDB Configuration by Environment

| Setting | DEV | SIT | PROD | Notes |
|---------|-----|-----|------|-------|
| **Table Names** | tenants, products, campaigns | Same | Same | Account isolation |
| **Capacity Mode** | On-Demand | On-Demand | On-Demand | Required |
| **Encryption** | AWS-managed (SSE-KMS) | AWS-managed (SSE-KMS) | AWS-managed (SSE-KMS) | All envs |
| **PITR** | Enabled | Enabled | Enabled | All envs |
| **Backup Frequency** | Daily | Daily | Hourly | PROD more frequent |
| **Backup Retention** | 7 days | 14 days | 90 days | PROD longest |
| **Deletion Protection** | Disabled | Disabled | Enabled | PROD only |
| **Streams** | Enabled | Enabled | Enabled | All envs |
| **Cross-Region Replication** | No | No | Yes (to eu-west-1) | PROD only |

### 3. S3 Configuration by Environment

| Setting | DEV | SIT | PROD | Notes |
|---------|-----|-----|------|-------|
| **Bucket Name** | bbws-templates-dev | bbws-templates-sit | bbws-templates-prod | Unique names |
| **Region** | af-south-1 | af-south-1 | af-south-1 | Primary region |
| **Public Access** | Blocked | Blocked | Blocked | All envs |
| **Versioning** | Enabled | Enabled | Enabled | All envs |
| **Encryption** | SSE-S3 (AES-256) | SSE-S3 (AES-256) | SSE-S3 (AES-256) | All envs |
| **Lifecycle Policy** | 30 days | 60 days | 90 days | Version retention |
| **Access Logging** | Disabled | Enabled | Enabled | SIT/PROD only |
| **Replication** | No | No | Yes (to eu-west-1) | PROD only |

### 4. Terraform Backend Configuration by Environment

| Setting | DEV | SIT | PROD |
|---------|-----|-----|------|
| **State Bucket** | bbws-terraform-state-dev | bbws-terraform-state-sit | bbws-terraform-state-prod |
| **State Path** | 2_1_bbws_dynamodb_schemas/{component}/terraform.tfstate | Same pattern | Same pattern |
| **Lock Table** | terraform-state-lock-dev | terraform-state-lock-sit | terraform-state-lock-prod |
| **Encryption** | Enabled | Enabled | Enabled |
| **Versioning** | Enabled | Enabled | Enabled |

### 5. Terraform Variables by Environment

**dev.tfvars**:
```hcl
environment         = "dev"
aws_account_id      = "536580886816"
aws_region          = "af-south-1"
backup_retention    = 7
enable_deletion_protection = false
enable_pitr         = true
enable_replication  = false
tags = {
  Environment = "dev"
  Project     = "BBWS WP Containers"
  Owner       = "Tebogo"
  CostCenter  = "AWS"
  ManagedBy   = "Terraform"
}
```

**sit.tfvars**:
```hcl
environment         = "sit"
aws_account_id      = "815856636111"
aws_region          = "af-south-1"
backup_retention    = 14
enable_deletion_protection = false
enable_pitr         = true
enable_replication  = false
tags = {
  Environment = "sit"
  Project     = "BBWS WP Containers"
  Owner       = "Tebogo"
  CostCenter  = "AWS"
  ManagedBy   = "Terraform"
}
```

**prod.tfvars**:
```hcl
environment         = "prod"
aws_account_id      = "093646564004"
aws_region          = "af-south-1"
backup_retention    = 90
enable_deletion_protection = true
enable_pitr         = true
enable_replication  = true
replication_region  = "eu-west-1"
tags = {
  Environment = "prod"
  Project     = "BBWS WP Containers"
  Owner       = "Tebogo"
  CostCenter  = "AWS"
  ManagedBy   = "Terraform"
  BackupPolicy = "hourly"
}
```

### 6. CI/CD Pipeline Configuration by Environment

| Stage | DEV | SIT | PROD |
|-------|-----|-----|------|
| **Trigger** | Push to main (auto) | Manual promotion | Manual promotion |
| **Validation** | terraform fmt, validate, tfsec | Same | Same |
| **Approval Gate (Plan)** | Yes | Yes | Yes |
| **Approval Gate (Apply)** | Yes | Yes | Yes |
| **Approvers** | Lead Dev | Tech Lead + QA | Tech Lead + PO |
| **Post-Deploy Tests** | Basic validation | Integration tests | Smoke tests |
| **Rollback Available** | Yes | Yes | Yes |

### 7. Monitoring Configuration by Environment

| Metric | DEV | SIT | PROD |
|--------|-----|-----|------|
| **CloudWatch Alarms** | Basic errors | Errors + performance | Comprehensive |
| **SNS Notifications** | Dev team | Dev + QA team | All stakeholders |
| **Retention Period** | 7 days | 14 days | 90 days |
| **Detailed Monitoring** | Disabled | Enabled | Enabled |

### 8. Cost Budget by Environment

| Budget Type | DEV | SIT | PROD |
|-------------|-----|-----|------|
| **Monthly Budget** | $500 | $1,000 | $5,000 |
| **Alert Threshold** | 80% | 80% | 80% |
| **Forecast Alert** | 100% | 100% | 100% |

### 9. Deployment Strategy by Environment

| Strategy Element | DEV | SIT | PROD |
|------------------|-----|-----|------|
| **Deployment Window** | Anytime | Business hours | Change window only |
| **Rollback Time** | Immediate | < 30 min | < 15 min |
| **Testing Required** | Unit + basic | Integration + E2E | Smoke + sanity |
| **Approval Required** | Single approver | 2 approvers | 3 approvers |

### 10. Access Control by Environment

| Access Type | DEV | SIT | PROD |
|-------------|-----|-----|------|
| **Terraform Apply** | Developers | DevOps | DevOps + Approvers |
| **AWS Console** | Developers | DevOps + QA | Read-only |
| **State Bucket** | Developers | DevOps | DevOps only |
| **GitHub Secrets** | Admins | Admins | Admins |

---

## Expected Output Format

```markdown
# Environment Configuration Analysis Output

## 1. Environment Overview Matrix

(Table as shown above)

## 2. DynamoDB Configuration by Environment

(Table as shown above)

...

## 10. Access Control by Environment

(Table as shown above)

## Key Differences Summary

### DEV Environment
- Auto-deployment after validation
- Shorter retention periods
- No deletion protection
- No cross-region replication
- Lower monitoring detail

### SIT Environment
- Manual promotion from DEV
- Medium retention periods
- Integration testing focus
- QA team involvement
- Enhanced monitoring

### PROD Environment
- Manual promotion from SIT
- Longest retention periods
- Deletion protection enabled
- Cross-region replication to DR
- Comprehensive monitoring
- Strict approval requirements
- Read-only console access

## Configuration Principles

1. **Progressive Hardening**: Security/durability increases from DEV → PROD
2. **Cost Optimization**: Lower costs in DEV, production-grade in PROD
3. **Account Isolation**: Separate AWS accounts prevent cross-env impact
4. **Consistent Patterns**: Same resource types, different parameters
5. **Automation**: Infrastructure as Code for all environments
```

---

## Success Criteria

- [ ] All 10 configuration matrices completed
- [ ] Environment overview documented
- [ ] DynamoDB configs per env documented
- [ ] S3 configs per env documented
- [ ] Terraform backend configs documented
- [ ] Terraform variables specified for all envs
- [ ] CI/CD pipeline configs documented
- [ ] Monitoring configs documented
- [ ] Cost budgets documented
- [ ] Deployment strategies documented
- [ ] Access control documented
- [ ] Key differences summarized

---

## Execution Steps

1. Read HLD Section 2.1 (Application Definition)
2. Read CLAUDE.md environment sections
3. Read specification Section 5 (Terraform)
4. Read specification Section 6 (GitHub Actions)
5. Extract environment-specific settings
6. Create configuration matrices for each category
7. Define terraform variables for each environment
8. Document CI/CD differences per environment
9. Summarize key differences
10. Create output.md with all matrices
11. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2025-12-25
