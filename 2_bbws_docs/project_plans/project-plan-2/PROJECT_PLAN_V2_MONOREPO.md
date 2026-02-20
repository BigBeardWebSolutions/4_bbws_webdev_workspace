# Project Plan V2: Product Lambda Monorepo Implementation

**Project ID**: project-plan-2-v2
**Created**: 2025-12-29
**Status**: 🟡 PENDING USER APPROVAL
**Type**: Monorepo Implementation with Infrastructure & CI/CD
**Architecture**: 2 Repositories (1 Infrastructure + 1 Product Lambda Monorepo)

---

## Project Overview

**Objective**: Implement the Product Lambda service as a single deployable unit with 6 Lambda functions (5 API handlers + 1 event-driven processor) in a monorepo architecture following the BBWS multi-environment deployment pattern with functional GitHub Actions workflows.

**Parent LLD**: 2.1.4_LLD_Product_Lambda.md (Version 3.0) - **UPDATED**

**Reference Architecture**: `/Users/tebogotseka/Documents/agentic_work/2_1_bbws_dynamodb_schemas` (workflow pattern)

**Architecture Change**: **Microservices (8 repos) → Monorepo (2 repos)**
- ❌ Removed: ProductAuditLogger, ProductSearchIndexer, ProductCacheInvalidator
- ✅ Simplified: Single `2_bbws_product_lambda/` repo with all 6 Lambda functions
- ✅ Reason: Avoid repository proliferation, simpler deployment, single CI/CD pipeline

---

## Key Changes from Previous Plan

| Aspect | Previous Plan (V1) | New Plan (V2) | Reason |
|--------|-------------------|---------------|--------|
| **Repositories** | 8 (1 infra + 7 Lambdas) | 2 (1 infra + 1 monorepo) | Avoid repo proliferation |
| **Lambda Functions** | 9 (5 API + 4 event) | 6 (5 API + 1 event) | Removed audit, search, cache |
| **Deployment Units** | 8 separate deployments | 2 deployments | Simpler CI/CD |
| **Stages** | 4 stages | 3 stages | Faster execution |
| **Workers** | 27 workers | 12 workers | Streamlined |
| **Timeline** | 10 days | 6-7 days | Faster delivery |
| **Workflows** | 24 (3 per repo × 8) | 6 (3 per repo × 2) | Less maintenance |

---

## Project Deliverables

1. **Infrastructure Repository** - `2_1_bbws_product_infrastructure` (shared resources)
2. **Product Lambda Monorepo** - `2_bbws_product_lambda` (6 Lambda functions in single repo)
3. **GitHub Actions Workflows** - Functional multi-environment CI/CD (DEV/SIT/PROD)
4. **Comprehensive Tests** - 80%+ coverage (TDD approach)
5. **Documentation** - README, runbooks, deployment guides

**Total Repositories**: 2
**Total Lambda Functions**: 6
**Total Workflows**: 6 (3 per repo × 2 repos)

---

## Repository Architecture

### Repository 1: Infrastructure (`2_1_bbws_product_infrastructure`)

**Purpose**: Shared AWS infrastructure resources
**Deploy Order**: **FIRST** (Product Lambda depends on outputs)

**Directory Structure**:
```
2_1_bbws_product_infrastructure/
├── terraform/
│   ├── api_gateway.tf        # REST API: bbws-product-api-{env}
│   ├── dynamodb.tf            # Table: bbws-products-{env}
│   ├── sqs.tf                 # Queue: bbws-product-change-{env} + DLQ
│   ├── iam.tf                 # Base Lambda execution roles
│   ├── variables.tf
│   ├── outputs.tf             # ⚠️ CRITICAL: Exports for Lambda repo
│   ├── backend.tf             # S3 backend config
│   └── environments/
│       ├── dev.tfvars         # eu-west-1, Account: 536580886816
│       ├── sit.tfvars         # eu-west-1, Account: 815856636111
│       └── prod.tfvars        # af-south-1, Account: 093646564004
├── .github/workflows/
│   ├── deploy-dev.yml         # Manual dispatch, OIDC auth
│   ├── deploy-sit.yml         # Manual dispatch + approval gate
│   └── deploy-prod.yml        # Manual dispatch + confirmation
├── scripts/
│   └── validate_infrastructure.py
├── README.md
├── .gitignore
└── CLAUDE.md
```

