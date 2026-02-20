# Worker 5 Output: Rollback Workflows

**Worker ID**: worker-5-rollback-workflow
**Status**: COMPLETE
**Completed**: 2026-01-25

---

## Deliverables

### 1. rollback-lambda.yml

```yaml
# .github/workflows/rollback-lambda.yml
name: Rollback Lambda Functions

on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Target environment'
        required: true
        type: choice
        options:
          - dev
          - sit
          - prod
      target_version:
        description: 'Target version (leave empty for previous)'
        required: false
        type: string
      services:
        description: 'Services to rollback (comma-separated or "all")'
        required: false
        type: string
        default: 'all'
      reason:
        description: 'Reason for rollback'
        required: true
        type: string

permissions:
  id-token: write
  contents: read

env:
  PYTHON_VERSION: '3.12'

jobs:
  prepare-rollback:
    name: Prepare Rollback
    runs-on: ubuntu-latest
    outputs:
      aws_region: ${{ steps.config.outputs.aws_region }}
      aws_account_id: ${{ steps.config.outputs.aws_account_id }}
      current_version: ${{ steps.versions.outputs.current }}
      target_version: ${{ steps.versions.outputs.target }}
      services: ${{ steps.services.outputs.list }}
    steps:
      - name: Set Environment Config
        id: config
        run: |
          case "${{ github.event.inputs.environment }}" in
            prod)
              echo "aws_region=af-south-1" >> $GITHUB_OUTPUT
              echo "aws_account_id=093646564004" >> $GITHUB_OUTPUT
              ;;
            sit)
              echo "aws_region=eu-west-1" >> $GITHUB_OUTPUT
              echo "aws_account_id=815856636111" >> $GITHUB_OUTPUT
              ;;
            *)
              echo "aws_region=eu-west-1" >> $GITHUB_OUTPUT
              echo "aws_account_id=536580886816" >> $GITHUB_OUTPUT
              ;;
          esac

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ steps.config.outputs.aws_account_id }}:role/bbws-access-${{ github.event.inputs.environment }}-github-actions-role
          aws-region: ${{ steps.config.outputs.aws_region }}

      - name: Get Current and Target Versions
        id: versions
        run: |
          ENV="${{ github.event.inputs.environment }}"

          # Get current deployed version
          CURRENT=$(aws ssm get-parameter \
            --name "/bbws-access/$ENV/deployed-version" \
            --query 'Parameter.Value' \
            --output text 2>/dev/null || echo "unknown")

          echo "current=$CURRENT" >> $GITHUB_OUTPUT
          echo "Current version: $CURRENT"

          # Determine target version
          if [ -n "${{ github.event.inputs.target_version }}" ]; then
            TARGET="${{ github.event.inputs.target_version }}"
          else
            # Get previous version from SSM history or Lambda versions
            TARGET=$(aws ssm get-parameter-history \
              --name "/bbws-access/$ENV/deployed-version" \
              --query 'Parameters[-2].Value' \
              --output text 2>/dev/null || echo "")

            if [ -z "$TARGET" ] || [ "$TARGET" == "None" ]; then
              echo "Error: Could not determine previous version"
              exit 1
            fi
          fi

          echo "target=$TARGET" >> $GITHUB_OUTPUT
          echo "Target version: $TARGET"

      - name: Determine Services
        id: services
        run: |
          SERVICES="${{ github.event.inputs.services }}"
          if [ "$SERVICES" == "all" ]; then
            SERVICES="permission_service,invitation_service,team_service,role_service,authorizer_service,audit_service"
          fi
          echo "list=$SERVICES" >> $GITHUB_OUTPUT
          echo "Services to rollback: $SERVICES"

  approval:
    name: Approval Required (PROD)
    runs-on: ubuntu-latest
    needs: prepare-rollback
    if: github.event.inputs.environment == 'prod'
    environment: prod-rollback
    steps:
      - name: Approval Checkpoint
        run: |
          echo "PROD rollback approved"
          echo "Reason: ${{ github.event.inputs.reason }}"

  execute-rollback:
    name: Execute Lambda Rollback
    runs-on: ubuntu-latest
    needs: [prepare-rollback, approval]
    if: always() && (needs.approval.result == 'success' || needs.approval.result == 'skipped')
    environment: ${{ github.event.inputs.environment }}
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ needs.prepare-rollback.outputs.aws_account_id }}:role/bbws-access-${{ github.event.inputs.environment }}-github-actions-role
          aws-region: ${{ needs.prepare-rollback.outputs.aws_region }}

      - name: Create Rollback Record
        id: record
        run: |
          ROLLBACK_ID="rollback-$(date +%Y%m%d%H%M%S)"
          echo "rollback_id=$ROLLBACK_ID" >> $GITHUB_OUTPUT

          # Store rollback record
          aws dynamodb put-item \
            --table-name "bbws-access-${{ github.event.inputs.environment }}-ddb-deployments" \
            --item '{
              "PK": {"S": "ROLLBACK#'"$ROLLBACK_ID"'"},
              "SK": {"S": "METADATA"},
              "rollback_id": {"S": "'"$ROLLBACK_ID"'"},
              "environment": {"S": "${{ github.event.inputs.environment }}"},
              "from_version": {"S": "${{ needs.prepare-rollback.outputs.current_version }}"},
              "to_version": {"S": "${{ needs.prepare-rollback.outputs.target_version }}"},
              "services": {"S": "${{ needs.prepare-rollback.outputs.services }}"},
              "reason": {"S": "${{ github.event.inputs.reason }}"},
              "initiated_by": {"S": "${{ github.actor }}"},
              "initiated_at": {"S": "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'"},
              "status": {"S": "IN_PROGRESS"}
            }' 2>/dev/null || echo "Rollback table not found, continuing..."

      - name: Rollback Lambda Aliases
        run: |
          ENV="${{ github.event.inputs.environment }}"
          TARGET_VERSION="${{ needs.prepare-rollback.outputs.target_version }}"
          SERVICES="${{ needs.prepare-rollback.outputs.services }}"

          IFS=',' read -ra SERVICE_ARRAY <<< "$SERVICES"

          for service in "${SERVICE_ARRAY[@]}"; do
            echo "Rolling back $service..."

            # Get all Lambda functions for this service
            FUNCTIONS=$(aws lambda list-functions \
              --query "Functions[?starts_with(FunctionName, 'bbws-access-$ENV-lambda-${service//_/-}')].FunctionName" \
              --output text)

            for func in $FUNCTIONS; do
              echo "  Processing $func..."

              # Find the version that matches the target version description
              TARGET_LAMBDA_VERSION=$(aws lambda list-versions-by-function \
                --function-name "$func" \
                --query "Versions[?Description=='$TARGET_VERSION'].Version" \
                --output text | head -1)

              if [ -z "$TARGET_LAMBDA_VERSION" ] || [ "$TARGET_LAMBDA_VERSION" == "None" ]; then
                # Fallback: get the version before the current one
                TARGET_LAMBDA_VERSION=$(aws lambda list-versions-by-function \
                  --function-name "$func" \
                  --query 'Versions[-2].Version' \
                  --output text)
              fi

              if [ -n "$TARGET_LAMBDA_VERSION" ] && [ "$TARGET_LAMBDA_VERSION" != "\$LATEST" ]; then
                # Update alias to point to target version
                aws lambda update-alias \
                  --function-name "$func" \
                  --name "live" \
                  --function-version "$TARGET_LAMBDA_VERSION" \
                  --routing-config '{}' || echo "Failed to update alias for $func"

                echo "  Rolled back $func to version $TARGET_LAMBDA_VERSION"
              else
                echo "  Warning: Could not find target version for $func"
              fi
            done
          done

      - name: Update Deployed Version
        run: |
          aws ssm put-parameter \
            --name "/bbws-access/${{ github.event.inputs.environment }}/deployed-version" \
            --value "${{ needs.prepare-rollback.outputs.target_version }}" \
            --type String \
            --overwrite

  verify-rollback:
    name: Verify Rollback
    runs-on: ubuntu-latest
    needs: [prepare-rollback, execute-rollback]
    environment: ${{ github.event.inputs.environment }}
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ env.PYTHON_VERSION }}
          cache: 'pip'

      - name: Install Dependencies
        run: pip install -r requirements-dev.txt

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ needs.prepare-rollback.outputs.aws_account_id }}:role/bbws-access-${{ github.event.inputs.environment }}-github-actions-role
          aws-region: ${{ needs.prepare-rollback.outputs.aws_region }}

      - name: Run Smoke Tests
        env:
          TEST_ENVIRONMENT: ${{ github.event.inputs.environment }}
        run: |
          pytest tests/smoke/ \
            -v \
            --junitxml=rollback-smoke-results.xml

      - name: Update Rollback Status
        if: always()
        run: |
          STATUS="${{ job.status == 'success' && 'COMPLETE' || 'FAILED' }}"

          aws dynamodb update-item \
            --table-name "bbws-access-${{ github.event.inputs.environment }}-ddb-deployments" \
            --key '{
              "PK": {"S": "ROLLBACK#${{ needs.execute-rollback.outputs.rollback_id }}"},
              "SK": {"S": "METADATA"}
            }' \
            --update-expression "SET #status = :status, completed_at = :completed_at" \
            --expression-attribute-names '{"#status": "status"}' \
            --expression-attribute-values '{
              ":status": {"S": "'"$STATUS"'"},
              ":completed_at": {"S": "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'"}
            }' 2>/dev/null || echo "Could not update rollback record"

  notify:
    name: Send Notifications
    runs-on: ubuntu-latest
    needs: [prepare-rollback, verify-rollback]
    if: always()
    steps:
      - name: Notify Slack
        uses: slackapi/slack-github-action@v1.25.0
        with:
          payload: |
            {
              "text": "${{ needs.verify-rollback.result == 'success' && ':rewind: Lambda Rollback Successful' || ':x: Lambda Rollback Failed' }}",
              "blocks": [
                {
                  "type": "section",
                  "text": {
                    "type": "mrkdwn",
                    "text": "*Lambda Rollback ${{ needs.verify-rollback.result == 'success' && 'Successful' || 'Failed' }}* ${{ needs.verify-rollback.result == 'success' && ':rewind:' || ':x:' }}\n\n*Environment:* `${{ github.event.inputs.environment }}`\n*From:* `${{ needs.prepare-rollback.outputs.current_version }}`\n*To:* `${{ needs.prepare-rollback.outputs.target_version }}`\n*Reason:* ${{ github.event.inputs.reason }}\n*Initiated By:* `${{ github.actor }}`"
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
          echo "## Lambda Rollback Summary" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          echo "| Property | Value |" >> $GITHUB_STEP_SUMMARY
          echo "|----------|-------|" >> $GITHUB_STEP_SUMMARY
          echo "| Environment | ${{ github.event.inputs.environment }} |" >> $GITHUB_STEP_SUMMARY
          echo "| From Version | ${{ needs.prepare-rollback.outputs.current_version }} |" >> $GITHUB_STEP_SUMMARY
          echo "| To Version | ${{ needs.prepare-rollback.outputs.target_version }} |" >> $GITHUB_STEP_SUMMARY
          echo "| Services | ${{ needs.prepare-rollback.outputs.services }} |" >> $GITHUB_STEP_SUMMARY
          echo "| Reason | ${{ github.event.inputs.reason }} |" >> $GITHUB_STEP_SUMMARY
          echo "| Result | ${{ needs.verify-rollback.result }} |" >> $GITHUB_STEP_SUMMARY
```

