# Error Handling Guide

**Version**: 1.0
**Last Updated**: 2026-01-25

---

## Overview

BBWS APIs use standard HTTP status codes and a consistent error response format. This guide covers error formats, error codes, and retry strategies.

---

## Error Response Format

All error responses follow this structure:

```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable error message",
    "details": {
      "field": "Additional context about the error"
    },
    "documentationUrl": "https://docs.bigbeardweb.solutions/errors/ERROR_CODE"
  },
  "requestId": "req-550e8400-e29b-41d4-a716-446655440000",
  "timestamp": "2026-01-25T14:30:00Z"
}
```

### Response Fields

| Field | Type | Description |
|-------|------|-------------|
| error.code | string | Machine-readable error code |
| error.message | string | Human-readable description |
| error.details | object | Additional error context |
| error.documentationUrl | string | Link to detailed documentation |
| requestId | string | Unique request identifier for support |
| timestamp | string | ISO 8601 timestamp |

---

## HTTP Status Codes

### Client Errors (4xx)

| Status | Meaning | When Used |
|--------|---------|-----------|
| 400 | Bad Request | Invalid request format or parameters |
| 401 | Unauthorized | Missing or invalid authentication |
| 403 | Forbidden | Valid auth but insufficient permissions |
| 404 | Not Found | Resource does not exist |
| 405 | Method Not Allowed | HTTP method not supported |
| 409 | Conflict | Resource state conflict (e.g., duplicate) |
| 422 | Unprocessable Entity | Valid format but semantic errors |
| 429 | Too Many Requests | Rate limit exceeded |

### Server Errors (5xx)

| Status | Meaning | When Used |
|--------|---------|-----------|
| 500 | Internal Server Error | Unexpected server error |
| 502 | Bad Gateway | Upstream service failure |
| 503 | Service Unavailable | Service temporarily unavailable |
| 504 | Gateway Timeout | Upstream service timeout |

---

## Error Codes Reference

### Validation Errors (400)

| Code | Description | Resolution |
|------|-------------|------------|
| VALIDATION_ERROR | Request validation failed | Check request body against schema |
| INVALID_JSON | Malformed JSON in request | Fix JSON syntax |
| MISSING_REQUIRED_FIELD | Required field not provided | Include all required fields |
| INVALID_FIELD_VALUE | Field value is invalid | Check field constraints |
| INVALID_FIELD_TYPE | Wrong data type for field | Use correct data type |
| FIELD_TOO_LONG | String exceeds max length | Shorten the value |
| FIELD_TOO_SHORT | String below min length | Provide longer value |
| INVALID_EMAIL | Email format is invalid | Use valid email format |
| INVALID_URL | URL format is invalid | Use valid URL format |
| INVALID_UUID | UUID format is invalid | Use valid UUID format |

