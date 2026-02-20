# Deployment Runbook: S3 and DynamoDB Infrastructure

**Document Version**: 1.0
**Last Updated**: 2025-12-25
**Applicable Environments**: DEV, SIT, PROD
**Status**: Active

---

## 1. Overview

### Purpose
This runbook provides step-by-step procedures for deploying and validating S3 bucket and DynamoDB table infrastructure across the BBWS multi-tenant platform environments. It serves as the single source of truth for infrastructure deployment activities.

### Scope
- S3 bucket creation and configuration
- DynamoDB table provisioning (on-demand capacity mode)
- Bucket policies and security configurations
- Cross-region replication setup (PROD only)
- Infrastructure validation and monitoring

### Intended Audience
- DevOps engineers
- Infrastructure team members
- Release managers
- On-call engineers

### Environment Target Accounts
| Environment | AWS Account | Primary Region | Failover Region |
|---|---|---|---|
| DEV | 536580886816 | af-south-1 | - |
| SIT | 815856636111 | af-south-1 | - |
| PROD | 093646564004 | af-south-1 (primary) | eu-west-1 (failover) |

---

## 2. Prerequisites

### AWS Access Requirements
- AWS CLI v2.13+ installed and configured
- Valid AWS credentials for each environment
- IAM permissions: S3FullAccess, DynamoDBFullAccess, CloudFormation, IAM policy creation
- MFA enabled for PROD account operations
- VPN/direct access to AWS accounts (if required)

### GitHub Access Requirements
- GitHub repository access: `2_bbws_terraform`
- GitHub personal access token with repo and workflow permissions
- Ability to trigger GitHub Actions workflows

### Required Tools
```bash
# Verify installations
aws --version          # Must be 2.13.0 or higher
terraform --version    # Must be 1.5.0 or higher
git --version          # Must be 2.40.0 or higher
jq --version           # For JSON parsing
```

### Environment Variables
```bash
# Set these in your shell before deployment
export AWS_PROFILE=bbws-dev        # or bbws-sit / bbws-prod
export AWS_REGION=af-south-1       # or eu-west-1 for failover
export ENVIRONMENT=dev             # or sit / prod
export TF_VAR_environment=dev       # Terraform environment variable
```

### Credentials Configuration
```bash
# Verify AWS credentials are configured correctly
aws sts get-caller-identity --profile bbws-dev
# Expected output:
# {
#   "UserId": "AIDAJXXXXXXXXXXXXXX",
#   "Account": "536580886816",
#   "Arn": "arn:aws:iam::536580886816:user/your-username"
# }
```

---

## 3. Pre-Deployment Checklist

Complete this checklist before proceeding with deployment:

- [ ] **Change Control**: Approval ticket created and approved in JIRA/Azure DevOps
- [ ] **Backup Verification**: Confirm existing DynamoDB backups are available
- [ ] **S3 Bucket Names**: Verify bucket names don't conflict with existing resources
- [ ] **Capacity Planning**: Confirm DynamoDB on-demand mode is appropriate
- [ ] **Access Control**: Validate IAM principal access in target environment
- [ ] **Network Connectivity**: Confirm VPN/network access to AWS accounts
- [ ] **Git Branch**: Verify you're on the correct branch (main for PROD, dev-* for DEV/SIT)
- [ ] **Terraform State**: Backup existing terraform.tfstate files
- [ ] **Dependency Check**: Confirm no other deployments are in progress
- [ ] **Communication**: Notify stakeholders of deployment window

### Pre-Deployment Validation Commands
```bash
# Verify AWS access
aws s3 ls --profile bbws-$ENVIRONMENT
# Expected: Lists existing buckets

# Check Terraform state
cd 2_bbws_terraform
terraform state list -lock=false
# Expected: Current resource list displays

# Verify Git status
git status
# Expected: "nothing to commit, working tree clean"

# Validate Terraform configuration
terraform validate
# Expected: "Success! The configuration is valid."
```

---

## 4. DEV Deployment Procedure

### Overview
DEV deployments follow standard Terraform workflow with automatic approval for faster iteration.

### Timing
- Expected duration: 10-15 minutes
- Terraform plan: 2-3 minutes
- Terraform apply: 5-7 minutes
- Validation: 3-5 minutes

### Step-by-Step Procedure

#### Step 1: Prepare Deployment Environment
```bash
# Clone or update repository
cd /path/to/2_bbws_terraform
git pull origin dev
git checkout dev

# Set environment variables
export AWS_PROFILE=bbws-dev
export AWS_REGION=af-south-1
export ENVIRONMENT=dev
export TF_VAR_environment=dev

# Verify AWS access
aws sts get-caller-identity --profile bbws-dev
```

