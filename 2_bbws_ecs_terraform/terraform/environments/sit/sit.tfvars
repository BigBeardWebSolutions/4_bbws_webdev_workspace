# SIT Environment Configuration
# BBWS Multi-Tenant WordPress Platform
# AWS Account: 815856636111 (af-south-1)

#------------------------------------------------------------------------------
# Account & Environment
#------------------------------------------------------------------------------
environment    = "sit"
aws_region     = "eu-west-1"
aws_account_id = "815856636111"

#------------------------------------------------------------------------------
# Network Configuration
# Unique CIDR block for VPC peering compatibility
# Using existing SIT VPC CIDR (deployed infrastructure uses 10.2.0.0/16)
# DEV: 10.0.0.0/16, SIT: 10.2.0.0/16, PROD: 10.3.0.0/16
#------------------------------------------------------------------------------
vpc_cidr              = "10.2.0.0/16"
public_subnet_cidrs   = ["10.2.1.0/24", "10.2.2.0/24"]
private_subnet_cidrs  = ["10.2.10.0/24", "10.2.11.0/24"]

#------------------------------------------------------------------------------
# RDS Configuration (Match DEV for consistency)
#------------------------------------------------------------------------------
rds_instance_class       = "db.t3.micro"
rds_master_username      = "admin"
rds_multi_az             = false
rds_backup_retention     = 7  # 7 days for SIT testing
rds_skip_final_snapshot  = false  # Preserve snapshots for debugging
rds_backup_window        = "03:00-04:00"
rds_maintenance_window   = "Mon:04:00-Mon:05:00"

#------------------------------------------------------------------------------
# ALB Configuration
#------------------------------------------------------------------------------
alb_deletion_protection = false  # Allow deletion in SIT

#------------------------------------------------------------------------------
# ECS Configuration (Match DEV)
#------------------------------------------------------------------------------
ecs_task_cpu    = "512"
ecs_task_memory = "1024"

#------------------------------------------------------------------------------
# WordPress Configuration
# Using DEV ECR image directly (cross-account pull)
# Ensures SIT runs the exact same image tested in DEV
# See: ecr_cross_account_policy.tf (DEV) + sit_ecr_pull_policy.tf (SIT)
#------------------------------------------------------------------------------
use_ecr_image       = false
wordpress_image     = "536580886816.dkr.ecr.eu-west-1.amazonaws.com/dev-wordpress"
wordpress_image_tag = "latest"

#------------------------------------------------------------------------------
# CloudFront Configuration
#------------------------------------------------------------------------------
cloudfront_enabled              = true
cloudfront_enable_basic_auth    = true
cloudfront_basic_auth_username  = "bbws-sit"
cloudfront_basic_auth_password  = "REPLACE_VIA_SECRETS"  # Set via GitHub Secrets
cloudfront_price_class          = "PriceClass_All"

#------------------------------------------------------------------------------
# Monitoring & Alerting
#------------------------------------------------------------------------------
alert_email = "devops@bbws.com"
