# Worker 3 Output: Test Automation Workflows

**Worker ID**: worker-3-test-automation-workflow
**Status**: COMPLETE
**Completed**: 2026-01-25

---

## Deliverables

### 1. test-unit.yml

```yaml
# .github/workflows/test-unit.yml
name: Unit Tests

on:
  pull_request:
    branches:
      - develop
      - 'release/**'
      - main
    paths:
      - 'src/**'
      - 'tests/**'
      - 'requirements*.txt'
      - 'pyproject.toml'
      - '.github/workflows/test-unit.yml'
  push:
    branches:
      - develop
    paths:
      - 'src/**'
      - 'tests/**'

permissions:
  contents: read
  pull-requests: write
  checks: write

env:
  COVERAGE_THRESHOLD: 80

jobs:
  unit-tests:
    name: Unit Tests (Python ${{ matrix.python-version }})
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        python-version: ['3.11', '3.12']

    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Setup Python ${{ matrix.python-version }}
        uses: actions/setup-python@v5
        with:
          python-version: ${{ matrix.python-version }}
          cache: 'pip'

      - name: Install Dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements.txt
          pip install -r requirements-dev.txt

      - name: Run Unit Tests with Coverage
        run: |
          pytest tests/unit/ \
            -v \
            --cov=src \
            --cov-report=xml \
            --cov-report=html \
            --cov-report=term-missing \
            --cov-fail-under=${{ env.COVERAGE_THRESHOLD }} \
            --junitxml=test-results-${{ matrix.python-version }}.xml \
            -n auto

      - name: Upload Coverage Report
        uses: actions/upload-artifact@v4
        with:
          name: coverage-report-${{ matrix.python-version }}
          path: |
            coverage.xml
            htmlcov/
          retention-days: 14

      - name: Upload Test Results
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: test-results-${{ matrix.python-version }}
          path: test-results-${{ matrix.python-version }}.xml
          retention-days: 14

  coverage-report:
    name: Coverage Report
    runs-on: ubuntu-latest
    needs: unit-tests
    if: github.event_name == 'pull_request'
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Download Coverage Report
        uses: actions/download-artifact@v4
        with:
          name: coverage-report-3.12
          path: coverage/

      - name: Code Coverage Summary
        uses: irongut/CodeCoverageSummary@v1.3.0
        with:
          filename: coverage/coverage.xml
          badge: true
          fail_below_min: true
          format: markdown
          hide_branch_rate: false
          hide_complexity: true
          indicators: true
          output: both
          thresholds: '60 80'

      - name: Add Coverage PR Comment
        uses: marocchino/sticky-pull-request-comment@v2
        if: github.event_name == 'pull_request'
        with:
          recreate: true
          path: code-coverage-results.md

      - name: Upload Coverage to Codecov
        uses: codecov/codecov-action@v4
        with:
          token: ${{ secrets.CODECOV_TOKEN }}
          files: coverage/coverage.xml
          flags: unittests
          name: codecov-umbrella
          fail_ci_if_error: false

  publish-results:
    name: Publish Test Results
    runs-on: ubuntu-latest
    needs: unit-tests
    if: always()
    steps:
      - name: Download Test Results (3.11)
        uses: actions/download-artifact@v4
        with:
          name: test-results-3.11
          path: results/

      - name: Download Test Results (3.12)
        uses: actions/download-artifact@v4
        with:
          name: test-results-3.12
          path: results/

      - name: Publish Test Results
        uses: EnricoMi/publish-unit-test-result-action@v2
        if: always()
        with:
          files: results/*.xml
          check_name: Unit Test Results
          comment_mode: always
          compare_to_earlier_commit: true
```

---

### 2. test-integration.yml

