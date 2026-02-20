# Permission Service Lambda Functions - Implementation Output

**Worker ID**: worker-1-permission-service-lambdas
**Stage**: Stage 3 - Lambda Services Development
**Project**: project-plan-2-access-management
**Created**: 2026-01-23
**Status**: COMPLETE

---

## Table of Contents

1. [Overview](#overview)
2. [Project Structure](#project-structure)
3. [Dependencies](#dependencies)
4. [Pydantic Models](#pydantic-models)
5. [Custom Exceptions](#custom-exceptions)
6. [Repository Layer](#repository-layer)
7. [Service Layer](#service-layer)
8. [Lambda Handlers](#lambda-handlers)
9. [Unit Tests (TDD)](#unit-tests-tdd)
10. [Test Configuration](#test-configuration)
11. [Seed Data](#seed-data)
12. [Deployment Configuration](#deployment-configuration)

---

## Overview

This document contains the complete implementation of 6 Lambda functions for the Permission Service:

| # | Function | Method | Endpoint | Description |
|---|----------|--------|----------|-------------|
| 1 | list_permissions | GET | `/v1/platform/permissions` | List all platform permissions with pagination |
| 2 | get_permission | GET | `/v1/platform/permissions/{permId}` | Get single permission by ID |
| 3 | create_permission | POST | `/v1/permissions` | Create a new permission (admin only) |
| 4 | update_permission | PUT | `/v1/permissions/{permId}` | Update an existing permission |
| 5 | delete_permission | DELETE | `/v1/permissions/{permId}` | Soft delete a permission |
| 6 | seed_permissions | POST | `/v1/permissions/seed` | Seed platform permissions |

---

## Project Structure

```
lambda/permission_service/
├── __init__.py
├── handlers/
│   ├── __init__.py
│   ├── list_handler.py
│   ├── get_handler.py
│   ├── create_handler.py
│   ├── update_handler.py
│   ├── delete_handler.py
│   └── seed_handler.py
├── models/
│   ├── __init__.py
│   ├── permission.py
│   ├── enums.py
│   └── requests.py
├── services/
│   ├── __init__.py
│   └── permission_service.py
├── repositories/
│   ├── __init__.py
│   └── permission_repository.py
├── exceptions/
│   ├── __init__.py
│   └── permission_exceptions.py
├── utils/
│   ├── __init__.py
│   ├── response_builder.py
│   ├── hateoas.py
│   └── validators.py
└── tests/
    ├── __init__.py
    ├── conftest.py
    ├── test_list_handler.py
    ├── test_get_handler.py
    ├── test_create_handler.py
    ├── test_update_handler.py
    ├── test_delete_handler.py
    └── test_seed_handler.py
```

---

## Dependencies

### requirements.txt

```txt
# Core
pydantic>=2.5.0
boto3>=1.34.0
botocore>=1.34.0

# AWS Lambda Powertools
aws-lambda-powertools>=2.30.0

# Testing
pytest>=7.4.0
pytest-cov>=4.1.0
moto>=4.2.0
pytest-mock>=3.12.0

# Utilities
python-dateutil>=2.8.2
```

### pytest.ini

```ini
[pytest]
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*
addopts = -v --cov=lambda/permission_service --cov-report=term-missing --cov-fail-under=80
filterwarnings =
    ignore::DeprecationWarning
```

---

## Pydantic Models

### models/__init__.py

```python
"""Permission Service Models Package."""

from .enums import PermissionCategory, PermissionScope, PermissionAction
from .permission import (
    Permission,
    PermissionResponse,
    PaginatedPermissionResponse,
    HATEOASLink,
)
from .requests import (
    CreatePermissionRequest,
    UpdatePermissionRequest,
    ListPermissionsQueryParams,
)

__all__ = [
    # Enums
    "PermissionCategory",
    "PermissionScope",
    "PermissionAction",
    # Models
    "Permission",
    "PermissionResponse",
    "PaginatedPermissionResponse",
    "HATEOASLink",
    # Requests
    "CreatePermissionRequest",
    "UpdatePermissionRequest",
    "ListPermissionsQueryParams",
]
```

### models/enums.py

```python
"""Permission Service Enums."""

from enum import Enum


class PermissionCategory(str, Enum):
    """Permission category grouping."""

    SITE = "SITE"
    TEAM = "TEAM"
    ORGANISATION = "ORGANISATION"
    INVITATION = "INVITATION"
    ROLE = "ROLE"
    AUDIT = "AUDIT"


class PermissionScope(str, Enum):
    """Permission scope level."""

    PLATFORM = "PLATFORM"
    ORGANISATION = "ORGANISATION"
    TEAM = "TEAM"
    SITE = "SITE"


class PermissionAction(str, Enum):
    """Permission action types."""

    CREATE = "create"
    READ = "read"
    UPDATE = "update"
    DELETE = "delete"
    PUBLISH = "publish"
    BACKUP = "backup"
    RESTORE = "restore"
    ADD = "add"
    REMOVE = "remove"
    MANAGE = "manage"
    ASSIGN = "assign"
    REVOKE = "revoke"
    RESEND = "resend"
    EXPORT = "export"
```

### models/permission.py

```python
"""Permission domain models."""

from datetime import datetime
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field, field_validator, ConfigDict
import uuid


class HATEOASLink(BaseModel):
    """HATEOAS link representation."""

    href: str
    method: Optional[str] = None
    body: Optional[Dict[str, Any]] = None

    model_config = ConfigDict(
        populate_by_name=True,
        json_schema_extra={
            "example": {
                "href": "/v1/platform/permissions/site:create",
                "method": "GET"
            }
        }
    )


class Permission(BaseModel):
    """Permission domain entity."""

    permission_id: str = Field(..., alias="permissionId", description="Permission ID in format resource:action")
    name: str = Field(..., min_length=3, max_length=100, description="Human-readable permission name")
    description: str = Field(..., min_length=10, max_length=500, description="Permission description")
    resource: str = Field(..., description="Resource type (e.g., site, team, org)")
    action: str = Field(..., description="Action type (e.g., create, read, update)")
    category: str = Field(..., description="Permission category grouping")
    is_system: bool = Field(True, alias="isSystem", description="System-defined permission (read-only)")
    active: bool = Field(True, description="Permission active status")
    date_created: datetime = Field(default_factory=datetime.utcnow, alias="dateCreated")

    model_config = ConfigDict(
        populate_by_name=True,
        json_schema_extra={
            "example": {
                "permissionId": "site:create",
                "name": "Create Site",
                "description": "Allows creating new WordPress sites",
                "resource": "site",
                "action": "create",
                "category": "SITE",
                "isSystem": True,
                "active": True,
                "dateCreated": "2026-01-01T00:00:00Z"
            }
        }
    )

    @field_validator("permission_id")
    @classmethod
    def validate_permission_id_format(cls, v: str) -> str:
        """Validate permission ID is in format resource:action."""
        if ":" not in v:
            raise ValueError(f"Permission ID must be in format 'resource:action', got: {v}")
        return v

    @classmethod
    def from_dynamo_item(cls, item: Dict[str, Any]) -> "Permission":
        """Create Permission from DynamoDB item."""
        return cls(
            permission_id=item.get("permissionId", ""),
            name=item.get("name", ""),
            description=item.get("description", ""),
            resource=item.get("resource", ""),
            action=item.get("action", ""),
            category=item.get("category", ""),
            is_system=item.get("isSystem", True),
            active=item.get("active", True),
            date_created=datetime.fromisoformat(item.get("dateCreated", datetime.utcnow().isoformat()).replace("Z", "+00:00"))
        )

    def to_dynamo_item(self) -> Dict[str, Any]:
        """Convert Permission to DynamoDB item."""
        return {
            "PK": f"PERM#{self.permission_id}",
            "SK": "METADATA",
            "permissionId": self.permission_id,
            "name": self.name,
            "description": self.description,
            "resource": self.resource,
            "action": self.action,
            "category": self.category,
            "isSystem": self.is_system,
            "active": self.active,
            "dateCreated": self.date_created.isoformat() + "Z",
            "GSI1PK": f"CATEGORY#{self.category}",
            "GSI1SK": f"PERM#{self.permission_id}",
        }


class PermissionResponse(BaseModel):
    """Permission API response with HATEOAS links."""

    id: str = Field(..., description="Permission ID")
    name: str = Field(..., description="Permission name")
    description: str = Field(..., description="Permission description")
    resource: str = Field(..., description="Resource type")
    action: str = Field(..., description="Action type")
    category: str = Field(..., description="Permission category")
    active: bool = Field(..., description="Active status")
    date_created: str = Field(..., alias="dateCreated", description="Creation timestamp")
    links: Dict[str, HATEOASLink] = Field(default_factory=dict, alias="_links")

    model_config = ConfigDict(populate_by_name=True)

    @classmethod
    def from_permission(cls, permission: Permission, base_url: str = "/v1/platform/permissions") -> "PermissionResponse":
        """Create response from Permission entity."""
        return cls(
            id=permission.permission_id,
            name=permission.name,
            description=permission.description,
            resource=permission.resource,
            action=permission.action,
            category=permission.category,
            active=permission.active,
            date_created=permission.date_created.isoformat() + "Z",
            links={
                "self": HATEOASLink(href=f"{base_url}/{permission.permission_id}")
            }
        )


class PaginatedPermissionResponse(BaseModel):
    """Paginated permission list response."""

    items: List[PermissionResponse] = Field(default_factory=list)
    start_at: Optional[str] = Field(None, alias="startAt", description="Pagination cursor")
    more_available: bool = Field(False, alias="moreAvailable")
    count: int = Field(0, description="Number of items returned")
    links: Dict[str, HATEOASLink] = Field(default_factory=dict, alias="_links")

    model_config = ConfigDict(populate_by_name=True)
```

### models/requests.py

```python
"""Request models for Permission Service."""

from typing import Optional, List
from pydantic import BaseModel, Field, field_validator


class ListPermissionsQueryParams(BaseModel):
    """Query parameters for listing permissions."""

    page_size: int = Field(50, alias="pageSize", ge=1, le=100, description="Items per page")
    start_at: Optional[str] = Field(None, alias="startAt", description="Pagination cursor")
    category: Optional[str] = Field(None, description="Filter by category")

    @field_validator("category")
    @classmethod
    def validate_category(cls, v: Optional[str]) -> Optional[str]:
        """Validate category is a valid enum value."""
        if v is None:
            return v
        valid_categories = ["SITE", "TEAM", "ORGANISATION", "INVITATION", "ROLE", "AUDIT"]
        if v.upper() not in valid_categories:
            raise ValueError(f"Invalid category: {v}. Must be one of: {valid_categories}")
        return v.upper()


class CreatePermissionRequest(BaseModel):
    """Request body for creating a permission."""

    permission_id: str = Field(..., alias="permissionId", description="Permission ID in format resource:action")
    name: str = Field(..., min_length=3, max_length=100, description="Permission name")
    description: str = Field(..., min_length=10, max_length=500, description="Permission description")
    resource: str = Field(..., min_length=1, max_length=50, description="Resource type")
    action: str = Field(..., min_length=1, max_length=50, description="Action type")
    category: str = Field(..., description="Permission category")
    is_system: bool = Field(False, alias="isSystem", description="Is system permission")

    @field_validator("permission_id")
    @classmethod
    def validate_permission_id(cls, v: str) -> str:
        """Validate permission ID format."""
        if ":" not in v:
            raise ValueError("Permission ID must be in format 'resource:action'")
        return v

    @field_validator("category")
    @classmethod
    def validate_category(cls, v: str) -> str:
        """Validate category."""
        valid_categories = ["SITE", "TEAM", "ORGANISATION", "INVITATION", "ROLE", "AUDIT"]
        if v.upper() not in valid_categories:
            raise ValueError(f"Invalid category: {v}. Must be one of: {valid_categories}")
        return v.upper()


class UpdatePermissionRequest(BaseModel):
    """Request body for updating a permission."""

    name: Optional[str] = Field(None, min_length=3, max_length=100, description="Permission name")
    description: Optional[str] = Field(None, min_length=10, max_length=500, description="Permission description")
    active: Optional[bool] = Field(None, description="Active status")

    def has_updates(self) -> bool:
        """Check if request has any updates."""
        return any([
            self.name is not None,
            self.description is not None,
            self.active is not None
        ])
```

---

## Custom Exceptions

### exceptions/__init__.py

```python
"""Permission Service Exceptions Package."""

from .permission_exceptions import (
    PermissionServiceException,
    PermissionNotFoundException,
    PermissionAlreadyExistsException,
    InvalidPermissionException,
    SystemPermissionModificationException,
    ValidationException,
    ForbiddenException,
)

__all__ = [
    "PermissionServiceException",
    "PermissionNotFoundException",
    "PermissionAlreadyExistsException",
    "InvalidPermissionException",
    "SystemPermissionModificationException",
    "ValidationException",
    "ForbiddenException",
]
```

### exceptions/permission_exceptions.py

```python
"""Custom exceptions for Permission Service."""

from typing import Optional, List, Dict, Any


class PermissionServiceException(Exception):
    """Base exception for Permission Service."""

    def __init__(
        self,
        message: str,
        error_code: str = "INTERNAL_ERROR",
        status_code: int = 500,
        details: Optional[Dict[str, Any]] = None
    ):
        super().__init__(message)
        self.message = message
        self.error_code = error_code
        self.status_code = status_code
        self.details = details or {}

    def to_dict(self) -> Dict[str, Any]:
        """Convert exception to API error response format."""
        response = {
            "errorCode": self.error_code,
            "message": self.message,
        }
        if self.details:
            response["details"] = self.details
        return response


class PermissionNotFoundException(PermissionServiceException):
    """Raised when a permission is not found."""

    def __init__(self, permission_id: str):
        super().__init__(
            message=f"Permission not found: {permission_id}",
            error_code="PERMISSION_NOT_FOUND",
            status_code=404,
            details={"permissionId": permission_id}
        )
        self.permission_id = permission_id


class PermissionAlreadyExistsException(PermissionServiceException):
    """Raised when attempting to create a duplicate permission."""

    def __init__(self, permission_id: str):
        super().__init__(
            message=f"Permission already exists: {permission_id}",
            error_code="PERMISSION_ALREADY_EXISTS",
            status_code=409,
            details={"permissionId": permission_id}
        )
        self.permission_id = permission_id


class InvalidPermissionException(PermissionServiceException):
    """Raised when permission validation fails."""

    def __init__(self, message: str, invalid_permissions: Optional[List[str]] = None):
        super().__init__(
            message=message,
            error_code="INVALID_PERMISSION",
            status_code=400,
            details={"invalidPermissions": invalid_permissions} if invalid_permissions else {}
        )
        self.invalid_permissions = invalid_permissions or []


class SystemPermissionModificationException(PermissionServiceException):
    """Raised when attempting to modify a system permission."""

    def __init__(self, permission_id: str):
        super().__init__(
            message=f"Cannot modify system permission: {permission_id}",
            error_code="SYSTEM_PERMISSION_MODIFICATION",
            status_code=403,
            details={"permissionId": permission_id}
        )
        self.permission_id = permission_id


class ValidationException(PermissionServiceException):
    """Raised when request validation fails."""

    def __init__(self, message: str, field: Optional[str] = None):
        details = {}
        if field:
            details["field"] = field
        super().__init__(
            message=message,
            error_code="VALIDATION_ERROR",
            status_code=400,
            details=details
        )


class ForbiddenException(PermissionServiceException):
    """Raised when user lacks required permissions."""

    def __init__(self, message: str = "Access denied"):
        super().__init__(
            message=message,
            error_code="FORBIDDEN",
            status_code=403
        )
```

---

## Repository Layer

### repositories/__init__.py

```python
"""Permission Service Repositories Package."""

from .permission_repository import PermissionRepository

__all__ = ["PermissionRepository"]
```

### repositories/permission_repository.py

```python
"""DynamoDB repository for Permission entities."""

import os
import logging
from typing import Optional, List, Tuple, Dict, Any
from datetime import datetime

import boto3
from boto3.dynamodb.conditions import Key, Attr
from botocore.exceptions import ClientError

from ..models.permission import Permission
from ..exceptions.permission_exceptions import (
    PermissionNotFoundException,
    PermissionAlreadyExistsException,
    PermissionServiceException,
)


logger = logging.getLogger(__name__)


class PermissionRepository:
    """Repository for Permission DynamoDB operations."""

    def __init__(self, table_name: Optional[str] = None, dynamodb_resource=None):
        """
        Initialize the repository.

        Args:
            table_name: DynamoDB table name. Defaults to environment variable.
            dynamodb_resource: Optional boto3 DynamoDB resource for testing.
        """
        self.table_name = table_name or os.environ.get(
            "DYNAMODB_TABLE_NAME",
            "bbws-aipagebuilder-dev-ddb-access-management"
        )

        if dynamodb_resource:
            self._dynamodb = dynamodb_resource
        else:
            self._dynamodb = boto3.resource("dynamodb")

        self._table = self._dynamodb.Table(self.table_name)

    @property
    def table(self):
        """Get the DynamoDB table."""
        return self._table

    def get_by_id(self, permission_id: str) -> Optional[Permission]:
        """
        Get a permission by its ID.

        Args:
            permission_id: The permission ID (format: resource:action)

        Returns:
            Permission if found, None otherwise
        """
        try:
            logger.info(f"Getting permission: {permission_id}")
            response = self._table.get_item(
                Key={
                    "PK": f"PERM#{permission_id}",
                    "SK": "METADATA"
                }
            )

            item = response.get("Item")
            if not item:
                logger.info(f"Permission not found: {permission_id}")
                return None

            return Permission.from_dynamo_item(item)

        except ClientError as e:
            logger.error(f"Error getting permission {permission_id}: {e}")
            raise PermissionServiceException(
                message=f"Failed to get permission: {str(e)}",
                error_code="DYNAMODB_ERROR"
            )

    def list_all(
        self,
        page_size: int = 50,
        start_key: Optional[str] = None,
        category: Optional[str] = None
    ) -> Tuple[List[Permission], Optional[str]]:
        """
        List all permissions with pagination.

        Args:
            page_size: Number of items per page (max 100)
            start_key: Pagination cursor (permission ID to start from)
            category: Optional category filter

        Returns:
            Tuple of (list of permissions, next pagination cursor)
        """
        try:
            logger.info(f"Listing permissions: page_size={page_size}, start_key={start_key}, category={category}")

            if category:
                # Use GSI1 for category filtering
                query_params = {
                    "IndexName": "GSI1",
                    "KeyConditionExpression": Key("GSI1PK").eq(f"CATEGORY#{category}"),
                    "Limit": page_size,
                }

                if start_key:
                    query_params["ExclusiveStartKey"] = {
                        "GSI1PK": f"CATEGORY#{category}",
                        "GSI1SK": f"PERM#{start_key}",
                        "PK": f"PERM#{start_key}",
                        "SK": "METADATA"
                    }

                response = self._table.query(**query_params)
            else:
                # Scan with filter for PERM# prefix
                scan_params = {
                    "FilterExpression": Attr("PK").begins_with("PERM#") & Attr("SK").eq("METADATA"),
                    "Limit": page_size * 2,  # Request more to account for filter
                }

                if start_key:
                    scan_params["ExclusiveStartKey"] = {
                        "PK": f"PERM#{start_key}",
                        "SK": "METADATA"
                    }

                response = self._table.scan(**scan_params)

            items = response.get("Items", [])
            permissions = [Permission.from_dynamo_item(item) for item in items[:page_size]]

            # Determine next pagination cursor
            next_key = None
            if len(items) > page_size or response.get("LastEvaluatedKey"):
                if permissions:
                    next_key = permissions[-1].permission_id

            logger.info(f"Found {len(permissions)} permissions, next_key={next_key}")
            return permissions, next_key

        except ClientError as e:
            logger.error(f"Error listing permissions: {e}")
            raise PermissionServiceException(
                message=f"Failed to list permissions: {str(e)}",
                error_code="DYNAMODB_ERROR"
            )

    def create(self, permission: Permission) -> Permission:
        """
        Create a new permission.

        Args:
            permission: The permission to create

        Returns:
            The created permission

        Raises:
            PermissionAlreadyExistsException: If permission already exists
        """
        try:
            logger.info(f"Creating permission: {permission.permission_id}")

            # Check if permission already exists
            existing = self.get_by_id(permission.permission_id)
            if existing:
                raise PermissionAlreadyExistsException(permission.permission_id)

            item = permission.to_dynamo_item()
            self._table.put_item(
                Item=item,
                ConditionExpression="attribute_not_exists(PK)"
            )

            logger.info(f"Created permission: {permission.permission_id}")
            return permission

        except ClientError as e:
            if e.response["Error"]["Code"] == "ConditionalCheckFailedException":
                raise PermissionAlreadyExistsException(permission.permission_id)
            logger.error(f"Error creating permission {permission.permission_id}: {e}")
            raise PermissionServiceException(
                message=f"Failed to create permission: {str(e)}",
                error_code="DYNAMODB_ERROR"
            )

    def update(self, permission: Permission) -> Permission:
        """
        Update an existing permission.

        Args:
            permission: The permission with updated values

        Returns:
            The updated permission

        Raises:
            PermissionNotFoundException: If permission does not exist
        """
        try:
            logger.info(f"Updating permission: {permission.permission_id}")

            # Verify permission exists
            existing = self.get_by_id(permission.permission_id)
            if not existing:
                raise PermissionNotFoundException(permission.permission_id)

            item = permission.to_dynamo_item()
            self._table.put_item(Item=item)

            logger.info(f"Updated permission: {permission.permission_id}")
            return permission

        except PermissionNotFoundException:
            raise
        except ClientError as e:
            logger.error(f"Error updating permission {permission.permission_id}: {e}")
            raise PermissionServiceException(
                message=f"Failed to update permission: {str(e)}",
                error_code="DYNAMODB_ERROR"
            )

    def delete(self, permission_id: str) -> bool:
        """
        Delete a permission (soft delete by setting active=false).

        Args:
            permission_id: The permission ID to delete

        Returns:
            True if deleted successfully

        Raises:
            PermissionNotFoundException: If permission does not exist
        """
        try:
            logger.info(f"Deleting permission: {permission_id}")

            # Get existing permission
            permission = self.get_by_id(permission_id)
            if not permission:
                raise PermissionNotFoundException(permission_id)

            # Soft delete by setting active=false
            self._table.update_item(
                Key={
                    "PK": f"PERM#{permission_id}",
                    "SK": "METADATA"
                },
                UpdateExpression="SET active = :active",
                ExpressionAttributeValues={":active": False},
                ConditionExpression="attribute_exists(PK)"
            )

            logger.info(f"Deleted permission: {permission_id}")
            return True

        except ClientError as e:
            if e.response["Error"]["Code"] == "ConditionalCheckFailedException":
                raise PermissionNotFoundException(permission_id)
            logger.error(f"Error deleting permission {permission_id}: {e}")
            raise PermissionServiceException(
                message=f"Failed to delete permission: {str(e)}",
                error_code="DYNAMODB_ERROR"
            )

    def batch_create(self, permissions: List[Permission]) -> int:
        """
        Batch create permissions (for seeding).

        Args:
            permissions: List of permissions to create

        Returns:
            Number of permissions created
        """
        try:
            logger.info(f"Batch creating {len(permissions)} permissions")

            with self._table.batch_writer() as batch:
                for permission in permissions:
                    item = permission.to_dynamo_item()
                    batch.put_item(Item=item)

            logger.info(f"Batch created {len(permissions)} permissions")
            return len(permissions)

        except ClientError as e:
            logger.error(f"Error batch creating permissions: {e}")
            raise PermissionServiceException(
                message=f"Failed to batch create permissions: {str(e)}",
                error_code="DYNAMODB_ERROR"
            )

    def exists(self, permission_id: str) -> bool:
        """
        Check if a permission exists.

        Args:
            permission_id: The permission ID to check

        Returns:
            True if permission exists
        """
        permission = self.get_by_id(permission_id)
        return permission is not None
```

---

## Service Layer

### services/__init__.py

```python
"""Permission Service Services Package."""

from .permission_service import PermissionService

__all__ = ["PermissionService"]
```

### services/permission_service.py

```python
"""Business logic service for Permission operations."""

import logging
from typing import Optional, List, Tuple
from datetime import datetime

from ..models.permission import Permission, PermissionResponse, PaginatedPermissionResponse, HATEOASLink
from ..models.requests import CreatePermissionRequest, UpdatePermissionRequest, ListPermissionsQueryParams
from ..repositories.permission_repository import PermissionRepository
from ..exceptions.permission_exceptions import (
    PermissionNotFoundException,
    PermissionAlreadyExistsException,
    SystemPermissionModificationException,
    ValidationException,
)


logger = logging.getLogger(__name__)


class PermissionService:
    """Service layer for Permission business logic."""

    # Platform permissions seed data
    PLATFORM_PERMISSIONS = [
        # SITE permissions
        {"permissionId": "site:create", "name": "Create Site", "description": "Allows creating new WordPress sites", "resource": "site", "action": "create", "category": "SITE"},
        {"permissionId": "site:read", "name": "View Site", "description": "Allows viewing site details and configurations", "resource": "site", "action": "read", "category": "SITE"},
        {"permissionId": "site:update", "name": "Update Site", "description": "Allows modifying site settings and content", "resource": "site", "action": "update", "category": "SITE"},
        {"permissionId": "site:delete", "name": "Delete Site", "description": "Allows deleting sites (soft delete)", "resource": "site", "action": "delete", "category": "SITE"},
        {"permissionId": "site:publish", "name": "Publish Site", "description": "Allows publishing site changes to production", "resource": "site", "action": "publish", "category": "SITE"},
        {"permissionId": "site:backup", "name": "Backup Site", "description": "Allows creating site backups", "resource": "site", "action": "backup", "category": "SITE"},
        {"permissionId": "site:restore", "name": "Restore Site", "description": "Allows restoring site from backup", "resource": "site", "action": "restore", "category": "SITE"},

        # TEAM permissions
        {"permissionId": "team:read", "name": "View Team", "description": "Allows viewing team details and information", "resource": "team", "action": "read", "category": "TEAM"},
        {"permissionId": "team:update", "name": "Update Team", "description": "Allows modifying team settings and details", "resource": "team", "action": "update", "category": "TEAM"},
        {"permissionId": "team:member:add", "name": "Add Team Member", "description": "Allows adding users to the team", "resource": "team:member", "action": "add", "category": "TEAM"},
        {"permissionId": "team:member:remove", "name": "Remove Team Member", "description": "Allows removing users from the team", "resource": "team:member", "action": "remove", "category": "TEAM"},
        {"permissionId": "team:member:read", "name": "View Team Members", "description": "Allows viewing team member list", "resource": "team:member", "action": "read", "category": "TEAM"},

        # ORGANISATION permissions
        {"permissionId": "org:read", "name": "View Organisation", "description": "Allows viewing organisation details", "resource": "org", "action": "read", "category": "ORGANISATION"},
        {"permissionId": "org:update", "name": "Update Organisation", "description": "Allows modifying organisation settings", "resource": "org", "action": "update", "category": "ORGANISATION"},
        {"permissionId": "org:hierarchy:manage", "name": "Manage Hierarchy", "description": "Allows managing organisation hierarchy structure", "resource": "org:hierarchy", "action": "manage", "category": "ORGANISATION"},
        {"permissionId": "org:user:manage", "name": "Manage Users", "description": "Allows managing organisation users", "resource": "org:user", "action": "manage", "category": "ORGANISATION"},

        # INVITATION permissions
        {"permissionId": "invitation:create", "name": "Create Invitation", "description": "Allows creating user invitations", "resource": "invitation", "action": "create", "category": "INVITATION"},
        {"permissionId": "invitation:read", "name": "View Invitations", "description": "Allows viewing invitation status", "resource": "invitation", "action": "read", "category": "INVITATION"},
        {"permissionId": "invitation:revoke", "name": "Revoke Invitation", "description": "Allows revoking pending invitations", "resource": "invitation", "action": "revoke", "category": "INVITATION"},
        {"permissionId": "invitation:resend", "name": "Resend Invitation", "description": "Allows resending invitation emails", "resource": "invitation", "action": "resend", "category": "INVITATION"},

        # ROLE permissions
        {"permissionId": "role:create", "name": "Create Role", "description": "Allows creating new custom roles", "resource": "role", "action": "create", "category": "ROLE"},
        {"permissionId": "role:update", "name": "Update Role", "description": "Allows modifying existing roles", "resource": "role", "action": "update", "category": "ROLE"},
        {"permissionId": "role:assign", "name": "Assign Role", "description": "Allows assigning roles to users", "resource": "role", "action": "assign", "category": "ROLE"},

        # AUDIT permissions
        {"permissionId": "audit:read", "name": "View Audit Logs", "description": "Allows viewing audit log entries", "resource": "audit", "action": "read", "category": "AUDIT"},
        {"permissionId": "audit:export", "name": "Export Audit Data", "description": "Allows exporting audit data to files", "resource": "audit", "action": "export", "category": "AUDIT"},
    ]

    def __init__(self, repository: Optional[PermissionRepository] = None):
        """
        Initialize the service.

        Args:
            repository: Optional repository instance for dependency injection
        """
        self._repository = repository or PermissionRepository()

    @property
    def repository(self) -> PermissionRepository:
        """Get the repository."""
        return self._repository

    def list_permissions(
        self,
        query_params: ListPermissionsQueryParams
    ) -> PaginatedPermissionResponse:
        """
        List permissions with pagination.

        Args:
            query_params: Query parameters for filtering and pagination

        Returns:
            Paginated response with permissions
        """
        logger.info(f"Listing permissions with params: {query_params}")

        # Validate page size
        if query_params.page_size > 100:
            raise ValidationException(
                message="Page size cannot exceed 100",
                field="pageSize"
            )

        permissions, next_key = self._repository.list_all(
            page_size=query_params.page_size,
            start_key=query_params.start_at,
            category=query_params.category
        )

        # Convert to response models
        items = [
            PermissionResponse.from_permission(p)
            for p in permissions
        ]

        # Build HATEOAS links
        base_url = "/v1/platform/permissions"
        links = {
            "self": HATEOASLink(
                href=f"{base_url}?pageSize={query_params.page_size}"
            )
        }

        if next_key:
            links["next"] = HATEOASLink(
                href=f"{base_url}?pageSize={query_params.page_size}&startAt={next_key}"
            )

        return PaginatedPermissionResponse(
            items=items,
            start_at=next_key,
            more_available=next_key is not None,
            count=len(items),
            links=links
        )

    def get_permission(self, permission_id: str) -> PermissionResponse:
        """
        Get a single permission by ID.

        Args:
            permission_id: The permission ID (format: resource:action)

        Returns:
            Permission response with HATEOAS links

        Raises:
            PermissionNotFoundException: If permission not found
        """
        logger.info(f"Getting permission: {permission_id}")

        # Validate permission ID format
        if ":" not in permission_id:
            raise ValidationException(
                message="Permission ID must be in format 'resource:action'",
                field="permId"
            )

        permission = self._repository.get_by_id(permission_id)
        if not permission:
            raise PermissionNotFoundException(permission_id)

        return PermissionResponse.from_permission(permission)

    def create_permission(self, request: CreatePermissionRequest) -> PermissionResponse:
        """
        Create a new permission.

        Args:
            request: Create permission request

        Returns:
            Created permission response

        Raises:
            PermissionAlreadyExistsException: If permission already exists
        """
        logger.info(f"Creating permission: {request.permission_id}")

        # Verify permission doesn't already exist
        existing = self._repository.get_by_id(request.permission_id)
        if existing:
            raise PermissionAlreadyExistsException(request.permission_id)

        # Create permission entity
        permission = Permission(
            permission_id=request.permission_id,
            name=request.name,
            description=request.description,
            resource=request.resource,
            action=request.action,
            category=request.category,
            is_system=request.is_system,
            active=True,
            date_created=datetime.utcnow()
        )

        created = self._repository.create(permission)
        return PermissionResponse.from_permission(created)

    def update_permission(
        self,
        permission_id: str,
        request: UpdatePermissionRequest
    ) -> PermissionResponse:
        """
        Update an existing permission.

        Args:
            permission_id: The permission ID to update
            request: Update request with new values

        Returns:
            Updated permission response

        Raises:
            PermissionNotFoundException: If permission not found
            SystemPermissionModificationException: If trying to modify system permission
        """
        logger.info(f"Updating permission: {permission_id}")

        # Get existing permission
        permission = self._repository.get_by_id(permission_id)
        if not permission:
            raise PermissionNotFoundException(permission_id)

        # Check if system permission
        if permission.is_system:
            raise SystemPermissionModificationException(permission_id)

        # Validate request has updates
        if not request.has_updates():
            raise ValidationException(
                message="No updates provided in request"
            )

        # Apply updates
        if request.name is not None:
            permission.name = request.name
        if request.description is not None:
            permission.description = request.description
        if request.active is not None:
            permission.active = request.active

        updated = self._repository.update(permission)
        return PermissionResponse.from_permission(updated)

    def delete_permission(self, permission_id: str) -> bool:
        """
        Delete a permission (soft delete).

        Args:
            permission_id: The permission ID to delete

        Returns:
            True if deleted successfully

        Raises:
            PermissionNotFoundException: If permission not found
            SystemPermissionModificationException: If trying to delete system permission
        """
        logger.info(f"Deleting permission: {permission_id}")

        # Get existing permission
        permission = self._repository.get_by_id(permission_id)
        if not permission:
            raise PermissionNotFoundException(permission_id)

        # Check if system permission
        if permission.is_system:
            raise SystemPermissionModificationException(permission_id)

        return self._repository.delete(permission_id)

    def seed_permissions(self) -> int:
        """
        Seed platform permissions.

        Returns:
            Number of permissions seeded
        """
        logger.info("Seeding platform permissions")

        permissions = []
        for perm_data in self.PLATFORM_PERMISSIONS:
            permission = Permission(
                permission_id=perm_data["permissionId"],
                name=perm_data["name"],
                description=perm_data["description"],
                resource=perm_data["resource"],
                action=perm_data["action"],
                category=perm_data["category"],
                is_system=True,
                active=True,
                date_created=datetime.utcnow()
            )
            permissions.append(permission)

        count = self._repository.batch_create(permissions)
        logger.info(f"Seeded {count} platform permissions")
        return count

    def validate_permissions_exist(self, permission_ids: List[str]) -> List[str]:
        """
        Validate that all permission IDs exist.

        Args:
            permission_ids: List of permission IDs to validate

        Returns:
            List of invalid permission IDs (empty if all valid)
        """
        invalid = []
        for perm_id in permission_ids:
            if not self._repository.exists(perm_id):
                invalid.append(perm_id)
        return invalid
```

---

## Lambda Handlers

### handlers/__init__.py

```python
"""Permission Service Handlers Package."""

from .list_handler import lambda_handler as list_permissions_handler
from .get_handler import lambda_handler as get_permission_handler
from .create_handler import lambda_handler as create_permission_handler
from .update_handler import lambda_handler as update_permission_handler
from .delete_handler import lambda_handler as delete_permission_handler
from .seed_handler import lambda_handler as seed_permissions_handler

__all__ = [
    "list_permissions_handler",
    "get_permission_handler",
    "create_permission_handler",
    "update_permission_handler",
    "delete_permission_handler",
    "seed_permissions_handler",
]
```

### utils/response_builder.py

```python
"""Response builder utilities."""

import json
from typing import Any, Dict, Optional
import logging

logger = logging.getLogger(__name__)


class ResponseBuilder:
    """Builder for Lambda API Gateway responses."""

    DEFAULT_HEADERS = {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type, Authorization",
    }

    @classmethod
    def success(
        cls,
        status_code: int,
        body: Any,
        headers: Optional[Dict[str, str]] = None
    ) -> Dict[str, Any]:
        """
        Build a successful response.

        Args:
            status_code: HTTP status code
            body: Response body (will be JSON serialized)
            headers: Optional additional headers

        Returns:
            API Gateway response dict
        """
        response_headers = cls.DEFAULT_HEADERS.copy()
        if headers:
            response_headers.update(headers)

        return {
            "statusCode": status_code,
            "headers": response_headers,
            "body": json.dumps(body, default=str)
        }

    @classmethod
    def error(
        cls,
        status_code: int,
        error_code: str,
        message: str,
        details: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """
        Build an error response.

        Args:
            status_code: HTTP status code
            error_code: Application error code
            message: Error message
            details: Optional error details

        Returns:
            API Gateway response dict
        """
        body = {
            "errorCode": error_code,
            "message": message
        }
        if details:
            body["details"] = details

        logger.error(f"Error response: {status_code} - {error_code}: {message}")

        return {
            "statusCode": status_code,
            "headers": cls.DEFAULT_HEADERS.copy(),
            "body": json.dumps(body)
        }

    @classmethod
    def from_exception(cls, exception: Exception) -> Dict[str, Any]:
        """
        Build error response from exception.

        Args:
            exception: The exception to convert

        Returns:
            API Gateway response dict
        """
        from ..exceptions.permission_exceptions import PermissionServiceException

        if isinstance(exception, PermissionServiceException):
            return cls.error(
                status_code=exception.status_code,
                error_code=exception.error_code,
                message=exception.message,
                details=exception.details if exception.details else None
            )

        # Unknown exception
        logger.exception("Unexpected error")
        return cls.error(
            status_code=500,
            error_code="INTERNAL_ERROR",
            message="An unexpected error occurred"
        )
```

### handlers/list_handler.py

```python
"""Lambda handler for listing permissions."""

import json
import logging
from typing import Any, Dict

from aws_lambda_powertools import Logger, Tracer
from aws_lambda_powertools.utilities.typing import LambdaContext
from pydantic import ValidationError

from ..services.permission_service import PermissionService
from ..models.requests import ListPermissionsQueryParams
from ..utils.response_builder import ResponseBuilder
from ..exceptions.permission_exceptions import PermissionServiceException

logger = Logger()
tracer = Tracer()


@logger.inject_lambda_context
@tracer.capture_lambda_handler
def lambda_handler(event: Dict[str, Any], context: LambdaContext) -> Dict[str, Any]:
    """
    Lambda handler for GET /v1/platform/permissions.

    Lists all platform permissions with pagination and optional category filtering.

    Query Parameters:
        pageSize (int): Items per page (default 50, max 100)
        startAt (str): Pagination cursor
        category (str): Filter by category (SITE, TEAM, ORGANISATION, INVITATION, ROLE, AUDIT)

    Returns:
        200: Paginated list of permissions with HATEOAS links
        400: Invalid request parameters
        500: Internal server error
    """
    try:
        logger.info("Handling list permissions request")

        # Parse query parameters
        query_params = event.get("queryStringParameters") or {}

        params = ListPermissionsQueryParams(
            page_size=int(query_params.get("pageSize", 50)),
            start_at=query_params.get("startAt"),
            category=query_params.get("category")
        )

        # Get permissions from service
        service = PermissionService()
        response = service.list_permissions(params)

        # Return successful response
        return ResponseBuilder.success(
            status_code=200,
            body=response.model_dump(by_alias=True, exclude_none=True)
        )

    except ValidationError as e:
        logger.warning(f"Validation error: {e}")
        return ResponseBuilder.error(
            status_code=400,
            error_code="VALIDATION_ERROR",
            message="Invalid request parameters",
            details={"errors": e.errors()}
        )

    except PermissionServiceException as e:
        return ResponseBuilder.from_exception(e)

    except Exception as e:
        logger.exception(f"Unexpected error: {e}")
        return ResponseBuilder.error(
            status_code=500,
            error_code="INTERNAL_ERROR",
            message="An unexpected error occurred"
        )
```

### handlers/get_handler.py

```python
"""Lambda handler for getting a single permission."""

import json
import logging
from typing import Any, Dict

from aws_lambda_powertools import Logger, Tracer
from aws_lambda_powertools.utilities.typing import LambdaContext
from pydantic import ValidationError

from ..services.permission_service import PermissionService
from ..utils.response_builder import ResponseBuilder
from ..exceptions.permission_exceptions import (
    PermissionServiceException,
    PermissionNotFoundException,
    ValidationException,
)

logger = Logger()
tracer = Tracer()


@logger.inject_lambda_context
@tracer.capture_lambda_handler
def lambda_handler(event: Dict[str, Any], context: LambdaContext) -> Dict[str, Any]:
    """
    Lambda handler for GET /v1/platform/permissions/{permId}.

    Gets a single permission by its ID.

    Path Parameters:
        permId (str): Permission ID in format resource:action

    Returns:
        200: Permission details with HATEOAS links
        400: Invalid permission ID format
        404: Permission not found
        500: Internal server error
    """
    try:
        logger.info("Handling get permission request")

        # Extract permission ID from path parameters
        path_params = event.get("pathParameters") or {}
        permission_id = path_params.get("permId")

        if not permission_id:
            return ResponseBuilder.error(
                status_code=400,
                error_code="MISSING_PARAMETER",
                message="Permission ID is required"
            )

        # Get permission from service
        service = PermissionService()
        response = service.get_permission(permission_id)

        # Return successful response
        return ResponseBuilder.success(
            status_code=200,
            body=response.model_dump(by_alias=True, exclude_none=True)
        )

    except PermissionNotFoundException as e:
        return ResponseBuilder.from_exception(e)

    except ValidationException as e:
        return ResponseBuilder.from_exception(e)

    except PermissionServiceException as e:
        return ResponseBuilder.from_exception(e)

    except Exception as e:
        logger.exception(f"Unexpected error: {e}")
        return ResponseBuilder.error(
            status_code=500,
            error_code="INTERNAL_ERROR",
            message="An unexpected error occurred"
        )
```

### handlers/create_handler.py

```python
"""Lambda handler for creating a permission."""

import json
import logging
from typing import Any, Dict

from aws_lambda_powertools import Logger, Tracer
from aws_lambda_powertools.utilities.typing import LambdaContext
from pydantic import ValidationError

from ..services.permission_service import PermissionService
from ..models.requests import CreatePermissionRequest
from ..utils.response_builder import ResponseBuilder
from ..exceptions.permission_exceptions import (
    PermissionServiceException,
    PermissionAlreadyExistsException,
    ValidationException,
)

logger = Logger()
tracer = Tracer()


@logger.inject_lambda_context
@tracer.capture_lambda_handler
def lambda_handler(event: Dict[str, Any], context: LambdaContext) -> Dict[str, Any]:
    """
    Lambda handler for POST /v1/permissions.

    Creates a new permission (admin only).

    Request Body:
        permissionId (str): Permission ID in format resource:action
        name (str): Human-readable name (3-100 chars)
        description (str): Permission description (10-500 chars)
        resource (str): Resource type
        action (str): Action type
        category (str): Permission category
        isSystem (bool): Is system permission (default false)

    Returns:
        201: Created permission with HATEOAS links
        400: Invalid request body
        409: Permission already exists
        500: Internal server error
    """
    try:
        logger.info("Handling create permission request")

        # Parse request body
        body = event.get("body")
        if not body:
            return ResponseBuilder.error(
                status_code=400,
                error_code="MISSING_BODY",
                message="Request body is required"
            )

        if isinstance(body, str):
            body = json.loads(body)

        # Validate request
        request = CreatePermissionRequest(**body)

        # Create permission
        service = PermissionService()
        response = service.create_permission(request)

        # Return successful response
        return ResponseBuilder.success(
            status_code=201,
            body=response.model_dump(by_alias=True, exclude_none=True)
        )

    except json.JSONDecodeError as e:
        logger.warning(f"Invalid JSON: {e}")
        return ResponseBuilder.error(
            status_code=400,
            error_code="INVALID_JSON",
            message="Invalid JSON in request body"
        )

    except ValidationError as e:
        logger.warning(f"Validation error: {e}")
        return ResponseBuilder.error(
            status_code=400,
            error_code="VALIDATION_ERROR",
            message="Invalid request body",
            details={"errors": e.errors()}
        )

    except PermissionAlreadyExistsException as e:
        return ResponseBuilder.from_exception(e)

    except PermissionServiceException as e:
        return ResponseBuilder.from_exception(e)

    except Exception as e:
        logger.exception(f"Unexpected error: {e}")
        return ResponseBuilder.error(
            status_code=500,
            error_code="INTERNAL_ERROR",
            message="An unexpected error occurred"
        )
```

### handlers/update_handler.py

```python
"""Lambda handler for updating a permission."""

import json
import logging
from typing import Any, Dict

from aws_lambda_powertools import Logger, Tracer
from aws_lambda_powertools.utilities.typing import LambdaContext
from pydantic import ValidationError

from ..services.permission_service import PermissionService
from ..models.requests import UpdatePermissionRequest
from ..utils.response_builder import ResponseBuilder
from ..exceptions.permission_exceptions import (
    PermissionServiceException,
    PermissionNotFoundException,
    SystemPermissionModificationException,
    ValidationException,
)

logger = Logger()
tracer = Tracer()


@logger.inject_lambda_context
@tracer.capture_lambda_handler
def lambda_handler(event: Dict[str, Any], context: LambdaContext) -> Dict[str, Any]:
    """
    Lambda handler for PUT /v1/permissions/{permId}.

    Updates an existing permission.

    Path Parameters:
        permId (str): Permission ID in format resource:action

    Request Body (all optional):
        name (str): Human-readable name (3-100 chars)
        description (str): Permission description (10-500 chars)
        active (bool): Active status

    Returns:
        200: Updated permission with HATEOAS links
        400: Invalid request
        403: Cannot modify system permission
        404: Permission not found
        500: Internal server error
    """
    try:
        logger.info("Handling update permission request")

        # Extract permission ID from path parameters
        path_params = event.get("pathParameters") or {}
        permission_id = path_params.get("permId")

        if not permission_id:
            return ResponseBuilder.error(
                status_code=400,
                error_code="MISSING_PARAMETER",
                message="Permission ID is required"
            )

        # Parse request body
        body = event.get("body")
        if not body:
            return ResponseBuilder.error(
                status_code=400,
                error_code="MISSING_BODY",
                message="Request body is required"
            )

        if isinstance(body, str):
            body = json.loads(body)

        # Validate request
        request = UpdatePermissionRequest(**body)

        # Update permission
        service = PermissionService()
        response = service.update_permission(permission_id, request)

        # Return successful response
        return ResponseBuilder.success(
            status_code=200,
            body=response.model_dump(by_alias=True, exclude_none=True)
        )

    except json.JSONDecodeError as e:
        logger.warning(f"Invalid JSON: {e}")
        return ResponseBuilder.error(
            status_code=400,
            error_code="INVALID_JSON",
            message="Invalid JSON in request body"
        )

    except ValidationError as e:
        logger.warning(f"Validation error: {e}")
        return ResponseBuilder.error(
            status_code=400,
            error_code="VALIDATION_ERROR",
            message="Invalid request body",
            details={"errors": e.errors()}
        )

    except PermissionNotFoundException as e:
        return ResponseBuilder.from_exception(e)

    except SystemPermissionModificationException as e:
        return ResponseBuilder.from_exception(e)

    except ValidationException as e:
        return ResponseBuilder.from_exception(e)

    except PermissionServiceException as e:
        return ResponseBuilder.from_exception(e)

    except Exception as e:
        logger.exception(f"Unexpected error: {e}")
        return ResponseBuilder.error(
            status_code=500,
            error_code="INTERNAL_ERROR",
            message="An unexpected error occurred"
        )
```

### handlers/delete_handler.py

```python
"""Lambda handler for deleting a permission."""

import json
import logging
from typing import Any, Dict

from aws_lambda_powertools import Logger, Tracer
from aws_lambda_powertools.utilities.typing import LambdaContext

from ..services.permission_service import PermissionService
from ..utils.response_builder import ResponseBuilder
from ..exceptions.permission_exceptions import (
    PermissionServiceException,
    PermissionNotFoundException,
    SystemPermissionModificationException,
)

logger = Logger()
tracer = Tracer()


@logger.inject_lambda_context
@tracer.capture_lambda_handler
def lambda_handler(event: Dict[str, Any], context: LambdaContext) -> Dict[str, Any]:
    """
    Lambda handler for DELETE /v1/permissions/{permId}.

    Soft deletes a permission by setting active=false.

    Path Parameters:
        permId (str): Permission ID in format resource:action

    Returns:
        204: No content (successful deletion)
        403: Cannot delete system permission
        404: Permission not found
        500: Internal server error
    """
    try:
        logger.info("Handling delete permission request")

        # Extract permission ID from path parameters
        path_params = event.get("pathParameters") or {}
        permission_id = path_params.get("permId")

        if not permission_id:
            return ResponseBuilder.error(
                status_code=400,
                error_code="MISSING_PARAMETER",
                message="Permission ID is required"
            )

        # Delete permission
        service = PermissionService()
        service.delete_permission(permission_id)

        # Return successful response (204 No Content)
        return {
            "statusCode": 204,
            "headers": ResponseBuilder.DEFAULT_HEADERS,
            "body": ""
        }

    except PermissionNotFoundException as e:
        return ResponseBuilder.from_exception(e)

    except SystemPermissionModificationException as e:
        return ResponseBuilder.from_exception(e)

    except PermissionServiceException as e:
        return ResponseBuilder.from_exception(e)

    except Exception as e:
        logger.exception(f"Unexpected error: {e}")
        return ResponseBuilder.error(
            status_code=500,
            error_code="INTERNAL_ERROR",
            message="An unexpected error occurred"
        )
```

### handlers/seed_handler.py

```python
"""Lambda handler for seeding platform permissions."""

import json
import logging
from typing import Any, Dict

from aws_lambda_powertools import Logger, Tracer
from aws_lambda_powertools.utilities.typing import LambdaContext

from ..services.permission_service import PermissionService
from ..utils.response_builder import ResponseBuilder
from ..exceptions.permission_exceptions import PermissionServiceException

logger = Logger()
tracer = Tracer()


@logger.inject_lambda_context
@tracer.capture_lambda_handler
def lambda_handler(event: Dict[str, Any], context: LambdaContext) -> Dict[str, Any]:
    """
    Lambda handler for POST /v1/permissions/seed.

    Seeds platform permissions. This is typically run once during initial setup.

    Returns:
        201: Seed successful with count of permissions created
        500: Internal server error
    """
    try:
        logger.info("Handling seed permissions request")

        # Seed permissions
        service = PermissionService()
        count = service.seed_permissions()

        # Return successful response
        return ResponseBuilder.success(
            status_code=201,
            body={
                "message": f"Successfully seeded {count} platform permissions",
                "count": count,
                "_links": {
                    "permissions": {
                        "href": "/v1/platform/permissions"
                    }
                }
            }
        )

    except PermissionServiceException as e:
        return ResponseBuilder.from_exception(e)

    except Exception as e:
        logger.exception(f"Unexpected error: {e}")
        return ResponseBuilder.error(
            status_code=500,
            error_code="INTERNAL_ERROR",
            message="An unexpected error occurred"
        )
```

---

## Unit Tests (TDD)

### tests/__init__.py

```python
"""Permission Service Tests Package."""
```

### tests/conftest.py

```python
"""Pytest configuration and fixtures."""

import os
import json
import pytest
from datetime import datetime
from typing import Dict, Any, Generator
from unittest.mock import MagicMock, patch

import boto3
from moto import mock_aws


# Set environment variables before importing application code
os.environ["DYNAMODB_TABLE_NAME"] = "test-access-management-table"
os.environ["AWS_DEFAULT_REGION"] = "af-south-1"
os.environ["AWS_ACCESS_KEY_ID"] = "testing"
os.environ["AWS_SECRET_ACCESS_KEY"] = "testing"
os.environ["AWS_SECURITY_TOKEN"] = "testing"
os.environ["AWS_SESSION_TOKEN"] = "testing"


@pytest.fixture
def dynamodb_table():
    """Create a mock DynamoDB table."""
    with mock_aws():
        dynamodb = boto3.resource("dynamodb", region_name="af-south-1")

        table = dynamodb.create_table(
            TableName="test-access-management-table",
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
                },
            ],
            BillingMode="PAY_PER_REQUEST",
        )

        table.wait_until_exists()
        yield table


@pytest.fixture
def sample_permission_item() -> Dict[str, Any]:
    """Create a sample permission DynamoDB item."""
    return {
        "PK": "PERM#site:create",
        "SK": "METADATA",
        "permissionId": "site:create",
        "name": "Create Site",
        "description": "Allows creating new WordPress sites",
        "resource": "site",
        "action": "create",
        "category": "SITE",
        "isSystem": True,
        "active": True,
        "dateCreated": "2026-01-01T00:00:00Z",
        "GSI1PK": "CATEGORY#SITE",
        "GSI1SK": "PERM#site:create",
    }


@pytest.fixture
def sample_permission_items() -> list:
    """Create multiple sample permission items."""
    permissions = [
        {
            "permissionId": "site:create",
            "name": "Create Site",
            "description": "Allows creating new WordPress sites",
            "resource": "site",
            "action": "create",
            "category": "SITE",
        },
        {
            "permissionId": "site:read",
            "name": "View Site",
            "description": "Allows viewing site details and configurations",
            "resource": "site",
            "action": "read",
            "category": "SITE",
        },
        {
            "permissionId": "team:read",
            "name": "View Team",
            "description": "Allows viewing team details and information",
            "resource": "team",
            "action": "read",
            "category": "TEAM",
        },
    ]

    items = []
    for perm in permissions:
        items.append({
            "PK": f"PERM#{perm['permissionId']}",
            "SK": "METADATA",
            **perm,
            "isSystem": True,
            "active": True,
            "dateCreated": "2026-01-01T00:00:00Z",
            "GSI1PK": f"CATEGORY#{perm['category']}",
            "GSI1SK": f"PERM#{perm['permissionId']}",
        })

    return items


@pytest.fixture
def populated_dynamodb_table(dynamodb_table, sample_permission_items):
    """Create a DynamoDB table populated with sample data."""
    for item in sample_permission_items:
        dynamodb_table.put_item(Item=item)
    return dynamodb_table


@pytest.fixture
def lambda_context():
    """Create a mock Lambda context."""
    context = MagicMock()
    context.function_name = "test-function"
    context.memory_limit_in_mb = 256
    context.invoked_function_arn = "arn:aws:lambda:af-south-1:123456789012:function:test-function"
    context.aws_request_id = "test-request-id"
    return context


@pytest.fixture
def api_gateway_event() -> Dict[str, Any]:
    """Create a base API Gateway event."""
    return {
        "resource": "/v1/platform/permissions",
        "path": "/v1/platform/permissions",
        "httpMethod": "GET",
        "headers": {
            "Content-Type": "application/json",
            "Authorization": "Bearer test-token",
        },
        "queryStringParameters": None,
        "pathParameters": None,
        "body": None,
        "requestContext": {
            "authorizer": {
                "claims": {
                    "sub": "test-user-id",
                    "email": "test@example.com",
                }
            }
        },
    }
```

### tests/test_list_handler.py

```python
"""Tests for list_permissions Lambda handler."""

import json
import pytest
from unittest.mock import patch, MagicMock
from moto import mock_aws

from lambda.permission_service.handlers.list_handler import lambda_handler
from lambda.permission_service.repositories.permission_repository import PermissionRepository


class TestListPermissionsHandler:
    """Test suite for list_permissions handler."""

    @mock_aws
    def test_returns_empty_list_when_no_permissions(self, dynamodb_table, lambda_context, api_gateway_event):
        """Test that handler returns empty list when no permissions exist."""
        # Arrange
        with patch.object(PermissionRepository, '__init__', lambda self, *args, **kwargs: None):
            with patch.object(PermissionRepository, '_dynamodb', dynamodb_table.meta.client.meta.service_model._service_description):
                repo = PermissionRepository(dynamodb_resource=dynamodb_table.meta.client.meta.service_model._service_description)

        # Act
        with patch('lambda.permission_service.services.permission_service.PermissionRepository') as MockRepo:
            mock_repo = MagicMock()
            mock_repo.list_all.return_value = ([], None)
            MockRepo.return_value = mock_repo

            response = lambda_handler(api_gateway_event, lambda_context)

        # Assert
        assert response["statusCode"] == 200
        body = json.loads(response["body"])
        assert body["items"] == []
        assert body["count"] == 0
        assert body["moreAvailable"] == False

    @mock_aws
    def test_returns_paginated_permissions(self, populated_dynamodb_table, lambda_context, api_gateway_event, sample_permission_items):
        """Test that handler returns paginated permissions."""
        # Act
        with patch('lambda.permission_service.services.permission_service.PermissionRepository') as MockRepo:
            mock_repo = MagicMock()

            # Create mock Permission objects
            from lambda.permission_service.models.permission import Permission
            permissions = [Permission.from_dynamo_item(item) for item in sample_permission_items]
            mock_repo.list_all.return_value = (permissions, None)
            MockRepo.return_value = mock_repo

            response = lambda_handler(api_gateway_event, lambda_context)

        # Assert
        assert response["statusCode"] == 200
        body = json.loads(response["body"])
        assert len(body["items"]) == 3
        assert body["count"] == 3
        assert body["moreAvailable"] == False
        assert "_links" in body
        assert "self" in body["_links"]

    @mock_aws
    def test_respects_page_size(self, lambda_context, api_gateway_event):
        """Test that handler respects pageSize parameter."""
        # Arrange
        api_gateway_event["queryStringParameters"] = {"pageSize": "2"}

        # Act
        with patch('lambda.permission_service.services.permission_service.PermissionRepository') as MockRepo:
            mock_repo = MagicMock()
            mock_repo.list_all.return_value = ([], None)
            MockRepo.return_value = mock_repo

            response = lambda_handler(api_gateway_event, lambda_context)

        # Assert
        assert response["statusCode"] == 200
        mock_repo.list_all.assert_called_once_with(
            page_size=2,
            start_key=None,
            category=None
        )

    @mock_aws
    def test_invalid_page_size_returns_400(self, lambda_context, api_gateway_event):
        """Test that invalid pageSize returns 400 error."""
        # Arrange
        api_gateway_event["queryStringParameters"] = {"pageSize": "200"}  # Exceeds max

        # Act
        with patch('lambda.permission_service.services.permission_service.PermissionRepository') as MockRepo:
            mock_repo = MagicMock()
            MockRepo.return_value = mock_repo

            response = lambda_handler(api_gateway_event, lambda_context)

        # Assert
        assert response["statusCode"] == 400
        body = json.loads(response["body"])
        assert body["errorCode"] == "VALIDATION_ERROR"

    @mock_aws
    def test_filters_by_category(self, lambda_context, api_gateway_event):
        """Test that handler filters by category."""
        # Arrange
        api_gateway_event["queryStringParameters"] = {"category": "SITE"}

        # Act
        with patch('lambda.permission_service.services.permission_service.PermissionRepository') as MockRepo:
            mock_repo = MagicMock()
            mock_repo.list_all.return_value = ([], None)
            MockRepo.return_value = mock_repo

            response = lambda_handler(api_gateway_event, lambda_context)

        # Assert
        assert response["statusCode"] == 200
        mock_repo.list_all.assert_called_once_with(
            page_size=50,
            start_key=None,
            category="SITE"
        )

    @mock_aws
    def test_returns_hateoas_links(self, lambda_context, api_gateway_event):
        """Test that response includes HATEOAS links."""
        # Act
        with patch('lambda.permission_service.services.permission_service.PermissionRepository') as MockRepo:
            mock_repo = MagicMock()
            mock_repo.list_all.return_value = ([], None)
            MockRepo.return_value = mock_repo

            response = lambda_handler(api_gateway_event, lambda_context)

        # Assert
        assert response["statusCode"] == 200
        body = json.loads(response["body"])
        assert "_links" in body
        assert "self" in body["_links"]
        assert "href" in body["_links"]["self"]

    @mock_aws
    def test_returns_next_link_when_more_available(self, lambda_context, api_gateway_event):
        """Test that next link is included when more pages available."""
        # Act
        with patch('lambda.permission_service.services.permission_service.PermissionRepository') as MockRepo:
            mock_repo = MagicMock()

            from lambda.permission_service.models.permission import Permission
            from datetime import datetime
            perm = Permission(
                permission_id="site:create",
                name="Create Site",
                description="Allows creating new WordPress sites",
                resource="site",
                action="create",
                category="SITE",
                is_system=True,
                active=True,
                date_created=datetime.utcnow()
            )
            mock_repo.list_all.return_value = ([perm], "site:read")
            MockRepo.return_value = mock_repo

            response = lambda_handler(api_gateway_event, lambda_context)

        # Assert
        assert response["statusCode"] == 200
        body = json.loads(response["body"])
        assert body["moreAvailable"] == True
        assert "next" in body["_links"]
        assert "startAt=site:read" in body["_links"]["next"]["href"]
```

### tests/test_get_handler.py

```python
"""Tests for get_permission Lambda handler."""

import json
import pytest
from unittest.mock import patch, MagicMock
from moto import mock_aws
from datetime import datetime

from lambda.permission_service.handlers.get_handler import lambda_handler
from lambda.permission_service.models.permission import Permission


class TestGetPermissionHandler:
    """Test suite for get_permission handler."""

    @mock_aws
    def test_returns_permission_when_found(self, lambda_context, api_gateway_event):
        """Test that handler returns permission when it exists."""
        # Arrange
        api_gateway_event["pathParameters"] = {"permId": "site:create"}

        # Act
        with patch('lambda.permission_service.services.permission_service.PermissionRepository') as MockRepo:
            mock_repo = MagicMock()
            mock_perm = Permission(
                permission_id="site:create",
                name="Create Site",
                description="Allows creating new WordPress sites",
                resource="site",
                action="create",
                category="SITE",
                is_system=True,
                active=True,
                date_created=datetime.utcnow()
            )
            mock_repo.get_by_id.return_value = mock_perm
            MockRepo.return_value = mock_repo

            response = lambda_handler(api_gateway_event, lambda_context)

        # Assert
        assert response["statusCode"] == 200
        body = json.loads(response["body"])
        assert body["id"] == "site:create"
        assert body["name"] == "Create Site"
        assert body["category"] == "SITE"

    @mock_aws
    def test_returns_404_when_not_found(self, lambda_context, api_gateway_event):
        """Test that handler returns 404 when permission not found."""
        # Arrange
        api_gateway_event["pathParameters"] = {"permId": "nonexistent:permission"}

        # Act
        with patch('lambda.permission_service.services.permission_service.PermissionRepository') as MockRepo:
            mock_repo = MagicMock()
            mock_repo.get_by_id.return_value = None
            MockRepo.return_value = mock_repo

            response = lambda_handler(api_gateway_event, lambda_context)

        # Assert
        assert response["statusCode"] == 404
        body = json.loads(response["body"])
        assert body["errorCode"] == "PERMISSION_NOT_FOUND"

    @mock_aws
    def test_returns_400_when_missing_perm_id(self, lambda_context, api_gateway_event):
        """Test that handler returns 400 when permId is missing."""
        # Arrange
        api_gateway_event["pathParameters"] = {}

        # Act
        response = lambda_handler(api_gateway_event, lambda_context)

        # Assert
        assert response["statusCode"] == 400
        body = json.loads(response["body"])
        assert body["errorCode"] == "MISSING_PARAMETER"

    @mock_aws
    def test_returns_400_for_invalid_permission_id_format(self, lambda_context, api_gateway_event):
        """Test that handler returns 400 for invalid permission ID format."""
        # Arrange
        api_gateway_event["pathParameters"] = {"permId": "invalid-format"}

        # Act
        with patch('lambda.permission_service.services.permission_service.PermissionRepository') as MockRepo:
            MockRepo.return_value = MagicMock()
            response = lambda_handler(api_gateway_event, lambda_context)

        # Assert
        assert response["statusCode"] == 400
        body = json.loads(response["body"])
        assert body["errorCode"] == "VALIDATION_ERROR"

    @mock_aws
    def test_includes_hateoas_links(self, lambda_context, api_gateway_event):
        """Test that response includes HATEOAS links."""
        # Arrange
        api_gateway_event["pathParameters"] = {"permId": "site:create"}

        # Act
        with patch('lambda.permission_service.services.permission_service.PermissionRepository') as MockRepo:
            mock_repo = MagicMock()
            mock_perm = Permission(
                permission_id="site:create",
                name="Create Site",
                description="Allows creating new WordPress sites",
                resource="site",
                action="create",
                category="SITE",
                is_system=True,
                active=True,
                date_created=datetime.utcnow()
            )
            mock_repo.get_by_id.return_value = mock_perm
            MockRepo.return_value = mock_repo

            response = lambda_handler(api_gateway_event, lambda_context)

        # Assert
        assert response["statusCode"] == 200
        body = json.loads(response["body"])
        assert "_links" in body
        assert "self" in body["_links"]
        assert "/site:create" in body["_links"]["self"]["href"]
```

### tests/test_create_handler.py

```python
"""Tests for create_permission Lambda handler."""

import json
import pytest
from unittest.mock import patch, MagicMock
from moto import mock_aws
from datetime import datetime

from lambda.permission_service.handlers.create_handler import lambda_handler
from lambda.permission_service.models.permission import Permission


class TestCreatePermissionHandler:
    """Test suite for create_permission handler."""

    @mock_aws
    def test_creates_permission_successfully(self, lambda_context, api_gateway_event):
        """Test that handler creates permission successfully."""
        # Arrange
        api_gateway_event["httpMethod"] = "POST"
        api_gateway_event["body"] = json.dumps({
            "permissionId": "custom:action",
            "name": "Custom Action",
            "description": "A custom permission for testing purposes",
            "resource": "custom",
            "action": "action",
            "category": "SITE",
            "isSystem": False
        })

        # Act
        with patch('lambda.permission_service.services.permission_service.PermissionRepository') as MockRepo:
            mock_repo = MagicMock()
            mock_repo.get_by_id.return_value = None  # Permission doesn't exist

            def create_side_effect(perm):
                return perm
            mock_repo.create.side_effect = create_side_effect
            MockRepo.return_value = mock_repo

            response = lambda_handler(api_gateway_event, lambda_context)

        # Assert
        assert response["statusCode"] == 201
        body = json.loads(response["body"])
        assert body["id"] == "custom:action"
        assert body["name"] == "Custom Action"

    @mock_aws
    def test_returns_409_when_permission_exists(self, lambda_context, api_gateway_event):
        """Test that handler returns 409 when permission already exists."""
        # Arrange
        api_gateway_event["httpMethod"] = "POST"
        api_gateway_event["body"] = json.dumps({
            "permissionId": "site:create",
            "name": "Create Site",
            "description": "Allows creating new WordPress sites",
            "resource": "site",
            "action": "create",
            "category": "SITE"
        })

        # Act
        with patch('lambda.permission_service.services.permission_service.PermissionRepository') as MockRepo:
            mock_repo = MagicMock()
            existing_perm = Permission(
                permission_id="site:create",
                name="Create Site",
                description="Allows creating new WordPress sites",
                resource="site",
                action="create",
                category="SITE",
                is_system=True,
                active=True,
                date_created=datetime.utcnow()
            )
            mock_repo.get_by_id.return_value = existing_perm
            MockRepo.return_value = mock_repo

            response = lambda_handler(api_gateway_event, lambda_context)

        # Assert
        assert response["statusCode"] == 409
        body = json.loads(response["body"])
        assert body["errorCode"] == "PERMISSION_ALREADY_EXISTS"

    @mock_aws
    def test_returns_400_for_missing_body(self, lambda_context, api_gateway_event):
        """Test that handler returns 400 when request body is missing."""
        # Arrange
        api_gateway_event["httpMethod"] = "POST"
        api_gateway_event["body"] = None

        # Act
        response = lambda_handler(api_gateway_event, lambda_context)

        # Assert
        assert response["statusCode"] == 400
        body = json.loads(response["body"])
        assert body["errorCode"] == "MISSING_BODY"

    @mock_aws
    def test_returns_400_for_invalid_json(self, lambda_context, api_gateway_event):
        """Test that handler returns 400 for invalid JSON."""
        # Arrange
        api_gateway_event["httpMethod"] = "POST"
        api_gateway_event["body"] = "invalid json {"

        # Act
        response = lambda_handler(api_gateway_event, lambda_context)

        # Assert
        assert response["statusCode"] == 400
        body = json.loads(response["body"])
        assert body["errorCode"] == "INVALID_JSON"

    @mock_aws
    def test_returns_400_for_validation_error(self, lambda_context, api_gateway_event):
        """Test that handler returns 400 for validation errors."""
        # Arrange
        api_gateway_event["httpMethod"] = "POST"
        api_gateway_event["body"] = json.dumps({
            "permissionId": "invalid",  # Missing colon
            "name": "Te",  # Too short
            "description": "Short",  # Too short
            "resource": "test",
            "action": "action",
            "category": "INVALID"  # Invalid category
        })

        # Act
        response = lambda_handler(api_gateway_event, lambda_context)

        # Assert
        assert response["statusCode"] == 400
        body = json.loads(response["body"])
        assert body["errorCode"] == "VALIDATION_ERROR"

    @mock_aws
    def test_returns_400_for_invalid_permission_id_format(self, lambda_context, api_gateway_event):
        """Test that handler returns 400 for invalid permission ID format."""
        # Arrange
        api_gateway_event["httpMethod"] = "POST"
        api_gateway_event["body"] = json.dumps({
            "permissionId": "no-colon-here",
            "name": "Test Permission",
            "description": "A test permission for validation",
            "resource": "test",
            "action": "action",
            "category": "SITE"
        })

        # Act
        response = lambda_handler(api_gateway_event, lambda_context)

        # Assert
        assert response["statusCode"] == 400
        body = json.loads(response["body"])
        assert body["errorCode"] == "VALIDATION_ERROR"
```

### tests/test_update_handler.py

```python
"""Tests for update_permission Lambda handler."""

import json
import pytest
from unittest.mock import patch, MagicMock
from moto import mock_aws
from datetime import datetime

from lambda.permission_service.handlers.update_handler import lambda_handler
from lambda.permission_service.models.permission import Permission


class TestUpdatePermissionHandler:
    """Test suite for update_permission handler."""

    @mock_aws
    def test_updates_permission_successfully(self, lambda_context, api_gateway_event):
        """Test that handler updates permission successfully."""
        # Arrange
        api_gateway_event["httpMethod"] = "PUT"
        api_gateway_event["pathParameters"] = {"permId": "custom:action"}
        api_gateway_event["body"] = json.dumps({
            "name": "Updated Custom Action",
            "description": "An updated custom permission description"
        })

        # Act
        with patch('lambda.permission_service.services.permission_service.PermissionRepository') as MockRepo:
            mock_repo = MagicMock()
            existing_perm = Permission(
                permission_id="custom:action",
                name="Custom Action",
                description="A custom permission for testing purposes",
                resource="custom",
                action="action",
                category="SITE",
                is_system=False,  # Not a system permission
                active=True,
                date_created=datetime.utcnow()
            )
            mock_repo.get_by_id.return_value = existing_perm

            def update_side_effect(perm):
                return perm
            mock_repo.update.side_effect = update_side_effect
            MockRepo.return_value = mock_repo

            response = lambda_handler(api_gateway_event, lambda_context)

        # Assert
        assert response["statusCode"] == 200
        body = json.loads(response["body"])
        assert body["id"] == "custom:action"
        assert body["name"] == "Updated Custom Action"

    @mock_aws
    def test_returns_404_when_permission_not_found(self, lambda_context, api_gateway_event):
        """Test that handler returns 404 when permission not found."""
        # Arrange
        api_gateway_event["httpMethod"] = "PUT"
        api_gateway_event["pathParameters"] = {"permId": "nonexistent:permission"}
        api_gateway_event["body"] = json.dumps({"name": "Updated Name"})

        # Act
        with patch('lambda.permission_service.services.permission_service.PermissionRepository') as MockRepo:
            mock_repo = MagicMock()
            mock_repo.get_by_id.return_value = None
            MockRepo.return_value = mock_repo

            response = lambda_handler(api_gateway_event, lambda_context)

        # Assert
        assert response["statusCode"] == 404
        body = json.loads(response["body"])
        assert body["errorCode"] == "PERMISSION_NOT_FOUND"

    @mock_aws
    def test_returns_403_for_system_permission(self, lambda_context, api_gateway_event):
        """Test that handler returns 403 when trying to modify system permission."""
        # Arrange
        api_gateway_event["httpMethod"] = "PUT"
        api_gateway_event["pathParameters"] = {"permId": "site:create"}
        api_gateway_event["body"] = json.dumps({"name": "Modified Name"})

        # Act
        with patch('lambda.permission_service.services.permission_service.PermissionRepository') as MockRepo:
            mock_repo = MagicMock()
            system_perm = Permission(
                permission_id="site:create",
                name="Create Site",
                description="Allows creating new WordPress sites",
                resource="site",
                action="create",
                category="SITE",
                is_system=True,  # System permission
                active=True,
                date_created=datetime.utcnow()
            )
            mock_repo.get_by_id.return_value = system_perm
            MockRepo.return_value = mock_repo

            response = lambda_handler(api_gateway_event, lambda_context)

        # Assert
        assert response["statusCode"] == 403
        body = json.loads(response["body"])
        assert body["errorCode"] == "SYSTEM_PERMISSION_MODIFICATION"

    @mock_aws
    def test_returns_400_for_missing_body(self, lambda_context, api_gateway_event):
        """Test that handler returns 400 when request body is missing."""
        # Arrange
        api_gateway_event["httpMethod"] = "PUT"
        api_gateway_event["pathParameters"] = {"permId": "custom:action"}
        api_gateway_event["body"] = None

        # Act
        response = lambda_handler(api_gateway_event, lambda_context)

        # Assert
        assert response["statusCode"] == 400
        body = json.loads(response["body"])
        assert body["errorCode"] == "MISSING_BODY"

    @mock_aws
    def test_returns_400_for_empty_updates(self, lambda_context, api_gateway_event):
        """Test that handler returns 400 when no updates provided."""
        # Arrange
        api_gateway_event["httpMethod"] = "PUT"
        api_gateway_event["pathParameters"] = {"permId": "custom:action"}
        api_gateway_event["body"] = json.dumps({})

        # Act
        with patch('lambda.permission_service.services.permission_service.PermissionRepository') as MockRepo:
            mock_repo = MagicMock()
            existing_perm = Permission(
                permission_id="custom:action",
                name="Custom Action",
                description="A custom permission for testing purposes",
                resource="custom",
                action="action",
                category="SITE",
                is_system=False,
                active=True,
                date_created=datetime.utcnow()
            )
            mock_repo.get_by_id.return_value = existing_perm
            MockRepo.return_value = mock_repo

            response = lambda_handler(api_gateway_event, lambda_context)

        # Assert
        assert response["statusCode"] == 400
        body = json.loads(response["body"])
        assert body["errorCode"] == "VALIDATION_ERROR"
```

### tests/test_delete_handler.py

```python
"""Tests for delete_permission Lambda handler."""

import json
import pytest
from unittest.mock import patch, MagicMock
from moto import mock_aws
from datetime import datetime

from lambda.permission_service.handlers.delete_handler import lambda_handler
from lambda.permission_service.models.permission import Permission


class TestDeletePermissionHandler:
    """Test suite for delete_permission handler."""

    @mock_aws
    def test_deletes_permission_successfully(self, lambda_context, api_gateway_event):
        """Test that handler deletes permission successfully."""
        # Arrange
        api_gateway_event["httpMethod"] = "DELETE"
        api_gateway_event["pathParameters"] = {"permId": "custom:action"}

        # Act
        with patch('lambda.permission_service.services.permission_service.PermissionRepository') as MockRepo:
            mock_repo = MagicMock()
            existing_perm = Permission(
                permission_id="custom:action",
                name="Custom Action",
                description="A custom permission for testing purposes",
                resource="custom",
                action="action",
                category="SITE",
                is_system=False,  # Not a system permission
                active=True,
                date_created=datetime.utcnow()
            )
            mock_repo.get_by_id.return_value = existing_perm
            mock_repo.delete.return_value = True
            MockRepo.return_value = mock_repo

            response = lambda_handler(api_gateway_event, lambda_context)

        # Assert
        assert response["statusCode"] == 204
        assert response["body"] == ""

    @mock_aws
    def test_returns_404_when_permission_not_found(self, lambda_context, api_gateway_event):
        """Test that handler returns 404 when permission not found."""
        # Arrange
        api_gateway_event["httpMethod"] = "DELETE"
        api_gateway_event["pathParameters"] = {"permId": "nonexistent:permission"}

        # Act
        with patch('lambda.permission_service.services.permission_service.PermissionRepository') as MockRepo:
            mock_repo = MagicMock()
            mock_repo.get_by_id.return_value = None
            MockRepo.return_value = mock_repo

            response = lambda_handler(api_gateway_event, lambda_context)

        # Assert
        assert response["statusCode"] == 404
        body = json.loads(response["body"])
        assert body["errorCode"] == "PERMISSION_NOT_FOUND"

    @mock_aws
    def test_returns_403_for_system_permission(self, lambda_context, api_gateway_event):
        """Test that handler returns 403 when trying to delete system permission."""
        # Arrange
        api_gateway_event["httpMethod"] = "DELETE"
        api_gateway_event["pathParameters"] = {"permId": "site:create"}

        # Act
        with patch('lambda.permission_service.services.permission_service.PermissionRepository') as MockRepo:
            mock_repo = MagicMock()
            system_perm = Permission(
                permission_id="site:create",
                name="Create Site",
                description="Allows creating new WordPress sites",
                resource="site",
                action="create",
                category="SITE",
                is_system=True,  # System permission
                active=True,
                date_created=datetime.utcnow()
            )
            mock_repo.get_by_id.return_value = system_perm
            MockRepo.return_value = mock_repo

            response = lambda_handler(api_gateway_event, lambda_context)

        # Assert
        assert response["statusCode"] == 403
        body = json.loads(response["body"])
        assert body["errorCode"] == "SYSTEM_PERMISSION_MODIFICATION"

    @mock_aws
    def test_returns_400_for_missing_permission_id(self, lambda_context, api_gateway_event):
        """Test that handler returns 400 when permission ID is missing."""
        # Arrange
        api_gateway_event["httpMethod"] = "DELETE"
        api_gateway_event["pathParameters"] = {}

        # Act
        response = lambda_handler(api_gateway_event, lambda_context)

        # Assert
        assert response["statusCode"] == 400
        body = json.loads(response["body"])
        assert body["errorCode"] == "MISSING_PARAMETER"
```

### tests/test_seed_handler.py

```python
"""Tests for seed_permissions Lambda handler."""

import json
import pytest
from unittest.mock import patch, MagicMock
from moto import mock_aws

from lambda.permission_service.handlers.seed_handler import lambda_handler
from lambda.permission_service.services.permission_service import PermissionService


class TestSeedPermissionsHandler:
    """Test suite for seed_permissions handler."""

    @mock_aws
    def test_seeds_permissions_successfully(self, lambda_context, api_gateway_event):
        """Test that handler seeds permissions successfully."""
        # Arrange
        api_gateway_event["httpMethod"] = "POST"
        api_gateway_event["path"] = "/v1/permissions/seed"

        # Act
        with patch('lambda.permission_service.services.permission_service.PermissionRepository') as MockRepo:
            mock_repo = MagicMock()
            mock_repo.batch_create.return_value = len(PermissionService.PLATFORM_PERMISSIONS)
            MockRepo.return_value = mock_repo

            response = lambda_handler(api_gateway_event, lambda_context)

        # Assert
        assert response["statusCode"] == 201
        body = json.loads(response["body"])
        assert "Successfully seeded" in body["message"]
        assert body["count"] == len(PermissionService.PLATFORM_PERMISSIONS)
        assert "_links" in body
        assert "permissions" in body["_links"]

    @mock_aws
    def test_returns_500_on_error(self, lambda_context, api_gateway_event):
        """Test that handler returns 500 on unexpected error."""
        # Arrange
        api_gateway_event["httpMethod"] = "POST"
        api_gateway_event["path"] = "/v1/permissions/seed"

        # Act
        with patch('lambda.permission_service.services.permission_service.PermissionRepository') as MockRepo:
            mock_repo = MagicMock()
            mock_repo.batch_create.side_effect = Exception("Database error")
            MockRepo.return_value = mock_repo

            response = lambda_handler(api_gateway_event, lambda_context)

        # Assert
        assert response["statusCode"] == 500
        body = json.loads(response["body"])
        assert body["errorCode"] == "INTERNAL_ERROR"

    @mock_aws
    def test_seeds_expected_number_of_permissions(self, lambda_context, api_gateway_event):
        """Test that correct number of permissions are seeded."""
        # Arrange
        api_gateway_event["httpMethod"] = "POST"

        # Act
        with patch('lambda.permission_service.services.permission_service.PermissionRepository') as MockRepo:
            mock_repo = MagicMock()

            # Capture the permissions passed to batch_create
            captured_permissions = []
            def capture_permissions(permissions):
                captured_permissions.extend(permissions)
                return len(permissions)
            mock_repo.batch_create.side_effect = capture_permissions
            MockRepo.return_value = mock_repo

            response = lambda_handler(api_gateway_event, lambda_context)

        # Assert
        assert response["statusCode"] == 201
        # Should have 25 platform permissions
        assert len(captured_permissions) == 25

        # Verify categories
        categories = set(p.category for p in captured_permissions)
        expected_categories = {"SITE", "TEAM", "ORGANISATION", "INVITATION", "ROLE", "AUDIT"}
        assert categories == expected_categories

    @mock_aws
    def test_all_seeded_permissions_are_system_permissions(self, lambda_context, api_gateway_event):
        """Test that all seeded permissions are marked as system permissions."""
        # Arrange
        api_gateway_event["httpMethod"] = "POST"

        # Act
        with patch('lambda.permission_service.services.permission_service.PermissionRepository') as MockRepo:
            mock_repo = MagicMock()

            captured_permissions = []
            def capture_permissions(permissions):
                captured_permissions.extend(permissions)
                return len(permissions)
            mock_repo.batch_create.side_effect = capture_permissions
            MockRepo.return_value = mock_repo

            response = lambda_handler(api_gateway_event, lambda_context)

        # Assert
        assert response["statusCode"] == 201
        # All permissions should be system permissions
        assert all(p.is_system for p in captured_permissions)
        # All permissions should be active
        assert all(p.active for p in captured_permissions)
```

---

## Seed Data

### Platform Permissions (25 total)

| # | Permission ID | Name | Description | Category |
|---|---------------|------|-------------|----------|
| 1 | site:create | Create Site | Allows creating new WordPress sites | SITE |
| 2 | site:read | View Site | Allows viewing site details and configurations | SITE |
| 3 | site:update | Update Site | Allows modifying site settings and content | SITE |
| 4 | site:delete | Delete Site | Allows deleting sites (soft delete) | SITE |
| 5 | site:publish | Publish Site | Allows publishing site changes to production | SITE |
| 6 | site:backup | Backup Site | Allows creating site backups | SITE |
| 7 | site:restore | Restore Site | Allows restoring site from backup | SITE |
| 8 | team:read | View Team | Allows viewing team details and information | TEAM |
| 9 | team:update | Update Team | Allows modifying team settings and details | TEAM |
| 10 | team:member:add | Add Team Member | Allows adding users to the team | TEAM |
| 11 | team:member:remove | Remove Team Member | Allows removing users from the team | TEAM |
| 12 | team:member:read | View Team Members | Allows viewing team member list | TEAM |
| 13 | org:read | View Organisation | Allows viewing organisation details | ORGANISATION |
| 14 | org:update | Update Organisation | Allows modifying organisation settings | ORGANISATION |
| 15 | org:hierarchy:manage | Manage Hierarchy | Allows managing organisation hierarchy structure | ORGANISATION |
| 16 | org:user:manage | Manage Users | Allows managing organisation users | ORGANISATION |
| 17 | invitation:create | Create Invitation | Allows creating user invitations | INVITATION |
| 18 | invitation:read | View Invitations | Allows viewing invitation status | INVITATION |
| 19 | invitation:revoke | Revoke Invitation | Allows revoking pending invitations | INVITATION |
| 20 | invitation:resend | Resend Invitation | Allows resending invitation emails | INVITATION |
| 21 | role:create | Create Role | Allows creating new custom roles | ROLE |
| 22 | role:update | Update Role | Allows modifying existing roles | ROLE |
| 23 | role:assign | Assign Role | Allows assigning roles to users | ROLE |
| 24 | audit:read | View Audit Logs | Allows viewing audit log entries | AUDIT |
| 25 | audit:export | Export Audit Data | Allows exporting audit data to files | AUDIT |

---

## Deployment Configuration

### Lambda Configuration (serverless.yml equivalent)

```yaml
# Lambda function configurations
functions:
  list_permissions:
    handler: lambda.permission_service.handlers.list_handler.lambda_handler
    runtime: python3.12
    memorySize: 256
    timeout: 30
    architecture: arm64
    environment:
      DYNAMODB_TABLE_NAME: ${self:custom.tableName}
      LOG_LEVEL: INFO
    events:
      - http:
          path: /v1/platform/permissions
          method: get
          authorizer:
            type: COGNITO_USER_POOLS
            authorizerId: !Ref CognitoAuthorizer

  get_permission:
    handler: lambda.permission_service.handlers.get_handler.lambda_handler
    runtime: python3.12
    memorySize: 256
    timeout: 30
    architecture: arm64
    environment:
      DYNAMODB_TABLE_NAME: ${self:custom.tableName}
      LOG_LEVEL: INFO
    events:
      - http:
          path: /v1/platform/permissions/{permId}
          method: get
          authorizer:
            type: COGNITO_USER_POOLS
            authorizerId: !Ref CognitoAuthorizer

  create_permission:
    handler: lambda.permission_service.handlers.create_handler.lambda_handler
    runtime: python3.12
    memorySize: 256
    timeout: 30
    architecture: arm64
    environment:
      DYNAMODB_TABLE_NAME: ${self:custom.tableName}
      LOG_LEVEL: INFO
    events:
      - http:
          path: /v1/permissions
          method: post
          authorizer:
            type: COGNITO_USER_POOLS
            authorizerId: !Ref CognitoAuthorizer

  update_permission:
    handler: lambda.permission_service.handlers.update_handler.lambda_handler
    runtime: python3.12
    memorySize: 256
    timeout: 30
    architecture: arm64
    environment:
      DYNAMODB_TABLE_NAME: ${self:custom.tableName}
      LOG_LEVEL: INFO
    events:
      - http:
          path: /v1/permissions/{permId}
          method: put
          authorizer:
            type: COGNITO_USER_POOLS
            authorizerId: !Ref CognitoAuthorizer

  delete_permission:
    handler: lambda.permission_service.handlers.delete_handler.lambda_handler
    runtime: python3.12
    memorySize: 256
    timeout: 30
    architecture: arm64
    environment:
      DYNAMODB_TABLE_NAME: ${self:custom.tableName}
      LOG_LEVEL: INFO
    events:
      - http:
          path: /v1/permissions/{permId}
          method: delete
          authorizer:
            type: COGNITO_USER_POOLS
            authorizerId: !Ref CognitoAuthorizer

  seed_permissions:
    handler: lambda.permission_service.handlers.seed_handler.lambda_handler
    runtime: python3.12
    memorySize: 256
    timeout: 60
    architecture: arm64
    environment:
      DYNAMODB_TABLE_NAME: ${self:custom.tableName}
      LOG_LEVEL: INFO
    events:
      - http:
          path: /v1/permissions/seed
          method: post
          authorizer:
            type: COGNITO_USER_POOLS
            authorizerId: !Ref CognitoAuthorizer

custom:
  tableName: bbws-aipagebuilder-${opt:stage, 'dev'}-ddb-access-management
```

### IAM Role Policy

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem",
        "dynamodb:Query",
        "dynamodb:Scan",
        "dynamodb:BatchWriteItem"
      ],
      "Resource": [
        "arn:aws:dynamodb:${AWS::Region}:${AWS::AccountId}:table/bbws-aipagebuilder-*-ddb-access-management",
        "arn:aws:dynamodb:${AWS::Region}:${AWS::AccountId}:table/bbws-aipagebuilder-*-ddb-access-management/index/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:${AWS::Region}:${AWS::AccountId}:log-group:/aws/lambda/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "xray:PutTraceSegments",
        "xray:PutTelemetryRecords"
      ],
      "Resource": "*"
    }
  ]
}
```

---

## Success Criteria Checklist

- [x] All 6 Lambda handlers implemented
- [x] Pydantic models match LLD specification
- [x] Repository pattern with DynamoDB operations
- [x] Service layer with business logic
- [x] Tests written FIRST (TDD approach demonstrated)
- [x] All tests designed to pass with moto mocking
- [x] HATEOAS response format with _links
- [x] Error handling with proper status codes (400, 403, 404, 409, 500)
- [x] Logging implemented via AWS Lambda Powertools
- [x] > 80% code coverage target in pytest.ini

---

## Implementation Notes

### TDD Approach
Tests were designed first to define expected behavior:
1. List handler tests: empty list, pagination, category filtering, HATEOAS links
2. Get handler tests: found, not found, invalid format, HATEOAS links
3. Create handler tests: success, already exists, validation errors
4. Update handler tests: success, not found, system permission protection
5. Delete handler tests: success, not found, system permission protection
6. Seed handler tests: success, correct count, all system permissions

### OOP Principles Applied
- **Single Responsibility**: Each class has one purpose (Repository for data access, Service for business logic, Handler for HTTP)
- **Dependency Injection**: Repository can be injected into Service for testing
- **Factory Methods**: `from_dynamo_item` and `from_permission` for object creation
- **Encapsulation**: Private methods prefixed with underscore

### Error Handling Strategy
- Custom exception hierarchy with base `PermissionServiceException`
- Specific exceptions: `PermissionNotFoundException`, `PermissionAlreadyExistsException`, `SystemPermissionModificationException`
- Consistent error response format with `errorCode`, `message`, and optional `details`

### HATEOAS Implementation
- All responses include `_links` section
- List responses include `self` and `next` (when paginated)
- Single resource responses include `self` link
- Links follow the pattern `/v1/platform/permissions/{permId}`

---

**Worker**: worker-1-permission-service-lambdas
**Status**: COMPLETE
**Date**: 2026-01-23
