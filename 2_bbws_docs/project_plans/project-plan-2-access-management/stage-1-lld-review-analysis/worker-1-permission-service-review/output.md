# Permission Service LLD Review Output

**Worker ID**: worker-1-permission-service-review
**Stage**: Stage 1 - LLD Review & Analysis
**Project**: project-plan-2-access-management
**LLD Source**: `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/2.8.1_LLD_Permission_Service.md`
**Review Date**: 2026-01-23
**Status**: COMPLETE

---

## 1. Lambda Function Checklist

| # | Function Name | Handler File | Method | Endpoint | Priority | Description |
|---|--------------|--------------|--------|----------|----------|-------------|
| 1 | list_permissions | `list_permissions.py` | GET | `/v1/platform/permissions` | HIGH | List all platform permissions with pagination |
| 2 | get_permission | `get_permission.py` | GET | `/v1/platform/permissions/{permId}` | HIGH | Get single permission details by ID |
| 3 | create_permission_set | `create_permission_set.py` | POST | `/v1/organisations/{orgId}/permission-sets` | HIGH | Create new permission set for organisation |
| 4 | list_permission_sets | `list_permission_sets.py` | GET | `/v1/organisations/{orgId}/permission-sets` | HIGH | List permission sets for organisation |
| 5 | get_permission_set | `get_permission_set.py` | GET | `/v1/organisations/{orgId}/permission-sets/{setId}` | MEDIUM | Get permission set details |
| 6 | update_permission_set | `update_permission_set.py` | PUT | `/v1/organisations/{orgId}/permission-sets/{setId}` | MEDIUM | Update permission set (including soft delete) |
| 7 | delete_permission_set | `delete_permission_set.py` | PUT | `/v1/organisations/{orgId}/permission-sets/{setId}` | MEDIUM | Soft delete (active=false) |

**Note**: The LLD specifies 7 Lambda functions (not 6 as originally stated in instructions). The delete operation uses PUT with `active=false` for soft delete pattern.

### Lambda Configuration

| Attribute | Value |
|-----------|-------|
| Runtime | Python 3.12 |
| Memory | 256MB |
| Timeout | 30s |
| Architecture | arm64 |
| Layer | aws-lambda-powertools |
| Repository | `2_bbws_access_permission_lambda` |

---

## 2. API Contract Summary

### 2.1 GET /v1/platform/permissions

**Purpose**: List all platform permissions with pagination and optional category filter

**Query Parameters**:
| Parameter | Type | Required | Default | Max | Description |
|-----------|------|----------|---------|-----|-------------|
| pageSize | integer | No | 50 | 100 | Items per page |
| startAt | string | No | - | - | Pagination cursor |
| category | string | No | - | - | Filter by category (SITE, TEAM, ORGANISATION, INVITATION, ROLE, AUDIT) |

**Required Permission**: `permission:read`

**Response 200**:
```json
{
  "items": [
    {
      "id": "site:create",
      "name": "Create Site",
      "description": "Allows creating new WordPress sites",
      "resource": "site",
      "action": "create",
      "category": "SITE",
      "active": true,
      "dateCreated": "2026-01-01T00:00:00Z",
      "_links": {
        "self": { "href": "/v1/platform/permissions/site:create" }
      }
    }
  ],
  "startAt": "site:read",
  "moreAvailable": true,
  "count": 2,
  "_links": {
    "self": { "href": "/v1/platform/permissions?pageSize=50" },
    "next": { "href": "/v1/platform/permissions?pageSize=50&startAt=site:read" }
  }
}
```

**Error Responses**:
| Status | Error Code | Description |
|--------|------------|-------------|
| 400 | INVALID_PAGE_SIZE | pageSize exceeds maximum of 100 |
| 401 | UNAUTHORIZED | Missing or invalid JWT |
| 500 | INTERNAL_ERROR | Internal server error |

---

### 2.2 GET /v1/platform/permissions/{permId}

**Purpose**: Get permission details by ID

**Path Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| permId | string | Yes | Permission ID (format: `resource:action`) |

