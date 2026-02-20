# Update Order Lambda

Worker 4 implementation for the Order Lambda microservice - handles order updates with optimistic locking.

## Overview

**Lambda Function**: `update_order`
**Endpoint**: `PUT /v1.0/orders/{orderId}`
**Purpose**: Update order status and payment details with optimistic locking to prevent concurrent update conflicts.

## Architecture

### Layered Architecture

```
Handler Layer (update_order.py)
    ↓
Service Layer (OrderService)
    ↓
DAO Layer (OrderDAO)
    ↓
DynamoDB
```

### Key Features

- **Optimistic Locking**: Uses `dateLastUpdated` for conditional updates
- **Status Validation**: Enforces valid status transitions
- **Immutable States**: Prevents updates to completed/cancelled/refunded orders
- **Payment Details**: Only allowed for paid/payment_pending orders
- **Tenant Isolation**: Enforces tenant-based access control via JWT

## Request/Response

### Request

**Path**: `PUT /v1.0/orders/{orderId}`

**Headers**:
```
Authorization: Bearer <JWT token>
Content-Type: application/json
```

**Body**:
```json
{
  "status": "paid",
  "paymentDetails": {
    "method": "credit_card",
    "transactionId": "txn-abc123",
    "paidAt": "2025-12-30T11:00:00Z"
  }
}
```

### Response

**Success (200 OK)**:
```json
{
  "success": true,
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "orderNumber": "ORD-2025-00001",
    "status": "paid",
    "paymentDetails": {
      "method": "credit_card",
      "transactionId": "txn-abc123",
      "paidAt": "2025-12-30T11:00:00Z"
    },
    "dateLastUpdated": "2025-12-30T11:00:05Z",
    ...
  }
}
```

**Error Responses**:
- `400 Bad Request`: Invalid request body or business rule violation
- `404 Not Found`: Order not found
- `409 Conflict`: Optimistic locking failure (order modified by another process)
- `500 Internal Server Error`: Unexpected error

## Valid Status Transitions

```
pending → payment_pending, paid, cancelled
payment_pending → paid, cancelled
paid → processing, cancelled
processing → completed, cancelled
```

**Immutable States**: completed, cancelled, refunded (cannot be updated)

## Environment Variables

```bash
DYNAMODB_TABLE_NAME=bbws-customer-portal-orders-{env}
LOG_LEVEL=INFO
AWS_REGION=af-south-1
```

## Setup

### Prerequisites

- Python 3.12
- Docker (for Lambda packaging)
- AWS CLI (for deployment)

### Installation

```bash
# Install dependencies
pip install -r requirements.txt

# Install dev dependencies
pip install -r requirements.txt pytest pytest-cov pytest-mock moto
```

## Testing

### Run All Tests

```bash
pytest
```

### Run Unit Tests Only

```bash
pytest tests/unit/ -v
```

### Run Integration Tests

```bash
pytest tests/integration/ -v
```

### Run with Coverage

```bash
pytest --cov=src --cov-report=html --cov-report=term-missing
```

### Coverage Threshold

- Minimum coverage: **80%**
- Coverage report: `htmlcov/index.html`

## Project Structure

```
worker-4-update-order-lambda/
├── src/
│   ├── handlers/
│   │   ├── __init__.py
│   │   └── update_order.py          # Lambda handler
│   ├── models/
│   │   ├── __init__.py
│   │   ├── order.py                 # Order, OrderItem, PaymentDetails
│   │   ├── requests.py              # UpdateOrderRequest
│   │   └── responses.py             # UpdateOrderResponse
│   ├── dao/
│   │   ├── __init__.py
│   │   └── order_dao.py             # DynamoDB operations
│   ├── services/
│   │   ├── __init__.py
│   │   └── order_service.py         # Business logic
│   └── utils/
│       ├── __init__.py
│       ├── exceptions.py            # Custom exceptions
│       └── logger.py                # Logging configuration
├── tests/
│   ├── unit/
│   │   ├── test_models.py
│   │   ├── test_order_dao.py
│   │   ├── test_order_service.py
│   │   └── test_handler.py
│   ├── integration/
│   │   └── test_update_order_integration.py
│   └── conftest.py                  # Shared fixtures
├── Dockerfile
├── requirements.txt
├── pytest.ini
├── pyproject.toml
├── .dockerignore
├── .gitignore
└── README.md
```

