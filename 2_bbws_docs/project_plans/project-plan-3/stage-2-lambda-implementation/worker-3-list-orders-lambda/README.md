# List Orders Lambda (Worker 3)

## Overview

This Lambda function implements the `list_orders` endpoint for the Order Lambda microservice. It retrieves all orders for a specific tenant with pagination support, using DynamoDB single-table design patterns with tenant isolation.

## API Specification

### Endpoint

```
GET /v1.0/tenants/{tenantId}/orders
```

### Request Parameters

#### Path Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `tenantId` | string (UUID) | Yes | The tenant identifier |

#### Query Parameters

| Parameter | Type | Required | Default | Max | Description |
|-----------|------|----------|---------|-----|-------------|
| `pageSize` | integer | No | 50 | 100 | Number of orders to return per page |
| `startAt` | string | No | null | N/A | Pagination continuation token from previous response |

### Response Format

#### Success Response (200 OK)

```json
{
  "success": true,
  "data": {
    "items": [
      {
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
        "billingAddress": {...},
        "paymentMethod": "payfast",
        "paymentDetails": null,
        "campaign": {...},
        "dateCreated": "2025-12-19T10:30:00Z",
        "dateLastUpdated": "2025-12-19T10:30:00Z",
        "lastUpdatedBy": "customer@example.com",
        "active": true
      }
    ],
    "startAt": "eyJQSyI6IHsiUyI6ICJURVnBTlQjdGVuYW50X2JiMGU4NDAwLWUyOWItNDFkNC1hNzE2LTQ0NjY1NTQ0MDAwNiJ9LCAiU0siOiB7IlMiOiAiT1JERVIjb3JkZXJfY2MwZTg0MDAtZTI5Yi00MWQ0LWE3MTYtNDQ2NjU1NDQwMDEwIn19",
    "moreAvailable": true
  }
}
```

#### Error Responses

**400 Bad Request** - Invalid request parameters

```json
{
  "error": "Bad Request",
  "message": "pageSize must be between 1 and 100"
}
```

**500 Internal Server Error** - Unexpected server error

```json
{
  "error": "Internal Server Error",
  "message": "An unexpected error occurred"
}
```

## Implementation Details

### Architecture

```
API Gateway Event
    ↓
lambda_handler()
    ├─ Extract pathParameters.tenantId
    ├─ Parse queryStringParameters (pageSize, startAt)
    ├─ Validate parameters
    ↓
OrderDAO.find_by_tenant_id()
    ├─ DynamoDB Query: PK=TENANT#{tenantId}, SK begins_with ORDER#
    ├─ Apply Limit and ExclusiveStartKey for pagination
    ├─ Sort by SK descending (newest first)
    ↓
Deserialize DynamoDB items → Order objects
    ↓
Build pagination response
    └─ Return {items, startAt, moreAvailable}
```

### DynamoDB Access Pattern (AP2)

**List all orders for a tenant with pagination**

```
Query:
  TableName: bbws-customer-portal-orders-{env}
  KeyConditionExpression: PK = :pk AND begins_with(SK, :sk_prefix)
  ExpressionAttributeValues:
    :pk = 'TENANT#{tenantId}'
    :sk_prefix = 'ORDER#'
  Limit: pageSize
  ExclusiveStartKey: lastEvaluatedKey (if provided)
  ScanIndexForward: false (newest first)
```

### Pagination Algorithm

1. **First Request**: No `startAt` parameter
   - Query with Limit=pageSize
   - If `LastEvaluatedKey` exists in response, set `moreAvailable=true` and serialize as `startAt`

2. **Subsequent Requests**: Include `startAt` from previous response
   - Parse `startAt` JSON string to reconstruct `ExclusiveStartKey`
   - Query with `ExclusiveStartKey` set
   - Repeat pagination process

3. **Last Page**: Response has no `LastEvaluatedKey`
   - Set `moreAvailable=false` and `startAt=null`

### Code Structure

```
src/
├── handlers/
│   ├── get_order.py          # GET /v1.0/orders/{orderId}
│   └── list_orders.py        # GET /v1.0/tenants/{tenantId}/orders (NEW)
├── dao/
│   └── order_dao.py          # Data Access Object
│       ├── get_order()       # Single order retrieval
│       └── find_by_tenant_id()  # List orders with pagination (NEW)
├── models/
│   ├── order.py
│   ├── order_item.py
│   ├── campaign.py
│   ├── billing_address.py
│   └── payment_details.py
└── __init__.py

tests/
├── unit/
│   ├── test_list_orders_handler.py    # Handler unit tests (NEW)
│   ├── test_order_dao.py              # DAO unit tests
│   └── test_get_order_handler.py      # Existing handler tests
├── integration/
│   ├── test_list_orders_integration.py    # Handler integration tests (NEW)
│   └── test_get_order_integration.py      # Existing integration tests
├── conftest.py                # Pytest fixtures
└── __init__.py

requirements.txt               # Python dependencies
pytest.ini                     # Pytest configuration
.gitignore                     # Git ignore rules
```

