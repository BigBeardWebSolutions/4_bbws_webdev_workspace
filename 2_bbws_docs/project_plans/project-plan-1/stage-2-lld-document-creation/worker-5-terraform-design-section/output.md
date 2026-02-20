# Section 6: Terraform Module Design

**LLD Document**: `2.1.8_LLD_S3_and_DynamoDB.md`
**Section**: 6 - Terraform Module Design
**Version**: 1.0
**Date**: 2025-12-25
**Worker**: worker-2-5-terraform-design-section

---

## 6.1 Overview

### 6.1.1 Purpose of Terraform Modules

This section defines the Terraform Infrastructure as Code (IaC) architecture for deploying and managing DynamoDB tables and S3 buckets across multiple environments (DEV, SIT, PROD). The Terraform modules are designed to provide:

1. **Reusability**: Generic modules that can be instantiated multiple times with different configurations
2. **Environment Agnostic**: Same code runs across all environments with only parameter differences
3. **State Isolation**: Separate state management per environment and component
4. **Automation**: Full CI/CD integration with approval gates
5. **Disaster Recovery**: Built-in support for cross-region replication and backups

### 6.1.2 Module Design Philosophy

The Terraform design follows these core principles:

**1. Separation of Concerns**
- Each resource type (DynamoDB table, S3 bucket) has its own module
- Modules are loosely coupled and independently deployable
- Clear interfaces defined through variables and outputs

**2. Environment-Agnostic Design**
- Modules contain no hardcoded values
- All environment-specific configuration via `.tfvars` files
- Same module code deployed to DEV, SIT, and PROD
- Account isolation prevents cross-environment impact

**3. Progressive Hardening**
- DEV: Minimal protection, fast iteration
- SIT: Medium protection, quality gates
- PROD: Maximum protection (deletion protection, replication, hourly backups)

**4. Compliance and Governance**
- Mandatory tagging on all resources
- Encryption at rest and in transit
- PITR enabled on all DynamoDB tables
- Public access blocked on all S3 buckets

**5. Cost Optimization**
- On-demand capacity mode for DynamoDB (no over-provisioning)
- Lifecycle policies for S3 version management
- Environment-specific backup retention periods
- Budget alerts configured per environment

### 6.1.3 State Management Strategy

**State Isolation Approach:**

```
Separate S3 backend per environment
├── DEV: s3://bbws-terraform-state-dev/
├── SIT: s3://bbws-terraform-state-sit/
└── PROD: s3://bbws-terraform-state-prod/

Separate state file per component (blast radius reduction)
├── 2_1_bbws_dynamodb_schemas/
│   ├── tenants/terraform.tfstate
│   ├── products/terraform.tfstate
│   └── campaigns/terraform.tfstate
└── 2_1_bbws_s3_schemas/
    └── templates/terraform.tfstate

DynamoDB lock table per environment
├── terraform-state-lock-dev
├── terraform-state-lock-sit
└── terraform-state-lock-prod
```

**Benefits:**
- **Environment Isolation**: DEV state changes cannot affect PROD
- **Component Isolation**: Table-level state prevents accidental changes to unrelated resources
- **Concurrent Development**: Multiple developers can work on different components
- **Rollback Capability**: Component-level rollback without affecting entire infrastructure
- **Reduced Blast Radius**: Issues contained to single component

---

## 6.2 Module: `dynamodb_table`

### 6.2.1 Module Purpose

The `dynamodb_table` module provides a reusable abstraction for creating DynamoDB tables with:

1. **Flexible Schema Definition**: Configurable partition key, sort key, and attributes
2. **Global Secondary Indexes**: Support for multiple GSIs with custom projections
3. **Point-in-Time Recovery**: PITR enabled for disaster recovery
4. **Automated Backups**: Integration with AWS Backup for scheduled backups
5. **Cross-Region Replication**: Optional replication to DR region (PROD only)
6. **Consistent Tagging**: Mandatory tags applied to all tables
7. **DynamoDB Streams**: Change data capture for auditing and event-driven workflows

### 6.2.2 Module Structure

```
modules/dynamodb_table/
├── main.tf           # Primary resource definitions
├── variables.tf      # Input variable declarations
├── outputs.tf        # Output value definitions
└── README.md         # Module documentation and usage examples
```

**File Descriptions:**

- **main.tf**: Contains `aws_dynamodb_table` resource, conditional replication configuration, and backup plan
- **variables.tf**: Defines all input parameters with types, descriptions, and defaults
- **outputs.tf**: Exports table name, ARN, stream ARN, and GSI details
- **README.md**: Usage examples, prerequisites, and integration patterns

### 6.2.3 Input Variables

```hcl
# ============================================================================
# REQUIRED VARIABLES
# ============================================================================

variable "table_name" {
  type        = string
  description = "Name of the DynamoDB table (e.g., 'tenants', 'products', 'campaigns')"

  validation {
    condition     = can(regex("^[a-z][a-z0-9_]*$", var.table_name))
    error_message = "Table name must start with a lowercase letter and contain only lowercase letters, numbers, and underscores."
  }
}

variable "partition_key" {
  type        = string
  description = "Partition key attribute name (e.g., 'PK')"
}

variable "partition_key_type" {
  type        = string
  description = "Data type of partition key (S = String, N = Number, B = Binary)"
  default     = "S"

  validation {
    condition     = contains(["S", "N", "B"], var.partition_key_type)
    error_message = "Partition key type must be S, N, or B."
  }
}

variable "attributes" {
  type = list(object({
    name = string
    type = string  # S = String, N = Number, B = Binary
  }))
  description = "List of attribute definitions for keys and GSI attributes"

  validation {
    condition     = alltrue([for attr in var.attributes : contains(["S", "N", "B"], attr.type)])
    error_message = "All attribute types must be S, N, or B."
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the DynamoDB table (must include mandatory tags)"

  validation {
    condition = alltrue([
      contains(keys(var.tags), "Environment"),
      contains(keys(var.tags), "Project"),
      contains(keys(var.tags), "Owner"),
      contains(keys(var.tags), "CostCenter"),
      contains(keys(var.tags), "ManagedBy"),
      contains(keys(var.tags), "Component")
    ])
    error_message = "Tags must include: Environment, Project, Owner, CostCenter, ManagedBy, Component."
  }
}

# ============================================================================
# OPTIONAL VARIABLES
# ============================================================================

variable "sort_key" {
  type        = string
  description = "Sort key attribute name (optional, e.g., 'SK')"
  default     = null
}

variable "sort_key_type" {
  type        = string
  description = "Data type of sort key (S = String, N = Number, B = Binary)"
  default     = "S"

  validation {
    condition     = contains(["S", "N", "B"], var.sort_key_type)
    error_message = "Sort key type must be S, N, or B."
  }
}

variable "billing_mode" {
  type        = string
  description = "Billing mode for the table (PROVISIONED or PAY_PER_REQUEST)"
  default     = "PAY_PER_REQUEST"  # On-demand mode (mandatory per CLAUDE.md)

  validation {
    condition     = var.billing_mode == "PAY_PER_REQUEST"
    error_message = "Billing mode must be PAY_PER_REQUEST (on-demand) per CLAUDE.md requirements."
  }
}

variable "global_secondary_indexes" {
  type = list(object({
    name               = string
    hash_key           = string
    range_key          = string
    projection_type    = string  # ALL, KEYS_ONLY, INCLUDE
    non_key_attributes = list(string)
  }))
  description = "List of Global Secondary Index definitions"
  default     = []

  validation {
    condition = alltrue([
      for gsi in var.global_secondary_indexes :
      contains(["ALL", "KEYS_ONLY", "INCLUDE"], gsi.projection_type)
    ])
    error_message = "GSI projection_type must be ALL, KEYS_ONLY, or INCLUDE."
  }
}

variable "point_in_time_recovery" {
  type        = bool
  description = "Enable point-in-time recovery (PITR) for disaster recovery"
  default     = true  # Mandatory for all environments
}

variable "stream_enabled" {
  type        = bool
  description = "Enable DynamoDB Streams for change data capture"
  default     = true  # Required for auditing per CLAUDE.md
}

variable "stream_view_type" {
  type        = string
  description = "Stream view type (KEYS_ONLY, NEW_IMAGE, OLD_IMAGE, NEW_AND_OLD_IMAGES)"
  default     = "NEW_AND_OLD_IMAGES"

  validation {
    condition = contains([
      "KEYS_ONLY",
      "NEW_IMAGE",
      "OLD_IMAGE",
      "NEW_AND_OLD_IMAGES"
    ], var.stream_view_type)
    error_message = "Stream view type must be one of: KEYS_ONLY, NEW_IMAGE, OLD_IMAGE, NEW_AND_OLD_IMAGES."
  }
}

variable "enable_backup" {
  type        = bool
  description = "Enable AWS Backup for automated backups"
  default     = false  # Set to true in SIT/PROD via tfvars
}

variable "backup_retention_days" {
  type        = number
  description = "Number of days to retain backups (7 for DEV, 14 for SIT, 90 for PROD)"
  default     = 7

  validation {
    condition     = var.backup_retention_days >= 1 && var.backup_retention_days <= 365
    error_message = "Backup retention must be between 1 and 365 days."
  }
}

variable "backup_schedule" {
  type        = string
  description = "Cron expression for backup schedule (e.g., 'cron(0 */1 * * ? *)' for hourly)"
  default     = "cron(0 2 * * ? *)"  # Daily at 2 AM UTC
}

variable "enable_deletion_protection" {
  type        = bool
  description = "Enable deletion protection (PROD only)"
  default     = false  # Set to true in PROD via tfvars
}

variable "enable_replication" {
  type        = bool
  description = "Enable cross-region replication (PROD only)"
  default     = false  # Set to true in PROD via tfvars
}

variable "replica_region" {
  type        = string
  description = "AWS region for cross-region replication (eu-west-1 for PROD DR)"
  default     = "eu-west-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-\\d{1}$", var.replica_region))
    error_message = "Replica region must be a valid AWS region format (e.g., eu-west-1)."
  }
}

variable "ttl_enabled" {
  type        = bool
  description = "Enable Time-to-Live (TTL) for automatic item expiration"
  default     = false  # Not required for current use cases
}

variable "ttl_attribute_name" {
  type        = string
  description = "Attribute name for TTL (must be a Number attribute)"
  default     = "expiryTime"
}
```

