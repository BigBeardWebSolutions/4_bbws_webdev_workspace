# BBWS Environment Promotion Runbook (DEV → SIT → PROD)

**Version**: 1.0
**Created**: 2025-12-25
**Status**: Final
**Component**: Multi-environment promotion strategy
**Scope**: S3, DynamoDB, Lambda, API Gateway across DEV, SIT, PROD

---

## Document Control

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-12-25 | Worker 5-2 | Initial version |

---

## 1. Overview

### 1.1 Promotion Strategy & Philosophy

The BBWS platform uses a three-environment promotion model with controlled gates between each environment:

- **DEV**: Development environment for active development and feature testing
- **SIT**: System Integration Testing environment for quality assurance
- **PROD**: Production environment (read-only during promotion) serving end customers

**Core Principle**: All defects must be fixed in DEV and promoted through SIT to PROD. Never hotfix production.

### 1.2 Promotion Objectives

- Ensure code quality and stability through progressive testing
- Maintain infrastructure consistency across environments
- Enable rapid but safe feature delivery
- Provide clear approval gates for governance
- Minimize deployment risk through thorough validation

### 1.3 Environment Details

| Attribute | DEV | SIT | PROD |
|-----------|-----|-----|------|
| AWS Account | 536580886816 | 815856636111 | 093646564004 |
| AWS Region | af-south-1 | af-south-1 | af-south-1 |
| Approval Gate | None | Tech Lead | Tech Lead + Business Owner |
| Change Ticket | Not Required | Recommended | Required |
| Downtime Tolerance | Any | <= 1 Hour | Zero-downtime |
| Data Retention | Development | Test | Live |

---

## 2. Promotion Flow (DEV → SIT → PROD)

### 2.1 Visual Workflow

```
┌─────────────┐      Approval       ┌──────────────┐      Approval       ┌──────────────┐
│     DEV     │ ────────────────→ │     SIT      │ ────────────────→ │     PROD     │
│  (No Gate)  │  (Tech Lead Only)  │  (2 Approvers)  (Business Owner)    │  (Zero DT)   │
└─────────────┘                    └──────────────┘                    └──────────────┘
     ▲                                    ▲                                   ▲
     │                                    │                                   │
  Develop &                            Test &                           Live Traffic
  Test Features                      Validate                           & Operations
     │                                    │                                   │
     └────────────── Feedback Loop ──────┘                                   │
                                         └────── Feedback/Rollback ────────┘
```

### 2.2 Promotion States

1. **Development Phase (DEV)**: Active development, feature branches, continuous testing
2. **Integration Phase (SIT)**: Code merged to release branch, full integration testing
3. **Staging Phase (PROD)**: Final validation, cutover preparation, go-live
4. **Live Phase (PROD)**: Monitoring and operations

---

## 3. Prerequisites & Requirements

### 3.1 Pre-Promotion Testing Checklist

#### Unit Tests
- [ ] All unit tests passing (coverage >= 80%)
- [ ] Code review approved by team lead
- [ ] No critical or high severity SonarQube findings
- [ ] No security vulnerabilities identified

#### Integration Tests
- [ ] Integration test suite passing in DEV
- [ ] API contracts validated
- [ ] Database migrations tested
- [ ] State machine transitions verified

#### Functional Testing
- [ ] Manual smoke tests completed
- [ ] User acceptance criteria met
- [ ] End-to-end workflows validated
- [ ] Error handling verified

### 3.2 Approval Requirements

#### DEV to SIT Promotion
- **Approver**: Tech Lead
- **Approval Duration**: Within 24 hours
- **Required Documentation**: PR description, test results link
- **Notification**: Slack notification to #devops-alerts

#### SIT to PROD Promotion
- **Approver 1**: Tech Lead (code quality owner)
- **Approver 2**: Infrastructure Lead (deployment owner)
- **Approval Duration**: Within 48 hours
- **Required Documentation**:
  - Change ticket (JIRA reference)
  - SIT test results
  - Performance baseline comparison
  - Rollback plan

### 3.3 Infrastructure Checks