**Required Permission**: `permission:read`

**Response 200**:
```json
{
  "id": "site:create",
  "name": "Create Site",
  "description": "Allows creating new WordPress sites",
  "resource": "site",
  "action": "create",
  "category": "SITE",
  "active": true,
  "dateCreated": "2026-01-01T00:00:00Z",
  "_links": {
    "self": { "href": "/v1/platform/permissions/site:create" }
  }
}
```

**Error Responses**:
| Status | Error Code | Description |
|--------|------------|-------------|
| 404 | PERMISSION_NOT_FOUND | Permission ID does not exist |
| 500 | INTERNAL_ERROR | Internal server error |

---

### 2.3 POST /v1/organisations/{orgId}/permission-sets

**Purpose**: Create a new permission set for an organisation

**Path Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| orgId | string | Yes | Organisation UUID |

**Request Body**:
```json
{
  "name": "Site Manager",
  "description": "Permissions for managing WordPress sites",
  "permissions": ["site:create", "site:read", "site:update", "site:publish"],
  "scope": "ORGANISATION"
}
```

**Request Body Schema**:
| Field | Type | Required | Min | Max | Description |
|-------|------|----------|-----|-----|-------------|
| name | string | Yes | 3 | 100 | Permission set name (unique per org) |
| description | string | Yes | 10 | 500 | Permission set description |
| permissions | array[string] | Yes | 1 | 50 | List of permission IDs |
| scope | string | No | - | - | PLATFORM, ORGANISATION (default), TEAM |

**Required Permission**: `permission:create`

**Response 201**:
```json
{
  "id": "permset-550e8400-e29b-41d4-a716-446655440001",
  "name": "Site Manager",
  "description": "Permissions for managing WordPress sites",
  "organisationId": "org-550e8400-e29b-41d4-a716-446655440000",
  "permissions": ["site:create", "site:read", "site:update", "site:publish"],
  "scope": "ORGANISATION",
  "isSystem": false,
  "active": true,
  "dateCreated": "2026-01-23T10:30:00Z",
  "dateLastUpdated": "2026-01-23T10:30:00Z",
  "createdBy": "admin@example.com",
  "lastUpdatedBy": "admin@example.com",
  "_links": {
    "self": { "href": "/v1/organisations/org-550e8400/permission-sets/permset-550e8400" },
    "organisation": { "href": "/v1/organisations/org-550e8400" },
    "update": { "href": "/v1/organisations/org-550e8400/permission-sets/permset-550e8400", "method": "PUT" },
    "delete": { "href": "/v1/organisations/org-550e8400/permission-sets/permset-550e8400", "method": "PUT", "body": { "active": false } }
  }
}
```

**Error Responses**:
| Status | Error Code | Description |
|--------|------------|-------------|
| 400 | INVALID_REQUEST | Validation failed (name too short, invalid permissions) |
| 400 | INVALID_PERMISSIONS | One or more permission IDs do not exist |
| 403 | FORBIDDEN | User's org does not match path orgId |
| 409 | DUPLICATE_NAME | Permission set name already exists for this org |
| 500 | INTERNAL_ERROR | Internal server error |

---

### 2.4 GET /v1/organisations/{orgId}/permission-sets

**Purpose**: List permission sets for an organisation

**Path Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| orgId | string | Yes | Organisation UUID |

**Query Parameters**:
| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| pageSize | integer | No | 50 | Items per page |
| startAt | string | No | - | Pagination cursor |
| includeInactive | boolean | No | false | Include soft-deleted sets |

**Required Permission**: Authenticated user belonging to organisation

**Response 200**:
```json
{
  "items": [
    {
      "id": "permset-550e8400",
      "name": "Site Manager",
      "description": "...",
      "permissions": ["site:create", "site:read"],
      "scope": "ORGANISATION",
      "isSystem": false,
      "active": true,
      "dateCreated": "2026-01-23T10:30:00Z",
      "dateLastUpdated": "2026-01-23T10:30:00Z",
      "_links": { ... }
    }
  ],
  "moreAvailable": false,
  "count": 1,
  "_links": {
    "self": { "href": "/v1/organisations/org-550e8400/permission-sets?pageSize=50" },
    "organisation": { "href": "/v1/organisations/org-550e8400" },
    "create": { "href": "/v1/organisations/org-550e8400/permission-sets", "method": "POST" }
  }
}
```