### 6.2.4 Outputs

```hcl
# ============================================================================
# TABLE OUTPUTS
# ============================================================================

output "table_name" {
  value       = aws_dynamodb_table.this.name
  description = "Name of the DynamoDB table"
}

output "table_id" {
  value       = aws_dynamodb_table.this.id
  description = "ID of the DynamoDB table (same as name)"
}

output "table_arn" {
  value       = aws_dynamodb_table.this.arn
  description = "ARN of the DynamoDB table for IAM policy references"
}

output "table_stream_arn" {
  value       = var.stream_enabled ? aws_dynamodb_table.this.stream_arn : null
  description = "ARN of the DynamoDB table stream (null if streams disabled)"
}

output "table_stream_label" {
  value       = var.stream_enabled ? aws_dynamodb_table.this.stream_label : null
  description = "Stream label of the DynamoDB table"
}

# ============================================================================
# GSI OUTPUTS
# ============================================================================

output "global_secondary_indexes" {
  value = [
    for gsi in var.global_secondary_indexes : {
      name      = gsi.name
      hash_key  = gsi.hash_key
      range_key = gsi.range_key
    }
  ]
  description = "List of Global Secondary Indexes created"
}

output "gsi_arns" {
  value = {
    for gsi in var.global_secondary_indexes :
    gsi.name => "${aws_dynamodb_table.this.arn}/index/${gsi.name}"
  }
  description = "Map of GSI names to ARNs for IAM policy references"
}

# ============================================================================
# BACKUP OUTPUTS
# ============================================================================

output "backup_plan_id" {
  value       = var.enable_backup ? aws_backup_plan.this[0].id : null
  description = "ID of the AWS Backup plan (null if backups disabled)"
}

output "backup_vault_name" {
  value       = var.enable_backup ? aws_backup_vault.this[0].name : null
  description = "Name of the AWS Backup vault (null if backups disabled)"
}

# ============================================================================
# REPLICATION OUTPUTS
# ============================================================================

output "replica_table_arn" {
  value       = var.enable_replication ? aws_dynamodb_table.this.replica[0].arn : null
  description = "ARN of the replica table in DR region (null if replication disabled)"
}

output "replica_region" {
  value       = var.enable_replication ? var.replica_region : null
  description = "AWS region of the replica table (null if replication disabled)"
}
```

### 6.2.5 Resource Configuration

#### 6.2.5.1 Main DynamoDB Table Resource

```hcl
# ============================================================================
# DYNAMODB TABLE
# ============================================================================

resource "aws_dynamodb_table" "this" {
  name             = var.table_name
  billing_mode     = var.billing_mode
  hash_key         = var.partition_key
  range_key        = var.sort_key
  stream_enabled   = var.stream_enabled
  stream_view_type = var.stream_enabled ? var.stream_view_type : null

  # Deletion protection (PROD only)
  deletion_protection_enabled = var.enable_deletion_protection

  # Partition key attribute
  attribute {
    name = var.partition_key
    type = var.partition_key_type
  }

  # Sort key attribute (conditional)
  dynamic "attribute" {
    for_each = var.sort_key != null ? [1] : []
    content {
      name = var.sort_key
      type = var.sort_key_type
    }
  }

  # Additional attributes (for GSIs)
  dynamic "attribute" {
    for_each = var.attributes
    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }

  # Global Secondary Indexes
  dynamic "global_secondary_index" {
    for_each = var.global_secondary_indexes
    content {
      name            = global_secondary_index.value.name
      hash_key        = global_secondary_index.value.hash_key
      range_key       = global_secondary_index.value.range_key
      projection_type = global_secondary_index.value.projection_type

      # Include non-key attributes for INCLUDE projection type
      non_key_attributes = (
        global_secondary_index.value.projection_type == "INCLUDE"
        ? global_secondary_index.value.non_key_attributes
        : null
      )
    }
  }

  # Point-in-Time Recovery
  point_in_time_recovery {
    enabled = var.point_in_time_recovery
  }

  # Time-to-Live (optional)
  dynamic "ttl" {
    for_each = var.ttl_enabled ? [1] : []
    content {
      enabled        = true
      attribute_name = var.ttl_attribute_name
    }
  }

  # Cross-region replication (PROD only)
  dynamic "replica" {
    for_each = var.enable_replication ? [1] : []
    content {
      region_name            = var.replica_region
      point_in_time_recovery = var.point_in_time_recovery
    }
  }

  # Server-side encryption (AWS-managed KMS key)
  server_side_encryption {
    enabled     = true
    kms_key_arn = null  # Use AWS-managed key
  }

  # Tags
  tags = merge(
    var.tags,
    {
      Name = var.table_name
      Type = "DynamoDB"
    }
  )

  # Lifecycle rules
  lifecycle {
    prevent_destroy = false  # Set to true in PROD via terraform override
  }
}

# ============================================================================
# AWS BACKUP CONFIGURATION (Conditional)
# ============================================================================

# Backup Vault
resource "aws_backup_vault" "this" {
  count = var.enable_backup ? 1 : 0

  name        = "${var.table_name}-backup-vault"
  kms_key_arn = null  # Use AWS-managed key

  tags = merge(
    var.tags,
    {
      Name      = "${var.table_name}-backup-vault"
      Component = "backup"
    }
  )
}

# Backup Plan
resource "aws_backup_plan" "this" {
  count = var.enable_backup ? 1 : 0

  name = "${var.table_name}-backup-plan"

  rule {
    rule_name         = "${var.table_name}-backup-rule"
    target_vault_name = aws_backup_vault.this[0].name
    schedule          = var.backup_schedule

    lifecycle {
      delete_after = var.backup_retention_days
    }

    # Copy to DR region (PROD only)
    dynamic "copy_action" {
      for_each = var.enable_replication ? [1] : []
      content {
        destination_vault_arn = aws_backup_vault.replica[0].arn

        lifecycle {
          delete_after = var.backup_retention_days
        }
      }
    }
  }

  tags = merge(
    var.tags,
    {
      Name      = "${var.table_name}-backup-plan"
      Component = "backup"
    }
  )
}

# Backup Selection
resource "aws_backup_selection" "this" {
  count = var.enable_backup ? 1 : 0

  name         = "${var.table_name}-backup-selection"
  iam_role_arn = aws_iam_role.backup[0].arn
  plan_id      = aws_backup_plan.this[0].id

  resources = [
    aws_dynamodb_table.this.arn
  ]
}

# Backup IAM Role
resource "aws_iam_role" "backup" {
  count = var.enable_backup ? 1 : 0

  name = "${var.table_name}-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name      = "${var.table_name}-backup-role"
      Component = "iam"
    }
  )
}

# Attach AWS-managed backup policy
resource "aws_iam_role_policy_attachment" "backup" {
  count = var.enable_backup ? 1 : 0

  role       = aws_iam_role.backup[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

# Attach restore policy
resource "aws_iam_role_policy_attachment" "restore" {
  count = var.enable_backup ? 1 : 0

  role       = aws_iam_role.backup[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

# ============================================================================
# DR REGION BACKUP VAULT (Conditional)
# ============================================================================

# Replica backup vault in DR region
resource "aws_backup_vault" "replica" {
  count    = var.enable_replication ? 1 : 0
  provider = aws.replica

  name        = "${var.table_name}-backup-vault-dr"
  kms_key_arn = null  # Use AWS-managed key

  tags = merge(
    var.tags,
    {
      Name      = "${var.table_name}-backup-vault-dr"
      Component = "backup"
      Region    = var.replica_region
    }
  )
}

# ============================================================================
# CLOUDWATCH ALARMS (Optional - for monitoring)
# ============================================================================

# Alarm for user errors (conditional query errors)
resource "aws_cloudwatch_metric_alarm" "user_errors" {
  alarm_name          = "${var.table_name}-user-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UserErrors"
  namespace           = "AWS/DynamoDB"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Alert when user errors exceed threshold"
  alarm_actions       = []  # Set via environment-specific configuration

  dimensions = {
    TableName = aws_dynamodb_table.this.name
  }

  tags = merge(
    var.tags,
    {
      Name      = "${var.table_name}-user-errors-alarm"
      Component = "monitoring"
    }
  )
}

# Alarm for system errors
resource "aws_cloudwatch_metric_alarm" "system_errors" {
  alarm_name          = "${var.table_name}-system-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "SystemErrors"
  namespace           = "AWS/DynamoDB"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Alert on any system errors"
  alarm_actions       = []  # Set via environment-specific configuration

  dimensions = {
    TableName = aws_dynamodb_table.this.name
  }

  tags = merge(
    var.tags,
    {
      Name      = "${var.table_name}-system-errors-alarm"
      Component = "monitoring"
    }
  )
}

# Alarm for throttled requests
resource "aws_cloudwatch_metric_alarm" "throttled_requests" {
  alarm_name          = "${var.table_name}-throttled-requests"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UserErrors"
  namespace           = "AWS/DynamoDB"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Alert when throttled requests exceed threshold"
  alarm_actions       = []  # Set via environment-specific configuration

  dimensions = {
    TableName = aws_dynamodb_table.this.name
  }

  tags = merge(
    var.tags,
    {
      Name      = "${var.table_name}-throttled-requests-alarm"
      Component = "monitoring"
    }
  )
}
```

