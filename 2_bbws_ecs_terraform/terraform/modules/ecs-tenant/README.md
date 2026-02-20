# ECS Tenant Module

Terraform module for deploying a single WordPress tenant on ECS Fargate with isolated storage and database credentials.

## Features

- **Isolated Storage**: Per-tenant EFS access point with www-data ownership
- **Secure Credentials**: Auto-generated database password stored in Secrets Manager
- **Load Balancing**: ALB target group and host-based routing rule
- **Health Monitoring**: Configurable health checks for high availability
- **CloudWatch Logging**: Centralized container logs with tenant-specific stream prefix
- **ECS Exec Support**: Optional debugging access to running containers

## Resources Created

1. **Random Password** - 24-character password for database
2. **Secrets Manager Secret** - Database credentials (username, password, host, port, database)
3. **EFS Access Point** - Isolated `/tenant_name` directory with proper permissions
4. **ECS Task Definition** - WordPress container with environment variables and secrets
5. **ALB Target Group** - Health checks and deregistration delay
6. **ALB Listener Rule** - Host-based routing with configurable priority
7. **ECS Service** - Fargate service with load balancer integration

## Usage

### Basic Example

```hcl
module "goldencrust_tenant" {
  source = "../../modules/ecs-tenant"

  # Tenant Identity
  tenant_name  = "goldencrust"
  environment  = "sit"
  domain_name  = "goldencrust.wpsit.kimmyai.io"
  alb_priority = 140

  # Shared Infrastructure
  vpc_id                       = aws_vpc.main.id
  cluster_id                   = aws_ecs_cluster.main.id
  efs_id                       = aws_efs_file_system.main.id
  rds_endpoint                 = aws_db_instance.main.address
  alb_listener_arn             = aws_lb_listener.http.arn
  private_subnet_ids           = aws_subnet.private[*].id
  ecs_security_group_ids       = [aws_security_group.ecs_tasks.id]
  ecs_task_execution_role_arn  = aws_iam_role.ecs_task_execution.arn
  ecs_task_role_arn            = aws_iam_role.ecs_task.arn
  cloudwatch_log_group_name    = aws_cloudwatch_log_group.ecs.name
  aws_region                   = var.aws_region

  # Docker Image
  wordpress_image = "536580886816.dkr.ecr.eu-west-1.amazonaws.com/sit-wordpress:latest"

  # Optional: Enable debugging
  enable_ecs_exec  = true
  wordpress_debug  = true

  tags = {
    Project = "BBWS"
    ManagedBy = "Terraform"
  }
}
```

### Production Example with Custom Configuration

```hcl
module "premierprop_tenant" {
  source = "../../modules/ecs-tenant"

  # Tenant Identity
  tenant_name  = "premierprop"
  environment  = "prod"
  domain_name  = "premierprop.wp.kimmyai.io"
  alb_priority = 200

  # Shared Infrastructure (same as basic example)
  vpc_id                       = aws_vpc.main.id
  cluster_id                   = aws_ecs_cluster.main.id
  efs_id                       = aws_efs_file_system.main.id
  rds_endpoint                 = aws_db_instance.main.address
  alb_listener_arn             = aws_lb_listener.http.arn
  private_subnet_ids           = aws_subnet.private[*].id
  ecs_security_group_ids       = [aws_security_group.ecs_tasks.id]
  ecs_task_execution_role_arn  = aws_iam_role.ecs_task_execution.arn
  ecs_task_role_arn            = aws_iam_role.ecs_task.arn
  cloudwatch_log_group_name    = aws_cloudwatch_log_group.ecs.name
  aws_region                   = var.aws_region
  wordpress_image              = local.wordpress_image

  # Production Configuration
  task_cpu       = 512
  task_memory    = 1024
  desired_count  = 2

  # Custom Health Checks
  health_check_interval            = 60
  health_check_healthy_threshold   = 3
  health_check_unhealthy_threshold = 2

  # Deployment Strategy
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  # Disable debugging in production
  enable_ecs_exec = false
  wordpress_debug = false

  tags = {
    Project     = "BBWS"
    Environment = "prod"
    Tenant      = "premierprop"
    ManagedBy   = "Terraform"
  }
}
```

### With Additional Environment Variables

```hcl
module "nexgentech_tenant" {
  source = "../../modules/ecs-tenant"

  # ... (same as basic example)

  additional_environment_vars = [
    {
      name  = "WORDPRESS_CONFIG_EXTRA_CUSTOM"
      value = "define('WP_MEMORY_LIMIT', '256M');"
    },
    {
      name  = "PHP_MAX_EXECUTION_TIME"
      value = "300"
    }
  ]
}
```

## Outputs

### Service Information
- `service_name` - ECS service name
- `service_id` - ECS service ARN
- `task_definition_arn` - Task definition ARN with revision

### Database
- `db_secret_arn` - Secrets Manager secret ARN
- `db_secret_name` - Secret name
- `db_username` - Database username (e.g., `goldencrust_user`)
- `db_name` - Database name (e.g., `goldencrust_db`)

### Storage
- `efs_access_point_id` - EFS access point ID
- `efs_access_point_arn` - EFS access point ARN

