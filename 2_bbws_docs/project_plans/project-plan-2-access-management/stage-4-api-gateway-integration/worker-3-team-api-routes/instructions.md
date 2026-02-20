# Worker Instructions: Team API Routes

**Worker ID**: worker-3-team-api-routes
**Stage**: Stage 4 - API Gateway Integration
**Project**: project-plan-2-access-management

---

## Task

Configure API Gateway routes for the Team Service (14 endpoints) - the largest API surface.

---

## Endpoints (14)

### Team Operations (4)
| Method | Path | Lambda |
|--------|------|--------|
| POST | /v1/orgs/{orgId}/teams | create_team |
| GET | /v1/orgs/{orgId}/teams | list_teams |
| GET | /v1/orgs/{orgId}/teams/{teamId} | get_team |
| PUT | /v1/orgs/{orgId}/teams/{teamId} | update_team |

### Team Role Operations (5)
| Method | Path | Lambda |
|--------|------|--------|
| POST | /v1/orgs/{orgId}/team-roles | create_team_role |
| GET | /v1/orgs/{orgId}/team-roles | list_team_roles |
| GET | /v1/orgs/{orgId}/team-roles/{roleId} | get_team_role |
| PUT | /v1/orgs/{orgId}/team-roles/{roleId} | update_team_role |
| DELETE | /v1/orgs/{orgId}/team-roles/{roleId} | delete_team_role |

### Member Operations (5)
| Method | Path | Lambda |
|--------|------|--------|
| POST | /v1/orgs/{orgId}/teams/{teamId}/members | add_member |
| GET | /v1/orgs/{orgId}/teams/{teamId}/members | list_members |
| GET | /v1/orgs/{orgId}/teams/{teamId}/members/{userId} | get_member |
| PUT | /v1/orgs/{orgId}/teams/{teamId}/members/{userId} | update_member |
| GET | /v1/orgs/{orgId}/users/{userId}/teams | get_user_teams |

---

## Deliverables

Create `output.md` with:
1. OpenAPI 3.0 specification (all 14 endpoints)
2. Terraform route configuration
3. Request/response schemas
4. CORS configuration
5. Path parameter validation

---

## Success Criteria

- [ ] All 14 routes configured
- [ ] Lambda authorizer attached
- [ ] Nested paths handled correctly
- [ ] CORS enabled
- [ ] OpenAPI spec complete

---

**Status**: PENDING
**Created**: 2026-01-23
