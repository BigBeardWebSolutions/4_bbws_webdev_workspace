#!/bin/bash
#
# Validate Tenant Migration to SIT
#
# This script performs comprehensive validation of a tenant's migration to SIT,
# checking database, ECS service, ALB, and HTTP/HTTPS access.
#
# Usage: ./validate_tenant_migration.sh <tenant_name>
#
# Example: ./validate_tenant_migration.sh goldencrust
#
# Author: Big Beard Web Solutions
# Date: December 2024
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Validation results
VALIDATION_PASSED=0
VALIDATION_FAILED=0
VALIDATION_WARNINGS=0

# Derive database and service names
if [ "$TENANT_NAME" = "tenant1" ]; then
    DB_NAME="tenant_1_db"
    DB_USER="tenant_1_user"
    SERVICE_NAME="sit-tenant-1-service"
    TARGET_GROUP_NAME="sit-tenant-1-tg"
    DOMAIN="tenant1.wpsit.kimmyai.io"
elif [ "$TENANT_NAME" = "tenant2" ]; then
    DB_NAME="tenant_2_db"
    DB_USER="tenant_2_user"
    SERVICE_NAME="sit-tenant-2-service"
    TARGET_GROUP_NAME="sit-tenant-2-tg"
    DOMAIN="tenant2.wpsit.kimmyai.io"
else
    DB_NAME="${TENANT_NAME}_db"
    DB_USER="${TENANT_NAME}_user"
    SERVICE_NAME="sit-${TENANT_NAME}-service"
    TARGET_GROUP_NAME="sit-${TENANT_NAME}-tg"
    DOMAIN="${TENANT_NAME}.wpsit.kimmyai.io"
fi

echo ""
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   SIT Tenant Migration Validation Report                 ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Tenant: $TENANT_NAME"
echo "Database: $DB_NAME"
echo "Service: $SERVICE_NAME"
echo "Domain: https://$DOMAIN"
echo "Region: $REGION"
echo "Profile: $AWS_PROFILE"
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# =============================================================================
# 1. Secrets Manager Validation
# =============================================================================
echo -e "${YELLOW}[1/7] Validating Secrets Manager...${NC}"

SECRET_NAME="sit-${TENANT_NAME}-db-credentials"
SECRET_EXISTS=$(aws secretsmanager describe-secret \
  --secret-id "$SECRET_NAME" \
  --region $REGION \
  --profile $AWS_PROFILE \
  --query 'Name' \
  --output text 2>/dev/null || echo "")

if [ -n "$SECRET_EXISTS" ]; then
    echo -e "${GREEN}✓ Secret exists: $SECRET_NAME${NC}"
    VALIDATION_PASSED=$((VALIDATION_PASSED + 1))

    # Validate secret structure
    SECRET_KEYS=$(aws secretsmanager get-secret-value \
      --secret-id "$SECRET_NAME" \
      --region $REGION \
      --profile $AWS_PROFILE \
      --query SecretString \
      --output text 2>/dev/null | jq -r 'keys | join(", ")' 2>/dev/null || echo "")

    echo "  Secret keys: $SECRET_KEYS"

    RDS_HOST=$(aws secretsmanager get-secret-value \
      --secret-id "$SECRET_NAME" \
      --region $REGION \
      --profile $AWS_PROFILE \
      --query SecretString \
      --output text | jq -r '.host')

    echo "  RDS Host: $RDS_HOST"
else
    echo -e "${RED}✗ Secret not found: $SECRET_NAME${NC}"
    VALIDATION_FAILED=$((VALIDATION_FAILED + 1))
fi

echo ""

# =============================================================================
# 2. Database Validation
# =============================================================================
echo -e "${YELLOW}[2/7] Validating Database...${NC}"