#### Step 2: Review and Plan Changes
```bash
# Initialize Terraform
terraform init -upgrade

# Format check
terraform fmt -check -recursive

# Validate syntax
terraform validate

# Generate plan
terraform plan -out=tfplan -var="environment=dev"

# Review plan output
terraform show tfplan
```

**Expected Output**:
```
Plan: X to add, Y to change, Z to destroy.
```

#### Step 3: Apply Infrastructure Changes
```bash
# Apply the plan
terraform apply tfplan

# Monitor output for successful completion
# Expected: "Apply complete! Resources: X added, Y changed, Z destroyed"
```

#### Step 4: Verify S3 Buckets
```bash
# List created buckets
aws s3 ls --profile bbws-dev

# Check bucket configuration
aws s3api get-bucket-versioning \
  --bucket bbws-dev-data-bucket \
  --profile bbws-dev

# Verify bucket block public access
aws s3api get-public-access-block \
  --bucket bbws-dev-data-bucket \
  --profile bbws-dev
```

#### Step 5: Verify DynamoDB Tables
```bash
# List tables
aws dynamodb list-tables --profile bbws-dev

# Check table details
aws dynamodb describe-table \
  --table-name Site-Generation-State \
  --profile bbws-dev

# Verify on-demand billing mode
aws dynamodb describe-table \
  --table-name Site-Generation-State \
  --profile bbws-dev \
  --query 'Table.BillingModeSummary'
```

#### Step 6: Clean Up
```bash
# Remove plan file
rm -f tfplan

# Commit changes (if terraform files were modified)
git add -A
git commit -m "DEV: Deploy S3 and DynamoDB infrastructure"
```

---

## 5. SIT Deployment Procedure

### Overview
SIT deployments require manual approval through GitHub Actions and additional validation.

### Timing
- Expected duration: 20-30 minutes
- Approval wait: 5-15 minutes
- Terraform execution: 10-15 minutes
- Extended validation: 5-10 minutes

### Step-by-Step Procedure

#### Step 1: Prepare SIT Deployment
```bash
# Create or switch to release branch
git checkout -b release/sit-s3-dynamodb-$(date +%Y%m%d)

# Update terraform variables for SIT
export AWS_PROFILE=bbws-sit
export AWS_REGION=af-south-1
export ENVIRONMENT=sit
export TF_VAR_environment=sit

# Verify SIT environment access
aws sts get-caller-identity --profile bbws-sit
```

#### Step 2: Create Pull Request for Approval
```bash
# Push branch to GitHub
git push origin release/sit-s3-dynamodb-$(date +%Y%m%d)

# Create PR with deployment request
# PR Title: "SIT: Deploy S3 and DynamoDB Infrastructure"
# PR Description should include:
# - Infrastructure changes summary
# - Risk assessment
# - Rollback plan
# - Validation approach
```

#### Step 3: Trigger Deployment via GitHub Actions
```bash
# Go to GitHub Actions > Deploy SIT Infrastructure
# Select the workflow "Deploy S3 and DynamoDB"
# Click "Run workflow"
# Select branch: release/sit-s3-dynamodb-*
# Confirm: S3 bucket names and DynamoDB tables
```

#### Step 4: Monitor Approval and Deployment
```bash
# Watch GitHub Actions output
# Expected stages:
# 1. Terraform Plan (should complete in 2-3 minutes)
# 2. Approval Required (wait for maintainer approval)
# 3. Terraform Apply (5-7 minutes)
# 4. Post-deployment tests (3-5 minutes)
```

#### Step 5: SIT-Specific Validation
```bash
# Test cross-account access
aws s3 ls --profile bbws-sit

# Verify data transfer between DEV and SIT
aws s3 sync s3://bbws-dev-data-bucket/export/ \
  s3://bbws-sit-data-bucket/import/ \
  --profile bbws-sit \
  --dry-run

# Run SIT integration tests
cd 2_bbws_ecs_tests
./run_sit_tests.sh --infrastructure
```

#### Step 6: Merge and Close
```bash
# After validation succeeds
git checkout main
git merge release/sit-s3-dynamodb-*
git push origin main

# Delete feature branch
git branch -D release/sit-s3-dynamodb-*
git push origin --delete release/sit-s3-dynamodb-*
```

---

## 6. PROD Deployment Procedure

