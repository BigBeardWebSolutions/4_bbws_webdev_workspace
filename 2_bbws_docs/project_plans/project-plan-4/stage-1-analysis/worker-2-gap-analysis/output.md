# Gap Analysis Output

**Worker**: worker-2-gap-analysis
**Status**: COMPLETE
**Date**: 2026-01-23

---

## 1. Handler Gap Analysis

### 1.1 GET Site Handler

| Component | Status | Notes |
|-----------|--------|-------|
| Handler file | **MISSING** | Create `get_site_handler.py` |
| Service method | EXISTS | `get_site(tenant_id, site_id)` in SiteLifecycleService |
| Repository method | EXISTS | `get_by_id(tenant_id, site_id)` in DynamoDBSiteRepository |
| Response model | EXISTS | Use `SiteResponse` from responses.py |
| Error handling | EXISTS | `SiteNotFoundException` (SITE_002, 404) |

**Implementation Complexity**: LOW - Service and repository methods exist

---

### 1.2 LIST Sites Handler

| Component | Status | Notes |
|-----------|--------|-------|
| Handler file | **MISSING** | Create `list_sites_handler.py` |
| Service method | EXISTS | `list_sites(tenant_id)` - BUT NO PAGINATION |
| Repository method | EXISTS | `list_by_tenant(tenant_id, env, limit, next_token)` - HAS PAGINATION |
| Response model | **MISSING** | Need `ListSitesResponse` with pagination fields |
| Query params | **MISSING** | Need to handle `pageSize`, `startAt` query parameters |

**Implementation Complexity**: MEDIUM - Need to:
1. Update service method to accept pagination params
2. Create `ListSitesResponse` model
3. Extract query parameters in handler

---

### 1.3 UPDATE Site Handler

| Component | Status | Notes |
|-----------|--------|-------|
| Handler file | **MISSING** | Create `update_site_handler.py` |
| Service method | **MISSING** | Need `update_site(tenant_id, site_id, update_data)` |
| Repository method | EXISTS | `update(site)` in DynamoDBSiteRepository |
| Request model | EXISTS | `UpdateSiteRequest` in requests.py |
| Response model | EXISTS | Use `SiteResponse` from responses.py |
| Error handling | EXISTS | `SiteNotFoundException` (SITE_002, 404) |

**Implementation Complexity**: MEDIUM - Need to:
1. Create `update_site` service method
2. Create handler with request body parsing

---

### 1.4 DELETE Site Handler

| Component | Status | Notes |
|-----------|--------|-------|
| Handler file | **MISSING** | Create `delete_site_handler.py` |
| Service method | EXISTS | `delete_site(tenant_id, site_id)` - Soft delete (DEPROVISIONING) |
| Repository method | EXISTS | Uses `save(site)` for status update |
| Response model | N/A | Return 204 No Content |
| Error handling | EXISTS | `SiteNotFoundException` (SITE_002, 404) |

**Implementation Complexity**: LOW - Service method exists, just need handler

---

## 2. Service Layer Gaps

### Methods Status

| Method | Exists | Needs Update |
|--------|--------|--------------|
| `create_site` | YES | No |
| `get_site` | YES | No |
| `list_sites` | YES | **YES - Add pagination params** |
| `delete_site` | YES | No |
| `update_site` | **NO** | **NEEDS CREATION** |

### Required Changes

#### 2.1 Add `update_site` Method

```python
def update_site(self, tenant_id: str, site_id: str, update_data: Dict[str, Any]) -> Site:
    """Update an existing site.

    Args:
        tenant_id: Tenant identifier
        site_id: Site identifier
        update_data: Dictionary containing fields to update:
            - site_name (str, optional): New display name
            - configuration (Dict, optional): WordPress/PHP configuration

    Returns:
        Site: The updated site entity

    Raises:
        SiteNotFoundException: If site does not exist
    """
    # Retrieve existing site
    site = self.get_site(tenant_id=tenant_id, site_id=site_id)

    # Update fields if provided
    if "site_name" in update_data and update_data["site_name"]:
        site.site_name = update_data["site_name"]

    if "configuration" in update_data:
        config = update_data["configuration"]
        if config.get("wordpress_version"):
            site.wordpress_version = config["wordpress_version"]
        if config.get("php_version"):
            site.php_version = config["php_version"]

    site.updated_at = datetime.now(timezone.utc)

    # Persist changes
    self.site_repository.save(site)

    return site
```

