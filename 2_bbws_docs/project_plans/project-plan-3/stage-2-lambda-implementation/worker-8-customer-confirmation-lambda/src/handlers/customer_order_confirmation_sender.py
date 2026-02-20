"""
CustomerOrderConfirmationSender Lambda Handler.

Processes SQS messages for new orders and sends customer confirmation emails
with presigned S3 URLs for order PDF invoices.

Trigger: SQS (bbws-order-creation-{env})
Target: SES (customer email address)
"""

import json
import logging
from typing import Any, Dict, List

from src.dao.order_dao import OrderDAO
from src.services.email_service import EmailService

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lambda handler for CustomerOrderConfirmationSender.

    Processes SQS messages containing order creation events and sends
    customer confirmation emails with presigned S3 invoice URLs.

    Args:
        event: SQS event with Records array
        context: Lambda context object

    Returns:
        Response dict with statusCode and batchItemFailures for partial batch retry
    """
    logger.info(f"CustomerOrderConfirmationSender invoked: {len(event.get('Records', []))} records")

    # Initialize dependencies
    order_dao = OrderDAO()
    email_service = EmailService()

    batch_item_failures = []
    successful_count = 0
    failed_count = 0

    # Process each SQS record
    for record in event.get('Records', []):
        message_id = record.get('messageId')

        try:
            # Parse message body
            body = json.loads(record['body'])
            tenant_id = body['tenantId']
            order_id = body['orderId']

            logger.info(f"Processing message {message_id}: tenantId={tenant_id}, orderId={order_id}")

            # Retrieve order from DynamoDB
            order = order_dao.get_order(tenant_id, order_id)

            if not order:
                logger.warning(f"Order not found: tenantId={tenant_id}, orderId={order_id}")
                # Treat as success (idempotent - order may have been deleted)
                successful_count += 1
                continue

            # Send customer confirmation email
            message_id_ses = email_service.send_customer_confirmation(order)
            logger.info(f"Customer confirmation sent for order {order_id}: SES MessageId={message_id_ses}")

            successful_count += 1

        except KeyError as e:
            logger.error(f"Missing required field in message {message_id}: {str(e)}")
            # Report as failure for retry
            batch_item_failures.append({
                'itemIdentifier': message_id
            })
            failed_count += 1

        except json.JSONDecodeError as e:
            logger.error(f"Invalid JSON in message {message_id}: {str(e)}")
            # Report as failure for retry
            batch_item_failures.append({
                'itemIdentifier': message_id
            })
            failed_count += 1

        except Exception as e:
            logger.error(f"Error processing message {message_id}: {str(e)}", exc_info=True)
            # Report as failure for retry
            batch_item_failures.append({
                'itemIdentifier': message_id
            })
            failed_count += 1

    # Log summary
    logger.info(f"Batch processing complete: {successful_count} succeeded, {failed_count} failed")

    # Return response with partial batch failure support
    return {
        'statusCode': 200,
        'batchItemFailures': batch_item_failures
    }
