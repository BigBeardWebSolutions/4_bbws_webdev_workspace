"""
PaymentDetails Pydantic model for Order Lambda.
"""
from pydantic import BaseModel, Field
from typing import Optional


class PaymentDetails(BaseModel):
    """
    Payment transaction details.

    Contains payment information for completed/paid orders.
    """

    paymentId: str = Field(..., description="Internal payment ID")
    payfastPaymentId: Optional[str] = Field(None, description="PayFast transaction ID")
    paidAt: Optional[str] = Field(None, description="ISO 8601 timestamp when payment completed")

    class Config:
        """Pydantic configuration."""
        schema_extra = {
            "example": {
                "paymentId": "pay_550e8400-e29b-41d4-a716-446655440001",
                "payfastPaymentId": "payfast_123456",
                "paidAt": "2025-12-19T10:35:00Z"
            }
        }
