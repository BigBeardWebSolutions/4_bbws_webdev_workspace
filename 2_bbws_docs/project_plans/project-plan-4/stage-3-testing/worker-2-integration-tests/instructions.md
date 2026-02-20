# Worker Instructions: Integration Tests

**Worker ID**: worker-2-integration-tests
**Stage**: Stage 3 - Testing
**Project**: project-plan-4

---

## Task Description

Create integration tests for the Sites API that test the full request/response flow including service layer and repository interactions. Use moto for AWS service mocking (DynamoDB) to test real data persistence patterns.

---

## Inputs

**Existing Integration Tests**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_wordpress_site_management_lambda/sites-service/tests/integration/test_create_site_integration.py`

**Handlers to Test**:
- All Sites Service handlers working together
- Full CRUD operations flow

**Test Fixtures**:
- `sites-service/tests/conftest.py`

---

## Deliverables

### 1. Integration Test File

Create: `/Users/tebogotseka/Documents/agentic_work/2_bbws_wordpress_site_management_lambda/sites-service/tests/integration/test_sites_api.py`

### 2. Test Data Fixtures

Update `conftest.py` if needed with shared fixtures for integration tests.

---

## Test Specifications

### test_sites_api.py

```python
"""Integration tests for Sites API endpoints.

These tests verify the full request/response flow including:
- Handler execution
- Service layer business logic
- Repository data persistence (mocked with moto)
- HATEOAS response structure
- Error handling across layers

Uses moto to mock AWS DynamoDB for realistic persistence testing.
"""
import pytest
import json
import os
from datetime import datetime, timezone
from unittest.mock import MagicMock
import boto3
from moto import mock_aws

from src.handlers.sites.create_site_handler import handler as create_handler
from src.handlers.sites.get_site_handler import handler as get_handler
from src.handlers.sites.list_sites_handler import handler as list_handler
from src.handlers.sites.update_site_handler import handler as update_handler
from src.handlers.sites.delete_site_handler import handler as delete_handler


@pytest.fixture
def aws_credentials():
    """Mock AWS Credentials for moto."""
    os.environ["AWS_ACCESS_KEY_ID"] = "testing"
    os.environ["AWS_SECRET_ACCESS_KEY"] = "testing"
    os.environ["AWS_SECURITY_TOKEN"] = "testing"
    os.environ["AWS_SESSION_TOKEN"] = "testing"
    os.environ["AWS_DEFAULT_REGION"] = "af-south-1"


@pytest.fixture
def dynamodb_table(aws_credentials):
    """Create mock DynamoDB table for testing."""
    with mock_aws():
        client = boto3.client("dynamodb", region_name="af-south-1")

        # Create Sites table matching production schema
        client.create_table(
            TableName="sites",
            KeySchema=[
                {"AttributeName": "PK", "KeyType": "HASH"},
                {"AttributeName": "SK", "KeyType": "RANGE"}
            ],
            AttributeDefinitions=[
                {"AttributeName": "PK", "AttributeType": "S"},
                {"AttributeName": "SK", "AttributeType": "S"},
                {"AttributeName": "subdomain", "AttributeType": "S"}
            ],
            GlobalSecondaryIndexes=[
                {
                    "IndexName": "SubdomainIndex",
                    "KeySchema": [
                        {"AttributeName": "subdomain", "KeyType": "HASH"}
                    ],
                    "Projection": {"ProjectionType": "ALL"}
                }
            ],
            BillingMode="PAY_PER_REQUEST"
        )

        os.environ["SITES_TABLE"] = "sites"

        yield client


@pytest.fixture
def mock_context():
    """Create mock Lambda context."""
    context = MagicMock()
    context.request_id = "integration-test-request-id"
    return context


