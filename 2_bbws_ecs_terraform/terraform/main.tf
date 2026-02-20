# Main Terraform Configuration for POC1 - ECS Fargate Multi-Tenant WordPress
# Multi-Account Deployment Support

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  # Backend configuration - values provided via -backend-config flag
  # See backends/*.hcl for environment-specific configurations
  backend "s3" {}
}

provider "aws" {
  region = var.aws_region

  # Cross-account deployment support via assume_role
  dynamic "assume_role" {
    for_each = var.assume_role_arn != "" ? [1] : []
    content {
      role_arn     = var.assume_role_arn
      session_name = "terraform-${var.environment}"
    }
  }

  default_tags {
    tags = {
      Project     = "BBWS-ECS-WordPress"
      Environment = var.environment
      ManagedBy   = "Terraform"
      AccountId   = var.aws_account_id
    }
  }
}

#------------------------------------------------------------------------------
# Account Validation
# Prevents accidental deployment to wrong AWS account
#------------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

resource "null_resource" "account_validation" {
  lifecycle {
    precondition {
      condition     = data.aws_caller_identity.current.account_id == var.aws_account_id
      error_message = "DEPLOYMENT BLOCKED: Wrong AWS account! Expected ${var.aws_account_id}, but connected to ${data.aws_caller_identity.current.account_id}"
    }
  }
}
