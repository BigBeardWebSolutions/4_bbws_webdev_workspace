"""
Unit tests for S3Service.

Tests S3 operations with mocked boto3 client.
"""

import pytest
from src.services.s3_service import S3Service


class TestS3Service:
    """Tests for S3Service class."""

    def test_init(self, mock_s3_client):
        """Test S3Service initialization."""
        service = S3Service(mock_s3_client, "test-bucket")
        assert service.s3_client == mock_s3_client
        assert service.bucket_name == "test-bucket"

    def test_upload_pdf_success(self, mock_s3_client):
        """Test successful PDF upload."""
        service = S3Service(mock_s3_client, "bbws-orders-dev")

        pdf_data = b"PDF content here"
        tenant_id = "tenant-123"
        order_id = "550e8400-e29b-41d4-a716-446655440000"

        result = service.upload_pdf(pdf_data, tenant_id, order_id)

        # Verify S3 put_object was called correctly
        mock_s3_client.put_object.assert_called_once()
        call_args = mock_s3_client.put_object.call_args[1]

        assert call_args['Bucket'] == 'bbws-orders-dev'
        assert call_args['Key'] == f'{tenant_id}/orders/order_{order_id}.pdf'
        assert call_args['Body'] == pdf_data
        assert call_args['ContentType'] == 'application/pdf'
        assert call_args['ServerSideEncryption'] == 'AES256'
        assert call_args['Metadata']['tenant-id'] == tenant_id
        assert call_args['Metadata']['order-id'] == order_id

        # Verify returned URL
        expected_url = f"https://bbws-orders-dev.s3.amazonaws.com/{tenant_id}/orders/order_{order_id}.pdf"
        assert result == expected_url

    def test_upload_pdf_s3_error(self, mock_s3_client):
        """Test S3 upload error is raised."""
        mock_s3_client.put_object.side_effect = Exception("S3 error")

        service = S3Service(mock_s3_client, "test-bucket")

        with pytest.raises(Exception) as exc_info:
            service.upload_pdf(b"data", "tenant-123", "order-123")

        assert "S3 error" in str(exc_info.value)

    def test_get_pdf_url(self, mock_s3_client):
        """Test getting PDF URL without upload."""
        service = S3Service(mock_s3_client, "bbws-orders-dev")

        url = service.get_pdf_url("tenant-123", "order-456")

        expected_url = "https://bbws-orders-dev.s3.amazonaws.com/tenant-123/orders/order_order-456.pdf"
        assert url == expected_url

    def test_check_pdf_exists_true(self, mock_s3_client):
        """Test checking PDF exists returns True."""
        # Mock successful head_object response
        mock_s3_client.head_object.return_value = {'ContentLength': 1024}

        service = S3Service(mock_s3_client, "test-bucket")

        exists = service.check_pdf_exists("tenant-123", "order-123")

        assert exists is True
        mock_s3_client.head_object.assert_called_once_with(
            Bucket='test-bucket',
            Key='tenant-123/orders/order_order-123.pdf'
        )

    def test_check_pdf_exists_false(self, mock_s3_client):
        """Test checking PDF exists returns False when not found."""
        # Mock NoSuchKey exception
        from botocore.exceptions import ClientError
        mock_s3_client.exceptions.NoSuchKey = ClientError
        mock_s3_client.head_object.side_effect = ClientError(
            {'Error': {'Code': 'NoSuchKey'}}, 'HeadObject'
        )

        service = S3Service(mock_s3_client, "test-bucket")

        exists = service.check_pdf_exists("tenant-123", "order-123")

        assert exists is False

    def test_check_pdf_exists_error(self, mock_s3_client):
        """Test checking PDF exists returns False on other errors."""
        mock_s3_client.head_object.side_effect = Exception("S3 error")

        service = S3Service(mock_s3_client, "test-bucket")

        exists = service.check_pdf_exists("tenant-123", "order-123")

        assert exists is False
