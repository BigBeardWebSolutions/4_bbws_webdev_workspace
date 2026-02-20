# Goldencrust Tenant Variables

#------------------------------------------------------------------------------
# Tenant Identity (Required)
#------------------------------------------------------------------------------

variable "tenant_name" {
  description = "Tenant name"
  type        = string
  default     = "serenity"
}

variable "environment" {
  description = "Environment (dev, sit, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "sit", "prod"], var.environment)
    error_message = "Environment must be dev, sit, or prod."
  }
}

variable "domain_name" {
  description = "Full domain name for the tenant"
  type        = string
}

variable "alb_priority" {
  description = "ALB listener rule priority (unique per environment)"
  type        = number
}

#------------------------------------------------------------------------------
# AWS Configuration
#------------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "aws_profile" {
  description = "AWS CLI profile for operations"
  type        = string
}

#------------------------------------------------------------------------------
# ECS Configuration
#------------------------------------------------------------------------------

variable "wordpress_image" {
  description = "WordPress Docker image URI"
  type        = string
}

variable "task_cpu" {
  description = "Fargate task CPU units"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Fargate task memory in MB"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 1
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

#------------------------------------------------------------------------------
# Database Configuration
#------------------------------------------------------------------------------

variable "init_db_script_path" {
  description = "Path to init_tenant_db.py script"
  type        = string
  default     = "../../../../2_bbws_agents/utils/init_tenant_db.py"
}

variable "verify_database" {
  description = "Verify database creation"
  type        = bool
  default     = true
}

#------------------------------------------------------------------------------
# DNS Configuration (PROD only)
#------------------------------------------------------------------------------

variable "create_dns_records" {
  description = "Create DNS records (PROD only)"
  type        = bool
  default     = false
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID"
  type        = string
  default     = ""
}

variable "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  type        = string
  default     = ""
}

variable "create_ipv6_record" {
  description = "Create AAAA record for IPv6"
  type        = bool
  default     = true
}

variable "evaluate_target_health" {
  description = "Evaluate target health for alias records"
  type        = bool
  default     = false
}

#------------------------------------------------------------------------------
# Feature Flags
#------------------------------------------------------------------------------

variable "wordpress_debug" {
  description = "Enable WordPress debug mode"
  type        = bool
  default     = false
}

variable "enable_ecs_exec" {
  description = "Enable ECS Exec for debugging"
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
