"""Unit tests for Pydantic models.

This module tests the validation logic in request and response models.
"""

import pytest
from pydantic import ValidationError
from src.models.requests import (
    OrderItemRequest,
    BillingAddressRequest,
    CreateOrderRequest
)
from src.models.responses import CreateOrderResponse


class TestOrderItemRequest:
    """Test cases for OrderItemRequest model."""

    def test_valid_order_item(self, valid_order_item):
        """Test creating a valid order item."""
        item = OrderItemRequest(**valid_order_item)
        assert item.productId == 'prod-123'
        assert item.productName == 'WordPress Professional Plan'
        assert item.quantity == 2
        assert item.unitPrice == 50.00

    def test_quantity_must_be_positive(self):
        """Test that quantity must be at least 1."""
        with pytest.raises(ValidationError) as exc_info:
            OrderItemRequest(
                productId='prod-123',
                productName='Test Product',
                quantity=0,
                unitPrice=10.00
            )
        assert 'quantity' in str(exc_info.value)

    def test_quantity_cannot_be_negative(self):
        """Test that quantity cannot be negative."""
        with pytest.raises(ValidationError) as exc_info:
            OrderItemRequest(
                productId='prod-123',
                productName='Test Product',
                quantity=-1,
                unitPrice=10.00
            )
        assert 'quantity' in str(exc_info.value)

    def test_unit_price_cannot_be_negative(self):
        """Test that unit price cannot be negative."""
        with pytest.raises(ValidationError) as exc_info:
            OrderItemRequest(
                productId='prod-123',
                productName='Test Product',
                quantity=1,
                unitPrice=-10.00
            )
        assert 'unitPrice' in str(exc_info.value)

    def test_unit_price_can_be_zero(self):
        """Test that unit price can be zero (free items)."""
        item = OrderItemRequest(
            productId='prod-free',
            productName='Free Item',
            quantity=1,
            unitPrice=0.00
        )
        assert item.unitPrice == 0.00

    def test_missing_required_fields(self):
        """Test that all required fields must be provided."""
        with pytest.raises(ValidationError):
            OrderItemRequest(productId='prod-123')


class TestBillingAddressRequest:
    """Test cases for BillingAddressRequest model."""

    def test_valid_billing_address(self, valid_billing_address):
        """Test creating a valid billing address."""
        address = BillingAddressRequest(**valid_billing_address)
        assert address.fullName == 'John Doe'
        assert address.addressLine1 == '123 Main St'
        assert address.city == 'Cape Town'
        assert address.stateProvince == 'Western Cape'
        assert address.postalCode == '8001'
        assert address.country == 'ZA'

    def test_country_code_is_uppercase(self):
        """Test that country code is converted to uppercase."""
        address = BillingAddressRequest(
            fullName='John Doe',
            addressLine1='123 Main St',
            city='Cape Town',
            stateProvince='Western Cape',
            postalCode='8001',
            country='za'  # lowercase
        )
        assert address.country == 'ZA'

    def test_country_code_must_be_two_chars(self):
        """Test that country code must be exactly 2 characters."""
        with pytest.raises(ValidationError) as exc_info:
            BillingAddressRequest(
                fullName='John Doe',
                addressLine1='123 Main St',
                city='Cape Town',
                stateProvince='Western Cape',
                postalCode='8001',
                country='USA'  # 3 characters
            )
        assert 'country' in str(exc_info.value)

    def test_address_line_2_is_optional(self):
        """Test that addressLine2 is optional."""
        address = BillingAddressRequest(
            fullName='John Doe',
            addressLine1='123 Main St',
            city='Cape Town',
            stateProvince='Western Cape',
            postalCode='8001',
            country='ZA'
        )
        assert address.addressLine2 is None

    def test_empty_strings_not_allowed(self):
        """Test that empty strings are not allowed for required fields."""
        with pytest.raises(ValidationError):
            BillingAddressRequest(
                fullName='',
                addressLine1='123 Main St',
                city='Cape Town',
                stateProvince='Western Cape',
                postalCode='8001',
                country='ZA'
            )


