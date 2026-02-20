# Stage T3: Access Control & RBAC

**Parent Plan**: [BBWS SDLC Main Plan](./main-plan.md)
**Stage**: T3 of T3 (Tenant Management Track)
**Status**: PENDING
**Last Updated**: 2026-01-01

---

## Objective

Implement Role-Based Access Control (RBAC) with tenant isolation, ensuring users from one team cannot access another team's data unless explicitly invited.

---

## Agent & Skill Assignment

| Role | Agent | Skill |
|------|-------|-------|
| **Primary** | Python_AWS_Developer_Agent | `AWS_Python_Dev.skill.md` |
| **Support** | SDET_Engineer_Agent | `SDET_integration_test.skill.md` |

---

## Workers

| # | Worker | Task | Status | Output |
|---|--------|------|--------|--------|
| 1 | worker-1-role-models | Define role and permission models | PENDING | `src/models/` |
| 2 | worker-2-auth-service | Implement authorization service | PENDING | `src/services/` |
| 3 | worker-3-middleware | Create authorization middleware | PENDING | `src/middleware/` |
| 4 | worker-4-isolation-tests | Write tenant isolation tests | PENDING | `tests/` |
| 5 | worker-5-integration | Integrate RBAC with all APIs | PENDING | All handlers |

---

## Worker Instructions

### Worker 1: Role and Permission Models

**Objective**: Define RBAC data models

**Role Hierarchy**:
```
Organization Admin (org_admin)
├── Can manage all resources in tenant
├── Can create/manage divisions, groups, teams
├── Can invite users with any role
└── Can configure tenant settings

Team Admin (team_admin)
├── Can manage team resources
├── Can invite users to their team
└── Can view team members

Team Lead (team_lead)
├── Can manage team sites
├── Can view team members
└── Cannot invite users

Member (member)
├── Can view own team resources
├── Can create/edit assigned sites
└── Cannot view other teams
```

**Permission Model**:
```python
# src/models/permissions.py
from enum import Enum
from typing import List, Set
from pydantic import BaseModel

class Permission(str, Enum):
    # Tenant management
    TENANT_READ = "tenant:read"
    TENANT_UPDATE = "tenant:update"
    TENANT_DELETE = "tenant:delete"

    # Hierarchy management
    DIVISION_CREATE = "division:create"
    DIVISION_READ = "division:read"
    DIVISION_UPDATE = "division:update"
    DIVISION_DELETE = "division:delete"

    GROUP_CREATE = "group:create"
    GROUP_READ = "group:read"
    GROUP_UPDATE = "group:update"
    GROUP_DELETE = "group:delete"

    TEAM_CREATE = "team:create"
    TEAM_READ = "team:read"
    TEAM_UPDATE = "team:update"
    TEAM_DELETE = "team:delete"

    # User management
    USER_INVITE = "user:invite"
    USER_READ = "user:read"
    USER_UPDATE = "user:update"
    USER_REMOVE = "user:remove"

    # Site management
    SITE_CREATE = "site:create"
    SITE_READ = "site:read"
    SITE_UPDATE = "site:update"
    SITE_DELETE = "site:delete"
    SITE_PUBLISH = "site:publish"

    # Admin
    ADMIN_ALL = "admin:*"

class Role(str, Enum):
    ORG_ADMIN = "org_admin"
    TEAM_ADMIN = "team_admin"
    TEAM_LEAD = "team_lead"
    MEMBER = "member"

# Role to permissions mapping
ROLE_PERMISSIONS: dict[Role, Set[Permission]] = {
    Role.ORG_ADMIN: {
        Permission.ADMIN_ALL,  # Has all permissions
    },
    Role.TEAM_ADMIN: {
        Permission.TEAM_READ,
        Permission.TEAM_UPDATE,
        Permission.USER_INVITE,
        Permission.USER_READ,
        Permission.USER_UPDATE,
        Permission.USER_REMOVE,
        Permission.SITE_CREATE,
        Permission.SITE_READ,
        Permission.SITE_UPDATE,
        Permission.SITE_DELETE,
        Permission.SITE_PUBLISH,
    },
    Role.TEAM_LEAD: {
        Permission.TEAM_READ,
        Permission.USER_READ,
        Permission.SITE_CREATE,
        Permission.SITE_READ,
        Permission.SITE_UPDATE,
        Permission.SITE_DELETE,
    },
    Role.MEMBER: {
        Permission.TEAM_READ,
        Permission.USER_READ,
        Permission.SITE_READ,
        Permission.SITE_CREATE,
        Permission.SITE_UPDATE,
    },
}

class UserRole(BaseModel):
    """User's role within a context."""
    user_id: str
    tenant_id: str
    role: Role
    team_id: Optional[str] = None  # None for org-level roles
```

