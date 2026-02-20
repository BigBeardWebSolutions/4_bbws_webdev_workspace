#!/bin/bash
#
# Export Tenant Database from DEV
#
# This script exports a tenant's database from the DEV RDS instance using mysqldump.
# The dump file is saved locally for migration to SIT.
#
# Usage: ./export_tenant_database.sh <tenant_name>
#
# Example: ./export_tenant_database.sh goldencrust
#
# Output: /tmp/tenant_migration_backups/{tenant}_dev_YYYYMMDD_HHMMSS.sql
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
AWS_PROFILE=Tebogo-dev
REGION=eu-west-1
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/tmp/tenant_migration_backups"
DUMP_FILE="${BACKUP_DIR}/${TENANT_NAME}_dev_${TIMESTAMP}.sql"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Derive database name
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

echo -e "${GREEN}=== Exporting DEV Database for Tenant: $TENANT_NAME ===${NC}"
echo "Database: $DB_NAME"
echo "Region: $REGION"
echo "Profile: $AWS_PROFILE"
echo "Output: $DUMP_FILE"
echo ""

# Get tenant database credentials from Secrets Manager
echo "Retrieving tenant database credentials..."
SECRET_NAME="dev-${TENANT_NAME}-db-credentials"

TENANT_USER=$(aws secretsmanager get-secret-value \
  --secret-id "$SECRET_NAME" \
  --region $REGION \
  --profile $AWS_PROFILE \
  --query SecretString \
  --output text 2>/dev/null | jq -r '.username' 2>/dev/null)

if [ -z "$TENANT_USER" ]; then
    echo -e "${RED}Error: Could not retrieve credentials from $SECRET_NAME${NC}"
    echo "Please ensure the secret exists in Secrets Manager"
    exit 1
fi

TENANT_PASS=$(aws secretsmanager get-secret-value \
  --secret-id "$SECRET_NAME" \
  --region $REGION \
  --profile $AWS_PROFILE \
  --query SecretString \
  --output text | jq -r '.password')

RDS_HOST=$(aws secretsmanager get-secret-value \
  --secret-id "$SECRET_NAME" \
  --region $REGION \
  --profile $AWS_PROFILE \
  --query SecretString \
  --output text | jq -r '.host')

echo "RDS Host: $RDS_HOST"
echo "Database User: $TENANT_USER"
echo ""

# Create ECS task override with mysqldump command
TEMP_FILE="/tmp/export_tenant_${TENANT_NAME}_db.json"
DUMP_TEMP="/tmp/${TENANT_NAME}_dump.sql"

cat <<EOF > "$TEMP_FILE"
{
  "containerOverrides": [{
    "name": "db-init",
    "command": [
      "sh", "-c",
      "mysqldump -h $RDS_HOST -u $TENANT_USER -p'$TENANT_PASS' --single-transaction --routines --triggers --databases $DB_NAME > $DUMP_TEMP && cat $DUMP_TEMP"
    ],
    "environment": []
  }]
}
EOF

# Get subnet and security group for DEV
echo "Retrieving VPC configuration..."
SUBNET_ID=$(aws ec2 describe-subnets \
  --region $REGION \
  --profile $AWS_PROFILE \
  --filters "Name=tag:Environment,Values=dev" "Name=tag:Name,Values=*private*" \
  --query 'Subnets[0].SubnetId' \
  --output text 2>/dev/null)

SG_ID=$(aws ec2 describe-security-groups \
  --region $REGION \
  --profile $AWS_PROFILE \
  --filters "Name=tag:Environment,Values=dev" "Name=tag:Name,Values=*ecs*" \
  --query 'SecurityGroups[0].GroupId' \
  --output text 2>/dev/null)

if [ -z "$SUBNET_ID" ] || [ "$SUBNET_ID" = "None" ]; then
    echo -e "${RED}Error: Could not find DEV private subnet${NC}"
    rm -f "$TEMP_FILE"
    exit 1
fi

if [ -z "$SG_ID" ] || [ "$SG_ID" = "None" ]; then
    echo -e "${RED}Error: Could not find DEV ECS security group${NC}"
    rm -f "$TEMP_FILE"
    exit 1
fi

echo "Subnet: $SUBNET_ID"
echo "Security Group: $SG_ID"
echo ""

# Determine cluster and task definition name
CLUSTER_NAME=$(aws ecs list-clusters \
  --region $REGION \
  --profile $AWS_PROFILE \
  --query 'clusterArns[?contains(@, `dev`)]' \
  --output text | head -1)

