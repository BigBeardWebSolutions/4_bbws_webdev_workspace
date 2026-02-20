# DevOps CI/CD Pipeline Plan Template

**Version**: 1.0
**Created**: 2026-01-01
**Purpose**: Template for creating CI/CD pipeline plans following the Agentic Project Manager pattern

---

## Template Usage

Use this template when creating CI/CD pipeline stages for infrastructure or application deployments. This template follows the proven pattern from `project-plan-1/stage-4-cicd-pipeline`.

---

# Stage {N}: CI/CD Pipeline Development

**Stage ID**: stage-{n}-cicd-pipeline
**Project**: {project-name}
**Status**: ⏳ PENDING
**Workers**: {N} (parallel execution)

---

## 🎯 Stage Objective

Create GitHub Actions workflows for {describe purpose: validation, terraform plan/apply, deployment, and rollback} with approval gates for DEV, SIT, and PROD environments.

---

## 🌍 Environment Configuration

### DEV Environment
| Setting | Value |
|---------|-------|
| Account | {dev_account_id} |
| Region | {dev_region} |
| AWS Role | arn:aws:iam::{dev_account_id}:role/{role_name} |
| Required Approvers | 1 |
| Trigger | Auto on push / Manual |

### SIT Environment
| Setting | Value |
|---------|-------|
| Account | {sit_account_id} |
| Region | {sit_region} |
| AWS Role | arn:aws:iam::{sit_account_id}:role/{role_name} |
| Required Approvers | 2 |
| Trigger | Manual only |

### PROD Environment
| Setting | Value |
|---------|-------|
| Account | {prod_account_id} |
| Region | {prod_region} |
| AWS Role | arn:aws:iam::{prod_account_id}:role/{role_name} |
| Required Approvers | 3 |
| Trigger | Manual only + Change ticket |

---

## 👷 Stage Workers

| # | Worker | Task | Status | Lines |
|---|--------|------|--------|-------|
| 1 | worker-1-validation-workflows | Create validation workflows (terraform validate, lint) | ⏳ PENDING | ~{N} |
| 2 | worker-2-terraform-plan-workflow | Create terraform plan workflow with PR comments | ⏳ PENDING | ~{N} |
| 3 | worker-3-deployment-workflows | Create deployment workflows (dev, sit, prod) | ⏳ PENDING | ~{N} |
| 4 | worker-4-rollback-workflow | Create rollback workflow with approvals | ⏳ PENDING | ~{N} |
| 5 | worker-5-test-scripts | Create post-deployment test scripts | ⏳ PENDING | ~{N} |

---

## 📥 Stage Inputs

**From Previous Stage(s)**:
- {Input 1 - e.g., Terraform modules}
- {Input 2 - e.g., Environment configurations}
- {Input 3 - e.g., Variable definitions}

**From Documentation**:
- {LLD reference - e.g., CI/CD Pipeline Design section}
- {Security requirements}

---

## 📤 Stage Outputs

### Workflow Files
- `.github/workflows/validate.yml` - Terraform validation
- `.github/workflows/terraform-plan.yml` - Plan with PR comments
- `.github/workflows/deploy-dev.yml` - DEV deployment
- `.github/workflows/deploy-sit.yml` - SIT deployment (manual)
- `.github/workflows/deploy-prod.yml` - PROD deployment (manual + approval)
- `.github/workflows/rollback.yml` - Emergency rollback

### Test Scripts
- `tests/test_deployment.py` - Post-deployment validation
- `tests/requirements.txt` - Test dependencies

---

## 🔧 Worker Specifications

### Worker 1: Validation Workflows

**Objective**: Create workflows that validate code on PR/push

**Deliverables**:
```yaml
# .github/workflows/validate.yml
name: Validate Terraform
on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

jobs:
  validate:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        environment: [dev, sit, prod]
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
      - name: Terraform Init
        run: terraform init -backend=false
      - name: Terraform Validate
        run: terraform validate
      - name: Terraform Format Check
        run: terraform fmt -check -recursive
```

