#!/bin/bash
#
# Create SIT Tenant Database
#
# This script creates a tenant database and user in the SIT RDS instance,
# then stores credentials in AWS Secrets Manager.
#
# Usage: ./create_sit_tenant_database.sh <tenant_name>
#
# Example: ./create_sit_tenant_database.sh goldencrust
#
# Author: Big Beard Web Solutions
# Date: December 2024
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Input validation
if [ $# -ne 1 ]; then
    echo -e "${RED}Error: Incorrect number of arguments${NC}"
    echo "Usage: $0 <tenant_name>"
    echo ""
    echo "Examples:"
    echo "  $0 goldencrust"
    echo "  $0 tenant1"
    exit 1
fi

TENANT_NAME=$1
AWS_PROFILE=Tebogo-sit
REGION=eu-west-1

# Derive database name and user
if [ "$TENANT_NAME" = "tenant1" ]; then
    DB_NAME="tenant_1_db"
    DB_USER="tenant_1_user"
elif [ "$TENANT_NAME" = "tenant2" ]; then
    DB_NAME="tenant_2_db"
    DB_USER="tenant_2_user"
else
    DB_NAME="${TENANT_NAME}_db"
    DB_USER="${TENANT_NAME}_user"
fi

echo -e "${GREEN}=== Creating SIT Database for Tenant: $TENANT_NAME ===${NC}"
echo "Database: $DB_NAME"
echo "User: $DB_USER"
echo "Region: $REGION"
echo "Profile: $AWS_PROFILE"
echo ""

# Generate random password (24 chars, no special chars to avoid shell issues)
TENANT_PASS=$(openssl rand -base64 24 | tr -d '/+=')

# Get RDS master credentials from Secrets Manager
echo "Retrieving RDS master credentials..."
MASTER_USER=$(aws secretsmanager get-secret-value \
  --secret-id sit-rds-master-credentials \
  --region $REGION \
  --profile $AWS_PROFILE \
  --query SecretString \
  --output text | jq -r '.username' 2>/dev/null)

if [ -z "$MASTER_USER" ]; then
    echo -e "${RED}Error: Could not retrieve master username from sit-rds-master-credentials${NC}"
    echo "Please ensure the secret exists in Secrets Manager"
    exit 1
fi

MASTER_PASS=$(aws secretsmanager get-secret-value \
  --secret-id sit-rds-master-credentials \
  --region $REGION \
  --profile $AWS_PROFILE \
  --query SecretString \
  --output text | jq -r '.password')

# Get RDS host from Terraform output or AWS RDS API
echo "Retrieving RDS endpoint..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$(dirname "$SCRIPT_DIR")/../2_bbws_ecs_terraform/terraform"

if [ -d "$TERRAFORM_DIR" ]; then
    cd "$TERRAFORM_DIR"
    RDS_HOST=$(terraform output -raw rds_address 2>/dev/null || echo "")
fi

# Fallback to AWS CLI if terraform output not available
if [ -z "$RDS_HOST" ]; then
    echo -e "${YELLOW}Terraform output not available, querying RDS API...${NC}"
    RDS_HOST=$(aws rds describe-db-instances \
      --region $REGION \
      --profile $AWS_PROFILE \
      --query 'DBInstances[?contains(DBInstanceIdentifier, `sit`)].Endpoint.Address' \
      --output text | head -1)
fi

if [ -z "$RDS_HOST" ]; then
    echo -e "${RED}Error: Could not determine RDS host${NC}"
    exit 1
fi

echo "RDS Host: $RDS_HOST"
echo ""

# Create ECS task override with SQL commands
TEMP_FILE="/tmp/create_sit_tenant_${TENANT_NAME}_db.json"
cat <<EOF > "$TEMP_FILE"
{
  "containerOverrides": [{
    "name": "db-init",
    "command": [
      "sh", "-c",
      "mysql -h $RDS_HOST -u $MASTER_USER -p'$MASTER_PASS' <<SQL
CREATE DATABASE IF NOT EXISTS $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$DB_USER'@'%' IDENTIFIED BY '$TENANT_PASS';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'%';
FLUSH PRIVILEGES;
SHOW DATABASES LIKE '$DB_NAME';
SELECT User, Host FROM mysql.user WHERE User = '$DB_USER';
SQL
"
    ],
    "environment": []
  }]
}
EOF

# Get subnet and security group for SIT
echo "Retrieving VPC configuration..."
SUBNET_ID=$(aws ec2 describe-subnets \
  --region $REGION \
  --profile $AWS_PROFILE \
  --filters "Name=tag:Environment,Values=sit" "Name=tag:Name,Values=*private*" \
  --query 'Subnets[0].SubnetId' \
  --output text)

SG_ID=$(aws ec2 describe-security-groups \
  --region $REGION \
  --profile $AWS_PROFILE \
  --filters "Name=tag:Environment,Values=sit" "Name=tag:Name,Values=*ecs*" \
  --query 'SecurityGroups[0].GroupId' \
  --output text)

if [ -z "$SUBNET_ID" ] || [ "$SUBNET_ID" = "None" ]; then
    echo -e "${RED}Error: Could not find SIT private subnet${NC}"
    rm -f "$TEMP_FILE"
    exit 1
fi

if [ -z "$SG_ID" ] || [ "$SG_ID" = "None" ]; then
    echo -e "${RED}Error: Could not find SIT ECS security group${NC}"
    rm -f "$TEMP_FILE"
    exit 1
fi

echo "Subnet: $SUBNET_ID"
echo "Security Group: $SG_ID"
echo ""

# Run ECS task to create database
echo "Running ECS task to create database..."
TASK_ARN=$(aws ecs run-task \
  --cluster sit-cluster \
  --task-definition sit-db-init \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_ID],securityGroups=[$SG_ID],assignPublicIp=DISABLED}" \
  --region $REGION \
  --profile $AWS_PROFILE \
  --overrides file://"$TEMP_FILE" \
  --query 'tasks[0].taskArn' \
  --output text 2>&1)

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to run ECS task${NC}"
    echo "Error details: $TASK_ARN"
    echo ""
    echo -e "${YELLOW}Note: Ensure sit-db-init task definition exists${NC}"
    rm -f "$TEMP_FILE"
    exit 1
