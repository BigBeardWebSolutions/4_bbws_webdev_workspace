# Worker 5: OrderCreatorRecord Lambda

**Lambda Function**: OrderCreatorRecord
**Trigger**: SQS (bbws-order-creation-{env})
**Target**: DynamoDB (bbws-customer-portal-orders-{env})
**Purpose**: Create order records in DynamoDB (CRITICAL EVENT PROCESSOR)

---

## Overview

The OrderCreatorRecord Lambda is the **most critical function** in the Order Lambda service. It processes SQS messages to create order records in DynamoDB with the following key features:

- **SQS Batch Processing**: Handles up to 10 messages per invocation
- **Atomic Order Numbers**: Sequential order number generation per tenant using DynamoDB atomic counters
- **Cart Integration**: Fetches cart data from Cart Lambda API (currently mocked)
- **Idempotency**: Prevents duplicate orders using conditional writes
- **Partial Batch Failures**: Returns failed message IDs for SQS retry

---

## Architecture

```
SQS Queue → OrderCreatorRecord Lambda → DynamoDB Table
                ↓
         Cart Lambda API (mocked)
```

### Key Components

1. **Lambda Handler** (`src/handlers/order_creator_record.py`)
   - Processes SQS batch events
   - Handles partial batch failures
   - Comprehensive error handling

2. **OrderDAO** (`src/dao/order_dao.py`)
   - DynamoDB single-table design
   - Atomic counter for order numbers
   - Conditional writes for idempotency

3. **CartService** (`src/services/cart_service.py`)
   - **Currently MOCKED** - Returns dummy cart data
   - **Future**: Will make HTTP requests to Cart Lambda API
   - Expected API contract documented in code

4. **Pydantic Models** (`src/models/`)
   - Order, OrderItem, Campaign, BillingAddress, PaymentDetails
   - Full validation and type safety
   - Pydantic v1.10.18 (pure Python, arm64 compatible)

---

## DynamoDB Schema

### Primary Keys

| Key | Pattern | Example |
|-----|---------|---------|
| PK | `TENANT#{tenantId}` | `TENANT#tenant_bb0e8400...` |
| SK | `ORDER#{orderId}` | `ORDER#order_aa0e8400...` |

### Global Secondary Indexes

**GSI1: OrdersByDateIndex** (sort by date)
- GSI1_PK: `TENANT#{tenantId}`
- GSI1_SK: `{dateCreated}#{orderId}`

**GSI2: OrderByIdIndex** (cross-tenant admin lookup)
- GSI2_PK: `ORDER#{orderId}`
- GSI2_SK: `METADATA`

### Access Patterns

| Pattern | Type | Keys | Use Case |
|---------|------|------|----------|
| AP1 | GetItem | PK + SK | Get specific order for tenant |
| AP2 | Query | PK | List all orders for tenant |
| AP3 | Query GSI1 | GSI1_PK + GSI1_SK | List orders by date |
| AP4 | Query GSI2 | GSI2_PK | Admin cross-tenant lookup |
| AP5 | Query + Filter | PK + FilterExpression | Filter by status |

---

## Order Number Generation

Order numbers use an **atomic counter pattern** to ensure uniqueness:

**Format**: `ORD-{YYYYMMDD}-{sequence}`

**Example**: `ORD-20251230-00001`

**Implementation**:
1. Counter stored in DynamoDB with PK=`COUNTER`, SK=`ORDER_NUMBER#{tenantId}#{date}`
2. Atomic increment using `UpdateExpression` with `if_not_exists`
3. Ensures sequential numbers per tenant per day

---

## SQS Message Format

### Input Message

```json
{
  "orderId": "order_550e8400-e29b-41d4-a716-446655440000",
  "tenantId": "tenant_bb0e8400-e29b-41d4-a716-446655440006",
  "customerEmail": "customer@example.com",
  "cartId": "cart_xyz789",
  "campaignCode": "SUMMER2025",
  "campaign": {
    "id": "camp_...",
    "code": "SUMMER2025",
    "discountPercentage": 20.0,
    ...
  },
  "billingAddress": {
    "street": "123 Main Street",
    "city": "Cape Town",
    "province": "Western Cape",
    "postalCode": "8001",
    "country": "ZA"
  },
  "paymentMethod": "payfast"
}
```

### Response (Partial Batch Failures)

```json
{
  "batchItemFailures": [
    {"itemIdentifier": "msg-123"}
  ]
}
```

---

## Error Handling

