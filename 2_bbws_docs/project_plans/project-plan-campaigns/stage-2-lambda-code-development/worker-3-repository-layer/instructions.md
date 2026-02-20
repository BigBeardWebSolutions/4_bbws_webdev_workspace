# Worker Instructions: Repository Layer

**Worker ID**: worker-3-repository-layer
**Stage**: Stage 2 - Lambda Code Development
**Project**: project-plan-campaigns

---

## Task

Create the CampaignRepository class for DynamoDB CRUD operations.

---

## Inputs

**Primary Input**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/2.1.3_LLD_Campaigns_Lambda.md`

**Reference**:
- Section 3: Component Diagram (CampaignRepository)
- Section 5.1: DynamoDB Schema

---

## Deliverables

### CampaignRepository (src/repositories/campaign_repository.py)

```python
"""Repository for Campaign data access operations."""

import os
from typing import Optional, List, Dict, Any
from decimal import Decimal
from datetime import datetime, timezone

import boto3
from boto3.dynamodb.conditions import Key, Attr
from botocore.exceptions import ClientError

from src.models.campaign import Campaign, CampaignStatus
from src.exceptions.campaign_exceptions import (
    CampaignNotFoundException,
    DuplicateCampaignException,
    DatabaseException,
)
from src.utils.logger import get_logger


logger = get_logger(__name__)


