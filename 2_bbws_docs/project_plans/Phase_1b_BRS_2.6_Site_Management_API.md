# Phase 1b: BRS 2.6 - WordPress Site Management API
## Project Plan

**Document ID**: PP-PHASE-1B-2.6
**Version**: 1.0
**Created**: 2026-01-16
**Status**: Draft
**Priority**: P0 - CRITICAL

---

## PROJECT STATUS

| Metric | Value |
|--------|-------|
| **Overall Status** | NOT STARTED |
| **Phase** | Phase 1b (Core APIs) |
| **Progress** | 0% |
| **Target Duration** | 8 weeks |
| **Dependencies** | Phase 0 (BRS 2.5 Tenant API) |

---

## 1. Project Overview

### 1.1 Objective

Build the **WordPress Site Management API** - the self-service capability enabling customers to create, configure, and manage WordPress sites including templates, plugins, and environment promotion (DEV → SIT → PROD).

### 1.2 Business Value

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| Site Creation Time | 2-3 days | 15 minutes | 99% reduction |
| Support Tickets (site mgmt) | 500/month | 100/month | 80% reduction |
| Customer Churn | 8% | 5% | 3% improvement |
| Time to First Site | 5 days | Same day | 5x faster |

### 1.3 Key Deliverables

| Deliverable | Description | Priority |
|-------------|-------------|----------|
| Site CRUD API | Create, Read, Update, Delete sites | P0 |
| Template Marketplace API | Browse, apply templates | P0 |
| Plugin Management API | Install, configure plugins | P0 |
| Environment Promotion API | DEV → SIT → PROD workflow | P0 |
| Background Jobs API | Long-running task status | P1 |
| Site Cloning API | Duplicate sites | P1 |

### 1.4 Success Criteria

| Metric | Target |
|--------|--------|
| Site Creation Time | < 15 minutes |
| Template Application | < 5 minutes |
| Plugin Installation | < 2 minutes |
| Environment Promotion | < 10 minutes |

---

## 2. Project Tracking

### 2.1 Stage Progress

| Stage | Status | Progress | Deliverable |
|-------|--------|----------|-------------|
| Stage 1: Requirements Validation | ⏳ PENDING | 0% | Validated BRS 2.6 |
| Stage 2: HLD Creation | ⏳ PENDING | 0% | 2.6_HLD_Site_Management.md |
| Stage 3: LLD Creation | ⏳ PENDING | 0% | 2.6_LLD_Site_Management.md |
| Stage 4: OpenAPI Spec | ⏳ PENDING | 0% | openapi_site_management.yaml |
| Stage 5: Template/Plugin Design | ⏳ PENDING | 0% | Marketplace architecture |
| Stage 6: TDD Tests | ⏳ PENDING | 0% | Unit + Integration tests |
| Stage 7: Lambda Implementation | ⏳ PENDING | 0% | 18 Lambda functions |
| Stage 8: Step Functions | ⏳ PENDING | 0% | Promotion workflows |
| Stage 9: Terraform IaC | ⏳ PENDING | 0% | Infrastructure as Code |
| Stage 10: DEV Deployment | ⏳ PENDING | 0% | Deployed to DEV |
| Stage 11: Integration Testing | ⏳ PENDING | 0% | All tests passing |

---

## 3. Technical Architecture

### 3.1 API Endpoints - Site Lifecycle

| Method | Endpoint | Description | Lambda |
|--------|----------|-------------|--------|
| POST | `/v1.0/sites` | Create site | site-create |
| GET | `/v1.0/sites/{siteId}` | Get site | site-get |
| PUT | `/v1.0/sites/{siteId}` | Update site | site-update |
| DELETE | `/v1.0/sites/{siteId}` | Delete site | site-delete |
| GET | `/v1.0/sites` | List sites | site-list |
| POST | `/v1.0/sites/{siteId}/clone` | Clone site | site-clone |
| POST | `/v1.0/sites/{siteId}/suspend` | Suspend site | site-suspend |
| POST | `/v1.0/sites/{siteId}/resume` | Resume site | site-resume |

### 3.2 API Endpoints - Template Marketplace

| Method | Endpoint | Description | Lambda |
|--------|----------|-------------|--------|
| GET | `/v1.0/templates` | List templates | template-list |
| GET | `/v1.0/templates/{templateId}` | Get template | template-get |
| POST | `/v1.0/templates/{templateId}/preview` | Preview template | template-preview |
| POST | `/v1.0/sites/{siteId}/templates` | Apply template | template-apply |

### 3.3 API Endpoints - Plugin Management