- [ ] Terraform validation passes: `terraform validate`
- [ ] Terraform planning successful: `terraform plan`
- [ ] No resource drift detected
- [ ] VPC, security groups, IAM policies consistent
- [ ] Database capacity planning complete
- [ ] CloudWatch alarms configured

### 3.4 Pre-Promotion Environment Validation

```bash
# Verify AWS credentials and permissions
aws sts get-caller-identity

# Verify Terraform state
terraform state list

# Validate Terraform syntax
terraform validate

# Check AWS resource status
aws ec2 describe-instances --filters "Name=tag:Environment,Values=dev"
aws dynamodb list-tables
aws s3 ls
```

---

## 4. DEV to SIT Promotion Procedure

### 4.1 Pre-Promotion Steps

**Step 1: Create Release Branch**
```bash
git checkout main
git pull origin main
git checkout -b release/v$(date +%Y%m%d.%H%M%S)
```

**Step 2: Update Version Numbers**
- Update version in `terraform.tfvars`: `version = "2024.12.25.1"`
- Update version in Lambda `__init__.py` or `package.json`
- Commit: `git commit -m "chore: bump version for SIT promotion"`

**Step 3: Run Pre-Promotion Test Suite**
```bash
# Backend tests
pytest tests/ -v --cov=src --cov-report=html

# Frontend tests
npm test -- --coverage

# Integration tests
python -m pytest tests/integration/ -v

# Terraform validation
terraform validate
terraform plan -out=tfplan
```

**Step 4: Create Change Request in JIRA**
- Title: `Promote v2024.12.25.1 from DEV to SIT`
- Type: Deployment
- Components: S3, DynamoDB, Lambda
- Attachments: Test results, terraform plan output

### 4.2 Promotion Steps

**Step 5: Deploy to SIT Terraform Infrastructure**
```bash
# Switch to SIT environment
export AWS_PROFILE=bbws-sit
export ENVIRONMENT=sit

# Initialize Terraform for SIT
terraform init -backend-config="key=sit/terraform.tfstate"

# Review plan
terraform plan -var-file="sit.tfvars" -out=sit.tfplan

# Apply changes (requires approval)
terraform apply sit.tfplan
```

**Step 6: Deploy Microservices to SIT**
```bash
# Auth Lambda
cd 2_bbws_auth_lambda
terraform apply -var-file="../sit.tfvars"

# Product Lambda
cd ../2_bbws_product_lambda
terraform apply -var-file="../sit.tfvars"

# Order Lambda
cd ../2_bbws_order_lambda
terraform apply -var-file="../sit.tfvars"

# Continue for all Lambda microservices
```

**Step 7: Validate Data Synchronization**
- S3 bucket configuration replicated: `aws s3api get-bucket-versioning`
- DynamoDB table structure matches: `aws dynamodb describe-table --table-name [table-name]`
- Lambda environment variables correctly set
- API Gateway endpoints responding

**Step 8: Run Post-Promotion Health Checks**
```bash
# Check Lambda status
aws lambda list-functions --region af-south-1

# Verify DynamoDB tables online
aws dynamodb list-tables

# Test API endpoints
curl -X GET https://sit-api.bbws.co.za/health

# Check CloudWatch logs for errors
aws logs describe-log-groups --log-group-name-prefix "/aws/lambda/bbws-sit"
```

### 4.3 Approval Gate

**Step 9: Request Tech Lead Approval**
- Post SIT deployment summary to Slack #devops-alerts
- Message template:
  ```
  📦 PROMOTION REQUEST: DEV → SIT
  Version: v2024.12.25.1
  Change Ticket: JIRA-XXXX
  Deployed At: 2025-12-25 14:30:00 UTC+2
  Status: ✅ All tests passing

  Infrastructure Changes:
  - S3: [list changes]
  - DynamoDB: [list changes]
  - Lambda: [list functions updated]
  - API Gateway: [list endpoints updated]

  Approval Required: @tech-lead
  ```
- Wait for explicit approval comment in Slack
- Document approval timestamp

---

## 5. SIT to PROD Promotion Procedure

### 5.1 Pre-Promotion SIT Validation