### Overview
PROD deployments include additional safeguards, scheduled windows, and multi-step approval process.

### Timing
- Expected duration: 45-60 minutes
- Change advisory board review: 15-20 minutes
- Scheduled deployment window: 30 minutes
- Post-deployment validation: 15-20 minutes

### Prerequisites for PROD
- [ ] Change control ticket approved and scheduled
- [ ] Stakeholder notification sent (minimum 24 hours notice)
- [ ] Runbook reviewed by 2 senior engineers
- [ ] DEV and SIT deployments completed successfully
- [ ] Data backup verified in both regions
- [ ] Disaster recovery team on standby

### Step-by-Step Procedure

#### Step 1: Announce Deployment Window
```bash
# Post to Slack #deployments channel
# Include:
# - Deployment window: START_TIME to END_TIME (UTC and local time)
# - Expected downtime: None (blue-green deployment)
# - Rollback time: 15 minutes (if needed)
# - Escalation contact: on-call engineer
# - Change ticket: JIRA-XXXXX
```

#### Step 2: Create PROD Deployment Tag
```bash
# Create release tag
git checkout main
git pull origin main
git tag -a v$(date +%Y.%m.%d)-prod-s3-dynamodb \
  -m "PROD: Deploy S3 and DynamoDB infrastructure"

# Push tag to GitHub
git push origin v$(date +%Y.%m.%d)-prod-s3-dynamodb

# Verify tag
git tag -l --format='%(tag) %(subject)'
```

#### Step 3: Trigger PROD Deployment
```bash
# Set PROD environment
export AWS_PROFILE=bbws-prod
export AWS_REGION=af-south-1
export ENVIRONMENT=prod
export TF_VAR_environment=prod

# Verify PROD access with MFA
aws sts get-caller-identity --profile bbws-prod
# MFA prompt will appear - enter your 2FA code

# Trigger deployment
# Option A: GitHub Actions
#   - Go to GitHub Actions > Deploy PROD Infrastructure
#   - Click "Run workflow" with tag: v$(date +%Y.%m.%d)-prod-s3-dynamodb
#   - Confirm bucket names and table schemas
#
# Option B: CLI
cd 2_bbws_terraform
terraform init -upgrade
terraform plan -var="environment=prod" -var="region=af-south-1" -out=tfplan
# WAIT FOR APPROVAL in GitHub Actions
terraform apply tfplan
```

#### Step 4: Monitor Primary Region Deployment
```bash
# Watch CloudFormation stack
aws cloudformation list-stacks \
  --profile bbws-prod \
  --region af-south-1 \
  --query 'StackSummaries[0]'

# Check CloudWatch logs
aws logs tail /aws/lambda/s3-dynamodb-deployment \
  --profile bbws-prod \
  --follow

# Monitor Lambda execution
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Invocations \
  --statistics Sum \
  --profile bbws-prod \
  --region af-south-1
```

#### Step 5: Deploy to Failover Region (eu-west-1)
```bash
# After primary region succeeds
export AWS_REGION=eu-west-1
export TF_VAR_region=eu-west-1

# Initialize Terraform for failover region
terraform init -backend-config="region=eu-west-1"

# Apply to failover region
terraform plan -var="environment=prod" -var="region=eu-west-1" -out=tfplan-failover
terraform apply tfplan-failover

# Verify failover region
aws s3 ls --profile bbws-prod --region eu-west-1
aws dynamodb list-tables --profile bbws-prod --region eu-west-1
```

#### Step 6: Enable Cross-Region Replication
```bash
# Configure S3 cross-region replication
aws s3api put-bucket-replication \
  --bucket bbws-prod-data-bucket \
  --replication-configuration file://replication-config.json \
  --profile bbws-prod

# Configure DynamoDB global tables (if using)
aws dynamodb create-global-table \
  --global-table-name Site-Generation-State \
  --replication-group RegionName=af-south-1 RegionName=eu-west-1 \
  --profile bbws-prod

# Verify replication
aws s3api get-bucket-replication \
  --bucket bbws-prod-data-bucket \
  --profile bbws-prod
```

#### Step 7: Execute Post-Deployment Validation (see Section 7)
```bash
# Run comprehensive validation
./scripts/validate_prod_deployment.sh
```

#### Step 8: Close Deployment Window
```bash
# Post completion status to Slack
# Message: "PROD deployment completed successfully at HH:MM UTC"
# Include:
# - All resources created successfully
# - Cross-region replication verified
# - Monitoring and alerts enabled
# - Change ticket: JIRA-XXXXX marked as COMPLETED
```

