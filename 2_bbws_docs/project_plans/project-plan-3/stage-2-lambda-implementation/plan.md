# Stage 2 Plan: Lambda Implementation

**Project**: Order Lambda Service Implementation (Project Plan 3)
**Stage**: Stage 2 - Lambda Implementation
**Status**: READY FOR EXECUTION
**Created**: 2025-12-30
**Workers**: 8 (parallel execution)
**Prerequisites**: Stage 1 Complete ✅

---

## Executive Summary

Stage 2 focuses on implementing the 8 Lambda functions for the Order Lambda microservice. This includes 4 API handlers (create, get, list, update) and 4 event-driven processors (order record creator, PDF generator, internal notifications, customer confirmations). All implementations will follow Test-Driven Development (TDD), Object-Oriented Programming (OOP) principles, and use Pydantic v1.10.18 for data validation.

**Key Objectives**:
- Implement 8 production-ready Lambda functions with 80%+ test coverage
- Create shared Pydantic models for Order, OrderItem, Campaign, BillingAddress, PaymentDetails
- Implement DAO (Data Access Object) with DynamoDB single-table design patterns
- Package Lambda functions using Docker (`public.ecr.aws/lambda/python:3.12`)
- Ensure all functions are environment-agnostic (parameterized configuration)

---

## Stage 2 Overview

### Workers

| Worker | Lambda Function | Type | Handler | Purpose | Priority |
|--------|----------------|------|---------|---------|----------|
| **Worker 1** | create_order | API Handler | POST /v1.0/orders | Validate request, publish to SQS | High |
| **Worker 2** | get_order | API Handler | GET /v1.0/orders/{orderId} | Query DynamoDB by orderId | High |
| **Worker 3** | list_orders | API Handler | GET /v1.0/tenants/{tenantId}/orders | Query with pagination | High |
| **Worker 4** | update_order | API Handler | PUT /v1.0/orders/{orderId} | Update order status/payment | High |
| **Worker 5** | OrderCreatorRecord | Event Processor | SQS → DynamoDB | Create order record in DynamoDB | Critical |
| **Worker 6** | OrderPDFCreator | Event Processor | SQS → S3 | Generate PDF invoice | Medium |
| **Worker 7** | OrderInternalNotificationSender | Event Processor | SQS → SES | Send internal notification | Medium |
| **Worker 8** | CustomerOrderConfirmationSender | Event Processor | SQS → SES | Send customer confirmation | High |

### Execution Strategy

**Parallel Execution Groups**:
- **Group A** (API Handlers): Workers 1-4 can run in parallel (shared models dependency)
- **Group B** (Event Processors): Workers 5-8 can run in parallel after Group A completes (depend on models from Group A)

**Recommended Approach**: Execute all 8 workers in parallel, as they will all create the shared models independently, and we can consolidate afterwards.

---

## Deliverables per Worker

Each worker must produce:

### 1. Lambda Function Implementation
- **Handler file**: `src/handlers/{function_name}.py`
- **Entry point**: Lambda handler function `lambda_handler(event, context)`
- **Architecture**: Layered architecture (handler → service → DAO)
- **Error handling**: Try-except blocks with proper logging
- **Logging**: CloudWatch-compatible structured logging

### 2. Shared Models (Pydantic v1.10.18)
Located in `src/models/`:
- `order.py` - Order model (25 attributes)
- `order_item.py` - OrderItem model (embedded in Order)
- `campaign.py` - Campaign model (denormalized for historical accuracy)
- `billing_address.py` - BillingAddress model
- `payment_details.py` - PaymentDetails model (optional)

### 3. Data Access Layer
Located in `src/dao/`:
- `order_dao.py` - DynamoDB operations with single-table design
- Access patterns: AP1-AP5 (get, list, list by date, admin lookup, filter by status)
- Tenant isolation: PK=`TENANT#{tenantId}`, SK=`ORDER#{orderId}`
- GSI support: OrdersByDateIndex, OrderByIdIndex

### 4. Service Layer
Located in `src/services/`:
- `order_service.py` - Business logic for order operations
- `sqs_service.py` - SQS message publishing (for create_order)
- `ses_service.py` - Email sending (for notification lambdas)
- `s3_service.py` - S3 operations (for PDF lambda)
- `pdf_service.py` - PDF generation (for PDF lambda)

