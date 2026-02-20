# CloudWatch Monitoring Module - Terraform Implementation

**Worker ID**: worker-6-cloudwatch-monitoring-module
**Stage**: Stage 2 - Infrastructure Terraform
**Project**: project-plan-2-access-management
**Created**: 2026-01-23
**Status**: COMPLETE

---

## Executive Summary

This document provides a comprehensive Terraform module for CloudWatch monitoring of the BBWS Access Management system. The module includes log groups for all 6 services (with appropriate retention periods), critical alarms for error tracking, SNS topics for alerting, custom metric filters for error tracking, and a unified dashboard for observability.

---

## Module Structure

```
terraform/modules/cloudwatch-monitoring/
├── main.tf           # Log groups for all 6 services
├── alarms.tf         # Alarm definitions
├── dashboards.tf     # Dashboard JSON
├── sns.tf            # Alert topics
├── metrics.tf        # Custom metric filters
├── variables.tf      # Input variables
└── outputs.tf        # Output values
```

---

## 1. variables.tf - Input Variables

```hcl
###############################################################################
# CloudWatch Monitoring Module - Variables
# BBWS Access Management System
###############################################################################

variable "environment" {
  description = "Deployment environment (dev, sit, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "sit", "prod"], var.environment)
    error_message = "Environment must be one of: dev, sit, prod."
  }
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "bbws-access"
}

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
}

variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
}

# Lambda function names (passed from Lambda module)
variable "lambda_permission_service_name" {
  description = "Name of the Permission Service Lambda function"
  type        = string
  default     = ""
}

variable "lambda_invitation_service_name" {
  description = "Name of the Invitation Service Lambda function"
  type        = string
  default     = ""
}

variable "lambda_team_service_name" {
  description = "Name of the Team Service Lambda function"
  type        = string
  default     = ""
}

variable "lambda_role_service_name" {
  description = "Name of the Role Service Lambda function"
  type        = string
  default     = ""
}

variable "lambda_authorizer_name" {
  description = "Name of the Authorizer Lambda function"
  type        = string
  default     = ""
}

variable "lambda_audit_service_name" {
  description = "Name of the Audit Service Lambda function"
  type        = string
  default     = ""
}

# DynamoDB table name
variable "dynamodb_table_name" {
  description = "Name of the Access Management DynamoDB table"
  type        = string
  default     = ""
}

# Alert configuration
variable "alert_email_endpoints" {
  description = "List of email addresses for critical alerts"
  type        = list(string)
  default     = []
}

variable "warning_email_endpoints" {
  description = "List of email addresses for warning alerts"
  type        = list(string)
  default     = []
}

# Alarm thresholds (configurable per environment)
variable "authorizer_error_threshold" {
  description = "Threshold for Authorizer error count per minute"
  type        = number
  default     = 10
}

variable "authorizer_latency_threshold_ms" {
  description = "Threshold for Authorizer p95 latency in milliseconds"
  type        = number
  default     = 100
}

variable "invitation_failure_threshold" {
  description = "Threshold for Invitation failures per minute"
  type        = number
  default     = 5
}

variable "audit_archive_failure_threshold" {
  description = "Threshold for Audit archive failures per hour"
  type        = number
  default     = 1
}

variable "lambda_concurrent_execution_threshold_percent" {
  description = "Lambda concurrent execution alarm threshold (percentage of limit)"
  type        = number
  default     = 80
}

variable "lambda_concurrent_execution_limit" {
  description = "Lambda concurrent execution limit for the account"
  type        = number
  default     = 1000
}

# Log retention periods (days)
variable "standard_log_retention_days" {
  description = "Standard log retention in days for most services"
  type        = number
  default     = 30
}

variable "audit_log_retention_days" {
  description = "Audit log retention in days (compliance requirement)"
  type        = number
  default     = 90
}

# Feature flags
variable "enable_dashboard" {
  description = "Enable CloudWatch dashboard creation"
  type        = bool
  default     = true
}

variable "enable_alarms" {
  description = "Enable CloudWatch alarms"
  type        = bool
  default     = true
}

variable "enable_sns_notifications" {
  description = "Enable SNS notifications for alarms"
  type        = bool
  default     = true
}

# Tags
variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}

# Local computed values
locals {
  # Service names for log groups
  services = {
    permission_service  = "permission-service"
    invitation_service  = "invitation-service"
    team_service        = "team-service"
    role_service        = "role-service"
    authorizer          = "authorizer"
    audit_service       = "audit-service"
  }

  # Common prefix for naming
  name_prefix = "${var.project_name}-${var.environment}"

  # Common tags
  common_tags = merge(var.tags, {
    Project     = "BBWS"
    Component   = "AccessManagement"
    Module      = "CloudWatchMonitoring"
    Environment = var.environment
    ManagedBy   = "Terraform"
  })
}
```

---

## 2. main.tf - Log Groups

```hcl
###############################################################################
# CloudWatch Monitoring Module - Log Groups
# BBWS Access Management System
###############################################################################

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

###############################################################################
# CloudWatch Log Groups - All 6 Services
###############################################################################

# Permission Service Log Group - 30 days retention
resource "aws_cloudwatch_log_group" "permission_service" {
  name              = "/aws/lambda/${local.name_prefix}-${local.services.permission_service}"
  retention_in_days = var.standard_log_retention_days

  tags = merge(local.common_tags, {
    Service = "PermissionService"
  })
}

# Invitation Service Log Group - 30 days retention
resource "aws_cloudwatch_log_group" "invitation_service" {
  name              = "/aws/lambda/${local.name_prefix}-${local.services.invitation_service}"
  retention_in_days = var.standard_log_retention_days

  tags = merge(local.common_tags, {
    Service = "InvitationService"
  })
}

# Team Service Log Group - 30 days retention
resource "aws_cloudwatch_log_group" "team_service" {
  name              = "/aws/lambda/${local.name_prefix}-${local.services.team_service}"
  retention_in_days = var.standard_log_retention_days

  tags = merge(local.common_tags, {
    Service = "TeamService"
  })
}

# Role Service Log Group - 30 days retention
resource "aws_cloudwatch_log_group" "role_service" {
  name              = "/aws/lambda/${local.name_prefix}-${local.services.role_service}"
  retention_in_days = var.standard_log_retention_days

  tags = merge(local.common_tags, {
    Service = "RoleService"
  })
}

# Authorizer Service Log Group - 30 days retention
resource "aws_cloudwatch_log_group" "authorizer" {
  name              = "/aws/lambda/${local.name_prefix}-${local.services.authorizer}"
  retention_in_days = var.standard_log_retention_days

  tags = merge(local.common_tags, {
    Service = "AuthorizerService"
  })
}

# Audit Service Log Group - 90 days retention (compliance requirement)
resource "aws_cloudwatch_log_group" "audit_service" {
  name              = "/aws/lambda/${local.name_prefix}-${local.services.audit_service}"
  retention_in_days = var.audit_log_retention_days

  tags = merge(local.common_tags, {
    Service     = "AuditService"
    Compliance  = "true"
    RetentionReason = "AuditCompliance"
  })
}

###############################################################################
# API Gateway Access Log Group
###############################################################################

resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/api-gateway/${local.name_prefix}-access-logs"
  retention_in_days = var.standard_log_retention_days

  tags = merge(local.common_tags, {
    Service = "APIGateway"
  })
}

###############################################################################
# Dead Letter Queue Log Group (for failed Lambda executions)
###############################################################################

resource "aws_cloudwatch_log_group" "dlq_processor" {
  name              = "/aws/lambda/${local.name_prefix}-dlq-processor"
  retention_in_days = var.audit_log_retention_days

  tags = merge(local.common_tags, {
    Service = "DLQProcessor"
    Purpose = "FailedTransactionTracking"
  })
}
```

---

## 3. sns.tf - SNS Topics for Alerts

