# GitHub Actions Pipeline for DEV Deployment

This directory contains GitHub Actions workflows and validation scripts for deploying S3 and DynamoDB infrastructure to DEV environment.

**Status**: ✅ Ready to deploy
**Environment**: DEV only (AWS Account 536580886816, eu-west-1)
**Last Updated**: 2025-12-25

**Region Configuration**:
- DEV: eu-west-1 (Ireland)
- SIT: eu-west-1 (Ireland)
- PROD Primary: af-south-1 (Cape Town)
- PROD DR: eu-west-1 (Ireland)

---

## 📁 Directory Structure

```
github-workflows-ready-to-deploy/
├── .github/
│   └── workflows/
│       └── deploy-dev.yml          # Main deployment workflow
├── scripts/
│   ├── validate_dynamodb_dev.py   # DynamoDB validation script
│   └── validate_s3_dev.py          # S3 validation script
└── README.md                       # This file
```

---

## 🚀 Quick Start

### 1. Copy Files to Your Repository

Copy the workflow and scripts to your repository:

```bash
# For DynamoDB repository
cp -r .github/ /path/to/2_1_bbws_dynamodb_schemas/
cp -r scripts/ /path/to/2_1_bbws_dynamodb_schemas/

# For S3 repository
cp -r .github/ /path/to/2_1_bbws_s3_schemas/
cp -r scripts/ /path/to/2_1_bbws_s3_schemas/
```

### 2. Configure GitHub Secrets

Add the following secret to your GitHub repository:

**Navigate to**: `Settings` → `Secrets and variables` → `Actions` → `New repository secret`

| Secret Name | Value | Description |
|-------------|-------|-------------|
| `AWS_ROLE_DEV` | `arn:aws:iam::536580886816:role/bbws-terraform-deployer-dev` | AWS IAM role ARN for DEV deployment |

### 3. Set Up GitHub Environment (Optional but Recommended)

Create a GitHub environment for approval gates (optional for DEV):

1. Go to `Settings` → `Environments` → `New environment`
2. Name: `dev`
3. Environment protection rules (optional for DEV):
   - ☐ Required reviewers: 0 (or add reviewers if you want approval gates)
   - ☐ Wait timer: 0 minutes
4. Save environment

### 4. Create AWS OIDC Provider (If Not Exists)

If you haven't set up AWS OIDC authentication for GitHub Actions:

```bash
# Run this AWS CLI command (only once per AWS account)
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
  --region eu-west-1
```

### 5. Create IAM Role for GitHub Actions

Create IAM role `bbws-terraform-deployer-dev` with trust policy:

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
          "token.actions.githubusercontent.com:sub": "repo:YOUR_GITHUB_ORG/2_1_bbws_*_schemas:*"
        }
      }
    }
  ]
}
```

**Replace `YOUR_GITHUB_ORG`** with your actual GitHub organization/username.

**Permissions Policy** (attach to the role):
- DynamoDB: Full access to tables (create, update, describe, tag)
- S3: Full access to buckets (create, configure, upload)
- CloudWatch: Create log groups
- Terraform State: Read/write to state bucket and lock table

---

## 🎯 How to Deploy

### Option 1: Deploy Both DynamoDB and S3

1. Go to your GitHub repository
2. Click `Actions` tab
3. Select `Deploy to DEV` workflow
4. Click `Run workflow`
5. Fill in the form:
   - **Component**: Select `both`
   - **Skip validation**: Leave unchecked (false)
6. Click `Run workflow`

### Option 2: Deploy Only DynamoDB

1. Go to `Actions` → `Deploy to DEV`
2. Click `Run workflow`
3. Select:
   - **Component**: `dynamodb`
   - **Skip validation**: false
4. Click `Run workflow`

### Option 3: Deploy Only S3

1. Go to `Actions` → `Deploy to DEV`
2. Click `Run workflow`
3. Select:
   - **Component**: `s3`
   - **Skip validation**: false
4. Click `Run workflow`

---

## 📊 What Happens During Deployment

### Workflow Stages

```
1. Deploy DynamoDB (if selected)
   ├─ Configure AWS credentials (OIDC)
   ├─ Setup Terraform
   ├─ Terraform init
   ├─ Terraform plan
   ├─ Terraform apply
   └─ Capture outputs

