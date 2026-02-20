# Promotion Plan: s3_schemas

**Project**: 2_1_bbws_s3_schemas
**Plan ID**: PROM-S3-005
**Created**: 2026-01-07
**Owner**: DevOps Engineer
**Status**: 📋 READY FOR EXECUTION

---

## Project Overview

| Attribute | Value |
|-----------|-------|
| **Project Type** | Infrastructure (S3 Buckets + Email Templates) |
| **Purpose** | Centralized S3 bucket definitions and email templates for BBWS platform |
| **Current Status** | 100% complete, Production Ready |
| **Buckets** | 6 (templates, orders, products, tenant-assets, backups, logs) |
| **Email Templates** | 12 (welcome, order-confirmation, password-reset, etc.) |
| **CI/CD Workflows** | 4 (deploy-dev, promote-sit, promote-prod, terraform-validate) |
| **Wave** | Wave 2 (Infrastructure Foundation) |

---

## Environments

| Environment | AWS Account | Region | Domain | Status |
|-------------|-------------|--------|--------|--------|
| **DEV** | 536580886816 | eu-west-1 | N/A | ✅ Deployed |
| **SIT** | 815856636111 | eu-west-1 | N/A | ⏳ Target |
| **PROD** | 093646564004 | af-south-1 (primary) | N/A | 🔵 Planned |
| **DR** | 093646564004 | eu-west-1 (failover) | N/A | 🔵 Planned |

---

## Promotion Timeline

```
PHASE 1: SIT PROMOTION (Jan 13, 2026)
├─ Pre-deployment  (Jan 11-12)
├─ Deployment      (Jan 13, 10:00 AM)
├─ Validation      (Jan 13, 10:30 AM - 12:00 PM)
└─ Sign-off        (Jan 13, 4:00 PM)

PHASE 2: SIT VALIDATION (Jan 14-31)
├─ Integration Testing (Jan 14-17)
├─ Versioning Test     (Jan 18-19)
├─ Replication Test    (Jan 20-21)
├─ Security Scanning   (Jan 22-24)
└─ SIT Sign-off        (Jan 31)

PHASE 3: PROD PROMOTION (Feb 24, 2026)
├─ Pre-deployment  (Feb 20-23)
├─ Deployment      (Feb 24, 9:00 AM)
├─ DR Setup        (Feb 24, 10:30 AM)
├─ Validation      (Feb 24, 11:30 AM - 1:30 PM)
└─ Sign-off        (Feb 27, 4:00 PM)
```

---

## Phase 1: SIT Promotion

### Pre-Deployment Checklist (Jan 11-12)

#### Environment Verification
- [ ] AWS SSO login to SIT account (815856636111)
- [ ] Verify AWS profile: `AWS_PROFILE=Tebogo-sit aws sts get-caller-identity`
- [ ] Confirm SIT region: eu-west-1
- [ ] Verify IAM permissions for S3 bucket creation
- [ ] Check KMS key for encryption available

#### Code Preparation
- [ ] Verify latest code in `main` branch
- [ ] Confirm all Terraform validations passing in DEV
- [ ] Review GitHub Actions workflows (promote-sit.yml)
- [ ] Tag release: `v1.0.0-sit`
- [ ] Create changelog for SIT release
- [ ] Document all email templates and their purposes
- [ ] Verify email templates are valid HTML

#### Infrastructure Planning
- [ ] Document all buckets to be created:
  - `bbws-templates-sit` (Email and document templates)
  - `bbws-orders-sit` (Order documents, invoices)
  - `bbws-product-images-sit` (Product images)
  - `bbws-tenant-assets-sit` (Tenant-specific files, logos)
  - `bbws-backups-sit` (Application backups)
  - `bbws-logs-sit` (Application and access logs)
- [ ] **CRITICAL**: Verify ALL buckets block public access
- [ ] Confirm versioning enabled on all buckets
- [ ] Verify encryption at rest configured (S3-KMS)
- [ ] Plan lifecycle policies (transition to IA, Glacier, expiration)
- [ ] Document bucket policies (least privilege)

