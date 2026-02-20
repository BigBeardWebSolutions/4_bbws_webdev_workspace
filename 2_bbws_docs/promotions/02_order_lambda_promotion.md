# Promotion Plan: order_lambda

**Project**: 2_bbws_order_lambda
**Plan ID**: PROM-ORDER-002
**Created**: 2026-01-07
**Owner**: DevOps Engineer
**Status**: 📋 READY FOR EXECUTION

---

## Project Overview

| Attribute | Value |
|-----------|-------|
| **Project Type** | API Lambda Microservice (Event-driven) |
| **Purpose** | Order management for Customer Portal |
| **Current Status** | 95% complete, Production Ready |
| **Test Coverage** | 85% |
| **Handlers** | 11 (create, get, list, update, delete, cancel, fulfill, track, history, status, events) |
| **CI/CD Workflows** | 4 (deploy-dev, promote-sit, promote-prod, terraform-validate) |
| **Wave** | Wave 1 (Core API Services) |

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
├─ Deployment      (Jan 10, 11:00 AM)
├─ Validation      (Jan 10, 11:30 AM - 1:00 PM)
└─ Sign-off        (Jan 10, 4:00 PM)

PHASE 2: SIT VALIDATION (Jan 11-31)
├─ Integration Testing (Jan 11-14)
├─ Load Testing        (Jan 15-17)
├─ Event Flow Testing  (Jan 18-20)
├─ Security Scanning   (Jan 20-21)
└─ SIT Sign-off        (Jan 31)

PHASE 3: PROD PROMOTION (Feb 21, 2026)
├─ Pre-deployment  (Feb 17-20)
├─ Deployment      (Feb 21, 10:00 AM)
├─ Validation      (Feb 21, 10:30 AM - 12:00 PM)
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
- [ ] Verify DynamoDB table exists in SIT: `orders-sit`
- [ ] Confirm DynamoDB GSIs: `OrdersByCustomer`, `OrdersByStatus`, `OrdersByDate`
- [ ] Verify EventBridge rule for order events in SIT
- [ ] Confirm S3 bucket for order documents: `bbws-orders-sit`
- [ ] Check Lambda execution role in SIT
- [ ] Verify VPC configuration (if applicable)
- [ ] Confirm CloudWatch Log Groups created
- [ ] Verify Dead Letter Queue (DLQ) configured
- [ ] Check SNS topics for order notifications

#### Dependencies
- [ ] DynamoDB schemas promoted to SIT (CRITICAL dependency)
- [ ] S3 schemas promoted to SIT (dependency)
- [ ] Product Lambda promoted to SIT (dependency)
- [ ] API Gateway base path mapping ready
- [ ] Cognito user pool in SIT configured (if used)
- [ ] EventBridge event bus configured

### Deployment Steps (Jan 10, 11:00 AM)

#### Step 1: Terraform Workspace Switch
```bash
cd /Users/tebogotseka/Documents/agentic_work/2_bbws_order_lambda/terraform
terraform workspace select sit
terraform workspace list  # Verify 'sit' is selected
```

#### Step 2: Terraform Plan
```bash
AWS_PROFILE=Tebogo-sit terraform plan -out=sit.tfplan
# Review output carefully
# Verify no unexpected changes
# Confirm resource counts match expectations
# CRITICAL: Check EventBridge rules and DLQ configuration
```

#### Step 3: Manual Approval
- Review terraform plan output
- Verify no data-destructive operations
- Confirm EventBridge rule targets correct Lambda
- Verify DLQ retention settings
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
cd /Users/tebogotseka/Documents/agentic_work/2_bbws_order_lambda
./scripts/deploy-sit.sh
```

#### Step 6: Verify Deployment
```bash
# Check Lambda function exists
AWS_PROFILE=Tebogo-sit aws lambda list-functions | grep order

# Get function details
AWS_PROFILE=Tebogo-sit aws lambda get-function --function-name order-handler-sit

# Check environment variables
AWS_PROFILE=Tebogo-sit aws lambda get-function-configuration \
  --function-name order-handler-sit --query 'Environment'

# Verify EventBridge rule
AWS_PROFILE=Tebogo-sit aws events list-rules --name-prefix order

