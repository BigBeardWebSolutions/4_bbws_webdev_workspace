# Tenant API Guide

**Version**: 1.0
**Last Updated**: 2026-01-25
**LLD Reference**: [2.5_LLD_Tenant_Management](../../LLDs/2.5_LLD_Tenant_Management.md)

---

## Overview

The Tenant API manages logical tenant entities in the BBWS platform. A tenant represents a customer organization with its hierarchy (divisions, groups, teams), users, and metadata.

### Key Concepts

| Concept | Description |
|---------|-------------|
| **Tenant** | A customer organization with dedicated resources |
| **Hierarchy** | Division > Group > Team organizational structure |
| **User Assignment** | Users belong to tenants with specific roles |
| **Lifecycle** | Tenants can be Active, Suspended, Parked, or Deprovisioned |

---

## Base URL

```
https://api-{env}.bigbeardweb.solutions/v1.0/tenants
```

---

## Authentication

All endpoints require a valid JWT token in the Authorization header:

```
Authorization: Bearer {access_token}
```

See [Authentication Guide](./authentication.md) for details.

---

## Tenant Lifecycle States

```
PENDING ────────────────> ACTIVE <────────────────> SUSPENDED
    │                       │                           │
    │                       │                           │
    │                       └────────────> PARKED <─────┘
    │                                         │
    │                                         │
    └─────────────────────> FAILED            │
                              │               │
                              ▼               │
                     DEPROVISIONED <──────────┘
```

| State | Description |
|-------|-------------|
| PENDING | Newly created, awaiting activation |
| ACTIVE | Fully operational |
| SUSPENDED | Temporarily disabled (data retained) |
| PARKED | Resources released, data retained (cost savings) |
| DEPROVISIONED | Soft-deleted, pending cleanup |
| FAILED | Provisioning or operation failed |

---

## API Endpoints

### Tenant CRUD Operations

| Method | Path | Description | Roles |
|--------|------|-------------|-------|
| POST | `/v1.0/tenants` | Create tenant | Operator, Admin |
| GET | `/v1.0/tenants` | List tenants | All |
| GET | `/v1.0/tenants/{tenantId}` | Get tenant | All |
| PUT | `/v1.0/tenants/{tenantId}` | Update tenant | Admin |
| DELETE | `/v1.0/tenants/{tenantId}` | Soft delete | Admin |

### Lifecycle Operations

| Method | Path | Description | Roles |
|--------|------|-------------|-------|
| POST | `/v1.0/tenants/{tenantId}/lifecycle/suspend` | Suspend tenant | Admin |
| POST | `/v1.0/tenants/{tenantId}/lifecycle/resume` | Resume tenant | Admin |
| POST | `/v1.0/tenants/{tenantId}/lifecycle/park` | Park tenant | Admin |
| POST | `/v1.0/tenants/{tenantId}/lifecycle/unpark` | Unpark tenant | Admin |

### User Operations

| Method | Path | Description | Roles |
|--------|------|-------------|-------|
| GET | `/v1.0/tenants/{tenantId}/users` | List users | Admin, Operator |
| POST | `/v1.0/tenants/{tenantId}/users` | Assign user | Admin |
| GET | `/v1.0/tenants/{tenantId}/users/{userId}` | Get user | Admin, Operator |
| DELETE | `/v1.0/tenants/{tenantId}/users/{userId}` | Remove user | Admin |

---

## Endpoint Details

### Create Tenant

Creates a new tenant organization.

**Request:**

```http
POST /v1.0/tenants
Authorization: Bearer {token}
Content-Type: application/json

{
  "organizationName": "Acme Corporation",
  "contactEmail": "admin@acme.com",
  "environment": "dev",
  "division": "Technology",
  "metadata": {
    "industry": "Software",
    "size": "Enterprise"
  }
}
```

**Request Fields:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| organizationName | string | Yes | Organization name (2-100 chars) |
| contactEmail | string | Yes | Admin contact email |
| environment | string | Yes | `dev`, `sit`, or `prod` |
| division | string | No | Top-level division name |
| group | string | No | Group name (requires division) |
| team | string | No | Team name (requires group) |
| metadata | object | No | Custom metadata key-value pairs |

**Response (201 Created):**