fi

echo "Task ARN: $TASK_ARN"
echo "Waiting for database creation to complete..."

aws ecs wait tasks-stopped \
  --cluster sit-cluster \
  --tasks $TASK_ARN \
  --region $REGION \
  --profile $AWS_PROFILE

echo ""
echo -e "${GREEN}=== DATABASE CREATION RESULTS ===${NC}"

# Get CloudWatch log stream name
TASK_ID="${TASK_ARN##*/}"
LOG_STREAM_PREFIX="db-init/db-init/$TASK_ID"

# Wait a moment for logs to propagate
sleep 5

aws logs tail /ecs/sit \
  --log-stream-name-prefix "$LOG_STREAM_PREFIX" \
  --since 5m \
  --format short \
  --region $REGION \
  --profile $AWS_PROFILE 2>/dev/null | grep -v "Using a password" || echo "Log retrieval skipped"

# Create Secrets Manager secret
echo ""
echo "Creating Secrets Manager secret..."

SECRET_NAME="sit-${TENANT_NAME}-db-credentials"
SECRET_VALUE=$(cat <<EOF
{
  "username": "$DB_USER",
  "password": "$TENANT_PASS",
  "database": "$DB_NAME",
  "host": "$RDS_HOST",
  "port": 3306
}
EOF
)

# Check if secret already exists
SECRET_EXISTS=$(aws secretsmanager describe-secret \
  --secret-id "$SECRET_NAME" \
  --region $REGION \
  --profile $AWS_PROFILE \
  --query 'Name' \
  --output text 2>/dev/null || echo "")

if [ -n "$SECRET_EXISTS" ]; then
    echo -e "${YELLOW}Secret $SECRET_NAME already exists, updating...${NC}"
    aws secretsmanager put-secret-value \
      --secret-id "$SECRET_NAME" \
      --secret-string "$SECRET_VALUE" \
      --region $REGION \
      --profile $AWS_PROFILE \
      --output text > /dev/null
else
    echo "Creating new secret: $SECRET_NAME"
    aws secretsmanager create-secret \
      --name "$SECRET_NAME" \
      --description "Database credentials for $TENANT_NAME in SIT" \
      --secret-string "$SECRET_VALUE" \
      --region $REGION \
      --profile $AWS_PROFILE \
      --tags Key=Environment,Value=sit Key=Tenant,Value=$TENANT_NAME \
      --output text > /dev/null
fi

# Cleanup
rm -f "$TEMP_FILE"

echo ""
echo -e "${GREEN}=== Database and Secret Created Successfully! ===${NC}"
echo "Database: $DB_NAME"
echo "User: $DB_USER"
echo "Host: $RDS_HOST"
echo "Secret: $SECRET_NAME"
echo ""
echo "Next steps:"
echo "1. Generate Terraform file: ./utils/generate_sit_tenant_tf.sh $TENANT_NAME <alb_priority>"
echo "2. Export DEV database: ./utils/export_tenant_database.sh $TENANT_NAME"
echo "3. Import to SIT: ./utils/import_tenant_database.sh $TENANT_NAME <dump_file>"
echo ""
echo -e "${GREEN}Complete!${NC}"