**AWS Resources Created** (per environment):
- ✅ API Gateway REST API: `bbws-product-api-{env}`
- ✅ DynamoDB Table: `bbws-products-{env}` (ON_DEMAND, PITR)
  - GSI1: ProductsByPriceIndex
  - GSI2: ProductsByNameIndex (for search)
- ✅ SQS Queue: `bbws-product-change-{env}` (4-day retention)
- ✅ SQS DLQ: `bbws-product-change-dlq-{env}` (max receive 3)
- ✅ IAM Roles: Lambda execution roles
- ✅ CloudWatch Log Groups: For Lambdas
- ✅ CloudWatch Alarms: SQS DLQ depth, API 5xx errors

**Terraform Outputs** (imported by Product Lambda repo):
```hcl
output "api_gateway_id" { value = aws_api_gateway_rest_api.product_api.id }
output "api_gateway_execution_arn" { value = aws_api_gateway_rest_api.product_api.execution_arn }
output "api_gateway_root_resource_id" { value = aws_api_gateway_rest_api.product_api.root_resource_id }
output "dynamodb_table_name" { value = aws_dynamodb_table.products.name }
output "dynamodb_table_arn" { value = aws_dynamodb_table.products.arn }
output "sqs_queue_url" { value = aws_sqs_queue.product_change.url }
output "sqs_queue_arn" { value = aws_sqs_queue.product_change.arn }
```

---

### Repository 2: Product Lambda Monorepo (`2_bbws_product_lambda`)

**Purpose**: All 6 Lambda functions in single deployable unit
**Deploy Order**: After infrastructure (imports infrastructure outputs)

**Directory Structure**:
```
2_bbws_product_lambda/
├── src/
│   ├── handlers/
│   │   ├── __init__.py
│   │   ├── list_products.py        # GET /v1.0/products
│   │   ├── get_product.py          # GET /v1.0/products/{id}
│   │   ├── create_product.py       # POST /v1.0/products
│   │   ├── update_product.py       # PUT /v1.0/products/{id}
│   │   └── delete_product.py       # DELETE /v1.0/products/{id}
│   ├── event_handlers/
│   │   ├── __init__.py
│   │   └── product_creator.py      # SQS → DynamoDB (CREATE/UPDATE/DELETE)
│   ├── services/
│   │   ├── __init__.py
│   │   ├── product_service.py      # Business logic
│   │   └── sqs_service.py          # SQS message publishing
│   ├── repositories/
│   │   ├── __init__.py
│   │   └── product_repository.py   # DynamoDB data access
│   ├── models/
│   │   ├── __init__.py
│   │   ├── product.py              # Pydantic Product model
│   │   └── events.py               # SQS event schemas
│   ├── validators/
│   │   ├── __init__.py
│   │   └── product_validator.py    # Input validation
│   ├── exceptions/
│   │   ├── __init__.py
│   │   └── product_exceptions.py   # Custom exceptions
│   └── utils/
│       ├── __init__.py
│       ├── response_builder.py     # API response formatting
│       └── logger.py               # CloudWatch logging
├── tests/
│   ├── unit/
│   │   ├── handlers/               # Test all 6 handlers
│   │   ├── services/
│   │   └── repositories/
│   ├── integration/
│   │   ├── test_product_api.py
│   │   ├── test_event_driven.py
│   │   └── test_crud_flow.py
│   └── conftest.py                 # Pytest fixtures
├── terraform/
│   ├── main.tf
│   ├── lambda.tf                   # All 6 Lambda functions
│   ├── api_gateway_integration.tf  # 5 API endpoints
│   ├── sqs_event_source.tf         # SQS trigger for ProductCreator
│   ├── iam.tf                      # Lambda-specific IAM
│   ├── cloudwatch.tf               # Logs & alarms (6 functions)
│   ├── variables.tf
│   ├── outputs.tf
│   ├── data.tf                     # ⚠️ Import infrastructure outputs
│   ├── backend.tf
│   └── environments/
│       ├── dev.tfvars
│       ├── sit.tfvars
│       └── prod.tfvars
├── .github/workflows/
│   ├── deploy-dev.yml              # Tests → Package → Terraform → Deploy
│   ├── deploy-sit.yml              # Tests → Approval → Deploy
│   └── deploy-prod.yml             # Tests → Confirmation → Approval → Deploy
├── scripts/
│   ├── package_lambdas.sh          # Package all 6 Lambdas as ZIP
│   └── validate_deployment.py      # Post-deployment validation
├── requirements.txt                # boto3, pydantic
├── requirements-dev.txt            # pytest, moto, black, mypy
├── pytest.ini
├── .gitignore
├── README.md
└── CLAUDE.md
```

