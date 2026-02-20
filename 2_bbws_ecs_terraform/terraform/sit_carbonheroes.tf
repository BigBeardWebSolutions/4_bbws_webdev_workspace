# SIT Tenant: carbonheroes
# Generated for SIT promotion: 2026-02-04
# ALB Priority: 210

# Random password for carbonheroes database
resource "random_password" "sit_carbonheroes_db" {
  length  = 24
  special = false
}

# Secrets Manager secret for carbonheroes database credentials
resource "aws_secretsmanager_secret" "sit_carbonheroes_db" {
  name        = "sit-carbonheroes-db-credentials"
  description = "Database credentials for carbonheroes"

  tags = {
    Name        = "sit-carbonheroes-db-credentials"
    Environment = var.environment
    Tenant      = "carbonheroes"
  }
}

resource "aws_secretsmanager_secret_version" "sit_carbonheroes_db" {
  secret_id = aws_secretsmanager_secret.sit_carbonheroes_db.id
  secret_string = jsonencode({
    username = "carbonheroes_user"
    password = random_password.sit_carbonheroes_db.result
    database = "carbonheroes_db"
    host     = aws_db_instance.main.address
    port     = 3306
  })
}

# EFS Access Point for CARBONHEROES
resource "aws_efs_access_point" "sit_carbonheroes" {
  file_system_id = aws_efs_file_system.main.id

  root_directory {
    path = "/carbonheroes"
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

  tags = {
    Name        = "sit-carbonheroes-ap"
    Environment = var.environment
    Tenant      = "carbonheroes"
  }
}

# ECS Task Definition for CARBONHEROES
resource "aws_ecs_task_definition" "sit_carbonheroes" {
  family                   = "sit-carbonheroes"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.ecs_task_cpu
  memory                   = var.ecs_task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([{
    name      = "wordpress"
    image     = local.wordpress_image
    essential = true

    portMappings = [{
      containerPort = 80
      protocol      = "tcp"
    }]

    environment = [
      {
        name  = "WORDPRESS_DB_HOST"
        value = aws_db_instance.main.address
      },
      {
        name  = "WORDPRESS_DB_NAME"
        value = "carbonheroes_db"
      },
      {
        name  = "WORDPRESS_TABLE_PREFIX"
        value = "wp_"
      },
      {
        name  = "WORDPRESS_DEBUG"
        value = "1"
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
          define('WP_HOME', 'https://carbonheroes.wpsit.kimmyai.io');
          define('WP_SITEURL', 'https://carbonheroes.wpsit.kimmyai.io');
          define('WP_ENVIRONMENT_TYPE', 'staging');
        EOT
      }
    ]

    secrets = [
      {
        name      = "WORDPRESS_DB_USER"
        valueFrom = "${aws_secretsmanager_secret.sit_carbonheroes_db.arn}:username::"
      },
      {
        name      = "WORDPRESS_DB_PASSWORD"
        valueFrom = "${aws_secretsmanager_secret.sit_carbonheroes_db.arn}:password::"
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
        "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "carbonheroes"
      }
    }
  }])

  volume {
    name = "wp-content"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.main.id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.sit_carbonheroes.id
        iam             = "ENABLED"
      }
    }
  }

  tags = {
    Name        = "sit-carbonheroes-task"
    Environment = var.environment
    Tenant      = "carbonheroes"
  }
}

# ECS Service for CARBONHEROES
resource "aws_ecs_service" "sit_carbonheroes" {
  name            = "sit-carbonheroes-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.sit_carbonheroes.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.sit_carbonheroes.arn
    container_name   = "wordpress"
    container_port   = 80
  }

  depends_on = [
    aws_lb_listener_rule.sit_carbonheroes,
  ]

  tags = {
    Name        = "sit-carbonheroes-service"
    Environment = var.environment
    Tenant      = "carbonheroes"
  }
}

# Target Group for CARBONHEROES
resource "aws_lb_target_group" "sit_carbonheroes" {
  name        = "sit-carbonheroes-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200,301,302"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }

  deregistration_delay = 30

  tags = {
    Name        = "sit-carbonheroes-tg"
    Environment = var.environment
    Tenant      = "carbonheroes"
  }
}

# ALB Listener Rule for CARBONHEROES
resource "aws_lb_listener_rule" "sit_carbonheroes" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 210

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sit_carbonheroes.arn
  }

  condition {
    host_header {
      values = ["carbonheroes.wpsit.kimmyai.io"]
    }
  }

  tags = {
    Name        = "sit-carbonheroes-rule"
    Environment = var.environment
    Tenant      = "carbonheroes"
  }
}