```json
{
  "tenantId": "tenant-550e8400-e29b-41d4-a716-446655440000",
  "organizationName": "Acme Corporation",
  "contactEmail": "admin@acme.com",
  "environment": "dev",
  "status": "PENDING",
  "division": "Technology",
  "createdAt": "2026-01-25T10:30:00Z",
  "createdBy": "operator@bbws.io",
  "version": 1,
  "_links": {
    "self": { "href": "/v1.0/tenants/tenant-550e8400-e29b-41d4-a716-446655440000" },
    "users": { "href": "/v1.0/tenants/tenant-550e8400-e29b-41d4-a716-446655440000/users" },
    "sites": { "href": "/v1.0/tenants/tenant-550e8400-e29b-41d4-a716-446655440000/sites" },
    "lifecycle": {
      "suspend": { "href": "/v1.0/tenants/tenant-550e8400-e29b-41d4-a716-446655440000/lifecycle/suspend" },
      "park": { "href": "/v1.0/tenants/tenant-550e8400-e29b-41d4-a716-446655440000/lifecycle/park" }
    }
  }
}
```

---

### List Tenants

Returns a paginated list of tenants.

**Request:**

```http
GET /v1.0/tenants?status=ACTIVE&environment=dev&pageSize=20&startAt=token123
Authorization: Bearer {token}
```

**Query Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| status | string | - | Filter by status |
| environment | string | - | Filter by environment |
| pageSize | integer | 20 | Items per page (1-100) |
| startAt | string | - | Pagination token |

**Response (200 OK):**

```json
{
  "items": [
    {
      "tenantId": "tenant-550e8400-e29b-41d4-a716-446655440000",
      "organizationName": "Acme Corporation",
      "status": "ACTIVE",
      "environment": "dev",
      "createdAt": "2026-01-25T10:30:00Z",
      "_links": {
        "self": { "href": "/v1.0/tenants/tenant-550e8400-e29b-41d4-a716-446655440000" }
      }
    }
  ],
  "count": 1,
  "moreAvailable": false,
  "nextToken": null,
  "_links": {
    "self": { "href": "/v1.0/tenants?status=ACTIVE&pageSize=20" }
  }
}
```

---

### Get Tenant

Returns detailed tenant information.

**Request:**

```http
GET /v1.0/tenants/tenant-550e8400-e29b-41d4-a716-446655440000
Authorization: Bearer {token}
```

**Response (200 OK):**

```json
{
  "tenantId": "tenant-550e8400-e29b-41d4-a716-446655440000",
  "organizationName": "Acme Corporation",
  "contactEmail": "admin@acme.com",
  "environment": "dev",
  "status": "ACTIVE",
  "division": "Technology",
  "group": "Engineering",
  "team": "Platform",
  "createdAt": "2026-01-25T10:30:00Z",
  "createdBy": "operator@bbws.io",
  "updatedAt": "2026-01-25T14:30:00Z",
  "updatedBy": "admin@acme.com",
  "metadata": {
    "industry": "Software",
    "size": "Enterprise",
    "tier": "PREMIUM"
  },
  "version": 3,
  "_links": {
    "self": { "href": "/v1.0/tenants/tenant-550e8400-e29b-41d4-a716-446655440000" },
    "users": { "href": "/v1.0/tenants/tenant-550e8400-e29b-41d4-a716-446655440000/users" },
    "sites": { "href": "/v1.0/tenants/tenant-550e8400-e29b-41d4-a716-446655440000/sites" },
    "instances": { "href": "/v1.0/tenants/tenant-550e8400-e29b-41d4-a716-446655440000/instances" },
    "lifecycle": {
      "suspend": { "href": "/v1.0/tenants/tenant-550e8400-e29b-41d4-a716-446655440000/lifecycle/suspend" },
      "park": { "href": "/v1.0/tenants/tenant-550e8400-e29b-41d4-a716-446655440000/lifecycle/park" }
    }
  }
}
```

---

### Update Tenant

Updates tenant information.

**Request:**

```http
PUT /v1.0/tenants/tenant-550e8400-e29b-41d4-a716-446655440000
Authorization: Bearer {token}
Content-Type: application/json

{
  "organizationName": "Acme Corp International",
  "contactEmail": "admin-new@acme.com",
  "metadata": {
    "tier": "ENTERPRISE"
  }
}
```

**Response (200 OK):**

```json
{
  "tenantId": "tenant-550e8400-e29b-41d4-a716-446655440000",
  "organizationName": "Acme Corp International",
  "contactEmail": "admin-new@acme.com",
  "status": "ACTIVE",
  "updatedAt": "2026-01-25T15:00:00Z",
  "updatedBy": "admin@acme.com",
  "version": 4,
  "_links": {
    "self": { "href": "/v1.0/tenants/tenant-550e8400-e29b-41d4-a716-446655440000" }
  }
}
```

