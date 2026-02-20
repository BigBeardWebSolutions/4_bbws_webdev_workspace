"""
Unit tests for Pydantic models.
"""

import pytest
from pydantic import ValidationError

from src.models.billing_address import BillingAddress
from src.models.campaign import Campaign
from src.models.order_item import OrderItem
from src.models.payment_details import PaymentDetails
from src.models.order import Order


class TestBillingAddress:
    """Test BillingAddress model."""

    def test_valid_billing_address(self, sample_billing_address):
        """Test creating valid billing address."""
        address = BillingAddress(**sample_billing_address)
        assert address.street == "123 Main Street"
        assert address.city == "Cape Town"
        assert address.country == "ZA"

    def test_country_code_validation(self):
        """Test country code must be uppercase."""
        with pytest.raises(ValidationError) as exc_info:
            BillingAddress(
                street="123 Main St",
                city="Cape Town",
                province="Western Cape",
                postalCode="8001",
                country="za"  # Lowercase should fail
            )
        assert "Country code must be uppercase" in str(exc_info.value)

    def test_missing_required_fields(self):
        """Test missing required fields raise validation error."""
        with pytest.raises(ValidationError):
            BillingAddress(street="123 Main St")


class TestCampaign:
    """Test Campaign model."""

    def test_valid_campaign(self, sample_campaign):
        """Test creating valid campaign."""
        campaign = Campaign(**sample_campaign)
        assert campaign.code == "SUMMER2025"
        assert campaign.discountPercentage == 20.0
        assert campaign.isValid is True

    def test_discount_percentage_range(self):
        """Test discount percentage must be 0-100."""
        sample = {
            "id": "camp_123",
            "code": "TEST",
            "description": "Test campaign",
            "discountPercentage": 150.0,  # Invalid
            "productId": "prod_123",
            "termsConditionsLink": "https://example.com/terms",
            "fromDate": "2025-06-01",
            "toDate": "2025-08-31",
            "isValid": True,
            "dateCreated": "2025-05-01T08:00:00Z",
            "dateLastUpdated": "2025-05-01T08:00:00Z",
            "lastUpdatedBy": "admin",
            "active": True
        }
        with pytest.raises(ValidationError) as exc_info:
            Campaign(**sample)
        assert "less than or equal to 100" in str(exc_info.value)

    def test_url_validation(self):
        """Test URL must have valid format."""
        sample = {
            "id": "camp_123",
            "code": "TEST",
            "description": "Test campaign",
            "discountPercentage": 20.0,
            "productId": "prod_123",
            "termsConditionsLink": "invalid-url",  # Invalid
            "fromDate": "2025-06-01",
            "toDate": "2025-08-31",
            "isValid": True,
            "dateCreated": "2025-05-01T08:00:00Z",
            "dateLastUpdated": "2025-05-01T08:00:00Z",
            "lastUpdatedBy": "admin",
            "active": True
        }
        with pytest.raises(ValidationError) as exc_info:
            Campaign(**sample)
        assert "valid URL" in str(exc_info.value)


class TestOrderItem:
    """Test OrderItem model."""

    def test_valid_order_item(self, sample_cart_item):
        """Test creating valid order item."""
        item = OrderItem(**sample_cart_item)
        assert item.productName == "WordPress Professional Plan"
        assert item.quantity == 1
        assert item.unitPrice == 299.99
        assert item.subtotal == 239.99

    def test_quantity_minimum(self):
        """Test quantity must be at least 1."""
        sample = {
            "id": "item_123",
            "productId": "prod_123",
            "productName": "Test Product",
            "quantity": 0,  # Invalid
            "unitPrice": 100.0,
            "discount": 0.0,
            "subtotal": 100.0,
            "dateCreated": "2025-12-30T10:00:00Z",
            "dateLastUpdated": "2025-12-30T10:00:00Z",
            "lastUpdatedBy": "system",
            "active": True
        }
        with pytest.raises(ValidationError) as exc_info:
            OrderItem(**sample)
        assert "greater than or equal to 1" in str(exc_info.value)

    def test_subtotal_validation(self):
        """Test subtotal must match calculation."""
        sample = {
            "id": "item_123",
            "productId": "prod_123",
            "productName": "Test Product",
            "quantity": 2,
            "unitPrice": 100.0,
            "discount": 20.0,
            "subtotal": 150.0,  # Should be 180.0 (2 * 100 - 20)
            "dateCreated": "2025-12-30T10:00:00Z",
            "dateLastUpdated": "2025-12-30T10:00:00Z",
            "lastUpdatedBy": "system",
            "active": True
        }
        with pytest.raises(ValidationError) as exc_info:
            OrderItem(**sample)
        assert "does not match calculation" in str(exc_info.value)


