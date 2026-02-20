# Product Lambda - Microservices Implementation Plan

**Date**: 2025-12-27
**LLD Reference**: 2.1.4_LLD_Product_Lambda.md
**Architecture**: Microservices (8 repositories)
**Status**: ✅ Ready to Execute

---

## Executive Summary

Based on user answers, implementing Product Lambda service as **true microservices architecture**:
- **8 repositories** (1 infrastructure + 7 Lambda functions)
- Each Lambda has dedicated repo, terraform, and CI/CD pipeline
- Shared code duplicated across repos (no external dependencies)
- Infrastructure deployed first, then Lambda functions reference it

---

## User Answers Summary

| Question | Answer | Impact |
|----------|--------|--------|
| Q1: Repo creation | Create new local repos | Initialize 8 new repos locally |
| Q2: Search | DynamoDB GSI | No OpenSearch, skip search indexer Lambda |
| Q3: CloudFront | Skip for now | Skip cache invalidator Lambda |
| Q4: S3 Audit | Create new bucket + Glacier after 1yr | New S3 resource in infrastructure |
| Q5: DynamoDB | New table `products` in Lambda repo | Create in infrastructure repo |
| Q6: API Gateway | Create new REST API | New API Gateway in infrastructure |
| Q7: Authentication | API Key (store in file) | API Keys in infrastructure, reference in Lambdas |
| Q8: Event-driven | All 4 functions, separate repos | 7 Lambda repos (5 API + 2 event-driven) |
| Q9: SQS | Dedicated queue with DLQ | SQS in infrastructure repo |
| Q10: Testing | Full TDD, 80%+ coverage | Write tests first for each Lambda |
| Q11: Dependencies | requirements.txt | Simple dependency management |
| Q12: Packaging | Zip file | Standard Lambda deployment |
| Q13: CI/CD | Manual dispatch for all envs | Manual approval for DEV/SIT/PROD |
| Q14: Monitoring | Full monitoring + SNS | CloudWatch alarms in each repo |
| Q15: Seeding | No seeding | Start with empty table |

---

## Repository Architecture

### 1. Infrastructure Repository (Foundation)

**Repository**: `2_1_bbws_product_infrastructure`
**Purpose**: Shared infrastructure resources
**Deploy Order**: **FIRST** (all Lambdas depend on this)

**Creates**:
- ✅ API Gateway REST API: `bbws-product-api-{env}`
- ✅ DynamoDB Table: `products` (on-demand capacity)
- ✅ SQS Queue: `bbws-product-change-{env}`
- ✅ SQS DLQ: `bbws-product-change-dlq-{env}`
- ✅ S3 Bucket: `bbws-product-audit-logs-{env}` (Glacier after 1 year)
- ✅ SNS Topic: `bbws-product-alerts-{env}`
- ✅ API Keys: Stored in AWS Secrets Manager + local file
- ✅ IAM Roles: Base execution roles for Lambdas

**Terraform Outputs** (for Lambda repos):
```hcl
output "api_gateway_id" { value = aws_api_gateway_rest_api.product_api.id }
output "api_gateway_execution_arn" { value = aws_api_gateway_rest_api.product_api.execution_arn }
output "api_gateway_root_resource_id" { value = aws_api_gateway_rest_api.product_api.root_resource_id }
output "dynamodb_table_name" { value = aws_dynamodb_table.products.name }
output "dynamodb_table_arn" { value = aws_dynamodb_table.products.arn }
output "sqs_queue_url" { value = aws_sqs_queue.product_change.url }
output "sqs_queue_arn" { value = aws_sqs_queue.product_change.arn }
output "s3_audit_bucket_name" { value = aws_s3_bucket.audit_logs.bucket }
output "sns_topic_arn" { value = aws_sns_topic.alerts.arn }
output "api_key_id" { value = aws_api_gateway_api_key.product_api_key.id }
```

---

### 2. API Handler Lambda Repositories (5 repos)

#### 2.1 List Products Lambda
**Repository**: `2_1_bbws_list_products`
**Endpoint**: `GET /v1.0/products`
**Function**: List all active products with pagination
**Dependencies**: DynamoDB table, API Gateway

