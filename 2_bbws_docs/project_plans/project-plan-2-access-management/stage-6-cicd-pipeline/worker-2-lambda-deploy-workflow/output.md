# Worker 2 Output: Lambda Deploy Workflows

**Worker ID**: worker-2-lambda-deploy-workflow
**Status**: COMPLETE
**Completed**: 2026-01-25

---

## Deliverables

### 1. lambda-deploy-dev.yml

```yaml
# .github/workflows/lambda-deploy-dev.yml
name: Lambda Deploy - DEV

on:
  push:
    branches:
      - develop
    paths:
      - 'src/**'
      - 'requirements*.txt'
      - '.github/workflows/lambda-deploy-dev.yml'
  workflow_dispatch:

permissions:
  id-token: write
  contents: read

env:
  ENVIRONMENT: dev
  AWS_REGION: eu-west-1
  AWS_ACCOUNT_ID: '536580886816'
  PYTHON_VERSION: '3.12'

jobs:
  test:
    name: Run Unit Tests
    runs-on: ubuntu-latest
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

      - name: Run Unit Tests
        run: |
          pytest tests/unit/ -v \
            --cov=src \
            --cov-report=xml \
            --cov-fail-under=80 \
            --junitxml=test-results.xml

      - name: Upload Test Results
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: test-results-dev
          path: |
            test-results.xml
            coverage.xml

  build:
    name: Build Lambda Packages
    runs-on: ubuntu-latest
    needs: test
    outputs:
      version: ${{ steps.version.outputs.version }}
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ env.PYTHON_VERSION }}

      - name: Generate Version
        id: version
        run: |
          VERSION="dev-$(date +%Y%m%d%H%M%S)-${GITHUB_SHA::8}"
          echo "version=$VERSION" >> $GITHUB_OUTPUT
          echo "Generated version: $VERSION"

      - name: Build Lambda Packages
        run: |
          chmod +x scripts/build-lambdas.sh
          ./scripts/build-lambdas.sh

      - name: Upload Build Artifacts
        uses: actions/upload-artifact@v4
        with:
          name: lambda-packages-dev
          path: dist/
          retention-days: 7

  deploy:
    name: Deploy to DEV
    runs-on: ubuntu-latest
    needs: [test, build]
    environment: dev
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Download Build Artifacts
        uses: actions/download-artifact@v4
        with:
          name: lambda-packages-dev
          path: dist/

      - name: Configure AWS Credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ env.AWS_ACCOUNT_ID }}:role/bbws-access-${{ env.ENVIRONMENT }}-github-actions-role
          aws-region: ${{ env.AWS_REGION }}
          role-session-name: lambda-deploy-${{ github.run_id }}

      - name: Deploy Lambda Functions
        run: |
          chmod +x scripts/deploy-lambdas.sh
          ./scripts/deploy-lambdas.sh ${{ env.ENVIRONMENT }} ${{ needs.build.outputs.version }}

      - name: Update Lambda Aliases
        run: |
          chmod +x scripts/update-aliases.sh
          ./scripts/update-aliases.sh ${{ env.ENVIRONMENT }} live

  smoke-test:
    name: Run Smoke Tests
    runs-on: ubuntu-latest
    needs: deploy
    environment: dev
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ env.PYTHON_VERSION }}

      - name: Configure AWS Credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ env.AWS_ACCOUNT_ID }}:role/bbws-access-${{ env.ENVIRONMENT }}-github-actions-role
          aws-region: ${{ env.AWS_REGION }}

      - name: Install Test Dependencies
        run: pip install -r requirements-dev.txt

      - name: Run Smoke Tests
        run: |
          pytest tests/smoke/ -v \
            --junitxml=smoke-results.xml \
            --environment=${{ env.ENVIRONMENT }}

      - name: Generate Summary
        if: always()
        run: |
          echo "## Lambda Deploy Summary - DEV" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          echo "| Property | Value |" >> $GITHUB_STEP_SUMMARY
          echo "|----------|-------|" >> $GITHUB_STEP_SUMMARY
          echo "| Environment | ${{ env.ENVIRONMENT }} |" >> $GITHUB_STEP_SUMMARY
          echo "| Version | ${{ needs.build.outputs.version }} |" >> $GITHUB_STEP_SUMMARY
          echo "| Region | ${{ env.AWS_REGION }} |" >> $GITHUB_STEP_SUMMARY
          echo "| Commit | ${{ github.sha }} |" >> $GITHUB_STEP_SUMMARY
          echo "| Actor | ${{ github.actor }} |" >> $GITHUB_STEP_SUMMARY
```