## DynamoDB Schema

### Primary Key Structure

- **PK**: `TENANT#{tenantId}` (Partition Key)
- **SK**: `ORDER#{orderId}` (Sort Key)

### Optimistic Locking

Updates use a conditional expression:
```
ConditionExpression: dateLastUpdated = :expectedLastUpdated
```

If the condition fails, update is rejected with `ConditionalCheckFailedException`, which is mapped to HTTP 409 Conflict.

## Deployment

### Build Docker Image

```bash
docker build -t update-order-lambda:latest .
```

### Test Locally

```bash
# Run tests in Docker
docker run --rm update-order-lambda:latest pytest
```

### Deploy to AWS (via Terraform in Stage 3)

The Lambda function will be deployed using Terraform in Stage 3.

## Key Design Decisions

### 1. Optimistic Locking

**Why**: Prevents lost updates when multiple processes modify the same order concurrently.

**How**:
- Fetch order with current `dateLastUpdated`
- Update with condition: `dateLastUpdated = <fetched_value>`
- If condition fails → 409 Conflict, client must refetch and retry

### 2. Immutable States

**Why**: Prevent accidental modification of finalized orders.

**States**: completed, cancelled, refunded cannot be updated.

### 3. Status Transition Validation

**Why**: Enforce business rules and prevent invalid state changes.

**Example**: Cannot go from `pending` directly to `completed` (must go through `paid` → `processing`).

### 4. Payment Details Restriction

**Why**: Payment details should only be added when order is actually paid.

**Rule**: `paymentDetails` only allowed when status is `paid` or `payment_pending`.

## Error Handling

### Business Exceptions (4xx)

- `OrderNotFoundException` → 404
- `InvalidOrderStateException` → 400
- `OptimisticLockException` → 409

### System Exceptions (5xx)

- `DatabaseException` → 500
- Unhandled exceptions → 500

All errors include structured JSON response:
```json
{
  "success": false,
  "error": "Error Type",
  "message": "Human-readable error message"
}
```

## Logging

Structured logging to CloudWatch:

```python
logger.info(f"Order updated: orderId={order_id}, status={old_status} -> {new_status}")
logger.warning(f"Optimistic lock failure: orderId={order_id}")
logger.error(f"Database error: {error}", exc_info=True)
```

## Performance Considerations

- **Connection Reuse**: DynamoDB client initialized outside handler
- **Single-Table Design**: Efficient queries with composite keys
- **Conditional Updates**: Atomic operations prevent race conditions
- **Minimal Data Transfer**: Only updated fields sent to DynamoDB

## Security

- **Tenant Isolation**: Orders accessed only via PK with tenant ID
- **JWT Authorization**: Tenant ID extracted from Cognito claims
- **Audit Trail**: `lastUpdatedBy` tracks who made changes
- **No Hard-coded Credentials**: All config via environment variables

## Next Steps (Stage 3)

1. Create Terraform module for Lambda deployment
2. Configure API Gateway integration
3. Set up CloudWatch alarms for errors
4. Enable X-Ray tracing
5. Create operational runbooks

## References

- **LLD**: `2.1.8_LLD_Order_Lambda.md`
- **Stage 2 Plan**: `../plan.md`
- **Pydantic Docs**: https://docs.pydantic.dev/1.10/
- **DynamoDB Best Practices**: https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/best-practices.html

---

**Author**: Worker 4 - Update Order Lambda
**Created**: 2025-12-30
**Status**: Implementation Complete
