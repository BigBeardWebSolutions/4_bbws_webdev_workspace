# MASTER: Au Pair Hive Migration Implementation Plan
## Xneelo → BBWS Multi-Tenant WordPress Platform

**Project Code**: MIGR-APH-2026-01
**Site**: aupairhive.com
**Migration Date**: TBD (Target: Jan 24, 2026)
**Version**: 1.0
**Created**: 2026-01-09
**Status**: 🟡 READY FOR EXECUTION

---

## Document Control

| Version | Date | Author | Status |
|---------|------|--------|--------|
| 1.0 | 2026-01-09 | Tenant Manager Agent | Ready for Execution |

**Related Documents**:
- PM Migration Plan: `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/training/PM_Migration_Plan_AuPairHive.md`
- Technical Plan: `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/training/aupairhive_migration_plan.md`
- Testing Checklist: `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/training/aupairhive_testing_checklist.md`

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Migration Overview](#migration-overview)
3. [10-Phase Implementation Plan](#10-phase-implementation-plan)
4. [Critical Path](#critical-path)
5. [Dependencies Matrix](#dependencies-matrix)
6. [Resource Requirements](#resource-requirements)
7. [Risk Management](#risk-management)
8. [Communication Plan](#communication-plan)
9. [Quality Gates](#quality-gates)
10. [Success Criteria](#success-criteria)
11. [Sub-Plan Index](#sub-plan-index)

---

## Executive Summary

### Migration Goal
Migrate aupairhive.com from Xneelo shared hosting to BBWS AWS multi-tenant platform with zero data loss and minimal downtime.

### Key Metrics
- **Total Duration**: 21 days (3 weeks)
- **Downtime Window**: <2 hours (DNS cutover only)
- **Environments**: DEV → SIT → PROD
- **Data Volume**: ~500 MB (50 posts, 200 images)
- **Critical Features**: Application forms (Gravity Forms), Blog, GDPR compliance

### Success Criteria
- ✅ All pages load without errors
- ✅ All 3 forms submit successfully
- ✅ Premium licenses activated (Divi, Gravity Forms)
- ✅ Page load time <3 seconds
- ✅ SSL certificate valid
- ✅ Zero data loss verified
- ✅ Downtime <2 hours

---

## Migration Overview

### Current State (Source)
- **Platform**: WordPress 6.4.2 on Xneelo shared hosting
- **Theme**: Divi 4.18.0 (premium)
- **Plugins**: Gravity Forms, Cookie Law Info, reCAPTCHA
- **Domain**: aupairhive.com
- **Hosting**: Xneelo South Africa
- **Traffic**: ~1,000 visitors/month

### Future State (Target)
- **Platform**: BBWS AWS Multi-Tenant WordPress
- **Infrastructure**: ECS Fargate, RDS MySQL, EFS, ALB, Route53, CloudFront
- **Environments**:
  - DEV: aupairhive.wpdev.kimmyai.io (eu-west-1)
  - SIT: aupairhive.wpsit.kimmyai.io (eu-west-1)
  - PROD: aupairhive.wp.kimmyai.io → aupairhive.com (af-south-1)
- **Benefits**: Auto-scaling, high availability, better performance, disaster recovery

### Migration Strategy
**Phased Promotion Approach**: DEV (test) → SIT (UAT) → PROD (go-live)

```
┌──────────┐      ┌──────────┐      ┌──────────┐      ┌──────────┐
│          │      │          │      │          │      │          │
│  Xneelo  │ ───▶ │   DEV    │ ───▶ │   SIT    │ ───▶ │   PROD   │
│          │      │  (Test)  │      │  (UAT)   │      │ (Go-Live)│
│          │      │          │      │          │      │          │
└──────────┘      └──────────┘      └──────────┘      └──────────┘
   Export         Provision &       Promotion &       Promotion &
   Validate       Test (Full)       UAT              DNS Cutover
```

---

## 10-Phase Implementation Plan

### Phase Overview

| # | Phase Name | Duration | Environment | Responsible | Dependencies |
|---|------------|----------|-------------|-------------|--------------|
| 1 | Environment Setup & Validation | 0.5 days | All | DevOps | None |
| 2 | Xneelo Data Export | 1.5 days | Xneelo | Site Owner + Tech | Phase 1 |
| 3 | DEV Environment Provisioning | 0.5 days | DEV | Tech Lead | Phase 2 |
| 4 | Data Import & Configuration (DEV) | 1 day | DEV | Tech Lead | Phase 3 |
| 5 | Testing & Validation (DEV) | 1.5 days | DEV | QA + Tech | Phase 4 |
| 6 | SIT Environment Promotion | 0.5 days | SIT | Tech Lead | Phase 5 |
| 7 | UAT & Performance Testing (SIT) | 1.5 days | SIT | Business Owner + QA | Phase 6 |
| 8 | PROD Deployment Preparation | 1 day | PROD | Tech Lead + DevOps | Phase 7 |
| 9 | DNS Cutover & Go-Live | 0.5 days | PROD | Tech Lead + DevOps | Phase 8 |
| 10 | Post-Migration Monitoring | 7 days | PROD | All | Phase 9 |
| **TOTAL** | **3 weeks** | **21 days** | | | |

### Phase Status Tracking

```
┌─────────────────────────────────────────────────────────────┐
│ MIGRATION PROGRESS                                          │
├─────────────────────────────────────────────────────────────┤
│ Phase 1: Environment Setup           ✅ COMPLETE            │
│ Phase 2: Xneelo Export                ✅ COMPLETE            │
│ Phase 3: DEV Provisioning             ✅ COMPLETE            │
│ Phase 4: Data Import (DEV)            ⏳ NOT STARTED         │
│ Phase 5: Testing (DEV)                ⏳ NOT STARTED         │
│ Phase 6: SIT Promotion                ⏳ NOT STARTED         │
│ Phase 7: UAT (SIT)                    ⏳ NOT STARTED         │
│ Phase 8: PROD Preparation             ⏳ NOT STARTED         │
│ Phase 9: DNS Cutover                  ⏳ NOT STARTED         │
│ Phase 10: Post-Migration              ⏳ NOT STARTED         │
└─────────────────────────────────────────────────────────────┘
```

**Status Legend**:
- ⏳ NOT STARTED
- 🟡 IN PROGRESS
- ✅ COMPLETE
- 🔴 BLOCKED
- 🟠 AT RISK

---

## Critical Path

The critical path (longest chain of dependent tasks) determines the minimum project duration:

```
Phase 2 (Export) → Phase 3 (DEV Provision) → Phase 4 (Import DEV) →
Phase 5 (Test DEV) → Phase 6 (SIT Promotion) → Phase 7 (UAT SIT) →
Phase 8 (PROD Prep) → Phase 9 (DNS Cutover)
```

**Total Critical Path Duration**: 8.5 days
**Total Schedule**: 21 days (includes Phase 1 prep + Phase 10 monitoring + buffer)

**⚠️ Critical Path Management**:
- Any delay on critical path delays entire project
- Monitor critical path tasks daily
- Escalate immediately if >10% delayed
- Focus resources on critical path activities

---

## Dependencies Matrix

### Inter-Phase Dependencies

| Phase | Depends On | Must Complete Before |
|-------|------------|---------------------|
| Phase 1 | None | Phase 2, 3 |
| Phase 2 | Phase 1 | Phase 3, 4 |
| Phase 3 | Phase 1, 2 | Phase 4 |
| Phase 4 | Phase 3 | Phase 5 |
| Phase 5 | Phase 4 | Phase 6 |
| Phase 6 | Phase 5 | Phase 7 |
| Phase 7 | Phase 6 | Phase 8 |
| Phase 8 | Phase 7 | Phase 9 |
| Phase 9 | Phase 8 | Phase 10 |
| Phase 10 | Phase 9 | Project Closure |

### External Dependencies

| Dependency | Owner | Required By | Risk if Unavailable |
|------------|-------|-------------|---------------------|
| Xneelo cPanel access | Business Owner | Phase 2 | Cannot export data |
| Domain registrar access | Business Owner | Phase 9 | Cannot update DNS |
| Divi license key | Business Owner | Phase 4 | Theme won't activate |
| Gravity Forms license | Business Owner | Phase 4 | Forms won't work |
| reCAPTCHA keys | Business Owner | Phase 4 | Spam protection fails |
| Facebook Pixel ID | Business Owner | Phase 4 | Analytics lost |
| AWS account access (3 envs) | DevOps | Phase 1 | Cannot provision |

---

## Resource Requirements

### Team Allocation

| Role | Total Hours | Allocation % | Peak Phase |
|------|-------------|--------------|------------|
| Project Manager | 12 hours | 30% | Phase 5, 7 |
| Technical Lead | 32 hours | 80% | Phase 3-9 |
| DevOps Engineer | 16 hours | 40% | Phase 1, 8, 9 |
| Database Administrator | 8 hours | 20% | Phase 4, 6 |
| WordPress Developer | 12 hours | 30% | Phase 4, 5 |
| QA Engineer | 16 hours | 40% | Phase 5, 7 |
| Business Owner | 4 hours | 10% | Phase 7, 9 |
| **Total** | **100 hours** | | |

### Tools & Access Required

- **AWS CLI**: Configured for all 3 environments (Tebogo-dev, Tebogo-sit, Tebogo-prod)
- **Terraform**: v1.6+ for infrastructure provisioning
- **MySQL Client**: For database operations
- **Git**: Version control for scripts and documentation
- **Scripts**: import_database.sh, upload_wordpress_files.sh (in training/)
- **Testing Tools**: GTmetrix, Lighthouse, Browser DevTools
- **Communication**: Slack, Email

---

## Risk Management

### Top 5 Risks

| ID | Risk | Probability | Impact | Score | Mitigation |
|----|------|-------------|--------|-------|------------|
| R01 | Premium licenses can't transfer | MEDIUM | HIGH | 🟠 8 | Contact vendors pre-migration |
| R03 | Downtime exceeds 2 hours | MEDIUM | HIGH | 🟠 8 | Reduce DNS TTL, rehearse cutover |
| R04 | Gravity Forms data lost | LOW | CRITICAL | 🔴 9 | Separate export, verify counts |
| R05 | DNS propagation delays | MEDIUM | MEDIUM | 🟡 6 | Reduce TTL 48h early |
| R09 | SEO ranking drops | MEDIUM | MEDIUM | 🟡 6 | Submit sitemap, monitor |

**See Full Risk Register**: PM_Migration_Plan_AuPairHive.md Section 7

---

## Communication Plan

### Stakeholder Updates

| Stakeholder | Update Frequency | Method | Content |
|-------------|------------------|--------|---------|
| Project Sponsor | Weekly | Email + Meeting | Overall status, risks, decisions needed |
| Technical Team | Daily | Standup (Slack) | Tasks, blockers, progress |
| Business Owner | Weekly | Email + Calls | Progress, testing needs, approvals |
| End Users | As Needed | Website Banner | Downtime notifications |

### Key Communications

**Pre-Migration (T-7 days)**:
- Email to all users: Migration announcement
- Subject: "Important: aupairhive.com Platform Upgrade Scheduled"

**Pre-Cutover (T-48 hours)**:
- Email with detailed schedule and downtime window
- Subject: "Reminder: Website Maintenance Window [Date] [Time]"

**During Cutover (T-0)**:
- Maintenance mode banner on site
- Message: "We're upgrading our platform for better performance. Back online shortly!"

**Post-Migration (T+0)**:
- Email: Migration complete, report issues
- Subject: "Website Upgrade Complete - Now Even Faster!"

---

## Quality Gates

### Gate Review Process

Each phase requires a **gate review** before proceeding to the next phase:

```
Phase N Complete → Gate Review → Approval → Phase N+1 Start
```

**Gate Review Checklist**:
- [ ] All phase tasks completed
- [ ] All success criteria met
- [ ] All verification items checked
- [ ] No critical blockers
- [ ] Sign-off obtained
- [ ] Go/No-Go decision: **GO**

**Gate Reviewers**:
- **Phases 1-5**: Technical Lead + PM
- **Phases 6-7**: Technical Lead + PM + Business Owner
- **Phases 8-9**: Technical Lead + PM + Business Owner + DevOps

### Quality Standards

| Dimension | Standard | Measurement |
|-----------|----------|-------------|
| Functionality | 100% parity | All features work |
| Performance | Page load <3s | GTmetrix |
| Availability | >99.9% uptime | CloudWatch |
| Security | SSL valid, HTTPS | Manual check |
| Data Integrity | Zero loss | Record count verification |

---

## Success Criteria

### Project-Level Success Criteria

**Must Have (Go/No-Go)**:
- ✅ All pages load without errors (200 OK)
- ✅ All 3 forms submit successfully (family, au pair, contact)
- ✅ Premium licenses activated (Divi, Gravity Forms)
- ✅ SSL certificate valid
- ✅ DNS resolving correctly to production
- ✅ Zero data loss verified (database row counts match)
- ✅ Downtime <2 hours
- ✅ Business owner UAT sign-off

**Should Have**:
- ✅ Page load time <3 seconds (desktop)
- ✅ Monitoring and alerts configured
- ✅ Backup schedule active
- ✅ Documentation complete

**Nice to Have**:
- ⭐ Performance improvement >50%
- ⭐ SEO ranking maintained within 7 days
- ⭐ User satisfaction >80%

### Phase-Level Success Criteria

See individual sub-plans for detailed phase success criteria.

---

## Sub-Plan Index

### Implementation Sub-Plans (10 Total)

All sub-plans are located in: `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/migrations/`

| # | Sub-Plan File | Phase | Duration |
|---|---------------|-------|----------|
| 1 | `01_Environment_Setup_and_Validation.md` | Setup & Validation | 0.5 days |
| 2 | `02_Xneelo_Data_Export.md` | Data Export | 1.5 days |
| 3 | `03_DEV_Environment_Provisioning.md` | DEV Provision | 0.5 days |
| 4 | `04_Data_Import_and_Configuration_DEV.md` | Import DEV | 1 day |
| 5 | `05_Testing_and_Validation_DEV.md` | Test DEV | 1.5 days |
| 6 | `06_SIT_Environment_Promotion.md` | SIT Promotion | 0.5 days |
| 7 | `07_UAT_and_Performance_Testing_SIT.md` | UAT SIT | 1.5 days |
| 8 | `08_PROD_Deployment_Preparation.md` | PROD Prep | 1 day |
| 9 | `09_DNS_Cutover_and_GoLive.md` | Go-Live | 0.5 days |
| 10 | `10_Post_Migration_Monitoring.md` | Monitoring | 7 days |

---

## How to Use This Master Plan

### For Project Manager:
1. Review this master plan with team
2. Assign roles per RACI matrix (PM_Migration_Plan)
3. Track phase status daily
4. Run gate reviews after each phase
5. Escalate blockers immediately
6. Communicate progress weekly

### For Technical Lead:
1. Review each sub-plan before starting phase
2. Execute tasks in order
3. Update phase status as you work
4. Document issues and resolutions
5. Verify success criteria met
6. Sign off before next phase

### For Junior Engineers:
1. Read the sub-plan for your assigned phase
2. Follow step-by-step instructions
3. Ask questions if unclear
4. Update task status in real-time
5. Communicate blockers immediately
6. Learn and document lessons

### For Business Owner:
1. Review overall timeline and downtime window
2. Provide required inputs (licenses, keys)
3. Conduct UAT in Phase 7
4. Approve go-live in Phase 8
5. Report issues during Phase 10

---

## Execution Workflow

### Daily Standup (During Active Phases)
**Time**: 9:00 AM daily
**Duration**: 15 minutes
**Format**:
- Each person: Yesterday, Today, Blockers
- Update phase status
- Identify risks
- Make decisions

### Weekly Status Report
**Due**: Every Friday 5:00 PM
**To**: Project Sponsor, Business Owner
**Content**:
- Phase progress
- Upcoming milestones
- Top 3 risks
- Decisions needed

### Gate Review Meeting
**Trigger**: Phase completion
**Duration**: 30 minutes
**Attendees**: Gate reviewers (see Quality Gates section)
**Outcome**: GO / NO-GO decision

---

## Emergency Contacts

| Role | Name | Contact | Availability |
|------|------|---------|--------------|
| Project Manager | [Name] | [Email/Phone] | Business hours |
| Technical Lead | [Name] | [Email/Phone] | Business hours + on-call |
| DevOps Engineer | [Name] | [Email/Phone] | Business hours |
| Business Owner | [Name] | [Email/Phone] | Flexible |
| Escalation (24/7) | [Name] | [Email/Phone] | 24/7 |

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2026-01-09 | Initial master plan created | Tenant Manager Agent |

---

## Approval Signatures

**Prepared By**:
Name: _______________________
Role: Technical Lead
Date: _______________________
Signature: _______________________

**Reviewed By**:
Name: _______________________
Role: Project Manager
Date: _______________________
Signature: _______________________

**Approved By**:
Name: _______________________
Role: Project Sponsor / Business Owner
Date: _______________________
Signature: _______________________

---

**Ready to Begin?**

Proceed to **Phase 1**: `01_Environment_Setup_and_Validation.md`

**Good luck with the migration!** 🚀
