"""
OrderDAO - Data Access Object for DynamoDB operations.

Implements single-table design with the following key structure:
- PK: TENANT#{tenantId}
- SK: ORDER#{orderId}
- GSI1_PK: TENANT#{tenantId}
- GSI1_SK: {dateCreated}#{orderId}
- GSI2_PK: ORDER#{orderId}
- GSI2_SK: METADATA
"""

import logging
from datetime import datetime
from decimal import Decimal
from typing import Optional, Dict, Any

from botocore.exceptions import ClientError

from src.models.order import Order
from src.utils.exceptions import (
    OrderNotFoundException,
    OptimisticLockException,
    DatabaseException
)

logger = logging.getLogger()


class OrderDAO:
    """
    Data Access Object for Order operations using DynamoDB.

    Implements access patterns:
    - AP1: Get order by tenantId and orderId
    - AP4: Update order with optimistic locking
    """

    def __init__(self, dynamodb_client, table_name: str):
        """
        Initialize OrderDAO.

        Args:
            dynamodb_client: Boto3 DynamoDB client
            table_name: DynamoDB table name
        """
        self.dynamodb = dynamodb_client
        self.table_name = table_name

    def get_order(self, tenant_id: str, order_id: str) -> Optional[Order]:
        """
        Get order by tenant ID and order ID (Access Pattern 1).

        Args:
            tenant_id: Tenant identifier
            order_id: Order identifier

        Returns:
            Order object or None if not found

        Raises:
            DatabaseException: If DynamoDB query fails
        """
        try:
            response = self.dynamodb.get_item(
                TableName=self.table_name,
                Key={
                    'PK': {'S': f'TENANT#{tenant_id}'},
                    'SK': {'S': f'ORDER#{order_id}'}
                }
            )

            if 'Item' not in response:
                logger.info(f"Order not found: tenantId={tenant_id}, orderId={order_id}")
                return None

            item = self._deserialize_item(response['Item'])
            return Order.parse_obj(item)

        except ClientError as e:
            logger.error(f"DynamoDB get_item failed: {str(e)}", exc_info=True)
            raise DatabaseException(f"Failed to retrieve order: {str(e)}")

    def update_order(
        self,
        tenant_id: str,
        order_id: str,
        updates: Dict[str, Any],
        expected_last_updated: str,
        updated_by: str
    ) -> Order:
        """
        Update order with optimistic locking (Access Pattern 4).

        Uses conditional update to prevent lost updates. The update will fail
        if dateLastUpdated has changed since the order was fetched.

        Args:
            tenant_id: Tenant identifier
            order_id: Order identifier
            updates: Dictionary of fields to update (status, paymentDetails)
            expected_last_updated: Expected dateLastUpdated value for optimistic locking
            updated_by: Email or system identifier of updater

        Returns:
            Updated Order object

        Raises:
            OptimisticLockException: If dateLastUpdated doesn't match (409 Conflict)
            OrderNotFoundException: If order doesn't exist
            DatabaseException: If DynamoDB update fails
        """
        try:
            # Build update expression
            now = datetime.utcnow().isoformat()
            update_expression_parts = []
            expression_attribute_names = {}
            expression_attribute_values = {}

            # Always update these fields
            update_expression_parts.append("#dateLastUpdated = :dateLastUpdated")
            update_expression_parts.append("#lastUpdatedBy = :lastUpdatedBy")
            expression_attribute_names['#dateLastUpdated'] = 'dateLastUpdated'
            expression_attribute_names['#lastUpdatedBy'] = 'lastUpdatedBy'
            expression_attribute_values[':dateLastUpdated'] = {'S': now}
            expression_attribute_values[':lastUpdatedBy'] = {'S': updated_by}

            # Add conditional updates
            if 'status' in updates:
                update_expression_parts.append("#status = :status")
                expression_attribute_names['#status'] = 'status'
                expression_attribute_values[':status'] = {'S': updates['status']}

            if 'paymentDetails' in updates:
                update_expression_parts.append("#paymentDetails = :paymentDetails")
                expression_attribute_names['#paymentDetails'] = 'paymentDetails'
                expression_attribute_values[':paymentDetails'] = {
                    'M': self._serialize_payment_details(updates['paymentDetails'])
                }

            update_expression = "SET " + ", ".join(update_expression_parts)

            # Optimistic locking condition
            condition_expression = "#dateLastUpdated = :expectedLastUpdated"
            expression_attribute_values[':expectedLastUpdated'] = {'S': expected_last_updated}

            # Execute conditional update
            response = self.dynamodb.update_item(
                TableName=self.table_name,
                Key={
                    'PK': {'S': f'TENANT#{tenant_id}'},
                    'SK': {'S': f'ORDER#{order_id}'}
                },
                UpdateExpression=update_expression,
                ConditionExpression=condition_expression,
                ExpressionAttributeNames=expression_attribute_names,
                ExpressionAttributeValues=expression_attribute_values,
                ReturnValues='ALL_NEW'
            )

            # Deserialize and return updated order
            item = self._deserialize_item(response['Attributes'])
            return Order.parse_obj(item)

        except ClientError as e:
            error_code = e.response['Error']['Code']

            if error_code == 'ConditionalCheckFailedException':
                logger.warning(
                    f"Optimistic lock failure: tenantId={tenant_id}, "
                    f"orderId={order_id}, expected={expected_last_updated}"
                )
                raise OptimisticLockException(
                    f"Order was modified by another process. Please refresh and try again."
                )

            if error_code == 'ResourceNotFoundException':
                logger.error(f"Order not found: tenantId={tenant_id}, orderId={order_id}")
                raise OrderNotFoundException(f"Order {order_id} not found")

            logger.error(f"DynamoDB update_item failed: {str(e)}", exc_info=True)
            raise DatabaseException(f"Failed to update order: {str(e)}")

    def _deserialize_item(self, item: Dict[str, Any]) -> Dict[str, Any]:
        """
        Deserialize DynamoDB item to Python dict.

        Args:
            item: DynamoDB item with type descriptors

        Returns:
            Python dictionary
        """
        result = {}

        for key, value in item.items():
            # Skip internal keys
            if key in ['PK', 'SK', 'GSI1_PK', 'GSI1_SK', 'GSI2_PK', 'GSI2_SK']:
                continue

            result[key] = self._deserialize_value(value)

        return result

    def _deserialize_value(self, value: Dict[str, Any]) -> Any:
        """Deserialize a single DynamoDB value."""
        if 'S' in value:
            return value['S']
        elif 'N' in value:
            return Decimal(value['N'])
        elif 'BOOL' in value:
            return value['BOOL']
        elif 'NULL' in value:
            return None
        elif 'L' in value:
            return [self._deserialize_value(v) for v in value['L']]
        elif 'M' in value:
            return {k: self._deserialize_value(v) for k, v in value['M'].items()}
        else:
            return value

    def _serialize_payment_details(self, payment_details: Dict[str, Any]) -> Dict[str, Any]:
        """
        Serialize PaymentDetails to DynamoDB Map format.

        Args:
            payment_details: Payment details dictionary

        Returns:
            DynamoDB Map (M) structure
        """
        result = {}

        if payment_details.get('method'):
            result['method'] = {'S': payment_details['method']}

        if payment_details.get('transactionId'):
            result['transactionId'] = {'S': payment_details['transactionId']}

        if payment_details.get('payfastPaymentId'):
            result['payfastPaymentId'] = {'S': payment_details['payfastPaymentId']}

        if payment_details.get('paidAt'):
            result['paidAt'] = {'S': payment_details['paidAt']}

        return result
