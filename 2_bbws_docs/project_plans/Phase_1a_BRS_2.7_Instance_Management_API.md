# Phase 1a: BRS 2.7 - WordPress Instance Management API
## Project Plan

**Document ID**: PP-PHASE-1A-2.7
**Version**: 1.0
**Created**: 2026-01-16
**Status**: Draft
**Priority**: P0 - CRITICAL

---

## PROJECT STATUS

| Metric | Value |
|--------|-------|
| **Overall Status** | NOT STARTED |
| **Phase** | Phase 1a (Core APIs) |
| **Progress** | 0% |
| **Target Duration** | 6 weeks |
| **Dependencies** | Phase 0 (BRS 2.5 Tenant API) |

---

## 1. Project Overview

### 1.1 Objective

Build the **WordPress Instance Management API** - the microservice that provisions, manages, and retires dedicated WordPress environments for each customer organization. This transforms manual 2+ hour provisioning into automated 15-minute onboarding.

### 1.2 Business Value

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| Onboarding Time | 2+ hours | < 15 minutes | 87.5% reduction |
| Staff Time/Customer | 4 hours | 0 hours | 100% reduction |
| Configuration Errors | 15% | < 1% | 93% reduction |
| Customer Wait Time | 1-3 days | Minutes | 99% reduction |

### 1.3 Key Deliverables

| Deliverable | Description | Priority |
|-------------|-------------|----------|
| Onboarding API | Provision WordPress environment | P0 |
| Lifecycle API | Suspend, Resume, Scale | P0 |
| Offboarding API | Clean customer removal | P0 |
| Authentication Setup | Cognito tenant pool creation | P0 |
| ECS Service Management | Task definitions, services | P0 |
| EFS Access Points | wp-content isolation | P0 |
| RDS Schema Creation | Database provisioning | P0 |

### 1.4 Success Criteria

| Metric | Target |
|--------|--------|
| Onboarding Time | < 15 minutes |
| Zero-Touch Setup | 100% automated |
| Configuration Consistency | 100% identical |
| Offboarding Completeness | 0 orphaned resources |

---

## 2. Project Tracking

### 2.1 Stage Progress

| Stage | Status | Progress | Deliverable |
|-------|--------|----------|-------------|
| Stage 1: Requirements Validation | ⏳ PENDING | 0% | Validated BRS 2.7 |
| Stage 2: HLD Creation | ⏳ PENDING | 0% | 2.7_HLD_Instance_Management.md |
| Stage 3: LLD Creation | ⏳ PENDING | 0% | 2.7_LLD_Instance_Management.md |
| Stage 4: OpenAPI Spec | ⏳ PENDING | 0% | openapi_instance_management.yaml |
| Stage 5: ECS/EFS/RDS Design | ⏳ PENDING | 0% | Infrastructure design |
| Stage 6: TDD Tests | ⏳ PENDING | 0% | Unit + Integration tests |
| Stage 7: Lambda Implementation | ⏳ PENDING | 0% | 12 Lambda functions |
| Stage 8: Step Functions | ⏳ PENDING | 0% | Orchestration workflows |
| Stage 9: Terraform IaC | ⏳ PENDING | 0% | Infrastructure as Code |
| Stage 10: DEV Deployment | ⏳ PENDING | 0% | Deployed to DEV |
| Stage 11: Integration Testing | ⏳ PENDING | 0% | All tests passing |

---

## 3. Technical Architecture

### 3.1 API Endpoints

| Method | Endpoint | Description | Lambda |
|--------|----------|-------------|--------|
| POST | `/v1.0/instances` | Provision instance | instance-provision |
| GET | `/v1.0/instances/{instanceId}` | Get instance | instance-get |
| GET | `/v1.0/instances` | List instances | instance-list |
| DELETE | `/v1.0/instances/{instanceId}` | Deprovision | instance-deprovision |
| POST | `/v1.0/instances/{instanceId}/suspend` | Suspend | instance-suspend |
| POST | `/v1.0/instances/{instanceId}/resume` | Resume | instance-resume |
| POST | `/v1.0/instances/{instanceId}/scale` | Scale | instance-scale |
| POST | `/v1.0/instances/{instanceId}/update` | Update WP | instance-update |
| GET | `/v1.0/instances/{instanceId}/status` | Get status | instance-status |
| POST | `/v1.0/instances/{instanceId}/backup` | Trigger backup | instance-backup |
| POST | `/v1.0/instances/{instanceId}/restore` | Restore | instance-restore |
| GET | `/v1.0/instances/{instanceId}/logs` | View logs | instance-logs |