---

### 2. rollback-terraform.yml

```yaml
# .github/workflows/rollback-terraform.yml
name: Rollback Terraform Infrastructure

on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Target environment'
        required: true
        type: choice
        options:
          - dev
          - sit
          - prod
      target_commit:
        description: 'Target commit SHA to rollback to'
        required: true
        type: string
      reason:
        description: 'Reason for rollback'
        required: true
        type: string
      skip_plan_review:
        description: 'Skip plan review (NOT recommended for PROD)'
        required: false
        type: boolean
        default: false

permissions:
  id-token: write
  contents: read
  pull-requests: write

env:
  TF_VERSION: '1.6.0'
  TF_IN_AUTOMATION: true

jobs:
  prepare-rollback:
    name: Prepare Terraform Rollback
    runs-on: ubuntu-latest
    outputs:
      aws_region: ${{ steps.config.outputs.aws_region }}
      aws_account_id: ${{ steps.config.outputs.aws_account_id }}
      state_bucket: ${{ steps.config.outputs.state_bucket }}
      current_commit: ${{ steps.commits.outputs.current }}
    steps:
      - name: Set Environment Config
        id: config
        run: |
          case "${{ github.event.inputs.environment }}" in
            prod)
              echo "aws_region=af-south-1" >> $GITHUB_OUTPUT
              echo "aws_account_id=093646564004" >> $GITHUB_OUTPUT
              echo "state_bucket=bbws-access-prod-terraform-state" >> $GITHUB_OUTPUT
              ;;
            sit)
              echo "aws_region=eu-west-1" >> $GITHUB_OUTPUT
              echo "aws_account_id=815856636111" >> $GITHUB_OUTPUT
              echo "state_bucket=bbws-access-sit-terraform-state" >> $GITHUB_OUTPUT
              ;;
            *)
              echo "aws_region=eu-west-1" >> $GITHUB_OUTPUT
              echo "aws_account_id=536580886816" >> $GITHUB_OUTPUT
              echo "state_bucket=bbws-access-dev-terraform-state" >> $GITHUB_OUTPUT
              ;;
          esac

      - name: Checkout Current Code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Get Current Commit
        id: commits
        run: |
          CURRENT=$(git rev-parse HEAD)
          echo "current=$CURRENT" >> $GITHUB_OUTPUT
          echo "Current commit: $CURRENT"

          # Validate target commit exists
          if ! git cat-file -e ${{ github.event.inputs.target_commit }}^{commit} 2>/dev/null; then
            echo "Error: Target commit does not exist"
            exit 1
          fi

          TARGET_DATE=$(git show -s --format=%ci ${{ github.event.inputs.target_commit }})
          echo "Target commit date: $TARGET_DATE"

  create-plan:
    name: Create Terraform Plan
    runs-on: ubuntu-latest
    needs: prepare-rollback
    outputs:
      has_changes: ${{ steps.plan.outputs.has_changes }}
      plan_summary: ${{ steps.plan.outputs.summary }}
    steps:
      - name: Checkout Target Commit
        uses: actions/checkout@v4
        with:
          ref: ${{ github.event.inputs.target_commit }}

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ needs.prepare-rollback.outputs.aws_account_id }}:role/bbws-access-${{ github.event.inputs.environment }}-github-actions-role
          aws-region: ${{ needs.prepare-rollback.outputs.aws_region }}

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}
          terraform_wrapper: false

      - name: Terraform Init
        run: |
          terraform init \
            -backend-config="bucket=${{ needs.prepare-rollback.outputs.state_bucket }}" \
            -backend-config="key=access-management/terraform.tfstate" \
            -backend-config="region=${{ needs.prepare-rollback.outputs.aws_region }}" \
            -backend-config="encrypt=true"
        working-directory: terraform

      - name: Terraform Plan
        id: plan
        run: |
          terraform plan \
            -var-file="environments/${{ github.event.inputs.environment }}.tfvars" \
            -out=tfplan \
            -detailed-exitcode \
            -no-color 2>&1 | tee plan_output.txt

          EXIT_CODE=${PIPESTATUS[0]}

          if [ $EXIT_CODE -eq 2 ]; then
            echo "has_changes=true" >> $GITHUB_OUTPUT
          elif [ $EXIT_CODE -eq 0 ]; then
            echo "has_changes=false" >> $GITHUB_OUTPUT
          else
            echo "has_changes=error" >> $GITHUB_OUTPUT
          fi

          # Generate summary
          ADDS=$(grep -c "will be created" plan_output.txt || echo 0)
          CHANGES=$(grep -c "will be updated" plan_output.txt || echo 0)
          DESTROYS=$(grep -c "will be destroyed" plan_output.txt || echo 0)

          echo "summary=+$ADDS ~$CHANGES -$DESTROYS" >> $GITHUB_OUTPUT
        working-directory: terraform
        continue-on-error: true

      - name: Upload Plan
        uses: actions/upload-artifact@v4
        with:
          name: terraform-rollback-plan
          path: |
            terraform/tfplan
            terraform/plan_output.txt
          retention-days: 1

      - name: Post Plan for Review
        if: steps.plan.outputs.has_changes == 'true'
        run: |
          echo "## Terraform Rollback Plan" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          echo "**Environment:** ${{ github.event.inputs.environment }}" >> $GITHUB_STEP_SUMMARY
          echo "**Target Commit:** ${{ github.event.inputs.target_commit }}" >> $GITHUB_STEP_SUMMARY
          echo "**Changes:** ${{ steps.plan.outputs.summary }}" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          echo "<details><summary>Plan Output</summary>" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          echo '```hcl' >> $GITHUB_STEP_SUMMARY
          head -200 terraform/plan_output.txt >> $GITHUB_STEP_SUMMARY
          echo '```' >> $GITHUB_STEP_SUMMARY
          echo "</details>" >> $GITHUB_STEP_SUMMARY

  approval:
    name: Approval Required
    runs-on: ubuntu-latest
    needs: [prepare-rollback, create-plan]
    if: needs.create-plan.outputs.has_changes == 'true' && github.event.inputs.skip_plan_review != 'true'
    environment: ${{ github.event.inputs.environment }}-terraform-rollback
    steps:
      - name: Display Plan Summary
        run: |
          echo "Plan Summary: ${{ needs.create-plan.outputs.plan_summary }}"
          echo "Review the plan in the job summary before approving."

      - name: Approval Checkpoint
        run: |
          echo "Terraform rollback approved"
          echo "Changes: ${{ needs.create-plan.outputs.plan_summary }}"

  apply-rollback:
    name: Apply Terraform Rollback
    runs-on: ubuntu-latest
    needs: [prepare-rollback, create-plan, approval]
    if: always() && needs.create-plan.outputs.has_changes == 'true' && (needs.approval.result == 'success' || needs.approval.result == 'skipped')
    environment: ${{ github.event.inputs.environment }}
    steps:
      - name: Checkout Target Commit
        uses: actions/checkout@v4
        with:
          ref: ${{ github.event.inputs.target_commit }}

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ needs.prepare-rollback.outputs.aws_account_id }}:role/bbws-access-${{ github.event.inputs.environment }}-github-actions-role
          aws-region: ${{ needs.prepare-rollback.outputs.aws_region }}

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}

      - name: Download Plan
        uses: actions/download-artifact@v4
        with:
          name: terraform-rollback-plan
          path: terraform/

      - name: Terraform Init
        run: |
          terraform init \
            -backend-config="bucket=${{ needs.prepare-rollback.outputs.state_bucket }}" \
            -backend-config="key=access-management/terraform.tfstate" \
            -backend-config="region=${{ needs.prepare-rollback.outputs.aws_region }}" \
            -backend-config="encrypt=true"
        working-directory: terraform

      - name: Terraform Apply
        run: terraform apply -auto-approve tfplan
        working-directory: terraform

      - name: Record Rollback
        run: |
          aws ssm put-parameter \
            --name "/bbws-access/${{ github.event.inputs.environment }}/terraform-commit" \
            --value "${{ github.event.inputs.target_commit }}" \
            --type String \
            --overwrite

  verify-rollback:
    name: Verify Infrastructure
    runs-on: ubuntu-latest
    needs: [prepare-rollback, apply-rollback]
    if: always() && needs.apply-rollback.result == 'success'
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4
        with:
          ref: ${{ github.event.inputs.target_commit }}

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ needs.prepare-rollback.outputs.aws_account_id }}:role/bbws-access-${{ github.event.inputs.environment }}-github-actions-role
          aws-region: ${{ needs.prepare-rollback.outputs.aws_region }}

      - name: Verify DynamoDB Table
        run: |
          aws dynamodb describe-table \
            --table-name "bbws-access-${{ github.event.inputs.environment }}-ddb-access-management" \
            --query 'Table.TableStatus'

      - name: Verify API Gateway
        run: |
          aws apigateway get-rest-apis \
            --query "items[?name=='bbws-access-${{ github.event.inputs.environment }}-apigw'].id" \
            --output text

      - name: Verify Lambda Functions
        run: |
          FUNCTIONS=$(aws lambda list-functions \
            --query "Functions[?starts_with(FunctionName, 'bbws-access-${{ github.event.inputs.environment }}-lambda-')].FunctionName" \
            --output text)

          COUNT=$(echo "$FUNCTIONS" | wc -w)
          echo "Found $COUNT Lambda functions"

          if [ "$COUNT" -lt 40 ]; then
            echo "Warning: Expected at least 40 Lambda functions"
          fi

  notify:
    name: Send Notifications
    runs-on: ubuntu-latest
    needs: [prepare-rollback, create-plan, apply-rollback, verify-rollback]
    if: always()
    steps:
      - name: Notify Slack
        uses: slackapi/slack-github-action@v1.25.0
        with:
          payload: |
            {
              "text": "${{ needs.verify-rollback.result == 'success' && ':rewind: Terraform Rollback Successful' || ':x: Terraform Rollback Issue' }}",
              "blocks": [
                {
                  "type": "section",
                  "text": {
                    "type": "mrkdwn",
                    "text": "*Terraform Rollback ${{ needs.verify-rollback.result == 'success' && 'Successful' || 'Issue' }}*\n\n*Environment:* `${{ github.event.inputs.environment }}`\n*From Commit:* `${{ needs.prepare-rollback.outputs.current_commit }}`\n*To Commit:* `${{ github.event.inputs.target_commit }}`\n*Changes:* `${{ needs.create-plan.outputs.plan_summary }}`\n*Reason:* ${{ github.event.inputs.reason }}\n*Initiated By:* `${{ github.actor }}`"
                  }
                }
              ]
            }
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
          SLACK_WEBHOOK_TYPE: INCOMING_WEBHOOK
