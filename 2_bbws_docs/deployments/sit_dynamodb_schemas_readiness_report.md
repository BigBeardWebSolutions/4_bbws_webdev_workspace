# SIT Deployment Readiness Report: DynamoDB Schemas

**Report Generated**: 2026-01-07
**Project**: 2_1_bbws_dynamodb_schemas
**Target Environment**: SIT (815856636111, eu-west-1)
**Execution Type**: READ-ONLY SIMULATION
**Batch**: Batch 1 Worker-1
**Plan Reference**: /Users/tebogotseka/Documents/agentic_work/2_bbws_docs/promotions/04_dynamodb_schemas_promotion.md

---

## EXECUTIVE SUMMARY

**Readiness Status**: **BLOCKED - CRITICAL ISSUES IDENTIFIED**

The DynamoDB schemas project is **NOT READY** for SIT deployment due to critical discrepancies between:
1. The promotion plan documentation (expects 5 tables, 8 GSIs)
2. The actual terraform configuration (defines 3 tables, 7 GSIs)

---

## CRITICAL FINDINGS

### Issue 1: Table Count Mismatch

**Expected (per promotion plan)**:
- 5 DynamoDB tables: campaigns, orders, products, tenants, users

**Actual (per terraform main.tf)**:
- 3 DynamoDB tables: campaigns, products, tenants

**Missing tables**:
- ❌ `orders` table
- ❌ `users` table

**Impact**: HIGH - Blocking for dependent Lambda services that expect these tables

---

### Issue 2: GSI Count Mismatch

**Expected (per promotion plan)**: 8 GSIs total across all tables

**Actual (per terraform main.tf)**: 7 GSIs total

**Breakdown by table**:

| Table | Expected GSIs (per plan) | Actual GSIs (terraform) | Status |
|-------|--------------------------|-------------------------|--------|
| campaigns | CampaignsByStatus, CampaignsByDate | CampaignActiveIndex, CampaignProductIndex, ActiveIndex | ⚠️ MISMATCH |
| orders | OrdersByCustomer, OrdersByStatus, OrdersByDate | N/A - table not defined | ❌ MISSING |
| products | ProductsByCategory, ProductsByPriceRange, ProductsByAvailability | ActiveProductsIndex | ⚠️ MISMATCH |
| tenants | TenantsByOrganization | EmailIndex, TenantStatusIndex, ActiveIndex | ⚠️ MISMATCH |
| users | UsersByEmail, UsersByOrganization | N/A - table not defined | ❌ MISSING |

**GSI Analysis**:
- **Tenants table**: 3 GSIs defined (EmailIndex, TenantStatusIndex, ActiveIndex)
- **Products table**: 1 GSI defined (ActiveProductsIndex)
- **Campaigns table**: 3 GSIs defined (CampaignActiveIndex, CampaignProductIndex, ActiveIndex)
- **Total**: 7 GSIs (not 8 as documented)

---

## PRE-DEPLOYMENT CHECKLIST STATUS

### Environment Verification
- ❌ AWS SSO login to SIT account (815856636111) - **NOT PERFORMED (read-only)**
- ❌ Verify AWS profile: `Tebogo-sit` - **BLOCKED: Invalid credentials**
- ✅ Confirm SIT region: eu-west-1 - **VERIFIED in sit.tfvars**
- ❌ Verify IAM permissions - **NOT VERIFIED (no AWS access)**
- ❌ Check KMS key availability - **NOT VERIFIED**

### Code Preparation
- ✅ Latest code in `main` branch - **VERIFIED: working tree clean**
- ⚠️ Terraform validations passing - **CANNOT VERIFY: workspace command requires AWS auth**
- ✅ GitHub Actions workflows exist - **VERIFIED: deploy-sit.yml present**
- ❌ Tag release: `v1.0.0-sit` - **NOT CREATED**
- ❌ Create changelog for SIT release - **NOT CREATED**
- ⚠️ Document table schemas - **PARTIAL: Only 3 of 5 tables documented**

### Infrastructure Planning
- ⚠️ Document tables to be created:
  - ✅ `campaigns` (but GSI naming mismatch)
  - ❌ `orders` - **MISSING**
  - ✅ `products` (but GSI naming mismatch)
  - ✅ `tenants` (but GSI naming mismatch)
  - ❌ `users` - **MISSING**
