# Promotion Plan: campaigns_lambda

**Project**: 2_bbws_campaigns_lambda
**Plan ID**: PROM-CAMP-001
**Created**: 2026-01-07
**Owner**: DevOps Engineer
**Status**: 📋 READY FOR EXECUTION

---

## Project Overview

| Attribute | Value |
|-----------|-------|
| **Project Type** | API Lambda Microservice |
| **Purpose** | Campaign retrieval for Customer Portal |
| **Current Status** | 95% complete, Production Ready |
| **Test Coverage** | 99.43% |
| **Handlers** | 5 (create, get, list, update, delete) |
| **CI/CD Workflows** | 4 (deploy-dev, promote-sit, promote-prod, terraform-validate) |

---

## Environments

| Environment | AWS Account | Region | Domain | Status |
|-------------|-------------|--------|--------|--------|
| **DEV** | 536580886816 | eu-west-1 | `api.dev.kimmyai.io` | ✅ Deployed |
| **SIT** | 815856636111 | eu-west-1 | `api.sit.kimmyai.io` | ⏳ Target |
| **PROD** | 093646564004 | af-south-1 | `api.kimmyai.io` | 🔵 Planned |

---

## Promotion Timeline

```
PHASE 1: SIT PROMOTION (Jan 10, 2026)
├─ Pre-deployment  (Jan 8-9)
├─ Deployment      (Jan 10, 10:00 AM)
├─ Validation      (Jan 10, 10:30 AM - 12:00 PM)
└─ Sign-off        (Jan 10, 4:00 PM)

PHASE 2: SIT VALIDATION (Jan 11-31)
├─ Integration Testing (Jan 11-14)
├─ Load Testing        (Jan 15-17)
├─ Security Scanning   (Jan 20-21)
└─ SIT Sign-off        (Jan 31)

PHASE 3: PROD PROMOTION (Feb 21, 2026)
├─ Pre-deployment  (Feb 17-20)
├─ Deployment      (Feb 21, 9:00 AM)
├─ Validation      (Feb 21, 9:30 AM - 11:00 AM)
└─ Sign-off        (Feb 24, 4:00 PM)
```

---

## Phase 1: SIT Promotion

### Pre-Deployment Checklist (Jan 8-9)

#### Environment Verification
- [ ] AWS SSO login to SIT account (815856636111)
- [ ] Verify AWS profile: `AWS_PROFILE=Tebogo-sit aws sts get-caller-identity`
- [ ] Confirm SIT region: eu-west-1
- [ ] Verify Route53 hosted zone for `api.sit.kimmyai.io`
- [ ] Check SSL certificate in ACM for `api.sit.kimmyai.io`

#### Code Preparation
- [ ] Verify latest code in `main` branch
- [ ] Confirm all tests passing in DEV
- [ ] Review GitHub Actions workflows (promote-sit.yml)
- [ ] Tag release: `v1.0.0-sit`
- [ ] Create changelog for SIT release

#### Infrastructure
- [ ] Verify DynamoDB table exists in SIT: `campaigns-sit`
- [ ] Confirm S3 bucket for email templates: `bbws-templates-sit`
- [ ] Check Lambda execution role in SIT
- [ ] Verify VPC configuration (if applicable)
- [ ] Confirm CloudWatch Log Groups created

#### Dependencies
- [ ] DynamoDB schemas promoted to SIT (dependency)
- [ ] S3 schemas promoted to SIT (dependency)
- [ ] API Gateway base path mapping ready
- [ ] Cognito user pool in SIT configured (if used)

### Deployment Steps (Jan 10, 10:00 AM)

#### Step 1: Terraform Workspace Switch
```bash
cd /Users/tebogotseka/Documents/agentic_work/2_bbws_campaigns_lambda/terraform
terraform workspace select sit
terraform workspace list  # Verify 'sit' is selected
```

#### Step 2: Terraform Plan
```bash
AWS_PROFILE=Tebogo-sit terraform plan -out=sit.tfplan
# Review output carefully
# Verify no unexpected changes
# Confirm resource counts match expectations
```

