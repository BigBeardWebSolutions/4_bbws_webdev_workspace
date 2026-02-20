# Site API Guide

**Version**: 1.0
**Last Updated**: 2026-01-25
**LLD Reference**: [2.6_LLD_WordPress_Site_Management](../../LLDs/2.6_LLD_WordPress_Site_Management.md)

---

## Overview

The Site API manages WordPress sites within tenant organizations. It supports site creation, cloning, template management, and plugin operations.

### Key Concepts

| Concept | Description |
|---------|-------------|
| **Site** | A WordPress installation within a tenant |
| **Template** | Pre-configured site configurations |
| **Plugin** | WordPress plugins that can be managed |
| **Async Operations** | Long-running operations return immediately with tracking |

---

## Base URL

```
https://api-{env}.bigbeardweb.solutions/v1.0/tenants/{tenantId}/sites
```

---

## Authentication

All endpoints require a valid JWT token:

```
Authorization: Bearer {access_token}
```

See [Authentication Guide](./authentication.md) for details.

---

## Asynchronous Operations

Site creation and cloning are **asynchronous** operations. These operations:

1. Return immediately with `202 Accepted`
2. Provide a `requestId` for tracking
3. Require polling to check completion status

### Async Operation Flow

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│  Client  │───>│   POST   │───>│  Lambda  │───>│   SQS    │
│          │<───│   API    │<───│          │    │  Queue   │
└──────────┘    └──────────┘    └──────────┘    └────┬─────┘
     │                                               │
     │  202 Accepted + requestId                     │
     │                                               ▼
     │                                          ┌──────────┐
     ├────────────────────────────────────────> │  Worker  │
     │  Poll GET /sites/{siteId}/status         │  Lambda  │
     │                                          └────┬─────┘
     │                                               │
     │  <──────────────── 200 OK (COMPLETED) <───────┘
```

---

## Site States

| State | Description |
|-------|-------------|
| CREATING | Initial creation in progress |
| ACTIVE | Fully operational |
| UPDATING | Configuration update in progress |
| CLONING | Clone operation in progress |
| SUSPENDED | Temporarily disabled |
| DELETING | Deletion in progress |
| DELETED | Soft-deleted |
| FAILED | Operation failed |

---

## API Endpoints

### Site Operations

| Method | Path | Description | Async |
|--------|------|-------------|-------|
| POST | `/tenants/{tenantId}/sites` | Create site | Yes |
| GET | `/tenants/{tenantId}/sites` | List sites | No |
| GET | `/tenants/{tenantId}/sites/{siteId}` | Get site | No |
| PUT | `/tenants/{tenantId}/sites/{siteId}` | Update site | No |
| DELETE | `/tenants/{tenantId}/sites/{siteId}` | Delete site | Yes |
| GET | `/tenants/{tenantId}/sites/{siteId}/status` | Get status | No |

### Clone Operations

| Method | Path | Description | Async |
|--------|------|-------------|-------|
| POST | `/tenants/{tenantId}/sites/{siteId}/clone` | Clone site | Yes |

### Template Operations

| Method | Path | Description |
|--------|------|-------------|
| GET | `/templates` | List templates |
| GET | `/templates/{templateId}` | Get template |

### Plugin Operations

| Method | Path | Description |
|--------|------|-------------|
| GET | `/tenants/{tenantId}/sites/{siteId}/plugins` | List plugins |
| POST | `/tenants/{tenantId}/sites/{siteId}/plugins` | Install plugin |
| PUT | `/tenants/{tenantId}/sites/{siteId}/plugins/{pluginId}` | Update plugin |
| DELETE | `/tenants/{tenantId}/sites/{siteId}/plugins/{pluginId}` | Remove plugin |

---

## Endpoint Details

### Create Site (Async)

Creates a new WordPress site for a tenant.

**Request:**

```http
POST /v1.0/tenants/tenant-123/sites
Authorization: Bearer {token}
Content-Type: application/json

