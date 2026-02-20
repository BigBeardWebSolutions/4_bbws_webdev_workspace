"""
Campaign model for Order Lambda.

Represents marketing campaign information denormalized into order for historical accuracy.
"""

from typing import Optional
from pydantic import BaseModel, Field
from datetime import datetime


class Campaign(BaseModel):
    """
    Campaign information embedded in order for historical tracking.

    Denormalized from Campaign entity to preserve campaign details as they
    existed at the time of order creation.

    Attributes:
        id: Campaign identifier
        code: Campaign code used by customer
        name: Campaign name
        discountType: Type of discount (percentage, fixed_amount)
        discountValue: Discount value (percentage or amount)
        startDate: Campaign start date
        endDate: Campaign end date
        isActive: Whether campaign is currently active
    """

    id: str = Field(..., description="Campaign identifier")
    code: str = Field(..., description="Campaign code", min_length=1, max_length=50)
    name: str = Field(..., description="Campaign name", min_length=1, max_length=200)
    discountType: str = Field(..., description="Discount type (percentage, fixed_amount)")
    discountValue: float = Field(..., description="Discount value", ge=0)
    startDate: Optional[datetime] = Field(None, description="Campaign start date")
    endDate: Optional[datetime] = Field(None, description="Campaign end date")
    isActive: bool = Field(True, description="Whether campaign is active")

    class Config:
        """Pydantic configuration."""
        json_encoders = {
            datetime: lambda v: v.isoformat() if v else None
        }
        schema_extra = {
            "example": {
                "id": "camp-123",
                "code": "SUMMER2025",
                "name": "Summer Sale 2025",
                "discountType": "percentage",
                "discountValue": 15.0,
                "startDate": "2025-06-01T00:00:00Z",
                "endDate": "2025-08-31T23:59:59Z",
                "isActive": True
            }
        }