## Installation & Setup

### Prerequisites

- Python 3.11+
- pip
- boto3 (AWS SDK)
- pydantic (data validation)
- pytest (testing)

### Install Dependencies

```bash
pip install -r requirements.txt
```

### Environment Variables

Configure these environment variables for the Lambda function:

```bash
# DynamoDB table name
export DYNAMODB_TABLE_NAME=bbws-customer-portal-orders-dev

# Logging level
export LOG_LEVEL=INFO
```

### Database Table Structure

The implementation expects a DynamoDB table with the following schema:

**Table Name**: `bbws-customer-portal-orders-{env}`

**Primary Key**:
- Partition Key (PK): String
- Sort Key (SK): String

**Indexes**:
- GSI1: Used for alternate query patterns
- GSI2: Used for metadata queries

**Capacity Mode**: On-Demand

## Testing

### Run All Tests

```bash
pytest
```

### Run Specific Test Categories

```bash
# Unit tests only
pytest tests/unit/

# Integration tests only
pytest tests/integration/

# Specific test file
pytest tests/unit/test_list_orders_handler.py

# Specific test class
pytest tests/unit/test_list_orders_handler.py::TestListOrdersHandler

# Specific test method
pytest tests/unit/test_list_orders_handler.py::TestListOrdersHandler::test_list_orders_success_first_page
```

### Test Coverage

```bash
# Generate coverage report
pytest --cov=src tests/

# HTML coverage report
pytest --cov=src --cov-report=html tests/
```

### Unit Tests

**TestListOrdersHandler** tests in `tests/unit/test_list_orders_handler.py`:
- ✓ Successful order listing (first page)
- ✓ Custom page size handling
- ✓ Pagination continuation token
- ✓ Empty result handling
- ✓ Missing tenantId error
- ✓ Invalid pageSize (negative)
- ✓ Invalid pageSize (exceeds max)
- ✓ Invalid pageSize (non-integer format)
- ✓ DAO error handling
- ✓ Missing pathParameters error
- ✓ Response headers (CORS)
- ✓ Maximum page size (100)

**TestOrderDAO** tests in `tests/unit/test_order_dao.py`:
- ✓ Successful order listing for tenant
- ✓ Empty result handling
- ✓ Pagination token generation
- ✓ Continuation token parsing
- ✓ Custom page size usage
- ✓ DynamoDB error handling
- ✓ Multiple orders deserialization

### Integration Tests

**TestListOrdersIntegration** tests in `tests/integration/test_list_orders_integration.py`:
- ✓ Realistic API Gateway event processing
- ✓ Pagination with multiple orders
- ✓ Pagination continuation flow (first → second page)
- ✓ Error response format validation
- ✓ Response structure compliance
- ✓ Oversized page request rejection
- ✓ Default page size usage

## Example Usage

### First Page Request

```bash
curl -X GET "https://api.example.com/v1.0/tenants/tenant_bb0e8400-e29b-41d4-a716-446655440006/orders" \
  -H "Authorization: Bearer <token>" \
  -H "Accept: application/json"

# Query with custom page size
curl -X GET "https://api.example.com/v1.0/tenants/tenant_bb0e8400-e29b-41d4-a716-446655440006/orders?pageSize=20" \
  -H "Authorization: Bearer <token>"
```

### Continuation Request

```bash
# Use startAt token from previous response
curl -X GET "https://api.example.com/v1.0/tenants/tenant_bb0e8400-e29b-41d4-a716-446655440006/orders?startAt=eyJQSyI6e..." \
  -H "Authorization: Bearer <token>"
```

## Development Workflow

### TDD Process

1. **Write Tests First**
   ```bash
   # Add test case to test_list_orders_handler.py or test_order_dao.py
   # Ensure test fails
   pytest tests/unit/test_list_orders_handler.py -v
   ```

2. **Implement Code**
   ```bash
   # Implement handler or DAO method to pass test
   # Maintain backward compatibility
   ```

