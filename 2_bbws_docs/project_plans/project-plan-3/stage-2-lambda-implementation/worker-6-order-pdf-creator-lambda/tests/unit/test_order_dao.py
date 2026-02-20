"""
Unit tests for OrderDAO.

Tests DynamoDB operations with mocked boto3 client.
"""

import pytest
from datetime import datetime
from src.dao.order_dao import OrderDAO
from src.models.order import Order


class TestOrderDAO:
    """Tests for OrderDAO class."""

    def test_init(self, mock_dynamodb_client):
        """Test OrderDAO initialization."""
        dao = OrderDAO(mock_dynamodb_client, "test-table")
        assert dao.dynamodb == mock_dynamodb_client
        assert dao.table_name == "test-table"

    def test_get_order_success(self, mock_dynamodb_client, sample_order):
        """Test successful order retrieval."""
        # Mock DynamoDB response
        mock_dynamodb_client.get_item.return_value = {
            'Item': {
                'PK': {'S': 'TENANT#tenant-123'},
                'SK': {'S': 'ORDER#550e8400-e29b-41d4-a716-446655440000'},
                'id': {'S': '550e8400-e29b-41d4-a716-446655440000'},
                'orderNumber': {'S': 'ORD-2025-00001'},
                'tenantId': {'S': 'tenant-123'},
                'customerEmail': {'S': 'customer@example.com'},
                'customerName': {'S': 'John Doe'},
                'status': {'S': 'paid'},
                'subtotal': {'N': '99.00'},
                'taxAmount': {'N': '14.85'},
                'shippingAmount': {'N': '0.00'},
                'discountAmount': {'N': '0.00'},
                'total': {'N': '113.85'},
                'currency': {'S': 'ZAR'},
                'isActive': {'BOOL': True},
                'dateCreated': {'S': '2025-12-30T10:30:00'},
                'dateLastUpdated': {'S': '2025-12-30T10:30:00'},
                'items': {'S': '[{"productId": "prod-123", "productName": "Premium WordPress Theme", "productSku": "WP-THEME-001", "quantity": 1, "unitPrice": 99.0, "currency": "ZAR", "subtotal": 99.0, "taxRate": 0.15, "taxAmount": 14.85, "total": 113.85}]'},
                'billingAddress': {'S': '{"fullName": "John Doe", "addressLine1": "123 Main Street", "addressLine2": "Apt 4B", "city": "Cape Town", "stateProvince": "Western Cape", "postalCode": "8001", "country": "ZA", "phoneNumber": "+27123456789"}'}
            }
        }

        dao = OrderDAO(mock_dynamodb_client, "test-table")
        order = dao.get_order("tenant-123", "550e8400-e29b-41d4-a716-446655440000")

        # Verify DynamoDB was called correctly
        mock_dynamodb_client.get_item.assert_called_once_with(
            TableName="test-table",
            Key={
                'PK': {'S': 'TENANT#tenant-123'},
                'SK': {'S': 'ORDER#550e8400-e29b-41d4-a716-446655440000'}
            }
        )

        # Verify returned order
        assert order is not None
        assert order.id == "550e8400-e29b-41d4-a716-446655440000"
        assert order.orderNumber == "ORD-2025-00001"
        assert order.tenantId == "tenant-123"
        assert order.total == 113.85

    def test_get_order_not_found(self, mock_dynamodb_client):
        """Test order not found returns None."""
        # Mock DynamoDB response with no item
        mock_dynamodb_client.get_item.return_value = {}

        dao = OrderDAO(mock_dynamodb_client, "test-table")
        order = dao.get_order("tenant-123", "non-existent")

        assert order is None

    def test_get_order_dynamodb_error(self, mock_dynamodb_client):
        """Test DynamoDB error is raised."""
        # Mock DynamoDB error
        mock_dynamodb_client.get_item.side_effect = Exception("DynamoDB error")

        dao = OrderDAO(mock_dynamodb_client, "test-table")

        with pytest.raises(Exception) as exc_info:
            dao.get_order("tenant-123", "order-123")

        assert "DynamoDB error" in str(exc_info.value)

    def test_update_order_success(self, mock_dynamodb_client, sample_order):
        """Test successful order update."""
        dao = OrderDAO(mock_dynamodb_client, "test-table")

        # Update PDF URL
        sample_order.pdfUrl = "https://s3.amazonaws.com/bucket/order.pdf"

        updated_order = dao.update_order(sample_order)

        # Verify DynamoDB was called
        mock_dynamodb_client.put_item.assert_called_once()
        call_args = mock_dynamodb_client.put_item.call_args

        # Verify table name
        assert call_args[1]['TableName'] == 'test-table'

        # Verify item has correct keys
        item = call_args[1]['Item']
        assert item['PK']['S'] == 'TENANT#tenant-123'
        assert item['SK']['S'] == 'ORDER#550e8400-e29b-41d4-a716-446655440000'
        assert item['pdfUrl']['S'] == 'https://s3.amazonaws.com/bucket/order.pdf'

        # Verify returned order
        assert updated_order.pdfUrl == "https://s3.amazonaws.com/bucket/order.pdf"
        assert updated_order.dateLastUpdated > sample_order.dateLastUpdated

    def test_update_order_dynamodb_error(self, mock_dynamodb_client, sample_order):
        """Test DynamoDB update error is raised."""
        # Mock DynamoDB error
        mock_dynamodb_client.put_item.side_effect = Exception("DynamoDB error")

        dao = OrderDAO(mock_dynamodb_client, "test-table")

        with pytest.raises(Exception) as exc_info:
            dao.update_order(sample_order)

        assert "DynamoDB error" in str(exc_info.value)

    def test_serialize_order_structure(self, mock_dynamodb_client, sample_order):
        """Test order serialization creates correct DynamoDB item structure."""
        dao = OrderDAO(mock_dynamodb_client, "test-table")

        item = dao._serialize_order(sample_order)

        # Verify primary key
        assert item['PK']['S'] == 'TENANT#tenant-123'
        assert item['SK']['S'] == 'ORDER#550e8400-e29b-41d4-a716-446655440000'

        # Verify GSI keys
        assert item['GSI1_PK']['S'] == 'TENANT#tenant-123'
        assert '2025-12-30' in item['GSI1_SK']['S']
        assert item['GSI2_PK']['S'] == 'ORDER#550e8400-e29b-41d4-a716-446655440000'
        assert item['GSI2_SK']['S'] == 'METADATA'

        # Verify attributes
        assert item['id']['S'] == sample_order.id
        assert item['orderNumber']['S'] == sample_order.orderNumber
        assert item['total']['N'] == str(sample_order.total)
        assert item['isActive']['BOOL'] == True

    def test_deserialize_item_structure(self, mock_dynamodb_client):
        """Test DynamoDB item deserialization."""
        dao = OrderDAO(mock_dynamodb_client, "test-table")

        dynamodb_item = {
            'id': {'S': 'order-123'},
            'orderNumber': {'S': 'ORD-2025-00001'},
            'tenantId': {'S': 'tenant-123'},
            'customerEmail': {'S': 'test@example.com'},
            'status': {'S': 'pending'},
            'subtotal': {'N': '100.00'},
            'taxAmount': {'N': '15.00'},
            'shippingAmount': {'N': '0.00'},
            'discountAmount': {'N': '0.00'},
            'total': {'N': '115.00'},
            'currency': {'S': 'ZAR'},
            'isActive': {'BOOL': True},
            'dateCreated': {'S': '2025-12-30T10:00:00'},
            'dateLastUpdated': {'S': '2025-12-30T10:00:00'},
            'items': {'S': '[]'},
            'billingAddress': {'S': '{"fullName": "Test", "addressLine1": "123 St", "city": "City", "stateProvince": "State", "postalCode": "12345", "country": "ZA"}'}
        }

        order_data = dao._deserialize_item(dynamodb_item)

        assert order_data['id'] == 'order-123'
        assert order_data['orderNumber'] == 'ORD-2025-00001'
        assert order_data['total'] == 115.00
        assert order_data['isActive'] is True
        assert isinstance(order_data['items'], list)
        assert isinstance(order_data['billingAddress'], dict)
