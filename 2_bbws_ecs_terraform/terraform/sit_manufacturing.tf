# SIT Tenant: manufacturing
# Auto-generated from DEV configuration for WordPress migration
# Generated: 2026-01-16
# ALB Priority: 190
# MANUFACTURING Tenant Infrastructure
# Multi-tenant WordPress resources for Manufacturing-Websites migration

# Random password for manufacturing database
resource "random_password" "sit_manufacturing_db" {
  length  = 24
  special = false
}

# Secrets Manager secret for manufacturing database credentials
resource "aws_secretsmanager_secret" "sit_manufacturing_db" {
  name        = "sit-manufacturing-db-credentials"
  description = "Database credentials for manufacturing"

  tags = {
    Name        = "sit-manufacturing-db-credentials"
    Environment = var.environment
    Tenant      = "manufacturing"
  }
}

resource "aws_secretsmanager_secret_version" "sit_manufacturing_db" {
  secret_id = aws_secretsmanager_secret.sit_manufacturing_db.id
  secret_string = jsonencode({
    username = "manufacturing_user"
    password = random_password.sit_manufacturing_db.result
    database = "manufacturing_db"
    host     = aws_db_instance.main.address
    port     = 3306
  })
}

# EFS Access Point for MANUFACTURING
resource "aws_efs_access_point" "sit_manufacturing" {
  file_system_id = aws_efs_file_system.main.id

  root_directory {
    path = "/manufacturing"
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
    Name        = "sit-manufacturing-ap"
    Environment = var.environment
    Tenant      = "manufacturing"
  }
}

# ECS Task Definition for MANUFACTURING
resource "aws_ecs_task_definition" "sit_manufacturing" {
  family                   = "sit-manufacturing"
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
        value = "manufacturing_db"
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
        name  = "WP_ENV"
        value = "sit"
      },
      {
        name  = "TEST_EMAIL_REDIRECT"
        value = "tebogo@bigbeard.co.za"
      },
      {
        name  = "PHP_MEMORY_LIMIT"
        value = "512M"
      },
      {
        name  = "PHP_MAX_EXECUTION_TIME"
        value = "600"
      },
      {
        name  = "PHP_POST_MAX_SIZE"
        value = "512M"
      },
      {
        name  = "PHP_UPLOAD_MAX_FILESIZE"
        value = "512M"
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
          define('WP_HOME', 'https://manufacturing.wpsit.kimmyai.io');
          define('WP_SITEURL', 'https://manufacturing.wpsit.kimmyai.io');
          define('WP_ENV', 'sit');
          define('TEST_EMAIL_REDIRECT', 'tebogo@bigbeard.co.za');
        EOT
      }
    ]

    secrets = [
      {
        name      = "WORDPRESS_DB_USER"
        valueFrom = "${aws_secretsmanager_secret.sit_manufacturing_db.arn}:username::"
      },
      {
        name      = "WORDPRESS_DB_PASSWORD"
        valueFrom = "${aws_secretsmanager_secret.sit_manufacturing_db.arn}:password::"
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
        "awslogs-stream-prefix" = "manufacturing"
      }
    }
  }])

  volume {
    name = "wp-content"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.main.id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.sit_manufacturing.id
        iam             = "ENABLED"
      }
    }
  }

  tags = {
    Name        = "sit-manufacturing-task"
    Environment = var.environment
    Tenant      = "manufacturing"
  }
}

# ECS Service for MANUFACTURING
resource "aws_ecs_service" "sit_manufacturing" {
  name            = "sit-manufacturing-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.sit_manufacturing.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.sit_manufacturing.arn
    container_name   = "wordpress"
    container_port   = 80
  }

  depends_on = [
    aws_lb_listener_rule.sit_manufacturing,
  ]

  tags = {
    Name        = "sit-manufacturing-service"
    Environment = var.environment
    Tenant      = "manufacturing"
  }
}

# Target Group for MANUFACTURING
resource "aws_lb_target_group" "sit_manufacturing" {
  name        = "sit-manufacturing-tg"
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
    Name        = "sit-manufacturing-tg"
    Environment = var.environment
    Tenant      = "manufacturing"
  }
}

# ALB Listener Rule for MANUFACTURING
resource "aws_lb_listener_rule" "sit_manufacturing" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 190

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sit_manufacturing.arn
  }

  condition {
    host_header {
      values = ["manufacturing.wpsit.kimmyai.io"]
    }
  }

  tags = {
    Name        = "sit-manufacturing-rule"
    Environment = var.environment
    Tenant      = "manufacturing"
  }
}