**Structure**:
```
2_1_bbws_list_products/
├── src/
│   ├── handler.py              # Lambda entry point
│   ├── models/
│   │   └── product.py          # Product Pydantic model
│   ├── repositories/
│   │   └── product_repository.py
│   ├── services/
│   │   └── product_service.py
│   └── utils/
│       ├── response_builder.py
│       └── logger.py
├── tests/
│   ├── unit/
│   └── integration/
├── terraform/
│   ├── main.tf
│   ├── lambda.tf
│   ├── api_gateway_integration.tf
│   ├── iam.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── data.tf                 # Import infrastructure outputs
│   └── environments/
│       ├── dev.tfvars
│       ├── sit.tfvars
│       └── prod.tfvars
├── .github/workflows/
│   ├── deploy-dev.yml
│   ├── deploy-sit.yml
│   └── deploy-prod.yml
├── requirements.txt
├── requirements-dev.txt
├── pytest.ini
├── .gitignore
└── README.md
```

---

#### 2.2 Get Product Lambda
**Repository**: `2_1_bbws_get_product`
**Endpoint**: `GET /v1.0/products/{productId}`
**Function**: Get single product by ID
**Dependencies**: DynamoDB table, API Gateway

*(Same structure as 2.1)*

---

#### 2.3 Create Product Lambda
**Repository**: `2_1_bbws_create_product`
**Endpoint**: `POST /v1.0/products`
**Function**: Validate product and publish to SQS (returns 202 Accepted)
**Dependencies**: SQS queue, API Gateway

*(Same structure as 2.1)*

---

#### 2.4 Update Product Lambda
**Repository**: `2_1_bbws_update_product`
**Endpoint**: `PUT /v1.0/products/{productId}`
**Function**: Validate product update and publish to SQS (returns 202 Accepted)
**Dependencies**: SQS queue, API Gateway

*(Same structure as 2.1)*

---

#### 2.5 Delete Product Lambda
**Repository**: `2_1_bbws_delete_product`
**Endpoint**: `DELETE /v1.0/products/{productId}`
**Function**: Soft delete product via SQS (returns 204 No Content)
**Dependencies**: SQS queue, API Gateway

*(Same structure as 2.1)*

---

### 3. Event-Driven Lambda Repositories (2 repos)

#### 3.1 Product Creator Lambda
**Repository**: `2_1_bbws_product_creator`
**Trigger**: SQS `bbws-product-change-{env}`
**Function**: Process CREATE/UPDATE/DELETE events, write to DynamoDB
**Dependencies**: SQS queue, DynamoDB table

**Structure**:
```
2_1_bbws_product_creator/
├── src/
│   ├── handler.py              # SQS event handler
│   ├── models/
│   │   ├── product.py
│   │   └── events.py           # SQS message schemas
│   ├── repositories/
│   │   └── product_repository.py
│   ├── services/
│   │   └── product_service.py
│   └── utils/
│       └── logger.py
├── tests/
│   ├── unit/
│   └── integration/
├── terraform/
│   ├── main.tf
│   ├── lambda.tf
│   ├── sqs_event_source.tf    # SQS trigger
│   ├── iam.tf
│   ├── cloudwatch.tf           # DLQ alarms
│   ├── variables.tf
│   ├── data.tf                 # Import infrastructure
│   └── environments/
├── .github/workflows/
├── requirements.txt
└── README.md
```

---

#### 3.2 Audit Logger Lambda
**Repository**: `2_1_bbws_audit_logger`
**Trigger**: SQS `bbws-product-change-{env}`
**Function**: Log product changes to S3 for compliance
**Dependencies**: SQS queue, S3 bucket

*(Same structure as 3.1, but writes to S3 instead of DynamoDB)*

---

## Shared Code Strategy

**Decision**: Duplicate code in each repo (Q2: Option A)

**Shared Components** (duplicated):
- `models/product.py` - Pydantic Product model
- `models/events.py` - SQS event schemas
- `utils/response_builder.py` - API response formatting
- `utils/logger.py` - CloudWatch logging utility

**Why Duplication**:
- ✅ No external dependencies
- ✅ Each Lambda independently deployable
- ✅ Simpler CI/CD
- ✅ No version conflicts
- ❌ Code changes need manual sync (acceptable trade-off)

---

## Deployment Order