#### Email Templates
- [ ] List all 12 email templates:
  - `welcome-email.html`
  - `order-confirmation.html`
  - `order-shipped.html`
  - `order-delivered.html`
  - `password-reset.html`
  - `password-changed.html`
  - `account-verification.html`
  - `invoice-generated.html`
  - `payment-received.html`
  - `payment-failed.html`
  - `subscription-renewal.html`
  - `account-suspended.html`
- [ ] Verify templates have correct variable placeholders
- [ ] Test templates render correctly

#### Dependencies
- [ ] No dependencies (foundation infrastructure)
- [ ] This is a dependency for Lambda services (campaigns, order, product)

### Deployment Steps (Jan 13, 10:00 AM)

#### Step 1: Terraform Workspace Switch
```bash
cd /Users/tebogotseka/Documents/agentic_work/2_1_bbws_s3_schemas/terraform
terraform workspace select sit
terraform workspace list  # Verify 'sit' is selected
```

#### Step 2: Terraform Plan
```bash
AWS_PROFILE=Tebogo-sit terraform plan -out=sit.tfplan
# CRITICAL REVIEW:
# - Verify 6 buckets will be created
# - Confirm ALL buckets have public access blocked
# - Verify versioning enabled
# - Confirm KMS encryption
# - Check lifecycle policies
# - Verify bucket policies (no public access)
# - Confirm CORS policies (if needed)
# - Verify no existing buckets will be destroyed
```

#### Step 3: Manual Approval
- Review terraform plan output line by line
- Verify no data-destructive operations
- **CRITICAL**: Confirm all buckets block public access
- Verify versioning enabled
- Confirm encryption at rest
- Verify lifecycle policies appropriate
- Get approval from Tech Lead and Security Lead
- Document approval in deployment log

#### Step 4: Terraform Apply
```bash
AWS_PROFILE=Tebogo-sit terraform apply sit.tfplan
# Monitor output carefully
# Verify each bucket creation successful
# Note: Bucket creation is instant
```

#### Step 5: Upload Email Templates
```bash
# Upload all email templates to templates bucket
cd /Users/tebogotseka/Documents/agentic_work/2_1_bbws_s3_schemas/templates/email

for template in *.html; do
  AWS_PROFILE=Tebogo-sit aws s3 cp $template \
    s3://bbws-templates-sit/email/$template \
    --content-type "text/html" \
    --metadata "version=1.0.0,environment=sit"
  echo "Uploaded: $template"
done

# Verify uploads
AWS_PROFILE=Tebogo-sit aws s3 ls s3://bbws-templates-sit/email/
```

#### Step 6: Post-Creation Verification
```bash
# Verify all buckets created
AWS_PROFILE=Tebogo-sit aws s3 ls | grep bbws

# Check each bucket configuration
for bucket in bbws-templates-sit bbws-orders-sit bbws-product-images-sit bbws-tenant-assets-sit bbws-backups-sit bbws-logs-sit; do
  echo "Verifying bucket: $bucket"

  # Check public access block
  AWS_PROFILE=Tebogo-sit aws s3api get-public-access-block --bucket $bucket

  # Check versioning
  AWS_PROFILE=Tebogo-sit aws s3api get-bucket-versioning --bucket $bucket

  # Check encryption
  AWS_PROFILE=Tebogo-sit aws s3api get-bucket-encryption --bucket $bucket

  # Check lifecycle policy
  AWS_PROFILE=Tebogo-sit aws s3api get-bucket-lifecycle-configuration --bucket $bucket || echo "No lifecycle policy"
done
```

### Post-Deployment Validation (Jan 13, 10:30 AM - 12:00 PM)

