# DevOps Agent Specification

**Version**: 1.0
**Date**: 2025-12-14
**Status**: Draft - Pending Approval
**Author**: Agentic Architect

---

## Document Purpose

This specification defines the DevOps Agent for the BBWS Multi-Tenant WordPress Platform. The agent automates the entire software delivery lifecycle from code generation to production deployment, following infrastructure-as-code principles and GitOps practices.

---

## 1. Agent Identity and Purpose

```
Agent Name: DevOps Agent (BBWS Multi-Tenant WordPress)

Primary Purpose:
This agent automates the complete software delivery lifecycle for the BBWS platform.
It reads Low-Level Design (LLD) documents, generates implementation code, creates CI/CD
pipelines using GitHub Actions, provisions infrastructure with Terraform, runs local
tests, and orchestrates deployments across DEV, SIT, and PROD environments.

Value Provided:
- GitHub repository creation and configuration
- Automated code generation from LLD specifications
- Consistent CI/CD pipeline creation and management
- Pipeline testing and validation
- Infrastructure-as-Code deployment with Terraform
- Local development and testing automation
- Environment promotion with approval gates
- Deployment rollback and recovery capabilities
- Security scanning and compliance validation
- Release management and versioning
```

---

## 2. Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         DevOps Agent Architecture                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                      DevOps Agent Core                               │   │
│  ├─────────────────────────────────────────────────────────────────────┤   │
│  │                                                                     │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │   │
│  │  │  Repository  │  │ LLD Reader   │  │    Code      │              │   │
│  │  │   Manager    │  │ & Parser     │  │  Generator   │              │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘              │   │
│  │                                                                     │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │   │
│  │  │   Pipeline   │  │   Pipeline   │  │  Terraform   │              │   │
│  │  │   Manager    │  │   Tester     │  │   Manager    │              │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘              │   │
│  │                                                                     │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │   │
│  │  │    Local     │  │  Deployment  │  │  Rollback    │              │   │
│  │  │    Runner    │  │  Orchestrator│  │   Handler    │              │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘              │   │
│  │                                                                     │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │   │
│  │  │   Security   │  │   Release    │  │  Monitoring  │              │   │
│  │  │   Scanner    │  │   Manager    │  │   Agent      │              │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘              │   │
│  │                                                                     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                        │
├────────────────────────────────────┼────────────────────────────────────────┤
│              Python CLI Utilities Layer (.claude/utils/devops/)             │
├────────────────────────────────────┼────────────────────────────────────────┤
│                                    │                                        │
│  repo_cli.py   lld_parser.py   code_gen.py   pipeline_cli.py               │
│  pipeline_test.py   terraform_cli.py   local_runner.py   deploy_cli.py     │
│  security_cli.py   release_cli.py   monitor_cli.py                         │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                          External Services                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│  GitHub │ GitHub Actions │ AWS (DEV/SIT/PROD) │ Terraform Cloud │ Docker   │
│  ECR │ S3 │ DynamoDB │ CloudWatch │ Secrets Manager │ SNS                   │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Environment Configuration

The DevOps Agent operates across three AWS environments with strict promotion flow:

| Environment | AWS Account ID | Primary Region | DR Region | Deployment |
|-------------|---------------|----------------|-----------|------------|
| **DEV** | 536580886816 | af-south-1 | eu-west-1 | Automated |
| **SIT** | 815856636111 | af-south-1 | eu-west-1 | Manual Approval |
| **PROD** | 093646564004 | af-south-1 | eu-west-1 | BO + Tech Lead Approval |

**Critical Safety Rules**:
- All deployments MUST validate AWS account ID before any operation
- PROD deployments require Business Owner approval
- No direct deployments to SIT/PROD - must promote from lower environment
- All infrastructure changes require Terraform plan review

---

## 4. Core Capabilities (Skills)

### 4.1 Skill: repo_manage

**Description**: Create and manage GitHub repositories with full configuration

**Operations**:
```yaml
repo_manage:
  create_repository:
    - Create new GitHub repository using gh CLI
    - Configure repository settings (visibility, description)
    - Set up branch protection rules (main branch)
    - Configure required status checks
    - Enable required reviewers for PRs
    - Set up CODEOWNERS file
    - Initialize with README and .gitignore
    - Create initial directory structure

  configure_environments:
    - Create GitHub environments (dev, sit, prod)
    - Configure environment protection rules
    - Set required reviewers per environment
    - Configure deployment branches
    - Set environment secrets references
    - Configure wait timer (for prod)

  configure_secrets:
    - Set repository secrets (AWS credentials, tokens)
    - Set environment-specific secrets
    - Configure OIDC for AWS authentication
    - Validate secret availability
    - Rotate secrets on schedule

  configure_branch_protection:
    - Protect main/master branch
    - Require PR reviews (minimum 1)
    - Require status checks to pass
    - Require signed commits (optional)
    - Restrict force pushes
    - Restrict deletions

  configure_webhooks:
    - Set up deployment notifications
    - Configure Slack/Teams webhooks
    - Set up status check webhooks
    - Configure PR notification webhooks

  clone_repository:
    - Clone repository to local workspace
    - Set up git configuration
    - Configure upstream remote
    - Fetch all branches and tags

  setup_repository_from_lld:
    - Read LLD specification
    - Create repository with naming convention (2_bbws_{service}_lambda)
    - Generate full scaffold (code, tests, terraform, pipelines)
    - Push initial commit
    - Configure environments and secrets
    - Set up branch protection
    - Return repository URL
```

**CLI Command**: `python .claude/utils/devops/repo_cli.py [create|configure|secrets|branches|webhooks|clone|setup-from-lld] --name <repo_name> [--org <org>] [--lld <path>]`

