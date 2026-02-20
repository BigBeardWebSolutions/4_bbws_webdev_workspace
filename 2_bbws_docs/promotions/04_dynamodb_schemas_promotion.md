# Promotion Plan: dynamodb_schemas

**Project**: 2_1_bbws_dynamodb_schemas
**Plan ID**: PROM-DDB-004
**Created**: 2026-01-07
**Owner**: DevOps Engineer
**Status**: 📋 READY FOR EXECUTION

---

## Project Overview

| Attribute | Value |
|-----------|-------|
| **Project Type** | Infrastructure (DynamoDB Tables) |
| **Purpose** | Centralized DynamoDB table definitions for BBWS platform |
| **Current Status** | 100% complete, Production Ready |
| **Tables** | 5 (campaigns, orders, products, tenants, users) |
| **GSIs** | 8 (across all tables) |
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
├─ Deployment      (Jan 13, 9:00 AM)
├─ Validation      (Jan 13, 9:30 AM - 11:00 AM)
└─ Sign-off        (Jan 13, 4:00 PM)

PHASE 2: SIT VALIDATION (Jan 14-31)
├─ Integration Testing (Jan 14-17)
├─ Performance Testing (Jan 18-21)
├─ Backup/Restore Test (Jan 22-24)
├─ Security Scanning   (Jan 25-26)
└─ SIT Sign-off        (Jan 31)

PHASE 3: PROD PROMOTION (Feb 24, 2026)
├─ Pre-deployment  (Feb 20-23)
├─ Deployment      (Feb 24, 8:00 AM)
├─ DR Setup        (Feb 24, 10:00 AM)
├─ Validation      (Feb 24, 11:00 AM - 1:00 PM)
└─ Sign-off        (Feb 27, 4:00 PM)
```

---

## Phase 1: SIT Promotion

### Pre-Deployment Checklist (Jan 11-12)

#### Environment Verification
- [ ] AWS SSO login to SIT account (815856636111)
- [ ] Verify AWS profile: `AWS_PROFILE=Tebogo-sit aws sts get-caller-identity`
- [ ] Confirm SIT region: eu-west-1
- [ ] Verify IAM permissions for DynamoDB table creation
- [ ] Verify IAM permissions for backup vault creation
- [ ] Check KMS key for encryption available

#### Code Preparation
- [ ] Verify latest code in `main` branch
- [ ] Confirm all Terraform validations passing in DEV
- [ ] Review GitHub Actions workflows (promote-sit.yml)
- [ ] Tag release: `v1.0.0-sit`
- [ ] Create changelog for SIT release
- [ ] Document table schemas and GSI definitions

#### Infrastructure Planning
- [ ] Document all tables to be created:
  - `campaigns-sit` (GSI: CampaignsByStatus, CampaignsByDate)
  - `orders-sit` (GSI: OrdersByCustomer, OrdersByStatus, OrdersByDate)
  - `products-sit` (GSI: ProductsByCategory, ProductsByPriceRange, ProductsByAvailability)
  - `tenants-sit` (GSI: TenantsByOrganization)
  - `users-sit` (GSI: UsersByEmail, UsersByOrganization)
- [ ] Verify on-demand capacity mode for all tables
- [ ] Confirm point-in-time recovery (PITR) will be enabled
- [ ] Verify encryption at rest configured (KMS)
- [ ] Plan DynamoDB Streams configuration (if needed)

#### Backup Strategy
- [ ] Document backup vault configuration
- [ ] Verify AWS Backup service role
- [ ] Define backup schedule (hourly backups)
- [ ] Set backup retention period (7 days SIT, 30 days PROD)
- [ ] Document restore procedure

#### Dependencies
- [ ] No dependencies (foundation infrastructure)
- [ ] This is a BLOCKING dependency for all Lambda services

### Deployment Steps (Jan 13, 9:00 AM)

#### Step 1: Terraform Workspace Switch
```bash
cd /Users/tebogotseka/Documents/agentic_work/2_1_bbws_dynamodb_schemas/terraform
terraform workspace select sit
terraform workspace list  # Verify 'sit' is selected
```

#### Step 2: Terraform Plan
```bash
AWS_PROFILE=Tebogo-sit terraform plan -out=sit.tfplan
# CRITICAL REVIEW:
# - Verify 5 tables will be created
# - Confirm 8 GSIs across all tables
# - Verify on-demand capacity mode
# - Confirm PITR enabled
# - Verify KMS encryption
# - Check backup vault configuration
# - Verify no existing tables will be destroyed
```

#### Step 3: Manual Approval
- Review terraform plan output line by line
- Verify no data-destructive operations
- Confirm table schemas match documentation
- Verify GSI definitions correct
- Verify capacity mode is on-demand (NOT provisioned)
- Confirm PITR enabled for all tables
- Get approval from Tech Lead and DBA
- Document approval in deployment log

#### Step 4: Terraform Apply
```bash
AWS_PROFILE=Tebogo-sit terraform apply sit.tfplan
# Monitor output carefully
# Verify each table creation successful
# Note: Table creation may take 2-5 minutes
# GSI creation may take additional 2-5 minutes per GSI
```

#### Step 5: Post-Creation Verification
```bash
# Verify all tables created
AWS_PROFILE=Tebogo-sit aws dynamodb list-tables

