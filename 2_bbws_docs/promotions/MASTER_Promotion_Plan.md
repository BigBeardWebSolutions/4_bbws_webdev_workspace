# MASTER Promotion Plan: DEV → SIT → PROD

**Plan ID**: PROM-2026-Q1-001
**Created**: 2026-01-07
**Project Manager**: Agentic Project Manager
**Status**: 🟡 IN PROGRESS

---

## Executive Summary

| Metric | Value |
|--------|-------|
| **Total Projects** | 7 |
| **Wave 1 (Core APIs)** | 3 projects |
| **Wave 2 (Infrastructure)** | 4 projects |
| **Environments** | DEV → SIT → PROD |
| **Timeline** | Jan 10 - Mar 14, 2026 |
| **Overall Risk** | 🟡 MEDIUM |

---

## Promotion Waves

### Wave 1: Core APIs (Jan 10 - Feb 21, 2026)

| # | Project | DEV Status | SIT Target | PROD Target | Owner |
|---|---------|------------|------------|-------------|-------|
| 1 | campaigns_lambda | ✅ Ready | Jan 10 | Feb 21 | DevOps |
| 2 | order_lambda | ✅ Ready | Jan 10 | Feb 21 | DevOps |
| 3 | product_lambda | ✅ Ready | Jan 10 | Feb 21 | DevOps |

**Prerequisites:**
- [x] All API tests passing (99.43%, 80%+, 80%+)
- [x] Code review complete (Gate 2 PASSED)
- [x] CI/CD workflows validated
- [ ] SIT environment ready
- [ ] Route53 domain configured for SIT

**Dependencies:** None (can proceed immediately)

---

### Wave 2: Infrastructure (Jan 13 - Feb 28, 2026)

| # | Project | DEV Status | SIT Target | PROD Target | Owner |
|---|---------|------------|------------|-------------|-------|
| 4 | dynamodb_schemas | ✅ Ready | Jan 13 | Feb 24 | DevOps |
| 5 | s3_schemas | ✅ Ready | Jan 13 | Feb 24 | DevOps |
| 6 | backend_public | ✅ Ready | Jan 13 | Feb 24 | DevOps |
| 7 | ecs_terraform | ✅ Ready | Jan 13 | Feb 24 | DevOps |

**Prerequisites:**
- [x] Infrastructure validated in DEV
- [x] Terraform state management configured
- [ ] Gate 3 (Infra Review) approval
- [ ] SIT AWS account access verified
- [ ] Backup and rollback procedures documented

**Dependencies:**
- dynamodb_schemas and s3_schemas must be promoted BEFORE backend_public
- Core APIs (Wave 1) should be in SIT for integration testing

---

## Overall Timeline

```
JANUARY 2026
├─ Jan 7  (Today)     📋 Master Plan Created
├─ Jan 8-9            🔧 Pre-promotion checks (all projects)
├─ Jan 10 (Wave 1)    🚀 Deploy Core APIs to SIT
├─ Jan 13 (Wave 2)    🚀 Deploy Infrastructure to SIT
├─ Jan 14-17          ✅ SIT Validation Testing
├─ Jan 20-24          🐛 Fix any issues found in SIT
└─ Jan 27-31          📊 SIT Sign-off & Prepare PROD

FEBRUARY 2026
├─ Feb 3-7            🔒 PROD Readiness Review
├─ Feb 10-14          ✅ Pre-PROD Testing & Validation
├─ Feb 17-21          🚀 PROD Deployment - Wave 1 (Core APIs)
└─ Feb 24-28          🚀 PROD Deployment - Wave 2 (Infrastructure)

MARCH 2026
├─ Mar 3-7            📊 Post-PROD Monitoring
└─ Mar 10-14          ✅ Full Platform Validation & Sign-off
```

---

## Individual Project Plans

