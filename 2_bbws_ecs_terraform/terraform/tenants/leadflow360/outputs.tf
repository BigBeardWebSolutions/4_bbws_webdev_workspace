# leadflow360 Tenant Outputs

output "tenant_name" {
  description = "Tenant name"
  value       = var.tenant_name
}

output "domain_name" {
  description = "Tenant domain"
  value       = var.domain_name
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = module.ecs_tenant.service_name
}

output "efs_access_point_id" {
  description = "EFS access point ID"
  value       = module.ecs_tenant.efs_access_point_id
}

output "db_secret_arn" {
  description = "Database credentials secret ARN"
  value       = module.ecs_tenant.db_secret_arn
}

output "target_group_arn" {
  description = "ALB target group ARN"
  value       = module.ecs_tenant.target_group_arn
}
