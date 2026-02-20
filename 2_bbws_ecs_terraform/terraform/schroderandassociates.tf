# SCHRODERANDASSOCIATES Tenant Infrastructure
# Multi-tenant WordPress resources for SchroderandAssociates migration
# Created: 2026-02-04
# ALB Priority: 240
# Source: schroderandassociates.co.za (Xneelo)
# Table Prefix: wjh648jiepoir735p_ (non-standard)

# Random password for schroderandassociates database
resource "random_password" "schroderandassociates_db" {
  length  = 24
  special = false
}

# Secrets Manager secret for schroderandassociates database credentials
resource "aws_secretsmanager_secret" "schroderandassociates_db" {
  name        = "${var.environment}-schroderandassociates-db-credentials"
  description = "Database credentials for schroderandassociates"

  tags = {
    Name        = "${var.environment}-schroderandassociates-db-credentials"
    Environment = var.environment
    Tenant      = "schroderandassociates"
  }
}

resource "aws_secretsmanager_secret_version" "schroderandassociates_db" {
  secret_id = aws_secretsmanager_secret.schroderandassociates_db.id
  secret_string = jsonencode({
    username = "schroderandassociates_user"
    password = random_password.schroderandassociates_db.result
    database = "schroderandassociates_db"
    host     = aws_db_instance.main.address
    port     = 3306
  })
}

# EFS Access Point for SCHRODERANDASSOCIATES
resource "aws_efs_access_point" "schroderandassociates" {
  file_system_id = aws_efs_file_system.main.id

  root_directory {
    path = "/schroderandassociates"
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
    Name        = "${var.environment}-schroderandassociates-ap"
    Environment = var.environment
    Tenant      = "schroderandassociates"
  }
}

# ECS Task Definition for SCHRODERANDASSOCIATES
resource "aws_ecs_task_definition" "schroderandassociates" {
  family                   = "${var.environment}-schroderandassociates"
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
        value = "schroderandassociates_db"
      },
      {
        name  = "WORDPRESS_TABLE_PREFIX"
        value = "wjh648jiepoir735p_"
      },
      {
        name  = "WP_ENV"
        value = "dev"
      },
      {
        name  = "TEST_EMAIL_REDIRECT"
        value = "tebogo@bigbeard.co.za"
      },
      {
        name  = "PHP_MEMORY_LIMIT"
        value = "256M"
      },
      {
        name  = "PHP_MAX_EXECUTION_TIME"
        value = "300"
      },
      {
        name  = "PHP_POST_MAX_SIZE"
        value = "64M"
      },
      {
        name  = "PHP_UPLOAD_MAX_FILESIZE"
        value = "64M"
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
          define('WP_HOME', 'https://schroderandassociates.wpdev.kimmyai.io');
          define('WP_SITEURL', 'https://schroderandassociates.wpdev.kimmyai.io');
          define('WP_ENV', 'dev');
          define('TEST_EMAIL_REDIRECT', 'tebogo@bigbeard.co.za');
        EOT
      }
    ]

    secrets = [
      {
        name      = "WORDPRESS_DB_USER"
        valueFrom = "${aws_secretsmanager_secret.schroderandassociates_db.arn}:username::"
      },
      {
        name      = "WORDPRESS_DB_PASSWORD"
        valueFrom = "${aws_secretsmanager_secret.schroderandassociates_db.arn}:password::"
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
        "awslogs-stream-prefix" = "schroderandassociates"
      }
    }
  }])

  volume {
    name = "wp-content"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.main.id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.schroderandassociates.id
        iam             = "ENABLED"
      }
    }
  }

  tags = {
    Name        = "${var.environment}-schroderandassociates-task"
    Environment = var.environment
    Tenant      = "schroderandassociates"
  }
}

# ECS Service for SCHRODERANDASSOCIATES
resource "aws_ecs_service" "schroderandassociates" {
  name            = "${var.environment}-schroderandassociates-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.schroderandassociates.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.schroderandassociates.arn
    container_name   = "wordpress"
    container_port   = 80
  }

  depends_on = [
    aws_lb_listener_rule.schroderandassociates,
  ]

  tags = {
    Name        = "${var.environment}-schroderandassociates-service"
    Environment = var.environment
    Tenant      = "schroderandassociates"
  }
}

# Target Group for SCHRODERANDASSOCIATES
resource "aws_lb_target_group" "schroderandassociates" {
  name        = "${var.environment}-schroderasso-tg"
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
    Name        = "${var.environment}-schroderandassociates-tg"
    Environment = var.environment
    Tenant      = "schroderandassociates"
  }
}

# ALB Listener Rule for SCHRODERANDASSOCIATES
resource "aws_lb_listener_rule" "schroderandassociates" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 240

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.schroderandassociates.arn
  }

  condition {
    host_header {
      values = ["schroderandassociates.wpdev.kimmyai.io"]
    }
  }

  tags = {
    Name        = "${var.environment}-schroderandassociates-rule"
    Environment = var.environment
    Tenant      = "schroderandassociates"
  }
}
