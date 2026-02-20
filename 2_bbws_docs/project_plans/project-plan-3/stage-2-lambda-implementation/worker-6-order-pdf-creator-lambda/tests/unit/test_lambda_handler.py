"""
Unit tests for OrderPDFCreator Lambda handler.

Tests Lambda function logic with mocked dependencies.
"""

import pytest
import json
from unittest.mock import patch, MagicMock
from src.handlers.order_pdf_creator import lambda_handler, process_order_pdf


class TestLambdaHandler:
    """Tests for Lambda handler function."""

    @patch('src.handlers.order_pdf_creator.order_dao')
    @patch('src.handlers.order_pdf_creator.pdf_service')
    @patch('src.handlers.order_pdf_creator.s3_service')
    def test_lambda_handler_success_single_message(
        self, mock_s3_service, mock_pdf_service, mock_order_dao,
        sqs_event_single_message, lambda_context, sample_order
    ):
        """Test successful processing of single SQS message."""
        # Mock DAO response
        mock_order_dao.get_order.return_value = sample_order

        # Mock PDF service
        mock_pdf_service.generate_invoice_pdf.return_value = b"PDF content"

        # Mock S3 service
        mock_s3_service.check_pdf_exists.return_value = False
        mock_s3_service.upload_pdf.return_value = "https://s3.amazonaws.com/bucket/order.pdf"

        # Invoke Lambda
        response = lambda_handler(sqs_event_single_message, lambda_context)

        # Verify no failures
        assert response['batchItemFailures'] == []

        # Verify services were called
        mock_order_dao.get_order.assert_called_once_with("tenant-123", "550e8400-e29b-41d4-a716-446655440000")
        mock_pdf_service.generate_invoice_pdf.assert_called_once()
        mock_s3_service.upload_pdf.assert_called_once()
        mock_order_dao.update_order.assert_called_once()

    @patch('src.handlers.order_pdf_creator.order_dao')
    @patch('src.handlers.order_pdf_creator.pdf_service')
    @patch('src.handlers.order_pdf_creator.s3_service')
    def test_lambda_handler_batch_messages(
        self, mock_s3_service, mock_pdf_service, mock_order_dao,
        sqs_event_batch_messages, lambda_context, sample_order
    ):
        """Test processing batch of SQS messages."""
        # Mock DAO responses
        mock_order_dao.get_order.return_value = sample_order

        # Mock services
        mock_pdf_service.generate_invoice_pdf.return_value = b"PDF content"
        mock_s3_service.check_pdf_exists.return_value = False
        mock_s3_service.upload_pdf.return_value = "https://s3.amazonaws.com/bucket/order.pdf"

        # Invoke Lambda
        response = lambda_handler(sqs_event_batch_messages, lambda_context)

        # Verify no failures
        assert response['batchItemFailures'] == []

        # Verify services were called twice (2 messages)
        assert mock_order_dao.get_order.call_count == 2
        assert mock_pdf_service.generate_invoice_pdf.call_count == 2

    @patch('src.handlers.order_pdf_creator.order_dao')
    def test_lambda_handler_missing_order_id(self, mock_order_dao, lambda_context):
        """Test handling of message with missing orderId."""
        event = {
            "Records": [{
                "messageId": "msg-123",
                "body": '{"tenantId": "tenant-123"}'  # Missing orderId
            }]
        }

        response = lambda_handler(event, lambda_context)

        # Should return failed message
        assert len(response['batchItemFailures']) == 1
        assert response['batchItemFailures'][0]['itemIdentifier'] == 'msg-123'

    @patch('src.handlers.order_pdf_creator.order_dao')
    def test_lambda_handler_order_not_found(self, mock_order_dao, sqs_event_single_message, lambda_context):
        """Test handling when order not found in DynamoDB."""
        # Mock order not found
        mock_order_dao.get_order.return_value = None

        response = lambda_handler(sqs_event_single_message, lambda_context)

        # Should return failed message for retry
        assert len(response['batchItemFailures']) == 1

    @patch('src.handlers.order_pdf_creator.order_dao')
    @patch('src.handlers.order_pdf_creator.pdf_service')
    @patch('src.handlers.order_pdf_creator.s3_service')
    def test_lambda_handler_pdf_already_exists(
        self, mock_s3_service, mock_pdf_service, mock_order_dao,
        sqs_event_single_message, lambda_context, sample_order
    ):
        """Test idempotency - skip if PDF already exists."""
        # Set PDF URL on order
        sample_order.pdfUrl = "https://s3.amazonaws.com/bucket/order.pdf"
        mock_order_dao.get_order.return_value = sample_order

        # Mock S3 check - PDF exists
        mock_s3_service.check_pdf_exists.return_value = True

        response = lambda_handler(sqs_event_single_message, lambda_context)

        # Should succeed without regenerating PDF
        assert response['batchItemFailures'] == []

        # Verify PDF was not regenerated
        mock_pdf_service.generate_invoice_pdf.assert_not_called()
        mock_s3_service.upload_pdf.assert_not_called()

    @patch('src.handlers.order_pdf_creator.order_dao')
    @patch('src.handlers.order_pdf_creator.pdf_service')
    def test_lambda_handler_pdf_generation_error(
        self, mock_pdf_service, mock_order_dao,
        sqs_event_single_message, lambda_context, sample_order
    ):
        """Test handling of PDF generation error."""
        mock_order_dao.get_order.return_value = sample_order
        mock_pdf_service.generate_invoice_pdf.side_effect = Exception("PDF generation failed")

        response = lambda_handler(sqs_event_single_message, lambda_context)

        # Should return failed message for retry
        assert len(response['batchItemFailures']) == 1
        assert response['batchItemFailures'][0]['itemIdentifier'] == 'msg-123'

    @patch('src.handlers.order_pdf_creator.order_dao')
    @patch('src.handlers.order_pdf_creator.pdf_service')
    @patch('src.handlers.order_pdf_creator.s3_service')
    def test_lambda_handler_s3_upload_error(
        self, mock_s3_service, mock_pdf_service, mock_order_dao,
        sqs_event_single_message, lambda_context, sample_order
    ):
        """Test handling of S3 upload error."""
        mock_order_dao.get_order.return_value = sample_order
        mock_pdf_service.generate_invoice_pdf.return_value = b"PDF content"
        mock_s3_service.check_pdf_exists.return_value = False
        mock_s3_service.upload_pdf.side_effect = Exception("S3 upload failed")

        response = lambda_handler(sqs_event_single_message, lambda_context)

        # Should return failed message for retry
        assert len(response['batchItemFailures']) == 1

    @patch('src.handlers.order_pdf_creator.order_dao')
    @patch('src.handlers.order_pdf_creator.pdf_service')
    @patch('src.handlers.order_pdf_creator.s3_service')
    def test_lambda_handler_partial_batch_failure(
        self, mock_s3_service, mock_pdf_service, mock_order_dao,
        lambda_context, sample_order
    ):
        """Test partial batch failure handling."""
        event = {
            "Records": [
                {
                    "messageId": "msg-success",
                    "body": '{"orderId": "order-1", "tenantId": "tenant-1"}'
                },
                {
                    "messageId": "msg-fail",
                    "body": '{"orderId": "order-2", "tenantId": "tenant-2"}'
                }
            ]
        }

        # First order succeeds, second fails
        mock_order_dao.get_order.side_effect = [sample_order, None]
        mock_pdf_service.generate_invoice_pdf.return_value = b"PDF content"
        mock_s3_service.check_pdf_exists.return_value = False
        mock_s3_service.upload_pdf.return_value = "https://s3.amazonaws.com/bucket/order.pdf"

        response = lambda_handler(event, lambda_context)

        # Only second message should fail
        assert len(response['batchItemFailures']) == 1
        assert response['batchItemFailures'][0]['itemIdentifier'] == 'msg-fail'