- ✅ On-demand capacity mode - **VERIFIED: PAY_PER_REQUEST in all tables**
- ✅ PITR enabled - **VERIFIED: enabled in all defined tables**
- ✅ Encryption at rest - **ASSUMED: AWS default encryption**
- ⚠️ DynamoDB Streams - **MIXED: enabled for campaigns/tenants, disabled for products**

### Backup Strategy
- ❌ Backup vault configuration - **NOT DEFINED in terraform**
- ❌ AWS Backup service role - **NOT VERIFIED**
- ❌ Backup schedule documentation - **NOT IMPLEMENTED**
- ❌ Backup retention period - **NOT CONFIGURED**

---

## RESOURCES TO BE CREATED

### DynamoDB Tables (3)

#### 1. `tenants` table
- **Billing Mode**: PAY_PER_REQUEST (on-demand)
- **Primary Key**: PK (HASH), SK (RANGE)
- **Attributes**: PK, SK, email, status, active
- **GSIs**:
  1. EmailIndex (hash: email, projection: ALL)
  2. TenantStatusIndex (hash: status, range: SK, projection: ALL)
  3. ActiveIndex (hash: active, range: SK, projection: ALL)
- **PITR**: Enabled
- **Streams**: Enabled (NEW_AND_OLD_IMAGES)
- **Tags**: Name, Owner, CostCenter, Environment, Project, ManagedBy, Component, Application

#### 2. `products-sit` table
- **Billing Mode**: PAY_PER_REQUEST (on-demand)
- **Primary Key**: PK (HASH), SK (RANGE)
- **Attributes**: PK, SK, active, createdAt
- **GSIs**:
  1. ActiveProductsIndex (hash: active, range: createdAt, projection: ALL)
- **PITR**: Enabled
- **Streams**: Disabled
- **Tags**: Name, Owner, CostCenter, Component, Environment, Project, ManagedBy, Component, Application

#### 3. `campaigns` table
- **Billing Mode**: PAY_PER_REQUEST (on-demand)
- **Primary Key**: PK (HASH), SK (RANGE)
- **Attributes**: PK, SK, campaignId, productId, active
- **GSIs**:
  1. CampaignActiveIndex (hash: campaignId, range: active, projection: ALL)
  2. CampaignProductIndex (hash: productId, range: SK, projection: ALL)
  3. ActiveIndex (hash: active, range: SK, projection: ALL)
- **PITR**: Enabled
- **Streams**: Enabled (NEW_AND_OLD_IMAGES)
- **Tags**: Name, Owner, CostCenter, Environment, Project, ManagedBy, Component, Application

### Total Resources
- **Tables**: 3 (expected 5)
- **GSIs**: 7 (expected 8)
- **PITR**: 3 configurations
- **Streams**: 2 streams enabled
- **Backup Vault**: 0 (should be 1)

---

## TERRAFORM CONFIGURATION REVIEW

### Files Present
- ✅ `/terraform/dynamodb/main.tf` (236 lines)
- ✅ `/terraform/dynamodb/variables.tf` (22 lines)
- ✅ `/terraform/dynamodb/outputs.tf` (39 lines)
- ✅ `/terraform/dynamodb/environments/sit.tfvars` (13 lines)

### Backend Configuration
- **Type**: S3
- **Bucket**: `bbws-terraform-state-sit` (per deploy-sit.yml)
- **Key**: `2_1_bbws_dynamodb_schemas/terraform.tfstate`
- **Region**: eu-west-1
- **DynamoDB Lock Table**: `terraform-state-lock-sit`
- **Encryption**: Enabled

### Terraform State
- ✅ Terraform initialized (`.terraform/` directory exists)
- ✅ Provider lock file present (`.terraform.lock.hcl`)
- ❌ Workspace verification **BLOCKED** (requires AWS credentials)
- ⚠️ Local terraform.tfstate exists (1566 bytes) - may be stale

### Variables Configuration (sit.tfvars)
```hcl
environment    = "sit"
aws_account_id = "815856636111"
aws_region     = "eu-west-1"
project        = "bbws"
```
✅ All required variables configured correctly

---

## SCHEMA VALIDATION

### Schema Files Present
- ✅ `/schemas/tenants.schema.json` (3493 bytes)
- ✅ `/schemas/products.schema.json` (3288 bytes)
- ✅ `/schemas/campaigns.schema.json` (3911 bytes)
- ❌ `/schemas/orders.schema.json` - **MISSING**
- ❌ `/schemas/users.schema.json` - **MISSING**

