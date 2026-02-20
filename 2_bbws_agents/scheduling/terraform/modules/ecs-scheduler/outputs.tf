output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.ecs_scheduler.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.ecs_scheduler.arn
}

output "stop_rule_arn" {
  description = "ARN of the EventBridge stop rule"
  value       = aws_cloudwatch_event_rule.stop.arn
}

output "start_rule_arn" {
  description = "ARN of the EventBridge start rule"
  value       = aws_cloudwatch_event_rule.start.arn
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB state table"
  value       = aws_dynamodb_table.state.name
}

output "sns_topic_arn" {
  description = "ARN of the SNS notification topic"
  value       = aws_sns_topic.notifications.arn
}
