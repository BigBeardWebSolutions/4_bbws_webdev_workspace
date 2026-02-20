#!/bin/bash
##############################################################################
# Database Provisioning Script for Au Pair Hive Migration
# Purpose: Create tenant database and user in DEV environment
# Usage: ./provision_database.sh aupairhive dev
##############################################################################

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Variables
TENANT_ID="${1:-aupairhive}"
ENVIRONMENT="${2:-dev}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Database Provisioning: ${TENANT_ID}${NC}"
echo -e "${GREEN}Environment: ${ENVIRONMENT}${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Set AWS profile based on environment
case "$ENVIRONMENT" in
    dev)
        AWS_PROFILE="Tebogo-dev"
        AWS_REGION="eu-west-1"
        RDS_INSTANCE="dev-mysql"
        SECRET_ID="dev-rds-master-credentials"
        ;;
    sit)
        AWS_PROFILE="Tebogo-sit"
        AWS_REGION="eu-west-1"
        RDS_INSTANCE="sit-mysql"
        SECRET_ID="sit-rds-master-credentials"
        ;;
    prod)
        AWS_PROFILE="Tebogo-prod"
        AWS_REGION="af-south-1"
        RDS_INSTANCE="prod-mysql"
        SECRET_ID="prod-rds-master-credentials"
        ;;
    *)
        echo -e "${RED}Invalid environment: $ENVIRONMENT${NC}"
        exit 1
        ;;
esac

export AWS_PROFILE
export AWS_REGION

echo "Step 1: Getting RDS endpoint..."
RDS_ENDPOINT=$(aws rds describe-db-instances \
    --db-instance-identifier "$RDS_INSTANCE" \
    --query 'DBInstances[0].Endpoint.Address' \
    --output text)
echo "✓ RDS Endpoint: $RDS_ENDPOINT"
echo ""

echo "Step 2: Getting master credentials..."
MASTER_CREDS=$(aws secretsmanager get-secret-value \
    --secret-id "$SECRET_ID" \
    --query SecretString \
    --output text)
MASTER_USER=$(echo "$MASTER_CREDS" | jq -r '.username')
MASTER_PASS=$(echo "$MASTER_CREDS" | jq -r '.password')
echo "✓ Retrieved master credentials"
echo ""

echo "Step 3: Generating tenant database password..."
TENANT_PASSWORD=$(openssl rand -base64 24 | tr -d '/+=' | head -c 32)
echo "✓ Generated secure password (32 characters)"
echo ""

# Database and user names
DB_NAME="tenant_${TENANT_ID}_db"
DB_USER="tenant_${TENANT_ID}_user"

echo "Step 4: Creating SQL script..."
cat > /tmp/provision_${TENANT_ID}.sql <<EOSQL
-- Au Pair Hive Database Provisioning
-- Tenant: ${TENANT_ID}
-- Environment: ${ENVIRONMENT}
-- Generated: ${TIMESTAMP}

-- Create database
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_520_ci;

-- Create user
CREATE USER IF NOT EXISTS '${DB_USER}'@'%'
    IDENTIFIED BY '${TENANT_PASSWORD}';

-- Grant privileges
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'%';

-- Flush privileges
FLUSH PRIVILEGES;

-- Verify
SHOW GRANTS FOR '${DB_USER}'@'%';
SELECT 'Database and user created successfully!' AS Status;
EOSQL

echo "✓ SQL script created: /tmp/provision_${TENANT_ID}.sql"
echo ""

echo "Step 5: Executing SQL on RDS..."
echo -e "${YELLOW}Note: This requires network access to RDS (VPC)${NC}"
echo ""

# Try to connect and execute
if command -v mysql &> /dev/null; then
    echo "Attempting to connect to RDS..."
    if mysql -h "$RDS_ENDPOINT" -u "$MASTER_USER" -p"$MASTER_PASS" < /tmp/provision_${TENANT_ID}.sql 2>&1; then
        echo -e "${GREEN}✓ Database provisioned successfully!${NC}"
    else
        echo -e "${RED}✗ Failed to connect to RDS directly${NC}"
        echo -e "${YELLOW}RDS is in private subnet. Use one of these methods:${NC}"
        echo ""
        echo "Method A: Run via ECS Task (recommended)"
        echo "  aws ecs run-task \\"
        echo "    --cluster ${ENVIRONMENT}-cluster \\"
        echo "    --task-definition mysql-client \\"
        echo "    --launch-type FARGATE \\"
        echo "    --network-configuration 'awsvpcConfiguration={subnets=[subnet-xxx],securityGroups=[sg-xxx]}'"
        echo ""
        echo "Method B: Copy SQL to bastion/EC2 in VPC and run:"
        echo "  mysql -h $RDS_ENDPOINT -u $MASTER_USER -p < /tmp/provision_${TENANT_ID}.sql"
        echo ""
        echo "SQL Script available at: /tmp/provision_${TENANT_ID}.sql"
    fi
else
    echo -e "${YELLOW}mysql client not found locally${NC}"
    echo "SQL script created: /tmp/provision_${TENANT_ID}.sql"
    echo ""
    echo "Execute via ECS task or bastion host in VPC"
fi

echo ""
echo "Step 6: Storing credentials in Secrets Manager..."

# Create secret
SECRET_NAME="${ENVIRONMENT}-${TENANT_ID}-db-credentials"
SECRET_VALUE=$(cat <<EOF
{
    "host": "${RDS_ENDPOINT}",
    "port": "3306",
    "username": "${DB_USER}",
    "password": "${TENANT_PASSWORD}",
    "dbname": "${DB_NAME}",
    "engine": "mysql"
}
EOF
)

aws secretsmanager create-secret \
    --name "$SECRET_NAME" \
    --description "Database credentials for ${TENANT_ID} tenant (${ENVIRONMENT})" \
    --secret-string "$SECRET_VALUE" \
    --tags Key=Environment,Value="$ENVIRONMENT" Key=Tenant,Value="$TENANT_ID" \
    2>&1 || \
aws secretsmanager update-secret \
    --secret-id "$SECRET_NAME" \
    --secret-string "$SECRET_VALUE" \
    2>&1

echo -e "${GREEN}✓ Credentials stored in: $SECRET_NAME${NC}"
echo ""

echo "========================================"
echo "Database Provisioning Summary"
echo "========================================"
echo "Tenant ID: $TENANT_ID"
echo "Environment: $ENVIRONMENT"
echo "Database Name: $DB_NAME"
echo "Database User: $DB_USER"
echo "RDS Endpoint: $RDS_ENDPOINT"
echo "Secret Name: $SECRET_NAME"
echo "SQL Script: /tmp/provision_${TENANT_ID}.sql"
echo ""
echo -e "${GREEN}✓ Provisioning script complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Verify database created: mysql -h $RDS_ENDPOINT -u $DB_USER -p $DB_NAME -e 'SELECT 1;'"
echo "2. Proceed to create EFS access point (Task 3.3)"
echo ""
