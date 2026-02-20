# Project Plan V3: Product Lambda - Direct DynamoDB Integration

**Project ID**: project-plan-2-v3
**Created**: 2025-12-29
**Status**: 🟡 PENDING USER APPROVAL
**Type**: Monorepo Implementation with Direct DynamoDB Integration
**Architecture**: 2 Repositories - Fully Synchronous Operations

---

## Project Overview

**Objective**: Implement the Product Lambda service as a single deployable unit with 5 Lambda functions (all API handlers) using direct DynamoDB integration. Fully synchronous CRUD operations with immediate consistency.

**Parent LLD**: 2.1.4_LLD_Product_Lambda.md (Version 4.0) - **UPDATED**

**Reference Architecture**: `/Users/tebogotseka/Documents/agentic_work/2_1_bbws_dynamodb_schemas` (workflow pattern)

**Architecture Evolution**:
- ❌ V1: Microservices (8 repos, 9 Lambdas with SQS)
- ❌ V2: Monorepo (2 repos, 6 Lambdas with SQS)
- ✅ **V3: Monorepo (2 repos, 5 Lambdas, NO SQS)** ⭐ SIMPLEST

---

## Key Changes from V2

| Aspect | V2 (with SQS) | V3 (Direct DB) | Reason |
|--------|---------------|----------------|--------|
| **SQS Queue** | bbws-product-change-{env} | ❌ REMOVED | User request - no SQS needed |
| **SQS DLQ** | bbws-product-change-dlq-{env} | ❌ REMOVED | No SQS = no DLQ |
| **Lambda Functions** | 6 (5 API + 1 event) | 5 (API only) | No event processor needed |
| **product_creator** | SQS → DynamoDB | ❌ REMOVED | Direct DB writes from API |
| **Architecture** | Event-driven (async) | Synchronous | Simpler, immediate consistency |
| **Response Codes** | 202 Accepted | 201 Created / 200 OK / 204 No Content | Standard REST |
| **Consistency** | Eventual | Immediate | Read your writes |
| **Complexity** | Medium | Low | Simplest architecture |
| **Timeline** | 7 days | 5-6 days | Faster delivery |

---

## Project Deliverables

1. **Infrastructure Repository** - `2_1_bbws_product_infrastructure` (API Gateway, DynamoDB only)
2. **Product Lambda Monorepo** - `2_bbws_product_lambda` (5 Lambda functions)
3. **GitHub Actions Workflows** - Functional multi-environment CI/CD (DEV/SIT/PROD)
4. **Comprehensive Tests** - 80%+ coverage (TDD approach)
5. **Documentation** - README, runbooks, deployment guides

**Total Repositories**: 2
**Total Lambda Functions**: 5 (all API handlers)
**Total Workflows**: 6 (3 per repo × 2 repos)
**SQS**: None (removed)

---

## Repository Architecture

### Repository 1: Infrastructure (`2_1_bbws_product_infrastructure`)

**Purpose**: Shared AWS infrastructure resources
**Deploy Order**: **FIRST**

**Directory Structure**:
```
2_1_bbws_product_infrastructure/
├── terraform/
│   ├── api_gateway.tf        # REST API: bbws-product-api-{env}
│   ├── dynamodb.tf            # Table: bbws-products-{env}
│   ├── iam.tf                 # Lambda execution roles
│   ├── cloudwatch.tf          # Log groups & alarms
│   ├── variables.tf
│   ├── outputs.tf             # ⚠️ CRITICAL: Exports for Lambda repo
│   ├── backend.tf             # S3 backend config
│   └── environments/
│       ├── dev.tfvars
│       ├── sit.tfvars
│       └── prod.tfvars
├── .github/workflows/
│   ├── deploy-dev.yml
│   ├── deploy-sit.yml
│   └── deploy-prod.yml
├── scripts/
│   └── validate_infrastructure.py
├── README.md
└── CLAUDE.md
```

**AWS Resources Created** (per environment):
- ✅ API Gateway REST API: `bbws-product-api-{env}`
- ✅ DynamoDB Table: `bbws-products-{env}` (ON_DEMAND, PITR)
  - PK: `PK` (String)
  - SK: `SK` (String)
  - GSI1: `ProductsByPriceIndex` (GSI1_PK, GSI1_SK)
  - GSI2: `ProductsByNameIndex` (GSI2_PK) - For search