```hcl
###############################################################################
# CloudWatch Monitoring Module - SNS Topics
# BBWS Access Management System
###############################################################################

###############################################################################
# Critical Alerts SNS Topic
###############################################################################

resource "aws_sns_topic" "alerts_critical" {
  count = var.enable_sns_notifications ? 1 : 0

  name         = "${local.name_prefix}-alerts-critical"
  display_name = "BBWS Access Management Critical Alerts (${upper(var.environment)})"

  # Enable server-side encryption
  kms_master_key_id = "alias/aws/sns"

  tags = merge(local.common_tags, {
    AlertLevel = "Critical"
  })
}

# Critical alerts email subscriptions
resource "aws_sns_topic_subscription" "critical_email" {
  count = var.enable_sns_notifications ? length(var.alert_email_endpoints) : 0

  topic_arn = aws_sns_topic.alerts_critical[0].arn
  protocol  = "email"
  endpoint  = var.alert_email_endpoints[count.index]
}

# SNS Topic Policy for Critical Alerts
resource "aws_sns_topic_policy" "alerts_critical" {
  count = var.enable_sns_notifications ? 1 : 0

  arn = aws_sns_topic.alerts_critical[0].arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudWatchAlarms"
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.alerts_critical[0].arn
        Condition = {
          ArnLike = {
            "aws:SourceArn" = "arn:aws:cloudwatch:${var.aws_region}:${var.aws_account_id}:alarm:*"
          }
        }
      },
      {
        Sid    = "AllowAccountAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.aws_account_id}:root"
        }
        Action = [
          "sns:GetTopicAttributes",
          "sns:SetTopicAttributes",
          "sns:AddPermission",
          "sns:RemovePermission",
          "sns:DeleteTopic",
          "sns:Subscribe",
          "sns:ListSubscriptionsByTopic",
          "sns:Publish"
        ]
        Resource = aws_sns_topic.alerts_critical[0].arn
      }
    ]
  })
}

###############################################################################
# Warning Alerts SNS Topic
###############################################################################

resource "aws_sns_topic" "alerts_warning" {
  count = var.enable_sns_notifications ? 1 : 0

  name         = "${local.name_prefix}-alerts-warning"
  display_name = "BBWS Access Management Warning Alerts (${upper(var.environment)})"

  # Enable server-side encryption
  kms_master_key_id = "alias/aws/sns"

  tags = merge(local.common_tags, {
    AlertLevel = "Warning"
  })
}

# Warning alerts email subscriptions
resource "aws_sns_topic_subscription" "warning_email" {
  count = var.enable_sns_notifications ? length(var.warning_email_endpoints) : 0

  topic_arn = aws_sns_topic.alerts_warning[0].arn
  protocol  = "email"
  endpoint  = var.warning_email_endpoints[count.index]
}

# SNS Topic Policy for Warning Alerts
resource "aws_sns_topic_policy" "alerts_warning" {
  count = var.enable_sns_notifications ? 1 : 0

  arn = aws_sns_topic.alerts_warning[0].arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudWatchAlarms"
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.alerts_warning[0].arn
        Condition = {
          ArnLike = {
            "aws:SourceArn" = "arn:aws:cloudwatch:${var.aws_region}:${var.aws_account_id}:alarm:*"
          }
        }
      },
      {
        Sid    = "AllowAccountAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.aws_account_id}:root"
        }
        Action = [
          "sns:GetTopicAttributes",
          "sns:SetTopicAttributes",
          "sns:AddPermission",
          "sns:RemovePermission",
          "sns:DeleteTopic",
          "sns:Subscribe",
          "sns:ListSubscriptionsByTopic",
          "sns:Publish"
        ]
        Resource = aws_sns_topic.alerts_warning[0].arn
      }
    ]
  })
}

###############################################################################
# Dead Letter Queue Alerts SNS Topic
###############################################################################

resource "aws_sns_topic" "dlq_alerts" {
  count = var.enable_sns_notifications ? 1 : 0

  name         = "${local.name_prefix}-dlq-alerts"
  display_name = "BBWS Access Management DLQ Alerts (${upper(var.environment)})"

  kms_master_key_id = "alias/aws/sns"

  tags = merge(local.common_tags, {
    AlertLevel = "Critical"
    Purpose    = "DeadLetterQueue"
  })
}

# DLQ alerts inherit critical email subscriptions
resource "aws_sns_topic_subscription" "dlq_email" {
  count = var.enable_sns_notifications ? length(var.alert_email_endpoints) : 0

  topic_arn = aws_sns_topic.dlq_alerts[0].arn
  protocol  = "email"
  endpoint  = var.alert_email_endpoints[count.index]
}

# SNS Topic Policy for DLQ Alerts
resource "aws_sns_topic_policy" "dlq_alerts" {
  count = var.enable_sns_notifications ? 1 : 0

  arn = aws_sns_topic.dlq_alerts[0].arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudWatchAlarms"
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.dlq_alerts[0].arn
        Condition = {
          ArnLike = {
            "aws:SourceArn" = "arn:aws:cloudwatch:${var.aws_region}:${var.aws_account_id}:alarm:*"
          }
        }
      },
      {
        Sid    = "AllowAccountAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.aws_account_id}:root"
        }
        Action = [
          "sns:GetTopicAttributes",
          "sns:SetTopicAttributes",
          "sns:AddPermission",
          "sns:RemovePermission",
          "sns:DeleteTopic",
          "sns:Subscribe",
          "sns:ListSubscriptionsByTopic",
          "sns:Publish"
        ]
        Resource = aws_sns_topic.dlq_alerts[0].arn
      }
    ]
  })
}
```

---

## 4. alarms.tf - CloudWatch Alarms

