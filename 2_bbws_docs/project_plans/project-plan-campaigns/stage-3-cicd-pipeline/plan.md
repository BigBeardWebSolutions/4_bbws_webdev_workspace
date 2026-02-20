# Stage 3: CI/CD Pipeline Development

**Stage ID**: stage-3-cicd-pipeline
**Project**: project-plan-campaigns
**Status**: PENDING
**Workers**: 4 (parallel execution)

---

## Stage Objective

Create GitHub Actions workflows for build, test, deployment, and environment promotion.

---

## Stage Workers

| Worker | Task | Status |
|--------|------|--------|
| worker-1-build-test-workflow | Create build and test workflow | PENDING |
| worker-2-terraform-plan-workflow | Create Terraform plan workflow | PENDING |
| worker-3-deploy-workflow | Create deployment workflow | PENDING |
| worker-4-promotion-workflow | Create environment promotion workflow | PENDING |

---

## Stage Inputs

**From Stage 2**:
- Lambda source code
- Test files
- Requirements files

**Primary Reference**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/2.1.3_LLD_Campaigns_Lambda.md`

---

## Stage Outputs

### GitHub Workflows
```
.github/
└── workflows/
    ├── build-test.yml        # PR validation, unit tests
    ├── terraform-plan.yml    # Terraform plan on PR
    ├── deploy.yml            # Deploy to environment
    └── promotion.yml         # Promote between environments
```

---

## Workflow Descriptions

### 1. Build & Test Workflow (build-test.yml)
- Triggered on: Pull Requests
- Python setup (3.12)
- Install dependencies
- Run linting (black, isort, flake8)
- Run unit tests with coverage
- Upload coverage report

### 2. Terraform Plan Workflow (terraform-plan.yml)
- Triggered on: Pull Requests
- Terraform init
- Terraform validate
- Terraform plan
- Post plan as PR comment

### 3. Deploy Workflow (deploy.yml)
- Triggered on: Push to main (DEV), manual for SIT/PROD
- Build Lambda package
- Upload to S3
- Terraform apply
- Validate deployment

### 4. Promotion Workflow (promotion.yml)
- Triggered on: Manual dispatch
- Promote from DEV to SIT
- Promote from SIT to PROD
- Requires approval for PROD

---

## Environment Strategy

From CLAUDE.md:
> "I have three environments, dev, sit and prod. I am now deploying to dev. Whatever we fix in dev, the workload will be promoted to sit, when sit is tested, the workload will be promoted to prod"

### Deployment Flow
```
DEV (eu-west-1) -> SIT (eu-west-1) -> PROD (af-south-1)
   Auto deploy      Manual promote    Manual promote
                                      + Approval
```

---

## Success Criteria

- [ ] All workflows pass validation
- [ ] Build & test workflow runs on PRs
- [ ] Terraform plan posts to PR
- [ ] Deploy workflow works for DEV
- [ ] Promotion workflow works between environments
- [ ] PROD deployment requires approval
- [ ] All 4 workers completed
- [ ] Stage summary created

---

## Dependencies

**Depends On**: Stage 2 (Lambda Code Development)

**Blocks**: Stage 4 (Testing)

---

**Created**: 2026-01-15
