# Phase 0: BRS 2.5 - Tenant Management API
## Project Plan

**Document ID**: PP-PHASE-0-2.5
**Version**: 1.0
**Created**: 2026-01-16
**Status**: Draft
**Priority**: P0 - CRITICAL (Foundation)

---

## PROJECT STATUS

| Metric | Value |
|--------|-------|
| **Overall Status** | IN PROGRESS |
| **Phase** | Phase 0 (Foundation) |
| **Progress** | 15% |
| **Target Duration** | 6 weeks |
| **Dependencies** | None (First to build) |
| **Repository** | `2_bbws_tenants_instances_lambda` |
| **Gap Analysis** | `LLDs/project-plan-tenant-management/stage-1-requirements/gap_analysis.md` |

---

## 1. Project Overview

### 1.1 Objective

Build the **Tenant Management API** - the foundational microservice that manages customer tenant organizations, hierarchy, user assignments, and lifecycle states. This is the CRITICAL PATH item that all other BRS components depend on.

### 1.2 Key Deliverables

| Deliverable | Description | Priority |
|-------------|-------------|----------|
| Tenant CRUD API | Create, Read, Update, Delete tenant operations | P0 |
| Organization Hierarchy API | Division → Group → Team structure | P1 |
| User Assignment API | Assign/remove users to/from tenants | P0 |
| Status Lifecycle API | PENDING → ACTIVE → SUSPENDED → PARKED → DEPROVISIONED | P0 |
| Park/Unpark API | Temporarily disable tenants | P1 |
| DynamoDB Schema | Single-table design with GSIs | P0 |
| Terraform Infrastructure | Lambda, API Gateway, DynamoDB | P0 |
| OpenAPI Specification | Complete API documentation | P0 |
| Unit & Integration Tests | 80%+ code coverage | P0 |

### 1.3 Success Criteria

| Metric | Target |
|--------|--------|
| API Response Time (P95) | < 200ms |
| Tenant Creation Time | < 5 seconds |
| Test Coverage | > 80% |
| Zero Critical Bugs | Before Phase 1 |
| API Gateway Latency | < 50ms overhead |

---

## 2. Project Tracking

### 2.1 Stage Progress

| Stage | Status | Progress | Deliverable |
|-------|--------|----------|-------------|
| Stage 1: Requirements Validation | 🔄 IN PROGRESS | 50% | Gap analysis complete |
| Stage 2: HLD Creation | ✅ COMPLETE | 100% | 2.5_HLD_Tenant_Management.md |
| Stage 3: LLD Creation | ✅ COMPLETE | 100% | 2.5_LLD_Tenant_Management.md |
| Stage 4: OpenAPI Spec | ✅ COMPLETE | 100% | openapi_tenant_management.yaml |
| Stage 5: DynamoDB Schema | 🔄 PARTIAL | 40% | Basic schema exists, GSIs needed |
| Stage 6: TDD Tests | 🔄 PARTIAL | 30% | Instance tests exist, tenant tests needed |
| Stage 7: Lambda Implementation | 🔄 PARTIAL | 10% | 1/13 handlers implemented (create_tenant) |
| Stage 8: Terraform IaC | 🔄 PARTIAL | 60% | Base infrastructure exists |
| Stage 9: DEV Deployment | ⏳ PENDING | 0% | Awaiting implementation |
| Stage 10: Integration Testing | ⏳ PENDING | 0% | Awaiting deployment |

### 2.2 Current Status

- **Active Stage**: Stage 1 (Requirements Validation)
- **Current Activity**: Gap analysis complete, 12 handlers to implement
- **Blockers**: None
- **Existing Repo**: `2_bbws_tenants_instances_lambda` (contains Instance Management + basic tenant create)

---

## 3. Technical Architecture

### 3.1 API Endpoints

