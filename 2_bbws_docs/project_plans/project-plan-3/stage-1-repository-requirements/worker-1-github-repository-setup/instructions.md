# Worker 1: GitHub Repository Setup

**Worker Task**: Create and configure GitHub repository with OIDC authentication
**Parent Stage**: Stage 1 - Repository Requirements
**LLD Reference**: 2.1.8_LLD_Order_Lambda.md

---

## Task Description

Set up a new GitHub repository for the Order Lambda service (`2_bbws_order_lambda`) with proper OIDC authentication configuration. This enables secure CI/CD deployments to AWS without storing long-lived credentials in GitHub secrets.

### Key Responsibilities

1. Create GitHub repository with standard configuration
2. Configure OIDC authentication for three AWS environments (DEV, SIT, PROD)
3. Set up branch protection rules and required reviews
4. Create GitHub Actions workflow templates for CI/CD
5. Document repository secrets and environment variables needed
6. Configure issue templates and contribution guidelines

---

## Inputs

### Required Information

| Item | Source | Purpose |
|------|--------|---------|
| Repository Name | BBWS Convention | `2_bbws_order_lambda` |
| AWS Account (DEV) | BBWS Configuration | 536580886816 |
| AWS Account (SIT) | BBWS Configuration | 815856636111 |
| AWS Account (PROD) | BBWS Configuration | 093646564004 |
| BBWS Naming Standards | BBWS Documentation | Repository structure and naming |
| GitHub Organization | User Configuration | Organization to host repository |

### AWS Account Details

**Development Environment (DEV)**
- AWS Account ID: 536580886816
- Region: af-south-1 (primary)
- Purpose: Development and testing

**System Integration Testing (SIT)**
- AWS Account ID: 815856636111
- Region: af-south-1 (primary)
- Purpose: Pre-production validation

**Production (PROD)**
- AWS Account ID: 093646564004
- Region: af-south-1 (primary)
- Failover Region: eu-west-1
- Purpose: Live production environment

---

## Deliverables

### Output Document: `output.md`

The final output must be saved as `/worker-1-github-repository-setup/output.md` and include:

1. **Repository Metadata**
   - Repository URL
   - Repository Owner/Organization
   - Visibility (private/public)
   - Default Branch

2. **OIDC Configuration**
   - OIDC Provider URL
   - Role ARN for DEV environment
   - Role ARN for SIT environment
   - Role ARN for PROD environment
   - Subject claim format for GitHub Actions

3. **Branch Protection Configuration**
   - Main branch protection rules
   - Required status checks
   - Require code review settings
   - Dismiss stale reviews when new commits are pushed

4. **Repository Secrets Template**
   - List of all GitHub secrets needed
   - Secret naming convention used
   - Purpose of each secret

5. **GitHub Actions Workflows Configured**
   - List of workflow files created
   - Workflow templates for DEV, SIT, PROD deployments
   - OIDC role assumption configuration

6. **Repository Structure**
   - Directory layout created
   - Initial files and configurations
   - README.md with setup instructions

7. **Verification Checklist**
   - OIDC authentication tested successfully for all 3 environments
   - Repository secrets accessible in GitHub Actions
   - Branch protection rules enforced
   - Repository visibility correct

---

## Success Criteria

### Must-Have Criteria

- [ ] GitHub repository created with name `2_bbws_order_lambda`
- [ ] Repository is private (not public)
- [ ] OIDC authentication configured for all 3 AWS environments
- [ ] IAM roles created in each AWS account with proper trust policy
- [ ] OIDC trust policy includes correct GitHub organization/repository path
- [ ] Main branch has protection rules (require code review, status checks)
- [ ] Default branch is set to `main`
- [ ] Repository has standard issue templates (Bug, Feature, Documentation)
- [ ] Contributing.md file created with development guidelines

### Should-Have Criteria

- [ ] GitHub Actions workflows created for test, lint, and build stages
- [ ] Secret management documentation provided
- [ ] OIDC role ARNs documented and tested
- [ ] GitHub Actions OIDC token request configured in workflow
- [ ] Role assumption in each environment tested
- [ ] Deployment approval gates configured (SIT, PROD)
- [ ] Repository secrets list documented with purposes

### Validation Criteria

- [ ] User can clone repository successfully
- [ ] OIDC authentication can assume IAM roles in all 3 environments
- [ ] GitHub Actions can access AWS APIs without stored credentials
- [ ] Branch protection prevents direct pushes to main
- [ ] Pull requests require approvals before merge

---

## Execution Steps

### Step 1: Create GitHub Repository

**Action**: Create new repository in GitHub organization

