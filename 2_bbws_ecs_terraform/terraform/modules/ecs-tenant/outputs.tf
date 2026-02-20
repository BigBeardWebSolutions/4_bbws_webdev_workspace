# ECS Tenant Module - Outputs

#------------------------------------------------------------------------------
# Service Information
#------------------------------------------------------------------------------

output "service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.tenant.name
}

output "service_id" {
  description = "ARN of the ECS service"
  value       = aws_ecs_service.tenant.id
}

output "service_cluster" {
  description = "Cluster the service is running in"
  value       = aws_ecs_service.tenant.cluster
}

#------------------------------------------------------------------------------
# Task Definition Information
#------------------------------------------------------------------------------

output "task_definition_arn" {
  description = "ARN of the ECS task definition"
  value       = aws_ecs_task_definition.tenant.arn
}

output "task_definition_family" {
  description = "Family of the ECS task definition"
  value       = aws_ecs_task_definition.tenant.family
}

output "task_definition_revision" {
  description = "Revision of the ECS task definition"
  value       = aws_ecs_task_definition.tenant.revision
}

#------------------------------------------------------------------------------
# Database Credentials
#------------------------------------------------------------------------------

output "db_secret_arn" {
  description = "ARN of the Secrets Manager secret containing database credentials"
  value       = aws_secretsmanager_secret.db.arn
}

output "db_secret_name" {
  description = "Name of the Secrets Manager secret"
  value       = aws_secretsmanager_secret.db.name
}

output "db_username" {
  description = "Database username for the tenant"
  value       = "${var.tenant_name}_user"
}

output "db_name" {
  description = "Database name for the tenant"
  value       = "${var.tenant_name}_db"
}

#------------------------------------------------------------------------------
# Storage Information
#------------------------------------------------------------------------------

output "efs_access_point_id" {
  description = "ID of the EFS access point"
  value       = aws_efs_access_point.tenant.id
}

output "efs_access_point_arn" {
  description = "ARN of the EFS access point"
  value       = aws_efs_access_point.tenant.arn
}

#------------------------------------------------------------------------------
# Load Balancer Information
#------------------------------------------------------------------------------

output "target_group_arn" {
  description = "ARN of the ALB target group"
  value       = aws_lb_target_group.tenant.arn
}

output "target_group_name" {
  description = "Name of the ALB target group"
  value       = aws_lb_target_group.tenant.name
}

output "listener_rule_arn" {
  description = "ARN of the ALB listener rule"
  value       = aws_lb_listener_rule.tenant.arn
}

output "listener_rule_priority" {
  description = "Priority of the ALB listener rule"
  value       = var.alb_priority
}

#------------------------------------------------------------------------------
# Tenant Configuration
#------------------------------------------------------------------------------

output "tenant_name" {
  description = "Name of the tenant"
  value       = var.tenant_name
}

output "domain_name" {
  description = "Domain name for the tenant"
  value       = var.domain_name
}

output "tenant_url" {
  description = "Full HTTPS URL for the tenant"
  value       = "https://${var.domain_name}"
}

#------------------------------------------------------------------------------
# Configuration Document (for auto-generated tenant config)
#------------------------------------------------------------------------------

output "tenant_config" {
  description = "Complete tenant configuration for documentation"
  value = {
    tenant_name = var.tenant_name
    environment = var.environment
    url         = "https://${var.domain_name}"

    infrastructure = {
      service_name         = aws_ecs_service.tenant.name
      service_arn          = aws_ecs_service.tenant.id
      task_definition_arn  = aws_ecs_task_definition.tenant.arn
      target_group_arn     = aws_lb_target_group.tenant.arn
      alb_priority         = var.alb_priority
      efs_access_point_id  = aws_efs_access_point.tenant.id
    }

    database = {
      name       = "${var.tenant_name}_db"
      username   = "${var.tenant_name}_user"
      secret_arn = aws_secretsmanager_secret.db.arn
      host       = var.rds_endpoint
      port       = 3306
    }
  }
}