# Check each table details
for table in campaigns-sit orders-sit products-sit tenants-sit users-sit; do
  echo "Verifying table: $table"
  AWS_PROFILE=Tebogo-sit aws dynamodb describe-table --table-name $table
done

# Verify PITR enabled
for table in campaigns-sit orders-sit products-sit tenants-sit users-sit; do
  AWS_PROFILE=Tebogo-sit aws dynamodb describe-continuous-backups --table-name $table
done

# Verify backup vault
AWS_PROFILE=Tebogo-sit aws backup list-backup-vaults
```

#### Step 6: Enable Backup Plan
```bash
# Apply backup plan to all tables
AWS_PROFILE=Tebogo-sit aws backup create-backup-selection \
  --backup-plan-id <plan-id> \
  --backup-selection file://backup-selection-sit.json

# Verify backup plan assigned
AWS_PROFILE=Tebogo-sit aws backup list-backup-selections --backup-plan-id <plan-id>
```

### Post-Deployment Validation (Jan 13, 9:30 AM - 11:00 AM)

#### Table Validation
```bash
# Test 1: Verify table status (all should be ACTIVE)
for table in campaigns-sit orders-sit products-sit tenants-sit users-sit; do
  STATUS=$(AWS_PROFILE=Tebogo-sit aws dynamodb describe-table \
    --table-name $table \
    --query 'Table.TableStatus' \
    --output text)
  echo "$table: $STATUS"
  if [ "$STATUS" != "ACTIVE" ]; then
    echo "ERROR: Table $table is not ACTIVE"
    exit 1
  fi
done

# Test 2: Verify GSI status (all should be ACTIVE)
AWS_PROFILE=Tebogo-sit aws dynamodb describe-table \
  --table-name orders-sit \
  --query 'Table.GlobalSecondaryIndexes[*].[IndexName,IndexStatus]' \
  --output table

# Test 3: Verify capacity mode (should be PAY_PER_REQUEST)
for table in campaigns-sit orders-sit products-sit tenants-sit users-sit; do
  CAPACITY=$(AWS_PROFILE=Tebogo-sit aws dynamodb describe-table \
    --table-name $table \
    --query 'Table.BillingModeSummary.BillingMode' \
    --output text)
  echo "$table: $CAPACITY"
  if [ "$CAPACITY" != "PAY_PER_REQUEST" ]; then
    echo "ERROR: Table $table is not in on-demand mode"
    exit 1
  fi
done

# Test 4: Write test data
AWS_PROFILE=Tebogo-sit aws dynamodb put-item \
  --table-name campaigns-sit \
  --item '{
    "campaign_id": {"S": "test-campaign-001"},
    "name": {"S": "SIT Test Campaign"},
    "status": {"S": "draft"},
    "created_at": {"S": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}
  }'

# Test 5: Read test data
AWS_PROFILE=Tebogo-sit aws dynamodb get-item \
  --table-name campaigns-sit \
  --key '{"campaign_id": {"S": "test-campaign-001"}}'

