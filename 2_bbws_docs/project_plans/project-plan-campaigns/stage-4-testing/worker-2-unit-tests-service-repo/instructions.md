# Worker Instructions: Unit Tests - Service & Repository

**Worker ID**: worker-2-unit-tests-service-repo
**Stage**: Stage 4 - Testing
**Project**: project-plan-campaigns

---

## Task

Create comprehensive unit tests for CampaignService and CampaignRepository layers.

---

## Deliverables

### Test Files

1. `tests/unit/services/test_campaign_service.py`
2. `tests/unit/repositories/test_campaign_repository.py`

### Service Layer Tests

| Method | Test Scenarios |
|--------|---------------|
| list_campaigns | All campaigns, with status filter, empty result |
| get_campaign | Found, not found, inactive |
| create_campaign | Success, calculates price, determines status |
| update_campaign | Success, partial update, recalculates price |
| delete_campaign | Success, not found |
| _calculate_price | Various discount percentages |
| _determine_status | DRAFT, ACTIVE, EXPIRED |

### Repository Layer Tests

| Method | Test Scenarios |
|--------|---------------|
| find_all | Returns campaigns, filters inactive, pagination |
| find_by_code | Found, not found |
| find_by_status | Query by status using GSI |
| create | Success, duplicate code |
| update | Success, not found, conditional update |
| soft_delete | Success, not found |
| exists | Active, inactive, not found |

---

## Example Tests

### tests/unit/repositories/test_campaign_repository.py (Complete)

