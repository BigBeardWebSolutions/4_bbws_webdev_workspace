"""Shared test fixtures for update_order Lambda tests."""

from datetime import datetime
from decimal import Decimal
from typing import Dict, Any

import pytest

from src.models.order import (
    Order,
    OrderItem,
    Campaign,
    BillingAddress,
    PaymentDetails,
    OrderStatus
)


@pytest.fixture
def sample_order_item() -> OrderItem:
    """Create a sample order item for testing."""
    return OrderItem(
        id="item-123",
        productId="prod-456",
        productName="WordPress Hosting - Premium",
        quantity=1,
        unitPrice=Decimal("299.00"),
        discount=Decimal("0.00"),
        subtotal=Decimal("299.00"),
        dateCreated="2025-12-30T10:00:00Z",
        dateLastUpdated="2025-12-30T10:00:00Z",
        lastUpdatedBy="system",
        active=True
    )


@pytest.fixture
def sample_billing_address() -> BillingAddress:
    """Create a sample billing address for testing."""
    return BillingAddress(
        street="123 Main St",
        city="Cape Town",
        province="Western Cape",
        postalCode="8001",
        country="South Africa"
    )


@pytest.fixture
def sample_campaign() -> Campaign:
    """Create a sample campaign for testing."""
    return Campaign(
        id="camp-789",
        code="SUMMER2025",
        description="Summer discount",
        discountPercentage=Decimal("10.00"),
        productId="prod-456",
        termsConditionsLink="https://example.com/terms",
        fromDate="2025-12-01T00:00:00Z",
        toDate="2026-01-31T23:59:59Z",
        isValid=True,
        dateCreated="2025-12-01T00:00:00Z",
        dateLastUpdated="2025-12-01T00:00:00Z",
        lastUpdatedBy="admin@example.com",
        active=True
    )


@pytest.fixture
def sample_payment_details() -> PaymentDetails:
    """Create sample payment details for testing."""
    return PaymentDetails(
        method="credit_card",
        transactionId="txn-abc123",
        payfastPaymentId="pf-xyz789",
        paidAt="2025-12-30T11:00:00Z"
    )


@pytest.fixture
def sample_order(
    sample_order_item: OrderItem,
    sample_billing_address: BillingAddress,
    sample_campaign: Campaign
) -> Order:
    """Create a sample order for testing."""
    return Order(
        id="550e8400-e29b-41d4-a716-446655440000",
        orderNumber="ORD-2025-00001",
        tenantId="tenant-123",
        customerEmail="customer@example.com",
        items=[sample_order_item],
        subtotal=Decimal("299.00"),
        tax=Decimal("0.00"),
        shipping=Decimal("0.00"),
        total=Decimal("299.00"),
        currency="ZAR",
        status=OrderStatus.PENDING,
        campaign=sample_campaign,
        billingAddress=sample_billing_address,
        paymentMethod=None,
        paymentDetails=None,
        pdfUrl=None,
        dateCreated="2025-12-30T10:00:00Z",
        dateLastUpdated="2025-12-30T10:00:00Z",
        lastUpdatedBy="system",
        active=True
    )


@pytest.fixture
def mock_dynamodb_client(mocker):
    """Create a mock DynamoDB client."""
    return mocker.MagicMock()


@pytest.fixture
def api_gateway_event() -> Dict[str, Any]:
    """Create a sample API Gateway event for testing."""
    return {
        'httpMethod': 'PUT',
        'path': '/v1.0/orders/550e8400-e29b-41d4-a716-446655440000',
        'pathParameters': {
            'orderId': '550e8400-e29b-41d4-a716-446655440000'
        },
        'body': '{"status": "paid", "paymentDetails": {"method": "credit_card", "transactionId": "txn-123"}}',
        'requestContext': {
            'authorizer': {
                'claims': {
                    'custom:tenantId': 'tenant-123',
                    'email': 'user@example.com'
                }
            }
        },
        'headers': {
            'Content-Type': 'application/json'
        }
    }


@pytest.fixture
def lambda_context(mocker):
    """Create a mock Lambda context."""
    context = mocker.MagicMock()
    context.function_name = 'update_order'
    context.invoked_function_arn = 'arn:aws:lambda:af-south-1:123456789012:function:update_order'
    context.aws_request_id = 'request-123'
    return context
