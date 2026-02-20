"""
Pytest configuration and shared fixtures.
"""
import pytest
from decimal import Decimal
from typing import Dict, Any


@pytest.fixture
def sample_order_data() -> Dict[str, Any]:
    """Sample order data for testing."""
    return {
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
                "unitPrice": Decimal("299.99"),
                "discount": Decimal("60.00"),
                "subtotal": Decimal("239.99"),
                "dateCreated": "2025-12-19T10:30:00Z",
                "dateLastUpdated": "2025-12-19T10:30:00Z",
                "lastUpdatedBy": "system",
                "active": True
            }
        ],
        "subtotal": Decimal("239.99"),
        "tax": Decimal("35.99"),
        "total": Decimal("275.98"),
        "currency": "ZAR",
        "status": "PENDING_PAYMENT",
        "campaign": {
            "id": "camp_770e8400-e29b-41d4-a716-446655440002",
            "code": "SUMMER2025",
            "description": "Summer 2025 Special Offer - 20% off all WordPress plans",
            "discountPercentage": Decimal("20.0"),
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


@pytest.fixture
def sample_dynamodb_item() -> Dict[str, Any]:
    """Sample DynamoDB item with type annotations."""
    return {
        "PK": {"S": "TENANT#tenant_bb0e8400-e29b-41d4-a716-446655440006"},
        "SK": {"S": "ORDER#order_aa0e8400-e29b-41d4-a716-446655440005"},
        "entityType": {"S": "ORDER"},
        "id": {"S": "order_aa0e8400-e29b-41d4-a716-446655440005"},
        "orderNumber": {"S": "ORD-20251215-0001"},
        "tenantId": {"S": "tenant_bb0e8400-e29b-41d4-a716-446655440006"},
        "customerEmail": {"S": "customer@example.com"},
        "items": {
            "L": [
                {
                    "M": {
                        "id": {"S": "item_cc0e8400-e29b-41d4-a716-446655440007"},
                        "productId": {"S": "prod_550e8400-e29b-41d4-a716-446655440000"},
                        "productName": {"S": "WordPress Professional Plan"},
                        "quantity": {"N": "1"},
                        "unitPrice": {"N": "299.99"},
                        "discount": {"N": "60.00"},
                        "subtotal": {"N": "239.99"},
                        "dateCreated": {"S": "2025-12-19T10:30:00Z"},
                        "dateLastUpdated": {"S": "2025-12-19T10:30:00Z"},
                        "lastUpdatedBy": {"S": "system"},
                        "active": {"BOOL": True}
                    }
                }
            ]
        },
        "subtotal": {"N": "239.99"},
        "tax": {"N": "35.99"},
        "total": {"N": "275.98"},
        "currency": {"S": "ZAR"},
        "status": {"S": "PENDING_PAYMENT"},
        "campaign": {
            "M": {
                "id": {"S": "camp_770e8400-e29b-41d4-a716-446655440002"},
                "code": {"S": "SUMMER2025"},
                "description": {"S": "Summer 2025 Special Offer - 20% off all WordPress plans"},
                "discountPercentage": {"N": "20.0"},
                "productId": {"S": "prod_550e8400-e29b-41d4-a716-446655440000"},
                "termsConditionsLink": {"S": "https://kimmyai.io/terms/campaigns/summer2025"},
                "fromDate": {"S": "2025-06-01"},
                "toDate": {"S": "2025-08-31"},
                "isValid": {"BOOL": True},
                "dateCreated": {"S": "2025-05-01T08:00:00Z"},
                "dateLastUpdated": {"S": "2025-05-01T08:00:00Z"},
                "lastUpdatedBy": {"S": "admin@kimmyai.io"},
                "active": {"BOOL": True}
            }
        },
        "billingAddress": {
            "M": {
                "street": {"S": "123 Main Street"},
                "city": {"S": "Cape Town"},
                "province": {"S": "Western Cape"},
                "postalCode": {"S": "8001"},
                "country": {"S": "ZA"}
            }
        },
        "paymentMethod": {"S": "payfast"},
        "paymentDetails": {"NULL": True},
        "dateCreated": {"S": "2025-12-19T10:30:00Z"},
        "dateLastUpdated": {"S": "2025-12-19T10:30:00Z"},
        "lastUpdatedBy": {"S": "customer@example.com"},
        "active": {"BOOL": True},
        "GSI1_PK": {"S": "TENANT#tenant_bb0e8400-e29b-41d4-a716-446655440006"},
        "GSI1_SK": {"S": "2025-12-19T10:30:00Z#order_aa0e8400-e29b-41d4-a716-446655440005"},
        "GSI2_PK": {"S": "ORDER#order_aa0e8400-e29b-41d4-a716-446655440005"},
        "GSI2_SK": {"S": "METADATA"}
    }


@pytest.fixture
def sample_api_gateway_event() -> Dict[str, Any]:
    """Sample API Gateway event for GET /v1.0/orders/{orderId}."""
    return {
        "resource": "/v1.0/orders/{orderId}",
        "path": "/v1.0/orders/order_aa0e8400-e29b-41d4-a716-446655440005",
        "httpMethod": "GET",
        "pathParameters": {
            "orderId": "order_aa0e8400-e29b-41d4-a716-446655440005"
        },
        "requestContext": {
            "authorizer": {
                "claims": {
                    "sub": "user-uuid",
                    "email": "customer@example.com",
                    "custom:tenantId": "tenant_bb0e8400-e29b-41d4-a716-446655440006"
                }
            },
            "requestId": "request-uuid"
        }
    }