### Step 1: Infrastructure (Day 1)
```bash
# Create and deploy infrastructure repository
cd /Users/tebogotseka/Documents/agentic_work/2_1_bbws_product_infrastructure
terraform init
terraform plan -var-file=environments/dev.tfvars
terraform apply -var-file=environments/dev.tfvars

# Outputs: API Gateway ID, DynamoDB table name, SQS queue URL, etc.
```

### Step 2: API Handler Lambdas (Days 2-6, parallel)
Deploy in any order (no dependencies between them):
1. `2_1_bbws_list_products`
2. `2_1_bbws_get_product`
3. `2_1_bbws_create_product`
4. `2_1_bbws_update_product`
5. `2_1_bbws_delete_product`

### Step 3: Event-Driven Lambdas (Days 7-8, parallel)
Deploy in any order:
6. `2_1_bbws_product_creator`
7. `2_1_bbws_audit_logger`

### Step 4: Integration Testing (Days 9-10)
- Test complete CRUD flows
- Test event-driven processing
- Verify SQS → DynamoDB → S3 pipeline

---

## Implementation Timeline

| Phase | Duration | Repositories | Deliverables |
|-------|----------|--------------|--------------|
| **Phase 1: Infrastructure** | 1 day | 1 repo | API GW, DynamoDB, SQS, S3, SNS |
| **Phase 2: API Handlers** | 5 days | 5 repos | 5 Lambda functions + tests |
| **Phase 3: Event-Driven** | 2 days | 2 repos | 2 Lambda functions + tests |
| **Phase 4: Integration** | 2 days | All repos | E2E testing, monitoring |
| **Total** | **10 days** | **8 repos** | Complete microservices |

---

## Terraform Data Source Pattern

Each Lambda repository imports infrastructure outputs using `terraform_remote_state`:

**Example** (in Lambda repo's `data.tf`):
```hcl
data "terraform_remote_state" "infrastructure" {
  backend = "s3"
  config = {
    bucket = "bbws-terraform-state-${var.environment}"
    key    = "product-infrastructure/terraform.tfstate"
    region = var.aws_region
  }
}

locals {
  api_gateway_id       = data.terraform_remote_state.infrastructure.outputs.api_gateway_id
  dynamodb_table_name  = data.terraform_remote_state.infrastructure.outputs.dynamodb_table_name
  sqs_queue_url        = data.terraform_remote_state.infrastructure.outputs.sqs_queue_url
  api_key_id           = data.terraform_remote_state.infrastructure.outputs.api_key_id
}
```

---

## CI/CD Pipeline (Per Repository)

**All environments use manual workflow dispatch** (Q13: Option B)

**DEV Workflow** (.github/workflows/deploy-dev.yml):
```yaml
name: Deploy to DEV
on:
  workflow_dispatch:
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Run tests
      - name: Terraform plan
      - name: Manual approval (GitHub environment)
      - name: Terraform apply
      - name: Smoke tests
```

**SIT/PROD Workflows**: Same pattern with stricter approval gates

---

## API Key Management (Q7)

**Infrastructure repo creates API keys**:

1. **AWS Secrets Manager**: Store API key securely
   ```hcl
   resource "aws_secretsmanager_secret" "api_key" {
     name = "bbws/product-api/key-${var.environment}"
   }
   ```

2. **Local file**: Export for development
   ```bash
   # infrastructure/outputs/api-keys-dev.txt
   API_KEY_DEV=abcd1234efgh5678
   ```

3. **Lambda repos reference**: Import from Secrets Manager
   ```python
   import boto3
   secrets_client = boto3.client('secretsmanager')
   api_key = secrets_client.get_secret_value(SecretId='bbws/product-api/key-dev')
   ```

---

## DynamoDB Schema

**Table Name**: `products`
**Capacity Mode**: ON_DEMAND
**Created In**: Infrastructure repository

**Schema** (from LLD):
```hcl
resource "aws_dynamodb_table" "products" {
  name           = "products"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "PK"
  range_key      = "SK"

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  attribute {
    name = "GSI1_PK"
    type = "S"
  }

  attribute {
    name = "GSI1_SK"
    type = "S"
  }

  attribute {
    name = "GSI2_PK"  # For product name search
    type = "S"
  }

  global_secondary_index {
    name            = "ProductsByPriceIndex"
    hash_key        = "GSI1_PK"
    range_key       = "GSI1_SK"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "ProductsByNameIndex"  # For search (no OpenSearch)
    hash_key        = "GSI2_PK"
    projection_type = "ALL"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Project     = "BBWS"
    Component   = "ProductInfrastructure"
    Environment = var.environment
  }
}
```

---

## Monitoring (Q14: Full Monitoring)

**Each Lambda repository** creates:
- CloudWatch Log Group (90-day retention)
- Lambda error alarm (threshold: 5%)
- Lambda duration alarm (threshold: p95 > 300ms)

**Infrastructure repository** creates:
- SQS DLQ depth alarm (threshold: > 0)
- API Gateway 5xx alarm (threshold: > 1%)
- SNS topic for all alerts

**SNS Topic**: `bbws-product-alerts-{env}`
- Email subscription (configure manually after deploy)

---

## Testing Strategy (Q10: Full TDD)

**Per Lambda Repository**:

1. **Write tests FIRST** (TDD)
2. **Unit tests** (80%+ coverage):
   - Test handler logic
   - Test service layer
   - Test repository layer
   - Mock AWS services (moto)

3. **Integration tests**:
   - Test with local DynamoDB
   - Test SQS message processing
   - Test API Gateway integration

**Example Test Structure**:
```
tests/
├── unit/
│   ├── test_handler.py
│   ├── test_service.py
│   └── test_repository.py
├── integration/
│   ├── test_api_integration.py
│   └── test_sqs_integration.py
└── conftest.py  # Pytest fixtures
```

**Coverage Requirement**: 80%+ (enforced in CI/CD)

---

## Repository Creation Order

### Day 1: Infrastructure
1. ✅ Create `2_1_bbws_product_infrastructure`
2. ✅ Implement terraform (API GW, DynamoDB, SQS, S3, SNS)
3. ✅ Deploy to DEV
4. ✅ Verify outputs

### Days 2-6: API Handlers (can be parallel)
5. Create `2_1_bbws_list_products`
6. Create `2_1_bbws_get_product`
7. Create `2_1_bbws_create_product`
8. Create `2_1_bbws_update_product`
9. Create `2_1_bbws_delete_product`

### Days 7-8: Event-Driven (can be parallel)
10. Create `2_1_bbws_product_creator`
11. Create `2_1_bbws_audit_logger`

### Days 9-10: Integration & Documentation
12. End-to-end testing
13. Update documentation
14. Create runbooks

---

## Success Criteria

**Infrastructure Repository**:
- ✅ API Gateway created with base path `/v1.0/products`
- ✅ DynamoDB table `products` with GSI1 and GSI2
- ✅ SQS queue + DLQ configured
- ✅ S3 bucket with Glacier lifecycle
- ✅ SNS topic for alerts
- ✅ API keys stored in Secrets Manager and local file
- ✅ All outputs available for Lambda repos

**Each Lambda Repository**:
- ✅ Handler function deployed
- ✅ Tests pass (80%+ coverage)
- ✅ Terraform integrates with infrastructure outputs
- ✅ CI/CD pipeline working (manual dispatch)
- ✅ CloudWatch logs and alarms configured
- ✅ README with deployment instructions

**Overall System**:
- ✅ All 5 API endpoints working
- ✅ Create/Update/Delete publish to SQS
- ✅ ProductCreator processes messages and writes to DynamoDB
- ✅ AuditLogger writes to S3
- ✅ No product seeding (empty table)
- ✅ API key authentication working

---

## Next Steps

**Immediate**:
1. Start with infrastructure repository: `2_1_bbws_product_infrastructure`
2. Create directory structure
3. Implement terraform for all shared resources
4. Deploy to DEV and verify outputs

**Then**:
5. Create Lambda repositories one by one
6. Each Lambda references infrastructure outputs
7. Deploy and test individually
8. Final integration testing

---

**Status**: ✅ **Plan Approved - Ready to Execute**

**First Task**: Create infrastructure repository `2_1_bbws_product_infrastructure`

---

**Estimated Completion**: 10 working days (60 hours)
**Complexity**: High (microservices coordination)
**Risk**: Medium (dependency management between repos)
