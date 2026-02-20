# Environment Configuration Analysis Output

**Worker ID**: worker-4-environment-configuration-analysis
**Stage**: Stage 1 - Requirements & Analysis
**Project**: project-plan-1
**Created**: 2025-12-25
**Status**: Complete

---

## 1. Environment Overview Matrix

| Environment | AWS Account | Region | Purpose | Deployment Type |
|-------------|-------------|--------|---------|-----------------|
| DEV | 536580886816 | af-south-1 | Development & Testing | Auto-deploy after validation |
| SIT | 815856636111 | af-south-1 | System Integration Testing | Manual promotion from DEV |
| PROD | 093646564004 | af-south-1 | Production (Live) | Manual promotion from SIT |
| DR (PROD) | 093646564004 | eu-west-1 | Disaster Recovery | Cross-region replication (hourly sync) |

---

## 2. DynamoDB Configuration by Environment

| Setting | DEV | SIT | PROD | Notes |
|---------|-----|-----|------|-------|
| **Table Names** | tenants, products, campaigns | tenants, products, campaigns | tenants, products, campaigns | Account isolation - same names across envs |
| **Capacity Mode** | On-Demand | On-Demand | On-Demand | Mandatory requirement |
| **Encryption** | AWS-managed (SSE-KMS) | AWS-managed (SSE-KMS) | AWS-managed (SSE-KMS) | All environments |
| **PITR** | Enabled | Enabled | Enabled | All environments |
| **Backup Frequency** | Daily | Daily | Hourly | PROD more frequent |
| **Backup Retention** | 7 days | 14 days | 90 days | PROD longest retention |
| **Deletion Protection** | Disabled | Disabled | Enabled | PROD only |
| **Streams** | Enabled (New and Old Images) | Enabled (New and Old Images) | Enabled (New and Old Images) | Change data capture for auditing |
| **Cross-Region Replication** | No | No | Yes (to eu-west-1) | PROD DR requirement |
| **TTL** | Not enabled | Not enabled | Not enabled | No automatic expiration needed |

---

## 3. S3 Configuration by Environment

| Setting | DEV | SIT | PROD | Notes |
|---------|-----|-----|------|-------|
| **Bucket Name** | bbws-templates-dev | bbws-templates-sit | bbws-templates-prod | Unique names per environment |
| **Region** | af-south-1 | af-south-1 | af-south-1 | Primary region |
| **Public Access** | Blocked | Blocked | Blocked | Security requirement - all environments |
| **Versioning** | Enabled | Enabled | Enabled | Template version tracking |
| **Encryption** | SSE-S3 (AES-256) | SSE-S3 (AES-256) | SSE-S3 (AES-256) | All environments |
| **Lifecycle Policy** | 30 days | 60 days | 90 days | Version retention varies |
| **Access Logging** | Disabled | Enabled | Enabled | SIT/PROD audit trails |
| **Replication** | No | No | Yes (to eu-west-1) | PROD DR requirement |
| **Object Lock** | Not enabled | Not enabled | Not enabled | No compliance hold needed |

---

## 4. Terraform Backend Configuration by Environment

| Setting | DEV | SIT | PROD |
|---------|-----|-----|------|
| **State Bucket** | bbws-terraform-state-dev | bbws-terraform-state-sit | bbws-terraform-state-prod |
| **State Path** | 2_1_bbws_dynamodb_schemas/{component}/terraform.tfstate | 2_1_bbws_dynamodb_schemas/{component}/terraform.tfstate | 2_1_bbws_dynamodb_schemas/{component}/terraform.tfstate |
| **Lock Table** | terraform-state-lock-dev | terraform-state-lock-sit | terraform-state-lock-prod |
| **Encryption** | Enabled (SSE-S3) | Enabled (SSE-S3) | Enabled (SSE-S3) |
| **Versioning** | Enabled | Enabled | Enabled |
| **State Per Component** | Yes (separate .tfstate files) | Yes (separate .tfstate files) | Yes (separate .tfstate files) |

**Component-Specific State Paths:**
```
s3://bbws-terraform-state-{env}/
├── 2_1_bbws_dynamodb_schemas/
│   ├── tenants/terraform.tfstate
│   ├── products/terraform.tfstate
│   └── campaigns/terraform.tfstate
└── 2_1_bbws_s3_schemas/
    └── templates/terraform.tfstate
```

