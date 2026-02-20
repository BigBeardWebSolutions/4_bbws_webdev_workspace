# Lambda Management Skill

**Version**: 1.0
**Created**: 2025-12-29
**Type**: AWS Lambda Deployment & Operations
**Purpose**: Complete lifecycle management of AWS Lambda functions from development to production

---

## Purpose

Comprehensive skill for managing AWS Lambda functions including TDD implementation, OOP architecture, CI/CD pipelines, packaging, deployment, monitoring, security, and operational runbooks. Based on real-world Product Lambda implementation (2.1.4_LLD_Product_Lambda.md v4.0).

---

## Session Learnings Summary

This skill is derived from the complete implementation of a production-grade Lambda service (Product Lambda) with:
- **5 Lambda functions** (list, get, create, update, delete)
- **Test-Driven Development** (80%+ coverage requirement)
- **Object-Oriented Architecture** (service layer, repository pattern, Pydantic models)
- **Complete CI/CD** (GitHub Actions for DEV/SIT/PROD)
- **Infrastructure as Code** (Terraform for all resources)
- **Security Best Practices** (repository visibility, secrets management, IAM least privilege)
- **Comprehensive Documentation** (5 operational runbooks)

### Key Achievements
- 84 files created across 3 stages
- Zero forks/security breaches after visibility issue resolution
- Automated packaging and deployment pipeline
- Multi-environment promotion workflow
- Complete operational documentation

---

## Lambda Architecture Patterns

### 1. OOP Architecture (Layered Pattern)

**Directory Structure**:
```
lambda-service/
├── src/
│   ├── handlers/           # Lambda entry points (API layer)
│   │   ├── list_products.py
│   │   ├── get_product.py
│   │   ├── create_product.py
│   │   ├── update_product.py
│   │   └── delete_product.py
│   ├── services/           # Business logic layer
│   │   └── product_service.py
│   ├── repositories/       # Data access layer
│   │   └── product_repository.py
│   ├── models/             # Pydantic data models
│   │   ├── product.py      # Domain model
│   │   ├── requests.py     # Request DTOs
│   │   └── responses.py    # Response DTOs
│   ├── validators/         # Input validation
│   │   └── product_validator.py
│   ├── exceptions/         # Custom exceptions
│   │   └── product_exceptions.py
│   └── utils/              # Utilities
│       ├── response_builder.py
│       └── logger.py
├── tests/
│   ├── unit/               # Unit tests (80%+ coverage)
│   ├── integration/        # Integration tests
│   └── conftest.py         # Pytest fixtures
├── terraform/              # Infrastructure as Code
├── .github/workflows/      # CI/CD pipelines
├── scripts/                # Helper scripts
│   └── package_lambdas.sh
├── requirements.txt        # Production dependencies
├── requirements-dev.txt    # Development dependencies
└── pytest.ini              # Pytest configuration
```

### 2. Handler Pattern (Lambda Proxy Integration)

**Standard Lambda Handler Template**:
```python
"""
Lambda Handler: {Operation} {Resource}
HTTP Method: {GET/POST/PUT/DELETE}
Path: /v1.0/{resource}[/{id}]
"""
import json
import os
from typing import Dict, Any

from src.services.product_service import ProductService
from src.models.requests import CreateProductRequest
from src.utils.response_builder import ResponseBuilder
from src.utils.logger import get_logger
from src.exceptions.product_exceptions import (
    ProductValidationException,
    exception_to_response
)
from pydantic import ValidationError

# Initialize logger
logger = get_logger(__name__)

def handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lambda handler for {operation} {resource}.

    Args:
        event: API Gateway Lambda Proxy event
        context: Lambda context object

    Returns:
        API Gateway Lambda Proxy response
    """
    request_id = context.aws_request_id
    logger.info(f"Processing request", extra={
        "request_id": request_id,
        "http_method": event.get("httpMethod"),
        "path": event.get("path")
    })

    try:
        # Parse request body (for POST/PUT)
        body = event.get('body')
        if body:
            data = json.loads(body)

        # Validate with Pydantic
        try:
            request = CreateProductRequest(**data)
        except ValidationError as e:
            errors = [
                {"field": err['loc'][0], "message": err['msg']}
                for err in e.errors()
            ]
            raise ProductValidationException(
                "Invalid request data",
                field_errors=errors
            )

        # Business logic via service layer
        service = ProductService()
        result = service.create_product(request)

        # Return success response
        logger.info(f"Request completed successfully", extra={
            "request_id": request_id
        })
        return ResponseBuilder.created(result)

    except Exception as e:
        # Convert exception to HTTP response
        logger.error(f"Request failed", extra={
            "request_id": request_id,
            "error": str(e)
        }, exc_info=True)
        return exception_to_response(e)
```

### 3. Service Layer Pattern