```hcl
###############################################################################
# CloudWatch Monitoring Module - Alarms
# BBWS Access Management System
###############################################################################

###############################################################################
# CRITICAL ALARMS
###############################################################################

# Authorizer Errors Alarm (> 10/min)
resource "aws_cloudwatch_metric_alarm" "authorizer_errors" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "${local.name_prefix}-authorizer-errors"
  alarm_description   = "CRITICAL: Authorizer Lambda errors exceeded threshold. This may indicate authentication/authorization failures affecting all API access."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = var.authorizer_error_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = "${local.name_prefix}-${local.services.authorizer}"
  }

  alarm_actions = var.enable_sns_notifications ? [aws_sns_topic.alerts_critical[0].arn] : []
  ok_actions    = var.enable_sns_notifications ? [aws_sns_topic.alerts_critical[0].arn] : []

  tags = merge(local.common_tags, {
    Service    = "Authorizer"
    AlertLevel = "Critical"
  })
}

# Authorizer Latency Alarm (> 100ms p95)
resource "aws_cloudwatch_metric_alarm" "authorizer_latency" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "${local.name_prefix}-authorizer-latency"
  alarm_description   = "CRITICAL: Authorizer Lambda p95 latency exceeded ${var.authorizer_latency_threshold_ms}ms. This affects API response times for all authenticated requests."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  threshold           = var.authorizer_latency_threshold_ms
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "p95_latency"
    return_data = true

    metric {
      metric_name = "Duration"
      namespace   = "AWS/Lambda"
      period      = 60
      stat        = "p95"

      dimensions = {
        FunctionName = "${local.name_prefix}-${local.services.authorizer}"
      }
    }
  }

  alarm_actions = var.enable_sns_notifications ? [aws_sns_topic.alerts_critical[0].arn] : []
  ok_actions    = var.enable_sns_notifications ? [aws_sns_topic.alerts_critical[0].arn] : []

  tags = merge(local.common_tags, {
    Service    = "Authorizer"
    AlertLevel = "Critical"
  })
}

# DynamoDB Throttling Alarm (> 0 throttled requests)
resource "aws_cloudwatch_metric_alarm" "dynamodb_throttling" {
  count = var.enable_alarms && var.dynamodb_table_name != "" ? 1 : 0

  alarm_name          = "${local.name_prefix}-dynamodb-throttling"
  alarm_description   = "CRITICAL: DynamoDB requests are being throttled. This indicates capacity issues that may cause request failures."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ThrottledRequests"
  namespace           = "AWS/DynamoDB"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    TableName = var.dynamodb_table_name
  }

  alarm_actions = var.enable_sns_notifications ? [aws_sns_topic.alerts_critical[0].arn] : []
  ok_actions    = var.enable_sns_notifications ? [aws_sns_topic.alerts_critical[0].arn] : []

  tags = merge(local.common_tags, {
    Service    = "DynamoDB"
    AlertLevel = "Critical"
  })
}

# Invitation Failures Alarm (> 5/min)
resource "aws_cloudwatch_metric_alarm" "invitation_failures" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "${local.name_prefix}-invitation-failures"
  alarm_description   = "CRITICAL: Invitation Service errors exceeded threshold. Users may not receive invitations."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = var.invitation_failure_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = "${local.name_prefix}-${local.services.invitation_service}"
  }

  alarm_actions = var.enable_sns_notifications ? [aws_sns_topic.alerts_critical[0].arn] : []
  ok_actions    = var.enable_sns_notifications ? [aws_sns_topic.alerts_critical[0].arn] : []

  tags = merge(local.common_tags, {
    Service    = "InvitationService"
    AlertLevel = "Critical"
  })
}

# Audit Archive Failures Alarm (> 1/hour)
resource "aws_cloudwatch_metric_alarm" "audit_archive_failures" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "${local.name_prefix}-audit-archive-failures"
  alarm_description   = "CRITICAL: Audit archive failures detected. This may cause compliance issues with audit log retention."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "AuditArchiveFailures"
  namespace           = "BBWS/AccessManagement"
  period              = 3600
  statistic           = "Sum"
  threshold           = var.audit_archive_failure_threshold
  treat_missing_data  = "notBreaching"

  alarm_actions = var.enable_sns_notifications ? [aws_sns_topic.alerts_critical[0].arn] : []
  ok_actions    = var.enable_sns_notifications ? [aws_sns_topic.alerts_critical[0].arn] : []

  tags = merge(local.common_tags, {
    Service    = "AuditService"
    AlertLevel = "Critical"
  })
}

###############################################################################
# WARNING ALARMS
###############################################################################

# Lambda Concurrent Executions Warning (> 80% of limit)
resource "aws_cloudwatch_metric_alarm" "lambda_concurrency" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "${local.name_prefix}-lambda-concurrency-warning"
  alarm_description   = "WARNING: Lambda concurrent executions approaching account limit (${var.lambda_concurrent_execution_threshold_percent}%). Consider increasing limits or optimizing."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "ConcurrentExecutions"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Maximum"
  threshold           = var.lambda_concurrent_execution_limit * (var.lambda_concurrent_execution_threshold_percent / 100)
  treat_missing_data  = "notBreaching"

  alarm_actions = var.enable_sns_notifications ? [aws_sns_topic.alerts_warning[0].arn] : []
  ok_actions    = var.enable_sns_notifications ? [aws_sns_topic.alerts_warning[0].arn] : []

  tags = merge(local.common_tags, {
    Service    = "Lambda"
    AlertLevel = "Warning"
  })
}

# Permission Service Errors Warning
resource "aws_cloudwatch_metric_alarm" "permission_service_errors" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "${local.name_prefix}-permission-service-errors"
  alarm_description   = "WARNING: Permission Service errors detected. Users may experience issues managing permissions."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = 5
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = "${local.name_prefix}-${local.services.permission_service}"
  }

  alarm_actions = var.enable_sns_notifications ? [aws_sns_topic.alerts_warning[0].arn] : []
  ok_actions    = var.enable_sns_notifications ? [aws_sns_topic.alerts_warning[0].arn] : []

  tags = merge(local.common_tags, {
    Service    = "PermissionService"
    AlertLevel = "Warning"
  })
}

# Team Service Errors Warning
resource "aws_cloudwatch_metric_alarm" "team_service_errors" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "${local.name_prefix}-team-service-errors"
  alarm_description   = "WARNING: Team Service errors detected. Users may experience issues with team management."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = 5
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = "${local.name_prefix}-${local.services.team_service}"
  }

  alarm_actions = var.enable_sns_notifications ? [aws_sns_topic.alerts_warning[0].arn] : []
  ok_actions    = var.enable_sns_notifications ? [aws_sns_topic.alerts_warning[0].arn] : []

  tags = merge(local.common_tags, {
    Service    = "TeamService"
    AlertLevel = "Warning"
  })
}

# Role Service Errors Warning
resource "aws_cloudwatch_metric_alarm" "role_service_errors" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "${local.name_prefix}-role-service-errors"
  alarm_description   = "WARNING: Role Service errors detected. Users may experience issues with role management."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = 5
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = "${local.name_prefix}-${local.services.role_service}"
  }

  alarm_actions = var.enable_sns_notifications ? [aws_sns_topic.alerts_warning[0].arn] : []
  ok_actions    = var.enable_sns_notifications ? [aws_sns_topic.alerts_warning[0].arn] : []

  tags = merge(local.common_tags, {
    Service    = "RoleService"
    AlertLevel = "Warning"
  })
}

# Audit Service Errors Warning
resource "aws_cloudwatch_metric_alarm" "audit_service_errors" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "${local.name_prefix}-audit-service-errors"
  alarm_description   = "WARNING: Audit Service errors detected. Audit events may not be properly recorded."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = 3
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = "${local.name_prefix}-${local.services.audit_service}"
  }

  alarm_actions = var.enable_sns_notifications ? [aws_sns_topic.alerts_warning[0].arn] : []
  ok_actions    = var.enable_sns_notifications ? [aws_sns_topic.alerts_warning[0].arn] : []

  tags = merge(local.common_tags, {
    Service    = "AuditService"
    AlertLevel = "Warning"
  })
}

###############################################################################
# DEAD LETTER QUEUE ALARMS
###############################################################################

# DLQ Messages Available Alarm
resource "aws_cloudwatch_metric_alarm" "dlq_messages" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "${local.name_prefix}-dlq-messages"
  alarm_description   = "CRITICAL: Messages in Dead Letter Queue detected. Failed transactions require investigation."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "DLQMessagesReceived"
  namespace           = "BBWS/AccessManagement"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  alarm_actions = var.enable_sns_notifications ? [aws_sns_topic.dlq_alerts[0].arn] : []
  ok_actions    = var.enable_sns_notifications ? [aws_sns_topic.dlq_alerts[0].arn] : []

  tags = merge(local.common_tags, {
    Service    = "DLQ"
    AlertLevel = "Critical"
  })
}

###############################################################################
# LATENCY ALARMS - All Services
###############################################################################

# Permission Service Latency Warning
resource "aws_cloudwatch_metric_alarm" "permission_service_latency" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "${local.name_prefix}-permission-service-latency"
  alarm_description   = "WARNING: Permission Service p95 latency exceeds 500ms."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  threshold           = 500
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "p95_latency"
    return_data = true

    metric {
      metric_name = "Duration"
      namespace   = "AWS/Lambda"
      period      = 60
      stat        = "p95"

      dimensions = {
        FunctionName = "${local.name_prefix}-${local.services.permission_service}"
      }
    }
  }

  alarm_actions = var.enable_sns_notifications ? [aws_sns_topic.alerts_warning[0].arn] : []
  ok_actions    = var.enable_sns_notifications ? [aws_sns_topic.alerts_warning[0].arn] : []

  tags = merge(local.common_tags, {
    Service    = "PermissionService"
    AlertLevel = "Warning"
  })
}

# Invitation Service Latency Warning
resource "aws_cloudwatch_metric_alarm" "invitation_service_latency" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "${local.name_prefix}-invitation-service-latency"
  alarm_description   = "WARNING: Invitation Service p95 latency exceeds 1000ms."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  threshold           = 1000
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "p95_latency"
    return_data = true

    metric {
      metric_name = "Duration"
      namespace   = "AWS/Lambda"
      period      = 60
      stat        = "p95"

      dimensions = {
        FunctionName = "${local.name_prefix}-${local.services.invitation_service}"
      }
    }
  }

  alarm_actions = var.enable_sns_notifications ? [aws_sns_topic.alerts_warning[0].arn] : []
  ok_actions    = var.enable_sns_notifications ? [aws_sns_topic.alerts_warning[0].arn] : []

  tags = merge(local.common_tags, {
    Service    = "InvitationService"
    AlertLevel = "Warning"
  })
}
```

---

## 5. metrics.tf - Custom Metric Filters

