# Worker Instructions: List Sites Handler

**Worker ID**: worker-2-list-sites-handler
**Stage**: Stage 2 - Implementation
**Project**: project-plan-4

---

## Task Description

Implement the LIST sites handler that retrieves all sites for a tenant with pagination support. This handler returns a paginated list of sites with HATEOAS links.

**Endpoint**: GET `/v1.0/tenants/{tenantId}/sites`
**LLD Reference**: Section 4.1, US-SITES-004

---

## Inputs

**Pattern Reference**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_wordpress_site_management_lambda/sites-service/src/handlers/sites/create_site_handler.py`

**Service Layer**:
- `SiteLifecycleService.list_sites(tenant_id)` - Already implemented (may need pagination enhancement)

**Stage 1 Outputs**:
- `stage-1-analysis/worker-1-existing-code-review/output.md`
- `stage-1-analysis/worker-2-gap-analysis/output.md`

**LLD Sections**:
- Section 4.1: Sites API Endpoint Specifications
- Section 3.6.1: SiteService Methods

---

## Deliverables

### 1. Handler File

Create: `/Users/tebogotseka/Documents/agentic_work/2_bbws_wordpress_site_management_lambda/sites-service/src/handlers/sites/list_sites_handler.py`

### 2. Request Model (Query Parameters)

Create in `requests.py`:
```python
class ListSitesQueryParams(BaseModel):
    page_size: int = Field(default=20, ge=1, le=100, alias="pageSize")
    start_at: Optional[str] = Field(None, alias="startAt")
    status: Optional[str] = Field(None)  # Optional filter by status
    environment: Optional[str] = Field(None)  # Optional filter by environment
```

### 3. Response Model

Create in `responses.py`:
```python
class SiteSummary(BaseModel):
    """Summary of a site for list responses."""
    site_id: str = Field(..., alias="siteId")
    tenant_id: str = Field(..., alias="tenantId")
    site_name: str = Field(..., alias="siteName")
    subdomain: str
    status: str
    environment: str
    health_status: Optional[str] = Field(None, alias="healthStatus")
    created_at: datetime = Field(..., alias="createdAt")
    updated_at: datetime = Field(..., alias="updatedAt")
    _links: Dict[str, HATEOASLink]

    class Config:
        populate_by_name = True


class ListSitesResponse(BaseModel):
    """Response for LIST sites endpoint."""
    items: List[SiteSummary]
    count: int
    more_available: bool = Field(..., alias="moreAvailable")
    next_token: Optional[str] = Field(None, alias="nextToken")
    _links: Dict[str, HATEOASLink]

    class Config:
        populate_by_name = True
```

### 4. Service Enhancement (if needed)

Check if `SiteLifecycleService.list_sites()` supports pagination. If not, enhance:

```python
def list_sites(
    self,
    tenant_id: str,
    page_size: int = 20,
    start_at: Optional[str] = None,
    status: Optional[str] = None,
    environment: Optional[str] = None
) -> Tuple[List[Site], Optional[str], bool]:
    """List sites for a tenant with pagination.

    Args:
        tenant_id: Tenant identifier
        page_size: Number of items per page (default: 20)
        start_at: Pagination token from previous response
        status: Optional status filter
        environment: Optional environment filter

    Returns:
        Tuple of (sites, next_token, more_available)
    """
    ...
```

### 5. Update `__init__.py`

Add export for `list_sites_handler`

---

## Implementation Specification

### Handler Structure

```python
"""Lambda handler for GET /v1.0/tenants/{tenantId}/sites.

This handler retrieves a paginated list of sites for a tenant per LLD 2.6.
Returns 200 OK with site list, pagination info, and HATEOAS links.

Architecture:
- Uses Lambda Powertools for observability (@logger, @tracer, @metrics)
- Validates path and query parameters
- Supports pagination via pageSize and startAt
- Returns 200 OK with paginated list
"""
import os
import json
from datetime import datetime, timezone
from typing import Dict, Any, Optional, List
from aws_lambda_powertools import Logger, Tracer, Metrics
from aws_lambda_powertools.utilities.typing import LambdaContext

from src.domain.services.site_lifecycle_service import SiteLifecycleService
from src.domain.exceptions import (
    BusinessException,
    UnexpectedException,
    ValidationException,
)
from src.domain.models.requests import ListSitesQueryParams
from src.domain.models.responses import ListSitesResponse, SiteSummary, ErrorResponse, ErrorDetail, HATEOASLink
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


def _extract_tenant_id(event: Dict[str, Any]) -> str:
    """Extract tenantId from path parameters."""
    path_params = event.get("pathParameters") or {}
    tenant_id = path_params.get("tenantId")

    if not tenant_id:
        raise ValidationException(
            message="Missing tenantId in path parameters",
            details={"pathParameters": path_params}
        )

    return tenant_id


def _extract_query_params(event: Dict[str, Any]) -> ListSitesQueryParams:
    """Extract and validate query parameters."""
    query_params = event.get("queryStringParameters") or {}

    try:
        return ListSitesQueryParams(
            pageSize=int(query_params.get("pageSize", 20)),
            startAt=query_params.get("startAt"),
            status=query_params.get("status"),
            environment=query_params.get("environment")
        )
    except ValueError as e:
        raise ValidationException(
            message="Invalid query parameters",
            details={"error": str(e), "queryParameters": query_params}
        )


