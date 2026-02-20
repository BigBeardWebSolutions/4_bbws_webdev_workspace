# Project Plan 3: Order Lambda Service Implementation

**Status**: READY FOR STAGE 1 EXECUTION
**Created**: 2025-12-30
**Total Stages**: 6
**Total Workers**: 31
**LLD**: [2.1.8_LLD_Order_Lambda.md](../2.1.8_LLD_Order_Lambda.md)

---

## Quick Start

### View Project Plan
```bash
cat project_plan.md
```

### View TBT Approval Plan
```bash
cat ../.claude/plans/plan_3.md
```

### Check Project Status
```bash
find . -name "work.state.*" | sort
```

---

## Project Overview

**Repository**: `2_bbws_order_lambda` (to be created)

**Deliverables**:
- 8 Lambda Functions (4 API + 4 event-driven)
- Event-driven architecture with SQS
- DynamoDB single-table design with 2 GSIs
- S3 buckets for templates and PDFs
- Complete Terraform infrastructure
- GitHub Actions CI/CD pipelines
- Operational runbooks

---

## Project Structure

```
project-plan-3/
├── project_plan.md              ← Master project plan
├── work.state.PENDING            ← Project-level state
├── README.md                     ← This file
│
├── stage-1-repository-requirements/
│   ├── plan.md                   ✓ Created
│   ├── work.state.PENDING
│   ├── worker-1-github-repository-setup/
│   │   ├── instructions.md       ✓ Created
│   │   └── work.state.PENDING
│   ├── worker-2-requirements-extraction/
│   │   ├── instructions.md       ✓ Created
│   │   └── work.state.PENDING
│   ├── worker-3-naming-validation/
│   │   ├── instructions.md       ✓ Created
│   │   └── work.state.PENDING
│   └── worker-4-environment-analysis/
│       ├── instructions.md       ← To be created
│       └── work.state.PENDING
│
├── stage-2-lambda-implementation/
│   ├── work.state.PENDING
│   ├── worker-1-create-order-lambda/
│   ├── worker-2-get-order-lambda/
│   ├── worker-3-list-orders-lambda/
│   ├── worker-4-update-order-lambda/
│   ├── worker-5-order-creator-record-lambda/
│   ├── worker-6-order-pdf-creator-lambda/
│   ├── worker-7-internal-notification-lambda/
│   └── worker-8-customer-confirmation-lambda/
│
├── stage-3-infrastructure-code/
│   ├── work.state.PENDING
│   ├── worker-1-terraform-dynamodb/
│   ├── worker-2-terraform-sqs/
│   ├── worker-3-terraform-s3/
│   ├── worker-4-terraform-lambda/
│   ├── worker-5-terraform-apigateway/
│   └── worker-6-terraform-monitoring/
│
├── stage-4-cicd-pipelines/
│   ├── work.state.PENDING
│   ├── worker-1-validation-workflow/
│   ├── worker-2-test-workflow/
│   ├── worker-3-package-workflow/
│   ├── worker-4-deploy-dev-workflow/
│   └── worker-5-promotion-workflows/
│
├── stage-5-templates-assets/
│   ├── work.state.PENDING
│   ├── worker-1-customer-confirmation-template/
│   ├── worker-2-internal-notification-template/
│   ├── worker-3-status-update-template/
│   └── worker-4-invoice-pdf-template/
│
└── stage-6-documentation-runbooks/
    ├── work.state.PENDING
    ├── worker-1-deployment-runbook/
    ├── worker-2-troubleshooting-runbook/
    ├── worker-3-rollback-runbook/
    └── worker-4-operations-runbook/
```

---

## Environments

| Environment | AWS Account | Region | Deployment Type |
|-------------|-------------|--------|-----------------|
| **DEV** | 536580886816 | af-south-1 | Automatic (on push to main) |
| **SIT** | 815856636111 | af-south-1 | Manual approval |
| **PROD** | 093646564004 | af-south-1 | Manual approval (BO + Tech Lead) |

**DR Region**: eu-west-1 (PROD failover)

---

## Execution Workflow

### Stage 1: Repository & Requirements (READY TO EXECUTE)
- [x] Plan created
- [ ] Execute 4 workers in parallel:
  1. Create GitHub repository with OIDC
  2. Extract requirements from LLD
  3. Validate naming conventions
  4. Analyze environment configurations
- [ ] Create stage-1 summary.md
- [ ] User approval (Gate 1)

### Stage 2: Lambda Implementation
- [ ] Plan to be created
- [ ] Execute 8 workers in parallel (Lambda functions)
- [ ] Create stage-2 summary.md
- [ ] User approval (Gate 2)

### Stage 3: Infrastructure Code
- [ ] Plan to be created
- [ ] Execute 6 workers in parallel (Terraform modules)
- [ ] Create stage-3 summary.md
- [ ] User approval (Gate 3)

### Stage 4: CI/CD Pipelines
- [ ] Plan to be created
- [ ] Execute 5 workers in parallel (GitHub Actions)
- [ ] Create stage-4 summary.md
- [ ] User approval (Gate 4)