# Test 6: Query GSI
AWS_PROFILE=Tebogo-sit aws dynamodb query \
  --table-name campaigns-sit \
  --index-name CampaignsByStatus \
  --key-condition-expression "status = :status" \
  --expression-attribute-values '{":status": {"S": "draft"}}'

# Test 7: Delete test data
AWS_PROFILE=Tebogo-sit aws dynamodb delete-item \
  --table-name campaigns-sit \
  --key '{"campaign_id": {"S": "test-campaign-001"}}'
```

#### PITR Validation
```bash
# Verify PITR enabled and recovery window
for table in campaigns-sit orders-sit products-sit tenants-sit users-sit; do
  AWS_PROFILE=Tebogo-sit aws dynamodb describe-continuous-backups \
    --table-name $table \
    --query 'ContinuousBackupsDescription.PointInTimeRecoveryDescription' \
    --output table
done
```

#### Backup Validation
```bash
# Trigger manual backup for testing
for table in campaigns-sit orders-sit products-sit tenants-sit users-sit; do
  AWS_PROFILE=Tebogo-sit aws dynamodb create-backup \
    --table-name $table \
    --backup-name "$table-manual-test-$(date +%Y%m%d-%H%M%S)"
done

# Verify backup created
AWS_PROFILE=Tebogo-sit aws dynamodb list-backups --time-range-lower-bound $(date -u -d '10 minutes ago' +%s)
```

#### Monitoring Setup
- [ ] Verify CloudWatch metrics available for all tables
  ```bash
  AWS_PROFILE=Tebogo-sit aws cloudwatch list-metrics \
    --namespace AWS/DynamoDB \
    --dimensions Name=TableName,Value=orders-sit
  ```
- [ ] Create CloudWatch alarms for:
  - User errors (400s)
  - System errors (500s)
  - Read/write throttling (should not occur with on-demand)
  - Consumed read/write capacity units (for cost monitoring)
- [ ] Create CloudWatch dashboard for all tables

---

## Phase 2: SIT Validation (Jan 14-31)

### Week 1: Integration Testing (Jan 14-17)
- [ ] Test table access from campaigns_lambda
- [ ] Test table access from order_lambda
- [ ] Test table access from product_lambda
- [ ] Verify GSI queries perform correctly
- [ ] Test concurrent read/write operations
- [ ] Verify data consistency across operations
- [ ] Test conditional writes (optimistic locking)
- [ ] Test transactions (if used)
- [ ] Verify DynamoDB Streams (if enabled)

### Week 2: Performance Testing (Jan 18-21)
- [ ] Configure load testing tool
- [ ] Run sustained load test (1000 writes/sec, 5000 reads/sec)
- [ ] Monitor on-demand capacity scaling
- [ ] Verify no throttling occurs
- [ ] Test GSI query performance under load
- [ ] Test scan operations (should be avoided in production)
- [ ] Monitor latency (p50, p95, p99)
- [ ] Document performance baselines
- [ ] Cost analysis (on-demand vs provisioned comparison)

### Week 3: Backup/Restore Testing (Jan 22-24)
- [ ] **CRITICAL**: Test PITR restore procedure
  ```bash
  # Restore to 1 hour ago
  AWS_PROFILE=Tebogo-sit aws dynamodb restore-table-to-point-in-time \
    --source-table-name campaigns-sit \
    --target-table-name campaigns-sit-restored-$(date +%Y%m%d) \
    --restore-date-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S)

  # Verify restored data
  # Delete restored table after validation
  ```
- [ ] Test backup restore procedure
  ```bash
  # List available backups
  AWS_PROFILE=Tebogo-sit aws dynamodb list-backups --table-name orders-sit

  # Restore from backup
  AWS_PROFILE=Tebogo-sit aws dynamodb restore-table-from-backup \
    --target-table-name orders-sit-restored-$(date +%Y%m%d) \
    --backup-arn <backup-arn>

  # Verify restored data matches source
  # Delete restored table after validation
  ```
- [ ] Test automated hourly backup execution
- [ ] Verify backup retention policies
- [ ] Document restore RTO (Recovery Time Objective)
- [ ] Document restore RPO (Recovery Point Objective)
- [ ] Test restore to different account (DR scenario)

### Week 4: Security & Compliance (Jan 25-26)
- [ ] Verify encryption at rest (KMS)
  ```bash
  for table in campaigns-sit orders-sit products-sit tenants-sit users-sit; do
    AWS_PROFILE=Tebogo-sit aws dynamodb describe-table \
      --table-name $table \
      --query 'Table.SSEDescription'
  done
  ```
- [ ] Verify encryption in transit (TLS)
- [ ] Test IAM policy enforcement (least privilege)
- [ ] Test fine-grained access control (if implemented)
- [ ] Verify CloudTrail logging enabled
- [ ] Test data access audit trail
- [ ] Verify no public access to tables
- [ ] Test VPC endpoint access (if configured)

### Week 5: Final Validation (Jan 27-31)
- [ ] Re-run all validation tests
- [ ] Verify all Lambda services can access tables
- [ ] Performance benchmarks documented
- [ ] Cost analysis completed
- [ ] Backup/restore procedures validated
- [ ] Security compliance verified
- [ ] SIT sign-off meeting
- [ ] SIT approval gate passed

---

## Phase 3: PROD Promotion (Feb 24, 2026)

### Pre-Deployment Checklist (Feb 20-23)

#### Production Readiness
- [ ] All SIT tests passing
- [ ] SIT sign-off obtained (Gate 4)
- [ ] Performance meets requirements
- [ ] Security scan clean
- [ ] Disaster recovery plan documented
- [ ] Backup/restore procedures validated in SIT
- [ ] Cross-region replication plan documented
- [ ] Rollback procedure documented (complex for DynamoDB)

#### PROD Environment Verification
- [ ] AWS SSO login to PROD account (093646564004)
- [ ] Verify AWS profile: `AWS_PROFILE=Tebogo-prod aws sts get-caller-identity`
- [ ] Confirm PROD primary region: af-south-1
- [ ] Confirm PROD DR region: eu-west-1
- [ ] Verify IAM permissions for DynamoDB in both regions
- [ ] Verify KMS keys available in both regions
- [ ] Verify AWS Backup service role in both regions

#### Multi-Region DR Setup
- [ ] **CRITICAL**: Document cross-region replication strategy
  - DynamoDB Global Tables for multi-region active-active
  - Hourly backups in both regions
  - Cross-region backup copy (af-south-1 → eu-west-1)
- [ ] Verify Route53 health checks for failover
- [ ] Document failover procedure (af-south-1 → eu-west-1)
- [ ] Document failback procedure (eu-west-1 → af-south-1)

#### Change Management
- [ ] Change request submitted and approved
- [ ] Maintenance window scheduled (recommended for initial creation)
- [ ] Customer notification sent (if applicable)
- [ ] Rollback team on standby
- [ ] Communication channels ready (Slack, email)
- [ ] Incident response team briefed
- [ ] DBA on standby

#### Data Migration
- [ ] No data migration needed (new tables)
- [ ] Verify PROD has no existing data
- [ ] Document data seeding process (if needed)
- [ ] Prepare initial tenant/user data (if applicable)

### Deployment Steps (Feb 24, 8:00 AM)

#### Step 1: Pre-deployment Verification
```bash
# Verify SIT is stable
for table in campaigns-sit orders-sit products-sit tenants-sit users-sit; do
  AWS_PROFILE=Tebogo-sit aws dynamodb describe-table --table-name $table \
    --query 'Table.TableStatus'
