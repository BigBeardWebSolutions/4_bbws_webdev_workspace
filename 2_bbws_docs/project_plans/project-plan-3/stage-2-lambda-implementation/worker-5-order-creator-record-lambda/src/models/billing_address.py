"""
Billing Address model for Order Lambda service.
"""

from pydantic import BaseModel, Field, validator


class BillingAddress(BaseModel):
    """
    Billing address model representing customer billing information.

    Attributes:
        street: Street address
        city: City name
        province: Province or state
        postalCode: Postal or ZIP code
        country: Country code (ISO 3166-1 alpha-2)
    """

    street: str = Field(..., description="Street address", min_length=1, max_length=255)
    city: str = Field(..., description="City name", min_length=1, max_length=100)
    province: str = Field(..., description="Province or state", min_length=1, max_length=100)
    postalCode: str = Field(..., description="Postal or ZIP code", min_length=1, max_length=20)
    country: str = Field(..., description="Country code (ISO 3166-1 alpha-2)", min_length=2, max_length=2)

    @validator('country')
    def validate_country_code(cls, v):
        """Validate country code is uppercase ISO 3166-1 alpha-2."""
        if not v.isupper():
            raise ValueError('Country code must be uppercase (e.g., ZA, US)')
        return v

    class Config:
        """Pydantic model configuration."""
        schema_extra = {
            "example": {
                "street": "123 Main Street",
                "city": "Cape Town",
                "province": "Western Cape",
                "postalCode": "8001",
                "country": "ZA"
            }
        }