{
  "siteName": "Corporate Blog",
  "subdomain": "blog",
  "templateId": "template-business-pro",
  "adminEmail": "admin@acme.com",
  "configuration": {
    "language": "en_US",
    "timezone": "Africa/Johannesburg",
    "plugins": ["yoast-seo", "wordfence"]
  }
}
```

**Request Fields:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| siteName | string | Yes | Display name (2-100 chars) |
| subdomain | string | Yes | URL subdomain (3-30 chars, lowercase) |
| templateId | string | No | Template to use |
| adminEmail | string | Yes | Site admin email |
| configuration.language | string | No | WordPress locale (default: en_US) |
| configuration.timezone | string | No | PHP timezone |
| configuration.plugins | array | No | Plugins to pre-install |

**Response (202 Accepted):**

```json
{
  "requestId": "req-550e8400-e29b-41d4-a716-446655440000",
  "siteId": "site-123e4567-e89b-12d3-a456-426614174000",
  "status": "CREATING",
  "message": "Site creation initiated. Use the status link to track progress.",
  "estimatedCompletionTime": "2026-01-25T11:00:00Z",
  "_links": {
    "self": { "href": "/v1.0/tenants/tenant-123/sites/site-123e4567" },
    "status": { "href": "/v1.0/tenants/tenant-123/sites/site-123e4567/status" },
    "cancel": { "href": "/v1.0/tenants/tenant-123/sites/site-123e4567/cancel" }
  }
}
```

---

### Get Site Status

Polls the status of an async operation.

**Request:**

```http
GET /v1.0/tenants/tenant-123/sites/site-123e4567/status
Authorization: Bearer {token}
```

**Response (200 OK - In Progress):**

```json
{
  "requestId": "req-550e8400-e29b-41d4-a716-446655440000",
  "siteId": "site-123e4567-e89b-12d3-a456-426614174000",
  "status": "CREATING",
  "progress": 45,
  "currentStep": "Installing WordPress core",
  "steps": [
    { "name": "Provisioning storage", "status": "COMPLETED" },
    { "name": "Creating database", "status": "COMPLETED" },
    { "name": "Installing WordPress core", "status": "IN_PROGRESS" },
    { "name": "Configuring plugins", "status": "PENDING" },
    { "name": "Applying template", "status": "PENDING" }
  ],
  "startedAt": "2026-01-25T10:30:00Z",
  "estimatedCompletionTime": "2026-01-25T11:00:00Z"
}
```

**Response (200 OK - Completed):**

```json
{
  "requestId": "req-550e8400-e29b-41d4-a716-446655440000",
  "siteId": "site-123e4567-e89b-12d3-a456-426614174000",
  "status": "ACTIVE",
  "progress": 100,
  "completedAt": "2026-01-25T10:58:00Z",
  "site": {
    "siteId": "site-123e4567-e89b-12d3-a456-426614174000",
    "siteName": "Corporate Blog",
    "url": "https://blog.acme.bigbeardweb.solutions",
    "adminUrl": "https://blog.acme.bigbeardweb.solutions/wp-admin",
    "status": "ACTIVE"
  },
  "_links": {
    "site": { "href": "/v1.0/tenants/tenant-123/sites/site-123e4567" }
  }
}
```

**Response (200 OK - Failed):**

```json
{
  "requestId": "req-550e8400-e29b-41d4-a716-446655440000",
  "siteId": "site-123e4567-e89b-12d3-a456-426614174000",
  "status": "FAILED",
  "progress": 30,
  "failedAt": "2026-01-25T10:45:00Z",
  "error": {
    "code": "DATABASE_CREATION_FAILED",
    "message": "Failed to create WordPress database",
    "details": "Connection timeout after 30s"
  },
  "_links": {
    "retry": { "href": "/v1.0/tenants/tenant-123/sites/site-123e4567/retry" }
  }
}
```

---

### Clone Site (Async)

Creates a copy of an existing site.

**Request:**

```http
POST /v1.0/tenants/tenant-123/sites/site-123e4567/clone
Authorization: Bearer {token}
Content-Type: application/json