class TestCreateOrderRequest:
    """Test cases for CreateOrderRequest model."""

    def test_valid_create_order_request(self, valid_create_order_request):
        """Test creating a valid order request."""
        request = CreateOrderRequest(**valid_create_order_request)
        assert request.customerEmail == 'customer@example.com'
        assert len(request.items) == 1
        assert request.items[0].productId == 'prod-123'
        assert request.billingAddress.fullName == 'John Doe'
        assert request.campaignCode == 'SUMMER2025'

    def test_email_is_lowercased(self):
        """Test that email is converted to lowercase."""
        data = {
            'customerEmail': 'CUSTOMER@EXAMPLE.COM',
            'items': [{
                'productId': 'prod-123',
                'productName': 'Test',
                'quantity': 1,
                'unitPrice': 10.00
            }],
            'billingAddress': {
                'fullName': 'John Doe',
                'addressLine1': '123 St',
                'city': 'City',
                'stateProvince': 'State',
                'postalCode': '12345',
                'country': 'ZA'
            }
        }
        request = CreateOrderRequest(**data)
        assert request.customerEmail == 'customer@example.com'

    def test_invalid_email_format(self):
        """Test that invalid email format is rejected."""
        data = {
            'customerEmail': 'not-an-email',
            'items': [{
                'productId': 'prod-123',
                'productName': 'Test',
                'quantity': 1,
                'unitPrice': 10.00
            }],
            'billingAddress': {
                'fullName': 'John Doe',
                'addressLine1': '123 St',
                'city': 'City',
                'stateProvince': 'State',
                'postalCode': '12345',
                'country': 'ZA'
            }
        }
        with pytest.raises(ValidationError) as exc_info:
            CreateOrderRequest(**data)
        assert 'email' in str(exc_info.value).lower()

    def test_items_must_not_be_empty(self):
        """Test that items list cannot be empty."""
        data = {
            'customerEmail': 'customer@example.com',
            'items': [],
            'billingAddress': {
                'fullName': 'John Doe',
                'addressLine1': '123 St',
                'city': 'City',
                'stateProvince': 'State',
                'postalCode': '12345',
                'country': 'ZA'
            }
        }
        with pytest.raises(ValidationError) as exc_info:
            CreateOrderRequest(**data)
        assert 'items' in str(exc_info.value).lower()

    def test_campaign_code_is_optional(self, valid_create_order_request):
        """Test that campaignCode is optional."""
        del valid_create_order_request['campaignCode']
        request = CreateOrderRequest(**valid_create_order_request)
        assert request.campaignCode is None

    def test_multiple_items_allowed(self, valid_billing_address):
        """Test that multiple items can be included."""
        data = {
            'customerEmail': 'customer@example.com',
            'items': [
                {
                    'productId': 'prod-1',
                    'productName': 'Product 1',
                    'quantity': 1,
                    'unitPrice': 10.00
                },
                {
                    'productId': 'prod-2',
                    'productName': 'Product 2',
                    'quantity': 2,
                    'unitPrice': 20.00
                }
            ],
            'billingAddress': valid_billing_address
        }
        request = CreateOrderRequest(**data)
        assert len(request.items) == 2


class TestCreateOrderResponse:
    """Test cases for CreateOrderResponse model."""

    def test_valid_response(self):
        """Test creating a valid response."""
        response = CreateOrderResponse(
            orderId='550e8400-e29b-41d4-a716-446655440000',
            orderNumber=None,
            status='pending',
            message='Order accepted for processing'
        )
        assert response.orderId == '550e8400-e29b-41d4-a716-446655440000'
        assert response.orderNumber is None
        assert response.status == 'pending'
        assert response.message == 'Order accepted for processing'

    def test_default_values(self):
        """Test default values for status and message."""
        response = CreateOrderResponse(
            orderId='550e8400-e29b-41d4-a716-446655440000'
        )
        assert response.status == 'pending'
        assert response.message == 'Order accepted for processing'

    def test_order_number_can_be_null(self):
        """Test that orderNumber can be None."""
        response = CreateOrderResponse(
            orderId='550e8400-e29b-41d4-a716-446655440000',
            orderNumber=None
        )
        assert response.orderNumber is None

    def test_response_dict_format(self):
        """Test response serialization to dict."""
        response = CreateOrderResponse(
            orderId='550e8400-e29b-41d4-a716-446655440000',
            orderNumber=None,
            status='pending',
            message='Order accepted for processing'
        )
        response_dict = response.dict()
        assert 'orderId' in response_dict
        assert 'orderNumber' in response_dict
        assert 'status' in response_dict
        assert 'message' in response_dict