done

# Verify PROD access (primary region)
AWS_PROFILE=Tebogo-prod aws sts get-caller-identity --region af-south-1

# Verify PROD access (DR region)
AWS_PROFILE=Tebogo-prod aws sts get-caller-identity --region eu-west-1

# Verify no existing tables in PROD
AWS_PROFILE=Tebogo-prod aws dynamodb list-tables --region af-south-1
AWS_PROFILE=Tebogo-prod aws dynamodb list-tables --region eu-west-1
```

#### Step 2: Terraform Workspace Switch
```bash
cd /Users/tebogotseka/Documents/agentic_work/2_1_bbws_dynamodb_schemas/terraform
terraform workspace select prod
terraform workspace list  # Verify 'prod' is selected
```

#### Step 3: Terraform Plan (Production - Primary Region)
```bash
AWS_PROFILE=Tebogo-prod terraform plan -out=prod.tfplan -var="region=af-south-1"
# CRITICAL REVIEW:
# - Verify 5 tables will be created
# - Confirm 8 GSIs across all tables
# - Verify on-demand capacity mode
# - Confirm PITR enabled
# - Verify KMS encryption
# - Check backup vault configuration (30-day retention for PROD)
# - Verify NO existing tables will be destroyed
# - Confirm no data loss risk
```

#### Step 4: Final Approval
- Review terraform plan with Product Owner and DBA
- Confirm change request approved
- Verify rollback team ready
- Verify backup team ready
- Get explicit "GO" from stakeholders
- Document all approvals

#### Step 5: Execute Deployment (Primary Region)
```bash
# Apply terraform for af-south-1
AWS_PROFILE=Tebogo-prod terraform apply prod.tfplan

