#!/bin/bash
#
# Migrate Tenant wp-content from DEV to SIT
#
# This script migrates a tenant's wp-content files from DEV EFS to SIT EFS
# using S3 as an intermediary storage layer.
#
# Process:
# 1. Sync DEV EFS → S3 (DEV account)
# 2. Copy S3 DEV → S3 SIT (cross-account)
# 3. Sync S3 → SIT EFS (SIT account)
#
# Usage: ./migrate_tenant_wpcontent.sh <tenant_name>
#
# Example: ./migrate_tenant_wpcontent.sh goldencrust
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
DEV_PROFILE=Tebogo-dev
SIT_PROFILE=Tebogo-sit
DEV_REGION=eu-west-1
SIT_REGION=eu-west-1
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# S3 buckets
DEV_BUCKET="bbws-terraform-state-dev"
SIT_BUCKET="bbws-terraform-state-sit"
S3_PREFIX="wpcontent-migration/${TENANT_NAME}_${TIMESTAMP}"

# Derive tenant directory path
if [ "$TENANT_NAME" = "tenant1" ]; then
    TENANT_DIR="tenant-1"
elif [ "$TENANT_NAME" = "tenant2" ]; then
    TENANT_DIR="tenant-2"
else
    TENANT_DIR="$TENANT_NAME"
fi

echo -e "${GREEN}=== Migrating wp-content for Tenant: $TENANT_NAME ===${NC}"
echo "Tenant Directory: /$TENANT_DIR"
echo "DEV Region: $DEV_REGION"
echo "SIT Region: $SIT_REGION"
echo "Migration Path: DEV EFS → S3 DEV → S3 SIT → SIT EFS"
echo ""

# =============================================================================
# STEP 1: Sync DEV EFS to S3 (DEV account)
# =============================================================================
echo -e "${YELLOW}Step 1: Syncing DEV EFS to S3...${NC}"

# Get DEV EFS file system ID
DEV_EFS_ID=$(aws efs describe-file-systems \
  --region $DEV_REGION \
  --profile $DEV_PROFILE \
  --query 'FileSystems[?contains(Name, `poc`) || contains(Tags[?Key==`Environment`].Value, `dev`)].FileSystemId' \
  --output text | head -1)

if [ -z "$DEV_EFS_ID" ]; then
    echo -e "${RED}Error: Could not find DEV EFS file system${NC}"
    exit 1
fi

echo "DEV EFS ID: $DEV_EFS_ID"

# Get DEV EFS access point for tenant
DEV_AP_ID=$(aws efs describe-access-points \
  --region $DEV_REGION \
  --profile $DEV_PROFILE \
  --file-system-id $DEV_EFS_ID \
  --query "AccessPoints[?RootDirectory.Path=='/${TENANT_DIR}'].AccessPointId" \
  --output text)

if [ -z "$DEV_AP_ID" ]; then
    echo -e "${RED}Error: Could not find DEV EFS access point for /${TENANT_DIR}${NC}"
    exit 1
fi

echo "DEV Access Point: $DEV_AP_ID"

# Create DataSync task or use ECS task with aws s3 sync
# For simplicity, we'll use an ECS task approach

# Get DEV VPC configuration
DEV_SUBNET=$(aws ec2 describe-subnets \
  --region $DEV_REGION \
  --profile $DEV_PROFILE \
  --filters "Name=tag:Environment,Values=dev" "Name=tag:Name,Values=*private*" \
  --query 'Subnets[0].SubnetId' \
  --output text 2>/dev/null)

if [ -z "$DEV_SUBNET" ] || [ "$DEV_SUBNET" = "None" ]; then
    DEV_SUBNET=$(aws ec2 describe-subnets \
      --region $DEV_REGION \
      --profile $DEV_PROFILE \
      --filters "Name=tag:Name,Values=*poc*private*" \
      --query 'Subnets[0].SubnetId' \
      --output text 2>/dev/null)
fi

DEV_SG=$(aws ec2 describe-security-groups \
  --region $DEV_REGION \
  --profile $DEV_PROFILE \
  --filters "Name=tag:Environment,Values=dev" "Name=tag:Name,Values=*ecs*" \
  --query 'SecurityGroups[0].GroupId' \
  --output text 2>/dev/null)