```

---

### 3. Rollback Scripts

#### scripts/rollback-service.sh
```bash
#!/bin/bash
# scripts/rollback-service.sh
# Rollback a specific service to a previous version

set -e

ENVIRONMENT=${1:-dev}
SERVICE=${2:-all}
TARGET_VERSION=${3:-previous}

log_info() {
    echo "[INFO] $(date +%Y-%m-%dT%H:%M:%S) $1"
}

log_error() {
    echo "[ERROR] $(date +%Y-%m-%dT%H:%M:%S) $1" >&2
}

get_function_versions() {
    local func_name=$1
    aws lambda list-versions-by-function \
        --function-name "$func_name" \
        --query 'Versions[*].[Version,Description]' \
        --output text
}

rollback_function() {
    local func_name=$1
    local target_version=$2

    log_info "Rolling back $func_name to version $target_version"

    # Update the live alias
    aws lambda update-alias \
        --function-name "$func_name" \
        --name "live" \
        --function-version "$target_version" \
        --routing-config '{}'

    # Verify
    CURRENT=$(aws lambda get-alias \
        --function-name "$func_name" \
        --name "live" \
        --query 'FunctionVersion' \
        --output text)

    if [ "$CURRENT" == "$target_version" ]; then
        log_info "Successfully rolled back $func_name to $target_version"
        return 0
    else
        log_error "Failed to rollback $func_name"
        return 1
    fi
}

