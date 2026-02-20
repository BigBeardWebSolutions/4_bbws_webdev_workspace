# cliplok DEV Environment Configuration
# WordPress WooCommerce site: clip-lok.co.za
tenant_name     = "cliplok"
environment     = "dev"
domain_name     = "cliplok.wpdev.kimmyai.io"
alb_priority    = 230
aws_region      = "eu-west-1"
aws_profile     = "dev"
wordpress_image = "536580886816.dkr.ecr.eu-west-1.amazonaws.com/dev-wordpress:latest"
task_cpu        = 512
task_memory     = 1024
desired_count   = 1
enable_ecs_exec = true
wordpress_debug = true

# DEV environment has multiple VPCs - specify the correct ones
vpc_id            = "vpc-0ebf629b5b69f8766"
security_group_id = "sg-08ffde767c054e090"

tags = {
  CostCenter     = "BBWS-Migrations"
  OriginalDomain = "clip-lok.co.za"
  MigrationDate  = "2026-02-04"
  HasWooCommerce = "true"
}