**Lambda Functions** (6 total):
1. **list_products** - GET /v1.0/products (sync read)
2. **get_product** - GET /v1.0/products/{id} (sync read)
3. **create_product** - POST /v1.0/products (async via SQS, returns 202)
4. **update_product** - PUT /v1.0/products/{id} (async via SQS, returns 202)
5. **delete_product** - DELETE /v1.0/products/{id} (async via SQS, returns 204)
6. **product_creator** - SQS trigger → DynamoDB writes (CREATE/UPDATE/DELETE)

**Critical**: `terraform/data.tf` imports infrastructure outputs:
```hcl
data "terraform_remote_state" "infrastructure" {
  backend = "s3"
  config = {
    bucket = "bbws-terraform-state-${var.environment}"
    key    = "2_1_bbws_product_infrastructure/terraform.tfstate"
    region = var.aws_region
  }
}

locals {
  api_gateway_id       = data.terraform_remote_state.infrastructure.outputs.api_gateway_id
  dynamodb_table_name  = data.terraform_remote_state.infrastructure.outputs.dynamodb_table_name
  sqs_queue_url        = data.terraform_remote_state.infrastructure.outputs.sqs_queue_url
}
```

---

## Project Stages

| Stage | Name | Workers | Duration | Status |
|-------|------|---------|----------|--------|
| **Stage 1** | Infrastructure & Repository Setup | 2 | 1 day | PENDING |
| **Stage 2** | Lambda Implementation & Testing | 6 | 4 days | PENDING |
| **Stage 3** | CI/CD Pipeline & Integration Testing | 4 | 2 days | PENDING |

**Total Workers**: 12
**Total Duration**: 7 working days (reduced from 10)

---

## Stage 1: Infrastructure & Repository Setup

**Duration**: 1 day
**Workers**: 2 (executed sequentially)
**Agent**: DevOps Engineer

### Worker 1-1: Infrastructure Repository

**Priority**: CRITICAL (must deploy first)

**Deliverables**:
1. Create `2_1_bbws_product_infrastructure/` repository
2. Terraform files for all AWS resources
3. GitHub Actions workflows (deploy-dev, deploy-sit, deploy-prod)
4. **Deploy to DEV** and verify all outputs
5. OIDC authentication configured

**Validation**:
```bash
# Verify infrastructure deployed
aws dynamodb describe-table --table-name bbws-products-dev --region eu-west-1
aws apigateway get-rest-apis --region eu-west-1 | grep bbws-product-api-dev
aws sqs list-queues --region eu-west-1 | grep bbws-product-change-dev

# Verify Terraform outputs
cd terraform && terraform output
```

### Worker 1-2: Product Lambda Repository Structure

**Deliverables**:
1. Create `2_bbws_product_lambda/` repository
2. Complete directory structure (79 files)
3. `terraform/data.tf` imports infrastructure outputs
4. requirements.txt with dependencies (boto3, pydantic)
5. pytest.ini configuration
6. .gitignore, README.md, CLAUDE.md

**Note**: Code implementation happens in Stage 2

---

## Stage 2: Lambda Implementation & Testing

**Duration**: 4 days
**Workers**: 6 (one per Lambda function, can execute in parallel after Day 1)
**Agent**: Python AWS Developer

