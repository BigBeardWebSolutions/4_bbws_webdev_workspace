# Worker Instructions: Service Layer

**Worker ID**: worker-4-service-layer
**Stage**: Stage 2 - Lambda Code Development
**Project**: project-plan-campaigns

---

## Task

Create the CampaignService class with business logic for campaign operations.

---

## Inputs

**Primary Input**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/2.1.3_LLD_Campaigns_Lambda.md`

**Reference**:
- Section 3: Component Diagram (CampaignService)
- Section 5: Data Models
- Section 6: REST API Operations (Business Rules)

---

## Deliverables

### CampaignService (src/services/campaign_service.py)

```python
"""Service layer for Campaign business logic."""

from typing import Optional, List, Dict, Any
from decimal import Decimal, ROUND_HALF_UP
from datetime import datetime, timezone

from src.repositories.campaign_repository import CampaignRepository
from src.models.campaign import (
    Campaign,
    CampaignStatus,
    CampaignResponse,
    CampaignListResponse,
    CreateCampaignRequest,
    UpdateCampaignRequest,
)
from src.exceptions.campaign_exceptions import (
    CampaignNotFoundException,
    ValidationException,
)
from src.utils.logger import get_logger


logger = get_logger(__name__)


class CampaignService:
    """Service for Campaign business operations."""

    def __init__(self, repository: Optional[CampaignRepository] = None):
        """Initialize service with repository.

        Args:
            repository: CampaignRepository instance. Creates new if not provided.
        """
        self.repository = repository or CampaignRepository()

    def list_campaigns(self, status_filter: Optional[CampaignStatus] = None) -> CampaignListResponse:
        """List all active campaigns.

        Args:
            status_filter: Optional status to filter by.

        Returns:
            CampaignListResponse with list of campaigns.
        """
        if status_filter:
            items = self.repository.find_by_status(status_filter)
        else:
            items = self.repository.find_all(active_only=True)

        campaigns = []
        for item in items:
            response = self._to_campaign_response(item)
            campaigns.append(response)

        # Sort by fromDate (newest first)
        campaigns.sort(key=lambda x: x.from_date, reverse=True)

        return CampaignListResponse(
            campaigns=campaigns,
            count=len(campaigns),
        )

    def get_campaign(self, code: str) -> CampaignResponse:
        """Get a campaign by code.

        Args:
            code: Campaign code.

        Returns:
            CampaignResponse with campaign details.

        Raises:
            CampaignNotFoundException: If campaign not found or inactive.
        """
        item = self.repository.find_by_code(code)

        if not item:
            raise CampaignNotFoundException(code)

        if not item.get("active", False):
            raise CampaignNotFoundException(code)

        return self._to_campaign_response(item)

    def create_campaign(self, request: CreateCampaignRequest) -> CampaignResponse:
        """Create a new campaign.

        Args:
            request: CreateCampaignRequest with campaign data.

        Returns:
            CampaignResponse with created campaign.
        """
        # Calculate effective price
        price = self._calculate_price(
            request.list_price,
            request.discount_percent,
        )

        # Determine initial status based on dates
        status = self._determine_status(request.from_date, request.to_date)

        campaign_data = {
            "code": request.code,
            "name": request.name,
            "productId": request.product_id,
            "discountPercent": request.discount_percent,
            "listPrice": request.list_price,
            "price": price,
            "termsAndConditions": request.terms_and_conditions,
            "status": status.value,
            "fromDate": request.from_date,
            "toDate": request.to_date,
            "specialConditions": request.special_conditions,
        }

        created_item = self.repository.create(campaign_data)
        logger.info(f"Created campaign: {request.code}")

        return self._to_campaign_response(created_item)

    def update_campaign(
        self, code: str, request: UpdateCampaignRequest
    ) -> CampaignResponse:
        """Update an existing campaign.

        Args:
            code: Campaign code.
            request: UpdateCampaignRequest with update data.

        Returns:
            CampaignResponse with updated campaign.

        Raises:
            CampaignNotFoundException: If campaign not found.
            ValidationException: If no update fields provided.
        """
        if not request.has_updates():
            raise ValidationException("No update fields provided")

        # Get current campaign to merge data
        current = self.repository.find_by_code(code)
        if not current:
            raise CampaignNotFoundException(code)

        update_data = {}

        # Map request fields to database fields
        field_mapping = {
            "name": "name",
            "product_id": "productId",
            "discount_percent": "discountPercent",
            "list_price": "listPrice",
            "terms_and_conditions": "termsAndConditions",
            "from_date": "fromDate",
            "to_date": "toDate",
            "special_conditions": "specialConditions",
            "status": "status",
            "active": "active",
        }

        for request_field, db_field in field_mapping.items():
            value = getattr(request, request_field, None)
            if value is not None:
                if request_field == "status":
                    update_data[db_field] = value.value
                else:
                    update_data[db_field] = value

        # Recalculate price if discount or list price changed
        list_price = update_data.get("listPrice", current.get("listPrice"))
        discount = update_data.get("discountPercent", current.get("discountPercent"))

        if "listPrice" in update_data or "discountPercent" in update_data:
            update_data["price"] = self._calculate_price(list_price, discount)

        # Recalculate status if dates changed
        from_date = update_data.get("fromDate", current.get("fromDate"))
        to_date = update_data.get("toDate", current.get("toDate"))

        if "fromDate" in update_data or "toDate" in update_data:
            new_status = self._determine_status(from_date, to_date)
            update_data["status"] = new_status.value

        updated_item = self.repository.update(code, update_data)
        logger.info(f"Updated campaign: {code}")

        return self._to_campaign_response(updated_item)

    def delete_campaign(self, code: str) -> bool:
        """Soft delete a campaign.

        Args:
            code: Campaign code.

        Returns:
            True if deleted successfully.

        Raises:
            CampaignNotFoundException: If campaign not found.
        """
        result = self.repository.soft_delete(code)
        logger.info(f"Deleted campaign: {code}")
        return result

    def _calculate_price(self, list_price: Decimal, discount_percent: int) -> Decimal:
        """Calculate effective price after discount.

        Formula: price = listPrice * (1 - discountPercent/100)

        Args:
            list_price: Original price.
            discount_percent: Discount percentage (0-100).

        Returns:
            Calculated price rounded to 2 decimal places.
        """
        discount_factor = Decimal(1) - (Decimal(discount_percent) / Decimal(100))
        price = list_price * discount_factor
        return price.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)

    def _determine_status(self, from_date: str, to_date: str) -> CampaignStatus:
        """Determine campaign status based on dates.

        Rules:
        - DRAFT: fromDate > current date
        - ACTIVE: fromDate <= current date <= toDate
        - EXPIRED: toDate < current date

        Args:
            from_date: Campaign start date (ISO 8601).
            to_date: Campaign end date (ISO 8601).

        Returns:
            CampaignStatus enum value.
        """
        now = datetime.now(timezone.utc)

        from_dt = datetime.fromisoformat(from_date.replace("Z", "+00:00"))
        to_dt = datetime.fromisoformat(to_date.replace("Z", "+00:00"))

        if now < from_dt:
            return CampaignStatus.DRAFT
        elif now > to_dt:
            return CampaignStatus.EXPIRED
        else:
            return CampaignStatus.ACTIVE

    def _is_campaign_valid(self, status: CampaignStatus) -> bool:
        """Check if campaign is currently valid.

        Args:
            status: Campaign status.

        Returns:
            True only if status is ACTIVE.
        """
        return status == CampaignStatus.ACTIVE

    def _to_campaign_response(self, item: Dict[str, Any]) -> CampaignResponse:
        """Convert DynamoDB item to CampaignResponse.

        Args:
            item: DynamoDB item dictionary.

        Returns:
            CampaignResponse model.
        """
        # Validate and recalculate status based on current date
        current_status = self._determine_status(
            item.get("fromDate", ""),
            item.get("toDate", ""),
        )

        return CampaignResponse(
            code=item.get("code"),
            name=item.get("name"),
            productId=item.get("productId"),
            discountPercent=item.get("discountPercent"),
            listPrice=item.get("listPrice"),
            price=item.get("price"),
            termsAndConditions=item.get("termsAndConditions"),
            status=current_status,
            fromDate=item.get("fromDate"),
            toDate=item.get("toDate"),
            specialConditions=item.get("specialConditions"),
            isValid=self._is_campaign_valid(current_status),
        )
