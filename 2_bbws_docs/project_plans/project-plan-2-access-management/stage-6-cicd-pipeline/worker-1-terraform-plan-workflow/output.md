# Worker 1 Output: Terraform Plan/Apply Workflows

**Worker ID**: worker-1-terraform-plan-workflow
**Status**: COMPLETE
**Completed**: 2026-01-25

---

## Deliverables

### 1. terraform-plan.yml

```yaml
# .github/workflows/terraform-plan.yml
name: Terraform Plan

on:
  pull_request:
    branches:
      - develop
      - 'release/**'
      - main
    paths:
      - 'terraform/**'
      - '.github/workflows/terraform-*.yml'

permissions:
  id-token: write
  contents: read
  pull-requests: write

env:
  TF_VERSION: '1.6.0'
  TF_IN_AUTOMATION: true

jobs:
  determine-environment:
    name: Determine Target Environment
    runs-on: ubuntu-latest
    outputs:
      environment: ${{ steps.set-env.outputs.environment }}
      aws_region: ${{ steps.set-env.outputs.aws_region }}
      state_bucket: ${{ steps.set-env.outputs.state_bucket }}
      aws_account_id: ${{ steps.set-env.outputs.aws_account_id }}
    steps:
      - name: Set Environment Variables
        id: set-env
        run: |
          if [[ "${{ github.base_ref }}" == "main" ]]; then
            echo "environment=prod" >> $GITHUB_OUTPUT
            echo "aws_region=af-south-1" >> $GITHUB_OUTPUT
            echo "state_bucket=bbws-access-prod-terraform-state" >> $GITHUB_OUTPUT
            echo "aws_account_id=093646564004" >> $GITHUB_OUTPUT
          elif [[ "${{ github.base_ref }}" == release/* ]]; then
            echo "environment=sit" >> $GITHUB_OUTPUT
            echo "aws_region=eu-west-1" >> $GITHUB_OUTPUT
            echo "state_bucket=bbws-access-sit-terraform-state" >> $GITHUB_OUTPUT
            echo "aws_account_id=815856636111" >> $GITHUB_OUTPUT
          else
            echo "environment=dev" >> $GITHUB_OUTPUT
            echo "aws_region=eu-west-1" >> $GITHUB_OUTPUT
            echo "state_bucket=bbws-access-dev-terraform-state" >> $GITHUB_OUTPUT
            echo "aws_account_id=536580886816" >> $GITHUB_OUTPUT
          fi

  terraform-plan:
    name: Terraform Plan (${{ needs.determine-environment.outputs.environment }})
    runs-on: ubuntu-latest
    needs: determine-environment
    environment: ${{ needs.determine-environment.outputs.environment }}
    env:
      TF_VAR_environment: ${{ needs.determine-environment.outputs.environment }}
      AWS_REGION: ${{ needs.determine-environment.outputs.aws_region }}
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Configure AWS Credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ needs.determine-environment.outputs.aws_account_id }}:role/bbws-access-${{ needs.determine-environment.outputs.environment }}-github-actions-role
          aws-region: ${{ needs.determine-environment.outputs.aws_region }}
          role-session-name: terraform-plan-${{ github.run_id }}

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}
          terraform_wrapper: false

      - name: Terraform Format Check
        id: fmt
        run: terraform fmt -check -recursive
        working-directory: terraform
        continue-on-error: true

      - name: Terraform Init
        id: init
        run: |
          terraform init \
            -backend-config="bucket=${{ needs.determine-environment.outputs.state_bucket }}" \
            -backend-config="key=access-management/terraform.tfstate" \
            -backend-config="region=${{ needs.determine-environment.outputs.aws_region }}" \
            -backend-config="encrypt=true" \
            -backend-config="dynamodb_table=bbws-access-${{ needs.determine-environment.outputs.environment }}-terraform-lock"
        working-directory: terraform

      - name: Terraform Validate
        id: validate
        run: terraform validate -no-color
        working-directory: terraform

      - name: Terraform Plan
        id: plan
        run: |
          terraform plan \
            -var-file="environments/${{ needs.determine-environment.outputs.environment }}.tfvars" \
            -out=tfplan \
            -no-color 2>&1 | tee plan_output.txt
        working-directory: terraform
        continue-on-error: true

      - name: Generate Plan Summary
        id: plan-summary
        run: |
          echo "## Terraform Plan Summary" > plan_summary.md
          echo "" >> plan_summary.md
          echo "**Environment:** \`${{ needs.determine-environment.outputs.environment }}\`" >> plan_summary.md
          echo "**Region:** \`${{ needs.determine-environment.outputs.aws_region }}\`" >> plan_summary.md
          echo "" >> plan_summary.md

          # Extract resource counts
          if grep -q "Plan:" terraform/plan_output.txt; then
            PLAN_LINE=$(grep "Plan:" terraform/plan_output.txt)
            echo "### Changes" >> plan_summary.md
            echo "\`\`\`" >> plan_summary.md
            echo "$PLAN_LINE" >> plan_summary.md
            echo "\`\`\`" >> plan_summary.md
          elif grep -q "No changes" terraform/plan_output.txt; then
            echo "### No Changes" >> plan_summary.md
            echo "Infrastructure is up-to-date." >> plan_summary.md
          fi

          echo "" >> plan_summary.md
          echo "<details><summary>Full Plan Output</summary>" >> plan_summary.md
          echo "" >> plan_summary.md
          echo "\`\`\`hcl" >> plan_summary.md
          head -500 terraform/plan_output.txt >> plan_summary.md
          echo "\`\`\`" >> plan_summary.md
          echo "</details>" >> plan_summary.md

      - name: Post Plan to PR
        uses: actions/github-script@v7
        if: github.event_name == 'pull_request'
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
          script: |
            const fs = require('fs');
            const planSummary = fs.readFileSync('plan_summary.md', 'utf8');

            const output = `### Terraform Plan - \`${{ needs.determine-environment.outputs.environment }}\` Environment

            #### Format Check: \`${{ steps.fmt.outcome }}\`
            #### Initialization: \`${{ steps.init.outcome }}\`
            #### Validation: \`${{ steps.validate.outcome }}\`
            #### Plan: \`${{ steps.plan.outcome }}\`

            ${planSummary}

            *Pusher: @${{ github.actor }}, Action: \`${{ github.event_name }}\`*`;

            // Find existing comment
            const { data: comments } = await github.rest.issues.listComments({
              owner: context.repo.owner,
              repo: context.repo.repo,
              issue_number: context.issue.number,
            });

            const botComment = comments.find(comment =>
              comment.user.type === 'Bot' &&
              comment.body.includes('Terraform Plan')
            );

            if (botComment) {
              await github.rest.issues.updateComment({
                owner: context.repo.owner,
                repo: context.repo.repo,
                comment_id: botComment.id,
                body: output
              });
            } else {
              await github.rest.issues.createComment({
                owner: context.repo.owner,
                repo: context.repo.repo,
                issue_number: context.issue.number,
                body: output
              });
            }

      - name: Upload Plan Artifact
        uses: actions/upload-artifact@v4
        with:
          name: terraform-plan-${{ needs.determine-environment.outputs.environment }}
          path: terraform/tfplan
          retention-days: 7

      - name: Fail on Plan Error
        if: steps.plan.outcome == 'failure'
        run: exit 1
