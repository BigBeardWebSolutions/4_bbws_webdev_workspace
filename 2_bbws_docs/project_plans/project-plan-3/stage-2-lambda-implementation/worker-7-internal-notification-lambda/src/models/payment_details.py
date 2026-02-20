"""Payment Details Pydantic Model."""

from typing import Optional
from pydantic import BaseModel, Field


class PaymentDetails(BaseModel):
    """Payment information (optional, for future use)."""

    payment_method: str = Field(..., alias="paymentMethod", description="Payment method (e.g., credit_card, paypal)")
    transaction_id: Optional[str] = Field(None, alias="transactionId", description="External transaction ID")
    payment_gateway: Optional[str] = Field(None, alias="paymentGateway", description="Payment gateway used")

    class Config:
        """Pydantic configuration."""
        allow_population_by_field_name = True
        schema_extra = {
            "example": {
                "paymentMethod": "credit_card",
                "transactionId": "txn_1234567890",
                "paymentGateway": "stripe"
            }
        }
