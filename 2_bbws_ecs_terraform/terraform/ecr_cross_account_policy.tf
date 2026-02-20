# Cross-Account ECR Pull Policy (DEV Only)
# Grants SIT and PROD accounts permission to pull images from DEV ECR
# This ensures SIT/PROD use the exact same tested image from DEV
#
# Only created in DEV environment — SIT/PROD do not need this resource

resource "aws_ecr_repository_policy" "cross_account_pull" {
  count      = var.environment == "dev" ? 1 : 0
  repository = aws_ecr_repository.wordpress.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCrossAccountPull"
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:aws:iam::815856636111:root",  # SIT account
            "arn:aws:iam::093646564004:root"   # PROD account
          ]
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:DescribeImages",
          "ecr:DescribeRepositories"
        ]
      }
    ]
  })
}