### 5. Unit Tests (TDD)
Located in `tests/unit/`:
- Test handler logic (mocked dependencies)
- Test service layer logic
- Test DAO operations (mocked boto3)
- **Coverage requirement**: 80%+ (enforced in CI/CD)

### 6. Integration Tests
Located in `tests/integration/`:
- Test Lambda handler with mocked AWS services (moto)
- Test end-to-end flow with LocalStack (optional)
- API contract validation

### 7. Lambda Packaging
- `Dockerfile` - Docker-based Lambda packaging
- `requirements.txt` - Python dependencies (Pydantic==1.10.18, boto3, etc.)
- `pyproject.toml` - Project metadata
- `.dockerignore` - Exclude test files from Lambda package

### 8. Documentation
- Function-level docstrings (Google style)
- README.md per worker with setup instructions
- API contract documentation (request/response schemas)

---

## Technical Standards

### Programming Standards

**Python Version**: 3.12
**Architecture**: arm64
**Framework**: AWS Lambda with boto3

**Code Quality**:
- **PEP 8**: Python style guide compliance
- **Type hints**: Use Python type annotations
- **Docstrings**: Google-style docstrings for all public functions
- **Error handling**: Explicit error types, structured error responses
- **Logging**: Structured logging with context (tenantId, orderId, requestId)

**Design Patterns**:
- **Dependency Injection**: Pass AWS clients/resources as parameters
- **Single Responsibility**: Each class/function has one clear purpose
- **DRY**: Don't repeat yourself - extract common logic
- **SOLID principles**: Apply OOP best practices

### Pydantic Models (v1.10.18)

**Why v1.10.18?**
- Pure Python implementation (no Rust binaries)
- Compatible with AWS Lambda arm64 architecture
- Proven working in Product Lambda implementation

**Model Standards**:
```python
from pydantic import BaseModel, Field, validator
from typing import Optional, List
from datetime import datetime

class Order(BaseModel):
    """Order model representing a customer order."""
    id: str = Field(..., description="Unique order identifier (UUID)")
    orderNumber: str = Field(..., description="Human-readable order number")
    tenantId: str = Field(..., description="Tenant identifier")
    customerEmail: str = Field(..., description="Customer email address")
    status: str = Field(default="pending", description="Order status")
    # ... additional fields

    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }

    @validator('customerEmail')
    def validate_email(cls, v):
        # Email validation logic
        return v
```

### DynamoDB Single-Table Design

**Table**: `bbws-customer-portal-orders-{environment}`

**Primary Key Structure**:
- **PK**: `TENANT#{tenantId}` - Enables tenant isolation
- **SK**: `ORDER#{orderId}` - Unique order identifier

**GSI 1: OrdersByDateIndex** (newest first):
- **GSI1_PK**: `TENANT#{tenantId}`
- **GSI1_SK**: `{dateCreated}#{orderId}` (ISO timestamp for sorting)

**GSI 2: OrderByIdIndex** (admin cross-tenant lookup):
- **GSI2_PK**: `ORDER#{orderId}`
- **GSI2_SK**: `METADATA`

**DAO Pattern**:
```python
class OrderDAO:
    """Data Access Object for Order operations."""

    def __init__(self, dynamodb_client, table_name: str):
        self.dynamodb = dynamodb_client
        self.table_name = table_name

    def get_order(self, tenant_id: str, order_id: str) -> Optional[Order]:
        """Get order by tenant and order ID (AP1)."""
        response = self.dynamodb.get_item(
            TableName=self.table_name,
            Key={
                'PK': {'S': f'TENANT#{tenant_id}'},
                'SK': {'S': f'ORDER#{order_id}'}
            }
        )
        if 'Item' not in response:
            return None
        return Order.parse_obj(self._deserialize_item(response['Item']))

    # Additional methods: create_order, update_order, list_orders, etc.
```

### Lambda Handler Pattern

