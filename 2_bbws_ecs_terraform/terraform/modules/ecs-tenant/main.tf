# ECS Tenant Module - Main Resources
# Creates ECS infrastructure for a single WordPress tenant

#------------------------------------------------------------------------------
# Random Password for Database Credentials
#------------------------------------------------------------------------------

resource "random_password" "db" {
  length  = 24
  special = false
}

#------------------------------------------------------------------------------
# Secrets Manager - Database Credentials
#------------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "db" {
  name        = "${var.environment}-${var.tenant_name}-db-credentials"
  description = "Database credentials for ${var.tenant_name} tenant"

  tags = merge(var.tags, {
    Name        = "${var.environment}-${var.tenant_name}-db-credentials"
    Environment = var.environment
    Tenant      = var.tenant_name
  })
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username = "${var.tenant_name}_user"
    password = random_password.db.result
    database = "${var.tenant_name}_db"
    host     = var.rds_endpoint
    port     = 3306
  })
}

#------------------------------------------------------------------------------
# IAM Policy - Grant Task Execution Role Access to Secrets
#------------------------------------------------------------------------------

# Extract role name from ARN (format: arn:aws:iam::ACCOUNT:role/ROLE_NAME)
locals {
  execution_role_name = element(split("/", var.ecs_task_execution_role_arn), length(split("/", var.ecs_task_execution_role_arn)) - 1)
}

resource "aws_iam_role_policy" "secrets_access" {
  name = "${var.environment}-ecs-secrets-access-${var.tenant_name}"
  role = local.execution_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          aws_secretsmanager_secret.db.arn,
          "${aws_secretsmanager_secret.db.arn}*"
        ]
      }
    ]
  })
}

#------------------------------------------------------------------------------
# EFS Access Point - Isolated Storage for Tenant
#------------------------------------------------------------------------------

resource "aws_efs_access_point" "tenant" {
  file_system_id = var.efs_id

  root_directory {
    path = "/${var.tenant_name}"
    creation_info {
      owner_gid   = 33 # www-data
      owner_uid   = 33
      permissions = "755"
    }
  }

  posix_user {
    gid = 33
    uid = 33
  }

  tags = merge(var.tags, {
    Name        = "${var.environment}-${var.tenant_name}-ap"
    Environment = var.environment
    Tenant      = var.tenant_name
  })
}

#------------------------------------------------------------------------------
# ECS Task Definition - WordPress Container
#------------------------------------------------------------------------------

resource "aws_ecs_task_definition" "tenant" {
  family                   = "${var.environment}-${var.tenant_name}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn

  container_definitions = jsonencode([{
    name      = "wordpress"
    image     = var.wordpress_image
    essential = true

    portMappings = [{
      containerPort = 80
      protocol      = "tcp"
    }]

    environment = concat([
      {
        name  = "WORDPRESS_DB_HOST"
        value = var.rds_endpoint
      },
      {
        name  = "WORDPRESS_DB_NAME"
        value = "${var.tenant_name}_db"
      },
      {
        name  = "WORDPRESS_TABLE_PREFIX"
        value = "wp_"
      },
      {
        name  = "WORDPRESS_DEBUG"
        value = var.wordpress_debug ? "1" : "0"
      },
      {
        name  = "WORDPRESS_CONFIG_EXTRA"
        value = <<-EOT
          if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
              $_SERVER['HTTPS'] = 'on';
          }
          if (isset($_SERVER['HTTP_CLOUDFRONT_FORWARDED_PROTO']) && $_SERVER['HTTP_CLOUDFRONT_FORWARDED_PROTO'] === 'https') {
              $_SERVER['HTTPS'] = 'on';
          }
          define('FORCE_SSL_ADMIN', true);
          define('WP_HOME', 'https://${var.domain_name}');
          define('WP_SITEURL', 'https://${var.domain_name}');
        EOT
      }
    ], var.additional_environment_vars)

    secrets = [
      {
        name      = "WORDPRESS_DB_USER"
        valueFrom = "${aws_secretsmanager_secret.db.arn}:username::"
      },
      {
        name      = "WORDPRESS_DB_PASSWORD"
        valueFrom = "${aws_secretsmanager_secret.db.arn}:password::"
      }
    ]

    mountPoints = [{
      sourceVolume  = "wp-content"
      containerPath = "/var/www/html/wp-content"
      readOnly      = false
    }]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = var.cloudwatch_log_group_name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = var.tenant_name
      }
    }

    healthCheck = {
      command     = ["CMD-SHELL", "curl -f http://localhost/ || exit 1"]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 60
    }
  }])

  volume {
    name = "wp-content"

    efs_volume_configuration {
      file_system_id     = var.efs_id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.tenant.id
        iam             = "ENABLED"
      }
    }
  }

  tags = merge(var.tags, {
    Name        = "${var.environment}-${var.tenant_name}-task"
    Environment = var.environment
    Tenant      = var.tenant_name
  })
}

#------------------------------------------------------------------------------
# ALB Target Group - Health Checks and Routing
#------------------------------------------------------------------------------

resource "aws_lb_target_group" "tenant" {
  name        = "${var.environment}-${var.tenant_name}-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = var.health_check_healthy_threshold
    interval            = var.health_check_interval
    matcher             = var.health_check_matcher
    path                = var.health_check_path
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = var.health_check_timeout
    unhealthy_threshold = var.health_check_unhealthy_threshold
  }

  deregistration_delay = var.deregistration_delay

  tags = merge(var.tags, {
    Name        = "${var.environment}-${var.tenant_name}-tg"
    Environment = var.environment
    Tenant      = var.tenant_name
  })
}

#------------------------------------------------------------------------------
# ALB Listener Rule - Host-Based Routing
#------------------------------------------------------------------------------

resource "aws_lb_listener_rule" "tenant" {
  listener_arn = var.alb_listener_arn
  priority     = var.alb_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tenant.arn
  }

  condition {
    host_header {
      values = [var.domain_name]
    }
  }

  tags = merge(var.tags, {
    Name        = "${var.environment}-${var.tenant_name}-rule"
    Environment = var.environment
    Tenant      = var.tenant_name
  })
}

#------------------------------------------------------------------------------
# ECS Service - Fargate Service with Load Balancer
#------------------------------------------------------------------------------

resource "aws_ecs_service" "tenant" {
  name            = "${var.environment}-${var.tenant_name}-service"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.tenant.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = var.ecs_security_group_ids
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tenant.arn
    container_name   = "wordpress"
    container_port   = 80
  }

  # deployment_configuration {
  #   maximum_percent         = var.deployment_maximum_percent
  #   minimum_healthy_percent = var.deployment_minimum_healthy_percent
  # }

  enable_execute_command = var.enable_ecs_exec

  depends_on = [
    aws_lb_listener_rule.tenant
  ]

  tags = merge(var.tags, {
    Name        = "${var.environment}-${var.tenant_name}-service"
    Environment = var.environment
    Tenant      = var.tenant_name
  })

  lifecycle {
    ignore_changes = [desired_count]
  }
}
