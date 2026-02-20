# SIT and PROD Environment Setup Checklist

**Purpose**: Enable multi-environment deployments (DEV → SIT → PROD) via GitHub Actions
**Status**: DEV ✅ Complete | SIT ❌ Pending | PROD ❌ Pending
**Created**: 2025-12-26

---

## Overview

The multi-environment workflow (`deploy-multi-env.yml`) has been created and is ready to deploy to DEV/SIT/PROD. However, **SIT and PROD accounts require setup** before the workflow can be used.

### Current State

| Environment | Account | Region | OIDC | IAM Role | GitHub Secret | Backend S3 | Backend DynamoDB | Status |
|-------------|---------|--------|------|----------|---------------|------------|------------------|--------|
| **DEV** | 536580886816 | eu-west-1 | ✅ | ✅ | ✅ | ✅ | ✅ | **READY** |
| **SIT** | 815856636111 | eu-west-1 | ❌ | ❌ | ❌ | ❌ | ❌ | **NOT READY** |
| **PROD** | 093646564004 | af-south-1 | ❌ | ❌ | ❌ | ❌ | ❌ | **NOT READY** |

---

## SIT Environment Setup (Account: 815856636111)

### Phase 1: AWS OIDC Provider Setup

```bash
# Login to SIT account
aws sso login --profile Tebogo-sit

# Create OIDC provider for GitHub Actions
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
  --profile Tebogo-sit

# Verify creation
aws iam list-open-id-connect-providers --profile Tebogo-sit
```

**Expected Output:**
```json
{
    "OpenIDConnectProviderList": [
        {
            "Arn": "arn:aws:iam::815856636111:oidc-provider/token.actions.githubusercontent.com"
        }
    ]
}
```

### Phase 2: IAM Role Creation

```bash
# Create trust policy file
cat > github-actions-trust-policy-sit.json <<'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::815856636111:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:BigBeardWebSolutions/*"
        }
      }
    }
  ]
}
EOF

# Create IAM role
aws iam create-role \
  --role-name github-actions-role-sit \
  --assume-role-policy-document file://github-actions-trust-policy-sit.json \
  --description "GitHub Actions OIDC role for SIT deployments" \
  --profile Tebogo-sit

# Get role ARN (save for GitHub secrets)
aws iam get-role \
  --role-name github-actions-role-sit \
  --query 'Role.Arn' \
  --output text \
  --profile Tebogo-sit
```

### Phase 3: IAM Permissions Policy

Use the same permissions policy as DEV, but update account ID:

```bash
# Download the DEV policy as template
aws iam get-policy-version \
  --policy-arn arn:aws:iam::536580886816:policy/github-actions-policy-dev \
  --version-id v2 \
  --query 'PolicyVersion.Document' \
  --output json \
  --profile AWSAdministratorAccess-536580886816 > github-actions-permissions-sit.json

# Update account IDs in the policy file from 536580886816 to 815856636111
# (Manual edit required)

# Create policy in SIT account
aws iam create-policy \
  --policy-name github-actions-policy-sit \
  --policy-document file://github-actions-permissions-sit.json \
  --description "Permissions for GitHub Actions to deploy infrastructure in SIT" \
  --profile Tebogo-sit

# Attach policy to role
aws iam attach-role-policy \
  --role-name github-actions-role-sit \
  --policy-arn arn:aws:iam::815856636111:policy/github-actions-policy-sit \
  --profile Tebogo-sit

# Verify attachment
aws iam list-attached-role-policies \
  --role-name github-actions-role-sit \
  --profile Tebogo-sit
```

### Phase 4: Terraform Backend Setup

```bash
# Create S3 bucket for Terraform state
aws s3api create-bucket \
  --bucket bbws-terraform-state-sit \
  --region eu-west-1 \
  --create-bucket-configuration LocationConstraint=eu-west-1 \
  --profile Tebogo-sit

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket bbws-terraform-state-sit \
  --versioning-configuration Status=Enabled \
  --profile Tebogo-sit

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket bbws-terraform-state-sit \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }' \
  --profile Tebogo-sit

# Block public access
aws s3api put-public-access-block \
  --bucket bbws-terraform-state-sit \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" \
  --profile Tebogo-sit

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name terraform-state-lock-sit \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region eu-west-1 \
  --profile Tebogo-sit

# Verify resources created
aws s3 ls | grep sit
aws dynamodb list-tables --region eu-west-1 --profile Tebogo-sit | grep sit
```

### Phase 5: GitHub Secret Configuration

