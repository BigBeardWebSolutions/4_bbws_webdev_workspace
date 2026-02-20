# Project Plan 3: Order Lambda Service Implementation

**Status**: IN_PROGRESS
**Created**: 2025-12-30
**Project Manager**: Agentic Project Manager
**LLD Reference**: [2.1.8_LLD_Order_Lambda.md](../2.1.8_LLD_Order_Lambda.md) v1.3

---

## Project Overview

### Mission
Implement a complete event-driven Order Lambda service for the BBWS Customer Portal Public application, including 8 Lambda functions, SQS-based async processing, DynamoDB storage, S3 assets, and full CI/CD automation across 3 environments.

### Repository
- **Name**: `2_bbws_order_lambda`
- **Location**: GitHub (new repository)
- **Template**: Based on `2_bbws_product_lambda` structure

### Key Deliverables
1. **8 Lambda Functions** (4 API + 4 event-driven)
2. **DynamoDB Table** with 2 GSIs for efficient querying
3. **SQS Queues** (OrderCreationQueue + DLQ)
4. **S3 Buckets** (email templates + order PDFs)
5. **Complete Terraform Infrastructure**
6. **GitHub Actions CI/CD Pipelines**
7. **Email Templates** (4 HTML templates)
8. **Operational Runbooks** (4 runbooks)

---

## Environments

| Environment | AWS Account | Region | Deployment | Approval Required |
|-------------|-------------|--------|------------|-------------------|
| **DEV** | 536580886816 | af-south-1 | Automatic (on push to main) | No |
| **SIT** | 815856636111 | af-south-1 | Manual promotion | Yes (Tech Lead) |
| **PROD** | 093646564004 | af-south-1 | Manual promotion | Yes (BO + Tech Lead) |

**DR Region**: eu-west-1 (PROD cross-region replication)

---

## Project Stages

### Stage 1: Repository and Requirements Analysis
**Status**: PENDING
**Workers**: 4 (parallel execution)
**Estimated Duration**: 1-2 days
**Approval Gate**: Yes

**Objective**: Set up GitHub repository with proper authentication and analyze LLD requirements.

**Workers**:
1. ✓ Create GitHub repository with OIDC setup
2. ✓ Extract implementation requirements from LLD
3. ✓ Validate naming conventions and AWS mappings
4. ✓ Analyze environment configurations

**Deliverables**:
- GitHub repository: `2_bbws_order_lambda`
- OIDC roles for all environments
- Requirements specification document
- Environment configuration matrix

---

### Stage 2: Lambda Function Implementation
**Status**: PENDING
**Workers**: 8 (parallel execution)
**Estimated Duration**: 3-5 days
**Approval Gate**: Yes

**Objective**: Implement all 8 Lambda functions with TDD approach, achieving 80%+ test coverage.

**API Handler Workers**:
1. ✓ `create_order` - Validate request and publish to SQS
2. ✓ `get_order` - Retrieve order from DynamoDB
3. ✓ `list_orders` - Query orders with pagination
4. ✓ `update_order` - Update order status

**Event-Driven Workers**:
5. ✓ `OrderCreatorRecord` - Persist order to DynamoDB
6. ✓ `OrderPDFCreator` - Generate invoice PDF
7. ✓ `OrderInternalNotificationSender` - Send admin notification
8. ✓ `CustomerOrderConfirmationSender` - Send customer email

**Deliverables**:
- 8 Lambda function handlers
- Pydantic models (Order, OrderItem, Campaign, etc.)
- DAO with DynamoDB access patterns
- Unit tests (80%+ coverage)
- Integration tests for SQS triggers

---

### Stage 3: Infrastructure as Code
**Status**: PENDING
**Workers**: 6 (parallel execution)
**Estimated Duration**: 2-3 days
**Approval Gate**: Yes

**Objective**: Create complete Terraform infrastructure for all AWS resources.

**Workers**:
1. ✓ Terraform: DynamoDB table with GSIs
2. ✓ Terraform: SQS queues (main + DLQ)
3. ✓ Terraform: S3 buckets (templates + PDFs)
4. ✓ Terraform: Lambda functions + event source mappings
5. ✓ Terraform: API Gateway + integrations
6. ✓ Terraform: CloudWatch alarms + SNS topics

**Deliverables**:
- Terraform modules for all resources
- Environment-specific .tfvars files
- IAM roles with least-privilege policies
- S3 backend configuration per environment

---

### Stage 4: CI/CD Pipeline Implementation
**Status**: PENDING
**Workers**: 5 (parallel execution)
**Estimated Duration**: 2-3 days
**Approval Gate**: Yes

**Objective**: Create GitHub Actions workflows for automated testing, packaging, deployment, and promotion.

**Workers**:
1. ✓ Validation workflow (lint, type check, security scan)
2. ✓ Test workflow (pytest with coverage)
3. ✓ Package workflow (Docker-based with verification)
4. ✓ Deploy-DEV workflow (auto on push)
5. ✓ Promotion workflows (DEV→SIT, SIT→PROD)

**Deliverables**:
- `.github/workflows/validate.yml`
- `.github/workflows/test.yml`
- `.github/workflows/deploy-dev.yml`
- `.github/workflows/promote-sit.yml`
- `.github/workflows/promote-prod.yml`

---

