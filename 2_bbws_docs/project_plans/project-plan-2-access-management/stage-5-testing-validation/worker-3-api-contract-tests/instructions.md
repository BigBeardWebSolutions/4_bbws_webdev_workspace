# Worker Instructions: API Contract Tests

**Worker ID**: worker-3-api-contract-tests
**Stage**: Stage 5 - Testing & Validation
**Project**: project-plan-2-access-management

---

## Task

Create API contract tests that validate all 44 endpoints against their OpenAPI specifications using schemathesis and pytest.

---

## Scope

### Endpoints by Service
| Service | Endpoints | Public |
|---------|-----------|--------|
| Permission | 6 | 0 |
| Invitation | 8 | 3 |
| Team | 14 | 0 |
| Role | 8 | 0 |
| Audit | 5 | 0 |
| **Total** | **41** | **3** |

---

## Deliverables

Create `output.md` with:

### 1. Test Directory Structure
```
tests/contract/
├── conftest.py
├── openapi/
│   ├── permission-service.yaml
│   ├── invitation-service.yaml
│   ├── team-service.yaml
│   ├── role-service.yaml
│   └── audit-service.yaml
├── test_permission_contract.py
├── test_invitation_contract.py
├── test_team_contract.py
├── test_role_contract.py
├── test_audit_contract.py
└── schemas/
    ├── request_schemas.py
    └── response_schemas.py
```

### 2. Contract Test Categories

#### Category 1: Request Validation
- Required fields
- Field types
- Value constraints
- Format validation (UUID, email, date-time)

#### Category 2: Response Validation
- Status codes match spec
- Response body schema
- HATEOAS links present
- Error response format

#### Category 3: Path Parameters
- UUID format validation
- Case sensitivity
- URL encoding

#### Category 4: Query Parameters
- Pagination parameters
- Filter parameters
- Sort parameters

### 3. schemathesis Configuration
```python
# pytest configuration for schemathesis
schema = schemathesis.from_path("openapi/permission-service.yaml")

@schema.parametrize()
def test_api(case):
    response = case.call_and_validate()
```

### 4. Sample Test Implementation
Complete contract test file for ONE service.

### 5. Response Schema Validation
- 200 OK responses
- 201 Created responses
- 400 Validation errors
- 401 Unauthorized
- 403 Forbidden
- 404 Not Found
- 409 Conflict

---

## Contract Test Patterns

### Pattern 1: Schema Validation
```python
def test_list_permissions_response_schema():
    response = call_api("/v1/permissions")
    validate(response.json(), PermissionListSchema)
```

### Pattern 2: Error Format
```python
def test_validation_error_format():
    response = call_api("/v1/permissions", method="POST", body={})
    assert response.status_code == 400
    assert "error" in response.json()
    assert "message" in response.json()
```

### Pattern 3: HATEOAS Links
```python
def test_permission_has_self_link():
    response = call_api("/v1/permissions/123")
    assert "_links" in response.json()
    assert "self" in response.json()["_links"]
```

---

## Success Criteria

- [ ] All 41 endpoints contract tested
- [ ] OpenAPI specs validated
- [ ] Request schemas tested
- [ ] Response schemas tested
- [ ] Error formats validated
- [ ] HATEOAS links verified

---

**Status**: PENDING
**Created**: 2026-01-23
