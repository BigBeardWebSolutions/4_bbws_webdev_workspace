# HLD Analysis Output

**Worker**: worker-1-hld-analysis
**Source Document**: `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/HLDs/2.1_BBWS_Customer_Portal_Public_HLD_V1.1.md`
**Analysis Date**: 2025-12-25
**HLD Version**: 1.1.1

---

## 1. Entity Summary

### 1.1 Tenant Entity

**Primary Key Pattern**: `TENANT#{tenantId}`
**Sort Key Pattern**: `METADATA`

**Attributes**:
- `id` (String, Required): Unique tenant identifier (UUID)
- `email` (String, Required): Tenant email address (used for lookup)
- `status` (String, Required): Tenant lifecycle status
- `active` (Boolean, Required): Soft delete flag (default=true)
- `dateCreated` (String, Required): Creation timestamp (ISO 8601)
- `dateLastUpdated` (String, Required): Last update timestamp (ISO 8601)
- `lastUpdatedBy` (String, Required): User who last updated the record

**Status Values**:
- `UNVALIDATED`: Created at checkout, email not verified
- `VALIDATED`: Email verified via OTP
- `REGISTERED`: Full Cognito registration complete
- `SUSPENDED`: Account suspended

**Business Rules**:
- Tenant is created automatically during checkout if email does not exist
- Email is used for tenant lookup (EmailIndex GSI)
- Tenant must exist before Order can be created (ORDER requires TENANT#)
- Same email reuses existing tenant across orders

**Relationships**:
- Parent to: Order, OrderItem, Payment
- Indexed by: EmailIndex (email → tenantId), TenantStatusIndex (status → dateCreated)

---

### 1.2 Product Entity

**Primary Key Pattern**: `PRODUCT#{productId}`
**Sort Key Pattern**: `METADATA`

**Attributes**:
- `id` (String, Required): Unique product identifier (UUID)
- `name` (String, Required): Product name
- `description` (String, Required): Product description
- `price` (Number, Required): Product price (decimal)
- `features` (List, Optional): Array of feature strings
- `billingCycle` (String, Required): Billing cycle (e.g., "monthly")
- `active` (Boolean, Required): Soft delete flag (default=true, false=soft deleted)
- `dateCreated` (String, Required): Creation timestamp (ISO 8601)
- `dateLastUpdated` (String, Required): Last update timestamp (ISO 8601)
- `lastUpdatedBy` (String, Required): User who last updated the record

**Pricing Structure**:
- Price is stored as decimal (e.g., 299.99)
- Currency is ZAR (South African Rand) - stored at Order level
- Discounts are applied via Campaign entity (not stored in Product)

**Soft Delete Pattern**:
- `active=true`: Product is available
- `active=false`: Product is soft deleted (excluded from default listings)
- Query parameter `includeInactive=true` shows soft-deleted products

**Relationships**:
- Referenced by: Campaign (productId), OrderItem (productId)
- Indexed by: ProductActiveIndex (active → dateCreated)

---

### 1.3 Campaign Entity

**Primary Key Pattern**: `CAMPAIGN#{code}`
**Sort Key Pattern**: `METADATA`

**Attributes**:
- `id` (String, Required): Unique campaign identifier (UUID)
- `code` (String, Required): Campaign code (used in PK and URLs, e.g., "SUMMER2025")
- `description` (String, Required): Campaign description
- `discountPercentage` (Number, Required): Discount percentage (0-100)
- `productId` (String, Required): Associated product identifier
- `termsConditionsLink` (String, Required): URL to terms and conditions document
- `fromDate` (String, Required): Campaign start date (ISO 8601 format: YYYY-MM-DD)
- `toDate` (String, Required): Campaign end date (ISO 8601 format: YYYY-MM-DD)
- `active` (Boolean, Required): Soft delete flag (default=true, false=soft deleted)
- `dateCreated` (String, Required): Creation timestamp (ISO 8601)
- `dateLastUpdated` (String, Required): Last update timestamp (ISO 8601)
- `lastUpdatedBy` (String, Required): User who last updated the record

**Computed Attributes** (returned in GET responses, not stored):
- `productName` (String): Product name from associated Product
- `originalPrice` (Number): Original product price
- `discountedPrice` (Number): Calculated as `originalPrice * (1 - discountPercentage/100)`
- `isValid` (Boolean): True if current date is between fromDate and toDate AND active=true

**Discount Logic**:
- Discount is percentage-based (e.g., 20.0 = 20% off)
- Applied to product price at Order creation time
- Campaign validation occurs at Order creation (date range + active status)
- Campaign is embedded in Order entity (full campaign object snapshot)

**Relationships**:
- References: Product (productId)
- Embedded in: Order (campaign object)
- Indexed by: CampaignActiveIndex (active → fromDate), CampaignProductIndex (productId → fromDate)

---

### 1.4 Order Entity

**Primary Key Pattern**: `TENANT#{tenantId}`
**Sort Key Pattern**: `ORDER#{orderId}`

**Attributes**:
- `id` (String, Required): Unique order identifier (UUID)
- `tenantId` (String, Required): Associated tenant identifier (from PK)
- `customerEmail` (String, Required): Customer email address
- `status` (String, Required): Order status
- `items` (List, Required): Array of order items (embedded objects)
- `subtotal` (Number, Required): Subtotal before tax
- `tax` (Number, Required): Tax amount
- `total` (Number, Required): Total amount (subtotal + tax)
- `currency` (String, Required): Currency code (e.g., "ZAR")
- `campaign` (Object, Optional): Embedded campaign object (snapshot at order time)
- `billingAddress` (Object, Required): Billing address object
- `paymentMethod` (String, Required): Payment method (e.g., "payfast")
- `paymentDetails` (Object, Optional): Payment details object (added after payment)
- `cancellationReason` (String, Optional): Reason for cancellation (if status=CANCELLED)
- `active` (Boolean, Required): Soft delete flag (default=true)
- `dateCreated` (String, Required): Creation timestamp (ISO 8601)
- `dateLastUpdated` (String, Required): Last update timestamp (ISO 8601)
- `lastUpdatedBy` (String, Required): User who last updated the record

**Status Values**:
- `PENDING_PAYMENT`: Order created, awaiting payment
- `PAID`: Payment confirmed
- `PROCESSING`: Order being processed
- `COMPLETED`: Order completed
- `CANCELLED`: Order cancelled by user
- `REFUNDED`: Order refunded

**Embedded Objects**:
- `billingAddress`: { street, city, province, postalCode, country }
- `campaign`: Full campaign object snapshot (id, code, description, discountPercentage, productId, termsConditionsLink, fromDate, toDate, isValid, active, dateCreated, dateLastUpdated, lastUpdatedBy)
- `paymentDetails`: { paymentId, payfastPaymentId, status, paidAt }

**Business Rules**:
- Order MUST always have TENANT# in PK (tenant created if not exists)
- Campaign is optional but embedded at order creation time (snapshot)
- Order items are embedded in Order entity (not separate entities)
- Soft delete sets `active=false` (not physical deletion)

**Relationships**:
- Child of: Tenant (PK contains TENANT#{tenantId})
- Parent to: OrderItem (embedded), Payment (PK pattern includes ORDER#)
- References: Campaign (embedded object), Product (via OrderItem)
- Indexed by: OrderStatusIndex (status → dateCreated), OrderTenantIndex (tenantId → dateCreated)

---

### 1.5 OrderItem Entity

**Primary Key Pattern**: `TENANT#{tenantId}#ORDER#{orderId}`
**Sort Key Pattern**: `ITEM#{itemId}`

**Attributes** (embedded in Order entity):
- `id` (String, Required): Unique item identifier (UUID)
- `productId` (String, Required): Associated product identifier
- `productName` (String, Required): Product name (snapshot)
- `quantity` (Number, Required): Quantity ordered
- `unitPrice` (Number, Required): Unit price (original product price)
- `discount` (Number, Required): Discount amount applied
- `subtotal` (Number, Required): Subtotal after discount (unitPrice * quantity - discount)
- `active` (Boolean, Required): Soft delete flag
- `dateCreated` (String, Required): Creation timestamp (ISO 8601)
- `dateLastUpdated` (String, Required): Last update timestamp (ISO 8601)
- `lastUpdatedBy` (String, Required): User who last updated the record

**Business Rules**:
- OrderItem is embedded in Order entity (in `items` array)
- Product data is snapshot at order time (productName, unitPrice)
- Discount is calculated from Campaign at order creation
- Subtotal = (unitPrice * quantity) - discount

**Relationships**:
- Child of: Order (embedded in items array)
- References: Product (productId)

---

### 1.6 Payment Entity

**Primary Key Pattern**: `TENANT#{tenantId}#ORDER#{orderId}`
**Sort Key Pattern**: `PAYMENT#{paymentId}`

**Attributes**:
- `id` (String, Required): Unique payment identifier (UUID)
- `orderId` (String, Required): Associated order identifier (from PK)
- `amount` (Number, Required): Payment amount
- `status` (String, Required): Payment status
- `payfastId` (String, Optional): PayFast payment identifier
- `paidAt` (String, Optional): Payment timestamp (ISO 8601)
- `active` (Boolean, Required): Soft delete flag
- `dateCreated` (String, Required): Creation timestamp (ISO 8601)
- `dateLastUpdated` (String, Required): Last update timestamp (ISO 8601)
- `lastUpdatedBy` (String, Required): User who last updated the record

**Payment Status Values**:
- `PENDING`: Payment initiated
- `COMPLETED`: Payment successful
- `FAILED`: Payment failed
- `REFUNDED`: Payment refunded

**Business Rules**:
- Payment MUST always have TENANT# via Order (PK inherited from Order)
- Payment is created after order, linked via orderId in PK
- PayFast integration provides payfastId after payment initiation
- Payment updates Order.paymentDetails and Order.status

**Relationships**:
- Child of: Order (PK contains TENANT#{tenantId}#ORDER#{orderId})
- Updates: Order (paymentDetails object and status)
- Indexed by: PaymentOrderIndex (orderId → dateCreated)

---

### 1.7 NewsletterSubscription Entity

**Primary Key Pattern**: `NEWSLETTER#{email}`
**Sort Key Pattern**: `METADATA`

**Attributes**:
- `id` (String, Required): Unique subscription identifier (UUID)
- `email` (String, Required): Subscriber email address (in PK)
- `active` (Boolean, Required): Soft delete flag (default=true)
- `subscribedAt` (String, Required): Subscription timestamp (ISO 8601)
- `preferences` (Object, Optional): Subscription preferences

**Business Rules**:
- Email is used as PK for uniqueness
- Unsubscribe sets `active=false`
- No relationship to Tenant entity

---

## 2. Table Relationships

### 2.1 Primary Key (PK) Patterns

| Entity | PK Pattern | Purpose |
|--------|------------|---------|
| Tenant | `TENANT#{tenantId}` | Unique tenant identifier |
| Product | `PRODUCT#{productId}` | Unique product identifier |
| Campaign | `CAMPAIGN#{code}` | Campaign code (business key, not UUID) |
| Order | `TENANT#{tenantId}` | Orders belong to tenant (hierarchical) |
| OrderItem | `TENANT#{tenantId}#ORDER#{orderId}` | Items belong to order (embedded in Order) |
| Payment | `TENANT#{tenantId}#ORDER#{orderId}` | Payments belong to order |
| NewsletterSub | `NEWSLETTER#{email}` | Email is unique identifier |

**Key Observations**:
- Hierarchical PK pattern: Tenant → Order → OrderItem/Payment
- All Orders and Payments are scoped to a Tenant (TENANT# prefix)
- Campaign uses business key (code) not UUID in PK
- OrderItem is embedded in Order (not separate SK in current design based on API responses)

---

### 2.2 Sort Key (SK) Patterns

| Entity | SK Pattern | Purpose |
|--------|------------|---------|
| Tenant | `METADATA` | Single item per tenant |
| Product | `METADATA` | Single item per product |
| Campaign | `METADATA` | Single item per campaign |
| Order | `ORDER#{orderId}` | Multiple orders per tenant |
| OrderItem | `ITEM#{itemId}` | Multiple items per order (if stored separately) |
| Payment | `PAYMENT#{paymentId}` | Multiple payments per order |
| NewsletterSub | `METADATA` | Single item per email |

**Key Observations**:
- `METADATA` SK used for single-item entities
- Prefixed UUIDs (ORDER#, ITEM#, PAYMENT#) for one-to-many relationships
- SK enables querying all orders for a tenant, all payments for an order

---

### 2.3 GSI Requirements

Based on Section 8.3 of the HLD:

| GSI Name | PK | SK | Purpose | Entities |
|----------|----|----|---------|----------|
| EmailIndex | email | entityType | Find tenant by email | Tenant |
| OrderStatusIndex | status | dateCreated | List orders by status | Order |
| OrderTenantIndex | tenantId | dateCreated | List orders by tenant | Order |
| PaymentOrderIndex | orderId | dateCreated | List payments by order | Payment |
| ProductActiveIndex | active | dateCreated | List active products | Product |
| CampaignActiveIndex | active | fromDate | List active campaigns by date | Campaign |
| CampaignProductIndex | productId | fromDate | List campaigns by product | Campaign |
| TenantStatusIndex | status | dateCreated | List tenants by status | Tenant |
| ActiveIndex | active | dateCreated | Filter by active status (sparse index, all entities) | All entities |

**Query Patterns Supported**:
1. Find tenant by email (EmailIndex)
2. List orders by status (OrderStatusIndex)
3. List orders for a tenant (OrderTenantIndex or base table query)
4. List payments for an order (PaymentOrderIndex)
5. List active products (ProductActiveIndex with active=true filter)
6. List active campaigns (CampaignActiveIndex with active=true filter)
7. List campaigns for a product (CampaignProductIndex)
8. List tenants by status (TenantStatusIndex)
9. Sparse index for soft delete queries across all entities (ActiveIndex)

---

### 2.4 Entity Hierarchy

```
TENANT (Root)
├── PK: TENANT#{tenantId}
├── SK: METADATA
│
├─── ORDER (Child of Tenant)
│    ├── PK: TENANT#{tenantId}
│    ├── SK: ORDER#{orderId}
│    │
│    ├─── ORDERITEM (Embedded in Order.items array)
│    │    └── No separate DynamoDB record (embedded JSON)
│    │
│    └─── PAYMENT (Child of Order)
│         ├── PK: TENANT#{tenantId}#ORDER#{orderId}
│         └── SK: PAYMENT#{paymentId}
│
PRODUCT (Standalone)
├── PK: PRODUCT#{productId}
├── SK: METADATA
│
CAMPAIGN (Standalone, references Product)
├── PK: CAMPAIGN#{code}
├── SK: METADATA
├── References: PRODUCT (productId)
│
NEWSLETTERSUB (Standalone)
├── PK: NEWSLETTER#{email}
├── SK: METADATA
```

**Hierarchy Rules**:
1. **Tenant is root**: All orders and payments trace back to a tenant
2. **Order requires Tenant**: PK=TENANT#{tenantId} enforces tenant existence
3. **Payment requires Order**: PK=TENANT#{tenantId}#ORDER#{orderId} enforces order existence
4. **OrderItem is embedded**: Stored in Order.items array (not separate DynamoDB items)
5. **Campaign references Product**: Weak reference via productId (no PK dependency)
6. **NewsletterSub is independent**: No relationship to Tenant

**Access Patterns**:
- Get tenant orders: Query where PK=TENANT#{tenantId} and SK begins_with ORDER#
- Get order payments: Query where PK=TENANT#{tenantId}#ORDER#{orderId} and SK begins_with PAYMENT#
- Get order items: Read Order entity, access items array

---

### 2.5 Relationship Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    ENTITY RELATIONSHIPS                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  TENANT                                                         │
│  PK: TENANT#{tenantId}                                          │
│  SK: METADATA                                                   │
│  Attributes: id, email, status, active                          │
│  Status: UNVALIDATED → VALIDATED → REGISTERED → SUSPENDED      │
│       │                                                         │
│       │ (1:N)                                                   │
│       ▼                                                         │
│  ORDER                                                          │
│  PK: TENANT#{tenantId}                                          │
│  SK: ORDER#{orderId}                                            │
│  Attributes: id, status, total, campaign (embedded), items[]    │
│  Status: PENDING_PAYMENT → PAID → PROCESSING → COMPLETED       │
│       │                                                         │
│       │ (1:1 embedded)                                          │
│       ├──► ORDERITEM (embedded in Order.items array)           │
│       │    Attributes: id, productId, quantity, price, discount │
│       │                                                         │
│       │ (1:N)                                                   │
│       ▼                                                         │
│  PAYMENT                                                        │
│  PK: TENANT#{tenantId}#ORDER#{orderId}                          │
│  SK: PAYMENT#{paymentId}                                        │
│  Attributes: id, amount, status, payfastId, paidAt              │
│  Status: PENDING → COMPLETED → FAILED → REFUNDED               │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  PRODUCT (Standalone)                                           │
│  PK: PRODUCT#{productId}                                        │
│  SK: METADATA                                                   │
│  Attributes: id, name, price, description, active               │
│       │                                                         │
│       │ (Referenced by)                                         │
│       ├──► CAMPAIGN.productId                                   │
│       └──► ORDERITEM.productId (snapshot)                       │
│                                                                 │
│  CAMPAIGN (Standalone, references Product)                      │
│  PK: CAMPAIGN#{code}                                            │
│  SK: METADATA                                                   │
│  Attributes: id, code, discountPercentage, productId,           │
│             fromDate, toDate, active                            │
│       │                                                         │
│       │ (Embedded in Order at creation time)                    │
│       └──► ORDER.campaign (embedded object snapshot)            │
│                                                                 │
│  NEWSLETTERSUB (Standalone)                                     │
│  PK: NEWSLETTER#{email}                                         │
│  SK: METADATA                                                   │
│  Attributes: id, email, active, subscribedAt, preferences       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 3. S3 Requirements

### 3.1 Required S3 Buckets

Based on Section 9.2 (Infrastructure) and operational needs:

| Bucket Name Pattern | Environment Variable | Purpose | Lifecycle | Public Access |
|---------------------|---------------------|---------|-----------|---------------|
| `bbws-templates-{env}` | `TEMPLATE_BUCKET_NAME` | Email templates (HTML), PDF templates | Retain | Blocked |
| `bbws-receipts-{env}` | `RECEIPTS_BUCKET_NAME` | Generated order receipts (PDF) | 7 years | Blocked |
| `bbws-static-assets-{env}` | `STATIC_ASSETS_BUCKET_NAME` | Static assets for frontend (images, CSS, JS) | Retain | Blocked (CloudFront only) |
| `bbws-lambda-artifacts-{env}` | `ARTIFACTS_BUCKET_NAME` | Lambda deployment packages (.zip) | 90 days | Blocked |
| `bbws-logs-{env}` | `LOGS_BUCKET_NAME` | Application logs, audit logs | 90 days | Blocked |

**Environment Suffixes**:
- `{env}` = `dev`, `sit`, `prod`
- Example: `bbws-templates-dev`, `bbws-templates-sit`, `bbws-templates-prod`

**Bucket Tagging** (all buckets):
```json
{
  "Project": "2.1",
  "Application": "CustomerPortalPublic",
  "Environment": "{env}",
  "ManagedBy": "Terraform"
}
```

---

### 3.2 Template Requirements

#### 3.2.1 Email Templates

**Bucket**: `bbws-templates-{env}`
**Base Path**: `/email-templates/`

| Template File | Purpose | Variables | Format |
|---------------|---------|-----------|--------|
| `registration-confirmation.html` | Registration confirmation email | `{customerName}`, `{verificationLink}`, `{otpCode}` | HTML |
| `password-reset.html` | Password reset email | `{customerName}`, `{resetLink}`, `{expiryTime}` | HTML |
| `otp-verification.html` | OTP verification email | `{customerName}`, `{otpCode}`, `{expiryMinutes}` | HTML |
| `order-confirmation.html` | Order confirmation email | `{customerName}`, `{orderId}`, `{orderItems}`, `{total}`, `{orderDate}` | HTML |
| `payment-receipt.html` | Payment receipt email | `{customerName}`, `{orderId}`, `{paymentId}`, `{amount}`, `{paidAt}` | HTML |
| `payment-failed.html` | Payment failed notification | `{customerName}`, `{orderId}`, `{retryLink}`, `{failureReason}` | HTML |
| `campaign-notification.html` | Campaign promotional email | `{customerName}`, `{campaignCode}`, `{discountPercentage}`, `{productName}`, `{expiryDate}` | HTML |

**Template Structure** (example):
```html
<!-- /email-templates/order-confirmation.html -->
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Order Confirmation - BBWS</title>
</head>
<body>
  <h1>Thank you for your order, {{customerName}}!</h1>
  <p>Order ID: {{orderId}}</p>
  <p>Order Date: {{orderDate}}</p>
  <h2>Order Items:</h2>
  {{#each orderItems}}
  <div>
    <p>{{productName}} - {{quantity}} x R{{unitPrice}} = R{{subtotal}}</p>
  </div>
  {{/each}}
  <h3>Total: R{{total}}</h3>
  <p>We'll process your order shortly.</p>
</body>
</html>
```

---

#### 3.2.2 Receipt Templates

**Bucket**: `bbws-templates-{env}`
**Base Path**: `/receipt-templates/`

| Template File | Purpose | Variables | Format |
|---------------|---------|-----------|--------|
| `order-receipt.html` | HTML receipt for PDF generation | `{orderId}`, `{customerEmail}`, `{orderDate}`, `{items}`, `{subtotal}`, `{tax}`, `{total}`, `{billingAddress}` | HTML |
| `payment-receipt.html` | Payment receipt for PDF | `{paymentId}`, `{orderId}`, `{customerEmail}`, `{amount}`, `{paidAt}`, `{payfastId}` | HTML |

**Receipt Generation Flow**:
1. Lambda retrieves template from `bbws-templates-{env}/receipt-templates/`
2. Lambda populates template with order/payment data
3. Lambda generates PDF using library (e.g., WeasyPrint, wkhtmltopdf)
4. Lambda uploads PDF to `bbws-receipts-{env}/orders/{tenantId}/{orderId}/receipt.pdf`
5. Lambda sends email with PDF attachment or download link

---

### 3.3 File Paths and Naming Patterns

#### 3.3.1 Receipt Storage Paths

**Bucket**: `bbws-receipts-{env}`

**Path Pattern**: `/orders/{tenantId}/{orderId}/`

**File Naming**:
- Order receipt: `receipt-{orderId}-{timestamp}.pdf`
- Payment receipt: `payment-{paymentId}-{timestamp}.pdf`

**Example**:
```
bbws-receipts-prod/
└── orders/
    └── tenant_bb0e8400-e29b-41d4-a716-446655440006/
        └── order_aa0e8400-e29b-41d4-a716-446655440005/
            ├── receipt-order_aa0e8400-e29b-41d4-a716-446655440005-2025-12-19T10-30-00Z.pdf
            └── payment-payment_ee0e8400-e29b-41d4-a716-446655440009-2025-12-19T10-45-00Z.pdf
```

---

#### 3.3.2 Lambda Artifact Paths

**Bucket**: `bbws-lambda-artifacts-{env}`

**Path Pattern**: `/{service-name}/{version}/`

**File Naming**: `{function-name}-{version}.zip`

**Example**:
```
bbws-lambda-artifacts-dev/
├── product-lambda/
│   └── 1.0.0/
│       ├── create-product-1.0.0.zip
│       ├── get-product-1.0.0.zip
│       ├── update-product-1.0.0.zip
│       ├── list-products-1.0.0.zip
│       └── soft-delete-product-1.0.0.zip
├── campaign-lambda/
│   └── 1.0.0/
│       ├── create-campaign-1.0.0.zip
│       ├── get-campaign-1.0.0.zip
│       ├── update-campaign-1.0.0.zip
│       ├── list-campaigns-1.0.0.zip
│       └── soft-delete-campaign-1.0.0.zip
└── order-lambda/
    └── 1.0.0/
        ├── create-order-1.0.0.zip
        ├── get-order-1.0.0.zip
        ├── update-order-1.0.0.zip
        └── list-orders-1.0.0.zip
```

---

#### 3.3.3 Static Asset Paths

**Bucket**: `bbws-static-assets-{env}`

**Path Pattern**: `/{asset-type}/`

**Example**:
```
bbws-static-assets-prod/
├── images/
│   ├── logos/
│   │   ├── bbws-logo.png
│   │   └── bbws-logo-dark.png
│   ├── products/
│   │   ├── product-starter.jpg
│   │   └── product-professional.jpg
│   └── campaigns/
│       └── summer2025-banner.jpg
├── css/
│   └── (managed by frontend build)
└── js/
    └── (managed by frontend build)
```

**Access**: CloudFront CDN only (no direct S3 public access)

---

### 3.4 S3 Bucket Policies

#### 3.4.1 Templates Bucket Policy

**Purpose**: Allow Lambda functions to read templates

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowLambdaReadTemplates",
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "arn:aws:iam::536580886816:role/2-1-bbws-order-lambda-role",
          "arn:aws:iam::536580886816:role/2-1-bbws-payment-lambda-role"
        ]
      },
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::bbws-templates-dev",
        "arn:aws:s3:::bbws-templates-dev/*"
      ]
    }
  ]
}
```

---

#### 3.4.2 Receipts Bucket Policy

**Purpose**: Allow Lambda to write receipts, restrict read access

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowLambdaWriteReceipts",
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "arn:aws:iam::536580886816:role/2-1-bbws-order-lambda-role",
          "arn:aws:iam::536580886816:role/2-1-bbws-payment-lambda-role"
        ]
      },
      "Action": [
        "s3:PutObject",
        "s3:PutObjectAcl"
      ],
      "Resource": "arn:aws:s3:::bbws-receipts-dev/orders/*/*"
    },
    {
      "Sid": "AllowLambdaReadReceipts",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::536580886816:role/2-1-bbws-order-lambda-role"
      },
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::bbws-receipts-dev/orders/*/*"
    }
  ]
}
```