**Repository Creation Flow**:
```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    REPOSITORY CREATION FLOW                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  1. CREATE REPOSITORY                                                       │
│     ├── gh repo create {org}/2_bbws_{service}_lambda --private             │
│     ├── Set description from LLD                                           │
│     └── Initialize with README                                             │
│                                                                             │
│  2. GENERATE SCAFFOLD                                                       │
│     ├── Create directory structure (src/, tests/, terraform/)              │
│     ├── Generate code from LLD                                             │
│     ├── Create GitHub Actions workflows                                    │
│     └── Generate configuration files                                       │
│                                                                             │
│  3. CONFIGURE ENVIRONMENTS                                                  │
│     ├── Create 'dev' environment (no protection)                           │
│     ├── Create 'sit' environment (require reviewer)                        │
│     └── Create 'prod' environment (require BO + Tech Lead)                 │
│                                                                             │
│  4. CONFIGURE SECRETS                                                       │
│     ├── AWS_ROLE_ARN_DEV                                                   │
│     ├── AWS_ROLE_ARN_SIT                                                   │
│     ├── AWS_ROLE_ARN_PROD                                                  │
│     └── SNS_TOPIC_ARN                                                      │
│                                                                             │
│  5. CONFIGURE BRANCH PROTECTION                                             │
│     ├── Protect 'main' branch                                              │
│     ├── Require PR reviews                                                 │
│     ├── Require status checks (ci, security)                               │
│     └── Restrict force push                                                │
│                                                                             │
│  6. INITIAL COMMIT & PUSH                                                   │
│     ├── git add -A                                                         │
│     ├── git commit -m "feat: initial scaffold from LLD"                    │
│     └── git push -u origin main                                            │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

**GitHub Environment Configuration**:
```yaml
environments:
  dev:
    protection_rules: []
    deployment_branch: main
    secrets:
      - AWS_ROLE_ARN: arn:aws:iam::536580886816:role/github-actions-role

  sit:
    protection_rules:
      - required_reviewers: [dev-lead]
      - wait_timer: 0
    deployment_branch: main
    secrets:
      - AWS_ROLE_ARN: arn:aws:iam::815856636111:role/github-actions-role

  prod:
    protection_rules:
      - required_reviewers: [business-owner, tech-lead]
      - wait_timer: 30  # 30 minute wait
    deployment_branch: main
    secrets:
      - AWS_ROLE_ARN: arn:aws:iam::093646564004:role/github-actions-role
```

---

### 4.2 Skill: lld_read

**Description**: Read and parse Low-Level Design documents to extract implementation specifications

**Operations**:
```yaml
lld_read:
  parse_lld:
    - Read LLD markdown document from specified path
    - Extract component specifications (APIs, models, services)
    - Parse DynamoDB schema definitions (PK, SK, GSIs)
    - Extract Lambda function specifications
    - Parse API Gateway endpoint definitions
    - Extract test case specifications
    - Validate LLD completeness and consistency
    - Generate implementation checklist

  extract_api_specs:
    - Parse OpenAPI/Swagger specifications from LLD
    - Extract request/response schemas
    - Identify authentication requirements
    - Map endpoints to Lambda functions
    - Generate API documentation

  extract_data_models:
    - Parse DynamoDB table definitions
    - Extract entity relationships
    - Identify GSI requirements
    - Generate data model classes
    - Create sample data fixtures

  validate_lld:
    - Check for missing sections
    - Validate schema consistency
    - Verify API endpoint completeness
    - Check test coverage requirements
    - Generate validation report
```

**CLI Command**: `python .claude/utils/devops/lld_parser.py [parse|extract-api|extract-models|validate] --lld <path>`

---

### 4.3 Skill: code_generate

**Description**: Generate implementation code from LLD specifications

**Operations**:
```yaml
code_generate:
  generate_lambda:
    - Create Lambda handler boilerplate (Python 3.12)
    - Generate service layer classes
    - Create data model classes (Pydantic)
    - Generate repository layer for DynamoDB
    - Create utility functions
    - Generate exception handlers
    - Apply OOP patterns from LLD

  generate_api:
    - Create API Gateway OpenAPI spec
    - Generate request/response validators
    - Create authentication middleware
    - Generate CORS configuration
    - Create error response handlers

  generate_tests:
    - Create unit test boilerplate (pytest)
    - Generate integration test scaffolding
    - Create mock fixtures
    - Generate test data factories
    - Create conftest.py with shared fixtures

  generate_terraform:
    - Create Lambda Terraform module
    - Generate API Gateway resources
    - Create IAM role definitions
    - Generate CloudWatch log groups
    - Create DynamoDB table definitions
    - Generate environment-specific tfvars

  generate_dockerfile:
    - Create Lambda container Dockerfile
    - Generate multi-stage build configuration
    - Add security scanning layers
    - Create .dockerignore

  scaffold_repository:
    - Create full repository structure
    - Generate README.md
    - Create requirements.txt / pyproject.toml
    - Generate .gitignore
    - Create pre-commit configuration
    - Add code formatting configs (black, isort, flake8)
```

**CLI Command**: `python .claude/utils/devops/code_gen.py [lambda|api|tests|terraform|docker|scaffold] --lld <path> --output <dir>`

**Repository Structure Generated**:
```
2_bbws_{service}_lambda/
├── src/
│   ├── __init__.py
│   ├── handlers/
│   │   ├── __init__.py
│   │   └── {handler}.py
│   ├── services/
│   │   ├── __init__.py
│   │   └── {service}.py
│   ├── models/
│   │   ├── __init__.py
│   │   └── {model}.py
│   ├── repositories/
│   │   ├── __init__.py
│   │   └── {repository}.py
│   └── utils/
│       ├── __init__.py
│       ├── exceptions.py
│       └── validators.py
├── tests/
│   ├── __init__.py
│   ├── conftest.py
│   ├── unit/
│   │   └── test_{service}.py
│   └── integration/
│       └── test_{handler}.py
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── lambda.tf
│   ├── api_gateway.tf
│   ├── iam.tf
│   └── environments/
│       ├── dev.tfvars
│       ├── sit.tfvars
│       └── prod.tfvars
├── .github/
│   └── workflows/
│       ├── ci.yml
│       ├── deploy-dev.yml
│       ├── promote-sit.yml
│       └── promote-prod.yml
├── Dockerfile
├── requirements.txt
├── requirements-dev.txt
├── pyproject.toml
├── pytest.ini
├── .pre-commit-config.yaml
├── .gitignore
└── README.md
```

---

### 4.4 Skill: pipeline_create

**Description**: Create and manage GitHub Actions CI/CD pipelines

**Operations**:
```yaml
pipeline_create:
  create_ci_pipeline:
    - Generate CI workflow (lint, test, security scan)
    - Configure Python 3.12 environment
    - Add dependency caching
    - Configure pytest with coverage
    - Add code quality checks (black, isort, flake8, mypy)
    - Add security scanning (bandit, safety)
    - Generate coverage reports
    - Configure artifact uploads

  create_deploy_dev_pipeline:
    - Generate DEV deployment workflow
    - Configure AWS credentials (OIDC)
    - Add Terraform plan/apply steps
    - Configure Lambda deployment
    - Add API Gateway deployment
    - Configure automatic rollback on failure
    - Add smoke tests post-deployment
    - Send deployment notifications (SNS)

  create_promote_sit_pipeline:
    - Generate SIT promotion workflow
    - Configure manual approval gate
    - Copy artifacts from DEV
    - Terraform plan for SIT
    - Require approval before apply
    - Deploy to SIT account
    - Run integration tests
    - Send promotion notifications

  create_promote_prod_pipeline:
    - Generate PROD promotion workflow
    - Configure BO approval gate
    - Configure Tech Lead approval gate
    - Copy artifacts from SIT
    - Terraform plan for PROD
    - Require dual approval before apply
    - Blue/green deployment strategy
    - Canary release configuration
    - Automated rollback triggers
    - Send go-live notifications

  create_rollback_pipeline:
    - Generate rollback workflow
    - List previous deployments
    - Select rollback target
    - Execute Terraform rollback
    - Verify service health
    - Send rollback notifications

  update_pipeline:
    - Modify existing workflow
    - Add/remove pipeline stages
    - Update environment variables
    - Modify approval requirements
    - Update notification channels