**Standard Handler Structure**:
```python
import json
import logging
import os
from typing import Dict, Any
from src.services.order_service import OrderService
from src.dao.order_dao import OrderDAO
import boto3

# Configure logging
logger = logging.getLogger()
logger.setLevel(os.environ.get('LOG_LEVEL', 'INFO'))

# Initialize AWS clients (outside handler for connection reuse)
dynamodb_client = boto3.client('dynamodb')
table_name = os.environ['DYNAMODB_TABLE_NAME']

# Initialize DAO and Service
order_dao = OrderDAO(dynamodb_client, table_name)
order_service = OrderService(order_dao)

def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lambda handler for [function purpose].

    Args:
        event: API Gateway event or SQS event
        context: Lambda context object

    Returns:
        API Gateway response or None (for SQS)
    """
    try:
        logger.info(f"Processing request: {json.dumps(event)}")

        # Extract parameters from event
        # Call service layer
        # Return formatted response

        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'success': True,
                'data': result
            })
        }

    except ValueError as e:
        logger.error(f"Validation error: {str(e)}")
        return {
            'statusCode': 400,
            'body': json.dumps({'error': 'Bad Request', 'message': str(e)})
        }

    except Exception as e:
        logger.error(f"Internal error: {str(e)}", exc_info=True)
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Internal Server Error'})
        }
```

### Testing Standards

**Test-Driven Development (TDD)**:
1. Write failing test first
2. Implement minimum code to pass test
3. Refactor for quality
4. Repeat

**Test Structure**:
```
tests/
├── unit/
│   ├── test_create_order_handler.py
│   ├── test_order_service.py
│   ├── test_order_dao.py
│   └── test_order_model.py
├── integration/
│   ├── test_create_order_integration.py
│   └── test_order_workflow.py
└── conftest.py  # Shared fixtures
```

**Coverage Thresholds**:
- Unit tests: 80%+ overall coverage
- Critical paths: 100% coverage (create_order, OrderCreatorRecord)
- Allow test failures if coverage threshold met (fail on coverage drop)

**Test Tools**:
- `pytest` - Test framework
- `pytest-cov` - Coverage reporting
- `pytest-mock` - Mocking support
- `moto` - Mock AWS services for integration tests

---

## Worker-Specific Requirements

### Worker 1: create_order (API Handler)

**Endpoint**: `POST /v1.0/orders`

**Functionality**:
1. Validate incoming request against CreateOrderRequest schema
2. Generate orderId (UUID v4) and orderNumber (sequential)
3. Enrich order data with timestamp, default status="pending"
4. Publish message to SQS queue (`bbws-order-creation-{env}`)
5. Return 202 Accepted with orderId

**Key Dependencies**:
- Pydantic models: CreateOrderRequest, CreateOrderResponse
- SQS client for message publishing
- Request validation and error handling

**Response**:
```json
{
  "success": true,
  "data": {
    "orderId": "550e8400-e29b-41d4-a716-446655440000",
    "orderNumber": "ORD-2025-00001",
    "status": "pending",
    "message": "Order accepted for processing"
  }
}
```

**Error Handling**:
- 400: Invalid request body
- 500: SQS publishing failure

---

### Worker 2: get_order (API Handler)

**Endpoint**: `GET /v1.0/orders/{orderId}`

**Functionality**:
1. Extract orderId from path parameters
2. Extract tenantId from JWT token (event['requestContext']['authorizer']['claims']['custom:tenantId'])
3. Query DynamoDB using PK+SK (AP1: get specific order for tenant)
4. Return order details or 404 if not found

**Key Dependencies**:
- OrderDAO: get_order method
- Pydantic models: Order
- Tenant isolation validation

**Response**:
```json
{
  "success": true,
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "orderNumber": "ORD-2025-00001",
    "tenantId": "tenant-123",
    "customerEmail": "customer@example.com",
    "status": "completed",
    "items": [...],
    "total": 250.00,
    "currency": "ZAR",
    "dateCreated": "2025-12-30T10:30:00Z"
  }
}
```

**Error Handling**:
- 404: Order not found or not authorized for tenant
- 500: DynamoDB query failure

---

### Worker 3: list_orders (API Handler)

**Endpoint**: `GET /v1.0/tenants/{tenantId}/orders?pageSize=50&startAt={token}`

**Functionality**:
1. Extract tenantId from path parameters (validate against JWT)
2. Extract pagination parameters: pageSize (default 50, max 100), startAt (optional)
3. Query DynamoDB using PK query (AP2: list all orders for tenant)
4. Return paginated results with nextToken for continuation

