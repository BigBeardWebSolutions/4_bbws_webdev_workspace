# Worker Instructions: Update Site Handler

**Worker ID**: worker-3-update-site-handler
**Stage**: Stage 2 - Implementation
**Project**: project-plan-4

---

## Task Description

Implement the UPDATE site handler that modifies an existing site's configuration. This handler allows updating site name, applying templates, and modifying site settings. Requires implementing a new `update_site()` method in the service layer.

**Endpoint**: PUT `/v1.0/tenants/{tenantId}/sites/{siteId}`
**LLD Reference**: Section 4.1, US-SITES-002

---

## Inputs

**Pattern Reference**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_wordpress_site_management_lambda/sites-service/src/handlers/sites/create_site_handler.py`

**Service Layer**:
- `SiteLifecycleService` - Need to add `update_site()` method

**Stage 1 Outputs**:
- `stage-1-analysis/worker-1-existing-code-review/output.md`
- `stage-1-analysis/worker-2-gap-analysis/output.md`

**LLD Sections**:
- Section 4.1: Sites API Endpoint Specifications
- Section 3.6.1: SiteService Methods
- Section 4.2: Site Status Lifecycle (for valid status transitions)

---

## Deliverables

### 1. Handler File

Create: `/Users/tebogotseka/Documents/agentic_work/2_bbws_wordpress_site_management_lambda/sites-service/src/handlers/sites/update_site_handler.py`

### 2. Request Model

Create in `requests.py`:
```python
class UpdateSiteRequest(BaseModel):
    """Request model for updating a site."""
    site_name: Optional[str] = Field(None, alias="siteName", min_length=1, max_length=100)
    template_id: Optional[str] = Field(None, alias="templateId")
    configuration: Optional[SiteConfiguration] = Field(None)

    class Config:
        populate_by_name = True

    @validator('site_name')
    def validate_site_name(cls, v):
        if v is not None and not v.strip():
            raise ValueError("site_name cannot be empty or whitespace")
        return v
```

### 3. Response Model

Create in `responses.py`:
```python
class UpdateSiteResponse(BaseModel):
    """Response model for site update."""
    site_id: str = Field(..., alias="siteId")
    tenant_id: str = Field(..., alias="tenantId")
    site_name: str = Field(..., alias="siteName")
    subdomain: str
    status: str
    environment: str
    template_id: Optional[str] = Field(None, alias="templateId")
    updated_at: datetime = Field(..., alias="updatedAt")
    message: str
    _links: Dict[str, HATEOASLink]

    class Config:
        populate_by_name = True
```

### 4. Service Layer Enhancement (REQUIRED)

Add to `site_lifecycle_service.py`:

```python
def update_site(
    self,
    tenant_id: str,
    site_id: str,
    update_data: Dict[str, Any]
) -> Site:
    """Update an existing site's configuration.

    This method orchestrates the site update process:
    1. Retrieves the existing site (validates it exists)
    2. Validates the site is in a valid state for updates (ACTIVE)
    3. Updates allowed fields
    4. Persists changes to repository
    5. Returns updated site

    Args:
        tenant_id: Tenant identifier
        site_id: Site identifier
        update_data: Dictionary containing fields to update:
            - site_name (str, optional): New display name
            - template_id (str, optional): New template to apply
            - configuration (Dict, optional): Updated configuration

    Returns:
        Site: The updated site entity

    Raises:
        SiteNotFoundException: If site does not exist
        InvalidStatusTransitionException: If site is not in ACTIVE status
    """
    logger.info(
        "Updating site",
        extra={
            "tenant_id": tenant_id,
            "site_id": site_id,
            "fields": list(update_data.keys())
        }
    )

    # Retrieve existing site (will raise SiteNotFoundException if not found)
    site = self.get_site(tenant_id=tenant_id, site_id=site_id)

    # Validate site can be updated (only ACTIVE sites can be updated)
    if site.status != SiteStatus.ACTIVE:
        raise InvalidStatusTransitionException(
            message=f"Site cannot be updated in {site.status.name} status",
            details={
                "current_status": site.status.name,
                "required_status": "ACTIVE"
            }
        )

    # Update allowed fields
    if "site_name" in update_data and update_data["site_name"]:
        site.site_name = update_data["site_name"]

    if "template_id" in update_data:
        site.template_id = update_data["template_id"]

    if "configuration" in update_data:
        config = update_data["configuration"]
        if config.get("wordpress_version"):
            site.wordpress_version = config["wordpress_version"]
        if config.get("php_version"):
            site.php_version = config["php_version"]

    # Update timestamp
    site.updated_at = datetime.now(timezone.utc)

    # Persist changes
    self.site_repository.save(site)

    logger.info(
        "Site updated successfully",
        extra={
            "tenant_id": tenant_id,
            "site_id": site_id,
            "updated_fields": list(update_data.keys())
        }
    )

    return site
