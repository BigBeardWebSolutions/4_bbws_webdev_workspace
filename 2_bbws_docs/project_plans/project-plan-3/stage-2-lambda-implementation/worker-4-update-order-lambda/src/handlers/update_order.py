"""
Lambda handler for update_order API endpoint.

Endpoint: PUT /v1.0/orders/{orderId}
Purpose: Update order status and/or payment details with optimistic locking

Environment Variables:
    DYNAMODB_TABLE_NAME: DynamoDB table name for orders
    LOG_LEVEL: Logging level (DEBUG, INFO, WARN, ERROR)
"""

import json
import logging
import os
from typing import Dict, Any

import boto3
from pydantic import ValidationError

from src.dao.order_dao import OrderDAO
from src.services.order_service import OrderService
from src.models.requests import UpdateOrderRequest
from src.utils.exceptions import (
    BusinessException,
    OrderNotFoundException,
    OptimisticLockException,
    InvalidOrderStateException,
    UnexpectedException
)
from src.utils.logger import configure_logger

# Configure logging
logger = configure_logger(__name__)

# Initialize AWS clients (outside handler for connection reuse)
dynamodb_client = boto3.client('dynamodb')
table_name = os.environ.get('DYNAMODB_TABLE_NAME', 'bbws-customer-portal-orders-dev')

# Initialize DAO and Service (singleton pattern)
order_dao = OrderDAO(dynamodb_client, table_name)
order_service = OrderService(order_dao)


def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lambda handler for updating an order.

    Request Path: PUT /v1.0/orders/{orderId}
    Request Body:
    {
        "status": "paid",  // optional
        "paymentDetails": {  // optional
            "method": "credit_card",
            "transactionId": "txn-abc123",
            "paidAt": "2025-12-30T11:00:00Z"
        }
    }

    Response (200 OK):
    {
        "success": true,
        "data": {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "status": "paid",
            "paymentDetails": {...},
            "dateLastUpdated": "2025-12-30T11:00:05Z",
            ...
        }
    }

    Error Responses:
    - 400: Invalid request body or business rule violation
    - 404: Order not found
    - 409: Optimistic locking failure (concurrent update)
    - 500: Internal server error

    Args:
        event: API Gateway event with path parameters and body
        context: Lambda context object

    Returns:
        API Gateway response with updated order or error
    """
    try:
        # Log request
        logger.info(f"Processing update_order request: {json.dumps(event, default=str)}")

        # Extract path parameters
        order_id = event.get('pathParameters', {}).get('orderId')
        if not order_id:
            logger.error("Missing orderId in path parameters")
            return _error_response(400, "Bad Request", "Missing orderId in path")

        # Extract tenant ID from JWT token
        tenant_id = _extract_tenant_id(event)
        if not tenant_id:
            logger.error("Missing tenantId in JWT claims")
            return _error_response(403, "Forbidden", "Missing tenantId in authorization")

        # Extract updated_by from JWT (email or sub)
        updated_by = _extract_user_email(event)

        # Parse and validate request body
        body = json.loads(event.get('body', '{}'))
        update_request = UpdateOrderRequest.parse_obj(body)

        logger.info(
            f"Update request: orderId={order_id}, tenantId={tenant_id}, "
            f"status={update_request.status}, hasPaymentDetails={update_request.paymentDetails is not None}"
        )

        # Call service layer
        updated_order = order_service.update_order(
            tenant_id=tenant_id,
            order_id=order_id,
            update_request=update_request,
            updated_by=updated_by
        )

        # Build success response
        response_data = updated_order.dict(exclude_none=True)

        logger.info(f"Order updated successfully: orderId={order_id}")

        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'success': True,
                'data': response_data
            }, default=str)
        }

    except ValidationError as e:
        logger.error(f"Validation error: {str(e)}")
        return _error_response(400, "Bad Request", f"Invalid request: {str(e)}")

    except OrderNotFoundException as e:
        logger.warning(f"Order not found: {str(e)}")
        return _error_response(404, "Not Found", e.message)

    except OptimisticLockException as e:
        logger.warning(f"Optimistic lock failure: {str(e)}")
        return _error_response(409, "Conflict", e.message)

    except InvalidOrderStateException as e:
        logger.warning(f"Invalid order state: {str(e)}")
        return _error_response(400, "Bad Request", e.message)

    except BusinessException as e:
        logger.error(f"Business exception: {str(e)}")
        return _error_response(400, "Bad Request", e.message)

    except UnexpectedException as e:
        logger.error(f"Unexpected exception: {str(e)}", exc_info=True)
        return _error_response(500, "Internal Server Error", "An unexpected error occurred")

    except Exception as e:
        logger.error(f"Unhandled exception: {str(e)}", exc_info=True)
        return _error_response(500, "Internal Server Error", "An unexpected error occurred")


def _extract_tenant_id(event: Dict[str, Any]) -> str:
    """
    Extract tenant ID from JWT token in API Gateway event.

    Args:
        event: API Gateway event

    Returns:
        Tenant ID or empty string if not found
    """
    try:
        # Cognito authorizer places claims in requestContext
        claims = event.get('requestContext', {}).get('authorizer', {}).get('claims', {})
        return claims.get('custom:tenantId', '')
    except Exception as e:
        logger.warning(f"Failed to extract tenantId: {str(e)}")
        return ''


def _extract_user_email(event: Dict[str, Any]) -> str:
    """
    Extract user email from JWT token.

    Args:
        event: API Gateway event

    Returns:
        User email or 'system' if not found
    """
    try:
        claims = event.get('requestContext', {}).get('authorizer', {}).get('claims', {})
        return claims.get('email', claims.get('cognito:username', 'system'))
    except Exception as e:
        logger.warning(f"Failed to extract user email: {str(e)}")
        return 'system'


def _error_response(status_code: int, error: str, message: str) -> Dict[str, Any]:
    """
    Build error response.

    Args:
        status_code: HTTP status code
        error: Error type
        message: Error message

    Returns:
        API Gateway error response
    """
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({
            'success': False,
            'error': error,
            'message': message
        })
    }