#### Step 3: Manual Approval
- Review terraform plan output
- Verify no data-destructive operations
- Get approval from Tech Lead
- Document approval in deployment log

#### Step 4: Terraform Apply
```bash
AWS_PROFILE=Tebogo-sit terraform apply sit.tfplan
```

#### Step 5: Deploy Lambda Code
```bash
# Option 1: GitHub Actions (Recommended)
gh workflow run promote-sit.yml --ref main

# Option 2: Manual deployment
cd /Users/tebogotseka/Documents/agentic_work/2_bbws_campaigns_lambda
./scripts/deploy-sit.sh
```

#### Step 6: Verify Deployment
```bash
# Check Lambda function exists
AWS_PROFILE=Tebogo-sit aws lambda list-functions | grep campaigns

# Get function details
AWS_PROFILE=Tebogo-sit aws lambda get-function --function-name campaigns-handler-sit

# Check environment variables
AWS_PROFILE=Tebogo-sit aws lambda get-function-configuration \
  --function-name campaigns-handler-sit --query 'Environment'
```

### Post-Deployment Validation (Jan 10, 10:30 AM - 12:00 PM)

#### Smoke Tests
```bash
# Test 1: Health Check
curl -X GET https://api.sit.kimmyai.io/v1.0/campaigns/health

# Test 2: List campaigns (should return empty or test data)
curl -X GET https://api.sit.kimmyai.io/v1.0/campaigns \
  -H "Authorization: Bearer ${SIT_TOKEN}"

# Test 3: Create campaign
curl -X POST https://api.sit.kimmyai.io/v1.0/campaigns \
  -H "Authorization: Bearer ${SIT_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "SIT Test Campaign",
    "status": "draft",
    "start_date": "2026-02-01"
  }'

# Test 4: Get campaign by ID
curl -X GET https://api.sit.kimmyai.io/v1.0/campaigns/{campaign_id} \
  -H "Authorization: Bearer ${SIT_TOKEN}"

# Test 5: Update campaign
curl -X PUT https://api.sit.kimmyai.io/v1.0/campaigns/{campaign_id} \
  -H "Authorization: Bearer ${SIT_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "status": "active"
  }'

# Test 6: Delete campaign
curl -X DELETE https://api.sit.kimmyai.io/v1.0/campaigns/{campaign_id} \
  -H "Authorization: Bearer ${SIT_TOKEN}"
```

#### Monitoring Checks
- [ ] Check CloudWatch Logs for errors
  ```bash
  AWS_PROFILE=Tebogo-sit aws logs tail /aws/lambda/campaigns-handler-sit --follow
  ```
- [ ] Verify CloudWatch Metrics (Invocations, Errors, Duration)
- [ ] Check X-Ray traces (if enabled)
- [ ] Verify alarms not triggered
- [ ] Review Lambda concurrent executions

#### Integration Tests
- [ ] Run automated integration test suite
  ```bash
  cd tests/integration
  pytest test_campaigns_api.py --env=sit
  ```
- [ ] Verify all 5 handlers (create, get, list, update, delete)
- [ ] Test error handling scenarios
- [ ] Verify authorization/authentication
- [ ] Test rate limiting (if configured)

---

## Phase 2: SIT Validation (Jan 11-31)

### Week 1: Integration Testing (Jan 11-14)
- [ ] Test with order_lambda integration
- [ ] Test with product_lambda integration
- [ ] End-to-end campaign workflow testing
- [ ] Cross-service transaction testing
- [ ] Database integrity verification

### Week 2: Load Testing (Jan 15-17)
- [ ] Configure load testing tool (JMeter/k6)
- [ ] Run load test: 100 req/sec for 10 minutes
- [ ] Run stress test: Gradual increase to failure point
- [ ] Monitor Lambda concurrency and throttling
- [ ] Verify auto-scaling behavior
- [ ] Document performance metrics

### Week 3: Security & Compliance (Jan 20-21)
- [ ] Run OWASP ZAP security scan
- [ ] SQL injection testing
- [ ] XSS vulnerability testing
- [ ] Authentication bypass testing
- [ ] Authorization matrix validation
- [ ] Data encryption verification (in-transit, at-rest)

