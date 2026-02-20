"""Unit tests for SQS service.

This module tests the SQS message publishing logic.
"""

import pytest
import json
from unittest.mock import Mock, MagicMock
from src.services.sqs_service import SQSService


class TestSQSService:
    """Test cases for SQSService class."""

    @pytest.fixture
    def mock_sqs_client(self):
        """Create a mock SQS client.

        Returns:
            Mock SQS client
        """
        return Mock()

    @pytest.fixture
    def sqs_service(self, mock_sqs_client):
        """Create SQS service with mock client.

        Args:
            mock_sqs_client: Mock SQS client fixture

        Returns:
            SQSService instance
        """
        return SQSService(mock_sqs_client, 'https://sqs.test.queue.url')

    @pytest.fixture
    def sample_order_data(self):
        """Create sample order data.

        Returns:
            Order data dictionary
        """
        return {
            'orderId': 'order-123',
            'tenantId': 'tenant-456',
            'customerEmail': 'test@example.com',
            'items': [
                {
                    'productId': 'prod-1',
                    'productName': 'Test Product',
                    'quantity': 1,
                    'unitPrice': 10.00
                }
            ],
            'billingAddress': {
                'fullName': 'John Doe',
                'addressLine1': '123 St',
                'city': 'City',
                'stateProvince': 'State',
                'postalCode': '12345',
                'country': 'ZA'
            },
            'status': 'pending',
            'dateCreated': '2025-12-30T10:30:00Z'
        }

    def test_publish_order_message_success(self, sqs_service, mock_sqs_client, sample_order_data):
        """Test successful message publishing."""
        # Arrange
        mock_sqs_client.send_message.return_value = {'MessageId': 'msg-123'}

        # Act
        message_id = sqs_service.publish_order_message(sample_order_data)

        # Assert
        assert message_id == 'msg-123'
        mock_sqs_client.send_message.assert_called_once()

        # Verify call arguments
        call_args = mock_sqs_client.send_message.call_args
        assert call_args.kwargs['QueueUrl'] == 'https://sqs.test.queue.url'

        # Verify message body
        message_body = json.loads(call_args.kwargs['MessageBody'])
        assert message_body['orderId'] == 'order-123'
        assert message_body['tenantId'] == 'tenant-456'

        # Verify message attributes
        message_attrs = call_args.kwargs['MessageAttributes']
        assert message_attrs['tenantId']['StringValue'] == 'tenant-456'
        assert message_attrs['tenantId']['DataType'] == 'String'
        assert message_attrs['orderId']['StringValue'] == 'order-123'
        assert message_attrs['orderId']['DataType'] == 'String'

    def test_publish_order_message_with_missing_tenant_id(self, sqs_service, mock_sqs_client):
        """Test publishing message with missing tenantId."""
        # Arrange
        mock_sqs_client.send_message.return_value = {'MessageId': 'msg-456'}
        order_data = {
            'orderId': 'order-123',
            'customerEmail': 'test@example.com'
            # Missing tenantId
        }

        # Act
        message_id = sqs_service.publish_order_message(order_data)

        # Assert
        assert message_id == 'msg-456'
        call_args = mock_sqs_client.send_message.call_args
        message_attrs = call_args.kwargs['MessageAttributes']
        assert message_attrs['tenantId']['StringValue'] == ''  # Default empty string

    def test_publish_order_message_failure(self, sqs_service, mock_sqs_client, sample_order_data):
        """Test message publishing failure."""
        # Arrange
        mock_sqs_client.send_message.side_effect = Exception("SQS error")

        # Act & Assert
        with pytest.raises(Exception) as exc_info:
            sqs_service.publish_order_message(sample_order_data)

        assert "SQS error" in str(exc_info.value)
        mock_sqs_client.send_message.assert_called_once()

    def test_publish_order_message_serializes_complex_data(
        self,
        sqs_service,
        mock_sqs_client,
        sample_order_data
    ):
        """Test that complex order data is properly serialized."""
        # Arrange
        mock_sqs_client.send_message.return_value = {'MessageId': 'msg-789'}

        # Act
        sqs_service.publish_order_message(sample_order_data)

        # Assert
        call_args = mock_sqs_client.send_message.call_args
        message_body = call_args.kwargs['MessageBody']

        # Verify it's valid JSON
        parsed_data = json.loads(message_body)

        # Verify nested structures are preserved
        assert isinstance(parsed_data['items'], list)
        assert len(parsed_data['items']) == 1
        assert parsed_data['items'][0]['productId'] == 'prod-1'
        assert isinstance(parsed_data['billingAddress'], dict)
        assert parsed_data['billingAddress']['country'] == 'ZA'

    def test_sqs_service_initialization(self, mock_sqs_client):
        """Test SQS service initialization."""
        # Act
        service = SQSService(mock_sqs_client, 'https://test.queue.url')

        # Assert
        assert service.sqs == mock_sqs_client
        assert service.queue_url == 'https://test.queue.url'

    def test_publish_preserves_all_order_fields(
        self,
        sqs_service,
        mock_sqs_client,
        sample_order_data
    ):
        """Test that all order fields are preserved in the message."""
        # Arrange
        mock_sqs_client.send_message.return_value = {'MessageId': 'msg-999'}

        # Add additional fields
        sample_order_data['campaignCode'] = 'SUMMER2025'
        sample_order_data['userId'] = 'user-789'

        # Act
        sqs_service.publish_order_message(sample_order_data)

        # Assert
        call_args = mock_sqs_client.send_message.call_args
        message_body = json.loads(call_args.kwargs['MessageBody'])

        # Verify all fields are present
        assert message_body['orderId'] == 'order-123'
        assert message_body['tenantId'] == 'tenant-456'
        assert message_body['customerEmail'] == 'test@example.com'
        assert message_body['campaignCode'] == 'SUMMER2025'
        assert message_body['userId'] == 'user-789'
        assert message_body['status'] == 'pending'
        assert 'dateCreated' in message_body
