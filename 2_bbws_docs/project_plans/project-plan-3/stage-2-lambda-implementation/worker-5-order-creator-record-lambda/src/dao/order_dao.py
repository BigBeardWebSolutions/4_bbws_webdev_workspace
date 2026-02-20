"""
Order Data Access Object for DynamoDB operations.
"""

import logging
from typing import Optional
from datetime import datetime

from botocore.exceptions import ClientError

from ..models.order import Order

logger = logging.getLogger()


class OrderDAO:
    """
    Data Access Object for Order operations using DynamoDB single-table design.

    This DAO implements the following access patterns:
    - AP1: Get specific order for a tenant (PK + SK)
    - AP2: List all orders for a tenant (PK query)
    - AP3: List orders by date (GSI1 query)
    - AP4: Get order by ID (GSI2 query)
    - AP5: List orders by status (PK query + filter)

    Attributes:
        dynamodb_client: Boto3 DynamoDB client
        table_name: DynamoDB table name
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
        self.counter_pk = "COUNTER"
        self.counter_sk = "ORDER_NUMBER"

    def create_order(self, order: Order) -> Order:
        """
        Create a new order in DynamoDB with conditional write to prevent duplicates.

        Args:
            order: Order object to create

        Returns:
            Created Order object

        Raises:
            ValueError: If order already exists
            ClientError: If DynamoDB operation fails
        """
        try:
            # Convert order to DynamoDB item
            item = order.to_dynamodb_item()

            # Conditional write: only create if PK+SK doesn't exist
            self.dynamodb.put_item(
                TableName=self.table_name,
                Item=self._serialize_item(item),
                ConditionExpression='attribute_not_exists(PK) AND attribute_not_exists(SK)'
            )

            logger.info(f"Created order: {order.id} for tenant: {order.tenantId}")
            return order

        except ClientError as e:
            if e.response['Error']['Code'] == 'ConditionalCheckFailedException':
                logger.error(f"Order already exists: {order.id}")
                raise ValueError(f"Order with ID {order.id} already exists")
            else:
                logger.error(f"Failed to create order: {str(e)}")
                raise

    def get_next_order_number(self, tenant_id: str) -> str:
        """
        Generate next order number using atomic counter pattern.

        This uses DynamoDB's atomic counter to ensure unique sequential order numbers
        per tenant. Format: ORD-{YYYYMMDD}-{sequence}

        Args:
            tenant_id: Tenant identifier

        Returns:
            Order number string (e.g., "ORD-20251230-00001")

        Raises:
            ClientError: If DynamoDB operation fails
        """
        try:
            # Generate date prefix
            date_prefix = datetime.utcnow().strftime('%Y%m%d')

            # Atomic counter key
            counter_sk = f"{self.counter_sk}#{tenant_id}#{date_prefix}"

            # Update counter atomically
            response = self.dynamodb.update_item(
                TableName=self.table_name,
                Key={
                    'PK': {'S': self.counter_pk},
                    'SK': {'S': counter_sk}
                },
                UpdateExpression='SET #counter = if_not_exists(#counter, :start) + :increment',
                ExpressionAttributeNames={
                    '#counter': 'counter'
                },
                ExpressionAttributeValues={
                    ':start': {'N': '0'},
                    ':increment': {'N': '1'}
                },
                ReturnValues='UPDATED_NEW'
            )

            # Extract counter value
            counter_value = int(response['Attributes']['counter']['N'])

            # Format order number: ORD-YYYYMMDD-NNNNN
            order_number = f"ORD-{date_prefix}-{counter_value:05d}"

            logger.info(f"Generated order number: {order_number} for tenant: {tenant_id}")
            return order_number

        except ClientError as e:
            logger.error(f"Failed to generate order number: {str(e)}")
            raise

    def get_order(self, tenant_id: str, order_id: str) -> Optional[Order]:
        """
        Get order by tenant and order ID (AP1).

        Args:
            tenant_id: Tenant identifier
            order_id: Order identifier

        Returns:
            Order object if found, None otherwise

        Raises:
            ClientError: If DynamoDB operation fails
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
                logger.info(f"Order not found: {order_id} for tenant: {tenant_id}")
                return None

            # Deserialize and convert to Order model
            item = self._deserialize_item(response['Item'])
            order = Order(**item)

            logger.info(f"Retrieved order: {order_id} for tenant: {tenant_id}")
            return order

        except ClientError as e:
            logger.error(f"Failed to get order: {str(e)}")
            raise

    def _serialize_item(self, item: dict) -> dict:
        """
        Serialize Python dict to DynamoDB format.

        Args:
            item: Python dictionary

        Returns:
            DynamoDB formatted dictionary
        """
        serialized = {}

        for key, value in item.items():
            if value is None:
                serialized[key] = {'NULL': True}
            elif isinstance(value, str):
                serialized[key] = {'S': value}
            elif isinstance(value, bool):
                serialized[key] = {'BOOL': value}
            elif isinstance(value, (int, float)):
                serialized[key] = {'N': str(value)}
            elif isinstance(value, list):
                serialized[key] = {'L': [self._serialize_value(v) for v in value]}
            elif isinstance(value, dict):
                serialized[key] = {'M': self._serialize_item(value)}
            else:
                # Default to string
                serialized[key] = {'S': str(value)}

        return serialized

    def _serialize_value(self, value):
        """
        Serialize a single value to DynamoDB format.

        Args:
            value: Value to serialize

        Returns:
            DynamoDB formatted value
        """
        if value is None:
            return {'NULL': True}
        elif isinstance(value, str):
            return {'S': value}
        elif isinstance(value, bool):
            return {'BOOL': value}
        elif isinstance(value, (int, float)):
            return {'N': str(value)}
        elif isinstance(value, list):
            return {'L': [self._serialize_value(v) for v in value]}
        elif isinstance(value, dict):
            return {'M': self._serialize_item(value)}
        else:
            return {'S': str(value)}

    def _deserialize_item(self, item: dict) -> dict:
        """
        Deserialize DynamoDB item to Python dict.

        Args:
            item: DynamoDB formatted dictionary

        Returns:
            Python dictionary
        """
        deserialized = {}

        for key, value in item.items():
            if 'S' in value:
                deserialized[key] = value['S']
            elif 'N' in value:
                # Try int first, fall back to float
                try:
                    deserialized[key] = int(value['N'])
                except ValueError:
                    deserialized[key] = float(value['N'])
            elif 'BOOL' in value:
                deserialized[key] = value['BOOL']
            elif 'NULL' in value:
                deserialized[key] = None
            elif 'L' in value:
                deserialized[key] = [self._deserialize_value(v) for v in value['L']]
            elif 'M' in value:
                deserialized[key] = self._deserialize_item(value['M'])

        return deserialized

    def _deserialize_value(self, value: dict):
        """
        Deserialize a single DynamoDB value.

        Args:
            value: DynamoDB formatted value

        Returns:
            Python value
        """
        if 'S' in value:
            return value['S']
        elif 'N' in value:
            try:
                return int(value['N'])
            except ValueError:
                return float(value['N'])
        elif 'BOOL' in value:
            return value['BOOL']
        elif 'NULL' in value:
            return None
        elif 'L' in value:
            return [self._deserialize_value(v) for v in value['L']]
        elif 'M' in value:
            return self._deserialize_item(value['M'])
        return None