```yaml
# .github/workflows/test-integration.yml
name: Integration Tests

on:
  push:
    branches:
      - develop
    paths:
      - 'src/**'
      - 'tests/**'
  workflow_dispatch:
    inputs:
      environment:
        description: 'Target environment for tests'
        required: true
        default: 'dev'
        type: choice
        options:
          - dev
          - sit

permissions:
  id-token: write
  contents: read
  checks: write

env:
  PYTHON_VERSION: '3.12'

jobs:
  determine-environment:
    name: Determine Environment
    runs-on: ubuntu-latest
    outputs:
      environment: ${{ steps.set-env.outputs.environment }}
      aws_region: ${{ steps.set-env.outputs.aws_region }}
      aws_account_id: ${{ steps.set-env.outputs.aws_account_id }}
    steps:
      - name: Set Environment
        id: set-env
        run: |
          ENV="${{ github.event.inputs.environment || 'dev' }}"
          echo "environment=$ENV" >> $GITHUB_OUTPUT

          case $ENV in
            sit)
              echo "aws_region=eu-west-1" >> $GITHUB_OUTPUT
              echo "aws_account_id=815856636111" >> $GITHUB_OUTPUT
              ;;
            *)
              echo "aws_region=eu-west-1" >> $GITHUB_OUTPUT
              echo "aws_account_id=536580886816" >> $GITHUB_OUTPUT
              ;;
          esac

  integration-tests:
    name: Integration Tests (${{ needs.determine-environment.outputs.environment }})
    runs-on: ubuntu-latest
    needs: determine-environment
    environment: ${{ needs.determine-environment.outputs.environment }}
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ env.PYTHON_VERSION }}
          cache: 'pip'

      - name: Install Dependencies
        run: |
          pip install -r requirements.txt
          pip install -r requirements-dev.txt

      - name: Configure AWS Credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ needs.determine-environment.outputs.aws_account_id }}:role/bbws-access-${{ needs.determine-environment.outputs.environment }}-github-actions-role
          aws-region: ${{ needs.determine-environment.outputs.aws_region }}
          role-session-name: integration-tests-${{ github.run_id }}

      - name: Run Integration Tests
        env:
          TEST_ENVIRONMENT: ${{ needs.determine-environment.outputs.environment }}
          AWS_REGION: ${{ needs.determine-environment.outputs.aws_region }}
        run: |
          pytest tests/integration/ \
            -v \
            --junitxml=integration-results.xml \
            --tb=short \
            -n 4

      - name: Upload Test Results
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: integration-results-${{ needs.determine-environment.outputs.environment }}
          path: integration-results.xml
          retention-days: 14

      - name: Publish Test Results
        uses: EnricoMi/publish-unit-test-result-action@v2
        if: always()
        with:
          files: integration-results.xml
          check_name: Integration Test Results
          comment_mode: off

  contract-tests:
    name: API Contract Tests
    runs-on: ubuntu-latest
    needs: determine-environment
    environment: ${{ needs.determine-environment.outputs.environment }}
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ env.PYTHON_VERSION }}
          cache: 'pip'

      - name: Install Dependencies
        run: |
          pip install -r requirements.txt
          pip install -r requirements-dev.txt

      - name: Configure AWS Credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ needs.determine-environment.outputs.aws_account_id }}:role/bbws-access-${{ needs.determine-environment.outputs.environment }}-github-actions-role
          aws-region: ${{ needs.determine-environment.outputs.aws_region }}

      - name: Run Contract Tests
        env:
          TEST_ENVIRONMENT: ${{ needs.determine-environment.outputs.environment }}
        run: |
          pytest tests/contract/ \
            -v \
            --junitxml=contract-results.xml \
            --tb=short

      - name: Upload Contract Test Results
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: contract-results-${{ needs.determine-environment.outputs.environment }}
          path: contract-results.xml
          retention-days: 14

  authorization-tests:
    name: Authorization Tests
    runs-on: ubuntu-latest
    needs: determine-environment
    environment: ${{ needs.determine-environment.outputs.environment }}
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ env.PYTHON_VERSION }}
          cache: 'pip'

      - name: Install Dependencies
        run: |
          pip install -r requirements.txt
          pip install -r requirements-dev.txt

      - name: Configure AWS Credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ needs.determine-environment.outputs.aws_account_id }}:role/bbws-access-${{ needs.determine-environment.outputs.environment }}-github-actions-role
          aws-region: ${{ needs.determine-environment.outputs.aws_region }}

      - name: Run Authorization Tests
        env:
          TEST_ENVIRONMENT: ${{ needs.determine-environment.outputs.environment }}
        run: |
          pytest tests/authorization/ \
            -v \
            --junitxml=auth-results.xml \
            --tb=short

      - name: Upload Authorization Test Results
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: auth-results-${{ needs.determine-environment.outputs.environment }}
          path: auth-results.xml
          retention-days: 14

  test-summary:
    name: Test Summary
    runs-on: ubuntu-latest
    needs: [integration-tests, contract-tests, authorization-tests]
    if: always()
    steps:
      - name: Generate Summary
        run: |
          echo "## Integration Test Summary" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          echo "| Test Suite | Status |" >> $GITHUB_STEP_SUMMARY
          echo "|------------|--------|" >> $GITHUB_STEP_SUMMARY
          echo "| Integration Tests | ${{ needs.integration-tests.result }} |" >> $GITHUB_STEP_SUMMARY
          echo "| Contract Tests | ${{ needs.contract-tests.result }} |" >> $GITHUB_STEP_SUMMARY
          echo "| Authorization Tests | ${{ needs.authorization-tests.result }} |" >> $GITHUB_STEP_SUMMARY
```

