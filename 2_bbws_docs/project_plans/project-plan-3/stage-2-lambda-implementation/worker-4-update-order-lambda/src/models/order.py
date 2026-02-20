"""Order domain models using Pydantic v1.10.18."""

from datetime import datetime
from decimal import Decimal
from enum import Enum
from typing import List, Optional

from pydantic import BaseModel, Field, validator


class OrderStatus(str, Enum):
    """Order status enumeration."""

    PENDING = "pending"
    PAYMENT_PENDING = "payment_pending"
    PAID = "paid"
    PROCESSING = "processing"
    COMPLETED = "completed"
    CANCELLED = "cancelled"
    REFUNDED = "refunded"


class PaymentDetails(BaseModel):
    """Payment details for an order."""

    method: Optional[str] = Field(None, description="Payment method (e.g., credit_card, payfast)")
    transactionId: Optional[str] = Field(None, description="Payment gateway transaction ID")
    payfastPaymentId: Optional[str] = Field(None, description="PayFast payment ID")
    paidAt: Optional[str] = Field(None, description="Payment timestamp (ISO 8601)")

    class Config:
        """Pydantic model configuration."""
        use_enum_values = True


class BillingAddress(BaseModel):
    """Billing address for an order."""

    street: str = Field(..., description="Street address")
    city: str = Field(..., description="City")
    province: str = Field(..., description="Province/State")
    postalCode: str = Field(..., description="Postal/ZIP code")
    country: str = Field(..., description="Country")


class Campaign(BaseModel):
    """Campaign/promotion details (denormalized for historical accuracy)."""

    id: str = Field(..., description="Campaign identifier")
    code: str = Field(..., description="Campaign code (e.g., SUMMER2025)")
    description: Optional[str] = Field(None, description="Campaign description")
    discountPercentage: Optional[Decimal] = Field(None, description="Discount percentage")
    productId: Optional[str] = Field(None, description="Associated product ID")
    termsConditionsLink: Optional[str] = Field(None, description="T&C link")
    fromDate: Optional[str] = Field(None, description="Campaign start date")
    toDate: Optional[str] = Field(None, description="Campaign end date")
    isValid: bool = Field(True, description="Campaign validity at order time")
    dateCreated: Optional[str] = Field(None, description="Creation timestamp")
    dateLastUpdated: Optional[str] = Field(None, description="Last update timestamp")
    lastUpdatedBy: Optional[str] = Field(None, description="Last updater")
    active: bool = Field(True, description="Active status")

    class Config:
        """Pydantic model configuration."""
        json_encoders = {
            Decimal: float,
            datetime: lambda v: v.isoformat()
        }


class OrderItem(BaseModel):
    """Order line item."""

    id: str = Field(..., description="Order item identifier")
    productId: str = Field(..., description="Product identifier")
    productName: str = Field(..., description="Product name")
    quantity: int = Field(..., ge=1, description="Quantity ordered")
    unitPrice: Decimal = Field(..., ge=0, description="Unit price")
    discount: Decimal = Field(0, ge=0, description="Discount amount")
    subtotal: Decimal = Field(..., ge=0, description="Line item subtotal")
    dateCreated: str = Field(..., description="Creation timestamp")
    dateLastUpdated: str = Field(..., description="Last update timestamp")
    lastUpdatedBy: str = Field(..., description="Last updater")
    active: bool = Field(True, description="Active status")

    @validator('subtotal', always=True)
    def calculate_subtotal(cls, v, values):
        """Calculate subtotal from quantity, unitPrice, and discount."""
        if 'quantity' in values and 'unitPrice' in values and 'discount' in values:
            return (values['quantity'] * values['unitPrice']) - values['discount']
        return v

    class Config:
        """Pydantic model configuration."""
        json_encoders = {
            Decimal: float,
            datetime: lambda v: v.isoformat()
        }


class Order(BaseModel):
    """
    Order entity representing a customer order.

    This model follows the Activatable Entity Pattern with:
    - Audit fields: dateCreated, dateLastUpdated, lastUpdatedBy
    - Soft delete: active field
    - Optimistic locking: dateLastUpdated
    """

    # Core identifiers
    id: str = Field(..., description="Unique order identifier (UUID)")
    orderNumber: str = Field(..., description="Human-readable order number")
    tenantId: str = Field(..., description="Tenant identifier")

    # Customer information
    customerEmail: str = Field(..., description="Customer email address")

    # Order details
    items: List[OrderItem] = Field(..., description="Order line items")
    subtotal: Decimal = Field(..., ge=0, description="Order subtotal")
    tax: Decimal = Field(0, ge=0, description="Tax amount")
    shipping: Decimal = Field(0, ge=0, description="Shipping cost")
    total: Decimal = Field(..., ge=0, description="Order total")
    currency: str = Field("ZAR", description="Currency code")

    # Status and workflow
    status: OrderStatus = Field(OrderStatus.PENDING, description="Order status")

    # Campaign and billing
    campaign: Optional[Campaign] = Field(None, description="Applied campaign")
    billingAddress: BillingAddress = Field(..., description="Billing address")

    # Payment
    paymentMethod: Optional[str] = Field(None, description="Payment method")
    paymentDetails: Optional[PaymentDetails] = Field(None, description="Payment details")

    # PDF invoice
    pdfUrl: Optional[str] = Field(None, description="S3 URL for PDF invoice")

    # Audit fields (Activatable Entity Pattern)
    dateCreated: str = Field(..., description="Creation timestamp (ISO 8601)")
    dateLastUpdated: str = Field(..., description="Last update timestamp (ISO 8601)")
    lastUpdatedBy: str = Field(..., description="Last updater (email or system)")
    active: bool = Field(True, description="Active status (soft delete)")

    @validator('customerEmail')
    def validate_email(cls, v):
        """Validate email format."""
        if '@' not in v or '.' not in v.split('@')[1]:
            raise ValueError('Invalid email format')
        return v.lower()

    @validator('total', always=True)
    def calculate_total(cls, v, values):
        """Calculate total from subtotal, tax, and shipping."""
        if 'subtotal' in values and 'tax' in values and 'shipping' in values:
            return values['subtotal'] + values['tax'] + values['shipping']
        return v

    class Config:
        """Pydantic model configuration."""
        use_enum_values = True
        json_encoders = {
            Decimal: float,
            datetime: lambda v: v.isoformat()
        }