---

## 4. Architectural Constraints

### 4.1 Soft Delete Pattern

**Requirement**: All entities must use soft delete (active boolean field)

**Implementation**:
- **Field**: `active` (Boolean, Required, Default=true)
- **Soft Delete**: Set `active=false` (not physical deletion)
- **Query Filter**: All list queries filter by `active=true` by default
- **Override**: Use query parameter `includeInactive=true` to include soft-deleted records

**API Pattern**:
- **No DELETE operations**: Use PUT to update `active=false`
- **Example**: `PUT /v1.0/products/{productId}` with body `{"active": false}`

**Rationale** (from Section 1.3):
- Audit trail preservation
- Data recovery capability
- Referential integrity maintenance
- Historical data analysis

**Applies to**:
- Tenant
- Product
- Campaign
- Order
- OrderItem (embedded in Order)
- Payment
- NewsletterSubscription

**Example Query**:
```python
# Default: Active only
response = table.query(
    KeyConditionExpression=Key('PK').eq('TENANT#123'),
    FilterExpression=Attr('active').eq(True)
)

# Include inactive
response = table.query(
    KeyConditionExpression=Key('PK').eq('TENANT#123'),
    FilterExpression=Attr('active').eq(True) | Attr('active').eq(False)  # or no filter
)
```