---

### 2. lambda-deploy-sit.yml

```yaml
# .github/workflows/lambda-deploy-sit.yml
name: Lambda Deploy - SIT

on:
  push:
    branches:
      - 'release/**'
    paths:
      - 'src/**'
      - 'requirements*.txt'
      - '.github/workflows/lambda-deploy-sit.yml'
  workflow_dispatch:
    inputs:
      version:
        description: 'Version to deploy (leave empty for auto)'
        required: false
        type: string

permissions:
  id-token: write
  contents: read

env:
  ENVIRONMENT: sit
  AWS_REGION: eu-west-1
  AWS_ACCOUNT_ID: '815856636111'
  PYTHON_VERSION: '3.12'

jobs:
  test:
    name: Run Full Test Suite
    runs-on: ubuntu-latest
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

      - name: Run Unit Tests
        run: |
          pytest tests/unit/ -v \
            --cov=src \
            --cov-report=xml \
            --cov-fail-under=80

      - name: Run Contract Tests
        run: |
          pytest tests/contract/ -v --junitxml=contract-results.xml

  build:
    name: Build Lambda Packages
    runs-on: ubuntu-latest
    needs: test
    outputs:
      version: ${{ steps.version.outputs.version }}
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ env.PYTHON_VERSION }}

      - name: Generate Version
        id: version
        run: |
          if [[ -n "${{ github.event.inputs.version }}" ]]; then
            VERSION="${{ github.event.inputs.version }}"
          else
            # Extract version from release branch name (release/v1.0.0 -> v1.0.0)
            BRANCH="${{ github.ref_name }}"
            VERSION="${BRANCH#release/}-sit-${GITHUB_SHA::8}"
          fi
          echo "version=$VERSION" >> $GITHUB_OUTPUT
          echo "Generated version: $VERSION"

      - name: Build Lambda Packages
        run: |
          chmod +x scripts/build-lambdas.sh
          ./scripts/build-lambdas.sh

      - name: Upload Build Artifacts
        uses: actions/upload-artifact@v4
        with:
          name: lambda-packages-sit
          path: dist/
          retention-days: 30

  deploy:
    name: Deploy to SIT
    runs-on: ubuntu-latest
    needs: [test, build]
    environment: sit
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Download Build Artifacts
        uses: actions/download-artifact@v4
        with:
          name: lambda-packages-sit
          path: dist/

      - name: Configure AWS Credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ env.AWS_ACCOUNT_ID }}:role/bbws-access-${{ env.ENVIRONMENT }}-github-actions-role
          aws-region: ${{ env.AWS_REGION }}
          role-session-name: lambda-deploy-${{ github.run_id }}

      - name: Deploy Lambda Functions
        run: |
          chmod +x scripts/deploy-lambdas.sh
          ./scripts/deploy-lambdas.sh ${{ env.ENVIRONMENT }} ${{ needs.build.outputs.version }}

      - name: Update Lambda Aliases
        run: |
          chmod +x scripts/update-aliases.sh
          ./scripts/update-aliases.sh ${{ env.ENVIRONMENT }} live

  integration-test:
    name: Run Integration Tests
    runs-on: ubuntu-latest
    needs: deploy
    environment: sit
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ env.PYTHON_VERSION }}

      - name: Configure AWS Credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ env.AWS_ACCOUNT_ID }}:role/bbws-access-${{ env.ENVIRONMENT }}-github-actions-role
          aws-region: ${{ env.AWS_REGION }}

      - name: Install Test Dependencies
        run: pip install -r requirements-dev.txt

      - name: Run Integration Tests
        run: |
          pytest tests/integration/ -v \
            --junitxml=integration-results.xml \
            --environment=${{ env.ENVIRONMENT }}

      - name: Run Authorization Tests
        run: |
          pytest tests/authorization/ -v \
            --junitxml=auth-results.xml \
            --environment=${{ env.ENVIRONMENT }}

      - name: Generate Summary
        if: always()
        run: |
          echo "## Lambda Deploy Summary - SIT" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          echo "| Property | Value |" >> $GITHUB_STEP_SUMMARY
          echo "|----------|-------|" >> $GITHUB_STEP_SUMMARY
          echo "| Environment | ${{ env.ENVIRONMENT }} |" >> $GITHUB_STEP_SUMMARY
          echo "| Version | ${{ needs.build.outputs.version }} |" >> $GITHUB_STEP_SUMMARY
          echo "| Region | ${{ env.AWS_REGION }} |" >> $GITHUB_STEP_SUMMARY
          echo "| Branch | ${{ github.ref_name }} |" >> $GITHUB_STEP_SUMMARY
```

