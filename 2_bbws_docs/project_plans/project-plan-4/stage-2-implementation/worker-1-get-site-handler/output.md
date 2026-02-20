# Worker Output: GET Site Handler

**Worker**: worker-1-get-site-handler
**Status**: COMPLETE
**Date**: 2026-01-23

---

## Deliverables

### Handler Created

**File**: `sites-service/src/handlers/sites/get_site_handler.py`

**Endpoint**: `GET /v1.0/tenants/{tenantId}/sites/{siteId}`

**Features**:
- Lambda Powertools decorators (@logger, @tracer, @metrics)
- Path parameter extraction (tenantId, siteId)
- Calls `SiteLifecycleService.get_site()`
- HATEOAS response with _links (self, update, delete, list)
- Error handling for SiteNotFoundException (404)
- Metrics: SiteRetrieved, SiteNotFound, SiteRetrievalFailed

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

    service = _get_site_lifecycle_service()
    site = service.get_site(tenant_id=tenant_id, site_id=site_id)

    return _build_success_response(site, tenant_id)  # 200 OK
```

---

## Verification

- [x] Syntax validation passed
- [x] Follows existing handler patterns
- [x] Uses existing service method
- [x] HATEOAS links included
- [x] Error handling implemented