{
  "siteName": "Corporate Blog - Staging",
  "subdomain": "blog-staging",
  "targetTenantId": "tenant-123",
  "options": {
    "includeContent": true,
    "includeMedia": true,
    "includePlugins": true,
    "includeUsers": false
  }
}
```

**Request Fields:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| siteName | string | Yes | Name for cloned site |
| subdomain | string | Yes | URL subdomain |
| targetTenantId | string | No | Target tenant (default: same) |
| options.includeContent | boolean | No | Clone posts/pages (default: true) |
| options.includeMedia | boolean | No | Clone media files (default: true) |
| options.includePlugins | boolean | No | Clone plugins (default: true) |
| options.includeUsers | boolean | No | Clone users (default: false) |

**Response (202 Accepted):**

```json
{
  "requestId": "req-clone-12345",
  "sourceSiteId": "site-123e4567",
  "clonedSiteId": "site-789abcde",
  "status": "CLONING",
  "message": "Clone operation initiated. This may take several minutes for large sites.",
  "estimatedCompletionTime": "2026-01-25T11:30:00Z",
  "_links": {
    "status": { "href": "/v1.0/tenants/tenant-123/sites/site-789abcde/status" }
  }
}
```

---

### List Sites

Returns all sites for a tenant.

**Request:**

```http
GET /v1.0/tenants/tenant-123/sites?status=ACTIVE&pageSize=20
Authorization: Bearer {token}
```

**Query Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| status | string | - | Filter by status |
| pageSize | integer | 20 | Items per page |
| startAt | string | - | Pagination token |

**Response (200 OK):**

```json
{
  "items": [
    {
      "siteId": "site-123e4567",
      "siteName": "Corporate Blog",
      "subdomain": "blog",
      "url": "https://blog.acme.bigbeardweb.solutions",
      "status": "ACTIVE",
      "templateId": "template-business-pro",
      "createdAt": "2026-01-25T10:00:00Z",
      "_links": {
        "self": { "href": "/v1.0/tenants/tenant-123/sites/site-123e4567" },
        "plugins": { "href": "/v1.0/tenants/tenant-123/sites/site-123e4567/plugins" }
      }
    }
  ],
  "count": 1,
  "moreAvailable": false,
  "_links": {
    "self": { "href": "/v1.0/tenants/tenant-123/sites" },
    "create": { "href": "/v1.0/tenants/tenant-123/sites", "method": "POST" }
  }
}
```

---

### Get Site Details

Returns detailed site information.

**Request:**

```http
GET /v1.0/tenants/tenant-123/sites/site-123e4567
Authorization: Bearer {token}
```

**Response (200 OK):**

```json
{
  "siteId": "site-123e4567",
  "tenantId": "tenant-123",
  "siteName": "Corporate Blog",
  "subdomain": "blog",
  "url": "https://blog.acme.bigbeardweb.solutions",
  "adminUrl": "https://blog.acme.bigbeardweb.solutions/wp-admin",
  "status": "ACTIVE",
  "templateId": "template-business-pro",
  "templateName": "Business Professional",
  "configuration": {
    "language": "en_US",
    "timezone": "Africa/Johannesburg",
    "wordpressVersion": "6.4.2",
    "phpVersion": "8.2"
  },
  "storage": {
    "usedMB": 256,
    "quotaMB": 5120
  },
  "database": {
    "sizeMB": 45
  },
  "traffic": {
    "last30Days": {
      "pageViews": 12500,
      "visitors": 3200
    }
  },
  "createdAt": "2026-01-25T10:00:00Z",
  "createdBy": "admin@acme.com",
  "updatedAt": "2026-01-25T14:00:00Z",
  "version": 5,
  "_links": {
    "self": { "href": "/v1.0/tenants/tenant-123/sites/site-123e4567" },
    "tenant": { "href": "/v1.0/tenants/tenant-123" },
    "plugins": { "href": "/v1.0/tenants/tenant-123/sites/site-123e4567/plugins" },
    "clone": { "href": "/v1.0/tenants/tenant-123/sites/site-123e4567/clone" },
    "suspend": { "href": "/v1.0/tenants/tenant-123/sites/site-123e4567/suspend" }
  }
}
```

---

### List Templates

Returns available site templates.

**Request:**

```http
GET /v1.0/templates?category=business
Authorization: Bearer {token}
```

**Response (200 OK):**

```json
{
  "items": [
    {
      "templateId": "template-business-pro",
      "name": "Business Professional",
      "description": "Clean, professional theme ideal for corporate websites",
      "category": "business",
      "thumbnail": "https://cdn.bigbeardweb.solutions/templates/business-pro.png",
      "features": [
        "Responsive design",
        "SEO optimized",
        "WooCommerce ready",
        "Multi-language support"
      ],
      "includedPlugins": [
        { "id": "yoast-seo", "name": "Yoast SEO" },
        { "id": "contact-form-7", "name": "Contact Form 7" }
      ],
      "tier": "PREMIUM",
      "_links": {
        "self": { "href": "/v1.0/templates/template-business-pro" },
        "preview": { "href": "https://preview.bigbeardweb.solutions/template-business-pro" }
      }
    }
  ],
  "count": 1
}
```

---

### Install Plugin

Installs a plugin on a site.

**Request:**

```http
POST /v1.0/tenants/tenant-123/sites/site-123e4567/plugins
Authorization: Bearer {token}
Content-Type: application/json

