# GOLDENCRUST Tenant Infrastructure
# Auto-generated multi-tenant WordPress resources

# Random password for goldencrust database
resource "random_password" "goldencrust_db" {
  length  = 24
  special = false
}

# Secrets Manager secret for goldencrust database credentials
resource "aws_secretsmanager_secret" "goldencrust_db" {
  name        = "${var.environment}-goldencrust-db-credentials"
  description = "Database credentials for goldencrust"

  tags = {
    Name        = "${var.environment}-goldencrust-db-credentials"
    Environment = var.environment
    Tenant      = "goldencrust"
  }
}

resource "aws_secretsmanager_secret_version" "goldencrust_db" {
  secret_id = aws_secretsmanager_secret.goldencrust_db.id
  secret_string = jsonencode({
    username = "goldencrust_user"
    password = random_password.goldencrust_db.result
    database = "goldencrust_db"
    host     = aws_db_instance.main.address
    port     = 3306
  })
}

# EFS Access Point for GOLDENCRUST
resource "aws_efs_access_point" "goldencrust" {
  file_system_id = aws_efs_file_system.main.id

  root_directory {
    path = "/goldencrust"
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
    Name        = "${var.environment}-goldencrust-ap"
    Environment = var.environment
    Tenant      = "goldencrust"
  }
}

# ECS Task Definition for GOLDENCRUST
resource "aws_ecs_task_definition" "goldencrust" {
  family                   = "${var.environment}-goldencrust"
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
        value = "goldencrust_db"
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
          define('WP_HOME', 'https://goldencrust.wpdev.kimmyai.io');
          define('WP_SITEURL', 'https://goldencrust.wpdev.kimmyai.io');
        EOT
      }
    ]

    secrets = [
      {
        name      = "WORDPRESS_DB_USER"
        valueFrom = "${aws_secretsmanager_secret.goldencrust_db.arn}:username::"
      },
      {
        name      = "WORDPRESS_DB_PASSWORD"
        valueFrom = "${aws_secretsmanager_secret.goldencrust_db.arn}:password::"
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
        "awslogs-stream-prefix" = "goldencrust"
      }
    }
  }])

  volume {
    name = "wp-content"

    efs_volume_configuration {
      file_system_id          = aws_efs_file_system.main.id
      transit_encryption      = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.goldencrust.id
        iam             = "ENABLED"
      }
    }
  }

  tags = {
    Name        = "${var.environment}-goldencrust-task"
    Environment = var.environment
    Tenant      = "goldencrust"
  }
}

# ECS Service for GOLDENCRUST
resource "aws_ecs_service" "goldencrust" {
  name            = "${var.environment}-goldencrust-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.goldencrust.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.goldencrust.arn
    container_name   = "wordpress"
    container_port   = 80
  }

  depends_on = [
    aws_lb_listener_rule.goldencrust,
  ]

  tags = {
    Name        = "${var.environment}-goldencrust-service"
    Environment = var.environment
    Tenant      = "goldencrust"
  }
}

# Target Group for GOLDENCRUST
resource "aws_lb_target_group" "goldencrust" {
  name        = "${var.environment}-goldencrust-tg"
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
    Name        = "${var.environment}-goldencrust-tg"
    Environment = var.environment
    Tenant      = "goldencrust"
  }
}

# ALB Listener Rule for GOLDENCRUST
resource "aws_lb_listener_rule" "goldencrust" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 40 

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.goldencrust.arn
  }

  condition {
    host_header {
      values = ["goldencrust.wpdev.kimmyai.io"]
    }
  }

  tags = {
    Name        = "${var.environment}-goldencrust-rule"
    Environment = var.environment
    Tenant      = "goldencrust"
  }
}