```hcl
###############################################################################
# CloudWatch Monitoring Module - Metric Filters
# BBWS Access Management System
###############################################################################

###############################################################################
# Authorizer Metric Filters
###############################################################################

# Authorization DENY responses
resource "aws_cloudwatch_log_metric_filter" "auth_deny" {
  name           = "${local.name_prefix}-auth-deny"
  log_group_name = aws_cloudwatch_log_group.authorizer.name
  pattern        = "{ $.decision = \"DENY\" || $.message = \"*DENY*\" || $.effect = \"Deny\" }"

  metric_transformation {
    name          = "AuthorizationDenied"
    namespace     = "BBWS/AccessManagement"
    value         = "1"
    default_value = "0"
    unit          = "Count"
    dimensions = {
      Service     = "Authorizer"
      Environment = var.environment
    }
  }
}

# Token validation failures
resource "aws_cloudwatch_log_metric_filter" "token_validation_failures" {
  name           = "${local.name_prefix}-token-validation-failures"
  log_group_name = aws_cloudwatch_log_group.authorizer.name
  pattern        = "{ $.error = \"TOKEN_*\" || $.message = \"*TOKEN_INVALID*\" || $.message = \"*TOKEN_EXPIRED*\" || $.message = \"*TOKEN_MISSING*\" }"

  metric_transformation {
    name          = "TokenValidationFailures"
    namespace     = "BBWS/AccessManagement"
    value         = "1"
    default_value = "0"
    unit          = "Count"
    dimensions = {
      Service     = "Authorizer"
      Environment = var.environment
    }
  }
}

# Permission denied errors
resource "aws_cloudwatch_log_metric_filter" "permission_denied" {
  name           = "${local.name_prefix}-permission-denied"
  log_group_name = aws_cloudwatch_log_group.authorizer.name
  pattern        = "{ $.reason = \"PERMISSION_DENIED\" || $.message = \"*PERMISSION_DENIED*\" }"

  metric_transformation {
    name          = "PermissionDenied"
    namespace     = "BBWS/AccessManagement"
    value         = "1"
    default_value = "0"
    unit          = "Count"
    dimensions = {
      Service     = "Authorizer"
      Environment = var.environment
    }
  }
}

# Organisation access denied
resource "aws_cloudwatch_log_metric_filter" "org_access_denied" {
  name           = "${local.name_prefix}-org-access-denied"
  log_group_name = aws_cloudwatch_log_group.authorizer.name
  pattern        = "{ $.reason = \"ORG_ACCESS_DENIED\" || $.message = \"*ORG_ACCESS_DENIED*\" }"

  metric_transformation {
    name          = "OrgAccessDenied"
    namespace     = "BBWS/AccessManagement"
    value         = "1"
    default_value = "0"
    unit          = "Count"
    dimensions = {
      Service     = "Authorizer"
      Environment = var.environment
    }
  }
}

###############################################################################
# Invitation Service Metric Filters
###############################################################################

# Invitation email failures
resource "aws_cloudwatch_log_metric_filter" "invitation_email_failures" {
  name           = "${local.name_prefix}-invitation-email-failures"
  log_group_name = aws_cloudwatch_log_group.invitation_service.name
  pattern        = "{ $.message = \"*SES*error*\" || $.message = \"*email*failed*\" || $.message = \"*EmailService*error*\" || $.level = \"ERROR\" && $.service = \"EmailService\" }"

  metric_transformation {
    name          = "InvitationEmailFailures"
    namespace     = "BBWS/AccessManagement"
    value         = "1"
    default_value = "0"
    unit          = "Count"
    dimensions = {
      Service     = "InvitationService"
      Environment = var.environment
    }
  }
}

# Invitations sent
resource "aws_cloudwatch_log_metric_filter" "invitations_sent" {
  name           = "${local.name_prefix}-invitations-sent"
  log_group_name = aws_cloudwatch_log_group.invitation_service.name
  pattern        = "{ $.action = \"INVITATION_CREATED\" || $.message = \"*invitation*sent*\" || $.event = \"invitation_created\" }"

  metric_transformation {
    name          = "InvitationsSent"
    namespace     = "BBWS/AccessManagement"
    value         = "1"
    default_value = "0"
    unit          = "Count"
    dimensions = {
      Service     = "InvitationService"
      Environment = var.environment
    }
  }
}

# Invitations accepted
resource "aws_cloudwatch_log_metric_filter" "invitations_accepted" {
  name           = "${local.name_prefix}-invitations-accepted"
  log_group_name = aws_cloudwatch_log_group.invitation_service.name
  pattern        = "{ $.action = \"INVITATION_ACCEPTED\" || $.message = \"*invitation*accepted*\" || $.event = \"invitation_accepted\" }"

  metric_transformation {
    name          = "InvitationsAccepted"
    namespace     = "BBWS/AccessManagement"
    value         = "1"
    default_value = "0"
    unit          = "Count"
    dimensions = {
      Service     = "InvitationService"
      Environment = var.environment
    }
  }
}

# Duplicate invitation attempts
resource "aws_cloudwatch_log_metric_filter" "duplicate_invitations" {
  name           = "${local.name_prefix}-duplicate-invitations"
  log_group_name = aws_cloudwatch_log_group.invitation_service.name
  pattern        = "{ $.error = \"DUPLICATE_INVITATION\" || $.message = \"*already*exists*\" }"

  metric_transformation {
    name          = "DuplicateInvitations"
    namespace     = "BBWS/AccessManagement"
    value         = "1"
    default_value = "0"
    unit          = "Count"
    dimensions = {
      Service     = "InvitationService"
      Environment = var.environment
    }
  }
}

###############################################################################
# Audit Service Metric Filters
###############################################################################

# Audit archive errors
resource "aws_cloudwatch_log_metric_filter" "audit_archive_errors" {
  name           = "${local.name_prefix}-audit-archive-errors"
  log_group_name = aws_cloudwatch_log_group.audit_service.name
  pattern        = "{ $.message = \"*archive*error*\" || $.message = \"*archive*failed*\" || $.message = \"*S3*upload*error*\" || $.level = \"ERROR\" && $.operation = \"archive\" }"

  metric_transformation {
    name          = "AuditArchiveFailures"
    namespace     = "BBWS/AccessManagement"
    value         = "1"
    default_value = "0"
    unit          = "Count"
    dimensions = {
      Service     = "AuditService"
      Environment = var.environment
    }
  }
}

# Audit events captured
resource "aws_cloudwatch_log_metric_filter" "audit_events_captured" {
  name           = "${local.name_prefix}-audit-events-captured"
  log_group_name = aws_cloudwatch_log_group.audit_service.name
  pattern        = "{ $.eventType = \"AUTHORIZATION\" || $.eventType = \"PERMISSION_CHANGE\" || $.eventType = \"USER_MANAGEMENT\" || $.eventType = \"TEAM_MEMBERSHIP\" || $.eventType = \"ROLE_CHANGE\" || $.eventType = \"INVITATION\" || $.eventType = \"CONFIGURATION\" }"

  metric_transformation {
    name          = "AuditEventsCaptured"
    namespace     = "BBWS/AccessManagement"
    value         = "1"
    default_value = "0"
    unit          = "Count"
    dimensions = {
      Service     = "AuditService"
      Environment = var.environment
    }
  }
}

# Audit export operations
resource "aws_cloudwatch_log_metric_filter" "audit_exports" {
  name           = "${local.name_prefix}-audit-exports"
  log_group_name = aws_cloudwatch_log_group.audit_service.name
  pattern        = "{ $.action = \"AUDIT_EXPORT\" || $.message = \"*export*completed*\" || $.event = \"audit_exported\" }"

  metric_transformation {
    name          = "AuditExports"
    namespace     = "BBWS/AccessManagement"
    value         = "1"
    default_value = "0"
    unit          = "Count"
    dimensions = {
      Service     = "AuditService"
      Environment = var.environment
    }
  }
}

###############################################################################
# Team Service Metric Filters
###############################################################################

# Team membership changes
resource "aws_cloudwatch_log_metric_filter" "team_membership_changes" {
  name           = "${local.name_prefix}-team-membership-changes"
  log_group_name = aws_cloudwatch_log_group.team_service.name
  pattern        = "{ $.action = \"MEMBER_ADDED\" || $.action = \"MEMBER_REMOVED\" || $.event = \"team_membership_changed\" }"

  metric_transformation {
    name          = "TeamMembershipChanges"
    namespace     = "BBWS/AccessManagement"
    value         = "1"
    default_value = "0"
    unit          = "Count"
    dimensions = {
      Service     = "TeamService"
      Environment = var.environment
    }
  }
}

# Cannot remove last lead errors
resource "aws_cloudwatch_log_metric_filter" "cannot_remove_last_lead" {
  name           = "${local.name_prefix}-cannot-remove-last-lead"
  log_group_name = aws_cloudwatch_log_group.team_service.name
  pattern        = "{ $.error = \"CannotRemoveLastLeadException\" || $.message = \"*last*lead*\" }"

  metric_transformation {
    name          = "CannotRemoveLastLeadAttempts"
    namespace     = "BBWS/AccessManagement"
    value         = "1"
    default_value = "0"
    unit          = "Count"
    dimensions = {
      Service     = "TeamService"
      Environment = var.environment
    }
  }
}

###############################################################################
# Role Service Metric Filters
###############################################################################

# Role permission changes
resource "aws_cloudwatch_log_metric_filter" "role_permission_changes" {
  name           = "${local.name_prefix}-role-permission-changes"
  log_group_name = aws_cloudwatch_log_group.role_service.name
  pattern        = "{ $.action = \"PERMISSIONS_ASSIGNED\" || $.action = \"ROLE_UPDATED\" || $.event = \"role_permissions_changed\" }"

  metric_transformation {
    name          = "RolePermissionChanges"
    namespace     = "BBWS/AccessManagement"
    value         = "1"
    default_value = "0"
    unit          = "Count"
    dimensions = {
      Service     = "RoleService"
      Environment = var.environment
    }
  }
}

# Role in use deletion attempts
resource "aws_cloudwatch_log_metric_filter" "role_in_use_deletion" {
  name           = "${local.name_prefix}-role-in-use-deletion"
  log_group_name = aws_cloudwatch_log_group.role_service.name
  pattern        = "{ $.error = \"RoleInUseException\" || $.message = \"*role*in*use*\" }"

  metric_transformation {
    name          = "RoleInUseDeletionAttempts"
    namespace     = "BBWS/AccessManagement"
    value         = "1"
    default_value = "0"
    unit          = "Count"
    dimensions = {
      Service     = "RoleService"
      Environment = var.environment
    }
  }
}

###############################################################################
# Permission Service Metric Filters
###############################################################################

# Permission set creations
resource "aws_cloudwatch_log_metric_filter" "permission_set_created" {
  name           = "${local.name_prefix}-permission-set-created"
  log_group_name = aws_cloudwatch_log_group.permission_service.name
  pattern        = "{ $.action = \"PERMISSION_SET_CREATED\" || $.event = \"permission_set_created\" }"

  metric_transformation {
    name          = "PermissionSetsCreated"
    namespace     = "BBWS/AccessManagement"
    value         = "1"
    default_value = "0"
    unit          = "Count"
    dimensions = {
      Service     = "PermissionService"
      Environment = var.environment
    }
  }
}

# Invalid permissions in request
resource "aws_cloudwatch_log_metric_filter" "invalid_permissions" {
  name           = "${local.name_prefix}-invalid-permissions"
  log_group_name = aws_cloudwatch_log_group.permission_service.name
  pattern        = "{ $.error = \"INVALID_PERMISSIONS\" || $.error = \"InvalidPermissionsException\" || $.message = \"*invalid*permission*\" }"

  metric_transformation {
    name          = "InvalidPermissionAttempts"
    namespace     = "BBWS/AccessManagement"
    value         = "1"
    default_value = "0"
    unit          = "Count"
    dimensions = {
      Service     = "PermissionService"
      Environment = var.environment
    }
  }
}

###############################################################################
# DLQ Metric Filters
###############################################################################

# Dead letter queue messages received
resource "aws_cloudwatch_log_metric_filter" "dlq_messages_received" {
  name           = "${local.name_prefix}-dlq-messages"
  log_group_name = aws_cloudwatch_log_group.dlq_processor.name
  pattern        = "{ $.source = \"DLQ\" || $.message = \"*DLQ*message*received*\" }"

  metric_transformation {
    name          = "DLQMessagesReceived"
    namespace     = "BBWS/AccessManagement"
    value         = "1"
    default_value = "0"
    unit          = "Count"
    dimensions = {
      Service     = "DLQ"
      Environment = var.environment
    }
  }
}

###############################################################################
# General Error Metric Filters
###############################################################################

# General ERROR level logs across all services
resource "aws_cloudwatch_log_metric_filter" "general_errors" {
  for_each = {
    permission  = aws_cloudwatch_log_group.permission_service.name
    invitation  = aws_cloudwatch_log_group.invitation_service.name
    team        = aws_cloudwatch_log_group.team_service.name
    role        = aws_cloudwatch_log_group.role_service.name
    authorizer  = aws_cloudwatch_log_group.authorizer.name
    audit       = aws_cloudwatch_log_group.audit_service.name
  }

  name           = "${local.name_prefix}-${each.key}-general-errors"
  log_group_name = each.value
  pattern        = "{ $.level = \"ERROR\" || $.level = \"error\" || $.levelname = \"ERROR\" }"

  metric_transformation {
    name          = "GeneralErrors"
    namespace     = "BBWS/AccessManagement"
    value         = "1"
    default_value = "0"
    unit          = "Count"
    dimensions = {
      Service     = each.key
      Environment = var.environment
    }
  }
}
```