{
  "pluginId": "wordfence",
  "activate": true,
  "configuration": {
    "autoUpdate": true
  }
}
```

**Response (201 Created):**

```json
{
  "pluginId": "wordfence",
  "name": "Wordfence Security",
  "version": "7.10.0",
  "status": "ACTIVE",
  "autoUpdate": true,
  "installedAt": "2026-01-25T15:00:00Z",
  "_links": {
    "self": { "href": "/v1.0/tenants/tenant-123/sites/site-123e4567/plugins/wordfence" },
    "deactivate": { "href": "/v1.0/tenants/tenant-123/sites/site-123e4567/plugins/wordfence/deactivate" }
  }
}
```

---

## Status Polling Pattern

### Python Example

```python
import requests
import time
from typing import Optional

def create_site_and_wait(
    base_url: str,
    token: str,
    tenant_id: str,
    site_data: dict,
    timeout_seconds: int = 600,
    poll_interval: int = 10
) -> dict:
    """
    Create a site and wait for completion.

    Args:
        base_url: API base URL
        token: Access token
        tenant_id: Tenant ID
        site_data: Site creation payload
        timeout_seconds: Max wait time
        poll_interval: Seconds between polls

    Returns:
        Completed site data
    """
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }

    # Create site (async)
    response = requests.post(
        f"{base_url}/tenants/{tenant_id}/sites",
        headers=headers,
        json=site_data
    )
    response.raise_for_status()

    result = response.json()
    site_id = result["siteId"]
    status_url = result["_links"]["status"]["href"]

    print(f"Site creation initiated: {site_id}")
    print(f"Estimated completion: {result.get('estimatedCompletionTime')}")

    # Poll for completion
    start_time = time.time()
    while True:
        elapsed = time.time() - start_time
        if elapsed > timeout_seconds:
            raise TimeoutError(f"Site creation timed out after {timeout_seconds}s")

        status_response = requests.get(
            f"{base_url}{status_url}",
            headers=headers
        )
        status_response.raise_for_status()
        status_data = status_response.json()

        status = status_data["status"]
        progress = status_data.get("progress", 0)

        print(f"Status: {status} ({progress}%)")

        if status == "ACTIVE":
            print("Site creation completed successfully!")
            return status_data.get("site", status_data)

        if status == "FAILED":
            error = status_data.get("error", {})
            raise Exception(
                f"Site creation failed: {error.get('code')} - {error.get('message')}"
            )

        time.sleep(poll_interval)


