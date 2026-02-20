# Worker 2: Requirements Extraction

**Worker Task**: Extract all implementation requirements from LLD 2.1.8
**Parent Stage**: Stage 1 - Repository Requirements
**LLD Reference**: 2.1.8_LLD_Order_Lambda.md (v1.3)

---

## Task Description

Analyze the Order Lambda LLD document (2.1.8_LLD_Order_Lambda.md) and extract all implementation requirements in a structured format. This establishes the definitive specification for development work in subsequent stages.

### Key Responsibilities

1. Extract all 8 Lambda function specifications with detailed requirements
2. Document DynamoDB table schema including primary keys, GSIs, and access patterns
3. Extract SQS queue configurations (main queue + DLQ)
4. Document S3 bucket requirements for templates and PDFs
5. Define API Gateway specifications and endpoint mapping
6. Extract security and authentication requirements
7. Document monitoring, logging, and alerting requirements
8. Create implementation checklist for all components

---

## Inputs

### Required LLD Document

**File**: `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/2.1.8_LLD_Order_Lambda.md`
**Version**: 1.3
**Last Updated**: 2025-12-19

### Sections to Extract

1. **Lambda Functions** (Section 1.3 and 4.x)
   - API Handler Functions (4 total)
   - Event-Driven Functions (4 total)
   - Function specifications, triggers, and outputs

2. **Data Models** (Section 5)
   - Pydantic models
   - DynamoDB schema and design
   - Access patterns
   - Example data items

3. **Messaging and Queues** (Section 5.4)
   - SQS queue configuration
   - Dead letter queue setup
   - Message format specification
   - Lambda event source mapping

4. **API Specifications** (Section 4.x - Sequence Diagrams)
   - Endpoint definitions
   - Request/response formats
   - Status codes
   - Error handling

5. **Email Templates** (Section 6)
   - Template storage (S3)
   - Template types and variables
   - SES configuration

6. **Non-Functional Requirements** (Section 7)
   - Performance targets
   - Scalability requirements
   - Availability targets
   - Data retention policies

---

## Deliverables

### Output Document: `output.md`

The final output must be saved as `/worker-2-requirements-extraction/output.md` with the following structure:

### 1. Lambda Functions Specification Sheet

**Subsection 1.1: API Handler Functions**

| Function | Endpoint | HTTP Method | Trigger | Memory | Timeout | Runtime | Key Requirements |
|----------|----------|-------------|---------|--------|---------|---------|-------------------|
| create_order | POST /v1.0/orders | POST | API Gateway | 512MB | 30s | Python 3.12 | Validate request, publish to SQS, return 202 |
| get_order | GET /v1.0/orders/{orderId} | GET | API Gateway | 512MB | 30s | Python 3.12 | Query DynamoDB, return 200 or 404 |
| list_orders | GET /v1.0/tenants/{tenantId}/orders | GET | API Gateway | 512MB | 30s | Python 3.12 | Support pagination, return list |
| update_order | PUT /v1.0/orders/{orderId} | PUT | API Gateway | 512MB | 30s | Python 3.12 | Update status, validate transition |

**Subsection 1.2: Event-Driven Functions**

| Function | Trigger | Queue | Target | Memory | Timeout | Key Requirements |
|----------|---------|-------|--------|--------|---------|------------------|
| OrderCreatorRecord | SQS: OrderCreationQueue | bbws-order-creation-{env} | DynamoDB | 512MB | 30s | Persist order, generate number |
| OrderPDFCreator | SQS: OrderCreationQueue | bbws-order-creation-{env} | S3 | 512MB | 60s | Generate PDF, upload to S3 |
| OrderInternalNotificationSender | SQS: OrderCreationQueue | bbws-order-creation-{env} | SES | 256MB | 30s | Send admin email notification |
| CustomerOrderConfirmationSender | SQS: OrderCreationQueue | bbws-order-creation-{env} | SES | 256MB | 30s | Send customer confirmation |

### 2. DynamoDB Schema Specification

**Subsection 2.1: Table Configuration**