```

**CLI Command**: `python .claude/utils/devops/pipeline_cli.py [create-ci|create-deploy|create-promote|create-rollback|update] --repo <path> --env <dev|sit|prod>`

**GitHub Actions Workflow Templates**:

**CI Pipeline** (`.github/workflows/ci.yml`):
```yaml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: '3.12'
      - run: pip install black isort flake8 mypy
      - run: black --check src/ tests/
      - run: isort --check-only src/ tests/
      - run: flake8 src/ tests/
      - run: mypy src/

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: '3.12'
      - run: pip install -r requirements-dev.txt
      - run: pytest --cov=src --cov-report=xml
      - uses: codecov/codecov-action@v3

  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: pip install bandit safety
      - run: bandit -r src/
      - run: safety check -r requirements.txt
```

**DEV Deploy Pipeline** (`.github/workflows/deploy-dev.yml`):
```yaml
name: Deploy to DEV

on:
  push:
    branches: [main]

permissions:
  id-token: write
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: dev
    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::536580886816:role/github-actions-role
          aws-region: af-south-1

      - name: Validate AWS Account
        run: |
          ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
          if [ "$ACCOUNT_ID" != "536580886816" ]; then
            echo "ERROR: Wrong AWS account! Expected DEV (536580886816), got $ACCOUNT_ID"
            exit 1
          fi

      - name: Terraform Plan
        run: |
          cd terraform
          terraform init
          terraform plan -var-file=environments/dev.tfvars -out=tfplan

      - name: Terraform Apply
        run: |
          cd terraform
          terraform apply -auto-approve tfplan

      - name: Smoke Tests
        run: |
          python scripts/smoke_tests.py --env dev

      - name: Notify Success
        if: success()
        run: |
          aws sns publish --topic-arn ${{ secrets.SNS_TOPIC_ARN }} \
            --message "DEV deployment successful: ${{ github.sha }}"
```

**SIT Promote Pipeline** (`.github/workflows/promote-sit.yml`):
```yaml
name: Promote to SIT

on:
  workflow_dispatch:
    inputs:
      version:
        description: 'Version to promote'
        required: true

permissions:
  id-token: write
  contents: read

jobs:
  promote:
    runs-on: ubuntu-latest
    environment: sit
    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::815856636111:role/github-actions-role
          aws-region: af-south-1

      - name: Validate AWS Account
        run: |
          ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
          if [ "$ACCOUNT_ID" != "815856636111" ]; then
            echo "ERROR: Wrong AWS account! Expected SIT (815856636111), got $ACCOUNT_ID"
            exit 1
          fi

      - name: Terraform Plan
        run: |
          cd terraform
          terraform init
          terraform plan -var-file=environments/sit.tfvars -out=tfplan

      - name: Terraform Apply
        run: |
          cd terraform
          terraform apply -auto-approve tfplan

      - name: Integration Tests
        run: |
          python scripts/integration_tests.py --env sit

      - name: Notify Success
        if: success()
        run: |
          aws sns publish --topic-arn ${{ secrets.SNS_TOPIC_ARN }} \
            --message "SIT promotion successful: ${{ github.event.inputs.version }}"
```

**PROD Promote Pipeline** (`.github/workflows/promote-prod.yml`):
```yaml
name: Promote to PROD

on:
  workflow_dispatch:
    inputs:
      version:
        description: 'Version to promote'
        required: true

permissions:
  id-token: write
  contents: read

jobs:
  promote:
    runs-on: ubuntu-latest
    environment: prod  # Requires BO + Tech Lead approval
    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::093646564004:role/github-actions-role
          aws-region: af-south-1

      - name: Validate AWS Account
        run: |
          ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
          if [ "$ACCOUNT_ID" != "093646564004" ]; then
            echo "ERROR: Wrong AWS account! Expected PROD (093646564004), got $ACCOUNT_ID"
            exit 1
          fi

      - name: Pre-deployment Backup
        run: |
          python scripts/backup.py --env prod --pre-deploy

      - name: Terraform Plan
        run: |
          cd terraform
          terraform init
          terraform plan -var-file=environments/prod.tfvars -out=tfplan

      - name: Terraform Apply
        run: |
          cd terraform
          terraform apply -auto-approve tfplan

      - name: Canary Deployment (10%)
        run: |
          python scripts/canary_deploy.py --env prod --traffic 10

      - name: Canary Validation
        run: |
          python scripts/canary_validate.py --env prod --duration 300

      - name: Full Deployment (100%)
        run: |
          python scripts/canary_deploy.py --env prod --traffic 100

      - name: Production Smoke Tests
        run: |
          python scripts/smoke_tests.py --env prod

      - name: Notify Go-Live
        if: success()
        run: |
          aws sns publish --topic-arn ${{ secrets.SNS_TOPIC_ARN }} \
            --message "PROD go-live successful: ${{ github.event.inputs.version }}"
