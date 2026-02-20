# SIT Tenant: greenpenevents
# Generated for SIT promotion: 2026-02-02
# ALB Priority: 110

# Random password for greenpenevents database
resource "random_password" "sit_greenpenevents_db" {
  length  = 24
  special = false
}

# Secrets Manager secret for greenpenevents database credentials
resource "aws_secretsmanager_secret" "sit_greenpenevents_db" {
  name        = "sit-greenpenevents-db-credentials"
  description = "Database credentials for greenpenevents"

  tags = {
    Name        = "sit-greenpenevents-db-credentials"
    Environment = var.environment
    Tenant      = "greenpenevents"
  }
}

resource "aws_secretsmanager_secret_version" "sit_greenpenevents_db" {
  secret_id = aws_secretsmanager_secret.sit_greenpenevents_db.id
  secret_string = jsonencode({
    username = "greenpenevents_user"
    password = random_password.sit_greenpenevents_db.result
    database = "greenpenevents_db"
    host     = aws_db_instance.main.address
    port     = 3306
  })
}

# EFS Access Point for GREENPENEVENTS
resource "aws_efs_access_point" "sit_greenpenevents" {
  file_system_id = aws_efs_file_system.main.id

  root_directory {
    path = "/greenpenevents"
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
    Name        = "sit-greenpenevents-ap"
    Environment = var.environment
    Tenant      = "greenpenevents"
  }
}

# ECS Task Definition for GREENPENEVENTS
resource "aws_ecs_task_definition" "sit_greenpenevents" {
  family                   = "sit-greenpenevents"
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
        value = "greenpenevents_db"
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
          define('WP_HOME', 'https://greenpenevents.wpsit.kimmyai.io');
          define('WP_SITEURL', 'https://greenpenevents.wpsit.kimmyai.io');
          define('WP_ENVIRONMENT_TYPE', 'staging');
        EOT
      }
    ]

    secrets = [
      {
        name      = "WORDPRESS_DB_USER"
        valueFrom = "${aws_secretsmanager_secret.sit_greenpenevents_db.arn}:username::"
      },
      {
        name      = "WORDPRESS_DB_PASSWORD"
        valueFrom = "${aws_secretsmanager_secret.sit_greenpenevents_db.arn}:password::"
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
        "awslogs-stream-prefix" = "greenpenevents"
      }
    }
  }])

  volume {
    name = "wp-content"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.main.id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.sit_greenpenevents.id
        iam             = "ENABLED"
      }
    }
  }

  tags = {
    Name        = "sit-greenpenevents-task"
    Environment = var.environment
    Tenant      = "greenpenevents"
  }
}

# ECS Service for GREENPENEVENTS
resource "aws_ecs_service" "sit_greenpenevents" {
  name            = "sit-greenpenevents-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.sit_greenpenevents.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.sit_greenpenevents.arn
    container_name   = "wordpress"
    container_port   = 80
  }

  depends_on = [
    aws_lb_listener_rule.sit_greenpenevents,
  ]

  tags = {
    Name        = "sit-greenpenevents-service"
    Environment = var.environment
    Tenant      = "greenpenevents"
  }
}

# Target Group for GREENPENEVENTS
resource "aws_lb_target_group" "sit_greenpenevents" {
  name        = "sit-greenpenevents-tg"
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
    Name        = "sit-greenpenevents-tg"
    Environment = var.environment
    Tenant      = "greenpenevents"
  }
}

# ALB Listener Rule for GREENPENEVENTS
resource "aws_lb_listener_rule" "sit_greenpenevents" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 110

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sit_greenpenevents.arn
  }

  condition {
    host_header {
      values = ["greenpenevents.wpsit.kimmyai.io"]
    }
  }

  tags = {
    Name        = "sit-greenpenevents-rule"
    Environment = var.environment
    Tenant      = "greenpenevents"
  }
}