**Step 1: SIT Smoke Testing (See Section 7)**
- All smoke tests passing
- Performance baselines met
- No critical alerts in CloudWatch
- Error rates within acceptable range

**Step 2: Create PROD Change Ticket**
- JIRA Ticket Type: "Production Deployment"
- Required Fields:
  - Summary: `Promote v2024.12.25.1 from SIT to PROD`
  - Approval: Tech Lead, Infrastructure Lead, Business Owner
  - Risk Assessment: Low/Medium/High
  - Rollback Plan: Documented
  - Maintenance Window: Scheduled time
  - Change Window: 2-hour window for zero-downtime deployment

**Step 3: Pre-Production Validation**
```bash
# Compare SIT and PROD resource configurations
export AWS_PROFILE=bbws-sit
aws dynamodb describe-table --table-name products > sit_products_schema.json

export AWS_PROFILE=bbws-prod
aws dynamodb describe-table --table-name products > prod_products_schema.json

# Verify schema compatibility
diff sit_products_schema.json prod_products_schema.json

# Check PROD capacity
aws dynamodb describe-table --table-name products | grep -E "BillingMode|ProvisionedThroughput"
```

### 5.2 Zero-Downtime Promotion Steps

**Step 4: Blue-Green Deployment Setup**
```bash
# Create new resources in PROD with "-blue" suffix
terraform workspace new blue

# Deploy new version to blue environment
terraform apply -var-file="prod.tfvars" -var "deployment=blue"

# Route 10% of traffic to blue (canary)
aws apigateway update-stage \
  --rest-api-id [api-id] \
  --stage-name prod \
  --patch-operations op=replace,path=/canarySettings/percentTraffic,value=10
```

**Step 5: Canary Deployment Validation**
- Monitor blue environment for 15 minutes
- Verify error rates < 0.5%
- Check latency p95 < baseline + 10%
- Validate business metrics (orders, conversions)
- If issues: immediately rollback canary to 0%

**Step 6: Gradual Traffic Shift**
```bash
# Timeline: 60-minute gradual shift
# 0-15 min:  10% traffic to blue
# 15-30 min: 25% traffic to blue
# 30-45 min: 50% traffic to blue
# 45-60 min: 100% traffic to blue

# Each step: monitor for 15 minutes before next shift
```

**Step 7: Switch Green to Blue**
```bash
# Once all traffic on blue and stable:
terraform workspace select blue
terraform workspace delete green

# Rename blue to prod
aws lambda alias update-alias \
  --function-name bbws-product-lambda \
  --name prod \
  --routing-config AdditionalVersionWeight=0
```

**Step 8: Final Validation in PROD**
```bash
# Verify all Lambda functions
aws lambda list-functions | grep "bbws-prod"

# Check DynamoDB replication
aws dynamodb describe-global-secondary-indexes --table-name products

# Validate CloudFront distribution
aws cloudfront get-distribution-config --id [dist-id]

# Run PROD smoke tests
curl -X GET https://api.bbws.co.za/health
curl -X GET https://api.bbws.co.za/products/list
```

### 5.3 Post-Promotion Monitoring

**Step 9: Extended Monitoring Period (2 hours)**
- CloudWatch dashboard refreshed every 5 minutes
- Alert on any anomalies
- Team on standby for rollback
- Database replication lag < 1 second
- No transaction errors in DynamoDB

---

## 6. Approval Process

### 6.1 Approval Workflow

```
Promotion Request
       ↓
    ┌─────────────────────────────────┐
    │ DEV to SIT Approval (1 gate)    │
    │ Required: Tech Lead             │
    │ Duration: 24 hours max          │
    └─────────────────────────────────┘
       ↓ (Approved)
    Deploy to SIT
       ↓
    Run SIT Tests
       ↓
    ┌─────────────────────────────────┐
    │ SIT to PROD Approval (2 gates)  │
    │ Required: Tech Lead +           │
    │           Infrastructure Lead   │
    │ Duration: 48 hours max          │
    └─────────────────────────────────┘
       ↓ (Both Approved)
    Deploy to PROD
       ↓
    Extended Monitoring (2 hrs)
       ↓
    Promotion Complete
```

