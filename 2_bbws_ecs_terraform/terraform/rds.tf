# RDS Module for POC1 - ECS Fargate Multi-Tenant WordPress

# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.environment}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name        = "${var.environment}-db-subnet-group"
    Environment = var.environment
  }
}

# DB Parameter Group
resource "aws_db_parameter_group" "main" {
  name   = "${var.environment}-mysql-params"
  family = "mysql8.0"

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "collation_server"
    value = "utf8mb4_unicode_ci"
  }

  parameter {
    name  = "max_connections"
    value = "100"
  }

  tags = {
    Name        = "${var.environment}-mysql-params"
    Environment = var.environment
  }
}

# Random password for RDS master user
resource "random_password" "rds_master" {
  length  = 32
  special = false # Avoid special chars that RDS doesn't allow (/, @, ", space)
}

# Store RDS master credentials in Secrets Manager
resource "aws_secretsmanager_secret" "rds_master" {
  name        = "${var.environment}-rds-master-credentials"
  description = "RDS master user credentials for POC"

  tags = {
    Name        = "${var.environment}-rds-master-credentials"
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "rds_master" {
  secret_id = aws_secretsmanager_secret.rds_master.id
  secret_string = jsonencode({
    username = var.rds_master_username
    password = random_password.rds_master.result
    engine   = "mysql"
    host     = aws_db_instance.main.endpoint
    port     = 3306
  })
}

# RDS MySQL Instance
resource "aws_db_instance" "main" {
  identifier             = "${var.environment}-mysql"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = var.rds_instance_class
  allocated_storage      = 20
  storage_type           = "gp3"
  storage_encrypted      = true
  db_name                = null # Do not create default DB, we create per-tenant DBs
  username               = var.rds_master_username
  password               = random_password.rds_master.result
  parameter_group_name   = aws_db_parameter_group.main.name
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  # Environment-specific settings (configured via tfvars)
  multi_az                  = var.rds_multi_az
  skip_final_snapshot       = var.rds_skip_final_snapshot
  final_snapshot_identifier = var.rds_skip_final_snapshot ? null : "${var.environment}-mysql-final-${formatdate("YYYY-MM-DD", timestamp())}"
  backup_retention_period   = var.rds_backup_retention
  backup_window             = "03:00-04:00"
  maintenance_window        = "Mon:04:00-Mon:05:00"

  tags = {
    Name        = "${var.environment}-mysql"
    Environment = var.environment
  }

  lifecycle {
    ignore_changes = [final_snapshot_identifier]
  }
}
