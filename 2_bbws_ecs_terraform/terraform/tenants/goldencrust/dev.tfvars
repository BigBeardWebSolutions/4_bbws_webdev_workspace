# Goldencrust Tenant - DEV Environment Configuration

# Tenant Identity
tenant_name  = "goldencrust"
environment  = "dev"
domain_name  = "goldencrust.wpdev.kimmyai.io"
alb_priority = 40

# AWS Configuration
aws_region  = "eu-west-1"
aws_profile = "Tebogo-dev"

# ECS Configuration
wordpress_image = "536580886816.dkr.ecr.eu-west-1.amazonaws.com/dev-wordpress:latest"
task_cpu        = 256
task_memory     = 512
desired_count   = 1

# Health Check Configuration
health_check_path                = "/"
health_check_interval            = 30
health_check_healthy_threshold   = 2
health_check_unhealthy_threshold = 3

# Database Configuration
init_db_script_path = "../../../../2_bbws_agents/utils/init_tenant_db.py"
verify_database     = true

# DNS Configuration (not used in DEV)
create_dns_records = false

# Feature Flags
wordpress_debug = true
enable_ecs_exec = true

# Tags
tags = {
  Project     = "BBWS"
  Tenant      = "goldencrust"
  Environment = "dev"
  CostCenter  = "Engineering"
}