### 6.2 DEV → SIT Approval Process

1. **Submitter**: Creates JIRA ticket with test results
2. **Tech Lead**: Reviews code changes, test coverage, quality metrics
3. **Approval Criteria**:
   - Code review approved
   - Unit test coverage >= 80%
   - All integration tests passing
   - No critical SonarQube findings
   - PR description complete
4. **Approval Method**: Comment "APPROVED" in JIRA + Slack confirmation
5. **Escalation**: If not approved in 24 hours, escalate to Team Manager

### 6.3 SIT → PROD Approval Process

**First Approver: Tech Lead**
- Criteria: Code quality, test results, performance metrics
- Checklist:
  - [ ] SIT smoke tests all passing
  - [ ] Performance baselines met
  - [ ] No regressions from previous release
  - [ ] Security scanning complete
  - [ ] Rollback plan documented

**Second Approver: Infrastructure Lead**
- Criteria: Infrastructure readiness, capacity, compliance
- Checklist:
  - [ ] Terraform plan reviewed
  - [ ] Capacity planning adequate
  - [ ] Disaster recovery tested
  - [ ] Compliance requirements met
  - [ ] Monitoring and alerting in place

**Third Approver: Business Owner (for critical changes)**
- Criteria: Business impact, stakeholder communication
- Checklist:
  - [ ] Business requirements met
  - [ ] Customer communication plan
  - [ ] Maintenance window acceptable
  - [ ] Risk assessment acceptable

### 6.4 Approval Documentation

**Approval Record Template**:
```
Promotion: v2024.12.25.1 (DEV → SIT → PROD)
Date: 2025-12-25 14:00:00 UTC+2

SIT Approval:
- Tech Lead: Jane Doe (@jane.doe)
  Approved: 2025-12-25 15:30:00
  Comment: "Code quality excellent, all tests passing"

PROD Approval:
- Tech Lead: Jane Doe (@jane.doe)
  Approved: 2025-12-25 16:45:00
  Comment: "Performance baseline met, ready for PROD"

- Infrastructure Lead: John Smith (@john.smith)
  Approved: 2025-12-25 17:00:00
  Comment: "Infrastructure ready, capacity verified"
```

---

## 7. Smoke Testing Checklists

### 7.1 DEV Smoke Tests (Post-DEV Deployment)

**API Gateway & Lambda Endpoints**
```bash
# Auth Lambda
curl -X POST https://dev-api.bbws.co.za/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}'

# Product Lambda
curl -X GET https://dev-api.bbws.co.za/products/list?limit=10

# Order Lambda
curl -X POST https://dev-api.bbws.co.za/orders/create \
  -H "Authorization: Bearer [token]" \
  -d '{"items":[{"productId":"1","quantity":2}]}'
```

**DynamoDB Operations**
```bash
# Test write operation
aws dynamodb put-item \
  --table-name dev-products \
  --item '{"productId":{"S":"test-001"},"name":{"S":"Test Product"}}'

# Test read operation
aws dynamodb get-item \
  --table-name dev-products \
  --key '{"productId":{"S":"test-001"}}'

# Test query operation
aws dynamodb query \
  --table-name dev-products \
  --key-condition-expression "productId = :id" \
  --expression-attribute-values '{":id":{"S":"test-001"}}'
```

**S3 Operations**
```bash
# Test upload
aws s3 cp test-file.txt s3://dev-bbws-content/test/

# Test download
aws s3 cp s3://dev-bbws-content/test/test-file.txt ./

# Verify encryption
aws s3api head-object --bucket dev-bbws-content --key test/test-file.txt
```

### 7.2 SIT Smoke Tests (Post-SIT Deployment)

All tests from DEV plus:

**Integrated Workflows**
- [ ] Complete order creation flow (product → cart → order → payment)
- [ ] User registration and authentication
- [ ] Tenant provisioning and configuration
- [ ] Admin portal access and operations
- [ ] Report generation and export

