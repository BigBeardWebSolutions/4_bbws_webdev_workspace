"""
OrderCreatorRecord Lambda Handler.

This is the CRITICAL Lambda function that creates order records in DynamoDB
after order creation requests are published to SQS.

Trigger: SQS (bbws-order-creation-{env})
Target: DynamoDB (bbws-customer-portal-orders-{env})
"""

import json
import logging
import os
from typing import Dict, Any, List
from datetime import datetime
import uuid

import boto3
from pydantic import ValidationError

from ..dao.order_dao import OrderDAO
from ..services.cart_service import CartService
from ..models.order import Order
from ..models.order_item import OrderItem
from ..models.campaign import Campaign
from ..models.billing_address import BillingAddress
from ..models.payment_details import PaymentDetails

# Configure logging
logger = logging.getLogger()
logger.setLevel(os.environ.get('LOG_LEVEL', 'INFO'))

# Initialize AWS clients (outside handler for connection reuse)
dynamodb_client = boto3.client('dynamodb')
table_name = os.environ.get('DYNAMODB_TABLE_NAME', 'bbws-customer-portal-orders-dev')

# Initialize DAO and Services
order_dao = OrderDAO(dynamodb_client, table_name)
cart_service = CartService(cart_api_url=os.environ.get('CART_LAMBDA_API_URL'))


def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lambda handler for OrderCreatorRecord.

    Processes SQS batch messages to create order records in DynamoDB.

    Args:
        event: SQS event with batch of up to 10 messages
        context: Lambda context object

    Returns:
        Dictionary with batch item failures for partial failure handling

    SQS Message Format:
        {
            "orderId": "order_uuid",
            "tenantId": "tenant_uuid",
            "customerEmail": "customer@example.com",
            "cartId": "cart_uuid",
            "campaignCode": "SUMMER2025" (optional),
            "billingAddress": {...},
            "paymentMethod": "payfast"
        }

    Response Format (Partial Batch Failure):
        {
            "batchItemFailures": [
                {"itemIdentifier": "messageId"}
            ]
        }
    """
    logger.info(f"Processing SQS batch with {len(event.get('Records', []))} messages")

    batch_item_failures = []

    # Process each message in the batch
    for record in event.get('Records', []):
        message_id = record.get('messageId')
        receipt_handle = record.get('receiptHandle')

        try:
            # Parse SQS message body
            message_body = json.loads(record['body'])
            logger.info(f"Processing message {message_id}: orderId={message_body.get('orderId')}")

            # Process the order message
            order = process_order_message(message_body)

            # Create order in DynamoDB
            created_order = order_dao.create_order(order)

            logger.info(
                f"Successfully created order: {created_order.id} "
                f"(orderNumber: {created_order.orderNumber}) "
                f"for tenant: {created_order.tenantId}"
            )

        except ValidationError as e:
            # Pydantic validation error - invalid message format
            logger.error(
                f"Validation error for message {message_id}: {str(e)}",
                exc_info=True
            )
            # Add to failures for retry
            batch_item_failures.append({"itemIdentifier": message_id})

        except ValueError as e:
            # Business logic error (e.g., duplicate order)
            logger.error(
                f"Business logic error for message {message_id}: {str(e)}",
                exc_info=True
            )
            # If duplicate, don't retry (idempotent)
            if "already exists" in str(e):
                logger.warning(f"Order already exists, skipping retry for message {message_id}")
            else:
                # Other business errors should retry
                batch_item_failures.append({"itemIdentifier": message_id})

        except Exception as e:
            # Unexpected error - add to failures for retry
            logger.error(
                f"Unexpected error processing message {message_id}: {str(e)}",
                exc_info=True
            )
            batch_item_failures.append({"itemIdentifier": message_id})

    # Log summary
    total_messages = len(event.get('Records', []))
    failed_messages = len(batch_item_failures)
    successful_messages = total_messages - failed_messages

    logger.info(
        f"Batch processing complete. "
        f"Total: {total_messages}, "
        f"Successful: {successful_messages}, "
        f"Failed: {failed_messages}"
    )

    # Return partial batch failures for SQS retry
    return {"batchItemFailures": batch_item_failures}


def process_order_message(message: Dict[str, Any]) -> Order:
    """
    Process order message and create Order object.

    Steps:
    1. Extract order data from message
    2. Fetch cart data from Cart Lambda
    3. Generate order number
    4. Validate and enrich order data
    5. Create Order object

    Args:
        message: SQS message body

    Returns:
        Order object ready for DynamoDB

    Raises:
        ValidationError: If message data is invalid
        ValueError: If business logic validation fails
    """
    # Extract required fields
    order_id = message.get('orderId')
    tenant_id = message.get('tenantId')
    customer_email = message.get('customerEmail')
    cart_id = message.get('cartId')
    campaign_code = message.get('campaignCode')  # Optional
    billing_address_data = message.get('billingAddress')
    payment_method = message.get('paymentMethod', 'payfast')

    # Validate required fields
    if not all([order_id, tenant_id, customer_email, cart_id, billing_address_data]):
        raise ValueError(
            "Missing required fields: orderId, tenantId, customerEmail, cartId, billingAddress"
        )

    logger.info(f"Processing order {order_id}: Fetching cart {cart_id}")

    # Fetch cart data from Cart Lambda
    cart_data = cart_service.get_cart(cart_id, tenant_id)

    # Validate cart data
    if not cart_service.validate_cart(cart_data):
        raise ValueError(f"Invalid cart data for cart {cart_id}")

    logger.info(f"Cart fetched: {len(cart_data['items'])} items, total: {cart_data['total']}")

    # Generate order number using atomic counter
    order_number = order_dao.get_next_order_number(tenant_id)

    logger.info(f"Generated order number: {order_number}")

    # Convert cart items to OrderItem objects
    now = datetime.utcnow().isoformat() + "Z"
    order_items = []

    for cart_item in cart_data['items']:
        order_item = OrderItem(
            id=cart_item['id'],
            productId=cart_item['productId'],
            productName=cart_item['productName'],
            quantity=cart_item['quantity'],
            unitPrice=cart_item['unitPrice'],
            discount=cart_item.get('discount', 0.0),
            subtotal=cart_item['subtotal'],
            dateCreated=cart_item.get('dateCreated', now),
            dateLastUpdated=cart_item.get('dateLastUpdated', now),
            lastUpdatedBy=cart_item.get('lastUpdatedBy', 'system'),
            active=cart_item.get('active', True)
        )
        order_items.append(order_item)

    # Parse billing address
    billing_address = BillingAddress(**billing_address_data)

    # Parse campaign (optional)
    campaign = None
    if campaign_code and 'campaign' in message:
        campaign_data = message['campaign']
        campaign = Campaign(**campaign_data)

    # Create Order object
    order = Order(
        id=order_id,
        orderNumber=order_number,
        tenantId=tenant_id,
        customerEmail=customer_email,
        items=order_items,
        subtotal=cart_data['subtotal'],
        tax=cart_data['tax'],
        total=cart_data['total'],
        currency=cart_data['currency'],
        status='PENDING_PAYMENT',
        campaign=campaign,
        billingAddress=billing_address,
        paymentMethod=payment_method,
        paymentDetails=None,  # Will be populated after payment
        dateCreated=now,
        dateLastUpdated=now,
        lastUpdatedBy=customer_email,
        active=True
    )

    logger.info(
        f"Order object created: {order.id}, "
        f"orderNumber={order.orderNumber}, "
        f"total={order.total} {order.currency}"
    )

    return order
