data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../../../lambda/ecs_scheduler.py"
  output_path = "${path.module}/files/ecs_scheduler.zip"
}

resource "aws_lambda_function" "ecs_scheduler" {
  function_name    = local.prefix
  description      = "Stop/start ECS services on schedule for ${var.environment}"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  handler          = "ecs_scheduler.handler"
  runtime          = "python3.12"
  timeout          = var.lambda_timeout
  role             = aws_iam_role.lambda.arn

  environment {
    variables = {
      DYNAMO_TABLE  = aws_dynamodb_table.state.name
      SNS_TOPIC_ARN = aws_sns_topic.notifications.arn
    }
  }

  tags = local.default_tags
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${local.prefix}"
  retention_in_days = 30
  tags              = local.default_tags
}
