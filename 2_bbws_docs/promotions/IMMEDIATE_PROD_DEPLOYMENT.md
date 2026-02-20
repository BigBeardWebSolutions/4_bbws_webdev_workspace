# Immediate PROD Deployment Plan

**Created**: 2026-01-08 08:05
**Status**: 🚀 APPROVED - DEPLOY ASAP
**Target**: Jan 10, 2026 (as soon as soak testing completes)
**Scope**: All 6 projects

---

## Executive Summary

**Strategy**: Deploy to PROD immediately after 48-hour soak testing validates SIT stability

**Timeline**:
- **Jan 8-9**: Complete soak testing (in progress)
- **Jan 9, 18:40**: Soak complete → Go/No-Go decision
- **Jan 9, 19:00-22:00**: PROD environment prep (evening)
- **Jan 10, 09:00-14:00**: PROD deployment (morning)

**Total Time**: ~36 hours from now

---

## Deployment Schedule

```
TODAY (Jan 8)
├─ 14:00 - Checkpoint #4 (auto)
├─ 20:00 - Checkpoint #5 (auto, 24-hour mark)
└─ Status: 2/8 checkpoints complete ✅

TOMORROW (Jan 9)
├─ 02:00 - Checkpoint #6 (auto)
├─ 08:00 - Checkpoint #7 (auto)
├─ 14:00 - Checkpoint #8 (auto, final)
├─ 18:40 - Soak testing complete
├─ 19:00 - GO/NO-GO decision
└─ 19:00-22:00 - PROD prep (if GO)

DAY AFTER (Jan 10)
├─ 09:00-10:00 - Batch 1: Foundation
├─ 10:30-11:30 - Batch 2: Backend
├─ 12:00-14:00 - Batch 3: APIs
└─ 14:00-17:00 - Validation & monitoring
```

---

## Prerequisites (Check Now)

### PROD AWS Account (093646564004)
```bash
# Verify PROD access
aws sso login --profile Tebogo-prod
AWS_PROFILE=Tebogo-prod aws sts get-caller-identity
```

**Required**:
- [x] PROD account access working ✅ (Verified: 093646564004)
- [x] VPC exists in af-south-1 ✅ (vpc-080991bf9615e8c65, prod-vpc, 10.3.0.0/16)
- [x] IAM role for GitHub Actions OIDC ✅ (2-1-bbws-tf-github-actions-prod)
- [x] S3 bucket for Terraform state ✅ (bbws-terraform-state-prod)
- [x] DynamoDB table for Terraform locks ✅ (terraform-state-lock-prod)

### DR Setup (eu-west-1)
- [ ] DR infrastructure ready OR
- [x] Plan to deploy DR after PROD primary ✅ (Multi-site active/active strategy)

### GitHub Actions Workflows Status (Verified Jan 8, 08:15)

| Repository | PROD Workflow | Workflow Name | Secret Name | Secret Status |
|------------|---------------|---------------|-------------|---------------|
| dynamodb_schemas | ✅ deploy-prod.yml | Deploy to PROD | AWS_ROLE_PROD | ❌ Missing |
| s3_schemas | ✅ deploy-prod.yml | Deploy to PROD | AWS_ROLE_PROD | ❌ Missing |
| web_public | ⚠️ deploy-application.yml | Deploy Application | AWS_ROLE_ARN_PROD | ✅ Configured |
| campaigns_lambda | ✅ promote-prod.yml | Promote to PROD | AWS_ROLE_ARN_PROD | ❌ Missing |
| product_lambda | ✅ deploy-prod.yml | Deploy to PROD | Hardcoded in workflow | ✅ N/A (already deployed) |
| order_lambda | ✅ terraform-prod.yml | Terraform Deploy - PROD | Hardcoded in workflow | ✅ N/A (already deployed) |

**Summary**:
- ✅ All repos have PROD workflows
- ⚠️ 3 repos need GitHub secrets configured (dynamodb, s3, campaigns)
- ✅ 2 repos already deployed to PROD (product, order)
- ✅ 1 repo fully configured (web_public)

**Action Required**: Set GitHub secrets before Jan 9 evening prep

---

## Tonight (Jan 9, 19:00-22:00): PROD Prep

**IF soak testing passes**, execute these tasks:

