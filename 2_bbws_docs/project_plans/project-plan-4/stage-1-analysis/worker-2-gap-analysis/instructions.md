# Worker Instructions: Gap Analysis

**Worker ID**: worker-2-gap-analysis
**Stage**: Stage 1 - Analysis
**Project**: project-plan-4

---

## Task Description

Analyze the LLD requirements against the existing codebase to identify gaps. Document what's missing for each of the 4 required handlers (GET site, LIST sites, UPDATE site, DELETE site) including handler code, service methods, repository methods, models, and tests.

---

## Inputs

**LLD Reference**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/2.6_LLD_WordPress_Site_Management.md`
  - Section 4.1: Sites API Endpoint Specifications
  - Section 4.3: Create Site Flow (for pattern reference)
  - Section 8.3: Site Schema (DynamoDB)
  - Section 3.6: Class Specifications (SiteService methods)

**Existing Codebase**:
- Sites Service handlers directory: `sites-service/src/handlers/sites/`
- Service layer: `sites-service/src/domain/services/site_lifecycle_service.py`
- Repository layer: `sites-service/src/infrastructure/repositories/dynamodb_site_repository.py`
- Models: `sites-service/src/domain/models/`
- Tests: `sites-service/tests/unit/handlers/`

**Code Review Output**:
- `worker-1-existing-code-review/output.md` (from Worker 1)

---

## Deliverables

Create `output.md` with the following sections:

### 1. Handler Gap Analysis

For each missing handler, document:

#### 1.1 GET /v1.0/tenants/{tenantId}/sites/{siteId}
- **Handler File**: `get_site_handler.py` - MISSING
- **LLD Reference**: Section 4.1, US-SITES-003
- **Service Method**: `get_site(tenant_id, site_id)` - EXISTS in SiteLifecycleService
- **Repository Method**: `get(tenant_id, site_id)` - EXISTS
- **Response Model**: Need `GetSiteResponse` - CHECK IF EXISTS
- **Error Codes**: SITE_002 (Site not found) - EXISTS

#### 1.2 GET /v1.0/tenants/{tenantId}/sites (List with Pagination)
- **Handler File**: `list_sites_handler.py` - MISSING
- **LLD Reference**: Section 4.1, US-SITES-004
- **Service Method**: `list_sites(tenant_id, page_size, start_at)` - PARTIAL (pagination missing)
- **Repository Method**: `list_by_tenant(tenant_id, page_size, start_at)` - CHECK IF SUPPORTS PAGINATION
- **Response Model**: Need `ListSitesResponse` with pagination - CHECK IF EXISTS
- **Query Parameters**: `pageSize`, `startAt` - Need to handle

#### 1.3 PUT /v1.0/tenants/{tenantId}/sites/{siteId}
- **Handler File**: `update_site_handler.py` - MISSING
- **LLD Reference**: Section 4.1, US-SITES-002
- **Service Method**: `update_site(tenant_id, site_id, update_data)` - MISSING
- **Repository Method**: `save(site)` - EXISTS (can be used for update)
- **Request Model**: Need `UpdateSiteRequest` - CHECK IF EXISTS
- **Response Model**: Need `UpdateSiteResponse` - CHECK IF EXISTS
- **Error Codes**: SITE_002 (Site not found) - EXISTS

#### 1.4 DELETE /v1.0/tenants/{tenantId}/sites/{siteId}
- **Handler File**: `delete_site_handler.py` - MISSING
- **LLD Reference**: Section 4.1, US-SITES-005
- **Service Method**: `delete_site(tenant_id, site_id)` - EXISTS (soft delete)
- **Repository Method**: `save(site)` - EXISTS (for status update)
- **Response Model**: 204 No Content or 200 OK - CHECK LLD
- **Error Codes**: SITE_002 (Site not found) - EXISTS

### 2. Service Layer Gaps

Document missing methods:
- `update_site(tenant_id, site_id, update_data)` - Need to implement
- `list_sites` with pagination support - May need enhancement

### 3. Repository Layer Gaps

Verify if existing methods support:
- Pagination for `list_by_tenant()`
- Update operations via `save()`

### 4. Model Gaps

List missing Pydantic models:
- Request models: `UpdateSiteRequest`, `ListSitesQueryParams`
- Response models: `GetSiteResponse`, `ListSitesResponse`, `UpdateSiteResponse`
- Check if any are already defined in `requests.py` / `responses.py`

### 5. Test Gaps

List missing test files:
- `test_get_site_handler.py`
- `test_list_sites_handler.py`
- `test_update_site_handler.py`
- `test_delete_site_handler.py`

### 6. Implementation Checklist

Create detailed checklist for Stage 2:

```markdown
## GET Site Handler Checklist
- [ ] Create `get_site_handler.py`
- [ ] Implement path parameter extraction (tenantId, siteId)
- [ ] Call `SiteLifecycleService.get_site()`
- [ ] Build HATEOAS response with _links
- [ ] Handle `SiteNotFoundException` -> 404

## LIST Sites Handler Checklist
- [ ] Create `list_sites_handler.py`
- [ ] Implement query parameter extraction (pageSize, startAt)
- [ ] Enhance `SiteLifecycleService.list_sites()` for pagination (if needed)
- [ ] Build paginated response with moreAvailable flag
- [ ] Add HATEOAS links

(Continue for UPDATE and DELETE...)
```

---

## Expected Output Format

```markdown
# Gap Analysis Output

## 1. Handler Gap Analysis

### 1.1 GET Site Handler
| Component | Status | Notes |
|-----------|--------|-------|
| Handler file | MISSING | Create `get_site_handler.py` |
| Service method | EXISTS | `get_site(tenant_id, site_id)` |
| Repository method | EXISTS | `get(tenant_id, site_id)` |
| Response model | CHECK | Verify `GetSiteResponse` |
| Error handling | EXISTS | `SiteNotFoundException` |

### 1.2 LIST Sites Handler
| Component | Status | Notes |
|-----------|--------|-------|
| Handler file | MISSING | Create `list_sites_handler.py` |
| Service method | PARTIAL | `list_sites()` needs pagination |
| Repository method | CHECK | Verify pagination support |
| Response model | CHECK | Need `ListSitesResponse` |
| Query params | MISSING | Handle pageSize, startAt |

(Continue for UPDATE and DELETE...)

## 2. Service Layer Gaps
...

## 3. Repository Layer Gaps
...

## 4. Model Gaps
...

## 5. Test Gaps
...

## 6. Implementation Checklist

### Handler Implementation Order (Recommended)
1. GET Site (simplest, validates service/repo work)
2. LIST Sites (adds pagination complexity)
3. DELETE Site (uses existing delete_site service method)
4. UPDATE Site (requires new service method)

### Detailed Checklists
(Detailed checklists for each handler...)
```

---

## Success Criteria

- [ ] All 4 missing handlers documented with component status
- [ ] Service layer gaps identified
- [ ] Repository layer gaps verified
- [ ] Model gaps documented
- [ ] Test gaps documented
- [ ] Implementation checklists created for Stage 2
- [ ] Recommended implementation order provided

---

## Execution Steps

1. Read LLD Section 4.1 for endpoint specifications
2. Read LLD Section 3.6 for class method specifications
3. Inventory existing handler files in `sites-service/src/handlers/sites/`
4. Check `site_lifecycle_service.py` for existing methods
5. Check `dynamodb_site_repository.py` for existing methods
6. Check `requests.py` and `responses.py` for existing models
7. Check `tests/unit/handlers/` for existing tests
8. Document all gaps in output.md
9. Create implementation checklists
10. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-23
