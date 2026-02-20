"""Unit tests for Campaign models."""

import pytest
from decimal import Decimal
from pydantic import ValidationError

from src.models.campaign import Campaign, CampaignResponse, CampaignStatus


class TestCampaignStatus:
    """Tests for CampaignStatus enum."""

    def test_campaign_status_values(self) -> None:
        """Test campaign status enum values."""
        assert CampaignStatus.DRAFT == "DRAFT"
        assert CampaignStatus.ACTIVE == "ACTIVE"
        assert CampaignStatus.EXPIRED == "EXPIRED"


class TestCampaign:
    """Tests for Campaign model."""

    def test_campaign_valid_creation(self) -> None:
        """Test creating a valid campaign."""
        campaign = Campaign(
            code="SUMMER2025",
            productId="PROD-001",
            discountPercent=20,
            listPrice=Decimal("100.00"),
            price=Decimal("80.00"),
            termsAndConditions="Valid until end of summer",
            status=CampaignStatus.ACTIVE,
            fromDate="2025-06-01T00:00:00Z",
            toDate="2025-08-31T23:59:59Z",
            specialConditions=None,
            active=True,
        )

        assert campaign.code == "SUMMER2025"
        assert campaign.product_id == "PROD-001"
        assert campaign.discount_percent == 20
        assert campaign.list_price == Decimal("100.00")
        assert campaign.price == Decimal("80.00")
        assert campaign.status == CampaignStatus.ACTIVE

    def test_campaign_with_camelcase_alias(self) -> None:
        """Test campaign creation with camelCase aliases."""
        campaign = Campaign(
            code="TEST",
            product_id="PROD-001",  # snake_case
            discount_percent=10,  # snake_case
            list_price=Decimal("50.00"),  # snake_case
            price=Decimal("45.00"),
            terms_and_conditions="Test T&C",  # snake_case
            status=CampaignStatus.DRAFT,
            from_date="2025-01-01T00:00:00Z",  # snake_case
            to_date="2025-12-31T23:59:59Z",  # snake_case
        )

        assert campaign.product_id == "PROD-001"
        assert campaign.discount_percent == 10

    def test_campaign_invalid_discount_above_100(self) -> None:
        """Test campaign with discount > 100% fails."""
        with pytest.raises(ValidationError) as exc_info:
            Campaign(
                code="TEST",
                productId="PROD-001",
                discountPercent=150,  # Invalid
                listPrice=Decimal("100.00"),
                price=Decimal("50.00"),
                termsAndConditions="T&C",
                status=CampaignStatus.ACTIVE,
                fromDate="2025-01-01T00:00:00Z",
                toDate="2025-12-31T23:59:59Z",
            )

        assert "Discount percent must be between 0 and 100" in str(exc_info.value)

    def test_campaign_invalid_discount_negative(self) -> None:
        """Test campaign with negative discount fails."""
        with pytest.raises(ValidationError):
            Campaign(
                code="TEST",
                productId="PROD-001",
                discountPercent=-10,  # Invalid
                listPrice=Decimal("100.00"),
                price=Decimal("100.00"),
                termsAndConditions="T&C",
                status=CampaignStatus.ACTIVE,
                fromDate="2025-01-01T00:00:00Z",
                toDate="2025-12-31T23:59:59Z",
            )

    def test_campaign_price_exceeds_list_price(self) -> None:
        """Test campaign where price > list price fails."""
        with pytest.raises(ValidationError) as exc_info:
            Campaign(
                code="TEST",
                productId="PROD-001",
                discountPercent=10,
                listPrice=Decimal("100.00"),
                price=Decimal("150.00"),  # Invalid: exceeds list price
                termsAndConditions="T&C",
                status=CampaignStatus.ACTIVE,
                fromDate="2025-01-01T00:00:00Z",
                toDate="2025-12-31T23:59:59Z",
            )

        assert "Price cannot exceed list price" in str(exc_info.value)


class TestCampaignResponse:
    """Tests for CampaignResponse model."""

    def test_campaign_response_from_campaign(self) -> None:
        """Test creating response from campaign."""
        campaign = Campaign(
            code="SUMMER2025",
            productId="PROD-001",
            discountPercent=20,
            listPrice=Decimal("100.00"),
            price=Decimal("80.00"),
            termsAndConditions="Valid until end of summer",
            status=CampaignStatus.ACTIVE,
            fromDate="2025-06-01T00:00:00Z",
            toDate="2025-08-31T23:59:59Z",
        )

        response = CampaignResponse.from_campaign(campaign)

        assert response.code == "SUMMER2025"
        assert response.product_id == "PROD-001"
        assert response.is_valid is True  # ACTIVE campaigns are valid

    def test_campaign_response_expired_not_valid(self) -> None:
        """Test expired campaign is not valid in response."""
        campaign = Campaign(
            code="OLD2024",
            productId="PROD-001",
            discountPercent=20,
            listPrice=Decimal("100.00"),
            price=Decimal("80.00"),
            termsAndConditions="Expired",
            status=CampaignStatus.EXPIRED,
            fromDate="2024-01-01T00:00:00Z",
            toDate="2024-12-31T23:59:59Z",
        )

        response = CampaignResponse.from_campaign(campaign)

        assert response.is_valid is False  # EXPIRED campaigns are not valid

    def test_campaign_response_json_serialization(self) -> None:
        """Test campaign response JSON serialization with camelCase."""
        campaign = Campaign(
            code="TEST",
            productId="PROD-001",
            discountPercent=10,
            listPrice=Decimal("50.00"),
            price=Decimal("45.00"),
            termsAndConditions="T&C",
            status=CampaignStatus.ACTIVE,
            fromDate="2025-01-01T00:00:00Z",
            toDate="2025-12-31T23:59:59Z",
        )

        response = CampaignResponse.from_campaign(campaign)
        json_str = response.model_dump_json(by_alias=True)

        # Verify camelCase in JSON
        assert "productId" in json_str
        assert "discountPercent" in json_str
        assert "listPrice" in json_str
        assert "termsAndConditions" in json_str
        assert "isValid" in json_str