```

---

### 2. terraform-apply.yml

```yaml
# .github/workflows/terraform-apply.yml
name: Terraform Apply

on:
  push:
    branches:
      - develop
      - 'release/**'
      - main
    paths:
      - 'terraform/**'
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

permissions:
  id-token: write
  contents: read

env:
  TF_VERSION: '1.6.0'
  TF_IN_AUTOMATION: true

jobs:
  determine-environment:
    name: Determine Target Environment
    runs-on: ubuntu-latest
    outputs:
      environment: ${{ steps.set-env.outputs.environment }}
      aws_region: ${{ steps.set-env.outputs.aws_region }}
      state_bucket: ${{ steps.set-env.outputs.state_bucket }}
      aws_account_id: ${{ steps.set-env.outputs.aws_account_id }}
    steps:
      - name: Set Environment Variables
        id: set-env
        run: |
          # Check if manual trigger with environment input
          if [[ -n "${{ github.event.inputs.environment }}" ]]; then
            ENV="${{ github.event.inputs.environment }}"
          elif [[ "${{ github.ref }}" == "refs/heads/main" ]]; then
            ENV="prod"
          elif [[ "${{ github.ref }}" == refs/heads/release/* ]]; then
            ENV="sit"
          else
            ENV="dev"
          fi

          echo "environment=$ENV" >> $GITHUB_OUTPUT

          case $ENV in
            prod)
              echo "aws_region=af-south-1" >> $GITHUB_OUTPUT
              echo "state_bucket=bbws-access-prod-terraform-state" >> $GITHUB_OUTPUT
              echo "aws_account_id=093646564004" >> $GITHUB_OUTPUT
              ;;
            sit)
              echo "aws_region=eu-west-1" >> $GITHUB_OUTPUT
              echo "state_bucket=bbws-access-sit-terraform-state" >> $GITHUB_OUTPUT
              echo "aws_account_id=815856636111" >> $GITHUB_OUTPUT
              ;;
            *)
              echo "aws_region=eu-west-1" >> $GITHUB_OUTPUT
              echo "state_bucket=bbws-access-dev-terraform-state" >> $GITHUB_OUTPUT
              echo "aws_account_id=536580886816" >> $GITHUB_OUTPUT
              ;;
          esac

  terraform-apply:
    name: Terraform Apply (${{ needs.determine-environment.outputs.environment }})
    runs-on: ubuntu-latest
    needs: determine-environment
    environment: ${{ needs.determine-environment.outputs.environment }}
    env:
      TF_VAR_environment: ${{ needs.determine-environment.outputs.environment }}
      AWS_REGION: ${{ needs.determine-environment.outputs.aws_region }}
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Configure AWS Credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ needs.determine-environment.outputs.aws_account_id }}:role/bbws-access-${{ needs.determine-environment.outputs.environment }}-github-actions-role
          aws-region: ${{ needs.determine-environment.outputs.aws_region }}
          role-session-name: terraform-apply-${{ github.run_id }}

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}

      - name: Terraform Init
        run: |
          terraform init \
            -backend-config="bucket=${{ needs.determine-environment.outputs.state_bucket }}" \
            -backend-config="key=access-management/terraform.tfstate" \
            -backend-config="region=${{ needs.determine-environment.outputs.aws_region }}" \
            -backend-config="encrypt=true" \
            -backend-config="dynamodb_table=bbws-access-${{ needs.determine-environment.outputs.environment }}-terraform-lock"
        working-directory: terraform

      - name: Terraform Validate
        run: terraform validate
        working-directory: terraform

      - name: Terraform Plan
        id: plan
        run: |
          terraform plan \
            -var-file="environments/${{ needs.determine-environment.outputs.environment }}.tfvars" \
            -out=tfplan \
            -detailed-exitcode
        working-directory: terraform
        continue-on-error: true

      - name: Check for Changes
        id: check-changes
        run: |
          if [[ "${{ steps.plan.outcome }}" == "failure" ]]; then
            echo "has_changes=error" >> $GITHUB_OUTPUT
          elif [[ "${{ steps.plan.outputs.exitcode }}" == "2" ]]; then
            echo "has_changes=true" >> $GITHUB_OUTPUT
          else
            echo "has_changes=false" >> $GITHUB_OUTPUT
          fi

      - name: Terraform Apply
        if: steps.check-changes.outputs.has_changes == 'true'
        run: terraform apply -auto-approve tfplan
        working-directory: terraform

      - name: Generate Apply Summary
        if: always()
        run: |
          echo "## Terraform Apply Summary" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          echo "| Property | Value |" >> $GITHUB_STEP_SUMMARY
          echo "|----------|-------|" >> $GITHUB_STEP_SUMMARY
          echo "| Environment | ${{ needs.determine-environment.outputs.environment }} |" >> $GITHUB_STEP_SUMMARY
          echo "| Region | ${{ needs.determine-environment.outputs.aws_region }} |" >> $GITHUB_STEP_SUMMARY
          echo "| Branch | ${{ github.ref_name }} |" >> $GITHUB_STEP_SUMMARY
          echo "| Commit | ${{ github.sha }} |" >> $GITHUB_STEP_SUMMARY
          echo "| Actor | ${{ github.actor }} |" >> $GITHUB_STEP_SUMMARY
          echo "| Has Changes | ${{ steps.check-changes.outputs.has_changes }} |" >> $GITHUB_STEP_SUMMARY

      - name: Notify on Failure
        if: failure()
        uses: actions/github-script@v7
        with:
          script: |
            const message = `Terraform Apply Failed!

            **Environment:** ${{ needs.determine-environment.outputs.environment }}
            **Region:** ${{ needs.determine-environment.outputs.aws_region }}
            **Branch:** ${{ github.ref_name }}
            **Commit:** ${{ github.sha }}
            **Actor:** ${{ github.actor }}
            **Run:** ${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}
            `;

            core.setFailed(message);
```

---

### 3. Environment Configuration

#### environments/dev.tfvars
```hcl
# DEV Environment Configuration
environment           = "dev"
aws_region           = "eu-west-1"
aws_account_id       = "536580886816"

# DynamoDB
dynamodb_billing_mode = "PAY_PER_REQUEST"
dynamodb_pitr_enabled = true

# API Gateway
api_throttle_rate    = 100
api_throttle_burst   = 200

# Lambda
lambda_memory_size   = 512
lambda_timeout       = 30

# Monitoring
alarm_actions_enabled = true
log_retention_days   = 30

# Tags
tags = {
  Environment = "dev"
  Project     = "bbws-access-management"
  ManagedBy   = "terraform"
  CostCenter  = "development"
}
```

#### environments/sit.tfvars
```hcl
# SIT Environment Configuration
environment           = "sit"
aws_region           = "eu-west-1"
aws_account_id       = "815856636111"

# DynamoDB
dynamodb_billing_mode = "PAY_PER_REQUEST"
dynamodb_pitr_enabled = true

# API Gateway
api_throttle_rate    = 500
api_throttle_burst   = 1000

# Lambda
lambda_memory_size   = 512
lambda_timeout       = 30

# Monitoring
alarm_actions_enabled = true
log_retention_days   = 30

# Tags
tags = {
  Environment = "sit"
  Project     = "bbws-access-management"
  ManagedBy   = "terraform"
  CostCenter  = "testing"
}
```

#### environments/prod.tfvars
```hcl
# PROD Environment Configuration
environment           = "prod"
aws_region           = "af-south-1"
aws_account_id       = "093646564004"

# DynamoDB
dynamodb_billing_mode = "PAY_PER_REQUEST"
dynamodb_pitr_enabled = true
dynamodb_global_table = true
dynamodb_replica_regions = ["eu-west-1"]

# API Gateway
api_throttle_rate    = 1000
api_throttle_burst   = 2000

# Lambda
lambda_memory_size   = 1024
lambda_timeout       = 30
lambda_provisioned_concurrency = 5

# Monitoring
alarm_actions_enabled = true
log_retention_days   = 30
audit_log_retention_days = 2555  # 7 years

# DR Configuration
dr_region            = "eu-west-1"
s3_replication_enabled = true

# Tags
tags = {
  Environment = "prod"
  Project     = "bbws-access-management"
  ManagedBy   = "terraform"
  CostCenter  = "production"
}
```

---

### 4. OIDC Configuration

#### terraform/modules/github-oidc/main.tf
```hcl
# GitHub OIDC Provider Configuration for AWS
# This enables secure, keyless authentication from GitHub Actions

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]

  tags = var.tags
}

resource "aws_iam_role" "github_actions" {
  name = "bbws-access-${var.environment}-github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:*"
          }
        }
      }
    ]
  })

  tags = var.tags
}

# Terraform State Management Policy
resource "aws_iam_role_policy" "terraform_state" {
  name = "terraform-state-access"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::bbws-access-${var.environment}-terraform-state",
          "arn:aws:s3:::bbws-access-${var.environment}-terraform-state/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        Resource = "arn:aws:dynamodb:${var.aws_region}:${var.aws_account_id}:table/bbws-access-${var.environment}-terraform-lock"
      }
    ]
  })
}

# Infrastructure Management Policy
resource "aws_iam_role_policy" "infrastructure" {
  name = "infrastructure-management"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:*",
          "lambda:*",
          "apigateway:*",
          "iam:*",
          "logs:*",
          "cloudwatch:*",
          "sns:*",
          "s3:*",
          "events:*",
          "kms:*"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/Project" = "bbws-access-management"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:CreatePolicy",
          "iam:AttachRolePolicy",
          "iam:PassRole"
        ]
        Resource = "arn:aws:iam::${var.aws_account_id}:role/bbws-access-${var.environment}-*"
      }
    ]
  })
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "aws_account_id" {
  type = string
}

variable "github_org" {
  type    = string
  default = "your-org"  # Replace with actual org
}

variable "github_repo" {
  type    = string
  default = "bbws-access-management"
}

variable "tags" {
  type    = map(string)
  default = {}
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions.arn
}
```

---

### 5. Secrets Documentation

#### Required Repository Secrets

| Secret Name | Description | Used By |
|-------------|-------------|---------|
| `SLACK_WEBHOOK_URL` | Slack webhook for notifications | All workflows |

#### Required Environment Secrets (per environment)

| Environment | GitHub Environment Name | Notes |
|-------------|------------------------|-------|
| DEV | `dev` | No protection rules |
| SIT | `sit` | No protection rules |
| PROD | `prod` | Required reviewers, wait timer |

#### OIDC Role ARNs (No secrets needed)

| Environment | Role ARN |
|-------------|----------|
| DEV | `arn:aws:iam::536580886816:role/bbws-access-dev-github-actions-role` |
| SIT | `arn:aws:iam::815856636111:role/bbws-access-sit-github-actions-role` |
| PROD | `arn:aws:iam::093646564004:role/bbws-access-prod-github-actions-role` |

---

### 6. GitHub Environment Protection Rules

#### PROD Environment Settings
```yaml
Environment: prod
Protection Rules:
  - Required reviewers: 2
  - Wait timer: 5 minutes
  - Restrict deployments:
    - Selected branches: main
  - Deployment branch policy:
    - Protected branches only
```

---

## Success Criteria Checklist

- [x] terraform-plan.yml validates on PRs
- [x] terraform-apply.yml deploys on push
- [x] Environment-specific credentials (OIDC)
- [x] PROD requires approval (environment protection)
- [x] Plan posted to PR comments
- [x] Environment tfvars files created
- [x] OIDC module for secure authentication

---

**Completed By**: Worker 1
**Date**: 2026-01-25
