terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region  = "eu-west-1"
  profile = "sit"

  default_tags {
    tags = {
      Environment = "sit"
      ManagedBy   = "terraform"
      Project     = "bbws-ecs-scheduler"
    }
  }
}

module "ecs_scheduler" {
  source   = "../../modules/ecs-scheduler"
  for_each = var.clusters

  environment         = var.environment
  cluster_name        = each.key
  region              = var.region
  notification_emails = var.notification_emails
  stop_cron           = var.stop_cron
  start_cron          = var.start_cron
  enabled             = var.enabled
  service_prefixes    = each.value.service_prefixes
}