# Usage
BASE_URL = "https://api-dev.bigbeardweb.solutions/v1.0"
TOKEN = "your-access-token"

site = create_site_and_wait(
    base_url=BASE_URL,
    token=TOKEN,
    tenant_id="tenant-123",
    site_data={
        "siteName": "My New Blog",
        "subdomain": "myblog",
        "templateId": "template-business-pro",
        "adminEmail": "admin@acme.com"
    }
)

print(f"Site URL: {site['url']}")
```

### JavaScript Example

```typescript
interface SiteCreationResult {
  requestId: string;
  siteId: string;
  status: string;
  _links: {
    status: { href: string };
  };
}

interface SiteStatus {
  status: string;
  progress: number;
  site?: {
    siteId: string;
    url: string;
  };
  error?: {
    code: string;
    message: string;
  };
}

async function createSiteAndWait(
  baseUrl: string,
  token: string,
  tenantId: string,
  siteData: Record<string, unknown>,
  timeoutSeconds: number = 600,
  pollIntervalMs: number = 10000
): Promise<SiteStatus> {
  const headers = {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  };

  // Create site (async)
  const createResponse = await fetch(`${baseUrl}/tenants/${tenantId}/sites`, {
    method: 'POST',
    headers,
    body: JSON.stringify(siteData)
  });

  if (!createResponse.ok) {
    throw new Error(`Failed to create site: ${createResponse.status}`);
  }

  const result: SiteCreationResult = await createResponse.json();
  const statusUrl = result._links.status.href;

  console.log(`Site creation initiated: ${result.siteId}`);

  // Poll for completion
  const startTime = Date.now();

  while (true) {
    const elapsed = (Date.now() - startTime) / 1000;
    if (elapsed > timeoutSeconds) {
      throw new Error(`Site creation timed out after ${timeoutSeconds}s`);
    }

    const statusResponse = await fetch(`${baseUrl}${statusUrl}`, { headers });

    if (!statusResponse.ok) {
      throw new Error(`Failed to get status: ${statusResponse.status}`);
    }

    const statusData: SiteStatus = await statusResponse.json();

    console.log(`Status: ${statusData.status} (${statusData.progress}%)`);

    if (statusData.status === 'ACTIVE') {
      console.log('Site creation completed successfully!');
      return statusData;
    }

    if (statusData.status === 'FAILED') {
      throw new Error(
        `Site creation failed: ${statusData.error?.code} - ${statusData.error?.message}`
      );
    }

    await new Promise(resolve => setTimeout(resolve, pollIntervalMs));
  }
}

// Usage
async function main() {
  const BASE_URL = 'https://api-dev.bigbeardweb.solutions/v1.0';
  const TOKEN = 'your-access-token';

  const result = await createSiteAndWait(
    BASE_URL,
    TOKEN,
    'tenant-123',
    {
      siteName: 'My New Blog',
      subdomain: 'myblog',
      templateId: 'template-business-pro',
      adminEmail: 'admin@acme.com'
    }
  );

  console.log(`Site URL: ${result.site?.url}`);
}

main().catch(console.error);
```

---

## Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| VALIDATION_ERROR | 400 | Request validation failed |
| SUBDOMAIN_TAKEN | 409 | Subdomain already in use |
| TEMPLATE_NOT_FOUND | 404 | Template does not exist |
| SITE_NOT_FOUND | 404 | Site does not exist |
| PLUGIN_NOT_COMPATIBLE | 422 | Plugin incompatible with WP version |
| QUOTA_EXCEEDED | 422 | Site quota exceeded |
| SITE_CREATION_FAILED | 500 | Internal creation error |

---

## Related Documentation

- [Getting Started](./getting-started.md)
- [Authentication](./authentication.md)
- [Tenant API Guide](./tenant-api-guide.md)
- [Instance API Guide](./instance-api-guide.md)
- [Error Handling](./error-handling.md)
- [Pagination](./pagination.md)

---

**End of Document**
