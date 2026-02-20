"""Campaign Pydantic Model."""

from typing import Optional
from pydantic import BaseModel, Field


class Campaign(BaseModel):
    """Campaign information (denormalized for historical accuracy)."""

    campaign_id: str = Field(..., alias="campaignId", description="Campaign ID")
    campaign_name: str = Field(..., alias="campaignName", description="Campaign name")
    price: float = Field(..., description="Campaign price at time of order")
    description: Optional[str] = Field(None, description="Campaign description")

    class Config:
        """Pydantic configuration."""
        allow_population_by_field_name = True
        schema_extra = {
            "example": {
                "campaignId": "campaign-123",
                "campaignName": "Basic Website Package",
                "price": 499.99,
                "description": "5-page website with responsive design"
            }
        }