---

### 3. codecov.yml

```yaml
# codecov.yml - Coverage configuration
codecov:
  require_ci_to_pass: yes
  notify:
    wait_for_ci: yes

coverage:
  precision: 2
  round: down
  range: "60...100"

  status:
    project:
      default:
        target: 80%
        threshold: 2%
        if_ci_failed: error
        informational: false

    patch:
      default:
        target: 80%
        threshold: 2%
        if_ci_failed: error
        only_pulls: true

parsers:
  gcov:
    branch_detection:
      conditional: yes
      loop: yes
      method: no
      macro: no

comment:
  layout: "reach,diff,flags,files"
  behavior: default
  require_changes: true
  require_base: no
  require_head: yes

flags:
  unittests:
    paths:
      - src/
    carryforward: true

  integration:
    paths:
      - src/
    carryforward: false

ignore:
  - "tests/**/*"
  - "**/__pycache__/**"
  - "**/conftest.py"
```

---

### 4. pytest.ini

```ini
# pytest.ini - Pytest configuration
[pytest]
minversion = 7.0
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*

# Markers
markers =
    unit: Unit tests (fast, no external dependencies)
    integration: Integration tests (require AWS resources)
    contract: API contract tests
    authorization: Authorization and security tests
    smoke: Smoke tests for deployment verification
    slow: Slow tests (skip with -m "not slow")

# Default options
addopts =
    --strict-markers
    --tb=short
    -ra

# Coverage options (when using --cov)
# Note: these are overridden by command line for flexibility

# Logging
log_cli = true
log_cli_level = INFO
log_cli_format = %(asctime)s [%(levelname)8s] %(name)s: %(message)s
log_cli_date_format = %Y-%m-%d %H:%M:%S

# Timeout for individual tests (requires pytest-timeout)
timeout = 300
timeout_method = thread

# Parallel execution (requires pytest-xdist)
# Use -n auto or -n <num> on command line

# Environment variables for tests
env =
    TESTING=true
    LOG_LEVEL=DEBUG
```

---

### 5. conftest.py (Test Fixtures)

