# Worker Instructions: Delete Site Handler

**Worker ID**: worker-4-delete-site-handler
**Stage**: Stage 2 - Implementation
**Project**: project-plan-4

---

## Task Description

Implement the DELETE site handler that performs a soft delete on an existing site by changing its status to DEPROVISIONING. This triggers async cleanup processes. The actual site record is not removed immediately per LLD BR-SITE-003.

**Endpoint**: DELETE `/v1.0/tenants/{tenantId}/sites/{siteId}`
**LLD Reference**: Section 4.1, US-SITES-005

---

## Inputs

**Pattern Reference**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_wordpress_site_management_lambda/sites-service/src/handlers/sites/create_site_handler.py`

**Service Layer**:
- `SiteLifecycleService.delete_site(tenant_id, site_id)` - Already implemented (soft delete)

**Stage 1 Outputs**:
- `stage-1-analysis/worker-1-existing-code-review/output.md`
- `stage-1-analysis/worker-2-gap-analysis/output.md`

**LLD Sections**:
- Section 4.1: Sites API Endpoint Specifications
- Section 4.2: Site Status Lifecycle (DEPROVISIONING state)
- Section 3.6.1: SiteService Methods

---

## Deliverables

### 1. Handler File

Create: `/Users/tebogotseka/Documents/agentic_work/2_bbws_wordpress_site_management_lambda/sites-service/src/handlers/sites/delete_site_handler.py`

### 2. Response Model (Optional)

For DELETE operations, we have two options per REST standards:
- **204 No Content**: No response body (more RESTful for DELETE)
- **200 OK with body**: Return deletion confirmation with HATEOAS

Recommended: **200 OK** with confirmation message (matches existing patterns)

Create in `responses.py` if needed:
```python
class DeleteSiteResponse(BaseModel):
    """Response model for site deletion."""
    site_id: str = Field(..., alias="siteId")
    tenant_id: str = Field(..., alias="tenantId")
    status: str
    message: str
    deleted_at: datetime = Field(..., alias="deletedAt")
    _links: Dict[str, HATEOASLink]

    class Config:
        populate_by_name = True