3. **Verify Tests Pass**
   ```bash
   pytest tests/unit/test_list_orders_handler.py -v
   ```

4. **Run All Tests**
   ```bash
   pytest
   ```

### Code Quality

```bash
# Type checking
mypy src/

# Linting
flake8 src/ tests/

# Format checking
black --check src/ tests/
```

## Pagination Best Practices

### Client Implementation

1. **First Request**: Omit `startAt` parameter
   ```python
   response = requests.get(
       f"/v1.0/tenants/{tenant_id}/orders",
       params={"pageSize": 50}
   )
   ```

2. **Check for More Items**: Inspect `moreAvailable` flag
   ```python
   if response['data']['moreAvailable']:
       next_token = response['data']['startAt']
       # Make next request with next_token
   ```

3. **Pagination Loop**: Continue until `moreAvailable=false`
   ```python
   all_orders = []
   start_at = None

   while True:
       params = {"pageSize": 50}
       if start_at:
           params["startAt"] = start_at

       response = requests.get(
           f"/v1.0/tenants/{tenant_id}/orders",
           params=params
       )

       all_orders.extend(response['data']['items'])

       if not response['data']['moreAvailable']:
           break

       start_at = response['data']['startAt']
   ```

### Performance Considerations

- Default page size is 50 items (balance between latency and throughput)
- Maximum page size is 100 items
- Pagination tokens are JSON-serialized DynamoDB keys
- Orders are sorted by date descending (newest first)
- Queries use consistent read (eventually consistent is default)

## Error Handling

### Input Validation

- **Missing tenantId**: Returns 400 "Missing tenantId"
- **Missing pathParameters**: Returns 400 "Missing path parameters"
- **Invalid pageSize**: Returns 400 with specific message
  - Non-integer: "pageSize must be an integer"
  - Out of range: "pageSize must be between 1 and 100"

### DynamoDB Errors

- **Query failures**: Logged and returned as 500 "Internal Server Error"
- **Deserialization errors**: Handled gracefully, logged with context
- **Timeout errors**: Return 500 after Lambda timeout (default 60s)

### Logging

All operations are logged with request context:
- INFO: Request received, orders found, pagination details
- WARNING: Order not found (expected), deserialization issues
- ERROR: Validation failures, DynamoDB errors, system exceptions

## Deployment

### To DEV Environment

```bash
# Build and test locally
pytest
./scripts/build.sh

# Deploy to dev
./scripts/deploy.sh --env dev --region af-south-1
```

### To SIT Environment (from DEV)

```bash
# After successful testing in DEV
./scripts/promote.sh --from dev --to sit
```

### To PROD Environment (from SIT)

```bash
# After successful testing in SIT
./scripts/promote.sh --from sit --to prod
```

## Monitoring & Debugging

### CloudWatch Logs

```bash
# View logs for list_orders handler
aws logs tail /aws/lambda/list-orders --follow

# Filter for errors
aws logs tail /aws/lambda/list-orders --follow --filter-pattern "ERROR"
```

### DynamoDB Metrics

- **ConsumedReadCapacityUnits**: Track query performance
- **UserErrors**: Monitor client request errors
- **SystemErrors**: Monitor server-side failures

### Alarms

Configure CloudWatch alarms for:
- Lambda error rate > 1%
- Lambda duration > 5 seconds (p99)
- DynamoDB consumed read units > threshold

## Troubleshooting

### Issue: Pagination Token Invalid

**Symptom**: "Invalid pagination token" error
**Solution**: Tokens are environment-specific and expire after 24 hours. Restart pagination from first page.

### Issue: Empty Results with Valid Tenant

**Symptom**: Returns `items: []` for tenant with orders
**Solution**: Verify tenant has orders in DynamoDB (check PK=TENANT#{tenantId})

### Issue: Slow Queries

**Symptom**: List orders takes > 2 seconds
**Solution**:
- Verify DynamoDB table has on-demand capacity
- Check if GSI queries are being used instead of main table
- Review CloudWatch metrics for hot partitions

## Related Documentation

- [Order Lambda LLD](2.1.8_LLD_Order_Lambda.md) - Complete microservice design
- [DynamoDB Design](2.1.8_LLD_S3_and_DynamoDB.md) - Table schema details
- [API Standards](../specs/api_standards.md) - RESTful API conventions

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2025-12-30 | Initial implementation - list_orders handler with pagination |

## Support

For issues or questions:
1. Check the [Troubleshooting](#troubleshooting) section
2. Review CloudWatch logs for detailed error context
3. Contact the Order Lambda team