| Method | Endpoint | Description | Lambda |
|--------|----------|-------------|--------|
| POST | `/v1.0/tenants` | Create tenant | tenant-create |
| GET | `/v1.0/tenants/{tenantId}` | Get tenant | tenant-get |
| PUT | `/v1.0/tenants/{tenantId}` | Update tenant | tenant-update |
| DELETE | `/v1.0/tenants/{tenantId}` | Soft delete tenant | tenant-delete |
| GET | `/v1.0/tenants` | List tenants | tenant-list |
| PATCH | `/v1.0/tenants/{tenantId}/status` | Update status | tenant-status |
| POST | `/v1.0/tenants/{tenantId}/park` | Park tenant | tenant-park |
| POST | `/v1.0/tenants/{tenantId}/unpark` | Unpark tenant | tenant-unpark |
| POST | `/v1.0/tenants/{tenantId}/users` | Assign user | user-assign |
| GET | `/v1.0/tenants/{tenantId}/users` | List users | user-list |
| DELETE | `/v1.0/tenants/{tenantId}/users/{userId}` | Remove user | user-remove |
| GET | `/v1.0/users/{userId}/tenants` | Get user's tenants | user-tenants |
| POST | `/v1.0/tenants/{tenantId}/hierarchy` | Create hierarchy | hierarchy-create |
| PUT | `/v1.0/tenants/{tenantId}/hierarchy` | Update hierarchy | hierarchy-update |
| DELETE | `/v1.0/tenants/{tenantId}/hierarchy` | Delete hierarchy | hierarchy-delete |

### 3.2 DynamoDB Schema Design

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        SINGLE TABLE DESIGN                               │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  PRIMARY KEY:  PK = "TENANT#{tenantId}"                                 │
│                SK = "METADATA" | "USER#{userId}" | "HIERARCHY"          │
│                                                                          │
│  GSI-1 (Status):  GSI1PK = "STATUS#{status}"                            │
│                   GSI1SK = "TENANT#{tenantId}"                          │
│                                                                          │
│  GSI-2 (User):    GSI2PK = "USER#{userId}"                              │
│                   GSI2SK = "TENANT#{tenantId}"                          │
│                                                                          │
│  GSI-3 (Org):     GSI3PK = "ORG#{orgName}"                              │
│                   GSI3SK = "TENANT#{tenantId}"                          │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 3.3 Tenant Status State Machine

```
                    ┌─────────────┐
                    │   PENDING   │
                    └──────┬──────┘
                           │ provision complete
                           ▼
                    ┌─────────────┐
        ┌──────────▶│   ACTIVE    │◀──────────┐
        │           └──────┬──────┘           │
        │                  │                  │
        │ unpark      suspend            reactivate
        │                  │                  │
        │           ┌──────▼──────┐           │
        │           │  SUSPENDED  │───────────┘
        │           └──────┬──────┘
        │                  │
        │             park │
        │                  ▼
   ┌────┴─────┐     ┌─────────────┐
   │  PARKED  │     │ deprovision │
   └──────────┘     └──────┬──────┘
                           │
                           ▼
                    ┌─────────────┐
                    │DEPROVISIONED│ (Terminal)
                    └─────────────┘
```

---

## 4. Stage Breakdown

### Stage 1: Requirements Validation (3 days)

**Objective**: Validate BRS 2.5 is complete and unambiguous

| Task | Owner | Output |
|------|-------|--------|
| Review BRS 2.5 completeness | BA | Validation checklist |
| Identify missing requirements | BA | Gap analysis |
| Stakeholder sign-off | PO | Approved BRS |

**Exit Criteria**: BRS 2.5 approved and frozen

---

### Stage 2: HLD Creation (3 days)

**Objective**: High-level architecture design

| Task | Owner | Output |
|------|-------|--------|
| System context diagram | Architect | HLD Section 2 |
| Component diagram | Architect | HLD Section 3 |
| Data flow diagrams | Architect | HLD Section 4 |
| Non-functional requirements | Architect | HLD Section 5 |

**Output**: `HLDs/2.5_HLD_Tenant_Management.md`

---

### Stage 3: LLD Creation (5 days)

**Objective**: Detailed technical design

| Task | Owner | Output |
|------|-------|--------|
| API contract design | Developer | LLD Section 3 |
| DynamoDB schema | Developer | LLD Section 4 |
| Lambda specifications | Developer | LLD Section 5 |
| Error handling design | Developer | LLD Section 6 |
| Security design | Developer | LLD Section 7 |

**Output**: `LLDs/2.5_LLD_Tenant_Management.md`

