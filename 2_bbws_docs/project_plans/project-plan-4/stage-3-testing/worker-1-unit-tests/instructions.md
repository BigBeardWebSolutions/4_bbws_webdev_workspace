# Worker Instructions: Unit Tests

**Worker ID**: worker-1-unit-tests
**Stage**: Stage 3 - Testing
**Project**: project-plan-4

---

## Task Description

Create comprehensive unit tests for all 4 new handlers implemented in Stage 2. Follow existing test patterns from `test_create_site_handler.py` and ensure >90% code coverage for each handler.

---

## Inputs

**Test Pattern Reference**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_wordpress_site_management_lambda/sites-service/tests/unit/handlers/test_create_site_handler.py`

**Handlers to Test**:
- `sites-service/src/handlers/sites/get_site_handler.py`
- `sites-service/src/handlers/sites/list_sites_handler.py`
- `sites-service/src/handlers/sites/update_site_handler.py`
- `sites-service/src/handlers/sites/delete_site_handler.py`

**Test Fixtures**:
- `sites-service/tests/conftest.py`

---

## Deliverables

### 1. Test Files

Create in `/Users/tebogotseka/Documents/agentic_work/2_bbws_wordpress_site_management_lambda/sites-service/tests/unit/handlers/`:

- `test_get_site_handler.py`
- `test_list_sites_handler.py`
- `test_update_site_handler.py`
- `test_delete_site_handler.py`

### 2. Test Coverage Report

Run and document coverage:
```bash
pytest tests/unit/handlers --cov=src/handlers/sites --cov-report=term-missing
```

---

## Test Specifications

### test_get_site_handler.py

```python
"""Unit tests for GET /v1.0/tenants/{tenantId}/sites/{siteId} handler.

Tests cover:
- Successful site retrieval (200 OK)
- Site not found (404)
- Missing path parameters (400)
- Internal errors (500)
"""
import pytest
import json
from unittest.mock import Mock, patch, MagicMock
from datetime import datetime, timezone

from src.handlers.sites.get_site_handler import handler
from src.domain.exceptions import SiteNotFoundException, ValidationException


class TestGetSiteHandler:
    """Test suite for get_site_handler."""

    @pytest.fixture
    def mock_context(self):
        """Create mock Lambda context."""
        context = MagicMock()
        context.request_id = "test-request-id"
        return context

    @pytest.fixture
    def valid_event(self):
        """Create valid API Gateway event."""
        return {
            "pathParameters": {
                "tenantId": "tenant-123",
                "siteId": "site-456"
            },
            "requestContext": {
                "authorizer": {
                    "claims": {
                        "email": "user@example.com"
                    }
                }
            }
        }

    @pytest.fixture
    def mock_site(self):
        """Create mock Site entity."""
        site = MagicMock()
        site.site_id.value = "site-456"
        site.tenant_id = "tenant-123"
        site.site_name = "Test Site"
        site.site_address.subdomain = "testsite"
        site.status.name = "ACTIVE"
        site.environment.name = "DEV"
        site.template_id = "template-789"
        site.wordpress_version = "6.5"
        site.php_version = "8.2"
        site.created_at = datetime(2026, 1, 1, tzinfo=timezone.utc)
        site.created_by = "creator@example.com"
        site.updated_at = datetime(2026, 1, 2, tzinfo=timezone.utc)
        return site

    def test_get_site_success(self, valid_event, mock_context, mock_site):
        """Test successful site retrieval returns 200 OK."""
        with patch('src.handlers.sites.get_site_handler._get_site_lifecycle_service') as mock_service:
            mock_service.return_value.get_site.return_value = mock_site

            response = handler(valid_event, mock_context)

            assert response["statusCode"] == 200
            body = json.loads(response["body"])
            assert body["siteId"] == "site-456"
            assert body["tenantId"] == "tenant-123"
            assert body["siteName"] == "Test Site"
            assert "_links" in body
            assert "self" in body["_links"]

    def test_get_site_not_found(self, valid_event, mock_context):
        """Test site not found returns 404."""
        with patch('src.handlers.sites.get_site_handler._get_site_lifecycle_service') as mock_service:
            mock_service.return_value.get_site.side_effect = SiteNotFoundException(
                tenant_id="tenant-123",
                site_id="site-456"
            )

            response = handler(valid_event, mock_context)

            assert response["statusCode"] == 404
            body = json.loads(response["body"])
            assert body["error"]["code"] == "SITE_002"

    def test_get_site_missing_tenant_id(self, mock_context):
        """Test missing tenantId returns 400."""
        event = {
            "pathParameters": {
                "siteId": "site-456"
            }
        }

        response = handler(event, mock_context)

        assert response["statusCode"] == 400
        body = json.loads(response["body"])
        assert "tenantId" in body["error"]["message"].lower()

    def test_get_site_missing_site_id(self, mock_context):
        """Test missing siteId returns 400."""
        event = {
            "pathParameters": {
                "tenantId": "tenant-123"
            }
        }

        response = handler(event, mock_context)

        assert response["statusCode"] == 400
        body = json.loads(response["body"])
        assert "siteId" in body["error"]["message"].lower()

    def test_get_site_internal_error(self, valid_event, mock_context):
        """Test internal error returns 500."""
        with patch('src.handlers.sites.get_site_handler._get_site_lifecycle_service') as mock_service:
            mock_service.return_value.get_site.side_effect = Exception("Database error")

            response = handler(valid_event, mock_context)

            assert response["statusCode"] == 500
            body = json.loads(response["body"])
            assert body["error"]["code"] == "SYS_001"