### Validation Errors
- **Cause**: Invalid message format or missing fields
- **Action**: Add to batch failures for retry
- **Max Retries**: 3 (configured in SQS)
- **DLQ**: Messages sent to dead-letter queue after max retries

### Duplicate Orders
- **Cause**: Order with same orderId already exists
- **Action**: Log warning, do NOT retry (idempotent)
- **Detection**: DynamoDB ConditionalCheckFailedException

### Cart Service Errors
- **Cause**: Cart Lambda API unavailable or returns invalid data
- **Action**: Add to batch failures for retry
- **Retry**: Exponential backoff via SQS redelivery

### DynamoDB Errors
- **Cause**: Throttling, network errors, service unavailable
- **Action**: Add to batch failures for retry
- **Mitigation**: On-demand capacity mode, reserved concurrency

---

## Testing

### Unit Tests

```bash
# Run unit tests
pytest tests/unit/ -v

# Run with coverage
pytest tests/unit/ --cov=src --cov-report=html
```

**Coverage Target**: 80%+

**Test Files**:
- `test_models.py` - Pydantic model validation
- `test_order_dao.py` - DynamoDB operations
- `test_cart_service.py` - Cart service (mocked)
- `test_lambda_handler.py` - Lambda handler logic

### Integration Tests

```bash
# Run integration tests (requires moto)
pytest tests/integration/ -v
```

**Test Files**:
- `test_order_creator_integration.py` - End-to-end flow with mocked DynamoDB

**Mocked Services**:
- DynamoDB (using moto)
- Cart Lambda API (mocked CartService)

---

## Local Development

### Setup

```bash
# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Run tests
pytest
```

### Environment Variables

```bash
export DYNAMODB_TABLE_NAME=bbws-customer-portal-orders-dev
export CART_LAMBDA_API_URL=https://api-dev.bbws.io/v1.0/cart
export LOG_LEVEL=INFO
export AWS_REGION=af-south-1
```

---

## Docker Packaging

### Build Image

```bash
docker build -t order-creator-record:latest .
```

### Test Locally

```bash
docker run -p 9000:8080 \
  -e DYNAMODB_TABLE_NAME=bbws-customer-portal-orders-dev \
  -e CART_LAMBDA_API_URL=https://api-dev.bbws.io/v1.0/cart \
  order-creator-record:latest
```

### Invoke Lambda

```bash
curl -X POST "http://localhost:9000/2015-03-31/functions/function/invocations" \
  -d @tests/fixtures/sample_sqs_event.json
```

---

## Deployment

Deployment is handled by Terraform (Stage 3). This Lambda will be deployed with:

- **Memory**: 512 MB
- **Timeout**: 30 seconds
- **Concurrency**: Reserved concurrency of 5 (prevent DynamoDB throttling)
- **Architecture**: arm64
- **Runtime**: Python 3.12
- **Trigger**: SQS with batch size 10, batch window 5s

---

## Dependencies

### Cart Lambda API Contract (Future Implementation)

**Endpoint**: `GET /v1.0/carts/{cartId}`

**Query Parameters**: `tenantId={tenantId}`

**Response**:
```json
{
  "cartId": "string",
  "tenantId": "string",
  "items": [
    {
      "id": "string",
      "productId": "string",
      "productName": "string",
      "quantity": number,
      "unitPrice": number,
      "discount": number,
      "subtotal": number
    }
  ],
  "subtotal": number,
  "tax": number,
  "total": number,
  "currency": "string"
}
```

**Current Status**: MOCKED in `src/services/cart_service.py`

---

## Monitoring

### CloudWatch Metrics
- Lambda invocations
- Lambda errors
- Lambda duration
- SQS messages processed
- DynamoDB write capacity

### CloudWatch Alarms
- High error rate (> 5%)
- High duration (> 25s)
- DLQ depth (> 0 messages)
- Throttling events

### Logs
- Structured JSON logs
- Request ID correlation
- Order ID and tenant ID in context

---

## Known Limitations

1. **Cart Lambda API**: Currently mocked, requires actual implementation
2. **Campaign Validation**: Campaign data is denormalized from message, not validated against Campaign Lambda
3. **Tax Calculation**: Currently uses tax amount from cart, doesn't recalculate

---

## Future Enhancements

1. Implement actual Cart Lambda API client with HTTP requests
2. Add campaign validation against Campaign Lambda
3. Add tax recalculation based on billing address
4. Add order total validation against payment gateway
5. Add webhook for order creation notifications

---

**Status**: ✅ READY FOR TESTING
**Test Coverage**: 80%+
**Last Updated**: 2025-12-30