---

### 4.2 Capacity Mode Requirements

**Requirement**: On-demand capacity mode for all DynamoDB tables

**From Global CLAUDE.md**:
> DynamoDB table capacity mode must always be "on-demand"

**Configuration**:
- **Billing Mode**: `PAY_PER_REQUEST`
- **Read/Write Capacity**: Automatically scaled by AWS
- **No Provisioned Capacity**: Do not set RCU/WCU

**Terraform Example**:
```hcl
resource "aws_dynamodb_table" "customer_portal_table" {
  name           = "2-1-bbws-customer-portal-${var.environment}"
  billing_mode   = "PAY_PER_REQUEST"  # Required
  hash_key       = "PK"
  range_key      = "SK"

  # ... attributes, GSIs, etc.
}
```

**Rationale**:
- Serverless workload (unpredictable traffic)
- Cost-effective for low-traffic startup phase
- Auto-scales to handle traffic spikes
- No capacity planning required

**Applies to**:
- Main table: `2-1-bbws-customer-portal-{env}`
- All GSIs on the table

---

### 4.3 Point-in-Time Recovery (PITR)

**Requirement**: PITR must be enabled for all DynamoDB tables

**Configuration**:
- **Enabled**: `true`
- **Retention**: 35 days (AWS maximum)

**Terraform Example**:
```hcl
resource "aws_dynamodb_table" "customer_portal_table" {
  name         = "2-1-bbws-customer-portal-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"

  point_in_time_recovery {
    enabled = true
  }

  # ... other configuration
}
```

