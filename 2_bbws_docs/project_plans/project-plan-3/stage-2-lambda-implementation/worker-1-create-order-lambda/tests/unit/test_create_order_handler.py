"""Unit tests for create_order Lambda handler.

This module tests the Lambda handler logic with mocked dependencies.
"""

import pytest
import json
import os
from unittest.mock import Mock, patch, MagicMock
from src.handlers.create_order import lambda_handler


class TestCreateOrderHandler:
    """Test cases for create_order Lambda handler."""

    @pytest.fixture(autouse=True)
    def setup_env(self):
        """Set up environment variables for tests."""
        os.environ['SQS_QUEUE_URL'] = 'https://sqs.test.queue.url'
        os.environ['LOG_LEVEL'] = 'INFO'

    def test_create_order_success(self, api_gateway_event, lambda_context):
        """Test successful order creation."""
        with patch('src.handlers.create_order.sqs_service') as mock_sqs:
            # Arrange
            mock_sqs.publish_order_message.return_value = 'msg-123'

            # Act
            response = lambda_handler(api_gateway_event, lambda_context)

            # Assert
            assert response['statusCode'] == 202
            assert 'body' in response

            body = json.loads(response['body'])
            assert body['success'] is True
            assert 'data' in body
            assert 'orderId' in body['data']
            assert body['data']['status'] == 'pending'
            assert body['data']['message'] == 'Order accepted for processing'

            # Verify SQS was called
            mock_sqs.publish_order_message.assert_called_once()

            # Verify order data structure
            call_args = mock_sqs.publish_order_message.call_args
            order_data = call_args[0][0]
            assert 'orderId' in order_data
            assert order_data['tenantId'] == 'tenant-123'
            assert order_data['userId'] == 'user-456'
            assert order_data['customerEmail'] == 'customer@example.com'
            assert order_data['status'] == 'pending'
            assert 'dateCreated' in order_data
            assert 'items' in order_data
            assert 'billingAddress' in order_data

    def test_create_order_with_campaign_code(self, api_gateway_event, lambda_context):
        """Test order creation with campaign code."""
        with patch('src.handlers.create_order.sqs_service') as mock_sqs:
            # Arrange
            mock_sqs.publish_order_message.return_value = 'msg-123'

            # Act
            response = lambda_handler(api_gateway_event, lambda_context)

            # Assert
            assert response['statusCode'] == 202

            # Verify campaign code is included
            call_args = mock_sqs.publish_order_message.call_args
            order_data = call_args[0][0]
            assert order_data['campaignCode'] == 'SUMMER2025'

    def test_create_order_without_campaign_code(self, api_gateway_event, lambda_context):
        """Test order creation without campaign code."""
        with patch('src.handlers.create_order.sqs_service') as mock_sqs:
            # Arrange
            mock_sqs.publish_order_message.return_value = 'msg-123'
            body = json.loads(api_gateway_event['body'])
            del body['campaignCode']
            api_gateway_event['body'] = json.dumps(body)

            # Act
            response = lambda_handler(api_gateway_event, lambda_context)

            # Assert
            assert response['statusCode'] == 202

            # Verify campaign code is None
            call_args = mock_sqs.publish_order_message.call_args
            order_data = call_args[0][0]
            assert order_data['campaignCode'] is None

    def test_create_order_invalid_json(self, api_gateway_event, lambda_context):
        """Test order creation with invalid JSON."""
        # Arrange
        api_gateway_event['body'] = '{invalid json'

        # Act
        response = lambda_handler(api_gateway_event, lambda_context)

        # Assert
        assert response['statusCode'] == 400
        body = json.loads(response['body'])
        assert body['success'] is False
        assert 'error' in body
        assert 'JSON' in body['message']

    def test_create_order_invalid_email(self, api_gateway_event, lambda_context):
        """Test order creation with invalid email."""
        # Arrange
        body = json.loads(api_gateway_event['body'])
        body['customerEmail'] = 'invalid-email'
        api_gateway_event['body'] = json.dumps(body)

        # Act
        response = lambda_handler(api_gateway_event, lambda_context)

        # Assert
        assert response['statusCode'] == 400
        body = json.loads(response['body'])
        assert body['success'] is False
        assert 'email' in body['message'].lower()

    def test_create_order_missing_items(self, api_gateway_event, lambda_context):
        """Test order creation without items."""
        # Arrange
        body = json.loads(api_gateway_event['body'])
        body['items'] = []
        api_gateway_event['body'] = json.dumps(body)

        # Act
        response = lambda_handler(api_gateway_event, lambda_context)

        # Assert
        assert response['statusCode'] == 400
        body = json.loads(response['body'])
        assert body['success'] is False

    def test_create_order_invalid_quantity(self, api_gateway_event, lambda_context):
        """Test order creation with invalid item quantity."""
        # Arrange
        body = json.loads(api_gateway_event['body'])
        body['items'][0]['quantity'] = 0
        api_gateway_event['body'] = json.dumps(body)

        # Act
        response = lambda_handler(api_gateway_event, lambda_context)

        # Assert
        assert response['statusCode'] == 400
        body = json.loads(response['body'])
        assert body['success'] is False

    def test_create_order_missing_billing_address(self, api_gateway_event, lambda_context):
        """Test order creation without billing address."""
        # Arrange
        body = json.loads(api_gateway_event['body'])
        del body['billingAddress']
        api_gateway_event['body'] = json.dumps(body)

        # Act
        response = lambda_handler(api_gateway_event, lambda_context)

        # Assert
        assert response['statusCode'] == 400
        body = json.loads(response['body'])
        assert body['success'] is False

    def test_create_order_missing_tenant_id_claim(self, api_gateway_event, lambda_context):
        """Test order creation without tenantId in JWT."""
        # Arrange
        del api_gateway_event['requestContext']['authorizer']['claims']['custom:tenantId']

        # Act
        response = lambda_handler(api_gateway_event, lambda_context)

        # Assert
        assert response['statusCode'] == 400
        body = json.loads(response['body'])
        assert body['success'] is False
        assert 'tenantId' in body['message'].lower()

    def test_create_order_missing_user_id_claim(self, api_gateway_event, lambda_context):
        """Test order creation without sub (userId) in JWT."""
        # Arrange
        del api_gateway_event['requestContext']['authorizer']['claims']['sub']

        # Act
        response = lambda_handler(api_gateway_event, lambda_context)

        # Assert
        assert response['statusCode'] == 400
        body = json.loads(response['body'])
        assert body['success'] is False
        assert 'sub' in body['message'].lower() or 'user' in body['message'].lower()

    def test_create_order_sqs_failure(self, api_gateway_event, lambda_context):
        """Test SQS publish failure."""
        with patch('src.handlers.create_order.sqs_service') as mock_sqs:
            # Arrange
            mock_sqs.publish_order_message.side_effect = Exception("SQS connection failed")

            # Act
            response = lambda_handler(api_gateway_event, lambda_context)

            # Assert
            assert response['statusCode'] == 500
            body = json.loads(response['body'])
            assert body['success'] is False
            assert body['error'] == 'Internal Server Error'

    def test_create_order_generates_unique_order_id(self, api_gateway_event, lambda_context):
        """Test that each request generates a unique order ID."""
        with patch('src.handlers.create_order.sqs_service') as mock_sqs:
            # Arrange
            mock_sqs.publish_order_message.return_value = 'msg-123'

            # Act - make two requests
            response1 = lambda_handler(api_gateway_event, lambda_context)
            response2 = lambda_handler(api_gateway_event, lambda_context)

            # Assert
            body1 = json.loads(response1['body'])
            body2 = json.loads(response2['body'])

            order_id_1 = body1['data']['orderId']
            order_id_2 = body2['data']['orderId']

            assert order_id_1 != order_id_2  # Different order IDs

    def test_create_order_response_headers(self, api_gateway_event, lambda_context):
        """Test that response includes proper CORS headers."""
        with patch('src.handlers.create_order.sqs_service') as mock_sqs:
            # Arrange
            mock_sqs.publish_order_message.return_value = 'msg-123'

            # Act
            response = lambda_handler(api_gateway_event, lambda_context)

            # Assert
            assert 'headers' in response
            headers = response['headers']
            assert headers['Content-Type'] == 'application/json'
            assert headers['Access-Control-Allow-Origin'] == '*'
            assert headers['Access-Control-Allow-Credentials'] is True

    def test_create_order_email_lowercase(self, api_gateway_event, lambda_context):
        """Test that customer email is converted to lowercase."""
        with patch('src.handlers.create_order.sqs_service') as mock_sqs:
            # Arrange
            mock_sqs.publish_order_message.return_value = 'msg-123'
            body = json.loads(api_gateway_event['body'])
            body['customerEmail'] = 'CUSTOMER@EXAMPLE.COM'
            api_gateway_event['body'] = json.dumps(body)

            # Act
            response = lambda_handler(api_gateway_event, lambda_context)

            # Assert
            assert response['statusCode'] == 202

            call_args = mock_sqs.publish_order_message.call_args
            order_data = call_args[0][0]
            assert order_data['customerEmail'] == 'customer@example.com'

    def test_create_order_country_code_uppercase(self, api_gateway_event, lambda_context):
        """Test that country code is converted to uppercase."""
        with patch('src.handlers.create_order.sqs_service') as mock_sqs:
            # Arrange
            mock_sqs.publish_order_message.return_value = 'msg-123'
            body = json.loads(api_gateway_event['body'])
            body['billingAddress']['country'] = 'za'  # lowercase
            api_gateway_event['body'] = json.dumps(body)

            # Act
            response = lambda_handler(api_gateway_event, lambda_context)

            # Assert
            assert response['statusCode'] == 202

            call_args = mock_sqs.publish_order_message.call_args
            order_data = call_args[0][0]
            assert order_data['billingAddress']['country'] == 'ZA'

    def test_create_order_timestamp_format(self, api_gateway_event, lambda_context):
        """Test that dateCreated is in ISO 8601 format."""
        with patch('src.handlers.create_order.sqs_service') as mock_sqs:
            # Arrange
            mock_sqs.publish_order_message.return_value = 'msg-123'

            # Act
            response = lambda_handler(api_gateway_event, lambda_context)

            # Assert
            assert response['statusCode'] == 202

            call_args = mock_sqs.publish_order_message.call_args
            order_data = call_args[0][0]

            # Verify timestamp format (ISO 8601 with Z suffix)
            assert 'dateCreated' in order_data
            assert order_data['dateCreated'].endswith('Z')
            assert 'T' in order_data['dateCreated']