---

## 6. dashboards.tf - CloudWatch Dashboard

```hcl
###############################################################################
# CloudWatch Monitoring Module - Dashboard
# BBWS Access Management System
###############################################################################

resource "aws_cloudwatch_dashboard" "access_management" {
  count = var.enable_dashboard ? 1 : 0

  dashboard_name = "${local.name_prefix}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      # Row 1: Header and Summary
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 1
        properties = {
          markdown = "# BBWS Access Management Dashboard - ${upper(var.environment)}\nReal-time monitoring of authentication, authorization, and access management services."
        }
      },

      # Row 2: Authorizer Metrics (Critical)
      {
        type   = "text"
        x      = 0
        y      = 1
        width  = 24
        height = 1
        properties = {
          markdown = "## Authorizer Service (Critical Path)"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 2
        width  = 8
        height = 6
        properties = {
          title  = "Authorizer Latency (p95)"
          view   = "timeSeries"
          region = var.aws_region
          metrics = [
            ["AWS/Lambda", "Duration", "FunctionName", "${local.name_prefix}-${local.services.authorizer}", { stat = "p95", color = "#2ca02c" }],
            ["...", { stat = "p99", color = "#ff7f0e" }]
          ]
          period = 60
          yAxis = {
            left = {
              min   = 0
              label = "Milliseconds"
            }
          }
          annotations = {
            horizontal = [
              {
                label = "SLA Threshold"
                value = var.authorizer_latency_threshold_ms
                color = "#d62728"
              }
            ]
          }
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 2
        width  = 8
        height = 6
        properties = {
          title  = "Authorizer Invocations & Errors"
          view   = "timeSeries"
          region = var.aws_region
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", "${local.name_prefix}-${local.services.authorizer}", { color = "#1f77b4" }],
            [".", "Errors", ".", ".", { color = "#d62728" }]
          ]
          period = 60
          yAxis = {
            left = {
              min = 0
            }
          }
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 2
        width  = 8
        height = 6
        properties = {
          title  = "Authorization Decisions"
          view   = "timeSeries"
          region = var.aws_region
          metrics = [
            ["BBWS/AccessManagement", "AuthorizationDenied", "Service", "Authorizer", "Environment", var.environment, { color = "#d62728", label = "Denied" }],
            [".", "TokenValidationFailures", ".", ".", ".", ".", { color = "#ff7f0e", label = "Token Failures" }],
            [".", "PermissionDenied", ".", ".", ".", ".", { color = "#9467bd", label = "Permission Denied" }]
          ]
          period = 60
          stat   = "Sum"
        }
      },

      # Row 3: Service Error Rates
      {
        type   = "text"
        x      = 0
        y      = 8
        width  = 24
        height = 1
        properties = {
          markdown = "## Service Error Rates"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 9
        width  = 12
        height = 6
        properties = {
          title  = "Lambda Errors by Service"
          view   = "timeSeries"
          region = var.aws_region
          metrics = [
            ["AWS/Lambda", "Errors", "FunctionName", "${local.name_prefix}-${local.services.permission_service}", { label = "Permission" }],
            ["...", "${local.name_prefix}-${local.services.invitation_service}", { label = "Invitation" }],
            ["...", "${local.name_prefix}-${local.services.team_service}", { label = "Team" }],
            ["...", "${local.name_prefix}-${local.services.role_service}", { label = "Role" }],
            ["...", "${local.name_prefix}-${local.services.audit_service}", { label = "Audit" }]
          ]
          period = 60
          stat   = "Sum"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 9
        width  = 12
        height = 6
        properties = {
          title  = "Lambda Invocations by Service"
          view   = "timeSeries"
          region = var.aws_region
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", "${local.name_prefix}-${local.services.permission_service}", { label = "Permission" }],
            ["...", "${local.name_prefix}-${local.services.invitation_service}", { label = "Invitation" }],
            ["...", "${local.name_prefix}-${local.services.team_service}", { label = "Team" }],
            ["...", "${local.name_prefix}-${local.services.role_service}", { label = "Role" }],
            ["...", "${local.name_prefix}-${local.services.audit_service}", { label = "Audit" }]
          ]
          period = 60
          stat   = "Sum"
        }
      },

      # Row 4: Invitations
      {
        type   = "text"
        x      = 0
        y      = 15
        width  = 24
        height = 1
        properties = {
          markdown = "## Invitation Service"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 16
        width  = 8
        height = 5
        properties = {
          title  = "Invitations Sent/Accepted"
          view   = "timeSeries"
          region = var.aws_region
          metrics = [
            ["BBWS/AccessManagement", "InvitationsSent", "Service", "InvitationService", "Environment", var.environment, { color = "#1f77b4", label = "Sent" }],
            [".", "InvitationsAccepted", ".", ".", ".", ".", { color = "#2ca02c", label = "Accepted" }]
          ]
          period = 300
          stat   = "Sum"
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 16
        width  = 8
        height = 5
        properties = {
          title  = "Invitation Email Failures"
          view   = "timeSeries"
          region = var.aws_region
          metrics = [
            ["BBWS/AccessManagement", "InvitationEmailFailures", "Service", "InvitationService", "Environment", var.environment, { color = "#d62728" }]
          ]
          period = 60
          stat   = "Sum"
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 16
        width  = 8
        height = 5
        properties = {
          title  = "Invitation Service Latency"
          view   = "timeSeries"
          region = var.aws_region
          metrics = [
            ["AWS/Lambda", "Duration", "FunctionName", "${local.name_prefix}-${local.services.invitation_service}", { stat = "p95", label = "p95" }],
            ["...", { stat = "Average", label = "Average" }]
          ]
          period = 60
        }
      },

      # Row 5: Audit Events
      {
        type   = "text"
        x      = 0
        y      = 21
        width  = 24
        height = 1
        properties = {
          markdown = "## Audit Service"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 22
        width  = 8
        height = 5
        properties = {
          title  = "Audit Events Captured"
          view   = "timeSeries"
          region = var.aws_region
          metrics = [
            ["BBWS/AccessManagement", "AuditEventsCaptured", "Service", "AuditService", "Environment", var.environment, { color = "#1f77b4" }]
          ]
          period = 300
          stat   = "Sum"
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 22
        width  = 8
        height = 5
        properties = {
          title  = "Audit Archive Failures"
          view   = "timeSeries"
          region = var.aws_region
          metrics = [
            ["BBWS/AccessManagement", "AuditArchiveFailures", "Service", "AuditService", "Environment", var.environment, { color = "#d62728" }]
          ]
          period = 3600
          stat   = "Sum"
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 22
        width  = 8
        height = 5
        properties = {
          title  = "Audit Exports"
          view   = "timeSeries"
          region = var.aws_region
          metrics = [
            ["BBWS/AccessManagement", "AuditExports", "Service", "AuditService", "Environment", var.environment, { color = "#2ca02c" }]
          ]
          period = 3600
          stat   = "Sum"
        }
      },

      # Row 6: DynamoDB Metrics
      {
        type   = "text"
        x      = 0
        y      = 27
        width  = 24
        height = 1
        properties = {
          markdown = "## DynamoDB Performance"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 28
        width  = 8
        height = 5
        properties = {
          title  = "DynamoDB Consumed Capacity"
          view   = "timeSeries"
          region = var.aws_region
          metrics = [
            ["AWS/DynamoDB", "ConsumedReadCapacityUnits", "TableName", var.dynamodb_table_name, { label = "Read" }],
            [".", "ConsumedWriteCapacityUnits", ".", ".", { label = "Write" }]
          ]
          period = 60
          stat   = "Sum"
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 28
        width  = 8
        height = 5
        properties = {
          title  = "DynamoDB Throttled Requests"
          view   = "timeSeries"
          region = var.aws_region
          metrics = [
            ["AWS/DynamoDB", "ThrottledRequests", "TableName", var.dynamodb_table_name, { color = "#d62728" }]
          ]
          period = 60
          stat   = "Sum"
          annotations = {
            horizontal = [
              {
                label = "Critical Threshold"
                value = 0
                color = "#d62728"
              }
            ]
          }
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 28
        width  = 8
        height = 5
        properties = {
          title  = "DynamoDB Latency (SuccessfulRequestLatency)"
          view   = "timeSeries"
          region = var.aws_region
          metrics = [
            ["AWS/DynamoDB", "SuccessfulRequestLatency", "TableName", var.dynamodb_table_name, "Operation", "GetItem", { label = "GetItem" }],
            ["...", "PutItem", { label = "PutItem" }],
            ["...", "Query", { label = "Query" }]
          ]
          period = 60
          stat   = "Average"
        }
      },

      # Row 7: Lambda Concurrency & Cold Starts
      {
        type   = "text"
        x      = 0
        y      = 33
        width  = 24
        height = 1
        properties = {
          markdown = "## Lambda Performance"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 34
        width  = 12
        height = 5
        properties = {
          title  = "Lambda Concurrent Executions"
          view   = "timeSeries"
          region = var.aws_region
          metrics = [
            ["AWS/Lambda", "ConcurrentExecutions", { stat = "Maximum", color = "#1f77b4" }]
          ]
          period = 60
          annotations = {
            horizontal = [
              {
                label = "Warning Threshold (${var.lambda_concurrent_execution_threshold_percent}%)"
                value = var.lambda_concurrent_execution_limit * (var.lambda_concurrent_execution_threshold_percent / 100)
                color = "#ff7f0e"
              }
            ]
          }
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 34
        width  = 12
        height = 5
        properties = {
          title  = "Service Latencies (p95)"
          view   = "timeSeries"
          region = var.aws_region
          metrics = [
            ["AWS/Lambda", "Duration", "FunctionName", "${local.name_prefix}-${local.services.permission_service}", { stat = "p95", label = "Permission" }],
            ["...", "${local.name_prefix}-${local.services.invitation_service}", { stat = "p95", label = "Invitation" }],
            ["...", "${local.name_prefix}-${local.services.team_service}", { stat = "p95", label = "Team" }],
            ["...", "${local.name_prefix}-${local.services.role_service}", { stat = "p95", label = "Role" }],
            ["...", "${local.name_prefix}-${local.services.audit_service}", { stat = "p95", label = "Audit" }]
          ]
          period = 60
        }
      },

      # Row 8: DLQ and Stuck Transactions
      {
        type   = "text"
        x      = 0
        y      = 39
        width  = 24
        height = 1
        properties = {
          markdown = "## Dead Letter Queue & Failed Transactions"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 40
        width  = 12
        height = 5
        properties = {
          title  = "DLQ Messages Received"
          view   = "timeSeries"
          region = var.aws_region
          metrics = [
            ["BBWS/AccessManagement", "DLQMessagesReceived", "Service", "DLQ", "Environment", var.environment, { color = "#d62728" }]
          ]
          period = 60
          stat   = "Sum"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 40
        width  = 12
        height = 5
        properties = {
          title  = "Business Logic Failures"
          view   = "timeSeries"
          region = var.aws_region
          metrics = [
            ["BBWS/AccessManagement", "CannotRemoveLastLeadAttempts", "Service", "TeamService", "Environment", var.environment, { label = "Last Lead Removal" }],
            [".", "RoleInUseDeletionAttempts", "Service", "RoleService", "Environment", var.environment, { label = "Role In Use" }],
            [".", "InvalidPermissionAttempts", "Service", "PermissionService", "Environment", var.environment, { label = "Invalid Permissions" }]
          ]
          period = 300
          stat   = "Sum"
        }
      },

      # Row 9: Active Users Counter
      {
        type   = "text"
        x      = 0
        y      = 45
        width  = 24
        height = 1
        properties = {
          markdown = "## Activity Summary"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 46
        width  = 8
        height = 4
        properties = {
          title  = "Active Users (Auth Requests)"
          view   = "singleValue"
          region = var.aws_region
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", "${local.name_prefix}-${local.services.authorizer}", { period = 3600, stat = "Sum" }]
          ]
          period = 3600
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 46
        width  = 8
        height = 4
        properties = {
          title  = "Permission Changes (24h)"
          view   = "singleValue"
          region = var.aws_region
          metrics = [
            ["BBWS/AccessManagement", "RolePermissionChanges", "Service", "RoleService", "Environment", var.environment, { period = 86400, stat = "Sum" }]
          ]
          period = 86400
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 46
        width  = 8
        height = 4
        properties = {
          title  = "Team Membership Changes (24h)"
          view   = "singleValue"
          region = var.aws_region
          metrics = [
            ["BBWS/AccessManagement", "TeamMembershipChanges", "Service", "TeamService", "Environment", var.environment, { period = 86400, stat = "Sum" }]
          ]
          period = 86400
        }
      }
    ]
  })
}
```

