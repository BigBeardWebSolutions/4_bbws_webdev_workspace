"""Request models for create_order Lambda function.

This module defines Pydantic v1.10.18 models for validating incoming order creation
requests from API Gateway.
"""

from pydantic import BaseModel, Field, validator
from typing import List, Optional


class OrderItemRequest(BaseModel):
    """Order item in create request.

    Attributes:
        productId: Product identifier (UUID)
        productName: Human-readable product name
        quantity: Quantity ordered (minimum 1)
        unitPrice: Price per unit (non-negative)
    """

    productId: str = Field(..., description="Product identifier")
    productName: str = Field(..., description="Product name")
    quantity: int = Field(..., ge=1, description="Quantity (min 1)")
    unitPrice: float = Field(..., ge=0, description="Unit price")

    @validator('quantity')
    def validate_quantity(cls, v: int) -> int:
        """Validate quantity is at least 1.

        Args:
            v: Quantity value to validate

        Returns:
            Validated quantity

        Raises:
            ValueError: If quantity is less than 1
        """
        if v < 1:
            raise ValueError("Quantity must be at least 1")
        return v

    @validator('unitPrice')
    def validate_unit_price(cls, v: float) -> float:
        """Validate unit price is non-negative.

        Args:
            v: Unit price value to validate

        Returns:
            Validated unit price

        Raises:
            ValueError: If unit price is negative
        """
        if v < 0:
            raise ValueError("Unit price must be non-negative")
        return v


class BillingAddressRequest(BaseModel):
    """Billing address in create request.

    Attributes:
        fullName: Full name of billing contact
        addressLine1: Primary address line
        addressLine2: Secondary address line (optional)
        city: City name
        stateProvince: State or province
        postalCode: Postal/ZIP code
        country: Country code (ISO 3166-1 alpha-2)
    """

    fullName: str = Field(..., min_length=1, description="Full name")
    addressLine1: str = Field(..., min_length=1, description="Address line 1")
    addressLine2: Optional[str] = Field(None, description="Address line 2")
    city: str = Field(..., min_length=1, description="City")
    stateProvince: str = Field(..., min_length=1, description="State/Province")
    postalCode: str = Field(..., min_length=1, description="Postal code")
    country: str = Field(..., min_length=2, max_length=2, description="Country code")

    @validator('country')
    def validate_country_code(cls, v: str) -> str:
        """Validate country code is uppercase ISO 3166-1 alpha-2.

        Args:
            v: Country code to validate

        Returns:
            Uppercase country code
        """
        return v.upper()


class CreateOrderRequest(BaseModel):
    """Request model for creating a new order.

    This model validates the incoming request body from API Gateway.
    Required fields ensure we have minimum information to process an order.

    Attributes:
        customerEmail: Customer email address
        items: List of order items (at least one required)
        billingAddress: Billing address details
        campaignCode: Optional campaign/promo code
    """

    customerEmail: str = Field(..., description="Customer email address")
    items: List[OrderItemRequest] = Field(..., min_items=1, description="Order items")
    billingAddress: BillingAddressRequest = Field(..., description="Billing address")
    campaignCode: Optional[str] = Field(None, description="Campaign code")

    @validator('customerEmail')
    def validate_email(cls, v: str) -> str:
        """Validate email address format.

        Performs basic email validation checking for @ and . characters.
        More comprehensive validation can be added if needed.

        Args:
            v: Email address to validate

        Returns:
            Lowercase email address

        Raises:
            ValueError: If email format is invalid
        """
        if '@' not in v or '.' not in v:
            raise ValueError("Invalid email address")
        return v.lower()

    @validator('items')
    def validate_items(cls, v: List[OrderItemRequest]) -> List[OrderItemRequest]:
        """Validate at least one item is present.

        Args:
            v: List of order items

        Returns:
            Validated items list

        Raises:
            ValueError: If items list is empty
        """
        if not v:
            raise ValueError("At least one item is required")
        return v

    class Config:
        """Pydantic model configuration."""
        schema_extra = {
            "example": {
                "customerEmail": "customer@example.com",
                "items": [
                    {
                        "productId": "prod-123",
                        "productName": "WordPress Professional Plan",
                        "quantity": 1,
                        "unitPrice": 299.99
                    }
                ],
                "billingAddress": {
                    "fullName": "John Doe",
                    "addressLine1": "123 Main St",
                    "city": "Cape Town",
                    "stateProvince": "Western Cape",
                    "postalCode": "8001",
                    "country": "ZA"
                },
                "campaignCode": "SUMMER2025"
            }
        }
