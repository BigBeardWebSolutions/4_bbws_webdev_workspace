# SDET Unit Test Skill

**Version**: 1.0
**Created**: 2026-01-01
**Type**: Test Automation
**Marker**: `@pytest.mark.unit`

---

## Purpose

Write isolated unit tests for pure business logic with no AWS dependencies. Tests are fast, deterministic, and use `unittest.mock` for dependency isolation.

---

## When to Use

- Testing validators and validation logic
- Testing data transformers and mappers
- Testing utility functions
- Testing business logic in service layers
- Testing domain models and entities

---

## Test Structure

```
lambdas/
└── create_organisation/
    ├── handler.py
    ├── service.py
    ├── validators.py
    └── tests/
        ├── __init__.py
        ├── test_validators.py      ← Unit tests
        └── test_service.py         ← Unit tests (mocked deps)
```

---

## Pattern: AAA (Arrange, Act, Assert)

```python
import pytest
from unittest.mock import patch, MagicMock

@pytest.mark.unit
def test_validate_organisation_name_valid():
    # Arrange
    name = "Valid Organisation"

    # Act
    result = validate_organisation_name(name)

    # Assert
    assert result is True


@pytest.mark.unit
def test_validate_organisation_name_empty():
    # Arrange
    name = ""

    # Act & Assert
    with pytest.raises(ValidationError) as exc:
        validate_organisation_name(name)

    assert "cannot be empty" in str(exc.value)
```

---

## Mocking Dependencies

```python
from unittest.mock import patch, MagicMock

@pytest.mark.unit
@patch('lambdas.create_organisation.service.OrganisationRepository')
def test_create_organisation_service(mock_repo):
    # Arrange
    mock_repo_instance = MagicMock()
    mock_repo.return_value = mock_repo_instance
    mock_repo_instance.save.return_value = {"id": "org-123"}

    service = OrganisationService(mock_repo_instance)

    # Act
    result = service.create(name="Test Org")

    # Assert
    mock_repo_instance.save.assert_called_once()
    assert result["id"] == "org-123"
```

---

## Fixtures

```python
# conftest.py
import pytest

@pytest.fixture
def valid_organisation_data():
    return {
        "name": "Test Organisation",
        "email": "admin@test.org",
        "plan": "enterprise"
    }

@pytest.fixture
def invalid_organisation_data():
    return {
        "name": "",  # Invalid: empty
        "email": "not-an-email",  # Invalid: format
        "plan": "unknown"  # Invalid: not in allowed values
    }
```

---

## Parametrized Tests

```python
import pytest

@pytest.mark.unit
@pytest.mark.parametrize("name,expected", [
    ("Valid Org", True),
    ("A", True),  # Minimum length
    ("", False),  # Empty
    (None, False),  # None
    ("A" * 256, False),  # Too long
])
def test_validate_organisation_name(name, expected):
    result = validate_organisation_name(name)
    assert result == expected
```

---

## Running Unit Tests

```bash
# Run all unit tests
pytest -m unit -v

# Run with coverage
pytest -m unit --cov=lambdas --cov-report=term-missing

# Run specific test file
pytest lambdas/create_organisation/tests/test_validators.py -v

# Run and stop on first failure
pytest -m unit -x -v
```

---

## Best Practices

| Practice | Description |
|----------|-------------|
| Fast | Tests complete in milliseconds |
| Isolated | No external dependencies |
| Deterministic | Same result every run |
| Self-validating | Clear pass/fail |
| Thorough | Cover edge cases |

---

## Version History

- **v1.0** (2026-01-01): Initial definition
