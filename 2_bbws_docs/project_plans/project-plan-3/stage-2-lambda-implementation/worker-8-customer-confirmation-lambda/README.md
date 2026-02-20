# Worker 8: CustomerOrderConfirmationSender Lambda

## Overview

The **CustomerOrderConfirmationSender** Lambda function processes SQS messages from new orders and sends customer-facing confirmation emails with presigned S3 URLs for invoice PDFs.

This worker differs from Worker 7 (Internal Notification Sender) in that it:
- Sends emails to **customers** (not internal team)
- Uses **customer-facing email template** with order details
- Includes **presigned S3 URL** for PDF invoice download (7-day expiration)
- Adds **campaign details** (discount code, discount amount) to email context
- Sets **reply-to address** for customer support email

## Architecture

```
SQS Queue (bbws-order-creation-{env})
    ↓
Lambda: CustomerOrderConfirmationSender
    ├→ OrderDAO: Retrieve order from DynamoDB
    ├→ EmailService: Compose customer confirmation email
    │  ├→ S3Service: Fetch customer email template
    │  ├→ S3Service: Generate presigned invoice URL (7 days)
    │  └→ SESService: Send email to customer with reply-to
    └→ SQS: Report batch item failures for retry
```

## Trigger

**Event Source**: SQS Queue `bbws-order-creation-{env}`

**Event Structure**:
```json
{
  "Records": [
    {
      "messageId": "message-123",
      "body": "{\"tenantId\": \"tenant-123\", \"orderId\": \"order-456\"}"
    }
  ]
}
```

## Email Template Variables

The customer confirmation email template receives the following context:

### Order Information
- `orderNumber`: Human-readable order number (e.g., "ORD-2025-001")
- `orderDate`: Order creation timestamp (YYYY-MM-DD HH:MM:SS format)
- `orderStatus`: Current order status (pending, processing, completed, cancelled)
- `paymentStatus`: Payment status (pending, paid, failed, refunded)

### Customer Information
- `customerName`: Full customer name
- `customerEmail`: Customer email address
- `customerPortalUrl`: URL to customer's order in portal

### Order Items
- `items`: Array of order items with:
  - `itemId`: Unique item identifier
  - `quantity`: Quantity ordered
  - `unitPrice`: Price per unit (formatted as R0.00)
  - `subtotal`: Line item total (formatted as R0.00)
  - `campaignName`: Campaign/product name

### Pricing
- `subtotal`: Order subtotal before tax/shipping (formatted as R0.00)
- `tax`: Tax amount (formatted as R0.00)
- `shipping`: Shipping cost (formatted as R0.00)
- `discount`: Discount amount (formatted as R0.00)
- `total`: Final order total (formatted as R0.00)

### Addresses
- `billingAddress`: Billing address object
  - `street`: Street address
  - `city`: City name
  - `postalCode`: Postal code
  - `country`: Country code
- `shippingAddress`: Shipping address (if different from billing)

### Campaign Information
- `campaign`: Campaign details (optional, only if campaign applied)
  - `campaignId`: Campaign identifier
  - `campaignName`: Campaign name
  - `code`: Campaign code (if available)
  - `discount`: Discount amount (if available)

### File Download
- `pdfPresignedUrl`: AWS S3 presigned URL for invoice PDF (expires in 7 days)
- `pdfDownloadUrl`: Same as pdfPresignedUrl (for template compatibility)

### Support
- `supportEmail`: Support team email (support@kimmyai.io)

## Configuration

### Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `DYNAMODB_TABLE_NAME` | `bbws-orders-dev` | DynamoDB table for orders |
| `EMAIL_TEMPLATE_BUCKET` | `bbws-email-templates-dev` | S3 bucket for email templates |
| `INVOICE_BUCKET` | `bbws-invoices-dev` | S3 bucket for invoice PDFs |
| `SES_FROM_EMAIL` | `noreply@kimmyai.io` | From address for emails |
| `INTERNAL_NOTIFICATION_EMAIL` | `internal@kimmyai.io` | Not used by this worker |
| `ADMIN_PORTAL_URL` | `https://admin.kimmyai.io` | Not used by this worker |
| `CUSTOMER_PORTAL_URL` | `https://customer.kimmyai.io` | Customer portal base URL |