| Method | Endpoint | Description | Lambda |
|--------|----------|-------------|--------|
| GET | `/v1.0/plugins` | List available plugins | plugin-list |
| GET | `/v1.0/sites/{siteId}/plugins` | Get installed plugins | plugin-installed |
| POST | `/v1.0/sites/{siteId}/plugins` | Install plugin | plugin-install |
| DELETE | `/v1.0/sites/{siteId}/plugins/{pluginId}` | Remove plugin | plugin-remove |
| PUT | `/v1.0/sites/{siteId}/plugins/{pluginId}` | Update plugin | plugin-update |

### 3.4 API Endpoints - Environment Promotion

| Method | Endpoint | Description | Lambda |
|--------|----------|-------------|--------|
| POST | `/v1.0/sites/{siteId}/promote` | Initiate promotion | promote-initiate |
| GET | `/v1.0/sites/{siteId}/promotions` | List promotions | promote-list |
| GET | `/v1.0/promotions/{promotionId}` | Get promotion status | promote-status |
| POST | `/v1.0/promotions/{promotionId}/approve` | Approve promotion | promote-approve |
| POST | `/v1.0/promotions/{promotionId}/rollback` | Rollback promotion | promote-rollback |

### 3.5 Environment Promotion Workflow

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     ENVIRONMENT PROMOTION WORKFLOW                       │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   DEV                      SIT                      PROD                 │
│   ┌───────────┐           ┌───────────┐           ┌───────────┐         │
│   │ WordPress │  promote  │ WordPress │  promote  │ WordPress │         │
│   │   Site    │ ────────▶ │   Site    │ ────────▶ │   Site    │         │
│   └───────────┘           └───────────┘           └───────────┘         │
│                                                                          │
│   Promotion Steps:                                                       │
│   1. Create snapshot of source environment                              │
│   2. Validate target environment available                              │
│   3. Copy database (mysqldump + restore)                                │
│   4. Sync wp-content (EFS rsync)                                        │
│   5. Update wp-config.php URLs                                          │
│   6. Run health checks                                                  │
│   7. Update DNS/ALB routing                                             │
│   8. Notify stakeholders                                                │
│                                                                          │
│   Rollback:                                                              │
│   1. Restore from pre-promotion snapshot                                │
│   2. Revert DNS/ALB routing                                             │
│   3. Notify stakeholders                                                │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 3.6 Site Status State Machine

```
                    ┌─────────────┐
                    │  CREATING   │
                    └──────┬──────┘
                           │ creation complete
                           ▼
                    ┌─────────────┐
        ┌──────────▶│   ACTIVE    │◀──────────┐
        │           └──────┬──────┘           │
        │                  │                  │
        │ resume       suspend            promote
        │                  │                  │
        │           ┌──────▼──────┐    ┌──────┴──────┐
        │           │  SUSPENDED  │    │  PROMOTING  │
        │           └─────────────┘    └─────────────┘
        │                                     │
   ┌────┴─────┐                              │
   │ RESUMED  │◀─────────────────────────────┘
   └──────────┘
                           │
                    delete │
                           ▼
                    ┌─────────────┐
                    │   DELETED   │ (Soft delete)
                    └─────────────┘
```

---

## 4. Domain Model

### 4.1 Entities

| Entity | Description | Key Attributes |
|--------|-------------|----------------|
| Site | WordPress website | siteId, name, domain, status, environment |
| Template | Pre-built design | templateId, name, category, thumbnail |
| Plugin | WordPress extension | pluginId, name, version, isApproved |
| Promotion | Env promotion record | promotionId, sourceEnv, targetEnv, status |
| Job | Background task | jobId, type, status, progress |

### 4.2 DynamoDB Schema

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        SINGLE TABLE DESIGN                               │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  PRIMARY KEY:  PK = "TENANT#{tenantId}"                                 │
│                SK = "SITE#{siteId}" | "TEMPLATE#{templateId}" | ...     │
│                                                                          │
│  GSI-1 (Domain):  GSI1PK = "DOMAIN#{domain}"                            │
│                   GSI1SK = "SITE#{siteId}"                              │
│                                                                          │
│  GSI-2 (Status):  GSI2PK = "STATUS#{status}"                            │
│                   GSI2SK = "SITE#{siteId}"                              │
│                                                                          │
│  GSI-3 (Environment): GSI3PK = "ENV#{environment}"                      │
│                       GSI3SK = "TENANT#{tenantId}#SITE#{siteId}"        │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 5. Stage Breakdown

### Stage 1: Requirements Validation (2 days)
### Stage 2: HLD Creation (3 days)
### Stage 3: LLD Creation (5 days)
### Stage 4: OpenAPI Specification (3 days)
### Stage 5: Template/Plugin Design (4 days)
- Template S3 bucket structure
- Plugin vetting workflow
- Marketplace catalog design

