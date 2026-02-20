# Automated Setup Guide - GitHub Actions Pipeline

**For first-time users**: This guide provides automated scripts to set up your entire GitHub Actions deployment pipeline.

**Time Required**: 15-20 minutes (mostly automated)

---

## Overview

These scripts will automatically set up everything you need:

1. ✅ AWS CLI profile configuration
2. ✅ AWS OIDC provider for GitHub Actions
3. ✅ IAM role with proper permissions
4. ✅ S3 bucket for Terraform state (in `eu-west-1`)
5. ✅ DynamoDB table for state locking (in `eu-west-1`)
6. ✅ GitHub secret configuration
7. ✅ Workflow files in your repository
8. ✅ Deployment triggering and monitoring

---

## Prerequisites

**Install these tools first:**

```bash
# macOS
brew install awscli gh

# Verify installations
aws --version
gh --version
```

**You'll also need:**
- AWS Access Key ID and Secret Access Key for DEV account (536580886816)
- GitHub account with admin access to your repository
- Your repository cloned locally

---

## Quick Start (4 Steps)

### Step 0: Check Current Setup

First, see what's already configured:

```bash
cd /Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/project-plan-1/github-workflows-ready-to-deploy

./check-setup.sh tsekatm 2_1_bbws_dynamodb_schemas
```

This will show you what's missing. Based on your diagnostic output, **everything needs to be set up**.

---

### Step 1: Configure AWS Profile (2 minutes)

```bash
./1-setup-aws-profile.sh
```

**What it does:**
- Configures AWS CLI profile named `dev`
- Sets region to `eu-west-1`
- Verifies connection to DEV account (536580886816)

**You'll need:**
- AWS Access Key ID
- AWS Secret Access Key

---

### Step 2: Setup AWS Infrastructure (5 minutes)

```bash
./2-setup-aws-infrastructure.sh tsekatm
```

**Replace `tsekatm`** with your GitHub username.

**What it does:**
- Creates OIDC provider for GitHub Actions
- Creates IAM role `bbws-terraform-deployer-dev`
- Attaches necessary permissions (DynamoDB, S3, CloudWatch)
- Creates S3 state bucket `bbws-terraform-state-dev` in `eu-west-1`
- Creates DynamoDB lock table `terraform-state-lock-dev` in `eu-west-1`

**This is fully automated** - just sit back and watch!

---

### Step 3: Setup GitHub Repository (3 minutes)

```bash
./3-setup-github.sh tsekatm 2_1_bbws_dynamodb_schemas
```

**What it does:**
- Creates GitHub secret `AWS_ROLE_DEV`
- Optionally creates GitHub environment `dev`
- Copies workflow file to your repository
- Copies validation scripts
- Commits and pushes changes

**You'll be asked:**
- Whether to create GitHub environment (optional for DEV)
- Component type (DynamoDB, S3, or both)
- Repository path on your local machine
- Whether to commit and push immediately

---

### Step 4: Trigger Deployment (5 minutes)

```bash
./4-trigger-deployment.sh tsekatm 2_1_bbws_dynamodb_schemas dynamodb
```

**Replace `dynamodb`** with:
- `dynamodb` - Deploy DynamoDB only
- `s3` - Deploy S3 only
- `both` - Deploy both components

**What it does:**
- Triggers GitHub Actions workflow
- Monitors deployment progress in real-time
- Shows results and next steps

---

## Example: Complete Setup Flow

```bash
# Navigate to scripts directory
cd /Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/project-plan-1/github-workflows-ready-to-deploy

# Step 1: Configure AWS profile
./1-setup-aws-profile.sh
# Enter your AWS Access Key ID and Secret Access Key when prompted

# Step 2: Setup AWS infrastructure
./2-setup-aws-infrastructure.sh tsekatm
# Fully automated - just wait for completion

# Step 3: Setup GitHub
./3-setup-github.sh tsekatm 2_1_bbws_dynamodb_schemas
# Answer prompts: component type, repo path, commit/push

# Step 4: Deploy!
./4-trigger-deployment.sh tsekatm 2_1_bbws_dynamodb_schemas dynamodb
# Watch the deployment happen in real-time
```

---

## What Happens During Deployment

### Stage 1: Deploy Infrastructure (2-3 minutes)
- Terraform initializes with remote state
- Terraform plans changes
- Terraform applies infrastructure
- DynamoDB tables created (if deploying DynamoDB)
- S3 buckets created (if deploying S3)

### Stage 2: Validation (30 seconds)
- **DynamoDB**: 8 checks per table (existence, status, keys, GSIs, PITR, streams, billing, tags)
- **S3**: 6 checks per bucket (existence, public access blocked, versioning, encryption, tags, region)

### Stage 3: Summary
- Displays deployment results
- Shows all job statuses
- Provides next steps

---

## Success Criteria

After running all 4 scripts, you should have:

