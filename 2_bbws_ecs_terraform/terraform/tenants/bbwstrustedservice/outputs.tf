# Goldencrust Tenant - Outputs

#------------------------------------------------------------------------------
# Tenant Information
#------------------------------------------------------------------------------

output "tenant_name" {
  description = "Tenant name"
  value       = var.tenant_name
}

output "environment" {
  description = "Environment"
  value       = var.environment
}

output "tenant_url" {
  description = "Tenant URL"
  value       = module.ecs_tenant.tenant_url
}

#------------------------------------------------------------------------------
# ECS Service
#------------------------------------------------------------------------------

output "service_name" {
  description = "ECS service name"
  value       = module.ecs_tenant.service_name
}

output "service_id" {
  description = "ECS service ARN"
  value       = module.ecs_tenant.service_id
}

output "task_definition_arn" {
  description = "ECS task definition ARN"
  value       = module.ecs_tenant.task_definition_arn
}

#------------------------------------------------------------------------------
# Database
#------------------------------------------------------------------------------

output "db_secret_arn" {
  description = "Database credentials secret ARN"
  value       = module.ecs_tenant.db_secret_arn
}

output "db_name" {
  description = "Database name"
  value       = module.database.database_name
}

output "db_username" {
  description = "Database username"
  value       = module.database.database_username
}

#------------------------------------------------------------------------------
# Storage
#------------------------------------------------------------------------------

output "efs_access_point_id" {
  description = "EFS access point ID"
  value       = module.ecs_tenant.efs_access_point_id
}

#------------------------------------------------------------------------------
# Load Balancer
#------------------------------------------------------------------------------

output "target_group_arn" {
  description = "ALB target group ARN"
  value       = module.ecs_tenant.target_group_arn
}

output "alb_priority" {
  description = "ALB listener rule priority"
  value       = module.ecs_tenant.listener_rule_priority
}

#------------------------------------------------------------------------------
# DNS (PROD only)
#------------------------------------------------------------------------------

output "dns_record" {
  description = "DNS A record (null if not created)"
  value       = var.environment == "prod" && var.create_dns_records ? module.dns_cloudfront[0].a_record_name : null
}

#------------------------------------------------------------------------------
# Complete Configuration
#------------------------------------------------------------------------------

output "tenant_config" {
  description = "Complete tenant configuration"
  value = {
    tenant_name = var.tenant_name
    environment = var.environment
    url         = module.ecs_tenant.tenant_url

    infrastructure = {
      service_name         = module.ecs_tenant.service_name
      service_arn          = module.ecs_tenant.service_id
      task_definition_arn  = module.ecs_tenant.task_definition_arn
      target_group_arn     = module.ecs_tenant.target_group_arn
      alb_priority         = module.ecs_tenant.listener_rule_priority
      efs_access_point_id  = module.ecs_tenant.efs_access_point_id
    }

    database = {
      name       = module.database.database_name
      username   = module.database.database_username
      secret_arn = module.ecs_tenant.db_secret_arn
    }

    dns = {
      record_created = var.environment == "prod" && var.create_dns_records
      domain_name    = var.domain_name
    }
  }
  sensitive = false
}