```

### 3. Update `__init__.py`

Add export for `delete_site_handler`

---

## Implementation Specification

### Handler Structure

```python
"""Lambda handler for DELETE /v1.0/tenants/{tenantId}/sites/{siteId}.

This handler performs a soft delete on a site per LLD 2.6 Section 4.1.
Changes site status to DEPROVISIONING (BR-SITE-003: soft delete pattern).
Returns 200 OK with deletion confirmation and HATEOAS links.

Architecture:
- Uses Lambda Powertools for observability (@logger, @tracer, @metrics)
- Validates path parameters
- Performs soft delete (status=DEPROVISIONING)
- Returns 200 OK with confirmation
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
from src.domain.models.responses import DeleteSiteResponse, ErrorResponse, ErrorDetail, HATEOASLink
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


def _build_hateoas_links(tenant_id: str) -> Dict[str, HATEOASLink]:
    """Build HATEOAS links for deletion response."""
    return {
        "tenant": HATEOASLink(href=f"/v1.0/tenants/{tenant_id}"),
        "sites": HATEOASLink(href=f"/v1.0/tenants/{tenant_id}/sites")
    }


def _build_success_response(tenant_id: str, site_id: str) -> Dict[str, Any]:
    """Build 200 OK success response for deletion."""
    response = DeleteSiteResponse(
        siteId=site_id,
        tenantId=tenant_id,
        status="DEPROVISIONING",
        message="Site deletion initiated. Site will be fully removed after cleanup completes.",
        deletedAt=datetime.now(timezone.utc),
        _links=_build_hateoas_links(tenant_id)
    )

    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": response.json(by_alias=True)
    }


def _build_no_content_response() -> Dict[str, Any]:
    """Build 204 No Content response (alternative option)."""
    return {
        "statusCode": 204,
        "headers": {"Content-Type": "application/json"},
        "body": ""
    }


def _build_error_response(
    exception: Exception,
    request_id: str
) -> Dict[str, Any]:
    """Build error response from exception."""
    if isinstance(exception, BusinessException):
        error_detail = ErrorDetail(
            code=exception.code,
            message=exception.message,
            details=exception.details
        )
        status_code = exception.http_status
    elif isinstance(exception, UnexpectedException):
        error_detail = ErrorDetail(
            code=exception.code,
            message=exception.message
        )
        status_code = exception.http_status
    else:
        error_detail = ErrorDetail(
            code="SYS_001",
            message="Internal error occurred"
        )
        status_code = 500
        logger.exception("Unexpected exception in handler", extra={"exception": str(exception)})

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


@logger.inject_lambda_context
@tracer.capture_lambda_handler
@metrics.log_metrics
def handler(event: Dict[str, Any], context: LambdaContext) -> Dict[str, Any]:
    """Lambda handler for DELETE /v1.0/tenants/{tenantId}/sites/{siteId}.

    Performs soft delete by changing site status to DEPROVISIONING.
    The actual WordPress site cleanup happens asynchronously via SQS.

    Args:
        event: API Gateway proxy event
        context: Lambda context

    Returns:
        API Gateway proxy response (200 OK or error)
    """
    request_id = context.request_id
    logger.append_keys(request_id=request_id)

    try:
        # Extract path parameters
        tenant_id, site_id = _extract_path_parameters(event)

        logger.info(
            "Deleting site (soft delete)",
            extra={"tenant_id": tenant_id, "site_id": site_id}
        )

        # Delete site via service layer (soft delete)
        service = _get_site_lifecycle_service()
        service.delete_site(tenant_id=tenant_id, site_id=site_id)

        logger.info(
            "Site marked for deletion",
            extra={
                "tenant_id": tenant_id,
                "site_id": site_id,
                "new_status": "DEPROVISIONING"
            }
        )

        # Record success metric
        metrics.add_metric(name="SiteDeleted", unit="Count", value=1)

        # Return 200 OK with confirmation
        return _build_success_response(tenant_id, site_id)

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
        metrics.add_metric(name="SiteDeletionFailed", unit="Count", value=1)
        return _build_error_response(e, request_id)
```

### Expected Response (200 OK)

```json
{
  "siteId": "site-550e8400-e29b-41d4-a716-446655440000",
  "tenantId": "tenant-123",
  "status": "DEPROVISIONING",
  "message": "Site deletion initiated. Site will be fully removed after cleanup completes.",
  "deletedAt": "2026-01-23T16:00:00Z",
  "_links": {
    "tenant": {"href": "/v1.0/tenants/tenant-123"},
    "sites": {"href": "/v1.0/tenants/tenant-123/sites"}
  }
}
```

### Alternative Response (204 No Content)

If using 204 No Content (more RESTful for DELETE):
- Status code: 204
- Body: empty

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
  "timestamp": "2026-01-23T10:30:00Z"
}
```

---

## Business Rules (from LLD)

### BR-SITE-003: Soft Delete Pattern
- Sites are NOT physically deleted immediately
- Status is changed to `DEPROVISIONING`
- Async processes (SQS consumers) handle actual cleanup:
  - Remove WordPress multisite
  - Clean up EFS storage
  - Archive DynamoDB record

### Site Status Lifecycle for Deletion

```
ACTIVE → DEPROVISIONING → DELETED (terminal)
SUSPENDED → DEPROVISIONING → DELETED (terminal)
```

Note: Only ACTIVE or SUSPENDED sites can be deleted. Sites in PROVISIONING or FAILED states should have different handling (not covered in this handler).

---

## Success Criteria

- [ ] Handler file created at correct path
- [ ] Lambda Powertools decorators applied
- [ ] Path parameters extracted (tenantId, siteId)
- [ ] Service layer called correctly (`delete_site`)
- [ ] Soft delete pattern implemented (status=DEPROVISIONING)
- [ ] 200 OK returned on success with confirmation
- [ ] 404 returned for SiteNotFoundException
- [ ] Error response format matches existing pattern
- [ ] Metrics recorded for success/failure
- [ ] HATEOAS links point to tenant and sites list

---

## Execution Steps

1. Review existing `delete_site()` method in `SiteLifecycleService`
2. Verify it performs soft delete (status=DEPROVISIONING)
3. Create `DeleteSiteResponse` model in `responses.py`
4. Create `delete_site_handler.py` following patterns
5. Implement path parameter extraction
6. Call service layer delete method
7. Handle `SiteNotFoundException` -> 404
8. Test locally with mock event
9. Update `handlers/sites/__init__.py` to export handler
10. Create `output.md` with implementation summary
11. Update work.state to COMPLETE

---

## Notes on Authorization

Per LLD Section 10.2, DELETE requires:
- **Admin** role for the tenant

Authorization is handled at API Gateway level via Cognito authorizer, not in this handler. Handler assumes request is already authorized.

---

**Status**: PENDING
**Created**: 2026-01-23