---

## 6.3 Module: `s3_bucket`

### 6.3.1 Module Purpose

The `s3_bucket` module provides a reusable abstraction for creating S3 buckets with:

1. **Security by Default**: Public access blocked, encryption enabled
2. **Versioning**: Track template changes over time
3. **Access Logging**: Audit trail for bucket access (SIT/PROD)
4. **Cross-Region Replication**: DR support (PROD only)
5. **Lifecycle Policies**: Automatic version cleanup
6. **Bucket Policies**: Fine-grained access control
7. **Consistent Tagging**: Mandatory tags applied to all buckets

### 6.3.2 Module Structure

```
modules/s3_bucket/
├── main.tf           # Primary resource definitions
├── variables.tf      # Input variable declarations
├── outputs.tf        # Output value definitions
└── README.md         # Module documentation and usage examples
```

### 6.3.3 Input Variables

```hcl
# ============================================================================
# REQUIRED VARIABLES
# ============================================================================

variable "bucket_name" {
  type        = string
  description = "Name of the S3 bucket (must be globally unique)"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.bucket_name))
    error_message = "Bucket name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the S3 bucket (must include mandatory tags)"

  validation {
    condition = alltrue([
      contains(keys(var.tags), "Environment"),
      contains(keys(var.tags), "Project"),
      contains(keys(var.tags), "Owner"),
      contains(keys(var.tags), "CostCenter"),
      contains(keys(var.tags), "ManagedBy"),
      contains(keys(var.tags), "Component")
    ])
    error_message = "Tags must include: Environment, Project, Owner, CostCenter, ManagedBy, Component."
  }
}

# ============================================================================
# OPTIONAL VARIABLES
# ============================================================================

variable "enable_versioning" {
  type        = bool
  description = "Enable versioning for template version tracking"
  default     = true  # Mandatory for all environments
}

variable "enable_logging" {
  type        = bool
  description = "Enable access logging for audit trails"
  default     = false  # Set to true in SIT/PROD via tfvars
}

variable "logging_bucket" {
  type        = string
  description = "Name of the bucket where access logs will be stored"
  default     = ""

  validation {
    condition     = var.enable_logging ? var.logging_bucket != "" : true
    error_message = "logging_bucket must be specified when enable_logging is true."
  }
}

variable "logging_prefix" {
  type        = string
  description = "Prefix for access log objects"
  default     = "access-logs/"
}

variable "enable_replication" {
  type        = bool
  description = "Enable cross-region replication (PROD only)"
  default     = false  # Set to true in PROD via tfvars
}

variable "replica_region" {
  type        = string
  description = "AWS region for cross-region replication (eu-west-1 for PROD DR)"
  default     = "eu-west-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-\\d{1}$", var.replica_region))
    error_message = "Replica region must be a valid AWS region format (e.g., eu-west-1)."
  }
}

variable "replica_bucket_name" {
  type        = string
  description = "Name of the replica bucket in DR region"
  default     = ""

  validation {
    condition     = var.enable_replication ? var.replica_bucket_name != "" : true
    error_message = "replica_bucket_name must be specified when enable_replication is true."
  }
}

variable "lifecycle_days" {
  type        = number
  description = "Number of days to retain non-current versions (30 for DEV, 60 for SIT, 90 for PROD)"
  default     = 30

  validation {
    condition     = var.lifecycle_days >= 1 && var.lifecycle_days <= 365
    error_message = "Lifecycle days must be between 1 and 365."
  }
}

variable "force_destroy" {
  type        = bool
  description = "Allow bucket deletion even if it contains objects (DEV/SIT only)"
  default     = false  # Set to true in DEV/SIT, false in PROD
}

variable "object_lock_enabled" {
  type        = bool
  description = "Enable S3 Object Lock for compliance (not required)"
  default     = false
}

variable "kms_key_id" {
  type        = string
  description = "KMS key ID for bucket encryption (null = AWS-managed key)"
  default     = null
}

variable "allowed_lambda_arns" {
  type        = list(string)
  description = "List of Lambda function ARNs allowed to access the bucket"
  default     = []
}
```

### 6.3.4 Outputs

```hcl
# ============================================================================
# BUCKET OUTPUTS
# ============================================================================

output "bucket_id" {
  value       = aws_s3_bucket.this.id
  description = "ID of the S3 bucket (same as name)"
}

output "bucket_name" {
  value       = aws_s3_bucket.this.bucket
  description = "Name of the S3 bucket"
}

output "bucket_arn" {
  value       = aws_s3_bucket.this.arn
  description = "ARN of the S3 bucket for IAM policy references"
}

output "bucket_domain_name" {
  value       = aws_s3_bucket.this.bucket_domain_name
  description = "Domain name of the S3 bucket"
}

output "bucket_regional_domain_name" {
  value       = aws_s3_bucket.this.bucket_regional_domain_name
  description = "Regional domain name of the S3 bucket"
}

output "bucket_region" {
  value       = aws_s3_bucket.this.region
  description = "AWS region where the bucket is located"
}

# ============================================================================
# REPLICATION OUTPUTS
# ============================================================================

output "replica_bucket_arn" {
  value       = var.enable_replication ? aws_s3_bucket.replica[0].arn : null
  description = "ARN of the replica bucket in DR region (null if replication disabled)"
}

output "replica_bucket_name" {
  value       = var.enable_replication ? aws_s3_bucket.replica[0].bucket : null
  description = "Name of the replica bucket in DR region (null if replication disabled)"
}

output "replica_region" {
  value       = var.enable_replication ? var.replica_region : null
  description = "AWS region of the replica bucket (null if replication disabled)"
}

# ============================================================================
# LOGGING OUTPUTS
# ============================================================================

output "logging_enabled" {
  value       = var.enable_logging
  description = "Whether access logging is enabled"
}

output "logging_bucket" {
  value       = var.enable_logging ? var.logging_bucket : null
  description = "Name of the logging bucket (null if logging disabled)"
}
```

### 6.3.5 Resource Configuration

