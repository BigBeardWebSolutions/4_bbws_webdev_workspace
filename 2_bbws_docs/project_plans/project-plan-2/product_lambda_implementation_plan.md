# Product Lambda Implementation Plan

**Date**: 2025-12-27
**LLD Reference**: 2.1.4_LLD_Product_Lambda.md (Version 2.0)
**Status**: 🟡 Pending User Approval
**Complexity**: High (Event-driven architecture with 9 Lambda functions)

---

## Executive Summary

This plan implements the Product Lambda service for the BBWS Customer Portal Public, following the same infrastructure patterns established in the S3 and DynamoDB repositories. The service provides CRUD operations for product management with an event-driven architecture for write operations.

**Key Deliverables**:
- New repository: `2_bbws_product_lambda` with Python 3.12 Lambda functions
- Infrastructure: API Gateway, Lambda, DynamoDB, SQS, CloudFront, OpenSearch, S3
- Multi-environment deployment: DEV (auto-deploy), SIT/PROD (approval gates)
- Comprehensive testing: Unit + Integration tests (TDD approach)
- OpenAPI 3.0 specification for REST API

---

## 1. Repository Structure

### 1.1 Create New Repository

**Repository Name**: `2_bbws_product_lambda`
**Location**: `/Users/tebogotseka/Documents/agentic_work/2_bbws_product_lambda`

**Directory Structure** (as per LLD Appendix):
```
2_bbws_product_lambda/
├── .github/
│   └── workflows/
│       ├── deploy-dev.yml          # Auto-deploy on push to main
│       ├── deploy-sit.yml          # Manual with approval gate
│       └── deploy-prod.yml         # Manual with strict approval
├── src/
│   ├── handlers/
│   │   ├── __init__.py
│   │   ├── list_products.py        # GET /v1.0/products
│   │   ├── get_product.py          # GET /v1.0/products/{productId}
│   │   ├── create_product.py       # POST /v1.0/products (publishes to SQS)
│   │   ├── update_product.py       # PUT /v1.0/products/{productId} (publishes to SQS)
│   │   └── delete_product.py       # DELETE /v1.0/products/{productId} (publishes to SQS)
│   ├── event_handlers/
│   │   ├── __init__.py
│   │   ├── product_creator.py      # SQS -> DynamoDB
│   │   ├── cache_invalidator.py    # SQS -> CloudFront
│   │   ├── search_indexer.py       # SQS -> OpenSearch
│   │   └── audit_logger.py         # SQS -> S3
│   ├── services/
│   │   ├── __init__.py
│   │   ├── product_service.py      # Business logic
│   │   ├── sqs_service.py          # SQS message publishing
│   │   ├── cache_service.py        # CloudFront invalidation
│   │   ├── search_service.py       # OpenSearch operations
│   │   └── audit_service.py        # S3 audit logging
│   ├── repositories/
│   │   ├── __init__.py
│   │   └── product_repository.py   # DynamoDB data access
│   ├── models/
│   │   ├── __init__.py
│   │   ├── product.py              # Pydantic models
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
│   │   ├── handlers/               # Test all 9 handlers
│   │   ├── services/
│   │   └── repositories/
│   ├── integration/
│   │   ├── test_product_api.py
│   │   ├── test_event_driven.py
│   │   └── test_crud_flow.py
│   └── conftest.py                 # Pytest fixtures
├── terraform/
│   ├── modules/
│   │   ├── api_gateway/            # API Gateway module
│   │   ├── lambda/                 # Lambda functions module
│   │   ├── dynamodb/               # DynamoDB table module
│   │   ├── sqs/                    # SQS queues module
│   │   ├── s3/                     # Audit logs bucket module
│   │   └── monitoring/             # CloudWatch alarms module
│   ├── main.tf
│   ├── api_gateway.tf
│   ├── lambda.tf                   # 9 Lambda functions
│   ├── dynamodb.tf                 # Products table
│   ├── sqs.tf                      # ProductChangeQueue + DLQ
│   ├── s3.tf                       # Audit logs bucket
│   ├── iam.tf                      # IAM roles and policies
│   ├── cloudwatch.tf               # Logs and alarms
│   ├── variables.tf
│   ├── outputs.tf
│   ├── backend.tf                  # S3 backend config
│   └── environments/
│       ├── dev.tfvars
│       ├── sit.tfvars
│       └── prod.tfvars
├── openapi/
│   └── product-api.yaml            # OpenAPI 3.0 specification
├── scripts/
│   ├── deploy.sh                   # Deployment helper script
│   ├── seed_products.py            # Seed initial product data
│   └── validate_deployment.py      # Post-deployment validation
├── requirements.txt                # Runtime dependencies
├── requirements-dev.txt            # Development dependencies
├── pytest.ini                      # Pytest configuration
├── .gitignore
├── .env.example                    # Environment variables template
├── README.md
└── CLAUDE.md                       # Project-specific instructions
```

