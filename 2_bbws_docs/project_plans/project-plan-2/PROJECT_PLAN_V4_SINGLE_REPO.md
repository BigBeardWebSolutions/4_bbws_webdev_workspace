# Project Plan V4: Product Lambda - Single Repository Architecture

**Project ID**: project-plan-2-v4
**Created**: 2025-12-29
**Status**: 🟢 READY FOR APPROVAL
**Type**: Single Repository with Direct DynamoDB Integration
**Architecture**: 1 Repository - Self-Contained with API Gateway

---

## Project Overview

**Objective**: Implement the Product Lambda service as a single self-contained repository with 5 Lambda functions (all API handlers), API Gateway, and DynamoDB schema reference. Fully synchronous CRUD operations with immediate consistency.

**Parent LLD**: 2.1.4_LLD_Product_Lambda.md (Version 4.0)

**DynamoDB Schema**: References `/Users/tebogotseka/Documents/agentic_work/2_1_bbws_dynamodb_schemas/schemas/products.schema.json` (UPDATED)

**Reference Architecture**: `/Users/tebogotseka/Documents/agentic_work/2_1_bbws_dynamodb_schemas` (workflow pattern)

**Architecture Evolution**:
- ❌ V1: Microservices (8 repos, 9 Lambdas with SQS)
- ❌ V2: Monorepo (2 repos, 6 Lambdas with SQS)
- ❌ V3: Monorepo (2 repos, 5 Lambdas, NO SQS)
- ✅ **V4: Single Repo (1 repo, 5 Lambdas, NO SQS, API Gateway included)** ⭐ SIMPLEST

---

## Key Changes from V3

| Aspect | V3 (2 repos) | V4 (1 repo) | Benefit |
|--------|--------------|-------------|---------|
| **Repositories** | 2 (infra + lambda) | 1 (lambda only) | Simpler deployment |
| **Infrastructure Repo** | 2_1_bbws_product_infrastructure | ❌ REMOVED | Not needed |
| **API Gateway** | Separate terraform | In lambda repo | Self-contained |
| **DynamoDB** | Created by infra repo | References existing schema | Reuses 2_1_bbws_dynamodb_schemas |
| **Deployment Order** | Infra first, then lambda | Single deployment | Faster |
| **Workers** | 10 | 7 | 30% reduction |
| **Timeline** | 5-6 days | 4-5 days | 20% faster |
| **Complexity** | Low | Lowest | Minimal moving parts |

---

## Project Deliverables

1. **Product Lambda Repository** - `2_bbws_product_lambda` (5 Lambdas + API Gateway + infrastructure)
2. **GitHub Actions Workflows** - Functional multi-environment CI/CD (DEV/SIT/PROD)
3. **Comprehensive Tests** - 80%+ coverage (TDD approach)
4. **Repository Documentation** - README.md in `2_bbws_product_lambda`
5. **Centralized Runbooks** - Operational runbooks in `2_bbws_docs/runbooks/`
6. **Deployment Guides** - Environment-specific deployment guides in `2_bbws_docs/runbooks/`

**Total Repositories**: 1 (`2_bbws_product_lambda`)
**Total Lambda Functions**: 5 (all API handlers)
**Total Workflows**: 3 (DEV/SIT/PROD)
**Documentation Location**: `2_bbws_docs/runbooks/` (centralized)
**External Dependencies**: `2_1_bbws_dynamodb_schemas` (DynamoDB table must exist first)

---

## Repository Architecture

### Repository: Product Lambda (`2_bbws_product_lambda`)

**Purpose**: Self-contained Product API service with Lambda functions, API Gateway, and infrastructure

