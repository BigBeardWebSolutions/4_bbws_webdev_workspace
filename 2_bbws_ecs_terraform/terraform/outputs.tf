# Outputs for POC1 - ECS Fargate Multi-Tenant WordPress

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "tenant_1_url" {
  description = "URL for Tenant 1 WordPress"
  value       = "http://${aws_lb.main.dns_name}/tenant-1/"
}

output "tenant_1_admin_url" {
  description = "Admin URL for Tenant 1 WordPress"
  value       = "http://${aws_lb.main.dns_name}/tenant-1/wp-admin"
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.main.arn
}

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.main.endpoint
}

output "rds_address" {
  description = "RDS instance address"
  value       = aws_db_instance.main.address
}

output "rds_master_secret_arn" {
  description = "ARN of RDS master credentials secret"
  value       = aws_secretsmanager_secret.rds_master.arn
}

output "efs_id" {
  description = "EFS file system ID"
  value       = aws_efs_file_system.main.id
}

output "tenant_1_access_point_id" {
  description = "EFS access point ID for tenant-1"
  value       = aws_efs_access_point.tenant_1.id
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "ecs_security_group_id" {
  description = "Security group ID for ECS tasks"
  value       = aws_security_group.ecs_tasks.id
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

output "alb_listener_arn" {
  description = "ARN of the ALB HTTP listener"
  value       = aws_lb_listener.http.arn
}

output "tenant_2_url" {
  description = "URL for tenant-2 WordPress site (use with Host header)"
  value       = "http://tenant2.localhost/ (or curl -H 'Host: tenant2.localhost' http://${aws_lb.main.dns_name}/)"
}

output "tenant_2_admin_url" {
  description = "URL for tenant-2 WordPress admin (use with Host header)"
  value       = "http://tenant2.localhost/wp-admin (or curl -H 'Host: tenant2.localhost' http://${aws_lb.main.dns_name}/wp-admin)"
}

output "tenant_2_access_point_id" {
  description = "EFS access point ID for tenant-2"
  value       = aws_efs_access_point.tenant_2.id
}