**Error Responses**:
| Status | Error Code | Description |
|--------|------------|-------------|
| 403 | FORBIDDEN | User does not belong to organisation |
| 500 | INTERNAL_ERROR | Internal server error |

---

### 2.5 GET /v1/organisations/{orgId}/permission-sets/{setId}

**Purpose**: Get permission set details with optional permission expansion

**Path Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| orgId | string | Yes | Organisation UUID |
| setId | string | Yes | Permission Set UUID |

**Query Parameters**:
| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| expandPermissions | boolean | No | false | Include full permission details |

**Required Permission**: Authenticated user belonging to organisation

**Response 200**: Same as POST response schema

**Error Responses**:
| Status | Error Code | Description |
|--------|------------|-------------|
| 403 | FORBIDDEN | User does not belong to organisation |
| 404 | PERMISSION_SET_NOT_FOUND | Permission set does not exist |
| 500 | INTERNAL_ERROR | Internal server error |

---

### 2.6 PUT /v1/organisations/{orgId}/permission-sets/{setId}

**Purpose**: Update permission set (partial update supported)

**Path Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| orgId | string | Yes | Organisation UUID |
| setId | string | Yes | Permission Set UUID |

**Request Body** (all fields optional):
```json
{
  "name": "Updated Site Manager",
  "description": "Updated description",
  "permissions": ["site:create", "site:read", "site:update"],
  "scope": "TEAM",
  "active": true
}
```

**Required Permission**: `permission:update`

**Response 200**: Updated permission set (same schema as POST response)

**Error Responses**:
| Status | Error Code | Description |
|--------|------------|-------------|
| 400 | INVALID_REQUEST | Validation failed |
| 400 | INVALID_PERMISSIONS | One or more permission IDs do not exist |
| 403 | FORBIDDEN | User does not belong to org OR attempting to modify system set |
| 404 | PERMISSION_SET_NOT_FOUND | Permission set does not exist |
| 500 | INTERNAL_ERROR | Internal server error |

---

## 3. DynamoDB Schema

### 3.1 Table Configuration

**Table Name**: `bbws-aipagebuilder-{env}-ddb-access-management`

| Configuration | Value |
|---------------|-------|
| Billing Mode | On-Demand (PAY_PER_REQUEST) |
| Encryption | KMS (AWS managed) |
| Point-in-Time Recovery | Enabled |
| Cross-Region Replication | PROD only (af-south-1 to eu-west-1) |

### 3.2 Permission Entity

| Attribute | Type | Key | Description |
|-----------|------|-----|-------------|
| PK | String | Partition Key | `PERM#{permissionId}` |
| SK | String | Sort Key | `METADATA` |
| permissionId | String | - | Format: `resource:action` (e.g., `site:create`) |
| name | String | - | Human-readable name |
| description | String | - | Permission description |
| resource | String | - | Resource type (site, team, org, invitation, role, audit) |
| action | String | - | Action type (create, read, update, delete, publish, backup, restore) |
| category | String | - | Grouping (SITE, TEAM, ORGANISATION, INVITATION, ROLE, AUDIT) |
| isSystem | Boolean | - | System-defined (cannot be deleted), default: true |
| active | Boolean | - | Active status, default: true |
| dateCreated | String | - | ISO 8601 timestamp |
| GSI1PK | String | GSI1 PK | `CATEGORY#{category}` |
| GSI1SK | String | GSI1 SK | `PERM#{permissionId}` |

### 3.3 Permission Set Entity

