"""
Unit tests for Pydantic models.

Tests data validation, serialization, and business logic in models.
"""

import pytest
from datetime import datetime
from pydantic import ValidationError
from src.models.order import Order
from src.models.order_item import OrderItem
from src.models.billing_address import BillingAddress
from src.models.campaign import Campaign
from src.models.payment_details import PaymentDetails


class TestBillingAddress:
    """Tests for BillingAddress model."""

    def test_valid_billing_address(self, sample_billing_address):
        """Test creating valid billing address."""
        assert sample_billing_address.fullName == "John Doe"
        assert sample_billing_address.city == "Cape Town"
        assert sample_billing_address.country == "ZA"

    def test_billing_address_minimal_fields(self):
        """Test billing address with minimal required fields."""
        addr = BillingAddress(
            fullName="Jane Smith",
            addressLine1="456 Oak Ave",
            city="Johannesburg",
            stateProvince="Gauteng",
            postalCode="2000",
            country="ZA"
        )
        assert addr.addressLine2 is None
        assert addr.phoneNumber is None

    def test_billing_address_invalid_country_code(self):
        """Test validation fails for invalid country code."""
        with pytest.raises(ValidationError) as exc_info:
            BillingAddress(
                fullName="Test User",
                addressLine1="123 Street",
                city="City",
                stateProvince="State",
                postalCode="12345",
                country="USA"  # Should be 2 chars
            )
        assert "country" in str(exc_info.value)

    def test_billing_address_missing_required_field(self):
        """Test validation fails when required field missing."""
        with pytest.raises(ValidationError) as exc_info:
            BillingAddress(
                fullName="Test User",
                # addressLine1 missing
                city="City",
                stateProvince="State",
                postalCode="12345",
                country="ZA"
            )
        assert "addressLine1" in str(exc_info.value)


class TestOrderItem:
    """Tests for OrderItem model."""

    def test_valid_order_item(self, sample_order_item):
        """Test creating valid order item."""
        assert sample_order_item.productName == "Premium WordPress Theme"
        assert sample_order_item.quantity == 1
        assert sample_order_item.total == 113.85

    def test_order_item_calculations(self):
        """Test order item price calculations."""
        item = OrderItem(
            productId="prod-456",
            productName="Test Product",
            productSku="TEST-001",
            quantity=2,
            unitPrice=50.00,
            currency="ZAR",
            subtotal=100.00,
            taxRate=0.15,
            taxAmount=15.00,
            total=115.00
        )
        assert item.subtotal == item.quantity * item.unitPrice
        assert item.total == item.subtotal + item.taxAmount

    def test_order_item_invalid_quantity(self):
        """Test validation fails for invalid quantity."""
        with pytest.raises(ValidationError) as exc_info:
            OrderItem(
                productId="prod-789",
                productName="Test Product",
                productSku="TEST-002",
                quantity=0,  # Must be >= 1
                unitPrice=50.00,
                currency="ZAR",
                subtotal=0.00,
                total=0.00
            )
        assert "quantity" in str(exc_info.value)


class TestCampaign:
    """Tests for Campaign model."""

    def test_valid_campaign(self, sample_campaign):
        """Test creating valid campaign."""
        assert sample_campaign.code == "SUMMER2025"
        assert sample_campaign.discountType == "percentage"
        assert sample_campaign.discountValue == 15.0

    def test_campaign_json_encoding(self, sample_campaign):
        """Test campaign JSON serialization."""
        campaign_dict = sample_campaign.dict()
        assert isinstance(campaign_dict['startDate'], datetime)

        # Test JSON encoding with datetime
        campaign_json = sample_campaign.json()
        assert "2025-06-01" in campaign_json


class TestPaymentDetails:
    """Tests for PaymentDetails model."""

    def test_valid_payment_details(self, sample_payment_details):
        """Test creating valid payment details."""
        assert sample_payment_details.method == "credit_card"
        assert sample_payment_details.status == "completed"
        assert sample_payment_details.amount == 250.00

    def test_payment_details_pending_status(self):
        """Test payment details with default pending status."""
        payment = PaymentDetails(
            method="bank_transfer",
            amount=100.00,
            currency="ZAR"
        )
        assert payment.status == "pending"
        assert payment.transactionId is None


