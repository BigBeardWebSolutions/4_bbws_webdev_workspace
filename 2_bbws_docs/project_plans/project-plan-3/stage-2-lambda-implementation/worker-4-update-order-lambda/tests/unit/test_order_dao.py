"""Unit tests for OrderDAO."""

from decimal import Decimal
from unittest.mock import MagicMock

import pytest
from botocore.exceptions import ClientError

from src.dao.order_dao import OrderDAO
from src.models.order import Order
from src.utils.exceptions import (
    OrderNotFoundException,
    OptimisticLockException,
    DatabaseException
)


class TestOrderDAOGetOrder:
    """Tests for OrderDAO.get_order method."""

    def test_get_order_success(self, mock_dynamodb_client, sample_order):
        """Test successful order retrieval."""
        # Mock DynamoDB response
        mock_dynamodb_client.get_item.return_value = {
            'Item': {
                'PK': {'S': 'TENANT#tenant-123'},
                'SK': {'S': 'ORDER#550e8400-e29b-41d4-a716-446655440000'},
                'id': {'S': sample_order.id},
                'orderNumber': {'S': sample_order.orderNumber},
                'tenantId': {'S': sample_order.tenantId},
                'customerEmail': {'S': sample_order.customerEmail},
                'status': {'S': sample_order.status.value},
                'subtotal': {'N': str(sample_order.subtotal)},
                'tax': {'N': str(sample_order.tax)},
                'shipping': {'N': str(sample_order.shipping)},
                'total': {'N': str(sample_order.total)},
                'currency': {'S': sample_order.currency},
                'items': {'L': [{
                    'M': {
                        'id': {'S': 'item-123'},
                        'productId': {'S': 'prod-456'},
                        'productName': {'S': 'Test Product'},
                        'quantity': {'N': '1'},
                        'unitPrice': {'N': '299.00'},
                        'discount': {'N': '0.00'},
                        'subtotal': {'N': '299.00'},
                        'dateCreated': {'S': '2025-12-30T10:00:00Z'},
                        'dateLastUpdated': {'S': '2025-12-30T10:00:00Z'},
                        'lastUpdatedBy': {'S': 'system'},
                        'active': {'BOOL': True}
                    }
                }]},
                'billingAddress': {'M': {
                    'street': {'S': '123 Main St'},
                    'city': {'S': 'Cape Town'},
                    'province': {'S': 'Western Cape'},
                    'postalCode': {'S': '8001'},
                    'country': {'S': 'South Africa'}
                }},
                'dateCreated': {'S': sample_order.dateCreated},
                'dateLastUpdated': {'S': sample_order.dateLastUpdated},
                'lastUpdatedBy': {'S': sample_order.lastUpdatedBy},
                'active': {'BOOL': sample_order.active}
            }
        }

        dao = OrderDAO(mock_dynamodb_client, 'test-table')
        order = dao.get_order('tenant-123', '550e8400-e29b-41d4-a716-446655440000')

        assert order is not None
        assert order.id == sample_order.id
        assert order.tenantId == 'tenant-123'

        mock_dynamodb_client.get_item.assert_called_once()

    def test_get_order_not_found(self, mock_dynamodb_client):
        """Test order not found returns None."""
        mock_dynamodb_client.get_item.return_value = {}

        dao = OrderDAO(mock_dynamodb_client, 'test-table')
        order = dao.get_order('tenant-123', 'nonexistent')

        assert order is None

    def test_get_order_database_error(self, mock_dynamodb_client):
        """Test database error raises DatabaseException."""
        mock_dynamodb_client.get_item.side_effect = ClientError(
            {'Error': {'Code': 'InternalServerError', 'Message': 'Server error'}},
            'GetItem'
        )

        dao = OrderDAO(mock_dynamodb_client, 'test-table')

        with pytest.raises(DatabaseException):
            dao.get_order('tenant-123', 'order-123')