**Business Logic Separation**:
```python
"""Product Service - Business Logic Layer"""
import uuid
from datetime import datetime
from typing import List
from decimal import Decimal

from src.models.product import Product
from src.models.requests import CreateProductRequest, UpdateProductRequest
from src.repositories.product_repository import ProductRepository
from src.validators.product_validator import ProductValidator
from src.exceptions.product_exceptions import (
    ProductNotFoundException,
    ProductAlreadyExistsException
)

class ProductService:
    """Service layer for product business logic."""

    def __init__(self, repository: ProductRepository = None):
        """Initialize service with optional repository dependency injection."""
        self.repository = repository or ProductRepository()

    def _generate_product_id(self) -> str:
        """Generate unique product ID: PROD-XXXXXX"""
        uid = str(uuid.uuid4()).replace('-', '').upper()[:6]
        return f"PROD-{uid}"

    def _get_timestamp(self) -> str:
        """Get current ISO 8601 timestamp."""
        return datetime.utcnow().isoformat() + 'Z'

    def list_products(self) -> List[Product]:
        """List all active products."""
        return self.repository.list_active_products()

    def get_product(self, product_id: str) -> Product:
        """
        Get product by ID.

        Raises:
            ProductNotFoundException: If product not found
        """
        ProductValidator.validate_product_id(product_id)
        return self.repository.get_by_id(product_id)

    def create_product(self, request: CreateProductRequest) -> Product:
        """
        Create new product.

        Raises:
            ProductValidationException: If validation fails
        """
        # Validate input data
        data = request.model_dump()
        ProductValidator.validate_product_data(data)

        # Generate ID and timestamps
        product_id = self._generate_product_id()
        timestamp = self._get_timestamp()

        # Create product
        product = Product(
            productId=product_id,
            name=request.name,
            description=request.description,
            price=request.price,
            currency=request.currency,
            period=request.period,
            features=request.features,
            active="true",
            createdAt=timestamp,
            updatedAt=timestamp
        )

        return self.repository.create(product)

    def update_product(self, product_id: str, request: UpdateProductRequest) -> Product:
        """
        Update existing product.

        Raises:
            ProductNotFoundException: If product not found
            ProductValidationException: If validation fails
        """
        # Validate product exists
        existing = self.repository.get_by_id(product_id)

        # Validate update data
        data = request.model_dump(exclude_none=True)
        if data:
            ProductValidator.validate_update_data(data)

        # Update timestamp
        data['updatedAt'] = self._get_timestamp()

        return self.repository.update(product_id, data)

    def delete_product(self, product_id: str) -> None:
        """
        Soft delete product (set active=false).

        Raises:
            ProductNotFoundException: If product not found
        """
        # Validate product exists
        self.repository.get_by_id(product_id)

        # Soft delete
        self.repository.delete(product_id)
```

### 4. Repository Pattern (DynamoDB)

**Data Access Layer**:
```python
"""Product Repository - Data Access Layer"""
import os
from typing import List, Dict, Any
import boto3
from boto3.dynamodb.conditions import Key

from src.models.product import Product
from src.exceptions.product_exceptions import ProductNotFoundException

class ProductRepository:
    """Repository for product data access."""

    def __init__(self):
        """Initialize DynamoDB connection."""
        dynamodb = boto3.resource('dynamodb')
        table_name = os.environ.get('DYNAMODB_TABLE', 'products-dev')
        self.table = dynamodb.Table(table_name)

    def _build_pk(self, product_id: str) -> str:
        """Build partition key: PRODUCT#{id}"""
        return f"PRODUCT#{product_id}"

    def _build_sk(self) -> str:
        """Build sort key: METADATA"""
        return "METADATA"

    def _item_to_product(self, item: Dict[str, Any]) -> Product:
        """Convert DynamoDB item to Product model."""
        # Remove DynamoDB keys
        item.pop('PK', None)
        item.pop('SK', None)
        return Product(**item)

    def get_by_id(self, product_id: str) -> Product:
        """
        Get product by ID.

        Raises:
            ProductNotFoundException: If product not found
        """
        response = self.table.get_item(
            Key={
                'PK': self._build_pk(product_id),
                'SK': self._build_sk()
            }
        )

        item = response.get('Item')
        if not item:
            raise ProductNotFoundException(product_id)

        return self._item_to_product(item)

    def list_active_products(self) -> List[Product]:
        """List all active products using GSI."""
        response = self.table.query(
            IndexName='ActiveProductsIndex',
            KeyConditionExpression=Key('active').eq('true'),
            ScanIndexForward=False  # Sort by createdAt DESC
        )

        items = response.get('Items', [])
        return [self._item_to_product(item) for item in items]

    def create(self, product: Product) -> Product:
        """Create new product."""
        item = product.model_dump()
        item['PK'] = self._build_pk(product.productId)
        item['SK'] = self._build_sk()

        self.table.put_item(Item=item)
        return product

    def update(self, product_id: str, data: Dict[str, Any]) -> Product:
        """
        Update product attributes.

        Raises:
            ProductNotFoundException: If product not found
        """
        # Build update expression
        update_expr = "SET " + ", ".join([f"#{k} = :{k}" for k in data.keys()])
        expr_names = {f"#{k}": k for k in data.keys()}
        expr_values = {f":{k}": v for k, v in data.items()}

        response = self.table.update_item(
            Key={
                'PK': self._build_pk(product_id),
                'SK': self._build_sk()
            },
            UpdateExpression=update_expr,
            ExpressionAttributeNames=expr_names,
            ExpressionAttributeValues=expr_values,
            ReturnValues='ALL_NEW'
        )

        return self._item_to_product(response['Attributes'])

    def delete(self, product_id: str) -> None:
        """Soft delete product (set active=false)."""
        self.table.update_item(
            Key={
                'PK': self._build_pk(product_id),
                'SK': self._build_sk()
            },
            UpdateExpression='SET active = :false, updatedAt = :timestamp',
            ExpressionAttributeValues={
                ':false': 'false',
                ':timestamp': datetime.utcnow().isoformat() + 'Z'
            }
        )
```

---

## Test-Driven Development (TDD)

### TDD Workflow

**Process**:
1. **Write test first** - Define expected behavior
2. **Run test** - Watch it fail (red)
3. **Implement code** - Make test pass (green)
4. **Refactor** - Improve code quality
5. **Repeat** - Continue until complete

### Test Structure

**Pytest Configuration** (`pytest.ini`):
```ini
[pytest]
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*
addopts =
    -v
    --tb=short
    --strict-markers
    --cov=src
    --cov-report=term-missing
    --cov-report=html
    --cov-fail-under=80
markers =
    unit: Unit tests
    integration: Integration tests
    slow: Slow-running tests
```

