# Worker 4-1: Validation Workflows - Output

**Worker ID**: worker-4-1-validation-workflows
**Stage**: Stage 4 - CI/CD Pipeline Development
**Status**: COMPLETE
**Date**: 2025-12-25
**Output Lines**: 450+

---

## Overview

This document contains four GitHub Actions validation workflows for the BBWS CI/CD pipeline:

**DynamoDB Repository:**
1. validate-schemas.yml - Validates JSON schemas for DynamoDB tables
2. validate-terraform.yml - Validates Terraform configuration files

**S3 Repository:**
3. validate-templates.yml - Validates HTML email templates
4. validate-terraform.yml - Validates Terraform configuration files

All workflows run on pull requests and pushes to main, use Python 3.9+, and integrate with the validation scripts from Stage 3 Worker 3-6.

---

## 1. DynamoDB Repository: validate-schemas.yml

```yaml
name: Validate DynamoDB Schemas

on:
  pull_request:
    branches:
      - main
    paths:
      - 'schemas/**'
      - '.github/workflows/validate-schemas.yml'
  push:
    branches:
      - main
    paths:
      - 'schemas/**'

permissions:
  contents: read
  pull-requests: write

jobs:
  validate-schemas:
    name: Validate DynamoDB JSON Schemas
    runs-on: ubuntu-latest
    timeout-minutes: 10
    strategy:
      fail-fast: false

    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Set up Python 3.9
        uses: actions/setup-python@v4
        with:
          python-version: '3.9'
          cache: 'pip'

      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements.txt

      - name: Run DynamoDB schema validation
        id: validate
        run: |
          python scripts/validate_dynamodb_schemas.py \
            --schemas-dir ./schemas \
            --output validation-report.json \
            --verbose
        continue-on-error: true

      - name: Generate validation summary
        if: always()
        id: summary
        run: |
          if [ -f validation-report.json ]; then
            python - << 'EOF'
          import json
          with open('validation-report.json', 'r') as f:
            report = json.load(f)
          summary = report.get('summary', {})
          print(f"VALIDATION_RESULT<<EOF")
          print(f"Total Files: {summary.get('total_files', 0)}")
          print(f"Passed: {summary.get('passed_files', 0)}")
          print(f"Failed: {summary.get('failed_files', 0)}")
          print(f"Errors: {summary.get('error_count', 0)}")
          print(f"Warnings: {summary.get('warning_count', 0)}")
          print(f"EOF")
          EOF
          fi
        env:
          VALIDATION_RESULT: ${{ steps.summary.outputs.VALIDATION_RESULT }}

      - name: Post validation results as PR comment
        if: github.event_name == 'pull_request' && always()
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            let comment = '## DynamoDB Schema Validation Results\n\n';

            if (fs.existsSync('validation-report.json')) {
              const report = JSON.parse(fs.readFileSync('validation-report.json', 'utf8'));
              const summary = report.summary || {};

              comment += `### Summary\n`;
              comment += `- **Total Files**: ${summary.total_files || 0}\n`;
              comment += `- **Passed**: ${summary.passed_files || 0}\n`;
              comment += `- **Failed**: ${summary.failed_files || 0}\n`;
              comment += `- **Errors**: ${summary.error_count || 0}\n`;
              comment += `- **Warnings**: ${summary.warning_count || 0}\n\n`;

              if (summary.error_count > 0) {
                comment += `### Errors\n`;
                report.errors?.forEach(error => {
                  comment += `- **${error.file}**: ${error.message}\n`;
                  if (error.field) {
                    comment += `  - Field: ${error.field}\n`;
                  }
                });
              }

              if (summary.warning_count > 0) {
                comment += `### Warnings\n`;
                report.warnings?.forEach(warning => {
                  comment += `- **${warning.file}**: ${warning.message}\n`;
                });
              }

              if (summary.error_count === 0) {
                comment += `\n✅ All validations passed!`;
              } else {
                comment += `\n❌ Validation failed with ${summary.error_count} error(s)`;
              }
            } else {
              comment += '⚠️ Validation report not found\n';
            }

            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: comment
            });

      - name: Upload validation report
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: dynamodb-validation-report
          path: validation-report.json
          retention-days: 30

      - name: Fail workflow if validation failed
        if: steps.validate.outcome == 'failure'
        run: |
          echo "DynamoDB schema validation failed!"
          exit 1
```

---

## 2. DynamoDB Repository: validate-terraform.yml

```yaml
name: Validate Terraform Configuration

