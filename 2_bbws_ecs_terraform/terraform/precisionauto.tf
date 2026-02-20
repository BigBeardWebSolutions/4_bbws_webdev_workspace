# PRECISIONAUTO Tenant Infrastructure
# Auto-generated multi-tenant WordPress resources

# Random password for precisionauto database
resource "random_password" "precisionauto_db" {
  length  = 24
  special = false
}

# Secrets Manager secret for precisionauto database credentials
resource "aws_secretsmanager_secret" "precisionauto_db" {
  name        = "${var.environment}-precisionauto-db-credentials"
  description = "Database credentials for precisionauto"

  tags = {
    Name        = "${var.environment}-precisionauto-db-credentials"
    Environment = var.environment
    Tenant      = "precisionauto"
  }
}

resource "aws_secretsmanager_secret_version" "precisionauto_db" {
  secret_id = aws_secretsmanager_secret.precisionauto_db.id
  secret_string = jsonencode({
    username = "precisionauto_user"
    password = random_password.precisionauto_db.result
    database = "precisionauto_db"
    host     = aws_db_instance.main.address
    port     = 3306
  })
}

# EFS Access Point for PRECISIONAUTO
resource "aws_efs_access_point" "precisionauto" {
  file_system_id = aws_efs_file_system.main.id

  root_directory {
    path = "/precisionauto"
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
    Name        = "${var.environment}-precisionauto-ap"
    Environment = var.environment
    Tenant      = "precisionauto"
  }
}

# ECS Task Definition for PRECISIONAUTO
resource "aws_ecs_task_definition" "precisionauto" {
  family                   = "${var.environment}-precisionauto"
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
        value = "precisionauto_db"
      },
      {
        name  = "WORDPRESS_TABLE_PREFIX"
        value = "wp_"
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
          define('WP_HOME', 'https://precisionauto.wpdev.kimmyai.io');
          define('WP_SITEURL', 'https://precisionauto.wpdev.kimmyai.io');
        EOT
      }
    ]

    secrets = [
      {
        name      = "WORDPRESS_DB_USER"
        valueFrom = "${aws_secretsmanager_secret.precisionauto_db.arn}:username::"
      },
      {
        name      = "WORDPRESS_DB_PASSWORD"
        valueFrom = "${aws_secretsmanager_secret.precisionauto_db.arn}:password::"
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
        "awslogs-stream-prefix" = "precisionauto"
      }
    }
  }])

  volume {
    name = "wp-content"

    efs_volume_configuration {
      file_system_id          = aws_efs_file_system.main.id
      transit_encryption      = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.precisionauto.id
        iam             = "ENABLED"
      }
    }
  }

  tags = {
    Name        = "${var.environment}-precisionauto-task"
    Environment = var.environment
    Tenant      = "precisionauto"
  }
}

# ECS Service for PRECISIONAUTO
resource "aws_ecs_service" "precisionauto" {
  name            = "${var.environment}-precisionauto-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.precisionauto.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.precisionauto.arn
    container_name   = "wordpress"
    container_port   = 80
  }

  depends_on = [
    aws_lb_listener_rule.precisionauto,
  ]

  tags = {
    Name        = "${var.environment}-precisionauto-service"
    Environment = var.environment
    Tenant      = "precisionauto"
  }
}

# Target Group for PRECISIONAUTO
resource "aws_lb_target_group" "precisionauto" {
  name        = "${var.environment}-precisionauto-tg"
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
    Name        = "${var.environment}-precisionauto-tg"
    Environment = var.environment
    Tenant      = "precisionauto"
  }
}

# ALB Listener Rule for PRECISIONAUTO
resource "aws_lb_listener_rule" "precisionauto" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 80 

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.precisionauto.arn
  }

  condition {
    host_header {
      values = ["precisionauto.wpdev.kimmyai.io"]
    }
  }

  tags = {
    Name        = "${var.environment}-precisionauto-rule"
    Environment = var.environment
    Tenant      = "precisionauto"
  }
}


