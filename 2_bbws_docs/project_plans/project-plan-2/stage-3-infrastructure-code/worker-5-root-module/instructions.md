# Worker 3-5: Terraform Root Module Integration

**Worker ID**: worker-5-root-module
**Stage**: Stage 3 - Infrastructure Code Development
**Status**: PENDING
**Agent**: DevOps Engineer Agent
**Repository**: `2_1_bbws_infrastructure`

---

## Objective

Create root Terraform configuration that integrates all modules (S3, CloudFront, Route 53, ACM, Lambda@Edge) for multi-environment deployment. Set up Terraform backend, environment-specific configurations, and deployment automation.

---

## Prerequisites

- ✅ All previous workers complete (3-1, 3-2, 3-3, 3-4)
- ✅ All Terraform modules created and validated
- Terraform state backend (S3 + DynamoDB) created

---

## Tasks

### 1. Create Environment Directories

Create separate directories for each environment:

```bash
mkdir -p environments/{dev,sit,prod}
```

---

### 2. Create DEV Environment Configuration

**Directory**: `environments/dev/`

#### 2.1 Main Configuration (`main.tf`)

```hcl
# environments/dev/main.tf

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }

  backend "s3" {
    bucket         = "bbws-terraform-state-dev"
    key            = "2-1-bbws-web-public/terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true
    dynamodb_table = "bbws-terraform-locks-dev"
  }
}

# Primary provider (eu-west-1 for DEV)
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = {
      Project     = "Buy Page"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Repository  = "2_1_bbws_infrastructure"
    }
  }
}

# Provider for us-east-1 (required for ACM & Lambda@Edge)
provider "aws" {
  alias   = "us_east_1"
  region  = "us-east-1"
  profile = var.aws_profile

  default_tags {
    tags = {
      Project     = "Buy Page"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Repository  = "2_1_bbws_infrastructure"
    }
  }
}

# ACM Certificate (must be in us-east-1)
module "acm" {
  source = "../../modules/acm"

  providers = {
    aws.us_east_1 = aws.us_east_1
  }

  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names
  hosted_zone_id            = var.hosted_zone_id
  environment               = var.environment
}

# Lambda@Edge Basic Auth (must be in us-east-1)
module "lambda_edge" {
  count  = var.basic_auth_enabled ? 1 : 0
  source = "../../modules/lambda-edge"

  providers = {
    aws.us_east_1 = aws.us_east_1
  }

  environment         = var.environment
  basic_auth_username = var.basic_auth_username
  basic_auth_password = var.basic_auth_password
}

# S3 Bucket (primary region)
module "s3_website" {
  source = "../../modules/s3-website"

  bucket_name                 = var.s3_bucket_name
  environment                 = var.environment
  cloudfront_distribution_arn = module.cloudfront.distribution_arn
}

# CloudFront Distribution
module "cloudfront" {
  source = "../../modules/cloudfront"

  environment                     = var.environment
  domain_name                     = var.domain_name
  s3_bucket_id                    = module.s3_website.bucket_id
  s3_bucket_regional_domain_name  = module.s3_website.bucket_regional_domain_name
  acm_certificate_arn             = module.acm.certificate_arn
  aliases                         = [var.domain_name]
  price_class                     = var.cloudfront_price_class
  lambda_edge_function_arn        = var.basic_auth_enabled ? module.lambda_edge[0].function_arn : ""
}

# Route 53 DNS
module "route53" {
  source = "../../modules/route53"

  hosted_zone_id            = var.hosted_zone_id
  domain_name               = var.domain_name
  cloudfront_domain_name    = module.cloudfront.distribution_domain_name
  cloudfront_hosted_zone_id = module.cloudfront.distribution_hosted_zone_id
}
```

#### 2.2 Variables (`variables.tf`)

```hcl
# environments/dev/variables.tf

variable "aws_region" {
  description = "AWS region for primary resources"
  type        = string
  default     = "eu-west-1"
}

variable "aws_profile" {
  description = "AWS CLI profile to use"
  type        = string
  default     = "Tebogo-dev"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "domain_name" {
  description = "Primary domain name"
  type        = string
}

variable "subject_alternative_names" {
  description = "Subject Alternative Names for ACM certificate"
  type        = list(string)
  default     = []
}

variable "hosted_zone_id" {
  description = "Route 53 hosted zone ID for kimmyai.io"
  type        = string
}

variable "s3_bucket_name" {
  description = "S3 bucket name for website hosting"
  type        = string
}

variable "cloudfront_price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_100"
}

variable "basic_auth_enabled" {
  description = "Enable Basic Authentication via Lambda@Edge"
  type        = bool
  default     = true
}

variable "basic_auth_username" {
  description = "Basic Auth username"
  type        = string
  default     = "admin"
}

variable "basic_auth_password" {
  description = "Basic Auth password"
  type        = string
  sensitive   = true
}
```