```

---

### 4.5 Skill: pipeline_test

**Description**: Test and validate CI/CD pipelines before and during deployment

**Operations**:
```yaml
pipeline_test:
  validate_workflow:
    - Validate GitHub Actions workflow syntax (actionlint)
    - Check for deprecated actions
    - Validate action versions
    - Check for security issues in workflows
    - Validate environment references
    - Check secret references exist

  dry_run_pipeline:
    - Simulate pipeline execution locally (act)
    - Test CI pipeline without pushing
    - Validate job dependencies
    - Check artifact paths
    - Verify environment variables
    - Test matrix builds

  test_ci_pipeline:
    - Run lint job locally
    - Run test job locally
    - Run security scan job locally
    - Validate coverage thresholds
    - Check all jobs pass
    - Generate test report

  test_deployment_pipeline:
    - Validate AWS credentials configuration
    - Test Terraform init/plan (dry-run)
    - Validate deployment scripts
    - Test smoke test scripts
    - Validate rollback scripts
    - Check notification configuration

  test_promotion_pipeline:
    - Validate approval gate configuration
    - Test artifact copy between environments
    - Validate environment protection rules
    - Test promotion scripts
    - Validate canary deployment logic
    - Check traffic shifting configuration

  integration_test_pipeline:
    - Run full CI pipeline on branch
    - Deploy to DEV and validate
    - Run integration tests
    - Validate deployment artifacts
    - Check CloudWatch logs
    - Generate integration report

  load_test_pipeline:
    - Configure load test parameters
    - Run locust/k6 load tests
    - Monitor performance metrics
    - Validate response times
    - Check error rates
    - Generate load test report

  chaos_test_pipeline:
    - Configure chaos scenarios
    - Test failure recovery
    - Validate auto-rollback
    - Test circuit breakers
    - Check alerting triggers
    - Generate resilience report