CLUSTER_NAME="${CLUSTER_NAME##*/}"

if [ -z "$CLUSTER_NAME" ]; then
    CLUSTER_NAME="dev-cluster"
fi

TASK_DEF=$(aws ecs list-task-definitions \
  --region $REGION \
  --profile $AWS_PROFILE \
  --family-prefix "dev-db-init" \
  --status ACTIVE \
  --query 'taskDefinitionArns[0]' \
  --output text 2>/dev/null)

if [ -z "$TASK_DEF" ] || [ "$TASK_DEF" = "None" ]; then
    TASK_DEF="dev-db-init"
else
    TASK_DEF="${TASK_DEF##*/}"
    TASK_DEF="${TASK_DEF%:*}"
fi

echo "Cluster: $CLUSTER_NAME"
echo "Task Definition: $TASK_DEF"
echo ""

# Run ECS task to export database
echo "Running ECS task to export database..."
TASK_ARN=$(aws ecs run-task \
  --cluster $CLUSTER_NAME \
  --task-definition $TASK_DEF \
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
    echo -e "${YELLOW}Note: Ensure $TASK_DEF task definition exists${NC}"
    rm -f "$TEMP_FILE"
    exit 1
fi

echo "Task ARN: $TASK_ARN"
echo "Waiting for database export to complete..."

aws ecs wait tasks-stopped \
  --cluster $CLUSTER_NAME \
  --tasks $TASK_ARN \
  --region $REGION \
  --profile $AWS_PROFILE

echo ""
echo -e "${GREEN}=== EXPORT RESULTS ===${NC}"

# Get CloudWatch log stream name
TASK_ID="${TASK_ARN##*/}"
LOG_STREAM_PREFIX="db-init/db-init/$TASK_ID"
LOG_GROUP="/ecs/poc"

# Wait for logs to propagate
sleep 5

echo "Retrieving SQL dump from CloudWatch logs..."

# Save the dump from CloudWatch logs
aws logs get-log-events \
  --log-group-name $LOG_GROUP \
  --log-stream-name $(aws logs describe-log-streams \
    --log-group-name $LOG_GROUP \
    --log-stream-name-prefix "$LOG_STREAM_PREFIX" \
    --region $REGION \
    --profile $AWS_PROFILE \
    --query 'logStreams[0].logStreamName' \
    --output text) \
  --region $REGION \
  --profile $AWS_PROFILE \
  --query 'events[].message' \
  --output text > "$DUMP_FILE.tmp" 2>/dev/null

# Filter out non-SQL content (only keep lines starting with SQL keywords or --)
grep -E '^(--|CREATE|DROP|USE|INSERT|UPDATE|DELETE|ALTER|GRANT|SET|LOCK|UNLOCK|/\*|$)' "$DUMP_FILE.tmp" > "$DUMP_FILE" || {
    echo -e "${YELLOW}Warning: Could not filter SQL content, saving raw output${NC}"
    mv "$DUMP_FILE.tmp" "$DUMP_FILE"
}

# Cleanup temp file
rm -f "$DUMP_FILE.tmp" "$TEMP_FILE"

# Verify dump file
if [ ! -f "$DUMP_FILE" ]; then
    echo -e "${RED}Error: Dump file was not created${NC}"
    exit 1
fi

DUMP_SIZE=$(wc -c < "$DUMP_FILE" | tr -d ' ')
DUMP_LINES=$(wc -l < "$DUMP_FILE" | tr -d ' ')

if [ "$DUMP_SIZE" -lt 100 ]; then
    echo -e "${RED}Error: Dump file is too small ($DUMP_SIZE bytes)${NC}"
    echo "File may be empty or invalid"
    cat "$DUMP_FILE"
    exit 1
fi

echo ""
echo -e "${GREEN}=== Export Successful! ===${NC}"
echo "Database: $DB_NAME"
echo "Output File: $DUMP_FILE"
echo "File Size: $(numfmt --to=iec-i --suffix=B $DUMP_SIZE 2>/dev/null || echo ${DUMP_SIZE} bytes)"
echo "Lines: $DUMP_LINES"
echo ""
echo "Next steps:"
echo "1. Review dump file: head -20 $DUMP_FILE"
echo "2. Import to SIT: ./utils/import_tenant_database.sh $TENANT_NAME $DUMP_FILE"
echo ""
echo -e "${GREEN}Complete!${NC}"
