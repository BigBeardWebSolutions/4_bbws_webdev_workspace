# Worker Instructions: Project Structure & Dependencies

**Worker ID**: worker-1-project-structure
**Stage**: Stage 2 - Lambda Code Development
**Project**: project-plan-campaigns

---

## Task

Set up the Python project structure with proper package initialization, dependencies, and configuration files.

---

## Inputs

**Primary Input**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/2.1.3_LLD_Campaigns_Lambda.md`

**Reference**:
- Section 16: Appendices > Project Structure

---

## Deliverables

### 1. Package Initialization Files

Create `__init__.py` files for all packages:

```python
# src/__init__.py
"""Campaign Management Lambda Service."""

__version__ = "1.0.0"
```

```python
# src/handlers/__init__.py
"""Lambda handlers for Campaign API endpoints."""

from .list_campaigns import handler as list_campaigns_handler
from .get_campaign import handler as get_campaign_handler
from .create_campaign import handler as create_campaign_handler
from .update_campaign import handler as update_campaign_handler
from .delete_campaign import handler as delete_campaign_handler

__all__ = [
    "list_campaigns_handler",
    "get_campaign_handler",
    "create_campaign_handler",
    "update_campaign_handler",
    "delete_campaign_handler",
]
```

```python
# src/services/__init__.py
"""Business logic services."""

from .campaign_service import CampaignService

__all__ = ["CampaignService"]
```

```python
# src/repositories/__init__.py
"""Data access repositories."""

from .campaign_repository import CampaignRepository

__all__ = ["CampaignRepository"]
```

```python
# src/models/__init__.py
"""Data models and schemas."""

from .campaign import (
    Campaign,
    CampaignStatus,
    CampaignResponse,
    CampaignListResponse,
    CreateCampaignRequest,
    UpdateCampaignRequest,
)

__all__ = [
    "Campaign",
    "CampaignStatus",
    "CampaignResponse",
    "CampaignListResponse",
    "CreateCampaignRequest",
    "UpdateCampaignRequest",
]
```

```python
# src/exceptions/__init__.py
"""Custom exceptions."""

from .campaign_exceptions import (
    CampaignNotFoundException,
    ValidationException,
    DuplicateCampaignException,
    DatabaseException,
)

__all__ = [
    "CampaignNotFoundException",
    "ValidationException",
    "DuplicateCampaignException",
    "DatabaseException",
]
```

```python
# src/validators/__init__.py
"""Input validators."""

from .campaign_validator import CampaignValidator

__all__ = ["CampaignValidator"]
```

```python
# src/utils/__init__.py
"""Utility functions."""

from .response_builder import ResponseBuilder
from .date_utils import DateUtils
from .logger import get_logger

__all__ = ["ResponseBuilder", "DateUtils", "get_logger"]
```

### 2. Requirements Files

**requirements.txt**
```txt
boto3>=1.34.0
pydantic>=2.5.0
aws-lambda-powertools>=2.30.0
python-dateutil>=2.8.2
```

**requirements-dev.txt**
```txt
-r requirements.txt
pytest>=7.4.0
pytest-cov>=4.1.0
pytest-mock>=3.12.0
pytest-asyncio>=0.21.0
moto>=4.2.0
freezegun>=1.2.0
black>=23.12.0
isort>=5.13.0
flake8>=6.1.0
mypy>=1.7.0
boto3-stubs[dynamodb]>=1.34.0
```

### 3. Configuration Files

**pyproject.toml**
```toml
[build-system]
requires = ["setuptools>=61.0"]
build-backend = "setuptools.build_meta"

[project]
name = "bbws-campaigns-lambda"
version = "1.0.0"
description = "Campaign Management Lambda Service for BBWS Customer Portal"
requires-python = ">=3.12"
dependencies = [
    "boto3>=1.34.0",
    "pydantic>=2.5.0",
    "aws-lambda-powertools>=2.30.0",
    "python-dateutil>=2.8.2",
]

[project.optional-dependencies]
dev = [
    "pytest>=7.4.0",
    "pytest-cov>=4.1.0",
    "pytest-mock>=3.12.0",
    "moto>=4.2.0",
    "black>=23.12.0",
    "isort>=5.13.0",
    "flake8>=6.1.0",
    "mypy>=1.7.0",
]

[tool.black]
line-length = 88
target-version = ["py312"]
include = '\.pyi?$'
exclude = '''
/(
    \.git
    | \.venv
    | build
    | dist
    | \.eggs
)/
'''

[tool.isort]
profile = "black"
line_length = 88
known_first_party = ["src"]

[tool.mypy]
python_version = "3.12"
warn_return_any = true
warn_unused_configs = true
ignore_missing_imports = true

[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]
python_classes = ["Test*"]
python_functions = ["test_*"]
addopts = "-v --cov=src --cov-report=term-missing --cov-report=html"
filterwarnings = ["ignore::DeprecationWarning"]
```

### 4. Test Configuration

**tests/__init__.py**
```python
"""Test suite for Campaign Management Lambda."""
```

**tests/conftest.py**
```python
"""Pytest configuration and fixtures."""

import os
import pytest
import boto3
from moto import mock_dynamodb
from decimal import Decimal
from datetime import datetime, timezone

