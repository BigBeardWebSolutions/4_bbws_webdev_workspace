#!/bin/bash
# Master script for complete tenant deployment
# Usage: ./deploy_tenant.sh <tenant_name> <environment> <alb_priority>

set -e

TENANT=$1
ENV=$2
PRIORITY=$3

if [[ -z "$TENANT" || -z "$ENV" || -z "$PRIORITY" ]]; then
  echo "Usage: $0 <tenant_name> <environment> <alb_priority>"
  echo "Example: $0 myclient sit 190"
  echo ""
  echo "Environments: dev, sit, prod"
  echo "ALB Priority: Unique number 10-260"
  exit 1
fi

# Validate environment
case $ENV in
  dev|sit|prod)
    ;;
  *)
    echo "Error: Invalid environment '$ENV'. Must be dev, sit, or prod."
    exit 1
    ;;
esac

# Validate priority is a number
if ! [[ "$PRIORITY" =~ ^[0-9]+$ ]]; then
  echo "Error: Priority must be a number"
  exit 1
fi

echo "========================================="
echo "     BBWS TENANT DEPLOYMENT"
echo "========================================="
echo "Tenant:      $TENANT"
echo "Environment: $ENV"
echo "Priority:    $PRIORITY"
echo "========================================="
echo ""

# Confirm before proceeding
read -p "Proceed with deployment? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Deployment cancelled."
  exit 0
fi

START_TIME=$(date +%s)

# Step 1: Generate Terraform configuration
echo ""
echo "========================================="
echo "[1/5] Generating Terraform Configuration"
echo "========================================="
./generate_tenant_tf.sh $TENANT $PRIORITY $ENV || {
  echo "Error: Failed to generate Terraform config"
  exit 1
}

# Step 2: Create database
echo ""
echo "========================================="
echo "[2/5] Creating Database"
echo "========================================="
./create_database.sh $TENANT $ENV || {
  echo "Error: Failed to create database"
  exit 1
}

# Get AWS profile and region for next steps
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
esac

# Get secret ARN for IAM policy
SECRET_ARN=$(aws secretsmanager describe-secret \
  --secret-id ${ENV}-${TENANT}-db-credentials \
  --region $REGION \
  --profile $PROFILE \
  --query 'ARN' \
  --output text)

# Step 3: Create IAM policy
echo ""
echo "========================================="
echo "[3/5] Creating IAM Policies"
echo "========================================="
./create_iam_policy.sh $TENANT $ENV $SECRET_ARN || {
  echo "Error: Failed to create IAM policy"
  exit 1
}

# Step 4: Deploy infrastructure with Terraform
echo ""
echo "========================================="
echo "[4/5] Deploying Infrastructure (Terraform)"
echo "========================================="

cd ../2_bbws_ecs_terraform/terraform

# Initialize Terraform
echo "Initializing Terraform..."
terraform init -backend-config=environments/${ENV}/backend-${ENV}.hcl > /dev/null

# Select workspace
echo "Selecting workspace: $ENV"
terraform workspace select $ENV > /dev/null || terraform workspace new $ENV

# Plan
echo "Running terraform plan..."
terraform plan \
  -var-file=environments/${ENV}/${ENV}.tfvars \
  -target=aws_ecs_service.${ENV}_${TENANT} \
  -out=/tmp/${ENV}-${TENANT}.tfplan

# Show plan summary
echo ""
echo "Review the plan above. Proceeding with apply in 5 seconds..."
sleep 5

# Apply
echo "Applying Terraform configuration..."
terraform apply /tmp/${ENV}-${TENANT}.tfplan

cd ../../2_bbws_agents/utils

# Step 5: Verify deployment
echo ""
echo "========================================="
echo "[5/5] Verifying Deployment"
echo "========================================="

# Wait for ECS service to stabilize
echo "Waiting for ECS service to start (60 seconds)..."
sleep 60

./verify_deployment.sh $TENANT $ENV || {
  echo "Warning: Verification found issues. Check output above."
}

# Calculate deployment time
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

# Final summary
echo ""
echo "========================================="
echo "     DEPLOYMENT COMPLETE!"
echo "========================================="
echo "Tenant:      $TENANT"
echo "Environment: $ENV"
echo "Duration:    ${MINUTES}m ${SECONDS}s"
echo ""
echo "Resources created:"
echo "  • Database: ${TENANT}_db"
echo "  • User: ${TENANT}_user"
echo "  • Secret: ${ENV}-${TENANT}-db-credentials"
echo "  • EFS Access Point: ${ENV}-${TENANT}"
echo "  • ECS Service: ${ENV}-${TENANT}-service"
echo "  • Target Group: ${ENV}-${TENANT}-tg"
echo "  • ALB Rule: Priority ${PRIORITY}"
echo ""
case $ENV in
  dev)
    URL="https://${TENANT}.wpdev.kimmyai.io"
    ;;
  sit)
    URL="https://${TENANT}.wpsit.kimmyai.io"
    echo "  Basic Auth: bbws-sit / <password from secrets>"
    ;;
  prod)
    URL="https://${TENANT}.wp.kimmyai.io"
    echo "  Basic Auth: bbws-prod / <password from secrets>"
    ;;
esac
echo "  Site URL: $URL"
echo ""
echo "Next steps:"
echo "  1. Test site: curl -I $URL"
echo "  2. Complete WordPress setup: ${URL}/wp-admin/install.php"
echo "  3. Monitor logs: aws logs tail /ecs/${ENV} --filter-pattern '${TENANT}'"
echo "========================================="

# Save deployment record
cat > /tmp/${TENANT}_${ENV}_deployment.txt <<DEPLOYMENT
BBWS Tenant Deployment Record
==============================
Tenant: ${TENANT}
Environment: ${ENV}
Date: $(date)
Duration: ${MINUTES}m ${SECONDS}s

Configuration:
  ALB Priority: ${PRIORITY}
  Domain: $(case $ENV in dev) echo wpdev;; sit) echo wpsit;; prod) echo wp;; esac).kimmyai.io
  Database: ${TENANT}_db
  Secret: ${ENV}-${TENANT}-db-credentials

URLs:
  Site: $URL
  WordPress Admin: ${URL}/wp-admin

Files Created:
  Terraform: ../2_bbws_ecs_terraform/terraform/${ENV}_${TENANT}.tf
  Password: /tmp/${TENANT}_${ENV}_password.txt
  DB Summary: /tmp/${TENANT}_${ENV}_db_summary.txt
  This record: /tmp/${TENANT}_${ENV}_deployment.txt

Deployed by: $(whoami)
Hostname: $(hostname)
DEPLOYMENT

echo "Deployment record saved to: /tmp/${TENANT}_${ENV}_deployment.txt"
