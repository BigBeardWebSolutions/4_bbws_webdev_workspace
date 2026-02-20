# Pagination Guide

**Version**: 1.0
**Last Updated**: 2026-01-25

---

## Overview

BBWS APIs use cursor-based pagination for list endpoints. This approach provides consistent results even when data is modified between requests.

---

## Pagination Parameters

### Request Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `pageSize` | integer | 20 | Number of items per page (1-100) |
| `startAt` | string | - | Cursor token from previous response |

### Response Fields

| Field | Type | Description |
|-------|------|-------------|
| `items` | array | Array of requested resources |
| `count` | integer | Number of items in current page |
| `moreAvailable` | boolean | Whether more pages exist |
| `nextToken` | string | Cursor for next page (null if last page) |
| `_links.next` | object | HATEOAS link to next page |

---

## How It Works

### Cursor-Based Pagination

BBWS uses an opaque cursor token that encodes the position in the result set:

```
┌─────────────────────────────────────────────────────────────────┐
│                        Result Set                                │
├─────────────────────────────────────────────────────────────────┤
│  Page 1 (items 1-20)                                            │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ Item 1 │ Item 2 │ ... │ Item 20 │                         │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                      ▲                          │
│                                      │ nextToken                │
│                                                                  │
│  Page 2 (items 21-40)                                           │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ Item 21 │ Item 22 │ ... │ Item 40 │                       │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                       ▲                         │
│                                       │ nextToken               │
│                                                                  │
│  Page 3 (items 41-45) - Last page                               │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ Item 41 │ Item 42 │ Item 43 │ Item 44 │ Item 45 │         │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                       ▲                         │
│                                       │ nextToken = null        │
└─────────────────────────────────────────────────────────────────┘
```

---

## Basic Usage

### First Page Request

```http
GET /v1.0/tenants?pageSize=20
Authorization: Bearer {token}
```

**Response:**

```json
{
  "items": [
    { "tenantId": "tenant-001", "organizationName": "Alpha Corp", "status": "ACTIVE" },
    { "tenantId": "tenant-002", "organizationName": "Beta Inc", "status": "ACTIVE" },
    // ... 18 more items
  ],
  "count": 20,
  "moreAvailable": true,
  "nextToken": "eyJsYXN0S2V5IjoiVEVOQU5UI3RlbmFudC0wMjAifQ==",
  "_links": {
    "self": { "href": "/v1.0/tenants?pageSize=20" },
    "next": { "href": "/v1.0/tenants?pageSize=20&startAt=eyJsYXN0S2V5IjoiVEVOQU5UI3RlbmFudC0wMjAifQ==" }
  }
}
```

### Subsequent Page Request

Use the `nextToken` from the previous response:

```http
GET /v1.0/tenants?pageSize=20&startAt=eyJsYXN0S2V5IjoiVEVOQU5UI3RlbmFudC0wMjAifQ==
Authorization: Bearer {token}
```

**Response:**

```json
{
  "items": [
    { "tenantId": "tenant-021", "organizationName": "Gamma LLC", "status": "ACTIVE" },
    // ... more items
  ],
  "count": 15,
  "moreAvailable": false,
  "nextToken": null,
  "_links": {
    "self": { "href": "/v1.0/tenants?pageSize=20&startAt=eyJsYXN0S2V5IjoiVEVOQU5UI3RlbmFudC0wMjAifQ==" },
    "prev": { "href": "/v1.0/tenants?pageSize=20" }
  }
}
```

---

## With Filters

Pagination works with all filter parameters:

```http
GET /v1.0/tenants?status=ACTIVE&environment=dev&pageSize=10
Authorization: Bearer {token}
```

**Response:**

```json
{
  "items": [
    { "tenantId": "tenant-001", "status": "ACTIVE", "environment": "dev" },
    // ... 9 more items
  ],
  "count": 10,
  "moreAvailable": true,
  "nextToken": "eyJsYXN0S2V5IjoiVEVOQU5UI3RlbmFudC0wMTAiLCJmaWx0ZXJzIjp7InN0YXR1cyI6IkFDVElWRSJ9fQ==",
  "_links": {
    "self": { "href": "/v1.0/tenants?status=ACTIVE&environment=dev&pageSize=10" },
    "next": { "href": "/v1.0/tenants?status=ACTIVE&environment=dev&pageSize=10&startAt=eyJsYXN0S2V5IjoiVEVOQU5UI3RlbmFudC0wMTAiLCJmaWx0ZXJzIjp7InN0YXR1cyI6IkFDVElWRSJ9fQ==" }
  }
}
```