# Monitor table creation
watch -n 5 'AWS_PROFILE=Tebogo-prod aws dynamodb list-tables --region af-south-1'

# Wait for all tables to be ACTIVE
for table in campaigns-prod orders-prod products-prod tenants-prod users-prod; do
  aws dynamodb wait table-exists --table-name $table --profile Tebogo-prod --region af-south-1
done
```

#### Step 6: Setup Cross-Region Replication (DR Region)
```bash
# Option 1: Create Global Tables (Recommended for active-active DR)
for table in campaigns-prod orders-prod products-prod tenants-prod users-prod; do
  AWS_PROFILE=Tebogo-prod aws dynamodb update-table \
    --table-name $table \
    --region af-south-1 \
    --replica-updates '[
      {
        "Create": {
          "RegionName": "eu-west-1"
        }
      }
    ]'

  # Wait for replication to complete
  aws dynamodb wait table-exists --table-name $table --profile Tebogo-prod --region eu-west-1
done

# Option 2: Hourly backup with cross-region copy
# (Configured via AWS Backup plan)
```

#### Step 7: Enable Backups in Both Regions
```bash
# Primary region (af-south-1)
AWS_PROFILE=Tebogo-prod aws backup create-backup-selection \
  --backup-plan-id <prod-plan-id> \
  --backup-selection file://backup-selection-prod.json \
  --region af-south-1

# DR region (eu-west-1)
AWS_PROFILE=Tebogo-prod aws backup create-backup-selection \
  --backup-plan-id <prod-dr-plan-id> \
  --backup-selection file://backup-selection-prod-dr.json \
  --region eu-west-1
```

### Post-Deployment Validation (Feb 24, 11:00 AM - 1:00 PM)

#### Primary Region Validation (af-south-1)
```bash
# Verify all tables ACTIVE
for table in campaigns-prod orders-prod products-prod tenants-prod users-prod; do
  STATUS=$(AWS_PROFILE=Tebogo-prod aws dynamodb describe-table \
    --table-name $table \
    --region af-south-1 \
    --query 'Table.TableStatus' \
    --output text)
  echo "$table (af-south-1): $STATUS"
done

# Verify GSIs ACTIVE
AWS_PROFILE=Tebogo-prod aws dynamodb describe-table \
  --table-name orders-prod \
  --region af-south-1 \
  --query 'Table.GlobalSecondaryIndexes[*].[IndexName,IndexStatus]' \
  --output table

# Verify on-demand capacity mode
for table in campaigns-prod orders-prod products-prod tenants-prod users-prod; do
  CAPACITY=$(AWS_PROFILE=Tebogo-prod aws dynamodb describe-table \
    --table-name $table \
    --region af-south-1 \
    --query 'Table.BillingModeSummary.BillingMode' \
    --output text)
  echo "$table: $CAPACITY"
done

# Verify PITR enabled
for table in campaigns-prod orders-prod products-prod tenants-prod users-prod; do
  AWS_PROFILE=Tebogo-prod aws dynamodb describe-continuous-backups \
    --table-name $table \
    --region af-south-1 \
    --query 'ContinuousBackupsDescription.PointInTimeRecoveryDescription.PointInTimeRecoveryStatus'