**Key Dependencies**:
- OrderDAO: list_orders_for_tenant method with pagination
- Pydantic models: OrderListResponse
- Pagination token encoding/decoding (base64 JSON)

**Response**:
```json
{
  "success": true,
  "data": {
    "orders": [
      {
        "id": "...",
        "orderNumber": "ORD-2025-00001",
        "status": "completed",
        "total": 250.00,
        "dateCreated": "2025-12-30T10:30:00Z"
      }
    ],
    "pagination": {
      "pageSize": 50,
      "totalReturned": 25,
      "nextToken": "eyJQSyI6IlRFTkFOVCMxMjMiLCJTSyI6Ik9SREVSIzQ1NiJ9"
    }
  }
}
```

**Error Handling**:
- 400: Invalid pagination parameters
- 403: Tenant mismatch (JWT tenantId ≠ path tenantId)
- 500: DynamoDB query failure

---

### Worker 4: update_order (API Handler)

**Endpoint**: `PUT /v1.0/orders/{orderId}`

**Functionality**:
1. Extract orderId from path and tenantId from JWT
2. Validate update request (status, paymentDetails allowed)
3. Fetch existing order from DynamoDB
4. Apply updates with optimistic locking (dateLastUpdated check)
5. Write updated order back to DynamoDB
6. Return updated order

**Key Dependencies**:
- OrderDAO: get_order, update_order methods
- Pydantic models: UpdateOrderRequest, Order
- Optimistic locking with conditional updates

**Request**:
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

**Response**:
```json
{
  "success": true,
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "status": "paid",
    "paymentDetails": {...},
    "dateLastUpdated": "2025-12-30T11:00:05Z"
  }
}
```

**Error Handling**:
- 400: Invalid update request
- 404: Order not found
- 409: Conflict (optimistic locking failure)
- 500: DynamoDB update failure

---

### Worker 5: OrderCreatorRecord (Event Processor - CRITICAL)

**Trigger**: SQS (`bbws-order-creation-{env}`)
**Target**: DynamoDB

**Functionality**:
1. Parse SQS message (batch of up to 10 messages)
2. For each message:
   a. Validate order data against Order schema
   b. Fetch cart data from Cart Lambda (external dependency)
   c. Calculate totals and enrich order details
   d. Generate orderNumber (atomic counter pattern)
   e. Write order to DynamoDB with PK/SK and GSI keys
3. Handle partial batch failures (return failed message IDs)

**Key Dependencies**:
- OrderDAO: create_order method
- Cart Lambda API client (HTTP request)
- Atomic counter for orderNumber generation
- DynamoDB conditional writes (prevent duplicates)

**SQS Message Format**:
```json
{
  "orderId": "550e8400-e29b-41d4-a716-446655440000",
  "tenantId": "tenant-123",
  "customerEmail": "customer@example.com",
  "cartId": "cart-xyz789",
  "campaignCode": "SUMMER2025",
  "billingAddress": {...}
}
```

**DynamoDB Item**:
- PK: `TENANT#tenant-123`
- SK: `ORDER#550e8400-e29b-41d4-a716-446655440000`
- GSI1_PK: `TENANT#tenant-123`
- GSI1_SK: `2025-12-30T10:30:00Z#550e8400-e29b-41d4-a716-446655440000`
- GSI2_PK: `ORDER#550e8400-e29b-41d4-a716-446655440000`
- GSI2_SK: `METADATA`
- ...all order attributes...

**Error Handling**:
- Partial batch failures: Return failed message IDs for retry
- Cart Lambda unavailable: Retry with exponential backoff (SQS redelivery)
- DynamoDB write failure: Return message for retry
- Max retries (3): Send to DLQ

---

### Worker 6: OrderPDFCreator (Event Processor)

**Trigger**: SQS (`bbws-order-creation-{env}`)
**Target**: S3 (`bbws-orders-{env}`)

**Functionality**:
1. Parse SQS message
2. Fetch order details from DynamoDB
3. Fetch email template from S3 (optional: use for PDF header/footer)
4. Generate PDF invoice using ReportLab or WeasyPrint
5. Upload PDF to S3: `{tenantId}/orders/order_{orderId}.pdf`
6. Update order record with pdfUrl

