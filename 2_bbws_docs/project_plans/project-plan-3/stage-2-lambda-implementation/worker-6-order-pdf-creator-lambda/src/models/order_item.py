"""
OrderItem model for Order Lambda.

Represents individual line items within an order.
"""

from typing import Optional
from pydantic import BaseModel, Field


class OrderItem(BaseModel):
    """
    Individual line item within an order.

    Attributes:
        productId: Product identifier
        productName: Product name (denormalized for historical accuracy)
        productSku: Product SKU code
        quantity: Quantity ordered
        unitPrice: Price per unit
        currency: Currency code (ISO 4217)
        subtotal: Line item subtotal (quantity * unitPrice)
        taxRate: Tax rate applied (as decimal, e.g., 0.15 for 15%)
        taxAmount: Tax amount for this line item
        total: Line item total (subtotal + taxAmount)
        imageUrl: Product image URL (optional)
        description: Product description (optional)
    """

    productId: str = Field(..., description="Product identifier")
    productName: str = Field(..., description="Product name", min_length=1, max_length=255)
    productSku: str = Field(..., description="Product SKU", min_length=1, max_length=100)
    quantity: int = Field(..., description="Quantity ordered", ge=1)
    unitPrice: float = Field(..., description="Price per unit", ge=0)
    currency: str = Field(..., description="Currency code (ISO 4217)", min_length=3, max_length=3)
    subtotal: float = Field(..., description="Line item subtotal", ge=0)
    taxRate: float = Field(default=0.0, description="Tax rate (decimal)", ge=0, le=1)
    taxAmount: float = Field(default=0.0, description="Tax amount", ge=0)
    total: float = Field(..., description="Line item total", ge=0)
    imageUrl: Optional[str] = Field(None, description="Product image URL", max_length=500)
    description: Optional[str] = Field(None, description="Product description", max_length=1000)

    class Config:
        """Pydantic configuration."""
        schema_extra = {
            "example": {
                "productId": "prod-123",
                "productName": "Premium WordPress Theme",
                "productSku": "WP-THEME-001",
                "quantity": 1,
                "unitPrice": 99.00,
                "currency": "ZAR",
                "subtotal": 99.00,
                "taxRate": 0.15,
                "taxAmount": 14.85,
                "total": 113.85,
                "imageUrl": "https://example.com/images/theme.jpg",
                "description": "Professional WordPress theme with responsive design"
            }
        }