**Rationale**:
- Disaster recovery capability
- Protection against accidental deletes/updates
- Continuous backups with no performance impact
- Meets compliance requirements

**Applies to**:
- DEV: Enabled
- SIT: Enabled
- PROD: Enabled

---

### 4.4 Cross-Region Replication

**Requirement**: Cross-region replication for PROD only

**From Global CLAUDE.md**:
> primary region for prod is af-south-1 and failover region is eu-west-1
> Disaster recovery strategy: multisite active/active DR... hourly DynamoDB backups and do cross-region replication of DynamoDB... cross-region replication of S3

**Configuration**:

**DynamoDB Global Tables**:
- **Primary Region**: `af-south-1` (Cape Town)
- **Replica Region**: `eu-west-1` (Ireland)
- **Replication**: Continuous (millisecond latency)

**Terraform Example**:
```hcl
resource "aws_dynamodb_table" "customer_portal_table" {
  name         = "2-1-bbws-customer-portal-prod"
  billing_mode = "PAY_PER_REQUEST"

  # Primary region: af-south-1
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  replica {
    region_name = "eu-west-1"
  }

  # ... other configuration
}
```

**S3 Cross-Region Replication**:
- **Source Buckets**: All prod buckets in `af-south-1`
- **Destination Buckets**: Replica buckets in `eu-west-1`
- **Replication Rules**: All objects

