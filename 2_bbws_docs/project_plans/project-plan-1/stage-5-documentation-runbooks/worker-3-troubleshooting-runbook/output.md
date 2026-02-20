# 2.1.8 Troubleshooting Runbook: S3 and DynamoDB Infrastructure

**Document**: 2.1.8_Troubleshooting_Runbook_S3_DynamoDB.md
**Worker**: worker-5-3-troubleshooting-runbook
**Stage**: Stage 5 - Documentation & Runbooks
**Created**: 2025-12-25
**Status**: Complete
**LLD Reference**: 2.1.8_LLD_S3_and_DynamoDB.md

---

## Table of Contents

1. [Overview](#1-overview)
2. [Diagnostic Tools](#2-diagnostic-tools)
3. [Common Issues](#3-common-issues)
   - [DynamoDB Issues](#31-dynamodb-issues)
   - [S3 Issues](#32-s3-issues)
   - [CI/CD Issues](#33-cicd-issues)
4. [Log Analysis](#4-log-analysis)
5. [Health Checks](#5-health-checks)
6. [Escalation Procedures](#6-escalation-procedures)

---

## 1. Overview

### 1.1 Purpose

This troubleshooting runbook provides step-by-step diagnostic and resolution procedures for common issues encountered in the BBWS Customer Portal Public S3 and DynamoDB infrastructure. It is designed for:

- **DevOps Engineers**: Investigating deployment and infrastructure failures
- **Support Engineers**: Troubleshooting production incidents
- **Developers**: Debugging integration issues with DynamoDB and S3
- **On-Call Engineers**: Resolving after-hours incidents

### 1.2 How to Use This Runbook

**Step 1**: Identify the symptom or error message from monitoring alerts, logs, or user reports

**Step 2**: Navigate to the relevant section (DynamoDB, S3, or CI/CD)

**Step 3**: Locate the issue matching your symptom

**Step 4**: Follow the step-by-step resolution procedure

**Step 5**: Implement prevention measures to avoid recurrence

**Step 6**: If issue persists, follow escalation procedures in Section 6

### 1.3 Conventions

- **Commands**: All CLI commands assume AWS CLI v2 is installed and configured
- **Environment Variables**: Replace `{env}` with `dev`, `sit`, or `prod`
- **Placeholders**: Replace `{value}` with actual values (e.g., `{table-name}`)
- **Permissions**: Ensure you have appropriate IAM permissions before running commands

### 1.4 Quick Reference

| Issue Type | Section | Common Errors |
|------------|---------|---------------|
| **DynamoDB** | 3.1 | ResourceNotFoundException, AccessDeniedException, ValidationException |
| **S3** | 3.2 | NoSuchBucket, AccessDenied, 404 Not Found |
| **CI/CD** | 3.3 | Terraform errors, workflow failures, state lock conflicts |

---

## 2. Diagnostic Tools

### 2.1 AWS CLI Commands

#### 2.1.1 DynamoDB Diagnostics

**List all DynamoDB tables in environment**:
```bash
aws dynamodb list-tables \
  --region af-south-1 \
  --output table
```

**Describe specific table**:
```bash
aws dynamodb describe-table \
  --table-name bbws-tenants-{env} \
  --region af-south-1 \
  --output json
```

**Check table status**:
```bash
aws dynamodb describe-table \
  --table-name bbws-tenants-{env} \
  --region af-south-1 \
  --query 'Table.TableStatus' \
  --output text
```

**List Global Secondary Indexes (GSIs)**:
```bash
aws dynamodb describe-table \
  --table-name bbws-tenants-{env} \
  --region af-south-1 \
  --query 'Table.GlobalSecondaryIndexes[].IndexName' \
  --output table
```

**Check Point-in-Time Recovery (PITR) status**:
```bash
aws dynamodb describe-continuous-backups \
  --table-name bbws-tenants-{env} \
  --region af-south-1 \
  --query 'ContinuousBackupsDescription.PointInTimeRecoveryDescription.PointInTimeRecoveryStatus' \
  --output text
```

**List table tags**:
```bash
aws dynamodb list-tags-of-resource \
  --resource-arn arn:aws:dynamodb:af-south-1:{account-id}:table/bbws-tenants-{env} \
  --region af-south-1 \
  --output table
```

**Query table items (email-based tenant lookup)**:
```bash
aws dynamodb query \
  --table-name bbws-tenants-{env} \
  --index-name email-index \
  --key-condition-expression "email = :email" \
  --expression-attribute-values '{":email":{"S":"user@example.com"}}' \
  --region af-south-1
```

#### 2.1.2 S3 Diagnostics

**List all S3 buckets**:
```bash
aws s3 ls
```

**Check if bucket exists**:
```bash
aws s3api head-bucket \
  --bucket bbws-templates-{env} \
  --region af-south-1
```

**Get bucket versioning status**:
```bash
aws s3api get-bucket-versioning \
  --bucket bbws-templates-{env} \
  --region af-south-1
```

**Get bucket encryption configuration**:
```bash
aws s3api get-bucket-encryption \
  --bucket bbws-templates-{env} \
  --region af-south-1
```

**Check public access block**:
```bash
aws s3api get-public-access-block \
  --bucket bbws-templates-{env} \
  --region af-south-1
```

**List bucket tags**:
```bash
aws s3api get-bucket-tagging \
  --bucket bbws-templates-{env} \
  --region af-south-1
```

**List objects in bucket**:
```bash
aws s3 ls s3://bbws-templates-{env}/ --recursive
```

**Check bucket replication status (PROD only)**:
```bash
aws s3api get-bucket-replication \
  --bucket bbws-templates-prod \
  --region af-south-1
```

**Download object for inspection**:
```bash
aws s3 cp s3://bbws-templates-{env}/receipts/payment_received.html /tmp/payment_received.html
```

#### 2.1.3 AWS Backup Diagnostics

**List backup plans**:
```bash
aws backup list-backup-plans \
  --region af-south-1 \
  --output table
```

**Get backup plan details**:
```bash
aws backup get-backup-plan \
  --backup-plan-id {backup-plan-id} \
  --region af-south-1
```

**List recovery points for table**:
```bash
aws backup list-recovery-points-by-resource \
  --resource-arn arn:aws:dynamodb:af-south-1:{account-id}:table/bbws-tenants-{env} \
  --region af-south-1
```

### 2.2 AWS Console Links

#### 2.2.1 DynamoDB Console Links

**DEV Tables**:
- Tenants: `https://af-south-1.console.aws.amazon.com/dynamodbv2/home?region=af-south-1#table?name=bbws-tenants-dev`
- Products: `https://af-south-1.console.aws.amazon.com/dynamodbv2/home?region=af-south-1#table?name=bbws-products-dev`
- Campaigns: `https://af-south-1.console.aws.amazon.com/dynamodbv2/home?region=af-south-1#table?name=bbws-campaigns-dev`

**SIT Tables**: (Replace `-dev` with `-sit` in URLs above)

**PROD Tables**: (Replace `-dev` with `-prod` in URLs above)

**Backup Console**:
- `https://af-south-1.console.aws.amazon.com/backup/home?region=af-south-1#/backupplan/list`

#### 2.2.2 S3 Console Links

**DEV Buckets**:
- Templates: `https://s3.console.aws.amazon.com/s3/buckets/bbws-templates-dev?region=af-south-1&tab=objects`

**SIT Buckets**: (Replace `-dev` with `-sit` in URLs above)

**PROD Buckets**: (Replace `-dev` with `-prod` in URLs above)

### 2.3 CloudWatch Log Queries

#### 2.3.1 DynamoDB CloudWatch Metrics

**View table read/write capacity metrics**:
```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/DynamoDB \
  --metric-name ConsumedReadCapacityUnits \
  --dimensions Name=TableName,Value=bbws-tenants-{env} \
  --start-time 2025-12-25T00:00:00Z \
  --end-time 2025-12-25T23:59:59Z \
  --period 3600 \
  --statistics Sum \
  --region af-south-1
```

**View table throttle events**:
```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/DynamoDB \
  --metric-name UserErrors \
  --dimensions Name=TableName,Value=bbws-tenants-{env} \
  --start-time 2025-12-25T00:00:00Z \
  --end-time 2025-12-25T23:59:59Z \
  --period 3600 \
  --statistics Sum \
  --region af-south-1
```

#### 2.3.2 Lambda CloudWatch Logs

**Tail Lambda logs (if Lambda integration exists)**:
```bash
aws logs tail /aws/lambda/bbws-order-lambda-{env} \
  --region af-south-1 \
  --follow
```

**Query Lambda errors**:
```bash
aws logs filter-log-events \
  --log-group-name /aws/lambda/bbws-order-lambda-{env} \
  --filter-pattern "ERROR" \
  --start-time $(date -u -d '1 hour ago' +%s)000 \
  --region af-south-1
```

#### 2.3.3 CloudWatch Insights Queries

**DynamoDB access errors (run in CloudWatch Insights console)**:
```sql
fields @timestamp, @message
| filter @message like /AccessDeniedException/
| sort @timestamp desc
| limit 100
```

**S3 access errors**:
```sql
fields @timestamp, @message
| filter @message like /NoSuchBucket|AccessDenied/
| sort @timestamp desc
| limit 100
```

### 2.4 GitHub Actions Log Access

**View workflow runs**:
```bash
gh run list --repo KimmyAI/2_1_bbws_dynamodb_schemas --limit 20
```

**View specific workflow run logs**:
```bash
gh run view {run-id} --repo KimmyAI/2_1_bbws_dynamodb_schemas --log
```

**Download workflow run logs**:
```bash
gh run download {run-id} --repo KimmyAI/2_1_bbws_dynamodb_schemas
```

### 2.5 Terraform State Inspection

**Show Terraform state**:
```bash
cd terraform/dynamodb  # or terraform/s3
terraform state list
```

**Show specific resource**:
```bash
terraform state show aws_dynamodb_table.tenants
```

**Pull remote state**:
```bash
terraform state pull > state.json
cat state.json | jq '.resources[] | select(.type == "aws_dynamodb_table")'
```

---

## 3. Common Issues

### 3.1 DynamoDB Issues

#### 3.1.1 Issue: Table Not Found

**Symptom/Error Message**:
```
ResourceNotFoundException: Requested resource not found: Table: bbws-tenants-dev not found
```

**Root Cause**:
- Table was never created (Terraform apply failed or was not run)
- Table was accidentally deleted
- Wrong AWS region specified
- Wrong environment name in table name

**Resolution Steps**:

**Step 1**: Verify table existence across all regions
```bash
for region in af-south-1 eu-west-1; do
  echo "Checking region: $region"
  aws dynamodb list-tables --region $region --query "TableNames[?contains(@, 'bbws-tenants')]"
done
```

**Step 2**: Check Terraform state to see if table should exist
```bash
cd /path/to/2_1_bbws_dynamodb_schemas/terraform/dynamodb
terraform state list | grep aws_dynamodb_table.tenants
```

**Step 3**: If table is in Terraform state but not in AWS, import or recreate
```bash
# Option A: Recreate with Terraform
terraform apply -target=aws_dynamodb_table.tenants -var="environment=dev"

# Option B: If table exists but state is missing, import
terraform import aws_dynamodb_table.tenants bbws-tenants-dev
```

**Step 4**: Verify table creation
```bash
aws dynamodb describe-table \
  --table-name bbws-tenants-dev \
  --region af-south-1 \
  --query 'Table.TableStatus'
```

**Step 5**: Wait for table to become ACTIVE (usually 1-2 minutes)
```bash
aws dynamodb wait table-exists \
  --table-name bbws-tenants-dev \
  --region af-south-1
```

**Prevention Measures**:
- Enable CloudWatch alarms for table deletion events
- Implement Terraform remote state locking to prevent concurrent modifications
- Add AWS Config rule to detect table deletions
- Use Terraform `prevent_destroy` lifecycle rule for production tables:
  ```hcl
  lifecycle {
    prevent_destroy = true
  }
  ```
- Document table dependencies in `README.md`

---

#### 3.1.2 Issue: Global Secondary Index (GSI) Creation Failed

**Symptom/Error Message**:
```
An error occurred (ValidationException) when calling the CreateTable operation:
One or more parameter values were invalid: Global Secondary Index already exists: email-index
```

**Root Cause**:
- GSI already exists (duplicate creation attempt)
- Invalid GSI configuration (missing attributes, wrong key schema)
- Exceeded GSI limit (20 GSIs per table)
- Insufficient IAM permissions to create GSI

**Resolution Steps**:

**Step 1**: Check current GSIs on table
```bash
aws dynamodb describe-table \
  --table-name bbws-tenants-dev \
  --region af-south-1 \
  --query 'Table.GlobalSecondaryIndexes[].{Name:IndexName,Status:IndexStatus,Keys:KeySchema}' \
  --output table
```

**Step 2**: If GSI exists but is in CREATING or DELETING state, wait for completion
```bash
# Check GSI status
aws dynamodb describe-table \
  --table-name bbws-tenants-dev \
  --region af-south-1 \
  --query 'Table.GlobalSecondaryIndexes[?IndexName==`email-index`].IndexStatus' \
  --output text

# Wait for GSI to become ACTIVE (can take 5-10 minutes)
aws dynamodb wait table-exists --table-name bbws-tenants-dev --region af-south-1
```

**Step 3**: If GSI is in FAILED state, delete and recreate
```bash
# Delete failed GSI
aws dynamodb update-table \
  --table-name bbws-tenants-dev \
  --region af-south-1 \
  --global-secondary-index-updates '[{"Delete":{"IndexName":"email-index"}}]'

# Wait for deletion to complete
sleep 60

# Recreate GSI with correct configuration
aws dynamodb update-table \
  --table-name bbws-tenants-dev \
  --region af-south-1 \
  --attribute-definitions '[{"AttributeName":"email","AttributeType":"S"}]' \
  --global-secondary-index-updates '[{
    "Create": {
      "IndexName": "email-index",
      "KeySchema": [{"AttributeName":"email","KeyType":"HASH"}],
      "Projection": {"ProjectionType":"ALL"},
      "ProvisionedThroughput": {"ReadCapacityUnits":5,"WriteCapacityUnits":5}
    }
  }]'
```

**Step 4**: For tables using on-demand billing, use this command instead:
```bash
aws dynamodb update-table \
  --table-name bbws-tenants-dev \
  --region af-south-1 \
  --attribute-definitions '[{"AttributeName":"email","AttributeType":"S"}]' \
  --global-secondary-index-updates '[{
    "Create": {
      "IndexName": "email-index",
      "KeySchema": [{"AttributeName":"email","KeyType":"HASH"}],
      "Projection": {"ProjectionType":"ALL"}
    }
  }]'
```

**Step 5**: Verify GSI creation in Terraform
```bash
cd terraform/dynamodb
terraform plan -var="environment=dev" | grep -A 20 "global_secondary_index"
terraform apply -var="environment=dev"
```

**Prevention Measures**:
- Always use Terraform for GSI creation (avoid manual AWS Console changes)
- Add validation checks in Terraform:
  ```hcl
  validation {
    condition     = length(var.global_secondary_indexes) <= 20
    error_message = "DynamoDB tables support a maximum of 20 GSIs."
  }
  ```
- Use `terraform plan` to preview GSI changes before applying
- Document GSI naming conventions in LLD
- Add GitHub Actions validation workflow to check GSI configuration

---

#### 3.1.3 Issue: Point-in-Time Recovery (PITR) Not Enabled

**Symptom/Error Message**:
```
PointInTimeRecoveryStatus: DISABLED
```

**Root Cause**:
- PITR was not enabled during table creation
- PITR was manually disabled via AWS Console
- Terraform configuration missing `point_in_time_recovery` block

**Resolution Steps**:

**Step 1**: Check current PITR status
```bash
aws dynamodb describe-continuous-backups \
  --table-name bbws-tenants-dev \
  --region af-south-1 \
  --query 'ContinuousBackupsDescription.PointInTimeRecoveryDescription' \
  --output table
```

**Step 2**: Enable PITR via AWS CLI
```bash
aws dynamodb update-continuous-backups \
  --table-name bbws-tenants-dev \
  --region af-south-1 \
  --point-in-time-recovery-specification PointInTimeRecoveryEnabled=true
```

**Step 3**: Verify PITR is enabled
```bash
aws dynamodb describe-continuous-backups \
  --table-name bbws-tenants-dev \
  --region af-south-1 \
  --query 'ContinuousBackupsDescription.PointInTimeRecoveryDescription.PointInTimeRecoveryStatus' \
  --output text
# Expected output: ENABLED
```

**Step 4**: Update Terraform configuration to ensure PITR is managed by IaC
```hcl
# In terraform/dynamodb/main.tf
resource "aws_dynamodb_table" "tenants" {
  name           = "bbws-tenants-${var.environment}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "PK"
  range_key      = "SK"

  point_in_time_recovery {
    enabled = true  # Add this block
  }

  # ... rest of configuration
}
```

**Step 5**: Apply Terraform changes
```bash
cd terraform/dynamodb
terraform plan -var="environment=dev"
terraform apply -var="environment=dev"
```

**Step 6**: Enable PITR for all tables across all environments
```bash
for env in dev sit prod; do
  for table in bbws-tenants-$env bbws-products-$env bbws-campaigns-$env; do
    echo "Enabling PITR for $table"
    aws dynamodb update-continuous-backups \
      --table-name $table \
      --region af-south-1 \
      --point-in-time-recovery-specification PointInTimeRecoveryEnabled=true
  done
done
```

**Prevention Measures**:
- Add PITR validation to post-deployment test scripts:
  ```python
  def test_pitr_enabled():
      response = dynamodb.describe_continuous_backups(TableName='bbws-tenants-dev')
      assert response['ContinuousBackupsDescription']['PointInTimeRecoveryDescription']['PointInTimeRecoveryStatus'] == 'ENABLED'
  ```
- Add AWS Config rule to detect PITR disabled events
- Create CloudWatch alarm for PITR status changes
- Document PITR requirement in LLD and deployment runbook

---

#### 3.1.4 Issue: Backup Plan Missing

**Symptom/Error Message**:
```
No backup plan found for table: bbws-tenants-dev
```

**Root Cause**:
- AWS Backup plan was not created during infrastructure deployment
- Backup plan was deleted accidentally
- Table is not assigned to backup plan (missing resource selection)

**Resolution Steps**:

**Step 1**: List existing backup plans
```bash
aws backup list-backup-plans \
  --region af-south-1 \
  --query 'BackupPlansList[?BackupPlanName.contains(@, `bbws`)]' \
  --output table
```

**Step 2**: If backup plan exists, check resource assignments
```bash
# Get backup plan ID
BACKUP_PLAN_ID=$(aws backup list-backup-plans \
  --region af-south-1 \
  --query 'BackupPlansList[?BackupPlanName==`bbws-dynamodb-backup-dev`].BackupPlanId' \
  --output text)

# List resource selections
aws backup list-backup-selections \
  --backup-plan-id $BACKUP_PLAN_ID \
  --region af-south-1 \
  --output table
```

**Step 3**: If backup plan is missing, create it using Terraform
```bash
cd terraform/dynamodb
terraform apply -target=aws_backup_plan.dynamodb_backup -var="environment=dev"
```

**Step 4**: Verify backup plan creation
```bash
aws backup get-backup-plan \
  --backup-plan-id $BACKUP_PLAN_ID \
  --region af-south-1 \
  --output json
```

**Step 5**: Check backup vault exists
```bash
aws backup list-backup-vaults \
  --region af-south-1 \
  --query 'BackupVaultList[?BackupVaultName.contains(@, `bbws`)]' \
  --output table
```

**Step 6**: Manually trigger on-demand backup to test
```bash
aws backup start-backup-job \
  --backup-vault-name bbws-backup-vault-dev \
  --resource-arn arn:aws:dynamodb:af-south-1:{account-id}:table/bbws-tenants-dev \
  --iam-role-arn arn:aws:iam::{account-id}:role/AWSBackupDefaultServiceRole \
  --region af-south-1
```

**Prevention Measures**:
- Add backup plan validation to post-deployment tests
- Create CloudWatch alarm for missed backup jobs
- Schedule weekly backup plan health checks
- Document backup and restore procedures in DR runbook
- Test backup restoration quarterly

---

#### 3.1.5 Issue: Incorrect Table Tags

**Symptom/Error Message**:
```
Tag validation failed: Missing required tag 'Environment'
```

**Root Cause**:
- Tags were not applied during table creation
- Tags were manually removed via AWS Console
- Terraform tag configuration is incomplete

**Resolution Steps**:

**Step 1**: Check current table tags
```bash
TABLE_ARN=$(aws dynamodb describe-table \
  --table-name bbws-tenants-dev \
  --region af-south-1 \
  --query 'Table.TableArn' \
  --output text)

aws dynamodb list-tags-of-resource \
  --resource-arn $TABLE_ARN \
  --region af-south-1 \
  --output table
```

**Step 2**: Apply required tags via AWS CLI
```bash
aws dynamodb tag-resource \
  --resource-arn $TABLE_ARN \
  --region af-south-1 \
  --tags \
    Key=Environment,Value=dev \
    Key=Project,Value="BBWS WP Containers" \
    Key=Owner,Value=Tebogo \
    Key=CostCenter,Value=AWS \
    Key=ManagedBy,Value=Terraform \
    Key=Component,Value=dynamodb \
    Key=Application,Value=CustomerPortalPublic \
    Key=LLD,Value=2.1.8
```

**Step 3**: Verify tags applied
```bash
aws dynamodb list-tags-of-resource \
  --resource-arn $TABLE_ARN \
  --region af-south-1 \
  --output table
```

**Step 4**: Update Terraform to ensure tags are managed
```hcl
# In terraform/dynamodb/main.tf
resource "aws_dynamodb_table" "tenants" {
  name         = "bbws-tenants-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "PK"
  range_key    = "SK"

  tags = {
    Environment  = var.environment
    Project      = "BBWS WP Containers"
    Owner        = "Tebogo"
    CostCenter   = "AWS"
    ManagedBy    = "Terraform"
    Component    = "dynamodb"
    Application  = "CustomerPortalPublic"
    LLD          = "2.1.8"
  }
}
```

**Step 5**: Apply Terraform to sync tags
```bash
cd terraform/dynamodb
terraform apply -var="environment=dev"
```

**Prevention Measures**:
- Add tag validation to post-deployment tests
- Create AWS Config rule to enforce required tags
- Use Terraform variable for tags to ensure consistency
- Document tagging standards in LLD

---

#### 3.1.6 Issue: DynamoDB Access Denied (IAM Permissions)

**Symptom/Error Message**:
```
AccessDeniedException: User: arn:aws:iam::536580886816:user/developer is not authorized
to perform: dynamodb:PutItem on resource: arn:aws:dynamodb:af-south-1:536580886816:table/bbws-tenants-dev
```

**Root Cause**:
- IAM user/role lacks necessary DynamoDB permissions
- Resource-based policy restricts access
- Service Control Policy (SCP) denies access
- VPC endpoint policy restricts access

**Resolution Steps**:

**Step 1**: Identify the principal attempting access
```bash
aws sts get-caller-identity
```

**Step 2**: Check IAM user/role policies
```bash
# For IAM user
aws iam list-attached-user-policies --user-name developer
aws iam list-user-policies --user-name developer

# For IAM role
aws iam list-attached-role-policies --role-name bbws-lambda-execution-dev
aws iam list-role-policies --role-name bbws-lambda-execution-dev
```

**Step 3**: Review inline and attached policies
```bash
# Get inline policy
aws iam get-user-policy \
  --user-name developer \
  --policy-name DynamoDBAccess

# Get attached managed policy
aws iam get-policy-version \
  --policy-arn arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess \
  --version-id v1
```

**Step 4**: Grant minimum required permissions (least privilege)
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:PutItem",
        "dynamodb:GetItem",
        "dynamodb:UpdateItem",
        "dynamodb:Query",
        "dynamodb:Scan"
      ],
      "Resource": [
        "arn:aws:dynamodb:af-south-1:536580886816:table/bbws-tenants-dev",
        "arn:aws:dynamodb:af-south-1:536580886816:table/bbws-tenants-dev/index/*"
      ]
    }
  ]
}
```

**Step 5**: Attach policy to IAM user/role
```bash
# Create policy
aws iam create-policy \
  --policy-name DynamoDBTenantsAccess \
  --policy-document file://dynamodb-policy.json

# Attach to user
aws iam attach-user-policy \
  --user-name developer \
  --policy-arn arn:aws:iam::536580886816:policy/DynamoDBTenantsAccess
```

**Step 6**: Test access after policy attachment (wait 30 seconds for propagation)
```bash
aws dynamodb get-item \
  --table-name bbws-tenants-dev \
  --key '{"PK":{"S":"TENANT#test-id"},"SK":{"S":"METADATA"}}' \
  --region af-south-1
```

**Prevention Measures**:
- Use Terraform to manage all IAM policies
- Implement IAM Access Analyzer to identify overly permissive policies
- Create IAM policy templates for common roles (lambda, developer, admin)
- Enable CloudTrail to audit access denied events
- Document IAM permission requirements in LLD

---

### 3.2 S3 Issues

#### 3.2.1 Issue: S3 Bucket Not Created

**Symptom/Error Message**:
```
NoSuchBucket: The specified bucket does not exist
```

**Root Cause**:
- Bucket was never created (Terraform apply failed or not run)
- Bucket was deleted accidentally
- Wrong bucket name or region specified
- Bucket name conflicts with existing bucket in another account

**Resolution Steps**:

**Step 1**: Verify bucket existence
```bash
aws s3api head-bucket \
  --bucket bbws-templates-dev \
  --region af-south-1
```

**Step 2**: List all buckets to check if it exists with different name
```bash
aws s3 ls | grep bbws-templates
```

**Step 3**: Check Terraform state
```bash
cd terraform/s3
terraform state list | grep aws_s3_bucket.templates
```

**Step 4**: If bucket missing, create using Terraform
```bash
terraform apply -target=aws_s3_bucket.templates -var="environment=dev"
```

**Step 5**: If bucket name is taken, rename in Terraform
```hcl
# In terraform/s3/main.tf
resource "aws_s3_bucket" "templates" {
  bucket = "bbws-templates-${var.environment}-${data.aws_caller_identity.current.account_id}"
  # Added account ID to ensure global uniqueness
}
```

**Step 6**: Verify bucket creation
```bash
aws s3api head-bucket --bucket bbws-templates-dev --region af-south-1
echo "Bucket created successfully"
```

**Prevention Measures**:
- Use account ID in bucket names to ensure uniqueness
- Enable S3 bucket deletion protection via AWS Config
- Add bucket existence validation to post-deployment tests
- Create CloudWatch alarm for bucket deletion events
- Document bucket naming conventions in LLD

---

#### 3.2.2 Issue: S3 Public Access Not Blocked

**Symptom/Error Message**:
```
Security validation failed: S3 bucket bbws-templates-dev does not have public access blocked
```

**Root Cause**:
- Public access block settings were not applied during bucket creation
- Settings were manually changed via AWS Console
- Terraform configuration missing `aws_s3_bucket_public_access_block` resource

**Resolution Steps**:

**Step 1**: Check current public access block status
```bash
aws s3api get-public-access-block \
  --bucket bbws-templates-dev \
  --region af-south-1
```

**Step 2**: Apply public access block via AWS CLI
```bash
aws s3api put-public-access-block \
  --bucket bbws-templates-dev \
  --region af-south-1 \
  --public-access-block-configuration \
    BlockPublicAcls=true,\
    IgnorePublicAcls=true,\
    BlockPublicPolicy=true,\
    RestrictPublicBuckets=true
```

**Step 3**: Verify public access is blocked
```bash
aws s3api get-public-access-block \
  --bucket bbws-templates-dev \
  --region af-south-1 \
  --output table
```

**Step 4**: Update Terraform to manage public access block
```hcl
# In terraform/s3/main.tf
resource "aws_s3_bucket_public_access_block" "templates" {
  bucket = aws_s3_bucket.templates.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

**Step 5**: Apply Terraform changes
```bash
cd terraform/s3
terraform apply -var="environment=dev"
```

**Step 6**: Apply to all environment buckets
```bash
for env in dev sit prod; do
  echo "Blocking public access for bbws-templates-$env"
  aws s3api put-public-access-block \
    --bucket bbws-templates-$env \
    --region af-south-1 \
    --public-access-block-configuration \
      BlockPublicAcls=true,\
      IgnorePublicAcls=true,\
      BlockPublicPolicy=true,\
      RestrictPublicBuckets=true
done
```

**Prevention Measures**:
- Add public access block validation to post-deployment tests
- Create AWS Config rule to detect public S3 buckets
- Enable S3 Block Public Access at account level (all buckets)
- Document S3 security requirements in LLD and security runbook

---

#### 3.2.3 Issue: S3 Versioning Not Enabled

**Symptom/Error Message**:
```
Versioning validation failed: S3 bucket bbws-templates-dev does not have versioning enabled
```

**Root Cause**:
- Versioning was not enabled during bucket creation
- Versioning was suspended via AWS Console
- Terraform configuration missing versioning block

**Resolution Steps**:

**Step 1**: Check current versioning status
```bash
aws s3api get-bucket-versioning \
  --bucket bbws-templates-dev \
  --region af-south-1
```

**Step 2**: Enable versioning
```bash
aws s3api put-bucket-versioning \
  --bucket bbws-templates-dev \
  --region af-south-1 \
  --versioning-configuration Status=Enabled
```

**Step 3**: Verify versioning is enabled
```bash
aws s3api get-bucket-versioning \
  --bucket bbws-templates-dev \
  --region af-south-1 \
  --query 'Status' \
  --output text
# Expected output: Enabled
```

**Step 4**: Update Terraform configuration
```hcl
# In terraform/s3/main.tf
resource "aws_s3_bucket_versioning" "templates" {
  bucket = aws_s3_bucket.templates.id

  versioning_configuration {
    status = "Enabled"
  }
}
```

**Step 5**: Apply Terraform changes
```bash
cd terraform/s3
terraform apply -var="environment=dev"
```

**Prevention Measures**:
- Add versioning validation to post-deployment tests
- Create AWS Config rule to detect versioning disabled
- Document versioning requirement in LLD
- Test version recovery procedures quarterly

---

#### 3.2.4 Issue: Email Templates Not Uploaded to S3

**Symptom/Error Message**:
```
NoSuchKey: The specified key does not exist. Key: receipts/payment_received.html
```

**Root Cause**:
- Templates were not uploaded during Terraform deployment
- Template upload script failed
- Wrong S3 key path specified in Lambda code
- Template file missing from local repository

**Resolution Steps**:

**Step 1**: List all objects in bucket to check what exists
```bash
aws s3 ls s3://bbws-templates-dev/ --recursive
```

**Step 2**: Check if template exists locally
```bash
ls -la /path/to/2_1_bbws_s3_schemas/templates/receipts/payment_received.html
```

**Step 3**: Manually upload missing template
```bash
aws s3 cp /path/to/templates/receipts/payment_received.html \
  s3://bbws-templates-dev/receipts/payment_received.html \
  --region af-south-1 \
  --content-type "text/html"
```

**Step 4**: Verify upload
```bash
aws s3 ls s3://bbws-templates-dev/receipts/payment_received.html
```

**Step 5**: Upload all templates using script
```bash
cd /path/to/2_1_bbws_s3_schemas
./scripts/upload-templates.sh dev
```

**Step 6**: If using Terraform to upload templates, check configuration
```hcl
# In terraform/s3/templates.tf
resource "aws_s3_object" "payment_received_template" {
  bucket       = aws_s3_bucket.templates.id
  key          = "receipts/payment_received.html"
  source       = "${path.module}/../../templates/receipts/payment_received.html"
  content_type = "text/html"
  etag         = filemd5("${path.module}/../../templates/receipts/payment_received.html")
}
```

**Step 7**: Apply Terraform to upload templates
```bash
cd terraform/s3
terraform apply -var="environment=dev"
```

**Prevention Measures**:
- Add template validation to post-deployment tests (check all 12 templates exist)
- Automate template upload in GitHub Actions deployment workflow
- Create CloudWatch alarm if Lambda reports missing templates
- Version templates in Git to track changes
- Document template upload procedures in deployment runbook

---

#### 3.2.5 Issue: S3 Cross-Region Replication Failed (PROD)

**Symptom/Error Message**:
```
Replication configuration validation failed: Objects not replicating to eu-west-1
```

**Root Cause**:
- Replication rule not configured
- Destination bucket does not exist (eu-west-1)
- IAM role for replication missing permissions
- Versioning not enabled on source or destination bucket

**Resolution Steps**:

**Step 1**: Check replication configuration
```bash
aws s3api get-bucket-replication \
  --bucket bbws-templates-prod \
  --region af-south-1
```

**Step 2**: Verify destination bucket exists
```bash
aws s3api head-bucket \
  --bucket bbws-templates-prod-dr-eu-west-1 \
  --region eu-west-1
```

**Step 3**: Check versioning on both source and destination
```bash
# Source bucket
aws s3api get-bucket-versioning \
  --bucket bbws-templates-prod \
  --region af-south-1

# Destination bucket
aws s3api get-bucket-versioning \
  --bucket bbws-templates-prod-dr-eu-west-1 \
  --region eu-west-1
```

**Step 4**: Create IAM role for replication (if missing)
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

```bash
aws iam create-role \
  --role-name S3ReplicationRole \
  --assume-role-policy-document file://s3-replication-trust-policy.json
```

**Step 5**: Attach replication policy to role
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetReplicationConfiguration",
        "s3:ListBucket"
      ],
      "Resource": "arn:aws:s3:::bbws-templates-prod"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObjectVersionForReplication",
        "s3:GetObjectVersionAcl"
      ],
      "Resource": "arn:aws:s3:::bbws-templates-prod/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:ReplicateObject",
        "s3:ReplicateDelete"
      ],
      "Resource": "arn:aws:s3:::bbws-templates-prod-dr-eu-west-1/*"
    }
  ]
}
```

**Step 6**: Configure replication rule
```bash
aws s3api put-bucket-replication \
  --bucket bbws-templates-prod \
  --region af-south-1 \
  --replication-configuration file://replication-config.json