**Total Files to Create**: ~60-70 files

---

## 2. Infrastructure Components

### 2.1 AWS Resources (Per Environment)

| Resource | Name Pattern | Purpose |
|----------|--------------|---------|
| **API Gateway** | `bbws-product-api-{env}` | REST API for product endpoints |
| **Lambda Functions (9 total)** | | |
| └─ list_products | `bbws-list-products-{env}` | GET /v1.0/products |
| └─ get_product | `bbws-get-product-{env}` | GET /v1.0/products/{id} |
| └─ create_product | `bbws-create-product-{env}` | POST /v1.0/products |
| └─ update_product | `bbws-update-product-{env}` | PUT /v1.0/products/{id} |
| └─ delete_product | `bbws-delete-product-{env}` | DELETE /v1.0/products/{id} |
| └─ product_creator | `bbws-product-creator-{env}` | SQS -> DynamoDB |
| └─ cache_invalidator | `bbws-cache-invalidator-{env}` | SQS -> CloudFront |
| └─ search_indexer | `bbws-search-indexer-{env}` | SQS -> OpenSearch |
| └─ audit_logger | `bbws-audit-logger-{env}` | SQS -> S3 |
| **DynamoDB Table** | `bbws-products-{env}` | Product storage |
| **SQS Queue** | `bbws-product-change-{env}` | Product change events |
| **SQS DLQ** | `bbws-product-change-dlq-{env}` | Failed messages |
| **S3 Bucket** | `bbws-product-audit-logs-{env}` | Audit trail storage |
| **CloudWatch Log Groups (9)** | `/aws/lambda/bbws-*-{env}` | Lambda logs |
| **CloudWatch Alarms** | Multiple per environment | Monitoring |
| **IAM Roles (9)** | `bbws-product-*-role-{env}` | Lambda execution roles |

**Dependencies** (requires clarification):
- ❓ CloudFront Distribution ID (for cache invalidation)
- ❓ OpenSearch Domain (for search indexing) - OR use DynamoDB GSI instead?
- ❓ Existing API Gateway? (or create new)

---

## 3. Implementation Phases

### Phase 1: Foundation (Days 1-2)

**Deliverables**:
1. Create repository structure
2. Initialize Git repository
3. Create CLAUDE.md with project-specific instructions
4. Create .gitignore and .env.example
5. Setup Python environment (Python 3.12)
6. Create requirements.txt with dependencies:
   - boto3 (AWS SDK)
   - pydantic (data validation)
   - pytest (testing)
   - moto (AWS mocking for tests)
   - requests (HTTP client)

**Terraform Backend Setup**:
- Verify state buckets exist:
  - `bbws-terraform-state-dev` (eu-west-1)
  - `bbws-terraform-state-sit` (eu-west-1)
  - `bbws-terraform-state-prod` (af-south-1)
- Configure backend.tf for remote state

**Acceptance Criteria**:
- ✅ Repository structure matches LLD
- ✅ Python 3.12 environment configured
- ✅ Dependencies installed and tested
- ✅ Git initialized and first commit made

---

### Phase 2: Data Models and Validation (Day 2)

**Deliverables**:
1. **Pydantic Models** (src/models/):
   - `Product` (camelCase field names with aliases)
   - `ProductListResponse`
   - `CreateProductRequest`
   - `UpdateProductRequest`
   - `ProductChangeEvent` (SQS message schema)

2. **Validators** (src/validators/):
   - Field validation (price > 0, name length, etc.)
   - Request body validation
   - Product ID format validation

3. **Exceptions** (src/exceptions/):
   - `ProductNotFoundException`
   - `ValidationException`
   - `DuplicateProductException`

**Tests**:
- Unit tests for all Pydantic models
- Validation tests (happy path + error cases)

**Acceptance Criteria**:
- ✅ All models match LLD data structures
- ✅ Validation rules implemented as per LLD Section 6.3
- ✅ Test coverage: 80%+

---

### Phase 3: DynamoDB Repository Layer (Day 3)

