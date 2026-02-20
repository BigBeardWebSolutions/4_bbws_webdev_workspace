# SIT Tenant: metisunicorns
# Promoted from DEV to SIT
# Generated: 2026-02-09

# Random password for metisunicorns database
resource "random_password" "sit_metisunicorns_db" {
  length  = 24
  special = false
}

# Secrets Manager secret for metisunicorns database credentials
resource "aws_secretsmanager_secret" "sit_metisunicorns_db" {
  name        = "sit-metisunicorns-db-credentials"
  description = "Database credentials for metisunicorns in SIT"

  tags = {
    Name        = "sit-metisunicorns-db-credentials"
    Environment = "sit"
    Tenant      = "metisunicorns"
  }
}

resource "aws_secretsmanager_secret_version" "sit_metisunicorns_db" {
  secret_id = aws_secretsmanager_secret.sit_metisunicorns_db.id
  secret_string = jsonencode({
    username = "metisunicorns_user"
    password = random_password.sit_metisunicorns_db.result
    database = "metisunicorns_wordpress"
    host     = aws_db_instance.main.address
    port     = 3306
  })
}

# EFS Access Point for metisunicorns
resource "aws_efs_access_point" "sit_metisunicorns" {
  file_system_id = aws_efs_file_system.main.id

  root_directory {
    path = "/metisunicorns"
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
    Name        = "sit-metisunicorns-ap"
    Environment = "sit"
    Tenant      = "metisunicorns"
  }
}

# ECS Task Definition for metisunicorns
resource "aws_ecs_task_definition" "sit_metisunicorns" {
  family                   = "sit-metisunicorns"
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
        value = "metisunicorns_wordpress"
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
          define('WP_HOME', 'https://metisunicorns.wpsit.kimmyai.io');
          define('WP_SITEURL', 'https://metisunicorns.wpsit.kimmyai.io');
          define('WP_DEBUG_LOG', true);
          define('WP_DEBUG_DISPLAY', false);
          @ini_set('display_errors', 0);
        EOT
      }
    ]

    secrets = [
      {
        name      = "WORDPRESS_DB_USER"
        valueFrom = "${aws_secretsmanager_secret.sit_metisunicorns_db.arn}:username::"
      },
      {
        name      = "WORDPRESS_DB_PASSWORD"
        valueFrom = "${aws_secretsmanager_secret.sit_metisunicorns_db.arn}:password::"
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
        "awslogs-stream-prefix" = "metisunicorns"
      }
    }
  }])

  volume {
    name = "wp-content"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.main.id
      transit_encryption = "ENABLED"

      authorization_config {
        access_point_id = aws_efs_access_point.sit_metisunicorns.id
        iam             = "ENABLED"
      }
    }
  }

  tags = {
    Name        = "sit-metisunicorns-task"
    Environment = "sit"
    Tenant      = "metisunicorns"
  }
}

# ECS Service for metisunicorns
resource "aws_ecs_service" "sit_metisunicorns" {
  name            = "sit-metisunicorns-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.sit_metisunicorns.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.sit_metisunicorns.arn
    container_name   = "wordpress"
    container_port   = 80
  }

  depends_on = [
    aws_lb_listener.http,
    aws_efs_mount_target.main
  ]

  tags = {
    Name        = "sit-metisunicorns-service"
    Environment = "sit"
    Tenant      = "metisunicorns"
  }
}

# Target Group for metisunicorns
resource "aws_lb_target_group" "sit_metisunicorns" {
  name        = "sit-metisunicorns-tg"
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
    Name        = "sit-metisunicorns-tg"
    Environment = "sit"
    Tenant      = "metisunicorns"
  }
}

# ALB Listener Rule for metisunicorns
resource "aws_lb_listener_rule" "sit_metisunicorns" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 155

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sit_metisunicorns.arn
  }

  condition {
    host_header {
      values = ["metisunicorns.wpsit.kimmyai.io"]
    }
  }

  tags = {
    Name        = "sit-metisunicorns-rule"
    Environment = "sit"
    Tenant      = "metisunicorns"
  }
}
