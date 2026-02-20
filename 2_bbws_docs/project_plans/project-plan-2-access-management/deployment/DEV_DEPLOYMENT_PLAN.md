# Access Management - DEV Deployment Plan

**Environment**: DEV
**AWS Account**: 536580886816
**Region**: eu-west-1
**Status**: PREREQUISITES VERIFIED - READY FOR DEPLOYMENT
**Created**: 2026-01-25

---

## 1. Prerequisites Checklist

### 1.1 Pre-requisites (Verify Before Terraform)

| Resource | Name | Purpose | Status |
|----------|------|---------|--------|
| S3 Bucket | `bbws-terraform-state-dev` | Shared Terraform state storage | ✅ Verified |
| DynamoDB Table | `bbws-terraform-locks-dev` | Shared Terraform state locking | ✅ Verified |
| GitHub OIDC Provider | IAM Identity Provider | Keyless GitHub Actions auth | ✅ Verified |
| GitHub Actions Role | `bbws-access-dev-github-actions-role` | CI/CD deployment role | ✅ Created |

**Note**: Using shared Terraform state infrastructure (consistent with other BBWS projects).

### 1.2 Commands to Verify Prerequisites

```bash
# Set environment
export AWS_PROFILE=AWSAdministratorAccess-536580886816
export AWS_REGION=eu-west-1

# 1. Verify Terraform State Bucket exists
aws s3api head-bucket --bucket bbws-terraform-state-dev 2>/dev/null && echo "✅ State bucket exists" || echo "❌ State bucket NOT found"

# 2. Verify Terraform Lock Table exists
aws dynamodb describe-table --table-name bbws-terraform-locks-dev --region eu-west-1 2>/dev/null && echo "✅ Lock table exists" || echo "❌ Lock table NOT found"

# 3. Verify GitHub OIDC Provider exists
aws iam list-open-id-connect-providers | grep token.actions.githubusercontent.com && echo "✅ OIDC provider exists" || echo "❌ OIDC provider NOT found"
```

### 1.3 Commands to Create Prerequisites (If Not Exists)

```bash
# Only run these if verification fails above

# 1. Create Terraform State Bucket (if needed)
aws s3api create-bucket \
  --bucket bbws-terraform-state-dev \
  --region eu-west-1 \
  --create-bucket-configuration LocationConstraint=eu-west-1

aws s3api put-bucket-versioning \
  --bucket bbws-terraform-state-dev \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \
  --bucket bbws-terraform-state-dev \
  --server-side-encryption-configuration '{
    "Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]
  }'

aws s3api put-public-access-block \
  --bucket bbws-terraform-state-dev \
  --public-access-block-configuration '{
    "BlockPublicAcls": true,
    "IgnorePublicAcls": true,
    "BlockPublicPolicy": true,
    "RestrictPublicBuckets": true
  }'

# 2. Create Terraform Lock Table (if needed)
aws dynamodb create-table \
  --table-name bbws-terraform-locks-dev \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region eu-west-1

# 3. Create GitHub OIDC Provider (if needed)
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

---

## 2. Resources to be Created

### 2.1 Infrastructure Resources (via Terraform)

| Resource | Name | Specification |
|----------|------|---------------|
| DynamoDB Table | `bbws-access-dev-ddb-access-management` | Single-table, On-demand, PITR enabled |
| DynamoDB GSIs | 5 GSIs | For access patterns |
| S3 Bucket | `bbws-access-dev-s3-audit-archive` | Audit logs, lifecycle policies |
| IAM Role | `bbws-access-dev-role-permission-service` | Permission service Lambda |
| IAM Role | `bbws-access-dev-role-invitation-service` | Invitation service Lambda |
| IAM Role | `bbws-access-dev-role-team-service` | Team service Lambda |
| IAM Role | `bbws-access-dev-role-role-service` | Role service Lambda |
| IAM Role | `bbws-access-dev-role-authorizer-service` | Authorizer Lambda |
| IAM Role | `bbws-access-dev-role-audit-service` | Audit service Lambda |
| IAM Role | `bbws-access-dev-github-actions-role` | GitHub Actions OIDC |
| API Gateway | `bbws-access-dev-apigw` | REST API, 40 routes |
| SNS Topic | `bbws-access-dev-sns-critical` | Critical alerts |
| SNS Topic | `bbws-access-dev-sns-warning` | Warning alerts |
| SNS Topic | `bbws-access-dev-sns-info` | Info notifications |
| SNS Topic | `bbws-access-dev-sns-dlq` | Dead letter queue alerts |

### 2.2 Lambda Functions (43 total)

| Service | Functions | Memory | Timeout |
|---------|-----------|--------|---------|
| Permission Service | 6 | 512MB | 30s |
| Invitation Service | 8 | 512MB | 30s |
| Team Service | 14 | 512MB | 30s |
| Role Service | 8 | 512MB | 30s |
| Authorizer Service | 1 | 512MB | 10s |
| Audit Service | 6 | 1024MB | 300s |

### 2.3 CloudWatch Resources

| Resource | Count |
|----------|-------|
| Log Groups | 8 |
| Alarms | 23 |
| Dashboard | 1 |
| Metric Filters | 7 |

---

## 3. Deployment Steps

### Step 1: Verify Prerequisites
```bash
# Run verification commands from Section 1.2
# Ensure all prerequisites show ✅ before proceeding
aws s3 ls s3://bbws-terraform-state-dev
aws dynamodb describe-table --table-name bbws-terraform-locks-dev
```

### Step 2: Clone/Setup Repository
```bash
# Clone the access management repository
git clone <repository-url> bbws-access-management
cd bbws-access-management

