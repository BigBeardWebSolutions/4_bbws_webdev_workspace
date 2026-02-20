"""
Pytest configuration and shared fixtures.

Provides common test fixtures for unit and integration tests.
"""

import pytest
from datetime import datetime
from src.models.order import Order
from src.models.order_item import OrderItem
from src.models.billing_address import BillingAddress
from src.models.campaign import Campaign
from src.models.payment_details import PaymentDetails


@pytest.fixture
def sample_billing_address():
    """Sample billing address for testing."""
    return BillingAddress(
        fullName="John Doe",
        addressLine1="123 Main Street",
        addressLine2="Apt 4B",
        city="Cape Town",
        stateProvince="Western Cape",
        postalCode="8001",
        country="ZA",
        phoneNumber="+27123456789"
    )


@pytest.fixture
def sample_order_item():
    """Sample order item for testing."""
    return OrderItem(
        productId="prod-123",
        productName="Premium WordPress Theme",
        productSku="WP-THEME-001",
        quantity=1,
        unitPrice=99.00,
        currency="ZAR",
        subtotal=99.00,
        taxRate=0.15,
        taxAmount=14.85,
        total=113.85,
        imageUrl="https://example.com/images/theme.jpg",
        description="Professional WordPress theme"
    )


@pytest.fixture
def sample_campaign():
    """Sample campaign for testing."""
    return Campaign(
        id="camp-123",
        code="SUMMER2025",
        name="Summer Sale 2025",
        discountType="percentage",
        discountValue=15.0,
        startDate=datetime(2025, 6, 1),
        endDate=datetime(2025, 8, 31),
        isActive=True
    )


@pytest.fixture
def sample_payment_details():
    """Sample payment details for testing."""
    return PaymentDetails(
        method="credit_card",
        transactionId="txn-abc123xyz",
        paidAt=datetime(2025, 12, 30, 12, 0, 0),
        amount=250.00,
        currency="ZAR",
        status="completed"
    )


@pytest.fixture
def sample_order(sample_billing_address, sample_order_item):
    """Sample complete order for testing."""
    return Order(
        id="550e8400-e29b-41d4-a716-446655440000",
        orderNumber="ORD-2025-00001",
        tenantId="tenant-123",
        customerId="cust-456",
        customerEmail="customer@example.com",
        customerName="John Doe",
        status="paid",
        items=[sample_order_item],
        subtotal=99.00,
        taxAmount=14.85,
        shippingAmount=0.00,
        discountAmount=0.00,
        total=113.85,
        currency="ZAR",
        billingAddress=sample_billing_address,
        isActive=True,
        dateCreated=datetime(2025, 12, 30, 10, 30, 0),
        dateLastUpdated=datetime(2025, 12, 30, 10, 30, 0)
    )


@pytest.fixture
def sqs_event_single_message():
    """Sample SQS event with single message."""
    return {
        "Records": [
            {
                "messageId": "msg-123",
                "receiptHandle": "receipt-123",
                "body": '{"orderId": "550e8400-e29b-41d4-a716-446655440000", "tenantId": "tenant-123"}',
                "attributes": {
                    "ApproximateReceiveCount": "1",
                    "SentTimestamp": "1640000000000"
                },
                "messageAttributes": {}
            }
        ]
    }


@pytest.fixture
def sqs_event_batch_messages():
    """Sample SQS event with multiple messages."""
    return {
        "Records": [
            {
                "messageId": "msg-1",
                "receiptHandle": "receipt-1",
                "body": '{"orderId": "order-1", "tenantId": "tenant-1"}',
                "attributes": {},
                "messageAttributes": {}
            },
            {
                "messageId": "msg-2",
                "receiptHandle": "receipt-2",
                "body": '{"orderId": "order-2", "tenantId": "tenant-2"}',
                "attributes": {},
                "messageAttributes": {}
            }
        ]
    }


@pytest.fixture
def mock_dynamodb_client(mocker):
    """Mock DynamoDB client."""
    return mocker.MagicMock()


@pytest.fixture
def mock_s3_client(mocker):
    """Mock S3 client."""
    return mocker.MagicMock()


@pytest.fixture
def lambda_context():
    """Mock Lambda context."""
    class LambdaContext:
        function_name = "order-pdf-creator"
        memory_limit_in_mb = 512
        invoked_function_arn = "arn:aws:lambda:af-south-1:123456789012:function:order-pdf-creator"
        aws_request_id = "request-123"

    return LambdaContext()
