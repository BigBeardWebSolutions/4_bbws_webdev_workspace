# Worker 4 Output: Environment Analysis

**Date Completed**: 2025-12-30
**Worker**: Worker 4 - Environment Analysis
**Stage**: Stage 1 - Repository Requirements
**LLD Reference**: 2.1.8_LLD_Order_Lambda.md
**Status**: Complete

---

## Executive Summary

This document provides comprehensive environment analysis for the BBWS Order Lambda microservice deployment across DEV, SIT, and PROD environments. The analysis covers AWS account configuration, regional deployment strategy, multi-environment parameter management, disaster recovery (DR) configuration, CI/CD pipeline setup, and access control policies.

**Key Highlights:**
- **Three isolated AWS accounts**: DEV (536580886816), SIT (815856636111), PROD (093646564004)
- **Primary regions**: eu-west-1 (Ireland) for DEV/SIT, af-south-1 (Cape Town) for PROD
- **DR region**: eu-west-1 (Dublin) for PROD only with multi-site active/active pattern
- **Promotion workflow**: DEV → SIT → PROD with manual approval gates
- **Terraform state management**: Separate S3 backend and DynamoDB locking per environment
- **Parameterization**: All resource names environment-specific (no hardcoding)
- **RTO/RPO targets**: < 1 hour RTO, < 5 minutes RPO for PROD

---

## 1. Environment Matrix

### 1.1 Complete Environment Overview

| Attribute | DEV | SIT | PROD |
|-----------|-----|-----|------|
| **AWS Account ID** | 536580886816 | 815856636111 | 093646564004 |
| **Primary Region** | eu-west-1 (Ireland) | eu-west-1 (Ireland) | af-south-1 (Cape Town) |
| **Failover Region** | None | None | eu-west-1 (Dublin) |
| **Environment Code** | dev | sit | prod |
| **Purpose** | Development & Rapid Iteration | Pre-production Testing & Validation | Live Production |
| **Data Classification** | Non-sensitive test data | Non-sensitive test data (realistic volume) | Real customer data (PCI DSS, GDPR) |
| **Access Level** | Development Team | QA Team + Tech Lead | Operations Team (read-only for Claude) |
| **Expected Scale** | Low (1-10 concurrent users) | Medium (50-100 concurrent users) | High (1000+ concurrent users) |
| **Availability SLA** | 95% (best effort) | 99% (pre-production) | 99.9% (production) |
| **Compliance Requirements** | Development only | Testing validation | PCI DSS, GDPR, data residency (South Africa) |
| **Data Residency** | eu-west-1 (Ireland) | eu-west-1 (Ireland) | af-south-1 (primary) + eu-west-1 (DR) |
| **Backup Strategy** | Daily (7-day retention) | Daily (14-day retention) | Hourly + PITR (90-day retention) |
| **DR Enabled** | No | No | Yes (multi-region active/active) |
| **Cost Focus** | Minimal (rapid iteration) | Realistic (pre-production) | High availability (production grade) |
| **Deployment Type** | Auto-deploy after approval | Manual promotion from DEV | Manual promotion from SIT |
| **Approval Required** | 1 (Lead Dev) | 2 (Tech Lead + QA Lead) | 3 (Tech Lead + Product Owner + DevOps) |

### 1.2 Environment Characteristics

#### Development (DEV)
- **Purpose**: Rapid development iteration and feature testing
- **Data**: Synthetic test data, safe to delete/recreate
- **Deployment**: Auto-deploy after successful validation and approval
- **Access**: Full access for development team
- **Cost Optimization**: Minimal resources, ephemeral infrastructure
- **Testing Focus**: Unit tests, basic integration tests

#### System Integration Testing (SIT)
- **Purpose**: Pre-production validation with realistic data volumes
- **Data**: Non-sensitive but realistic test data
- **Deployment**: Manual promotion from DEV after successful testing
- **Access**: QA team and tech leads
- **Testing Focus**: Integration tests, regression tests, UAT, load testing
- **Cost Optimization**: Balanced between realism and cost

#### Production (PROD)
- **Purpose**: Live customer-facing environment
- **Data**: Real customer data (PCI compliant, GDPR compliant)
- **Deployment**: Manual promotion from SIT after comprehensive validation
- **Access**: Operations team (read-only for Claude Code, no automated changes)
- **Testing Focus**: Smoke tests, health checks, monitoring
- **Cost Optimization**: High availability, performance, and resilience prioritized
- **DR**: Multi-region active/active with hourly backups and cross-region replication

---

## 2. AWS Account Details

### 2.1 Development Account (DEV)

| Attribute | Value | Notes |
|-----------|-------|-------|
| **Account ID** | 536580886816 | Isolated development account |
| **Account Alias** | bbws-cpp-dev | Human-readable identifier |
| **Region** | eu-west-1 (Ireland) | Primary DEV region |
| **VPC CIDR** | 10.0.0.0/16 | Development VPC |
| **Availability Zones** | eu-west-1a, eu-west-1b, eu-west-1c | 3 AZs for development |
| **Public Subnets** | 10.0.1.0/24, 10.0.2.0/24, 10.0.3.0/24 | Internet-facing resources |
| **Private Subnets** | 10.0.10.0/24, 10.0.11.0/24, 10.0.12.0/24 | Lambda functions, internal services |
| **NAT Gateway** | Single NAT in 1 AZ | Cost optimization |
| **Root Account MFA** | Enabled | Security requirement |
| **IAM Role-Based Access** | Yes (GitHub OIDC) | Secure CI/CD integration |
| **Cost Budget** | $500/month | With 80% alert threshold |

**VPC Configuration:**
```
VPC: bbws-cpp-dev-vpc (10.0.0.0/16)
├── Public Subnets (Internet Gateway)
│   ├── bbws-cpp-dev-public-1a (10.0.1.0/24)
│   ├── bbws-cpp-dev-public-1b (10.0.2.0/24)
│   └── bbws-cpp-dev-public-1c (10.0.3.0/24)
├── Private Subnets (NAT Gateway)
│   ├── bbws-cpp-dev-private-1a (10.0.10.0/24)
│   ├── bbws-cpp-dev-private-1b (10.0.11.0/24)
│   └── bbws-cpp-dev-private-1c (10.0.12.0/24)
└── NAT Gateway (bbws-cpp-dev-nat-1a)
```

### 2.2 System Integration Testing Account (SIT)

| Attribute | Value | Notes |
|-----------|-------|-------|
| **Account ID** | 815856636111 | Isolated pre-production account |
| **Account Alias** | bbws-cpp-sit | Human-readable identifier |
| **Region** | eu-west-1 (Ireland) | Primary SIT region |
| **VPC CIDR** | 10.1.0.0/16 | SIT VPC (different from DEV) |
| **Availability Zones** | eu-west-1a, eu-west-1b, eu-west-1c | 3 AZs for high availability |
| **Public Subnets** | 10.1.1.0/24, 10.1.2.0/24, 10.1.3.0/24 | Internet-facing resources |
| **Private Subnets** | 10.1.10.0/24, 10.1.11.0/24, 10.1.12.0/24 | Lambda functions, internal services |
| **NAT Gateway** | 2 NATs in 2 AZs | High availability for testing |
| **Root Account MFA** | Enabled | Security requirement |
| **IAM Role-Based Access** | Yes (GitHub OIDC) | Secure CI/CD integration |
| **Cost Budget** | $1,000/month | With 80% alert threshold |

**VPC Configuration:**
```
VPC: bbws-cpp-sit-vpc (10.1.0.0/16)
├── Public Subnets (Internet Gateway)
│   ├── bbws-cpp-sit-public-1a (10.1.1.0/24)
│   ├── bbws-cpp-sit-public-1b (10.1.2.0/24)
│   └── bbws-cpp-sit-public-1c (10.1.3.0/24)
├── Private Subnets (NAT Gateways)
│   ├── bbws-cpp-sit-private-1a (10.1.10.0/24)
│   ├── bbws-cpp-sit-private-1b (10.1.11.0/24)
│   ├── bbws-cpp-sit-private-1c (10.1.12.0/24)
└── NAT Gateways
    ├── bbws-cpp-sit-nat-1a
    └── bbws-cpp-sit-nat-1b
```

### 2.3 Production Account (PROD)

| Attribute | Value | Notes |
|-----------|-------|-------|
| **Account ID** | 093646564004 | Isolated production account |
| **Account Alias** | bbws-cpp-prod | Human-readable identifier |
| **Primary Region** | af-south-1 (Cape Town) | Primary BBWS region |
| **Failover Region** | eu-west-1 (Dublin) | DR region for multi-site active/active |
| **VPC CIDR (Primary)** | 10.2.0.0/16 | Production VPC (af-south-1) |
| **VPC CIDR (DR)** | 10.3.0.0/16 | DR VPC (eu-west-1) |
| **Availability Zones (Primary)** | af-south-1a, af-south-1b, af-south-1c | 3 AZs for production |
| **Availability Zones (DR)** | eu-west-1a, eu-west-1b, eu-west-1c | 3 AZs for DR |
| **Public Subnets (Primary)** | 10.2.1.0/24, 10.2.2.0/24, 10.2.3.0/24 | Internet-facing resources |
| **Private Subnets (Primary)** | 10.2.10.0/24, 10.2.11.0/24, 10.2.12.0/24 | Lambda functions, internal services |
| **Public Subnets (DR)** | 10.3.1.0/24, 10.3.2.0/24, 10.3.3.0/24 | DR internet-facing resources |
| **Private Subnets (DR)** | 10.3.10.0/24, 10.3.11.0/24, 10.3.12.0/24 | DR Lambda functions, services |
| **NAT Gateway (Primary)** | 3 NATs in 3 AZs | Maximum availability |
| **NAT Gateway (DR)** | 3 NATs in 3 AZs | Maximum availability |
| **Root Account MFA** | Enabled | Security requirement |
| **IAM Role-Based Access** | Yes (GitHub OIDC) | Secure CI/CD integration |
| **Cost Budget** | $5,000/month | With 80% alert threshold |
| **Deletion Protection** | Enabled | All critical resources |

**VPC Configuration (Primary - af-south-1):**
```
VPC: bbws-prod-vpc-primary (10.2.0.0/16)
├── Public Subnets (Internet Gateway)
│   ├── bbws-prod-public-1a (10.2.1.0/24)
│   ├── bbws-prod-public-1b (10.2.2.0/24)
│   └── bbws-prod-public-1c (10.2.3.0/24)
├── Private Subnets (NAT Gateways)
│   ├── bbws-prod-private-1a (10.2.10.0/24)
│   ├── bbws-prod-private-1b (10.2.11.0/24)
│   └── bbws-prod-private-1c (10.2.12.0/24)
└── NAT Gateways
    ├── bbws-prod-nat-1a
    ├── bbws-prod-nat-1b
    └── bbws-prod-nat-1c
```

