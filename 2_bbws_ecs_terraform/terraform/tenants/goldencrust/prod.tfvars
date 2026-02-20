# Goldencrust Tenant - PROD Environment Configuration

# Tenant Identity
tenant_name  = "goldencrust"
environment  = "prod"
domain_name  = "goldencrust.wp.kimmyai.io"
alb_priority = 1040

# AWS Configuration
aws_region  = "af-south-1"
aws_profile = "Tebogo-prod"

# ECS Configuration
wordpress_image = "093646564004.dkr.ecr.af-south-1.amazonaws.com/prod-wordpress:latest"
task_cpu        = 512
task_memory     = 1024
desired_count   = 2

# Health Check Configuration
health_check_path                = "/"
health_check_interval            = 60
health_check_healthy_threshold   = 3
health_check_unhealthy_threshold = 2

# Database Configuration
init_db_script_path = "../../../../2_bbws_agents/utils/init_tenant_db.py"
verify_database     = true

# DNS Configuration (CloudFront + Route53)
create_dns_records     = true
route53_zone_id        = "Z1234567890ABC"  # TODO: Update with actual zone ID for wp.kimmyai.io
cloudfront_domain_name = "d1a2b3c4d5e6f7.cloudfront.net"  # TODO: Update with actual CloudFront domain
create_ipv6_record     = true
evaluate_target_health = false

# Feature Flags
wordpress_debug = false
enable_ecs_exec = false

# Tags
tags = {
  Project     = "BBWS"
  Tenant      = "goldencrust"
  Environment = "prod"
  CostCenter  = "Operations"
  Backup      = "Required"
}
