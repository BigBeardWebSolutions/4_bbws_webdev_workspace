# Stage T1: Tenant API Implementation

**Parent Plan**: [BBWS SDLC Main Plan](./main-plan.md)
**Stage**: T1 of T3 (Tenant Management Track)
**Status**: PENDING
**Last Updated**: 2026-01-01

---

## Objective

Implement the Tenant Management API (Lambda functions) for organization CRUD operations, including creating tenants, managing configuration, and setting up destination email for forms.

---

## Agent & Skill Assignment

| Role | Agent | Skill |
|------|-------|-------|
| **Primary** | Python_AWS_Developer_Agent | `AWS_Python_Dev.skill.md` |
| **Support** | Python_AWS_Developer_Agent | `Lambda_Management.skill.md` |

---

## Workers

| # | Worker | Task | Status | Output |
|---|--------|------|--------|--------|
| 1 | worker-1-tenant-models | Create Pydantic models for tenant | PENDING | `src/models/` |
| 2 | worker-2-tenant-repository | Implement DynamoDB repository | PENDING | `src/repositories/` |
| 3 | worker-3-tenant-service | Implement tenant service layer | PENDING | `src/services/` |
| 4 | worker-4-tenant-handlers | Create Lambda handlers | PENDING | `src/handlers/` |

---

## Worker Instructions

### Worker 1: Tenant Models

**Objective**: Define Pydantic models for tenant data

**Tenant Data Model**:
```python
# src/models/tenant.py
from pydantic import BaseModel, EmailStr, Field
from typing import Optional, List
from datetime import datetime
from enum import Enum

class TenantStatus(str, Enum):
    ACTIVE = "active"
    SUSPENDED = "suspended"
    PENDING = "pending"

class TenantConfig(BaseModel):
    """Tenant configuration settings."""
    destination_email: EmailStr = Field(..., description="Email for form submissions")
    max_sites: int = Field(default=5, ge=1, le=100)
    max_users: int = Field(default=10, ge=1, le=1000)
    features_enabled: List[str] = Field(default_factory=list)
    custom_domain: Optional[str] = None

class Tenant(BaseModel):
    """Tenant (Organization) model."""
    tenant_id: str = Field(..., description="Unique tenant identifier")
    organization_name: str = Field(..., min_length=2, max_length=100)
    admin_email: EmailStr = Field(..., description="Admin user email")
    status: TenantStatus = Field(default=TenantStatus.PENDING)
    config: TenantConfig
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

class CreateTenantRequest(BaseModel):
    """Request to create a new tenant."""
    organization_name: str = Field(..., min_length=2, max_length=100)
    admin_email: EmailStr
    destination_email: EmailStr
    max_sites: Optional[int] = 5
    max_users: Optional[int] = 10

class UpdateTenantRequest(BaseModel):
    """Request to update tenant."""
    organization_name: Optional[str] = None
    destination_email: Optional[EmailStr] = None
    max_sites: Optional[int] = None
    max_users: Optional[int] = None
    status: Optional[TenantStatus] = None
```

**Quality Criteria**:
- [ ] All models defined with validation
- [ ] Required fields documented
- [ ] Config model includes destination email
- [ ] Status enum defined

---

### Worker 2: Tenant Repository

**Objective**: Implement DynamoDB data access layer

**DynamoDB Schema (Single Table)**:
```
Table: tenants-{env}

Primary Key:
- PK: TENANT#{tenant_id}
- SK: METADATA

GSI1 (by status):
- GSI1PK: STATUS#{status}
- GSI1SK: TENANT#{tenant_id}

GSI2 (by admin email):
- GSI2PK: EMAIL#{admin_email}
- GSI2SK: TENANT#{tenant_id}
```

