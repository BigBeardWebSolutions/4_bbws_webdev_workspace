# thejudokan Tenant - Provider Configuration
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
    random = { source = "hashicorp/random", version = "~> 3.5" }
    null = { source = "hashicorp/null", version = "~> 3.2" }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
  default_tags {
    tags = {
      Project     = "BBWS"
      Tenant      = var.tenant_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}