### Stage 5: Templates and Assets
**Status**: PENDING
**Workers**: 4 (parallel execution)
**Estimated Duration**: 1-2 days
**Approval Gate**: Yes

**Objective**: Create HTML email templates and PDF invoice template.

**Workers**:
1. ✓ Customer order confirmation template
2. ✓ Internal order notification template
3. ✓ Order status update template
4. ✓ Invoice PDF template

**Deliverables**:
- 4 HTML email templates
- Template upload scripts for S3
- Template versioning strategy

---

### Stage 6: Documentation and Runbooks
**Status**: PENDING
**Workers**: 4 (parallel execution)
**Estimated Duration**: 1-2 days
**Approval Gate**: Yes

**Objective**: Create comprehensive operational documentation.

**Workers**:
1. ✓ Deployment runbook
2. ✓ Troubleshooting runbook
3. ✓ Rollback runbook
4. ✓ Operational monitoring runbook

**Deliverables**:
- Deployment procedures (DEV → SIT → PROD)
- Troubleshooting guide
- Rollback procedures
- CloudWatch dashboard configuration

---

## Progress Tracking

### Overall Project Status

| Metric | Count | Status |
|--------|-------|--------|
| **Total Stages** | 6 | 0 Complete, 0 In Progress, 6 Pending |
| **Total Workers** | 31 | 0 Complete, 0 In Progress, 31 Pending |
| **Test Coverage** | Target: 80%+ | Not started |
| **Deployments** | DEV/SIT/PROD | Not started |

### Stage Completion

| Stage | Status | Workers Complete | Summary |
|-------|--------|------------------|---------|
| Stage 1 | PENDING | 0/4 | Not started |
| Stage 2 | PENDING | 0/8 | Not started |
| Stage 3 | PENDING | 0/6 | Not started |
| Stage 4 | PENDING | 0/5 | Not started |
| Stage 5 | PENDING | 0/4 | Not started |
| Stage 6 | PENDING | 0/4 | Not started |

---

## Critical Success Factors

### Must-Haves (Blockers)
- [ ] GitHub repository created with OIDC
- [ ] All 8 Lambda functions with 80%+ test coverage
- [ ] DynamoDB table with correct GSI configuration
- [ ] SQS event source mappings working
- [ ] Email templates uploaded to S3
- [ ] CI/CD pipelines tested in DEV
- [ ] All tests passing before PROD deployment

### Quality Gates
- **Test Coverage**: Minimum 80%
- **Security Scan**: No high/critical vulnerabilities
- **Terraform Validation**: Plan must succeed
- **Lambda Packaging**: Docker-based with import verification
- **Documentation**: All runbooks complete

---

## Lessons Learned Applied

Based on Product Lambda implementation (from DevOps Engineer Agent v1.2 and Python AWS Developer Agent v1.1):

### Critical Decisions
1. **Pydantic v1.10.18**: Use pure Python version (no Rust binaries) to avoid Lambda compatibility issues
2. **Docker Packaging**: All Lambda packages built with `public.ecr.aws/lambda/python:3.12`
3. **Package Verification**: Import test in Lambda Docker environment before deployment
4. **Terraform State**: S3 backend with DynamoDB locking, separate state per environment
5. **IAM Permissions**: Evidence-based iteration (start minimal, add based on errors)
6. **Test Quality**: Prioritize coverage (80%+) over 100% pass rate

### Implementation Patterns
- Repository pattern for DynamoDB access
- AWS Powertools for observability (@logger, @tracer, @metrics)
- boto3 clients initialized at global scope (not inside handler)
- Single-table DynamoDB design with GSIs
- SQS dead-letter queues with CloudWatch alarms
- Exponential backoff for retries

---

## Risk Management

| Risk | Impact | Mitigation |
|------|--------|------------|
| **SQS processing failures** | High | DLQ + alarms + retry logic |
| **Binary dependency issues** | High | Pydantic v1.10.18 (pure Python) |
| **Terraform state conflicts** | High | S3 backend + DynamoDB locking |
| **DynamoDB throttling** | Medium | On-demand capacity + reserved concurrency |
| **Email delivery failures** | Medium | SQS retries + SES bounce handling |
| **Lambda cold starts** | Low | Provisioned concurrency for critical functions |

---

## State File Tracking

### Current State
- **Project**: `work.state.PENDING`
- **Stage 1**: `work.state.PENDING`
- **Stage 2**: `work.state.PENDING`
- **Stage 3**: `work.state.PENDING`
- **Stage 4**: `work.state.PENDING`
- **Stage 5**: `work.state.PENDING`
- **Stage 6**: `work.state.PENDING`

### Crash Recovery
If interrupted, resume by:
1. Check `find . -name "work.state.*"`
2. Identify last COMPLETE stage
3. Resume from next PENDING worker
4. Verify outputs exist for completed workers

---

## Next Actions

### Immediate (Stage 1)
1. Execute worker-1: Create GitHub repository
2. Execute worker-2: Extract requirements from LLD
3. Execute worker-3: Validate naming conventions
4. Execute worker-4: Analyze environment configs
5. Create stage-1 summary.md
6. Request user approval for Stage 2

### Upcoming
- Begin Stage 2 upon Stage 1 approval
- Parallel execution of 8 Lambda implementations
- TDD approach with pytest + moto

---

**Project Manager**: Agentic Project Manager
**Created**: 2025-12-30
**Last Updated**: 2025-12-30