if [ -z "$DEV_SG" ] || [ "$DEV_SG" = "None" ]; then
    DEV_SG=$(aws ec2 describe-security-groups \
      --region $DEV_REGION \
      --profile $DEV_PROFILE \
      --filters "Name=tag:Name,Values=*poc*ecs*" \
      --query 'SecurityGroups[0].GroupId' \
      --output text 2>/dev/null)
fi

echo "DEV Subnet: $DEV_SUBNET"
echo "DEV Security Group: $DEV_SG"
echo ""

# Create ECS task to sync EFS to S3
echo "Creating EFS to S3 sync task definition..."

SYNC_TASK_FILE="/tmp/sync_efs_s3_${TENANT_NAME}.json"
cat <<EOF > "$SYNC_TASK_FILE"
{
  "containerOverrides": [{
    "name": "wordpress",
    "command": [
      "sh", "-c",
      "echo 'Starting EFS to S3 sync...' && ls -la /var/www/html/wp-content/ && aws s3 sync /var/www/html/wp-content/ s3://${DEV_BUCKET}/${S3_PREFIX}/ --region $DEV_REGION --delete && echo 'Sync complete!' && aws s3 ls s3://${DEV_BUCKET}/${S3_PREFIX}/ --recursive --region $DEV_REGION | wc -l"
    ],
    "environment": []
  }]
}
EOF

# Determine DEV cluster and task definition
DEV_CLUSTER=$(aws ecs list-clusters \
  --region $DEV_REGION \
  --profile $DEV_PROFILE \
  --query 'clusterArns[?contains(@, `poc`) || contains(@, `dev`)]' \
  --output text | head -1)

DEV_CLUSTER="${DEV_CLUSTER##*/}"

if [ -z "$DEV_CLUSTER" ]; then
    DEV_CLUSTER="poc-cluster"
fi

# Use existing tenant task definition (it has EFS mount)
DEV_TASK_DEF=$(aws ecs list-task-definitions \
  --region $DEV_REGION \
  --profile $DEV_PROFILE \
  --family-prefix "${TENANT_NAME}" \
  --status ACTIVE \
  --query 'taskDefinitionArns[0]' \
  --output text 2>/dev/null)

if [ -z "$DEV_TASK_DEF" ] || [ "$DEV_TASK_DEF" = "None" ]; then
    # Fallback to dev-tenant task pattern
    DEV_TASK_DEF=$(aws ecs list-task-definitions \
      --region $DEV_REGION \
      --profile $DEV_PROFILE \
      --family-prefix "dev-${TENANT_NAME}" \
      --status ACTIVE \
      --query 'taskDefinitionArns[0]' \
      --output text 2>/dev/null)
fi

if [ -z "$DEV_TASK_DEF" ] || [ "$DEV_TASK_DEF" = "None" ]; then
    echo -e "${YELLOW}Warning: Could not find tenant task definition, using poc-tenant-1 as template${NC}"
    DEV_TASK_DEF="poc-tenant-1"
else
    DEV_TASK_DEF="${DEV_TASK_DEF##*/}"
    DEV_TASK_DEF="${DEV_TASK_DEF%:*}"
fi

echo "DEV Cluster: $DEV_CLUSTER"
echo "DEV Task Definition: $DEV_TASK_DEF"
echo ""

echo "Running ECS task to sync DEV EFS to S3..."
DEV_TASK_ARN=$(aws ecs run-task \
  --cluster $DEV_CLUSTER \
  --task-definition $DEV_TASK_DEF \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$DEV_SUBNET],securityGroups=[$DEV_SG],assignPublicIp=DISABLED}" \
  --region $DEV_REGION \
  --profile $DEV_PROFILE \
  --overrides file://"$SYNC_TASK_FILE" \
  --query 'tasks[0].taskArn' \
  --output text 2>&1)

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to run DEV sync task${NC}"
    echo "Error details: $DEV_TASK_ARN"
    rm -f "$SYNC_TASK_FILE"
    exit 1
fi

