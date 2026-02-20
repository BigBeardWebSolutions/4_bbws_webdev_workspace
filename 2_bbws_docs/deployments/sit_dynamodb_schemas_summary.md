# SIT Deployment Summary: DynamoDB Schemas (READ-ONLY)

**Date**: 2026-01-07
**Project**: 2_1_bbws_dynamodb_schemas
**Environment**: SIT (815856636111, eu-west-1)
**Status**: ❌ **BLOCKED - NOT READY FOR DEPLOYMENT**

---

## QUICK STATUS

| Category | Status | Details |
|----------|--------|---------|
| **Overall Readiness** | ❌ BLOCKED | Critical discrepancies found |
| **Code Status** | ✅ Clean | Git working tree clean, on main branch |
| **Terraform Files** | ✅ Present | All required .tf files exist |
| **AWS Access** | ❌ Blocked | Invalid credentials (expected for read-only) |
| **Documentation** | ⚠️ Inconsistent | Plan vs. code mismatch |
| **Validation Script** | ⚠️ Partial | DEV only, needs SIT version |
| **Backup Config** | ❌ Missing | No backup vault defined |

---

## CRITICAL BLOCKERS (5)

### 1. MISSING TABLES (2)
**Expected**: 5 tables (campaigns, orders, products, tenants, users)
**Actual**: 3 tables (campaigns, products, tenants)
**Missing**: `orders`, `users`

### 2. GSI COUNT MISMATCH
**Expected**: 8 GSIs
**Actual**: 7 GSIs
**Issue**: Validation script expects 8, terraform defines 7

### 3. NO BACKUP VAULT
**Issue**: AWS Backup vault and backup plan not defined in terraform
**Impact**: Cannot meet 14-day retention requirement for SIT

### 4. NO SIT VALIDATION SCRIPT
**Issue**: Only `validate_dynamodb_dev.py` exists
**Impact**: Cannot validate SIT deployment post-apply

### 5. TABLE NAMING INCONSISTENCY
**Issue**:
- `tenants` (no suffix)
- `campaigns` (no suffix)
- `products-sit` (has suffix)

---

## ACTUAL RESOURCES (TERRAFORM)

### Tables: 3
1. **tenants** - 3 GSIs, PITR enabled, Streams enabled
2. **products-sit** - 1 GSI, PITR enabled, Streams disabled
3. **campaigns** - 3 GSIs, PITR enabled, Streams enabled

### GSIs: 7
**Tenants** (3):
- EmailIndex
- TenantStatusIndex
- ActiveIndex

**Products** (1):
- ActiveProductsIndex

**Campaigns** (3):
- CampaignActiveIndex
- CampaignProductIndex
- ActiveIndex

### Other Resources: 0
- No backup vault
- No backup plan
- No backup selection

---

## DOCUMENTATION DISCREPANCIES

| Document | Tables | GSIs | Notes |
|----------|--------|------|-------|
| Promotion Plan | 5 | 8 | orders-sit, users-sit missing |
| Terraform main.tf | 3 | 7 | Only campaigns, products, tenants |
| README.md | 3 | 8 | GSI count mismatch |
| Validation Script | 3 | 8 | Expects different GSI names |

---

## IMMEDIATE ACTIONS REQUIRED

### BEFORE SIT DEPLOYMENT

**Priority 1 - Architecture Decision**:
- [ ] Determine if orders/users tables are required
- [ ] Update terraform OR update promotion plan
- [ ] Document decision and rationale

**Priority 2 - Terraform Updates**:
- [ ] Add missing tables (if required)
- [ ] Add AWS Backup vault resource
- [ ] Add AWS Backup plan resource
- [ ] Standardize table naming (add/remove environment suffix)
- [ ] Reconcile GSI naming

**Priority 3 - Validation & Scripts**:
- [ ] Create `validate_dynamodb_sit.py`
- [ ] Update validation script with correct GSI names
- [ ] Test validation script in DEV first

**Priority 4 - Documentation**:
- [ ] Create release tag: `v1.0.0-sit`
- [ ] Update CHANGELOG.md
- [ ] Update promotion plan with actual resources
- [ ] Update README.md GSI count

**Priority 5 - Testing**:
- [ ] Test terraform plan locally (when credentials available)
- [ ] Verify terraform workspace: sit
- [ ] Dry-run validation script

---

## DEPLOYMENT BLOCKERS SUMMARY

**Cannot deploy to SIT until**:
1. Missing tables resolved (orders, users)
2. Backup vault configuration added
3. SIT validation script created
4. Table naming standardized
5. Documentation updated to match implementation

**Estimated Time to Ready**: 2-3 days

---

## DEPENDENCIES BLOCKED

**The following projects CANNOT be promoted to SIT until this completes**:

- campaigns_lambda (requires campaigns table)
- order_lambda (requires orders table - NOT DEFINED)
- product_lambda (requires products table)
- Tenant management services (requires tenants + users tables)

---

## GITHUB WORKFLOW STATUS

**File**: `.github/workflows/deploy-sit.yml`
**Status**: ✅ Properly configured

**Deployment Method**:
1. Manual trigger via GitHub Actions
2. Job 1: Terraform plan
3. Job 2: Manual approval gate
4. Job 3: Terraform apply
5. Job 4: Deployment summary

**Backend**: S3 bucket `bbws-terraform-state-sit`

---

## TERRAFORM STATE

**Backend Type**: S3
**Bucket**: bbws-terraform-state-sit
**Key**: 2_1_bbws_dynamodb_schemas/terraform.tfstate
**Region**: eu-west-1
**Lock Table**: terraform-state-lock-sit
**Encryption**: Enabled

**Workspace**: Cannot verify (requires AWS credentials)

---

## COST ESTIMATE

**Estimated SIT Monthly Cost**: $22-50/month
- DynamoDB tables (on-demand): $5-10
- PITR: $5-15
- Streams: $2-5
- Backup (when configured): $10-20

---

## NEXT STEPS

1. **URGENT**: Schedule architecture review meeting
   - Attendees: Product Owner, Backend Dev, DBA, DevOps
   - Agenda: Resolve missing tables (orders, users)

2. **HIGH**: Update terraform based on review outcome

3. **HIGH**: Add backup vault configuration

4. **MEDIUM**: Create SIT validation script

5. **MEDIUM**: Test changes in DEV

6. **LOW**: Update documentation

7. **When ready**: Re-run readiness assessment

8. **When all blockers clear**: Trigger SIT deployment

---

## APPROVAL STATUS

**Deployment Approval**: ❌ **DENIED - BLOCKERS PRESENT**

**Required Approvals Before Deployment**:
- [ ] Tech Lead (architecture decision)
- [ ] Product Owner (table requirements)
- [ ] DBA (backup strategy)
- [ ] DevOps Lead (deployment readiness)

---

## CONTACTS

| Role | Responsibility |
|------|----------------|
| Tech Lead | Architecture decisions, final approval |
| Product Owner | Requirements clarification |
| DBA | Backup/restore strategy, PITR configuration |
| DevOps Engineer | Deployment execution, troubleshooting |

---

## REFERENCES

**Full Report**: `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/deployments/sit_dynamodb_schemas_readiness_report.md`

**Promotion Plan**: `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/promotions/04_dynamodb_schemas_promotion.md`

**Project Location**: `/Users/tebogotseka/Documents/agentic_work/2_1_bbws_dynamodb_schemas`

---

**Report Generated**: 2026-01-07
**Next Review**: After blockers resolved