on:
  pull_request:
    branches:
      - main
    paths:
      - 'terraform/**'
      - '.github/workflows/validate-terraform.yml'
  push:
    branches:
      - main
    paths:
      - 'terraform/**'

permissions:
  contents: read
  pull-requests: write

jobs:
  validate-terraform:
    name: Validate Terraform Config
    runs-on: ubuntu-latest
    timeout-minutes: 15
    strategy:
      matrix:
        environment:
          - dev
          - sit
          - prod
      fail-fast: false

    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Set up Python 3.9
        uses: actions/setup-python@v4
        with:
          python-version: '3.9'
          cache: 'pip'

      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements.txt

      - name: Validate Terraform for ${{ matrix.environment }}
        id: validate
        run: |
          python scripts/validate_terraform_config.py \
            --config-dir ./terraform \
            --environment ${{ matrix.environment }} \
            --output terraform-validation-${{ matrix.environment }}.json \
            --verbose
        continue-on-error: true

      - name: Generate validation summary
        if: always()
        id: summary
        run: |
          if [ -f "terraform-validation-${{ matrix.environment }}.json" ]; then
            python - << 'EOF'
          import json
          import sys
          with open('terraform-validation-${{ matrix.environment }}.json', 'r') as f:
            report = json.load(f)
          summary = report.get('summary', {})
          print(f"Environment: ${{ matrix.environment }}")
          print(f"Total Files: {summary.get('total_files', 0)}")
          print(f"Passed: {summary.get('passed_files', 0)}")
          print(f"Failed: {summary.get('failed_files', 0)}")
          print(f"Errors: {summary.get('error_count', 0)}")
          print(f"Warnings: {summary.get('warning_count', 0)}")
          EOF
          fi

      - name: Post validation results as PR comment
        if: github.event_name == 'pull_request' && always()
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const fileName = 'terraform-validation-${{ matrix.environment }}.json';
            let comment = `## Terraform Validation Results - ${{ matrix.environment }}\n\n`;

            if (fs.existsSync(fileName)) {
              const report = JSON.parse(fs.readFileSync(fileName, 'utf8'));
              const summary = report.summary || {};

              comment += `### Summary\n`;
              comment += `- **Total Files**: ${summary.total_files || 0}\n`;
              comment += `- **Passed**: ${summary.passed_files || 0}\n`;
              comment += `- **Failed**: ${summary.failed_files || 0}\n`;
              comment += `- **Errors**: ${summary.error_count || 0}\n`;
              comment += `- **Warnings**: ${summary.warning_count || 0}\n\n`;

              if (summary.error_count > 0) {
                comment += `### Critical Issues\n`;
                report.errors?.forEach(error => {
                  comment += `- **${error.file}**: ${error.message}\n`;
                  if (error.variable) {
                    comment += `  - Variable: ${error.variable}\n`;
                  }
                });
              }

              if (summary.warning_count > 0 && summary.error_count === 0) {
                comment += `### Warnings\n`;
                report.warnings?.forEach(warning => {
                  comment += `- **${warning.file}**: ${warning.message}\n`;
                });
              }

              if (summary.error_count === 0) {
                comment += `\n✅ ${{ matrix.environment }} validation passed!`;
              } else {
                comment += `\n❌ ${{ matrix.environment }} validation failed`;
              }
            } else {
              comment += '⚠️ Validation report not found\n';
            }

            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: comment
            });

      - name: Upload validation report
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: terraform-validation-${{ matrix.environment }}
          path: terraform-validation-${{ matrix.environment }}.json
          retention-days: 30

      - name: Fail workflow if validation failed
        if: steps.validate.outcome == 'failure'
        run: |
          echo "Terraform validation failed for ${{ matrix.environment }}"
          exit 1
```

---

## 3. S3 Repository: validate-templates.yml

```yaml
name: Validate HTML Email Templates

on:
  pull_request:
    branches:
      - main
    paths:
      - 'templates/**'
      - '.github/workflows/validate-templates.yml'
  push:
    branches:
      - main
    paths:
      - 'templates/**'

permissions:
  contents: read
  pull-requests: write

