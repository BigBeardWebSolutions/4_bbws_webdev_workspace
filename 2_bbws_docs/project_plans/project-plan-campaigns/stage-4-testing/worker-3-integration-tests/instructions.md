# Worker Instructions: Integration Tests

**Worker ID**: worker-3-integration-tests
**Stage**: Stage 4 - Testing
**Project**: project-plan-campaigns

---

## Task

Create integration tests that test the full API flow and CRUD operations.

---

## Deliverables

### Test Files

1. `tests/integration/test_campaign_api.py` - API endpoint tests
2. `tests/integration/test_campaign_crud_flow.py` - End-to-end CRUD flow

---

## Integration Test Strategy

Integration tests verify:
- Full request/response cycle
- Service and repository integration
- DynamoDB operations (using moto)
- Error propagation
- Business logic execution

---

## Example Tests

### tests/integration/test_campaign_api.py

```python
"""Integration tests for Campaign API."""

import pytest
import json
from decimal import Decimal
from datetime import datetime, timezone, timedelta

from moto import mock_dynamodb
import boto3

from src.handlers.list_campaigns import handler as list_handler
from src.handlers.get_campaign import handler as get_handler
from src.handlers.create_campaign import handler as create_handler
from src.handlers.update_campaign import handler as update_handler
from src.handlers.delete_campaign import handler as delete_handler


@pytest.fixture
def setup_dynamodb():
    """Setup DynamoDB table for integration tests."""
    with mock_dynamodb():
        dynamodb = boto3.resource("dynamodb", region_name="eu-west-1")

        table = dynamodb.create_table(
            TableName="test-campaigns-table",
            KeySchema=[
                {"AttributeName": "PK", "KeyType": "HASH"},
                {"AttributeName": "SK", "KeyType": "RANGE"},
            ],
            AttributeDefinitions=[
                {"AttributeName": "PK", "AttributeType": "S"},
                {"AttributeName": "SK", "AttributeType": "S"},
                {"AttributeName": "GSI1_PK", "AttributeType": "S"},
                {"AttributeName": "GSI1_SK", "AttributeType": "S"},
            ],
            GlobalSecondaryIndexes=[
                {
                    "IndexName": "CampaignsByStatusIndex",
                    "KeySchema": [
                        {"AttributeName": "GSI1_PK", "KeyType": "HASH"},
                        {"AttributeName": "GSI1_SK", "KeyType": "RANGE"},
                    ],
                    "Projection": {"ProjectionType": "ALL"},
                }
            ],
            BillingMode="PAY_PER_REQUEST",
        )
        table.wait_until_exists()
        yield table


class TestListCampaignsAPI:
    """Integration tests for list campaigns endpoint."""

    def test_list_empty_campaigns(self, setup_dynamodb, api_gateway_event, lambda_context):
        """Test listing when no campaigns exist."""
        response = list_handler(api_gateway_event, lambda_context)

        assert response["statusCode"] == 200
        body = json.loads(response["body"])
        assert body["campaigns"] == []
        assert body["count"] == 0

    def test_list_with_campaigns(self, setup_dynamodb, api_gateway_event, lambda_context):
        """Test listing when campaigns exist."""
        # Create a campaign first
        now = datetime.now(timezone.utc)
        setup_dynamodb.put_item(
            Item={
                "PK": "CAMPAIGN#TEST2025",
                "SK": "METADATA",
                "entityType": "CAMPAIGN",
                "code": "TEST2025",
                "name": "Test Campaign",
                "productId": "PROD-001",
                "discountPercent": 20,
                "listPrice": Decimal("100.00"),
                "price": Decimal("80.00"),
                "termsAndConditions": "Test terms.",
                "status": "ACTIVE",
                "fromDate": (now - timedelta(days=10)).isoformat(),
                "toDate": (now + timedelta(days=10)).isoformat(),
                "active": True,
                "GSI1_PK": "CAMPAIGN",
                "GSI1_SK": "ACTIVE#TEST2025",
            }
        )

        response = list_handler(api_gateway_event, lambda_context)

        assert response["statusCode"] == 200
        body = json.loads(response["body"])
        assert body["count"] == 1
        assert body["campaigns"][0]["code"] == "TEST2025"


class TestGetCampaignAPI:
    """Integration tests for get campaign endpoint."""

    def test_get_existing_campaign(self, setup_dynamodb, api_gateway_event, lambda_context):
        """Test getting an existing campaign."""
        now = datetime.now(timezone.utc)
        setup_dynamodb.put_item(
            Item={
                "PK": "CAMPAIGN#SUMMER2025",
                "SK": "METADATA",
                "entityType": "CAMPAIGN",
                "code": "SUMMER2025",
                "name": "Summer Sale",
                "productId": "PROD-001",
                "discountPercent": 25,
                "listPrice": Decimal("200.00"),
                "price": Decimal("150.00"),
                "termsAndConditions": "Summer sale terms.",
                "status": "ACTIVE",
                "fromDate": (now - timedelta(days=10)).isoformat(),
                "toDate": (now + timedelta(days=10)).isoformat(),
                "active": True,
                "GSI1_PK": "CAMPAIGN",
                "GSI1_SK": "ACTIVE#SUMMER2025",
            }
        )

        api_gateway_event["pathParameters"] = {"code": "SUMMER2025"}
        response = get_handler(api_gateway_event, lambda_context)

        assert response["statusCode"] == 200
        body = json.loads(response["body"])
        assert body["campaign"]["code"] == "SUMMER2025"
        assert body["campaign"]["discountPercent"] == 25

    def test_get_nonexistent_campaign(self, setup_dynamodb, api_gateway_event, lambda_context):
        """Test getting a campaign that doesn't exist."""
        api_gateway_event["pathParameters"] = {"code": "NONEXISTENT"}
        response = get_handler(api_gateway_event, lambda_context)

        assert response["statusCode"] == 404


class TestCreateCampaignAPI:
    """Integration tests for create campaign endpoint."""

    def test_create_new_campaign(self, setup_dynamodb, api_gateway_event, lambda_context):
        """Test creating a new campaign."""
        api_gateway_event["httpMethod"] = "POST"
        api_gateway_event["body"] = json.dumps({
            "code": "WINTER2025",
            "name": "Winter Sale",
            "productId": "PROD-001",
            "discountPercent": 30,
            "listPrice": 1000.00,
            "termsAndConditions": "Winter sale terms and conditions apply.",
            "fromDate": "2025-07-01T00:00:00Z",
            "toDate": "2025-08-31T23:59:59Z",
        })

        response = create_handler(api_gateway_event, lambda_context)

        assert response["statusCode"] == 201
        body = json.loads(response["body"])
        assert body["campaign"]["code"] == "WINTER2025"
        assert body["campaign"]["price"] == 700.00  # 30% off 1000


class TestUpdateCampaignAPI:
    """Integration tests for update campaign endpoint."""

    def test_update_existing_campaign(self, setup_dynamodb, api_gateway_event, lambda_context):
        """Test updating an existing campaign."""
        now = datetime.now(timezone.utc)
        setup_dynamodb.put_item(
            Item={
                "PK": "CAMPAIGN#UPDATE2025",
                "SK": "METADATA",
                "entityType": "CAMPAIGN",
                "code": "UPDATE2025",
                "name": "Original Name",
                "productId": "PROD-001",
                "discountPercent": 10,
                "listPrice": Decimal("100.00"),
                "price": Decimal("90.00"),
                "termsAndConditions": "Original terms.",
                "status": "ACTIVE",
                "fromDate": (now - timedelta(days=10)).isoformat(),
                "toDate": (now + timedelta(days=10)).isoformat(),
                "active": True,
                "GSI1_PK": "CAMPAIGN",
                "GSI1_SK": "ACTIVE#UPDATE2025",
            }
        )

        api_gateway_event["httpMethod"] = "PUT"
        api_gateway_event["pathParameters"] = {"code": "UPDATE2025"}
        api_gateway_event["body"] = json.dumps({"name": "Updated Name"})

        response = update_handler(api_gateway_event, lambda_context)

        assert response["statusCode"] == 200
        body = json.loads(response["body"])
        assert body["campaign"]["name"] == "Updated Name"


class TestDeleteCampaignAPI:
    """Integration tests for delete campaign endpoint."""

    def test_delete_existing_campaign(self, setup_dynamodb, api_gateway_event, lambda_context):
        """Test deleting an existing campaign."""
        now = datetime.now(timezone.utc)
        setup_dynamodb.put_item(
            Item={
                "PK": "CAMPAIGN#DELETE2025",
                "SK": "METADATA",
                "entityType": "CAMPAIGN",
                "code": "DELETE2025",
                "name": "To Delete",
                "productId": "PROD-001",
                "discountPercent": 10,
                "listPrice": Decimal("100.00"),
                "price": Decimal("90.00"),
                "termsAndConditions": "Terms to delete.",
                "status": "ACTIVE",
                "fromDate": (now - timedelta(days=10)).isoformat(),
                "toDate": (now + timedelta(days=10)).isoformat(),
                "active": True,
                "GSI1_PK": "CAMPAIGN",
                "GSI1_SK": "ACTIVE#DELETE2025",
            }
        )

        api_gateway_event["httpMethod"] = "DELETE"
        api_gateway_event["pathParameters"] = {"code": "DELETE2025"}

        response = delete_handler(api_gateway_event, lambda_context)

        assert response["statusCode"] == 204
```

