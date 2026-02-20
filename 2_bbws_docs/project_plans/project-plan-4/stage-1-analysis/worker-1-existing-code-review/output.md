# Existing Code Review Output

**Worker**: worker-1-existing-code-review
**Status**: COMPLETE
**Date**: 2026-01-23

---

## 1. Handler Pattern Analysis

### Lambda Powertools Usage

```python
from aws_lambda_powertools import Logger, Tracer, Metrics

logger = Logger()
tracer = Tracer()
metrics = Metrics(namespace="BBWS/WPTechnical")

@logger.inject_lambda_context
@tracer.capture_lambda_handler
@metrics.log_metrics
def handler(event: Dict[str, Any], context: LambdaContext) -> Dict[str, Any]:
```

### Path Parameter Extraction

```python
def _extract_tenant_id(event: Dict[str, Any]) -> str:
    path_params = event.get("pathParameters") or {}
    tenant_id = path_params.get("tenantId")
    if not tenant_id:
        raise ValidationException(
            message="Missing tenantId in path parameters",
            details={"pathParameters": path_params}
        )
    return tenant_id
```

### Request Body Parsing (Pydantic)

```python
def _parse_request_body(event: Dict[str, Any]) -> CreateSiteRequest:
    try:
        body_str = event.get("body", "{}")
        body_dict = json.loads(body_str)
        return CreateSiteRequest(**body_dict)
    except json.JSONDecodeError as e:
        raise ValidationException(message="Malformed JSON", details={"error": str(e)})
    except ValidationError as e:
        raise ValidationException(message="Validation failed", details={"validationErrors": e.errors()})
```

### Service Layer Invocation

```python
def _get_site_lifecycle_service() -> SiteLifecycleService:
    repository = DynamoDBSiteRepository(table_name=table_name)
    return SiteLifecycleService(site_repository=repository)

# In handler:
service = _get_site_lifecycle_service()
site = service.create_site(site_data=site_data)
```

### HATEOAS Response Building

```python
def _build_hateoas_links(tenant_id: str, site_id: str) -> Dict[str, HATEOASLink]:
    base_path = f"/v1.0/tenants/{tenant_id}/sites/{site_id}"
    return {
        "self": HATEOASLink(href=base_path),
        "status": HATEOASLink(href=base_path)
    }

def _build_success_response(site, tenant_id: str) -> Dict[str, Any]:
    response_body = CreateSiteResponse(
        siteId=site.site_id.value,
        tenantId=tenant_id,
        # ... other fields
        _links=_build_hateoas_links(tenant_id, site.site_id.value)
    )
    return {
        "statusCode": 202,
        "headers": {"Content-Type": "application/json"},
        "body": response_body.json(by_alias=True)
    }
```

### Error Response Building

```python
def _build_error_response(exception: Exception, request_id: str) -> Dict[str, Any]:
    if isinstance(exception, BusinessException):
        error_detail = ErrorDetail(
            code=exception.code,
            message=exception.message,
            details=exception.details
        )
        status_code = exception.http_status
    elif isinstance(exception, UnexpectedException):
        error_detail = ErrorDetail(code=exception.code, message=exception.message)
        status_code = exception.http_status
    else:
        error_detail = ErrorDetail(code="SYS_001", message="Internal error occurred")
        status_code = 500

    error_response = ErrorResponse(
        error=error_detail,
        requestId=request_id,
        timestamp=datetime.now(timezone.utc)
    )
    return {
        "statusCode": status_code,
        "headers": {"Content-Type": "application/json"},
        "body": error_response.json(by_alias=True)
    }
```

---

## 2. Service Layer Analysis

### SiteLifecycleService

**Location**: `sites-service/src/domain/services/site_lifecycle_service.py`

**Constructor**:
```python
def __init__(
    self,
    site_repository: SiteRepository,
    max_sites_per_tenant: int = 10
):
    self.site_repository = site_repository
    self.max_sites_per_tenant = max_sites_per_tenant
```

**Available Methods**:

| Method | Signature | Status |
|--------|-----------|--------|
| `create_site` | `(site_data: Dict[str, Any]) -> Site` | EXISTS |
| `get_site` | `(tenant_id: str, site_id: str) -> Site` | EXISTS |
| `list_sites` | `(tenant_id: str) -> List[Site]` | EXISTS (no pagination) |
| `delete_site` | `(tenant_id: str, site_id: str) -> None` | EXISTS (soft delete) |
| `update_site` | `(tenant_id: str, site_id: str, update_data: Dict) -> Site` | **MISSING** |

**Business Rule Validation**:
```python
def _validate_tenant_quota(self, tenant_id: str) -> None:
    current_count = self.site_repository.count_by_tenant(tenant_id)
    if current_count >= self.max_sites_per_tenant:
        raise SiteQuotaExceededException(...)

def _validate_subdomain_unique(self, subdomain: str) -> None:
    if self.site_repository.exists_by_subdomain(subdomain):
        raise SubdomainAlreadyExistsException(subdomain=subdomain)
```

---

## 3. Repository Layer Analysis

### Abstract Base Class (SiteRepository)

**Location**: `sites-service/src/domain/repositories/site_repository.py`

