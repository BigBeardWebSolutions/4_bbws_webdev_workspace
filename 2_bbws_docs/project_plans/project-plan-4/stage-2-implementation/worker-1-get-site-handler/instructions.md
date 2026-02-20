# Worker Instructions: Get Site Handler

**Worker ID**: worker-1-get-site-handler
**Stage**: Stage 2 - Implementation
**Project**: project-plan-4

---

## Task Description

Implement the GET single site handler that retrieves a specific site's details by siteId within a tenant context. This handler returns full site information with HATEOAS links.

**Endpoint**: GET `/v1.0/tenants/{tenantId}/sites/{siteId}`
**LLD Reference**: Section 4.1, US-SITES-003

---

## Inputs

**Pattern Reference**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_wordpress_site_management_lambda/sites-service/src/handlers/sites/create_site_handler.py`

**Service Layer**:
- `SiteLifecycleService.get_site(tenant_id, site_id)` - Already implemented

**Stage 1 Outputs**:
- `stage-1-analysis/worker-1-existing-code-review/output.md`
- `stage-1-analysis/worker-2-gap-analysis/output.md`

**LLD Sections**:
- Section 4.1: Sites API Endpoint Specifications
- Section 3.6.1: SiteService Methods

---

## Deliverables

### 1. Handler File

Create: `/Users/tebogotseka/Documents/agentic_work/2_bbws_wordpress_site_management_lambda/sites-service/src/handlers/sites/get_site_handler.py`

### 2. Response Model (if not exists)

Check/Create in `responses.py`:
```python
class GetSiteResponse(BaseModel):
    site_id: str = Field(..., alias="siteId")
    tenant_id: str = Field(..., alias="tenantId")
    site_name: str = Field(..., alias="siteName")
    subdomain: str
    status: str
    environment: str
    template_id: Optional[str] = Field(None, alias="templateId")
    wp_site_id: Optional[int] = Field(None, alias="wpSiteId")
    wordpress_version: Optional[str] = Field(None, alias="wordpressVersion")
    php_version: Optional[str] = Field(None, alias="phpVersion")
    health_status: Optional[str] = Field(None, alias="healthStatus")
    created_at: datetime = Field(..., alias="createdAt")
    created_by: str = Field(..., alias="createdBy")
    updated_at: datetime = Field(..., alias="updatedAt")
    _links: Dict[str, HATEOASLink]
```

### 3. Update `__init__.py`

Add export for `get_site_handler`

---

## Implementation Specification

### Handler Structure

```python
"""Lambda handler for GET /v1.0/tenants/{tenantId}/sites/{siteId}.

This handler retrieves a single site's details per LLD 2.6 Section 4.1.
Returns 200 OK with full site information and HATEOAS links.

Architecture:
- Uses Lambda Powertools for observability (@logger, @tracer, @metrics)
- Validates path parameters
- Returns 200 OK with site details
- Handles SiteNotFoundException (404)
"""
import os
import json
from datetime import datetime, timezone
from typing import Dict, Any
from aws_lambda_powertools import Logger, Tracer, Metrics
from aws_lambda_powertools.utilities.typing import LambdaContext

from src.domain.services.site_lifecycle_service import SiteLifecycleService
from src.domain.exceptions import (
    BusinessException,
    UnexpectedException,
    ValidationException,
    SiteNotFoundException,
)
from src.domain.models.responses import GetSiteResponse, ErrorResponse, ErrorDetail, HATEOASLink
from src.infrastructure.repositories.dynamodb_site_repository import DynamoDBSiteRepository

# Initialize Lambda Powertools
logger = Logger()
tracer = Tracer()
metrics = Metrics(namespace="BBWS/WPTechnical")

# Initialize dependencies
table_name = os.environ.get("SITES_TABLE", "sites")


def _get_site_lifecycle_service() -> SiteLifecycleService:
    """Get SiteLifecycleService instance."""
    repository = DynamoDBSiteRepository(table_name=table_name)
    return SiteLifecycleService(site_repository=repository)


def _extract_path_parameters(event: Dict[str, Any]) -> tuple[str, str]:
    """Extract tenantId and siteId from path parameters."""
    path_params = event.get("pathParameters") or {}
    tenant_id = path_params.get("tenantId")
    site_id = path_params.get("siteId")

    if not tenant_id:
        raise ValidationException(
            message="Missing tenantId in path parameters",
            details={"pathParameters": path_params}
        )
    if not site_id:
        raise ValidationException(
            message="Missing siteId in path parameters",
            details={"pathParameters": path_params}
        )

    return tenant_id, site_id


