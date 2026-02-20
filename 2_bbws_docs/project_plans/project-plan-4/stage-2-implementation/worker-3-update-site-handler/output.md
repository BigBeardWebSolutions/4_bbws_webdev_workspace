# Worker Output: UPDATE Site Handler

**Worker**: worker-3-update-site-handler
**Status**: COMPLETE
**Date**: 2026-01-23

---

## Deliverables

### 1. Service Method Added

**File**: `sites-service/src/domain/services/site_lifecycle_service.py`

**Method**: `update_site(tenant_id, site_id, update_data)`
- Updates site_name if provided
- Updates wordpress_version if in configuration
- Updates php_version if in configuration
- Sets updated_at timestamp
- Raises SiteNotFoundException if not found

### 2. Handler Created

**File**: `sites-service/src/handlers/sites/update_site_handler.py`

**Endpoint**: `PUT /v1.0/tenants/{tenantId}/sites/{siteId}`

**Request Body** (UpdateSiteRequest):
- siteName (optional)
- configuration (optional): { wordpressVersion, phpVersion }

**Features**:
- Lambda Powertools decorators (@logger, @tracer, @metrics)
- Path parameter extraction (tenantId, siteId)
- Request body parsing with Pydantic validation
- Calls `SiteLifecycleService.update_site()`
- HATEOAS response with _links
- Error handling for SiteNotFoundException (404), ValidationException (400)
- Metrics: SiteUpdated, SiteUpdateNotFound, SiteUpdateFailed

**Response**: 200 OK with SiteResponse

---

## Code Summary

```python
@logger.inject_lambda_context
@tracer.capture_lambda_handler
@metrics.log_metrics
def handler(event: Dict[str, Any], context: LambdaContext) -> Dict[str, Any]:
    tenant_id = _extract_tenant_id(event)
    site_id = _extract_site_id(event)
    request = _parse_request_body(event)  # UpdateSiteRequest

    update_data = {}
    if request.site_name:
        update_data["site_name"] = request.site_name
    if request.configuration:
        update_data["configuration"] = {...}

    service = _get_site_lifecycle_service()
    site = service.update_site(tenant_id, site_id, update_data)

    return _build_success_response(site, tenant_id)  # 200 OK
```

---

## Verification

- [x] Syntax validation passed
- [x] Service method `update_site` added
- [x] Uses existing UpdateSiteRequest model
- [x] Partial updates supported
- [x] HATEOAS links included
- [x] Error handling implemented