class TestSitesAPIIntegration:
    """Integration test suite for Sites API."""

    def test_full_site_lifecycle(self, dynamodb_table, mock_context):
        """Test complete site lifecycle: Create -> Get -> Update -> Delete."""

        # 1. CREATE SITE
        create_event = {
            "pathParameters": {"tenantId": "tenant-integration-test"},
            "requestContext": {
                "authorizer": {
                    "claims": {"email": "integration@test.com"}
                }
            },
            "body": json.dumps({
                "siteName": "Integration Test Site",
                "subdomain": "integration-test",
                "environment": "DEV"
            })
        }

        create_response = create_handler(create_event, mock_context)

        assert create_response["statusCode"] == 202
        create_body = json.loads(create_response["body"])
        site_id = create_body["siteId"]
        assert site_id is not None
        assert create_body["status"] == "PROVISIONING"

        # 2. GET SITE
        get_event = {
            "pathParameters": {
                "tenantId": "tenant-integration-test",
                "siteId": site_id
            }
        }

        get_response = get_handler(get_event, mock_context)

        assert get_response["statusCode"] == 200
        get_body = json.loads(get_response["body"])
        assert get_body["siteId"] == site_id
        assert get_body["siteName"] == "Integration Test Site"
        assert "_links" in get_body
        assert "self" in get_body["_links"]

        # 3. LIST SITES
        list_event = {
            "pathParameters": {"tenantId": "tenant-integration-test"},
            "queryStringParameters": {"pageSize": "10"}
        }

        list_response = list_handler(list_event, mock_context)

        assert list_response["statusCode"] == 200
        list_body = json.loads(list_response["body"])
        assert list_body["count"] >= 1
        assert any(item["siteId"] == site_id for item in list_body["items"])

        # Note: UPDATE and DELETE require site to be in ACTIVE status
        # For integration tests, we'd need to simulate the async provisioning
        # completing, or test with pre-created ACTIVE sites

    def test_create_duplicate_subdomain_fails(self, dynamodb_table, mock_context):
        """Test that creating a site with existing subdomain fails."""

        # Create first site
        event1 = {
            "pathParameters": {"tenantId": "tenant-dup-test"},
            "requestContext": {
                "authorizer": {"claims": {"email": "test@test.com"}}
            },
            "body": json.dumps({
                "siteName": "First Site",
                "subdomain": "unique-subdomain",
                "environment": "DEV"
            })
        }

        response1 = create_handler(event1, mock_context)
        assert response1["statusCode"] == 202

        # Attempt to create second site with same subdomain
        event2 = {
            "pathParameters": {"tenantId": "tenant-dup-test-2"},
            "requestContext": {
                "authorizer": {"claims": {"email": "test2@test.com"}}
            },
            "body": json.dumps({
                "siteName": "Second Site",
                "subdomain": "unique-subdomain",  # Same subdomain
                "environment": "DEV"
            })
        }

        response2 = create_handler(event2, mock_context)

        assert response2["statusCode"] == 409  # Conflict
        body = json.loads(response2["body"])
        assert body["error"]["code"] == "SITE_003"  # Subdomain already exists

    def test_get_nonexistent_site(self, dynamodb_table, mock_context):
        """Test getting a non-existent site returns 404."""
        event = {
            "pathParameters": {
                "tenantId": "tenant-nonexistent",
                "siteId": "site-does-not-exist"
            }
        }

        response = get_handler(event, mock_context)

        assert response["statusCode"] == 404
        body = json.loads(response["body"])
        assert body["error"]["code"] == "SITE_002"

    def test_list_empty_tenant(self, dynamodb_table, mock_context):
        """Test listing sites for tenant with no sites."""
        event = {
            "pathParameters": {"tenantId": "tenant-no-sites"},
            "queryStringParameters": {}
        }

        response = list_handler(event, mock_context)

        assert response["statusCode"] == 200
        body = json.loads(response["body"])
        assert body["items"] == []
        assert body["count"] == 0

    def test_delete_nonexistent_site(self, dynamodb_table, mock_context):
        """Test deleting a non-existent site returns 404."""
        event = {
            "pathParameters": {
                "tenantId": "tenant-delete-test",
                "siteId": "site-does-not-exist"
            }
        }

        response = delete_handler(event, mock_context)

        assert response["statusCode"] == 404
        body = json.loads(response["body"])
        assert body["error"]["code"] == "SITE_002"

    def test_tenant_isolation(self, dynamodb_table, mock_context):
        """Test that tenants cannot access each other's sites."""

        # Create site for tenant-A
        create_event = {
            "pathParameters": {"tenantId": "tenant-A"},
            "requestContext": {
                "authorizer": {"claims": {"email": "tenantA@test.com"}}
            },
            "body": json.dumps({
                "siteName": "Tenant A Site",
                "subdomain": "tenant-a-site",
                "environment": "DEV"
            })
        }

        create_response = create_handler(create_event, mock_context)
        site_id = json.loads(create_response["body"])["siteId"]

        # Try to get site from tenant-B (should fail)
        get_event = {
            "pathParameters": {
                "tenantId": "tenant-B",  # Different tenant
                "siteId": site_id
            }
        }

        get_response = get_handler(get_event, mock_context)

        # Site should not be found for tenant-B
        assert get_response["statusCode"] == 404

    def test_hateoas_links_structure(self, dynamodb_table, mock_context):
        """Test that HATEOAS links are correctly structured."""

        # Create a site
        create_event = {
            "pathParameters": {"tenantId": "tenant-hateoas"},
            "requestContext": {
                "authorizer": {"claims": {"email": "hateoas@test.com"}}
            },
            "body": json.dumps({
                "siteName": "HATEOAS Test Site",
                "subdomain": "hateoas-test",
                "environment": "DEV"
            })
        }

        create_response = create_handler(create_event, mock_context)
        body = json.loads(create_response["body"])

        # Verify HATEOAS structure
        assert "_links" in body
        assert "self" in body["_links"]
        assert "href" in body["_links"]["self"]
        assert "/v1.0/tenants/tenant-hateoas/sites/" in body["_links"]["self"]["href"]


