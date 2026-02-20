# vdanutrition Tenant - Outputs

output "tenant_name" {
  value = var.tenant_name
}

output "environment" {
  value = var.environment
}

output "tenant_url" {
  value = module.ecs_tenant.tenant_url
}

output "service_name" {
  value = module.ecs_tenant.service_name
}

output "service_id" {
  value = module.ecs_tenant.service_id
}

output "task_definition_arn" {
  value = module.ecs_tenant.task_definition_arn
}

output "db_secret_arn" {
  value = module.ecs_tenant.db_secret_arn
}

output "db_name" {
  value = module.database.database_name
}

output "db_username" {
  value = module.database.database_username
}

output "efs_access_point_id" {
  value = module.ecs_tenant.efs_access_point_id
}

output "target_group_arn" {
  value = module.ecs_tenant.target_group_arn
}

output "alb_priority" {
  value = module.ecs_tenant.listener_rule_priority
}
