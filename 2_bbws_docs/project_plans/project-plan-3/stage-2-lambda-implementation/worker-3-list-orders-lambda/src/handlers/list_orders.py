"""
Lambda handler for GET /v1.0/tenants/{tenantId}/orders.

Implements list_orders functionality with pagination and tenant isolation.
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

# Pagination constants
DEFAULT_PAGE_SIZE = 50
MAX_PAGE_SIZE = 100


def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lambda handler for GET /v1.0/tenants/{tenantId}/orders.

    Lists all orders for a tenant with pagination support.
    Extracts tenantId from path parameters and pagination parameters from query string.

    Args:
        event: API Gateway event containing:
            - pathParameters.tenantId: Tenant identifier
            - queryStringParameters.pageSize: Number of items to return (optional, default 50, max 100)
            - queryStringParameters.startAt: Pagination token for continuation (optional)
        context: Lambda context object

    Returns:
        API Gateway response with:
            - 200: List of orders with pagination metadata
            - 400: Bad request (invalid parameters)
            - 500: Internal server error

    Example event:
        {
            "pathParameters": {
                "tenantId": "tenant_bb0e8400-e29b-41d4-a716-446655440006"
            },
            "queryStringParameters": {
                "pageSize": "20",
                "startAt": null
            }
        }
    """
    try:
        logger.info(f"Processing list_orders request: {json.dumps(event)}")

        # Extract tenantId from path parameters
        path_parameters = event.get('pathParameters', {})
        if not path_parameters:
            logger.error("Missing pathParameters in event")
            return _build_response(400, {'error': 'Bad Request', 'message': 'Missing path parameters'})

        tenant_id = path_parameters.get('tenantId')
        if not tenant_id:
            logger.error("Missing tenantId in pathParameters")
            return _build_response(400, {'error': 'Bad Request', 'message': 'Missing tenantId'})

        # Extract and validate pagination parameters
        query_parameters = event.get('queryStringParameters', {}) or {}

        # Parse pageSize
        page_size = DEFAULT_PAGE_SIZE
        if 'pageSize' in query_parameters:
            try:
                page_size = int(query_parameters['pageSize'])
                if page_size <= 0 or page_size > MAX_PAGE_SIZE:
                    logger.error(f"Invalid pageSize: {page_size}")
                    return _build_response(400, {
                        'error': 'Bad Request',
                        'message': f'pageSize must be between 1 and {MAX_PAGE_SIZE}'
                    })
            except ValueError:
                logger.error(f"Invalid pageSize format: {query_parameters['pageSize']}")
                return _build_response(400, {'error': 'Bad Request', 'message': 'pageSize must be an integer'})

        # Parse startAt (pagination token)
        start_at = query_parameters.get('startAt')

        logger.info(f"Fetching orders: tenantId={tenant_id}, pageSize={page_size}, startAt={start_at}")

        # Query DynamoDB using tenant query (PK=TENANT#{tenantId}, SK begins_with ORDER#)
        result = order_dao.find_by_tenant_id(tenant_id, page_size, start_at)

        # Convert Order objects to dicts for JSON response
        items_dicts = [order.dict() for order in result['items']]

        logger.info(f"Orders retrieved successfully: tenantId={tenant_id}, count={len(items_dicts)}, "
                   f"moreAvailable={result['moreAvailable']}")

        return _build_response(200, {
            'success': True,
            'data': {
                'items': items_dicts,
                'startAt': result['startAt'],
                'moreAvailable': result['moreAvailable']
            }
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