```bash
# Get SIT role ARN
SIT_ROLE_ARN=$(aws iam get-role \
  --role-name github-actions-role-sit \
  --query 'Role.Arn' \
  --output text \
  --profile Tebogo-sit)

echo "SIT Role ARN: $SIT_ROLE_ARN"

# Set GitHub secret
gh secret set AWS_ROLE_SIT --body "$SIT_ROLE_ARN"

# Verify
gh secret list | grep AWS_ROLE
```

### Phase 6: Create SIT Environment Variables

Create Terraform variables file:

```bash
# terraform/dynamodb/environments/sit.tfvars
environment = "sit"
aws_region  = "eu-west-1"
project     = "bbws"
```

```bash
# terraform/s3/environments/sit.tfvars
environment = "sit"
aws_region  = "eu-west-1"
project     = "bbws"
```

---

## PROD Environment Setup (Account: 093646564004)

### Phase 1: AWS OIDC Provider Setup

```bash
# Login to PROD account
aws sso login --profile Tebogo-prod

# Create OIDC provider
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
  --profile Tebogo-prod

# Verify
aws iam list-open-id-connect-providers --profile Tebogo-prod
```

### Phase 2: IAM Role Creation

```bash
# Create trust policy
cat > github-actions-trust-policy-prod.json <<'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::093646564004:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:BigBeardWebSolutions/*"
        }
      }
    }
  ]
}
EOF

# Create role
aws iam create-role \
  --role-name github-actions-role-prod \
  --assume-role-policy-document file://github-actions-trust-policy-prod.json \
  --description "GitHub Actions OIDC role for PROD deployments" \
  --profile Tebogo-prod

# Get ARN
aws iam get-role \
  --role-name github-actions-role-prod \
  --query 'Role.Arn' \
  --output text \
  --profile Tebogo-prod
```

### Phase 3: IAM Permissions Policy

```bash
# Update policy JSON with PROD account ID (093646564004)
# Create permissions policy
aws iam create-policy \
  --policy-name github-actions-policy-prod \
  --policy-document file://github-actions-permissions-prod.json \
  --description "Permissions for GitHub Actions to deploy infrastructure in PROD" \
  --profile Tebogo-prod

# Attach to role
aws iam attach-role-policy \
  --role-name github-actions-role-prod \
  --policy-arn arn:aws:iam::093646564004:policy/github-actions-policy-prod \
  --profile Tebogo-prod
```

### Phase 4: Terraform Backend Setup

**⚠️ IMPORTANT: PROD uses af-south-1 (Cape Town)**

```bash
# Create S3 bucket in af-south-1
aws s3api create-bucket \
  --bucket bbws-terraform-state-prod \
  --region af-south-1 \
  --create-bucket-configuration LocationConstraint=af-south-1 \
  --profile Tebogo-prod

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket bbws-terraform-state-prod \
  --versioning-configuration Status=Enabled \
  --profile Tebogo-prod

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket bbws-terraform-state-prod \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }' \
  --profile Tebogo-prod

# Block public access
aws s3api put-public-access-block \
  --bucket bbws-terraform-state-prod \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" \
  --profile Tebogo-prod

# Create DynamoDB table in af-south-1
aws dynamodb create-table \
  --table-name terraform-state-lock-prod \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region af-south-1 \
  --profile Tebogo-prod
```

### Phase 5: GitHub Secret Configuration

```bash
# Get PROD role ARN
PROD_ROLE_ARN=$(aws iam get-role \
  --role-name github-actions-role-prod \
  --query 'Role.Arn' \
  --output text \
  --profile Tebogo-prod)

echo "PROD Role ARN: $PROD_ROLE_ARN"

# Set GitHub secret
gh secret set AWS_ROLE_PROD --body "$PROD_ROLE_ARN"

# Verify all three secrets exist
gh secret list
```

**Expected Output:**
```
AWS_ROLE_DEV   2025-12-26T07:36:18Z
AWS_ROLE_PROD  2025-12-26T10:00:00Z
AWS_ROLE_SIT   2025-12-26T10:00:00Z
```

### Phase 6: Create PROD Environment Variables

```bash
# terraform/dynamodb/environments/prod.tfvars
environment = "prod"
aws_region  = "af-south-1"  # CRITICAL: PROD uses Cape Town
project     = "bbws"
```

```bash
# terraform/s3/environments/prod.tfvars
environment = "prod"
aws_region  = "af-south-1"
project     = "bbws"
```

### Phase 7: GitHub Environment Protection Rules (PROD)

**CRITICAL for PROD**: Configure approval gates

1. Go to GitHub Repository → Settings → Environments
2. Create environment: `prod`
3. Enable "Required reviewers"
4. Add yourself as required reviewer
5. Set wait timer: 0 minutes (or as preferred)

This ensures PROD deployments require manual approval.

---

## Verification Checklist

### SIT Environment

