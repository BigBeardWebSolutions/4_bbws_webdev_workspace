# OrderPDFCreator Lambda Function

**Worker 6** - Stage 2: Lambda Implementation

## Overview

The OrderPDFCreator Lambda function is an SQS-triggered event processor that generates professional PDF invoices for customer orders and uploads them to S3.

### Purpose

- **Trigger**: SQS queue (`bbws-order-creation-{env}`)
- **Target**: S3 bucket (`bbws-orders-{env}`)
- **Function**: Generate PDF invoices using ReportLab and upload to S3
- **Timeout**: 60s (longer than other Lambdas due to PDF generation)

## Architecture

### Event-Driven Flow

```
SQS Queue → OrderPDFCreator Lambda → [DynamoDB, S3] → Update Order
```

1. Receive SQS message with order creation event
2. Fetch order details from DynamoDB
3. Generate PDF invoice using ReportLab
4. Upload PDF to S3 with SSE-S3 encryption
5. Update order record with `pdfUrl` field

### Components

- **Handler**: `src/handlers/order_pdf_creator.py` - Lambda entry point
- **DAO**: `src/dao/order_dao.py` - DynamoDB operations
- **Services**:
  - `src/services/pdf_service.py` - PDF generation using ReportLab
  - `src/services/s3_service.py` - S3 upload operations
- **Models**: `src/models/` - Pydantic v1.10.18 data models

## Features

### PDF Invoice Contents

- Company branding and name
- Order information (number, date, status, ID)
- Customer details (name, email, billing address)
- Itemized line items table with:
  - Product name, SKU, quantity
  - Unit price, subtotal, tax, total per item
- Financial totals:
  - Subtotal
  - Discount (if applicable)
  - Tax
  - Shipping (if applicable)
  - Grand total
- Payment information (if available)
- Professional formatting with ReportLab

### S3 Upload Configuration

- **Bucket**: `bbws-orders-{env}`
- **Key Format**: `{tenantId}/orders/order_{orderId}.pdf`
- **Content Type**: `application/pdf`
- **Encryption**: SSE-S3 (AES256)
- **Metadata**:
  - `tenant-id`: Tenant identifier
  - `order-id`: Order identifier
  - `document-type`: "invoice"

### Idempotency

The function implements idempotency checks:
- If order already has `pdfUrl`, check if file exists in S3
- Skip regeneration if PDF already exists
- Regenerate if URL exists but file is missing

## Installation

### Prerequisites

- Python 3.12
- pip
- Docker (for packaging)

### Local Development Setup

```bash
# Create virtual environment
python3.12 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Install development dependencies
pip install -e ".[dev]"
```

## Testing

### Run Unit Tests

```bash
# Run all tests with coverage
pytest

# Run only unit tests
pytest tests/unit/

# Run with verbose output
pytest -v

# Generate coverage report
pytest --cov=src --cov-report=html
open htmlcov/index.html
```

### Run Integration Tests

```bash
# Run integration tests (requires moto)
pytest tests/integration/ -m integration

# Run all tests including integration
pytest tests/
```

### Test Coverage Requirements

- **Minimum Coverage**: 80%
- **Target Coverage**: 90%+
- **Critical Paths**: 100% coverage required

### Current Coverage

Run `pytest --cov=src --cov-report=term-missing` to see current coverage.

## Environment Variables

The Lambda function requires the following environment variables:

| Variable | Description | Example | Required |
|----------|-------------|---------|----------|
| `DYNAMODB_TABLE_NAME` | DynamoDB orders table | `bbws-customer-portal-orders-dev` | Yes |
| `S3_ORDERS_BUCKET` | S3 bucket for PDFs | `bbws-orders-dev` | Yes |
| `COMPANY_NAME` | Company name for invoice | `BBWS` | No (default: BBWS) |
| `LOG_LEVEL` | Logging level | `INFO` | No (default: INFO) |
| `AWS_REGION` | AWS region | `af-south-1` | Yes (auto-set) |

## Docker Packaging

### Build Docker Image

```bash
# Build Lambda container image
docker build -t order-pdf-creator:latest .

# Test locally (requires AWS credentials)
docker run --rm \
  -e DYNAMODB_TABLE_NAME=test-table \
  -e S3_ORDERS_BUCKET=test-bucket \
  -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
  -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
  -e AWS_REGION=af-south-1 \
  order-pdf-creator:latest
```

### Push to ECR (for deployment)

```bash
# Authenticate to ECR
aws ecr get-login-password --region af-south-1 | \
  docker login --username AWS --password-stdin {account}.dkr.ecr.af-south-1.amazonaws.com

# Tag image
docker tag order-pdf-creator:latest \
  {account}.dkr.ecr.af-south-1.amazonaws.com/order-pdf-creator:latest

# Push to ECR
docker push {account}.dkr.ecr.af-south-1.amazonaws.com/order-pdf-creator:latest
```

## Deployment

Deployment is handled via Terraform in Stage 3. The Lambda function will be configured with:

- **Runtime**: Python 3.12
- **Architecture**: arm64
- **Memory**: 512 MB
- **Timeout**: 60 seconds
- **Concurrency**: 10 concurrent executions (batch processing)
- **Trigger**: SQS queue with batch size 10
- **IAM Permissions**:
  - DynamoDB: GetItem, PutItem
  - S3: PutObject, HeadObject
  - SQS: ReceiveMessage, DeleteMessage
  - CloudWatch Logs: CreateLogGroup, CreateLogStream, PutLogEvents

## Error Handling

### Retry Strategy

The function implements partial batch failure handling:

1. **Successful messages**: Deleted from queue
2. **Failed messages**: Returned in `batchItemFailures` for retry
3. **Max retries**: 3 (configured in SQS)
4. **DLQ**: Failed messages after max retries sent to Dead Letter Queue

### Error Scenarios

| Error | Handling | Retry |
|-------|----------|-------|
| Order not found | Return failure, retry | Yes (eventual consistency) |
| PDF generation failure | Return failure, retry | Yes |
| S3 upload failure | Return failure, retry | Yes |
| DynamoDB update failure | Return failure, retry | Yes |
| Invalid message format | Log error, skip message | No |

## Monitoring

### CloudWatch Metrics

- Lambda invocations, errors, duration
- SQS queue depth, messages processed
- Custom metrics:
  - PDF generation time
  - S3 upload time
  - Order processing success/failure rate

### CloudWatch Logs

Structured logging with:
- Request ID
- Tenant ID
- Order ID
- Processing steps
- Error details

### Alarms

Recommended CloudWatch alarms:
- Lambda errors > 5% threshold
- Lambda duration > 55s (approaching timeout)
- DLQ message count > 0
- SQS queue age > 5 minutes

## Dependencies

### Production Dependencies

- `boto3==1.34.0` - AWS SDK
- `pydantic==1.10.18` - Data validation (arm64 compatible)
- `reportlab==4.0.7` - PDF generation
- `python-dateutil==2.8.2` - Date utilities
- `pytz==2023.3` - Timezone support

### Development Dependencies

- `pytest==7.4.3` - Testing framework
- `pytest-cov==4.1.0` - Coverage reporting
- `pytest-mock==3.12.0` - Mocking support
- `moto==4.2.9` - AWS service mocking
- `PyPDF2==3.0.1` - PDF validation in tests

## Project Structure

```
worker-6-order-pdf-creator-lambda/
├── src/
│   ├── handlers/
│   │   ├── __init__.py
│   │   └── order_pdf_creator.py       # Lambda handler
│   ├── models/
│   │   ├── __init__.py
│   │   ├── order.py                    # Order model
│   │   ├── order_item.py               # OrderItem model
│   │   ├── billing_address.py          # BillingAddress model
│   │   ├── campaign.py                 # Campaign model
│   │   └── payment_details.py          # PaymentDetails model
│   ├── dao/
│   │   ├── __init__.py
│   │   └── order_dao.py                # DynamoDB DAO
│   ├── services/
│   │   ├── __init__.py
│   │   ├── pdf_service.py              # PDF generation
│   │   └── s3_service.py               # S3 operations
│   └── utils/
│       └── __init__.py
├── tests/
│   ├── unit/
│   │   ├── test_models.py
│   │   ├── test_order_dao.py
│   │   ├── test_pdf_service.py
│   │   ├── test_s3_service.py
│   │   └── test_lambda_handler.py
│   ├── integration/
│   │   └── test_order_pdf_workflow.py
│   └── conftest.py                     # Shared fixtures
├── Dockerfile                          # Lambda packaging
├── requirements.txt                    # Dependencies
├── pytest.ini                          # Test configuration
├── pyproject.toml                      # Project metadata
├── .dockerignore                       # Docker exclusions
├── .gitignore                          # Git exclusions
├── README.md                           # This file
└── output.md                           # Implementation summary
```

## Code Quality Standards

- **PEP 8**: Python style guide compliance
- **Type Hints**: All public functions have type annotations
- **Docstrings**: Google-style docstrings for all classes and functions
- **Test Coverage**: Minimum 80% code coverage
- **Linting**: Pass flake8 checks
- **Formatting**: Black code formatter (line length 120)

## Performance Considerations

### PDF Generation

- Average generation time: 2-5 seconds per invoice
- Memory usage: ~100-200 MB per PDF
- Concurrent executions: 10 max (to manage S3 upload rate)

### Optimization Tips

- ReportLab is efficient for standard invoices
- Consider caching company logo if fetched from S3
- Use connection pooling for DynamoDB and S3 clients
- Monitor Lambda memory usage and adjust if needed

## Security

### Data Protection

- PDF files encrypted at rest (SSE-S3)
- DynamoDB encryption enabled
- No PII logged to CloudWatch
- IAM roles follow least privilege principle

### Access Control

- S3 bucket blocks all public access
- Tenant isolation enforced via S3 key prefix
- Order access validated via tenant ID

## Troubleshooting

### Common Issues

1. **PDF generation timeout**
   - Check Lambda timeout setting (should be 60s)
   - Review order complexity (number of items)
   - Check ReportLab logs for errors

2. **S3 upload failures**
   - Verify IAM permissions
   - Check S3 bucket exists and is accessible
   - Review S3 bucket policies

3. **Order not found**
   - Check DynamoDB table name
   - Verify tenant ID and order ID format
   - Check for eventual consistency delays

4. **ImportError for pydantic**
   - Ensure using Pydantic v1.10.18 (not v2)
   - Verify Docker build includes correct version

## References

- [Stage 2 Plan](../plan.md)
- [LLD 2.1.8 Order Lambda](../../../2.1.8_LLD_Order_Lambda.md)
- [ReportLab Documentation](https://www.reportlab.com/docs/reportlab-userguide.pdf)
- [AWS Lambda Python](https://docs.aws.amazon.com/lambda/latest/dg/lambda-python.html)

## Support

For issues or questions:
- Review the Stage 2 plan and LLD documents
- Check CloudWatch logs for detailed error messages
- Verify environment variables are correctly set
- Test locally using mocked AWS services

## License

Internal BBWS project. All rights reserved.
