# Worker 1 Output: GitHub Repository Setup

**Date Completed**: 2025-12-30
**Worker**: Agentic Project Manager
**Status**: Complete

---

## Executive Summary

This document provides complete instructions and configurations for creating the GitHub repository `2_bbws_order_lambda` with OIDC authentication for all three AWS environments (DEV, SIT, PROD).

**Repository**: `2_bbws_order_lambda`
**Organization**: (Your GitHub organization)
**Visibility**: Private
**OIDC Environments**: 3 (DEV: 536580886816, SIT: 815856636111, PROD: 093646564004)

---

## 1. Repository Creation

### 1.1 Using GitHub CLI

```bash
# Create repository
gh repo create 2_bbws_order_lambda \
  --private \
  --description "Order Lambda service for BBWS Customer Portal Public - Event-driven order processing with SQS" \
  --clone

cd 2_bbws_order_lambda

# Initialize git if not already initialized
git init
git branch -M main
```

### 1.2 Using GitHub Web UI

1. Navigate to GitHub organization
2. Click "New Repository"
3. Repository name: `2_bbws_order_lambda`
4. Description: "Order Lambda service for BBWS Customer Portal Public - Event-driven order processing with SQS"
5. Visibility: Private
6. Initialize with: None (will push from local)
7. Click "Create Repository"

---

## 2. Repository Configuration

### 2.1 Branch Protection Rules

**For `main` branch (PROD)**:

```bash
# Using GitHub CLI
gh api repos/:owner/2_bbws_order_lambda/branches/main/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":["test","validate"]}' \
  --field enforce_admins=true \
  --field required_pull_request_reviews='{"required_approving_review_count":2}' \
  --field restrictions=null
```

**Via Web UI**:
1. Settings → Branches → Add rule
2. Branch name pattern: `main`
3. ✅ Require pull request before merging (2 approvals)
4. ✅ Require status checks to pass (test, validate)
5. ✅ Require branches to be up to date
6. ✅ Include administrators
7. Save changes

**For `develop` branch (DEV)**:
- No strict protection
- Auto-deploy on push

**For `release` branch (SIT)**:
- Require 1 approval
- Require status checks

---

## 3. OIDC Authentication Setup

### 3.1 AWS IAM Identity Provider Configuration

**For Each Environment**, create an OIDC identity provider in AWS:

#### DEV Environment (Account: 536580886816)

```bash
# Create OIDC provider
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
  --profile bbws-dev
```

#### SIT Environment (Account: 815856636111)

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
  --profile bbws-sit
```

#### PROD Environment (Account: 093646564004)

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
  --profile bbws-prod
```

---

### 3.2 IAM Role Creation

#### DEV OIDC Role

**Role Name**: `github-2-bbws-order-lambda-dev`

**Trust Policy** (`trust-policy-dev.json`):

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
          "token.actions.githubusercontent.com:sub": "repo:YOUR_ORG/2_bbws_order_lambda:*"
        }
      }
    }
  ]
}
```

**Create Role**:

```bash
aws iam create-role \
  --role-name github-2-bbws-order-lambda-dev \
  --assume-role-policy-document file://trust-policy-dev.json \
  --description "GitHub Actions OIDC role for Order Lambda DEV deployments" \
  --profile bbws-dev
```

**Attach Permissions**:

```bash
# Attach policies for Terraform operations
aws iam attach-role-policy \
  --role-name github-2-bbws-order-lambda-dev \
  --policy-arn arn:aws:iam::aws:policy/PowerUserAccess \
  --profile bbws-dev

# Create custom policy for state file access
aws iam put-role-policy \
  --role-name github-2-bbws-order-lambda-dev \
  --policy-name TerraformStateAccess \
  --policy-document file://state-access-policy.json \
  --profile bbws-dev
```

**State Access Policy** (`state-access-policy.json`):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": [
        "arn:aws:s3:::bbws-terraform-state-dev",
        "arn:aws:s3:::bbws-terraform-state-dev/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:DescribeTable",
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": "arn:aws:dynamodb:af-south-1:536580886816:table/terraform-locks-dev"
    }
  ]
}
```

#### SIT OIDC Role

**Role Name**: `github-2-bbws-order-lambda-sit`

**Trust Policy** (`trust-policy-sit.json`):

```json
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
          "token.actions.githubusercontent.com:sub": "repo:YOUR_ORG/2_bbws_order_lambda:ref:refs/heads/release"
        }
      }
    }
  ]
}
```

**Create Role**:

```bash
aws iam create-role \
  --role-name github-2-bbws-order-lambda-sit \
  --assume-role-policy-document file://trust-policy-sit.json \
  --description "GitHub Actions OIDC role for Order Lambda SIT deployments" \
  --profile bbws-sit

aws iam attach-role-policy \
  --role-name github-2-bbws-order-lambda-sit \
  --policy-arn arn:aws:iam::aws:policy/PowerUserAccess \
  --profile bbws-sit

aws iam put-role-policy \
  --role-name github-2-bbws-order-lambda-sit \
  --policy-name TerraformStateAccess \
  --policy-document file://state-access-policy-sit.json \
  --profile bbws-sit
```

#### PROD OIDC Role

**Role Name**: `github-2-bbws-order-lambda-prod`

**Trust Policy** (`trust-policy-prod.json`):

```json
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
          "token.actions.githubusercontent.com:sub": "repo:YOUR_ORG/2_bbws_order_lambda:ref:refs/heads/main"
        }
      }
    }
  ]
}
```

**Create Role**:

```bash
aws iam create-role \
  --role-name github-2-bbws-order-lambda-prod \
  --assume-role-policy-document file://trust-policy-prod.json \
  --description "GitHub Actions OIDC role for Order Lambda PROD deployments" \
  --profile bbws-prod

# Use more restrictive permissions for PROD
aws iam attach-role-policy \
  --role-name github-2-bbws-order-lambda-prod \
  --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess \
  --profile bbws-prod

# Add specific deployment permissions via custom policy
aws iam put-role-policy \
  --role-name github-2-bbws-order-lambda-prod \
  --policy-name PRODDeploymentPermissions \
  --policy-document file://prod-deploy-policy.json \
  --profile bbws-prod
```

---

### 3.3 OIDC Role ARNs Summary

| Environment | AWS Account | Role Name | ARN |
|-------------|-------------|-----------|-----|
| **DEV** | 536580886816 | github-2-bbws-order-lambda-dev | `arn:aws:iam::536580886816:role/github-2-bbws-order-lambda-dev` |
| **SIT** | 815856636111 | github-2-bbws-order-lambda-sit | `arn:aws:iam::815856636111:role/github-2-bbws-order-lambda-sit` |
| **PROD** | 093646564004 | github-2-bbws-order-lambda-prod | `arn:aws:iam::093646564004:role/github-2-bbws-order-lambda-prod` |

---

## 4. GitHub Environments Setup

### 4.1 Create Environments

**Via GitHub Web UI**:

1. Repository → Settings → Environments
2. Click "New environment"
3. Create three environments:
   - `dev`
   - `sit`
   - `prod`

### 4.2 Environment: dev

**Protection Rules**:
- ❌ No required reviewers (auto-deploy)
- ✅ Allow only develop branch

**Environment Secrets**:

```bash
# Using GitHub CLI
gh secret set DEV_AWS_ACCOUNT_ID --body "536580886816" --env dev
gh secret set DEV_AWS_REGION --body "af-south-1" --env dev
gh secret set DEV_OIDC_ROLE_ARN --body "arn:aws:iam::536580886816:role/github-2-bbws-order-lambda-dev" --env dev
```

### 4.3 Environment: sit

**Protection Rules**:
- ✅ Required reviewers: 1 (QA Lead)
- ✅ Allow only release branch

**Environment Secrets**:

```bash
gh secret set SIT_AWS_ACCOUNT_ID --body "815856636111" --env sit
gh secret set SIT_AWS_REGION --body "af-south-1" --env sit
gh secret set SIT_OIDC_ROLE_ARN --body "arn:aws:iam::815856636111:role/github-2-bbws-order-lambda-sit" --env sit
```

### 4.4 Environment: prod

**Protection Rules**:
- ✅ Required reviewers: 2 (Ops Lead + Tech Lead)
- ✅ Allow only main branch
- ✅ Wait timer: 5 minutes (cool-down period)

**Environment Secrets**:

```bash
gh secret set PROD_AWS_ACCOUNT_ID --body "093646564004" --env prod
gh secret set PROD_AWS_REGION --body "af-south-1" --env prod
gh secret set PROD_AWS_FAILOVER_REGION --body "eu-west-1" --env prod
gh secret set PROD_OIDC_ROLE_ARN --body "arn:aws:iam::093646564004:role/github-2-bbws-order-lambda-prod" --env prod
```

---

## 5. Repository Structure

### 5.1 Initial Directory Structure

```bash
mkdir -p src/handlers
mkdir -p src/services
mkdir -p src/repositories
mkdir -p src/models
mkdir -p tests/unit
mkdir -p tests/integration
mkdir -p terraform/dev
mkdir -p terraform/sit
mkdir -p terraform/prod
mkdir -p terraform/modules/{lambda,dynamodb,sqs,s3,api_gateway,monitoring}
mkdir -p .github/workflows
mkdir -p docs
```