```hcl
# ============================================================================
# S3 BUCKET
# ============================================================================

resource "aws_s3_bucket" "this" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy

  # Object lock (optional, for compliance)
  object_lock_enabled = var.object_lock_enabled

  tags = merge(
    var.tags,
    {
      Name = var.bucket_name
      Type = "S3"
    }
  )
}

# ============================================================================
# BUCKET VERSIONING
# ============================================================================

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

# ============================================================================
# SERVER-SIDE ENCRYPTION
# ============================================================================

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_id != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_key_id
    }
    bucket_key_enabled = var.kms_key_id != null ? true : false
  }
}

# ============================================================================
# PUBLIC ACCESS BLOCK (Security Requirement)
# ============================================================================

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  # Block all public access (mandatory per CLAUDE.md)
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ============================================================================
# ACCESS LOGGING (SIT/PROD only)
# ============================================================================

resource "aws_s3_bucket_logging" "this" {
  count = var.enable_logging ? 1 : 0

  bucket = aws_s3_bucket.this.id

  target_bucket = var.logging_bucket
  target_prefix = var.logging_prefix
}

# ============================================================================
# LIFECYCLE POLICY (Version Management)
# ============================================================================

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    # Expire non-current versions after specified days
    noncurrent_version_expiration {
      noncurrent_days = var.lifecycle_days
    }

    # Abort incomplete multipart uploads after 7 days
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# ============================================================================
# BUCKET POLICY (Lambda Access)
# ============================================================================

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Sid    = "DenyInsecureTransport"
          Effect = "Deny"
          Principal = "*"
          Action = "s3:*"
          Resource = [
            aws_s3_bucket.this.arn,
            "${aws_s3_bucket.this.arn}/*"
          ]
          Condition = {
            Bool = {
              "aws:SecureTransport" = "false"
            }
          }
        }
      ],
      length(var.allowed_lambda_arns) > 0 ? [
        {
          Sid    = "AllowLambdaAccess"
          Effect = "Allow"
          Principal = {
            AWS = var.allowed_lambda_arns
          }
          Action = [
            "s3:GetObject",
            "s3:ListBucket"
          ]
          Resource = [
            aws_s3_bucket.this.arn,
            "${aws_s3_bucket.this.arn}/*"
          ]
        }
      ] : []
    )
  })
}

# ============================================================================
# CROSS-REGION REPLICATION (PROD Only)
# ============================================================================

# Replica bucket in DR region
resource "aws_s3_bucket" "replica" {
  count    = var.enable_replication ? 1 : 0
  provider = aws.replica

  bucket        = var.replica_bucket_name
  force_destroy = false  # Never allow force destroy in DR

  tags = merge(
    var.tags,
    {
      Name   = var.replica_bucket_name
      Type   = "S3"
      Region = var.replica_region
      Role   = "replica"
    }
  )
}

# Replica bucket versioning
resource "aws_s3_bucket_versioning" "replica" {
  count    = var.enable_replication ? 1 : 0
  provider = aws.replica

  bucket = aws_s3_bucket.replica[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

# Replica bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "replica" {
  count    = var.enable_replication ? 1 : 0
  provider = aws.replica

  bucket = aws_s3_bucket.replica[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
      kms_master_key_id = null
    }
  }
}

# Replica bucket public access block
resource "aws_s3_bucket_public_access_block" "replica" {
  count    = var.enable_replication ? 1 : 0
  provider = aws.replica

  bucket = aws_s3_bucket.replica[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Replication IAM role
resource "aws_iam_role" "replication" {
  count = var.enable_replication ? 1 : 0

  name = "${var.bucket_name}-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name      = "${var.bucket_name}-replication-role"
      Component = "iam"
    }
  )
}

# Replication IAM policy
resource "aws_iam_role_policy" "replication" {
  count = var.enable_replication ? 1 : 0

  name = "${var.bucket_name}-replication-policy"
  role = aws_iam_role.replication[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.this.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ]
        Resource = "${aws_s3_bucket.this.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ]
        Resource = "${aws_s3_bucket.replica[0].arn}/*"
      }
    ]
  })
}

# Replication configuration
resource "aws_s3_bucket_replication_configuration" "this" {
  count = var.enable_replication ? 1 : 0

  depends_on = [aws_s3_bucket_versioning.this]

  bucket = aws_s3_bucket.this.id
  role   = aws_iam_role.replication[0].arn

  rule {
    id     = "replicate-all"
    status = "Enabled"

    filter {
      prefix = ""  # Replicate all objects
    }

    destination {
      bucket        = aws_s3_bucket.replica[0].arn
      storage_class = "STANDARD"

      # Replicate encryption settings
      encryption_configuration {
        replica_kms_key_id = null  # Use AWS-managed key
      }

      # Replication time control (optional)
      replication_time {
        status = "Enabled"
        time {
          minutes = 15
        }
      }

      # Metrics (optional)
      metrics {
        status = "Enabled"
        event_threshold {
          minutes = 15
        }
      }
    }

    # Delete marker replication
    delete_marker_replication {
      status = "Enabled"
    }
  }
}

# ============================================================================
# CLOUDWATCH METRICS (Optional)
# ============================================================================

resource "aws_cloudwatch_metric_alarm" "replication_latency" {
  count = var.enable_replication ? 1 : 0

  alarm_name          = "${var.bucket_name}-replication-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ReplicationLatency"
  namespace           = "AWS/S3"
  period              = 300
  statistic           = "Maximum"
  threshold           = 900  # 15 minutes
  alarm_description   = "Alert when S3 replication latency exceeds 15 minutes"
  alarm_actions       = []  # Set via environment-specific configuration

  dimensions = {
    SourceBucket      = aws_s3_bucket.this.bucket
    DestinationBucket = aws_s3_bucket.replica[0].bucket
    RuleId            = "replicate-all"
  }

  tags = merge(
    var.tags,
    {
      Name      = "${var.bucket_name}-replication-latency-alarm"
      Component = "monitoring"
    }
  )
}
```

---

## 6.4 Root Module Structure

### 6.4.1 DynamoDB Repository Root Module

**Repository**: `2_1_bbws_dynamodb_schemas`

**Directory Structure**:
```
2_1_bbws_dynamodb_schemas/terraform/
├── main.tf                   # Module instantiations for all tables
├── variables.tf              # Root-level variables
├── outputs.tf                # Root-level outputs
├── backend.tf                # S3 backend configuration
├── providers.tf              # AWS provider configuration
├── versions.tf               # Terraform and provider version constraints
├── modules/
│   ├── dynamodb_table/       # Reusable DynamoDB table module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   └── backup/               # Backup configuration module (optional)
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── environments/
    ├── dev.tfvars            # DEV environment configuration
    ├── sit.tfvars            # SIT environment configuration
    └── prod.tfvars           # PROD environment configuration
```

### 6.4.2 Root main.tf Structure