#### Bucket Validation
```bash
# Test 1: Verify bucket exists and accessible
for bucket in bbws-templates-sit bbws-orders-sit bbws-product-images-sit bbws-tenant-assets-sit bbws-backups-sit bbws-logs-sit; do
  AWS_PROFILE=Tebogo-sit aws s3 ls s3://$bucket/ && echo "$bucket: OK" || echo "$bucket: FAILED"
done

# Test 2: Verify public access blocked
for bucket in bbws-templates-sit bbws-orders-sit bbws-product-images-sit bbws-tenant-assets-sit bbws-backups-sit bbws-logs-sit; do
  RESULT=$(AWS_PROFILE=Tebogo-sit aws s3api get-public-access-block --bucket $bucket --query 'PublicAccessBlockConfiguration.BlockPublicAcls' --output text)
  if [ "$RESULT" != "True" ]; then
    echo "ERROR: $bucket allows public access!"
    exit 1
  fi
  echo "$bucket: Public access blocked ✓"
done

# Test 3: Verify versioning enabled
for bucket in bbws-templates-sit bbws-orders-sit bbws-product-images-sit bbws-tenant-assets-sit bbws-backups-sit bbws-logs-sit; do
  STATUS=$(AWS_PROFILE=Tebogo-sit aws s3api get-bucket-versioning --bucket $bucket --query 'Status' --output text)
  if [ "$STATUS" != "Enabled" ]; then
    echo "ERROR: $bucket versioning not enabled!"
    exit 1
  fi
  echo "$bucket: Versioning enabled ✓"
done

# Test 4: Write test file
echo "SIT Test File" > test-file.txt
AWS_PROFILE=Tebogo-sit aws s3 cp test-file.txt s3://bbws-templates-sit/test/test-file.txt

# Test 5: Read test file
AWS_PROFILE=Tebogo-sit aws s3 cp s3://bbws-templates-sit/test/test-file.txt test-file-downloaded.txt
cat test-file-downloaded.txt

# Test 6: Verify versioning (upload same file twice)
echo "SIT Test File v2" > test-file.txt
AWS_PROFILE=Tebogo-sit aws s3 cp test-file.txt s3://bbws-templates-sit/test/test-file.txt

# List versions
AWS_PROFILE=Tebogo-sit aws s3api list-object-versions \
  --bucket bbws-templates-sit \
  --prefix test/test-file.txt

# Test 7: Delete test file (creates delete marker)
AWS_PROFILE=Tebogo-sit aws s3 rm s3://bbws-templates-sit/test/test-file.txt
rm test-file.txt test-file-downloaded.txt
```

#### Email Template Validation
```bash
# Verify all 12 templates uploaded
TEMPLATE_COUNT=$(AWS_PROFILE=Tebogo-sit aws s3 ls s3://bbws-templates-sit/email/ | wc -l)
if [ "$TEMPLATE_COUNT" -ne 12 ]; then
  echo "ERROR: Expected 12 templates, found $TEMPLATE_COUNT"
  exit 1
fi
echo "All 12 email templates uploaded ✓"

# Download and verify each template
for template in welcome-email.html order-confirmation.html order-shipped.html order-delivered.html password-reset.html password-changed.html account-verification.html invoice-generated.html payment-received.html payment-failed.html subscription-renewal.html account-suspended.html; do
  AWS_PROFILE=Tebogo-sit aws s3 cp s3://bbws-templates-sit/email/$template /tmp/$template

  # Verify file is valid HTML (basic check)
  if grep -q "<html" /tmp/$template && grep -q "</html>" /tmp/$template; then
    echo "$template: Valid HTML ✓"
  else
    echo "ERROR: $template is not valid HTML"
    exit 1
  fi

  rm /tmp/$template
done
```

#### Encryption Validation
```bash
# Verify encryption at rest (KMS)
for bucket in bbws-templates-sit bbws-orders-sit bbws-product-images-sit bbws-tenant-assets-sit bbws-backups-sit bbws-logs-sit; do
  ENCRYPTION=$(AWS_PROFILE=Tebogo-sit aws s3api get-bucket-encryption --bucket $bucket --query 'ServerSideEncryptionConfiguration.Rules[0].ApplyServerSideEncryptionByDefault.SSEAlgorithm' --output text)
  echo "$bucket: Encryption = $ENCRYPTION"
  if [ "$ENCRYPTION" != "aws:kms" ]; then
    echo "WARNING: $bucket not using KMS encryption"
  fi
done
```

#### Monitoring Setup
- [ ] Enable S3 server access logging
  ```bash
  for bucket in bbws-templates-sit bbws-orders-sit bbws-product-images-sit bbws-tenant-assets-sit bbws-backups-sit; do
    AWS_PROFILE=Tebogo-sit aws s3api put-bucket-logging \
      --bucket $bucket \
      --bucket-logging-status '{
        "LoggingEnabled": {
          "TargetBucket": "bbws-logs-sit",
          "TargetPrefix": "s3-access-logs/'$bucket'/"
        }
      }'
  done
  ```