**VPC Configuration (DR - eu-west-1):**
```
VPC: bbws-prod-vpc-dr (10.3.0.0/16)
├── Public Subnets (Internet Gateway)
│   ├── bbws-prod-dr-public-1a (10.3.1.0/24)
│   ├── bbws-prod-dr-public-1b (10.3.2.0/24)
│   └── bbws-prod-dr-public-1c (10.3.3.0/24)
├── Private Subnets (NAT Gateways)
│   ├── bbws-prod-dr-private-1a (10.3.10.0/24)
│   ├── bbws-prod-dr-private-1b (10.3.11.0/24)
│   └── bbws-prod-dr-private-1c (10.3.12.0/24)
└── NAT Gateways
    ├── bbws-prod-dr-nat-1a
    ├── bbws-prod-dr-nat-1b
    └── bbws-prod-dr-nat-1c
```

---

## 3. Regional Configuration

### 3.1 Primary Region: af-south-1 (Cape Town)

| Attribute | Value | Rationale |
|-----------|-------|-----------|
| **Region Code** | af-south-1 | Primary BBWS region |
| **Region Name** | Africa (Cape Town) | Local data residency for South African customers |
| **Available Services** | Lambda, DynamoDB, S3, SQS, SES, SNS, API Gateway, CloudWatch, Route 53, Secrets Manager, Systems Manager | All required services available |
| **Latency from South Africa** | < 20ms | Low latency for local users |
| **Cost** | Moderate | Standard AWS pricing |
| **Availability Zones** | 3 AZs (af-south-1a, 1b, 1c) | High availability support |
| **Data Residency Compliance** | Yes | Meets South African data residency requirements |
| **Environments** | PROD only | PROD uses af-south-1 as primary; DEV/SIT use eu-west-1 |

**Service Availability Verification:**
- Lambda: ✓ (Python 3.12, arm64 supported)
- DynamoDB: ✓ (On-demand, Global Tables, PITR)
- S3: ✓ (Cross-region replication, versioning)
- SQS: ✓ (Standard queues, FIFO queues, DLQ)
- SES: ✓ (Email sending, domain verification)
- API Gateway: ✓ (REST APIs, HTTP APIs, WebSocket)

### 3.2 Failover Region: eu-west-1 (Dublin) [PROD ONLY]

| Attribute | Value | Rationale |
|-----------|-------|-----------|
| **Region Code** | eu-west-1 | Secondary/DR region |
| **Region Name** | Europe (Dublin) | Geographically diverse from primary |
| **Available Services** | All required services (Lambda, DynamoDB, S3, SQS, SES, SNS, API Gateway, etc.) | Full service parity with primary region |
| **Latency from South Africa** | ~180-220ms | Acceptable for failover scenarios |
| **Cost** | Moderate | Standard AWS pricing (similar to af-south-1) |
| **Availability Zones** | 3 AZs (eu-west-1a, 1b, 1c) | High availability support |
| **Active/Standby** | Active (multi-site active/active) | Continuous synchronization and health checks |
| **Environments** | PROD only | DR not required for DEV/SIT |

**Cross-Region Capabilities:**
- DynamoDB Global Tables: ✓ (Multi-region replication)
- S3 Cross-Region Replication: ✓ (Automatic replication)
- Route 53 Failover: ✓ (Health check-based routing)
- Lambda Multi-Region: ✓ (Duplicate Lambda deployment)

### 3.3 Route 53 Health Checks and Failover

**Health Check Configuration:**

```hcl
resource "aws_route53_health_check" "primary_region" {
  fqdn              = "api.bbws.io"
  port              = 443
  type              = "HTTPS"
  resource_path     = "/health"
  failure_threshold = 2              # 2 consecutive failures trigger failover
  request_interval  = 30             # Check every 30 seconds
  measure_latency   = true

  tags = {
    Name        = "bbws-order-api-health-check-primary"
    Environment = "prod"
    Region      = "af-south-1"
  }
}

resource "aws_route53_record" "api_primary" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "api.bbws.io"
  type    = "A"

  set_identifier = "primary-af-south-1"

  failover_routing_policy {
    type = "PRIMARY"
  }

  alias {
    name                   = aws_api_gateway_domain_name.primary.regional_domain_name
    zone_id                = aws_api_gateway_domain_name.primary.regional_zone_id
    evaluate_target_health = true
  }

  health_check_id = aws_route53_health_check.primary_region.id
}

resource "aws_route53_record" "api_secondary" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "api.bbws.io"
  type    = "A"

  set_identifier = "secondary-eu-west-1"

  failover_routing_policy {
    type = "SECONDARY"
  }

  alias {
    name                   = aws_api_gateway_domain_name.secondary.regional_domain_name
    zone_id                = aws_api_gateway_domain_name.secondary.regional_zone_id
    evaluate_target_health = true
  }
}
```

**Failover Behavior:**
1. Route 53 checks primary region health every 30 seconds
2. If 2 consecutive health checks fail (60 seconds total), failover triggered
3. DNS routes traffic to secondary region (eu-west-1)
4. DNS TTL: 60 seconds (quick propagation)
5. Total failover time: ~1-2 minutes (health check + DNS propagation)

### 3.4 Cross-Region Replication

**DynamoDB Global Tables (PROD):**

```hcl
resource "aws_dynamodb_table" "orders_primary" {
  provider     = aws.af_south_1
  name         = "bbws-customer-portal-orders-prod"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "PK"
  range_key    = "SK"

  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  replica {
    region_name = "eu-west-1"
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Environment = "prod"
    Region      = "af-south-1"
    Replication = "enabled"
  }
}
```

**S3 Cross-Region Replication (PROD):**

```hcl
resource "aws_s3_bucket_replication_configuration" "orders" {
  provider = aws.af_south_1
  role     = aws_iam_role.s3_replication.arn
  bucket   = aws_s3_bucket.orders_prod.id

  rule {
    id       = "replicate-orders-to-dr"
    status   = "Enabled"
    priority = 1

    filter {
      prefix = ""  # Replicate all objects
    }

    destination {
      bucket        = aws_s3_bucket.orders_prod_dr.arn
      storage_class = "STANDARD"

      replication_time {
        status = "Enabled"
        time {
          minutes = 15  # Replicate within 15 minutes
        }
      }

      metrics {
        status = "Enabled"
        event_threshold {
          minutes = 15
        }
      }
    }
  }
}
```

**Replication Latency:**
- DynamoDB: < 1 second (Global Tables)
- S3: < 15 minutes (S3 Replication Time Control)

---

## 4. Complete Parameter Matrix

### 4.1 DynamoDB Tables

| Resource | DEV | SIT | PROD (Primary) | PROD (DR) |
|----------|-----|-----|----------------|-----------|
| **Table Name** | bbws-customer-portal-orders-dev | bbws-customer-portal-orders-sit | bbws-customer-portal-orders-prod | bbws-customer-portal-orders-prod (replica) |
| **Region** | eu-west-1 | eu-west-1 | af-south-1 | eu-west-1 |
| **Billing Mode** | PAY_PER_REQUEST | PAY_PER_REQUEST | PAY_PER_REQUEST | PAY_PER_REQUEST |
| **PITR** | Enabled (7 days) | Enabled (14 days) | Enabled (35 days) | Enabled (35 days) |
| **Backup Frequency** | Daily | Daily | Hourly | Hourly (synced from primary) |
| **Backup Retention** | 7 days | 14 days | 90 days | 90 days |
| **Streams** | Enabled (NEW_AND_OLD_IMAGES) | Enabled (NEW_AND_OLD_IMAGES) | Enabled (NEW_AND_OLD_IMAGES) | Enabled (NEW_AND_OLD_IMAGES) |
| **Encryption** | AWS-managed KMS | AWS-managed KMS | AWS-managed KMS | AWS-managed KMS |
| **Deletion Protection** | Disabled | Disabled | Enabled | Enabled |
| **Global Table** | No | No | Yes (primary) | Yes (replica) |

### 4.2 SQS Queues

| Resource | DEV | SIT | PROD |
|----------|-----|-----|------|
| **Main Queue Name** | bbws-order-creation-dev | bbws-order-creation-sit | bbws-order-creation-prod |
| **DLQ Name** | bbws-order-creation-dlq-dev | bbws-order-creation-dlq-sit | bbws-order-creation-dlq-prod |
| **Region** | eu-west-1 | eu-west-1 | af-south-1 (primary) + eu-west-1 (DR) |
| **Visibility Timeout** | 60 seconds | 60 seconds | 60 seconds |
| **Message Retention** | 4 days | 4 days | 14 days |
| **Max Receive Count** | 3 | 3 | 3 |
| **DLQ Retention** | 7 days | 14 days | 14 days |
| **Batch Size** | 10 | 10 | 10 |
| **Encryption** | AWS-managed SQS SSE | AWS-managed SQS SSE | AWS-managed SQS SSE |

### 4.3 S3 Buckets

| Resource | DEV | SIT | PROD (Primary) | PROD (DR) |
|----------|-----|-----|----------------|-----------|
| **Email Templates Bucket** | bbws-email-templates-dev | bbws-email-templates-sit | bbws-email-templates-prod | bbws-email-templates-prod-dr |
| **Order Artifacts Bucket** | bbws-orders-dev | bbws-orders-sit | bbws-orders-prod | bbws-orders-prod-dr |
| **Region** | eu-west-1 | eu-west-1 | af-south-1 | eu-west-1 |
| **Versioning** | Disabled | Enabled | Enabled | Enabled |
| **Public Access** | Blocked | Blocked | Blocked | Blocked |
| **Encryption** | SSE-S3 (AES-256) | SSE-S3 (AES-256) | SSE-S3 (AES-256) | SSE-S3 (AES-256) |
| **Lifecycle Policy** | 30-day retention | 60-day retention | 7-year retention (Glacier after 2 years) | Same as primary |
| **Access Logging** | Disabled | Enabled | Enabled | Enabled |
| **Replication** | No | No | Yes (to eu-west-1) | Replica of primary |
| **Object Lock** | Not enabled | Not enabled | Not enabled | Not enabled |

### 4.4 Lambda Functions