```

**CLI Command**: `python .claude/utils/devops/pipeline_test.py [validate|dry-run|ci|deploy|promote|integration|load|chaos] --workflow <path> [--env <dev|sit|prod>]`

**Pipeline Testing Flow**:
```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    PIPELINE TESTING FLOW                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  1. VALIDATE SYNTAX                                                         │
│     ├── actionlint .github/workflows/*.yml                                 │
│     ├── Check YAML structure                                               │
│     └── Validate action references                                         │
│                                                                             │
│  2. DRY RUN (LOCAL)                                                         │
│     ├── act -n (dry run)                                                   │
│     ├── act -j lint (run specific job)                                     │
│     └── act -j test (run test job)                                         │
│                                                                             │
│  3. TEST CI PIPELINE                                                        │
│     ├── Push to feature branch                                             │
│     ├── Monitor workflow execution                                         │
│     ├── Validate all jobs pass                                             │
│     └── Check artifacts created                                            │
│                                                                             │
│  4. TEST DEPLOYMENT PIPELINE                                                │
│     ├── Trigger manual workflow (workflow_dispatch)                        │
│     ├── Monitor deployment to DEV                                          │
│     ├── Validate infrastructure created                                    │
│     ├── Run smoke tests                                                    │
│     └── Validate notifications sent                                        │
│                                                                             │
│  5. TEST PROMOTION PIPELINE                                                 │
│     ├── Trigger promotion workflow                                         │
│     ├── Verify approval gate works                                         │
│     ├── Approve and monitor deployment                                     │
│     ├── Validate environment isolation                                     │
│     └── Check audit logs                                                   │
│                                                                             │
│  6. INTEGRATION TEST                                                        │
│     ├── Full E2E pipeline run                                              │
│     ├── DEV → SIT promotion                                                │
│     ├── Validate all environments                                          │
│     └── Generate test report                                               │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Local Pipeline Testing with `act`**:
```bash
# Install act (GitHub Actions local runner)
brew install act

# Dry run - validate without executing
act -n

# Run specific job
act -j lint
act -j test
act -j security

# Run with specific event
act push
act pull_request
act workflow_dispatch

# Run with secrets
act -s AWS_ACCESS_KEY_ID=xxx -s AWS_SECRET_ACCESS_KEY=xxx

# Run with specific workflow
act -W .github/workflows/ci.yml
```

**Pipeline Validation Checks**:
```yaml
validation_checks:
  syntax:
    - YAML structure valid
    - Action names resolve
    - Job dependencies valid
    - Step references valid

  security:
    - No hardcoded secrets
    - Uses OIDC authentication
    - Secrets not logged
    - Permissions minimized

  best_practices:
    - Uses pinned action versions
    - Has timeout configured
    - Has concurrency limits
    - Caches dependencies
    - Uploads artifacts

  deployment:
    - Account validation present
    - Rollback configured
    - Notifications configured
    - Smoke tests included
```

---

### 4.6 Skill: terraform_manage

**Description**: Manage Terraform infrastructure provisioning and state

**Operations**:
```yaml
terraform_manage:
  init:
    - Initialize Terraform working directory
    - Configure backend (S3 + DynamoDB locking)
    - Download required providers
    - Validate backend configuration
    - Check state file accessibility

  plan:
    - Generate execution plan
    - Show resource changes (create, update, destroy)
    - Validate against environment tfvars
    - Check for security policy violations
    - Estimate cost changes
    - Save plan to file for apply

  apply:
    - Apply Terraform plan (requires saved plan file)
    - Validate AWS account ID before apply
    - Execute with auto-approve (CI/CD only)
    - Capture outputs
    - Update state file
    - Log all changes

  destroy:
    - Generate destroy plan
    - Require explicit confirmation
    - BLOCKED for PROD (requires manual intervention)
    - Execute destruction
    - Clean up state

  validate:
    - Validate Terraform syntax
    - Check resource references
    - Validate variable definitions
    - Check provider configurations

  format:
    - Format Terraform files (terraform fmt)
    - Check formatting in CI
    - Auto-fix formatting issues

  state_manage:
    - List state resources
    - Show resource details
    - Import existing resources
    - Remove resources from state
    - Move resources between states
    - Refresh state from cloud

  workspace_manage:
    - Create workspaces (dev, sit, prod)
    - Switch between workspaces
    - List available workspaces
    - Delete workspaces (non-prod only)

  module_manage:
    - Create reusable modules
    - Publish modules to registry
    - Update module versions
    - Validate module compatibility
```

**CLI Command**: `python .claude/utils/devops/terraform_cli.py [init|plan|apply|destroy|validate|format|state|workspace] --env <dev|sit|prod> --path <terraform_dir>`

**Terraform Backend Configuration**:
```hcl
terraform {
  backend "s3" {
    bucket         = "bbws-terraform-state-${var.environment}"
    key            = "${var.service_name}/terraform.tfstate"
    region         = "af-south-1"
    encrypt        = true
    dynamodb_table = "bbws-terraform-locks-${var.environment}"
  }
}
```

---

### 4.7 Skill: local_run

**Description**: Run code and tests locally in development environment

**Operations**:
```yaml
local_run:
  setup_environment:
    - Create Python virtual environment
    - Install dependencies (pip install -r requirements.txt)
    - Install dev dependencies
    - Configure pre-commit hooks
    - Set up local environment variables
    - Validate Python version (3.12)

  run_tests:
    - Run unit tests (pytest)
    - Run integration tests
    - Generate coverage report
    - Run with specific markers
    - Run single test file/function
    - Run tests in parallel
    - Watch mode for TDD

  run_lint:
    - Run black (code formatting)
    - Run isort (import sorting)
    - Run flake8 (linting)
    - Run mypy (type checking)
    - Run bandit (security)
    - Auto-fix where possible

  run_local_lambda:
    - Start LocalStack for AWS services
    - Create local DynamoDB tables
    - Invoke Lambda locally (SAM CLI)
    - Test API Gateway locally
    - View CloudWatch logs locally

  run_docker:
    - Build Docker image locally
    - Run container with local mounts
    - Execute tests in container
    - Scan image for vulnerabilities
    - Push to local registry

  run_security_scan:
    - Run dependency vulnerability scan (safety)
    - Run code security scan (bandit)
    - Run secrets detection (detect-secrets)
    - Run SAST analysis
    - Generate security report

  run_pre_commit:
    - Run all pre-commit hooks
    - Validate commit message format
    - Check for large files
    - Detect secrets
    - Run formatters and linters
```

**CLI Command**: `python .claude/utils/devops/local_runner.py [setup|test|lint|lambda|docker|security|pre-commit] [--watch] [--parallel]`

**Local Development Commands**:
```bash
# Setup
python .claude/utils/devops/local_runner.py setup

# Run tests with coverage
python .claude/utils/devops/local_runner.py test --coverage

# Run tests in watch mode (TDD)
python .claude/utils/devops/local_runner.py test --watch

# Run all linters with auto-fix
python .claude/utils/devops/local_runner.py lint --fix

# Run Lambda locally with LocalStack
python .claude/utils/devops/local_runner.py lambda --event event.json

# Run full pre-commit checks
python .claude/utils/devops/local_runner.py pre-commit
```

---

### 4.8 Skill: deploy

**Description**: Deploy to AWS environments (DEV, SIT, PROD)

**Operations**:
```yaml
deploy:
  deploy_dev:
    - Validate AWS credentials for DEV account
    - Build Lambda deployment package
    - Push Docker image to ECR (if containerized)
    - Run Terraform plan
    - Apply Terraform changes
    - Update Lambda function code
    - Deploy API Gateway stage
    - Invalidate CloudFront cache (if applicable)
    - Run smoke tests
    - Send deployment notification

  promote_sit:
    - Verify DEV deployment successful
    - Request manual approval (GitHub environment)
    - Copy artifacts from DEV
    - Validate AWS credentials for SIT account
    - Run Terraform plan for SIT
    - Wait for approval
    - Apply Terraform changes
    - Deploy Lambda and API Gateway
    - Run integration tests
    - Send promotion notification

  promote_prod:
    - Verify SIT deployment successful and tested
    - Request Business Owner approval
    - Request Tech Lead approval
    - Copy artifacts from SIT
    - Validate AWS credentials for PROD account
    - Run Terraform plan for PROD
    - Wait for dual approval
    - Execute blue/green deployment
    - Run canary validation (10% traffic)
    - Gradual traffic shift (25% → 50% → 100%)
    - Run production smoke tests
    - Send go-live notification

  hotfix_deploy:
    - Create hotfix branch
    - Fast-track CI checks
    - Deploy to DEV with expedited approval
    - Deploy to SIT with single approval
    - Deploy to PROD with BO approval only
    - Merge hotfix to main branch
```

**CLI Command**: `python .claude/utils/devops/deploy_cli.py [dev|promote-sit|promote-prod|hotfix] --service <name> [--version <tag>]`

**Deployment Flow**:
```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        DEPLOYMENT PROMOTION FLOW                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │                          DEV DEPLOYMENT                               │  │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐   │  │
│  │  │  Build  │→│Terraform│→│ Deploy  │→│  Smoke  │→│ Notify  │   │  │
│  │  │         │  │  Plan   │  │ Lambda  │  │  Tests  │  │         │   │  │
│  │  └─────────┘  └─────────┘  └─────────┘  └─────────┘  └─────────┘   │  │
│  │                           (Automated on merge to main)              │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                     │                                       │
│                                     ▼                                       │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │                          SIT PROMOTION                                │  │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐   │  │
│  │  │ Request │→│ Manual  │→│Terraform│→│ Deploy  │→│  Int    │   │  │
│  │  │Approval │  │Approval │  │  Apply  │  │         │  │ Tests   │   │  │
│  │  └─────────┘  └─────────┘  └─────────┘  └─────────┘  └─────────┘   │  │
│  │                        (Manual trigger with approval)               │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                     │                                       │
│                                     ▼                                       │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │                          PROD PROMOTION                               │  │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐   │  │
│  │  │   BO    │→│  Tech   │→│Blue/Grn │→│ Canary  │→│ Go-Live │   │  │
│  │  │Approval │  │Lead Appr│  │ Deploy  │  │Validate │  │ 100%    │   │  │
│  │  └─────────┘  └─────────┘  └─────────┘  └─────────┘  └─────────┘   │  │
│  │                  (Dual approval + gradual traffic shift)            │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

### 4.9 Skill: rollback

**Description**: Handle deployment rollbacks and recovery

**Operations**:
```yaml
rollback:
  list_deployments:
    - List recent deployments by environment
    - Show deployment metadata (version, date, status)
    - Identify current active version
    - Show rollback candidates

  rollback_lambda:
    - Identify previous Lambda version
    - Update alias to previous version
    - Verify function health
    - Log rollback action

  rollback_terraform:
    - Identify previous Terraform state
    - Generate rollback plan
    - Apply previous state
    - Verify infrastructure health

  rollback_full:
    - Rollback Lambda functions
    - Rollback API Gateway stage
    - Rollback infrastructure (if needed)
    - Invalidate caches
    - Verify service health
    - Send rollback notification

  recover_from_failure:
    - Diagnose deployment failure
    - Identify failed component
    - Execute targeted rollback
    - Restore service health
    - Generate incident report
```

**CLI Command**: `python .claude/utils/devops/deploy_cli.py rollback --env <dev|sit|prod> --version <tag> [--component lambda|terraform|full]`

---

### 4.10 Skill: security_scan

**Description**: Perform security scanning and compliance validation

**Operations**:
```yaml
security_scan:
  dependency_scan:
    - Scan Python dependencies (safety)
    - Check for known vulnerabilities (CVEs)
    - Generate dependency report
    - Block deployment on critical vulnerabilities

  code_scan:
    - Run SAST analysis (bandit)
    - Detect hardcoded secrets (detect-secrets)
    - Check for insecure patterns
    - Validate input sanitization
    - Generate security report

  container_scan:
    - Scan Docker images (trivy)
    - Check base image vulnerabilities
    - Validate container configuration
    - Check for secrets in layers

  infrastructure_scan:
    - Scan Terraform for misconfigurations (tfsec)
    - Check IAM policy violations
    - Validate security group rules
    - Check encryption settings
    - Validate compliance (CIS benchmarks)

  secrets_scan:
    - Scan repository for secrets
    - Check environment variables
    - Validate Secrets Manager usage
    - Detect exposed credentials

  compliance_report:
    - Generate compliance summary
    - Map findings to OWASP Top 10
    - Create remediation recommendations
    - Track security debt
```

**CLI Command**: `python .claude/utils/devops/security_cli.py [dependencies|code|container|infra|secrets|report] [--fail-on critical|high|medium]`

---

### 4.11 Skill: release_manage

**Description**: Manage releases, versioning, and changelog

**Operations**:
```yaml
release_manage:
  create_release:
    - Generate semantic version (major.minor.patch)
    - Create release branch
    - Generate changelog from commits
    - Tag release in Git
    - Create GitHub release
    - Attach build artifacts

  version_bump:
    - Determine version bump type (major/minor/patch)
    - Update version files
    - Update changelog
    - Create version commit

  changelog_generate:
    - Parse commit history (conventional commits)
    - Group by type (feat, fix, chore, etc.)
    - Generate markdown changelog
    - Include breaking changes section

  artifact_manage:
    - Build release artifacts
    - Upload to S3 artifact bucket
    - Generate artifact manifest
    - Sign artifacts (optional)
    - Create artifact checksums

  release_notes:
    - Generate release notes template
    - Include feature highlights
    - List bug fixes
    - Document breaking changes
    - Add upgrade instructions
```

**CLI Command**: `python .claude/utils/devops/release_cli.py [create|bump|changelog|artifacts|notes] --version <semver> [--type major|minor|patch]`

---

### 4.12 Skill: monitor_deployment

**Description**: Monitor deployments and track metrics

**Operations**:
```yaml
monitor_deployment:
  watch_deployment:
    - Monitor deployment progress in real-time
    - Track Lambda update status
    - Watch API Gateway deployment
    - Monitor error rates during deployment
    - Alert on anomalies

  health_check:
    - Check Lambda function health
    - Verify API Gateway endpoints
    - Test database connectivity
    - Validate external integrations
    - Generate health report

  metrics_collect:
    - Collect deployment metrics
    - Track deployment duration
    - Monitor error rates
    - Measure latency changes
    - Report on success/failure rates

  alert_manage:
    - Create deployment alerts
    - Configure thresholds
    - Set up SNS notifications
    - Integrate with PagerDuty/Slack (optional)
```

**CLI Command**: `python .claude/utils/devops/deploy_cli.py monitor --env <env> [--watch] [--health-check]`

---

### 4.13 Skill: docker_manage

**Description**: Build and manage custom Docker images for WordPress with WP-CLI

**Purpose**: The standard `wordpress:latest` image lacks essential tools (WP-CLI, curl, unzip) required for safe WordPress automation. This skill creates and maintains a custom WordPress image that enables production-safe operations via WP-CLI instead of risky direct database manipulation.

**Why This Is Critical**:
```
WITHOUT Custom Image:
  Agent → Workarounds → Direct SQL → Database (RISKY, bypasses WordPress hooks)

WITH Custom Image:
  Agent → WP-CLI → WordPress Core → Database (SAFE, triggers hooks, validates data)
```

**Operations**:
```yaml
docker_manage:
  build_wordpress_image:
    - Build custom WordPress image with WP-CLI
    - Include utilities: curl, unzip, mysql-client
    - Bake in HTTPS detection mu-plugin
    - Tag with version: bbws-wordpress:{wp-version}-wpcli-{image-version}
    - Run security scan on image (Trivy/Snyk)
    - Test WP-CLI functionality in built image

  push_to_ecr:
    - Authenticate to ECR in target environment
    - Tag image for ECR: {account}.dkr.ecr.{region}.amazonaws.com/bbws-wordpress
    - Push image to ECR
    - Verify push succeeded
    - Update latest tag

  promote_image:
    - Pull image from source environment ECR
    - Retag for target environment
    - Push to target environment ECR
    - Verify image digest matches
    - Update ECS task definitions to use new image

  validate_image:
    - Pull image from ECR
    - Verify WP-CLI is functional: wp --version
    - Verify utilities present: curl, unzip, mysql
    - Verify mu-plugin exists: /var/www/html/wp-content/mu-plugins/https-fix.php
    - Run WordPress installation test
    - Generate validation report

  cleanup_old_images:
    - List ECR images older than retention period
    - Keep last N versions (configurable, default 10)
    - Delete old images
    - Report cleanup results
```

**Dockerfile Template** (`docker/wordpress/Dockerfile`):
```dockerfile
FROM wordpress:6.4-php8.2-apache

LABEL maintainer="BBWS DevOps <devops@bigbeard.co.za>"
LABEL description="WordPress with WP-CLI for BBWS Multi-Tenant Platform"
LABEL version="1.0"

# Install WP-CLI - REQUIRED for safe WordPress automation
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp \
    && wp --info --allow-root

# Install required utilities
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    unzip \
    default-mysql-client \
    less \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Create mu-plugins directory and add HTTPS fix
RUN mkdir -p /var/www/html/wp-content/mu-plugins

# Copy HTTPS detection mu-plugin (baked into image)
COPY mu-plugins/https-fix.php /var/www/html/wp-content/mu-plugins/

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html/wp-content/mu-plugins

# Healthcheck using WP-CLI
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD wp --info --allow-root || exit 1
```

**HTTPS Mu-Plugin** (`docker/wordpress/mu-plugins/https-fix.php`):
```php
<?php
/**
 * Plugin Name: BBWS HTTPS Fix
 * Description: Force HTTPS detection when behind ALB/CloudFront proxy
 * Version: 1.0
 * Author: BBWS DevOps
 */

