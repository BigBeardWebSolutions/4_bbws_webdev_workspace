# Worker Instructions: Test Automation Workflows

**Worker ID**: worker-3-test-automation-workflow
**Stage**: Stage 6 - CI/CD Pipeline
**Project**: project-plan-2-access-management

---

## Task

Create GitHub Actions workflows for automated testing including unit tests on PRs and integration tests on branch pushes.

---

## Deliverables

Create `output.md` with:

### 1. test-unit.yml
- Trigger: Pull Request to any branch
- Setup Python 3.12
- Install dependencies
- Run pytest for unit tests
- Generate coverage report (target > 80%)
- Post coverage summary to PR
- Fail if coverage drops

### 2. test-integration.yml
- Trigger: Push to develop branch
- Setup Python 3.12
- Configure AWS credentials (DEV)
- Run integration tests against DEV
- Generate test report
- Post results to PR/commit

### 3. Coverage Configuration
- codecov.yml configuration
- Coverage thresholds
- Badge generation

### 4. Test Matrix
- Python version matrix (3.11, 3.12)
- OS matrix (ubuntu-latest)
- Parallel test execution

---

## Test Commands

```bash
# Unit tests
pytest tests/unit/ -v --cov=src --cov-report=xml --junitxml=results.xml

# Integration tests
pytest tests/integration/ -v --junitxml=integration-results.xml

# Contract tests
pytest tests/contract/ -v --junitxml=contract-results.xml

# Security tests
pytest tests/authorization/ -v --junitxml=security-results.xml
```

---

## Success Criteria

- [ ] Unit tests run on every PR
- [ ] Coverage report posted to PR
- [ ] Coverage threshold enforced (> 80%)
- [ ] Integration tests run on develop push
- [ ] Test reports generated
- [ ] Parallel execution for speed

---

**Status**: PENDING
**Created**: 2026-01-24
