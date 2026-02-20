# Worker Instructions: GitHub Repository Setup

**Worker ID**: worker-1-github-repo-setup
**Stage**: Stage 1 - Repository Setup & Infrastructure Code
**Project**: project-plan-campaigns

---

## Task

Create the GitHub repository `2_bbws_campaigns_lambda` with the complete project structure for the Campaign Management Lambda service.

---

## Inputs

**Primary Input**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/2.1.3_LLD_Campaigns_Lambda.md`

**Reference**:
- Section 16: Appendices > Project Structure

---

## Deliverables

Create the complete repository structure:

### 1. Root Directory
```
2_bbws_campaigns_lambda/
├── .gitignore
├── .python-version
├── README.md
├── requirements.txt
├── requirements-dev.txt
├── pytest.ini
└── pyproject.toml
```

### 2. Source Directory
```
src/
├── __init__.py
├── handlers/
│   ├── __init__.py
│   ├── list_campaigns.py
│   ├── get_campaign.py
│   ├── create_campaign.py
│   ├── update_campaign.py
│   └── delete_campaign.py
├── services/
│   ├── __init__.py
│   └── campaign_service.py
├── repositories/
│   ├── __init__.py
│   └── campaign_repository.py
├── models/
│   ├── __init__.py
│   └── campaign.py
├── validators/
│   ├── __init__.py
│   └── campaign_validator.py
├── exceptions/
│   ├── __init__.py
│   └── campaign_exceptions.py
└── utils/
    ├── __init__.py
    ├── response_builder.py
    ├── date_utils.py
    └── logger.py
```

### 3. Tests Directory
```
tests/
├── __init__.py
├── conftest.py
├── unit/
│   ├── __init__.py
│   ├── handlers/
│   │   ├── __init__.py
│   │   ├── test_list_campaigns.py
│   │   ├── test_get_campaign.py
│   │   ├── test_create_campaign.py
│   │   ├── test_update_campaign.py
│   │   └── test_delete_campaign.py
│   ├── services/
│   │   ├── __init__.py
│   │   └── test_campaign_service.py
│   └── repositories/
│       ├── __init__.py
│       └── test_campaign_repository.py
└── integration/
    ├── __init__.py
    ├── test_campaign_api.py
    └── test_campaign_crud_flow.py
```

### 4. Terraform Directory
```
terraform/
├── main.tf
├── variables.tf
├── outputs.tf
├── lambda.tf
├── dynamodb.tf
├── api_gateway.tf
├── iam.tf
├── cloudwatch.tf
├── versions.tf
└── environments/
    ├── dev.tfvars
    ├── sit.tfvars
    └── prod.tfvars
```

### 5. OpenAPI Directory
```
openapi/
└── campaigns-api.yaml
```

### 6. GitHub Workflows Directory
```
.github/
└── workflows/
    ├── build-test.yml
    ├── terraform-plan.yml
    ├── deploy.yml
    └── promotion.yml
```

---

## File Contents

### .gitignore
```gitignore
# Python
__pycache__/
*.py[cod]
*$py.class
.Python
build/
dist/
*.egg-info/
.eggs/
*.egg
.env
venv/
ENV/

# IDE
.idea/
.vscode/
*.swp
*.swo

# Terraform
.terraform/
*.tfstate
*.tfstate.*
*.tfplan
.terraform.lock.hcl
crash.log

# Testing
.pytest_cache/
.coverage
htmlcov/
.tox/

# Lambda
*.zip
package/

# OS
.DS_Store
Thumbs.db
```

### requirements.txt
```txt
boto3>=1.34.0
pydantic>=2.5.0
aws-lambda-powertools>=2.30.0
```

### requirements-dev.txt
```txt
-r requirements.txt
pytest>=7.4.0
pytest-cov>=4.1.0
pytest-mock>=3.12.0
moto>=4.2.0
black>=23.12.0
isort>=5.13.0
flake8>=6.1.0
mypy>=1.7.0
```

### pytest.ini
```ini
[pytest]
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*
addopts = -v --cov=src --cov-report=term-missing --cov-report=html
filterwarnings =
    ignore::DeprecationWarning
```

### .python-version
```
3.12
```

---

## Success Criteria

- [ ] Repository structure matches LLD Section 16
- [ ] All __init__.py files created
- [ ] .gitignore includes Python, Terraform, IDE files
- [ ] requirements.txt has correct dependencies
- [ ] pytest.ini configured correctly
- [ ] All directories exist with placeholder files

---

## Execution Steps

1. Create repository root directory
2. Create .gitignore, requirements.txt, requirements-dev.txt
3. Create pytest.ini and pyproject.toml
4. Create src/ directory structure with __init__.py files
5. Create tests/ directory structure with __init__.py files
6. Create terraform/ directory structure
7. Create openapi/ directory
8. Create .github/workflows/ directory
9. Create README.md placeholder
10. Validate all files exist
11. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-15
