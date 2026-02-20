# DynamoDB Tables Module - Terraform Implementation

**Worker ID**: worker-1-dynamodb-tables-module
**Stage**: Stage 2 - Infrastructure Terraform
**Project**: project-plan-2-access-management
**Created**: 2026-01-23
**Status**: COMPLETE

---

## Overview

This Terraform module creates the DynamoDB table for the BBWS Access Management system using a single-table design. The table supports all entity types defined in Stage 1 LLD reviews:

- Permissions (platform-level)
- Permission Sets (organisation-level)
- Invitations (with token lookup)
- Teams (with role definitions)
- Team Members
- Platform Roles
- Organisation Roles
- User Role Assignments
- Audit Events

---

## Module Structure

```
terraform/modules/dynamodb-access-management/
├── main.tf           # Table definition
├── gsi.tf            # Global Secondary Indexes
├── variables.tf      # Input variables
├── outputs.tf        # Output values
└── locals.tf         # Local values
```

---

## 1. locals.tf

```hcl
# =============================================================================
# Local Values for DynamoDB Access Management Table
# =============================================================================
# Worker: worker-1-dynamodb-tables-module
# Stage: Stage 2 - Infrastructure Terraform
# Project: project-plan-2-access-management
# =============================================================================

locals {
  # Table naming convention: bbws-access-{env}-ddb-access-management
  table_name = "${var.project_name}-${var.environment}-ddb-access-management"

  # Common tags applied to all resources
  common_tags = merge(
    {
      Project     = "BBWS"
      Component   = "AccessManagement"
      CostCenter  = "BBWS-ACCESS"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Module      = "dynamodb-access-management"
    },
    var.tags
  )

  # TTL attribute name for invitation tokens and audit events
  ttl_attribute_name = "ttl"

  # GSI names for reference
  gsi_names = {
    gsi1 = "${local.table_name}-gsi1"
    gsi2 = "${local.table_name}-gsi2"
    gsi3 = "${local.table_name}-gsi3"
    gsi4 = "${local.table_name}-gsi4"
    gsi5 = "${local.table_name}-gsi5"
  }

  # Entity key patterns documentation (for reference)
  entity_patterns = {
    # Permission Service
    permission             = "PK: PERM#{permissionId}, SK: METADATA"
    permission_set         = "PK: ORG#{organisationId}, SK: PERMSET#{permissionSetId}"
    platform_permission_set = "PK: PLATFORM, SK: PERMSET#{permissionSetId}"

    # Invitation Service
    invitation             = "PK: ORG#{organisationId}, SK: INV#{invitationId}"
    invitation_token       = "PK: INVTOKEN#{token}, SK: METADATA"

    # Team Service
    team                   = "PK: ORG#{organisationId}, SK: TEAM#{teamId}"
    team_role_definition   = "PK: ORG#{organisationId}, SK: TEAMROLE#{teamRoleId}"
    team_member            = "PK: ORG#{organisationId}#TEAM#{teamId}, SK: MEMBER#{userId}"

    # Role Service
    platform_role          = "PK: PLATFORM, SK: ROLE#{roleId}"
    organisation_role      = "PK: ORG#{organisationId}, SK: ROLE#{roleId}"
    user_role_assignment   = "PK: ORG#{organisationId}#USER#{userId}, SK: ROLE#{roleId}"

    # Audit Service
    audit_event            = "PK: ORG#{organisationId}#DATE#{YYYY-MM-DD}, SK: EVENT#{timestamp}#{eventId}"
  }
}
```

---

## 2. variables.tf