---

### Park Tenant

Parks a tenant to release resources while preserving data (cost optimization).

**Request:**

```http
POST /v1.0/tenants/tenant-550e8400-e29b-41d4-a716-446655440000/lifecycle/park
Authorization: Bearer {token}
Content-Type: application/json

{
  "reason": "Customer requested temporary suspension for cost reduction"
}
```

**Request Fields:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| reason | string | Yes | Reason for parking (10-500 chars) |

**Response (200 OK):**

```json
{
  "tenantId": "tenant-550e8400-e29b-41d4-a716-446655440000",
  "status": "PARKED",
  "parkedAt": "2026-01-25T16:00:00Z",
  "parkedBy": "admin@acme.com",
  "parkReason": "Customer requested temporary suspension for cost reduction",
  "message": "Tenant parked successfully. Resources will be released within 5 minutes.",
  "_links": {
    "self": { "href": "/v1.0/tenants/tenant-550e8400-e29b-41d4-a716-446655440000" },
    "unpark": { "href": "/v1.0/tenants/tenant-550e8400-e29b-41d4-a716-446655440000/lifecycle/unpark" }
  }
}
```

---

### Unpark Tenant

Restores a parked tenant and reprovisions resources.

**Request:**

```http
POST /v1.0/tenants/tenant-550e8400-e29b-41d4-a716-446655440000/lifecycle/unpark
Authorization: Bearer {token}
```

**Response (200 OK):**

```json
{
  "tenantId": "tenant-550e8400-e29b-41d4-a716-446655440000",
  "status": "ACTIVE",
  "unparkedAt": "2026-01-25T17:00:00Z",
  "unparkedBy": "admin@acme.com",
  "message": "Tenant unpark initiated. Resources will be reprovisioned within 15 minutes.",
  "warning": "Full functionality may not be available immediately. Resource reprovisioning in progress.",
  "_links": {
    "self": { "href": "/v1.0/tenants/tenant-550e8400-e29b-41d4-a716-446655440000" },
    "park": { "href": "/v1.0/tenants/tenant-550e8400-e29b-41d4-a716-446655440000/lifecycle/park" }
  }
}
```

---

### Delete Tenant

Soft-deletes a tenant (sets status to DEPROVISIONED).

**Request:**

```http
DELETE /v1.0/tenants/tenant-550e8400-e29b-41d4-a716-446655440000?force=false
Authorization: Bearer {token}
```

**Query Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| force | boolean | false | Skip resource checks |

**Response (200 OK):**

```json
{
  "tenantId": "tenant-550e8400-e29b-41d4-a716-446655440000",
  "status": "DEPROVISIONED",
  "deprovisionedAt": "2026-01-25T18:00:00Z",
  "deprovisionedBy": "admin@acme.com",
  "message": "Tenant deprovisioned. Resources will be cleaned up within 24 hours."
}
```

---

### Assign User to Tenant

Assigns a user to a tenant with a specific role.

**Request:**

```http
POST /v1.0/tenants/tenant-550e8400-e29b-41d4-a716-446655440000/users
Authorization: Bearer {token}
Content-Type: application/json

{
  "email": "john.doe@acme.com",
  "role": "Admin"
}
```

**Request Fields:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| email | string | Yes | User email address |
| role | string | Yes | `Admin`, `Operator`, or `Viewer` |

**Response (201 Created):**

```json
{
  "tenantId": "tenant-550e8400-e29b-41d4-a716-446655440000",
  "userId": "user-123e4567-e89b-12d3-a456-426614174000",
  "email": "john.doe@acme.com",
  "role": "Admin",
  "assignedAt": "2026-01-25T11:00:00Z",
  "assignedBy": "admin@bbws.io",
  "_links": {
    "self": { "href": "/v1.0/tenants/tenant-550e8400/users/user-123e4567" },
    "tenant": { "href": "/v1.0/tenants/tenant-550e8400" }
  }
}
```

---

## HATEOAS Navigation

The Tenant API follows hierarchical HATEOAS design. Use the `_links` in responses to navigate:

```
/v1.0/tenants
└── /{tenantId}
    ├── /divisions
    │   └── /{divisionId}
    │       └── /groups
    │           └── /{groupId}
    │               └── /teams
    │                   └── /{teamId}
    │                       └── /users
    ├── /users
    ├── /invitations
    │   └── /{invitationId}
    │       ├── /resend
    │       └── /revoke
    └── /lifecycle
        ├── /suspend
        ├── /resume
        ├── /park
        └── /unpark
```

---

## Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| VALIDATION_ERROR | 400 | Request validation failed |
| UNAUTHORIZED | 401 | Invalid or missing token |
| FORBIDDEN | 403 | Insufficient permissions |
| TENANT_NOT_FOUND | 404 | Tenant does not exist |
| CONFLICT | 409 | Organization name exists |
| INVALID_STATUS_TRANSITION | 422 | Invalid state change |
| RATE_LIMITED | 429 | Too many requests |
| INTERNAL_ERROR | 500 | Server error |

**Error Response Format:**

```json
{
  "error": {
    "code": "INVALID_STATUS_TRANSITION",
    "message": "Cannot park a tenant that is not ACTIVE",
    "details": {
      "currentStatus": "SUSPENDED",
      "requestedStatus": "PARKED",
      "allowedTransitions": ["ACTIVE", "DEPROVISIONED"]
    }
  },
  "requestId": "req-abc123",
  "timestamp": "2026-01-25T14:30:00Z"
}
```

---

## Code Examples

### Create and Configure Tenant (Python)

```python
import requests

BASE_URL = "https://api-dev.bigbeardweb.solutions/v1.0"
TOKEN = "your-access-token"

headers = {
    "Authorization": f"Bearer {TOKEN}",
    "Content-Type": "application/json"
}

# Create tenant
tenant_data = {
    "organizationName": "Acme Corporation",
    "contactEmail": "admin@acme.com",
    "environment": "dev",
    "division": "Technology",
    "metadata": {
        "industry": "Software",
        "tier": "PREMIUM"
    }
}

response = requests.post(
    f"{BASE_URL}/tenants",
    headers=headers,
    json=tenant_data
)
tenant = response.json()
tenant_id = tenant["tenantId"]
print(f"Created tenant: {tenant_id}")

# Follow HATEOAS link to add user
users_url = tenant["_links"]["users"]["href"]
user_data = {
    "email": "john.doe@acme.com",
    "role": "Admin"
}

response = requests.post(
    f"{BASE_URL}{users_url}",
    headers=headers,
    json=user_data
)
user = response.json()
print(f"Assigned user: {user['userId']}")

# Park tenant when not in use
park_url = tenant["_links"]["lifecycle"]["park"]["href"]
park_data = {
    "reason": "Scheduled maintenance - customer notified"
}

response = requests.post(
    f"{BASE_URL}{park_url}",
    headers=headers,
    json=park_data
)
result = response.json()
print(f"Tenant parked: {result['status']}")
```

### Create and Configure Tenant (JavaScript)

```javascript
const BASE_URL = 'https://api-dev.bigbeardweb.solutions/v1.0';
const TOKEN = 'your-access-token';

const headers = {
  'Authorization': `Bearer ${TOKEN}`,
  'Content-Type': 'application/json'
};

async function createAndConfigureTenant() {
  // Create tenant
  const tenantResponse = await fetch(`${BASE_URL}/tenants`, {
    method: 'POST',
    headers,
    body: JSON.stringify({
      organizationName: 'Acme Corporation',
      contactEmail: 'admin@acme.com',
      environment: 'dev',
      division: 'Technology',
      metadata: {
        industry: 'Software',
        tier: 'PREMIUM'
      }
    })
  });

  const tenant = await tenantResponse.json();
  console.log(`Created tenant: ${tenant.tenantId}`);

  // Follow HATEOAS link to add user
  const usersUrl = tenant._links.users.href;
  const userResponse = await fetch(`${BASE_URL}${usersUrl}`, {
    method: 'POST',
    headers,
    body: JSON.stringify({
      email: 'john.doe@acme.com',
      role: 'Admin'
    })
  });

  const user = await userResponse.json();
  console.log(`Assigned user: ${user.userId}`);

  // Park tenant when not in use
  const parkUrl = tenant._links.lifecycle.park.href;
  const parkResponse = await fetch(`${BASE_URL}${parkUrl}`, {
    method: 'POST',
    headers,
    body: JSON.stringify({
      reason: 'Scheduled maintenance - customer notified'
    })
  });

  const result = await parkResponse.json();
  console.log(`Tenant parked: ${result.status}`);

  return tenant;
}

createAndConfigureTenant().catch(console.error);
```

---

## Related Documentation

- [Getting Started](./getting-started.md)
- [Authentication](./authentication.md)
- [Site API Guide](./site-api-guide.md)
- [Instance API Guide](./instance-api-guide.md)
- [Error Handling](./error-handling.md)
- [Pagination](./pagination.md)

---

**End of Document**
