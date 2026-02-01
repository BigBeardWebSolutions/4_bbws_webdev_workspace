# SANDBOX Environment Configuration
# BBWS Multi-Tenant WordPress Platform
# AWS Account: 417589271098 (eu-west-1)
# Purpose: Web Development Team sandbox - mirrors DEV

#------------------------------------------------------------------------------
# Account & Environment
#------------------------------------------------------------------------------
environment    = "sandbox"
aws_region     = "eu-west-1"
aws_account_id = "417589271098"

#------------------------------------------------------------------------------
# Network Configuration
# SANDBOX: 10.1.0.0/16 (DEV: 10.0.0.0/16, SIT: 10.2.0.0/16, PROD: 10.3.0.0/16)
#------------------------------------------------------------------------------
vpc_cidr              = "10.1.0.0/16"
public_subnet_cidrs   = ["10.1.1.0/24", "10.1.2.0/24"]
private_subnet_cidrs  = ["10.1.10.0/24", "10.1.11.0/24"]

#------------------------------------------------------------------------------
# RDS Configuration (mirrors DEV)
#------------------------------------------------------------------------------
rds_instance_class       = "db.t3.micro"
rds_master_username      = "admin"
rds_multi_az             = false
rds_backup_retention     = 7
rds_skip_final_snapshot  = true
rds_backup_window        = "03:00-04:00"
rds_maintenance_window   = "Mon:04:00-Mon:05:00"

#------------------------------------------------------------------------------
# ALB Configuration
#------------------------------------------------------------------------------
alb_deletion_protection = false

#------------------------------------------------------------------------------
# ECS Configuration (mirrors DEV)
#------------------------------------------------------------------------------
ecs_task_cpu    = "512"
ecs_task_memory = "1024"

#------------------------------------------------------------------------------
# WordPress Configuration
#------------------------------------------------------------------------------
use_ecr_image       = false
wordpress_image     = "wordpress"
wordpress_image_tag = "latest"

#------------------------------------------------------------------------------
# CloudFront Configuration
#------------------------------------------------------------------------------
cloudfront_enabled              = true
cloudfront_enable_basic_auth    = false
cloudfront_price_class          = "PriceClass_All"

#------------------------------------------------------------------------------
# Monitoring & Alerting
#------------------------------------------------------------------------------
alert_email = "development@bigbeard.co.za"
