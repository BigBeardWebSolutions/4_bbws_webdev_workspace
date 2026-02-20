# Promotion Plan: product_lambda

**Project**: 2_bbws_product_lambda
**Plan ID**: PROM-PROD-003
**Created**: 2026-01-07
**Owner**: DevOps Engineer
**Status**: 📋 READY FOR EXECUTION

---

## Project Overview

| Attribute | Value |
|-----------|-------|
| **Project Type** | API Lambda Microservice |
| **Purpose** | Product catalog management for Customer Portal |
| **Current Status** | 95% complete, Production Ready |
| **Test Coverage** | 88% |
| **Handlers** | 5 (create, get, list, update, delete) |
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
├─ Deployment      (Jan 10, 10:30 AM)
├─ Validation      (Jan 10, 11:00 AM - 12:30 PM)
└─ Sign-off        (Jan 10, 4:00 PM)

PHASE 2: SIT VALIDATION (Jan 11-31)
├─ Integration Testing (Jan 11-14)
├─ Load Testing        (Jan 15-17)
├─ Catalog Testing     (Jan 18-19)
├─ Security Scanning   (Jan 20-21)
└─ SIT Sign-off        (Jan 31)

PHASE 3: PROD PROMOTION (Feb 21, 2026)
├─ Pre-deployment  (Feb 17-20)
├─ Deployment      (Feb 21, 9:30 AM)
├─ Validation      (Feb 21, 10:00 AM - 11:30 AM)
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
- [ ] Verify DynamoDB table exists in SIT: `products-sit`
- [ ] Confirm DynamoDB GSIs: `ProductsByCategory`, `ProductsByPriceRange`, `ProductsByAvailability`
- [ ] Confirm S3 bucket for product images: `bbws-product-images-sit`
- [ ] Verify CloudFront distribution for image delivery
- [ ] Check Lambda execution role in SIT
- [ ] Verify VPC configuration (if applicable)
- [ ] Confirm CloudWatch Log Groups created

#### Dependencies
- [ ] DynamoDB schemas promoted to SIT (CRITICAL dependency)
- [ ] S3 schemas promoted to SIT (dependency)
- [ ] API Gateway base path mapping ready
- [ ] Cognito user pool in SIT configured (if used)

### Deployment Steps (Jan 10, 10:30 AM)

#### Step 1: Terraform Workspace Switch
```bash
cd /Users/tebogotseka/Documents/agentic_work/2_bbws_product_lambda/terraform
terraform workspace select sit
terraform workspace list  # Verify 'sit' is selected
```

#### Step 2: Terraform Plan
```bash
AWS_PROFILE=Tebogo-sit terraform plan -out=sit.tfplan
# Review output carefully
# Verify no unexpected changes
# Confirm resource counts match expectations
# CRITICAL: Check S3 bucket policies and CloudFront configuration
```

#### Step 3: Manual Approval
- Review terraform plan output
- Verify no data-destructive operations
- Confirm S3 bucket public access blocked
- Verify CloudFront caching policies
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
cd /Users/tebogotseka/Documents/agentic_work/2_bbws_product_lambda
./scripts/deploy-sit.sh
```

#### Step 6: Verify Deployment
```bash
# Check Lambda function exists
AWS_PROFILE=Tebogo-sit aws lambda list-functions | grep product

# Get function details
AWS_PROFILE=Tebogo-sit aws lambda get-function --function-name product-handler-sit

# Check environment variables
AWS_PROFILE=Tebogo-sit aws lambda get-function-configuration \
  --function-name product-handler-sit --query 'Environment'

# Verify S3 bucket configuration
AWS_PROFILE=Tebogo-sit aws s3api get-bucket-policy --bucket bbws-product-images-sit

# Check CloudFront distribution
AWS_PROFILE=Tebogo-sit aws cloudfront list-distributions \
  --query "DistributionList.Items[?contains(Origins.Items[0].DomainName, 'product-images-sit')]"
```

### Post-Deployment Validation (Jan 10, 11:00 AM - 12:30 PM)

#### Smoke Tests
```bash
# Test 1: Health Check
curl -X GET https://api.sit.kimmyai.io/v1.0/products/health

# Test 2: List products (should return empty or test data)
curl -X GET https://api.sit.kimmyai.io/v1.0/products \
  -H "Authorization: Bearer ${SIT_TOKEN}"

# Test 3: Create product
curl -X POST https://api.sit.kimmyai.io/v1.0/products \
  -H "Authorization: Bearer ${SIT_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "SIT Test Product",
    "description": "Test product for SIT validation",
    "category": "Electronics",
    "price": 299.99,
    "currency": "USD",
    "inventory": 100,
    "sku": "TEST-SIT-001",
    "image_url": "https://images.sit.kimmyai.io/test-product.jpg"
  }'