jobs:
  validate-templates:
    name: Validate HTML Email Templates
    runs-on: ubuntu-latest
    timeout-minutes: 10

    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Set up Python 3.9
        uses: actions/setup-python@v4
        with:
          python-version: '3.9'
          cache: 'pip'

      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements.txt

      - name: Run HTML template validation
        id: validate
        run: |
          python scripts/validate_html_templates.py \
            --templates-dir ./templates \
            --output template-validation-report.json \
            --verbose
        continue-on-error: true

      - name: Generate validation summary
        if: always()
        id: summary
        run: |
          if [ -f template-validation-report.json ]; then
            python - << 'EOF'
          import json
          with open('template-validation-report.json', 'r') as f:
            report = json.load(f)
          summary = report.get('summary', {})
          print(f"TEMPLATE_VALIDATION<<EOF")
          print(f"Total Templates: {summary.get('total_files', 0)}")
          print(f"Passed: {summary.get('passed_files', 0)}")
          print(f"Failed: {summary.get('failed_files', 0)}")
          print(f"Errors: {summary.get('error_count', 0)}")
          print(f"Warnings: {summary.get('warning_count', 0)}")
          print(f"EOF")
          EOF
          fi

      - name: Post validation results as PR comment
        if: github.event_name == 'pull_request' && always()
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            let comment = '## HTML Email Template Validation Results\n\n';

            if (fs.existsSync('template-validation-report.json')) {
              const report = JSON.parse(fs.readFileSync('template-validation-report.json', 'utf8'));
              const summary = report.summary || {};

              comment += `### Summary\n`;
              comment += `- **Total Templates**: ${summary.total_files || 0}\n`;
              comment += `- **Passed**: ${summary.passed_files || 0}\n`;
              comment += `- **Failed**: ${summary.failed_files || 0}\n`;
              comment += `- **Errors**: ${summary.error_count || 0}\n`;
              comment += `- **Warnings**: ${summary.warning_count || 0}\n\n`;

              if (summary.error_count > 0) {
                comment += `### Critical Issues\n`;
                report.errors?.forEach(error => {
                  comment += `- **${error.file}**: ${error.message}\n`;
                  if (error.line) {
                    comment += `  - Line: ${error.line}\n`;
                  }
                });
              }

              if (summary.warning_count > 0) {
                comment += `### Warnings\n`;
                report.warnings?.forEach(warning => {
                  comment += `- **${warning.file}**: ${warning.message}\n`;
                });
              }

              if (summary.error_count === 0) {
                comment += `\n✅ All templates are valid!`;
              } else {
                comment += `\n❌ Template validation failed with ${summary.error_count} error(s)`;
              }
            } else {
              comment += '⚠️ Validation report not found\n';
            }

            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: comment
            });

      - name: Upload validation report
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: template-validation-report
          path: template-validation-report.json
          retention-days: 30

      - name: Fail workflow if validation failed
        if: steps.validate.outcome == 'failure'
        run: |
          echo "HTML template validation failed!"
          exit 1
```

---

## 4. S3 Repository: validate-terraform.yml

```yaml
name: Validate Terraform Configuration

on:
  pull_request:
    branches:
      - main
    paths:
      - 'terraform/**'
      - '.github/workflows/validate-terraform.yml'
  push:
    branches:
      - main
    paths:
      - 'terraform/**'

permissions:
  contents: read
  pull-requests: write