### Schema Consistency Check

#### Tenants Schema ✅ CONSISTENT
- Schema defines: EmailIndex, TenantStatusIndex, ActiveIndex (3 GSIs)
- Terraform defines: EmailIndex, TenantStatusIndex, ActiveIndex (3 GSIs)
- **Status**: MATCH

#### Products Schema ✅ CONSISTENT
- Schema defines: ActiveProductsIndex (1 GSI)
- Terraform defines: ActiveProductsIndex (1 GSI)
- **Status**: MATCH

#### Campaigns Schema ✅ CONSISTENT
- Schema defines: CampaignActiveIndex, CampaignProductIndex, ActiveIndex (3 GSIs)
- Terraform defines: CampaignActiveIndex, CampaignProductIndex, ActiveIndex (3 GSIs)
- **Status**: MATCH

---

## GITHUB ACTIONS WORKFLOW REVIEW

### Deployment Workflow: deploy-sit.yml

**Status**: ✅ PROPERLY CONFIGURED

**Key Features**:
- Manual trigger (workflow_dispatch)
- 4-job pipeline: plan → approval → apply → summary
- OIDC authentication (AWS role from secrets.AWS_ROLE_SIT)
- Approval gate (sit-approval environment)
- Artifact retention: 7 days (plan), 90 days (outputs)

**Jobs**:
1. **Plan**: Terraform init + plan with sit.tfvars
2. **Approval**: Manual approval gate
3. **Apply**: Terraform apply with approved plan
4. **Summary**: Deployment status report

**Backend Configuration** (in workflow):
```bash
terraform init \
  -backend-config="bucket=bbws-terraform-state-sit" \
  -backend-config="key=2_1_bbws_dynamodb_schemas/terraform.tfstate" \
  -backend-config="region=eu-west-1" \
  -backend-config="dynamodb_table=terraform-state-lock-sit" \
  -backend-config="encrypt=true"
```

---

## VALIDATION SCRIPT REVIEW

### Script: `/scripts/validate_dynamodb_dev.py`

**Status**: ✅ EXISTS (adapted for DEV, needs SIT version)

**Validations Performed**:
1. Table existence check
2. Table status (ACTIVE)
3. Primary key configuration (PK, SK)
4. GSI verification
5. PITR enabled check
6. Streams enabled check
7. Billing mode (ON_DEMAND)
8. Required tags

**Expected GSIs (per validation script)**:
- tenants: EmailIndex, TenantStatusIndex, ActiveIndex (3 GSIs)
- products: ProductActiveIndex, ActiveIndex (2 GSIs)
- campaigns: CampaignActiveIndex, CampaignProductIndex, ActiveIndex (3 GSIs)
- **Total: 8 GSIs**

**DISCREPANCY IDENTIFIED**: Validation script expects 8 GSIs, but terraform only defines 7 GSIs!

**Missing GSI**: The validation script expects `products` table to have `ActiveIndex` in addition to `ProductActiveIndex`, but terraform only defines `ActiveProductsIndex`.

---

## BLOCKERS AND WARNINGS

### CRITICAL BLOCKERS (Must Fix Before Deployment)

1. **BLOCKER 1**: Missing `orders` table
   - **Impact**: HIGH - Dependent Lambda services will fail
   - **Action Required**: Add orders table definition to main.tf OR update promotion plan to reflect current architecture

2. **BLOCKER 2**: Missing `users` table
   - **Impact**: HIGH - User management features will fail
   - **Action Required**: Add users table definition to main.tf OR update promotion plan to reflect current architecture

3. **BLOCKER 3**: GSI naming inconsistency
   - **Impact**: MEDIUM - Validation script will fail, queries may break
   - **Action Required**: Reconcile GSI names between:
     - Promotion plan documentation
     - Terraform configuration
     - Validation script expectations
     - Schema JSON files

4. **BLOCKER 4**: No backup vault configuration
   - **Impact**: HIGH - Cannot meet backup retention requirements
   - **Action Required**: Add AWS Backup vault and backup plan to terraform

5. **BLOCKER 5**: No SIT-specific validation script
   - **Impact**: MEDIUM - Cannot validate SIT deployment
   - **Action Required**: Create `validate_dynamodb_sit.py` with SIT-specific config

### WARNINGS (Should Address)

