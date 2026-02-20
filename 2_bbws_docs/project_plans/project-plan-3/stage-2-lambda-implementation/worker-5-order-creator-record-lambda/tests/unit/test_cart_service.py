"""
Unit tests for CartService.
"""

import pytest

from src.services.cart_service import CartService


class TestCartService:
    """Test CartService."""

    @pytest.fixture
    def cart_service(self):
        """Create CartService instance."""
        return CartService()

    def test_get_cart_mocked(self, cart_service, sample_cart_id, sample_tenant_id):
        """Test getting cart returns mocked data."""
        cart = cart_service.get_cart(sample_cart_id, sample_tenant_id)

        assert cart['cartId'] == sample_cart_id
        assert cart['tenantId'] == sample_tenant_id
        assert 'items' in cart
        assert len(cart['items']) > 0
        assert 'subtotal' in cart
        assert 'tax' in cart
        assert 'total' in cart
        assert 'currency' in cart

    def test_validate_cart_valid(self, cart_service, sample_cart_data):
        """Test validating valid cart data."""
        result = cart_service.validate_cart(sample_cart_data)
        assert result is True

    def test_validate_cart_missing_fields(self, cart_service):
        """Test validating cart with missing fields."""
        invalid_cart = {'cartId': 'cart-123'}
        result = cart_service.validate_cart(invalid_cart)
        assert result is False

    def test_validate_cart_empty_items(self, cart_service, sample_cart_data):
        """Test validating cart with empty items."""
        sample_cart_data['items'] = []
        result = cart_service.validate_cart(sample_cart_data)
        assert result is False

    def test_calculate_totals(self, cart_service):
        """Test calculating cart totals."""
        items = [
            {'subtotal': 100.0},
            {'subtotal': 50.0}
        ]

        totals = cart_service.calculate_totals(items, tax_rate=0.15)

        assert totals['subtotal'] == 150.0
        assert totals['tax'] == 22.5  # 15% of 150
        assert totals['total'] == 172.5

    def test_calculate_totals_custom_tax_rate(self, cart_service):
        """Test calculating totals with custom tax rate."""
        items = [{'subtotal': 100.0}]

        totals = cart_service.calculate_totals(items, tax_rate=0.20)

        assert totals['subtotal'] == 100.0
        assert totals['tax'] == 20.0
        assert totals['total'] == 120.0
