# Stage 4: Deployment

**Stage ID**: stage-4-deployment
**Project**: project-plan-4
**Status**: PENDING
**Workers**: 2

---

## Stage Objective

Validate Terraform infrastructure code and deploy the updated WordPress Site Management Lambda to the DEV environment (AWS Account: 536580886816, Region: af-south-1).

---

## Stage Workers

| Worker | Task | Status |
|--------|------|--------|
| worker-1-terraform-validation | Validate Terraform modules and plan | PENDING |
| worker-2-dev-deployment | Deploy to DEV environment | PENDING |

---

## Stage Inputs

| Document | Location |
|----------|----------|
| Stage 3 Test Results | `stage-3-testing/summary.md` |
| Terraform Modules | `terraform/` |
| Environment Variables | `terraform/environments/dev/` |
| GitHub Actions Workflows | `.github/workflows/` |

---

## Stage Outputs

- Terraform validation report
- Terraform plan output
- DEV deployment confirmation
- Lambda function ARN
- API Gateway endpoint URL
- CloudWatch Log Groups

---

## Environment Information

| Environment | AWS Account | Region | Purpose |
|-------------|-------------|--------|---------|
| **DEV** | 536580886816 | af-south-1 | Target for this deployment |
| **SIT** | 815856636111 | af-south-1 | Promotion target (not in this stage) |
| **PROD** | 093646564004 | af-south-1 | Read-only (not in this stage) |

**Important**: All deployments start in DEV. Fix defects in DEV and promote to SIT.

---

## Deployment Standards

### Pre-Deployment Checks
- [ ] All unit tests passing
- [ ] All integration tests passing
- [ ] Code coverage >90%
- [ ] Terraform format validated
- [ ] Terraform plan reviewed
- [ ] No hardcoded credentials

### Terraform Validation
```bash
terraform fmt -check
terraform validate
terraform plan -out=tfplan
```

### Deployment Flow
```
1. terraform init
2. terraform plan -out=tfplan
3. [HUMAN APPROVAL]
4. terraform apply tfplan
5. Verify deployment
```

---

## Success Criteria

- [ ] Terraform fmt passes
- [ ] Terraform validate passes
- [ ] Terraform plan shows expected changes
- [ ] DEV deployment successful
- [ ] All Lambda functions deployed
- [ ] API Gateway endpoints accessible
- [ ] CloudWatch logs configured
- [ ] All 2 workers completed
- [ ] Stage summary created

---

## Dependencies

**Depends On**: Stage 3 (Testing) - All tests must pass

**Blocks**: Stage 5 (Verification) - Need deployed APIs to test

---

## Rollback Procedure

If deployment fails:
1. Review Terraform state
2. Identify failed resources
3. Run `terraform destroy` for failed resources only
4. Fix issues and redeploy
5. Or rollback to previous state

---

**Created**: 2026-01-23