| Attribute | Type | Key | Description |
|-----------|------|-----|-------------|
| PK | String | Partition Key | `ORG#{organisationId}` |
| SK | String | Sort Key | `PERMSET#{permissionSetId}` |
| permissionSetId | String | - | UUID |
| name | String | - | Set name (unique per org) |
| description | String | - | Set description |
| organisationId | String | - | Organisation UUID (null for platform sets) |
| permissions | List[String] | - | List of permission IDs |
| scope | String | - | `PLATFORM`, `ORGANISATION`, `TEAM` |
| isSystem | Boolean | - | System set (cannot be deleted), default: false |
| active | Boolean | - | Active status, default: true |
| dateCreated | String | - | ISO 8601 timestamp |
| dateLastUpdated | String | - | ISO 8601 timestamp |
| createdBy | String | - | Creator email |
| lastUpdatedBy | String | - | Last updater email |
| GSI1PK | String | GSI1 PK | `ORG#{organisationId}` |
| GSI1SK | String | GSI1 SK | `PERMSET#{dateCreated}` |
| GSI2PK | String | GSI2 PK | `PERMSET#ACTIVE#{active}` |
| GSI2SK | String | GSI2 SK | `ORG#{organisationId}#{dateCreated}` |

### 3.4 Platform Permission Set Entity

| Attribute | Type | Key | Description |
|-----------|------|-----|-------------|
| PK | String | Partition Key | `PLATFORM` |
| SK | String | Sort Key | `PERMSET#{permissionSetId}` |
| permissionSetId | String | - | UUID |
| name | String | - | Set name |
| description | String | - | Set description |
| organisationId | String | - | null (platform-wide) |
| permissions | List[String] | - | List of permission IDs |
| scope | String | - | `PLATFORM` |
| isSystem | Boolean | - | true (system-defined) |
| active | Boolean | - | Active status |
| dateCreated | String | - | ISO 8601 timestamp |

### 3.5 GSI Definitions

| GSI Name | Partition Key | Sort Key | Purpose |
|----------|---------------|----------|---------|
| GSI1 | GSI1PK | GSI1SK | Query permissions by category; Query permission sets by org sorted by date |
| GSI2 | GSI2PK | GSI2SK | Query permission sets by active status across organisations |

### 3.6 Access Patterns

| Access Pattern | Key Condition | Index |
|----------------|---------------|-------|
| Get permission by ID | PK = `PERM#{permId}`, SK = `METADATA` | Table |
| List all permissions | PK begins_with `PERM#` | Table (scan) |
| List permissions by category | GSI1PK = `CATEGORY#{category}` | GSI1 |
| Get permission set by ID | PK = `ORG#{orgId}`, SK = `PERMSET#{setId}` | Table |
| List permission sets by org | PK = `ORG#{orgId}`, SK begins_with `PERMSET#` | Table |
| List permission sets sorted by date | GSI1PK = `ORG#{orgId}` | GSI1 |
| List active permission sets | GSI2PK = `PERMSET#ACTIVE#true` | GSI2 |
| Get platform permission sets | PK = `PLATFORM`, SK begins_with `PERMSET#` | Table |

---

## 4. Pydantic Models Required

### 4.1 Enum Models

```python
class PermissionCategory(str, Enum):
    """Permission category grouping."""
    SITE = "SITE"
    TEAM = "TEAM"
    ORGANISATION = "ORGANISATION"
    INVITATION = "INVITATION"
    ROLE = "ROLE"
    AUDIT = "AUDIT"

class PermissionScope(str, Enum):
    """Permission set scope level."""
    PLATFORM = "PLATFORM"
    ORGANISATION = "ORGANISATION"
    TEAM = "TEAM"
```

### 4.2 Entity Models

| Model | Purpose | Key Fields |
|-------|---------|------------|
| `Permission` | Platform-defined permission entity | permissionId, name, description, resource, action, category, isSystem, active, dateCreated |
| `PermissionSet` | Bundled permission set entity | permissionSetId, name, description, organisationId, permissions, scope, isSystem, active, dateCreated, dateLastUpdated, createdBy, lastUpdatedBy |

### 4.3 Request Models