**Quality Criteria**:
- [ ] Valid YAML syntax
- [ ] Matrix strategy for all environments
- [ ] PR comment integration
- [ ] Exit codes handled correctly

---

### Worker 2: Terraform Plan Workflow

**Objective**: Create plan workflow with PR comments and artifact storage

**Deliverables**:
```yaml
# .github/workflows/terraform-plan.yml
name: Terraform Plan
on:
  pull_request:
    branches: [main]

permissions:
  id-token: write
  contents: read
  pull-requests: write

jobs:
  plan-dev:
    runs-on: ubuntu-latest
    environment: dev
    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_DEV }}
          aws-region: {region}

      - uses: hashicorp/setup-terraform@v3

      - name: Terraform Init
        run: |
          terraform init \
            -backend-config="bucket={state_bucket}" \
            -backend-config="key={state_key}" \
            -backend-config="region={region}"

      - name: Terraform Plan
        run: terraform plan -var-file=environments/dev.tfvars -out=tfplan

      - name: Upload Plan Artifact
        uses: actions/upload-artifact@v4
        with:
          name: tfplan-dev
          path: tfplan
          retention-days: 30
```

**Quality Criteria**:
- [ ] AWS OIDC authentication (no long-lived credentials)
- [ ] Plan artifacts stored for 30 days
- [ ] PR comments with plan summary
- [ ] Parallel jobs for all environments

---

### Worker 3: Deployment Workflows

**Objective**: Create deployment workflows with approval gates

**Deliverables**:

```yaml
# .github/workflows/deploy-{env}.yml
name: Deploy to {ENV}
on:
  workflow_dispatch:
    inputs:
      confirm:
        description: 'Type "deploy-{env}" to confirm'
        required: true

permissions:
  id-token: write
  contents: read

jobs:
  validate-confirmation:
    runs-on: ubuntu-latest
    steps:
      - name: Validate Confirmation
        if: ${{ github.event.inputs.confirm != 'deploy-{env}' }}
        run: |
          echo "Confirmation string invalid"
          exit 1

  deploy:
    needs: validate-confirmation
    runs-on: ubuntu-latest
    environment: {env}  # Triggers approval gate
    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_{ENV} }}
          aws-region: {region}

      - uses: hashicorp/setup-terraform@v3

      - name: Terraform Init
        run: |
          terraform init \
            -backend-config="bucket={state_bucket}" \
            -backend-config="key={state_key}" \
            -backend-config="region={region}"

      - name: Terraform Apply
        run: terraform apply -var-file=environments/{env}.tfvars -auto-approve

      - name: Create Deployment Tag
        run: |
          git tag "deploy-{env}-$(date +%Y%m%d-%H%M%S)"
          git push origin --tags

  post-deploy-validation:
    needs: deploy
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: '3.12'
      - name: Install Dependencies
        run: pip install -r tests/requirements.txt
      - name: Run Validation Tests
        run: pytest tests/test_deployment.py --env={env} -v
```

**Approval Gates**:
- DEV: 1 required approver
- SIT: 2 required approvers
- PROD: 3 required approvers + change ticket

**Quality Criteria**:
- [ ] Manual trigger (workflow_dispatch)
- [ ] Confirmation string validation
- [ ] GitHub Environment protection
- [ ] Deployment tagging
- [ ] Post-deployment validation
- [ ] Slack notifications (PROD only)

---

### Worker 4: Rollback Workflow

**Objective**: Create emergency rollback workflow