### 3.2 Provisioning Workflow (Step Functions)

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     INSTANCE PROVISIONING WORKFLOW                       │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   START                                                                  │
│     │                                                                    │
│     ▼                                                                    │
│   ┌─────────────────┐                                                   │
│   │ Validate Tenant │ ← Check tenant exists in 2.5 API                  │
│   └────────┬────────┘                                                   │
│            │                                                             │
│            ▼                                                             │
│   ┌─────────────────┐                                                   │
│   │ Create Cognito  │ ← Tenant-specific user pool                       │
│   │   User Pool     │                                                   │
│   └────────┬────────┘                                                   │
│            │                                                             │
│     ┌──────┴──────┐ (Parallel)                                          │
│     ▼             ▼                                                      │
│   ┌───────┐   ┌───────┐                                                 │
│   │Create │   │Create │                                                 │
│   │ EFS   │   │ RDS   │                                                 │
│   │Access │   │Schema │                                                 │
│   │ Point │   │       │                                                 │
│   └───┬───┘   └───┬───┘                                                 │
│       └─────┬─────┘                                                      │
│             ▼                                                            │
│   ┌─────────────────┐                                                   │
│   │ Create ECS Task │                                                   │
│   │   Definition    │                                                   │
│   └────────┬────────┘                                                   │
│            │                                                             │
│            ▼                                                             │
│   ┌─────────────────┐                                                   │
│   │ Create ECS      │                                                   │
│   │   Service       │                                                   │
│   └────────┬────────┘                                                   │
│            │                                                             │
│            ▼                                                             │
│   ┌─────────────────┐                                                   │
│   │ Configure ALB   │                                                   │
│   │  Target Group   │                                                   │
│   └────────┬────────┘                                                   │
│            │                                                             │
│            ▼                                                             │
│   ┌─────────────────┐                                                   │
│   │ Health Check    │ ← Wait for WordPress to respond                   │
│   └────────┬────────┘                                                   │
│            │                                                             │
│            ▼                                                             │
│   ┌─────────────────┐                                                   │
│   │ Update Tenant   │ ← Call 2.5 API to set ACTIVE                      │
│   │   Status        │                                                   │
│   └────────┬────────┘                                                   │
│            │                                                             │
│            ▼                                                             │
│          END                                                             │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 3.3 Resource Naming Convention

| Resource | Pattern | Example |
|----------|---------|---------|
| ECS Service | `wp-{tenantId}-{env}` | `wp-tenant123-dev` |
| EFS Access Point | `efs-ap-{tenantId}` | `efs-ap-tenant123` |
| RDS Schema | `wp_{tenantId}` | `wp_tenant123` |
| Cognito Pool | `bbws-{tenantId}-users` | `bbws-tenant123-users` |
| ALB Target Group | `tg-{tenantId}-{env}` | `tg-tenant123-dev` |

---

## 4. Stage Breakdown

### Stage 1: Requirements Validation (2 days)
- Validate BRS 2.7 completeness
- Identify missing requirements
- Stakeholder sign-off

### Stage 2: HLD Creation (3 days)
- System context diagram
- Provisioning workflow design
- Cross-account architecture
- Non-functional requirements

### Stage 3: LLD Creation (5 days)
- API contract design
- Step Functions state machine
- ECS task definition specs
- Error handling and rollback

### Stage 4: OpenAPI Specification (2 days)
- Define all endpoints
- Define schemas
- Add examples
- Validate spec

### Stage 5: ECS/EFS/RDS Design (3 days)
- ECS Fargate task specs
- EFS access point isolation
- RDS shared database model
- CloudWatch integration

### Stage 6: TDD Tests (4 days)
- Unit tests for Lambdas
- Integration tests for workflows
- Mock AWS services
- Performance tests

### Stage 7: Lambda Implementation (8 days)
- All 12 Lambda functions
- Step Functions integration
- Error handling
- Logging and monitoring

### Stage 8: Step Functions (3 days)
- Provisioning workflow
- Deprovisioning workflow
- Suspend/Resume workflows
- Error states and retries

### Stage 9: Terraform Infrastructure (3 days)
- Lambda functions
- Step Functions
- IAM roles
- CloudWatch alarms