```hcl
# =============================================================================
# Input Variables for DynamoDB Access Management Table
# =============================================================================
# Worker: worker-1-dynamodb-tables-module
# Stage: Stage 2 - Infrastructure Terraform
# Project: project-plan-2-access-management
# =============================================================================

variable "environment" {
  description = "Deployment environment (dev, sit, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "sit", "prod"], var.environment)
    error_message = "Environment must be one of: dev, sit, prod."
  }
}

variable "project_name" {
  description = "Project name prefix for resource naming"
  type        = string
  default     = "bbws-access"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "enable_pitr" {
  description = "Enable Point-in-Time Recovery for disaster recovery"
  type        = bool
  default     = true
}

variable "enable_server_side_encryption" {
  description = "Enable server-side encryption using AWS managed KMS key"
  type        = bool
  default     = true
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection to prevent accidental table deletion"
  type        = bool
  default     = false  # Set to true for production
}

variable "enable_global_tables" {
  description = "Enable DynamoDB Global Tables for multi-region replication (PROD only)"
  type        = bool
  default     = false
}

variable "replica_regions" {
  description = "List of AWS regions for global table replicas (only used if enable_global_tables is true)"
  type        = list(string)
  default     = ["eu-west-1"]
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "stream_enabled" {
  description = "Enable DynamoDB Streams for change data capture (required for audit archiving)"
  type        = bool
  default     = true
}

variable "stream_view_type" {
  description = "DynamoDB Stream view type (NEW_IMAGE, OLD_IMAGE, NEW_AND_OLD_IMAGES, KEYS_ONLY)"
  type        = string
  default     = "NEW_AND_OLD_IMAGES"

  validation {
    condition     = contains(["NEW_IMAGE", "OLD_IMAGE", "NEW_AND_OLD_IMAGES", "KEYS_ONLY"], var.stream_view_type)
    error_message = "Stream view type must be one of: NEW_IMAGE, OLD_IMAGE, NEW_AND_OLD_IMAGES, KEYS_ONLY."
  }
}
```

---

## 3. main.tf

