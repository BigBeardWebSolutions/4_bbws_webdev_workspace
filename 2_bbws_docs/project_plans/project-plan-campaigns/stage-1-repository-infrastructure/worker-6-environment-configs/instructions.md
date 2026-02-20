# Worker Instructions: Environment Configurations

**Worker ID**: worker-6-environment-configs
**Stage**: Stage 1 - Repository Setup & Infrastructure Code
**Project**: project-plan-campaigns

---

## Task

Create Terraform environment configuration files (.tfvars) for DEV, SIT, and PROD environments, along with main.tf, variables.tf, and versions.tf.

---

## Inputs

**Primary Input**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/2.1.3_LLD_Campaigns_Lambda.md`
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/HLDs/2.1.3_HLD_Campaign_Management.md`

**Reference**:
- HLD Section 10.2: Environments

---

## Deliverables

### 1. Environment Configuration Matrix

| Environment | Region | AWS Account | Notes |
|-------------|--------|-------------|-------|
| DEV | eu-west-1 | 536580886816 | Development and testing |
| SIT | eu-west-1 | 815856636111 | System integration testing |
| PROD | af-south-1 | 093646564004 | Production (DR: eu-west-1) |

### 2. Files to Create

```
terraform/
├── main.tf
├── variables.tf
├── outputs.tf          (already covered by other workers)
├── versions.tf
├── backend.tf
└── environments/
    ├── dev.tfvars
    ├── sit.tfvars
    └── prod.tfvars
```

---

## Expected Output Format

### terraform/versions.tf

```hcl
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

### terraform/backend.tf

```hcl
# Backend configuration (use -backend-config for environment-specific settings)
terraform {
  backend "s3" {
    # These values are provided via -backend-config
    # bucket         = "bbws-terraform-state-{account}"
    # key            = "campaigns-lambda/{environment}/terraform.tfstate"
    # region         = "{region}"
    # dynamodb_table = "terraform-state-lock"
    # encrypt        = true
  }
}
```

### terraform/main.tf

```hcl
# Provider Configuration
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "BBWS"
      Component   = "CampaignsLambda"
      CostCenter  = "BBWS-CPP"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# Local values
locals {
  project_name     = "bbws-campaigns"
  table_name       = "campaigns-${var.environment}"

  common_tags = {
    Project     = "BBWS"
    Component   = "CampaignsLambda"
    CostCenter  = "BBWS-CPP"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
```

### terraform/variables.tf

```hcl
# ===================
# Required Variables
# ===================

variable "environment" {
  description = "Deployment environment (dev, sit, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "sit", "prod"], var.environment)
    error_message = "Environment must be one of: dev, sit, prod."
  }
}

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
}

# ===================
# Optional Variables with Defaults
# ===================

variable "project_name" {
  description = "Project name prefix for resources"
  type        = string
  default     = "bbws-campaigns"
}

variable "dynamodb_table_prefix" {
  description = "Prefix for DynamoDB table names"
  type        = string
  default     = "bbws-customer-portal"
}

# Lambda Configuration
variable "lambda_memory" {
  description = "Lambda memory in MB"
  type        = number
  default     = 256
}

variable "lambda_timeout" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 30
}

variable "lambda_zip_path" {
  description = "Path to Lambda deployment package"
  type        = string
  default     = "../dist/lambda.zip"
}

# Logging
variable "log_level" {
  description = "Logging level for Lambda functions"
  type        = string
  default     = "INFO"

  validation {
    condition     = contains(["DEBUG", "INFO", "WARNING", "ERROR"], var.log_level)
    error_message = "Log level must be one of: DEBUG, INFO, WARNING, ERROR."
  }
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 90
}

# API Gateway
variable "api_throttle_burst" {
  description = "API Gateway throttle burst limit"
  type        = number
  default     = 100
}

variable "api_throttle_rate" {
  description = "API Gateway throttle rate limit"
  type        = number
  default     = 50
}