| Handler | DEV | SIT | PROD (Primary) | PROD (DR) |
|---------|-----|-----|----------------|-----------|
| **create_order** | bbws-order-lambda-create-order-dev | bbws-order-lambda-create-order-sit | bbws-order-lambda-create-order-prod | bbws-order-lambda-create-order-prod-dr |
| **get_order** | bbws-order-lambda-get-order-dev | bbws-order-lambda-get-order-sit | bbws-order-lambda-get-order-prod | bbws-order-lambda-get-order-prod-dr |
| **list_orders** | bbws-order-lambda-list-orders-dev | bbws-order-lambda-list-orders-sit | bbws-order-lambda-list-orders-prod | bbws-order-lambda-list-orders-prod-dr |
| **update_order** | bbws-order-lambda-update-order-dev | bbws-order-lambda-update-order-sit | bbws-order-lambda-update-order-prod | bbws-order-lambda-update-order-prod-dr |
| **OrderCreatorRecord** | bbws-order-lambda-creator-record-dev | bbws-order-lambda-creator-record-sit | bbws-order-lambda-creator-record-prod | bbws-order-lambda-creator-record-prod-dr |
| **OrderPDFCreator** | bbws-order-lambda-pdf-creator-dev | bbws-order-lambda-pdf-creator-sit | bbws-order-lambda-pdf-creator-prod | bbws-order-lambda-pdf-creator-prod-dr |
| **OrderInternalNotifier** | bbws-order-lambda-internal-notifier-dev | bbws-order-lambda-internal-notifier-sit | bbws-order-lambda-internal-notifier-prod | bbws-order-lambda-internal-notifier-prod-dr |
| **CustomerNotifier** | bbws-order-lambda-customer-notifier-dev | bbws-order-lambda-customer-notifier-sit | bbws-order-lambda-customer-notifier-prod | bbws-order-lambda-customer-notifier-prod-dr |
| **Region** | eu-west-1 | eu-west-1 | af-south-1 | eu-west-1 |
| **Memory** | 512 MB | 512 MB | 512 MB | 512 MB |
| **Timeout** | 30 seconds | 30 seconds | 30 seconds | 30 seconds |
| **Architecture** | arm64 | arm64 | arm64 | arm64 |
| **Runtime** | Python 3.12 | Python 3.12 | Python 3.12 | Python 3.12 |

### 4.5 API Gateway

| Resource | DEV | SIT | PROD (Primary) | PROD (DR) |
|----------|-----|-----|----------------|-----------|
| **API Name** | bbws-order-api-dev | bbws-order-api-sit | bbws-order-api-prod | bbws-order-api-prod-dr |
| **API Type** | REST API | REST API | REST API | REST API |
| **Stage** | dev | sit | prod | prod |
| **Base URL** | https://api-dev.bbws.io/v1.0 | https://api-sit.bbws.io/v1.0 | https://api.bbws.io/v1.0 | https://api-dr.bbws.io/v1.0 |
| **Region** | eu-west-1 | eu-west-1 | af-south-1 | eu-west-1 |
| **Throttling (req/s)** | 1,000 | 5,000 | 10,000 | 10,000 |
| **Burst Limit** | 2,000 | 10,000 | 20,000 | 20,000 |
| **API Key Required** | No | No | Yes | Yes |
| **Custom Domain** | api-dev.bbws.io | api-sit.bbws.io | api.bbws.io (Route 53 failover) | api-dr.bbws.io |

### 4.6 Terraform .tfvars Files

#### dev.tfvars

```hcl
# Environment Configuration
environment             = "dev"
aws_account_id          = "536580886816"
aws_region              = "eu-west-1"
aws_failover_region     = null  # No DR for DEV

# DynamoDB Configuration
dynamodb_table_name             = "bbws-customer-portal-orders-dev"
dynamodb_billing_mode           = "PAY_PER_REQUEST"
dynamodb_pitr_enabled           = true
dynamodb_backup_retention_days  = 7
dynamodb_deletion_protection    = false
dynamodb_enable_streams         = true
dynamodb_stream_view_type       = "NEW_AND_OLD_IMAGES"
dynamodb_enable_global_table    = false

# SQS Configuration
sqs_queue_name                  = "bbws-order-creation-dev"
sqs_dlq_name                    = "bbws-order-creation-dlq-dev"
sqs_visibility_timeout          = 60
sqs_message_retention           = 345600  # 4 days
sqs_max_receive_count           = 3
sqs_dlq_retention               = 604800  # 7 days

# S3 Configuration
s3_templates_bucket             = "bbws-email-templates-dev"
s3_orders_bucket                = "bbws-orders-dev"
s3_versioning_enabled           = false
s3_lifecycle_days               = 30
s3_access_logging               = false
s3_enable_replication           = false
s3_block_public_access          = true  # MANDATORY

# Lambda Configuration
lambda_memory_size              = 512
lambda_timeout                  = 30
lambda_architecture             = "arm64"
lambda_runtime                  = "python3.12"
lambda_reserved_concurrency     = null  # No reserved concurrency for DEV
lambda_provisioned_concurrency  = 0
lambda_log_retention_days       = 7
lambda_enable_xray              = false

# API Gateway Configuration
api_gateway_throttle_rate       = 1000
api_gateway_throttle_burst      = 2000
api_gateway_api_key_required    = false
api_gateway_custom_domain       = "api-dev.bbws.io"

# SES Configuration
ses_sending_limit               = "1/sec"  # 1 email per second
ses_from_address                = "test@kimmyai.io"
ses_domain_verification         = false

# CloudWatch Configuration
cloudwatch_log_retention        = 7
cloudwatch_detailed_metrics     = false
cloudwatch_enable_alarms        = false
cloudwatch_alarm_sns_topic      = null

# Disaster Recovery
enable_cross_region_dr          = false

# Cost Budget
cost_budget_monthly             = 500
cost_budget_alert_threshold     = 400  # 80%

# Tagging
tags = {
  Environment  = "dev"
  Project      = "BBWS Customer Portal"
  Component    = "Order Lambda"
  Owner        = "Tebogo"
  CostCenter   = "AWS"
  ManagedBy    = "Terraform"
  Application  = "CustomerPortalPublic"
  Repository   = "2_bbws_order_lambda"
}
```

#### sit.tfvars

```hcl
# Environment Configuration
environment             = "sit"
aws_account_id          = "815856636111"
aws_region              = "eu-west-1"
aws_failover_region     = null  # No DR for SIT

# DynamoDB Configuration
dynamodb_table_name             = "bbws-customer-portal-orders-sit"
dynamodb_billing_mode           = "PAY_PER_REQUEST"
dynamodb_pitr_enabled           = true
dynamodb_backup_retention_days  = 14
dynamodb_deletion_protection    = false
dynamodb_enable_streams         = true
dynamodb_stream_view_type       = "NEW_AND_OLD_IMAGES"
dynamodb_enable_global_table    = false

# SQS Configuration
sqs_queue_name                  = "bbws-order-creation-sit"
sqs_dlq_name                    = "bbws-order-creation-dlq-sit"
sqs_visibility_timeout          = 60
sqs_message_retention           = 345600  # 4 days
sqs_max_receive_count           = 3
sqs_dlq_retention               = 1209600  # 14 days

# S3 Configuration
s3_templates_bucket             = "bbws-email-templates-sit"
s3_orders_bucket                = "bbws-orders-sit"
s3_versioning_enabled           = true
s3_lifecycle_days               = 60
s3_access_logging               = true
s3_enable_replication           = false
s3_block_public_access          = true  # MANDATORY

# Lambda Configuration
lambda_memory_size              = 512
lambda_timeout                  = 30
lambda_architecture             = "arm64"
lambda_runtime                  = "python3.12"
lambda_reserved_concurrency     = 10
lambda_provisioned_concurrency  = 0
lambda_log_retention_days       = 30
lambda_enable_xray              = true

# API Gateway Configuration
api_gateway_throttle_rate       = 5000
api_gateway_throttle_burst      = 10000
api_gateway_api_key_required    = false
api_gateway_custom_domain       = "api-sit.bbws.io"

# SES Configuration
ses_sending_limit               = "10/sec"  # 10 emails per second
ses_from_address                = "noreply@kimmyai.io"
ses_domain_verification         = true

# CloudWatch Configuration
cloudwatch_log_retention        = 30
cloudwatch_detailed_metrics     = true
cloudwatch_enable_alarms        = true
cloudwatch_alarm_sns_topic      = "bbws-alerts-sit"

# Disaster Recovery
enable_cross_region_dr          = false

# Cost Budget
cost_budget_monthly             = 1000
cost_budget_alert_threshold     = 800  # 80%

# Tagging
tags = {
  Environment  = "sit"
  Project      = "BBWS Customer Portal"
  Component    = "Order Lambda"
  Owner        = "Tebogo"
  CostCenter   = "AWS"
  ManagedBy    = "Terraform"
  Application  = "CustomerPortalPublic"
  Repository   = "2_bbws_order_lambda"
}
```

#### prod.tfvars

```hcl
# Environment Configuration
environment             = "prod"
aws_account_id          = "093646564004"
aws_region              = "af-south-1"
aws_failover_region     = "eu-west-1"  # DR region

# DynamoDB Configuration
dynamodb_table_name             = "bbws-customer-portal-orders-prod"
dynamodb_billing_mode           = "PAY_PER_REQUEST"
dynamodb_pitr_enabled           = true
dynamodb_backup_retention_days  = 90
dynamodb_deletion_protection    = true
dynamodb_enable_streams         = true
dynamodb_stream_view_type       = "NEW_AND_OLD_IMAGES"
dynamodb_enable_global_table    = true
dynamodb_replica_region         = "eu-west-1"

# SQS Configuration
sqs_queue_name                  = "bbws-order-creation-prod"
sqs_dlq_name                    = "bbws-order-creation-dlq-prod"
sqs_visibility_timeout          = 60
sqs_message_retention           = 1209600  # 14 days
sqs_max_receive_count           = 3
sqs_dlq_retention               = 1209600  # 14 days

# S3 Configuration
s3_templates_bucket             = "bbws-email-templates-prod"
s3_orders_bucket                = "bbws-orders-prod"
s3_versioning_enabled           = true
s3_lifecycle_days               = 730  # 2 years before Glacier
s3_glacier_transition_days      = 730
s3_retention_years              = 7
s3_access_logging               = true
s3_enable_replication           = true
s3_replication_destination_region = "eu-west-1"
s3_block_public_access          = true  # MANDATORY

# Lambda Configuration
lambda_memory_size              = 512
lambda_timeout                  = 30
lambda_architecture             = "arm64"
lambda_runtime                  = "python3.12"
lambda_reserved_concurrency     = 50
lambda_provisioned_concurrency  = 20  # For OrderCreatorRecord
lambda_log_retention_days       = 90
lambda_enable_xray              = true

# API Gateway Configuration
api_gateway_throttle_rate       = 10000
api_gateway_throttle_burst      = 20000
api_gateway_api_key_required    = true
api_gateway_custom_domain       = "api.bbws.io"

# SES Configuration
ses_sending_limit               = "50/sec"  # 50 emails per second
ses_from_address                = "noreply@kimmyai.io"
ses_domain_verification         = true

# CloudWatch Configuration
cloudwatch_log_retention        = 90
cloudwatch_detailed_metrics     = true
cloudwatch_enable_alarms        = true
cloudwatch_alarm_sns_topic      = "bbws-alerts-prod"

# Disaster Recovery
enable_cross_region_dr          = true
dr_region                       = "eu-west-1"
route53_health_check_enabled    = true
route53_health_check_interval   = 30
route53_health_check_failure_threshold = 2

# Cost Budget
cost_budget_monthly             = 5000
cost_budget_alert_threshold     = 4000  # 80%

# Tagging
tags = {
  Environment  = "prod"
  Project      = "BBWS Customer Portal"
  Component    = "Order Lambda"
  Owner        = "Tebogo"
  CostCenter   = "AWS"
  ManagedBy    = "Terraform"
  Application  = "CustomerPortalPublic"
  Repository   = "2_bbws_order_lambda"
  BackupPolicy = "hourly"
  DR           = "enabled"
  Compliance   = "PCI-DSS,GDPR"
}
```