**Deliverables**:
1. **ProductRepository** (src/repositories/product_repository.py):
   ```python
   class ProductRepository:
       def find_all(self, pagination: dict) -> List[Product]
       def find_by_id(self, product_id: str) -> Optional[Product]
       def create(self, product: Product) -> Product
       def update(self, product_id: str, update_data: dict) -> Product
       def soft_delete(self, product_id: str) -> bool
   ```

2. **DynamoDB Table** (terraform/dynamodb.tf):
   - Table name: `bbws-products-{env}`
   - Capacity mode: ON_DEMAND
   - Primary key: PK (partition), SK (sort)
   - GSI1: ProductsByPriceIndex
   - PITR enabled
   - Encryption at rest (AWS managed keys)

**Tests**:
- Unit tests with moto (DynamoDB mocking)
- Integration tests with local DynamoDB

**Acceptance Criteria**:
- ✅ Repository implements all CRUD operations
- ✅ DynamoDB table schema matches LLD Section 5.1
- ✅ Tests cover all access patterns (AP1-AP4)

---

### Phase 4: API Handler Functions (Days 4-5)

**Deliverables**:
1. **5 API Handlers**:
   - `list_products.py` - GET /v1.0/products
   - `get_product.py` - GET /v1.0/products/{productId}
   - `create_product.py` - POST /v1.0/products (sync validation, async via SQS)
   - `update_product.py` - PUT /v1.0/products/{productId} (sync validation, async via SQS)
   - `delete_product.py` - DELETE /v1.0/products/{productId} (soft delete via SQS)

2. **ProductService** (src/services/product_service.py):
   - Business logic layer
   - Orchestrates repository calls
   - Handles validation and error handling

3. **SQSService** (src/services/sqs_service.py):
   - Publish ProductChangeEvent to SQS
   - Message formatting and serialization

4. **Response Builder** (src/utils/response_builder.py):
   - API Gateway response formatting
   - CORS headers
   - Error response standardization

**Tests**:
- Unit tests for each handler
- Integration tests for API flows
- Mock AWS services (DynamoDB, SQS)

**Acceptance Criteria**:
- ✅ All 5 API handlers working
- ✅ Responses match OpenAPI specification
- ✅ Error handling follows LLD patterns
- ✅ Read operations synchronous (< 200ms)
- ✅ Write operations publish to SQS and return 202 Accepted

---

### Phase 5: Event-Driven Lambda Functions (Days 6-7)

**Deliverables**:

**5.1 ProductCreatorRecord Handler**:
- Consumes ProductChangeQueue
- Processes CREATE/UPDATE/DELETE events
- Writes to DynamoDB
- Handles batch processing (10 messages)
- Idempotent operations

**5.2 ProductCacheInvalidator Handler** (if CloudFront available):
- Consumes ProductChangeQueue
- Invalidates CloudFront paths:
  - `/v1.0/products*`
  - `/v1.0/products/{productId}`
- Handles invalidation failures

**5.3 ProductSearchIndexer Handler** (if OpenSearch available):
- Consumes ProductChangeQueue
- Updates OpenSearch index
- Handles CREATE/UPDATE/DELETE operations
- Index mapping for product search

**5.4 ProductAuditLogger Handler**:
- Consumes ProductChangeQueue
- Writes audit logs to S3
- Partition pattern: `{year}/{month}/{day}/{productId}_{timestamp}.json`
- Includes: timestamp, user, changeType, before/after data

**Tests**:
- Unit tests for each event handler
- SQS message processing tests
- Error handling and retry logic tests

**Acceptance Criteria**:
- ✅ All 4 event-driven functions working
- ✅ SQS batch processing implemented
- ✅ DLQ handling configured
- ✅ Idempotent operations (safe retries)

---

### Phase 6: SQS and Message Processing (Day 7)

**Deliverables**:
1. **SQS Queue** (terraform/sqs.tf):
   - Main queue: `bbws-product-change-{env}`
   - Dead Letter Queue: `bbws-product-change-dlq-{env}`
   - Visibility timeout: 60 seconds
   - Max receive count: 3
   - Message retention: 4 days

2. **Lambda Event Source Mappings**:
   - 4 Lambdas subscribed to same queue
   - Batch size: 10 (ProductCreator, CacheInvalidator, AuditLogger)
   - Batch size: 5 (SearchIndexer)
   - Batch window: 5 seconds

3. **CloudWatch Alarms**:
   - DLQ depth > 0 (alert on failed messages)
   - Queue age > 5 minutes (backlog alert)

