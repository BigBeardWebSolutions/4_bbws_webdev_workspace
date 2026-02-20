#!/bin/bash
#
# Import Tenant Database to SIT
#
# This script imports a tenant database dump to the SIT RDS instance,
# performing URL replacements (wpdev.kimmyai.io → wpsit.kimmyai.io).
#
# Usage: ./import_tenant_database.sh <tenant_name> <dump_file>
#
# Example: ./import_tenant_database.sh goldencrust /tmp/tenant_migration_backups/goldencrust_dev_20241221_120000.sql
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
if [ $# -ne 2 ]; then
    echo -e "${RED}Error: Incorrect number of arguments${NC}"
    echo "Usage: $0 <tenant_name> <dump_file>"
    echo ""
    echo "Examples:"
    echo "  $0 goldencrust /tmp/tenant_migration_backups/goldencrust_dev_20241221_120000.sql"
    echo "  $0 tenant1 /tmp/tenant_migration_backups/tenant1_dev_20241221_120000.sql"
    exit 1
fi

TENANT_NAME=$1
DUMP_FILE=$2
AWS_PROFILE=Tebogo-sit
REGION=eu-west-1

# Validate dump file exists
if [ ! -f "$DUMP_FILE" ]; then
    echo -e "${RED}Error: Dump file not found: $DUMP_FILE${NC}"
    exit 1
fi

# Derive database name
if [ "$TENANT_NAME" = "tenant1" ]; then
    DB_NAME="tenant_1_db"
    DB_USER="tenant_1_user"
    SEARCH_DOMAIN="tenant1.wpdev.kimmyai.io"
    REPLACE_DOMAIN="tenant1.wpsit.kimmyai.io"
elif [ "$TENANT_NAME" = "tenant2" ]; then
    DB_NAME="tenant_2_db"
    DB_USER="tenant_2_user"
    SEARCH_DOMAIN="tenant2.wpdev.kimmyai.io"
    REPLACE_DOMAIN="tenant2.wpsit.kimmyai.io"
else
    DB_NAME="${TENANT_NAME}_db"
    DB_USER="${TENANT_NAME}_user"
    SEARCH_DOMAIN="${TENANT_NAME}.wpdev.kimmyai.io"
    REPLACE_DOMAIN="${TENANT_NAME}.wpsit.kimmyai.io"
fi

DUMP_SIZE=$(wc -c < "$DUMP_FILE" | tr -d ' ')
DUMP_LINES=$(wc -l < "$DUMP_FILE" | tr -d ' ')

echo -e "${GREEN}=== Importing Database to SIT for Tenant: $TENANT_NAME ===${NC}"
echo "Database: $DB_NAME"
echo "Dump File: $DUMP_FILE"
echo "File Size: $(numfmt --to=iec-i --suffix=B $DUMP_SIZE 2>/dev/null || echo ${DUMP_SIZE} bytes)"
echo "Lines: $DUMP_LINES"
echo "Region: $REGION"
echo "Profile: $AWS_PROFILE"
echo ""
echo "URL Replacement:"
echo "  From: https://$SEARCH_DOMAIN"
echo "  To:   https://$REPLACE_DOMAIN"
echo ""

# Create modified dump file with URL replacements
MODIFIED_DUMP="/tmp/${TENANT_NAME}_sit_import_$(date +%Y%m%d_%H%M%S).sql"
echo "Creating modified dump with URL replacements..."

# Perform URL replacements
sed -e "s|https://${SEARCH_DOMAIN}|https://${REPLACE_DOMAIN}|g" \
    -e "s|http://${SEARCH_DOMAIN}|https://${REPLACE_DOMAIN}|g" \
    -e "s|${SEARCH_DOMAIN}|${REPLACE_DOMAIN}|g" \
    "$DUMP_FILE" > "$MODIFIED_DUMP"

# Verify modified dump
MODIFIED_SIZE=$(wc -c < "$MODIFIED_DUMP" | tr -d ' ')
if [ "$MODIFIED_SIZE" -lt 100 ]; then
    echo -e "${RED}Error: Modified dump file is too small${NC}"
    rm -f "$MODIFIED_DUMP"
    exit 1
fi

# Count replacements made
REPLACEMENT_COUNT=$(grep -c "$REPLACE_DOMAIN" "$MODIFIED_DUMP" || echo "0")
echo "URL replacements made: $REPLACEMENT_COUNT occurrences"
echo ""

# Get SIT tenant credentials from Secrets Manager
echo "Retrieving SIT tenant database credentials..."
SECRET_NAME="sit-${TENANT_NAME}-db-credentials"

TENANT_PASS=$(aws secretsmanager get-secret-value \
  --secret-id "$SECRET_NAME" \
  --region $REGION \
  --profile $AWS_PROFILE \
  --query SecretString \
  --output text 2>/dev/null | jq -r '.password' 2>/dev/null)

if [ -z "$TENANT_PASS" ]; then
    echo -e "${RED}Error: Could not retrieve credentials from $SECRET_NAME${NC}"
    echo "Please ensure the secret exists (run create_sit_tenant_database.sh first)"
    rm -f "$MODIFIED_DUMP"
    exit 1
fi

RDS_HOST=$(aws secretsmanager get-secret-value \
  --secret-id "$SECRET_NAME" \
  --region $REGION \
  --profile $AWS_PROFILE \
  --query SecretString \
  --output text | jq -r '.host')

echo "RDS Host: $RDS_HOST"
echo "Database User: $DB_USER"
echo ""

# Upload modified dump to S3 for ECS task to access
S3_BUCKET="bbws-terraform-state-sit"
S3_KEY="migrations/${TENANT_NAME}_import_$(date +%Y%m%d_%H%M%S).sql"

echo "Uploading dump to S3..."
aws s3 cp "$MODIFIED_DUMP" "s3://${S3_BUCKET}/${S3_KEY}" \
  --region $REGION \
  --profile $AWS_PROFILE \
  --no-progress

echo "S3 Location: s3://${S3_BUCKET}/${S3_KEY}"
echo ""

# Create ECS task override with import commands
TEMP_FILE="/tmp/import_tenant_${TENANT_NAME}_db.json"
cat <<EOF > "$TEMP_FILE"
{
  "containerOverrides": [{
    "name": "db-init",
    "command": [
      "sh", "-c",
      "aws s3 cp s3://${S3_BUCKET}/${S3_KEY} /tmp/import.sql --region $REGION && mysql -h $RDS_HOST -u $DB_USER -p'$TENANT_PASS' $DB_NAME < /tmp/import.sql && mysql -h $RDS_HOST -u $DB_USER -p'$TENANT_PASS' $DB_NAME -e 'SELECT COUNT(*) as table_count FROM information_schema.tables WHERE table_schema=\"$DB_NAME\"; SELECT table_name, table_rows FROM information_schema.tables WHERE table_schema=\"$DB_NAME\" ORDER BY table_name;'"
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
    rm -f "$TEMP_FILE" "$MODIFIED_DUMP"
    exit 1
fi

if [ -z "$SG_ID" ] || [ "$SG_ID" = "None" ]; then
    echo -e "${RED}Error: Could not find SIT ECS security group${NC}"
    rm -f "$TEMP_FILE" "$MODIFIED_DUMP"
    exit 1
fi

echo "Subnet: $SUBNET_ID"
echo "Security Group: $SG_ID"
echo ""

# Run ECS task to import database
echo "Running ECS task to import database..."
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
    echo -e "${YELLOW}Note: Ensure sit-db-init task definition exists and has S3 read permissions${NC}"
    rm -f "$TEMP_FILE" "$MODIFIED_DUMP"
    exit 1
fi

echo "Task ARN: $TASK_ARN"
echo "Waiting for database import to complete (this may take several minutes)..."

aws ecs wait tasks-stopped \
  --cluster sit-cluster \
  --tasks $TASK_ARN \
  --region $REGION \
  --profile $AWS_PROFILE

echo ""
echo -e "${GREEN}=== IMPORT RESULTS ===${NC}"

# Get CloudWatch log stream name
TASK_ID="${TASK_ARN##*/}"
LOG_STREAM_PREFIX="db-init/db-init/$TASK_ID"

# Wait for logs to propagate
sleep 5

aws logs tail /ecs/sit \
  --log-stream-name-prefix "$LOG_STREAM_PREFIX" \
  --since 10m \
  --format short \
  --region $REGION \
  --profile $AWS_PROFILE 2>/dev/null | grep -v "Using a password" || echo "Log retrieval skipped"

# Cleanup
rm -f "$TEMP_FILE" "$MODIFIED_DUMP"

# Delete S3 dump file (optional - comment out to keep for troubleshooting)
echo ""
echo "Cleaning up S3 dump file..."
aws s3 rm "s3://${S3_BUCKET}/${S3_KEY}" \
  --region $REGION \
  --profile $AWS_PROFILE \
  --no-progress 2>/dev/null || echo "S3 cleanup skipped"

echo ""
echo -e "${GREEN}=== Import Complete! ===${NC}"
echo "Database: $DB_NAME"
echo "Host: $RDS_HOST"
echo "URL Replacements: $REPLACEMENT_COUNT occurrences"
echo ""
echo "Validation:"
echo "  Check table count and row counts in logs above"
echo "  Verify URLs updated correctly"
echo ""
echo "Next steps:"
echo "1. Validate migration: ./utils/validate_tenant_migration.sh $TENANT_NAME"
echo "2. Migrate wp-content files: ./utils/migrate_tenant_wpcontent.sh $TENANT_NAME"
echo ""
echo -e "${GREEN}Complete!${NC}"