---

## 5. Promotion Workflow

### 5.1 Promotion Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          PROMOTION WORKFLOW                                 │
│                    DEV → SIT → PROD with Approval Gates                     │
└─────────────────────────────────────────────────────────────────────────────┘

    DEV Branch              SIT Branch              PROD Branch
    (develop)              (release)               (main)
        │                      │                      │
        │                      │                      │
┌───────┴────────┐             │                      │
│  DEV Testing   │             │                      │
│  ✓ Unit Tests  │             │                      │
│  ✓ Integration │             │                      │
│  ✓ Manual Test │             │                      │
└───────┬────────┘             │                      │
        │                      │                      │
        ├──────────────────────┤                      │
        │                      │                      │
   [APPROVAL GATE]             │                      │
   ─────────────────           │                      │
   Lead Dev Reviews            │                      │
   Terraform Plan              │                      │
   Manual Trigger: "go"        │                      │
        │                      │                      │
        └──────────►           │                      │
                     ┌─────────┴──────────┐           │
                     │   SIT Testing      │           │
                     │   ✓ Regression     │           │
                     │   ✓ Load Testing   │           │
                     │   ✓ UAT Testing    │           │
                     │   ✓ Security Scan  │           │
                     └─────────┬──────────┘           │
                               │                      │
                               ├──────────────────────┤
                               │                      │
                          [APPROVAL GATE]             │
                          ─────────────────           │
                          Tech Lead + QA Lead         │
                          Terraform Plan Review       │
                          Manual Trigger: "go"        │
                               │                      │
                               └──────────►           │
                                            ┌─────────┴──────────┐
                                            │   PROD Deployment  │
                                            │   ✓ Smoke Tests    │
                                            │   ✓ Health Checks  │
                                            │   ✓ DR Validation  │
                                            │   (read-only ops)  │
                                            └────────────────────┘
```

### 5.2 DEV → SIT Promotion Criteria

**Checklist (All items must pass):**

- [ ] All unit tests pass (>80% code coverage)
- [ ] All integration tests pass
- [ ] Manual testing in DEV complete (QA sign-off)
- [ ] Code review approved (minimum 2 approvals)
- [ ] No high/critical security vulnerabilities (tfsec, checkov)
- [ ] Terraform plan reviewed and approved
- [ ] Release notes prepared and reviewed
- [ ] Database migration scripts tested (if applicable)
- [ ] API contract changes documented (OpenAPI updated)
- [ ] Manual approval from **Lead Developer**

**Approval Process:**
1. Developer creates PR from `develop` → `release` branch
2. CI/CD runs validation pipeline (tests, security scans, terraform plan)
3. Lead Developer reviews terraform plan output
4. Lead Developer approves via GitHub review
5. Manual trigger: `workflow_dispatch` for "deploy-sit"
6. CI/CD deploys to SIT environment

### 5.3 SIT → PROD Promotion Criteria

**Checklist (All items must pass):**

- [ ] All regression tests pass in SIT
- [ ] Load testing completed (capacity verified for expected volume)
- [ ] UAT testing complete (business stakeholder validation)
- [ ] Security scan cleared (no high/critical vulnerabilities)
- [ ] Performance baselines met (latency, throughput)
- [ ] DR procedures tested (failover simulation)
- [ ] Smoke tests pass in SIT
- [ ] Terraform plan reviewed and approved by Tech Lead + PO + DevOps
- [ ] Rollback plan documented and reviewed
- [ ] Change management approval (if required)
- [ ] Manual approval from **Tech Lead + Product Owner + DevOps Lead**

**Approval Process:**
1. QA Lead creates PR from `release` → `main` branch
2. CI/CD runs comprehensive validation (tests, security, performance, terraform plan)
3. Stakeholders review terraform plan and change impact
4. **Tech Lead** approves via GitHub review
5. **Product Owner** approves via GitHub review
6. **DevOps Lead** approves via GitHub review
7. Manual trigger: `workflow_dispatch` for "deploy-prod"
8. CI/CD deploys to PROD environment (primary + DR regions)

### 5.4 Approval Gates in GitHub Actions

**DEV Approval Gate:**

```yaml
# .github/workflows/deploy-dev.yml
name: Deploy to DEV

on:
  workflow_dispatch:  # Manual trigger only
    inputs:
      approve:
        description: 'Type "approve" to confirm deployment'
        required: true
        type: string

jobs:
  validate-approval:
    runs-on: ubuntu-latest
    steps:
      - name: Validate Approval
        if: ${{ github.event.inputs.approve != 'approve' }}
        run: |
          echo "ERROR: Deployment not approved. Please type 'approve' to continue."
          exit 1

  deploy:
    needs: validate-approval
    runs-on: ubuntu-latest
    environment: dev  # GitHub environment with protection rules
    steps:
      - name: Deploy to DEV
        run: |
          cd terraform/dev
          terraform init
          terraform apply -var-file=dev.tfvars -auto-approve
```

**SIT Approval Gate:**

```yaml
# .github/workflows/deploy-sit.yml
name: Deploy to SIT

on:
  workflow_dispatch:
    inputs:
      approve:
        description: 'Type "approve" to confirm SIT deployment'
        required: true
        type: string
      test_results_url:
        description: 'Link to DEV test results'
        required: true
        type: string

jobs:
  validate-approval:
    runs-on: ubuntu-latest
    steps:
      - name: Validate Approval
        if: ${{ github.event.inputs.approve != 'approve' }}
        run: |
          echo "ERROR: SIT deployment not approved."
          exit 1

  deploy:
    needs: validate-approval
    runs-on: ubuntu-latest
    environment: sit  # Requires QA Lead + Tech Lead approval
    steps:
      - name: Deploy to SIT
        run: |
          cd terraform/sit
          terraform init
          terraform apply -var-file=sit.tfvars -auto-approve
```

**PROD Approval Gate:**

```yaml
# .github/workflows/deploy-prod.yml
name: Deploy to PROD

on:
  workflow_dispatch:
    inputs:
      approve:
        description: 'Type "APPROVE-PROD" to confirm PRODUCTION deployment'
        required: true
        type: string
      uat_results_url:
        description: 'Link to SIT UAT test results'
        required: true
        type: string
      rollback_plan_url:
        description: 'Link to rollback plan document'
        required: true
        type: string

jobs:
  validate-approval:
    runs-on: ubuntu-latest
    steps:
      - name: Validate Strict Approval
        if: ${{ github.event.inputs.approve != 'APPROVE-PROD' }}
        run: |
          echo "ERROR: PROD deployment not approved. Type 'APPROVE-PROD' exactly."
          exit 1

  deploy:
    needs: validate-approval
    runs-on: ubuntu-latest
    environment: prod  # Requires Tech Lead + PO + DevOps approval
    steps:
      - name: Deploy to PROD (Primary + DR)
        run: |
          # Deploy to primary region (af-south-1)
          cd terraform/prod
          terraform init
          terraform apply -var-file=prod.tfvars -auto-approve

          # Deploy to DR region (eu-west-1)
          terraform apply -var-file=prod.tfvars -var="aws_region=eu-west-1" -auto-approve
```

### 5.5 Rollback Procedure

**Scenario: PROD deployment fails or introduces critical bug**

```bash
# Step 1: Assess severity
# If critical: Failover to DR region immediately

# Step 2: Terraform Rollback
cd terraform/prod
terraform state list  # Identify resources to rollback

# Option A: Rollback to previous state (if state versioning enabled)
aws s3 cp s3://bbws-terraform-state-prod/order-lambda/terraform.tfstate.backup \
          s3://bbws-terraform-state-prod/order-lambda/terraform.tfstate

terraform apply -var-file=prod.tfvars  # Apply previous state

# Option B: Destroy problematic resources and recreate from last good state
terraform destroy -target=aws_lambda_function.create_order -var-file=prod.tfvars
terraform apply -var-file=prod.tfvars

# Step 3: Validate health checks
aws route53 get-health-check-status --health-check-id <health-check-id>

# Step 4: Notify stakeholders
# Send incident notification via SNS/Slack

# Step 5: Post-incident review
# Document what went wrong and update deployment procedures
```

**Automated Rollback (CI/CD):**

```yaml
# .github/workflows/rollback-prod.yml
name: Rollback PROD

on:
  workflow_dispatch:
    inputs:
      rollback_target:
        description: 'Target to rollback (e.g., aws_lambda_function.create_order)'
        required: true
        type: string

jobs:
  rollback:
    runs-on: ubuntu-latest
    environment: prod
    steps:
      - name: Rollback Resource
        run: |
          cd terraform/prod
          terraform init
          terraform destroy -target=${{ github.event.inputs.rollback_target }} -var-file=prod.tfvars
          terraform apply -var-file=prod.tfvars