```hcl
# =============================================================================
# DynamoDB Table Definition - Access Management (Single-Table Design)
# =============================================================================
# Worker: worker-1-dynamodb-tables-module
# Stage: Stage 2 - Infrastructure Terraform
# Project: project-plan-2-access-management
# =============================================================================
#
# This table uses a single-table design supporting multiple entity types:
# - Permissions (PERM#{id})
# - Permission Sets (ORG#{orgId}#PERMSET#{setId} or PLATFORM#PERMSET#{setId})
# - Invitations (ORG#{orgId}#INV#{invId})
# - Invitation Tokens (INVTOKEN#{token})
# - Teams (ORG#{orgId}#TEAM#{teamId})
# - Team Role Definitions (ORG#{orgId}#TEAMROLE#{roleId})
# - Team Members (ORG#{orgId}#TEAM#{teamId}#MEMBER#{userId})
# - Platform Roles (PLATFORM#ROLE#{roleId})
# - Organisation Roles (ORG#{orgId}#ROLE#{roleId})
# - User Role Assignments (ORG#{orgId}#USER#{userId}#ROLE#{roleId})
# - Audit Events (ORG#{orgId}#DATE#{date}#EVENT#{timestamp}#{eventId})
# =============================================================================

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }
}

# =============================================================================
# Main DynamoDB Table
# =============================================================================

resource "aws_dynamodb_table" "access_management" {
  name = local.table_name

  # On-demand capacity mode (PAY_PER_REQUEST) as per project requirements
  billing_mode = "PAY_PER_REQUEST"

  # Primary Key Definition
  hash_key  = "PK"
  range_key = "SK"

  # ==========================================================================
  # Attribute Definitions
  # ==========================================================================
  # Primary table keys
  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  # GSI1 attributes - Status/Expiry queries, Category lookups, Name lookups
  attribute {
    name = "GSI1PK"
    type = "S"
  }

  attribute {
    name = "GSI1SK"
    type = "S"
  }

  # GSI2 attributes - Email lookups, Active status filtering, Division lookups
  attribute {
    name = "GSI2PK"
    type = "S"
  }

  attribute {
    name = "GSI2SK"
    type = "S"
  }

  # GSI3 attributes - User team memberships, User role lookups
  attribute {
    name = "GSI3PK"
    type = "S"
  }

  attribute {
    name = "GSI3SK"
    type = "S"
  }

  # GSI4 attributes - Audit by user
  attribute {
    name = "GSI4PK"
    type = "S"
  }

  attribute {
    name = "GSI4SK"
    type = "S"
  }

  # GSI5 attributes - Audit by event type
  attribute {
    name = "GSI5PK"
    type = "S"
  }

  attribute {
    name = "GSI5SK"
    type = "S"
  }

  # ==========================================================================
  # Global Secondary Indexes (defined in gsi.tf)
  # ==========================================================================

  # GSI1: Status/Expiry queries, Category lookups, Role/Team name lookups
  global_secondary_index {
    name            = local.gsi_names.gsi1
    hash_key        = "GSI1PK"
    range_key       = "GSI1SK"
    projection_type = "ALL"
  }

  # GSI2: Email lookups, Active status filtering, Division team lookups
  global_secondary_index {
    name            = local.gsi_names.gsi2
    hash_key        = "GSI2PK"
    range_key       = "GSI2SK"
    projection_type = "ALL"
  }

  # GSI3: User team memberships, Team member by role filtering
  global_secondary_index {
    name            = local.gsi_names.gsi3
    hash_key        = "GSI3PK"
    range_key       = "GSI3SK"
    projection_type = "ALL"
  }

  # GSI4: Audit events by user
  global_secondary_index {
    name            = local.gsi_names.gsi4
    hash_key        = "GSI4PK"
    range_key       = "GSI4SK"
    projection_type = "ALL"
  }

  # GSI5: Audit events by event type
  global_secondary_index {
    name            = local.gsi_names.gsi5
    hash_key        = "GSI5PK"
    range_key       = "GSI5SK"
    projection_type = "ALL"
  }

  # ==========================================================================
  # TTL Configuration
  # ==========================================================================
  # Used for:
  # - Invitation token auto-expiry (7 days + 24h buffer)
  # - Audit event hot storage expiry (30 days)
  ttl {
    attribute_name = local.ttl_attribute_name
    enabled        = true
  }

  # ==========================================================================
  # Point-in-Time Recovery (PITR)
  # ==========================================================================
  point_in_time_recovery {
    enabled = var.enable_pitr
  }

  # ==========================================================================
  # Server-Side Encryption (SSE)
  # ==========================================================================
  server_side_encryption {
    enabled = var.enable_server_side_encryption
    # Uses AWS managed KMS key by default (aws/dynamodb)
  }

  # ==========================================================================
  # Deletion Protection
  # ==========================================================================
  deletion_protection_enabled = var.enable_deletion_protection

  # ==========================================================================
  # DynamoDB Streams Configuration
  # ==========================================================================
  # Required for:
  # - Audit event archiving (capture TTL deletions)
  # - Cross-region replication (Global Tables)
  dynamic "stream_specification" {
    for_each = var.stream_enabled ? [1] : []
    content {
      stream_enabled   = true
      stream_view_type = var.stream_view_type
    }
  }

  # ==========================================================================
  # Global Table Replicas (PROD only for DR)
  # ==========================================================================
  dynamic "replica" {
    for_each = var.enable_global_tables ? var.replica_regions : []
    content {
      region_name = replica.value
    }
  }

  # ==========================================================================
  # Tags
  # ==========================================================================
  tags = local.common_tags

  lifecycle {
    # Prevent accidental destruction of the table
    prevent_destroy = false  # Set to true for production

    # Ignore changes to replicas managed outside Terraform
    ignore_changes = [
      replica,
    ]
  }
}
```

---

## 4. gsi.tf

