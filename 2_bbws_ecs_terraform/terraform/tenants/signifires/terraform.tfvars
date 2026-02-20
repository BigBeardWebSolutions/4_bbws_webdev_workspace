# signifires SIT Environment Configuration
# WordPress site: signifires.com
tenant_name     = "signifires"
environment     = "sit"
domain_name     = "signifires.wpsit.kimmyai.io"
alb_priority    = 114
aws_region      = "eu-west-1"
aws_profile     = "sit"
wordpress_image = "wordpress:latest"
task_cpu        = 512
task_memory     = 1024
desired_count   = 1
enable_ecs_exec = true
wordpress_debug = true

# SIT environment VPC and Security Group
vpc_id            = "vpc-02ca0b5516152669d"
security_group_id = "sg-01bca1fb9806ad397"

tags = {
  CostCenter     = "BBWS-Migrations"
  OriginalDomain = "signifires.com"
  MigrationDate  = "2026-02-04"
  HasWooCommerce = "false"
}
