"""Campaign service containing business logic."""

import logging
from datetime import datetime
from decimal import Decimal

from src.models.campaign import Campaign, CampaignStatus
from src.repositories.campaign_repository import CampaignRepository

logger = logging.getLogger(__name__)


class CampaignService:
    """Service for campaign business logic."""

    def __init__(self, repository: CampaignRepository) -> None:
        """
        Initialize campaign service.

        Args:
            repository: Campaign repository
        """
        self.repository = repository
        logger.info("Initialized CampaignService")

    def get_campaign(self, code: str) -> Campaign:
        """
        Get campaign by code with validation and price calculation.

        Args:
            code: Campaign code

        Returns:
            Campaign with validated status and calculated price

        Raises:
            CampaignNotFoundException: If campaign not found
            DynamoDBException: If database error occurs
        """
        logger.info(f"Getting campaign: {code}")

        # Retrieve campaign from repository
        campaign = self.repository.find_by_code(code)

        # Validate campaign status based on dates
        campaign = self._validate_campaign_status(campaign)

        # Calculate effective price based on discount
        campaign = self._calculate_effective_price(campaign)

        logger.info(f"Campaign retrieved successfully: {code}, status: {campaign.status}")
        return campaign

    def _validate_campaign_status(self, campaign: Campaign) -> Campaign:
        """
        Validate and update campaign status based on dates.

        Args:
            campaign: Campaign to validate

        Returns:
            Campaign with updated status if needed
        """
        now = datetime.utcnow()
        from_date = datetime.fromisoformat(campaign.from_date.replace("Z", "+00:00"))
        to_date = datetime.fromisoformat(campaign.to_date.replace("Z", "+00:00"))

        # Check if campaign has expired
        if now > to_date:
            logger.info(f"Campaign {campaign.code} has expired")
            campaign.status = CampaignStatus.EXPIRED
        # Check if campaign is active
        elif from_date <= now <= to_date and campaign.status == CampaignStatus.DRAFT:
            logger.info(f"Campaign {campaign.code} is now active")
            campaign.status = CampaignStatus.ACTIVE

        return campaign

    def _calculate_effective_price(self, campaign: Campaign) -> Campaign:
        """
        Calculate effective price based on discount.

        Formula: price = listPrice * (1 - discountPercent / 100)

        Args:
            campaign: Campaign to calculate price for

        Returns:
            Campaign with calculated price
        """
        if campaign.discount_percent > 0:
            discount_multiplier = Decimal("1") - (
                Decimal(str(campaign.discount_percent)) / Decimal("100")
            )
            calculated_price = campaign.list_price * discount_multiplier

            # Round to 2 decimal places
            campaign.price = calculated_price.quantize(Decimal("0.01"))

            logger.info(
                f"Calculated price for {campaign.code}: "
                f"listPrice={campaign.list_price}, "
                f"discount={campaign.discount_percent}%, "
                f"price={campaign.price}"
            )

        return campaign
