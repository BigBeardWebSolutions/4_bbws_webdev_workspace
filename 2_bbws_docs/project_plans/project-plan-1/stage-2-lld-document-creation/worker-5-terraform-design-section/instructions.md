# Worker 2-5: Terraform Design Section

**Worker ID**: worker-2-5-terraform-design-section
**Stage**: Stage 2 - LLD Document Creation
**Status**: PENDING
**Estimated Effort**: High
**Dependencies**: Stage 1 Worker 3-3, Worker 4-4

---

## Objective

Create comprehensive Terraform module design section (Section 6) of the LLD document with module specifications, variable definitions, state management, and deployment patterns.

---

## Input Documents

1. **Stage 1 Outputs**:
   - `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/project-plan-1/stage-1-requirements-analysis/worker-3-naming-convention-analysis/output.md` (Terraform naming conventions)
   - `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/project-plan-1/stage-1-requirements-analysis/worker-4-environment-configuration-analysis/output.md` (Terraform backend, .tfvars examples)

2. **Specification Documents**:
   - `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/specs/2.1.8_LLD_S3_and_DynamoDB_Spec.md` (Section 5: Terraform Module Structure)

---

## Deliverables

Create `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/project-plan-1/stage-2-lld-document-creation/worker-5-terraform-design-section/output.md` containing:

### Section 6: Terraform Module Design

#### 6.1 Overview
- Purpose of Terraform modules
- Module design philosophy (reusable, environment-agnostic)
- State management strategy (separate state per component)

#### 6.2 Module: `dynamodb_table`

**6.2.1 Module Purpose**
- Create DynamoDB tables with GSIs
- Configure PITR, backups, and replication
- Apply tags consistently

**6.2.2 Module Structure**
```
modules/dynamodb_table/
├── main.tf
├── variables.tf
├── outputs.tf
└── README.md
```

**6.2.3 Input Variables**

Document all variables with type, description, and default:

```hcl
variable "table_name" {
  type        = string
  description = "Name of the DynamoDB table"
}

variable "partition_key" {
  type        = string
  description = "Partition key attribute name"
}

variable "sort_key" {
  type        = string
  description = "Sort key attribute name (optional)"
  default     = null
}

variable "attributes" {
  type = list(object({
    name = string
    type = string
  }))
  description = "List of attribute definitions"
}

variable "global_secondary_indexes" {
  type = list(object({
    name            = string
    partition_key   = string
    sort_key        = string
    projection_type = string
  }))
  description = "List of GSI definitions"
  default     = []
}

variable "point_in_time_recovery" {
  type        = bool
  description = "Enable PITR"
  default     = true
}

variable "enable_backup" {
  type        = bool
  description = "Enable automated backups"
  default     = false
}

variable "enable_replication" {
  type        = bool
  description = "Enable cross-region replication"
  default     = false
}

variable "replica_region" {
  type        = string
  description = "DR region for replication"
  default     = "eu-west-1"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the table"
}
```

**6.2.4 Outputs**

```hcl
output "table_name" {
  value       = aws_dynamodb_table.this.name
  description = "DynamoDB table name"
}

output "table_arn" {
  value       = aws_dynamodb_table.this.arn
  description = "DynamoDB table ARN"
}

output "table_stream_arn" {
  value       = aws_dynamodb_table.this.stream_arn
  description = "DynamoDB table stream ARN"
}
```

**6.2.5 Resource Configuration**

Provide detailed main.tf structure:
- `aws_dynamodb_table` resource
- Conditional replication (count based on `enable_replication`)
- Conditional backup plan (count based on `enable_backup`)

#### 6.3 Module: `s3_bucket`

**6.3.1 Module Purpose**
- Create S3 buckets with versioning and encryption
- Configure replication for DR
- Apply bucket policies

**6.3.2 Module Structure**
(same as 6.2.2)

**6.3.3 Input Variables**

```hcl
variable "bucket_name" {
  type        = string
  description = "S3 bucket name"
}

variable "enable_versioning" {
  type        = bool
  description = "Enable versioning"
  default     = true
}

variable "enable_logging" {
  type        = bool
  description = "Enable access logging"
  default     = true
}

variable "logging_bucket" {
  type        = string
  description = "Bucket for access logs"
  default     = ""
}

variable "enable_replication" {
  type        = bool
  description = "Enable cross-region replication"
  default     = false
}

variable "replica_region" {
  type        = string
  description = "DR region for replication"
  default     = "eu-west-1"
}

variable "replica_bucket_name" {
  type        = string
  description = "DR bucket name"
  default     = ""
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the bucket"
}
```

**6.3.4 Outputs**

```hcl
output "bucket_name" {
  value       = aws_s3_bucket.this.id
  description = "S3 bucket name"
}

output "bucket_arn" {
  value       = aws_s3_bucket.this.arn
  description = "S3 bucket ARN"
}

output "bucket_regional_domain_name" {
  value       = aws_s3_bucket.this.bucket_regional_domain_name
  description = "S3 bucket regional domain name"
}
```

**6.3.5 Resource Configuration**
- `aws_s3_bucket` resource
- `aws_s3_bucket_versioning` resource
- `aws_s3_bucket_server_side_encryption_configuration` (AES-256)
- `aws_s3_bucket_public_access_block` (block all public access)
- Conditional replication configuration

