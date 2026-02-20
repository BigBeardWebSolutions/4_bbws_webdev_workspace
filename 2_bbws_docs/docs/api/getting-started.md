# Getting Started with BBWS APIs

**Version**: 1.0
**Last Updated**: 2026-01-25

---

## Overview

The BBWS (Big Beard Web Solutions) platform provides a comprehensive suite of RESTful APIs for managing multi-tenant WordPress hosting infrastructure. This guide will help you get started with the BBWS APIs quickly.

### API Categories

| API | Purpose | Documentation |
|-----|---------|---------------|
| **Tenant API** | Manage tenant organizations, users, and hierarchy | [Tenant API Guide](./tenant-api-guide.md) |
| **Site API** | Manage WordPress sites, templates, and plugins | [Site API Guide](./site-api-guide.md) |
| **Instance API** | Manage WordPress infrastructure instances | [Instance API Guide](./instance-api-guide.md) |
| **Auth API** | User authentication and registration | [Authentication](./authentication.md) |

---

## Base URLs

All BBWS APIs are accessed through environment-specific base URLs:

| Environment | Base URL | Purpose |
|-------------|----------|---------|
| **DEV** | `https://api-dev.bigbeardweb.solutions/v1.0` | Development and testing |
| **SIT** | `https://api-sit.bigbeardweb.solutions/v1.0` | System Integration Testing |
| **PROD** | `https://api.bigbeardweb.solutions/v1.0` | Production |

### API Versioning

All endpoints are versioned using URL path versioning. The current version is `v1.0`:

```
https://api-dev.bigbeardweb.solutions/v1.0/tenants
```

---

## Quick Start

### Step 1: Obtain Authentication Credentials

Before making API calls, you need to authenticate with AWS Cognito to obtain a JWT token.

```bash
# Using curl to authenticate
curl -X POST https://cognito-idp.af-south-1.amazonaws.com/ \
  -H "Content-Type: application/x-amz-json-1.1" \
  -H "X-Amz-Target: AWSCognitoIdentityProviderService.InitiateAuth" \
  -d '{
    "AuthFlow": "USER_PASSWORD_AUTH",
    "ClientId": "YOUR_COGNITO_CLIENT_ID",
    "AuthParameters": {
      "USERNAME": "your.email@example.com",
      "PASSWORD": "your-password"
    }
  }'
```

### Step 2: Make Your First API Call

Use the obtained access token to list your tenants:

```bash
curl -X GET https://api-dev.bigbeardweb.solutions/v1.0/tenants \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json"
```

### Step 3: Create a Tenant

```bash
curl -X POST https://api-dev.bigbeardweb.solutions/v1.0/tenants \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "organizationName": "My Company",
    "contactEmail": "admin@mycompany.com",
    "environment": "dev"
  }'
```

**Response (201 Created):**

```json
{
  "tenantId": "tenant-550e8400-e29b-41d4-a716-446655440000",
  "organizationName": "My Company",
  "contactEmail": "admin@mycompany.com",
  "environment": "dev",
  "status": "PENDING",
  "createdAt": "2026-01-25T10:30:00Z",
  "_links": {
    "self": { "href": "/v1.0/tenants/tenant-550e8400-e29b-41d4-a716-446655440000" },
    "users": { "href": "/v1.0/tenants/tenant-550e8400-e29b-41d4-a716-446655440000/users" },
    "sites": { "href": "/v1.0/tenants/tenant-550e8400-e29b-41d4-a716-446655440000/sites" }
  }
}
```

---

## Authentication Overview

BBWS APIs use AWS Cognito for authentication. All requests must include a valid JWT token in the `Authorization` header.

### Required Headers

| Header | Required | Description |
|--------|----------|-------------|
| `Authorization` | Yes | Bearer token from Cognito: `Bearer {access_token}` |
| `Content-Type` | Yes | `application/json` for request bodies |
| `X-Request-ID` | No | Optional request correlation ID for tracing |