**Tests**:
- End-to-end message flow tests
- DLQ handling tests
- Concurrent processing tests

**Acceptance Criteria**:
- ✅ SQS queue created with correct configuration
- ✅ All 4 Lambdas triggered by same queue
- ✅ DLQ receives failed messages after 3 retries
- ✅ CloudWatch alarms configured

---

### Phase 7: API Gateway Integration (Day 8)

**Deliverables**:
1. **API Gateway REST API** (terraform/api_gateway.tf):
   - API name: `bbws-product-api-{env}`
   - Stage: `v1` or `{env}`
   - CORS configuration
   - Request validation
   - Rate limiting: 100 req/s (public), 50 req/s (admin)

2. **Endpoints**:
   ```
   GET    /v1.0/products              -> list_products Lambda
   GET    /v1.0/products/{productId}  -> get_product Lambda
   POST   /v1.0/products              -> create_product Lambda
   PUT    /v1.0/products/{productId}  -> update_product Lambda
   DELETE /v1.0/products/{productId}  -> delete_product Lambda
   ```

3. **Lambda Permissions**:
   - Allow API Gateway to invoke Lambdas
   - Execution role with DynamoDB/SQS/CloudWatch permissions

**Tests**:
- API Gateway integration tests
- CORS tests
- Rate limiting tests

**Acceptance Criteria**:
- ✅ All 5 endpoints configured
- ✅ Request/response validation active
- ✅ CORS headers present
- ✅ API accessible via HTTPS

---

### Phase 8: OpenAPI Specification (Day 8)

**Deliverables**:
1. **OpenAPI 3.0 Spec** (openapi/product-api.yaml):
   - All 5 endpoints documented
   - Request/response schemas
   - Error responses (400, 404, 500, 503)
   - Example requests/responses
   - Security schemes (for future auth)

**Acceptance Criteria**:
- ✅ OpenAPI spec matches implemented API
- ✅ Validates with Swagger Editor
- ✅ Can generate API documentation

---

### Phase 9: Monitoring and Logging (Day 9)

**Deliverables**:
1. **CloudWatch Log Groups** (9 total):
   - One per Lambda function
   - Retention: 90 days (DEV), 180 days (SIT), 365 days (PROD)
   - Log level: INFO (DEV), WARN (PROD)

2. **CloudWatch Metrics**:
   - Lambda invocations, errors, duration
   - API Gateway 4xx, 5xx errors
   - SQS queue depth, age
   - DynamoDB read/write capacity

3. **CloudWatch Alarms** (per LLD Section 8):
   - Lambda error rate > 5%
   - API latency p95 > 300ms
   - DLQ messages > 0
   - DynamoDB throttling events

4. **SNS Topic**:
   - `bbws-product-alerts-{env}`
   - Email subscription for alerts

**Acceptance Criteria**:
- ✅ All logs centralized in CloudWatch
- ✅ Alarms trigger correctly
- ✅ SNS notifications working

---

### Phase 10: CI/CD Pipelines (Days 10-11)

**Deliverables**:

**10.1 DEV Deployment Workflow** (.github/workflows/deploy-dev.yml):
- **Trigger**: Push to `main` branch (auto-deploy)
- **Jobs**:
  1. Run tests (pytest)
  2. Terraform plan
  3. Terraform apply (auto-approve)
  4. Post-deployment validation
  5. Smoke tests

**10.2 SIT Deployment Workflow** (.github/workflows/deploy-sit.yml):
- **Trigger**: Manual workflow dispatch
- **Jobs**:
  1. Run tests
  2. Terraform plan
  3. **Manual approval gate**
  4. Terraform apply
  5. Integration tests
  6. Deployment summary

**10.3 PROD Deployment Workflow** (.github/workflows/deploy-prod.yml):
- **Trigger**: Manual workflow dispatch with confirmation text "DEPLOY-TO-PROD"
- **Jobs**:
  1. Validation (confirmation text check)
  2. Run tests
  3. Terraform plan
  4. **Manual approval gate (prod-approval environment)**
  5. Terraform apply
  6. Post-deployment validation
  7. Deployment summary

**Lambda Deployment**:
- Package Python code as ZIP
- Upload to S3 (version per deployment)
- Update Lambda function code via Terraform

**Acceptance Criteria**:
- ✅ DEV auto-deploys on push to main
- ✅ SIT requires manual approval
- ✅ PROD requires confirmation text + manual approval
- ✅ All workflows use OIDC authentication

