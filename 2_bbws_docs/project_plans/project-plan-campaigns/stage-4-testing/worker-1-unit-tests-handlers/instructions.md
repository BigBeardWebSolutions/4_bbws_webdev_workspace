# Worker Instructions: Unit Tests - Handlers

**Worker ID**: worker-1-unit-tests-handlers
**Stage**: Stage 4 - Testing
**Project**: project-plan-campaigns

---

## Task

Create comprehensive unit tests for all 5 Lambda handler functions.

---

## Deliverables

Create unit test files for each handler in `tests/unit/handlers/`:

### Test Coverage Requirements

| Handler | Test Scenarios |
|---------|---------------|
| list_campaigns | Success, with status filter, invalid status, empty result, error handling |
| get_campaign | Success, not found, missing code, inactive campaign, error handling |
| create_campaign | Success, validation errors, duplicate code, error handling |
| update_campaign | Success, not found, no fields, validation errors, error handling |
| delete_campaign | Success, not found, missing code, error handling |

### Test File Template

Each test file should include:
- Test class for the handler
- Mock service layer
- Test for successful response
- Tests for error scenarios
- Tests for input validation

---

## Example Test Structure

### tests/unit/handlers/test_create_campaign.py

```python
"""Unit tests for create_campaign handler."""

import pytest
import json
from decimal import Decimal
from unittest.mock import patch, MagicMock

from src.handlers.create_campaign import handler
from src.exceptions.campaign_exceptions import (
    DuplicateCampaignException,
    ValidationException,
    DatabaseException,
)


class TestCreateCampaignHandler:
    """Tests for create_campaign handler."""

    @pytest.fixture
    def valid_request_body(self):
        """Valid campaign creation request."""
        return {
            "code": "WINTER2025",
            "name": "Winter Sale",
            "productId": "PROD-001",
            "discountPercent": 25,
            "listPrice": 1000.00,
            "termsAndConditions": "Valid for all customers. Minimum purchase required.",
            "fromDate": "2025-07-01T00:00:00Z",
            "toDate": "2025-08-31T23:59:59Z",
        }

    @patch("src.handlers.create_campaign.CampaignService")
    def test_create_campaign_success(
        self, mock_service_class, valid_request_body, api_gateway_event, lambda_context
    ):
        """Test successful campaign creation."""
        # Setup
        api_gateway_event["body"] = json.dumps(valid_request_body)
        api_gateway_event["httpMethod"] = "POST"

        mock_campaign = MagicMock()
        mock_campaign.model_dump.return_value = {
            "code": "WINTER2025",
            "name": "Winter Sale",
            "price": 750.00,
        }

        mock_service = MagicMock()
        mock_service.create_campaign.return_value = mock_campaign
        mock_service_class.return_value = mock_service

        # Execute
        response = handler(api_gateway_event, lambda_context)

        # Verify
        assert response["statusCode"] == 201
        body = json.loads(response["body"])
        assert "campaign" in body
        assert body["campaign"]["code"] == "WINTER2025"

    def test_create_campaign_missing_body(self, api_gateway_event, lambda_context):
        """Test create with missing request body."""
        api_gateway_event["body"] = None
        api_gateway_event["httpMethod"] = "POST"

        response = handler(api_gateway_event, lambda_context)

        assert response["statusCode"] == 400
        body = json.loads(response["body"])
        assert "Request body is required" in body["message"]

    def test_create_campaign_invalid_json(self, api_gateway_event, lambda_context):
        """Test create with invalid JSON."""
        api_gateway_event["body"] = "not valid json"
        api_gateway_event["httpMethod"] = "POST"

        response = handler(api_gateway_event, lambda_context)

        assert response["statusCode"] == 400

    @patch("src.handlers.create_campaign.CampaignService")
    def test_create_campaign_validation_error(
        self, mock_service_class, api_gateway_event, lambda_context
    ):
        """Test create with validation error."""
        invalid_body = {
            "code": "W",  # Too short
            "name": "Winter Sale",
            "productId": "PROD-001",
            "discountPercent": 150,  # Over 100
            "listPrice": 1000.00,
            "termsAndConditions": "Too short",  # Less than 10 chars
            "fromDate": "2025-07-01T00:00:00Z",
            "toDate": "2025-06-01T00:00:00Z",  # Before fromDate
        }
        api_gateway_event["body"] = json.dumps(invalid_body)
        api_gateway_event["httpMethod"] = "POST"

        response = handler(api_gateway_event, lambda_context)

        assert response["statusCode"] == 400
        body = json.loads(response["body"])
        assert "errors" in body or "Validation" in body.get("message", "")

    @patch("src.handlers.create_campaign.CampaignService")
    def test_create_campaign_duplicate(
        self, mock_service_class, valid_request_body, api_gateway_event, lambda_context
    ):
        """Test create with duplicate campaign code."""
        api_gateway_event["body"] = json.dumps(valid_request_body)
        api_gateway_event["httpMethod"] = "POST"

        mock_service = MagicMock()
        mock_service.create_campaign.side_effect = DuplicateCampaignException("WINTER2025")
        mock_service_class.return_value = mock_service

        response = handler(api_gateway_event, lambda_context)

        assert response["statusCode"] == 400
        body = json.loads(response["body"])
        assert "already exists" in body["message"]

    @patch("src.handlers.create_campaign.CampaignService")
    def test_create_campaign_database_error(
        self, mock_service_class, valid_request_body, api_gateway_event, lambda_context
    ):
        """Test create with database error."""
        api_gateway_event["body"] = json.dumps(valid_request_body)
        api_gateway_event["httpMethod"] = "POST"

        mock_service = MagicMock()
        mock_service.create_campaign.side_effect = DatabaseException("Connection failed")
        mock_service_class.return_value = mock_service

        response = handler(api_gateway_event, lambda_context)

        assert response["statusCode"] == 500

    @patch("src.handlers.create_campaign.CampaignService")
    def test_create_campaign_unexpected_error(
        self, mock_service_class, valid_request_body, api_gateway_event, lambda_context
    ):
        """Test create with unexpected error."""
        api_gateway_event["body"] = json.dumps(valid_request_body)
        api_gateway_event["httpMethod"] = "POST"

        mock_service = MagicMock()
        mock_service.create_campaign.side_effect = Exception("Unexpected error")
        mock_service_class.return_value = mock_service

        response = handler(api_gateway_event, lambda_context)

        assert response["statusCode"] == 500
```

---

## Success Criteria

- [ ] All 5 handler test files created
- [ ] Each handler has 5+ test cases
- [ ] Success scenarios covered
- [ ] Error scenarios covered
- [ ] Input validation tested
- [ ] Edge cases tested
- [ ] All tests pass

---

## Execution Steps

1. Create test_list_campaigns.py
2. Create test_get_campaign.py
3. Create test_create_campaign.py
4. Create test_update_campaign.py
5. Create test_delete_campaign.py
6. Run all handler tests
7. Verify coverage > 80%
8. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-15