```hcl
# ============================================================================
# TERRAFORM CONFIGURATION
# ============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ============================================================================
# TENANTS TABLE
# ============================================================================

module "tenants_table" {
  source = "./modules/dynamodb_table"

  # Table configuration
  table_name          = "tenants"
  partition_key       = "PK"
  partition_key_type  = "S"
  sort_key            = "SK"
  sort_key_type       = "S"

  # Attributes (PK, SK, and GSI keys)
  attributes = [
    { name = "PK", type = "S" },
    { name = "SK", type = "S" },
    { name = "email", type = "S" },
    { name = "entityType", type = "S" },
    { name = "status", type = "S" },
    { name = "dateCreated", type = "S" },
    { name = "active", type = "S" }
  ]

  # Global Secondary Indexes
  global_secondary_indexes = [
    {
      name               = "EmailIndex"
      hash_key           = "email"
      range_key          = "entityType"
      projection_type    = "ALL"
      non_key_attributes = []
    },
    {
      name               = "TenantStatusIndex"
      hash_key           = "status"
      range_key          = "dateCreated"
      projection_type    = "ALL"
      non_key_attributes = []
    },
    {
      name               = "ActiveIndex"
      hash_key           = "active"
      range_key          = "dateCreated"
      projection_type    = "KEYS_ONLY"
      non_key_attributes = []
    }
  ]

  # PITR and streams (mandatory)
  point_in_time_recovery = true
  stream_enabled         = true
  stream_view_type       = "NEW_AND_OLD_IMAGES"

  # Backup configuration (environment-specific)
  enable_backup           = var.enable_backup
  backup_retention_days   = var.backup_retention_days
  backup_schedule         = var.backup_schedule

  # Deletion protection (PROD only)
  enable_deletion_protection = var.enable_deletion_protection

  # Replication (PROD only)
  enable_replication = var.enable_replication
  replica_region     = var.replica_region

  # Tags
  tags = merge(
    var.tags,
    {
      Component    = "dynamodb"
      Table        = "tenants"
      BackupPolicy = var.enable_backup ? "enabled" : "disabled"
    }
  )
}

# ============================================================================
# PRODUCTS TABLE
# ============================================================================

module "products_table" {
  source = "./modules/dynamodb_table"

  # Table configuration
  table_name          = "products"
  partition_key       = "PK"
  partition_key_type  = "S"
  sort_key            = "SK"
  sort_key_type       = "S"

  # Attributes
  attributes = [
    { name = "PK", type = "S" },
    { name = "SK", type = "S" },
    { name = "active", type = "S" },
    { name = "dateCreated", type = "S" }
  ]

  # Global Secondary Indexes
  global_secondary_indexes = [
    {
      name               = "ProductActiveIndex"
      hash_key           = "active"
      range_key          = "dateCreated"
      projection_type    = "ALL"
      non_key_attributes = []
    },
    {
      name               = "ActiveIndex"
      hash_key           = "active"
      range_key          = "dateCreated"
      projection_type    = "KEYS_ONLY"
      non_key_attributes = []
    }
  ]

  # PITR and streams (mandatory)
  point_in_time_recovery = true
  stream_enabled         = true
  stream_view_type       = "NEW_AND_OLD_IMAGES"

  # Backup configuration (environment-specific)
  enable_backup           = var.enable_backup
  backup_retention_days   = var.backup_retention_days
  backup_schedule         = var.backup_schedule

  # Deletion protection (PROD only)
  enable_deletion_protection = var.enable_deletion_protection

  # Replication (PROD only)
  enable_replication = var.enable_replication
  replica_region     = var.replica_region

  # Tags
  tags = merge(
    var.tags,
    {
      Component    = "dynamodb"
      Table        = "products"
      BackupPolicy = var.enable_backup ? "enabled" : "disabled"
    }
  )
}

# ============================================================================
# CAMPAIGNS TABLE
# ============================================================================

module "campaigns_table" {
  source = "./modules/dynamodb_table"

  # Table configuration
  table_name          = "campaigns"
  partition_key       = "PK"
  partition_key_type  = "S"
  sort_key            = "SK"
  sort_key_type       = "S"

  # Attributes
  attributes = [
    { name = "PK", type = "S" },
    { name = "SK", type = "S" },
    { name = "active", type = "S" },
    { name = "fromDate", type = "S" },
    { name = "dateCreated", type = "S" },
    { name = "productId", type = "S" }
  ]

  # Global Secondary Indexes
  global_secondary_indexes = [
    {
      name               = "CampaignActiveIndex"
      hash_key           = "active"
      range_key          = "fromDate"
      projection_type    = "ALL"
      non_key_attributes = []
    },
    {
      name               = "CampaignProductIndex"
      hash_key           = "productId"
      range_key          = "fromDate"
      projection_type    = "ALL"
      non_key_attributes = []
    },
    {
      name               = "ActiveIndex"
      hash_key           = "active"
      range_key          = "dateCreated"
      projection_type    = "KEYS_ONLY"
      non_key_attributes = []
    }
  ]

  # PITR and streams (mandatory)
  point_in_time_recovery = true
  stream_enabled         = true
  stream_view_type       = "NEW_AND_OLD_IMAGES"

  # Backup configuration (environment-specific)
  enable_backup           = var.enable_backup
  backup_retention_days   = var.backup_retention_days
  backup_schedule         = var.backup_schedule

  # Deletion protection (PROD only)
  enable_deletion_protection = var.enable_deletion_protection

  # Replication (PROD only)
  enable_replication = var.enable_replication
  replica_region     = var.replica_region

  # Tags
  tags = merge(
    var.tags,
    {
      Component    = "dynamodb"
      Table        = "campaigns"
      BackupPolicy = var.enable_backup ? "enabled" : "disabled"
    }
  )
}
```

### 6.4.3 S3 Repository Root Module

**Repository**: `2_1_bbws_s3_schemas`

**Directory Structure**:
```
2_1_bbws_s3_schemas/terraform/
├── main.tf                   # Module instantiations for buckets
├── variables.tf              # Root-level variables
├── outputs.tf                # Root-level outputs
├── backend.tf                # S3 backend configuration
├── providers.tf              # AWS provider configuration
├── versions.tf               # Terraform and provider version constraints
├── modules/
│   └── s3_bucket/            # Reusable S3 bucket module
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── README.md
└── environments/
    ├── dev.tfvars            # DEV environment configuration
    ├── sit.tfvars            # SIT environment configuration
    └── prod.tfvars           # PROD environment configuration
```

### 6.4.4 S3 Root main.tf Structure

```hcl
# ============================================================================
# TERRAFORM CONFIGURATION
# ============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ============================================================================
# TEMPLATES BUCKET
# ============================================================================

module "templates_bucket" {
  source = "./modules/s3_bucket"

  # Bucket configuration
  bucket_name = "bbws-templates-${var.environment}"

  # Versioning (mandatory)
  enable_versioning = true

  # Access logging (SIT/PROD only)
  enable_logging  = var.enable_logging
  logging_bucket  = var.enable_logging ? "bbws-logs-${var.environment}" : ""
  logging_prefix  = "templates-access-logs/"

  # Replication (PROD only)
  enable_replication  = var.enable_replication
  replica_region      = var.replica_region
  replica_bucket_name = var.enable_replication ? "bbws-templates-${var.environment}-dr-${var.replica_region}" : ""

  # Lifecycle policy
  lifecycle_days = var.lifecycle_days

  # Force destroy (DEV/SIT only)
  force_destroy = var.force_destroy

  # Lambda access (to be populated with Lambda ARNs)
  allowed_lambda_arns = var.lambda_arns

  # Tags
  tags = merge(
    var.tags,
    {
      Component = "s3"
      Purpose   = "templates"
    }
  )
}

# ============================================================================
# LOGGING BUCKET (if access logging enabled)
# ============================================================================

module "logging_bucket" {
  count  = var.enable_logging ? 1 : 0
  source = "./modules/s3_bucket"

  # Bucket configuration
  bucket_name = "bbws-logs-${var.environment}"

  # Versioning
  enable_versioning = false  # Not required for logs

  # No logging on the logging bucket (avoid circular dependency)
  enable_logging = false

  # No replication for logging bucket
  enable_replication = false

  # Lifecycle policy (shorter retention for logs)
  lifecycle_days = 30

  # Force destroy (DEV/SIT only)
  force_destroy = var.force_destroy

  # No Lambda access for logging bucket
  allowed_lambda_arns = []

  # Tags
  tags = merge(
    var.tags,
    {
      Component = "s3"
      Purpose   = "logging"
    }
  )
}
```

---

## 6.5 Environment Configuration Files

### 6.5.1 dev.tfvars

**File**: `environments/dev.tfvars`

```hcl
# ============================================================================
# DEV ENVIRONMENT CONFIGURATION
# ============================================================================

# Environment Metadata
environment    = "dev"
aws_account_id = "536580886816"
aws_region     = "af-south-1"

# ============================================================================
# DYNAMODB CONFIGURATION
# ============================================================================

# Backup settings (DEV: Daily backups, 7-day retention)
enable_backup         = true
backup_retention_days = 7
backup_schedule       = "cron(0 2 * * ? *)"  # Daily at 2 AM UTC

# Deletion protection (DEV: Disabled for easy cleanup)
enable_deletion_protection = false

# Cross-region replication (DEV: Disabled)
enable_replication = false
replica_region     = "eu-west-1"  # Not used in DEV

# ============================================================================
# S3 CONFIGURATION
# ============================================================================

# S3 versioning (mandatory for all environments)
s3_versioning_enabled = true

# Lifecycle management (DEV: 30 days)
lifecycle_days = 30

# Access logging (DEV: Disabled to reduce costs)
enable_logging = false

# Force destroy (DEV: Enabled for easy cleanup)
force_destroy = true

# Lambda ARNs (to be populated when Lambda functions are deployed)
lambda_arns = []

# ============================================================================
# MANDATORY TAGS
# ============================================================================

tags = {
  Environment  = "dev"
  Project      = "BBWS WP Containers"
  Owner        = "Tebogo"
  CostCenter   = "AWS"
  ManagedBy    = "Terraform"
  Component    = "infrastructure"
  BackupPolicy = "daily"
  LLD          = "2.1.8"
}
```

### 6.5.2 sit.tfvars

**File**: `environments/sit.tfvars`

