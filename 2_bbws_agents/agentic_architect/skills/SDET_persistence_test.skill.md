# SDET Persistence Test Skill

**Version**: 1.0
**Created**: 2026-01-01
**Type**: Test Automation
**Marker**: `@pytest.mark.persistence`

---

## Purpose

Write tests for the repository/persistence layer against DynamoDB Local. Tests CRUD operations, queries, and index behavior.

---

## When to Use

- Testing repository classes
- Validating DynamoDB access patterns
- Testing GSI and LSI queries
- Testing transaction operations
- Validating single-table design

---

## DynamoDB Local Setup

### Docker
```bash
docker run -d -p 8000:8000 amazon/dynamodb-local
```

### docker-compose.yml
```yaml
version: '3.8'
services:
  dynamodb-local:
    image: amazon/dynamodb-local:latest
    ports:
      - "8000:8000"
    command: "-jar DynamoDBLocal.jar -sharedDb -dbPath /data"
    volumes:
      - "./dynamodb-data:/data"
```

---

## Pattern: Repository CRUD Test

```python
import pytest
import boto3

@pytest.mark.persistence
def test_organisation_repository_create(dynamodb_local):
    # Arrange
    from lambdas.common.repositories import OrganisationRepository
    from lambdas.common.models import Organisation

    repo = OrganisationRepository(dynamodb_local)

    org = Organisation(
        name="Test Organisation",
        email="admin@test.org",
        plan="enterprise"
    )

    # Act
    result = repo.save(org)

    # Assert
    assert result is not None
    assert result.id is not None
    assert result.name == "Test Organisation"


@pytest.mark.persistence
def test_organisation_repository_get(dynamodb_local):
    # Arrange
    from lambdas.common.repositories import OrganisationRepository

    repo = OrganisationRepository(dynamodb_local)

    # Seed data
    dynamodb_local.put_item(Item={
        'PK': 'ORG#org-123',
        'SK': 'METADATA',
        'name': 'Test Org',
        'email': 'admin@test.org',
        'GSI1PK': 'ORGS',
        'GSI1SK': 'ORG#org-123'
    })

    # Act
    org = repo.get('org-123')

    # Assert
    assert org is not None
    assert org['name'] == 'Test Org'


@pytest.mark.persistence
def test_organisation_repository_update(dynamodb_local):
    # Arrange
    from lambdas.common.repositories import OrganisationRepository

    repo = OrganisationRepository(dynamodb_local)

    # Seed data
    dynamodb_local.put_item(Item={
        'PK': 'ORG#org-123',
        'SK': 'METADATA',
        'name': 'Old Name',
        'email': 'admin@test.org'
    })

    # Act
    result = repo.update('org-123', {'name': 'New Name'})

    # Assert
    assert result['name'] == 'New Name'

    # Verify in table
    item = dynamodb_local.get_item(Key={'PK': 'ORG#org-123', 'SK': 'METADATA'})
    assert item['Item']['name'] == 'New Name'


@pytest.mark.persistence
def test_organisation_repository_delete(dynamodb_local):
    # Arrange
    from lambdas.common.repositories import OrganisationRepository

    repo = OrganisationRepository(dynamodb_local)

    # Seed data
    dynamodb_local.put_item(Item={
        'PK': 'ORG#org-123',
        'SK': 'METADATA',
        'name': 'To Delete'
    })

    # Act
    repo.delete('org-123')

    # Assert
    item = dynamodb_local.get_item(Key={'PK': 'ORG#org-123', 'SK': 'METADATA'})
    assert 'Item' not in item
```

---

## Pattern: Query Tests

