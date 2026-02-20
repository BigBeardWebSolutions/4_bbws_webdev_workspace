# Plan Comparison: Microservices (V1) vs Monorepo (V2)

**Date**: 2025-12-29
**Decision**: User requested monorepo approach to avoid repository proliferation

---

## Executive Summary

**Recommendation**: ✅ **Approve V2 (Monorepo Plan)**

| Metric | V1 (Microservices) | V2 (Monorepo) | Improvement |
|--------|-------------------|---------------|-------------|
| **Repositories** | 8 | 2 | ✅ 75% reduction |
| **Lambda Functions** | 9 | 6 | ✅ 33% reduction |
| **Stages** | 4 | 3 | ✅ 25% reduction |
| **Workers** | 27 | 12 | ✅ 56% reduction |
| **Timeline** | 10 days | 7 days | ✅ 30% faster |
| **GitHub Workflows** | 24 | 6 | ✅ 75% reduction |
| **Complexity** | High | Medium | ✅ Simpler |
| **Maintenance Overhead** | High | Low | ✅ Easier |
| **Deployment Complexity** | 8 separate deploys | 2 deploys | ✅ Simpler |

---

## Architecture Comparison

### V1: Microservices (8 Repositories)

```
2_1_bbws_product_infrastructure/     (Shared resources)
2_1_bbws_list_products/              (GET /products)
2_1_bbws_get_product/                (GET /products/{id})
2_1_bbws_create_product/             (POST /products)
2_1_bbws_update_product/             (PUT /products/{id})
2_1_bbws_delete_product/             (DELETE /products/{id})
2_1_bbws_product_creator/            (SQS → DynamoDB)
2_1_bbws_audit_logger/               (SQS → S3)

REMOVED (per user request):
- ProductSearchIndexer               (SQS → OpenSearch)
- ProductCacheInvalidator            (SQS → CloudFront)
```

**Pros**:
- ✅ Maximum isolation per Lambda
- ✅ Independent scaling
- ✅ Team can own individual services

**Cons**:
- ❌ 8 repositories to manage
- ❌ 24 GitHub Actions workflows
- ❌ Code duplication (shared models, utils)
- ❌ Complex coordination
- ❌ More overhead

---

### V2: Monorepo (2 Repositories) ⭐ RECOMMENDED

```
2_1_bbws_product_infrastructure/     (Shared resources)
2_bbws_product_lambda/               (All 6 Lambdas in one repo)
    ├── list_products
    ├── get_product
    ├── create_product
    ├── update_product
    ├── delete_product
    └── product_creator
```

**Pros**:
- ✅ Only 2 repositories to manage
- ✅ Only 6 GitHub Actions workflows
- ✅ Shared code in one place (no duplication)
- ✅ Single deployment unit
- ✅ Simpler CI/CD
- ✅ 7-day timeline (vs 10 days)
- ✅ Easier testing (all functions in one repo)
- ✅ Less maintenance overhead

**Cons**:
- ⚠️ All Lambdas deploy together (acceptable for small service)
- ⚠️ Less isolation (mitigated by function boundaries)

---

## Lambda Functions Comparison

### V1: 9 Lambda Functions

| Function | Type | Kept in V2? |
|----------|------|-------------|
| list_products | API | ✅ YES |
| get_product | API | ✅ YES |
| create_product | API | ✅ YES |
| update_product | API | ✅ YES |
| delete_product | API | ✅ YES |
| ProductCreatorRecord | Event | ✅ YES |
| ProductSearchIndexer | Event | ❌ REMOVED (user request) |
| ProductCacheInvalidator | Event | ❌ REMOVED (user request) |
| ProductAuditLogger | Event | ❌ REMOVED (user request) |

### V2: 6 Lambda Functions

**API Handlers** (5):
1. list_products - GET /v1.0/products
2. get_product - GET /v1.0/products/{id}
3. create_product - POST /v1.0/products
4. update_product - PUT /v1.0/products/{id}
5. delete_product - DELETE /v1.0/products/{id}

**Event Processor** (1):
6. product_creator - SQS → DynamoDB (handles CREATE/UPDATE/DELETE)