### Token Format

The access token contains claims that identify the user and their permissions:

```json
{
  "sub": "user-uuid",
  "email": "user@example.com",
  "cognito:groups": ["Admins", "tenant-123-admins"],
  "custom:customerId": "customer-uuid",
  "custom:tenantIds": "tenant-1,tenant-2"
}
```

For detailed authentication information, see [Authentication Guide](./authentication.md).

---

## HATEOAS Navigation

BBWS APIs follow the HATEOAS (Hypermedia as the Engine of Application State) principle. Each response includes `_links` that allow you to navigate the API without hardcoding URLs.

### Example Response with Links

```json
{
  "tenantId": "tenant-123",
  "organizationName": "Acme Corp",
  "status": "ACTIVE",
  "_links": {
    "self": { "href": "/v1.0/tenants/tenant-123" },
    "users": { "href": "/v1.0/tenants/tenant-123/users" },
    "sites": { "href": "/v1.0/tenants/tenant-123/sites" },
    "instances": { "href": "/v1.0/tenants/tenant-123/instances" },
    "lifecycle": {
      "park": { "href": "/v1.0/tenants/tenant-123/lifecycle/park" },
      "suspend": { "href": "/v1.0/tenants/tenant-123/lifecycle/suspend" }
    }
  }
}
```

### Following Links

```python
import requests

# Get tenant details
response = requests.get(
    "https://api-dev.bigbeardweb.solutions/v1.0/tenants/tenant-123",
    headers={"Authorization": f"Bearer {token}"}
)
tenant = response.json()

# Follow the 'sites' link to get tenant sites
sites_url = tenant["_links"]["sites"]["href"]
sites_response = requests.get(
    f"https://api-dev.bigbeardweb.solutions{sites_url}",
    headers={"Authorization": f"Bearer {token}"}
)
```

---

## Common Operations

### List Resources (with Pagination)

```bash
# List tenants with pagination
curl -X GET "https://api-dev.bigbeardweb.solutions/v1.0/tenants?pageSize=20&startAt=token123" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Get a Single Resource

```bash
# Get specific tenant
curl -X GET https://api-dev.bigbeardweb.solutions/v1.0/tenants/tenant-123 \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Create a Resource

```bash
# Create a new site
curl -X POST https://api-dev.bigbeardweb.solutions/v1.0/tenants/tenant-123/sites \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "siteName": "My WordPress Site",
    "subdomain": "myblog",
    "templateId": "template-business-pro"
  }'
```

### Update a Resource

```bash
# Update tenant details
curl -X PUT https://api-dev.bigbeardweb.solutions/v1.0/tenants/tenant-123 \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "organizationName": "Updated Company Name",
    "contactEmail": "newemail@company.com"
  }'
```

### Delete a Resource

```bash
# Delete a site (soft delete)
curl -X DELETE https://api-dev.bigbeardweb.solutions/v1.0/tenants/tenant-123/sites/site-456 \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## SDK Examples

### Python

```python
import requests
from typing import Optional

class BBWSClient:
    def __init__(self, base_url: str, access_token: str):
        self.base_url = base_url
        self.headers = {
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/json"
        }

    def list_tenants(self, page_size: int = 20, start_at: Optional[str] = None):
        params = {"pageSize": page_size}
        if start_at:
            params["startAt"] = start_at

        response = requests.get(
            f"{self.base_url}/tenants",
            headers=self.headers,
            params=params
        )
        response.raise_for_status()
        return response.json()

    def create_tenant(self, organization_name: str, contact_email: str, environment: str = "dev"):
        payload = {
            "organizationName": organization_name,
            "contactEmail": contact_email,
            "environment": environment
        }

        response = requests.post(
            f"{self.base_url}/tenants",
            headers=self.headers,
            json=payload
        )
        response.raise_for_status()
        return response.json()

    def get_tenant(self, tenant_id: str):
        response = requests.get(
            f"{self.base_url}/tenants/{tenant_id}",
            headers=self.headers
        )
        response.raise_for_status()
        return response.json()