```

---

## 6. Terraform Configuration Strategy

### 6.1 File Organization

```
2_bbws_order_lambda/
├── terraform/
│   ├── modules/
│   │   ├── lambda/
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   └── iam.tf
│   │   ├── dynamodb/
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   └── backup.tf
│   │   ├── sqs/
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   └── dlq.tf
│   │   ├── s3/
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   ├── replication.tf
│   │   │   └── lifecycle.tf
│   │   ├── api_gateway/
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   └── custom_domain.tf
│   │   └── monitoring/
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       ├── outputs.tf
│   │       ├── cloudwatch.tf
│   │       └── alarms.tf
│   ├── environments/
│   │   ├── dev/
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   ├── backend.tf
│   │   │   └── dev.tfvars
│   │   ├── sit/
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   ├── backend.tf
│   │   │   └── sit.tfvars
│   │   └── prod/
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       ├── outputs.tf
│   │       ├── backend.tf
│   │       ├── prod.tfvars
│   │       └── dr.tf  # DR-specific resources
│   └── README.md
```

### 6.2 Backend Configuration

**DEV Backend (terraform/environments/dev/backend.tf):**

```hcl
terraform {
  backend "s3" {
    bucket         = "bbws-terraform-state-dev"
    key            = "order-lambda/terraform.tfstate"
    region         = "af-south-1"
    encrypt        = true
    dynamodb_table = "terraform-locks-dev"

    # State locking
    versioning     = true
  }

  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.tags
  }
}
```

**SIT Backend (terraform/environments/sit/backend.tf):**

```hcl
terraform {
  backend "s3" {
    bucket         = "bbws-terraform-state-sit"
    key            = "order-lambda/terraform.tfstate"
    region         = "af-south-1"
    encrypt        = true
    dynamodb_table = "terraform-locks-sit"

    versioning     = true
  }

  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.tags
  }
}
```

**PROD Backend (terraform/environments/prod/backend.tf):**

```hcl
terraform {
  backend "s3" {
    bucket         = "bbws-terraform-state-prod"
    key            = "order-lambda/terraform.tfstate"
    region         = "af-south-1"
    encrypt        = true
    dynamodb_table = "terraform-locks-prod"

    versioning     = true
  }

  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Primary region provider
provider "aws" {
  alias  = "primary"
  region = var.aws_region

  default_tags {
    tags = merge(var.tags, { Region = "primary" })
  }
}

# DR region provider
provider "aws" {
  alias  = "dr"
  region = var.aws_failover_region

  default_tags {
    tags = merge(var.tags, { Region = "dr" })
  }
}
```

### 6.3 State File Management

**State Bucket Configuration (must be created before first terraform init):**

```hcl
# Manual setup (run once per environment)
# terraform/setup/state-backend/main.tf

resource "aws_s3_bucket" "terraform_state" {
  bucket = "bbws-terraform-state-${var.environment}"

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = "Terraform State Bucket"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-locks-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Terraform Lock Table"
    Environment = var.environment
  }
}
```

**State File Encryption:**
- S3 bucket versioning: Enabled (all environments)
- Server-side encryption: SSE-S3 (AES-256)
- Block public access: Yes (all buckets)
- Access logging: Enabled for SIT/PROD
- MFA delete: Enabled for PROD

**Locking Mechanism:**
- DynamoDB table per environment for state locking
- Table name: `terraform-locks-{environment}`
- Hash key: `LockID`
- Billing mode: On-demand (no capacity planning needed)
- Prevents concurrent terraform operations

---

## 7. CI/CD Pipeline Configuration

### 7.1 GitHub Actions Environments

**GitHub Repository Settings → Environments:**

**Environment: dev**
```yaml
Name: dev
Deployment branches:
  - develop
Protection rules:
  - Required reviewers: 1 (Lead Developer)
  - Wait timer: 0 minutes
  - Prevent self-review: false
Environment secrets:
  - DEV_AWS_ACCOUNT_ID: 536580886816
  - DEV_AWS_REGION: eu-west-1
  - DEV_OIDC_ROLE_ARN: arn:aws:iam::536580886816:role/github-2-bbws-order-lambda-dev
```

**Environment: sit**
```yaml
Name: sit
Deployment branches:
  - release
Protection rules:
  - Required reviewers: 2 (Tech Lead + QA Lead)
  - Wait timer: 0 minutes
  - Prevent self-review: true
Environment secrets:
  - SIT_AWS_ACCOUNT_ID: 815856636111
  - SIT_AWS_REGION: eu-west-1
  - SIT_OIDC_ROLE_ARN: arn:aws:iam::815856636111:role/github-2-bbws-order-lambda-sit
```

**Environment: prod**
```yaml
Name: prod
Deployment branches:
  - main
Protection rules:
  - Required reviewers: 3 (Tech Lead + Product Owner + DevOps Lead)
  - Wait timer: 30 minutes (cooling-off period)
  - Prevent self-review: true
  - Deployment window: Business hours only
Environment secrets:
  - PROD_AWS_ACCOUNT_ID: 093646564004
  - PROD_AWS_REGION: af-south-1
  - PROD_AWS_FAILOVER_REGION: eu-west-1
  - PROD_OIDC_ROLE_ARN: arn:aws:iam::093646564004:role/github-2-bbws-order-lambda-prod
```

### 7.2 OIDC Role ARNs

**DEV OIDC Role:**
```
arn:aws:iam::536580886816:role/github-2-bbws-order-lambda-dev
```

**SIT OIDC Role:**
```
arn:aws:iam::815856636111:role/github-2-bbws-order-lambda-sit
```

**PROD OIDC Role:**
```
arn:aws:iam::093646564004:role/github-2-bbws-order-lambda-prod
```

**OIDC Role Trust Policy (Example for DEV):**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::536580886816:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:your-org/2_bbws_order_lambda:ref:refs/heads/develop"
        }
      }
    }
  ]
}
```

### 7.3 GitHub Actions Workflow Examples

**Validation Workflow (.github/workflows/validate.yml):**

```yaml
name: Validate Terraform

on:
  pull_request:
    branches: [develop, release, main]
  push:
    branches: [develop, release, main]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.6.0

      - name: Terraform Format Check
        run: |
          terraform fmt -check -recursive terraform/

      - name: Terraform Init (DEV)
        run: |
          cd terraform/environments/dev
          terraform init -backend=false

      - name: Terraform Validate
        run: |
          cd terraform/environments/dev
          terraform validate

      - name: Security Scan (tfsec)
        uses: aquasecurity/tfsec-action@v1.0.3
        with:
          working_directory: terraform/
          soft_fail: false

      - name: Cost Estimation (Infracost)
        uses: infracost/actions/setup@v2
        with:
          api-key: ${{ secrets.INFRACOST_API_KEY }}

      - name: Generate Cost Estimate
        run: |
          cd terraform/environments/dev
          infracost breakdown --path . --format json --out-file /tmp/infracost-dev.json
```

**DEV Deployment Workflow (.github/workflows/deploy-dev.yml):**

```yaml
name: Deploy to DEV

on:
  workflow_dispatch:
    inputs:
      approve:
        description: 'Type "approve" to deploy to DEV'
        required: true
        type: string

env:
  AWS_REGION: eu-west-1
  TF_VERSION: 1.6.0

jobs:
  validate-approval:
    runs-on: ubuntu-latest
    steps:
      - name: Validate Approval
        if: ${{ github.event.inputs.approve != 'approve' }}
        run: |
          echo "ERROR: Deployment not approved"
          exit 1

  terraform-plan:
    needs: validate-approval
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.DEV_OIDC_ROLE_ARN }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Terraform Init
        run: |
          cd terraform/environments/dev
          terraform init

      - name: Terraform Plan
        run: |
          cd terraform/environments/dev
          terraform plan -var-file=dev.tfvars -out=tfplan

      - name: Upload Plan
        uses: actions/upload-artifact@v3
        with:
          name: dev-tfplan
          path: terraform/environments/dev/tfplan

  terraform-apply:
    needs: terraform-plan
    runs-on: ubuntu-latest
    environment: dev
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.DEV_OIDC_ROLE_ARN }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Download Plan
        uses: actions/download-artifact@v3
        with:
          name: dev-tfplan
          path: terraform/environments/dev/

      - name: Terraform Apply
        run: |
          cd terraform/environments/dev
          terraform init
          terraform apply -auto-approve tfplan

      - name: Post-Deployment Validation
        run: |
          # Run basic health checks
          python tests/integration/health_check.py --environment dev

      - name: Notify Slack
        uses: slackapi/slack-github-action@v1
        with:
          webhook-url: ${{ secrets.SLACK_WEBHOOK_DEV }}
          payload: |
            {
              "text": "✅ DEV deployment successful for 2_bbws_order_lambda"
            }
```

**SIT Deployment Workflow (.github/workflows/deploy-sit.yml):**

```yaml
name: Deploy to SIT

on:
  workflow_dispatch:
    inputs:
      approve:
        description: 'Type "approve" to deploy to SIT'
        required: true
        type: string
      dev_test_url:
        description: 'Link to DEV test results'
        required: true
        type: string

env:
  AWS_REGION: eu-west-1
  TF_VERSION: 1.6.0

jobs:
  validate-approval:
    runs-on: ubuntu-latest
    steps:
      - name: Validate Approval
        if: ${{ github.event.inputs.approve != 'approve' }}
        run: |
          echo "ERROR: SIT deployment not approved"
          exit 1

  terraform-apply:
    needs: validate-approval
    runs-on: ubuntu-latest
    environment: sit
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.SIT_OIDC_ROLE_ARN }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Terraform Init
        run: |
          cd terraform/environments/sit
          terraform init

      - name: Terraform Apply
        run: |
          cd terraform/environments/sit
          terraform plan -var-file=sit.tfvars -out=tfplan
          terraform apply -auto-approve tfplan

      - name: Integration Tests
        run: |
          python -m pytest tests/integration/ -v --environment sit

      - name: Notify Stakeholders
        uses: slackapi/slack-github-action@v1
        with:
          webhook-url: ${{ secrets.SLACK_WEBHOOK_SIT }}
          payload: |
            {
              "text": "✅ SIT deployment successful. Test URL: ${{ github.event.inputs.dev_test_url }}"
            }
```

**PROD Deployment Workflow (.github/workflows/deploy-prod.yml):**

```yaml
name: Deploy to PROD

on:
  workflow_dispatch:
    inputs:
      approve:
        description: 'Type "APPROVE-PROD" to deploy to PRODUCTION'
        required: true
        type: string
      uat_results_url:
        description: 'Link to SIT UAT results'
        required: true
        type: string
      rollback_plan_url:
        description: 'Link to rollback plan'
        required: true
        type: string

env:
  AWS_REGION_PRIMARY: af-south-1
  AWS_REGION_DR: eu-west-1
  TF_VERSION: 1.6.0

jobs:
  validate-approval:
    runs-on: ubuntu-latest
    steps:
      - name: Validate Strict Approval
        if: ${{ github.event.inputs.approve != 'APPROVE-PROD' }}
        run: |
          echo "ERROR: PROD deployment not approved. Type 'APPROVE-PROD' exactly."
          exit 1

  deploy-primary:
    needs: validate-approval
    runs-on: ubuntu-latest
    environment: prod
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}

      - name: Configure AWS Credentials (Primary)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.PROD_OIDC_ROLE_ARN }}
          aws-region: ${{ env.AWS_REGION_PRIMARY }}

      - name: Deploy to Primary Region (af-south-1)
        run: |
          cd terraform/environments/prod
          terraform init
          terraform plan -var-file=prod.tfvars -out=tfplan-primary
          terraform apply -auto-approve tfplan-primary

      - name: Smoke Tests (Primary)
        run: |
          python -m pytest tests/smoke/ -v --environment prod --region af-south-1

  deploy-dr:
    needs: deploy-primary
    runs-on: ubuntu-latest
    environment: prod
    steps:
      - uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}

      - name: Configure AWS Credentials (DR)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.PROD_OIDC_ROLE_ARN }}
          aws-region: ${{ env.AWS_REGION_DR }}

      - name: Deploy to DR Region (eu-west-1)
        run: |
          cd terraform/environments/prod
          terraform init
          terraform plan -var-file=prod.tfvars -var="aws_region=eu-west-1" -out=tfplan-dr
          terraform apply -auto-approve tfplan-dr

      - name: Validate DR Replication
        run: |
          # Check DynamoDB Global Table replication
          python tests/dr/validate_replication.py --source af-south-1 --target eu-west-1

      - name: Notify All Stakeholders
        uses: slackapi/slack-github-action@v1
        with:
          webhook-url: ${{ secrets.SLACK_WEBHOOK_PROD }}
          payload: |
            {
              "text": "✅ PROD deployment successful (Primary + DR). UAT: ${{ github.event.inputs.uat_results_url }}, Rollback Plan: ${{ github.event.inputs.rollback_plan_url }}"
            }
```