jobs:
  validate-terraform:
    name: Validate Terraform Config
    runs-on: ubuntu-latest
    timeout-minutes: 15
    strategy:
      matrix:
        environment:
          - dev
          - sit
          - prod
      fail-fast: false

    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Set up Python 3.9
        uses: actions/setup-python@v4
        with:
          python-version: '3.9'
          cache: 'pip'

      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements.txt

      - name: Validate Terraform for ${{ matrix.environment }}
        id: validate
        run: |
          python scripts/validate_terraform_config.py \
            --config-dir ./terraform \
            --environment ${{ matrix.environment }} \
            --output terraform-validation-${{ matrix.environment }}.json \
            --verbose
        continue-on-error: true

      - name: Generate validation summary
        if: always()
        id: summary
        run: |
          if [ -f "terraform-validation-${{ matrix.environment }}.json" ]; then
            python - << 'EOF'
          import json
          import sys
          with open('terraform-validation-${{ matrix.environment }}.json', 'r') as f:
            report = json.load(f)
          summary = report.get('summary', {})
          print(f"Environment: ${{ matrix.environment }}")
          print(f"Total Files: {summary.get('total_files', 0)}")
          print(f"Passed: {summary.get('passed_files', 0)}")
          print(f"Failed: {summary.get('failed_files', 0)}")
          print(f"Errors: {summary.get('error_count', 0)}")
          print(f"Warnings: {summary.get('warning_count', 0)}")
          EOF
          fi

      - name: Post validation results as PR comment
        if: github.event_name == 'pull_request' && always()
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const fileName = 'terraform-validation-${{ matrix.environment }}.json';
            let comment = `## Terraform Validation Results - ${{ matrix.environment }}\n\n`;

            if (fs.existsSync(fileName)) {
              const report = JSON.parse(fs.readFileSync(fileName, 'utf8'));
              const summary = report.summary || {};

              comment += `### Summary\n`;
              comment += `- **Total Files**: ${summary.total_files || 0}\n`;
              comment += `- **Passed**: ${summary.passed_files || 0}\n`;
              comment += `- **Failed**: ${summary.failed_files || 0}\n`;
              comment += `- **Errors**: ${summary.error_count || 0}\n`;
              comment += `- **Warnings**: ${summary.warning_count || 0}\n\n`;

              if (summary.error_count > 0) {
                comment += `### Critical Issues\n`;
                report.errors?.forEach(error => {
                  comment += `- **${error.file}**: ${error.message}\n`;
                  if (error.variable) {
                    comment += `  - Variable: ${error.variable}\n`;
                  }
                });
              }

              if (summary.warning_count > 0 && summary.error_count === 0) {
                comment += `### Warnings\n`;
                report.warnings?.forEach(warning => {
                  comment += `- **${warning.file}**: ${warning.message}\n`;
                });
              }

              if (summary.error_count === 0) {
                comment += `\n✅ ${{ matrix.environment }} validation passed!`;
              } else {
                comment += `\n❌ ${{ matrix.environment }} validation failed`;
              }
            } else {
              comment += '⚠️ Validation report not found\n';
            }

            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: comment
            });

      - name: Upload validation report
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: terraform-validation-${{ matrix.environment }}
          path: terraform-validation-${{ matrix.environment }}.json
          retention-days: 30

      - name: Fail workflow if validation failed
        if: steps.validate.outcome == 'failure'
        run: |
          echo "Terraform validation failed for ${{ matrix.environment }}"
          exit 1
```

---

## Integration Notes

### Workflow Features

All four workflows include:

1. **Triggers**: Run on pull_request and push to main
2. **Python Environment**: Uses Python 3.9+ with pip caching
3. **Validation Scripts**: Calls corresponding validation scripts from Stage 3
4. **PR Comments**: Posts formatted validation results as GitHub PR comments
5. **Artifact Upload**: Stores validation reports (JSON) for 30 days
6. **Proper Exit Codes**: Fails workflow if validation fails (exit code 1)
7. **Error Handling**: Uses `continue-on-error: true` to generate reports even on failure
8. **Matrix Strategy**: Terraform workflows validate across all three environments (dev, sit, prod)

### Repository Structure Required

Each repository should have:

```
repository/
├── .github/
│   └── workflows/
│       ├── validate-schemas.yml          (DynamoDB only)
│       ├── validate-templates.yml        (S3 only)
│       └── validate-terraform.yml        (Both repos)
├── scripts/
│   ├── validate_dynamodb_schemas.py      (DynamoDB only)
│   ├── validate_html_templates.py        (S3 only)
│   └── validate_terraform_config.py      (Both repos)
├── schemas/                              (DynamoDB only)
├── templates/                            (S3 only)
├── terraform/                            (Both repos)
└── requirements.txt
```

### Validation Script Locations

Scripts should be placed in `scripts/` directory and available in both repositories for their respective validations.

---

## Quality Checklist

- [x] All 4 workflows created (2 per repository)
- [x] Valid YAML syntax
- [x] Proper triggers (pull_request, push to main)
- [x] Uses validation scripts from Stage 3
- [x] PR comment integration (actions/github-script@v7)
- [x] Proper error handling (continue-on-error, exit codes)
- [x] Artifact upload (validation reports)
- [x] Matrix strategy for multi-environment Terraform validation
- [x] Python 3.9+ environment
- [x] Timeout protection (10-15 minutes)
- [x] Permissions properly configured
- [x] Cache strategy for pip dependencies

---

## Summary

These four GitHub Actions workflows provide automated validation for both the DynamoDB and S3 repositories in the BBWS CI/CD pipeline:

1. **validate-schemas.yml** (DynamoDB) - Validates JSON schemas conform to standards
2. **validate-templates.yml** (S3) - Validates HTML email templates for correctness
3. **validate-terraform.yml** (Both repos) - Validates Terraform config across dev/sit/prod

All workflows integrate seamlessly with the Python validation scripts from Stage 3 Worker 3-6 and provide clear feedback via PR comments and artifact storage.

---

**End of Worker 4-1 Output**