### DynamoDB Implementation

**Location**: `sites-service/src/infrastructure/repositories/dynamodb_site_repository.py`

**Available Methods**:

| Method | Signature | Notes |
|--------|-----------|-------|
| `create` | `async (site: Site) -> Site` | Async, checks uniqueness |
| `get_by_id` | `async (tenant_id: str, site_id: SiteId) -> Optional[Site]` | Uses PK/SK |
| `get_by_address` | `async (tenant_id: str, address: str, env: Environment) -> Optional[Site]` | Uses GSI4 |
| `list_by_tenant` | `async (tenant_id: str, env: Optional, limit: int, next_token: Optional) -> tuple[List[Site], Optional[str]]` | **Has pagination!** |
| `update` | `async (site: Site) -> Site` | Uses conditional write |
| `delete` | `async (tenant_id: str, site_id: SiteId) -> None` | Hard delete |
| `exists` | `async (tenant_id: str, site_id: SiteId) -> bool` | Existence check |

**PK/SK Patterns**:
- PK: `TENANT#{tenant_id}`
- SK: `SITE#{site_id}`
- GSI3PK: `STATUS#{status}` (for status filtering)
- GSI4PK: `SUBDOMAIN#{subdomain}` (for uniqueness)
- GSI5PK: `ENV#{environment}` (for environment filtering)

---

## 4. Model Analysis

### Request Models (`requests.py`)

| Model | Fields | Status |
|-------|--------|--------|
| `CreateSiteRequest` | siteName, subdomain, environment, templateId, plugins, configuration | EXISTS |
| `UpdateSiteRequest` | siteName, configuration | EXISTS |
| `SiteConfiguration` | wordpressVersion, phpVersion | EXISTS |

### Response Models (`responses.py`)

| Model | Fields | Status |
|-------|--------|--------|
| `SiteResponse` | siteId, tenantId, siteName, subdomain, status, environment, _links, etc. | EXISTS |
| `CreateSiteResponse` | siteId, tenantId, siteName, subdomain, status, message, _links | EXISTS |
| `HATEOASLink` | href | EXISTS |
| `ErrorDetail` | code, message, details, suggestion | EXISTS |
| `ErrorResponse` | error, requestId, timestamp | EXISTS |
| `ListSitesResponse` | items, count, moreAvailable, startAt, _links | **MISSING** |

---

## 5. Exception Handling Pattern

### Exception Hierarchy

```
BusinessException (4xx)
├── SiteNotFoundException (404, SITE_002)
├── SubdomainAlreadyExistsException (409, SITE_003)
├── SiteQuotaExceededException (422, SITE_004)
└── ValidationException (400, SITE_001)

UnexpectedException (5xx)
└── Default: SYS_001 (500)

DomainException
└── RepositoryError
    ├── SiteAlreadyExistsError
    ├── SiteNotFoundError
    └── AddressAlreadyInUseError
```

### Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| SITE_001 | 400 | Invalid request / validation error |
| SITE_002 | 404 | Site not found |
| SITE_003 | 409 | Subdomain already exists |
| SITE_004 | 422 | Site quota exceeded |
| SYS_001 | 500 | Internal system error |

---

## 6. Test Pattern Analysis

### Test Structure

```
sites-service/tests/
├── unit/
│   ├── handlers/
│   │   └── test_create_site_handler.py
│   ├── services/
│   └── repositories/
└── integration/
```

### pytest Fixtures Pattern

```python
@pytest.fixture
def mock_site_repository():
    return Mock(spec=SiteRepository)

@pytest.fixture
def site_lifecycle_service(mock_site_repository):
    return SiteLifecycleService(
        site_repository=mock_site_repository,
        max_sites_per_tenant=10
    )
```

### Test Naming Convention

```python
def test_create_site_handler_success():
def test_create_site_handler_returns_202_accepted():
def test_create_site_handler_validation_error_returns_400():
def test_create_site_handler_quota_exceeded_returns_422():
```

### Assertion Pattern

```python
def test_create_site_handler_success(mock_event, mock_context):
    response = handler(mock_event, mock_context)

    assert response["statusCode"] == 202
    body = json.loads(response["body"])
    assert body["siteId"] is not None
    assert body["status"] == "PROVISIONING"
    assert "_links" in body
```

---

## Key Patterns Summary

| Pattern | Implementation |
|---------|----------------|
| Decorators | `@logger.inject_lambda_context`, `@tracer.capture_lambda_handler`, `@metrics.log_metrics` |
| Request Validation | Pydantic models with Field validation |
| Response Format | HATEOAS with `_links` dictionary |
| Error Codes | SITE_001 to SITE_004, SYS_001 |
| Error Response | ErrorResponse with ErrorDetail, requestId, timestamp |
| Test Framework | pytest with fixtures and mocking |
| Repository | Abstract + DynamoDB implementation |
| Service Layer | Business logic with validation methods |

---

## Success Criteria Checklist

- [x] Handler pattern fully documented with code examples
- [x] Service layer methods and patterns documented
- [x] Repository methods inventory complete
- [x] Request/response models documented
- [x] Exception classes and error codes documented
- [x] Test patterns documented for replication
- [x] Key patterns summary table created