### tests/integration/test_campaign_crud_flow.py

```python
"""End-to-end CRUD flow integration tests."""

import pytest
import json
from decimal import Decimal

from moto import mock_dynamodb
import boto3

from src.handlers.create_campaign import handler as create_handler
from src.handlers.get_campaign import handler as get_handler
from src.handlers.update_campaign import handler as update_handler
from src.handlers.delete_campaign import handler as delete_handler
from src.handlers.list_campaigns import handler as list_handler


class TestCampaignCRUDFlow:
    """End-to-end CRUD flow tests."""

    @pytest.fixture
    def setup_env(self, setup_dynamodb, api_gateway_event, lambda_context):
        """Setup test environment."""
        return {
            "table": setup_dynamodb,
            "event": api_gateway_event,
            "context": lambda_context,
        }

    def test_full_crud_flow(self, setup_env):
        """Test complete Create -> Read -> Update -> Delete flow."""
        event = setup_env["event"]
        context = setup_env["context"]

        # 1. CREATE
        event["httpMethod"] = "POST"
        event["body"] = json.dumps({
            "code": "FLOW2025",
            "name": "Flow Test Campaign",
            "productId": "PROD-001",
            "discountPercent": 20,
            "listPrice": 500.00,
            "termsAndConditions": "Flow test terms and conditions apply.",
            "fromDate": "2025-06-01T00:00:00Z",
            "toDate": "2025-12-31T23:59:59Z",
        })

        create_response = create_handler(event, context)
        assert create_response["statusCode"] == 201

        created = json.loads(create_response["body"])["campaign"]
        assert created["code"] == "FLOW2025"
        assert created["price"] == 400.00  # 20% off 500

        # 2. READ
        event["httpMethod"] = "GET"
        event["pathParameters"] = {"code": "FLOW2025"}
        event["body"] = None

        get_response = get_handler(event, context)
        assert get_response["statusCode"] == 200

        retrieved = json.loads(get_response["body"])["campaign"]
        assert retrieved["code"] == "FLOW2025"

        # 3. UPDATE
        event["httpMethod"] = "PUT"
        event["body"] = json.dumps({
            "name": "Updated Flow Test",
            "discountPercent": 30,
        })

        update_response = update_handler(event, context)
        assert update_response["statusCode"] == 200

        updated = json.loads(update_response["body"])["campaign"]
        assert updated["name"] == "Updated Flow Test"
        assert updated["price"] == 350.00  # 30% off 500

        # 4. LIST (should include updated campaign)
        event["httpMethod"] = "GET"
        event["pathParameters"] = None
        event["body"] = None

        list_response = list_handler(event, context)
        assert list_response["statusCode"] == 200

        campaigns = json.loads(list_response["body"])["campaigns"]
        assert any(c["code"] == "FLOW2025" for c in campaigns)

        # 5. DELETE
        event["httpMethod"] = "DELETE"
        event["pathParameters"] = {"code": "FLOW2025"}

        delete_response = delete_handler(event, context)
        assert delete_response["statusCode"] == 204

        # 6. VERIFY DELETED (should return 404)
        event["httpMethod"] = "GET"

        get_deleted_response = get_handler(event, context)
        assert get_deleted_response["statusCode"] == 404
```

---

## Success Criteria

- [ ] API endpoint tests created
- [ ] CRUD flow test created
- [ ] All handlers tested together
- [ ] DynamoDB integration tested
- [ ] Error propagation verified
- [ ] All integration tests pass

---

## Execution Steps

1. Create test_campaign_api.py
2. Create test_campaign_crud_flow.py
3. Setup mocked DynamoDB
4. Test full API request/response cycle
5. Test CRUD flow end-to-end
6. Run integration tests
7. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-15