**Performance & Load**
```bash
# Load test API gateway (100 concurrent requests)
ab -n 1000 -c 100 https://sit-api.bbws.co.za/products/list

# Monitor DynamoDB capacity
watch -n 5 'aws dynamodb describe-table --table-name sit-products | grep ConsumedWriteCapacityUnits'

# Check Lambda concurrent execution
aws lambda get-account-settings | grep ConcurrentExecutions
```

**Data Consistency**
- [ ] DynamoDB global secondary indexes responding
- [ ] S3 versioning and replication active
- [ ] CloudFront cache invalidation working
- [ ] Cross-region replication lag < 1 second

### 7.3 PROD Smoke Tests (Post-PROD Deployment)

All tests from SIT plus:

**Production-Specific Checks**
- [ ] SSL/TLS certificates valid (not self-signed)
- [ ] Custom domain routing correctly configured
- [ ] Firewall rules allow production traffic
- [ ] Rate limiting and throttling active
- [ ] Dead letter queues for failed transactions

**High-Volume Validations**
```bash
# Load test production (1000 concurrent over 5 minutes)
ab -n 10000 -c 1000 -t 300 https://api.bbws.co.za/health

# Monitor error rates
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Errors \
  --start-time $(date -u -d '5 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60 \
  --statistics Average

# Check transaction success rate
aws logs filter-log-events \
  --log-group-name /aws/lambda/bbws-prod-order \
  --filter-pattern '{"$.status":"ERROR"}'
```

---

## 8. Go/No-Go Criteria & Decision Matrix

### 8.1 Go/No-Go Decision Framework

**Promotion proceeds (GO) if ALL of the following are true:**

#### Code Quality Gates
- Unit test coverage >= 80%
- Code review approved
- SonarQube quality gate PASSED
- No critical security vulnerabilities
- No high-severity code smells

#### Functional Testing Gates
- All smoke tests PASSED
- Integration tests PASSED (100% of test cases)
- Performance tests PASSED (p95 latency within baseline +10%)
- API contract tests PASSED
- Database migration tests PASSED

#### Infrastructure Gates
- Terraform plan review APPROVED
- No resource drift detected
- Capacity planning adequate
- Disaster recovery tested
- Monitoring and alerting verified

#### Approval Gates
- Tech Lead approval obtained
- Infrastructure Lead approval obtained (SIT→PROD only)
- Business Owner approval obtained (if required)
- Change ticket documented
- Risk assessment completed

### 8.2 No-Go Criteria (Halt Promotion)

**STOP and investigate if ANY of the following occur:**

1. **Critical Failures**
   - Any unit/integration test failure
   - Code coverage drops below 80%
   - Critical SonarQube findings (blocker)
   - Security vulnerability (CVSS > 7.0)

2. **Performance Degradation**
   - Latency p95 increases > 20% from baseline
   - Error rate exceeds 1%
   - Lambda throttling events > 0
   - DynamoDB throttling events > 0

3. **Infrastructure Issues**
   - Terraform validation failures
   - Resource quota exceeded
   - VPC network connectivity problems
   - IAM permission errors

4. **Approval Blockers**
   - Required approval(s) denied
   - Change ticket rejected
   - Compliance exceptions not approved
   - Risk assessment marked HIGH without mitigation

### 8.3 Decision Matrix

| Scenario | Coverage | Tests | Perf | Approval | Decision |
|----------|----------|-------|------|----------|----------|
| All green | >= 80% | PASS | OK | YES | **GO** |
| Coverage low | < 80% | PASS | OK | YES | **NO-GO** |
| Test fail | >= 80% | FAIL | OK | YES | **NO-GO** |
| Perf issue | >= 80% | PASS | BAD | YES | **NO-GO** |
| No approval | >= 80% | PASS | OK | NO | **NO-GO** |
| Medium risk | >= 80% | PASS | OK | YES | **GO** + extra monitoring |

---

## 9. Communication & Notification Plan

### 9.1 Stakeholder Groups & Notifications

**Development Team**
- Channel: Slack #dev-deployments
- Timing: At start of DEV deployment
- Content: Version number, what's being deployed, estimated duration

**QA Team**
- Channel: Slack #qa-testing + Email
- Timing: When promoted to SIT
- Content: Feature list, test scenarios, acceptance criteria

