# Stage 5: Documentation & Runbooks

**Stage ID**: stage-5-documentation-runbooks
**Project**: project-plan-4 (Marketing Lambda Implementation)
**Status**: PENDING
**Workers**: 4 (parallel execution)

---

## Stage Objective

Create comprehensive operational runbooks for deployment, promotion, troubleshooting, and rollback procedures to support day-to-day operations and incident response.

---

## Stage Workers

| Worker | Task | Status |
|--------|------|--------|
| worker-1-deployment-runbook | Create deployment runbook | PENDING |
| worker-2-promotion-runbook | Create promotion runbook (DEV→SIT→PROD) | PENDING |
| worker-3-troubleshooting-runbook | Create troubleshooting runbook | PENDING |
| worker-4-rollback-runbook | Create rollback runbook | PENDING |

---

## Stage Inputs

- Stage 4 summary.md
- All GitHub Actions workflows from Stage 4
- Terraform modules from Stage 3
- Lambda implementation from Stage 2
- LLD section 10 (Troubleshooting Playbook)

---

## Stage Outputs

- **Runbooks** (in `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/runbooks/marketing_lambda/`):
  - `deployment_runbook.md`
  - `promotion_runbook.md`
  - `troubleshooting_runbook.md`
  - `rollback_runbook.md`
- Stage 5 summary.md

---

## Success Criteria

- [ ] Deployment runbook covers all environments (DEV, SIT, PROD)
- [ ] Promotion runbook documents DEV→SIT→PROD flow with approval steps
- [ ] Troubleshooting runbook addresses common issues from LLD section 10
- [ ] Rollback runbook provides step-by-step recovery procedures
- [ ] All runbooks include:
  - Prerequisites
  - Step-by-step instructions
  - Verification steps
  - Troubleshooting section
  - Rollback procedures (where applicable)
- [ ] All runbooks are actionable and clear
- [ ] All 4 workers completed
- [ ] Stage summary created
- [ ] Gate 5 approval obtained

---

## Dependencies

**Depends On**: Stage 4 (CI/CD Pipeline)

**Blocks**: Project Completion

---

## Runbook Structure

Each runbook must include:

1. **Overview**
   - Purpose
   - When to use this runbook
   - Prerequisites

2. **Step-by-Step Procedures**
   - Numbered steps
   - Commands to execute
   - Expected outputs
   - Screenshots (where helpful)

3. **Verification Steps**
   - How to verify success
   - Health checks
   - Monitoring dashboards

4. **Troubleshooting**
   - Common issues
   - Error messages
   - Resolution steps

5. **Rollback Procedures** (where applicable)
   - When to rollback
   - How to rollback
   - Validation after rollback

6. **References**
   - Related runbooks
   - GitHub workflows
   - Terraform modules
   - CloudWatch dashboards

---

## Deployment Runbook Requirements

Must cover:
- [ ] Pre-deployment checklist
- [ ] DEV deployment (automatic)
- [ ] SIT deployment (manual)
- [ ] PROD deployment (manual)
- [ ] Post-deployment validation
- [ ] Health checks
- [ ] Monitoring setup

---

## Promotion Runbook Requirements

Must cover:
- [ ] Promotion readiness checklist
- [ ] DEV→SIT promotion process
- [ ] SIT→PROD promotion process
- [ ] Approval gate procedures
- [ ] Post-promotion validation
- [ ] Rollback if promotion fails

---

## Troubleshooting Runbook Requirements

Must cover (from LLD section 10):
- [ ] Campaign not found (verify code in DynamoDB)
- [ ] Wrong status (check from_date/to_date values)
- [ ] Lambda timeout
- [ ] DynamoDB throttling
- [ ] API Gateway 5xx errors
- [ ] CloudWatch logs investigation
- [ ] Performance degradation

---

## Rollback Runbook Requirements

Must cover:
- [ ] Rollback decision criteria
- [ ] Terraform state rollback
- [ ] Lambda version rollback
- [ ] API Gateway stage rollback
- [ ] DynamoDB table recovery (if needed)
- [ ] Post-rollback validation
- [ ] Incident reporting

---

**Created**: 2025-12-30