### Task 1: PROD Infrastructure Check (30 min)
```bash
AWS_PROFILE=Tebogo-prod aws ec2 describe-vpcs
AWS_PROFILE=Tebogo-prod aws s3 ls | grep terraform
AWS_PROFILE=Tebogo-prod aws dynamodb list-tables
```

**Create if missing**:
- VPC (af-south-1)
- Terraform state bucket
- Terraform locks table

### Task 2: IAM Role Setup (30 min)
```bash
# Create GitHub Actions OIDC role if not exists
AWS_PROFILE=Tebogo-prod aws iam get-role \
  --role-name github-actions-oidc-prod
```

**Permissions needed**:
- S3 (buckets, objects)
- DynamoDB (tables, items)
- Lambda (functions, aliases)
- API Gateway (REST APIs, deployments)
- CloudWatch (logs, alarms)

### Task 3: GitHub Secrets (20 min)
```bash
# IAM role ARN for PROD deployments
PROD_ROLE_ARN="arn:aws:iam::093646564004:role/2-1-bbws-tf-github-actions-prod"

# Set AWS_ROLE_PROD for schema repos (they use this secret name)
gh secret set AWS_ROLE_PROD \
  --repo BigBeardWebSolutions/2_1_bbws_dynamodb_schemas \
  --body "$PROD_ROLE_ARN"

gh secret set AWS_ROLE_PROD \
  --repo BigBeardWebSolutions/2_1_bbws_s3_schemas \
  --body "$PROD_ROLE_ARN"

# Set AWS_ROLE_ARN_PROD for campaigns Lambda (it uses this secret name)
gh secret set AWS_ROLE_ARN_PROD \
  --repo BigBeardWebSolutions/2_bbws_campaigns_lambda \
  --body "$PROD_ROLE_ARN"

# web_public: Already has AWS_ROLE_ARN_PROD ✅
# product_lambda: Uses hardcoded role in workflow ✅
# order_lambda: Uses hardcoded role in workflow ✅

# Check if web_public needs CLOUDFRONT_DISTRIBUTION_ID_PROD
# (Currently only has DEV and SIT distribution IDs configured)
gh secret list --repo BigBeardWebSolutions/2_1_bbws_web_public | grep CLOUDFRONT

# If missing, get PROD CloudFront distribution ID and set it:
# AWS_PROFILE=Tebogo-prod aws cloudfront list-distributions --query 'DistributionList.Items[?Comment==`PROD Frontend`].Id' --output text
# gh secret set CLOUDFRONT_DISTRIBUTION_ID_PROD \
#   --repo BigBeardWebSolutions/2_1_bbws_web_public \
#   --body "<DISTRIBUTION_ID>"

# Verify all secrets
echo "Verifying secrets..."
gh secret list --repo BigBeardWebSolutions/2_1_bbws_dynamodb_schemas | grep PROD
gh secret list --repo BigBeardWebSolutions/2_1_bbws_s3_schemas | grep PROD
gh secret list --repo BigBeardWebSolutions/2_bbws_campaigns_lambda | grep PROD
```

**Notes**:
- Product and Order Lambda workflows have the IAM role ARN hardcoded (line 96 in workflows), so they don't need GitHub secrets
- web_public may need CLOUDFRONT_DISTRIBUTION_ID_PROD if deploying via workflow (check during prep)

### Task 4: Release Tags (30 min)
```bash
# Tag releases for all 6 projects
cd /Users/tebogotseka/Documents/agentic_work/2_1_bbws_dynamodb_schemas
git tag -a v1.0.0-prod -m "PROD Release - Jan 10, 2026"
git push origin v1.0.0-prod

# Repeat for all 6 repos
```

### Task 5: DNS & SSL (1 hour)
```bash
# Verify Route 53 hosted zones
AWS_PROFILE=Tebogo-prod aws route53 list-hosted-zones

# Request SSL certificates (if not exist)
AWS_PROFILE=Tebogo-prod aws acm request-certificate \
  --domain-name "*.kimmyai.io" \
  --validation-method DNS \
  --region af-south-1
```

---

## Tomorrow Morning (Jan 10): PROD Deployment

### Pre-Deployment Checklist (08:30-09:00)

```bash
# Verify SIT still stable
curl https://sit.kimmyai.io
curl https://u3lui292v4.execute-api.eu-west-1.amazonaws.com/api/campaigns/health

# Verify PROD access
AWS_PROFILE=Tebogo-prod aws sts get-caller-identity

# Team ready
- DevOps Engineer: READY
- Tech Lead: STANDBY
- Rollback plan: REVIEWED
```

