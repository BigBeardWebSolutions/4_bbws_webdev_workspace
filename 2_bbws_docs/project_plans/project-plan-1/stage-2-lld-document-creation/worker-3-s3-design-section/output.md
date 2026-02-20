# Section 5: S3 Bucket Design

**Worker**: worker-2-3-s3-design-section
**Stage**: Stage 2 - LLD Document Creation
**Date**: 2025-12-25
**Status**: Complete

---

## 5.1 Overview

### 5.1.1 Purpose of S3 Buckets in the Architecture

The BBWS Customer Portal (Public) system utilizes Amazon S3 buckets as a centralized repository for HTML email templates that support the order management, payment processing, and customer notification workflows. S3 provides the following benefits for this architecture:

**Separation of Concerns**: Email templates are decoupled from Lambda function code, enabling template updates without code deployments.

**Version Control**: S3 versioning tracks template changes over time, allowing rollback to previous versions if needed.

**Multi-Environment Support**: Separate buckets for DEV, SIT, and PROD environments ensure template isolation and enable environment-specific testing.

**Scalability**: S3 automatically scales to handle unlimited template retrievals without capacity planning.

**Disaster Recovery**: Cross-region replication for PROD ensures template availability during regional failures.

**Cost Efficiency**: S3 storage costs are minimal compared to embedding templates in Lambda code or databases.

### 5.1.2 Email Template Storage and Retrieval Strategy

The system implements a pull-based template retrieval pattern:

**Template Upload**: HTML templates are uploaded to S3 during infrastructure deployment via Terraform.

**Lambda Retrieval**: Lambda functions retrieve templates from S3 at runtime using the AWS SDK (boto3).

**Variable Substitution**: Lambda functions perform Mustache-style variable substitution (`{{variableName}}`) before sending emails.

**Caching Strategy**: Lambda functions cache templates in memory across invocations to minimize S3 GetObject calls (future enhancement).

**Fallback Pattern**: Lambda functions implement graceful degradation if template retrieval fails (send plain text email or use inline template).

**Template Retrieval Flow**:
```
1. Order Lambda triggered (e.g., POST /v1.0/orders)
2. Lambda retrieves template from S3: bbws-templates-{env}/receipts/payment_received.html
3. Lambda substitutes variables: {{tenantEmail}}, {{orderId}}, {{amount}}, etc.
4. Lambda sends email via SES with rendered HTML
5. Lambda logs template retrieval and email send status
```

### 5.1.3 HTML Template Design Philosophy

All HTML email templates follow a consistent design philosophy:

**Mobile-First Responsive Design**: Templates use table-based layouts for maximum email client compatibility (Outlook, Gmail, Apple Mail).

**Brand Consistency**: All templates incorporate BBWS/KimmyAI branding (logo, color scheme, typography).

**Accessibility**: Templates include alt text for images, semantic HTML, and plain text alternatives for screen readers.

**Compliance**: Marketing templates include unsubscribe links ({{unsubscribeUrl}}) to comply with CAN-SPAM and POPIA regulations.

**Variable Format**: Mustache-style double-brace syntax (`{{variableName}}`) enables simple string replacement.

**Defensive Design**: Templates gracefully handle missing variables by displaying empty strings (no template errors).

**Testing**: All templates are tested in Gmail, Outlook 2016+, Apple Mail, and mobile email clients before deployment.

**Internationalization Ready**: Template structure supports future multi-language expansion (e.g., `{{greeting}}` instead of hardcoded "Hello").

---

## 5.2 Bucket: `bbws-templates-{env}`

### 5.2.1 Bucket Configuration

**Bucket Naming Convention**:
```
DEV:  bbws-templates-dev
SIT:  bbws-templates-sit
PROD: bbws-templates-prod
```

**Primary Region**: `af-south-1` (Cape Town, South Africa)

**Disaster Recovery Region** (PROD only): `eu-west-1` (Ireland)

**Versioning**:
- **Status**: Enabled (all environments)
- **Rationale**: Track template changes, enable rollback to previous versions
- **Retention**: Keep all versions indefinitely (templates are small, storage cost is negligible)

**Encryption**:
- **Type**: Server-Side Encryption with Amazon S3-Managed Keys (SSE-S3)
- **Algorithm**: AES-256
- **Rationale**: Protect templates at rest, no additional KMS cost
- **Key Rotation**: Automatic by AWS

**Public Access**:
- **Status**: BLOCKED (all environments)
- **Configuration**:
  - Block public ACLs: `true`
  - Ignore public ACLs: `true`
  - Block public policy: `true`
  - Restrict public buckets: `true`
- **Rationale**: Templates contain business logic and branding, must not be publicly accessible
- **Access Method**: Lambda execution roles have GetObject permission via IAM policies

**Access Logging**:
- **DEV**: Disabled (cost optimization)
- **SIT**: Enabled (log to `bbws-logs-sit/s3-access-logs/templates/`)
- **PROD**: Enabled (log to `bbws-logs-prod/s3-access-logs/templates/`)
- **Retention**: 90 days (DEV: N/A, SIT: 30 days, PROD: 90 days)
- **Rationale**: Audit template access for security and compliance

**Object Lock**:
- **Status**: Not enabled
- **Rationale**: No regulatory requirement for immutable templates

**Lifecycle Policy**:
- **Current Versions**: Retain indefinitely
- **Non-Current Versions**: Retain for 90 days, then delete
- **Rationale**: Balance between version history and storage costs

**Cross-Region Replication** (PROD only):
- **Source Bucket**: `bbws-templates-prod` (af-south-1)
- **Destination Bucket**: `bbws-templates-prod-dr-eu-west-1` (eu-west-1)
- **Replication Rule**: Replicate all objects and delete markers
- **Storage Class**: STANDARD (both regions)
- **Rationale**: Disaster recovery requirement, ensure template availability during regional failure

**Tagging** (all environments):
```json
{
  "Environment": "dev | sit | prod",
  "Project": "BBWS WP Containers",
  "Owner": "Tebogo",
  "CostCenter": "AWS",
  "ManagedBy": "Terraform",
  "Component": "s3",
  "Application": "CustomerPortalPublic",
  "LLD": "2.1.8"
}
```

