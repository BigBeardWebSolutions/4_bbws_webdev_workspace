# Phase 1a: BRS 2.7 Instance Management API - Gap Analysis

**Date**: 2026-01-18
**Status**: Phase 1a Stage 1 COMPLETE
**Repository**: `2_bbws_tenants_instances_lambda`

---

## 1. Executive Summary

The existing implementation has **~70% of API layer complete** but **0% of infrastructure provisioning automation**. The current handlers perform CRUD operations but rely on GitOps/Terraform for actual AWS resource creation.

**Focus for Phase 1a**: Complete the missing API endpoints and enhance existing handlers.

---

## 2. Current Implementation Status

### Existing Instance Handlers (8 handlers)
| Handler | Endpoint | Status |
|---------|----------|--------|
| `create_instance.py` | POST /tenants/{tenantId}/instances | ✅ IMPLEMENTED |
| `get_instance.py` | GET /tenants/{tenantId}/instances/{instanceId} | ✅ IMPLEMENTED |
| `list_instances.py` | GET /tenants/{tenantId}/instances | ✅ IMPLEMENTED |
| `update_instance.py` | PUT /tenants/{tenantId}/instances/{instanceId} | ✅ IMPLEMENTED |
| `delete_instance.py` | DELETE /tenants/{tenantId}/instances/{instanceId} | ✅ IMPLEMENTED |
| `get_status.py` | GET /tenants/{tenantId}/instances/{instanceId}/status | ✅ IMPLEMENTED |
| `update_status.py` | POST /tenants/{tenantId}/instances/{instanceId}/status | ✅ IMPLEMENTED |
| `scale_instance.py` | POST /tenants/{tenantId}/instances/{instanceId}/scale | ✅ IMPLEMENTED |

### Existing Test Coverage
- ✅ test_create_instance.py (9 tests)
- ✅ test_get_instance.py
- ✅ test_list_instances.py
- ✅ test_update_instance.py
- ✅ test_delete_instance.py
- ✅ test_get_status.py
- ✅ test_update_status.py
- ✅ test_scale_instance.py

---

## 3. Missing Endpoints (Phase 1a Requirements)

### API Gaps (ALL RESOLVED)
| Endpoint | Method | BRS Requirement | Status | Priority |
|----------|--------|-----------------|--------|----------|
| `/tenants/{tenantId}/instances/{instanceId}/suspend` | POST | Suspend instance | ✅ IMPLEMENTED | P0 |
| `/tenants/{tenantId}/instances/{instanceId}/resume` | POST | Resume instance | ✅ IMPLEMENTED | P0 |
| `/tenants/{tenantId}/instances/{instanceId}/backup` | POST | Create backup | ✅ IMPLEMENTED | P1 |
| `/tenants/{tenantId}/instances/{instanceId}/restore` | POST | Restore from backup | ✅ IMPLEMENTED | P1 |
| `/tenants/{tenantId}/instances/{instanceId}/logs` | GET | Get instance logs | ✅ IMPLEMENTED | P1 |

---

## 4. Implementation Plan

### Stage 1: Missing API Endpoints (Current Focus)

#### 4.1 instance_suspend.py - POST /tenants/{tenantId}/instances/{instanceId}/suspend
**Purpose**: Suspend a running WordPress instance (stop ECS tasks, preserve data)

**Business Rules**:
- Instance must be ACTIVE to suspend
- Cannot suspend TERMINATED/DEPROVISIONED instances
- Sets status to SUSPENDED
- Stops ECS service (desired count = 0)
- Preserves EFS data and RDS database

**Response**: 200 OK with HATEOAS links

#### 4.2 instance_resume.py - POST /tenants/{tenantId}/instances/{instanceId}/resume
**Purpose**: Resume a suspended WordPress instance

**Business Rules**:
- Instance must be SUSPENDED to resume
- Cannot resume ACTIVE/TERMINATED instances
- Sets status to RESUMING, then ACTIVE
- Starts ECS service (desired count = previous value)
- Waits for health check to pass

**Response**: 200 OK with HATEOAS links

#### 4.3 instance_backup.py - POST /tenants/{tenantId}/instances/{instanceId}/backup
**Purpose**: Create a backup of instance (EFS snapshot + RDS snapshot)

