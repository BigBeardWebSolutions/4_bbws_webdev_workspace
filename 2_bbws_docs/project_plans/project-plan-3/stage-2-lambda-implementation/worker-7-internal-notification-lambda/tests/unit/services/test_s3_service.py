"""Unit tests for S3Service."""

import pytest
from unittest.mock import Mock, patch
from botocore.exceptions import ClientError

from src.services.s3_service import S3Service


class TestS3Service:
    """Test cases for S3Service."""

    @pytest.fixture
    def mock_s3_client(self):
        """Create mock S3 client."""
        return Mock()

    @pytest.fixture
    def s3_service(self, mock_s3_client):
        """Create S3Service instance with mocked S3 client."""
        with patch.dict('os.environ', {'EMAIL_TEMPLATE_BUCKET': 'test-templates-bucket'}):
            service = S3Service()
            service.s3_client = mock_s3_client
            return service

    def test_get_template_success(self, s3_service, mock_s3_client):
        """Test successful template retrieval from S3."""
        # Arrange
        template_html = """
        <html>
            <body>
                <h1>Order Notification</h1>
                <p>Order: {{orderNumber}}</p>
            </body>
        </html>
        """
        mock_s3_client.get_object.return_value = {
            'Body': Mock(read=Mock(return_value=template_html.encode('utf-8')))
        }

        # Act
        result = s3_service.get_template('internal/order_notification.html')

        # Assert
        assert result == template_html
        mock_s3_client.get_object.assert_called_once_with(
            Bucket='test-templates-bucket',
            Key='internal/order_notification.html'
        )

    def test_get_template_not_found(self, s3_service, mock_s3_client):
        """Test template not found in S3."""
        # Arrange
        error_response = {'Error': {'Code': 'NoSuchKey', 'Message': 'Key not found'}}
        mock_s3_client.get_object.side_effect = ClientError(error_response, 'GetObject')

        # Act
        result = s3_service.get_template('nonexistent/template.html')

        # Assert
        assert result is None

    def test_get_template_access_denied(self, s3_service, mock_s3_client):
        """Test S3 access denied error."""
        # Arrange
        error_response = {'Error': {'Code': 'AccessDenied', 'Message': 'Access denied'}}
        mock_s3_client.get_object.side_effect = ClientError(error_response, 'GetObject')

        # Act
        result = s3_service.get_template('internal/template.html')

        # Assert
        assert result is None

    def test_get_template_other_client_error(self, s3_service, mock_s3_client):
        """Test other S3 client errors."""
        # Arrange
        error_response = {'Error': {'Code': 'InternalError', 'Message': 'Internal error'}}
        mock_s3_client.get_object.side_effect = ClientError(error_response, 'GetObject')

        # Act & Assert
        with pytest.raises(Exception) as exc_info:
            s3_service.get_template('internal/template.html')

        assert 'Failed to retrieve template' in str(exc_info.value)

    def test_get_template_decoding_error(self, s3_service, mock_s3_client):
        """Test template decoding error."""
        # Arrange
        mock_s3_client.get_object.return_value = {
            'Body': Mock(read=Mock(return_value=b'\xff\xfe'))  # Invalid UTF-8
        }

        # Act & Assert
        with pytest.raises(Exception):
            s3_service.get_template('internal/template.html')

    def test_get_template_empty_content(self, s3_service, mock_s3_client):
        """Test empty template content."""
        # Arrange
        mock_s3_client.get_object.return_value = {
            'Body': Mock(read=Mock(return_value=b''))
        }

        # Act
        result = s3_service.get_template('internal/empty.html')

        # Assert
        assert result == ''

    def test_get_template_with_special_characters(self, s3_service, mock_s3_client):
        """Test template with special UTF-8 characters."""
        # Arrange
        template_html = "<h1>Order № 123 – Customer: José García</h1>"
        mock_s3_client.get_object.return_value = {
            'Body': Mock(read=Mock(return_value=template_html.encode('utf-8')))
        }

        # Act
        result = s3_service.get_template('internal/template.html')

        # Assert
        assert result == template_html
        assert 'José García' in result