```python
"""Unit tests for CampaignRepository."""

import pytest
from decimal import Decimal
from moto import mock_dynamodb
import boto3

from src.repositories.campaign_repository import CampaignRepository
from src.exceptions.campaign_exceptions import (
    CampaignNotFoundException,
    DuplicateCampaignException,
    DatabaseException,
)


@pytest.fixture
def dynamodb_client(aws_credentials):
    """Create mocked DynamoDB client."""
    with mock_dynamodb():
        yield boto3.client("dynamodb", region_name="eu-west-1")


@pytest.fixture
def campaigns_table(dynamodb_client):
    """Create campaigns table."""
    dynamodb_client.create_table(
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
    yield
    dynamodb_client.delete_table(TableName="test-campaigns-table")


class TestCampaignRepositoryFindAll:
    """Tests for find_all method."""

    def test_find_all_returns_empty_list(self, campaigns_table):
        """Test find_all returns empty list when no campaigns."""
        repo = CampaignRepository(table_name="test-campaigns-table")
        result = repo.find_all()
        assert result == []

    def test_find_all_returns_active_campaigns(
        self, campaigns_table, sample_campaign_item
    ):
        """Test find_all returns active campaigns."""
        # Setup
        dynamodb = boto3.resource("dynamodb", region_name="eu-west-1")
        table = dynamodb.Table("test-campaigns-table")
        table.put_item(Item=sample_campaign_item)

        # Execute
        repo = CampaignRepository(table_name="test-campaigns-table")
        result = repo.find_all()

        # Verify
        assert len(result) == 1
        assert result[0]["code"] == "SUMMER2025"

    def test_find_all_excludes_inactive(self, campaigns_table, sample_campaign_item):
        """Test find_all excludes inactive campaigns."""
        # Setup
        inactive_item = {**sample_campaign_item, "active": False}
        dynamodb = boto3.resource("dynamodb", region_name="eu-west-1")
        table = dynamodb.Table("test-campaigns-table")
        table.put_item(Item=inactive_item)

        # Execute
        repo = CampaignRepository(table_name="test-campaigns-table")
        result = repo.find_all(active_only=True)

        # Verify
        assert len(result) == 0


class TestCampaignRepositoryFindByCode:
    """Tests for find_by_code method."""

    def test_find_by_code_returns_campaign(
        self, campaigns_table, sample_campaign_item
    ):
        """Test find_by_code returns campaign when found."""
        # Setup
        dynamodb = boto3.resource("dynamodb", region_name="eu-west-1")
        table = dynamodb.Table("test-campaigns-table")
        table.put_item(Item=sample_campaign_item)

        # Execute
        repo = CampaignRepository(table_name="test-campaigns-table")
        result = repo.find_by_code("SUMMER2025")

        # Verify
        assert result is not None
        assert result["code"] == "SUMMER2025"

    def test_find_by_code_returns_none_when_not_found(self, campaigns_table):
        """Test find_by_code returns None when not found."""
        repo = CampaignRepository(table_name="test-campaigns-table")
        result = repo.find_by_code("NONEXISTENT")
        assert result is None


class TestCampaignRepositoryCreate:
    """Tests for create method."""

    def test_create_success(self, campaigns_table):
        """Test create successfully creates campaign."""
        repo = CampaignRepository(table_name="test-campaigns-table")

        campaign_data = {
            "code": "WINTER2025",
            "name": "Winter Sale",
            "productId": "PROD-001",
            "discountPercent": 20,
            "listPrice": Decimal("100.00"),
            "price": Decimal("80.00"),
            "status": "DRAFT",
            "termsAndConditions": "Valid terms here.",
            "fromDate": "2025-07-01T00:00:00Z",
            "toDate": "2025-08-31T23:59:59Z",
        }

        result = repo.create(campaign_data)

        assert result["code"] == "WINTER2025"
        assert result["entityType"] == "CAMPAIGN"
        assert "dateCreated" in result
        assert result["active"] is True

    def test_create_duplicate_raises_exception(
        self, campaigns_table, sample_campaign_item
    ):
        """Test create raises exception for duplicate code."""
        dynamodb = boto3.resource("dynamodb", region_name="eu-west-1")
        table = dynamodb.Table("test-campaigns-table")
        table.put_item(Item=sample_campaign_item)

        repo = CampaignRepository(table_name="test-campaigns-table")

        campaign_data = {
            "code": "SUMMER2025",  # Same as existing
            "name": "Another Campaign",
            "productId": "PROD-001",
            "discountPercent": 10,
            "listPrice": Decimal("100.00"),
            "price": Decimal("90.00"),
            "status": "DRAFT",
            "termsAndConditions": "Valid terms.",
            "fromDate": "2025-01-01T00:00:00Z",
            "toDate": "2025-12-31T23:59:59Z",
        }

        with pytest.raises(DuplicateCampaignException):
            repo.create(campaign_data)


class TestCampaignRepositoryUpdate:
    """Tests for update method."""

    def test_update_success(self, campaigns_table, sample_campaign_item):
        """Test update successfully updates campaign."""
        dynamodb = boto3.resource("dynamodb", region_name="eu-west-1")
        table = dynamodb.Table("test-campaigns-table")
        table.put_item(Item=sample_campaign_item)

        repo = CampaignRepository(table_name="test-campaigns-table")
        result = repo.update("SUMMER2025", {"name": "Updated Name"})

        assert result["name"] == "Updated Name"

    def test_update_not_found_raises_exception(self, campaigns_table):
        """Test update raises exception when not found."""
        repo = CampaignRepository(table_name="test-campaigns-table")

        with pytest.raises(CampaignNotFoundException):
            repo.update("NONEXISTENT", {"name": "New Name"})


class TestCampaignRepositorySoftDelete:
    """Tests for soft_delete method."""

    def test_soft_delete_success(self, campaigns_table, sample_campaign_item):
        """Test soft_delete sets active to False."""
        dynamodb = boto3.resource("dynamodb", region_name="eu-west-1")
        table = dynamodb.Table("test-campaigns-table")
        table.put_item(Item=sample_campaign_item)

        repo = CampaignRepository(table_name="test-campaigns-table")
        result = repo.soft_delete("SUMMER2025")

        assert result is True

        # Verify item is now inactive
        item = repo.find_by_code("SUMMER2025")
        assert item["active"] is False

    def test_soft_delete_not_found_raises_exception(self, campaigns_table):
        """Test soft_delete raises exception when not found."""
        repo = CampaignRepository(table_name="test-campaigns-table")

        with pytest.raises(CampaignNotFoundException):
            repo.soft_delete("NONEXISTENT")
```

---

## Success Criteria

- [ ] Service test file created
- [ ] Repository test file created
- [ ] All service methods tested
- [ ] All repository methods tested
- [ ] Price calculation tested
- [ ] Status determination tested
- [ ] Error handling tested
- [ ] All tests pass

---

## Execution Steps

1. Create test_campaign_service.py
2. Create test_campaign_repository.py
3. Mock DynamoDB using moto
4. Test all CRUD operations
5. Test business logic
6. Run tests and verify coverage
7. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-15
