# Worker Instructions: Role Service LLD Review

**Worker ID**: worker-4-role-service-review
**Stage**: Stage 1 - LLD Review & Analysis
**Project**: project-plan-2-access-management

---

## Task

Review the Role Service LLD (2.8.4) and extract implementation-ready specifications. This service manages platform roles (read-only) and organisation roles (customizable), plus user role assignments.

---

## Inputs

**Primary Input**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/2.8.4_LLD_Role_Service.md`

**Supporting Inputs**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/HLDs/2.8_HLD_Access_Management.md`

---

## Deliverables

Create `output.md` with the following sections:

### 1. Lambda Function Checklist (8 functions)

**Platform Role Operations (2)**:
| # | Function Name | Method | Endpoint |
|---|--------------|--------|----------|
| 1 | platform_role_list | GET | /platform/roles |
| 2 | platform_role_get | GET | /platform/roles/{roleId} |

**Organisation Role Operations (6)**:
| # | Function Name | Method | Endpoint |
|---|--------------|--------|----------|
| 3 | org_role_create | POST | /orgs/{orgId}/roles |
| 4 | org_role_list | GET | /orgs/{orgId}/roles |
| 5 | org_role_get | GET | /orgs/{orgId}/roles/{roleId} |
| 6 | org_role_update | PUT | /orgs/{orgId}/roles/{roleId} |
| 7 | org_role_delete | DELETE | /orgs/{orgId}/roles/{roleId} |
| 8 | org_role_seed | POST | /orgs/{orgId}/roles/seed |

### 2. API Contract Summary

Document all 8 endpoints with schemas.

### 3. DynamoDB Schema

**Entities**:
- PlatformRole (seeded, read-only)
- OrganisationRole (customizable)
- UserRoleAssignment

### 4. Role Types

**Platform Roles** (cannot be modified):
- SUPER_ADMIN
- PLATFORM_SUPPORT

**Default Organisation Roles** (seeded on org creation):
- ORG_ADMIN
- ORG_MANAGER
- SITE_ADMIN
- SITE_EDITOR
- SITE_VIEWER

### 5. Role Scope

| Scope | Description | Example |
|-------|-------------|---------|
| PLATFORM | System-wide | SUPER_ADMIN |
| ORGANISATION | Org-wide | ORG_ADMIN |
| TEAM | Team-specific | via team membership |

### 6. Permission Bundling

Document how roles bundle permissions:
- Role → [Permission1, Permission2, ...]
- Additive model (union of all role permissions)

### 7. Integration Points

- Permission Service (permission bundling)
- Team Service (team-level permissions)
- Authorizer (permission resolution)
- Audit Service (log changes)

### 8. Risk Assessment

- Privilege escalation risks
- Orphaned role assignments
- Circular dependencies

---

## Success Criteria

- [ ] All 8 Lambda functions documented
- [ ] Platform vs Org roles differentiated
- [ ] Role scopes documented
- [ ] Default org roles listed
- [ ] Permission bundling explained
- [ ] Integration points identified
- [ ] Risks assessed

---

## Execution Steps

1. Read LLD 2.8.4 completely
2. Extract platform role operations (2)
3. Extract org role operations (6)
4. Document DynamoDB schema
5. List platform roles
6. List default org roles
7. Explain permission bundling
8. Identify integration points
9. Assess risks
10. Create output.md
11. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-23
