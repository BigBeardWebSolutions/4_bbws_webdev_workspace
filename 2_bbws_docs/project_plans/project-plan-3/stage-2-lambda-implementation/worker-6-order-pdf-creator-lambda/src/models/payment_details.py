"""
PaymentDetails model for Order Lambda.

Represents payment transaction information.
"""

from typing import Optional
from pydantic import BaseModel, Field
from datetime import datetime


class PaymentDetails(BaseModel):
    """
    Payment transaction details for an order.

    Attributes:
        method: Payment method (credit_card, debit_card, paypal, bank_transfer)
        transactionId: External payment provider transaction ID
        paidAt: Timestamp when payment was completed
        amount: Amount paid
        currency: Currency code (ISO 4217)
        status: Payment status (pending, completed, failed, refunded)
        failureReason: Reason for payment failure (optional)
    """

    method: str = Field(..., description="Payment method", min_length=1, max_length=50)
    transactionId: Optional[str] = Field(None, description="Payment provider transaction ID", max_length=255)
    paidAt: Optional[datetime] = Field(None, description="Payment completion timestamp")
    amount: float = Field(..., description="Amount paid", ge=0)
    currency: str = Field(..., description="Currency code (ISO 4217)", min_length=3, max_length=3)
    status: str = Field(default="pending", description="Payment status")
    failureReason: Optional[str] = Field(None, description="Payment failure reason", max_length=500)

    class Config:
        """Pydantic configuration."""
        json_encoders = {
            datetime: lambda v: v.isoformat() if v else None
        }
        schema_extra = {
            "example": {
                "method": "credit_card",
                "transactionId": "txn-abc123xyz",
                "paidAt": "2025-12-30T12:00:00Z",
                "amount": 250.00,
                "currency": "ZAR",
                "status": "completed",
                "failureReason": None
            }
        }
