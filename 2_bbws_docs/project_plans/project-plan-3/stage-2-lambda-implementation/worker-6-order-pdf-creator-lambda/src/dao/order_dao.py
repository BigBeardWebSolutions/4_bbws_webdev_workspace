"""
OrderDAO - Data Access Object for Order DynamoDB operations.

Implements DynamoDB single-table design with tenant isolation.
"""

import logging
from typing import Optional
from datetime import datetime
from src.models.order import Order

logger = logging.getLogger(__name__)


class OrderDAO:
    """
    Data Access Object for Order entity operations in DynamoDB.

    Implements single-table design with tenant isolation:
    - PK: TENANT#{tenantId}
    - SK: ORDER#{orderId}
    - GSI1_PK: TENANT#{tenantId}
    - GSI1_SK: {dateCreated}#{orderId} (for date-based sorting)
    - GSI2_PK: ORDER#{orderId}
    - GSI2_SK: METADATA (for admin cross-tenant lookup)

    Attributes:
        dynamodb_client: Boto3 DynamoDB client
        table_name: DynamoDB table name
    """

    def __init__(self, dynamodb_client, table_name: str):
        """
        Initialize OrderDAO.

        Args:
            dynamodb_client: Boto3 DynamoDB client
            table_name: Name of DynamoDB table
        """
        self.dynamodb = dynamodb_client
        self.table_name = table_name

    def get_order(self, tenant_id: str, order_id: str) -> Optional[Order]:
        """
        Get order by tenant ID and order ID (Access Pattern AP1).

        Args:
            tenant_id: Tenant identifier
            order_id: Order identifier

        Returns:
            Order object if found, None otherwise

        Raises:
            Exception: If DynamoDB operation fails
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

            # Deserialize DynamoDB item to Order model
            order_data = self._deserialize_item(response['Item'])
            order = Order.parse_obj(order_data)

            logger.info(f"Order retrieved successfully: orderId={order_id}")
            return order

        except Exception as e:
            logger.error(f"Error getting order: {str(e)}", exc_info=True)
            raise

    def update_order(self, order: Order) -> Order:
        """
        Update existing order in DynamoDB.

        Args:
            order: Order object with updated data

        Returns:
            Updated Order object

        Raises:
            Exception: If DynamoDB operation fails
        """
        try:
            logger.info(f"Updating order: orderId={order.id}, tenantId={order.tenantId}")

            # Update timestamp
            order.dateLastUpdated = datetime.utcnow()

            # Serialize order to DynamoDB item
            item = self._serialize_order(order)

            # Put item to DynamoDB (will overwrite existing)
            self.dynamodb.put_item(
                TableName=self.table_name,
                Item=item
            )

            logger.info(f"Order updated successfully: orderId={order.id}")
            return order

        except Exception as e:
            logger.error(f"Error updating order: {str(e)}", exc_info=True)
            raise

    def _serialize_order(self, order: Order) -> dict:
        """
        Serialize Order model to DynamoDB item format.

        Args:
            order: Order object

        Returns:
            DynamoDB item dictionary
        """
        # Convert Order to dict
        order_dict = order.dict()

        # Build DynamoDB item with proper attribute types
        item = {
            # Primary key
            'PK': {'S': f'TENANT#{order.tenantId}'},
            'SK': {'S': f'ORDER#{order.id}'},

            # GSI keys for access patterns
            'GSI1_PK': {'S': f'TENANT#{order.tenantId}'},
            'GSI1_SK': {'S': f'{order.dateCreated.isoformat()}#{order.id}'},
            'GSI2_PK': {'S': f'ORDER#{order.id}'},
            'GSI2_SK': {'S': 'METADATA'},

            # Order attributes
            'id': {'S': order.id},
            'orderNumber': {'S': order.orderNumber},
            'tenantId': {'S': order.tenantId},
            'customerEmail': {'S': order.customerEmail},
            'status': {'S': order.status},
            'subtotal': {'N': str(order.subtotal)},
            'taxAmount': {'N': str(order.taxAmount)},
            'shippingAmount': {'N': str(order.shippingAmount)},
            'discountAmount': {'N': str(order.discountAmount)},
            'total': {'N': str(order.total)},
            'currency': {'S': order.currency},
            'isActive': {'BOOL': order.isActive},
            'dateCreated': {'S': order.dateCreated.isoformat()},
            'dateLastUpdated': {'S': order.dateLastUpdated.isoformat()},
        }

        # Optional fields
        if order.customerId:
            item['customerId'] = {'S': order.customerId}
        if order.customerName:
            item['customerName'] = {'S': order.customerName}
        if order.pdfUrl:
            item['pdfUrl'] = {'S': order.pdfUrl}
        if order.notes:
            item['notes'] = {'S': order.notes}
        if order.dateCompleted:
            item['dateCompleted'] = {'S': order.dateCompleted.isoformat()}

        # Complex nested objects (store as JSON strings for simplicity)
        import json
        if order.items:
            item['items'] = {'S': json.dumps([item.dict() for item in order.items])}
        if order.billingAddress:
            item['billingAddress'] = {'S': json.dumps(order.billingAddress.dict())}
        if order.shippingAddress:
            item['shippingAddress'] = {'S': json.dumps(order.shippingAddress.dict())}
        if order.campaign:
            item['campaign'] = {'S': json.dumps(order.campaign.dict())}
        if order.paymentDetails:
            item['paymentDetails'] = {'S': json.dumps(order.paymentDetails.dict())}
        if order.metadata:
            item['metadata'] = {'S': json.dumps(order.metadata)}

        return item

    def _deserialize_item(self, item: dict) -> dict:
        """
        Deserialize DynamoDB item to dictionary suitable for Order model.

        Args:
            item: DynamoDB item

        Returns:
            Dictionary with order data
        """
        import json

        order_data = {
            'id': item['id']['S'],
            'orderNumber': item['orderNumber']['S'],
            'tenantId': item['tenantId']['S'],
            'customerEmail': item['customerEmail']['S'],
            'status': item['status']['S'],
            'subtotal': float(item['subtotal']['N']),
            'taxAmount': float(item['taxAmount']['N']),
            'shippingAmount': float(item['shippingAmount']['N']),
            'discountAmount': float(item['discountAmount']['N']),
            'total': float(item['total']['N']),
            'currency': item['currency']['S'],
            'isActive': item['isActive']['BOOL'],
            'dateCreated': item['dateCreated']['S'],
            'dateLastUpdated': item['dateLastUpdated']['S'],
        }

        # Optional simple fields
        if 'customerId' in item:
            order_data['customerId'] = item['customerId']['S']
        if 'customerName' in item:
            order_data['customerName'] = item['customerName']['S']
        if 'pdfUrl' in item:
            order_data['pdfUrl'] = item['pdfUrl']['S']
        if 'notes' in item:
            order_data['notes'] = item['notes']['S']
        if 'dateCompleted' in item:
            order_data['dateCompleted'] = item['dateCompleted']['S']

        # Deserialize JSON strings
        if 'items' in item:
            order_data['items'] = json.loads(item['items']['S'])
        if 'billingAddress' in item:
            order_data['billingAddress'] = json.loads(item['billingAddress']['S'])
        if 'shippingAddress' in item:
            order_data['shippingAddress'] = json.loads(item['shippingAddress']['S'])
        if 'campaign' in item:
            order_data['campaign'] = json.loads(item['campaign']['S'])
        if 'paymentDetails' in item:
            order_data['paymentDetails'] = json.loads(item['paymentDetails']['S'])
        if 'metadata' in item:
            order_data['metadata'] = json.loads(item['metadata']['S'])

        return order_data
