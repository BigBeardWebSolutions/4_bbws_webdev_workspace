# Product Lambda - Documentation Structure

**Date**: 2025-12-29
**Project**: Product Lambda (V4 Single Repo)

---

## Documentation Locations

### 1. Repository Documentation (`2_bbws_product_lambda/`)

**Purpose**: Developer-focused, quick start guides

**Files**:
- `README.md` - Quick start & developer guide
  - Project overview
  - Prerequisites
  - Local setup
  - Running tests
  - API endpoint overview
  - Contributing guidelines

- `CLAUDE.md` - TBT workflow integration
  - Workflow patterns
  - Agent instructions
  - Development guidelines

---

### 2. Centralized Runbooks (`2_bbws_docs/runbooks/`)

**Purpose**: Operations team reference, deployment procedures

**Files Created in Stage 3**:

#### Deployment Runbooks

1. **`product_lambda_deployment.md`**
   - Prerequisites
     - DynamoDB table exists (`products-{env}`)
     - AWS credentials configured
     - Terraform state bucket exists
   - DEV Deployment Steps
     - Auto-deploy via GitHub Actions
     - Manual deployment process
     - Verification steps
   - SIT Deployment Steps
     - Approval workflow
     - Promotion from DEV
     - Smoke tests
   - PROD Deployment Steps
     - Release process
     - Approval gates
     - Rollback procedures
   - Troubleshooting
     - Terraform failures
     - Lambda deployment errors
     - API Gateway issues

2. **`product_lambda_operations.md`**
   - Monitoring
     - CloudWatch dashboards
     - Key metrics (latency, errors, invocations)
     - Log insights queries
   - Common Alerts
     - Lambda errors (response & mitigation)
     - API Gateway 4xx/5xx (troubleshooting)
     - DynamoDB throttling (resolution)
   - Troubleshooting Guide
     - 404 Not Found (product doesn't exist)
     - 400 Bad Request (validation errors)
     - 500 Internal Server Error (Lambda/DynamoDB issues)
     - Timeout errors (Lambda duration)
   - Performance Tuning
     - Lambda memory optimization
     - DynamoDB GSI usage
     - Cold start mitigation
   - Scaling Considerations
     - Lambda concurrency limits
     - DynamoDB on-demand capacity
     - API Gateway throttling

3. **`product_lambda_disaster_recovery.md`**
   - Backup Verification
     - DynamoDB PITR status
     - Terraform state backups
     - Code repository backups
   - Restore Procedures
     - DynamoDB table restore
     - Lambda function rollback
     - API Gateway configuration restore
   - Multi-Region Failover (if applicable)
     - Primary: af-south-1
     - DR: eu-west-1
     - Failover triggers
     - Route 53 health checks
   - RTO/RPO Targets
     - RTO: < 30 minutes
     - RPO: < 1 minute (PITR)

#### Developer Guides

4. **`product_lambda_dev_setup.md`**
   - Local Development Environment
     - Python 3.12 setup
     - Virtual environment creation
     - Dependencies installation
     - AWS CLI configuration
   - Running Tests Locally
     - Unit tests (pytest)
     - Integration tests (moto)
     - Coverage reports
     - Code quality checks (black, mypy, ruff)
   - Debugging Lambda Functions
     - Local invocation
     - SAM CLI usage
     - CloudWatch log streaming
   - Mock DynamoDB Setup
     - moto configuration
     - Test data seeding
     - Local DynamoDB (if needed)

5. **`product_lambda_cicd_guide.md`**
   - GitHub Actions Workflow Overview
     - `deploy-dev.yml` - Auto-deploy
     - `deploy-sit.yml` - Manual approval
     - `deploy-prod.yml` - Strict approval
   - Secrets Configuration
     - AWS_ROLE_ARN (OIDC)
     - AWS_REGION
     - Repository secrets setup
   - OIDC Role Setup
     - Trust policy configuration
     - Permissions policy
     - Role ARN retrieval
   - Terraform State Management
     - S3 backend configuration
     - DynamoDB locking table
     - State file per environment
   - Approval Process
     - SIT: Manual trigger → Approval → Deploy
     - PROD: Release tag → Confirmation → Approval → Deploy
     - Rollback workflow

---

## Documentation Tree

```
2_bbws_docs/
└── runbooks/
    ├── product_lambda_deployment.md       # Deployment procedures
    ├── product_lambda_operations.md       # Monitoring & troubleshooting
    ├── product_lambda_disaster_recovery.md # DR procedures
    ├── product_lambda_dev_setup.md        # Local development
    └── product_lambda_cicd_guide.md       # CI/CD workflows

2_bbws_product_lambda/
├── README.md                              # Quick start guide
└── CLAUDE.md                              # TBT workflow
```

---

## Documentation Standards

### All Runbooks Must Include

1. **Purpose**: What this runbook covers
2. **Prerequisites**: What must be in place before following
3. **Step-by-Step Procedures**: Clear, numbered steps
4. **Verification**: How to confirm success
5. **Troubleshooting**: Common issues and resolutions
6. **Contacts**: Who to escalate to if needed

### Format

- **Markdown**: All docs in `.md` format
- **Code Blocks**: Use syntax highlighting
- **Screenshots**: Include where helpful (in `2_bbws_docs/runbooks/assets/`)
- **Links**: Internal references to related runbooks
- **Version**: Date and author at top of each doc

---

## Maintenance

### When to Update Runbooks

- After infrastructure changes
- When deployment process changes
- After incident resolution (capture lessons learned)
- When new troubleshooting steps discovered
- After DR drills

### Review Cycle

- **Quarterly**: Review all runbooks for accuracy
- **After Major Changes**: Immediate update
- **After Incidents**: Update within 1 week

---

## Rationale for Centralized Runbooks

**Why `2_bbws_docs/runbooks/` instead of in Lambda repo?**

1. **Consistency**: All BBWS services follow same runbook structure
2. **Discoverability**: Ops team knows where to find all runbooks
3. **Cross-Service**: Some runbooks reference multiple services
4. **Separation of Concerns**: Code repo for code, docs repo for operations
5. **Access Control**: Docs repo can have different permissions
6. **Search**: Single location to search for operational procedures

**Benefits**:
- ✅ New ops team members onboard faster
- ✅ Troubleshooting knowledge centralized
- ✅ Easier to maintain consistency across services
- ✅ Reduces duplication across repos

---

## Stage 3 Deliverables Checklist

Worker 3-1 must create:

- [ ] `product_lambda_deployment.md` (deployment procedures)
- [ ] `product_lambda_operations.md` (monitoring & troubleshooting)
- [ ] `product_lambda_disaster_recovery.md` (DR procedures)
- [ ] `product_lambda_dev_setup.md` (local development guide)
- [ ] `product_lambda_cicd_guide.md` (CI/CD workflow guide)

All files in: `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/runbooks/`

---

**Created**: 2025-12-29
**Status**: Planned (to be created in Stage 3)
**Location**: `2_bbws_docs/runbooks/`
