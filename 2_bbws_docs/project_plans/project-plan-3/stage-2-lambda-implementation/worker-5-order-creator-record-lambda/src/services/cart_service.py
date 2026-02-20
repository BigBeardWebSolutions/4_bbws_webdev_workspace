"""
Cart Service for fetching cart data.

This is a MOCKED implementation until Cart Lambda API contract is defined.
"""

import logging
from typing import Dict, Any, List
from datetime import datetime
import uuid

logger = logging.getLogger()


class CartService:
    """
    Service for interacting with Cart Lambda API.

    This is currently a MOCKED implementation. The actual implementation will use
    HTTP requests to Cart Lambda API endpoint once the contract is defined.

    Expected Cart Lambda API Contract (to be implemented):
    - Endpoint: GET /v1.0/carts/{cartId}
    - Response: {
        "cartId": "string",
        "tenantId": "string",
        "items": [
          {
            "id": "string",
            "productId": "string",
            "productName": "string",
            "quantity": number,
            "unitPrice": number,
            "discount": number,
            "subtotal": number
          }
        ],
        "subtotal": number,
        "tax": number,
        "total": number,
        "currency": "string"
      }
    """

    def __init__(self, cart_api_url: str = None):
        """
        Initialize CartService.

        Args:
            cart_api_url: Cart Lambda API URL (optional, for future implementation)
        """
        self.cart_api_url = cart_api_url or "https://api-dev.bbws.io/v1.0/cart"
        logger.warning(
            f"CartService initialized with MOCKED implementation. "
            f"API URL: {self.cart_api_url}"
        )

    def get_cart(self, cart_id: str, tenant_id: str) -> Dict[str, Any]:
        """
        Fetch cart data by cart ID.

        CURRENT IMPLEMENTATION: Returns mocked cart data.
        FUTURE IMPLEMENTATION: Will make HTTP request to Cart Lambda API.

        Args:
            cart_id: Cart identifier
            tenant_id: Tenant identifier

        Returns:
            Cart data dictionary with items, totals, etc.

        Raises:
            ValueError: If cart not found or invalid
        """
        logger.info(f"Fetching cart: {cart_id} for tenant: {tenant_id} (MOCKED)")

        # MOCKED RESPONSE
        # TODO: Replace with actual HTTP request to Cart Lambda API
        mock_cart = {
            "cartId": cart_id,
            "tenantId": tenant_id,
            "items": [
                {
                    "id": f"item_{uuid.uuid4()}",
                    "productId": f"prod_{uuid.uuid4()}",
                    "productName": "WordPress Professional Plan",
                    "quantity": 1,
                    "unitPrice": 299.99,
                    "discount": 60.00,
                    "subtotal": 239.99,
                    "dateCreated": datetime.utcnow().isoformat() + "Z",
                    "dateLastUpdated": datetime.utcnow().isoformat() + "Z",
                    "lastUpdatedBy": "system",
                    "active": True
                }
            ],
            "subtotal": 239.99,
            "tax": 35.99,
            "total": 275.98,
            "currency": "ZAR"
        }

        logger.info(f"Cart fetched (MOCKED): {cart_id} with {len(mock_cart['items'])} items")
        return mock_cart

    def validate_cart(self, cart_data: Dict[str, Any]) -> bool:
        """
        Validate cart data structure.

        Args:
            cart_data: Cart data dictionary

        Returns:
            True if valid, False otherwise
        """
        required_fields = ['cartId', 'tenantId', 'items', 'subtotal', 'tax', 'total', 'currency']

        for field in required_fields:
            if field not in cart_data:
                logger.error(f"Missing required field in cart data: {field}")
                return False

        if not isinstance(cart_data['items'], list) or len(cart_data['items']) == 0:
            logger.error("Cart must have at least one item")
            return False

        return True

    def calculate_totals(self, items: List[Dict[str, Any]], tax_rate: float = 0.15) -> Dict[str, float]:
        """
        Calculate cart totals from items.

        Args:
            items: List of cart items
            tax_rate: Tax rate (default 15% for South Africa VAT)

        Returns:
            Dictionary with subtotal, tax, and total
        """
        subtotal = sum(item.get('subtotal', 0.0) for item in items)
        tax = round(subtotal * tax_rate, 2)
        total = round(subtotal + tax, 2)

        return {
            'subtotal': subtotal,
            'tax': tax,
            'total': total
        }
