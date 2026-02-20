"""
OrderPDFCreator Lambda Handler.

SQS-triggered Lambda function that generates PDF invoices for orders
and uploads them to S3.

Event Flow:
1. Receive SQS message with order creation event
2. Fetch order details from DynamoDB
3. Generate PDF invoice using ReportLab
4. Upload PDF to S3 bucket
5. Update order record with pdfUrl

Timeout: 60s (longer than other Lambdas due to PDF generation)
"""

import json
import logging
import os
from typing import Dict, Any, List
import boto3
from src.dao.order_dao import OrderDAO
from src.services.pdf_service import PDFService
from src.services.s3_service import S3Service

# Configure logging
logger = logging.getLogger()
logger.setLevel(os.environ.get('LOG_LEVEL', 'INFO'))

# Initialize AWS clients (outside handler for connection reuse)
dynamodb_client = boto3.client('dynamodb')
s3_client = boto3.client('s3')

# Environment variables
DYNAMODB_TABLE_NAME = os.environ.get('DYNAMODB_TABLE_NAME', 'bbws-customer-portal-orders-dev')
S3_BUCKET_NAME = os.environ.get('S3_ORDERS_BUCKET', 'bbws-orders-dev')
COMPANY_NAME = os.environ.get('COMPANY_NAME', 'BBWS')

# Initialize services
order_dao = OrderDAO(dynamodb_client, DYNAMODB_TABLE_NAME)
pdf_service = PDFService(company_name=COMPANY_NAME)
s3_service = S3Service(s3_client, S3_BUCKET_NAME)


def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lambda handler for OrderPDFCreator.

    Processes SQS messages containing order creation events, generates PDF
    invoices, and uploads them to S3.

    Args:
        event: SQS event containing batch of order creation messages
        context: Lambda context object

    Returns:
        Dictionary with batchItemFailures for partial batch failure handling

    SQS Event Structure:
    {
        "Records": [
            {
                "messageId": "...",
                "receiptHandle": "...",
                "body": "{\"orderId\": \"...\", \"tenantId\": \"...\", ...}",
                "attributes": {...},
                "messageAttributes": {...}
            }
        ]
    }
    """
    logger.info(f"OrderPDFCreator invoked with {len(event.get('Records', []))} messages")

    # Track failed messages for partial batch failure
    failed_message_ids = []

    # Process each SQS message
    for record in event.get('Records', []):
        message_id = record.get('messageId')

        try:
            # Parse message body
            message_body = json.loads(record['body'])
            logger.info(f"Processing message {message_id}: {json.dumps(message_body)}")

            # Extract order identifiers
            order_id = message_body.get('orderId')
            tenant_id = message_body.get('tenantId')

            if not order_id or not tenant_id:
                logger.error(f"Missing orderId or tenantId in message {message_id}")
                failed_message_ids.append(message_id)
                continue

            # Process the order PDF generation
            process_order_pdf(tenant_id, order_id)

            logger.info(f"Successfully processed message {message_id}")

        except Exception as e:
            logger.error(
                f"Error processing message {message_id}: {str(e)}",
                exc_info=True
            )
            # Add to failed messages for retry
            failed_message_ids.append(message_id)

    # Return partial batch failure response
    # SQS will retry only the failed messages
    if failed_message_ids:
        logger.warning(f"Failed to process {len(failed_message_ids)} messages: {failed_message_ids}")
        return {
            'batchItemFailures': [
                {'itemIdentifier': msg_id} for msg_id in failed_message_ids
            ]
        }

    logger.info("All messages processed successfully")
    return {'batchItemFailures': []}


def process_order_pdf(tenant_id: str, order_id: str) -> None:
    """
    Process PDF generation for a single order.

    Steps:
    1. Fetch order from DynamoDB
    2. Check if PDF already exists (idempotency)
    3. Generate PDF invoice
    4. Upload to S3
    5. Update order record with pdfUrl

    Args:
        tenant_id: Tenant identifier
        order_id: Order identifier

    Raises:
        ValueError: If order not found
        Exception: If PDF generation or upload fails
    """
    logger.info(f"Processing PDF for order: tenantId={tenant_id}, orderId={order_id}")

    # Step 1: Fetch order from DynamoDB
    order = order_dao.get_order(tenant_id, order_id)

    if not order:
        logger.error(f"Order not found: tenantId={tenant_id}, orderId={order_id}")
        # Don't fail - order might not be created yet (eventual consistency)
        # Let SQS retry
        raise ValueError(f"Order not found: {order_id}")

    # Step 2: Check if PDF already exists (idempotency)
    if order.pdfUrl:
        logger.info(f"PDF already exists for order {order_id}: {order.pdfUrl}")
        # Check if file actually exists in S3
        if s3_service.check_pdf_exists(tenant_id, order_id):
            logger.info(f"PDF confirmed in S3, skipping regeneration")
            return
        else:
            logger.warning(f"PDF URL exists but file missing in S3, regenerating")

    # Step 3: Generate PDF invoice
    logger.info(f"Generating PDF for order {order.orderNumber}")
    pdf_bytes = pdf_service.generate_invoice_pdf(order)
    logger.info(f"PDF generated: {len(pdf_bytes)} bytes")

    # Step 4: Upload to S3
    logger.info(f"Uploading PDF to S3")
    pdf_url = s3_service.upload_pdf(pdf_bytes, tenant_id, order_id)
    logger.info(f"PDF uploaded successfully: {pdf_url}")

    # Step 5: Update order record with pdfUrl
    order.pdfUrl = pdf_url
    order_dao.update_order(order)
    logger.info(f"Order updated with PDF URL: {order_id}")

    logger.info(f"PDF processing complete for order {order_id}")