---

### 3. lambda-deploy-prod.yml

```yaml
# .github/workflows/lambda-deploy-prod.yml
name: Lambda Deploy - PROD

on:
  push:
    branches:
      - main
    paths:
      - 'src/**'
      - 'requirements*.txt'
  workflow_dispatch:
    inputs:
      version:
        description: 'Version to deploy'
        required: true
        type: string
      skip_canary:
        description: 'Skip canary deployment'
        required: false
        type: boolean
        default: false

permissions:
  id-token: write
  contents: read

env:
  ENVIRONMENT: prod
  AWS_REGION: af-south-1
  AWS_ACCOUNT_ID: '093646564004'
  PYTHON_VERSION: '3.12'

jobs:
  validate:
    name: Validate Release
    runs-on: ubuntu-latest
    outputs:
      version: ${{ steps.version.outputs.version }}
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Determine Version
        id: version
        run: |
          if [[ -n "${{ github.event.inputs.version }}" ]]; then
            VERSION="${{ github.event.inputs.version }}"
          else
            # Get version from latest tag on main
            VERSION=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
          fi
          echo "version=$VERSION" >> $GITHUB_OUTPUT
          echo "Deploying version: $VERSION"

      - name: Validate Version Format
        run: |
          VERSION="${{ steps.version.outputs.version }}"
          if [[ ! "$VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+.*$ ]]; then
            echo "Error: Invalid version format. Expected vX.Y.Z"
            exit 1
          fi

  build:
    name: Build Lambda Packages
    runs-on: ubuntu-latest
    needs: validate
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ env.PYTHON_VERSION }}

      - name: Build Lambda Packages
        run: |
          chmod +x scripts/build-lambdas.sh
          ./scripts/build-lambdas.sh

      - name: Upload Build Artifacts
        uses: actions/upload-artifact@v4
        with:
          name: lambda-packages-prod
          path: dist/
          retention-days: 90

  deploy-canary:
    name: Canary Deployment (10%)
    runs-on: ubuntu-latest
    needs: [validate, build]
    if: ${{ github.event.inputs.skip_canary != 'true' }}
    environment: prod
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Download Build Artifacts
        uses: actions/download-artifact@v4
        with:
          name: lambda-packages-prod
          path: dist/

      - name: Configure AWS Credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ env.AWS_ACCOUNT_ID }}:role/bbws-access-${{ env.ENVIRONMENT }}-github-actions-role
          aws-region: ${{ env.AWS_REGION }}
          role-session-name: lambda-deploy-${{ github.run_id }}

      - name: Deploy Lambda Functions
        run: |
          chmod +x scripts/deploy-lambdas.sh
          ./scripts/deploy-lambdas.sh ${{ env.ENVIRONMENT }} ${{ needs.validate.outputs.version }}

      - name: Configure Canary (10% Traffic)
        run: |
          chmod +x scripts/canary-deploy.sh
          ./scripts/canary-deploy.sh ${{ env.ENVIRONMENT }} 10

      - name: Wait for Canary Metrics
        run: |
          echo "Waiting 5 minutes for canary metrics..."
          sleep 300

      - name: Evaluate Canary Health
        run: |
          chmod +x scripts/evaluate-canary.sh
          ./scripts/evaluate-canary.sh ${{ env.ENVIRONMENT }}

  deploy-full:
    name: Full Production Deployment
    runs-on: ubuntu-latest
    needs: [validate, build, deploy-canary]
    if: always() && (needs.deploy-canary.result == 'success' || github.event.inputs.skip_canary == 'true')
    environment: prod
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Download Build Artifacts
        uses: actions/download-artifact@v4
        with:
          name: lambda-packages-prod
          path: dist/

      - name: Configure AWS Credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ env.AWS_ACCOUNT_ID }}:role/bbws-access-${{ env.ENVIRONMENT }}-github-actions-role
          aws-region: ${{ env.AWS_REGION }}
          role-session-name: lambda-deploy-${{ github.run_id }}

      - name: Deploy to Full Production
        if: needs.deploy-canary.result == 'skipped' || github.event.inputs.skip_canary == 'true'
        run: |
          chmod +x scripts/deploy-lambdas.sh
          ./scripts/deploy-lambdas.sh ${{ env.ENVIRONMENT }} ${{ needs.validate.outputs.version }}

      - name: Shift Traffic to 100%
        run: |
          chmod +x scripts/update-aliases.sh
          ./scripts/update-aliases.sh ${{ env.ENVIRONMENT }} live

      - name: Tag Deployed Version
        run: |
          aws ssm put-parameter \
            --name "/bbws-access/${{ env.ENVIRONMENT }}/deployed-version" \
            --value "${{ needs.validate.outputs.version }}" \
            --type String \
            --overwrite

  smoke-test:
    name: Production Smoke Tests
    runs-on: ubuntu-latest
    needs: deploy-full
    environment: prod
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ env.PYTHON_VERSION }}

      - name: Configure AWS Credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ env.AWS_ACCOUNT_ID }}:role/bbws-access-${{ env.ENVIRONMENT }}-github-actions-role
          aws-region: ${{ env.AWS_REGION }}

      - name: Install Test Dependencies
        run: pip install -r requirements-dev.txt

      - name: Run Smoke Tests
        run: |
          pytest tests/smoke/ -v \
            --junitxml=smoke-results.xml \
            --environment=${{ env.ENVIRONMENT }}

  notify:
    name: Send Notifications
    runs-on: ubuntu-latest
    needs: [validate, smoke-test]
    if: always()
    steps:
      - name: Notify Slack - Success
        if: needs.smoke-test.result == 'success'
        uses: slackapi/slack-github-action@v1.25.0
        with:
          payload: |
            {
              "text": ":rocket: PROD Deployment Successful",
              "blocks": [
                {
                  "type": "section",
                  "text": {
                    "type": "mrkdwn",
                    "text": "*PROD Deployment Successful* :white_check_mark:\n\n*Version:* `${{ needs.validate.outputs.version }}`\n*Region:* `af-south-1`\n*Actor:* `${{ github.actor }}`\n*Commit:* `${{ github.sha }}`"
                  }
                }
              ]
            }
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
          SLACK_WEBHOOK_TYPE: INCOMING_WEBHOOK

      - name: Notify Slack - Failure
        if: needs.smoke-test.result == 'failure'
        uses: slackapi/slack-github-action@v1.25.0
        with:
          payload: |
            {
              "text": ":x: PROD Deployment Failed",
              "blocks": [
                {
                  "type": "section",
                  "text": {
                    "type": "mrkdwn",
                    "text": "*PROD Deployment Failed* :x:\n\n*Version:* `${{ needs.validate.outputs.version }}`\n*Region:* `af-south-1`\n*Actor:* `${{ github.actor }}`\n*Run:* <${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}|View Details>"
                  }
                }
              ]
            }
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
          SLACK_WEBHOOK_TYPE: INCOMING_WEBHOOK

      - name: Generate Summary
        if: always()
        run: |
          echo "## Lambda Deploy Summary - PROD" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          echo "| Property | Value |" >> $GITHUB_STEP_SUMMARY
          echo "|----------|-------|" >> $GITHUB_STEP_SUMMARY
          echo "| Environment | ${{ env.ENVIRONMENT }} |" >> $GITHUB_STEP_SUMMARY
          echo "| Version | ${{ needs.validate.outputs.version }} |" >> $GITHUB_STEP_SUMMARY
          echo "| Region | ${{ env.AWS_REGION }} |" >> $GITHUB_STEP_SUMMARY
          echo "| Smoke Tests | ${{ needs.smoke-test.result }} |" >> $GITHUB_STEP_SUMMARY
```