| Model | Purpose | Validation Rules |
|-------|---------|-----------------|
| `CreatePermissionSetRequest` | POST request body validation | name (3-100 chars), description (10-500 chars), permissions (1-50 items, format `resource:action`), scope (optional) |
| `UpdatePermissionSetRequest` | PUT request body validation | All fields optional, same validation when present |

### 4.4 Response Models

| Model | Purpose | Includes |
|-------|---------|----------|
| `PermissionResponse` | Single permission response | All permission fields + `_links` |
| `PermissionSetResponse` | Single permission set response | All set fields + optional `permissionDetails` + `_links` |
| `PaginatedResponse` | List response wrapper | items, startAt, moreAvailable, count, `_links` |

### 4.5 HATEOAS Models

| Model | Purpose |
|-------|---------|
| `HATEOASLink` | Link representation with href, method, body |

### 4.6 Exception Models

| Exception | Purpose | Fields |
|-----------|---------|--------|
| `PermissionNotFoundException` | Permission not found | permissionId, message |
| `PermissionSetNotFoundException` | Permission set not found | setId, message |
| `InvalidPermissionsException` | Invalid permission IDs | invalidPermissions, message |
| `DuplicatePermissionSetException` | Duplicate name | name, message |
| `ForbiddenException` | Access denied | message |

---

## 5. Integration Points

| Integration | Service | Direction | Purpose | Method |
|-------------|---------|-----------|---------|--------|
| Cognito | Authentication | Inbound | JWT validation via Lambda Authorizer | JWT Bearer token |
| Audit Service | Audit | Outbound | Log permission set create/update/delete | DynamoDB write to audit table |
| Role Service | Role | Outbound | Permission sets assigned to roles | Permission set IDs referenced |
| API Gateway | Gateway | Inbound | HTTP request routing | REST API |
| CloudWatch | Monitoring | Outbound | Metrics and logs | Lambda Powertools |
| SNS | Notifications | Outbound | Org admin notifications | Event publishing |

### Integration Details

#### Cognito Integration
- Lambda Authorizer validates JWT tokens
- Auth context extracted: userId, email, organisationId, teamIds, permissions
- Organisation scoping enforced from auth context

#### Audit Service Integration
- Events logged: `permission_set_created`, `permission_set_updated`, `permission_set_deleted`
- Audit payload: setId, orgId, changes (for updates), actor email
- Target: DynamoDB audit table (same access-management table)

#### Role Service Integration
- Roles reference permission set IDs
- Permission sets bundled for role assignment
- Role Service validates permission set exists before assignment

---

## 6. Risk Assessment

| # | Risk | Impact | Likelihood | Mitigation |
|---|------|--------|------------|------------|
| 1 | Invalid permissions in permission set | MEDIUM | LOW | Validate all permissions exist in DynamoDB before saving; Return 400 with list of invalid IDs |
| 2 | Duplicate permission set names | LOW | MEDIUM | Unique constraint via GSI query on org + name before create |
| 3 | System permission set modification | HIGH | LOW | Check `isSystem` flag before any update/delete; Return 403 Forbidden |
| 4 | Cross-organisation access | HIGH | LOW | Validate `orgId` from path matches `organisationId` from auth context |
| 5 | Permission set over-allocation | MEDIUM | MEDIUM | Enforce max 50 permissions per set via Pydantic validation |
| 6 | Orphaned permission sets | LOW | LOW | Soft delete pattern preserves data; Active flag filtering |
| 7 | Platform permission modification | HIGH | LOW | Platform permissions are system-defined (`isSystem=true`), read-only |
| 8 | Lambda cold start latency | LOW | HIGH | arm64 architecture, 256MB memory, aws-lambda-powertools layer |
| 9 | DynamoDB throttling | MEDIUM | LOW | On-demand capacity mode; Exponential backoff retry |
| 10 | Circular permission dependencies | N/A | N/A | Not applicable - permissions are flat, no hierarchy |

---

## 7. Implementation Notes