**Operations Team**
- Channel: Slack #devops-alerts + PagerDuty
- Timing: Before each promotion, every 15 min during deployment
- Content: Deployment status, metrics, any issues encountered

**Business Stakeholders**
- Channel: Email + Slack #business-updates
- Timing: Before SIT→PROD, after PROD deployment complete
- Content: Feature summary, business impact, customer communication

### 9.2 Slack Notification Templates

**DEV Deployment Started**
```
🚀 DEV DEPLOYMENT STARTED
Version: v2024.12.25.1
Components: Order Lambda, Product Lambda, DynamoDB tables
Estimated Duration: 15 minutes
Status: In Progress ⏳

@team-dev Deployment in progress, please avoid dev deployments for 15 minutes
```

**SIT Promotion Request**
```
📦 SIT PROMOTION REQUEST
Version: v2024.12.25.1
Test Results: ✅ All tests passing (847 tests)
Code Coverage: 85%
Ready for QA validation

Approval Required: @tech-lead
Please review and approve in JIRA: JIRA-XXXX
```

**PROD Promotion - Pre-Deployment**
```
⚠️  PROD DEPLOYMENT SCHEDULED
Version: v2024.12.25.1
Maintenance Window: 2025-12-25 20:00-22:00 UTC+2
Expected Downtime: Zero (Blue-Green deployment)

SIT Validation: ✅ Complete
Approvals: ✅ Complete (Tech Lead, Infra Lead)
Change Ticket: JIRA-YYYY

@on-call-team Please monitor closely
```

**PROD Deployment Complete**
```
✅ PROD DEPLOYMENT COMPLETE
Version: v2024.12.25.1
Deployment Duration: 45 minutes
All Services: Online ✅
Error Rate: < 0.1%
Performance: Baseline maintained

Full Release Notes: [link]
Customer Communication: [status]
```

### 9.3 Customer Communication

**Before PROD Deployment** (24 hours)
- Email to all customers
- In-app notification banner
- Status page update
- Content:
  - New features deployed
  - Maintenance window (if applicable)
  - Expected duration (even if zero-downtime)
  - Contact info for issues

**After PROD Deployment** (immediately)
- Email confirmation
- In-app success message
- Status page update to green
- Release notes link

### 9.4 Escalation Contacts

| Role | Name | Phone | Email | Slack |
|------|------|-------|-------|-------|
| Tech Lead | Jane Doe | +27-XXX-XXXX | jane.doe@bbws.co.za | @jane.doe |
| Infra Lead | John Smith | +27-XXX-XXXX | john.smith@bbws.co.za | @john.smith |
| On-Call | TBD | +27-XXX-XXXX | oncall@bbws.co.za | @on-call |
| Business Owner | Sarah Johnson | +27-XXX-XXXX | sarah@bbws.co.za | @sarah.johnson |

---

## 10. Rollback Decision & Procedures

### 10.1 When to Rollback

**Immediate Rollback if:**

1. **Critical System Failures** (Severity P1)
   - Services completely unavailable
   - Database corruption detected
   - Data loss occurring
   - Security breach detected
   - Customer data exposed

2. **Business Impact Failures** (Severity P1)
   - Unable to complete customer orders
   - Customer authentication broken
   - Payment processing failures
   - Critical feature non-functional

3. **Performance Degradation** (Severity P2)
   - Latency p95 > 2x baseline
   - Error rate > 5% sustained
   - Lambda throttling preventing transactions
   - Database query timeouts

4. **Data Consistency Issues** (Severity P2)
   - DynamoDB replication lag > 5 seconds
   - Data inconsistency between regions
   - Transaction state lost
   - Transaction rollback failures

### 10.2 Rollback Decision Tree

```
Critical Issue Detected?
    ├─ YES → P1 Severity?
    │        ├─ YES → IMMEDIATE ROLLBACK
    │        └─ NO → Proceed to P2 check
    │
    └─ NO → Monitor for 15 minutes
             ├─ Issue persists? → ROLLBACK
             └─ Issue resolves? → CONTINUE MONITORING

Error Rate High?
    ├─ > 5% → INVESTIGATE
    │        ├─ Root cause known? → FIX
    │        └─ Root cause unknown? → ROLLBACK
    │
    └─ < 5% → Continue

Performance Degraded?
    ├─ p95 Latency > 2x baseline → INVESTIGATE
    │        ├─ Spike temporary? → Continue
    │        └─ Persistent? → ROLLBACK
    │
    └─ Within baseline → Continue
```