done
```

#### DR Region Validation (eu-west-1)
```bash
# Verify all replica tables ACTIVE
for table in campaigns-prod orders-prod products-prod tenants-prod users-prod; do
  STATUS=$(AWS_PROFILE=Tebogo-prod aws dynamodb describe-table \
    --table-name $table \
    --region eu-west-1 \
    --query 'Table.TableStatus' \
    --output text)
  echo "$table (eu-west-1): $STATUS"
done

# Verify replication lag
for table in campaigns-prod orders-prod products-prod tenants-prod users-prod; do
  AWS_PROFILE=Tebogo-prod aws dynamodb describe-table \
    --table-name $table \
    --region af-south-1 \
    --query 'Table.Replicas[?RegionName==`eu-west-1`].ReplicationStatus'
done
```

#### Cross-Region Replication Test
```bash
# Write to primary region (af-south-1)
AWS_PROFILE=Tebogo-prod aws dynamodb put-item \
  --table-name campaigns-prod \
  --region af-south-1 \
  --item '{
    "campaign_id": {"S": "replication-test-001"},
    "name": {"S": "Replication Test"},
    "status": {"S": "active"},
    "created_at": {"S": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}
  }'

# Wait 5 seconds for replication
sleep 5

# Read from DR region (eu-west-1)
AWS_PROFILE=Tebogo-prod aws dynamodb get-item \
  --table-name campaigns-prod \
  --region eu-west-1 \
  --key '{"campaign_id": {"S": "replication-test-001"}}'

# Cleanup test data
AWS_PROFILE=Tebogo-prod aws dynamodb delete-item \
  --table-name campaigns-prod \
  --region af-south-1 \
  --key '{"campaign_id": {"S": "replication-test-001"}}'
```

#### Backup Validation
```bash
# Trigger manual backup in primary region
for table in campaigns-prod orders-prod products-prod tenants-prod users-prod; do
  AWS_PROFILE=Tebogo-prod aws dynamodb create-backup \
    --table-name $table \
    --region af-south-1 \
    --backup-name "$table-manual-test-$(date +%Y%m%d-%H%M%S)"
done

# Verify backups created
AWS_PROFILE=Tebogo-prod aws dynamodb list-backups \
  --region af-south-1 \
  --time-range-lower-bound $(date -u -d '10 minutes ago' +%s)

# Verify backup plan execution
AWS_PROFILE=Tebogo-prod aws backup list-backup-jobs \
  --by-backup-vault-name bbws-dynamodb-backup-vault-prod \
  --region af-south-1
```

#### Production Monitoring (First 24 Hours)
- [ ] Monitor every 30 minutes for first 6 hours
- [ ] Check CloudWatch metrics hourly
- [ ] Review CloudWatch alarms
- [ ] Monitor table capacity (should auto-scale with on-demand)
- [ ] Monitor replication lag (should be <1 second)
- [ ] Verify backup jobs executing hourly
- [ ] Check cost metrics

#### Production Monitoring (First Week)
- [ ] Daily health checks
- [ ] Weekly performance review
- [ ] Cost monitoring (on-demand capacity, backups, replication, storage)
- [ ] Replication health checks
- [ ] Backup success rate
- [ ] PITR validation
- [ ] Incident tracking

---

## Rollback Procedures

### SIT Rollback
```bash
# CRITICAL WARNING: DynamoDB table deletion is irreversible
# Only rollback if absolutely necessary

# Option 1: Destroy all tables (USE WITH EXTREME CAUTION)
cd /Users/tebogotseka/Documents/agentic_work/2_1_bbws_dynamodb_schemas
terraform workspace select sit
AWS_PROFILE=Tebogo-sit terraform destroy

# Option 2: Delete specific table
AWS_PROFILE=Tebogo-sit aws dynamodb delete-table --table-name <table-name>
```

### PROD Rollback (CRITICAL)
```bash
# CRITICAL WARNING: PROD rollback for DynamoDB is extremely risky
# Contact DBA before proceeding
# Document incident before rollback