```bash
# Repository Details
Name: 2_bbws_order_lambda
Description: Order Lambda Service for BBWS Customer Portal - Event-driven order processing
Visibility: Private
Include README.md: Yes
.gitignore: Python
License: (Select appropriate for organization)
```

**Deliverable Evidence**:
- Repository URL
- Repository creation timestamp
- Initial commit hash

### Step 2: Configure OIDC Authentication

**Action**: Set up OIDC authentication for CI/CD

**For Each Environment (DEV, SIT, PROD)**:

1. Create IAM role in AWS account
   - Role name: `github-2-bbws-order-lambda-{environment}`
   - Trust entity: Web identity (OIDC)
   - Provider: `token.actions.githubusercontent.com`
   - Subject claim: `repo:{GitHub_Org}/2_bbws_order_lambda:*`
   - Max session duration: 3600 seconds (1 hour)

2. Attach permission policies
   - CloudFormation/Terraform execution permissions
   - S3 access for artifacts and state
   - DynamoDB table permissions
   - Lambda deployment permissions
   - SQS, SES, API Gateway permissions

3. Document IAM role ARN

**Deliverable Evidence**:
- IAM role creation screenshot (each environment)
- Trust policy JSON showing OIDC configuration
- Role ARN for each environment (formatted for GitHub Actions)

### Step 3: Set Up Branch Protection Rules

**Action**: Configure main branch protection

```yaml
Branch: main
Settings:
  - Require pull request reviews before merging: Yes
  - Number of required reviews: 2
  - Dismiss stale pull request approvals when new commits are pushed: Yes
  - Require status checks to pass before merging: Yes
  - Require branches to be up to date before merging: Yes
  - Require code quality checks to pass: Yes
  - Include administrators: Yes
```

**Deliverable Evidence**:
- Screenshot of branch protection rules
- Confirmation of settings applied

### Step 4: Create Repository Structure

**Action**: Initialize repository structure

```
2_bbws_order_lambda/
├── .github/
│   ├── workflows/
│   │   ├── test.yml (Unit and integration tests)
│   │   ├── lint.yml (Code quality checks)
│   │   ├── deploy-dev.yml (DEV deployment)
│   │   ├── deploy-sit.yml (SIT deployment)
│   │   └── deploy-prod.yml (PROD deployment)
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.md
│   │   ├── feature_request.md
│   │   └── documentation.md
│   └── pull_request_template.md
├── src/
│   ├── handlers/
│   ├── services/
│   ├── repositories/
│   └── models/
├── tests/
│   ├── unit/
│   ├── integration/
│   └── e2e/
├── terraform/
│   ├── dev/
│   ├── sit/
│   └── prod/
├── docs/
├── .gitignore
├── .pre-commit-config.yaml
├── CONTRIBUTING.md
├── README.md
├── requirements.txt
└── setup.py
```

**Deliverable Evidence**:
- Git log showing initial commit
- Repository file structure screenshot

### Step 5: Create GitHub Actions Workflows

**Action**: Create workflow templates for CI/CD

**File**: `.github/workflows/deploy-dev.yml`

```yaml
name: Deploy to DEV

on:
  push:
    branches: [develop]
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read

    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::536580886816:role/github-2-bbws-order-lambda-dev
          aws-region: af-south-1

      - name: Deploy with Terraform
        run: |
          cd terraform/dev
          terraform init
          terraform plan
          terraform apply -auto-approve
```

**Files to Create**:
- `.github/workflows/test.yml` - Run unit and integration tests
- `.github/workflows/lint.yml` - Code quality and security checks
- `.github/workflows/deploy-dev.yml` - Deploy to DEV environment
- `.github/workflows/deploy-sit.yml` - Deploy to SIT with approval gate
- `.github/workflows/deploy-prod.yml` - Deploy to PROD with approval gate

**Deliverable Evidence**:
- Workflow YAML files saved to repository
- GitHub Actions test run showing workflows detected

### Step 6: Create GitHub Secrets Template

**Action**: Document required GitHub secrets and environment variables

**Template Document**: `docs/github-secrets-template.md`

```markdown
# GitHub Secrets Configuration

## Repository Secrets

Ensure the following secrets are configured in GitHub repository settings:

### DEV Environment
- `DEV_AWS_ACCOUNT_ID`: 536580886816
- `DEV_AWS_ROLE_NAME`: github-2-bbws-order-lambda-dev
- `DEV_ENVIRONMENT`: dev

### SIT Environment
- `SIT_AWS_ACCOUNT_ID`: 815856636111
- `SIT_AWS_ROLE_NAME`: github-2-bbws-order-lambda-sit
- `SIT_ENVIRONMENT`: sit

### PROD Environment
- `PROD_AWS_ACCOUNT_ID`: 093646564004
- `PROD_AWS_ROLE_NAME`: github-2-bbws-order-lambda-prod
- `PROD_ENVIRONMENT`: prod
```

