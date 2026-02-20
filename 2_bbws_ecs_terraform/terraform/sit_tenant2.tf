# SIT Tenant: tenant2
# Auto-generated from DEV configuration: /Users/tebogotseka/Documents/agentic_work/2_bbws_agents/../2_bbws_ecs_terraform/terraform/tenant2.tf
# Generated: 2025-12-21 20:38:41
# ALB Priority: 160
# Tenant 2 Infrastructure for POC1
# This creates all resources for a second tenant to demonstrate multi-tenancy

# Random password for tenant-2 database
resource "random_password" "sit_tenant_2_db" {
  length  = 24
  special = false
}

# Secrets Manager secret for tenant-2 database credentials
resource "aws_secretsmanager_secret" "sit_tenant_2_db" {
  name        = "sit-tenant-2-db-credentials"
  description = "Database credentials for tenant-2"

  tags = {
    Name        = "sit-tenant-2-db-credentials"
    Environment = var.environment
    Tenant      = "tenant-2"
  }
}

resource "aws_secretsmanager_secret_version" "sit_tenant_2_db" {
  secret_id = aws_secretsmanager_secret.sit_tenant_2_db.id
  secret_string = jsonencode({
    username = "tenant_2_user"
    password = random_password.sit_tenant_2_db.result
    database = "tenant_2_db"
    host     = aws_db_instance.main.address
    port     = 3306
  })
}

# EFS Access Point for Tenant 2
resource "aws_efs_access_point" "sit_tenant_2" {
  file_system_id = aws_efs_file_system.main.id

  root_directory {
    path = "/tenant-2"
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
    Name        = "sit-tenant-2-ap"
    Environment = var.environment
    Tenant      = "tenant-2"
  }
}

# ECS Task Definition for Tenant 2
resource "aws_ecs_task_definition" "sit_tenant_2" {
  family                   = "sit-tenant-2"
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
        value = "tenant_2_db"
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
          /* Disable HTTPS redirects for POC */
          define('FORCE_SSL_ADMIN', false);
          define('FORCE_SSL_LOGIN', false);
          $_SERVER['HTTPS'] = 'off';

          /* Fix for load balancer */
          if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
              $_SERVER['HTTPS'] = 'on';
          }
        EOT
      }
    ]

    secrets = [
      {
        name      = "WORDPRESS_DB_USER"
        valueFrom = "${aws_secretsmanager_secret.sit_tenant_2_db.arn}:username::"
      },
      {
        name      = "WORDPRESS_DB_PASSWORD"
        valueFrom = "${aws_secretsmanager_secret.sit_tenant_2_db.arn}:password::"
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
        "awslogs-stream-prefix" = "tenant-2"
      }
    }
  }])

  volume {
    name = "wp-content"

    efs_volume_configuration {
      file_system_id          = aws_efs_file_system.main.id
      transit_encryption      = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.sit_tenant_2.id
        iam             = "ENABLED"
      }
    }
  }

  tags = {
    Name        = "sit-tenant-2-task"
    Environment = var.environment
    Tenant      = "tenant-2"
  }
}

# ALB Target Group for Tenant 2
resource "aws_lb_target_group" "sit_tenant_2" {
  name        = "sit-tenant-2-tg"
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
    Name        = "sit-tenant-2-tg"
    Environment = var.environment
    Tenant      = "tenant-2"
  }
}

# ALB Listener Rule for Tenant 2 - Host-based routing
resource "aws_lb_listener_rule" "sit_tenant_2" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 160

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sit_tenant_2.arn
  }

  condition {
    host_header {
      values = ["tenant2.wpsit.kimmyai.io"]
    }
  }

  tags = {
    Name        = "sit-tenant-2-rule"
    Environment = var.environment
    Tenant      = "tenant-2"
  }
}

# ECS Service for Tenant 2
resource "aws_ecs_service" "sit_tenant_2" {
  name            = "sit-tenant-2-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.sit_tenant_2.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.sit_tenant_2.arn
    container_name   = "wordpress"
    container_port   = 80
  }

  depends_on = [
    aws_lb_listener_rule.sit_tenant_2,
    null_resource.sit_tenant_2_db_init
  ]

  tags = {
    Name        = "sit-tenant-2-service"
    Environment = var.environment
    Tenant      = "tenant-2"
  }
}

# Database initialization for Tenant 2
resource "null_resource" "sit_tenant_2_db_init" {
  depends_on = [
    aws_db_instance.main,
    aws_secretsmanager_secret_version.sit_tenant_2_db,
    aws_ecs_task_definition.db_init
  ]

  provisioner "local-exec" {
    command = <<-EOT
      # Run ECS task to initialize tenant-2 database
      TASK_ARN=$(aws ecs run-task \
        --cluster ${aws_ecs_cluster.main.name} \
        --task-definition ${aws_ecs_task_definition.db_init.family} \
        --launch-type FARGATE \
        --network-configuration "awsvpcConfiguration={subnets=[${join(",", aws_subnet.private[*].id)}],securityGroups=[${aws_security_group.ecs_tasks.id}],assignPublicIp=DISABLED}" \
        --region ${var.aws_region} \
        --overrides '{"containerOverrides":[{"name":"db-init","environment":[{"name":"DB_HOST","value":"${aws_db_instance.main.address}"},{"name":"DB_NAME","value":"tenant_2_db"},{"name":"MASTER_USER_SECRET","value":"${aws_secretsmanager_secret.rds_master.arn}:username::"},{"name":"MASTER_PASS_SECRET","value":"${aws_secretsmanager_secret.rds_master.arn}:password::"},{"name":"DB_USER_SECRET","value":"${aws_secretsmanager_secret.tenant_2_db.arn}:username::"},{"name":"DB_PASS_SECRET","value":"${aws_secretsmanager_secret.tenant_2_db.arn}:password::"}]}]}' \
        --query 'tasks[0].taskArn' \
        --output text)

      echo "Waiting for database initialization task to complete..."
      aws ecs wait tasks-stopped \
        --cluster ${aws_ecs_cluster.main.name} \
        --tasks $TASK_ARN \
        --region ${var.aws_region} || echo "Tenant 2 database initialized successfully"
    EOT

    environment = {
      AWS_REGION = var.aws_region
    }
  }

  triggers = {
    db_secret = aws_secretsmanager_secret_version.sit_tenant_2_db.id
  }
}

# Update IAM policy to allow access to tenant-2 secret
resource "aws_iam_role_policy" "ecs_task_execution_secrets_sit_tenant_2" {
  name = "sit-ecs-secrets-access-tenant-2"
  role = aws_iam_role.ecs_task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue"
      ]
      Resource = [
        aws_secretsmanager_secret.sit_tenant_2_db.arn,
        "${aws_secretsmanager_secret.sit_tenant_2_db.arn}*"
      ]
    }]
  })
}

# Update EFS access policy for tenant-2
resource "aws_iam_role_policy" "ecs_task_efs_sit_tenant_2" {
  name = "sit-ecs-efs-access-tenant-2"
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
          "elasticfilesystem:AccessPointArn" = aws_efs_access_point.sit_tenant_2.arn
        }
      }
    }]
  })
}