**Repository Implementation**:
```python
# src/repositories/tenant_repository.py
import boto3
from typing import Optional, List
from botocore.exceptions import ClientError
from src.models.tenant import Tenant, TenantStatus

class TenantRepository:
    """DynamoDB repository for tenant operations."""

    def __init__(self, table_name: str):
        self.dynamodb = boto3.resource('dynamodb')
        self.table = self.dynamodb.Table(table_name)

    def create(self, tenant: Tenant) -> Tenant:
        """Create a new tenant."""
        item = {
            'PK': f'TENANT#{tenant.tenant_id}',
            'SK': 'METADATA',
            'tenant_id': tenant.tenant_id,
            'organization_name': tenant.organization_name,
            'admin_email': tenant.admin_email,
            'status': tenant.status.value,
            'config': tenant.config.dict(),
            'created_at': tenant.created_at.isoformat(),
            'updated_at': tenant.updated_at.isoformat(),
            # GSI attributes
            'GSI1PK': f'STATUS#{tenant.status.value}',
            'GSI1SK': f'TENANT#{tenant.tenant_id}',
            'GSI2PK': f'EMAIL#{tenant.admin_email}',
            'GSI2SK': f'TENANT#{tenant.tenant_id}',
        }

        self.table.put_item(
            Item=item,
            ConditionExpression='attribute_not_exists(PK)'
        )
        return tenant

    def get_by_id(self, tenant_id: str) -> Optional[Tenant]:
        """Get tenant by ID."""
        response = self.table.get_item(
            Key={
                'PK': f'TENANT#{tenant_id}',
                'SK': 'METADATA'
            }
        )
        item = response.get('Item')
        return self._item_to_tenant(item) if item else None

    def list_all(self, status: Optional[TenantStatus] = None) -> List[Tenant]:
        """List all tenants, optionally filtered by status."""
        if status:
            response = self.table.query(
                IndexName='GSI1',
                KeyConditionExpression='GSI1PK = :pk',
                ExpressionAttributeValues={':pk': f'STATUS#{status.value}'}
            )
        else:
            response = self.table.scan(
                FilterExpression='SK = :sk',
                ExpressionAttributeValues={':sk': 'METADATA'}
            )
        return [self._item_to_tenant(item) for item in response.get('Items', [])]

    def update(self, tenant_id: str, updates: dict) -> Optional[Tenant]:
        """Update tenant attributes."""
        update_expr_parts = []
        expr_values = {}
        expr_names = {}

        for key, value in updates.items():
            if value is not None:
                update_expr_parts.append(f'#{key} = :{key}')
                expr_values[f':{key}'] = value
                expr_names[f'#{key}'] = key

        if not update_expr_parts:
            return self.get_by_id(tenant_id)

        update_expr_parts.append('#updated_at = :updated_at')
        expr_values[':updated_at'] = datetime.utcnow().isoformat()
        expr_names['#updated_at'] = 'updated_at'

        response = self.table.update_item(
            Key={'PK': f'TENANT#{tenant_id}', 'SK': 'METADATA'},
            UpdateExpression='SET ' + ', '.join(update_expr_parts),
            ExpressionAttributeNames=expr_names,
            ExpressionAttributeValues=expr_values,
            ReturnValues='ALL_NEW'
        )
        return self._item_to_tenant(response.get('Attributes'))

    def delete(self, tenant_id: str) -> bool:
        """Delete a tenant."""
        self.table.delete_item(
            Key={'PK': f'TENANT#{tenant_id}', 'SK': 'METADATA'}
        )
        return True

    def _item_to_tenant(self, item: dict) -> Tenant:
        """Convert DynamoDB item to Tenant model."""
        return Tenant(
            tenant_id=item['tenant_id'],
            organization_name=item['organization_name'],
            admin_email=item['admin_email'],
            status=TenantStatus(item['status']),
            config=TenantConfig(**item['config']),
            created_at=datetime.fromisoformat(item['created_at']),
            updated_at=datetime.fromisoformat(item['updated_at'])
        )
```

**Quality Criteria**:
- [ ] CRUD operations implemented
- [ ] GSI queries optimized
- [ ] Error handling complete
- [ ] Condition expressions for safety

---

### Worker 3: Tenant Service

**Objective**: Implement business logic layer

**Service Implementation**:
```python
# src/services/tenant_service.py
import uuid
from typing import Optional, List
from src.models.tenant import (
    Tenant, TenantConfig, TenantStatus,
    CreateTenantRequest, UpdateTenantRequest
)
from src.repositories.tenant_repository import TenantRepository
from src.exceptions import TenantNotFoundError, TenantExistsError

class TenantService:
    """Service layer for tenant operations."""

    def __init__(self, repository: TenantRepository):
        self.repository = repository

    def create_tenant(self, request: CreateTenantRequest) -> Tenant:
        """Create a new tenant organization."""
        tenant_id = f"TEN-{uuid.uuid4().hex[:8].upper()}"

        config = TenantConfig(
            destination_email=request.destination_email,
            max_sites=request.max_sites or 5,
            max_users=request.max_users or 10
        )

        tenant = Tenant(
            tenant_id=tenant_id,
            organization_name=request.organization_name,
            admin_email=request.admin_email,
            status=TenantStatus.PENDING,
            config=config
        )

        return self.repository.create(tenant)

    def get_tenant(self, tenant_id: str) -> Tenant:
        """Get tenant by ID."""
        tenant = self.repository.get_by_id(tenant_id)
        if not tenant:
            raise TenantNotFoundError(f"Tenant {tenant_id} not found")
        return tenant

    def list_tenants(self, status: Optional[TenantStatus] = None) -> List[Tenant]:
        """List all tenants."""
        return self.repository.list_all(status)

    def update_tenant(self, tenant_id: str, request: UpdateTenantRequest) -> Tenant:
        """Update tenant details."""
        existing = self.get_tenant(tenant_id)

        updates = {}
        if request.organization_name:
            updates['organization_name'] = request.organization_name
        if request.destination_email:
            updates['config'] = {**existing.config.dict(), 'destination_email': request.destination_email}
        if request.status:
            updates['status'] = request.status.value

        return self.repository.update(tenant_id, updates)

    def delete_tenant(self, tenant_id: str) -> None:
        """Delete a tenant."""
        self.get_tenant(tenant_id)  # Verify exists
        self.repository.delete(tenant_id)

    def activate_tenant(self, tenant_id: str) -> Tenant:
        """Activate a pending tenant."""
        return self.repository.update(tenant_id, {'status': TenantStatus.ACTIVE.value})

    def suspend_tenant(self, tenant_id: str) -> Tenant:
        """Suspend a tenant."""
        return self.repository.update(tenant_id, {'status': TenantStatus.SUSPENDED.value})
```