```

### 5. New Exception (if not exists)

Add to `exceptions.py`:
```python
class InvalidStatusTransitionException(BusinessException):
    """Raised when attempting an invalid status transition."""

    def __init__(
        self,
        message: str = "Invalid status transition",
        details: Optional[Dict[str, Any]] = None
    ):
        super().__init__(
            code="SITE_005",
            message=message,
            details=details or {},
            http_status=422
        )
```

### 6. Update `__init__.py`

Add export for `update_site_handler`

---

## Implementation Specification

### Handler Structure

```python
"""Lambda handler for PUT /v1.0/tenants/{tenantId}/sites/{siteId}.

This handler updates an existing site's configuration per LLD 2.6 Section 4.1.
Returns 200 OK with updated site information and HATEOAS links.

Architecture:
- Uses Lambda Powertools for observability (@logger, @tracer, @metrics)
- Validates path parameters and request body
- Only ACTIVE sites can be updated
- Returns 200 OK with updated site details
- Handles SiteNotFoundException (404), InvalidStatusTransitionException (422)
"""
import os
import json
from datetime import datetime, timezone
from typing import Dict, Any
from pydantic import ValidationError
from aws_lambda_powertools import Logger, Tracer, Metrics
from aws_lambda_powertools.utilities.typing import LambdaContext

from src.domain.services.site_lifecycle_service import SiteLifecycleService
from src.domain.exceptions import (
    BusinessException,
    UnexpectedException,
    ValidationException,
    SiteNotFoundException,
    InvalidStatusTransitionException,
)
from src.domain.models.requests import UpdateSiteRequest
from src.domain.models.responses import UpdateSiteResponse, ErrorResponse, ErrorDetail, HATEOASLink
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


def _parse_request_body(event: Dict[str, Any]) -> UpdateSiteRequest:
    """Parse and validate request body with Pydantic."""
    try:
        body_str = event.get("body", "{}")
        body_dict = json.loads(body_str)
        return UpdateSiteRequest(**body_dict)
    except json.JSONDecodeError as e:
        raise ValidationException(
            message="Malformed JSON in request body",
            details={"error": str(e)}
        )
    except ValidationError as e:
        errors = e.errors()
        raise ValidationException(
            message="Request validation failed",
            details={"validationErrors": errors}
        )


def _build_hateoas_links(tenant_id: str, site_id: str) -> Dict[str, HATEOASLink]:
    """Build HATEOAS links for site resource."""
    base_path = f"/v1.0/tenants/{tenant_id}/sites/{site_id}"
    return {
        "self": HATEOASLink(href=base_path),
        "tenant": HATEOASLink(href=f"/v1.0/tenants/{tenant_id}"),
        "plugins": HATEOASLink(href=f"{base_path}/plugins")
    }


def _build_success_response(site, tenant_id: str) -> Dict[str, Any]:
    """Build 200 OK success response with updated site details."""
    site_id = site.site_id.value if hasattr(site.site_id, 'value') else str(site.site_id)

    response = UpdateSiteResponse(
        siteId=site_id,
        tenantId=tenant_id,
        siteName=site.site_name,
        subdomain=site.site_address.subdomain,
        status=site.status.name,
        environment=site.environment.name,
        templateId=site.template_id,
        updatedAt=site.updated_at,
        message="Site updated successfully",
        _links=_build_hateoas_links(tenant_id, site_id)
    )

    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": response.json(by_alias=True)
    }