- [ ] Enable S3 metrics and request metrics
- [ ] Create CloudWatch alarms for:
  - 4xx errors (client errors)
  - 5xx errors (server errors)
  - Bucket size (cost monitoring)
  - Number of objects (cost monitoring)
- [ ] Create CloudWatch dashboard for all buckets

---

## Phase 2: SIT Validation (Jan 14-31)

### Week 1: Integration Testing (Jan 14-17)
- [ ] Test template access from campaigns_lambda
- [ ] Test order document upload from order_lambda
- [ ] Test product image upload from product_lambda
- [ ] Verify signed URLs work correctly
- [ ] Test presigned URL expiration
- [ ] Test multipart upload (large files)
- [ ] Verify CORS policies (if applicable)
- [ ] Test CloudFront integration (if configured)

### Week 2: Versioning Testing (Jan 18-19)
- [ ] **CRITICAL**: Test object versioning
  ```bash
  # Upload file v1
  echo "Version 1" > test.txt
  AWS_PROFILE=Tebogo-sit aws s3 cp test.txt s3://bbws-orders-sit/test/test.txt

  # Upload file v2
  echo "Version 2" > test.txt
  AWS_PROFILE=Tebogo-sit aws s3 cp test.txt s3://bbws-orders-sit/test/test.txt

  # List versions
  AWS_PROFILE=Tebogo-sit aws s3api list-object-versions --bucket bbws-orders-sit --prefix test/test.txt

  # Retrieve specific version
  VERSION_ID=$(AWS_PROFILE=Tebogo-sit aws s3api list-object-versions --bucket bbws-orders-sit --prefix test/test.txt --query 'Versions[1].VersionId' --output text)
  AWS_PROFILE=Tebogo-sit aws s3api get-object --bucket bbws-orders-sit --key test/test.txt --version-id $VERSION_ID test-v1.txt
  cat test-v1.txt
  ```
- [ ] Test delete marker creation
- [ ] Test restore from previous version
- [ ] Verify lifecycle policies on versioned objects

### Week 3: Replication Testing (Jan 20-21)
- [ ] Document cross-region replication strategy for PROD
- [ ] Test bucket lifecycle policies
  - Transition to STANDARD_IA after 30 days
  - Transition to GLACIER after 90 days
  - Delete after 365 days (except backups)
- [ ] Verify lifecycle transitions working
- [ ] Test intelligent tiering (if configured)

### Week 4: Security & Compliance (Jan 22-24)
- [ ] **CRITICAL**: Verify no public access
  ```bash
  for bucket in bbws-templates-sit bbws-orders-sit bbws-product-images-sit bbws-tenant-assets-sit bbws-backups-sit bbws-logs-sit; do
    # Attempt public access (should fail)
    curl -I https://s3.amazonaws.com/$bucket/
    # Should return 403 Forbidden
  done
  ```
- [ ] Test IAM policy enforcement (least privilege)
- [ ] Test bucket policies
- [ ] Verify encryption in transit (TLS only)
- [ ] Verify encryption at rest (KMS)
- [ ] Test CloudTrail logging enabled
- [ ] Test data access audit trail
- [ ] Verify VPC endpoint access (if configured)
- [ ] Test signed URL security

### Week 5: Final Validation (Jan 27-31)
- [ ] Re-run all validation tests
- [ ] Verify all Lambda services can access buckets
- [ ] Cost analysis completed
- [ ] Security compliance verified
- [ ] Email templates tested in all Lambda services
- [ ] SIT sign-off meeting
- [ ] SIT approval gate passed

---

## Phase 3: PROD Promotion (Feb 24, 2026)

### Pre-Deployment Checklist (Feb 20-23)

#### Production Readiness
- [ ] All SIT tests passing
- [ ] SIT sign-off obtained (Gate 4)
- [ ] Security scan clean
- [ ] Versioning tested and validated
- [ ] Lifecycle policies validated
- [ ] Cross-region replication plan documented
- [ ] Rollback procedure documented

