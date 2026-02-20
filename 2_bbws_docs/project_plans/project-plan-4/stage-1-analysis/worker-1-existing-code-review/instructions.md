# Worker Instructions: Existing Code Review

**Worker ID**: worker-1-existing-code-review
**Stage**: Stage 1 - Analysis
**Project**: project-plan-4

---

## Task Description

Review the existing WordPress Site Management Lambda codebase to understand and document established patterns for handlers, services, repositories, models, and tests. This analysis will guide the implementation of the 4 missing handlers.

---

## Inputs

**Primary Files to Analyze**:

1. **Handler Pattern Reference**:
   - `/Users/tebogotseka/Documents/agentic_work/2_bbws_wordpress_site_management_lambda/sites-service/src/handlers/sites/create_site_handler.py`
   - `/Users/tebogotseka/Documents/agentic_work/2_bbws_wordpress_site_management_lambda/sites-service/src/handlers/sites/apply_template_handler.py`

2. **Service Layer**:
   - `/Users/tebogotseka/Documents/agentic_work/2_bbws_wordpress_site_management_lambda/sites-service/src/domain/services/site_lifecycle_service.py`

3. **Repository Layer**:
   - `/Users/tebogotseka/Documents/agentic_work/2_bbws_wordpress_site_management_lambda/sites-service/src/domain/repositories/site_repository.py`
   - `/Users/tebogotseka/Documents/agentic_work/2_bbws_wordpress_site_management_lambda/sites-service/src/infrastructure/repositories/dynamodb_site_repository.py`

4. **Domain Models**:
   - `/Users/tebogotseka/Documents/agentic_work/2_bbws_wordpress_site_management_lambda/sites-service/src/domain/models/requests.py`
   - `/Users/tebogotseka/Documents/agentic_work/2_bbws_wordpress_site_management_lambda/sites-service/src/domain/models/responses.py`

5. **Domain Entities**:
   - `/Users/tebogotseka/Documents/agentic_work/2_bbws_wordpress_site_management_lambda/sites-service/src/domain/entities/site.py`

6. **Exceptions**:
   - `/Users/tebogotseka/Documents/agentic_work/2_bbws_wordpress_site_management_lambda/sites-service/src/domain/exceptions.py`

7. **Test Patterns**:
   - `/Users/tebogotseka/Documents/agentic_work/2_bbws_wordpress_site_management_lambda/sites-service/tests/unit/handlers/test_create_site_handler.py`

**Reference LLD**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/2.6_LLD_WordPress_Site_Management.md`

---

## Deliverables

Create `output.md` with the following sections:

### 1. Handler Pattern Analysis

Document the handler implementation pattern including:
- Lambda Powertools decorators (`@logger`, `@tracer`, `@metrics`)
- Function signature and type hints
- Path parameter extraction pattern
- Request body parsing pattern (Pydantic)
- Service layer invocation
- HATEOAS response building
- Error response building
- HTTP status codes used

### 2. Service Layer Analysis

Document the SiteLifecycleService pattern:
- Constructor and dependency injection
- Method signatures
- Business rule validation
- Repository interactions
- Exception handling
- Logging patterns

### 3. Repository Layer Analysis

Document the repository pattern:
- Abstract base class (SiteRepository)
- DynamoDB implementation (DynamoDBSiteRepository)
- Available methods: `save()`, `get()`, `list_by_tenant()`, `count_by_tenant()`, `exists_by_subdomain()`
- PK/SK patterns used

### 4. Model Analysis

Document request/response models:
- Pydantic model patterns
- Field validation
- HATEOAS link structure
- Error response format

### 5. Exception Handling Pattern

Document exception patterns:
- BusinessException (4xx errors)
- UnexpectedException (5xx errors)
- Specific exceptions: `SiteNotFoundException`, `SiteQuotaExceededException`, `SubdomainAlreadyExistsException`
- Error code conventions (SITE_001, SITE_002, etc.)

### 6. Test Pattern Analysis

Document testing patterns:
- pytest fixtures
- Mock setup patterns
- Test naming conventions
- Assertion patterns

---

## Expected Output Format

```markdown
# Existing Code Review Output

## 1. Handler Pattern Analysis

### Lambda Powertools Usage
```python
@logger.inject_lambda_context
@tracer.capture_lambda_handler
@metrics.log_metrics
def handler(event: Dict[str, Any], context: LambdaContext) -> Dict[str, Any]:
```

### Path Parameter Extraction
- Function: `_extract_tenant_id(event)`
- Pattern: `event.get("pathParameters") or {}`

(Continue documenting each pattern...)

## 2. Service Layer Analysis

### SiteLifecycleService
- Constructor: `__init__(site_repository: SiteRepository, max_sites_per_tenant: int = 10)`
- Methods:
  - `create_site(site_data: Dict[str, Any]) -> Site`
  - `get_site(tenant_id: str, site_id: str) -> Site`
  - `list_sites(tenant_id: str) -> List[Site]`
  - `delete_site(tenant_id: str, site_id: str) -> None`

(Continue documenting...)

## 3. Repository Layer Analysis
...

## 4. Model Analysis
...

## 5. Exception Handling Pattern
...

## 6. Test Pattern Analysis
...

## Key Patterns Summary

| Pattern | Implementation |
|---------|----------------|
| Decorators | @logger, @tracer, @metrics |
| Request Validation | Pydantic models |
| Response Format | HATEOAS with _links |
| Error Codes | SITE_001 to SITE_00X |
| Test Framework | pytest with fixtures |
```

---

## Success Criteria

- [ ] Handler pattern fully documented with code examples
- [ ] Service layer methods and patterns documented
- [ ] Repository methods inventory complete
- [ ] Request/response models documented
- [ ] Exception classes and error codes documented
- [ ] Test patterns documented for replication
- [ ] Key patterns summary table created

---

## Execution Steps

1. Read `create_site_handler.py` and document handler patterns
2. Read `apply_template_handler.py` to confirm patterns consistency
3. Read `site_lifecycle_service.py` and document service patterns
4. Read repository files and document available methods
5. Read model files and document Pydantic patterns
6. Read exception file and document error handling
7. Read test file and document testing patterns
8. Create comprehensive output.md
9. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-23
