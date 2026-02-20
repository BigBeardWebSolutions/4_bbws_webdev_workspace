"""
Order model for Order Lambda.

Represents a complete customer order with all associated data.
"""

from typing import Optional, List
from pydantic import BaseModel, Field, validator
from datetime import datetime
from src.models.order_item import OrderItem
from src.models.billing_address import BillingAddress
from src.models.campaign import Campaign
from src.models.payment_details import PaymentDetails
import re


class Order(BaseModel):
    """
    Complete order entity with all associated data.

    Attributes:
        id: Unique order identifier (UUID v4)
        orderNumber: Human-readable order number (ORD-YYYY-NNNNN)
        tenantId: Tenant identifier
        customerId: Customer identifier (optional)
        customerEmail: Customer email address
        customerName: Customer full name (optional)
        status: Order status (pending, processing, paid, shipped, delivered, cancelled, refunded)
        items: List of order line items
        subtotal: Order subtotal (sum of item subtotals)
        taxAmount: Total tax amount
        shippingAmount: Shipping/delivery charge
        discountAmount: Total discount applied
        total: Order grand total
        currency: Currency code (ISO 4217)
        billingAddress: Billing address
        shippingAddress: Shipping address (optional, can differ from billing)
        campaign: Campaign information (optional)
        paymentDetails: Payment transaction details (optional)
        pdfUrl: URL to generated PDF invoice (optional)
        notes: Order notes/comments (optional)
        metadata: Additional metadata (JSON object, optional)
        isActive: Soft delete flag (Activatable Entity Pattern)
        dateCreated: Order creation timestamp
        dateLastUpdated: Last update timestamp
        dateCompleted: Order completion timestamp (optional)
    """

    # Core identifiers
    id: str = Field(..., description="Unique order ID (UUID v4)")
    orderNumber: str = Field(..., description="Human-readable order number")
    tenantId: str = Field(..., description="Tenant identifier")
    customerId: Optional[str] = Field(None, description="Customer identifier")
    customerEmail: str = Field(..., description="Customer email address")
    customerName: Optional[str] = Field(None, description="Customer full name")

    # Status
    status: str = Field(default="pending", description="Order status")

    # Line items
    items: List[OrderItem] = Field(..., description="Order line items", min_items=1)

    # Financial calculations
    subtotal: float = Field(..., description="Order subtotal", ge=0)
    taxAmount: float = Field(default=0.0, description="Total tax amount", ge=0)
    shippingAmount: float = Field(default=0.0, description="Shipping charge", ge=0)
    discountAmount: float = Field(default=0.0, description="Total discount", ge=0)
    total: float = Field(..., description="Order grand total", ge=0)
    currency: str = Field(..., description="Currency code (ISO 4217)", min_length=3, max_length=3)

    # Addresses
    billingAddress: BillingAddress = Field(..., description="Billing address")
    shippingAddress: Optional[BillingAddress] = Field(None, description="Shipping address")

    # Campaign and payment
    campaign: Optional[Campaign] = Field(None, description="Campaign information")
    paymentDetails: Optional[PaymentDetails] = Field(None, description="Payment details")

    # PDF invoice
    pdfUrl: Optional[str] = Field(None, description="PDF invoice URL")

    # Additional data
    notes: Optional[str] = Field(None, description="Order notes", max_length=2000)
    metadata: Optional[dict] = Field(None, description="Additional metadata")

    # Activatable Entity Pattern
    isActive: bool = Field(default=True, description="Soft delete flag")

    # Timestamps
    dateCreated: datetime = Field(..., description="Order creation timestamp")
    dateLastUpdated: datetime = Field(..., description="Last update timestamp")
    dateCompleted: Optional[datetime] = Field(None, description="Order completion timestamp")

    @validator('orderNumber')
    def validate_order_number(cls, v):
        """Validate order number format (ORD-YYYY-NNNNN)."""
        pattern = r'^ORD-\d{4}-\d{5}$'
        if not re.match(pattern, v):
            raise ValueError(f'Invalid order number format. Expected ORD-YYYY-NNNNN, got {v}')
        return v

    @validator('customerEmail')
    def validate_email(cls, v):
        """Validate email format."""
        pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        if not re.match(pattern, v):
            raise ValueError(f'Invalid email format: {v}')
        return v

    @validator('status')
    def validate_status(cls, v):
        """Validate order status."""
        valid_statuses = ['pending', 'processing', 'paid', 'shipped', 'delivered', 'cancelled', 'refunded']
        if v not in valid_statuses:
            raise ValueError(f'Invalid status. Must be one of: {", ".join(valid_statuses)}')
        return v

    @validator('currency')
    def validate_currency(cls, v):
        """Validate currency code (ISO 4217)."""
        if not v.isupper():
            raise ValueError('Currency code must be uppercase')
        return v

    @validator('total')
    def validate_total(cls, v, values):
        """Validate total calculation."""
        if 'subtotal' in values and 'taxAmount' in values and 'shippingAmount' in values and 'discountAmount' in values:
            expected_total = values['subtotal'] + values['taxAmount'] + values['shippingAmount'] - values['discountAmount']
            # Allow small floating point differences
            if abs(v - expected_total) > 0.01:
                raise ValueError(
                    f'Total mismatch. Expected {expected_total:.2f}, got {v:.2f} '
                    f'(subtotal={values["subtotal"]}, tax={values["taxAmount"]}, '
                    f'shipping={values["shippingAmount"]}, discount={values["discountAmount"]})'
                )
        return v

    class Config:
        """Pydantic configuration."""
        json_encoders = {
            datetime: lambda v: v.isoformat() if v else None
        }
        schema_extra = {
            "example": {
                "id": "550e8400-e29b-41d4-a716-446655440000",
                "orderNumber": "ORD-2025-00001",
                "tenantId": "tenant-123",
                "customerId": "cust-456",
                "customerEmail": "customer@example.com",
                "customerName": "John Doe",
                "status": "paid",
                "items": [
                    {
                        "productId": "prod-123",
                        "productName": "Premium WordPress Theme",
                        "productSku": "WP-THEME-001",
                        "quantity": 1,
                        "unitPrice": 99.00,
                        "currency": "ZAR",
                        "subtotal": 99.00,
                        "taxRate": 0.15,
                        "taxAmount": 14.85,
                        "total": 113.85
                    }
                ],
                "subtotal": 99.00,
                "taxAmount": 14.85,
                "shippingAmount": 0.00,
                "discountAmount": 0.00,
                "total": 113.85,
                "currency": "ZAR",
                "billingAddress": {
                    "fullName": "John Doe",
                    "addressLine1": "123 Main Street",
                    "city": "Cape Town",
                    "stateProvince": "Western Cape",
                    "postalCode": "8001",
                    "country": "ZA"
                },
                "pdfUrl": "https://s3.amazonaws.com/bbws-orders-dev/tenant-123/orders/order_550e8400.pdf",
                "isActive": True,
                "dateCreated": "2025-12-30T10:30:00Z",
                "dateLastUpdated": "2025-12-30T10:30:00Z"
            }
        }