```

---

## Unit Tests (TDD Approach)

### tests/unit/services/test_campaign_service.py

```python
"""Unit tests for CampaignService."""

import pytest
from decimal import Decimal
from datetime import datetime, timedelta, timezone
from unittest.mock import MagicMock, patch

from src.services.campaign_service import CampaignService
from src.models.campaign import (
    CampaignStatus,
    CreateCampaignRequest,
    UpdateCampaignRequest,
)
from src.exceptions.campaign_exceptions import (
    CampaignNotFoundException,
    ValidationException,
)


class TestCampaignServicePriceCalculation:
    """Tests for price calculation."""

    def test_calculate_price_20_percent_discount(self):
        """Test 20% discount calculation."""
        service = CampaignService(repository=MagicMock())
        result = service._calculate_price(Decimal("100.00"), 20)
        assert result == Decimal("80.00")

    def test_calculate_price_zero_discount(self):
        """Test 0% discount calculation."""
        service = CampaignService(repository=MagicMock())
        result = service._calculate_price(Decimal("100.00"), 0)
        assert result == Decimal("100.00")

    def test_calculate_price_100_percent_discount(self):
        """Test 100% discount calculation."""
        service = CampaignService(repository=MagicMock())
        result = service._calculate_price(Decimal("100.00"), 100)
        assert result == Decimal("0.00")

    def test_calculate_price_rounds_correctly(self):
        """Test price is rounded to 2 decimal places."""
        service = CampaignService(repository=MagicMock())
        # 1500 * 0.8 = 1200.00
        result = service._calculate_price(Decimal("1500.00"), 20)
        assert result == Decimal("1200.00")

        # 99.99 * 0.85 = 84.9915 -> 84.99
        result = service._calculate_price(Decimal("99.99"), 15)
        assert result == Decimal("84.99")


