# yourfinancialflow SIT Environment Configuration
tenant_name     = "yourfinancialflow"
environment     = "sit"
domain_name     = "yourfinancialflow.wpsit.kimmyai.io"
alb_priority    = 325
aws_region      = "eu-west-1"
aws_profile     = "sit"
wordpress_image = "815856636111.dkr.ecr.eu-west-1.amazonaws.com/sit-wordpress:latest"
task_cpu        = 256
task_memory     = 512
desired_count   = 1
enable_ecs_exec = true
wordpress_debug = false

# SIT-specific: VPC ID and Security Group ID to avoid duplicate resource matching
vpc_id                = "vpc-02ca0b5516152669d"
ecs_security_group_id = "sg-01bca1fb9806ad397"
