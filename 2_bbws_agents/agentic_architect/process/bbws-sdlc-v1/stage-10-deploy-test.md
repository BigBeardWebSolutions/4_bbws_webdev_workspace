# Stage 10: Deploy & Test

**Parent Plan**: [BBWS SDLC Main Plan](./main-plan.md)
**Stage**: 10 of 10
**Status**: ⏳ PENDING
**Last Updated**: 2026-01-01

---

## Objective

Execute full deployment to DEV environment, run comprehensive E2E tests, create operational runbooks, and prepare for environment promotion (DEV → SIT → PROD).

---

## Agent & Skill Assignment

| Role | Agent | Skill |
|------|-------|-------|
| **Primary** | DevOps_Engineer_Agent | `github_oidc_cicd.skill.md` |
| **Support** | SDET_Engineer_Agent | `SDET_integration_test.skill.md` |

**Agent Paths**:
- `agentic_architect/DevOps_Engineer_Agent.md`
- `agentic_architect/SDET_Engineer_Agent.md`

---

## Workers

| # | Worker | Task | Status | Output |
|---|--------|------|--------|--------|
| 1 | worker-1-deploy-dev | Deploy to DEV environment | ⏳ PENDING | Deployment logs |
| 2 | worker-2-e2e-validation | Run E2E test suite | ⏳ PENDING | Test report |
| 3 | worker-3-runbooks | Create operational runbooks | ⏳ PENDING | `2_bbws_docs/runbooks/` |

---

## Worker Instructions

### Worker 1: Deploy to DEV

**Objective**: Execute full deployment to DEV environment

**Execution Steps**:

1. **Trigger CI Pipeline**:
```bash
# Push to main branch triggers deploy-dev.yml
git push origin main
```

2. **Monitor Deployment**:
- GitHub Actions: Check workflow execution
- Terraform: Review plan and apply logs
- CloudWatch: Verify Lambda logs

3. **Verify Resources**:
```bash
# Check Lambda functions
aws lambda list-functions --query "Functions[?contains(FunctionName, 'product')]"

# Check API Gateway
aws apigateway get-rest-apis --query "items[?contains(name, 'product')]"

# Check CloudWatch logs
aws logs describe-log-groups --log-group-name-prefix "/aws/lambda/2-1-bbws"
```

**Quality Criteria**:
- [ ] CI pipeline passes
- [ ] Terraform apply successful
- [ ] All Lambda functions deployed
- [ ] API Gateway accessible
- [ ] CloudWatch logs streaming

---

### Worker 2: E2E Validation

**Objective**: Run comprehensive E2E test suite against deployed API

**Skill Reference**: Apply `SDET_integration_test.skill.md`

**Test Execution**:
```bash
# Run all E2E tests against DEV
pytest tests/e2e/ --env=dev -v --tb=short

# Generate test report
pytest tests/e2e/ --env=dev --html=reports/e2e-report.html

# Run with coverage
pytest tests/e2e/ --env=dev --cov=tests/proxies --cov-report=html
```

**Test Scenarios**:
| Test Category | Expected Count | Pass Criteria |
|---------------|----------------|---------------|
| List operations | 8+ | All pass |
| Get operations | 6+ | All pass |
| Create operations | 14+ | All pass |
| Update operations | 10+ | All pass |
| Delete operations | 6+ | All pass |
| Error handling | 5+ | All pass |
| **Total** | **48+** | **100% pass** |

**Validation Checklist**:
- [ ] All CRUD endpoints responding
- [ ] Response formats match specification
- [ ] Error codes correct
- [ ] Performance acceptable (< 3s per request)
- [ ] No data leakage between requests

**Quality Criteria**:
- [ ] All E2E tests pass
- [ ] No flaky tests
- [ ] Test report generated
- [ ] Performance within SLA

---

### Worker 3: Operational Runbooks

**Objective**: Create runbooks for operations team

**Deliverables**:
```
2_bbws_docs/runbooks/{service}/
├── deployment-runbook.md
├── promotion-runbook.md
├── troubleshooting-runbook.md
└── rollback-runbook.md
```