**Quality Criteria**:
- [ ] All CRUD operations implemented
- [ ] Business logic encapsulated
- [ ] Validation in place
- [ ] Error handling complete

---

### Worker 4: Lambda Handlers

**Objective**: Create API Gateway Lambda handlers

**Handlers Implementation**:
```python
# src/handlers/tenant_handlers.py
import json
from src.services.tenant_service import TenantService
from src.repositories.tenant_repository import TenantRepository
from src.models.tenant import CreateTenantRequest, UpdateTenantRequest
from src.utils.response_builder import success_response, error_response

def get_service():
    table_name = os.environ.get('TENANT_TABLE_NAME', 'tenants-dev')
    repo = TenantRepository(table_name)
    return TenantService(repo)

def list_tenants(event, context):
    """GET /v1.0/tenants"""
    service = get_service()
    tenants = service.list_tenants()
    return success_response({
        'tenants': [t.dict() for t in tenants],
        'count': len(tenants)
    })

def get_tenant(event, context):
    """GET /v1.0/tenants/{tenant_id}"""
    tenant_id = event['pathParameters']['tenant_id']
    service = get_service()
    tenant = service.get_tenant(tenant_id)
    return success_response(tenant.dict())

def create_tenant(event, context):
    """POST /v1.0/tenants"""
    body = json.loads(event['body'])
    request = CreateTenantRequest(**body)
    service = get_service()
    tenant = service.create_tenant(request)
    return success_response(tenant.dict(), status_code=201)

def update_tenant(event, context):
    """PUT /v1.0/tenants/{tenant_id}"""
    tenant_id = event['pathParameters']['tenant_id']
    body = json.loads(event['body'])
    request = UpdateTenantRequest(**body)
    service = get_service()
    tenant = service.update_tenant(tenant_id, request)
    return success_response(tenant.dict())

def delete_tenant(event, context):
    """DELETE /v1.0/tenants/{tenant_id}"""
    tenant_id = event['pathParameters']['tenant_id']
    service = get_service()
    service.delete_tenant(tenant_id)
    return success_response(None, status_code=204)
```

**API Endpoints**:
| Method | Path | Handler | Description |
|--------|------|---------|-------------|
| GET | `/v1.0/tenants` | `list_tenants` | List all tenants |
| GET | `/v1.0/tenants/{id}` | `get_tenant` | Get tenant by ID |
| POST | `/v1.0/tenants` | `create_tenant` | Create new tenant |
| PUT | `/v1.0/tenants/{id}` | `update_tenant` | Update tenant |
| DELETE | `/v1.0/tenants/{id}` | `delete_tenant` | Delete tenant |

**Quality Criteria**:
- [ ] All CRUD endpoints implemented
- [ ] Input validation with Pydantic
- [ ] Proper HTTP status codes
- [ ] Error responses standardized

---

## Stage Outputs

| Output | Description | Location |
|--------|-------------|----------|
| Models | Pydantic tenant models | `src/models/` |
| Repository | DynamoDB data access | `src/repositories/` |
| Service | Business logic layer | `src/services/` |
| Handlers | Lambda functions | `src/handlers/` |

---

## Success Criteria

- [ ] All 4 workers completed
- [ ] CRUD operations working
- [ ] DynamoDB schema implemented
- [ ] Test coverage >= 80%

---

## Dependencies

**Depends On**: Stage 3 (LLD) - Data model design
**Blocks**: Stage T2 (User Hierarchy)

---

## Estimated Duration

| Activity | Agentic | Manual |
|----------|---------|--------|
| Models | 15 min | 1 hour |
| Repository | 30 min | 3 hours |
| Service | 20 min | 2 hours |
| Handlers | 20 min | 2 hours |
| **Total** | **1.5 hours** | **8 hours** |

---

**Navigation**: [Main Plan](./main-plan.md) | [Stage T2: User Hierarchy ->](./stage-t2-user-hierarchy.md)