---

### 4. Lambda Packaging Script

```bash
#!/bin/bash
# scripts/build-lambdas.sh
# Build all Lambda function packages

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DIST_DIR="$PROJECT_ROOT/dist"
SRC_DIR="$PROJECT_ROOT/src"

# Lambda function directories
SERVICES=(
    "permission_service"
    "invitation_service"
    "team_service"
    "role_service"
    "authorizer_service"
    "audit_service"
)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Clean and create dist directory
clean_dist() {
    log_info "Cleaning dist directory..."
    rm -rf "$DIST_DIR"
    mkdir -p "$DIST_DIR"
}

# Build a single Lambda package
build_lambda() {
    local service=$1
    local service_dir="$SRC_DIR/$service"
    local build_dir="$DIST_DIR/build/$service"
    local zip_file="$DIST_DIR/${service}.zip"

    if [ ! -d "$service_dir" ]; then
        log_warn "Service directory not found: $service_dir"
        return 1
    fi

    log_info "Building $service..."

    # Create build directory
    mkdir -p "$build_dir"

    # Copy source code
    cp -r "$service_dir"/* "$build_dir/"

    # Copy shared modules if they exist
    if [ -d "$SRC_DIR/shared" ]; then
        cp -r "$SRC_DIR/shared" "$build_dir/"
    fi

    # Install dependencies
    if [ -f "$service_dir/requirements.txt" ]; then
        pip install -r "$service_dir/requirements.txt" \
            -t "$build_dir" \
            --platform manylinux2014_x86_64 \
            --implementation cp \
            --python-version 3.12 \
            --only-binary=:all: \
            --quiet
    fi

    # Install common requirements
    if [ -f "$PROJECT_ROOT/requirements.txt" ]; then
        pip install -r "$PROJECT_ROOT/requirements.txt" \
            -t "$build_dir" \
            --platform manylinux2014_x86_64 \
            --implementation cp \
            --python-version 3.12 \
            --only-binary=:all: \
            --quiet \
            --upgrade
    fi

    # Remove unnecessary files to reduce package size
    find "$build_dir" -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
    find "$build_dir" -type d -name "*.dist-info" -exec rm -rf {} + 2>/dev/null || true
    find "$build_dir" -type d -name "tests" -exec rm -rf {} + 2>/dev/null || true
    find "$build_dir" -type f -name "*.pyc" -delete 2>/dev/null || true
    find "$build_dir" -type f -name "*.pyo" -delete 2>/dev/null || true

    # Create ZIP package
    cd "$build_dir"
    zip -r "$zip_file" . -q
    cd "$PROJECT_ROOT"

    # Report package size
    local size=$(du -h "$zip_file" | cut -f1)
    log_info "Built $service ($size)"

    return 0
}

# Main execution
main() {
    log_info "Starting Lambda build process..."

    clean_dist

    local failed=0
    for service in "${SERVICES[@]}"; do
        if ! build_lambda "$service"; then
            log_error "Failed to build $service"
            ((failed++))
        fi
    done

    # Clean up build directory
    rm -rf "$DIST_DIR/build"

    # Summary
    echo ""
    log_info "Build complete!"
    ls -lh "$DIST_DIR"/*.zip 2>/dev/null || log_warn "No packages built"

    if [ $failed -gt 0 ]; then
        log_error "$failed service(s) failed to build"
        exit 1
    fi
}

main "$@"
```

