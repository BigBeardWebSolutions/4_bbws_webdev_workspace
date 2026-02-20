"""
Lambda handler for GET /v1.0/orders/{orderId}.

Implements get_order functionality with tenant isolation and error handling.
"""
import json
import logging
import os
from typing import Dict, Any
import boto3

from src.dao.order_dao import OrderDAO

# Configure logging
logger = logging.getLogger()
logger.setLevel(os.environ.get('LOG_LEVEL', 'INFO'))

# Initialize AWS clients (outside handler for connection reuse)
dynamodb_client = boto3.client('dynamodb')
table_name = os.environ.get('DYNAMODB_TABLE_NAME', 'bbws-customer-portal-orders-dev')

# Initialize DAO
order_dao = OrderDAO(dynamodb_client, table_name)


def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lambda handler for GET /v1.0/orders/{orderId}.

    Retrieves order details from DynamoDB using tenant isolation (PK+SK query).
    Extracts tenantId from JWT token and orderId from path parameters.

    Args:
        event: API Gateway event containing:
            - pathParameters.orderId: Order identifier
            - requestContext.authorizer.claims.custom:tenantId: Tenant identifier (from JWT)
        context: Lambda context object

    Returns:
        API Gateway response with:
            - 200: Order details
            - 404: Order not found or not authorized for tenant
            - 500: Internal server error

    Example event:
        {
            "pathParameters": {
                "orderId": "order_aa0e8400-e29b-41d4-a716-446655440005"
            },
            "requestContext": {
                "authorizer": {
                    "claims": {
                        "custom:tenantId": "tenant_bb0e8400-e29b-41d4-a716-446655440006"
                    }
                }
            }
        }
    """
    try:
        logger.info(f"Processing get_order request: {json.dumps(event)}")

        # Extract orderId from path parameters
        path_parameters = event.get('pathParameters', {})
        if not path_parameters:
            logger.error("Missing pathParameters in event")
            return _build_response(400, {'error': 'Bad Request', 'message': 'Missing path parameters'})

        order_id = path_parameters.get('orderId')
        if not order_id:
            logger.error("Missing orderId in pathParameters")
            return _build_response(400, {'error': 'Bad Request', 'message': 'Missing orderId'})

        # Extract tenantId from JWT token
        tenant_id = _extract_tenant_id(event)
        if not tenant_id:
            logger.error("Missing tenantId in JWT claims")
            return _build_response(401, {'error': 'Unauthorized', 'message': 'Missing tenant identifier'})

        logger.info(f"Fetching order: tenantId={tenant_id}, orderId={order_id}")

        # Query DynamoDB using PK+SK (tenant isolation)
        order = order_dao.get_order(tenant_id, order_id)

        if not order:
            logger.warning(f"Order not found: tenantId={tenant_id}, orderId={order_id}")
            return _build_response(404, {'error': 'Not Found', 'message': f'Order not found: {order_id}'})

        # Convert Order object to dict for JSON response
        order_dict = order.dict()

        logger.info(f"Order retrieved successfully: orderId={order_id}")
        return _build_response(200, {
            'success': True,
            'data': order_dict
        })

    except ValueError as e:
        # Business logic errors (expected)
        logger.error(f"Validation error: {str(e)}")
        return _build_response(400, {'error': 'Bad Request', 'message': str(e)})

    except Exception as e:
        # Unexpected system errors
        logger.error(f"Internal error: {str(e)}", exc_info=True)
        return _build_response(500, {
            'error': 'Internal Server Error',
            'message': 'An unexpected error occurred'
        })


def _extract_tenant_id(event: Dict[str, Any]) -> str:
    """
    Extract tenantId from JWT claims in API Gateway event.

    Args:
        event: API Gateway event

    Returns:
        Tenant identifier from JWT claims, or empty string if not found
    """
    try:
        # Path: requestContext.authorizer.claims.custom:tenantId
        claims = event.get('requestContext', {}).get('authorizer', {}).get('claims', {})
        tenant_id = claims.get('custom:tenantId', '')
        return tenant_id
    except Exception as e:
        logger.error(f"Error extracting tenantId from JWT: {str(e)}")
        return ''


def _build_response(status_code: int, body: Dict[str, Any]) -> Dict[str, Any]:
    """
    Build API Gateway response with CORS headers.

    Args:
        status_code: HTTP status code
        body: Response body dictionary

    Returns:
        API Gateway response object
    """
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type,Authorization',
            'Access-Control-Allow-Methods': 'GET,OPTIONS'
        },
        'body': json.dumps(body)
    }
