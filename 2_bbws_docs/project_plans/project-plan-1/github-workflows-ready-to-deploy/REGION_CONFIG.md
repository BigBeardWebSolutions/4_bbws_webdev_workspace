# Region Configuration Guide

This document clarifies the AWS region configuration for all environments.

---

## Environment Region Mapping

| Environment | Primary Region | DR Region | AWS Account | Purpose |
|-------------|----------------|-----------|-------------|---------|
| **DEV** | eu-west-1 (Ireland) | None | 536580886816 | Development and testing |
| **SIT** | eu-west-1 (Ireland) | None | 815856636111 | System Integration Testing |
| **PROD** | af-south-1 (Cape Town) | eu-west-1 (Ireland) | 093646564004 | Production with DR |

---

## Regional Architecture

### DEV Environment
```
┌─────────────────────────────────────┐
│   DEV - eu-west-1 (Ireland)         │
├─────────────────────────────────────┤
│                                     │
│  DynamoDB Tables                    │
│  ├─ tenants                         │
│  ├─ products                        │
│  └─ campaigns                       │
│                                     │
│  S3 Buckets                         │
│  └─ bbws-templates-dev              │
│                                     │
│  Terraform State                    │
│  ├─ bbws-terraform-state-dev        │
│  └─ terraform-state-lock-dev        │
│                                     │
└─────────────────────────────────────┘
```

### SIT Environment
```
┌─────────────────────────────────────┐
│   SIT - eu-west-1 (Ireland)         │
├─────────────────────────────────────┤
│                                     │
│  DynamoDB Tables                    │
│  ├─ tenants                         │
│  ├─ products                        │
│  └─ campaigns                       │
│                                     │
│  S3 Buckets                         │
│  └─ bbws-templates-sit              │
│                                     │
│  Terraform State                    │
│  ├─ bbws-terraform-state-sit        │
│  └─ terraform-state-lock-sit        │
│                                     │
└─────────────────────────────────────┘
```

### PROD Environment (Multi-Region)
```
┌─────────────────────────────────────┐  ┌─────────────────────────────────────┐
│  PRIMARY - af-south-1 (Cape Town)   │  │  DR - eu-west-1 (Ireland)           │
├─────────────────────────────────────┤  ├─────────────────────────────────────┤
│                                     │  │                                     │
│  DynamoDB Tables (Global Tables)    │◄─┤  DynamoDB Replicas                  │
│  ├─ tenants                         │  │  ├─ tenants (replica)               │
│  ├─ products                        │  │  ├─ products (replica)              │
│  └─ campaigns                       │  │  └─ campaigns (replica)             │
│                                     │  │                                     │
│  S3 Buckets                         │  │  S3 Buckets (Replicated)            │
│  └─ bbws-templates-prod             │──┤  └─ bbws-templates-prod-dr          │
│                                     │  │                                     │
│  Terraform State                    │  │  Terraform State (Replicated)       │
│  ├─ bbws-terraform-state-prod       │──┤  └─ bbws-terraform-state-prod-dr    │
│  └─ terraform-state-lock-prod       │  │                                     │
│                                     │  │                                     │
│  Route 53 Health Checks             │  │  Standby (Active/Active)            │
│  └─ Primary endpoint                │  │  └─ Failover endpoint               │
│                                     │  │                                     │
└─────────────────────────────────────┘  └─────────────────────────────────────┘
         PRIMARY (ACTIVE)                          DR (STANDBY)
              │                                          ▲
              │                                          │
              └────────── FAILOVER (< 15 min) ──────────┘
```

---

## Region Selection Rationale

### DEV & SIT: eu-west-1 (Ireland)

**Reasons**:
1. **Cost Optimization**: Lower AWS costs compared to af-south-1
2. **Service Availability**: Full service catalog availability
3. **Developer Proximity**: Closer to global developer teams
4. **No DR Required**: Non-production environments don't need DR
5. **Faster Deployment**: No cross-region replication overhead

### PROD Primary: af-south-1 (Cape Town)