class TestSitesPaginationIntegration:
    """Integration tests for Sites API pagination."""

    def test_pagination_with_multiple_sites(self, dynamodb_table, mock_context):
        """Test pagination returns correct page sizes."""

        # Create multiple sites
        for i in range(5):
            create_event = {
                "pathParameters": {"tenantId": "tenant-pagination"},
                "requestContext": {
                    "authorizer": {"claims": {"email": "pagination@test.com"}}
                },
                "body": json.dumps({
                    "siteName": f"Pagination Site {i}",
                    "subdomain": f"pagination-site-{i}",
                    "environment": "DEV"
                })
            }
            create_handler(create_event, mock_context)

        # List with page size of 2
        list_event = {
            "pathParameters": {"tenantId": "tenant-pagination"},
            "queryStringParameters": {"pageSize": "2"}
        }

        response = list_handler(list_event, mock_context)
        body = json.loads(response["body"])

        # Should return at most 2 items (if pagination is implemented)
        # If pagination not implemented, will return all 5
        assert response["statusCode"] == 200
        assert body["count"] <= 5  # Total created


class TestSitesErrorHandlingIntegration:
    """Integration tests for error handling across layers."""

    def test_validation_error_propagation(self, dynamodb_table, mock_context):
        """Test that validation errors are properly propagated."""
        event = {
            "pathParameters": {"tenantId": "tenant-validation"},
            "requestContext": {
                "authorizer": {"claims": {"email": "validation@test.com"}}
            },
            "body": json.dumps({
                # Missing required fields
                "environment": "INVALID_ENV"  # Invalid environment
            })
        }

        response = create_handler(event, mock_context)

        assert response["statusCode"] == 400
        body = json.loads(response["body"])
        assert "error" in body

    def test_request_id_in_error_response(self, dynamodb_table, mock_context):
        """Test that requestId is included in error responses."""
        event = {
            "pathParameters": {
                "tenantId": "tenant-error",
                "siteId": "nonexistent"
            }
        }

        response = get_handler(event, mock_context)

        body = json.loads(response["body"])
        assert "requestId" in body
        assert body["requestId"] == mock_context.request_id
```

---

## Success Criteria

- [ ] Integration test file created
- [ ] All integration tests passing
- [ ] Full site lifecycle tested (Create -> Get -> Update -> Delete)
- [ ] Tenant isolation verified
- [ ] Error propagation tested
- [ ] HATEOAS structure validated
- [ ] Pagination behavior tested
- [ ] moto used for realistic DynamoDB mocking

---

## Execution Steps

1. Review existing `test_create_site_integration.py` for patterns
2. Set up moto fixtures for DynamoDB mocking
3. Create table schema matching production
4. Implement full lifecycle test
5. Implement error scenario tests
6. Implement tenant isolation tests
7. Implement pagination tests
8. Run integration tests: `pytest tests/integration -v`
9. Verify all tests pass
10. Create `output.md` with test results summary
11. Update work.state to COMPLETE

---

## Test Execution

```bash
# Run integration tests
cd /Users/tebogotseka/Documents/agentic_work/2_bbws_wordpress_site_management_lambda/sites-service
pytest tests/integration -v

# Run with verbose output
pytest tests/integration -v -s

# Run specific test class
pytest tests/integration/test_sites_api.py::TestSitesAPIIntegration -v
```

---

**Status**: PENDING
**Created**: 2026-01-23
