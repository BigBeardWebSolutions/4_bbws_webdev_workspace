# Action Items: DynamoDB Schemas SIT Deployment

**Generated**: 2026-01-07
**Project**: 2_1_bbws_dynamodb_schemas
**Target**: SIT Environment
**Status**: BLOCKED - Actions Required

---

## CRITICAL - MUST FIX BEFORE DEPLOYMENT

### 🔴 Action 1: Resolve Missing Tables
**Priority**: CRITICAL
**Owner**: Tech Lead + Product Owner
**Estimated Time**: 4 hours (meeting + decision + implementation)

**Issue**: Promotion plan expects 5 tables, terraform defines 3 tables

**Options**:
- **Option A**: Add `orders` and `users` table definitions to terraform
  - Review original HLD/LLD for table schema
  - Create schema JSON files
  - Add terraform resources to main.tf
  - Test in DEV environment first

- **Option B**: Update promotion plan to reflect 3-table architecture
  - Document decision to exclude orders/users
  - Update all downstream Lambda dependencies
  - Revise deployment timeline

**Decision Required**: Which option to pursue?

**Tasks**:
- [ ] Schedule architecture review meeting (attendees: Tech Lead, Product Owner, Backend Dev, DBA)
- [ ] Review original requirements and HLD/LLD documents
- [ ] Make decision: Add tables OR revise plan
- [ ] Document decision and rationale
- [ ] Update affected documentation
- [ ] If Option A: Implement table definitions in terraform
- [ ] If Option A: Create schema JSON files for orders and users
- [ ] If Option A: Test in DEV environment
- [ ] If Option B: Update promotion plan
- [ ] If Option B: Notify downstream Lambda teams

---

### 🔴 Action 2: Add Backup Vault Configuration
**Priority**: CRITICAL
**Owner**: DevOps Engineer + DBA
**Estimated Time**: 3 hours

**Issue**: No AWS Backup vault, plan, or selection defined in terraform

**Requirements** (per promotion plan):
- Hourly backups
- 14-day retention for SIT
- Cross-region backup copy (for PROD only)

**Tasks**:
- [ ] Add `aws_backup_vault` resource to main.tf
  ```hcl
  resource "aws_backup_vault" "dynamodb_backup_vault" {
    name = "bbws-dynamodb-backup-vault-${var.environment}"
    kms_key_arn = aws_kms_key.backup_key.arn
  }
  ```
- [ ] Add `aws_backup_plan` resource with hourly schedule
  ```hcl
  resource "aws_backup_plan" "dynamodb_backup_plan" {
    name = "bbws-dynamodb-backup-plan-${var.environment}"

    rule {
      rule_name         = "hourly_backup_14day_retention"
      target_vault_name = aws_backup_vault.dynamodb_backup_vault.name
      schedule          = "cron(0 * * * ? *)"  # Every hour

      lifecycle {
        delete_after = 14  # 14 days for SIT
      }
    }
  }
  ```
- [ ] Add `aws_backup_selection` resource targeting all DynamoDB tables
- [ ] Add IAM role for AWS Backup service
- [ ] Update outputs.tf to export backup vault name and ARN
- [ ] Test in DEV environment first
- [ ] Document backup procedures in runbook

---

### 🔴 Action 3: Reconcile GSI Naming
**Priority**: CRITICAL
**Owner**: Backend Developer + DevOps Engineer
**Estimated Time**: 2 hours

**Issue**: GSI names inconsistent between promotion plan, terraform, and validation script

**Current State**:
| Table | Promotion Plan GSIs | Terraform GSIs | Status |
|-------|-------------------|----------------|--------|
| campaigns | CampaignsByStatus, CampaignsByDate | CampaignActiveIndex, CampaignProductIndex, ActiveIndex | MISMATCH |
| products | ProductsByCategory, ProductsByPriceRange, ProductsByAvailability | ActiveProductsIndex | MISMATCH |
| tenants | TenantsByOrganization | EmailIndex, TenantStatusIndex, ActiveIndex | MISMATCH |

**Tasks**:
- [ ] Review application code (Lambda functions) to identify which GSI names are actually used
- [ ] Decide on correct GSI naming convention
- [ ] Update terraform main.tf with correct GSI names
- [ ] Update schema JSON files to match
- [ ] Update promotion plan documentation
- [ ] Update validation script expected GSI list
- [ ] Test queries in DEV environment
- [ ] Document GSI usage patterns