### Load Balancer
- `target_group_arn` - ALB target group ARN
- `target_group_name` - Target group name
- `listener_rule_arn` - Listener rule ARN
- `listener_rule_priority` - Listener rule priority

### Tenant Configuration
- `tenant_name` - Tenant identifier
- `domain_name` - Full domain name
- `tenant_url` - HTTPS URL (e.g., `https://goldencrust.wpsit.kimmyai.io`)
- `tenant_config` - Complete configuration object (JSON-serializable)

## Requirements

### Prerequisites

1. **VPC with Subnets** - Public and private subnets configured
2. **ECS Cluster** - Fargate-compatible cluster
3. **EFS File System** - Shared storage with appropriate mount targets
4. **RDS Instance** - MySQL database instance
5. **ALB with HTTP Listener** - Application Load Balancer configured
6. **IAM Roles** - Task execution and task roles with proper permissions
7. **Security Groups** - ECS tasks security group allowing ALB → ECS traffic
8. **CloudWatch Log Group** - For container logs

### IAM Permissions

**ECS Task Execution Role** requires:
- `secretsmanager:GetSecretValue` - Read database credentials
- `ecr:GetAuthorizationToken`, `ecr:BatchCheckLayerAvailability`, `ecr:GetDownloadUrlForLayer`, `ecr:BatchGetImage` - Pull Docker images
- `logs:CreateLogStream`, `logs:PutLogEvents` - Write logs

**ECS Task Role** requires:
- `elasticfilesystem:ClientMount`, `elasticfilesystem:ClientWrite` - EFS access
- Additional permissions based on WordPress plugins/functionality

## Domain Configuration

The module expects the domain to follow this pattern:
- **DEV**: `{tenant}.wpdev.kimmyai.io`
- **SIT**: `{tenant}.wpsit.kimmyai.io`
- **PROD**: `{tenant}.wp.kimmyai.io`

WordPress environment variables `WP_HOME` and `WP_SITEURL` are automatically set to `https://{domain_name}`.

## ALB Priority Management

Each tenant **must** have a unique ALB priority. Suggested ranges:
- **DEV**: 10-999
- **SIT**: 140-1139 (offset by 140 from DEV)
- **PROD**: 1000-9999

**Conflict Prevention**: Use the `check-priority-conflict` GitHub Action before deployment.

## Database Setup

This module **creates the Secrets Manager secret** but does **not** create the database itself. The database must be created separately using:
1. Python script: `utils/init_tenant_db.py`
2. Terraform database module (see `modules/database/`)
3. Manual creation via RDS

## Health Checks

### ALB Health Check
- Path: `/` (configurable)
- Interval: 30s (configurable)
- Timeout: 5s (configurable)
- Healthy threshold: 2 consecutive successes
- Unhealthy threshold: 3 consecutive failures
- Matcher: `200,301,302` (WordPress redirects are healthy)

### Container Health Check
- Command: `curl -f http://localhost/ || exit 1`
- Interval: 30s
- Timeout: 5s
- Retries: 3
- Start period: 60s

## Troubleshooting

### Service Not Starting
```bash
# Check task status
aws ecs list-tasks --cluster sit-cluster --service-name sit-goldencrust-service --profile Tebogo-sit

# Describe task to see stopped reason
aws ecs describe-tasks --cluster sit-cluster --tasks <task-arn> --profile Tebogo-sit
```

### Database Connection Issues
```bash
# Get database credentials
aws secretsmanager get-secret-value \
  --secret-id sit-goldencrust-db-credentials \
  --profile Tebogo-sit \
  --query SecretString \
  --output text | jq .
```

### EFS Mount Issues
```bash
# Check EFS access point
aws efs describe-access-points \
  --access-point-id <access-point-id> \
  --profile Tebogo-sit
```

### View Container Logs
```bash
# Stream logs
aws logs tail /ecs/sit-cluster --follow \
  --filter-pattern "goldencrust" \
  --profile Tebogo-sit
```

## Inputs Reference

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| tenant_name | Unique tenant identifier | string | - | yes |
| environment | Environment (dev/sit/prod) | string | - | yes |
| domain_name | Full domain name | string | - | yes |
| alb_priority | ALB rule priority (1-50000) | number | - | yes |
| vpc_id | VPC ID | string | - | yes |
| cluster_id | ECS cluster ID | string | - | yes |
| efs_id | EFS file system ID | string | - | yes |
| rds_endpoint | RDS endpoint | string | - | yes |
| task_cpu | Task CPU units | number | 256 | no |
| task_memory | Task memory (MB) | number | 512 | no |
| desired_count | Desired task count | number | 1 | no |
| wordpress_debug | Enable debug mode | bool | false | no |

See `variables.tf` for complete list.

## Related Documentation

- [Pipeline Design](../../../../2_bbws_agents/devops/design/TENANT_DEPLOYMENT_PIPELINE_DESIGN.md)
- [Database Module](../database/README.md)
- [DNS-CloudFront Module](../dns-cloudfront/README.md)

## Version

- **Terraform**: >= 1.5.0
- **AWS Provider**: ~> 5.0
- **Random Provider**: ~> 3.5
