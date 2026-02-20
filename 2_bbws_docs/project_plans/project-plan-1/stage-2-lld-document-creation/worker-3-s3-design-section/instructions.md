# Worker 2-3: S3 Design Section

**Worker ID**: worker-2-3-s3-design-section
**Stage**: Stage 2 - LLD Document Creation
**Status**: PENDING
**Estimated Effort**: Medium
**Dependencies**: Stage 1 Worker 1-1, Worker 3-3

---

## Objective

Create comprehensive S3 bucket design section (Section 5) of the LLD document with bucket specifications, object key patterns, HTML email templates, and lifecycle policies.

---

## Input Documents

1. **Stage 1 Outputs**:
   - `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/project-plan-1/stage-1-requirements-analysis/worker-1-hld-analysis/output.md` (S3 requirements from HLD)
   - `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/project-plan-1/stage-1-requirements-analysis/worker-3-naming-convention-analysis/output.md` (S3 naming, object key patterns)
   - `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/project-plan-1/stage-1-requirements-analysis/worker-4-environment-configuration-analysis/output.md` (S3 configs per env)

2. **Specification Documents**:
   - `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/specs/2.1.8_LLD_S3_and_DynamoDB_Spec.md` (Section 4: S3 Bucket Specifications)

3. **Parent HLD**:
   - `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/HLDs/2.1_BBWS_Customer_Portal_Public_HLD_V1.1.md` (Email template requirements)

---

## Deliverables

Create `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/project-plan-1/stage-2-lld-document-creation/worker-3-s3-design-section/output.md` containing:

### Section 5: S3 Bucket Design

#### 5.1 Overview
- Purpose of S3 buckets in the architecture
- Email template storage and retrieval strategy
- HTML template design philosophy

#### 5.2 Bucket: `bbws-templates-{env}`

**5.2.1 Bucket Configuration**
- Bucket naming: `bbws-templates-dev`, `bbws-templates-sit`, `bbws-templates-prod`
- Region: af-south-1 (primary), eu-west-1 (PROD DR only)
- Versioning: Enabled (all environments)
- Encryption: AES-256 (SSE-S3)
- Public access: BLOCKED (all environments)
- Logging: Enabled (log to separate bucket)

**5.2.2 Object Key Structure**

Document the organized folder structure:
```
receipts/
  ├── payment_received.html
  ├── payment_failed.html
  └── refund_processed.html
notifications/
  ├── order_confirmation.html
  ├── order_shipped.html
  ├── order_delivered.html
  └── order_cancelled.html
invoices/
  ├── invoice_created.html
  └── invoice_updated.html
marketing/
  ├── campaign_notification.html
  ├── welcome_email.html
  └── newsletter_template.html
```

**5.2.3 HTML Email Templates**

For each of the 12 templates, document:

1. **receipts/payment_received.html**
   - Purpose: Sent when payment is successfully processed
   - Variables: `{{tenantEmail}}`, `{{orderId}}`, `{{amount}}`, `{{currency}}`, `{{paymentDate}}`, `{{receiptUrl}}`
   - Triggered by: Order Lambda POST /v1.0/orders (when payment succeeds)

2. **receipts/payment_failed.html**
   - Purpose: Sent when payment fails
   - Variables: `{{tenantEmail}}`, `{{orderId}}`, `{{amount}}`, `{{failureReason}}`
   - Triggered by: Order Lambda POST /v1.0/orders (when payment fails)

3. **receipts/refund_processed.html**
   - Purpose: Sent when refund is processed
   - Variables: `{{tenantEmail}}`, `{{orderId}}`, `{{refundAmount}}`, `{{refundDate}}`
   - Triggered by: Payment Lambda refund operation

4. **notifications/order_confirmation.html**
   - Purpose: Sent immediately after order creation
   - Variables: `{{tenantEmail}}`, `{{orderId}}`, `{{productName}}`, `{{totalAmount}}`, `{{orderDate}}`
   - Triggered by: Order Lambda POST /v1.0/orders (immediately after creation)

5. **notifications/order_shipped.html**
   - Purpose: Sent when order status changes to SHIPPED (if physical goods in future)
   - Variables: `{{tenantEmail}}`, `{{orderId}}`, `{{trackingNumber}}`, `{{shippedDate}}`
   - Triggered by: Order Lambda PUT /v1.0/orders/{id} (status update)

6. **notifications/order_delivered.html**
   - Purpose: Sent when order status changes to DELIVERED
   - Variables: `{{tenantEmail}}`, `{{orderId}}`, `{{deliveredDate}}`
   - Triggered by: Order Lambda PUT /v1.0/orders/{id} (status update)

7. **notifications/order_cancelled.html**
   - Purpose: Sent when order is cancelled
   - Variables: `{{tenantEmail}}`, `{{orderId}}`, `{{cancellationReason}}`, `{{refundInfo}}`
   - Triggered by: Order Lambda PUT /v1.0/orders/{id} (status=CANCELLED)

8. **invoices/invoice_created.html**
   - Purpose: Sent when invoice is generated
   - Variables: `{{tenantEmail}}`, `{{invoiceId}}`, `{{orderId}}`, `{{invoiceDate}}`, `{{dueDate}}`, `{{amount}}`, `{{invoiceUrl}}`
   - Triggered by: Invoice generation process