def _build_hateoas_links(tenant_id: str, site_id: str) -> Dict[str, HATEOASLink]:
    """Build HATEOAS links for site resource."""
    base_path = f"/v1.0/tenants/{tenant_id}/sites/{site_id}"
    return {
        "self": HATEOASLink(href=base_path),
        "tenant": HATEOASLink(href=f"/v1.0/tenants/{tenant_id}"),
        "plugins": HATEOASLink(href=f"{base_path}/plugins"),
        "health": HATEOASLink(href=f"{base_path}/health")
    }


def _build_success_response(site, tenant_id: str) -> Dict[str, Any]:
    """Build 200 OK success response with site details."""
    # Convert site entity to response model
    # (Implementation depends on Site entity structure)
    ...


def _build_error_response(exception: Exception, request_id: str) -> Dict[str, Any]:
    """Build error response from exception."""
    # Follow pattern from create_site_handler.py
    ...


@logger.inject_lambda_context
@tracer.capture_lambda_handler
@metrics.log_metrics
def handler(event: Dict[str, Any], context: LambdaContext) -> Dict[str, Any]:
    """Lambda handler for GET /v1.0/tenants/{tenantId}/sites/{siteId}."""
    request_id = context.request_id
    logger.append_keys(request_id=request_id)

    try:
        # Extract path parameters
        tenant_id, site_id = _extract_path_parameters(event)

        logger.info(
            "Getting site",
            extra={"tenant_id": tenant_id, "site_id": site_id}
        )

        # Get site via service layer
        service = _get_site_lifecycle_service()
        site = service.get_site(tenant_id=tenant_id, site_id=site_id)

        logger.info(
            "Site retrieved successfully",
            extra={"tenant_id": tenant_id, "site_id": site_id}
        )

        # Record success metric
        metrics.add_metric(name="SiteRetrieved", unit="Count", value=1)

        # Return 200 OK
        return _build_success_response(site, tenant_id)

    except (BusinessException, UnexpectedException) as e:
        logger.warning(
            "Business or expected exception",
            extra={
                "error_code": e.code,
                "error_message": e.message,
                "http_status": e.http_status
            }
        )
        return _build_error_response(e, request_id)

    except Exception as e:
        logger.exception("Unexpected exception in handler", extra={"error": str(e)})
        metrics.add_metric(name="SiteRetrievalFailed", unit="Count", value=1)
        return _build_error_response(e, request_id)
```

### Expected Response (200 OK)

```json
{
  "siteId": "site-550e8400-e29b-41d4-a716-446655440000",
  "tenantId": "tenant-123",
  "siteName": "My Business Site",
  "subdomain": "mybusiness",
  "status": "ACTIVE",
  "environment": "DEV",
  "templateId": "template-uuid",
  "wpSiteId": 2,
  "wordpressVersion": "6.5",
  "phpVersion": "8.2",
  "healthStatus": "HEALTHY",
  "createdAt": "2026-01-05T10:30:00Z",
  "createdBy": "user@example.com",
  "updatedAt": "2026-01-05T14:30:00Z",
  "_links": {
    "self": {"href": "/v1.0/tenants/tenant-123/sites/site-550e8400"},
    "tenant": {"href": "/v1.0/tenants/tenant-123"},
    "plugins": {"href": "/v1.0/tenants/tenant-123/sites/site-550e8400/plugins"},
    "health": {"href": "/v1.0/tenants/tenant-123/sites/site-550e8400/health"}
  }
}
```

### Error Response (404 Not Found)

```json
{
  "error": {
    "code": "SITE_002",
    "message": "Site not found",
    "details": {
      "tenantId": "tenant-123",
      "siteId": "site-nonexistent"
    }
  },
  "requestId": "req-abc123",
  "timestamp": "2026-01-05T10:30:00Z"
}
```

---

## Success Criteria

- [ ] Handler file created at correct path
- [ ] Lambda Powertools decorators applied
- [ ] Path parameters extracted (tenantId, siteId)
- [ ] Service layer called correctly
- [ ] HATEOAS links included in response
- [ ] 200 OK returned on success
- [ ] 404 returned for SiteNotFoundException
- [ ] Error response format matches existing pattern
- [ ] Metrics recorded for success/failure
- [ ] Logging includes correlation keys

---

## Execution Steps

1. Copy structure from `create_site_handler.py` as starting point
2. Modify to extract both `tenantId` and `siteId` from path parameters
3. Call `SiteLifecycleService.get_site(tenant_id, site_id)`
4. Create `GetSiteResponse` model if not exists in `responses.py`
5. Build response with HATEOAS links
6. Handle `SiteNotFoundException` -> 404
7. Test locally with mock event
8. Update `handlers/sites/__init__.py` to export handler
9. Create `output.md` with implementation summary
10. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-23