- ✅ AWS profile `dev` configured
- ✅ OIDC provider created in AWS
- ✅ IAM role `bbws-terraform-deployer-dev` with correct permissions
- ✅ S3 bucket `bbws-terraform-state-dev` in `eu-west-1`
- ✅ DynamoDB table `terraform-state-lock-dev` in `eu-west-1`
- ✅ GitHub secret `AWS_ROLE_DEV` configured
- ✅ Workflow file in repository (`.github/workflows/deploy-dev.yml`)
- ✅ Validation scripts in repository (`scripts/validate_*.py`)
- ✅ Infrastructure deployed to DEV
- ✅ All validation checks passing

---

## Troubleshooting

### Script 1 Fails: "Cannot verify credentials"

**Problem**: Invalid AWS credentials

**Fix**:
1. Verify you're using DEV account credentials (536580886816)
2. Check Access Key ID and Secret Access Key are correct
3. Ensure IAM user has permissions to call `sts:GetCallerIdentity`

---

### Script 2 Fails: "Access Denied"

**Problem**: IAM user lacks permissions to create infrastructure

**Fix**:
1. Your IAM user needs these permissions:
   - `iam:CreateOpenIDConnectProvider`
   - `iam:CreateRole`
   - `iam:AttachRolePolicy`
   - `s3:CreateBucket`
   - `dynamodb:CreateTable`
2. Contact your AWS administrator to grant permissions

---

### Script 3 Fails: "Repository not found"

**Problem**: GitHub repository doesn't exist or you lack access

**Fix**:
1. Verify repository name is correct: `tsekatm/2_1_bbws_dynamodb_schemas`
2. Ensure you have admin access to the repository
3. Check GitHub CLI authentication: `gh auth status`

---

### Script 4 Fails: "Workflow not found"

**Problem**: Workflow file not pushed to repository

**Fix**:
1. Verify workflow file exists:
   ```bash
   gh api repos/tsekatm/2_1_bbws_dynamodb_schemas/contents/.github/workflows/deploy-dev.yml
   ```
2. If missing, re-run Script 3 and ensure you commit/push

---

### Deployment Fails: "Backend initialization failed"

**Problem**: Terraform can't access state bucket

**Fix**:
1. Verify state bucket exists in `eu-west-1`:
   ```bash
   aws s3 ls --profile dev | grep bbws-terraform-state-dev
   ```
2. Verify lock table exists:
   ```bash
   aws dynamodb describe-table --table-name terraform-state-lock-dev --region eu-west-1 --profile dev
   ```
3. Re-run Script 2 if infrastructure is missing

---

## Security Best Practices

1. **Never commit AWS credentials** - These scripts use OIDC (no long-lived credentials)
2. **Rotate access keys regularly** - The keys you used in Script 1 should be rotated quarterly
3. **Use MFA** - Enable MFA on your AWS IAM user
4. **Review IAM permissions** - Periodically audit the role permissions
5. **Monitor CloudTrail** - Review all Terraform actions in CloudTrail logs

---

## Next Steps After Successful Deployment

### For DynamoDB

```bash
# Verify tables in AWS Console
open "https://console.aws.amazon.com/dynamodbv2/home?region=eu-west-1#tables"

# List tables via CLI
aws dynamodb list-tables --region eu-west-1 --profile dev

# Insert test data
aws dynamodb put-item \
  --table-name tenants \
  --item '{"PK":{"S":"TENANT#test"},"SK":{"S":"METADATA"},"email":{"S":"test@example.com"},"active":{"BOOL":true}}' \
  --region eu-west-1 \
  --profile dev
```

### For S3

```bash
# Verify bucket in AWS Console
open "https://console.aws.amazon.com/s3/home?region=eu-west-1"

# Upload HTML templates
aws s3 sync ./templates/ s3://bbws-templates-dev/templates/ --region eu-west-1 --profile dev

# List templates
aws s3 ls s3://bbws-templates-dev/templates/ --profile dev
```

### Prepare for SIT Deployment

Once DEV is working:
1. Create similar scripts for SIT environment
2. Change AWS account to `815856636111`
3. Keep region as `eu-west-1`
4. Add 2 required approvers for SIT deployments

---

## Comparison: Manual vs Automated Setup

| Task | Manual Time | Automated Time |
|------|-------------|----------------|
| AWS CLI configuration | 5 min | 2 min (just enter credentials) |
| Create OIDC provider | 3 min | Automated ✓ |
| Create IAM role | 10 min | Automated ✓ |
| Create S3 bucket | 5 min | Automated ✓ |
| Create DynamoDB table | 5 min | Automated ✓ |
| Configure GitHub secrets | 3 min | Automated ✓ |
| Copy workflow files | 5 min | 3 min (just answer prompts) |
| Trigger deployment | 2 min | Automated ✓ |
| **Total** | **38 minutes** | **5 minutes (+ 10 min deployment)** |

---

## Support

If you encounter issues:

1. **Run diagnostic**: `./check-setup.sh tsekatm 2_1_bbws_dynamodb_schemas`
2. **Check workflow logs**: `gh run view <run-id> --log`
3. **Review manual guide**: See `human-steps.md` for step-by-step details
4. **Check AWS Console**: Verify resources in eu-west-1

---

**Last Updated**: 2025-12-25
**Status**: ✅ Ready for automated setup
**Tested With**: AWS CLI 2.x, GitHub CLI 2.x
