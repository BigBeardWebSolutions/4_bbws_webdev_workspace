# SDET Integration Test Skill

**Version**: 2.0
**Created**: 2026-01-01
**Updated**: 2026-01-01
**Type**: Test Automation
**Markers**: `@pytest.mark.integration`, `@pytest.mark.e2e`

---

## Purpose

Write tests against LocalStack, JIT-provisioned AWS environments, or deployed API endpoints. Tests real service interactions with actual AWS APIs and validates deployed infrastructure.

---

## When to Use

- Testing multi-service workflows
- Validating AWS resource configurations
- Testing event-driven architectures (SQS triggers)
- Pre-deployment validation
- Testing infrastructure as code
- **E2E API testing against deployed environments (DEV/SIT/PROD)**

---

## Environment Options

| Environment | Use Case | Speed | Write Operations |
|-------------|----------|-------|------------------|
| LocalStack | Local development | Fast | Allowed |
| JIT AWS | CI/CD pipelines | Medium | Allowed |
| DEV AWS | Development testing | Medium | Allowed |
| SIT AWS | Pre-production validation | Medium | Allowed |
| PROD AWS | Production smoke tests | Slow | **Read-only** |

---

## LocalStack Setup

### docker-compose.yml
```yaml
version: '3.8'
services:
  localstack:
    image: localstack/localstack:latest
    ports:
      - "4566:4566"
    environment:
      - SERVICES=dynamodb,sqs,s3,lambda
      - DEBUG=1
      - DATA_DIR=/tmp/localstack/data
    volumes:
      - "./localstack:/tmp/localstack"
```

### Start LocalStack
```bash
docker-compose up -d localstack
```

---

## Pattern: LocalStack Integration Test

```python
import pytest
import boto3

@pytest.mark.integration
def test_organisation_workflow_e2e(localstack_endpoint):
    # Arrange - Use LocalStack endpoint
    dynamodb = boto3.resource(
        'dynamodb',
        endpoint_url=localstack_endpoint,
        region_name='af-south-1'
    )

    sqs = boto3.client(
        'sqs',
        endpoint_url=localstack_endpoint,
        region_name='af-south-1'
    )

    # Create resources
    table = dynamodb.create_table(
        TableName='bbws-integration-main',
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
    table.wait_until_exists()

    queue = sqs.create_queue(QueueName='bbws-integration-notifications')
    queue_url = queue['QueueUrl']

    # Act - Create organisation
    from lambdas.create_organisation.handler import handler

    event = {
        'body': '{"name": "Integration Test Org"}',
        'httpMethod': 'POST'
    }
    response = handler(event, {})

    # Assert - Verify in DynamoDB
    assert response['statusCode'] == 201

    # Verify notification sent
    messages = sqs.receive_message(QueueUrl=queue_url, WaitTimeSeconds=5)
    assert 'Messages' in messages
```

---

## Pattern: JIT AWS Environment

```python
import pytest
import boto3
import os

@pytest.mark.integration
@pytest.mark.skipif(
    os.getenv('AWS_INTEGRATION_TEST') != 'true',
    reason="JIT AWS environment not provisioned"
)
def test_lambda_invocation_jit():
    # Arrange - Use real AWS (JIT provisioned by DevOps)
    lambda_client = boto3.client('lambda', region_name='af-south-1')

    # Act
    response = lambda_client.invoke(
        FunctionName='bbws-dev-create-organisation',
        Payload=json.dumps({
            'body': '{"name": "JIT Test Org"}'
        })
    )

    # Assert
    payload = json.loads(response['Payload'].read())
    assert payload['statusCode'] == 201
```

---

## Fixtures