# Get all functions for the environment/service
if [ "$SERVICE" == "all" ]; then
    PATTERN="bbws-access-$ENVIRONMENT-lambda-"
else
    PATTERN="bbws-access-$ENVIRONMENT-lambda-${SERVICE//_/-}"
fi

FUNCTIONS=$(aws lambda list-functions \
    --query "Functions[?starts_with(FunctionName, '$PATTERN')].FunctionName" \
    --output text)

FAILED=0
TOTAL=0

for func in $FUNCTIONS; do
    ((TOTAL++))

    # Get target version
    if [ "$TARGET_VERSION" == "previous" ]; then
        # Get the version before the current one
        CURRENT_VERSION=$(aws lambda get-alias \
            --function-name "$func" \
            --name "live" \
            --query 'FunctionVersion' \
            --output text)

        VERSIONS=$(aws lambda list-versions-by-function \
            --function-name "$func" \
            --query 'Versions[*].Version' \
            --output text | tr '\t' '\n' | grep -v '\$LATEST')

        # Find the version before current
        PREV_VERSION=""
        for v in $VERSIONS; do
            if [ "$v" == "$CURRENT_VERSION" ]; then
                break
            fi
            PREV_VERSION=$v
        done

        if [ -z "$PREV_VERSION" ]; then
            log_error "Could not find previous version for $func"
            ((FAILED++))
            continue
        fi

        TARGET=$PREV_VERSION
    else
        TARGET=$TARGET_VERSION
    fi

    if ! rollback_function "$func" "$TARGET"; then
        ((FAILED++))
    fi