# Checkout develop branch
git checkout develop
```

### Step 3: Initialize Terraform
```bash
cd terraform

terraform init \
  -backend-config="bucket=bbws-terraform-state-dev" \
  -backend-config="key=access-management/terraform.tfstate" \
  -backend-config="region=eu-west-1" \
  -backend-config="encrypt=true" \
  -backend-config="dynamodb_table=bbws-terraform-locks-dev"
```

### Step 4: Plan Infrastructure
```bash
terraform plan \
  -var-file="environments/dev.tfvars" \
  -out=dev.tfplan

# Review plan output carefully
# Verify number of resources to create
```

### Step 5: Apply Infrastructure
```bash
# Only after reviewing plan
terraform apply dev.tfplan
```

### Step 6: Deploy Lambda Functions
```bash
cd ..

# Build Lambda packages
./scripts/build-lambdas.sh

# Deploy to DEV
./scripts/deploy-lambdas.sh dev v0.1.0

# Update aliases
./scripts/update-aliases.sh dev live
```

### Step 7: Verify Deployment
```bash
# Run smoke tests
pytest tests/smoke/ -v --environment=dev

# Check health endpoint
curl https://<api-id>.execute-api.eu-west-1.amazonaws.com/dev/health
```

---

## 4. Estimated Resources & Costs

### 4.1 Resource Count

| Resource Type | Count |
|---------------|-------|
| DynamoDB Tables | 1 (Access Management data) |
| DynamoDB GSIs | 5 |
| S3 Buckets | 1 (Audit archive) |
| Lambda Functions | 43 |
| IAM Roles | 7 |
| IAM Policies | 7 |
| API Gateway | 1 |
| API Routes | 40 |
| SNS Topics | 4 |
| CloudWatch Alarms | 23 |
| CloudWatch Log Groups | 8 |

### 4.2 Estimated Monthly Cost (DEV)

| Service | Estimated Cost |
|---------|----------------|
| DynamoDB (On-demand) | $5-20 |
| Lambda | $5-15 |
| API Gateway | $5-10 |
| S3 | $1-5 |
| CloudWatch | $5-10 |
| **Total** | **$21-60/month** |

*Note: Costs vary based on usage. DEV typically has low traffic.*

---

## 5. Rollback Plan

If deployment fails:

```bash
# Rollback Terraform
terraform destroy -var-file="environments/dev.tfvars"

# Or rollback to previous state
git checkout <previous-commit> -- terraform/
terraform apply -var-file="environments/dev.tfvars"
```

---

## 6. Post-Deployment Tasks

- [ ] Verify all Lambda functions deployed
- [ ] Verify API Gateway routes accessible
- [ ] Run smoke tests
- [ ] Verify CloudWatch alarms created
- [ ] Verify SNS topics created
- [ ] Test authorizer with sample token
- [ ] Seed initial permissions
- [ ] Update deployment documentation

---

## 7. Approval

| Role | Name | Approval | Date |
|------|------|----------|------|
| Requestor | | Requested | 2026-01-25 |
| DevOps Lead | | ☐ Pending | |
| Tech Lead | | ☐ Pending | |

---

## 8. Sign-Off

**Deployment Approved**: ☐ Yes / ☐ No

**Comments**:

---

*Document created by Agentic Project Manager*
*Last updated: 2026-01-25*
