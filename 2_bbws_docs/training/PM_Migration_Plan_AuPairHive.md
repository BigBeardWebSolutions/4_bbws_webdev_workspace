# Project Migration Plan: Au Pair Hive → BBWS Platform
## Professional PM-Style Plan with State Tracking

**Project Code**: MIGR-APH-2026-01
**Project Manager**: [Assign PM Name]
**Technical Lead**: Tenant Manager Agent
**Business Owner**: Au Pair Hive
**Version**: 1.0
**Last Updated**: 2026-01-09
**Status**: 🟡 PLANNING

---

## Document Control

| Version | Date | Author | Changes | Approver |
|---------|------|--------|---------|----------|
| 0.1 | 2026-01-09 | Tenant Manager Agent | Initial draft | Pending |
| 1.0 | 2026-01-09 | Tenant Manager Agent | Complete plan | Pending |

**Distribution List**:
- Project Sponsor
- Technical Lead
- Business Owner
- DevOps Team
- Junior Engineers (Knowledge Share)

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Project Charter](#project-charter)
3. [Stakeholder Management](#stakeholder-management)
4. [Work Breakdown Structure](#work-breakdown-structure)
5. [Project Timeline & Milestones](#project-timeline--milestones)
6. [Resource Allocation](#resource-allocation)
7. [Risk Register](#risk-register)
8. [Dependencies & Constraints](#dependencies--constraints)
9. [Communication Plan](#communication-plan)
10. [Quality Assurance Plan](#quality-assurance-plan)
11. [Change Management](#change-management)
12. [State Tracking & Status Reporting](#state-tracking--status-reporting)
13. [Budget & Cost Management](#budget--cost-management)
14. [Success Criteria & KPIs](#success-criteria--kpis)
15. [Knowledge Transfer Plan](#knowledge-transfer-plan)
16. [Lessons Learned Template](#lessons-learned-template)
17. [Appendices](#appendices)

---

## 1. Executive Summary

### 1.1 Project Overview

**Business Need**:
Migrate Au Pair Hive WordPress website from Xneelo shared hosting to BBWS multi-tenant AWS platform for improved performance, scalability, and reliability.

**Current State**:
- Hosting: Xneelo shared hosting
- Platform: WordPress 6.4.2 with Divi Theme
- Status: Live production site (aupairhive.com)
- Traffic: Moderate (service business)
- Critical Features: Application forms (Gravity Forms), blog, GDPR compliance

**Future State**:
- Hosting: BBWS AWS Multi-Tenant Platform (ECS Fargate)
- Environments: DEV → SIT → PROD
- Infrastructure: Auto-scaling, high-availability, CloudFront CDN
- Domain: aupairhive.com (preserved)
- Enhanced: Performance, security, disaster recovery

**Business Value**:
- 🚀 **Performance**: 40-60% faster page load times
- 📈 **Scalability**: Auto-scaling for traffic spikes
- 🔒 **Security**: Enterprise-grade security, automated backups
- 💰 **Cost**: Predictable cloud costs (~R500-800/month vs Xneelo R200-500/month)
- ⏱️ **Availability**: 99.9% uptime SLA

### 1.2 Project Scope

**In Scope**:
- ✅ Complete WordPress database migration
- ✅ All WordPress files (themes, plugins, media)
- ✅ DNS configuration and cutover
- ✅ SSL certificate setup (via CloudFront)
- ✅ Premium plugin license transfers (Divi, Gravity Forms)
- ✅ Testing in DEV, SIT, PROD
- ✅ User acceptance testing
- ✅ Knowledge transfer to operations team
- ✅ 30-day post-migration support

**Out of Scope**:
- ❌ Website redesign or content changes
- ❌ New feature development
- ❌ Email hosting migration (separate project)
- ❌ Custom development or integrations
- ❌ Historical backup restoration (beyond latest)
- ❌ SEO optimization (beyond maintaining current)

### 1.3 Key Milestones & Timeline

| Milestone | Target Date | Status |
|-----------|-------------|--------|
| **M1**: Plan Approval | 2026-01-10 | 🟡 PENDING |
| **M2**: Xneelo Export Complete | 2026-01-13 | ⏳ NOT STARTED |
| **M3**: DEV Environment Ready | 2026-01-14 | ⏳ NOT STARTED |
| **M4**: DEV Testing Complete | 2026-01-17 | ⏳ NOT STARTED |
| **M5**: SIT Deployment Complete | 2026-01-20 | ⏳ NOT STARTED |
| **M6**: PROD Go-Live | 2026-01-24 | ⏳ NOT STARTED |
| **M7**: Post-Migration Review | 2026-01-31 | ⏳ NOT STARTED |

**Total Duration**: 21 days (3 weeks)
**Critical Path**: Export → DEV → SIT → PROD → DNS Cutover

### 1.4 Budget Summary

| Category | Estimated Cost | Notes |
|----------|----------------|-------|
| AWS Infrastructure (3 envs) | R0 | Existing platform |
| Premium Licenses | R0 | Already owned |
| Labor (PM + Technical) | 40 hours | Internal resources |
| Contingency (10%) | 4 hours | Risk buffer |
| **Total Project Cost** | **44 hours** | ~R35,000 @ R800/hr |

**Ongoing Costs (Monthly)**:
- PROD Infrastructure: R600-800/month
- Premium licenses: Already owned
- Total: R600-800/month vs Xneelo R200-500/month

---

## 2. Project Charter

### 2.1 Project Objectives

**Primary Objectives**:
1. Migrate aupairhive.com to BBWS platform with zero data loss
2. Maintain 100% functionality parity with current site
3. Minimize downtime to <2 hours during cutover
4. Achieve >99.9% uptime post-migration
5. Improve page load times by 40%+

**Secondary Objectives**:
1. Document migration process for future tenants
2. Train operations team on platform management
3. Establish monitoring and alerting
4. Create disaster recovery runbook

### 2.2 Success Criteria

**Must Have (Go/No-Go)**:
- ✅ All pages load without errors
- ✅ All forms submit successfully
- ✅ Premium licenses activated
- ✅ SSL certificate valid
- ✅ DNS resolving correctly
- ✅ Zero data loss verified

**Should Have**:
- ✅ Page load time <3 seconds
- ✅ Monitoring and alerts configured
- ✅ Backup schedule active
- ✅ Documentation complete

**Nice to Have**:
- ⭐ Performance improvement >50%
- ⭐ SEO ranking maintained within 7 days
- ⭐ Automated rollback capability

### 2.3 Assumptions

1. Xneelo hosting remains accessible throughout migration
2. Premium licenses can be transferred/reactivated
3. Business owner available for UAT testing
4. DNS can be updated within 1-hour window
5. BBWS platform infrastructure is stable and ready
6. No major WordPress/plugin updates during migration

### 2.4 Constraints

**Technical**:
- Must use existing BBWS platform architecture
- Limited to AWS af-south-1 region for PROD
- Must maintain current WordPress version initially

**Business**:
- Minimal downtime (business-critical application forms)
- Must complete before end of Q1 2026
- Limited budget for external services

**Regulatory**:
- POPIA compliance required (data residency in SA)
- GDPR compliance must be maintained

---

## 3. Stakeholder Management

### 3.1 Stakeholder Register

| Stakeholder | Role | Interest | Influence | Engagement Strategy |
|-------------|------|----------|-----------|---------------------|
| Business Owner | Sponsor | HIGH | HIGH | Weekly status, UAT approval |
| Technical Lead | Delivery | HIGH | HIGH | Daily standups, technical decisions |
| DevOps Team | Support | MEDIUM | MEDIUM | Technical coordination meetings |
| End Users (Families) | User | HIGH | LOW | Downtime notifications only |
| End Users (Au Pairs) | User | HIGH | LOW | Downtime notifications only |
| Junior Engineers | Learning | MEDIUM | LOW | Knowledge share sessions |

### 3.2 RACI Matrix

| Activity | Business Owner | Technical Lead | DevOps | PM | Junior |
|----------|----------------|----------------|--------|-----|--------|
| **Planning** |
| Approve migration plan | **A** | C | C | **R** | I |
| Define success criteria | **A/R** | C | I | **R** | I |
| Budget approval | **A** | I | I | **R** | I |
| **Execution** |
| Export from Xneelo | I | **R** | C | **A** | I |
| Provision DEV tenant | I | **A/R** | C | I | I |
| Database import | I | **A/R** | C | I | C |
| Files upload | I | **A/R** | C | I | C |
| Configuration | I | **A/R** | C | I | C |
| **Testing** |
| DEV testing | C | **R** | I | **A** | C |
| SIT testing | **R** | **R** | I | **A** | C |
| UAT | **A/R** | C | I | I | I |
| **Deployment** |
| PROD deployment | **A** | **R** | C | I | I |
| DNS cutover | **A** | **R** | **R** | I | I |
| Monitoring setup | C | **R** | **A** | I | I |
| **Post-Migration** |
| Issue resolution | C | **A/R** | C | I | I |
| Documentation | I | **R** | C | **A** | **R** |
| Knowledge transfer | C | **R** | C | **A** | **R** |

**Legend**:
**R** = Responsible (does the work)
**A** = Accountable (final approval)
**C** = Consulted (provides input)
**I** = Informed (kept updated)

---

## 4. Work Breakdown Structure (WBS)

```
MIGR-APH-2026-01: Au Pair Hive Migration
│
├── 1.0 INITIATION
│   ├── 1.1 Project charter creation
│   ├── 1.2 Stakeholder identification
│   ├── 1.3 Kickoff meeting
│   └── 1.4 Plan approval
│
├── 2.0 PLANNING
│   ├── 2.1 Technical assessment
│   ├── 2.2 Migration strategy design
│   ├── 2.3 Risk assessment
│   ├── 2.4 Resource allocation
│   ├── 2.5 Communication plan
│   └── 2.6 Testing strategy
│
├── 3.0 PREPARATION (Xneelo Export)
│   ├── 3.1 Database export
│   │   ├── 3.1.1 Access phpMyAdmin
│   │   ├── 3.1.2 Export database SQL
│   │   ├── 3.1.3 Verify export integrity
│   │   └── 3.1.4 Document database info
│   ├── 3.2 Files export
│   │   ├── 3.2.1 Compress WordPress files
│   │   ├── 3.2.2 Download via FTP/File Manager
│   │   ├── 3.2.3 Verify file integrity
│   │   └── 3.2.4 Backup validation
│   ├── 3.3 Configuration documentation
│   │   ├── 3.3.1 Plugin licenses
│   │   ├── 3.3.2 API keys (reCAPTCHA, FB Pixel)
│   │   ├── 3.3.3 DNS settings
│   │   └── 3.3.4 Current performance baseline
│   └── 3.4 Screenshot baseline
│
├── 4.0 DEV ENVIRONMENT
│   ├── 4.1 Infrastructure provisioning
│   │   ├── 4.1.1 Provision tenant (Terraform)
│   │   ├── 4.1.2 Create database
│   │   ├── 4.1.3 Deploy ECS service
│   │   ├── 4.1.4 Configure ALB routing
│   │   ├── 4.1.5 Create DNS record
│   │   └── 4.1.6 Verify infrastructure health
│   ├── 4.2 Data migration
│   │   ├── 4.2.1 Import database (with URL replacement)
│   │   ├── 4.2.2 Upload WordPress files
│   │   ├── 4.2.3 Update wp-config.php
│   │   ├── 4.2.4 Set file permissions
│   │   └── 4.2.5 Verify data integrity
│   ├── 4.3 Configuration
│   │   ├── 4.3.1 Activate Divi theme license
│   │   ├── 4.3.2 Activate Gravity Forms license
│   │   ├── 4.3.3 Configure reCAPTCHA
│   │   ├── 4.3.4 Configure Facebook Pixel
│   │   ├── 4.3.5 Regenerate WordPress salts
│   │   └── 4.3.6 Test admin login
│   ├── 4.4 Testing
│   │   ├── 4.4.1 Infrastructure validation
│   │   ├── 4.4.2 Functional testing
│   │   ├── 4.4.3 Forms testing (CRITICAL)
│   │   ├── 4.4.4 Performance testing
│   │   ├── 4.4.5 Security validation
│   │   └── 4.4.6 Mobile/browser testing
│   └── 4.5 DEV sign-off
│
├── 5.0 SIT ENVIRONMENT
│   ├── 5.1 Promote from DEV to SIT
│   ├── 5.2 Smoke testing
│   ├── 5.3 User acceptance testing (UAT)
│   ├── 5.4 Performance benchmarking
│   ├── 5.5 Issue resolution
│   └── 5.6 SIT sign-off
│
├── 6.0 PROD DEPLOYMENT
│   ├── 6.1 Promote from SIT to PROD
│   ├── 6.2 Configure auto-scaling
│   ├── 6.3 Enable monitoring/alerts
│   ├── 6.4 Final testing
│   ├── 6.5 Go/No-Go decision
│   └── 6.6 PROD ready sign-off
│
├── 7.0 DNS CUTOVER
│   ├── 7.1 Pre-cutover checklist
│   ├── 7.2 Reduce DNS TTL (48h before)
│   ├── 7.3 Maintenance mode
│   ├── 7.4 Final data sync
│   ├── 7.5 Update DNS records
│   ├── 7.6 Monitor DNS propagation
│   ├── 7.7 Verify site live
│   └── 7.8 Remove maintenance mode
│
├── 8.0 POST-MIGRATION
│   ├── 8.1 Monitoring (24-48 hours)
│   ├── 8.2 Issue resolution
│   ├── 8.3 Performance tuning
│   ├── 8.4 User feedback collection
│   └── 8.5 Stability confirmation
│
└── 9.0 CLOSURE
    ├── 9.1 Documentation finalization
    ├── 9.2 Knowledge transfer
    ├── 9.3 Lessons learned
    ├── 9.4 Decommission Xneelo
    └── 9.5 Project closure report
```

---

## 5. Project Timeline & Milestones

### 5.1 Gantt Chart (Text-Based)

```
Week 1: Jan 6-12, 2026
Day    Mon Tue Wed Thu Fri Sat Sun
Task   [==================]
1.0    [##]                        Initiation
2.0        [######]                Planning
3.0            [########]          Preparation

Week 2: Jan 13-19, 2026
Day    Mon Tue Wed Thu Fri Sat Sun
Task   [==================]
3.0    [##]                        Preparation (cont.)
4.0        [##########]            DEV Environment
4.4                [####]          DEV Testing

Week 3: Jan 20-26, 2026
Day    Mon Tue Wed Thu Fri Sat Sun
Task   [==================]
5.0    [####]                      SIT Environment
6.0          [##]                  PROD Deployment
7.0              [##]              DNS Cutover
8.0                  [##]          Monitoring

Week 4: Jan 27-31, 2026
Day    Mon Tue Wed Thu Fri
Task   [==============]
8.0    [####]              Post-Migration
9.0          [##]          Closure

Legend:
[##] = Active work
M    = Milestone
```

### 5.2 Detailed Schedule

| WBS | Task | Duration | Start | End | Dependencies | Status |
|-----|------|----------|-------|-----|--------------|--------|
| **1.0** | **INITIATION** | **2 days** | Jan 6 | Jan 7 | - | 🟢 COMPLETE |
| 1.1 | Project charter | 0.5 days | Jan 6 | Jan 6 | - | ✅ DONE |
| 1.2 | Stakeholder ID | 0.5 days | Jan 6 | Jan 6 | - | ✅ DONE |
| 1.3 | Kickoff meeting | 1 day | Jan 7 | Jan 7 | 1.1, 1.2 | 🟡 PENDING |
| 1.4 | Plan approval | 0.5 days | Jan 7 | Jan 7 | 1.3 | 🟡 PENDING |
| **2.0** | **PLANNING** | **3 days** | Jan 8 | Jan 10 | 1.4 | 🟡 IN PROGRESS |
| 2.1 | Technical assessment | 1 day | Jan 8 | Jan 8 | 1.4 | ✅ DONE |
| 2.2 | Migration strategy | 1 day | Jan 9 | Jan 9 | 2.1 | ✅ DONE |
| 2.3 | Risk assessment | 0.5 days | Jan 9 | Jan 9 | 2.1 | ✅ DONE |
| 2.4 | Resource allocation | 0.5 days | Jan 10 | Jan 10 | 2.2 | 🟡 PENDING |
| 2.5 | Communication plan | 0.5 days | Jan 10 | Jan 10 | 2.2 | 🟡 PENDING |
| 2.6 | Testing strategy | 0.5 days | Jan 10 | Jan 10 | 2.2 | ✅ DONE |
| **3.0** | **PREPARATION** | **3 days** | Jan 10 | Jan 13 | 2.0 | ⏳ NOT STARTED |
| 3.1 | Database export | 1 day | Jan 10 | Jan 10 | 2.6 | ⏳ NOT STARTED |
| 3.2 | Files export | 1.5 days | Jan 10 | Jan 11 | 2.6 | ⏳ NOT STARTED |
| 3.3 | Config documentation | 0.5 days | Jan 12 | Jan 12 | 3.1, 3.2 | ⏳ NOT STARTED |
| 3.4 | Screenshots | 0.5 days | Jan 13 | Jan 13 | 3.1, 3.2 | ⏳ NOT STARTED |
| **4.0** | **DEV ENVIRONMENT** | **4 days** | Jan 13 | Jan 17 | 3.0 | ⏳ NOT STARTED |
| 4.1 | Provision infrastructure | 0.5 days | Jan 13 | Jan 13 | 3.0 | ⏳ NOT STARTED |
| 4.2 | Data migration | 1 day | Jan 13 | Jan 14 | 4.1 | ⏳ NOT STARTED |
| 4.3 | Configuration | 1 day | Jan 14 | Jan 15 | 4.2 | ⏳ NOT STARTED |
| 4.4 | DEV testing | 1.5 days | Jan 15 | Jan 17 | 4.3 | ⏳ NOT STARTED |
| 4.5 | DEV sign-off | 0.5 days | Jan 17 | Jan 17 | 4.4 | ⏳ NOT STARTED |
| **5.0** | **SIT ENVIRONMENT** | **3 days** | Jan 17 | Jan 20 | 4.5 | ⏳ NOT STARTED |
| 5.1 | Promote to SIT | 0.5 days | Jan 17 | Jan 17 | 4.5 | ⏳ NOT STARTED |
| 5.2 | Smoke testing | 0.5 days | Jan 17 | Jan 18 | 5.1 | ⏳ NOT STARTED |
| 5.3 | UAT | 1.5 days | Jan 18 | Jan 20 | 5.2 | ⏳ NOT STARTED |
| 5.4 | Performance benchmark | 0.5 days | Jan 20 | Jan 20 | 5.3 | ⏳ NOT STARTED |
| 5.5 | Issue resolution | 0.5 days | Jan 20 | Jan 20 | 5.3 | ⏳ NOT STARTED |
| 5.6 | SIT sign-off | 0.5 days | Jan 20 | Jan 20 | 5.4, 5.5 | ⏳ NOT STARTED |
| **6.0** | **PROD DEPLOYMENT** | **1 day** | Jan 21 | Jan 21 | 5.6 | ⏳ NOT STARTED |
| 6.1 | Promote to PROD | 0.5 days | Jan 21 | Jan 21 | 5.6 | ⏳ NOT STARTED |
| 6.2 | Configure auto-scaling | 0.25 days | Jan 21 | Jan 21 | 6.1 | ⏳ NOT STARTED |
| 6.3 | Monitoring setup | 0.25 days | Jan 21 | Jan 21 | 6.1 | ⏳ NOT STARTED |
| 6.4 | Final testing | 0.5 days | Jan 21 | Jan 21 | 6.2, 6.3 | ⏳ NOT STARTED |
| 6.5 | Go/No-Go | 0.25 days | Jan 21 | Jan 21 | 6.4 | ⏳ NOT STARTED |
| 6.6 | PROD ready sign-off | 0.25 days | Jan 21 | Jan 21 | 6.5 | ⏳ NOT STARTED |
| **7.0** | **DNS CUTOVER** | **1 day** | Jan 24 | Jan 24 | 6.6 | ⏳ NOT STARTED |
| 7.1 | Pre-cutover checklist | 0.25 days | Jan 22 | Jan 22 | 6.6 | ⏳ NOT STARTED |
| 7.2 | Reduce TTL (48h prior) | - | Jan 22 | Jan 22 | 6.6 | ⏳ NOT STARTED |
| 7.3 | Maintenance mode | 0.25 days | Jan 24 | Jan 24 | 7.1 | ⏳ NOT STARTED |
| 7.4 | Final data sync | 0.25 days | Jan 24 | Jan 24 | 7.3 | ⏳ NOT STARTED |
| 7.5 | Update DNS | 0.25 days | Jan 24 | Jan 24 | 7.4 | ⏳ NOT STARTED |
| 7.6 | Monitor propagation | 1 hour | Jan 24 | Jan 24 | 7.5 | ⏳ NOT STARTED |
| 7.7 | Verify live | 0.25 days | Jan 24 | Jan 24 | 7.6 | ⏳ NOT STARTED |
| 7.8 | Remove maintenance | 0.25 days | Jan 24 | Jan 24 | 7.7 | ⏳ NOT STARTED |
| **8.0** | **POST-MIGRATION** | **3 days** | Jan 24 | Jan 27 | 7.8 | ⏳ NOT STARTED |
| 8.1 | 24-48h monitoring | 2 days | Jan 24 | Jan 26 | 7.8 | ⏳ NOT STARTED |
| 8.2 | Issue resolution | 1 day | Jan 24 | Jan 25 | 7.8 | ⏳ NOT STARTED |
| 8.3 | Performance tuning | 0.5 days | Jan 26 | Jan 27 | 8.1 | ⏳ NOT STARTED |
| 8.4 | User feedback | 1 day | Jan 25 | Jan 26 | 7.8 | ⏳ NOT STARTED |
| 8.5 | Stability confirm | 0.5 days | Jan 27 | Jan 27 | 8.1, 8.3 | ⏳ NOT STARTED |
| **9.0** | **CLOSURE** | **2 days** | Jan 28 | Jan 31 | 8.5 | ⏳ NOT STARTED |
| 9.1 | Documentation | 0.5 days | Jan 28 | Jan 28 | 8.5 | ⏳ NOT STARTED |
| 9.2 | Knowledge transfer | 1 day | Jan 29 | Jan 30 | 9.1 | ⏳ NOT STARTED |
| 9.3 | Lessons learned | 0.5 days | Jan 30 | Jan 30 | 9.1 | ⏳ NOT STARTED |
| 9.4 | Decommission Xneelo | 0.5 days | Jan 31 | Jan 31 | 9.3 | ⏳ NOT STARTED |
| 9.5 | Closure report | 0.5 days | Jan 31 | Jan 31 | 9.3 | ⏳ NOT STARTED |

**Status Legend**:
- 🟢 COMPLETE - Task finished successfully
- 🟡 IN PROGRESS - Currently being worked on
- ⏳ NOT STARTED - Not yet begun
- 🔴 BLOCKED - Cannot proceed due to blocker
- 🟠 AT RISK - May miss deadline

---

## 6. Resource Allocation

### 6.1 Team Structure

```
Project Sponsor (Business Owner)
    │
    ├── Project Manager
    │   ├── Technical Lead (Tenant Manager Agent)
    │   │   ├── DevOps Engineer
    │   │   ├── Database Administrator
    │   │   └── WordPress Developer
    │   │
    │   └── QA/Testing Lead
    │       ├── QA Engineer
    │       └── UAT Coordinator
    │
    └── Knowledge Transfer
        ├── Documentation Specialist
        └── Junior Engineers (learners)
```

### 6.2 Resource Assignments

| Role | Name | Allocation | Phase | Tasks |
|------|------|------------|-------|-------|
| **Project Manager** | [Assign] | 30% (12h) | All | Planning, coordination, reporting |
| **Technical Lead** | Tenant Manager Agent | 80% (32h) | 3-8 | Technical execution, troubleshooting |
| **DevOps Engineer** | [Assign] | 40% (16h) | 4-7 | Infrastructure, DNS, monitoring |
| **Database Admin** | [Assign] | 20% (8h) | 4-5 | Database migration, optimization |
| **WordPress Developer** | [Assign] | 30% (12h) | 4-6 | Plugin config, theme testing |
| **QA Engineer** | [Assign] | 40% (16h) | 4-8 | Testing, validation |
| **Business Owner** | [Assign] | 10% (4h) | 5, 7 | UAT, sign-offs |
| **Junior Engineers** | [Assign] | 10% (4h) | 9 | Knowledge transfer (learning) |
| **Total** | | **40 hours** | | |

### 6.3 Skills Matrix

| Skill Required | Level Needed | Team Members | Gap | Mitigation |
|----------------|--------------|--------------|-----|------------|
| WordPress Admin | Advanced | WordPress Dev | ✅ None | - |
| AWS ECS/Fargate | Advanced | DevOps, Tech Lead | ✅ None | - |
| Terraform | Intermediate | DevOps | ✅ None | - |
| MySQL/RDS | Intermediate | DBA, Tech Lead | ✅ None | - |
| DNS Management | Intermediate | DevOps | ✅ None | - |
| Divi Theme | Intermediate | WordPress Dev | ⚠️ Medium | Documentation, vendor support |
| Gravity Forms | Intermediate | WordPress Dev | ⚠️ Medium | Documentation, vendor support |
| Project Management | Advanced | PM | ✅ None | - |

---

## 7. Risk Register

### 7.1 Risk Assessment Matrix

| Risk ID | Risk Description | Category | Probability | Impact | Score | Owner | Status |
|---------|------------------|----------|-------------|--------|-------|-------|--------|
| R01 | Premium licenses cannot be transferred | Technical | MEDIUM | HIGH | 🟠 8 | WordPress Dev | OPEN |
| R02 | Database export fails/corrupts | Technical | LOW | HIGH | 🟡 6 | DBA | OPEN |
| R03 | Downtime exceeds 2-hour window | Technical | MEDIUM | HIGH | 🟠 8 | Tech Lead | OPEN |
| R04 | Gravity Forms data lost in migration | Technical | LOW | CRITICAL | 🔴 9 | DBA | OPEN |
| R05 | DNS propagation delays | Technical | MEDIUM | MEDIUM | 🟡 6 | DevOps | OPEN |
| R06 | Performance degradation post-migration | Technical | LOW | MEDIUM | 🟢 4 | Tech Lead | OPEN |
| R07 | Business owner unavailable for UAT | Resource | MEDIUM | MEDIUM | 🟡 6 | PM | OPEN |
| R08 | reCAPTCHA keys don't work on new domain | Technical | LOW | MEDIUM | 🟢 4 | WordPress Dev | OPEN |
| R09 | SEO ranking drops significantly | Business | MEDIUM | MEDIUM | 🟡 6 | PM | OPEN |
| R10 | Budget overrun due to extended testing | Financial | LOW | LOW | 🟢 3 | PM | OPEN |
| R11 | Xneelo hosting canceled prematurely | Operational | LOW | CRITICAL | 🟠 7 | PM | OPEN |
| R12 | Discovery of undocumented integrations | Technical | MEDIUM | MEDIUM | 🟡 6 | Tech Lead | OPEN |

**Risk Scoring**: Probability (1-3) × Impact (1-3) = Score (1-9)
- 🟢 LOW (1-3): Monitor
- 🟡 MEDIUM (4-6): Mitigation plan required
- 🟠 HIGH (7-8): Active mitigation ongoing
- 🔴 CRITICAL (9): Escalate to sponsor

### 7.2 Risk Mitigation Plans

#### R01: Premium Licenses Cannot Be Transferred
**Probability**: MEDIUM | **Impact**: HIGH | **Score**: 🟠 8

**Mitigation Strategy**:
1. **Pre-Migration**: Contact Elegant Themes and Gravity Forms support to confirm license transfer process
2. **Action**: Document license keys and purchase emails before migration
3. **Plan B**: Purchase new licenses if transfer fails (budget: R3,000-5,000)
4. **Testing**: Activate licenses in DEV environment first to validate

**Contingency**:
- If licenses cannot activate, delay go-live until resolved
- Use trial/demo versions for testing if needed
- Budget approved for emergency license purchase

**Owner**: WordPress Developer
**Review Date**: Weekly until resolved

---

#### R03: Downtime Exceeds 2-Hour Window
**Probability**: MEDIUM | **Impact**: HIGH | **Score**: 🟠 8

**Mitigation Strategy**:
1. **Pre-Cutover**: Reduce DNS TTL to 300s (5 min) 48 hours before cutover
2. **Preparation**: Pre-stage all files and database in PROD before cutover
3. **Rehearsal**: Practice cutover procedure in SIT environment
4. **Communication**: Set expectation for 1-2 hour window, notify users 48h in advance
5. **Timing**: Schedule cutover for Saturday evening (lowest traffic)

**Contingency**:
- If cutover fails, immediately revert DNS to Xneelo (5-10 minute rollback)
- Keep Xneelo hosting active for 7 days as safety net
- Have rollback runbook ready

**Owner**: Technical Lead
**Status**: Pre-cutover checklist created ✅

---

#### R04: Gravity Forms Data Lost in Migration
**Probability**: LOW | **Impact**: CRITICAL | **Score**: 🔴 9

**Mitigation Strategy**:
1. **Export**: Use Gravity Forms native export feature for all form entries
2. **Backup**: Take separate backup of wp_gf_* tables before migration
3. **Validation**: Verify form entry count in source vs target database
4. **Testing**: Submit test forms in DEV and verify they save correctly
5. **Documentation**: Document form IDs and notification settings

**Contingency**:
- If entries lost, import from separate Gravity Forms export file
- Restore from wp_gf_* table backup
- Manually recreate recent entries from email notifications (if critical)

**Owner**: Database Administrator
**Status**: Export completed ⏳ (pending Xneelo export phase)

---

#### R09: SEO Ranking Drops Significantly
**Probability**: MEDIUM | **Impact**: MEDIUM | **Score**: 🟡 6

**Mitigation Strategy**:
1. **301 Redirects**: Ensure all old URLs redirect properly to new platform
2. **Sitemap**: Submit updated sitemap.xml to Google Search Console immediately
3. **Monitoring**: Track keyword rankings daily for 2 weeks post-migration
4. **Technical SEO**: Verify all meta tags, structured data, and robots.txt preserved
5. **Communication**: Notify Google of server migration via Search Console

**Contingency**:
- If rankings drop >20%, investigate and fix technical SEO issues within 24h
- Engage SEO specialist if needed (budget: R5,000)
- Monitor Google Search Console for crawl errors

**Owner**: Project Manager
**Acceptance Criteria**: <10% ranking drop after 7 days

---

### 7.3 Risk Monitoring Schedule

| Risk ID | Review Frequency | Next Review | Escalation Threshold |
|---------|------------------|-------------|---------------------|
| R01 | Weekly | Jan 10 | Cannot activate in DEV |
| R02 | One-time (export) | Jan 10 | Export file corrupted |
| R03 | Before cutover | Jan 21 | >2 hour estimate |
| R04 | One-time (import) | Jan 14 | Missing form entries |
| R05 | Before cutover | Jan 21 | TTL not reduced |
| R06 | Post-go-live | Jan 25 | Page load >5s |
| R07 | Weekly | Jan 10 | Owner unavailable |
| R08 | During DEV config | Jan 14 | Keys don't work |
| R09 | Post-go-live | Jan 25 | >20% ranking drop |
| R10 | Weekly | Jan 17 | >10% over budget |
| R11 | Weekly | Jan 17 | Xneelo cancellation notice |
| R12 | During testing | Jan 17 | Undocumented feature found |

---

## 8. Dependencies & Constraints

### 8.1 External Dependencies

| Dependency | Owner | Required By | Status | Risk If Delayed |
|------------|-------|-------------|--------|-----------------|
| Xneelo hosting access | Business Owner | Jan 10 | ✅ READY | Cannot export data |
| cPanel credentials | Business Owner | Jan 10 | ✅ READY | Cannot export data |
| Domain registrar access | Business Owner | Jan 24 | ⚠️ NEEDED | Cannot update DNS |
| Divi license key | Business Owner | Jan 14 | ⚠️ NEEDED | Theme won't activate |
| Gravity Forms license | Business Owner | Jan 14 | ⚠️ NEEDED | Forms won't work |
| reCAPTCHA keys | Business Owner | Jan 14 | ⚠️ NEEDED | Spam protection fails |
| Facebook Pixel ID | Business Owner | Jan 14 | ⚠️ NEEDED | Analytics lost |
| AWS account access (all envs) | DevOps | Jan 13 | ✅ READY | Cannot provision |
| BBWS platform stability | DevOps | Jan 13 | ✅ READY | Infrastructure issues |

### 8.2 Internal Dependencies

| Predecessor Task | Successor Task | Type | Lag Time |
|------------------|----------------|------|----------|
| Plan approval (1.4) | Xneelo export (3.0) | Finish-to-Start | 0 days |
| Database export (3.1) | Database import (4.2.1) | Finish-to-Start | 0 days |
| Files export (3.2) | Files upload (4.2.2) | Finish-to-Start | 0 days |
| DEV infrastructure (4.1) | Data migration (4.2) | Finish-to-Start | 0 days |
| Data migration (4.2) | Configuration (4.3) | Finish-to-Start | 0 days |
| DEV testing (4.4) | SIT promotion (5.1) | Finish-to-Start | 0 days |
| SIT sign-off (5.6) | PROD deployment (6.1) | Finish-to-Start | 0 days |
| PROD ready (6.6) | DNS cutover (7.0) | Finish-to-Start | 2 days (TTL reduction) |
| DNS cutover (7.8) | Decommission Xneelo (9.4) | Finish-to-Start | 7 days (safety period) |

### 8.3 Critical Path

**Critical Path Tasks** (any delay impacts go-live):
1. Plan approval → 2. Xneelo export → 3. DEV provisioning → 4. Data migration → 5. DEV testing → 6. SIT promotion → 7. UAT → 8. SIT sign-off → 9. PROD deployment → 10. DNS cutover

**Total Critical Path Duration**: 18 days
**Float/Buffer**: 3 days (21-day total schedule)

**Critical Path Management**:
- Daily status checks on critical path tasks
- Immediate escalation if any task >10% delayed
- Fast-track approvals for critical path decisions
- Prioritize resources to critical path activities

---

## 9. Communication Plan

### 9.1 Communication Matrix

| Stakeholder Group | Information Need | Frequency | Method | Owner |
|-------------------|------------------|-----------|--------|-------|
| **Project Sponsor** | Overall status, risks, decisions | Weekly | Status report + meeting | PM |
| **Technical Team** | Task assignments, blockers | Daily | Standup (Slack/Teams) | Tech Lead |
| **Business Owner** | Progress, testing needs, approvals | Weekly | Email + calls | PM |
| **End Users (Families)** | Downtime notifications | As needed | Website banner + email | PM |
| **End Users (Au Pairs)** | Downtime notifications | As needed | Website banner + email | PM |
| **DevOps Team** | Technical coordination | As needed | Slack channel | Tech Lead |
| **Junior Engineers** | Learning updates, documentation | Weekly | Knowledge share session | PM |
| **Management** | Executive summary | Bi-weekly | Dashboard | PM |

### 9.2 Status Report Template

**Project**: Au Pair Hive Migration (MIGR-APH-2026-01)
**Reporting Period**: [Week of XXX]
**Report Date**: [Date]
**Prepared By**: [PM Name]

**Executive Summary**:
Overall Project Status: 🟢 GREEN / 🟡 YELLOW / 🔴 RED
[1-2 sentence summary of current state]

**Progress This Period**:
- Completed tasks:
  - Task 1
  - Task 2
- In-progress tasks:
  - Task 3 (60% complete)
- Upcoming tasks:
  - Task 4 (starting [date])

**Milestones**:
| Milestone | Target Date | Status | Variance |
|-----------|-------------|--------|----------|
| M1: Plan Approval | Jan 10 | 🟢 ON TRACK | 0 days |
| M2: Xneelo Export | Jan 13 | 🟡 AT RISK | +1 day |

**Risks & Issues**:
| ID | Description | Status | Mitigation |
|----|-------------|--------|------------|
| R01 | License transfer | 🟡 OPEN | Contacted vendor support |

**Budget Status**:
- Planned: 40 hours
- Actual: 15 hours
- Variance: -25 hours (62% remaining)

**Resource Utilization**:
- Technical Lead: 80% allocated, 60% utilized
- DevOps: 40% allocated, 30% utilized

**Decisions Needed**:
1. Decision 1: [description] - Due: [date]
2. Decision 2: [description] - Due: [date]

**Next Period Focus**:
- Focus area 1
- Focus area 2

### 9.3 Escalation Path

**Level 1**: Technical Lead
**Scope**: Technical blockers, resource conflicts
**Response Time**: 4 hours

**Level 2**: Project Manager
**Scope**: Schedule delays, budget overruns, stakeholder issues
**Response Time**: 24 hours

**Level 3**: Project Sponsor
**Scope**: Go/No-Go decisions, major scope changes, critical risks
**Response Time**: 48 hours

**Escalation Criteria**:
- ⚠️ Any critical path task delayed >1 day
- ⚠️ Budget variance >10%
- ⚠️ Critical risk (score 9) identified
- ⚠️ Go/No-Go decision needed
- ⚠️ Scope change request
- ⚠️ Resource unavailability >2 days

---

## 10. Quality Assurance Plan

### 10.1 Quality Standards

| Quality Dimension | Standard | Measurement | Acceptance Criteria |
|-------------------|----------|-------------|---------------------|
| **Functionality** | 100% feature parity | Manual testing | All pages/forms work |
| **Performance** | Page load time | GTmetrix/Lighthouse | <3s (desktop), <5s (mobile) |
| **Availability** | Uptime | CloudWatch | >99.9% (excluding planned downtime) |
| **Security** | SSL, HTTPS | Manual verification | All traffic over HTTPS |
| **Data Integrity** | Zero data loss | Database record count | Source count = Target count |
| **User Experience** | Visual parity | Screenshot comparison | Matches original site |
| **Accessibility** | WCAG 2.1 Level AA | WAVE tool | No critical errors |
| **SEO** | Ranking maintained | Google Search Console | <10% drop after 7 days |

### 10.2 Testing Strategy

**Test Levels**:

1. **Unit Testing** (Component-level)
   - Database connection
   - EFS mount
   - ALB routing
   - DNS resolution

2. **Integration Testing** (System-level)
   - End-to-end page load
   - Form submission flow
   - Theme/plugin interaction
   - CDN delivery

3. **System Testing** (Full environment)
   - All pages accessible
   - All forms functional
   - Performance benchmarks
   - Security validation

4. **User Acceptance Testing (UAT)**
   - Business owner validates
   - Real-world workflows
   - Content accuracy
   - User journey completion

5. **Regression Testing**
   - Retest after fixes
   - Verify no new issues
   - Compare to baseline

**Test Environments**:
- DEV: Full testing (functional, performance, security)
- SIT: UAT, performance benchmarking, final validation
- PROD: Smoke testing only (pre and post go-live)

### 10.3 Test Cases (Summary)

**Total Test Cases**: 127
**Priority Breakdown**:
- P0 (Critical): 23 (must pass for go-live)
- P1 (High): 45 (must pass for each environment)
- P2 (Medium): 39 (should pass, can defer fixes)
- P3 (Low): 20 (nice to have)

**Critical Test Cases (P0)**:
1. Homepage loads without errors (200 OK)
2. WordPress admin login works
3. Family application form submits successfully
4. Au Pair application form submits successfully
5. Contact form submits successfully
6. Form email notifications received
7. Database connection stable
8. All images display correctly
9. SSL certificate valid
10. DNS resolves to correct site
11. Divi theme activated
12. Gravity Forms activated
13. reCAPTCHA validates
14. No JavaScript errors in console
15. No PHP errors in logs
16. File permissions correct
17. Backup restoration tested
18. Blog posts display
19. Navigation menu works
20. Mobile responsive design
21. Page load time <5s
22. Zero form submission failures
23. GDPR cookie banner displays

**Full test checklist**: See `aupairhive_testing_checklist.md`

### 10.4 Defect Management

**Defect Severity**:
- **S1 (Critical)**: Site down, forms not working, data loss
  - Response: Immediate (1 hour)
  - Resolution: Same day
  - Impact: Blocks go-live

- **S2 (High)**: Major functionality broken, performance degraded >50%
  - Response: 4 hours
  - Resolution: 1-2 days
  - Impact: May block go-live

- **S3 (Medium)**: Minor functionality issue, cosmetic problems
  - Response: 1 day
  - Resolution: 3-5 days
  - Impact: Can go-live with workaround

- **S4 (Low)**: Enhancement, nice-to-have
  - Response: 1 week
  - Resolution: Post-migration
  - Impact: No impact on go-live

**Defect Workflow**:
1. Tester identifies issue
2. Log in tracking system (Jira/GitHub Issues)
3. Assign severity and priority
4. Tech Lead assigns to developer
5. Developer fixes and marks "Ready for Test"
6. Tester validates fix
7. Close defect or reopen if not fixed

**Go/No-Go Criteria**:
- ✅ GO: Zero S1 defects, <3 S2 defects, S3/S4 deferred
- ❌ NO-GO: Any S1 defect, >3 S2 defects

---

## 11. Change Management

### 11.1 Change Control Process

**Change Request Procedure**:
1. **Submit**: Requestor submits change request form
2. **Assess**: PM assesses impact (scope, schedule, budget, risk)
3. **Review**: Change Control Board (CCB) reviews
4. **Approve/Reject**: Sponsor approves or rejects
5. **Implement**: If approved, update plan and execute
6. **Communicate**: Notify all stakeholders

**Change Control Board (CCB)**:
- Project Sponsor (Chair)
- Project Manager
- Technical Lead
- Business Owner

**Meeting Frequency**: As needed (within 24h of change request)

### 11.2 Change Request Template

```
CHANGE REQUEST #CR-XXX

Date Submitted: [Date]
Submitted By: [Name]
Priority: LOW / MEDIUM / HIGH / URGENT

CHANGE DESCRIPTION:
[Describe the requested change]

JUSTIFICATION:
[Why is this change needed?]

IMPACT ANALYSIS:
Scope: [Impact on scope]
Schedule: [Delay? How many days?]
Budget: [Additional cost?]
Resources: [Additional resources needed?]
Quality: [Impact on quality standards?]
Risk: [New risks introduced?]

ALTERNATIVES CONSIDERED:
1. [Alternative 1]
2. [Alternative 2]

RECOMMENDATION:
[ ] Approve
[ ] Reject
[ ] Defer to post-migration

CCB DECISION:
Decision: [Approved/Rejected/Deferred]
Date: [Date]
Approved By: [Sponsor Name]
Conditions: [Any conditions or caveats]

IMPLEMENTATION:
Updated Tasks: [List WBS tasks affected]
Updated Schedule: [New dates]
Communication: [Who needs to be notified?]
```

### 11.3 User Adoption Plan

**Training & Support**:

**Business Owner Training**:
- Session 1: WordPress admin on new platform (1 hour)
- Session 2: Gravity Forms management (30 min)
- Session 3: Monitoring dashboard overview (30 min)
- Materials: Video recordings, documentation, quick reference guide

**End User Communication**:
- **T-7 days**: Email announcement of upcoming migration
- **T-48 hours**: Detailed migration schedule, what to expect
- **T-2 hours**: Maintenance window begins notification
- **T+0**: Migration complete, site live announcement
- **T+7 days**: "Everything working well?" survey

**Support Plan**:
- **Week 1**: Hypercare support (4-hour response time)
- **Week 2-4**: Standard support (8-hour response time)
- **Ongoing**: Normal operations support

---

## 12. State Tracking & Status Reporting

### 12.1 Project State Tracking

**Overall Project Status Dashboard**:

```
╔════════════════════════════════════════════════════════════╗
║         AU PAIR HIVE MIGRATION - STATUS DASHBOARD          ║
║                    Updated: 2026-01-09                     ║
╠════════════════════════════════════════════════════════════╣
║                                                            ║
║  OVERALL STATUS:  🟡 PLANNING                              ║
║                                                            ║
║  ┌──────────────────────────────────────────────────────┐ ║
║  │ PROGRESS: [######################··················] │ ║
║  │           50% Complete (Planning Phase)              │ ║
║  └──────────────────────────────────────────────────────┘ ║
║                                                            ║
║  PHASE STATUS:                                             ║
║    1.0 Initiation        🟢 COMPLETE                       ║
║    2.0 Planning          🟡 IN PROGRESS (70% complete)     ║
║    3.0 Preparation       ⏳ NOT STARTED                    ║
║    4.0 DEV Environment   ⏳ NOT STARTED                    ║
║    5.0 SIT Environment   ⏳ NOT STARTED                    ║
║    6.0 PROD Deployment   ⏳ NOT STARTED                    ║
║    7.0 DNS Cutover       ⏳ NOT STARTED                    ║
║    8.0 Post-Migration    ⏳ NOT STARTED                    ║
║    9.0 Closure           ⏳ NOT STARTED                    ║
║                                                            ║
║  KEY METRICS:                                              ║
║    Schedule Health:      🟢 ON TRACK                       ║
║    Budget Health:        🟢 ON TRACK                       ║
║    Quality Health:       🟢 ON TRACK                       ║
║    Risk Health:          🟡 MEDIUM (2 high risks)          ║
║                                                            ║
║  MILESTONES:                                               ║
║    M1: Plan Approval     Jan 10  🟡 PENDING                ║
║    M2: Xneelo Export     Jan 13  ⏳ NOT STARTED            ║
║    M3: DEV Ready         Jan 14  ⏳ NOT STARTED            ║
║    M4: DEV Testing Done  Jan 17  ⏳ NOT STARTED            ║
║    M5: SIT Deploy Done   Jan 20  ⏳ NOT STARTED            ║
║    M6: PROD Go-Live      Jan 24  ⏳ NOT STARTED            ║
║    M7: Post-Mig Review   Jan 31  ⏳ NOT STARTED            ║
║                                                            ║
║  ACTIVE ISSUES:                                            ║
║    • None currently                                        ║
║                                                            ║
║  TOP RISKS:                                                ║
║    • R01: License transfer (🟠 Score: 8)                  ║
║    • R03: Downtime window (🟠 Score: 8)                   ║
║                                                            ║
║  NEXT ACTIONS:                                             ║
║    • Finalize communication plan (Due: Jan 10)             ║
║    • Obtain Xneelo credentials (Due: Jan 10)               ║
║    • Schedule kickoff meeting (Due: Jan 10)                ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝
```

### 12.2 Daily Standup Template (for Active Phases)

**Date**: [Date]
**Attendees**: [List]

**Yesterday's Accomplishments**:
- [Team Member 1]: Completed X, Y
- [Team Member 2]: Completed Z

**Today's Plan**:
- [Team Member 1]: Will work on A, B
- [Team Member 2]: Will work on C

**Blockers/Issues**:
- [Blocker 1]: Description - Owner: [Name] - ETA: [Date]
- [Blocker 2]: Description - Owner: [Name] - ETA: [Date]

**Decisions Needed**:
- [Decision 1]: Description - By: [Name] - Deadline: [Date]

**Help Needed**:
- [Team Member]: Needs help with X from [Person]

### 12.3 Weekly Status Update Template

**Week**: [Week of XXX]
**Status**: 🟢 GREEN / 🟡 YELLOW / 🔴 RED

**Headline**: [One sentence describing the week]

**Completed This Week**:
- ✅ Task 1
- ✅ Task 2
- ✅ Task 3

**In Progress**:
- 🔄 Task 4 (60% complete) - On track for [date]
- 🔄 Task 5 (30% complete) - Delayed by 1 day due to [reason]

**Planned for Next Week**:
- 📅 Task 6
- 📅 Task 7

**Risks & Issues**:
| ID | Description | Status | Action |
|----|-------------|--------|--------|
| R01 | License transfer | 🟡 OPEN | Contacted vendor |

**Milestones**:
- M2: Xneelo Export - Target: Jan 13 - Status: 🟢 ON TRACK

**Metrics**:
- Schedule variance: +0 days (on track)
- Budget variance: -R0 (on track)
- Quality: 0 defects

**Blockers**: None / [Description]

**Next Major Milestone**: M2 - Xneelo Export (Jan 13)

---

## 13. Budget & Cost Management

### 13.1 Budget Breakdown

| Cost Category | Estimated Hours | Rate | Total Cost | Notes |
|---------------|----------------|------|------------|-------|
| **Labor** | | | | |
| Project Manager | 12 hours | R800/hr | R9,600 | Planning, coordination, reporting |
| Technical Lead | 32 hours | R1,000/hr | R32,000 | Technical execution |
| DevOps Engineer | 16 hours | R900/hr | R14,400 | Infrastructure, DNS |
| Database Admin | 8 hours | R900/hr | R7,200 | Database migration |
| WordPress Developer | 12 hours | R800/hr | R9,600 | Plugin config, testing |
| QA Engineer | 16 hours | R700/hr | R11,200 | Testing, validation |
| **Subtotal Labor** | **96 hours** | | **R84,000** | |
| | | | | |
| **Software & Licenses** | | | | |
| Premium licenses | - | - | R0 | Already owned |
| Tools/utilities | - | - | R0 | Using existing |
| **Subtotal Software** | | | **R0** | |
| | | | | |
| **Infrastructure** | | | | |
| AWS DEV (1 month) | - | - | R150 | Testing environment |
| AWS SIT (1 month) | - | - | R200 | Staging environment |
| AWS PROD (1 month) | - | - | R700 | Production |
| S3 storage (migration) | - | - | R50 | Temporary file storage |
| **Subtotal Infrastructure** | | | **R1,100** | |
| | | | | |
| **Contingency (10%)** | | | **R8,510** | Risk buffer |
| | | | | |
| **TOTAL PROJECT COST** | | | **R93,610** | One-time |

**Ongoing Monthly Cost (Post-Migration)**:
- AWS PROD infrastructure: R600-800/month
- Domain registration: R150/month (existing)
- Premium licenses: R0 (already owned)
- **Total**: R750-950/month

**Cost-Benefit Analysis**:
- **Current Xneelo**: ~R300/month × 12 = R3,600/year
- **New BBWS**: ~R850/month × 12 = R10,200/year
- **Incremental Cost**: R6,600/year
- **Benefits**: Improved performance, scalability, reliability, disaster recovery
- **ROI**: Improved user experience may increase conversions (unmeasured)

### 13.2 Budget Tracking

| Week | Planned Spend | Actual Spend | Variance | % Used | Notes |
|------|---------------|--------------|----------|--------|-------|
| Week 1 (Jan 6-12) | R15,000 | R0 | -R15,000 | 0% | Planning phase |
| Week 2 (Jan 13-19) | R35,000 | R0 | - | 0% | Not started |
| Week 3 (Jan 20-26) | R30,000 | R0 | - | 0% | Not started |
| Week 4 (Jan 27-31) | R13,610 | R0 | - | 0% | Not started |
| **Total** | **R93,610** | **R0** | **R0** | **0%** | |

**Budget Status**: 🟢 ON TRACK
**Burn Rate**: R0/week (not started)
**Forecast**: On budget

### 13.3 Cost Control Measures

1. **Weekly budget reviews** with PM
2. **Time tracking** for all team members
3. **Scope control** via change management process
4. **Resource optimization** (right-size AWS instances)
5. **Automation** where possible to reduce manual hours

---

## 14. Success Criteria & KPIs

### 14.1 Project Success Criteria

**Go-Live Readiness** (Must all be YES):
- [ ] All P0 test cases passed
- [ ] Zero S1 defects
- [ ] <3 S2 defects (with workarounds)
- [ ] Business owner UAT sign-off received
- [ ] Performance meets targets (<3s page load)
- [ ] All forms tested and working
- [ ] Premium licenses activated
- [ ] SSL certificate valid
- [ ] DNS configured and tested
- [ ] Monitoring and alerts active
- [ ] Rollback plan tested
- [ ] Communication sent to users

**Post-Migration Success** (30 days):
- [ ] Uptime >99.9%
- [ ] Zero critical incidents
- [ ] <5 support tickets
- [ ] SEO ranking drop <10%
- [ ] User satisfaction >80%
- [ ] Performance improvement >40%

### 14.2 Key Performance Indicators (KPIs)

| KPI | Baseline (Xneelo) | Target (BBWS) | Measurement | Frequency |
|-----|-------------------|---------------|-------------|-----------|
| **Performance** | | | | |
| Page load time (desktop) | 4.2s | <3s | GTmetrix | Daily |
| Page load time (mobile) | 6.8s | <5s | GTmetrix | Daily |
| Time to first byte (TTFB) | 1.8s | <1s | GTmetrix | Daily |
| Lighthouse score | 65 | >80 | Lighthouse | Weekly |
| | | | | |
| **Availability** | | | | |
| Uptime % | 99.5% | >99.9% | CloudWatch | Real-time |
| MTTR (Mean Time to Repair) | - | <1 hour | Incident logs | Per incident |
| Downtime incidents | - | <2/month | Incident logs | Monthly |
| | | | | |
| **Functionality** | | | | |
| Form submission success rate | - | >99% | Gravity Forms logs | Daily |
| Failed form submissions | - | <1/day | Gravity Forms logs | Daily |
| JavaScript errors | - | 0 | Browser console | Daily |
| PHP errors | - | 0 | WordPress logs | Daily |
| | | | | |
| **SEO** | | | | |
| Organic search ranking | Baseline | <10% drop | Google Search Console | Weekly |
| Indexed pages | Baseline | Maintain | Google Search Console | Weekly |
| Crawl errors | - | 0 | Google Search Console | Weekly |
| | | | | |
| **User Experience** | | | | |
| User satisfaction | - | >80% | Post-migration survey | 30 days |
| Support tickets | - | <5 | Support system | Weekly |
| Complaint rate | - | <2% | Email feedback | Weekly |

### 14.3 Monitoring Dashboard

**Real-Time Monitoring** (CloudWatch):
- ECS task health (running/stopped)
- ALB target health (healthy/unhealthy)
- HTTP response codes (2xx/4xx/5xx)
- Page load latency (p50, p95, p99)
- Database connections (active/idle)
- EFS throughput and IOPS

**Daily Reports**:
- Uptime percentage
- Error log summary
- Form submission count
- Top 10 slowest pages

**Weekly Reports**:
- Performance trends
- SEO ranking changes
- User feedback summary
- Cost analysis

---

## 15. Knowledge Transfer Plan

### 15.1 Knowledge Transfer Objectives

**Primary Goal**: Enable junior engineers and operations team to understand, manage, and troubleshoot the migrated Au Pair Hive tenant on the BBWS platform.

**Learning Outcomes**:
By the end of knowledge transfer, participants will be able to:
1. Explain the BBWS multi-tenant architecture
2. Describe the complete migration process
3. Troubleshoot common tenant issues
4. Perform basic tenant operations (health checks, restarts)
5. Understand WordPress on AWS best practices
6. Use monitoring and alerting tools

### 15.2 Knowledge Transfer Sessions

| Session # | Topic | Duration | Audience | Deliverables |
|-----------|-------|----------|----------|--------------|
| **KT-1** | BBWS Platform Overview | 1 hour | All | Architecture diagram, platform docs |
| **KT-2** | Migration Process Walkthrough | 2 hours | Junior engineers | Migration playbook |
| **KT-3** | Hands-On: Tenant Provisioning | 2 hours | Junior engineers | Lab exercises |
| **KT-4** | Troubleshooting Workshop | 1.5 hours | Operations team | Runbooks |
| **KT-5** | Monitoring & Alerting | 1 hour | Operations team | Dashboard guide |
| **KT-6** | Lessons Learned Review | 1 hour | All | Lessons learned doc |

**Total KT Time**: 8.5 hours

### 15.3 Documentation Deliverables

**For Junior Engineers** (Learning Focus):
1. **Migration Playbook** (Step-by-step guide)
   - How to plan a tenant migration
   - Export procedures for different hosting providers
   - Import and configuration steps
   - Testing checklist
   - Common pitfalls and how to avoid them

2. **BBWS Platform Guide** (Conceptual)
   - Architecture overview (with diagrams)
   - How multi-tenancy works
   - AWS services explained (ECS, RDS, EFS, ALB, Route53)
   - Security and isolation mechanisms

3. **Hands-On Labs**
   - Lab 1: Provision a test tenant
   - Lab 2: Import a sample database
   - Lab 3: Troubleshoot a failing tenant
   - Lab 4: Monitor tenant performance

**For Operations Team** (Operational Focus):
1. **Operations Runbook**
   - Daily health check procedures
   - Common issues and resolutions
   - Escalation procedures
   - Backup and restore procedures

2. **Monitoring Guide**
   - CloudWatch dashboard overview
   - Alert interpretation
   - Performance metrics explained
   - How to investigate incidents

3. **Troubleshooting Guide**
   - Symptom → Diagnosis → Resolution flowcharts
   - FAQ (Frequently Asked Questions)
   - Contact list for escalations

### 15.4 Knowledge Transfer Schedule

```
Week 4: Knowledge Transfer Week (Jan 27-31)

Monday (Jan 27):
  10:00-11:00  KT-1: BBWS Platform Overview
  14:00-16:00  KT-2: Migration Process Walkthrough

Tuesday (Jan 28):
  10:00-12:00  KT-3: Hands-On Tenant Provisioning (Lab)

Wednesday (Jan 29):
  10:00-11:30  KT-4: Troubleshooting Workshop
  14:00-15:00  KT-5: Monitoring & Alerting

Thursday (Jan 30):
  10:00-11:00  KT-6: Lessons Learned Review

Friday (Jan 31):
  All day      Open Q&A / Documentation review
```

### 15.5 Teaching Methodology

**For Junior Engineers**:
- **Guided Learning**: Walk through each step, explain the "why" not just the "how"
- **Hands-On Practice**: Lab exercises with real (test) tenants
- **Pair Programming**: Shadow senior engineer during actual migration
- **Documentation**: Encourage note-taking, provide templates
- **Q&A Sessions**: Regular check-ins for questions

**Teaching Tips for Seniors**:
- Use visual aids (diagrams, screenshots)
- Explain technical concepts in simple terms
- Provide context: "This is how it works on Xneelo vs BBWS"
- Share war stories: "Here's what went wrong when we first tried this"
- Be patient: Repeat explanations as needed
- Encourage questions: "No question is too basic"

### 15.6 Competency Assessment

**Knowledge Check Quiz** (Post-KT):
1. What are the three AWS environments in BBWS? (DEV, SIT, PROD)
2. Name 5 components of tenant infrastructure (Database, ECS service, EFS, ALB, DNS)
3. What does the import script do to WordPress URLs? (Replaces old URLs with new)
4. How do you check if a tenant is healthy? (Check container, DB, EFS, ALB, DNS)
5. Where are database credentials stored? (AWS Secrets Manager)
6. What's the first thing to check if forms aren't working? (Gravity Forms license, reCAPTCHA)
7. What does "503 Service Unavailable" usually mean? (No healthy targets in ALB)
8. Where do you find tenant logs? (CloudWatch Logs)
9. What's the proper way to restart a tenant? (Update ECS service desired count or deploy new task def)
10. Who do you escalate to for infrastructure issues? (DevOps team)

**Passing Score**: 8/10 (80%)

**Hands-On Assessment**:
- Provision a test tenant from scratch (pass/fail)
- Troubleshoot a simulated issue (pass/fail)
- Explain the architecture to a colleague (pass/fail)

---

## 16. Lessons Learned Template

*To be completed post-project*

### 16.1 What Went Well

| Item | Description | Why It Worked | Recommendation for Future |
|------|-------------|---------------|---------------------------|
| 1 | [Example: Detailed planning] | Identified risks early | Continue thorough planning phase |
| 2 | | | |
| 3 | | | |

### 16.2 What Didn't Go Well

| Item | Description | Root Cause | How We Addressed It | Prevention for Future |
|------|-------------|------------|---------------------|----------------------|
| 1 | [Example: License activation delay] | Vendor response time | Escalated to vendor support | Contact vendor 1 week earlier |
| 2 | | | | |
| 3 | | | | |

### 16.3 Metrics Summary

| Metric | Planned | Actual | Variance | Notes |
|--------|---------|--------|----------|-------|
| Project Duration | 21 days | TBD | TBD | |
| Total Cost | R93,610 | TBD | TBD | |
| Downtime | <2 hours | TBD | TBD | |
| Defects Found | <50 | TBD | TBD | |
| Test Pass Rate | >95% | TBD | TBD | |
| User Satisfaction | >80% | TBD | TBD | |

### 16.4 Key Takeaways

**Technical Learnings**:
1. [Example: Terraform state management for tenants]
2.
3.

**Process Learnings**:
1. [Example: UAT needs more time than estimated]
2.
3.

**People Learnings**:
1. [Example: Early stakeholder engagement is critical]
2.
3.

### 16.5 Recommendations

**For Next Migration**:
1.
2.
3.

**For Platform Improvement**:
1.
2.
3.

**For Documentation**:
1.
2.
3.

---

## 17. Appendices

### A. Glossary of Terms

**For Junior Engineers & Stakeholders**:

| Term | Definition | Example |
|------|------------|---------|
| **ALB** | Application Load Balancer - AWS service that routes HTTP traffic | Routes banana.wpdev.kimmyai.io traffic to tenant container |
| **CloudFront** | AWS CDN (Content Delivery Network) - caches content globally | Serves images faster to users worldwide |
| **DEV** | Development environment - for testing and experimentation | aupairhive.wpdev.kimmyai.io |
| **DNS** | Domain Name System - translates domain names to IP addresses | aupairhive.com → 13.247.8.121 |
| **ECS** | Elastic Container Service - AWS service for running Docker containers | Runs WordPress in Docker containers |
| **EFS** | Elastic File System - AWS shared file storage | Stores WordPress files (uploads, themes, plugins) |
| **Fargate** | AWS serverless compute for containers - no EC2 management | Runs containers without managing servers |
| **Gravity Forms** | Premium WordPress plugin for creating forms | Family/Au Pair application forms |
| **Multi-Tenant** | Single platform serving multiple isolated customers | BBWS hosts many WordPress sites on shared infrastructure |
| **PROD** | Production environment - live customer-facing site | aupairhive.com |
| **RDS** | Relational Database Service - AWS managed MySQL database | Hosts tenant databases |
| **Route53** | AWS DNS service | Manages wpdev.kimmyai.io domain records |
| **SIT** | System Integration Testing environment - pre-production staging | aupairhive.wpsit.kimmyai.io |
| **SSL/TLS** | Secure Sockets Layer - encrypts HTTPS traffic | Green padlock in browser |
| **Terraform** | Infrastructure-as-Code tool - defines AWS resources in code | tenant_ecs_service.tf |
| **TTL** | Time To Live - how long DNS records are cached | 300s = 5 minutes |
| **UAT** | User Acceptance Testing - business owner validates before go-live | Business owner tests forms work |
| **VPC** | Virtual Private Cloud - isolated network in AWS | Private network for tenant resources |
| **WordPress** | Open-source content management system (CMS) | Platform powering aupairhive.com |

### B. Acronyms

| Acronym | Full Term |
|---------|-----------|
| API | Application Programming Interface |
| AWS | Amazon Web Services |
| CCB | Change Control Board |
| CDN | Content Delivery Network |
| CLI | Command Line Interface |
| CMS | Content Management System |
| CNAME | Canonical Name (DNS record type) |
| DB | Database |
| DNS | Domain Name System |
| DRY | Don't Repeat Yourself |
| EC2 | Elastic Compute Cloud |
| ECS | Elastic Container Service |
| EFS | Elastic File System |
| ETA | Estimated Time of Arrival |
| FAQ | Frequently Asked Questions |
| FTP | File Transfer Protocol |
| GB | Gigabyte |
| GDPR | General Data Protection Regulation |
| HTML | HyperText Markup Language |
| HTTP | HyperText Transfer Protocol |
| HTTPS | HTTP Secure |
| IAM | Identity and Access Management |
| IP | Internet Protocol |
| JSON | JavaScript Object Notation |
| KB | Kilobyte |
| KPI | Key Performance Indicator |
| KT | Knowledge Transfer |
| LB | Load Balancer |
| MB | Megabyte |
| MFA | Multi-Factor Authentication |
| MTTR | Mean Time To Repair |
| MySQL | Relational database system |
| NFS | Network File System |
| PHP | PHP: Hypertext Preprocessor |
| PM | Project Manager |
| POC | Proof of Concept |
| POPIA | Protection of Personal Information Act (South Africa) |
| PROD | Production |
| QA | Quality Assurance |
| RACI | Responsible, Accountable, Consulted, Informed |
| RDS | Relational Database Service |
| ROI | Return on Investment |
| RTO | Recovery Time Objective |
| S3 | Simple Storage Service |
| SEO | Search Engine Optimization |
| SIT | System Integration Testing |
| SLA | Service Level Agreement |
| SMTP | Simple Mail Transfer Protocol |
| SQL | Structured Query Language |
| SSH | Secure Shell |
| SSL | Secure Sockets Layer |
| TBT | Turn-by-Turn (workflow mechanism) |
| TLS | Transport Layer Security |
| TTL | Time To Live |
| UAT | User Acceptance Testing |
| URL | Uniform Resource Locator |
| VPC | Virtual Private Cloud |
| WBS | Work Breakdown Structure |
| WCAG | Web Content Accessibility Guidelines |
| WP | WordPress |
| WSOD | White Screen of Death |
| YAML | YAML Ain't Markup Language |

### C. Reference Documents

| Document | Location | Purpose |
|----------|----------|---------|
| Migration Plan (Technical) | `aupairhive_migration_plan.md` | Detailed technical migration steps |
| Xneelo Export Instructions | `xneelo_export_instructions.md` | How to export from Xneelo |
| Testing Checklist | `aupairhive_testing_checklist.md` | Comprehensive test cases |
| Database Import Script | `import_database.sh` | Automated database import |
| File Upload Script | `upload_wordpress_files.sh` | Automated file upload |
| Tenant Manager Agent | `agent.md` | Agent capabilities reference |
| BBWS Platform Docs | `../../2_bbws_docs/` | Platform documentation |

### D. Contact List

| Role | Name | Email | Phone | Availability |
|------|------|-------|-------|--------------|
| Project Sponsor | [Name] | [email] | [phone] | Business hours |
| Project Manager | [Name] | [email] | [phone] | Business hours + on-call |
| Technical Lead | [Name] | [email] | [phone] | Business hours + on-call |
| DevOps Engineer | [Name] | [email] | [phone] | Business hours |
| Business Owner | [Name] | [email] | [phone] | Flexible |
| Escalation (24/7) | [Name] | [email] | [phone] | 24/7 |

### E. Key Dates

| Event | Date | Notes |
|-------|------|-------|
| Project Kickoff | Jan 7, 2026 | Team alignment |
| Xneelo Export Deadline | Jan 13, 2026 | Must complete before DEV |
| DEV Sign-Off | Jan 17, 2026 | Gate to SIT |
| SIT Sign-Off | Jan 20, 2026 | Gate to PROD |
| DNS TTL Reduction | Jan 22, 2026 | 48h before cutover |
| **GO-LIVE** | **Jan 24, 2026** | **Production cutover** |
| Post-Migration Review | Jan 31, 2026 | Lessons learned |
| Xneelo Cancellation | Feb 7, 2026 | 7-day safety period |

---

## Document Approval

**Prepared By**:
Name: Tenant Manager Agent
Title: Technical Lead
Date: 2026-01-09
Signature: _______________________

**Reviewed By**:
Name: [PM Name]
Title: Project Manager
Date: _______________________
Signature: _______________________

**Approved By**:
Name: [Business Owner]
Title: Project Sponsor
Date: _______________________
Signature: _______________________

---

**END OF PROJECT PLAN**

**Version**: 1.0
**Status**: 🟡 PENDING APPROVAL
**Next Review**: Upon sponsor approval

---

## How to Use This Plan (For Junior Engineers)

**If you're new to project management or migrations, here's how to read this plan**:

1. **Start with Executive Summary (Section 1)**: Get the big picture
2. **Review the Timeline (Section 5)**: Understand what happens when
3. **Understand the WBS (Section 4)**: See all the tasks that need to happen
4. **Check the RACI (Section 3.2)**: Know who does what
5. **Read the Risks (Section 7)**: Learn what could go wrong
6. **Study the Testing Strategy (Section 10)**: Understand quality gates
7. **Follow the State Tracking (Section 12)**: Monitor progress

**Key Takeaways for Juniors**:
- **Planning is critical**: 50% of project success is good planning
- **State tracking matters**: Always know where you are in the project
- **Communication is key**: Keep stakeholders informed
- **Risks need mitigation**: Identify risks early, plan responses
- **Quality gates prevent issues**: Don't skip testing phases
- **Documentation enables learning**: Write everything down

**Questions to Ask Your Mentor**:
1. Why did we choose this specific WBS structure?
2. How did we estimate the durations?
3. What's the critical path and why does it matter?
4. How do we know when to escalate a risk?
5. What does "good" state tracking look like?
6. How do you balance speed vs quality?

Good luck with the migration! 🚀