// Detect HTTPS from X-Forwarded-Proto header (ALB/CloudFront)
if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
    $_SERVER['HTTPS'] = 'on';
}

// CloudFront-specific header
if (isset($_SERVER['HTTP_CLOUDFRONT_FORWARDED_PROTO']) && $_SERVER['HTTP_CLOUDFRONT_FORWARDED_PROTO'] === 'https') {
    $_SERVER['HTTPS'] = 'on';
}
```

**ECR Repository Configuration**:
```yaml
ecr_repositories:
  dev:
    name: bbws-wordpress
    account: "536580886816"
    region: eu-west-1
    lifecycle_policy:
      keep_last: 10
      expire_days: 90

  sit:
    name: bbws-wordpress
    account: "815856636111"
    region: eu-west-1
    lifecycle_policy:
      keep_last: 10
      expire_days: 90

  prod:
    name: bbws-wordpress
    account: "093646564004"
    region: af-south-1
    lifecycle_policy:
      keep_last: 20
      expire_days: 180
```

**Image Promotion Flow**:
```
┌─────────────┐      ┌─────────────┐      ┌─────────────┐
│    DEV      │      │    SIT      │      │    PROD     │
│   Build &   │ ───► │  Promote &  │ ───► │  Promote &  │
│    Test     │      │    Test     │      │   Deploy    │
└─────────────┘      └─────────────┘      └─────────────┘
     │                    │                    │
     ▼                    ▼                    ▼
  536580886816        815856636111        093646564004
  .dkr.ecr...         .dkr.ecr...         .dkr.ecr...
