"""Unit tests for OrderDAO."""

import pytest
from datetime import datetime
from unittest.mock import Mock, MagicMock, patch
from decimal import Decimal
from botocore.exceptions import ClientError

from src.dao.order_dao import OrderDAO
from src.models import Order, OrderItem, Campaign, BillingAddress


class TestOrderDAO:
    """Test cases for OrderDAO."""

    @pytest.fixture
    def mock_dynamodb(self):
        """Create mock DynamoDB client."""
        return Mock()

    @pytest.fixture
    def order_dao(self, mock_dynamodb):
        """Create OrderDAO instance with mocked DynamoDB."""
        with patch.dict('os.environ', {'DYNAMODB_TABLE_NAME': 'test-orders-table'}):
            dao = OrderDAO()
            dao.dynamodb = mock_dynamodb
            dao.table = mock_dynamodb.Table.return_value
            return dao

    @pytest.fixture
    def sample_order_data(self):
        """Sample order data from DynamoDB."""
        return {
            'PK': 'TENANT#tenant-123',
            'SK': 'ORDER#order-123',
            'orderId': 'order-123',
            'tenantId': 'tenant-123',
            'orderNumber': 'ORD-2025-001',
            'customerEmail': 'customer@example.com',
            'customerName': 'John Doe',
            'customerPhone': '+27123456789',
            'items': [
                {
                    'itemId': 'item-123',
                    'campaign': {
                        'campaignId': 'campaign-123',
                        'campaignName': 'Basic Website Package',
                        'price': Decimal('499.99'),
                        'description': '5-page website'
                    },
                    'quantity': 1,
                    'unitPrice': Decimal('499.99'),
                    'subtotal': Decimal('499.99')
                }
            ],
            'subtotal': Decimal('499.99'),
            'tax': Decimal('75.00'),
            'shipping': Decimal('0.00'),
            'discount': Decimal('0.00'),
            'total': Decimal('574.99'),
            'orderStatus': 'pending',
            'paymentStatus': 'pending',
            'billingAddress': {
                'street': '123 Main St',
                'city': 'Cape Town',
                'state': 'Western Cape',
                'postalCode': '8001',
                'country': 'ZA'
            },
            'createdAt': '2025-12-30T10:00:00Z',
            'updatedAt': '2025-12-30T10:00:00Z',
            'createdBy': 'user-123',
            'notificationSent': False,
            'confirmationSent': False
        }

    def test_get_order_success(self, order_dao, sample_order_data):
        """Test successful order retrieval."""
        # Arrange
        order_dao.table.get_item.return_value = {
            'Item': sample_order_data
        }

        # Act
        result = order_dao.get_order('tenant-123', 'order-123')

        # Assert
        assert result is not None
        assert isinstance(result, Order)
        assert result.order_id == 'order-123'
        assert result.tenant_id == 'tenant-123'
        assert result.order_number == 'ORD-2025-001'
        assert result.customer_email == 'customer@example.com'
        assert result.total == 574.99
        assert len(result.items) == 1

        # Verify DynamoDB call
        order_dao.table.get_item.assert_called_once_with(
            Key={
                'PK': 'TENANT#tenant-123',
                'SK': 'ORDER#order-123'
            }
        )

    def test_get_order_not_found(self, order_dao):
        """Test order not found scenario."""
        # Arrange
        order_dao.table.get_item.return_value = {}

        # Act
        result = order_dao.get_order('tenant-123', 'nonexistent-order')

        # Assert
        assert result is None

    def test_get_order_dynamodb_error(self, order_dao):
        """Test DynamoDB error handling."""
        # Arrange
        error_response = {'Error': {'Code': 'InternalServerError', 'Message': 'Internal error'}}
        order_dao.table.get_item.side_effect = ClientError(error_response, 'GetItem')

        # Act & Assert
        with pytest.raises(Exception) as exc_info:
            order_dao.get_order('tenant-123', 'order-123')

        assert 'Failed to retrieve order' in str(exc_info.value)

    def test_get_order_decimal_conversion(self, order_dao, sample_order_data):
        """Test that Decimal values are properly converted to float."""
        # Arrange
        order_dao.table.get_item.return_value = {
            'Item': sample_order_data
        }

        # Act
        result = order_dao.get_order('tenant-123', 'order-123')

        # Assert
        assert isinstance(result.total, float)
        assert isinstance(result.subtotal, float)
        assert isinstance(result.tax, float)
        assert isinstance(result.items[0].unit_price, float)

    def test_get_order_with_optional_fields(self, order_dao, sample_order_data):
        """Test order retrieval with optional fields populated."""
        # Arrange
        sample_order_data['notes'] = 'Special delivery instructions'
        sample_order_data['pdfUrl'] = 's3://bucket/order-123.pdf'
        sample_order_data['cartId'] = 'cart-123'

        order_dao.table.get_item.return_value = {
            'Item': sample_order_data
        }

        # Act
        result = order_dao.get_order('tenant-123', 'order-123')

        # Assert
        assert result.notes == 'Special delivery instructions'
        assert result.pdf_url == 's3://bucket/order-123.pdf'
        assert result.cart_id == 'cart-123'

    def test_get_order_missing_required_field(self, order_dao, sample_order_data):
        """Test handling of missing required fields."""
        # Arrange
        del sample_order_data['customerEmail']
        order_dao.table.get_item.return_value = {
            'Item': sample_order_data
        }

        # Act & Assert
        with pytest.raises(Exception) as exc_info:
            order_dao.get_order('tenant-123', 'order-123')

        # Pydantic validation error expected
        assert 'customerEmail' in str(exc_info.value) or 'customer_email' in str(exc_info.value)
