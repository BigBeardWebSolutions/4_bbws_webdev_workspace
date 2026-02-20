# Worker Instructions: Lambda Deploy Workflows

**Worker ID**: worker-2-lambda-deploy-workflow
**Stage**: Stage 6 - CI/CD Pipeline
**Project**: project-plan-2-access-management

---

## Task

Create GitHub Actions workflows for Lambda function deployment across DEV, SIT, and PROD environments.

---

## Deliverables

Create `output.md` with:

### 1. lambda-deploy-dev.yml
- Trigger: Push to develop branch
- Package all Lambda functions
- Deploy to DEV environment
- Run smoke tests

### 2. lambda-deploy-sit.yml
- Trigger: Push to release/* branches
- Package all Lambda functions
- Deploy to SIT environment
- Run integration tests

### 3. lambda-deploy-prod.yml
- Trigger: Push to main branch
- Require environment protection/approval
- Package all Lambda functions
- Deploy to PROD (af-south-1)
- Run smoke tests
- Notify on completion

### 4. Lambda Packaging Script
- Install dependencies into package
- Create deployment ZIP files
- Support all 41 Lambda functions

### 5. Deployment Strategy
- Update function code
- Publish new version
- Update alias (live, staging)
- Gradual rollout for PROD

---

## Lambda Functions (41)

| Service | Functions |
|---------|-----------|
| Permission | 6 |
| Invitation | 7 |
| Team | 14 |
| Role | 8 |
| Authorizer | 1 |
| Audit | 5 |

---

## Success Criteria

- [ ] DEV deploy on push to develop
- [ ] SIT deploy on push to release/*
- [ ] PROD deploy on push to main (with approval)
- [ ] All 41 functions deployed
- [ ] Smoke tests pass
- [ ] Version aliases updated

---

**Status**: PENDING
**Created**: 2026-01-24
