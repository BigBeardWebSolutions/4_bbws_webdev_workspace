# thejudokan DEV Environment Configuration
tenant_name     = "thejudokan"
environment     = "dev"
domain_name     = "thejudokan.wpdev.kimmyai.io"
alb_priority    = 226
aws_region      = "eu-west-1"
aws_profile     = "dev"
wordpress_image = "536580886816.dkr.ecr.eu-west-1.amazonaws.com/dev-wordpress:latest"
task_cpu        = 256
task_memory     = 512
desired_count   = 1
enable_ecs_exec = true
wordpress_debug = false