# Usage
client = BBWSClient(
    base_url="https://api-dev.bigbeardweb.solutions/v1.0",
    access_token="your-access-token"
)

# List tenants
tenants = client.list_tenants()
print(f"Found {len(tenants['items'])} tenants")

# Create a tenant
new_tenant = client.create_tenant(
    organization_name="My Company",
    contact_email="admin@mycompany.com"
)
print(f"Created tenant: {new_tenant['tenantId']}")
```

### JavaScript/TypeScript

```typescript
interface BBWSConfig {
  baseUrl: string;
  accessToken: string;
}

interface Tenant {
  tenantId: string;
  organizationName: string;
  contactEmail: string;
  status: string;
  _links: Record<string, { href: string }>;
}

class BBWSClient {
  private baseUrl: string;
  private headers: HeadersInit;

  constructor(config: BBWSConfig) {
    this.baseUrl = config.baseUrl;
    this.headers = {
      'Authorization': `Bearer ${config.accessToken}`,
      'Content-Type': 'application/json'
    };
  }

  async listTenants(pageSize: number = 20, startAt?: string): Promise<{ items: Tenant[], moreAvailable: boolean }> {
    const params = new URLSearchParams({ pageSize: pageSize.toString() });
    if (startAt) params.append('startAt', startAt);

    const response = await fetch(`${this.baseUrl}/tenants?${params}`, {
      headers: this.headers
    });

    if (!response.ok) {
      throw new Error(`API error: ${response.status}`);
    }

    return response.json();
  }

  async createTenant(organizationName: string, contactEmail: string, environment: string = 'dev'): Promise<Tenant> {
    const response = await fetch(`${this.baseUrl}/tenants`, {
      method: 'POST',
      headers: this.headers,
      body: JSON.stringify({
        organizationName,
        contactEmail,
        environment
      })
    });

    if (!response.ok) {
      throw new Error(`API error: ${response.status}`);
    }

    return response.json();
  }

  async getTenant(tenantId: string): Promise<Tenant> {
    const response = await fetch(`${this.baseUrl}/tenants/${tenantId}`, {
      headers: this.headers
    });

    if (!response.ok) {
      throw new Error(`API error: ${response.status}`);
    }

    return response.json();
  }
}

// Usage
const client = new BBWSClient({
  baseUrl: 'https://api-dev.bigbeardweb.solutions/v1.0',
  accessToken: 'your-access-token'
});

// List tenants
const tenants = await client.listTenants();
console.log(`Found ${tenants.items.length} tenants`);

// Create a tenant
const newTenant = await client.createTenant('My Company', 'admin@mycompany.com');
console.log(`Created tenant: ${newTenant.tenantId}`);
```

---

## Rate Limiting

BBWS APIs implement rate limiting to ensure fair usage:

| Endpoint Type | Rate Limit |
|---------------|------------|
| Read operations (GET) | 100 requests/second |
| Write operations (POST/PUT/DELETE) | 50 requests/second |
| Authentication | 10 requests/minute per user |

When rate limited, the API returns `429 Too Many Requests` with a `Retry-After` header.

---

## Next Steps

1. **[Authentication Guide](./authentication.md)** - Learn about Cognito authentication and token management
2. **[Tenant API Guide](./tenant-api-guide.md)** - Manage organizations and users
3. **[Site API Guide](./site-api-guide.md)** - Create and manage WordPress sites
4. **[Instance API Guide](./instance-api-guide.md)** - Manage WordPress infrastructure
5. **[Error Handling](./error-handling.md)** - Handle errors gracefully
6. **[Pagination](./pagination.md)** - Navigate large result sets

---

## Support

For API support:
- **Email**: api-support@bigbeardweb.solutions
- **Documentation Issues**: Create an issue in the docs repository

---

**End of Document**
