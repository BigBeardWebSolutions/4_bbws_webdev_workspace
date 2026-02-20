# SIT Tenant: managedis
# Promoted from DEV to SIT
# Generated: 2026-02-09

# Random password for managedis database
resource "random_password" "sit_managedis_db" {
  length  = 24
  special = false
}

# Secrets Manager secret for managedis database credentials
resource "aws_secretsmanager_secret" "sit_managedis_db" {
  name        = "sit-managedis-db-credentials"
  description = "Database credentials for managedis in SIT"

  tags = {
    Name        = "sit-managedis-db-credentials"
    Environment = "sit"
    Tenant      = "managedis"
  }
}

resource "aws_secretsmanager_secret_version" "sit_managedis_db" {
  secret_id = aws_secretsmanager_secret.sit_managedis_db.id
  secret_string = jsonencode({
    username = "managedis_user"
    password = random_password.sit_managedis_db.result
    database = "managedis_wordpress"
    host     = aws_db_instance.main.address
    port     = 3306
  })
}

# EFS Access Point for managedis
resource "aws_efs_access_point" "sit_managedis" {
  file_system_id = aws_efs_file_system.main.id

  root_directory {
    path = "/managedis"
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
    Name        = "sit-managedis-ap"
    Environment = "sit"
    Tenant      = "managedis"
  }
}

# ECS Task Definition for managedis
resource "aws_ecs_task_definition" "sit_managedis" {
  family                   = "sit-managedis"
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
        value = "managedis_wordpress"
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
          define('WP_HOME', 'https://managedis.wpsit.kimmyai.io');
          define('WP_SITEURL', 'https://managedis.wpsit.kimmyai.io');
          define('WP_DEBUG_LOG', true);
          define('WP_DEBUG_DISPLAY', false);
          @ini_set('display_errors', 0);
        EOT
      }
    ]

    secrets = [
      {
        name      = "WORDPRESS_DB_USER"
        valueFrom = "${aws_secretsmanager_secret.sit_managedis_db.arn}:username::"
      },
      {
        name      = "WORDPRESS_DB_PASSWORD"
        valueFrom = "${aws_secretsmanager_secret.sit_managedis_db.arn}:password::"
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
        access_point_id = aws_efs_access_point.sit_managedis.id
        iam             = "ENABLED"
      }
    }
  }

  tags = {
    Name        = "sit-managedis-task"
    Environment = "sit"
    Tenant      = "managedis"
  }
}

# ECS Service for managedis
resource "aws_ecs_service" "sit_managedis" {
  name            = "sit-managedis-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.sit_managedis.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.sit_managedis.arn
    container_name   = "wordpress"
    container_port   = 80
  }

  depends_on = [
    aws_lb_listener.http,
    aws_efs_mount_target.main
  ]

  tags = {
    Name        = "sit-managedis-service"
    Environment = "sit"
    Tenant      = "managedis"
  }
}

# Target Group for managedis
resource "aws_lb_target_group" "sit_managedis" {
  name        = "sit-managedis-tg"
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
    Name        = "sit-managedis-tg"
    Environment = "sit"
    Tenant      = "managedis"
  }
}

# ALB Listener Rule for managedis
resource "aws_lb_listener_rule" "sit_managedis" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 145

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sit_managedis.arn
  }

  condition {
    host_header {
      values = ["managedis.wpsit.kimmyai.io"]
    }
  }

  tags = {
    Name        = "sit-managedis-rule"
    Environment = "sit"
    Tenant      = "managedis"
  }
}