---

### Stage 4: OpenAPI Specification (2 days)

**Objective**: Complete API documentation

| Task | Owner | Output |
|------|-------|--------|
| Define all endpoints | Developer | OpenAPI paths |
| Define schemas | Developer | OpenAPI components |
| Add examples | Developer | Request/response examples |
| Validate spec | QA | Validated YAML |

**Output**: `project_plans/openapi-specs/tenant_management_v1.0.yaml`

---

### Stage 5: DynamoDB Schema (2 days)

**Objective**: Finalize database design

| Task | Owner | Output |
|------|-------|--------|
| Table definition | Developer | Table spec |
| GSI design | Developer | GSI definitions |
| Access patterns | Developer | Query patterns doc |
| Capacity planning | Developer | On-demand config |

**Output**: Terraform DynamoDB resource

---

### Stage 6: TDD Tests (5 days)

**Objective**: Write tests before implementation

| Task | Owner | Output |
|------|-------|--------|
| Unit test specs | SDET | Unit test files |
| Integration test specs | SDET | Integration test files |
| Mock data setup | SDET | Test fixtures |
| Test coverage config | SDET | pytest.ini |

**Output**: `/tests/` folder with all test cases (RED state)

---

### Stage 7: Lambda Implementation (10 days)

**Objective**: Implement all Lambda functions

| Lambda | Days | Priority |
|--------|------|----------|
| tenant-create | 1 | P0 |
| tenant-get | 0.5 | P0 |
| tenant-update | 1 | P0 |
| tenant-delete | 0.5 | P0 |
| tenant-list | 1 | P0 |
| tenant-status | 1 | P0 |
| tenant-park | 0.5 | P1 |
| tenant-unpark | 0.5 | P1 |
| user-assign | 1 | P0 |
| user-list | 0.5 | P0 |
| user-remove | 0.5 | P0 |
| user-tenants | 0.5 | P1 |
| hierarchy-create | 1 | P1 |
| hierarchy-update | 0.5 | P1 |
| hierarchy-delete | 0.5 | P1 |

**Output**: All Lambda functions passing tests (GREEN state)

---

### Stage 8: Terraform Infrastructure (3 days)

**Objective**: Infrastructure as Code

| Resource | Description |
|----------|-------------|
| DynamoDB Table | bbws-tenants-{env} |
| Lambda Functions | 15 functions |
| API Gateway | REST API with routes |
| IAM Roles | Lambda execution roles |
| CloudWatch | Log groups, alarms |

**Output**: `terraform/` folder with all resources

---

### Stage 9: DEV Deployment (2 days)

**Objective**: Deploy to DEV environment

| Task | Owner | Output |
|------|-------|--------|
| Terraform apply DEV | DevOps | Deployed resources |
| Smoke test | QA | Smoke test results |
| API Gateway URL | DevOps | https://dev.api.kimmyai.io/v1.0/tenants |

**Environment**: DEV (536580886816)

---

### Stage 10: Integration Testing (2 days)

**Objective**: Validate end-to-end functionality

| Test Type | Coverage |
|-----------|----------|
| Happy path tests | All endpoints |
| Error handling tests | All error codes |
| Performance tests | P95 < 200ms |
| Security tests | Auth, authz |

**Exit Criteria**: All tests passing, ready for Phase 1

---

## 5. Dependencies

### 5.1 Upstream Dependencies

| Dependency | Status | Owner |
|------------|--------|-------|
| AWS Account (DEV) | READY | DevOps |
| Cognito User Pool | READY | DevOps |
| VPC + Subnets | READY | DevOps |
| CI/CD Pipeline | READY | DevOps |

### 5.2 Downstream Dependents

| Dependent | Waiting For |
|-----------|-------------|
| BRS 2.6 Site Management API | Tenant API |
| BRS 2.7 Instance Management API | Tenant API |
| BRS 2.2 Customer Portal | Tenant API |
| BRS 2.3 Admin App | Tenant API |
| BRS 2.4 Admin Portal | Tenant API |

---

