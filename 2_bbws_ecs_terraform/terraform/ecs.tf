# ECS Module for POC1 - ECS Fargate Multi-Tenant WordPress

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.environment}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "${var.environment}-cluster"
    Environment = var.environment
  }
}

# CloudWatch Log Group is defined in cloudwatch.tf

# ECS Task Execution Role (for pulling images, writing logs, accessing secrets)
resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.environment}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })

  tags = {
    Name        = "${var.environment}-ecs-task-execution-role"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Additional policy for Secrets Manager access
resource "aws_iam_role_policy" "ecs_task_execution_secrets" {
  name = "${var.environment}-ecs-secrets-access"
  role = aws_iam_role.ecs_task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue"
      ]
      Resource = [
        aws_secretsmanager_secret.rds_master.arn,
        "${aws_secretsmanager_secret.rds_master.arn}*",
        aws_secretsmanager_secret.tenant_1_db.arn,
        "${aws_secretsmanager_secret.tenant_1_db.arn}*"
      ]
    }]
  })
}

# ECS Task Role (for tasks to access AWS services)
resource "aws_iam_role" "ecs_task" {
  name = "${var.environment}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })

  tags = {
    Name        = "${var.environment}-ecs-task-role"
    Environment = var.environment
  }
}

# Policy for EFS access
resource "aws_iam_role_policy" "ecs_task_efs" {
  name = "${var.environment}-ecs-efs-access"
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
          "elasticfilesystem:AccessPointArn" = aws_efs_access_point.tenant_1.arn
        }
      }
    }]
  })
}

# Random password for tenant-1 database
resource "random_password" "tenant_1_db" {
  length  = 24
  special = false # Avoid special chars for easier MySQL compatibility
}

# Secrets Manager secret for tenant-1 database credentials
resource "aws_secretsmanager_secret" "tenant_1_db" {
  name        = "${var.environment}-tenant-1-db-credentials"
  description = "Database credentials for tenant-1"

  tags = {
    Name        = "${var.environment}-tenant-1-db-credentials"
    Environment = var.environment
    Tenant      = "tenant-1"
  }
}

resource "aws_secretsmanager_secret_version" "tenant_1_db" {
  secret_id = aws_secretsmanager_secret.tenant_1_db.id
  secret_string = jsonencode({
    username = "tenant_1_user"
    password = random_password.tenant_1_db.result
    database = "tenant_1_db"
    host     = aws_db_instance.main.address
    port     = 3306
  })
}

# Local variable for WordPress image selection
locals {
  # Use ECR image if use_ecr_image is true, otherwise fall back to Docker Hub or custom image
  wordpress_image = var.use_ecr_image ? "${aws_ecr_repository.wordpress.repository_url}:${var.wordpress_image_tag}" : (
    var.wordpress_image != "" ? "${var.wordpress_image}:${var.wordpress_image_tag}" : "wordpress:${var.wordpress_image_tag}"
  )
}

# ECS Task Definition for Tenant 1
resource "aws_ecs_task_definition" "tenant_1" {
  family                   = "${var.environment}-tenant-1"
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
        value = "tenant_1_db"
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
          define('WP_HOME', 'https://tenant1.wpdev.kimmyai.io');
          define('WP_SITEURL', 'https://tenant1.wpdev.kimmyai.io');
        EOT
      }
    ]

    secrets = [
      {
        name      = "WORDPRESS_DB_USER"
        valueFrom = "${aws_secretsmanager_secret.tenant_1_db.arn}:username::"
      },
      {
        name      = "WORDPRESS_DB_PASSWORD"
        valueFrom = "${aws_secretsmanager_secret.tenant_1_db.arn}:password::"
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
        "awslogs-stream-prefix" = "tenant-1"
      }
    }
  }])

  volume {
    name = "wp-content"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.main.id
      transit_encryption = "ENABLED"

      authorization_config {
        access_point_id = aws_efs_access_point.tenant_1.id
        iam             = "ENABLED"
      }
    }
  }

  tags = {
    Name        = "${var.environment}-tenant-1-task"
    Environment = var.environment
    Tenant      = "tenant-1"
  }
}

# ECS Service for Tenant 1
resource "aws_ecs_service" "tenant_1" {
  name            = "${var.environment}-tenant-1-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.tenant_1.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tenant_1.arn
    container_name   = "wordpress"
    container_port   = 80
  }

  depends_on = [
    aws_lb_listener.http,
    aws_efs_mount_target.main
  ]

  tags = {
    Name        = "${var.environment}-tenant-1-service"
    Environment = var.environment
    Tenant      = "tenant-1"
  }
}