# Option 1: Restore from PITR (if data corruption)
AWS_PROFILE=Tebogo-prod aws dynamodb restore-table-to-point-in-time \
  --source-table-name <table-name> \
  --target-table-name <table-name>-restored \
  --region af-south-1 \
  --restore-date-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S)

# Option 2: Restore from backup
AWS_PROFILE=Tebogo-prod aws dynamodb restore-table-from-backup \
  --target-table-name <table-name>-restored \
  --backup-arn <backup-arn> \
  --region af-south-1

# Option 3: Failover to DR region (if primary region failure)
# Update Route53 health checks to point to eu-west-1
# Update Lambda environment variables to use eu-west-1 endpoint
```

### Rollback Triggers
- Data corruption detected
- Critical functionality broken
- Replication failures
- Backup failures
- Unexpected cost spike
- Security breach
- Compliance violation
- Cannot rollback deployment (tables cannot be "undeployed" without data loss)

---

## Success Criteria

### SIT Success
- [ ] All 5 tables created successfully
- [ ] All 8 GSIs ACTIVE
- [ ] On-demand capacity mode confirmed
- [ ] PITR enabled and tested
- [ ] Backup plan executing successfully
- [ ] Restore procedure validated
- [ ] Performance baseline established
- [ ] Monitoring dashboards configured
- [ ] Integration tests passing (from Lambda services)

### PROD Success
- [ ] All 5 tables created in af-south-1
- [ ] All 5 tables replicated to eu-west-1
- [ ] All GSIs ACTIVE in both regions
- [ ] Replication lag < 1 second
- [ ] PITR enabled in both regions
- [ ] Hourly backups executing in both regions
- [ ] Cross-region backup copy functioning
- [ ] No errors or alarms triggered
- [ ] Cost within budget
- [ ] Product Owner and DBA sign-off

---

## Monitoring & Alerts

### CloudWatch Alarms
| Alarm | Threshold | Action |
|-------|-----------|--------|
| User Errors | > 10 errors/min | SNS alert to DevOps |
| System Errors | > 1 error/min | SNS alert to DevOps (CRITICAL) |
| Read Throttle Events | > 0 (should not occur with on-demand) | SNS alert to DevOps |
| Write Throttle Events | > 0 (should not occur with on-demand) | SNS alert to DevOps |
| Replication Lag | > 5 seconds | SNS alert to DevOps |
| Backup Failures | > 0 failures | SNS alert to DevOps (CRITICAL) |
| Cost Anomaly | > 20% increase | SNS alert to FinOps |

### CloudWatch Dashboards
- Create: `dynamodb-schemas-sit-dashboard`
- Create: `dynamodb-schemas-prod-dashboard`
- Widgets:
  - Table status
  - Consumed capacity units
  - Throttled requests
  - System errors
  - User errors
  - Replication lag (PROD only)
  - Backup success rate

---

## Contacts & Escalation

| Role | Contact | Availability |
|------|---------|--------------|
| DevOps Engineer | TBD | Primary deployer |
| DBA | TBD | Table design and backup/restore |
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
- [ ] Table schema documentation
- [ ] GSI usage patterns
- [ ] Backup/restore procedures
- [ ] Cross-region replication configuration
- [ ] Performance benchmarks
- [ ] Cost analysis

### Post-Deployment
- [ ] Deployment retrospective notes
- [ ] Lessons learned document
- [ ] Updated architecture diagrams (multi-region setup)
- [ ] Incident reports (if any)
- [ ] Backup schedule documentation
- [ ] Restore runbook
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
1. Review and approve this plan (CRITICAL: DBA review required)
2. Complete pre-deployment checklist
3. MUST be deployed to SIT BEFORE Wave 1 Lambda services can be promoted
4. Schedule SIT deployment for Jan 13
5. Execute deployment following this plan
6. Block Wave 1 Lambda promotion to SIT until this completes

**Plan Status:** 📋 READY FOR REVIEW
**Approval Required By:** Tech Lead, DevOps Lead, DBA, FinOps Lead
**Wave:** Wave 2 (Infrastructure Foundation)
**Dependencies:** NONE (foundation infrastructure)
**Blocks:** campaigns_lambda, order_lambda, product_lambda (Wave 1)
**CRITICAL:** This is a BLOCKING dependency for all API Lambda services
