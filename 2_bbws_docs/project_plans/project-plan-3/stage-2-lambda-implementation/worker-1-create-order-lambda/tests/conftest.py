"""Shared pytest fixtures for all tests.

This module provides common fixtures used across unit and integration tests.
"""

import pytest
import json
from typing import Dict, Any


@pytest.fixture
def valid_order_item() -> Dict[str, Any]:
    """Fixture for a valid order item.

    Returns:
        Dictionary representing a valid order item
    """
    return {
        'productId': 'prod-123',
        'productName': 'WordPress Professional Plan',
        'quantity': 2,
        'unitPrice': 50.00
    }


@pytest.fixture
def valid_billing_address() -> Dict[str, Any]:
    """Fixture for a valid billing address.

    Returns:
        Dictionary representing a valid billing address
    """
    return {
        'fullName': 'John Doe',
        'addressLine1': '123 Main St',
        'city': 'Cape Town',
        'stateProvince': 'Western Cape',
        'postalCode': '8001',
        'country': 'ZA'
    }


@pytest.fixture
def valid_create_order_request(valid_order_item, valid_billing_address) -> Dict[str, Any]:
    """Fixture for a valid create order request body.

    Args:
        valid_order_item: Order item fixture
        valid_billing_address: Billing address fixture

    Returns:
        Dictionary representing a valid create order request
    """
    return {
        'customerEmail': 'customer@example.com',
        'items': [valid_order_item],
        'billingAddress': valid_billing_address,
        'campaignCode': 'SUMMER2025'
    }


@pytest.fixture
def api_gateway_event(valid_create_order_request) -> Dict[str, Any]:
    """Fixture for an API Gateway proxy event.

    Args:
        valid_create_order_request: Valid request body fixture

    Returns:
        Dictionary representing API Gateway event
    """
    return {
        'httpMethod': 'POST',
        'path': '/v1.0/orders',
        'body': json.dumps(valid_create_order_request),
        'requestContext': {
            'requestId': 'test-request-123',
            'authorizer': {
                'claims': {
                    'custom:tenantId': 'tenant-123',
                    'sub': 'user-456'
                }
            }
        },
        'headers': {
            'Content-Type': 'application/json'
        }
    }


@pytest.fixture
def lambda_context():
    """Fixture for Lambda context.

    Returns:
        Mock Lambda context object
    """
    class LambdaContext:
        def __init__(self):
            self.function_name = 'create_order'
            self.memory_limit_in_mb = 512
            self.invoked_function_arn = 'arn:aws:lambda:af-south-1:123456789012:function:create_order'
            self.aws_request_id = 'test-request-123'
            self.request_id = 'test-request-123'

    return LambdaContext()