---

### Batch 1: Foundation (09:00-10:00)

#### DynamoDB Schemas
```bash
cd /Users/tebogotseka/Documents/agentic_work/2_1_bbws_dynamodb_schemas

# Deploy via GitHub Actions
gh workflow run deploy-prod.yml --ref v1.0.0-prod

# Monitor
gh run watch

# Verify
AWS_PROFILE=Tebogo-prod aws dynamodb list-tables
```

**Expected**: 3 tables (tenants, products, campaigns)
**Duration**: 10 minutes

#### S3 Schemas
```bash
cd /Users/tebogotseka/Documents/agentic_work/2_1_bbws_s3_schemas

# Deploy
gh workflow run deploy-prod.yml --ref v1.0.0-prod

# Upload templates
AWS_PROFILE=Tebogo-prod aws s3 sync templates/ s3://bbws-templates-prod/

# Verify
AWS_PROFILE=Tebogo-prod aws s3 ls s3://bbws-templates-prod/
```

**Expected**: 1 bucket, 12 templates
**Duration**: 10 minutes

---

### Batch 2: Backend (10:30-11:30)

#### Backend Public
```bash
cd /Users/tebogotseka/Documents/agentic_work/2_1_bbws_web_public

# Deploy
gh workflow run deploy-prod.yml --ref v1.0.0-prod

# Monitor (includes build + CloudFront deployment)
gh run watch

# Verify
curl -I https://kimmyai.io
```

**Expected**: React SPA live at https://kimmyai.io
**Duration**: 20 minutes

---

### Batch 3: Lambda APIs (12:00-14:00)

**Deployment Strategy**: Blue/Green with gradual traffic shift

#### Product Lambda
```bash
cd /Users/tebogotseka/Documents/agentic_work/2_bbws_product_lambda

# Deploy green version
gh workflow run deploy-prod.yml --ref v1.0.0-prod

# Wait for completion
gh run watch

# Shift 10% traffic
AWS_PROFILE=Tebogo-prod aws lambda update-alias \
  --function-name 2-1-bbws-tf-product-get-prod \
  --name live \
  --routing-config AdditionalVersionWeights={"2"=0.1}

# Monitor for 10 minutes
# If stable: shift 50%, monitor 5 min
# If stable: shift 100%
```

**Expected**: 5 functions, API at api.kimmyai.io/products
**Duration**: 30 minutes

#### Order Lambda
```bash
cd /Users/tebogotseka/Documents/agentic_work/2_bbws_order_lambda

# Same blue/green process
gh workflow run deploy-prod.yml --ref v1.0.0-prod
# Gradual shift: 10% → 50% → 100%
```

**Expected**: 10 functions, API at api.kimmyai.io/orders
**Duration**: 40 minutes

#### Campaigns Lambda
```bash
cd /Users/tebogotseka/Documents/agentic_work/2_bbws_campaigns_lambda

# Same blue/green process
gh workflow run deploy-prod.yml --ref v1.0.0-prod
# Gradual shift: 10% → 50% → 100%
```

**Expected**: 5 functions, API at api.kimmyai.io/campaigns
**Duration**: 30 minutes

---

### Post-Deployment Validation (14:00-15:00)

#### Health Checks
```bash
# All APIs
curl https://api.kimmyai.io/v1.0/campaigns/health
curl https://api.kimmyai.io/v1.0/orders/health
curl https://api.kimmyai.io/v1.0/products/health

# Backend
curl https://kimmyai.io
```

**Expected**: All return 200 or 401/403 (auth required)

#### Smoke Tests
```bash
cd /Users/tebogotseka/Documents/agentic_work/2_bbws_agents/scripts

# Run PROD smoke tests
./smoke_test_campaigns.sh prod
./smoke_test_products.sh prod
./smoke_test_orders.sh prod
```

**Expected**: All tests passing (auth enforcement working)

#### Monitoring
```bash
# Check CloudWatch
AWS_PROFILE=Tebogo-prod aws cloudwatch describe-alarms \
  --state-value ALARM

# Check Lambda metrics
AWS_PROFILE=Tebogo-prod aws lambda list-functions | grep prod
```

