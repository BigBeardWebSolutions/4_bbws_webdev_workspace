# Stage 4: CI/CD Pipeline Development

**Stage ID**: stage-4-cicd-pipeline
**Project**: project-plan-5-lld-implementation
**Status**: PENDING
**Workers**: 6 (parallel execution)

---

## Stage Objective

Develop GitHub Actions CI/CD pipelines for all Lambda repositories, including validation, testing, Terraform planning/applying, and environment promotion workflows with human approval gates.

---

## Stage Workers

| Worker | Task | Repositories | Description |
|--------|------|--------------|-------------|
| worker-1-tenant-lambda-cicd | Tenant Lambda CI/CD | `2_bbws_tenant_lambda` | Build, test, deploy workflow |
| worker-2-site-management-cicd | Site Management CI/CD | `2_bbws_wordpress_site_management_lambda` | Build, test, deploy workflow |
| worker-3-instance-lambda-cicd | Instance Lambda CI/CD | `2_bbws_tenants_instances_lambda` | Build, test, deploy workflow |
| worker-4-terraform-pipelines | Terraform Pipelines | All repos | Plan, apply with approval gates |
| worker-5-gitops-workflows | GitOps Workflows | `2_bbws_tenants_instances_dev` | Instance provisioning via GitOps |
| worker-6-test-automation | Test Automation | All repos | pytest integration, coverage |

---

## Stage Inputs

| Input | Source |
|-------|--------|
| Lambda Code | Stage 2 & 3 outputs |
| Terraform Modules | Each repository |
| Test Suites | Stage 2 & 3 outputs |
| LLD CI/CD Specifications | LLD 2.5, 2.6, 2.7 |

---

## Stage Outputs

### Worker 1-3: Lambda CI/CD Workflows

Each Lambda repository gets:
```
.github/
└── workflows/
    ├── ci.yml                    # Lint, test on PR
    ├── deploy-dev.yml            # Auto-deploy to DEV
    ├── promote-sit.yml           # Manual promote to SIT
    ├── promote-prod.yml          # Manual promote to PROD
    └── rollback.yml              # Emergency rollback
```

**ci.yml** includes:
- Python linting (flake8, black)
- Unit tests (pytest)
- Coverage report (80% threshold)
- Security scanning (bandit)
- Terraform validate (if applicable)

**deploy-dev.yml** includes:
- Triggered on merge to main
- Build Lambda package
- Deploy to DEV account (536580886816)
- Run smoke tests
- Notify on failure

**promote-sit.yml** includes:
- Manual trigger with approval
- Deploy to SIT account (815856636111)
- Run integration tests
- Require approval before completion

**promote-prod.yml** includes:
- Manual trigger with approval
- Deploy to PROD account (093646564004)
- Run smoke tests
- Read-only verification

### Worker 4: Terraform Pipelines

```
.github/
└── workflows/
    ├── terraform-plan.yml        # Plan on PR
    ├── terraform-apply-dev.yml   # Apply to DEV (auto)
    ├── terraform-apply-sit.yml   # Apply to SIT (manual)
    ├── terraform-apply-prod.yml  # Apply to PROD (manual)
    └── terraform-rollback.yml    # State rollback
```

### Worker 5: GitOps Workflows

For `2_bbws_tenants_instances_dev`:
```
.github/
└── workflows/
    ├── provision-instance.yml    # Triggered by API
    ├── deprovision-instance.yml  # Triggered by API
    ├── update-instance.yml       # Scale, modify
    └── sync-state.yml            # State reconciliation
```

### Worker 6: Test Automation

```
# Shared across all repos
scripts/
├── run-unit-tests.sh
├── run-integration-tests.sh
├── generate-coverage.sh
└── check-coverage-threshold.sh

.github/
└── workflows/
    └── test-report.yml           # Publish test results
```

---

## Success Criteria

- [ ] All Lambda repos have CI/CD workflows
- [ ] All workflows pass validation
- [ ] DEV auto-deployment working
- [ ] SIT/PROD manual promotion with approvals
- [ ] Terraform plan/apply workflows functional
- [ ] GitOps provisioning workflows functional
- [ ] Test automation integrated with coverage thresholds
- [ ] Rollback workflows tested
- [ ] All 6 workers completed
- [ ] Stage summary created

---

## Dependencies

**Depends On**: Stage 3 (Lambda Implementation - Admin Portal)

**Blocks**: Stage 5 (Integration Testing)

---

## Gate 4 Approval

**Approvers**: DevOps Lead, QA Lead

**Criteria**:
- All CI/CD pipelines functional
- DEV deployment successful via pipeline
- Approval gates working correctly
- Test automation integrated
- Coverage thresholds enforced (80%)

---

## Environment Configuration

| Environment | AWS Account | Region | Deployment |
|-------------|-------------|--------|------------|
| DEV | 536580886816 | af-south-1 | Auto on merge |
| SIT | 815856636111 | af-south-1 | Manual with approval |
| PROD | 093646564004 | af-south-1 | Manual with approval |

---

**Created**: 2026-01-24
