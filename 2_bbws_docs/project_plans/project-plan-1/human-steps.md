# Human Testing Steps - DEV Pipeline Deployment

**Pipeline**: GitHub Actions DEV Deployment for S3 and DynamoDB
**Environment**: DEV (AWS Account 536580886816, eu-west-1)
**Estimated Time**: 15-20 minutes
**Last Updated**: 2025-12-25

---

## Prerequisites Checklist

Before starting, verify you have:

- [ ] AWS CLI installed and configured
- [ ] AWS credentials for DEV account (536580886816)
- [ ] GitHub account with admin access to the repository
- [ ] Git installed locally
- [ ] Python 3.x installed (for local validation testing)

---

## Step 1: Verify AWS CLI Access (2 minutes)

### Test AWS Connectivity

```bash
# Configure AWS profile for DEV
aws configure --profile dev

# Verify access to DEV account
aws sts get-caller-identity --profile dev
```

**Expected Output**:
```json
{
    "UserId": "...",
    "Account": "536580886816",
    "Arn": "arn:aws:iam::536580886816:user/your-username"
}
```

**Checkpoint**: Account ID must be `536580886816`

---

## Step 2: Create AWS Infrastructure (5 minutes)

### Create Terraform State Bucket

```bash
# Create S3 bucket for Terraform state in eu-west-1
aws s3api create-bucket \
  --bucket bbws-terraform-state-dev \
  --region eu-west-1 \
  --create-bucket-configuration LocationConstraint=eu-west-1 \
  --profile dev

# Enable versioning on state bucket
aws s3api put-bucket-versioning \
  --bucket bbws-terraform-state-dev \
  --versioning-configuration Status=Enabled \
  --profile dev

# Verify bucket created
aws s3 ls --profile dev | grep bbws-terraform-state-dev
```

### Create DynamoDB Lock Table

```bash
# Create DynamoDB table for state locking in eu-west-1
aws dynamodb create-table \
  --table-name terraform-state-lock-dev \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region eu-west-1 \
  --profile dev

# Verify table created
aws dynamodb describe-table \
  --table-name terraform-state-lock-dev \
  --region eu-west-1 \
  --profile dev
```

**Checkpoint**: Both bucket and table created successfully in `eu-west-1`

---

## Step 3: Create AWS IAM Role for GitHub Actions (5 minutes)

### Create OIDC Provider (One-Time Setup)

```bash
# Create GitHub OIDC provider (only once per AWS account)
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
  --profile dev
```

### Create IAM Role Trust Policy

