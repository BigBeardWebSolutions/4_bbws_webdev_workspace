# metisunicorns DEV Environment Configuration
tenant_name     = "metisunicorns"
environment     = "dev"
domain_name     = "metisunicorns.wpdev.kimmyai.io"
alb_priority    = 228
aws_region      = "eu-west-1"
aws_profile     = "dev"
wordpress_image = "536580886816.dkr.ecr.eu-west-1.amazonaws.com/dev-wordpress:latest"
task_cpu        = 256
task_memory     = 512
desired_count   = 1
enable_ecs_exec = true
wordpress_debug = false

# DEV environment has multiple VPCs - specify the correct ones
vpc_id            = "vpc-0ebf629b5b69f8766"
security_group_id = "sg-08ffde767c054e090"
