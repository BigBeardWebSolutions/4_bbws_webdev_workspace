"""
OrderDAO - Data Access Object for Order operations.

Implements DynamoDB single-table design patterns with tenant isolation.
"""
import logging
from typing import Optional, Dict, Any
from decimal import Decimal

from src.models import Order, OrderItem, Campaign, BillingAddress, PaymentDetails

logger = logging.getLogger(__name__)


class OrderDAO:
    """
    Data Access Object for Order operations.

    Implements Access Pattern AP1: Get specific order for a tenant.
    Primary Key Structure: PK=TENANT#{tenantId}, SK=ORDER#{orderId}
    """

    def __init__(self, dynamodb_client, table_name: str):
        """
        Initialize OrderDAO with DynamoDB client.

        Args:
            dynamodb_client: boto3 DynamoDB client
            table_name: DynamoDB table name
        """
        self.dynamodb = dynamodb_client
        self.table_name = table_name

    def get_order(self, tenant_id: str, order_id: str) -> Optional[Order]:
        """
        Get order by tenant and order ID (AP1).

        Implements Access Pattern AP1: Get specific order for a tenant
        Query: PK=TENANT#{tenantId} AND SK=ORDER#{orderId}

        Args:
            tenant_id: Tenant identifier
            order_id: Order identifier

        Returns:
            Order object if found, None otherwise

        Raises:
            Exception: For DynamoDB errors
        """
        try:
            logger.info(f"Getting order: tenantId={tenant_id}, orderId={order_id}")

            response = self.dynamodb.get_item(
                TableName=self.table_name,
                Key={
                    'PK': {'S': f'TENANT#{tenant_id}'},
                    'SK': {'S': f'ORDER#{order_id}'}
                }
            )

            if 'Item' not in response:
                logger.warning(f"Order not found: tenantId={tenant_id}, orderId={order_id}")
                return None

            # Deserialize DynamoDB item to Order object
            order_dict = self._deserialize_item(response['Item'])
            order = Order(**order_dict)

            logger.info(f"Order retrieved successfully: orderId={order_id}, status={order.status}")
            return order

        except Exception as e:
            logger.error(f"Error getting order: {str(e)}", exc_info=True)
            raise

    def _deserialize_item(self, item: Dict[str, Any]) -> Dict[str, Any]:
        """
        Deserialize DynamoDB item to dictionary compatible with Pydantic models.

        Converts DynamoDB type-annotated format to plain Python types.

        Args:
            item: DynamoDB item with type annotations

        Returns:
            Dictionary with plain Python types
        """
        def deserialize_value(value: Dict[str, Any]) -> Any:
            """Deserialize a single DynamoDB value."""
            if 'S' in value:
                return value['S']
            elif 'N' in value:
                # Convert to Decimal for monetary values
                return Decimal(value['N'])
            elif 'BOOL' in value:
                return value['BOOL']
            elif 'NULL' in value:
                return None
            elif 'L' in value:
                # List
                return [deserialize_value(v) for v in value['L']]
            elif 'M' in value:
                # Map (nested object)
                return {k: deserialize_value(v) for k, v in value['M'].items()}
            else:
                logger.warning(f"Unknown DynamoDB type: {value}")
                return value

        # Deserialize all attributes
        result = {}
        for key, value in item.items():
            # Skip internal DynamoDB keys
            if key in ['PK', 'SK', 'entityType', 'GSI1_PK', 'GSI1_SK', 'GSI2_PK', 'GSI2_SK']:
                continue
            result[key] = deserialize_value(value)

        return result