```hcl
# =============================================================================
# Global Secondary Index Documentation
# =============================================================================
# Worker: worker-1-dynamodb-tables-module
# Stage: Stage 2 - Infrastructure Terraform
# Project: project-plan-2-access-management
# =============================================================================
#
# Note: GSIs are defined inline in main.tf because Terraform's AWS provider
# requires GSIs to be defined as part of the aws_dynamodb_table resource.
# This file documents the GSI design and access patterns.
# =============================================================================

# =============================================================================
# GSI1: Status/Expiry, Category, and Name Lookups
# =============================================================================
#
# Partition Key (GSI1PK):
#   - Permissions by category:     CATEGORY#{category}
#   - Permission sets by org:      ORG#{orgId}
#   - Invitations by status:       ORG#{orgId}#STATUS#{status}
#   - Teams by active status:      ORG#{orgId}#ACTIVE#{active}
#   - Team roles by active status: ORG#{orgId}#ACTIVE#{active}
#   - Team members by user:        USER#{userId}
#   - Platform roles by active:    PLATFORM#ACTIVE#{active}
#   - Org roles by active:         ORG#{orgId}#ACTIVE#{active}
#   - User role assignments:       ORG#{orgId}#ROLE#{roleId}
#
# Sort Key (GSI1SK):
#   - Permissions:                 PERM#{permissionId}
#   - Permission sets:             PERMSET#{dateCreated}
#   - Invitations:                 {expiresAt}#{invitationId}
#   - Teams:                       TEAM#{name}
#   - Team roles:                  TEAMROLE#{name}
#   - Team members:                ORG#{orgId}#TEAM#{teamId}
#   - Roles:                       ROLE#{name}
#   - User role assignments:       USER#{userId}
#
# Access Patterns Supported:
#   1. List permissions by category
#   2. List permission sets by org sorted by date
#   3. List pending invitations by org sorted by expiry
#   4. Find team by name within org
#   5. Find team role by name within org
#   6. Get all teams for a user
#   7. List users assigned to a specific role
# =============================================================================


# =============================================================================
# GSI2: Email, Active Status, and Division Lookups
# =============================================================================
#
# Partition Key (GSI2PK):
#   - Invitations by email:        EMAIL#{email}
#   - Permission sets by status:   PERMSET#ACTIVE#{active}
#   - Teams by division:           ORG#{orgId}#DIV#{divisionId}
#   - Team members by role:        ORG#{orgId}#TEAM#{teamId}#ROLE#{teamRoleId}
#
# Sort Key (GSI2SK):
#   - Invitations:                 ORG#{orgId}#{dateCreated}
#   - Permission sets:             ORG#{orgId}#{dateCreated}
#   - Teams:                       TEAM#{teamId}
#   - Team members:                MEMBER#{userId}
#
# Access Patterns Supported:
#   1. Find invitations by email address (duplicate checking)
#   2. Find invitation by email + org (for checking existing membership)
#   3. List active permission sets across all orgs
#   4. List teams within a division
#   5. List team members filtered by role
# =============================================================================


# =============================================================================
# GSI3: User Team Memberships and Role Member Lookups
# =============================================================================
#
# Partition Key (GSI3PK):
#   - User's team memberships:     USER#{userId}
#   - Not used for other entities (sparse index)
#
# Sort Key (GSI3SK):
#   - Team memberships:            ORG#{orgId}#TEAM#{teamId}
#
# Access Patterns Supported:
#   1. Get all team memberships for a user
#   2. Get user's teams filtered by org
# =============================================================================


# =============================================================================
# GSI4: Audit Events by User
# =============================================================================
#
# Partition Key (GSI4PK):
#   - Audit by user:               USER#{userId}
#
# Sort Key (GSI4SK):
#   - Timestamp-ordered:           {timestamp}#{eventId}
#
# Access Patterns Supported:
#   1. Query all audit events for a specific user
#   2. Query user audit events within a time range
# =============================================================================


# =============================================================================
# GSI5: Audit Events by Event Type
# =============================================================================
#
# Partition Key (GSI5PK):
#   - Audit by org + type:         ORG#{orgId}#TYPE#{eventType}
#
# Sort Key (GSI5SK):
#   - Timestamp-ordered:           {timestamp}#{eventId}
#
# Event Types:
#   - AUTHORIZATION
#   - PERMISSION_CHANGE
#   - USER_MANAGEMENT
#   - TEAM_MEMBERSHIP
#   - ROLE_CHANGE
#   - INVITATION
#   - CONFIGURATION
#
# Access Patterns Supported:
#   1. Query audit events by event type for an org
#   2. Query specific event type within time range
# =============================================================================


# =============================================================================
# GSI Summary Table
# =============================================================================
#
# | GSI  | PK       | SK       | Purpose                              |
# |------|----------|----------|--------------------------------------|
# | GSI1 | GSI1PK   | GSI1SK   | Status/expiry, category, name lookup |
# | GSI2 | GSI2PK   | GSI2SK   | Email, active status, division       |
# | GSI3 | GSI3PK   | GSI3SK   | User team memberships                |
# | GSI4 | GSI4PK   | GSI4SK   | Audit by user                        |
# | GSI5 | GSI5PK   | GSI5SK   | Audit by event type                  |
# =============================================================================


# =============================================================================
# Entity to GSI Mapping
# =============================================================================
#
# Permission Entity:
#   - GSI1: GSI1PK=CATEGORY#{category}, GSI1SK=PERM#{permissionId}
#
# Permission Set Entity:
#   - GSI1: GSI1PK=ORG#{orgId}, GSI1SK=PERMSET#{dateCreated}
#   - GSI2: GSI2PK=PERMSET#ACTIVE#{active}, GSI2SK=ORG#{orgId}#{dateCreated}
#
# Invitation Entity:
#   - GSI1: GSI1PK=ORG#{orgId}#STATUS#{status}, GSI1SK={expiresAt}#{invId}
#   - GSI2: GSI2PK=EMAIL#{email}, GSI2SK=ORG#{orgId}#{dateCreated}
#
# Team Entity:
#   - GSI1: GSI1PK=ORG#{orgId}#ACTIVE#{active}, GSI1SK=TEAM#{name}
#   - GSI2: GSI2PK=ORG#{orgId}#DIV#{divisionId}, GSI2SK=TEAM#{teamId}
#
# TeamRoleDefinition Entity:
#   - GSI1: GSI1PK=ORG#{orgId}#ACTIVE#{active}, GSI1SK=TEAMROLE#{name}
#
# TeamMember Entity:
#   - GSI1: GSI1PK=USER#{userId}, GSI1SK=ORG#{orgId}#TEAM#{teamId}
#   - GSI2: GSI2PK=ORG#{orgId}#TEAM#{teamId}#ROLE#{teamRoleId}, GSI2SK=MEMBER#{userId}
#   - GSI3: GSI3PK=USER#{userId}, GSI3SK=ORG#{orgId}#TEAM#{teamId}
#
# Platform Role Entity:
#   - GSI1: GSI1PK=PLATFORM#ACTIVE#{active}, GSI1SK=ROLE#{name}
#
# Organisation Role Entity:
#   - GSI1: GSI1PK=ORG#{orgId}#ACTIVE#{active}, GSI1SK=ROLE#{name}
#
# User Role Assignment Entity:
#   - GSI1: GSI1PK=ORG#{orgId}#ROLE#{roleId}, GSI1SK=USER#{userId}
#
# Audit Event Entity:
#   - GSI4: GSI4PK=USER#{userId}, GSI4SK={timestamp}#{eventId}
#   - GSI5: GSI5PK=ORG#{orgId}#TYPE#{eventType}, GSI5SK={timestamp}#{eventId}
# =============================================================================
```

