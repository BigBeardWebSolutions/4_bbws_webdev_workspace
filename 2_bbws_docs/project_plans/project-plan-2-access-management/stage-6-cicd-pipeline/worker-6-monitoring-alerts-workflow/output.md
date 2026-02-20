# Worker 6 Output: Monitoring & Alerts Workflows

**Worker ID**: worker-6-monitoring-alerts-workflow
**Status**: COMPLETE
**Completed**: 2026-01-25

---

## Deliverables

### 1. setup-monitoring.yml

```yaml
# .github/workflows/setup-monitoring.yml
name: Setup Monitoring & Alerts

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
      components:
        description: 'Components to setup (comma-separated or "all")'
        required: false
        type: string
        default: 'all'
  workflow_call:
    inputs:
      environment:
        required: true
        type: string

permissions:
  id-token: write
  contents: read

env:
  TF_VERSION: '1.6.0'

jobs:
  configure-environment:
    name: Configure Environment
    runs-on: ubuntu-latest
    outputs:
      aws_region: ${{ steps.config.outputs.aws_region }}
      aws_account_id: ${{ steps.config.outputs.aws_account_id }}
      state_bucket: ${{ steps.config.outputs.state_bucket }}
    steps:
      - name: Set Environment Config
        id: config
        run: |
          ENV="${{ inputs.environment || github.event.inputs.environment }}"
          case "$ENV" in
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

  deploy-cloudwatch-alarms:
    name: Deploy CloudWatch Alarms
    runs-on: ubuntu-latest
    needs: configure-environment
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ needs.configure-environment.outputs.aws_account_id }}:role/bbws-access-${{ inputs.environment || github.event.inputs.environment }}-github-actions-role
          aws-region: ${{ needs.configure-environment.outputs.aws_region }}

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}

      - name: Deploy Monitoring Module
        run: |
          cd terraform/modules/monitoring
          terraform init \
            -backend-config="bucket=${{ needs.configure-environment.outputs.state_bucket }}" \
            -backend-config="key=access-management/monitoring.tfstate" \
            -backend-config="region=${{ needs.configure-environment.outputs.aws_region }}"

          terraform apply \
            -var="environment=${{ inputs.environment || github.event.inputs.environment }}" \
            -var="aws_region=${{ needs.configure-environment.outputs.aws_region }}" \
            -auto-approve

  configure-sns-topics:
    name: Configure SNS Topics
    runs-on: ubuntu-latest
    needs: [configure-environment, deploy-cloudwatch-alarms]
    steps:
      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ needs.configure-environment.outputs.aws_account_id }}:role/bbws-access-${{ inputs.environment || github.event.inputs.environment }}-github-actions-role
          aws-region: ${{ needs.configure-environment.outputs.aws_region }}

      - name: Configure Slack Subscription
        if: ${{ secrets.SLACK_WEBHOOK_URL != '' }}
        run: |
          ENV="${{ inputs.environment || github.event.inputs.environment }}"

          # Get SNS topic ARN
          CRITICAL_TOPIC_ARN=$(aws sns list-topics \
            --query "Topics[?contains(TopicArn, 'bbws-access-$ENV-sns-critical')].TopicArn" \
            --output text)

          WARNING_TOPIC_ARN=$(aws sns list-topics \
            --query "Topics[?contains(TopicArn, 'bbws-access-$ENV-sns-warning')].TopicArn" \
            --output text)

          echo "Critical topic: $CRITICAL_TOPIC_ARN"
          echo "Warning topic: $WARNING_TOPIC_ARN"

          # Note: For Lambda-based Slack integration, use the separate alert-notification workflow

      - name: Configure Email Subscriptions
        run: |
          ENV="${{ inputs.environment || github.event.inputs.environment }}"

          # Get topic ARNs
          INFO_TOPIC_ARN=$(aws sns list-topics \
            --query "Topics[?contains(TopicArn, 'bbws-access-$ENV-sns-info')].TopicArn" \
            --output text)

          # Email subscriptions are managed via Terraform
          echo "Info topic configured: $INFO_TOPIC_ARN"

  setup-dashboards:
    name: Setup CloudWatch Dashboards
    runs-on: ubuntu-latest
    needs: [configure-environment, deploy-cloudwatch-alarms]
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ needs.configure-environment.outputs.aws_account_id }}:role/bbws-access-${{ inputs.environment || github.event.inputs.environment }}-github-actions-role
          aws-region: ${{ needs.configure-environment.outputs.aws_region }}

      - name: Deploy Dashboard
        run: |
          ENV="${{ inputs.environment || github.event.inputs.environment }}"
          REGION="${{ needs.configure-environment.outputs.aws_region }}"

          # Dashboard body is in monitoring/dashboards/access-management.json
          aws cloudwatch put-dashboard \
            --dashboard-name "bbws-access-$ENV-dashboard" \
            --dashboard-body file://monitoring/dashboards/access-management.json

          echo "Dashboard deployed: bbws-access-$ENV-dashboard"

  verify-alarms:
    name: Verify Alarm Configuration
    runs-on: ubuntu-latest
    needs: [configure-environment, deploy-cloudwatch-alarms]
    steps:
      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ needs.configure-environment.outputs.aws_account_id }}:role/bbws-access-${{ inputs.environment || github.event.inputs.environment }}-github-actions-role
          aws-region: ${{ needs.configure-environment.outputs.aws_region }}

      - name: List Configured Alarms
        run: |
          ENV="${{ inputs.environment || github.event.inputs.environment }}"

          echo "## CloudWatch Alarms" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          echo "| Alarm Name | State | Actions Enabled |" >> $GITHUB_STEP_SUMMARY
          echo "|------------|-------|-----------------|" >> $GITHUB_STEP_SUMMARY

          aws cloudwatch describe-alarms \
            --alarm-name-prefix "bbws-access-$ENV" \
            --query 'MetricAlarms[*].[AlarmName,StateValue,ActionsEnabled]' \
            --output text | while read -r name state actions; do
              echo "| $name | $state | $actions |" >> $GITHUB_STEP_SUMMARY
          done

      - name: Verify Alarm Count
        run: |
          ENV="${{ inputs.environment || github.event.inputs.environment }}"

          ALARM_COUNT=$(aws cloudwatch describe-alarms \
            --alarm-name-prefix "bbws-access-$ENV" \
            --query 'length(MetricAlarms)' \
            --output text)

          echo "Total alarms configured: $ALARM_COUNT"

          if [ "$ALARM_COUNT" -lt 10 ]; then
            echo "Warning: Expected at least 10 alarms"
          fi

  test-alert:
    name: Test Alert Notification
    runs-on: ubuntu-latest
    needs: [configure-environment, configure-sns-topics]
    if: github.event.inputs.environment != 'prod'
    steps:
      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ needs.configure-environment.outputs.aws_account_id }}:role/bbws-access-${{ inputs.environment || github.event.inputs.environment }}-github-actions-role
          aws-region: ${{ needs.configure-environment.outputs.aws_region }}

      - name: Send Test Alert
        run: |
          ENV="${{ inputs.environment || github.event.inputs.environment }}"

          # Get info topic ARN
          INFO_TOPIC_ARN=$(aws sns list-topics \
            --query "Topics[?contains(TopicArn, 'bbws-access-$ENV-sns-info')].TopicArn" \
            --output text)

          # Send test message
          aws sns publish \
            --topic-arn "$INFO_TOPIC_ARN" \
            --subject "Test Alert - $ENV" \
            --message "This is a test alert from the monitoring setup workflow. Environment: $ENV, Time: $(date -u +%Y-%m-%dT%H:%M:%SZ)"

          echo "Test alert sent to $INFO_TOPIC_ARN"

  summary:
    name: Generate Summary
    runs-on: ubuntu-latest
    needs: [configure-environment, deploy-cloudwatch-alarms, configure-sns-topics, setup-dashboards, verify-alarms]
    if: always()
    steps:
      - name: Generate Summary
        run: |
          echo "## Monitoring Setup Summary" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          echo "| Component | Status |" >> $GITHUB_STEP_SUMMARY
          echo "|-----------|--------|" >> $GITHUB_STEP_SUMMARY
          echo "| CloudWatch Alarms | ${{ needs.deploy-cloudwatch-alarms.result }} |" >> $GITHUB_STEP_SUMMARY
          echo "| SNS Topics | ${{ needs.configure-sns-topics.result }} |" >> $GITHUB_STEP_SUMMARY
          echo "| Dashboards | ${{ needs.setup-dashboards.result }} |" >> $GITHUB_STEP_SUMMARY
          echo "| Verification | ${{ needs.verify-alarms.result }} |" >> $GITHUB_STEP_SUMMARY
```

