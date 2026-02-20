#!/bin/bash
# Get database credentials for a specific tenant
# Usage: ./get_tenant_credentials.sh <tenant_id>
# Example: ./get_tenant_credentials.sh 1

set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <tenant_id>"
  echo "Example: $0 1"
  exit 1
fi

TENANT_ID=$1
export AWS_PROFILE=Tebogo-dev

echo "=== TENANT $TENANT_ID DATABASE CREDENTIALS ==="
aws secretsmanager get-secret-value \
  --secret-id "poc-tenant-${TENANT_ID}-db-credentials" \
  --region af-south-1 \
  --query SecretString \
  --output text | jq

echo ""
echo "=== CONNECTION STRING ==="
USERNAME=$(aws secretsmanager get-secret-value \
  --secret-id "poc-tenant-${TENANT_ID}-db-credentials" \
  --region af-south-1 \
  --query SecretString \
  --output text | jq -r '.username')

PASSWORD=$(aws secretsmanager get-secret-value \
  --secret-id "poc-tenant-${TENANT_ID}-db-credentials" \
  --region af-south-1 \
  --query SecretString \
  --output text | jq -r '.password')

DATABASE=$(aws secretsmanager get-secret-value \
  --secret-id "poc-tenant-${TENANT_ID}-db-credentials" \
  --region af-south-1 \
  --query SecretString \
  --output text | jq -r '.database')

HOST=$(aws secretsmanager get-secret-value \
  --secret-id "poc-tenant-${TENANT_ID}-db-credentials" \
  --region af-south-1 \
  --query SecretString \
  --output text | jq -r '.host')

echo "mysql -h $HOST -u $USERNAME -p'$PASSWORD' $DATABASE"
