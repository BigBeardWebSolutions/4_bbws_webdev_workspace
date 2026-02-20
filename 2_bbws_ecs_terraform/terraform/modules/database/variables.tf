# Database Module - Input Variables

#------------------------------------------------------------------------------
# Required Variables
#------------------------------------------------------------------------------

variable "tenant_name" {
  description = "Unique name for the tenant (must match ecs-tenant module)"
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

variable "tenant_db_secret_arn" {
  description = "ARN of Secrets Manager secret containing tenant database credentials (from ecs-tenant module)"
  type        = string
}

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
}

variable "aws_profile" {
  description = "AWS CLI profile for database operations"
  type        = string
}

#------------------------------------------------------------------------------
# Script Configuration
#------------------------------------------------------------------------------

variable "init_db_script_path" {
  description = "Path to the init_tenant_db.py script"
  type        = string
  default     = "../../../2_bbws_agents/utils/init_tenant_db.py"
}

variable "verify_database" {
  description = "Run verification check after database creation"
  type        = bool
  default     = true
}

#------------------------------------------------------------------------------
# Tags
#------------------------------------------------------------------------------

variable "tags" {
  description = "Additional tags for resources (currently null_resource doesn't support tags)"
  type        = map(string)
  default     = {}
}
