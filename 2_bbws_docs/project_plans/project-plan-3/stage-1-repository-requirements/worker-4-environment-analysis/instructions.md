# Worker 4: Environment Analysis

**Worker Task**: Analyze and document multi-environment configurations
**Parent Stage**: Stage 1 - Repository Requirements
**LLD Reference**: 2.1.8_LLD_Order_Lambda.md

---

## Task Description

Analyze the BBWS deployment environments (DEV, SIT, PROD) and create comprehensive documentation for multi-environment deployment strategy. This includes environment specifications, regional configuration, failover strategy, and environment-specific parameters for Terraform and CI/CD pipelines.

### Key Responsibilities

1. Document environment specifications (DEV, SIT, PROD)
2. Analyze AWS account configuration for each environment
3. Document primary and failover regions
4. Create environment parameter matrix for Terraform
5. Define promotion workflow (dev → sit → prod)
6. Document environment-specific configurations
7. Create disaster recovery strategy documentation
8. Document environment naming conventions

---

## Inputs

### BBWS Environment Information

**Development Environment (DEV)**
- AWS Account ID: 536580886816
- Primary Region: af-south-1 (Cape Town)
- Purpose: Development and rapid iteration
- Data: Non-sensitive test data
- Compliance: Testing/development only

**System Integration Testing (SIT)**
- AWS Account ID: 815856636111
- Primary Region: af-south-1 (Cape Town)
- Purpose: Pre-production validation
- Data: Non-sensitive test data (realistic volume)
- Compliance: Testing/validation

**Production (PROD)**
- AWS Account ID: 093646564004
- Primary Region: af-south-1 (Cape Town)
- Failover Region: eu-west-1 (Dublin)
- Purpose: Live production environment
- Data: Real customer data (sensitive)
- Compliance: PCI DSS, GDPR, local data residency

### DR Strategy from CLAUDE.md

- **Pattern**: Multi-site Active/Active
- **Backup Strategy**: Hourly DynamoDB backups + cross-region replication
- **RTO**: < 1 hour
- **RPO**: < 5 minutes

---

## Deliverables

### Output Document: `output.md`

The final output must be saved as `/worker-4-environment-analysis/output.md` and include:

1. **Environment Matrix**
   - Account IDs for each environment
   - Regions and failover configuration
   - Environment purpose and characteristics
   - Access control and security levels

2. **AWS Account Details**
   - Account structure and organization
   - VPC configuration per environment
   - Networking topology
   - Cross-account IAM policies

3. **Regional Configuration**
   - Primary region: af-south-1 (Cape Town)
   - Failover region: eu-west-1 (Dublin) [PROD only]
   - Latency expectations
   - Data residency requirements

4. **Parameter Matrix**
   - Environment-specific Terraform variables
   - S3 bucket names by environment
   - DynamoDB table names by environment
   - SQS queue names by environment
   - Lambda function names by environment
   - API Gateway endpoint URLs by environment

5. **Promotion Workflow**
   - DEV → SIT promotion criteria
   - SIT → PROD promotion criteria
   - Approval gates and sign-off procedures
   - Rollback procedures
   - State management strategy

6. **Disaster Recovery Strategy**
   - Active/Active multi-region setup (PROD)
   - DynamoDB cross-region replication (PROD)
   - S3 cross-region replication (PROD)
   - Route 53 health checks and failover
   - RTO/RPO targets and validation

7. **Environment-Specific Configurations**
   - Database capacity (on-demand for all)
   - Lambda concurrency settings per environment
   - SES sending limits per environment
   - CloudWatch retention policies
   - Cost optimization strategies

8. **Terraform Configuration Strategy**
   - Variable file organization (dev.tfvars, sit.tfvars, prod.tfvars)
   - State file management (separate state per environment)
   - Backend configuration per account
   - S3 backend for state storage
   - DynamoDB locking

9. **CI/CD Pipeline Configuration**
   - GitHub Actions environment variables
   - Deployment approval gates per environment
   - OIDC role ARNs for each environment
   - Environment-specific workflow steps
   - Post-deployment testing per environment

10. **Access Control and Security**
    - IAM role policies per environment
    - Least privilege principles
    - Environment-specific permissions
    - Cross-environment access (if needed)
    - Sensitive data handling per environment

