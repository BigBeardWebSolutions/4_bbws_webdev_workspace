#!/bin/bash
# Generate environment-specific Terraform configuration from template
# Usage: ./generate_tenant_tf.sh <tenant_name> <alb_priority> <environment>

set -e

TENANT=$1
PRIORITY=$2
ENV=$3  # dev, sit, prod

if [[ -z "$TENANT" || -z "$PRIORITY" || -z "$ENV" ]]; then
  echo "Usage: $0 <tenant_name> <alb_priority> <environment>"
  echo "Example: $0 myclient 190 sit"
  exit 1
fi

TERRAFORM_DIR="../2_bbws_ecs_terraform/terraform"
TEMPLATE_FILE="${TERRAFORM_DIR}/goldencrust.tf"
OUTPUT_FILE="${TERRAFORM_DIR}/${ENV}_${TENANT}.tf"

# Check if tenant already exists
if [[ -f "$OUTPUT_FILE" ]]; then
  echo "Error: $OUTPUT_FILE already exists"
  exit 1
fi

echo "Generating Terraform config for ${TENANT} in ${ENV} environment..."

# Generate from template
cp "$TEMPLATE_FILE" "$OUTPUT_FILE"

# Replace tenant name
sed -i '' "s/goldencrust/${TENANT}/g" "$OUTPUT_FILE"

# Update priority
sed -i '' "s/priority     = 140/priority     = ${PRIORITY}/" "$OUTPUT_FILE"

# Update domain based on environment
case $ENV in
  dev)
    DOMAIN="wpdev.kimmyai.io"
    ;;
  sit)
    DOMAIN="wpsit.kimmyai.io"
    ;;
  prod)
    DOMAIN="wp.kimmyai.io"
    ;;
esac

# Replace all domain references
sed -i '' "s/goldencrust\.wpdev\.kimmyai\.io/${TENANT}.${DOMAIN}/g" "$OUTPUT_FILE"
sed -i '' "s/goldencrust\.wpsit\.kimmyai\.io/${TENANT}.${DOMAIN}/g" "$OUTPUT_FILE"

# Update resource names with environment prefix
# Critical: All resources must have environment prefix to avoid conflicts

# Random password
sed -i '' "s/resource \"random_password\" \"sit_goldencrust_db\"/resource \"random_password\" \"${ENV}_${TENANT}_db\"/" "$OUTPUT_FILE"

# Secrets Manager
sed -i '' "s/resource \"aws_secretsmanager_secret\" \"sit_goldencrust_db\"/resource \"aws_secretsmanager_secret\" \"${ENV}_${TENANT}_db\"/" "$OUTPUT_FILE"
sed -i '' "s/resource \"aws_secretsmanager_secret_version\" \"sit_goldencrust_db\"/resource \"aws_secretsmanager_secret_version\" \"${ENV}_${TENANT}_db\"/" "$OUTPUT_FILE"

# EFS Access Point
sed -i '' "s/resource \"aws_efs_access_point\" \"sit_goldencrust\"/resource \"aws_efs_access_point\" \"${ENV}_${TENANT}\"/" "$OUTPUT_FILE"

# ECS Task Definition
sed -i '' "s/resource \"aws_ecs_task_definition\" \"sit_goldencrust\"/resource \"aws_ecs_task_definition\" \"${ENV}_${TENANT}\"/" "$OUTPUT_FILE"

# Target Group
sed -i '' "s/resource \"aws_lb_target_group\" \"sit_goldencrust\"/resource \"aws_lb_target_group\" \"${ENV}_${TENANT}\"/" "$OUTPUT_FILE"

# Listener Rule
sed -i '' "s/resource \"aws_lb_listener_rule\" \"sit_goldencrust\"/resource \"aws_lb_listener_rule\" \"${ENV}_${TENANT}\"/" "$OUTPUT_FILE"

# ECS Service
sed -i '' "s/resource \"aws_ecs_service\" \"sit_goldencrust\"/resource \"aws_ecs_service\" \"${ENV}_${TENANT}\"/" "$OUTPUT_FILE"

# Update all resource references (critical to avoid broken dependencies)
sed -i '' "s/aws_secretsmanager_secret\.sit_goldencrust_db/aws_secretsmanager_secret.${ENV}_${TENANT}_db/g" "$OUTPUT_FILE"
sed -i '' "s/random_password\.sit_goldencrust_db/random_password.${ENV}_${TENANT}_db/g" "$OUTPUT_FILE"
sed -i '' "s/aws_efs_access_point\.sit_goldencrust/aws_efs_access_point.${ENV}_${TENANT}/g" "$OUTPUT_FILE"
sed -i '' "s/aws_ecs_task_definition\.sit_goldencrust/aws_ecs_task_definition.${ENV}_${TENANT}/g" "$OUTPUT_FILE"
sed -i '' "s/aws_lb_target_group\.sit_goldencrust/aws_lb_target_group.${ENV}_${TENANT}/g" "$OUTPUT_FILE"
sed -i '' "s/aws_lb_listener_rule\.sit_goldencrust/aws_lb_listener_rule.${ENV}_${TENANT}/g" "$OUTPUT_FILE"

# Update AWS resource names (these use dashes)
sed -i '' "s/sit-goldencrust/${ENV}-${TENANT}/g" "$OUTPUT_FILE"

# Update comment header
sed -i '' "1i\\
# ${ENV^^} Tenant: ${TENANT}\\
# Auto-generated from template: goldencrust.tf\\
# Generated: $(date '+%Y-%m-%d %H:%M:%S')\\
# ALB Priority: ${PRIORITY}\\
" "$OUTPUT_FILE"

echo "✅ Generated: $OUTPUT_FILE"
echo ""
echo "Next steps:"
echo "  1. Review the generated file: cat $OUTPUT_FILE"
echo "  2. Create database: ./create_database.sh ${TENANT} ${ENV}"
echo "  3. Deploy infrastructure: cd ../2_bbws_ecs_terraform/terraform && terraform apply -var-file=environments/${ENV}/${ENV}.tfvars -target=aws_ecs_service.${ENV}_${TENANT}"