### TDD Approach (All Workers)

1. **Write tests FIRST** (define expected behavior)
2. **Implement code** to make tests pass
3. **Refactor** for quality
4. **Verify 80%+ coverage**

### Worker 2-1: List Products Lambda

**Files**:
- `src/handlers/list_products.py`
- `src/services/product_service.py`
- `src/repositories/product_repository.py`
- `src/models/product.py`
- `tests/unit/handlers/test_list_products.py`
- `tests/unit/services/test_product_service.py`
- `tests/unit/repositories/test_product_repository.py`

**Implementation**:
- Parse query parameters (limit, lastEvaluatedKey)
- Call ProductRepository.find_all()
- Return 200 with product list + pagination token
- Error handling (500, 503)

**Tests**: 80%+ coverage

### Worker 2-2: Get Product Lambda

**Similar to Worker 2-1**, but single product by ID
- Parse productId from path
- Call ProductRepository.find_by_id()
- Return 200 or 404

### Worker 2-3: Create Product Lambda

**Implementation**:
- Parse request body
- Validate using Pydantic
- Generate productId (UUID)
- Publish ProductChangeEvent to SQS
- Return 202 Accepted (not 201!)

**Key**: Does NOT write to DynamoDB

### Worker 2-4: Update Product Lambda

**Similar to Worker 2-3**, but UPDATE event

### Worker 2-5: Delete Product Lambda

**Similar to Worker 2-3**, but DELETE event (soft delete)

### Worker 2-6: Product Creator Lambda (Event-Driven)

**Implementation**:
- Parse SQS event (batch up to 10 messages)
- For each message:
  - Parse ProductChangeEvent
  - Switch on eventType (CREATE/UPDATE/DELETE)
  - Call ProductRepository methods
- Handle partial batch failures
- Idempotent operations

**This is the ONLY Lambda that writes to DynamoDB**

**Tests**: Batch processing, idempotency, error handling

---

## Stage 3: CI/CD Pipeline & Integration Testing

**Duration**: 2 days
**Workers**: 4
**Agent**: DevOps Engineer + QA Engineer

### Worker 3-1: Infrastructure Repo Workflows

**Create 3 workflows**:
1. `deploy-dev.yml` - Manual dispatch, auto-deploy
2. `deploy-sit.yml` - Manual dispatch + approval
3. `deploy-prod.yml` - Manual dispatch + confirmation + approval

**Follow**: `2_1_bbws_dynamodb_schemas/.github/workflows/deploy-dev.yml` pattern

### Worker 3-2: Product Lambda Repo Workflows

**Create 3 workflows**:
1. `deploy-dev.yml`:
   - Run pytest (80%+ coverage required)
   - Package all 6 Lambdas as ZIP files
   - Terraform plan/apply
   - Post-deployment validation

2. `deploy-sit.yml`:
   - Same as DEV + approval gate

3. `deploy-prod.yml`:
   - Confirmation text required
   - Strict approval gate
   - Read-only for Claude

**Packaging Script** (`scripts/package_lambdas.sh`):
```bash
#!/bin/bash
# Package all 6 Lambda functions

cd src

# Package each handler
for handler in list_products get_product create_product update_product delete_product; do
  zip -r ../lambda_${handler}.zip handlers/${handler}.py services/ repositories/ models/ validators/ exceptions/ utils/
done

# Package event handler
zip -r ../lambda_product_creator.zip event_handlers/product_creator.py services/ repositories/ models/ utils/

cd ..
```

### Worker 3-3: Integration Testing

**Deliverables**:
1. **E2E CRUD Test**:
   - Create product → Wait for SQS → Verify in DynamoDB
   - Update product → Wait for SQS → Verify update
   - Delete product → Wait for SQS → Verify soft delete

2. **Performance Tests**:
   - API latency < 300ms (p95)
   - SQS processing < 10s end-to-end

3. **Error Tests**:
   - DLQ receives failed messages
   - Lambda retries work
   - Partial batch failures

### Worker 3-4: Documentation

**Deliverables**:
1. **README.md** for both repositories
   - Setup instructions
   - Deployment guide (DEV/SIT/PROD)
   - Testing guide
   - Architecture diagram