---

## Success Criteria

### Completeness Criteria

- [ ] All 3 environments documented (DEV, SIT, PROD)
- [ ] AWS account details specified for each environment
- [ ] Primary and failover regions documented
- [ ] Parameter matrix includes all resource names for each environment
- [ ] Promotion workflow defined with approval gates
- [ ] DR strategy aligned with multi-site active/active pattern
- [ ] Terraform configuration strategy specified
- [ ] CI/CD pipeline configuration per environment
- [ ] Access control policies defined

### Quality Criteria

- [ ] All parameters are environment-specific (no hardcoding)
- [ ] S3 bucket names follow naming conventions and are globally unique
- [ ] Environment names are consistent (dev, sit, prod - not stage/staging)
- [ ] All parameters have clear descriptions
- [ ] Examples provided for each parameter type
- [ ] Naming follows BBWS conventions

### Validation Criteria

- [ ] AWS account IDs verified and accurate
- [ ] Regions aligned with BBWS primary (af-south-1) and failover (eu-west-1)
- [ ] No inconsistencies between environment configurations
- [ ] All resource names follow naming conventions
- [ ] Terraform variables properly scoped
- [ ] OIDC role ARNs correct format and structure

---

## Execution Steps

### Step 1: Document Environment Specifications

**Action**: Create comprehensive environment matrix

**Environment Matrix Table**:

| Attribute | DEV | SIT | PROD |
|-----------|-----|-----|------|
| AWS Account ID | 536580886816 | 815856636111 | 093646564004 |
| Primary Region | af-south-1 | af-south-1 | af-south-1 |
| Failover Region | None | None | eu-west-1 |
| Environment Name (Code) | dev | sit | prod |
| Purpose | Development & Testing | Pre-Production Testing | Live Production |
| Data Type | Non-sensitive | Non-sensitive (realistic) | Real Customer Data |
| Access Level | Development Team | QA Team | Operations Team |
| Scale | Low (1-10 users) | Medium (100+ users) | High (1000+ users) |
| Availability SLA | 95% | 99% | 99.9% |
| Compliance | Development only | Testing only | PCI DSS, GDPR |
| Data Residency | Any | af-south-1 | af-south-1 (primary) |
| Backup Strategy | None (ephemeral) | Daily backups | Hourly backups + PITR |
| DR Enabled | No | No | Yes (multi-region) |
| Cost Focus | Minimal | Realistic | High availability |

**Deliverable Evidence**:
- Environment matrix table
- Account ID verification
- Purpose and characteristics documented

### Step 2: Document AWS Account Details

**Action**: Specify AWS account structure and configuration

**For Each Environment (DEV, SIT, PROD)**:

1. **Account Information**
   - Account ID
   - Account Alias (if configured)
   - Root account security settings
   - MFA enabled (yes/no)
   - Organization path (if in AWS Organizations)

2. **VPC Configuration**
   - VPC CIDR block
   - Availability zones used
   - Public/Private subnets
   - NAT Gateway configuration
   - VPN/Direct Connect (if applicable)

3. **IAM Configuration**
   - Root user access (disabled/enabled)
   - User access key rotation policy
   - Role-based access policies
   - Cross-account access roles (if needed)

4. **CloudFormation/Terraform Management**
   - CloudFormation StackSets enabled
   - Terraform backend account
   - State file encryption

**Deliverable Evidence**:
- AWS account details table
- VPC architecture diagram per environment
- IAM policy structure diagram
- Screenshot of AWS account settings

### Step 3: Document Regional Configuration

**Action**: Specify regions and failover strategy

**Primary Region: af-south-1 (Cape Town)**

| Attribute | Value | Rationale |
|-----------|-------|-----------|
| Region Code | af-south-1 | Primary BBWS region |
| Region Name | Africa (Cape Town) | Local data residency |
| Services Available | Lambda, DynamoDB, S3, SQS, SES, etc. | All required services |
| Latency from SA | < 20ms | Low latency for local users |
| Cost | Moderate | Standard AWS pricing |
| Availability | 3 AZs | High availability support |