**Save this as `trust-policy.json`** (replace `YOUR_GITHUB_ORG` with your actual GitHub username/org):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::536580886816:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:YOUR_GITHUB_ORG/*:*"
        }
      }
    }
  ]
}
```

### Create IAM Role

```bash
# Create the IAM role
aws iam create-role \
  --role-name bbws-terraform-deployer-dev \
  --assume-role-policy-document file://trust-policy.json \
  --profile dev
```

### Attach Permissions

```bash
# DynamoDB full access
aws iam attach-role-policy \
  --role-name bbws-terraform-deployer-dev \
  --policy-arn arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess \
  --profile dev

# S3 full access
aws iam attach-role-policy \
  --role-name bbws-terraform-deployer-dev \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess \
  --profile dev

# CloudWatch Logs
aws iam attach-role-policy \
  --role-name bbws-terraform-deployer-dev \
  --policy-arn arn:aws:iam::aws:policy/CloudWatchLogsFullAccess \
  --profile dev
```

**Checkpoint**: IAM role `bbws-terraform-deployer-dev` created with correct trust policy and permissions

---

## Step 4: Configure GitHub Repository (3 minutes)

### Add GitHub Secret

1. Go to your GitHub repository
2. Navigate to: `Settings` → `Secrets and variables` → `Actions`
3. Click `New repository secret`
4. Add the following secret:
   - **Name**: `AWS_ROLE_DEV`
   - **Value**: `arn:aws:iam::536580886816:role/bbws-terraform-deployer-dev`
5. Click `Add secret`

### Create GitHub Environment (Optional for DEV)

1. Go to: `Settings` → `Environments` → `New environment`
2. **Name**: `dev`
3. Click `Configure environment`
4. No protection rules needed for DEV (instant deployment)
5. Click `Save protection rules`

**Checkpoint**: GitHub secret `AWS_ROLE_DEV` configured

---

## Step 5: Copy Pipeline Files to Repository (2 minutes)

### For DynamoDB Repository

```bash
# Navigate to your DynamoDB repository
cd /path/to/2_1_bbws_dynamodb_schemas

# Copy workflow
mkdir -p .github/workflows
cp /Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/project-plan-1/github-workflows-ready-to-deploy/.github/workflows/deploy-dev.yml .github/workflows/

# Copy validation scripts
mkdir -p scripts
cp /Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/project-plan-1/github-workflows-ready-to-deploy/scripts/validate_dynamodb_dev.py scripts/

# Commit and push
git add .github/ scripts/
git commit -m "Add DEV deployment pipeline"
git push origin main
```

### For S3 Repository

```bash
# Navigate to your S3 repository
cd /path/to/2_1_bbws_s3_schemas

# Copy workflow
mkdir -p .github/workflows
cp /Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/project-plan-1/github-workflows-ready-to-deploy/.github/workflows/deploy-dev.yml .github/workflows/

# Copy validation scripts
mkdir -p scripts
cp /Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/project-plan-1/github-workflows-ready-to-deploy/scripts/validate_s3_dev.py scripts/

# Commit and push
git add .github/ scripts/
git commit -m "Add DEV deployment pipeline"
git push origin main
```

**Checkpoint**: Workflow and validation scripts committed to repository

---

## Step 6: Verify Terraform Code Exists (1 minute)

Your repository should have this structure:

```
2_1_bbws_dynamodb_schemas/          # or 2_1_bbws_s3_schemas
├── .github/
│   └── workflows/
│       └── deploy-dev.yml          ✅ Copied
├── terraform/
│   ├── dynamodb/                   ⚠️ MUST EXIST
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── environments/
│   │       └── dev.tfvars          ⚠️ MUST EXIST
│   └── s3/                         ⚠️ MUST EXIST (for S3 repo)
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── environments/
│           └── dev.tfvars          ⚠️ MUST EXIST
└── scripts/
    └── validate_dynamodb_dev.py    ✅ Copied
```

**If Terraform code doesn't exist**, you need to create it from Stage 3 outputs:
- See: `stage-3-infrastructure-code/worker-2-terraform-dynamodb-module/output.md`
- See: `stage-3-infrastructure-code/worker-3-terraform-s3-module/output.md`

**Checkpoint**: Terraform code exists with dev.tfvars

---

## Step 7: Trigger Deployment Workflow (1 minute)

### Option A: Via GitHub UI

1. Go to your GitHub repository
2. Click **`Actions`** tab
3. Select **`Deploy to DEV`** workflow (left sidebar)
4. Click **`Run workflow`** button (right side)
5. Fill in the form:
   - **Component**: Select `dynamodb` (or `s3` or `both`)
   - **Skip validation**: Leave **unchecked** (we want validation)
6. Click **`Run workflow`** (green button)

### Option B: Via GitHub CLI

```bash
# Install GitHub CLI (if not already installed)
# https://cli.github.com/

# Trigger workflow for DynamoDB
gh workflow run deploy-dev.yml -f component=dynamodb -f skip_validation=false

# Trigger workflow for S3
gh workflow run deploy-dev.yml -f component=s3 -f skip_validation=false

# Trigger workflow for both
gh workflow run deploy-dev.yml -f component=both -f skip_validation=false
```

**Checkpoint**: Workflow triggered successfully

---

## Step 8: Monitor Deployment (4-6 minutes)

### Watch Workflow Progress

1. Go to: `Actions` → `Deploy to DEV` → Click on the running workflow
2. Monitor the following stages:
   - **Deploy DynamoDB** (2-3 minutes) - Terraform init, plan, apply
   - **Deploy S3** (1-2 minutes) - Terraform init, plan, apply
   - **Validate DynamoDB** (30 seconds) - 8 validation checks
   - **Validate S3** (30 seconds) - 6 validation checks
   - **Summary** - Deployment results

### Expected Success Output

```
================================================================================
DEV DEPLOYMENT SUMMARY
================================================================================
Component: dynamodb
Environment: DEV
AWS Account: 536580886816
Region: eu-west-1

Job Results:
  DynamoDB Deploy: success
  S3 Deploy: skipped
  DynamoDB Validation: success
  S3 Validation: skipped

Workflow Run: 123456789
Triggered by: your-username
================================================================================
✅ DEPLOYMENT SUCCESSFUL
```

**Checkpoint**: All jobs completed successfully

---

## Step 9: Verify Resources in AWS Console (2 minutes)

### DynamoDB Tables

**AWS Console**: https://console.aws.amazon.com/dynamodbv2/home?region=eu-west-1#tables

**CLI Verification**:

```bash
# List tables in eu-west-1
aws dynamodb list-tables --region eu-west-1 --profile dev

# Describe tenants table
aws dynamodb describe-table --table-name tenants --region eu-west-1 --profile dev
```

**Expected Output**:
```json
{
    "Table": {
        "TableName": "tenants",
        "TableStatus": "ACTIVE",
        "KeySchema": [
            {"AttributeName": "PK", "KeyType": "HASH"},
            {"AttributeName": "SK", "KeyType": "RANGE"}
        ],
        "BillingModeSummary": {
            "BillingMode": "PAY_PER_REQUEST"
        },
        "GlobalSecondaryIndexes": [
            {"IndexName": "EmailIndex", "IndexStatus": "ACTIVE"},
            {"IndexName": "TenantStatusIndex", "IndexStatus": "ACTIVE"},
            {"IndexName": "ActiveIndex", "IndexStatus": "ACTIVE"}
        ]
    }
}
```

### S3 Buckets

**AWS Console**: https://console.aws.amazon.com/s3/home?region=eu-west-1

**CLI Verification**:

```bash
# List buckets
aws s3 ls --profile dev | grep bbws

# Check bucket versioning
aws s3api get-bucket-versioning --bucket bbws-templates-dev --profile dev

# Check bucket location
aws s3api get-bucket-location --bucket bbws-templates-dev --profile dev
```

**Expected Output**:
```json
{
    "Status": "Enabled"
}
```

```json
{
    "LocationConstraint": "eu-west-1"
}
```

**Checkpoint**: All resources exist in `eu-west-1` and are configured correctly

---

## Step 10: Test Validation Scripts Locally (Optional) (2 minutes)

### Install Dependencies

```bash
pip install boto3
```

### Run DynamoDB Validation

```bash
# Configure AWS credentials
export AWS_PROFILE=dev

# Run DynamoDB validation
cd /path/to/repository
python3 scripts/validate_dynamodb_dev.py
```

**Expected Output**:

```
================================================================================
DYNAMODB VALIDATION - DEV ENVIRONMENT
================================================================================
Region: eu-west-1
AWS Account: 536580886816
Expected Tables: 3
✓ Connected to AWS account: 536580886816

--------------------------------------------------------------------------------
VALIDATING TABLE: tenants
--------------------------------------------------------------------------------
✓ Table 'tenants' exists
✓ Table 'tenants' status: ACTIVE
✓ Table 'tenants' has correct primary key (PK: PK, SK: SK)
✓ Table 'tenants' has correct GSIs: EmailIndex, TenantStatusIndex, ActiveIndex
✓ Table 'tenants' PITR: ENABLED
✓ Table 'tenants' Streams: ENABLED (NEW_AND_OLD_IMAGES)
✓ Table 'tenants' billing mode: ON_DEMAND
✓ Table 'tenants' has all required tags

Table 'tenants' validation: 8/8 tests passed

...

================================================================================
VALIDATION SUMMARY
================================================================================
✅ PASS - tenants
✅ PASS - products
✅ PASS - campaigns

Overall: 3/3 tables validated successfully

✅ ALL DYNAMODB VALIDATIONS PASSED
```

### Run S3 Validation

```bash
# Run S3 validation
python3 scripts/validate_s3_dev.py
```

**Checkpoint**: All validation tests pass locally

---

## Success Criteria

Mark each item as complete:

- [ ] AWS CLI configured for DEV account (536580886816)
- [ ] S3 state bucket `bbws-terraform-state-dev` created in `eu-west-1`
- [ ] DynamoDB lock table `terraform-state-lock-dev` created in `eu-west-1`
- [ ] AWS OIDC provider created
- [ ] IAM role `bbws-terraform-deployer-dev` created
- [ ] GitHub secret `AWS_ROLE_DEV` configured
- [ ] Workflow file copied to `.github/workflows/`
- [ ] Validation scripts copied to `scripts/`
- [ ] Terraform code exists in `terraform/dynamodb/` or `terraform/s3/`
- [ ] `environments/dev.tfvars` file exists
- [ ] Workflow triggered successfully
- [ ] All workflow jobs completed (Deploy + Validate)
- [ ] DynamoDB tables created in `eu-west-1` (if deployed)
- [ ] S3 buckets created in `eu-west-1` (if deployed)
- [ ] All validation checks passed (8 for DynamoDB, 6 for S3)
- [ ] Resources visible in AWS Console

---

## Troubleshooting

### Issue: "Role cannot be assumed"

**Symptom**: Workflow fails with "Unable to assume role"

**Fix**:
```bash
# Verify OIDC provider exists
aws iam list-open-id-connect-providers --profile dev

# Check IAM role trust policy
aws iam get-role --role-name bbws-terraform-deployer-dev --profile dev

# Verify GitHub repository name matches trust policy condition
```

### Issue: "Backend initialization failed"

**Symptom**: Terraform init fails with "Error loading backend config"

**Fix**:
```bash
# Verify state bucket exists in eu-west-1
aws s3 ls --profile dev | grep bbws-terraform-state-dev

# Verify lock table exists in eu-west-1
aws dynamodb describe-table --table-name terraform-state-lock-dev --region eu-west-1 --profile dev
```

### Issue: "Validation failed - Table not found"

**Symptom**: Deployment succeeds but validation fails

**Fix**:
```bash
# Wait 30 seconds for eventual consistency
sleep 30

# Check tables exist in eu-west-1
aws dynamodb list-tables --region eu-west-1 --profile dev

# Run validation manually
python3 scripts/validate_dynamodb_dev.py
```

### Issue: "Wrong region"

**Symptom**: Resources created in af-south-1 instead of eu-west-1

**Fix**:
- Verify workflow file has `AWS_REGION: eu-west-1`
- Verify validation scripts have `REGION = 'eu-west-1'`
- Check Terraform backend configuration points to `eu-west-1`
- Destroy resources in wrong region:
  ```bash
  # Destroy in af-south-1 (if created there by mistake)
  cd terraform/dynamodb
  terraform destroy -var-file=environments/dev.tfvars
  ```

---

## Next Steps After Successful Deployment

1. **Upload HTML Templates** (for S3):
   ```bash
   aws s3 sync ./templates/ s3://bbws-templates-dev/templates/ --region eu-west-1 --profile dev
   ```

2. **Test DynamoDB Access**:
   ```bash
   # Insert test tenant
   aws dynamodb put-item \
     --table-name tenants \
     --item '{"PK":{"S":"TENANT#test"},"SK":{"S":"METADATA"},"email":{"S":"test@example.com"},"active":{"BOOL":true}}' \
     --region eu-west-1 \
     --profile dev

   # Query test tenant
   aws dynamodb get-item \
     --table-name tenants \
     --key '{"PK":{"S":"TENANT#test"},"SK":{"S":"METADATA"}}' \
     --region eu-west-1 \
     --profile dev
   ```

3. **Prepare SIT Deployment**:
   - Create similar workflow for SIT environment
   - Change AWS account ID to `815856636111`
   - Keep region as `eu-west-1`
   - Add 2 required approvers for SIT

4. **Integration Testing**:
   - Test Lambda functions can read/write to DynamoDB
   - Test Lambda functions can read templates from S3

---

## Important Reminders

- **DEV Region**: `eu-west-1` (Ireland)
- **SIT Region**: `eu-west-1` (Ireland)
- **PROD Primary Region**: `af-south-1` (Cape Town)
- **PROD DR Region**: `eu-west-1` (Ireland)

- **No Approval Gates for DEV** - Instant deployment
- **2 Approvers for SIT** - Moderate control
- **3 Approvers for PROD** - Strict control

- **Never commit AWS credentials** - Use OIDC only
- **All S3 buckets block public access**
- **DynamoDB tables use ON_DEMAND billing**
- **Terraform state stored in S3 with DynamoDB locking**

---

**Testing Time**: 15-20 minutes
**Status**: Ready for DEV deployment
**Last Updated**: 2025-12-25
