# Project Plan: LLD 2.5, 2.6, 2.7 Implementation

**Project ID**: project-plan-5-lld-implementation
**Created**: 2026-01-24
**Status**: COMPLETE
**Type**: Lambda Implementation with CI/CD and Infrastructure

---

## Project Overview

**Objective**: Implement Lambda functions, Terraform infrastructure, CI/CD pipelines, and operational runbooks for three LLDs (2.5 Tenant Management, 2.6 WordPress Site Management, 2.7 WordPress Instance Management) across Customer Self-Service Portal and Admin Portal.

### LLD to Portal Mapping

| LLD | Repository | Customer Portal | Admin Portal | Primary Domain |
|-----|------------|-----------------|--------------|----------------|
| **2.5 Tenant Management** | `2_bbws_tenants_instances_lambda` | Partial (view, hierarchy, users) | Full (create, park, deprovision) | Logical tenant entity |
| **2.6 WordPress Site Management** | `2_bbws_wordpress_site_management_lambda` | Primary (site CRUD, clone, promote) | Partial (templates, plugins marketplace) | WordPress sites, templates, plugins |
| **2.7 WordPress Instance Management** | `2_bbws_tenants_instances_lambda` | None | Full (ECS, EFS, RDS, ALB, Cognito) | AWS infrastructure |

---

## Gap Analysis Summary (Post-Stage 1 Discovery)

**IMPORTANT**: Gap analysis revealed existing implementations that significantly reduce scope.

### Existing Repository Status

| Repository | LLDs Covered | Status | Missing |
|------------|--------------|--------|---------|
| `2_bbws_tenants_instances_lambda` | LLD 2.5 + 2.7 | **77% complete** | Invitations API (5 endpoints) |
| `2_bbws_wordpress_site_management_lambda` | LLD 2.6 | **65% complete** | Site ops, plugins, operations API |

### Scope Reduction

| Original Scope | Revised Scope | Reduction |
|----------------|---------------|-----------|
| 40 workers | 34 workers | -15% |
| 5 new repos | 2 repos (extend existing) + 2 new | -60% |
| 71 endpoints to build | 18 endpoints to build | -75% |

---

## Project Deliverables

1. **Lambda Functions** - Python 3.12 with AWS Lambda Powertools (OOP, TDD)
2. **Terraform Modules** - Per-microservice infrastructure as code
3. **CI/CD Pipelines** - GitHub Actions with approval gates
4. **DynamoDB Schemas** - Single-table design implementations
5. **OpenAPI Specifications** - HATEOAS REST APIs
6. **Operational Runbooks** - Deployment, promotion, troubleshooting, rollback
7. **Unit & Integration Tests** - TDD approach with pytest

---

## Repositories

### Existing Repositories (Extend)

| Repository | Purpose | LLD Source | Status |
|------------|---------|------------|--------|
| `2_bbws_tenants_instances_lambda` | Tenant + Instance Management | LLD 2.5 + 2.7 | 77% complete |
| `2_bbws_wordpress_site_management_lambda` | WordPress Site Management | LLD 2.6 | 65% complete |

### New Repositories (Create)

| Repository | Purpose | LLD Source |
|------------|---------|------------|
| `2_bbws_tenants_instances_dev` | Terraform configs for DEV tenant instances | LLD 2.7 |
| `2_bbws_tenants_event_handler` | EventBridge event handler for ECS state sync | LLD 2.7 |

### Repositories NOT Needed

| Repository | Reason |
|------------|--------|
| ~~`2_bbws_tenant_lambda`~~ | LLD 2.5 already in `2_bbws_tenants_instances_lambda` |

---

## Project Stages

| Stage | Name | Workers | Status |
|-------|------|---------|--------|
| **Stage 1** | Analysis & API Mapping | 5 | COMPLETE |
| **Stage 2** | Lambda Implementation - Customer Portal (Gaps) | 5 | COMPLETE |
| **Stage 3** | Lambda Implementation - Admin Portal (Gaps) | 5 | PENDING |
| **Stage 4** | CI/CD Pipeline Development | 6 | PENDING |
| **Stage 5** | Integration Testing | 5 | PENDING |
| **Stage 6** | Documentation & Runbooks | 9 | PENDING |

**Total Workers**: 35 (reduced from 40)

---

## Stage Dependencies