**Failover Region: eu-west-1 (Dublin) [PROD ONLY]**

| Attribute | Value | Rationale |
|-----------|-------|-----------|
| Region Code | eu-west-1 | Secondary/DR region |
| Region Name | Europe (Dublin) | Geographically diverse |
| Services Available | All required services | Replication capability |
| Latency from SA | ~200ms | Acceptable for failover |
| Cost | Moderate | Standard AWS pricing |
| Active/Standby | Active (multi-site) | Continuous synchronization |

**Route 53 Health Checks**:
- Primary region health check (every 30s)
- Failover condition: Primary region unhealthy
- Failover time: ~30-60 seconds
- DNS TTL: 60 seconds

**Cross-Region Replication**:
- DynamoDB: Global Tables or replica tables
- S3: Cross-region replication (CRR)
- Update frequency: Real-time for DynamoDB, eventual for S3

**Deliverable Evidence**:
- Regional configuration table
- Route 53 failover diagram
- Replication flow diagram
- Health check configuration

### Step 4: Create Parameter Matrix

**Action**: Extract all environment-specific parameters

**DynamoDB Tables**:

| Resource | DEV | SIT | PROD |
|----------|-----|-----|------|
| Table Name | bbws-customer-portal-orders-dev | bbws-customer-portal-orders-sit | bbws-customer-portal-orders-prod |
| Billing Mode | PAY_PER_REQUEST | PAY_PER_REQUEST | PAY_PER_REQUEST |
| Region | af-south-1 | af-south-1 | af-south-1 (+ eu-west-1 replica) |
| PITR | Disabled (dev) | Enabled (7 days) | Enabled (35 days) |
| Backup Frequency | None | Daily | Hourly |

**SQS Queues**:

| Resource | DEV | SIT | PROD |
|----------|-----|-----|------|
| Main Queue | bbws-order-creation-dev | bbws-order-creation-sit | bbws-order-creation-prod |
| DLQ | bbws-order-creation-dlq-dev | bbws-order-creation-dlq-sit | bbws-order-creation-dlq-prod |
| Visibility Timeout | 60s | 60s | 60s |
| Message Retention | 4 days | 4 days | 4 days |
| Batch Size | 10 | 10 | 10 |

**S3 Buckets**:

| Resource | DEV | SIT | PROD |
|----------|-----|-----|------|
| Email Templates | bbws-email-templates-dev | bbws-email-templates-sit | bbws-email-templates-prod |
| Order Artifacts | bbws-orders-dev | bbws-orders-sit | bbws-orders-prod |
| Versioning | Disabled | Enabled | Enabled |
| Region | af-south-1 | af-south-1 | af-south-1 + Replication to eu-west-1 |
| Lifecycle | None | 30-day retention | 7-year retention (Glacier after 2 years) |

**Lambda Functions**:

| Handler | DEV | SIT | PROD |
|---------|-----|-----|------|
| create_order | bbws-order-lambda-create-order-dev | bbws-order-lambda-create-order-sit | bbws-order-lambda-create-order-prod |
| get_order | bbws-order-lambda-get-order-dev | bbws-order-lambda-get-order-sit | bbws-order-lambda-get-order-prod |
| list_orders | bbws-order-lambda-list-orders-dev | bbws-order-lambda-list-orders-sit | bbws-order-lambda-list-orders-prod |
| update_order | bbws-order-lambda-update-order-dev | bbws-order-lambda-update-order-sit | bbws-order-lambda-update-order-prod |
| OrderCreatorRecord | bbws-order-lambda-creator-record-dev | bbws-order-lambda-creator-record-sit | bbws-order-lambda-creator-record-prod |
| OrderPDFCreator | bbws-order-lambda-pdf-creator-dev | bbws-order-lambda-pdf-creator-sit | bbws-order-lambda-pdf-creator-prod |
| OrderInternalNotifier | bbws-order-lambda-internal-notifier-dev | bbws-order-lambda-internal-notifier-sit | bbws-order-lambda-internal-notifier-prod |
| CustomerNotifier | bbws-order-lambda-customer-notifier-dev | bbws-order-lambda-customer-notifier-sit | bbws-order-lambda-customer-notifier-prod |

**API Gateway**:

| Resource | DEV | SIT | PROD |
|----------|-----|-----|------|
| API Name | bbws-order-api-dev | bbws-order-api-sit | bbws-order-api-prod |
| Stage | dev | sit | prod |
| Base URL | https://api-dev.bbws... | https://api-sit.bbws... | https://api.bbws... |
| Throttling | 1000 req/s | 5000 req/s | 10000 req/s |

**Environment Variables** (Terraform .tfvars):

```hcl
# dev.tfvars
environment             = "dev"
aws_account_id          = "536580886816"
aws_region              = "af-south-1"
dynamodb_table_name     = "bbws-customer-portal-orders-dev"
sqs_queue_name          = "bbws-order-creation-dev"
s3_templates_bucket     = "bbws-email-templates-dev"
s3_orders_bucket        = "bbws-orders-dev"
lambda_memory           = 512
lambda_timeout          = 30
enable_cross_region_dr  = false
ses_sending_limit       = "1/sec"  # 1 email per second

# sit.tfvars
environment             = "sit"
aws_account_id          = "815856636111"
aws_region              = "af-south-1"
dynamodb_table_name     = "bbws-customer-portal-orders-sit"
sqs_queue_name          = "bbws-order-creation-sit"
s3_templates_bucket     = "bbws-email-templates-sit"
s3_orders_bucket        = "bbws-orders-sit"
lambda_memory           = 512
lambda_timeout          = 30
enable_cross_region_dr  = false
ses_sending_limit       = "10/sec"

# prod.tfvars
environment             = "prod"
aws_account_id          = "093646564004"
aws_region              = "af-south-1"
aws_failover_region     = "eu-west-1"
dynamodb_table_name     = "bbws-customer-portal-orders-prod"
dynamodb_replica_region = "eu-west-1"
sqs_queue_name          = "bbws-order-creation-prod"
s3_templates_bucket     = "bbws-email-templates-prod"
s3_orders_bucket        = "bbws-orders-prod"
lambda_memory           = 512
lambda_timeout          = 30
enable_cross_region_dr  = true
ses_sending_limit       = "50/sec"
```

**Deliverable Evidence**:
- Complete parameter matrix table
- Terraform .tfvars file templates for all 3 environments
- Parameter naming convention validation
- Default values specified

### Step 5: Define Promotion Workflow

**Action**: Document promotion from DEV → SIT → PROD

**Promotion Flow Diagram**:

```
┌─────────────────────────────────────────────────────────────┐
│                 PROMOTION WORKFLOW                           │
└─────────────────────────────────────────────────────────────┘

     DEV Branch              SIT Branch              PROD Branch
     (develop)              (release)               (main)
        │                      │                      │
        ├──────────────────────┤                      │
        │   DEV Testing        │                      │
        │   ✓ Unit Tests       │                      │
        │   ✓ Integration      │                      │
        │   ✓ Manual Testing   │                      │
        │                      │                      │
        └──→ [Approval Gate]───┤                      │
                 (Manual)      │                      │
                               ├──────────────────────┤
                               │   SIT Testing        │
                               │   ✓ Regression Tests │
                               │   ✓ Load Testing     │
                               │   ✓ UAT Testing      │
                               │   ✓ Security Scan    │
                               │                      │
                               └──→ [Approval Gate]───┤
                                    (Manual)          │
                                                      │
                                                   PROD Deploy
                                                  (read-only ops)
```

**Promotion Criteria**:

**DEV → SIT**:
- [ ] All unit tests pass (>80% coverage)
- [ ] All integration tests pass
- [ ] Manual testing in DEV complete
- [ ] Code review approved (2 approvals)
- [ ] No high/critical security issues
- [ ] Release notes prepared
- [ ] Manual approval from Tech Lead

**SIT → PROD**:
- [ ] All regression tests pass
- [ ] Load testing completed (capacity verified)
- [ ] UAT testing complete (business validation)
- [ ] Security scan cleared
- [ ] Performance baselines met
- [ ] DR procedures tested
- [ ] Manual approval from Product Owner & Ops Lead

**Approval Gates in GitHub Actions**:

