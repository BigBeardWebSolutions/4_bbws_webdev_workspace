#!/bin/bash
# Create database and user for a new tenant
# Usage: ./create_tenant_database.sh <tenant_id> <tenant_user> <tenant_password> <database_name>
# Example: ./create_tenant_database.sh 3 tenant_3_user mySecurePass123 tenant_3_db

set -e

if [ "$#" -ne 4 ]; then
  echo "Usage: $0 <tenant_id> <tenant_user> <tenant_password> <database_name>"
  echo "Example: $0 3 tenant_3_user mySecurePass123 tenant_3_db"
  exit 1
fi

TENANT_ID=$1
TENANT_USER=$2
TENANT_PASS=$3
DB_NAME=$4

export AWS_PROFILE=Tebogo-dev
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/../terraform"

echo "=== Creating database and user for Tenant $TENANT_ID ==="
echo "Database: $DB_NAME"
echo "User: $TENANT_USER"
echo ""

# Get RDS master credentials
cd "$TERRAFORM_DIR"

MASTER_USER=$(aws secretsmanager get-secret-value \
  --secret-id poc-rds-master-credentials \
  --region af-south-1 \
  --query SecretString \
  --output text | jq -r '.username')

MASTER_PASS=$(aws secretsmanager get-secret-value \
  --secret-id poc-rds-master-credentials \
  --region af-south-1 \
  --query SecretString \
  --output text | jq -r '.password')

RDS_HOST=$(terraform output -raw rds_address)

echo "RDS Host: $RDS_HOST"
echo "Creating ECS task to initialize database..."

# Create task override with SQL commands
cat <<EOF > /tmp/create_tenant_${TENANT_ID}_db.json
{
  "containerOverrides": [{
    "name": "db-init",
    "command": [
      "sh", "-c",
      "mysql -h $RDS_HOST -u $MASTER_USER -p'$MASTER_PASS' <<SQL
CREATE DATABASE IF NOT EXISTS $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$TENANT_USER'@'%' IDENTIFIED BY '$TENANT_PASS';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$TENANT_USER'@'%';
FLUSH PRIVILEGES;
SHOW DATABASES;
SELECT User, Host FROM mysql.user WHERE User = '$TENANT_USER';
SQL
"
    ],
    "environment": []
  }]
}
EOF

# Run ECS task
TASK_ARN=$(aws ecs run-task \
  --cluster poc-cluster \
  --task-definition poc-db-init \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-00d4d073ea29955d9],securityGroups=[sg-0dd1a87b16d7529be],assignPublicIp=DISABLED}" \
  --region af-south-1 \
  --overrides file:///tmp/create_tenant_${TENANT_ID}_db.json \
  --query 'tasks[0].taskArn' \
  --output text)

echo "Task ARN: $TASK_ARN"
echo "Waiting for database creation to complete..."
aws ecs wait tasks-stopped --cluster poc-cluster --tasks $TASK_ARN --region af-south-1

echo ""
echo "=== DATABASE CREATION RESULTS ==="
aws logs tail /ecs/poc \
  --log-stream-name-prefix "db-init/db-init/${TASK_ARN##*/}" \
  --since 2m \
  --format short \
  --region af-south-1 | grep -v "Using a password"

# Cleanup
rm -f /tmp/create_tenant_${TENANT_ID}_db.json

echo ""
echo "=== Database created successfully! ==="
echo "Database: $DB_NAME"
echo "User: $TENANT_USER"
echo "Host: $RDS_HOST"
echo ""
echo "Next steps:"
echo "1. Create Secrets Manager secret for tenant credentials"
echo "2. Create EFS access point for tenant"
echo "3. Create ECS task definition for tenant"
echo "4. Create ALB target group and listener rule"
echo "5. Create ECS service"