**Key Dependencies**:
- PDF generation library: ReportLab (recommended) or WeasyPrint
- S3 client for upload
- OrderDAO: get_order, update_order methods
- PDF template (HTML or programmatic)

**PDF Contents**:
- Order number, date, customer details
- Itemized list with quantities and prices
- Subtotal, tax, shipping, total
- Payment status
- Company branding (logo from S3)

**S3 Upload**:
- Bucket: `bbws-orders-{env}`
- Key: `{tenantId}/orders/order_{orderId}.pdf`
- Metadata: ContentType=application/pdf
- Encryption: SSE-S3

**Error Handling**:
- Order not found: Log error, return success (idempotent)
- PDF generation failure: Retry (SQS redelivery)
- S3 upload failure: Retry
- Max retries: Send to DLQ

---

### Worker 7: OrderInternalNotificationSender (Event Processor)

**Trigger**: SQS (`bbws-order-creation-{env}`)
**Target**: SES (internal team email)

**Functionality**:
1. Parse SQS message
2. Fetch order details from DynamoDB
3. Fetch email template from S3: `internal/order_notification.html`
4. Render template with order data
5. Send email via SES to internal team (configurable recipient)

**Key Dependencies**:
- SES client for email sending
- S3 client for template retrieval
- Template rendering (Jinja2 or string replacement)
- OrderDAO: get_order method

**Email Template Variables**:
- `{{orderNumber}}`
- `{{customerEmail}}`
- `{{total}}`
- `{{orderDate}}`
- `{{itemCount}}`
- `{{orderDetailsUrl}}` (link to admin portal)

**SES Configuration**:
- From: `noreply@kimmyai.io` (SIT/PROD), `test@kimmyai.io` (DEV)
- To: Configurable via environment variable `INTERNAL_NOTIFICATION_EMAIL`
- Subject: `New Order Received: {{orderNumber}}`

**Error Handling**:
- Template not found: Use fallback plain-text email
- SES send failure: Retry
- Max retries: Send to DLQ (critical notification)

---

### Worker 8: CustomerOrderConfirmationSender (Event Processor)

**Trigger**: SQS (`bbws-order-creation-{env}`)
**Target**: SES (customer email)

**Functionality**:
1. Parse SQS message
2. Fetch order details from DynamoDB
3. Fetch email template from S3: `customer/order_confirmation.html`
4. Render template with order data
5. Send confirmation email to customer via SES

**Key Dependencies**:
- SES client for email sending
- S3 client for template retrieval
- Template rendering (Jinja2 or string replacement)
- OrderDAO: get_order method

**Email Template Variables**:
- `{{customerName}}`
- `{{orderNumber}}`
- `{{orderTotal}}`
- `{{orderDate}}`
- `{{orderItems}}` (loop)
- `{{trackingUrl}}` (link to customer portal)

**SES Configuration**:
- From: `noreply@kimmyai.io` (SIT/PROD), `test@kimmyai.io` (DEV)
- To: Order's customerEmail
- Subject: `Order Confirmation: {{orderNumber}}`
- ReplyTo: `support@kimmyai.io`

**Error Handling**:
- Invalid customer email: Log error, mark as failed, send to DLQ
- Template not found: Use fallback plain-text email
- SES send failure: Retry
- Max retries: Send to DLQ

---

## Shared Components

### Repository Structure

```
2_bbws_order_lambda/
├── src/
│   ├── handlers/
│   │   ├── create_order.py
│   │   ├── get_order.py
│   │   ├── list_orders.py
│   │   ├── update_order.py
│   │   ├── order_creator_record.py
│   │   ├── order_pdf_creator.py
│   │   ├── order_internal_notifier.py
│   │   └── customer_order_confirmation.py
│   ├── models/
│   │   ├── __init__.py
│   │   ├── order.py
│   │   ├── order_item.py
│   │   ├── campaign.py
│   │   ├── billing_address.py
│   │   ├── payment_details.py
│   │   ├── requests.py  # API request models
│   │   └── responses.py  # API response models
│   ├── dao/
│   │   ├── __init__.py
│   │   └── order_dao.py
│   ├── services/
│   │   ├── __init__.py
│   │   ├── order_service.py
│   │   ├── sqs_service.py
│   │   ├── ses_service.py
│   │   ├── s3_service.py
│   │   └── pdf_service.py
│   └── utils/
│       ├── __init__.py
│       ├── logger.py
│       ├── validators.py
│       └── exceptions.py
├── tests/
│   ├── unit/
│   ├── integration/
│   └── conftest.py
├── Dockerfile
├── requirements.txt
├── pyproject.toml
├── pytest.ini
├── .dockerignore
├── .gitignore
└── README.md
```

