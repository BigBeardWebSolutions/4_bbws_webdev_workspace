variable "environment" {
  description = "Environment name (dev, sit)"
  type        = string
}

variable "cluster_name" {
  description = "ECS cluster name"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "notification_emails" {
  description = "Email addresses for SNS notifications"
  type        = list(string)
}

variable "stop_cron" {
  description = "Cron expression for stopping services (UTC)"
  type        = string
  default     = "cron(0 17 ? * MON-FRI *)"
}

variable "start_cron" {
  description = "Cron expression for starting services (UTC)"
  type        = string
  default     = "cron(0 5 ? * MON-FRI *)"
}

variable "enabled" {
  description = "Enable or disable the schedule rules without destroying resources"
  type        = bool
  default     = true
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 300
}

variable "service_prefixes" {
  description = "List of service name prefixes to include. Empty list means all services."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