```hcl
# ============================================================================
# SIT ENVIRONMENT CONFIGURATION
# ============================================================================

# Environment Metadata
environment    = "sit"
aws_account_id = "815856636111"
aws_region     = "af-south-1"

# ============================================================================
# DYNAMODB CONFIGURATION
# ============================================================================

# Backup settings (SIT: Daily backups, 14-day retention)
enable_backup         = true
backup_retention_days = 14
backup_schedule       = "cron(0 2 * * ? *)"  # Daily at 2 AM UTC

# Deletion protection (SIT: Disabled to allow testing)
enable_deletion_protection = false

# Cross-region replication (SIT: Disabled)
enable_replication = false
replica_region     = "eu-west-1"  # Not used in SIT

# ============================================================================
# S3 CONFIGURATION
# ============================================================================

# S3 versioning (mandatory for all environments)
s3_versioning_enabled = true

# Lifecycle management (SIT: 60 days)
lifecycle_days = 60

# Access logging (SIT: Enabled for audit trails)
enable_logging = true

# Force destroy (SIT: Enabled for testing)
force_destroy = true

# Lambda ARNs (to be populated when Lambda functions are deployed)
lambda_arns = []

# ============================================================================
# MANDATORY TAGS
# ============================================================================

tags = {
  Environment  = "sit"
  Project      = "BBWS WP Containers"
  Owner        = "Tebogo"
  CostCenter   = "AWS"
  ManagedBy    = "Terraform"
  Component    = "infrastructure"
  BackupPolicy = "daily"
  LLD          = "2.1.8"
}
```

### 6.5.3 prod.tfvars

**File**: `environments/prod.tfvars`

```hcl
# ============================================================================
# PROD ENVIRONMENT CONFIGURATION
# ============================================================================

# Environment Metadata
environment    = "prod"
aws_account_id = "093646564004"
aws_region     = "af-south-1"

# ============================================================================
# DYNAMODB CONFIGURATION
# ============================================================================

# Backup settings (PROD: Hourly backups, 90-day retention)
enable_backup         = true
backup_retention_days = 90
backup_schedule       = "cron(0 */1 * * ? *)"  # Hourly

# Deletion protection (PROD: Enabled to prevent accidental deletion)
enable_deletion_protection = true

# Cross-region replication (PROD: Enabled for DR)
enable_replication = true
replica_region     = "eu-west-1"  # DR region: Ireland

# ============================================================================
# S3 CONFIGURATION
# ============================================================================

# S3 versioning (mandatory for all environments)
s3_versioning_enabled = true

# Lifecycle management (PROD: 90 days)
lifecycle_days = 90

# Access logging (PROD: Enabled for compliance and audit)
enable_logging = true

# Force destroy (PROD: Disabled to prevent accidental deletion)
force_destroy = false

# Lambda ARNs (to be populated when Lambda functions are deployed)
lambda_arns = []

# ============================================================================
# MANDATORY TAGS
# ============================================================================

tags = {
  Environment  = "prod"
  Project      = "BBWS WP Containers"
  Owner        = "Tebogo"
  CostCenter   = "AWS"
  ManagedBy    = "Terraform"
  Component    = "infrastructure"
  BackupPolicy = "hourly"
  DR           = "enabled"
  LLD          = "2.1.8"
}
```

---

## 6.6 Backend Configuration

### 6.6.1 Backend Strategy

**State Management Principles:**

1. **Separate S3 Bucket Per Environment**: Each environment (DEV, SIT, PROD) has its own state bucket to prevent cross-environment state corruption
2. **Component-Level State Files**: Each component (tenants table, products table, templates bucket) has its own state file to reduce blast radius
3. **DynamoDB Locking**: Prevents concurrent modifications using DynamoDB lock table
4. **State Encryption**: All state files encrypted at rest using SSE-S3
5. **State Versioning**: S3 versioning enabled for rollback capability

**State Bucket Naming Convention:**
```
bbws-terraform-state-{environment}
├── DEV:  bbws-terraform-state-dev
├── SIT:  bbws-terraform-state-sit
└── PROD: bbws-terraform-state-prod
```

**State File Path Convention:**
```
{repository}/{component}/terraform.tfstate

Examples:
- 2_1_bbws_dynamodb_schemas/tenants/terraform.tfstate
- 2_1_bbws_dynamodb_schemas/products/terraform.tfstate
- 2_1_bbws_dynamodb_schemas/campaigns/terraform.tfstate
- 2_1_bbws_s3_schemas/templates/terraform.tfstate
```

**Lock Table Naming Convention:**
```
terraform-state-lock-{environment}
├── DEV:  terraform-state-lock-dev
├── SIT:  terraform-state-lock-sit
└── PROD: terraform-state-lock-prod
```

### 6.6.2 backend.tf Example (DynamoDB Repository)

**File**: `terraform/backend.tf`

```hcl
# ============================================================================
# TERRAFORM BACKEND CONFIGURATION
# ============================================================================
# NOTE: Backend configuration cannot use variables. You must either:
#   1. Use backend config files: terraform init -backend-config=backend-dev.hcl
#   2. Use partial configuration with CLI flags
#   3. Hardcode values per environment directory
# ============================================================================

terraform {
  backend "s3" {
    # State bucket (environment-specific)
    bucket = "bbws-terraform-state-dev"  # Change per environment

    # State file path (component-specific)
    key = "2_1_bbws_dynamodb_schemas/terraform.tfstate"

    # AWS region
    region = "af-south-1"

    # DynamoDB lock table (environment-specific)
    dynamodb_table = "terraform-state-lock-dev"  # Change per environment

    # Encryption at rest
    encrypt = true

    # ACL (private)
    acl = "private"

    # Server-side encryption
    server_side_encryption_configuration {
      rule {
        apply_server_side_encryption_by_default {
          sse_algorithm = "AES256"
        }
      }
    }
  }
}
```

**Alternative: Backend Configuration Files**

**File**: `terraform/backend-dev.hcl`
```hcl
bucket         = "bbws-terraform-state-dev"
key            = "2_1_bbws_dynamodb_schemas/terraform.tfstate"
region         = "af-south-1"
dynamodb_table = "terraform-state-lock-dev"
encrypt        = true
```

**File**: `terraform/backend-sit.hcl`
```hcl
bucket         = "bbws-terraform-state-sit"
key            = "2_1_bbws_dynamodb_schemas/terraform.tfstate"
region         = "af-south-1"
dynamodb_table = "terraform-state-lock-sit"
encrypt        = true
```

**File**: `terraform/backend-prod.hcl`
```hcl
bucket         = "bbws-terraform-state-prod"
key            = "2_1_bbws_dynamodb_schemas/terraform.tfstate"
region         = "af-south-1"
dynamodb_table = "terraform-state-lock-prod"
encrypt        = true
```

**Usage**:
```bash
# Initialize with environment-specific backend config
terraform init -backend-config=backend-dev.hcl
```

### 6.6.3 providers.tf Example

**File**: `terraform/providers.tf`

```hcl
# ============================================================================
# AWS PROVIDER CONFIGURATION
# ============================================================================

provider "aws" {
  region = var.aws_region

  # Assume role for deployment (configured in GitHub Actions)
  # Role ARN passed via environment variable: AWS_ROLE_TO_ASSUME

  default_tags {
    tags = {
      ManagedBy   = "Terraform"
      Repository  = "2_1_bbws_dynamodb_schemas"
      Environment = var.environment
    }
  }
}

# Provider alias for DR region (PROD only)
provider "aws" {
  alias  = "replica"
  region = var.replica_region

  # Same role assumption as primary provider

  default_tags {
    tags = {
      ManagedBy   = "Terraform"
      Repository  = "2_1_bbws_dynamodb_schemas"
      Environment = var.environment
      Region      = "dr"
    }
  }
}
```

### 6.6.4 versions.tf Example

**File**: `terraform/versions.tf`

