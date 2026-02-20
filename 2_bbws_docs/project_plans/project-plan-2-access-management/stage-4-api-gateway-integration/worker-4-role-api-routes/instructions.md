# Worker Instructions: Role API Routes

**Worker ID**: worker-4-role-api-routes
**Stage**: Stage 4 - API Gateway Integration
**Project**: project-plan-2-access-management

---

## Task

Configure API Gateway routes for the Role Service (8 endpoints) including platform and organisation roles.

---

## Endpoints (8)

### Platform Roles (2 - Read Only)
| Method | Path | Lambda |
|--------|------|--------|
| GET | /v1/platform/roles | list_platform_roles |
| GET | /v1/platform/roles/{roleId} | get_platform_role |

### Organisation Roles (6)
| Method | Path | Lambda |
|--------|------|--------|
| POST | /v1/orgs/{orgId}/roles | create_org_role |
| GET | /v1/orgs/{orgId}/roles | list_org_roles |
| GET | /v1/orgs/{orgId}/roles/{roleId} | get_org_role |
| PUT | /v1/orgs/{orgId}/roles/{roleId} | update_org_role |
| DELETE | /v1/orgs/{orgId}/roles/{roleId} | delete_org_role |
| POST | /v1/orgs/{orgId}/roles/seed | seed_org_roles |

---

## Deliverables

Create `output.md` with:
1. OpenAPI 3.0 specification
2. Terraform route configuration
3. Request/response schemas
4. CORS configuration

---

## Success Criteria

- [ ] All 8 routes configured
- [ ] Platform routes under /v1/platform
- [ ] Org routes under /v1/orgs/{orgId}
- [ ] Lambda authorizer attached
- [ ] OpenAPI spec complete

---

**Status**: PENDING
**Created**: 2026-01-23