2. **Deployment Runbook** - Step-by-step procedures

3. **Troubleshooting Guide** - Common issues & solutions

---

## Approval Gates

| Gate | After Stage | Status | Approvers |
|------|-------------|--------|-----------|
| **Gate 0** | Project Plan | 🟡 **PENDING NOW** | Product Owner, Tech Lead |
| Gate 1 | Stage 1 | ⏸️ Not Started | DevOps Lead, Tech Lead |
| Gate 2 | Stage 2 | ⏸️ Not Started | Tech Lead, Developer Lead |
| Gate 3 | Stage 3 | ⏸️ Not Started | Product Owner, Tech Lead, QA Lead |

---

## Success Criteria

### Stage 1: Infrastructure & Repository Setup
- [x] Infrastructure repo created and deployed to DEV
- [x] All AWS resources created (API Gateway, DynamoDB, SQS)
- [x] Terraform outputs verified
- [x] Product Lambda repo structure created (79 files)
- [x] `terraform/data.tf` imports infrastructure outputs
- [x] README, CLAUDE.md created

### Stage 2: Lambda Implementation
- [x] All 6 Lambda functions implemented (Python 3.12)
- [x] Unit tests passing (80%+ coverage per Lambda)
- [x] Integration tests passing
- [x] All Lambdas reference infrastructure outputs
- [x] Pydantic models created (camelCase fields)

### Stage 3: CI/CD & Integration
- [x] 6 GitHub Actions workflows created and functional
- [x] All workflows follow `2_1_bbws_dynamodb_schemas` pattern
- [x] E2E CRUD flow tested and passing
- [x] Performance tests passing (API < 300ms, SQS < 10s)
- [x] Documentation complete (README, runbooks)

---

## Timeline

**Total Duration**: 7 working days

| Day | Stage | Activities | Deliverables |
|-----|-------|------------|--------------|
| **Day 1** | Stage 1 | Infrastructure + repo structure | Infrastructure deployed, repo created |
| **Days 2-5** | Stage 2 | Implement 6 Lambdas (TDD) | All Lambdas coded & tested (80%+ coverage) |
| **Days 6-7** | Stage 3 | CI/CD workflows + integration tests | All workflows functional, tests passing |

**Estimated Start**: Upon Gate 0 approval
**Estimated Completion**: 7 working days after start

---

## Risk Management

### Technical Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Infrastructure deployment fails | Medium | High | Test in DEV first, rollback procedures |
| Test coverage below 80% | Medium | Medium | TDD approach, enforce in CI/CD |
| Terraform state corruption | Low | High | S3 versioning, DynamoDB locking |
| OIDC authentication issues | Medium | High | Test thoroughly in DEV |
| SQS message processing delays | Low | Medium | Monitor DLQ, configure alarms |

---

## TBT Workflow Integration

**Project Directory Structure**:
```
project-plan-2/
├── .tbt/
│   ├── logs/history.log          # All commands logged
│   ├── state/state.md             # Current state tracking
│   ├── snapshots/                 # File snapshots
│   └── staging/                   # Artifacts
├── stage-1-infrastructure-setup/
│   ├── plan.md
│   ├── summary.md
│   ├── worker-1-1-infrastructure-repo/
│   └── worker-1-2-product-lambda-repo/
├── stage-2-lambda-implementation/
│   ├── plan.md
│   ├── summary.md
│   ├── worker-2-1-list-products/
│   ├── worker-2-2-get-product/
│   ├── worker-2-3-create-product/
│   ├── worker-2-4-update-product/
│   ├── worker-2-5-delete-product/
│   └── worker-2-6-product-creator/
├── stage-3-cicd-integration/
│   ├── plan.md
│   ├── summary.md
│   ├── worker-3-1-infrastructure-workflows/
│   ├── worker-3-2-product-lambda-workflows/
│   ├── worker-3-3-integration-testing/
│   └── worker-3-4-documentation/
├── documentation/
├── PROJECT_PLAN_V2_MONOREPO.md    # This file
├── PROJECT_PLAN.md                # Previous version (8 repos)
├── PROJECT_ANALYSIS_REPORT.md
└── README.md
```