---

## 5. Terraform Variables by Environment (with .tfvars examples)

### 5.1 dev.tfvars

```hcl
# Environment Configuration
environment         = "dev"
aws_account_id      = "536580886816"
aws_region          = "af-south-1"

# DynamoDB Settings
backup_retention_days    = 7
enable_deletion_protection = false
enable_pitr              = true
enable_replication       = false

# S3 Settings
s3_versioning_enabled    = true
s3_lifecycle_days        = 30
s3_access_logging        = false

# Tagging
tags = {
  Environment = "dev"
  Project     = "BBWS WP Containers"
  Owner       = "Tebogo"
  CostCenter  = "AWS"
  ManagedBy   = "Terraform"
  Application = "CustomerPortalPublic"
}
```

### 5.2 sit.tfvars

```hcl
# Environment Configuration
environment         = "sit"
aws_account_id      = "815856636111"
aws_region          = "af-south-1"

# DynamoDB Settings
backup_retention_days    = 14
enable_deletion_protection = false
enable_pitr              = true
enable_replication       = false

# S3 Settings
s3_versioning_enabled    = true
s3_lifecycle_days        = 60
s3_access_logging        = true

# Tagging
tags = {
  Environment = "sit"
  Project     = "BBWS WP Containers"
  Owner       = "Tebogo"
  CostCenter  = "AWS"
  ManagedBy   = "Terraform"
  Application = "CustomerPortalPublic"
}
```

### 5.3 prod.tfvars

```hcl
# Environment Configuration
environment         = "prod"
aws_account_id      = "093646564004"
aws_region          = "af-south-1"

# DynamoDB Settings
backup_retention_days    = 90
enable_deletion_protection = true
enable_pitr              = true
enable_replication       = true
replication_region       = "eu-west-1"

# S3 Settings
s3_versioning_enabled    = true
s3_lifecycle_days        = 90
s3_access_logging        = true

# Tagging
tags = {
  Environment  = "prod"
  Project      = "BBWS WP Containers"
  Owner        = "Tebogo"
  CostCenter   = "AWS"
  ManagedBy    = "Terraform"
  Application  = "CustomerPortalPublic"
  BackupPolicy = "hourly"
  DR           = "enabled"
}
```

---

## 6. CI/CD Pipeline Configuration by Environment

| Stage | DEV | SIT | PROD |
|-------|-----|-----|------|
| **Trigger** | Push to main (automatic) | Manual promotion | Manual promotion |
| **Validation** | terraform fmt, validate, tfsec | Same as DEV | Same as DEV |
| **Approval Gate (Plan)** | Yes (Lead Dev) | Yes (Tech Lead + QA) | Yes (Tech Lead + PO) |
| **Approval Gate (Apply)** | Yes (manual trigger) | Yes (manual trigger) | Yes (manual trigger) |
| **Approvers** | Lead Developer | Tech Lead + QA Lead | Tech Lead + Product Owner + DevOps |
| **Post-Deploy Tests** | Basic validation | Integration tests | Smoke tests + sanity checks |
| **Rollback Available** | Yes (terraform state rollback) | Yes (terraform state rollback) | Yes (terraform state rollback) |
| **Notification** | Slack #dev-alerts | Slack #sit-alerts, Email QA | Slack #prod-alerts, Email All Stakeholders |
| **Deployment Window** | Anytime | Business hours (8am-5pm SAST) | Change window only (pre-approved) |