#### 2.3 Terraform Variables File (`terraform.tfvars`)

```hcl
# environments/dev/terraform.tfvars

# AWS Configuration
aws_region  = "eu-west-1"
aws_profile = "Tebogo-dev"
environment = "dev"

# Domain Configuration
domain_name               = "dev.kimmyai.io"
subject_alternative_names = []
hosted_zone_id            = "Z1234567890ABC"  # UPDATE with actual zone ID

# S3 Configuration
s3_bucket_name = "dev-kimmyai-web-public"

# CloudFront Configuration
cloudfront_price_class = "PriceClass_100"  # North America + Europe

# Basic Auth Configuration
basic_auth_enabled  = true
basic_auth_username = "admin"
basic_auth_password = "DevPassword123!"  # TODO: Use Secrets Manager
```

#### 2.4 Outputs (`outputs.tf`)

```hcl
# environments/dev/outputs.tf

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = module.cloudfront.distribution_id
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = module.cloudfront.distribution_domain_name
}

output "website_url" {
  description = "Website URL"
  value       = "https://${var.domain_name}"
}

output "s3_bucket_name" {
  description = "S3 bucket name"
  value       = module.s3_website.bucket_id
}

output "acm_certificate_arn" {
  description = "ACM certificate ARN"
  value       = module.acm.certificate_arn
}

output "route53_records" {
  description = "Route 53 DNS records"
  value = {
    a_record    = module.route53.a_record_name
    aaaa_record = module.route53.aaaa_record_name
  }
}

output "lambda_edge_function" {
  description = "Lambda@Edge function details"
  value = var.basic_auth_enabled ? {
    function_name = module.lambda_edge[0].function_name
    function_arn  = module.lambda_edge[0].function_arn
  } : null
}
```

---

### 3. Create SIT and PROD Configurations

**SIT** (`environments/sit/`): Similar structure to DEV

```hcl
# environments/sit/terraform.tfvars

aws_region  = "eu-west-1"
aws_profile = "Tebogo-sit"
environment = "sit"

domain_name               = "sit.kimmyai.io"
hosted_zone_id            = "Z1234567890ABC"
s3_bucket_name            = "sit-kimmyai-web-public"
cloudfront_price_class    = "PriceClass_100"

basic_auth_enabled  = true
basic_auth_username = "admin"
basic_auth_password = "SitPassword123!"
```

**PROD** (`environments/prod/`): Different region and no Basic Auth

```hcl
# environments/prod/terraform.tfvars

aws_region  = "af-south-1"  # Cape Town
aws_profile = "Tebogo-prod"
environment = "prod"

domain_name               = "kimmyai.io"
subject_alternative_names = ["*.kimmyai.io", "www.kimmyai.io"]
hosted_zone_id            = "Z1234567890ABC"
s3_bucket_name            = "prod-kimmyai-web-public"
cloudfront_price_class    = "PriceClass_All"  # Global distribution

basic_auth_enabled = false  # No Basic Auth in production
```

---

### 4. Create Makefile for Deployment Automation

**File**: `Makefile`

