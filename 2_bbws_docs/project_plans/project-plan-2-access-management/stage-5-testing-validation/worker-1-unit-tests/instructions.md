# Worker Instructions: Unit Tests

**Worker ID**: worker-1-unit-tests
**Stage**: Stage 5 - Testing & Validation
**Project**: project-plan-2-access-management

---

## Task

Create comprehensive unit test suites for all 6 Access Management services using pytest with moto for AWS mocking. Target > 80% code coverage.

---

## Scope

### Services to Test (6)
1. Permission Service (6 Lambda handlers)
2. Invitation Service (7 Lambda handlers)
3. Team Service (14 Lambda handlers)
4. Role Service (8 Lambda handlers)
5. Authorizer Service (1 Lambda handler)
6. Audit Service (5 Lambda handlers)

**Total Handlers**: 41

---

## Deliverables

Create `output.md` with:

### 1. Test Directory Structure
```
tests/unit/
├── conftest.py                    # Shared fixtures
├── test_permission_service/
│   ├── __init__.py
│   ├── test_list_permissions.py
│   ├── test_get_permission.py
│   ├── test_create_permission.py
│   ├── test_update_permission.py
│   ├── test_delete_permission.py
│   └── test_seed_permissions.py
├── test_invitation_service/
├── test_team_service/
├── test_role_service/
├── test_authorizer_service/
└── test_audit_service/
```

### 2. pytest Configuration
- pytest.ini configuration
- Coverage configuration (.coveragerc)
- requirements-test.txt

### 3. Shared Test Fixtures (conftest.py)
- DynamoDB table mocks
- Sample test data generators
- API Gateway event generators
- Lambda context mock

### 4. Sample Test Implementation
For ONE service (Permission Service), provide complete test file showing:
- Test class structure
- Fixture usage
- Moto DynamoDB mocking
- Positive and negative test cases
- Edge case handling
- Assertion patterns

### 5. Test Case Summary
| Service | Test Files | Test Cases | Edge Cases |
|---------|------------|------------|------------|
| Permission | 6 | 30+ | 15+ |
| Invitation | 7 | 35+ | 20+ |
| Team | 14 | 70+ | 35+ |
| Role | 8 | 40+ | 20+ |
| Authorizer | 1 | 15+ | 10+ |
| Audit | 5 | 25+ | 15+ |

---

## Test Patterns

### Pattern 1: Happy Path
Test successful execution with valid inputs.

### Pattern 2: Validation Errors
Test input validation failures (missing fields, invalid formats).

### Pattern 3: Not Found
Test 404 scenarios for missing resources.

### Pattern 4: Conflict
Test 409 scenarios (duplicate names, etc.).

### Pattern 5: Authorization
Test unauthorized access attempts.

---

## Success Criteria

- [ ] Unit tests for all 41 handlers
- [ ] pytest.ini configured
- [ ] Coverage target > 80%
- [ ] Fixtures for all services
- [ ] Sample test file complete
- [ ] Edge cases documented

---

**Status**: PENDING
**Created**: 2026-01-23