### 6.1 Pipeline Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│                    CI/CD PIPELINE FLOW                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. CODE PUSH (main branch)                                     │
│     └── Triggers validation pipeline                           │
│                                                                 │
│  2. VALIDATION STAGE                                            │
│     ├── terraform fmt -check                                    │
│     ├── terraform validate                                      │
│     ├── tfsec security scan                                     │
│     └── infracost estimate                                      │
│                                                                 │
│  3. TERRAFORM PLAN (all environments)                           │
│     ├── Generate plan for DEV                                   │
│     ├── Generate plan for SIT                                   │
│     └── Generate plan for PROD                                  │
│                                                                 │
│  4. APPROVAL GATE: DEV DEPLOYMENT                               │
│     ├── Review terraform plan                                   │
│     ├── Lead Dev approval required                              │
│     └── Manual trigger: "deploy-dev"                            │
│                                                                 │
│  5. DEPLOY TO DEV                                               │
│     ├── terraform apply (dev.tfvars)                            │
│     ├── Post-deployment validation tests                        │
│     └── Notify: Slack #dev-alerts                               │
│                                                                 │
│  6. APPROVAL GATE: SIT PROMOTION                                │
│     ├── DEV tests must pass                                     │
│     ├── Tech Lead + QA approval required                        │
│     └── Manual trigger: "promote-sit"                           │
│                                                                 │
│  7. PROMOTE TO SIT                                              │
│     ├── terraform apply (sit.tfvars)                            │
│     ├── Integration tests                                       │
│     └── Notify: Slack #sit-alerts + Email QA                    │
│                                                                 │
│  8. APPROVAL GATE: PROD PROMOTION                               │
│     ├── SIT tests must pass                                     │
│     ├── Tech Lead + PO + DevOps approval                        │
│     └── Manual trigger: "promote-prod"                          │
│                                                                 │
│  9. PROMOTE TO PROD                                             │
│     ├── terraform apply (prod.tfvars)                           │
│     ├── Smoke tests + sanity checks                             │
│     └── Notify: All stakeholders                                │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 7. Monitoring Configuration by Environment

| Metric | DEV | SIT | PROD |
|--------|-----|-----|------|
| **CloudWatch Alarms** | Basic errors only | Errors + performance warnings | Comprehensive (errors, performance, availability) |
| **SNS Notifications** | Dev team Slack | Dev + QA Slack + Email | All stakeholders (Slack + Email + PagerDuty) |
| **Log Retention Period** | 7 days | 14 days | 90 days |
| **Detailed Monitoring** | Disabled (5-min intervals) | Enabled (1-min intervals) | Enabled (1-min intervals) |
| **Dashboard** | Basic metrics | Service-level metrics | Executive + Service-level dashboards |
| **Dead Letter Queue** | Enabled | Enabled | Enabled |
| **DLQ Retention** | 7 days | 14 days | 14 days |
| **State Management Table** | Enabled | Enabled | Enabled |
| **Alert Escalation** | None | After 2 hours → Tech Lead | After 30 min → Tech Lead, After 1 hour → PO |

### 7.1 CloudWatch Alarms by Environment

| Alarm Type | DEV Threshold | SIT Threshold | PROD Threshold |
|------------|---------------|---------------|----------------|
| Lambda Errors | > 10 in 5 min | > 5 in 5 min | > 3 in 5 min |
| DynamoDB Throttling | > 50 requests | > 20 requests | > 10 requests |
| API Gateway 5xx | > 10 in 5 min | > 5 in 5 min | > 2 in 5 min |
| DLQ Message Count | > 5 messages | > 3 messages | > 1 message |

---

## 8. Cost Budget by Environment

| Budget Type | DEV | SIT | PROD |
|-------------|-----|-----|------|
| **Monthly Budget** | $500 | $1,000 | $5,000 |
| **Alert Threshold (80%)** | $400 | $800 | $4,000 |
| **Forecast Alert (100%)** | $500 | $1,000 | $5,000 |
| **Notification Recipients** | DevOps team | DevOps + Finance | DevOps + Finance + Executives |
| **Cost Allocation Tags** | Environment=dev, Project=BBWS | Environment=sit, Project=BBWS | Environment=prod, Project=BBWS |
| **Budget Period** | Monthly | Monthly | Monthly |
| **Budget Type** | Cost | Cost | Cost + Usage |

### 8.1 Cost Breakdown Estimates

| Service | DEV Monthly | SIT Monthly | PROD Monthly |
|---------|-------------|-------------|--------------|
| **DynamoDB** | $50 | $100 | $800 |
| **S3** | $10 | $20 | $100 |
| **Lambda** | $50 | $100 | $500 |
| **API Gateway** | $20 | $50 | $400 |
| **CloudWatch** | $10 | $20 | $100 |
| **Data Transfer** | $10 | $20 | $200 |
| **Backups** | $5 | $10 | $100 |
| **Cross-Region Replication** | $0 | $0 | $300 |
| **Total Estimated** | ~$155 | ~$320 | ~$2,500 |
| **Budget Buffer** | 3.2x | 3.1x | 2x |