---

## 5. outputs.tf

```hcl
# =============================================================================
# Output Values for DynamoDB Access Management Table
# =============================================================================
# Worker: worker-1-dynamodb-tables-module
# Stage: Stage 2 - Infrastructure Terraform
# Project: project-plan-2-access-management
# =============================================================================

# =============================================================================
# Table Outputs
# =============================================================================

output "table_name" {
  description = "Name of the DynamoDB table"
  value       = aws_dynamodb_table.access_management.name
}

output "table_arn" {
  description = "ARN of the DynamoDB table"
  value       = aws_dynamodb_table.access_management.arn
}

output "table_id" {
  description = "ID of the DynamoDB table"
  value       = aws_dynamodb_table.access_management.id
}

# =============================================================================
# Stream Outputs
# =============================================================================

output "stream_arn" {
  description = "ARN of the DynamoDB stream (if enabled)"
  value       = var.stream_enabled ? aws_dynamodb_table.access_management.stream_arn : null
}

output "stream_label" {
  description = "Label of the DynamoDB stream (if enabled)"
  value       = var.stream_enabled ? aws_dynamodb_table.access_management.stream_label : null
}

# =============================================================================
# GSI Outputs
# =============================================================================

output "gsi_names" {
  description = "Map of GSI names"
  value       = local.gsi_names
}

output "gsi1_name" {
  description = "Name of GSI1 (status/expiry, category, name lookups)"
  value       = local.gsi_names.gsi1
}

output "gsi2_name" {
  description = "Name of GSI2 (email, active status, division lookups)"
  value       = local.gsi_names.gsi2
}

output "gsi3_name" {
  description = "Name of GSI3 (user team memberships)"
  value       = local.gsi_names.gsi3
}

output "gsi4_name" {
  description = "Name of GSI4 (audit by user)"
  value       = local.gsi_names.gsi4
}

output "gsi5_name" {
  description = "Name of GSI5 (audit by event type)"
  value       = local.gsi_names.gsi5
}

# =============================================================================
# GSI ARNs (for IAM policies)
# =============================================================================

output "gsi_arns" {
  description = "Map of GSI ARNs for IAM policy configuration"
  value = {
    gsi1 = "${aws_dynamodb_table.access_management.arn}/index/${local.gsi_names.gsi1}"
    gsi2 = "${aws_dynamodb_table.access_management.arn}/index/${local.gsi_names.gsi2}"
    gsi3 = "${aws_dynamodb_table.access_management.arn}/index/${local.gsi_names.gsi3}"
    gsi4 = "${aws_dynamodb_table.access_management.arn}/index/${local.gsi_names.gsi4}"
    gsi5 = "${aws_dynamodb_table.access_management.arn}/index/${local.gsi_names.gsi5}"
  }
}

output "all_index_arns" {
  description = "ARN pattern for all indexes (for IAM policies)"
  value       = "${aws_dynamodb_table.access_management.arn}/index/*"
}

# =============================================================================
# Configuration Outputs
# =============================================================================

output "ttl_attribute_name" {
  description = "Name of the TTL attribute"
  value       = local.ttl_attribute_name
}

output "billing_mode" {
  description = "Billing mode of the table"
  value       = aws_dynamodb_table.access_management.billing_mode
}

output "pitr_enabled" {
  description = "Whether Point-in-Time Recovery is enabled"
  value       = var.enable_pitr
}

output "deletion_protection_enabled" {
  description = "Whether deletion protection is enabled"
  value       = var.enable_deletion_protection
}

# =============================================================================
# Primary Key Configuration
# =============================================================================

output "primary_key" {
  description = "Primary key configuration"
  value = {
    partition_key = "PK"
    sort_key      = "SK"
  }
}

# =============================================================================
# Entity Key Patterns (for documentation/reference)
# =============================================================================

output "entity_key_patterns" {
  description = "Entity key patterns for single-table design"
  value       = local.entity_patterns
}
```

