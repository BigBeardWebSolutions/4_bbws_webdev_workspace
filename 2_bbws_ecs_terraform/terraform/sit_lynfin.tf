# SIT Tenant: lynfin
# Promoted from DEV to SIT
# Generated: 2026-02-06

# Random password for lynfin database
resource "random_password" "sit_lynfin_db" {
  length  = 24
  special = false
}

# Secrets Manager secret for lynfin database credentials
resource "aws_secretsmanager_secret" "sit_lynfin_db" {
  name        = "sit-lynfin-db-credentials"
  description = "Database credentials for lynfin in SIT"

  tags = {
    Name        = "sit-lynfin-db-credentials"
    Environment = "sit"
    Tenant      = "lynfin"
  }
}

resource "aws_secretsmanager_secret_version" "sit_lynfin_db" {
  secret_id = aws_secretsmanager_secret.sit_lynfin_db.id
  secret_string = jsonencode({
    username = "lynfin_user"
    password = random_password.sit_lynfin_db.result
    database = "lynfin_wordpress"
    host     = aws_db_instance.main.address
    port     = 3306
  })
}

# EFS Access Point for lynfin
resource "aws_efs_access_point" "sit_lynfin" {
  file_system_id = aws_efs_file_system.main.id

  root_directory {
    path = "/lynfin"
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
    Name        = "sit-lynfin-ap"
    Environment = "sit"
    Tenant      = "lynfin"
  }
}

# ECS Task Definition for lynfin
resource "aws_ecs_task_definition" "sit_lynfin" {
  family                   = "sit-lynfin"
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
        value = "lynfin_wordpress"
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
          define('WP_HOME', 'https://lynfin.wpsit.kimmyai.io');
          define('WP_SITEURL', 'https://lynfin.wpsit.kimmyai.io');
          define('WP_DEBUG_LOG', true);
          define('WP_DEBUG_DISPLAY', false);
          @ini_set('display_errors', 0);
        EOT
      }
    ]

    secrets = [
      {
        name      = "WORDPRESS_DB_USER"
        valueFrom = "${aws_secretsmanager_secret.sit_lynfin_db.arn}:username::"
      },
      {
        name      = "WORDPRESS_DB_PASSWORD"
        valueFrom = "${aws_secretsmanager_secret.sit_lynfin_db.arn}:password::"
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
        "awslogs-stream-prefix" = "lynfin"
      }
    }
  }])

  volume {
    name = "wp-content"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.main.id
      transit_encryption = "ENABLED"

      authorization_config {
        access_point_id = aws_efs_access_point.sit_lynfin.id
        iam             = "ENABLED"
      }
    }
  }

  tags = {
    Name        = "sit-lynfin-task"
    Environment = "sit"
    Tenant      = "lynfin"
  }
}

# ECS Service for lynfin
resource "aws_ecs_service" "sit_lynfin" {
  name            = "sit-lynfin-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.sit_lynfin.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.sit_lynfin.arn
    container_name   = "wordpress"
    container_port   = 80
  }

  depends_on = [
    aws_lb_listener.http,
    aws_efs_mount_target.main
  ]

  tags = {
    Name        = "sit-lynfin-service"
    Environment = "sit"
    Tenant      = "lynfin"
  }
}

# Target Group for lynfin
resource "aws_lb_target_group" "sit_lynfin" {
  name        = "sit-lynfin-tg"
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
    Name        = "sit-lynfin-tg"
    Environment = "sit"
    Tenant      = "lynfin"
  }
}

# ALB Listener Rule for lynfin
resource "aws_lb_listener_rule" "sit_lynfin" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 116

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sit_lynfin.arn
  }

  condition {
    host_header {
      values = ["lynfin.wpsit.kimmyai.io"]
    }
  }

  tags = {
    Name        = "sit-lynfin-rule"
    Environment = "sit"
    Tenant      = "lynfin"
  }
}