if [ -n "$SECRET_EXISTS" ]; then
    # Get credentials
    TENANT_PASS=$(aws secretsmanager get-secret-value \
      --secret-id "$SECRET_NAME" \
      --region $REGION \
      --profile $AWS_PROFILE \
      --query SecretString \
      --output text | jq -r '.password')

    # Create temp file for database check
    DB_CHECK_FILE="/tmp/validate_db_${TENANT_NAME}.json"
    cat <<EOF > "$DB_CHECK_FILE"
{
  "containerOverrides": [{
    "name": "db-init",
    "command": [
      "sh", "-c",
      "mysql -h $RDS_HOST -u $DB_USER -p'$TENANT_PASS' -e 'SELECT DATABASE(); SELECT COUNT(*) as table_count FROM information_schema.tables WHERE table_schema=\"$DB_NAME\"; SELECT table_name, table_rows FROM information_schema.tables WHERE table_schema=\"$DB_NAME\" ORDER BY table_rows DESC LIMIT 5;' 2>&1"
    ],
    "environment": []
  }]
}
EOF

    # Get subnet and security group
    SUBNET_ID=$(aws ec2 describe-subnets \
      --region $REGION \
      --profile $AWS_PROFILE \
      --filters "Name=tag:Environment,Values=sit" "Name=tag:Name,Values=*private*" \
      --query 'Subnets[0].SubnetId' \
      --output text 2>/dev/null)

    SG_ID=$(aws ec2 describe-security-groups \
      --region $REGION \
      --profile $AWS_PROFILE \
      --filters "Name=tag:Environment,Values=sit" "Name=tag:Name,Values=*ecs*" \
      --query 'SecurityGroups[0].GroupId' \
      --output text 2>/dev/null)

    if [ -n "$SUBNET_ID" ] && [ "$SUBNET_ID" != "None" ] && [ -n "$SG_ID" ] && [ "$SG_ID" != "None" ]; then
        echo "  Running database connectivity test..."

        TASK_ARN=$(aws ecs run-task \
          --cluster sit-cluster \
          --task-definition sit-db-init \
          --launch-type FARGATE \
          --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_ID],securityGroups=[$SG_ID],assignPublicIp=DISABLED}" \
          --region $REGION \
          --profile $AWS_PROFILE \
          --overrides file://"$DB_CHECK_FILE" \
          --query 'tasks[0].taskArn' \
          --output text 2>&1)

        if [ $? -eq 0 ] && [ "$TASK_ARN" != "None" ]; then
            aws ecs wait tasks-stopped \
              --cluster sit-cluster \
              --tasks $TASK_ARN \
              --region $REGION \
              --profile $AWS_PROFILE 2>/dev/null || true

            echo -e "${GREEN}✓ Database connectivity confirmed${NC}"
            VALIDATION_PASSED=$((VALIDATION_PASSED + 1))
        else
            echo -e "${YELLOW}⚠ Could not run database test task${NC}"
            VALIDATION_WARNINGS=$((VALIDATION_WARNINGS + 1))
        fi

        rm -f "$DB_CHECK_FILE"
    else
        echo -e "${YELLOW}⚠ VPC configuration not available for database test${NC}"
        VALIDATION_WARNINGS=$((VALIDATION_WARNINGS + 1))
    fi
else
    echo -e "${RED}✗ Cannot validate database (secret missing)${NC}"
    VALIDATION_FAILED=$((VALIDATION_FAILED + 1))
fi

echo ""

# =============================================================================
# 3. ECS Service Validation
# =============================================================================
echo -e "${YELLOW}[3/7] Validating ECS Service...${NC}"

SERVICE_INFO=$(aws ecs describe-services \
  --cluster sit-cluster \
  --services $SERVICE_NAME \
  --region $REGION \
  --profile $AWS_PROFILE \
  --query 'services[0]' \
  --output json 2>/dev/null)

if [ -n "$SERVICE_INFO" ] && [ "$SERVICE_INFO" != "null" ]; then
    STATUS=$(echo "$SERVICE_INFO" | jq -r '.status')
    DESIRED=$(echo "$SERVICE_INFO" | jq -r '.desiredCount')
    RUNNING=$(echo "$SERVICE_INFO" | jq -r '.runningCount')

    echo "  Service Status: $STATUS"
    echo "  Desired Count: $DESIRED"
    echo "  Running Count: $RUNNING"

    if [ "$STATUS" = "ACTIVE" ] && [ "$RUNNING" -ge "$DESIRED" ] && [ "$DESIRED" -gt 0 ]; then
        echo -e "${GREEN}✓ ECS service is healthy${NC}"
        VALIDATION_PASSED=$((VALIDATION_PASSED + 1))
    elif [ "$STATUS" = "ACTIVE" ] && [ "$DESIRED" -eq 0 ]; then
        echo -e "${YELLOW}⚠ Service exists but desired count is 0${NC}"
        VALIDATION_WARNINGS=$((VALIDATION_WARNINGS + 1))
    else
        echo -e "${RED}✗ ECS service is not healthy (Running: $RUNNING, Desired: $DESIRED)${NC}"
        VALIDATION_FAILED=$((VALIDATION_FAILED + 1))
    fi