#### PROD Environment Verification
- [ ] AWS SSO login to PROD account (093646564004)
- [ ] Verify AWS profile: `AWS_PROFILE=Tebogo-prod aws sts get-caller-identity`
- [ ] Confirm PROD primary region: af-south-1
- [ ] Confirm PROD DR region: eu-west-1
- [ ] Verify IAM permissions for S3 in both regions
- [ ] Verify KMS keys available in both regions

#### Multi-Region DR Setup
- [ ] **CRITICAL**: Document cross-region replication strategy
  - Replicate all buckets from af-south-1 to eu-west-1
  - Versioning enabled in both regions
  - Delete markers replicated
  - Encrypted replication with KMS
- [ ] Verify replication IAM role configured
- [ ] Document failover procedure (af-south-1 → eu-west-1)
- [ ] Document failback procedure (eu-west-1 → af-south-1)

#### Change Management
- [ ] Change request submitted and approved
- [ ] Customer notification sent (if applicable)
- [ ] Rollback team on standby
- [ ] Communication channels ready (Slack, email)
- [ ] Incident response team briefed

#### Data Migration
- [ ] No data migration needed (new buckets)
- [ ] Verify PROD has no existing data
- [ ] Prepare email templates for upload

### Deployment Steps (Feb 24, 9:00 AM)

#### Step 1: Pre-deployment Verification
```bash
# Verify SIT is stable
AWS_PROFILE=Tebogo-sit aws s3 ls | grep bbws

# Verify PROD access (primary region)
AWS_PROFILE=Tebogo-prod aws sts get-caller-identity --region af-south-1

# Verify PROD access (DR region)
AWS_PROFILE=Tebogo-prod aws sts get-caller-identity --region eu-west-1

# Verify no existing buckets in PROD
AWS_PROFILE=Tebogo-prod aws s3 ls --region af-south-1 | grep bbws
AWS_PROFILE=Tebogo-prod aws s3 ls --region eu-west-1 | grep bbws
```

#### Step 2: Terraform Workspace Switch
```bash
cd /Users/tebogotseka/Documents/agentic_work/2_1_bbws_s3_schemas/terraform
terraform workspace select prod
terraform workspace list  # Verify 'prod' is selected
```

#### Step 3: Terraform Plan (Production - Primary Region)
```bash
AWS_PROFILE=Tebogo-prod terraform plan -out=prod.tfplan -var="region=af-south-1"
# CRITICAL REVIEW:
# - Verify 6 buckets will be created
# - Confirm ALL buckets block public access
# - Verify versioning enabled
# - Confirm KMS encryption
# - Check lifecycle policies
# - Verify bucket policies
# - Confirm replication configuration to eu-west-1
# - Verify NO existing buckets will be destroyed
```

#### Step 4: Final Approval
- Review terraform plan with Product Owner and Security Lead
- Confirm change request approved
- **CRITICAL**: Confirm all buckets block public access
- Verify rollback team ready
- Get explicit "GO" from stakeholders
- Document all approvals

#### Step 5: Execute Deployment (Primary Region)
```bash
# Apply terraform for af-south-1
AWS_PROFILE=Tebogo-prod terraform apply prod.tfplan

# Verify all buckets created
AWS_PROFILE=Tebogo-prod aws s3 ls --region af-south-1 | grep bbws
```

#### Step 6: Setup Cross-Region Replication (DR Region)
```bash
# Enable replication for each bucket
for bucket in bbws-templates-prod bbws-orders-prod bbws-product-images-prod bbws-tenant-assets-prod bbws-backups-prod bbws-logs-prod; do
  # Create destination bucket in DR region
  AWS_PROFILE=Tebogo-prod aws s3 mb s3://$bucket-dr --region eu-west-1

  # Enable versioning on destination
  AWS_PROFILE=Tebogo-prod aws s3api put-bucket-versioning \
    --bucket $bucket-dr \
    --region eu-west-1 \
    --versioning-configuration Status=Enabled

  # Configure replication on source bucket
  AWS_PROFILE=Tebogo-prod aws s3api put-bucket-replication \
    --bucket $bucket \
    --region af-south-1 \
    --replication-configuration file://replication-config-$bucket.json

  echo "Replication configured: $bucket (af-south-1) → $bucket-dr (eu-west-1)"
done
```

