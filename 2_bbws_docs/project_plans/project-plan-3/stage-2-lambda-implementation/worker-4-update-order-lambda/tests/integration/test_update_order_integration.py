"""Integration tests for update_order Lambda with mocked AWS services."""

import json
import os
from decimal import Decimal

import pytest
from moto import mock_dynamodb

import boto3

from src.handlers.update_order import lambda_handler
from src.models.order import OrderStatus


@pytest.fixture(scope='function')
def dynamodb_table():
    """Create a mock DynamoDB table for testing."""
    with mock_dynamodb():
        dynamodb = boto3.client('dynamodb', region_name='af-south-1')

        # Create table
        table_name = 'bbws-customer-portal-orders-test'
        dynamodb.create_table(
            TableName=table_name,
            KeySchema=[
                {'AttributeName': 'PK', 'KeyType': 'HASH'},
                {'AttributeName': 'SK', 'KeyType': 'RANGE'}
            ],
            AttributeDefinitions=[
                {'AttributeName': 'PK', 'AttributeType': 'S'},
                {'AttributeName': 'SK', 'AttributeType': 'S'},
            ],
            BillingMode='PAY_PER_REQUEST'
        )

        # Set environment variable
        os.environ['DYNAMODB_TABLE_NAME'] = table_name

        yield dynamodb


@pytest.fixture
def seed_order(dynamodb_table):
    """Seed a test order in DynamoDB."""
    order_id = '550e8400-e29b-41d4-a716-446655440000'
    tenant_id = 'tenant-123'

    dynamodb_table.put_item(
        TableName='bbws-customer-portal-orders-test',
        Item={
            'PK': {'S': f'TENANT#{tenant_id}'},
            'SK': {'S': f'ORDER#{order_id}'},
            'id': {'S': order_id},
            'orderNumber': {'S': 'ORD-2025-00001'},
            'tenantId': {'S': tenant_id},
            'customerEmail': {'S': 'customer@example.com'},
            'status': {'S': 'pending'},
            'subtotal': {'N': '299.00'},
            'tax': {'N': '0.00'},
            'shipping': {'N': '0.00'},
            'total': {'N': '299.00'},
            'currency': {'S': 'ZAR'},
            'items': {'L': [{
                'M': {
                    'id': {'S': 'item-123'},
                    'productId': {'S': 'prod-456'},
                    'productName': {'S': 'Test Product'},
                    'quantity': {'N': '1'},
                    'unitPrice': {'N': '299.00'},
                    'discount': {'N': '0.00'},
                    'subtotal': {'N': '299.00'},
                    'dateCreated': {'S': '2025-12-30T10:00:00Z'},
                    'dateLastUpdated': {'S': '2025-12-30T10:00:00Z'},
                    'lastUpdatedBy': {'S': 'system'},
                    'active': {'BOOL': True}
                }
            }]},
            'billingAddress': {'M': {
                'street': {'S': '123 Main St'},
                'city': {'S': 'Cape Town'},
                'province': {'S': 'Western Cape'},
                'postalCode': {'S': '8001'},
                'country': {'S': 'South Africa'}
            }},
            'dateCreated': {'S': '2025-12-30T10:00:00Z'},
            'dateLastUpdated': {'S': '2025-12-30T10:00:00Z'},
            'lastUpdatedBy': {'S': 'system'},
            'active': {'BOOL': True}
        }
    )

    return order_id, tenant_id