**Quality Criteria**:
- [ ] All permissions defined
- [ ] Role hierarchy implemented
- [ ] Permission mapping complete
- [ ] Scope handling (org vs team)

---

### Worker 2: Authorization Service

**Objective**: Implement permission checking logic

**Authorization Service**:
```python
# src/services/auth_service.py
class AuthorizationService:
    """Service for authorization and permission checks."""

    def __init__(self, repository: HierarchyRepository):
        self.repository = repository

    def check_permission(
        self,
        user_id: str,
        tenant_id: str,
        permission: Permission,
        resource_id: Optional[str] = None
    ) -> bool:
        """Check if user has permission for resource."""
        # Get user's roles
        user_roles = self.repository.get_user_roles(user_id, tenant_id)

        for user_role in user_roles:
            role_permissions = ROLE_PERMISSIONS.get(user_role.role, set())

            # Check for admin all permission
            if Permission.ADMIN_ALL in role_permissions:
                return True

            # Check specific permission
            if permission in role_permissions:
                # If team-scoped, verify team membership
                if user_role.team_id and resource_id:
                    if self._is_resource_in_team(resource_id, user_role.team_id):
                        return True
                else:
                    return True

        return False

    def get_accessible_teams(self, user_id: str, tenant_id: str) -> List[str]:
        """Get list of team IDs user can access."""
        user = self.repository.get_user(user_id)
        return user.teams

    def can_access_resource(
        self,
        user_id: str,
        tenant_id: str,
        resource_type: str,
        resource_id: str
    ) -> bool:
        """Check if user can access a specific resource."""
        # Get resource's team
        resource_team = self._get_resource_team(resource_type, resource_id)

        if not resource_team:
            return False

        # Check if user is member of that team
        user = self.repository.get_user(user_id)
        return resource_team in user.teams

    def enforce_tenant_isolation(
        self,
        user_tenant_id: str,
        resource_tenant_id: str
    ) -> None:
        """Ensure user cannot access cross-tenant resources."""
        if user_tenant_id != resource_tenant_id:
            raise PermissionError("Cross-tenant access denied")

    def _is_resource_in_team(self, resource_id: str, team_id: str) -> bool:
        """Check if resource belongs to team."""
        # Implementation depends on resource type
        resource = self.repository.get_resource(resource_id)
        return resource.team_id == team_id

    def _get_resource_team(self, resource_type: str, resource_id: str) -> Optional[str]:
        """Get team ID for a resource."""
        if resource_type == 'site':
            site = self.repository.get_site(resource_id)
            return site.team_id if site else None
        # Add other resource types
        return None
```

**Quality Criteria**:
- [ ] Permission checking works
- [ ] Tenant isolation enforced
- [ ] Team-level access working
- [ ] Admin bypass functional

---

### Worker 3: Authorization Middleware

**Objective**: Create Lambda middleware for authorization