```yaml
# In deploy-sit.yml
- name: Request Manual Approval for SIT
  uses: actions/github-script@v7
  with:
    script: |
      github.rest.issues.createComment({
        issue_number: context.issue.number,
        owner: context.repo.owner,
        repo: context.repo.repo,
        body: 'Ready for SIT deployment. Review and approve.'
      })
  # Manual approval required before next step

# In deploy-prod.yml
- name: Request Manual Approval for PROD
  uses: actions/github-script@v7
  with:
    script: |
      github.rest.issues.createComment({
        issue_number: context.issue.number,
        owner: context.repo.owner,
        repo: context.repo.repo,
        body: 'Ready for PROD deployment. Product Owner and Ops Lead approval required.'
      })
  # Manual approval required before deployment
```

**Rollback Procedure**:

```bash
# If PROD deployment fails:
1. Notify on-call team immediately
2. Assess severity
3. If critical: Failover to eu-west-1 via Route 53
4. If recoverable: Terraform destroy → reapply from last stable state
5. Validate health checks
6. Post-incident review
```

**Deliverable Evidence**:
- Promotion flow diagram
- Criteria checklist for each promotion stage
- Approval gate configuration
- Rollback procedures documented

### Step 6: Document Terraform Configuration Strategy

**Action**: Define Terraform state management and module organization

**Terraform File Organization**:

```
terraform/
├── modules/
│   ├── lambda/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── iam.tf
│   ├── dynamodb/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── sqs/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── s3/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── api_gateway/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── monitoring/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── dev/
│   ├── main.tf (root)
│   ├── variables.tf
│   ├── outputs.tf
│   ├── backend.tf
│   └── dev.tfvars
├── sit/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── backend.tf
│   └── sit.tfvars
└── prod/
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    ├── backend.tf
    └── prod.tfvars
```

**Backend Configuration Strategy**:

```hcl
# terraform/dev/backend.tf
terraform {
  backend "s3" {
    bucket         = "bbws-terraform-state-dev"
    key            = "order-lambda/terraform.tfstate"
    region         = "af-south-1"
    encrypt        = true
    dynamodb_table = "terraform-locks-dev"
  }
}

# terraform/sit/backend.tf
terraform {
  backend "s3" {
    bucket         = "bbws-terraform-state-sit"
    key            = "order-lambda/terraform.tfstate"
    region         = "af-south-1"
    encrypt        = true
    dynamodb_table = "terraform-locks-sit"
  }
}

# terraform/prod/backend.tf
terraform {
  backend "s3" {
    bucket         = "bbws-terraform-state-prod"
    key            = "order-lambda/terraform.tfstate"
    region         = "af-south-1"
    encrypt        = true
    dynamodb_table = "terraform-locks-prod"
  }
}
```

**State File Encryption**:
- S3 bucket versioning: Enabled (all environments)
- Server-side encryption: SSE-S3 or SSE-KMS
- Block public access: Yes
- Access logging: Enabled
- MFA delete: Enabled (PROD)

**Locking Mechanism**:
- DynamoDB table per environment for state locking
- TTL: No expiration (manual unlock only)
- Read capacity: On-demand
- Write capacity: On-demand

**Deliverable Evidence**:
- Terraform file structure diagram
- Backend configuration templates
- Module organization documented
- State management strategy

### Step 7: Document CI/CD Pipeline Configuration

**Action**: Specify GitHub Actions environment-specific configuration

**GitHub Actions Environments** (GitHub Settings):

```yaml
# Environment: dev
- Name: dev
  Deployment branches: [develop]
  Protection rules: None (auto-deploy)

# Environment: sit
- Name: sit
  Deployment branches: [release]
  Protection rules:
    - Require specific reviewers: 1 (QA Lead)
    - Require status checks to pass

# Environment: prod
- Name: prod
  Deployment branches: [main]
  Protection rules:
    - Require specific reviewers: 2 (Ops Lead + Tech Lead)
    - Require status checks to pass
    - Restrict deployments: Scheduled Windows Only
```

**Environment Variables in GitHub**:

```yaml
# Repository → Settings → Environments → dev
DEV_AWS_ACCOUNT_ID: 536580886816
DEV_AWS_REGION: af-south-1
DEV_OIDC_ROLE_ARN: arn:aws:iam::536580886816:role/github-2-bbws-order-lambda-dev
DEV_ENVIRONMENT: dev

# Repository → Settings → Environments → sit
SIT_AWS_ACCOUNT_ID: 815856636111
SIT_AWS_REGION: af-south-1
SIT_OIDC_ROLE_ARN: arn:aws:iam::815856636111:role/github-2-bbws-order-lambda-sit
SIT_ENVIRONMENT: sit

# Repository → Settings → Environments → prod
PROD_AWS_ACCOUNT_ID: 093646564004
PROD_AWS_REGION: af-south-1
PROD_AWS_FAILOVER_REGION: eu-west-1
PROD_OIDC_ROLE_ARN: arn:aws:iam::093646564004:role/github-2-bbws-order-lambda-prod
PROD_ENVIRONMENT: prod
```

**Workflow Example** (deploy-dev.yml):

```yaml
name: Deploy to DEV

on:
  push:
    branches: [develop]
  workflow_dispatch:

env:
  AWS_REGION: ${{ secrets.DEV_AWS_REGION }}

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run tests
        run: |
          python -m pytest tests/ -v --cov

  deploy:
    runs-on: ubuntu-latest
    needs: test
    environment: dev
    permissions:
      id-token: write
      contents: read

    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.DEV_OIDC_ROLE_ARN }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Terraform Init
        run: |
          cd terraform/dev
          terraform init -upgrade

      - name: Terraform Plan
        run: |
          cd terraform/dev
          terraform plan -out=tfplan

      - name: Terraform Apply
        run: |
          cd terraform/dev
          terraform apply -auto-approve tfplan

      - name: Post-deployment tests
        run: |
          python -m pytest tests/integration/ -v -k "dev"
```

**Deliverable Evidence**:
- GitHub Actions environment configuration
- Environment variables template
- Workflow file examples
- Approval gate configuration

### Step 8: Document Disaster Recovery Strategy

**Action**: Define multi-region DR for PROD

**DR Architecture** (PROD Only):

```
┌─────────────────────────────────────────────────────────────┐
│              Multi-Site Active/Active DR                     │
└─────────────────────────────────────────────────────────────┘

    af-south-1 (Cape Town)              eu-west-1 (Dublin)
    PRIMARY REGION                      DR REGION
    ┌──────────────────┐               ┌──────────────────┐
    │ ✓ Active Serving │               │ ✓ Active Serving │
    │ DynamoDB Table   │◄──Replicate──►│ DynamoDB Replica │
    │ OrdersByDateIdx  │               │ OrdersByDateIdx  │
    │ OrderByIdIdx     │               │ OrderByIdIdx     │
    │                  │               │                  │
    │ S3 Orders        │◄──CRR────────►│ S3 Orders        │
    │ S3 Templates     │               │ S3 Templates     │
    │                  │               │                  │
    │ Lambda Functions │               │ Lambda Functions │
    │ SQS Queues       │               │ SQS Queues       │
    │                  │               │                  │
    └──────────────────┘               └──────────────────┘
          │                                    │
          └────────────────┬────────────────────┘
                           │
                    Route 53 Health Check
                    (Endpoint Evaluation)

    If af-south-1 fails (health check fails for 30s):
    → Route 53 automatically switches DNS to eu-west-1
    → API traffic redirected to Dublin region
    → DynamoDB replica becomes primary
    → S3 replication continues (eventual consistency)
    → RTO: ~1 minute (Route 53 failover + DNS propagation)
    → RPO: ~5 minutes (replication latency)
```

**DynamoDB Replication**:

```hcl
# Main table in af-south-1
resource "aws_dynamodb_table" "orders" {
  name           = "bbws-customer-portal-orders-prod"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "PK"
  range_key      = "SK"
  region         = "af-south-1"

  stream_specification {
    stream_enabled   = true
    stream_view_type = "NEW_AND_OLD_IMAGES"
  }

  replica {
    region_name = "eu-west-1"
  }

  point_in_time_recovery {
    enabled = true
  }
}

# Backup configuration
resource "aws_backup_vault" "dynamodb" {
  name = "bbws-order-backup-prod"
}

resource "aws_backup_plan" "dynamodb" {
  name = "bbws-order-daily-backup-prod"

  rule {
    rule_name         = "hourly_snapshots"
    target_backup_vault_name = aws_backup_vault.dynamodb.name
    schedule          = "cron(0 * * * ? *)"  # Every hour
    lifecycle {
      cold_storage_after = 30
      delete_after       = 365  # 1 year retention
    }
  }
}
```

