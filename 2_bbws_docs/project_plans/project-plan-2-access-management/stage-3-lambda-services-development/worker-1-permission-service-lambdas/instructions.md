# Worker Instructions: Permission Service Lambdas

**Worker ID**: worker-1-permission-service-lambdas
**Stage**: Stage 3 - Lambda Services Development
**Project**: project-plan-2-access-management

---

## Task

Implement 6 Lambda functions for the Permission Service using TDD and OOP principles. Create handlers, models, services, repositories, and tests.

---

## Inputs

**From Stage 1**:
- `/stage-1-lld-review-analysis/worker-1-permission-service-review/output.md`

**From Stage 2**:
- DynamoDB table structure
- IAM role configuration

**LLD Reference**:
- `/2_bbws_docs/LLDs/2.8.1_LLD_Permission_Service.md`

---

## Lambda Functions (6)

| # | Function | Method | Endpoint | Priority |
|---|----------|--------|----------|----------|
| 1 | list_permissions | GET | /v1/permissions | HIGH |
| 2 | get_permission | GET | /v1/permissions/{id} | HIGH |
| 3 | create_permission | POST | /v1/permissions | HIGH |
| 4 | update_permission | PUT | /v1/permissions/{id} | MEDIUM |
| 5 | delete_permission | DELETE | /v1/permissions/{id} | MEDIUM |
| 6 | seed_permissions | POST | /v1/permissions/seed | LOW |

---

## Deliverables

Create comprehensive Python code in `output.md`:

### 1. Project Structure
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
│   └── requests.py
├── services/
│   ├── __init__.py
│   └── permission_service.py
├── repositories/
│   ├── __init__.py
│   └── permission_repository.py
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

### 2. Pydantic Models

```python
from pydantic import BaseModel, Field
from enum import Enum
from typing import Optional, List
from datetime import datetime

class PermissionScope(str, Enum):
    PLATFORM = "PLATFORM"
    ORGANISATION = "ORGANISATION"
    TEAM = "TEAM"
    SITE = "SITE"

class PermissionAction(str, Enum):
    READ = "READ"
    WRITE = "WRITE"
    DELETE = "DELETE"
    ADMIN = "ADMIN"

class Permission(BaseModel):
    id: str
    name: str
    description: str
    scope: PermissionScope
    action: PermissionAction
    resource: str
    is_system: bool = False
    active: bool = True
    created_at: datetime
    updated_at: datetime
```

### 3. Repository Pattern

```python
class PermissionRepository:
    def __init__(self, table_name: str):
        self.table = boto3.resource('dynamodb').Table(table_name)

    def get_by_id(self, permission_id: str) -> Optional[Permission]:
        ...

    def list_all(self, page_size: int, start_key: Optional[str]) -> Tuple[List[Permission], Optional[str]]:
        ...

    def create(self, permission: Permission) -> Permission:
        ...

    def update(self, permission: Permission) -> Permission:
        ...

    def delete(self, permission_id: str) -> bool:
        ...
```

### 4. Service Layer

```python
class PermissionService:
    def __init__(self, repository: PermissionRepository):
        self.repository = repository

    def list_permissions(self, page_size: int, start_at: Optional[str]) -> PaginatedResponse:
        ...

    def get_permission(self, permission_id: str) -> Permission:
        ...

    def create_permission(self, request: CreatePermissionRequest) -> Permission:
        ...
```

### 5. Handler Pattern

```python
def lambda_handler(event: dict, context) -> dict:
    try:
        # Parse request
        # Validate input
        # Call service
        # Return HATEOAS response
    except ValidationError as e:
        return error_response(400, str(e))
    except NotFoundException as e:
        return error_response(404, str(e))
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        return error_response(500, "Internal server error")
```

### 6. Tests (TDD)

```python
import pytest
from moto import mock_dynamodb

@mock_dynamodb
class TestListPermissions:
    def test_returns_empty_list_when_no_permissions(self):
        ...

    def test_returns_paginated_permissions(self):
        ...

    def test_respects_page_size(self):
        ...
```

---

## Success Criteria

- [ ] All 6 Lambda handlers implemented
- [ ] Pydantic models match LLD specification
- [ ] Repository pattern with DynamoDB
- [ ] Service layer with business logic
- [ ] Tests written FIRST (TDD)
- [ ] All tests pass with moto mocking
- [ ] HATEOAS response format
- [ ] Error handling with proper status codes
- [ ] Logging implemented
- [ ] > 80% code coverage

---

## Execution Steps

1. Read Stage 1 output for API contracts
2. Create Pydantic models (Permission, requests, responses)
3. Write tests for list_permissions (TDD)
4. Implement list_permissions handler
5. Repeat TDD cycle for remaining 5 handlers
6. Create repository with DynamoDB operations
7. Create service layer
8. Ensure all tests pass
9. Create output.md with all code
10. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-23