class TestPaymentDetails:
    """Test PaymentDetails model."""

    def test_valid_payment_details(self):
        """Test creating valid payment details."""
        payment = PaymentDetails(
            paymentId="pay_123",
            payfastPaymentId="pf_456",
            paidAt="2025-12-30T12:00:00Z"
        )
        assert payment.paymentId == "pay_123"
        assert payment.payfastPaymentId == "pf_456"

    def test_optional_fields(self):
        """Test optional fields can be None."""
        payment = PaymentDetails(paymentId="pay_123")
        assert payment.payfastPaymentId is None
        assert payment.paidAt is None


class TestOrder:
    """Test Order model."""

    def test_valid_order(self, sample_order_data):
        """Test creating valid order."""
        order = Order(**sample_order_data)
        assert order.orderNumber == "ORD-20251230-00001"
        assert order.status == "PENDING_PAYMENT"
        assert len(order.items) == 1
        assert order.total == 275.98

    def test_email_validation(self, sample_order_data):
        """Test email validation."""
        sample_order_data['customerEmail'] = "invalid-email"
        with pytest.raises(ValidationError) as exc_info:
            Order(**sample_order_data)
        assert "Invalid email format" in str(exc_info.value)

    def test_currency_validation(self, sample_order_data):
        """Test currency must be uppercase."""
        sample_order_data['currency'] = "zar"  # Lowercase
        with pytest.raises(ValidationError) as exc_info:
            Order(**sample_order_data)
        assert "Currency code must be uppercase" in str(exc_info.value)

    def test_total_validation(self, sample_order_data):
        """Test total must match subtotal + tax."""
        sample_order_data['total'] = 500.0  # Incorrect total
        with pytest.raises(ValidationError) as exc_info:
            Order(**sample_order_data)
        assert "does not match subtotal + tax" in str(exc_info.value)

    def test_subtotal_validation(self, sample_order_data):
        """Test subtotal must match sum of items."""
        sample_order_data['subtotal'] = 500.0  # Incorrect subtotal
        with pytest.raises(ValidationError) as exc_info:
            Order(**sample_order_data)
        assert "does not match sum of items" in str(exc_info.value)

    def test_status_enum_validation(self, sample_order_data):
        """Test status must be valid enum value."""
        sample_order_data['status'] = "INVALID_STATUS"
        with pytest.raises(ValidationError) as exc_info:
            Order(**sample_order_data)
        assert "string does not match regex" in str(exc_info.value)

    def test_to_dynamodb_item(self, sample_order_data):
        """Test converting Order to DynamoDB item format."""
        order = Order(**sample_order_data)
        item = order.to_dynamodb_item()

        # Check PK/SK structure
        assert item['PK'] == f"TENANT#{order.tenantId}"
        assert item['SK'] == f"ORDER#{order.id}"
        assert item['entityType'] == 'ORDER'

        # Check GSI keys
        assert item['GSI1_PK'] == f"TENANT#{order.tenantId}"
        assert item['GSI1_SK'] == f"{order.dateCreated}#{order.id}"
        assert item['GSI2_PK'] == f"ORDER#{order.id}"
        assert item['GSI2_SK'] == 'METADATA'

        # Check attributes
        assert item['orderNumber'] == order.orderNumber
        assert item['customerEmail'] == order.customerEmail
        assert item['total'] == order.total
        assert item['status'] == order.status

    def test_items_minimum(self, sample_order_data):
        """Test order must have at least one item."""
        sample_order_data['items'] = []
        with pytest.raises(ValidationError) as exc_info:
            Order(**sample_order_data)
        assert "at least 1 item" in str(exc_info.value)