class TestProcessOrderPDF:
    """Tests for process_order_pdf helper function."""

    @patch('src.handlers.order_pdf_creator.order_dao')
    @patch('src.handlers.order_pdf_creator.pdf_service')
    @patch('src.handlers.order_pdf_creator.s3_service')
    def test_process_order_pdf_success(
        self, mock_s3_service, mock_pdf_service, mock_order_dao, sample_order
    ):
        """Test successful order PDF processing."""
        mock_order_dao.get_order.return_value = sample_order
        mock_pdf_service.generate_invoice_pdf.return_value = b"PDF content"
        mock_s3_service.check_pdf_exists.return_value = False
        mock_s3_service.upload_pdf.return_value = "https://s3.amazonaws.com/bucket/order.pdf"

        process_order_pdf("tenant-123", "order-123")

        # Verify all steps executed
        mock_order_dao.get_order.assert_called_once_with("tenant-123", "order-123")
        mock_s3_service.check_pdf_exists.assert_called_once()
        mock_pdf_service.generate_invoice_pdf.assert_called_once_with(sample_order)
        mock_s3_service.upload_pdf.assert_called_once_with(b"PDF content", "tenant-123", "order-123")
        mock_order_dao.update_order.assert_called_once()

    @patch('src.handlers.order_pdf_creator.order_dao')
    def test_process_order_pdf_order_not_found(self, mock_order_dao):
        """Test processing when order not found."""
        mock_order_dao.get_order.return_value = None

        with pytest.raises(ValueError) as exc_info:
            process_order_pdf("tenant-123", "order-123")

        assert "Order not found" in str(exc_info.value)

    @patch('src.handlers.order_pdf_creator.order_dao')
    @patch('src.handlers.order_pdf_creator.s3_service')
    def test_process_order_pdf_already_exists(
        self, mock_s3_service, mock_order_dao, sample_order
    ):
        """Test skipping when PDF already exists."""
        sample_order.pdfUrl = "https://s3.amazonaws.com/bucket/order.pdf"
        mock_order_dao.get_order.return_value = sample_order
        mock_s3_service.check_pdf_exists.return_value = True

        process_order_pdf("tenant-123", "order-123")

        # Should skip PDF generation
        mock_s3_service.upload_pdf.assert_not_called()
        mock_order_dao.update_order.assert_not_called()

    @patch('src.handlers.order_pdf_creator.order_dao')
    @patch('src.handlers.order_pdf_creator.pdf_service')
    @patch('src.handlers.order_pdf_creator.s3_service')
    def test_process_order_pdf_regenerate_missing(
        self, mock_s3_service, mock_pdf_service, mock_order_dao, sample_order
    ):
        """Test regenerating PDF when URL exists but file is missing."""
        sample_order.pdfUrl = "https://s3.amazonaws.com/bucket/order.pdf"
        mock_order_dao.get_order.return_value = sample_order
        mock_s3_service.check_pdf_exists.return_value = False  # File missing
        mock_pdf_service.generate_invoice_pdf.return_value = b"PDF content"
        mock_s3_service.upload_pdf.return_value = "https://s3.amazonaws.com/bucket/order.pdf"

        process_order_pdf("tenant-123", "order-123")

        # Should regenerate PDF
        mock_pdf_service.generate_invoice_pdf.assert_called_once()
        mock_s3_service.upload_pdf.assert_called_once()
        mock_order_dao.update_order.assert_called_once()