**Fixtures** (`tests/conftest.py`):
```python
"""Pytest fixtures for Lambda tests."""
import os
import pytest
import boto3
from moto import mock_dynamodb

@pytest.fixture(scope="function")
def aws_credentials():
    """Mock AWS credentials for moto."""
    os.environ["AWS_ACCESS_KEY_ID"] = "testing"
    os.environ["AWS_SECRET_ACCESS_KEY"] = "testing"
    os.environ["AWS_SECURITY_TOKEN"] = "testing"
    os.environ["AWS_SESSION_TOKEN"] = "testing"
    os.environ["AWS_DEFAULT_REGION"] = "us-east-1"

@pytest.fixture(scope="function")
def dynamodb_table(aws_credentials):
    """Create mock DynamoDB table."""
    with mock_dynamodb():
        dynamodb = boto3.resource('dynamodb', region_name='us-east-1')

        table = dynamodb.create_table(
            TableName='products-test',
            KeySchema=[
                {'AttributeName': 'PK', 'KeyType': 'HASH'},
                {'AttributeName': 'SK', 'KeyType': 'RANGE'}
            ],
            AttributeDefinitions=[
                {'AttributeName': 'PK', 'AttributeType': 'S'},
                {'AttributeName': 'SK', 'AttributeType': 'S'},
                {'AttributeName': 'active', 'AttributeType': 'S'},
                {'AttributeName': 'createdAt', 'AttributeType': 'S'}
            ],
            GlobalSecondaryIndexes=[
                {
                    'IndexName': 'ActiveProductsIndex',
                    'KeySchema': [
                        {'AttributeName': 'active', 'KeyType': 'HASH'},
                        {'AttributeName': 'createdAt', 'KeyType': 'RANGE'}
                    ],
                    'Projection': {'ProjectionType': 'ALL'},
                    'ProvisionedThroughput': {
                        'ReadCapacityUnits': 5,
                        'WriteCapacityUnits': 5
                    }
                }
            ],
            BillingMode='PAY_PER_REQUEST'
        )

        yield table

@pytest.fixture
def sample_product_data():
    """Sample product data for tests."""
    return {
        "name": "Test Product",
        "description": "Test description",
        "price": "99.99",
        "currency": "ZAR",
        "period": "monthly",
        "features": ["Feature 1", "Feature 2"]
    }

@pytest.fixture
def api_gateway_event():
    """Mock API Gateway event."""
    def _event(method="GET", path="/v1.0/products", body=None, path_params=None):
        return {
            "httpMethod": method,
            "path": path,
            "headers": {"Accept": "application/json"},
            "body": json.dumps(body) if body else None,
            "pathParameters": path_params or {},
            "requestContext": {"requestId": "test-request-id"}
        }
    return _event

@pytest.fixture
def lambda_context():
    """Mock Lambda context."""
    class Context:
        aws_request_id = "test-request-id"
        function_name = "test-function"
        memory_limit_in_mb = 256
        invoked_function_arn = "arn:aws:lambda:us-east-1:123456789012:function:test"

    return Context()
```

**Unit Test Example**:
```python
"""Unit tests for ProductService."""
import pytest
from decimal import Decimal
from src.services.product_service import ProductService
from src.models.requests import CreateProductRequest
from src.exceptions.product_exceptions import ProductNotFoundException

@pytest.mark.unit
def test_create_product_success(dynamodb_table, sample_product_data, monkeypatch):
    """Test successful product creation."""
    monkeypatch.setenv('DYNAMODB_TABLE', 'products-test')

    # Create request
    request = CreateProductRequest(**sample_product_data)

    # Create product
    service = ProductService()
    product = service.create_product(request)

    # Assertions
    assert product.productId.startswith('PROD-')
    assert product.name == sample_product_data['name']
    assert product.price == Decimal('99.99')
    assert product.active == 'true'
    assert product.createdAt is not None

@pytest.mark.unit
def test_get_product_not_found(dynamodb_table, monkeypatch):
    """Test getting non-existent product raises exception."""
    monkeypatch.setenv('DYNAMODB_TABLE', 'products-test')

    service = ProductService()

    with pytest.raises(ProductNotFoundException) as exc_info:
        service.get_product('PROD-NOTFOUND')

    assert 'not found' in str(exc_info.value)
```

**Integration Test Example**:
```python
"""Integration tests for Lambda handlers."""
import pytest
import json
from src.handlers.create_product import handler

@pytest.mark.integration
def test_create_product_handler(dynamodb_table, api_gateway_event, lambda_context, sample_product_data, monkeypatch):
    """Test create product Lambda handler end-to-end."""
    monkeypatch.setenv('DYNAMODB_TABLE', 'products-test')

    # Create event
    event = api_gateway_event(method='POST', path='/v1.0/products', body=sample_product_data)

    # Invoke handler
    response = handler(event, lambda_context)

    # Assertions
    assert response['statusCode'] == 201
    body = json.loads(response['body'])
    assert body['productId'].startswith('PROD-')
    assert body['name'] == sample_product_data['name']
```

### Coverage Requirements

**Minimum**: 80% code coverage enforced in CI/CD

**Running Tests**:
```bash
# All tests with coverage
pytest

# Unit tests only
pytest -m unit

# Integration tests only
pytest -m integration

# Coverage report
pytest --cov=src --cov-report=html
open htmlcov/index.html
```

---

## Lambda Packaging

### Packaging Script

**`scripts/package_lambdas.sh`**:
```bash
#!/bin/bash
#
# Package Lambda functions for deployment
#
set -e

echo "========================================
echo "Product Lambda Packaging Script"
echo "========================================"

# Get project root
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/..)" && pwd)"
cd "$PROJECT_ROOT"

# Clean previous builds
echo "Cleaning previous builds..."
rm -rf dist/
mkdir -p dist/

# Lambda handlers to package
HANDLERS=("list_products" "get_product" "create_product" "update_product" "delete_product")

# Package each handler
for handler in "${HANDLERS[@]}"; do
    echo ""
    echo "========================================"
    echo "Packaging: ${handler}"
    echo "========================================"

    # Create handler directory
    HANDLER_DIR="dist/$handler"
    mkdir -p "$HANDLER_DIR"

    # Install dependencies
    echo "Installing dependencies..."
    pip install -q -r requirements.txt -t "$HANDLER_DIR/"

    # Copy source code
    echo "Copying source code..."
    cp -r src "$HANDLER_DIR/"

    # Create ZIP file
    echo "Creating ZIP file..."
    cd "$HANDLER_DIR"
    zip -q -r "../${handler}.zip" .
    cd "$PROJECT_ROOT"

    # Get ZIP file size
    ZIP_SIZE=$(du -h "dist/${handler}.zip" | cut -f1)
    echo "✓ Created: dist/${handler}.zip (${ZIP_SIZE})"

    # Clean up temporary directory
    rm -rf "$HANDLER_DIR"
done

echo ""
echo "========================================"
echo "✓ All Lambda functions packaged successfully!"
echo "========================================"
echo ""

# List all ZIP files with sizes
echo "Package Summary:"
ls -lh dist/*.zip | awk '{print "  " $9 " - " $5}'
echo ""
```

