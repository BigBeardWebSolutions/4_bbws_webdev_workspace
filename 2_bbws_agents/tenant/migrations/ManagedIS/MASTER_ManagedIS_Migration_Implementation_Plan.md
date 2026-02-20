# MASTER: ManagedIS Migration Implementation Plan
## Xneelo → BBWS Multi-Tenant WordPress Platform

**Project Code**: MIGR-MIS-2026-01
**Site**: managedis.personalinvest.co.za
**Migration Date**: 2026-01-22
**Version**: 1.0
**Created**: 2026-01-22
**Status**: 🟡 IN PROGRESS

---

## Document Control

| Version | Date | Author | Status |
|---------|------|--------|--------|
| 1.0 | 2026-01-22 | Tenant Manager Agent | In Progress |

**Related Documents**:
- Site Profile: `.claude/staging/staging_1/site_profile.md`
- Migration Playbook: `../runbooks/wordpress_migration_playbook_automated.md`
- TBT Plan: `.claude/plans/plan_1.md`

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Migration Overview](#migration-overview)
3. [6-Phase Implementation Plan](#6-phase-implementation-plan)
4. [Critical Path](#critical-path)
5. [Dependencies Matrix](#dependencies-matrix)
6. [Risk Management](#risk-management)
7. [Quality Gates](#quality-gates)
8. [Success Criteria](#success-criteria)
9. [Documentation Checklist](#documentation-checklist)

---

## Executive Summary

### Migration Goal
Migrate managedis.personalinvest.co.za from Xneelo hosting to BBWS AWS multi-tenant platform with zero data loss and minimal downtime.

### Key Metrics
- **Total Duration**: ~2 hours (DEV environment)
- **Downtime Window**: <2 hours (DNS cutover for PROD)
- **Environments**: DEV → SIT → PROD
- **Data Volume**: ~615 MB site files, 13.6 MB database
- **Critical Features**: Contact forms, Uncode theme, Visual Composer

### Success Criteria
- ✅ All pages load without errors
- ✅ Contact Form 7 forms submit successfully
- ✅ Uncode theme renders correctly
- ✅ Visual Composer shortcodes display properly
- ✅ Page load time <3 seconds
- ✅ SSL certificate valid
- ✅ Zero data loss verified

---

## Migration Overview

### Current State (Source)
- **Platform**: WordPress 6.8.3 on Xneelo shared hosting
- **Theme**: Uncode (with child theme)
- **Page Builder**: Visual Composer/WPBakery
- **Plugins**: 17 active plugins
- **Domain**: managedis.personalinvest.co.za
- **Hosting**: Xneelo South Africa
- **Database Host**: srv005907:3306

### Future State (Target)
- **Platform**: BBWS AWS Multi-Tenant WordPress
- **Infrastructure**: ECS Fargate, RDS MySQL, EFS, ALB, Route53, CloudFront
- **Environments**:
  - DEV: managedis.wpdev.kimmyai.io (eu-west-1)
  - SIT: managedis.wpsit.kimmyai.io (eu-west-1)
  - PROD: managedis.personalinvest.co.za (af-south-1)
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

## 6-Phase Implementation Plan

### Phase 0: Discovery ✅ COMPLETE
- [x] Set up TBT tracking structure
- [x] Analyze database backup (WordPress 6.8.3, wp_ prefix)
- [x] Analyze site files (615 MB total, Uncode theme)
- [x] Generate site profile
- [x] Identify special considerations (LDAP plugin, email config)

### Phase 1: Pre-Migration Setup 🔄 IN PROGRESS
- [ ] Verify AWS CLI access with Tebogo-dev profile
- [ ] Upload database backup to S3
- [ ] Upload site files to S3
- [ ] Update CloudFront basic auth exclusion
- [ ] Create integration analysis document

### Phase 2: Target Environment Preparation
- [ ] Create tenant in DEV environment
- [ ] Verify ECS task is running
- [ ] Verify EFS mount
- [ ] Configure PHP memory limit (512M for Uncode)
- [ ] Export ECS task definition

### Phase 3: Database Migration
- [ ] Import database via bastion host
- [ ] Verify table creation
- [ ] Run URL search-replace operations
- [ ] Deactivate LDAP plugin via database
- [ ] Verify WordPress admin access

### Phase 4: Files Migration
- [ ] Sync wp-content to EFS via bastion
- [ ] Set correct permissions
- [ ] Verify theme files present
- [ ] Verify plugin files present
- [ ] Verify uploads directory

### Phase 5: Post-Migration Validation
- [ ] Test site accessibility
- [ ] Test admin login
- [ ] Test contact forms
- [ ] Verify media files loading
- [ ] Run full validation checklist
- [ ] Create testing documentation

### Phase 6: Documentation & Cleanup
- [ ] Create migration complete document
- [ ] Create testing summary
- [ ] Create site owner checklist
- [ ] Update TBT plan with completion

---

## Critical Path

```
Phase 0 → Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5 → Phase 6
Discovery  S3 Upload  Tenant     Database   Files     Validation Docs
           CF Config  Creation   Import     Sync
```

**Blockers to Watch:**
1. S3 bucket access from bastion host
2. Uncode theme PHP memory requirements
3. LDAP plugin deactivation
4. Visual Composer license (if applicable)

---

## Dependencies Matrix

| Task | Depends On | Blocking |
|------|------------|----------|
| S3 Upload | AWS CLI access | Database import |
| Tenant Creation | - | Database import, File sync |
| Database Import | S3 Upload, Tenant | URL replace |
| URL Replace | Database Import | Site testing |
| File Sync | S3 Upload, Tenant | Theme activation |
| Validation | All above | Documentation |

---

## Risk Management

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| LDAP plugin breaks login | High | High | Deactivate via database before testing |
| Uncode theme memory issues | Medium | Medium | Set PHP memory_limit to 512M |
| Visual Composer shortcodes | Medium | Low | Test archive pages specifically |
| WooCommerce remnants | Low | Low | Review database, clean if needed |
| Email deliverability | Medium | Medium | Configure WP Mail SMTP early |
| Encoding issues | Medium | Medium | Monitor for UTF-8 artifacts |

---

## Quality Gates

### Gate 1: Pre-Migration (Phase 1)
- [ ] AWS access verified
- [ ] S3 upload complete
- [ ] CloudFront exclusion configured

### Gate 2: Environment Ready (Phase 2)
- [ ] Tenant provisioned
- [ ] ECS task healthy
- [ ] PHP configuration correct

### Gate 3: Data Migration (Phase 3-4)
- [ ] Database imported successfully
- [ ] URLs replaced correctly
- [ ] Files synced completely

### Gate 4: Validation (Phase 5)
- [ ] Homepage loads
- [ ] Admin accessible
- [ ] Forms working
- [ ] Media loading

---

## Success Criteria

| Criterion | Target | Measurement |
|-----------|--------|-------------|
| Page Load Time | <3 seconds | Curl response time |
| Uptime | 100% | No 5xx errors |
| Data Integrity | Zero loss | Content count verification |
| Form Functionality | 100% | Test submissions |
| Media Accessibility | 100% | Image load verification |
| SSL Valid | Yes | Certificate check |

---

## Documentation Checklist

| Document | Status | Location |
|----------|--------|----------|
| Site Profile | ✅ Complete | `.claude/staging/staging_1/site_profile.md` |
| Master Plan | ✅ Complete | `MASTER_ManagedIS_Migration_Implementation_Plan.md` |
| Integration Analysis | 🔄 Pending | `managedis_integration_analysis.md` |
| Task Definition | 🔄 Pending | `managedis_task_definition.json` |
| Migration Complete | 🔄 Pending | `managedis_migration_complete.md` |
| Testing Summary | 🔄 Pending | `managedis_testing_summary.md` |
| Testing Verification | 🔄 Pending | `managedis_testing_verification.md` |
| Site Owner Checklist | 🔄 Pending | `PHASE2_SITE_OWNER_CHECKLIST.md` |
| Retrospective | 🔄 Pending | `managedis_migration_retrospective.md` |

---

**Document Version:** 1.0
**Last Updated:** 2026-01-22
**Maintained By:** Tenant Manager Agent