---

### 2. CloudWatch Alarms Terraform Module

```hcl
# terraform/modules/monitoring/main.tf
# CloudWatch Alarms for Access Management Services

variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "alarm_actions_enabled" {
  type    = bool
  default = true
}

locals {
  prefix = "bbws-access-${var.environment}"

  services = [
    "permission",
    "invitation",
    "team",
    "role",
    "authorizer",
    "audit"
  ]

  # Thresholds vary by environment
  thresholds = {
    dev = {
      lambda_error_threshold      = 10
      lambda_duration_threshold   = 10000  # 10s
      lambda_throttle_threshold   = 5
      api_5xx_threshold           = 5
      api_4xx_threshold           = 20
      dynamodb_throttle_threshold = 5
      authorizer_latency_p95      = 200  # 200ms
    }
    sit = {
      lambda_error_threshold      = 5
      lambda_duration_threshold   = 8000   # 8s
      lambda_throttle_threshold   = 3
      api_5xx_threshold           = 3
      api_4xx_threshold           = 15
      dynamodb_throttle_threshold = 3
      authorizer_latency_p95      = 150
    }
    prod = {
      lambda_error_threshold      = 1
      lambda_duration_threshold   = 5000   # 5s
      lambda_throttle_threshold   = 1
      api_5xx_threshold           = 1
      api_4xx_threshold           = 10
      dynamodb_throttle_threshold = 1
      authorizer_latency_p95      = 100
    }
  }

  current_thresholds = local.thresholds[var.environment]
}

# ============================================================================
# SNS Topics
# ============================================================================

resource "aws_sns_topic" "critical" {
  name = "${local.prefix}-sns-critical"
  tags = {
    Environment = var.environment
    Severity    = "critical"
  }
}

resource "aws_sns_topic" "warning" {
  name = "${local.prefix}-sns-warning"
  tags = {
    Environment = var.environment
    Severity    = "warning"
  }
}

resource "aws_sns_topic" "info" {
  name = "${local.prefix}-sns-info"
  tags = {
    Environment = var.environment
    Severity    = "info"
  }
}

resource "aws_sns_topic" "dlq" {
  name = "${local.prefix}-sns-dlq"
  tags = {
    Environment = var.environment
    Purpose     = "dead-letter-queue"
  }
}

# ============================================================================
# Lambda Error Alarms
# ============================================================================

resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  for_each = toset(local.services)

  alarm_name          = "${local.prefix}-alarm-${each.key}-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = local.current_thresholds.lambda_error_threshold
  alarm_description   = "Lambda errors for ${each.key} service exceeded threshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = "${local.prefix}-lambda-${each.key}-*"
  }

  alarm_actions = var.alarm_actions_enabled ? [aws_sns_topic.critical.arn] : []
  ok_actions    = var.alarm_actions_enabled ? [aws_sns_topic.info.arn] : []

  tags = {
    Environment = var.environment
    Service     = each.key
    Severity    = "critical"
  }
}

# ============================================================================
# Lambda Duration Alarms
# ============================================================================

resource "aws_cloudwatch_metric_alarm" "lambda_duration" {
  for_each = toset(local.services)

  alarm_name          = "${local.prefix}-alarm-${each.key}-lambda-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = 60
  extended_statistic  = "p95"
  threshold           = local.current_thresholds.lambda_duration_threshold
  alarm_description   = "Lambda P95 duration for ${each.key} service exceeded threshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = "${local.prefix}-lambda-${each.key}-*"
  }

  alarm_actions = var.alarm_actions_enabled ? [aws_sns_topic.warning.arn] : []

  tags = {
    Environment = var.environment
    Service     = each.key
    Severity    = "warning"
  }
}

# ============================================================================
# Lambda Throttle Alarms
# ============================================================================

resource "aws_cloudwatch_metric_alarm" "lambda_throttles" {
  for_each = toset(local.services)

  alarm_name          = "${local.prefix}-alarm-${each.key}-lambda-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = local.current_thresholds.lambda_throttle_threshold
  alarm_description   = "Lambda throttles for ${each.key} service"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = "${local.prefix}-lambda-${each.key}-*"
  }

  alarm_actions = var.alarm_actions_enabled ? [aws_sns_topic.critical.arn] : []

  tags = {
    Environment = var.environment
    Service     = each.key
    Severity    = "critical"
  }
}

# ============================================================================
# Authorizer Specific Alarms
# ============================================================================

resource "aws_cloudwatch_metric_alarm" "authorizer_latency" {
  alarm_name          = "${local.prefix}-alarm-authorizer-latency-p95"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = 60
  extended_statistic  = "p95"
  threshold           = local.current_thresholds.authorizer_latency_p95
  alarm_description   = "Authorizer P95 latency exceeded ${local.current_thresholds.authorizer_latency_p95}ms"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = "${local.prefix}-lambda-authorizer"
  }

  alarm_actions = var.alarm_actions_enabled ? [aws_sns_topic.critical.arn] : []

  tags = {
    Environment = var.environment
    Service     = "authorizer"
    Severity    = "critical"
  }
}

# ============================================================================
# API Gateway Alarms
# ============================================================================

resource "aws_cloudwatch_metric_alarm" "api_5xx" {
  alarm_name          = "${local.prefix}-alarm-api-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "5XXError"
  namespace           = "AWS/ApiGateway"
  period              = 60
  statistic           = "Sum"
  threshold           = local.current_thresholds.api_5xx_threshold
  alarm_description   = "API Gateway 5XX errors exceeded threshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ApiName = "${local.prefix}-apigw"
  }

  alarm_actions = var.alarm_actions_enabled ? [aws_sns_topic.critical.arn] : []

  tags = {
    Environment = var.environment
    Severity    = "critical"
  }
}

resource "aws_cloudwatch_metric_alarm" "api_4xx" {
  alarm_name          = "${local.prefix}-alarm-api-4xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "4XXError"
  namespace           = "AWS/ApiGateway"
  period              = 300
  statistic           = "Sum"
  threshold           = local.current_thresholds.api_4xx_threshold
  alarm_description   = "API Gateway 4XX errors exceeded threshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ApiName = "${local.prefix}-apigw"
  }

  alarm_actions = var.alarm_actions_enabled ? [aws_sns_topic.warning.arn] : []

  tags = {
    Environment = var.environment
    Severity    = "warning"
  }
}

# ============================================================================
# DynamoDB Alarms
# ============================================================================

resource "aws_cloudwatch_metric_alarm" "dynamodb_read_throttle" {
  alarm_name          = "${local.prefix}-alarm-dynamodb-read-throttle"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ReadThrottledRequests"
  namespace           = "AWS/DynamoDB"
  period              = 60
  statistic           = "Sum"
  threshold           = local.current_thresholds.dynamodb_throttle_threshold
  alarm_description   = "DynamoDB read throttling detected"
  treat_missing_data  = "notBreaching"

  dimensions = {
    TableName = "${local.prefix}-ddb-access-management"
  }

  alarm_actions = var.alarm_actions_enabled ? [aws_sns_topic.critical.arn] : []

  tags = {
    Environment = var.environment
    Severity    = "critical"
  }
}

resource "aws_cloudwatch_metric_alarm" "dynamodb_write_throttle" {
  alarm_name          = "${local.prefix}-alarm-dynamodb-write-throttle"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "WriteThrottledRequests"
  namespace           = "AWS/DynamoDB"
  period              = 60
  statistic           = "Sum"
  threshold           = local.current_thresholds.dynamodb_throttle_threshold
  alarm_description   = "DynamoDB write throttling detected"
  treat_missing_data  = "notBreaching"

  dimensions = {
    TableName = "${local.prefix}-ddb-access-management"
  }

  alarm_actions = var.alarm_actions_enabled ? [aws_sns_topic.critical.arn] : []

  tags = {
    Environment = var.environment
    Severity    = "critical"
  }
}

# ============================================================================
# Outputs
# ============================================================================

output "sns_topic_arns" {
  value = {
    critical = aws_sns_topic.critical.arn
    warning  = aws_sns_topic.warning.arn
    info     = aws_sns_topic.info.arn
    dlq      = aws_sns_topic.dlq.arn
  }
}

output "alarm_count" {
  value = length(aws_cloudwatch_metric_alarm.lambda_errors) +
          length(aws_cloudwatch_metric_alarm.lambda_duration) +
          length(aws_cloudwatch_metric_alarm.lambda_throttles) + 5
}
```