### Stage 5: Templates & Assets
- [ ] Plan to be created
- [ ] Execute 4 workers in parallel (HTML templates)
- [ ] Create stage-5 summary.md
- [ ] User approval (Gate 5)

### Stage 6: Documentation & Runbooks
- [ ] Plan to be created
- [ ] Execute 4 workers in parallel (Runbooks)
- [ ] Create stage-6 summary.md
- [ ] User approval (Gate 6)

### Project Completion
- [ ] Create project summary.md
- [ ] Update project work.state to COMPLETE
- [ ] Deliver all artifacts

---

## State Management

### Current State
- **Project**: `work.state.PENDING`
- **Stage 1**: `work.state.PENDING` (ready to begin)
- **Stage 2-6**: `work.state.PENDING` (awaiting Stage 1 completion)

### Crash Recovery

If interrupted:
1. Check state files: `find . -name "work.state.*"`
2. Identify last COMPLETE stage
3. Resume from next PENDING worker
4. Verify outputs exist for completed workers

**State File Reference**:
- `work.state.PENDING` - Not started
- `work.state.IN_PROGRESS` - Currently working
- `work.state.COMPLETE` - Finished successfully

---

## Key Deliverables by Stage

### Stage 1 Deliverables
- GitHub repository created (`2_bbws_order_lambda`)
- OIDC authentication configured (3 environments)
- Complete requirements extracted from LLD
- Naming conventions validated
- Environment configuration matrix

### Stage 2 Deliverables
- 8 Lambda function implementations
- Pydantic models (Order, OrderItem, Campaign, etc.)
- DAO with DynamoDB access patterns
- Unit tests (80%+ coverage)
- Integration tests

### Stage 3 Deliverables
- Terraform modules for all AWS resources
- Environment-specific .tfvars files
- IAM roles with least-privilege policies
- S3 backend configuration

### Stage 4 Deliverables
- GitHub Actions workflows (validate, test, deploy, promote)
- Automated DEV deployment
- Manual SIT/PROD promotion with approvals
- Package verification with Docker

### Stage 5 Deliverables
- 4 HTML email templates
- PDF invoice template
- Template upload scripts
- S3 template versioning

### Stage 6 Deliverables
- Deployment runbook
- Troubleshooting guide
- Rollback procedures
- CloudWatch monitoring guide

---

## Lessons Learned Applied

Based on Product Lambda (DevOps Engineer Agent v1.2 + Python AWS Developer Agent v1.1):

✅ **Pydantic v1.10.18**: Pure Python (no Rust binaries)
✅ **Docker Packaging**: `public.ecr.aws/lambda/python:3.12`
✅ **Package Verification**: Import test before deployment
✅ **Terraform State**: S3 + DynamoDB locking, separate per env
✅ **IAM Permissions**: Evidence-based iteration
✅ **Test Coverage**: 80%+ threshold, allow test failures if coverage met

---

## Commands

### Check Progress
```bash
# Overall status
cat work.state.*

# Stage status
find . -maxdepth 2 -name "work.state.*" | sort

# Worker status by stage
find stage-1-repository-requirements -name "work.state.*"
```

### Count Workers
```bash
echo "PENDING: $(find . -name "work.state.PENDING" | grep worker | wc -l)"
echo "IN_PROGRESS: $(find . -name "work.state.IN_PROGRESS" | grep worker | wc -l)"
echo "COMPLETE: $(find . -name "work.state.COMPLETE" | grep worker | wc -l)"
```

### List Pending Workers
```bash
find . -name "work.state.PENDING" -exec dirname {} \; | grep worker
```

### List Completed Workers
```bash
find . -name "work.state.COMPLETE" -exec dirname {} \; | grep worker
```

---

## Next Steps

1. **User reviews** Stage 1 plan and worker instructions
2. **Execute Stage 1** workers (4 workers in parallel recommended)
3. **Create Stage 1 summary** consolidating worker outputs
4. **Request approval** before proceeding to Stage 2
5. **Iterate** through remaining stages sequentially

---

## Critical Success Factors

- [ ] GitHub repository with OIDC authentication
- [ ] All 8 Lambda functions with 80%+ test coverage
- [ ] DynamoDB table with correct GSI configuration
- [ ] SQS event source mappings working
- [ ] Email templates uploaded to S3
- [ ] CI/CD pipelines tested in DEV
- [ ] All tests passing before PROD deployment

---

## Support

**Project Manager**: Agentic Project Manager
**LLD**: 2.1.8_LLD_Order_Lambda.md v1.3
**Parent HLD**: 2.1_BBWS_Customer_Portal_Public_HLD.md v1.3.5

**Documentation**:
- TBT Approval Plan: `../.claude/plans/plan_3.md`
- Master Project Plan: `project_plan.md`
- LLD Reference: `../2.1.8_LLD_Order_Lambda.md`

---

**Status**: READY FOR EXECUTION
**Created**: 2025-12-30
**Last Updated**: 2025-12-30
