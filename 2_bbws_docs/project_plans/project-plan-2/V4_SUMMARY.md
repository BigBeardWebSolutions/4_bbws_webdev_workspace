# V4 Single Repository Architecture - Summary

**Date**: 2025-12-29
**Status**: ✅ COMPLETE - Ready for Your Approval

---

## What Was Completed

### 1. ✅ LLD Cleanup (SQS Removal)

**File**: `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/2.1.4_LLD_Product_Lambda.md`

**Changes**:
- ✅ Simplified Document Control (removed SQS version history)
- ✅ Removed Section 4.3 (Event-Driven flows) - 218 lines deleted
- ✅ Removed ProductChangeEvent class (SQS message schema)
- ✅ Removed Section 5.3 (SQS Queue Configuration) - 111 lines deleted
- ✅ Updated NFRs (performance metrics now reflect direct DB)
- ✅ Updated Risks (removed SQS-related risks)

**Result**: LLD is 100% clean of SQS implementation details

---

### 2. ✅ DynamoDB Schema Update (Option A)

**File**: `/Users/tebogotseka/Documents/agentic_work/2_1_bbws_dynamodb_schemas/schemas/products.schema.json`

**Changes**:
```diff
- "id"              → "productId"
- (missing)         → "currency" (ADDED with default "ZAR")
- "billingCycle"    → "period"
- "dateCreated"     → "createdAt"
- "dateLastUpdated" → "updatedAt"
- "lastUpdatedBy"   → (REMOVED - not needed)
```

**GSI Changes**:
- ✅ Removed duplicate GSI (ProductActiveIndex + ActiveIndex → ActiveProductsIndex)
- ✅ Updated sort key reference (dateCreated → createdAt)

**Streams**:
- ✅ Disabled (changed from enabled to disabled - not needed for direct DB)

**Result**: Schema now perfectly matches LLD requirements

---

### 3. ✅ Project Plan V4 Created

**File**: `PROJECT_PLAN_V4_SINGLE_REPO.md`

**Architecture**: Single Repository (no separate infrastructure repo)

---

## Architecture Comparison

### Before (V3 - 2 Repos)
```
2_1_bbws_product_infrastructure/     2_bbws_product_lambda/
├── terraform/                       ├── src/
│   ├── api_gateway.tf              │   └── handlers/
│   ├── dynamodb.tf                 ├── terraform/
│   ├── iam.tf                      │   ├── lambda.tf
│   └── cloudwatch.tf               │   └── api_integration.tf
└── .github/workflows/ (3)          └── .github/workflows/ (3)

Deploy Order: Infrastructure FIRST, then Lambda
Total Repos: 2
Total Workflows: 6
Timeline: 5-6 days
Workers: 10
```

### After (V4 - 1 Repo) ⭐ SIMPLEST
```
2_bbws_product_lambda/
├── src/
│   └── handlers/ (5 Lambdas)
├── terraform/
│   ├── api_gateway.tf         # Self-contained
│   ├── lambda.tf              # All 5 functions
│   ├── data.tf                # Reference existing DynamoDB
│   └── iam.tf
└── .github/workflows/ (3)

Deploy Order: Single deployment (references existing DynamoDB)
Total Repos: 1
Total Workflows: 3
Timeline: 4-5 days
Workers: 7
```

---

## Key Benefits of V4

### Simplicity
- ✅ **1 repository** instead of 2 (50% reduction)
- ✅ **No infrastructure repo** to maintain
- ✅ **Self-contained** - API Gateway + Lambdas together
- ✅ **7 workers** instead of 10 (30% reduction)

### Reusability
- ✅ **References existing DynamoDB schema** from `2_1_bbws_dynamodb_schemas`
- ✅ **No schema duplication** - single source of truth
- ✅ **Schema updates** centralized in one place

### Speed
- ✅ **4-5 days** instead of 5-6 days (20% faster)
- ✅ **Single deployment** - no waiting for infrastructure
- ✅ **Parallel development** - 5 workers on 5 Lambdas

### Maintenance
- ✅ **3 workflows** instead of 6 (50% reduction)
- ✅ **Simpler CI/CD** - one pipeline
- ✅ **Easier troubleshooting** - all code in one repo

---

## V4 Repository Structure

```
2_bbws_product_lambda/
├── src/
│   ├── handlers/              # 5 Lambda functions
│   │   ├── list_products.py   # GET /v1.0/products
│   │   ├── get_product.py     # GET /v1.0/products/{id}
│   │   ├── create_product.py  # POST /v1.0/products
│   │   ├── update_product.py  # PUT /v1.0/products/{id}
│   │   └── delete_product.py  # DELETE /v1.0/products/{id}
│   ├── services/              # Business logic
│   ├── repositories/          # DynamoDB access
│   ├── models/                # Pydantic models
│   ├── validators/            # Input validation
│   └── utils/                 # Response builder, logger
├── tests/
│   ├── unit/                  # 80%+ coverage
│   ├── integration/           # CRUD flow tests
│   └── conftest.py
├── terraform/
│   ├── api_gateway.tf         # REST API: bbws-product-api-{env}
│   ├── lambda.tf              # All 5 Lambda functions
│   ├── api_gateway_integration.tf  # Lambda integrations
│   ├── data.tf                # Reference products-{env} table
│   ├── iam.tf                 # Lambda roles (DynamoDB permissions)
│   └── cloudwatch.tf          # Logs & alarms
├── .github/workflows/
│   ├── deploy-dev.yml         # Auto-deploy
│   ├── deploy-sit.yml         # Manual approval
│   └── deploy-prod.yml        # Manual approval
└── scripts/
    ├── package_lambdas.sh     # ZIP all 5 Lambdas
    └── validate_deployment.py # Health checks
```