---

## Comparison: V1 (Microservices) vs V2 (Monorepo)

| Metric | V1 (Microservices) | V2 (Monorepo) | Improvement |
|--------|-------------------|---------------|-------------|
| **Repositories** | 8 | 2 | 75% reduction |
| **Lambda Functions** | 9 | 6 | 33% reduction |
| **Stages** | 4 | 3 | 25% reduction |
| **Workers** | 27 | 12 | 56% reduction |
| **Timeline** | 10 days | 7 days | 30% faster |
| **Workflows** | 24 | 6 | 75% reduction |
| **Complexity** | High | Medium | Simpler |
| **Maintenance** | High | Low | Easier |

**Winner**: V2 (Monorepo) - Simpler, faster, easier to maintain

---

## What Was Removed

**From LLD v2.0 → v3.0**:
- ❌ ProductAuditLogger (SQS → S3 audit logging)
- ❌ ProductSearchIndexer (SQS → OpenSearch indexing)
- ❌ ProductCacheInvalidator (SQS → CloudFront cache invalidation)

**Rationale**:
- User decision to avoid repository proliferation
- Simplify deployment and maintenance
- Focus on core CRUD operations
- Search handled by DynamoDB GSI2
- Cache and audit can be added later if needed

**Remaining**: 6 Lambda functions (5 API + 1 event processor)

---

## Resource Requirements

### Personnel

| Role | Stages | Effort | Availability |
|------|--------|--------|--------------|
| **DevOps Engineer** | Stage 1, Stage 3 | 3 days | Required |
| **Python AWS Developer** | Stage 2 | 4 days | Required |
| **QA Engineer** | Stage 3 | 1 day | Required |
| **Project Manager** | All stages | 7 days | Required (orchestration) |

**Total Effort**: 42 hours (7 days × 6 hours/day)

### AWS Resources

**DEV Environment**:
- AWS Account: 536580886816
- Region: eu-west-1
- Cost Estimate: $30-50/month (DynamoDB, Lambda, SQS, API Gateway)

**SIT Environment**:
- AWS Account: 815856636111
- Region: eu-west-1
- Cost Estimate: $30-50/month

**PROD Environment**:
- AWS Account: 093646564004
- Region: af-south-1
- Cost Estimate: $50-100/month

---

## Approval Request

**Project**: Product Lambda Monorepo Implementation
**Plan**: This document (PROJECT_PLAN_V2_MONOREPO.md)
**LLD**: Updated to v3.0 (ProductAuditLogger, ProductSearchIndexer, ProductCacheInvalidator removed)
**Status**: 🟡 PENDING USER APPROVAL

**Architecture**:
- ✅ 2 repositories (1 infrastructure + 1 product lambda monorepo)
- ✅ 6 Lambda functions (5 API + 1 event processor)
- ✅ Single deployable unit
- ✅ 7-day timeline (vs 10-day previous plan)

**To Approve**:
Reply with: **"GO"** or **"APPROVED"** or **"Proceed with V2 monorepo plan"**

**To Request Changes**:
Reply with specific changes needed

**Upon Approval**:
1. Initialize TBT workflow structure
2. Create Stage 1 worker instructions
3. Execute Worker 1-1: Create infrastructure repo and deploy to DEV
4. Execute Worker 1-2: Create product lambda repo structure
5. Request Gate 1 approval
6. Proceed to Stage 2

---

**Estimated Start**: Immediately upon approval
**Estimated Completion**: 7 working days after start
**Success Probability**: 95% (based on project-plan-1 success + simpler architecture)

---

**Document Metadata**:
- **Version**: 2.0 (Monorepo)
- **Created**: 2025-12-29
- **Author**: Agentic Project Manager (Claude Code)
- **Status**: Awaiting Gate 0 Approval
- **Total Workers**: 12 (reduced from 27)
- **Total Deliverables**: 2 repositories + 6 workflows + comprehensive documentation
- **LLD Version**: 3.0 (updated)

---

**END OF PROJECT PLAN V2**