1. **WARNING 1**: Terraform workspace not verified
   - **Reason**: AWS credentials required for workspace commands
   - **Mitigation**: Verify workspace during actual deployment

2. **WARNING 2**: Local terraform.tfstate file exists
   - **Concern**: May cause state conflicts with S3 backend
   - **Mitigation**: Ensure backend is properly configured on first run

3. **WARNING 3**: No release tag created
   - **Impact**: LOW - Difficult to track deployed version
   - **Mitigation**: Create git tag before triggering workflow

4. **WARNING 4**: Streams configuration inconsistent
   - Products table: streams disabled
   - Campaigns/Tenants: streams enabled
   - **Review**: Confirm this is intentional based on business requirements

5. **WARNING 5**: Table naming inconsistency
   - `tenants`: No environment suffix
   - `campaigns`: No environment suffix
   - `products-sit`: Has environment suffix
   - **Mitigation**: Standardize naming convention

---

## DEPENDENCIES

### Upstream Dependencies
- ✅ None - This is foundation infrastructure (Wave 2)

### Downstream Dependencies (BLOCKED by this deployment)
The following Lambda services cannot be promoted to SIT until DynamoDB tables are deployed:

**Wave 1 - Lambda Services**:
1. `campaigns_lambda` - **BLOCKED** (requires campaigns table)
2. `order_lambda` - **BLOCKED** (requires orders table - NOT DEFINED)
3. `product_lambda` - **BLOCKED** (requires products table)
4. Tenant management services - **BLOCKED** (requires tenants + users tables)

---

## RISK ASSESSMENT

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Missing tables cause Lambda failures | HIGH | CRITICAL | Add missing table definitions before deployment |
| GSI naming breaks application queries | MEDIUM | HIGH | Reconcile GSI naming across all documentation and code |
| No backup vault prevents disaster recovery | HIGH | CRITICAL | Add backup vault terraform configuration |
| State file conflicts | LOW | MEDIUM | Use S3 backend from first init |
| Wrong AWS account deployment | LOW | CRITICAL | Verify AWS account ID before apply |
| Incomplete PITR recovery | MEDIUM | HIGH | Test PITR restore in DEV first |

---

## RECOMMENDATIONS

### IMMEDIATE ACTIONS (Before SIT Deployment)

1. **CRITICAL**: Resolve table count discrepancy
   - **Option A**: Add `orders` and `users` table definitions to terraform
   - **Option B**: Update promotion plan to reflect current 3-table architecture
   - **Recommendation**: Investigate original requirements to determine correct approach

2. **CRITICAL**: Standardize GSI naming
   - Review application code to determine which GSI names are actually used
   - Update terraform configuration to match application expectations
   - Update promotion plan documentation
   - Update validation scripts

3. **CRITICAL**: Add backup vault configuration
   - Define `aws_backup_vault` resource in terraform
   - Define `aws_backup_plan` resource with hourly schedule
   - Define `aws_backup_selection` to target all DynamoDB tables
   - Configure 14-day retention for SIT (per promotion plan)

4. **HIGH**: Create SIT validation script
   - Copy `validate_dynamodb_dev.py` to `validate_dynamodb_sit.py`
   - Update account ID: 815856636111
   - Update environment: sit
   - Update expected table names (with environment suffixes if applicable)
   - Verify expected GSI list matches terraform configuration

5. **HIGH**: Standardize table naming
   - Choose consistent pattern: either `{table}-sit` OR `{table}` for all tables
   - Update terraform configuration
   - Update promotion plan documentation

6. **MEDIUM**: Create release tag
   - Tag commit: `git tag -a v1.0.0-sit -m "SIT release for DynamoDB schemas"`
   - Document changes in CHANGELOG.md

7. **MEDIUM**: Test terraform plan locally (when AWS credentials available)
   ```bash
   cd terraform/dynamodb
   terraform init -backend-config=...
   terraform workspace select sit || terraform workspace new sit
   terraform plan -var-file=environments/sit.tfvars
   ```

### ARCHITECTURE REVIEW REQUIRED

The discrepancies identified suggest a possible misalignment between:
- Original HLD/LLD design documents
- Promotion plan documentation
- Actual implemented terraform code

**Recommendation**: Conduct architecture review meeting with:
- Product Owner (clarify table requirements)
- Backend Developer (verify Lambda dependencies)
- DBA (review backup/recovery strategy)
- DevOps Engineer (validate deployment approach)

---

## DEPLOYMENT PROCESS (WHEN READY)