| Project | Plan Document | Status |
|---------|--------------|--------|
| campaigns_lambda | [01_campaigns_lambda_promotion.md](./01_campaigns_lambda_promotion.md) | 📋 Ready |
| order_lambda | [02_order_lambda_promotion.md](./02_order_lambda_promotion.md) | 📋 Ready |
| product_lambda | [03_product_lambda_promotion.md](./03_product_lambda_promotion.md) | 📋 Ready |
| dynamodb_schemas | [04_dynamodb_schemas_promotion.md](./04_dynamodb_schemas_promotion.md) | 📋 Ready |
| s3_schemas | [05_s3_schemas_promotion.md](./05_s3_schemas_promotion.md) | 📋 Ready |
| backend_public | [06_backend_public_promotion.md](./06_backend_public_promotion.md) | 📋 Ready |
| ecs_terraform | [07_ecs_terraform_promotion.md](./07_ecs_terraform_promotion.md) | 📋 Ready |

---

## Pre-Promotion Checklist (All Projects)

### Environment Setup
- [ ] SIT AWS Account (815856636111) access verified
- [ ] PROD AWS Account (093646564004) access verified
- [ ] AWS SSO login working for all accounts
- [ ] Terraform workspaces configured (sit, prod)
- [ ] GitHub Actions secrets configured for SIT/PROD
- [ ] Route53 hosted zones verified

### Security & Compliance
- [ ] No hardcoded credentials in any project
- [ ] All secrets in AWS Secrets Manager or GitHub Secrets
- [ ] IAM roles and policies reviewed
- [ ] Security group rules validated
- [ ] VPC configurations verified (if applicable)

### Backup & Rollback
- [ ] Backup procedures documented for each project
- [ ] Rollback procedures tested in DEV
- [ ] DynamoDB point-in-time recovery enabled
- [ ] S3 versioning enabled
- [ ] Lambda deployment aliases configured

### Testing
- [ ] All unit tests passing in DEV
- [ ] Integration tests passing in DEV
- [ ] E2E tests passing in DEV
- [ ] Load testing completed (for APIs)
- [ ] Security scanning completed

### Documentation
- [ ] Deployment runbooks updated
- [ ] Architecture diagrams current
- [ ] API documentation published
- [ ] Monitoring dashboards configured
- [ ] Alert notifications configured

---

## Approval Gates

### Gate 2: Code Review (PASSED ✅)
- **Location:** After Stage 6 (API Proxy)
- **Approvers:** Tech Lead, Developer Lead
- **Criteria:** API tests pass, code reviewed
- **Status:** ✅ PASSED for Wave 1 projects

### Gate 3: Infrastructure Review (IN PROGRESS 🟡)
- **Location:** After Stage 9 (Route53/Domain)
- **Approvers:** DevOps Lead, Tech Lead
- **Criteria:** Infrastructure validated
- **Status:** 🟡 IN PROGRESS for Wave 2 projects
- **Required Before:** SIT promotion of Wave 2

### Gate 4: Production Ready (PENDING ⏳)
- **Location:** After full SIT validation
- **Approvers:** Product Owner, Ops Lead
- **Criteria:** Full stack ready for PROD
- **Status:** ⏳ PENDING (after SIT validation)

---

## Risk Assessment

| Risk | Severity | Project(s) | Mitigation |
|------|----------|------------|------------|
| SIT environment not ready | 🔴 HIGH | All | Verify SIT setup by Jan 8 |
| Route53 domain conflicts | 🟠 MEDIUM | All APIs | Pre-configure domains by Jan 9 |
| DynamoDB table naming conflicts | 🟠 MEDIUM | dynamodb_schemas | Validate naming convention |
| S3 bucket name collisions | 🟠 MEDIUM | s3_schemas | Reserve bucket names early |
| Lambda cold start in SIT | 🟡 LOW | All lambdas | Configure provisioned concurrency |
| IAM permission issues | 🟡 LOW | All | Test permissions before promotion |
| Terraform state lock | 🟡 LOW | All IaC | Use DynamoDB state locking |

---

## Communication Plan

### Daily Standup (During Promotion)
- **Time:** 9:00 AM
- **Duration:** 15 minutes
- **Attendees:** PM, DevOps Lead, Tech Lead
- **Format:**
  - What was deployed yesterday?
  - What's deploying today?
  - Any blockers?