**S3 Terraform Example**:
```hcl
resource "aws_s3_bucket_replication_configuration" "templates_replication" {
  bucket = aws_s3_bucket.templates_prod.id
  role   = aws_iam_role.replication_role.arn

  rule {
    id     = "ReplicateAllToEuWest1"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.templates_prod_replica_eu_west_1.arn
      storage_class = "STANDARD"
    }
  }
}
```

**Applies to**:
- **PROD only**: DynamoDB Global Table, S3 CRR
- **DEV/SIT**: No replication (single region only)

**Failover Strategy**:
- **Route 53**: Health checks on primary region
- **Automatic Failover**: DNS failover to `eu-west-1` on primary region failure
- **Manual Failback**: After primary region recovery

---

### 4.5 Tagging Requirements

**Requirement**: All resources must have standard tags

**Mandatory Tags** (from HLD Section 10.4):

| Tag Key | Tag Value | Purpose |
|---------|-----------|---------|
| `Project` | `2.1` | Project identifier (from HLD prefix) |
| `Application` | `CustomerPortalPublic` | Application name |
| `Environment` | `dev`, `sit`, `prod` | Environment identifier |
| `ManagedBy` | `Terraform` | IaC tool |
| `Service` | `{service-name}` | Microservice name (e.g., `ProductLambda`, `OrderLambda`) |

**Optional Tags**:

| Tag Key | Example Value | Purpose |
|---------|---------------|---------|
| `Owner` | `devops@bigbeard.co.za` | Team owner |
| `CostCenter` | `Engineering` | Cost allocation |
| `Compliance` | `POPIA` | Compliance requirements |

**Terraform Example**:
```hcl
locals {
  common_tags = {
    Project      = "2.1"
    Application  = "CustomerPortalPublic"
    Environment  = var.environment
    ManagedBy    = "Terraform"
    Owner        = "devops@bigbeard.co.za"
  }
}

resource "aws_dynamodb_table" "customer_portal_table" {
  name         = "2-1-bbws-customer-portal-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"

  tags = merge(local.common_tags, {
    Service = "DynamoDB"
    Name    = "customer-portal-table"
  })
}

resource "aws_s3_bucket" "templates" {
  bucket = "bbws-templates-${var.environment}"

  tags = merge(local.common_tags, {
    Service = "S3"
    Purpose = "EmailTemplates"
  })
}
```

**Rationale**:
- Cost tracking and allocation
- Resource ownership identification
- Environment segregation
- Compliance and audit trails
- Automated resource management

**Applies to**:
- DynamoDB tables and GSIs
- S3 buckets
- Lambda functions
- API Gateway resources
- CloudFront distributions
- IAM roles and policies
- CloudWatch alarms and dashboards
- SNS topics and SQS queues

---

### 4.6 Encryption Requirements

**Requirement**: Encryption at rest and in transit

**DynamoDB Encryption**:
- **At Rest**: AWS managed keys (KMS)
- **Default**: `AWS_OWNED_CMK` (no cost)
- **Optional**: Customer managed CMK for compliance