```makefile
# Makefile

.PHONY: help init plan apply destroy validate fmt clean deploy-app

# Environment variable (default: dev)
ENV ?= dev
ENV_DIR = environments/$(ENV)

help:
	@echo "Usage: make [target] ENV=[dev|sit|prod]"
	@echo ""
	@echo "Targets:"
	@echo "  init        - Initialize Terraform"
	@echo "  plan        - Run terraform plan"
	@echo "  apply       - Apply Terraform changes"
	@echo "  destroy     - Destroy infrastructure"
	@echo "  validate    - Validate Terraform code"
	@echo "  fmt         - Format Terraform code"
	@echo "  clean       - Clean Terraform cache"
	@echo "  deploy-app  - Deploy React app to S3 and invalidate CloudFront"

init:
	cd $(ENV_DIR) && terraform init

plan:
	cd $(ENV_DIR) && terraform plan -out=tfplan

apply:
	cd $(ENV_DIR) && terraform apply tfplan

destroy:
	cd $(ENV_DIR) && terraform destroy

validate:
	cd $(ENV_DIR) && terraform validate

fmt:
	terraform fmt -recursive

clean:
	find . -type d -name ".terraform" -exec rm -rf {} +
	find . -type f -name "*.tfstate*" -delete
	find . -type f -name "tfplan" -delete

deploy-app:
	@echo "Building React app..."
	cd ../2_1_bbws_web_public && npm run build
	@echo "Syncing to S3..."
	aws s3 sync ../2_1_bbws_web_public/dist/ s3://$(ENV)-kimmyai-web-public/ \
		--delete \
		--cache-control "public, max-age=31536000" \
		--exclude "index.html" \
		--profile Tebogo-$(ENV)
	aws s3 cp ../2_1_bbws_web_public/dist/index.html s3://$(ENV)-kimmyai-web-public/ \
		--cache-control "no-cache" \
		--profile Tebogo-$(ENV)
	@echo "Invalidating CloudFront cache..."
	aws cloudfront create-invalidation \
		--distribution-id $$(cd $(ENV_DIR) && terraform output -raw cloudfront_distribution_id) \
		--paths "/*" \
		--profile Tebogo-$(ENV)
	@echo "Deployment complete!"
```

---

### 5. Create README

**File**: `README.md`

```markdown
# 2_1_bbws_infrastructure

Terraform infrastructure for BBWS Customer Portal Public - Buy Page.

## Architecture

- **S3**: Static website hosting (origin)
- **CloudFront**: CDN distribution
- **Route 53**: DNS management
- **ACM**: SSL/TLS certificates
- **Lambda@Edge**: Basic Authentication (DEV/SIT only)

## Environments

| Environment | Domain | Region | Basic Auth |
|-------------|--------|--------|------------|
| **DEV** | dev.kimmyai.io | eu-west-1 | ✅ Enabled |
| **SIT** | sit.kimmyai.io | eu-west-1 | ✅ Enabled |
| **PROD** | kimmyai.io | af-south-1 | ❌ Disabled |

## Prerequisites

1. **AWS CLI** configured with profiles:
   - `Tebogo-dev` (DEV account)
   - `Tebogo-sit` (SIT account)
   - `Tebogo-prod` (PROD account)

2. **Terraform** 1.6+ installed

3. **Route 53 Hosted Zone** for `kimmyai.io` exists

4. **Terraform State Backend** (S3 + DynamoDB):
   \`\`\`bash
   # DEV
   aws s3 mb s3://bbws-terraform-state-dev --region eu-west-1
   aws dynamodb create-table \
     --table-name bbws-terraform-locks-dev \
     --attribute-definitions AttributeName=LockID,AttributeType=S \
     --key-schema AttributeName=LockID,KeyType=HASH \
     --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
     --region eu-west-1
   \`\`\`

## Deployment

### Initial Infrastructure Deployment

\`\`\`bash
# DEV environment
make init ENV=dev
make plan ENV=dev
make apply ENV=dev

# SIT environment (after DEV verified)
make init ENV=sit
make plan ENV=sit
make apply ENV=sit

# PROD environment (after SIT verified)
make init ENV=prod
make plan ENV=prod
make apply ENV=prod  # Requires manual approval
\`\`\`

### Deploy React Application

\`\`\`bash
# Deploy to DEV
make deploy-app ENV=dev

# Deploy to SIT
make deploy-app ENV=sit

# Deploy to PROD
make deploy-app ENV=prod
\`\`\`

## Module Structure

\`\`\`
modules/
├── s3-website/       - S3 bucket for static hosting
├── cloudfront/       - CloudFront CDN distribution
├── route53/          - Route 53 DNS records
├── acm/              - ACM SSL/TLS certificate
└── lambda-edge/      - Lambda@Edge Basic Auth
\`\`\`

## Troubleshooting

### Certificate Validation Stuck

\`\`\`bash
# Check validation records in Route 53
aws route53 list-resource-record-sets --hosted-zone-id Z1234567890ABC

# Check certificate status
aws acm describe-certificate \
  --certificate-arn arn:aws:acm:us-east-1:123456789012:certificate/abc123 \
  --region us-east-1
\`\`\`

### CloudFront Not Serving Latest Content

\`\`\`bash
# Create CloudFront invalidation
aws cloudfront create-invalidation \
  --distribution-id E1234567890ABC \
  --paths "/*"
\`\`\`

### Basic Auth Not Working

\`\`\`bash
# Check Lambda@Edge logs (check region where request was processed)
aws logs tail /aws/lambda/dev-basic-auth --follow --region us-east-1
\`\`\`

## Security Notes

- S3 bucket has all public access blocked (OAC used)
- CloudFront enforces HTTPS (HTTP redirects to HTTPS)
- TLS 1.2+ only
- Basic Auth passwords stored in terraform.tfvars (TODO: migrate to Secrets Manager)

## Cost Estimate (Monthly)

| Service | DEV | PROD |
|---------|-----|------|
| S3 | $1 | $5 |
| CloudFront | $5 | $50 |
| Route 53 | $0.50 | $0.50 |
| Lambda@Edge | $1 | $0 |
| **Total** | **~$7.50** | **~$55.50** |
\`\`\`

---

### 6. Create .gitignore

**File**: `.gitignore`

```
# Terraform
.terraform/
*.tfstate
*.tfstate.*
tfplan
*.tfvars.backup