```hcl
# ============================================================================
# TERRAFORM AND PROVIDER VERSION CONSTRAINTS
# ============================================================================

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

---

## 6.7 Tagging Strategy

### 6.7.1 Mandatory Tags

All AWS resources created by Terraform must include the following 7 mandatory tags:

| Tag Key | Description | Values | Example |
|---------|-------------|--------|---------|
| `Environment` | Deployment environment | `dev`, `sit`, `prod` | `Environment=prod` |
| `Project` | Project name | `BBWS WP Containers` | `Project=BBWS WP Containers` |
| `Owner` | Resource owner | `Tebogo` | `Owner=Tebogo` |
| `CostCenter` | Cost allocation | `AWS` | `CostCenter=AWS` |
| `ManagedBy` | Automation tool | `Terraform` | `ManagedBy=Terraform` |
| `BackupPolicy` | Backup frequency | `none`, `daily`, `hourly` | `BackupPolicy=hourly` |
| `Component` | Component type | `dynamodb`, `s3`, `lambda`, `infrastructure` | `Component=dynamodb` |

### 6.7.2 Optional Tags

Additional tags that provide context and traceability:

| Tag Key | Description | Values | Example |
|---------|-------------|--------|---------|
| `Application` | Application name | `CustomerPortalPublic` | `Application=CustomerPortalPublic` |
| `LLD` | LLD document version | `2.1.8` | `LLD=2.1.8` |
| `DR` | DR status | `enabled`, `disabled` | `DR=enabled` |
| `Table` | Table name (DynamoDB only) | `tenants`, `products`, `campaigns` | `Table=tenants` |
| `Purpose` | Resource purpose (S3 only) | `templates`, `logging` | `Purpose=templates` |
| `Region` | Region identifier | `primary`, `dr` | `Region=dr` |
| `Role` | Resource role | `primary`, `replica` | `Role=replica` |

### 6.7.3 Tag Validation

Terraform variable validation ensures mandatory tags are present:

```hcl
variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources"

  validation {
    condition = alltrue([
      contains(keys(var.tags), "Environment"),
      contains(keys(var.tags), "Project"),
      contains(keys(var.tags), "Owner"),
      contains(keys(var.tags), "CostCenter"),
      contains(keys(var.tags), "ManagedBy"),
      contains(keys(var.tags), "Component")
    ])
    error_message = "Tags must include: Environment, Project, Owner, CostCenter, ManagedBy, Component."
  }
}
```

### 6.7.4 Tag Merging Pattern

Tags are merged at multiple levels:

1. **Provider Default Tags**: Applied to all resources automatically
2. **Root Module Tags**: Passed from `.tfvars` files
3. **Module-Specific Tags**: Added by modules for resource-specific context
4. **Resource-Level Tags**: Final overrides for specific resources

**Example Tag Merging**:
```hcl
tags = merge(
  var.tags,                    # From tfvars (mandatory tags)
  {
    Name      = var.table_name  # Resource-specific
    Component = "dynamodb"      # Module-specific
    Table     = var.table_name  # Additional context
  }
)
```

### 6.7.5 Cost Tracking via Tags

Tags enable AWS Cost Explorer filtering:

**Example Queries**:
- **Total cost per environment**: Filter by `Environment=prod`
- **DynamoDB costs only**: Filter by `Component=dynamodb`
- **Project-wide costs**: Filter by `Project=BBWS WP Containers`
- **Backup costs**: Filter by `BackupPolicy=hourly`
- **DR costs**: Filter by `DR=enabled`

**Budget Alert Configuration**:
```hcl
resource "aws_budgets_budget" "environment" {
  name              = "bbws-${var.environment}-monthly-budget"
  budget_type       = "COST"
  limit_amount      = var.budget_limit
  limit_unit        = "USD"
  time_unit         = "MONTHLY"

  cost_filters = {
    TagKeyValue = "Environment$${var.environment}"
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.budget_alert_emails
  }
}
```

---

## 6.8 Deployment Workflow

### 6.8.1 Prerequisites

**Before deploying infrastructure:**

1. **AWS Credentials**: Configured for each environment
   - DEV: `AWS_ROLE_DEV` (GitHub secret)
   - SIT: `AWS_ROLE_SIT` (GitHub secret)
   - PROD: `AWS_ROLE_PROD` (GitHub secret)

2. **Terraform State Backend**: State buckets and lock tables must exist
   ```bash
   # Create state bucket (one-time setup per environment)
   aws s3 mb s3://bbws-terraform-state-dev --region af-south-1

   # Enable versioning
   aws s3api put-bucket-versioning \
     --bucket bbws-terraform-state-dev \
     --versioning-configuration Status=Enabled

   # Enable encryption
   aws s3api put-bucket-encryption \
     --bucket bbws-terraform-state-dev \
     --server-side-encryption-configuration \
     '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

   # Create lock table
   aws dynamodb create-table \
     --table-name terraform-state-lock-dev \
     --attribute-definitions AttributeName=LockID,AttributeType=S \
     --key-schema AttributeName=LockID,KeyType=HASH \
     --billing-mode PAY_PER_REQUEST \
     --region af-south-1
   ```

3. **GitHub Repository Secrets**: Configure environment-specific secrets
   - `AWS_ROLE_DEV`: `arn:aws:iam::536580886816:role/bbws-terraform-deployer-dev`
   - `AWS_ROLE_SIT`: `arn:aws:iam::815856636111:role/bbws-terraform-deployer-sit`
   - `AWS_ROLE_PROD`: `arn:aws:iam::093646564004:role/bbws-terraform-deployer-prod`

### 6.8.2 Initialization

**Step 1: Clone Repository**
```bash
git clone https://github.com/bbws/2_1_bbws_dynamodb_schemas.git
cd 2_1_bbws_dynamodb_schemas/terraform
```

**Step 2: Initialize Terraform**
```bash
# Option 1: Using backend config file
terraform init -backend-config=backend-dev.hcl

# Option 2: Using inline backend config
terraform init \
  -backend-config="bucket=bbws-terraform-state-dev" \
  -backend-config="key=2_1_bbws_dynamodb_schemas/terraform.tfstate" \
  -backend-config="region=af-south-1" \
  -backend-config="dynamodb_table=terraform-state-lock-dev"
```

**Expected Output**:
```
Initializing the backend...

Successfully configured the backend "s3"! Terraform will automatically
use this backend unless the backend configuration changes.

Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 5.0"...
- Installing hashicorp/aws v5.31.0...
- Installed hashicorp/aws v5.31.0

Terraform has been successfully initialized!
```

### 6.8.3 Planning

**Step 1: Validate Configuration**
```bash
# Format check
terraform fmt -check -recursive

# Validation
terraform validate
```

**Step 2: Generate Plan**
```bash
# Generate plan for DEV environment
terraform plan -var-file=environments/dev.tfvars -out=tfplan-dev

# Review plan output
terraform show tfplan-dev
```

**Expected Output** (excerpt):
```
Terraform will perform the following actions:

  # module.tenants_table.aws_dynamodb_table.this will be created
  + resource "aws_dynamodb_table" "this" {
      + arn              = (known after apply)
      + billing_mode     = "PAY_PER_REQUEST"
      + hash_key         = "PK"
      + id               = (known after apply)
      + name             = "tenants"
      + range_key        = "SK"
      + stream_arn       = (known after apply)
      + stream_enabled   = true
      + stream_view_type = "NEW_AND_OLD_IMAGES"

      + attribute {
          + name = "PK"
          + type = "S"
        }
      + attribute {
          + name = "SK"
          + type = "S"
        }

      + global_secondary_index {
          + hash_key         = "email"
          + name             = "EmailIndex"
          + projection_type  = "ALL"
          + range_key        = "entityType"
        }

      + point_in_time_recovery {
          + enabled = true
        }

      + server_side_encryption {
          + enabled = true
        }

      + tags = {
          + "Component"    = "dynamodb"
          + "Environment"  = "dev"
          + "ManagedBy"    = "Terraform"
          + "Owner"        = "Tebogo"
          + "Project"      = "BBWS WP Containers"
          + "Table"        = "tenants"
        }
    }

Plan: 3 to add, 0 to change, 0 to destroy.
```

### 6.8.4 Application

**Step 1: Apply Plan (Manual)**
```bash
# Apply the saved plan
terraform apply tfplan-dev
```

**Step 2: Verify Deployment**
```bash
# List DynamoDB tables
aws dynamodb list-tables --region af-south-1

# Describe specific table
aws dynamodb describe-table --table-name tenants --region af-south-1

# List S3 buckets
aws s3 ls | grep bbws-templates
```

**Expected Output**:
```
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.

Outputs:

tenants_table_arn = "arn:aws:dynamodb:af-south-1:536580886816:table/tenants"
tenants_table_name = "tenants"
tenants_table_stream_arn = "arn:aws:dynamodb:af-south-1:536580886816:table/tenants/stream/2025-12-25T10:30:00.000"
products_table_arn = "arn:aws:dynamodb:af-south-1:536580886816:table/products"
campaigns_table_arn = "arn:aws:dynamodb:af-south-1:536580886816:table/campaigns"
```

### 6.8.5 Destroy (Emergency Only)

**WARNING**: Destroying infrastructure deletes all data. Only use in DEV/SIT or emergency situations.

```bash
# Generate destroy plan
terraform plan -destroy -var-file=environments/dev.tfvars -out=tfplan-destroy

# Review destroy plan
terraform show tfplan-destroy

# Apply destroy (requires confirmation)
terraform apply tfplan-destroy
```

**Alternative: Direct destroy (requires manual confirmation)**
```bash
terraform destroy -var-file=environments/dev.tfvars
```

**Expected Output**:
```
Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes

Destroy complete! Resources: 3 destroyed.
```

### 6.8.6 CI/CD Pipeline Deployment

**Automated Deployment via GitHub Actions:**

1. **Push to main branch**: Triggers validation pipeline
2. **Validation passes**: Terraform plan generated for all environments
3. **Manual approval**: Developer/Tech Lead approves plan
4. **Manual trigger**: `deploy-dev` workflow triggered
5. **DEV deployment**: Terraform apply executed in DEV
6. **Post-deploy tests**: Automated validation tests run
7. **Promotion to SIT**: Manual trigger after DEV tests pass
8. **SIT deployment**: Terraform apply executed in SIT
9. **Integration tests**: QA team validates SIT deployment
10. **Promotion to PROD**: Manual trigger after SIT approval
11. **PROD deployment**: Terraform apply executed in PROD
12. **Smoke tests**: Final validation in PROD

**GitHub Actions Workflow Commands**:

```bash
# Trigger DEV deployment
gh workflow run terraform-apply-dev.yml \
  -f confirmation="deploy-dev"

# Trigger SIT promotion
gh workflow run terraform-apply-sit.yml \
  -f confirmation="promote-sit"

# Trigger PROD promotion
gh workflow run terraform-apply-prod.yml \
  -f confirmation="promote-prod"
```

---

## 6.9 State Management and Rollback

### 6.9.1 State File Versioning

All state buckets have S3 versioning enabled, providing automatic rollback capability.

**List State Versions**:
```bash
aws s3api list-object-versions \
  --bucket bbws-terraform-state-dev \
  --prefix 2_1_bbws_dynamodb_schemas/terraform.tfstate
```

**Example Output**:
```json
{
  "Versions": [
    {
      "Key": "2_1_bbws_dynamodb_schemas/terraform.tfstate",
      "VersionId": "X8fL3QpJK9rM5nN7oO8pP",
      "IsLatest": true,
      "LastModified": "2025-12-25T12:00:00.000Z",
      "Size": 45678
    },
    {
      "Key": "2_1_bbws_dynamodb_schemas/terraform.tfstate",
      "VersionId": "A1bC2dE3fG4hI5jK6lM7n",
      "IsLatest": false,
      "LastModified": "2025-12-24T10:00:00.000Z",
      "Size": 43210
    }
  ]
}
```

### 6.9.2 Manual Rollback Process

**Step 1: Identify Previous State Version**
```bash
# List versions with timestamps
aws s3api list-object-versions \
  --bucket bbws-terraform-state-dev \
  --prefix 2_1_bbws_dynamodb_schemas/terraform.tfstate \
  --query 'Versions[*].[VersionId,LastModified]' \
  --output table
```

**Step 2: Download Previous State**
```bash
# Download specific version
aws s3api get-object \
  --bucket bbws-terraform-state-dev \
  --key 2_1_bbws_dynamodb_schemas/terraform.tfstate \
  --version-id A1bC2dE3fG4hI5jK6lM7n \
  terraform.tfstate.backup
```

**Step 3: Restore Previous State**
```bash
# Push previous state as current
terraform state push terraform.tfstate.backup
```

**Step 4: Verify State Restoration**
```bash
# Generate plan to see differences
terraform plan -var-file=environments/dev.tfvars

# Expected: Plan should show changes to revert infrastructure
```

**Step 5: Apply Rollback**
```bash
# Apply changes to revert infrastructure
terraform apply -var-file=environments/dev.tfvars -auto-approve
```

### 6.9.3 Automated Rollback via GitHub Actions

Use the `terraform-rollback.yml` workflow to automate rollback:

```bash
gh workflow run terraform-rollback.yml \
  -f environment="dev" \
  -f version_id="A1bC2dE3fG4hI5jK6lM7n"
```

**Workflow performs:**
1. Downloads specified state version
2. Pushes state to current
3. Generates terraform plan
4. Requires manual approval
5. Applies rollback
6. Runs post-rollback validation
7. Notifies stakeholders

### 6.9.4 State Locking

DynamoDB table prevents concurrent modifications:

**Lock Table Structure**:
```
terraform-state-lock-dev
├── LockID (String, Hash Key): "bbws-terraform-state-dev/2_1_bbws_dynamodb_schemas/terraform.tfstate-md5"
├── Info (String): JSON metadata about who holds the lock
└── Digest (String): State file MD5 hash
```

**If Lock is Stuck** (emergency only):
```bash
# Force unlock (use with extreme caution)
terraform force-unlock <LOCK_ID>

# Example:
terraform force-unlock 12345678-1234-1234-1234-123456789012
```

---

## 6.10 Security and Compliance

### 6.10.1 Encryption

All resources use encryption at rest and in transit:

**DynamoDB Encryption**:
- SSE-KMS with AWS-managed keys
- Encryption enabled by default
- PITR encrypted backups

**S3 Encryption**:
- SSE-S3 (AES-256) for buckets
- SSL/TLS for all API calls
- Bucket policies enforce HTTPS

**Terraform State Encryption**:
- S3 bucket encryption enabled
- Backend configuration specifies `encrypt = true`

### 6.10.2 Access Control

**IAM Roles**:
- `bbws-terraform-deployer-dev`: Full access to DEV resources
- `bbws-terraform-deployer-sit`: Full access to SIT resources
- `bbws-terraform-deployer-prod`: Full access to PROD resources

**Principle of Least Privilege**:
- GitHub Actions assumes role only during deployment
- Time-limited credentials (1 hour max)
- No permanent access keys

**S3 Bucket Policies**:
- Block all public access (mandatory)
- Deny insecure transport (HTTP)
- Allow Lambda access via ARN whitelist

### 6.10.3 Compliance

**Audit Trail**:
- CloudWatch Logs for all Lambda invocations
- S3 access logging (SIT/PROD)
- DynamoDB Streams capture all changes
- Terraform state changes tracked via S3 versioning
- GitHub Actions logs for all deployments

**Backup and Recovery**:
- PITR enabled on all DynamoDB tables (35-day retention)
- AWS Backup scheduled backups (7/14/90 days)
- S3 versioning enabled (30/60/90 day lifecycle)
- Cross-region replication (PROD only)

**Deletion Protection**:
- PROD: Deletion protection enabled on tables
- PROD: `force_destroy = false` on S3 buckets
- DEV/SIT: Deletion allowed for testing

---

## 6.11 Monitoring and Alerting

### 6.11.1 CloudWatch Alarms

**DynamoDB Alarms** (per table):
- User errors (threshold: 10 in 5 min)
- System errors (threshold: 0)
- Throttled requests (threshold: 5 in 5 min)

**S3 Alarms** (PROD only):
- Replication latency (threshold: 15 minutes)

**Alarm Actions**:
- DEV: Slack notifications
- SIT: Slack + Email to QA
- PROD: Slack + Email + PagerDuty (future)

### 6.11.2 CloudWatch Dashboards

**Infrastructure Dashboard** (per environment):
- DynamoDB table metrics (read/write capacity, latency)
- S3 bucket metrics (request count, 4xx/5xx errors)
- Terraform deployment history
- Cost tracking

### 6.11.3 AWS Cost Anomaly Detection

**Budget Alerts**:
- DEV: $500/month (alert at 80%)
- SIT: $1,000/month (alert at 80%)
- PROD: $5,000/month (alert at 80%)

**Cost Allocation Tags**:
- Filter by `Environment`, `Component`, `Project`
- Track backup costs via `BackupPolicy` tag
- Track DR costs via `DR` tag

---

## 6.12 Summary

This Terraform module design provides:

1. **Reusable Modules**: Generic `dynamodb_table` and `s3_bucket` modules
2. **Environment Isolation**: Separate state, accounts, and configurations
3. **Progressive Hardening**: DEV → SIT → PROD security increases
4. **Disaster Recovery**: PROD cross-region replication
5. **Automated Deployment**: CI/CD with approval gates
6. **Rollback Capability**: State versioning and automated rollback
7. **Compliance**: Encryption, access control, audit trails
8. **Cost Optimization**: On-demand capacity, lifecycle policies, budget alerts
9. **Monitoring**: CloudWatch alarms and dashboards
10. **Documentation**: Comprehensive inline comments and README files

**Key Files Created**:
- `/modules/dynamodb_table/main.tf` (DynamoDB module)
- `/modules/s3_bucket/main.tf` (S3 module)
- `/main.tf` (Root module with table/bucket instantiations)
- `/environments/dev.tfvars` (DEV configuration)
- `/environments/sit.tfvars` (SIT configuration)
- `/environments/prod.tfvars` (PROD configuration)
- `/backend.tf` (State management)
- `/providers.tf` (AWS provider configuration)

**Next Steps**:
1. Deploy infrastructure to DEV
2. Validate deployment with post-deploy tests
3. Promote to SIT after DEV validation
4. Run integration tests in SIT
5. Promote to PROD after SIT approval
6. Monitor PROD deployment for 24 hours

---

**End of Section 6: Terraform Module Design**