**Deliverables**:
```yaml
# .github/workflows/rollback.yml
name: Emergency Rollback
on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to rollback'
        required: true
        type: choice
        options:
          - dev
          - sit
          - prod
      deployment_tag:
        description: 'Deployment tag to rollback to'
        required: true

permissions:
  id-token: write
  contents: read

jobs:
  rollback-approval:
    runs-on: ubuntu-latest
    environment: rollback-approval  # Requires 2 approvers
    steps:
      - name: Validate Tag
        run: |
          if ! git rev-parse "${{ github.event.inputs.deployment_tag }}" >/dev/null 2>&1; then
            echo "Invalid deployment tag"
            exit 1
          fi

  rollback:
    needs: rollback-approval
    runs-on: ubuntu-latest
    environment: rollback-apply  # Requires 2 approvers
    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${{ github.event.inputs.deployment_tag }}

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets[format('AWS_ROLE_{0}', upper(github.event.inputs.environment))] }}
          aws-region: {region}

      - uses: hashicorp/setup-terraform@v3

      - name: Terraform Apply (Rollback)
        run: |
          terraform init
          terraform apply -var-file=environments/${{ github.event.inputs.environment }}.tfvars -auto-approve

      - name: Create Rollback Tag
        run: |
          git tag "rollback-${{ github.event.inputs.environment }}-$(date +%Y%m%d-%H%M%S)"
          git push origin --tags
```

**Quality Criteria**:
- [ ] Git tag validation
- [ ] Dual approval gates (plan + apply)
- [ ] Slack emergency notifications
- [ ] Audit trail (tags + records)

---

### Worker 5: Post-Deployment Test Scripts

**Objective**: Create Python test scripts for post-deployment validation

**Deliverables**:

```python
# tests/test_deployment.py
import boto3
import pytest
import argparse

class TestDeployment:
    """Post-deployment validation tests"""

    @pytest.fixture(autouse=True)
    def setup(self, request):
        """Setup test environment"""
        self.env = request.config.getoption("--env")
        self.region = self._get_region(self.env)
        self.session = boto3.Session(region_name=self.region)

    def _get_region(self, env):
        regions = {
            "dev": "eu-west-1",
            "sit": "eu-west-1",
            "prod": "af-south-1"
        }
        return regions.get(env, "eu-west-1")

    def test_resource_exists(self):
        """Verify deployed resource exists"""
        # Add resource-specific tests
        assert True

    def test_configuration_correct(self):
        """Verify resource configuration"""
        # Add configuration validation
        assert True

def pytest_addoption(parser):
    parser.addoption("--env", action="store", default="dev")
```

```text
# tests/requirements.txt
boto3>=1.34.0
pytest>=7.4.0
pytest-cov>=4.1.0
```

**Quality Criteria**:
- [ ] CLI arguments (--env)
- [ ] JSON test reports for CI/CD
- [ ] Exit codes: 0 (pass), 1 (fail)
- [ ] Pytest compatible

---

## ✅ Success Criteria

| Criterion | Status |
|-----------|--------|
| All {N} workers completed | ⏳ |
| All workflows YAML valid | ⏳ |
| Approval gates configured (1/2/3) | ⏳ |
| Environment protection rules specified | ⏳ |
| Test scripts executable | ⏳ |
| AWS OIDC authentication (no long-lived credentials) | ⏳ |
| Slack notifications (PROD) | ⏳ |
| Stage summary created | ⏳ |

---

## 🔒 Security Checklist

### GitHub Actions Security
- [ ] AWS OIDC Authentication (no long-lived credentials)
- [ ] Approval gates (progressive: 1 → 2 → 3)
- [ ] Environment protection rules
- [ ] Secret management (GitHub Secrets)
- [ ] Least privilege IAM roles
- [ ] Audit trail (git tags, Slack)

### Required GitHub Secrets
| Secret | Description |
|--------|-------------|
| AWS_ROLE_DEV | IAM role ARN for DEV |
| AWS_ROLE_SIT | IAM role ARN for SIT |
| AWS_ROLE_PROD | IAM role ARN for PROD |
| SLACK_WEBHOOK_URL | Slack webhook for notifications |

