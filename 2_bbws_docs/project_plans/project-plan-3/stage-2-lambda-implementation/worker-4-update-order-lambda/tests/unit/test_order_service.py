"""Unit tests for OrderService."""

from unittest.mock import MagicMock

import pytest

from src.services.order_service import OrderService
from src.models.order import OrderStatus
from src.models.requests import UpdateOrderRequest
from src.models.order import PaymentDetails
from src.utils.exceptions import (
    OrderNotFoundException,
    InvalidOrderStateException,
    OptimisticLockException
)


class TestOrderServiceUpdateOrder:
    """Tests for OrderService.update_order method."""

    def test_update_order_status_success(self, sample_order):
        """Test successful status update."""
        mock_dao = MagicMock()
        mock_dao.get_order.return_value = sample_order

        updated_order = sample_order.copy(deep=True)
        updated_order.status = OrderStatus.PAID
        updated_order.dateLastUpdated = '2025-12-30T11:00:00Z'
        mock_dao.update_order.return_value = updated_order

        service = OrderService(mock_dao)
        update_request = UpdateOrderRequest(status=OrderStatus.PAID)

        result = service.update_order(
            tenant_id='tenant-123',
            order_id='550e8400-e29b-41d4-a716-446655440000',
            update_request=update_request,
            updated_by='user@example.com'
        )

        assert result.status == OrderStatus.PAID
        mock_dao.get_order.assert_called_once_with('tenant-123', '550e8400-e29b-41d4-a716-446655440000')
        mock_dao.update_order.assert_called_once()

    def test_update_order_with_payment_details(self, sample_order):
        """Test update with payment details."""
        mock_dao = MagicMock()
        sample_order.status = OrderStatus.PAYMENT_PENDING
        mock_dao.get_order.return_value = sample_order

        updated_order = sample_order.copy(deep=True)
        updated_order.status = OrderStatus.PAID
        updated_order.paymentDetails = PaymentDetails(
            method='credit_card',
            transactionId='txn-123'
        )
        mock_dao.update_order.return_value = updated_order

        service = OrderService(mock_dao)
        payment = PaymentDetails(method='credit_card', transactionId='txn-123')
        update_request = UpdateOrderRequest(status=OrderStatus.PAID, paymentDetails=payment)

        result = service.update_order(
            tenant_id='tenant-123',
            order_id='550e8400-e29b-41d4-a716-446655440000',
            update_request=update_request,
            updated_by='user@example.com'
        )

        assert result.paymentDetails is not None
        assert result.paymentDetails.transactionId == 'txn-123'

    def test_update_order_not_found(self):
        """Test updating non-existent order raises OrderNotFoundException."""
        mock_dao = MagicMock()
        mock_dao.get_order.return_value = None

        service = OrderService(mock_dao)
        update_request = UpdateOrderRequest(status=OrderStatus.PAID)

        with pytest.raises(OrderNotFoundException):
            service.update_order(
                tenant_id='tenant-123',
                order_id='nonexistent',
                update_request=update_request,
                updated_by='user@example.com'
            )

    def test_update_order_no_updates(self):
        """Test request with no updates raises InvalidOrderStateException."""
        mock_dao = MagicMock()

        service = OrderService(mock_dao)
        update_request = UpdateOrderRequest()

        with pytest.raises(InvalidOrderStateException) as exc_info:
            service.update_order(
                tenant_id='tenant-123',
                order_id='order-123',
                update_request=update_request,
                updated_by='user@example.com'
            )

        assert "No updates provided" in str(exc_info.value)

    def test_update_completed_order_fails(self, sample_order):
        """Test updating completed order raises InvalidOrderStateException."""
        mock_dao = MagicMock()
        sample_order.status = OrderStatus.COMPLETED
        mock_dao.get_order.return_value = sample_order

        service = OrderService(mock_dao)
        update_request = UpdateOrderRequest(status=OrderStatus.CANCELLED)

        with pytest.raises(InvalidOrderStateException) as exc_info:
            service.update_order(
                tenant_id='tenant-123',
                order_id='550e8400-e29b-41d4-a716-446655440000',
                update_request=update_request,
                updated_by='user@example.com'
            )

        assert "immutable state" in str(exc_info.value).lower()

    def test_update_cancelled_order_fails(self, sample_order):
        """Test updating cancelled order raises InvalidOrderStateException."""
        mock_dao = MagicMock()
        sample_order.status = OrderStatus.CANCELLED
        mock_dao.get_order.return_value = sample_order

        service = OrderService(mock_dao)
        update_request = UpdateOrderRequest(status=OrderStatus.PAID)

        with pytest.raises(InvalidOrderStateException):
            service.update_order(
                tenant_id='tenant-123',
                order_id='550e8400-e29b-41d4-a716-446655440000',
                update_request=update_request,
                updated_by='user@example.com'
            )

    def test_invalid_status_transition(self, sample_order):
        """Test invalid status transition raises InvalidOrderStateException."""
        mock_dao = MagicMock()
        sample_order.status = OrderStatus.PENDING
        mock_dao.get_order.return_value = sample_order

        service = OrderService(mock_dao)
        # Invalid: pending -> completed (must go through paid -> processing first)
        update_request = UpdateOrderRequest(status=OrderStatus.COMPLETED)

        with pytest.raises(InvalidOrderStateException) as exc_info:
            service.update_order(
                tenant_id='tenant-123',
                order_id='550e8400-e29b-41d4-a716-446655440000',
                update_request=update_request,
                updated_by='user@example.com'
            )

        assert "Invalid status transition" in str(exc_info.value)

    def test_valid_status_transitions(self, sample_order):
        """Test valid status transitions are allowed."""
        mock_dao = MagicMock()
        service = OrderService(mock_dao)

        valid_transitions = [
            (OrderStatus.PENDING, OrderStatus.PAYMENT_PENDING),
            (OrderStatus.PENDING, OrderStatus.PAID),
            (OrderStatus.PENDING, OrderStatus.CANCELLED),
            (OrderStatus.PAYMENT_PENDING, OrderStatus.PAID),
            (OrderStatus.PAYMENT_PENDING, OrderStatus.CANCELLED),
            (OrderStatus.PAID, OrderStatus.PROCESSING),
            (OrderStatus.PAID, OrderStatus.CANCELLED),
            (OrderStatus.PROCESSING, OrderStatus.COMPLETED),
            (OrderStatus.PROCESSING, OrderStatus.CANCELLED),
        ]

        for current_status, new_status in valid_transitions:
            sample_order.status = current_status
            mock_dao.get_order.return_value = sample_order

            updated_order = sample_order.copy(deep=True)
            updated_order.status = new_status
            mock_dao.update_order.return_value = updated_order

            update_request = UpdateOrderRequest(status=new_status)

            result = service.update_order(
                tenant_id='tenant-123',
                order_id='550e8400-e29b-41d4-a716-446655440000',
                update_request=update_request,
                updated_by='user@example.com'
            )

            assert result.status == new_status

    def test_payment_details_without_paid_status_fails(self, sample_order):
        """Test setting payment details on non-paid order fails."""
        mock_dao = MagicMock()
        sample_order.status = OrderStatus.PENDING
        mock_dao.get_order.return_value = sample_order

        service = OrderService(mock_dao)
        payment = PaymentDetails(method='credit_card', transactionId='txn-123')
        update_request = UpdateOrderRequest(paymentDetails=payment)

        with pytest.raises(InvalidOrderStateException) as exc_info:
            service.update_order(
                tenant_id='tenant-123',
                order_id='550e8400-e29b-41d4-a716-446655440000',
                update_request=update_request,
                updated_by='user@example.com'
            )

        assert "payment details" in str(exc_info.value).lower()

    def test_optimistic_lock_propagates(self, sample_order):
        """Test OptimisticLockException propagates from DAO."""
        mock_dao = MagicMock()
        mock_dao.get_order.return_value = sample_order
        mock_dao.update_order.side_effect = OptimisticLockException()

        service = OrderService(mock_dao)
        update_request = UpdateOrderRequest(status=OrderStatus.PAID)

        with pytest.raises(OptimisticLockException):
            service.update_order(
                tenant_id='tenant-123',
                order_id='550e8400-e29b-41d4-a716-446655440000',
                update_request=update_request,
                updated_by='user@example.com'
            )