class CampaignRepository:
    """Repository for Campaign DynamoDB operations."""

    def __init__(self, table_name: Optional[str] = None):
        """Initialize repository with DynamoDB table.

        Args:
            table_name: DynamoDB table name. Defaults to env variable.
        """
        self.table_name = table_name or os.environ.get("CAMPAIGNS_TABLE_NAME")
        if not self.table_name:
            raise ValueError("CAMPAIGNS_TABLE_NAME environment variable not set")

        self.dynamodb = boto3.resource("dynamodb")
        self.table = self.dynamodb.Table(self.table_name)
        logger.info(f"CampaignRepository initialized with table: {self.table_name}")

    def _build_pk(self, code: str) -> str:
        """Build partition key for campaign."""
        return f"CAMPAIGN#{code}"

    def _build_sk(self) -> str:
        """Build sort key for campaign metadata."""
        return "METADATA"

    def _build_gsi1_pk(self) -> str:
        """Build GSI1 partition key."""
        return "CAMPAIGN"

    def _build_gsi1_sk(self, status: str, code: str) -> str:
        """Build GSI1 sort key."""
        return f"{status}#{code}"

    def find_all(self, active_only: bool = True) -> List[Dict[str, Any]]:
        """Find all campaigns.

        Args:
            active_only: If True, only return active campaigns.

        Returns:
            List of campaign dictionaries.
        """
        try:
            scan_kwargs = {}
            if active_only:
                scan_kwargs["FilterExpression"] = Attr("active").eq(True)

            response = self.table.scan(**scan_kwargs)
            items = response.get("Items", [])

            # Handle pagination
            while "LastEvaluatedKey" in response:
                scan_kwargs["ExclusiveStartKey"] = response["LastEvaluatedKey"]
                response = self.table.scan(**scan_kwargs)
                items.extend(response.get("Items", []))

            logger.info(f"Found {len(items)} campaigns")
            return items

        except ClientError as e:
            logger.error(f"Error scanning campaigns: {e}")
            raise DatabaseException("Failed to retrieve campaigns", e)

    def find_by_code(self, code: str) -> Optional[Dict[str, Any]]:
        """Find campaign by code.

        Args:
            code: Campaign code.

        Returns:
            Campaign dictionary or None if not found.
        """
        try:
            response = self.table.get_item(
                Key={
                    "PK": self._build_pk(code),
                    "SK": self._build_sk(),
                }
            )
            item = response.get("Item")

            if item:
                logger.info(f"Found campaign: {code}")
            else:
                logger.info(f"Campaign not found: {code}")

            return item

        except ClientError as e:
            logger.error(f"Error getting campaign {code}: {e}")
            raise DatabaseException(f"Failed to retrieve campaign {code}", e)

    def find_by_status(self, status: CampaignStatus) -> List[Dict[str, Any]]:
        """Find campaigns by status using GSI.

        Args:
            status: Campaign status to filter by.

        Returns:
            List of campaign dictionaries.
        """
        try:
            response = self.table.query(
                IndexName="CampaignsByStatusIndex",
                KeyConditionExpression=Key("GSI1_PK").eq(self._build_gsi1_pk())
                & Key("GSI1_SK").begins_with(f"{status.value}#"),
                FilterExpression=Attr("active").eq(True),
            )
            items = response.get("Items", [])
            logger.info(f"Found {len(items)} campaigns with status {status}")
            return items

        except ClientError as e:
            logger.error(f"Error querying campaigns by status: {e}")
            raise DatabaseException(f"Failed to query campaigns by status {status}", e)

    def create(self, campaign_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create a new campaign.

        Args:
            campaign_data: Campaign data dictionary.

        Returns:
            Created campaign dictionary.

        Raises:
            DuplicateCampaignException: If campaign code already exists.
        """
        code = campaign_data["code"]

        # Check if campaign already exists
        existing = self.find_by_code(code)
        if existing:
            raise DuplicateCampaignException(code)

        now = datetime.now(timezone.utc).isoformat()

        item = {
            "PK": self._build_pk(code),
            "SK": self._build_sk(),
            "entityType": "CAMPAIGN",
            **campaign_data,
            "dateCreated": now,
            "dateLastUpdated": now,
            "lastUpdatedBy": campaign_data.get("lastUpdatedBy", "system"),
            "active": True,
            "GSI1_PK": self._build_gsi1_pk(),
            "GSI1_SK": self._build_gsi1_sk(campaign_data.get("status", "DRAFT"), code),
        }

        try:
            self.table.put_item(
                Item=item,
                ConditionExpression="attribute_not_exists(PK)",
            )
            logger.info(f"Created campaign: {code}")
            return item

        except ClientError as e:
            if e.response["Error"]["Code"] == "ConditionalCheckFailedException":
                raise DuplicateCampaignException(code)
            logger.error(f"Error creating campaign {code}: {e}")
            raise DatabaseException(f"Failed to create campaign {code}", e)

    def update(self, code: str, update_data: Dict[str, Any]) -> Dict[str, Any]:
        """Update an existing campaign.

        Args:
            code: Campaign code.
            update_data: Fields to update.

        Returns:
            Updated campaign dictionary.

        Raises:
            CampaignNotFoundException: If campaign doesn't exist.
        """
        # Build update expression
        update_parts = []
        expression_values = {}
        expression_names = {}

        now = datetime.now(timezone.utc).isoformat()
        update_data["dateLastUpdated"] = now

        for key, value in update_data.items():
            if value is not None:
                safe_key = f"#{key}"
                safe_value = f":{key}"
                update_parts.append(f"{safe_key} = {safe_value}")
                expression_values[safe_value] = value
                expression_names[safe_key] = key

        # Update GSI1_SK if status changed
        if "status" in update_data:
            gsi1_sk = self._build_gsi1_sk(update_data["status"], code)
            update_parts.append("#GSI1_SK = :gsi1sk")
            expression_values[":gsi1sk"] = gsi1_sk
            expression_names["#GSI1_SK"] = "GSI1_SK"

        update_expression = "SET " + ", ".join(update_parts)

        try:
            response = self.table.update_item(
                Key={
                    "PK": self._build_pk(code),
                    "SK": self._build_sk(),
                },
                UpdateExpression=update_expression,
                ExpressionAttributeValues=expression_values,
                ExpressionAttributeNames=expression_names,
                ConditionExpression="attribute_exists(PK)",
                ReturnValues="ALL_NEW",
            )
            logger.info(f"Updated campaign: {code}")
            return response.get("Attributes", {})

        except ClientError as e:
            if e.response["Error"]["Code"] == "ConditionalCheckFailedException":
                raise CampaignNotFoundException(code)
            logger.error(f"Error updating campaign {code}: {e}")
            raise DatabaseException(f"Failed to update campaign {code}", e)

    def soft_delete(self, code: str) -> bool:
        """Soft delete a campaign by setting active to False.

        Args:
            code: Campaign code.

        Returns:
            True if deleted successfully.

        Raises:
            CampaignNotFoundException: If campaign doesn't exist.
        """
        try:
            now = datetime.now(timezone.utc).isoformat()
            self.table.update_item(
                Key={
                    "PK": self._build_pk(code),
                    "SK": self._build_sk(),
                },
                UpdateExpression="SET #active = :active, #updated = :updated",
                ExpressionAttributeValues={
                    ":active": False,
                    ":updated": now,
                },
                ExpressionAttributeNames={
                    "#active": "active",
                    "#updated": "dateLastUpdated",
                },
                ConditionExpression="attribute_exists(PK)",
            )
            logger.info(f"Soft deleted campaign: {code}")
            return True

        except ClientError as e:
            if e.response["Error"]["Code"] == "ConditionalCheckFailedException":
                raise CampaignNotFoundException(code)
            logger.error(f"Error deleting campaign {code}: {e}")
            raise DatabaseException(f"Failed to delete campaign {code}", e)

    def exists(self, code: str) -> bool:
        """Check if a campaign exists.

        Args:
            code: Campaign code.

        Returns:
            True if campaign exists and is active.
        """
        item = self.find_by_code(code)
        return item is not None and item.get("active", False)
```

---

## Unit Tests (TDD Approach)

### tests/unit/repositories/test_campaign_repository.py

```python
"""Unit tests for CampaignRepository."""

import pytest
from decimal import Decimal
from unittest.mock import MagicMock, patch

from src.repositories.campaign_repository import CampaignRepository
from src.exceptions.campaign_exceptions import (
    CampaignNotFoundException,
    DuplicateCampaignException,
    DatabaseException,
)


class TestCampaignRepository:
    """Tests for CampaignRepository."""

    def test_find_all_returns_campaigns(self, dynamodb_table, sample_campaign_item):
        """Test find_all returns all active campaigns."""
        # Setup
        dynamodb_table.put_item(Item=sample_campaign_item)

        # Execute
        repo = CampaignRepository(table_name="test-campaigns-table")
        result = repo.find_all()

        # Verify
        assert len(result) == 1
        assert result[0]["code"] == "SUMMER2025"

    def test_find_all_filters_inactive(self, dynamodb_table, sample_campaign_item):
        """Test find_all excludes inactive campaigns."""
        # Setup
        inactive_item = {**sample_campaign_item, "active": False}
        dynamodb_table.put_item(Item=inactive_item)

        # Execute
        repo = CampaignRepository(table_name="test-campaigns-table")
        result = repo.find_all(active_only=True)

        # Verify
        assert len(result) == 0

    def test_find_by_code_returns_campaign(self, dynamodb_table, sample_campaign_item):
        """Test find_by_code returns campaign when found."""
        # Setup
        dynamodb_table.put_item(Item=sample_campaign_item)

        # Execute
        repo = CampaignRepository(table_name="test-campaigns-table")
        result = repo.find_by_code("SUMMER2025")

        # Verify
        assert result is not None
        assert result["code"] == "SUMMER2025"

    def test_find_by_code_returns_none_when_not_found(self, dynamodb_table):
        """Test find_by_code returns None when campaign not found."""
        repo = CampaignRepository(table_name="test-campaigns-table")
        result = repo.find_by_code("NONEXISTENT")
        assert result is None

    def test_create_success(self, dynamodb_table, sample_campaign_data):
        """Test create successfully creates campaign."""
        repo = CampaignRepository(table_name="test-campaigns-table")
        campaign_data = {
            **sample_campaign_data,
            "status": "ACTIVE",
            "price": Decimal("1200.00"),
        }

        result = repo.create(campaign_data)

        assert result["code"] == "SUMMER2025"
        assert result["entityType"] == "CAMPAIGN"
        assert "dateCreated" in result
        assert result["active"] is True

    def test_create_duplicate_raises_exception(
        self, dynamodb_table, sample_campaign_item
    ):
        """Test create raises exception for duplicate code."""
        dynamodb_table.put_item(Item=sample_campaign_item)

        repo = CampaignRepository(table_name="test-campaigns-table")
        campaign_data = {
            "code": "SUMMER2025",  # Same code
            "name": "Another Campaign",
            "productId": "PROD-001",
            "discountPercent": 10,
            "listPrice": Decimal("100.00"),
            "price": Decimal("90.00"),
            "status": "DRAFT",
            "termsAndConditions": "Some terms",
            "fromDate": "2025-01-01T00:00:00Z",
            "toDate": "2025-12-31T23:59:59Z",
        }

        with pytest.raises(DuplicateCampaignException):
            repo.create(campaign_data)

    def test_update_success(self, dynamodb_table, sample_campaign_item):
        """Test update successfully updates campaign."""
        dynamodb_table.put_item(Item=sample_campaign_item)

        repo = CampaignRepository(table_name="test-campaigns-table")
        result = repo.update("SUMMER2025", {"name": "Updated Name"})

        assert result["name"] == "Updated Name"
        assert "dateLastUpdated" in result

    def test_update_not_found_raises_exception(self, dynamodb_table):
        """Test update raises exception when campaign not found."""
        repo = CampaignRepository(table_name="test-campaigns-table")

        with pytest.raises(CampaignNotFoundException):
            repo.update("NONEXISTENT", {"name": "New Name"})

    def test_soft_delete_success(self, dynamodb_table, sample_campaign_item):
        """Test soft_delete sets active to False."""
        dynamodb_table.put_item(Item=sample_campaign_item)

        repo = CampaignRepository(table_name="test-campaigns-table")
        result = repo.soft_delete("SUMMER2025")

        assert result is True

        # Verify item is now inactive
        item = repo.find_by_code("SUMMER2025")
        assert item["active"] is False

    def test_soft_delete_not_found_raises_exception(self, dynamodb_table):
        """Test soft_delete raises exception when campaign not found."""
        repo = CampaignRepository(table_name="test-campaigns-table")

        with pytest.raises(CampaignNotFoundException):
            repo.soft_delete("NONEXISTENT")

    def test_exists_returns_true_for_active(
        self, dynamodb_table, sample_campaign_item
    ):
        """Test exists returns True for active campaign."""
        dynamodb_table.put_item(Item=sample_campaign_item)

        repo = CampaignRepository(table_name="test-campaigns-table")
        assert repo.exists("SUMMER2025") is True

    def test_exists_returns_false_for_inactive(
        self, dynamodb_table, sample_campaign_item
    ):
        """Test exists returns False for inactive campaign."""
        inactive_item = {**sample_campaign_item, "active": False}
        dynamodb_table.put_item(Item=inactive_item)

        repo = CampaignRepository(table_name="test-campaigns-table")
        assert repo.exists("SUMMER2025") is False
```

---

## Success Criteria

- [ ] CampaignRepository class implements all methods
- [ ] find_all() retrieves campaigns with pagination
- [ ] find_by_code() uses PK/SK pattern
- [ ] find_by_status() uses GSI query
- [ ] create() checks for duplicates
- [ ] update() uses conditional expressions
- [ ] soft_delete() sets active=false
- [ ] All unit tests pass with moto

---

## Execution Steps

1. Write unit tests for repository (TDD)
2. Create src/repositories/campaign_repository.py
3. Implement all CRUD methods
4. Handle DynamoDB errors properly
5. Run tests to verify implementation
6. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-15
