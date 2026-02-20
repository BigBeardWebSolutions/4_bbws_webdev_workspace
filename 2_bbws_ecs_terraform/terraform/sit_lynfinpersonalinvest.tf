# SIT Tenant: lynfinpersonalinvest
# Promoted from DEV to SIT
# Generated: 2026-02-09

# Random password for lynfinpersonalinvest database
resource "random_password" "sit_lynfinpersonalinvest_db" {
  length  = 24
  special = false
}

# Secrets Manager secret for lynfinpersonalinvest database credentials
resource "aws_secretsmanager_secret" "sit_lynfinpersonalinvest_db" {
  name        = "sit-lynfinpersonalinvest-db-credentials"
  description = "Database credentials for lynfinpersonalinvest in SIT"

  tags = {
    Name        = "sit-lynfinpersonalinvest-db-credentials"
    Environment = "sit"
    Tenant      = "lynfinpersonalinvest"
  }
}

resource "aws_secretsmanager_secret_version" "sit_lynfinpersonalinvest_db" {
  secret_id = aws_secretsmanager_secret.sit_lynfinpersonalinvest_db.id
  secret_string = jsonencode({
    username = "lynfinpersonalinvest_user"
    password = random_password.sit_lynfinpersonalinvest_db.result
    database = "lynfinpersonalinvest_wordpress"
    host     = aws_db_instance.main.address
    port     = 3306
  })
}

# EFS Access Point for lynfinpersonalinvest
resource "aws_efs_access_point" "sit_lynfinpersonalinvest" {
  file_system_id = aws_efs_file_system.main.id

  root_directory {
    path = "/lynfinpersonalinvest"
    creation_info {
      owner_gid   = 33  # www-data
      owner_uid   = 33
      permissions = "755"
    }
  }

  posix_user {
    gid = 33
    uid = 33
  }

  tags = {
    Name        = "sit-lynfinpersonalinvest-ap"
    Environment = "sit"
    Tenant      = "lynfinpersonalinvest"
  }
}

# ECS Task Definition for lynfinpersonalinvest
resource "aws_ecs_task_definition" "sit_lynfinpersonalinvest" {
  family                   = "sit-lynfinpersonalinvest"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
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
        value = "lynfinpersonalinvest_wordpress"
      },
      {
        name  = "WORDPRESS_TABLE_PREFIX"
        value = "wp_"
      },
      {
        name  = "WORDPRESS_DEBUG"
        value = "0"
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
          define('WP_HOME', 'https://lynfinpersonalinvest.wpsit.kimmyai.io');
          define('WP_SITEURL', 'https://lynfinpersonalinvest.wpsit.kimmyai.io');
          define('WP_DEBUG_LOG', true);
          define('WP_DEBUG_DISPLAY', false);
          @ini_set('display_errors', 0);
        EOT
      }
    ]

    secrets = [
      {
        name      = "WORDPRESS_DB_USER"
        valueFrom = "${aws_secretsmanager_secret.sit_lynfinpersonalinvest_db.arn}:username::"
      },
      {
        name      = "WORDPRESS_DB_PASSWORD"
        valueFrom = "${aws_secretsmanager_secret.sit_lynfinpersonalinvest_db.arn}:password::"
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
        "awslogs-stream-prefix" = "lynfinpersonalinvest"
      }
    }
  }])

  volume {
    name = "wp-content"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.main.id
      transit_encryption = "ENABLED"

      authorization_config {
        access_point_id = aws_efs_access_point.sit_lynfinpersonalinvest.id
        iam             = "ENABLED"
      }
    }
  }

  tags = {
    Name        = "sit-lynfinpersonalinvest-task"
    Environment = "sit"
    Tenant      = "lynfinpersonalinvest"
  }
}

# ECS Service for lynfinpersonalinvest
resource "aws_ecs_service" "sit_lynfinpersonalinvest" {
  name            = "sit-lynfinpersonalinvest-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.sit_lynfinpersonalinvest.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.sit_lynfinpersonalinvest.arn
    container_name   = "wordpress"
    container_port   = 80
  }

  depends_on = [
    aws_lb_listener.http,
    aws_efs_mount_target.main
  ]

  tags = {
    Name        = "sit-lynfinpersonalinvest-service"
    Environment = "sit"
    Tenant      = "lynfinpersonalinvest"
  }
}

# Target Group for lynfinpersonalinvest
resource "aws_lb_target_group" "sit_lynfinpersonalinvest" {
  name        = "sit-lynfinpersonalinvest-tg"
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
    Name        = "sit-lynfinpersonalinvest-tg"
    Environment = "sit"
    Tenant      = "lynfinpersonalinvest"
  }
}

# ALB Listener Rule for lynfinpersonalinvest
resource "aws_lb_listener_rule" "sit_lynfinpersonalinvest" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 135

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sit_lynfinpersonalinvest.arn
  }

  condition {
    host_header {
      values = ["lynfinpersonalinvest.wpsit.kimmyai.io"]
    }
  }

  tags = {
    Name        = "sit-lynfinpersonalinvest-rule"
    Environment = "sit"
    Tenant      = "lynfinpersonalinvest"
  }
}
