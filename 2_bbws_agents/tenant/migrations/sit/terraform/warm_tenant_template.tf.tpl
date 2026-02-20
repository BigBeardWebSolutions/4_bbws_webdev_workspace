# SIT Tenant: __TENANT__
# Warm Tenant — Pre-provisioned for quick DEV-to-SIT promotion
# Generated: __DATE__
# ALB Priority: __ALB_PRIORITY__
# Image: DEV ECR (cross-account pull)

# Random password for __TENANT__ database
resource "random_password" "sit___TENANT___db" {
  length  = 24
  special = false
}

# Secrets Manager secret for __TENANT__ database credentials
resource "aws_secretsmanager_secret" "sit___TENANT___db" {
  name        = "sit-__TENANT__-db-credentials"
  description = "Database credentials for __TENANT__"

  tags = {
    Name        = "sit-__TENANT__-db-credentials"
    Environment = var.environment
    Tenant      = "__TENANT__"
    WarmTenant  = "true"
  }
}

resource "aws_secretsmanager_secret_version" "sit___TENANT___db" {
  secret_id = aws_secretsmanager_secret.sit___TENANT___db.id
  secret_string = jsonencode({
    username = "__TENANT___user"
    password = random_password.sit___TENANT___db.result
    database = "__TENANT___db"
    host     = aws_db_instance.main.address
    port     = 3306
  })
}

# EFS Access Point for __TENANT__
resource "aws_efs_access_point" "sit___TENANT__" {
  file_system_id = aws_efs_file_system.main.id

  root_directory {
    path = "/__TENANT__"
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
    Name        = "sit-__TENANT__-ap"
    Environment = var.environment
    Tenant      = "__TENANT__"
    WarmTenant  = "true"
  }
}

# ECS Task Definition for __TENANT__
resource "aws_ecs_task_definition" "sit___TENANT__" {
  family                   = "sit-__TENANT__"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.ecs_task_cpu
  memory                   = var.ecs_task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([{
    name      = "wordpress"
    image     = "536580886816.dkr.ecr.eu-west-1.amazonaws.com/dev-wordpress:latest"
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
        value = "__TENANT___db"
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
          define('WP_HOME', 'https://__TENANT__.wpsit.kimmyai.io');
          define('WP_SITEURL', 'https://__TENANT__.wpsit.kimmyai.io');
        EOT
      }
    ]

    secrets = [
      {
        name      = "WORDPRESS_DB_USER"
        valueFrom = "${aws_secretsmanager_secret.sit___TENANT___db.arn}:username::"
      },
      {
        name      = "WORDPRESS_DB_PASSWORD"
        valueFrom = "${aws_secretsmanager_secret.sit___TENANT___db.arn}:password::"
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
        "awslogs-stream-prefix" = "__TENANT__"
      }
    }
  }])

  volume {
    name = "wp-content"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.main.id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.sit___TENANT__.id
        iam             = "ENABLED"
      }
    }
  }

  tags = {
    Name        = "sit-__TENANT__-task"
    Environment = var.environment
    Tenant      = "__TENANT__"
    WarmTenant  = "true"
  }
}

# ECS Service for __TENANT__
resource "aws_ecs_service" "sit___TENANT__" {
  name            = "sit-__TENANT__-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.sit___TENANT__.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.sit___TENANT__.arn
    container_name   = "wordpress"
    container_port   = 80
  }

  depends_on = [
    aws_lb_listener_rule.sit___TENANT__,
  ]

  tags = {
    Name        = "sit-__TENANT__-service"
    Environment = var.environment
    Tenant      = "__TENANT__"
    WarmTenant  = "true"
  }
}

# Target Group for __TENANT__
resource "aws_lb_target_group" "sit___TENANT__" {
  name        = "sit-__TENANT__-tg"
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
    Name        = "sit-__TENANT__-tg"
    Environment = var.environment
    Tenant      = "__TENANT__"
    WarmTenant  = "true"
  }
}

# ALB Listener Rule for __TENANT__
resource "aws_lb_listener_rule" "sit___TENANT__" {
  listener_arn = aws_lb_listener.http.arn
  priority     = __ALB_PRIORITY__

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sit___TENANT__.arn
  }

  condition {
    host_header {
      values = ["__TENANT__.wpsit.kimmyai.io"]
    }
  }

  tags = {
    Name        = "sit-__TENANT__-rule"
    Environment = var.environment
    Tenant      = "__TENANT__"
    WarmTenant  = "true"
  }
}