---

## 6. Usage Example

```hcl
# =============================================================================
# Example Usage of DynamoDB Access Management Module
# =============================================================================

# Development Environment
module "dynamodb_access_management_dev" {
  source = "./modules/dynamodb-access-management"

  environment                   = "dev"
  project_name                  = "bbws-access"
  enable_pitr                   = true
  enable_server_side_encryption = true
  enable_deletion_protection    = false  # Allow deletion in dev
  enable_global_tables          = false  # No DR in dev
  stream_enabled                = true
  stream_view_type              = "NEW_AND_OLD_IMAGES"

  tags = {
    Owner = "DevTeam"
  }
}

# SIT Environment
module "dynamodb_access_management_sit" {
  source = "./modules/dynamodb-access-management"

  environment                   = "sit"
  project_name                  = "bbws-access"
  enable_pitr                   = true
  enable_server_side_encryption = true
  enable_deletion_protection    = true  # Protect in SIT
  enable_global_tables          = false  # No DR in SIT
  stream_enabled                = true
  stream_view_type              = "NEW_AND_OLD_IMAGES"

  tags = {
    Owner = "QATeam"
  }
}

# Production Environment (with DR)
module "dynamodb_access_management_prod" {
  source = "./modules/dynamodb-access-management"

  environment                   = "prod"
  project_name                  = "bbws-access"
  enable_pitr                   = true
  enable_server_side_encryption = true
  enable_deletion_protection    = true   # Protect in prod
  enable_global_tables          = true   # Enable DR with eu-west-1 replica
  replica_regions               = ["eu-west-1"]
  stream_enabled                = true
  stream_view_type              = "NEW_AND_OLD_IMAGES"

  tags = {
    Owner       = "OpsTeam"
    CriticalApp = "true"
  }
}

# =============================================================================
# Output References
# =============================================================================

output "dev_table_name" {
  value = module.dynamodb_access_management_dev.table_name
}

output "dev_table_arn" {
  value = module.dynamodb_access_management_dev.table_arn
}

output "dev_gsi_arns" {
  value = module.dynamodb_access_management_dev.gsi_arns
}
```