#### 6.4 Root Module Structure

**6.4.1 DynamoDB Repository Root Module**

```
2_1_bbws_dynamodb_schemas/terraform/
├── modules/
│   └── dynamodb_table/
├── main.tf
├── variables.tf
├── outputs.tf
├── backend.tf
└── environments/
    ├── dev.tfvars
    ├── sit.tfvars
    └── prod.tfvars
```

**6.4.2 main.tf Structure**

```hcl
module "tenants_table" {
  source = "./modules/dynamodb_table"

  table_name          = "tenants"
  partition_key       = "PK"
  sort_key            = "SK"
  attributes          = [...]
  global_secondary_indexes = [...]
  point_in_time_recovery   = true
  enable_backup            = var.enable_backup
  enable_replication       = var.enable_replication
  replica_region           = var.replica_region
  tags                     = var.tags
}

module "products_table" {
  source = "./modules/dynamodb_table"
  ...
}

module "campaigns_table" {
  source = "./modules/dynamodb_table"
  ...
}
```

**6.4.3 S3 Repository Root Module**

(same structure as 6.4.1 but for S3)

#### 6.5 Environment Configuration Files

**6.5.1 dev.tfvars**

```hcl
# DEV Environment Configuration
aws_region = "af-south-1"
environment = "dev"
aws_account_id = "536580886816"

# DynamoDB Configuration
enable_backup = false
enable_replication = false

# S3 Configuration
bucket_name = "bbws-templates-dev"
enable_logging = true
logging_bucket = "bbws-logs-dev"

# Tags
tags = {
  Environment  = "dev"
  Project      = "bbws-customer-portal-public"
  Owner        = "platform-team@bbws.com"
  CostCenter   = "engineering"
  ManagedBy    = "terraform"
  BackupPolicy = "none"
  Component    = "infrastructure"
}
```

**6.5.2 sit.tfvars**
(same structure with SIT values)

**6.5.3 prod.tfvars**

```hcl
# PROD Environment Configuration
aws_region = "af-south-1"
environment = "prod"
aws_account_id = "093646564004"

# DynamoDB Configuration
enable_backup = true
enable_replication = true
replica_region = "eu-west-1"

# S3 Configuration
bucket_name = "bbws-templates-prod"
enable_logging = true
logging_bucket = "bbws-logs-prod"
enable_replication = true
replica_bucket_name = "bbws-templates-prod-dr-eu-west-1"

# Tags
tags = {
  Environment  = "prod"
  Project      = "bbws-customer-portal-public"
  Owner        = "platform-team@bbws.com"
  CostCenter   = "engineering"
  ManagedBy    = "terraform"
  BackupPolicy = "hourly"
  Component    = "infrastructure"
}
```

#### 6.6 Backend Configuration

**6.6.1 Backend Strategy**
- Separate S3 state bucket per environment
- DynamoDB lock table per environment
- State file naming: `{component}/terraform.tfstate`

**6.6.2 backend.tf Example**

```hcl
terraform {
  backend "s3" {
    bucket         = "bbws-terraform-state-dev"
    key            = "dynamodb-schemas/terraform.tfstate"
    region         = "af-south-1"
    dynamodb_table = "bbws-terraform-locks-dev"
    encrypt        = true
  }

  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

#### 6.7 Tagging Strategy

Document the 7 mandatory tags from Worker 3-3:
1. `Environment`: dev, sit, prod
2. `Project`: bbws-customer-portal-public
3. `Owner`: platform-team@bbws.com
4. `CostCenter`: engineering
5. `ManagedBy`: terraform
6. `BackupPolicy`: none, hourly, daily
7. `Component`: infrastructure, dynamodb, s3

#### 6.8 Deployment Workflow

**6.8.1 Initialization**
```bash
terraform init -backend-config=environments/dev.tfvars
```

**6.8.2 Planning**
```bash
terraform plan -var-file=environments/dev.tfvars -out=tfplan
```

**6.8.3 Application**
```bash
terraform apply tfplan
```

**6.8.4 Destroy (emergency only)**
```bash
terraform destroy -var-file=environments/dev.tfvars
```

---

## Quality Criteria

- [ ] Both modules (dynamodb_table, s3_bucket) fully specified
- [ ] All variables documented with types and defaults
- [ ] All outputs documented
- [ ] All 3 .tfvars files complete and accurate
- [ ] Backend configuration documented
- [ ] Tagging strategy matches Worker 3-3
- [ ] Deployment workflow clear
- [ ] No placeholder text

---

## Output Format

Write output to `output.md` using markdown format with proper headings and code blocks.

**Target Length**: 1,000-1,200 lines

---

## Special Instructions

1. **Use Stage 1 Naming**:
   - Module names from Worker 3-3
   - Variable names consistent with AWS conventions
   - Tag names from Worker 3-3

2. **Cross-Reference Worker 4-4**:
   - Use exact .tfvars examples from Worker 4-4
   - Use backend config from Worker 4-4

3. **Code Quality**:
   - Use proper HCL formatting
   - Include comments in code blocks
   - Use consistent indentation

---

**Worker Created**: 2025-12-25
**Execution Mode**: Parallel (with 5 other Stage 2 workers)
