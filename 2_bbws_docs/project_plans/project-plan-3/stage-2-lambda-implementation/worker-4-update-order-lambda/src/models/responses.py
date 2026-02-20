"""Response models for Order Lambda API."""

from typing import Any, Dict, Optional

from pydantic import BaseModel, Field

from .order import Order


class UpdateOrderResponse(BaseModel):
    """Response model for update order operation."""

    success: bool = Field(True, description="Operation success status")
    data: Optional[Dict[str, Any]] = Field(None, description="Order data")
    message: Optional[str] = Field(None, description="Success message")

    class Config:
        """Pydantic model configuration."""
        pass


class ErrorResponse(BaseModel):
    """Error response model."""

    success: bool = Field(False, description="Operation success status")
    error: str = Field(..., description="Error type")
    message: str = Field(..., description="Error message")
    statusCode: int = Field(..., description="HTTP status code")

    class Config:
        """Pydantic model configuration."""
        pass
