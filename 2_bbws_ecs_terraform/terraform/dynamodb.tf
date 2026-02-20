# DynamoDB State Tracking Tables with Cross-Region Replication
# Monitors tenant provisioning, modifications, and transactions
# Implements on-demand billing and cross-region DR to eu-west-1

#------------------------------------------------------------------------------
# Tenant State Management Table
# Tracks tenant provisioning and modification state for each tenant
#------------------------------------------------------------------------------
resource "aws_dynamodb_table" "tenant_state" {
  name           = "${var.environment}-tenant-state"
  billing_mode   = "PAY_PER_REQUEST"  # On-demand capacity (no provisioned throughput)
  stream_enabled = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  hash_key  = "tenant_id"
  range_key = "state_timestamp"

  attribute {
    name = "tenant_id"
    type = "S"  # String
  }

  attribute {
    name = "state_timestamp"
    type = "N"  # Number (Unix timestamp)
  }

  attribute {
    name = "status"
    type = "S"  # String (provisioning, active, modifying, failed, deleted)
  }

  # Global Secondary Index for querying by status
  global_secondary_index {
    name            = "status-index"
    hash_key        = "status"
    range_key       = "state_timestamp"
    projection_type = "ALL"
  }

  # Point-in-time recovery for data protection
  point_in_time_recovery {
    enabled = true
  }

  # Server-side encryption at rest
  server_side_encryption {
    enabled = true
  }

  # Cross-region replication (SIT and PROD only)
  # SIT (eu-west-1) replicates to af-south-1
  # PROD (af-south-1) replicates to eu-west-1
  dynamic "replica" {
    for_each = var.environment == "sit" ? ["af-south-1"] : var.environment == "prod" ? ["eu-west-1"] : []
    content {
      region_name            = replica.value
      point_in_time_recovery = true
    }
  }

  tags = {
    Name        = "${var.environment}-tenant-state"
    Environment = var.environment
    Purpose     = "Track tenant provisioning and modification state"
  }
}

#------------------------------------------------------------------------------
# Transaction Log Table
# Tracks site generation and modification transactions
# Supports failed transaction monitoring and deadletter queue analysis
#------------------------------------------------------------------------------
resource "aws_dynamodb_table" "transaction_log" {
  name           = "${var.environment}-transaction-log"
  billing_mode   = "PAY_PER_REQUEST"  # On-demand capacity
  stream_enabled = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  hash_key  = "transaction_id"
  range_key = "timestamp"

  attribute {
    name = "transaction_id"
    type = "S"  # String (UUID)
  }

  attribute {
    name = "timestamp"
    type = "N"  # Number (Unix timestamp)
  }

  attribute {
    name = "tenant_id"
    type = "S"  # String
  }

  attribute {
    name = "status"
    type = "S"  # String (pending, processing, completed, failed, stuck)
  }

  # Global Secondary Index for querying tenant transactions
  global_secondary_index {
    name            = "tenant-index"
    hash_key        = "tenant_id"
    range_key       = "timestamp"
    projection_type = "ALL"
  }

  # Global Secondary Index for querying failed transactions
  global_secondary_index {
    name            = "status-index"
    hash_key        = "status"
    range_key       = "timestamp"
    projection_type = "ALL"
  }

  # Time-to-Live for automatic cleanup (90 days)
  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  # Point-in-time recovery
  point_in_time_recovery {
    enabled = true
  }

  # Server-side encryption
  server_side_encryption {
    enabled = true
  }

  # Cross-region replication (SIT and PROD only)
  # SIT (eu-west-1) replicates to af-south-1
  # PROD (af-south-1) replicates to eu-west-1
  dynamic "replica" {
    for_each = var.environment == "sit" ? ["af-south-1"] : var.environment == "prod" ? ["eu-west-1"] : []
    content {
      region_name            = replica.value
      point_in_time_recovery = true
    }
  }

  tags = {
    Name        = "${var.environment}-transaction-log"
    Environment = var.environment
    Purpose     = "Track site generation and modification transactions"
  }
}

#------------------------------------------------------------------------------
# Outputs
#------------------------------------------------------------------------------
output "tenant_state_table_name" {
  description = "Name of the tenant state DynamoDB table"
  value       = aws_dynamodb_table.tenant_state.name
}

output "tenant_state_table_arn" {
  description = "ARN of the tenant state DynamoDB table"
  value       = aws_dynamodb_table.tenant_state.arn
}

output "transaction_log_table_name" {
  description = "Name of the transaction log DynamoDB table"
  value       = aws_dynamodb_table.transaction_log.name
}

output "transaction_log_table_arn" {
  description = "ARN of the transaction log DynamoDB table"
  value       = aws_dynamodb_table.transaction_log.arn
}
