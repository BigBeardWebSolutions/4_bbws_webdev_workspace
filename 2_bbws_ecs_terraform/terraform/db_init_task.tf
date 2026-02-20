# Database Initialization Task Definition
# This creates a one-time task that initializes the database for tenant-1

resource "aws_ecs_task_definition" "db_init" {
  family                   = "${var.environment}-db-init"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([{
    name  = "db-init"
    image = "mysql:8.0"
    command = [
      "sh",
      "-c",
      <<-EOT
        echo "Waiting for RDS to be ready..."
        sleep 10
        echo "Creating database and user..."
        mysql -h $DB_HOST -u $MASTER_USER -p$MASTER_PASS <<EOF
        CREATE DATABASE IF NOT EXISTS $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
        CREATE USER IF NOT EXISTS '$DB_USER'@'%' IDENTIFIED BY '$DB_PASS';
        GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'%';
        FLUSH PRIVILEGES;
        SHOW DATABASES;
        SELECT User, Host FROM mysql.user WHERE User = '$DB_USER';
        EOF
        echo "Database initialization completed!"
      EOT
    ]

    secrets = [
      {
        name      = "MASTER_USER"
        valueFrom = "${aws_secretsmanager_secret.rds_master.arn}:username::"
      },
      {
        name      = "MASTER_PASS"
        valueFrom = "${aws_secretsmanager_secret.rds_master.arn}:password::"
      },
      {
        name      = "DB_USER"
        valueFrom = "${aws_secretsmanager_secret.tenant_1_db.arn}:username::"
      },
      {
        name      = "DB_PASS"
        valueFrom = "${aws_secretsmanager_secret.tenant_1_db.arn}:password::"
      },
      {
        name      = "DB_NAME"
        valueFrom = "${aws_secretsmanager_secret.tenant_1_db.arn}:database::"
      }
    ]

    environment = [
      {
        name  = "DB_HOST"
        value = aws_db_instance.main.address
      }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.ecs.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "db-init"
      }
    }
  }])

  tags = {
    Name        = "${var.environment}-db-init"
    Environment = var.environment
  }
}
