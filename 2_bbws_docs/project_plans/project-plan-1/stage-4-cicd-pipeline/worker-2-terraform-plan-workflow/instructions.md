# Worker 4-2: Terraform Plan Workflow

**Worker ID**: worker-4-2-terraform-plan-workflow
**Stage**: Stage 4 - CI/CD Pipeline Development
**Status**: PENDING
**Estimated Effort**: Medium
**Dependencies**: Stage 2 Worker 2-6

---

## Objective

Create terraform-plan.yml workflow that generates plans for all environments and posts them as PR comments.

---

## Input Documents

1. **Stage 2 LLD**: CI/CD Pipeline Design (Section 7.3.2)
2. **Stage 3**: Terraform modules and .tfvars files

---

## Deliverables

Create for both repositories:

### `.github/workflows/terraform-plan.yml`

Must include:
- Trigger: pull_request to main
- 3 jobs: plan-dev, plan-sit, plan-prod (run in parallel)
- AWS OIDC authentication (no long-lived credentials)
- Terraform init with backend config
- Terraform validate
- Terraform plan with -var-file
- Upload plan artifact
- Post plan output to PR comment
- Cost estimation (optional, using infracost if available)

---

## Quality Criteria

- [ ] Valid YAML syntax
- [ ] AWS OIDC authentication
- [ ] Runs for all 3 environments
- [ ] Uploads plan artifacts
- [ ] Posts PR comments
- [ ] No hardcoded credentials

---

## Output Format

Write output to `output.md` with 2 workflow files (one per repo).

**Target Length**: 300-400 lines

---

**Worker Created**: 2025-12-25
**Execution Mode**: Parallel
