# Quick Setup Guide - DEV Deployment Pipeline

**Goal**: Get your DEV deployment pipeline running in 15 minutes

**Region Configuration**:
- DEV: eu-west-1 (Ireland)
- SIT: eu-west-1 (Ireland)
- PROD Primary: af-south-1 (Cape Town)
- PROD DR: eu-west-1 (Ireland)

---

## Step 1: Prerequisites (5 minutes)

### AWS Setup

1. **Create Terraform State Infrastructure**:
   ```bash
   # Connect to DEV AWS account (536580886816)
   aws configure --profile dev

   # Create S3 bucket for Terraform state
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

   # Create DynamoDB table for state locking
   aws dynamodb create-table \
     --table-name terraform-state-lock-dev \
     --attribute-definitions AttributeName=LockID,AttributeType=S \
     --key-schema AttributeName=LockID,KeyType=HASH \
     --billing-mode PAY_PER_REQUEST \
     --region eu-west-1 \
     --profile dev
   ```

2. **Create OIDC Provider** (one-time setup):
   ```bash
   aws iam create-open-id-connect-provider \
     --url https://token.actions.githubusercontent.com \
     --client-id-list sts.amazonaws.com \
     --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
     --profile dev
   ```

3. **Create IAM Role** (replace `YOUR_GITHUB_ORG` with your GitHub username/org):

   Save this as `trust-policy.json`:
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

   Create the role:
   ```bash
   aws iam create-role \
     --role-name bbws-terraform-deployer-dev \
     --assume-role-policy-document file://trust-policy.json \
     --profile dev
   ```

4. **Attach Permissions** (use managed policies for quick setup):
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

### GitHub Setup

1. **Add GitHub Secret**:
   - Go to your repository → `Settings` → `Secrets and variables` → `Actions`
   - Click `New repository secret`
   - Name: `AWS_ROLE_DEV`
   - Value: `arn:aws:iam::536580886816:role/bbws-terraform-deployer-dev`
   - Click `Add secret`

2. **Create GitHub Environment** (optional for DEV):
   - Go to `Settings` → `Environments` → `New environment`
   - Name: `dev`
   - Click `Configure environment`
   - (No protection rules needed for DEV)
   - Click `Save protection rules`

---

## Step 2: Copy Files to Repository (2 minutes)

Choose your target repository and copy files:

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

---

## Step 3: Verify Terraform Structure (3 minutes)

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

**If Terraform code doesn't exist yet**, you need to create it from the Stage 3 outputs:
- See: `stage-3-infrastructure-code/worker-2-terraform-dynamodb-module/output.md`
- See: `stage-3-infrastructure-code/worker-3-terraform-s3-module/output.md`

---

## Step 4: Test Workflow (5 minutes)

### Trigger Manual Deployment

1. Go to your GitHub repository
2. Click **`Actions`** tab
3. Select **`Deploy to DEV`** workflow (left sidebar)
4. Click **`Run workflow`** button (right side)
5. Fill in the form:
   - **Component**: Select `dynamodb` (or `s3` or `both`)
   - **Skip validation**: Leave **unchecked** (we want validation)
6. Click **`Run workflow`** (green button)

### Monitor Deployment

Watch the workflow progress:
- ✓ Deploy DynamoDB (2-3 minutes)
- ✓ Validate DynamoDB (30 seconds)
- ✓ Summary

### Expected Success Output

```
================================================================================
DEV DEPLOYMENT SUMMARY
================================================================================
Component: dynamodb
Environment: DEV
AWS Account: 536580886816
Region: af-south-1

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

---

## Step 5: Verify Resources in AWS (2 minutes)

### DynamoDB Tables

```bash
# List tables
aws dynamodb list-tables --region af-south-1 --profile dev

# Describe tenants table
aws dynamodb describe-table --table-name tenants --region af-south-1 --profile dev
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
        }
    }
}
```

### S3 Buckets

```bash
# List buckets
aws s3 ls --profile dev | grep bbws

# Check bucket details
aws s3api get-bucket-versioning --bucket bbws-templates-dev --profile dev
```

**Expected Output**:
```json
{
    "Status": "Enabled"
}
```

---

## Troubleshooting

### Issue: "Workflow not found"

**Solution**: Make sure you pushed the workflow file to the `main` branch:
```bash
git push origin main
```

### Issue: "Role cannot be assumed"

**Solution**: Check the trust policy includes your GitHub repository:
```bash
aws iam get-role --role-name bbws-terraform-deployer-dev --profile dev
```

Verify the `StringLike` condition includes your repo.

### Issue: "Backend initialization failed"

**Solution**: State bucket or lock table doesn't exist. Re-run Step 1 AWS setup.

### Issue: "Validation failed"

**Solution**: Tables created but validation failed. Check:
```bash
# Verify table exists
aws dynamodb describe-table --table-name tenants --region af-south-1 --profile dev

# Run validation locally
python3 scripts/validate_dynamodb_dev.py
```

---

## Success Checklist

- [ ] AWS OIDC provider created
- [ ] IAM role `bbws-terraform-deployer-dev` created
- [ ] S3 state bucket `bbws-terraform-state-dev` created
- [ ] DynamoDB lock table `terraform-state-lock-dev` created
- [ ] GitHub secret `AWS_ROLE_DEV` configured
- [ ] Workflow file copied to `.github/workflows/`
- [ ] Validation script copied to `scripts/`
- [ ] Terraform code exists in `terraform/dynamodb/` or `terraform/s3/`
- [ ] `environments/dev.tfvars` file exists
- [ ] Workflow triggered successfully
- [ ] All validation checks passed
- [ ] Resources visible in AWS Console

---

## Next Steps

1. **Test the deployment**: Trigger the workflow and verify success
2. **Deploy the other component**: If you deployed DynamoDB, now deploy S3 (or vice versa)
3. **Upload HTML templates** (for S3):
   ```bash
   aws s3 sync ./templates/ s3://bbws-templates-dev/templates/ --region af-south-1 --profile dev
   ```
4. **Prepare SIT deployment**: Modify workflow for SIT environment
5. **Document any issues**: Update troubleshooting section

---

**Setup Time**: ~15 minutes
**Status**: ✅ Ready to deploy
**Support**: Check README.md for detailed documentation
