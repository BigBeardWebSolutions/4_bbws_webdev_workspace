# Worker Instructions: Build & Test Workflow

**Worker ID**: worker-1-build-test-workflow
**Stage**: Stage 3 - CI/CD Pipeline Development
**Project**: project-plan-campaigns

---

## Task

Create GitHub Actions workflow for building and testing the Lambda code on pull requests.

---

## Deliverables

### .github/workflows/build-test.yml

```yaml
name: Build and Test

on:
  pull_request:
    branches:
      - main
      - develop
    paths:
      - 'src/**'
      - 'tests/**'
      - 'requirements*.txt'
      - 'pyproject.toml'
      - '.github/workflows/build-test.yml'

  push:
    branches:
      - main
    paths:
      - 'src/**'
      - 'tests/**'

env:
  PYTHON_VERSION: '3.12'

jobs:
  lint:
    name: Lint Code
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ env.PYTHON_VERSION }}

      - name: Cache pip dependencies
        uses: actions/cache@v4
        with:
          path: ~/.cache/pip
          key: ${{ runner.os }}-pip-${{ hashFiles('**/requirements-dev.txt') }}
          restore-keys: |
            ${{ runner.os }}-pip-

      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements-dev.txt

      - name: Run Black (code formatting)
        run: black --check --diff src/ tests/

      - name: Run isort (import sorting)
        run: isort --check-only --diff src/ tests/

      - name: Run Flake8 (linting)
        run: flake8 src/ tests/ --max-line-length=88 --extend-ignore=E203

  test:
    name: Run Tests
    runs-on: ubuntu-latest
    needs: lint

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ env.PYTHON_VERSION }}

      - name: Cache pip dependencies
        uses: actions/cache@v4
        with:
          path: ~/.cache/pip
          key: ${{ runner.os }}-pip-${{ hashFiles('**/requirements-dev.txt') }}
          restore-keys: |
            ${{ runner.os }}-pip-

      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements-dev.txt

      - name: Set environment variables
        run: |
          echo "CAMPAIGNS_TABLE_NAME=test-campaigns-table" >> $GITHUB_ENV
          echo "ENVIRONMENT=test" >> $GITHUB_ENV
          echo "LOG_LEVEL=DEBUG" >> $GITHUB_ENV
          echo "AWS_DEFAULT_REGION=eu-west-1" >> $GITHUB_ENV

      - name: Run unit tests with coverage
        run: |
          pytest tests/unit/ \
            --cov=src \
            --cov-report=xml \
            --cov-report=html \
            --cov-report=term-missing \
            --cov-fail-under=80 \
            -v

      - name: Upload coverage report
        uses: actions/upload-artifact@v4
        with:
          name: coverage-report
          path: htmlcov/
          retention-days: 7

      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v4
        with:
          file: ./coverage.xml
          fail_ci_if_error: false
        continue-on-error: true

  type-check:
    name: Type Check
    runs-on: ubuntu-latest
    needs: lint

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ env.PYTHON_VERSION }}

      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements-dev.txt

      - name: Run MyPy
        run: mypy src/ --ignore-missing-imports
        continue-on-error: true

  build:
    name: Build Lambda Package
    runs-on: ubuntu-latest
    needs: test

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ env.PYTHON_VERSION }}

      - name: Install dependencies for packaging
        run: |
          python -m pip install --upgrade pip
          mkdir -p package
          pip install -r requirements.txt -t package/

      - name: Copy source code
        run: |
          cp -r src/ package/

      - name: Create Lambda ZIP
        run: |
          cd package
          zip -r ../lambda.zip .
          cd ..

      - name: Upload Lambda package
        uses: actions/upload-artifact@v4
        with:
          name: lambda-package
          path: lambda.zip
          retention-days: 7

      - name: Display package size
        run: |
          echo "Lambda package size:"
          ls -lh lambda.zip
```

---

## Workflow Features

### Triggers
- Pull requests to main/develop branches
- Push to main branch
- Path filters for relevant files only

### Jobs
1. **lint** - Code formatting and style checks
2. **test** - Unit tests with coverage
3. **type-check** - MyPy type checking
4. **build** - Create Lambda ZIP package

### Coverage Requirements
- Minimum 80% code coverage
- Report uploaded as artifact
- Optional Codecov integration

### Caching
- Pip dependencies cached for faster builds

---

## Success Criteria

- [ ] Workflow file is valid YAML
- [ ] Python 3.12 is used
- [ ] All linting tools configured
- [ ] Unit tests run with coverage
- [ ] Lambda package is built
- [ ] Artifacts are uploaded

---

## Execution Steps

1. Create .github/workflows/build-test.yml
2. Configure Python 3.12 setup
3. Add linting steps (black, isort, flake8)
4. Add test step with coverage
5. Add build step for Lambda package
6. Validate workflow syntax
7. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-15
