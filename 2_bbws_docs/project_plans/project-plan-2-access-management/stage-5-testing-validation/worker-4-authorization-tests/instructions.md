# Worker Instructions: Authorization Tests

**Worker ID**: worker-4-authorization-tests
**Stage**: Stage 5 - Testing & Validation
**Project**: project-plan-2-access-management

---

## Task

Create comprehensive security tests validating the Lambda Authorizer, permission enforcement, team data isolation, and organisation boundaries.

---

## Scope

### Security Test Categories
1. **JWT Validation** - Token parsing, expiry, signature
2. **Permission Enforcement** - Required permissions for each endpoint
3. **Team Data Isolation** - Users can only access their team data
4. **Organisation Boundaries** - Cross-org access prevention
5. **Role-Based Access** - Role permission resolution
6. **Public Endpoints** - No auth required for invitation accept/decline

---

## Deliverables

Create `output.md` with:

### 1. Test Directory Structure
```
tests/authorization/
├── conftest.py
├── fixtures/
│   ├── jwt_fixtures.py
│   ├── user_fixtures.py
│   └── permission_fixtures.py
├── test_jwt_validation.py
├── test_permission_enforcement.py
├── test_team_data_isolation.py
├── test_org_boundaries.py
├── test_role_permissions.py
├── test_authorizer_context.py
└── test_public_endpoints.py
```

### 2. Test Scenarios

#### Scenario 1: JWT Validation
| Test Case | Expected |
|-----------|----------|
| Valid token | Allow |
| Expired token | 401 |
| Invalid signature | 401 |
| Missing token | 401 |
| Malformed token | 401 |
| Wrong issuer | 401 |

#### Scenario 2: Permission Enforcement
| Endpoint | Required Permission | Test |
|----------|---------------------|------|
| POST /permissions | permission:create | Deny without |
| GET /permissions | None (authenticated) | Allow |
| PUT /permissions/{id} | permission:update | Deny without |

#### Scenario 3: Team Data Isolation
| Test Case | Expected |
|-----------|----------|
| User queries own team | Allow |
| User queries other team | 403 |
| User with multiple teams | Allow for all |
| Admin queries any team | Allow (with role) |

#### Scenario 4: Organisation Boundaries
| Test Case | Expected |
|-----------|----------|
| Access own org | Allow |
| Access other org | 403 |
| Org ID in path vs token | Must match |

### 3. Authorizer Context Tests
```python
def test_authorizer_populates_context():
    # Verify all context values passed to backend:
    # - userId
    # - email
    # - orgId
    # - teamIds (comma-separated)
    # - permissions (comma-separated)
    # - roleIds (comma-separated)
```

### 4. Sample Test Implementation
Complete test file for permission enforcement.

### 5. Security Test Matrix
Full matrix of endpoints × permissions × expected outcomes.

---

## Authorization Test Patterns

### Pattern 1: Permission Check
```python
def test_create_permission_requires_permission_create():
    token = generate_token(permissions=[])  # No permissions
    response = call_api("/v1/permissions", method="POST", token=token)
    assert response.status_code == 403
```

### Pattern 2: Team Isolation
```python
def test_user_cannot_access_other_team():
    token = generate_token(team_ids=["team-1"])
    response = call_api("/v1/orgs/org1/teams/team-2/members", token=token)
    assert response.status_code == 403
```

### Pattern 3: Org Boundary
```python
def test_user_cannot_access_other_org():
    token = generate_token(org_id="org-1")
    response = call_api("/v1/orgs/org-2/teams", token=token)
    assert response.status_code == 403
```

---

## Success Criteria

- [ ] All JWT validation scenarios tested
- [ ] All 41 endpoints permission tested
- [ ] Team data isolation verified
- [ ] Organisation boundaries enforced
- [ ] Public endpoints accessible without auth
- [ ] Authorizer context verified
- [ ] Security test matrix complete

---

**Status**: PENDING
**Created**: 2026-01-23
