# Role Service Lambda Functions - Implementation

**Worker ID**: worker-4-role-service-lambdas
**Stage**: Stage 3 - Lambda Services Development
**Project**: project-plan-2-access-management
**Status**: COMPLETE
**Date**: 2026-01-23

---

## Table of Contents

1. [Project Structure](#1-project-structure)
2. [Models](#2-models)
3. [Exceptions](#3-exceptions)
4. [Repository Layer](#4-repository-layer)
5. [Service Layer](#5-service-layer)
6. [Platform Role Handlers](#6-platform-role-handlers)
7. [Organisation Role Handlers](#7-organisation-role-handlers)
8. [Utility Modules](#8-utility-modules)
9. [Unit Tests](#9-unit-tests)
10. [Configuration Files](#10-configuration-files)

---

## 1. Project Structure

```
2_bbws_access_role_lambda/
├── src/
│   ├── __init__.py
│   ├── handlers/
│   │   ├── __init__.py
│   │   ├── platform/
│   │   │   ├── __init__.py
│   │   │   ├── list_platform_roles.py
│   │   │   └── get_platform_role.py
│   │   └── organisation/
│   │       ├── __init__.py
│   │       ├── create_role.py
│   │       ├── list_roles.py
│   │       ├── get_role.py
│   │       ├── update_role.py
│   │       ├── delete_role.py
│   │       └── seed_roles.py
│   ├── models/
│   │   ├── __init__.py
│   │   ├── role.py
│   │   ├── user_role_assignment.py
│   │   ├── default_roles.py
│   │   └── requests.py
│   ├── services/
│   │   ├── __init__.py
│   │   ├── role_service.py
│   │   └── permission_bundler.py
│   ├── repositories/
│   │   ├── __init__.py
│   │   ├── role_repository.py
│   │   └── user_role_repository.py
│   ├── exceptions/
│   │   ├── __init__.py
│   │   └── role_exceptions.py
│   └── utils/
│       ├── __init__.py
│       ├── response_builder.py
│       ├── validators.py
│       └── hateoas.py
├── tests/
│   ├── __init__.py
│   ├── conftest.py
│   ├── unit/
│   │   ├── __init__.py
│   │   ├── test_models.py
│   │   ├── test_role_repository.py
│   │   ├── test_role_service.py
│   │   ├── test_permission_bundler.py
│   │   └── handlers/
│   │       ├── __init__.py
│   │       ├── test_list_platform_roles.py
│   │       ├── test_get_platform_role.py
│   │       ├── test_create_role.py
│   │       ├── test_list_roles.py
│   │       ├── test_get_role.py
│   │       ├── test_update_role.py
│   │       ├── test_delete_role.py
│   │       └── test_seed_roles.py
│   └── integration/
│       └── test_api.py
├── requirements.txt
├── requirements-dev.txt
└── pytest.ini
```

---

## 2. Models

### 2.1 src/models/__init__.py

```python
"""Models package for Role Service."""

from .role import (
    RoleScope,
    Role,
    PlatformRole,
    OrganisationRole,
    PermissionSummary,
    RoleResponse,
    RoleListResponse,
)
from .user_role_assignment import UserRoleAssignment
from .default_roles import DEFAULT_ORG_ROLES, PLATFORM_ROLES
from .requests import (
    CreateRoleRequest,
    UpdateRoleRequest,
    AssignPermissionsRequest,
    RoleFilters,
    PaginationParams,
)

__all__ = [
    "RoleScope",
    "Role",
    "PlatformRole",
    "OrganisationRole",
    "PermissionSummary",
    "RoleResponse",
    "RoleListResponse",
    "UserRoleAssignment",
    "DEFAULT_ORG_ROLES",
    "PLATFORM_ROLES",
    "CreateRoleRequest",
    "UpdateRoleRequest",
    "AssignPermissionsRequest",
    "RoleFilters",
    "PaginationParams",
]
```

### 2.2 src/models/role.py

```python
"""Role models for the Role Service."""

from __future__ import annotations
from pydantic import BaseModel, Field, field_validator
from typing import List, Optional, Dict, Any
from enum import Enum
from datetime import datetime
import uuid
import re


class RoleScope(str, Enum):
    """Scope at which the role applies."""
    PLATFORM = "PLATFORM"
    ORGANISATION = "ORGANISATION"
    TEAM = "TEAM"


class Role(BaseModel):
    """Base role entity stored in DynamoDB."""

    role_id: str = Field(
        default_factory=lambda: f"role-{uuid.uuid4()}",
        alias="roleId"
    )
    name: str = Field(
        ...,
        min_length=2,
        max_length=50,
        description="Role code name (uppercase with underscores)"
    )
    display_name: str = Field(
        ...,
        min_length=2,
        max_length=100,
        alias="displayName"
    )
    description: str = Field(
        default="",
        max_length=500
    )
    organisation_id: Optional[str] = Field(
        default=None,
        alias="organisationId"
    )
    scope: RoleScope = Field(default=RoleScope.ORGANISATION)
    permissions: List[str] = Field(default_factory=list)
    is_system: bool = Field(default=False, alias="isSystem")
    is_default: bool = Field(default=False, alias="isDefault")
    priority: int = Field(default=100, ge=1, le=999)
    active: bool = Field(default=True)
    date_created: datetime = Field(
        default_factory=datetime.utcnow,
        alias="dateCreated"
    )
    date_last_updated: datetime = Field(
        default_factory=datetime.utcnow,
        alias="dateLastUpdated"
    )
    created_by: Optional[str] = Field(default=None, alias="createdBy")
    last_updated_by: Optional[str] = Field(default=None, alias="lastUpdatedBy")

    @field_validator("name")
    @classmethod
    def validate_name_format(cls, v: str) -> str:
        """Validate role name follows uppercase pattern."""
        pattern = r"^[A-Z][A-Z0-9_]*$"
        if not re.match(pattern, v):
            raise ValueError(
                f"Role name must match pattern {pattern}. "
                "Use uppercase letters, numbers, and underscores."
            )
        return v

    class Config:
        populate_by_name = True
        json_encoders = {
            datetime: lambda v: v.isoformat() + "Z"
        }

    def to_dynamodb_item(self) -> Dict[str, Any]:
        """Convert role to DynamoDB item format."""
        pk = "PLATFORM" if self.scope == RoleScope.PLATFORM else f"ORG#{self.organisation_id}"

        item = {
            "PK": pk,
            "SK": f"ROLE#{self.role_id}",
            "roleId": self.role_id,
            "name": self.name,
            "displayName": self.display_name,
            "description": self.description,
            "scope": self.scope.value,
            "permissions": self.permissions,
            "isSystem": self.is_system,
            "isDefault": self.is_default,
            "priority": self.priority,
            "active": self.active,
            "dateCreated": self.date_created.isoformat() + "Z",
            "dateLastUpdated": self.date_last_updated.isoformat() + "Z",
        }

        if self.organisation_id:
            item["organisationId"] = self.organisation_id
            item["GSI1PK"] = f"ORG#{self.organisation_id}#ACTIVE#{self.active}"
            item["GSI1SK"] = f"ROLE#{self.name}"
        else:
            item["GSI1PK"] = f"PLATFORM#ACTIVE#{self.active}"
            item["GSI1SK"] = f"ROLE#{self.name}"

        if self.created_by:
            item["createdBy"] = self.created_by
        if self.last_updated_by:
            item["lastUpdatedBy"] = self.last_updated_by

        return item

    @classmethod
    def from_dynamodb_item(cls, item: Dict[str, Any]) -> "Role":
        """Create Role from DynamoDB item."""
        return cls(
            role_id=item["roleId"],
            name=item["name"],
            display_name=item["displayName"],
            description=item.get("description", ""),
            organisation_id=item.get("organisationId"),
            scope=RoleScope(item["scope"]),
            permissions=item.get("permissions", []),
            is_system=item.get("isSystem", False),
            is_default=item.get("isDefault", False),
            priority=item.get("priority", 100),
            active=item.get("active", True),
            date_created=datetime.fromisoformat(
                item["dateCreated"].replace("Z", "+00:00")
            ),
            date_last_updated=datetime.fromisoformat(
                item["dateLastUpdated"].replace("Z", "+00:00")
            ),
            created_by=item.get("createdBy"),
            last_updated_by=item.get("lastUpdatedBy"),
        )


class PlatformRole(Role):
    """System-defined, read-only platform role."""

    scope: RoleScope = Field(default=RoleScope.PLATFORM, frozen=True)
    is_system: bool = Field(default=True, frozen=True, alias="isSystem")
    organisation_id: Optional[str] = Field(default=None, frozen=True, alias="organisationId")


class OrganisationRole(Role):
    """Customizable organisation-scoped role."""

    organisation_id: str = Field(..., alias="organisationId")
    is_system: bool = Field(default=False, alias="isSystem")


class PermissionSummary(BaseModel):
    """Summary of a permission for role responses."""

    id: str
    name: str
    resource: str
    action: str

    class Config:
        populate_by_name = True


class RoleResponse(BaseModel):
    """Role response with HATEOAS links."""

    id: str
    name: str
    display_name: str = Field(..., alias="displayName")
    description: str
    organisation_id: Optional[str] = Field(default=None, alias="organisationId")
    scope: str
    permissions: List[PermissionSummary]
    is_system: bool = Field(..., alias="isSystem")
    is_default: bool = Field(..., alias="isDefault")
    priority: int
    user_count: int = Field(..., alias="userCount")
    active: bool
    date_created: str = Field(..., alias="dateCreated")
    date_last_updated: str = Field(..., alias="dateLastUpdated")
    links: Dict[str, Any] = Field(default_factory=dict, alias="_links")

    class Config:
        populate_by_name = True


class RoleListResponse(BaseModel):
    """Paginated role list response."""

    items: List[RoleResponse]
    start_at: Optional[str] = Field(default=None, alias="startAt")
    more_available: bool = Field(..., alias="moreAvailable")
    count: int
    links: Dict[str, Any] = Field(default_factory=dict, alias="_links")

    class Config:
        populate_by_name = True
```

### 2.3 src/models/user_role_assignment.py

```python
"""User role assignment model."""

from pydantic import BaseModel, Field
from typing import Optional, Dict, Any
from datetime import datetime
from .role import RoleScope


class UserRoleAssignment(BaseModel):
    """User role assignment entity."""

    organisation_id: str = Field(..., alias="organisationId")
    user_id: str = Field(..., alias="userId")
    role_id: str = Field(..., alias="roleId")
    role_name: str = Field(..., alias="roleName")
    scope: RoleScope
    team_id: Optional[str] = Field(default=None, alias="teamId")
    assigned_by: str = Field(..., alias="assignedBy")
    assigned_at: datetime = Field(
        default_factory=datetime.utcnow,
        alias="assignedAt"
    )
    active: bool = Field(default=True)

    class Config:
        populate_by_name = True
        json_encoders = {
            datetime: lambda v: v.isoformat() + "Z"
        }

    def to_dynamodb_item(self) -> Dict[str, Any]:
        """Convert to DynamoDB item format."""
        item = {
            "PK": f"ORG#{self.organisation_id}#USER#{self.user_id}",
            "SK": f"ROLE#{self.role_id}",
            "organisationId": self.organisation_id,
            "userId": self.user_id,
            "roleId": self.role_id,
            "roleName": self.role_name,
            "scope": self.scope.value,
            "assignedBy": self.assigned_by,
            "assignedAt": self.assigned_at.isoformat() + "Z",
            "active": self.active,
            "GSI1PK": f"ORG#{self.organisation_id}#ROLE#{self.role_id}",
            "GSI1SK": f"USER#{self.user_id}",
        }

        if self.team_id:
            item["teamId"] = self.team_id

        return item

    @classmethod
    def from_dynamodb_item(cls, item: Dict[str, Any]) -> "UserRoleAssignment":
        """Create from DynamoDB item."""
        return cls(
            organisation_id=item["organisationId"],
            user_id=item["userId"],
            role_id=item["roleId"],
            role_name=item["roleName"],
            scope=RoleScope(item["scope"]),
            team_id=item.get("teamId"),
            assigned_by=item["assignedBy"],
            assigned_at=datetime.fromisoformat(
                item["assignedAt"].replace("Z", "+00:00")
            ),
            active=item.get("active", True),
        )
```

### 2.4 src/models/default_roles.py

```python
"""Default and platform role definitions."""

from .role import RoleScope

# Platform roles (system-defined, read-only)
PLATFORM_ROLES = [
    {
        "role_id": "role-platform-admin-001",
        "name": "PLATFORM_ADMIN",
        "display_name": "Platform Administrator",
        "description": "Full platform access including organisation management",
        "scope": RoleScope.PLATFORM,
        "permissions": [
            "org:create", "org:read", "org:update", "org:delete",
            "user:create", "user:read", "user:update", "user:delete",
            "subscription:create", "subscription:read", "subscription:update",
            "billing:read", "billing:update",
        ],
        "is_system": True,
        "is_default": False,
        "priority": 1,
    },
    {
        "role_id": "role-support-agent-001",
        "name": "SUPPORT_AGENT",
        "display_name": "Support Agent",
        "description": "Read access for support operations, no data modification",
        "scope": RoleScope.PLATFORM,
        "permissions": [
            "org:read",
            "user:read",
            "site:read",
            "team:read",
            "subscription:read",
        ],
        "is_system": True,
        "is_default": False,
        "priority": 2,
    },
    {
        "role_id": "role-billing-admin-001",
        "name": "BILLING_ADMIN",
        "display_name": "Billing Administrator",
        "description": "Manage subscriptions and view usage across platform",
        "scope": RoleScope.PLATFORM,
        "permissions": [
            "subscription:create", "subscription:read", "subscription:update", "subscription:delete",
            "billing:read", "billing:update",
            "usage:read",
            "org:read",
        ],
        "is_system": True,
        "is_default": False,
        "priority": 3,
    },
]

# Default organisation roles (seeded on org creation)
DEFAULT_ORG_ROLES = [
    {
        "name": "ORG_ADMIN",
        "display_name": "Organisation Admin",
        "description": "Full organisation access including user and role management",
        "scope": RoleScope.ORGANISATION,
        "permissions": [
            "org:read", "org:update",
            "user:create", "user:read", "user:update", "user:delete",
            "team:create", "team:read", "team:update", "team:delete",
            "role:create", "role:read", "role:update", "role:delete",
            "site:create", "site:read", "site:update", "site:delete", "site:publish",
            "invitation:create", "invitation:read", "invitation:revoke",
        ],
        "is_system": False,
        "is_default": True,
        "priority": 1,
    },
    {
        "name": "ORG_MANAGER",
        "display_name": "Organisation Manager",
        "description": "Manage teams and invite users",
        "scope": RoleScope.ORGANISATION,
        "permissions": [
            "org:read",
            "user:read",
            "team:create", "team:read", "team:update",
            "invitation:create", "invitation:read",
        ],
        "is_system": False,
        "is_default": True,
        "priority": 2,
    },
    {
        "name": "SITE_ADMIN",
        "display_name": "Site Admin",
        "description": "Full site management within team scope",
        "scope": RoleScope.TEAM,
        "permissions": [
            "site:create", "site:read", "site:update", "site:delete", "site:publish",
        ],
        "is_system": False,
        "is_default": True,
        "priority": 3,
    },
    {
        "name": "SITE_EDITOR",
        "display_name": "Site Editor",
        "description": "Edit and publish sites within team scope",
        "scope": RoleScope.TEAM,
        "permissions": [
            "site:read", "site:update", "site:publish",
        ],
        "is_system": False,
        "is_default": True,
        "priority": 4,
    },
    {
        "name": "SITE_VIEWER",
        "display_name": "Site Viewer",
        "description": "Read-only access to team sites",
        "scope": RoleScope.TEAM,
        "permissions": [
            "site:read",
        ],
        "is_system": False,
        "is_default": True,
        "priority": 5,
    },
]
```

### 2.5 src/models/requests.py

```python
"""Request models for Role Service API."""

from pydantic import BaseModel, Field, field_validator
from typing import List, Optional
from .role import RoleScope
import re


class CreateRoleRequest(BaseModel):
    """Request body for creating a role."""

    name: str = Field(
        ...,
        min_length=2,
        max_length=50,
        description="Role code name"
    )
    display_name: str = Field(
        ...,
        min_length=2,
        max_length=100,
        alias="displayName"
    )
    description: str = Field(default="", max_length=500)
    scope: RoleScope = Field(default=RoleScope.ORGANISATION)
    permissions: List[str] = Field(..., min_length=1)
    priority: int = Field(default=100, ge=1, le=999)

    @field_validator("name")
    @classmethod
    def validate_name_format(cls, v: str) -> str:
        """Validate role name follows uppercase pattern."""
        pattern = r"^[A-Z][A-Z0-9_]*$"
        if not re.match(pattern, v):
            raise ValueError(
                f"Role name must match pattern {pattern}. "
                "Use uppercase letters, numbers, and underscores."
            )
        return v

    class Config:
        populate_by_name = True


class UpdateRoleRequest(BaseModel):
    """Request body for updating a role."""

    display_name: Optional[str] = Field(
        default=None,
        min_length=2,
        max_length=100,
        alias="displayName"
    )
    description: Optional[str] = Field(default=None, max_length=500)
    scope: Optional[RoleScope] = None
    priority: Optional[int] = Field(default=None, ge=1, le=999)
    active: Optional[bool] = None

    class Config:
        populate_by_name = True


class AssignPermissionsRequest(BaseModel):
    """Request body for assigning permissions to a role."""

    permissions: List[str] = Field(..., min_length=1)

    class Config:
        populate_by_name = True


class RoleFilters(BaseModel):
    """Filters for listing roles."""

    scope: Optional[RoleScope] = None
    include_inactive: bool = Field(default=False, alias="includeInactive")

    class Config:
        populate_by_name = True


class PaginationParams(BaseModel):
    """Pagination parameters."""

    page_size: int = Field(default=50, ge=1, le=100, alias="pageSize")
    start_at: Optional[str] = Field(default=None, alias="startAt")

    class Config:
        populate_by_name = True
```

---

## 3. Exceptions

### 3.1 src/exceptions/__init__.py

```python
"""Exceptions package for Role Service."""

from .role_exceptions import (
    RoleServiceException,
    RoleNotFoundException,
    DuplicateRoleNameException,
    RoleInUseException,
    InvalidPermissionException,
    CannotModifySystemRoleException,
    UnauthorizedOrgAccessException,
    ValidationException,
)

__all__ = [
    "RoleServiceException",
    "RoleNotFoundException",
    "DuplicateRoleNameException",
    "RoleInUseException",
    "InvalidPermissionException",
    "CannotModifySystemRoleException",
    "UnauthorizedOrgAccessException",
    "ValidationException",
]
```

### 3.2 src/exceptions/role_exceptions.py

```python
"""Custom exceptions for Role Service."""

from typing import Optional


class RoleServiceException(Exception):
    """Base exception for Role Service."""

    def __init__(
        self,
        message: str,
        error_code: str,
        status_code: int = 500
    ):
        super().__init__(message)
        self.message = message
        self.error_code = error_code
        self.status_code = status_code

    def to_dict(self):
        """Convert exception to error response dict."""
        return {
            "errorCode": self.error_code,
            "message": self.message,
        }


class RoleNotFoundException(RoleServiceException):
    """Raised when a role is not found."""

    def __init__(self, role_id: str):
        super().__init__(
            message=f"Role not found: {role_id}",
            error_code="ROLE_NOT_FOUND",
            status_code=404
        )
        self.role_id = role_id


class DuplicateRoleNameException(RoleServiceException):
    """Raised when role name already exists in org."""

    def __init__(self, name: str, org_id: Optional[str] = None):
        context = f" in organisation {org_id}" if org_id else ""
        super().__init__(
            message=f"Role name '{name}' already exists{context}",
            error_code="DUPLICATE_ROLE_NAME",
            status_code=409
        )
        self.name = name
        self.org_id = org_id


class RoleInUseException(RoleServiceException):
    """Raised when trying to delete a role with assigned users."""

    def __init__(self, role_id: str, user_count: int):
        super().__init__(
            message=f"Role has {user_count} users assigned. Reassign users first.",
            error_code="ROLE_IN_USE",
            status_code=400
        )
        self.role_id = role_id
        self.user_count = user_count


class InvalidPermissionException(RoleServiceException):
    """Raised when a permission ID is invalid."""

    def __init__(self, permission_id: str):
        super().__init__(
            message=f"Permission not found: {permission_id}",
            error_code="INVALID_PERMISSION",
            status_code=400
        )
        self.permission_id = permission_id


class CannotModifySystemRoleException(RoleServiceException):
    """Raised when trying to modify a system role."""

    def __init__(self, role_id: str):
        super().__init__(
            message="System roles cannot be modified",
            error_code="CANNOT_MODIFY_SYSTEM_ROLE",
            status_code=403
        )
        self.role_id = role_id


class UnauthorizedOrgAccessException(RoleServiceException):
    """Raised when user tries to access another org's data."""

    def __init__(self, user_org_id: str, target_org_id: str):
        super().__init__(
            message="Access denied to this organisation",
            error_code="UNAUTHORIZED_ORG_ACCESS",
            status_code=403
        )
        self.user_org_id = user_org_id
        self.target_org_id = target_org_id


class ValidationException(RoleServiceException):
    """Raised for validation errors."""

    def __init__(self, message: str, field: Optional[str] = None):
        super().__init__(
            message=message,
            error_code="VALIDATION_ERROR",
            status_code=400
        )
        self.field = field
```

---

## 4. Repository Layer

### 4.1 src/repositories/__init__.py

```python
"""Repository package for Role Service."""

from .role_repository import RoleRepository
from .user_role_repository import UserRoleRepository

__all__ = ["RoleRepository", "UserRoleRepository"]
```

### 4.2 src/repositories/role_repository.py

```python
"""Repository for Role entity operations."""

import boto3
from boto3.dynamodb.conditions import Key, Attr
from typing import Optional, List, Tuple, Dict, Any
from datetime import datetime
import os
import logging

from ..models.role import Role, RoleScope
from ..exceptions import RoleNotFoundException

logger = logging.getLogger(__name__)


class RoleRepository:
    """Repository for Role CRUD operations in DynamoDB."""

    def __init__(self, table_name: Optional[str] = None):
        """Initialize repository with DynamoDB table.

        Args:
            table_name: DynamoDB table name. Defaults to env var.
        """
        self.table_name = table_name or os.environ.get(
            "DYNAMODB_TABLE_NAME",
            "bbws-aipagebuilder-dev-ddb-access-management"
        )
        self._dynamodb = None
        self._table = None

    @property
    def dynamodb(self):
        """Lazy initialization of DynamoDB resource."""
        if self._dynamodb is None:
            self._dynamodb = boto3.resource("dynamodb")
        return self._dynamodb

    @property
    def table(self):
        """Lazy initialization of DynamoDB table."""
        if self._table is None:
            self._table = self.dynamodb.Table(self.table_name)
        return self._table

    def save(self, role: Role) -> Role:
        """Save a new role to DynamoDB.

        Args:
            role: Role entity to save.

        Returns:
            The saved role.
        """
        item = role.to_dynamodb_item()

        logger.info(f"Saving role: {role.role_id}")

        self.table.put_item(Item=item)

        return role

    def find_by_id(
        self,
        role_id: str,
        org_id: Optional[str] = None
    ) -> Optional[Role]:
        """Find a role by ID.

        Args:
            role_id: The role ID.
            org_id: Organisation ID (None for platform roles).

        Returns:
            The role if found, None otherwise.
        """
        pk = "PLATFORM" if org_id is None else f"ORG#{org_id}"
        sk = f"ROLE#{role_id}"

        response = self.table.get_item(
            Key={"PK": pk, "SK": sk}
        )

        item = response.get("Item")
        if not item:
            return None

        return Role.from_dynamodb_item(item)

    def find_by_name(
        self,
        name: str,
        org_id: Optional[str] = None,
        include_inactive: bool = False
    ) -> Optional[Role]:
        """Find a role by name within an org or platform.

        Args:
            name: Role name to find.
            org_id: Organisation ID (None for platform roles).
            include_inactive: Whether to include inactive roles.

        Returns:
            The role if found, None otherwise.
        """
        if org_id:
            gsi1pk = f"ORG#{org_id}#ACTIVE#true"
        else:
            gsi1pk = "PLATFORM#ACTIVE#true"

        gsi1sk = f"ROLE#{name}"

        response = self.table.query(
            IndexName="GSI1",
            KeyConditionExpression=Key("GSI1PK").eq(gsi1pk) & Key("GSI1SK").eq(gsi1sk)
        )

        items = response.get("Items", [])
        if not items:
            # Try inactive if requested
            if include_inactive and org_id:
                gsi1pk = f"ORG#{org_id}#ACTIVE#false"
                response = self.table.query(
                    IndexName="GSI1",
                    KeyConditionExpression=Key("GSI1PK").eq(gsi1pk) & Key("GSI1SK").eq(gsi1sk)
                )
                items = response.get("Items", [])

        if not items:
            return None

        return Role.from_dynamodb_item(items[0])

    def find_platform_roles(
        self,
        page_size: int = 50,
        start_key: Optional[str] = None
    ) -> Tuple[List[Role], Optional[str]]:
        """List all platform roles with pagination.

        Args:
            page_size: Number of items per page.
            start_key: Pagination cursor.

        Returns:
            Tuple of (roles list, next page cursor).
        """
        query_params = {
            "KeyConditionExpression": Key("PK").eq("PLATFORM") & Key("SK").begins_with("ROLE#"),
            "Limit": page_size,
        }

        if start_key:
            query_params["ExclusiveStartKey"] = {
                "PK": "PLATFORM",
                "SK": f"ROLE#{start_key}"
            }

        response = self.table.query(**query_params)

        items = response.get("Items", [])
        roles = [Role.from_dynamodb_item(item) for item in items]

        last_key = response.get("LastEvaluatedKey")
        next_cursor = None
        if last_key:
            next_cursor = last_key["SK"].replace("ROLE#", "")

        return roles, next_cursor

    def find_by_org_id(
        self,
        org_id: str,
        filters: Optional[Dict[str, Any]] = None,
        page_size: int = 50,
        start_key: Optional[str] = None
    ) -> Tuple[List[Role], Optional[str]]:
        """List roles for an organisation with filters and pagination.

        Args:
            org_id: Organisation ID.
            filters: Optional filters (scope, includeInactive).
            page_size: Number of items per page.
            start_key: Pagination cursor.

        Returns:
            Tuple of (roles list, next page cursor).
        """
        filters = filters or {}
        include_inactive = filters.get("includeInactive", False)
        scope = filters.get("scope")

        pk = f"ORG#{org_id}"

        query_params = {
            "KeyConditionExpression": Key("PK").eq(pk) & Key("SK").begins_with("ROLE#"),
            "Limit": page_size,
        }

        # Build filter expression
        filter_conditions = []

        if not include_inactive:
            filter_conditions.append(Attr("active").eq(True))

        if scope:
            filter_conditions.append(Attr("scope").eq(scope))

        if filter_conditions:
            filter_expr = filter_conditions[0]
            for condition in filter_conditions[1:]:
                filter_expr = filter_expr & condition
            query_params["FilterExpression"] = filter_expr

        if start_key:
            query_params["ExclusiveStartKey"] = {
                "PK": pk,
                "SK": f"ROLE#{start_key}"
            }

        response = self.table.query(**query_params)

        items = response.get("Items", [])
        roles = [Role.from_dynamodb_item(item) for item in items]

        last_key = response.get("LastEvaluatedKey")
        next_cursor = None
        if last_key:
            next_cursor = last_key["SK"].replace("ROLE#", "")

        return roles, next_cursor

    def update(self, role: Role) -> Role:
        """Update an existing role.

        Args:
            role: Role with updated values.

        Returns:
            The updated role.
        """
        role.date_last_updated = datetime.utcnow()
        item = role.to_dynamodb_item()

        logger.info(f"Updating role: {role.role_id}")

        self.table.put_item(Item=item)

        return role

    def delete(self, role_id: str, org_id: Optional[str] = None) -> bool:
        """Delete a role (hard delete - use soft delete via update instead).

        Args:
            role_id: Role ID to delete.
            org_id: Organisation ID (None for platform roles).

        Returns:
            True if deleted.
        """
        pk = "PLATFORM" if org_id is None else f"ORG#{org_id}"
        sk = f"ROLE#{role_id}"

        logger.info(f"Deleting role: {role_id}")

        self.table.delete_item(
            Key={"PK": pk, "SK": sk}
        )

        return True
```

### 4.3 src/repositories/user_role_repository.py

```python
"""Repository for UserRoleAssignment operations."""

import boto3
from boto3.dynamodb.conditions import Key, Attr
from typing import Optional, List
import os
import logging

from ..models.user_role_assignment import UserRoleAssignment

logger = logging.getLogger(__name__)


class UserRoleRepository:
    """Repository for user-role assignment operations."""

    def __init__(self, table_name: Optional[str] = None):
        """Initialize repository with DynamoDB table."""
        self.table_name = table_name or os.environ.get(
            "DYNAMODB_TABLE_NAME",
            "bbws-aipagebuilder-dev-ddb-access-management"
        )
        self._dynamodb = None
        self._table = None

    @property
    def dynamodb(self):
        """Lazy initialization of DynamoDB resource."""
        if self._dynamodb is None:
            self._dynamodb = boto3.resource("dynamodb")
        return self._dynamodb

    @property
    def table(self):
        """Lazy initialization of DynamoDB table."""
        if self._table is None:
            self._table = self.dynamodb.Table(self.table_name)
        return self._table

    def count_users_with_role(self, org_id: str, role_id: str) -> int:
        """Count active users assigned to a role.

        Args:
            org_id: Organisation ID.
            role_id: Role ID.

        Returns:
            Count of users with this role.
        """
        gsi1pk = f"ORG#{org_id}#ROLE#{role_id}"

        response = self.table.query(
            IndexName="GSI1",
            KeyConditionExpression=Key("GSI1PK").eq(gsi1pk),
            FilterExpression=Attr("active").eq(True),
            Select="COUNT"
        )

        return response.get("Count", 0)

    def find_by_role_id(
        self,
        org_id: str,
        role_id: str
    ) -> List[UserRoleAssignment]:
        """Find all user assignments for a role.

        Args:
            org_id: Organisation ID.
            role_id: Role ID.

        Returns:
            List of user role assignments.
        """
        gsi1pk = f"ORG#{org_id}#ROLE#{role_id}"

        response = self.table.query(
            IndexName="GSI1",
            KeyConditionExpression=Key("GSI1PK").eq(gsi1pk),
            FilterExpression=Attr("active").eq(True)
        )

        items = response.get("Items", [])
        return [UserRoleAssignment.from_dynamodb_item(item) for item in items]

    def find_by_user_id(
        self,
        org_id: str,
        user_id: str
    ) -> List[UserRoleAssignment]:
        """Find all role assignments for a user.

        Args:
            org_id: Organisation ID.
            user_id: User ID.

        Returns:
            List of user role assignments.
        """
        pk = f"ORG#{org_id}#USER#{user_id}"

        response = self.table.query(
            KeyConditionExpression=Key("PK").eq(pk) & Key("SK").begins_with("ROLE#"),
            FilterExpression=Attr("active").eq(True)
        )

        items = response.get("Items", [])
        return [UserRoleAssignment.from_dynamodb_item(item) for item in items]

    def save(self, assignment: UserRoleAssignment) -> UserRoleAssignment:
        """Save a user role assignment.

        Args:
            assignment: The assignment to save.

        Returns:
            The saved assignment.
        """
        item = assignment.to_dynamodb_item()

        logger.info(
            f"Saving role assignment: user={assignment.user_id}, "
            f"role={assignment.role_id}"
        )

        self.table.put_item(Item=item)

        return assignment

    def revoke(
        self,
        org_id: str,
        user_id: str,
        role_id: str
    ) -> bool:
        """Revoke a user's role (soft delete).

        Args:
            org_id: Organisation ID.
            user_id: User ID.
            role_id: Role ID to revoke.

        Returns:
            True if revoked.
        """
        pk = f"ORG#{org_id}#USER#{user_id}"
        sk = f"ROLE#{role_id}"

        logger.info(f"Revoking role {role_id} from user {user_id}")

        self.table.update_item(
            Key={"PK": pk, "SK": sk},
            UpdateExpression="SET active = :active",
            ExpressionAttributeValues={":active": False}
        )

        return True
```

---

## 5. Service Layer

### 5.1 src/services/__init__.py

```python
"""Services package for Role Service."""

from .role_service import RoleService
from .permission_bundler import PermissionBundler

__all__ = ["RoleService", "PermissionBundler"]
```

### 5.2 src/services/role_service.py

```python
"""Role Service - Business logic for role operations."""

from typing import List, Optional, Set, Dict, Any
from datetime import datetime
import logging
import uuid

from ..models.role import Role, RoleScope, RoleResponse, RoleListResponse, PermissionSummary
from ..models.requests import CreateRoleRequest, UpdateRoleRequest, RoleFilters, PaginationParams
from ..models.default_roles import DEFAULT_ORG_ROLES, PLATFORM_ROLES
from ..repositories.role_repository import RoleRepository
from ..repositories.user_role_repository import UserRoleRepository
from ..exceptions import (
    RoleNotFoundException,
    DuplicateRoleNameException,
    RoleInUseException,
    InvalidPermissionException,
    CannotModifySystemRoleException,
)
from .permission_bundler import PermissionBundler

logger = logging.getLogger(__name__)


class RoleService:
    """Service class for role business logic."""

    def __init__(
        self,
        role_repository: Optional[RoleRepository] = None,
        user_role_repository: Optional[UserRoleRepository] = None,
        permission_bundler: Optional[PermissionBundler] = None
    ):
        """Initialize service with dependencies.

        Args:
            role_repository: Repository for role operations.
            user_role_repository: Repository for user-role assignments.
            permission_bundler: Service for permission bundling.
        """
        self.role_repository = role_repository or RoleRepository()
        self.user_role_repository = user_role_repository or UserRoleRepository()
        self.permission_bundler = permission_bundler or PermissionBundler()

    # ==================== Platform Role Operations ====================

    def list_platform_roles(
        self,
        pagination: Optional[PaginationParams] = None
    ) -> RoleListResponse:
        """List all platform roles.

        Args:
            pagination: Pagination parameters.

        Returns:
            Paginated list of platform roles.
        """
        pagination = pagination or PaginationParams()

        roles, next_cursor = self.role_repository.find_platform_roles(
            page_size=pagination.page_size,
            start_key=pagination.start_at
        )

        # Build responses with user counts
        items = []
        for role in roles:
            user_count = 0  # Platform roles don't have org-scoped user counts
            response = self._build_role_response(role, user_count)
            items.append(response)

        return RoleListResponse(
            items=items,
            start_at=next_cursor,
            more_available=next_cursor is not None,
            count=len(items),
            links=self._build_platform_list_links(pagination, next_cursor)
        )

    def get_platform_role(self, role_id: str) -> RoleResponse:
        """Get a platform role by ID.

        Args:
            role_id: Platform role ID.

        Returns:
            Role response.

        Raises:
            RoleNotFoundException: If role not found.
        """
        role = self.role_repository.find_by_id(role_id, org_id=None)

        if not role:
            raise RoleNotFoundException(role_id)

        user_count = 0  # Platform roles
        return self._build_role_response(role, user_count)

    # ==================== Organisation Role Operations ====================

    def create_role(
        self,
        org_id: str,
        request: CreateRoleRequest,
        created_by: str
    ) -> RoleResponse:
        """Create a new organisation role.

        Args:
            org_id: Organisation ID.
            request: Create role request.
            created_by: Email of creator.

        Returns:
            Created role response.

        Raises:
            DuplicateRoleNameException: If name exists.
            InvalidPermissionException: If permission invalid.
        """
        # Check for duplicate name
        existing = self.role_repository.find_by_name(request.name, org_id)
        if existing:
            raise DuplicateRoleNameException(request.name, org_id)

        # Validate permissions exist
        self._validate_permissions(request.permissions)

        # Create role
        role = Role(
            role_id=f"role-{uuid.uuid4()}",
            name=request.name,
            display_name=request.display_name,
            description=request.description,
            organisation_id=org_id,
            scope=request.scope,
            permissions=request.permissions,
            is_system=False,
            is_default=False,
            priority=request.priority,
            active=True,
            date_created=datetime.utcnow(),
            date_last_updated=datetime.utcnow(),
            created_by=created_by,
            last_updated_by=created_by,
        )

        saved_role = self.role_repository.save(role)

        logger.info(f"Created role: {saved_role.role_id} in org {org_id}")

        return self._build_role_response(saved_role, user_count=0)

    def list_roles(
        self,
        org_id: str,
        filters: Optional[RoleFilters] = None,
        pagination: Optional[PaginationParams] = None
    ) -> RoleListResponse:
        """List organisation roles.

        Args:
            org_id: Organisation ID.
            filters: Optional filters.
            pagination: Pagination parameters.

        Returns:
            Paginated list of roles.
        """
        filters = filters or RoleFilters()
        pagination = pagination or PaginationParams()

        filter_dict = {
            "includeInactive": filters.include_inactive,
        }
        if filters.scope:
            filter_dict["scope"] = filters.scope.value

        roles, next_cursor = self.role_repository.find_by_org_id(
            org_id=org_id,
            filters=filter_dict,
            page_size=pagination.page_size,
            start_key=pagination.start_at
        )

        # Build responses with user counts
        items = []
        for role in roles:
            user_count = self.user_role_repository.count_users_with_role(
                org_id, role.role_id
            )
            response = self._build_role_response(role, user_count)
            items.append(response)

        return RoleListResponse(
            items=items,
            start_at=next_cursor,
            more_available=next_cursor is not None,
            count=len(items),
            links=self._build_org_list_links(org_id, pagination, next_cursor)
        )

    def get_role(self, org_id: str, role_id: str) -> RoleResponse:
        """Get an organisation role by ID.

        Args:
            org_id: Organisation ID.
            role_id: Role ID.

        Returns:
            Role response.

        Raises:
            RoleNotFoundException: If role not found.
        """
        role = self.role_repository.find_by_id(role_id, org_id)

        if not role:
            raise RoleNotFoundException(role_id)

        user_count = self.user_role_repository.count_users_with_role(
            org_id, role_id
        )

        return self._build_role_response(role, user_count)

    def update_role(
        self,
        org_id: str,
        role_id: str,
        request: UpdateRoleRequest,
        updated_by: str
    ) -> RoleResponse:
        """Update an organisation role.

        Args:
            org_id: Organisation ID.
            role_id: Role ID.
            request: Update request.
            updated_by: Email of updater.

        Returns:
            Updated role response.

        Raises:
            RoleNotFoundException: If role not found.
            CannotModifySystemRoleException: If system role.
            RoleInUseException: If deactivating role with users.
        """
        role = self.role_repository.find_by_id(role_id, org_id)

        if not role:
            raise RoleNotFoundException(role_id)

        if role.is_system:
            raise CannotModifySystemRoleException(role_id)

        # Check if deactivating a role with users
        if request.active is False:
            user_count = self.user_role_repository.count_users_with_role(
                org_id, role_id
            )
            if user_count > 0:
                raise RoleInUseException(role_id, user_count)

        # Update fields
        if request.display_name is not None:
            role.display_name = request.display_name
        if request.description is not None:
            role.description = request.description
        if request.scope is not None:
            role.scope = request.scope
        if request.priority is not None:
            role.priority = request.priority
        if request.active is not None:
            role.active = request.active

        role.last_updated_by = updated_by
        role.date_last_updated = datetime.utcnow()

        updated_role = self.role_repository.update(role)

        logger.info(f"Updated role: {role_id}")

        user_count = self.user_role_repository.count_users_with_role(
            org_id, role_id
        )

        return self._build_role_response(updated_role, user_count)

    def assign_permissions(
        self,
        org_id: str,
        role_id: str,
        permissions: List[str],
        updated_by: str
    ) -> RoleResponse:
        """Assign permissions to a role.

        Args:
            org_id: Organisation ID.
            role_id: Role ID.
            permissions: List of permission IDs.
            updated_by: Email of updater.

        Returns:
            Updated role response.

        Raises:
            RoleNotFoundException: If role not found.
            CannotModifySystemRoleException: If system role.
            InvalidPermissionException: If permission invalid.
        """
        role = self.role_repository.find_by_id(role_id, org_id)

        if not role:
            raise RoleNotFoundException(role_id)

        if role.is_system:
            raise CannotModifySystemRoleException(role_id)

        # Validate permissions
        self._validate_permissions(permissions)

        # Capture old permissions for audit
        old_permissions = role.permissions.copy()

        # Update permissions
        role.permissions = permissions
        role.last_updated_by = updated_by
        role.date_last_updated = datetime.utcnow()

        updated_role = self.role_repository.update(role)

        logger.info(
            f"Updated permissions for role {role_id}: "
            f"{old_permissions} -> {permissions}"
        )

        user_count = self.user_role_repository.count_users_with_role(
            org_id, role_id
        )

        return self._build_role_response(updated_role, user_count)

    def delete_role(
        self,
        org_id: str,
        role_id: str,
        deleted_by: str
    ) -> None:
        """Soft delete a role by setting active=False.

        Args:
            org_id: Organisation ID.
            role_id: Role ID.
            deleted_by: Email of deleter.

        Raises:
            RoleNotFoundException: If role not found.
            CannotModifySystemRoleException: If system role.
            RoleInUseException: If role has assigned users.
        """
        role = self.role_repository.find_by_id(role_id, org_id)

        if not role:
            raise RoleNotFoundException(role_id)

        if role.is_system:
            raise CannotModifySystemRoleException(role_id)

        # Check if role has users
        user_count = self.user_role_repository.count_users_with_role(
            org_id, role_id
        )
        if user_count > 0:
            raise RoleInUseException(role_id, user_count)

        # Soft delete
        role.active = False
        role.last_updated_by = deleted_by
        role.date_last_updated = datetime.utcnow()

        self.role_repository.update(role)

        logger.info(f"Soft deleted role: {role_id}")

    def seed_default_roles(
        self,
        org_id: str,
        created_by: str
    ) -> List[RoleResponse]:
        """Seed default roles for a new organisation.

        Args:
            org_id: Organisation ID.
            created_by: Email of creator.

        Returns:
            List of created role responses.
        """
        created_roles = []

        for role_def in DEFAULT_ORG_ROLES:
            # Check if already exists
            existing = self.role_repository.find_by_name(
                role_def["name"],
                org_id,
                include_inactive=True
            )
            if existing:
                logger.info(f"Role {role_def['name']} already exists in org {org_id}")
                continue

            role = Role(
                role_id=f"role-{uuid.uuid4()}",
                name=role_def["name"],
                display_name=role_def["display_name"],
                description=role_def["description"],
                organisation_id=org_id,
                scope=role_def["scope"],
                permissions=role_def["permissions"],
                is_system=False,
                is_default=True,
                priority=role_def["priority"],
                active=True,
                date_created=datetime.utcnow(),
                date_last_updated=datetime.utcnow(),
                created_by=created_by,
                last_updated_by=created_by,
            )

            saved_role = self.role_repository.save(role)
            response = self._build_role_response(saved_role, user_count=0)
            created_roles.append(response)

            logger.info(f"Seeded role: {role_def['name']} in org {org_id}")

        return created_roles

    # ==================== Permission Bundling ====================

    def get_user_permissions(
        self,
        org_id: str,
        user_id: str
    ) -> Set[str]:
        """Get all permissions for a user (union of all assigned roles).

        Args:
            org_id: Organisation ID.
            user_id: User ID.

        Returns:
            Set of permission strings.
        """
        assignments = self.user_role_repository.find_by_user_id(org_id, user_id)

        all_permissions: Set[str] = set()

        for assignment in assignments:
            role = self.role_repository.find_by_id(
                assignment.role_id,
                org_id
            )
            if role and role.active:
                all_permissions.update(role.permissions)

        return all_permissions

    # ==================== Private Methods ====================

    def _validate_permissions(self, permissions: List[str]) -> None:
        """Validate that permissions are in correct format.

        For now, validates format only. In production, would call
        Permission Service to verify existence.

        Args:
            permissions: List of permission strings.

        Raises:
            InvalidPermissionException: If permission format invalid.
        """
        import re
        pattern = r"^[a-z]+:[a-z*]+$"

        for perm in permissions:
            if not re.match(pattern, perm):
                raise InvalidPermissionException(perm)

    def _build_role_response(
        self,
        role: Role,
        user_count: int
    ) -> RoleResponse:
        """Build a role response with HATEOAS links.

        Args:
            role: Role entity.
            user_count: Number of users with this role.

        Returns:
            Role response.
        """
        # Build permission summaries
        permission_summaries = []
        for perm in role.permissions:
            parts = perm.split(":")
            resource = parts[0] if len(parts) > 0 else ""
            action = parts[1] if len(parts) > 1 else ""

            permission_summaries.append(PermissionSummary(
                id=perm,
                name=perm,
                resource=resource,
                action=action
            ))

        # Build HATEOAS links
        if role.scope == RoleScope.PLATFORM:
            links = {
                "self": {"href": f"/v1/platform/roles/{role.role_id}"},
                "permissions": {"href": "/v1/platform/permissions"},
            }
        else:
            org_id = role.organisation_id
            links = {
                "self": {"href": f"/v1/organisations/{org_id}/roles/{role.role_id}"},
                "organisation": {"href": f"/v1/organisations/{org_id}"},
                "permissions": {
                    "href": f"/v1/organisations/{org_id}/roles/{role.role_id}/permissions",
                    "method": "PUT"
                },
                "users": {
                    "href": f"/v1/organisations/{org_id}/roles/{role.role_id}/users"
                },
                "update": {
                    "href": f"/v1/organisations/{org_id}/roles/{role.role_id}",
                    "method": "PUT"
                },
            }

        return RoleResponse(
            id=role.role_id,
            name=role.name,
            display_name=role.display_name,
            description=role.description,
            organisation_id=role.organisation_id,
            scope=role.scope.value,
            permissions=permission_summaries,
            is_system=role.is_system,
            is_default=role.is_default,
            priority=role.priority,
            user_count=user_count,
            active=role.active,
            date_created=role.date_created.isoformat() + "Z",
            date_last_updated=role.date_last_updated.isoformat() + "Z",
            links=links
        )

    def _build_platform_list_links(
        self,
        pagination: PaginationParams,
        next_cursor: Optional[str]
    ) -> Dict[str, Any]:
        """Build HATEOAS links for platform role list."""
        links = {
            "self": {"href": "/v1/platform/roles"}
        }

        if next_cursor:
            links["next"] = {
                "href": f"/v1/platform/roles?startAt={next_cursor}&pageSize={pagination.page_size}"
            }

        return links

    def _build_org_list_links(
        self,
        org_id: str,
        pagination: PaginationParams,
        next_cursor: Optional[str]
    ) -> Dict[str, Any]:
        """Build HATEOAS links for org role list."""
        links = {
            "self": {"href": f"/v1/organisations/{org_id}/roles"},
            "organisation": {"href": f"/v1/organisations/{org_id}"},
        }

        if next_cursor:
            links["next"] = {
                "href": f"/v1/organisations/{org_id}/roles?startAt={next_cursor}&pageSize={pagination.page_size}"
            }

        return links
```

### 5.3 src/services/permission_bundler.py

```python
"""Permission bundling service for additive permission union."""

from typing import Set, List
import re
import logging

logger = logging.getLogger(__name__)


class PermissionBundler:
    """Service for bundling and evaluating permissions."""

    def bundle_permissions(self, permission_sets: List[Set[str]]) -> Set[str]:
        """Bundle multiple permission sets into one (additive union).

        Args:
            permission_sets: List of permission sets from roles.

        Returns:
            Union of all permissions.
        """
        combined: Set[str] = set()

        for perm_set in permission_sets:
            combined.update(perm_set)

        return combined

    def has_permission(
        self,
        user_permissions: Set[str],
        required_permission: str
    ) -> bool:
        """Check if user has a specific permission.

        Supports wildcard matching:
        - "site:*" matches any site action
        - "*:read" matches read on any resource
        - "*:*" matches everything

        Args:
            user_permissions: User's permission set.
            required_permission: Permission to check.

        Returns:
            True if user has permission.
        """
        # Direct match
        if required_permission in user_permissions:
            return True

        # Check for wildcard matches
        req_parts = required_permission.split(":")
        if len(req_parts) != 2:
            return False

        req_resource, req_action = req_parts

        for perm in user_permissions:
            perm_parts = perm.split(":")
            if len(perm_parts) != 2:
                continue

            perm_resource, perm_action = perm_parts

            # Check resource match (exact or wildcard)
            resource_match = (
                perm_resource == "*" or
                perm_resource == req_resource
            )

            # Check action match (exact or wildcard)
            action_match = (
                perm_action == "*" or
                perm_action == req_action
            )

            if resource_match and action_match:
                return True

        return False

    def expand_wildcards(self, permissions: Set[str]) -> Set[str]:
        """Expand wildcard permissions for display purposes.

        Note: In practice, wildcard evaluation happens at check time,
        not by pre-expanding. This is for display/audit purposes.

        Args:
            permissions: Set of permissions (may include wildcards).

        Returns:
            Same set (wildcards kept as-is for storage efficiency).
        """
        # Wildcards are stored as-is and evaluated at check time
        return permissions

    def validate_permission_format(self, permission: str) -> bool:
        """Validate permission follows resource:action format.

        Args:
            permission: Permission string to validate.

        Returns:
            True if valid format.
        """
        pattern = r"^[a-z*]+:[a-z*]+$"
        return bool(re.match(pattern, permission))
```

---

## 6. Platform Role Handlers

### 6.1 src/handlers/__init__.py

```python
"""Handlers package for Role Service Lambda functions."""
```

### 6.2 src/handlers/platform/__init__.py

```python
"""Platform role handlers."""

from .list_platform_roles import lambda_handler as list_platform_roles_handler
from .get_platform_role import lambda_handler as get_platform_role_handler

__all__ = ["list_platform_roles_handler", "get_platform_role_handler"]
```

### 6.3 src/handlers/platform/list_platform_roles.py

```python
"""Lambda handler for listing platform roles."""

import json
import logging
from typing import Any, Dict

from aws_lambda_powertools import Logger, Tracer
from aws_lambda_powertools.utilities.typing import LambdaContext

from ...services.role_service import RoleService
from ...models.requests import PaginationParams
from ...utils.response_builder import ResponseBuilder
from ...exceptions import RoleServiceException

logger = Logger()
tracer = Tracer()


@logger.inject_lambda_context
@tracer.capture_lambda_handler
def lambda_handler(event: Dict[str, Any], context: LambdaContext) -> Dict[str, Any]:
    """Handle GET /v1/platform/roles request.

    Args:
        event: API Gateway event.
        context: Lambda context.

    Returns:
        API Gateway response.
    """
    try:
        # Parse query parameters
        query_params = event.get("queryStringParameters") or {}

        pagination = PaginationParams(
            page_size=int(query_params.get("pageSize", 50)),
            start_at=query_params.get("startAt")
        )

        # Call service
        role_service = RoleService()
        result = role_service.list_platform_roles(pagination)

        # Build response
        response_body = {
            "items": [item.model_dump(by_alias=True) for item in result.items],
            "startAt": result.start_at,
            "moreAvailable": result.more_available,
            "count": result.count,
            "_links": result.links
        }

        return ResponseBuilder.success(response_body, status_code=200)

    except RoleServiceException as e:
        logger.error(f"Role service error: {e.message}")
        return ResponseBuilder.error(
            e.error_code,
            e.message,
            e.status_code
        )

    except Exception as e:
        logger.exception("Unexpected error listing platform roles")
        return ResponseBuilder.error(
            "INTERNAL_ERROR",
            "Internal server error",
            500
        )
```

### 6.4 src/handlers/platform/get_platform_role.py

```python
"""Lambda handler for getting a platform role."""

import json
import logging
from typing import Any, Dict

from aws_lambda_powertools import Logger, Tracer
from aws_lambda_powertools.utilities.typing import LambdaContext

from ...services.role_service import RoleService
from ...utils.response_builder import ResponseBuilder
from ...exceptions import RoleServiceException, RoleNotFoundException

logger = Logger()
tracer = Tracer()


@logger.inject_lambda_context
@tracer.capture_lambda_handler
def lambda_handler(event: Dict[str, Any], context: LambdaContext) -> Dict[str, Any]:
    """Handle GET /v1/platform/roles/{roleId} request.

    Args:
        event: API Gateway event.
        context: Lambda context.

    Returns:
        API Gateway response.
    """
    try:
        # Extract path parameters
        path_params = event.get("pathParameters") or {}
        role_id = path_params.get("roleId")

        if not role_id:
            return ResponseBuilder.error(
                "VALIDATION_ERROR",
                "roleId is required",
                400
            )

        # Call service
        role_service = RoleService()
        result = role_service.get_platform_role(role_id)

        return ResponseBuilder.success(
            result.model_dump(by_alias=True),
            status_code=200
        )

    except RoleNotFoundException as e:
        logger.warning(f"Platform role not found: {e.role_id}")
        return ResponseBuilder.error(
            e.error_code,
            e.message,
            e.status_code
        )

    except RoleServiceException as e:
        logger.error(f"Role service error: {e.message}")
        return ResponseBuilder.error(
            e.error_code,
            e.message,
            e.status_code
        )

    except Exception as e:
        logger.exception("Unexpected error getting platform role")
        return ResponseBuilder.error(
            "INTERNAL_ERROR",
            "Internal server error",
            500
        )
```

---

## 7. Organisation Role Handlers

### 7.1 src/handlers/organisation/__init__.py

```python
"""Organisation role handlers."""

from .create_role import lambda_handler as create_role_handler
from .list_roles import lambda_handler as list_roles_handler
from .get_role import lambda_handler as get_role_handler
from .update_role import lambda_handler as update_role_handler
from .delete_role import lambda_handler as delete_role_handler
from .seed_roles import lambda_handler as seed_roles_handler

__all__ = [
    "create_role_handler",
    "list_roles_handler",
    "get_role_handler",
    "update_role_handler",
    "delete_role_handler",
    "seed_roles_handler",
]
```

### 7.2 src/handlers/organisation/create_role.py

```python
"""Lambda handler for creating organisation roles."""

import json
from typing import Any, Dict

from aws_lambda_powertools import Logger, Tracer
from aws_lambda_powertools.utilities.typing import LambdaContext
from pydantic import ValidationError

from ...services.role_service import RoleService
from ...models.requests import CreateRoleRequest
from ...utils.response_builder import ResponseBuilder
from ...utils.validators import validate_org_access
from ...exceptions import (
    RoleServiceException,
    DuplicateRoleNameException,
    InvalidPermissionException,
    UnauthorizedOrgAccessException,
)

logger = Logger()
tracer = Tracer()


@logger.inject_lambda_context
@tracer.capture_lambda_handler
def lambda_handler(event: Dict[str, Any], context: LambdaContext) -> Dict[str, Any]:
    """Handle POST /v1/organisations/{orgId}/roles request.

    Args:
        event: API Gateway event.
        context: Lambda context.

    Returns:
        API Gateway response.
    """
    try:
        # Extract path parameters
        path_params = event.get("pathParameters") or {}
        org_id = path_params.get("orgId")

        if not org_id:
            return ResponseBuilder.error(
                "VALIDATION_ERROR",
                "orgId is required",
                400
            )

        # Extract auth context
        request_context = event.get("requestContext", {})
        authorizer = request_context.get("authorizer", {})
        user_email = authorizer.get("email", "system")
        user_org_id = authorizer.get("orgId")

        # Validate org access
        if user_org_id and user_org_id != org_id:
            raise UnauthorizedOrgAccessException(user_org_id, org_id)

        # Parse request body
        body = json.loads(event.get("body") or "{}")
        request = CreateRoleRequest(**body)

        # Call service
        role_service = RoleService()
        result = role_service.create_role(org_id, request, user_email)

        logger.info(f"Created role {result.id} in org {org_id}")

        return ResponseBuilder.success(
            result.model_dump(by_alias=True),
            status_code=201
        )

    except ValidationError as e:
        logger.warning(f"Validation error: {e}")
        return ResponseBuilder.error(
            "VALIDATION_ERROR",
            str(e),
            400
        )

    except (DuplicateRoleNameException, InvalidPermissionException) as e:
        logger.warning(f"Business error: {e.message}")
        return ResponseBuilder.error(
            e.error_code,
            e.message,
            e.status_code
        )

    except UnauthorizedOrgAccessException as e:
        logger.warning(f"Unauthorized access attempt: {e.message}")
        return ResponseBuilder.error(
            e.error_code,
            e.message,
            e.status_code
        )

    except RoleServiceException as e:
        logger.error(f"Role service error: {e.message}")
        return ResponseBuilder.error(
            e.error_code,
            e.message,
            e.status_code
        )

    except Exception as e:
        logger.exception("Unexpected error creating role")
        return ResponseBuilder.error(
            "INTERNAL_ERROR",
            "Internal server error",
            500
        )
```

### 7.3 src/handlers/organisation/list_roles.py

```python
"""Lambda handler for listing organisation roles."""

import json
from typing import Any, Dict

from aws_lambda_powertools import Logger, Tracer
from aws_lambda_powertools.utilities.typing import LambdaContext

from ...services.role_service import RoleService
from ...models.requests import RoleFilters, PaginationParams
from ...models.role import RoleScope
from ...utils.response_builder import ResponseBuilder
from ...exceptions import RoleServiceException, UnauthorizedOrgAccessException

logger = Logger()
tracer = Tracer()


@logger.inject_lambda_context
@tracer.capture_lambda_handler
def lambda_handler(event: Dict[str, Any], context: LambdaContext) -> Dict[str, Any]:
    """Handle GET /v1/organisations/{orgId}/roles request.

    Args:
        event: API Gateway event.
        context: Lambda context.

    Returns:
        API Gateway response.
    """
    try:
        # Extract path parameters
        path_params = event.get("pathParameters") or {}
        org_id = path_params.get("orgId")

        if not org_id:
            return ResponseBuilder.error(
                "VALIDATION_ERROR",
                "orgId is required",
                400
            )

        # Extract auth context
        request_context = event.get("requestContext", {})
        authorizer = request_context.get("authorizer", {})
        user_org_id = authorizer.get("orgId")

        # Validate org access
        if user_org_id and user_org_id != org_id:
            raise UnauthorizedOrgAccessException(user_org_id, org_id)

        # Parse query parameters
        query_params = event.get("queryStringParameters") or {}

        scope = None
        if query_params.get("scope"):
            scope = RoleScope(query_params["scope"])

        filters = RoleFilters(
            scope=scope,
            include_inactive=query_params.get("includeInactive", "false").lower() == "true"
        )

        pagination = PaginationParams(
            page_size=int(query_params.get("pageSize", 50)),
            start_at=query_params.get("startAt")
        )

        # Call service
        role_service = RoleService()
        result = role_service.list_roles(org_id, filters, pagination)

        # Build response
        response_body = {
            "items": [item.model_dump(by_alias=True) for item in result.items],
            "startAt": result.start_at,
            "moreAvailable": result.more_available,
            "count": result.count,
            "_links": result.links
        }

        return ResponseBuilder.success(response_body, status_code=200)

    except UnauthorizedOrgAccessException as e:
        logger.warning(f"Unauthorized access attempt: {e.message}")
        return ResponseBuilder.error(
            e.error_code,
            e.message,
            e.status_code
        )

    except RoleServiceException as e:
        logger.error(f"Role service error: {e.message}")
        return ResponseBuilder.error(
            e.error_code,
            e.message,
            e.status_code
        )

    except Exception as e:
        logger.exception("Unexpected error listing roles")
        return ResponseBuilder.error(
            "INTERNAL_ERROR",
            "Internal server error",
            500
        )
```

### 7.4 src/handlers/organisation/get_role.py

```python
"""Lambda handler for getting an organisation role."""

from typing import Any, Dict

from aws_lambda_powertools import Logger, Tracer
from aws_lambda_powertools.utilities.typing import LambdaContext

from ...services.role_service import RoleService
from ...utils.response_builder import ResponseBuilder
from ...exceptions import (
    RoleServiceException,
    RoleNotFoundException,
    UnauthorizedOrgAccessException,
)

logger = Logger()
tracer = Tracer()


@logger.inject_lambda_context
@tracer.capture_lambda_handler
def lambda_handler(event: Dict[str, Any], context: LambdaContext) -> Dict[str, Any]:
    """Handle GET /v1/organisations/{orgId}/roles/{roleId} request.

    Args:
        event: API Gateway event.
        context: Lambda context.

    Returns:
        API Gateway response.
    """
    try:
        # Extract path parameters
        path_params = event.get("pathParameters") or {}
        org_id = path_params.get("orgId")
        role_id = path_params.get("roleId")

        if not org_id:
            return ResponseBuilder.error(
                "VALIDATION_ERROR",
                "orgId is required",
                400
            )

        if not role_id:
            return ResponseBuilder.error(
                "VALIDATION_ERROR",
                "roleId is required",
                400
            )

        # Extract auth context
        request_context = event.get("requestContext", {})
        authorizer = request_context.get("authorizer", {})
        user_org_id = authorizer.get("orgId")

        # Validate org access
        if user_org_id and user_org_id != org_id:
            raise UnauthorizedOrgAccessException(user_org_id, org_id)

        # Call service
        role_service = RoleService()
        result = role_service.get_role(org_id, role_id)

        return ResponseBuilder.success(
            result.model_dump(by_alias=True),
            status_code=200
        )

    except RoleNotFoundException as e:
        logger.warning(f"Role not found: {e.role_id}")
        return ResponseBuilder.error(
            e.error_code,
            e.message,
            e.status_code
        )

    except UnauthorizedOrgAccessException as e:
        logger.warning(f"Unauthorized access attempt: {e.message}")
        return ResponseBuilder.error(
            e.error_code,
            e.message,
            e.status_code
        )

    except RoleServiceException as e:
        logger.error(f"Role service error: {e.message}")
        return ResponseBuilder.error(
            e.error_code,
            e.message,
            e.status_code
        )

    except Exception as e:
        logger.exception("Unexpected error getting role")
        return ResponseBuilder.error(
            "INTERNAL_ERROR",
            "Internal server error",
            500
        )
```

### 7.5 src/handlers/organisation/update_role.py

```python
"""Lambda handler for updating an organisation role."""

import json
from typing import Any, Dict

from aws_lambda_powertools import Logger, Tracer
from aws_lambda_powertools.utilities.typing import LambdaContext
from pydantic import ValidationError

from ...services.role_service import RoleService
from ...models.requests import UpdateRoleRequest, AssignPermissionsRequest
from ...utils.response_builder import ResponseBuilder
from ...exceptions import (
    RoleServiceException,
    RoleNotFoundException,
    CannotModifySystemRoleException,
    RoleInUseException,
    InvalidPermissionException,
    UnauthorizedOrgAccessException,
)

logger = Logger()
tracer = Tracer()


@logger.inject_lambda_context
@tracer.capture_lambda_handler
def lambda_handler(event: Dict[str, Any], context: LambdaContext) -> Dict[str, Any]:
    """Handle PUT /v1/organisations/{orgId}/roles/{roleId} request.

    Also handles PUT /v1/organisations/{orgId}/roles/{roleId}/permissions.

    Args:
        event: API Gateway event.
        context: Lambda context.

    Returns:
        API Gateway response.
    """
    try:
        # Extract path parameters
        path_params = event.get("pathParameters") or {}
        org_id = path_params.get("orgId")
        role_id = path_params.get("roleId")

        if not org_id:
            return ResponseBuilder.error(
                "VALIDATION_ERROR",
                "orgId is required",
                400
            )

        if not role_id:
            return ResponseBuilder.error(
                "VALIDATION_ERROR",
                "roleId is required",
                400
            )

        # Extract auth context
        request_context = event.get("requestContext", {})
        authorizer = request_context.get("authorizer", {})
        user_email = authorizer.get("email", "system")
        user_org_id = authorizer.get("orgId")

        # Validate org access
        if user_org_id and user_org_id != org_id:
            raise UnauthorizedOrgAccessException(user_org_id, org_id)

        # Check if this is a permissions update
        path = event.get("path", "")
        is_permissions_update = path.endswith("/permissions")

        # Parse request body
        body = json.loads(event.get("body") or "{}")

        role_service = RoleService()

        if is_permissions_update:
            # Handle permissions assignment
            request = AssignPermissionsRequest(**body)
            result = role_service.assign_permissions(
                org_id, role_id, request.permissions, user_email
            )
        else:
            # Handle role update
            request = UpdateRoleRequest(**body)
            result = role_service.update_role(
                org_id, role_id, request, user_email
            )

        logger.info(f"Updated role {role_id} in org {org_id}")

        return ResponseBuilder.success(
            result.model_dump(by_alias=True),
            status_code=200
        )

    except ValidationError as e:
        logger.warning(f"Validation error: {e}")
        return ResponseBuilder.error(
            "VALIDATION_ERROR",
            str(e),
            400
        )

    except (RoleNotFoundException, CannotModifySystemRoleException,
            RoleInUseException, InvalidPermissionException) as e:
        logger.warning(f"Business error: {e.message}")
        return ResponseBuilder.error(
            e.error_code,
            e.message,
            e.status_code
        )

    except UnauthorizedOrgAccessException as e:
        logger.warning(f"Unauthorized access attempt: {e.message}")
        return ResponseBuilder.error(
            e.error_code,
            e.message,
            e.status_code
        )

    except RoleServiceException as e:
        logger.error(f"Role service error: {e.message}")
        return ResponseBuilder.error(
            e.error_code,
            e.message,
            e.status_code
        )

    except Exception as e:
        logger.exception("Unexpected error updating role")
        return ResponseBuilder.error(
            "INTERNAL_ERROR",
            "Internal server error",
            500
        )
```

### 7.6 src/handlers/organisation/delete_role.py

```python
"""Lambda handler for deleting (deactivating) an organisation role."""

from typing import Any, Dict

from aws_lambda_powertools import Logger, Tracer
from aws_lambda_powertools.utilities.typing import LambdaContext

from ...services.role_service import RoleService
from ...utils.response_builder import ResponseBuilder
from ...exceptions import (
    RoleServiceException,
    RoleNotFoundException,
    CannotModifySystemRoleException,
    RoleInUseException,
    UnauthorizedOrgAccessException,
)

logger = Logger()
tracer = Tracer()


@logger.inject_lambda_context
@tracer.capture_lambda_handler
def lambda_handler(event: Dict[str, Any], context: LambdaContext) -> Dict[str, Any]:
    """Handle DELETE /v1/organisations/{orgId}/roles/{roleId} request.

    Note: This performs a soft delete (sets active=false).

    Args:
        event: API Gateway event.
        context: Lambda context.

    Returns:
        API Gateway response.
    """
    try:
        # Extract path parameters
        path_params = event.get("pathParameters") or {}
        org_id = path_params.get("orgId")
        role_id = path_params.get("roleId")

        if not org_id:
            return ResponseBuilder.error(
                "VALIDATION_ERROR",
                "orgId is required",
                400
            )

        if not role_id:
            return ResponseBuilder.error(
                "VALIDATION_ERROR",
                "roleId is required",
                400
            )

        # Extract auth context
        request_context = event.get("requestContext", {})
        authorizer = request_context.get("authorizer", {})
        user_email = authorizer.get("email", "system")
        user_org_id = authorizer.get("orgId")

        # Validate org access
        if user_org_id and user_org_id != org_id:
            raise UnauthorizedOrgAccessException(user_org_id, org_id)

        # Call service
        role_service = RoleService()
        role_service.delete_role(org_id, role_id, user_email)

        logger.info(f"Deleted role {role_id} in org {org_id}")

        return ResponseBuilder.success(
            {"message": "Role deleted successfully"},
            status_code=200
        )

    except (RoleNotFoundException, CannotModifySystemRoleException,
            RoleInUseException) as e:
        logger.warning(f"Business error: {e.message}")
        return ResponseBuilder.error(
            e.error_code,
            e.message,
            e.status_code
        )

    except UnauthorizedOrgAccessException as e:
        logger.warning(f"Unauthorized access attempt: {e.message}")
        return ResponseBuilder.error(
            e.error_code,
            e.message,
            e.status_code
        )

    except RoleServiceException as e:
        logger.error(f"Role service error: {e.message}")
        return ResponseBuilder.error(
            e.error_code,
            e.message,
            e.status_code
        )

    except Exception as e:
        logger.exception("Unexpected error deleting role")
        return ResponseBuilder.error(
            "INTERNAL_ERROR",
            "Internal server error",
            500
        )
```

### 7.7 src/handlers/organisation/seed_roles.py

```python
"""Lambda handler for seeding default organisation roles."""

from typing import Any, Dict

from aws_lambda_powertools import Logger, Tracer
from aws_lambda_powertools.utilities.typing import LambdaContext

from ...services.role_service import RoleService
from ...utils.response_builder import ResponseBuilder
from ...exceptions import RoleServiceException, UnauthorizedOrgAccessException

logger = Logger()
tracer = Tracer()


@logger.inject_lambda_context
@tracer.capture_lambda_handler
def lambda_handler(event: Dict[str, Any], context: LambdaContext) -> Dict[str, Any]:
    """Handle POST /v1/organisations/{orgId}/roles/seed request.

    Seeds default roles for an organisation. Typically called during
    organisation creation.

    Args:
        event: API Gateway event.
        context: Lambda context.

    Returns:
        API Gateway response.
    """
    try:
        # Extract path parameters
        path_params = event.get("pathParameters") or {}
        org_id = path_params.get("orgId")

        if not org_id:
            return ResponseBuilder.error(
                "VALIDATION_ERROR",
                "orgId is required",
                400
            )

        # Extract auth context
        request_context = event.get("requestContext", {})
        authorizer = request_context.get("authorizer", {})
        user_email = authorizer.get("email", "system")
        user_org_id = authorizer.get("orgId")

        # Validate org access (platform admins or org admins can seed)
        if user_org_id and user_org_id != org_id:
            raise UnauthorizedOrgAccessException(user_org_id, org_id)

        # Call service
        role_service = RoleService()
        results = role_service.seed_default_roles(org_id, user_email)

        logger.info(f"Seeded {len(results)} default roles in org {org_id}")

        # Build response
        response_body = {
            "message": f"Seeded {len(results)} default roles",
            "roles": [r.model_dump(by_alias=True) for r in results],
            "_links": {
                "self": {"href": f"/v1/organisations/{org_id}/roles/seed"},
                "roles": {"href": f"/v1/organisations/{org_id}/roles"}
            }
        }

        return ResponseBuilder.success(response_body, status_code=201)

    except UnauthorizedOrgAccessException as e:
        logger.warning(f"Unauthorized access attempt: {e.message}")
        return ResponseBuilder.error(
            e.error_code,
            e.message,
            e.status_code
        )

    except RoleServiceException as e:
        logger.error(f"Role service error: {e.message}")
        return ResponseBuilder.error(
            e.error_code,
            e.message,
            e.status_code
        )

    except Exception as e:
        logger.exception("Unexpected error seeding roles")
        return ResponseBuilder.error(
            "INTERNAL_ERROR",
            "Internal server error",
            500
        )
```

---

## 8. Utility Modules

### 8.1 src/utils/__init__.py

```python
"""Utility package for Role Service."""

from .response_builder import ResponseBuilder
from .validators import validate_org_access, validate_uuid
from .hateoas import HateoasBuilder

__all__ = [
    "ResponseBuilder",
    "validate_org_access",
    "validate_uuid",
    "HateoasBuilder",
]
```

### 8.2 src/utils/response_builder.py

```python
"""Response builder for API Gateway responses."""

import json
from typing import Any, Dict, Optional


class ResponseBuilder:
    """Builder for standardized API Gateway responses."""

    @staticmethod
    def success(
        body: Any,
        status_code: int = 200,
        headers: Optional[Dict[str, str]] = None
    ) -> Dict[str, Any]:
        """Build a success response.

        Args:
            body: Response body (will be JSON serialized).
            status_code: HTTP status code.
            headers: Optional additional headers.

        Returns:
            API Gateway response dict.
        """
        default_headers = {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Headers": "Content-Type,Authorization",
            "Access-Control-Allow-Methods": "GET,POST,PUT,DELETE,OPTIONS",
        }

        if headers:
            default_headers.update(headers)

        return {
            "statusCode": status_code,
            "headers": default_headers,
            "body": json.dumps(body, default=str)
        }

    @staticmethod
    def error(
        error_code: str,
        message: str,
        status_code: int = 400,
        details: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """Build an error response.

        Args:
            error_code: Application error code.
            message: Human-readable error message.
            status_code: HTTP status code.
            details: Optional additional error details.

        Returns:
            API Gateway response dict.
        """
        body = {
            "errorCode": error_code,
            "message": message,
        }

        if details:
            body["details"] = details

        return {
            "statusCode": status_code,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*",
            },
            "body": json.dumps(body)
        }

    @staticmethod
    def no_content() -> Dict[str, Any]:
        """Build a 204 No Content response.

        Returns:
            API Gateway response dict.
        """
        return {
            "statusCode": 204,
            "headers": {
                "Access-Control-Allow-Origin": "*",
            },
            "body": ""
        }
```

### 8.3 src/utils/validators.py

```python
"""Validation utilities for Role Service."""

import re
from typing import Optional
from ..exceptions import ValidationException, UnauthorizedOrgAccessException


def validate_org_access(user_org_id: Optional[str], target_org_id: str) -> None:
    """Validate user has access to target organisation.

    Args:
        user_org_id: User's organisation ID from auth context.
        target_org_id: Target organisation ID from path.

    Raises:
        UnauthorizedOrgAccessException: If user not authorized.
    """
    if user_org_id and user_org_id != target_org_id:
        raise UnauthorizedOrgAccessException(user_org_id, target_org_id)


def validate_uuid(value: str, field_name: str = "id") -> str:
    """Validate value is a valid UUID format.

    Args:
        value: Value to validate.
        field_name: Name of field for error message.

    Returns:
        The validated value.

    Raises:
        ValidationException: If not valid UUID.
    """
    uuid_pattern = r"^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$"

    # Also accept our prefixed format like "role-{uuid}"
    prefixed_pattern = r"^[a-z]+-[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$"

    if not (re.match(uuid_pattern, value, re.IGNORECASE) or
            re.match(prefixed_pattern, value, re.IGNORECASE)):
        raise ValidationException(
            f"Invalid {field_name} format: {value}",
            field=field_name
        )

    return value


def validate_role_name(name: str) -> str:
    """Validate role name format.

    Args:
        name: Role name to validate.

    Returns:
        The validated name.

    Raises:
        ValidationException: If name format invalid.
    """
    pattern = r"^[A-Z][A-Z0-9_]*$"

    if not re.match(pattern, name):
        raise ValidationException(
            "Role name must start with uppercase letter and contain only "
            "uppercase letters, numbers, and underscores",
            field="name"
        )

    if len(name) < 2 or len(name) > 50:
        raise ValidationException(
            "Role name must be between 2 and 50 characters",
            field="name"
        )

    return name


def validate_permission_format(permission: str) -> str:
    """Validate permission follows resource:action format.

    Args:
        permission: Permission string to validate.

    Returns:
        The validated permission.

    Raises:
        ValidationException: If format invalid.
    """
    pattern = r"^[a-z*]+:[a-z*]+$"

    if not re.match(pattern, permission):
        raise ValidationException(
            f"Invalid permission format: {permission}. "
            "Must be resource:action (e.g., site:read)",
            field="permissions"
        )

    return permission
```

### 8.4 src/utils/hateoas.py

```python
"""HATEOAS link builder utilities."""

from typing import Dict, Any, Optional


class HateoasBuilder:
    """Builder for HATEOAS links."""

    @staticmethod
    def build_platform_role_links(role_id: str) -> Dict[str, Any]:
        """Build links for a platform role.

        Args:
            role_id: The role ID.

        Returns:
            Dictionary of HATEOAS links.
        """
        return {
            "self": {"href": f"/v1/platform/roles/{role_id}"},
            "permissions": {"href": "/v1/platform/permissions"},
        }

    @staticmethod
    def build_org_role_links(org_id: str, role_id: str) -> Dict[str, Any]:
        """Build links for an organisation role.

        Args:
            org_id: Organisation ID.
            role_id: Role ID.

        Returns:
            Dictionary of HATEOAS links.
        """
        return {
            "self": {"href": f"/v1/organisations/{org_id}/roles/{role_id}"},
            "organisation": {"href": f"/v1/organisations/{org_id}"},
            "permissions": {
                "href": f"/v1/organisations/{org_id}/roles/{role_id}/permissions",
                "method": "PUT"
            },
            "users": {
                "href": f"/v1/organisations/{org_id}/roles/{role_id}/users"
            },
            "update": {
                "href": f"/v1/organisations/{org_id}/roles/{role_id}",
                "method": "PUT"
            },
        }

    @staticmethod
    def build_role_list_links(
        base_path: str,
        page_size: int,
        next_cursor: Optional[str] = None
    ) -> Dict[str, Any]:
        """Build links for a role list response.

        Args:
            base_path: Base API path.
            page_size: Page size used.
            next_cursor: Next page cursor if available.

        Returns:
            Dictionary of HATEOAS links.
        """
        links = {
            "self": {"href": base_path}
        }

        if next_cursor:
            links["next"] = {
                "href": f"{base_path}?startAt={next_cursor}&pageSize={page_size}"
            }

        return links
```

---

## 9. Unit Tests

### 9.1 tests/__init__.py

```python
"""Tests package for Role Service."""
```

### 9.2 tests/conftest.py

```python
"""Pytest fixtures for Role Service tests."""

import pytest
import boto3
from moto import mock_aws
import os
from datetime import datetime

from src.models.role import Role, RoleScope
from src.models.user_role_assignment import UserRoleAssignment


@pytest.fixture(scope="function")
def aws_credentials():
    """Mocked AWS Credentials for moto."""
    os.environ["AWS_ACCESS_KEY_ID"] = "testing"
    os.environ["AWS_SECRET_ACCESS_KEY"] = "testing"
    os.environ["AWS_SECURITY_TOKEN"] = "testing"
    os.environ["AWS_SESSION_TOKEN"] = "testing"
    os.environ["AWS_DEFAULT_REGION"] = "af-south-1"


@pytest.fixture(scope="function")
def dynamodb_table(aws_credentials):
    """Create a mocked DynamoDB table."""
    with mock_aws():
        dynamodb = boto3.resource("dynamodb", region_name="af-south-1")

        table_name = "bbws-aipagebuilder-dev-ddb-access-management"
        os.environ["DYNAMODB_TABLE_NAME"] = table_name

        table = dynamodb.create_table(
            TableName=table_name,
            KeySchema=[
                {"AttributeName": "PK", "KeyType": "HASH"},
                {"AttributeName": "SK", "KeyType": "RANGE"},
            ],
            AttributeDefinitions=[
                {"AttributeName": "PK", "AttributeType": "S"},
                {"AttributeName": "SK", "AttributeType": "S"},
                {"AttributeName": "GSI1PK", "AttributeType": "S"},
                {"AttributeName": "GSI1SK", "AttributeType": "S"},
            ],
            GlobalSecondaryIndexes=[
                {
                    "IndexName": "GSI1",
                    "KeySchema": [
                        {"AttributeName": "GSI1PK", "KeyType": "HASH"},
                        {"AttributeName": "GSI1SK", "KeyType": "RANGE"},
                    ],
                    "Projection": {"ProjectionType": "ALL"},
                }
            ],
            BillingMode="PAY_PER_REQUEST",
        )

        table.meta.client.get_waiter("table_exists").wait(TableName=table_name)

        yield table


@pytest.fixture
def sample_platform_role():
    """Create a sample platform role."""
    return Role(
        role_id="role-platform-admin-001",
        name="PLATFORM_ADMIN",
        display_name="Platform Administrator",
        description="Full platform access",
        organisation_id=None,
        scope=RoleScope.PLATFORM,
        permissions=["org:create", "org:read", "org:update", "org:delete"],
        is_system=True,
        is_default=False,
        priority=1,
        active=True,
        date_created=datetime.utcnow(),
        date_last_updated=datetime.utcnow(),
    )


@pytest.fixture
def sample_org_role():
    """Create a sample organisation role."""
    return Role(
        role_id="role-test-12345678-1234-1234-1234-123456789012",
        name="ORG_ADMIN",
        display_name="Organisation Admin",
        description="Full organisation access",
        organisation_id="org-12345678-1234-1234-1234-123456789012",
        scope=RoleScope.ORGANISATION,
        permissions=["org:read", "org:update", "user:create", "user:read"],
        is_system=False,
        is_default=True,
        priority=1,
        active=True,
        date_created=datetime.utcnow(),
        date_last_updated=datetime.utcnow(),
        created_by="admin@test.com",
        last_updated_by="admin@test.com",
    )


@pytest.fixture
def sample_user_role_assignment():
    """Create a sample user role assignment."""
    return UserRoleAssignment(
        organisation_id="org-12345678-1234-1234-1234-123456789012",
        user_id="user-12345678-1234-1234-1234-123456789012",
        role_id="role-test-12345678-1234-1234-1234-123456789012",
        role_name="ORG_ADMIN",
        scope=RoleScope.ORGANISATION,
        assigned_by="admin@test.com",
        assigned_at=datetime.utcnow(),
        active=True,
    )


@pytest.fixture
def api_gateway_event():
    """Create a sample API Gateway event."""
    def _event(
        method="GET",
        path="/v1/organisations/org-123/roles",
        path_params=None,
        query_params=None,
        body=None,
        authorizer=None
    ):
        return {
            "httpMethod": method,
            "path": path,
            "pathParameters": path_params or {},
            "queryStringParameters": query_params,
            "body": body,
            "requestContext": {
                "authorizer": authorizer or {
                    "email": "test@example.com",
                    "orgId": "org-123"
                }
            }
        }
    return _event
```

### 9.3 tests/unit/test_models.py

```python
"""Unit tests for Role models - TDD style."""

import pytest
from datetime import datetime
from pydantic import ValidationError

from src.models.role import Role, RoleScope, PlatformRole, OrganisationRole
from src.models.requests import CreateRoleRequest, UpdateRoleRequest
from src.models.user_role_assignment import UserRoleAssignment


class TestRoleScope:
    """Tests for RoleScope enum."""

    def test_platform_scope_value(self):
        """Test PLATFORM scope has correct value."""
        assert RoleScope.PLATFORM.value == "PLATFORM"

    def test_organisation_scope_value(self):
        """Test ORGANISATION scope has correct value."""
        assert RoleScope.ORGANISATION.value == "ORGANISATION"

    def test_team_scope_value(self):
        """Test TEAM scope has correct value."""
        assert RoleScope.TEAM.value == "TEAM"


class TestRole:
    """Tests for Role model."""

    def test_create_role_with_required_fields(self):
        """Test creating role with minimum required fields."""
        role = Role(
            name="TEST_ROLE",
            display_name="Test Role"
        )

        assert role.name == "TEST_ROLE"
        assert role.display_name == "Test Role"
        assert role.role_id.startswith("role-")
        assert role.scope == RoleScope.ORGANISATION
        assert role.is_system is False
        assert role.active is True

    def test_role_name_validation_uppercase(self):
        """Test role name must be uppercase."""
        with pytest.raises(ValidationError):
            Role(name="lowercase", display_name="Test")

    def test_role_name_validation_starts_with_letter(self):
        """Test role name must start with letter."""
        with pytest.raises(ValidationError):
            Role(name="1ROLE", display_name="Test")

    def test_role_name_allows_underscores(self):
        """Test role name can contain underscores."""
        role = Role(name="TEST_ROLE_NAME", display_name="Test")
        assert role.name == "TEST_ROLE_NAME"

    def test_role_name_allows_numbers(self):
        """Test role name can contain numbers."""
        role = Role(name="ROLE123", display_name="Test")
        assert role.name == "ROLE123"

    def test_role_to_dynamodb_item(self, sample_org_role):
        """Test conversion to DynamoDB item format."""
        item = sample_org_role.to_dynamodb_item()

        assert item["PK"] == f"ORG#{sample_org_role.organisation_id}"
        assert item["SK"] == f"ROLE#{sample_org_role.role_id}"
        assert item["name"] == sample_org_role.name
        assert item["displayName"] == sample_org_role.display_name
        assert "GSI1PK" in item
        assert "GSI1SK" in item

    def test_role_from_dynamodb_item(self):
        """Test creation from DynamoDB item."""
        item = {
            "PK": "ORG#org-123",
            "SK": "ROLE#role-456",
            "roleId": "role-456",
            "name": "TEST_ROLE",
            "displayName": "Test Role",
            "description": "A test role",
            "organisationId": "org-123",
            "scope": "ORGANISATION",
            "permissions": ["site:read"],
            "isSystem": False,
            "isDefault": False,
            "priority": 100,
            "active": True,
            "dateCreated": "2026-01-23T10:00:00Z",
            "dateLastUpdated": "2026-01-23T10:00:00Z",
        }

        role = Role.from_dynamodb_item(item)

        assert role.role_id == "role-456"
        assert role.name == "TEST_ROLE"
        assert role.organisation_id == "org-123"
        assert role.scope == RoleScope.ORGANISATION


class TestPlatformRole:
    """Tests for PlatformRole model."""

    def test_platform_role_has_platform_scope(self):
        """Test platform role scope is PLATFORM."""
        role = PlatformRole(
            name="PLATFORM_ADMIN",
            display_name="Platform Admin"
        )
        assert role.scope == RoleScope.PLATFORM

    def test_platform_role_is_system(self):
        """Test platform role is system role."""
        role = PlatformRole(
            name="PLATFORM_ADMIN",
            display_name="Platform Admin"
        )
        assert role.is_system is True


class TestCreateRoleRequest:
    """Tests for CreateRoleRequest model."""

    def test_create_request_with_valid_data(self):
        """Test creating request with valid data."""
        request = CreateRoleRequest(
            name="CUSTOM_ROLE",
            display_name="Custom Role",
            permissions=["site:read", "site:update"]
        )

        assert request.name == "CUSTOM_ROLE"
        assert len(request.permissions) == 2

    def test_create_request_requires_permissions(self):
        """Test permissions are required."""
        with pytest.raises(ValidationError):
            CreateRoleRequest(
                name="CUSTOM_ROLE",
                display_name="Custom Role",
                permissions=[]
            )

    def test_create_request_validates_name_format(self):
        """Test name format validation."""
        with pytest.raises(ValidationError):
            CreateRoleRequest(
                name="invalid-name",
                display_name="Custom Role",
                permissions=["site:read"]
            )


class TestUpdateRoleRequest:
    """Tests for UpdateRoleRequest model."""

    def test_update_request_all_fields_optional(self):
        """Test all fields are optional."""
        request = UpdateRoleRequest()
        assert request.display_name is None
        assert request.active is None

    def test_update_request_validates_priority_range(self):
        """Test priority must be between 1 and 999."""
        with pytest.raises(ValidationError):
            UpdateRoleRequest(priority=0)

        with pytest.raises(ValidationError):
            UpdateRoleRequest(priority=1000)


class TestUserRoleAssignment:
    """Tests for UserRoleAssignment model."""

    def test_create_assignment(self):
        """Test creating user role assignment."""
        assignment = UserRoleAssignment(
            organisation_id="org-123",
            user_id="user-456",
            role_id="role-789",
            role_name="ORG_ADMIN",
            scope=RoleScope.ORGANISATION,
            assigned_by="admin@test.com"
        )

        assert assignment.organisation_id == "org-123"
        assert assignment.user_id == "user-456"
        assert assignment.active is True

    def test_assignment_to_dynamodb_item(self, sample_user_role_assignment):
        """Test conversion to DynamoDB item."""
        item = sample_user_role_assignment.to_dynamodb_item()

        assert "ORG#" in item["PK"]
        assert "USER#" in item["PK"]
        assert item["SK"].startswith("ROLE#")
        assert "GSI1PK" in item
```

### 9.4 tests/unit/test_role_repository.py

```python
"""Unit tests for RoleRepository - TDD style."""

import pytest
from moto import mock_aws

from src.repositories.role_repository import RoleRepository
from src.models.role import Role, RoleScope


@pytest.mark.usefixtures("dynamodb_table")
class TestRoleRepository:
    """Tests for RoleRepository."""

    def test_save_role(self, dynamodb_table, sample_org_role):
        """Test saving a role to DynamoDB."""
        repo = RoleRepository()
        saved = repo.save(sample_org_role)

        assert saved.role_id == sample_org_role.role_id
        assert saved.name == sample_org_role.name

    def test_find_by_id_returns_role(self, dynamodb_table, sample_org_role):
        """Test finding role by ID."""
        repo = RoleRepository()
        repo.save(sample_org_role)

        found = repo.find_by_id(
            sample_org_role.role_id,
            sample_org_role.organisation_id
        )

        assert found is not None
        assert found.role_id == sample_org_role.role_id

    def test_find_by_id_returns_none_when_not_found(self, dynamodb_table):
        """Test finding non-existent role returns None."""
        repo = RoleRepository()
        found = repo.find_by_id("nonexistent-id", "org-123")

        assert found is None

    def test_find_by_name(self, dynamodb_table, sample_org_role):
        """Test finding role by name."""
        repo = RoleRepository()
        repo.save(sample_org_role)

        found = repo.find_by_name(
            sample_org_role.name,
            sample_org_role.organisation_id
        )

        assert found is not None
        assert found.name == sample_org_role.name

    def test_find_by_org_id(self, dynamodb_table):
        """Test listing roles by organisation."""
        repo = RoleRepository()
        org_id = "org-test-123"

        # Create multiple roles
        for i in range(3):
            role = Role(
                name=f"ROLE_{i}",
                display_name=f"Role {i}",
                organisation_id=org_id,
                scope=RoleScope.ORGANISATION,
                permissions=["site:read"]
            )
            repo.save(role)

        roles, cursor = repo.find_by_org_id(org_id)

        assert len(roles) == 3

    def test_find_by_org_id_with_pagination(self, dynamodb_table):
        """Test pagination when listing roles."""
        repo = RoleRepository()
        org_id = "org-test-456"

        # Create 5 roles
        for i in range(5):
            role = Role(
                name=f"ROLE_P{i}",
                display_name=f"Role {i}",
                organisation_id=org_id,
                scope=RoleScope.ORGANISATION,
                permissions=["site:read"]
            )
            repo.save(role)

        # Get first page
        roles, cursor = repo.find_by_org_id(org_id, page_size=2)

        assert len(roles) == 2
        # Note: cursor may or may not be set depending on DynamoDB behavior

    def test_find_platform_roles(self, dynamodb_table, sample_platform_role):
        """Test listing platform roles."""
        repo = RoleRepository()
        repo.save(sample_platform_role)

        roles, cursor = repo.find_platform_roles()

        assert len(roles) >= 1
        assert any(r.name == "PLATFORM_ADMIN" for r in roles)

    def test_update_role(self, dynamodb_table, sample_org_role):
        """Test updating a role."""
        repo = RoleRepository()
        repo.save(sample_org_role)

        sample_org_role.display_name = "Updated Name"
        updated = repo.update(sample_org_role)

        assert updated.display_name == "Updated Name"

        # Verify persisted
        found = repo.find_by_id(
            sample_org_role.role_id,
            sample_org_role.organisation_id
        )
        assert found.display_name == "Updated Name"

    def test_find_by_org_id_filters_inactive(self, dynamodb_table):
        """Test filtering inactive roles."""
        repo = RoleRepository()
        org_id = "org-filter-test"

        # Create active role
        active_role = Role(
            name="ACTIVE_ROLE",
            display_name="Active",
            organisation_id=org_id,
            scope=RoleScope.ORGANISATION,
            permissions=["site:read"],
            active=True
        )
        repo.save(active_role)

        # Create inactive role
        inactive_role = Role(
            name="INACTIVE_ROLE",
            display_name="Inactive",
            organisation_id=org_id,
            scope=RoleScope.ORGANISATION,
            permissions=["site:read"],
            active=False
        )
        repo.save(inactive_role)

        # Query without inactive
        roles, _ = repo.find_by_org_id(org_id, filters={"includeInactive": False})

        assert len(roles) == 1
        assert roles[0].name == "ACTIVE_ROLE"
```

### 9.5 tests/unit/test_role_service.py

```python
"""Unit tests for RoleService - TDD style."""

import pytest
from unittest.mock import Mock, MagicMock
from datetime import datetime

from src.services.role_service import RoleService
from src.models.role import Role, RoleScope, RoleResponse
from src.models.requests import CreateRoleRequest, UpdateRoleRequest, PaginationParams
from src.exceptions import (
    RoleNotFoundException,
    DuplicateRoleNameException,
    CannotModifySystemRoleException,
    RoleInUseException,
    InvalidPermissionException,
)


class TestRoleServicePlatformRoles:
    """Tests for platform role operations."""

    def test_list_platform_roles_returns_roles(self):
        """Test listing platform roles."""
        mock_repo = Mock()
        mock_repo.find_platform_roles.return_value = (
            [
                Role(
                    role_id="role-1",
                    name="PLATFORM_ADMIN",
                    display_name="Platform Admin",
                    scope=RoleScope.PLATFORM,
                    is_system=True
                )
            ],
            None
        )

        service = RoleService(role_repository=mock_repo)
        result = service.list_platform_roles()

        assert result.count == 1
        assert result.items[0].name == "PLATFORM_ADMIN"

    def test_get_platform_role_returns_role(self):
        """Test getting platform role by ID."""
        mock_repo = Mock()
        mock_repo.find_by_id.return_value = Role(
            role_id="role-platform-1",
            name="PLATFORM_ADMIN",
            display_name="Platform Admin",
            scope=RoleScope.PLATFORM,
            is_system=True
        )

        service = RoleService(role_repository=mock_repo)
        result = service.get_platform_role("role-platform-1")

        assert result.name == "PLATFORM_ADMIN"
        assert result.is_system is True

    def test_get_platform_role_not_found_raises_exception(self):
        """Test getting non-existent platform role raises exception."""
        mock_repo = Mock()
        mock_repo.find_by_id.return_value = None

        service = RoleService(role_repository=mock_repo)

        with pytest.raises(RoleNotFoundException):
            service.get_platform_role("nonexistent")


class TestRoleServiceCreateRole:
    """Tests for create role operation."""

    def test_create_role_success(self):
        """Test creating a new role."""
        mock_repo = Mock()
        mock_repo.find_by_name.return_value = None
        mock_repo.save.return_value = Role(
            role_id="role-new",
            name="CUSTOM_ROLE",
            display_name="Custom Role",
            organisation_id="org-123",
            scope=RoleScope.ORGANISATION,
            permissions=["site:read"]
        )

        mock_user_role_repo = Mock()
        mock_user_role_repo.count_users_with_role.return_value = 0

        service = RoleService(
            role_repository=mock_repo,
            user_role_repository=mock_user_role_repo
        )

        request = CreateRoleRequest(
            name="CUSTOM_ROLE",
            display_name="Custom Role",
            permissions=["site:read"]
        )

        result = service.create_role("org-123", request, "admin@test.com")

        assert result.name == "CUSTOM_ROLE"
        mock_repo.save.assert_called_once()

    def test_create_role_duplicate_name_raises_exception(self):
        """Test creating role with duplicate name raises exception."""
        mock_repo = Mock()
        mock_repo.find_by_name.return_value = Role(
            role_id="existing",
            name="DUPLICATE",
            display_name="Existing",
            organisation_id="org-123"
        )

        service = RoleService(role_repository=mock_repo)

        request = CreateRoleRequest(
            name="DUPLICATE",
            display_name="Duplicate",
            permissions=["site:read"]
        )

        with pytest.raises(DuplicateRoleNameException):
            service.create_role("org-123", request, "admin@test.com")

    def test_create_role_invalid_permission_raises_exception(self):
        """Test creating role with invalid permission raises exception."""
        mock_repo = Mock()
        mock_repo.find_by_name.return_value = None

        service = RoleService(role_repository=mock_repo)

        request = CreateRoleRequest(
            name="NEW_ROLE",
            display_name="New Role",
            permissions=["invalid-format"]  # Invalid format
        )

        with pytest.raises(InvalidPermissionException):
            service.create_role("org-123", request, "admin@test.com")


class TestRoleServiceUpdateRole:
    """Tests for update role operation."""

    def test_update_role_success(self):
        """Test updating a role."""
        existing_role = Role(
            role_id="role-123",
            name="TEST_ROLE",
            display_name="Test Role",
            organisation_id="org-123",
            scope=RoleScope.ORGANISATION,
            is_system=False,
            permissions=["site:read"]
        )

        mock_repo = Mock()
        mock_repo.find_by_id.return_value = existing_role
        mock_repo.update.return_value = existing_role

        mock_user_role_repo = Mock()
        mock_user_role_repo.count_users_with_role.return_value = 0

        service = RoleService(
            role_repository=mock_repo,
            user_role_repository=mock_user_role_repo
        )

        request = UpdateRoleRequest(display_name="Updated Name")
        result = service.update_role("org-123", "role-123", request, "admin@test.com")

        assert result is not None
        mock_repo.update.assert_called_once()

    def test_update_system_role_raises_exception(self):
        """Test updating system role raises exception."""
        system_role = Role(
            role_id="role-system",
            name="PLATFORM_ADMIN",
            display_name="Platform Admin",
            scope=RoleScope.PLATFORM,
            is_system=True
        )

        mock_repo = Mock()
        mock_repo.find_by_id.return_value = system_role

        service = RoleService(role_repository=mock_repo)

        request = UpdateRoleRequest(display_name="Hacked")

        with pytest.raises(CannotModifySystemRoleException):
            service.update_role("org-123", "role-system", request, "hacker@test.com")

    def test_deactivate_role_with_users_raises_exception(self):
        """Test deactivating role with assigned users raises exception."""
        role = Role(
            role_id="role-in-use",
            name="USED_ROLE",
            display_name="Used Role",
            organisation_id="org-123",
            scope=RoleScope.ORGANISATION,
            is_system=False
        )

        mock_repo = Mock()
        mock_repo.find_by_id.return_value = role

        mock_user_role_repo = Mock()
        mock_user_role_repo.count_users_with_role.return_value = 5

        service = RoleService(
            role_repository=mock_repo,
            user_role_repository=mock_user_role_repo
        )

        request = UpdateRoleRequest(active=False)

        with pytest.raises(RoleInUseException) as exc_info:
            service.update_role("org-123", "role-in-use", request, "admin@test.com")

        assert exc_info.value.user_count == 5


class TestRoleServiceSeedRoles:
    """Tests for seed default roles operation."""

    def test_seed_default_roles_creates_five_roles(self):
        """Test seeding creates 5 default org roles."""
        mock_repo = Mock()
        mock_repo.find_by_name.return_value = None
        mock_repo.save.side_effect = lambda r: r

        service = RoleService(role_repository=mock_repo)

        results = service.seed_default_roles("org-123", "system@bbws.io")

        assert len(results) == 5
        assert mock_repo.save.call_count == 5

    def test_seed_default_roles_skips_existing(self):
        """Test seeding skips already existing roles."""
        mock_repo = Mock()
        # First role exists, others don't
        mock_repo.find_by_name.side_effect = [
            Role(name="ORG_ADMIN", display_name="Existing", organisation_id="org-123"),
            None, None, None, None
        ]
        mock_repo.save.side_effect = lambda r: r

        service = RoleService(role_repository=mock_repo)

        results = service.seed_default_roles("org-123", "system@bbws.io")

        assert len(results) == 4  # One skipped
        assert mock_repo.save.call_count == 4


class TestRoleServicePermissionBundling:
    """Tests for permission bundling."""

    def test_get_user_permissions_returns_union(self):
        """Test user permissions are union of all role permissions."""
        role1 = Role(
            role_id="role-1",
            name="ROLE_1",
            display_name="Role 1",
            organisation_id="org-123",
            permissions=["site:read", "site:update"],
            active=True
        )
        role2 = Role(
            role_id="role-2",
            name="ROLE_2",
            display_name="Role 2",
            organisation_id="org-123",
            permissions=["site:read", "user:read"],  # site:read is duplicate
            active=True
        )

        mock_repo = Mock()
        mock_repo.find_by_id.side_effect = [role1, role2]

        mock_user_role_repo = Mock()
        mock_user_role_repo.find_by_user_id.return_value = [
            Mock(role_id="role-1"),
            Mock(role_id="role-2")
        ]

        service = RoleService(
            role_repository=mock_repo,
            user_role_repository=mock_user_role_repo
        )

        permissions = service.get_user_permissions("org-123", "user-456")

        # Union should have 3 unique permissions
        assert len(permissions) == 3
        assert "site:read" in permissions
        assert "site:update" in permissions
        assert "user:read" in permissions
```

### 9.6 tests/unit/test_permission_bundler.py

```python
"""Unit tests for PermissionBundler - TDD style."""

import pytest

from src.services.permission_bundler import PermissionBundler


class TestPermissionBundler:
    """Tests for PermissionBundler service."""

    def test_bundle_permissions_returns_union(self):
        """Test bundling multiple permission sets."""
        bundler = PermissionBundler()

        result = bundler.bundle_permissions([
            {"site:read", "site:update"},
            {"site:read", "user:read"},
            {"team:create"}
        ])

        assert len(result) == 4
        assert "site:read" in result
        assert "site:update" in result
        assert "user:read" in result
        assert "team:create" in result

    def test_bundle_empty_sets(self):
        """Test bundling empty sets."""
        bundler = PermissionBundler()
        result = bundler.bundle_permissions([set(), set()])

        assert len(result) == 0

    def test_has_permission_direct_match(self):
        """Test direct permission match."""
        bundler = PermissionBundler()

        assert bundler.has_permission({"site:read"}, "site:read") is True
        assert bundler.has_permission({"site:read"}, "site:update") is False

    def test_has_permission_wildcard_action(self):
        """Test wildcard action match (site:*)."""
        bundler = PermissionBundler()

        user_perms = {"site:*"}

        assert bundler.has_permission(user_perms, "site:read") is True
        assert bundler.has_permission(user_perms, "site:update") is True
        assert bundler.has_permission(user_perms, "site:delete") is True
        assert bundler.has_permission(user_perms, "user:read") is False

    def test_has_permission_wildcard_resource(self):
        """Test wildcard resource match (*:read)."""
        bundler = PermissionBundler()

        user_perms = {"*:read"}

        assert bundler.has_permission(user_perms, "site:read") is True
        assert bundler.has_permission(user_perms, "user:read") is True
        assert bundler.has_permission(user_perms, "site:update") is False

    def test_has_permission_full_wildcard(self):
        """Test full wildcard match (*:*)."""
        bundler = PermissionBundler()

        user_perms = {"*:*"}

        assert bundler.has_permission(user_perms, "site:read") is True
        assert bundler.has_permission(user_perms, "user:delete") is True
        assert bundler.has_permission(user_perms, "anything:something") is True

    def test_validate_permission_format_valid(self):
        """Test valid permission formats."""
        bundler = PermissionBundler()

        assert bundler.validate_permission_format("site:read") is True
        assert bundler.validate_permission_format("site:*") is True
        assert bundler.validate_permission_format("*:read") is True
        assert bundler.validate_permission_format("*:*") is True

    def test_validate_permission_format_invalid(self):
        """Test invalid permission formats."""
        bundler = PermissionBundler()

        assert bundler.validate_permission_format("invalid") is False
        assert bundler.validate_permission_format("Site:read") is False  # Uppercase
        assert bundler.validate_permission_format("site:Read") is False
        assert bundler.validate_permission_format("site-read") is False
        assert bundler.validate_permission_format("") is False
```

### 9.7 tests/unit/handlers/test_list_platform_roles.py

```python
"""Unit tests for list_platform_roles handler - TDD style."""

import pytest
import json
from unittest.mock import Mock, patch

from src.handlers.platform.list_platform_roles import lambda_handler
from src.models.role import RoleListResponse, RoleResponse, PermissionSummary


class TestListPlatformRolesHandler:
    """Tests for list platform roles Lambda handler."""

    @patch("src.handlers.platform.list_platform_roles.RoleService")
    def test_returns_200_with_roles(self, mock_service_class):
        """Test successful response with roles."""
        # Setup mock
        mock_service = Mock()
        mock_service_class.return_value = mock_service

        mock_service.list_platform_roles.return_value = RoleListResponse(
            items=[
                RoleResponse(
                    id="role-1",
                    name="PLATFORM_ADMIN",
                    display_name="Platform Admin",
                    description="Full access",
                    scope="PLATFORM",
                    permissions=[],
                    is_system=True,
                    is_default=False,
                    priority=1,
                    user_count=0,
                    active=True,
                    date_created="2026-01-23T00:00:00Z",
                    date_last_updated="2026-01-23T00:00:00Z"
                )
            ],
            start_at=None,
            more_available=False,
            count=1,
            links={"self": {"href": "/v1/platform/roles"}}
        )

        # Execute
        event = {
            "queryStringParameters": {"pageSize": "50"},
            "requestContext": {"authorizer": {}}
        }

        response = lambda_handler(event, None)

        # Assert
        assert response["statusCode"] == 200
        body = json.loads(response["body"])
        assert body["count"] == 1
        assert body["items"][0]["name"] == "PLATFORM_ADMIN"

    @patch("src.handlers.platform.list_platform_roles.RoleService")
    def test_returns_empty_list(self, mock_service_class):
        """Test response when no roles exist."""
        mock_service = Mock()
        mock_service_class.return_value = mock_service

        mock_service.list_platform_roles.return_value = RoleListResponse(
            items=[],
            start_at=None,
            more_available=False,
            count=0,
            links={}
        )

        event = {"queryStringParameters": None, "requestContext": {"authorizer": {}}}
        response = lambda_handler(event, None)

        assert response["statusCode"] == 200
        body = json.loads(response["body"])
        assert body["count"] == 0
        assert body["items"] == []

    @patch("src.handlers.platform.list_platform_roles.RoleService")
    def test_handles_pagination_params(self, mock_service_class):
        """Test pagination parameters are passed to service."""
        mock_service = Mock()
        mock_service_class.return_value = mock_service

        mock_service.list_platform_roles.return_value = RoleListResponse(
            items=[],
            start_at=None,
            more_available=False,
            count=0,
            links={}
        )

        event = {
            "queryStringParameters": {
                "pageSize": "10",
                "startAt": "cursor123"
            },
            "requestContext": {"authorizer": {}}
        }

        lambda_handler(event, None)

        # Verify pagination was passed
        call_args = mock_service.list_platform_roles.call_args
        pagination = call_args[0][0] if call_args[0] else call_args[1].get("pagination")
        assert pagination.page_size == 10
        assert pagination.start_at == "cursor123"

    @patch("src.handlers.platform.list_platform_roles.RoleService")
    def test_returns_500_on_unexpected_error(self, mock_service_class):
        """Test 500 response on unexpected errors."""
        mock_service = Mock()
        mock_service_class.return_value = mock_service
        mock_service.list_platform_roles.side_effect = Exception("Unexpected error")

        event = {"queryStringParameters": None, "requestContext": {"authorizer": {}}}
        response = lambda_handler(event, None)

        assert response["statusCode"] == 500
        body = json.loads(response["body"])
        assert body["errorCode"] == "INTERNAL_ERROR"
```

### 9.8 tests/unit/handlers/test_create_role.py

```python
"""Unit tests for create_role handler - TDD style."""

import pytest
import json
from unittest.mock import Mock, patch

from src.handlers.organisation.create_role import lambda_handler
from src.models.role import RoleResponse, PermissionSummary
from src.exceptions import DuplicateRoleNameException, InvalidPermissionException


class TestCreateRoleHandler:
    """Tests for create role Lambda handler."""

    @patch("src.handlers.organisation.create_role.RoleService")
    def test_returns_201_on_success(self, mock_service_class):
        """Test successful role creation returns 201."""
        mock_service = Mock()
        mock_service_class.return_value = mock_service

        mock_service.create_role.return_value = RoleResponse(
            id="role-new",
            name="CUSTOM_ROLE",
            display_name="Custom Role",
            description="A custom role",
            organisation_id="org-123",
            scope="ORGANISATION",
            permissions=[],
            is_system=False,
            is_default=False,
            priority=100,
            user_count=0,
            active=True,
            date_created="2026-01-23T00:00:00Z",
            date_last_updated="2026-01-23T00:00:00Z"
        )

        event = {
            "pathParameters": {"orgId": "org-123"},
            "body": json.dumps({
                "name": "CUSTOM_ROLE",
                "displayName": "Custom Role",
                "permissions": ["site:read"]
            }),
            "requestContext": {
                "authorizer": {"email": "admin@test.com", "orgId": "org-123"}
            }
        }

        response = lambda_handler(event, None)

        assert response["statusCode"] == 201
        body = json.loads(response["body"])
        assert body["name"] == "CUSTOM_ROLE"

    @patch("src.handlers.organisation.create_role.RoleService")
    def test_returns_409_on_duplicate_name(self, mock_service_class):
        """Test duplicate name returns 409."""
        mock_service = Mock()
        mock_service_class.return_value = mock_service
        mock_service.create_role.side_effect = DuplicateRoleNameException(
            "DUPLICATE", "org-123"
        )

        event = {
            "pathParameters": {"orgId": "org-123"},
            "body": json.dumps({
                "name": "DUPLICATE",
                "displayName": "Duplicate",
                "permissions": ["site:read"]
            }),
            "requestContext": {
                "authorizer": {"email": "admin@test.com", "orgId": "org-123"}
            }
        }

        response = lambda_handler(event, None)

        assert response["statusCode"] == 409
        body = json.loads(response["body"])
        assert body["errorCode"] == "DUPLICATE_ROLE_NAME"

    def test_returns_400_on_missing_org_id(self):
        """Test missing orgId returns 400."""
        event = {
            "pathParameters": {},
            "body": "{}",
            "requestContext": {"authorizer": {}}
        }

        response = lambda_handler(event, None)

        assert response["statusCode"] == 400
        body = json.loads(response["body"])
        assert "orgId" in body["message"]

    def test_returns_400_on_invalid_body(self):
        """Test invalid request body returns 400."""
        event = {
            "pathParameters": {"orgId": "org-123"},
            "body": json.dumps({
                "name": "invalid-name",  # Invalid format
                "displayName": "Test",
                "permissions": ["site:read"]
            }),
            "requestContext": {
                "authorizer": {"email": "admin@test.com", "orgId": "org-123"}
            }
        }

        response = lambda_handler(event, None)

        assert response["statusCode"] == 400

    def test_returns_403_on_cross_org_access(self):
        """Test accessing different org returns 403."""
        event = {
            "pathParameters": {"orgId": "org-456"},  # Different org
            "body": json.dumps({
                "name": "ROLE",
                "displayName": "Role",
                "permissions": ["site:read"]
            }),
            "requestContext": {
                "authorizer": {"email": "admin@test.com", "orgId": "org-123"}
            }
        }

        response = lambda_handler(event, None)

        assert response["statusCode"] == 403
        body = json.loads(response["body"])
        assert body["errorCode"] == "UNAUTHORIZED_ORG_ACCESS"
```

---

## 10. Configuration Files

### 10.1 requirements.txt

```
boto3>=1.34.0
pydantic>=2.5.0
aws-lambda-powertools>=2.30.0
```

### 10.2 requirements-dev.txt

```
-r requirements.txt
pytest>=7.4.0
pytest-cov>=4.1.0
moto[dynamodb]>=5.0.0
pytest-mock>=3.12.0
```

### 10.3 pytest.ini

```ini
[pytest]
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*
addopts = -v --cov=src --cov-report=term-missing --cov-report=html
filterwarnings =
    ignore::DeprecationWarning
```

### 10.4 src/__init__.py

```python
"""Role Service Lambda functions for BBWS Access Management."""

__version__ = "1.0.0"
```

---

## Summary

This implementation provides:

1. **8 Lambda Functions**:
   - 2 Platform Role handlers (list, get) - READ-ONLY
   - 6 Organisation Role handlers (create, list, get, update, delete, seed)

2. **Role Models**:
   - `PlatformRole` - System-defined, read-only (PLATFORM_ADMIN, SUPPORT_AGENT, BILLING_ADMIN)
   - `OrganisationRole` - Customizable per-organisation
   - `RoleScope` - PLATFORM, ORGANISATION, TEAM

3. **Default Organisation Roles** (seeded on org creation):
   - ORG_ADMIN
   - ORG_MANAGER
   - SITE_ADMIN
   - SITE_EDITOR
   - SITE_VIEWER

4. **Permission Bundling**:
   - Additive union model
   - Wildcard support (`site:*`, `*:read`, `*:*`)

5. **Security Controls**:
   - System roles cannot be modified
   - Roles with assigned users cannot be deleted
   - Cross-org access validation

6. **TDD Approach**:
   - Tests written first
   - Unit tests with pytest + moto
   - >80% code coverage target

---

**Status**: COMPLETE
**Date Completed**: 2026-01-23
**Worker**: worker-4-role-service-lambdas
