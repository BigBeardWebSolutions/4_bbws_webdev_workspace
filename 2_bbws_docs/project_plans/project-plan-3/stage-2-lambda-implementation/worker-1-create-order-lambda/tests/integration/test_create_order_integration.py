"""Integration tests for create_order Lambda.

This module tests the complete create order flow with mocked AWS services
using moto library.
"""

import pytest
import json
import os
from moto import mock_sqs
import boto3


# Note: These integration tests require moto library
# They test the full flow with mocked AWS services


@pytest.fixture
def sqs_queue():
    """Create a mocked SQS queue.

    Yields:
        Dictionary with queue URL and client
    """
    with mock_sqs():
        # Create SQS client
        sqs = boto3.client('sqs', region_name='af-south-1')

        # Create queue
        queue_response = sqs.create_queue(QueueName='test-order-queue')
        queue_url = queue_response['QueueUrl']

        yield {
            'client': sqs,
            'url': queue_url
        }


@mock_sqs
def test_create_order_full_flow(api_gateway_event, lambda_context):
    """Test complete create order flow with mocked SQS.

    This test verifies:
    1. Handler processes valid request
    2. Order message is published to SQS
    3. Message contains all expected fields
    4. Response is 202 Accepted
    """
    # Setup mock SQS
    sqs = boto3.client('sqs', region_name='af-south-1')
    queue_response = sqs.create_queue(QueueName='test-order-queue')
    queue_url = queue_response['QueueUrl']

    # Set environment variable
    os.environ['SQS_QUEUE_URL'] = queue_url

    # Import handler after setting environment
    from src.handlers import create_order
    # Reinitialize SQS service with new queue URL
    create_order.sqs_queue_url = queue_url
    from src.services.sqs_service import SQSService
    create_order.sqs_service = SQSService(sqs, queue_url)

    # Execute handler
    response = create_order.lambda_handler(api_gateway_event, lambda_context)

    # Verify response
    assert response['statusCode'] == 202
    body = json.loads(response['body'])
    assert body['success'] is True
    assert 'orderId' in body['data']

    # Verify SQS message
    messages = sqs.receive_message(
        QueueUrl=queue_url,
        MaxNumberOfMessages=1,
        MessageAttributeNames=['All']
    )

    assert 'Messages' in messages
    assert len(messages['Messages']) == 1

    message = messages['Messages'][0]

    # Verify message body
    message_body = json.loads(message['Body'])
    assert message_body['orderId'] == body['data']['orderId']
    assert message_body['tenantId'] == 'tenant-123'
    assert message_body['userId'] == 'user-456'
    assert message_body['customerEmail'] == 'customer@example.com'
    assert message_body['status'] == 'pending'
    assert 'items' in message_body
    assert 'billingAddress' in message_body
    assert 'dateCreated' in message_body

    # Verify message attributes
    assert 'MessageAttributes' in message
    msg_attrs = message['MessageAttributes']
    assert msg_attrs['tenantId']['StringValue'] == 'tenant-123'
    assert msg_attrs['orderId']['StringValue'] == body['data']['orderId']


@mock_sqs
def test_create_order_multiple_items(api_gateway_event, lambda_context):
    """Test order creation with multiple items."""
    # Setup mock SQS
    sqs = boto3.client('sqs', region_name='af-south-1')
    queue_response = sqs.create_queue(QueueName='test-order-queue-multi')
    queue_url = queue_response['QueueUrl']
    os.environ['SQS_QUEUE_URL'] = queue_url

    # Add multiple items to request
    body = json.loads(api_gateway_event['body'])
    body['items'].append({
        'productId': 'prod-456',
        'productName': 'Premium Plan',
        'quantity': 2,
        'unitPrice': 100.00
    })
    api_gateway_event['body'] = json.dumps(body)

    # Import and reinitialize
    from src.handlers import create_order
    create_order.sqs_queue_url = queue_url
    from src.services.sqs_service import SQSService
    create_order.sqs_service = SQSService(sqs, queue_url)

    # Execute
    response = create_order.lambda_handler(api_gateway_event, lambda_context)

    # Verify
    assert response['statusCode'] == 202

    # Check message
    messages = sqs.receive_message(QueueUrl=queue_url, MaxNumberOfMessages=1)
    message_body = json.loads(messages['Messages'][0]['Body'])
    assert len(message_body['items']) == 2
    assert message_body['items'][0]['productId'] == 'prod-123'
    assert message_body['items'][1]['productId'] == 'prod-456'