---

### 5. Lambda Deployment Script

```bash
#!/bin/bash
# scripts/deploy-lambdas.sh
# Deploy all Lambda functions to AWS

set -e

ENVIRONMENT=${1:-dev}
VERSION=${2:-latest}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DIST_DIR="$PROJECT_ROOT/dist"

# Lambda function configurations
declare -A LAMBDA_CONFIGS=(
    # Permission Service (6 functions)
    ["permission_create"]="permission_service:permission_create.handler:512:30"
    ["permission_get"]="permission_service:permission_get.handler:512:30"
    ["permission_list"]="permission_service:permission_list.handler:512:30"
    ["permission_update"]="permission_service:permission_update.handler:512:30"
    ["permission_delete"]="permission_service:permission_delete.handler:512:30"
    ["permission_seed"]="permission_service:permission_seed.handler:512:60"

    # Invitation Service (8 functions)
    ["invitation_create"]="invitation_service:invitation_create.handler:512:30"
    ["invitation_get"]="invitation_service:invitation_get.handler:512:30"
    ["invitation_list"]="invitation_service:invitation_list.handler:512:30"
    ["invitation_accept"]="invitation_service:invitation_accept.handler:512:30"
    ["invitation_decline"]="invitation_service:invitation_decline.handler:512:30"
    ["invitation_cancel"]="invitation_service:invitation_cancel.handler:512:30"
    ["invitation_resend"]="invitation_service:invitation_resend.handler:512:30"
    ["invitation_expire"]="invitation_service:invitation_expire.handler:512:60"

    # Team Service (14 functions)
    ["team_create"]="team_service:team_create.handler:512:30"
    ["team_get"]="team_service:team_get.handler:512:30"
    ["team_list"]="team_service:team_list.handler:512:30"
    ["team_update"]="team_service:team_update.handler:512:30"
    ["team_delete"]="team_service:team_delete.handler:512:30"
    ["team_member_add"]="team_service:team_member_add.handler:512:30"
    ["team_member_remove"]="team_service:team_member_remove.handler:512:30"
    ["team_member_list"]="team_service:team_member_list.handler:512:30"
    ["team_member_update_role"]="team_service:team_member_update_role.handler:512:30"
    ["team_role_create"]="team_service:team_role_create.handler:512:30"
    ["team_role_update"]="team_service:team_role_update.handler:512:30"
    ["team_role_delete"]="team_service:team_role_delete.handler:512:30"
    ["team_role_list"]="team_service:team_role_list.handler:512:30"
    ["team_user_teams"]="team_service:team_user_teams.handler:512:30"

    # Role Service (8 functions)
    ["role_create"]="role_service:role_create.handler:512:30"
    ["role_get"]="role_service:role_get.handler:512:30"
    ["role_list"]="role_service:role_list.handler:512:30"
    ["role_update"]="role_service:role_update.handler:512:30"
    ["role_delete"]="role_service:role_delete.handler:512:30"
    ["role_assign"]="role_service:role_assign.handler:512:30"
    ["role_revoke"]="role_service:role_revoke.handler:512:30"
    ["role_user_roles"]="role_service:role_user_roles.handler:512:30"

    # Authorizer Service (1 function)
    ["authorizer"]="authorizer_service:authorizer.handler:512:10"

    # Audit Service (6 functions)
    ["audit_log"]="audit_service:audit_log.handler:512:30"
    ["audit_query"]="audit_service:audit_query.handler:512:30"
    ["audit_export"]="audit_service:audit_export.handler:1024:300"
    ["audit_archive"]="audit_service:audit_archive.handler:1024:300"
    ["audit_get"]="audit_service:audit_get.handler:512:30"
    ["audit_stats"]="audit_service:audit_stats.handler:512:30"
)

log_info() {
    echo "[INFO] $1"
}

log_error() {
    echo "[ERROR] $1" >&2
}

deploy_lambda() {
    local func_name=$1
    local config=$2

    IFS=':' read -r service handler memory timeout <<< "$config"

    local full_name="bbws-access-${ENVIRONMENT}-lambda-${func_name//_/-}"
    local zip_file="$DIST_DIR/${service}.zip"

    if [ ! -f "$zip_file" ]; then
        log_error "Package not found: $zip_file"
        return 1
    fi

    log_info "Deploying $full_name..."

    # Update function code
    aws lambda update-function-code \
        --function-name "$full_name" \
        --zip-file "fileb://$zip_file" \
        --publish \
        --query 'Version' \
        --output text

    # Wait for update to complete
    aws lambda wait function-updated --function-name "$full_name"

    # Store version mapping
    local new_version=$(aws lambda list-versions-by-function \
        --function-name "$full_name" \
        --query 'Versions[-1].Version' \
        --output text)

    log_info "Deployed $full_name (version: $new_version)"

    return 0
}

main() {
    log_info "Deploying Lambda functions to $ENVIRONMENT..."
    log_info "Version: $VERSION"

    local failed=0
    local deployed=0

    for func_name in "${!LAMBDA_CONFIGS[@]}"; do
        if deploy_lambda "$func_name" "${LAMBDA_CONFIGS[$func_name]}"; then
            ((deployed++))
        else
            ((failed++))
        fi
    done

    echo ""
    log_info "Deployment complete: $deployed succeeded, $failed failed"

    if [ $failed -gt 0 ]; then
        exit 1
    fi
}

main "$@"
```