class TestCampaignServiceStatusDetermination:
    """Tests for status determination."""

    def test_status_draft_for_future_campaign(self):
        """Test DRAFT status for future campaign."""
        service = CampaignService(repository=MagicMock())

        future_date = (datetime.now(timezone.utc) + timedelta(days=30)).isoformat()
        far_future = (datetime.now(timezone.utc) + timedelta(days=60)).isoformat()

        result = service._determine_status(future_date, far_future)
        assert result == CampaignStatus.DRAFT

    def test_status_active_for_current_campaign(self):
        """Test ACTIVE status for current campaign."""
        service = CampaignService(repository=MagicMock())

        past_date = (datetime.now(timezone.utc) - timedelta(days=30)).isoformat()
        future_date = (datetime.now(timezone.utc) + timedelta(days=30)).isoformat()

        result = service._determine_status(past_date, future_date)
        assert result == CampaignStatus.ACTIVE

    def test_status_expired_for_past_campaign(self):
        """Test EXPIRED status for past campaign."""
        service = CampaignService(repository=MagicMock())

        past_date = (datetime.now(timezone.utc) - timedelta(days=60)).isoformat()
        less_past = (datetime.now(timezone.utc) - timedelta(days=30)).isoformat()

        result = service._determine_status(past_date, less_past)
        assert result == CampaignStatus.EXPIRED


class TestCampaignServiceListCampaigns:
    """Tests for list_campaigns method."""

    def test_list_campaigns_returns_all_active(self):
        """Test list_campaigns returns all active campaigns."""
        mock_repo = MagicMock()
        mock_repo.find_all.return_value = [
            {
                "code": "SUMMER2025",
                "name": "Summer Sale",
                "productId": "PROD-001",
                "discountPercent": 20,
                "listPrice": Decimal("100.00"),
                "price": Decimal("80.00"),
                "termsAndConditions": "Terms",
                "status": "ACTIVE",
                "fromDate": (datetime.now(timezone.utc) - timedelta(days=10)).isoformat(),
                "toDate": (datetime.now(timezone.utc) + timedelta(days=10)).isoformat(),
                "specialConditions": None,
                "active": True,
            }
        ]

        service = CampaignService(repository=mock_repo)
        result = service.list_campaigns()

        assert result.count == 1
        assert result.campaigns[0].code == "SUMMER2025"
        mock_repo.find_all.assert_called_once_with(active_only=True)


class TestCampaignServiceGetCampaign:
    """Tests for get_campaign method."""

    def test_get_campaign_returns_campaign(self):
        """Test get_campaign returns campaign when found."""
        mock_repo = MagicMock()
        mock_repo.find_by_code.return_value = {
            "code": "SUMMER2025",
            "name": "Summer Sale",
            "productId": "PROD-001",
            "discountPercent": 20,
            "listPrice": Decimal("100.00"),
            "price": Decimal("80.00"),
            "termsAndConditions": "Terms",
            "status": "ACTIVE",
            "fromDate": (datetime.now(timezone.utc) - timedelta(days=10)).isoformat(),
            "toDate": (datetime.now(timezone.utc) + timedelta(days=10)).isoformat(),
            "specialConditions": None,
            "active": True,
        }

        service = CampaignService(repository=mock_repo)
        result = service.get_campaign("SUMMER2025")

        assert result.code == "SUMMER2025"
        assert result.is_valid is True

    def test_get_campaign_raises_not_found(self):
        """Test get_campaign raises exception when not found."""
        mock_repo = MagicMock()
        mock_repo.find_by_code.return_value = None

        service = CampaignService(repository=mock_repo)

        with pytest.raises(CampaignNotFoundException):
            service.get_campaign("NONEXISTENT")

    def test_get_campaign_raises_not_found_for_inactive(self):
        """Test get_campaign raises exception for inactive campaign."""
        mock_repo = MagicMock()
        mock_repo.find_by_code.return_value = {
            "code": "SUMMER2025",
            "active": False,
        }

        service = CampaignService(repository=mock_repo)

        with pytest.raises(CampaignNotFoundException):
            service.get_campaign("SUMMER2025")