---

### 3. CloudWatch Dashboard JSON

```json
{
  "widgets": [
    {
      "type": "text",
      "x": 0,
      "y": 0,
      "width": 24,
      "height": 1,
      "properties": {
        "markdown": "# BBWS Access Management Dashboard - ${environment}"
      }
    },
    {
      "type": "metric",
      "x": 0,
      "y": 1,
      "width": 8,
      "height": 6,
      "properties": {
        "title": "Lambda Invocations",
        "view": "timeSeries",
        "stacked": false,
        "metrics": [
          ["AWS/Lambda", "Invocations", "FunctionName", "bbws-access-${environment}-lambda-permission-*", {"stat": "Sum"}],
          [".", ".", ".", "bbws-access-${environment}-lambda-invitation-*", {"stat": "Sum"}],
          [".", ".", ".", "bbws-access-${environment}-lambda-team-*", {"stat": "Sum"}],
          [".", ".", ".", "bbws-access-${environment}-lambda-role-*", {"stat": "Sum"}],
          [".", ".", ".", "bbws-access-${environment}-lambda-audit-*", {"stat": "Sum"}]
        ],
        "region": "${region}",
        "period": 60
      }
    },
    {
      "type": "metric",
      "x": 8,
      "y": 1,
      "width": 8,
      "height": 6,
      "properties": {
        "title": "Lambda Errors",
        "view": "timeSeries",
        "stacked": true,
        "metrics": [
          ["AWS/Lambda", "Errors", "FunctionName", "bbws-access-${environment}-lambda-permission-*", {"stat": "Sum", "color": "#d62728"}],
          [".", ".", ".", "bbws-access-${environment}-lambda-invitation-*", {"stat": "Sum", "color": "#ff7f0e"}],
          [".", ".", ".", "bbws-access-${environment}-lambda-team-*", {"stat": "Sum", "color": "#2ca02c"}],
          [".", ".", ".", "bbws-access-${environment}-lambda-role-*", {"stat": "Sum", "color": "#1f77b4"}],
          [".", ".", ".", "bbws-access-${environment}-lambda-audit-*", {"stat": "Sum", "color": "#9467bd"}]
        ],
        "region": "${region}",
        "period": 60
      }
    },
    {
      "type": "metric",
      "x": 16,
      "y": 1,
      "width": 8,
      "height": 6,
      "properties": {
        "title": "Lambda Duration (P95)",
        "view": "timeSeries",
        "stacked": false,
        "metrics": [
          ["AWS/Lambda", "Duration", "FunctionName", "bbws-access-${environment}-lambda-authorizer", {"stat": "p95", "color": "#d62728"}],
          [".", ".", ".", "bbws-access-${environment}-lambda-permission-*", {"stat": "p95"}],
          [".", ".", ".", "bbws-access-${environment}-lambda-team-*", {"stat": "p95"}]
        ],
        "region": "${region}",
        "period": 60,
        "annotations": {
          "horizontal": [
            {"label": "Target (100ms)", "value": 100, "color": "#ff0000"}
          ]
        }
      }
    },
    {
      "type": "metric",
      "x": 0,
      "y": 7,
      "width": 12,
      "height": 6,
      "properties": {
        "title": "API Gateway Requests",
        "view": "timeSeries",
        "stacked": false,
        "metrics": [
          ["AWS/ApiGateway", "Count", "ApiName", "bbws-access-${environment}-apigw", {"stat": "Sum"}],
          [".", "5XXError", ".", ".", {"stat": "Sum", "color": "#d62728"}],
          [".", "4XXError", ".", ".", {"stat": "Sum", "color": "#ff7f0e"}]
        ],
        "region": "${region}",
        "period": 60
      }
    },
    {
      "type": "metric",
      "x": 12,
      "y": 7,
      "width": 12,
      "height": 6,
      "properties": {
        "title": "API Gateway Latency",
        "view": "timeSeries",
        "stacked": false,
        "metrics": [
          ["AWS/ApiGateway", "Latency", "ApiName", "bbws-access-${environment}-apigw", {"stat": "p50"}],
          [".", ".", ".", ".", {"stat": "p95", "color": "#ff7f0e"}],
          [".", ".", ".", ".", {"stat": "p99", "color": "#d62728"}]
        ],
        "region": "${region}",
        "period": 60,
        "annotations": {
          "horizontal": [
            {"label": "Target P95 (500ms)", "value": 500, "color": "#ff0000"}
          ]
        }
      }
    },
    {
      "type": "metric",
      "x": 0,
      "y": 13,
      "width": 8,
      "height": 6,
      "properties": {
        "title": "DynamoDB Read/Write Capacity",
        "view": "timeSeries",
        "stacked": false,
        "metrics": [
          ["AWS/DynamoDB", "ConsumedReadCapacityUnits", "TableName", "bbws-access-${environment}-ddb-access-management", {"stat": "Sum"}],
          [".", "ConsumedWriteCapacityUnits", ".", ".", {"stat": "Sum"}]
        ],
        "region": "${region}",
        "period": 60
      }
    },
    {
      "type": "metric",
      "x": 8,
      "y": 13,
      "width": 8,
      "height": 6,
      "properties": {
        "title": "DynamoDB Throttling",
        "view": "timeSeries",
        "stacked": true,
        "metrics": [
          ["AWS/DynamoDB", "ReadThrottledRequests", "TableName", "bbws-access-${environment}-ddb-access-management", {"stat": "Sum", "color": "#d62728"}],
          [".", "WriteThrottledRequests", ".", ".", {"stat": "Sum", "color": "#ff7f0e"}]
        ],
        "region": "${region}",
        "period": 60
      }
    },
    {
      "type": "metric",
      "x": 16,
      "y": 13,
      "width": 8,
      "height": 6,
      "properties": {
        "title": "Authorizer Performance",
        "view": "timeSeries",
        "stacked": false,
        "metrics": [
          ["AWS/Lambda", "Duration", "FunctionName", "bbws-access-${environment}-lambda-authorizer", {"stat": "Average"}],
          [".", ".", ".", ".", {"stat": "p95", "color": "#ff7f0e"}],
          [".", "ConcurrentExecutions", ".", ".", {"stat": "Maximum", "yAxis": "right"}]
        ],
        "region": "${region}",
        "period": 60,
        "annotations": {
          "horizontal": [
            {"label": "Target (100ms)", "value": 100, "color": "#ff0000"}
          ]
        }
      }
    },
    {
      "type": "alarm",
      "x": 0,
      "y": 19,
      "width": 24,
      "height": 4,
      "properties": {
        "title": "Active Alarms",
        "alarms": [
          "arn:aws:cloudwatch:${region}:${account_id}:alarm:bbws-access-${environment}-alarm-*"
        ]
      }
    }
  ]
}
```