# Test 4: Get product by ID
curl -X GET https://api.sit.kimmyai.io/v1.0/products/{product_id} \
  -H "Authorization: Bearer ${SIT_TOKEN}"

# Test 5: Update product
curl -X PUT https://api.sit.kimmyai.io/v1.0/products/{product_id} \
  -H "Authorization: Bearer ${SIT_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "price": 279.99,
    "inventory": 95
  }'

# Test 6: Delete product
curl -X DELETE https://api.sit.kimmyai.io/v1.0/products/{product_id} \
  -H "Authorization: Bearer ${SIT_TOKEN}"

# Test 7: Get products by category
curl -X GET "https://api.sit.kimmyai.io/v1.0/products?category=Electronics" \
  -H "Authorization: Bearer ${SIT_TOKEN}"

# Test 8: Get products by price range
curl -X GET "https://api.sit.kimmyai.io/v1.0/products?min_price=100&max_price=500" \
  -H "Authorization: Bearer ${SIT_TOKEN}"

# Test 9: Test image upload
curl -X POST https://api.sit.kimmyai.io/v1.0/products/{product_id}/image \
  -H "Authorization: Bearer ${SIT_TOKEN}" \
  -F "image=@test-image.jpg"

# Test 10: Verify CloudFront image delivery
curl -I https://images.sit.kimmyai.io/products/test-image.jpg
```

#### Monitoring Checks
- [ ] Check CloudWatch Logs for errors
  ```bash
  AWS_PROFILE=Tebogo-sit aws logs tail /aws/lambda/product-handler-sit --follow
  ```
- [ ] Verify CloudWatch Metrics (Invocations, Errors, Duration)
- [ ] Check X-Ray traces (if enabled)
- [ ] Verify alarms not triggered
- [ ] Review Lambda concurrent executions
- [ ] Monitor S3 request metrics
- [ ] Check CloudFront cache hit ratio

#### Integration Tests
- [ ] Run automated integration test suite
  ```bash
  cd tests/integration
  pytest test_product_api.py --env=sit -v
  ```
- [ ] Verify all 5 handlers (create, get, list, update, delete)
- [ ] Test error handling scenarios
- [ ] Verify authorization/authentication
- [ ] Test rate limiting (if configured)
- [ ] Test product search functionality
- [ ] Verify GSI queries (by category, price range, availability)
- [ ] Test image upload and retrieval

---

## Phase 2: SIT Validation (Jan 11-31)

### Week 1: Integration Testing (Jan 11-14)
- [ ] Test with order_lambda integration
- [ ] Test product inventory updates when orders created
- [ ] Test product availability checks
- [ ] End-to-end product catalog workflow testing
- [ ] Cross-service transaction testing
- [ ] Database integrity verification
- [ ] Verify GSI queries (by category, by price, by availability)
- [ ] Test product image lifecycle (upload, retrieve, delete)

### Week 2: Load Testing (Jan 15-17)
- [ ] Configure load testing tool (JMeter/k6)
- [ ] Run load test: 150 req/sec for 10 minutes
- [ ] Run stress test: Gradual increase to failure point
- [ ] Test concurrent product updates
- [ ] Monitor Lambda concurrency and throttling
- [ ] Verify auto-scaling behavior
- [ ] Test DynamoDB read/write capacity (on-demand scaling)
- [ ] Monitor CloudFront cache performance
- [ ] Test S3 request rate limits
- [ ] Document performance metrics

### Week 3: Catalog Testing (Jan 18-19)
- [ ] Test bulk product import
- [ ] Test bulk product update
- [ ] Test product search with complex filters
- [ ] Test pagination for large catalogs
- [ ] Verify product sorting (price, name, date)
- [ ] Test product recommendations (if implemented)
- [ ] Verify product variant handling
- [ ] Test product category hierarchy

### Week 4: Security & Compliance (Jan 20-21)
- [ ] Run OWASP ZAP security scan
- [ ] SQL injection testing (DynamoDB query parameters)
- [ ] XSS vulnerability testing
- [ ] Authentication bypass testing
- [ ] Authorization matrix validation
- [ ] Data encryption verification (in-transit, at-rest)
- [ ] Test S3 bucket access controls (no public access)
- [ ] Verify CloudFront signed URLs (if used)
- [ ] Test image file validation (prevent malicious uploads)

### Week 5: Final Validation (Jan 27-31)
- [ ] Re-run full test suite
- [ ] UAT with business stakeholders
- [ ] Performance benchmarking
- [ ] Cost analysis (Lambda invocations, DynamoDB, S3, CloudFront, data transfer)
- [ ] Verify product catalog SLA (<500ms for reads, <2s for writes)
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
- [ ] Product catalog backup procedure documented

#### PROD Environment Verification
- [ ] AWS SSO login to PROD account (093646564004)
- [ ] Verify AWS profile: `AWS_PROFILE=Tebogo-prod aws sts get-caller-identity`
- [ ] Confirm PROD region: af-south-1 (primary)
- [ ] Verify failover region: eu-west-1
- [ ] Verify Route53 hosted zone for `api.kimmyai.io`
- [ ] Check SSL certificate in ACM for `api.kimmyai.io`
- [ ] Verify multi-region DR setup (af-south-1 primary, eu-west-1 failover)
- [ ] Confirm DynamoDB cross-region replication configured
- [ ] Verify S3 cross-region replication for product images

#### Change Management
- [ ] Change request submitted and approved
- [ ] Maintenance window scheduled (if required)
- [ ] Customer notification sent (if applicable)
- [ ] Rollback team on standby
- [ ] Communication channels ready (Slack, email)
- [ ] Incident response team briefed

#### Data Migration
- [ ] Backup current PROD data (if any)
- [ ] Product catalog migration script tested in SIT
- [ ] Data validation queries prepared
- [ ] Point-in-time recovery enabled on DynamoDB
- [ ] Verify hourly DynamoDB backups configured
- [ ] Test restore procedure from backup
- [ ] Verify S3 versioning enabled for images

### Deployment Steps (Feb 21, 9:30 AM)

#### Step 1: Pre-deployment Verification
```bash
# Verify SIT is stable
curl -X GET https://api.sit.kimmyai.io/v1.0/products/health