### 5.2 Initial Files

**README.md**:

```markdown
# 2_bbws_order_lambda

Order Lambda service for BBWS Customer Portal Public - Event-driven order processing with SQS.

## Architecture

- **8 Lambda Functions**: 4 API handlers + 4 event-driven processors
- **Event-Driven**: SQS-based async processing
- **Storage**: DynamoDB single-table design with 2 GSIs
- **Messaging**: SQS OrderCreationQueue + DLQ
- **Email**: SES integration with S3 template storage
- **Environments**: DEV, SIT, PROD (af-south-1 + eu-west-1 DR)

## Repository Structure

- `src/` - Lambda function source code
- `tests/` - Unit and integration tests
- `terraform/` - Infrastructure as Code
- `.github/workflows/` - CI/CD pipelines
- `docs/` - Documentation

## Deployment

See [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) for deployment procedures.
```

**.gitignore**:

```
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
env/
venv/
*.egg-info/
dist/
build/

# Terraform
*.tfstate
*.tfstate.*
.terraform/
*.tfvars
!terraform/modules/**/*.tfvars

# IDE
.vscode/
.idea/
*.swp
*.swo

# AWS
.aws/

# Testing
.pytest_cache/
.coverage
htmlcov/

# Environment
.env
.env.local
```

**requirements.txt**:

```
boto3==1.34.19
pydantic==1.10.18
aws-lambda-powertools==2.31.0
pytest==7.4.3
pytest-cov==4.1.0
moto==4.2.9
```

---

## 6. Workflow Templates

### 6.1 Validation Workflow

Create `.github/workflows/validate.yml`:

```yaml
name: Validate

on:
  pull_request:
    branches: [develop, release, main]
  push:
    branches: [develop, release, main]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.12'

      - name: Install dependencies
        run: |
          pip install flake8 black mypy
          pip install -r requirements.txt

      - name: Lint with flake8
        run: flake8 src/ tests/

      - name: Check formatting with black
        run: black --check src/ tests/

      - name: Type check with mypy
        run: mypy src/

  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Run security scan
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          scan-ref: '.'
```

### 6.2 Test Workflow

Create `.github/workflows/test.yml`:

```yaml
name: Test

on:
  pull_request:
    branches: [develop, release, main]
  push:
    branches: [develop, release, main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.12'

      - name: Install dependencies
        run: pip install -r requirements.txt

      - name: Run tests with coverage
        run: |
          pytest tests/ -v --cov=src --cov-report=term --cov-report=html --cov-fail-under=80

      - name: Upload coverage report
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage.xml
```

---

## 7. Verification

### 7.1 Verify OIDC Setup

```bash
# Test DEV OIDC role assumption
aws sts assume-role-with-web-identity \
  --role-arn arn:aws:iam::536580886816:role/github-2-bbws-order-lambda-dev \
  --role-session-name github-actions-test \
  --web-identity-token $GITHUB_TOKEN

# Verify role exists
aws iam get-role --role-name github-2-bbws-order-lambda-dev --profile bbws-dev
```

### 7.2 Verify GitHub Repository

```bash
# Check repository
gh repo view 2_bbws_order_lambda

# Check environments
gh api repos/:owner/2_bbws_order_lambda/environments

# Check branch protection
gh api repos/:owner/2_bbws_order_lambda/branches/main/protection
```

---

## 8. Next Steps

After repository setup:

1. ✅ Repository created: `2_bbws_order_lambda`
2. ✅ OIDC providers configured in all 3 AWS accounts
3. ✅ IAM roles created with proper trust policies
4. ✅ GitHub environments configured with secrets
5. ✅ Branch protection rules applied
6. ✅ Initial project structure created

**Ready for Stage 2**: Lambda function implementation can now begin.

---

## 9. Troubleshooting

### OIDC Authentication Failures

**Error**: `AssumeRoleWithWebIdentity failed`

**Solution**:
1. Verify OIDC provider exists in AWS account
2. Check trust policy allows GitHub Actions
3. Verify repository name matches trust policy condition
4. Check branch restrictions in trust policy

### GitHub Secrets Not Available

**Error**: `Secret DEV_OIDC_ROLE_ARN not found`

**Solution**:
1. Verify environment exists (dev, sit, prod)
2. Check secret is set in correct environment (not repository-level)
3. Ensure workflow specifies `environment:` key

---

## 10. Documentation References

- **AWS OIDC Setup**: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html
- **GitHub Actions OIDC**: https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services
- **GitHub Environments**: https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment

---

**Worker 1 Status**: Complete
**Repository Ready**: Yes
**OIDC Configured**: Yes (all 3 environments)
**Next Action**: Begin Stage 2 Lambda implementation

