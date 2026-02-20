"""
OrderItem Pydantic model for Order Lambda.

This model represents a line item in an order with the Activatable Entity Pattern.
"""
from pydantic import BaseModel, Field
from decimal import Decimal
from datetime import datetime
from typing import Optional


class OrderItem(BaseModel):
    """
    Order line item with Activatable Entity Pattern.

    Represents a single product/service in an order with pricing and quantity.
    """

    id: str = Field(..., description="Unique item identifier (UUID)")
    productId: str = Field(..., description="Product reference (UUID)")
    productName: str = Field(..., description="Product name (denormalized)")
    quantity: int = Field(..., ge=1, description="Item quantity (minimum 1)")
    unitPrice: Decimal = Field(..., description="Price per unit")
    discount: Decimal = Field(default=Decimal("0.0"), description="Discount amount applied")
    subtotal: Decimal = Field(..., description="Line subtotal (unitPrice × quantity - discount)")
    dateCreated: str = Field(..., description="ISO 8601 timestamp when item was created")
    dateLastUpdated: str = Field(..., description="ISO 8601 timestamp when item was last updated")
    lastUpdatedBy: str = Field(..., description="User/system identifier who last updated")
    active: bool = Field(default=True, description="Soft delete flag (true = active, false = deleted)")

    class Config:
        """Pydantic configuration."""
        json_encoders = {
            Decimal: lambda v: float(v),
            datetime: lambda v: v.isoformat()
        }
        schema_extra = {
            "example": {
                "id": "item_cc0e8400-e29b-41d4-a716-446655440007",
                "productId": "prod_550e8400-e29b-41d4-a716-446655440000",
                "productName": "WordPress Professional Plan",
                "quantity": 1,
                "unitPrice": 299.99,
                "discount": 60.00,
                "subtotal": 239.99,
                "dateCreated": "2025-12-19T10:30:00Z",
                "dateLastUpdated": "2025-12-19T10:30:00Z",
                "lastUpdatedBy": "system",
                "active": True
            }
        }