---

## LLD Changes

**File**: `2.1.4_LLD_Product_Lambda.md`
**Version**: 2.0 → 3.0

**Changes Made**:
1. ✅ Removed ProductAuditLogger from architecture
2. ✅ Removed ProductSearchIndexer from architecture
3. ✅ Removed ProductCacheInvalidator from architecture
4. ✅ Updated component diagram (removed 3 handler classes)
5. ✅ Updated user stories (removed US-PRD-009, US-PRD-010, US-PRD-011)
6. ✅ Updated architecture pattern description (single event processor)
7. ✅ Updated version to 3.0
8. ✅ Updated last modified date to 2025-12-29
9. ✅ Added v3.0 changelog entry

**Document Status**: ✅ Updated and consistent with V2 plan

---

## Timeline Comparison

### V1: 10 Working Days

| Stage | Duration | Activities |
|-------|----------|------------|
| Stage 1 | 2 days | Create 8 repositories + deploy infrastructure |
| Stage 2 | 4 days | Implement 7 Lambdas |
| Stage 3 | 2 days | Create 24 workflows |
| Stage 4 | 2 days | Integration testing + docs |
| **TOTAL** | **10 days** | |

### V2: 7 Working Days ⭐ 30% FASTER

| Stage | Duration | Activities |
|-------|----------|------------|
| Stage 1 | 1 day | Create 2 repositories + deploy infrastructure |
| Stage 2 | 4 days | Implement 6 Lambdas (same duration, TDD) |
| Stage 3 | 2 days | Create 6 workflows + integration testing + docs |
| **TOTAL** | **7 days** | |

**Time Saved**: 3 days (30% reduction)

---

## Worker Comparison

### V1: 27 Workers

**Stage 1**: 8 workers (1 infrastructure + 7 Lambda repos)
**Stage 2**: 7 workers (7 Lambda implementations)
**Stage 3**: 8 workers (8 workflow sets)
**Stage 4**: 4 workers (testing + docs)

### V2: 12 Workers ⭐ 56% REDUCTION

**Stage 1**: 2 workers (1 infrastructure + 1 Lambda repo structure)
**Stage 2**: 6 workers (6 Lambda implementations)
**Stage 3**: 4 workers (2 workflow sets + testing + docs)

**Workers Saved**: 15 workers (56% reduction)

---

## Workflow Comparison

### V1: 24 GitHub Actions Workflows

| Repository | Workflows | Total |
|------------|-----------|-------|
| Infrastructure | 3 (DEV/SIT/PROD) | 3 |
| list_products | 3 | 3 |
| get_product | 3 | 3 |
| create_product | 3 | 3 |
| update_product | 3 | 3 |
| delete_product | 3 | 3 |
| product_creator | 3 | 3 |
| audit_logger | 3 | 3 |
| **TOTAL** | | **24** |

**Maintenance**: 24 workflow files to maintain

### V2: 6 GitHub Actions Workflows ⭐ 75% REDUCTION

| Repository | Workflows | Total |
|------------|-----------|-------|
| Infrastructure | 3 (DEV/SIT/PROD) | 3 |
| Product Lambda | 3 (DEV/SIT/PROD) | 3 |
| **TOTAL** | | **6** |

**Maintenance**: 6 workflow files to maintain

**Workflows Saved**: 18 workflows (75% reduction)

---

## Deployment Complexity

### V1: 8 Separate Deployments

**Deploy Order**:
1. Infrastructure repo → DEV
2. Lambda repo 1 → DEV
3. Lambda repo 2 → DEV
4. Lambda repo 3 → DEV
5. Lambda repo 4 → DEV
6. Lambda repo 5 → DEV
7. Lambda repo 6 → DEV
8. Lambda repo 7 → DEV

**Promotion to SIT**: Repeat 8 deployments
**Promotion to PROD**: Repeat 8 deployments

**Total Deployments per Environment**: 8
**Total for 3 Environments**: 24 deployments

### V2: 2 Deployments ⭐ 75% REDUCTION