**Example:**

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Request validation failed",
    "details": {
      "errors": [
        {
          "field": "organizationName",
          "code": "FIELD_TOO_SHORT",
          "message": "Organization name must be at least 2 characters"
        },
        {
          "field": "contactEmail",
          "code": "INVALID_EMAIL",
          "message": "Email format is invalid"
        }
      ]
    }
  },
  "requestId": "req-abc123",
  "timestamp": "2026-01-25T14:30:00Z"
}
```

---

### Authentication Errors (401)

| Code | Description | Resolution |
|------|-------------|------------|
| UNAUTHORIZED | No authentication provided | Include Authorization header |
| TOKEN_EXPIRED | JWT token has expired | Refresh or re-authenticate |
| TOKEN_INVALID | JWT token is malformed | Use valid token format |
| TOKEN_REVOKED | Token has been revoked | Re-authenticate |

**Example:**

```json
{
  "error": {
    "code": "TOKEN_EXPIRED",
    "message": "The access token has expired",
    "details": {
      "expiredAt": "2026-01-25T13:00:00Z"
    }
  },
  "requestId": "req-abc123",
  "timestamp": "2026-01-25T14:30:00Z"
}
```

---

### Authorization Errors (403)

| Code | Description | Resolution |
|------|-------------|------------|
| FORBIDDEN | Insufficient permissions | Request elevated permissions |
| TENANT_ACCESS_DENIED | No access to this tenant | Verify tenant membership |
| ROLE_REQUIRED | Operation requires specific role | Contact admin for role |
| ACCOUNT_SUSPENDED | Account is suspended | Contact support |

**Example:**

```json
{
  "error": {
    "code": "TENANT_ACCESS_DENIED",
    "message": "You do not have access to this tenant",
    "details": {
      "tenantId": "tenant-123",
      "requiredRole": "Admin"
    }
  },
  "requestId": "req-abc123",
  "timestamp": "2026-01-25T14:30:00Z"
}
```

---

### Not Found Errors (404)

| Code | Description | Resolution |
|------|-------------|------------|
| RESOURCE_NOT_FOUND | Resource does not exist | Verify resource ID |
| TENANT_NOT_FOUND | Tenant does not exist | Check tenant ID |
| SITE_NOT_FOUND | Site does not exist | Check site ID |
| INSTANCE_NOT_FOUND | Instance does not exist | Check instance ID |
| USER_NOT_FOUND | User does not exist | Check user ID |
| TEMPLATE_NOT_FOUND | Template does not exist | Check template ID |

**Example:**

```json
{
  "error": {
    "code": "TENANT_NOT_FOUND",
    "message": "Tenant not found",
    "details": {
      "tenantId": "tenant-invalid"
    }
  },
  "requestId": "req-abc123",
  "timestamp": "2026-01-25T14:30:00Z"
}
```

---

### Conflict Errors (409)

| Code | Description | Resolution |
|------|-------------|------------|
| CONFLICT | Resource state conflict | Resolve conflict condition |
| DUPLICATE_RESOURCE | Resource already exists | Use existing or change values |
| ORGANIZATION_EXISTS | Organization name taken | Use different name |
| SUBDOMAIN_TAKEN | Subdomain already in use | Choose different subdomain |
| OPTIMISTIC_LOCK_ERROR | Concurrent modification | Refresh and retry |

**Example:**

```json
{
  "error": {
    "code": "SUBDOMAIN_TAKEN",
    "message": "The subdomain 'blog' is already in use",
    "details": {
      "subdomain": "blog",
      "existingSiteId": "site-456"
    }
  },
  "requestId": "req-abc123",
  "timestamp": "2026-01-25T14:30:00Z"
}
```

---

### Business Logic Errors (422)

| Code | Description | Resolution |
|------|-------------|------------|
| UNPROCESSABLE_ENTITY | Business rule violation | Review business rules |
| INVALID_STATUS_TRANSITION | Invalid state change | Check allowed transitions |
| SCALE_LIMIT_EXCEEDED | Task count out of range | Use 2-10 range |
| QUOTA_EXCEEDED | Resource quota exceeded | Upgrade plan or cleanup |
| OPERATION_IN_PROGRESS | Operation already running | Wait for completion |
| DEPENDENCIES_EXIST | Cannot delete with dependencies | Remove dependencies first |

**Example:**

```json
{
  "error": {
    "code": "INVALID_STATUS_TRANSITION",
    "message": "Cannot park a tenant that is not ACTIVE",
    "details": {
      "currentStatus": "SUSPENDED",
      "requestedTransition": "PARKED",
      "allowedTransitions": ["ACTIVE", "DEPROVISIONED"]
    }
  },
  "requestId": "req-abc123",
  "timestamp": "2026-01-25T14:30:00Z"
}
```

---

### Rate Limiting Errors (429)

| Code | Description | Resolution |
|------|-------------|------------|
| RATE_LIMITED | Too many requests | Wait and retry |
| QUOTA_EXCEEDED_DAILY | Daily quota exceeded | Wait until reset |

**Example:**

```json
{
  "error": {
    "code": "RATE_LIMITED",
    "message": "Rate limit exceeded. Try again in 30 seconds.",
    "details": {
      "limit": 100,
      "window": "1 minute",
      "retryAfter": 30
    }
  },
  "requestId": "req-abc123",
  "timestamp": "2026-01-25T14:30:00Z"
}
```

**Headers included:**

```
Retry-After: 30
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 1737814230
```

---

### Server Errors (500)

| Code | Description | Resolution |
|------|-------------|------------|
| INTERNAL_ERROR | Unexpected server error | Retry with exponential backoff |
| DATABASE_ERROR | Database operation failed | Retry after delay |
| GIT_COMMIT_FAILED | Failed to commit to Git | Contact support |
| WORKFLOW_TRIGGER_FAILED | Failed to trigger workflow | Check GitHub status |
| TERRAFORM_APPLY_FAILED | Infrastructure error | Review error details |

**Example:**

```json
{
  "error": {
    "code": "INTERNAL_ERROR",
    "message": "An unexpected error occurred. Please try again or contact support.",
    "details": {
      "supportReference": "ERR-20260125-ABC123"
    }
  },
  "requestId": "req-abc123",
  "timestamp": "2026-01-25T14:30:00Z"
}
```

---

## Retry Strategies

### Retryable vs Non-Retryable Errors

| Status | Retryable | Strategy |
|--------|-----------|----------|
| 400 | No | Fix request and resend |
| 401 | Maybe | Refresh token, then retry |
| 403 | No | Request permissions |
| 404 | No | Verify resource exists |
| 409 | Maybe | Resolve conflict, then retry |
| 422 | No | Fix business logic issue |
| 429 | Yes | Wait for Retry-After |
| 500 | Yes | Exponential backoff |
| 502 | Yes | Exponential backoff |
| 503 | Yes | Wait for Retry-After |
| 504 | Yes | Exponential backoff |

### Exponential Backoff

For retryable errors, use exponential backoff:

```
delay = min(base_delay * 2^attempt, max_delay)
```

**Recommended values:**

| Parameter | Value |
|-----------|-------|
| Base delay | 1 second |
| Max delay | 60 seconds |
| Max attempts | 3-5 |
| Jitter | +/- 20% |

### Python Retry Example

```python
import requests
import time
import random
from typing import Optional

