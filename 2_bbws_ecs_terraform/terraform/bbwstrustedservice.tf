# BBWS Trusted Service Tenant Infrastructure
# Agent: Tenant Manager Agent
# Created: 2025-12-16
# Domain: bbwstrustedservice.co.za

#------------------------------------------------------------------------------
# Database Credentials
#------------------------------------------------------------------------------

resource "random_password" "bbwstrustedservice_db" {
  length  = 24
  special = false
}

resource "aws_secretsmanager_secret" "bbwstrustedservice_db" {
  name        = "${var.environment}-bbwstrustedservice-db-credentials"
  description = "Database credentials for bbwstrustedservice tenant"

  tags = {
    Name        = "${var.environment}-bbwstrustedservice-db-credentials"
    Environment = var.environment
    Tenant      = "bbwstrustedservice"
    Domain      = "bbwstrustedservice.co.za"
  }
}

resource "aws_secretsmanager_secret_version" "bbwstrustedservice_db" {
  secret_id = aws_secretsmanager_secret.bbwstrustedservice_db.id
  secret_string = jsonencode({
    username = "bbwstrusted_user"
    password = random_password.bbwstrustedservice_db.result
    database = "bbwstrustedservice_db"
    host     = aws_db_instance.main.address
    port     = 3306
  })
}

#------------------------------------------------------------------------------
# EFS Access Point
#------------------------------------------------------------------------------

resource "aws_efs_access_point" "bbwstrustedservice" {
  file_system_id = aws_efs_file_system.main.id

  root_directory {
    path = "/bbwstrustedservice"
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
    Name        = "${var.environment}-bbwstrustedservice-ap"
    Environment = var.environment
    Tenant      = "bbwstrustedservice"
    Domain      = "bbwstrustedservice.co.za"
  }
}

#------------------------------------------------------------------------------
# ECS Task Definition
#------------------------------------------------------------------------------

resource "aws_ecs_task_definition" "bbwstrustedservice" {
  family                   = "${var.environment}-bbwstrustedservice"
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
        value = "bbwstrustedservice_db"
      },
      {
        name  = "WORDPRESS_TABLE_PREFIX"
        value = "wp_"
      },
      {
        name  = "WORDPRESS_DEBUG"
        value = var.environment == "prod" ? "0" : "1"
      },
      {
        name  = "WORDPRESS_CONFIG_EXTRA"
        value = <<-EOT
          /* HTTPS Detection for ALB/CloudFront - BBWS HTTPS Fix */
          if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
              $_SERVER['HTTPS'] = 'on';
          }
          if (isset($_SERVER['HTTP_CLOUDFRONT_FORWARDED_PROTO']) && $_SERVER['HTTP_CLOUDFRONT_FORWARDED_PROTO'] === 'https') {
              $_SERVER['HTTPS'] = 'on';
          }

          /* Force HTTPS URLs */
          define('FORCE_SSL_ADMIN', true);
          define('WP_HOME', 'https://bbwstrustedservice.wpdev.kimmyai.io');
          define('WP_SITEURL', 'https://bbwstrustedservice.wpdev.kimmyai.io');
        EOT
      }
    ]

    secrets = [
      {
        name      = "WORDPRESS_DB_USER"
        valueFrom = "${aws_secretsmanager_secret.bbwstrustedservice_db.arn}:username::"
      },
      {
        name      = "WORDPRESS_DB_PASSWORD"
        valueFrom = "${aws_secretsmanager_secret.bbwstrustedservice_db.arn}:password::"
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
        "awslogs-stream-prefix" = "bbwstrustedservice"
      }
    }
  }])

  volume {
    name = "wp-content"

    efs_volume_configuration {
      file_system_id          = aws_efs_file_system.main.id
      transit_encryption      = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.bbwstrustedservice.id
        iam             = "ENABLED"
      }
    }
  }

  tags = {
    Name        = "${var.environment}-bbwstrustedservice-task"
    Environment = var.environment
    Tenant      = "bbwstrustedservice"
    Domain      = "bbwstrustedservice.co.za"
  }
}

#------------------------------------------------------------------------------
# ALB Target Group
#------------------------------------------------------------------------------

resource "aws_lb_target_group" "bbwstrustedservice" {
  name        = "${var.environment}-bbwstrust-tg"  # Max 32 chars
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
    Name        = "${var.environment}-bbwstrustedservice-tg"
    Environment = var.environment
    Tenant      = "bbwstrustedservice"
    Domain      = "bbwstrustedservice.co.za"
  }
}

#------------------------------------------------------------------------------
# ALB Listener Rule - Host-based routing
#------------------------------------------------------------------------------

resource "aws_lb_listener_rule" "bbwstrustedservice" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 50  # Unique priority for this tenant

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.bbwstrustedservice.arn
  }

  condition {
    host_header {
      values = [
        "bbwstrustedservice.wpdev.kimmyai.io",
        "bbwstrustedservice.co.za",
        "www.bbwstrustedservice.co.za"
      ]
    }
  }

  tags = {
    Name        = "${var.environment}-bbwstrustedservice-rule"
    Environment = var.environment
    Tenant      = "bbwstrustedservice"
    Domain      = "bbwstrustedservice.co.za"
  }
}

