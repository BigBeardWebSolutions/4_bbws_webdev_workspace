"""
Order Item model for Order Lambda service.
"""

from decimal import Decimal
from pydantic import BaseModel, Field, validator
from datetime import datetime


class OrderItem(BaseModel):
    """
    Order item model representing a line item in an order.

    Attributes:
        id: UUID (item ID)
        productId: Product reference
        productName: Product name (denormalized)
        quantity: Item quantity (minimum 1)
        unitPrice: Price per unit
        discount: Discount amount applied
        subtotal: Line subtotal (unitPrice × quantity - discount)
        dateCreated: ISO 8601 timestamp
        dateLastUpdated: ISO 8601 timestamp
        lastUpdatedBy: User identifier
        active: Soft delete flag
    """

    id: str = Field(..., description="UUID (item ID)")
    productId: str = Field(..., description="Product reference")
    productName: str = Field(..., description="Product name (denormalized)", min_length=1, max_length=255)
    quantity: int = Field(..., description="Item quantity", ge=1)
    unitPrice: float = Field(..., description="Price per unit", ge=0.0)
    discount: float = Field(default=0.0, description="Discount amount applied", ge=0.0)
    subtotal: float = Field(..., description="Line subtotal", ge=0.0)
    dateCreated: str = Field(..., description="ISO 8601 timestamp")
    dateLastUpdated: str = Field(..., description="ISO 8601 timestamp")
    lastUpdatedBy: str = Field(..., description="User identifier")
    active: bool = Field(default=True, description="Soft delete flag")

    @validator('dateCreated', 'dateLastUpdated')
    def validate_iso_date(cls, v):
        """Validate ISO 8601 date format."""
        try:
            datetime.fromisoformat(v.replace('Z', '+00:00'))
        except ValueError:
            raise ValueError(f'Invalid ISO 8601 date format: {v}')
        return v

    @validator('subtotal')
    def validate_subtotal(cls, v, values):
        """Validate subtotal calculation."""
        if 'unitPrice' in values and 'quantity' in values and 'discount' in values:
            expected_subtotal = (values['unitPrice'] * values['quantity']) - values['discount']
            if abs(v - expected_subtotal) > 0.01:  # Allow small floating point differences
                raise ValueError(f'Subtotal {v} does not match calculation: {expected_subtotal}')
        return v

    class Config:
        """Pydantic model configuration."""
        json_encoders = {
            datetime: lambda v: v.isoformat(),
            Decimal: lambda v: float(v)
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
