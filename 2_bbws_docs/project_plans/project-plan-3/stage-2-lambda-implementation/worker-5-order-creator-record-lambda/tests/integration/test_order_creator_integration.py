"""
Integration tests for OrderCreatorRecord Lambda using moto.
"""

import pytest
import json
import os
import boto3
from moto import mock_dynamodb
from datetime import datetime

from src.handlers.order_creator_record import lambda_handler
from src.dao.order_dao import OrderDAO


@mock_dynamodb
class TestOrderCreatorIntegration:
    """Integration tests with mocked AWS services."""

    @pytest.fixture
    def dynamodb_table(self):
        """Create mocked DynamoDB table."""
        # Create mocked DynamoDB resource
        dynamodb = boto3.resource('dynamodb', region_name='us-east-1')

        # Create table
        table = dynamodb.create_table(
            TableName='test-orders-table',
            KeySchema=[
                {'AttributeName': 'PK', 'KeyType': 'HASH'},
                {'AttributeName': 'SK', 'KeyType': 'RANGE'}
            ],
            AttributeDefinitions=[
                {'AttributeName': 'PK', 'AttributeType': 'S'},
                {'AttributeName': 'SK', 'AttributeType': 'S'},
                {'AttributeName': 'GSI1_PK', 'AttributeType': 'S'},
                {'AttributeName': 'GSI1_SK', 'AttributeType': 'S'},
                {'AttributeName': 'GSI2_PK', 'AttributeType': 'S'},
                {'AttributeName': 'GSI2_SK', 'AttributeType': 'S'}
            ],
            GlobalSecondaryIndexes=[
                {
                    'IndexName': 'OrdersByDateIndex',
                    'KeySchema': [
                        {'AttributeName': 'GSI1_PK', 'KeyType': 'HASH'},
                        {'AttributeName': 'GSI1_SK', 'KeyType': 'RANGE'}
                    ],
                    'Projection': {'ProjectionType': 'ALL'}
                },
                {
                    'IndexName': 'OrderByIdIndex',
                    'KeySchema': [
                        {'AttributeName': 'GSI2_PK', 'KeyType': 'HASH'},
                        {'AttributeName': 'GSI2_SK', 'KeyType': 'RANGE'}
                    ],
                    'Projection': {'ProjectionType': 'ALL'}
                }
            ],
            BillingMode='PAY_PER_REQUEST'
        )

        return table

    @pytest.fixture
    def setup_environment(self, dynamodb_table):
        """Setup environment variables."""
        os.environ['DYNAMODB_TABLE_NAME'] = 'test-orders-table'
        os.environ['CART_LAMBDA_API_URL'] = 'https://api-dev.bbws.io/v1.0/cart'
        yield
        # Cleanup
        if 'DYNAMODB_TABLE_NAME' in os.environ:
            del os.environ['DYNAMODB_TABLE_NAME']
        if 'CART_LAMBDA_API_URL' in os.environ:
            del os.environ['CART_LAMBDA_API_URL']

    def test_end_to_end_order_creation(self, dynamodb_table, setup_environment, sample_sqs_event):
        """Test complete order creation flow with mocked DynamoDB."""
        # Note: This test will use the mocked CartService which returns dummy data
        # In a real integration test, we would mock the Cart Lambda API as well

        # Execute Lambda handler
        result = lambda_handler(sample_sqs_event, None)

        # Verify no failures
        assert result['batchItemFailures'] == []

        # Verify order was written to DynamoDB
        response = dynamodb_table.scan()
        items = response['Items']

        # Should have 2 items: 1 order + 1 counter
        assert len(items) >= 1

        # Find the order item (not the counter)
        order_items = [item for item in items if item.get('entityType') == 'ORDER']
        assert len(order_items) == 1

        order_item = order_items[0]

        # Verify order attributes
        assert order_item['PK'].startswith('TENANT#')
        assert order_item['SK'].startswith('ORDER#')
        assert order_item['entityType'] == 'ORDER'
        assert 'orderNumber' in order_item
        assert order_item['status'] == 'PENDING_PAYMENT'
        assert 'total' in order_item
        assert 'items' in order_item

        # Verify GSI keys
        assert 'GSI1_PK' in order_item
        assert 'GSI1_SK' in order_item
        assert 'GSI2_PK' in order_item
        assert 'GSI2_SK' in order_item

    def test_atomic_counter_increments(self, dynamodb_table, setup_environment, sample_sqs_message, sample_tenant_id):
        """Test that order numbers increment atomically."""
        # Create multiple SQS events
        events = []
        for i in range(3):
            event = {
                'Records': [
                    {
                        'messageId': f'msg-{i}',
                        'receiptHandle': f'receipt-{i}',
                        'body': json.dumps({
                            **sample_sqs_message,
                            'orderId': f'order-{i}'
                        })
                    }
                ]
            }
            events.append(event)

        # Process events
        for event in events:
            lambda_handler(event, None)

        # Verify 3 orders were created with sequential numbers
        response = dynamodb_table.scan()
        order_items = [item for item in response['Items'] if item.get('entityType') == 'ORDER']

        assert len(order_items) == 3

        # Extract order numbers
        order_numbers = sorted([item['orderNumber'] for item in order_items])

        # Verify they are sequential (same date, incrementing sequence)
        # Format: ORD-YYYYMMDD-NNNNN
        assert order_numbers[0].endswith('-00001')
        assert order_numbers[1].endswith('-00002')
        assert order_numbers[2].endswith('-00003')

    def test_duplicate_order_idempotency(self, dynamodb_table, setup_environment, sample_sqs_event):
        """Test that duplicate orders are handled idempotently."""
        # Process same event twice
        result1 = lambda_handler(sample_sqs_event, None)
        result2 = lambda_handler(sample_sqs_event, None)

        # First should succeed
        assert result1['batchItemFailures'] == []

        # Second should fail but not retry (idempotent)
        assert result2['batchItemFailures'] == []

        # Verify only one order in database
        response = dynamodb_table.scan()
        order_items = [item for item in response['Items'] if item.get('entityType') == 'ORDER']

        assert len(order_items) == 1

    def test_order_retrieval_by_pk_sk(self, dynamodb_table, setup_environment, sample_sqs_event, sample_tenant_id, sample_order_id):
        """Test retrieving order using PK+SK access pattern (AP1)."""
        # Create order
        lambda_handler(sample_sqs_event, None)

        # Create DAO and retrieve order
        dynamodb_client = boto3.client('dynamodb', region_name='us-east-1')
        order_dao = OrderDAO(dynamodb_client, 'test-orders-table')

        # Note: We need to extract the actual tenant_id and order_id from the event
        message = json.loads(sample_sqs_event['Records'][0]['body'])
        tenant_id = message['tenantId']
        order_id = message['orderId']

        # Retrieve order
        order = order_dao.get_order(tenant_id, order_id)

        # Verify order was retrieved
        assert order is not None
        assert order.tenantId == tenant_id
        assert order.id == order_id
        assert order.status == 'PENDING_PAYMENT'