def _build_site_summary(site, tenant_id: str) -> SiteSummary:
    """Build site summary for list response."""
    site_id = site.site_id.value if hasattr(site.site_id, 'value') else str(site.site_id)
    return SiteSummary(
        siteId=site_id,
        tenantId=tenant_id,
        siteName=site.site_name,
        subdomain=site.site_address.subdomain,
        status=site.status.name,
        environment=site.environment.name,
        healthStatus=site.health_status if hasattr(site, 'health_status') else None,
        createdAt=site.created_at,
        updatedAt=site.updated_at,
        _links={
            "self": HATEOASLink(href=f"/v1.0/tenants/{tenant_id}/sites/{site_id}")
        }
    )


def _build_hateoas_links(tenant_id: str, query_params: ListSitesQueryParams, next_token: Optional[str]) -> Dict[str, HATEOASLink]:
    """Build HATEOAS links for list response."""
    base_path = f"/v1.0/tenants/{tenant_id}/sites"
    links = {
        "self": HATEOASLink(href=f"{base_path}?pageSize={query_params.page_size}"),
        "tenant": HATEOASLink(href=f"/v1.0/tenants/{tenant_id}")
    }

    if next_token:
        links["next"] = HATEOASLink(href=f"{base_path}?pageSize={query_params.page_size}&startAt={next_token}")

    return links


def _build_success_response(
    sites: List,
    tenant_id: str,
    query_params: ListSitesQueryParams,
    next_token: Optional[str],
    more_available: bool
) -> Dict[str, Any]:
    """Build 200 OK success response with site list."""
    site_summaries = [_build_site_summary(site, tenant_id) for site in sites]

    response = ListSitesResponse(
        items=site_summaries,
        count=len(site_summaries),
        moreAvailable=more_available,
        nextToken=next_token,
        _links=_build_hateoas_links(tenant_id, query_params, next_token)
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
    """Lambda handler for GET /v1.0/tenants/{tenantId}/sites."""
    request_id = context.request_id
    logger.append_keys(request_id=request_id)

    try:
        # Extract parameters
        tenant_id = _extract_tenant_id(event)
        query_params = _extract_query_params(event)

        logger.info(
            "Listing sites",
            extra={
                "tenant_id": tenant_id,
                "page_size": query_params.page_size,
                "start_at": query_params.start_at
            }
        )

        # Get sites via service layer
        service = _get_site_lifecycle_service()
        sites = service.list_sites(tenant_id=tenant_id)

        # Apply pagination manually if service doesn't support it
        # TODO: Implement proper pagination in service layer if needed

        logger.info(
            "Sites listed successfully",
            extra={"tenant_id": tenant_id, "count": len(sites)}
        )

        # Record success metric
        metrics.add_metric(name="SitesListed", unit="Count", value=1)

        # Return 200 OK
        return _build_success_response(
            sites=sites,
            tenant_id=tenant_id,
            query_params=query_params,
            next_token=None,  # Implement if pagination added
            more_available=False  # Implement if pagination added
        )

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
        metrics.add_metric(name="SiteListingFailed", unit="Count", value=1)
        return _build_error_response(e, request_id)
```

### Expected Response (200 OK)

```json
{
  "items": [
    {
      "siteId": "site-550e8400-e29b-41d4-a716-446655440000",
      "tenantId": "tenant-123",
      "siteName": "My Business Site",
      "subdomain": "mybusiness",
      "status": "ACTIVE",
      "environment": "DEV",
      "healthStatus": "HEALTHY",
      "createdAt": "2026-01-05T10:30:00Z",
      "updatedAt": "2026-01-05T14:30:00Z",
      "_links": {
        "self": {"href": "/v1.0/tenants/tenant-123/sites/site-550e8400"}
      }
    }
  ],
  "count": 1,
  "moreAvailable": false,
  "nextToken": null,
  "_links": {
    "self": {"href": "/v1.0/tenants/tenant-123/sites?pageSize=20"},
    "tenant": {"href": "/v1.0/tenants/tenant-123"}
  }
}
```

### Query Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| pageSize | int | 20 | Items per page (1-100) |
| startAt | string | null | Pagination token |
| status | string | null | Filter by status (ACTIVE, SUSPENDED, etc.) |
| environment | string | null | Filter by environment (DEV, SIT, PROD) |

---

## Success Criteria

- [ ] Handler file created at correct path
- [ ] Lambda Powertools decorators applied
- [ ] Path parameter extracted (tenantId)
- [ ] Query parameters extracted and validated
- [ ] Service layer called correctly
- [ ] Paginated response structure implemented
- [ ] HATEOAS links included (self, tenant, next)
- [ ] 200 OK returned on success
- [ ] Error response format matches existing pattern
- [ ] Metrics recorded for success/failure

---

## Execution Steps

1. Copy structure from `create_site_handler.py` as starting point
2. Implement query parameter extraction for pagination
3. Create `ListSitesQueryParams` model if not exists
4. Create `ListSitesResponse` and `SiteSummary` models if not exist
5. Call `SiteLifecycleService.list_sites(tenant_id)`
6. Build paginated response with HATEOAS links
7. Implement basic pagination (if needed, can enhance service layer later)
8. Test locally with mock event
9. Update `handlers/sites/__init__.py` to export handler
10. Create `output.md` with implementation summary
11. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-23
