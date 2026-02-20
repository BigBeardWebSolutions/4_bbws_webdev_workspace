# cliplok Tenant - Outputs

output "tenant_name" {
  description = "Tenant name"
  value       = var.tenant_name
}

output "environment" {
  description = "Environment"
  value       = var.environment
}

output "domain_name" {
  description = "Domain name"
  value       = var.domain_name
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = module.ecs_tenant.service_name
}

output "target_group_arn" {
  description = "Target group ARN"
  value       = module.ecs_tenant.target_group_arn
}

output "efs_access_point_id" {
  description = "EFS access point ID"
  value       = module.ecs_tenant.efs_access_point_id
}

output "db_secret_arn" {
  description = "Database credentials secret ARN"
  value       = module.ecs_tenant.db_secret_arn
}

output "database_name" {
  description = "Database name"
  value       = module.database.database_name
}

output "database_user" {
  description = "Database user"
  value       = module.database.database_username
}