```

**Step 7**: Test replication by uploading test file
```bash
# Upload test file to source
echo "test" > test-replication.txt
aws s3 cp test-replication.txt s3://bbws-templates-prod/test-replication.txt

# Wait 5 minutes, then check destination
sleep 300
aws s3 ls s3://bbws-templates-prod-dr-eu-west-1/test-replication.txt --region eu-west-1
```

**Prevention Measures**:
- Add replication validation to post-deployment tests (PROD only)
- Create CloudWatch alarm for replication failures
- Test DR failover quarterly
- Document replication architecture in DR runbook
- Use Terraform to manage replication configuration

---

#### 3.2.6 Issue: S3 Encryption Not Configured

**Symptom/Error Message**:
```
ServerSideEncryptionConfigurationNotFoundError: The server side encryption configuration was not found
```

**Root Cause**:
- Encryption was not enabled during bucket creation
- Terraform configuration missing encryption block
- Encryption policy was removed manually

**Resolution Steps**:

**Step 1**: Check current encryption status
```bash
aws s3api get-bucket-encryption \
  --bucket bbws-templates-dev \
  --region af-south-1
```

**Step 2**: Enable default encryption (SSE-S3)
```bash
aws s3api put-bucket-encryption \
  --bucket bbws-templates-dev \
  --region af-south-1 \
  --server-side-encryption-configuration '{
    "Rules": [
      {
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "AES256"
        },
        "BucketKeyEnabled": true
      }
    ]
  }'