class TestOrder:
    """Tests for Order model."""

    def test_valid_order(self, sample_order):
        """Test creating valid order."""
        assert sample_order.orderNumber == "ORD-2025-00001"
        assert sample_order.tenantId == "tenant-123"
        assert sample_order.total == 113.85
        assert len(sample_order.items) == 1

    def test_order_number_validation(self, sample_order):
        """Test order number format validation."""
        # Valid format
        order = sample_order.copy(deep=True)
        order.orderNumber = "ORD-2025-12345"
        assert order.orderNumber == "ORD-2025-12345"

        # Invalid format
        with pytest.raises(ValidationError) as exc_info:
            order_data = sample_order.dict()
            order_data['orderNumber'] = "ORDER-123"
            Order(**order_data)
        assert "orderNumber" in str(exc_info.value)

    def test_email_validation(self, sample_order):
        """Test customer email validation."""
        # Valid email
        assert sample_order.customerEmail == "customer@example.com"

        # Invalid email
        with pytest.raises(ValidationError) as exc_info:
            order_data = sample_order.dict()
            order_data['customerEmail'] = "invalid-email"
            Order(**order_data)
        assert "customerEmail" in str(exc_info.value)

    def test_status_validation(self, sample_order):
        """Test order status validation."""
        # Valid statuses
        valid_statuses = ['pending', 'processing', 'paid', 'shipped', 'delivered', 'cancelled', 'refunded']
        for status in valid_statuses:
            order = sample_order.copy(deep=True)
            order.status = status
            assert order.status == status

        # Invalid status
        with pytest.raises(ValidationError) as exc_info:
            order_data = sample_order.dict()
            order_data['status'] = "invalid_status"
            Order(**order_data)
        assert "status" in str(exc_info.value)

    def test_currency_validation(self, sample_order):
        """Test currency code validation."""
        # Valid uppercase currency
        assert sample_order.currency == "ZAR"

        # Invalid lowercase currency
        with pytest.raises(ValidationError) as exc_info:
            order_data = sample_order.dict()
            order_data['currency'] = "zar"
            Order(**order_data)
        assert "currency" in str(exc_info.value)

    def test_total_calculation_validation(self, sample_order):
        """Test total calculation validation."""
        # Valid total
        order = sample_order.copy(deep=True)
        order.subtotal = 100.00
        order.taxAmount = 15.00
        order.shippingAmount = 10.00
        order.discountAmount = 5.00
        order.total = 120.00  # 100 + 15 + 10 - 5
        # Should not raise error

        # Invalid total
        with pytest.raises(ValidationError) as exc_info:
            order_data = sample_order.dict()
            order_data['subtotal'] = 100.00
            order_data['taxAmount'] = 15.00
            order_data['shippingAmount'] = 10.00
            order_data['discountAmount'] = 5.00
            order_data['total'] = 999.99  # Incorrect
            Order(**order_data)
        assert "total" in str(exc_info.value).lower()

    def test_order_with_optional_fields(self, sample_order, sample_campaign, sample_payment_details):
        """Test order with all optional fields."""
        order = sample_order.copy(deep=True)
        order.campaign = sample_campaign
        order.paymentDetails = sample_payment_details
        order.pdfUrl = "https://s3.amazonaws.com/bucket/order.pdf"
        order.notes = "Special delivery instructions"
        order.metadata = {"source": "web", "referrer": "google"}

        assert order.campaign.code == "SUMMER2025"
        assert order.paymentDetails.method == "credit_card"
        assert order.pdfUrl is not None
        assert order.notes is not None
        assert order.metadata["source"] == "web"

    def test_order_json_serialization(self, sample_order):
        """Test order JSON serialization."""
        order_json = sample_order.json()
        assert "ORD-2025-00001" in order_json
        assert "tenant-123" in order_json
        assert "2025-12-30" in order_json  # Date formatted as ISO

    def test_order_activatable_pattern(self, sample_order):
        """Test Activatable Entity Pattern (soft delete)."""
        assert sample_order.isActive is True

        # Soft delete
        order = sample_order.copy(deep=True)
        order.isActive = False
        assert order.isActive is False