```python
# conftest.py
import pytest
import os

@pytest.fixture(scope="session")
def localstack_endpoint():
    """Return LocalStack endpoint URL."""
    return os.getenv('LOCALSTACK_ENDPOINT', 'http://localhost:4566')

@pytest.fixture(scope="function")
def localstack_dynamodb(localstack_endpoint):
    """Create DynamoDB table in LocalStack."""
    import boto3

    dynamodb = boto3.resource(
        'dynamodb',
        endpoint_url=localstack_endpoint,
        region_name='af-south-1',
        aws_access_key_id='testing',
        aws_secret_access_key='testing'
    )

    table = dynamodb.create_table(
        TableName='bbws-integration-main',
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
    table.wait_until_exists()

    yield table

    # Cleanup
    table.delete()

@pytest.fixture(scope="function")
def localstack_sqs(localstack_endpoint):
    """Create SQS queue in LocalStack."""
    import boto3

    sqs = boto3.client(
        'sqs',
        endpoint_url=localstack_endpoint,
        region_name='af-south-1',
        aws_access_key_id='testing',
        aws_secret_access_key='testing'
    )

    queue = sqs.create_queue(QueueName='bbws-integration-notifications')
    queue_url = queue['QueueUrl']

    yield queue_url

    # Cleanup
    sqs.delete_queue(QueueUrl=queue_url)
```

---

## Environment Variables

```bash
# LocalStack
export LOCALSTACK_ENDPOINT=http://localhost:4566
export AWS_ACCESS_KEY_ID=testing
export AWS_SECRET_ACCESS_KEY=testing
export AWS_DEFAULT_REGION=af-south-1

# JIT AWS
export AWS_INTEGRATION_TEST=true
export AWS_PROFILE=bbws-dev
```

---

## Running Integration Tests

```bash
# Start LocalStack first
docker-compose up -d localstack

# Run integration tests
pytest -m integration -v

# Run with LocalStack endpoint
LOCALSTACK_ENDPOINT=http://localhost:4566 pytest -m integration -v

# Run JIT AWS tests
AWS_INTEGRATION_TEST=true pytest -m integration -v
```

---

## Best Practices

| Practice | Description |
|----------|-------------|
| Cleanup | Always clean up resources after tests |
| Isolation | Use unique names per test run |
| Timeouts | Set appropriate wait times |
| Skip conditions | Skip if environment not ready |
| Idempotent | Tests can run multiple times |

---

# E2E API Testing (Deployed Environments)

## Overview

E2E tests validate deployed Lambda functions via API Gateway endpoints across DEV, SIT, and PROD environments.

---

## E2E Environment Configuration

### Base URLs

| Environment | Base URL | Write Operations |
|-------------|----------|------------------|
| DEV | `https://api.dev.kimmyai.io` | Allowed |
| SIT | `https://api.sit.kimmyai.io` | Allowed |
| PROD | `https://api.kimmyai.io` | **Read-only** |

### config.py

```python
"""
Environment configuration for E2E tests.

Usage:
    ENV=dev pytest tests/e2e/
    pytest tests/e2e/ --env=sit
"""

import os
from dataclasses import dataclass
from typing import Optional


@dataclass
class EnvironmentConfig:
    """Configuration for a specific environment."""

    name: str
    base_url: str
    api_version: str = "v1.0"
    timeout: int = 30
    is_read_only: bool = False

    @property
    def products_endpoint(self) -> str:
        """Full URL for products endpoint."""
        return f"{self.base_url}/{self.api_version}/products"


# Environment configurations
ENVIRONMENTS = {
    "dev": EnvironmentConfig(
        name="dev",
        base_url="https://api.dev.kimmyai.io",
        timeout=30,
        is_read_only=False,
    ),
    "sit": EnvironmentConfig(
        name="sit",
        base_url="https://api.sit.kimmyai.io",
        timeout=30,
        is_read_only=False,
    ),
    "prod": EnvironmentConfig(
        name="prod",
        base_url="https://api.kimmyai.io",
        timeout=30,
        is_read_only=True,  # PROD is read-only
    ),
}


def get_environment(env_name: Optional[str] = None) -> EnvironmentConfig:
    """Get environment configuration."""
    if env_name is None:
        env_name = os.getenv("ENV", "dev").lower()

    if env_name not in ENVIRONMENTS:
        raise ValueError(
            f"Unknown environment: {env_name}. "
            f"Valid options: {list(ENVIRONMENTS.keys())}"
        )

    return ENVIRONMENTS[env_name]
```

---

## E2E Test Structure