## 6. Risks & Mitigations

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| DynamoDB design issues | HIGH | MEDIUM | Early schema review |
| API contract changes | HIGH | LOW | Freeze spec after Stage 4 |
| Test coverage gaps | MEDIUM | MEDIUM | TDD approach |
| Integration delays | HIGH | LOW | Mock services for parallel dev |

---

## 7. Team Assignments

| Role | Name | Responsibility |
|------|------|----------------|
| Tech Lead | TBD | Architecture decisions |
| Backend Developer | TBD | Lambda implementation |
| SDET | TBD | Test development |
| DevOps | TBD | Infrastructure |
| BA | TBD | Requirements validation |

---

## 8. Repository Structure

```
2_bbws_tenant_management/
├── README.md
├── src/
│   └── handlers/
│       ├── tenant_create.py
│       ├── tenant_get.py
│       ├── tenant_update.py
│       ├── tenant_delete.py
│       ├── tenant_list.py
│       ├── tenant_status.py
│       ├── tenant_park.py
│       ├── tenant_unpark.py
│       ├── user_assign.py
│       ├── user_list.py
│       ├── user_remove.py
│       ├── user_tenants.py
│       ├── hierarchy_create.py
│       ├── hierarchy_update.py
│       └── hierarchy_delete.py
├── tests/
│   ├── unit/
│   └── integration/
├── terraform/
│   ├── main.tf
│   ├── dynamodb.tf
│   ├── lambda.tf
│   ├── api_gateway.tf
│   └── variables.tf
├── openapi/
│   └── tenant_management_v1.0.yaml
└── requirements.txt
```

---

## 9. Release Management

### Release Information

| Attribute | Value |
|-----------|-------|
| **Release #** | R1.0 |
| **Release Date** | _______________ |
| **UAT Signoff Date** | _______________ |
| **Business Owner** | _______________ |

### Deliverables Checklist

| # | Deliverable | Status | Sign-off |
|---|-------------|--------|----------|
| 1 | `HLDs/2.5_HLD_Tenant_Management.md` - Approved | ☐ | _______________ |
| 2 | `LLDs/2.5_LLD_Tenant_Management.md` - Approved | ☐ | _______________ |
| 3 | `2_bbws_tenant_management/` repository - Code complete | ☐ | _______________ |
| 4 | `openapi-specs/tenant_management_v1.0.yaml` - Finalized | ☐ | _______________ |
| 5 | Terraform modules - Deployed to DEV | ☐ | _______________ |
| 6 | CI/CD pipelines - Operational | ☐ | _______________ |
| 7 | Runbooks - Published | ☐ | _______________ |
| 8 | Unit tests - >80% coverage | ☐ | _______________ |
| 9 | Integration tests - All passing | ☐ | _______________ |
| 10 | API documentation - Published | ☐ | _______________ |

### Definition of Done

| # | Criteria | Status |
|---|----------|--------|
| 1 | All SDLC stages (1-10) completed | ☐ |
| 2 | All validation gates approved | ☐ |
| 3 | Code review completed and approved | ☐ |
| 4 | Security review passed | ☐ |
| 5 | Performance tests meet SLA (< 200ms P95 latency) | ☐ |
| 6 | DEV environment deployment successful | ☐ |
| 7 | SIT environment deployment successful | ☐ |
| 8 | UAT completed with sign-off | ☐ |
| 9 | PROD deployment approved | ☐ |
| 10 | Monitoring and alerting configured | ☐ |
| 11 | Rollback procedure documented and tested | ☐ |
| 12 | DynamoDB single-table design validated | ☐ |
| 13 | Tenant lifecycle state machine functional | ☐ |
| 14 | Organization hierarchy CRUD operational | ☐ |
| 15 | User assignment/removal working | ☐ |

### Environment Promotion

| Environment | Deployment Date | Verified By | Status |
|-------------|-----------------|-------------|--------|
| DEV (536580886816) | _______________ | _______________ | ☐ Pending |
| SIT (815856636111) | _______________ | _______________ | ☐ Pending |
| PROD (093646564004) | _______________ | _______________ | ☐ Pending |

---

## 10. Approval

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Product Owner | | | |
| Tech Lead | | | |
| DevOps Lead | | | |
| Business Owner | | | |

---

*Phase 0 is the CRITICAL PATH. All other phases depend on this completing successfully.*