class APIClient:
    def __init__(
        self,
        base_url: str,
        token: str,
        max_retries: int = 3,
        base_delay: float = 1.0,
        max_delay: float = 60.0
    ):
        self.base_url = base_url.rstrip("/")
        self.headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        }
        self.max_retries = max_retries
        self.base_delay = base_delay
        self.max_delay = max_delay

    def _should_retry(self, status_code: int) -> bool:
        """Determine if request should be retried."""
        return status_code in [429, 500, 502, 503, 504]

    def _get_delay(self, attempt: int, response: Optional[requests.Response] = None) -> float:
        """Calculate delay for retry with jitter."""
        # Check for Retry-After header
        if response and "Retry-After" in response.headers:
            try:
                return float(response.headers["Retry-After"])
            except ValueError:
                pass

        # Exponential backoff with jitter
        delay = min(self.base_delay * (2 ** attempt), self.max_delay)
        jitter = delay * 0.2 * random.random()
        return delay + jitter

    def request(
        self,
        method: str,
        path: str,
        json: dict = None,
        params: dict = None
    ) -> dict:
        """Make HTTP request with retry logic."""
        url = f"{self.base_url}{path}"

        for attempt in range(self.max_retries + 1):
            try:
                response = requests.request(
                    method=method,
                    url=url,
                    headers=self.headers,
                    json=json,
                    params=params
                )

                # Success
                if response.ok:
                    return response.json() if response.text else {}

                # Non-retryable error
                if not self._should_retry(response.status_code):
                    error_data = response.json() if response.text else {}
                    raise APIError(
                        status_code=response.status_code,
                        error_code=error_data.get("error", {}).get("code", "UNKNOWN"),
                        message=error_data.get("error", {}).get("message", "Unknown error"),
                        details=error_data.get("error", {}).get("details"),
                        request_id=error_data.get("requestId")
                    )

                # Retryable error - check if more attempts
                if attempt < self.max_retries:
                    delay = self._get_delay(attempt, response)
                    print(f"Request failed with {response.status_code}. Retrying in {delay:.1f}s...")
                    time.sleep(delay)
                else:
                    # Max retries exceeded
                    error_data = response.json() if response.text else {}
                    raise APIError(
                        status_code=response.status_code,
                        error_code=error_data.get("error", {}).get("code", "UNKNOWN"),
                        message=f"Max retries exceeded: {error_data.get('error', {}).get('message', 'Unknown error')}",
                        details=error_data.get("error", {}).get("details"),
                        request_id=error_data.get("requestId")
                    )

            except requests.exceptions.ConnectionError as e:
                if attempt < self.max_retries:
                    delay = self._get_delay(attempt)
                    print(f"Connection error. Retrying in {delay:.1f}s...")
                    time.sleep(delay)
                else:
                    raise APIError(
                        status_code=0,
                        error_code="CONNECTION_ERROR",
                        message=str(e)
                    )

        raise APIError(status_code=0, error_code="UNKNOWN", message="Request failed")