# Set environment variables before importing modules
os.environ["CAMPAIGNS_TABLE_NAME"] = "test-campaigns-table"
os.environ["ENVIRONMENT"] = "test"
os.environ["LOG_LEVEL"] = "DEBUG"
os.environ["AWS_DEFAULT_REGION"] = "eu-west-1"


@pytest.fixture
def aws_credentials():
    """Mocked AWS Credentials for moto."""
    os.environ["AWS_ACCESS_KEY_ID"] = "testing"
    os.environ["AWS_SECRET_ACCESS_KEY"] = "testing"
    os.environ["AWS_SECURITY_TOKEN"] = "testing"
    os.environ["AWS_SESSION_TOKEN"] = "testing"
    os.environ["AWS_DEFAULT_REGION"] = "eu-west-1"


@pytest.fixture
def dynamodb_table(aws_credentials):
    """Create mocked DynamoDB table."""
    with mock_dynamodb():
        dynamodb = boto3.resource("dynamodb", region_name="eu-west-1")

        table = dynamodb.create_table(
            TableName="test-campaigns-table",
            KeySchema=[
                {"AttributeName": "PK", "KeyType": "HASH"},
                {"AttributeName": "SK", "KeyType": "RANGE"},
            ],
            AttributeDefinitions=[
                {"AttributeName": "PK", "AttributeType": "S"},
                {"AttributeName": "SK", "AttributeType": "S"},
                {"AttributeName": "GSI1_PK", "AttributeType": "S"},
                {"AttributeName": "GSI1_SK", "AttributeType": "S"},
            ],
            GlobalSecondaryIndexes=[
                {
                    "IndexName": "CampaignsByStatusIndex",
                    "KeySchema": [
                        {"AttributeName": "GSI1_PK", "KeyType": "HASH"},
                        {"AttributeName": "GSI1_SK", "KeyType": "RANGE"},
                    ],
                    "Projection": {"ProjectionType": "ALL"},
                }
            ],
            BillingMode="PAY_PER_REQUEST",
        )

        table.wait_until_exists()
        yield table


@pytest.fixture
def sample_campaign_data():
    """Sample campaign data for testing."""
    return {
        "code": "SUMMER2025",
        "name": "Summer Sale 2025",
        "productId": "PROD-002",
        "discountPercent": 20,
        "listPrice": Decimal("1500.00"),
        "termsAndConditions": "Valid for new customers only.",
        "fromDate": "2025-06-01T00:00:00Z",
        "toDate": "2025-08-31T23:59:59Z",
        "specialConditions": "Minimum purchase of R500 required",
    }


@pytest.fixture
def sample_campaign_item():
    """Sample DynamoDB campaign item."""
    return {
        "PK": "CAMPAIGN#SUMMER2025",
        "SK": "METADATA",
        "entityType": "CAMPAIGN",
        "code": "SUMMER2025",
        "name": "Summer Sale 2025",
        "productId": "PROD-002",
        "discountPercent": 20,
        "listPrice": Decimal("1500.00"),
        "price": Decimal("1200.00"),
        "termsAndConditions": "Valid for new customers only.",
        "status": "ACTIVE",
        "fromDate": "2025-06-01T00:00:00Z",
        "toDate": "2025-08-31T23:59:59Z",
        "specialConditions": "Minimum purchase of R500 required",
        "dateCreated": "2025-05-15T10:00:00Z",
        "dateLastUpdated": "2025-05-20T14:30:00Z",
        "lastUpdatedBy": "system",
        "active": True,
        "GSI1_PK": "CAMPAIGN",
        "GSI1_SK": "ACTIVE#SUMMER2025",
    }


@pytest.fixture
def api_gateway_event():
    """Sample API Gateway event."""
    return {
        "httpMethod": "GET",
        "path": "/v1.0/campaigns",
        "headers": {
            "Content-Type": "application/json",
            "Accept": "application/json",
        },
        "pathParameters": None,
        "queryStringParameters": None,
        "body": None,
        "requestContext": {
            "requestId": "test-request-id",
            "stage": "v1",
        },
    }


@pytest.fixture
def lambda_context():
    """Mock Lambda context."""

    class MockContext:
        function_name = "test-function"
        memory_limit_in_mb = 256
        invoked_function_arn = "arn:aws:lambda:eu-west-1:123456789:function:test"
        aws_request_id = "test-request-id"
        log_group_name = "/aws/lambda/test-function"
        log_stream_name = "2025/01/15/[$LATEST]test"

        def get_remaining_time_in_millis(self):
            return 30000

    return MockContext()
```

---

## Success Criteria

- [ ] All __init__.py files created
- [ ] requirements.txt has production dependencies
- [ ] requirements-dev.txt has development dependencies
- [ ] pyproject.toml configured correctly
- [ ] pytest fixtures created in conftest.py
- [ ] Mock DynamoDB table configured
- [ ] Sample test data fixtures created

---

## Execution Steps

1. Create all __init__.py files in src/ packages
2. Create all __init__.py files in tests/ packages
3. Create requirements.txt with production deps
4. Create requirements-dev.txt with dev deps
5. Create pyproject.toml with tool configs
6. Create tests/conftest.py with fixtures
7. Verify imports work correctly
8. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-15
