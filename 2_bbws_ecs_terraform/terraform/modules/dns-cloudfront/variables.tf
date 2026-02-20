# DNS-CloudFront Module - Input Variables

#------------------------------------------------------------------------------
# Required Variables
#------------------------------------------------------------------------------

variable "tenant_name" {
  description = "Unique name for the tenant (used for tagging)"
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

variable "route53_zone_id" {
  description = "Route53 hosted zone ID (e.g., Z07406882WSFMSDQTX1HR for wpsit.kimmyai.io)"
  type        = string
}

variable "cloudfront_domain_name" {
  description = "CloudFront distribution domain name (e.g., d1234567890.cloudfront.net)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]+\\.cloudfront\\.net$", var.cloudfront_domain_name))
    error_message = "CloudFront domain must be in format: {id}.cloudfront.net"
  }
}

variable "cloudfront_zone_id" {
  description = "CloudFront hosted zone ID (always Z2FDTNDATAQYW2 for all distributions)"
  type        = string
  default     = "Z2FDTNDATAQYW2"
}

#------------------------------------------------------------------------------
# Optional Configuration
#------------------------------------------------------------------------------

variable "create_ipv6_record" {
  description = "Create AAAA record for IPv6 support"
  type        = bool
  default     = true
}

variable "evaluate_target_health" {
  description = "Evaluate target health for alias records"
  type        = bool
  default     = false
}

#------------------------------------------------------------------------------
# Tags
#------------------------------------------------------------------------------

variable "tags" {
  description = "Additional tags for DNS records"
  type        = map(string)
  default     = {}
}
