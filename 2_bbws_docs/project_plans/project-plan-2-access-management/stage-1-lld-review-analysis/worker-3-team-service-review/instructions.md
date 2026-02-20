# Worker Instructions: Team Service LLD Review

**Worker ID**: worker-3-team-service-review
**Stage**: Stage 1 - LLD Review & Analysis
**Project**: project-plan-2-access-management

---

## Task

Review the Team Service LLD (2.8.3) and extract implementation-ready specifications. This is the largest service with 14 Lambda functions covering teams, team members, and configurable team roles.

---

## Inputs

**Primary Input**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/2.8.3_LLD_Team_Service.md`

**Supporting Inputs**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/HLDs/2.8_HLD_Access_Management.md`

---

## Deliverables

Create `output.md` with the following sections:

### 1. Lambda Function Checklist (14 functions)

**Team Operations (5)**:
| # | Function Name | Method | Endpoint |
|---|--------------|--------|----------|
| 1 | team_create | POST | /orgs/{orgId}/teams |
| 2 | team_list | GET | /orgs/{orgId}/teams |
| 3 | team_get | GET | /orgs/{orgId}/teams/{teamId} |
| 4 | team_update | PUT | /orgs/{orgId}/teams/{teamId} |
| 5 | team_delete | DELETE | /orgs/{orgId}/teams/{teamId} |

**Team Member Operations (4)**:
| # | Function Name | Method | Endpoint |
|---|--------------|--------|----------|
| 6 | team_member_add | POST | /orgs/{orgId}/teams/{teamId}/members |
| 7 | team_member_list | GET | /orgs/{orgId}/teams/{teamId}/members |
| 8 | team_member_remove | DELETE | /orgs/{orgId}/teams/{teamId}/members/{userId} |
| 9 | team_member_update_role | PUT | /orgs/{orgId}/teams/{teamId}/members/{userId}/role |

**Team Role Operations (5)**:
| # | Function Name | Method | Endpoint |
|---|--------------|--------|----------|
| 10 | team_role_create | POST | /orgs/{orgId}/team-roles |
| 11 | team_role_list | GET | /orgs/{orgId}/team-roles |
| 12 | team_role_get | GET | /orgs/{orgId}/team-roles/{teamRoleId} |
| 13 | team_role_update | PUT | /orgs/{orgId}/team-roles/{teamRoleId} |
| 14 | team_role_delete | DELETE | /orgs/{orgId}/team-roles/{teamRoleId} |

### 2. API Contract Summary

Document all 14 endpoints with full schemas.

### 3. DynamoDB Schema

**Entities**:
- Team
- TeamMembership
- TeamRoleDefinition

**Access Patterns**:
- Get team by ID
- List teams by org
- Get members by team
- Get user's teams
- Get team roles by org

### 4. Configurable Team Roles

Document the capability system:
- CAN_MANAGE_MEMBERS
- CAN_UPDATE_TEAM
- CAN_VIEW_MEMBERS
- CAN_VIEW_SITES
- CAN_EDIT_SITES
- CAN_DELETE_SITES
- CAN_VIEW_AUDIT

### 5. Default Team Roles

| Role Name | Capabilities |
|-----------|--------------|
| TEAM_LEAD | All capabilities |
| SENIOR_MEMBER | View + Edit |
| MEMBER | View only |
| VIEWER | View members only |

### 6. Integration Points

- Invitation Service (accepts add member)
- Role Service (org role assignment)
- Audit Service (log changes)
- Site Service (team-site association)

### 7. Risk Assessment

Document data isolation and permission escalation risks.

---

## Success Criteria

- [ ] All 14 Lambda functions documented
- [ ] All API endpoints specified
- [ ] DynamoDB schema complete
- [ ] Team role capabilities documented
- [ ] Default roles defined
- [ ] Integration points identified
- [ ] Risks assessed

---

## Execution Steps

1. Read LLD 2.8.3 completely
2. Extract all 14 Lambda specifications
3. Document team operations API (5 endpoints)
4. Document member operations API (4 endpoints)
5. Document team role operations API (5 endpoints)
6. Extract DynamoDB schema for all entities
7. Document configurable team role system
8. List default team roles
9. Identify integration points
10. Assess risks
11. Create output.md
12. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-23