#### Step 7: Upload Email Templates
```bash
# Upload all email templates to templates bucket (primary region)
cd /Users/tebogotseka/Documents/agentic_work/2_1_bbws_s3_schemas/templates/email

for template in *.html; do
  AWS_PROFILE=Tebogo-prod aws s3 cp $template \
    s3://bbws-templates-prod/email/$template \
    --region af-south-1 \
    --content-type "text/html" \
    --metadata "version=1.0.0,environment=prod"
  echo "Uploaded: $template"
done

# Wait for replication (5-10 minutes)
sleep 600

# Verify templates replicated to DR region
AWS_PROFILE=Tebogo-prod aws s3 ls s3://bbws-templates-prod-dr/email/ --region eu-west-1
```

### Post-Deployment Validation (Feb 24, 11:30 AM - 1:30 PM)

#### Primary Region Validation (af-south-1)
```bash
# Verify all buckets exist and accessible
for bucket in bbws-templates-prod bbws-orders-prod bbws-product-images-prod bbws-tenant-assets-prod bbws-backups-prod bbws-logs-prod; do
  AWS_PROFILE=Tebogo-prod aws s3 ls s3://$bucket/ --region af-south-1 && echo "$bucket: OK" || echo "$bucket: FAILED"
done

# Verify public access blocked
for bucket in bbws-templates-prod bbws-orders-prod bbws-product-images-prod bbws-tenant-assets-prod bbws-backups-prod bbws-logs-prod; do
  RESULT=$(AWS_PROFILE=Tebogo-prod aws s3api get-public-access-block --bucket $bucket --region af-south-1 --query 'PublicAccessBlockConfiguration.BlockPublicAcls' --output text)
  if [ "$RESULT" != "True" ]; then
    echo "ERROR: $bucket allows public access!"
    exit 1
  fi
  echo "$bucket: Public access blocked ✓"
done

# Verify versioning enabled
for bucket in bbws-templates-prod bbws-orders-prod bbws-product-images-prod bbws-tenant-assets-prod bbws-backups-prod bbws-logs-prod; do
  STATUS=$(AWS_PROFILE=Tebogo-prod aws s3api get-bucket-versioning --bucket $bucket --region af-south-1 --query 'Status' --output text)
  if [ "$STATUS" != "Enabled" ]; then
    echo "ERROR: $bucket versioning not enabled!"
    exit 1
  fi
  echo "$bucket: Versioning enabled ✓"
done

# Verify encryption
for bucket in bbws-templates-prod bbws-orders-prod bbws-product-images-prod bbws-tenant-assets-prod bbws-backups-prod bbws-logs-prod; do
  ENCRYPTION=$(AWS_PROFILE=Tebogo-prod aws s3api get-bucket-encryption --bucket $bucket --region af-south-1 --query 'ServerSideEncryptionConfiguration.Rules[0].ApplyServerSideEncryptionByDefault.SSEAlgorithm' --output text)
  echo "$bucket: Encryption = $ENCRYPTION"
done
```

#### DR Region Validation (eu-west-1)
```bash
# Verify all replica buckets exist
for bucket in bbws-templates-prod-dr bbws-orders-prod-dr bbws-product-images-prod-dr bbws-tenant-assets-prod-dr bbws-backups-prod-dr bbws-logs-prod-dr; do
  AWS_PROFILE=Tebogo-prod aws s3 ls s3://$bucket/ --region eu-west-1 && echo "$bucket: OK" || echo "$bucket: FAILED"
done

# Verify replication status
for bucket in bbws-templates-prod bbws-orders-prod bbws-product-images-prod bbws-tenant-assets-prod bbws-backups-prod bbws-logs-prod; do
  AWS_PROFILE=Tebogo-prod aws s3api get-bucket-replication \
    --bucket $bucket \
    --region af-south-1 \
    --query 'ReplicationConfiguration.Rules[0].Status'
done
```

