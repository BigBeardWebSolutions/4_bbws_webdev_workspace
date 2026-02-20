"""Billing Address Pydantic Model."""

from typing import Optional
from pydantic import BaseModel, Field


class BillingAddress(BaseModel):
    """Billing address information."""

    street: str = Field(..., description="Street address")
    city: str = Field(..., description="City")
    state: Optional[str] = Field(None, description="State/Province")
    postal_code: str = Field(..., alias="postalCode", description="Postal/ZIP code")
    country: str = Field(..., description="Country code (ISO 3166-1 alpha-2)")

    class Config:
        """Pydantic configuration."""
        allow_population_by_field_name = True
        schema_extra = {
            "example": {
                "street": "123 Main St",
                "city": "Cape Town",
                "state": "Western Cape",
                "postalCode": "8001",
                "country": "ZA"
            }
        }