# Check DLQ configuration
AWS_PROFILE=Tebogo-sit aws sqs get-queue-attributes \
  --queue-url $(aws sqs get-queue-url --queue-name order-dlq-sit --query 'QueueUrl' --output text) \
  --attribute-names All
```

### Post-Deployment Validation (Jan 10, 11:30 AM - 1:00 PM)

#### Smoke Tests
```bash
# Test 1: Health Check
curl -X GET https://api.sit.kimmyai.io/v1.0/orders/health

# Test 2: List orders (should return empty or test data)
curl -X GET https://api.sit.kimmyai.io/v1.0/orders \
  -H "Authorization: Bearer ${SIT_TOKEN}"

# Test 3: Create order
curl -X POST https://api.sit.kimmyai.io/v1.0/orders \
  -H "Authorization: Bearer ${SIT_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "customer_id": "cust_test_001",
    "items": [
      {"product_id": "prod_001", "quantity": 2, "price": 29.99}
    ],
    "total": 59.98,
    "currency": "USD"
  }'

# Test 4: Get order by ID
curl -X GET https://api.sit.kimmyai.io/v1.0/orders/{order_id} \
  -H "Authorization: Bearer ${SIT_TOKEN}"

# Test 5: Update order status
curl -X PUT https://api.sit.kimmyai.io/v1.0/orders/{order_id}/status \
  -H "Authorization: Bearer ${SIT_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "status": "processing"
  }'

# Test 6: Cancel order
curl -X POST https://api.sit.kimmyai.io/v1.0/orders/{order_id}/cancel \
  -H "Authorization: Bearer ${SIT_TOKEN}"

# Test 7: Track order
curl -X GET https://api.sit.kimmyai.io/v1.0/orders/{order_id}/track \
  -H "Authorization: Bearer ${SIT_TOKEN}"

# Test 8: Get order history
curl -X GET https://api.sit.kimmyai.io/v1.0/orders/{order_id}/history \
  -H "Authorization: Bearer ${SIT_TOKEN}"

# Test 9: Fulfill order
curl -X POST https://api.sit.kimmyai.io/v1.0/orders/{order_id}/fulfill \
  -H "Authorization: Bearer ${SIT_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "tracking_number": "TRACK123456",
    "carrier": "DHL"
  }'

# Test 10: Get orders by customer
curl -X GET https://api.sit.kimmyai.io/v1.0/orders?customer_id=cust_test_001 \
  -H "Authorization: Bearer ${SIT_TOKEN}"

# Test 11: Get orders by status
curl -X GET https://api.sit.kimmyai.io/v1.0/orders?status=processing \
  -H "Authorization: Bearer ${SIT_TOKEN}"
```

#### Event Flow Validation
```bash
# Verify EventBridge event publication
AWS_PROFILE=Tebogo-sit aws events put-events --entries file://test-order-event.json

# Check CloudWatch Logs for event processing
AWS_PROFILE=Tebogo-sit aws logs tail /aws/lambda/order-handler-sit --follow --filter-pattern "EVENT"

