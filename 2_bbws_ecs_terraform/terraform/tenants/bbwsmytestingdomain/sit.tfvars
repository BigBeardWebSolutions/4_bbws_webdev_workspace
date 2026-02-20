# BBWSMyTestingDomain Tenant - SIT Environment Configuration

# Tenant Identity
tenant_name  = "bbwsmytestingdomain"
environment  = "sit"
domain_name  = "bbwsmytestingdomain.wpsit.kimmyai.io"
alb_priority = 146

# AWS Configuration
aws_region  = "eu-west-1"
aws_profile = "Tebogo-sit"

# ECS Configuration
wordpress_image = "815856636111.dkr.ecr.eu-west-1.amazonaws.com/sit-wordpress:latest"
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

# DNS Configuration (not used in SIT - testing via ALB only)
create_dns_records = false

# Feature Flags
wordpress_debug = false
enable_ecs_exec = true

# Tags
tags = {
  Project     = "BBWS"
  Tenant      = "bbwsmytestingdomain"
  Environment = "sit"
  CostCenter  = "Engineering"
}