```python
import pytest

@pytest.mark.persistence
def test_list_organisations_by_plan(dynamodb_local):
    # Arrange
    from lambdas.common.repositories import OrganisationRepository

    repo = OrganisationRepository(dynamodb_local)

    # Seed multiple orgs
    for i in range(5):
        dynamodb_local.put_item(Item={
            'PK': f'ORG#org-{i}',
            'SK': 'METADATA',
            'name': f'Org {i}',
            'plan': 'enterprise' if i % 2 == 0 else 'starter',
            'GSI1PK': 'PLAN#enterprise' if i % 2 == 0 else 'PLAN#starter',
            'GSI1SK': f'ORG#org-{i}'
        })

    # Act
    enterprise_orgs = repo.list_by_plan('enterprise')

    # Assert
    assert len(enterprise_orgs) == 3  # org-0, org-2, org-4


@pytest.mark.persistence
def test_list_users_in_organisation(dynamodb_local):
    # Arrange
    from lambdas.common.repositories import UserRepository

    repo = UserRepository(dynamodb_local)

    # Seed org with users
    dynamodb_local.put_item(Item={
        'PK': 'ORG#org-123',
        'SK': 'USER#user-1',
        'name': 'User One',
        'email': 'user1@test.org'
    })
    dynamodb_local.put_item(Item={
        'PK': 'ORG#org-123',
        'SK': 'USER#user-2',
        'name': 'User Two',
        'email': 'user2@test.org'
    })

    # Act
    users = repo.list_by_organisation('org-123')

    # Assert
    assert len(users) == 2
```

---

## Fixtures

```python
# conftest.py
import pytest
import boto3
import os

@pytest.fixture(scope="session")
def dynamodb_local_endpoint():
    """Return DynamoDB Local endpoint."""
    return os.getenv('DYNAMODB_LOCAL_ENDPOINT', 'http://localhost:8000')

@pytest.fixture(scope="function")
def dynamodb_local(dynamodb_local_endpoint):
    """Create test table in DynamoDB Local."""
    dynamodb = boto3.resource(
        'dynamodb',
        endpoint_url=dynamodb_local_endpoint,
        region_name='af-south-1',
        aws_access_key_id='testing',
        aws_secret_access_key='testing'
    )

    # Create table with GSI
    table = dynamodb.create_table(
        TableName='bbws-test-main',
        KeySchema=[
            {'AttributeName': 'PK', 'KeyType': 'HASH'},
            {'AttributeName': 'SK', 'KeyType': 'RANGE'}
        ],
        AttributeDefinitions=[
            {'AttributeName': 'PK', 'AttributeType': 'S'},
            {'AttributeName': 'SK', 'AttributeType': 'S'},
            {'AttributeName': 'GSI1PK', 'AttributeType': 'S'},
            {'AttributeName': 'GSI1SK', 'AttributeType': 'S'}
        ],
        GlobalSecondaryIndexes=[
            {
                'IndexName': 'GSI1',
                'KeySchema': [
                    {'AttributeName': 'GSI1PK', 'KeyType': 'HASH'},
                    {'AttributeName': 'GSI1SK', 'KeyType': 'RANGE'}
                ],
                'Projection': {'ProjectionType': 'ALL'}
            }
        ],
        BillingMode='PAY_PER_REQUEST'
    )
    table.wait_until_exists()

    yield table

    # Cleanup
    table.delete()
```

---

## Environment Variables

```bash
export DYNAMODB_LOCAL_ENDPOINT=http://localhost:8000
export AWS_ACCESS_KEY_ID=testing
export AWS_SECRET_ACCESS_KEY=testing
export AWS_DEFAULT_REGION=af-south-1
```

---

## Running Persistence Tests

```bash
# Start DynamoDB Local
docker run -d -p 8000:8000 amazon/dynamodb-local

# Run persistence tests
pytest -m persistence -v

# Run with custom endpoint
DYNAMODB_LOCAL_ENDPOINT=http://localhost:8000 pytest -m persistence -v

# Run specific repository tests
pytest -m persistence -k "organisation" -v
```

---

## Best Practices

| Practice | Description |
|----------|-------------|
| Fresh table | Create new table per test |
| Cleanup | Delete table after test |
| Realistic schema | Use production-like indexes |
| Edge cases | Test empty results, not found |
| Transactions | Test batch operations |

---

## Version History

- **v1.0** (2026-01-01): Initial definition
