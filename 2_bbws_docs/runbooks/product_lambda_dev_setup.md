# Product Lambda Development Setup

**Service**: Product Lambda API
**Last Updated**: 2025-12-29

---

## Prerequisites

- Python 3.12
- Git
- AWS CLI
- Terraform >= 1.5.0
- Code editor (VS Code recommended)

---

## Initial Setup

### 1. Clone Repository
```bash
git clone https://github.com/BigBeardWebSolutions/2_bbws_product_lambda.git
cd 2_bbws_product_lambda
```

### 2. Set Up Python Environment
```bash
# Create virtual environment
python3.12 -m venv venv

# Activate (macOS/Linux)
source venv/bin/activate

# Activate (Windows)
venv\Scripts\activate

# Install dependencies
pip install -r requirements-dev.txt
```

### 3. Configure AWS Credentials
```bash
# Configure AWS CLI
aws configure --profile bbws-dev

# Set profile
export AWS_PROFILE=bbws-dev

# Verify access
aws sts get-caller-identity
```

---

## Running Tests

### Run All Tests
```bash
pytest
```

### Run with Coverage
```bash
pytest --cov=src --cov-report=html
open htmlcov/index.html
```

### Run Specific Tests
```bash
# Unit tests only
pytest tests/unit/

# Specific test file
pytest tests/unit/models/test_product.py

# Specific test function
pytest tests/unit/models/test_product.py::test_product_model_basic_creation
```

---

## Code Quality Checks

### Format Code
```bash
# Format all Python files
black src/ tests/

# Check formatting without changes
black --check src/ tests/
```

### Type Checking
```bash
# Run mypy on source code
mypy src/
```

### Linting
```bash
# Check for issues
ruff check src/ tests/

# Fix auto-fixable issues
ruff check --fix src/ tests/
```

### Run All Quality Checks
```bash
# One command to run all checks
black --check src/ tests/ && \
mypy src/ && \
ruff check src/ tests/ && \
pytest --cov=src --cov-fail-under=80
```

---

## Local Development

### Test Lambda Handler Locally
```python
# Create test file: test_local.py
from src.handlers.list_products import handler

event = {
    "httpMethod": "GET",
    "path": "/v1.0/products",
    "headers": {"Accept": "application/json"}
}

class Context:
    aws_request_id = "test-request-id"

response = handler(event, Context())
print(response)
```

### Test with Mocked DynamoDB
```python
# Tests automatically use moto for DynamoDB mocking
# See tests/conftest.py for fixtures

pytest tests/unit/repositories/
```

---

## Working with Terraform

### Initialize
```bash
cd terraform

terraform init \
  -backend-config="bucket=bbws-terraform-state-dev" \
  -backend-config="key=product-lambda/dev/terraform.tfstate" \
  -backend-config="region=eu-west-1" \
  -backend-config="dynamodb_table=terraform-state-lock-dev" \
  -backend-config="encrypt=true"
```

### Plan Changes
```bash
terraform plan -var-file=environments/dev.tfvars
```

### Format Terraform
```bash
terraform fmt -recursive
```

### Validate
```bash
terraform validate
```

---

## Development Workflow

### 1. Create Feature Branch
```bash
git checkout -b feature/your-feature-name
```

### 2. Implement Changes (TDD)
```bash
# Write test first
vim tests/unit/services/test_new_feature.py

# Run test (should fail)
pytest tests/unit/services/test_new_feature.py

# Implement feature
vim src/services/product_service.py

# Run test (should pass)
pytest tests/unit/services/test_new_feature.py
```

### 3. Run Quality Checks
```bash
black src/ tests/
mypy src/
ruff check src/ tests/
pytest --cov=src --cov-fail-under=80
```

### 4. Commit Changes
```bash
git add .
git commit -m "feat: add new feature"
```

### 5. Push and Create PR
```bash
git push origin feature/your-feature-name
# Create PR on GitHub
```

---

## Debugging

### Enable Debug Logging
```bash
# Set environment variable
export LOG_LEVEL=DEBUG

# Run tests with debug output
pytest -s tests/unit/handlers/
```

### Use Python Debugger
```python
# Add breakpoint in code
import pdb; pdb.set_trace()

# Run test
pytest tests/unit/services/test_product_service.py
```

---

## Common Issues

### Issue: Import Errors
```bash
# Ensure virtual environment is activated
source venv/bin/activate

# Reinstall dependencies
pip install -r requirements-dev.txt
```

### Issue: Test Failures
```bash
# Check test output
pytest -vv

# Run single failing test
pytest tests/unit/path/to/test.py::test_name -vv
```

### Issue: Moto Mocking Issues
```bash
# Ensure moto[all] is installed
pip install 'moto[all]==5.0.24'

# Check conftest.py fixtures are loaded
pytest --fixtures | grep dynamodb
```

---

## IDE Configuration

### VS Code Settings
```json
{
  "python.defaultInterpreterPath": "./venv/bin/python",
  "python.testing.pytestEnabled": true,
  "python.testing.unittestEnabled": false,
  "python.linting.enabled": true,
  "python.linting.mypyEnabled": true,
  "python.formatting.provider": "black",
  "[python]": {
    "editor.formatOnSave": true
  }
}
```

---

**Related**: `product_lambda_deployment.md`, `product_lambda_cicd_guide.md`