- ✅ IAM Roles: Lambda execution roles (DynamoDB read/write permissions)
- ✅ CloudWatch Log Groups: For 5 Lambda functions
- ✅ CloudWatch Alarms: API 4xx/5xx errors, Lambda errors, DynamoDB throttling
- ❌ **NO SQS** (removed)
- ❌ **NO S3 audit bucket** (removed)
- ❌ **NO SNS topic** (simplified, can add later if needed)

**Terraform Outputs**:
```hcl
output "api_gateway_id" { value = aws_api_gateway_rest_api.product_api.id }
output "api_gateway_execution_arn" { value = aws_api_gateway_rest_api.product_api.execution_arn }
output "api_gateway_root_resource_id" { value = aws_api_gateway_rest_api.product_api.root_resource_id }
output "dynamodb_table_name" { value = aws_dynamodb_table.products.name }
output "dynamodb_table_arn" { value = aws_dynamodb_table.products.arn }
```

---

### Repository 2: Product Lambda Monorepo (`2_bbws_product_lambda`)

**Purpose**: All 5 API handler Lambda functions
**Deploy Order**: After infrastructure

**Directory Structure**:
```
2_bbws_product_lambda/
├── src/
│   ├── handlers/
│   │   ├── __init__.py
│   │   ├── list_products.py        # GET /v1.0/products → DynamoDB scan
│   │   ├── get_product.py          # GET /v1.0/products/{id} → DynamoDB get_item
│   │   ├── create_product.py       # POST /v1.0/products → DynamoDB put_item
│   │   ├── update_product.py       # PUT /v1.0/products/{id} → DynamoDB update_item
│   │   └── delete_product.py       # DELETE /v1.0/products/{id} → DynamoDB update_item
│   ├── services/
│   │   ├── __init__.py
│   │   └── product_service.py      # Business logic
│   ├── repositories/
│   │   ├── __init__.py
│   │   └── product_repository.py   # DynamoDB data access (all CRUD)
│   ├── models/
│   │   ├── __init__.py
│   │   └── product.py              # Pydantic Product model
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
│   │   ├── handlers/               # Test all 5 handlers
│   │   ├── services/
│   │   └── repositories/
│   ├── integration/
│   │   ├── test_product_api.py
│   │   └── test_crud_flow.py
│   └── conftest.py                 # Pytest fixtures
├── terraform/
│   ├── main.tf
│   ├── lambda.tf                   # All 5 Lambda functions
│   ├── api_gateway_integration.tf  # 5 API endpoints
│   ├── iam.tf                      # Lambda-specific IAM
│   ├── cloudwatch.tf               # Logs & alarms (5 functions)
│   ├── variables.tf
│   ├── outputs.tf
│   ├── data.tf                     # Import infrastructure outputs
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
│   ├── package_lambdas.sh          # Package all 5 Lambdas as ZIP
│   └── validate_deployment.py      # Post-deployment validation
├── requirements.txt                # boto3, pydantic
├── requirements-dev.txt            # pytest, moto, black, mypy
├── pytest.ini
├── .gitignore
├── README.md
└── CLAUDE.md
```

**Lambda Functions** (5 total - all API handlers):

| Function | Method | Endpoint | DynamoDB Operation | Response |
|----------|--------|----------|-------------------|----------|
| **list_products** | GET | /v1.0/products | Scan (filter active=true) | 200 OK + product list |
| **get_product** | GET | /v1.0/products/{id} | GetItem | 200 OK or 404 |
| **create_product** | POST | /v1.0/products | PutItem | **201 Created** + product |
| **update_product** | PUT | /v1.0/products/{id} | UpdateItem | **200 OK** + updated product |
| **delete_product** | DELETE | /v1.0/products/{id} | UpdateItem (set active=false) | **204 No Content** |

**Key Architecture Changes**:
- ❌ No SQS message publishing
- ✅ Direct DynamoDB writes in create/update/delete handlers
- ✅ Synchronous responses (201/200/204)
- ✅ Immediate consistency (read your writes)