---

## 7. outputs.tf - Module Outputs

```hcl
###############################################################################
# CloudWatch Monitoring Module - Outputs
# BBWS Access Management System
###############################################################################

###############################################################################
# Log Group ARNs
###############################################################################

output "log_group_permission_service_arn" {
  description = "ARN of the Permission Service log group"
  value       = aws_cloudwatch_log_group.permission_service.arn
}

output "log_group_permission_service_name" {
  description = "Name of the Permission Service log group"
  value       = aws_cloudwatch_log_group.permission_service.name
}

output "log_group_invitation_service_arn" {
  description = "ARN of the Invitation Service log group"
  value       = aws_cloudwatch_log_group.invitation_service.arn
}

output "log_group_invitation_service_name" {
  description = "Name of the Invitation Service log group"
  value       = aws_cloudwatch_log_group.invitation_service.name
}

output "log_group_team_service_arn" {
  description = "ARN of the Team Service log group"
  value       = aws_cloudwatch_log_group.team_service.arn
}

output "log_group_team_service_name" {
  description = "Name of the Team Service log group"
  value       = aws_cloudwatch_log_group.team_service.name
}

output "log_group_role_service_arn" {
  description = "ARN of the Role Service log group"
  value       = aws_cloudwatch_log_group.role_service.arn
}

output "log_group_role_service_name" {
  description = "Name of the Role Service log group"
  value       = aws_cloudwatch_log_group.role_service.name
}

output "log_group_authorizer_arn" {
  description = "ARN of the Authorizer log group"
  value       = aws_cloudwatch_log_group.authorizer.arn
}

output "log_group_authorizer_name" {
  description = "Name of the Authorizer log group"
  value       = aws_cloudwatch_log_group.authorizer.name
}

output "log_group_audit_service_arn" {
  description = "ARN of the Audit Service log group"
  value       = aws_cloudwatch_log_group.audit_service.arn
}

output "log_group_audit_service_name" {
  description = "Name of the Audit Service log group"
  value       = aws_cloudwatch_log_group.audit_service.name
}

output "log_group_api_gateway_arn" {
  description = "ARN of the API Gateway log group"
  value       = aws_cloudwatch_log_group.api_gateway.arn
}

output "log_group_api_gateway_name" {
  description = "Name of the API Gateway log group"
  value       = aws_cloudwatch_log_group.api_gateway.name
}

output "log_group_dlq_processor_arn" {
  description = "ARN of the DLQ Processor log group"
  value       = aws_cloudwatch_log_group.dlq_processor.arn
}

output "log_group_dlq_processor_name" {
  description = "Name of the DLQ Processor log group"
  value       = aws_cloudwatch_log_group.dlq_processor.name
}

# Map of all log group ARNs
output "log_group_arns" {
  description = "Map of all log group ARNs"
  value = {
    permission_service = aws_cloudwatch_log_group.permission_service.arn
    invitation_service = aws_cloudwatch_log_group.invitation_service.arn
    team_service       = aws_cloudwatch_log_group.team_service.arn
    role_service       = aws_cloudwatch_log_group.role_service.arn
    authorizer         = aws_cloudwatch_log_group.authorizer.arn
    audit_service      = aws_cloudwatch_log_group.audit_service.arn
    api_gateway        = aws_cloudwatch_log_group.api_gateway.arn
    dlq_processor      = aws_cloudwatch_log_group.dlq_processor.arn
  }
}

###############################################################################
# SNS Topic ARNs
###############################################################################

output "sns_topic_critical_arn" {
  description = "ARN of the critical alerts SNS topic"
  value       = var.enable_sns_notifications ? aws_sns_topic.alerts_critical[0].arn : null
}

output "sns_topic_critical_name" {
  description = "Name of the critical alerts SNS topic"
  value       = var.enable_sns_notifications ? aws_sns_topic.alerts_critical[0].name : null
}

output "sns_topic_warning_arn" {
  description = "ARN of the warning alerts SNS topic"
  value       = var.enable_sns_notifications ? aws_sns_topic.alerts_warning[0].arn : null
}

output "sns_topic_warning_name" {
  description = "Name of the warning alerts SNS topic"
  value       = var.enable_sns_notifications ? aws_sns_topic.alerts_warning[0].name : null
}

output "sns_topic_dlq_arn" {
  description = "ARN of the DLQ alerts SNS topic"
  value       = var.enable_sns_notifications ? aws_sns_topic.dlq_alerts[0].arn : null
}

output "sns_topic_dlq_name" {
  description = "Name of the DLQ alerts SNS topic"
  value       = var.enable_sns_notifications ? aws_sns_topic.dlq_alerts[0].name : null
}

# Map of all SNS topic ARNs
output "sns_topic_arns" {
  description = "Map of all SNS topic ARNs"
  value = var.enable_sns_notifications ? {
    critical = aws_sns_topic.alerts_critical[0].arn
    warning  = aws_sns_topic.alerts_warning[0].arn
    dlq      = aws_sns_topic.dlq_alerts[0].arn
  } : {}
}

###############################################################################
# Dashboard
###############################################################################

output "dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = var.enable_dashboard ? aws_cloudwatch_dashboard.access_management[0].dashboard_name : null
}

output "dashboard_arn" {
  description = "ARN of the CloudWatch dashboard"
  value       = var.enable_dashboard ? aws_cloudwatch_dashboard.access_management[0].dashboard_arn : null
}

###############################################################################
# Alarm ARNs
###############################################################################

output "alarm_authorizer_errors_arn" {
  description = "ARN of the Authorizer errors alarm"
  value       = var.enable_alarms ? aws_cloudwatch_metric_alarm.authorizer_errors[0].arn : null
}

output "alarm_authorizer_latency_arn" {
  description = "ARN of the Authorizer latency alarm"
  value       = var.enable_alarms ? aws_cloudwatch_metric_alarm.authorizer_latency[0].arn : null
}

output "alarm_dynamodb_throttling_arn" {
  description = "ARN of the DynamoDB throttling alarm"
  value       = var.enable_alarms && var.dynamodb_table_name != "" ? aws_cloudwatch_metric_alarm.dynamodb_throttling[0].arn : null
}

output "alarm_invitation_failures_arn" {
  description = "ARN of the Invitation failures alarm"
  value       = var.enable_alarms ? aws_cloudwatch_metric_alarm.invitation_failures[0].arn : null
}

output "alarm_audit_archive_failures_arn" {
  description = "ARN of the Audit archive failures alarm"
  value       = var.enable_alarms ? aws_cloudwatch_metric_alarm.audit_archive_failures[0].arn : null
}

output "alarm_lambda_concurrency_arn" {
  description = "ARN of the Lambda concurrency warning alarm"
  value       = var.enable_alarms ? aws_cloudwatch_metric_alarm.lambda_concurrency[0].arn : null
}

output "alarm_dlq_messages_arn" {
  description = "ARN of the DLQ messages alarm"
  value       = var.enable_alarms ? aws_cloudwatch_metric_alarm.dlq_messages[0].arn : null
}

# Map of critical alarm ARNs
output "critical_alarm_arns" {
  description = "Map of critical alarm ARNs"
  value = var.enable_alarms ? {
    authorizer_errors     = aws_cloudwatch_metric_alarm.authorizer_errors[0].arn
    authorizer_latency    = aws_cloudwatch_metric_alarm.authorizer_latency[0].arn
    dynamodb_throttling   = var.dynamodb_table_name != "" ? aws_cloudwatch_metric_alarm.dynamodb_throttling[0].arn : null
    invitation_failures   = aws_cloudwatch_metric_alarm.invitation_failures[0].arn
    audit_archive_failures = aws_cloudwatch_metric_alarm.audit_archive_failures[0].arn
    dlq_messages          = aws_cloudwatch_metric_alarm.dlq_messages[0].arn
  } : {}
}

# Map of warning alarm ARNs
output "warning_alarm_arns" {
  description = "Map of warning alarm ARNs"
  value = var.enable_alarms ? {
    lambda_concurrency         = aws_cloudwatch_metric_alarm.lambda_concurrency[0].arn
    permission_service_errors  = aws_cloudwatch_metric_alarm.permission_service_errors[0].arn
    team_service_errors        = aws_cloudwatch_metric_alarm.team_service_errors[0].arn
    role_service_errors        = aws_cloudwatch_metric_alarm.role_service_errors[0].arn
    audit_service_errors       = aws_cloudwatch_metric_alarm.audit_service_errors[0].arn
    permission_service_latency = aws_cloudwatch_metric_alarm.permission_service_latency[0].arn
    invitation_service_latency = aws_cloudwatch_metric_alarm.invitation_service_latency[0].arn
  } : {}
}

###############################################################################
# Custom Metric Namespace
###############################################################################

output "custom_metric_namespace" {
  description = "Custom metric namespace for BBWS Access Management"
  value       = "BBWS/AccessManagement"
}
```