---

## DynamoDB Reference Pattern

**Key Concept**: Lambda repo **references** existing DynamoDB table, doesn't create it

**terraform/data.tf**:
```hcl
# Reference existing table (created by 2_1_bbws_dynamodb_schemas)
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

**Prerequisite**: DynamoDB table `products-dev` must exist before deploying this Lambda repo

---

## Timeline & Stages

| Day | Stage | Workers | Activities |
|-----|-------|---------|------------|
| **Day 1** | Stage 1: Setup | 1 | Create repo, Terraform infra, GitHub workflows |
| **Days 2-4** | Stage 2: Implementation | 5 | TDD: Implement 5 Lambdas (parallel) |
| **Day 5** | Stage 3: CI/CD & Docs | 1 | Workflows, integration tests, deploy DEV, create runbooks |

**Total**: 4-5 working days
**Total Workers**: 7

**Documentation Deliverables** (Stage 3):
- `2_bbws_docs/runbooks/product_lambda_deployment.md`
- `2_bbws_docs/runbooks/product_lambda_operations.md`
- `2_bbws_docs/runbooks/product_lambda_disaster_recovery.md`
- `2_bbws_docs/runbooks/product_lambda_dev_setup.md`
- `2_bbws_docs/runbooks/product_lambda_cicd_guide.md`

---

## Lambda Functions

| Function | Method | Endpoint | DynamoDB Operation | Response |
|----------|--------|----------|-------------------|----------|
| **list_products** | GET | /v1.0/products | Query ActiveProductsIndex | 200 OK + products[] |
| **get_product** | GET | /v1.0/products/{id} | GetItem (PK=PRODUCT#{id}) | 200 OK or 404 |
| **create_product** | POST | /v1.0/products | PutItem | **201 Created** |
| **update_product** | PUT | /v1.0/products/{id} | UpdateItem | **200 OK** |
| **delete_product** | DELETE | /v1.0/products/{id} | UpdateItem (active=false) | **204 No Content** |

**All operations are synchronous** - no SQS, immediate consistency

---

## Prerequisites

Before starting implementation:

1. ✅ **DynamoDB Schema Deployed**:
   - Deploy `2_1_bbws_dynamodb_schemas` to DEV
   - Verify table `products-dev` exists
   - Verify schema matches updated version (productId, currency, period, createdAt)

2. ✅ **AWS Infrastructure**:
   - AWS OIDC role for GitHub Actions (DEV: 536580886816)
   - S3 bucket for Terraform state
   - CloudWatch permissions

3. ✅ **GitHub Setup**:
   - Repository secrets configured
   - Branch protection rules

---

## Success Metrics

| Metric | Target |
|--------|--------|
| Test Coverage | 80%+ |
| API Response (p95) | < 250ms |
| Lambda Cold Start | < 2s |
| Deployment Time | < 10 min |
| Error Rate | < 0.1% |

---

## What's Next

After your approval:

1. **Stage 1** (0.5 days):
   - Create `2_bbws_product_lambda` repository
   - Initialize structure (src/, terraform/, tests/, .github/)
   - Create Terraform files (API Gateway + Lambda + data source)
   - Create GitHub Actions workflows

2. **Stage 2** (2.5-3 days):
   - Implement 5 Lambda functions (TDD approach)
   - Write comprehensive tests (80%+ coverage)
   - Create shared components (service, repository, models)

3. **Stage 3** (1 day):
   - Finalize CI/CD workflows
   - Integration tests
   - Deploy to DEV
   - Post-deployment validation

---

## Files Created/Updated

| File | Status | Purpose |
|------|--------|---------|
| `2.1.4_LLD_Product_Lambda.md` | ✅ UPDATED v4.0 | LLD clean of SQS |
| `products.schema.json` | ✅ UPDATED | Schema matches LLD |
| `PROJECT_PLAN_V4_SINGLE_REPO.md` | ✅ NEW | Single repo plan |
| `.tbt/state/state.md` | ✅ UPDATED | State tracking |
| `V4_SUMMARY.md` | ✅ NEW | This file |

---

## Approval Checklist

Please confirm you're OK with:

- ✅ **1 repository** (no separate infrastructure repo)
- ✅ **API Gateway** in lambda repo terraform
- ✅ **DynamoDB** referenced from `2_1_bbws_dynamodb_schemas`
- ✅ **Updated schema** (productId, currency, period, createdAt)
- ✅ **4-5 day timeline**
- ✅ **7 workers** (reduced from 10)
- ✅ **Single deployment** (prerequisites: DynamoDB table exists)

---

## To Approve

Reply with:
- **"GO"** or
- **"APPROVED"** or
- **"Proceed with V4"** or
- **"Start implementation"**

---

## What Happens After Approval

1. Initialize Stage 1 (create repository structure)
2. Validate DynamoDB table exists in DEV
3. Create Terraform infrastructure files
4. Create GitHub Actions workflows
5. Execute Stage 2 (implement 5 Lambdas)
6. Execute Stage 3 (CI/CD and deploy to DEV)
7. **Complete in 4-5 days**

---

**Status**: 🟢 **READY FOR YOUR APPROVAL**

**Current Architecture**: V4 (Single Repo) - 1 repo, 5 Lambdas, NO SQS, API Gateway included

**Timeline**: 4-5 working days

**Next**: Awaiting your approval to proceed

---

**Created**: 2025-12-29
**Document**: V4 Single Repository Summary
**Version**: 4.0 (Simplest Architecture)
