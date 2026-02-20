# Worker Output: LIST Sites Handler

**Worker**: worker-2-list-sites-handler
**Status**: COMPLETE
**Date**: 2026-01-23

---

## Deliverables

### 1. Response Model Added

**File**: `sites-service/src/domain/models/responses.py`

**Model**: `ListSitesResponse`
- items: List[SiteResponse]
- count: int
- moreAvailable: bool
- nextToken: Optional[str]
- _links: HATEOAS links

### 2. Handler Created

**File**: `sites-service/src/handlers/sites/list_sites_handler.py`

**Endpoint**: `GET /v1.0/tenants/{tenantId}/sites`

**Query Parameters**:
- `pageSize` (default: 20, max: 100)
- `startAt` (pagination token)

**Features**:
- Lambda Powertools decorators (@logger, @tracer, @metrics)
- Query parameter extraction for pagination
- Calls `SiteLifecycleService.list_sites()`
- Client-side pagination (until service is updated)
- HATEOAS response with _links (self, create, next)
- Metrics: SitesListed, SitesCount, SitesListFailed

**Response**: 200 OK with ListSitesResponse

---

## Code Summary

```python
@logger.inject_lambda_context
@tracer.capture_lambda_handler
@metrics.log_metrics
def handler(event: Dict[str, Any], context: LambdaContext) -> Dict[str, Any]:
    tenant_id = _extract_tenant_id(event)
    page_size, start_at = _extract_pagination_params(event)

    service = _get_site_lifecycle_service()
    sites = service.list_sites(tenant_id=tenant_id)

    # Pagination applied client-side for now
    paginated_sites = sites[start_index:start_index + page_size]
    more_available = len(sites) > start_index + page_size

    return _build_success_response(paginated_sites, tenant_id, page_size, more_available, next_token)
```

---

## Verification

- [x] Syntax validation passed
- [x] ListSitesResponse model created
- [x] Pagination parameters supported
- [x] HATEOAS links with "next" when more pages available
- [x] Error handling implemented