9. **invoices/invoice_updated.html**
   - Purpose: Sent when invoice is updated
   - Variables: `{{tenantEmail}}`, `{{invoiceId}}`, `{{updateReason}}`, `{{newAmount}}`, `{{invoiceUrl}}`
   - Triggered by: Invoice Lambda PUT operation

10. **marketing/campaign_notification.html**
    - Purpose: Sent when new campaign is available
    - Variables: `{{tenantEmail}}`, `{{campaignCode}}`, `{{productName}}`, `{{discountPercentage}}`, `{{originalPrice}}`, `{{discountedPrice}}`, `{{fromDate}}`, `{{toDate}}`, `{{termsLink}}`
    - Triggered by: Campaign Lambda (manual or scheduled)

11. **marketing/welcome_email.html**
    - Purpose: Sent when tenant completes registration
    - Variables: `{{tenantEmail}}`, `{{tenantId}}`, `{{registrationDate}}`
    - Triggered by: Tenant Lambda (status change to REGISTERED)

12. **marketing/newsletter_template.html**
    - Purpose: Monthly newsletter template
    - Variables: `{{tenantEmail}}`, `{{month}}`, `{{featuredProducts}}`, `{{activeCampaigns}}`
    - Triggered by: Newsletter service (scheduled)

**5.2.4 Template Design Standards**

- **Responsive Design**: All templates must be mobile-responsive
- **Plain Text Alternative**: Each HTML template should have a plain text version
- **Unsubscribe Link**: Marketing emails must include `{{unsubscribeUrl}}`
- **Brand Consistency**: Use BBWS brand colors and logo
- **Variable Format**: Mustache-style variables `{{variableName}}`
- **Testing**: Test in multiple email clients (Gmail, Outlook, Apple Mail)

#### 5.3 Repository Structure

**5.3.1 Repository: `2_1_bbws_s3_schemas`**

Folder structure:
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
│   └── marketing/
│       ├── campaign_notification.html
│       ├── welcome_email.html
│       └── newsletter_template.html
├── terraform/
│   ├── modules/
│   │   └── s3_bucket/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── environments/
│       ├── dev.tfvars
│       ├── sit.tfvars
│       └── prod.tfvars
├── .github/
│   └── workflows/
│       ├── validate-templates.yml
│       ├── terraform-plan.yml
│       └── terraform-apply.yml
└── README.md
```

#### 5.4 Environment Configuration

**5.4.1 DEV Environment**
- Bucket: `bbws-templates-dev`
- Account ID: 536580886816
- Region: af-south-1
- Versioning: Enabled
- Logging: Enabled
- Replication: None
- Tags: Environment=dev, Project=bbws-customer-portal-public, ManagedBy=terraform

**5.4.2 SIT Environment**
(same structure)

**5.4.3 PROD Environment**
- Bucket: `bbws-templates-prod`
- Account ID: 093646564004
- Region: af-south-1 (primary)
- Versioning: Enabled
- Logging: Enabled
- Replication: Enabled to eu-west-1 (DR)
- Replication bucket: `bbws-templates-prod-dr-eu-west-1`
- Tags: (7 mandatory tags from Worker 3-3)

#### 5.5 Access Control

- **IAM Policies**: Lambda execution roles have GetObject permission
- **Bucket Policy**: Deny public access
- **Encryption**: All objects encrypted at rest (AES-256)
- **HTTPS Only**: Enforce SSL/TLS for all requests

#### 5.6 Lifecycle Policies

- **Template Versions**: Keep last 10 versions, delete older
- **Retention**: No automatic deletion (templates are permanent)

#### 5.7 Cross-Region Replication (PROD Only)

- Source: `bbws-templates-prod` (af-south-1)
- Destination: `bbws-templates-prod-dr-eu-west-1` (eu-west-1)
- Replication rule: All objects
- Storage class: STANDARD in both regions
- Purpose: Disaster recovery

---

## Quality Criteria

- [ ] All 12 HTML templates documented with purpose and variables
- [ ] Object key structure clearly defined
- [ ] Repository structure matches spec
- [ ] Environment configs match Stage 1 Worker 4-4 output
- [ ] Cross-region replication documented for PROD
- [ ] Access control and security documented
- [ ] No inconsistencies with HLD
- [ ] Technical accuracy verified

---

## Output Format

Write output to `output.md` using markdown format with proper headings, code blocks, and tables.

**Target Length**: 800-1,000 lines

---

## Special Instructions

1. **Use Exact Naming from Stage 1**:
   - Bucket naming from Worker 3-3: `bbws-templates-{env}`
   - Object key patterns from Worker 3-3
   - Repository name: `2_1_bbws_s3_schemas`

2. **Reference Worker 1-1 S3 Requirements**:
   - Extract email template requirements from HLD analysis
   - Identify all 12 templates and their purposes

3. **Cross-Reference Worker 4-4**:
   - Use environment account IDs from Worker 4-4
   - Use S3 configs (versioning, replication) from Worker 4-4

4. **Template Variables**:
   - Be specific about variable names and formats
   - Link templates to Lambda triggers (from Order Lambda spec)

---

**Worker Created**: 2025-12-25
**Execution Mode**: Parallel (with 5 other Stage 2 workers)