```

**Step 3**: Verify encryption is enabled
```bash
aws s3api get-bucket-encryption \
  --bucket bbws-templates-dev \
  --region af-south-1 \
  --output table
```

**Step 4**: Update Terraform configuration
```hcl
# In terraform/s3/main.tf
resource "aws_s3_bucket_server_side_encryption_configuration" "templates" {
  bucket = aws_s3_bucket.templates.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}
```

**Step 5**: Apply Terraform changes
```bash
cd terraform/s3
terraform apply -var="environment=dev"
```

**Prevention Measures**:
- Add encryption validation to post-deployment tests
- Create AWS Config rule to detect unencrypted buckets
- Enable S3 default encryption at account level (if supported)
- Document encryption requirements in security runbook

---

### 3.3 CI/CD Issues

#### 3.3.1 Issue: GitHub Actions Workflow Validation Failures

**Symptom/Error Message**:
```
Error: workflow validation failed
  Line 25: invalid value for 'runs-on': ubuntu-latest-8-cores
```

**Root Cause**:
- Invalid YAML syntax in workflow file
- Unsupported GitHub Actions runner
- Missing required workflow inputs
- Invalid environment variable references

**Resolution Steps**:

**Step 1**: Validate workflow YAML syntax locally
```bash
# Install yamllint
pip install yamllint

