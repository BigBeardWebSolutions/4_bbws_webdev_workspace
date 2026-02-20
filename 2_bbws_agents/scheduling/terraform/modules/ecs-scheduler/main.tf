terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.0"
    }
  }
}

locals {
  # Include cluster name in prefix to ensure uniqueness when multiple clusters are scheduled
  prefix = "${var.environment}-ecs-scheduler-${var.cluster_name}"
  default_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
    Purpose     = "ecs-cost-savings"
    Cluster     = var.cluster_name
  })
}
