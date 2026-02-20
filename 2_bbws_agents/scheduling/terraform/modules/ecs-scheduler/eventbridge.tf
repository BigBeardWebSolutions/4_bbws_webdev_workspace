resource "aws_cloudwatch_event_rule" "stop" {
  name                = "${local.prefix}-stop"
  description         = "Stop ECS services at 7 PM SAST (5 PM UTC) weekdays"
  schedule_expression = var.stop_cron
  state               = var.enabled ? "ENABLED" : "DISABLED"
  tags                = local.default_tags
}

resource "aws_cloudwatch_event_rule" "start" {
  name                = "${local.prefix}-start"
  description         = "Start ECS services at 7 AM SAST (5 AM UTC) weekdays"
  schedule_expression = var.start_cron
  state               = var.enabled ? "ENABLED" : "DISABLED"
  tags                = local.default_tags
}

resource "aws_cloudwatch_event_target" "stop" {
  rule = aws_cloudwatch_event_rule.stop.name
  arn  = aws_lambda_function.ecs_scheduler.arn

  input = jsonencode({
    action           = "stop"
    cluster_name     = var.cluster_name
    region           = var.region
    service_prefixes = var.service_prefixes
  })
}

resource "aws_cloudwatch_event_target" "start" {
  rule = aws_cloudwatch_event_rule.start.name
  arn  = aws_lambda_function.ecs_scheduler.arn

  input = jsonencode({
    action           = "start"
    cluster_name     = var.cluster_name
    region           = var.region
    service_prefixes = var.service_prefixes
  })
}

resource "aws_lambda_permission" "allow_eventbridge_stop" {
  statement_id  = "AllowEventBridgeStop"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ecs_scheduler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.stop.arn
}

resource "aws_lambda_permission" "allow_eventbridge_start" {
  statement_id  = "AllowEventBridgeStart"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ecs_scheduler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.start.arn
}