**Bucket Policy** (example for DEV):
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyPublicAccess",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::bbws-templates-dev",
        "arn:aws:s3:::bbws-templates-dev/*"
      ],
      "Condition": {
        "StringNotEquals": {
          "aws:PrincipalAccount": "536580886816"
        }
      }
    },
    {
      "Sid": "AllowLambdaReadTemplates",
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "arn:aws:iam::536580886816:role/2-1-bbws-order-lambda-role-dev",
          "arn:aws:iam::536580886816:role/2-1-bbws-payment-lambda-role-dev",
          "arn:aws:iam::536580886816:role/2-1-bbws-tenant-lambda-role-dev"
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

**CORS Configuration**:
- **Status**: Not enabled
- **Rationale**: Templates are accessed server-side by Lambda, not client-side by browsers

---

### 5.2.2 Object Key Structure

The S3 bucket uses a hierarchical folder structure to organize templates by category:

```
bbws-templates-{env}/
├── receipts/
│   ├── payment_received.html
│   ├── payment_failed.html
│   └── refund_processed.html
├── notifications/
│   ├── order_confirmation.html
│   ├── order_shipped.html
│   ├── order_delivered.html
│   └── order_cancelled.html
├── invoices/
│   ├── invoice_created.html
│   └── invoice_updated.html
└── marketing/
    ├── campaign_notification.html
    ├── welcome_email.html
    └── newsletter_template.html
```

**Folder Categories**:

1. **`receipts/`**: Templates for financial transaction confirmations
2. **`notifications/`**: Templates for order status updates and system events
3. **`invoices/`**: Templates for billing and invoicing
4. **`marketing/`**: Templates for promotional campaigns and customer engagement

**Object Key Naming Conventions**:

- **Format**: `{category}/{action}_{noun}.html`
- **Examples**:
  - `receipts/payment_received.html` (action: received, noun: payment)
  - `notifications/order_confirmation.html` (action: confirmation, noun: order)
  - `marketing/campaign_notification.html` (action: notification, noun: campaign)

- **Rules**:
  - Lowercase with underscores for multi-word names
  - Descriptive filenames that indicate purpose
  - `.html` extension for all templates
  - No version numbers in filenames (use S3 versioning instead)

**Access Pattern**:

Lambda functions construct object keys using environment variables:
```python
import os

ENVIRONMENT = os.environ.get('ENVIRONMENT', 'dev')
TEMPLATE_BUCKET = f"bbws-templates-{ENVIRONMENT}"

def get_template_key(category: str, template_name: str) -> str:
    """Construct S3 object key for template."""
    return f"{category}/{template_name}.html"

# Example usage:
template_key = get_template_key("receipts", "payment_received")
# Returns: "receipts/payment_received.html"
```

---

### 5.2.3 HTML Email Templates

This section documents all 12 HTML email templates, including purpose, variables, and triggers.

#### 1. receipts/payment_received.html

**Purpose**: Sent to customer when payment is successfully processed for an order.

**Trigger**: Order Lambda POST `/v1.0/orders` (when payment status changes to `PAID`)

**Sender**: `noreply@kimmyai.io`

**Subject Line**: `Payment Received - Order {{orderId}}`

**Variables**:

| Variable | Type | Example | Description |
|----------|------|---------|-------------|
| `{{tenantEmail}}` | String | customer@example.com | Customer email address |
| `{{tenantName}}` | String | John Doe | Customer name (optional) |
| `{{orderId}}` | String | order_aa0e8400-e29b-41d4-a716-446655440005 | Order UUID |
| `{{amount}}` | Number | 299.99 | Payment amount (decimal) |
| `{{currency}}` | String | ZAR | Currency code (ISO 4217) |
| `{{paymentDate}}` | String | 2025-12-19T10:30:00Z | Payment timestamp (ISO 8601) |
| `{{paymentMethod}}` | String | PayFast | Payment method used |
| `{{payfastPaymentId}}` | String | 12345678 | PayFast transaction ID |
| `{{receiptUrl}}` | String | https://portal.kimmyai.io/receipts/aa0e8400 | Link to detailed receipt |
| `{{orderDetailsUrl}}` | String | https://portal.kimmyai.io/orders/aa0e8400 | Link to order details page |

**Template Structure**:
```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Payment Received</title>
</head>
<body style="font-family: Arial, sans-serif; background-color: #f4f4f4; margin: 0; padding: 20px;">
  <table width="100%" cellpadding="0" cellspacing="0" border="0" bgcolor="#f4f4f4">
    <tr>
      <td align="center">
        <table width="600" cellpadding="0" cellspacing="0" border="0" bgcolor="#ffffff" style="border-radius: 8px; margin: 20px auto;">
          <!-- Header -->
          <tr>
            <td style="background-color: #0066cc; padding: 20px; text-align: center; border-radius: 8px 8px 0 0;">
              <h1 style="color: #ffffff; margin: 0;">Payment Received</h1>
            </td>
          </tr>
          <!-- Body -->
          <tr>
            <td style="padding: 30px;">
              <p>Dear {{tenantName}},</p>
              <p>Thank you! We have successfully received your payment.</p>
              <table width="100%" cellpadding="10" cellspacing="0" border="1" bordercolor="#dddddd" style="border-collapse: collapse; margin: 20px 0;">
                <tr>
                  <td><strong>Order ID:</strong></td>
                  <td>{{orderId}}</td>
                </tr>
                <tr>
                  <td><strong>Amount:</strong></td>
                  <td>{{currency}} {{amount}}</td>
                </tr>
                <tr>
                  <td><strong>Payment Date:</strong></td>
                  <td>{{paymentDate}}</td>
                </tr>
                <tr>
                  <td><strong>Payment Method:</strong></td>
                  <td>{{paymentMethod}}</td>
                </tr>
                <tr>
                  <td><strong>Transaction ID:</strong></td>
                  <td>{{payfastPaymentId}}</td>
                </tr>
              </table>
              <p><a href="{{receiptUrl}}" style="color: #0066cc;">View Receipt</a> | <a href="{{orderDetailsUrl}}" style="color: #0066cc;">View Order Details</a></p>
            </td>
          </tr>
          <!-- Footer -->
          <tr>
            <td style="background-color: #f4f4f4; padding: 20px; text-align: center; font-size: 12px; color: #666666;">
              <p>&copy; 2025 KimmyAI. All rights reserved.</p>
              <p>Questions? Contact us at support@kimmyai.io</p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
```

**Plain Text Alternative**:
```
Payment Received

Dear {{tenantName}},

Thank you! We have successfully received your payment.

Order ID: {{orderId}}
Amount: {{currency}} {{amount}}
Payment Date: {{paymentDate}}
Payment Method: {{paymentMethod}}
Transaction ID: {{payfastPaymentId}}

View Receipt: {{receiptUrl}}
View Order Details: {{orderDetailsUrl}}

---
© 2025 KimmyAI. All rights reserved.
Questions? Contact us at support@kimmyai.io
```

---

#### 2. receipts/payment_failed.html

**Purpose**: Sent to customer when payment processing fails.

**Trigger**: Order Lambda POST `/v1.0/orders` (when payment status changes to `FAILED`)

**Sender**: `noreply@kimmyai.io`

**Subject Line**: `Payment Failed - Order {{orderId}}`

**Variables**:

| Variable | Type | Example | Description |
|----------|------|---------|-------------|
| `{{tenantEmail}}` | String | customer@example.com | Customer email address |
| `{{tenantName}}` | String | John Doe | Customer name (optional) |
| `{{orderId}}` | String | order_aa0e8400-e29b-41d4-a716-446655440005 | Order UUID |
| `{{amount}}` | Number | 299.99 | Payment amount attempted |
| `{{currency}}` | String | ZAR | Currency code |
| `{{failureReason}}` | String | Insufficient funds | Reason for payment failure |
| `{{failureDate}}` | String | 2025-12-19T10:30:00Z | Failure timestamp |
| `{{retryPaymentUrl}}` | String | https://portal.kimmyai.io/orders/aa0e8400/pay | Link to retry payment |
| `{{supportUrl}}` | String | https://portal.kimmyai.io/support | Link to support page |

**Email Content Focus**:
- Empathetic tone acknowledging the inconvenience
- Clear explanation of failure reason
- Prominent call-to-action to retry payment
- Support contact information
- Alternative payment methods (if available)

---

#### 3. receipts/refund_processed.html

**Purpose**: Sent to customer when a refund has been successfully processed.

**Trigger**: Payment Lambda refund operation (manual or automated refund flow)

**Sender**: `noreply@kimmyai.io`

**Subject Line**: `Refund Processed - Order {{orderId}}`

**Variables**:

| Variable | Type | Example | Description |
|----------|------|---------|-------------|
| `{{tenantEmail}}` | String | customer@example.com | Customer email address |
| `{{tenantName}}` | String | John Doe | Customer name |
| `{{orderId}}` | String | order_aa0e8400-e29b-41d4-a716-446655440005 | Order UUID |
| `{{refundAmount}}` | Number | 299.99 | Refund amount |
| `{{currency}}` | String | ZAR | Currency code |
| `{{refundDate}}` | String | 2025-12-20T14:00:00Z | Refund processing date |
| `{{refundReason}}` | String | Order cancelled by customer | Reason for refund |
| `{{originalPaymentDate}}` | String | 2025-12-19T10:30:00Z | Original payment date |
| `{{refundMethod}}` | String | Original payment method | Refund destination |
| `{{processingTime}}` | String | 5-10 business days | Estimated time for refund to appear |

**Email Content Focus**:
- Confirmation of refund approval
- Refund amount and destination
- Timeline for funds to appear in customer's account
- Reference to original order and payment
- Support contact for questions

---

#### 4. notifications/order_confirmation.html

**Purpose**: Sent immediately after order creation to confirm order details.

**Trigger**: Order Lambda POST `/v1.0/orders` (immediately after successful order creation)

**Sender**: `orders@kimmyai.io`

**Subject Line**: `Order Confirmation - {{productName}}`

**Variables**:

| Variable | Type | Example | Description |
|----------|------|---------|-------------|
| `{{tenantEmail}}` | String | customer@example.com | Customer email address |
| `{{tenantName}}` | String | John Doe | Customer name |
| `{{orderId}}` | String | order_aa0e8400-e29b-41d4-a716-446655440005 | Order UUID |
| `{{productName}}` | String | WordPress Professional Plan | Product purchased |
| `{{productDescription}}` | String | Professional WordPress hosting... | Product description |
| `{{quantity}}` | Number | 1 | Quantity ordered |
| `{{unitPrice}}` | Number | 299.99 | Unit price |
| `{{subtotal}}` | Number | 299.99 | Subtotal before tax |
| `{{tax}}` | Number | 45.00 | Tax amount (15% VAT) |
| `{{totalAmount}}` | Number | 344.99 | Total amount |
| `{{currency}}` | String | ZAR | Currency code |
| `{{orderDate}}` | String | 2025-12-19T10:30:00Z | Order creation timestamp |
| `{{paymentStatus}}` | String | PENDING_PAYMENT | Current payment status |
| `{{billingAddress}}` | Object | {street, city, province, postalCode, country} | Billing address |
| `{{campaignCode}}` | String | SUMMER2025 | Campaign code (if applied) |
| `{{discount}}` | Number | 60.00 | Discount amount (if applicable) |
| `{{orderDetailsUrl}}` | String | https://portal.kimmyai.io/orders/aa0e8400 | Link to order details |

**Email Content Focus**:
- Thank you message for choosing the service
- Complete order summary with line items
- Billing address confirmation
- Next steps (payment instructions if pending)
- Links to order tracking and support

---

#### 5. notifications/order_shipped.html

**Purpose**: Sent when order status changes to SHIPPED (future feature for physical goods or provisioning started).

**Trigger**: Order Lambda PUT `/v1.0/orders/{id}` (status update to `SHIPPED`)

**Sender**: `orders@kimmyai.io`

**Subject Line**: `Your Order Has Shipped - {{orderId}}`

**Variables**:

| Variable | Type | Example | Description |
|----------|------|---------|-------------|
| `{{tenantEmail}}` | String | customer@example.com | Customer email address |
| `{{tenantName}}` | String | John Doe | Customer name |
| `{{orderId}}` | String | order_aa0e8400-e29b-41d4-a716-446655440005 | Order UUID |
| `{{productName}}` | String | WordPress Professional Plan | Product shipped |
| `{{trackingNumber}}` | String | N/A (digital product) | Tracking number (if applicable) |
| `{{shippedDate}}` | String | 2025-12-19T12:00:00Z | Shipment date |
| `{{estimatedDelivery}}` | String | 2025-12-21 | Estimated delivery date |
| `{{trackingUrl}}` | String | N/A | Tracking URL (if applicable) |
| `{{provisioningStatus}}` | String | In Progress | Provisioning status for digital products |

**Note**: For digital products (WordPress hosting), this template may be repurposed to indicate "Provisioning Started" rather than physical shipment.

---

#### 6. notifications/order_delivered.html

**Purpose**: Sent when order status changes to DELIVERED (WordPress site provisioned and ready).

**Trigger**: Order Lambda PUT `/v1.0/orders/{id}` (status update to `DELIVERED` or `COMPLETED`)

**Sender**: `orders@kimmyai.io`

**Subject Line**: `Your WordPress Site is Ready! - Order {{orderId}}`

**Variables**:

| Variable | Type | Example | Description |
|----------|------|---------|-------------|
| `{{tenantEmail}}` | String | customer@example.com | Customer email address |
| `{{tenantName}}` | String | John Doe | Customer name |
| `{{orderId}}` | String | order_aa0e8400-e29b-41d4-a716-446655440005 | Order UUID |
| `{{productName}}` | String | WordPress Professional Plan | Product delivered |
| `{{deliveredDate}}` | String | 2025-12-19T14:00:00Z | Delivery/provisioning completion date |
| `{{siteUrl}}` | String | https://johndoe.kimmyai.io | WordPress site URL |
| `{{wpAdminUrl}}` | String | https://johndoe.kimmyai.io/wp-admin | WordPress admin URL |
| `{{wpUsername}}` | String | johndoe | WordPress admin username |
| `{{wpPasswordResetUrl}}` | String | https://johndoe.kimmyai.io/wp-login.php?action=lostpassword | Password reset URL |
| `{{dashboardUrl}}` | String | https://portal.kimmyai.io/dashboard | Customer portal dashboard |
| `{{supportUrl}}` | String | https://portal.kimmyai.io/support | Support URL |

**Email Content Focus**:
- Congratulations on site readiness
- Access credentials and login instructions
- Getting started guide
- Links to documentation and tutorials
- Support contact information

---

#### 7. notifications/order_cancelled.html

**Purpose**: Sent when an order is cancelled by customer or system.

**Trigger**: Order Lambda PUT `/v1.0/orders/{id}` (status update to `CANCELLED`)

**Sender**: `orders@kimmyai.io`

**Subject Line**: `Order Cancelled - {{orderId}}`

**Variables**:

| Variable | Type | Example | Description |
|----------|------|---------|-------------|
| `{{tenantEmail}}` | String | customer@example.com | Customer email address |
| `{{tenantName}}` | String | John Doe | Customer name |
| `{{orderId}}` | String | order_aa0e8400-e29b-41d4-a716-446655440005 | Order UUID |
| `{{productName}}` | String | WordPress Professional Plan | Product cancelled |
| `{{cancellationDate}}` | String | 2025-12-19T15:00:00Z | Cancellation timestamp |
| `{{cancellationReason}}` | String | Customer requested cancellation | Reason for cancellation |
| `{{refundInfo}}` | String | Refund will be processed within 5-10 business days | Refund information |
| `{{refundAmount}}` | Number | 299.99 | Refund amount (if applicable) |
| `{{orderDate}}` | String | 2025-12-19T10:30:00Z | Original order date |
| `{{supportUrl}}` | String | https://portal.kimmyai.io/support | Support URL |

**Email Content Focus**:
- Confirmation of cancellation
- Cancellation reason
- Refund status and timeline (if applicable)
- Invitation to reorder or explore alternatives
- Support contact for questions

---

#### 8. invoices/invoice_created.html

**Purpose**: Sent when a billing invoice is generated for the order.

**Trigger**: Invoice generation process (post-order or recurring billing)

**Sender**: `billing@kimmyai.io`

**Subject Line**: `Invoice {{invoiceId}} for Order {{orderId}}`

**Variables**:

| Variable | Type | Example | Description |
|----------|------|---------|-------------|
| `{{tenantEmail}}` | String | customer@example.com | Customer email address |
| `{{tenantName}}` | String | John Doe | Customer name |
| `{{invoiceId}}` | String | INV-2025-0001234 | Invoice identifier |
| `{{orderId}}` | String | order_aa0e8400-e29b-41d4-a716-446655440005 | Associated order UUID |
| `{{invoiceDate}}` | String | 2025-12-19 | Invoice issue date |
| `{{dueDate}}` | String | 2025-12-26 | Payment due date |
| `{{amount}}` | Number | 344.99 | Invoice amount |
| `{{currency}}` | String | ZAR | Currency code |
| `{{invoiceUrl}}` | String | https://portal.kimmyai.io/invoices/INV-2025-0001234 | Link to view/download invoice |
| `{{pdfUrl}}` | String | https://s3.af-south-1.amazonaws.com/bbws-invoices-prod/... | Direct link to PDF invoice |
| `{{lineItems}}` | Array | [{description, quantity, unitPrice, total}] | Invoice line items |
| `{{subtotal}}` | Number | 299.99 | Subtotal before tax |
| `{{tax}}` | Number | 45.00 | Tax amount |
| `{{billingAddress}}` | Object | {street, city, province, postalCode, country} | Billing address |

**Email Content Focus**:
- Professional invoice presentation
- Clear payment instructions
- Due date emphasis
- Itemized billing details
- Links to view or download invoice PDF
- Payment methods accepted

---

#### 9. invoices/invoice_updated.html

**Purpose**: Sent when an existing invoice is updated (amount change, due date extension, etc.).

**Trigger**: Invoice Lambda PUT operation (manual invoice updates)

**Sender**: `billing@kimmyai.io`

**Subject Line**: `Updated Invoice {{invoiceId}} for Order {{orderId}}`

**Variables**:

| Variable | Type | Example | Description |
|----------|------|---------|-------------|
| `{{tenantEmail}}` | String | customer@example.com | Customer email address |
| `{{tenantName}}` | String | John Doe | Customer name |
| `{{invoiceId}}` | String | INV-2025-0001234 | Invoice identifier |
| `{{orderId}}` | String | order_aa0e8400-e29b-41d4-a716-446655440005 | Associated order UUID |
| `{{updateReason}}` | String | Discount applied | Reason for invoice update |
| `{{originalAmount}}` | Number | 344.99 | Original invoice amount |
| `{{newAmount}}` | Number | 299.99 | Updated invoice amount |
| `{{currency}}` | String | ZAR | Currency code |
| `{{newDueDate}}` | String | 2025-12-30 | Updated due date (if changed) |
| `{{invoiceUrl}}` | String | https://portal.kimmyai.io/invoices/INV-2025-0001234 | Link to view updated invoice |
| `{{updateDate}}` | String | 2025-12-20T10:00:00Z | Invoice update timestamp |

**Email Content Focus**:
- Clear notification of invoice changes
- Reason for update
- Comparison of old vs. new amounts
- New payment deadline (if applicable)
- Assurance that previous invoice is superseded

---

#### 10. marketing/campaign_notification.html

**Purpose**: Sent when a new marketing campaign is available for a product.

**Trigger**: Campaign Lambda (manual trigger or scheduled send for active campaigns)

**Sender**: `marketing@kimmyai.io`

**Subject Line**: `{{campaignCode}}: {{discountPercentage}}% Off {{productName}}!`

**Variables**:

| Variable | Type | Example | Description |
|----------|------|---------|-------------|
| `{{tenantEmail}}` | String | customer@example.com | Customer email address |
| `{{tenantName}}` | String | John | Customer first name (personalization) |
| `{{campaignCode}}` | String | SUMMER2025 | Campaign code identifier |
| `{{campaignDescription}}` | String | Summer 2025 Special Offer | Campaign description |
| `{{productName}}` | String | WordPress Professional Plan | Product on promotion |
| `{{productDescription}}` | String | Professional WordPress hosting... | Product description |
| `{{discountPercentage}}` | Number | 20 | Discount percentage (0-100) |
| `{{originalPrice}}` | Number | 299.99 | Original product price |
| `{{discountedPrice}}` | Number | 239.99 | Discounted price (calculated) |
| `{{currency}}` | String | ZAR | Currency code |
| `{{fromDate}}` | String | 2025-06-01 | Campaign start date |
| `{{toDate}}` | String | 2025-08-31 | Campaign end date |
| `{{termsLink}}` | String | https://kimmyai.io/terms/campaigns/summer2025 | Terms and conditions URL |
| `{{ctaUrl}}` | String | https://portal.kimmyai.io/checkout?campaign=SUMMER2025 | Call-to-action URL |
| `{{unsubscribeUrl}}` | String | https://portal.kimmyai.io/unsubscribe?email=customer@example.com | Unsubscribe link (required) |

**Email Content Focus**:
- Eye-catching promotional design
- Clear value proposition (discount amount)
- Urgency (limited time offer, expiry date)
- Product benefits and features
- Strong call-to-action button
- Terms and conditions link
- Unsubscribe link (CAN-SPAM compliance)

**Compliance Requirements**:
- Must include unsubscribe link
- Must honor unsubscribe requests within 10 business days
- Must include physical mailing address
- Must clearly identify as advertisement

---

#### 11. marketing/welcome_email.html

**Purpose**: Sent when a tenant completes registration (status changes to REGISTERED).

**Trigger**: Tenant Lambda (status update from `VALIDATED` to `REGISTERED`)

**Sender**: `welcome@kimmyai.io`

**Subject Line**: `Welcome to KimmyAI, {{tenantName}}!`

**Variables**:

| Variable | Type | Example | Description |
|----------|------|---------|-------------|
| `{{tenantEmail}}` | String | customer@example.com | Customer email address |
| `{{tenantName}}` | String | John Doe | Customer name |
| `{{tenantId}}` | String | tenant_bb0e8400-e29b-41d4-a716-446655440006 | Tenant UUID |
| `{{registrationDate}}` | String | 2025-12-19 | Registration completion date |
| `{{dashboardUrl}}` | String | https://portal.kimmyai.io/dashboard | Customer portal dashboard |
| `{{gettingStartedUrl}}` | String | https://portal.kimmyai.io/getting-started | Getting started guide URL |
| `{{supportUrl}}` | String | https://portal.kimmyai.io/support | Support page URL |
| `{{communityUrl}}` | String | https://community.kimmyai.io | Community forum URL |
| `{{nextSteps}}` | Array | [{step, description, link}] | Recommended next steps |

**Email Content Focus**:
- Warm welcome message
- Overview of services and benefits
- Getting started guide
- Links to key resources (dashboard, documentation, support)
- Community engagement invitation
- Support contact information

---

#### 12. marketing/newsletter_template.html

**Purpose**: Monthly newsletter template for product updates, tips, and community highlights.

**Trigger**: Newsletter service (scheduled monthly send, typically first Monday of each month)

**Sender**: `newsletter@kimmyai.io`

**Subject Line**: `KimmyAI Newsletter - {{month}} 2025`

**Variables**:

| Variable | Type | Example | Description |
|----------|------|---------|-------------|
| `{{tenantEmail}}` | String | customer@example.com | Subscriber email address |
| `{{tenantName}}` | String | John | Subscriber first name |
| `{{month}}` | String | December | Newsletter month |
| `{{year}}` | String | 2025 | Newsletter year |
| `{{featuredProducts}}` | Array | [{name, description, price, imageUrl, ctaUrl}] | Featured products for the month |
| `{{activeCampaigns}}` | Array | [{code, description, discount, expiryDate, ctaUrl}] | Active promotional campaigns |
| `{{blogPosts}}` | Array | [{title, excerpt, imageUrl, readMoreUrl}] | Recent blog posts |
| `{{communityHighlights}}` | Array | [{title, description, url}] | Community highlights |
| `{{tipsAndTricks}}` | Array | [{title, description, link}] | Tips and tricks section |
| `{{unsubscribeUrl}}` | String | https://portal.kimmyai.io/unsubscribe?email=customer@example.com | Unsubscribe link (required) |

**Email Content Focus**:
- Engaging monthly digest format
- Product updates and new features
- Educational content (tips, tutorials)
- Community highlights and success stories
- Active promotions and special offers
- Blog post summaries with read-more links
- Unsubscribe link (CAN-SPAM compliance)

**Newsletter Sections**:
1. **Hero Section**: Featured announcement or promotion
2. **Product Spotlight**: New or updated products
3. **Active Campaigns**: Current promotions
4. **Blog Highlights**: Recent articles
5. **Tips & Tricks**: Educational content
6. **Community Corner**: User highlights
7. **Footer**: Contact info, social links, unsubscribe

---

### 5.2.4 Template Design Standards

All HTML email templates adhere to the following design and technical standards:

#### 5.2.4.1 Responsive Design

**Mobile-First Approach**:
- Templates use table-based layouts for maximum email client compatibility
- Fluid tables with `max-width` constraints adapt to screen sizes
- Font sizes scale appropriately (minimum 14px for body text on mobile)
- Buttons are touch-friendly (minimum 44x44px tap targets)
- Single-column layout on mobile devices

**Media Queries**:
```html
<style>
  @media only screen and (max-width: 600px) {
    .responsive-table {
      width: 100% !important;
    }
    .mobile-padding {
      padding: 10px !important;
    }
    .mobile-font {
      font-size: 16px !important;
    }
  }
</style>
```

**Tested Email Clients**:
- Gmail (web, Android, iOS)
- Outlook 2016, 2019, 2021 (Windows)
- Outlook for Mac
- Apple Mail (macOS, iOS)
- Yahoo Mail
- ProtonMail

#### 5.2.4.2 Plain Text Alternative

Every HTML template has a corresponding plain text version for:
- Email clients that disable HTML
- Accessibility (screen readers)
- Spam filter compliance

**Plain Text Format**:
```
Subject: [Clear subject line]

[Greeting]

[Body content with clear hierarchy using line breaks and dashes]

[Call-to-action URLs on separate lines]

---
[Footer with contact information and legal text]
```

**Delivery Strategy**:
- Send as multipart/alternative MIME type
- HTML version as primary, plain text as fallback

#### 5.2.4.3 Unsubscribe Link (Marketing Emails Only)

**Requirement**: All marketing emails must include unsubscribe link per CAN-SPAM Act and POPIA.

**Placement**: Footer section, clearly visible

**Link Format**:
```html
<p style="font-size: 12px; color: #666666; text-align: center;">
  Don't want to receive these emails?
  <a href="{{unsubscribeUrl}}" style="color: #0066cc;">Unsubscribe</a>
</p>
```

**Unsubscribe URL Pattern**:
```
https://portal.kimmyai.io/unsubscribe?email={{tenantEmail}}&token={{unsubscribeToken}}
```

**Processing**:
- Unsubscribe requests processed immediately
- Confirmation email sent within 24 hours
- Email address removed from marketing lists within 10 business days
- Transaction emails (receipts, order confirmations) are not affected

**Applicable Templates**:
- `marketing/campaign_notification.html`
- `marketing/newsletter_template.html`

**Not Required For**:
- Transaction emails (receipts, order confirmations, invoices)
- Account notification emails (password resets, security alerts)

#### 5.2.4.4 Brand Consistency

**Logo**:
- KimmyAI logo in header (PNG format, optimized for email)
- Alt text: "KimmyAI - WordPress Hosting"
- Dimensions: 200x50px (2x resolution: 400x100px)
- Hosted on: `https://static.kimmyai.io/logos/kimmyai-logo-email.png`

**Color Scheme**:
```css
/* Primary Colors */
--primary-blue: #0066cc;
--primary-dark: #004080;
--primary-light: #3385d6;

/* Secondary Colors */
--success-green: #28a745;
--warning-orange: #ffc107;
--error-red: #dc3545;

/* Neutral Colors */
--text-dark: #333333;
--text-light: #666666;
--background-white: #ffffff;
--background-gray: #f4f4f4;
--border-gray: #dddddd;
```

**Typography**:
- **Headings**: Arial, Helvetica, sans-serif
- **Body Text**: Arial, Helvetica, sans-serif
- **Font Sizes**:
  - H1: 24px (bold, color: primary-blue or white)
  - H2: 20px (bold, color: text-dark)
  - H3: 18px (bold, color: text-dark)
  - Body: 16px (color: text-dark)
  - Footer: 12px (color: text-light)

**Button Styles**:
```html
<a href="{{ctaUrl}}" style="display: inline-block; background-color: #0066cc; color: #ffffff; padding: 12px 24px; text-decoration: none; border-radius: 4px; font-weight: bold;">
  Call to Action
</a>
```

#### 5.2.4.5 Variable Format

**Mustache-Style Variables**:
- Format: `{{variableName}}`
- Case: camelCase (e.g., `{{tenantEmail}}`, `{{orderId}}`)
- No spaces inside braces: `{{variableName}}` not `{{ variableName }}`

**Variable Substitution Logic** (Lambda):
```python
import re

def render_template(template_html: str, variables: dict) -> str:
    """
    Replace Mustache-style variables in template with actual values.

    Args:
        template_html: HTML template string with {{variables}}
        variables: Dictionary of variable names to values

    Returns:
        Rendered HTML string with variables substituted
    """
    rendered = template_html
    for key, value in variables.items():
        pattern = r'\{\{' + key + r'\}\}'
        rendered = re.sub(pattern, str(value), rendered)

    # Remove any unreplaced variables (defensive)
    rendered = re.sub(r'\{\{[^}]+\}\}', '', rendered)

    return rendered
```

**Handling Missing Variables**:
- Replace with empty string (default behavior)
- No template errors or broken rendering
- Log warning for missing required variables

**Conditional Blocks** (future enhancement):
```html
<!-- Conditional rendering (not yet implemented) -->
{{#if campaignCode}}
  <p>Campaign: {{campaignCode}}</p>
{{/if}}

{{#each lineItems}}
  <tr>
    <td>{{description}}</td>
    <td>{{quantity}}</td>
    <td>{{unitPrice}}</td>
  </tr>
{{/each}}
```

#### 5.2.4.6 Testing Requirements

**Pre-Deployment Testing**:

1. **HTML Validation**:
   ```bash
   tidy -q -e templates/receipts/payment_received.html
   ```

2. **Variable Validation**:
   ```python
   # Ensure all variables have corresponding test data
   python scripts/validate_template_variables.py --template receipts/payment_received.html
   ```

3. **Rendering Test**:
   ```python
   # Test render with sample data
   python scripts/test_render.py --template receipts/payment_received.html --data test_data.json
   ```

4. **Email Client Testing**:
   - Use Email on Acid or Litmus for cross-client testing
   - Test in Gmail, Outlook, Apple Mail (minimum)
   - Verify mobile responsiveness on iOS and Android

5. **Accessibility Testing**:
   - Screen reader compatibility (NVDA, JAWS, VoiceOver)
   - Alt text for all images
   - Sufficient color contrast (WCAG AA: 4.5:1 for body text)

6. **Link Testing**:
   - All links functional (no 404s)
   - Unsubscribe link works correctly
   - Tracking parameters included (if applicable)

**Test Data**:
```json
{
  "tenantEmail": "test@example.com",
  "tenantName": "Test User",
  "orderId": "order_test-1234",
  "amount": 299.99,
  "currency": "ZAR",
  "paymentDate": "2025-12-19T10:30:00Z",
  "receiptUrl": "https://portal.kimmyai.io/receipts/test-1234"
}
```

---

## 5.3 Repository Structure

### 5.3.1 Repository: `2_1_bbws_s3_schemas`

**Repository URL**: `https://github.com/bigbeard-ventures/2_1_bbws_s3_schemas`

**Purpose**: Centralized repository for S3 bucket configurations and HTML email templates.

**Repository Structure**:

```
2_1_bbws_s3_schemas/
├── templates/
│   ├── receipts/
│   │   ├── payment_received.html
│   │   ├── payment_failed.html
│   │   └── refund_processed.html
│   ├── notifications/
│   │   ├── order_confirmation.html
│   │   ├── order_shipped.html
│   │   ├── order_delivered.html
│   │   └── order_cancelled.html
│   ├── invoices/
│   │   ├── invoice_created.html
│   │   └── invoice_updated.html
│   ├── marketing/
│   │   ├── campaign_notification.html
│   │   ├── welcome_email.html
│   │   └── newsletter_template.html
│   └── README.md
├── plaintext/
│   ├── receipts/
│   │   ├── payment_received.txt
│   │   ├── payment_failed.txt
│   │   └── refund_processed.txt
│   ├── notifications/
│   │   ├── order_confirmation.txt
│   │   ├── order_shipped.txt
│   │   ├── order_delivered.txt
│   │   └── order_cancelled.txt
│   ├── invoices/
│   │   ├── invoice_created.txt
│   │   └── invoice_updated.txt
│   └── marketing/
│       ├── campaign_notification.txt
│       ├── welcome_email.txt
│       └── newsletter_template.txt
├── terraform/
│   ├── modules/
│   │   ├── s3_bucket/
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   └── README.md
│   │   ├── bucket_policy/
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   └── replication/
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       └── outputs.tf
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── backend.tf
│   │   └── dev.tfvars
│   ├── sit/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── backend.tf
│   │   └── sit.tfvars
│   ├── prod/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── backend.tf
│   │   └── prod.tfvars
│   └── README.md
├── .github/
│   └── workflows/
│       ├── validate-templates.yml
│       ├── terraform-plan.yml
│       ├── terraform-apply-dev.yml
│       ├── terraform-apply-sit.yml
│       └── terraform-apply-prod.yml
├── scripts/
│   ├── validate_templates.py
│   ├── validate_template_variables.py
│   ├── test_render.py
│   ├── upload_templates_to_s3.py
│   └── README.md
├── tests/
│   ├── test_templates.py
│   ├── test_terraform.py
│   ├── test_data/
│   │   ├── payment_received_data.json
│   │   ├── order_confirmation_data.json
│   │   └── campaign_notification_data.json
│   └── README.md
├── docs/
│   ├── TEMPLATE_GUIDELINES.md
│   ├── DEPLOYMENT.md
│   └── TROUBLESHOOTING.md
├── .gitignore
├── .pre-commit-config.yaml
├── requirements.txt
└── README.md
```

### 5.3.2 Directory Descriptions

#### `templates/`

**Purpose**: HTML email templates organized by category.

**Subdirectories**:
- `receipts/`: Financial transaction templates (payment confirmations, refunds)
- `notifications/`: Order status and event notification templates
- `invoices/`: Billing and invoice templates
- `marketing/`: Promotional and engagement templates

**File Naming**: `{action}_{noun}.html` (e.g., `payment_received.html`, `order_confirmation.html`)

#### `plaintext/`

**Purpose**: Plain text alternatives for all HTML templates.

**Structure**: Mirrors `templates/` directory structure

**File Naming**: Same as HTML templates, but with `.txt` extension

#### `terraform/`

**Purpose**: Infrastructure as Code for S3 bucket creation and configuration.

**Subdirectories**:
- `modules/`: Reusable Terraform modules (s3_bucket, bucket_policy, replication)
- `dev/`, `sit/`, `prod/`: Environment-specific configurations

**Key Files**:
- `main.tf`: Resource definitions
- `variables.tf`: Input variables
- `outputs.tf`: Output values
- `backend.tf`: Terraform backend configuration (S3 state storage)
- `{env}.tfvars`: Environment-specific variable values

#### `.github/workflows/`

**Purpose**: CI/CD pipeline automation using GitHub Actions.

**Workflows**:
1. `validate-templates.yml`: Validate HTML syntax and variables
2. `terraform-plan.yml`: Generate Terraform plans for all environments
3. `terraform-apply-dev.yml`: Deploy to DEV environment
4. `terraform-apply-sit.yml`: Promote to SIT environment
5. `terraform-apply-prod.yml`: Promote to PROD environment

#### `scripts/`

**Purpose**: Automation scripts for template validation and deployment.

**Scripts**:
- `validate_templates.py`: HTML syntax validation using HTML Tidy
- `validate_template_variables.py`: Check all variables have test data
- `test_render.py`: Render templates with test data
- `upload_templates_to_s3.py`: Manual template upload (for testing)

#### `tests/`

**Purpose**: Automated tests for templates and Terraform configurations.

**Test Files**:
- `test_templates.py`: Unit tests for template rendering
- `test_terraform.py`: Terraform configuration validation tests
- `test_data/`: JSON files with sample data for template testing

#### `docs/`

**Purpose**: Documentation for template development and deployment.

**Documents**:
- `TEMPLATE_GUIDELINES.md`: Template design standards and best practices
- `DEPLOYMENT.md`: Deployment runbook for infrastructure
- `TROUBLESHOOTING.md`: Common issues and solutions

---

## 5.4 Environment Configuration

### 5.4.1 DEV Environment

**Bucket Name**: `bbws-templates-dev`

**AWS Account ID**: `536580886816`

**Region**: `af-south-1` (Cape Town, South Africa)

**Versioning**: Enabled

**Lifecycle Policy**:
- Current versions: Retain indefinitely
- Non-current versions: Delete after 30 days

**Access Logging**: Disabled (cost optimization)

**Replication**: None

**Tags**:
```hcl
tags = {
  Environment  = "dev"
  Project      = "BBWS WP Containers"
  Owner        = "Tebogo"
  CostCenter   = "AWS"
  ManagedBy    = "Terraform"
  Component    = "s3"
  Application  = "CustomerPortalPublic"
  LLD          = "2.1.8"
}
```

**IAM Access**:
- Lambda execution roles: Read-only (GetObject, ListBucket)
- Developers: Read/write via AWS Console and CLI
- GitHub Actions: Full access for deployment

**Terraform Backend**:
```hcl
terraform {
  backend "s3" {
    bucket         = "bbws-terraform-state-dev"
    key            = "2_1_bbws_s3_schemas/templates/terraform.tfstate"
    region         = "af-south-1"
    dynamodb_table = "terraform-state-lock-dev"
    encrypt        = true
  }
}
```

**Environment Variables** (Terraform):
```hcl
# dev.tfvars
environment         = "dev"
aws_account_id      = "536580886816"
aws_region          = "af-south-1"
bucket_name         = "bbws-templates-dev"
versioning_enabled  = true
lifecycle_days      = 30
access_logging      = false
replication_enabled = false
```

---

### 5.4.2 SIT Environment

**Bucket Name**: `bbws-templates-sit`

**AWS Account ID**: `815856636111`

**Region**: `af-south-1` (Cape Town, South Africa)

**Versioning**: Enabled

**Lifecycle Policy**:
- Current versions: Retain indefinitely
- Non-current versions: Delete after 60 days

**Access Logging**: Enabled
- Log bucket: `bbws-logs-sit`
- Log prefix: `s3-access-logs/templates/`
- Retention: 30 days

**Replication**: None

**Tags**:
```hcl
tags = {
  Environment  = "sit"
  Project      = "BBWS WP Containers"
  Owner        = "Tebogo"
  CostCenter   = "AWS"
  ManagedBy    = "Terraform"
  Component    = "s3"
  Application  = "CustomerPortalPublic"
  LLD          = "2.1.8"
}
```

**IAM Access**:
- Lambda execution roles: Read-only (GetObject, ListBucket)
- DevOps + QA: Read/write via AWS Console and CLI
- GitHub Actions: Full access for deployment

**Terraform Backend**:
```hcl
terraform {
  backend "s3" {
    bucket         = "bbws-terraform-state-sit"
    key            = "2_1_bbws_s3_schemas/templates/terraform.tfstate"
    region         = "af-south-1"
    dynamodb_table = "terraform-state-lock-sit"
    encrypt        = true
  }
}
```

**Environment Variables** (Terraform):
```hcl
# sit.tfvars
environment         = "sit"
aws_account_id      = "815856636111"
aws_region          = "af-south-1"
bucket_name         = "bbws-templates-sit"
versioning_enabled  = true
lifecycle_days      = 60
access_logging      = true
log_bucket          = "bbws-logs-sit"
log_prefix          = "s3-access-logs/templates/"
replication_enabled = false
```

---

### 5.4.3 PROD Environment

**Bucket Name**: `bbws-templates-prod`

**AWS Account ID**: `093646564004`

**Primary Region**: `af-south-1` (Cape Town, South Africa)

**DR Region**: `eu-west-1` (Ireland)

**Versioning**: Enabled

**Lifecycle Policy**:
- Current versions: Retain indefinitely
- Non-current versions: Delete after 90 days

**Access Logging**: Enabled
- Log bucket: `bbws-logs-prod`
- Log prefix: `s3-access-logs/templates/`
- Retention: 90 days

**Replication**: Enabled
- Destination bucket: `bbws-templates-prod-dr-eu-west-1`
- Replication rule: All objects (including delete markers)
- Storage class: STANDARD (both regions)
- Encryption: Replicate SSE-S3 encryption

**Tags** (7 mandatory tags from Worker 3-3):
```hcl
tags = {
  Environment  = "prod"
  Project      = "BBWS WP Containers"
  Owner        = "Tebogo"
  CostCenter   = "AWS"
  ManagedBy    = "Terraform"
  Component    = "s3"
  Application  = "CustomerPortalPublic"
  LLD          = "2.1.8"
  BackupPolicy = "hourly"  # Additional tag for PROD
  DR           = "enabled"  # Additional tag for PROD
}
```

**IAM Access**:
- Lambda execution roles: Read-only (GetObject, ListBucket)
- DevOps: Read-only via AWS Console (write only via Terraform/pipeline)
- GitHub Actions: Full access for deployment (manual approval required)

**Terraform Backend**:
```hcl
terraform {
  backend "s3" {
    bucket         = "bbws-terraform-state-prod"
    key            = "2_1_bbws_s3_schemas/templates/terraform.tfstate"
    region         = "af-south-1"
    dynamodb_table = "terraform-state-lock-prod"
    encrypt        = true
  }
}
```

**Environment Variables** (Terraform):
```hcl
# prod.tfvars
environment         = "prod"
aws_account_id      = "093646564004"
aws_region          = "af-south-1"
bucket_name         = "bbws-templates-prod"
versioning_enabled  = true
lifecycle_days      = 90
access_logging      = true
log_bucket          = "bbws-logs-prod"
log_prefix          = "s3-access-logs/templates/"
replication_enabled = true
replication_region  = "eu-west-1"
replication_bucket  = "bbws-templates-prod-dr-eu-west-1"
```

**Disaster Recovery Bucket** (eu-west-1):

**Bucket Name**: `bbws-templates-prod-dr-eu-west-1`

**Purpose**: Disaster recovery replica of primary PROD bucket

**Region**: `eu-west-1` (Ireland)

**Versioning**: Enabled (automatically by replication)

**Encryption**: SSE-S3 (replicated from source)

**Public Access**: BLOCKED

**Replication Source**: `bbws-templates-prod` (af-south-1)

**Access**: Read-only (failover scenario only)

---

## 5.5 Access Control

### 5.5.1 IAM Policies for Lambda Functions

Lambda functions require read-only access to S3 templates bucket.

**Policy Name**: `bbws-lambda-s3-templates-read-{env}`

**Policy Document**:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowReadTemplates",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:ListBucket",
        "s3:ListBucketVersions"
      ],
      "Resource": [
        "arn:aws:s3:::bbws-templates-dev",
        "arn:aws:s3:::bbws-templates-dev/*"
      ]
    }
  ]
}
```

**Attached to Roles**:
- `2-1-bbws-order-lambda-role-{env}`
- `2-1-bbws-payment-lambda-role-{env}`
- `2-1-bbws-tenant-lambda-role-{env}`
- `2-1-bbws-invoice-lambda-role-{env}` (future)
- `2-1-bbws-campaign-lambda-role-{env}` (future)

### 5.5.2 Bucket Policy

**Purpose**: Enforce bucket-level access controls, deny public access.

**DEV Bucket Policy**:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyPublicAccess",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::bbws-templates-dev",
        "arn:aws:s3:::bbws-templates-dev/*"
      ],
      "Condition": {
        "StringNotEquals": {
          "aws:PrincipalAccount": "536580886816"
        }
      }
    },
    {
      "Sid": "AllowLambdaReadTemplates",
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "arn:aws:iam::536580886816:role/2-1-bbws-order-lambda-role-dev",
          "arn:aws:iam::536580886816:role/2-1-bbws-payment-lambda-role-dev",
          "arn:aws:iam::536580886816:role/2-1-bbws-tenant-lambda-role-dev"
        ]
      },
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::bbws-templates-dev",
        "arn:aws:s3:::bbws-templates-dev/*"
      ]
    },
    {
      "Sid": "AllowTerraformManagement",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::536580886816:role/bbws-terraform-deployer-dev"
      },
      "Action": [
        "s3:PutObject",
        "s3:PutObjectAcl",
        "s3:DeleteObject",
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

**SIT and PROD**: Similar structure, with account IDs and role names updated per environment.

### 5.5.3 Encryption

**Encryption at Rest**:
- **Method**: Server-Side Encryption with Amazon S3-Managed Keys (SSE-S3)
- **Algorithm**: AES-256
- **Key Management**: AWS manages encryption keys automatically
- **Cost**: No additional charge for SSE-S3

**Terraform Configuration**:
```hcl
resource "aws_s3_bucket_server_side_encryption_configuration" "templates" {
  bucket = aws_s3_bucket.templates.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}