**Reasons**:
1. **Data Sovereignty**: South African data residency requirements
2. **Latency**: Lowest latency for South African customers
3. **Compliance**: POPIA compliance requirements
4. **Business Requirement**: Primary market is South Africa

### PROD DR: eu-west-1 (Ireland)

**Reasons**:
1. **Geographic Diversity**: Physically separate from primary region
2. **High Availability**: AWS Tier 1 region with 99.99% SLA
3. **Service Parity**: All required services available
4. **Proven Track Record**: Stable region with minimal outages
5. **Cross-Region Replication**: Supports DynamoDB Global Tables and S3 CRR

---

## Workflow Configuration by Environment

### DEV Workflow (.github/workflows/deploy-dev.yml)

```yaml
env:
  AWS_REGION: eu-west-1        # Ireland
  AWS_ACCOUNT_ID: '536580886816'
  ENVIRONMENT: dev
```

### SIT Workflow (.github/workflows/deploy-sit.yml)

```yaml
env:
  AWS_REGION: eu-west-1        # Ireland
  AWS_ACCOUNT_ID: '815856636111'
  ENVIRONMENT: sit
```

### PROD Workflow (.github/workflows/deploy-prod.yml)

```yaml
env:
  PRIMARY_REGION: af-south-1   # Cape Town
  DR_REGION: eu-west-1         # Ireland
  AWS_ACCOUNT_ID: '093646564004'
  ENVIRONMENT: prod
```

---

## Terraform Backend Configuration

### DEV Environment

```hcl
terraform {
  backend "s3" {
    bucket         = "bbws-terraform-state-dev"
    key            = "2_1_bbws_dynamodb_schemas/terraform.tfstate"
    region         = "eu-west-1"  # Ireland
    dynamodb_table = "terraform-state-lock-dev"
    encrypt        = true
  }
}
```

### SIT Environment

```hcl
terraform {
  backend "s3" {
    bucket         = "bbws-terraform-state-sit"
    key            = "2_1_bbws_dynamodb_schemas/terraform.tfstate"
    region         = "eu-west-1"  # Ireland
    dynamodb_table = "terraform-state-lock-sit"
    encrypt        = true
  }
}
```

### PROD Environment

```hcl
terraform {
  backend "s3" {
    bucket         = "bbws-terraform-state-prod"
    key            = "2_1_bbws_dynamodb_schemas/terraform.tfstate"
    region         = "af-south-1"  # Cape Town (Primary)
    dynamodb_table = "terraform-state-lock-prod"
    encrypt        = true
  }
}
```

---

## Validation Script Configuration

### DEV (validate_dynamodb_dev.py)

```python
REGION = 'eu-west-1'
ENVIRONMENT = 'dev'
AWS_ACCOUNT_ID = '536580886816'
```

### SIT (validate_dynamodb_sit.py)

```python
REGION = 'eu-west-1'
ENVIRONMENT = 'sit'
AWS_ACCOUNT_ID = '815856636111'
```

### PROD (validate_dynamodb_prod.py)

```python
PRIMARY_REGION = 'af-south-1'
DR_REGION = 'eu-west-1'
ENVIRONMENT = 'prod'
AWS_ACCOUNT_ID = '093646564004'
```

---

## AWS Console Links by Environment

### DEV (eu-west-1)

- **DynamoDB**: https://console.aws.amazon.com/dynamodbv2/home?region=eu-west-1#tables
- **S3**: https://console.aws.amazon.com/s3/home?region=eu-west-1
- **CloudWatch**: https://console.aws.amazon.com/cloudwatch/home?region=eu-west-1

### SIT (eu-west-1)

- **DynamoDB**: https://console.aws.amazon.com/dynamodbv2/home?region=eu-west-1#tables
- **S3**: https://console.aws.amazon.com/s3/home?region=eu-west-1
- **CloudWatch**: https://console.aws.amazon.com/cloudwatch/home?region=eu-west-1

### PROD Primary (af-south-1)

