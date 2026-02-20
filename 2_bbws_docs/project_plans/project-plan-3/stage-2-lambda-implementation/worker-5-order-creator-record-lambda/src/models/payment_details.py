"""
Payment Details model for Order Lambda service.
"""

from typing import Optional
from pydantic import BaseModel, Field, validator
from datetime import datetime


class PaymentDetails(BaseModel):
    """
    Payment details model representing payment transaction information.

    Attributes:
        paymentId: Internal payment ID
        payfastPaymentId: PayFast transaction ID (optional)
        paidAt: ISO 8601 timestamp when payment completed (optional)
    """

    paymentId: str = Field(..., description="Internal payment ID")
    payfastPaymentId: Optional[str] = Field(None, description="PayFast transaction ID")
    paidAt: Optional[str] = Field(None, description="ISO 8601 timestamp when payment completed")

    @validator('paidAt')
    def validate_paid_at(cls, v):
        """Validate paidAt ISO 8601 format if provided."""
        if v is not None:
            try:
                datetime.fromisoformat(v.replace('Z', '+00:00'))
            except ValueError:
                raise ValueError(f'Invalid ISO 8601 date format: {v}')
        return v

    class Config:
        """Pydantic model configuration."""
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }
        schema_extra = {
            "example": {
                "paymentId": "pay_123456789",
                "payfastPaymentId": "pf_987654321",
                "paidAt": "2025-12-30T12:00:00Z"
            }
        }
