# Stage 4: CI/CD Pipeline (GitHub Actions)

**Stage ID**: stage-4-cicd-pipeline
**Project**: project-plan-4 (Marketing Lambda Implementation)
**Status**: PENDING
**Workers**: 5 (parallel execution)

---

## Stage Objective

Create comprehensive CI/CD pipelines using GitHub Actions for validation, deployment, promotion, and rollback across 3 environments (DEV, SIT, PROD) with human approval gates.

---

## Stage Workers

| Worker | Task | Status |
|--------|------|--------|
| worker-1-validation-workflows | Create lint, test, security scan workflows | PENDING |
| worker-2-terraform-plan-workflow | Create Terraform plan workflow | PENDING |
| worker-3-deployment-workflows | Create deployment workflows (DEV, SIT, PROD) | PENDING |
| worker-4-promotion-workflows | Create promotion workflows (DEV→SIT, SIT→PROD) | PENDING |
| worker-5-test-workflows | Create integration and E2E test workflows | PENDING |

---

## Stage Inputs

- Stage 3 summary.md
- Terraform modules from Stage 3
- Lambda code from Stage 2
- Environment configurations from worker-3-3

---

## Stage Outputs

- **Validation Workflows**:
  - `.github/workflows/01-validation.yml` (lint, test, security scan)
- **Terraform Workflows**:
  - `.github/workflows/02-terraform-plan.yml` (plan with approval)
- **Deployment Workflows**:
  - `.github/workflows/03-deploy-dev.yml` (auto on merge to main)
  - `.github/workflows/04-deploy-sit.yml` (manual trigger)
  - `.github/workflows/05-deploy-prod.yml` (manual trigger)
- **Promotion Workflows**:
  - `.github/workflows/06-promote-sit.yml` (DEV→SIT with approval)
  - `.github/workflows/07-promote-prod.yml` (SIT→PROD with approval)
- **Test Workflows**:
  - `.github/workflows/08-integration-tests.yml`
  - `.github/workflows/09-e2e-tests.yml`
- **Rollback Workflow**:
  - `.github/workflows/10-rollback.yml`
- Stage 4 summary.md

---

## Success Criteria

- [ ] Validation workflow runs on every commit
- [ ] Terraform plan requires human approval before apply
- [ ] DEV auto-deploys on merge to main
- [ ] SIT and PROD require manual trigger + approval
- [ ] Promotion workflows enforce DEV→SIT→PROD flow
- [ ] Integration tests run after each deployment
- [ ] E2E tests validate end-to-end functionality
- [ ] Rollback workflow can revert to previous version
- [ ] All workflows use environment-specific secrets
- [ ] All workflows use parameterized configurations
- [ ] All 5 workers completed
- [ ] Stage summary created
- [ ] Gate 4 approval obtained

---

## Dependencies

**Depends On**: Stage 3 (Infrastructure - Terraform)

**Blocks**: Stage 5 (Documentation & Runbooks)

---

## Deployment Flow

```
Commit → Validation (lint, test, scan)
  ↓
Terraform Plan → [Approval] → Deploy DEV (auto)
  ↓
Integration Tests → E2E Tests
  ↓
[Manual Trigger + Approval] → Promote to SIT
  ↓
Integration Tests → E2E Tests
  ↓
[Manual Trigger + Approval] → Promote to PROD
  ↓
Integration Tests → E2E Tests
```

---

## GitHub Secrets Required

### DEV Environment
- `AWS_ACCOUNT_ID_DEV`: 536580886816
- `AWS_REGION_DEV`: eu-west-1
- `DYNAMODB_TABLE_DEV`: bbws-cpp-dev
- `AWS_ACCESS_KEY_ID_DEV`
- `AWS_SECRET_ACCESS_KEY_DEV`

### SIT Environment
- `AWS_ACCOUNT_ID_SIT`: 815856636111
- `AWS_REGION_SIT`: eu-west-1
- `DYNAMODB_TABLE_SIT`: bbws-cpp-sit
- `AWS_ACCESS_KEY_ID_SIT`
- `AWS_SECRET_ACCESS_KEY_SIT`

### PROD Environment
- `AWS_ACCOUNT_ID_PROD`: 093646564004
- `AWS_REGION_PROD`: af-south-1
- `DYNAMODB_TABLE_PROD`: bbws-cpp-prod
- `AWS_ACCESS_KEY_ID_PROD`
- `AWS_SECRET_ACCESS_KEY_PROD`

---

## Technical Standards

### Workflow Triggers
- **Validation**: On every push/PR
- **Terraform Plan**: On PR to main
- **Deploy DEV**: On merge to main
- **Deploy SIT/PROD**: Manual workflow_dispatch
- **Promote**: Manual workflow_dispatch with environment input

### Approval Gates
- **Terraform Apply**: Required before any deployment
- **SIT Promotion**: Required before promoting from DEV
- **PROD Promotion**: Required before promoting from SIT

### Rollback Strategy
- **Terraform State**: Revert to previous state version
- **Lambda Version**: Use Lambda versioning and aliases
- **Validation**: Run tests after rollback

---

**Created**: 2025-12-30
