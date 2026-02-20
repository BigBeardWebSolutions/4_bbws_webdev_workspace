#!/bin/bash
# Comprehensive SIT Environment Health Check
# Validates all infrastructure components in SIT

set -e

ENVIRONMENT="sit"
REGION="eu-west-1"
AWS_PROFILE="Tebogo-sit"

echo "=========================================="
echo "SIT Environment Health Check"
echo "AWS Profile: $AWS_PROFILE"
echo "Region: $REGION"
echo "=========================================="

# Verify AWS connection
echo -e "\n[0/6] Verifying AWS connection..."
ACCOUNT_ID=$(aws sts get-caller-identity --profile $AWS_PROFILE --query Account --output text 2>&1)
if [ $? -ne 0 ]; then
  echo "❌ Failed to connect to AWS. Please check your AWS profile configuration."
  exit 1
fi
echo "✅ Connected to AWS Account: $ACCOUNT_ID"

# Expected account ID for SIT
EXPECTED_ACCOUNT="815856636111"
if [ "$ACCOUNT_ID" != "$EXPECTED_ACCOUNT" ]; then
  echo "⚠️  WARNING: Connected to account $ACCOUNT_ID, expected $EXPECTED_ACCOUNT"
fi

# Check RDS
echo -e "\n[1/6] Checking RDS..."
RDS_STATUS=$(aws rds describe-db-instances \
  --db-instance-identifier sit-mysql \
  --region $REGION \
  --profile $AWS_PROFILE \
  --query 'DBInstances[0].DBInstanceStatus' \
  --output text 2>&1)

if [ $? -eq 0 ]; then
  if [ "$RDS_STATUS" == "available" ]; then
    echo "✅ RDS: $RDS_STATUS"

    # Get RDS endpoint
    RDS_ENDPOINT=$(aws rds describe-db-instances \
      --db-instance-identifier sit-mysql \
      --region $REGION \
      --profile $AWS_PROFILE \
      --query 'DBInstances[0].Endpoint.Address' \
      --output text)
    echo "   Endpoint: $RDS_ENDPOINT"
  else
    echo "⚠️  RDS: $RDS_STATUS (not available)"
  fi
else
  echo "❌ RDS: Not found or error accessing"
fi

# Check ECS Cluster
echo -e "\n[2/6] Checking ECS Cluster..."
CLUSTER_STATUS=$(aws ecs describe-clusters \
  --clusters sit-cluster \
  --region $REGION \
  --profile $AWS_PROFILE \
  --query 'clusters[0].status' \
  --output text 2>&1)

if [ $? -eq 0 ]; then
  if [ "$CLUSTER_STATUS" == "ACTIVE" ]; then
    echo "✅ ECS Cluster: $CLUSTER_STATUS"

    # Get running tasks count
    RUNNING_TASKS=$(aws ecs describe-clusters \
      --clusters sit-cluster \
      --region $REGION \
      --profile $AWS_PROFILE \
      --query 'clusters[0].runningTasksCount' \
      --output text)
    echo "   Running Tasks: $RUNNING_TASKS"
  else
    echo "⚠️  ECS Cluster: $CLUSTER_STATUS"
  fi
else
  echo "❌ ECS Cluster: Not found or error accessing"
fi

# Check ECS Services
echo -e "\n[3/6] Checking ECS Services..."
SERVICES=$(aws ecs list-services \
  --cluster sit-cluster \
  --region $REGION \
  --profile $AWS_PROFILE \
  --query 'serviceArns' \
  --output text 2>&1)

if [ $? -eq 0 ] && [ -n "$SERVICES" ]; then
  SERVICE_COUNT=$(echo "$SERVICES" | wc -w)
  echo "Found $SERVICE_COUNT service(s)"

  for SERVICE in $SERVICES; do
    SERVICE_NAME=$(basename $SERVICE)

    # Get service status
    SERVICE_INFO=$(aws ecs describe-services \
      --cluster sit-cluster \
      --services $SERVICE \
      --region $REGION \
      --profile $AWS_PROFILE \
      --query 'services[0].[status,runningCount,desiredCount]' \
      --output text)

    STATUS=$(echo $SERVICE_INFO | awk '{print $1}')
    RUNNING=$(echo $SERVICE_INFO | awk '{print $2}')
    DESIRED=$(echo $SERVICE_INFO | awk '{print $3}')

    if [ "$RUNNING" == "$DESIRED" ] && [ "$STATUS" == "ACTIVE" ]; then
      echo "✅ Service $SERVICE_NAME: $RUNNING/$DESIRED running ($STATUS)"
    else
      echo "⚠️  Service $SERVICE_NAME: $RUNNING/$DESIRED running ($STATUS)"
    fi
  done