### Python Dependencies (requirements.txt)

```
# AWS SDK
boto3==1.34.0
botocore==1.34.0

# Data validation
pydantic==1.10.18

# PDF generation
reportlab==4.0.7

# Email templating
jinja2==3.1.2

# Utilities
python-dateutil==2.8.2
pytz==2023.3

# Testing (dev dependencies)
pytest==7.4.3
pytest-cov==4.1.0
pytest-mock==3.12.0
moto==4.2.9
```

### Docker Packaging (Dockerfile)

```dockerfile
FROM public.ecr.aws/lambda/python:3.12

# Copy requirements
COPY requirements.txt ${LAMBDA_TASK_ROOT}/

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy source code
COPY src/ ${LAMBDA_TASK_ROOT}/src/

# Set handler
CMD ["src.handlers.create_order.lambda_handler"]
```

**Note**: Each Lambda function will have its own CMD override in Terraform.

---

## Environment Configuration

All Lambda functions must use environment variables for configuration (no hardcoding):

### Common Environment Variables

```bash
# Environment
ENVIRONMENT=dev|sit|prod
AWS_REGION=eu-west-1|af-south-1

# DynamoDB
DYNAMODB_TABLE_NAME=bbws-customer-portal-orders-{env}

# SQS
SQS_QUEUE_URL=https://sqs.{region}.amazonaws.com/{account}/bbws-order-creation-{env}

# S3
S3_EMAIL_TEMPLATES_BUCKET=bbws-email-templates-{env}
S3_ORDERS_BUCKET=bbws-orders-{env}

# SES
SES_FROM_ADDRESS=noreply@kimmyai.io
INTERNAL_NOTIFICATION_EMAIL=orders@kimmyai.io

# Logging
LOG_LEVEL=DEBUG|INFO|WARN|ERROR
ENABLE_XRAY=true|false

# External Dependencies
CART_LAMBDA_API_URL=https://api-{env}.bbws.io/v1.0/cart
```

---

## Success Criteria

Stage 2 will be considered complete when:

### Code Quality
- ✅ All 8 Lambda functions implemented with handler, service, and DAO layers
- ✅ Pydantic v1.10.18 models for all data structures
- ✅ PEP 8 compliance (verified with flake8/black)
- ✅ Type hints on all public functions
- ✅ Google-style docstrings on all public classes/functions

### Testing
- ✅ Unit test coverage ≥ 80% (enforced in CI/CD)
- ✅ Integration tests for all Lambda handlers
- ✅ All tests passing (pytest exit code 0)
- ✅ Mocked AWS services using moto for unit tests

### Functionality
- ✅ All API handlers return correct HTTP status codes
- ✅ All event processors handle SQS messages correctly
- ✅ DynamoDB single-table design implemented with all 5 access patterns
- ✅ Tenant isolation enforced in all queries
- ✅ Error handling with proper logging and structured responses

### Packaging
- ✅ Dockerfile for Lambda packaging created
- ✅ requirements.txt with all dependencies (Pydantic v1.10.18)
- ✅ Docker image builds successfully
- ✅ Lambda package verification (import test)

### Documentation
- ✅ README.md with setup and testing instructions
- ✅ API contract documentation (OpenAPI specs in Stage 3)
- ✅ Code comments explaining complex logic
- ✅ Worker output documents summarizing implementation

---

## Risk Mitigation

### Risk 1: Cart Lambda API Contract Undefined
**Impact**: Worker 5 (OrderCreatorRecord) cannot fetch cart data
**Mitigation**:
- Mock Cart Lambda response in Worker 5
- Document expected API contract
- Flag as external dependency for Stage 1 coordination

### Risk 2: Pydantic v1 vs v2 Confusion
**Impact**: Binary dependency issues if wrong version used
**Mitigation**:
- Pin exact version: `pydantic==1.10.18`
- Verify in Docker build
- Test Lambda package import before deployment

