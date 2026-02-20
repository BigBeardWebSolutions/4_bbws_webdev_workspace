# Cognito Tenant Module - Input Variables

#------------------------------------------------------------------------------
# Required Variables
#------------------------------------------------------------------------------

variable "tenant_name" {
  description = "Unique name for the tenant (e.g., goldencrust)"
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
  description = "Full domain name for the tenant (e.g., goldencrust.wpsit.kimmyai.io)"
  type        = string
}

#------------------------------------------------------------------------------
# Tags
#------------------------------------------------------------------------------

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}