```python
# tests/conftest.py
"""
Shared pytest fixtures for all test types.
"""

import os
import json
import pytest
import boto3
from moto import mock_dynamodb, mock_s3, mock_ses, mock_sns, mock_lambda
from unittest.mock import MagicMock, patch
from datetime import datetime, timezone
import uuid


# ============================================================================
# Environment Configuration
# ============================================================================

@pytest.fixture(scope="session")
def test_environment():
    """Get test environment from env var or default to 'test'."""
    return os.environ.get("TEST_ENVIRONMENT", "test")


@pytest.fixture(scope="session")
def aws_region():
    """Get AWS region from env var or default."""
    return os.environ.get("AWS_REGION", "eu-west-1")


# ============================================================================
# AWS Mock Fixtures (for Unit Tests)
# ============================================================================

@pytest.fixture
def mock_dynamodb_resource():
    """Provide mocked DynamoDB resource."""
    with mock_dynamodb():
        yield boto3.resource("dynamodb", region_name="eu-west-1")


@pytest.fixture
def mock_s3_client():
    """Provide mocked S3 client."""
    with mock_s3():
        yield boto3.client("s3", region_name="eu-west-1")


@pytest.fixture
def mock_ses_client():
    """Provide mocked SES client."""
    with mock_ses():
        client = boto3.client("ses", region_name="eu-west-1")
        # Verify email identity for testing
        client.verify_email_identity(EmailAddress="noreply@bbws.test")
        yield client


@pytest.fixture
def mock_sns_client():
    """Provide mocked SNS client."""
    with mock_sns():
        yield boto3.client("sns", region_name="eu-west-1")


# ============================================================================
# DynamoDB Table Fixtures
# ============================================================================

@pytest.fixture
def access_management_table(mock_dynamodb_resource):
    """Create access management DynamoDB table for testing."""
    table = mock_dynamodb_resource.create_table(
        TableName="bbws-access-test-ddb-access-management",
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
        ],
        BillingMode="PAY_PER_REQUEST",
    )
    table.wait_until_exists()
    yield table


# ============================================================================
# Test Data Fixtures
# ============================================================================

@pytest.fixture
def sample_organisation():
    """Sample organisation data."""
    return {
        "org_id": f"org_{uuid.uuid4().hex[:12]}",
        "name": "Test Organisation",
        "created_at": datetime.now(timezone.utc).isoformat(),
    }


@pytest.fixture
def sample_user(sample_organisation):
    """Sample user data."""
    return {
        "user_id": f"user_{uuid.uuid4().hex[:12]}",
        "org_id": sample_organisation["org_id"],
        "email": "test.user@example.com",
        "name": "Test User",
        "created_at": datetime.now(timezone.utc).isoformat(),
    }


@pytest.fixture
def sample_team(sample_organisation, sample_user):
    """Sample team data."""
    return {
        "team_id": f"team_{uuid.uuid4().hex[:12]}",
        "org_id": sample_organisation["org_id"],
        "name": "Test Team",
        "description": "A test team",
        "created_by": sample_user["user_id"],
        "created_at": datetime.now(timezone.utc).isoformat(),
    }


@pytest.fixture
def sample_permission():
    """Sample permission data."""
    return {
        "permission_id": f"perm_{uuid.uuid4().hex[:12]}",
        "code": "site:create",
        "name": "Create Site",
        "description": "Permission to create new sites",
        "category": "site",
        "is_system": False,
    }


@pytest.fixture
def sample_role(sample_organisation, sample_permission):
    """Sample role data."""
    return {
        "role_id": f"role_{uuid.uuid4().hex[:12]}",
        "org_id": sample_organisation["org_id"],
        "name": "Site Admin",
        "description": "Administrator for sites",
        "permissions": [sample_permission["code"]],
        "is_system": False,
    }


# ============================================================================
# Lambda Event Fixtures
# ============================================================================

@pytest.fixture
def api_gateway_event():
    """Factory for API Gateway events."""
    def _create_event(
        method: str = "GET",
        path: str = "/",
        body: dict = None,
        path_params: dict = None,
        query_params: dict = None,
        headers: dict = None,
        user_context: dict = None,
    ):
        event = {
            "httpMethod": method,
            "path": path,
            "pathParameters": path_params or {},
            "queryStringParameters": query_params or {},
            "headers": headers or {"Content-Type": "application/json"},
            "body": json.dumps(body) if body else None,
            "requestContext": {
                "requestId": str(uuid.uuid4()),
                "authorizer": user_context or {
                    "userId": "user_test123",
                    "orgId": "org_test123",
                    "email": "test@example.com",
                    "permissions": ["*:*"],
                    "teamIds": ["team_test123"],
                },
            },
        }
        return event

    return _create_event


@pytest.fixture
def lambda_context():
    """Mock Lambda context object."""
    context = MagicMock()
    context.function_name = "test-function"
    context.function_version = "$LATEST"
    context.invoked_function_arn = "arn:aws:lambda:eu-west-1:123456789012:function:test-function"
    context.memory_limit_in_mb = 512
    context.aws_request_id = str(uuid.uuid4())
    context.log_group_name = "/aws/lambda/test-function"
    context.log_stream_name = "2026/01/25/[$LATEST]abc123"
    context.get_remaining_time_in_millis = lambda: 30000
    return context


# ============================================================================
# Authentication Fixtures
# ============================================================================

@pytest.fixture
def mock_cognito_token():
    """Generate mock Cognito JWT token claims."""
    return {
        "sub": "user_test123",
        "email": "test@example.com",
        "cognito:username": "test@example.com",
        "custom:org_id": "org_test123",
        "iss": "https://cognito-idp.eu-west-1.amazonaws.com/eu-west-1_TestPool",
        "token_use": "access",
        "auth_time": int(datetime.now(timezone.utc).timestamp()),
        "exp": int(datetime.now(timezone.utc).timestamp()) + 3600,
    }


# ============================================================================
# Helper Functions
# ============================================================================

@pytest.fixture
def assert_api_response():
    """Helper to assert API Gateway response structure."""
    def _assert(response, expected_status: int = 200):
        assert "statusCode" in response
        assert response["statusCode"] == expected_status
        assert "headers" in response
        assert response["headers"].get("Content-Type") == "application/json"

        if response.get("body"):
            body = json.loads(response["body"])
            return body
        return None

    return _assert
```