# Validate workflow file
yamllint .github/workflows/validate-schemas.yml
```

**Step 2**: Check for common YAML issues
```bash
# Check for tabs (should use spaces)
grep -P '\t' .github/workflows/validate-schemas.yml

# Check for trailing whitespace
grep ' $' .github/workflows/validate-schemas.yml
```

**Step 3**: Fix runner specification
```yaml
# Incorrect
runs-on: ubuntu-latest-8-cores

# Correct
runs-on: ubuntu-latest
```

**Step 4**: Validate workflow using GitHub CLI
```bash
gh workflow view validate-schemas.yml
```

**Step 5**: Test workflow locally using act
```bash
# Install act (GitHub Actions local runner)
brew install act  # macOS
# or
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash

# Run workflow locally
act -W .github/workflows/validate-schemas.yml
```

**Step 6**: Push fix and monitor workflow run
```bash
git add .github/workflows/validate-schemas.yml
git commit -m "fix: correct workflow YAML syntax"
git push origin main

# Monitor workflow run
gh run watch
```

**Prevention Measures**:
- Add YAML linting to pre-commit hooks
- Use GitHub Actions workflow templates from Stage 4 outputs
- Test workflows locally with `act` before pushing
- Enable branch protection to require workflow success before merge
- Document workflow standards in CI/CD runbook

---

#### 3.3.2 Issue: Terraform Plan Failures in GitHub Actions

**Symptom/Error Message**:
```
Error: Error acquiring the state lock