---

### Phase 11: Testing (Days 11-12)

**Deliverables**:

**11.1 Unit Tests**:
- Test all handlers (9 functions)
- Test all services (5 services)
- Test repository (5 methods)
- Test models and validators
- **Coverage target**: 80%+

**11.2 Integration Tests**:
- Test complete CRUD flows
- Test event-driven processing
- Test error handling
- Test SQS message processing

**11.3 End-to-End Tests**:
- Create product → verify in DynamoDB
- Update product → verify cache invalidation
- Delete product → verify soft delete
- Search product → verify OpenSearch index

**Test Configuration**:
- pytest.ini with coverage settings
- conftest.py with fixtures (mock DynamoDB, SQS, etc.)
- Moto for AWS service mocking
- Local DynamoDB for integration tests

**Acceptance Criteria**:
- ✅ 80%+ code coverage
- ✅ All tests pass in CI/CD
- ✅ Integration tests validate end-to-end flows

---

### Phase 12: Documentation and Seeding (Day 12)

**Deliverables**:

**12.1 README.md**:
- Project overview
- Architecture diagram
- Setup instructions
- Deployment guide
- Testing guide
- API documentation links

**12.2 CLAUDE.md**:
- Project-specific instructions for Claude Code
- Inherits from parent CLAUDE.md files
- TBT workflow integration

**12.3 Product Seeding**:
- Create `scripts/seed_products.py`
- Seed 5 products from LLD:
  1. Entry (R95/domain/year)
  2. Basic (R1500 once-off + R1000/year)
  3. Standard (R2500 once-off + R1500/year)
  4. Premium (R3500 once-off + R2500/year)
  5. Enterprise (R5000 once-off + R3500/year)

**12.4 Deployment Validation**:
- Create `scripts/validate_deployment.py`
- Verify all resources created
- Test API endpoints
- Check Lambda logs

**Acceptance Criteria**:
- ✅ README complete and accurate
- ✅ CLAUDE.md inherits workflow
- ✅ Products seeded in DEV
- ✅ Deployment validation passes

---

## 4. Dependencies and Risks

### 4.1 Clarifications Needed (See questions.md)

| # | Question | Impact |
|---|----------|--------|
| Q2 | OpenSearch cluster required? | High - affects search indexing implementation |
| Q3 | CloudFront distribution ID? | Medium - affects cache invalidation |
| Q4 | S3 audit bucket strategy? | Low - can create new bucket |
| Q5 | DynamoDB table naming/location? | High - affects repository integration |
| Q6 | API Gateway new or existing? | Medium - affects endpoint URLs |
| Q8 | Event-driven phasing? | Medium - affects implementation order |

### 4.2 Technical Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| OpenSearch not available in DEV | High | Medium | Use DynamoDB GSI for search, defer OpenSearch to SIT |
| CloudFront not configured | Medium | Low | Skip cache invalidation for DEV |
| SQS message processing delays | Low | Medium | Configure alarms, monitor DLQ |
| Lambda cold starts > 1s | Medium | Low | Provision concurrency for PROD |
| DynamoDB throttling | Low | Medium | Use on-demand capacity mode |
| API Gateway quota limits | Very Low | Low | Monitor usage, request increase |

---

## 5. Terraform Configuration

### 5.1 Environment-Specific Variables

**dev.tfvars**:
```hcl
environment                = "dev"
aws_account_id            = "536580886816"
aws_region                = "eu-west-1"
project                   = "bbws"

# Lambda Configuration
lambda_runtime            = "python3.12"
lambda_memory             = 256
lambda_timeout            = 30
lambda_architecture       = "arm64"

# DynamoDB Configuration
dynamodb_table_name       = "bbws-products-dev"
dynamodb_capacity_mode    = "ON_DEMAND"
dynamodb_pitr_enabled     = true

# SQS Configuration
sqs_queue_name            = "bbws-product-change-dev"
sqs_visibility_timeout    = 60
sqs_max_receive_count     = 3
sqs_message_retention     = 345600  # 4 days

# S3 Configuration
audit_bucket_name         = "bbws-product-audit-logs-dev"
audit_lifecycle_days      = 90

# API Gateway Configuration
api_name                  = "bbws-product-api-dev"
api_stage                 = "v1"

# Monitoring
log_retention_days        = 90
enable_detailed_monitoring = true

# Feature Flags
enable_opensearch         = false  # TBD based on Q2
enable_cloudfront_cache   = false  # TBD based on Q3
```