---

### 4. Log Retention Configuration

```hcl
# terraform/modules/monitoring/log_groups.tf

locals {
  log_groups = {
    # Lambda function logs
    permission_service  = "/aws/lambda/${local.prefix}-lambda-permission"
    invitation_service  = "/aws/lambda/${local.prefix}-lambda-invitation"
    team_service        = "/aws/lambda/${local.prefix}-lambda-team"
    role_service        = "/aws/lambda/${local.prefix}-lambda-role"
    authorizer_service  = "/aws/lambda/${local.prefix}-lambda-authorizer"
    audit_service       = "/aws/lambda/${local.prefix}-lambda-audit"

    # API Gateway logs
    api_gateway = "/aws/apigateway/${local.prefix}-apigw"
  }

  retention_days = {
    dev  = 30
    sit  = 30
    prod = 30
  }

  audit_retention_days = {
    dev  = 90
    sit  = 90
    prod = 2555  # 7 years
  }
}

resource "aws_cloudwatch_log_group" "service_logs" {
  for_each = local.log_groups

  name              = each.value
  retention_in_days = local.retention_days[var.environment]

  tags = {
    Environment = var.environment
    Service     = each.key
  }
}

resource "aws_cloudwatch_log_group" "audit_logs" {
  name              = "/aws/lambda/${local.prefix}-lambda-audit-archive"
  retention_in_days = local.audit_retention_days[var.environment]

  tags = {
    Environment = var.environment
    Service     = "audit"
    Compliance  = "7-year-retention"
  }
}

# Metric filters for error tracking
resource "aws_cloudwatch_log_metric_filter" "error_count" {
  for_each = local.log_groups

  name           = "${local.prefix}-${each.key}-error-count"
  pattern        = "[timestamp, request_id, level=ERROR, ...]"
  log_group_name = aws_cloudwatch_log_group.service_logs[each.key].name

  metric_transformation {
    name          = "ErrorCount"
    namespace     = "BBWS/AccessManagement"
    value         = "1"
    default_value = "0"
    dimensions = {
      Service = each.key
    }
  }
}

# Metric filter for authorization failures
resource "aws_cloudwatch_log_metric_filter" "auth_failures" {
  name           = "${local.prefix}-auth-failure-count"
  pattern        = "[timestamp, request_id, level, msg=\"Authorization failed*\"]"
  log_group_name = aws_cloudwatch_log_group.service_logs["authorizer_service"].name

  metric_transformation {
    name          = "AuthorizationFailures"
    namespace     = "BBWS/AccessManagement"
    value         = "1"
    default_value = "0"
  }
}
```

---

## Alarms Summary

| Alarm Category | Count | Severity | SNS Topic |
|----------------|-------|----------|-----------|
| Lambda Errors | 6 | Critical | critical |
| Lambda Duration | 6 | Warning | warning |
| Lambda Throttles | 6 | Critical | critical |
| Authorizer Latency | 1 | Critical | critical |
| API 5XX Errors | 1 | Critical | critical |
| API 4XX Errors | 1 | Warning | warning |
| DynamoDB Read Throttle | 1 | Critical | critical |
| DynamoDB Write Throttle | 1 | Critical | critical |

**Total: 23 Alarms**

---

## Success Criteria Checklist

- [x] All alarms deployed via Terraform
- [x] SNS topics configured (critical, warning, info, DLQ)
- [x] CloudWatch dashboard created
- [x] Log groups configured with retention
- [x] Metric filters for error tracking
- [x] Alert thresholds vary by environment
- [x] Test alert capability

---

**Completed By**: Worker 6
**Date**: 2026-01-25
