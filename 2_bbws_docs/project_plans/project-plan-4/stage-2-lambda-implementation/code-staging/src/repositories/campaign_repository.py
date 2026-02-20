"""Campaign repository for DynamoDB access."""

import logging
import os
from decimal import Decimal
from typing import Optional

import boto3
from botocore.exceptions import ClientError

from src.exceptions.campaign_exceptions import CampaignNotFoundException, DynamoDBException
from src.models.campaign import Campaign, CampaignStatus

logger = logging.getLogger(__name__)


class CampaignRepository:
    """Repository for campaign data access."""

    def __init__(self) -> None:
        """Initialize campaign repository."""
        self.dynamodb = boto3.resource("dynamodb")
        self.table_name = os.environ.get("DYNAMODB_TABLE_NAME", "bbws-cpp-dev")
        self.table = self.dynamodb.Table(self.table_name)
        logger.info(f"Initialized CampaignRepository with table: {self.table_name}")

    def find_by_code(self, code: str) -> Campaign:
        """
        Find campaign by code.

        Args:
            code: Campaign code

        Returns:
            Campaign domain model

        Raises:
            CampaignNotFoundException: If campaign not found
            DynamoDBException: If DynamoDB operation fails
        """
        try:
            logger.info(f"Finding campaign by code: {code}")

            response = self.table.get_item(
                Key={"PK": f"CAMPAIGN#{code}", "SK": "METADATA"}
            )

            if "Item" not in response:
                logger.warning(f"Campaign not found: {code}")
                raise CampaignNotFoundException(code)

            item = response["Item"]
            logger.info(f"Campaign found: {code}")

            return self._to_entity(item)

        except CampaignNotFoundException:
            raise
        except ClientError as e:
            logger.error(f"DynamoDB ClientError: {e}")
            raise DynamoDBException("Failed to retrieve campaign", e)
        except Exception as e:
            logger.error(f"Unexpected error: {e}")
            raise DynamoDBException("Unexpected error retrieving campaign", e)

    def _to_entity(self, item: dict) -> Campaign:
        """
        Convert DynamoDB item to Campaign entity.

        Args:
            item: DynamoDB item

        Returns:
            Campaign domain model
        """
        return Campaign(
            code=item["code"],
            productId=item["productId"],
            discountPercent=int(item["discountPercent"]),
            listPrice=Decimal(str(item["listPrice"])),
            price=Decimal(str(item["price"])),
            termsAndConditions=item["termsAndConditions"],
            status=CampaignStatus(item["status"]),
            fromDate=item["fromDate"],
            toDate=item["toDate"],
            specialConditions=item.get("specialConditions"),
            active=item.get("active", True),
        )