---

## 7. Post-Deployment Validation

### Immediate Validation (5 minutes)

#### S3 Bucket Validation
```bash
# Check bucket exists and is accessible
aws s3 ls --profile bbws-$ENVIRONMENT

# Verify bucket versioning
aws s3api get-bucket-versioning \
  --bucket bbws-$ENVIRONMENT-data-bucket \
  --profile bbws-$ENVIRONMENT

# Check block public access is enabled
aws s3api get-public-access-block \
  --bucket bbws-$ENVIRONMENT-data-bucket \
  --profile bbws-$ENVIRONMENT
# Expected: BlockPublicAcls, IgnorePublicAcls, BlockPublicPolicy all TRUE

# Verify encryption
aws s3api get-bucket-encryption \
  --bucket bbws-$ENVIRONMENT-data-bucket \
  --profile bbws-$ENVIRONMENT

# Test write access
echo "test-$(date +%s)" | aws s3 cp - \
  s3://bbws-$ENVIRONMENT-data-bucket/test-write.txt \
  --profile bbws-$ENVIRONMENT

# Verify write
aws s3 ls s3://bbws-$ENVIRONMENT-data-bucket/test-write.txt \
  --profile bbws-$ENVIRONMENT

# Clean up test file
aws s3 rm s3://bbws-$ENVIRONMENT-data-bucket/test-write.txt \
  --profile bbws-$ENVIRONMENT
```

#### DynamoDB Table Validation
```bash
# List tables
aws dynamodb list-tables --profile bbws-$ENVIRONMENT

# Describe table
aws dynamodb describe-table \
  --table-name Site-Generation-State \
  --profile bbws-$ENVIRONMENT

# Check attributes
aws dynamodb describe-table \
  --table-name Site-Generation-State \
  --profile bbws-$ENVIRONMENT \
  --query 'Table.{Name:TableName, Keys:KeySchema, Attributes:AttributeDefinitions}'

# Verify on-demand billing
aws dynamodb describe-table \
  --table-name Site-Generation-State \
  --profile bbws-$ENVIRONMENT \
  --query 'Table.BillingModeSummary'
# Expected: BillingMode: PAY_PER_REQUEST

# Test write operation
aws dynamodb put-item \
  --table-name Site-Generation-State \
  --item '{"SiteId":{"S":"test-site-001"},"Status":{"S":"ACTIVE"},"CreatedAt":{"N":"'$(date +%s)'"},"TTL":{"N":"'$(($(date +%s) + 86400))'"},"Metadata":{"M":{"Version":{"S":"1.0"}}}}' \
  --profile bbws-$ENVIRONMENT

# Verify write
aws dynamodb get-item \
  --table-name Site-Generation-State \
  --key '{"SiteId":{"S":"test-site-001"}}' \
  --profile bbws-$ENVIRONMENT

# Clean up test item
aws dynamodb delete-item \
  --table-name Site-Generation-State \
  --key '{"SiteId":{"S":"test-site-001"}}' \
  --profile bbws-$ENVIRONMENT
```

### Extended Validation (10 minutes)

#### CloudWatch Monitoring
```bash
# Check for any errors in CloudWatch logs
aws logs describe-log-groups \
  --log-group-name-prefix /aws/s3/ \
  --profile bbws-$ENVIRONMENT

# Check Lambda execution logs
aws logs tail /aws/lambda/ \
  --log-group-name-prefix /aws/lambda/ \
  --profile bbws-$ENVIRONMENT \
  --since 10m

# Monitor DynamoDB metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/DynamoDB \
  --metric-name ConsumedWriteCapacityUnits \
  --dimensions Name=TableName,Value=Site-Generation-State \
  --statistics Sum,Average \
  --start-time $(date -u -d '10 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60 \
  --profile bbws-$ENVIRONMENT
```

#### Integration Testing
```bash
# Run integration tests
cd 2_bbws_ecs_tests
./run_integration_tests.sh --environment=$ENVIRONMENT --infrastructure

# Expected output:
# All tests passed for S3 infrastructure
# All tests passed for DynamoDB infrastructure
```

#### PROD-Specific Validation
```bash
# Verify cross-region replication (PROD only)
aws s3api get-bucket-replication \
  --bucket bbws-prod-data-bucket \
  --profile bbws-prod

# Check replication status
aws s3api get-object-tagging \
  --bucket bbws-prod-data-bucket \
  --key test-replication-marker \
  --profile bbws-prod

# Verify Route 53 health check
aws route53 list-health-checks --profile bbws-prod

# Test failover DNS resolution
nslookup bbws.example.com
# Should resolve to primary region initially
```

