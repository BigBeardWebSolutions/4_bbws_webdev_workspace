# ECS Tenant Module - Input Variables

#------------------------------------------------------------------------------
# Required Variables
#------------------------------------------------------------------------------

variable "tenant_name" {
  description = "Unique name for the tenant (e.g., goldencrust, sunsetbistro)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]+$", var.tenant_name))
    error_message = "Tenant name must contain only lowercase letters and numbers."
  }
}

variable "environment" {
  description = "Environment name (dev, sit, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "sit", "prod"], var.environment)
    error_message = "Environment must be dev, sit, or prod."
  }
}

variable "domain_name" {
  description = "Full domain name for the tenant (e.g., goldencrust.wpdev.kimmyai.io)"
  type        = string
}

variable "alb_priority" {
  description = "ALB listener rule priority (must be unique per tenant, 1-50000)"
  type        = number

  validation {
    condition     = var.alb_priority >= 1 && var.alb_priority <= 50000
    error_message = "ALB priority must be between 1 and 50000."
  }
}

#------------------------------------------------------------------------------
# Infrastructure References (from shared resources)
#------------------------------------------------------------------------------

variable "vpc_id" {
  description = "VPC ID where tenant will be deployed"
  type        = string
}

variable "cluster_id" {
  description = "ECS cluster ID"
  type        = string
}

variable "efs_id" {
  description = "EFS file system ID for wp-content storage"
  type        = string
}

variable "rds_endpoint" {
  description = "RDS endpoint address"
  type        = string
}

variable "alb_listener_arn" {
  description = "ALB HTTP listener ARN for routing rules"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for ECS tasks"
  type        = list(string)
}

variable "ecs_security_group_ids" {
  description = "List of security group IDs for ECS tasks"
  type        = list(string)
}

variable "ecs_task_execution_role_arn" {
  description = "IAM role ARN for ECS task execution (pulls images, writes logs)"
  type        = string
}

variable "ecs_task_role_arn" {
  description = "IAM role ARN for ECS task (application permissions)"
  type        = string
}

variable "cloudwatch_log_group_name" {
  description = "CloudWatch log group name for container logs"
  type        = string
}

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
}

#------------------------------------------------------------------------------
# ECS Task Configuration
#------------------------------------------------------------------------------

variable "task_cpu" {
  description = "Fargate task CPU units (256, 512, 1024, 2048, 4096)"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Fargate task memory in MB (512, 1024, 2048, etc.)"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 1
}

variable "wordpress_image" {
  description = "WordPress Docker image URI"
  type        = string
}

variable "wordpress_debug" {
  description = "Enable WordPress debug mode"
  type        = bool
  default     = false
}

variable "additional_environment_vars" {
  description = "Additional environment variables for WordPress container"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

#------------------------------------------------------------------------------
# Health Check Configuration
#------------------------------------------------------------------------------

variable "health_check_path" {
  description = "Health check path"
  type        = string
  default     = "/"
}

variable "health_check_interval" {
  description = "Health check interval in seconds"
  type        = number
  default     = 30
}

variable "health_check_timeout" {
  description = "Health check timeout in seconds"
  type        = number
  default     = 5
}

variable "health_check_healthy_threshold" {
  description = "Healthy threshold count"
  type        = number
  default     = 2
}

variable "health_check_unhealthy_threshold" {
  description = "Unhealthy threshold count"
  type        = number
  default     = 3
}

variable "health_check_matcher" {
  description = "HTTP response codes to consider healthy"
  type        = string
  default     = "200,301,302"
}

#------------------------------------------------------------------------------
# Service Configuration
#------------------------------------------------------------------------------

variable "deregistration_delay" {
  description = "Target group deregistration delay in seconds"
  type        = number
  default     = 30
}

variable "deployment_maximum_percent" {
  description = "Maximum percentage of tasks during deployment"
  type        = number
  default     = 200
}

variable "deployment_minimum_healthy_percent" {
  description = "Minimum healthy percentage of tasks during deployment"
  type        = number
  default     = 100
}

variable "enable_ecs_exec" {
  description = "Enable ECS Exec for debugging (aws ecs execute-command)"
  type        = bool
  default     = false
}

#------------------------------------------------------------------------------
# Tags
#------------------------------------------------------------------------------

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}
