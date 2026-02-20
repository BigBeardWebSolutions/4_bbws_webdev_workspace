"""
Pytest configuration and shared fixtures.
"""

import pytest
from datetime import datetime
import uuid


@pytest.fixture
def sample_order_id():
    """Sample order ID."""
    return f"order_{uuid.uuid4()}"


@pytest.fixture
def sample_tenant_id():
    """Sample tenant ID."""
    return f"tenant_{uuid.uuid4()}"


@pytest.fixture
def sample_cart_id():
    """Sample cart ID."""
    return f"cart_{uuid.uuid4()}"


@pytest.fixture
def sample_billing_address():
    """Sample billing address data."""
    return {
        "street": "123 Main Street",
        "city": "Cape Town",
        "province": "Western Cape",
        "postalCode": "8001",
        "country": "ZA"
    }


@pytest.fixture
def sample_campaign():
    """Sample campaign data."""
    return {
        "id": f"camp_{uuid.uuid4()}",
        "code": "SUMMER2025",
        "description": "Summer 2025 Special Offer - 20% off all WordPress plans",
        "discountPercentage": 20.0,
        "productId": f"prod_{uuid.uuid4()}",
        "termsConditionsLink": "https://kimmyai.io/terms/campaigns/summer2025",
        "fromDate": "2025-06-01",
        "toDate": "2025-08-31",
        "isValid": True,
        "dateCreated": "2025-05-01T08:00:00Z",
        "dateLastUpdated": "2025-05-01T08:00:00Z",
        "lastUpdatedBy": "admin@kimmyai.io",
        "active": True
    }


@pytest.fixture
def sample_cart_item():
    """Sample cart item data."""
    now = datetime.utcnow().isoformat() + "Z"
    return {
        "id": f"item_{uuid.uuid4()}",
        "productId": f"prod_{uuid.uuid4()}",
        "productName": "WordPress Professional Plan",
        "quantity": 1,
        "unitPrice": 299.99,
        "discount": 60.00,
        "subtotal": 239.99,
        "dateCreated": now,
        "dateLastUpdated": now,
        "lastUpdatedBy": "system",
        "active": True
    }


@pytest.fixture
def sample_cart_data(sample_cart_id, sample_tenant_id, sample_cart_item):
    """Sample cart data."""
    return {
        "cartId": sample_cart_id,
        "tenantId": sample_tenant_id,
        "items": [sample_cart_item],
        "subtotal": 239.99,
        "tax": 35.99,
        "total": 275.98,
        "currency": "ZAR"
    }


@pytest.fixture
def sample_sqs_message(sample_order_id, sample_tenant_id, sample_cart_id, sample_billing_address):
    """Sample SQS message body."""
    return {
        "orderId": sample_order_id,
        "tenantId": sample_tenant_id,
        "customerEmail": "customer@example.com",
        "cartId": sample_cart_id,
        "billingAddress": sample_billing_address,
        "paymentMethod": "payfast"
    }


@pytest.fixture
def sample_sqs_event(sample_sqs_message):
    """Sample SQS event."""
    import json
    return {
        "Records": [
            {
                "messageId": "msg-123",
                "receiptHandle": "receipt-123",
                "body": json.dumps(sample_sqs_message),
                "attributes": {
                    "ApproximateReceiveCount": "1",
                    "SentTimestamp": "1640000000000",
                    "SenderId": "AIDAIT2UOQQY3AUEKVGXU",
                    "ApproximateFirstReceiveTimestamp": "1640000000000"
                },
                "messageAttributes": {},
                "md5OfBody": "md5hash",
                "eventSource": "aws:sqs",
                "eventSourceARN": "arn:aws:sqs:us-east-1:123456789012:order-creation-queue",
                "awsRegion": "us-east-1"
            }
        ]
    }


@pytest.fixture
def sample_order_data(sample_order_id, sample_tenant_id, sample_cart_item, sample_billing_address):
    """Sample order data."""
    now = datetime.utcnow().isoformat() + "Z"
    return {
        "id": sample_order_id,
        "orderNumber": "ORD-20251230-00001",
        "tenantId": sample_tenant_id,
        "customerEmail": "customer@example.com",
        "items": [sample_cart_item],
        "subtotal": 239.99,
        "tax": 35.99,
        "total": 275.98,
        "currency": "ZAR",
        "status": "PENDING_PAYMENT",
        "billingAddress": sample_billing_address,
        "paymentMethod": "payfast",
        "dateCreated": now,
        "dateLastUpdated": now,
        "lastUpdatedBy": "customer@example.com",
        "active": True
    }
