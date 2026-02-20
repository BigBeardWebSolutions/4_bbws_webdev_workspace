# Worker Instructions: Terraform DynamoDB Module

**Worker ID**: worker-3-terraform-dynamodb-module
**Stage**: Stage 1 - Repository Setup & Infrastructure Code
**Project**: project-plan-campaigns

---

## Task

Create the Terraform DynamoDB module (`dynamodb.tf`) for the Campaigns table with GSI and on-demand capacity.

---

## Inputs

**Primary Input**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/2.1.3_LLD_Campaigns_Lambda.md`

**Reference**:
- Section 5: Data Models
- Section 5.1: DynamoDB Schema

---

## Deliverables

Create `terraform/dynamodb.tf` with the following:

### 1. Table Configuration

| Attribute | Value |
|-----------|-------|
| Table Name | `campaigns` |
| Billing Mode | PAY_PER_REQUEST (on-demand) |
| PITR | Enabled |
| Encryption | AWS Managed Key |

### 2. Primary Key Structure

| Key | Attribute | Type | Pattern |
|-----|-----------|------|---------|
| PK | `PK` | String | `CAMPAIGN#{code}` |
| SK | `SK` | String | `METADATA` |

### 3. Global Secondary Index (GSI)

**GSI1: CampaignsByStatusIndex**

| Attribute | Key Type | Pattern |
|-----------|----------|---------|
| GSI1_PK | Partition Key | `CAMPAIGN` |
| GSI1_SK | Sort Key | `{status}#{code}` |

Projection: ALL

---

## Expected Output Format

```hcl
# terraform/dynamodb.tf

# Campaigns DynamoDB Table
# Table name is simply "campaigns" across all environments (no prefix/suffix)
resource "aws_dynamodb_table" "campaigns" {
  name         = "campaigns"
  billing_mode = "PAY_PER_REQUEST"  # On-demand - REQUIRED

  # Primary Key
  hash_key  = "PK"
  range_key = "SK"

  # Attribute definitions
  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  attribute {
    name = "GSI1_PK"
    type = "S"
  }

  attribute {
    name = "GSI1_SK"
    type = "S"
  }

  # GSI1: CampaignsByStatusIndex
  global_secondary_index {
    name            = "CampaignsByStatusIndex"
    hash_key        = "GSI1_PK"
    range_key       = "GSI1_SK"
    projection_type = "ALL"
  }

  # Point-in-Time Recovery (PITR) - REQUIRED
  point_in_time_recovery {
    enabled = true
  }

  # Server-side encryption
  server_side_encryption {
    enabled = true
  }

  # Time-to-Live (optional, not used for campaigns)
  # ttl {
  #   attribute_name = "ttl"
  #   enabled        = true
  # }

  tags = merge(var.common_tags, {
    Name        = "campaigns"
    Component   = "CampaignsLambda"
    TableType   = "Campaigns"
  })

  lifecycle {
    prevent_destroy = var.environment == "prod" ? true : false
  }
}

# DynamoDB Table Auto Scaling (not needed for on-demand)
# Note: On-demand billing automatically scales read/write capacity
```

---

## Variables Required (add to variables.tf)

```hcl
variable "dynamodb_table_name" {
  description = "DynamoDB table name for campaigns"
  type        = string
  default     = "campaigns"  # Same name across all environments
}
```

---

## Outputs Required (add to outputs.tf)

```hcl
output "dynamodb_table_name" {
  description = "Name of the Campaigns DynamoDB table"
  value       = aws_dynamodb_table.campaigns.name
}

output "dynamodb_table_arn" {
  description = "ARN of the Campaigns DynamoDB table"
  value       = aws_dynamodb_table.campaigns.arn
}

output "dynamodb_table_id" {
  description = "ID of the Campaigns DynamoDB table"
  value       = aws_dynamodb_table.campaigns.id
}

output "dynamodb_gsi_names" {
  description = "Names of Global Secondary Indexes"
  value = {
    campaigns_by_status = "CampaignsByStatusIndex"
  }
}
```

---

## IMPORTANT Requirements

### From CLAUDE.md
1. **DynamoDB capacity mode must always be "on-demand"**
   - Use `billing_mode = "PAY_PER_REQUEST"`
   - NEVER use provisioned capacity

2. **Enable PITR (Point-in-Time Recovery)**
   - Required for disaster recovery
   - `point_in_time_recovery { enabled = true }`

3. **Cross-Region Replication (PROD only)**
   - PROD environment: af-south-1 (primary) with eu-west-1 (DR)
   - Configure Global Tables for PROD

### Cross-Region Replication (PROD Only)

For PROD environment, add:

```hcl
# Global Table Replica for DR (PROD only)
resource "aws_dynamodb_table_replica" "campaigns_dr" {
  count = var.environment == "prod" ? 1 : 0

  global_table_arn = aws_dynamodb_table.campaigns.arn
  region           = var.dr_region  # eu-west-1

  tags = merge(var.common_tags, {
    Name = "campaigns-replica"
    Type = "DR-Replica"
  })
}

variable "dr_region" {
  description = "Disaster recovery region"
  type        = string
  default     = "eu-west-1"
}
```

---

## Success Criteria

- [ ] Table name is `campaigns` (no prefix/suffix, same across all environments)
- [ ] Billing mode is PAY_PER_REQUEST (on-demand)
- [ ] PITR is enabled
- [ ] GSI1 (CampaignsByStatusIndex) is configured
- [ ] Server-side encryption enabled
- [ ] Tags include Project, Component, CostCenter
- [ ] No hardcoded values
- [ ] Terraform validates successfully

---

## Execution Steps

1. Read LLD Section 5 for DynamoDB schema
2. Create dynamodb.tf with table and GSI
3. Ensure billing_mode is PAY_PER_REQUEST
4. Enable PITR
5. Add encryption configuration
6. Add variables and outputs
7. Add lifecycle rules for PROD protection
8. Run `terraform validate`
9. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-15