# Lambda packages
lambda_function.zip
node_modules/

# OS
.DS_Store
Thumbs.db

# IDE
.vscode/
.idea/
*.swp
```

---

## Deliverables

### Environment Configurations
- [x] `environments/dev/main.tf`
- [x] `environments/dev/variables.tf`
- [x] `environments/dev/terraform.tfvars`
- [x] `environments/dev/outputs.tf`
- [x] `environments/sit/` (similar structure)
- [x] `environments/prod/` (similar structure)

### Automation & Documentation
- [x] `Makefile` - Deployment automation
- [x] `README.md` - Comprehensive documentation
- [x] `.gitignore` - Git ignore rules

---

## Success Criteria

- [ ] All environment configurations created (dev, sit, prod)
- [ ] Terraform backend configured for each environment
- [ ] Makefile created with deployment automation
- [ ] README documentation complete
- [ ] `terraform init` succeeds for all environments
- [ ] `terraform plan` succeeds for DEV environment
- [ ] output.md created with deployment guide

---

## Testing

### Validation

```bash
# Validate all modules
make validate ENV=dev

# Format check
make fmt
```

### DEV Deployment Test

```bash
# Initialize
make init ENV=dev

# Plan (verify resources)
make plan ENV=dev

# Expected resources: ~20 resources
# - S3 bucket + configurations (6 resources)
# - CloudFront + OAC (2 resources)
# - Route 53 records (2 resources)
# - ACM certificate + validation (3 resources)
# - Lambda@Edge + IAM (4 resources)
```

### End-to-End Test (After Apply)

```bash
# 1. Deploy infrastructure
make apply ENV=dev

# 2. Deploy React app
make deploy-app ENV=dev

# 3. Test in browser
open https://dev.kimmyai.io/buy

# Expected:
# - Basic Auth prompt appears
# - Enter credentials (admin / DevPassword123!)
# - Buy page loads
# - Check browser console (no errors)
# - Verify HTTPS (lock icon)
```

---

## Deployment Checklist

### Pre-Deployment
- [ ] Route 53 hosted zone ID verified
- [ ] AWS profiles configured (Tebogo-dev, Tebogo-sit, Tebogo-prod)
- [ ] Terraform state backend created (S3 + DynamoDB)
- [ ] terraform.tfvars reviewed (especially passwords)

### DEV Deployment
- [ ] `make init ENV=dev`
- [ ] `make plan ENV=dev` (review plan)
- [ ] `make apply ENV=dev` (apply infrastructure)
- [ ] Wait for CloudFront deployment (~15-30 min)
- [ ] `make deploy-app ENV=dev` (deploy React app)
- [ ] Test website (https://dev.kimmyai.io)

### SIT Deployment (After DEV Verified)
- [ ] `make init ENV=sit`
- [ ] `make plan ENV=sit`
- [ ] `make apply ENV=sit`
- [ ] `make deploy-app ENV=sit`
- [ ] Test website (https://sit.kimmyai.io)

### PROD Deployment (After SIT Verified)
- [ ] `make init ENV=prod`
- [ ] `make plan ENV=prod`
- [ ] **Manual approval required**
- [ ] `make apply ENV=prod`
- [ ] `make deploy-app ENV=prod`
- [ ] Test website (https://kimmyai.io)

---

## Notes

- CloudFront deployment takes 15-30 minutes
- Lambda@Edge replication takes 5-10 minutes
- DNS propagation takes 5-60 minutes
- First deployment to new environment will be slowest

---

**Created**: 2025-12-30
**Worker**: worker-5-root-module
**Status**: PENDING