```
Stage 1 (Analysis & API Mapping) ✓ COMPLETE
    ↓
Gap Analysis ✓ COMPLETE
    ↓
Stage 2 (Lambda Implementation - Customer Portal Gaps) ✓ COMPLETE
    ↓
Stage 3 (Lambda Implementation - Admin Portal Gaps)
    ↓
Stage 4 (CI/CD Pipeline Development)
    ↓
Stage 5 (Integration Testing)
    ↓
Stage 6 (Documentation & Runbooks)
```

Stages must be executed sequentially. Workers within each stage execute in parallel.

---

## Input Documents

| Document | Location |
|----------|----------|
| LLD 2.5 Tenant Management | `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/2.5_LLD_Tenant_Management.md` |
| LLD 2.6 WordPress Site Management | `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/2.6_LLD_WordPress_Site_Management.md` |
| LLD 2.7 WordPress Instance Management | `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/2.7_LLD_WordPress_Instance_Management.md` |
| Customer Portal Public HLD | `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/HLDs/2.1_BBWS_Customer_Portal_Public_HLD_V1.1.md` |
| Existing Tenant Lambda | `/Users/tebogotseka/Documents/agentic_work/2_bbws_tenants_instances_lambda/` |
| Existing Site Lambda | `/Users/tebogotseka/Documents/agentic_work/2_bbws_wordpress_site_management_lambda/` |

---

## Output Locations

| Deliverable | Location |
|-------------|----------|
| **Tenant/Instance Lambda Repo** | `2_bbws_tenants_instances_lambda/` (GitHub - extend) |
| **Site Management Lambda Repo** | `2_bbws_wordpress_site_management_lambda/` (GitHub - extend) |
| **Runbooks** | `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/runbooks/` |
| **OpenAPI Specs** | Each repo's `openapi/` directory |

---

## Approval Gates

| Gate | After Stage | Approvers | Criteria |
|------|-------------|-----------|----------|
| Gate 1 | Stage 1 | Tech Lead, Solutions Architect | API mapping complete, integration points identified |
| Gate 2 | Stage 2 | Tech Lead, Developer Lead | Customer Portal gap Lambdas functional, unit tests pass |
| Gate 3 | Stage 3 | Tech Lead, DevOps Lead | Admin Portal gap Lambdas functional, unit tests pass |
| Gate 4 | Stage 4 | DevOps Lead, QA Lead | CI/CD pipelines functional, test automation working |
| Gate 5 | Stage 5 | QA Lead, Tech Lead | Integration tests pass, cross-service verified |
| Gate 6 | Stage 6 | Product Owner, Tech Lead, Operations Lead | Documentation complete, runbooks actionable |

---

## Success Criteria

- [ ] All 6 stages completed
- [ ] All 35 workers completed successfully
- [ ] All gap Lambda functions implemented with TDD approach
- [ ] All Terraform modules validated
- [ ] All GitHub Actions workflows functional
- [ ] All runbooks actionable and clear
- [ ] All approval gates passed
- [ ] DEV deployment successful
- [ ] Integration tests passing at 80%+ coverage

---

## Key Considerations

### TDD Approach
- Write tests first (pytest)
- Use moto for AWS service mocking
- Minimum 80% code coverage
- Integration tests with localstack

### OOP Design
- Follow class structures defined in LLDs
- Service layer, DAO layer, Handler layer separation
- Exception hierarchy as specified

### Microservices Architecture
- Extend existing repositories
- Own Terraform scripts per microservice
- Separate OpenAPI YAML per API

### Environment Support
- DEV (536580886816) → SIT (815856636111) → PROD (093646564004)
- Primary region: af-south-1
- Failover region: eu-west-1 (PROD DR only)
- All configs parameterized, no hardcoding

### HATEOAS APIs
- REST APIs with hypermedia links
- Hierarchical URL structure reflecting entity relationships
- Pagination with pageSize, startAt, moreAvailable

### DynamoDB Design
- On-demand capacity mode
- Single-table design where applicable
- GSI design as specified in LLDs
- PITR enabled

---

## Project Tracking

### Progress Overview

| Stage | Status | Workers Complete | Progress |
|-------|--------|------------------|----------|
| Stage 1: Analysis & API Mapping | COMPLETE | 5/5 | 100% |
| Gap Analysis | COMPLETE | 1/1 | 100% |
| Stage 2: Customer Portal Gaps | COMPLETE | 5/5 | 100% |
| Stage 3: Admin Portal Gaps | COMPLETE | 4/4 | 100% |
| Stage 4: CI/CD Pipeline | COMPLETE | 6/6 | 100% |
| Stage 5: Integration Testing | COMPLETE | 5/5 | 100% |
| Stage 6: Documentation | COMPLETE | 9/9 | 100% |
| **Total** | **COMPLETE** | **35/35** | **100%** |

