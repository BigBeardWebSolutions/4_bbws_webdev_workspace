"""Request models for Order Lambda API."""

from typing import Optional

from pydantic import BaseModel, Field

from .order import PaymentDetails, OrderStatus


class UpdateOrderRequest(BaseModel):
    """
    Request model for updating an order.

    Only status and paymentDetails are allowed to be updated.
    All other fields are immutable after order creation.
    """

    status: Optional[OrderStatus] = Field(None, description="New order status")
    paymentDetails: Optional[PaymentDetails] = Field(None, description="Payment details")

    class Config:
        """Pydantic model configuration."""
        use_enum_values = True

    def has_updates(self) -> bool:
        """Check if request contains any updates."""
        return self.status is not None or self.paymentDetails is not None