echo "DEV Task ARN: $DEV_TASK_ARN"
echo "Waiting for DEV EFS to S3 sync to complete..."

aws ecs wait tasks-stopped \
  --cluster $DEV_CLUSTER \
  --tasks $DEV_TASK_ARN \
  --region $DEV_REGION \
  --profile $DEV_PROFILE

echo -e "${GREEN}✓ DEV EFS synced to S3${NC}"
echo ""

# =============================================================================
# STEP 2: Copy S3 from DEV to SIT
# =============================================================================
echo -e "${YELLOW}Step 2: Copying S3 from DEV to SIT...${NC}"

# Count files in DEV S3
FILE_COUNT=$(aws s3 ls s3://${DEV_BUCKET}/${S3_PREFIX}/ --recursive \
  --region $DEV_REGION \
  --profile $DEV_PROFILE | wc -l)

echo "Files in DEV S3: $FILE_COUNT"

if [ "$FILE_COUNT" -eq 0 ]; then
    echo -e "${YELLOW}Warning: No files found in DEV S3. wp-content may be empty.${NC}"
fi

# Sync from DEV S3 to SIT S3
echo "Syncing S3 DEV → SIT..."
aws s3 sync s3://${DEV_BUCKET}/${S3_PREFIX}/ s3://${SIT_BUCKET}/${S3_PREFIX}/ \
  --source-region $DEV_REGION \
  --region $SIT_REGION \
  --profile $DEV_PROFILE

# Verify in SIT
SIT_FILE_COUNT=$(aws s3 ls s3://${SIT_BUCKET}/${S3_PREFIX}/ --recursive \
  --region $SIT_REGION \
  --profile $SIT_PROFILE | wc -l)

echo "Files in SIT S3: $SIT_FILE_COUNT"

if [ "$SIT_FILE_COUNT" -ne "$FILE_COUNT" ]; then
    echo -e "${YELLOW}Warning: File count mismatch (DEV: $FILE_COUNT, SIT: $SIT_FILE_COUNT)${NC}"
fi

echo -e "${GREEN}✓ Files copied to SIT S3${NC}"
echo ""

# =============================================================================
# STEP 3: Sync S3 to SIT EFS
# =============================================================================
echo -e "${YELLOW}Step 3: Syncing S3 to SIT EFS...${NC}"

# Get SIT EFS configuration
SIT_EFS_ID=$(aws efs describe-file-systems \
  --region $SIT_REGION \
  --profile $SIT_PROFILE \
  --query 'FileSystems[?contains(Tags[?Key==`Environment`].Value, `sit`)].FileSystemId' \
  --output text | head -1)

if [ -z "$SIT_EFS_ID" ]; then
    echo -e "${RED}Error: Could not find SIT EFS file system${NC}"
    exit 1
fi

echo "SIT EFS ID: $SIT_EFS_ID"

# Get SIT VPC configuration
SIT_SUBNET=$(aws ec2 describe-subnets \
  --region $SIT_REGION \
  --profile $SIT_PROFILE \
  --filters "Name=tag:Environment,Values=sit" "Name=tag:Name,Values=*private*" \
  --query 'Subnets[0].SubnetId' \
  --output text)

SIT_SG=$(aws ec2 describe-security-groups \
  --region $SIT_REGION \
  --profile $SIT_PROFILE \
  --filters "Name=tag:Environment,Values=sit" "Name=tag:Name,Values=*ecs*" \
  --query 'SecurityGroups[0].GroupId' \
  --output text)

echo "SIT Subnet: $SIT_SUBNET"
echo "SIT Security Group: $SIT_SG"
echo ""

# Create ECS task to sync S3 to EFS
SYNC_SIT_TASK_FILE="/tmp/sync_s3_efs_sit_${TENANT_NAME}.json"
cat <<EOF > "$SYNC_SIT_TASK_FILE"
{
  "containerOverrides": [{
    "name": "wordpress",
    "command": [
      "sh", "-c",
      "echo 'Starting S3 to EFS sync...' && mkdir -p /var/www/html/wp-content && aws s3 sync s3://${SIT_BUCKET}/${S3_PREFIX}/ /var/www/html/wp-content/ --region $SIT_REGION --delete && chown -R www-data:www-data /var/www/html/wp-content && chmod -R 755 /var/www/html/wp-content && echo 'Sync complete!' && ls -la /var/www/html/wp-content/"
    ],
    "environment": []
  }]
}
EOF