**Expected**:
- 0 alarms in ALARM state
- All 20 Lambda functions active
- No errors in CloudWatch

---

## Go/No-Go Criteria

### Before PROD Prep (Jan 9, 19:00)

**SIT Soak Testing** (must ALL pass):
- [ ] All 8 checkpoints completed
- [ ] Error rate < 0.1% across all checkpoints
- [ ] Lambda duration p95 < 2s
- [ ] Zero throttling events
- [ ] No P0 or P1 incidents
- [ ] All Lambda functions active
- [ ] All alarms green (except 1 pre-existing order DLQ)

**IF ANY FAIL**: Investigate, fix in SIT, restart soak testing

### Before PROD Deployment (Jan 10, 09:00)

**PROD Environment** (must ALL be ready):
- [ ] PROD account access working
- [ ] IAM roles configured
- [ ] GitHub secrets set
- [ ] Release tags created
- [ ] DNS/SSL ready (or plan to configure)
- [ ] Team ready and on standby

**IF ANY MISSING**: Complete prep, delay by 1-2 hours

---

## Rollback Plan

### Instant Rollback (< 1 minute)
```bash
# Shift Lambda traffic back to previous version
AWS_PROFILE=Tebogo-prod aws lambda update-alias \
  --function-name <function-name> \
  --name live \
  --function-version <previous-version>
```

### Full Rollback (< 10 minutes)
```bash
# Revert infrastructure
cd <project>/terraform
terraform workspace select prod
terraform destroy -target=<new-resource>
```

### Rollback Triggers
- Error rate > 5% (immediate)
- Response time p95 > 5s (within 15 min)
- Data corruption (immediate)
- Any P0 incident (immediate)

---

## Success Criteria

### Deployment Success (Jan 10, 15:00)
- [ ] All 6 projects deployed
- [ ] Zero downtime
- [ ] All health checks green
- [ ] Error rate < 0.1%
- [ ] Response time p95 < 500ms
- [ ] No customer-impacting issues

### 24-Hour Soak (Jan 10-11)
- [ ] Monitor every 2 hours
- [ ] Run smoke tests every 4 hours
- [ ] CloudWatch dashboards active
- [ ] No critical incidents
- [ ] Final sign-off (Jan 11, 15:00)

---

## Risk Assessment

### Risks
| Risk | Impact | Mitigation |
|------|--------|------------|
| No time for comprehensive testing | HIGH | Use SIT results, focus on smoke tests |
| PROD infrastructure not ready | HIGH | Prep tonight (Jan 9), verify before deploy |
| Hidden PROD-only issues | MEDIUM | Blue/green deployment, gradual traffic |
| Team fatigue | MEDIUM | Clear schedule, backup team on standby |

### Acceptance
✅ **ACCEPTED** - User approved immediate deployment after soak testing

---

## Current Status

**Now** (Jan 8, 08:05):
- ✅ Checkpoint #1 complete (07:25)
- ✅ Checkpoint #3 complete (07:45)
- ⏳ Checkpoint #4 pending (14:00 today)
- ⏳ 6 more checkpoints (Jan 8-9)

**Hours Until PROD**:
- ~34 hours until soak complete (Jan 9, 18:40)
- ~36 hours until PROD prep (Jan 9, 19:00)
- ~49 hours until PROD deployment (Jan 10, 09:00)

---

## Next Actions

### Right Now
1. ✅ Continue automated soak testing
2. 📋 Review PROD account access
3. 📋 Verify GitHub workflows have `deploy-prod.yml`
4. 📋 Check if PROD infrastructure exists

### Tonight (if available)
1. Pre-check PROD account
2. Verify IAM roles exist
3. Test GitHub Actions access
4. Prepare release tags

### Tomorrow Evening (Jan 9, 19:00)
1. **IF soak passes**: Execute PROD prep (2-3 hours)
2. **IF soak fails**: Investigate, fix, continue monitoring

### Day After Tomorrow (Jan 10, 09:00)
1. 🚀 PROD DEPLOYMENT
2. Deploy in 3 batches (foundation → backend → APIs)
3. Validate and monitor
4. 24-hour soak in PROD

---

**Status**: ✅ PLAN READY
**Approval**: ✅ USER APPROVED
**Timeline**: Deploy ASAP after soak complete
**Risk**: MODERATE (acceptable)

---

**Last Updated**: 2026-01-08 08:05