### S3 Template Path

Customer confirmation email template location:
```
s3://{EMAIL_TEMPLATE_BUCKET}/customer/order_confirmation.html
```

### Invoice PDF Location

Invoice PDFs expected at:
```
s3://{INVOICE_BUCKET}/invoices/{order_id}/{order_id}.pdf
```

## Handler Function

**Module**: `src/handlers/customer_order_confirmation_sender.py`

**Function**: `lambda_handler(event, context)`

### Input
- `event`: SQS event with Records array
- `context`: Lambda context object

### Output
```json
{
  "statusCode": 200,
  "batchItemFailures": [
    {"itemIdentifier": "message-123"}
  ]
}
```

## Error Handling

The handler implements **partial batch failure** processing:

- **Successful messages**: Not included in batchItemFailures
- **Failed messages**: Added to batchItemFailures for automatic SQS retry
- **Idempotency**: If order not found in DynamoDB, treated as success (may have been deleted)

### Handled Errors

1. **Missing fields**: KeyError (missing tenantId or orderId)
2. **Invalid JSON**: JSONDecodeError (malformed message body)
3. **Order not found**: Treated as success (idempotent)
4. **DynamoDB errors**: Added to batchItemFailures for retry
5. **Template errors**: Added to batchItemFailures for retry
6. **SES send failures**: Added to batchItemFailures for retry
7. **S3 errors**: Added to batchItemFailures for retry

## Key Features

### 1. Customer-Facing Email
- Professional HTML template with order details
- Clean, branded design with gradient header
- Itemized order summary with campaign information
- Billing and shipping addresses

### 2. Presigned URL Generation
- Generates 7-day expiration presigned URL for invoice PDF
- S3 key pattern: `invoices/{order_id}/{order_id}.pdf`
- URL embedded in email for direct PDF download
- Automatic expiration ensures temporary access

### 3. Campaign Support
- Extracts campaign details from first order item
- Displays campaign name and discount amount in email
- Campaign details optional (gracefully handles missing campaigns)

### 4. Email Delivery
- **To**: Customer email from order (`order.customerEmail`)
- **From**: `noreply@kimmyai.io`
- **Reply-To**: `support@kimmyai.io`
- **Subject**: `Order Confirmation - #{orderNumber}`

### 5. Fallback Handling
- Uses HTML template from S3 if available
- Falls back to plain text email if template missing
- Continues processing even if template unavailable

## Dependencies

### Python Packages
- `boto3`: AWS SDK for DynamoDB, S3, SES
- `pydantic`: Data validation and serialization
- `jinja2`: Template rendering

### AWS Services
- **DynamoDB**: Order retrieval
- **S3**: Template and invoice file storage
- **SES**: Email sending
- **SQS**: Event source and partial batch failure handling
- **CloudWatch**: Logging and monitoring

## Testing

### Unit Tests
Test files: `tests/unit/test_lambda_handler.py`

```bash
pytest tests/unit/ -v
```

### Integration Tests
Test files: `tests/integration/test_customer_confirmation_integration.py`

```bash
pytest tests/integration/ -v
```

### Local Testing
```bash
python -m pytest --cov=src --cov-report=html
```

## Deployment

### Infrastructure as Code
Terraform variables required:
```hcl
variable "invoice_bucket" {
  description = "S3 bucket for invoice PDFs"
  type        = string
  default     = "bbws-invoices-dev"
}
```

### Environment-Specific Configuration