# Verify order status change triggers event
# Create order → Check EventBridge metrics → Verify downstream consumers receive event
```

#### Monitoring Checks
- [ ] Check CloudWatch Logs for errors
  ```bash
  AWS_PROFILE=Tebogo-sit aws logs tail /aws/lambda/order-handler-sit --follow
  ```
- [ ] Verify CloudWatch Metrics (Invocations, Errors, Duration)
- [ ] Check X-Ray traces (if enabled)
- [ ] Verify alarms not triggered
- [ ] Review Lambda concurrent executions
- [ ] Check DLQ for failed messages (should be 0)
- [ ] Verify EventBridge rule invocation count

#### Integration Tests
- [ ] Run automated integration test suite
  ```bash
  cd tests/integration
  pytest test_order_api.py --env=sit -v
  ```
- [ ] Verify all 11 handlers (create, get, list, update, delete, cancel, fulfill, track, history, status, events)
- [ ] Test error handling scenarios
- [ ] Verify authorization/authentication
- [ ] Test rate limiting (if configured)
- [ ] Test idempotency for duplicate requests
- [ ] Verify event-driven workflows

---

## Phase 2: SIT Validation (Jan 11-31)

### Week 1: Integration Testing (Jan 11-14)
- [ ] Test with product_lambda integration
- [ ] Test with campaigns_lambda integration
- [ ] Test order creation → product inventory update flow
- [ ] End-to-end order workflow testing (create → process → fulfill → complete)
- [ ] Cross-service transaction testing
- [ ] Database integrity verification
- [ ] Event propagation testing (order events trigger notifications)
- [ ] Verify GSI queries (by customer, by status, by date)

### Week 2: Load Testing (Jan 15-17)
- [ ] Configure load testing tool (JMeter/k6)
- [ ] Run load test: 200 req/sec for 15 minutes (higher load for order service)
- [ ] Run stress test: Gradual increase to failure point
- [ ] Test concurrent order creation (race conditions)
- [ ] Monitor Lambda concurrency and throttling
- [ ] Verify auto-scaling behavior
- [ ] Test DynamoDB read/write capacity (on-demand scaling)
- [ ] Monitor EventBridge throttling
- [ ] Document performance metrics

### Week 3: Event Flow Testing (Jan 18-20)
- [ ] Test order status change events
- [ ] Verify event routing to correct consumers
- [ ] Test event replay scenarios
- [ ] Verify DLQ handling for failed events
- [ ] Test exponential backoff retry logic
- [ ] Validate event idempotency
- [ ] Test EventBridge rule filtering
- [ ] Verify SNS notification delivery

### Week 4: Security & Compliance (Jan 20-21)
- [ ] Run OWASP ZAP security scan
- [ ] SQL injection testing (DynamoDB query parameters)
- [ ] XSS vulnerability testing
- [ ] Authentication bypass testing
- [ ] Authorization matrix validation (customer can only access own orders)
- [ ] Data encryption verification (in-transit, at-rest)
- [ ] PCI compliance review for payment data handling
- [ ] Test PII data masking in logs

### Week 5: Final Validation (Jan 27-31)
- [ ] Re-run full test suite
- [ ] UAT with business stakeholders
- [ ] Performance benchmarking
- [ ] Cost analysis (Lambda invocations, DynamoDB, EventBridge, data transfer)
- [ ] Verify order processing SLA (<2s for create, <1s for status updates)
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
- [ ] Event replay procedure documented
- [ ] DLQ monitoring alerts configured

#### PROD Environment Verification
- [ ] AWS SSO login to PROD account (093646564004)
- [ ] Verify AWS profile: `AWS_PROFILE=Tebogo-prod aws sts get-caller-identity`
- [ ] Confirm PROD region: af-south-1 (primary)
- [ ] Verify failover region: eu-west-1
- [ ] Verify Route53 hosted zone for `api.kimmyai.io`
- [ ] Check SSL certificate in ACM for `api.kimmyai.io`
- [ ] Verify multi-region DR setup (af-south-1 primary, eu-west-1 failover)
- [ ] Confirm DynamoDB cross-region replication configured
- [ ] Verify EventBridge cross-region replication

#### Change Management
- [ ] Change request submitted and approved
- [ ] Maintenance window scheduled (if required)
- [ ] Customer notification sent (if applicable)
- [ ] Rollback team on standby
- [ ] Communication channels ready (Slack, email)
- [ ] Incident response team briefed

#### Data Migration
- [ ] Backup current PROD data (if any)
- [ ] Data migration script tested in SIT
- [ ] Data validation queries prepared
- [ ] Point-in-time recovery enabled on DynamoDB
- [ ] Verify hourly DynamoDB backups configured
- [ ] Test restore procedure from backup

### Deployment Steps (Feb 21, 10:00 AM)

#### Step 1: Pre-deployment Verification
```bash
# Verify SIT is stable
curl -X GET https://api.sit.kimmyai.io/v1.0/orders/health

# Verify PROD access
AWS_PROFILE=Tebogo-prod aws sts get-caller-identity

# Create deployment snapshot
AWS_PROFILE=Tebogo-prod aws lambda get-function \
  --function-name order-handler-prod > pre-deployment-snapshot.json

