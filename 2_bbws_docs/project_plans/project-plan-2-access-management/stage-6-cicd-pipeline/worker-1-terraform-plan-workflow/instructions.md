# Worker Instructions: Terraform Plan/Apply Workflows

**Worker ID**: worker-1-terraform-plan-workflow
**Stage**: Stage 6 - CI/CD Pipeline
**Project**: project-plan-2-access-management

---

## Task

Create GitHub Actions workflows for Terraform plan (PR validation) and Terraform apply (infrastructure deployment) across all environments.

---

## Deliverables

Create `output.md` with:

### 1. terraform-plan.yml
- Trigger on Pull Requests to develop, release/*, main
- Run terraform init, validate, plan
- Post plan output as PR comment
- Use appropriate AWS credentials per target branch

### 2. terraform-apply.yml
- Trigger on push to develop (DEV), release/* (SIT), main (PROD)
- Run terraform apply -auto-approve (except PROD)
- PROD requires manual approval via environment protection
- Post apply summary

### 3. Environment Configuration
```yaml
Environment Variables:
  DEV:
    AWS_REGION: eu-west-1
    STATE_BUCKET: bbws-access-dev-terraform-state
  SIT:
    AWS_REGION: eu-west-1
    STATE_BUCKET: bbws-access-sit-terraform-state
  PROD:
    AWS_REGION: af-south-1
    STATE_BUCKET: bbws-access-prod-terraform-state
```

### 4. Secrets Documentation
Required repository secrets for each environment.

### 5. OIDC Configuration (Preferred)
AWS OIDC provider configuration for secure authentication.

---

## Success Criteria

- [ ] terraform-plan.yml validates on PRs
- [ ] terraform-apply.yml deploys on push
- [ ] Environment-specific credentials
- [ ] PROD requires approval
- [ ] Plan posted to PR comments

---

**Status**: PENDING
**Created**: 2026-01-24
