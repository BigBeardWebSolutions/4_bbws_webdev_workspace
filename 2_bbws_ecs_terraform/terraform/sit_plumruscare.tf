# SIT Tenant: plumruscare
# Promoted from DEV to SIT
# Generated: 2026-02-09

# Random password for plumruscare database
resource "random_password" "sit_plumruscare_db" {
  length  = 24
  special = false
}

# Secrets Manager secret for plumruscare database credentials
resource "aws_secretsmanager_secret" "sit_plumruscare_db" {
  name        = "sit-plumruscare-db-credentials"
  description = "Database credentials for plumruscare in SIT"

  tags = {
    Name        = "sit-plumruscare-db-credentials"
    Environment = "sit"
    Tenant      = "plumruscare"
  }
}

resource "aws_secretsmanager_secret_version" "sit_plumruscare_db" {
  secret_id = aws_secretsmanager_secret.sit_plumruscare_db.id
  secret_string = jsonencode({
    username = "plumruscare_user"
    password = random_password.sit_plumruscare_db.result
    database = "plumruscare_wordpress"
    host     = aws_db_instance.main.address
    port     = 3306
  })
}

# EFS Access Point for plumruscare
resource "aws_efs_access_point" "sit_plumruscare" {
  file_system_id = aws_efs_file_system.main.id

  root_directory {
    path = "/plumruscare"
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
    Name        = "sit-plumruscare-ap"
    Environment = "sit"
    Tenant      = "plumruscare"
  }
}

# ECS Task Definition for plumruscare
resource "aws_ecs_task_definition" "sit_plumruscare" {
  family                   = "sit-plumruscare"
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
        value = "plumruscare_wordpress"
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
          define('WP_HOME', 'https://plumruscare.wpsit.kimmyai.io');
          define('WP_SITEURL', 'https://plumruscare.wpsit.kimmyai.io');
          define('WP_DEBUG_LOG', true);
          define('WP_DEBUG_DISPLAY', false);
          @ini_set('display_errors', 0);
        EOT
      }
    ]

    secrets = [
      {
        name      = "WORDPRESS_DB_USER"
        valueFrom = "${aws_secretsmanager_secret.sit_plumruscare_db.arn}:username::"
      },
      {
        name      = "WORDPRESS_DB_PASSWORD"
        valueFrom = "${aws_secretsmanager_secret.sit_plumruscare_db.arn}:password::"
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
        "awslogs-stream-prefix" = "plumruscare"
      }
    }
  }])

  volume {
    name = "wp-content"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.main.id
      transit_encryption = "ENABLED"

      authorization_config {
        access_point_id = aws_efs_access_point.sit_plumruscare.id
        iam             = "ENABLED"
      }
    }
  }

  tags = {
    Name        = "sit-plumruscare-task"
    Environment = "sit"
    Tenant      = "plumruscare"
  }
}

# ECS Service for plumruscare
resource "aws_ecs_service" "sit_plumruscare" {
  name            = "sit-plumruscare-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.sit_plumruscare.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.sit_plumruscare.arn
    container_name   = "wordpress"
    container_port   = 80
  }

  depends_on = [
    aws_lb_listener.http,
    aws_efs_mount_target.main
  ]

  tags = {
    Name        = "sit-plumruscare-service"
    Environment = "sit"
    Tenant      = "plumruscare"
  }
}

# Target Group for plumruscare
resource "aws_lb_target_group" "sit_plumruscare" {
  name        = "sit-plumruscare-tg"
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
    Name        = "sit-plumruscare-tg"
    Environment = "sit"
    Tenant      = "plumruscare"
  }
}

# ALB Listener Rule for plumruscare
resource "aws_lb_listener_rule" "sit_plumruscare" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 165

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sit_plumruscare.arn
  }

  condition {
    host_header {
      values = ["plumruscare.wpsit.kimmyai.io"]
    }
  }

  tags = {
    Name        = "sit-plumruscare-rule"
    Environment = "sit"
    Tenant      = "plumruscare"
  }
}