class APIError(Exception):
    """Custom exception for API errors."""

    def __init__(
        self,
        status_code: int,
        error_code: str,
        message: str,
        details: dict = None,
        request_id: str = None
    ):
        self.status_code = status_code
        self.error_code = error_code
        self.message = message
        self.details = details or {}
        self.request_id = request_id
        super().__init__(f"[{error_code}] {message}")

    def is_retryable(self) -> bool:
        """Check if error is retryable."""
        return self.status_code in [429, 500, 502, 503, 504]


# Usage
client = APIClient(
    base_url="https://api-dev.bigbeardweb.solutions/v1.0",
    token="your-token"
)

try:
    tenants = client.request("GET", "/tenants")
    print(f"Found {len(tenants['items'])} tenants")
except APIError as e:
    print(f"Error: {e.error_code} - {e.message}")
    if e.request_id:
        print(f"Support reference: {e.request_id}")
```

### JavaScript Retry Example

```typescript
interface APIErrorDetails {
  error: {
    code: string;
    message: string;
    details?: Record<string, unknown>;
  };
  requestId?: string;
}

class APIError extends Error {
  statusCode: number;
  errorCode: string;
  details: Record<string, unknown>;
  requestId?: string;

  constructor(
    statusCode: number,
    errorCode: string,
    message: string,
    details: Record<string, unknown> = {},
    requestId?: string
  ) {
    super(`[${errorCode}] ${message}`);
    this.statusCode = statusCode;
    this.errorCode = errorCode;
    this.details = details;
    this.requestId = requestId;
    this.name = 'APIError';
  }

  isRetryable(): boolean {
    return [429, 500, 502, 503, 504].includes(this.statusCode);
  }
}

class APIClient {
  private baseUrl: string;
  private headers: HeadersInit;
  private maxRetries: number;
  private baseDelay: number;
  private maxDelay: number;

  constructor(
    baseUrl: string,
    token: string,
    maxRetries: number = 3,
    baseDelay: number = 1000,
    maxDelay: number = 60000
  ) {
    this.baseUrl = baseUrl.replace(/\/$/, '');
    this.headers = {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    };
    this.maxRetries = maxRetries;
    this.baseDelay = baseDelay;
    this.maxDelay = maxDelay;
  }

  private shouldRetry(statusCode: number): boolean {
    return [429, 500, 502, 503, 504].includes(statusCode);
  }

