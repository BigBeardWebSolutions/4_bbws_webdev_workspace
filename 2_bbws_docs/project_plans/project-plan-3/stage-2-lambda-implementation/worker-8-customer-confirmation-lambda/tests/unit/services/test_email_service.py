"""Unit tests for EmailService."""

import pytest
from unittest.mock import Mock, MagicMock, patch
from datetime import datetime

from src.services.email_service import EmailService
from src.models import Order, OrderItem, Campaign, BillingAddress


class TestEmailService:
    """Test cases for EmailService."""

    @pytest.fixture
    def mock_s3_service(self):
        """Create mock S3Service."""
        return Mock()

    @pytest.fixture
    def mock_ses_service(self):
        """Create mock SESService."""
        return Mock()

    @pytest.fixture
    def email_service(self, mock_s3_service, mock_ses_service):
        """Create EmailService instance with mocked dependencies."""
        service = EmailService()
        service.s3_service = mock_s3_service
        service.ses_service = mock_ses_service
        return service

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

    def test_render_template_success(self, email_service, sample_order):
        """Test successful template rendering with Jinja2."""
        # Arrange
        template_html = """
        <html>
            <body>
                <h1>New Order: {{ orderNumber }}</h1>
                <p>Customer: {{ customerEmail }}</p>
                <p>Total: R{{ total }}</p>
                <p>Items: {{ itemCount }}</p>
            </body>
        </html>
        """

        # Act
        result = email_service.render_template(template_html, sample_order)

        # Assert
        assert 'ORD-2025-001' in result
        assert 'customer@example.com' in result
        assert 'R574.99' in result
        assert '1' in result  # itemCount

    def test_render_template_with_order_details_url(self, email_service, sample_order):
        """Test template rendering with orderDetailsUrl."""
        # Arrange
        template_html = "<a href='{{ orderDetailsUrl }}'>View Order</a>"

        # Act
        result = email_service.render_template(template_html, sample_order)

        # Assert
        assert 'tenant-123' in result
        assert 'order-123' in result
        assert 'href=' in result

    def test_render_template_with_order_date_formatting(self, email_service, sample_order):
        """Test template rendering with date formatting."""
        # Arrange
        template_html = "<p>Order Date: {{ orderDate }}</p>"

        # Act
        result = email_service.render_template(template_html, sample_order)

        # Assert
        assert '2025-12-30' in result

    def test_render_template_invalid_syntax(self, email_service, sample_order):
        """Test template rendering with invalid Jinja2 syntax."""
        # Arrange
        template_html = "{{ unclosed"

        # Act & Assert
        with pytest.raises(Exception) as exc_info:
            email_service.render_template(template_html, sample_order)

        assert 'Failed to render template' in str(exc_info.value)

    def test_render_template_missing_variable(self, email_service, sample_order):
        """Test template rendering with missing variable (should not error in Jinja2)."""
        # Arrange
        template_html = "<p>{{ nonExistentVariable }}</p>"

        # Act
        result = email_service.render_template(template_html, sample_order)

        # Assert - Jinja2 renders missing variables as empty string
        assert result == "<p></p>"

    def test_send_internal_notification_with_template(
        self, email_service, mock_s3_service, mock_ses_service, sample_order
    ):
        """Test sending internal notification with HTML template."""
        # Arrange
        template_html = "<h1>Order {{ orderNumber }}</h1>"
        mock_s3_service.get_template.return_value = template_html

        # Act
        email_service.send_internal_notification(sample_order)

        # Assert
        mock_s3_service.get_template.assert_called_once_with('internal/order_notification.html')
        mock_ses_service.send_email.assert_called_once()

        call_args = mock_ses_service.send_email.call_args
        assert 'ORD-2025-001' in call_args[1]['subject']
        assert 'ORD-2025-001' in call_args[1]['html_body']

    def test_send_internal_notification_template_not_found(
        self, email_service, mock_s3_service, mock_ses_service, sample_order
    ):
        """Test sending internal notification when template not found (fallback to plain text)."""
        # Arrange
        mock_s3_service.get_template.return_value = None

        # Act
        email_service.send_internal_notification(sample_order)

        # Assert
        mock_s3_service.get_template.assert_called_once()
        mock_ses_service.send_email.assert_called_once()

        call_args = mock_ses_service.send_email.call_args
        # Should use plain text fallback
        assert call_args[1]['text_body'] is not None
        assert 'ORD-2025-001' in call_args[1]['text_body']

    def test_send_internal_notification_ses_failure(
        self, email_service, mock_s3_service, mock_ses_service, sample_order
    ):
        """Test handling of SES send failure."""
        # Arrange
        mock_s3_service.get_template.return_value = "<h1>Test</h1>"
        mock_ses_service.send_email.side_effect = Exception("SES error")

        # Act & Assert
        with pytest.raises(Exception) as exc_info:
            email_service.send_internal_notification(sample_order)

        assert 'SES error' in str(exc_info.value)

    def test_create_fallback_plain_text_email(self, email_service, sample_order):
        """Test creation of fallback plain text email."""
        # Act
        result = email_service._create_fallback_email(sample_order)

        # Assert
        assert 'ORD-2025-001' in result
        assert 'customer@example.com' in result
        assert '574.99' in result
        assert 'John Doe' in result
        assert '1' in result  # item count

    def test_get_template_context(self, email_service, sample_order):
        """Test generation of template context from order."""
        # Act
        context = email_service._get_template_context(sample_order)

        # Assert
        assert context['orderNumber'] == 'ORD-2025-001'
        assert context['customerEmail'] == 'customer@example.com'
        assert context['total'] == 574.99
        assert context['itemCount'] == 1
        assert 'orderDate' in context
        assert 'orderDetailsUrl' in context
        assert 'tenant-123' in context['orderDetailsUrl']
        assert 'order-123' in context['orderDetailsUrl']
