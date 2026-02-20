#!/bin/bash
#
# Generate SIT Tenant Terraform File
#
# This script generates a SIT-specific Terraform file for a tenant by copying
# the DEV tenant file and replacing environment-specific values.
#
# Usage: ./generate_sit_tenant_tf.sh <tenant_name> <alb_priority>
#
# Example: ./generate_sit_tenant_tf.sh goldencrust 140
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
    echo "Usage: $0 <tenant_name> <alb_priority>"
    echo ""
    echo "Examples:"
    echo "  $0 goldencrust 140"
    echo "  $0 tenant1 150"
    exit 1
fi

TENANT_NAME=$1
ALB_PRIORITY=$2

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$(dirname "$SCRIPT_DIR")/../2_bbws_ecs_terraform/terraform"
DEV_TENANT_FILE=""
SIT_TENANT_FILE="${TERRAFORM_DIR}/sit_${TENANT_NAME}.tf"

# Determine source DEV file
if [ "$TENANT_NAME" = "tenant1" ]; then
    # tenant1 is defined in alb.tf, not separate file
    DEV_TENANT_FILE="${TERRAFORM_DIR}/ecs.tf"
elif [ "$TENANT_NAME" = "tenant2" ]; then
    DEV_TENANT_FILE="${TERRAFORM_DIR}/tenant2.tf"
else
    DEV_TENANT_FILE="${TERRAFORM_DIR}/${TENANT_NAME}.tf"
fi

