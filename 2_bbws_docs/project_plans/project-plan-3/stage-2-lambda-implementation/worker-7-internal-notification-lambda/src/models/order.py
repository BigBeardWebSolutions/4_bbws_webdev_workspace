"""Order Pydantic Model."""

from typing import List, Optional
from datetime import datetime
from pydantic import BaseModel, Field, validator
from .order_item import OrderItem
from .billing_address import BillingAddress
from .payment_details import PaymentDetails


class Order(BaseModel):
    """Complete order model with 25 attributes."""

    # Identity
    order_id: str = Field(..., alias="orderId", description="Unique order ID (UUID)")
    tenant_id: str = Field(..., alias="tenantId", description="Tenant ID for multi-tenancy")
    order_number: str = Field(..., alias="orderNumber", description="Human-readable order number")

    # Customer Information
    customer_email: str = Field(..., alias="customerEmail", description="Customer email address")
    customer_name: str = Field(..., alias="customerName", description="Customer full name")
    customer_phone: Optional[str] = Field(None, alias="customerPhone", description="Customer phone number")

    # Order Items
    items: List[OrderItem] = Field(..., min_items=1, description="List of order items")

    # Pricing
    subtotal: float = Field(..., ge=0, description="Subtotal before tax and shipping")
    tax: float = Field(0.0, ge=0, description="Tax amount")
    shipping: float = Field(0.0, ge=0, description="Shipping cost")
    discount: float = Field(0.0, ge=0, description="Discount amount")
    total: float = Field(..., ge=0, description="Total order amount")

    # Status
    order_status: str = Field(
        "pending",
        alias="orderStatus",
        description="Order status: pending, processing, completed, cancelled, failed"
    )
    payment_status: str = Field(
        "pending",
        alias="paymentStatus",
        description="Payment status: pending, paid, failed, refunded"
    )

    # Addresses
    billing_address: BillingAddress = Field(..., alias="billingAddress", description="Billing address")
    shipping_address: Optional[BillingAddress] = Field(
        None,
        alias="shippingAddress",
        description="Shipping address (if different from billing)"
    )

    # Payment
    payment_details: Optional[PaymentDetails] = Field(None, alias="paymentDetails", description="Payment information")

    # Metadata
    created_at: datetime = Field(..., alias="createdAt", description="Order creation timestamp")
    updated_at: datetime = Field(..., alias="updatedAt", description="Last update timestamp")
    created_by: str = Field(..., alias="createdBy", description="User who created the order")
    notes: Optional[str] = Field(None, description="Additional order notes")

    # PDF and Notifications
    pdf_url: Optional[str] = Field(None, alias="pdfUrl", description="S3 URL to order PDF invoice")
    notification_sent: bool = Field(False, alias="notificationSent", description="Internal notification sent flag")
    confirmation_sent: bool = Field(False, alias="confirmationSent", description="Customer confirmation sent flag")

    # Cart Reference
    cart_id: Optional[str] = Field(None, alias="cartId", description="Original cart ID (if from cart)")

    @validator("total")
    def validate_total(cls, v, values):
        """Validate that total matches calculation."""
        if "subtotal" in values and "tax" in values and "shipping" in values and "discount" in values:
            expected_total = values["subtotal"] + values["tax"] + values["shipping"] - values["discount"]
            if abs(v - expected_total) > 0.01:  # Allow for floating point precision
                raise ValueError(f"Total {v} does not match calculated total {expected_total}")
        return v

    class Config:
        """Pydantic configuration."""
        allow_population_by_field_name = True
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }
        schema_extra = {
            "example": {
                "orderId": "550e8400-e29b-41d4-a716-446655440000",
                "tenantId": "tenant-123",
                "orderNumber": "ORD-2025-001",
                "customerEmail": "customer@example.com",
                "customerName": "John Doe",
                "customerPhone": "+27123456789",
                "items": [
                    {
                        "itemId": "item-123",
                        "campaign": {
                            "campaignId": "campaign-123",
                            "campaignName": "Basic Website Package",
                            "price": 499.99
                        },
                        "quantity": 1,
                        "unitPrice": 499.99,
                        "subtotal": 499.99
                    }
                ],
                "subtotal": 499.99,
                "tax": 75.00,
                "shipping": 0.00,
                "discount": 0.00,
                "total": 574.99,
                "orderStatus": "pending",
                "paymentStatus": "pending",
                "billingAddress": {
                    "street": "123 Main St",
                    "city": "Cape Town",
                    "postalCode": "8001",
                    "country": "ZA"
                },
                "createdAt": "2025-12-30T10:00:00Z",
                "updatedAt": "2025-12-30T10:00:00Z",
                "createdBy": "user-123"
            }
        }