**Make executable**:
```bash
chmod +x scripts/package_lambdas.sh
```

---

## Infrastructure as Code (Terraform)

### Lambda Function Resource

**`terraform/lambda.tf`**:
```hcl
# Lambda Functions with CloudWatch Log Groups

locals {
  lambda_functions = {
    list    = { handler = "src.handlers.list_products.handler", description = "List all active products" }
    get     = { handler = "src.handlers.get_product.handler", description = "Get product by ID" }
    create  = { handler = "src.handlers.create_product.handler", description = "Create new product" }
    update  = { handler = "src.handlers.update_product.handler", description = "Update existing product" }
    delete  = { handler = "src.handlers.delete_product.handler", description = "Delete product (soft delete)" }
  }
}

# Lambda Functions
resource "aws_lambda_function" "product_lambdas" {
  for_each = local.lambda_functions

  function_name = "bbws-product-${each.key}-${var.environment}"
  description   = each.value.description

  filename         = "${path.module}/../dist/${each.key}_products.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/${each.key}_products.zip")

  handler = each.value.handler
  runtime = "python3.12"

  role = aws_iam_role.lambda_execution.arn

  timeout     = 30
  memory_size = 256

  architectures = ["arm64"]

  environment {
    variables = {
      DYNAMODB_TABLE = data.aws_dynamodb_table.products.name
      ENVIRONMENT    = var.environment
      LOG_LEVEL      = var.log_level
    }
  }

  tags = merge(var.tags, {
    Name        = "bbws-product-${each.key}-${var.environment}"
    Component   = "Lambda"
    Function    = each.key
  })

  depends_on = [
    aws_cloudwatch_log_group.lambda_logs,
    aws_iam_role_policy_attachment.lambda_execution_policy
  ]
}

# CloudWatch Log Groups (created before Lambda)
resource "aws_cloudwatch_log_group" "lambda_logs" {
  for_each = local.lambda_functions

  name              = "/aws/lambda/bbws-product-${each.key}-${var.environment}"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name      = "/aws/lambda/bbws-product-${each.key}-${var.environment}"
    Component = "CloudWatch"
  })
}
```

### API Gateway Integration

**`terraform/api_gateway_integration.tf`**:
```hcl
# API Gateway Lambda Integrations

locals {
  lambda_integrations = {
    "list"   = { method = "GET",    path_part = null }
    "get"    = { method = "GET",    path_part = "{productId}" }
    "create" = { method = "POST",   path_part = null }
    "update" = { method = "PUT",    path_part = "{productId}" }
    "delete" = { method = "DELETE", path_part = "{productId}" }
  }
}

# API Gateway Methods
resource "aws_api_gateway_method" "product_methods" {
  for_each = local.lambda_integrations

  rest_api_id   = aws_api_gateway_rest_api.product_api.id
  resource_id   = each.value.path_part == null ? aws_api_gateway_resource.products.id : aws_api_gateway_resource.product_id.id
  http_method   = each.value.method
  authorization = "NONE"
}

# Lambda Integrations
resource "aws_api_gateway_integration" "lambda_integrations" {
  for_each = local.lambda_integrations

  rest_api_id = aws_api_gateway_rest_api.product_api.id
  resource_id = each.value.path_part == null ? aws_api_gateway_resource.products.id : aws_api_gateway_resource.product_id.id
  http_method = aws_api_gateway_method.product_methods[each.key].http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.product_lambdas[each.key].invoke_arn
}

# Lambda Permissions for API Gateway
resource "aws_lambda_permission" "api_gateway" {
  for_each = local.lambda_integrations

  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.product_lambdas[each.key].function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.product_api.execution_arn}/*/*"
}

# CORS OPTIONS Methods
resource "aws_api_gateway_method" "options" {
  for_each = toset(["products", "product_id"])

  rest_api_id   = aws_api_gateway_rest_api.product_api.id
  resource_id   = each.key == "products" ? aws_api_gateway_resource.products.id : aws_api_gateway_resource.product_id.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options" {
  for_each = toset(["products", "product_id"])

  rest_api_id = aws_api_gateway_rest_api.product_api.id
  resource_id = each.key == "products" ? aws_api_gateway_resource.products.id : aws_api_gateway_resource.product_id.id
  http_method = aws_api_gateway_method.options[each.key].http_method

  type = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "options" {
  for_each = toset(["products", "product_id"])

  rest_api_id = aws_api_gateway_rest_api.product_api.id
  resource_id = each.key == "products" ? aws_api_gateway_resource.products.id : aws_api_gateway_resource.product_id.id
  http_method = aws_api_gateway_method.options[each.key].http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "options" {
  for_each = toset(["products", "product_id"])

  rest_api_id = aws_api_gateway_rest_api.product_api.id
  resource_id = each.key == "products" ? aws_api_gateway_resource.products.id : aws_api_gateway_resource.product_id.id
  http_method = aws_api_gateway_method.options[each.key].http_method
  status_code = aws_api_gateway_method_response.options[each.key].status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = each.key == "products" ? "'GET,POST,OPTIONS'" : "'GET,PUT,DELETE,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [aws_api_gateway_integration.options]
}
```

---

## CI/CD Pipeline (GitHub Actions)

### DEV Deployment (Auto)

