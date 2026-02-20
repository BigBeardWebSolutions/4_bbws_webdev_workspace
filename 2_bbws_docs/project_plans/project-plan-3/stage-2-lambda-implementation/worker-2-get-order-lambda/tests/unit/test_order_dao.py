"""
Unit tests for OrderDAO.

Tests the Data Access Object layer with mocked DynamoDB client.
"""
import pytest
from unittest.mock import Mock, MagicMock
from decimal import Decimal

from src.dao.order_dao import OrderDAO
from src.models import Order


class TestOrderDAO:
    """Test suite for OrderDAO."""

    def test_get_order_success(self, sample_dynamodb_item, sample_order_data):
        """Test successful order retrieval."""
        # Arrange
        mock_dynamodb = Mock()
        mock_dynamodb.get_item.return_value = {'Item': sample_dynamodb_item}
        dao = OrderDAO(mock_dynamodb, 'test-table')

        # Act
        order = dao.get_order('tenant_bb0e8400-e29b-41d4-a716-446655440006',
                             'order_aa0e8400-e29b-41d4-a716-446655440005')

        # Assert
        assert order is not None
        assert isinstance(order, Order)
        assert order.id == 'order_aa0e8400-e29b-41d4-a716-446655440005'
        assert order.orderNumber == 'ORD-20251215-0001'
        assert order.tenantId == 'tenant_bb0e8400-e29b-41d4-a716-446655440006'
        assert order.customerEmail == 'customer@example.com'
        assert order.total == Decimal('275.98')
        assert order.status == 'PENDING_PAYMENT'

        # Verify DynamoDB call
        mock_dynamodb.get_item.assert_called_once_with(
            TableName='test-table',
            Key={
                'PK': {'S': 'TENANT#tenant_bb0e8400-e29b-41d4-a716-446655440006'},
                'SK': {'S': 'ORDER#order_aa0e8400-e29b-41d4-a716-446655440005'}
            }
        )

    def test_get_order_not_found(self):
        """Test order not found scenario."""
        # Arrange
        mock_dynamodb = Mock()
        mock_dynamodb.get_item.return_value = {}  # No 'Item' key
        dao = OrderDAO(mock_dynamodb, 'test-table')

        # Act
        order = dao.get_order('tenant_123', 'order_999')

        # Assert
        assert order is None
        mock_dynamodb.get_item.assert_called_once()

    def test_get_order_with_campaign(self, sample_dynamodb_item):
        """Test order retrieval with embedded campaign."""
        # Arrange
        mock_dynamodb = Mock()
        mock_dynamodb.get_item.return_value = {'Item': sample_dynamodb_item}
        dao = OrderDAO(mock_dynamodb, 'test-table')

        # Act
        order = dao.get_order('tenant_bb0e8400-e29b-41d4-a716-446655440006',
                             'order_aa0e8400-e29b-41d4-a716-446655440005')

        # Assert
        assert order.campaign is not None
        assert order.campaign.code == 'SUMMER2025'
        assert order.campaign.discountPercentage == Decimal('20.0')

    def test_get_order_with_items(self, sample_dynamodb_item):
        """Test order retrieval with order items."""
        # Arrange
        mock_dynamodb = Mock()
        mock_dynamodb.get_item.return_value = {'Item': sample_dynamodb_item}
        dao = OrderDAO(mock_dynamodb, 'test-table')

        # Act
        order = dao.get_order('tenant_bb0e8400-e29b-41d4-a716-446655440006',
                             'order_aa0e8400-e29b-41d4-a716-446655440005')

        # Assert
        assert len(order.items) == 1
        assert order.items[0].productName == 'WordPress Professional Plan'
        assert order.items[0].quantity == 1
        assert order.items[0].subtotal == Decimal('239.99')

    def test_get_order_dynamodb_error(self):
        """Test handling of DynamoDB errors."""
        # Arrange
        mock_dynamodb = Mock()
        mock_dynamodb.get_item.side_effect = Exception('DynamoDB error')
        dao = OrderDAO(mock_dynamodb, 'test-table')

        # Act & Assert
        with pytest.raises(Exception) as exc_info:
            dao.get_order('tenant_123', 'order_456')

        assert 'DynamoDB error' in str(exc_info.value)

    def test_deserialize_item(self, sample_dynamodb_item):
        """Test _deserialize_item private method."""
        # Arrange
        mock_dynamodb = Mock()
        dao = OrderDAO(mock_dynamodb, 'test-table')

        # Act
        result = dao._deserialize_item(sample_dynamodb_item)

        # Assert
        assert result['id'] == 'order_aa0e8400-e29b-41d4-a716-446655440005'
        assert result['orderNumber'] == 'ORD-20251215-0001'
        assert result['total'] == Decimal('275.98')
        assert isinstance(result['items'], list)
        assert isinstance(result['billingAddress'], dict)
        # GSI keys should be excluded
        assert 'PK' not in result
        assert 'SK' not in result
        assert 'GSI1_PK' not in result
