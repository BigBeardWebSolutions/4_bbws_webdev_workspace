# Stage 8: CI/CD Pipeline

**Parent Plan**: [BBWS SDLC Main Plan](./main-plan.md)
**Stage**: 8 of 10
**Status**: ⏳ PENDING
**Last Updated**: 2026-01-01

---

## Objective

Create GitHub Actions CI/CD workflows for automated testing, building, and deployment across DEV, SIT, and PROD environments using OIDC authentication.

---

## Agent & Skill Assignment

| Role | Agent | Skill |
|------|-------|-------|
| **Primary** | DevOps_Engineer_Agent | `github_oidc_cicd.skill.md` |
| **Support** | - | `dns_environment_naming.skill.md` |

**Agent Path**: `agentic_architect/DevOps_Engineer_Agent.md`
**Skill Path**: `devops/skills/github_oidc_cicd.skill.md`

---

## Workers

| # | Worker | Task | Status | Output |
|---|--------|------|--------|--------|
| 1 | worker-1-ci-workflow | Create CI workflow (test, lint, build) | ⏳ PENDING | `.github/workflows/ci.yml` |
| 2 | worker-2-deploy-workflows | Create deployment workflows | ⏳ PENDING | `.github/workflows/deploy-*.yml` |
| 3 | worker-3-reusable-workflows | Create reusable workflow components | ⏳ PENDING | `.github/workflows/` |

---

## Worker Instructions

### Worker 1: CI Workflow

**Objective**: Create continuous integration workflow

**Skill Reference**: Apply `github_oidc_cicd.skill.md`

**Deliverables**:
- `.github/workflows/ci.yml`

**Workflow Pattern**:
```yaml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

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
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements-dev.txt

      - name: Run black (formatting)
        run: black --check src/ tests/

      - name: Run mypy (type checking)
        run: mypy src/

      - name: Run ruff (linting)
        run: ruff check src/ tests/

      - name: Run tests
        run: pytest tests/ -v --cov=src --cov-report=term-missing --cov-fail-under=80
```

**Quality Criteria**:
- [ ] Runs on push and PR
- [ ] Tests with coverage enforcement
- [ ] Code quality checks (black, mypy, ruff)
- [ ] Fast feedback (< 5 minutes)

---

### Worker 2: Deployment Workflows

**Objective**: Create environment-specific deployment workflows

**Skill Reference**: Apply `github_oidc_cicd.skill.md`

**Deliverables**:
```
.github/workflows/
├── deploy-dev.yml     # Auto-deploy on push to main
├── deploy-sit.yml     # Manual trigger with approval
└── deploy-prod.yml    # Manual trigger with strict approval
```

**DEV Workflow Pattern**:
```yaml
name: Deploy to DEV

on:
  push:
    branches: [main]
  workflow_dispatch:

env:
  AWS_REGION: eu-west-1
  ENVIRONMENT: dev

permissions:
  id-token: write
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: dev

    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::536580886816:role/github-actions-oidc
          aws-region: ${{ env.AWS_REGION }}

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3

      - name: Terraform Init
        working-directory: terraform
        run: |
          terraform init \
            -backend-config="bucket=bbws-terraform-state-dev" \
            -backend-config="key=product-lambda/dev/terraform.tfstate" \
            -backend-config="region=eu-west-1"

      - name: Terraform Plan
        working-directory: terraform
        run: terraform plan -var-file=environments/dev.tfvars -out=tfplan

      - name: Terraform Apply
        working-directory: terraform
        run: terraform apply -auto-approve tfplan

      - name: Run E2E Tests
        run: pytest tests/e2e/ --env=dev -v
```

**SIT Workflow Pattern** (Manual with confirmation):
```yaml
name: Deploy to SIT

on:
  workflow_dispatch:
    inputs:
      confirm:
        description: 'Type "deploy" to confirm'
        required: true

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - name: Validate confirmation
        if: github.event.inputs.confirm != 'deploy'
        run: |
          echo "Confirmation required. Type 'deploy' to proceed."
          exit 1
```

**PROD Workflow Pattern** (Strict approval):
```yaml
name: Deploy to PROD

on:
  workflow_dispatch:
    inputs:
      confirm:
        description: 'Type "deploy-to-production" to confirm'
        required: true
      reason:
        description: 'Reason for deployment'
        required: true

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - name: Validate confirmation
        if: github.event.inputs.confirm != 'deploy-to-production'
        run: |
          echo "Production deployment requires typing 'deploy-to-production'"
          exit 1
```

**Quality Criteria**:
- [ ] DEV auto-deploys on main push
- [ ] SIT requires manual trigger + "deploy" confirmation
- [ ] PROD requires manual trigger + "deploy-to-production" + reason
- [ ] OIDC authentication (no secrets)
- [ ] E2E tests run post-deployment

---

### Worker 3: Reusable Workflows

**Objective**: Create reusable workflow components

**Deliverables**:
```
.github/workflows/
├── _terraform-plan.yml     # Reusable Terraform plan
├── _terraform-apply.yml    # Reusable Terraform apply
└── _run-tests.yml          # Reusable test runner
```

**Reusable Pattern**:
```yaml
# _terraform-plan.yml
name: Terraform Plan (Reusable)

on:
  workflow_call:
    inputs:
      environment:
        required: true
        type: string
      aws_region:
        required: true
        type: string

jobs:
  plan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      # ... terraform steps
```

**Quality Criteria**:
- [ ] DRY principle applied
- [ ] Consistent across environments
- [ ] Easy to maintain

---

## Stage Outputs

| Output | Description | Location |
|--------|-------------|----------|
| CI workflow | Test/lint pipeline | `.github/workflows/ci.yml` |
| DEV deploy | Auto-deployment | `.github/workflows/deploy-dev.yml` |
| SIT deploy | Manual deployment | `.github/workflows/deploy-sit.yml` |
| PROD deploy | Strict deployment | `.github/workflows/deploy-prod.yml` |
| Reusable workflows | Shared components | `.github/workflows/_*.yml` |

---

## OIDC Configuration

Each environment requires an IAM OIDC role:

| Environment | Account | Role ARN |
|-------------|---------|----------|
| DEV | 536580886816 | `arn:aws:iam::536580886816:role/github-actions-oidc` |
| SIT | 815856636111 | `arn:aws:iam::815856636111:role/github-actions-oidc` |
| PROD | 093646564004 | `arn:aws:iam::093646564004:role/github-actions-oidc` |

---

## Success Criteria

- [ ] All 3 workers completed
- [ ] CI workflow passing
- [ ] DEV deployment tested
- [ ] OIDC authentication working
- [ ] No hardcoded secrets

---

## Dependencies

**Depends On**: Stage 7 (Infrastructure)
**Blocks**: Stage 9 (Route53)

---

## Estimated Duration

| Activity | Agentic | Manual |
|----------|---------|--------|
| CI workflow | 15 min | 1 hour |
| Deploy workflows | 20 min | 2 hours |
| Reusable workflows | 10 min | 30 min |
| **Total** | **45 min** | **3.5 hours** |

---

**Navigation**: [← Stage 7](./stage-7-infrastructure.md) | [Main Plan](./main-plan.md) | [Stage 9: Route53 →](./stage-9-route53-domain.md)
