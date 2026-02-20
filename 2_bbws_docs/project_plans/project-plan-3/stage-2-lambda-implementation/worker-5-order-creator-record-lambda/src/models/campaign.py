"""
Campaign model for Order Lambda service.
"""

from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field, validator


class Campaign(BaseModel):
    """
    Campaign model representing promotional campaign details.

    Campaign data is denormalized to preserve historical state at order creation time.

    Attributes:
        id: Campaign UUID
        code: Campaign code (e.g., SUMMER2025)
        description: Campaign description
        discountPercentage: Discount percentage (e.g., 20.0)
        productId: Product reference
        termsConditionsLink: Terms and conditions URL
        fromDate: Campaign start date
        toDate: Campaign end date
        isValid: Campaign validity at order creation
        dateCreated: Campaign creation timestamp
        dateLastUpdated: Campaign last update timestamp
        lastUpdatedBy: User who last updated campaign
        active: Campaign soft delete flag
    """

    id: str = Field(..., description="Campaign UUID")
    code: str = Field(..., description="Campaign code", min_length=1, max_length=50)
    description: str = Field(..., description="Campaign description", min_length=1, max_length=500)
    discountPercentage: float = Field(..., description="Discount percentage", ge=0.0, le=100.0)
    productId: str = Field(..., description="Product reference")
    termsConditionsLink: str = Field(..., description="Terms and conditions URL")
    fromDate: str = Field(..., description="Campaign start date (ISO 8601)")
    toDate: str = Field(..., description="Campaign end date (ISO 8601)")
    isValid: bool = Field(..., description="Campaign validity at order creation")
    dateCreated: str = Field(..., description="Campaign creation timestamp (ISO 8601)")
    dateLastUpdated: str = Field(..., description="Campaign last update timestamp (ISO 8601)")
    lastUpdatedBy: str = Field(..., description="User who last updated campaign")
    active: bool = Field(default=True, description="Campaign soft delete flag")

    @validator('fromDate', 'toDate', 'dateCreated', 'dateLastUpdated')
    def validate_iso_date(cls, v):
        """Validate ISO 8601 date format."""
        try:
            datetime.fromisoformat(v.replace('Z', '+00:00'))
        except ValueError:
            raise ValueError(f'Invalid ISO 8601 date format: {v}')
        return v

    @validator('termsConditionsLink')
    def validate_url(cls, v):
        """Validate URL format."""
        if not v.startswith(('http://', 'https://')):
            raise ValueError('Terms and conditions link must be a valid URL')
        return v

    class Config:
        """Pydantic model configuration."""
        json_encoders = {
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