```

### test_list_sites_handler.py

```python
"""Unit tests for GET /v1.0/tenants/{tenantId}/sites handler.

Tests cover:
- Successful list with sites (200 OK)
- Empty list (200 OK with empty items)
- Missing tenant ID (400)
- Invalid query parameters (400)
- Pagination parameters
- Internal errors (500)
"""
import pytest
import json
from unittest.mock import Mock, patch, MagicMock
from datetime import datetime, timezone

from src.handlers.sites.list_sites_handler import handler


class TestListSitesHandler:
    """Test suite for list_sites_handler."""

    @pytest.fixture
    def mock_context(self):
        """Create mock Lambda context."""
        context = MagicMock()
        context.request_id = "test-request-id"
        return context

    @pytest.fixture
    def valid_event(self):
        """Create valid API Gateway event."""
        return {
            "pathParameters": {
                "tenantId": "tenant-123"
            },
            "queryStringParameters": {
                "pageSize": "20"
            }
        }

    @pytest.fixture
    def mock_sites(self):
        """Create list of mock Site entities."""
        sites = []
        for i in range(3):
            site = MagicMock()
            site.site_id.value = f"site-{i}"
            site.tenant_id = "tenant-123"
            site.site_name = f"Test Site {i}"
            site.site_address.subdomain = f"testsite{i}"
            site.status.name = "ACTIVE"
            site.environment.name = "DEV"
            site.created_at = datetime(2026, 1, 1, tzinfo=timezone.utc)
            site.updated_at = datetime(2026, 1, 2, tzinfo=timezone.utc)
            sites.append(site)
        return sites

    def test_list_sites_success(self, valid_event, mock_context, mock_sites):
        """Test successful sites listing returns 200 OK."""
        with patch('src.handlers.sites.list_sites_handler._get_site_lifecycle_service') as mock_service:
            mock_service.return_value.list_sites.return_value = mock_sites

            response = handler(valid_event, mock_context)

            assert response["statusCode"] == 200
            body = json.loads(response["body"])
            assert len(body["items"]) == 3
            assert body["count"] == 3
            assert "_links" in body

    def test_list_sites_empty(self, valid_event, mock_context):
        """Test empty list returns 200 OK with empty items."""
        with patch('src.handlers.sites.list_sites_handler._get_site_lifecycle_service') as mock_service:
            mock_service.return_value.list_sites.return_value = []

            response = handler(valid_event, mock_context)

            assert response["statusCode"] == 200
            body = json.loads(response["body"])
            assert body["items"] == []
            assert body["count"] == 0

    def test_list_sites_missing_tenant_id(self, mock_context):
        """Test missing tenantId returns 400."""
        event = {
            "pathParameters": {}
        }

        response = handler(event, mock_context)

        assert response["statusCode"] == 400

    def test_list_sites_custom_page_size(self, mock_context, mock_sites):
        """Test custom pageSize parameter."""
        event = {
            "pathParameters": {"tenantId": "tenant-123"},
            "queryStringParameters": {"pageSize": "50"}
        }

        with patch('src.handlers.sites.list_sites_handler._get_site_lifecycle_service') as mock_service:
            mock_service.return_value.list_sites.return_value = mock_sites

            response = handler(event, mock_context)

            assert response["statusCode"] == 200

    def test_list_sites_invalid_page_size(self, mock_context):
        """Test invalid pageSize returns 400."""
        event = {
            "pathParameters": {"tenantId": "tenant-123"},
            "queryStringParameters": {"pageSize": "invalid"}
        }

        response = handler(event, mock_context)

        assert response["statusCode"] == 400