---

## 8. Disaster Recovery Strategy

### 8.1 Multi-Region Architecture (PROD Only)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                   Multi-Site Active/Active DR Architecture                 │
│                             PRODUCTION ONLY                                 │
└─────────────────────────────────────────────────────────────────────────────┘

    PRIMARY REGION: af-south-1                  DR REGION: eu-west-1
    (Cape Town)                                 (Dublin)
    ┌──────────────────────────┐               ┌──────────────────────────┐
    │  ✓ ACTIVE (Serving)      │               │  ✓ ACTIVE (Standby)      │
    │                          │               │                          │
    │  Route 53 (PRIMARY)      │               │  Route 53 (SECONDARY)    │
    │  ↓                       │               │  ↓                       │
    │  API Gateway (PROD)      │               │  API Gateway (PROD-DR)   │
    │  ↓                       │               │  ↓                       │
    │  Lambda Functions (8x)   │               │  Lambda Functions (8x)   │
    │  ↓                       │               │  ↓                       │
    │  DynamoDB (Global Table) │◄──Replicate──►│  DynamoDB (Replica)      │
    │  - Orders Table          │   < 1 sec     │  - Orders Table          │
    │  - GSIs (3x)             │               │  - GSIs (3x)             │
    │  ↓                       │               │  ↓                       │
    │  S3 Buckets              │◄──CRR────────►│  S3 Buckets              │
    │  - Email Templates       │   < 15 min    │  - Email Templates       │
    │  - Order PDFs            │               │  - Order PDFs            │
    │  ↓                       │               │  ↓                       │
    │  SQS Queues              │   (Separate)  │  SQS Queues              │
    │  - OrderCreationQueue    │               │  - OrderCreationQueue    │
    │  - DLQ                   │               │  - DLQ                   │
    └──────────────────────────┘               └──────────────────────────┘
              │                                          │
              └──────────────────┬───────────────────────┘
                                 │
                        Route 53 Health Check
                        (Endpoint: /health)
                        Interval: 30 seconds
                        Failure Threshold: 2
                                 │
                        If Primary Fails:
                        ↓ DNS Failover (60s TTL)
                        Route traffic to DR region
```

### 8.2 DynamoDB Global Tables Configuration

**Primary Table (af-south-1):**

```hcl
resource "aws_dynamodb_table" "orders" {
  provider     = aws.primary
  name         = "bbws-customer-portal-orders-prod"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "PK"
  range_key    = "SK"

  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  attribute {
    name = "tenantId"
    type = "S"
  }

  attribute {
    name = "createdAt"
    type = "S"
  }

  attribute {
    name = "orderNumber"
    type = "S"
  }

  # GSI 1: OrdersByTenantAndDate
  global_secondary_index {
    name            = "OrdersByTenantAndDate"
    hash_key        = "tenantId"
    range_key       = "createdAt"
    projection_type = "ALL"
  }

  # GSI 2: OrdersByDate
  global_secondary_index {
    name            = "OrdersByDate"
    hash_key        = "createdAt"
    projection_type = "ALL"
  }

  # GSI 3: OrderByNumber
  global_secondary_index {
    name            = "OrderByNumber"
    hash_key        = "orderNumber"
    projection_type = "ALL"
  }

  # Cross-region replication
  replica {
    region_name = "eu-west-1"
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Environment = "prod"
    Region      = "primary"
    DR          = "enabled"
  }
}
```

**Replication Monitoring:**

```hcl
resource "aws_cloudwatch_metric_alarm" "dynamodb_replication_latency" {
  alarm_name          = "bbws-orders-replication-latency-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ReplicationLatency"
  namespace           = "AWS/DynamoDB"
  period              = 300
  statistic           = "Average"
  threshold           = 5000  # 5 seconds
  alarm_description   = "DynamoDB replication latency is too high"
  alarm_actions       = [aws_sns_topic.prod_alerts.arn]

  dimensions = {
    TableName           = aws_dynamodb_table.orders.name
    ReceivingRegion     = "eu-west-1"
  }
}
```

### 8.3 S3 Cross-Region Replication

**Replication Configuration:**

```hcl
# Primary bucket (af-south-1)
resource "aws_s3_bucket" "orders_prod" {
  provider = aws.primary
  bucket   = "bbws-orders-prod"

  tags = {
    Environment = "prod"
    Region      = "primary"
  }
}

resource "aws_s3_bucket_versioning" "orders_prod" {
  provider = aws.primary
  bucket   = aws_s3_bucket.orders_prod.id

  versioning_configuration {
    status = "Enabled"
  }
}

# DR bucket (eu-west-1)
resource "aws_s3_bucket" "orders_prod_dr" {
  provider = aws.dr
  bucket   = "bbws-orders-prod-dr"

  tags = {
    Environment = "prod"
    Region      = "dr"
  }
}

resource "aws_s3_bucket_versioning" "orders_prod_dr" {
  provider = aws.dr
  bucket   = aws_s3_bucket.orders_prod_dr.id

  versioning_configuration {
    status = "Enabled"
  }
}

# IAM role for replication
resource "aws_iam_role" "s3_replication" {
  name = "bbws-s3-replication-role-prod"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "s3_replication" {
  name = "bbws-s3-replication-policy"
  role = aws_iam_role.s3_replication.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.orders_prod.arn
        ]
      },
      {
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl"
        ]
        Effect = "Allow"
        Resource = [
          "${aws_s3_bucket.orders_prod.arn}/*"
        ]
      },
      {
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete"
        ]
        Effect = "Allow"
        Resource = [
          "${aws_s3_bucket.orders_prod_dr.arn}/*"
        ]
      }
    ]
  })
}

# Replication rule
resource "aws_s3_bucket_replication_configuration" "orders" {
  provider = aws.primary
  role     = aws_iam_role.s3_replication.arn
  bucket   = aws_s3_bucket.orders_prod.id

  depends_on = [aws_s3_bucket_versioning.orders_prod]

  rule {
    id       = "replicate-all-objects"
    status   = "Enabled"
    priority = 1

    filter {}

    destination {
      bucket        = aws_s3_bucket.orders_prod_dr.arn
      storage_class = "STANDARD"

      replication_time {
        status = "Enabled"
        time {
          minutes = 15
        }
      }

      metrics {
        status = "Enabled"
        event_threshold {
          minutes = 15
        }
      }
    }

    delete_marker_replication {
      status = "Enabled"
    }
  }
}
```

### 8.4 Route 53 Failover Configuration

**DNS Failover Setup:**

```hcl
# Route 53 Hosted Zone
resource "aws_route53_zone" "main" {
  name = "bbws.io"

  tags = {
    Environment = "prod"
  }
}

# Health check for primary region
resource "aws_route53_health_check" "primary" {
  fqdn              = "api.bbws.io"
  port              = 443
  type              = "HTTPS"
  resource_path     = "/health"
  failure_threshold = 2
  request_interval  = 30
  measure_latency   = true

  alarm_identifier {
    name   = aws_cloudwatch_metric_alarm.api_health.alarm_name
    region = "us-east-1"  # CloudWatch alarms for Route 53 must be in us-east-1
  }

  tags = {
    Name = "bbws-api-primary-health-check"
  }
}

# CloudWatch alarm for health check
resource "aws_cloudwatch_metric_alarm" "api_health" {
  provider            = aws.us_east_1  # Must be us-east-1
  alarm_name          = "bbws-api-primary-health-failure"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = 60
  statistic           = "Minimum"
  threshold           = 1
  alarm_description   = "Primary API health check failed"
  alarm_actions       = [aws_sns_topic.prod_alerts.arn]

  dimensions = {
    HealthCheckId = aws_route53_health_check.primary.id
  }
}

# Primary record (af-south-1)
resource "aws_route53_record" "api_primary" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "api.bbws.io"
  type    = "A"

  set_identifier = "primary-af-south-1"

  failover_routing_policy {
    type = "PRIMARY"
  }

  alias {
    name                   = aws_api_gateway_domain_name.primary.regional_domain_name
    zone_id                = aws_api_gateway_domain_name.primary.regional_zone_id
    evaluate_target_health = true
  }

  health_check_id = aws_route53_health_check.primary.id
}

# Secondary record (eu-west-1)
resource "aws_route53_record" "api_secondary" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "api.bbws.io"
  type    = "A"

  set_identifier = "secondary-eu-west-1"

  failover_routing_policy {
    type = "SECONDARY"
  }

  alias {
    name                   = aws_api_gateway_domain_name.secondary.regional_domain_name
    zone_id                = aws_api_gateway_domain_name.secondary.regional_zone_id
    evaluate_target_health = true
  }
}
```

### 8.5 RTO/RPO Targets and Validation

| Metric | Target | How Achieved | Validation Method |
|--------|--------|--------------|-------------------|
| **RTO** | < 1 hour | Route 53 DNS failover (30-60s) + health check detection (30-60s) + manual validation (~30 min) | Monthly failover drill |
| **RPO** | < 5 minutes | DynamoDB Global Tables (< 1s replication) + S3 CRR (< 15 min) + hourly backups | Replication lag monitoring |

**RTO Breakdown:**
1. Health check failure detection: 60 seconds (2 failed checks @ 30s interval)
2. Route 53 DNS failover: 60 seconds (DNS TTL)
3. Client DNS cache expiry: 60 seconds
4. Manual validation and testing: 30 minutes (verify DR region fully functional)
5. **Total RTO: ~32 minutes** (well within < 1 hour target)

**RPO Breakdown:**
1. DynamoDB replication: < 1 second (Global Tables)
2. S3 replication: < 15 minutes (S3 Replication Time Control)
3. Hourly backups: Last backup within 60 minutes
4. **Total RPO: < 5 minutes** (data loss limited to in-flight S3 objects)

**Failover Testing Procedure (Monthly):**

```bash
#!/bin/bash
# Monthly DR Failover Test

# Step 1: Simulate primary region failure
echo "Step 1: Simulating primary region failure..."
aws route53 change-resource-record-sets \
  --hosted-zone-id Z1234567890ABC \
  --change-batch file://failover-to-dr.json

# Step 2: Verify DNS resolution
echo "Step 2: Verifying DNS failover..."
dig api.bbws.io +short

