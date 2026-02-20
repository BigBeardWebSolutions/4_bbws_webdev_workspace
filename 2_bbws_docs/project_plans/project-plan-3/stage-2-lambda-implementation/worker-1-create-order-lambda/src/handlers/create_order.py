"""Lambda handler for creating new orders.

This module implements the create_order Lambda function which accepts order
requests via API Gateway, validates the data, and publishes to SQS for
asynchronous processing.
"""

import json
import logging
import os
import uuid
from datetime import datetime
from typing import Dict, Any
import boto3
from src.models.requests import CreateOrderRequest
from src.models.responses import CreateOrderResponse
from src.services.sqs_service import SQSService


# Configure logging
logger = logging.getLogger()
logger.setLevel(os.environ.get('LOG_LEVEL', 'INFO'))

# Initialize SQS client outside handler for reuse (Lambda container reuse optimization)
sqs_client = boto3.client('sqs')
sqs_queue_url = os.environ.get('SQS_QUEUE_URL', '')
sqs_service = SQSService(sqs_client, sqs_queue_url)


def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """Lambda handler for creating new orders.

    Accepts order requests via API Gateway, validates the data using Pydantic,
    generates a unique order ID, and publishes to SQS for asynchronous processing.

    The handler performs the following steps:
    1. Extract tenantId and userId from JWT claims
    2. Parse and validate request body against CreateOrderRequest schema
    3. Generate unique orderId (UUID v4)
    4. Enrich order data with metadata (timestamp, status, tenant/user info)
    5. Publish complete order data to SQS
    6. Return 202 Accepted response with orderId

    Args:
        event: API Gateway proxy event containing:
            - body: JSON request body
            - requestContext.authorizer.claims: JWT claims with tenantId and userId
        context: Lambda context object

    Returns:
        API Gateway response dictionary:
            - statusCode: 202 (Accepted), 400 (Bad Request), or 500 (Internal Error)
            - headers: CORS headers
            - body: JSON response with order details or error message

    Response Examples:
        Success (202):
            {
                "statusCode": 202,
                "body": {
                    "success": true,
                    "data": {
                        "orderId": "550e8400-e29b-41d4-a716-446655440000",
                        "orderNumber": null,
                        "status": "pending",
                        "message": "Order accepted for processing"
                    }
                }
            }

        Validation Error (400):
            {
                "statusCode": 400,
                "body": {
                    "success": false,
                    "error": "Validation Error",
                    "message": "Invalid email address"
                }
            }

        Internal Error (500):
            {
                "statusCode": 500,
                "body": {
                    "success": false,
                    "error": "Internal Server Error",
                    "message": "An unexpected error occurred"
                }
            }
    """
    try:
        # Log incoming request (exclude sensitive data in production)
        logger.info("Processing create order request", extra={
            'request_id': context.request_id if context else 'unknown',
            'http_method': event.get('httpMethod', 'unknown')
        })

        # Extract tenant ID and user ID from JWT claims
        tenant_id = _extract_tenant_id(event)
        user_id = _extract_user_id(event)

        logger.info("Extracted JWT claims", extra={
            'tenant_id': tenant_id,
            'user_id': user_id
        })

        # Parse request body
        body_str = event.get('body', '{}')
        try:
            body_data = json.loads(body_str) if isinstance(body_str, str) else body_str
        except json.JSONDecodeError as e:
            logger.warning(f"Invalid JSON in request body: {str(e)}")
            return _error_response(400, "Invalid JSON in request body")

        # Validate request using Pydantic model
        try:
            request = CreateOrderRequest(**body_data)
        except Exception as e:
            logger.warning(f"Request validation failed: {str(e)}")
            return _error_response(400, f"Validation Error: {str(e)}")

        # Generate unique order ID (UUID v4)
        order_id = str(uuid.uuid4())
        logger.info(f"Generated order ID: {order_id}")

        # Build enriched order data for SQS
        order_data = _build_order_data(
            order_id=order_id,
            tenant_id=tenant_id,
            user_id=user_id,
            request=request
        )

        # Publish to SQS
        message_id = sqs_service.publish_order_message(order_data)
        logger.info(
            "Order message published to SQS",
            extra={
                'order_id': order_id,
                'message_id': message_id,
                'tenant_id': tenant_id
            }
        )

        # Build response
        response_data = CreateOrderResponse(
            orderId=order_id,
            orderNumber=None,  # Will be assigned by Worker 5 (OrderCreatorRecord)
            status="pending",
            message="Order accepted for processing"
        )

        return _success_response(202, response_data.dict())

    except ValueError as e:
        # Business logic errors (validation, etc.)
        logger.error(f"Validation error: {str(e)}", exc_info=True)
        return _error_response(400, str(e))

    except Exception as e:
        # Unexpected system errors
        logger.error(f"Internal error: {str(e)}", exc_info=True)
        return _error_response(500, "An unexpected error occurred")