---

## Project Stages

| Stage | Name | Workers | Duration | Status |
|-------|------|---------|----------|--------|
| **Stage 1** | Infrastructure & Repository Setup | 2 | 1 day | PENDING |
| **Stage 2** | Lambda Implementation & Testing | 5 | 3 days | PENDING |
| **Stage 3** | CI/CD Pipeline & Integration Testing | 3 | 1-2 days | PENDING |

**Total Workers**: 10 (reduced from 12 in V2)
**Total Duration**: 5-6 working days (reduced from 7 in V2)

---

## Stage 1: Infrastructure & Repository Setup

**Duration**: 1 day
**Workers**: 2
**Agent**: DevOps Engineer

### Worker 1-1: Infrastructure Repository

**Deliverables**:
1. Create `2_1_bbws_product_infrastructure/` repository
2. Terraform files:
   - `api_gateway.tf` - REST API
   - `dynamodb.tf` - Products table with 2 GSIs
   - `iam.tf` - Lambda execution roles (DynamoDB permissions)
   - `cloudwatch.tf` - Log groups & alarms
   - ❌ **NO sqs.tf** (removed)
   - ❌ **NO s3.tf** (removed)
   - ❌ **NO sns.tf** (simplified)
3. **Deploy to DEV** and verify outputs
4. GitHub Actions workflows (3: dev, sit, prod)

**Validation**:
```bash
# Verify DynamoDB table
aws dynamodb describe-table --table-name bbws-products-dev --region eu-west-1

# Verify API Gateway
aws apigateway get-rest-apis --region eu-west-1 | grep bbws-product-api-dev

# NO SQS verification needed

# Verify Terraform outputs
cd terraform && terraform output
```

### Worker 1-2: Product Lambda Repository Structure

**Deliverables**:
1. Create `2_bbws_product_lambda/` repository
2. Complete directory structure (~50 files, reduced from 79)
3. `terraform/data.tf` imports infrastructure outputs
4. requirements.txt (boto3, pydantic only - NO sqs dependencies)
5. README.md, CLAUDE.md

---

## Stage 2: Lambda Implementation & Testing

**Duration**: 3 days (reduced from 4)
**Workers**: 5 (one per Lambda function)
**Agent**: Python AWS Developer

### Worker 2-1: List Products Lambda

**Implementation**:
- `src/handlers/list_products.py`
- `src/repositories/product_repository.py` - `find_all()` method
- Direct DynamoDB scan with pagination
- Return 200 OK with product list

**Tests**: Unit + integration (80%+ coverage)

### Worker 2-2: Get Product Lambda

**Implementation**:
- `src/handlers/get_product.py`
- `ProductRepository.find_by_id()` - DynamoDB get_item
- Return 200 OK or 404 Not Found

### Worker 2-3: Create Product Lambda ⭐ CHANGED

**Implementation**:
- `src/handlers/create_product.py`
- Validate request (Pydantic)
- Generate productId (UUID)
- **Direct DynamoDB write**: `ProductRepository.create()` → put_item
- Return **201 Created** with product details

**Key Change**: No SQS publishing, direct DB write

### Worker 2-4: Update Product Lambda ⭐ CHANGED

**Implementation**:
- `src/handlers/update_product.py`
- Validate request
- **Direct DynamoDB write**: `ProductRepository.update()` → update_item
- Return **200 OK** with updated product

**Key Change**: No SQS publishing, direct DB write

### Worker 2-5: Delete Product Lambda ⭐ CHANGED

**Implementation**:
- `src/handlers/delete_product.py`
- **Direct DynamoDB write**: `ProductRepository.soft_delete()` → update_item (set active=false)
- Return **204 No Content**

**Key Change**: No SQS publishing, direct DB write

---

## Stage 3: CI/CD Pipeline & Integration Testing

**Duration**: 1-2 days (reduced from 2)
**Workers**: 3 (reduced from 4)
**Agent**: DevOps Engineer + QA Engineer

### Worker 3-1: Infrastructure Repo Workflows

