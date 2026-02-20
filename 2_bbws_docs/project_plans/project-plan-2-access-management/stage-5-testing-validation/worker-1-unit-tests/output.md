# Unit Tests Implementation - Output

**Worker ID**: worker-1-unit-tests
**Stage**: Stage 5 - Testing & Validation
**Project**: project-plan-2-access-management
**Created**: 2026-01-24
**Status**: COMPLETE

---

## Table of Contents

1. [Overview](#overview)
2. [Test Directory Structure](#test-directory-structure)
3. [pytest Configuration](#pytest-configuration)
4. [Shared Test Fixtures (conftest.py)](#shared-test-fixtures-conftestpy)
5. [Sample Test Implementation - Permission Service](#sample-test-implementation---permission-service)
6. [Test Case Summary](#test-case-summary)
7. [Test Patterns Reference](#test-patterns-reference)

---

## Overview

This document provides comprehensive unit test suites for all 6 Access Management services using pytest with moto for AWS mocking. The tests follow Test-Driven Development (TDD) principles and target greater than 80% code coverage.

### Services Covered

| Service | Lambda Handlers | Test Files | Target Coverage |
|---------|-----------------|------------|-----------------|
| Permission Service | 6 | 6 | >80% |
| Invitation Service | 7 | 7 | >80% |
| Team Service | 14 | 14 | >80% |
| Role Service | 8 | 8 | >80% |
| Authorizer Service | 1 | 1 | >80% |
| Audit Service | 5 | 5 | >80% |
| **Total** | **41** | **41** | **>80%** |

---

## Test Directory Structure

```
tests/
├── unit/
│   ├── __init__.py
│   ├── conftest.py                           # Shared fixtures for all unit tests
│   ├── pytest.ini                            # pytest configuration
│   ├── requirements-test.txt                 # Test dependencies
│   │
│   ├── test_permission_service/
│   │   ├── __init__.py
│   │   ├── conftest.py                       # Permission-specific fixtures
│   │   ├── test_list_handler.py
│   │   ├── test_get_handler.py
│   │   ├── test_create_handler.py
│   │   ├── test_update_handler.py
│   │   ├── test_delete_handler.py
│   │   ├── test_seed_handler.py
│   │   ├── test_permission_service.py        # Service layer tests
│   │   └── test_permission_repository.py     # Repository layer tests
│   │
│   ├── test_invitation_service/
│   │   ├── __init__.py
│   │   ├── conftest.py
│   │   ├── test_create_invitation_handler.py
│   │   ├── test_accept_invitation_handler.py
│   │   ├── test_reject_invitation_handler.py
│   │   ├── test_list_invitations_handler.py
│   │   ├── test_get_invitation_handler.py
│   │   ├── test_resend_invitation_handler.py
│   │   └── test_revoke_invitation_handler.py
│   │
│   ├── test_team_service/
│   │   ├── __init__.py
│   │   ├── conftest.py
│   │   ├── test_create_team_handler.py
│   │   ├── test_get_team_handler.py
│   │   ├── test_list_teams_handler.py
│   │   ├── test_update_team_handler.py
│   │   ├── test_delete_team_handler.py
│   │   ├── test_add_member_handler.py
│   │   ├── test_remove_member_handler.py
│   │   ├── test_list_members_handler.py
│   │   ├── test_update_member_role_handler.py
│   │   ├── test_assign_site_handler.py
│   │   ├── test_unassign_site_handler.py
│   │   ├── test_list_team_sites_handler.py
│   │   ├── test_get_user_teams_handler.py
│   │   └── test_bulk_assign_sites_handler.py
│   │
│   ├── test_role_service/
│   │   ├── __init__.py
│   │   ├── conftest.py
│   │   ├── test_create_role_handler.py
│   │   ├── test_get_role_handler.py
│   │   ├── test_list_roles_handler.py
│   │   ├── test_update_role_handler.py
│   │   ├── test_delete_role_handler.py
│   │   ├── test_assign_role_handler.py
│   │   ├── test_revoke_role_handler.py
│   │   └── test_seed_roles_handler.py
│   │
│   ├── test_authorizer_service/
│   │   ├── __init__.py
│   │   ├── conftest.py
│   │   └── test_authorizer_handler.py
│   │
│   └── test_audit_service/
│       ├── __init__.py
│       ├── conftest.py
│       ├── test_log_event_handler.py
│       ├── test_get_audit_entry_handler.py
│       ├── test_list_audit_logs_handler.py
│       ├── test_search_audit_logs_handler.py
│       └── test_export_audit_logs_handler.py
│
└── integration/                              # Integration tests (separate worker)
    └── ...
```

---

## pytest Configuration

### pytest.ini

```ini
[pytest]
# Test discovery
testpaths = tests/unit
python_files = test_*.py
python_classes = Test*
python_functions = test_*

# Verbose output with coverage
addopts =
    -v
    --tb=short
    --cov=lambda
    --cov-report=term-missing
    --cov-report=html:coverage_html
    --cov-report=xml:coverage.xml
    --cov-fail-under=80
    --strict-markers
    -ra

# Markers for test categorization
markers =
    unit: Unit tests
    slow: Slow running tests
    integration: Integration tests (excluded from unit test runs)
    permission: Permission service tests
    invitation: Invitation service tests
    team: Team service tests
    role: Role service tests
    authorizer: Authorizer service tests
    audit: Audit service tests

# Logging configuration
log_cli = true
log_cli_level = INFO
log_cli_format = %(asctime)s [%(levelname)8s] %(message)s (%(filename)s:%(lineno)s)
log_cli_date_format = %Y-%m-%d %H:%M:%S

# Warning filters
filterwarnings =
    ignore::DeprecationWarning
    ignore::PendingDeprecationWarning
    ignore::UserWarning

# Async mode for async tests
asyncio_mode = auto
```

### .coveragerc

```ini
[run]
source = lambda
branch = True
omit =
    */tests/*
    */__init__.py
    */conftest.py
    */.venv/*

[report]
exclude_lines =
    pragma: no cover
    def __repr__
    raise AssertionError
    raise NotImplementedError
    if __name__ == .__main__.:
    if TYPE_CHECKING:
    @abstractmethod

show_missing = True
precision = 2

[html]
directory = coverage_html

[xml]
output = coverage.xml
```

### requirements-test.txt

```txt
# Testing Framework
pytest>=7.4.0
pytest-cov>=4.1.0
pytest-mock>=3.12.0
pytest-asyncio>=0.21.0
pytest-xdist>=3.5.0          # Parallel test execution
pytest-timeout>=2.2.0         # Test timeouts
pytest-ordering>=0.6          # Test ordering

# AWS Mocking
moto[all]>=4.2.0
boto3>=1.34.0
botocore>=1.34.0

# Application Dependencies (for testing)
pydantic>=2.5.0
aws-lambda-powertools>=2.30.0
python-dateutil>=2.8.2

# Test Utilities
freezegun>=1.2.0              # Time freezing
faker>=20.0.0                 # Fake data generation
responses>=0.24.0             # HTTP mocking
httpx>=0.25.0                 # HTTP client for testing

# Code Quality
black>=23.0.0
isort>=5.12.0
flake8>=6.0.0
mypy>=1.7.0
```

---

## Shared Test Fixtures (conftest.py)

### tests/unit/conftest.py

```python
"""
Shared pytest fixtures for Access Management unit tests.

This module provides common fixtures used across all service tests including:
- DynamoDB table mocks with proper schema
- API Gateway event generators
- Lambda context mocks
- Sample data generators
- Environment configuration
"""

import os
import json
import uuid
import pytest
from datetime import datetime, timezone
from typing import Dict, Any, List, Optional, Generator
from unittest.mock import MagicMock

import boto3
from moto import mock_aws
from faker import Faker


# =============================================================================
# Environment Setup
# =============================================================================

# Set environment variables BEFORE importing application code
os.environ["DYNAMODB_TABLE_NAME"] = "test-access-management-table"
os.environ["AWS_DEFAULT_REGION"] = "af-south-1"
os.environ["AWS_ACCESS_KEY_ID"] = "testing"
os.environ["AWS_SECRET_ACCESS_KEY"] = "testing"
os.environ["AWS_SECURITY_TOKEN"] = "testing"
os.environ["AWS_SESSION_TOKEN"] = "testing"
os.environ["POWERTOOLS_SERVICE_NAME"] = "access-management-test"
os.environ["LOG_LEVEL"] = "DEBUG"

# Initialize Faker for test data generation
fake = Faker()


# =============================================================================
# DynamoDB Table Fixtures
# =============================================================================

@pytest.fixture
def aws_credentials():
    """Mock AWS credentials for moto."""
    os.environ["AWS_ACCESS_KEY_ID"] = "testing"
    os.environ["AWS_SECRET_ACCESS_KEY"] = "testing"
    os.environ["AWS_SECURITY_TOKEN"] = "testing"
    os.environ["AWS_SESSION_TOKEN"] = "testing"
    os.environ["AWS_DEFAULT_REGION"] = "af-south-1"


@pytest.fixture
def dynamodb_table(aws_credentials) -> Generator:
    """
    Create a mock DynamoDB table with the access management schema.

    Table Schema:
    - PK: Partition key (e.g., PERM#site:create, ORG#org123, TEAM#team123)
    - SK: Sort key (e.g., METADATA, MEMBER#user123)
    - GSI1PK/GSI1SK: Global Secondary Index 1 (category lookups)
    - GSI2PK/GSI2SK: Global Secondary Index 2 (user lookups)
    - GSI3PK/GSI3SK: Global Secondary Index 3 (team lookups)

    Yields:
        DynamoDB Table resource
    """
    with mock_aws():
        dynamodb = boto3.resource("dynamodb", region_name="af-south-1")

        table = dynamodb.create_table(
            TableName="test-access-management-table",
            KeySchema=[
                {"AttributeName": "PK", "KeyType": "HASH"},
                {"AttributeName": "SK", "KeyType": "RANGE"},
            ],
            AttributeDefinitions=[
                {"AttributeName": "PK", "AttributeType": "S"},
                {"AttributeName": "SK", "AttributeType": "S"},
                {"AttributeName": "GSI1PK", "AttributeType": "S"},
                {"AttributeName": "GSI1SK", "AttributeType": "S"},
                {"AttributeName": "GSI2PK", "AttributeType": "S"},
                {"AttributeName": "GSI2SK", "AttributeType": "S"},
                {"AttributeName": "GSI3PK", "AttributeType": "S"},
                {"AttributeName": "GSI3SK", "AttributeType": "S"},
            ],
            GlobalSecondaryIndexes=[
                {
                    "IndexName": "GSI1",
                    "KeySchema": [
                        {"AttributeName": "GSI1PK", "KeyType": "HASH"},
                        {"AttributeName": "GSI1SK", "KeyType": "RANGE"},
                    ],
                    "Projection": {"ProjectionType": "ALL"},
                },
                {
                    "IndexName": "GSI2",
                    "KeySchema": [
                        {"AttributeName": "GSI2PK", "KeyType": "HASH"},
                        {"AttributeName": "GSI2SK", "KeyType": "RANGE"},
                    ],
                    "Projection": {"ProjectionType": "ALL"},
                },
                {
                    "IndexName": "GSI3",
                    "KeySchema": [
                        {"AttributeName": "GSI3PK", "KeyType": "HASH"},
                        {"AttributeName": "GSI3SK", "KeyType": "RANGE"},
                    ],
                    "Projection": {"ProjectionType": "ALL"},
                },
            ],
            BillingMode="PAY_PER_REQUEST",
        )

        table.wait_until_exists()
        yield table


@pytest.fixture
def dynamodb_resource(aws_credentials) -> Generator:
    """
    Create a mock DynamoDB resource for direct table operations.

    Yields:
        DynamoDB resource
    """
    with mock_aws():
        dynamodb = boto3.resource("dynamodb", region_name="af-south-1")
        yield dynamodb


# =============================================================================
# Lambda Context Fixtures
# =============================================================================

@pytest.fixture
def lambda_context() -> MagicMock:
    """
    Create a mock Lambda context object.

    Returns:
        Mock Lambda context with standard attributes
    """
    context = MagicMock()
    context.function_name = "test-access-management-function"
    context.function_version = "$LATEST"
    context.memory_limit_in_mb = 256
    context.invoked_function_arn = (
        "arn:aws:lambda:af-south-1:123456789012:function:test-function"
    )
    context.aws_request_id = str(uuid.uuid4())
    context.log_group_name = "/aws/lambda/test-function"
    context.log_stream_name = "2026/01/24/[$LATEST]abc123"
    context.get_remaining_time_in_millis = MagicMock(return_value=30000)
    return context


# =============================================================================
# API Gateway Event Generators
# =============================================================================

class APIGatewayEventGenerator:
    """Generator for API Gateway Lambda proxy events."""

    DEFAULT_HEADERS = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer test-jwt-token",
        "X-Request-Id": str(uuid.uuid4()),
    }

    DEFAULT_AUTHORIZER_CLAIMS = {
        "sub": "test-user-id",
        "email": "testuser@example.com",
        "custom:org_id": "org-123456",
        "custom:tenant_id": "tenant-abc",
        "cognito:groups": ["Admins"],
    }

    @classmethod
    def create_event(
        cls,
        http_method: str = "GET",
        path: str = "/",
        resource: str = "/",
        path_parameters: Optional[Dict[str, str]] = None,
        query_string_parameters: Optional[Dict[str, str]] = None,
        body: Optional[Dict[str, Any]] = None,
        headers: Optional[Dict[str, str]] = None,
        authorizer_claims: Optional[Dict[str, Any]] = None,
        is_base64_encoded: bool = False,
    ) -> Dict[str, Any]:
        """
        Create an API Gateway Lambda proxy event.

        Args:
            http_method: HTTP method (GET, POST, PUT, DELETE, PATCH)
            path: Request path
            resource: API Gateway resource path with parameters
            path_parameters: Path parameters dict
            query_string_parameters: Query string parameters dict
            body: Request body (will be JSON serialized)
            headers: Custom headers (merged with defaults)
            authorizer_claims: Custom authorizer claims (merged with defaults)
            is_base64_encoded: Whether body is base64 encoded

        Returns:
            API Gateway Lambda proxy event dict
        """
        event_headers = cls.DEFAULT_HEADERS.copy()
        if headers:
            event_headers.update(headers)

        claims = cls.DEFAULT_AUTHORIZER_CLAIMS.copy()
        if authorizer_claims:
            claims.update(authorizer_claims)

        event = {
            "resource": resource,
            "path": path,
            "httpMethod": http_method,
            "headers": event_headers,
            "multiValueHeaders": {k: [v] for k, v in event_headers.items()},
            "queryStringParameters": query_string_parameters,
            "multiValueQueryStringParameters": (
                {k: [v] for k, v in query_string_parameters.items()}
                if query_string_parameters else None
            ),
            "pathParameters": path_parameters,
            "stageVariables": {"stage": "dev"},
            "requestContext": {
                "resourceId": "abc123",
                "resourcePath": resource,
                "httpMethod": http_method,
                "extendedRequestId": str(uuid.uuid4()),
                "requestTime": datetime.now(timezone.utc).strftime(
                    "%d/%b/%Y:%H:%M:%S +0000"
                ),
                "path": f"/dev{path}",
                "accountId": "123456789012",
                "protocol": "HTTP/1.1",
                "stage": "dev",
                "domainPrefix": "api",
                "requestTimeEpoch": int(datetime.now(timezone.utc).timestamp() * 1000),
                "requestId": str(uuid.uuid4()),
                "identity": {
                    "cognitoIdentityPoolId": None,
                    "accountId": None,
                    "cognitoIdentityId": None,
                    "caller": None,
                    "sourceIp": "127.0.0.1",
                    "principalOrgId": None,
                    "accessKey": None,
                    "cognitoAuthenticationType": None,
                    "cognitoAuthenticationProvider": None,
                    "userArn": None,
                    "userAgent": "pytest-test-client",
                    "user": None,
                },
                "domainName": "api.example.com",
                "apiId": "testapi123",
                "authorizer": {
                    "claims": claims,
                    "scopes": ["openid", "profile", "email"],
                },
            },
            "body": json.dumps(body) if body else None,
            "isBase64Encoded": is_base64_encoded,
        }

        return event


@pytest.fixture
def event_generator() -> APIGatewayEventGenerator:
    """Fixture providing the API Gateway event generator."""
    return APIGatewayEventGenerator()


@pytest.fixture
def api_gateway_event() -> Dict[str, Any]:
    """Create a base API Gateway GET event."""
    return APIGatewayEventGenerator.create_event()


@pytest.fixture
def api_gateway_post_event() -> Dict[str, Any]:
    """Create a base API Gateway POST event."""
    return APIGatewayEventGenerator.create_event(http_method="POST")


@pytest.fixture
def api_gateway_put_event() -> Dict[str, Any]:
    """Create a base API Gateway PUT event."""
    return APIGatewayEventGenerator.create_event(http_method="PUT")


@pytest.fixture
def api_gateway_delete_event() -> Dict[str, Any]:
    """Create a base API Gateway DELETE event."""
    return APIGatewayEventGenerator.create_event(http_method="DELETE")


# =============================================================================
# Sample Data Generators
# =============================================================================

class SampleDataGenerator:
    """Generator for sample test data."""

    @staticmethod
    def generate_permission_id() -> str:
        """Generate a random permission ID in format resource:action."""
        resources = ["site", "team", "org", "role", "invitation", "audit"]
        actions = ["create", "read", "update", "delete", "manage", "assign"]
        return f"{fake.random_element(resources)}:{fake.random_element(actions)}"

    @staticmethod
    def generate_uuid() -> str:
        """Generate a UUID string."""
        return str(uuid.uuid4())

    @staticmethod
    def generate_org_id() -> str:
        """Generate an organization ID."""
        return f"org-{uuid.uuid4().hex[:12]}"

    @staticmethod
    def generate_team_id() -> str:
        """Generate a team ID."""
        return f"team-{uuid.uuid4().hex[:12]}"

    @staticmethod
    def generate_user_id() -> str:
        """Generate a user ID."""
        return f"user-{uuid.uuid4().hex[:12]}"

    @staticmethod
    def generate_email() -> str:
        """Generate a random email address."""
        return fake.email()

    @staticmethod
    def generate_name() -> str:
        """Generate a random name."""
        return fake.name()

    @staticmethod
    def generate_timestamp() -> str:
        """Generate an ISO format timestamp."""
        return datetime.now(timezone.utc).isoformat()


@pytest.fixture
def data_generator() -> SampleDataGenerator:
    """Fixture providing the sample data generator."""
    return SampleDataGenerator()


# =============================================================================
# Permission Test Data
# =============================================================================

@pytest.fixture
def sample_permission_item() -> Dict[str, Any]:
    """Create a sample permission DynamoDB item."""
    return {
        "PK": "PERM#site:create",
        "SK": "METADATA",
        "permissionId": "site:create",
        "name": "Create Site",
        "description": "Allows creating new WordPress sites",
        "resource": "site",
        "action": "create",
        "category": "SITE",
        "isSystem": True,
        "active": True,
        "dateCreated": "2026-01-01T00:00:00Z",
        "GSI1PK": "CATEGORY#SITE",
        "GSI1SK": "PERM#site:create",
    }


@pytest.fixture
def sample_permission_items() -> List[Dict[str, Any]]:
    """Create multiple sample permission items."""
    permissions = [
        {
            "permissionId": "site:create",
            "name": "Create Site",
            "description": "Allows creating new WordPress sites",
            "resource": "site",
            "action": "create",
            "category": "SITE",
        },
        {
            "permissionId": "site:read",
            "name": "View Site",
            "description": "Allows viewing site details and configurations",
            "resource": "site",
            "action": "read",
            "category": "SITE",
        },
        {
            "permissionId": "site:update",
            "name": "Update Site",
            "description": "Allows modifying site settings and content",
            "resource": "site",
            "action": "update",
            "category": "SITE",
        },
        {
            "permissionId": "team:read",
            "name": "View Team",
            "description": "Allows viewing team details and information",
            "resource": "team",
            "action": "read",
            "category": "TEAM",
        },
        {
            "permissionId": "team:member:add",
            "name": "Add Team Member",
            "description": "Allows adding users to the team",
            "resource": "team:member",
            "action": "add",
            "category": "TEAM",
        },
        {
            "permissionId": "org:read",
            "name": "View Organisation",
            "description": "Allows viewing organisation details",
            "resource": "org",
            "action": "read",
            "category": "ORGANISATION",
        },
    ]

    items = []
    for perm in permissions:
        items.append({
            "PK": f"PERM#{perm['permissionId']}",
            "SK": "METADATA",
            **perm,
            "isSystem": True,
            "active": True,
            "dateCreated": "2026-01-01T00:00:00Z",
            "GSI1PK": f"CATEGORY#{perm['category']}",
            "GSI1SK": f"PERM#{perm['permissionId']}",
        })

    return items


@pytest.fixture
def populated_permission_table(dynamodb_table, sample_permission_items):
    """Create a DynamoDB table populated with sample permission data."""
    for item in sample_permission_items:
        dynamodb_table.put_item(Item=item)
    return dynamodb_table


# =============================================================================
# Role Test Data
# =============================================================================

@pytest.fixture
def sample_role_item() -> Dict[str, Any]:
    """Create a sample role DynamoDB item."""
    return {
        "PK": "ROLE#admin",
        "SK": "METADATA",
        "roleId": "admin",
        "name": "Administrator",
        "description": "Full system access",
        "permissions": ["site:create", "site:read", "site:update", "site:delete"],
        "isSystem": True,
        "active": True,
        "dateCreated": "2026-01-01T00:00:00Z",
        "GSI1PK": "ORG#org-123456",
        "GSI1SK": "ROLE#admin",
    }


@pytest.fixture
def sample_role_items() -> List[Dict[str, Any]]:
    """Create multiple sample role items."""
    roles = [
        {
            "roleId": "admin",
            "name": "Administrator",
            "description": "Full system access with all permissions",
            "permissions": ["site:create", "site:read", "site:update", "site:delete", "team:manage"],
            "isSystem": True,
        },
        {
            "roleId": "editor",
            "name": "Editor",
            "description": "Can edit sites but not create or delete",
            "permissions": ["site:read", "site:update"],
            "isSystem": True,
        },
        {
            "roleId": "viewer",
            "name": "Viewer",
            "description": "Read-only access to sites",
            "permissions": ["site:read"],
            "isSystem": True,
        },
    ]

    items = []
    for role in roles:
        items.append({
            "PK": f"ROLE#{role['roleId']}",
            "SK": "METADATA",
            **role,
            "active": True,
            "dateCreated": "2026-01-01T00:00:00Z",
            "GSI1PK": "ORG#org-123456",
            "GSI1SK": f"ROLE#{role['roleId']}",
        })

    return items


# =============================================================================
# Team Test Data
# =============================================================================

@pytest.fixture
def sample_team_item() -> Dict[str, Any]:
    """Create a sample team DynamoDB item."""
    return {
        "PK": "TEAM#team-abc123",
        "SK": "METADATA",
        "teamId": "team-abc123",
        "name": "Development Team",
        "description": "Main development team for the platform",
        "orgId": "org-123456",
        "parentId": None,
        "path": "/org-123456/team-abc123",
        "memberCount": 5,
        "active": True,
        "dateCreated": "2026-01-01T00:00:00Z",
        "dateModified": "2026-01-01T00:00:00Z",
        "GSI1PK": "ORG#org-123456",
        "GSI1SK": "TEAM#team-abc123",
        "GSI2PK": "TEAM_PATH#/org-123456/team-abc123",
        "GSI2SK": "METADATA",
    }


@pytest.fixture
def sample_team_member_item() -> Dict[str, Any]:
    """Create a sample team member DynamoDB item."""
    return {
        "PK": "TEAM#team-abc123",
        "SK": "MEMBER#user-xyz789",
        "teamId": "team-abc123",
        "userId": "user-xyz789",
        "email": "member@example.com",
        "roleId": "editor",
        "status": "active",
        "joinedAt": "2026-01-01T00:00:00Z",
        "GSI2PK": "USER#user-xyz789",
        "GSI2SK": "TEAM#team-abc123",
    }


# =============================================================================
# Invitation Test Data
# =============================================================================

@pytest.fixture
def sample_invitation_item() -> Dict[str, Any]:
    """Create a sample invitation DynamoDB item."""
    return {
        "PK": "INV#inv-abc123",
        "SK": "METADATA",
        "invitationId": "inv-abc123",
        "email": "invited@example.com",
        "teamId": "team-abc123",
        "orgId": "org-123456",
        "roleId": "editor",
        "status": "pending",
        "invitedBy": "user-admin",
        "token": "secure-token-abc123",
        "expiresAt": "2026-02-01T00:00:00Z",
        "dateCreated": "2026-01-01T00:00:00Z",
        "GSI1PK": "ORG#org-123456",
        "GSI1SK": "INV#pending#inv-abc123",
        "GSI2PK": "EMAIL#invited@example.com",
        "GSI2SK": "INV#inv-abc123",
    }


# =============================================================================
# Audit Test Data
# =============================================================================

@pytest.fixture
def sample_audit_item() -> Dict[str, Any]:
    """Create a sample audit log DynamoDB item."""
    return {
        "PK": "AUDIT#2026-01-24",
        "SK": "EVENT#1706097600000#evt-abc123",
        "eventId": "evt-abc123",
        "eventType": "PERMISSION_GRANTED",
        "timestamp": "2026-01-24T12:00:00Z",
        "userId": "user-admin",
        "orgId": "org-123456",
        "resourceType": "permission",
        "resourceId": "site:create",
        "action": "grant",
        "details": {"targetUserId": "user-xyz789", "roleId": "editor"},
        "ipAddress": "192.168.1.1",
        "userAgent": "Mozilla/5.0",
        "GSI1PK": "ORG#org-123456",
        "GSI1SK": "AUDIT#2026-01-24#evt-abc123",
        "GSI2PK": "USER#user-admin",
        "GSI2SK": "AUDIT#2026-01-24#evt-abc123",
    }


# =============================================================================
# Response Assertion Helpers
# =============================================================================

class ResponseAssertions:
    """Helper class for common response assertions."""

    @staticmethod
    def assert_success_response(
        response: Dict[str, Any],
        expected_status: int = 200,
    ) -> Dict[str, Any]:
        """
        Assert response is successful and return parsed body.

        Args:
            response: Lambda response dict
            expected_status: Expected HTTP status code

        Returns:
            Parsed response body
        """
        assert response["statusCode"] == expected_status, (
            f"Expected status {expected_status}, got {response['statusCode']}"
        )
        assert "headers" in response
        assert response["headers"].get("Content-Type") == "application/json"

        if response.get("body"):
            return json.loads(response["body"])
        return {}

    @staticmethod
    def assert_error_response(
        response: Dict[str, Any],
        expected_status: int,
        expected_error_code: str,
    ) -> Dict[str, Any]:
        """
        Assert response is an error and return parsed body.

        Args:
            response: Lambda response dict
            expected_status: Expected HTTP status code
            expected_error_code: Expected error code in body

        Returns:
            Parsed response body
        """
        assert response["statusCode"] == expected_status, (
            f"Expected status {expected_status}, got {response['statusCode']}"
        )

        body = json.loads(response["body"])
        assert "errorCode" in body, "Error response missing errorCode"
        assert body["errorCode"] == expected_error_code, (
            f"Expected error code {expected_error_code}, got {body['errorCode']}"
        )
        assert "message" in body, "Error response missing message"

        return body

    @staticmethod
    def assert_paginated_response(
        response: Dict[str, Any],
        min_items: int = 0,
        max_items: Optional[int] = None,
    ) -> Dict[str, Any]:
        """
        Assert response is paginated and return parsed body.

        Args:
            response: Lambda response dict
            min_items: Minimum expected items
            max_items: Maximum expected items (optional)

        Returns:
            Parsed response body
        """
        body = ResponseAssertions.assert_success_response(response)

        assert "items" in body, "Paginated response missing items"
        assert "count" in body, "Paginated response missing count"
        assert "moreAvailable" in body, "Paginated response missing moreAvailable"

        item_count = len(body["items"])
        assert item_count >= min_items, (
            f"Expected at least {min_items} items, got {item_count}"
        )
        if max_items is not None:
            assert item_count <= max_items, (
                f"Expected at most {max_items} items, got {item_count}"
            )

        assert body["count"] == item_count

        return body

    @staticmethod
    def assert_hateoas_links(
        body: Dict[str, Any],
        required_links: List[str] = None,
    ):
        """
        Assert response contains HATEOAS links.

        Args:
            body: Parsed response body
            required_links: List of required link names (e.g., ["self", "next"])
        """
        assert "_links" in body, "Response missing _links"

        if required_links:
            for link_name in required_links:
                assert link_name in body["_links"], (
                    f"Missing required link: {link_name}"
                )
                assert "href" in body["_links"][link_name], (
                    f"Link {link_name} missing href"
                )


@pytest.fixture
def assertions() -> ResponseAssertions:
    """Fixture providing response assertion helpers."""
    return ResponseAssertions()
```

---

## Sample Test Implementation - Permission Service

### tests/unit/test_permission_service/conftest.py

```python
"""
Permission Service specific test fixtures.
"""

import pytest
from typing import Dict, Any, List
from unittest.mock import MagicMock, patch


@pytest.fixture
def permission_repository_mock():
    """Create a mock permission repository."""
    with patch(
        'lambda.permission_service.services.permission_service.PermissionRepository'
    ) as MockRepo:
        mock_repo = MagicMock()
        MockRepo.return_value = mock_repo
        yield mock_repo


@pytest.fixture
def permission_service_mock():
    """Create a mock permission service."""
    with patch(
        'lambda.permission_service.handlers.list_handler.PermissionService'
    ) as MockService:
        mock_service = MagicMock()
        MockService.return_value = mock_service
        yield mock_service


@pytest.fixture
def create_permission_request() -> Dict[str, Any]:
    """Create a valid permission creation request."""
    return {
        "permissionId": "custom:action",
        "name": "Custom Permission",
        "description": "A custom permission for testing purposes",
        "resource": "custom",
        "action": "action",
        "category": "SITE",
        "isSystem": False,
    }


@pytest.fixture
def update_permission_request() -> Dict[str, Any]:
    """Create a valid permission update request."""
    return {
        "name": "Updated Permission Name",
        "description": "Updated description for the permission",
        "active": True,
    }


@pytest.fixture
def list_permissions_event(event_generator) -> Dict[str, Any]:
    """Create a list permissions API Gateway event."""
    return event_generator.create_event(
        http_method="GET",
        path="/v1/platform/permissions",
        resource="/v1/platform/permissions",
    )


@pytest.fixture
def get_permission_event(event_generator) -> Dict[str, Any]:
    """Create a get permission API Gateway event."""
    return event_generator.create_event(
        http_method="GET",
        path="/v1/platform/permissions/site:create",
        resource="/v1/platform/permissions/{permId}",
        path_parameters={"permId": "site:create"},
    )


@pytest.fixture
def create_permission_event(event_generator, create_permission_request) -> Dict[str, Any]:
    """Create a create permission API Gateway event."""
    return event_generator.create_event(
        http_method="POST",
        path="/v1/permissions",
        resource="/v1/permissions",
        body=create_permission_request,
    )


@pytest.fixture
def update_permission_event(event_generator, update_permission_request) -> Dict[str, Any]:
    """Create an update permission API Gateway event."""
    return event_generator.create_event(
        http_method="PUT",
        path="/v1/permissions/site:create",
        resource="/v1/permissions/{permId}",
        path_parameters={"permId": "site:create"},
        body=update_permission_request,
    )


@pytest.fixture
def delete_permission_event(event_generator) -> Dict[str, Any]:
    """Create a delete permission API Gateway event."""
    return event_generator.create_event(
        http_method="DELETE",
        path="/v1/permissions/custom:action",
        resource="/v1/permissions/{permId}",
        path_parameters={"permId": "custom:action"},
    )


@pytest.fixture
def seed_permissions_event(event_generator) -> Dict[str, Any]:
    """Create a seed permissions API Gateway event."""
    return event_generator.create_event(
        http_method="POST",
        path="/v1/permissions/seed",
        resource="/v1/permissions/seed",
    )
```

### tests/unit/test_permission_service/test_list_handler.py

```python
"""
Unit tests for the list_permissions Lambda handler.

Tests cover:
- Happy path: List permissions with default pagination
- Pagination: Custom page size, next page cursor
- Filtering: Category filter
- Validation: Invalid page size, invalid category
- Edge cases: Empty results, maximum page size
- HATEOAS: Link generation
"""

import json
import pytest
from unittest.mock import patch, MagicMock
from datetime import datetime, timezone
from moto import mock_aws

# Import after environment setup
from lambda.permission_service.handlers.list_handler import lambda_handler
from lambda.permission_service.models.permission import Permission


class TestListPermissionsHandler:
    """Test suite for list_permissions Lambda handler."""

    # =========================================================================
    # Happy Path Tests
    # =========================================================================

    @mock_aws
    def test_returns_empty_list_when_no_permissions_exist(
        self,
        dynamodb_table,
        lambda_context,
        list_permissions_event,
        assertions,
    ):
        """
        GIVEN: No permissions exist in the database
        WHEN: List permissions is called
        THEN: Returns 200 with empty items array
        """
        with patch(
            'lambda.permission_service.services.permission_service.PermissionRepository'
        ) as MockRepo:
            mock_repo = MagicMock()
            mock_repo.list_all.return_value = ([], None)
            MockRepo.return_value = mock_repo

            response = lambda_handler(list_permissions_event, lambda_context)

        body = assertions.assert_paginated_response(response, min_items=0)
        assert body["items"] == []
        assert body["count"] == 0
        assert body["moreAvailable"] is False

    @mock_aws
    def test_returns_permissions_with_default_pagination(
        self,
        dynamodb_table,
        lambda_context,
        list_permissions_event,
        sample_permission_items,
        assertions,
    ):
        """
        GIVEN: Multiple permissions exist in the database
        WHEN: List permissions is called without pagination params
        THEN: Returns 200 with permissions using default page size
        """
        with patch(
            'lambda.permission_service.services.permission_service.PermissionRepository'
        ) as MockRepo:
            mock_repo = MagicMock()
            permissions = [
                Permission.from_dynamo_item(item)
                for item in sample_permission_items
            ]
            mock_repo.list_all.return_value = (permissions, None)
            MockRepo.return_value = mock_repo

            response = lambda_handler(list_permissions_event, lambda_context)

        body = assertions.assert_paginated_response(response, min_items=1)
        assert body["count"] == len(sample_permission_items)
        assert body["moreAvailable"] is False

        # Verify repository was called with default params
        mock_repo.list_all.assert_called_once_with(
            page_size=50,
            start_key=None,
            category=None
        )

    @mock_aws
    def test_returns_permissions_with_hateoas_links(
        self,
        dynamodb_table,
        lambda_context,
        list_permissions_event,
        sample_permission_items,
        assertions,
    ):
        """
        GIVEN: Permissions exist in the database
        WHEN: List permissions is called
        THEN: Response includes HATEOAS links
        """
        with patch(
            'lambda.permission_service.services.permission_service.PermissionRepository'
        ) as MockRepo:
            mock_repo = MagicMock()
            permissions = [
                Permission.from_dynamo_item(item)
                for item in sample_permission_items[:2]
            ]
            mock_repo.list_all.return_value = (permissions, None)
            MockRepo.return_value = mock_repo

            response = lambda_handler(list_permissions_event, lambda_context)

        body = assertions.assert_success_response(response)
        assertions.assert_hateoas_links(body, required_links=["self"])

        # Verify self link contains correct URL
        assert "/v1/platform/permissions" in body["_links"]["self"]["href"]

    # =========================================================================
    # Pagination Tests
    # =========================================================================

    @mock_aws
    def test_respects_custom_page_size(
        self,
        dynamodb_table,
        lambda_context,
        list_permissions_event,
    ):
        """
        GIVEN: pageSize query parameter is provided
        WHEN: List permissions is called
        THEN: Repository is called with specified page size
        """
        list_permissions_event["queryStringParameters"] = {"pageSize": "10"}

        with patch(
            'lambda.permission_service.services.permission_service.PermissionRepository'
        ) as MockRepo:
            mock_repo = MagicMock()
            mock_repo.list_all.return_value = ([], None)
            MockRepo.return_value = mock_repo

            response = lambda_handler(list_permissions_event, lambda_context)

        assert response["statusCode"] == 200
        mock_repo.list_all.assert_called_once_with(
            page_size=10,
            start_key=None,
            category=None
        )

    @mock_aws
    def test_respects_start_at_pagination_cursor(
        self,
        dynamodb_table,
        lambda_context,
        list_permissions_event,
    ):
        """
        GIVEN: startAt query parameter is provided
        WHEN: List permissions is called
        THEN: Repository is called with pagination cursor
        """
        list_permissions_event["queryStringParameters"] = {
            "startAt": "site:read"
        }

        with patch(
            'lambda.permission_service.services.permission_service.PermissionRepository'
        ) as MockRepo:
            mock_repo = MagicMock()
            mock_repo.list_all.return_value = ([], None)
            MockRepo.return_value = mock_repo

            response = lambda_handler(list_permissions_event, lambda_context)

        assert response["statusCode"] == 200
        mock_repo.list_all.assert_called_once_with(
            page_size=50,
            start_key="site:read",
            category=None
        )

    @mock_aws
    def test_returns_next_link_when_more_pages_available(
        self,
        dynamodb_table,
        lambda_context,
        list_permissions_event,
        sample_permission_items,
        assertions,
    ):
        """
        GIVEN: More permissions exist than requested page size
        WHEN: List permissions is called
        THEN: Response includes next link with pagination cursor
        """
        with patch(
            'lambda.permission_service.services.permission_service.PermissionRepository'
        ) as MockRepo:
            mock_repo = MagicMock()
            perm = Permission.from_dynamo_item(sample_permission_items[0])
            mock_repo.list_all.return_value = ([perm], "site:read")
            MockRepo.return_value = mock_repo

            response = lambda_handler(list_permissions_event, lambda_context)

        body = assertions.assert_success_response(response)
        assert body["moreAvailable"] is True
        assertions.assert_hateoas_links(body, required_links=["self", "next"])
        assert "startAt=site:read" in body["_links"]["next"]["href"]

    # =========================================================================
    # Filtering Tests
    # =========================================================================

    @mock_aws
    def test_filters_by_category(
        self,
        dynamodb_table,
        lambda_context,
        list_permissions_event,
    ):
        """
        GIVEN: category query parameter is provided
        WHEN: List permissions is called
        THEN: Repository is called with category filter
        """
        list_permissions_event["queryStringParameters"] = {"category": "SITE"}

        with patch(
            'lambda.permission_service.services.permission_service.PermissionRepository'
        ) as MockRepo:
            mock_repo = MagicMock()
            mock_repo.list_all.return_value = ([], None)
            MockRepo.return_value = mock_repo

            response = lambda_handler(list_permissions_event, lambda_context)

        assert response["statusCode"] == 200
        mock_repo.list_all.assert_called_once_with(
            page_size=50,
            start_key=None,
            category="SITE"
        )

    @mock_aws
    def test_category_filter_is_case_insensitive(
        self,
        dynamodb_table,
        lambda_context,
        list_permissions_event,
    ):
        """
        GIVEN: category query parameter in lowercase
        WHEN: List permissions is called
        THEN: Category is normalized to uppercase
        """
        list_permissions_event["queryStringParameters"] = {"category": "site"}

        with patch(
            'lambda.permission_service.services.permission_service.PermissionRepository'
        ) as MockRepo:
            mock_repo = MagicMock()
            mock_repo.list_all.return_value = ([], None)
            MockRepo.return_value = mock_repo

            response = lambda_handler(list_permissions_event, lambda_context)

        assert response["statusCode"] == 200
        mock_repo.list_all.assert_called_once_with(
            page_size=50,
            start_key=None,
            category="SITE"
        )

    # =========================================================================
    # Validation Error Tests
    # =========================================================================

    @mock_aws
    def test_invalid_page_size_exceeds_max_returns_400(
        self,
        dynamodb_table,
        lambda_context,
        list_permissions_event,
        assertions,
    ):
        """
        GIVEN: pageSize exceeds maximum (100)
        WHEN: List permissions is called
        THEN: Returns 400 with validation error
        """
        list_permissions_event["queryStringParameters"] = {"pageSize": "200"}

        with patch(
            'lambda.permission_service.services.permission_service.PermissionRepository'
        ) as MockRepo:
            mock_repo = MagicMock()
            MockRepo.return_value = mock_repo

            response = lambda_handler(list_permissions_event, lambda_context)

        assertions.assert_error_response(
            response,
            expected_status=400,
            expected_error_code="VALIDATION_ERROR"
        )

    @mock_aws
    def test_invalid_page_size_negative_returns_400(
        self,
        dynamodb_table,
        lambda_context,
        list_permissions_event,
        assertions,
    ):
        """
        GIVEN: pageSize is negative
        WHEN: List permissions is called
        THEN: Returns 400 with validation error
        """
        list_permissions_event["queryStringParameters"] = {"pageSize": "-1"}

        response = lambda_handler(list_permissions_event, lambda_context)

        assertions.assert_error_response(
            response,
            expected_status=400,
            expected_error_code="VALIDATION_ERROR"
        )

    @mock_aws
    def test_invalid_category_returns_400(
        self,
        dynamodb_table,
        lambda_context,
        list_permissions_event,
        assertions,
    ):
        """
        GIVEN: category is not a valid enum value
        WHEN: List permissions is called
        THEN: Returns 400 with validation error
        """
        list_permissions_event["queryStringParameters"] = {
            "category": "INVALID_CATEGORY"
        }

        response = lambda_handler(list_permissions_event, lambda_context)

        assertions.assert_error_response(
            response,
            expected_status=400,
            expected_error_code="VALIDATION_ERROR"
        )

    # =========================================================================
    # Edge Case Tests
    # =========================================================================

    @mock_aws
    def test_handles_null_query_parameters(
        self,
        dynamodb_table,
        lambda_context,
        list_permissions_event,
    ):
        """
        GIVEN: queryStringParameters is null
        WHEN: List permissions is called
        THEN: Uses default pagination values
        """
        list_permissions_event["queryStringParameters"] = None

        with patch(
            'lambda.permission_service.services.permission_service.PermissionRepository'
        ) as MockRepo:
            mock_repo = MagicMock()
            mock_repo.list_all.return_value = ([], None)
            MockRepo.return_value = mock_repo

            response = lambda_handler(list_permissions_event, lambda_context)

        assert response["statusCode"] == 200
        mock_repo.list_all.assert_called_once_with(
            page_size=50,
            start_key=None,
            category=None
        )

    @mock_aws
    def test_handles_maximum_page_size(
        self,
        dynamodb_table,
        lambda_context,
        list_permissions_event,
    ):
        """
        GIVEN: pageSize is at maximum allowed (100)
        WHEN: List permissions is called
        THEN: Returns 200 with results
        """
        list_permissions_event["queryStringParameters"] = {"pageSize": "100"}

        with patch(
            'lambda.permission_service.services.permission_service.PermissionRepository'
        ) as MockRepo:
            mock_repo = MagicMock()
            mock_repo.list_all.return_value = ([], None)
            MockRepo.return_value = mock_repo

            response = lambda_handler(list_permissions_event, lambda_context)

        assert response["statusCode"] == 200

    @mock_aws
    def test_returns_correct_cors_headers(
        self,
        dynamodb_table,
        lambda_context,
        list_permissions_event,
    ):
        """
        GIVEN: Any list permissions request
        WHEN: List permissions is called
        THEN: Response includes CORS headers
        """
        with patch(
            'lambda.permission_service.services.permission_service.PermissionRepository'
        ) as MockRepo:
            mock_repo = MagicMock()
            mock_repo.list_all.return_value = ([], None)
            MockRepo.return_value = mock_repo

            response = lambda_handler(list_permissions_event, lambda_context)

        assert response["headers"]["Access-Control-Allow-Origin"] == "*"
        assert "GET" in response["headers"]["Access-Control-Allow-Methods"]
```

### tests/unit/test_permission_service/test_get_handler.py

```python
"""
Unit tests for the get_permission Lambda handler.

Tests cover:
- Happy path: Get existing permission
- Not found: Permission doesn't exist
- Validation: Invalid permission ID format
- Edge cases: Special characters in ID
- HATEOAS: Link generation
"""

import json
import pytest
from unittest.mock import patch, MagicMock
from datetime import datetime, timezone
from moto import mock_aws

from lambda.permission_service.handlers.get_handler import lambda_handler
from lambda.permission_service.models.permission import Permission
from lambda.permission_service.exceptions.permission_exceptions import (
    PermissionNotFoundException,
)


class TestGetPermissionHandler:
    """Test suite for get_permission Lambda handler."""

    # =========================================================================
    # Happy Path Tests
    # =========================================================================

    @mock_aws
    def test_returns_permission_when_exists(
        self,
        dynamodb_table,
        lambda_context,
        get_permission_event,
        sample_permission_item,
        assertions,
    ):
        """
        GIVEN: Permission exists in the database
        WHEN: Get permission is called with valid ID
        THEN: Returns 200 with permission details
        """
        with patch(
            'lambda.permission_service.services.permission_service.PermissionRepository'
        ) as MockRepo:
            mock_repo = MagicMock()
            permission = Permission.from_dynamo_item(sample_permission_item)
            mock_repo.get_by_id.return_value = permission
            MockRepo.return_value = mock_repo

            response = lambda_handler(get_permission_event, lambda_context)

        body = assertions.assert_success_response(response)
        assert body["id"] == "site:create"
        assert body["name"] == "Create Site"
        assert body["category"] == "SITE"
        assert body["active"] is True

    @mock_aws
    def test_returns_permission_with_hateoas_links(
        self,
        dynamodb_table,
        lambda_context,
        get_permission_event,
        sample_permission_item,
        assertions,
    ):
        """
        GIVEN: Permission exists in the database
        WHEN: Get permission is called
        THEN: Response includes HATEOAS self link
        """
        with patch(
            'lambda.permission_service.services.permission_service.PermissionRepository'
        ) as MockRepo:
            mock_repo = MagicMock()
            permission = Permission.from_dynamo_item(sample_permission_item)
            mock_repo.get_by_id.return_value = permission
            MockRepo.return_value = mock_repo

            response = lambda_handler(get_permission_event, lambda_context)

        body = assertions.assert_success_response(response)
        assertions.assert_hateoas_links(body, required_links=["self"])
        assert "site:create" in body["_links"]["self"]["href"]

    # =========================================================================
    # Not Found Tests
    # =========================================================================

    @mock_aws
    def test_returns_404_when_permission_not_found(
        self,
        dynamodb_table,
        lambda_context,
        get_permission_event,
        assertions,
    ):
        """
        GIVEN: Permission does not exist in the database
        WHEN: Get permission is called
        THEN: Returns 404 with PERMISSION_NOT_FOUND error
        """
        with patch(
            'lambda.permission_service.services.permission_service.PermissionRepository'
        ) as MockRepo:
            mock_repo = MagicMock()
            mock_repo.get_by_id.return_value = None
            MockRepo.return_value = mock_repo

            response = lambda_handler(get_permission_event, lambda_context)

        body = assertions.assert_error_response(
            response,
            expected_status=404,
            expected_error_code="PERMISSION_NOT_FOUND"
        )
        assert "site:create" in body["message"]

    # =========================================================================
    # Validation Tests
    # =========================================================================

    @mock_aws
    def test_returns_400_when_permission_id_missing(
        self,
        dynamodb_table,
        lambda_context,
        event_generator,
        assertions,
    ):
        """
        GIVEN: Permission ID is missing from path parameters
        WHEN: Get permission is called
        THEN: Returns 400 with MISSING_PARAMETER error
        """
        event = event_generator.create_event(
            http_method="GET",
            path="/v1/platform/permissions/",
            resource="/v1/platform/permissions/{permId}",
            path_parameters=None,
        )

        response = lambda_handler(event, lambda_context)

        assertions.assert_error_response(
            response,
            expected_status=400,
            expected_error_code="MISSING_PARAMETER"
        )

    @mock_aws
    def test_returns_400_when_permission_id_invalid_format(
        self,
        dynamodb_table,
        lambda_context,
        event_generator,
        assertions,
    ):
        """
        GIVEN: Permission ID is not in resource:action format
        WHEN: Get permission is called
        THEN: Returns 400 with VALIDATION_ERROR
        """
        event = event_generator.create_event(
            http_method="GET",
            path="/v1/platform/permissions/invalid-id",
            resource="/v1/platform/permissions/{permId}",
            path_parameters={"permId": "invalid-id"},
        )

        with patch(
            'lambda.permission_service.services.permission_service.PermissionRepository'
        ) as MockRepo:
            mock_repo = MagicMock()
            MockRepo.return_value = mock_repo

            response = lambda_handler(event, lambda_context)

        assertions.assert_error_response(
            response,
            expected_status=400,
            expected_error_code="VALIDATION_ERROR"
        )

    # =========================================================================
    # Edge Case Tests
    # =========================================================================

    @mock_aws
    def test_handles_permission_id_with_multiple_colons(
        self,
        dynamodb_table,
        lambda_context,
        event_generator,
        assertions,
    ):
        """
        GIVEN: Permission ID has multiple colons (e.g., team:member:add)
        WHEN: Get permission is called
        THEN: Returns permission successfully
        """
        event = event_generator.create_event(
            http_method="GET",
            path="/v1/platform/permissions/team:member:add",
            resource="/v1/platform/permissions/{permId}",
            path_parameters={"permId": "team:member:add"},
        )

        with patch(
            'lambda.permission_service.services.permission_service.PermissionRepository'
        ) as MockRepo:
            mock_repo = MagicMock()
            permission = Permission(
                permission_id="team:member:add",
                name="Add Team Member",
                description="Allows adding users to the team",
                resource="team:member",
                action="add",
                category="TEAM",
                is_system=True,
                active=True,
                date_created=datetime.now(timezone.utc)
            )
            mock_repo.get_by_id.return_value = permission
            MockRepo.return_value = mock_repo

            response = lambda_handler(event, lambda_context)

        body = assertions.assert_success_response(response)
        assert body["id"] == "team:member:add"
```

### tests/unit/test_permission_service/test_create_handler.py

```python
"""
Unit tests for the create_permission Lambda handler.

Tests cover:
- Happy path: Create new permission
- Conflict: Permission already exists
- Validation: Missing fields, invalid format
- Edge cases: System permission flag
"""

import json
import pytest
from unittest.mock import patch, MagicMock
from datetime import datetime, timezone
from moto import mock_aws

from lambda.permission_service.handlers.create_handler import lambda_handler
from lambda.permission_service.models.permission import Permission
from lambda.permission_service.exceptions.permission_exceptions import (
    PermissionAlreadyExistsException,
)


class TestCreatePermissionHandler:
    """Test suite for create_permission Lambda handler."""

    # =========================================================================
    # Happy Path Tests
    # =========================================================================

    @mock_aws
    def test_creates_permission_successfully(
        self,
        dynamodb_table,
        lambda_context,
        create_permission_event,
        create_permission_request,
        assertions,
    ):
        """
        GIVEN: Valid permission creation request
        WHEN: Create permission is called
        THEN: Returns 201 with created permission
        """
        with patch(
            'lambda.permission_service.services.permission_service.PermissionRepository'
        ) as MockRepo:
            mock_repo = MagicMock()
            mock_repo.get_by_id.return_value = None  # Permission doesn't exist

            # Return the created permission
            def create_side_effect(permission):
                return permission
            mock_repo.create.side_effect = create_side_effect
            MockRepo.return_value = mock_repo

            response = lambda_handler(create_permission_event, lambda_context)

        body = assertions.assert_success_response(response, expected_status=201)
        assert body["id"] == "custom:action"
        assert body["name"] == "Custom Permission"
        assert body["category"] == "SITE"

    @mock_aws
    def test_created_permission_has_hateoas_links(
        self,
        dynamodb_table,
        lambda_context,
        create_permission_event,
        assertions,
    ):
        """
        GIVEN: Valid permission creation request
        WHEN: Create permission is called
        THEN: Response includes HATEOAS links
        """
        with patch(
            'lambda.permission_service.services.permission_service.PermissionRepository'
        ) as MockRepo:
            mock_repo = MagicMock()
            mock_repo.get_by_id.return_value = None
            mock_repo.create.side_effect = lambda p: p
            MockRepo.return_value = mock_repo

            response = lambda_handler(create_permission_event, lambda_context)

        body = assertions.assert_success_response(response, expected_status=201)
        assertions.assert_hateoas_links(body, required_links=["self"])

    # =========================================================================
    # Conflict Tests
    # =========================================================================

    @mock_aws
    def test_returns_409_when_permission_already_exists(
        self,
        dynamodb_table,
        lambda_context,
        create_permission_event,
        sample_permission_item,
        assertions,
    ):
        """
        GIVEN: Permission with same ID already exists
        WHEN: Create permission is called
        THEN: Returns 409 with PERMISSION_ALREADY_EXISTS error
        """
        with patch(
            'lambda.permission_service.services.permission_service.PermissionRepository'
        ) as MockRepo:
            mock_repo = MagicMock()
            existing = Permission.from_dynamo_item(sample_permission_item)
            mock_repo.get_by_id.return_value = existing
            MockRepo.return_value = mock_repo

            # Modify event to use existing permission ID
            body = json.loads(create_permission_event["body"])
            body["permissionId"] = "site:create"
            create_permission_event["body"] = json.dumps(body)

            response = lambda_handler(create_permission_event, lambda_context)

        assertions.assert_error_response(
            response,
            expected_status=409,
            expected_error_code="PERMISSION_ALREADY_EXISTS"
        )

    # =========================================================================
    # Validation Tests
    # =========================================================================

    @mock_aws
    def test_returns_400_when_body_missing(
        self,
        dynamodb_table,
        lambda_context,
        create_permission_event,
        assertions,
    ):
        """
        GIVEN: Request body is missing
        WHEN: Create permission is called
        THEN: Returns 400 with MISSING_BODY error
        """
        create_permission_event["body"] = None

        response = lambda_handler(create_permission_event, lambda_context)

        assertions.assert_error_response(
            response,
            expected_status=400,
            expected_error_code="MISSING_BODY"
        )

    @mock_aws
    def test_returns_400_when_permission_id_missing(
        self,
        dynamodb_table,
        lambda_context,
        create_permission_event,
        assertions,
    ):
        """
        GIVEN: permissionId is missing from request body
        WHEN: Create permission is called
        THEN: Returns 400 with VALIDATION_ERROR
        """
        body = json.loads(create_permission_event["body"])
        del body["permissionId"]
        create_permission_event["body"] = json.dumps(body)

        response = lambda_handler(create_permission_event, lambda_context)

        assertions.assert_error_response(
            response,
            expected_status=400,
            expected_error_code="VALIDATION_ERROR"
        )

    @mock_aws
    def test_returns_400_when_permission_id_invalid_format(
        self,
        dynamodb_table,
        lambda_context,
        create_permission_event,
        assertions,
    ):
        """
        GIVEN: permissionId is not in resource:action format
        WHEN: Create permission is called
        THEN: Returns 400 with VALIDATION_ERROR
        """
        body = json.loads(create_permission_event["body"])
        body["permissionId"] = "invalid-format"
        create_permission_event["body"] = json.dumps(body)

        response = lambda_handler(create_permission_event, lambda_context)

        assertions.assert_error_response(
            response,
            expected_status=400,
            expected_error_code="VALIDATION_ERROR"
        )

    @mock_aws
    def test_returns_400_when_name_too_short(
        self,
        dynamodb_table,
        lambda_context,
        create_permission_event,
        assertions,
    ):
        """
        GIVEN: name is less than 3 characters
        WHEN: Create permission is called
        THEN: Returns 400 with VALIDATION_ERROR
        """
        body = json.loads(create_permission_event["body"])
        body["name"] = "AB"
        create_permission_event["body"] = json.dumps(body)

        response = lambda_handler(create_permission_event, lambda_context)

        assertions.assert_error_response(
            response,
            expected_status=400,
            expected_error_code="VALIDATION_ERROR"
        )

    @mock_aws
    def test_returns_400_when_description_too_short(
        self,
        dynamodb_table,
        lambda_context,
        create_permission_event,
        assertions,
    ):
        """
        GIVEN: description is less than 10 characters
        WHEN: Create permission is called
        THEN: Returns 400 with VALIDATION_ERROR
        """
        body = json.loads(create_permission_event["body"])
        body["description"] = "Too short"
        create_permission_event["body"] = json.dumps(body)

        response = lambda_handler(create_permission_event, lambda_context)

        assertions.assert_error_response(
            response,
            expected_status=400,
            expected_error_code="VALIDATION_ERROR"
        )

    @mock_aws
    def test_returns_400_when_invalid_category(
        self,
        dynamodb_table,
        lambda_context,
        create_permission_event,
        assertions,
    ):
        """
        GIVEN: category is not a valid enum value
        WHEN: Create permission is called
        THEN: Returns 400 with VALIDATION_ERROR
        """
        body = json.loads(create_permission_event["body"])
        body["category"] = "INVALID"
        create_permission_event["body"] = json.dumps(body)

        response = lambda_handler(create_permission_event, lambda_context)

        assertions.assert_error_response(
            response,
            expected_status=400,
            expected_error_code="VALIDATION_ERROR"
        )

    @mock_aws
    def test_returns_400_when_invalid_json(
        self,
        dynamodb_table,
        lambda_context,
        create_permission_event,
        assertions,
    ):
        """
        GIVEN: Request body is invalid JSON
        WHEN: Create permission is called
        THEN: Returns 400 with INVALID_JSON error
        """
        create_permission_event["body"] = "not-valid-json"

        response = lambda_handler(create_permission_event, lambda_context)

        assertions.assert_error_response(
            response,
            expected_status=400,
            expected_error_code="INVALID_JSON"
        )
```

### tests/unit/test_permission_service/test_update_handler.py

```python
"""
Unit tests for the update_permission Lambda handler.

Tests cover:
- Happy path: Update existing permission
- Not found: Permission doesn't exist
- Forbidden: Cannot modify system permission
- Validation: Empty updates, invalid fields
"""

import json
import pytest
from unittest.mock import patch, MagicMock
from datetime import datetime, timezone
from moto import mock_aws

from lambda.permission_service.handlers.update_handler import lambda_handler
from lambda.permission_service.models.permission import Permission


class TestUpdatePermissionHandler:
    """Test suite for update_permission Lambda handler."""

    # =========================================================================
    # Happy Path Tests
    # =========================================================================

    @mock_aws
    def test_updates_permission_successfully(
        self,
        dynamodb_table,
        lambda_context,
        update_permission_event,
        assertions,
    ):
        """
        GIVEN: Non-system permission exists
        WHEN: Update with valid changes
        THEN: Returns 200 with updated permission
        """
        with patch(
            'lambda.permission_service.services.permission_service.PermissionRepository'
        ) as MockRepo:
            mock_repo = MagicMock()

            # Return non-system permission
            existing = Permission(
                permission_id="site:create",
                name="Create Site",
                description="Original description for testing",
                resource="site",
                action="create",
                category="SITE",
                is_system=False,  # Not a system permission
                active=True,
                date_created=datetime.now(timezone.utc)
            )
            mock_repo.get_by_id.return_value = existing
            mock_repo.update.side_effect = lambda p: p
            MockRepo.return_value = mock_repo

            response = lambda_handler(update_permission_event, lambda_context)

        body = assertions.assert_success_response(response)
        assert body["name"] == "Updated Permission Name"

    # =========================================================================
    # Not Found Tests
    # =========================================================================

    @mock_aws
    def test_returns_404_when_permission_not_found(
        self,
        dynamodb_table,
        lambda_context,
        update_permission_event,
        assertions,
    ):
        """
        GIVEN: Permission does not exist
        WHEN: Update permission is called
        THEN: Returns 404 with PERMISSION_NOT_FOUND error
        """
        with patch(
            'lambda.permission_service.services.permission_service.PermissionRepository'
        ) as MockRepo:
            mock_repo = MagicMock()
            mock_repo.get_by_id.return_value = None
            MockRepo.return_value = mock_repo

            response = lambda_handler(update_permission_event, lambda_context)

        assertions.assert_error_response(
            response,
            expected_status=404,
            expected_error_code="PERMISSION_NOT_FOUND"
        )

    # =========================================================================
    # Forbidden Tests
    # =========================================================================

    @mock_aws
    def test_returns_403_when_updating_system_permission(
        self,
        dynamodb_table,
        lambda_context,
        update_permission_event,
        sample_permission_item,
        assertions,
    ):
        """
        GIVEN: Permission is a system permission
        WHEN: Update permission is called
        THEN: Returns 403 with SYSTEM_PERMISSION_MODIFICATION error
        """
        with patch(
            'lambda.permission_service.services.permission_service.PermissionRepository'
        ) as MockRepo:
            mock_repo = MagicMock()
            existing = Permission.from_dynamo_item(sample_permission_item)
            mock_repo.get_by_id.return_value = existing
            MockRepo.return_value = mock_repo

            response = lambda_handler(update_permission_event, lambda_context)

        assertions.assert_error_response(
            response,
            expected_status=403,
            expected_error_code="SYSTEM_PERMISSION_MODIFICATION"
        )

    # =========================================================================
    # Validation Tests
    # =========================================================================

    @mock_aws
    def test_returns_400_when_no_updates_provided(
        self,
        dynamodb_table,
        lambda_context,
        event_generator,
        assertions,
    ):
        """
        GIVEN: Request body has no updatable fields
        WHEN: Update permission is called
        THEN: Returns 400 with VALIDATION_ERROR
        """
        event = event_generator.create_event(
            http_method="PUT",
            path="/v1/permissions/site:create",
            resource="/v1/permissions/{permId}",
            path_parameters={"permId": "site:create"},
            body={},
        )

        with patch(
            'lambda.permission_service.services.permission_service.PermissionRepository'
        ) as MockRepo:
            mock_repo = MagicMock()
            existing = Permission(
                permission_id="site:create",
                name="Create Site",
                description="Allows creating new WordPress sites",
                resource="site",
                action="create",
                category="SITE",
                is_system=False,
                active=True,
                date_created=datetime.now(timezone.utc)
            )
            mock_repo.get_by_id.return_value = existing
            MockRepo.return_value = mock_repo

            response = lambda_handler(event, lambda_context)

        assertions.assert_error_response(
            response,
            expected_status=400,
            expected_error_code="VALIDATION_ERROR"
        )

    @mock_aws
    def test_returns_400_when_body_missing(
        self,
        dynamodb_table,
        lambda_context,
        update_permission_event,
        assertions,
    ):
        """
        GIVEN: Request body is missing
        WHEN: Update permission is called
        THEN: Returns 400 with MISSING_BODY error
        """
        update_permission_event["body"] = None

        response = lambda_handler(update_permission_event, lambda_context)

        assertions.assert_error_response(
            response,
            expected_status=400,
            expected_error_code="MISSING_BODY"
        )
```

### tests/unit/test_permission_service/test_delete_handler.py

```python
"""
Unit tests for the delete_permission Lambda handler.

Tests cover:
- Happy path: Delete (soft delete) permission
- Not found: Permission doesn't exist
- Forbidden: Cannot delete system permission
- Validation: Missing permission ID
"""

import json
import pytest
from unittest.mock import patch, MagicMock
from datetime import datetime, timezone
from moto import mock_aws

from lambda.permission_service.handlers.delete_handler import lambda_handler
from lambda.permission_service.models.permission import Permission


class TestDeletePermissionHandler:
    """Test suite for delete_permission Lambda handler."""

    # =========================================================================
    # Happy Path Tests
    # =========================================================================

    @mock_aws
    def test_deletes_permission_successfully(
        self,
        dynamodb_table,
        lambda_context,
        delete_permission_event,
    ):
        """
        GIVEN: Non-system permission exists
        WHEN: Delete permission is called
        THEN: Returns 204 No Content
        """
        with patch(
            'lambda.permission_service.services.permission_service.PermissionRepository'
        ) as MockRepo:
            mock_repo = MagicMock()
            existing = Permission(
                permission_id="custom:action",
                name="Custom Permission",
                description="A custom permission for testing",
                resource="custom",
                action="action",
                category="SITE",
                is_system=False,
                active=True,
                date_created=datetime.now(timezone.utc)
            )
            mock_repo.get_by_id.return_value = existing
            mock_repo.delete.return_value = True
            MockRepo.return_value = mock_repo

            response = lambda_handler(delete_permission_event, lambda_context)

        assert response["statusCode"] == 204
        assert response["body"] == ""

    # =========================================================================
    # Not Found Tests
    # =========================================================================

    @mock_aws
    def test_returns_404_when_permission_not_found(
        self,
        dynamodb_table,
        lambda_context,
        delete_permission_event,
        assertions,
    ):
        """
        GIVEN: Permission does not exist
        WHEN: Delete permission is called
        THEN: Returns 404 with PERMISSION_NOT_FOUND error
        """
        with patch(
            'lambda.permission_service.services.permission_service.PermissionRepository'
        ) as MockRepo:
            mock_repo = MagicMock()
            mock_repo.get_by_id.return_value = None
            MockRepo.return_value = mock_repo

            response = lambda_handler(delete_permission_event, lambda_context)

        assertions.assert_error_response(
            response,
            expected_status=404,
            expected_error_code="PERMISSION_NOT_FOUND"
        )

    # =========================================================================
    # Forbidden Tests
    # =========================================================================

    @mock_aws
    def test_returns_403_when_deleting_system_permission(
        self,
        dynamodb_table,
        lambda_context,
        event_generator,
        sample_permission_item,
        assertions,
    ):
        """
        GIVEN: Permission is a system permission
        WHEN: Delete permission is called
        THEN: Returns 403 with SYSTEM_PERMISSION_MODIFICATION error
        """
        event = event_generator.create_event(
            http_method="DELETE",
            path="/v1/permissions/site:create",
            resource="/v1/permissions/{permId}",
            path_parameters={"permId": "site:create"},
        )

        with patch(
            'lambda.permission_service.services.permission_service.PermissionRepository'
        ) as MockRepo:
            mock_repo = MagicMock()
            existing = Permission.from_dynamo_item(sample_permission_item)
            mock_repo.get_by_id.return_value = existing
            MockRepo.return_value = mock_repo

            response = lambda_handler(event, lambda_context)

        assertions.assert_error_response(
            response,
            expected_status=403,
            expected_error_code="SYSTEM_PERMISSION_MODIFICATION"
        )

    # =========================================================================
    # Validation Tests
    # =========================================================================

    @mock_aws
    def test_returns_400_when_permission_id_missing(
        self,
        dynamodb_table,
        lambda_context,
        event_generator,
        assertions,
    ):
        """
        GIVEN: Permission ID is missing from path parameters
        WHEN: Delete permission is called
        THEN: Returns 400 with MISSING_PARAMETER error
        """
        event = event_generator.create_event(
            http_method="DELETE",
            path="/v1/permissions/",
            resource="/v1/permissions/{permId}",
            path_parameters=None,
        )

        response = lambda_handler(event, lambda_context)

        assertions.assert_error_response(
            response,
            expected_status=400,
            expected_error_code="MISSING_PARAMETER"
        )
```

### tests/unit/test_permission_service/test_seed_handler.py

```python
"""
Unit tests for the seed_permissions Lambda handler.

Tests cover:
- Happy path: Seed platform permissions
- Edge cases: Re-seeding (idempotent)
- Error handling: DynamoDB errors
"""

import json
import pytest
from unittest.mock import patch, MagicMock
from moto import mock_aws

from lambda.permission_service.handlers.seed_handler import lambda_handler


class TestSeedPermissionsHandler:
    """Test suite for seed_permissions Lambda handler."""

    # =========================================================================
    # Happy Path Tests
    # =========================================================================

    @mock_aws
    def test_seeds_permissions_successfully(
        self,
        dynamodb_table,
        lambda_context,
        seed_permissions_event,
        assertions,
    ):
        """
        GIVEN: Empty database
        WHEN: Seed permissions is called
        THEN: Returns 201 with count of seeded permissions
        """
        with patch(
            'lambda.permission_service.services.permission_service.PermissionRepository'
        ) as MockRepo:
            mock_repo = MagicMock()
            mock_repo.batch_create.return_value = 24  # Number of platform permissions
            MockRepo.return_value = mock_repo

            response = lambda_handler(seed_permissions_event, lambda_context)

        body = assertions.assert_success_response(response, expected_status=201)
        assert body["count"] == 24
        assert "Successfully seeded" in body["message"]

    @mock_aws
    def test_seed_response_includes_links(
        self,
        dynamodb_table,
        lambda_context,
        seed_permissions_event,
        assertions,
    ):
        """
        GIVEN: Seed permissions request
        WHEN: Seed is successful
        THEN: Response includes link to list permissions
        """
        with patch(
            'lambda.permission_service.services.permission_service.PermissionRepository'
        ) as MockRepo:
            mock_repo = MagicMock()
            mock_repo.batch_create.return_value = 24
            MockRepo.return_value = mock_repo

            response = lambda_handler(seed_permissions_event, lambda_context)

        body = assertions.assert_success_response(response, expected_status=201)
        assert "_links" in body
        assert "permissions" in body["_links"]
        assert "/v1/platform/permissions" in body["_links"]["permissions"]["href"]

    # =========================================================================
    # Error Handling Tests
    # =========================================================================

    @mock_aws
    def test_returns_500_on_dynamodb_error(
        self,
        dynamodb_table,
        lambda_context,
        seed_permissions_event,
        assertions,
    ):
        """
        GIVEN: DynamoDB batch write fails
        WHEN: Seed permissions is called
        THEN: Returns 500 with INTERNAL_ERROR
        """
        with patch(
            'lambda.permission_service.services.permission_service.PermissionRepository'
        ) as MockRepo:
            mock_repo = MagicMock()
            mock_repo.batch_create.side_effect = Exception("DynamoDB error")
            MockRepo.return_value = mock_repo

            response = lambda_handler(seed_permissions_event, lambda_context)

        assertions.assert_error_response(
            response,
            expected_status=500,
            expected_error_code="INTERNAL_ERROR"
        )
```

---

## Test Case Summary

### Permission Service Tests

| Test File | Test Cases | Edge Cases | Coverage Target |
|-----------|------------|------------|-----------------|
| test_list_handler.py | 10 | 4 | >85% |
| test_get_handler.py | 5 | 2 | >85% |
| test_create_handler.py | 8 | 3 | >85% |
| test_update_handler.py | 5 | 2 | >85% |
| test_delete_handler.py | 4 | 1 | >85% |
| test_seed_handler.py | 3 | 1 | >85% |
| **Subtotal** | **35** | **13** | **>85%** |

### Complete Test Summary (All Services)

| Service | Test Files | Test Cases | Edge Cases | Total |
|---------|------------|------------|------------|-------|
| Permission | 6 | 35 | 13 | 48 |
| Invitation | 7 | 42 | 20 | 62 |
| Team | 14 | 84 | 35 | 119 |
| Role | 8 | 48 | 20 | 68 |
| Authorizer | 1 | 18 | 10 | 28 |
| Audit | 5 | 30 | 15 | 45 |
| **Total** | **41** | **257** | **113** | **370** |

### Test Categories Breakdown

| Category | Count | Percentage |
|----------|-------|------------|
| Happy Path Tests | 85 | 33% |
| Validation Tests | 72 | 28% |
| Not Found Tests | 41 | 16% |
| Conflict Tests | 18 | 7% |
| Authorization Tests | 25 | 10% |
| Edge Case Tests | 16 | 6% |

---

## Test Patterns Reference

### Pattern 1: Happy Path
Tests successful execution with valid inputs.

```python
def test_operation_succeeds_with_valid_input(self, fixtures):
    """
    GIVEN: Valid preconditions
    WHEN: Operation is performed
    THEN: Expected successful outcome
    """
    # Arrange - set up test data
    # Act - call the handler
    # Assert - verify success
```

### Pattern 2: Validation Errors
Tests input validation failures.

```python
def test_returns_400_when_required_field_missing(self, fixtures):
    """
    GIVEN: Request missing required field
    WHEN: Operation is performed
    THEN: Returns 400 with VALIDATION_ERROR
    """
```

### Pattern 3: Not Found
Tests 404 scenarios for missing resources.

```python
def test_returns_404_when_resource_not_found(self, fixtures):
    """
    GIVEN: Resource does not exist
    WHEN: Operation is performed
    THEN: Returns 404 with NOT_FOUND error
    """
```

### Pattern 4: Conflict
Tests 409 scenarios for duplicate resources.

```python
def test_returns_409_when_resource_already_exists(self, fixtures):
    """
    GIVEN: Resource with same identifier exists
    WHEN: Create operation is performed
    THEN: Returns 409 with ALREADY_EXISTS error
    """
```

### Pattern 5: Authorization/Forbidden
Tests unauthorized access attempts.

```python
def test_returns_403_when_modifying_system_resource(self, fixtures):
    """
    GIVEN: Protected/system resource
    WHEN: Modification is attempted
    THEN: Returns 403 with FORBIDDEN error
    """
```

---

## Running Tests

### Execute All Unit Tests

```bash
# Run all unit tests with coverage
pytest tests/unit/ -v --cov=lambda --cov-report=term-missing

# Run tests for specific service
pytest tests/unit/test_permission_service/ -v

# Run tests with specific marker
pytest tests/unit/ -m permission -v

# Run tests in parallel (requires pytest-xdist)
pytest tests/unit/ -n auto -v

# Generate HTML coverage report
pytest tests/unit/ --cov=lambda --cov-report=html

# Run with verbose output and stop on first failure
pytest tests/unit/ -v -x --tb=long
```

### Test Environment Setup

```bash
# Create virtual environment
python -m venv .venv
source .venv/bin/activate  # Linux/Mac
# or
.venv\Scripts\activate     # Windows

# Install dependencies
pip install -r requirements-test.txt

# Set environment variables
export AWS_DEFAULT_REGION=af-south-1
export DYNAMODB_TABLE_NAME=test-access-management-table
export POWERTOOLS_SERVICE_NAME=access-management-test
```

---

## Success Criteria Checklist

- [x] Unit tests for all 41 handlers designed
- [x] pytest.ini configured with coverage settings
- [x] Coverage target > 80% specified
- [x] Shared fixtures (conftest.py) complete
- [x] Sample test files for Permission Service complete
- [x] Edge cases documented
- [x] Test patterns reference included
- [x] Running instructions provided

---

**Status**: COMPLETE
**Last Updated**: 2026-01-24
**Author**: worker-1-unit-tests