def _extract_tenant_id(event: Dict[str, Any]) -> str:
    """Extract tenant ID from JWT claims.

    Args:
        event: API Gateway event

    Returns:
        Tenant ID string

    Raises:
        ValueError: If tenantId claim is missing
    """
    try:
        claims = event['requestContext']['authorizer']['claims']
        tenant_id = claims.get('custom:tenantId')

        if not tenant_id:
            raise ValueError("Missing tenantId in JWT claims")

        return tenant_id
    except (KeyError, TypeError) as e:
        logger.error(f"Failed to extract tenantId from JWT: {str(e)}")
        raise ValueError("Invalid JWT structure - missing tenantId")


def _extract_user_id(event: Dict[str, Any]) -> str:
    """Extract user ID from JWT claims.

    Args:
        event: API Gateway event

    Returns:
        User ID string (sub claim)

    Raises:
        ValueError: If sub claim is missing
    """
    try:
        claims = event['requestContext']['authorizer']['claims']
        user_id = claims.get('sub')

        if not user_id:
            raise ValueError("Missing sub (user ID) in JWT claims")

        return user_id
    except (KeyError, TypeError) as e:
        logger.error(f"Failed to extract userId from JWT: {str(e)}")
        raise ValueError("Invalid JWT structure - missing sub")


def _build_order_data(
    order_id: str,
    tenant_id: str,
    user_id: str,
    request: CreateOrderRequest
) -> Dict[str, Any]:
    """Build enriched order data for SQS message.

    Args:
        order_id: Generated order ID
        tenant_id: Tenant ID from JWT
        user_id: User ID from JWT
        request: Validated CreateOrderRequest

    Returns:
        Complete order data dictionary
    """
    current_time = datetime.utcnow().isoformat() + 'Z'

    return {
        'orderId': order_id,
        'tenantId': tenant_id,
        'userId': user_id,
        'customerEmail': request.customerEmail,
        'items': [item.dict() for item in request.items],
        'billingAddress': request.billingAddress.dict(),
        'campaignCode': request.campaignCode,
        'dateCreated': current_time,
        'status': 'pending',
        'createdBy': user_id
    }


def _success_response(status_code: int, data: Dict[str, Any]) -> Dict[str, Any]:
    """Build successful API Gateway response.

    Args:
        status_code: HTTP status code
        data: Response data dictionary

    Returns:
        API Gateway response dictionary
    """
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Credentials': True
        },
        'body': json.dumps({
            'success': True,
            'data': data
        })
    }


def _error_response(status_code: int, message: str) -> Dict[str, Any]:
    """Build error API Gateway response.

    Args:
        status_code: HTTP status code
        message: Error message

    Returns:
        API Gateway response dictionary
    """
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Credentials': True
        },
        'body': json.dumps({
            'success': False,
            'error': 'Bad Request' if status_code == 400 else 'Internal Server Error',
            'message': message
        })
    }