#### Cross-Region Replication Test
```bash
# Write to primary region (af-south-1)
echo "Replication Test $(date)" > replication-test.txt
AWS_PROFILE=Tebogo-prod aws s3 cp replication-test.txt \
  s3://bbws-templates-prod/test/replication-test.txt \
  --region af-south-1

# Wait for replication (typical: 15 minutes for small objects)
echo "Waiting 15 minutes for replication..."
sleep 900

# Read from DR region (eu-west-1)
AWS_PROFILE=Tebogo-prod aws s3 cp \
  s3://bbws-templates-prod-dr/test/replication-test.txt \
  replication-test-downloaded.txt \
  --region eu-west-1

# Verify content matches
diff replication-test.txt replication-test-downloaded.txt && echo "Replication successful ✓" || echo "ERROR: Replication failed"

# Cleanup
rm replication-test.txt replication-test-downloaded.txt
AWS_PROFILE=Tebogo-prod aws s3 rm s3://bbws-templates-prod/test/replication-test.txt --region af-south-1
```

#### Email Template Validation
```bash
# Verify all 12 templates in primary region
TEMPLATE_COUNT=$(AWS_PROFILE=Tebogo-prod aws s3 ls s3://bbws-templates-prod/email/ --region af-south-1 | wc -l)
if [ "$TEMPLATE_COUNT" -ne 12 ]; then
  echo "ERROR: Expected 12 templates, found $TEMPLATE_COUNT"
  exit 1
fi
echo "All 12 email templates in primary region ✓"

# Verify all 12 templates replicated to DR region
sleep 900  # Wait 15 minutes for replication
TEMPLATE_COUNT_DR=$(AWS_PROFILE=Tebogo-prod aws s3 ls s3://bbws-templates-prod-dr/email/ --region eu-west-1 | wc -l)
if [ "$TEMPLATE_COUNT_DR" -ne 12 ]; then
  echo "WARNING: Expected 12 templates in DR, found $TEMPLATE_COUNT_DR (replication may be in progress)"
fi
```

#### Production Monitoring (First 24 Hours)
- [ ] Monitor every hour for first 6 hours
- [ ] Check CloudWatch metrics hourly
- [ ] Review CloudWatch alarms
- [ ] Monitor replication lag
- [ ] Verify lifecycle policies triggering correctly
- [ ] Check cost metrics
- [ ] Monitor bucket sizes

#### Production Monitoring (First Week)
- [ ] Daily health checks
- [ ] Weekly performance review
- [ ] Cost monitoring (storage, requests, replication, data transfer)
- [ ] Replication health checks
- [ ] Versioning overhead monitoring
- [ ] Incident tracking

---

## Rollback Procedures

### SIT Rollback
```bash
# CRITICAL WARNING: S3 bucket deletion requires buckets to be empty first
# Versioned objects must be permanently deleted

# Option 1: Empty and delete buckets (USE WITH EXTREME CAUTION)
for bucket in bbws-templates-sit bbws-orders-sit bbws-product-images-sit bbws-tenant-assets-sit bbws-backups-sit bbws-logs-sit; do
  # Remove all object versions and delete markers
  AWS_PROFILE=Tebogo-sit aws s3api delete-objects \
    --bucket $bucket \
    --delete "$(aws s3api list-object-versions \
      --bucket $bucket \
      --query='{Objects: Versions[].{Key:Key,VersionId:VersionId}}' \
      --max-items 1000)"

  # Delete bucket
  AWS_PROFILE=Tebogo-sit aws s3 rb s3://$bucket --force
done
```

### PROD Rollback (CRITICAL)
```bash
# CRITICAL WARNING: PROD rollback for S3 is extremely risky
# Buckets with data cannot be rolled back without data loss
# Contact Security Lead before proceeding

# Option 1: Restore from versioned object (if data corruption)
# Identify version to restore
AWS_PROFILE=Tebogo-prod aws s3api list-object-versions \
  --bucket <bucket-name> \
  --prefix <object-key>

# Restore specific version
AWS_PROFILE=Tebogo-prod aws s3api copy-object \
  --bucket <bucket-name> \
  --copy-source <bucket-name>/<object-key>?versionId=<version-id> \
  --key <object-key>

# Option 2: Failover to DR region (if primary region failure)
# Update Lambda environment variables to use eu-west-1 buckets
# Update application configuration to point to DR buckets
```

### Rollback Triggers
- Data corruption detected
- Security breach (unauthorized access)
- Public access misconfiguration
- Encryption failure
- Replication failures
- Unexpected cost spike
- Compliance violation
- Cannot rollback deployment (buckets cannot be "undeployed" without data loss)

