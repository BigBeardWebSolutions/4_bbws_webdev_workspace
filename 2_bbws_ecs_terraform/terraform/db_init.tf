# Database Initialization for Tenant 1

# Wait for RDS to be available and create tenant-1 database
resource "null_resource" "tenant_1_db_init" {
  depends_on = [
    aws_db_instance.main,
    aws_secretsmanager_secret_version.rds_master,
    aws_secretsmanager_secret_version.tenant_1_db
  ]

  provisioner "local-exec" {
    command = <<-EOT
      # Wait for RDS to be fully available
      sleep 60

      # Get RDS master credentials from Secrets Manager
      MASTER_SECRET=$(aws secretsmanager get-secret-value \
        --secret-id ${aws_secretsmanager_secret.rds_master.arn} \
        --region ${var.aws_region} \
        --query SecretString \
        --output text)

      MASTER_USER=$(echo $MASTER_SECRET | jq -r '.username')
      MASTER_PASS=$(echo $MASTER_SECRET | jq -r '.password')
      RDS_HOST="${aws_db_instance.main.address}"

      # Get tenant-1 credentials from Secrets Manager
      TENANT_SECRET=$(aws secretsmanager get-secret-value \
        --secret-id ${aws_secretsmanager_secret.tenant_1_db.arn} \
        --region ${var.aws_region} \
        --query SecretString \
        --output text)

      TENANT_USER=$(echo $TENANT_SECRET | jq -r '.username')
      TENANT_PASS=$(echo $TENANT_SECRET | jq -r '.password')

      # Create database and user via MySQL client
      # Note: This requires mysql client installed and network access to RDS
      # For POC, you may need to run this manually if mysql client is not available
      echo "Creating tenant_1_db database and user..."
      mysql -h "$RDS_HOST" -u "$MASTER_USER" -p"$MASTER_PASS" <<-SQL
        CREATE DATABASE IF NOT EXISTS tenant_1_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
        CREATE USER IF NOT EXISTS '$TENANT_USER'@'%' IDENTIFIED BY '$TENANT_PASS';
        GRANT ALL PRIVILEGES ON tenant_1_db.* TO '$TENANT_USER'@'%';
        FLUSH PRIVILEGES;
SQL

      echo "Tenant 1 database initialized successfully"
    EOT

    environment = {
      AWS_REGION = var.aws_region
    }
  }

  triggers = {
    rds_endpoint = aws_db_instance.main.endpoint
  }
}
