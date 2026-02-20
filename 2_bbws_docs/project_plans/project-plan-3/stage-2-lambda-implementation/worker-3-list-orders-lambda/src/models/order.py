"""
Order Pydantic model for Order Lambda.

Main Order entity with Activatable Entity Pattern and embedded Campaign.
"""
from pydantic import BaseModel, Field, EmailStr
from decimal import Decimal
from datetime import datetime
from typing import List, Optional
from enum import Enum

from .order_item import OrderItem
from .campaign import Campaign
from .billing_address import BillingAddress
from .payment_details import PaymentDetails


class OrderStatus(str, Enum):
    """Order status enumeration."""
    PENDING = "pending"
    PENDING_PAYMENT = "PENDING_PAYMENT"
    PAID = "PAID"
    PROCESSING = "PROCESSING"
    COMPLETED = "COMPLETED"
    CANCELLED = "CANCELLED"
    REFUNDED = "REFUNDED"
    EXPIRED = "EXPIRED"


class Order(BaseModel):
    """
    Order entity with Activatable Entity Pattern and embedded Campaign.

    Represents a complete customer order with all line items, payment details,
    and billing information.
    """

    # Core identifiers
    id: str = Field(..., description="Unique order identifier (UUID)")
    orderNumber: str = Field(..., description="Human-readable order number (e.g., ORD-20251215-0001)")
    tenantId: str = Field(..., description="Tenant identifier (UUID)")
    customerEmail: EmailStr = Field(..., description="Customer email address")

    # Order items and pricing
    items: List[OrderItem] = Field(default_factory=list, description="Array of OrderItem objects")
    subtotal: Decimal = Field(..., description="Subtotal amount (before tax)")
    tax: Decimal = Field(..., description="Tax amount")
    total: Decimal = Field(..., description="Total amount (subtotal + tax)")
    currency: str = Field(default="ZAR", description="Currency code (e.g., ZAR, USD)")

    # Status and workflow
    status: OrderStatus = Field(..., description="Order status enum")

    # Campaign (optional, denormalized)
    campaign: Optional[Campaign] = Field(None, description="Embedded Campaign object (denormalized, optional)")

    # Billing and payment
    billingAddress: BillingAddress = Field(..., description="Billing address object")
    paymentMethod: str = Field(..., description="Payment method (e.g., payfast, credit_card)")
    paymentDetails: Optional[PaymentDetails] = Field(None, description="Payment transaction details (optional)")

    # Audit fields (Activatable Entity Pattern)
    dateCreated: str = Field(..., description="ISO 8601 timestamp when order was created")
    dateLastUpdated: str = Field(..., description="ISO 8601 timestamp when order was last updated")
    lastUpdatedBy: str = Field(..., description="User/system identifier who last updated")
    active: bool = Field(default=True, description="Soft delete flag (true = active, false = deleted)")

    class Config:
        """Pydantic configuration."""
        json_encoders = {
            Decimal: lambda v: float(v),
            datetime: lambda v: v.isoformat()
        }
        use_enum_values = True
        schema_extra = {
            "example": {
                "id": "order_aa0e8400-e29b-41d4-a716-446655440005",
                "orderNumber": "ORD-20251215-0001",
                "tenantId": "tenant_bb0e8400-e29b-41d4-a716-446655440006",
                "customerEmail": "customer@example.com",
                "items": [
                    {
                        "id": "item_cc0e8400-e29b-41d4-a716-446655440007",
                        "productId": "prod_550e8400-e29b-41d4-a716-446655440000",
                        "productName": "WordPress Professional Plan",
                        "quantity": 1,
                        "unitPrice": 299.99,
                        "discount": 60.00,
                        "subtotal": 239.99,
                        "dateCreated": "2025-12-19T10:30:00Z",
                        "dateLastUpdated": "2025-12-19T10:30:00Z",
                        "lastUpdatedBy": "system",
                        "active": True
                    }
                ],
                "subtotal": 239.99,
                "tax": 35.99,
                "total": 275.98,
                "currency": "ZAR",
                "status": "PENDING_PAYMENT",
                "campaign": {
                    "id": "camp_770e8400-e29b-41d4-a716-446655440002",
                    "code": "SUMMER2025",
                    "description": "Summer 2025 Special Offer",
                    "discountPercentage": 20.0,
                    "productId": "prod_550e8400-e29b-41d4-a716-446655440000",
                    "termsConditionsLink": "https://kimmyai.io/terms/campaigns/summer2025",
                    "fromDate": "2025-06-01",
                    "toDate": "2025-08-31",
                    "isValid": True,
                    "dateCreated": "2025-05-01T08:00:00Z",
                    "dateLastUpdated": "2025-05-01T08:00:00Z",
                    "lastUpdatedBy": "admin@kimmyai.io",
                    "active": True
                },
                "billingAddress": {
                    "street": "123 Main Street",
                    "city": "Cape Town",
                    "province": "Western Cape",
                    "postalCode": "8001",
                    "country": "ZA"
                },
                "paymentMethod": "payfast",
                "paymentDetails": None,
                "dateCreated": "2025-12-19T10:30:00Z",
                "dateLastUpdated": "2025-12-19T10:30:00Z",
                "lastUpdatedBy": "customer@example.com",
                "active": True
            }
        }