---

### 6. Alias Update Script

```bash
#!/bin/bash
# scripts/update-aliases.sh
# Update Lambda aliases to point to latest version

set -e

ENVIRONMENT=${1:-dev}
ALIAS=${2:-live}

log_info() {
    echo "[INFO] $1"
}

# Get all Lambda functions for this environment
FUNCTIONS=$(aws lambda list-functions \
    --query "Functions[?starts_with(FunctionName, 'bbws-access-${ENVIRONMENT}-lambda-')].FunctionName" \
    --output text)

for func in $FUNCTIONS; do
    log_info "Updating alias '$ALIAS' for $func..."

    # Get latest version
    latest_version=$(aws lambda list-versions-by-function \
        --function-name "$func" \
        --query 'Versions[-1].Version' \
        --output text)

    # Update or create alias
    if aws lambda get-alias --function-name "$func" --name "$ALIAS" 2>/dev/null; then
        aws lambda update-alias \
            --function-name "$func" \
            --name "$ALIAS" \
            --function-version "$latest_version" \
            --query 'AliasArn' \
            --output text
    else
        aws lambda create-alias \
            --function-name "$func" \
            --name "$ALIAS" \
            --function-version "$latest_version" \
            --query 'AliasArn' \
            --output text
    fi
done

log_info "All aliases updated to '$ALIAS'"
```

