# Worker Instructions: Audit API Routes

**Worker ID**: worker-5-audit-api-routes
**Stage**: Stage 4 - API Gateway Integration
**Project**: project-plan-2-access-management

---

## Task

Configure API Gateway routes for the Audit Service (5 endpoints) for audit querying and export.

---

## Endpoints (5)

| # | Method | Path | Lambda |
|---|--------|------|--------|
| 1 | GET | /v1/orgs/{orgId}/audit | query_org_audit |
| 2 | GET | /v1/orgs/{orgId}/audit/users/{userId} | query_user_audit |
| 3 | GET | /v1/orgs/{orgId}/audit/resources/{type}/{resourceId} | query_resource_audit |
| 4 | GET | /v1/orgs/{orgId}/audit/summary | get_audit_summary |
| 5 | POST | /v1/orgs/{orgId}/audit/export | export_audit |

Note: Archive handler is scheduled (EventBridge), not API Gateway.

---

## Deliverables

Create `output.md` with:
1. OpenAPI 3.0 specification
2. Terraform route configuration
3. Query parameter schemas (dateFrom, dateTo, eventType, etc.)
4. Request/response schemas
5. CORS configuration

---

## Success Criteria

- [ ] All 5 routes configured
- [ ] Query parameters documented
- [ ] Lambda authorizer attached
- [ ] CORS enabled
- [ ] OpenAPI spec complete

---

**Status**: PENDING
**Created**: 2026-01-23
