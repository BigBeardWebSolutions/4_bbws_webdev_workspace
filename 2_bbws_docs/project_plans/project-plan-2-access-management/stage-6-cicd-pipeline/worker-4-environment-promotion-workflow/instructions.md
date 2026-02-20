# Worker Instructions: Environment Promotion Workflows

**Worker ID**: worker-4-environment-promotion-workflow
**Stage**: Stage 6 - CI/CD Pipeline
**Project**: project-plan-2-access-management

---

## Task

Create GitHub Actions workflows for promoting releases from DEV to SIT and from SIT to PROD.

---

## Deliverables

Create `output.md` with:

### 1. promote-to-sit.yml
- Trigger: Manual (workflow_dispatch)
- Input: Version tag (e.g., v1.0.0)
- Steps:
  1. Validate version tag
  2. Create release branch from develop
  3. Run full test suite in DEV
  4. Deploy to SIT
  5. Run integration tests in SIT
  6. Create GitHub release (draft)
  7. Notify team (Slack/Teams)

### 2. promote-to-prod.yml
- Trigger: Manual (workflow_dispatch)
- Input: Version tag, Release notes
- Require: Environment protection (approvers)
- Steps:
  1. Validate version exists in SIT
  2. Require manual approval
  3. Merge release branch to main
  4. Deploy to PROD (af-south-1)
  5. Run smoke tests
  6. Finalize GitHub release
  7. Notify team

### 3. Version Management
- Semantic versioning (MAJOR.MINOR.PATCH)
- Automatic changelog generation
- Git tagging

### 4. Approval Process
- Required reviewers for PROD
- Environment protection rules
- Audit trail

---

## Promotion Flow

```
DEV (develop) → SIT (release/*) → PROD (main)
    ↓               ↓                ↓
 promote-to-sit  validation    promote-to-prod
```

---

## Success Criteria

- [ ] Manual promotion trigger works
- [ ] Version tag validation
- [ ] Release branch creation
- [ ] SIT deployment automated
- [ ] PROD requires approval
- [ ] GitHub releases created
- [ ] Team notifications sent

---

**Status**: PENDING
**Created**: 2026-01-24
