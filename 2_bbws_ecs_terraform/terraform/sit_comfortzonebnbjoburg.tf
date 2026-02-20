# SIT Tenant: comfortzonebnbjoburg
# Direct-to-SIT migration from local Xneelo export
# Generated: 2026-02-09
# ALB Priority: 215
# COMFORTZONEBNBJOBURG Tenant Infrastructure
# WooCommerce site - migrated from comfortzonebnbjoburg.co.za

# Random password for comfortzonebnbjoburg database
resource "random_password" "sit_comfortzonebnbjoburg_db" {
  length  = 24
  special = false
}

# Secrets Manager secret for comfortzonebnbjoburg database credentials
resource "aws_secretsmanager_secret" "sit_comfortzonebnbjoburg_db" {
  name        = "sit-comfortzonebnbjoburg-db-credentials"
  description = "Database credentials for comfortzonebnbjoburg"

  tags = {
    Name        = "sit-comfortzonebnbjoburg-db-credentials"
    Environment = var.environment
    Tenant      = "comfortzonebnbjoburg"
  }
}

resource "aws_secretsmanager_secret_version" "sit_comfortzonebnbjoburg_db" {
  secret_id = aws_secretsmanager_secret.sit_comfortzonebnbjoburg_db.id
  secret_string = jsonencode({
    username = "comfortzonebnbjoburg_user"
    password = random_password.sit_comfortzonebnbjoburg_db.result
    database = "comfortzonebnbjoburg_db"
    host     = aws_db_instance.main.address
    port     = 3306
  })
}

# EFS Access Point for COMFORTZONEBNBJOBURG
resource "aws_efs_access_point" "sit_comfortzonebnbjoburg" {
  file_system_id = aws_efs_file_system.main.id

  root_directory {
    path = "/comfortzonebnbjoburg"
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
    Name        = "sit-comfortzonebnbjoburg-ap"
    Environment = var.environment
    Tenant      = "comfortzonebnbjoburg"
  }
}

# ECS Task Definition for COMFORTZONEBNBJOBURG
resource "aws_ecs_task_definition" "sit_comfortzonebnbjoburg" {
  family                   = "sit-comfortzonebnbjoburg"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.ecs_task_cpu
  memory                   = var.ecs_task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([{
    name      = "wordpress"
    image     = "${aws_ecr_repository.wordpress.repository_url}:latest"
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
        value = "comfortzonebnbjoburg_db"
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
          define('WP_DEBUG_DISPLAY', false);
          define('WP_DEBUG_LOG', true);
          define('WP_HOME', 'https://comfortzonebnbjoburg.wpsit.kimmyai.io');
          define('WP_SITEURL', 'https://comfortzonebnbjoburg.wpsit.kimmyai.io');
        EOT
      }
    ]

    secrets = [
      {
        name      = "WORDPRESS_DB_USER"
        valueFrom = "${aws_secretsmanager_secret.sit_comfortzonebnbjoburg_db.arn}:username::"
      },
      {
        name      = "WORDPRESS_DB_PASSWORD"
        valueFrom = "${aws_secretsmanager_secret.sit_comfortzonebnbjoburg_db.arn}:password::"
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
        "awslogs-stream-prefix" = "comfortzonebnbjoburg"
      }
    }
  }])

  volume {
    name = "wp-content"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.main.id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.sit_comfortzonebnbjoburg.id
        iam             = "ENABLED"
      }
    }
  }

  tags = {
    Name        = "sit-comfortzonebnbjoburg-task"
    Environment = var.environment
    Tenant      = "comfortzonebnbjoburg"
  }
}

# ECS Service for COMFORTZONEBNBJOBURG
resource "aws_ecs_service" "sit_comfortzonebnbjoburg" {
  name            = "sit-comfortzonebnbjoburg-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.sit_comfortzonebnbjoburg.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.sit_comfortzonebnbjoburg.arn
    container_name   = "wordpress"
    container_port   = 80
  }

  depends_on = [
    aws_lb_listener_rule.sit_comfortzonebnbjoburg,
  ]

  tags = {
    Name        = "sit-comfortzonebnbjoburg-service"
    Environment = var.environment
    Tenant      = "comfortzonebnbjoburg"
  }
}

# Target Group for COMFORTZONEBNBJOBURG
resource "aws_lb_target_group" "sit_comfortzonebnbjoburg" {
  name        = "sit-comfortzonebnbjoburg-tg"
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
    Name        = "sit-comfortzonebnbjoburg-tg"
    Environment = var.environment
    Tenant      = "comfortzonebnbjoburg"
  }
}

# ALB Listener Rule for COMFORTZONEBNBJOBURG
resource "aws_lb_listener_rule" "sit_comfortzonebnbjoburg" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 215

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sit_comfortzonebnbjoburg.arn
  }

  condition {
    host_header {
      values = ["comfortzonebnbjoburg.wpsit.kimmyai.io"]
    }
  }

  tags = {
    Name        = "sit-comfortzonebnbjoburg-rule"
    Environment = var.environment
    Tenant      = "comfortzonebnbjoburg"
  }
}