**`.github/workflows/deploy-dev.yml`**:
```yaml
name: Deploy to DEV

on:
  push:
    branches: [main]
  workflow_dispatch:

permissions:
  id-token: write
  contents: read

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.12'

      - name: Install dependencies
        run: |
          pip install -r requirements-dev.txt

      - name: Run tests with coverage
        run: |
          pytest --cov=src --cov-fail-under=80 --cov-report=term-missing

  quality:
    runs-on: ubuntu-latest
    needs: test
    steps:
      - uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.12'

      - name: Install dependencies
        run: |
          pip install black mypy ruff

      - name: Run black formatting check
        run: black --check src/ tests/

      - name: Run mypy type checking
        run: mypy src/

      - name: Run ruff linting
        run: ruff check src/ tests/

  package:
    runs-on: ubuntu-latest
    needs: [test, quality]
    steps:
      - uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.12'

      - name: Package Lambda functions
        run: |
          mkdir -p dist
          for handler in list_products get_product create_product update_product delete_product; do
            HANDLER_DIR="dist/$handler"
            mkdir -p "$HANDLER_DIR"
            pip install -r requirements.txt -t "$HANDLER_DIR/"
            cp -r src "$HANDLER_DIR/"
            cd "$HANDLER_DIR" && zip -r "../$handler.zip" . && cd ../..
          done

      - name: Upload artifacts
        uses: actions/upload-artifact@v4
        with:
          name: lambda-packages
          path: dist/*.zip
          retention-days: 7

  deploy:
    runs-on: ubuntu-latest
    needs: package
    environment: dev
    steps:
      - uses: actions/checkout@v4

      - name: Download artifacts
        uses: actions/download-artifact@v4
        with:
          name: lambda-packages
          path: dist/

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::536580886816:role/github-actions-oidc
          aws-region: eu-west-1

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.5.0

      - name: Terraform Init
        working-directory: terraform
        run: |
          terraform init \
            -backend-config="bucket=bbws-terraform-state-dev" \
            -backend-config="key=product-lambda/dev/terraform.tfstate" \
            -backend-config="region=eu-west-1" \
            -backend-config="dynamodb_table=terraform-state-lock-dev" \
            -backend-config="encrypt=true"

      - name: Terraform Plan
        working-directory: terraform
        run: terraform plan -var-file=environments/dev.tfvars -out=tfplan

      - name: Terraform Apply
        working-directory: terraform
        run: terraform apply -auto-approve tfplan

      - name: Get API URL
        working-directory: terraform
        run: |
          API_URL=$(terraform output -raw api_gateway_url)
          echo "API_URL=$API_URL" >> $GITHUB_ENV

      - name: Validate deployment
        run: |
          echo "Testing API endpoint: $API_URL"
          curl -f $API_URL || exit 1
```

### SIT Deployment (Manual with Approval)

**`.github/workflows/deploy-sit.yml`**:
```yaml
name: Deploy to SIT

on:
  workflow_dispatch:
    inputs:
      confirm:
        description: 'Type "deploy" to confirm deployment to SIT'
        required: true
        type: string

permissions:
  id-token: write
  contents: read

jobs:
  validate-input:
    runs-on: ubuntu-latest
    steps:
      - name: Validate confirmation
        run: |
          if [ "${{ github.event.inputs.confirm }}" != "deploy" ]; then
            echo "❌ Deployment cancelled - confirmation required"
            exit 1
          fi
          echo "✅ Confirmation validated"

  test:
    runs-on: ubuntu-latest
    needs: validate-input
    steps:
      - uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.12'

      - name: Install dependencies
        run: pip install -r requirements-dev.txt

      - name: Run full test suite
        run: pytest --cov=src --cov-fail-under=80

  quality:
    runs-on: ubuntu-latest
    needs: test
    steps:
      - uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.12'

      - name: Run quality checks
        run: |
          pip install black mypy ruff
          black --check src/ tests/
          mypy src/
          ruff check src/ tests/

  package:
    runs-on: ubuntu-latest
    needs: [test, quality]
    steps:
      - uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.12'

      - name: Package Lambda functions
        run: ./scripts/package_lambdas.sh

      - name: Upload artifacts
        uses: actions/upload-artifact@v4
        with:
          name: lambda-packages-sit
          path: dist/*.zip
          retention-days: 14

  plan:
    runs-on: ubuntu-latest
    needs: package
    environment: sit-plan
    steps:
      - uses: actions/checkout@v4

      - name: Download artifacts
        uses: actions/download-artifact@v4
        with:
          name: lambda-packages-sit
          path: dist/

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::815856636111:role/github-actions-oidc
          aws-region: eu-west-1

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3

      - name: Terraform Init
        working-directory: terraform
        run: |
          terraform init \
            -backend-config="bucket=bbws-terraform-state-sit" \
            -backend-config="key=product-lambda/sit/terraform.tfstate" \
            -backend-config="region=eu-west-1"

      - name: Terraform Plan
        working-directory: terraform
        run: terraform plan -var-file=environments/sit.tfvars

  deploy:
    runs-on: ubuntu-latest
    needs: plan
    environment: sit
    steps:
      - uses: actions/checkout@v4

      - name: Download artifacts
        uses: actions/download-artifact@v4
        with:
          name: lambda-packages-sit
          path: dist/

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::815856636111:role/github-actions-oidc
          aws-region: eu-west-1

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3

      - name: Terraform Init
        working-directory: terraform
        run: |
          terraform init \
            -backend-config="bucket=bbws-terraform-state-sit" \
            -backend-config="key=product-lambda/sit/terraform.tfstate" \
            -backend-config="region=eu-west-1"

      - name: Terraform Apply
        working-directory: terraform
        run: terraform apply -var-file=environments/sit.tfvars -auto-approve

      - name: Validate deployment
        working-directory: terraform
        run: |
          API_URL=$(terraform output -raw api_gateway_url)
          curl -f $API_URL
```

### PROD Deployment (Strict Approval)