**Directory Structure**:
```
2_bbws_product_lambda/
├── src/
│   ├── handlers/
│   │   ├── __init__.py
│   │   ├── list_products.py        # GET /v1.0/products → DynamoDB query (ActiveProductsIndex)
│   │   ├── get_product.py          # GET /v1.0/products/{id} → DynamoDB get_item
│   │   ├── create_product.py       # POST /v1.0/products → DynamoDB put_item (201 Created)
│   │   ├── update_product.py       # PUT /v1.0/products/{id} → DynamoDB update_item (200 OK)
│   │   └── delete_product.py       # DELETE /v1.0/products/{id} → DynamoDB soft delete (204)
│   ├── services/
│   │   ├── __init__.py
│   │   └── product_service.py      # Business logic layer
│   ├── repositories/
│   │   ├── __init__.py
│   │   └── product_repository.py   # DynamoDB data access (all CRUD operations)
│   ├── models/
│   │   ├── __init__.py
│   │   └── product.py              # Pydantic Product model
│   ├── validators/
│   │   ├── __init__.py
│   │   └── product_validator.py    # Request validation
│   ├── exceptions/
│   │   ├── __init__.py
│   │   └── product_exceptions.py   # Custom exceptions
│   └── utils/
│       ├── __init__.py
│       ├── response_builder.py     # Standardized API responses
│       └── logger.py               # CloudWatch structured logging
├── tests/
│   ├── unit/
│   │   ├── handlers/               # Test all 5 handlers
│   │   │   ├── test_list_products.py
│   │   │   ├── test_get_product.py
│   │   │   ├── test_create_product.py
│   │   │   ├── test_update_product.py
│   │   │   └── test_delete_product.py
│   │   ├── services/
│   │   │   └── test_product_service.py
│   │   └── repositories/
│   │       └── test_product_repository.py
│   ├── integration/
│   │   ├── test_api_crud_flow.py   # End-to-end CRUD flow
│   │   └── test_dynamodb_operations.py
│   └── conftest.py                 # Pytest fixtures & mocks
├── terraform/
│   ├── main.tf                     # Provider & backend config
│   ├── api_gateway.tf              # REST API: bbws-product-api-{env}
│   ├── lambda.tf                   # All 5 Lambda functions
│   ├── api_gateway_integration.tf  # Lambda integrations & routes
│   ├── iam.tf                      # Lambda execution roles (DynamoDB permissions)
│   ├── cloudwatch.tf               # Log groups & alarms
│   ├── data.tf                     # Reference existing DynamoDB table
│   ├── variables.tf
│   ├── outputs.tf                  # API URL, Lambda ARNs
│   ├── backend.tf                  # S3 backend per environment
│   └── environments/
│       ├── dev.tfvars
│       ├── sit.tfvars
│       └── prod.tfvars
├── .github/workflows/
│   ├── deploy-dev.yml              # Auto-deploy: Test → Package → Deploy → Validate
│   ├── deploy-sit.yml              # Manual approval → Deploy → Smoke tests
│   └── deploy-prod.yml             # Manual approval → Deploy → Full validation
├── scripts/
│   ├── package_lambdas.sh          # Create deployment ZIPs for all 5 Lambdas
│   ├── validate_deployment.py      # Post-deployment health checks
│   └── setup_dev_environment.sh    # Local development setup
├── requirements.txt                # boto3, pydantic, python-dateutil
├── requirements-dev.txt            # pytest, moto, black, mypy, ruff
├── pytest.ini
├── .gitignore
├── .python-version                 # Python 3.12
├── README.md                       # Quick start & developer guide
└── CLAUDE.md                       # TBT workflow integration
```

**Documentation Strategy**:
- **In Repository** (`2_bbws_product_lambda/README.md`):
  - Quick start guide
  - Local development setup
  - Running tests
  - API endpoint overview

- **Centralized** (`2_bbws_docs/runbooks/`):
  - Deployment runbooks (DEV/SIT/PROD)
  - Operational procedures
  - Troubleshooting guides
  - Disaster recovery procedures
  - CI/CD guides

**Rationale**: Operational runbooks are centralized in `2_bbws_docs` for:
- Consistency across all BBWS services
- Easy discoverability by ops team
- Shared troubleshooting knowledge
- Version control separate from code

---

## AWS Resources

### Created by This Repository

**API Gateway**:
- REST API: `bbws-product-api-{env}`
- Endpoints: GET/POST /products, GET/PUT/DELETE /products/{id}
- Stage: `v1.0`
- CloudWatch logs enabled

**Lambda Functions** (5 total):
1. `bbws-list-products-{env}` - GET /v1.0/products
2. `bbws-get-product-{env}` - GET /v1.0/products/{id}
3. `bbws-create-product-{env}` - POST /v1.0/products
4. `bbws-update-product-{env}` - PUT /v1.0/products/{id}
5. `bbws-delete-product-{env}` - DELETE /v1.0/products/{id}

**IAM Roles**:
- Lambda execution role with DynamoDB read/write permissions
- API Gateway CloudWatch logging role

