"""
BillingAddress model for Order Lambda.

Represents customer billing address information.
"""

from typing import Optional
from pydantic import BaseModel, Field


class BillingAddress(BaseModel):
    """
    Billing address information for an order.

    Attributes:
        fullName: Full name for billing
        addressLine1: Primary address line
        addressLine2: Secondary address line (optional)
        city: City name
        stateProvince: State or province
        postalCode: Postal/ZIP code
        country: Country code (ISO 3166-1 alpha-2)
        phoneNumber: Contact phone number (optional)
    """

    fullName: str = Field(..., description="Full name for billing", min_length=1, max_length=200)
    addressLine1: str = Field(..., description="Primary address line", min_length=1, max_length=255)
    addressLine2: Optional[str] = Field(None, description="Secondary address line", max_length=255)
    city: str = Field(..., description="City name", min_length=1, max_length=100)
    stateProvince: str = Field(..., description="State or province", min_length=1, max_length=100)
    postalCode: str = Field(..., description="Postal/ZIP code", min_length=1, max_length=20)
    country: str = Field(..., description="Country code (ISO 3166-1 alpha-2)", min_length=2, max_length=2)
    phoneNumber: Optional[str] = Field(None, description="Contact phone number", max_length=20)

    class Config:
        """Pydantic configuration."""
        schema_extra = {
            "example": {
                "fullName": "John Doe",
                "addressLine1": "123 Main Street",
                "addressLine2": "Apt 4B",
                "city": "Cape Town",
                "stateProvince": "Western Cape",
                "postalCode": "8001",
                "country": "ZA",
                "phoneNumber": "+27123456789"
            }
        }
