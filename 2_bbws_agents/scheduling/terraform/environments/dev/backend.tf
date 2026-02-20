terraform {
  backend "s3" {
    bucket  = "bbws-terraform-state-dev"
    key     = "ecs-scheduler/terraform.tfstate"
    region  = "eu-west-1"
    profile = "dev"
    encrypt = true
  }
}

variable "environment" {
  type = string
}

variable "clusters" {
  description = "Map of cluster names to their configuration"
  type = map(object({
    service_prefixes = list(string)
  }))
}

variable "region" {
  type    = string
  default = "eu-west-1"
}

variable "notification_emails" {
  type = list(string)
}

variable "stop_cron" {
  type = string
}

variable "start_cron" {
  type = string
}

variable "enabled" {
  type    = bool
  default = true
}