**Middleware Implementation**:
```python
# src/middleware/auth_middleware.py
import json
import functools
from typing import Callable, List
from src.services.auth_service import AuthorizationService
from src.models.permissions import Permission

def require_permission(*permissions: Permission):
    """Decorator to require specific permissions."""
    def decorator(handler: Callable):
        @functools.wraps(handler)
        def wrapper(event, context):
            # Extract user context from event (set by API Gateway authorizer)
            user_context = event.get('requestContext', {}).get('authorizer', {})
            user_id = user_context.get('user_id')
            tenant_id = user_context.get('tenant_id')

            if not user_id or not tenant_id:
                return {
                    'statusCode': 401,
                    'body': json.dumps({'error': 'Unauthorized'})
                }

            # Check permissions
            auth_service = AuthorizationService(get_repository())

            for permission in permissions:
                if not auth_service.check_permission(user_id, tenant_id, permission):
                    return {
                        'statusCode': 403,
                        'body': json.dumps({
                            'error': 'Forbidden',
                            'message': f'Missing permission: {permission.value}'
                        })
                    }

            # Add auth context to event for handler
            event['auth'] = {
                'user_id': user_id,
                'tenant_id': tenant_id,
                'permissions': [p.value for p in permissions]
            }

            return handler(event, context)
        return wrapper
    return decorator

def require_team_access(handler: Callable):
    """Decorator to require team-level access to resource."""
    @functools.wraps(handler)
    def wrapper(event, context):
        user_context = event.get('requestContext', {}).get('authorizer', {})
        user_id = user_context.get('user_id')
        tenant_id = user_context.get('tenant_id')

        # Get resource from path
        path_params = event.get('pathParameters', {})
        resource_id = path_params.get('site_id') or path_params.get('team_id')

        if resource_id:
            auth_service = AuthorizationService(get_repository())
            if not auth_service.can_access_resource(user_id, tenant_id, 'site', resource_id):
                return {
                    'statusCode': 403,
                    'body': json.dumps({
                        'error': 'Forbidden',
                        'message': 'No access to this resource'
                    })
                }

        return handler(event, context)
    return wrapper

def enforce_tenant(handler: Callable):
    """Decorator to enforce tenant isolation."""
    @functools.wraps(handler)
    def wrapper(event, context):
        user_context = event.get('requestContext', {}).get('authorizer', {})
        user_tenant_id = user_context.get('tenant_id')

        # Check tenant in path or body
        path_params = event.get('pathParameters', {})
        request_tenant_id = path_params.get('tenant_id')

        if not request_tenant_id and event.get('body'):
            body = json.loads(event['body'])
            request_tenant_id = body.get('tenant_id')

        if request_tenant_id and request_tenant_id != user_tenant_id:
            return {
                'statusCode': 403,
                'body': json.dumps({
                    'error': 'Forbidden',
                    'message': 'Cross-tenant access denied'
                })
            }

        return handler(event, context)
    return wrapper
```

**Usage Example**:
```python
# src/handlers/site_handlers.py
from src.middleware.auth_middleware import require_permission, require_team_access

@require_permission(Permission.SITE_CREATE)
@enforce_tenant
def create_site(event, context):
    """Create a new site - requires site:create permission."""
    auth = event['auth']
    tenant_id = auth['tenant_id']
    # ... create site logic

@require_permission(Permission.SITE_READ)
@require_team_access
def get_site(event, context):
    """Get site - requires site:read and team membership."""
    site_id = event['pathParameters']['site_id']
    # ... get site logic
```

**Quality Criteria**:
- [ ] Middleware decorators working
- [ ] Permission checking in middleware
- [ ] Tenant isolation enforced
- [ ] Clean error messages

---

### Worker 4: Tenant Isolation Tests

**Objective**: Verify cross-tenant and cross-team isolation