#### 2.2 Update `list_sites` for Pagination

```python
def list_sites(
    self,
    tenant_id: str,
    page_size: int = 20,
    start_at: Optional[str] = None
) -> Tuple[List[Site], bool, Optional[str]]:
    """List all sites for a tenant with pagination.

    Args:
        tenant_id: Tenant identifier
        page_size: Number of sites per page (default: 20)
        start_at: Pagination token for next page

    Returns:
        Tuple of (sites, more_available, next_token)
    """
    sites, next_token = self.site_repository.list_by_tenant(
        tenant_id=tenant_id,
        limit=page_size,
        next_token=start_at
    )

    more_available = next_token is not None

    return sites, more_available, next_token
```

---

## 3. Repository Layer Gaps

### Methods Status

| Method | Exists | Supports Pagination |
|--------|--------|---------------------|
| `create` | YES | N/A |
| `get_by_id` | YES | N/A |
| `get_by_address` | YES | N/A |
| `list_by_tenant` | YES | **YES** - `limit`, `next_token` params |
| `update` | YES | N/A |
| `delete` | YES | N/A |
| `exists` | YES | N/A |

**GOOD NEWS**: Repository already supports pagination! No changes needed.

---

## 4. Model Gaps

### Request Models Status

| Model | Exists | Notes |
|-------|--------|-------|
| `CreateSiteRequest` | YES | Complete |
| `UpdateSiteRequest` | YES | Complete (siteName, configuration) |
| `SiteConfiguration` | YES | Complete |

### Response Models Status

| Model | Exists | Notes |
|-------|--------|-------|
| `SiteResponse` | YES | Complete - Use for GET single site |
| `CreateSiteResponse` | YES | Complete |
| `ErrorResponse` | YES | Complete |
| `HATEOASLink` | YES | Complete |
| `ListSitesResponse` | **MISSING** | **NEEDS CREATION** |

### Required: ListSitesResponse

```python
class ListSitesResponse(BaseModel):
    """Response model for GET /v1.0/tenants/{tenantId}/sites.

    Attributes:
        items: List of sites
        count: Number of sites in current page
        more_available: Whether more pages exist
        next_token: Token for next page (if more_available)
        links: HATEOAS links
    """

    items: List[SiteResponse] = Field(..., description="List of sites")
    count: int = Field(..., description="Number of sites in this page")
    more_available: bool = Field(
        ...,
        alias="moreAvailable",
        description="Whether more pages exist"
    )
    next_token: Optional[str] = Field(
        None,
        alias="nextToken",
        description="Pagination token for next page"
    )
    links: Dict[str, HATEOASLink] = Field(..., alias="_links", description="HATEOAS links")

    class Config:
        populate_by_name = True
```

---

## 5. Test Gaps

### Missing Test Files

| Test File | Handler | Priority |
|-----------|---------|----------|
| `test_get_site_handler.py` | get_site_handler.py | HIGH |
| `test_list_sites_handler.py` | list_sites_handler.py | HIGH |
| `test_update_site_handler.py` | update_site_handler.py | HIGH |
| `test_delete_site_handler.py` | delete_site_handler.py | HIGH |

### Test Scenarios per Handler

**GET Site Handler Tests:**
- `test_get_site_success` - Returns 200 with site data
- `test_get_site_not_found_returns_404` - SiteNotFoundException
- `test_get_site_missing_tenant_id_returns_400` - ValidationException
- `test_get_site_missing_site_id_returns_400` - ValidationException
- `test_get_site_includes_hateoas_links` - Verify _links

**LIST Sites Handler Tests:**
- `test_list_sites_success` - Returns 200 with array
- `test_list_sites_empty_returns_empty_array` - No sites case
- `test_list_sites_pagination_first_page` - First page with moreAvailable=true
- `test_list_sites_pagination_last_page` - Last page with moreAvailable=false
- `test_list_sites_respects_page_size` - pageSize query param
- `test_list_sites_uses_start_at_token` - startAt query param

