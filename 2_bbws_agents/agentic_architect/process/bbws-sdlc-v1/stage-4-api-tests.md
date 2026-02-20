# Stage 4: API Tests (TDD)

**Parent Plan**: [BBWS SDLC Main Plan](./main-plan.md)
**Stage**: 4 of 10
**Status**: ⏳ PENDING
**Last Updated**: 2026-01-01

---

## Objective

Write comprehensive tests BEFORE implementation following Test-Driven Development (TDD). Create unit tests, mock tests, integration tests, and E2E tests based on the LLD specifications.

---

## Agent & Skill Assignment

| Role | Agent | Skill |
|------|-------|-------|
| **Primary** | SDET_Engineer_Agent | `SDET_unit_test.skill.md` |
| **Support** | - | `SDET_mock_test.skill.md` |
| **Support** | - | `SDET_integration_test.skill.md` |
| **Support** | - | `SDET_persistence_test.skill.md` |

**Agent Path**: `agentic_architect/SDET_Engineer_Agent.md`

---

## Workers

| # | Worker | Task | Status | Output |
|---|--------|------|--------|--------|
| 1 | worker-1-unit-tests | Write unit tests for services and validators | ⏳ PENDING | `tests/unit/` |
| 2 | worker-2-mock-tests | Write mocked AWS tests (moto) | ⏳ PENDING | `tests/unit/` |
| 3 | worker-3-integration-tests | Write integration test stubs | ⏳ PENDING | `tests/integration/` |
| 4 | worker-4-e2e-tests | Write E2E test framework | ⏳ PENDING | `tests/e2e/` |

---

## Worker Instructions

### Worker 1: Unit Tests

**Objective**: Write pure unit tests for business logic

**Skill Reference**: Apply `SDET_unit_test.skill.md`

**Inputs**:
- LLD document (service specifications)
- API contracts

**Deliverables**:
- `tests/unit/services/test_{service_name}.py`
- `tests/unit/validators/test_{validator_name}.py`
- `tests/unit/models/test_{model_name}.py`

**Test Categories**:
- Service method tests (happy path, edge cases)
- Validator tests (valid/invalid inputs)
- Model serialization tests

**Quality Criteria**:
- [ ] 80%+ coverage target per file
- [ ] Tests are isolated (no external dependencies)
- [ ] Clear test naming (test_{scenario}_{expected_result})
- [ ] Fixtures in conftest.py

---

### Worker 2: Mock Tests

**Objective**: Write tests with mocked AWS services using moto

**Skill Reference**: Apply `SDET_mock_test.skill.md`

**Inputs**:
- LLD document (repository specifications)
- Database design

**Deliverables**:
- `tests/unit/repositories/test_{repository_name}.py`
- `tests/unit/handlers/test_{handler_name}.py`

**Test Categories**:
- Repository CRUD operations (mocked DynamoDB)
- Handler tests with mocked services
- Error handling scenarios

**Mocking Pattern**:
```python
@pytest.fixture
def dynamodb_table(aws_mock):
    # Create mock table with moto
    ...
```

**Quality Criteria**:
- [ ] All repository methods tested
- [ ] All handlers tested
- [ ] Error scenarios covered
- [ ] Uses moto for DynamoDB mocking

---

### Worker 3: Integration Tests

**Objective**: Create integration test framework for deployed services

**Skill Reference**: Apply `SDET_integration_test.skill.md`

**Inputs**:
- API contracts
- Environment configuration

**Deliverables**:
- `tests/integration/__init__.py`
- `tests/integration/conftest.py`
- `tests/integration/test_{endpoint}.py` (stubs)

**Test Categories**:
- Lambda direct invocation tests
- DynamoDB read/write tests
- Cross-service integration tests

**Quality Criteria**:
- [ ] Test framework established
- [ ] Environment-aware configuration
- [ ] Test data cleanup implemented
- [ ] Stubs ready for implementation

---

### Worker 4: E2E Tests

**Objective**: Create E2E test framework for API Gateway endpoints

**Skill Reference**: Apply `SDET_integration_test.skill.md`

**Inputs**:
- API contracts
- Environment configuration

**Deliverables**:
- `tests/e2e/__init__.py`
- `tests/e2e/config.py` (environment configuration)
- `tests/e2e/conftest.py` (fixtures)
- `tests/e2e/{operation}/test_{operation}.py`

**Test Structure**:
```
tests/e2e/
├── config.py           # DEV/SIT/PROD URLs
├── conftest.py         # Fixtures, cleanup
├── list_{resource}/
│   └── test_list.py
├── get_{resource}/
│   └── test_get.py
├── create_{resource}/
│   └── test_create.py
├── update_{resource}/
│   └── test_update.py
└── delete_{resource}/
    └── test_delete.py
```

**Quality Criteria**:
- [ ] All CRUD operations have E2E tests
- [ ] Tests work across environments
- [ ] PROD tests are read-only
- [ ] Test data isolated (unique IDs)

---

## Stage Outputs

| Output | Description | Location |
|--------|-------------|----------|
| Unit tests | Pure logic tests | `{repo}/tests/unit/` |
| Mock tests | Moto-based AWS tests | `{repo}/tests/unit/` |
| Integration tests | Deployed service tests | `{repo}/tests/integration/` |
| E2E tests | API Gateway tests | `{repo}/tests/e2e/` |
| conftest.py | Shared fixtures | `{repo}/tests/conftest.py` |

---

## Test Coverage Requirements

| Test Type | Coverage Target | Purpose |
|-----------|-----------------|---------|
| Unit | ≥ 80% | Business logic validation |
| Mock | ≥ 80% | AWS integration validation |
| Integration | Key paths | Deployed service validation |
| E2E | All endpoints | Full API validation |

---

## Success Criteria

- [ ] All 4 workers completed
- [ ] Test framework established
- [ ] Unit tests written (will fail until Stage 5)
- [ ] Mock tests written (will fail until Stage 5)
- [ ] E2E test framework ready
- [ ] Coverage configuration in pytest.ini

---

## Dependencies

**Depends On**: Stage 3 (LLD)
**Blocks**: Stage 5 (API Implementation)

---

## Estimated Duration

| Activity | Agentic | Manual |
|----------|---------|--------|
| Unit tests | 20 min | 2 hours |
| Mock tests | 20 min | 2 hours |
| Integration tests | 15 min | 1 hour |
| E2E tests | 20 min | 2 hours |
| **Total** | **75 min** | **7 hours** |

---

**Navigation**: [← Stage 3](./stage-3-lld.md) | [Main Plan](./main-plan.md) | [Stage 5: Implementation →](./stage-5-api-implementation.md)