**Deploy Order**:
1. Infrastructure repo → DEV
2. Product Lambda repo → DEV (all 6 functions together)

**Promotion to SIT**: Repeat 2 deployments
**Promotion to PROD**: Repeat 2 deployments

**Total Deployments per Environment**: 2
**Total for 3 Environments**: 6 deployments

**Deployments Saved**: 18 deployments (75% reduction)

---

## Code Sharing

### V1: Code Duplication

**Duplicated Files** (across 7 Lambda repos):
- `models/product.py` - Duplicated 7 times
- `models/events.py` - Duplicated 7 times
- `utils/response_builder.py` - Duplicated 7 times
- `utils/logger.py` - Duplicated 7 times

**Problem**: Changes require updates in 7 places
**Risk**: Version drift, inconsistency

### V2: Shared Code ⭐ DRY PRINCIPLE

**Shared Files** (in single repo):
- `src/models/product.py` - Single source of truth
- `src/models/events.py` - Single source of truth
- `src/utils/response_builder.py` - Single source of truth
- `src/utils/logger.py` - Single source of truth

**Benefit**: Change once, used by all 6 Lambdas
**Risk**: None (all functions in same repo)

---

## Testing Strategy

### V1: Testing Across 8 Repos

- 8 separate test suites
- 8 pytest configurations
- 8 coverage reports
- Hard to test integration between Lambdas

### V2: Unified Testing ⭐ EASIER

- 1 test suite for all functions
- 1 pytest configuration
- 1 coverage report (overall 80%+ target)
- Easy integration testing (all functions in same repo)

**Test Structure** (V2):
```
tests/
├── unit/
│   ├── handlers/           # Test all 6 handlers
│   ├── services/
│   └── repositories/
├── integration/
│   ├── test_product_api.py       # Test all 5 API endpoints
│   ├── test_event_driven.py      # Test ProductCreator
│   └── test_crud_flow.py         # E2E flow
└── conftest.py
```

---

## Recommendation

### ✅ Approve V2 (Monorepo Plan)

**Reasons**:
1. **75% fewer repositories** (2 vs 8) - Less overhead
2. **56% fewer workers** (12 vs 27) - Faster execution
3. **30% faster timeline** (7 days vs 10 days)
4. **75% fewer workflows** (6 vs 24) - Less maintenance
5. **DRY principle** - Shared code, no duplication
6. **Simpler deployment** - 2 deploys vs 8
7. **Easier testing** - Unified test suite
8. **Lower complexity** - Medium vs High
9. **User request** - Avoid repository proliferation
10. **LLD updated** - v3.0 reflects monorepo architecture

**Trade-offs**:
- ⚠️ All Lambdas deploy together (acceptable for small service)
- ⚠️ Less isolation (mitigated by function boundaries and IAM)

**Conclusion**: V2 is significantly simpler, faster, and easier to maintain while delivering the same functionality.

---

## Next Steps

**If V2 Approved**:
1. ✅ Use PROJECT_PLAN_V2_MONOREPO.md (not PROJECT_PLAN.md)
2. ✅ LLD already updated to v3.0
3. ✅ Initialize Stage 1 with 2 workers (not 8)
4. ✅ Create 2 repositories (not 8)
5. ✅ Deploy in 7 days (not 10)

**Files to Use**:
- ✅ PROJECT_PLAN_V2_MONOREPO.md (this is the active plan)
- ✅ 2.1.4_LLD_Product_Lambda.md (v3.0 - updated)
- ⚠️ Ignore PROJECT_PLAN.md (superseded by V2)

---

## User Approval Required

**Please confirm**:
- ✅ Approve V2 monorepo plan (2 repos, 7 days)
- ✅ LLD v3.0 changes acceptable
- ✅ 6 Lambda functions sufficient (3 removed)
- ✅ Ready to proceed with Stage 1

**To Approve**: Reply "GO" or "APPROVED" or "Proceed with V2"

---

**Document**: Plan Comparison V1 vs V2
**Status**: Awaiting User Confirmation
**Recommendation**: ✅ Approve V2 (Monorepo)
**Created**: 2025-12-29