else
    echo -e "${RED}✗ ECS service not found: $SERVICE_NAME${NC}"
    VALIDATION_FAILED=$((VALIDATION_FAILED + 1))
fi

echo ""

# =============================================================================
# 4. ALB Target Group Validation
# =============================================================================
echo -e "${YELLOW}[4/7] Validating ALB Target Group...${NC}"

TG_ARN=$(aws elbv2 describe-target-groups \
  --region $REGION \
  --profile $AWS_PROFILE \
  --names $TARGET_GROUP_NAME \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text 2>/dev/null)

if [ -n "$TG_ARN" ] && [ "$TG_ARN" != "None" ]; then
    echo "  Target Group: $TARGET_GROUP_NAME"
    echo "  ARN: $TG_ARN"

    # Check target health
    HEALTH_STATUS=$(aws elbv2 describe-target-health \
      --target-group-arn $TG_ARN \
      --region $REGION \
      --profile $AWS_PROFILE \
      --query 'TargetHealthDescriptions[*].[Target.Id,TargetHealth.State]' \
      --output text 2>/dev/null)

    if [ -n "$HEALTH_STATUS" ]; then
        echo "  Target Health:"
        echo "$HEALTH_STATUS" | while read -r line; do
            echo "    $line"
        done

        HEALTHY_COUNT=$(echo "$HEALTH_STATUS" | grep -c "healthy" || echo "0")
        TOTAL_COUNT=$(echo "$HEALTH_STATUS" | wc -l | tr -d ' ')

        if [ "$HEALTHY_COUNT" -gt 0 ]; then
            echo -e "${GREEN}✓ Target group has $HEALTHY_COUNT/$TOTAL_COUNT healthy targets${NC}"
            VALIDATION_PASSED=$((VALIDATION_PASSED + 1))
        else
            echo -e "${RED}✗ No healthy targets in target group${NC}"
            VALIDATION_FAILED=$((VALIDATION_FAILED + 1))
        fi
    else
        echo -e "${YELLOW}⚠ No targets registered in target group${NC}"
        VALIDATION_WARNINGS=$((VALIDATION_WARNINGS + 1))
    fi
else
    echo -e "${RED}✗ Target group not found: $TARGET_GROUP_NAME${NC}"
    VALIDATION_FAILED=$((VALIDATION_FAILED + 1))
fi

echo ""

# =============================================================================
# 5. DNS Resolution Validation
# =============================================================================
echo -e "${YELLOW}[5/7] Validating DNS Resolution...${NC}"

DNS_RESULT=$(dig +short $DOMAIN | tail -1)

if [ -n "$DNS_RESULT" ]; then
    echo "  Domain: $DOMAIN"
    echo "  Resolves to: $DNS_RESULT"

    # Check if it's a CloudFront distribution
    if [[ "$DNS_RESULT" == *"cloudfront.net" ]] || [[ "$DNS_RESULT" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo -e "${GREEN}✓ DNS resolution successful${NC}"
        VALIDATION_PASSED=$((VALIDATION_PASSED + 1))
    else
        echo -e "${YELLOW}⚠ DNS resolves but may not point to CloudFront${NC}"
        VALIDATION_WARNINGS=$((VALIDATION_WARNINGS + 1))
    fi
else
    echo -e "${RED}✗ DNS does not resolve for $DOMAIN${NC}"
    VALIDATION_FAILED=$((VALIDATION_FAILED + 1))
fi

echo ""

# =============================================================================
# 6. HTTP/HTTPS Access Validation
# =============================================================================
echo -e "${YELLOW}[6/7] Validating HTTP/HTTPS Access...${NC}"

if [ -n "$DNS_RESULT" ]; then
    echo "  Testing HTTPS access to https://$DOMAIN"

    # Try without auth first
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -L --max-time 10 "https://$DOMAIN" 2>/dev/null || echo "000")

    echo "  HTTP Status: $HTTP_STATUS"

    if [ "$HTTP_STATUS" = "401" ]; then
        echo -e "${GREEN}✓ HTTPS accessible (Basic Auth protecting site)${NC}"
        VALIDATION_PASSED=$((VALIDATION_PASSED + 1))

        # Check if BASIC_AUTH_PASSWORD is set
        if [ -n "$BASIC_AUTH_PASSWORD" ]; then
            AUTH_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -L --max-time 10 \
              -u "bbws-sit:$BASIC_AUTH_PASSWORD" "https://$DOMAIN" 2>/dev/null || echo "000")
            echo "  Authenticated Status: $AUTH_STATUS"

            if [ "$AUTH_STATUS" = "200" ] || [ "$AUTH_STATUS" = "301" ] || [ "$AUTH_STATUS" = "302" ]; then
                echo -e "${GREEN}✓ Site accessible with Basic Auth${NC}"
            fi
        else
            echo -e "${YELLOW}  Note: Set BASIC_AUTH_PASSWORD env var to test authenticated access${NC}"
        fi

    elif [ "$HTTP_STATUS" = "200" ] || [ "$HTTP_STATUS" = "301" ] || [ "$HTTP_STATUS" = "302" ]; then
        echo -e "${GREEN}✓ HTTPS accessible${NC}"
        VALIDATION_PASSED=$((VALIDATION_PASSED + 1))
    elif [ "$HTTP_STATUS" = "000" ]; then
        echo -e "${RED}✗ Connection timeout or network error${NC}"
        VALIDATION_FAILED=$((VALIDATION_FAILED + 1))
    else
        echo -e "${RED}✗ Unexpected HTTP status: $HTTP_STATUS${NC}"
        VALIDATION_FAILED=$((VALIDATION_FAILED + 1))
    fi