# Backup DynamoDB table
AWS_PROFILE=Tebogo-prod aws dynamodb create-backup \
  --table-name orders-prod \
  --backup-name orders-prod-pre-deployment-$(date +%Y%m%d-%H%M%S)
```

#### Step 2: Terraform Workspace Switch
```bash
cd /Users/tebogotseka/Documents/agentic_work/2_bbws_order_lambda/terraform
terraform workspace select prod
terraform workspace list  # Verify 'prod' is selected
```

#### Step 3: Terraform Plan (Production)
```bash
AWS_PROFILE=Tebogo-prod terraform plan -out=prod.tfplan
# CRITICAL: Review output line by line
# Verify NO data destruction
# Confirm resource modifications are expected
# Verify EventBridge rules target correct Lambda
# Confirm DLQ configuration
# Verify cross-region replication settings
```

#### Step 4: Final Approval
- Review terraform plan with Product Owner
- Confirm change request approved
- Verify rollback team ready
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
  --function-name order-handler-prod \
  --name live \
  --routing-config AdditionalVersionWeights={"$LATEST"=0.1}

# Monitor for 15 minutes
# If stable, increase to 50%
AWS_PROFILE=Tebogo-prod aws lambda update-alias \
  --function-name order-handler-prod \
  --name live \
  --routing-config AdditionalVersionWeights={"$LATEST"=0.5}

# Monitor for 30 minutes
# If stable, shift to 100%
AWS_PROFILE=Tebogo-prod aws lambda update-alias \
  --function-name order-handler-prod \
  --name live \
  --function-version $LATEST
```

### Post-Deployment Validation (Feb 21, 10:30 AM - 12:00 PM)

#### Critical Checks
- [ ] Health endpoint responding
- [ ] All 11 Lambda handlers operational
- [ ] No error spikes in CloudWatch
- [ ] Response times within SLA (<2s create, <1s status, <500ms read)
- [ ] No customer-reported issues
- [ ] Database connections stable
- [ ] API Gateway throttling not triggered
- [ ] EventBridge rule firing correctly
- [ ] DLQ empty (no failed messages)
- [ ] SNS notifications delivering

#### Production Monitoring (First 24 Hours)
- [ ] Monitor every 30 minutes for first 6 hours
- [ ] Check error rates hourly
- [ ] Review CloudWatch alarms
- [ ] Monitor Lambda concurrency
- [ ] Track DynamoDB read/write capacity units
- [ ] Monitor EventBridge invocation count
- [ ] Check DLQ depth
- [ ] Verify backup jobs running
- [ ] Monitor cross-region replication lag

#### Production Monitoring (First Week)
- [ ] Daily health checks
- [ ] Weekly performance review
- [ ] Cost monitoring (Lambda, API Gateway, DynamoDB, EventBridge, S3)
- [ ] User feedback collection
- [ ] Incident tracking
- [ ] Order processing metrics (completion rate, average processing time)
- [ ] Event delivery metrics (success rate, retry count)

---

## Rollback Procedures

### SIT Rollback
```bash
# Revert to previous version
cd /Users/tebogotseka/Documents/agentic_work/2_bbws_order_lambda
git checkout <previous-tag>
gh workflow run promote-sit.yml --ref <previous-tag>
```

### PROD Rollback (CRITICAL)
```bash
# Option 1: Instant alias switch (recommended for Lambda)
AWS_PROFILE=Tebogo-prod aws lambda update-alias \
  --function-name order-handler-prod \
  --name live \
  --function-version <previous-version>

# Option 2: Full terraform revert
terraform workspace select prod
terraform apply -target=module.order_lambda -var="version=<previous>"

# Option 3: GitHub Actions rollback
gh workflow run rollback-prod.yml --ref <previous-tag>

# Option 4: DynamoDB restore (if data corruption)
AWS_PROFILE=Tebogo-prod aws dynamodb restore-table-from-backup \
  --target-table-name orders-prod-restored \
  --backup-arn <backup-arn>
```

### Rollback Triggers
- Error rate > 5%
- Response time p95 > 3 seconds for create operations
- Response time p95 > 2 seconds for status updates
- Any data corruption detected
- Critical functionality broken (cannot create/process orders)
- Customer escalation
- EventBridge rule misfiring
- DLQ depth > 10 messages
- Order processing failure rate > 1%