```

**Encryption in Transit**:
- **Method**: HTTPS/TLS 1.2+
- **Enforcement**: Bucket policy denies requests without secure transport

**Enforce HTTPS Policy**:
```json
{
  "Sid": "DenyInsecureTransport",
  "Effect": "Deny",
  "Principal": "*",
  "Action": "s3:*",
  "Resource": [
    "arn:aws:s3:::bbws-templates-dev",
    "arn:aws:s3:::bbws-templates-dev/*"
  ],
  "Condition": {
    "Bool": {
      "aws:SecureTransport": "false"
    }
  }
}
```

### 5.5.4 HTTPS Only

All S3 bucket access enforced via HTTPS only (no HTTP).

**Lambda S3 Client Configuration**:
```python
import boto3

s3_client = boto3.client(
    's3',
    region_name='af-south-1',
    config=boto3.session.Config(
        signature_version='s3v4',
        s3={'addressing_style': 'virtual'}  # Use virtual-hosted-style URLs (HTTPS)
    )
)

# GetObject always uses HTTPS
response = s3_client.get_object(
    Bucket='bbws-templates-dev',
    Key='receipts/payment_received.html'
)
```

---

## 5.6 Lifecycle Policies

### 5.6.1 Template Version Retention

**Current Versions**:
- **Retention**: Indefinite (no automatic deletion)
- **Rationale**: Templates are small (< 100 KB each), storage cost negligible

**Non-Current Versions** (previous template versions):
- **DEV**: Delete after 30 days
- **SIT**: Delete after 60 days
- **PROD**: Delete after 90 days
- **Rationale**: Balance between version history and storage costs

**Lifecycle Rule Configuration** (Terraform):
```hcl
resource "aws_s3_bucket_lifecycle_configuration" "templates" {
  bucket = aws_s3_bucket.templates.id

  rule {
    id     = "delete-old-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = var.lifecycle_days  # 30, 60, or 90 based on env
    }
  }
}
```

### 5.6.2 No Automatic Deletion of Current Templates

**Policy**: Current template versions are never automatically deleted.

**Manual Deletion**: Requires explicit Terraform change or manual S3 operation (with approval).

**Rationale**:
- Templates are critical for system operation
- Accidental deletion would break email sending
- Versioning provides rollback capability
- Storage cost is negligible (12 templates × 50 KB average = 600 KB total)

---

## 5.7 Cross-Region Replication (PROD Only)

### 5.7.1 Replication Configuration

**Source Bucket**: `bbws-templates-prod` (af-south-1)

**Destination Bucket**: `bbws-templates-prod-dr-eu-west-1` (eu-west-1)

**Replication Rule**: Replicate all objects and delete markers

**Storage Class**: STANDARD in both regions (fast access for DR scenario)

**Replication Time**: Near real-time (within 15 minutes typical)

**Purpose**: Disaster recovery, ensure template availability during af-south-1 regional failure

### 5.7.2 Terraform Replication Configuration

**Source Bucket Versioning** (required for replication):
```hcl
resource "aws_s3_bucket_versioning" "templates_prod" {
  bucket = aws_s3_bucket.templates_prod.id

  versioning_configuration {
    status = "Enabled"
  }
}
```

**IAM Replication Role**:
```hcl
resource "aws_iam_role" "replication" {
  name = "bbws-s3-replication-role-prod"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "replication" {
  role = aws_iam_role.replication.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.templates_prod.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ]
        Resource = "${aws_s3_bucket.templates_prod.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ]
        Resource = "${aws_s3_bucket.templates_prod_dr.arn}/*"
      }
    ]
  })
}
```

**Replication Rule**:
```hcl
resource "aws_s3_bucket_replication_configuration" "templates_prod" {
  bucket = aws_s3_bucket.templates_prod.id
  role   = aws_iam_role.replication.arn

  rule {
    id     = "replicate-all-to-eu-west-1"
    status = "Enabled"

    filter {}  # Empty filter = replicate all objects

    delete_marker_replication {
      status = "Enabled"
    }

    destination {
      bucket        = aws_s3_bucket.templates_prod_dr.arn
      storage_class = "STANDARD"

      replication_time {
        status = "Enabled"
        time {
          minutes = 15
        }
      }

      metrics {
        status = "Enabled"
        event_threshold {
          minutes = 15
        }
      }
    }
  }
}
```

### 5.7.3 DR Bucket Configuration

**Bucket Name**: `bbws-templates-prod-dr-eu-west-1`

**Region**: `eu-west-1` (Ireland)

**Versioning**: Enabled (required for replication)

**Encryption**: SSE-S3 (AES-256)

**Public Access**: BLOCKED

**Access**: Read-only (failover scenario only)

**Terraform Configuration**:
```hcl
resource "aws_s3_bucket" "templates_prod_dr" {
  provider = aws.eu_west_1  # Use alternate region provider
  bucket   = "bbws-templates-prod-dr-eu-west-1"

  tags = merge(var.common_tags, {
    Name    = "BBWS Templates PROD DR"
    Region  = "eu-west-1"
    Purpose = "DisasterRecovery"
  })
}