**Terraform Example**:
```hcl
resource "aws_dynamodb_table" "customer_portal_table" {
  name         = "2-1-bbws-customer-portal-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.environment == "prod" ? aws_kms_key.dynamodb_prod.arn : null
  }
}
```

**S3 Encryption**:
- **At Rest**: SSE-S3 or SSE-KMS
- **In Transit**: TLS 1.2+ required

**S3 Terraform Example**:
```hcl
resource "aws_s3_bucket_server_side_encryption_configuration" "templates" {
  bucket = aws_s3_bucket.templates.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "templates" {
  bucket                  = aws_s3_bucket.templates.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

**From Global CLAUDE.md**:
> all buckets in all environments, dev, sit and prod must never have public access. public access in all s3 buckets must be blocked

**Applies to**:
- All DynamoDB tables
- All S3 buckets
- Lambda environment variables (sensitive data)

---

### 4.7 Activatable Entity Pattern

**Requirement**: All entities must follow the Activatable Entity Pattern

**From HLD Section 1.3**:
> Entity Pattern: Activatable Entity Pattern - All entities: id, dateCreated, dateLastUpdated, lastUpdatedBy, active

**Mandatory Fields** (all entities):

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `id` | String (UUID) | Yes | Generated | Unique identifier |
| `dateCreated` | String (ISO 8601) | Yes | Auto | Creation timestamp |
| `dateLastUpdated` | String (ISO 8601) | Yes | Auto | Last update timestamp |
| `lastUpdatedBy` | String (email) | Yes | From context | User/system who last updated |
| `active` | Boolean | Yes | `true` | Soft delete flag |

**Implementation Pattern**:
```python
# Python Lambda example
import uuid
from datetime import datetime

def create_entity(entity_data, user_email):
    return {
        "id": str(uuid.uuid4()),
        "dateCreated": datetime.utcnow().isoformat() + "Z",
        "dateLastUpdated": datetime.utcnow().isoformat() + "Z",
        "lastUpdatedBy": user_email,
        "active": True,
        **entity_data  # Merge entity-specific fields
    }

def update_entity(existing_entity, updates, user_email):
    existing_entity.update({
        "dateLastUpdated": datetime.utcnow().isoformat() + "Z",
        "lastUpdatedBy": user_email,
        **updates
    })
    return existing_entity
```

**Applies to**:
- Tenant
- Product
- Campaign
- Order
- OrderItem
- Payment
- NewsletterSubscription

**Benefits**:
- Consistent audit trail across all entities
- Standardized soft delete mechanism
- Simplified data governance
- Easier debugging and troubleshooting

---

### 4.8 Environment Parameterization

**Requirement**: Never hardcode environment credentials

**From Global CLAUDE.md**:
> never hardcode environment credentials, parameterise them so that we can deploy to any environment without breaking the system. Automate everything

**Environment Variables** (Lambda):

| Variable | DEV Value | SIT Value | PROD Value | Purpose |
|----------|-----------|-----------|------------|---------|
| `DYNAMODB_TABLE_NAME` | `2-1-bbws-customer-portal-dev` | `2-1-bbws-customer-portal-sit` | `2-1-bbws-customer-portal-prod` | DynamoDB table |
| `TEMPLATE_BUCKET_NAME` | `bbws-templates-dev` | `bbws-templates-sit` | `bbws-templates-prod` | Email templates |
| `RECEIPTS_BUCKET_NAME` | `bbws-receipts-dev` | `bbws-receipts-sit` | `bbws-receipts-prod` | Order receipts |
| `ENVIRONMENT` | `dev` | `sit` | `prod` | Environment identifier |
| `AWS_REGION` | `af-south-1` | `af-south-1` | `af-south-1` | AWS region |
| `LOG_LEVEL` | `DEBUG` | `INFO` | `WARNING` | Logging level |

**Terraform Parameterization**:
```hcl
variable "environment" {
  description = "Environment name"
  type        = string
  validation {
    condition     = contains(["dev", "sit", "prod"], var.environment)
    error_message = "Environment must be dev, sit, or prod."
  }
}

resource "aws_lambda_function" "product_lambda" {
  function_name = "2-1-bbws-product-lambda-${var.environment}"

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = aws_dynamodb_table.customer_portal_table.name
      TEMPLATE_BUCKET_NAME = aws_s3_bucket.templates.id
      RECEIPTS_BUCKET_NAME = aws_s3_bucket.receipts.id
      ENVIRONMENT          = var.environment
      LOG_LEVEL            = var.environment == "prod" ? "WARNING" : "DEBUG"
    }
  }
}
```

**Deployment Automation**:
- Use Terraform workspaces or separate state files per environment
- CI/CD pipelines promote workload from DEV → SIT → PROD
- No manual credential management

---

### 4.9 Read-Only PROD Constraint

**Requirement**: PROD environment should allow read-only operations during maintenance

**From Global CLAUDE.md**:
> PROD environment should allow read-only.

**Implementation**:
- Feature flag or environment variable: `READ_ONLY_MODE=true/false`
- Lambda functions check flag before write operations
- Return HTTP 503 (Service Unavailable) during read-only mode

**Lambda Example**:
```python
import os

READ_ONLY_MODE = os.environ.get('READ_ONLY_MODE', 'false').lower() == 'true'

def create_product_handler(event, context):
    if READ_ONLY_MODE:
        return {
            'statusCode': 503,
            'body': json.dumps({
                'error': 'ServiceUnavailable',
                'message': 'System is in read-only mode for maintenance.'
            })
        }

    # Normal create logic
    ...