### 7.1 Design Patterns
- **Soft Delete**: Use `active=false` instead of physical deletion
- **HATEOAS**: All responses include `_links` section for navigation
- **Single-Table Design**: Permissions and Permission Sets in same DynamoDB table
- **Organisation Scoping**: All permission sets scoped to organisation via PK

### 7.2 Validation Rules
- Permission ID format: `resource:action` (must contain colon)
- Name: 3-100 characters
- Description: 10-500 characters
- Permissions list: 1-50 items maximum
- All timestamps: ISO 8601 format

### 7.3 Security Controls
- JWT validation via Cognito Lambda Authorizer
- Organisation isolation via auth context validation
- System entities protected from modification
- All data encrypted at rest (DynamoDB KMS)
- TLS 1.3 for data in transit

### 7.4 Platform Permissions (Seed Data)
25 platform permissions defined across 6 categories:
- **SITE** (7): create, read, update, delete, publish, backup, restore
- **TEAM** (5): read, update, member:add, member:remove, member:read
- **ORGANISATION** (4): read, update, hierarchy:manage, user:manage
- **INVITATION** (4): create, read, revoke, resend
- **ROLE** (3): create, update, assign
- **AUDIT** (2): read, export

### 7.5 Default Permission Sets (Seed Data)
6 system permission sets:
1. Platform Admin - Full platform access
2. Org Admin - Full organisation access
3. Site Manager - Site management
4. Team Lead - Team management
5. Site Operator - Site operations
6. Viewer - Read-only access

### 7.6 NFR Targets
| Metric | Target |
|--------|--------|
| List permissions latency (p95) | < 200ms |
| Get permission latency (p95) | < 100ms |
| Create permission set latency (p95) | < 500ms |
| List permission sets latency (p95) | < 200ms |
| Update permission set latency (p95) | < 500ms |
| Lambda cold start | < 2s |
| Error rate | < 0.1% |

---

## 8. Project Structure

```
2_bbws_access_permission_lambda/
├── src/
│   ├── handlers/
│   │   ├── __init__.py
│   │   ├── list_permissions.py
│   │   ├── get_permission.py
│   │   ├── create_permission_set.py
│   │   ├── list_permission_sets.py
│   │   ├── get_permission_set.py
│   │   ├── update_permission_set.py
│   │   └── delete_permission_set.py
│   ├── services/
│   │   ├── __init__.py
│   │   ├── permission_service.py
│   │   └── permission_set_service.py
│   ├── repositories/
│   │   ├── __init__.py
│   │   ├── permission_repository.py
│   │   └── permission_set_repository.py
│   ├── models/
│   │   ├── __init__.py
│   │   ├── permission.py
│   │   ├── permission_set.py
│   │   └── requests.py
│   ├── exceptions/
│   │   ├── __init__.py
│   │   └── permission_exceptions.py
│   └── utils/
│       ├── __init__.py
│       ├── response_builder.py
│       ├── validators.py
│       └── hateoas.py
├── tests/
│   ├── unit/
│   │   ├── test_handlers/
│   │   ├── test_services/
│   │   └── test_repositories/
│   └── integration/
│       └── test_api.py
├── terraform/
│   ├── main.tf
│   ├── api_gateway.tf
│   ├── lambda.tf
│   ├── iam.tf
│   ├── variables.tf
│   └── outputs.tf
├── openapi/
│   └── permission-service-api.yaml
├── requirements.txt
├── pytest.ini
└── README.md
```

---

## 9. Success Criteria Checklist

- [x] All 7 Lambda functions documented (LLD specifies 7, not 6)
- [x] All API endpoints fully specified with request/response schemas
- [x] DynamoDB schema extracted with all entities, keys, and GSIs
- [x] All Pydantic models listed with validation rules
- [x] Integration points identified with direction and purpose
- [x] Risks assessed with impact, likelihood, and mitigations
- [x] Output follows expected format

---

**Review Complete**
**Worker**: worker-1-permission-service-review
**Status**: COMPLETE
**Date**: 2026-01-23
