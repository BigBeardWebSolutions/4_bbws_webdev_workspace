"""
BillingAddress Pydantic model for Order Lambda.
"""
from pydantic import BaseModel, Field


class BillingAddress(BaseModel):
    """
    Billing address details.

    Represents the billing address for an order.
    """

    street: str = Field(..., description="Street address")
    city: str = Field(..., description="City")
    province: str = Field(..., description="Province/State")
    postalCode: str = Field(..., description="Postal/ZIP code")
    country: str = Field(..., description="Country code (ISO 3166-1 alpha-2, e.g., ZA)")

    class Config:
        """Pydantic configuration."""
        schema_extra = {
            "example": {
                "street": "123 Main Street",
                "city": "Cape Town",
                "province": "Western Cape",
                "postalCode": "8001",
                "country": "ZA"
            }
        }
