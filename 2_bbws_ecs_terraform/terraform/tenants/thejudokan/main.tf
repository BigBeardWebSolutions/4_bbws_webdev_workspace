# thejudokan Tenant Infrastructure

data "aws_vpc" "main" {
  filter {
    name   = "tag:Environment"
    values = [var.environment]
  }
  filter {
    name   = "tag:Name"
    values = ["${var.environment}-vpc"]
  }
}

data "aws_ecs_cluster" "main" {
  cluster_name = "${var.environment}-cluster"
}

data "aws_efs_file_system" "main" {
  tags = {
    Environment = var.environment
    Name        = "${var.environment}-efs"
  }
}

data "aws_db_instance" "main" {
  db_instance_identifier = "${var.environment}-mysql"
}

data "aws_lb" "main" {
  tags = {
    Environment = var.environment
    Name        = "${var.environment}-alb"
  }
}

data "aws_lb_listener" "http" {
  load_balancer_arn = data.aws_lb.main.arn
  port              = 80
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
  filter {
    name   = "tag:Type"
    values = ["Private"]
  }
}

data "aws_security_group" "ecs_tasks" {
  tags = {
    Environment = var.environment
    Name        = "${var.environment}-ecs-tasks-sg"
  }
}

data "aws_iam_role" "ecs_task_execution" {
  name = "${var.environment}-ecs-task-execution-role"
}

data "aws_iam_role" "ecs_task" {
  name = "${var.environment}-ecs-task-role"
}

data "aws_cloudwatch_log_group" "ecs" {
  name = "/ecs/${var.environment}"
}

module "ecs_tenant" {
  source = "../../modules/ecs-tenant"

  tenant_name  = var.tenant_name
  environment  = var.environment
  domain_name  = var.domain_name
  alb_priority = var.alb_priority

  vpc_id                       = data.aws_vpc.main.id
  cluster_id                   = data.aws_ecs_cluster.main.id
  efs_id                       = data.aws_efs_file_system.main.id
  rds_endpoint                 = data.aws_db_instance.main.address
  alb_listener_arn             = data.aws_lb_listener.http.arn
  private_subnet_ids           = data.aws_subnets.private.ids
  ecs_security_group_ids       = [data.aws_security_group.ecs_tasks.id]
  ecs_task_execution_role_arn  = data.aws_iam_role.ecs_task_execution.arn
  ecs_task_role_arn            = data.aws_iam_role.ecs_task.arn
  cloudwatch_log_group_name    = data.aws_cloudwatch_log_group.ecs.name
  aws_region                   = var.aws_region

  wordpress_image = var.wordpress_image
  task_cpu        = var.task_cpu
  task_memory     = var.task_memory
  desired_count   = var.desired_count

  health_check_path                = var.health_check_path
  health_check_interval            = var.health_check_interval
  health_check_healthy_threshold   = var.health_check_healthy_threshold
  health_check_unhealthy_threshold = var.health_check_unhealthy_threshold

  wordpress_debug = var.wordpress_debug
  enable_ecs_exec = var.enable_ecs_exec

  tags = merge(var.tags, {
    Tenant      = var.tenant_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  })
}

module "database" {
  source = "../../modules/database"

  tenant_name          = var.tenant_name
  environment          = var.environment
  tenant_db_secret_arn = module.ecs_tenant.db_secret_arn
  aws_region           = var.aws_region
  aws_profile          = var.aws_profile
  init_db_script_path  = var.init_db_script_path
  verify_database      = var.verify_database

  depends_on = [module.ecs_tenant]

  tags = merge(var.tags, {
    Tenant      = var.tenant_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  })
}

module "dns_cloudfront" {
  count  = var.environment == "prod" && var.create_dns_records ? 1 : 0
  source = "../../modules/dns-cloudfront"

  tenant_name            = var.tenant_name
  environment            = var.environment
  domain_name            = var.domain_name
  route53_zone_id        = var.route53_zone_id
  cloudfront_domain_name = var.cloudfront_domain_name
  create_ipv6_record     = var.create_ipv6_record
  evaluate_target_health = var.evaluate_target_health

  depends_on = [module.ecs_tenant, module.database]

  tags = merge(var.tags, {
    Tenant      = var.tenant_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  })
}
