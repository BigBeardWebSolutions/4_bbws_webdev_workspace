# metisunicorns Tenant Variables

variable "tenant_name" {
  description = "Tenant name"
  type        = string
  default     = "metisunicorns"
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

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "aws_profile" {
  description = "AWS CLI profile for operations"
  type        = string
}

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

variable "health_check_path" {
  type    = string
  default = "/"
}

variable "health_check_interval" {
  type    = number
  default = 30
}

variable "health_check_healthy_threshold" {
  type    = number
  default = 2
}

variable "health_check_unhealthy_threshold" {
  type    = number
  default = 3
}

variable "init_db_script_path" {
  type    = string
  default = "../../../../2_bbws_agents/utils/init_tenant_db.py"
}

variable "verify_database" {
  type    = bool
  default = true
}

variable "create_dns_records" {
  type    = bool
  default = false
}

variable "route53_zone_id" {
  type    = string
  default = ""
}

variable "cloudfront_domain_name" {
  type    = string
  default = ""
}

variable "create_ipv6_record" {
  type    = bool
  default = true
}

variable "evaluate_target_health" {
  type    = bool
  default = false
}

variable "wordpress_debug" {
  type    = bool
  default = false
}

variable "enable_ecs_exec" {
  type    = bool
  default = true
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "vpc_id" {
  description = "VPC ID (optional - use to override tag-based lookup when multiple VPCs match)"
  type        = string
  default     = ""
}

variable "security_group_id" {
  description = "ECS Security Group ID (optional - use to override tag-based lookup)"
  type        = string
  default     = ""
}