**S3 Cross-Region Replication**:

```hcl
# Replication rule for order artifacts
resource "aws_s3_bucket_replication_configuration" "orders" {
  role   = aws_iam_role.s3_replication.arn
  bucket = aws_s3_bucket.orders_prod.id
  depends_on = [aws_s3_bucket_versioning.orders_prod]

  rule {
    id       = "replicate-orders"
    status   = "Enabled"
    priority = 1

    filter {}

    destination {
      bucket       = aws_s3_bucket.orders_prod_replica.arn
      storage_class = "STANDARD"
      replication_time {
        status = "Enabled"
        time {
          minutes = 15
        }
      }
    }
  }
}
```

**Route 53 Failover**:

```hcl
resource "aws_route53_zone" "main" {
  name = "bbws.io"
}

resource "aws_route53_record" "api_primary" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "api.bbws.io"
  type    = "A"

  set_identifier       = "primary"
  failover_routing_policy {
    type = "PRIMARY"
  }

  alias {
    name                   = aws_api_gateway_stage.prod_primary.invoke_url
    zone_id                = aws_api_gateway_stage.prod_primary.zone_id
    evaluate_target_health = true
  }

  health_check_id = aws_route53_health_check.primary.id
}

resource "aws_route53_record" "api_secondary" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "api.bbws.io"
  type    = "A"

  set_identifier       = "secondary"
  failover_routing_policy {
    type = "SECONDARY"
  }

  alias {
    name                   = aws_api_gateway_stage.prod_secondary.invoke_url
    zone_id                = aws_api_gateway_stage.prod_secondary.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_health_check" "primary" {
  fqdn              = "api-primary.bbws.io"
  port              = 443
  type              = "HTTPS"
  failure_threshold = 2
  request_interval  = 30

  alarm_identifier {
    name           = aws_cloudwatch_metric_alarm.api_health.alarm_name
    region         = "us-east-1"
  }
}
```

**Failover Testing Procedure**:

```bash
# Monthly failover test
1. Create test Lambda function in PROD
2. Manually failover Route 53 record to eu-west-1
3. Verify API calls succeed in eu-west-1
4. Verify DynamoDB replication consistency
5. Monitor CloudWatch metrics
6. Failback to primary region
7. Document test results and issues found
```

**RTO/RPO Validation**:

| Metric | Target | How Achieved |
|--------|--------|--------------|
| RTO | < 1 hour | Route 53 failover (30-60s) + retest (remaining time) |
| RPO | < 5 minutes | DynamoDB streams + hourly backup snapshots |

**Deliverable Evidence**:
- DR architecture diagram
- Terraform replication configuration
- Failover procedure documentation
- Failover test schedule and results

### Step 9: Document Environment-Specific Configurations

**Action**: Define configurations that vary by environment

**Lambda Configuration**:

| Setting | DEV | SIT | PROD |
|---------|-----|-----|------|
| Memory | 512 MB | 512 MB | 512 MB |
| Timeout | 30 sec | 30 sec | 30 sec |
| Concurrency (Reserved) | None | 10 | 50 |
| Concurrency (Provisioned) | None | None | 20 (OrderCreatorRecord) |
| Ephemeral Storage | 512 MB | 512 MB | 512 MB |
| Log Retention | 7 days | 30 days | 90 days |
| X-Ray Tracing | Disabled | Enabled | Enabled |

**SES Configuration**:

| Setting | DEV | SIT | PROD |
|---------|-----|-----|------|
| Sending Quota | 1 email/sec | 10 emails/sec | 50 emails/sec |
| From Addresses | test@kimmyai.io | noreply@kimmyai.io | noreply@kimmyai.io |
| Domain Verification | Not required | kimmyai.io | kimmyai.io |
| Bounce Handling | Disabled | SNS notifications | SNS + automated suppression |
| Complaint Handling | Disabled | SNS notifications | SNS + automated suppression |