### Required GitHub Environments
| Environment | Required Reviewers | Branch Restriction |
|-------------|-------------------|-------------------|
| dev | 1 | main |
| sit | 2 | main |
| prod | 3 | main |
| rollback-approval | 2 | main |
| rollback-apply | 2 | main |

---

## 📊 CI/CD Pipeline Flow

```
┌─────────────────────────────────────────────────────────┐
│ STAGE 1: CODE PUSH                                      │
├─────────────────────────────────────────────────────────┤
│ - Developer pushes to feature branch                    │
│ - Creates pull request to main                          │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│ STAGE 2: AUTOMATED VALIDATION (on PR)                  │
├─────────────────────────────────────────────────────────┤
│ - validate.yml (terraform validate, fmt)                │
│ - PR comments with validation results                   │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│ STAGE 3: TERRAFORM PLAN (on PR)                        │
├─────────────────────────────────────────────────────────┤
│ - terraform-plan.yml runs for all 3 environments        │
│ - Plan artifacts stored (30 days)                       │
│ - PR comment with plan summary                          │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│ GATE 1: CODE REVIEW APPROVAL                           │
├─────────────────────────────────────────────────────────┤
│ - Human review of code changes                          │
│ - Review terraform plan outputs                         │
│ - Approve and merge PR to main                          │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│ STAGE 4: DEPLOY TO DEV (auto or manual)                │
├─────────────────────────────────────────────────────────┤
│ - deploy-dev.yml triggered                              │
│ - 1 approver required                                   │
│ - Terraform apply                                       │
│ - Post-deployment validation                            │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│ STAGE 5: PROMOTE TO SIT (manual)                       │
├─────────────────────────────────────────────────────────┤
│ - deploy-sit.yml triggered manually                     │
│ - 2 approvers required                                  │
│ - Terraform apply                                       │
│ - Post-deployment validation                            │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│ STAGE 6: PROMOTE TO PROD (manual + ticket)             │
├─────────────────────────────────────────────────────────┤
│ - deploy-prod.yml triggered manually                    │
│ - 3 approvers required + change ticket                  │
│ - Terraform apply                                       │
│ - Post-deployment validation                            │
│ - Slack notification                                    │
└─────────────────────────────────────────────────────────┘
```

**Rollback Path**: Use rollback.yml to revert to previous deployment tag

---

## 📋 Implementation Checklist

### Prerequisites
- [ ] GitHub repository created
- [ ] AWS OIDC provider configured in each account
- [ ] IAM roles created for GitHub Actions

### GitHub Configuration
- [ ] Add GitHub Secrets (AWS_ROLE_DEV, AWS_ROLE_SIT, AWS_ROLE_PROD)
- [ ] Create GitHub Environments (dev, sit, prod, rollback-approval, rollback-apply)
- [ ] Configure environment protection rules
- [ ] Add required reviewers

### File Deployment
- [ ] Copy workflows to `.github/workflows/`
- [ ] Copy test scripts to `tests/`
- [ ] Copy requirements.txt to repo root
- [ ] Commit and push to main

---

## 🔗 Dependencies

- **Depends on**: Stage {N-1} ({previous_stage_name})
- **Blocks**: Stage {N+1} ({next_stage_name})

---

## ⏱️ Estimated Duration

| Activity | Agentic | Manual |
|----------|---------|--------|
| Worker 1 (Validation) | 10 min | 2 hours |
| Worker 2 (Plan) | 10 min | 2 hours |
| Worker 3 (Deployment) | 15 min | 4 hours |
| Worker 4 (Rollback) | 10 min | 2 hours |
| Worker 5 (Tests) | 15 min | 3 hours |
| **Total** | **~1 hour** | **~2 days** |

---

**Template Version**: 1.0
**Last Updated**: 2026-01-01
**Based On**: project-plan-1/stage-4-cicd-pipeline
