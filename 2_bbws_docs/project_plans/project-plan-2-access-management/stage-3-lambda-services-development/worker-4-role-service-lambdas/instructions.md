# Worker Instructions: Role Service Lambdas

**Worker ID**: worker-4-role-service-lambdas
**Stage**: Stage 3 - Lambda Services Development
**Project**: project-plan-2-access-management

---

## Task

Implement 8 Lambda functions for the Role Service handling platform roles (read-only) and organisation roles (customizable), plus user role assignment.

---

## Inputs

**From Stage 1**:
- `/stage-1-lld-review-analysis/worker-4-role-service-review/output.md`

**LLD Reference**:
- `/2_bbws_docs/LLDs/2.8.4_LLD_Role_Service.md`

---

## Lambda Functions (8)

### Platform Role Operations (2 - Read Only)
| # | Function | Method | Endpoint |
|---|----------|--------|----------|
| 1 | list_platform_roles | GET | /v1/platform/roles |
| 2 | get_platform_role | GET | /v1/platform/roles/{roleId} |

### Organisation Role Operations (6)
| # | Function | Method | Endpoint |
|---|----------|--------|----------|
| 3 | create_org_role | POST | /v1/orgs/{orgId}/roles |
| 4 | list_org_roles | GET | /v1/orgs/{orgId}/roles |
| 5 | get_org_role | GET | /v1/orgs/{orgId}/roles/{roleId} |
| 6 | update_org_role | PUT | /v1/orgs/{orgId}/roles/{roleId} |
| 7 | delete_org_role | DELETE | /v1/orgs/{orgId}/roles/{roleId} |
| 8 | seed_org_roles | POST | /v1/orgs/{orgId}/roles/seed |

---

## Deliverables

### 1. Project Structure
```
lambda/role_service/
├── __init__.py
├── handlers/
│   ├── platform/
│   │   ├── list_handler.py
│   │   └── get_handler.py
│   └── organisation/
│       ├── create_handler.py
│       ├── list_handler.py
│       ├── get_handler.py
│       ├── update_handler.py
│       ├── delete_handler.py
│       └── seed_handler.py
├── models/
│   ├── role.py
│   ├── user_role_assignment.py
│   └── requests.py
├── services/
│   ├── platform_role_service.py
│   └── org_role_service.py
├── repositories/
│   └── role_repository.py
└── tests/
```

### 2. Role Models

```python
class RoleScope(str, Enum):
    PLATFORM = "PLATFORM"
    ORGANISATION = "ORGANISATION"
    TEAM = "TEAM"

class Role(BaseModel):
    id: str
    name: str
    description: str
    scope: RoleScope
    permissions: List[str]  # Permission IDs
    is_system: bool = False
    active: bool = True
    created_at: datetime
    updated_at: datetime

class PlatformRole(Role):
    """System-defined, read-only roles."""
    scope: RoleScope = RoleScope.PLATFORM
    is_system: bool = True

class OrganisationRole(Role):
    """Customizable per-organisation roles."""
    org_id: str
    scope: RoleScope = RoleScope.ORGANISATION
```

### 3. Platform Roles (Seeded)

```python
PLATFORM_ROLES = [
    {
        "id": "PLATFORM_ADMIN",
        "name": "Platform Administrator",
        "description": "Full platform access",
        "permissions": ["*:*"],
        "is_system": True
    },
    {
        "id": "SUPPORT_AGENT",
        "name": "Support Agent",
        "description": "Read access for support",
        "permissions": ["*:READ"],
        "is_system": True
    },
    {
        "id": "BILLING_ADMIN",
        "name": "Billing Administrator",
        "description": "Billing management",
        "permissions": ["BILLING:*"],
        "is_system": True
    }
]
```

### 4. Default Organisation Roles

```python
DEFAULT_ORG_ROLES = [
    {
        "name": "ORG_ADMIN",
        "description": "Organisation administrator",
        "permissions": ["ORGANISATION:*", "TEAM:*", "SITE:*", "USER:*"]
    },
    {
        "name": "ORG_MANAGER",
        "description": "Organisation manager",
        "permissions": ["TEAM:READ", "TEAM:WRITE", "SITE:READ", "USER:READ"]
    },
    {
        "name": "SITE_ADMIN",
        "description": "Site administrator",
        "permissions": ["SITE:*"]
    },
    {
        "name": "SITE_EDITOR",
        "description": "Site editor",
        "permissions": ["SITE:READ", "SITE:WRITE"]
    },
    {
        "name": "SITE_VIEWER",
        "description": "Site viewer",
        "permissions": ["SITE:READ"]
    }
]
```

### 5. Permission Bundling

```python
class RoleService:
    def get_user_permissions(self, user_id: str, org_id: str) -> Set[str]:
        """Get all permissions for user (union of all assigned roles)."""
        roles = self.get_user_roles(user_id, org_id)
        permissions = set()
        for role in roles:
            permissions.update(role.permissions)
        return permissions
```

---

## Success Criteria

- [ ] All 8 Lambda handlers implemented
- [ ] Platform roles read-only
- [ ] Organisation roles CRUD
- [ ] Default org roles seeded
- [ ] Permission bundling (additive union)
- [ ] Wildcard permission support (e.g., `site:*`)
- [ ] Cannot modify system roles
- [ ] Tests with moto
- [ ] > 80% code coverage

---

## Execution Steps

1. Read Stage 1 output for API contracts
2. Create role models (Platform, Organisation)
3. Implement platform role handlers (read-only)
4. Implement org role CRUD handlers
5. Implement seed handler for defaults
6. Add permission bundling logic
7. Add wildcard permission matching
8. Ensure all tests pass
9. Create output.md
10. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-23
