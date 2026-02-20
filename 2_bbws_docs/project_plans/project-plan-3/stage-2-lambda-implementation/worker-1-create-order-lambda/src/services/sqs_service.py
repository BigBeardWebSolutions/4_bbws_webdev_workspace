"""SQS service for publishing order messages.

This module provides a service class for publishing order creation messages
to Amazon SQS for asynchronous processing.
"""

import json
import logging
from typing import Dict, Any


logger = logging.getLogger(__name__)


class SQSService:
    """Service for SQS operations.

    This service handles publishing order creation messages to SQS with
    appropriate message attributes for routing and filtering.

    Attributes:
        sqs: Boto3 SQS client
        queue_url: SQS queue URL for order creation messages
    """

    def __init__(self, sqs_client, queue_url: str):
        """Initialize SQS service.

        Args:
            sqs_client: Boto3 SQS client instance
            queue_url: URL of the SQS queue
        """
        self.sqs = sqs_client
        self.queue_url = queue_url

    def publish_order_message(self, order_data: Dict[str, Any]) -> str:
        """Publish order creation message to SQS.

        Publishes the complete order data to SQS with message attributes
        for tenantId and orderId to enable filtering and routing.

        Args:
            order_data: Complete order data dictionary including:
                - orderId: Unique order identifier
                - tenantId: Tenant identifier
                - customerEmail: Customer email
                - items: List of order items
                - billingAddress: Billing address details
                - campaignCode: Optional campaign code
                - dateCreated: ISO 8601 timestamp
                - status: Order status

        Returns:
            SQS message ID

        Raises:
            Exception: If SQS publish fails (boto3 exceptions)

        Example:
            >>> service = SQSService(sqs_client, queue_url)
            >>> order_data = {
            ...     "orderId": "123e4567-e89b-12d3-a456-426614174000",
            ...     "tenantId": "tenant-123",
            ...     "customerEmail": "test@example.com",
            ...     "items": [...],
            ...     "billingAddress": {...},
            ...     "status": "pending"
            ... }
            >>> message_id = service.publish_order_message(order_data)
        """
        try:
            response = self.sqs.send_message(
                QueueUrl=self.queue_url,
                MessageBody=json.dumps(order_data),
                MessageAttributes={
                    'tenantId': {
                        'StringValue': order_data.get('tenantId', ''),
                        'DataType': 'String'
                    },
                    'orderId': {
                        'StringValue': order_data.get('orderId', ''),
                        'DataType': 'String'
                    }
                }
            )

            message_id = response['MessageId']
            logger.info(
                f"Published order to SQS",
                extra={
                    'message_id': message_id,
                    'order_id': order_data.get('orderId'),
                    'tenant_id': order_data.get('tenantId')
                }
            )
            return message_id

        except Exception as e:
            logger.error(
                f"Failed to publish to SQS: {str(e)}",
                extra={
                    'order_id': order_data.get('orderId'),
                    'tenant_id': order_data.get('tenantId')
                },
                exc_info=True
            )
            raise