---

### 6. Test Directory Structure

```
tests/
├── conftest.py                    # Shared fixtures
├── pytest.ini                     # Pytest configuration
│
├── unit/                          # Unit tests (mocked)
│   ├── __init__.py
│   ├── conftest.py               # Unit test fixtures
│   │
│   ├── permission_service/
│   │   ├── test_permission_create.py
│   │   ├── test_permission_get.py
│   │   ├── test_permission_list.py
│   │   ├── test_permission_update.py
│   │   └── test_permission_delete.py
│   │
│   ├── invitation_service/
│   │   ├── test_invitation_create.py
│   │   ├── test_invitation_accept.py
│   │   ├── test_invitation_decline.py
│   │   └── ...
│   │
│   ├── team_service/
│   │   ├── test_team_create.py
│   │   ├── test_team_member_add.py
│   │   └── ...
│   │
│   ├── role_service/
│   │   ├── test_role_create.py
│   │   ├── test_role_assign.py
│   │   └── ...
│   │
│   ├── authorizer_service/
│   │   └── test_authorizer.py
│   │
│   └── audit_service/
│       ├── test_audit_log.py
│       └── test_audit_query.py
│
├── integration/                   # Integration tests (real AWS)
│   ├── __init__.py
│   ├── conftest.py               # Integration fixtures
│   ├── test_permission_api.py
│   ├── test_invitation_flow.py
│   ├── test_team_management.py
│   ├── test_role_assignment.py
│   └── test_audit_logging.py
│
├── contract/                      # API contract tests
│   ├── __init__.py
│   ├── conftest.py
│   ├── test_openapi_compliance.py
│   ├── test_response_schemas.py
│   └── test_error_formats.py
│
├── authorization/                 # Security tests
│   ├── __init__.py
│   ├── conftest.py
│   ├── test_permission_enforcement.py
│   ├── test_team_isolation.py
│   ├── test_org_boundaries.py
│   └── test_authorizer_security.py
│
└── smoke/                         # Deployment verification
    ├── __init__.py
    ├── conftest.py
    ├── test_health_checks.py
    ├── test_api_reachability.py
    └── test_critical_paths.py
```

---

## Success Criteria Checklist

- [x] Unit tests run on every PR
- [x] Coverage report posted to PR
- [x] Coverage threshold enforced (> 80%)
- [x] Integration tests run on develop push
- [x] Test reports generated (JUnit XML)
- [x] Parallel execution for speed (-n auto)
- [x] Contract tests for API compliance
- [x] Authorization tests for security
- [x] Codecov integration configured

---

**Completed By**: Worker 3
**Date**: 2026-01-25