# Step 3: Test API endpoints in DR region
echo "Step 3: Testing API endpoints in DR region..."
curl -X GET https://api.bbws.io/health -H "x-region-test: eu-west-1"

# Step 4: Verify DynamoDB replication
echo "Step 4: Checking DynamoDB replication status..."
aws dynamodb describe-table \
  --table-name bbws-customer-portal-orders-prod \
  --region eu-west-1

# Step 5: Verify S3 replication
echo "Step 5: Checking S3 replication metrics..."
aws s3api get-bucket-replication \
  --bucket bbws-orders-prod \
  --region af-south-1

# Step 6: Run smoke tests against DR region
echo "Step 6: Running smoke tests..."
python -m pytest tests/smoke/ -v --environment prod --region eu-west-1

# Step 7: Failback to primary
echo "Step 7: Failing back to primary region..."
aws route53 change-resource-record-sets \
  --hosted-zone-id Z1234567890ABC \
  --change-batch file://failback-to-primary.json

# Step 8: Document results
echo "Step 8: Documenting test results..."
echo "Test Date: $(date)" >> dr-test-results.log
echo "RTO Achieved: <measured time>" >> dr-test-results.log
echo "RPO Verified: <data consistency check>" >> dr-test-results.log
```

---

## 9. Environment-Specific Configurations

### 9.1 Lambda Configuration by Environment

| Setting | DEV | SIT | PROD |
|---------|-----|-----|------|
| **Memory** | 512 MB | 512 MB | 512 MB |
| **Timeout** | 30 seconds | 30 seconds | 30 seconds |
| **Reserved Concurrency** | None (unlimited) | 10 (controlled) | 50 (high availability) |
| **Provisioned Concurrency** | 0 | 0 | 20 (OrderCreatorRecord only) |
| **Ephemeral Storage** | 512 MB | 512 MB | 512 MB |
| **Log Retention** | 7 days | 30 days | 90 days |
| **X-Ray Tracing** | Disabled (cost savings) | Enabled (debugging) | Enabled (monitoring) |
| **Environment Variables** | Standard + DEBUG=true | Standard | Standard + PRODUCTION=true |
| **VPC** | No VPC (public Lambda) | VPC-attached | VPC-attached (private subnets) |
| **Dead Letter Queue** | Enabled | Enabled | Enabled |

**Lambda Environment Variables (Example for create_order):**

**DEV:**
```hcl
environment {
  variables = {
    ENVIRONMENT           = "dev"
    DYNAMODB_TABLE        = "bbws-customer-portal-orders-dev"
    SQS_QUEUE_URL         = "https://sqs.eu-west-1.amazonaws.com/536580886816/bbws-order-creation-dev"
    LOG_LEVEL             = "DEBUG"
    ENABLE_XRAY           = "false"
    AWS_REGION            = "eu-west-1"
  }
}
```

**SIT:**
```hcl
environment {
  variables = {
    ENVIRONMENT           = "sit"
    DYNAMODB_TABLE        = "bbws-customer-portal-orders-sit"
    SQS_QUEUE_URL         = "https://sqs.eu-west-1.amazonaws.com/815856636111/bbws-order-creation-sit"
    LOG_LEVEL             = "INFO"
    ENABLE_XRAY           = "true"
    AWS_REGION            = "eu-west-1"
  }
}
```

**PROD:**
```hcl
environment {
  variables = {
    ENVIRONMENT           = "prod"
    DYNAMODB_TABLE        = "bbws-customer-portal-orders-prod"
    SQS_QUEUE_URL         = "https://sqs.af-south-1.amazonaws.com/093646564004/bbws-order-creation-prod"
    LOG_LEVEL             = "WARN"
    ENABLE_XRAY           = "true"
    AWS_REGION            = "af-south-1"
    FAILOVER_REGION       = "eu-west-1"
  }
}
```

### 9.2 SES Configuration by Environment

| Setting | DEV | SIT | PROD |
|---------|-----|-----|------|
| **Sending Quota** | 1 email/sec (200/day) | 10 emails/sec (5,000/day) | 50 emails/sec (50,000/day) |
| **From Address** | test@kimmyai.io | noreply@kimmyai.io | noreply@kimmyai.io |
| **Domain Verification** | Not required | kimmyai.io (verified) | kimmyai.io (verified) |
| **Bounce Handling** | Disabled | SNS notifications | SNS + automated suppression list |
| **Complaint Handling** | Disabled | SNS notifications | SNS + automated suppression list |
| **Configuration Set** | None | bbws-emails-sit | bbws-emails-prod (with event publishing) |
| **Reputation Dashboard** | Not monitored | Monitored | Actively monitored + alerts |

**SES Configuration Set (PROD):**

```hcl
resource "aws_ses_configuration_set" "prod" {
  name = "bbws-emails-prod"

  reputation_metrics_enabled = true
  sending_enabled            = true
}

resource "aws_ses_event_destination" "prod_cloudwatch" {
  name                   = "cloudwatch-destination"
  configuration_set_name = aws_ses_configuration_set.prod.name
  enabled                = true
  matching_types         = ["send", "bounce", "complaint", "delivery", "reject"]

  cloudwatch_destination {
    default_value  = "default"
    dimension_name = "ses:configuration-set"
    value_source   = "messageTag"
  }
}

resource "aws_ses_event_destination" "prod_sns" {
  name                   = "sns-destination"
  configuration_set_name = aws_ses_configuration_set.prod.name
  enabled                = true
  matching_types         = ["bounce", "complaint"]

  sns_destination {
    topic_arn = aws_sns_topic.ses_events.arn
  }
}
```

### 9.3 CloudWatch Configuration by Environment

| Setting | DEV | SIT | PROD |
|---------|-----|-----|------|
| **Log Retention** | 7 days | 30 days | 90 days |
| **Detailed Metrics** | No (5-min intervals) | Yes (1-min intervals) | Yes (1-min intervals) |
| **Dashboard** | No | Yes (service-level) | Yes (executive + service-level) |
| **Alarms Enabled** | No | Yes (critical only) | Yes (comprehensive) |
| **Alarm SNS Topic** | None | bbws-alerts-sit | bbws-alerts-prod |
| **Lambda Insights** | Disabled | Enabled | Enabled |
| **X-Ray Tracing** | Disabled | Enabled | Enabled |
| **Contributor Insights** | Disabled | Disabled | Enabled (DynamoDB) |

**CloudWatch Alarms (PROD):**

```hcl
# Lambda error rate alarm
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "bbws-order-lambda-errors-prod"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 3
  alarm_description   = "Lambda function errors exceeded threshold"
  alarm_actions       = [aws_sns_topic.prod_alerts.arn]

  dimensions = {
    FunctionName = aws_lambda_function.create_order.function_name
  }
}

# DynamoDB throttling alarm
resource "aws_cloudwatch_metric_alarm" "dynamodb_throttling" {
  alarm_name          = "bbws-orders-dynamodb-throttling-prod"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UserErrors"
  namespace           = "AWS/DynamoDB"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "DynamoDB throttling detected"
  alarm_actions       = [aws_sns_topic.prod_alerts.arn]

  dimensions = {
    TableName = aws_dynamodb_table.orders.name
  }
}

# API Gateway 5xx errors
resource "aws_cloudwatch_metric_alarm" "api_gateway_5xx" {
  alarm_name          = "bbws-order-api-5xx-errors-prod"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "5XXError"
  namespace           = "AWS/ApiGateway"
  period              = 300
  statistic           = "Sum"
  threshold           = 2
  alarm_description   = "API Gateway 5xx errors detected"
  alarm_actions       = [aws_sns_topic.prod_alerts.arn]

  dimensions = {
    ApiName = aws_api_gateway_rest_api.orders.name
  }
}

# DLQ message count alarm
resource "aws_cloudwatch_metric_alarm" "dlq_messages" {
  alarm_name          = "bbws-order-dlq-messages-prod"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Messages in DLQ - investigate failures"
  alarm_actions       = [aws_sns_topic.prod_alerts.arn]

  dimensions = {
    QueueName = aws_sqs_queue.order_creation_dlq.name
  }
}
```

### 9.4 Cost Optimization by Environment

| Strategy | DEV | SIT | PROD |
|----------|-----|-----|------|
| **Lambda Reserved Concurrency** | None (cost savings) | 10 (controlled) | 50 (performance) |
| **Lambda Provisioned Concurrency** | None | None | 20 (OrderCreatorRecord) |
| **DynamoDB Capacity Mode** | On-Demand | On-Demand | On-Demand (mandatory) |
| **S3 Lifecycle Policies** | 30-day deletion | 60-day deletion | 7-year retention (Glacier after 2 years) |
| **S3 Intelligent Tiering** | No | No | Yes (order PDFs) |
| **NAT Gateway** | Single NAT (1 AZ) | 2 NATs (2 AZs) | 3 NATs (3 AZs) |
| **VPC Endpoints** | None | S3, DynamoDB | S3, DynamoDB, SQS, SNS, SES |
| **Backup Frequency** | Daily | Daily | Hourly |
| **Backup Retention** | 7 days | 14 days | 90 days |
| **Cross-Region Replication** | No | No | Yes (DR requirement) |
| **Reserved Capacity** | No | No | Consider for stable workloads |
| **Spot Instances** | N/A (serverless) | N/A (serverless) | N/A (serverless) |

**Cost Estimation (Monthly):**

| Service | DEV | SIT | PROD |
|---------|-----|-----|------|
| **Lambda** | $50 | $100 | $500 |
| **DynamoDB** | $30 | $80 | $800 |
| **S3** | $10 | $20 | $150 |
| **SQS** | $5 | $10 | $50 |
| **API Gateway** | $20 | $50 | $400 |
| **CloudWatch** | $10 | $30 | $100 |
| **Data Transfer** | $10 | $20 | $200 |
| **Backups** | $5 | $15 | $150 |
| **Cross-Region Replication** | $0 | $0 | $300 |
| **NAT Gateway** | $35 | $70 | $105 |
| **VPC Endpoints** | $0 | $15 | $50 |
| **Route 53** | $1 | $1 | $5 |
| **Total Estimated** | **~$176** | **~$411** | **~$2,810** |
| **Budget Allocated** | $500 | $1,000 | $5,000 |
| **Buffer** | 2.8x | 2.4x | 1.8x |

---

## 10. Access Control and Security

### 10.1 IAM Policies by Environment

**DEV IAM Policy (Permissive for Development):**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "LambdaExecution",
      "Effect": "Allow",
      "Action": [
        "lambda:InvokeFunction",
        "lambda:UpdateFunctionCode",
        "lambda:UpdateFunctionConfiguration",
        "lambda:GetFunction",
        "lambda:ListFunctions"
      ],
      "Resource": "arn:aws:lambda:af-south-1:536580886816:function:bbws-order-*-dev"
    },
    {
      "Sid": "DynamoDBAccess",
      "Effect": "Allow",
      "Action": [
        "dynamodb:PutItem",
        "dynamodb:GetItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem",
        "dynamodb:Query",
        "dynamodb:Scan",
        "dynamodb:BatchWriteItem",
        "dynamodb:BatchGetItem"
      ],
      "Resource": [
        "arn:aws:dynamodb:af-south-1:536580886816:table/bbws-customer-portal-orders-dev",
        "arn:aws:dynamodb:af-south-1:536580886816:table/bbws-customer-portal-orders-dev/index/*"
      ]
    },
    {
      "Sid": "SQSAccess",
      "Effect": "Allow",
      "Action": [
        "sqs:SendMessage",
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes",
        "sqs:GetQueueUrl"
      ],
      "Resource": [
        "arn:aws:sqs:af-south-1:536580886816:bbws-order-*-dev",
        "arn:aws:sqs:af-south-1:536580886816:bbws-order-*-dlq-dev"
      ]
    },
    {
      "Sid": "S3Access",
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::bbws-*-dev",
        "arn:aws:s3:::bbws-*-dev/*"
      ]
    },
    {
      "Sid": "CloudWatchLogs",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:af-south-1:536580886816:log-group:/aws/lambda/bbws-order-*-dev:*"
    }
  ]
}
```

