# Goldencrust Tenant Configuration

Terraform configuration for the Goldencrust WordPress tenant across DEV, SIT, and PROD environments.

## Overview

This tenant configuration uses reusable modules to deploy:
- ECS Fargate service with WordPress container
- MySQL database with isolated credentials
- EFS access point for wp-content storage
- ALB target group and listener rule
- Route53 DNS records (PROD only)

## Files

- `main.tf` - Module calls and data sources
- `variables.tf` - Variable declarations
- `backend.tf` - S3 backend configuration
- `providers.tf` - AWS provider setup
- `outputs.tf` - Output values
- `dev.tfvars` - DEV environment values
- `sit.tfvars` - SIT environment values
- `prod.tfvars` - PROD environment values

## Deployment

### Initialize Backend

```bash
# DEV
terraform init \
  -backend-config="../../environments/dev/backend-dev.hcl" \
  -backend-config="key=tenants/goldencrust/terraform.tfstate"

# SIT
terraform init \
  -backend-config="../../environments/sit/backend-sit.hcl" \
  -backend-config="key=tenants/goldencrust/terraform.tfstate"

# PROD
terraform init \
  -backend-config="../../environments/prod/backend-prod.hcl" \
  -backend-config="key=tenants/goldencrust/terraform.tfstate"
```

### Plan Deployment

```bash
# DEV
terraform plan -var-file=dev.tfvars -out=dev.tfplan

# SIT
terraform plan -var-file=sit.tfvars -out=sit.tfplan

# PROD
terraform plan -var-file=prod.tfvars -out=prod.tfplan
```

### Apply Deployment

```bash
# DEV
terraform apply dev.tfplan

# SIT
terraform apply sit.tfplan

# PROD (requires approval)
terraform apply prod.tfplan
```

## Environment Configuration

### DEV
- **Region:** eu-west-1
- **Domain:** goldencrust.wpdev.kimmyai.io
- **ALB Priority:** 40
- **Tasks:** 1
- **Resources:** 256 CPU, 512 MB memory
- **Debug:** Enabled
- **ECS Exec:** Enabled

### SIT
- **Region:** eu-west-1
- **Domain:** goldencrust.wpsit.kimmyai.io
- **ALB Priority:** 140
- **Tasks:** 1
- **Resources:** 256 CPU, 512 MB memory
- **Debug:** Disabled
- **ECS Exec:** Enabled

### PROD
- **Region:** af-south-1
- **Domain:** goldencrust.wp.kimmyai.io
- **ALB Priority:** 1040
- **Tasks:** 2 (high availability)
- **Resources:** 512 CPU, 1024 MB memory
- **Debug:** Disabled
- **ECS Exec:** Disabled
- **DNS:** CloudFront + Route53

## Outputs

After deployment, get tenant information:

```bash
terraform output tenant_url
terraform output service_name
terraform output db_secret_arn
terraform output tenant_config
```

## Testing

### Test ALB Access (DEV/SIT)

```bash
# Get ALB DNS
ALB_DNS=$(aws elbv2 describe-load-balancers \
  --query "LoadBalancers[?LoadBalancerName=='sit-alb'].DNSName | [0]" \
  --output text \
  --profile Tebogo-sit)

# Test with Host header
curl -H "Host: goldencrust.wpsit.kimmyai.io" http://${ALB_DNS}/
```

### Test CloudFront Access (PROD)

```bash
curl -I https://goldencrust.wp.kimmyai.io
```

## Troubleshooting

### Service Not Starting

```bash
# Check service status
aws ecs describe-services \
  --cluster sit-cluster \
  --services sit-goldencrust-service \
  --profile Tebogo-sit

# Check task logs
aws logs tail /ecs/sit-cluster \
  --follow \
  --filter-pattern goldencrust \
  --profile Tebogo-sit
```

### Database Connection Issues

```bash
# Get database credentials
aws secretsmanager get-secret-value \
  --secret-id sit-goldencrust-db-credentials \
  --query SecretString \
  --output text \
  --profile Tebogo-sit | jq .
```

### Target Not Healthy

```bash
# Check target health
TG_ARN=$(aws elbv2 describe-target-groups \
  --query "TargetGroups[?TargetGroupName=='sit-goldencrust-tg'].TargetGroupArn | [0]" \
  --output text \
  --profile Tebogo-sit)

aws elbv2 describe-target-health \
  --target-group-arn "$TG_ARN" \
  --profile Tebogo-sit
```

## Rollback

```bash
# Destroy infrastructure (⚠️ DATA LOSS)
terraform destroy -var-file=sit.tfvars
```

## Related Documentation

- [ECS Tenant Module](../../modules/ecs-tenant/README.md)
- [Database Module](../../modules/database/README.md)
- [DNS-CloudFront Module](../../modules/dns-cloudfront/README.md)
- [Pipeline Design](../../../../2_bbws_agents/devops/design/TENANT_DEPLOYMENT_PIPELINE_DESIGN.md)