| Attribute | Value |
|-----------|-------|
| Table Name | bbws-customer-portal-orders-{environment} |
| Billing Mode | PAY_PER_REQUEST (On-Demand) |
| Partition Key (PK) | TENANT#{tenantId} |
| Sort Key (SK) | ORDER#{orderId} |
| PITR | Enabled (35-day window) |
| Encryption | Enabled (at-rest) |

**Subsection 2.2: Access Patterns**

| Access Pattern | Query Method | Index/Table | Example Use Case |
|---|---|---|---|
| AP1 | Get specific order for tenant | Base table (PK + SK) | Retrieve single order details |
| AP2 | List orders for tenant | Base table (PK + SK begins_with) | List all tenant orders |
| AP3 | List orders by date (tenant) | GSI1 (GSI1_PK + GSI1_SK) | Paginated order history |
| AP4 | Get order by ID (admin) | GSI2 (GSI2_PK + GSI2_SK) | Cross-tenant lookup |
| AP5 | List orders by status (tenant) | Base table + FilterExpression | Filter by status |

**Subsection 2.3: Global Secondary Indexes**

**GSI1: OrdersByDateIndex**
- Partition Key: `GSI1_PK` (TENANT#{tenantId})
- Sort Key: `GSI1_SK` ({dateCreated}#{orderId})
- Projection: ALL
- Use Case: Time-sorted order listing

**GSI2: OrderByIdIndex**
- Partition Key: `GSI2_PK` (ORDER#{orderId})
- Sort Key: `GSI2_SK` (METADATA)
- Projection: ALL
- Use Case: Admin lookup by order ID

**Subsection 2.4: Item Schema**

All Order items include:
- PK, SK, entityType (ORDER)
- id, orderNumber, tenantId, customerEmail
- items[] (array of OrderItem)
- subtotal, tax, total, currency
- status (enum: PENDING_PAYMENT, PAID, PROCESSING, COMPLETED, CANCELLED, EXPIRED, REFUNDED)
- campaign (optional, embedded Campaign object)
- billingAddress (embedded BillingAddress object)
- paymentMethod, paymentDetails (optional)
- dateCreated, dateLastUpdated, lastUpdatedBy, active

### 3. SQS Queue Specification

**Subsection 3.1: Main Queue Configuration**

| Attribute | Value | Notes |
|-----------|-------|-------|
| Queue Name | bbws-order-creation-{environment} | Standard queue |
| Queue Type | Standard | High throughput, at-least-once |
| Visibility Timeout | 60 seconds | Lambda processing time |
| Message Retention | 4 days | Standard retention |
| Max Message Size | 256 KB | For order events |
| Receive Wait Time | 20 seconds | Long polling enabled |
| Batch Size | 10 messages | Per Lambda invocation |
| Batch Window | 5 seconds | Collection time |
| Max Concurrent Batches | 5 | Reserved concurrency |
| DLQ | bbws-order-creation-dlq-{environment} | Max Receive Count: 3 |

**Subsection 3.2: Dead Letter Queue Configuration**

| Attribute | Value |
|-----------|-------|
| Queue Name | bbws-order-creation-dlq-{environment} |
| Message Retention | 14 days |
| CloudWatch Alarm | DLQDepthAlarm (threshold > 0) |
| SNS Alert Topic | bbws-alerts-{environment} |

**Subsection 3.3: Message Schema**

```json
{
  "messageId": "uuid-v4",
  "timestamp": "ISO-8601",
  "eventType": "ORDER_CREATED",
  "version": "1.0",
  "payload": {
    "orderId": "string",
    "tenantId": "string",
    "customerEmail": "string",
    "cartId": "string",
    "campaignCode": "string (optional)",
    "billingAddress": {
      "street": "string",
      "city": "string",
      "province": "string",
      "postalCode": "string",
      "country": "string"
    },
    "paymentMethod": "string",
    "currency": "string",
    "createdBy": "string"
  }
}
```

### 4. S3 Bucket Requirements

**Subsection 4.1: Email Templates Bucket**

| Attribute | Value |
|-----------|-------|
| Bucket Name | bbws-email-templates-{environment} |
| Versioning | Enabled |
| Public Access | Blocked (all) |
| Encryption | Enabled (at-rest) |
| Retention | Indefinite (versioned) |

**Template Structure**:
```
s3://bbws-email-templates-{env}/
├── customer/
│   ├── order_confirmation.html
│   ├── order_status_update.html
│   └── order_cancelled.html
└── internal/
    └── order_notification.html
```

**Subsection 4.2: Order Artifacts Bucket**

| Attribute | Value |
|-----------|-------|
| Bucket Name | bbws-orders-{environment} |
| Versioning | Enabled |
| Public Access | Blocked (all) |
| Encryption | Enabled (at-rest) |
| Lifecycle | S3 Standard → Glacier after 2 years |
| Retention | 7 years (compliance) |

**Structure**:
```
s3://bbws-orders-{env}/
├── {tenantId}/
│   ├── orders/
│   │   └── order_{orderId}.pdf
│   └── receipts/
│       └── receipt_{orderId}.pdf
```

### 5. API Gateway Specification

**Subsection 5.1: Endpoints**

| Endpoint | Method | Handler | Request | Response | Status Codes |
|----------|--------|---------|---------|----------|--------------|
| /v1.0/orders | POST | create_order | CreateOrderRequest | {orderId, message} | 202, 400, 500 |
| /v1.0/orders/{orderId} | GET | get_order | Path params | Order | 200, 404, 500 |
| /v1.0/tenants/{tenantId}/orders | GET | list_orders | Query params (pagination) | {items[], startAt, moreAvailable} | 200, 500 |
| /v1.0/orders/{orderId} | PUT | update_order | UpdateOrderRequest | Order | 200, 400, 404, 500 |

**Subsection 5.2: Request/Response Models**

- **CreateOrderRequest**: tenantId, customerEmail, campaignCode (optional), billingAddress, paymentMethod
- **UpdateOrderRequest**: status, paymentDetails (optional), cancellationReason (optional)
- **Order**: All fields as per DynamoDB schema
- **OrderListResponse**: items[], startAt (optional), moreAvailable

### 6. Security and Authentication Requirements

**Subsection 6.1: Authentication**

- API Gateway: Cognito JWT validation
- Tenant Isolation: JWT must match order's tenantId
- Service-to-Service: IAM role-based access

**Subsection 6.2: Authorization**

- Orders only accessible by owning tenant (tenant isolation)
- Admin operations (cross-tenant lookup via GSI2) require special role
- PCI DSS compliance for payment data

**Subsection 6.3: Encryption**

- At-rest: DynamoDB, S3, RDS (if applicable)
- In-transit: TLS 1.2+
- Billing details encrypted
- Order PDFs encrypted in S3

### 7. Monitoring and Alerting

**Subsection 7.1: CloudWatch Metrics**

| Metric | Threshold | Action |
|--------|-----------|--------|
| DLQ Messages | > 0 | Immediate alert to ops team |
| Lambda Errors | > 5% error rate | Investigate Lambda failures |
| Lambda Duration | > 50 seconds | Review performance |
| SQS Queue Depth | > 1000 messages | Scale Lambda concurrency |
| DynamoDB Throttling | > 0 occurrences | Review capacity/access patterns |

**Subsection 7.2: Logging**

- All Lambda functions: CloudWatch Logs
- Log retention: 90 days
- Structured logging (JSON format)
- Log Insights queries pre-configured

**Subsection 7.3: Alarms**

- DLQ Depth Alarm → SNS Topic (bbws-alerts-{env})
- Lambda Error Rate Alarm
- SQS Age of Oldest Message Alarm
- DynamoDB Throttling Alarm

### 8. NFR Summary

| Category | Requirement |
|----------|-------------|
| Performance (Create) | < 300ms p95 |
| Performance (Persistence) | < 2s p95 |
| Performance (PDF) | < 5s p95 |
| Performance (Email) | < 10s p95 |
| Availability | 99.9% (SLA) |
| Success Rate | 99.95% order processing |
| Data Durability | 99.999999999% (11 9's) |
| RTO | < 1 hour |
| RPO | < 5 minutes |
| Data Retention | 7 years |

---

## Success Criteria

### Extraction Completeness

- [ ] All 8 Lambda functions documented with specifications
- [ ] DynamoDB table schema fully specified (PK, SK, GSI, attributes)
- [ ] All 5 access patterns defined with query examples
- [ ] SQS queue configuration complete (main + DLQ)
- [ ] S3 bucket requirements for templates and PDFs documented
- [ ] API Gateway endpoints fully specified (method, handler, request/response)
- [ ] Security and authentication requirements documented
- [ ] Monitoring and alerting requirements extracted
- [ ] All NFRs extracted (performance, availability, retention)

### Quality Criteria

- [ ] No inconsistencies between extracted requirements and LLD
- [ ] All specifications include examples or sample values
- [ ] Access patterns have corresponding query code examples
- [ ] Error handling paths documented
- [ ] Status codes and error responses defined
- [ ] Pydantic models match LLD section 5.2
- [ ] DynamoDB configuration matches Terraform in LLD section 5.1.9

### Validation Criteria

- [ ] All Lambda functions reference correct LLD sections
- [ ] Queue configurations match LLD section 5.4
- [ ] S3 bucket structure matches LLD section 6
- [ ] API responses match sequence diagrams (section 4)
- [ ] NFRs traceable to LLD section 7

---

## Execution Steps

### Step 1: Extract Lambda Function Specifications

**Action**: Read LLD sections 1.3 and 4.x, extract function details

**For Each Lambda Function (8 total)**:

1. Function name and unique identifier
2. Trigger type (API Gateway or SQS)
3. Endpoint path (if API Handler)
4. Queue name (if Event-Driven)
5. Memory allocation
6. Timeout duration
7. Runtime (Python 3.12)
8. Architecture (arm64)
9. Key processing requirements
10. Input/output specifications
11. Dependencies (other AWS services)
12. Error handling approach

**Deliverable Evidence**:
- Completed Lambda functions table
- List of all 8 functions with basic specs

### Step 2: Extract DynamoDB Schema

**Action**: Read LLD section 5.1, extract complete table design

**Extract Elements**:

1. Table name and naming pattern
2. Billing mode (on-demand)
3. Primary key structure (PK, SK)
4. Partition key pattern: `TENANT#{tenantId}`
5. Sort key pattern: `ORDER#{orderId}`
6. All entity attributes (25+ attributes)
7. Embedded object schemas (OrderItem, BillingAddress, Campaign, PaymentDetails)
8. Global Secondary Indexes (GSI1, GSI2) with:
   - Index names
   - Partition keys
   - Sort keys
   - Projection type
9. All 5 access patterns with query examples
10. Example DynamoDB items (complete JSON)
11. Query code examples (Python/boto3)

**Deliverable Evidence**:
- Complete DynamoDB schema table
- GSI configuration matrix
- Access patterns with implementation details
- Sample query code from LLD section 5.1.8

### Step 3: Extract SQS Configuration

**Action**: Read LLD section 5.4, extract queue specifications

**Extract Elements**:

1. Main queue configuration (15+ attributes)
2. DLQ configuration (5+ attributes)
3. Queue naming pattern: `bbws-order-creation-{environment}`
4. Visibility timeout: 60 seconds
5. Message retention: 4 days
6. Max message size: 256 KB
7. Receive wait time: 20 seconds (long polling)
8. Batch size per function: 5-10 messages
9. Max receive count: 3 (before DLQ)
10. Message schema (JSON structure with fields)
11. Lambda event source mapping (batch settings)
12. Error handling and retry strategy

**Deliverable Evidence**:
- SQS queue specifications table
- Event source mapping configuration
- Message schema JSON
- Retry/backoff strategy

### Step 4: Extract API Gateway Specifications

**Action**: Read LLD section 4.x (Sequence Diagrams), extract API details

**For Each Endpoint**:

1. HTTP method (GET, POST, PUT, DELETE)
2. Path pattern
3. Handler Lambda function
4. Request parameters (path, query, body)
5. Request model (Pydantic schema)
6. Response model (Pydantic schema)
7. HTTP status codes (success and errors)
8. Error response format
9. Authentication method (Cognito JWT)
10. Authorization rules (tenant isolation)

**Deliverable Evidence**:
- API endpoints specification table
- Request/response models
- Status code mapping
- Error handling specification

### Step 5: Extract S3 Requirements

**Action**: Read LLD section 6, extract bucket and template specifications

**Extract Elements**:

1. Email templates bucket:
   - Name pattern: `bbws-email-templates-{environment}`
   - Versioning: enabled
   - Public access: blocked
   - Encryption: enabled
   - Folder structure (customer/, internal/)
   - Templates: order_confirmation.html, order_notification.html, etc.

2. Order artifacts bucket:
   - Name pattern: `bbws-orders-{environment}`
   - Versioning: enabled
   - Public access: blocked
   - Encryption: enabled
   - Lifecycle: S3 Standard → Glacier after 2 years
   - Folder structure: {tenantId}/orders/, {tenantId}/receipts/

3. Template variables for each template:
   - Customer order confirmation: orderNumber, items, total, pdfLink, etc.
   - Internal notification: orderNumber, tenantId, customerEmail, orderLink, etc.
   - Status update: orderNumber, oldStatus, newStatus, nextSteps
   - Cancellation: orderNumber, cancellationReason, refundInfo

**Deliverable Evidence**:
- S3 bucket specification table
- Bucket folder structure diagram
- Template variable list for each template

### Step 6: Extract Security Requirements

**Action**: Read LLD sections 11 (Security) and scattered throughout

**Extract Elements**:

1. Authentication mechanism (Cognito JWT)
2. Authorization rules (tenant isolation)
3. Data encryption (at-rest, in-transit)
4. PCI DSS compliance for payment data
5. Tenant isolation enforcement
6. API key/token validation
7. Cross-tenant access prevention
8. Admin operation restrictions
9. Audit logging requirements
10. Secret management (credentials, API keys)

**Deliverable Evidence**:
- Security requirements table
- Tenant isolation validation logic
- Encryption requirements specification

### Step 7: Extract Monitoring and NFR Requirements

**Action**: Read LLD sections 7 (NFRs), 5.4.7 (Monitoring), extract specifications

**Extract Elements**:

1. Performance targets (latency p95):
   - Create order API: < 300ms
   - Order persistence: < 2 seconds
   - PDF generation: < 5 seconds
   - Email delivery: < 10 seconds

2. Scalability targets:
   - Concurrent orders: 1000/second
   - SQS throughput: 5000 msg/sec
   - Lambda concurrency: 500 per function

3. Availability targets:
   - API: 99.9% SLA
   - Order processing: 99.95% success
   - RTO: < 1 hour
   - RPO: < 5 minutes

4. Data retention:
   - Order records: 7 years
   - CloudWatch logs: 90 days
   - SQS messages: 4 days

5. CloudWatch metrics:
   - DLQ depth, Lambda errors, SQS queue depth
   - DynamoDB throttling, Lambda duration

6. Alarms:
   - DLQ messages > 0
   - Lambda error rate > 5%
   - SQS age of oldest message > 300s

**Deliverable Evidence**:
- NFR summary table
- Monitoring specification
- Alarms configuration table

### Step 8: Create Implementation Checklist

**Action**: Compile all requirements into implementation checklist

**Checklist Structure**:

```markdown
## Implementation Checklist

### Lambda Functions (8 total)
- [ ] create_order API handler
- [ ] get_order API handler
- [ ] list_orders API handler
- [ ] update_order API handler
- [ ] OrderCreatorRecord event handler
- [ ] OrderPDFCreator event handler
- [ ] OrderInternalNotificationSender event handler
- [ ] CustomerOrderConfirmationSender event handler

### Database (DynamoDB)
- [ ] Create bbws-customer-portal-orders-{env} table
- [ ] Configure on-demand billing
- [ ] Create GSI1 (OrdersByDateIndex)
- [ ] Create GSI2 (OrderByIdIndex)
- [ ] Enable PITR
- [ ] Enable encryption
- [ ] Create DynamoDB access patterns (5 patterns)

### Messaging (SQS)
- [ ] Create bbws-order-creation-{env} queue
- [ ] Create bbws-order-creation-dlq-{env} queue
- [ ] Configure visibility timeout (60s)
- [ ] Configure redrive policy (max 3 retries)
- [ ] Create event source mapping for 4 Lambda functions

### Email (SES + S3)
- [ ] Create bbws-email-templates-{env} S3 bucket
- [ ] Create 4 email templates (customer confirmation, internal notification, status update, cancellation)
- [ ] Verify SES domain (kimmyai.io)
- [ ] Configure SES sending limits
- [ ] Create SNS topics for bounce/complaint handling

### Order Storage (S3)
- [ ] Create bbws-orders-{env} S3 bucket
- [ ] Configure lifecycle policies
- [ ] Block public access
- [ ] Enable versioning

### API Gateway
- [ ] Create API endpoint
- [ ] Configure POST /v1.0/orders
- [ ] Configure GET /v1.0/orders/{orderId}
- [ ] Configure GET /v1.0/tenants/{tenantId}/orders
- [ ] Configure PUT /v1.0/orders/{orderId}
- [ ] Configure Cognito authorizer
- [ ] Set up CORS

### Monitoring
- [ ] Create DLQ depth alarm
- [ ] Create Lambda error rate alarm
- [ ] Create SQS age alarm
- [ ] Create SNS alert topic
- [ ] Configure CloudWatch log retention

### Testing
- [ ] Unit tests for all Lambda functions
- [ ] Integration tests for API endpoints
- [ ] DynamoDB access pattern tests
- [ ] SQS message processing tests
- [ ] Error handling tests

### Infrastructure
- [ ] Terraform modules for all resources
- [ ] Environment-specific variables (dev/sit/prod)
- [ ] State file configuration
- [ ] IAM roles and policies
- [ ] VPC configuration (if applicable)
```

---

## Output Format

### Output File: `worker-2-requirements-extraction/output.md`

```markdown
# Worker 2 Output: Requirements Extraction

**Date Completed**: YYYY-MM-DD
**Worker**: [Your Name/Identifier]
**Status**: Complete / In Progress / Blocked

## Executive Summary

[Summary of extracted requirements from LLD 2.1.8]

## 1. Lambda Functions Specification

### 1.1 API Handler Functions (4 total)

[Complete table with all 4 handlers]

### 1.2 Event-Driven Functions (4 total)

[Complete table with all 4 functions]

## 2. DynamoDB Schema

### 2.1 Table Configuration
[Configuration table]

### 2.2 Access Patterns (5 total)
[Access patterns table with examples]

### 2.3 Global Secondary Indexes
[GSI1 and GSI2 specifications]

### 2.4 Item Schema
[Complete attribute list with types and descriptions]

## 3. SQS Queue Specification

### 3.1 Main Queue
[Configuration details]

### 3.2 Dead Letter Queue
[DLQ configuration]

### 3.3 Message Schema
[Example SQS message]

### 3.4 Event Source Mapping
[Lambda trigger configuration]

## 4. API Gateway Specification

### 4.1 Endpoints
[Complete API specification]

### 4.2 Request/Response Models
[Model schemas]

## 5. S3 Requirements

### 5.1 Email Templates Bucket
[Bucket specification and templates]

### 5.2 Order Artifacts Bucket
[Bucket specification and structure]

## 6. Security Requirements

[Security specification table]

## 7. Monitoring and Alerts

### 7.1 CloudWatch Metrics
[Metrics table with thresholds]

### 7.2 Alarms Configuration
[Alarms table]

## 8. NFRs Summary

[NFRs table]

## 9. Implementation Checklist

[Complete checklist with 40+ items]

## 10. Issues/Blockers

[Any items unclear or missing from LLD]

## 11. Cross-References

[References to LLD sections for each requirement]
```

---

## References

- **LLD Document**: `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/2.1.8_LLD_Order_Lambda.md`
- **BBWS Documentation**: `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/CLAUDE.md`

---

**Document Version**: 1.0
**Created**: 2025-12-30