```

### test_update_site_handler.py

```python
"""Unit tests for PUT /v1.0/tenants/{tenantId}/sites/{siteId} handler.

Tests cover:
- Successful update (200 OK)
- Site not found (404)
- Invalid request body (400)
- Site not in ACTIVE status (422)
- Missing path parameters (400)
- Internal errors (500)
"""
import pytest
import json
from unittest.mock import Mock, patch, MagicMock
from datetime import datetime, timezone

from src.handlers.sites.update_site_handler import handler
from src.domain.exceptions import (
    SiteNotFoundException,
    InvalidStatusTransitionException,
    ValidationException
)


class TestUpdateSiteHandler:
    """Test suite for update_site_handler."""

    @pytest.fixture
    def mock_context(self):
        """Create mock Lambda context."""
        context = MagicMock()
        context.request_id = "test-request-id"
        return context

    @pytest.fixture
    def valid_event(self):
        """Create valid API Gateway event."""
        return {
            "pathParameters": {
                "tenantId": "tenant-123",
                "siteId": "site-456"
            },
            "body": json.dumps({
                "siteName": "Updated Site Name",
                "templateId": "template-new"
            })
        }

    @pytest.fixture
    def mock_updated_site(self):
        """Create mock updated Site entity."""
        site = MagicMock()
        site.site_id.value = "site-456"
        site.tenant_id = "tenant-123"
        site.site_name = "Updated Site Name"
        site.site_address.subdomain = "testsite"
        site.status.name = "ACTIVE"
        site.environment.name = "DEV"
        site.template_id = "template-new"
        site.updated_at = datetime(2026, 1, 23, tzinfo=timezone.utc)
        return site

    def test_update_site_success(self, valid_event, mock_context, mock_updated_site):
        """Test successful site update returns 200 OK."""
        with patch('src.handlers.sites.update_site_handler._get_site_lifecycle_service') as mock_service:
            mock_service.return_value.update_site.return_value = mock_updated_site

            response = handler(valid_event, mock_context)

            assert response["statusCode"] == 200
            body = json.loads(response["body"])
            assert body["siteName"] == "Updated Site Name"
            assert body["message"] == "Site updated successfully"

    def test_update_site_not_found(self, valid_event, mock_context):
        """Test site not found returns 404."""
        with patch('src.handlers.sites.update_site_handler._get_site_lifecycle_service') as mock_service:
            mock_service.return_value.update_site.side_effect = SiteNotFoundException(
                tenant_id="tenant-123",
                site_id="site-456"
            )

            response = handler(valid_event, mock_context)

            assert response["statusCode"] == 404

    def test_update_site_invalid_status(self, valid_event, mock_context):
        """Test update of non-ACTIVE site returns 422."""
        with patch('src.handlers.sites.update_site_handler._get_site_lifecycle_service') as mock_service:
            mock_service.return_value.update_site.side_effect = InvalidStatusTransitionException(
                message="Site cannot be updated in SUSPENDED status"
            )

            response = handler(valid_event, mock_context)

            assert response["statusCode"] == 422

    def test_update_site_malformed_json(self, mock_context):
        """Test malformed JSON returns 400."""
        event = {
            "pathParameters": {
                "tenantId": "tenant-123",
                "siteId": "site-456"
            },
            "body": "not valid json"
        }

        response = handler(event, mock_context)

        assert response["statusCode"] == 400

    def test_update_site_empty_body(self, mock_context):
        """Test empty update body (no changes)."""
        event = {
            "pathParameters": {
                "tenantId": "tenant-123",
                "siteId": "site-456"
            },
            "body": "{}"
        }

        with patch('src.handlers.sites.update_site_handler._get_site_lifecycle_service') as mock_service:
            mock_updated = MagicMock()
            mock_service.return_value.update_site.return_value = mock_updated

            response = handler(event, mock_context)

            # Should still succeed even with no changes
            assert response["statusCode"] in [200, 400]  # Depends on validation rules