| Environment | Table | Template Bucket | Invoice Bucket |
|-------------|-------|-----------------|-----------------|
| **DEV** | bbws-orders-dev | bbws-email-templates-dev | bbws-invoices-dev |
| **SIT** | bbws-orders-sit | bbws-email-templates-sit | bbws-invoices-sit |
| **PROD** | bbws-orders-prod | bbws-email-templates-prod | bbws-invoices-prod |

## Monitoring

### CloudWatch Metrics
- Invocations: Count of Lambda executions
- Errors: Failed orders (check batchItemFailures)
- Duration: Email sending latency
- Throttles: SQS concurrency limits

### CloudWatch Logs
All operations logged with structured format:
```
INFO CustomerOrderConfirmationSender invoked: 5 records
INFO Processing message msg-123: tenantId=tenant-123, orderId=order-456
INFO Preparing customer confirmation for order: order-456
INFO Generating presigned URL for invoice: invoices/order-456/order-456.pdf (expires in 604800s)
INFO Customer confirmation sent successfully to customer@example.com: SES MessageId=ses-123
INFO Batch processing complete: 5 succeeded, 0 failed
```

### Alarms
Recommended CloudWatch alarms:
- Lambda errors > 0 in 5 minutes
- Lambda throttles > 0
- SES SendEmail failures > 0
- SQS messages in DLQ > 0

## Differences from Worker 7 (Internal Notification)

| Aspect | Worker 7 (Internal) | Worker 8 (Customer) |
|--------|-------------------|-------------------|
| **Recipient** | Internal team (env var) | Customer email (from order) |
| **Email Template** | `internal/order_notification.html` | `customer/order_confirmation.html` |
| **Template Path** | Admin portal link to order details | Presigned S3 URL for invoice PDF |
| **Subject** | "New Order Received: {orderNumber}" | "Order Confirmation - #{orderNumber}" |
| **From Address** | noreply@kimmyai.io | noreply@kimmyai.io |
| **Reply-To** | None (default) | support@kimmyai.io |
| **Campaign Details** | Not included | Included in email |
| **Purpose** | Notify operations team | Provide customer confirmation |

## Common Issues

### Issue: Presigned URL generates but PDF not accessible
**Cause**: Invoice PDF not yet created in S3 bucket
**Solution**: Ensure Worker 6 (Invoice Generator) has completed before this worker

### Issue: Email not sent but no error in logs
**Cause**: SES template not found in S3
**Solution**: Verify `customer/order_confirmation.html` exists in EMAIL_TEMPLATE_BUCKET

### Issue: Wrong email recipient
**Cause**: `order.customerEmail` is null or invalid
**Solution**: Ensure Order model has valid customerEmail field from database

### Issue: Campaign details not appearing in email
**Cause**: Order items don't have campaign objects
**Solution**: Campaign is optional - email works without it

## Future Enhancements

1. **Email retry logic**: Implement exponential backoff for transient SES failures
2. **Email verification**: Verify customer email before sending (optional)
3. **Multi-language support**: Template variants for different languages
4. **PDF attachment**: Attach invoice as email attachment instead of presigned URL
5. **Email tracking**: SNS notifications for delivery, bounce, complaints
6. **A/B testing**: Multiple template variants for optimization

## Related Workers

- **Worker 5**: Order Creator Record Lambda (creates order)
- **Worker 6**: Invoice Generator Lambda (creates PDF invoice)
- **Worker 7**: Internal Notification Sender Lambda (internal email)
- **Worker 9**: Email Event Processor Lambda (handles SES events)

## References

- [AWS Lambda SQS Integration](https://docs.aws.amazon.com/lambda/latest/dg/services-sqs.html)
- [AWS SES Email Sending](https://docs.aws.amazon.com/ses/latest/DeveloperGuide/send-email.html)
- [AWS S3 Presigned URLs](https://docs.aws.amazon.com/AmazonS3/latest/dev/PresignedUrlUploadObject.html)
- [Jinja2 Template Engine](https://jinja.palletsprojects.com/)
- [Pydantic Models](https://docs.pydantic.dev/)