**CloudWatch**:
- Log groups for each Lambda (90-day retention)
- Alarms: Lambda errors, API 4xx/5xx, DynamoDB throttling

### Referenced from External Schema

**DynamoDB Table** (must exist before deployment):
- Table: `products-{env}` (created by `2_1_bbws_dynamodb_schemas`)
- Schema: `/Users/tebogotseka/Documents/agentic_work/2_1_bbws_dynamodb_schemas/schemas/products.schema.json`
- Reference method: Terraform data source

**Data Source Reference** (terraform/data.tf):
```hcl
data "aws_dynamodb_table" "products" {
  name = "products-${var.environment}"
}

# Use in IAM policies
resource "aws_iam_role_policy" "lambda_dynamodb" {
  policy = jsonencode({
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:Query",
        "dynamodb:Scan"
      ]
      Resource = [
        data.aws_dynamodb_table.products.arn,
        "${data.aws_dynamodb_table.products.arn}/index/*"
      ]
    }]
  })
}
```

---

## Lambda Functions Detailed Spec

| Function | Method | Endpoint | DynamoDB Operation | Response | Notes |
|----------|--------|----------|-------------------|----------|-------|
| **list_products** | GET | /v1.0/products | Query ActiveProductsIndex (active=true) | 200 OK + products array | Pagination via limit/offset |
| **get_product** | GET | /v1.0/products/{productId} | GetItem (PK=PRODUCT#{id}) | 200 OK or 404 | Check active=true |
| **create_product** | POST | /v1.0/products | PutItem | 201 Created + product | Generate productId, set createdAt |
| **update_product** | PUT | /v1.0/products/{productId} | UpdateItem | 200 OK + updated product | Set updatedAt, validate exists |
| **delete_product** | DELETE | /v1.0/products/{productId} | UpdateItem (active=false) | 204 No Content | Soft delete only |

**Shared Logic**:
- All handlers use `ProductService` for business logic
- `ProductRepository` handles all DynamoDB operations
- Pydantic models for request/response validation
- Structured CloudWatch logging
- Standardized error responses

---

## Project Stages

| Stage | Name | Workers | Duration | Status |
|-------|------|---------|----------|--------|
| **Stage 1** | Repository Setup | 1 | 0.5 days | PENDING |
| **Stage 2** | Lambda Implementation & Testing (TDD) | 5 | 2.5-3 days | PENDING |
| **Stage 3** | CI/CD Pipeline & Integration Testing | 1 | 1 day | PENDING |

**Total Workers**: 7 (reduced from 10 in V3)
**Total Duration**: 4-5 working days (reduced from 5-6 in V3)

---

## Stage 1: Repository Setup

**Duration**: 0.5 days
**Workers**: 1
**Agent**: DevOps Engineer

### Worker 1-1: Repository Initialization

**Deliverables**:
1. Create `2_bbws_product_lambda/` repository on GitHub
2. Initialize repository structure (all directories)
3. Create Terraform infrastructure files:
   - `api_gateway.tf` - REST API definition
   - `lambda.tf` - All 5 Lambda function resources
   - `api_gateway_integration.tf` - Lambda integrations
   - `data.tf` - **Reference existing DynamoDB table**
   - `iam.tf` - Lambda execution roles
   - `cloudwatch.tf` - Logs & alarms
   - Backend config for DEV/SIT/PROD
4. Create GitHub Actions workflows (3: dev, sit, prod)
5. Create initial README.md and CLAUDE.md
6. Create `.gitignore`, `pytest.ini`, `requirements.txt`

**Prerequisites**:
- ✅ DynamoDB table `products-dev` must exist (deployed by `2_1_bbws_dynamodb_schemas`)
- ✅ AWS OIDC role for GitHub Actions configured
- ✅ S3 backend bucket for Terraform state exists

**Validation**:
```bash
# Verify DynamoDB table exists
aws dynamodb describe-table --table-name products-dev --region eu-west-1

# Verify schema matches expectations
# Check for: productId, name, description, price, currency, period, features, active, createdAt

# Initialize Terraform
cd terraform
terraform init -backend-config=environments/dev.tfvars

# Validate terraform (should pass without applying)
terraform validate
```

**Success Criteria**:
- ✅ Repository created with complete structure
- ✅ Terraform validates successfully
- ✅ DynamoDB data source can reference existing table
- ✅ GitHub Actions workflows created
- ✅ Ready for Stage 2

---

## Stage 2: Lambda Implementation & Testing

**Duration**: 2.5-3 days
**Workers**: 5 (parallel implementation)
**Agent**: Python AWS Developer
**Approach**: Test-Driven Development (TDD)

### Worker 2-1: list_products Lambda

**TDD Approach**:
1. Write tests first (`tests/unit/handlers/test_list_products.py`)
2. Implement handler to pass tests
3. Refactor and optimize

**Deliverables**:
1. **Tests**:
   - Unit tests: Mock DynamoDB, test query logic
   - Integration tests: Real DynamoDB query (moto)
   - Edge cases: Empty results, pagination, DynamoDB errors
2. **Implementation**:
   - `src/handlers/list_products.py` - Lambda handler
   - `src/repositories/product_repository.py` - `list_active_products()` method
   - Query ActiveProductsIndex (active=true, sort by createdAt)
3. **Coverage**: 80%+ for this Lambda

**Success Criteria**:
- ✅ All tests pass
- ✅ Returns 200 OK with products array
- ✅ Pagination works correctly
- ✅ Handles DynamoDB errors gracefully

---

### Worker 2-2: get_product Lambda

**Deliverables**:
1. **Tests**:
   - Unit tests: GetItem success, 404 not found, inactive product
   - Integration tests: Real DynamoDB get_item
2. **Implementation**:
   - `src/handlers/get_product.py`
   - `src/repositories/product_repository.py` - `get_by_id()` method
   - GetItem by PK=PRODUCT#{productId}, SK=METADATA
3. **Coverage**: 80%+

**Success Criteria**:
- ✅ Returns 200 OK for valid product
- ✅ Returns 404 for non-existent product
- ✅ Returns 404 for inactive product (active=false)

---

### Worker 2-3: create_product Lambda

**Deliverables**:
1. **Tests**:
   - Unit tests: Validation, PutItem success, duplicate detection
   - Integration tests: Create product flow
2. **Implementation**:
   - `src/handlers/create_product.py`
   - `src/validators/product_validator.py` - Request validation
   - `src/models/product.py` - Pydantic Product model
   - `src/repositories/product_repository.py` - `create()` method
   - Generate productId (e.g., PROD-001, PROD-002)
   - Set PK=PRODUCT#{productId}, SK=METADATA
   - Set createdAt timestamp
3. **Coverage**: 80%+

**Success Criteria**:
- ✅ Returns 201 Created with product object
- ✅ Validates all required fields (name, description, price, currency, period, features)
- ✅ Handles validation errors (400 Bad Request)
- ✅ Handles DynamoDB errors (500 Internal Server Error)

---

### Worker 2-4: update_product Lambda

**Deliverables**:
1. **Tests**:
   - Unit tests: Validation, UpdateItem success, 404 not found
   - Integration tests: Update flow
2. **Implementation**:
   - `src/handlers/update_product.py`
   - `src/repositories/product_repository.py` - `update()` method
   - UpdateItem with conditional expression (product exists)
   - Set updatedAt timestamp
3. **Coverage**: 80%+

**Success Criteria**:
- ✅ Returns 200 OK with updated product
- ✅ Returns 404 for non-existent product
- ✅ Validates update data
- ✅ Prevents updating inactive products

---

### Worker 2-5: delete_product Lambda

**Deliverables**:
1. **Tests**:
   - Unit tests: Soft delete, 404 not found, idempotency
   - Integration tests: Delete flow
2. **Implementation**:
   - `src/handlers/delete_product.py`
   - `src/repositories/product_repository.py` - `soft_delete()` method
   - UpdateItem (set active=false, updatedAt)
   - **Soft delete only** - data retained
3. **Coverage**: 80%+

**Success Criteria**:
- ✅ Returns 204 No Content
- ✅ Returns 404 for non-existent product
- ✅ Product remains in DynamoDB with active=false
- ✅ Idempotent (deleting again returns 204)

---

### Shared Components (All Workers)

**Created during Stage 2**:
- `src/services/product_service.py` - Business logic layer (shared)
- `src/repositories/product_repository.py` - DynamoDB operations (shared)
- `src/models/product.py` - Pydantic models (shared)
- `src/validators/product_validator.py` - Validation logic (shared)
- `src/utils/response_builder.py` - Standardized responses (shared)
- `src/utils/logger.py` - CloudWatch logging (shared)
- `src/exceptions/product_exceptions.py` - Custom exceptions (shared)

**Testing Requirements**:
- Unit test coverage: 80%+ per Lambda
- Integration tests: CRUD flow end-to-end
- Mocking: moto for DynamoDB, pytest fixtures
- Code quality: black (formatting), mypy (type checking), ruff (linting)

---

## Stage 3: CI/CD Pipeline & Integration Testing

**Duration**: 1 day
**Workers**: 1
**Agent**: DevOps Engineer

### Worker 3-1: CI/CD Implementation

**Deliverables**:
1. **GitHub Actions Workflows**:
   - `deploy-dev.yml` - Auto-deploy on main branch push
   - `deploy-sit.yml` - Manual trigger with approval
   - `deploy-prod.yml` - Manual trigger with strict approval

2. **Workflow Steps** (all environments):
   ```yaml
   - Checkout code
   - Setup Python 3.12
   - Install dependencies
   - Run tests (pytest with coverage)
   - Lint & format check (black, mypy, ruff)
   - Package Lambdas (ZIP files)
   - Setup Terraform
   - Terraform init
   - Terraform validate
   - Terraform plan
   - [APPROVAL GATE for SIT/PROD]
   - Terraform apply
   - Post-deployment validation (API health check)
   - Smoke tests (create/read/delete flow)
   ```

3. **Post-Deployment Validation**:
   - `scripts/validate_deployment.py`:
     - Test GET /v1.0/products (should return 200)
     - Test GET /v1.0/products/PROD-001 (should return 200 or 404)
     - Test POST /v1.0/products (create test product)
     - Test DELETE /v1.0/products/{id} (clean up)

4. **Integration Tests**:
   - End-to-end CRUD flow test
   - API Gateway → Lambda → DynamoDB → Response
   - Error handling (404, 400, 500)

5. **Centralized Documentation** (in `2_bbws_docs/runbooks/`):

   **Runbooks Created**:
   - `2_bbws_docs/runbooks/product_lambda_deployment.md`:
     - Prerequisites (DynamoDB table, AWS credentials)
     - DEV deployment steps
     - SIT deployment steps
     - PROD deployment steps
     - Rollback procedures

   - `2_bbws_docs/runbooks/product_lambda_operations.md`:
     - Monitoring (CloudWatch dashboards)
     - Common alerts and responses
     - Troubleshooting guide (404s, 500s, timeouts)
     - Performance tuning
     - Scaling considerations

   - `2_bbws_docs/runbooks/product_lambda_disaster_recovery.md`:
     - Backup verification
     - Restore procedures
     - Multi-region failover (if applicable)
     - RTO/RPO targets

   **Deployment Guides Created**:
   - `2_bbws_docs/runbooks/product_lambda_dev_setup.md`:
     - Local development environment setup
     - Running tests locally
     - Debugging Lambda functions
     - Mock DynamoDB setup

   - `2_bbws_docs/runbooks/product_lambda_cicd_guide.md`:
     - GitHub Actions workflow overview
     - Secrets configuration
     - OIDC role setup
     - Terraform state management
     - Approval process (SIT/PROD)

**Success Criteria**:
- ✅ DEV workflow deploys automatically
- ✅ SIT/PROD workflows require approval
- ✅ All tests pass in CI pipeline
- ✅ Post-deployment validation succeeds
- ✅ Smoke tests confirm API functionality
- ✅ All runbooks created in `2_bbws_docs/runbooks/`
- ✅ Deployment guides are comprehensive and tested

---

## Deployment Flow

### DEV Environment
1. Push to `main` branch
2. GitHub Actions auto-triggers `deploy-dev.yml`
3. Tests run → Package → Terraform apply → Deploy
4. Post-deployment validation
5. ✅ Live in DEV

### SIT Environment
1. Manual trigger of `deploy-sit.yml`
2. Select branch/tag to deploy
3. Tests run → Package → Terraform plan
4. **Human approval required**
5. Terraform apply → Deploy
6. Smoke tests
7. ✅ Live in SIT

### PROD Environment
1. Manual trigger of `deploy-prod.yml`
2. Select release tag
3. Tests run → Package → Terraform plan
4. **Senior engineer approval required**
5. Terraform apply → Deploy
6. Full validation suite
7. ✅ Live in PROD

---

## Dependencies & Prerequisites

### Before Starting Implementation

1. **DynamoDB Table Deployed**:
   - Deploy `2_1_bbws_dynamodb_schemas` to DEV first
   - Verify table `products-dev` exists
   - Verify schema matches updated version (productId, currency, period, createdAt)

2. **AWS Infrastructure**:
   - AWS OIDC role for GitHub Actions (DEV: 536580886816)
   - S3 bucket for Terraform state
   - CloudWatch log groups permissions

3. **GitHub Setup**:
   - Repository secrets: AWS_ROLE_ARN, AWS_REGION
   - Branch protection rules (main branch)

### During Development

- Python 3.12 environment
- AWS CLI configured
- Terraform 1.5+
- pytest, moto for testing

---

## Success Metrics

| Metric | Target | Validation |
|--------|--------|------------|
| **Test Coverage** | 80%+ | pytest-cov report |
| **API Response Time (p95)** | < 250ms | CloudWatch metrics |
| **Lambda Cold Start** | < 2s | CloudWatch Insights |
| **Deployment Time** | < 10 minutes | GitHub Actions logs |
| **Zero Downtime** | 100% | Health check during deploy |
| **Error Rate** | < 0.1% | CloudWatch alarms |

---

## Risk Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| DynamoDB table doesn't exist | High | Validate table exists in Stage 1 |
| Schema mismatch | High | Schema validation in tests |
| Lambda timeout | Medium | 30s timeout, optimize queries |
| API Gateway throttling | Low | Default limits sufficient, monitor |
| Deployment failure | Medium | Terraform state rollback, smoke tests |

---

## Timeline Summary

| Day | Stage | Activities | Deliverable |
|-----|-------|------------|-------------|
| **Day 1** | Stage 1 | Repository setup, Terraform infrastructure | Repo ready, infra validated |
| **Days 2-4** | Stage 2 | Implement 5 Lambdas (TDD), shared components, tests | All Lambdas tested, 80%+ coverage |
| **Day 5** | Stage 3 | CI/CD workflows, integration tests, deploy to DEV | Working CI/CD, DEV deployed |

**Total**: 4-5 working days

---

## Approval Gates

| Gate | Required For | Approver |
|------|--------------|----------|
| **Gate 0** | Start implementation | User (approve this plan) |
| **Gate 1** | Stage 1 → Stage 2 | Automated (Terraform validate) |
| **Gate 2** | Stage 2 → Stage 3 | Automated (80%+ test coverage) |
| **Gate 3** | DEV deployment | Automated (all tests pass) |
| **Gate 4** | SIT deployment | Manual approval |
| **Gate 5** | PROD deployment | Senior engineer approval |

---

## Comparison: All Versions

| Aspect | V1 | V2 | V3 | V4 ⭐ |
|--------|----|----|----|----|
| **Repositories** | 8 | 2 | 2 | **1** |
| **Lambda Functions** | 9 | 6 | 5 | **5** |
| **SQS** | ✅ | ✅ | ❌ | ❌ |
| **Infrastructure Repo** | ✅ | ✅ | ✅ | ❌ |
| **API Gateway** | Infra repo | Infra repo | Infra repo | **Lambda repo** |
| **DynamoDB** | Per-repo | Infra repo | Infra repo | **Reference schema** |
| **Workers** | 27 | 12 | 10 | **7** |
| **Timeline** | 10 days | 7 days | 5-6 days | **4-5 days** |
| **Complexity** | High | Medium | Low | **Lowest** |

---

## Next Steps

After approval:
1. Initialize Stage 1: Create repository structure
2. Deploy `2_1_bbws_dynamodb_schemas` to DEV (if not already deployed)
3. Validate DynamoDB table and schema
4. Execute Stage 1 → Stage 2 → Stage 3
5. Deploy to DEV → SIT → PROD

---

**Status**: 🟢 READY FOR USER APPROVAL

**Awaiting**: Your confirmation to proceed with V4 single-repo architecture

**Reply**: "GO", "APPROVED", or "Proceed with V4"

---

**Created**: 2025-12-29
**Version**: 4.0 (Single Repository Architecture)
**Next**: User approval to start Stage 1