# Find SIT tenant task definition
SIT_CLUSTER="sit-cluster"
SIT_TASK_DEF=$(aws ecs list-task-definitions \
  --region $SIT_REGION \
  --profile $SIT_PROFILE \
  --family-prefix "sit-${TENANT_NAME}" \
  --status ACTIVE \
  --query 'taskDefinitionArns[0]' \
  --output text 2>/dev/null)

if [ -z "$SIT_TASK_DEF" ] || [ "$SIT_TASK_DEF" = "None" ]; then
    echo -e "${YELLOW}Note: SIT task definition sit-${TENANT_NAME} not found${NC}"
    echo "This is expected if infrastructure hasn't been deployed yet"
    echo "Skipping S3 to SIT EFS sync - run this script again after Terraform deployment"
    echo ""
    echo -e "${GREEN}Files are ready in S3: s3://${SIT_BUCKET}/${S3_PREFIX}/${NC}"
    rm -f "$SYNC_TASK_FILE" "$SYNC_SIT_TASK_FILE"
    exit 0
else
    SIT_TASK_DEF="${SIT_TASK_DEF##*/}"
    SIT_TASK_DEF="${SIT_TASK_DEF%:*}"
fi

echo "SIT Cluster: $SIT_CLUSTER"
echo "SIT Task Definition: $SIT_TASK_DEF"
echo ""

echo "Running ECS task to sync S3 to SIT EFS..."
SIT_TASK_ARN=$(aws ecs run-task \
  --cluster $SIT_CLUSTER \
  --task-definition $SIT_TASK_DEF \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$SIT_SUBNET],securityGroups=[$SIT_SG],assignPublicIp=DISABLED}" \
  --region $SIT_REGION \
  --profile $SIT_PROFILE \
  --overrides file://"$SYNC_SIT_TASK_FILE" \
  --query 'tasks[0].taskArn' \
  --output text 2>&1)

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to run SIT sync task${NC}"
    echo "Error details: $SIT_TASK_ARN"
    rm -f "$SYNC_TASK_FILE" "$SYNC_SIT_TASK_FILE"
    exit 1
fi

echo "SIT Task ARN: $SIT_TASK_ARN"
echo "Waiting for S3 to SIT EFS sync to complete..."

aws ecs wait tasks-stopped \
  --cluster $SIT_CLUSTER \
  --tasks $SIT_TASK_ARN \
  --region $SIT_REGION \
  --profile $SIT_PROFILE

echo -e "${GREEN}✓ Files synced to SIT EFS${NC}"

# Cleanup
rm -f "$SYNC_TASK_FILE" "$SYNC_SIT_TASK_FILE"

# Optional: cleanup S3 files (comment out to keep for troubleshooting)
echo ""
echo "Cleaning up S3 migration files..."
aws s3 rm s3://${DEV_BUCKET}/${S3_PREFIX}/ --recursive \
  --region $DEV_REGION \
  --profile $DEV_PROFILE \
  --quiet 2>/dev/null || echo "DEV S3 cleanup skipped"

aws s3 rm s3://${SIT_BUCKET}/${S3_PREFIX}/ --recursive \
  --region $SIT_REGION \
  --profile $SIT_PROFILE \
  --quiet 2>/dev/null || echo "SIT S3 cleanup skipped"

echo ""
echo -e "${GREEN}=== wp-content Migration Complete! ===${NC}"
echo "Tenant: $TENANT_NAME"
echo "Files Migrated: $FILE_COUNT"
echo "DEV EFS → S3 DEV → S3 SIT → SIT EFS"
echo ""
echo "Next steps:"
echo "1. Validate migration: ./utils/validate_tenant_migration.sh $TENANT_NAME"
echo "2. Test tenant: https://${TENANT_NAME}.wpsit.kimmyai.io"
echo ""
echo -e "${GREEN}Complete!${NC}"
