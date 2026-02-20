# MANAGEDIS Tenant Infrastructure
# Multi-tenant WordPress resources for ManagedIS migration
# Created: 2026-01-22
# ALB Priority: 210

# Random password for managedis database
resource "random_password" "managedis_db" {
  length  = 24
  special = false
}

# Secrets Manager secret for managedis database credentials
resource "aws_secretsmanager_secret" "managedis_db" {
  name        = "${var.environment}-managedis-db-credentials"
  description = "Database credentials for managedis"

  tags = {
    Name        = "${var.environment}-managedis-db-credentials"
    Environment = var.environment
    Tenant      = "managedis"
  }
}

resource "aws_secretsmanager_secret_version" "managedis_db" {
  secret_id = aws_secretsmanager_secret.managedis_db.id
  secret_string = jsonencode({
    username = "managedis_user"
    password = random_password.managedis_db.result
    database = "managedis_db"
    host     = aws_db_instance.main.address
    port     = 3306
  })
}

# EFS Access Point for MANAGEDIS
resource "aws_efs_access_point" "managedis" {
  file_system_id = aws_efs_file_system.main.id

  root_directory {
    path = "/managedis"
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
    Name        = "${var.environment}-managedis-ap"
    Environment = var.environment
    Tenant      = "managedis"
  }
}

# ECS Task Definition for MANAGEDIS
resource "aws_ecs_task_definition" "managedis" {
  family                   = "${var.environment}-managedis"
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
        value = "managedis_db"
      },
      {
        name  = "WORDPRESS_TABLE_PREFIX"
        value = "wp_"
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
          define('WP_HOME', 'https://managedis.wpdev.kimmyai.io');
          define('WP_SITEURL', 'https://managedis.wpdev.kimmyai.io');
          define('WP_ENV', 'dev');
          define('TEST_EMAIL_REDIRECT', 'tebogo@bigbeard.co.za');
        EOT
      }
    ]

    secrets = [
      {
        name      = "WORDPRESS_DB_USER"
        valueFrom = "${aws_secretsmanager_secret.managedis_db.arn}:username::"
      },
      {
        name      = "WORDPRESS_DB_PASSWORD"
        valueFrom = "${aws_secretsmanager_secret.managedis_db.arn}:password::"
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
        "awslogs-stream-prefix" = "managedis"
      }
    }
  }])

  volume {
    name = "wp-content"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.main.id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.managedis.id
        iam             = "ENABLED"
      }
    }
  }

  tags = {
    Name        = "${var.environment}-managedis-task"
    Environment = var.environment
    Tenant      = "managedis"
  }
}

# ECS Service for MANAGEDIS
resource "aws_ecs_service" "managedis" {
  name            = "${var.environment}-managedis-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.managedis.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.managedis.arn
    container_name   = "wordpress"
    container_port   = 80
  }

  depends_on = [
    aws_lb_listener_rule.managedis,
  ]

  tags = {
    Name        = "${var.environment}-managedis-service"
    Environment = var.environment
    Tenant      = "managedis"
  }
}

# Target Group for MANAGEDIS
resource "aws_lb_target_group" "managedis" {
  name        = "${var.environment}-managedis-tg"
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
    Name        = "${var.environment}-managedis-tg"
    Environment = var.environment
    Tenant      = "managedis"
  }
}

# ALB Listener Rule for MANAGEDIS
resource "aws_lb_listener_rule" "managedis" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 210

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.managedis.arn
  }

  condition {
    host_header {
      values = ["managedis.wpdev.kimmyai.io"]
    }
  }

  tags = {
    Name        = "${var.environment}-managedis-rule"
    Environment = var.environment
    Tenant      = "managedis"
  }
}