**`.github/workflows/deploy-prod.yml`**:
```yaml
name: Deploy to PROD

on:
  workflow_dispatch:
    inputs:
      confirm:
        description: 'Type "deploy-to-production" to confirm'
        required: true
        type: string
      reason:
        description: 'Reason for deployment (required)'
        required: true
        type: string

permissions:
  id-token: write
  contents: read

jobs:
  validate-input:
    runs-on: ubuntu-latest
    steps:
      - name: Validate confirmation
        run: |
          if [ "${{ github.event.inputs.confirm }}" != "deploy-to-production" ]; then
            echo "❌ Deployment cancelled - strict confirmation required"
            exit 1
          fi
          if [ -z "${{ github.event.inputs.reason }}" ]; then
            echo "❌ Deployment cancelled - reason required"
            exit 1
          fi
          echo "✅ Validation passed"
          echo "📝 Reason: ${{ github.event.inputs.reason }}"

  test:
    runs-on: ubuntu-latest
    needs: validate-input
    steps:
      - uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.12'

      - name: Run full test suite
        run: |
          pip install -r requirements-dev.txt
          pytest --cov=src --cov-fail-under=80

  quality:
    runs-on: ubuntu-latest
    needs: test
    steps:
      - uses: actions/checkout@v4

      - name: Run quality checks
        run: |
          pip install black mypy ruff
          black --check src/ tests/
          mypy src/
          ruff check src/ tests/

  package:
    runs-on: ubuntu-latest
    needs: [test, quality]
    steps:
      - uses: actions/checkout@v4

      - name: Package Lambda functions
        run: ./scripts/package_lambdas.sh

      - name: Upload artifacts
        uses: actions/upload-artifact@v4
        with:
          name: lambda-packages-prod
          path: dist/*.zip
          retention-days: 30

  plan:
    runs-on: ubuntu-latest
    needs: package
    environment: prod-plan
    steps:
      - uses: actions/checkout@v4

      - name: Download artifacts
        uses: actions/download-artifact@v4
        with:
          name: lambda-packages-prod
          path: dist/

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::093646564004:role/github-actions-oidc
          aws-region: af-south-1

      - name: Terraform Plan
        working-directory: terraform
        run: |
          terraform init \
            -backend-config="bucket=bbws-terraform-state-prod" \
            -backend-config="key=product-lambda/prod/terraform.tfstate" \
            -backend-config="region=af-south-1"
          terraform plan -var-file=environments/prod.tfvars

  deploy:
    runs-on: ubuntu-latest
    needs: plan
    environment: prod
    steps:
      - uses: actions/checkout@v4

      - name: Download artifacts
        uses: actions/download-artifact@v4
        with:
          name: lambda-packages-prod
          path: dist/

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::093646564004:role/github-actions-oidc
          aws-region: af-south-1

      - name: Terraform Apply
        working-directory: terraform
        run: |
          terraform init \
            -backend-config="bucket=bbws-terraform-state-prod" \
            -backend-config="key=product-lambda/prod/terraform.tfstate" \
            -backend-config="region=af-south-1"
          terraform apply -var-file=environments/prod.tfvars -auto-approve

      - name: Validate deployment
        working-directory: terraform
        run: |
          API_URL=$(terraform output -raw api_gateway_url)
          curl -f $API_URL

      - name: Log deployment
        run: |
          echo "🚀 PROD Deployment Complete"
          echo "Reason: ${{ github.event.inputs.reason }}"
          echo "Deployed by: ${{ github.actor }}"
          echo "Timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
```

---

## Security Best Practices

### 1. Repository Visibility

**Critical Lesson**: Always create repositories as PRIVATE

**Repository Creation**:
```bash
# CORRECT: Create private repository
gh repo create BigBeardWebSolutions/lambda-service --private

# WRONG: Public repository exposes sensitive data
gh repo create BigBeardWebSolutions/lambda-service --public  # ❌ NEVER DO THIS
```

**Visibility Audit**:
```bash
# List all repositories with visibility
gh repo list BigBeardWebSolutions --json name,visibility,isPrivate --limit 100

# Make repository private
gh repo edit BigBeardWebSolutions/repo-name --visibility private --accept-visibility-change-consequences
```

**Security Risks of Public Repositories**:
- AWS account IDs exposed
- Infrastructure architecture visible
- Database schemas revealed
- Business logic accessible
- API endpoints discoverable
- Easier social engineering attacks

### 2. Secrets Management

**Never Hardcode Credentials**:
```python
# ❌ WRONG: Hardcoded credentials
DATABASE_PASSWORD = "my-secret-password"

# ✅ CORRECT: Use AWS Secrets Manager
import boto3
import json

def get_db_credentials():
    """Get database credentials from Secrets Manager."""
    client = boto3.client('secretsmanager')
    response = client.get_secret_value(SecretId='/prod/db/credentials')
    return json.loads(response['SecretString'])

# ✅ CORRECT: Use environment variables
import os
DYNAMODB_TABLE = os.environ['DYNAMODB_TABLE']
```

**GitHub Secrets**:
```yaml
# Store in GitHub repository secrets, NOT in code
# Settings → Secrets and variables → Actions → New repository secret
env:
  AWS_ACCOUNT_ID: ${{ secrets.AWS_ACCOUNT_ID }}
  API_KEY: ${{ secrets.API_KEY }}
```

### 3. IAM Least Privilege

**Lambda Execution Role** (terraform):
```hcl
resource "aws_iam_role" "lambda_execution" {
  name = "bbws-product-lambda-execution-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# CloudWatch Logs permissions (required)
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# DynamoDB permissions (least privilege)
resource "aws_iam_role_policy" "dynamodb_access" {
  name = "dynamodb-access"
  role = aws_iam_role.lambda_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query"
        ]
        Resource = [
          data.aws_dynamodb_table.products.arn,
          "${data.aws_dynamodb_table.products.arn}/index/*"
        ]
      }
    ]
  })
}
```

### 4. GitHub OIDC Authentication

**Use OIDC instead of long-lived credentials**:

```yaml
# .github/workflows/deploy-dev.yml
permissions:
  id-token: write  # Required for OIDC
  contents: read

- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::536580886816:role/github-actions-oidc
    aws-region: eu-west-1
```

**AWS IAM Role for GitHub OIDC**:
```hcl
resource "aws_iam_role" "github_actions" {
  name = "github-actions-oidc"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:BigBeardWebSolutions/*:*"
        }
      }
    }]
  })
}
```

### 5. Security Scanning

**Pre-commit Hooks** (`.pre-commit-config.yaml`):
```yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: detect-private-key
      - id: check-added-large-files
      - id: check-merge-conflict

  - repo: https://github.com/Yelp/detect-secrets
    rev: v1.4.0
    hooks:
      - id: detect-secrets
        args: ['--baseline', '.secrets.baseline']
```

**Dependabot** (`.github/dependabot.yml`):
```yaml
version: 2
updates:
  - package-ecosystem: "pip"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 10

  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
```

---

## Monitoring & Operations

### CloudWatch Alarms

**`terraform/cloudwatch.tf`**:
```hcl
# SNS Topic for alarms
resource "aws_sns_topic" "lambda_alarms" {
  name = "bbws-product-lambda-alarms-${var.environment}"

  tags = merge(var.tags, {
    Name = "bbws-product-lambda-alarms-${var.environment}"
  })
}

# CloudWatch Alarms for each Lambda
locals {
  alarm_functions = ["list", "get", "create", "update", "delete"]
}

# Lambda Errors Alarm
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  for_each = toset(local.alarm_functions)

  alarm_name          = "bbws-product-${each.key}-errors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "Alert when Lambda function has more than 5 errors in 5 minutes"
  alarm_actions       = [aws_sns_topic.lambda_alarms.arn]

  dimensions = {
    FunctionName = aws_lambda_function.product_lambdas[each.key].function_name
  }

  tags = merge(var.tags, {
    Function = each.key
  })
}

# Lambda Duration Alarm
resource "aws_cloudwatch_metric_alarm" "lambda_duration" {
  for_each = toset(local.alarm_functions)

  alarm_name          = "bbws-product-${each.key}-duration-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = "60"
  statistic           = "Average"
  threshold           = "25000"  # 25 seconds (timeout is 30s)
  alarm_description   = "Alert when Lambda duration approaches timeout"
  alarm_actions       = [aws_sns_topic.lambda_alarms.arn]

  dimensions = {
    FunctionName = aws_lambda_function.product_lambdas[each.key].function_name
  }

  tags = merge(var.tags, {
    Function = each.key
  })
}

# Lambda Throttles Alarm
resource "aws_cloudwatch_metric_alarm" "lambda_throttles" {
  for_each = toset(local.alarm_functions)

  alarm_name          = "bbws-product-${each.key}-throttles-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "Alert when Lambda is throttled"
  alarm_actions       = [aws_sns_topic.lambda_alarms.arn]

  dimensions = {
    FunctionName = aws_lambda_function.product_lambdas[each.key].function_name
  }

  tags = merge(var.tags, {
    Function = each.key
  })
}

# API Gateway 5xx Errors
resource "aws_cloudwatch_metric_alarm" "api_5xx" {
  alarm_name          = "bbws-product-api-5xx-errors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "5XXError"
  namespace           = "AWS/ApiGateway"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "Alert when API Gateway has more than 10 5xx errors in 5 minutes"
  alarm_actions       = [aws_sns_topic.lambda_alarms.arn]

  dimensions = {
    ApiName = aws_api_gateway_rest_api.product_api.name
  }

  tags = var.tags
}

# API Gateway Latency
resource "aws_cloudwatch_metric_alarm" "api_latency" {
  alarm_name          = "bbws-product-api-latency-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Latency"
  namespace           = "AWS/ApiGateway"
  period              = "60"
  statistic           = "Average"
  threshold           = "5000"  # 5 seconds
  alarm_description   = "Alert when API Gateway latency exceeds 5 seconds"
  alarm_actions       = [aws_sns_topic.lambda_alarms.arn]

  dimensions = {
    ApiName = aws_api_gateway_rest_api.product_api.name
  }

  tags = var.tags
}
```

### Operations Commands

**View Logs**:
```bash
# Tail Lambda logs
aws logs tail /aws/lambda/bbws-product-list-dev --follow

# Filter for errors
aws logs tail /aws/lambda/bbws-product-list-dev --filter-pattern "ERROR"

# Get logs for time range
aws logs filter-log-events \
  --log-group-name /aws/lambda/bbws-product-list-dev \
  --start-time $(date -u -v-1H +%s)000 \
  --filter-pattern "ERROR"
```

**Test API**:
```bash
API_URL="https://abc123.execute-api.eu-west-1.amazonaws.com/v1/v1.0/products"

# List products
curl -X GET $API_URL

# Get product
curl -X GET $API_URL/PROD-ABC123

# Create product
curl -X POST $API_URL \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Product",
    "description": "Test",
    "price": "99.99",
    "currency": "ZAR",
    "period": "monthly",
    "features": []
  }'
```

**Monitor Metrics**:
```bash
# Check Lambda errors (last hour)
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Errors \
  --dimensions Name=FunctionName,Value=bbws-product-list-dev \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum

# Check API Gateway requests
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApiGateway \
  --metric-name Count \
  --dimensions Name=ApiName,Value=bbws-product-api-dev \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum
```

---

## Operational Runbooks

### Runbook Categories

Create 5 comprehensive runbooks for each Lambda service:

1. **Deployment Runbook** (`{service}_deployment.md`)
   - Prerequisites and access requirements
   - Automated deployment (GitHub Actions)
   - Local deployment (Terraform)
   - Post-deployment validation
   - Environment-specific details
   - Rollback procedures
   - Troubleshooting

2. **Operations Runbook** (`{service}_operations.md`)
   - Daily operations tasks
   - Monitoring commands
   - Log viewing and filtering
   - API endpoint testing
   - Configuration management
   - Performance tuning
   - Data operations