**UPDATE Site Handler Tests:**
- `test_update_site_success` - Returns 200 with updated site
- `test_update_site_not_found_returns_404` - SiteNotFoundException
- `test_update_site_name_only` - Partial update
- `test_update_site_configuration_only` - Partial update
- `test_update_site_invalid_request_returns_400` - Validation error

**DELETE Site Handler Tests:**
- `test_delete_site_success_returns_204` - Soft delete success
- `test_delete_site_not_found_returns_404` - SiteNotFoundException
- `test_delete_site_sets_deprovisioning_status` - Verify soft delete

---

## 6. Implementation Checklist

### Recommended Implementation Order

1. **GET Site Handler** (simplest, validates patterns work)
2. **DELETE Site Handler** (service method exists, simple 204 response)
3. **LIST Sites Handler** (needs response model and pagination)
4. **UPDATE Site Handler** (needs new service method)

---

### GET Site Handler Checklist

- [ ] Create `sites-service/src/handlers/sites/get_site_handler.py`
- [ ] Implement `_extract_tenant_id(event)` helper
- [ ] Implement `_extract_site_id(event)` helper
- [ ] Call `SiteLifecycleService.get_site(tenant_id, site_id)`
- [ ] Build HATEOAS response with `_links`
- [ ] Handle `SiteNotFoundException` → 404
- [ ] Add Lambda Powertools decorators
- [ ] Create `test_get_site_handler.py` with 5+ tests
- [ ] Update `__init__.py` to export handler

---

### DELETE Site Handler Checklist

- [ ] Create `sites-service/src/handlers/sites/delete_site_handler.py`
- [ ] Implement path parameter extraction (tenantId, siteId)
- [ ] Call `SiteLifecycleService.delete_site(tenant_id, site_id)`
- [ ] Return 204 No Content on success
- [ ] Handle `SiteNotFoundException` → 404
- [ ] Add Lambda Powertools decorators
- [ ] Create `test_delete_site_handler.py` with 3+ tests
- [ ] Update `__init__.py` to export handler

---

### LIST Sites Handler Checklist

- [ ] Create `ListSitesResponse` in `responses.py`
- [ ] Update `SiteLifecycleService.list_sites()` for pagination (or create new method)
- [ ] Create `sites-service/src/handlers/sites/list_sites_handler.py`
- [ ] Implement `_extract_query_params(event)` for pageSize, startAt
- [ ] Call service method with pagination params
- [ ] Build paginated HATEOAS response
- [ ] Add Lambda Powertools decorators
- [ ] Create `test_list_sites_handler.py` with 6+ tests
- [ ] Update `__init__.py` to export handler

---

### UPDATE Site Handler Checklist

- [ ] Create `update_site()` method in `SiteLifecycleService`
- [ ] Create `sites-service/src/handlers/sites/update_site_handler.py`
- [ ] Implement path parameter extraction (tenantId, siteId)
- [ ] Parse request body with `UpdateSiteRequest`
- [ ] Call `SiteLifecycleService.update_site(tenant_id, site_id, update_data)`
- [ ] Build HATEOAS response with `SiteResponse`
- [ ] Handle `SiteNotFoundException` → 404
- [ ] Handle validation errors → 400
- [ ] Add Lambda Powertools decorators
- [ ] Create `test_update_site_handler.py` with 5+ tests
- [ ] Update `__init__.py` to export handler

---

## Summary of Gaps

| Category | Items Missing | Effort |
|----------|---------------|--------|
| Handlers | 4 | HIGH |
| Service Methods | 1 (update_site) | MEDIUM |
| Service Updates | 1 (list_sites pagination) | LOW |
| Response Models | 1 (ListSitesResponse) | LOW |
| Test Files | 4 | MEDIUM |

**Total Estimated Effort**: 4-6 hours

---

## Success Criteria Checklist

- [x] All 4 missing handlers documented with component status
- [x] Service layer gaps identified (update_site missing, list_sites needs pagination)
- [x] Repository layer verified (pagination already supported!)
- [x] Model gaps documented (ListSitesResponse missing)
- [x] Test gaps documented (4 test files needed)
- [x] Implementation checklists created for Stage 2
- [x] Recommended implementation order provided