**Deliverable Evidence**:
- Secrets template document created
- Screenshot showing GitHub secrets configured (values masked)

### Step 7: Create Contributing Guidelines

**Action**: Create CONTRIBUTING.md with development guidelines

**Content**:
- Development setup instructions
- Git workflow (main → feature branches)
- Code style guide (Python)
- Testing requirements (TDD approach)
- Pull request process
- Commit message conventions
- Running tests locally

**Deliverable Evidence**:
- CONTRIBUTING.md file in repository
- README.md updated with links to contributing guidelines

### Step 8: Verify OIDC Authentication

**Action**: Test OIDC authentication end-to-end

**Testing Steps**:
1. Create test workflow that assumes IAM role in DEV
2. Run workflow and verify role assumption succeeds
3. Verify AWS CLI calls within workflow execute successfully
4. Repeat for SIT and PROD environments
5. Document results

**Deliverable Evidence**:
- GitHub Actions workflow run logs showing successful role assumption
- AWS CloudTrail logs showing GitHub Actions principal making API calls
- IAM role trust policy verification

---

## Output Format

### Output File: `worker-1-github-repository-setup/output.md`

```markdown
# Worker 1 Output: GitHub Repository Setup

**Date Completed**: YYYY-MM-DD
**Worker**: [Your Name/Identifier]
**Status**: Complete / In Progress / Blocked

## Executive Summary

[Summary of repository created and OIDC configuration]

## Repository Metadata

| Item | Value |
|------|-------|
| Repository URL | https://github.com/[org]/2_bbws_order_lambda |
| Repository Owner | [GitHub Organization] |
| Default Branch | main |
| Visibility | Private |

## OIDC Configuration

### DEV Environment
- **AWS Account ID**: 536580886816
- **IAM Role**: github-2-bbws-order-lambda-dev
- **Role ARN**: arn:aws:iam::536580886816:role/github-2-bbws-order-lambda-dev
- **Verification**: ✓ Tested and working

### SIT Environment
- **AWS Account ID**: 815856636111
- **IAM Role**: github-2-bbws-order-lambda-sit
- **Role ARN**: arn:aws:iam::815856636111:role/github-2-bbws-order-lambda-sit
- **Verification**: ✓ Tested and working

### PROD Environment
- **AWS Account ID**: 093646564004
- **IAM Role**: github-2-bbws-order-lambda-prod
- **Role ARN**: arn:aws:iam::093646564004:role/github-2-bbws-order-lambda-prod
- **Verification**: ✓ Tested and working

## Branch Protection Rules

- [x] Require pull request reviews: 2 required
- [x] Dismiss stale reviews on new commits
- [x] Require status checks to pass
- [x] Require branches to be up to date

## Repository Structure

### Created Files/Directories
- `.github/workflows/` - CI/CD automation
- `src/` - Application code
- `tests/` - Test suites
- `terraform/` - Infrastructure as Code
- `docs/` - Documentation

### Workflow Files Created
- `.github/workflows/test.yml`
- `.github/workflows/lint.yml`
- `.github/workflows/deploy-dev.yml`
- `.github/workflows/deploy-sit.yml`
- `.github/workflows/deploy-prod.yml`

## Verification Results

| Check | Result | Evidence |
|-------|--------|----------|
| Repository created | ✓ Pass | URL: [link] |
| OIDC configured (DEV) | ✓ Pass | Workflow run: [link] |
| OIDC configured (SIT) | ✓ Pass | Workflow run: [link] |
| OIDC configured (PROD) | ✓ Pass | Workflow run: [link] |
| Branch protection active | ✓ Pass | Settings screenshot |
| Workflows detected | ✓ Pass | GitHub Actions tab |

## Next Steps

1. Worker 2 to extract requirements from LLD
2. Worker 3 to validate naming conventions
3. Worker 4 to analyze environment configurations
4. Proceed to Stage 2 implementation once all workers complete

## Issues/Blockers

[Note any issues encountered]

## Additional Notes

[Any relevant information about repository setup]
```

---

## References

- **GitHub OIDC Documentation**: https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect
- **AWS OIDC Provider Setup**: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-idp_oidc.html
- **BBWS Documentation**: `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/CLAUDE.md`

---

**Document Version**: 1.0
**Created**: 2025-12-30