Error message: ConditionalCheckFailedException: The conditional request failed
Lock Info:
  ID:        a1b2c3d4-5678-90ab-cdef-1234567890ab
  Path:      bbws-terraform-state-dev/dynamodb/terraform.tfstate
  Operation: OperationTypePlan
  Who:       runner@github-actions-runner-12345
  Version:   1.6.0
  Created:   2025-12-25 10:30:00 UTC
```

**Root Cause**:
- Terraform state is locked by another operation
- Previous workflow run did not release lock (crashed)
- Concurrent workflow runs attempting to acquire lock
- DynamoDB state lock table does not exist

**Resolution Steps**:

**Step 1**: Check if state lock table exists
```bash
aws dynamodb describe-table \
  --table-name bbws-terraform-locks \
  --region af-south-1 \
  --query 'Table.TableStatus'
```

**Step 2**: List current locks
```bash
aws dynamodb scan \
  --table-name bbws-terraform-locks \
  --region af-south-1 \
  --output table
```

**Step 3**: Identify the lock holder
```bash
aws dynamodb get-item \
  --table-name bbws-terraform-locks \
  --region af-south-1 \
  --key '{"LockID":{"S":"bbws-terraform-state-dev/dynamodb/terraform.tfstate-md5"}}' \
  --query 'Item.Info.S' \
  --output text | jq '.'
```

**Step 4**: If lock is stale (> 15 minutes old), force unlock
```bash
cd terraform/dynamodb
terraform force-unlock a1b2c3d4-5678-90ab-cdef-1234567890ab
```

**Step 5**: Cancel any stuck workflow runs
```bash
# List running workflows
gh run list --status in_progress --repo KimmyAI/2_1_bbws_dynamodb_schemas

# Cancel stuck run
gh run cancel {run-id} --repo KimmyAI/2_1_bbws_dynamodb_schemas
```

**Step 6**: Re-trigger workflow after lock is released
```bash
gh workflow run terraform-plan.yml \
  --repo KimmyAI/2_1_bbws_dynamodb_schemas \
  --ref main