---

## 7. IAM Policy Example

```hcl
# =============================================================================
# IAM Policy for Lambda Functions to Access DynamoDB Table
# =============================================================================

data "aws_iam_policy_document" "dynamodb_access" {
  # Read/Write to main table
  statement {
    sid    = "DynamoDBTableAccess"
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:BatchGetItem",
      "dynamodb:BatchWriteItem",
      "dynamodb:TransactGetItems",
      "dynamodb:TransactWriteItems"
    ]
    resources = [
      module.dynamodb_access_management.table_arn
    ]
  }

  # Query GSIs
  statement {
    sid    = "DynamoDBGSIAccess"
    effect = "Allow"
    actions = [
      "dynamodb:Query",
      "dynamodb:Scan"
    ]
    resources = [
      module.dynamodb_access_management.all_index_arns
    ]
  }
}

resource "aws_iam_policy" "lambda_dynamodb_access" {
  name        = "bbws-access-${var.environment}-lambda-dynamodb-policy"
  description = "IAM policy for Lambda functions to access Access Management DynamoDB table"
  policy      = data.aws_iam_policy_document.dynamodb_access.json
}
```

---

## 8. Entity Key Patterns Reference

### Permission Service Entities

| Entity | PK | SK | GSI1PK | GSI1SK | GSI2PK | GSI2SK |
|--------|----|----|--------|--------|--------|--------|
| Permission | `PERM#{permId}` | `METADATA` | `CATEGORY#{category}` | `PERM#{permId}` | - | - |
| Permission Set | `ORG#{orgId}` | `PERMSET#{setId}` | `ORG#{orgId}` | `PERMSET#{dateCreated}` | `PERMSET#ACTIVE#{active}` | `ORG#{orgId}#{dateCreated}` |
| Platform Permission Set | `PLATFORM` | `PERMSET#{setId}` | - | - | - | - |

### Invitation Service Entities

