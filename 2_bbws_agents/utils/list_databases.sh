#!/bin/bash
# List all databases in RDS instance
# Usage: ./list_databases.sh

set -e

export AWS_PROFILE=Tebogo-dev
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/../terraform"

echo "=== Fetching RDS Credentials ==="
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
echo "Creating ECS task to query databases..."

# Create task override
cat <<EOF > /tmp/list_databases.json
{
  "containerOverrides": [{
    "name": "db-init",
    "command": ["sh", "-c", "echo '=== ALL DATABASES ===' && mysql -h $RDS_HOST -u $MASTER_USER -p'$MASTER_PASS' -e 'SHOW DATABASES;' && echo '' && echo '=== TENANT USERS ===' && mysql -h $RDS_HOST -u $MASTER_USER -p'$MASTER_PASS' -e \"SELECT User, Host FROM mysql.user WHERE User LIKE 'tenant_%';\" && echo '' && echo '=== DATABASE SIZES ===' && mysql -h $RDS_HOST -u $MASTER_USER -p'$MASTER_PASS' -e \"SELECT table_schema AS 'Database', ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)' FROM information_schema.tables WHERE table_schema LIKE 'tenant_%' GROUP BY table_schema;\""],
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
  --overrides file:///tmp/list_databases.json \
  --query 'tasks[0].taskArn' \
  --output text)

echo "Task ARN: $TASK_ARN"
echo "Waiting for query to complete..."
aws ecs wait tasks-stopped --cluster poc-cluster --tasks $TASK_ARN --region af-south-1

echo ""
echo "=== DATABASE REPORT ==="
aws logs tail /ecs/poc \
  --log-stream-name-prefix "db-init/db-init/${TASK_ARN##*/}" \
  --since 2m \
  --format short \
  --region af-south-1 | grep -v "Using a password"

# Cleanup
rm -f /tmp/list_databases.json
