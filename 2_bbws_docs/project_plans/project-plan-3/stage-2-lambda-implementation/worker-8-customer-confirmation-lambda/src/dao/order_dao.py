"""Order Data Access Object for DynamoDB operations."""

import os
import logging
from typing import Optional
from decimal import Decimal
import boto3
from botocore.exceptions import ClientError

from src.models import Order

logger = logging.getLogger(__name__)


class OrderDAO:
    """
    Data Access Object for Order operations with DynamoDB.

    Implements single-table design pattern:
    - PK: TENANT#{tenantId}
    - SK: ORDER#{orderId}
    - GSI1: OrdersByDateIndex (for listing by date)
    - GSI2: OrderByIdIndex (for admin lookup by orderId alone)
    """

    def __init__(self):
        """Initialize OrderDAO with DynamoDB client."""
        self.dynamodb = boto3.resource('dynamodb')
        self.table_name = os.environ.get('DYNAMODB_TABLE_NAME', 'bbws-orders-dev')
        self.table = self.dynamodb.Table(self.table_name)
        logger.info(f"OrderDAO initialized with table: {self.table_name}")

    def get_order(self, tenant_id: str, order_id: str) -> Optional[Order]:
        """
        Retrieve an order by tenant_id and order_id.

        Args:
            tenant_id: Tenant identifier
            order_id: Order identifier

        Returns:
            Order object if found, None otherwise

        Raises:
            Exception: If DynamoDB operation fails
        """
        try:
            logger.info(f"Retrieving order: tenantId={tenant_id}, orderId={order_id}")

            response = self.table.get_item(
                Key={
                    'PK': f'TENANT#{tenant_id}',
                    'SK': f'ORDER#{order_id}'
                }
            )

            if 'Item' not in response:
                logger.warning(f"Order not found: tenantId={tenant_id}, orderId={order_id}")
                return None

            # Convert DynamoDB item to Order model
            item = response['Item']
            order_dict = self._deserialize_dynamodb_item(item)

            order = Order(**order_dict)
            logger.info(f"Successfully retrieved order: {order_id}")
            return order

        except ClientError as e:
            error_code = e.response['Error']['Code']
            error_message = e.response['Error']['Message']
            logger.error(f"DynamoDB ClientError: {error_code} - {error_message}")
            raise Exception(f"Failed to retrieve order: {error_message}")
        except Exception as e:
            logger.error(f"Error retrieving order: {str(e)}")
            raise

    def _deserialize_dynamodb_item(self, item: dict) -> dict:
        """
        Convert DynamoDB item to Python dict with proper type conversion.

        Args:
            item: DynamoDB item with Decimal types

        Returns:
            Dictionary with float values (Pydantic-compatible)
        """
        # Remove DynamoDB keys
        item.pop('PK', None)
        item.pop('SK', None)
        item.pop('GSI1PK', None)
        item.pop('GSI1SK', None)
        item.pop('GSI2PK', None)

        # Convert Decimal to float recursively
        return self._convert_decimals(item)

    def _convert_decimals(self, obj):
        """
        Recursively convert Decimal objects to float.

        Args:
            obj: Object that may contain Decimal values

        Returns:
            Object with Decimals converted to float
        """
        if isinstance(obj, Decimal):
            return float(obj)
        elif isinstance(obj, dict):
            return {k: self._convert_decimals(v) for k, v in obj.items()}
        elif isinstance(obj, list):
            return [self._convert_decimals(item) for item in obj]
        else:
            return obj