2. Deploy S3 (if selected)
   ├─ Configure AWS credentials (OIDC)
   ├─ Setup Terraform
   ├─ Terraform init
   ├─ Terraform plan
   ├─ Terraform apply
   └─ Capture outputs

3. Validate DynamoDB (if deployed)
   ├─ Check tables exist (tenants, products, campaigns)
   ├─ Verify table status = ACTIVE
   ├─ Verify primary keys (PK, SK)
   ├─ Verify GSIs (8 total across 3 tables)
   ├─ Verify PITR enabled
   ├─ Verify streams enabled
   ├─ Verify billing mode = ON_DEMAND
   └─ Verify tags present

4. Validate S3 (if deployed)
   ├─ Check bucket exists (bbws-templates-dev)
   ├─ Verify public access blocked (all 4 settings)
   ├─ Verify versioning enabled
   ├─ Verify encryption enabled
   ├─ Verify tags present
   └─ Check templates uploaded (optional)

5. Deployment Summary
   └─ Display overall results
```

### Expected Duration

- **DynamoDB deployment**: 2-3 minutes
- **S3 deployment**: 1-2 minutes
- **Validation**: 30 seconds per component
- **Total (both)**: 4-6 minutes

---

## ✅ Validation Checks

### DynamoDB Validation

The `validate_dynamodb_dev.py` script checks:

| Check | Requirement | Fail Condition |
|-------|-------------|----------------|
| **Table Existence** | Tables `tenants`, `products`, `campaigns` exist | Any table missing |
| **Table Status** | All tables = `ACTIVE` | Any table not ACTIVE |
| **Primary Keys** | PK (HASH), SK (RANGE) | Incorrect key schema |
| **GSIs** | 8 GSIs total across 3 tables | Missing or extra GSIs |
| **PITR** | Enabled for all tables | PITR disabled |
| **Streams** | Enabled (NEW_AND_OLD_IMAGES) | Streams disabled or wrong type |
| **Billing Mode** | ON_DEMAND (PAY_PER_REQUEST) | Provisioned capacity |
| **Tags** | 7 required tags present | Any tag missing |

### S3 Validation

The `validate_s3_dev.py` script checks:

| Check | Requirement | Fail Condition |
|-------|-------------|----------------|
| **Bucket Existence** | Bucket `bbws-templates-dev` exists | Bucket not found |
| **Public Access** | All 4 block settings = true | Any setting false |
| **Versioning** | Versioning = Enabled | Versioning disabled |
| **Encryption** | SSE-S3 or SSE-KMS enabled | No encryption |
| **Tags** | 7 required tags present | Any tag missing |
| **Region** | Bucket in eu-west-1 | Wrong region |
| **Templates** | 12 HTML templates (optional) | Warning only (not failure) |

---

## 🔧 Troubleshooting

### Error: "Role cannot be assumed"

**Symptom**: Workflow fails with "Unable to assume role"

**Causes**:
1. OIDC provider not created in AWS
2. IAM role trust policy incorrect
3. GitHub repository name doesn't match trust policy condition

**Solution**:
```bash
# 1. Verify OIDC provider exists
aws iam list-open-id-connect-providers

# 2. Check IAM role trust policy
aws iam get-role --role-name bbws-terraform-deployer-dev

# 3. Update trust policy to match your GitHub repo
```

### Error: "Backend initialization failed"

**Symptom**: Terraform init fails with "Error loading backend config"

**Causes**:
1. S3 state bucket doesn't exist (`bbws-terraform-state-dev`)
2. DynamoDB lock table doesn't exist (`terraform-state-lock-dev`)
3. IAM role lacks permissions to access state bucket

**Solution**:
```bash
# Create state bucket
aws s3api create-bucket \
  --bucket bbws-terraform-state-dev \
  --region eu-west-1 \
  --create-bucket-configuration LocationConstraint=eu-west-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket bbws-terraform-state-dev \
  --versioning-configuration Status=Enabled

# Create lock table
aws dynamodb create-table \
  --table-name terraform-state-lock-dev \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region eu-west-1