| Entity | PK | SK | GSI1PK | GSI1SK | GSI2PK | GSI2SK |
|--------|----|----|--------|--------|--------|--------|
| Invitation | `ORG#{orgId}` | `INV#{invId}` | `ORG#{orgId}#STATUS#{status}` | `{expiresAt}#{invId}` | `EMAIL#{email}` | `ORG#{orgId}#{dateCreated}` |
| Invitation Token | `INVTOKEN#{token}` | `METADATA` | - | - | - | - |

### Team Service Entities

| Entity | PK | SK | GSI1PK | GSI1SK | GSI2PK | GSI2SK | GSI3PK | GSI3SK |
|--------|----|----|--------|--------|--------|--------|--------|--------|
| Team | `ORG#{orgId}` | `TEAM#{teamId}` | `ORG#{orgId}#ACTIVE#{active}` | `TEAM#{name}` | `ORG#{orgId}#DIV#{divId}` | `TEAM#{teamId}` | - | - |
| Team Role Definition | `ORG#{orgId}` | `TEAMROLE#{roleId}` | `ORG#{orgId}#ACTIVE#{active}` | `TEAMROLE#{name}` | - | - | - | - |
| Team Member | `ORG#{orgId}#TEAM#{teamId}` | `MEMBER#{userId}` | `USER#{userId}` | `ORG#{orgId}#TEAM#{teamId}` | `ORG#{orgId}#TEAM#{teamId}#ROLE#{roleId}` | `MEMBER#{userId}` | `USER#{userId}` | `ORG#{orgId}#TEAM#{teamId}` |

### Role Service Entities

| Entity | PK | SK | GSI1PK | GSI1SK |
|--------|----|----|--------|--------|
| Platform Role | `PLATFORM` | `ROLE#{roleId}` | `PLATFORM#ACTIVE#{active}` | `ROLE#{name}` |
| Organisation Role | `ORG#{orgId}` | `ROLE#{roleId}` | `ORG#{orgId}#ACTIVE#{active}` | `ROLE#{name}` |
| User Role Assignment | `ORG#{orgId}#USER#{userId}` | `ROLE#{roleId}` | `ORG#{orgId}#ROLE#{roleId}` | `USER#{userId}` |

### Audit Service Entities

| Entity | PK | SK | GSI4PK | GSI4SK | GSI5PK | GSI5SK |
|--------|----|----|--------|--------|--------|--------|
| Audit Event | `ORG#{orgId}#DATE#{YYYY-MM-DD}` | `EVENT#{timestamp}#{eventId}` | `USER#{userId}` | `{timestamp}#{eventId}` | `ORG#{orgId}#TYPE#{eventType}` | `{timestamp}#{eventId}` |

---

## 9. Success Criteria Checklist

- [x] Table uses on-demand capacity (PAY_PER_REQUEST)
- [x] All 5 GSIs defined with documented access patterns
- [x] PITR enabled (configurable)
- [x] TTL configured for invitation tokens and audit events
- [x] Server-side encryption enabled (AWS managed KMS)
- [x] No hardcoded values (all parameterized)
- [x] Environment parameterized (dev, sit, prod)
- [x] Follows BBWS naming convention (`bbws-access-{env}-ddb-access-management`)
- [x] DynamoDB Streams enabled for audit archiving
- [x] Global Tables support for PROD DR (af-south-1 to eu-west-1)
- [x] Deletion protection configurable
- [x] Comprehensive outputs for IAM policy creation
- [x] Entity key patterns documented for all services

---

## 10. Validation Commands

```bash
# Initialize Terraform
terraform init

# Validate Terraform configuration
terraform validate

# Format Terraform files
terraform fmt -recursive

# Plan deployment
terraform plan -var="environment=dev"

# Apply (with approval)
terraform apply -var="environment=dev"
```

---

**Worker**: worker-1-dynamodb-tables-module
**Stage**: Stage 2 - Infrastructure Terraform
**Status**: COMPLETE
**Created**: 2026-01-23