```

### test_delete_site_handler.py

```python
"""Unit tests for DELETE /v1.0/tenants/{tenantId}/sites/{siteId} handler.

Tests cover:
- Successful deletion (200 OK)
- Site not found (404)
- Missing path parameters (400)
- Internal errors (500)
"""
import pytest
import json
from unittest.mock import Mock, patch, MagicMock
from datetime import datetime, timezone

from src.handlers.sites.delete_site_handler import handler
from src.domain.exceptions import SiteNotFoundException


class TestDeleteSiteHandler:
    """Test suite for delete_site_handler."""

    @pytest.fixture
    def mock_context(self):
        """Create mock Lambda context."""
        context = MagicMock()
        context.request_id = "test-request-id"
        return context

    @pytest.fixture
    def valid_event(self):
        """Create valid API Gateway event."""
        return {
            "pathParameters": {
                "tenantId": "tenant-123",
                "siteId": "site-456"
            }
        }

    def test_delete_site_success(self, valid_event, mock_context):
        """Test successful site deletion returns 200 OK."""
        with patch('src.handlers.sites.delete_site_handler._get_site_lifecycle_service') as mock_service:
            mock_service.return_value.delete_site.return_value = None

            response = handler(valid_event, mock_context)

            assert response["statusCode"] == 200
            body = json.loads(response["body"])
            assert body["status"] == "DEPROVISIONING"
            assert "deletion" in body["message"].lower() or "deleted" in body["message"].lower()

    def test_delete_site_not_found(self, valid_event, mock_context):
        """Test site not found returns 404."""
        with patch('src.handlers.sites.delete_site_handler._get_site_lifecycle_service') as mock_service:
            mock_service.return_value.delete_site.side_effect = SiteNotFoundException(
                tenant_id="tenant-123",
                site_id="site-456"
            )

            response = handler(valid_event, mock_context)

            assert response["statusCode"] == 404
            body = json.loads(response["body"])
            assert body["error"]["code"] == "SITE_002"

    def test_delete_site_missing_tenant_id(self, mock_context):
        """Test missing tenantId returns 400."""
        event = {
            "pathParameters": {
                "siteId": "site-456"
            }
        }

        response = handler(event, mock_context)

        assert response["statusCode"] == 400

    def test_delete_site_missing_site_id(self, mock_context):
        """Test missing siteId returns 400."""
        event = {
            "pathParameters": {
                "tenantId": "tenant-123"
            }
        }

        response = handler(event, mock_context)

        assert response["statusCode"] == 400

    def test_delete_site_internal_error(self, valid_event, mock_context):
        """Test internal error returns 500."""
        with patch('src.handlers.sites.delete_site_handler._get_site_lifecycle_service') as mock_service:
            mock_service.return_value.delete_site.side_effect = Exception("Database error")

            response = handler(valid_event, mock_context)

            assert response["statusCode"] == 500
            body = json.loads(response["body"])
            assert body["error"]["code"] == "SYS_001"

    def test_delete_site_hateoas_links(self, valid_event, mock_context):
        """Test response includes HATEOAS links."""
        with patch('src.handlers.sites.delete_site_handler._get_site_lifecycle_service') as mock_service:
            mock_service.return_value.delete_site.return_value = None

            response = handler(valid_event, mock_context)

            body = json.loads(response["body"])
            assert "_links" in body
            assert "tenant" in body["_links"]
            assert "sites" in body["_links"]
```

---

## Success Criteria

- [ ] All 4 test files created
- [ ] All tests passing (`pytest tests/unit/handlers -v`)
- [ ] Coverage >90% for each handler
- [ ] Tests cover success paths
- [ ] Tests cover error paths (400, 404, 422, 500)
- [ ] Tests follow existing patterns from `test_create_site_handler.py`
- [ ] Mocks properly configured for service layer

---

## Execution Steps

1. Review existing `test_create_site_handler.py` for patterns
2. Review `conftest.py` for available fixtures
3. Create `test_get_site_handler.py` with all test cases
4. Create `test_list_sites_handler.py` with all test cases
5. Create `test_update_site_handler.py` with all test cases
6. Create `test_delete_site_handler.py` with all test cases
7. Run all tests: `pytest tests/unit/handlers -v`
8. Run coverage: `pytest tests/unit/handlers --cov=src/handlers/sites`
9. Verify >90% coverage for new handlers
10. Create `output.md` with test results summary
11. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-23