- [ ] OIDC provider created in account 815856636111
- [ ] IAM role `github-actions-role-sit` created with correct trust policy
- [ ] Permissions policy attached to role
- [ ] S3 bucket `bbws-terraform-state-sit` created in eu-west-1
- [ ] DynamoDB table `terraform-state-lock-sit` created in eu-west-1
- [ ] GitHub secret `AWS_ROLE_SIT` set
- [ ] Terraform tfvars file created: `terraform/*/environments/sit.tfvars`
- [ ] Test deployment: `gh workflow run deploy-multi-env.yml --field environment=sit --field component=dynamodb`

### PROD Environment

- [ ] OIDC provider created in account 093646564004
- [ ] IAM role `github-actions-role-prod` created with correct trust policy
- [ ] Permissions policy attached to role
- [ ] S3 bucket `bbws-terraform-state-prod` created in **af-south-1** (NOT eu-west-1)
- [ ] DynamoDB table `terraform-state-lock-prod` created in **af-south-1**
- [ ] GitHub secret `AWS_ROLE_PROD` set
- [ ] Terraform tfvars file created: `terraform/*/environments/prod.tfvars` (region: af-south-1)
- [ ] GitHub environment protection configured with approval gate
- [ ] Test deployment (after SIT validation): `gh workflow run deploy-multi-env.yml --field environment=prod --field component=dynamodb`

---

## Testing Multi-Environment Workflow

### Test 1: DEV Deployment (Should Work Immediately)

```bash
gh workflow run deploy-multi-env.yml \
  --field environment=dev \
  --field component=dynamodb

gh run list --workflow=deploy-multi-env.yml --limit 1
gh run watch <RUN_ID>
```

### Test 2: SIT Deployment (After SIT Setup Complete)

```bash
gh workflow run deploy-multi-env.yml \
  --field environment=sit \
  --field component=dynamodb

gh run watch <RUN_ID>
```

### Test 3: PROD Deployment (After SIT+PROD Setup Complete)

```bash
# This will require approval in GitHub UI
gh workflow run deploy-multi-env.yml \
  --field environment=prod \
  --field component=dynamodb

# Approve in GitHub: Actions → Workflow → Review deployments → Approve
gh run watch <RUN_ID>
```

---

## Promotion Workflow Example

```
1. Develop feature in DEV
   ↓
   gh workflow run deploy-multi-env.yml --field environment=dev --field component=dynamodb
   ↓
   Validate in DEV ✅

2. Promote to SIT
   ↓
   git tag sit-v1.0.0
   git push origin sit-v1.0.0
   ↓
   gh workflow run deploy-multi-env.yml --field environment=sit --field component=dynamodb
   ↓
   Run integration tests in SIT ✅

3. Promote to PROD (only after SIT validation)
   ↓
   git tag prod-v1.0.0
   git push origin prod-v1.0.0
   ↓
   gh workflow run deploy-multi-env.yml --field environment=prod --field component=dynamodb
   ↓
   Manual approval required → Deploy → Monitor ✅
```

---

## Quick Reference Commands

```bash
# Check OIDC providers across all accounts
aws iam list-open-id-connect-providers --profile Tebogo-dev
aws iam list-open-id-connect-providers --profile Tebogo-sit
aws iam list-open-id-connect-providers --profile Tebogo-prod

# Check IAM roles
aws iam get-role --role-name github-actions-role-dev --profile Tebogo-dev
aws iam get-role --role-name github-actions-role-sit --profile Tebogo-sit
aws iam get-role --role-name github-actions-role-prod --profile Tebogo-prod

# Check backend resources
aws s3 ls | grep terraform-state
aws dynamodb list-tables --region eu-west-1 --profile Tebogo-sit | grep lock
aws dynamodb list-tables --region af-south-1 --profile Tebogo-prod | grep lock

# Check GitHub secrets
gh secret list
```

---

## Summary

**Current Status:**
- ✅ DEV: Fully configured and operational
- ❌ SIT: Requires setup (estimated time: 30 minutes)
- ❌ PROD: Requires setup (estimated time: 30 minutes)

**Next Steps:**
1. Execute SIT setup commands in order
2. Test SIT deployment
3. Execute PROD setup commands in order
4. Configure PROD approval gates
5. Test full promotion workflow (DEV → SIT → PROD)

**Reference Documentation:**
- Skill file: `2_bbws_agents/devops/skills/github_oidc_cicd.skill.md`
- Workflow: `.github/workflows/deploy-multi-env.yml`
- This checklist: `2_bbws_agents/devops/plans/sit-prod-setup-checklist.md`

---

**Last Updated**: 2025-12-26
**Status**: Ready for SIT/PROD setup