---

### 🔴 Action 4: Create SIT Validation Script
**Priority**: CRITICAL
**Owner**: DevOps Engineer
**Estimated Time**: 1 hour

**Issue**: Only `validate_dynamodb_dev.py` exists, need SIT version

**Tasks**:
- [ ] Copy `validate_dynamodb_dev.py` to `validate_dynamodb_sit.py`
- [ ] Update account ID to: 815856636111
- [ ] Update region to: eu-west-1
- [ ] Update environment to: sit
- [ ] Update expected table names (include environment suffix if applicable)
- [ ] Update expected GSI list to match terraform configuration
- [ ] Test script locally (when AWS credentials available)
- [ ] Add script to GitHub Actions workflow (post-deployment step)
- [ ] Document script usage in README.md

---

### 🔴 Action 5: Standardize Table Naming
**Priority**: HIGH
**Owner**: DevOps Engineer
**Estimated Time**: 1 hour

**Issue**: Inconsistent table naming (some have environment suffix, some don't)

**Current State**:
- `tenants` (no suffix)
- `campaigns` (no suffix)
- `products-sit` (has suffix)

**Decision Required**: Which pattern to use?
- **Option A**: Add suffix to all tables (`{table}-{env}`)
- **Option B**: Remove suffix from all tables (`{table}`)

**Recommendation**: Option A (add suffix) for better multi-environment clarity

**Tasks**:
- [ ] Decide on naming convention
- [ ] Update terraform main.tf table names
- [ ] Update outputs.tf
- [ ] Update validation script
- [ ] Update schema JSON files (if they reference table names)
- [ ] Update promotion plan documentation
- [ ] Update Lambda environment variables (in dependent projects)
- [ ] Test in DEV environment first

---

## HIGH PRIORITY - SHOULD FIX

### 🟡 Action 6: Create Release Tag
**Priority**: HIGH
**Owner**: DevOps Engineer
**Estimated Time**: 15 minutes

**Tasks**:
- [ ] Create git tag: `git tag -a v1.0.0-sit -m "SIT release for DynamoDB schemas"`
- [ ] Push tag: `git push origin v1.0.0-sit`
- [ ] Create CHANGELOG.md entry for v1.0.0-sit
- [ ] Document changes in release notes

---

### 🟡 Action 7: Test Terraform Plan Locally
**Priority**: HIGH
**Owner**: DevOps Engineer
**Estimated Time**: 30 minutes
**Prerequisites**: AWS SSO access to SIT account

**Tasks**:
- [ ] Configure AWS SSO profile: Tebogo-sit
- [ ] Verify access: `aws sts get-caller-identity --profile Tebogo-sit`
- [ ] Navigate to: `cd terraform/dynamodb`
- [ ] Initialize terraform with SIT backend:
  ```bash
  terraform init \
    -backend-config="bucket=bbws-terraform-state-sit" \
    -backend-config="key=2_1_bbws_dynamodb_schemas/terraform.tfstate" \
    -backend-config="region=eu-west-1" \
    -backend-config="dynamodb_table=terraform-state-lock-sit" \
    -backend-config="encrypt=true"
  ```
- [ ] Select/create workspace: `terraform workspace select sit || terraform workspace new sit`
- [ ] Run plan: `terraform plan -var-file=environments/sit.tfvars`
- [ ] Review plan output for any errors or unexpected changes
- [ ] Save plan: `terraform plan -var-file=environments/sit.tfvars -out=sit.tfplan`
- [ ] Document plan summary (resources to add/change/destroy)

---

### 🟡 Action 8: Update Documentation
**Priority**: MEDIUM
**Owner**: DevOps Engineer
**Estimated Time**: 1 hour

**Tasks**:
- [ ] Update README.md with correct table count (3 or 5)
- [ ] Update README.md with correct GSI count (7 or 8)
- [ ] Update promotion plan with actual terraform resources
- [ ] Add backup vault information to promotion plan
- [ ] Update deployment timeline (if delays due to blockers)
- [ ] Document architecture decisions made during Action 1
- [ ] Update HLD/LLD documents if table schema changes

---

### 🟡 Action 9: Verify AWS Resources Exist
**Priority**: MEDIUM
**Owner**: DevOps Engineer
**Estimated Time**: 30 minutes
**Prerequisites**: AWS SSO access to SIT account

**Tasks**:
- [ ] Verify S3 bucket exists: `bbws-terraform-state-sit`
- [ ] Verify DynamoDB lock table exists: `terraform-state-lock-sit`
- [ ] Verify KMS key available for DynamoDB encryption
- [ ] Verify IAM permissions for GitHub Actions OIDC role
- [ ] Verify AWS Backup service-linked role exists
- [ ] Document any missing resources
- [ ] Create missing resources if needed

---

## MEDIUM PRIORITY - RECOMMENDED

### 🟢 Action 10: Review Streams Configuration
**Priority**: MEDIUM
**Owner**: Backend Developer + Architect
**Estimated Time**: 1 hour

**Issue**: Inconsistent streams configuration
- Products: streams disabled
- Campaigns: streams enabled
- Tenants: streams enabled

**Tasks**:
- [ ] Review business requirements for each table
- [ ] Determine if streams are needed for products table
- [ ] Document rationale for streams enabled/disabled per table
- [ ] Update terraform if streams configuration needs to change
- [ ] Update schema JSON files
- [ ] Update promotion plan documentation

---

### 🟢 Action 11: Cost Analysis
**Priority**: MEDIUM
**Owner**: FinOps Lead + DevOps Engineer
**Estimated Time**: 1 hour

**Tasks**:
- [ ] Calculate expected DynamoDB usage in SIT (read/write units per month)
- [ ] Estimate storage costs (GB per table)
- [ ] Calculate PITR costs
- [ ] Calculate backup costs (14-day retention)
- [ ] Calculate streams costs (if enabled)
- [ ] Set up cost alerts in CloudWatch
- [ ] Set up budget alerts in AWS Budgets
- [ ] Document cost projections in promotion plan

---

### 🟢 Action 12: Security Review
**Priority**: MEDIUM
**Owner**: Security Team + DBA
**Estimated Time**: 2 hours

**Tasks**:
- [ ] Review IAM policies for DynamoDB access
- [ ] Verify encryption at rest (KMS) configuration
- [ ] Verify encryption in transit (TLS) enforced
- [ ] Review VPC endpoint usage (if applicable)
- [ ] Verify CloudTrail logging enabled for DynamoDB API calls
- [ ] Review backup encryption configuration
- [ ] Test least-privilege access for Lambda service roles
- [ ] Document security findings and recommendations

---

## WORKFLOW SUMMARY

```
┌─────────────────────────────────────────────────────────────┐
│ PHASE 1: ARCHITECTURE DECISIONS (Day 1)                     │
├─────────────────────────────────────────────────────────────┤
│ ✓ Action 1: Resolve missing tables (orders, users)         │
│ ✓ Action 3: Reconcile GSI naming                           │
│ ✓ Action 5: Standardize table naming                       │
│ ✓ Action 10: Review streams configuration                   │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ PHASE 2: TERRAFORM IMPLEMENTATION (Day 2)                   │
├─────────────────────────────────────────────────────────────┤
│ ✓ Action 2: Add backup vault configuration                 │
│ ✓ Action 4: Create SIT validation script                   │
│ ✓ Action 6: Create release tag                             │
│ ✓ Action 8: Update documentation                           │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ PHASE 3: TESTING & VALIDATION (Day 3)                       │
├─────────────────────────────────────────────────────────────┤
│ ✓ Test changes in DEV environment                          │
│ ✓ Action 7: Test terraform plan locally (SIT)              │
│ ✓ Action 9: Verify AWS resources exist                     │
│ ✓ Run validation script in DEV                             │
│ ✓ Action 11: Cost analysis                                 │
│ ✓ Action 12: Security review                               │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ PHASE 4: DEPLOYMENT READINESS (Day 3-4)                     │
├─────────────────────────────────────────────────────────────┤
│ ✓ Re-run readiness assessment                              │
│ ✓ Obtain deployment approvals                              │
│ ✓ Schedule deployment window                               │
│ ✓ Brief incident response team                             │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ PHASE 5: SIT DEPLOYMENT (Day 4)                             │
├─────────────────────────────────────────────────────────────┤
│ ✓ Trigger GitHub Actions workflow                          │
│ ✓ Review terraform plan                                    │
│ ✓ Approve deployment at gate                               │
│ ✓ Monitor deployment execution                             │
│ ✓ Run post-deployment validation                           │
│ ✓ Document deployment results                              │
└─────────────────────────────────────────────────────────────┘
```

---

## CHECKLIST TRACKER

### Pre-Deployment Checklist

**Architecture & Planning**:
- [ ] Missing tables resolved (Action 1)
- [ ] GSI naming reconciled (Action 3)
- [ ] Table naming standardized (Action 5)
- [ ] Streams configuration reviewed (Action 10)
- [ ] Architecture decisions documented

**Terraform Implementation**:
- [ ] Backup vault added (Action 2)
- [ ] All tables defined in main.tf
- [ ] All GSIs defined correctly
- [ ] Variables configured for SIT
- [ ] Outputs defined
- [ ] Tags configured

**Validation & Testing**:
- [ ] SIT validation script created (Action 4)
- [ ] Terraform plan tested locally (Action 7)
- [ ] Changes tested in DEV first
- [ ] AWS resources verified (Action 9)
- [ ] Cost analysis completed (Action 11)
- [ ] Security review completed (Action 12)

**Documentation**:
- [ ] Release tag created (Action 6)
- [ ] Documentation updated (Action 8)
- [ ] CHANGELOG.md updated
- [ ] Promotion plan updated
- [ ] README.md updated

**Approvals**:
- [ ] Tech Lead approval
- [ ] Product Owner approval
- [ ] DBA approval
- [ ] DevOps Lead approval
- [ ] Security team approval (if required)

**Infrastructure Readiness**:
- [ ] S3 backend bucket exists
- [ ] DynamoDB lock table exists
- [ ] KMS keys available
- [ ] IAM roles configured
- [ ] AWS Backup service role exists
- [ ] GitHub Actions secrets configured

---

## TIMELINE

| Day | Phase | Actions | Deliverables |
|-----|-------|---------|--------------|
| Day 1 | Architecture | 1, 3, 5, 10 | Architecture decision document |
| Day 2 | Implementation | 2, 4, 6, 8 | Updated terraform, validation script, docs |
| Day 3 | Testing | 7, 9, 11, 12 | Test results, cost analysis, security report |
| Day 4 | Deployment | - | Deployed infrastructure in SIT |

**Total Estimated Time**: 3-4 days

---

## RISK MITIGATION

| Risk | Mitigation Action |
|------|-------------------|
| Wrong AWS account | Action 7 (verify account ID before plan) |
| State file conflicts | Test terraform init in isolation first |
| Missing dependencies | Action 9 (verify all AWS resources) |
| Cost overruns | Action 11 (cost analysis and alerts) |
| Security vulnerabilities | Action 12 (security review) |
| Lambda failures | Test in DEV, document table schema |

---

## SUCCESS CRITERIA

Deployment is ready when:
- ✅ All CRITICAL actions (1-5) completed
- ✅ All HIGH priority actions (6-9) completed
- ✅ Terraform plan executes successfully with no errors
- ✅ All approvals obtained
- ✅ Pre-deployment checklist 100% complete
- ✅ Readiness assessment shows "READY" status

---

## CONTACTS

| Action Owner | Contact | Responsibility |
|--------------|---------|----------------|
| Tech Lead | TBD | Architecture decisions, final approval |
| Product Owner | TBD | Requirements, business logic |
| Backend Developer | TBD | GSI naming, Lambda dependencies |
| DBA | TBD | Backup strategy, PITR, performance |
| DevOps Engineer | TBD | Terraform, deployment, automation |
| Security Team | TBD | Security review, compliance |
| FinOps Lead | TBD | Cost analysis, budget monitoring |

---

## REFERENCES

- **Full Readiness Report**: `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/deployments/sit_dynamodb_schemas_readiness_report.md`
- **Quick Summary**: `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/deployments/sit_dynamodb_schemas_summary.md`
- **Promotion Plan**: `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/promotions/04_dynamodb_schemas_promotion.md`
- **Project Location**: `/Users/tebogotseka/Documents/agentic_work/2_1_bbws_dynamodb_schemas`

---

**Document Status**: ACTIVE - Track progress in this document
**Last Updated**: 2026-01-07
**Next Review**: After Phase 1 completion

