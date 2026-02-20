"""Unit tests for SESService."""

import pytest
from unittest.mock import Mock, patch
from botocore.exceptions import ClientError

from src.services.ses_service import SESService


class TestSESService:
    """Test cases for SESService."""

    @pytest.fixture
    def mock_ses_client(self):
        """Create mock SES client."""
        return Mock()

    @pytest.fixture
    def ses_service(self, mock_ses_client):
        """Create SESService instance with mocked SES client."""
        with patch.dict('os.environ', {
            'SES_FROM_EMAIL': 'test@kimmyai.io',
            'INTERNAL_NOTIFICATION_EMAIL': 'internal@kimmyai.io'
        }):
            service = SESService()
            service.ses_client = mock_ses_client
            return service

    def test_send_email_html_only_success(self, ses_service, mock_ses_client):
        """Test successful email sending with HTML body only."""
        # Arrange
        mock_ses_client.send_email.return_value = {
            'MessageId': 'msg-123'
        }

        # Act
        message_id = ses_service.send_email(
            to_email='recipient@example.com',
            subject='Test Subject',
            html_body='<h1>Test Email</h1>'
        )

        # Assert
        assert message_id == 'msg-123'
        mock_ses_client.send_email.assert_called_once()

        call_args = mock_ses_client.send_email.call_args[1]
        assert call_args['Source'] == 'test@kimmyai.io'
        assert call_args['Destination']['ToAddresses'] == ['recipient@example.com']
        assert call_args['Message']['Subject']['Data'] == 'Test Subject'
        assert call_args['Message']['Body']['Html']['Data'] == '<h1>Test Email</h1>'

    def test_send_email_text_only_success(self, ses_service, mock_ses_client):
        """Test successful email sending with text body only."""
        # Arrange
        mock_ses_client.send_email.return_value = {
            'MessageId': 'msg-456'
        }

        # Act
        message_id = ses_service.send_email(
            to_email='recipient@example.com',
            subject='Test Subject',
            text_body='Plain text email'
        )

        # Assert
        assert message_id == 'msg-456'
        call_args = mock_ses_client.send_email.call_args[1]
        assert call_args['Message']['Body']['Text']['Data'] == 'Plain text email'

    def test_send_email_both_html_and_text(self, ses_service, mock_ses_client):
        """Test email sending with both HTML and text bodies."""
        # Arrange
        mock_ses_client.send_email.return_value = {
            'MessageId': 'msg-789'
        }

        # Act
        message_id = ses_service.send_email(
            to_email='recipient@example.com',
            subject='Test Subject',
            html_body='<h1>HTML Version</h1>',
            text_body='Text Version'
        )

        # Assert
        assert message_id == 'msg-789'
        call_args = mock_ses_client.send_email.call_args[1]
        assert 'Html' in call_args['Message']['Body']
        assert 'Text' in call_args['Message']['Body']

    def test_send_email_no_body_raises_error(self, ses_service):
        """Test that sending email without body raises ValueError."""
        # Act & Assert
        with pytest.raises(ValueError) as exc_info:
            ses_service.send_email(
                to_email='recipient@example.com',
                subject='Test Subject'
            )

        assert 'Either html_body or text_body must be provided' in str(exc_info.value)

    def test_send_email_ses_client_error(self, ses_service, mock_ses_client):
        """Test handling of SES client error."""
        # Arrange
        error_response = {'Error': {'Code': 'MessageRejected', 'Message': 'Email rejected'}}
        mock_ses_client.send_email.side_effect = ClientError(error_response, 'SendEmail')

        # Act & Assert
        with pytest.raises(Exception) as exc_info:
            ses_service.send_email(
                to_email='invalid@example.com',
                subject='Test',
                text_body='Test'
            )

        assert 'Failed to send email' in str(exc_info.value)

    def test_send_email_with_utf8_characters(self, ses_service, mock_ses_client):
        """Test email sending with UTF-8 characters."""
        # Arrange
        mock_ses_client.send_email.return_value = {'MessageId': 'msg-utf8'}

        # Act
        message_id = ses_service.send_email(
            to_email='recipient@example.com',
            subject='Pedido № 123',
            html_body='<p>Cliente: José García</p>'
        )

        # Assert
        assert message_id == 'msg-utf8'
        call_args = mock_ses_client.send_email.call_args[1]
        assert call_args['Message']['Subject']['Charset'] == 'UTF-8'
        assert call_args['Message']['Body']['Html']['Charset'] == 'UTF-8'

    def test_send_email_to_default_internal_email(self, ses_service, mock_ses_client):
        """Test sending to default internal notification email."""
        # Arrange
        mock_ses_client.send_email.return_value = {'MessageId': 'msg-internal'}

        # Act
        message_id = ses_service.send_email(
            to_email=None,  # Should use default
            subject='Internal Notification',
            text_body='Notification message'
        )

        # Assert
        call_args = mock_ses_client.send_email.call_args[1]
        assert call_args['Destination']['ToAddresses'] == ['internal@kimmyai.io']

    def test_send_email_empty_to_email_uses_default(self, ses_service, mock_ses_client):
        """Test that empty to_email uses default internal email."""
        # Arrange
        mock_ses_client.send_email.return_value = {'MessageId': 'msg-default'}

        # Act
        message_id = ses_service.send_email(
            to_email='',
            subject='Test',
            text_body='Test message'
        )

        # Assert
        call_args = mock_ses_client.send_email.call_args[1]
        assert call_args['Destination']['ToAddresses'] == ['internal@kimmyai.io']