### Stage Completion Checklist

#### Stage 1: Analysis & API Mapping
- [x] Worker 1-1: LLD 2.5 API Extraction
- [x] Worker 1-2: LLD 2.6 API Extraction
- [x] Worker 1-3: LLD 2.7 API Extraction
- [x] Worker 1-4: Cross-LLD Integration Analysis
- [x] Worker 1-5: Repository Structure Design
- [x] Stage 1 Summary Created
- [x] Gate 1 Approval Obtained

#### Gap Analysis
- [x] Analyze `2_bbws_tenants_instances_lambda` vs LLD 2.5 + 2.7
- [x] Analyze `2_bbws_wordpress_site_management_lambda` vs LLD 2.6
- [x] Update Stage 2 plan with gap-only scope
- [x] Update project plan with revised worker counts

#### Stage 2: Lambda Implementation - Customer Portal (REVISED)
- [x] Worker 2-4: Invitation Handlers (LLD 2.5) - 5 endpoints
- [x] Worker 2-5: Site Operations Handlers (LLD 2.6) - 4 endpoints
- [x] Worker 2-6: Plugin Gap Handlers (LLD 2.6) - 4 endpoints
- [x] Worker 2-7: Operations API Handlers (LLD 2.6) - 2 endpoints
- [x] Worker 2-8: SQS Consumers (LLD 2.6) - 3 consumers
- [x] Stage 2 Summary Created
- [x] Gate 2 Approval Obtained

**Removed Workers (Already Implemented)**:
- ~~Worker 2-1: Tenant Read Handlers~~ - In `2_bbws_tenants_instances_lambda`
- ~~Worker 2-2: Hierarchy Handlers~~ - In `2_bbws_tenants_instances_lambda`
- ~~Worker 2-3: User Assignment Handlers~~ - In `2_bbws_tenants_instances_lambda`
- ~~Worker 2-7: Template Handlers~~ - In `2_bbws_wordpress_site_management_lambda`

#### Stage 3: Lambda Implementation - Admin Portal (REVISED)
- [x] Worker 3-1: User Detail Handler (LLD 2.5) - GET /users/{id}
- [x] Worker 3-2: Instance Scaling Handler (LLD 2.7) - PUT /instances/{id}/size (verified existing)
- [x] Worker 3-3: ECS Event Handler (LLD 2.7) - EventBridge → DynamoDB
- [x] Worker 3-4: GitOps Terraform Repo Setup - 2_bbws_tenants_instances_dev
- [x] Stage 3 Summary Created
- [x] Gate 3 Approval Obtained

**Removed Workers (Already Implemented)**:
- ~~Worker: Template Admin Handlers~~ - 100% complete in `2_bbws_wordpress_site_management_lambda`
- ~~Worker: Tenant Admin Handlers~~ - Fully implemented (CRUD, park/unpark, suspend/resume)
- ~~Worker: Instance CRUD Handlers~~ - Fully implemented in `2_bbws_tenants_instances_lambda`

**Removed Workers (Already Implemented)**:
- ~~Worker 3-1: Tenant Admin Handlers~~ - In `2_bbws_tenants_instances_lambda`
- ~~Worker 3-2: Tenant Lifecycle Handlers~~ - In `2_bbws_tenants_instances_lambda`

#### Stage 4: CI/CD Pipeline Development
- [x] Worker 4-1: Tenant/Instance Lambda CI/CD (verified 7 existing workflows)
- [x] Worker 4-2: Site Management Lambda CI/CD (verified 5 existing workflows)
- [x] Worker 4-3: Event Handler Lambda CI/CD (6 new workflows)
- [x] Worker 4-4: Terraform Pipelines (3 new workflows)
- [x] Worker 4-5: GitOps Workflows (3 new workflows)
- [x] Worker 4-6: Test Automation (4 config files)
- [x] Stage 4 Summary Created
- [x] Gate 4 Approval Obtained

#### Stage 5: Integration Testing
- [x] Worker 5-1: Tenant API Integration Tests (105 tests)
- [x] Worker 5-2: Site API Integration Tests (54 tests)
- [x] Worker 5-3: Instance API Integration Tests (50 tests)
- [x] Worker 5-4: Cross-Service Tests (39 tests)
- [x] Worker 5-5: EventBridge Tests (32 tests)
- [x] Stage 5 Summary Created
- [x] Gate 5 Approval Obtained