```

### Error: "Validation failed - Table not found"

**Symptom**: Deployment succeeds but validation fails

**Causes**:
1. Terraform apply succeeded but resources not fully created (eventual consistency)
2. Terraform working directory incorrect
3. Wrong AWS region

**Solution**:
```bash
# Wait 30 seconds and retry validation
sleep 30
python3 scripts/validate_dynamodb_dev.py

# Check tables manually
aws dynamodb list-tables --region af-south-1
```

### Error: "Permission denied"

**Symptom**: Terraform apply fails with access denied

**Causes**:
1. IAM role lacks required permissions
2. Service Control Policies (SCPs) blocking actions

**Solution**:
```bash
# Test IAM permissions
aws dynamodb list-tables --region af-south-1
aws s3 ls

# Check STS assume role works
aws sts get-caller-identity
```

---

## 📋 Prerequisites Checklist

Before running the workflow, verify:

- [ ] AWS Account: 536580886816 (DEV)
- [ ] Region: eu-west-1
- [ ] GitHub secret `AWS_ROLE_DEV` configured
- [ ] IAM role `bbws-terraform-deployer-dev` exists
- [ ] OIDC provider created in AWS
- [ ] S3 state bucket `bbws-terraform-state-dev` exists
- [ ] DynamoDB lock table `terraform-state-lock-dev` exists
- [ ] Terraform code exists in `terraform/dynamodb/` or `terraform/s3/`
- [ ] Environment config `environments/dev.tfvars` exists
- [ ] GitHub environment `dev` created (optional)

---

## 🎓 Running Validation Locally

You can run validation scripts locally to test:

```bash
# Install dependencies
pip install boto3

# Configure AWS credentials
export AWS_PROFILE=dev
# OR
export AWS_ACCESS_KEY_ID=xxx
export AWS_SECRET_ACCESS_KEY=xxx

# Run DynamoDB validation
python3 scripts/validate_dynamodb_dev.py

# Run S3 validation
python3 scripts/validate_s3_dev.py
```

**Expected Output** (success):
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

---

## 📝 Next Steps After Successful Deployment

1. **Verify Resources in AWS Console**
   - DynamoDB: https://console.aws.amazon.com/dynamodbv2/home?region=eu-west-1#tables
   - S3: https://console.aws.amazon.com/s3/home?region=eu-west-1

2. **Test Manual Operations**
   ```bash
   # Test DynamoDB access
   aws dynamodb describe-table --table-name tenants --region af-south-1

   # Test S3 access
   aws s3 ls s3://bbws-templates-dev/
   ```

3. **Upload HTML Templates** (if not done during deployment)
   ```bash
   aws s3 sync ./templates/ s3://bbws-templates-dev/templates/ --region af-south-1
   ```

4. **Run Integration Tests**
   - Test Lambda functions can read/write to DynamoDB
   - Test Lambda functions can read templates from S3

5. **Prepare for SIT Deployment**
   - Copy workflow to SIT environment (with 2 approvers)
   - Update AWS account ID to 815856636111
   - Test promotion workflow

---

## 🔐 Security Best Practices

1. **Never commit AWS credentials** - Use OIDC authentication only
2. **Rotate IAM role permissions** - Review quarterly
3. **Enable MFA for approvers** - For production deployments
4. **Use least privilege** - IAM role has minimum required permissions
5. **Monitor CloudTrail** - Review all Terraform actions
6. **Encrypt state files** - S3 state bucket has encryption enabled

---

## 📞 Support

For issues with:
- **Workflow failures**: Check workflow logs in GitHub Actions
- **Terraform errors**: Review Terraform plan output
- **AWS permissions**: Contact AWS administrator
- **Validation failures**: Run validation scripts locally

---

## 📄 Related Documentation

- [LLD Document](../2.1.8_LLD_S3_and_DynamoDB.md) - Complete Low-Level Design
- [Deployment Runbook](../stage-5-documentation-runbooks/worker-1-deployment-runbook/output.md)
- [Troubleshooting Runbook](../stage-5-documentation-runbooks/worker-3-troubleshooting-runbook/output.md)
- [Rollback Runbook](../stage-5-documentation-runbooks/worker-4-rollback-runbook/output.md)

---

**Last Updated**: 2025-12-25
**Version**: 1.0
**Status**: ✅ Ready for DEV deployment