```

**Use Cases**:
- During database migration
- During disaster recovery failover
- During major maintenance windows

**Applies to**:
- All write operations (POST, PUT)
- Read operations (GET) remain available

---

## 5. API Patterns

### 5.1 Hierarchical HATEOAS Pattern

**Principle**: URLs reflect entity ownership and relationships

**From HLD Section 1.3**:
> API Structure: Hierarchical HATEOAS - URLs reflect entity relationships, explicit ownership context

**Pattern Examples**:

| Resource | Endpoint Pattern | Ownership Context |
|----------|------------------|-------------------|
| Tenant Orders | `/v1.0/tenants/{tenantId}/orders` | Orders belong to tenant |
| Tenant Order Detail | `/v1.0/tenants/{tenantId}/orders/{orderId}` | Specific order for tenant |
| Order (alternate) | `/v1.0/orders/{orderId}` | Direct order access (no context) |
| Products | `/v1.0/products` | Standalone resource (no owner) |
| Campaigns | `/v1.0/campaigns` | Standalone resource (no owner) |
| Campaign by Code | `/v1.0/campaigns/{code}` | Campaign identified by code |

**Hierarchical Relationships**:
```
/v1.0/tenants/{tenantId}
  └── /orders
       ├── GET (list tenant's orders)
       └── POST (create order for tenant)

       /orders/{orderId}
         ├── GET (get specific order)
         └── PUT (update order)
```

**Design Decision**:
- **Tenant context is explicit**: `/v1.0/tenants/{tenantId}/orders` makes ownership clear
- **Direct access available**: `/v1.0/orders/{orderId}` for convenience (auth checks tenantId)
- **Standalone resources**: Products and Campaigns are not scoped to tenants

---

### 5.2 Entity Ownership Context

**Authentication & Authorization**:
- **Tenant-scoped endpoints**: Validate that authenticated user has access to `{tenantId}`
- **Direct endpoints**: Extract tenant from order/payment and validate ownership

**Examples**:

**Create Order (tenant context)**:
```
POST /v1.0/tenants/{tenantId}/orders
Authorization: Bearer <token>

Body:
{
  "customerEmail": "customer@example.com",
  "billingAddress": {...},
  "campaignCode": "SUMMER2025"
}

Response: 201 Created
{
  "id": "order_aa0e8400-e29b-41d4-a716-446655440005",
  "tenantId": "tenant_bb0e8400-e29b-41d4-a716-446655440006",
  ...
}
```

**Authorization Check**:
```python
def create_order_handler(event, context):
    tenant_id = event['pathParameters']['tenantId']
    user_tenant_id = get_tenant_from_token(event['headers']['Authorization'])

    if tenant_id != user_tenant_id:
        return {
            'statusCode': 403,
            'body': json.dumps({
                'error': 'Forbidden',
                'message': 'You do not have permission to create orders for this tenant.'
            })
        }

    # Create order logic
    ...
```

**Get Order (direct access)**:
```
GET /v1.0/orders/{orderId}
Authorization: Bearer <token>

Response: 200 OK
{
  "id": "order_aa0e8400-e29b-41d4-a716-446655440005",
  "tenantId": "tenant_bb0e8400-e29b-41d4-a716-446655440006",
  ...
}
```

**Authorization Check**:
```python
def get_order_handler(event, context):
    order_id = event['pathParameters']['orderId']
    order = get_order_from_dynamodb(order_id)

    user_tenant_id = get_tenant_from_token(event['headers']['Authorization'])

    if order['tenantId'] != user_tenant_id:
        return {
            'statusCode': 403,
            'body': json.dumps({
                'error': 'Forbidden',
                'message': 'You do not have permission to access this order.'
            })
        }

    return {
        'statusCode': 200,
        'body': json.dumps(order)
    }
```

**Key Principle**: Ownership is enforced at the data layer (PK contains TENANT#), API validates access

---

### 5.3 Pagination Pattern

**From HLD Section 1.3**:
> Pagination: pageSize/startAt/moreAvailable - Client-friendly, simpler than limit/next_token

**Parameters**:
- `pageSize` (integer, optional): Number of items per page. Default: `50`, Max: `100`
- `startAt` (string, optional): Pagination token (last item ID from previous page)
- `moreAvailable` (boolean, response only): True if more items exist

**Example Request**:
```
GET /v1.0/products?pageSize=10&startAt=prod_660e8400-e29b-41d4-a716-446655440001
```

**Example Response**:
```json
{
  "items": [
    {
      "id": "prod_770e8400-e29b-41d4-a716-446655440002",
      "name": "WordPress Enterprise Plan",
      ...
    },
    {
      "id": "prod_880e8400-e29b-41d4-a716-446655440003",
      "name": "WordPress Starter Plan",
      ...
    }
  ],
  "startAt": "prod_880e8400-e29b-41d4-a716-446655440003",
  "moreAvailable": true
}
```

**Implementation** (DynamoDB):
```python
def list_products(page_size=50, start_at=None):
    query_params = {
        'Limit': page_size,
        'FilterExpression': Attr('active').eq(True)
    }

    if start_at:
        # startAt is the last item ID from previous page
        query_params['ExclusiveStartKey'] = {
            'PK': f'PRODUCT#{start_at}',
            'SK': 'METADATA'
        }

    response = table.scan(**query_params)

    items = response.get('Items', [])
    last_evaluated_key = response.get('LastEvaluatedKey')

    return {
        'items': items,
        'startAt': items[-1]['id'] if items else None,
        'moreAvailable': last_evaluated_key is not None
    }
```

**Client Usage**:
```javascript
// Fetch first page
let response = await fetch('/v1.0/products?pageSize=10');
let data = await response.json();

// Fetch next page if available
if (data.moreAvailable) {
  response = await fetch(`/v1.0/products?pageSize=10&startAt=${data.startAt}`);
  data = await response.json();
}
```

**Applies to**:
- `GET /v1.0/products`
- `GET /v1.0/campaigns`
- `GET /v1.0/tenants/{tenantId}/orders`
- All list endpoints

---

### 5.4 No DELETE Operations

**Principle**: No DELETE HTTP method, use PUT to set active=false

**From HLD Section 1.3**:
> API Pattern: No DELETE operations - Status updates for all state changes

**Rationale**:
- Soft delete preserves audit trail
- Prevents accidental data loss
- Maintains referential integrity
- Enables data recovery

**Pattern**:
```
DELETE /v1.0/products/{productId}  ❌ NOT ALLOWED

PUT /v1.0/products/{productId}     ✅ CORRECT
Body: { "active": false }
```

**Example**:

**Soft Delete Product**:
```
PUT /v1.0/products/{productId}
Authorization: Bearer <admin-token>

Body:
{
  "active": false
}

Response: 200 OK
{
  "id": "prod_550e8400-e29b-41d4-a716-446655440000",
  "name": "WordPress Professional Plan",
  "active": false,
  "dateLastUpdated": "2025-12-19T15:00:00Z",
  "lastUpdatedBy": "admin@kimmyai.io"
}
```

**Query Behavior**:
- Default: `GET /v1.0/products` returns only `active=true`
- Override: `GET /v1.0/products?includeInactive=true` returns all

**Applies to**:
- Products: `PUT /v1.0/products/{productId}`
- Campaigns: `PUT /v1.0/campaigns/{code}`
- Orders: `PUT /v1.0/orders/{orderId}` (set active=false or status=CANCELLED)
- Payments: `PUT /v1.0/payments/{paymentId}`

---

### 5.5 Status Updates Pattern

**Principle**: Use PUT with status field for state changes

**Order Status Transitions**:
```
PENDING_PAYMENT → PAID → PROCESSING → COMPLETED
                    ↓
                CANCELLED
                    ↓
                REFUNDED
```

**Example**:

**Cancel Order**:
```
PUT /v1.0/orders/{orderId}
Authorization: Bearer <token>

Body:
{
  "status": "CANCELLED",
  "cancellationReason": "Customer requested cancellation"
}

Response: 200 OK
{
  "id": "order_aa0e8400-e29b-41d4-a716-446655440005",
  "status": "CANCELLED",
  "cancellationReason": "Customer requested cancellation",
  "dateLastUpdated": "2025-12-19T11:00:00Z",
  "lastUpdatedBy": "customer@example.com"
}
```

**Validation**:
- Backend validates allowed transitions (e.g., cannot cancel COMPLETED order)
- Returns 400 Bad Request for invalid transitions

**Applies to**:
- Order status updates
- Payment status updates
- Tenant status updates

---

### 5.6 HATEOAS Links Pattern

**Principle**: Include navigation links in responses (future enhancement)

**Example** (not yet implemented, but pattern defined):

```json
{
  "id": "order_aa0e8400-e29b-41d4-a716-446655440005",
  "tenantId": "tenant_bb0e8400-e29b-41d4-a716-446655440006",
  "status": "PAID",
  "total": 275.98,
  "_links": {
    "self": {
      "href": "/v1.0/orders/order_aa0e8400-e29b-41d4-a716-446655440005"
    },
    "tenant": {
      "href": "/v1.0/tenants/tenant_bb0e8400-e29b-41d4-a716-446655440006"
    },
    "payments": {
      "href": "/v1.0/orders/order_aa0e8400-e29b-41d4-a716-446655440005/payments"
    },
    "cancel": {
      "href": "/v1.0/orders/order_aa0e8400-e29b-41d4-a716-446655440005",
      "method": "PUT",
      "body": { "status": "CANCELLED" }
    }
  }
}
```

**Future Work**: Add `_links` to all entity responses for discoverability

---

### 5.7 Error Response Pattern

**Standardized Error Format**:

```json
{
  "error": "ErrorType",
  "message": "Human-readable error message",
  "details": [
    {
      "field": "fieldName",
      "message": "Field-specific error message"
    }
  ]
}
```

**Error Types**:
- `ValidationError` (400): Invalid input data
- `NotFound` (404): Resource not found
- `Forbidden` (403): Access denied
- `ConflictError` (409): Resource already exists
- `ServiceUnavailable` (503): Read-only mode or maintenance
- `TooManyRequests` (429): Rate limit exceeded

**Examples**:

**Validation Error (400)**:
```json
{
  "error": "ValidationError",
  "message": "Invalid product data",
  "details": [
    {
      "field": "price",
      "message": "Price must be a positive number"
    },
    {
      "field": "name",
      "message": "Product name is required"
    }
  ]
}
```

**Not Found (404)**:
```json
{
  "error": "NotFound",
  "message": "Product with id 'prod_550e8400-e29b-41d4-a716-446655440000' not found"
}
```

**Forbidden (403)**:
```json
{
  "error": "Forbidden",
  "message": "You do not have permission to access this order"
}
```

**Conflict (409)**:
```json
{
  "error": "ConflictError",
  "message": "Campaign with code 'SUMMER2025' already exists"
}
```

**Applies to**: All API endpoints

---

### 5.8 Query Parameters Pattern

**Common Query Parameters**:

| Parameter | Type | Default | Purpose | Endpoints |
|-----------|------|---------|---------|-----------|
| `includeInactive` | boolean | `false` | Include soft-deleted records | All list endpoints |
| `pageSize` | integer | `50` | Number of items per page (max 100) | All list endpoints |
| `startAt` | string | - | Pagination token | All list endpoints |
| `status` | string | - | Filter by status | `/v1.0/tenants/{id}/orders` |
| `validOnly` | boolean | `false` | Only valid campaigns (date range) | `/v1.0/campaigns` |
| `productId` | string | - | Filter campaigns by product | `/v1.0/campaigns` |

**Example Requests**:

```
GET /v1.0/products?includeInactive=true&pageSize=20
GET /v1.0/campaigns?validOnly=true&productId=prod_550e8400
GET /v1.0/tenants/{tenantId}/orders?status=PAID&pageSize=50
```

---

### 5.9 Versioning Pattern

**API Version**: `/v1.0/` prefix in all endpoints

**From HLD Section 5.1**:
> Note: API version (`/v1.0`) is included in each endpoint path, not the base URL.

**Pattern**:
- Base URL: `https://api.kimmyai.io` (no version)
- Endpoint: `/v1.0/products` (version in path)
- Full URL: `https://api.kimmyai.io/v1.0/products`

**Future Versions**:
- `/v2.0/products` for breaking changes
- `/v1.1/products` for backwards-compatible additions (optional)

**Applies to**: All API endpoints

---

### 5.10 Anonymous Access Pattern

**Public Endpoints** (no authentication):
- `GET /v1.0/products` - List products
- `GET /v1.0/products/{productId}` - Get product details
- `GET /v1.0/campaigns` - List campaigns
- `GET /v1.0/campaigns/{code}` - Get campaign details

**Authenticated Endpoints**:
- `POST /v1.0/products` - Create product (admin only)
- `PUT /v1.0/products/{productId}` - Update/delete product (admin only)
- `POST /v1.0/tenants/{tenantId}/orders` - Create order (tenant or anonymous)
- `GET /v1.0/tenants/{tenantId}/orders` - List tenant orders (tenant only)
- `GET /v1.0/orders/{orderId}` - Get order details (tenant only)

**Anonymous Shopping Flow**:
1. Browse products (no auth)
2. View campaigns (no auth)
3. Checkout: Enter email → Tenant created (status=UNVALIDATED)
4. Create order: Uses tenant ID (no full auth required, OTP verification)
5. Payment: PayFast integration (no auth)
6. Post-purchase: User can register later with same email (links to tenant)

**From HLD Section 7**:
> Anonymous Shopping: Purchase without registration barrier

---

## Summary

This analysis extracted the following from the Customer Portal Public HLD v1.1:

1. **Entity Summary**: 7 entities (Tenant, Product, Campaign, Order, OrderItem, Payment, NewsletterSub) with detailed attributes, PK/SK patterns, status values, and business rules.

2. **Table Relationships**: Hierarchical PK patterns (TENANT → ORDER → PAYMENT), 9 GSIs, entity hierarchy diagram, and access patterns.

3. **S3 Requirements**: 5 bucket types (templates, receipts, static assets, lambda artifacts, logs), email/receipt templates, file paths, and bucket policies.

4. **Architectural Constraints**: Soft delete pattern (active boolean), on-demand capacity mode, PITR enabled, cross-region replication (PROD only), tagging requirements, encryption, Activatable Entity Pattern, environment parameterization, and read-only PROD mode.

5. **API Patterns**: Hierarchical HATEOAS URLs, entity ownership context, pagination (pageSize/startAt/moreAvailable), no DELETE operations, status updates via PUT, error response format, query parameters, versioning (/v1.0), and anonymous access pattern.

All information is traceable to specific sections of the HLD document.

---

**End of Analysis**