**Important:** Always include the same filter parameters when using the `startAt` token. The token encodes the filter context.

---

## Code Examples

### Python: Iterate All Pages

```python
import requests
from typing import Generator, List, Optional

def paginate_all(
    base_url: str,
    path: str,
    token: str,
    page_size: int = 20,
    filters: dict = None
) -> Generator[dict, None, None]:
    """
    Generator that yields all items across all pages.

    Args:
        base_url: API base URL
        path: Endpoint path (e.g., "/tenants")
        token: Access token
        page_size: Items per page
        filters: Optional filter parameters

    Yields:
        Individual items from all pages
    """
    headers = {"Authorization": f"Bearer {token}"}
    params = {"pageSize": page_size}

    if filters:
        params.update(filters)

    next_token = None

    while True:
        if next_token:
            params["startAt"] = next_token

        response = requests.get(
            f"{base_url}{path}",
            headers=headers,
            params=params
        )
        response.raise_for_status()
        data = response.json()

        for item in data["items"]:
            yield item

        if not data.get("moreAvailable", False):
            break

        next_token = data.get("nextToken")
        if not next_token:
            break


def get_all_items(
    base_url: str,
    path: str,
    token: str,
    page_size: int = 20,
    filters: dict = None
) -> List[dict]:
    """
    Fetch all items from a paginated endpoint.

    Args:
        base_url: API base URL
        path: Endpoint path
        token: Access token
        page_size: Items per page
        filters: Optional filter parameters

    Returns:
        List of all items
    """
    return list(paginate_all(base_url, path, token, page_size, filters))


# Usage Examples

BASE_URL = "https://api-dev.bigbeardweb.solutions/v1.0"
TOKEN = "your-access-token"

# Example 1: Get all tenants
all_tenants = get_all_items(BASE_URL, "/tenants", TOKEN)
print(f"Total tenants: {len(all_tenants)}")

# Example 2: Get active tenants with filter
active_tenants = get_all_items(
    BASE_URL,
    "/tenants",
    TOKEN,
    page_size=50,
    filters={"status": "ACTIVE", "environment": "dev"}
)
print(f"Active tenants: {len(active_tenants)}")

# Example 3: Process items as they come (memory efficient)
for tenant in paginate_all(BASE_URL, "/tenants", TOKEN, page_size=100):
    print(f"Processing tenant: {tenant['tenantId']}")
    # Process each tenant individually


# Example 4: Parallel processing with pages
import concurrent.futures

def process_page(page_data: dict) -> List[str]:
    """Process a single page of results."""
    results = []
    for item in page_data["items"]:
        # Do something with each item
        results.append(item["tenantId"])
    return results


def get_pages_parallel(
    base_url: str,
    path: str,
    token: str,
    max_pages: int = 10
) -> List[dict]:
    """Fetch multiple pages (for demonstration - typically sequential is fine)."""
    headers = {"Authorization": f"Bearer {token}"}
    pages = []

    # First, collect page tokens
    params = {"pageSize": 100}
    page_count = 0

    while page_count < max_pages:
        if pages:
            params["startAt"] = pages[-1].get("nextToken")

        response = requests.get(f"{base_url}{path}", headers=headers, params=params)
        response.raise_for_status()
        data = response.json()
        pages.append(data)
        page_count += 1

        if not data.get("moreAvailable", False):
            break

    return pages
```

### JavaScript: Iterate All Pages