### Status Updates
- **Frequency:** Twice daily (10 AM, 4 PM)
- **Channel:** Slack #deployments
- **Format:** Project name, environment, status, issues

### Incident Escalation
1. **Level 1 (Minor):** DevOps handles, log in tracking sheet
2. **Level 2 (Major):** Escalate to Tech Lead, pause deployments
3. **Level 3 (Critical):** Escalate to Product Owner, execute rollback

---

## Success Criteria

### SIT Promotion Success
- [ ] All 7 projects deployed to SIT without errors
- [ ] All health checks passing in SIT
- [ ] Integration tests passing in SIT
- [ ] No critical or high severity issues
- [ ] Monitoring dashboards showing green metrics
- [ ] SIT sign-off from QA team

### PROD Promotion Success
- [ ] All 7 projects deployed to PROD without errors
- [ ] Zero downtime during deployment
- [ ] All production health checks passing
- [ ] Performance metrics within SLA
- [ ] No customer-impacting issues
- [ ] 24-hour soak period with no incidents
- [ ] Final sign-off from Product Owner

---

## Rollback Procedures

### Immediate Rollback Triggers
- Any production-down scenario
- Data corruption detected
- Security vulnerability exposed
- >5% error rate in logs
- Critical functionality broken

### Rollback Process
1. **Notify:** Alert team via Slack + email
2. **Execute:** Run rollback script (per project plan)
3. **Verify:** Confirm previous version operational
4. **Investigate:** Root cause analysis
5. **Document:** Incident report with lessons learned

---

## Post-Promotion Activities

### Wave 1 (After SIT)
- [ ] Monitor for 24 hours in SIT
- [ ] Run full integration test suite
- [ ] Performance testing against SIT
- [ ] Load testing with production-like traffic
- [ ] Security scanning

### Wave 2 (After SIT)
- [ ] Verify infrastructure stability
- [ ] Database replication validation
- [ ] S3 cross-region sync verification
- [ ] Terraform state consistency check
- [ ] Cost monitoring validation

### After PROD Promotion
- [ ] Monitor for 72 hours post-deployment
- [ ] Daily status reports to stakeholders
- [ ] Weekly retrospective meeting
- [ ] Update runbooks with lessons learned
- [ ] Performance optimization review

---

## Resource Allocation

| Role | Name | Availability | Responsibility |
|------|------|--------------|----------------|
| **Project Manager** | Agentic PM | Full-time | Overall coordination, risk management |
| **DevOps Lead** | TBD | Full-time (Jan 10-Feb 28) | Deployment execution, infrastructure |
| **Tech Lead** | TBD | Part-time (50%) | Technical oversight, approvals |
| **SDET Lead** | TBD | Part-time (50%) | Testing coordination, validation |
| **SRE** | TBD | On-call | Monitoring, incident response |

---

## Dependencies & Blockers

### External Dependencies
- [ ] AWS account access (SIT: 815856636111, PROD: 093646564004)
- [ ] Route53 domain delegation
- [ ] SSL certificates for SIT/PROD domains
- [ ] GitHub repository permissions
- [ ] VPN access for team members

### Current Blockers
- 🔴 **api_infra (40%)**: Must complete before Wave 1 SIT
  - **Impact:** Blocks custom domain routing
  - **Owner:** DevOps Engineer
  - **Due:** Jan 9, 2026
  - **Mitigation:** Prioritize this week

---

## Change Log

| Date | Change | Author |
|------|--------|--------|
| 2026-01-07 | Initial master plan created | Agentic PM |

---

## Next Steps

### Immediate (Jan 7-8)
1. Review and approve this master plan
2. Assign resource owners
3. Complete pre-promotion checklist
4. Verify SIT environment readiness
5. Schedule kick-off meeting

### This Week (Jan 7-10)
1. Execute Wave 1 SIT promotion
2. Monitor and validate in SIT
3. Prepare Wave 2 for Jan 13

### Next Week (Jan 13-17)
1. Execute Wave 2 SIT promotion
2. Full integration testing
3. SIT validation and sign-off

---

**Plan Status:** 📋 READY FOR APPROVAL
**Next Review:** 2026-01-08
**Contact:** Agentic Project Manager
