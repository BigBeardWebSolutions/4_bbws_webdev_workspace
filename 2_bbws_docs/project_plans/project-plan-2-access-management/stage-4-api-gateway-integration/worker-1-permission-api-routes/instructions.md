# Worker Instructions: Permission API Routes

**Worker ID**: worker-1-permission-api-routes
**Stage**: Stage 4 - API Gateway Integration
**Project**: project-plan-2-access-management

---

## Task

Configure API Gateway routes for the Permission Service (6 endpoints) with Lambda integrations, request validation, and CORS.

---

## Endpoints (6)

| # | Method | Path | Lambda | Auth |
|---|--------|------|--------|------|
| 1 | GET | /v1/permissions | list_permissions | Yes |
| 2 | GET | /v1/permissions/{permissionId} | get_permission | Yes |
| 3 | POST | /v1/permissions | create_permission | Yes |
| 4 | PUT | /v1/permissions/{permissionId} | update_permission | Yes |
| 5 | DELETE | /v1/permissions/{permissionId} | delete_permission | Yes |
| 6 | POST | /v1/permissions/seed | seed_permissions | Yes |

---

## Deliverables

Create `output.md` with:

### 1. OpenAPI Specification
Complete OpenAPI 3.0 spec for Permission Service endpoints.

### 2. Terraform Route Configuration
```hcl
# API Gateway resources, methods, integrations
```

### 3. Request/Response Models
JSON schemas for request validation.

### 4. CORS Configuration
OPTIONS method for all endpoints.

### 5. Integration Configuration
Lambda proxy integration settings.

---

## Success Criteria

- [ ] All 6 routes configured
- [ ] Lambda authorizer attached
- [ ] Request validation enabled
- [ ] CORS configured
- [ ] OpenAPI spec complete

---

**Status**: PENDING
**Created**: 2026-01-23
