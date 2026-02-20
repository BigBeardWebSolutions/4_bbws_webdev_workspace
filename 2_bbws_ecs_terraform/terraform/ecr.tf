# ECR Repository for Custom WordPress Image
# This repository stores the custom WordPress image with WP-CLI and mu-plugins

resource "aws_ecr_repository" "wordpress" {
  name                 = "${var.environment}-wordpress"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name        = "${var.environment}-wordpress-ecr"
    Environment = var.environment
    Project     = "bbws-wordpress"
  }
}

# Lifecycle policy to keep only last 10 images (cost optimization)
resource "aws_ecr_lifecycle_policy" "wordpress" {
  repository = aws_ecr_repository.wordpress.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = {
        type = "expire"
      }
    }]
  })
}

# Output for ECR repository URL (used by build scripts)
output "ecr_repository_url" {
  description = "ECR repository URL for WordPress image"
  value       = aws_ecr_repository.wordpress.repository_url
}

output "ecr_repository_name" {
  description = "ECR repository name"
  value       = aws_ecr_repository.wordpress.name
}