else
  echo "⚠️  No services found or error accessing"
fi

# Check ALB
echo -e "\n[4/6] Checking ALB..."
ALB_STATE=$(aws elbv2 describe-load-balancers \
  --names sit-alb \
  --region $REGION \
  --profile $AWS_PROFILE \
  --query 'LoadBalancers[0].State.Code' \
  --output text 2>&1)

if [ $? -eq 0 ]; then
  if [ "$ALB_STATE" == "active" ]; then
    echo "✅ ALB: $ALB_STATE"

    # Get ALB DNS name
    ALB_DNS=$(aws elbv2 describe-load-balancers \
      --names sit-alb \
      --region $REGION \
      --profile $AWS_PROFILE \
      --query 'LoadBalancers[0].DNSName' \
      --output text)
    echo "   DNS: $ALB_DNS"
  else
    echo "⚠️  ALB: $ALB_STATE"
  fi
else
  echo "❌ ALB: Not found or error accessing"
fi

# Check ALB Target Groups
echo -e "\n[5/6] Checking ALB Target Groups..."
TARGET_GROUPS=$(aws elbv2 describe-target-groups \
  --region $REGION \
  --profile $AWS_PROFILE \
  --query 'TargetGroups[?starts_with(TargetGroupName, `sit-`)].TargetGroupArn' \
  --output text 2>&1)

if [ $? -eq 0 ] && [ -n "$TARGET_GROUPS" ]; then
  TG_COUNT=$(echo "$TARGET_GROUPS" | wc -w)
  echo "Found $TG_COUNT target group(s)"

  for TG_ARN in $TARGET_GROUPS; do
    TG_NAME=$(aws elbv2 describe-target-groups \
      --target-group-arns $TG_ARN \
      --region $REGION \
      --profile $AWS_PROFILE \
      --query 'TargetGroups[0].TargetGroupName' \
      --output text)

    # Get target health
    HEALTH=$(aws elbv2 describe-target-health \
      --target-group-arn $TG_ARN \
      --region $REGION \
      --profile $AWS_PROFILE \
      --query 'TargetHealthDescriptions[0].TargetHealth.State' \
      --output text 2>&1)

    if [ "$HEALTH" == "healthy" ]; then
      echo "✅ Target Group $TG_NAME: $HEALTH"
    elif [ "$HEALTH" == "None" ] || [ -z "$HEALTH" ]; then
      echo "⚠️  Target Group $TG_NAME: No targets registered"
    else
      echo "⚠️  Target Group $TG_NAME: $HEALTH"
    fi
  done
else
  echo "⚠️  No target groups found or error accessing"
fi

# Check DynamoDB Tables
echo -e "\n[6/6] Checking DynamoDB Tables..."
TABLES=$(aws dynamodb list-tables \
  --region $REGION \
  --profile $AWS_PROFILE \
  --query 'TableNames[?starts_with(@, `sit-`)]' \
  --output text 2>&1)

if [ $? -eq 0 ] && [ -n "$TABLES" ]; then
  TABLE_COUNT=$(echo "$TABLES" | wc -w)
  echo "Found $TABLE_COUNT table(s)"

  for TABLE in $TABLES; do
    TABLE_STATUS=$(aws dynamodb describe-table \
      --table-name $TABLE \
      --region $REGION \
      --profile $AWS_PROFILE \
      --query 'Table.TableStatus' \
      --output text 2>&1)

    if [ "$TABLE_STATUS" == "ACTIVE" ]; then
      echo "✅ Table $TABLE: $TABLE_STATUS"
    else
      echo "⚠️  Table $TABLE: $TABLE_STATUS"
    fi
  done
else
  echo "⚠️  No DynamoDB tables found or error accessing"
fi

# Summary
echo -e "\n=========================================="
echo "Health Check Complete"
echo "=========================================="
echo ""
echo "Summary:"
echo "  - RDS: $([ "$RDS_STATUS" == "available" ] && echo "✅ Healthy" || echo "⚠️  Check required")"
echo "  - ECS Cluster: $([ "$CLUSTER_STATUS" == "ACTIVE" ] && echo "✅ Healthy" || echo "⚠️  Check required")"
echo "  - ALB: $([ "$ALB_STATE" == "active" ] && echo "✅ Healthy" || echo "⚠️  Check required")"
echo ""
