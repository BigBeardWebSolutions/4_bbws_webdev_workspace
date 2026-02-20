"""Order Item Pydantic Model."""

from typing import Optional
from pydantic import BaseModel, Field
from .campaign import Campaign


class OrderItem(BaseModel):
    """Individual item in an order."""

    item_id: str = Field(..., alias="itemId", description="Unique item ID")
    campaign: Campaign = Field(..., description="Campaign details (denormalized)")
    quantity: int = Field(..., ge=1, description="Quantity ordered")
    unit_price: float = Field(..., alias="unitPrice", ge=0, description="Price per unit")
    subtotal: float = Field(..., ge=0, description="Item subtotal (quantity × unitPrice)")
    customization: Optional[dict] = Field(None, description="Custom requirements for this item")

    class Config:
        """Pydantic configuration."""
        allow_population_by_field_name = True
        schema_extra = {
            "example": {
                "itemId": "item-123",
                "campaign": {
                    "campaignId": "campaign-123",
                    "campaignName": "Basic Website Package",
                    "price": 499.99,
                    "description": "5-page website"
                },
                "quantity": 1,
                "unitPrice": 499.99,
                "subtotal": 499.99,
                "customization": {
                    "color_scheme": "blue",
                    "logo": "custom_logo.png"
                }
            }
        }