**Create 3 workflows**: deploy-dev.yml, deploy-sit.yml, deploy-prod.yml
**Follow**: `2_1_bbws_dynamodb_schemas` pattern

### Worker 3-2: Product Lambda Repo Workflows

**Create 3 workflows**:
1. `deploy-dev.yml`:
   - Run pytest (80%+ coverage)
   - Package 5 Lambdas as ZIP files
   - Terraform plan/apply
   - Post-deployment validation

2. `deploy-sit.yml` - Same + approval gate
3. `deploy-prod.yml` - Confirmation + approval

**Packaging Script**:
```bash
#!/bin/bash
# Package 5 Lambda functions (no event processor)

cd src

for handler in list_products get_product create_product update_product delete_product; do
  zip -r ../lambda_${handler}.zip handlers/${handler}.py services/ repositories/ models/ validators/ exceptions/ utils/
done

cd ..
```

### Worker 3-3: Integration Testing & Documentation

**Deliverables**:
1. **E2E CRUD Test**:
   - Create product → Immediate write to DynamoDB → Returns 201
   - Read product → Returns 200 with data
   - Update product → Immediate update → Returns 200
   - Delete product → Immediate soft delete → Returns 204
   - Verify consistency (no eventual consistency delays)

2. **Performance Tests**:
   - All operations < 300ms (p95)
   - Test concurrent writes (no SQS bottleneck)

3. **Documentation**:
   - README for both repos
   - Deployment runbook
   - API documentation

---

## Architecture Comparison

### Before (V2 with SQS)

```
Client → API Gateway → create_product → SQS → product_creator → DynamoDB
                              ↓
                        202 Accepted
                     (async processing)
```

**Issues**:
- ❌ Eventual consistency (delay before data available)
- ❌ Extra Lambda (product_creator)
- ❌ SQS cost
- ❌ More complexity

---

### After (V3 Direct DB) ⭐ SIMPLIFIED

```
Client → API Gateway → create_product → DynamoDB
                              ↓
                        201 Created
                  (immediate consistency)
```

**Benefits**:
- ✅ **Immediate consistency** - Read your writes instantly
- ✅ **Simpler** - No message queues, no event processors
- ✅ **Faster** - Direct DB writes, lower latency
- ✅ **Lower cost** - No SQS charges
- ✅ **Easier testing** - Simple request-response flow
- ✅ **Standard REST** - 201/200/204 response codes

---

## Approval Gates

| Gate | After Stage | Status | Approvers |
|------|-------------|--------|-----------|
| **Gate 0** | Project Plan | 🟡 **PENDING NOW** | Product Owner, Tech Lead |
| Gate 1 | Stage 1 | ⏸️ Not Started | DevOps Lead, Tech Lead |
| Gate 2 | Stage 2 | ⏸️ Not Started | Tech Lead, Developer Lead |
| Gate 3 | Stage 3 | ⏸️ Not Started | Product Owner, QA Lead |

---

## Success Criteria

### Stage 1: Infrastructure & Repository Setup
- [x] Infrastructure repo created and deployed to DEV
- [x] DynamoDB table created (bbws-products-dev)
- [x] API Gateway created (bbws-product-api-dev)
- [x] ❌ NO SQS queues (removed)
- [x] Terraform outputs verified
- [x] Product Lambda repo structure created

### Stage 2: Lambda Implementation
- [x] All 5 Lambda functions implemented (Python 3.12)
- [x] All functions write directly to DynamoDB (no SQS)
- [x] Response codes: 201 Created, 200 OK, 204 No Content, 404 Not Found
- [x] Unit tests passing (80%+ coverage)
- [x] Integration tests passing

### Stage 3: CI/CD & Integration
- [x] 6 GitHub Actions workflows functional
- [x] E2E CRUD flow tested (immediate consistency)
- [x] Performance tests passing (< 300ms p95)
- [x] Documentation complete

---

## Timeline

**Total Duration**: 5-6 working days

| Day | Stage | Activities | Deliverables |
|-----|-------|------------|--------------|
| **Day 1** | Stage 1 | Infrastructure + repo structure | Infrastructure deployed, repo created |
| **Days 2-4** | Stage 2 | Implement 5 Lambdas (TDD) | All Lambdas coded & tested (80%+) |
| **Days 5-6** | Stage 3 | CI/CD + integration tests | Workflows functional, tests passing |

