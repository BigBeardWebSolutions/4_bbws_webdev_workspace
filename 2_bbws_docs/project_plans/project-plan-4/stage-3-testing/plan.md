# Stage 3: Testing

**Stage ID**: stage-3-testing
**Project**: project-plan-4
**Status**: PENDING
**Workers**: 2

---

## Stage Objective

Create comprehensive test coverage for the 4 new handlers implemented in Stage 2. Follow TDD principles with unit tests for each handler and integration tests for the Sites API endpoints.

---

## Stage Workers

| Worker | Task | Status |
|--------|------|--------|
| worker-1-unit-tests | Create unit tests for all 4 handlers | PENDING |
| worker-2-integration-tests | Create integration tests for Sites API | PENDING |

---

## Stage Inputs

| Document | Location |
|----------|----------|
| Stage 2 Handlers | `sites-service/src/handlers/sites/` |
| Existing Test Patterns | `sites-service/tests/unit/handlers/test_create_site_handler.py` |
| pytest Configuration | `sites-service/pytest.ini` |
| Test Fixtures | `sites-service/tests/conftest.py` |

---

## Stage Outputs

**Unit Test Files** (in `sites-service/tests/unit/handlers/`):
- `test_get_site_handler.py`
- `test_list_sites_handler.py`
- `test_update_site_handler.py`
- `test_delete_site_handler.py`

**Integration Test Files** (in `sites-service/tests/integration/`):
- `test_sites_api.py` - Full Sites API integration tests

**Coverage Report**:
- Target: >90% coverage for new handlers
- Run: `pytest --cov=src --cov-report=term-missing`

---

## Testing Standards

### Unit Test Requirements
- Each handler must have dedicated test file
- Test all success paths
- Test all error paths (validation, not found, business rules)
- Use mocks for external dependencies (DynamoDB, service layer)
- Follow AAA pattern (Arrange, Act, Assert)

### Test Coverage Targets
| Component | Minimum Coverage |
|-----------|-----------------|
| Handlers | 90% |
| Service Layer | 90% |
| Models | 80% |
| Exceptions | 100% |

### Testing Framework
- **pytest**: Test runner
- **pytest-cov**: Coverage reporting
- **moto**: AWS service mocking
- **unittest.mock**: Python mocking

---

## Success Criteria

- [ ] Unit tests created for all 4 handlers
- [ ] All unit tests passing
- [ ] Integration tests created for Sites API
- [ ] All integration tests passing
- [ ] Code coverage >90% for new handlers
- [ ] No regressions in existing tests (347 tests still passing)
- [ ] All 2 workers completed
- [ ] Stage summary created

---

## Dependencies

**Depends On**: Stage 2 (Implementation) - Handlers must be implemented

**Blocks**: Stage 4 (Deployment) - Tests must pass before deployment

---

## Test Execution Commands

### Run All Tests
```bash
cd /Users/tebogotseka/Documents/agentic_work/2_bbws_wordpress_site_management_lambda/sites-service
pytest tests/ -v
```

### Run Unit Tests Only
```bash
pytest tests/unit -v
```

### Run Integration Tests Only
```bash
pytest tests/integration -v
```

### Run with Coverage
```bash
pytest tests/unit --cov=src --cov-report=term-missing --cov-report=html
```

### Run Specific Handler Tests
```bash
pytest tests/unit/handlers/test_get_site_handler.py -v
pytest tests/unit/handlers/test_list_sites_handler.py -v
pytest tests/unit/handlers/test_update_site_handler.py -v
pytest tests/unit/handlers/test_delete_site_handler.py -v
```

---

**Created**: 2026-01-23