# Verify PROD access
AWS_PROFILE=Tebogo-prod aws sts get-caller-identity

# Create deployment snapshot
AWS_PROFILE=Tebogo-prod aws lambda get-function \
  --function-name product-handler-prod > pre-deployment-snapshot.json

# Backup DynamoDB table
AWS_PROFILE=Tebogo-prod aws dynamodb create-backup \
  --table-name products-prod \
  --backup-name products-prod-pre-deployment-$(date +%Y%m%d-%H%M%S)

# Verify S3 versioning enabled
AWS_PROFILE=Tebogo-prod aws s3api get-bucket-versioning \
  --bucket bbws-product-images-prod
```

#### Step 2: Terraform Workspace Switch
```bash
cd /Users/tebogotseka/Documents/agentic_work/2_bbws_product_lambda/terraform
terraform workspace select prod
terraform workspace list  # Verify 'prod' is selected
```

#### Step 3: Terraform Plan (Production)
```bash
AWS_PROFILE=Tebogo-prod terraform plan -out=prod.tfplan
# CRITICAL: Review output line by line
# Verify NO data destruction
# Confirm resource modifications are expected
# Verify S3 bucket policies (no public access)
# Confirm CloudFront caching policies
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
  --function-name product-handler-prod \
  --name live \
  --routing-config AdditionalVersionWeights={"$LATEST"=0.1}

# Monitor for 15 minutes
# If stable, increase to 50%
AWS_PROFILE=Tebogo-prod aws lambda update-alias \
  --function-name product-handler-prod \
  --name live \
  --routing-config AdditionalVersionWeights={"$LATEST"=0.5}

# Monitor for 30 minutes
# If stable, shift to 100%
AWS_PROFILE=Tebogo-prod aws lambda update-alias \
  --function-name product-handler-prod \
  --name live \
  --function-version $LATEST
```

### Post-Deployment Validation (Feb 21, 10:00 AM - 11:30 AM)

#### Critical Checks
- [ ] Health endpoint responding
- [ ] All 5 Lambda handlers operational
- [ ] No error spikes in CloudWatch
- [ ] Response times within SLA (<500ms reads, <2s writes)
- [ ] No customer-reported issues
- [ ] Database connections stable
- [ ] API Gateway throttling not triggered
- [ ] S3 image delivery functioning
- [ ] CloudFront cache functioning (>80% hit ratio)

#### Production Monitoring (First 24 Hours)
- [ ] Monitor every 30 minutes for first 6 hours
- [ ] Check error rates hourly
- [ ] Review CloudWatch alarms
- [ ] Monitor Lambda concurrency
- [ ] Track DynamoDB read/write capacity units
- [ ] Monitor S3 request rates
- [ ] Check CloudFront cache hit ratio
- [ ] Verify backup jobs running
- [ ] Monitor cross-region replication lag

#### Production Monitoring (First Week)
- [ ] Daily health checks
- [ ] Weekly performance review
- [ ] Cost monitoring (Lambda, API Gateway, DynamoDB, S3, CloudFront, data transfer)
- [ ] User feedback collection
- [ ] Incident tracking
- [ ] Product catalog metrics (search performance, image load times)

---

## Rollback Procedures

### SIT Rollback
```bash
# Revert to previous version
cd /Users/tebogotseka/Documents/agentic_work/2_bbws_product_lambda
git checkout <previous-tag>
gh workflow run promote-sit.yml --ref <previous-tag>
```

### PROD Rollback (CRITICAL)
```bash
# Option 1: Instant alias switch (recommended for Lambda)
AWS_PROFILE=Tebogo-prod aws lambda update-alias \
  --function-name product-handler-prod \
  --name live \
  --function-version <previous-version>

