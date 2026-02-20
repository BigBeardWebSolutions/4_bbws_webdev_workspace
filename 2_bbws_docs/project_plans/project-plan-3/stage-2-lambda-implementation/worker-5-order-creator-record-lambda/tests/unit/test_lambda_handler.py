"""
Unit tests for OrderCreatorRecord Lambda handler.
"""

import pytest
import json
from unittest.mock import Mock, patch, MagicMock
from pydantic import ValidationError

from src.handlers.order_creator_record import lambda_handler, process_order_message
from src.models.order import Order


class TestLambdaHandler:
    """Test Lambda handler."""

    @patch('src.handlers.order_creator_record.order_dao')
    @patch('src.handlers.order_creator_record.cart_service')
    def test_lambda_handler_success(self, mock_cart_service, mock_order_dao, sample_sqs_event, sample_cart_data):
        """Test successful Lambda execution."""
        # Mock cart service
        mock_cart_service.get_cart.return_value = sample_cart_data
        mock_cart_service.validate_cart.return_value = True

        # Mock order DAO
        mock_order_dao.get_next_order_number.return_value = "ORD-20251230-00001"
        mock_order_dao.create_order.return_value = MagicMock()

        # Execute handler
        result = lambda_handler(sample_sqs_event, None)

        # Verify no failures
        assert result['batchItemFailures'] == []

        # Verify cart was fetched
        mock_cart_service.get_cart.assert_called_once()

        # Verify order number was generated
        mock_order_dao.get_next_order_number.assert_called_once()

        # Verify order was created
        mock_order_dao.create_order.assert_called_once()

    @patch('src.handlers.order_creator_record.order_dao')
    @patch('src.handlers.order_creator_record.cart_service')
    def test_lambda_handler_validation_error(self, mock_cart_service, mock_order_dao, sample_sqs_event):
        """Test Lambda handler with validation error."""
        # Mock cart service to raise validation error
        mock_cart_service.get_cart.side_effect = ValidationError([], Order)

        # Execute handler
        result = lambda_handler(sample_sqs_event, None)

        # Verify message added to failures
        assert len(result['batchItemFailures']) == 1
        assert result['batchItemFailures'][0]['itemIdentifier'] == 'msg-123'

    @patch('src.handlers.order_creator_record.order_dao')
    @patch('src.handlers.order_creator_record.cart_service')
    def test_lambda_handler_duplicate_order(self, mock_cart_service, mock_order_dao, sample_sqs_event, sample_cart_data):
        """Test Lambda handler with duplicate order."""
        # Mock cart service
        mock_cart_service.get_cart.return_value = sample_cart_data
        mock_cart_service.validate_cart.return_value = True

        # Mock order DAO
        mock_order_dao.get_next_order_number.return_value = "ORD-20251230-00001"
        mock_order_dao.create_order.side_effect = ValueError("Order already exists")

        # Execute handler
        result = lambda_handler(sample_sqs_event, None)

        # Verify message NOT added to failures (idempotent)
        assert len(result['batchItemFailures']) == 0

    @patch('src.handlers.order_creator_record.order_dao')
    @patch('src.handlers.order_creator_record.cart_service')
    def test_lambda_handler_unexpected_error(self, mock_cart_service, mock_order_dao, sample_sqs_event, sample_cart_data):
        """Test Lambda handler with unexpected error."""
        # Mock cart service
        mock_cart_service.get_cart.return_value = sample_cart_data
        mock_cart_service.validate_cart.return_value = True

        # Mock order DAO to raise unexpected error
        mock_order_dao.get_next_order_number.return_value = "ORD-20251230-00001"
        mock_order_dao.create_order.side_effect = Exception("Unexpected error")

        # Execute handler
        result = lambda_handler(sample_sqs_event, None)

        # Verify message added to failures
        assert len(result['batchItemFailures']) == 1
        assert result['batchItemFailures'][0]['itemIdentifier'] == 'msg-123'

    @patch('src.handlers.order_creator_record.order_dao')
    @patch('src.handlers.order_creator_record.cart_service')
    def test_lambda_handler_batch_processing(self, mock_cart_service, mock_order_dao, sample_sqs_message, sample_cart_data):
        """Test Lambda handler with multiple messages."""
        # Create event with 3 messages
        event = {
            'Records': [
                {
                    'messageId': f'msg-{i}',
                    'receiptHandle': f'receipt-{i}',
                    'body': json.dumps(sample_sqs_message)
                }
                for i in range(3)
            ]
        }

        # Mock cart service
        mock_cart_service.get_cart.return_value = sample_cart_data
        mock_cart_service.validate_cart.return_value = True

        # Mock order DAO
        mock_order_dao.get_next_order_number.return_value = "ORD-20251230-00001"
        mock_order_dao.create_order.return_value = MagicMock()

        # Execute handler
        result = lambda_handler(event, None)

        # Verify all messages processed successfully
        assert len(result['batchItemFailures']) == 0

        # Verify cart was fetched 3 times
        assert mock_cart_service.get_cart.call_count == 3

        # Verify order number was generated 3 times
        assert mock_order_dao.get_next_order_number.call_count == 3

        # Verify 3 orders were created
        assert mock_order_dao.create_order.call_count == 3

    @patch('src.handlers.order_creator_record.order_dao')
    @patch('src.handlers.order_creator_record.cart_service')
    def test_lambda_handler_partial_batch_failure(self, mock_cart_service, mock_order_dao, sample_sqs_message, sample_cart_data):
        """Test Lambda handler with partial batch failure."""
        # Create event with 3 messages
        event = {
            'Records': [
                {
                    'messageId': f'msg-{i}',
                    'receiptHandle': f'receipt-{i}',
                    'body': json.dumps(sample_sqs_message)
                }
                for i in range(3)
            ]
        }

        # Mock cart service
        mock_cart_service.get_cart.return_value = sample_cart_data
        mock_cart_service.validate_cart.return_value = True

        # Mock order DAO - fail on second message
        mock_order_dao.get_next_order_number.return_value = "ORD-20251230-00001"
        mock_order_dao.create_order.side_effect = [
            MagicMock(),  # Success
            Exception("DynamoDB error"),  # Failure
            MagicMock()   # Success
        ]

        # Execute handler
        result = lambda_handler(event, None)

        # Verify only one message failed
        assert len(result['batchItemFailures']) == 1
        assert result['batchItemFailures'][0]['itemIdentifier'] == 'msg-1'