### Stage 10: DEV Deployment (2 days)
- Terraform apply DEV
- Smoke testing
- Integration with 2.5 API

### Stage 11: Integration Testing (3 days)
- End-to-end provisioning test
- Lifecycle tests
- Cross-account tests

---

## 5. Dependencies

### 5.1 Upstream Dependencies

| Dependency | Status | Owner |
|------------|--------|-------|
| BRS 2.5 Tenant API | REQUIRED | Phase 0 |
| ECS Cluster (shared) | READY | DevOps |
| EFS File System | READY | DevOps |
| RDS MySQL (shared) | READY | DevOps |
| ALB (shared) | READY | DevOps |

### 5.2 Downstream Dependents

| Dependent | Waiting For |
|-----------|-------------|
| BRS 2.3 Admin App | Instance API |
| BRS 2.6 Site Management | Instance infrastructure |

---

## 6. Cross-Account Access

| Source Account | Target Account | Method |
|----------------|----------------|--------|
| PROD (093646564004) | DEV (536580886816) | AssumeRole |
| PROD (093646564004) | SIT (815856636111) | AssumeRole |

---

## 7. Repository Structure

```
2_bbws_instance_management/
├── README.md
├── src/
│   └── handlers/
│       ├── instance_provision.py
│       ├── instance_get.py
│       ├── instance_list.py
│       ├── instance_deprovision.py
│       ├── instance_suspend.py
│       ├── instance_resume.py
│       ├── instance_scale.py
│       ├── instance_update.py
│       ├── instance_status.py
│       ├── instance_backup.py
│       ├── instance_restore.py
│       └── instance_logs.py
├── step_functions/
│   ├── provision_workflow.asl.json
│   ├── deprovision_workflow.asl.json
│   └── suspend_resume_workflow.asl.json
├── tests/
│   ├── unit/
│   └── integration/
├── terraform/
│   ├── main.tf
│   ├── lambda.tf
│   ├── step_functions.tf
│   └── variables.tf
├── openapi/
│   └── instance_management_v1.0.yaml
└── requirements.txt
```

---

## 8. Release Management

### Release Information

| Attribute | Value |
|-----------|-------|
| **Release #** | R1.1 |
| **Release Date** | _______________ |
| **UAT Signoff Date** | _______________ |
| **Business Owner** | _______________ |

### Deliverables Checklist

| # | Deliverable | Status | Sign-off |
|---|-------------|--------|----------|
| 1 | `HLDs/2.7_HLD_Instance_Management.md` - Approved | ☐ | _______________ |
| 2 | `LLDs/2.7_LLD_Instance_Management.md` - Approved | ☐ | _______________ |
| 3 | `2_bbws_instance_management/` repository - Code complete | ☐ | _______________ |
| 4 | `openapi-specs/instance_management_v1.0.yaml` - Finalized | ☐ | _______________ |
| 5 | Step Functions workflows - Deployed | ☐ | _______________ |
| 6 | ECS/EFS/RDS provisioning automation - Functional | ☐ | _______________ |
| 7 | Terraform modules - Deployed to DEV | ☐ | _______________ |
| 8 | CI/CD pipelines - Operational | ☐ | _______________ |
| 9 | Unit tests - >80% coverage | ☐ | _______________ |
| 10 | Integration tests - All passing | ☐ | _______________ |

### Definition of Done

| # | Criteria | Status |
|---|----------|--------|
| 1 | All SDLC stages (1-11) completed | ☐ |
| 2 | All validation gates approved | ☐ |
| 3 | Code review completed and approved | ☐ |
| 4 | Security review passed | ☐ |
| 5 | Tenant provisioning < 15 minutes (automated) | ☐ |
| 6 | Cross-account AssumeRole working (DEV/SIT/PROD) | ☐ |
| 7 | Health checks operational | ☐ |
| 8 | DEV environment deployment successful | ☐ |
| 9 | SIT environment deployment successful | ☐ |
| 10 | UAT completed with sign-off | ☐ |
| 11 | PROD deployment approved | ☐ |
| 12 | Monitoring dashboards configured | ☐ |
| 13 | Step Functions workflows tested end-to-end | ☐ |
| 14 | Rollback/cleanup on failure working | ☐ |
| 15 | ECS service auto-scaling configured | ☐ |

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

*Phase 1a runs in parallel with Phase 1b after Phase 0 completes.*
