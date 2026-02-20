"""
OrderService - Business logic for order operations.

This service layer implements business rules and validation before
delegating to the DAO layer for persistence.
"""

import logging
from typing import Dict, Any

from src.dao.order_dao import OrderDAO
from src.models.order import Order, OrderStatus
from src.models.requests import UpdateOrderRequest
from src.utils.exceptions import (
    OrderNotFoundException,
    InvalidOrderStateException,
    OptimisticLockException
)

logger = logging.getLogger()


class OrderService:
    """Service class for order business logic."""

    # Orders in these states cannot be updated
    IMMUTABLE_STATES = {OrderStatus.COMPLETED, OrderStatus.CANCELLED, OrderStatus.REFUNDED}

    def __init__(self, order_dao: OrderDAO):
        """
        Initialize OrderService.

        Args:
            order_dao: Order data access object
        """
        self.order_dao = order_dao

    def update_order(
        self,
        tenant_id: str,
        order_id: str,
        update_request: UpdateOrderRequest,
        updated_by: str
    ) -> Order:
        """
        Update order status and/or payment details.

        Business rules:
        1. Order must exist and belong to the tenant
        2. Order must not be in immutable state (completed, cancelled, refunded)
        3. Status transitions must be valid
        4. Payment details can only be set when status is paid or payment_pending
        5. Optimistic locking prevents concurrent updates

        Args:
            tenant_id: Tenant identifier (from JWT)
            order_id: Order identifier (from path)
            update_request: Update request with status and/or paymentDetails
            updated_by: Email or system identifier of updater

        Returns:
            Updated Order object

        Raises:
            OrderNotFoundException: If order doesn't exist
            InvalidOrderStateException: If order is in immutable state or invalid transition
            OptimisticLockException: If concurrent update detected
        """
        # Validate request has updates
        if not update_request.has_updates():
            raise InvalidOrderStateException("No updates provided")

        # Fetch existing order
        existing_order = self.order_dao.get_order(tenant_id, order_id)
        if not existing_order:
            logger.warning(f"Order not found: tenantId={tenant_id}, orderId={order_id}")
            raise OrderNotFoundException(f"Order {order_id} not found")

        # Check if order is in immutable state
        if existing_order.status in self.IMMUTABLE_STATES:
            logger.warning(
                f"Cannot update order in immutable state: orderId={order_id}, "
                f"status={existing_order.status}"
            )
            raise InvalidOrderStateException(
                f"Cannot update order in {existing_order.status} state"
            )

        # Validate status transition
        if update_request.status:
            self._validate_status_transition(existing_order.status, update_request.status)

        # Validate payment details
        if update_request.paymentDetails:
            new_status = update_request.status or existing_order.status
            if new_status not in {OrderStatus.PAID, OrderStatus.PAYMENT_PENDING}:
                raise InvalidOrderStateException(
                    f"Payment details can only be set when status is 'paid' or 'payment_pending'"
                )

        # Build updates dictionary
        updates = {}
        if update_request.status:
            updates['status'] = update_request.status.value

        if update_request.paymentDetails:
            updates['paymentDetails'] = update_request.paymentDetails.dict(exclude_none=True)

        # Perform update with optimistic locking
        try:
            updated_order = self.order_dao.update_order(
                tenant_id=tenant_id,
                order_id=order_id,
                updates=updates,
                expected_last_updated=existing_order.dateLastUpdated,
                updated_by=updated_by
            )

            logger.info(
                f"Order updated successfully: orderId={order_id}, "
                f"status={existing_order.status} -> {updated_order.status}"
            )

            return updated_order

        except OptimisticLockException:
            # Re-raise with context
            logger.warning(f"Optimistic lock failure for orderId={order_id}")
            raise

    def _validate_status_transition(self, current: OrderStatus, new: OrderStatus) -> None:
        """
        Validate status transition is allowed.

        Valid transitions:
        - pending -> payment_pending, paid, cancelled
        - payment_pending -> paid, cancelled
        - paid -> processing
        - processing -> completed, cancelled
        - Any state can transition to cancelled (customer/admin action)

        Args:
            current: Current order status
            new: New order status

        Raises:
            InvalidOrderStateException: If transition is not allowed
        """
        # Allow same status (no-op)
        if current == new:
            return

        # Define valid transitions
        valid_transitions = {
            OrderStatus.PENDING: {
                OrderStatus.PAYMENT_PENDING,
                OrderStatus.PAID,
                OrderStatus.CANCELLED
            },
            OrderStatus.PAYMENT_PENDING: {
                OrderStatus.PAID,
                OrderStatus.CANCELLED
            },
            OrderStatus.PAID: {
                OrderStatus.PROCESSING,
                OrderStatus.CANCELLED
            },
            OrderStatus.PROCESSING: {
                OrderStatus.COMPLETED,
                OrderStatus.CANCELLED
            },
        }

        # Check if transition is valid
        allowed_next_states = valid_transitions.get(current, set())

        # Cancelled can be reached from any non-immutable state
        if new == OrderStatus.CANCELLED and current not in self.IMMUTABLE_STATES:
            return

        if new not in allowed_next_states:
            logger.warning(
                f"Invalid status transition: {current} -> {new}"
            )
            raise InvalidOrderStateException(
                f"Invalid status transition from {current} to {new}"
            )