resource "aws_s3_bucket_versioning" "templates_prod_dr" {
  provider = aws.eu_west_1
  bucket   = aws_s3_bucket.templates_prod_dr.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "templates_prod_dr" {
  provider = aws.eu_west_1
  bucket   = aws_s3_bucket.templates_prod_dr.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "templates_prod_dr" {
  provider = aws.eu_west_1
  bucket   = aws_s3_bucket.templates_prod_dr.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

### 5.7.4 Failover Strategy

**Primary Region Failure Detection**:
- CloudWatch alarm monitors S3 API errors in af-south-1
- Route 53 health checks monitor Lambda endpoints in af-south-1
- Manual failover decision by DevOps team

**Failover Process**:
1. **Detection**: CloudWatch alarm triggers SNS notification
2. **Decision**: DevOps team assesses impact and decides to failover
3. **Lambda Update**: Update Lambda environment variables to use DR bucket:
   ```
   TEMPLATE_BUCKET_NAME=bbws-templates-prod-dr-eu-west-1
   AWS_REGION=eu-west-1
   ```
4. **Deploy**: Deploy Lambda configuration change via Terraform
5. **Verify**: Run smoke tests to confirm email sending from DR bucket
6. **Monitor**: CloudWatch dashboards track DR region performance

**Failback Process** (after primary region recovery):
1. **Verification**: Confirm af-south-1 region is fully operational
2. **Data Sync**: Ensure replication is caught up (check S3 replication metrics)
3. **Lambda Rollback**: Update Lambda environment variables back to primary:
   ```
   TEMPLATE_BUCKET_NAME=bbws-templates-prod
   AWS_REGION=af-south-1
   ```
4. **Deploy**: Deploy Lambda configuration change via Terraform
5. **Monitor**: Verify normal operations in primary region

**RTO (Recovery Time Objective)**: < 30 minutes

**RPO (Recovery Point Objective)**: < 15 minutes (replication time)

---

## 5.8 Integration with Lambda Services

### 5.8.1 Lambda Template Retrieval Pattern

Lambda functions retrieve templates from S3 using the following pattern:

**Python Example** (Order Lambda):
```python
import os
import boto3
import re
from botocore.exceptions import ClientError

# Initialize S3 client
s3_client = boto3.client('s3', region_name=os.environ.get('AWS_REGION', 'af-south-1'))

TEMPLATE_BUCKET = os.environ.get('TEMPLATE_BUCKET_NAME', 'bbws-templates-dev')

def get_email_template(category: str, template_name: str) -> str:
    """
    Retrieve HTML email template from S3.

    Args:
        category: Template category (receipts, notifications, invoices, marketing)
        template_name: Template filename without extension

    Returns:
        HTML template string

    Raises:
        TemplateNotFoundException: If template does not exist
        S3AccessException: If S3 access fails
    """
    object_key = f"{category}/{template_name}.html"

    try:
        response = s3_client.get_object(
            Bucket=TEMPLATE_BUCKET,
            Key=object_key
        )
        template_html = response['Body'].read().decode('utf-8')
        return template_html

    except s3_client.exceptions.NoSuchKey:
        raise TemplateNotFoundException(f"Template not found: {object_key}")

    except ClientError as e:
        raise S3AccessException(f"Failed to retrieve template: {e}")


def render_template(template_html: str, variables: dict) -> str:
    """
    Replace Mustache-style variables in template with actual values.

    Args:
        template_html: HTML template string with {{variables}}
        variables: Dictionary of variable names to values

    Returns:
        Rendered HTML string with variables substituted
    """
    rendered = template_html
    for key, value in variables.items():
        pattern = r'\{\{' + key + r'\}\}'
        rendered = re.sub(pattern, str(value), rendered)

    # Log warning for unreplaced variables
    unreplaced = re.findall(r'\{\{([^}]+)\}\}', rendered)
    if unreplaced:
        print(f"WARNING: Unreplaced variables: {unreplaced}")

    # Remove unreplaced variables (defensive)
    rendered = re.sub(r'\{\{[^}]+\}\}', '', rendered)

    return rendered


def send_payment_received_email(order: dict, payment: dict):
    """
    Send payment received email to customer.

    Args:
        order: Order object from DynamoDB
        payment: Payment object from DynamoDB
    """
    # Retrieve template
    template_html = get_email_template('receipts', 'payment_received')

    # Prepare variables
    variables = {
        'tenantEmail': order['customerEmail'],
        'tenantName': order.get('customerName', 'Valued Customer'),
        'orderId': order['id'],
        'amount': f"{payment['amount']:.2f}",
        'currency': order['currency'],
        'paymentDate': payment['paidAt'],
        'paymentMethod': order['paymentMethod'],
        'payfastPaymentId': payment.get('payfastId', 'N/A'),
        'receiptUrl': f"https://portal.kimmyai.io/receipts/{order['id']}",
        'orderDetailsUrl': f"https://portal.kimmyai.io/orders/{order['id']}"
    }

    # Render template
    email_html = render_template(template_html, variables)

    # Send email via SES
    ses_client = boto3.client('ses', region_name='af-south-1')

    response = ses_client.send_email(
        Source='noreply@kimmyai.io',
        Destination={'ToAddresses': [order['customerEmail']]},
        Message={
            'Subject': {'Data': f"Payment Received - Order {order['id']}"},
            'Body': {
                'Html': {'Data': email_html},
                'Text': {'Data': generate_plain_text(variables)}  # Fallback
            }
        }
    )

    print(f"Email sent: MessageId={response['MessageId']}")
```

### 5.8.2 Caching Strategy (Future Enhancement)

**Problem**: Lambda cold starts incur S3 GetObject latency (50-100ms per template).

**Solution**: Cache templates in Lambda memory across invocations.

**Implementation**:
```python
import time

# Global cache (persists across Lambda invocations)
_template_cache = {}
CACHE_TTL = 3600  # 1 hour

def get_email_template_cached(category: str, template_name: str) -> str:
    """
    Retrieve HTML email template from S3 with in-memory caching.

    Args:
        category: Template category
        template_name: Template filename without extension

    Returns:
        HTML template string (from cache or S3)
    """
    cache_key = f"{category}/{template_name}"

    # Check cache
    if cache_key in _template_cache:
        cached_template, cached_time = _template_cache[cache_key]
        if time.time() - cached_time < CACHE_TTL:
            print(f"Template retrieved from cache: {cache_key}")
            return cached_template

    # Cache miss or expired, fetch from S3
    template_html = get_email_template(category, template_name)

    # Update cache
    _template_cache[cache_key] = (template_html, time.time())

    print(f"Template fetched from S3 and cached: {cache_key}")
    return template_html
```

**Benefits**:
- Reduced S3 API calls (cost savings)
- Faster email rendering (reduced latency)
- Cached templates persist across warm Lambda invocations

**Trade-offs**:
- Template updates require cache invalidation (TTL or Lambda restart)
- Memory consumption (12 templates × 50 KB = 600 KB, negligible)

---

## 5.9 Deployment Workflow

### 5.9.1 GitHub Actions Pipeline

**Workflow Trigger**: Push to `main` branch or manual workflow dispatch

**Pipeline Stages**:

1. **Validation**
   - HTML syntax validation (`tidy`)
   - Variable validation (check all variables have test data)
   - Terraform format check (`terraform fmt -check`)
   - Terraform validation (`terraform validate`)

2. **Terraform Plan**
   - Generate plan for DEV, SIT, PROD environments
   - Upload plan artifacts

3. **Approval Gate**
   - Manual review of terraform plans
   - Lead Developer approval for DEV
   - Tech Lead + QA approval for SIT
   - Tech Lead + Product Owner approval for PROD

4. **Deploy DEV**
   - Manual trigger: "deploy-dev"
   - Terraform apply to DEV environment
   - Upload templates to `bbws-templates-dev`
   - Post-deployment validation tests

5. **Promote SIT**
   - Manual trigger: "promote-sit"
   - Terraform apply to SIT environment
   - Upload templates to `bbws-templates-sit`
   - Integration tests

6. **Promote PROD**
   - Manual trigger: "promote-prod"
   - Terraform apply to PROD environment
   - Upload templates to `bbws-templates-prod`
   - Smoke tests
   - Verify cross-region replication

### 5.9.2 Template Upload Process

Templates are uploaded to S3 during Terraform apply using `aws_s3_object` resources:

```hcl
resource "aws_s3_object" "payment_received_template" {
  bucket       = aws_s3_bucket.templates.id
  key          = "receipts/payment_received.html"
  source       = "${path.module}/../../templates/receipts/payment_received.html"
  content_type = "text/html"
  etag         = filemd5("${path.module}/../../templates/receipts/payment_received.html")

  server_side_encryption = "AES256"

  tags = merge(var.common_tags, {
    TemplateCategory = "receipts"
    TemplateName     = "payment_received"
  })
}
```

**Benefits**:
- Templates are versioned in Git
- Terraform tracks template changes (etag)
- Atomic deployment (all templates or none)
- Rollback capability via Terraform state

---

## 5.10 Monitoring and Alerting

### 5.10.1 CloudWatch Metrics

**S3 Metrics to Monitor**:
- `NumberOfObjects`: Track template count
- `BucketSizeBytes`: Monitor storage usage
- `AllRequests`: Total request count
- `GetRequests`: Template retrieval count
- `4xxErrors`: Client errors (template not found)
- `5xxErrors`: Server errors (S3 service issues)

**Replication Metrics** (PROD only):
- `ReplicationLatency`: Time to replicate objects to DR
- `BytesPendingReplication`: Data pending replication
- `OperationsPendingReplication`: Number of operations pending

### 5.10.2 CloudWatch Alarms

**DEV Environment**:
- No alarms (cost optimization)

**SIT Environment**:
- `TemplateNotFoundAlarm`: Trigger if 4xx errors > 5 in 5 minutes

**PROD Environment**:
- `TemplateNotFoundAlarm`: Trigger if 4xx errors > 2 in 5 minutes
- `S3ServiceErrorAlarm`: Trigger if 5xx errors > 1 in 5 minutes
- `ReplicationLatencyAlarm`: Trigger if replication latency > 30 minutes

**Alarm Actions**:
- SNS notification to DevOps team
- Slack channel: `#prod-alerts`
- PagerDuty escalation (PROD only)

### 5.10.3 Access Logging Analysis

**SIT and PROD**: S3 access logs enable security auditing.

**Log Format**: S3 Server Access Logs
```
79a59df900b949e55d96a1e698fbacedfd6e09d98eacf8f8d5218e7cd47ef2be bbws-templates-prod [19/Dec/2025:10:30:00 +0000] 203.0.113.1 arn:aws:iam::093646564004:role/2-1-bbws-order-lambda-role-prod 3E57427F3EXAMPLE REST.GET.OBJECT receipts/payment_received.html "GET /bbws-templates-prod/receipts/payment_received.html HTTP/1.1" 200 - 12345 12345 50 40 "-" "aws-sdk-python/1.26.0" - 7NKU2C90PYmYBvEDr0qYUkEGFBOROLBrQqWVZkZ8FPBiVHZF6Qk= SigV4 ECDHE-RSA-AES128-GCM-SHA256 AuthHeader bbws-templates-prod.s3.af-south-1.amazonaws.com TLSv1.2
```

**Analysis Queries** (S3 Select or Athena):
- Templates accessed by hour
- Most frequently accessed templates
- Access patterns by Lambda function
- Failed access attempts (404s)

---

## 5.11 Cost Estimation

### 5.11.1 Storage Costs

**Template Storage**:
- Templates: 12 files × 50 KB average = 600 KB
- S3 Standard storage (af-south-1): $0.023 per GB/month
- **Cost**: $0.023 × 0.0006 GB = **$0.00001/month** (negligible)

**Version Storage** (worst case: 10 versions per template):
- Total versions: 12 templates × 10 versions × 50 KB = 6 MB
- **Cost**: $0.023 × 0.006 GB = **$0.00014/month** (negligible)

**Cross-Region Replication** (PROD only):
- Primary: 600 KB (af-south-1)
- Replica: 600 KB (eu-west-1)
- Data transfer: $0.02 per GB (one-time)
- **Cost**: $0.02 × 0.0006 GB = **$0.00001** (one-time)

**Total Storage Cost**: < $0.01/month per environment

### 5.11.2 Request Costs

**Assumptions**:
- 10,000 orders/month (PROD)
- 2 email templates per order average (order confirmation + payment receipt)
- 20,000 template retrievals/month

**S3 GET Request Pricing**:
- af-south-1: $0.0004 per 1,000 GET requests
- 20,000 requests = 20 × $0.0004 = **$0.008/month**

**With Caching** (90% cache hit rate):
- Actual S3 requests: 2,000/month
- **Cost**: 2 × $0.0004 = **$0.0008/month**

**Total Request Cost**: < $0.01/month

### 5.11.3 Total S3 Costs

| Environment | Storage | Requests | Replication | Total/Month |
|-------------|---------|----------|-------------|-------------|
| DEV | $0.00001 | $0.001 | $0 | **$0.001** |
| SIT | $0.00001 | $0.002 | $0 | **$0.002** |
| PROD | $0.00002 | $0.008 | $0 | **$0.01** |

**Total Across All Environments**: < $0.02/month

**Conclusion**: S3 template storage costs are negligible. Primary costs are Lambda execution and SES email sending.

---

## Summary

This comprehensive S3 bucket design section documents:

1. **Overview**: Purpose, retrieval strategy, and design philosophy for HTML email templates
2. **Bucket Configuration**: Detailed settings for `bbws-templates-{env}` including versioning, encryption, access logging, and cross-region replication
3. **Object Key Structure**: Hierarchical folder organization by template category
4. **12 HTML Email Templates**: Complete specifications with purpose, variables, triggers, and content focus
5. **Template Design Standards**: Responsive design, plain text alternatives, unsubscribe links, brand consistency, variable format, and testing requirements
6. **Repository Structure**: Complete directory layout for `2_1_bbws_s3_schemas` repository
7. **Environment Configuration**: Detailed configurations for DEV, SIT, and PROD environments
8. **Access Control**: IAM policies, bucket policies, encryption, and HTTPS enforcement
9. **Lifecycle Policies**: Template version retention rules
10. **Cross-Region Replication**: PROD disaster recovery configuration
11. **Lambda Integration**: Template retrieval patterns and caching strategies
12. **Deployment Workflow**: GitHub Actions pipeline and Terraform template uploads
13. **Monitoring**: CloudWatch metrics, alarms, and access logging
14. **Cost Estimation**: Storage and request cost analysis

All configurations align with Stage 1 requirements, naming conventions, and environment specifications.

---

**End of Section 5: S3 Bucket Design**
