# Stage 2: Lambda Implementation - Customer Portal (REVISED)

**Stage ID**: stage-2-lambda-customer-portal
**Project**: project-plan-5-lld-implementation
**Status**: COMPLETE
**Workers**: 5 (reduced from 8 based on gap analysis)
**Completed**: 2026-01-25

---

## Revision Notes

**IMPORTANT**: This plan has been revised based on gap analysis of existing implementations.

### Existing Implementations Discovered

| Repository | LLDs Covered | Implementation Status |
|------------|--------------|----------------------|
| `2_bbws_tenants_instances_lambda` | LLD 2.5 + 2.7 | 77% complete (24/31 endpoints) |
| `2_bbws_wordpress_site_management_lambda` | LLD 2.6 | 65% complete |

### Workers Removed (Already Implemented)

| Original Worker | Reason for Removal |
|-----------------|-------------------|
| worker-1-tenant-handlers | ✅ Fully implemented in `2_bbws_tenants_instances_lambda` |
| worker-2-hierarchy-handlers | ✅ Fully implemented in `2_bbws_tenants_instances_lambda` |
| worker-3-user-handlers | ✅ Fully implemented in `2_bbws_tenants_instances_lambda` |
| worker-7-template-handlers | ✅ 100% complete in `2_bbws_wordpress_site_management_lambda` |

### Repository Consolidation

The original plan proposed creating `2_bbws_tenant_lambda` - this is **NOT NEEDED**. LLD 2.5 functionality is already implemented in `2_bbws_tenants_instances_lambda`.

---

## Stage Objective

Implement **MISSING** Lambda functions for the Customer Self-Service Portal by extending existing repositories, not creating new ones.

---

## Revised Stage Workers

| Worker | Task | Target Repo | Missing APIs |
|--------|------|-------------|--------------|
| worker-4-invitation-handlers | Invitation Handlers | `2_bbws_tenants_instances_lambda` | 5 endpoints (100% missing) |
| worker-5-site-operations | Site Operations Handlers | `2_bbws_wordpress_site_management_lambda` | clone, promote, health, status |
| worker-6-plugins-gaps | Plugin Missing Handlers | `2_bbws_wordpress_site_management_lambda` | detail, list-installed, update, toggle |
| worker-7-operations-api | Operations API Handlers | `2_bbws_wordpress_site_management_lambda` | 2 endpoints (100% missing) |
| worker-8-sqs-consumers | SQS Consumer Handlers | `2_bbws_wordpress_site_management_lambda` | 3 specific consumers |

---

## Gap Analysis Detail

### Worker 4: Invitation Handlers (LLD 2.5)

**Target Repository**: `2_bbws_tenants_instances_lambda`
**Status**: 0% implemented

| Endpoint | Method | Path | Handler Needed |
|----------|--------|------|----------------|
| List Invitations | GET | `/tenants/{id}/invitations` | `list_invitations_handler.py` |
| Create Invitation | POST | `/tenants/{id}/invitations` | `create_invitation_handler.py` |
| Get Invitation | GET | `/tenants/{id}/invitations/{invId}` | `get_invitation_handler.py` |
| Cancel Invitation | DELETE | `/tenants/{id}/invitations/{invId}` | `cancel_invitation_handler.py` |
| Resend Invitation | POST | `/tenants/{id}/invitations/{invId}/resend` | `resend_invitation_handler.py` |

**Additional Required**:
- `src/services/invitation_service.py` (NEW)
- `src/dao/invitation_dao.py` (NEW)
- `src/models/invitation.py` (NEW)

### Worker 5: Site Operations (LLD 2.6)

**Target Repository**: `2_bbws_wordpress_site_management_lambda`
**Status**: 4 endpoints missing

| Endpoint | Method | Path | Handler Needed |
|----------|--------|------|----------------|
| Clone Site | POST | `/sites/{id}/clone` | `clone_site_handler.py` |
| Promote Site | POST | `/sites/{id}/promote` | `promote_site_handler.py` |
| Get Health | GET | `/sites/{id}/health` | `get_site_health_handler.py` |
| Get Status | GET | `/sites/{id}/status` | `get_site_status_handler.py` |

### Worker 6: Plugin Gaps (LLD 2.6)

**Target Repository**: `2_bbws_wordpress_site_management_lambda`
**Status**: 4 endpoints missing

| Endpoint | Method | Path | Handler Needed |
|----------|--------|------|----------------|
| Get Plugin Detail | GET | `/plugins/{id}` | `get_plugin_handler.py` |
| List Installed | GET | `/sites/{id}/plugins` | `list_site_plugins_handler.py` |
| Update Plugin | PUT | `/sites/{id}/plugins/{pluginId}` | `update_plugin_handler.py` |
| Toggle Plugin | POST | `/sites/{id}/plugins/{pluginId}/toggle` | `toggle_plugin_handler.py` |

