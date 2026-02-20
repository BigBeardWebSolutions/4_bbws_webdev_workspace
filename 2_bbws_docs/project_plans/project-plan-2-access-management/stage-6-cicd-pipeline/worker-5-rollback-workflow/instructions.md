# Worker Instructions: Rollback Workflows

**Worker ID**: worker-5-rollback-workflow
**Stage**: Stage 6 - CI/CD Pipeline
**Project**: project-plan-2-access-management

---

## Task

Create GitHub Actions workflows for rolling back Lambda functions and Terraform infrastructure in case of deployment failures.

---

## Deliverables

Create `output.md` with:

### 1. rollback-lambda.yml
- Trigger: Manual (workflow_dispatch)
- Inputs:
  - Environment (DEV/SIT/PROD)
  - Target version (or "previous")
  - Services to rollback (all or specific)
- Steps:
  1. Get current version
  2. Get target version
  3. Update Lambda aliases to target version
  4. Run smoke tests
  5. Verify rollback success
  6. Create incident record
  7. Notify team

### 2. rollback-terraform.yml
- Trigger: Manual (workflow_dispatch)
- Inputs:
  - Environment (DEV/SIT/PROD)
  - Target commit SHA
- Steps:
  1. Checkout specific commit
  2. Run terraform plan
  3. Show diff (require review)
  4. Require manual approval
  5. Run terraform apply
  6. Verify infrastructure state
  7. Notify team

### 3. Lambda Version Management
- Version tracking in DynamoDB or S3
- Alias management (live, staging, previous)
- Rollback to any published version

### 4. Terraform State Management
- State file versioning
- State snapshot before apply
- Recovery procedures

### 5. Runbook Integration
- Link to rollback runbook
- Incident documentation
- Post-mortem template

---

## Rollback Scenarios

| Scenario | Action | Recovery Time |
|----------|--------|---------------|
| Lambda bug | Alias rollback | < 5 minutes |
| Config error | Terraform rollback | < 15 minutes |
| Full deployment | Combined rollback | < 30 minutes |

---

## Success Criteria

- [ ] Lambda rollback works for all services
- [ ] Terraform rollback restores state
- [ ] Approval required for PROD
- [ ] Smoke tests verify rollback
- [ ] Audit trail maintained
- [ ] Team notified

---

**Status**: PENDING
**Created**: 2026-01-24