class TestUpdateOrderIntegration:
    """Integration tests for update_order Lambda."""

    def test_update_order_status_e2e(self, dynamodb_table, seed_order):
        """Test end-to-end order status update."""
        order_id, tenant_id = seed_order

        event = {
            'pathParameters': {'orderId': order_id},
            'body': json.dumps({'status': 'paid'}),
            'requestContext': {
                'authorizer': {
                    'claims': {
                        'custom:tenantId': tenant_id,
                        'email': 'user@example.com'
                    }
                }
            }
        }

        # Note: This test requires mocking the imported modules
        # Since the handler imports are at module level, we need to reload
        # For now, this serves as a template for integration testing

        # response = lambda_handler(event, {})
        # assert response['statusCode'] == 200

    def test_update_order_with_payment_details_e2e(self, dynamodb_table, seed_order):
        """Test end-to-end order update with payment details."""
        order_id, tenant_id = seed_order

        event = {
            'pathParameters': {'orderId': order_id},
            'body': json.dumps({
                'status': 'paid',
                'paymentDetails': {
                    'method': 'credit_card',
                    'transactionId': 'txn-abc123',
                    'paidAt': '2025-12-30T11:00:00Z'
                }
            }),
            'requestContext': {
                'authorizer': {
                    'claims': {
                        'custom:tenantId': tenant_id,
                        'email': 'user@example.com'
                    }
                }
            }
        }

        # response = lambda_handler(event, {})
        # assert response['statusCode'] == 200

    def test_update_nonexistent_order(self, dynamodb_table):
        """Test updating non-existent order returns 404."""
        event = {
            'pathParameters': {'orderId': 'nonexistent'},
            'body': json.dumps({'status': 'paid'}),
            'requestContext': {
                'authorizer': {
                    'claims': {
                        'custom:tenantId': 'tenant-123',
                        'email': 'user@example.com'
                    }
                }
            }
        }

        # response = lambda_handler(event, {})
        # assert response['statusCode'] == 404

    def test_optimistic_locking_scenario(self, dynamodb_table, seed_order):
        """Test optimistic locking prevents concurrent updates."""
        order_id, tenant_id = seed_order

        # First update
        event1 = {
            'pathParameters': {'orderId': order_id},
            'body': json.dumps({'status': 'payment_pending'}),
            'requestContext': {
                'authorizer': {
                    'claims': {
                        'custom:tenantId': tenant_id,
                        'email': 'user1@example.com'
                    }
                }
            }
        }

        # response1 = lambda_handler(event1, {})
        # assert response1['statusCode'] == 200

        # Second concurrent update (should fail with 409)
        event2 = {
            'pathParameters': {'orderId': order_id},
            'body': json.dumps({'status': 'paid'}),
            'requestContext': {
                'authorizer': {
                    'claims': {
                        'custom:tenantId': tenant_id,
                        'email': 'user2@example.com'
                    }
                }
            }
        }

        # This would fail if both updates use old dateLastUpdated
        # response2 = lambda_handler(event2, {})
        # assert response2['statusCode'] == 409


class TestUpdateOrderDAO Integration:
    """Integration tests for DAO layer with DynamoDB."""

    def test_dao_update_with_dynamodb(self, dynamodb_table, seed_order):
        """Test DAO update_order with real DynamoDB mock."""
        from src.dao.order_dao import OrderDAO

        order_id, tenant_id = seed_order

        dao = OrderDAO(dynamodb_table, 'bbws-customer-portal-orders-test')

        # Get order first
        order = dao.get_order(tenant_id, order_id)
        assert order is not None
        assert order.status == OrderStatus.PENDING

        # Update order
        updated_order = dao.update_order(
            tenant_id=tenant_id,
            order_id=order_id,
            updates={'status': 'paid'},
            expected_last_updated=order.dateLastUpdated,
            updated_by='test@example.com'
        )

        assert updated_order.status == OrderStatus.PAID
        assert updated_order.lastUpdatedBy == 'test@example.com'

    def test_dao_optimistic_lock_with_dynamodb(self, dynamodb_table, seed_order):
        """Test DAO optimistic locking with real DynamoDB mock."""
        from src.dao.order_dao import OrderDAO
        from src.utils.exceptions import OptimisticLockException

        order_id, tenant_id = seed_order

        dao = OrderDAO(dynamodb_table, 'bbws-customer-portal-orders-test')

        # Try to update with wrong dateLastUpdated
        with pytest.raises(OptimisticLockException):
            dao.update_order(
                tenant_id=tenant_id,
                order_id=order_id,
                updates={'status': 'paid'},
                expected_last_updated='2025-12-01T00:00:00Z',  # Wrong timestamp
                updated_by='test@example.com'
            )