### Risk 3: DynamoDB Access Pattern Complexity
**Impact**: Incorrect query patterns, poor performance
**Mitigation**:
- Document all 5 access patterns in DAO
- Unit test each access pattern
- Verify GSI key structure matches requirements

### Risk 4: SQS Batch Processing Failures
**Impact**: Lost orders if Worker 5 fails
**Mitigation**:
- Implement partial batch failure handling
- Return failed message IDs for retry
- Configure DLQ with CloudWatch alarms
- Test retry logic with mocked failures

### Risk 5: PDF Generation Library Compatibility
**Impact**: Lambda deployment failures
**Mitigation**:
- Test ReportLab in Docker packaging early
- Verify library works on arm64 architecture
- Have fallback option (WeasyPrint) documented

---

## Execution Plan

### Pre-Execution Checklist
- ✅ Stage 1 completed with all requirements documented
- ✅ LLD 2.1.8 available for reference
- ✅ Worker directories created
- ✅ Stage 2 plan approved by user

### Execution Steps

**Step 1**: Launch all 8 workers in parallel (recommended)
- Each worker implements its assigned Lambda function
- Workers create shared models independently
- Workers document implementation decisions

**Step 2**: Consolidate shared components
- Review all worker outputs
- Merge shared models (Order, OrderItem, etc.) into single source
- Ensure consistency across implementations

**Step 3**: Integration testing
- Test API handler → SQS → Event processor flow
- Verify DynamoDB access patterns
- Validate error handling and retry logic

**Step 4**: Create Stage 2 summary
- Consolidate all worker outputs
- Document any deviations from plan
- List dependencies for Stage 3 (Terraform)

**Step 5**: User approval (Gate 2)
- Present Stage 2 summary
- Demonstrate test coverage
- Show Docker packaging success
- Request approval to proceed to Stage 3

---

## Next Stage Preview

**Stage 3: Infrastructure as Code (Terraform)**
- 6 workers creating Terraform modules
- DynamoDB table with GSIs
- SQS queues with DLQ
- S3 buckets with lifecycle policies
- Lambda functions with IAM roles
- API Gateway with Cognito authorizer
- CloudWatch monitoring and alarms

---

## Appendix

### A. Lambda Function Summary

| Function | Memory | Timeout | Concurrency | Architecture | Runtime |
|----------|--------|---------|-------------|--------------|---------|
| create_order | 512 MB | 30s | None | arm64 | Python 3.12 |
| get_order | 512 MB | 30s | None | arm64 | Python 3.12 |
| list_orders | 512 MB | 30s | None | arm64 | Python 3.12 |
| update_order | 512 MB | 30s | None | arm64 | Python 3.12 |
| OrderCreatorRecord | 512 MB | 30s | 5 batches | arm64 | Python 3.12 |
| OrderPDFCreator | 512 MB | 60s | 10 batches | arm64 | Python 3.12 |
| OrderInternalNotifier | 256 MB | 30s | 5 batches | arm64 | Python 3.12 |
| CustomerConfirmation | 256 MB | 30s | 5 batches | arm64 | Python 3.12 |

### B. Access Patterns Reference

| Pattern | Query Type | Keys Used | Use Case |
|---------|-----------|-----------|----------|
| AP1 | GetItem | PK + SK | Get specific order for tenant |
| AP2 | Query | PK | List all orders for tenant (paginated) |
| AP3 | Query GSI1 | GSI1_PK + GSI1_SK | List orders by date (newest first) |
| AP4 | Query GSI2 | GSI2_PK | Admin: Get order by ID (cross-tenant) |
| AP5 | Query + Filter | PK + FilterExpression | List orders by status for tenant |

### C. References

- LLD: `2.1.8_LLD_Order_Lambda.md`
- Stage 1 Summary: `../stage-1-repository-requirements/summary.md`
- Worker 2 Requirements: `../stage-1-repository-requirements/worker-2-requirements-extraction/output.md`
- Product Lambda Reference: Lessons learned applied (Pydantic v1.10.18, Docker packaging)

---

**Status**: READY FOR EXECUTION
**Approval Required**: User approval to proceed with 8 workers
**Estimated Completion**: 2-3 days (parallel execution)

---

**Created**: 2025-12-30
**Author**: Agentic Project Manager
**Version**: 1.0