3. **Disaster Recovery Runbook** (`{service}_disaster_recovery.md`)
   - DR strategy (RPO/RTO)
   - Backup components
   - Failure scenarios with recovery procedures
   - Regional failover (if applicable)
   - Complete infrastructure loss recovery
   - DR testing procedures
   - Post-recovery actions

4. **Development Setup Runbook** (`{service}_dev_setup.md`)
   - Prerequisites
   - Repository cloning
   - Python environment setup
   - Running tests
   - Code quality checks
   - Local development workflow
   - IDE configuration
   - Common issues

5. **CI/CD Guide** (`{service}_cicd_guide.md`)
   - CI/CD overview
   - Workflow architecture
   - Pipeline stages
   - Deployment procedures
   - Monitoring deployments
   - Troubleshooting pipelines
   - Rollback procedures
   - Best practices

### Runbook Template Structure

```markdown
# {Service} {Type} Runbook

**Service**: {Service Name}
**Last Updated**: {Date}
{**Repository**: URL (if applicable)}
{**RPO/RTO**: Values (if DR)}

---

## Overview

{Brief description of purpose}

---

## {Section 1}

{Content with code examples}

```bash
# Command examples
command --flag value
```

---

## {Section 2}

{Tables, lists, procedures}

---

**Related**: Links to other runbooks
```

---

## Environment Management

### Multi-Environment Strategy

**Environments**:
| Environment | AWS Account | Region | Deployment | Approval |
|-------------|-------------|--------|------------|----------|
| **DEV** | 536580886816 | eu-west-1 | Auto (push to main) | None |
| **SIT** | 815856636111 | eu-west-1 | Manual trigger | Required |
| **PROD** | 093646564004 | af-south-1 | Manual trigger | Strict |

**Promotion Flow**:
```
Code Push → DEV (auto-deploy) → [Approval] → SIT (manual) → [Approval] → PROD (manual)
```

### Environment Configuration

**Terraform Variables** (`terraform/environments/{env}.tfvars`):

**`environments/dev.tfvars`**:
```hcl
environment         = "dev"
aws_region          = "eu-west-1"
aws_account_id      = "536580886816"
log_level           = "DEBUG"
log_retention_days  = 7

tags = {
  Environment = "dev"
  Project     = "BBWS-Customer-Portal"
  ManagedBy   = "Terraform"
  Component   = "Product-Lambda"
  Owner       = "Platform-Team"
}
```

**`environments/sit.tfvars`**:
```hcl
environment         = "sit"
aws_region          = "eu-west-1"
aws_account_id      = "815856636111"
log_level           = "INFO"
log_retention_days  = 14

tags = {
  Environment = "sit"
  Project     = "BBWS-Customer-Portal"
  ManagedBy   = "Terraform"
  Component   = "Product-Lambda"
  Owner       = "Platform-Team"
}
```

**`environments/prod.tfvars`**:
```hcl
environment         = "prod"
aws_region          = "af-south-1"
aws_account_id      = "093646564004"
log_level           = "WARN"
log_retention_days  = 30

tags = {
  Environment = "prod"
  Project     = "BBWS-Customer-Portal"
  ManagedBy   = "Terraform"
  Component   = "Product-Lambda"
  Owner       = "Platform-Team"
  CostCenter  = "Infrastructure"
}
```

### Environment Variables

**Lambda Environment Variables**:
```python
import os

# Required
DYNAMODB_TABLE = os.environ['DYNAMODB_TABLE']  # products-{env}
ENVIRONMENT = os.environ['ENVIRONMENT']  # dev/sit/prod
LOG_LEVEL = os.environ.get('LOG_LEVEL', 'INFO')  # DEBUG/INFO/WARN/ERROR

# Optional
AWS_REGION = os.environ.get('AWS_REGION', 'eu-west-1')
```

---

## Disaster Recovery

### DR Strategy

**Pattern**: Multi-site Active/Active with Route 53 failover

**Primary Region**: af-south-1 (Cape Town) - PROD only
**DR Region**: eu-west-1 (Ireland) - Passive standby

**RPO**: 1 hour (hourly DynamoDB backups)
**RTO**: 30 minutes (automated failover)

### Backup Components

1. **Lambda Code**
   - GitHub: Primary source of truth
   - S3 Artifacts: Deployment ZIPs retained (7-30 days)
   - Terraform State: S3 backend with versioning

2. **DynamoDB**
   - PITR: Enabled (point-in-time recovery)
   - Hourly Snapshots: Automated
   - Cross-Region Replication: PROD only (af-south-1 → eu-west-1)

3. **Infrastructure**
   - Terraform: All infrastructure as code
   - State Backups: S3 versioning enabled
   - Git History: Complete deployment history

### Recovery Scenarios

**Scenario 1: Lambda Function Failure**
```bash
# Rollback to previous version
aws lambda update-function-code \
  --function-name bbws-product-list-prod \
  --s3-bucket bbws-lambda-artifacts-prod \
  --s3-key previous-version/list_products.zip

# Verify recovery
curl https://api.kimmyai.io/v1/v1.0/products
```

**RTO**: 5 minutes

**Scenario 2: Complete Infrastructure Loss**
```bash
# Clone repository
git clone https://github.com/BigBeardWebSolutions/2_bbws_product_lambda.git
cd 2_bbws_product_lambda

# Package Lambda functions
./scripts/package_lambdas.sh

# Initialize Terraform
cd terraform
terraform init -backend-config=environments/prod.tfvars

# Recreate infrastructure
terraform apply -var-file=environments/prod.tfvars

# Restore DynamoDB data from backup
aws dynamodb restore-table-from-backup \
  --target-table-name products-prod \
  --backup-arn arn:aws:dynamodb:af-south-1:093646564004:table/products-prod/backup/LATEST
```

**RTO**: 45-60 minutes

---

## Version History

- **v1.0** (2025-12-29): Initial Lambda Management skill with complete lifecycle coverage based on Product Lambda implementation (Session 3)
