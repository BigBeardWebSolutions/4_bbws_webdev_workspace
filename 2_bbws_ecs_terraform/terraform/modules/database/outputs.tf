# Database Module - Outputs

#------------------------------------------------------------------------------
# Database Information
#------------------------------------------------------------------------------

output "database_name" {
  description = "Name of the created database"
  value       = "${var.tenant_name}_db"
}

output "database_username" {
  description = "Database username for the tenant"
  value       = "${var.tenant_name}_user"
}

output "database_created" {
  description = "Timestamp when database was created/updated"
  value       = null_resource.create_database.id
}

output "database_verified" {
  description = "Verification status (null if verification disabled)"
  value       = var.verify_database ? null_resource.verify_database[0].id : null
}

#------------------------------------------------------------------------------
# Secret Information
#------------------------------------------------------------------------------

output "secret_arn" {
  description = "ARN of the Secrets Manager secret (passthrough from input)"
  value       = var.tenant_db_secret_arn
}
