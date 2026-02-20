"""Unit tests for OrderInternalNotificationSender Lambda handler."""

import json
import pytest
from unittest.mock import Mock, MagicMock, patch
from datetime import datetime

from src.handlers.order_internal_notification_sender import lambda_handler
from src.models import Order, OrderItem, Campaign, BillingAddress


class TestOrderInternalNotificationSenderHandler:
    """Test cases for OrderInternalNotificationSender Lambda handler."""

    @pytest.fixture
    def sample_order(self):
        """Create sample Order object."""
        return Order(
            orderId='order-123',
            tenantId='tenant-123',
            orderNumber='ORD-2025-001',
            customerEmail='customer@example.com',
            customerName='John Doe',
            items=[
                OrderItem(
                    itemId='item-123',
                    campaign=Campaign(
                        campaignId='campaign-123',
                        campaignName='Basic Website Package',
                        price=499.99
                    ),
                    quantity=1,
                    unitPrice=499.99,
                    subtotal=499.99
                )
            ],
            subtotal=499.99,
            tax=75.00,
            shipping=0.00,
            discount=0.00,
            total=574.99,
            orderStatus='pending',
            paymentStatus='pending',
            billingAddress=BillingAddress(
                street='123 Main St',
                city='Cape Town',
                postalCode='8001',
                country='ZA'
            ),
            createdAt=datetime(2025, 12, 30, 10, 0, 0),
            updatedAt=datetime(2025, 12, 30, 10, 0, 0),
            createdBy='user-123'
        )

    @pytest.fixture
    def sqs_event_single_record(self):
        """Create SQS event with single record."""
        return {
            'Records': [
                {
                    'messageId': 'msg-123',
                    'receiptHandle': 'receipt-123',
                    'body': json.dumps({
                        'tenantId': 'tenant-123',
                        'orderId': 'order-123'
                    }),
                    'attributes': {
                        'ApproximateReceiveCount': '1'
                    }
                }
            ]
        }

    @pytest.fixture
    def sqs_event_batch(self):
        """Create SQS event with batch of records."""
        return {
            'Records': [
                {
                    'messageId': 'msg-1',
                    'receiptHandle': 'receipt-1',
                    'body': json.dumps({
                        'tenantId': 'tenant-1',
                        'orderId': 'order-1'
                    })
                },
                {
                    'messageId': 'msg-2',
                    'receiptHandle': 'receipt-2',
                    'body': json.dumps({
                        'tenantId': 'tenant-2',
                        'orderId': 'order-2'
                    })
                }
            ]
        }

    @pytest.fixture
    def mock_context(self):
        """Create mock Lambda context."""
        context = Mock()
        context.function_name = 'OrderInternalNotificationSender'
        context.request_id = 'test-request-id'
        context.aws_request_id = 'test-aws-request-id'
        return context

    @patch('src.handlers.order_internal_notification_sender.OrderDAO')
    @patch('src.handlers.order_internal_notification_sender.EmailService')
    def test_lambda_handler_single_message_success(
        self, mock_email_service_class, mock_order_dao_class,
        sqs_event_single_record, mock_context, sample_order
    ):
        """Test successful processing of single SQS message."""
        # Arrange
        mock_order_dao = Mock()
        mock_email_service = Mock()
        mock_order_dao_class.return_value = mock_order_dao
        mock_email_service_class.return_value = mock_email_service

        mock_order_dao.get_order.return_value = sample_order
        mock_email_service.send_internal_notification.return_value = 'msg-ses-123'

        # Act
        response = lambda_handler(sqs_event_single_record, mock_context)

        # Assert
        assert response['statusCode'] == 200
        assert response['batchItemFailures'] == []

        # Verify DAO was called
        mock_order_dao.get_order.assert_called_once_with('tenant-123', 'order-123')

        # Verify email was sent
        mock_email_service.send_internal_notification.assert_called_once_with(sample_order)

    @patch('src.handlers.order_internal_notification_sender.OrderDAO')
    @patch('src.handlers.order_internal_notification_sender.EmailService')
    def test_lambda_handler_batch_messages_success(
        self, mock_email_service_class, mock_order_dao_class,
        sqs_event_batch, mock_context, sample_order
    ):
        """Test successful processing of batch SQS messages."""
        # Arrange
        mock_order_dao = Mock()
        mock_email_service = Mock()
        mock_order_dao_class.return_value = mock_order_dao
        mock_email_service_class.return_value = mock_email_service

        mock_order_dao.get_order.return_value = sample_order
        mock_email_service.send_internal_notification.return_value = 'msg-ses-123'

        # Act
        response = lambda_handler(sqs_event_batch, mock_context)

        # Assert
        assert response['statusCode'] == 200
        assert response['batchItemFailures'] == []
        assert mock_order_dao.get_order.call_count == 2
        assert mock_email_service.send_internal_notification.call_count == 2

    @patch('src.handlers.order_internal_notification_sender.OrderDAO')
    @patch('src.handlers.order_internal_notification_sender.EmailService')
    def test_lambda_handler_order_not_found(
        self, mock_email_service_class, mock_order_dao_class,
        sqs_event_single_record, mock_context
    ):
        """Test handling when order is not found in DynamoDB."""
        # Arrange
        mock_order_dao = Mock()
        mock_email_service = Mock()
        mock_order_dao_class.return_value = mock_order_dao
        mock_email_service_class.return_value = mock_email_service

        mock_order_dao.get_order.return_value = None

        # Act
        response = lambda_handler(sqs_event_single_record, mock_context)

        # Assert - Should still succeed (idempotent behavior)
        assert response['statusCode'] == 200
        assert response['batchItemFailures'] == []

        # Email should not be sent
        mock_email_service.send_internal_notification.assert_not_called()

    @patch('src.handlers.order_internal_notification_sender.OrderDAO')
    @patch('src.handlers.order_internal_notification_sender.EmailService')
    def test_lambda_handler_email_send_failure(
        self, mock_email_service_class, mock_order_dao_class,
        sqs_event_single_record, mock_context, sample_order
    ):
        """Test handling of email send failure (should retry via SQS)."""
        # Arrange
        mock_order_dao = Mock()
        mock_email_service = Mock()
        mock_order_dao_class.return_value = mock_order_dao
        mock_email_service_class.return_value = mock_email_service

        mock_order_dao.get_order.return_value = sample_order
        mock_email_service.send_internal_notification.side_effect = Exception("SES error")

        # Act
        response = lambda_handler(sqs_event_single_record, mock_context)

        # Assert - Should report failure for retry
        assert response['statusCode'] == 200
        assert len(response['batchItemFailures']) == 1
        assert response['batchItemFailures'][0]['itemIdentifier'] == 'msg-123'

    @patch('src.handlers.order_internal_notification_sender.OrderDAO')
    @patch('src.handlers.order_internal_notification_sender.EmailService')
    def test_lambda_handler_partial_batch_failure(
        self, mock_email_service_class, mock_order_dao_class,
        sqs_event_batch, mock_context, sample_order
    ):
        """Test partial batch failure handling."""
        # Arrange
        mock_order_dao = Mock()
        mock_email_service = Mock()
        mock_order_dao_class.return_value = mock_order_dao
        mock_email_service_class.return_value = mock_email_service

        mock_order_dao.get_order.return_value = sample_order

        # First call succeeds, second fails
        mock_email_service.send_internal_notification.side_effect = [
            'msg-ses-success',
            Exception("Email send failed")
        ]

        # Act
        response = lambda_handler(sqs_event_batch, mock_context)

        # Assert
        assert response['statusCode'] == 200
        assert len(response['batchItemFailures']) == 1
        assert response['batchItemFailures'][0]['itemIdentifier'] == 'msg-2'

    @patch('src.handlers.order_internal_notification_sender.OrderDAO')
    @patch('src.handlers.order_internal_notification_sender.EmailService')
    def test_lambda_handler_invalid_json_body(
        self, mock_email_service_class, mock_order_dao_class, mock_context
    ):
        """Test handling of invalid JSON in SQS message body."""
        # Arrange
        mock_order_dao = Mock()
        mock_email_service = Mock()
        mock_order_dao_class.return_value = mock_order_dao
        mock_email_service_class.return_value = mock_email_service

        event = {
            'Records': [
                {
                    'messageId': 'msg-invalid',
                    'receiptHandle': 'receipt-invalid',
                    'body': 'invalid json'
                }
            ]
        }

        # Act
        response = lambda_handler(event, mock_context)

        # Assert
        assert response['statusCode'] == 200
        assert len(response['batchItemFailures']) == 1
        assert response['batchItemFailures'][0]['itemIdentifier'] == 'msg-invalid'

    @patch('src.handlers.order_internal_notification_sender.OrderDAO')
    @patch('src.handlers.order_internal_notification_sender.EmailService')
    def test_lambda_handler_missing_required_fields(
        self, mock_email_service_class, mock_order_dao_class, mock_context
    ):
        """Test handling of missing required fields in message."""
        # Arrange
        mock_order_dao = Mock()
        mock_email_service = Mock()
        mock_order_dao_class.return_value = mock_order_dao
        mock_email_service_class.return_value = mock_email_service

        event = {
            'Records': [
                {
                    'messageId': 'msg-missing-fields',
                    'receiptHandle': 'receipt-missing',
                    'body': json.dumps({
                        'tenantId': 'tenant-123'
                        # Missing orderId
                    })
                }
            ]
        }

        # Act
        response = lambda_handler(event, mock_context)

        # Assert
        assert response['statusCode'] == 200
        assert len(response['batchItemFailures']) == 1

    @patch('src.handlers.order_internal_notification_sender.OrderDAO')
    @patch('src.handlers.order_internal_notification_sender.EmailService')
    def test_lambda_handler_dao_exception(
        self, mock_email_service_class, mock_order_dao_class,
        sqs_event_single_record, mock_context
    ):
        """Test handling of DAO exception."""
        # Arrange
        mock_order_dao = Mock()
        mock_email_service = Mock()
        mock_order_dao_class.return_value = mock_order_dao
        mock_email_service_class.return_value = mock_email_service

        mock_order_dao.get_order.side_effect = Exception("DynamoDB error")

        # Act
        response = lambda_handler(sqs_event_single_record, mock_context)

        # Assert
        assert response['statusCode'] == 200
        assert len(response['batchItemFailures']) == 1
        assert response['batchItemFailures'][0]['itemIdentifier'] == 'msg-123'
