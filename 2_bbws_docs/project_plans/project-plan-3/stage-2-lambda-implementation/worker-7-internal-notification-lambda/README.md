# OrderInternalNotificationSender Lambda

Event-driven Lambda function that sends internal team notifications when new orders are created.

## Overview

**Trigger**: SQS (`bbws-order-creation-{env}`)
**Target**: SES (internal team email)
**Architecture**: Python 3.12, arm64, Docker-based Lambda

## Functionality

1. Parse SQS messages containing order creation events
2. Fetch order details from DynamoDB
3. Retrieve HTML email template from S3
4. Render template with order data (Jinja2)
5. Send notification via SES to internal team
6. Fallback to plain-text email if template unavailable

## Key Features

- **Template-based emails**: HTML templates from S3 with Jinja2 rendering
- **Fallback mechanism**: Plain-text email if template fetch fails
- **Partial batch failure support**: Failed messages returned for SQS retry
- **Environment-agnostic**: All configs via environment variables
- **Comprehensive error handling**: Proper logging and exception handling
- **Test-Driven Development**: 80%+ test coverage

## Architecture

```
SQS Message → Lambda Handler → OrderDAO → DynamoDB
                     ↓
              EmailService → S3Service → S3 (templates)
                     ↓
              SESService → SES → Internal Email
```

## Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `DYNAMODB_TABLE_NAME` | DynamoDB table name | `bbws-orders-dev` |
| `EMAIL_TEMPLATE_BUCKET` | S3 bucket for email templates | `bbws-email-templates-dev` |
| `SES_FROM_EMAIL` | Sender email address | `noreply@kimmyai.io` (PROD/SIT), `test@kimmyai.io` (DEV) |
| `INTERNAL_NOTIFICATION_EMAIL` | Internal team recipient | `team@kimmyai.io` |
| `ADMIN_PORTAL_URL` | Admin portal base URL | `https://admin.kimmyai.io` |

## SQS Message Format

```json
{
  "tenantId": "tenant-123",
  "orderId": "order-456"
}
```

## Email Template Variables

The HTML template supports the following Jinja2 variables:

- `{{ orderNumber }}` - Human-readable order number
- `{{ customerEmail }}` - Customer email address
- `{{ customerName }}` - Customer full name
- `{{ total }}` - Total order amount
- `{{ orderDate }}` - Order creation date
- `{{ itemCount }}` - Number of items in order
- `{{ orderDetailsUrl }}` - Link to order in admin portal
- `{{ orderStatus }}` - Current order status
- `{{ paymentStatus }}` - Current payment status
- `{{ tenantId }}` - Tenant identifier
- `{{ orderId }}` - Order identifier

## Template Location

S3 Key: `internal/order_notification.html`

Sample template included in `templates/order_notification.html`

## Development

### Prerequisites

- Python 3.12+
- pip or poetry

### Installation

```bash
pip install -r requirements.txt
```

### Running Tests

```bash
# Run all tests with coverage
pytest

# Run specific test file
pytest tests/unit/handlers/test_order_internal_notification_sender.py

# Run with verbose output
pytest -v
```

### Test Coverage

Target: 80%+ coverage

```bash
pytest --cov=src --cov-report=html
open htmlcov/index.html
```

## Deployment

### Build Docker Image

```bash
docker build -t order-internal-notification-sender:latest .
```

### Test Locally

```bash
# Set environment variables
export DYNAMODB_TABLE_NAME=bbws-orders-dev
export EMAIL_TEMPLATE_BUCKET=bbws-email-templates-dev
export SES_FROM_EMAIL=test@kimmyai.io
export INTERNAL_NOTIFICATION_EMAIL=internal@kimmyai.io
export AWS_REGION=af-south-1

# Run tests
pytest
```

### Deploy to AWS

See Terraform configuration in `terraform/` directory (to be created in Stage 3).

## Error Handling

### Retry Logic

- **Order not found**: Treated as success (idempotent)
- **Template not found**: Falls back to plain-text email
- **SES send failure**: Message returned for SQS retry
- **DynamoDB error**: Message returned for SQS retry
- **Max retries**: Message sent to DLQ after 3 attempts (configured in SQS)

### Partial Batch Failures

The Lambda returns `batchItemFailures` array with `itemIdentifier` (messageId) for failed messages. SQS will only retry failed messages.

## Monitoring

### CloudWatch Metrics

- Lambda invocations
- Lambda errors
- Lambda duration
- SQS message age
- DLQ message count

### CloudWatch Logs

Structured logging with:
- Request ID
- Tenant ID
- Order ID
- Message ID
- Error details

### Alerts (to be configured)

- SES send failures
- DLQ messages
- Lambda errors > threshold
- Lambda duration > timeout

## Security

- IAM role with least-privilege permissions
- DynamoDB: Read-only access to orders table
- S3: Read-only access to email templates bucket
- SES: Send email permission for verified sender
- SQS: Receive and delete messages

## Dependencies

- `pydantic==1.10.18` - Data validation
- `boto3>=1.26.0` - AWS SDK
- `jinja2>=3.1.2` - Template rendering

### Dev Dependencies

- `pytest>=7.4.0`
- `pytest-cov>=4.1.0`
- `pytest-mock>=3.11.1`
- `moto[dynamodb,ses,s3,sqs]>=4.2.0`

## Project Structure

```
worker-7-internal-notification-lambda/
├── src/
│   ├── handlers/
│   │   └── order_internal_notification_sender.py
│   ├── services/
│   │   ├── email_service.py
│   │   ├── s3_service.py
│   │   └── ses_service.py
│   ├── dao/
│   │   └── order_dao.py
│   └── models/
│       ├── order.py
│       ├── order_item.py
│       ├── campaign.py
│       ├── billing_address.py
│       └── payment_details.py
├── tests/
│   └── unit/
│       ├── handlers/
│       ├── services/
│       └── dao/
├── templates/
│   └── order_notification.html
├── Dockerfile
├── requirements.txt
├── pyproject.toml
└── pytest.ini
```

## Related Documentation

- Stage 2 Plan: `../plan.md`
- LLD: `../../../2.1.8_LLD_Order_Lambda.md`
- HLD: `../../../HLDs/2.1_BBWS_Customer_Portal_Public_HLD_V1.1.md`

## License

Copyright 2025 BBWS Multi-Tenant Platform