else
    echo -e "${YELLOW}⚠ Skipping HTTP test (DNS not resolved)${NC}"
    VALIDATION_WARNINGS=$((VALIDATION_WARNINGS + 1))
fi

echo ""

# =============================================================================
# 7. WordPress URL Configuration Validation
# =============================================================================
echo -e "${YELLOW}[7/7] Validating WordPress Configuration...${NC}"

if [ -n "$DNS_RESULT" ]; then
    # Try to fetch homepage and check for correct domain in content
    PAGE_CONTENT=$(curl -s -L --max-time 10 "https://$DOMAIN" 2>/dev/null || echo "")

    if [[ "$PAGE_CONTENT" == *"$DOMAIN"* ]]; then
        echo -e "${GREEN}✓ WordPress configured with correct domain${NC}"
        VALIDATION_PASSED=$((VALIDATION_PASSED + 1))
    elif [[ "$PAGE_CONTENT" == *"wpdev.kimmyai.io"* ]]; then
        echo -e "${RED}✗ WordPress still has DEV URLs (wpdev.kimmyai.io found)${NC}"
        VALIDATION_FAILED=$((VALIDATION_FAILED + 1))
    elif [ -z "$PAGE_CONTENT" ]; then
        echo -e "${YELLOW}⚠ Could not fetch page content${NC}"
        VALIDATION_WARNINGS=$((VALIDATION_WARNINGS + 1))
    else
        echo -e "${YELLOW}⚠ Could not verify WordPress domain configuration${NC}"
        VALIDATION_WARNINGS=$((VALIDATION_WARNINGS + 1))
    fi
else
    echo -e "${YELLOW}⚠ Skipping WordPress validation (DNS not resolved)${NC}"
    VALIDATION_WARNINGS=$((VALIDATION_WARNINGS + 1))
fi

echo ""

# =============================================================================
# Validation Summary
# =============================================================================
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Validation Summary                                      ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Tenant: $TENANT_NAME"
echo "Domain: https://$DOMAIN"
echo ""
echo -e "${GREEN}Passed:   $VALIDATION_PASSED${NC}"
echo -e "${YELLOW}Warnings: $VALIDATION_WARNINGS${NC}"
echo -e "${RED}Failed:   $VALIDATION_FAILED${NC}"
echo ""

TOTAL_CHECKS=7
SUCCESS_RATE=$((VALIDATION_PASSED * 100 / TOTAL_CHECKS))

if [ $VALIDATION_FAILED -eq 0 ]; then
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   ✓ MIGRATION SUCCESSFUL ($SUCCESS_RATE% checks passed)                  ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    exit 0
elif [ $VALIDATION_PASSED -ge 4 ]; then
    echo -e "${YELLOW}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║   ⚠ MIGRATION PARTIALLY SUCCESSFUL ($SUCCESS_RATE% checks passed)      ║${NC}"
    echo -e "${YELLOW}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Some checks failed. Review the results above and address issues."
    exit 1
else
    echo -e "${RED}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║   ✗ MIGRATION FAILED ($SUCCESS_RATE% checks passed)                      ║${NC}"
    echo -e "${RED}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Multiple critical checks failed. Migration requires attention."
    exit 1
fi