---

## 9. Deployment Strategy by Environment

| Strategy Element | DEV | SIT | PROD |
|------------------|-----|-----|------|
| **Deployment Window** | Anytime | Business hours (8am-5pm SAST) | Pre-approved change window only |
| **Rollback Time (RTO)** | Immediate (best effort) | < 30 min | < 15 min |
| **Testing Required** | Unit + basic integration | Integration + E2E | Smoke + sanity + regression |
| **Approval Required** | 1 approver (Lead Dev) | 2 approvers (Tech Lead + QA) | 3 approvers (Tech Lead + PO + DevOps) |
| **Backup Before Deploy** | No | Yes (on-demand) | Yes (mandatory) |
| **Canary Deployment** | No | No | Yes (10% traffic for 1 hour) |
| **Blue/Green Support** | No | Optional | Recommended |
| **Rollback Strategy** | Terraform state rollback | Terraform state rollback + data restore | Terraform state rollback + data restore + traffic shift |
| **Post-Deploy Validation** | Automated tests | Automated + manual QA | Automated + manual + business validation |

### 9.1 Promotion Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│              ENVIRONMENT PROMOTION WORKFLOW                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  DEV ENVIRONMENT                                                │
│  ├── Auto-deploy after validation passes                       │
│  ├── Run unit tests + basic integration tests                  │
│  ├── Developer testing and validation                          │
│  └── Lead Dev sign-off                                         │
│       │                                                         │
│       ▼                                                         │
│  APPROVAL GATE: PROMOTE TO SIT                                  │
│  ├── Review DEV test results                                   │
│  ├── Review terraform plan for SIT                             │
│  ├── Tech Lead approval                                        │
│  └── QA Lead approval                                          │
│       │                                                         │
│       ▼                                                         │
│  SIT ENVIRONMENT                                                │
│  ├── Manual trigger "promote-sit"                              │
│  ├── terraform apply (sit.tfvars)                              │
│  ├── Run integration tests + E2E tests                         │
│  ├── QA team validation                                        │
│  └── Business Owner validation (for customer-facing changes)   │
│       │                                                         │
│       ▼                                                         │
│  APPROVAL GATE: PROMOTE TO PROD                                 │
│  ├── Review SIT test results                                   │
│  ├── Review terraform plan for PROD                            │
│  ├── Tech Lead approval                                        │
│  ├── Product Owner approval                                    │
│  ├── DevOps approval                                           │
│  └── Change Management ticket (for major changes)              │
│       │                                                         │
│       ▼                                                         │
│  PROD ENVIRONMENT                                               │
│  ├── Manual trigger "promote-prod"                             │
│  ├── Pre-deployment backup (mandatory)                         │
│  ├── terraform apply (prod.tfvars)                             │
│  ├── Canary deployment (10% traffic, 1 hour)                   │
│  ├── Run smoke tests + sanity checks                           │
│  ├── Business validation                                       │
│  ├── Full traffic cutover                                      │
│  └── Post-deployment monitoring (24 hours)                     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 10. Access Control by Environment

| Access Type | DEV | SIT | PROD |
|-------------|-----|-----|------|
| **Terraform Apply** | Developers (via pipeline) | DevOps (via pipeline) | DevOps + Approvers (via pipeline) |
| **AWS Console (Write)** | Developers | DevOps + QA | DevOps only (emergency) |
| **AWS Console (Read)** | Developers | DevOps + QA + Tech Lead | All stakeholders (read-only) |
| **State Bucket Access** | Developers | DevOps | DevOps only |
| **GitHub Secrets Management** | Admins | Admins | Admins |
| **DynamoDB Direct Access** | Developers (read/write) | DevOps + QA (read/write) | Read-only (via AWS Console) |
| **S3 Direct Access** | Developers (read/write) | DevOps + QA (read/write) | Read-only (via AWS Console) |
| **Lambda Function Modification** | Via pipeline only | Via pipeline only | Via pipeline only |
| **IAM Role Assumption** | Developers (time-limited) | DevOps (time-limited) | DevOps only (time-limited, logged) |

### 10.1 IAM Roles by Environment