```
tests/e2e/
├── __init__.py
├── config.py                     # Environment configuration
├── conftest.py                   # Shared pytest fixtures
├── README.md                     # Documentation
├── list_products/
│   ├── __init__.py
│   └── test_list_products.py     # GET /v1.0/products
├── get_product/
│   ├── __init__.py
│   └── test_get_product.py       # GET /v1.0/products/{id}
├── create_product/
│   ├── __init__.py
│   └── test_create_product.py    # POST /v1.0/products
├── update_product/
│   ├── __init__.py
│   └── test_update_product.py    # PUT /v1.0/products/{id}
└── delete_product/
    ├── __init__.py
    └── test_delete_product.py    # DELETE /v1.0/products/{id}
```

---

## E2E Fixtures (conftest.py)

```python
"""Pytest fixtures for E2E tests."""

import pytest
import requests
import uuid
from typing import Generator, Dict, Any, List

from .config import get_environment, EnvironmentConfig


def pytest_addoption(parser):
    """Add custom CLI options for pytest."""
    parser.addoption(
        "--env",
        action="store",
        default="dev",
        choices=["dev", "sit", "prod"],
        help="Environment to run tests against: dev, sit, prod",
    )


@pytest.fixture(scope="session")
def env_name(request) -> str:
    """Get environment name from CLI option."""
    return request.config.getoption("--env")


@pytest.fixture(scope="session")
def env_config(env_name: str) -> EnvironmentConfig:
    """Get environment configuration."""
    return get_environment(env_name)


@pytest.fixture(scope="session")
def base_url(env_config: EnvironmentConfig) -> str:
    """Get base URL for the environment."""
    return env_config.base_url


@pytest.fixture(scope="session")
def products_url(env_config: EnvironmentConfig) -> str:
    """Get products endpoint URL."""
    return env_config.products_endpoint


@pytest.fixture(scope="session")
def api_timeout(env_config: EnvironmentConfig) -> int:
    """Get API timeout for requests."""
    return env_config.timeout


@pytest.fixture(scope="session")
def is_read_only(env_config: EnvironmentConfig) -> bool:
    """Check if environment is read-only."""
    return env_config.is_read_only


@pytest.fixture(scope="session")
def http_session() -> Generator[requests.Session, None, None]:
    """Create a requests session for API calls."""
    session = requests.Session()
    session.headers.update({
        "Content-Type": "application/json",
        "Accept": "application/json",
    })
    yield session
    session.close()


@pytest.fixture
def test_product_data() -> Dict[str, Any]:
    """Generate unique test product data."""
    unique_id = str(uuid.uuid4())[:8]
    return {
        "name": f"Test Product {unique_id}",
        "description": f"E2E test product created with ID {unique_id}",
        "price": "199.99",
        "currency": "ZAR",
        "period": "monthly",
        "features": ["Test Feature 1", "Test Feature 2"],
    }


@pytest.fixture
def created_products(
    http_session: requests.Session,
    products_url: str,
    api_timeout: int,
    is_read_only: bool,
) -> Generator[List[str], None, None]:
    """Track created products for cleanup."""
    product_ids: List[str] = []
    yield product_ids

    # Cleanup: Delete all created products
    if not is_read_only:
        for product_id in product_ids:
            try:
                http_session.delete(
                    f"{products_url}/{product_id}",
                    timeout=api_timeout,
                )
            except Exception:
                pass  # Best effort cleanup
```

---

## E2E Test Patterns

### Pattern: List Resources (GET)

```python
import pytest
import requests


class TestListProducts:
    """Test cases for GET /v1.0/products endpoint."""

    def test_list_products_success(
        self,
        http_session: requests.Session,
        products_url: str,
        api_timeout: int,
    ):
        """Test that list products returns 200 OK."""
        response = http_session.get(products_url, timeout=api_timeout)

        assert response.status_code == 200
        assert response.headers.get("Content-Type").startswith("application/json")

    def test_list_products_response_structure(
        self,
        http_session: requests.Session,
        products_url: str,
        api_timeout: int,
    ):
        """Test that response has correct structure."""
        response = http_session.get(products_url, timeout=api_timeout)

        assert response.status_code == 200
        data = response.json()
        assert "products" in data
        assert isinstance(data["products"], list)
```