**SIT IAM Policy (Balanced for Testing):**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "LambdaExecution",
      "Effect": "Allow",
      "Action": [
        "lambda:InvokeFunction",
        "lambda:GetFunction"
      ],
      "Resource": "arn:aws:lambda:af-south-1:815856636111:function:bbws-order-*-sit"
    },
    {
      "Sid": "DynamoDBAccess",
      "Effect": "Allow",
      "Action": [
        "dynamodb:PutItem",
        "dynamodb:GetItem",
        "dynamodb:UpdateItem",
        "dynamodb:Query",
        "dynamodb:BatchWriteItem",
        "dynamodb:BatchGetItem"
      ],
      "Resource": [
        "arn:aws:dynamodb:af-south-1:815856636111:table/bbws-customer-portal-orders-sit",
        "arn:aws:dynamodb:af-south-1:815856636111:table/bbws-customer-portal-orders-sit/index/*"
      ]
    },
    {
      "Sid": "DynamoDBReadOnly",
      "Effect": "Deny",
      "Action": [
        "dynamodb:DeleteItem",
        "dynamodb:DeleteTable"
      ],
      "Resource": "arn:aws:dynamodb:af-south-1:815856636111:table/bbws-customer-portal-orders-sit"
    },
    {
      "Sid": "SQSAccess",
      "Effect": "Allow",
      "Action": [
        "sqs:SendMessage",
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes"
      ],
      "Resource": [
        "arn:aws:sqs:af-south-1:815856636111:bbws-order-*-sit",
        "arn:aws:sqs:af-south-1:815856636111:bbws-order-*-dlq-sit"
      ]
    },
    {
      "Sid": "S3Access",
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::bbws-*-sit",
        "arn:aws:s3:::bbws-*-sit/*"
      ]
    },
    {
      "Sid": "CloudWatchLogs",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:af-south-1:815856636111:log-group:/aws/lambda/bbws-order-*-sit:*"
    },
    {
      "Sid": "XRayTracing",
      "Effect": "Allow",
      "Action": [
        "xray:PutTraceSegments",
        "xray:PutTelemetryRecords"
      ],
      "Resource": "*"
    }
  ]
}
```

**PROD IAM Policy (Least Privilege, Read-Only for Claude):**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "LambdaExecution",
      "Effect": "Allow",
      "Action": [
        "lambda:InvokeFunction"
      ],
      "Resource": "arn:aws:lambda:*:093646564004:function:bbws-order-*-prod*",
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": ["af-south-1", "eu-west-1"]
        }
      }
    },
    {
      "Sid": "DynamoDBReadWrite",
      "Effect": "Allow",
      "Action": [
        "dynamodb:PutItem",
        "dynamodb:GetItem",
        "dynamodb:UpdateItem",
        "dynamodb:Query",
        "dynamodb:BatchGetItem"
      ],
      "Resource": [
        "arn:aws:dynamodb:*:093646564004:table/bbws-customer-portal-orders-prod",
        "arn:aws:dynamodb:*:093646564004:table/bbws-customer-portal-orders-prod/index/*"
      ]
    },
    {
      "Sid": "DynamoDBDeleteDeny",
      "Effect": "Deny",
      "Action": [
        "dynamodb:DeleteItem",
        "dynamodb:DeleteTable",
        "dynamodb:BatchWriteItem"
      ],
      "Resource": "arn:aws:dynamodb:*:093646564004:table/bbws-customer-portal-orders-prod"
    },
    {
      "Sid": "SQSAccess",
      "Effect": "Allow",
      "Action": [
        "sqs:SendMessage",
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes"
      ],
      "Resource": [
        "arn:aws:sqs:*:093646564004:bbws-order-*-prod*"
      ]
    },
    {
      "Sid": "S3ReadWrite",
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject"
      ],
      "Resource": [
        "arn:aws:s3:::bbws-*-prod/*",
        "arn:aws:s3:::bbws-*-prod-dr/*"
      ]
    },
    {
      "Sid": "S3DeleteDeny",
      "Effect": "Deny",
      "Action": [
        "s3:DeleteObject",
        "s3:DeleteBucket"
      ],
      "Resource": [
        "arn:aws:s3:::bbws-*-prod",
        "arn:aws:s3:::bbws-*-prod/*"
      ]
    },
    {
      "Sid": "CloudWatchLogs",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:093646564004:log-group:/aws/lambda/bbws-order-*-prod*:*"
    },
    {
      "Sid": "XRayTracing",
      "Effect": "Allow",
      "Action": [
        "xray:PutTraceSegments",
        "xray:PutTelemetryRecords"
      ],
      "Resource": "*"
    },
    {
      "Sid": "KMSEncryption",
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt",
        "kms:Encrypt",
        "kms:GenerateDataKey"
      ],
      "Resource": "arn:aws:kms:*:093646564004:key/*",
      "Condition": {
        "StringEquals": {
          "kms:ViaService": [
            "dynamodb.af-south-1.amazonaws.com",
            "dynamodb.eu-west-1.amazonaws.com",
            "s3.af-south-1.amazonaws.com",
            "s3.eu-west-1.amazonaws.com"
          ]
        }
      }
    }
  ]
}
```

### 10.2 Environment-Specific Security Policies

| Security Control | DEV | SIT | PROD |
|------------------|-----|-----|------|
| **MFA Required** | No | Yes (for human access) | Yes (mandatory) |
| **IP Whitelisting** | No | No | Yes (API Gateway resource policy) |
| **VPC Attachment** | No (public Lambda) | Yes (private subnets) | Yes (private subnets) |
| **Encryption at Rest** | AWS-managed KMS | AWS-managed KMS | Customer-managed KMS |
| **Encryption in Transit** | TLS 1.2+ | TLS 1.2+ | TLS 1.3 |
| **Secrets Management** | Environment variables | AWS Secrets Manager | AWS Secrets Manager (auto-rotation) |
| **IAM Password Policy** | Standard | Strong (12+ chars) | Strong (16+ chars, symbols) |
| **Access Key Rotation** | 90 days | 60 days | 30 days |
| **CloudTrail Logging** | Disabled | Enabled | Enabled (multi-region) |
| **GuardDuty** | Disabled | Enabled | Enabled (with automated responses) |
| **AWS Config** | Disabled | Enabled | Enabled (compliance rules) |
| **WAF (API Gateway)** | No | No | Yes (rate limiting, geo-blocking) |

### 10.3 Sensitive Data Handling

**DEV:**
- Use synthetic/anonymized test data only
- No real customer data permitted
- PII fields can be clear text for debugging

**SIT:**
- Non-sensitive test data (realistic volume)
- Masked PII where possible
- No credit card numbers or real financial data

**PROD:**
- Real customer data (PCI DSS compliant)
- All PII encrypted at rest (KMS)
- Credit card data tokenized (never stored in DynamoDB)
- Audit logging enabled for all data access
- Data retention: 7 years (compliance requirement)
- GDPR right to erasure: Soft delete with retention flags

---

## Issues/Blockers

**None identified at this time.**

All environment configurations are well-defined and aligned with BBWS standards. Terraform backend buckets and DynamoDB lock tables must be created manually before first deployment (see Section 6.3).

---

## Appendix: Quick Reference

### Environment Quick Reference Table

| Attribute | DEV | SIT | PROD |
|-----------|-----|-----|------|
| **Account** | 536580886816 | 815856636111 | 093646564004 |
| **Region** | af-south-1 | af-south-1 | af-south-1 + eu-west-1 |
| **DynamoDB Table** | bbws-customer-portal-orders-dev | bbws-customer-portal-orders-sit | bbws-customer-portal-orders-prod |
| **SQS Queue** | bbws-order-creation-dev | bbws-order-creation-sit | bbws-order-creation-prod |
| **S3 Bucket (Templates)** | bbws-email-templates-dev | bbws-email-templates-sit | bbws-email-templates-prod |
| **S3 Bucket (Orders)** | bbws-orders-dev | bbws-orders-sit | bbws-orders-prod |
| **API Gateway** | https://api-dev.bbws.io | https://api-sit.bbws.io | https://api.bbws.io |
| **Terraform State** | s3://bbws-terraform-state-dev/order-lambda/ | s3://bbws-terraform-state-sit/order-lambda/ | s3://bbws-terraform-state-prod/order-lambda/ |
| **OIDC Role** | arn:aws:iam::536580886816:role/github-2-bbws-order-lambda-dev | arn:aws:iam::815856636111:role/github-2-bbws-order-lambda-sit | arn:aws:iam::093646564004:role/github-2-bbws-order-lambda-prod |
| **Budget** | $500/month | $1,000/month | $5,000/month |
| **Approvers** | 1 (Lead Dev) | 2 (Tech Lead + QA) | 3 (Tech Lead + PO + DevOps) |

### Deployment Commands Quick Reference

```bash
# DEV Deployment
cd terraform/environments/dev
terraform init
terraform plan -var-file=dev.tfvars -out=tfplan
terraform apply tfplan

# SIT Deployment
cd terraform/environments/sit
terraform init
terraform plan -var-file=sit.tfvars -out=tfplan
terraform apply tfplan

# PROD Deployment (Primary + DR)
cd terraform/environments/prod
terraform init

# Primary region
terraform plan -var-file=prod.tfvars -out=tfplan-primary
terraform apply tfplan-primary

# DR region
terraform plan -var-file=prod.tfvars -var="aws_region=eu-west-1" -out=tfplan-dr
terraform apply tfplan-dr
```

---

**End of Worker 4 Environment Analysis Output**