**sit.tfvars** and **prod.tfvars**: Similar structure with environment-specific values.

---

## 6. Success Criteria

### 6.1 Functional Requirements

- ✅ All 5 API endpoints operational (GET, GET by ID, POST, PUT, DELETE)
- ✅ Products stored in DynamoDB with correct schema
- ✅ Write operations return 202 Accepted and publish to SQS
- ✅ Read operations return data synchronously
- ✅ ProductCreatorRecord Lambda processes SQS messages and writes to DynamoDB
- ✅ Soft delete sets active=false (not hard delete)
- ✅ API responses match OpenAPI specification

### 6.2 Non-Functional Requirements

- ✅ API latency p95 < 300ms (read operations < 200ms)
- ✅ Event processing latency < 10 seconds end-to-end
- ✅ Test coverage ≥ 80%
- ✅ All CloudWatch alarms configured and tested
- ✅ CI/CD pipelines working for all environments
- ✅ Infrastructure as Code (Terraform) for all resources

### 6.3 Documentation Requirements

- ✅ README with setup/deployment instructions
- ✅ OpenAPI specification published
- ✅ Code comments for complex logic
- ✅ Sequence diagrams match implementation

---

## 7. Timeline and Effort Estimation

| Phase | Duration | Files | Complexity |
|-------|----------|-------|------------|
| Phase 1: Foundation | 0.5 days | 10 | Low |
| Phase 2: Data Models | 0.5 days | 8 | Medium |
| Phase 3: Repository Layer | 1 day | 5 | Medium |
| Phase 4: API Handlers | 2 days | 12 | High |
| Phase 5: Event-Driven Functions | 1.5 days | 8 | High |
| Phase 6: SQS & Messaging | 0.5 days | 3 | Medium |
| Phase 7: API Gateway | 1 day | 5 | Medium |
| Phase 8: OpenAPI Spec | 0.5 days | 1 | Low |
| Phase 9: Monitoring | 1 day | 4 | Medium |
| Phase 10: CI/CD | 1.5 days | 3 | Medium |
| Phase 11: Testing | 2 days | 15 | High |
| Phase 12: Documentation | 1 day | 5 | Low |
| **Total** | **12 days** | **79 files** | **High** |

**Assumptions**:
- 6-hour working days
- Answers to questions.md provided upfront
- No major blockers or dependency issues
- Python development environment ready

**Effort**: ~72 hours (12 days × 6 hours/day)

---

## 8. Post-Implementation Tasks

### 8.1 DEV Environment Testing
- [ ] Seed 5 products via API
- [ ] Test all CRUD operations
- [ ] Verify SQS message processing
- [ ] Check CloudWatch logs and metrics
- [ ] Validate DynamoDB data

### 8.2 SIT Promotion
- [ ] Run full test suite
- [ ] Deploy to SIT via GitHub Actions
- [ ] Execute integration tests
- [ ] Performance testing
- [ ] Security scan

### 8.3 PROD Readiness
- [ ] Load testing (100 req/s)
- [ ] Disaster recovery test
- [ ] Runbook creation
- [ ] Team training
- [ ] Production deployment approval

---

## 9. Open Questions Summary

**Critical** (blocks implementation):
- Q5: DynamoDB table location (new vs existing repo)
- Q6: API Gateway configuration (new vs existing)

**High Priority** (affects scope):
- Q2: OpenSearch implementation strategy
- Q8: Event-driven function phasing

**Medium Priority** (affects features):
- Q3: CloudFront integration
- Q4: Audit logging strategy
- Q7: Authentication approach

**Low Priority** (implementation details):
- Q1: Repository creation method
- Q9: SQS queue configuration
- Q10-Q15: Testing, deployment, monitoring preferences

**Action**: Please review and answer questions in `questions.md` before approval.

---

## 10. Approval

**Proposed Approach**:
1. User reviews this plan and `questions.md`
2. User provides answers to all questions
3. User approves plan with "go" or "approved"
4. Implementation begins with Phase 1

**Estimated Start**: Upon approval
**Estimated Completion**: 12 working days after start

---

**Status**: 🟡 **Awaiting User Approval and Answers to questions.md**

**Next Steps**:
1. Review this implementation plan
2. Answer all questions in `questions.md`
3. Approve plan to proceed with Phase 1

---

**Document Version**: 1.0
**Last Updated**: 2025-12-27
**Author**: Claude Code (Agentic Architect)
