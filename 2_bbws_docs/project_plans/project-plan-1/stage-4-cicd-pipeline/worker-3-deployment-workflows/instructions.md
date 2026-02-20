# Worker 4-3: Deployment Workflows

**Worker ID**: worker-4-3-deployment-workflows
**Stage**: Stage 4 - CI/CD Pipeline Development
**Status**: PENDING
**Estimated Effort**: High
**Dependencies**: Stage 2 Worker 2-6

---

## Objective

Create terraform-apply.yml workflows with manual approval gates for deploying to DEV, SIT, and PROD.

---

## Input Documents

1. **Stage 2 LLD**: CI/CD Pipeline Design (Section 7.3.3, 7.6)
2. **Stage 3**: Environment configurations

---

## Deliverables

Create for both repositories:

### `.github/workflows/terraform-apply.yml`

Must include:
- Trigger: workflow_dispatch with environment input (dev/sit/prod)
- Approval gate using GitHub Environments:
  - DEV: 1 required approver
  - SIT: 2 required approvers
  - PROD: 3 required approvers
- AWS OIDC authentication
- Download terraform plan artifact
- Terraform apply
- Git tag for deployment tracking
- Slack notification (PROD only)
- Post-deployment validation

---

## Quality Criteria

- [ ] Valid YAML syntax
- [ ] Manual trigger (workflow_dispatch)
- [ ] GitHub Environment protection
- [ ] Approval gates (1/2/3 approvers)
- [ ] Deployment tagging
- [ ] Slack notifications (PROD)
- [ ] No hardcoded secrets

---

## Output Format

Write output to `output.md` with 2 workflow files.

**Target Length**: 400-500 lines

---

**Worker Created**: 2025-12-25
**Execution Mode**: Parallel