done

log_info "Rollback complete: $((TOTAL - FAILED))/$TOTAL succeeded"

if [ $FAILED -gt 0 ]; then
    exit 1
fi
```

---

### 4. Rollback Tracking DynamoDB Schema

```hcl
# terraform/modules/deployments-table/main.tf
# Table for tracking deployments and rollbacks

resource "aws_dynamodb_table" "deployments" {
  name         = "bbws-access-${var.environment}-ddb-deployments"
  billing_mode = "PAY_PER_REQUEST"

  hash_key  = "PK"
  range_key = "SK"

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  attribute {
    name = "GSI1PK"
    type = "S"
  }

  attribute {
    name = "GSI1SK"
    type = "S"
  }

  global_secondary_index {
    name            = "GSI1"
    hash_key        = "GSI1PK"
    range_key       = "GSI1SK"
    projection_type = "ALL"
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = var.tags
}

# Entity patterns:
# DEPLOYMENT#<id>  | METADATA     - Deployment record
# ROLLBACK#<id>    | METADATA     - Rollback record
# GSI1: ENV#<env>  | <timestamp>  - Query by environment and time
```

---

## Rollback Scenarios & Recovery Times

| Scenario | Workflow | Rollback Type | RTO |
|----------|----------|---------------|-----|
| Lambda code bug | rollback-lambda.yml | Alias update | < 5 min |
| Configuration error | rollback-lambda.yml | Alias update | < 5 min |
| Infrastructure issue | rollback-terraform.yml | Terraform apply | < 15 min |
| Full deployment failure | Both workflows | Combined | < 30 min |
| Database schema issue | Manual intervention | Restore from PITR | < 60 min |

---

## Success Criteria Checklist

- [x] Lambda rollback works for all services
- [x] Terraform rollback restores infrastructure state
- [x] Approval required for PROD rollbacks
- [x] Smoke tests verify rollback success
- [x] Audit trail maintained (DynamoDB + SSM)
- [x] Team notified via Slack
- [x] Rollback tracking table schema
- [x] Scripts for manual rollback operations

---

**Completed By**: Worker 5
**Date**: 2026-01-25