  private getDelay(attempt: number, retryAfter?: string): number {
    if (retryAfter) {
      const parsed = parseInt(retryAfter, 10);
      if (!isNaN(parsed)) return parsed * 1000;
    }

    const delay = Math.min(this.baseDelay * Math.pow(2, attempt), this.maxDelay);
    const jitter = delay * 0.2 * Math.random();
    return delay + jitter;
  }

  private async sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  async request<T>(
    method: string,
    path: string,
    body?: Record<string, unknown>,
    params?: Record<string, string>
  ): Promise<T> {
    let url = `${this.baseUrl}${path}`;
    if (params) {
      const queryString = new URLSearchParams(params).toString();
      url += `?${queryString}`;
    }

    for (let attempt = 0; attempt <= this.maxRetries; attempt++) {
      try {
        const response = await fetch(url, {
          method,
          headers: this.headers,
          body: body ? JSON.stringify(body) : undefined
        });

        if (response.ok) {
          const text = await response.text();
          return text ? JSON.parse(text) : {} as T;
        }

        if (!this.shouldRetry(response.status)) {
          const errorData: APIErrorDetails = await response.json().catch(() => ({
            error: { code: 'UNKNOWN', message: 'Unknown error' }
          }));

          throw new APIError(
            response.status,
            errorData.error.code,
            errorData.error.message,
            errorData.error.details || {},
            errorData.requestId
          );
        }

        if (attempt < this.maxRetries) {
          const retryAfter = response.headers.get('Retry-After') || undefined;
          const delay = this.getDelay(attempt, retryAfter);
          console.log(`Request failed with ${response.status}. Retrying in ${Math.round(delay / 1000)}s...`);
          await this.sleep(delay);
        } else {
          const errorData: APIErrorDetails = await response.json().catch(() => ({
            error: { code: 'MAX_RETRIES', message: 'Max retries exceeded' }
          }));

          throw new APIError(
            response.status,
            errorData.error.code,
            `Max retries exceeded: ${errorData.error.message}`,
            errorData.error.details || {},
            errorData.requestId
          );
        }
      } catch (e) {
        if (e instanceof APIError) throw e;

        if (attempt < this.maxRetries) {
          const delay = this.getDelay(attempt);
          console.log(`Connection error. Retrying in ${Math.round(delay / 1000)}s...`);
          await this.sleep(delay);
        } else {
          throw new APIError(0, 'CONNECTION_ERROR', String(e));
        }
      }
    }

    throw new APIError(0, 'UNKNOWN', 'Request failed');
  }
}

// Usage
async function main() {
  const client = new APIClient(
    'https://api-dev.bigbeardweb.solutions/v1.0',
    'your-token'
  );

  try {
    const tenants = await client.request<{ items: unknown[] }>('GET', '/tenants');
    console.log(`Found ${tenants.items.length} tenants`);
  } catch (e) {
    if (e instanceof APIError) {
      console.error(`Error: ${e.errorCode} - ${e.message}`);
      if (e.requestId) {
        console.error(`Support reference: ${e.requestId}`);
      }
    } else {
      throw e;
    }
  }
}

main();
```

---

## Error Logging for Support

When reporting issues to support, include:

1. **Request ID** - From error response `requestId`
2. **Timestamp** - When the error occurred
3. **Endpoint** - Full URL that was called
4. **Error Code** - From error response `error.code`
5. **HTTP Status** - Response status code

**Example support request:**

```
Request ID: req-550e8400-e29b-41d4-a716-446655440000
Timestamp: 2026-01-25T14:30:00Z
Endpoint: POST https://api-dev.bigbeardweb.solutions/v1.0/tenants
Error Code: INTERNAL_ERROR
HTTP Status: 500
Description: Tenant creation failed unexpectedly
```

---

## Related Documentation

- [Getting Started](./getting-started.md)
- [Authentication](./authentication.md)
- [Tenant API Guide](./tenant-api-guide.md)
- [Site API Guide](./site-api-guide.md)
- [Instance API Guide](./instance-api-guide.md)

---

**End of Document**