### Pre-Deployment
1. Resolve all CRITICAL blockers listed above
2. Obtain AWS SSO access to SIT account (815856636111)
3. Verify AWS credentials: `aws sts get-caller-identity --profile Tebogo-sit`
4. Create release tag: `v1.0.0-sit`
5. Update CHANGELOG.md

### Deployment Steps
1. Go to GitHub Actions: https://github.com/{repo}/actions
2. Select "Deploy to SIT" workflow
3. Click "Run workflow"
4. Select component: `dynamodb`
5. Review terraform plan in "Plan" job output
6. Approve deployment at approval gate
7. Monitor "Apply" job for successful completion
8. Download deployment outputs artifact

### Post-Deployment Validation
1. Run validation script: `python3 scripts/validate_dynamodb_sit.py`
2. Verify all tables ACTIVE in AWS Console
3. Verify GSIs ACTIVE
4. Test write/read operations
5. Verify PITR enabled
6. Verify backup vault created and backup plan executing
7. Document deployment in promotion plan

### Rollback Procedure
**WARNING**: DynamoDB table deletion is IRREVERSIBLE

If deployment fails:
- Do NOT delete tables if any data has been written
- Use PITR or backups to restore if needed
- Document incident before any rollback actions
- Contact DBA before executing rollback

---

## COST ESTIMATE

**Estimated Monthly Cost (SIT)**:

| Resource | Quantity | Estimated Cost |
|----------|----------|----------------|
| DynamoDB tables (on-demand, minimal usage) | 3 tables | $5-10/month |
| PITR (continuous backups) | 3 tables | $5-15/month |
| DynamoDB Streams | 2 streams | $2-5/month |
| AWS Backup (if configured) | 3 tables, daily | $10-20/month |
| **TOTAL** | | **$22-50/month** |

**Note**: Costs will be minimal in SIT due to low transaction volume. Production costs will be significantly higher.

---

## CONCLUSION

**Deployment Readiness**: ❌ **NOT READY - BLOCKED**

The 2_1_bbws_dynamodb_schemas project has significant discrepancies between documented plans and implemented code. Critical issues must be resolved before SIT deployment can proceed:

**MUST FIX**:
1. Resolve missing tables (orders, users)
2. Reconcile GSI naming inconsistencies
3. Add backup vault configuration
4. Create SIT validation script
5. Standardize table naming convention

**ESTIMATED TIME TO READY**: 2-3 days
- 1 day: Architecture review and decision on missing tables
- 1 day: Terraform updates, validation script creation
- 0.5 day: Testing in DEV environment
- 0.5 day: Documentation updates

**NEXT STEPS**:
1. Schedule architecture review meeting (URGENT)
2. Update terraform configuration based on review outcomes
3. Test all changes in DEV environment first
4. Update promotion plan documentation to reflect actual implementation
5. Re-run this readiness assessment
6. Proceed with SIT deployment only after all blockers resolved

---

## APPENDIX: FILE LOCATIONS

### Project Files
- **Terraform Configuration**: `/Users/tebogotseka/Documents/agentic_work/2_1_bbws_dynamodb_schemas/terraform/dynamodb/`
- **Schemas**: `/Users/tebogotseka/Documents/agentic_work/2_1_bbws_dynamodb_schemas/schemas/`
- **Scripts**: `/Users/tebogotseka/Documents/agentic_work/2_1_bbws_dynamodb_schemas/scripts/`
- **Workflows**: `/Users/tebogotseka/Documents/agentic_work/2_1_bbws_dynamodb_schemas/.github/workflows/`

### Documentation
- **Promotion Plan**: `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/promotions/04_dynamodb_schemas_promotion.md`
- **This Report**: `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/deployments/sit_dynamodb_schemas_readiness_report.md`

### Key Files Reviewed
- `main.tf` (236 lines, 3 tables, 7 GSIs)
- `sit.tfvars` (13 lines, environment configuration)
- `deploy-sit.yml` (235 lines, GitHub Actions workflow)
- `validate_dynamodb_dev.py` (352 lines, validation script)
- `tenants.schema.json`, `products.schema.json`, `campaigns.schema.json`

---

**Report Prepared By**: DevOps Engineer Agent
**Report Date**: 2026-01-07
**Review Status**: CRITICAL REVIEW REQUIRED
**Approval Required From**: Tech Lead, Product Owner, DBA, DevOps Lead