@mock_sqs
def test_create_order_idempotency(api_gateway_event, lambda_context):
    """Test that each request generates a unique order ID."""
    # Setup mock SQS
    sqs = boto3.client('sqs', region_name='af-south-1')
    queue_response = sqs.create_queue(QueueName='test-order-queue-idempotent')
    queue_url = queue_response['QueueUrl']
    os.environ['SQS_QUEUE_URL'] = queue_url

    from src.handlers import create_order
    create_order.sqs_queue_url = queue_url
    from src.services.sqs_service import SQSService
    create_order.sqs_service = SQSService(sqs, queue_url)

    # Execute twice
    response1 = create_order.lambda_handler(api_gateway_event, lambda_context)
    response2 = create_order.lambda_handler(api_gateway_event, lambda_context)

    # Verify different order IDs
    body1 = json.loads(response1['body'])
    body2 = json.loads(response2['body'])
    assert body1['data']['orderId'] != body2['data']['orderId']

    # Verify two messages in queue
    messages = sqs.receive_message(
        QueueUrl=queue_url,
        MaxNumberOfMessages=10
    )
    assert len(messages['Messages']) == 2


@mock_sqs
def test_create_order_with_optional_fields(api_gateway_event, lambda_context):
    """Test order creation with all optional fields."""
    # Setup mock SQS
    sqs = boto3.client('sqs', region_name='af-south-1')
    queue_response = sqs.create_queue(QueueName='test-order-queue-optional')
    queue_url = queue_response['QueueUrl']
    os.environ['SQS_QUEUE_URL'] = queue_url

    # Add optional addressLine2
    body = json.loads(api_gateway_event['body'])
    body['billingAddress']['addressLine2'] = 'Apartment 5B'
    api_gateway_event['body'] = json.dumps(body)

    from src.handlers import create_order
    create_order.sqs_queue_url = queue_url
    from src.services.sqs_service import SQSService
    create_order.sqs_service = SQSService(sqs, queue_url)

    # Execute
    response = create_order.lambda_handler(api_gateway_event, lambda_context)

    # Verify
    assert response['statusCode'] == 202

    messages = sqs.receive_message(QueueUrl=queue_url, MaxNumberOfMessages=1)
    message_body = json.loads(messages['Messages'][0]['Body'])
    assert message_body['billingAddress']['addressLine2'] == 'Apartment 5B'


@mock_sqs
def test_create_order_error_handling_invalid_data(api_gateway_event, lambda_context):
    """Test that invalid data returns 400 without publishing to SQS."""
    # Setup mock SQS
    sqs = boto3.client('sqs', region_name='af-south-1')
    queue_response = sqs.create_queue(QueueName='test-order-queue-error')
    queue_url = queue_response['QueueUrl']
    os.environ['SQS_QUEUE_URL'] = queue_url

    # Make request invalid
    body = json.loads(api_gateway_event['body'])
    body['customerEmail'] = 'invalid-email'  # No @ or .
    api_gateway_event['body'] = json.dumps(body)

    from src.handlers import create_order
    create_order.sqs_queue_url = queue_url
    from src.services.sqs_service import SQSService
    create_order.sqs_service = SQSService(sqs, queue_url)

    # Execute
    response = create_order.lambda_handler(api_gateway_event, lambda_context)

    # Verify error response
    assert response['statusCode'] == 400

    # Verify no message in queue
    messages = sqs.receive_message(QueueUrl=queue_url, MaxNumberOfMessages=1)
    assert 'Messages' not in messages  # Queue should be empty