```

**Prevention Measures**:
- Configure workflow concurrency to prevent parallel runs:
  ```yaml
  concurrency:
    group: terraform-${{ github.ref }}-${{ inputs.environment }}
    cancel-in-progress: false
  ```
- Add timeout to Terraform jobs (30 minutes max)
- Implement automatic stale lock cleanup (Lambda function)
- Create CloudWatch alarm for long-running Terraform operations
- Document state lock troubleshooting in deployment runbook

---

#### 3.3.3 Issue: Terraform Apply Failures in GitHub Actions

**Symptom/Error Message**:
```
Error: creating DynamoDB Table (bbws-tenants-dev): LimitExceededException:
Subscriber limit exceeded: Provisioned throughput decreases are limited within a given UTC day
```

**Root Cause**:
- DynamoDB table throughput decrease limit reached (4 decreases per day)
- Resource already exists (apply attempted twice)
- Insufficient IAM permissions for GitHub Actions role
- Terraform resource configuration error

**Resolution Steps**:

**Step 1**: Check Terraform plan output in workflow artifacts
```bash
# Download plan artifact
gh run download {run-id} --name terraform-plan-dev --repo KimmyAI/2_1_bbws_dynamodb_schemas

# View plan
terraform show tfplan-dev.binary
```

**Step 2**: If throughput limit error, check table update history
```bash
aws dynamodb describe-table \
  --table-name bbws-tenants-dev \
  --region af-south-1 \
  --query 'Table.[TableName,BillingModeSummary,ProvisionedThroughput]' \
  --output table
```

**Step 3**: For throughput limit error, wait 24 hours or switch to on-demand
```hcl
# In terraform/dynamodb/main.tf
resource "aws_dynamodb_table" "tenants" {
  name         = "bbws-tenants-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"  # Switch from PROVISIONED to PAY_PER_REQUEST
  hash_key     = "PK"
  range_key    = "SK"
  # Remove read_capacity and write_capacity
}
```

**Step 4**: Check IAM role permissions for GitHub Actions
```bash
# Get role ARN from GitHub secrets
aws iam get-role \
  --role-name bbws-terraform-deployer-dev \
  --query 'Role.Arn'

# List attached policies
aws iam list-attached-role-policies \
  --role-name bbws-terraform-deployer-dev
```

**Step 5**: If resource already exists, import into state
```bash
# Run import via GitHub Actions workflow (add import step)
# Or manually:
cd terraform/dynamodb
terraform import aws_dynamodb_table.tenants bbws-tenants-dev
```

**Step 6**: Re-run apply workflow
```bash
gh workflow run terraform-apply.yml \
  --repo KimmyAI/2_1_bbws_dynamodb_schemas \
  --ref main \
  --field environment=dev \
  --field confirmation=deploy-dev
```

**Prevention Measures**:
- Use `billing_mode = "PAY_PER_REQUEST"` to avoid throughput limits
- Add Terraform `prevent_destroy` lifecycle for production tables
- Implement `terraform plan` review before apply (approval gate)
- Create pre-deployment validation workflow
- Document Terraform troubleshooting in deployment runbook

---

#### 3.3.4 Issue: GitHub Actions Approval Timeout

**Symptom/Error Message**:
```
Error: Approval timed out after 6 hours
```

**Root Cause**:
- No approvers reviewed the deployment request within timeout period
- Approvers are unavailable (after hours, weekend)
- Notification not sent to approvers
- Wrong approvers configured in GitHub Environment

**Resolution Steps**:

**Step 1**: Check workflow run status
```bash
gh run view {run-id} --repo KimmyAI/2_1_bbws_dynamodb_schemas
```

**Step 2**: Check environment protection rules
```bash
# View in GitHub UI
open "https://github.com/KimmyAI/2_1_bbws_dynamodb_schemas/settings/environments"
```

**Step 3**: Notify approvers via Slack or email
```bash
# Send manual notification
echo "Deployment waiting for approval: https://github.com/KimmyAI/2_1_bbws_dynamodb_schemas/actions/runs/{run-id}"
```

**Step 4**: If timeout occurred, re-trigger workflow
```bash
gh workflow run terraform-apply.yml \
  --repo KimmyAI/2_1_bbws_dynamodb_schemas \
  --ref main \
  --field environment=dev \
  --field confirmation=deploy-dev
```

**Step 5**: Update environment protection rules if needed
```yaml
# In GitHub UI: Settings > Environments > dev
# Required reviewers: 1
# Deployment timeout: 6 hours (default)
# Allowed branches: main
```

**Prevention Measures**:
- Configure Slack notifications for approval requests:
  ```yaml
  - name: Notify Slack - Approval Required
    uses: slackapi/slack-github-action@v1
    with:
      channel-id: 'deployments'
      slack-message: 'Deployment approval required: ${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}'
  ```
- Set up email notifications for approvers
- Document on-call escalation procedures
- Adjust timeout period for SIT/PROD (longer timeout)
- Create deployment schedule (business hours only for PROD)

---

#### 3.3.5 Issue: Terraform State Lock Conflicts

**Symptom/Error Message**:
```
Error: Error acquiring the state lock: resource temporarily unavailable
```

**Root Cause**:
- Multiple users/workflows attempting to run Terraform concurrently
- State lock not released from previous failed operation
- DynamoDB state lock table throttling (rare)

**Resolution Steps**:

**Step 1**: Check who holds the lock
```bash
cd terraform/dynamodb
terraform force-unlock -help

# Get lock ID from error message, then check DynamoDB
aws dynamodb get-item \
  --table-name bbws-terraform-locks \
  --region af-south-1 \
  --key '{"LockID":{"S":"bbws-terraform-state-dev/dynamodb/terraform.tfstate-md5"}}'
```

**Step 2**: Verify lock is stale (check timestamp)
```bash
# Lock info includes Created timestamp
# If > 15 minutes old and operation not running, unlock
```

**Step 3**: Force unlock (use with caution)
```bash
cd terraform/dynamodb
terraform force-unlock {lock-id}
```

**Step 4**: Implement workflow concurrency control
```yaml
# In .github/workflows/terraform-apply.yml
concurrency:
  group: terraform-${{ inputs.environment }}
  cancel-in-progress: false  # Wait for previous run to complete
```

**Step 5**: Check for zombie GitHub Actions runners
```bash
gh run list --status in_progress --repo KimmyAI/2_1_bbws_dynamodb_schemas

# Cancel stuck runs
gh run cancel {run-id}
```

**Prevention Measures**:
- Implement workflow concurrency control (shown above)
- Create CloudWatch alarm for state lock duration > 10 minutes
- Document state lock procedures in deployment runbook
- Use separate Terraform workspaces for parallel dev/sit/prod work
- Coordinate deployments via deployment calendar

---

## 4. Log Analysis

### 4.1 GitHub Actions Logs

#### 4.1.1 Viewing Workflow Run Logs

**Via GitHub CLI**:
```bash
# List recent runs
gh run list --repo KimmyAI/2_1_bbws_dynamodb_schemas --limit 10

# View specific run
gh run view {run-id} --repo KimmyAI/2_1_bbws_dynamodb_schemas --log

# Download logs
gh run download {run-id} --repo KimmyAI/2_1_bbws_dynamodb_schemas
```

**Via GitHub UI**:
1. Navigate to `https://github.com/KimmyAI/2_1_bbws_dynamodb_schemas/actions`
2. Click on workflow run
3. Click on job name to view logs
4. Use search box to filter log lines

#### 4.1.2 Common Log Patterns

**Success Pattern**:
```
✓ Terraform initialized successfully
✓ Terraform plan completed (5 resources to add, 0 to change, 0 to destroy)
✓ Terraform apply completed successfully
✓ Post-deployment tests passed (24/24)
```

**Failure Pattern - DynamoDB**:
```
✗ Error: Error creating DynamoDB Table (bbws-tenants-dev): ResourceInUseException
  Terraform will perform the following actions:
    # aws_dynamodb_table.tenants will be created
  Error: table already exists
```

**Failure Pattern - S3**:
```
✗ Error: Error creating S3 bucket: BucketAlreadyExists
  The requested bucket name is not available
  Bucket: bbws-templates-dev
```

**Failure Pattern - IAM**:
```
✗ Error: AccessDeniedException: User is not authorized to perform: dynamodb:CreateTable
  IAM Role: arn:aws:iam::536580886816:role/bbws-terraform-deployer-dev
  Missing permissions: dynamodb:CreateTable
```