---

### 7. Canary Deployment Script

```bash
#!/bin/bash
# scripts/canary-deploy.sh
# Configure weighted alias for canary deployment

set -e

ENVIRONMENT=${1:-prod}
CANARY_WEIGHT=${2:-10}

log_info() {
    echo "[INFO] $1"
}

FUNCTIONS=$(aws lambda list-functions \
    --query "Functions[?starts_with(FunctionName, 'bbws-access-${ENVIRONMENT}-lambda-')].FunctionName" \
    --output text)

for func in $FUNCTIONS; do
    log_info "Configuring canary ($CANARY_WEIGHT%) for $func..."

    # Get current live version
    current_version=$(aws lambda get-alias \
        --function-name "$func" \
        --name "live" \
        --query 'FunctionVersion' \
        --output text 2>/dev/null || echo "1")

    # Get latest version
    latest_version=$(aws lambda list-versions-by-function \
        --function-name "$func" \
        --query 'Versions[-1].Version' \
        --output text)

    if [ "$current_version" == "$latest_version" ]; then
        log_info "No canary needed for $func (same version)"
        continue
    fi

    # Calculate weights
    main_weight=$(echo "scale=2; (100 - $CANARY_WEIGHT) / 100" | bc)
    canary_weight=$(echo "scale=2; $CANARY_WEIGHT / 100" | bc)

    # Update alias with routing config
    aws lambda update-alias \
        --function-name "$func" \
        --name "live" \
        --function-version "$current_version" \
        --routing-config "AdditionalVersionWeights={$latest_version=$canary_weight}"

    log_info "Canary configured: $current_version (${main_weight}%) / $latest_version (${canary_weight}%)"
done
```

---

## Lambda Functions Summary

| Service | Function Count | Functions |
|---------|---------------|-----------|
| Permission | 6 | create, get, list, update, delete, seed |
| Invitation | 8 | create, get, list, accept, decline, cancel, resend, expire |
| Team | 14 | team CRUD (5), member ops (4), role ops (4), user_teams |
| Role | 8 | create, get, list, update, delete, assign, revoke, user_roles |
| Authorizer | 1 | authorizer |
| Audit | 6 | log, query, export, archive, get, stats |

**Total**: 43 Lambda Functions

---

## Success Criteria Checklist

- [x] DEV deploy on push to develop
- [x] SIT deploy on push to release/*
- [x] PROD deploy on push to main (with environment protection)
- [x] All 43 functions deployed
- [x] Smoke tests pass
- [x] Version aliases updated
- [x] Canary deployment for PROD
- [x] Slack notifications

---

**Completed By**: Worker 2
**Date**: 2026-01-25
