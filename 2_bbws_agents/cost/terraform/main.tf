/**
 * Automated Cost Reporting Infrastructure
 *
 * This Terraform configuration deploys:
 * - Lambda function for cost report generation
 * - SNS topic for email notifications
 * - EventBridge rules for daily/weekly scheduling
 * - IAM roles and permissions
 * - CloudWatch Log Groups
 */

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend configuration - uncomment and configure for remote state
  # backend "s3" {
  #   bucket = "bbws-terraform-state-${var.environment}"
  #   key    = "cost-reporting/terraform.tfstate"
  #   region = "eu-west-1"
  # }

  # Using local backend with environment-specific state files
  backend "local" {}
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "BBWS"
      Component   = "CostReporting"
      ManagedBy   = "Terraform"
      Environment = var.environment
    }
  }
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}

# Data source for AWS region
data "aws_region" "current" {}

##############################################################################
# SNS Topic for Email Notifications
##############################################################################

resource "aws_sns_topic" "cost_report" {
  name              = "bbws-cost-report-${var.environment}"
  display_name      = "BBWS Cost Report Notifications"
  kms_master_key_id = "alias/aws/sns"

  tags = {
    Name = "bbws-cost-report-${var.environment}"
  }
}

resource "aws_sns_topic_policy" "cost_report" {
  arn = aws_sns_topic.cost_report.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.cost_report.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

# Email subscriptions
resource "aws_sns_topic_subscription" "cost_report_email" {
  for_each = toset(var.notification_emails)

  topic_arn = aws_sns_topic.cost_report.arn
  protocol  = "email"
  endpoint  = each.value
}

##############################################################################
# Lambda Function for Cost Reporting
##############################################################################

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "cost_reporter" {
  name              = "/aws/lambda/${local.lambda_function_name}"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "cost-reporter-logs-${var.environment}"
  }
}

# IAM Role for Lambda
resource "aws_iam_role" "cost_reporter" {
  name = "bbws-cost-reporter-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "bbws-cost-reporter-${var.environment}"
  }
}

# IAM Policy for Lambda
resource "aws_iam_role_policy" "cost_reporter" {
  name = "cost-reporter-policy"
  role = aws_iam_role.cost_reporter.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ce:GetCostAndUsage",
          "ce:GetCostForecast",
          "ce:GetDimensionValues"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.cost_report.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.cost_reporter.arn}:*"
      }
    ]
  })
}

# Cross-account assume role policy (if needed)
resource "aws_iam_role_policy" "cost_reporter_cross_account" {
  count = length(var.cross_account_role_arns) > 0 ? 1 : 0

  name = "cost-reporter-cross-account"
  role = aws_iam_role.cost_reporter.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "sts:AssumeRole"
        Resource = var.cross_account_role_arns
      }
    ]
  })
}

# Package Lambda function
data "archive_file" "cost_reporter" {
  type        = "zip"
  source_file = "${path.module}/../lambda_cost_reporter.py"
  output_path = "${path.module}/lambda_cost_reporter.zip"
}

# Lambda Function
resource "aws_lambda_function" "cost_reporter" {
  filename         = data.archive_file.cost_reporter.output_path
  function_name    = local.lambda_function_name
  role            = aws_iam_role.cost_reporter.arn
  handler         = "lambda_cost_reporter.lambda_handler"
  source_code_hash = data.archive_file.cost_reporter.output_base64sha256
  runtime         = "python3.11"
  timeout         = 300
  memory_size     = 256

  environment {
    variables = {
      SNS_TOPIC_ARN           = aws_sns_topic.cost_report.arn
      REPORT_TYPE             = var.report_type
      DEV_ACCOUNT_ROLE_ARN    = var.dev_account_role_arn
      SIT_ACCOUNT_ROLE_ARN    = var.sit_account_role_arn
      PROD_ACCOUNT_ROLE_ARN   = var.prod_account_role_arn
    }
  }

  tags = {
    Name = local.lambda_function_name
  }
}

##############################################################################
# EventBridge Rules for Scheduling
##############################################################################

# Monthly Report Schedule (1st of month at 8 AM UTC = 10 AM CAT)
resource "aws_cloudwatch_event_rule" "monthly_cost_report" {
  count = var.enable_monthly_report ? 1 : 0

  name                = "bbws-monthly-cost-report-${var.environment}"
  description         = "Trigger monthly cost report generation"
  schedule_expression = "cron(0 8 1 * ? *)"  # 1st of month at 8 AM UTC

  tags = {
    Name = "monthly-cost-report-${var.environment}"
  }
}

resource "aws_cloudwatch_event_target" "monthly_cost_report" {
  count = var.enable_monthly_report ? 1 : 0

  rule      = aws_cloudwatch_event_rule.monthly_cost_report[0].name
  target_id = "MonthlyCostReportLambda"
  arn       = aws_lambda_function.cost_reporter.arn

  input = jsonencode({
    report_type = "monthly"
  })
}

resource "aws_lambda_permission" "allow_eventbridge_monthly" {
  count = var.enable_monthly_report ? 1 : 0

  statement_id  = "AllowExecutionFromEventBridgeMonthly"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cost_reporter.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.monthly_cost_report[0].arn
}

# Weekly Report Schedule (Mondays at 8 AM UTC = 10 AM CAT)
resource "aws_cloudwatch_event_rule" "weekly_cost_report" {
  count = var.enable_weekly_report ? 1 : 0

  name                = "bbws-weekly-cost-report-${var.environment}"
  description         = "Trigger weekly cost report generation"
  schedule_expression = "cron(0 8 ? * MON *)"  # Every Monday at 8 AM UTC

  tags = {
    Name = "weekly-cost-report-${var.environment}"
  }
}

resource "aws_cloudwatch_event_target" "weekly_cost_report" {
  count = var.enable_weekly_report ? 1 : 0

  rule      = aws_cloudwatch_event_rule.weekly_cost_report[0].name
  target_id = "WeeklyCostReportLambda"
  arn       = aws_lambda_function.cost_reporter.arn

  input = jsonencode({
    report_type = "weekly"
  })
}

resource "aws_lambda_permission" "allow_eventbridge_weekly" {
  count = var.enable_weekly_report ? 1 : 0

  statement_id  = "AllowExecutionFromEventBridgeWeekly"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cost_reporter.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.weekly_cost_report[0].arn
}

##############################################################################
# CloudWatch Alarms for Monitoring
##############################################################################

# Lambda Error Alarm
resource "aws_cloudwatch_metric_alarm" "cost_reporter_errors" {
  alarm_name          = "cost-reporter-errors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alert when cost reporter Lambda encounters errors"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.cost_reporter.function_name
  }

  alarm_actions = [aws_sns_topic.cost_report.arn]

  tags = {
    Name = "cost-reporter-errors-${var.environment}"
  }
}

##############################################################################
# Local Variables
##############################################################################

locals {
  lambda_function_name = "bbws-cost-reporter-${var.environment}"
}