### Pattern: Get Single Resource (GET)

```python
class TestGetProduct:
    """Test cases for GET /v1.0/products/{productId} endpoint."""

    def test_get_product_success(
        self,
        http_session: requests.Session,
        products_url: str,
        api_timeout: int,
    ):
        """Test getting an existing product by ID."""
        # First, list products to get a valid ID
        list_response = http_session.get(products_url, timeout=api_timeout)

        if list_response.status_code != 200:
            pytest.skip("Cannot list products to get test ID")

        products = list_response.json().get("products", [])
        if not products:
            pytest.skip("No products available to test")

        product_id = products[0]["productId"]

        # Get the product by ID
        response = http_session.get(
            f"{products_url}/{product_id}",
            timeout=api_timeout,
        )

        assert response.status_code == 200
        assert response.json()["productId"] == product_id

    def test_get_product_not_found(
        self,
        http_session: requests.Session,
        products_url: str,
        api_timeout: int,
    ):
        """Test getting a non-existent product returns 404."""
        response = http_session.get(
            f"{products_url}/PROD-NONEXISTENT-99999",
            timeout=api_timeout,
        )

        assert response.status_code == 404
```

### Pattern: Create Resource (POST) - With PROD Safety

```python
from typing import Dict, Any, List


class TestCreateProduct:
    """Test cases for POST /v1.0/products endpoint."""

    def test_create_product_success(
        self,
        http_session: requests.Session,
        products_url: str,
        api_timeout: int,
        test_product_data: Dict[str, Any],
        created_products: List[str],
        is_read_only: bool,
    ):
        """Test creating a new product successfully."""
        if is_read_only:
            pytest.skip("Write operations not allowed in this environment")

        response = http_session.post(
            products_url,
            json=test_product_data,
            timeout=api_timeout,
        )

        assert response.status_code == 201
        product = response.json()
        assert "productId" in product

        # Track for cleanup
        created_products.append(product["productId"])

    def test_create_product_missing_required_fields(
        self,
        http_session: requests.Session,
        products_url: str,
        api_timeout: int,
        is_read_only: bool,
    ):
        """Test that missing required fields return 400."""
        if is_read_only:
            pytest.skip("Write operations not allowed in this environment")

        incomplete_data = {
            "description": "Test description",
            "price": "99.99",
            "period": "monthly",
        }

        response = http_session.post(
            products_url,
            json=incomplete_data,
            timeout=api_timeout,
        )

        assert response.status_code == 400
```

### Pattern: Update Resource (PUT)

```python
class TestUpdateProduct:
    """Test cases for PUT /v1.0/products/{productId} endpoint."""

    def test_update_product_success(
        self,
        http_session: requests.Session,
        products_url: str,
        api_timeout: int,
        test_product_data: Dict[str, Any],
        created_products: List[str],
        is_read_only: bool,
    ):
        """Test updating an existing product."""
        if is_read_only:
            pytest.skip("Write operations not allowed in this environment")

        # Create product first
        create_response = http_session.post(
            products_url,
            json=test_product_data,
            timeout=api_timeout,
        )

        assert create_response.status_code == 201
        product_id = create_response.json()["productId"]
        created_products.append(product_id)

        # Update the product
        update_data = {"name": "Updated Product Name", "price": "399.99"}

        update_response = http_session.put(
            f"{products_url}/{product_id}",
            json=update_data,
            timeout=api_timeout,
        )

        assert update_response.status_code == 200
        assert update_response.json()["name"] == update_data["name"]

    def test_update_product_not_found(
        self,
        http_session: requests.Session,
        products_url: str,
        api_timeout: int,
        is_read_only: bool,
    ):
        """Test updating non-existent product returns 404."""
        if is_read_only:
            pytest.skip("Write operations not allowed in this environment")

        response = http_session.put(
            f"{products_url}/PROD-NONEXISTENT-99999",
            json={"name": "Updated Name"},
            timeout=api_timeout,
        )

        assert response.status_code == 404
```

### Pattern: Delete Resource (DELETE)