---

## Success Criteria

### SIT Success
- [ ] All 6 buckets created successfully
- [ ] ALL buckets block public access
- [ ] Versioning enabled and tested
- [ ] Encryption at rest confirmed
- [ ] Lifecycle policies configured
- [ ] Email templates uploaded (12 templates)
- [ ] Access logging configured
- [ ] Monitoring dashboards configured
- [ ] Integration tests passing (from Lambda services)

### PROD Success
- [ ] All 6 buckets created in af-south-1
- [ ] All 6 buckets replicated to eu-west-1
- [ ] Cross-region replication functioning
- [ ] Replication lag < 15 minutes
- [ ] ALL buckets block public access
- [ ] Versioning enabled in both regions
- [ ] Email templates replicated to DR
- [ ] No errors or alarms triggered
- [ ] Cost within budget
- [ ] Product Owner and Security Lead sign-off

---

## Monitoring & Alerts

### CloudWatch Alarms
| Alarm | Threshold | Action |
|-------|-----------|--------|
| 4xx Errors | > 10 errors/min | SNS alert to DevOps |
| 5xx Errors | > 1 error/min | SNS alert to DevOps (CRITICAL) |
| Replication Lag | > 1 hour | SNS alert to DevOps |
| Replication Failures | > 0 failures | SNS alert to DevOps (CRITICAL) |
| Bucket Size | > 1 TB | SNS alert to FinOps |
| Cost Anomaly | > 20% increase | SNS alert to FinOps |

### CloudWatch Dashboards
- Create: `s3-schemas-sit-dashboard`
- Create: `s3-schemas-prod-dashboard`
- Widgets:
  - Bucket sizes
  - Number of objects
  - Request metrics (GET, PUT, DELETE)
  - 4xx/5xx errors
  - Replication lag (PROD only)
  - Replication failures (PROD only)
  - Cost metrics

---

## Contacts & Escalation

| Role | Contact | Availability |
|------|---------|--------------|
| DevOps Engineer | TBD | Primary deployer |
| Security Lead | TBD | Public access and encryption |
| Tech Lead | TBD | Approval & escalation |
| Product Owner | TBD | Final sign-off |
| On-Call SRE | TBD | 24/7 incident response |
| FinOps Lead | TBD | Cost monitoring |
| AWS Support | TBD | Critical escalations |

---

## Documentation

### Deployment Artifacts
- [ ] Deployment runbook (this document)
- [ ] Terraform plan outputs (sit.tfplan, prod.tfplan)
- [ ] Bucket policy documentation
- [ ] Lifecycle policy documentation
- [ ] Replication configuration
- [ ] Email template documentation
- [ ] Cost analysis

### Post-Deployment
- [ ] Deployment retrospective notes
- [ ] Lessons learned document
- [ ] Updated architecture diagrams (multi-region setup)
- [ ] Incident reports (if any)
- [ ] Replication runbook
- [ ] Versioning best practices
- [ ] DR failover runbook
- [ ] DR failback runbook

---

## Change Log

| Date | Phase | Status | Notes |
|------|-------|--------|-------|
| 2026-01-07 | Planning | 📋 Complete | Promotion plan created |
| 2026-01-13 | SIT Deploy | ⏳ Scheduled | Target deployment (Wave 2) |
| 2026-02-24 | PROD Deploy | 🔵 Planned | Target deployment (Wave 2) |

---

**Next Steps:**
1. Review and approve this plan (CRITICAL: Security Lead review required)
2. Complete pre-deployment checklist
3. MUST be deployed to SIT BEFORE Wave 1 Lambda services can be promoted
4. Schedule SIT deployment for Jan 13 (after DynamoDB schemas)
5. Execute deployment following this plan

**Plan Status:** 📋 READY FOR REVIEW
**Approval Required By:** Tech Lead, DevOps Lead, Security Lead, FinOps Lead
**Wave:** Wave 2 (Infrastructure Foundation)
**Dependencies:** NONE (foundation infrastructure)
**Blocks:** campaigns_lambda, order_lambda, product_lambda (Wave 1)
**CRITICAL:** All buckets MUST block public access
**CRITICAL:** Cross-region replication MUST be validated in PROD
