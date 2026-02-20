# Stage 2: Implementation

**Stage ID**: stage-2-implementation
**Project**: project-plan-4
**Status**: PENDING
**Workers**: 4 (can execute in parallel)

---

## Stage Objective

Implement the 4 missing Lambda handlers for the Sites Service following the established code patterns identified in Stage 1. Each handler follows TDD principles with OOP design.

---

## Stage Workers

| Worker | Task | Endpoint | Status |
|--------|------|----------|--------|
| worker-1-get-site-handler | Implement GET single site | GET /v1.0/tenants/{tenantId}/sites/{siteId} | PENDING |
| worker-2-list-sites-handler | Implement LIST sites with pagination | GET /v1.0/tenants/{tenantId}/sites | PENDING |
| worker-3-update-site-handler | Implement UPDATE site | PUT /v1.0/tenants/{tenantId}/sites/{siteId} | PENDING |
| worker-4-delete-site-handler | Implement DELETE site (soft delete) | DELETE /v1.0/tenants/{tenantId}/sites/{siteId} | PENDING |

---

## Stage Inputs

| Document | Location |
|----------|----------|
| Stage 1 Code Review Output | `stage-1-analysis/worker-1-existing-code-review/output.md` |
| Stage 1 Gap Analysis Output | `stage-1-analysis/worker-2-gap-analysis/output.md` |
| LLD Section 4.1 | Sites API Endpoint Specifications |
| LLD Section 3.6 | Class Specifications |
| Existing create_site_handler.py | Pattern reference |

---

## Stage Outputs

**Handler Files** (in `sites-service/src/handlers/sites/`):
- `get_site_handler.py`
- `list_sites_handler.py`
- `update_site_handler.py`
- `delete_site_handler.py`

**Supporting Files** (if needed):
- Updated `requests.py` with new request models
- Updated `responses.py` with new response models
- Updated `site_lifecycle_service.py` with `update_site()` method
- Updated `__init__.py` exports

---

## Implementation Standards

### Code Quality
- **OOP Principles**: Clean separation of concerns
- **Type Hints**: All functions and parameters
- **Docstrings**: Google-style docstrings for all functions
- **Error Handling**: Business vs System exceptions

### Lambda Powertools
```python
@logger.inject_lambda_context
@tracer.capture_lambda_handler
@metrics.log_metrics
def handler(event: Dict[str, Any], context: LambdaContext) -> Dict[str, Any]:
```

### HATEOAS Response
All responses include `_links` with:
- `self`: Link to current resource
- Related resource links as appropriate

### Error Codes (per LLD Section 12.1)
| Code | HTTP | Description |
|------|------|-------------|
| SITE_001 | 400 | Invalid request |
| SITE_002 | 404 | Site not found |
| SITE_003 | 409 | Subdomain already exists |
| SITE_004 | 422 | Site quota exceeded |
| SITE_005 | 422 | Invalid status transition |
| SYS_001 | 500 | Internal error |

---

## Success Criteria

- [ ] All 4 handlers implemented
- [ ] All handlers follow established patterns from Stage 1
- [ ] Lambda Powertools decorators applied
- [ ] HATEOAS responses implemented
- [ ] Error handling consistent with existing handlers
- [ ] Type hints on all functions
- [ ] Docstrings on all functions
- [ ] Handlers export correctly from `__init__.py`
- [ ] All 4 workers completed
- [ ] Stage summary created

---

## Dependencies

**Depends On**: Stage 1 (Analysis) - Need code patterns and gap analysis

**Blocks**: Stage 3 (Testing)

---

## Parallel Execution Notes

Workers in this stage CAN execute in parallel because:
- Each handler is independent
- They use existing service/repository methods
- Only worker-3 (update) requires a new service method

**Recommended Order** (if sequential):
1. GET Site (simplest, validates patterns)
2. DELETE Site (uses existing service method)
3. LIST Sites (adds pagination)
4. UPDATE Site (requires new service method)

---

**Created**: 2026-01-23
