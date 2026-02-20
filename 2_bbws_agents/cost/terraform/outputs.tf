output "lambda_function_arn" {
  description = "ARN of the cost reporter Lambda function"
  value       = aws_lambda_function.cost_reporter.arn
}

output "lambda_function_name" {
  description = "Name of the cost reporter Lambda function"
  value       = aws_lambda_function.cost_reporter.function_name
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for cost reports"
  value       = aws_sns_topic.cost_report.arn
}

output "sns_topic_name" {
  description = "Name of the SNS topic for cost reports"
  value       = aws_sns_topic.cost_report.name
}

output "monthly_schedule_rule" {
  description = "Name of the monthly cost report EventBridge rule"
  value       = var.enable_monthly_report ? aws_cloudwatch_event_rule.monthly_cost_report[0].name : null
}

output "weekly_schedule_rule" {
  description = "Name of the weekly cost report EventBridge rule"
  value       = var.enable_weekly_report ? aws_cloudwatch_event_rule.weekly_cost_report[0].name : null
}

output "cloudwatch_log_group" {
  description = "CloudWatch Log Group for Lambda function"
  value       = aws_cloudwatch_log_group.cost_reporter.name
}

output "subscription_confirmation_note" {
  description = "Instructions for confirming email subscriptions"
  value       = "Check your email and confirm the SNS subscription to start receiving cost reports"
}