### 4.2 CloudWatch Logs

#### 4.2.1 Lambda Function Logs (if applicable)

**Tail logs in real-time**:
```bash
aws logs tail /aws/lambda/bbws-order-lambda-dev \
  --region af-south-1 \
  --follow \
  --format short
```

**Query errors from last hour**:
```bash
aws logs filter-log-events \
  --log-group-name /aws/lambda/bbws-order-lambda-dev \
  --region af-south-1 \
  --filter-pattern "ERROR" \
  --start-time $(date -u -d '1 hour ago' +%s)000
```

**Common Lambda error patterns**:
```
# S3 template not found
[ERROR] NoSuchKey: The specified key does not exist. Key: receipts/payment_received.html

# DynamoDB access denied
[ERROR] AccessDeniedException: User is not authorized to perform: dynamodb:PutItem

# DynamoDB table not found
[ERROR] ResourceNotFoundException: Requested resource not found: Table: bbws-tenants-dev not found
```

#### 4.2.2 CloudWatch Insights Queries

**Query all DynamoDB errors**:
```sql
fields @timestamp, @message
| filter @message like /DynamoDB/
| filter @message like /Error|Exception/
| sort @timestamp desc
| limit 100
```

**Query S3 access errors**:
```sql
fields @timestamp, @message
| filter @message like /S3/
| filter @message like /NoSuchBucket|AccessDenied|NoSuchKey/
| sort @timestamp desc
| limit 100
```

**Query slow DynamoDB queries**:
```sql
fields @timestamp, @message, @duration
| filter @message like /DynamoDB Query/
| filter @duration > 1000
| sort @duration desc
| limit 50
```

### 4.3 Terraform Logs

#### 4.3.1 Enabling Terraform Debug Logging

**Local Terraform debugging**:
```bash
export TF_LOG=DEBUG
export TF_LOG_PATH=./terraform-debug.log
terraform plan -var="environment=dev"
```

**In GitHub Actions workflow**:
```yaml
- name: Terraform Plan
  env:
    TF_LOG: DEBUG
  run: terraform plan -var="environment=${{ inputs.environment }}"
```

#### 4.3.2 Common Terraform Log Patterns

**Resource creation success**:
```
aws_dynamodb_table.tenants: Creating...
aws_dynamodb_table.tenants: Still creating... [10s elapsed]
aws_dynamodb_table.tenants: Creation complete after 15s [id=bbws-tenants-dev]
```

**Resource already exists error**:
```
aws_dynamodb_table.tenants: Creating...
Error: ResourceInUseException: Table already exists: bbws-tenants-dev
  with aws_dynamodb_table.tenants,
  on main.tf line 10, in resource "aws_dynamodb_table" "tenants":
  10: resource "aws_dynamodb_table" "tenants" {
```

**IAM permission error**:
```
Error: error creating DynamoDB Table: AccessDeniedException:
User: arn:aws:sts::536580886816:assumed-role/bbws-terraform-deployer-dev/GitHubActions
is not authorized to perform: dynamodb:CreateTable
```

---

## 5. Health Checks

### 5.1 DynamoDB Health Check Script

**Create health check script: `scripts/health-check-dynamodb.sh`**:
```bash
#!/bin/bash
# Health check for DynamoDB tables

ENV=${1:-dev}
REGION="af-south-1"
TABLES=("bbws-tenants-$ENV" "bbws-products-$ENV" "bbws-campaigns-$ENV")

echo "=== DynamoDB Health Check for $ENV Environment ==="
echo ""

for TABLE in "${TABLES[@]}"; do
  echo "Checking table: $TABLE"

  # Check table exists
  STATUS=$(aws dynamodb describe-table \
    --table-name $TABLE \
    --region $REGION \
    --query 'Table.TableStatus' \
    --output text 2>/dev/null)

  if [ $? -ne 0 ]; then
    echo "  ✗ Table does not exist"
    continue
  fi

  echo "  ✓ Table status: $STATUS"

  # Check PITR
  PITR=$(aws dynamodb describe-continuous-backups \
    --table-name $TABLE \
    --region $REGION \
    --query 'ContinuousBackupsDescription.PointInTimeRecoveryDescription.PointInTimeRecoveryStatus' \
    --output text)
  echo "  ✓ PITR: $PITR"

  # Check GSI count
  GSI_COUNT=$(aws dynamodb describe-table \
    --table-name $TABLE \
    --region $REGION \
    --query 'length(Table.GlobalSecondaryIndexes)' \
    --output text)
  echo "  ✓ GSI count: $GSI_COUNT"

  # Check item count (approximate)
  ITEM_COUNT=$(aws dynamodb describe-table \
    --table-name $TABLE \
    --region $REGION \
    --query 'Table.ItemCount' \
    --output text)
  echo "  ✓ Item count: $ITEM_COUNT"

  echo ""
done

echo "=== Health Check Complete ==="
```

**Run health check**:
```bash
chmod +x scripts/health-check-dynamodb.sh
./scripts/health-check-dynamodb.sh dev
```

### 5.2 S3 Health Check Script

**Create health check script: `scripts/health-check-s3.sh`**:
```bash
#!/bin/bash
# Health check for S3 buckets

ENV=${1:-dev}
REGION="af-south-1"
BUCKET="bbws-templates-$ENV"

echo "=== S3 Health Check for $ENV Environment ==="
echo ""

echo "Checking bucket: $BUCKET"

# Check bucket exists
aws s3api head-bucket --bucket $BUCKET --region $REGION 2>/dev/null
if [ $? -ne 0 ]; then
  echo "  ✗ Bucket does not exist"
  exit 1
fi
echo "  ✓ Bucket exists"

# Check versioning
VERSIONING=$(aws s3api get-bucket-versioning \
  --bucket $BUCKET \
  --region $REGION \
  --query 'Status' \
  --output text)
echo "  ✓ Versioning: $VERSIONING"

# Check encryption
ENCRYPTION=$(aws s3api get-bucket-encryption \
  --bucket $BUCKET \
  --region $REGION \
  --query 'ServerSideEncryptionConfiguration.Rules[0].ApplyServerSideEncryptionByDefault.SSEAlgorithm' \
  --output text 2>/dev/null)
echo "  ✓ Encryption: $ENCRYPTION"

# Check public access block
PUBLIC_ACCESS=$(aws s3api get-public-access-block \
  --bucket $BUCKET \
  --region $REGION \
  --query 'PublicAccessBlockConfiguration.BlockPublicAcls' \
  --output text)
echo "  ✓ Public access blocked: $PUBLIC_ACCESS"

# Count objects
OBJECT_COUNT=$(aws s3 ls s3://$BUCKET/ --recursive | wc -l)
echo "  ✓ Object count: $OBJECT_COUNT"

# Check for required templates (12 templates)
REQUIRED_TEMPLATES=(
  "receipts/payment_received.html"
  "receipts/order_confirmation.html"
  "notifications/welcome.html"
  "notifications/account_created.html"
  "marketing/campaign_announcement.html"
  "marketing/special_offer.html"
  "billing/invoice.html"
  "billing/payment_reminder.html"
  "support/ticket_created.html"
  "support/ticket_resolved.html"
  "admin/new_tenant_notification.html"
  "admin/daily_summary.html"
)

MISSING_COUNT=0
for TEMPLATE in "${REQUIRED_TEMPLATES[@]}"; do
  aws s3 ls s3://$BUCKET/$TEMPLATE &>/dev/null
  if [ $? -ne 0 ]; then
    echo "  ✗ Missing template: $TEMPLATE"
    MISSING_COUNT=$((MISSING_COUNT + 1))
  fi
done

if [ $MISSING_COUNT -eq 0 ]; then
  echo "  ✓ All 12 required templates present"
else
  echo "  ✗ Missing $MISSING_COUNT templates"
fi

echo ""
echo "=== Health Check Complete ==="
```

**Run health check**:
```bash
chmod +x scripts/health-check-s3.sh
./scripts/health-check-s3.sh dev
```

### 5.3 Combined Infrastructure Health Check