| Role Name | Environment | Permissions | Who Can Assume |
|-----------|-------------|-------------|----------------|
| `bbws-terraform-deployer-dev` | DEV | Full DynamoDB, S3, Lambda, API Gateway | GitHub Actions, Developers |
| `bbws-terraform-deployer-sit` | SIT | Full DynamoDB, S3, Lambda, API Gateway | GitHub Actions, DevOps |
| `bbws-terraform-deployer-prod` | PROD | Full DynamoDB, S3, Lambda, API Gateway | GitHub Actions only |
| `bbws-developer-dev` | DEV | Read/Write on all resources | Developers |
| `bbws-developer-sit` | SIT | Read/Write on all resources | DevOps, QA |
| `bbws-readonly-prod` | PROD | Read-only on all resources | All stakeholders |

### 10.2 GitHub Secrets by Environment

| Secret Name | DEV Value | SIT Value | PROD Value | Usage |
|-------------|-----------|-----------|------------|-------|
| `AWS_ROLE_DEV` | arn:aws:iam::536580886816:role/bbws-terraform-deployer-dev | N/A | N/A | Terraform deployment |
| `AWS_ROLE_SIT` | N/A | arn:aws:iam::815856636111:role/bbws-terraform-deployer-sit | N/A | Terraform deployment |
| `AWS_ROLE_PROD` | N/A | N/A | arn:aws:iam::093646564004:role/bbws-terraform-deployer-prod | Terraform deployment |
| `SLACK_WEBHOOK_DEV` | https://hooks.slack.com/dev | N/A | N/A | Notifications |
| `SLACK_WEBHOOK_SIT` | N/A | https://hooks.slack.com/sit | N/A | Notifications |
| `SLACK_WEBHOOK_PROD` | N/A | N/A | https://hooks.slack.com/prod | Notifications |

---

## Key Differences Summary

### DEV Environment
- **Purpose**: Development and testing
- **Deployment**: Auto-deploy after validation passes
- **Retention**: Shortest (7 days)
- **Protection**: No deletion protection
- **Replication**: None
- **Monitoring**: Basic error alerts only
- **Budget**: $500/month
- **Access**: Developers have full access
- **Testing**: Unit + basic integration tests
- **Approval**: Single approver (Lead Dev)

### SIT Environment
- **Purpose**: System Integration Testing and QA validation
- **Deployment**: Manual promotion from DEV
- **Retention**: Medium (14 days)
- **Protection**: No deletion protection
- **Replication**: None
- **Monitoring**: Errors + performance warnings
- **Budget**: $1,000/month
- **Access**: DevOps + QA have full access
- **Testing**: Integration + E2E tests
- **Approval**: Two approvers (Tech Lead + QA Lead)

### PROD Environment
- **Purpose**: Production live environment
- **Deployment**: Manual promotion from SIT with strict approval
- **Retention**: Longest (90 days)
- **Protection**: Deletion protection enabled
- **Replication**: Yes (to eu-west-1 for DR)
- **Monitoring**: Comprehensive monitoring with 24/7 alerting
- **Budget**: $5,000/month
- **Access**: Read-only for most, write via pipeline only
- **Testing**: Smoke + sanity + regression + business validation
- **Approval**: Three approvers (Tech Lead + PO + DevOps)
- **Change Windows**: Pre-approved windows only
- **Rollback**: < 15 minutes RTO
- **Canary**: 10% traffic test for 1 hour before full cutover

---

## Configuration Principles

### 1. Progressive Hardening
Security, durability, and monitoring increase from DEV → SIT → PROD:
- **DEV**: Minimal protection, fast iteration
- **SIT**: Medium protection, quality gates
- **PROD**: Maximum protection, strict controls

### 2. Cost Optimization
Resource allocation matches environment criticality:
- **DEV**: Cost-conscious (buffer: 3.2x)
- **SIT**: Balanced (buffer: 3.1x)
- **PROD**: Production-grade (buffer: 2x for predictability)

### 3. Account Isolation
Separate AWS accounts prevent cross-environment impact:
- **DEV**: 536580886816
- **SIT**: 815856636111
- **PROD**: 093646564004

This ensures:
- No accidental DEV changes affect PROD
- Independent IAM policies per environment
- Clear cost separation
- Blast radius containment