---

## Success Criteria

### SIT Success
- [ ] Deployment completed without errors
- [ ] All smoke tests passing
- [ ] Integration tests passing (100%)
- [ ] Event flow tests passing (100%)
- [ ] No critical or high severity bugs
- [ ] Performance baseline established
- [ ] Monitoring dashboards configured
- [ ] All 11 handlers functional
- [ ] EventBridge integration validated

### PROD Success
- [ ] Zero-downtime deployment
- [ ] All health checks green
- [ ] Error rate < 0.1%
- [ ] Response time p95 < 2s (create), < 1s (status), < 500ms (read)
- [ ] No customer-impacting issues
- [ ] 72-hour soak period clean
- [ ] Event delivery success rate > 99.9%
- [ ] DLQ empty
- [ ] Cross-region replication functioning
- [ ] Product Owner sign-off

---

## Monitoring & Alerts

### CloudWatch Alarms
| Alarm | Threshold | Action |
|-------|-----------|--------|
| High Error Rate | > 5% errors | SNS alert to DevOps |
| High Duration (Create) | p95 > 3s | SNS alert to DevOps |
| High Duration (Read) | p95 > 1s | SNS alert to DevOps |
| Throttling | > 10 throttles/min | SNS alert + auto-scale |
| Dead Letter Queue | > 5 messages | SNS alert to DevOps (CRITICAL) |
| EventBridge Failures | > 1% failure rate | SNS alert to DevOps |
| Order Processing Failures | > 1% failures | SNS alert to DevOps |
| DynamoDB Throttling | > 0 throttled requests | SNS alert to DevOps |

### CloudWatch Dashboards
- Create: `order-lambda-sit-dashboard`
- Create: `order-lambda-prod-dashboard`
- Widgets: Invocations, Errors, Duration, Throttles, Concurrent Executions, DLQ Depth, EventBridge Metrics, Order Processing Metrics

### X-Ray Tracing
- [ ] Enable X-Ray for all handlers
- [ ] Create service map
- [ ] Monitor trace analytics
- [ ] Alert on anomalies

---

## Contacts & Escalation

| Role | Contact | Availability |
|------|---------|--------------|
| DevOps Engineer | TBD | Primary deployer |
| Tech Lead | TBD | Approval & escalation |
| Product Owner | TBD | Final sign-off |
| On-Call SRE | TBD | 24/7 incident response |
| DBA | TBD | Database issues |
| Event Architect | TBD | EventBridge issues |

---

## Documentation

### Deployment Artifacts
- [ ] Deployment runbook (this document)
- [ ] Terraform plan outputs (sit.tfplan, prod.tfplan)
- [ ] Test results (unit, integration, load, event flow)
- [ ] Performance benchmarks
- [ ] Security scan reports
- [ ] Event flow diagrams
- [ ] DLQ handling procedures

### Post-Deployment
- [ ] Deployment retrospective notes
- [ ] Lessons learned document
- [ ] Updated architecture diagrams (including EventBridge flows)
- [ ] Updated API documentation
- [ ] Incident reports (if any)
- [ ] Event schema documentation
- [ ] DynamoDB GSI usage patterns

---

## Change Log

| Date | Phase | Status | Notes |
|------|-------|--------|-------|
| 2026-01-07 | Planning | 📋 Complete | Promotion plan created |
| 2026-01-10 | SIT Deploy | ⏳ Scheduled | Target deployment (Wave 1) |
| 2026-02-21 | PROD Deploy | 🔵 Planned | Target deployment (Wave 1) |

---

**Next Steps:**
1. Review and approve this plan
2. Complete pre-deployment checklist
3. Coordinate with campaigns_lambda and product_lambda deployment (Wave 1)
4. Schedule SIT deployment for Jan 10 (after campaigns_lambda)
5. Execute deployment following this plan

**Plan Status:** 📋 READY FOR REVIEW
**Approval Required By:** Tech Lead, DevOps Lead, Event Architect
**Wave:** Wave 1 (Core API Services)
**Dependencies:** DynamoDB schemas, S3 schemas, product_lambda