### Week 4: Final Validation (Jan 27-31)
- [ ] Re-run full test suite
- [ ] UAT with business stakeholders
- [ ] Performance benchmarking
- [ ] Cost analysis (Lambda invocations, data transfer)
- [ ] SIT sign-off meeting
- [ ] SIT approval gate passed

---

## Phase 3: PROD Promotion (Feb 21, 2026)

### Pre-Deployment Checklist (Feb 17-20)

#### Production Readiness
- [ ] All SIT tests passing
- [ ] SIT sign-off obtained (Gate 4)
- [ ] Performance meets SLA requirements
- [ ] Security scan clean (no high/critical issues)
- [ ] Disaster recovery plan documented
- [ ] Rollback procedure tested in SIT

#### PROD Environment Verification
- [ ] AWS SSO login to PROD account (093646564004)
- [ ] Verify AWS profile: `AWS_PROFILE=Tebogo-prod aws sts get-caller-identity`
- [ ] Confirm PROD region: af-south-1
- [ ] Verify Route53 hosted zone for `api.kimmyai.io`
- [ ] Check SSL certificate in ACM for `api.kimmyai.io`
- [ ] Verify multi-region DR setup (af-south-1 primary, eu-west-1 failover)

#### Change Management
- [ ] Change request submitted and approved
- [ ] Maintenance window scheduled (if required)
- [ ] Customer notification sent (if applicable)
- [ ] Rollback team on standby
- [ ] Communication channels ready

#### Data Migration
- [ ] Backup current PROD data (if any)
- [ ] Data migration script tested in SIT
- [ ] Data validation queries prepared
- [ ] Point-in-time recovery enabled

### Deployment Steps (Feb 21, 9:00 AM)

#### Step 1: Pre-deployment Verification
```bash
# Verify SIT is stable
curl -X GET https://api.sit.kimmyai.io/v1.0/campaigns/health

# Verify PROD access
AWS_PROFILE=Tebogo-prod aws sts get-caller-identity

# Create deployment snapshot
AWS_PROFILE=Tebogo-prod aws lambda get-function \
  --function-name campaigns-handler-prod > pre-deployment-snapshot.json
```

#### Step 2: Terraform Workspace Switch
```bash
cd /Users/tebogotseka/Documents/agentic_work/2_bbws_campaigns_lambda/terraform
terraform workspace select prod
terraform workspace list  # Verify 'prod' is selected
```

#### Step 3: Terraform Plan (Production)
```bash
AWS_PROFILE=Tebogo-prod terraform plan -out=prod.tfplan
# CRITICAL: Review output line by line
# Verify NO data destruction
# Confirm resource modifications are expected
```

#### Step 4: Final Approval
- Review terraform plan with Product Owner
- Confirm change request approved
- Get explicit "GO" from stakeholders
- Document all approvals

#### Step 5: Execute Deployment
```bash
# Blue/Green Deployment (Recommended)
gh workflow run promote-prod.yml --ref v1.0.0-prod

# Monitor deployment progress
gh run watch

# Alternative: Manual deployment with alias
AWS_PROFILE=Tebogo-prod ./scripts/deploy-prod-bluegreen.sh
```

#### Step 6: Traffic Shifting (Gradual)
```bash
# Start with 10% traffic to new version
AWS_PROFILE=Tebogo-prod aws lambda update-alias \
  --function-name campaigns-handler-prod \
  --name live \
  --routing-config AdditionalVersionWeights={"$LATEST"=0.1}

# Monitor for 15 minutes
# If stable, increase to 50%
# If stable, shift to 100%
```

### Post-Deployment Validation (Feb 21, 9:30 AM - 11:00 AM)

#### Critical Checks
- [ ] Health endpoint responding
- [ ] All 5 Lambda handlers operational
- [ ] No error spikes in CloudWatch
- [ ] Response times within SLA (<500ms p95)
- [ ] No customer-reported issues
- [ ] Database connections stable
- [ ] API Gateway throttling not triggered