### Worker 7: Operations API (LLD 2.6)

**Target Repository**: `2_bbws_wordpress_site_management_lambda`
**Status**: 0% implemented (critical gap)

| Endpoint | Method | Path | Handler Needed |
|----------|--------|------|----------------|
| List Operations | GET | `/operations` | `list_operations_handler.py` |
| Get Operation | GET | `/operations/{id}` | `get_operation_handler.py` |

**Additional Required**:
- `src/services/operation_service.py` (NEW)
- `src/dao/operation_dao.py` (NEW)
- `src/models/operation.py` (NEW)

### Worker 8: SQS Consumers (LLD 2.6)

**Target Repository**: `2_bbws_wordpress_site_management_lambda`
**Status**: Generic processor exists, specific consumers missing

| Consumer | Queue | Handler Needed |
|----------|-------|----------------|
| Site Creator | `bbws-wp-site-creation-{env}` | `site_creation_consumer.py` |
| Site Updater | `bbws-wp-site-update-{env}` | `site_update_consumer.py` |
| Site Deleter | `bbws-wp-site-deletion-{env}` | `site_deletion_consumer.py` |

---

## Stage Inputs

| Input | Source |
|-------|--------|
| Stage 1 Analysis Outputs | Stage 1 workers |
| Gap Analysis Report | Gap analysis task |
| LLD 2.5 Tenant Management | `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/2.5_LLD_Tenant_Management.md` |
| LLD 2.6 WordPress Site Management | `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/2.6_LLD_WordPress_Site_Management.md` |
| Existing Tenant Lambda | `/Users/tebogotseka/Documents/agentic_work/2_bbws_tenants_instances_lambda/` |
| Existing Site Lambda | `/Users/tebogotseka/Documents/agentic_work/2_bbws_wordpress_site_management_lambda/` |

---

## Stage Outputs

### Worker 4 Outputs (Invitations - `2_bbws_tenants_instances_lambda`)
```
src/handlers/invitations/
├── list_invitations_handler.py
├── create_invitation_handler.py
├── get_invitation_handler.py
├── cancel_invitation_handler.py
└── resend_invitation_handler.py
src/services/invitation_service.py
src/dao/invitation_dao.py
src/models/invitation.py
tests/unit/handlers/invitations/
tests/unit/services/test_invitation_service.py
```

### Worker 5 Outputs (Site Operations - `2_bbws_wordpress_site_management_lambda`)
```
sites-service/src/handlers/
├── clone_site_handler.py
├── promote_site_handler.py
├── get_site_health_handler.py
└── get_site_status_handler.py
sites-service/tests/unit/handlers/
```

### Worker 6 Outputs (Plugin Gaps - `2_bbws_wordpress_site_management_lambda`)
```
plugins-service/src/handlers/
├── get_plugin_handler.py
├── list_site_plugins_handler.py
├── update_plugin_handler.py
└── toggle_plugin_handler.py
plugins-service/tests/unit/handlers/
```

### Worker 7 Outputs (Operations API - `2_bbws_wordpress_site_management_lambda`)
```
operations-service/
├── src/
│   ├── handlers/
│   │   ├── list_operations_handler.py
│   │   └── get_operation_handler.py
│   ├── services/operation_service.py
│   ├── dao/operation_dao.py
│   └── models/operation.py
└── tests/
```

### Worker 8 Outputs (SQS Consumers - `2_bbws_wordpress_site_management_lambda`)
```
sqs-consumers/
├── src/
│   ├── site_creation_consumer.py
│   ├── site_update_consumer.py
│   └── site_deletion_consumer.py
└── tests/
```

---

## Success Criteria

- [x] All 5 workers completed
- [x] Invitation API fully functional (5 endpoints)
- [x] Site operations completed (clone, promote, health, status)
- [x] Plugin gaps filled (detail, list-installed, update, toggle)
- [x] Operations API implemented (2 endpoints)
- [x] SQS consumers implemented (3 consumers)
- [x] All unit tests passing (80%+ coverage)
- [x] All handlers follow existing code patterns in target repos
- [x] All responses follow HATEOAS format
- [x] Stage summary created

---

## Dependencies

**Depends On**: Stage 1 (Analysis & API Mapping)

**Blocks**: Stage 3 (Lambda Implementation - Admin Portal)

---

## Gate 2 Approval

**Approvers**: Tech Lead, Developer Lead

**Criteria**:
- All gap Lambdas functional
- Unit tests pass with 80%+ coverage
- Code follows existing patterns in target repos
- API responses match LLD specifications

---

**Created**: 2026-01-24
**Revised**: 2026-01-24 (Gap analysis revision)