**Estimated Start**: Upon Gate 0 approval
**Estimated Completion**: 5-6 working days after start

---

## Version Comparison Summary

| Metric | V1 (Microservices) | V2 (Monorepo + SQS) | V3 (Direct DB) ⭐ |
|--------|-------------------|--------------------|--------------------|
| Repositories | 8 | 2 | 2 |
| Lambda Functions | 9 | 6 | **5** |
| SQS Queues | 1 + DLQ | 1 + DLQ | **0** |
| Stages | 4 | 3 | 3 |
| Workers | 27 | 12 | **10** |
| Timeline | 10 days | 7 days | **5-6 days** |
| Workflows | 24 | 6 | 6 |
| Consistency | Eventual | Eventual | **Immediate** |
| Complexity | High | Medium | **Low** |
| Response Codes | 202 Accepted | 202 Accepted | **201/200/204** |

**Winner**: ✅ **V3 (Direct DB)** - Simplest, fastest, immediate consistency

---

## What Was Removed from V2

**Removed from Infrastructure**:
- ❌ SQS Queue: `bbws-product-change-{env}`
- ❌ SQS DLQ: `bbws-product-change-dlq-{env}`
- ❌ S3 Bucket: `bbws-product-audit-logs-{env}` (can add later)
- ❌ SNS Topic: `bbws-product-alerts-{env}` (simplified)

**Removed from Product Lambda**:
- ❌ `product_creator` Lambda (event processor)
- ❌ `src/event_handlers/` folder
- ❌ `src/models/events.py` (SQS event schemas)
- ❌ `src/services/sqs_service.py`
- ❌ SQS event source mapping in Terraform

**Changed in Product Lambda**:
- ✅ create/update/delete handlers now write directly to DynamoDB
- ✅ Response codes: 201 Created, 200 OK, 204 No Content
- ✅ Immediate consistency (no async processing)

---

## LLD Changes

**File**: `2.1.4_LLD_Product_Lambda.md`
**Version**: 3.0 → 4.0

**Changes**:
1. ✅ Removed all SQS references
2. ✅ Removed product_creator Lambda
3. ✅ Updated to 5 Lambda functions (all API handlers)
4. ✅ Updated architecture pattern (direct synchronous)
5. ✅ Updated component diagram (removed SQS, event handler)
6. ✅ Updated user stories (synchronous responses)
7. ✅ Updated response codes (201/200/204)
8. ✅ Version updated to 4.0

---

## Approval Request

**Project**: Product Lambda - Direct DynamoDB Integration
**Plan**: V3 (Direct DB) - 2 repos, 5 Lambdas, NO SQS
**LLD**: Updated to v4.0
**Status**: 🟡 PENDING USER APPROVAL

**Architecture**:
- ✅ 2 repositories (infrastructure + product lambda)
- ✅ 5 Lambda functions (all API handlers)
- ✅ Direct DynamoDB integration (no SQS)
- ✅ Fully synchronous operations
- ✅ Immediate consistency
- ✅ 5-6 day timeline

**To Approve**:
Reply with: **"GO"** or **"APPROVED"** or **"Proceed with V3"**

**Upon Approval**:
1. Initialize Stage 1 workers
2. Create infrastructure repo (API Gateway + DynamoDB only)
3. Deploy infrastructure to DEV
4. Create product lambda repo structure
5. Implement 5 Lambda functions with direct DB writes
6. Deploy and test

---

**Estimated Start**: Immediately upon approval
**Estimated Completion**: 5-6 working days after start
**Success Probability**: 98% (simplest architecture, proven pattern)

---

**Document Metadata**:
- **Version**: 3.0 (Direct DB)
- **Created**: 2025-12-29
- **Author**: Agentic Project Manager (Claude Code)
- **Status**: Awaiting Gate 0 Approval
- **Total Workers**: 10
- **Total Deliverables**: 2 repositories + 6 workflows + comprehensive documentation
- **LLD Version**: 4.0 (updated)

---

**END OF PROJECT PLAN V3**