### Validation Checklist
- [ ] S3 buckets created successfully
- [ ] S3 block public access enabled
- [ ] S3 versioning enabled
- [ ] S3 encryption enabled
- [ ] DynamoDB tables created successfully
- [ ] DynamoDB on-demand billing enabled
- [ ] DynamoDB read/write operations working
- [ ] CloudWatch logs and metrics visible
- [ ] Integration tests passing
- [ ] No errors in CloudWatch Logs
- [ ] Cross-region replication working (PROD)
- [ ] Disaster recovery route configured (PROD)

---

## 8. Common Issues and Troubleshooting

### Issue 1: S3 Bucket Already Exists
**Problem**: `BucketAlreadyExists` error during terraform apply

**Solution**:
```bash
# Check if bucket exists in another AWS account
aws s3 ls | grep bbws-$ENVIRONMENT-data-bucket

# Option A: Use different bucket name
# Update terraform variables with unique name

# Option B: Import existing bucket
terraform import aws_s3_bucket.data_bucket bbws-$ENVIRONMENT-data-bucket

# Option C: Destroy and recreate (DEV only)
terraform destroy -auto-approve
terraform apply -auto-approve
```

### Issue 2: DynamoDB Table Creation Timeout
**Problem**: Terraform apply hangs on DynamoDB table creation

**Solution**:
```bash
# Check CloudFormation stack status
aws cloudformation describe-stacks \
  --stack-name bbws-dynamodb \
  --profile bbws-$ENVIRONMENT \
  --region af-south-1

# Check for rollback in progress
aws cloudformation describe-stack-events \
  --stack-name bbws-dynamodb \
  --profile bbws-$ENVIRONMENT \
  --query 'StackEvents[0:5]'

# If stuck, cancel the operation
# Press Ctrl+C to cancel terraform
# Then cleanup
terraform destroy -target=aws_dynamodb_table.site_generation_state
```

### Issue 3: Access Denied Errors
**Problem**: `AccessDenied` or `User is not authorized` errors

**Solution**:
```bash
# Verify AWS credentials
aws sts get-caller-identity --profile bbws-$ENVIRONMENT

# Check IAM permissions
aws iam get-user-policy \
  --user-name your-username \
  --policy-name S3-DynamoDB-Deployment \
  --profile bbws-$ENVIRONMENT

# For PROD, verify MFA is enabled
# Re-authenticate with MFA token
aws sts get-session-token \
  --serial-number arn:aws:iam::093646564004:mfa/your-mfa-device \
  --token-code 123456 \
  --profile bbws-prod
```

### Issue 4: Cross-Region Replication Not Working
**Problem**: Objects in primary bucket not replicating to failover bucket

**Solution**:
```bash
# Verify replication configuration
aws s3api get-bucket-replication \
  --bucket bbws-prod-data-bucket \
  --profile bbws-prod

# Check IAM role permissions
aws iam get-role-policy \
  --role-name S3-Replication-Role \
  --policy-name S3-Replication-Policy \
  --profile bbws-prod

# Re-enable replication
aws s3api put-bucket-replication \
  --bucket bbws-prod-data-bucket \
  --replication-configuration file://replication-config.json \
  --profile bbws-prod

# Force replication of existing objects
aws s3 sync s3://bbws-prod-data-bucket/ \
  s3://bbws-prod-data-bucket-failover/ \
  --profile bbws-prod
```

### Issue 5: Terraform State Corruption
**Problem**: `Error: state lock timeout` or state inconsistencies

**Solution**:
```bash
# List locks
terraform force-unlock [LOCK_ID]

# Refresh state
terraform refresh

# Validate state
terraform state list

# As last resort, rebuild state (after backup)
cp terraform.tfstate terraform.tfstate.backup
terraform refresh
terraform state list
```

### Issue 6: DynamoDB Throttling
**Problem**: `ProvisionedThroughputExceededException` or slow operations

**Solution**:
```bash
# Verify table is in on-demand mode
aws dynamodb describe-table \
  --table-name Site-Generation-State \
  --profile bbws-$ENVIRONMENT \
  --query 'Table.BillingModeSummary'

# Check recent metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/DynamoDB \
  --metric-name UserErrors \
  --dimensions Name=TableName,Value=Site-Generation-State \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum \
  --profile bbws-$ENVIRONMENT

# Retry with exponential backoff
# Application code should implement automatic retries
```

