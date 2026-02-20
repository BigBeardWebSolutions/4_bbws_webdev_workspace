"""Unit tests for Pydantic models."""

from decimal import Decimal

import pytest
from pydantic import ValidationError

from src.models.order import (
    Order,
    OrderItem,
    PaymentDetails,
    OrderStatus
)
from src.models.requests import UpdateOrderRequest


class TestOrderStatus:
    """Tests for OrderStatus enum."""

    def test_order_status_values(self):
        """Test that all order statuses are defined."""
        assert OrderStatus.PENDING == "pending"
        assert OrderStatus.PAYMENT_PENDING == "payment_pending"
        assert OrderStatus.PAID == "paid"
        assert OrderStatus.PROCESSING == "processing"
        assert OrderStatus.COMPLETED == "completed"
        assert OrderStatus.CANCELLED == "cancelled"
        assert OrderStatus.REFUNDED == "refunded"


class TestPaymentDetails:
    """Tests for PaymentDetails model."""

    def test_payment_details_with_all_fields(self):
        """Test PaymentDetails with all fields."""
        payment = PaymentDetails(
            method="credit_card",
            transactionId="txn-123",
            payfastPaymentId="pf-456",
            paidAt="2025-12-30T11:00:00Z"
        )

        assert payment.method == "credit_card"
        assert payment.transactionId == "txn-123"
        assert payment.payfastPaymentId == "pf-456"
        assert payment.paidAt == "2025-12-30T11:00:00Z"

    def test_payment_details_optional_fields(self):
        """Test PaymentDetails with optional fields."""
        payment = PaymentDetails()

        assert payment.method is None
        assert payment.transactionId is None
        assert payment.payfastPaymentId is None
        assert payment.paidAt is None

    def test_payment_details_partial(self):
        """Test PaymentDetails with partial data."""
        payment = PaymentDetails(
            method="payfast",
            payfastPaymentId="pf-789"
        )

        assert payment.method == "payfast"
        assert payment.payfastPaymentId == "pf-789"
        assert payment.transactionId is None


class TestOrderItem:
    """Tests for OrderItem model."""

    def test_order_item_valid(self, sample_order_item):
        """Test OrderItem with valid data."""
        assert sample_order_item.id == "item-123"
        assert sample_order_item.productId == "prod-456"
        assert sample_order_item.quantity == 1
        assert sample_order_item.unitPrice == Decimal("299.00")
        assert sample_order_item.subtotal == Decimal("299.00")

    def test_order_item_subtotal_calculation(self):
        """Test automatic subtotal calculation."""
        item = OrderItem(
            id="item-123",
            productId="prod-456",
            productName="Test Product",
            quantity=3,
            unitPrice=Decimal("100.00"),
            discount=Decimal("50.00"),
            subtotal=Decimal("250.00"),
            dateCreated="2025-12-30T10:00:00Z",
            dateLastUpdated="2025-12-30T10:00:00Z",
            lastUpdatedBy="system",
            active=True
        )

        # Subtotal = (quantity * unitPrice) - discount = (3 * 100) - 50 = 250
        assert item.subtotal == Decimal("250.00")

    def test_order_item_invalid_quantity(self):
        """Test OrderItem validation for invalid quantity."""
        with pytest.raises(ValidationError) as exc_info:
            OrderItem(
                id="item-123",
                productId="prod-456",
                productName="Test Product",
                quantity=0,  # Invalid: must be >= 1
                unitPrice=Decimal("100.00"),
                discount=Decimal("0.00"),
                subtotal=Decimal("100.00"),
                dateCreated="2025-12-30T10:00:00Z",
                dateLastUpdated="2025-12-30T10:00:00Z",
                lastUpdatedBy="system",
                active=True
            )

        assert "quantity" in str(exc_info.value)


class TestOrder:
    """Tests for Order model."""

    def test_order_valid(self, sample_order):
        """Test Order with valid data."""
        assert sample_order.id == "550e8400-e29b-41d4-a716-446655440000"
        assert sample_order.orderNumber == "ORD-2025-00001"
        assert sample_order.tenantId == "tenant-123"
        assert sample_order.customerEmail == "customer@example.com"
        assert sample_order.status == OrderStatus.PENDING
        assert sample_order.total == Decimal("299.00")

    def test_order_email_validation(self, sample_order_item, sample_billing_address):
        """Test email validation."""
        with pytest.raises(ValidationError) as exc_info:
            Order(
                id="order-123",
                orderNumber="ORD-001",
                tenantId="tenant-123",
                customerEmail="invalid-email",  # Invalid email
                items=[sample_order_item],
                subtotal=Decimal("100.00"),
                tax=Decimal("0.00"),
                shipping=Decimal("0.00"),
                total=Decimal("100.00"),
                currency="ZAR",
                status=OrderStatus.PENDING,
                billingAddress=sample_billing_address,
                dateCreated="2025-12-30T10:00:00Z",
                dateLastUpdated="2025-12-30T10:00:00Z",
                lastUpdatedBy="system",
                active=True
            )

        assert "email" in str(exc_info.value).lower()

    def test_order_email_normalization(self, sample_order):
        """Test email is normalized to lowercase."""
        order = sample_order.copy(deep=True)
        order.customerEmail = "User@Example.COM"

        # Re-validate
        validated_order = Order.parse_obj(order.dict())
        assert validated_order.customerEmail == "user@example.com"


class TestUpdateOrderRequest:
    """Tests for UpdateOrderRequest model."""

    def test_update_request_with_status(self):
        """Test UpdateOrderRequest with status only."""
        request = UpdateOrderRequest(status=OrderStatus.PAID)

        assert request.status == OrderStatus.PAID
        assert request.paymentDetails is None
        assert request.has_updates() is True

    def test_update_request_with_payment_details(self):
        """Test UpdateOrderRequest with payment details only."""
        payment = PaymentDetails(method="credit_card", transactionId="txn-123")
        request = UpdateOrderRequest(paymentDetails=payment)

        assert request.status is None
        assert request.paymentDetails is not None
        assert request.has_updates() is True

    def test_update_request_with_both(self):
        """Test UpdateOrderRequest with both status and payment details."""
        payment = PaymentDetails(method="credit_card", transactionId="txn-123")
        request = UpdateOrderRequest(status=OrderStatus.PAID, paymentDetails=payment)

        assert request.status == OrderStatus.PAID
        assert request.paymentDetails is not None
        assert request.has_updates() is True

    def test_update_request_empty(self):
        """Test UpdateOrderRequest with no updates."""
        request = UpdateOrderRequest()

        assert request.status is None
        assert request.paymentDetails is None
        assert request.has_updates() is False

    def test_update_request_from_json(self):
        """Test parsing UpdateOrderRequest from JSON."""
        json_data = {
            "status": "paid",
            "paymentDetails": {
                "method": "credit_card",
                "transactionId": "txn-abc123"
            }
        }

        request = UpdateOrderRequest.parse_obj(json_data)

        assert request.status == OrderStatus.PAID
        assert request.paymentDetails.method == "credit_card"
        assert request.paymentDetails.transactionId == "txn-abc123"
