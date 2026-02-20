# get_order Lambda Function

Lambda function for retrieving order details from DynamoDB.

## Overview

- **Endpoint**: `GET /v1.0/orders/{orderId}`
- **Purpose**: Query DynamoDB by orderId with tenant isolation
- **Runtime**: Python 3.12 (arm64)
- **Memory**: 512MB
- **Timeout**: 30s

## Architecture

```
API Gateway → Lambda Handler → OrderDAO → DynamoDB
                ↓
           Pydantic Models
```

## Features

- Tenant isolation via JWT token validation
- DynamoDB single-table design (PK+SK query)
- Pydantic v1.10.18 data validation
- Comprehensive error handling
- CORS support
- Structured logging

## Project Structure

```
worker-2-get-order-lambda/
├── src/
│   ├── handlers/
│   │   └── get_order.py          # Lambda handler
│   ├── models/
│   │   ├── order.py               # Order Pydantic model
│   │   ├── order_item.py          # OrderItem model
│   │   ├── campaign.py            # Campaign model
│   │   ├── billing_address.py     # BillingAddress model
│   │   └── payment_details.py     # PaymentDetails model
│   └── dao/
│       └── order_dao.py           # Data Access Object
├── tests/
│   ├── unit/                      # Unit tests
│   ├── integration/               # Integration tests
│   └── conftest.py                # Shared fixtures
├── Dockerfile                      # Lambda packaging
├── requirements.txt                # Python dependencies
├── pytest.ini                      # Pytest configuration
└── README.md                       # This file
```

## Local Development

### Prerequisites

- Python 3.12
- pip
- virtualenv (recommended)

### Setup

```bash
# Create virtual environment
python3.12 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Run tests
pytest

# Run tests with coverage
pytest --cov=src --cov-report=html
```

### Environment Variables

```bash
DYNAMODB_TABLE_NAME=bbws-customer-portal-orders-dev
LOG_LEVEL=INFO
AWS_REGION=af-south-1
```

## Testing

### Unit Tests

```bash
# Run unit tests only
pytest tests/unit/ -v

# Run with coverage
pytest tests/unit/ --cov=src --cov-report=term-missing
```

### Integration Tests

```bash
# Run integration tests (uses moto for DynamoDB mocking)
pytest tests/integration/ -v
```

### All Tests

```bash
# Run all tests with coverage (minimum 80%)
pytest --cov=src --cov-fail-under=80
```

## API Contract

### Request

```http
GET /v1.0/orders/{orderId}
Authorization: Bearer <JWT_TOKEN>
```

**Path Parameters:**
- `orderId` (string, required): Order identifier

**Headers:**
- `Authorization` (string, required): JWT token with `custom:tenantId` claim

### Response

**Success (200 OK):**

```json
{
  "success": true,
  "data": {
    "id": "order_aa0e8400-e29b-41d4-a716-446655440005",
    "orderNumber": "ORD-20251215-0001",
    "tenantId": "tenant_bb0e8400-e29b-41d4-a716-446655440006",
    "customerEmail": "customer@example.com",
    "items": [...],
    "subtotal": 239.99,
    "tax": 35.99,
    "total": 275.98,
    "currency": "ZAR",
    "status": "PENDING_PAYMENT",
    "campaign": {...},
    "billingAddress": {...},
    "paymentMethod": "payfast",
    "paymentDetails": null,
    "dateCreated": "2025-12-19T10:30:00Z",
    "dateLastUpdated": "2025-12-19T10:30:00Z",
    "lastUpdatedBy": "customer@example.com",
    "active": true
  }
}
```

**Error Responses:**

- `400 Bad Request`: Missing orderId
- `401 Unauthorized`: Missing tenantId in JWT
- `404 Not Found`: Order not found or tenant mismatch
- `500 Internal Server Error`: Unexpected error

## DynamoDB Access Pattern

**Access Pattern AP1**: Get specific order for a tenant

**Query:**
```python
PK = "TENANT#{tenantId}"
SK = "ORDER#{orderId}"
```

**Example:**
```python
PK = "TENANT#tenant_bb0e8400-e29b-41d4-a716-446655440006"
SK = "ORDER#order_aa0e8400-e29b-41d4-a716-446655440005"
```

## Docker Packaging

### Build Docker Image

```bash
docker build -t get-order-lambda .
```

### Test Docker Image Locally

```bash
docker run -p 9000:8080 \
  -e DYNAMODB_TABLE_NAME=bbws-customer-portal-orders-dev \
  -e AWS_REGION=af-south-1 \
  get-order-lambda
```

### Invoke Lambda Locally

```bash
curl -XPOST "http://localhost:9000/2015-03-31/functions/function/invocations" \
  -d '{
    "pathParameters": {"orderId": "order_123"},
    "requestContext": {
      "authorizer": {
        "claims": {"custom:tenantId": "tenant_456"}
      }
    }
  }'
```

## Deployment

This Lambda function is deployed via Terraform in Stage 3.

**Terraform Module**: `stage-3-infrastructure/worker-2-lambda-terraform/`

**Environment-specific deployment:**
```bash
# DEV
terraform apply -var-file=environments/dev.tfvars

# SIT
terraform apply -var-file=environments/sit.tfvars

# PROD (manual approval required)
terraform apply -var-file=environments/prod.tfvars
```

## Monitoring

### CloudWatch Logs

```bash
aws logs tail /aws/lambda/get-order-dev --follow
```

### CloudWatch Metrics

- `Invocations`: Number of invocations
- `Duration`: Execution time
- `Errors`: Error count
- `Throttles`: Throttling events

### Alarms

- Lambda errors > 1% of invocations
- Lambda duration > 25s (approaching timeout)
- DynamoDB read throttling

## Security

- **Tenant Isolation**: Orders queried by PK=TENANT#{tenantId}
- **JWT Validation**: API Gateway validates JWT tokens
- **IAM Permissions**: Lambda has minimal DynamoDB read permissions
- **Encryption**: DynamoDB encryption at rest enabled
- **HTTPS**: All API calls over HTTPS only

## Troubleshooting

### Order Not Found

1. Verify orderId exists in DynamoDB
2. Check tenantId matches (tenant isolation)
3. Verify order is active (active=true)

### Timeout Errors

1. Check DynamoDB query performance
2. Verify table has on-demand capacity
3. Review Lambda memory allocation

### Permission Errors

1. Verify Lambda IAM role has DynamoDB read permissions
2. Check table name environment variable

## Contributing

1. Write tests first (TDD)
2. Ensure 80%+ coverage
3. Follow PEP 8 style guide
4. Add type hints
5. Document public functions

## License

Internal BBWS project - Proprietary
