# SDET Mock Test Skill

**Version**: 1.0
**Created**: 2026-01-01
**Type**: Test Automation
**Marker**: `@pytest.mark.mock`

---

## Purpose

Write tests using moto to mock AWS services. Tests Lambda handlers and AWS SDK calls without requiring real AWS resources.

---

## When to Use

- Testing Lambda handlers end-to-end
- Testing code that calls DynamoDB, SQS, S3
- Testing API Gateway event handling
- Testing error scenarios with AWS services
- Testing retries and error handling

---

## moto Decorators

| Decorator | AWS Service |
|-----------|-------------|
| `@mock_aws` | All AWS services |
| `@mock_dynamodb` | DynamoDB only |
| `@mock_sqs` | SQS only |
| `@mock_s3` | S3 only |
| `@mock_lambda` | Lambda only |

---

## Pattern: Lambda Handler Test

```python
import pytest
import boto3
from moto import mock_aws

@pytest.mark.mock
@mock_aws
def test_create_organisation_handler():
    # Arrange - Setup mocked DynamoDB
    dynamodb = boto3.resource('dynamodb', region_name='af-south-1')
    table = dynamodb.create_table(
        TableName='bbws-dev-main',
        KeySchema=[
            {'AttributeName': 'PK', 'KeyType': 'HASH'},
            {'AttributeName': 'SK', 'KeyType': 'RANGE'}
        ],
        AttributeDefinitions=[
            {'AttributeName': 'PK', 'AttributeType': 'S'},
            {'AttributeName': 'SK', 'AttributeType': 'S'}
        ],
        BillingMode='PAY_PER_REQUEST'
    )

    event = {
        'body': '{"name": "Test Org", "email": "admin@test.org"}',
        'httpMethod': 'POST',
        'path': '/organisations'
    }
    context = {}

    # Act
    from lambdas.create_organisation.handler import handler
    response = handler(event, context)

    # Assert
    assert response['statusCode'] == 201
    body = json.loads(response['body'])
    assert 'organisation_id' in body
```

---

## Pattern: SQS Integration

```python
import pytest
import boto3
import json
from moto import mock_aws

@pytest.mark.mock
@mock_aws
def test_send_notification_to_sqs():
    # Arrange - Setup mocked SQS
    sqs = boto3.client('sqs', region_name='af-south-1')
    queue = sqs.create_queue(QueueName='bbws-dev-notifications')
    queue_url = queue['QueueUrl']

    # Act
    from lambdas.notifications.sender import send_notification
    send_notification(
        queue_url=queue_url,
        message={'type': 'org_created', 'org_id': 'org-123'}
    )

    # Assert
    messages = sqs.receive_message(QueueUrl=queue_url)
    assert len(messages['Messages']) == 1
    body = json.loads(messages['Messages'][0]['Body'])
    assert body['type'] == 'org_created'
```

---

## Pattern: DynamoDB CRUD

```python
import pytest
import boto3
from moto import mock_dynamodb

@pytest.mark.mock
@mock_dynamodb
def test_organisation_repository_get():
    # Arrange
    dynamodb = boto3.resource('dynamodb', region_name='af-south-1')
    table = dynamodb.create_table(
        TableName='bbws-dev-main',
        KeySchema=[
            {'AttributeName': 'PK', 'KeyType': 'HASH'},
            {'AttributeName': 'SK', 'KeyType': 'RANGE'}
        ],
        AttributeDefinitions=[
            {'AttributeName': 'PK', 'AttributeType': 'S'},
            {'AttributeName': 'SK', 'AttributeType': 'S'}
        ],
        BillingMode='PAY_PER_REQUEST'
    )

    # Seed test data
    table.put_item(Item={
        'PK': 'ORG#org-123',
        'SK': 'METADATA',
        'name': 'Test Org',
        'email': 'admin@test.org'
    })

    # Act
    from lambdas.common.repositories import OrganisationRepository
    repo = OrganisationRepository(table)
    org = repo.get('org-123')

    # Assert
    assert org is not None
    assert org['name'] == 'Test Org'
```

---

## Fixtures

```python
# conftest.py
import pytest
import boto3
from moto import mock_aws

@pytest.fixture
def aws_credentials():
    """Mocked AWS Credentials for moto."""
    import os
    os.environ['AWS_ACCESS_KEY_ID'] = 'testing'
    os.environ['AWS_SECRET_ACCESS_KEY'] = 'testing'
    os.environ['AWS_SECURITY_TOKEN'] = 'testing'
    os.environ['AWS_SESSION_TOKEN'] = 'testing'
    os.environ['AWS_DEFAULT_REGION'] = 'af-south-1'

@pytest.fixture
def dynamodb_table(aws_credentials):
    """Create mocked DynamoDB table."""
    with mock_aws():
        dynamodb = boto3.resource('dynamodb', region_name='af-south-1')
        table = dynamodb.create_table(
            TableName='bbws-dev-main',
            KeySchema=[
                {'AttributeName': 'PK', 'KeyType': 'HASH'},
                {'AttributeName': 'SK', 'KeyType': 'RANGE'}
            ],
            AttributeDefinitions=[
                {'AttributeName': 'PK', 'AttributeType': 'S'},
                {'AttributeName': 'SK', 'AttributeType': 'S'}
            ],
            BillingMode='PAY_PER_REQUEST'
        )
        yield table

@pytest.fixture
def sqs_queue(aws_credentials):
    """Create mocked SQS queue."""
    with mock_aws():
        sqs = boto3.client('sqs', region_name='af-south-1')
        queue = sqs.create_queue(QueueName='bbws-dev-notifications')
        yield queue['QueueUrl']
```

---

## Running Mock Tests

```bash
# Run all mock tests
pytest -m mock -v

# Run with coverage
pytest -m mock --cov=lambdas --cov-report=term-missing

# Run specific handler tests
pytest -m mock -k "handler" -v
```

---

## Best Practices

| Practice | Description |
|----------|-------------|
| Use fixtures | Reusable AWS resource setup |
| Region consistency | Always use `af-south-1` |
| Clean state | Each test starts fresh |
| Realistic data | Use production-like structures |
| Error scenarios | Test AWS exceptions |

---

## Version History

- **v1.0** (2026-01-01): Initial definition
