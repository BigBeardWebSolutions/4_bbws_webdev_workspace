variable "environment" {
  description = "Environment name (dev, sit, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "sit", "prod"], var.environment)
    error_message = "Environment must be dev, sit, or prod"
  }
}

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "af-south-1"
}

variable "notification_emails" {
  description = "List of email addresses to receive cost reports"
  type        = list(string)
  default     = []
}

variable "report_type" {
  description = "Default report type (weekly or monthly)"
  type        = string
  default     = "weekly"

  validation {
    condition     = contains(["weekly", "monthly"], var.report_type)
    error_message = "Report type must be weekly or monthly"
  }
}

variable "enable_monthly_report" {
  description = "Enable monthly cost reports"
  type        = bool
  default     = true
}

variable "enable_weekly_report" {
  description = "Enable weekly cost reports"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention period in days"
  type        = number
  default     = 7
}

variable "dev_account_role_arn" {
  description = "IAM role ARN for DEV account (for cross-account access)"
  type        = string
  default     = ""
}

variable "sit_account_role_arn" {
  description = "IAM role ARN for SIT account (for cross-account access)"
  type        = string
  default     = ""
}

variable "prod_account_role_arn" {
  description = "IAM role ARN for PROD account (for cross-account access)"
  type        = string
  default     = ""
}

variable "cross_account_role_arns" {
  description = "List of cross-account role ARNs that Lambda can assume"
  type        = list(string)
  default     = []
}