### 4. Consistent Patterns
Same resource types and naming across environments:
- **DynamoDB**: tenants, products, campaigns (same table names)
- **S3**: bbws-templates-{env} (environment suffix)
- **Terraform**: Same module structure, different .tfvars

Benefits:
- Code reusability
- Reduced configuration drift
- Simplified troubleshooting
- Easier promotion between environments

### 5. Automation
Infrastructure as Code for all environments:
- **No manual AWS Console changes** (except emergencies)
- **All changes via terraform** (version controlled)
- **Approval gates** (human validation at critical stages)
- **Automated testing** (post-deployment validation)

This ensures:
- Reproducible deployments
- Audit trail
- Rollback capability
- Environment parity

### 6. Parameterization
No hardcoded values, everything configurable:
- **Environment-specific .tfvars files**
- **AWS account IDs parameterized**
- **Region configurable** (af-south-1 primary, eu-west-1 DR)
- **Retention periods configurable**
- **Budget thresholds configurable**

Benefits:
- Deploy to any environment without code changes
- Easy to add new environments (e.g., UAT)
- Configuration as documentation
- Prevents accidental cross-environment deployments

### 7. Disaster Recovery
Multi-region strategy for PROD only:
- **Primary Region**: af-south-1 (Cape Town, South Africa)
- **DR Region**: eu-west-1 (Ireland)
- **Strategy**: Multi-site Active/Active (serverless)
- **Replication**: Hourly DynamoDB backups + S3 cross-region replication
- **Failover**: Route 53 health checks
- **RTO**: < 15 minutes
- **RPO**: < 1 hour (hourly backups)

DEV and SIT do not require DR:
- Lower criticality
- Cost optimization
- Faster recovery acceptable (restore from backup)

---

## Compliance and Security

### 1. Data Protection
- **Encryption at rest**: SSE-KMS (DynamoDB), SSE-S3 (S3)
- **Encryption in transit**: HTTPS/TLS for all API traffic
- **Versioning**: Enabled on all S3 buckets
- **PITR**: Enabled on all DynamoDB tables

### 2. Access Control
- **Principle of least privilege**: Developers limited to DEV
- **Read-only PROD**: Prevents accidental changes
- **Time-limited sessions**: IAM role assumption expires
- **MFA**: Required for PROD access (future enhancement)

### 3. Audit and Compliance
- **CloudWatch Logs**: All Lambda invocations logged
- **S3 Access Logging**: SIT and PROD buckets
- **DynamoDB Streams**: Change data capture for audit
- **Terraform State**: Versioned in S3, locked with DynamoDB
- **GitHub Actions**: Full deployment audit trail

### 4. Backup and Recovery
- **PITR**: 35-day continuous backup (all environments)
- **AWS Backup**: Scheduled backups (7/14/90 day retention)
- **Cross-Region**: PROD only (to eu-west-1)
- **Terraform State**: S3 versioning for rollback

---

## Future Enhancements

### 1. Additional Environments
- **UAT**: User Acceptance Testing (between SIT and PROD)
- **PERF**: Performance testing environment
- **SANDBOX**: Isolated experimentation environment

### 2. Advanced DR
- **Active-Active**: Full traffic splitting (not just failover)
- **Multi-region writes**: DynamoDB global tables
- **Automated failover**: Health-based traffic routing

### 3. Enhanced Monitoring
- **Distributed tracing**: AWS X-Ray integration
- **APM**: Application Performance Monitoring
- **Synthetic monitoring**: Automated user journey tests
- **Cost anomaly detection**: AWS Cost Anomaly Detection

### 4. Security Hardening
- **MFA enforcement**: Required for PROD access
- **VPC endpoints**: Private connectivity to AWS services
- **WAF**: Web Application Firewall on API Gateway
- **GuardDuty**: Threat detection
- **Security Hub**: Centralized security findings

---

## Related Documents

- **HLD**: `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/HLDs/2.1_BBWS_Customer_Portal_Public_HLD_V1.1.md`
- **S3 and DynamoDB Spec**: `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/specs/2.1.8_LLD_S3_and_DynamoDB_Spec.md`
- **Global Config**: `/Users/tebogotseka/.claude/CLAUDE.md`
- **Project Instructions**: `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/CLAUDE.md`

---

**End of Environment Configuration Analysis**