# Option 2: Full terraform revert
terraform workspace select prod
terraform apply -target=module.product_lambda -var="version=<previous>"

# Option 3: GitHub Actions rollback
gh workflow run rollback-prod.yml --ref <previous-tag>

# Option 4: DynamoDB restore (if data corruption)
AWS_PROFILE=Tebogo-prod aws dynamodb restore-table-from-backup \
  --target-table-name products-prod-restored \
  --backup-arn <backup-arn>

# Option 5: S3 version restore (if image corruption)
AWS_PROFILE=Tebogo-prod aws s3api list-object-versions \
  --bucket bbws-product-images-prod \
  --prefix products/
# Restore specific version if needed
```

### Rollback Triggers
- Error rate > 5%
- Response time p95 > 3 seconds for writes
- Response time p95 > 1 second for reads
- Any data corruption detected
- Critical functionality broken (cannot create/update products)
- Customer escalation
- CloudFront cache poisoning
- S3 image delivery failures > 1%
- Product catalog unavailable

---

## Success Criteria

### SIT Success
- [ ] Deployment completed without errors
- [ ] All smoke tests passing
- [ ] Integration tests passing (100%)
- [ ] Catalog tests passing (100%)
- [ ] No critical or high severity bugs
- [ ] Performance baseline established
- [ ] Monitoring dashboards configured
- [ ] All 5 handlers functional
- [ ] S3 and CloudFront integration validated

### PROD Success
- [ ] Zero-downtime deployment
- [ ] All health checks green
- [ ] Error rate < 0.1%
- [ ] Response time p95 < 500ms (reads), < 2s (writes)
- [ ] No customer-impacting issues
- [ ] 72-hour soak period clean
- [ ] CloudFront cache hit ratio > 80%
- [ ] S3 image delivery success rate > 99.9%
- [ ] Cross-region replication functioning
- [ ] Product Owner sign-off

---

## Monitoring & Alerts

### CloudWatch Alarms
| Alarm | Threshold | Action |
|-------|-----------|--------|
| High Error Rate | > 5% errors | SNS alert to DevOps |
| High Duration (Write) | p95 > 3s | SNS alert to DevOps |
| High Duration (Read) | p95 > 1s | SNS alert to DevOps |
| Throttling | > 10 throttles/min | SNS alert + auto-scale |
| DynamoDB Throttling | > 0 throttled requests | SNS alert to DevOps |
| S3 4xx Errors | > 1% error rate | SNS alert to DevOps |
| S3 5xx Errors | > 0.1% error rate | SNS alert to DevOps (CRITICAL) |
| CloudFront 5xx Errors | > 0.5% error rate | SNS alert to DevOps |
| CloudFront Cache Hit Ratio | < 70% | SNS alert to DevOps |

### CloudWatch Dashboards
- Create: `product-lambda-sit-dashboard`
- Create: `product-lambda-prod-dashboard`
- Widgets: Invocations, Errors, Duration, Throttles, Concurrent Executions, DynamoDB Metrics, S3 Metrics, CloudFront Metrics

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
| CDN Specialist | TBD | CloudFront issues |

---

## Documentation

### Deployment Artifacts
- [ ] Deployment runbook (this document)
- [ ] Terraform plan outputs (sit.tfplan, prod.tfplan)
- [ ] Test results (unit, integration, load, catalog)
- [ ] Performance benchmarks
- [ ] Security scan reports
- [ ] S3 bucket policies
- [ ] CloudFront distribution configuration

### Post-Deployment
- [ ] Deployment retrospective notes
- [ ] Lessons learned document
- [ ] Updated architecture diagrams (including S3 and CloudFront)
- [ ] Updated API documentation
- [ ] Incident reports (if any)
- [ ] Product catalog schema documentation
- [ ] DynamoDB GSI usage patterns
- [ ] Image storage and delivery patterns

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
3. Coordinate with campaigns_lambda and order_lambda deployment (Wave 1)
4. Schedule SIT deployment for Jan 10 (between campaigns and order)
5. Execute deployment following this plan

**Plan Status:** 📋 READY FOR REVIEW
**Approval Required By:** Tech Lead, DevOps Lead, CDN Specialist
**Wave:** Wave 1 (Core API Services)
**Dependencies:** DynamoDB schemas, S3 schemas