### 10.3 Rollback Procedures

#### SIT Rollback (to previous DEV version)

**Step 1: Declare Rollback**
```bash
# Notify team
slack-notify "#devops-alerts" "🚨 ROLLING BACK SIT to previous version"

# Create incident
jira create-issue \
  --type Incident \
  --summary "SIT Rollback: v2024.12.25.1 → v2024.12.24.3"
```

**Step 2: Rollback Terraform & Lambda**
```bash
# Switch AWS profile to SIT
export AWS_PROFILE=bbws-sit

# Get previous version from git
git log --oneline | head -5
git checkout <previous-commit-hash>

# Rollback Terraform
terraform destroy -var-file="sit.tfvars" -auto-approve
terraform apply -var-file="sit.tfvars"

# Rollback Lambda functions
for lambda in auth product order; do
  aws lambda update-function-code \
    --function-name bbws-sit-${lambda}-lambda \
    --s3-bucket bbws-artifacts-sit \
    --s3-key bbws-${lambda}/v2024.12.24.3.zip
done
```

**Step 3: Validate Rollback**
```bash
# Run smoke tests
curl -X GET https://sit-api.bbws.co.za/health
curl -X GET https://sit-api.bbws.co.za/products/list

# Verify database state
aws dynamodb scan --table-name sit-products --limit 5

# Check logs for errors
aws logs tail /aws/lambda/bbws-sit-product-lambda --follow
```

**Step 4: Post-Rollback Notification**
```
✅ SIT ROLLBACK COMPLETE
Previous Version: v2024.12.24.3
All Services: Online ✅
Error Rate: < 0.1%

Incident Ticket: JIRA-YYYY
RCA Due: 2025-12-26 09:00:00
```

#### PROD Rollback (Blue-Green Revert)

**Step 1: Initiate Rollback**
```bash
# Switch traffic back to green (previous version)
aws apigateway update-stage \
  --rest-api-id [api-id] \
  --stage-name prod \
  --patch-operations op=replace,path=/canarySettings/percentTraffic,value=0

# Shift all traffic to green
aws lambda alias update-alias \
  --function-name bbws-product-lambda \
  --name prod \
  --routing-config AdditionalVersionWeight=0
```

**Step 2: Validate Green Environment**
```bash
# Verify traffic routing
curl -v https://api.bbws.co.za/health | grep X-Lambda-Version

# Monitor error rates (should drop)
watch -n 5 'aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Errors \
  --statistics Sum'

# Confirm database consistency
aws dynamodb describe-continuous-backups --table-name products
```

**Step 3: Cleanup Blue Environment**
```bash
# Keep blue for 24 hours (in case quick re-deployment needed)
# Then destroy
terraform workspace delete blue

# Cleanup artifacts
aws s3 rm s3://bbws-artifacts-prod/bbws-product/v2024.12.25.1.zip
```

**Step 4: RCA & Communication**
```
🚨 PROD ROLLBACK COMPLETED
Version Reverted: v2024.12.25.1 → v2024.12.24.3
Duration: 8 minutes
All Services: Restored ✅

What Happened: [brief summary]
Root Cause: [TBD - investigation ongoing]
RCA Due: 2025-12-26 17:00:00
Remediation: [planned fix]

Customer Communication: Sent
Next Steps: Dev team investigating failure mode
```

---

## Document Approval

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Tech Lead | Jane Doe | 2025-12-25 | _____ |
| Infrastructure Lead | John Smith | 2025-12-25 | _____ |
| Business Owner | Sarah Johnson | 2025-12-25 | _____ |

---

**Document Status**: FINAL - Ready for Implementation
**Last Updated**: 2025-12-25 18:00:00 UTC+2
**Next Review**: 2026-03-25 (Quarterly)