# DR Configuration (PROD only)
variable "dr_region" {
  description = "Disaster recovery region"
  type        = string
  default     = "eu-west-1"
}

variable "enable_dr_replication" {
  description = "Enable cross-region DynamoDB replication"
  type        = bool
  default     = false
}

# Tags
variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
```

### terraform/environments/dev.tfvars

```hcl
# ===================
# DEV Environment Configuration
# ===================

environment = "dev"
aws_region  = "eu-west-1"

# Lambda Configuration
lambda_memory  = 256
lambda_timeout = 30
log_level      = "DEBUG"  # More verbose logging in DEV

# API Gateway Throttling (lower limits for DEV)
api_throttle_burst = 50
api_throttle_rate  = 25

# Logging
log_retention_days = 30  # Shorter retention in DEV

# DR not enabled in DEV
enable_dr_replication = false

# Additional tags for DEV
common_tags = {
  CostTracking = "DEV-Environment"
}
```

### terraform/environments/sit.tfvars

```hcl
# ===================
# SIT Environment Configuration
# ===================

environment = "sit"
aws_region  = "eu-west-1"

# Lambda Configuration
lambda_memory  = 256
lambda_timeout = 30
log_level      = "INFO"

# API Gateway Throttling
api_throttle_burst = 75
api_throttle_rate  = 40

# Logging
log_retention_days = 60

# DR not enabled in SIT
enable_dr_replication = false

# Additional tags for SIT
common_tags = {
  CostTracking = "SIT-Environment"
}
```

### terraform/environments/prod.tfvars

```hcl
# ===================
# PROD Environment Configuration
# ===================

environment = "prod"
aws_region  = "af-south-1"  # Primary region for PROD

# Lambda Configuration
lambda_memory  = 256
lambda_timeout = 30
log_level      = "INFO"  # Less verbose in PROD

# API Gateway Throttling (full capacity in PROD)
api_throttle_burst = 100
api_throttle_rate  = 50

# Logging
log_retention_days = 90  # Longer retention in PROD

# DR Configuration
dr_region             = "eu-west-1"
enable_dr_replication = true  # Enable cross-region replication

# Additional tags for PROD
common_tags = {
  CostTracking = "PROD-Environment"
  DR           = "Enabled"
  Compliance   = "SOC2"
}
```

---

## Key Requirements from CLAUDE.md

### Environment Strategy

> "I have three environments, dev, sit and prod. I am now deploying to dev. can we stick to that. Whatever we fix in dev, the workload will be promoted to sit, when sit is tested, the workload will be promoted to prod"

### No Hardcoded Credentials

> "never hardcode environment credentials, parameterise them so that we can deploy to any environment without breaking the system"

All environment-specific values MUST be in .tfvars files:
- AWS region
- Log levels
- Throttle limits
- DR settings

### DR Strategy

> "Disaster recovery strategy: Since we are server less, we decided to go with the multisite active/active DR. This means that we will have active production in South Africa and passive DR in Ireland."

- PROD primary: af-south-1
- PROD DR: eu-west-1
- Cross-region replication enabled for PROD only

---

## Success Criteria

- [ ] versions.tf created with Terraform >= 1.5.0
- [ ] backend.tf created for S3 state storage
- [ ] main.tf created with provider configuration
- [ ] variables.tf created with all required variables
- [ ] dev.tfvars created for DEV environment
- [ ] sit.tfvars created for SIT environment
- [ ] prod.tfvars created for PROD with DR settings
- [ ] No hardcoded credentials or account IDs
- [ ] DR enabled only for PROD
- [ ] Terraform validates successfully

---

## Execution Steps

1. Read HLD Section 10.2 for environment specifications
2. Create versions.tf with provider requirements
3. Create backend.tf for S3 state
4. Create main.tf with provider and locals
5. Create variables.tf with all variables
6. Create dev.tfvars with DEV settings
7. Create sit.tfvars with SIT settings
8. Create prod.tfvars with PROD and DR settings
9. Run `terraform validate`
10. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-15