```

**CLI Command**: `python .claude/utils/devops/docker_cli.py [build|push|promote|validate|cleanup] --env <dev|sit|prod> [--version <tag>]`

**Usage Examples**:
```bash
# Build and test locally
python .claude/utils/devops/docker_cli.py build --version 1.0.0

# Push to DEV ECR
python .claude/utils/devops/docker_cli.py push --env dev --version 1.0.0

# Validate image in DEV
python .claude/utils/devops/docker_cli.py validate --env dev --version 1.0.0

# Promote from DEV to SIT
python .claude/utils/devops/docker_cli.py promote --from dev --to sit --version 1.0.0

# Promote from SIT to PROD (requires approval)
python .claude/utils/devops/docker_cli.py promote --from sit --to prod --version 1.0.0

# Cleanup old images
python .claude/utils/devops/docker_cli.py cleanup --env dev --keep 10
```

**Maintenance Schedule**:
- Monthly: Rebuild with latest WordPress and security patches
- Quarterly: Review and update WP-CLI version
- On-demand: Rebuild when critical WordPress security patches released

---

## 5. Business Approval Integration

The DevOps Agent integrates with the Business Approval Requirements defined in the Customer Portal Public HLD:

| Deployment Stage | Approval Required | Automated |
|------------------|-------------------|-----------|
| DEV Deploy | None | Yes |
| SIT Promote | Dev Lead | GitHub Environment |
| PROD Promote | BO + Tech Lead | GitHub Environment |
| Hotfix PROD | BO Only | GitHub Environment |
| Rollback | Tech Lead | Semi-automated |

---

## 6. CLI Utility Structure

```
.claude/utils/devops/
├── __init__.py
├── repo_cli.py            # Repository creation and management
├── lld_parser.py          # LLD reading and parsing
├── code_gen.py            # Code generation from LLD
├── pipeline_cli.py        # GitHub Actions management
├── pipeline_test.py       # Pipeline testing and validation
├── terraform_cli.py       # Terraform operations
├── local_runner.py        # Local development utilities
├── deploy_cli.py          # Deployment orchestration
├── security_cli.py        # Security scanning
├── release_cli.py         # Release management
├── monitor_cli.py         # Deployment monitoring
├── docker_cli.py          # Docker image build and ECR management
├── config/
│   ├── environments.yaml  # Environment configurations
│   ├── templates/         # Code generation templates
│   └── workflows/         # GitHub Actions templates
├── docker/
│   └── wordpress/
│       ├── Dockerfile     # Custom WordPress image with WP-CLI
│       └── mu-plugins/
│           └── https-fix.php  # HTTPS detection mu-plugin
└── utils/
    ├── aws_helpers.py     # AWS utility functions
    ├── git_helpers.py     # Git utility functions
    └── logger.py          # Logging configuration
```

---

## 7. Safety Rules and Constraints

### 7.1 Environment Protection

```yaml
safety_rules:
  account_validation:
    - ALWAYS validate AWS account ID before any operation
    - BLOCK operations if account mismatch detected
    - Log all account validation attempts

  prod_protection:
    - NO direct deployments to PROD
    - REQUIRE promotion from SIT
    - REQUIRE dual approval (BO + Tech Lead)
    - NO terraform destroy in PROD (requires manual intervention)
    - READ-ONLY access for non-deployment operations

  sit_protection:
    - NO direct deployments to SIT
    - REQUIRE promotion from DEV
    - REQUIRE manual approval

  dev_access:
    - Automated deployments allowed
    - Terraform destroy allowed with confirmation
    - Full read/write access
```

### 7.2 Security Constraints

```yaml
security_constraints:
  secrets:
    - NEVER hardcode credentials
    - USE AWS Secrets Manager for all secrets
    - PARAMETERIZE environment-specific values
    - SCAN for secrets before commit

  permissions:
    - USE least-privilege IAM policies
    - USE OIDC for GitHub Actions authentication
    - ROTATE credentials regularly
    - AUDIT all permission changes

  encryption:
    - ENCRYPT all data at rest
    - USE TLS for all data in transit
    - ENCRYPT Terraform state files
    - ENCRYPT deployment artifacts
```

---

## 8. Integration Points

### 8.1 GitHub Integration

| Integration | Purpose |
|-------------|---------|
| GitHub Actions | CI/CD pipeline execution |
| GitHub Environments | Approval gates and secrets |
| GitHub Releases | Release management |
| GitHub Packages | Artifact storage |

### 8.2 AWS Integration

| Service | Purpose |
|---------|---------|
| ECR | Container image registry |
| S3 | Terraform state, artifacts |
| DynamoDB | Terraform state locking |
| Secrets Manager | Credentials and secrets |
| CloudWatch | Logs and metrics |
| SNS | Deployment notifications |
| IAM | Access control |

### 8.3 Other Agent Integration

| Agent | Integration Point |
|-------|-------------------|
| ECS Cluster Manager | Infrastructure provisioning |
| Tenant Manager | Tenant-specific deployments |
| Backup Manager | Pre-deployment backups |
| Monitoring Agent | Deployment health monitoring |
| Cost Manager | Deployment cost tracking |

---

## 9. Error Handling and Recovery

```yaml
error_handling:
  deployment_failure:
    - Capture error details
    - Trigger automatic rollback (if enabled)
    - Send failure notification
    - Create incident ticket
    - Preserve logs for diagnosis

  terraform_failure:
    - Capture Terraform error output
    - Check state consistency
    - Attempt state recovery
    - Notify operations team
    - Block subsequent deployments

  pipeline_failure:
    - Capture GitHub Actions logs
    - Identify failed step
    - Provide remediation guidance
    - Allow manual retry
    - Track failure patterns

  recovery_procedures:
    - Document recovery steps
    - Provide rollback commands
    - Include escalation paths
    - Define SLAs for recovery
