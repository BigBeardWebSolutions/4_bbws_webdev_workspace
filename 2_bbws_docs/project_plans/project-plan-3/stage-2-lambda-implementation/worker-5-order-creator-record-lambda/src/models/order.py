"""
Order model for Order Lambda service.
"""

from typing import List, Optional
from datetime import datetime
from pydantic import BaseModel, Field, validator

from .order_item import OrderItem
from .campaign import Campaign
from .billing_address import BillingAddress
from .payment_details import PaymentDetails


class Order(BaseModel):
    """
    Order model representing a customer order.

    Attributes:
        id: Unique order identifier (UUID)
        orderNumber: Human-readable order number (e.g., ORD-20251215-0001)
        tenantId: Tenant UUID
        customerEmail: Customer email address
        items: Array of OrderItem objects
        subtotal: Subtotal amount (sum of all item subtotals)
        tax: Tax amount
        total: Total amount (subtotal + tax)
        currency: Currency code (e.g., ZAR, USD)
        status: Order status enum
        campaign: Embedded Campaign object (denormalized, optional)
        billingAddress: Billing address object
        paymentMethod: Payment method (e.g., payfast)
        paymentDetails: Payment transaction details (optional)
        dateCreated: ISO 8601 timestamp
        dateLastUpdated: ISO 8601 timestamp
        lastUpdatedBy: User/system identifier who last updated
        active: Soft delete flag (true = active, false = deleted)
    """

    id: str = Field(..., description="Unique order identifier (UUID)")
    orderNumber: str = Field(..., description="Human-readable order number")
    tenantId: str = Field(..., description="Tenant UUID")
    customerEmail: str = Field(..., description="Customer email address")
    items: List[OrderItem] = Field(..., description="Array of OrderItem objects", min_items=1)
    subtotal: float = Field(..., description="Subtotal amount", ge=0.0)
    tax: float = Field(..., description="Tax amount", ge=0.0)
    total: float = Field(..., description="Total amount", ge=0.0)
    currency: str = Field(..., description="Currency code (ISO 4217)", min_length=3, max_length=3)
    status: str = Field(
        default="PENDING_PAYMENT",
        description="Order status",
        regex="^(PENDING_PAYMENT|PAID|PROCESSING|COMPLETED|CANCELLED|REFUNDED)$"
    )
    campaign: Optional[Campaign] = Field(None, description="Embedded Campaign object (optional)")
    billingAddress: BillingAddress = Field(..., description="Billing address object")
    paymentMethod: str = Field(..., description="Payment method", min_length=1, max_length=50)
    paymentDetails: Optional[PaymentDetails] = Field(None, description="Payment transaction details (optional)")
    dateCreated: str = Field(..., description="ISO 8601 timestamp")
    dateLastUpdated: str = Field(..., description="ISO 8601 timestamp")
    lastUpdatedBy: str = Field(..., description="User/system identifier")
    active: bool = Field(default=True, description="Soft delete flag")

    @validator('customerEmail')
    def validate_email(cls, v):
        """Validate email format."""
        if '@' not in v or '.' not in v.split('@')[1]:
            raise ValueError('Invalid email format')
        return v

    @validator('currency')
    def validate_currency(cls, v):
        """Validate currency code is uppercase."""
        if not v.isupper():
            raise ValueError('Currency code must be uppercase (e.g., ZAR, USD)')
        return v

    @validator('dateCreated', 'dateLastUpdated')
    def validate_iso_date(cls, v):
        """Validate ISO 8601 date format."""
        try:
            datetime.fromisoformat(v.replace('Z', '+00:00'))
        except ValueError:
            raise ValueError(f'Invalid ISO 8601 date format: {v}')
        return v

    @validator('total')
    def validate_total(cls, v, values):
        """Validate total calculation."""
        if 'subtotal' in values and 'tax' in values:
            expected_total = values['subtotal'] + values['tax']
            if abs(v - expected_total) > 0.01:  # Allow small floating point differences
                raise ValueError(f'Total {v} does not match subtotal + tax: {expected_total}')
        return v

    @validator('subtotal')
    def validate_subtotal_matches_items(cls, v, values):
        """Validate subtotal matches sum of item subtotals."""
        if 'items' in values:
            items_total = sum(item.subtotal for item in values['items'])
            if abs(v - items_total) > 0.01:  # Allow small floating point differences
                raise ValueError(f'Subtotal {v} does not match sum of items: {items_total}')
        return v

    def to_dynamodb_item(self) -> dict:
        """
        Convert Order to DynamoDB item format.

        Returns:
            Dictionary with DynamoDB item structure including PK/SK and GSI keys.
        """
        item = {
            'PK': f'TENANT#{self.tenantId}',
            'SK': f'ORDER#{self.id}',
            'entityType': 'ORDER',
            'id': self.id,
            'orderNumber': self.orderNumber,
            'tenantId': self.tenantId,
            'customerEmail': self.customerEmail,
            'items': [item.dict() for item in self.items],
            'subtotal': self.subtotal,
            'tax': self.tax,
            'total': self.total,
            'currency': self.currency,
            'status': self.status,
            'billingAddress': self.billingAddress.dict(),
            'paymentMethod': self.paymentMethod,
            'dateCreated': self.dateCreated,
            'dateLastUpdated': self.dateLastUpdated,
            'lastUpdatedBy': self.lastUpdatedBy,
            'active': self.active,
            'GSI1_PK': f'TENANT#{self.tenantId}',
            'GSI1_SK': f'{self.dateCreated}#{self.id}',
            'GSI2_PK': f'ORDER#{self.id}',
            'GSI2_SK': 'METADATA'
        }

        # Add optional fields
        if self.campaign:
            item['campaign'] = self.campaign.dict()
        if self.paymentDetails:
            item['paymentDetails'] = self.paymentDetails.dict()

        return item

    class Config:
        """Pydantic model configuration."""
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }
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
                "billingAddress": {
                    "street": "123 Main Street",
                    "city": "Cape Town",
                    "province": "Western Cape",
                    "postalCode": "8001",
                    "country": "ZA"
                },
                "paymentMethod": "payfast",
                "dateCreated": "2025-12-19T10:30:00Z",
                "dateLastUpdated": "2025-12-19T10:30:00Z",
                "lastUpdatedBy": "customer@example.com",
                "active": True
            }
        }
