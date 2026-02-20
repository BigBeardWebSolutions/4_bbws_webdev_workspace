#!/bin/bash
# Create tenant database, user, and Secrets Manager secret
# Usage: ./create_database.sh <tenant_name> <environment>

set -e

TENANT=$1
ENV=$2

if [[ -z "$TENANT" || -z "$ENV" ]]; then
  echo "Usage: $0 <tenant_name> <environment>"
  echo "Example: $0 myclient sit"
  exit 1
fi

# Get AWS profile and region
case $ENV in
  dev)
    PROFILE="Tebogo-dev"
    REGION="eu-west-1"
    ;;
  sit)
    PROFILE="Tebogo-sit"
    REGION="eu-west-1"
    ;;
  prod)
    PROFILE="Tebogo-prod"
    REGION="af-south-1"
    ;;
  *)
    echo "Error: Invalid environment '$ENV'. Must be dev, sit, or prod."
    exit 1
    ;;
esac

echo "========================================="
echo "Creating database for ${TENANT} in ${ENV}"
echo "========================================="

# Step 1: Generate strong password
echo ""
echo "[1/6] Generating database password..."
PASSWORD=$(openssl rand -base64 18 | tr -d '/+=' | cut -c1-24)
echo "Password generated (24 characters)"
echo "$PASSWORD" > /tmp/${TENANT}_${ENV}_password.txt
echo "Saved to: /tmp/${TENANT}_${ENV}_password.txt"

# Step 2: Get RDS endpoint
echo ""
echo "[2/6] Getting RDS endpoint..."
RDS_ENDPOINT=$(aws rds describe-db-instances \
  --db-instance-identifier ${ENV}-mysql \
  --region $REGION \
  --profile $PROFILE \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text)

if [[ -z "$RDS_ENDPOINT" ]]; then
  echo "Error: Could not find RDS instance ${ENV}-mysql"
  exit 1
fi

echo "RDS Endpoint: $RDS_ENDPOINT"

# Step 3: Create Secrets Manager secret
echo ""
echo "[3/6] Creating Secrets Manager secret..."
SECRET_NAME="${ENV}-${TENANT}-db-credentials"

aws secretsmanager create-secret \
  --name $SECRET_NAME \
  --description "Database credentials for ${TENANT} in ${ENV}" \
  --secret-string "{\"username\":\"${TENANT}_user\",\"password\":\"$PASSWORD\",\"database\":\"${TENANT}_db\",\"host\":\"$RDS_ENDPOINT\",\"port\":3306}" \
  --region $REGION \
  --profile $PROFILE \
  --tags Key=Environment,Value=${ENV} Key=Tenant,Value=${TENANT} \
  > /dev/null

SECRET_ARN=$(aws secretsmanager describe-secret \
  --secret-id $SECRET_NAME \
  --region $REGION \
  --profile $PROFILE \
  --query 'ARN' \
  --output text)

echo "✅ Secret created: $SECRET_ARN"
echo "   Secret name: $SECRET_NAME"

# Step 4: Get RDS master credentials
echo ""
echo "[4/6] Retrieving RDS master credentials..."
MASTER_SECRET="${ENV}-rds-master-credentials"
MASTER_CREDS=$(aws secretsmanager get-secret-value \
  --secret-id $MASTER_SECRET \
  --region $REGION \
  --profile $PROFILE \
  --query 'SecretString' \
  --output text)

MASTER_USER=$(echo $MASTER_CREDS | jq -r '.username')
MASTER_PASS=$(echo $MASTER_CREDS | jq -r '.password')

if [[ -z "$MASTER_USER" || -z "$MASTER_PASS" ]]; then
  echo "Error: Could not retrieve RDS master credentials from $MASTER_SECRET"
  exit 1
fi

echo "Master user: $MASTER_USER"

# Step 5: Create task override JSON for database creation
echo ""
echo "[5/6] Creating database via ECS task..."

