"""Campaign domain models using Pydantic for validation."""

from decimal import Decimal
from enum import Enum
from typing import Optional

from pydantic import BaseModel, Field, field_validator


class CampaignStatus(str, Enum):
    """Campaign status enumeration."""

    DRAFT = "DRAFT"
    ACTIVE = "ACTIVE"
    EXPIRED = "EXPIRED"


class Campaign(BaseModel):
    """Campaign domain model."""

    code: str
    product_id: str = Field(..., alias="productId")
    discount_percent: int = Field(..., alias="discountPercent", ge=0, le=100)
    list_price: Decimal = Field(..., alias="listPrice", gt=0)
    price: Decimal = Field(gt=0)
    terms_and_conditions: str = Field(..., alias="termsAndConditions")
    status: CampaignStatus
    from_date: str = Field(..., alias="fromDate")
    to_date: str = Field(..., alias="toDate")
    special_conditions: Optional[str] = Field(None, alias="specialConditions")
    active: bool = True

    class Config:
        """Pydantic configuration."""

        populate_by_name = True
        use_enum_values = True

    @field_validator("discount_percent")
    @classmethod
    def validate_discount(cls, v: int) -> int:
        """Validate discount percentage is between 0 and 100."""
        if not 0 <= v <= 100:
            raise ValueError("Discount percent must be between 0 and 100")
        return v

    @field_validator("price")
    @classmethod
    def validate_price(cls, v: Decimal, info) -> Decimal:
        """Validate price is less than or equal to list price."""
        if "list_price" in info.data and v > info.data["list_price"]:
            raise ValueError("Price cannot exceed list price")
        return v


class CampaignResponse(BaseModel):
    """Campaign API response model."""

    code: str
    product_id: str = Field(..., alias="productId")
    discount_percent: int = Field(..., alias="discountPercent")
    list_price: Decimal = Field(..., alias="listPrice")
    price: Decimal
    terms_and_conditions: str = Field(..., alias="termsAndConditions")
    status: CampaignStatus
    from_date: str = Field(..., alias="fromDate")
    to_date: str = Field(..., alias="toDate")
    special_conditions: Optional[str] = Field(None, alias="specialConditions")
    is_valid: bool = Field(..., alias="isValid")

    class Config:
        """Pydantic configuration."""

        populate_by_name = True
        use_enum_values = True

    @classmethod
    def from_campaign(cls, campaign: Campaign) -> "CampaignResponse":
        """Create response from campaign domain model."""
        return cls(
            code=campaign.code,
            productId=campaign.product_id,
            discountPercent=campaign.discount_percent,
            listPrice=campaign.list_price,
            price=campaign.price,
            termsAndConditions=campaign.terms_and_conditions,
            status=campaign.status,
            fromDate=campaign.from_date,
            toDate=campaign.to_date,
            specialConditions=campaign.special_conditions,
            isValid=campaign.status == CampaignStatus.ACTIVE,
        )