class TestProcessOrderMessage:
    """Test process_order_message function."""

    @patch('src.handlers.order_creator_record.order_dao')
    @patch('src.handlers.order_creator_record.cart_service')
    def test_process_order_message_success(self, mock_cart_service, mock_order_dao, sample_sqs_message, sample_cart_data):
        """Test successful order message processing."""
        # Mock cart service
        mock_cart_service.get_cart.return_value = sample_cart_data
        mock_cart_service.validate_cart.return_value = True

        # Mock order DAO
        mock_order_dao.get_next_order_number.return_value = "ORD-20251230-00001"

        # Process message
        order = process_order_message(sample_sqs_message)

        # Verify order object
        assert isinstance(order, Order)
        assert order.id == sample_sqs_message['orderId']
        assert order.tenantId == sample_sqs_message['tenantId']
        assert order.customerEmail == sample_sqs_message['customerEmail']
        assert order.orderNumber == "ORD-20251230-00001"
        assert order.status == "PENDING_PAYMENT"
        assert len(order.items) == 1
        assert order.total == sample_cart_data['total']

    @patch('src.handlers.order_creator_record.cart_service')
    def test_process_order_message_missing_fields(self, mock_cart_service):
        """Test processing message with missing fields."""
        invalid_message = {
            'orderId': 'order-123'
            # Missing other required fields
        }

        with pytest.raises(ValueError) as exc_info:
            process_order_message(invalid_message)

        assert "Missing required fields" in str(exc_info.value)

    @patch('src.handlers.order_creator_record.order_dao')
    @patch('src.handlers.order_creator_record.cart_service')
    def test_process_order_message_invalid_cart(self, mock_cart_service, mock_order_dao, sample_sqs_message, sample_cart_data):
        """Test processing message with invalid cart."""
        # Mock cart service with invalid cart
        mock_cart_service.get_cart.return_value = sample_cart_data
        mock_cart_service.validate_cart.return_value = False

        with pytest.raises(ValueError) as exc_info:
            process_order_message(sample_sqs_message)

        assert "Invalid cart data" in str(exc_info.value)

    @patch('src.handlers.order_creator_record.order_dao')
    @patch('src.handlers.order_creator_record.cart_service')
    def test_process_order_message_with_campaign(self, mock_cart_service, mock_order_dao, sample_sqs_message, sample_cart_data, sample_campaign):
        """Test processing message with campaign."""
        # Add campaign to message
        sample_sqs_message['campaignCode'] = 'SUMMER2025'
        sample_sqs_message['campaign'] = sample_campaign

        # Mock cart service
        mock_cart_service.get_cart.return_value = sample_cart_data
        mock_cart_service.validate_cart.return_value = True

        # Mock order DAO
        mock_order_dao.get_next_order_number.return_value = "ORD-20251230-00001"

        # Process message
        order = process_order_message(sample_sqs_message)

        # Verify campaign is included
        assert order.campaign is not None
        assert order.campaign.code == 'SUMMER2025'