cat > /tmp/create_${TENANT}_${ENV}_db.json <<EOF
{
  "containerOverrides": [{
    "name": "mysql-client",
    "command": [
      "sh",
      "-c",
      "mysql -h ${RDS_ENDPOINT} -u ${MASTER_USER} -p${MASTER_PASS} <<'SQL'
CREATE DATABASE IF NOT EXISTS ${TENANT}_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${TENANT}_user'@'%' IDENTIFIED BY '${PASSWORD}';
GRANT ALL PRIVILEGES ON ${TENANT}_db.* TO '${TENANT}_user'@'%';
FLUSH PRIVILEGES;
SELECT '✅ Database ${TENANT}_db created successfully' AS status;
SELECT '✅ User ${TENANT}_user created successfully' AS status;
SHOW DATABASES LIKE '${TENANT}%';
SQL
"
    ]
  }]
}
EOF

# Get network configuration
SUBNET=$(aws ec2 describe-subnets \
  --filters "Name=tag:Name,Values=${ENV}-private-subnet-1" \
  --region $REGION \
  --profile $PROFILE \
  --query 'Subnets[0].SubnetId' \
  --output text)

SG=$(aws ec2 describe-security-groups \
  --filters "Name=tag:Name,Values=${ENV}-ecs-tasks-sg" \
  --region $REGION \
  --profile $PROFILE \
  --query 'SecurityGroups[0].GroupId' \
  --output text)

if [[ -z "$SUBNET" || -z "$SG" ]]; then
  echo "Error: Could not find subnet or security group"
  echo "Subnet: $SUBNET"
  echo "Security Group: $SG"
  exit 1
fi

# Run database creation task
TASK_ARN=$(aws ecs run-task \
  --cluster ${ENV}-cluster \
  --task-definition ${ENV}-generic-db-init:1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$SUBNET],securityGroups=[$SG],assignPublicIp=DISABLED}" \
  --region $REGION \
  --profile $PROFILE \
  --overrides file:///tmp/create_${TENANT}_${ENV}_db.json \
  --query 'tasks[0].taskArn' \
  --output text)

if [[ -z "$TASK_ARN" ]]; then
  echo "Error: Failed to start database creation task"
  exit 1
fi

TASK_ID=$(echo $TASK_ARN | awk -F'/' '{print $NF}')
echo "Database creation task started: $TASK_ID"

# Wait for task to complete
echo "Waiting for task to complete (max 2 minutes)..."
aws ecs wait tasks-stopped \
  --cluster ${ENV}-cluster \
  --tasks $TASK_ARN \
  --region $REGION \
  --profile $PROFILE \
  || echo "Warning: Task may still be running"

# Step 6: Check task execution results
echo ""
echo "[6/6] Verifying database creation..."
sleep 5  # Give logs time to propagate

aws logs get-log-events \
  --log-group-name /ecs/${ENV} \
  --log-stream-name "db-init/mysql-client/${TASK_ID}" \
  --region $REGION \
  --profile $PROFILE \
  --query 'events[*].message' \
  --output text 2>/dev/null || echo "Note: Logs may not be available yet. Check CloudWatch manually if needed."

# Summary
echo ""
echo "========================================="
echo "✅ Database setup complete!"
echo "========================================="
echo "Tenant: ${TENANT}"
echo "Database: ${TENANT}_db"
echo "User: ${TENANT}_user"
echo "Secret: $SECRET_NAME"
echo "Secret ARN: $SECRET_ARN"
echo "Password file: /tmp/${TENANT}_${ENV}_password.txt"
echo ""
echo "Next steps:"
echo "  1. Create IAM policy: ./create_iam_policy.sh ${TENANT} ${ENV}"
echo "  2. Deploy Terraform: cd ../2_bbws_ecs_terraform/terraform && terraform apply"
echo "========================================="

# Save summary to file
cat > /tmp/${TENANT}_${ENV}_db_summary.txt <<SUMMARY
Database Creation Summary
=========================
Tenant: ${TENANT}
Environment: ${ENV}
Date: $(date)

Database Details:
  Database: ${TENANT}_db
  User: ${TENANT}_user
  Host: $RDS_ENDPOINT
  Port: 3306

AWS Resources:
  Secret Name: $SECRET_NAME
  Secret ARN: $SECRET_ARN
  Task ARN: $TASK_ARN

Files Created:
  Password: /tmp/${TENANT}_${ENV}_password.txt
  This summary: /tmp/${TENANT}_${ENV}_db_summary.txt

Next Steps:
  1. Create IAM policy for secret access
  2. Deploy Terraform configuration
  3. Verify ECS service deployment
SUMMARY

echo "Summary saved to: /tmp/${TENANT}_${ENV}_db_summary.txt"