**Create master health check script: `scripts/health-check-all.sh`**:
```bash
#!/bin/bash
# Master health check for all infrastructure

ENV=${1:-dev}

echo "==================================================================="
echo "  BBWS Infrastructure Health Check - $ENV Environment"
echo "==================================================================="
echo ""

# Run DynamoDB health check
./scripts/health-check-dynamodb.sh $ENV
DYNAMODB_STATUS=$?

echo ""

# Run S3 health check
./scripts/health-check-s3.sh $ENV
S3_STATUS=$?

echo ""

# Summary
echo "==================================================================="
echo "  Health Check Summary"
echo "==================================================================="
if [ $DYNAMODB_STATUS -eq 0 ] && [ $S3_STATUS -eq 0 ]; then
  echo "  ✓ All systems healthy"
  exit 0
else
  echo "  ✗ Some systems unhealthy"
  [ $DYNAMODB_STATUS -ne 0 ] && echo "    - DynamoDB: UNHEALTHY"
  [ $S3_STATUS -ne 0 ] && echo "    - S3: UNHEALTHY"
  exit 1
fi
```

**Run master health check**:
```bash
chmod +x scripts/health-check-all.sh
./scripts/health-check-all.sh dev
```

---

## 6. Escalation Procedures

### 6.1 Escalation Matrix

| Severity | Issue Type | First Responder | Escalate To | Escalation Time | Final Escalation |
|----------|-----------|----------------|-------------|-----------------|------------------|
| **P1 - Critical** | Production outage, data loss | On-call DevOps Engineer | Tech Lead | 15 minutes | Product Owner |
| **P2 - High** | Deployment failure (PROD), security breach | DevOps Engineer | Tech Lead | 30 minutes | Product Owner |
| **P3 - Medium** | Deployment failure (SIT), performance degradation | Developer | DevOps Lead | 2 hours | Tech Lead |
| **P4 - Low** | Deployment failure (DEV), documentation issues | Developer | Team Lead | 1 business day | N/A |

### 6.2 Escalation Criteria

#### 6.2.1 When to Escalate

**Immediate Escalation (P1)**:
- Production DynamoDB tables inaccessible for > 5 minutes
- Production S3 buckets deleted or inaccessible
- Data loss or corruption detected
- Security breach or unauthorized access
- Cross-region replication failure in PROD

**Escalate within 30 minutes (P2)**:
- PROD deployment failed and cannot be rolled back
- Multiple failed rollback attempts
- DynamoDB backup restoration required
- IAM role compromise suspected
- Terraform state corruption

**Escalate within 2 hours (P3)**:
- SIT deployment blocked > 4 hours
- Recurring GitHub Actions failures
- Terraform state lock conflicts for > 1 hour
- DynamoDB throttling impacting applications
- S3 template sync failures

### 6.3 Contact Information

**DevOps Team**:
- On-call rotation: Check PagerDuty schedule
- Slack channel: `#devops-alerts`
- Email: `devops@kimmyai.com`

**Technical Leadership**:
- Tech Lead: Tebogo (tebogo@kimmyai.com, +27-XXX-XXX-XXXX)
- DevOps Lead: (TBD)
- Product Owner: (TBD)

**AWS Support**:
- Support plan: Business (Response time: < 1 hour for urgent issues)
- Support console: `https://console.aws.amazon.com/support/home`
- Support cases: Create via AWS Console or CLI

### 6.4 Escalation Workflow

**Step 1**: Document the issue
- Copy error messages
- Capture screenshots
- Record timeline of events
- Identify affected environment (dev/sit/prod)

**Step 2**: Attempt self-resolution (5-15 minutes)
- Check this troubleshooting runbook
- Review recent changes (Git log)
- Check monitoring dashboards

**Step 3**: Notify team (if not resolved)
- Post in Slack channel with severity tag
- Include error messages and attempted solutions
- Tag relevant team members

**Step 4**: Escalate per matrix (if not resolved within escalation time)
- Contact next level directly (Slack DM + phone call for P1/P2)
- Provide issue summary and timeline
- Share access to logs and dashboards

**Step 5**: Engage AWS Support (if needed)
- Create AWS Support case
- Attach CloudWatch logs, Terraform outputs
- Reference AWS resource ARNs

**Step 6**: Post-incident review (after resolution)
- Document root cause
- Identify prevention measures
- Update runbooks
- Create tickets for long-term fixes

### 6.5 Emergency Contacts

**AWS Account Owners**:
- DEV (536580886816): Tebogo
- SIT (815856636111): Tebogo
- PROD (093646564004): Tebogo

**Business Hours**: Monday-Friday, 08:00-17:00 SAST (UTC+2)

**After-Hours Support**: On-call rotation (PagerDuty)

### 6.6 Incident Communication Template

**Slack/Email Template**:
```
🚨 [P{severity}] {Brief issue description}

Environment: {dev/sit/prod}
Component: {DynamoDB/S3/CI-CD}
Impact: {User-facing impact}
Started: {Timestamp}

Symptoms:
- {Symptom 1}
- {Symptom 2}

Error Messages:
```
{Paste error logs}
```

Attempted Solutions:
- {Action 1} - {Result}
- {Action 2} - {Result}

Current Status: {Investigating/Mitigated/Resolved}

Next Steps:
- {Action}

Resources:
- GitHub Actions: {link}
- CloudWatch Logs: {link}
- AWS Console: {link}
```

---

## Appendix A: Quick Reference Commands

### A.1 DynamoDB Quick Commands
```bash
# List all tables
aws dynamodb list-tables --region af-south-1

# Describe table
aws dynamodb describe-table --table-name bbws-tenants-{env} --region af-south-1

# Check PITR
aws dynamodb describe-continuous-backups --table-name bbws-tenants-{env} --region af-south-1

# Query by email
aws dynamodb query --table-name bbws-tenants-{env} --index-name email-index \
  --key-condition-expression "email = :email" \
  --expression-attribute-values '{":email":{"S":"user@example.com"}}'
```

### A.2 S3 Quick Commands
```bash
# Check bucket exists
aws s3api head-bucket --bucket bbws-templates-{env}

# List objects
aws s3 ls s3://bbws-templates-{env}/ --recursive

# Check versioning
aws s3api get-bucket-versioning --bucket bbws-templates-{env}

# Check encryption
aws s3api get-bucket-encryption --bucket bbws-templates-{env}

# Download object
aws s3 cp s3://bbws-templates-{env}/path/to/file.html /tmp/
```

### A.3 GitHub Actions Quick Commands
```bash
# List workflow runs
gh run list --repo KimmyAI/2_1_bbws_dynamodb_schemas --limit 10

# View run logs
gh run view {run-id} --log

# Cancel run
gh run cancel {run-id}

# Trigger workflow
gh workflow run terraform-apply.yml --field environment=dev --field confirmation=deploy-dev
```

### A.4 Terraform Quick Commands
```bash
# Show state
terraform state list

# Show resource
terraform state show aws_dynamodb_table.tenants

# Force unlock
terraform force-unlock {lock-id}

# Import resource
terraform import aws_dynamodb_table.tenants bbws-tenants-dev
```

---

## Appendix B: Useful Links

**AWS Console**:
- DynamoDB: `https://af-south-1.console.aws.amazon.com/dynamodbv2/home?region=af-south-1`
- S3: `https://s3.console.aws.amazon.com/s3/buckets?region=af-south-1`
- CloudWatch: `https://af-south-1.console.aws.amazon.com/cloudwatch/home?region=af-south-1`
- AWS Backup: `https://af-south-1.console.aws.amazon.com/backup/home?region=af-south-1`

**GitHub**:
- DynamoDB Repo: `https://github.com/KimmyAI/2_1_bbws_dynamodb_schemas`
- S3 Repo: `https://github.com/KimmyAI/2_1_bbws_s3_schemas`
- Actions: `https://github.com/KimmyAI/2_1_bbws_dynamodb_schemas/actions`

**Documentation**:
- LLD: `2.1.8_LLD_S3_and_DynamoDB.md`
- Deployment Runbook: `2.1.8_Deployment_Runbook.md`
- Promotion Runbook: `2.1.8_Promotion_Runbook.md`
- Rollback Runbook: `2.1.8_Rollback_Runbook.md`

---

**Document Version**: 1.0
**Last Updated**: 2025-12-25
**Owner**: DevOps Team
**Review Cycle**: Quarterly
