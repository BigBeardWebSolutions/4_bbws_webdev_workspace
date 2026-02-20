# SIT Cross-Account ECR Pull Policy (SIT Only)
# Grants the SIT ECS task execution role permission to pull images from DEV ECR
# This allows SIT tasks to use the DEV-built WordPress image directly
#
# Only created in SIT environment — DEV/PROD do not need this resource

resource "aws_iam_role_policy" "ecs_cross_account_ecr_pull" {
  count = var.environment == "sit" ? 1 : 0
  name  = "${var.environment}-ecs-cross-account-ecr-pull"
  role  = aws_iam_role.ecs_task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCrossAccountECRPull"
        Effect = "Allow"
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
        Resource = "arn:aws:ecr:eu-west-1:536580886816:repository/dev-wordpress"
      },
      {
        Sid    = "AllowECRAuthToken"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      }
    ]
  })
}