```typescript
interface PaginatedResponse<T> {
  items: T[];
  count: number;
  moreAvailable: boolean;
  nextToken: string | null;
}

interface TenantSummary {
  tenantId: string;
  organizationName: string;
  status: string;
}

async function* paginateAll<T>(
  baseUrl: string,
  path: string,
  token: string,
  pageSize: number = 20,
  filters: Record<string, string> = {}
): AsyncGenerator<T> {
  const headers = { 'Authorization': `Bearer ${token}` };
  let nextToken: string | null = null;

  while (true) {
    const params = new URLSearchParams({
      pageSize: pageSize.toString(),
      ...filters
    });

    if (nextToken) {
      params.append('startAt', nextToken);
    }

    const response = await fetch(`${baseUrl}${path}?${params}`, { headers });

    if (!response.ok) {
      throw new Error(`Request failed: ${response.status}`);
    }

    const data: PaginatedResponse<T> = await response.json();

    for (const item of data.items) {
      yield item;
    }

    if (!data.moreAvailable) {
      break;
    }

    nextToken = data.nextToken;
    if (!nextToken) {
      break;
    }
  }
}

async function getAllItems<T>(
  baseUrl: string,
  path: string,
  token: string,
  pageSize: number = 20,
  filters: Record<string, string> = {}
): Promise<T[]> {
  const items: T[] = [];

  for await (const item of paginateAll<T>(baseUrl, path, token, pageSize, filters)) {
    items.push(item);
  }

  return items;
}

// Usage Examples

const BASE_URL = 'https://api-dev.bigbeardweb.solutions/v1.0';
const TOKEN = 'your-access-token';

async function examples() {
  // Example 1: Get all tenants
  const allTenants = await getAllItems<TenantSummary>(BASE_URL, '/tenants', TOKEN);
  console.log(`Total tenants: ${allTenants.length}`);

  // Example 2: Get active tenants with filter
  const activeTenants = await getAllItems<TenantSummary>(
    BASE_URL,
    '/tenants',
    TOKEN,
    50,
    { status: 'ACTIVE', environment: 'dev' }
  );
  console.log(`Active tenants: ${activeTenants.length}`);

  // Example 3: Process items as they come (memory efficient)
  for await (const tenant of paginateAll<TenantSummary>(BASE_URL, '/tenants', TOKEN, 100)) {
    console.log(`Processing tenant: ${tenant.tenantId}`);
    // Process each tenant individually
  }

  // Example 4: Take first N items
  const firstTen: TenantSummary[] = [];
  for await (const tenant of paginateAll<TenantSummary>(BASE_URL, '/tenants', TOKEN, 10)) {
    firstTen.push(tenant);
    if (firstTen.length >= 10) break;
  }
  console.log(`First 10 tenants:`, firstTen);
}

examples().catch(console.error);
```

---

## Best Practices

### Do's

1. **Use consistent page sizes** - Avoid changing `pageSize` between requests
2. **Preserve filters** - Include all original filter parameters with each page request
3. **Handle empty pages** - Check `count` or `items.length` before processing
4. **Respect rate limits** - Add appropriate delays between page requests
5. **Use generators** - For large datasets, process items as they arrive

### Don'ts

1. **Don't parse the token** - Treat `nextToken` as an opaque string
2. **Don't cache tokens long-term** - Tokens may expire or become invalid
3. **Don't assume page count** - Use `moreAvailable` to determine if more pages exist
4. **Don't modify data mid-iteration** - May cause inconsistent results

---

## Pagination Limits

| Endpoint | Max Page Size | Default Page Size |
|----------|---------------|-------------------|
| `/tenants` | 100 | 20 |
| `/tenants/{id}/sites` | 100 | 20 |
| `/tenants/{id}/users` | 100 | 20 |
| `/tenants/{id}/instances` | 50 | 10 |
| `/templates` | 50 | 20 |

---

## Token Expiration

Pagination tokens expire after:

- **24 hours** from creation
- **Immediately** if underlying data structure changes significantly

If a token has expired:

```json
{
  "error": {
    "code": "INVALID_PAGINATION_TOKEN",
    "message": "The pagination token has expired or is invalid",
    "details": {
      "hint": "Start from the first page without a startAt parameter"
    }
  },
  "requestId": "req-abc123",
  "timestamp": "2026-01-25T14:30:00Z"
}
```

**Resolution:** Start pagination from the beginning (without `startAt`).

---

## Using HATEOAS Links

You can also navigate pages using HATEOAS links in the response:

```python
def paginate_using_links(base_url: str, initial_path: str, token: str):
    """Paginate using HATEOAS links."""
    headers = {"Authorization": f"Bearer {token}"}
    url = f"{base_url}{initial_path}"

    while url:
        response = requests.get(url, headers=headers)
        response.raise_for_status()
        data = response.json()

        for item in data["items"]:
            yield item

        # Follow the 'next' link if available
        next_link = data.get("_links", {}).get("next", {}).get("href")
        if next_link and data.get("moreAvailable"):
            url = f"{base_url}{next_link}"
        else:
            url = None
```

---

## Related Documentation

- [Getting Started](./getting-started.md)
- [Tenant API Guide](./tenant-api-guide.md)
- [Error Handling](./error-handling.md)

---

**End of Document**