- **DynamoDB**: https://console.aws.amazon.com/dynamodbv2/home?region=af-south-1#tables
- **S3**: https://console.aws.amazon.com/s3/home?region=af-south-1
- **CloudWatch**: https://console.aws.amazon.com/cloudwatch/home?region=af-south-1

### PROD DR (eu-west-1)

- **DynamoDB**: https://console.aws.amazon.com/dynamodbv2/home?region=eu-west-1#tables
- **S3**: https://console.aws.amazon.com/s3/home?region=eu-west-1
- **CloudWatch**: https://console.aws.amazon.com/cloudwatch/home?region=eu-west-1

---

## CLI Commands by Environment

### DEV

```bash
# List DynamoDB tables
aws dynamodb list-tables --region eu-west-1 --profile dev

# List S3 buckets (S3 is global, but filter by region)
aws s3 ls --profile dev | grep bbws-templates-dev

# Describe table
aws dynamodb describe-table --table-name tenants --region eu-west-1 --profile dev
```

### SIT

```bash
# List DynamoDB tables
aws dynamodb list-tables --region eu-west-1 --profile sit

# List S3 buckets
aws s3 ls --profile sit | grep bbws-templates-sit

# Describe table
aws dynamodb describe-table --table-name tenants --region eu-west-1 --profile sit
```

### PROD (Primary Region)

```bash
# List DynamoDB tables (primary)
aws dynamodb list-tables --region af-south-1 --profile prod

# List S3 buckets
aws s3 ls --profile prod | grep bbws-templates-prod

# Describe global table
aws dynamodb describe-table --table-name tenants --region af-south-1 --profile prod
```

### PROD (DR Region)

```bash
# List DynamoDB replicas
aws dynamodb list-tables --region eu-west-1 --profile prod

# Describe replica
aws dynamodb describe-table --table-name tenants --region eu-west-1 --profile prod
```

---

## Disaster Recovery Configuration (PROD Only)

### DynamoDB Global Tables

```hcl
resource "aws_dynamodb_table" "tenants_prod" {
  name         = "tenants"
  billing_mode = "PAY_PER_REQUEST"

  # Primary region: af-south-1
  hash_key  = "PK"
  range_key = "SK"

  # Enable streams for replication
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  # DR replica in eu-west-1
  replica {
    region_name = "eu-west-1"
  }
}
```

### S3 Cross-Region Replication

```hcl
resource "aws_s3_bucket_replication_configuration" "templates_prod" {
  bucket = aws_s3_bucket.templates_prod.id
  role   = aws_iam_role.replication.arn

  rule {
    id     = "replicate-to-dr"
    status = "Enabled"

    destination {
      bucket        = "arn:aws:s3:::bbws-templates-prod-dr"
      storage_class = "STANDARD"

      # DR bucket is in eu-west-1
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

---

## Important Notes

1. **DEV and SIT use the same region** (eu-west-1) but different AWS accounts
2. **PROD is multi-region** with primary in af-south-1 and DR in eu-west-1
3. **No cross-region replication for DEV/SIT** - cost optimization
4. **PROD replication is bi-directional** - active/active DR strategy
5. **Route 53 health checks** monitor primary region and trigger failover
6. **RTO for PROD**: < 15 minutes (DNS failover time)
7. **RPO for PROD**: < 1 second (replication lag is milliseconds)

---

## Checklist for New Deployments

### Before Deploying to DEV/SIT

- [ ] Verify AWS account ID matches environment
- [ ] Confirm region is eu-west-1
- [ ] No cross-region replication configured
- [ ] Terraform backend points to eu-west-1

### Before Deploying to PROD

- [ ] Verify AWS account ID is 093646564004
- [ ] Primary region is af-south-1
- [ ] DR region is eu-west-1
- [ ] DynamoDB Global Tables configured
- [ ] S3 cross-region replication enabled
- [ ] Route 53 health checks configured
- [ ] Both regions have PITR enabled
- [ ] Terraform state backend in af-south-1 (primary)

---

**Last Updated**: 2025-12-25
**Version**: 1.0
**Status**: ✅ Verified and Corrected