class TestCampaignServiceCreateCampaign:
    """Tests for create_campaign method."""

    def test_create_campaign_success(self, sample_campaign_data):
        """Test create_campaign creates campaign successfully."""
        mock_repo = MagicMock()
        mock_repo.create.return_value = {
            **sample_campaign_data,
            "price": Decimal("1200.00"),
            "status": "DRAFT",
            "active": True,
            "dateCreated": "2025-01-15T10:00:00Z",
        }

        service = CampaignService(repository=mock_repo)
        request = CreateCampaignRequest(**sample_campaign_data)

        result = service.create_campaign(request)

        assert result.code == "SUMMER2025"
        assert result.price == Decimal("1200.00")
        mock_repo.create.assert_called_once()


class TestCampaignServiceUpdateCampaign:
    """Tests for update_campaign method."""

    def test_update_campaign_success(self):
        """Test update_campaign updates successfully."""
        mock_repo = MagicMock()
        mock_repo.find_by_code.return_value = {
            "code": "SUMMER2025",
            "name": "Old Name",
            "productId": "PROD-001",
            "discountPercent": 20,
            "listPrice": Decimal("100.00"),
            "price": Decimal("80.00"),
            "termsAndConditions": "Terms",
            "status": "ACTIVE",
            "fromDate": (datetime.now(timezone.utc) - timedelta(days=10)).isoformat(),
            "toDate": (datetime.now(timezone.utc) + timedelta(days=10)).isoformat(),
            "active": True,
        }
        mock_repo.update.return_value = {
            "code": "SUMMER2025",
            "name": "New Name",
            "productId": "PROD-001",
            "discountPercent": 20,
            "listPrice": Decimal("100.00"),
            "price": Decimal("80.00"),
            "termsAndConditions": "Terms",
            "status": "ACTIVE",
            "fromDate": (datetime.now(timezone.utc) - timedelta(days=10)).isoformat(),
            "toDate": (datetime.now(timezone.utc) + timedelta(days=10)).isoformat(),
            "active": True,
        }

        service = CampaignService(repository=mock_repo)
        request = UpdateCampaignRequest(name="New Name")

        result = service.update_campaign("SUMMER2025", request)

        assert result.name == "New Name"

    def test_update_campaign_no_fields_raises_exception(self):
        """Test update raises exception when no fields provided."""
        mock_repo = MagicMock()

        service = CampaignService(repository=mock_repo)
        request = UpdateCampaignRequest()

        with pytest.raises(ValidationException):
            service.update_campaign("SUMMER2025", request)


class TestCampaignServiceDeleteCampaign:
    """Tests for delete_campaign method."""

    def test_delete_campaign_success(self):
        """Test delete_campaign soft deletes successfully."""
        mock_repo = MagicMock()
        mock_repo.soft_delete.return_value = True

        service = CampaignService(repository=mock_repo)
        result = service.delete_campaign("SUMMER2025")

        assert result is True
        mock_repo.soft_delete.assert_called_once_with("SUMMER2025")
```

---

## Success Criteria

- [ ] CampaignService class implements all methods
- [ ] list_campaigns() returns CampaignListResponse
- [ ] get_campaign() validates active status
- [ ] create_campaign() calculates price and status
- [ ] update_campaign() recalculates price/status
- [ ] delete_campaign() calls soft_delete
- [ ] _calculate_price() uses correct formula
- [ ] _determine_status() correctly evaluates dates
- [ ] All unit tests pass

---

## Execution Steps

1. Write unit tests for service (TDD)
2. Create src/services/campaign_service.py
3. Implement all business methods
4. Implement price calculation
5. Implement status determination
6. Run tests to verify implementation
7. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-15