**Isolation Test Suite**:
```python
# tests/integration/test_tenant_isolation.py
import pytest

class TestTenantIsolation:
    """Tests for multi-tenant isolation."""

    @pytest.fixture
    def tenant_a_user(self):
        """User from Tenant A."""
        return {'user_id': 'user-a', 'tenant_id': 'tenant-a'}

    @pytest.fixture
    def tenant_b_user(self):
        """User from Tenant B."""
        return {'user_id': 'user-b', 'tenant_id': 'tenant-b'}

    def test_user_cannot_access_other_tenant_data(
        self, tenant_a_user, tenant_b_user, api_client
    ):
        """Verify cross-tenant access is denied."""
        # Create site in Tenant A
        site = api_client.create_site(
            auth=tenant_a_user,
            data={'name': 'Site A'}
        )

        # Try to access from Tenant B - should fail
        response = api_client.get_site(
            auth=tenant_b_user,
            site_id=site['site_id']
        )
        assert response.status_code == 403
        assert 'Cross-tenant' in response.json()['message']

    def test_user_cannot_list_other_tenant_resources(
        self, tenant_a_user, tenant_b_user, api_client
    ):
        """Verify tenant scoping in list operations."""
        # Create sites in both tenants
        api_client.create_site(auth=tenant_a_user, data={'name': 'A1'})
        api_client.create_site(auth=tenant_b_user, data={'name': 'B1'})

        # List from Tenant A - should only see A's sites
        sites = api_client.list_sites(auth=tenant_a_user)
        assert all(s['tenant_id'] == 'tenant-a' for s in sites['sites'])

    def test_user_cannot_modify_other_tenant_data(
        self, tenant_a_user, tenant_b_user, api_client
    ):
        """Verify cross-tenant modification is denied."""
        site = api_client.create_site(
            auth=tenant_a_user,
            data={'name': 'Site A'}
        )

        response = api_client.update_site(
            auth=tenant_b_user,
            site_id=site['site_id'],
            data={'name': 'Hacked'}
        )
        assert response.status_code == 403


class TestTeamIsolation:
    """Tests for team-level isolation."""

    @pytest.fixture
    def team_a_user(self):
        """User in Team A."""
        return {'user_id': 'user-a', 'tenant_id': 'tenant-1', 'teams': ['team-a']}

    @pytest.fixture
    def team_b_user(self):
        """User in Team B."""
        return {'user_id': 'user-b', 'tenant_id': 'tenant-1', 'teams': ['team-b']}

    def test_user_cannot_access_other_team_sites(
        self, team_a_user, team_b_user, api_client
    ):
        """Verify team isolation within same tenant."""
        # Create site for Team A
        site = api_client.create_site(
            auth=team_a_user,
            data={'name': 'Team A Site', 'team_id': 'team-a'}
        )

        # Team B user cannot access
        response = api_client.get_site(
            auth=team_b_user,
            site_id=site['site_id']
        )
        assert response.status_code == 403

    def test_multi_team_user_can_access_all_teams(
        self, api_client
    ):
        """User in multiple teams can access all their teams."""
        multi_team_user = {
            'user_id': 'user-multi',
            'tenant_id': 'tenant-1',
            'teams': ['team-a', 'team-b']
        }

        # Create sites in both teams
        site_a = api_client.create_site(
            auth=multi_team_user,
            data={'name': 'A', 'team_id': 'team-a'}
        )
        site_b = api_client.create_site(
            auth=multi_team_user,
            data={'name': 'B', 'team_id': 'team-b'}
        )

        # Can access both
        assert api_client.get_site(auth=multi_team_user, site_id=site_a['site_id']).status_code == 200
        assert api_client.get_site(auth=multi_team_user, site_id=site_b['site_id']).status_code == 200
```

**Quality Criteria**:
- [ ] Cross-tenant access denied
- [ ] Cross-team access denied (same tenant)
- [ ] Multi-team membership working
- [ ] Admin override working

---

### Worker 5: RBAC Integration

**Objective**: Integrate RBAC with all API handlers

**Integration Pattern**:
```python
# Apply middleware to all handlers

# Tenant handlers
@require_permission(Permission.TENANT_READ)
def get_tenant(event, context): ...

@require_permission(Permission.TENANT_UPDATE)
def update_tenant(event, context): ...

# Team handlers
@require_permission(Permission.TEAM_READ)
def list_teams(event, context): ...

@require_permission(Permission.TEAM_CREATE)
def create_team(event, context): ...

# Site handlers
@require_permission(Permission.SITE_READ)
@require_team_access
def get_site(event, context): ...

@require_permission(Permission.SITE_CREATE)
@require_team_access
def create_site(event, context): ...
```

**Quality Criteria**:
- [ ] All handlers protected
- [ ] Consistent authorization
- [ ] Error messages clear
- [ ] Performance acceptable

---

## Stage Outputs

| Output | Description | Location |
|--------|-------------|----------|
| Permission models | Role and permission definitions | `src/models/` |
| Auth service | Authorization logic | `src/services/` |
| Middleware | Lambda middleware | `src/middleware/` |
| Isolation tests | Tenant/team isolation tests | `tests/` |

---

## Approval Gate T1

**Location**: After this stage
**Approvers**: Tech Lead, Security Lead
**Criteria**:
- [ ] RBAC implementation complete
- [ ] Tenant isolation verified
- [ ] Team isolation verified
- [ ] Security review passed

---

## Success Criteria

- [ ] All 5 workers completed
- [ ] RBAC fully functional
- [ ] All isolation tests passing
- [ ] Integrated with all APIs
- [ ] Gate T1 approval obtained

---

## Dependencies

**Depends On**: Stage T2 (User Hierarchy)
**Blocks**: Integration Phase

---

## Estimated Duration

| Activity | Agentic | Manual |
|----------|---------|--------|
| Role models | 20 min | 2 hours |
| Auth service | 30 min | 3 hours |
| Middleware | 25 min | 3 hours |
| Isolation tests | 30 min | 4 hours |
| Integration | 20 min | 2 hours |
| **Total** | **2 hours** | **14 hours** |

---

**Navigation**: [<- Stage T2](./stage-t2-user-hierarchy.md) | [Main Plan](./main-plan.md)