**Deployment Runbook Template**:
```markdown
# {Service} Deployment Runbook

## Overview
- Service: {Service Name}
- Repository: {repo}
- Environments: DEV, SIT, PROD

## Prerequisites
- AWS credentials configured
- GitHub access
- Terraform state access

## Deployment Steps

### DEV (Automatic)
1. Merge PR to main branch
2. CI/CD auto-triggers deploy-dev.yml
3. Monitor GitHub Actions

### SIT (Manual)
1. Navigate to Actions → Deploy to SIT
2. Click "Run workflow"
3. Type "deploy" in confirmation
4. Monitor deployment

### PROD (Manual with Approval)
1. Navigate to Actions → Deploy to PROD
2. Click "Run workflow"
3. Type "deploy-to-production"
4. Provide deployment reason
5. Monitor deployment

## Post-Deployment Verification
1. Run E2E tests: `pytest tests/e2e/ --env={env}`
2. Check CloudWatch logs
3. Verify API responses

## Contacts
- DevOps Lead: [name]
- Tech Lead: [name]
```

**Quality Criteria**:
- [ ] All 4 runbooks created
- [ ] Step-by-step instructions clear
- [ ] Troubleshooting scenarios covered
- [ ] Rollback procedures documented

---

## Stage Outputs

| Output | Description | Location |
|--------|-------------|----------|
| Deployment logs | CI/CD execution logs | GitHub Actions |
| E2E test report | Test results | `reports/e2e-report.html` |
| Deployment runbook | Operations guide | `2_bbws_docs/runbooks/{service}/` |
| Promotion runbook | Environment promotion | `2_bbws_docs/runbooks/{service}/` |
| Troubleshooting runbook | Issue resolution | `2_bbws_docs/runbooks/{service}/` |
| Rollback runbook | Disaster recovery | `2_bbws_docs/runbooks/{service}/` |

---

## Approval Gate 4 (Final)

**Location**: After this stage
**Approvers**: Product Owner, Operations Lead
**Criteria**:
- [ ] DEV deployment successful
- [ ] All E2E tests passing (100%)
- [ ] Runbooks reviewed and approved
- [ ] Ready for SIT promotion
- [ ] No critical issues outstanding

---

## Environment Promotion Path

```
DEV (Auto-deploy) ──► SIT (Manual + Approval) ──► PROD (Strict Approval)
     │                       │                         │
     ▼                       ▼                         ▼
E2E Tests (48+)        E2E Tests (48+)           Smoke Tests Only
All operations         All operations            Read-only operations
```

**Promotion Checklist**:
- [ ] DEV deployment stable (24+ hours)
- [ ] All DEV E2E tests passing
- [ ] No critical bugs
- [ ] Stakeholder approval for SIT
- [ ] SIT deployment successful
- [ ] All SIT E2E tests passing
- [ ] Production approval obtained
- [ ] PROD deployment successful
- [ ] PROD smoke tests passing

---

## Success Criteria

- [ ] All 3 workers completed
- [ ] DEV deployment successful
- [ ] 100% E2E tests passing
- [ ] All runbooks created
- [ ] Gate 4 approval obtained
- [ ] **SDLC COMPLETE**

---

## Dependencies

**Depends On**: Stage 9 (Route53)
**Blocks**: None (final stage)

---

## Estimated Duration

| Activity | Agentic | Manual |
|----------|---------|--------|
| DEV deployment | 10 min | 30 min |
| E2E validation | 15 min | 1 hour |
| Runbooks | 20 min | 2 hours |
| **Total** | **45 min** | **3.5 hours** |

---

## Project Completion

Upon successful completion of this stage:

1. **Mark project as COMPLETE**
2. **Archive plan files**
3. **Update CLAUDE.md** with service reference
4. **Notify stakeholders**
5. **Schedule SIT promotion** (if approved)

---

**Navigation**: [← Stage 9](./stage-9-route53-domain.md) | [Main Plan](./main-plan.md)

---

## SDLC Summary

| Metric | Value |
|--------|-------|
| Total Stages | 10 |
| Total Workers | 35 |
| Agentic Time | ~8 hours |
| Manual Time | ~36 hours |
| Automation Savings | ~78% |
| Approval Gates | 4 |
| Test Coverage | ≥80% |
| E2E Tests | 48+ |

**Congratulations!** The microservice SDLC is now complete. The service is deployed to DEV and ready for environment promotion.