#------------------------------------------------------------------------------
# ECS Service
#------------------------------------------------------------------------------

resource "aws_ecs_service" "bbwstrustedservice" {
  name            = "${var.environment}-bbwstrustedservice-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.bbwstrustedservice.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  # Enable ECS Execute Command for WP-CLI access
  enable_execute_command = true

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.bbwstrustedservice.arn
    container_name   = "wordpress"
    container_port   = 80
  }

  depends_on = [
    aws_lb_listener_rule.bbwstrustedservice,
    null_resource.bbwstrustedservice_db_init
  ]

  tags = {
    Name        = "${var.environment}-bbwstrustedservice-service"
    Environment = var.environment
    Tenant      = "bbwstrustedservice"
    Domain      = "bbwstrustedservice.co.za"
  }
}

#------------------------------------------------------------------------------
# Database Initialization
#------------------------------------------------------------------------------

resource "null_resource" "bbwstrustedservice_db_init" {
  depends_on = [
    aws_db_instance.main,
    aws_secretsmanager_secret_version.bbwstrustedservice_db,
    aws_ecs_task_definition.db_init
  ]

  provisioner "local-exec" {
    command = <<-EOT
      # Run ECS task to initialize bbwstrustedservice database
      TASK_ARN=$(aws ecs run-task \
        --cluster ${aws_ecs_cluster.main.name} \
        --task-definition ${aws_ecs_task_definition.db_init.family} \
        --launch-type FARGATE \
        --network-configuration "awsvpcConfiguration={subnets=[${join(",", aws_subnet.private[*].id)}],securityGroups=[${aws_security_group.ecs_tasks.id}],assignPublicIp=DISABLED}" \
        --region ${var.aws_region} \
        --overrides '{"containerOverrides":[{"name":"db-init","environment":[{"name":"DB_HOST","value":"${aws_db_instance.main.address}"},{"name":"DB_NAME","value":"bbwstrustedservice_db"},{"name":"MASTER_USER_SECRET","value":"${aws_secretsmanager_secret.rds_master.arn}:username::"},{"name":"MASTER_PASS_SECRET","value":"${aws_secretsmanager_secret.rds_master.arn}:password::"},{"name":"DB_USER_SECRET","value":"${aws_secretsmanager_secret.bbwstrustedservice_db.arn}:username::"},{"name":"DB_PASS_SECRET","value":"${aws_secretsmanager_secret.bbwstrustedservice_db.arn}:password::"}]}]}' \
        --query 'tasks[0].taskArn' \
        --output text)

      echo "Waiting for bbwstrustedservice database initialization..."
      aws ecs wait tasks-stopped \
        --cluster ${aws_ecs_cluster.main.name} \
        --tasks $TASK_ARN \
        --region ${var.aws_region} || echo "bbwstrustedservice database initialized"
    EOT

    environment = {
      AWS_REGION = var.aws_region
    }
  }

  triggers = {
    db_secret = aws_secretsmanager_secret_version.bbwstrustedservice_db.id
  }
}

#------------------------------------------------------------------------------
# IAM Policies for Tenant
#------------------------------------------------------------------------------

resource "aws_iam_role_policy" "ecs_task_execution_secrets_bbwstrustedservice" {
  name = "${var.environment}-ecs-secrets-access-bbwstrustedservice"
  role = aws_iam_role.ecs_task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue"
      ]
      Resource = [
        aws_secretsmanager_secret.bbwstrustedservice_db.arn,
        "${aws_secretsmanager_secret.bbwstrustedservice_db.arn}*"
      ]
    }]
  })
}

resource "aws_iam_role_policy" "ecs_task_efs_bbwstrustedservice" {
  name = "${var.environment}-ecs-efs-access-bbwstrustedservice"
  role = aws_iam_role.ecs_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "elasticfilesystem:ClientMount",
        "elasticfilesystem:ClientWrite",
        "elasticfilesystem:ClientRootAccess"
      ]
      Resource = aws_efs_file_system.main.arn
      Condition = {
        StringEquals = {
          "elasticfilesystem:AccessPointArn" = aws_efs_access_point.bbwstrustedservice.arn
        }
      }
    }]
  })
}

#------------------------------------------------------------------------------
# Outputs
#------------------------------------------------------------------------------

output "bbwstrustedservice_url" {
  description = "URL for bbwstrustedservice tenant"
  value       = "https://bbwstrustedservice.wpdev.kimmyai.io"
}

output "bbwstrustedservice_service_name" {
  description = "ECS service name for bbwstrustedservice"
  value       = aws_ecs_service.bbwstrustedservice.name
}

output "bbwstrustedservice_task_definition" {
  description = "Task definition ARN for bbwstrustedservice"
  value       = aws_ecs_task_definition.bbwstrustedservice.arn
}