**Business Rules**:
- Instance must exist (any status except DEPROVISIONED)
- Creates EFS backup via AWS Backup
- Creates RDS snapshot
- Returns backup ID for tracking

**Response**: 202 Accepted (async operation)

#### 4.4 instance_restore.py - POST /tenants/{tenantId}/instances/{instanceId}/restore
**Purpose**: Restore instance from a backup

**Request Body**: `{ "backupId": "backup-xxx" }`

**Business Rules**:
- Instance must exist
- Backup must exist and belong to this instance
- Suspends instance during restore
- Restores EFS from backup
- Restores RDS from snapshot
- Resumes instance after restore

**Response**: 202 Accepted (async operation)

#### 4.5 instance_logs.py - GET /tenants/{tenantId}/instances/{instanceId}/logs
**Purpose**: Retrieve CloudWatch logs for instance

**Query Parameters**:
- `startTime`: ISO timestamp (optional)
- `endTime`: ISO timestamp (optional)
- `limit`: Max log entries (default 100, max 1000)
- `nextToken`: Pagination token

**Business Rules**:
- Instance must exist
- Retrieves logs from CloudWatch log group
- Supports pagination

**Response**: 200 OK with log entries and pagination

---

## 5. Handlers Needed (5 new handlers)

| # | Handler | Endpoint | Priority |
|---|---------|----------|----------|
| 1 | instance_suspend.py | POST /tenants/{tenantId}/instances/{instanceId}/suspend | P0 |
| 2 | instance_resume.py | POST /tenants/{tenantId}/instances/{instanceId}/resume | P0 |
| 3 | instance_backup.py | POST /tenants/{tenantId}/instances/{instanceId}/backup | P1 |
| 4 | instance_restore.py | POST /tenants/{tenantId}/instances/{instanceId}/restore | P1 |
| 5 | instance_logs.py | GET /tenants/{tenantId}/instances/{instanceId}/logs | P1 |

---

## 6. Test Files Needed

| Test File | Handler | Tests |
|-----------|---------|-------|
| test_instance_suspend.py | instance_suspend.py | ~12 tests |
| test_instance_resume.py | instance_resume.py | ~12 tests |
| test_instance_backup.py | instance_backup.py | ~10 tests |
| test_instance_restore.py | instance_restore.py | ~10 tests |
| test_instance_logs.py | instance_logs.py | ~8 tests |

---

## 7. Dependencies

### Existing Utilities to Leverage
- `src/utils/response_builder.py` - HATEOAS responses
- `src/utils/logger.py` - Structured logging
- `src/utils/tenant_id.py` - ID validation
- `src/helpers/ecs_helper.py` - ECS operations
- `src/utils/operation_state.py` - Async operation tracking

### New AWS Services Required
- AWS Backup (for EFS backups)
- CloudWatch Logs (for log retrieval)
- RDS (for snapshot operations)

---

## 8. Implementation Progress

1. ✅ Create gap_analysis.md (this document)
2. ✅ Implement instance_suspend.py with TDD (11 tests)
3. ✅ Implement instance_resume.py with TDD (10 tests)
4. ✅ Implement instance_backup.py with TDD (11 tests)
5. ✅ Implement instance_restore.py with TDD (11 tests)
6. ✅ Implement instance_logs.py with TDD (10 tests)
7. ✅ Update api_router.py with new routes
8. ✅ Run tests and verify all pass (461 total unit tests)
9. ⏳ Deploy to DEV and test

---

## 9. Test Summary

| Test File | Handler | Tests | Status |
|-----------|---------|-------|--------|
| test_instance_suspend.py | instance_suspend.py | 11 tests | ✅ PASS |
| test_instance_resume.py | instance_resume.py | 10 tests | ✅ PASS |
| test_instance_backup.py | instance_backup.py | 11 tests | ✅ PASS |
| test_instance_restore.py | instance_restore.py | 11 tests | ✅ PASS |
| test_instance_logs.py | instance_logs.py | 10 tests | ✅ PASS |

**Total New Tests**: 53 tests
**Total Unit Tests**: 461 tests (all passing)

---

*Phase 1a Stage 1 complete. Ready for CI/CD pipeline and DEV deployment.*