**CloudWatch Configuration**:

| Setting | DEV | SIT | PROD |
|---------|-----|-----|------|
| Log Retention | 7 days | 30 days | 90 days |
| Detailed Metrics | No | Yes | Yes |
| Dashboard | No | Yes | Yes |
| Alarms Enabled | No | Yes | Yes |
| Alarm SNS Topic | None | bbws-alerts-sit | bbws-alerts-prod |

**Cost Optimization**:

| Strategy | DEV | SIT | PROD |
|----------|-----|-----|------|
| Spot Instances | Yes (if applicable) | No | No |
| Reserved Capacity | No | No | Yes (Lambda) |
| Auto-scaling | Conservative | Moderate | Aggressive |
| Data Transfer | No optimization | Standard | Optimized (VPC endpoints) |
| Backup Frequency | None | Daily | Hourly |

**Deliverable Evidence**:
- Environment-specific configuration table
- Lambda configuration by environment
- SES quota comparison
- Cost optimization matrix

### Step 10: Compile Environment Analysis Output

**Action**: Create final comprehensive environment analysis document

---

## Output Format

### Output File: `worker-4-environment-analysis/output.md`

```markdown
# Worker 4 Output: Environment Analysis

**Date Completed**: YYYY-MM-DD
**Worker**: [Your Name/Identifier]
**Status**: Complete / In Progress / Blocked

## Executive Summary

[Summary of environment analysis and deployment strategy]

## 1. Environment Matrix

[Complete table with DEV, SIT, PROD specifications]

## 2. AWS Account Details

### Development Account (DEV)
[Account details and configuration]

### System Integration Testing Account (SIT)
[Account details and configuration]

### Production Account (PROD)
[Account details and configuration]

## 3. Regional Configuration

### Primary Region: af-south-1 (Cape Town)
[Region specifications]

### Failover Region: eu-west-1 (Dublin) [PROD Only]
[Failover region specifications]

### Route 53 Health Check Configuration
[Health check details]

## 4. Parameter Matrix

### DynamoDB Tables
[Table names by environment]

### SQS Queues
[Queue names by environment]

### S3 Buckets
[Bucket names by environment]

### Lambda Functions
[Function names by environment]

### Terraform Variables (.tfvars)
[Variable files for each environment]

## 5. Promotion Workflow

### Promotion Flow Diagram
[Diagram or ASCII art]

### DEV → SIT Criteria
[Checklist]

### SIT → PROD Criteria
[Checklist]

### Rollback Procedure
[Steps for rollback]

## 6. Terraform Configuration Strategy

### File Organization
[Directory structure]

### Backend Configuration
[S3 backend setup]

### State File Management
[State file encryption and locking]

## 7. CI/CD Pipeline Configuration

### GitHub Actions Environments
[Environment setup]

### Environment Variables
[GitHub secrets configuration]

### Workflow Configuration
[Deploy workflow templates]

## 8. Disaster Recovery Strategy

### Multi-Region Architecture
[Architecture diagram]

### DynamoDB Replication
[Replication configuration]

### S3 Cross-Region Replication
[CRR configuration]

### Route 53 Failover
[Failover configuration]

### RTO/RPO Targets
[Recovery targets and how achieved]

## 9. Environment-Specific Configurations

### Lambda Configuration
[By environment table]

### SES Configuration
[Email service settings]

### CloudWatch Configuration
[Logging and monitoring]

### Cost Optimization
[Strategies by environment]

## 10. Access Control and Security

[IAM roles and policies per environment]

## Issues/Blockers

[Any environment-related issues]

## Appendix: Quick Reference

[One-page environment reference]
```

---

## References

- **BBWS Documentation**: `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/CLAUDE.md`
- **LLD Document**: `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/2.1.8_LLD_Order_Lambda.md`
- **AWS Multi-Region Guide**: https://docs.aws.amazon.com/whitepapers/latest/disaster-recovery-aws/
- **Route 53 Failover**: https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/routing-policy-failover.html

---

**Document Version**: 1.0
**Created**: 2025-12-30
