"""Response models for create_order Lambda function.

This module defines Pydantic v1.10.18 models for Lambda function responses.
"""

from pydantic import BaseModel, Field
from typing import Optional


class CreateOrderResponse(BaseModel):
    """Response model for order creation.

    Returns a 202 Accepted response with the order identifier.
    The order is accepted for asynchronous processing via SQS.

    Attributes:
        orderId: Unique order identifier (UUID v4)
        orderNumber: Human-readable order number (assigned by Worker 5)
        status: Order status (always "pending" for create)
        message: Human-readable status message
    """

    orderId: str = Field(..., description="Unique order identifier")
    orderNumber: Optional[str] = Field(None, description="Human-readable order number")
    status: str = Field(default="pending", description="Order status")
    message: str = Field(default="Order accepted for processing", description="Status message")

    class Config:
        """Pydantic model configuration."""
        schema_extra = {
            "example": {
                "orderId": "550e8400-e29b-41d4-a716-446655440000",
                "orderNumber": None,
                "status": "pending",
                "message": "Order accepted for processing"
            }
        }