# Validate source file exists
if [ ! -f "$DEV_TENANT_FILE" ]; then
    echo -e "${RED}Error: Source DEV tenant file not found: $DEV_TENANT_FILE${NC}"
    echo "Available tenant files:"
    ls -1 "$TERRAFORM_DIR"/*.tf | grep -v "^sit_" | head -20
    exit 1
fi

echo -e "${GREEN}=== Generating SIT Terraform File ===${NC}"
echo "Tenant: $TENANT_NAME"
echo "ALB Priority: $ALB_PRIORITY"
echo "Source: $DEV_TENANT_FILE"
echo "Output: $SIT_TENANT_FILE"
echo ""

# Special handling for tenant1 (extract from ecs.tf)
if [ "$TENANT_NAME" = "tenant1" ]; then
    echo -e "${YELLOW}Note: tenant1 resources are in ecs.tf, extracting relevant sections...${NC}"

    # Create temporary file with tenant1-specific resources
    cat > "$SIT_TENANT_FILE" <<'EOF'
# SIT Tenant: tenant1 (tenant-1)
# Auto-generated from DEV configuration
# Generated: $(date)

# Random password for tenant-1 database
resource "random_password" "sit_tenant_1_db" {
  length  = 24
  special = false
}

# Secrets Manager secret for tenant-1 database credentials
resource "aws_secretsmanager_secret" "sit_tenant_1_db" {
  name        = "sit-tenant-1-db-credentials"
  description = "Database credentials for tenant-1 in SIT"

  tags = {
    Name        = "sit-tenant-1-db-credentials"
    Environment = "sit"
    Tenant      = "tenant-1"
  }
}

resource "aws_secretsmanager_secret_version" "sit_tenant_1_db" {
  secret_id = aws_secretsmanager_secret.sit_tenant_1_db.id
  secret_string = jsonencode({
    username = "tenant_1_user"
    password = random_password.sit_tenant_1_db.result
    database = "tenant_1_db"
    host     = aws_db_instance.main.address
    port     = 3306
  })
}

# EFS Access Point for tenant-1
resource "aws_efs_access_point" "sit_tenant_1" {
  file_system_id = aws_efs_file_system.main.id

  root_directory {
    path = "/tenant-1"
    creation_info {
      owner_gid   = 33  # www-data
      owner_uid   = 33
      permissions = "755"
    }
  }

  posix_user {
    gid = 33
    uid = 33
  }

  tags = {
    Name        = "sit-tenant-1-ap"
    Environment = "sit"
    Tenant      = "tenant-1"
  }
}

# ECS Task Definition for tenant-1
resource "aws_ecs_task_definition" "sit_tenant_1" {
  family                   = "sit-tenant-1"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.ecs_task_cpu
  memory                   = var.ecs_task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([{
    name      = "wordpress"
    image     = local.wordpress_image
    essential = true

    portMappings = [{
      containerPort = 80
      protocol      = "tcp"
    }]

    environment = [
      {
        name  = "WORDPRESS_DB_HOST"
        value = aws_db_instance.main.address
      },
      {
        name  = "WORDPRESS_DB_NAME"
        value = "tenant_1_db"
      },
      {
        name  = "WORDPRESS_TABLE_PREFIX"
        value = "wp_"
      },
      {
        name  = "WORDPRESS_CONFIG_EXTRA"
        value = <<-EOT
          if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
              $_SERVER['HTTPS'] = 'on';
          }
          if (isset($_SERVER['HTTP_CLOUDFRONT_FORWARDED_PROTO']) && $_SERVER['HTTP_CLOUDFRONT_FORWARDED_PROTO'] === 'https') {
              $_SERVER['HTTPS'] = 'on';
          }
          define('FORCE_SSL_ADMIN', true);
          define('WP_HOME', 'https://tenant1.wpsit.kimmyai.io');
          define('WP_SITEURL', 'https://tenant1.wpsit.kimmyai.io');
        EOT
      }
    ]

    secrets = [
      {
        name      = "WORDPRESS_DB_USER"
        valueFrom = "${aws_secretsmanager_secret.sit_tenant_1_db.arn}:username::"
      },
      {
        name      = "WORDPRESS_DB_PASSWORD"
        valueFrom = "${aws_secretsmanager_secret.sit_tenant_1_db.arn}:password::"
      }
    ]

    mountPoints = [{
      sourceVolume  = "wp-content"
      containerPath = "/var/www/html/wp-content"
      readOnly      = false
    }]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "tenant-1"
      }
    }
  }])

  volume {
    name = "wp-content"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.main.id
      transit_encryption = "ENABLED"

      authorization_config {
        access_point_id = aws_efs_access_point.sit_tenant_1.id
        iam             = "ENABLED"
      }
    }
  }

  tags = {
    Name        = "sit-tenant-1-task"
    Environment = "sit"
    Tenant      = "tenant-1"
  }
}

# ECS Service for tenant-1
resource "aws_ecs_service" "sit_tenant_1" {
  name            = "sit-tenant-1-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.sit_tenant_1.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.sit_tenant_1.arn
    container_name   = "wordpress"
    container_port   = 80
  }

  depends_on = [
    aws_lb_listener.http,
    aws_efs_mount_target.main
  ]

  tags = {
    Name        = "sit-tenant-1-service"
    Environment = "sit"
    Tenant      = "tenant-1"
  }
}

# Target Group for tenant-1
resource "aws_lb_target_group" "sit_tenant_1" {
  name        = "sit-tenant-1-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200,301,302"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }

  deregistration_delay = 30

  tags = {
    Name        = "sit-tenant-1-tg"
    Environment = "sit"
    Tenant      = "tenant-1"
  }
}

# ALB Listener Rule for tenant-1
resource "aws_lb_listener_rule" "sit_tenant_1" {
  listener_arn = aws_lb_listener.http.arn
  priority     = ALB_PRIORITY_PLACEHOLDER

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sit_tenant_1.arn
  }

  condition {
    host_header {
      values = ["tenant1.wpsit.kimmyai.io"]
    }
  }

  tags = {
    Name        = "sit-tenant-1-rule"
    Environment = "sit"
    Tenant      = "tenant-1"
  }
}
EOF

    # Replace placeholder with actual priority
    sed -i.bak "s/ALB_PRIORITY_PLACEHOLDER/$ALB_PRIORITY/g" "$SIT_TENANT_FILE"
    rm "${SIT_TENANT_FILE}.bak"

    echo -e "${GREEN}✓ Generated $SIT_TENANT_FILE${NC}"
    exit 0
fi

# For all other tenants, use template-based approach
echo "Reading source file and applying transformations..."

# Read source file and apply substitutions
cat "$DEV_TENANT_FILE" | \
  # Replace resource names with sit_ prefix
  sed "s/resource \"random_password\" \"${TENANT_NAME}_db\"/resource \"random_password\" \"sit_${TENANT_NAME}_db\"/g" | \
  sed "s/resource \"aws_secretsmanager_secret\" \"${TENANT_NAME}_db\"/resource \"aws_secretsmanager_secret\" \"sit_${TENANT_NAME}_db\"/g" | \
  sed "s/resource \"aws_secretsmanager_secret_version\" \"${TENANT_NAME}_db\"/resource \"aws_secretsmanager_secret_version\" \"sit_${TENANT_NAME}_db\"/g" | \
  sed "s/resource \"aws_efs_access_point\" \"${TENANT_NAME}\"/resource \"aws_efs_access_point\" \"sit_${TENANT_NAME}\"/g" | \
  sed "s/resource \"aws_ecs_task_definition\" \"${TENANT_NAME}\"/resource \"aws_ecs_task_definition\" \"sit_${TENANT_NAME}\"/g" | \
  sed "s/resource \"aws_ecs_service\" \"${TENANT_NAME}\"/resource \"aws_ecs_service\" \"sit_${TENANT_NAME}\"/g" | \
  sed "s/resource \"aws_lb_target_group\" \"${TENANT_NAME}\"/resource \"aws_lb_target_group\" \"sit_${TENANT_NAME}\"/g" | \
  sed "s/resource \"aws_lb_listener_rule\" \"${TENANT_NAME}\"/resource \"aws_lb_listener_rule\" \"sit_${TENANT_NAME}\"/g" | \
  # Replace resource references
  sed "s/random_password\.${TENANT_NAME}_db/random_password.sit_${TENANT_NAME}_db/g" | \
  sed "s/aws_secretsmanager_secret\.${TENANT_NAME}_db/aws_secretsmanager_secret.sit_${TENANT_NAME}_db/g" | \
  sed "s/aws_secretsmanager_secret_version\.${TENANT_NAME}_db/aws_secretsmanager_secret_version.sit_${TENANT_NAME}_db/g" | \
  sed "s/aws_efs_access_point\.${TENANT_NAME}/aws_efs_access_point.sit_${TENANT_NAME}/g" | \
  sed "s/aws_ecs_task_definition\.${TENANT_NAME}/aws_ecs_task_definition.sit_${TENANT_NAME}/g" | \
  sed "s/aws_ecs_service\.${TENANT_NAME}/aws_ecs_service.sit_${TENANT_NAME}/g" | \
  sed "s/aws_lb_target_group\.${TENANT_NAME}/aws_lb_target_group.sit_${TENANT_NAME}/g" | \
  sed "s/aws_lb_listener_rule\.${TENANT_NAME}/aws_lb_listener_rule.sit_${TENANT_NAME}/g" | \
  # Replace environment variables
  sed 's/${var\.environment}/sit/g' | \
  sed "s/\${var\.environment}-${TENANT_NAME}/sit-${TENANT_NAME}/g" | \
  sed "s/dev-${TENANT_NAME}/sit-${TENANT_NAME}/g" | \
  # Replace domains
  sed "s/${TENANT_NAME}\.wpdev\.kimmyai\.io/${TENANT_NAME}.wpsit.kimmyai.io/g" | \
  # Replace secret names
  sed "s/dev-${TENANT_NAME}-db-credentials/sit-${TENANT_NAME}-db-credentials/g" | \
  # Replace ALB priority (capture existing priority and replace with new one)
  sed "s/priority[[:space:]]*=[[:space:]]*[0-9]*/priority     = $ALB_PRIORITY/g" | \
  # Add header comment
  sed "1i\\
