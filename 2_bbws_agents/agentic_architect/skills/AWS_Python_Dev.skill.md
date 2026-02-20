# AWS Python Development Skill

**Version**: 1.0
**Created**: 2025-12-17
**Type**: Language-Specific AWS Patterns
**Purpose**: Python-specific patterns for AWS Lambda, boto3, and serverless development

---

## Purpose

Provide Python-specific best practices for AWS serverless development including Lambda Powertools, boto3 optimization, cold start mitigation, and production patterns.

---

## Research Summary

### Research Questions
- What are boto3 best practices for Lambda?
- How to minimize cold starts in Python Lambda?
- What does Powertools provide and when to use it?
- What are 2025 SnapStart capabilities for Python?

### Key Findings
- Move boto3 clients to global scope for connection reuse
- Powertools provides structured logging, tracing, metrics, idempotency
- 2025 SnapStart for Python enables sub-100ms cold starts
- Lambda Layers with pre-optimized dependencies reduce package size

### Sources
- [Powertools for AWS Lambda (Python) - AWS](https://docs.powertools.aws.dev/lambda/python/)
- [Performance Optimization - Powertools](https://docs.aws.amazon.com/powertools/python/latest/build_recipes/performance-optimization/)
- [Python Lambda Functions - Capital One Tech](https://www.capitalone.com/tech/software-engineering/python-lambda-functions/)
- [AWS Lambda Cold Start Optimization - Refactix](https://refactix.com/cloud-infrastructure-devops/aws-lambda-cold-start-optimization-sub-100ms)
- [SnapStart 2025 Guide - Medium](https://medium.com/@naeemulhaq/conquering-cold-starts-a-2025-tune-up-guide-for-lambda-snapstart-with-python-and-net-8a004c3a6a76)

---

## Project Structure

### Recommended Layout
```
lambda-function/
├── src/
│   ├── __init__.py
│   ├── handler.py           # Lambda entry point
│   ├── domain/              # Business logic (DDD)
│   │   ├── entities/
│   │   ├── services/
│   │   └── repositories/
│   ├── infrastructure/      # AWS integrations
│   │   ├── dynamodb.py
│   │   ├── s3.py
│   │   └── secrets.py
│   └── utils/
│       └── config.py
├── tests/
│   ├── unit/
│   ├── integration/
│   └── conftest.py
├── requirements.txt
├── requirements-dev.txt
├── template.yaml            # SAM template
└── Makefile
```

---

## Cold Start Optimization

### Global Scope Pattern

**Critical**: Initialize boto3 clients outside handler.

```python
import boto3
from aws_lambda_powertools import Logger, Tracer

# GLOBAL SCOPE - initialized once per container
logger = Logger()
tracer = Tracer()

# Create clients at global scope
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['TABLE_NAME'])

# Optional: Reuse session for multiple clients
session = boto3.Session()
s3_client = session.client('s3')
secrets_client = session.client('secretsmanager')


@logger.inject_lambda_context
@tracer.capture_lambda_handler
def handler(event, context):
    # Use pre-initialized clients
    response = table.get_item(Key={'pk': event['id']})
    return response['Item']
```

### Lazy Loading Pattern

**When to use**: For clients not always needed.

```python
import boto3
from functools import lru_cache

@lru_cache(maxsize=1)
def get_bedrock_client():
    """Lazy-load expensive Bedrock client"""
    return boto3.client('bedrock-runtime')

def handler(event, context):
    if event.get('use_ai'):
        client = get_bedrock_client()  # Created only if needed
        # Use client
```

### 2025 Performance Benchmarks
- Baseline cold start: ~180ms (Python 3.12+)
- With SnapStart: sub-100ms achievable
- VPC overhead: +20-50ms (down from 10-15s in 2019)
- Optimized packages: 70-90% faster first-request

---

## Powertools Integration

### Core Features

| Feature | Purpose | Import |
|---------|---------|--------|
| Logger | Structured JSON logging | `from aws_lambda_powertools import Logger` |
| Tracer | X-Ray tracing with annotations | `from aws_lambda_powertools import Tracer` |
| Metrics | CloudWatch EMF metrics | `from aws_lambda_powertools import Metrics` |
| Parameters | SSM/Secrets caching | `from aws_lambda_powertools.utilities import parameters` |
| Idempotency | Prevent duplicate processing | `from aws_lambda_powertools.utilities.idempotency` |
| Validation | JSON Schema validation | `from aws_lambda_powertools.utilities.validation` |
| Batch | SQS/Kinesis batch processing | `from aws_lambda_powertools.utilities.batch` |

### Complete Handler Example

```python
import os
from aws_lambda_powertools import Logger, Tracer, Metrics
from aws_lambda_powertools.metrics import MetricUnit
from aws_lambda_powertools.utilities.typing import LambdaContext
from aws_lambda_powertools.utilities.validation import validator

logger = Logger(service="order-service")
tracer = Tracer(service="order-service")
metrics = Metrics(service="order-service", namespace="OrderApp")


@logger.inject_lambda_context(log_event=True)
@tracer.capture_lambda_handler
@metrics.log_metrics(capture_cold_start_metric=True)
def handler(event: dict, context: LambdaContext) -> dict:
    """Process order creation request."""

    # Add custom metrics
    metrics.add_metric(name="OrdersProcessed", unit=MetricUnit.Count, value=1)

    # Add trace annotation for filtering
    tracer.put_annotation(key="OrderId", value=event.get('order_id'))

    try:
        result = process_order(event)
        logger.info("Order processed successfully", order_id=event.get('order_id'))
        return {"statusCode": 200, "body": result}

    except ValidationError as e:
        logger.warning("Validation failed", error=str(e))
        metrics.add_metric(name="ValidationErrors", unit=MetricUnit.Count, value=1)
        return {"statusCode": 400, "body": str(e)}

    except Exception as e:
        logger.exception("Unexpected error")
        metrics.add_metric(name="Errors", unit=MetricUnit.Count, value=1)
        raise
```

### Idempotency Pattern

```python
from aws_lambda_powertools.utilities.idempotency import (
    DynamoDBPersistenceLayer,
    idempotent_function,
    IdempotencyConfig
)

persistence = DynamoDBPersistenceLayer(table_name="IdempotencyTable")
config = IdempotencyConfig(expires_after_seconds=3600)

@idempotent_function(
    data_keyword_argument="order",
    persistence_store=persistence,
    config=config
)
def process_order(order: dict) -> dict:
    """Process order exactly once."""
    # Business logic here
    return {"status": "processed", "order_id": order['id']}
```

---

## SnapStart for Python (2025)

### Enabling SnapStart

```yaml
# template.yaml (SAM)
Resources:
  MyFunction:
    Type: AWS::Serverless::Function
    Properties:
      Runtime: python3.12
      SnapStart:
        ApplyOn: PublishedVersions
      AutoPublishAlias: live
```

### Runtime Hooks

```python
from aws_lambda_powertools.utilities.snapstart import (
    before_checkpoint,
    after_restore
)

# Pre-warm before snapshot
@before_checkpoint
def warm_up():
    """Run before SnapStart snapshot."""
    # Pre-load configuration
    load_config()
    # Prime database connections
    prime_dynamodb_connection()

# Refresh after restore
@after_restore
def refresh():
    """Run after SnapStart restore."""
    # Refresh credentials
    refresh_secrets()
    # Re-establish connections if needed
```

### SnapStart Best Practices
1. Move heavy initialization to global scope
2. Use hooks for credential refresh
3. Avoid random/unique values in init phase
4. Test snapshot restoration behavior

---

## Testing Patterns

### Unit Testing with Moto

```python
import pytest
import boto3
from moto import mock_dynamodb
from src.handler import handler


@pytest.fixture
def dynamodb_table():
    """Create mock DynamoDB table."""
    with mock_dynamodb():
        dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
        table = dynamodb.create_table(
            TableName='TestTable',
            KeySchema=[{'AttributeName': 'pk', 'KeyType': 'HASH'}],
            AttributeDefinitions=[{'AttributeName': 'pk', 'AttributeType': 'S'}],
            BillingMode='PAY_PER_REQUEST'
        )
        yield table


def test_handler_success(dynamodb_table, monkeypatch):
    """Test successful handler execution."""
    monkeypatch.setenv('TABLE_NAME', 'TestTable')

    # Seed test data
    dynamodb_table.put_item(Item={'pk': 'test-123', 'name': 'Test'})

    event = {'id': 'test-123'}
    result = handler(event, None)

    assert result['statusCode'] == 200
```

### Integration Testing

```python
import pytest
from testcontainers.localstack import LocalStackContainer


@pytest.fixture(scope="session")
def localstack():
    """Start LocalStack for integration tests."""
    with LocalStackContainer(image="localstack/localstack:3.0") as container:
        container.with_services("dynamodb", "s3", "secretsmanager")
        yield container


def test_full_workflow(localstack):
    """Test complete order workflow."""
    # Test against LocalStack services
    pass
```

---

## Error Handling

### Structured Error Response

```python
from dataclasses import dataclass
from typing import Optional
import json


@dataclass
class APIError(Exception):
    status_code: int
    error_code: str
    message: str
    details: Optional[dict] = None

    def to_response(self) -> dict:
        body = {
            "error": {
                "code": self.error_code,
                "message": self.message
            }
        }
        if self.details:
            body["error"]["details"] = self.details

        return {
            "statusCode": self.status_code,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps(body)
        }


class ValidationError(APIError):
    def __init__(self, message: str, details: dict = None):
        super().__init__(400, "VALIDATION_ERROR", message, details)


class NotFoundError(APIError):
    def __init__(self, resource: str, identifier: str):
        super().__init__(404, "NOT_FOUND", f"{resource} not found: {identifier}")
```

---

## Dependencies & Layers

### requirements.txt (Production)

```
aws-lambda-powertools[all]>=2.0.0
boto3>=1.34.0
pydantic>=2.0.0
```

### Lambda Layer Usage

```yaml
# template.yaml
Globals:
  Function:
    Layers:
      - !Sub arn:aws:lambda:${AWS::Region}:017000801446:layer:AWSLambdaPowertoolsPythonV2:79

Resources:
  MyFunction:
    Type: AWS::Serverless::Function
    Properties:
      Handler: src.handler.handler
      Runtime: python3.12
      # No need to include powertools in deployment package
```

---

## Security Patterns

### Secrets Management

```python
from aws_lambda_powertools.utilities import parameters

# Cache secrets (default 5 seconds)
@parameters.get_secret_value(name="/prod/db/credentials", transform="json")
def get_db_credentials():
    pass

# Or with explicit caching
db_password = parameters.get_secret(
    "/prod/db/password",
    max_age=300  # Cache for 5 minutes
)
```

### Input Validation

```python
from aws_lambda_powertools.utilities.validation import validator

INPUT_SCHEMA = {
    "$schema": "http://json-schema.org/draft-07/schema#",
    "type": "object",
    "required": ["order_id", "items"],
    "properties": {
        "order_id": {"type": "string", "pattern": "^ORD-[0-9]+$"},
        "items": {
            "type": "array",
            "minItems": 1,
            "items": {"type": "object"}
        }
    }
}

@validator(inbound_schema=INPUT_SCHEMA)
def handler(event, context):
    # Event is validated before reaching here
    pass
```

---

## Version History

- **v1.0** (2025-12-17): Initial skill with embedded research on AWS Lambda Python patterns