class TestOrderDAOUpdateOrder:
    """Tests for OrderDAO.update_order method."""

    def test_update_order_status_success(self, mock_dynamodb_client, sample_order):
        """Test successful order status update."""
        # Mock DynamoDB response
        updated_order_data = sample_order.dict()
        updated_order_data['status'] = 'paid'
        updated_order_data['dateLastUpdated'] = '2025-12-30T11:00:00Z'

        mock_dynamodb_client.update_item.return_value = {
            'Attributes': {
                'PK': {'S': 'TENANT#tenant-123'},
                'SK': {'S': 'ORDER#550e8400-e29b-41d4-a716-446655440000'},
                'id': {'S': sample_order.id},
                'orderNumber': {'S': sample_order.orderNumber},
                'tenantId': {'S': sample_order.tenantId},
                'customerEmail': {'S': sample_order.customerEmail},
                'status': {'S': 'paid'},
                'subtotal': {'N': str(sample_order.subtotal)},
                'tax': {'N': str(sample_order.tax)},
                'shipping': {'N': str(sample_order.shipping)},
                'total': {'N': str(sample_order.total)},
                'currency': {'S': sample_order.currency},
                'items': {'L': [{
                    'M': {
                        'id': {'S': 'item-123'},
                        'productId': {'S': 'prod-456'},
                        'productName': {'S': 'Test Product'},
                        'quantity': {'N': '1'},
                        'unitPrice': {'N': '299.00'},
                        'discount': {'N': '0.00'},
                        'subtotal': {'N': '299.00'},
                        'dateCreated': {'S': '2025-12-30T10:00:00Z'},
                        'dateLastUpdated': {'S': '2025-12-30T10:00:00Z'},
                        'lastUpdatedBy': {'S': 'system'},
                        'active': {'BOOL': True}
                    }
                }]},
                'billingAddress': {'M': {
                    'street': {'S': '123 Main St'},
                    'city': {'S': 'Cape Town'},
                    'province': {'S': 'Western Cape'},
                    'postalCode': {'S': '8001'},
                    'country': {'S': 'South Africa'}
                }},
                'dateCreated': {'S': sample_order.dateCreated},
                'dateLastUpdated': {'S': '2025-12-30T11:00:00Z'},
                'lastUpdatedBy': {'S': 'user@example.com'},
                'active': {'BOOL': True}
            }
        }

        dao = OrderDAO(mock_dynamodb_client, 'test-table')
        updated_order = dao.update_order(
            tenant_id='tenant-123',
            order_id='550e8400-e29b-41d4-a716-446655440000',
            updates={'status': 'paid'},
            expected_last_updated='2025-12-30T10:00:00Z',
            updated_by='user@example.com'
        )

        assert updated_order.status.value == 'paid'
        assert updated_order.dateLastUpdated == '2025-12-30T11:00:00Z'

        mock_dynamodb_client.update_item.assert_called_once()

    def test_update_order_with_payment_details(self, mock_dynamodb_client, sample_order):
        """Test order update with payment details."""
        payment_details = {
            'method': 'credit_card',
            'transactionId': 'txn-123',
            'paidAt': '2025-12-30T11:00:00Z'
        }

        mock_dynamodb_client.update_item.return_value = {
            'Attributes': {
                'PK': {'S': 'TENANT#tenant-123'},
                'SK': {'S': 'ORDER#550e8400-e29b-41d4-a716-446655440000'},
                'id': {'S': sample_order.id},
                'orderNumber': {'S': sample_order.orderNumber},
                'tenantId': {'S': sample_order.tenantId},
                'customerEmail': {'S': sample_order.customerEmail},
                'status': {'S': 'paid'},
                'paymentDetails': {'M': {
                    'method': {'S': 'credit_card'},
                    'transactionId': {'S': 'txn-123'},
                    'paidAt': {'S': '2025-12-30T11:00:00Z'}
                }},
                'subtotal': {'N': str(sample_order.subtotal)},
                'tax': {'N': str(sample_order.tax)},
                'shipping': {'N': str(sample_order.shipping)},
                'total': {'N': str(sample_order.total)},
                'currency': {'S': sample_order.currency},
                'items': {'L': [{
                    'M': {
                        'id': {'S': 'item-123'},
                        'productId': {'S': 'prod-456'},
                        'productName': {'S': 'Test Product'},
                        'quantity': {'N': '1'},
                        'unitPrice': {'N': '299.00'},
                        'discount': {'N': '0.00'},
                        'subtotal': {'N': '299.00'},
                        'dateCreated': {'S': '2025-12-30T10:00:00Z'},
                        'dateLastUpdated': {'S': '2025-12-30T10:00:00Z'},
                        'lastUpdatedBy': {'S': 'system'},
                        'active': {'BOOL': True}
                    }
                }]},
                'billingAddress': {'M': {
                    'street': {'S': '123 Main St'},
                    'city': {'S': 'Cape Town'},
                    'province': {'S': 'Western Cape'},
                    'postalCode': {'S': '8001'},
                    'country': {'S': 'South Africa'}
                }},
                'dateCreated': {'S': sample_order.dateCreated},
                'dateLastUpdated': {'S': '2025-12-30T11:00:00Z'},
                'lastUpdatedBy': {'S': 'user@example.com'},
                'active': {'BOOL': True}
            }
        }

        dao = OrderDAO(mock_dynamodb_client, 'test-table')
        updated_order = dao.update_order(
            tenant_id='tenant-123',
            order_id='550e8400-e29b-41d4-a716-446655440000',
            updates={'status': 'paid', 'paymentDetails': payment_details},
            expected_last_updated='2025-12-30T10:00:00Z',
            updated_by='user@example.com'
        )

        assert updated_order.paymentDetails is not None
        assert updated_order.paymentDetails.method == 'credit_card'

    def test_update_order_optimistic_lock_failure(self, mock_dynamodb_client):
        """Test optimistic lock failure raises OptimisticLockException."""
        mock_dynamodb_client.update_item.side_effect = ClientError(
            {'Error': {'Code': 'ConditionalCheckFailedException', 'Message': 'Condition failed'}},
            'UpdateItem'
        )

        dao = OrderDAO(mock_dynamodb_client, 'test-table')

        with pytest.raises(OptimisticLockException) as exc_info:
            dao.update_order(
                tenant_id='tenant-123',
                order_id='order-123',
                updates={'status': 'paid'},
                expected_last_updated='2025-12-30T10:00:00Z',
                updated_by='user@example.com'
            )

        assert "modified by another process" in str(exc_info.value).lower()

    def test_update_order_not_found(self, mock_dynamodb_client):
        """Test updating non-existent order raises OrderNotFoundException."""
        mock_dynamodb_client.update_item.side_effect = ClientError(
            {'Error': {'Code': 'ResourceNotFoundException', 'Message': 'Table not found'}},
            'UpdateItem'
        )

        dao = OrderDAO(mock_dynamodb_client, 'test-table')

        with pytest.raises(OrderNotFoundException):
            dao.update_order(
                tenant_id='tenant-123',
                order_id='nonexistent',
                updates={'status': 'paid'},
                expected_last_updated='2025-12-30T10:00:00Z',
                updated_by='user@example.com'
            )

    def test_update_order_database_error(self, mock_dynamodb_client):
        """Test database error raises DatabaseException."""
        mock_dynamodb_client.update_item.side_effect = ClientError(
            {'Error': {'Code': 'InternalServerError', 'Message': 'Server error'}},
            'UpdateItem'
        )

        dao = OrderDAO(mock_dynamodb_client, 'test-table')

        with pytest.raises(DatabaseException):
            dao.update_order(
                tenant_id='tenant-123',
                order_id='order-123',
                updates={'status': 'paid'},
                expected_last_updated='2025-12-30T10:00:00Z',
                updated_by='user@example.com'
            )
