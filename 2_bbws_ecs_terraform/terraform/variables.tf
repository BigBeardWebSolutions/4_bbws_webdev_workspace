# Variables for POC1 - ECS Fargate Multi-Tenant WordPress
# Multi-Account Deployment Configuration

#------------------------------------------------------------------------------
# Account & Environment Configuration
#------------------------------------------------------------------------------

variable "aws_account_id" {
  description = "Target AWS Account ID for validation"
  type        = string
  # Required - no default, must be provided via tfvars
}

variable "aws_region" {
  description = "AWS region for deployment (eu-west-1 for DEV/SIT, af-south-1 for PROD)"
  type        = string
  # No default - must be provided via tfvars to prevent wrong region deployment
}

variable "environment" {
  description = "Environment name (dev, sit, prod)"
  type        = string
  # Required - no default, must be provided via tfvars
}

variable "assume_role_arn" {
  description = "IAM role ARN to assume for cross-account deployment (optional)"
  type        = string
  default     = ""
}

#------------------------------------------------------------------------------
# Network Configuration
#------------------------------------------------------------------------------

variable "vpc_cidr" {
  description = "VPC CIDR block (unique per environment to allow peering)"
  type        = string
  # Required - no default, must be provided via tfvars
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
  # Required - no default, must be provided via tfvars
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
  # Required - no default, must be provided via tfvars
}

#------------------------------------------------------------------------------
# RDS Configuration
#------------------------------------------------------------------------------

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_master_username" {
  description = "RDS master username"
  type        = string
  default     = "admin"
}

variable "rds_multi_az" {
  description = "Enable Multi-AZ deployment for RDS"
  type        = bool
  default     = false
}

variable "rds_backup_retention" {
  description = "RDS backup retention period in days (0 = disabled)"
  type        = number
  default     = 0
}

variable "rds_skip_final_snapshot" {
  description = "Skip final snapshot on RDS deletion (set false for prod)"
  type        = bool
  default     = true
}

#------------------------------------------------------------------------------
# ALB Configuration
#------------------------------------------------------------------------------

variable "alb_deletion_protection" {
  description = "Enable deletion protection for ALB (set true for prod)"
  type        = bool
  default     = false
}

#------------------------------------------------------------------------------
# ECS Configuration
#------------------------------------------------------------------------------

variable "ecs_task_cpu" {
  description = "Fargate task CPU units (256, 512, 1024, etc.)"
  type        = string
  default     = "512"
}

variable "ecs_task_memory" {
  description = "Fargate task memory in MB"
  type        = string
  default     = "1024"
}

variable "wordpress_image" {
  description = "WordPress Docker image (leave empty to use ECR repository)"
  type        = string
  default     = ""  # Empty = use ECR repository
}

variable "wordpress_image_tag" {
  description = "WordPress Docker image tag"
  type        = string
  default     = "latest"
}

variable "use_ecr_image" {
  description = "Use custom ECR image instead of Docker Hub (requires image to be built and pushed first)"
  type        = bool
  default     = false  # Set to true after first image push
}

#------------------------------------------------------------------------------
# CloudFront Configuration
#------------------------------------------------------------------------------

variable "cloudfront_enabled" {
  description = "Enable CloudFront distribution for HTTPS and CDN"
  type        = bool
  default     = true
}

variable "cloudfront_enable_basic_auth" {
  description = "Enable basic auth protection (recommended for non-production)"
  type        = bool
  default     = true
}

variable "cloudfront_basic_auth_username" {
  description = "Username for basic auth"
  type        = string
  default     = "bbws"
  sensitive   = true
}

variable "cloudfront_basic_auth_password" {
  description = "Password for basic auth"
  type        = string
  default     = ""
  sensitive   = true
}

variable "cloudfront_price_class" {
  description = "CloudFront price class (PriceClass_100, PriceClass_200, PriceClass_All)"
  type        = string
  default     = "PriceClass_All"
}

#------------------------------------------------------------------------------
# Monitoring & Alerting Configuration
#------------------------------------------------------------------------------

variable "alert_email" {
  description = "Email address for CloudWatch alerts and SNS notifications"
  type        = string
  default     = ""
}

variable "enable_dynamodb_monitoring" {
  description = "Enable DynamoDB-specific monitoring alarms"
  type        = bool
  default     = false
}

variable "enable_dlq_monitoring" {
  description = "Enable Dead Letter Queue monitoring (for future Lambda functions)"
  type        = bool
  default     = false
}