---

## 8. Example Usage

```hcl
###############################################################################
# Example: Using the CloudWatch Monitoring Module
###############################################################################

module "cloudwatch_monitoring" {
  source = "./terraform/modules/cloudwatch-monitoring"

  # Environment configuration
  environment    = "dev"
  project_name   = "bbws-access"
  aws_region     = "af-south-1"
  aws_account_id = "536580886816"

  # DynamoDB table name
  dynamodb_table_name = "bbws-aipagebuilder-dev-ddb-access-management"

  # Alert endpoints
  alert_email_endpoints   = ["critical-alerts@example.com"]
  warning_email_endpoints = ["dev-team@example.com"]

  # Alarm thresholds (can be adjusted per environment)
  authorizer_error_threshold      = 10
  authorizer_latency_threshold_ms = 100
  invitation_failure_threshold    = 5
  audit_archive_failure_threshold = 1

  # Feature flags
  enable_dashboard         = true
  enable_alarms           = true
  enable_sns_notifications = true

  # Tags
  tags = {
    Project    = "BBWS"
    CostCenter = "BBWS-ACCESS"
    Owner      = "DevOps"
  }
}

# Use outputs for other modules
output "cloudwatch_dashboard_url" {
  value = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${module.cloudwatch_monitoring.dashboard_name}"
}
```