# SIT Tenant: $TENANT_NAME\\
# Auto-generated from DEV configuration: $DEV_TENANT_FILE\\
# Generated: $(date '+%Y-%m-%d %H:%M:%S')\\
# ALB Priority: $ALB_PRIORITY\\
" \
  > "$SIT_TENANT_FILE"

# Validate output file was created
if [ ! -f "$SIT_TENANT_FILE" ]; then
    echo -e "${RED}Error: Failed to create output file${NC}"
    exit 1
fi

# Check file size
FILE_SIZE=$(wc -l < "$SIT_TENANT_FILE")
if [ "$FILE_SIZE" -lt 50 ]; then
    echo -e "${YELLOW}Warning: Generated file seems small ($FILE_SIZE lines). Please review.${NC}"
fi

echo -e "${GREEN}✓ Successfully generated $SIT_TENANT_FILE${NC}"
echo -e "${GREEN}✓ File size: $FILE_SIZE lines${NC}"
echo ""
echo "Next steps:"
echo "1. Review the generated file: cat $SIT_TENANT_FILE"
echo "2. Run terraform fmt: cd $TERRAFORM_DIR && terraform fmt sit_${TENANT_NAME}.tf"
echo "3. Validate syntax: cd $TERRAFORM_DIR && terraform validate"
echo ""
echo -e "${GREEN}Generation complete!${NC}"