#### Production Monitoring (First 24 Hours)
- [ ] Monitor every 30 minutes for first 6 hours
- [ ] Check error rates hourly
- [ ] Review CloudWatch alarms
- [ ] Monitor Lambda concurrency
- [ ] Track DynamoDB read/write capacity
- [ ] Verify backup jobs running

#### Production Monitoring (First Week)
- [ ] Daily health checks
- [ ] Weekly performance review
- [ ] Cost monitoring (Lambda, API Gateway, DynamoDB)
- [ ] User feedback collection
- [ ] Incident tracking

---

## Rollback Procedures

### SIT Rollback
```bash
# Revert to previous version
cd /Users/tebogotseka/Documents/agentic_work/2_bbws_campaigns_lambda
git checkout <previous-tag>
gh workflow run promote-sit.yml --ref <previous-tag>
```

### PROD Rollback (CRITICAL)
```bash
# Option 1: Instant alias switch (recommended for Lambda)
AWS_PROFILE=Tebogo-prod aws lambda update-alias \
  --function-name campaigns-handler-prod \
  --name live \
  --function-version <previous-version>

# Option 2: Full terraform revert
terraform workspace select prod
terraform apply -target=module.campaigns_lambda -var="version=<previous>"

# Option 3: GitHub Actions rollback
gh workflow run rollback-prod.yml --ref <previous-tag>
```

### Rollback Triggers
- Error rate > 5%
- Response time p95 > 2 seconds
- Any data corruption detected
- Critical functionality broken
- Customer escalation

---

## Success Criteria

### SIT Success
- [x] Deployment completed without errors
- [ ] All smoke tests passing
- [ ] Integration tests passing (100%)
- [ ] No critical or high severity bugs
- [ ] Performance baseline established
- [ ] Monitoring dashboards configured

### PROD Success
- [ ] Zero-downtime deployment
- [ ] All health checks green
- [ ] Error rate < 0.1%
- [ ] Response time p95 < 500ms
- [ ] No customer-impacting issues
- [ ] 72-hour soak period clean
- [ ] Product Owner sign-off

---

## Monitoring & Alerts

### CloudWatch Alarms
| Alarm | Threshold | Action |
|-------|-----------|--------|
| High Error Rate | > 5% errors | SNS alert to DevOps |
| High Duration | p95 > 2s | SNS alert to DevOps |
| Throttling | > 10 throttles/min | SNS alert + auto-scale |
| Dead Letter Queue | > 0 messages | SNS alert to DevOps |

### CloudWatch Dashboards
- Create: `campaigns-lambda-sit-dashboard`
- Create: `campaigns-lambda-prod-dashboard`
- Widgets: Invocations, Errors, Duration, Throttles, Concurrent Executions

---

## Contacts & Escalation

| Role | Contact | Availability |
|------|---------|--------------|
| DevOps Engineer | TBD | Primary deployer |
| Tech Lead | TBD | Approval & escalation |
| Product Owner | TBD | Final sign-off |
| On-Call SRE | TBD | 24/7 incident response |

---

## Documentation

### Deployment Artifacts
- [ ] Deployment runbook (this document)
- [ ] Terraform plan outputs (sit.tfplan, prod.tfplan)
- [ ] Test results (unit, integration, load)
- [ ] Performance benchmarks
- [ ] Security scan reports

### Post-Deployment
- [ ] Deployment retrospective notes
- [ ] Lessons learned document
- [ ] Updated architecture diagrams
- [ ] Updated API documentation
- [ ] Incident reports (if any)

---

## Change Log

| Date | Phase | Status | Notes |
|------|-------|--------|-------|
| 2026-01-07 | Planning | 📋 Complete | Promotion plan created |
| 2026-01-10 | SIT Deploy | ⏳ Scheduled | Target deployment |
| 2026-02-21 | PROD Deploy | 🔵 Planned | Target deployment |

---

**Next Steps:**
1. Review and approve this plan
2. Complete pre-deployment checklist
3. Schedule SIT deployment for Jan 10
4. Execute deployment following this plan

**Plan Status:** 📋 READY FOR REVIEW
**Approval Required By:** Tech Lead, DevOps Lead