```python
class TestDeleteProduct:
    """Test cases for DELETE /v1.0/products/{productId} endpoint."""

    def test_delete_product_success(
        self,
        http_session: requests.Session,
        products_url: str,
        api_timeout: int,
        test_product_data: Dict[str, Any],
        is_read_only: bool,
    ):
        """Test deleting a product (soft delete)."""
        if is_read_only:
            pytest.skip("Write operations not allowed in this environment")

        # Create product first
        create_response = http_session.post(
            products_url,
            json=test_product_data,
            timeout=api_timeout,
        )

        assert create_response.status_code == 201
        product_id = create_response.json()["productId"]

        # Delete the product
        delete_response = http_session.delete(
            f"{products_url}/{product_id}",
            timeout=api_timeout,
        )

        assert delete_response.status_code == 204

    def test_delete_product_removes_from_list(
        self,
        http_session: requests.Session,
        products_url: str,
        api_timeout: int,
        test_product_data: Dict[str, Any],
        is_read_only: bool,
    ):
        """Test that deleted product is not returned in list."""
        if is_read_only:
            pytest.skip("Write operations not allowed in this environment")

        # Create product
        create_response = http_session.post(
            products_url,
            json=test_product_data,
            timeout=api_timeout,
        )
        product_id = create_response.json()["productId"]

        # Delete the product
        http_session.delete(f"{products_url}/{product_id}", timeout=api_timeout)

        # Verify not in list
        list_response = http_session.get(products_url, timeout=api_timeout)
        products = list_response.json().get("products", [])
        product_ids = [p["productId"] for p in products]

        assert product_id not in product_ids
```

---

## Running E2E Tests

```bash
# Run all E2E tests against DEV (default)
pytest tests/e2e/ -v

# Explicitly specify DEV
pytest tests/e2e/ --env=dev -v

# Run against SIT
pytest tests/e2e/ --env=sit -v

# Run against PROD (read-only tests only)
pytest tests/e2e/ --env=prod -v

# Run specific Lambda tests
pytest tests/e2e/list_products/ --env=dev -v
pytest tests/e2e/create_product/ --env=dev -v

# Run with verbose output
pytest tests/e2e/ --env=dev -v -s

# Stop on first failure
pytest tests/e2e/ --env=dev -v -x

# Run specific test by name
pytest tests/e2e/ --env=dev -v -k "test_list_products_success"
```

---

## E2E Test Coverage Matrix

| Lambda | Endpoint | Tests | Categories |
|--------|----------|-------|------------|
| list_products | GET /v1.0/products | 8 | Success, Structure, Validation |
| get_product | GET /v1.0/products/{id} | 6 | Success, Not Found, Structure |
| create_product | POST /v1.0/products | 14 | Success, Validation, Defaults |
| update_product | PUT /v1.0/products/{id} | 11 | Success, Partial, Not Found |
| delete_product | DELETE /v1.0/products/{id} | 9 | Success, Not Found, Cleanup |

**Total E2E Tests: ~48**

---

## E2E Best Practices

| Practice | Description |
|----------|-------------|
| PROD Safety | Skip write operations in PROD environment |
| Unique Test Data | Use UUID-based names to prevent collisions |
| Automatic Cleanup | Track and delete created resources after tests |
| Environment Isolation | Use `--env` flag to target specific environment |
| Graceful Skipping | Use `pytest.skip()` when dependencies missing |
| Timeout Handling | Configure appropriate timeouts per environment |

---

## Troubleshooting E2E Tests

### Connection Errors
```
ConnectionError: Failed to establish connection
```
- Verify API is deployed and accessible
- Check network connectivity
- Verify base URL in config.py

### 403 Forbidden
```
AssertionError: Expected 200, got 403
```
- Check if API requires authentication
- Verify API Gateway configuration
- Check CORS settings

### Timeout Errors
```
ReadTimeout: Read timed out
```
- Increase timeout in config.py
- Check Lambda cold start times
- Verify Lambda function performance

---

## Version History

- **v1.0** (2026-01-01): Initial definition with LocalStack and JIT AWS
- **v2.0** (2026-01-01): Added E2E API testing for deployed environments (DEV/SIT/PROD)