@logger.inject_lambda_context
@tracer.capture_lambda_handler
@metrics.log_metrics
def handler(event: Dict[str, Any], context: LambdaContext) -> Dict[str, Any]:
    """Lambda handler for PUT /v1.0/tenants/{tenantId}/sites/{siteId}."""
    request_id = context.request_id
    logger.append_keys(request_id=request_id)

    try:
        # Extract and validate inputs
        tenant_id, site_id = _extract_path_parameters(event)
        request = _parse_request_body(event)

        logger.info(
            "Updating site",
            extra={
                "tenant_id": tenant_id,
                "site_id": site_id,
                "update_fields": [f for f in ['site_name', 'template_id', 'configuration'] if getattr(request, f.replace('_', ''), None) is not None]
            }
        )

        # Build update data
        update_data = {}
        if request.site_name:
            update_data["site_name"] = request.site_name
        if request.template_id:
            update_data["template_id"] = request.template_id
        if request.configuration:
            update_data["configuration"] = {
                "wordpress_version": request.configuration.wordpress_version,
                "php_version": request.configuration.php_version
            }

        # Update site via service layer
        service = _get_site_lifecycle_service()
        site = service.update_site(
            tenant_id=tenant_id,
            site_id=site_id,
            update_data=update_data
        )

        logger.info(
            "Site updated successfully",
            extra={"tenant_id": tenant_id, "site_id": site_id}
        )

        # Record success metric
        metrics.add_metric(name="SiteUpdated", unit="Count", value=1)

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
        metrics.add_metric(name="SiteUpdateFailed", unit="Count", value=1)
        return _build_error_response(e, request_id)
```

### Expected Request Body

```json
{
  "siteName": "Updated Business Site",
  "templateId": "template-new-uuid",
  "configuration": {
    "wordpressVersion": "6.6",
    "phpVersion": "8.3"
  }
}
```

### Expected Response (200 OK)

```json
{
  "siteId": "site-550e8400-e29b-41d4-a716-446655440000",
  "tenantId": "tenant-123",
  "siteName": "Updated Business Site",
  "subdomain": "mybusiness",
  "status": "ACTIVE",
  "environment": "DEV",
  "templateId": "template-new-uuid",
  "updatedAt": "2026-01-23T15:30:00Z",
  "message": "Site updated successfully",
  "_links": {
    "self": {"href": "/v1.0/tenants/tenant-123/sites/site-550e8400"},
    "tenant": {"href": "/v1.0/tenants/tenant-123"},
    "plugins": {"href": "/v1.0/tenants/tenant-123/sites/site-550e8400/plugins"}
  }
}
```

### Error Responses

**404 Not Found** (Site not found):
```json
{
  "error": {
    "code": "SITE_002",
    "message": "Site not found",
    "details": {"tenantId": "tenant-123", "siteId": "site-nonexistent"}
  },
  "requestId": "req-abc123",
  "timestamp": "2026-01-23T10:30:00Z"
}
```

**422 Unprocessable Entity** (Invalid status):
```json
{
  "error": {
    "code": "SITE_005",
    "message": "Site cannot be updated in SUSPENDED status",
    "details": {"current_status": "SUSPENDED", "required_status": "ACTIVE"}
  },
  "requestId": "req-abc123",
  "timestamp": "2026-01-23T10:30:00Z"
}
```

---

## Success Criteria

- [ ] Handler file created at correct path
- [ ] Lambda Powertools decorators applied
- [ ] Path parameters extracted (tenantId, siteId)
- [ ] Request body validated with Pydantic
- [ ] `update_site()` method added to SiteLifecycleService
- [ ] Status validation (only ACTIVE sites can be updated)
- [ ] HATEOAS links included in response
- [ ] 200 OK returned on success
- [ ] 404 returned for SiteNotFoundException
- [ ] 422 returned for InvalidStatusTransitionException
- [ ] Error response format matches existing pattern
- [ ] Metrics recorded for success/failure

---

## Execution Steps

1. Add `InvalidStatusTransitionException` to `exceptions.py` if not exists
2. Add `update_site()` method to `SiteLifecycleService`
3. Create `UpdateSiteRequest` model in `requests.py`
4. Create `UpdateSiteResponse` model in `responses.py`
5. Create `update_site_handler.py` following patterns
6. Handle `SiteNotFoundException` -> 404
7. Handle `InvalidStatusTransitionException` -> 422
8. Test locally with mock event
9. Update `handlers/sites/__init__.py` to export handler
10. Create `output.md` with implementation summary
11. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-23