### Stage 6: TDD Tests (5 days)
### Stage 7: Lambda Implementation (12 days)
- Site lifecycle (4 days)
- Template management (3 days)
- Plugin management (3 days)
- Promotion workflow (2 days)

### Stage 8: Step Functions (4 days)
- Site creation workflow
- Promotion workflow
- Clone workflow

### Stage 9: Terraform Infrastructure (3 days)
### Stage 10: DEV Deployment (2 days)
### Stage 11: Integration Testing (4 days)

---

## 6. Dependencies

### 6.1 Upstream Dependencies

| Dependency | Status | Owner |
|------------|--------|-------|
| BRS 2.5 Tenant API | REQUIRED | Phase 0 |
| BRS 2.7 Instance API | OPTIONAL | Phase 1a |
| S3 Template Bucket | READY | DevOps |
| S3 Plugin Repository | READY | DevOps |

### 6.2 Downstream Dependents

| Dependent | Waiting For |
|-----------|-------------|
| BRS 2.2 Customer Portal | Site API |
| BRS 2.4 Admin Portal | Site API |

---

## 7. Repository Structure

```
2_bbws_site_management/
├── README.md
├── src/
│   └── handlers/
│       ├── site_create.py
│       ├── site_get.py
│       ├── site_update.py
│       ├── site_delete.py
│       ├── site_list.py
│       ├── site_clone.py
│       ├── template_list.py
│       ├── template_get.py
│       ├── template_preview.py
│       ├── template_apply.py
│       ├── plugin_list.py
│       ├── plugin_installed.py
│       ├── plugin_install.py
│       ├── plugin_remove.py
│       ├── plugin_update.py
│       ├── promote_initiate.py
│       ├── promote_approve.py
│       └── promote_rollback.py
├── step_functions/
│   ├── site_creation_workflow.asl.json
│   ├── promotion_workflow.asl.json
│   └── clone_workflow.asl.json
├── tests/
├── terraform/
├── openapi/
│   └── site_management_v1.0.yaml
└── requirements.txt
```

---

## 8. Release Management

### Release Information

| Attribute | Value |
|-----------|-------|
| **Release #** | R1.2 |
| **Release Date** | _______________ |
| **UAT Signoff Date** | _______________ |
| **Business Owner** | _______________ |

### Deliverables Checklist

| # | Deliverable | Status | Sign-off |
|---|-------------|--------|----------|
| 1 | `HLDs/2.6_HLD_Site_Management.md` - Approved | ☐ | _______________ |
| 2 | `LLDs/2.6_LLD_Site_Management.md` - Approved | ☐ | _______________ |
| 3 | `2_bbws_site_management/` repository - Code complete | ☐ | _______________ |
| 4 | `openapi-specs/site_management_v1.0.yaml` - Finalized | ☐ | _______________ |
| 5 | Template marketplace - Functional | ☐ | _______________ |
| 6 | Plugin management system - Functional | ☐ | _______________ |
| 7 | Environment promotion workflows (DEV→SIT→PROD) - Tested | ☐ | _______________ |
| 8 | Terraform modules - Deployed to DEV | ☐ | _______________ |
| 9 | CI/CD pipelines - Operational | ☐ | _______________ |
| 10 | Unit tests - >80% coverage | ☐ | _______________ |
| 11 | Integration tests - All passing | ☐ | _______________ |

### Definition of Done

| # | Criteria | Status |
|---|----------|--------|
| 1 | All SDLC stages (1-11) completed | ☐ |
| 2 | All validation gates approved | ☐ |
| 3 | Code review completed and approved | ☐ |
| 4 | Security review passed | ☐ |
| 5 | Site CRUD operations functional | ☐ |
| 6 | Template application working (< 5 min) | ☐ |
| 7 | Plugin installation/management working (< 2 min) | ☐ |
| 8 | Environment promotion tested end-to-end (< 10 min) | ☐ |
| 9 | Site cloning operational | ☐ |
| 10 | DEV environment deployment successful | ☐ |
| 11 | SIT environment deployment successful | ☐ |
| 12 | UAT completed with sign-off | ☐ |
| 13 | PROD deployment approved | ☐ |
| 14 | Rollback procedure documented and tested | ☐ |
| 15 | DynamoDB single-table design validated | ☐ |

### Environment Promotion

| Environment | Deployment Date | Verified By | Status |
|-------------|-----------------|-------------|--------|
| DEV (536580886816) | _______________ | _______________ | ☐ Pending |
| SIT (815856636111) | _______________ | _______________ | ☐ Pending |
| PROD (093646564004) | _______________ | _______________ | ☐ Pending |

---

## 9. Approval

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Product Owner | | | |
| Tech Lead | | | |
| DevOps Lead | | | |
| Business Owner | | | |

---

*Phase 1b runs in parallel with Phase 1a after Phase 0 completes.*