```

---

## 10. Metrics and Reporting

### 10.1 Deployment Metrics

| Metric | Description |
|--------|-------------|
| Deployment Frequency | Deployments per day/week |
| Lead Time | Commit to production time |
| MTTR | Mean time to recovery |
| Change Failure Rate | Failed deployment percentage |
| Rollback Rate | Rollback frequency |

### 10.2 Reports Generated

| Report | Frequency | Audience |
|--------|-----------|----------|
| Deployment Summary | Per deployment | Dev Team |
| Weekly Metrics | Weekly | Tech Lead |
| Security Scan Report | Per PR/deployment | Security Team |
| Release Notes | Per release | Stakeholders |
| Compliance Report | Monthly | BO + Compliance |

---

## 11. Appendices

### Appendix A: CLI Command Reference

```bash
# Repository Management
python .claude/utils/devops/repo_cli.py create --name 2_bbws_auth_lambda --org bbws
python .claude/utils/devops/repo_cli.py configure --name 2_bbws_auth_lambda --environments
python .claude/utils/devops/repo_cli.py secrets --name 2_bbws_auth_lambda --env dev
python .claude/utils/devops/repo_cli.py branches --name 2_bbws_auth_lambda --protect main
python .claude/utils/devops/repo_cli.py setup-from-lld --lld ./LLDs/CPP_Auth_Lambda_LLD.md --org bbws

# LLD Operations
python .claude/utils/devops/lld_parser.py parse --lld ./LLDs/CPP_Auth_Lambda_LLD.md
python .claude/utils/devops/lld_parser.py validate --lld ./LLDs/CPP_Auth_Lambda_LLD.md

# Code Generation
python .claude/utils/devops/code_gen.py scaffold --lld ./LLDs/CPP_Auth_Lambda_LLD.md --output ./repos/2_bbws_auth_lambda
python .claude/utils/devops/code_gen.py lambda --lld ./LLDs/CPP_Auth_Lambda_LLD.md --output ./src
python .claude/utils/devops/code_gen.py tests --lld ./LLDs/CPP_Auth_Lambda_LLD.md --output ./tests

# Pipeline Management
python .claude/utils/devops/pipeline_cli.py create-ci --repo ./repos/2_bbws_auth_lambda
python .claude/utils/devops/pipeline_cli.py create-deploy --repo ./repos/2_bbws_auth_lambda --env dev
python .claude/utils/devops/pipeline_cli.py create-promote --repo ./repos/2_bbws_auth_lambda --env sit

# Pipeline Testing
python .claude/utils/devops/pipeline_test.py validate --workflow .github/workflows/ci.yml
python .claude/utils/devops/pipeline_test.py dry-run --workflow .github/workflows/ci.yml
python .claude/utils/devops/pipeline_test.py ci --workflow .github/workflows/ci.yml
python .claude/utils/devops/pipeline_test.py deploy --workflow .github/workflows/deploy-dev.yml --env dev
python .claude/utils/devops/pipeline_test.py integration --env dev
python .claude/utils/devops/pipeline_test.py load --config ./tests/load/config.yaml

# Terraform Operations
python .claude/utils/devops/terraform_cli.py init --env dev --path ./terraform
python .claude/utils/devops/terraform_cli.py plan --env dev --path ./terraform
python .claude/utils/devops/terraform_cli.py apply --env dev --path ./terraform

# Local Development
python .claude/utils/devops/local_runner.py setup
python .claude/utils/devops/local_runner.py test --coverage --watch
python .claude/utils/devops/local_runner.py lint --fix

# Deployment
python .claude/utils/devops/deploy_cli.py dev --service auth
python .claude/utils/devops/deploy_cli.py promote-sit --service auth
python .claude/utils/devops/deploy_cli.py promote-prod --service auth
python .claude/utils/devops/deploy_cli.py rollback --env dev --version v1.2.3

# Security
python .claude/utils/devops/security_cli.py dependencies --fail-on critical
python .claude/utils/devops/security_cli.py code
python .claude/utils/devops/security_cli.py infra --path ./terraform

# Release
python .claude/utils/devops/release_cli.py bump --type minor
python .claude/utils/devops/release_cli.py create --version v1.3.0
python .claude/utils/devops/release_cli.py changelog

# Monitoring
python .claude/utils/devops/monitor_cli.py watch --env dev --service auth
python .claude/utils/devops/monitor_cli.py health-check --env dev
python .claude/utils/devops/monitor_cli.py metrics --env dev --duration 24h
```

### Appendix B: Environment Variables

```bash
# AWS Configuration
AWS_REGION=af-south-1
AWS_ACCOUNT_ID_DEV=536580886816
AWS_ACCOUNT_ID_SIT=815856636111
AWS_ACCOUNT_ID_PROD=093646564004

# Terraform
TF_STATE_BUCKET=bbws-terraform-state-${ENV}
TF_LOCK_TABLE=bbws-terraform-locks-${ENV}

# GitHub
GITHUB_TOKEN=<from GitHub Actions>
GITHUB_REPOSITORY=<org/repo>

# Notifications
SNS_TOPIC_ARN=arn:aws:sns:af-south-1:${ACCOUNT_ID}:bbws-deployments
```

### Appendix C: Conventional Commit Format

```
<type>(<scope>): <subject>

[optional body]

[optional footer]
```

| Type | Description |
|------|-------------|
| feat | New feature |
| fix | Bug fix |
| docs | Documentation |
| style | Formatting |
| refactor | Code restructuring |
| test | Adding tests |
| chore | Maintenance |

---

## Related Documents

- [BBWS Customer Portal Public HLD](../../BBWS_Customer_Portal_Public_HLD.md)
- [ECS Cluster Manager Agent Spec](./agent_spec.md)
- [AWS Management Agents Spec](./aws_management_agents_spec.md)
- [Tenant Manager Agent Spec](./tenant_manager_agent_spec.md)

---

**End of Document**
