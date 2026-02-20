"""
Integration tests for get_order Lambda.

Tests the complete Lambda flow with mocked AWS services using moto.
"""
import pytest
import json
import os
from decimal import Decimal
from moto import mock_dynamodb
import boto3

from src.handlers.get_order import lambda_handler


@mock_dynamodb
class TestGetOrderIntegration:
    """Integration test suite for get_order Lambda."""

    @pytest.fixture(autouse=True)
    def setup(self):
        """Set up test environment with mocked DynamoDB."""
        # Set environment variables
        os.environ['DYNAMODB_TABLE_NAME'] = 'test-orders-table'
        os.environ['LOG_LEVEL'] = 'DEBUG'

        # Create mock DynamoDB table
        dynamodb = boto3.resource('dynamodb', region_name='af-south-1')
        table = dynamodb.create_table(
            TableName='test-orders-table',
            KeySchema=[
                {'AttributeName': 'PK', 'KeyType': 'HASH'},
                {'AttributeName': 'SK', 'KeyType': 'RANGE'}
            ],
            AttributeDefinitions=[
                {'AttributeName': 'PK', 'AttributeType': 'S'},
                {'AttributeName': 'SK', 'AttributeType': 'S'}
            ],
            BillingMode='PAY_PER_REQUEST'
        )

        # Insert test order
        table.put_item(Item={
            'PK': 'TENANT#tenant_123',
            'SK': 'ORDER#order_456',
            'id': 'order_456',
            'orderNumber': 'ORD-20251230-0001',
            'tenantId': 'tenant_123',
            'customerEmail': 'test@example.com',
            'items': [
                {
                    'id': 'item_789',
                    'productId': 'prod_001',
                    'productName': 'Test Product',
                    'quantity': Decimal('1'),
                    'unitPrice': Decimal('100.00'),
                    'discount': Decimal('10.00'),
                    'subtotal': Decimal('90.00'),
                    'dateCreated': '2025-12-30T10:00:00Z',
                    'dateLastUpdated': '2025-12-30T10:00:00Z',
                    'lastUpdatedBy': 'system',
                    'active': True
                }
            ],
            'subtotal': Decimal('90.00'),
            'tax': Decimal('13.50'),
            'total': Decimal('103.50'),
            'currency': 'ZAR',
            'status': 'PENDING_PAYMENT',
            'billingAddress': {
                'street': '123 Test St',
                'city': 'Test City',
                'province': 'Test Province',
                'postalCode': '1234',
                'country': 'ZA'
            },
            'paymentMethod': 'payfast',
            'dateCreated': '2025-12-30T10:00:00Z',
            'dateLastUpdated': '2025-12-30T10:00:00Z',
            'lastUpdatedBy': 'system',
            'active': True
        })

        yield

        # Cleanup
        table.delete()

    def test_get_order_success_integration(self):
        """Test successful order retrieval through complete flow."""
        # Arrange
        event = {
            'pathParameters': {
                'orderId': 'order_456'
            },
            'requestContext': {
                'authorizer': {
                    'claims': {
                        'custom:tenantId': 'tenant_123'
                    }
                }
            }
        }

        # Act
        # Need to reload the handler module to pick up new DynamoDB client
        import importlib
        from src.handlers import get_order as get_order_module
        importlib.reload(get_order_module)

        response = get_order_module.lambda_handler(event, None)

        # Assert
        assert response['statusCode'] == 200
        body = json.loads(response['body'])
        assert body['success'] is True
        assert body['data']['id'] == 'order_456'
        assert body['data']['orderNumber'] == 'ORD-20251230-0001'
        assert body['data']['total'] == 103.50  # Converted from Decimal

    def test_get_order_not_found_integration(self):
        """Test order not found scenario."""
        # Arrange
        event = {
            'pathParameters': {
                'orderId': 'order_999'  # Non-existent
            },
            'requestContext': {
                'authorizer': {
                    'claims': {
                        'custom:tenantId': 'tenant_123'
                    }
                }
            }
        }

        # Act
        import importlib
        from src.handlers import get_order as get_order_module
        importlib.reload(get_order_module)

        response = get_order_module.lambda_handler(event, None)

        # Assert
        assert response['statusCode'] == 404
        body = json.loads(response['body'])
        assert body['error'] == 'Not Found'

    def test_get_order_tenant_isolation(self):
        """Test tenant isolation - different tenant cannot access order."""
        # Arrange
        event = {
            'pathParameters': {
                'orderId': 'order_456'
            },
            'requestContext': {
                'authorizer': {
                    'claims': {
                        'custom:tenantId': 'tenant_999'  # Different tenant
                    }
                }
            }
        }

        # Act
        import importlib
        from src.handlers import get_order as get_order_module
        importlib.reload(get_order_module)

        response = get_order_module.lambda_handler(event, None)

        # Assert
        assert response['statusCode'] == 404
        body = json.loads(response['body'])
        assert body['error'] == 'Not Found'