### Issue 7: Deployment Approval Stuck
**Problem**: GitHub Actions approval pending for more than 30 minutes

**Solution**:
```bash
# Check workflow run status
gh run list --repo 2_bbws_terraform --status waiting

# Get run details
gh run view [RUN_ID] --repo 2_bbws_terraform

# Cancel workflow if needed
gh run cancel [RUN_ID] --repo 2_bbws_terraform

# Re-trigger after issues resolved
gh workflow run deploy.yml --repo 2_bbws_terraform
```

---

## 9. Rollback Trigger Criteria and Procedures

### When to Rollback (vs. Fix Forward)

#### Rollback Immediately If:
1. **Data Loss Risk**: Write operations failing for more than 5 minutes
2. **Security Breach**: Unauthorized access detected in logs
3. **Service Unavailability**: Application cannot access S3 or DynamoDB
4. **Cross-Region Failure**: Replication not functioning (PROD only)
5. **Configuration Errors**: Wrong IAM policies causing access denial
6. **Resource Exhaustion**: Unexpected AWS service limits hit

#### Fix Forward If:
1. **Minor Connectivity Issues**: Temporary network glitches (resolve in <5 min)
2. **Monitoring Gaps**: Missing CloudWatch metrics (non-critical)
3. **Documentation Issues**: Runbook or label inconsistencies
4. **Performance Degradation**: Elevated latency under investigation

### Rollback Procedure

#### Step 1: Declare Incident
```bash
# Notify stakeholders immediately
# Slack: #incidents channel
# Message: "INCIDENT: Infrastructure deployment rollback in progress"
# Include incident ticket number
```

#### Step 2: Identify Last Known Good State
```bash
# Check git history
git log --oneline -20

# Identify last successful deployment tag
git tag -l --format='%(tag) %(creatordate:short)' | sort -k2 -r

# Verify backup state files
ls -la terraform.tfstate*
```

#### Step 3: Execute Rollback
```bash
# Option A: Rollback to previous Terraform state (< 1 hour old)
git checkout previous-successful-tag
terraform init
terraform plan -out=rollback-plan
terraform apply rollback-plan

# Option B: Delete and recreate from previous state (if state corrupted)
# Backup current state
cp terraform.tfstate terraform.tfstate.failed-$(date +%s)

# Restore previous state
cp terraform.tfstate.backup terraform.tfstate

# Apply previous state
terraform apply

# Option C: Manual AWS CLI rollback (fastest for critical issues)
# Delete problematic resources
aws dynamodb delete-table \
  --table-name Site-Generation-State \
  --profile bbws-$ENVIRONMENT

# Recreate from previous template
aws cloudformation create-stack \
  --stack-name bbws-infrastructure \
  --template-body file://previous-template.json \
  --parameters file://previous-parameters.json \
  --profile bbws-$ENVIRONMENT
```

#### Step 4: Validate Rollback
```bash
# Run validation checklist (Section 7)
./scripts/validate_deployment.sh

# Verify data integrity
aws dynamodb scan \
  --table-name Site-Generation-State \
  --profile bbws-$ENVIRONMENT \
  --query 'Count'
# Expected: Previous item count

# Verify S3 objects
aws s3 ls s3://bbws-$ENVIRONMENT-data-bucket/ \
  --recursive \
  --profile bbws-$ENVIRONMENT \
  --summarize
```

#### Step 5: Post-Incident Review
```bash
# Create post-mortem ticket
# Include:
# - Timeline of events
# - Root cause analysis
# - Why rollback was necessary
# - Preventive measures
# - Implementation timeline

# Update runbook based on lessons learned
# Schedule team retrospective
```

### Rollback Time Estimates
| Scenario | Time | Complexity |
|---|---|---|
| Rollback to previous state (< 1 hr) | 5-10 min | Low |
| Restore from backup (1-24 hrs) | 10-15 min | Medium |
| Manual AWS CLI rollback | 15-20 min | High |
| Data restoration from backup | 30-60 min | High |

---

## Document History

| Version | Date | Author | Changes |
|---|---|---|---|
| 1.0 | 2025-12-25 | DevOps Team | Initial release with 3-environment procedures |

---

## Contact and Escalation

**On-Call Engineer**: Check PagerDuty schedule
**Deployment Lead**: Check JIRA incident ticket
**Escalation Path**: On-Call Engineer → Team Lead → Manager → Director

**Document Owners**: DevOps Team
**Last Review**: 2025-12-25
**Next Review**: 2026-01-25
