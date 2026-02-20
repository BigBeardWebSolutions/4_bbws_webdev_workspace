# Worker Instructions: Team Service Lambdas

**Worker ID**: worker-3-team-service-lambdas
**Stage**: Stage 3 - Lambda Services Development
**Project**: project-plan-2-access-management

---

## Task

Implement 14 Lambda functions for the Team Service - the largest service handling teams, team members, and configurable team roles.

---

## Inputs

**From Stage 1**:
- `/stage-1-lld-review-analysis/worker-3-team-service-review/output.md`

**LLD Reference**:
- `/2_bbws_docs/LLDs/2.8.3_LLD_Team_Service.md`

---

## Lambda Functions (14)

### Team Operations (4)
| # | Function | Method | Endpoint |
|---|----------|--------|----------|
| 1 | create_team | POST | /v1/orgs/{orgId}/teams |
| 2 | list_teams | GET | /v1/orgs/{orgId}/teams |
| 3 | get_team | GET | /v1/orgs/{orgId}/teams/{teamId} |
| 4 | update_team | PUT | /v1/orgs/{orgId}/teams/{teamId} |

### Team Role Operations (5)
| # | Function | Method | Endpoint |
|---|----------|--------|----------|
| 5 | create_team_role | POST | /v1/orgs/{orgId}/team-roles |
| 6 | list_team_roles | GET | /v1/orgs/{orgId}/team-roles |
| 7 | get_team_role | GET | /v1/orgs/{orgId}/team-roles/{roleId} |
| 8 | update_team_role | PUT | /v1/orgs/{orgId}/team-roles/{roleId} |
| 9 | delete_team_role | DELETE | /v1/orgs/{orgId}/team-roles/{roleId} |

### Team Member Operations (5)
| # | Function | Method | Endpoint |
|---|----------|--------|----------|
| 10 | add_member | POST | /v1/orgs/{orgId}/teams/{teamId}/members |
| 11 | list_members | GET | /v1/orgs/{orgId}/teams/{teamId}/members |
| 12 | get_member | GET | /v1/orgs/{orgId}/teams/{teamId}/members/{userId} |
| 13 | update_member | PUT | /v1/orgs/{orgId}/teams/{teamId}/members/{userId} |
| 14 | get_user_teams | GET | /v1/orgs/{orgId}/users/{userId}/teams |

---

## Deliverables

### 1. Project Structure
```
lambda/team_service/
├── __init__.py
├── handlers/
│   ├── teams/
│   │   ├── create_handler.py
│   │   ├── list_handler.py
│   │   ├── get_handler.py
│   │   └── update_handler.py
│   ├── team_roles/
│   │   ├── create_handler.py
│   │   ├── list_handler.py
│   │   ├── get_handler.py
│   │   ├── update_handler.py
│   │   └── delete_handler.py
│   └── members/
│       ├── add_handler.py
│       ├── list_handler.py
│       ├── get_handler.py
│       ├── update_handler.py
│       └── user_teams_handler.py
├── models/
│   ├── team.py
│   ├── team_role.py
│   ├── team_member.py
│   └── requests.py
├── services/
│   ├── team_service.py
│   ├── team_role_service.py
│   └── member_service.py
├── repositories/
│   ├── team_repository.py
│   ├── team_role_repository.py
│   └── member_repository.py
└── tests/
```

### 2. Configurable Team Roles

```python
class TeamRoleCapability(str, Enum):
    CAN_MANAGE_MEMBERS = "CAN_MANAGE_MEMBERS"
    CAN_UPDATE_TEAM = "CAN_UPDATE_TEAM"
    CAN_VIEW_MEMBERS = "CAN_VIEW_MEMBERS"
    CAN_VIEW_SITES = "CAN_VIEW_SITES"
    CAN_EDIT_SITES = "CAN_EDIT_SITES"
    CAN_DELETE_SITES = "CAN_DELETE_SITES"
    CAN_VIEW_AUDIT = "CAN_VIEW_AUDIT"

class TeamRoleDefinition(BaseModel):
    id: str
    org_id: str
    name: str
    description: str
    capabilities: List[TeamRoleCapability]
    is_default: bool = False
    sort_order: int
    active: bool = True
```

### 3. Default Team Roles

```python
DEFAULT_TEAM_ROLES = [
    {
        "name": "TEAM_LEAD",
        "capabilities": [cap.value for cap in TeamRoleCapability],
        "sort_order": 1
    },
    {
        "name": "SENIOR_MEMBER",
        "capabilities": ["CAN_VIEW_MEMBERS", "CAN_VIEW_SITES", "CAN_EDIT_SITES"],
        "sort_order": 2
    },
    {
        "name": "MEMBER",
        "capabilities": ["CAN_VIEW_MEMBERS", "CAN_VIEW_SITES"],
        "sort_order": 3
    },
    {
        "name": "VIEWER",
        "capabilities": ["CAN_VIEW_MEMBERS"],
        "sort_order": 4
    }
]
```

### 4. Team Member Model

```python
class TeamMember(BaseModel):
    team_id: str
    user_id: str
    team_role_id: str
    joined_at: datetime
    # Denormalized user info for queries
    user_email: str
    user_name: str
```

---

## Success Criteria

- [ ] All 14 Lambda handlers implemented
- [ ] Team CRUD operations
- [ ] Configurable team roles with capabilities
- [ ] Default roles seeded on org creation
- [ ] Member management with role assignment
- [ ] User's teams query (GSI)
- [ ] Capability checking for actions
- [ ] Tests with moto
- [ ] > 80% code coverage

---

## Execution Steps

1. Read Stage 1 output for all 14 APIs
2. Create models (Team, TeamRoleDefinition, TeamMember)
3. Implement team handlers (TDD)
4. Implement team role handlers
5. Implement member handlers
6. Implement user_teams query
7. Add capability checking
8. Ensure all tests pass
9. Create output.md
10. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-23
