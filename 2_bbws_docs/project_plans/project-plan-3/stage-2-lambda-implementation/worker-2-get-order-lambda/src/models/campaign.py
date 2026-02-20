"""
Campaign Pydantic model for Order Lambda.

Embedded Campaign object (denormalized for historical accuracy).
"""
from pydantic import BaseModel, Field
from decimal import Decimal
from datetime import datetime
from typing import Optional


class Campaign(BaseModel):
    """
    Embedded Campaign object (denormalized for historical accuracy).

    Campaign details are denormalized to preserve historical campaign state
    at order creation time.
    """

    id: str = Field(..., description="Campaign UUID")
    code: str = Field(..., description="Campaign code (e.g., SUMMER2025)")
    description: str = Field(..., description="Campaign description")
    discountPercentage: Decimal = Field(..., description="Discount percentage (e.g., 20.0)")
    productId: str = Field(..., description="Product reference (UUID)")
    termsConditionsLink: str = Field(..., description="Terms and conditions URL")
    fromDate: str = Field(..., description="Campaign start date (ISO 8601)")
    toDate: str = Field(..., description="Campaign end date (ISO 8601)")
    isValid: bool = Field(..., description="Campaign validity at order creation")
    dateCreated: str = Field(..., description="Campaign creation timestamp (ISO 8601)")
    dateLastUpdated: str = Field(..., description="Campaign last update timestamp (ISO 8601)")
    lastUpdatedBy: str = Field(..., description="User who last updated campaign")
    active: bool = Field(default=True, description="Campaign soft delete flag")

    class Config:
        """Pydantic configuration."""
        json_encoders = {
            Decimal: lambda v: float(v),
            datetime: lambda v: v.isoformat()
        }
        schema_extra = {
            "example": {
                "id": "camp_770e8400-e29b-41d4-a716-446655440002",
                "code": "SUMMER2025",
                "description": "Summer 2025 Special Offer - 20% off all WordPress plans",
                "discountPercentage": 20.0,
                "productId": "prod_550e8400-e29b-41d4-a716-446655440000",
                "termsConditionsLink": "https://kimmyai.io/terms/campaigns/summer2025",
                "fromDate": "2025-06-01",
                "toDate": "2025-08-31",
                "isValid": True,
                "dateCreated": "2025-05-01T08:00:00Z",
                "dateLastUpdated": "2025-05-01T08:00:00Z",
                "lastUpdatedBy": "admin@kimmyai.io",
                "active": True
            }
        }