---

## 9. Alarm Summary Table

| Alarm Name | Metric | Threshold | Severity | SNS Topic |
|------------|--------|-----------|----------|-----------|
| AuthorizerErrors | Lambda Errors (Sum/min) | > 10 | Critical | alerts-critical |
| AuthorizerLatency | Lambda Duration (p95) | > 100ms | Critical | alerts-critical |
| DynamoDBThrottling | ThrottledRequests (Sum/min) | > 0 | Critical | alerts-critical |
| InvitationFailures | Lambda Errors (Sum/min) | > 5 | Critical | alerts-critical |
| AuditArchiveFailures | Custom Metric (Sum/hour) | > 1 | Critical | alerts-critical |
| DLQMessages | Custom Metric (Sum/min) | > 0 | Critical | dlq-alerts |
| LambdaConcurrency | ConcurrentExecutions (Max) | > 80% limit | Warning | alerts-warning |
| PermissionServiceErrors | Lambda Errors (Sum/min) | > 5 | Warning | alerts-warning |
| TeamServiceErrors | Lambda Errors (Sum/min) | > 5 | Warning | alerts-warning |
| RoleServiceErrors | Lambda Errors (Sum/min) | > 5 | Warning | alerts-warning |
| AuditServiceErrors | Lambda Errors (Sum/min) | > 3 | Warning | alerts-warning |
| PermissionServiceLatency | Lambda Duration (p95) | > 500ms | Warning | alerts-warning |
| InvitationServiceLatency | Lambda Duration (p95) | > 1000ms | Warning | alerts-warning |

---

## 10. Custom Metric Filters Summary

| Metric Name | Service | Pattern | Purpose |
|-------------|---------|---------|---------|
| AuthorizationDenied | Authorizer | DENY decisions | Track access denials |
| TokenValidationFailures | Authorizer | TOKEN_* errors | Track auth failures |
| PermissionDenied | Authorizer | PERMISSION_DENIED | Track permission issues |
| OrgAccessDenied | Authorizer | ORG_ACCESS_DENIED | Track cross-org attempts |
| InvitationEmailFailures | Invitation | SES/email errors | Track email delivery issues |
| InvitationsSent | Invitation | INVITATION_CREATED | Track invitation volume |
| InvitationsAccepted | Invitation | INVITATION_ACCEPTED | Track acceptance rate |
| AuditArchiveFailures | Audit | archive errors | Track archive issues |
| AuditEventsCaptured | Audit | All event types | Track audit volume |
| TeamMembershipChanges | Team | MEMBER_ADDED/REMOVED | Track membership changes |
| RolePermissionChanges | Role | PERMISSIONS_ASSIGNED | Track permission changes |
| DLQMessagesReceived | DLQ | DLQ messages | Track failed transactions |
| GeneralErrors | All Services | level = ERROR | Track all errors |

---

## 11. Success Criteria Checklist

- [x] Log groups for all 6 services (Permission, Invitation, Team, Role, Authorizer, Audit)
- [x] Appropriate retention periods (30 days standard, 90 days for Audit)
- [x] Critical alarms configured (AuthorizerErrors, AuthorizerLatency, DynamoDBThrottling, InvitationFailures, AuditArchiveFailures)
- [x] SNS topics created (critical, warning, DLQ)
- [x] Dashboard with key metrics (Authorizer latency, error rates, invitations, audit events, DynamoDB capacity, Lambda concurrency)
- [x] Metric filters for error tracking (auth failures, permission denied, email failures, archive errors)
- [x] Environment parameterized (dev, sit, prod)
- [x] Alarm actions configured (SNS notifications)
- [x] Dead Letter Queue monitoring included
- [x] All outputs documented (log group ARNs, SNS topic ARNs, dashboard name)

---

**Module Complete**
**Worker**: worker-6-cloudwatch-monitoring-module
**Status**: COMPLETE
**Date**: 2026-01-23