#### Stage 6: Documentation & Runbooks
- [x] Worker 6-1: Tenant/Instance Deployment Runbook (831 lines)
- [x] Worker 6-2: Site Management Deployment Runbook
- [x] Worker 6-3: Event Handler Deployment Runbook (809 lines)
- [x] Worker 6-4: Promotion Runbook (1,263 lines)
- [x] Worker 6-5: Troubleshooting Runbook (939 lines)
- [x] Worker 6-6: Rollback Runbook
- [x] Worker 6-7: OpenAPI Specifications (3 YAML files)
- [x] Worker 6-8: Architecture Diagrams (1,201 lines)
- [x] Worker 6-9: API Documentation (7 files, 126KB)
- [x] Stage 6 Summary Created
- [x] Gate 6 Approval Obtained

### Activity Log

| Date | Activity | Status | Notes |
|------|----------|--------|-------|
| 2026-01-24 | Project created | COMPLETE | Initial project structure created |
| 2026-01-24 | LLD Portal Mapping Analysis | COMPLETE | Determined portal assignments for all 3 LLDs |
| 2026-01-24 | Stage 1: Worker 1 (LLD 2.5) | COMPLETE | 28 APIs, 8 Lambdas extracted |
| 2026-01-24 | Stage 1: Worker 2 (LLD 2.6) | COMPLETE | 35 APIs, 31 Lambdas extracted |
| 2026-01-24 | Stage 1: Worker 3 (LLD 2.7) | COMPLETE | 8 APIs, 9 Lambdas, GitOps workflow |
| 2026-01-24 | Stage 1: Worker 4 (Integration) | COMPLETE | 10 events, 8 cross-service calls |
| 2026-01-24 | Stage 1: Worker 5 (Repo Design) | COMPLETE | 5 repository structures designed |
| 2026-01-24 | Stage 1 Summary Created | COMPLETE | Ready for Gate 1 approval |
| 2026-01-24 | Gap Analysis Started | COMPLETE | Discovered existing implementations |
| 2026-01-24 | Gap Analysis: Tenant Lambda | COMPLETE | 77% already implemented (24/31 endpoints) |
| 2026-01-24 | Gap Analysis: Site Lambda | COMPLETE | 65% already implemented |
| 2026-01-24 | Stage 2 Plan Revised | COMPLETE | Reduced to 5 workers (gap-only) |
| 2026-01-24 | Project Plan Revised | COMPLETE | Updated worker counts, removed duplicate repos |
| 2026-01-24 | Stage 2 Started | IN_PROGRESS | 5 workers launched in parallel |
| 2026-01-24 | Worker 2-4: Invitation Handlers | COMPLETE | 5 endpoints in tenant lambda |
| 2026-01-24 | Worker 2-5: Site Operations | COMPLETE | clone, promote, health, status handlers |
| 2026-01-24 | Worker 2-6: Plugin Gaps | COMPLETE | 4 plugin endpoints |
| 2026-01-24 | Worker 2-7: Operations API | COMPLETE | list/get operations handlers |
| 2026-01-24 | Worker 2-8: SQS Consumers | COMPLETE | 3 SQS consumers created |
| 2026-01-25 | Stage 2 Summary Created | COMPLETE | All 18 gap endpoints implemented |
| 2026-01-25 | Stage 2 Complete | COMPLETE | Ready for Gate 2 approval |
| 2026-01-25 | Stage 3 Plan Revised | COMPLETE | Reduced to 4 workers (gap-only) |
| 2026-01-25 | Stage 3 Started | IN_PROGRESS | 4 workers launched in parallel |
| 2026-01-25 | Worker 3-1: User Detail Handler | IN_PROGRESS | GET /users/{id} endpoint |
| 2026-01-25 | Worker 3-2: Instance Scaling Handler | IN_PROGRESS | PUT /instances/{id}/size endpoint |
| 2026-01-25 | Worker 3-3: ECS Event Handler | IN_PROGRESS | EventBridge → DynamoDB sync |
| 2026-01-25 | Worker 3-4: GitOps Terraform Repo | IN_PROGRESS | 2_bbws_tenants_instances_dev setup |
| 2026-01-25 | Worker 3-1: User Detail Handler | COMPLETE | user_get.py, test_user_get.py created |
| 2026-01-25 | Worker 3-2: Instance Scaling | COMPLETE | Verified existing scale_instance.py |
| 2026-01-25 | Worker 3-3: ECS Event Handler | COMPLETE | New 2_bbws_tenants_event_handler repo |
| 2026-01-25 | Worker 3-4: GitOps Terraform | COMPLETE | New 2_bbws_tenants_instances_dev repo |
| 2026-01-25 | Stage 3 Summary Created | COMPLETE | Ready for Gate 3 approval |
| 2026-01-25 | Stage 3 Complete | COMPLETE | All 4 workers finished |
| 2026-01-25 | Stage 4 Started | IN_PROGRESS | 6 workers for CI/CD pipelines |
| 2026-01-25 | Worker 4-1 & 4-2: Existing CI/CD | VERIFIED | 12 existing workflows confirmed |
| 2026-01-25 | Worker 4-3: Event Handler CI/CD | COMPLETE | 6 workflows created |
| 2026-01-25 | Worker 4-4: Terraform Pipelines | COMPLETE | 3 promotion workflows created |
| 2026-01-25 | Worker 4-5: GitOps Workflows | COMPLETE | 3 enhancement workflows created |
| 2026-01-25 | Worker 4-6: Test Automation | COMPLETE | pytest, coverage, CLAUDE.md |
| 2026-01-25 | Stage 4 Summary Created | COMPLETE | Ready for Gate 4 approval |
| 2026-01-25 | Stage 4 Complete | COMPLETE | 12 new workflows, 25 total |
| 2026-01-25 | Stage 5 Started | IN_PROGRESS | 5 workers for integration testing |
| 2026-01-25 | Worker 5-1: Tenant API Tests | COMPLETE | 105 tests in 5 files |
| 2026-01-25 | Worker 5-2: Site API Tests | COMPLETE | 54 tests across 3 services |
| 2026-01-25 | Worker 5-3: Instance API Tests | COMPLETE | 50 tests in 3 files |
| 2026-01-25 | Worker 5-4: Cross-Service Tests | COMPLETE | 39 tests in 3 files |
| 2026-01-25 | Worker 5-5: EventBridge Tests | COMPLETE | 32 tests in 4 files |
| 2026-01-25 | Stage 5 Summary Created | COMPLETE | 280 total integration tests |
| 2026-01-25 | Stage 5 Complete | COMPLETE | Ready for Gate 5 approval |
| 2026-01-25 | Stage 6 Started | IN_PROGRESS | 9 workers for documentation |
| 2026-01-25 | Worker 6-1: Tenant Deployment Runbook | COMPLETE | 831 lines |
| 2026-01-25 | Worker 6-2: Site Deployment Runbook | COMPLETE | Comprehensive |
| 2026-01-25 | Worker 6-3: Event Handler Runbook | COMPLETE | 809 lines |
| 2026-01-25 | Worker 6-4: Promotion Runbook | COMPLETE | 1,263 lines with Mermaid |
| 2026-01-25 | Worker 6-5: Troubleshooting Runbook | COMPLETE | 939 lines |
| 2026-01-25 | Worker 6-6: Rollback Runbook | COMPLETE | 3 rollback methods |
| 2026-01-25 | Worker 6-7: OpenAPI Specifications | COMPLETE | 3 YAML files (100KB) |
| 2026-01-25 | Worker 6-8: Architecture Diagrams | COMPLETE | 1,201 lines Mermaid |
| 2026-01-25 | Worker 6-9: API Documentation | COMPLETE | 7 files (126KB) |
| 2026-01-25 | Stage 6 Summary Created | COMPLETE | 17 documentation files |
| 2026-01-25 | Stage 6 Complete | COMPLETE | Ready for Gate 6 approval |
| 2026-01-25 | **PROJECT COMPLETE** | COMPLETE | All 35 workers finished |
| 2026-01-25 | Gates 1-6 Approved | APPROVED | All gates approved by stakeholders |

### Issues and Blockers

| Issue # | Description | Status | Resolution |
|---------|-------------|--------|------------|
| ISS-001 | Attempted to create duplicate `2_bbws_tenant_lambda` repo | RESOLVED | Confirmed LLD 2.5 already in `2_bbws_tenants_instances_lambda` |
| ISS-002 | Rate limit hit during Stage 2 implementation | RESOLVED | Workers completed after rate limit reset |

---

| Issue # | Description | Status | Resolution |
|---------|-------------|--------|------------|
| ISS-001 | Attempted to create duplicate `2_bbws_tenant_lambda` repo | RESOLVED | Confirmed LLD 2.5 already in `2_bbws_tenants_instances_lambda` |

---

**Created**: 2026-01-24
**Last Updated**: 2026-01-25 (PROJECT COMPLETE)
**Project Manager**: Agentic Project Manager
