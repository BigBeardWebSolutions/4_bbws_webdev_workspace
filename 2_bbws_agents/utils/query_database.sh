#!/bin/bash
# Execute arbitrary SQL query on RDS via ECS task
# Usage: ./query_database.sh "<SQL_QUERY>"
# Example: ./query_database.sh "SELECT * FROM tenant_1_db.wp_posts LIMIT 5;"

set -e

if [ -z "$1" ]; then
  echo "Usage: $0 \"<SQL_QUERY>\""
  echo "Example: $0 \"SHOW DATABASES;\""
  exit 1
fi

SQL_QUERY=$1
export AWS_PROFILE=Tebogo-dev
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/../terraform"

echo "=== Executing SQL Query ==="
echo "Query: $SQL_QUERY"
echo ""

cd "$TERRAFORM_DIR"

# Get RDS master credentials
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

# Create task override
cat <<EOF > /tmp/query_db.json
{
  "containerOverrides": [{
    "name": "db-init",
    "command": ["sh", "-c", "mysql -h $RDS_HOST -u $MASTER_USER -p'$MASTER_PASS' -e \"$SQL_QUERY\""],
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
  --overrides file:///tmp/query_db.json \
  --query 'tasks[0].taskArn' \
  --output text)

echo "Task ARN: $TASK_ARN"
echo "Executing query..."
aws ecs wait tasks-stopped --cluster poc-cluster --tasks $TASK_ARN --region af-south-1

echo ""
echo "=== QUERY RESULTS ==="
aws logs tail /ecs/poc \
  --log-stream-name-prefix "db-init/db-init/${TASK_ARN##*/}" \
  --since 2m \
  --format short \
  --region af-south-1 | grep -v "Using a password"

# Cleanup
rm -f /tmp/query_db.json
