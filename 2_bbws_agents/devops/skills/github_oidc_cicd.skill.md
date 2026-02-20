# GitHub OIDC and CI/CD Pipeline Setup Skill

**Version**: 1.0
**Created**: 2025-12-26
**Type**: Infrastructure / DevOps / CI/CD
**Purpose**: Setup GitHub Actions with AWS OIDC authentication and deploy infrastructure across multiple AWS services

---

## Purpose

This skill provides comprehensive guidance for setting up GitHub Actions with AWS OIDC (OpenID Connect) authentication and deploying infrastructure to AWS. It covers the complete setup process from OIDC provider configuration through multi-service deployment (S3, Lambda, ECS, CloudFront, Route53) with proper validation and troubleshooting.

**Use this skill when:**
- Setting up GitHub Actions for AWS deployments
- Implementing secure CI/CD without long-lived access keys
- Deploying infrastructure to multiple AWS environments (DEV/SIT/PROD)
- Troubleshooting OIDC authentication issues
- Configuring Terraform backends for GitHub Actions
- Validating AWS resource deployments

**This skill solves:**
- OIDC trust policy configuration errors
- IAM permission issues for GitHub Actions
- Terraform backend state management
- Multi-environment deployment challenges
- Resource validation and verification

---

## Prerequisites

### Required Access
- AWS account access with IAM admin permissions
- GitHub repository admin access
- AWS CLI configured locally
- GitHub CLI (`gh`) installed
- Terraform knowledge (basic to intermediate)

### Required Tools
```bash
# Verify tools are installed
aws --version          # AWS CLI v2
gh --version           # GitHub CLI
terraform --version    # Terraform >= 1.6.0
```

### Environment Context
This skill integrates with the **3-environment promotion workflow**:
- **DEV** (536580886816, eu-west-1): Development and testing
- **SIT** (815856636111, eu-west-1): Staging/integration testing
- **PROD** (093646564004, af-south-1): Production with DR in eu-west-1

**Promotion Flow**: DEV → SIT → PROD (NEVER skip SIT)

---

## Phase 1: OIDC Provider Setup

### Check if OIDC Provider Exists

Before creating resources, verify if the OIDC provider already exists:

```bash
# List OIDC providers
aws iam list-open-id-connect-providers --profile AWSAdministratorAccess-536580886816

# Expected output if exists:
# {
#     "OpenIDConnectProviderList": [
#         {
#             "Arn": "arn:aws:iam::536580886816:oidc-provider/token.actions.githubusercontent.com"
#         }
#     ]
# }
```

### Create OIDC Provider (If Needed)

If the provider doesn't exist, create it:

```bash
# Create GitHub OIDC provider
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
  --profile AWSAdministratorAccess-536580886816

# Verify creation
aws iam list-open-id-connect-providers --profile AWSAdministratorAccess-536580886816
```

**Note**: The thumbprint is GitHub's certificate thumbprint and should remain constant unless GitHub changes their certificate.

---

## Phase 2: IAM Role Creation

### Create GitHub Actions IAM Role

Create an IAM role that GitHub Actions will assume via OIDC:

```bash
# Create trust policy file
cat > github-actions-trust-policy.json <<'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::536580886816:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:BigBeardWebSolutions/*"
        }
      }
    }
  ]
}
EOF

# Create the role
aws iam create-role \
  --role-name github-actions-role-dev \
  --assume-role-policy-document file://github-actions-trust-policy.json \
  --description "GitHub Actions OIDC role for DEV deployments" \
  --profile AWSAdministratorAccess-536580886816

# Get the role ARN (save this for GitHub secrets)
aws iam get-role \
  --role-name github-actions-role-dev \
  --query 'Role.Arn' \
  --output text \
  --profile AWSAdministratorAccess-536580886816
```

### Trust Policy Patterns

**Pattern 1: Single Repository (Most Restrictive)**
```json
{
  "StringLike": {
    "token.actions.githubusercontent.com:sub": "repo:BigBeardWebSolutions/2_1_bbws_dynamodb_schemas:*"
  }
}
```

**Pattern 2: Multiple Specific Repositories**
```json
{
  "StringLike": {
    "token.actions.githubusercontent.com:sub": [
      "repo:BigBeardWebSolutions/2_1_bbws_dynamodb_schemas:*",
      "repo:BigBeardWebSolutions/2_1_bbws_web_public:*",
      "repo:BigBeardWebSolutions/3_forms_microservices:*"
    ]
  }
}
```

**Pattern 3: All Repositories in Organization (Recommended)**
```json
{
  "StringLike": {
    "token.actions.githubusercontent.com:sub": "repo:BigBeardWebSolutions/*"
  }
}
```

### ⚠️ CRITICAL: Organization Name Must Match Exactly

**Common Mistake:**
```json
❌ "token.actions.githubusercontent.com:sub": "repo:tsekatm/*"
```

**Correct:**
```json
✅ "token.actions.githubusercontent.com:sub": "repo:BigBeardWebSolutions/*"
```

**Verification**: Check your repository URL on GitHub:
```
https://github.com/BigBeardWebSolutions/2_1_bbws_dynamodb_schemas
                    ^^^^^^^^^^^^^^^^^^^^^^
                    This is your organization name
```

---

## Phase 3: IAM Permissions Policy

### Understanding Permission Requirements

The IAM role needs permissions for:
1. **Terraform State Management**: S3 bucket + DynamoDB table access
2. **Service Deployment**: Specific AWS service permissions
3. **Resource Management**: Create, read, update, delete operations

### Terraform Backend Permissions (CRITICAL)

**Common Error**: Missing `s3:ListBucket` permission causes Terraform init to fail.

```json
{
  "Sid": "TerraformStateAccess",
  "Effect": "Allow",
  "Action": [
    "s3:ListBucket",
    "s3:GetObject",
    "s3:PutObject",
    "s3:DeleteObject"
  ],
  "Resource": [
    "arn:aws:s3:::bbws-terraform-state-dev",
    "arn:aws:s3:::bbws-terraform-state-dev/*"
  ]
}
```

**⚠️ Common Mistake**: Resource ARN mismatch

```json
❌ "Resource": ["arn:aws:s3:::2-1-bbws-tf-terraform-state-dev/*"]
✅ "Resource": ["arn:aws:s3:::bbws-terraform-state-dev/*"]
```

**Terraform State Lock Permissions**:
```json
{
  "Sid": "TerraformStateLocking",
  "Effect": "Allow",
  "Action": [
    "dynamodb:GetItem",
    "dynamodb:PutItem",
    "dynamodb:DeleteItem",
    "dynamodb:DescribeTable"
  ],
  "Resource": [
    "arn:aws:dynamodb:*:536580886816:table/terraform-state-lock-dev"
  ]
}
```

### Complete IAM Policy Template

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "TerraformStateAccess",
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": [
        "arn:aws:s3:::bbws-terraform-state-dev",
        "arn:aws:s3:::bbws-terraform-state-dev/*"
      ]
    },
    {
      "Sid": "TerraformStateLocking",
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem",
        "dynamodb:DescribeTable"
      ],
      "Resource": [
        "arn:aws:dynamodb:*:536580886816:table/terraform-state-lock-dev"
      ]
    },
    {
      "Sid": "DynamoDBManagement",
      "Effect": "Allow",
      "Action": [
        "dynamodb:CreateTable",
        "dynamodb:DeleteTable",
        "dynamodb:DescribeTable",
        "dynamodb:UpdateTable",
        "dynamodb:ListTables",
        "dynamodb:TagResource",
        "dynamodb:UntagResource",
        "dynamodb:DescribeContinuousBackups",
        "dynamodb:UpdateContinuousBackups",
        "dynamodb:ListTagsOfResource",
        "dynamodb:DescribeTimeToLive",
        "dynamodb:UpdateTimeToLive"
      ],
      "Resource": "arn:aws:dynamodb:*:536580886816:table/*"
    },
    {
      "Sid": "S3Management",
      "Effect": "Allow",
      "Action": [
        "s3:CreateBucket",
        "s3:DeleteBucket",
        "s3:ListBucket",
        "s3:GetBucketLocation",
        "s3:GetBucketVersioning",
        "s3:PutBucketVersioning",
        "s3:GetBucketEncryption",
        "s3:PutBucketEncryption",
        "s3:GetBucketPublicAccessBlock",
        "s3:PutBucketPublicAccessBlock",
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:PutBucketPolicy",
        "s3:GetBucketPolicy",
        "s3:DeleteBucketPolicy",
        "s3:PutBucketTagging",
        "s3:GetBucketTagging"
      ],
      "Resource": [
        "arn:aws:s3:::*"
      ]
    },
    {
      "Sid": "LambdaManagement",
      "Effect": "Allow",
      "Action": [
        "lambda:CreateFunction",
        "lambda:DeleteFunction",
        "lambda:GetFunction",
        "lambda:GetFunctionConfiguration",
        "lambda:UpdateFunctionCode",
        "lambda:UpdateFunctionConfiguration",
        "lambda:ListFunctions",
        "lambda:PublishVersion",
        "lambda:CreateAlias",
        "lambda:UpdateAlias",
        "lambda:GetAlias",
        "lambda:TagResource",
        "lambda:UntagResource",
        "lambda:AddPermission",
        "lambda:RemovePermission"
      ],
      "Resource": "arn:aws:lambda:*:536580886816:function:*"
    },
    {
      "Sid": "ECSManagement",
      "Effect": "Allow",
      "Action": [
        "ecs:CreateCluster",
        "ecs:DeleteCluster",
        "ecs:DescribeClusters",
        "ecs:CreateService",
        "ecs:UpdateService",
        "ecs:DeleteService",
        "ecs:DescribeServices",
        "ecs:ListServices",
        "ecs:RegisterTaskDefinition",
        "ecs:DeregisterTaskDefinition",
        "ecs:DescribeTaskDefinition",
        "ecs:ListTaskDefinitions",
        "ecs:TagResource",
        "ecs:UntagResource"
      ],
      "Resource": "*"
    },
    {
      "Sid": "CloudFrontManagement",
      "Effect": "Allow",
      "Action": [
        "cloudfront:CreateDistribution",
        "cloudfront:GetDistribution",
        "cloudfront:UpdateDistribution",
        "cloudfront:DeleteDistribution",
        "cloudfront:ListDistributions",
        "cloudfront:CreateInvalidation",
        "cloudfront:TagResource"
      ],
      "Resource": "*"
    },
    {
      "Sid": "Route53Management",
      "Effect": "Allow",
      "Action": [
        "route53:GetHostedZone",
        "route53:ListHostedZones",
        "route53:CreateHostedZone",
        "route53:DeleteHostedZone",
        "route53:ChangeResourceRecordSets",
        "route53:GetChange",
        "route53:ListResourceRecordSets",
        "route53:ChangeTagsForResource"
      ],
      "Resource": "*"
    },
    {
      "Sid": "IAMRoleManagement",
      "Effect": "Allow",
      "Action": [
        "iam:CreateRole",
        "iam:GetRole",
        "iam:DeleteRole",
        "iam:PassRole",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:PutRolePolicy",
        "iam:DeleteRolePolicy",
        "iam:GetRolePolicy",
        "iam:TagRole",
        "iam:UntagRole"
      ],
      "Resource": "arn:aws:iam::536580886816:role/*"
    },
    {
      "Sid": "CloudWatchLogs",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:DeleteLogGroup",
        "logs:DescribeLogGroups",
        "logs:PutRetentionPolicy",
        "logs:TagLogGroup"
      ],
      "Resource": "arn:aws:logs:*:536580886816:log-group:*"
    }
  ]
}
```

### Create and Attach Policy

```bash
# Save policy to file
cat > github-actions-permissions.json <<'EOF'
[paste the JSON policy above]
EOF

# Create policy
aws iam create-policy \
  --policy-name github-actions-policy-dev \
  --policy-document file://github-actions-permissions.json \
  --description "Permissions for GitHub Actions to deploy infrastructure" \
  --profile AWSAdministratorAccess-536580886816

# Attach policy to role
aws iam attach-role-policy \
  --role-name github-actions-role-dev \
  --policy-arn arn:aws:iam::536580886816:policy/github-actions-policy-dev \
  --profile AWSAdministratorAccess-536580886816

# Verify attachment
aws iam list-attached-role-policies \
  --role-name github-actions-role-dev \
  --profile AWSAdministratorAccess-536580886816
```

### Update Existing Policy

If you need to update permissions later:

```bash
# Create new policy version
aws iam create-policy-version \
  --policy-arn arn:aws:iam::536580886816:policy/github-actions-policy-dev \
  --policy-document file://github-actions-permissions.json \
  --set-as-default \
  --profile AWSAdministratorAccess-536580886816
```

---

## Phase 4: GitHub Secrets Configuration

### Set IAM Role ARN as GitHub Secret

GitHub Actions needs the IAM role ARN to authenticate:

```bash
# Get the role ARN
ROLE_ARN=$(aws iam get-role \
  --role-name github-actions-role-dev \
  --query 'Role.Arn' \
  --output text \
  --profile AWSAdministratorAccess-536580886816)

echo "Role ARN: $ROLE_ARN"

# Set GitHub secret
gh secret set AWS_ROLE_DEV --body "$ROLE_ARN"

# Verify secret is set
gh secret list
```

### Multi-Environment Secret Pattern

For multiple environments, create separate secrets:

```bash
# DEV environment
gh secret set AWS_ROLE_DEV --body "arn:aws:iam::536580886816:role/github-actions-role-dev"

# SIT environment
gh secret set AWS_ROLE_SIT --body "arn:aws:iam::815856636111:role/github-actions-role-sit"

# PROD environment
gh secret set AWS_ROLE_PROD --body "arn:aws:iam::093646564004:role/github-actions-role-prod"

# Verify all secrets
gh secret list
```

**Expected Output:**
```
AWS_ROLE_DEV   2025-12-26T10:00:00Z
AWS_ROLE_PROD  2025-12-26T10:00:00Z
AWS_ROLE_SIT   2025-12-26T10:00:00Z
```

---

## Phase 5: GitHub Actions Workflow Configuration

### Workflow Structure

A complete GitHub Actions workflow with OIDC authentication:

```yaml
# .github/workflows/deploy-infrastructure.yml
name: Deploy Infrastructure

on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to deploy to'
        type: choice
        required: true
        options:
          - dev
          - sit
          - prod
      component:
        description: 'Component to deploy'
        type: choice
        required: true
        options:
          - dynamodb
          - s3
          - lambda
          - ecs
          - cloudfront
          - route53
          - all

# CRITICAL: Required permissions for OIDC
permissions:
  id-token: write   # Required for AWS OIDC authentication
  contents: read    # Required to checkout code
  actions: read     # Required for artifacts

env:
  TF_VERSION: 1.6.0

jobs:
  setup:
    name: Environment Setup
    runs-on: ubuntu-latest
    outputs:
      region: ${{ steps.config.outputs.region }}
      account_id: ${{ steps.config.outputs.account_id }}
    steps:
      - name: Set environment configuration
        id: config
        run: |
          case "${{ inputs.environment }}" in
            dev)
              echo "region=eu-west-1" >> $GITHUB_OUTPUT
              echo "account_id=536580886816" >> $GITHUB_OUTPUT
              ;;
            sit)
              echo "region=eu-west-1" >> $GITHUB_OUTPUT
              echo "account_id=815856636111" >> $GITHUB_OUTPUT
              ;;
            prod)
              echo "region=af-south-1" >> $GITHUB_OUTPUT
              echo "account_id=093646564004" >> $GITHUB_OUTPUT
              ;;
          esac

  deploy:
    name: Deploy to ${{ inputs.environment }}
    runs-on: ubuntu-latest
    needs: setup
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      # OIDC Authentication
      - name: Configure AWS credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets[format('AWS_ROLE_{0}', upper(inputs.environment))] }}
          aws-region: ${{ needs.setup.outputs.region }}
          role-session-name: github-actions-deploy-${{ inputs.environment }}

      - name: Verify AWS identity
        run: |
          echo "=================================================="
          echo "AWS IDENTITY VERIFICATION"
          echo "=================================================="
          echo "Account ID: $(aws sts get-caller-identity --query Account --output text)"
          echo "Region: ${{ needs.setup.outputs.region }}"
          echo "User ARN: $(aws sts get-caller-identity --query Arn --output text)"
          echo "=================================================="

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}

      - name: Terraform init
        working-directory: terraform/${{ inputs.component }}
        run: |
          terraform init \
            -backend-config="bucket=bbws-terraform-state-${{ inputs.environment }}" \
            -backend-config="key=${{ github.repository }}/${{ inputs.component }}/terraform.tfstate" \
            -backend-config="region=${{ needs.setup.outputs.region }}" \
            -backend-config="dynamodb_table=terraform-state-lock-${{ inputs.environment }}" \
            -backend-config="encrypt=true"

      - name: Terraform plan
        working-directory: terraform/${{ inputs.component }}
        run: |
          terraform plan \
            -var-file=environments/${{ inputs.environment }}.tfvars \
            -out=tfplan \
            -no-color

      - name: Terraform apply
        working-directory: terraform/${{ inputs.component }}
        run: terraform apply -auto-approve tfplan

      - name: Capture terraform outputs
        working-directory: terraform/${{ inputs.component }}
        run: |
          terraform output -json | tee outputs.json
          terraform output
```

### Service-Specific Workflow Examples

#### DynamoDB Deployment

```yaml
# Terraform configuration
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend configuration provided via -backend-config flags
  backend "s3" {}
}

provider "aws" {
  region = var.aws_region
}

resource "aws_dynamodb_table" "main" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "PK"
  range_key    = "SK"

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  tags = {
    Environment = var.environment
    Project     = "bbws"
    ManagedBy   = "Terraform"
  }
}
```

#### S3 Bucket Deployment

```yaml
resource "aws_s3_bucket" "main" {
  bucket = "${var.project}-${var.environment}-${var.bucket_suffix}"

  tags = {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

#### Lambda Function Deployment

```yaml
resource "aws_lambda_function" "main" {
  function_name = "${var.project}-${var.environment}-${var.function_name}"
  role          = aws_iam_role.lambda.arn
  handler       = "index.handler"
  runtime       = "python3.11"
  timeout       = 30
  memory_size   = 256

  filename         = "lambda.zip"
  source_code_hash = filebase64sha256("lambda.zip")

  environment {
    variables = {
      ENVIRONMENT = var.environment
      LOG_LEVEL   = var.log_level
    }
  }

  tags = {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "Terraform"
  }
}

resource "aws_iam_role" "lambda" {
  name = "${var.project}-${var.environment}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
```

#### ECS Service Deployment

```yaml
resource "aws_ecs_cluster" "main" {
  name = "${var.project}-${var.environment}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "Terraform"
  }
}

resource "aws_ecs_task_definition" "main" {
  family                   = "${var.project}-${var.environment}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([{
    name      = var.container_name
    image     = var.container_image
    essential = true
    portMappings = [{
      containerPort = var.container_port
      protocol      = "tcp"
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/${var.project}-${var.environment}"
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])

  tags = {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "Terraform"
  }
}

resource "aws_ecs_service" "main" {
  name            = "${var.project}-${var.environment}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = var.container_name
    container_port   = var.container_port
  }

  tags = {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "Terraform"
  }
}
```

#### CloudFront Distribution Deployment

```yaml
resource "aws_cloudfront_distribution" "main" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.project}-${var.environment} distribution"
  default_root_object = "index.html"
  aliases             = var.domain_names

  origin {
    domain_name = aws_s3_bucket.main.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.main.id}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.main.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.main.id}"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "Terraform"
  }
}

resource "aws_cloudfront_origin_access_identity" "main" {
  comment = "${var.project}-${var.environment} OAI"
}
```

#### Route53 DNS Records Deployment

```yaml
resource "aws_route53_zone" "main" {
  name = var.domain_name

  tags = {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "Terraform"
  }
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.main.domain_name
    zone_id                = aws_cloudfront_distribution.main.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_health_check" "main" {
  fqdn              = var.domain_name
  port              = 443
  type              = "HTTPS"
  resource_path     = "/health"
  failure_threshold = 3
  request_interval  = 30

  tags = {
    Name        = "${var.project}-${var.environment}-health-check"
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "Terraform"
  }
}

# Failover routing for DR
resource "aws_route53_record" "primary" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  set_identifier = "primary"

  failover_routing_policy {
    type = "PRIMARY"
  }

  health_check_id = aws_route53_health_check.main.id

  alias {
    name                   = var.primary_alb_dns
    zone_id                = var.primary_alb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "secondary" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  set_identifier = "secondary"

  failover_routing_policy {
    type = "SECONDARY"
  }

  alias {
    name                   = var.secondary_alb_dns
    zone_id                = var.secondary_alb_zone_id
    evaluate_target_health = true
  }
}
```

---

## Phase 6: Terraform Backend Configuration

### The Parameterization Pattern

**CRITICAL**: Never hardcode backend configuration in `main.tf`

❌ **Wrong - Hardcoded Backend:**
```hcl
terraform {
  backend "s3" {
    bucket         = "bbws-terraform-state-dev"
    key            = "dynamodb/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "terraform-state-lock-dev"
    encrypt        = true
  }
}
```

✅ **Correct - Parameterized Backend:**
```hcl
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend configuration provided via -backend-config flags in CI/CD
  # This allows different environments (dev/sit/prod) to use different backends
  backend "s3" {}
}
```

### Workflow Backend Configuration

Provide backend configuration via workflow:

```yaml
- name: Terraform init
  working-directory: terraform/${{ inputs.component }}
  run: |
    terraform init \
      -backend-config="bucket=bbws-terraform-state-${{ inputs.environment }}" \
      -backend-config="key=${{ github.repository }}/${{ inputs.component }}/terraform.tfstate" \
      -backend-config="region=${{ needs.setup.outputs.region }}" \
      -backend-config="dynamodb_table=terraform-state-lock-${{ inputs.environment }}" \
      -backend-config="encrypt=true"
```

### Multi-Environment Backend Strategy

Each environment has its own backend:

| Environment | S3 Bucket | DynamoDB Table | Region |
|-------------|-----------|----------------|--------|
| DEV | `bbws-terraform-state-dev` | `terraform-state-lock-dev` | eu-west-1 |
| SIT | `bbws-terraform-state-sit` | `terraform-state-lock-sit` | eu-west-1 |
| PROD | `bbws-terraform-state-prod` | `terraform-state-lock-prod` | af-south-1 |

**Key Pattern**: `${{ github.repository }}/${{ inputs.component }}/terraform.tfstate`

This ensures:
- State files are organized by repository and component
- No conflicts between different projects
- Easy to locate state files

---

## Phase 7: Post-Deployment Validation (AWS Query-Based)

### Validation Strategy

Use AWS CLI queries to validate deployments (no script execution):

1. **Pre-deployment snapshot**: List existing resources
2. **Deploy infrastructure**: Run Terraform apply
3. **Post-deployment snapshot**: List resources again
4. **Compare diff**: Identify new/changed resources
5. **Validate against Terraform output**: Confirm expected resources created

### DynamoDB Validation

```bash
# Pre-deployment snapshot
echo "=== BEFORE DEPLOYMENT ==="
aws dynamodb list-tables \
  --region eu-west-1 \
  --profile AWSAdministratorAccess-536580886816 \
  --query 'TableNames' \
  --output json | tee dynamodb-before.json

# Deploy via workflow...

# Post-deployment snapshot
echo "=== AFTER DEPLOYMENT ==="
aws dynamodb list-tables \
  --region eu-west-1 \
  --profile AWSAdministratorAccess-536580886816 \
  --query 'TableNames' \
  --output json | tee dynamodb-after.json

# Verify specific table
aws dynamodb describe-table \
  --table-name tenants \
  --region eu-west-1 \
  --profile AWSAdministratorAccess-536580886816 \
  --query 'Table.{Name:TableName,Status:TableStatus,BillingMode:BillingModeSummary.BillingMode,StreamEnabled:StreamSpecification.StreamEnabled}'

# Expected output:
# {
#     "Name": "tenants",
#     "Status": "ACTIVE",
#     "BillingMode": "PAY_PER_REQUEST",
#     "StreamEnabled": true
# }
```

### S3 Validation

```bash
# Pre-deployment snapshot
echo "=== BEFORE DEPLOYMENT ==="
aws s3 ls --profile AWSAdministratorAccess-536580886816 | tee s3-before.txt

# Post-deployment snapshot
echo "=== AFTER DEPLOYMENT ==="
aws s3 ls --profile AWSAdministratorAccess-536580886816 | tee s3-after.txt

# Verify specific bucket
aws s3api get-bucket-versioning \
  --bucket bbws-dev-data \
  --profile AWSAdministratorAccess-536580886816

aws s3api get-bucket-encryption \
  --bucket bbws-dev-data \
  --profile AWSAdministratorAccess-536580886816

aws s3api get-public-access-block \
  --bucket bbws-dev-data \
  --profile AWSAdministratorAccess-536580886816
```

### Lambda Validation

```bash
# Pre-deployment snapshot
aws lambda list-functions \
  --region eu-west-1 \
  --profile AWSAdministratorAccess-536580886816 \
  --query 'Functions[].FunctionName' \
  --output json | tee lambda-before.json

# Post-deployment snapshot
aws lambda list-functions \
  --region eu-west-1 \
  --profile AWSAdministratorAccess-536580886816 \
  --query 'Functions[].FunctionName' \
  --output json | tee lambda-after.json

# Verify specific function
aws lambda get-function \
  --function-name bbws-dev-api-handler \
  --region eu-west-1 \
  --profile AWSAdministratorAccess-536580886816 \
  --query '{Name:Configuration.FunctionName,Runtime:Configuration.Runtime,State:Configuration.State,LastModified:Configuration.LastModified}'
```

### ECS Validation

```bash
# List clusters before
aws ecs list-clusters \
  --region eu-west-1 \
  --profile AWSAdministratorAccess-536580886816 | tee ecs-clusters-before.json

# List services before
aws ecs list-services \
  --cluster dev-cluster \
  --region eu-west-1 \
  --profile AWSAdministratorAccess-536580886816 | tee ecs-services-before.json

# After deployment, verify service
aws ecs describe-services \
  --cluster dev-cluster \
  --services bbws-dev-service \
  --region eu-west-1 \
  --profile AWSAdministratorAccess-536580886816 \
  --query 'services[0].{Name:serviceName,Status:status,DesiredCount:desiredCount,RunningCount:runningCount,LaunchType:launchType}'
```

### CloudFront Validation

```bash
# List distributions before
aws cloudfront list-distributions \
  --profile AWSAdministratorAccess-536580886816 \
  --query 'DistributionList.Items[].{Id:Id,DomainName:DomainName,Status:Status}' \
  --output json | tee cloudfront-before.json

# After deployment, get specific distribution
aws cloudfront get-distribution \
  --id E1234567890ABC \
  --profile AWSAdministratorAccess-536580886816 \
  --query 'Distribution.{Id:Id,Status:Status,DomainName:DomainName,Enabled:DistributionConfig.Enabled}'
```

### Route53 Validation

```bash
# List hosted zones before
aws route53 list-hosted-zones \
  --profile AWSAdministratorAccess-536580886816 \
  --query 'HostedZones[].{Name:Name,Id:Id,RecordSetCount:ResourceRecordSetCount}' | tee route53-zones-before.json

# List record sets for specific zone
aws route53 list-resource-record-sets \
  --hosted-zone-id Z1234567890ABC \
  --profile AWSAdministratorAccess-536580886816 \
  --query 'ResourceRecordSets[].{Name:Name,Type:Type,TTL:TTL}' | tee route53-records-before.json

# Verify health checks
aws route53 list-health-checks \
  --profile AWSAdministratorAccess-536580886816 \
  --query 'HealthChecks[].{Id:Id,Type:HealthCheckConfig.Type,FQDN:HealthCheckConfig.FullyQualifiedDomainName}'
```

### Terraform Output Comparison

```bash
# Get Terraform outputs after apply
cd terraform/dynamodb
terraform output -json | tee terraform-outputs.json

# Example output:
# {
#   "table_names": {
#     "value": ["tenants", "products", "campaigns"]
#   },
#   "table_arns": {
#     "value": {
#       "tenants": "arn:aws:dynamodb:eu-west-1:536580886816:table/tenants"
#     }
#   }
# }

# Compare with AWS CLI results
# The table names from Terraform output should match the new tables in dynamodb-after.json
```

---

## Troubleshooting Guide

### Error: "Not authorized to perform sts:AssumeRoleWithWebIdentity"

**Symptom:**
```
Error: Could not assume role with OIDC: Not authorized to perform sts:AssumeRoleWithWebIdentity
```

**Root Causes:**

1. **Organization Name Mismatch** (Most Common)

```bash
# Check your repository URL
echo "Repository: https://github.com/BigBeardWebSolutions/2_1_bbws_dynamodb_schemas"
#                                    ^^^^^^^^^^^^^^^^^^^^^^
#                                    This is your organization

# Verify trust policy
aws iam get-role \
  --role-name github-actions-role-dev \
  --query 'Role.AssumeRolePolicyDocument.Statement[0].Condition.StringLike' \
  --profile AWSAdministratorAccess-536580886816

# Should show:
# {
#     "token.actions.githubusercontent.com:sub": "repo:BigBeardWebSolutions/*"
# }

# If it shows wrong organization (e.g., "repo:tsekatm/*"), update it:
aws iam update-assume-role-policy \
  --role-name github-actions-role-dev \
  --policy-document file://corrected-trust-policy.json \
  --profile AWSAdministratorAccess-536580886816
```

2. **GitHub Secret Not Set**

```bash
# Check if secret exists
gh secret list | grep AWS_ROLE

# If missing, set it:
gh secret set AWS_ROLE_DEV --body "arn:aws:iam::536580886816:role/github-actions-role-dev"
```

3. **Repository Not in Trust Policy**

```bash
# Get current trust policy
aws iam get-role \
  --role-name github-actions-role-dev \
  --query 'Role.AssumeRolePolicyDocument' \
  --profile AWSAdministratorAccess-536580886816

# Verify repository pattern matches:
# "repo:BigBeardWebSolutions/2_1_bbws_dynamodb_schemas:*"  (specific repo)
# OR
# "repo:BigBeardWebSolutions/*"  (all repos in org)
```

### Error: "Failed to get existing workspaces" (Terraform S3 Backend)

**Symptom:**
```
Error: Failed to get existing workspaces: Unable to list objects in S3 bucket "bbws-terraform-state-dev":
operation error S3: ListObjectsV2, https response error StatusCode: 403,
api error AccessDenied: User is not authorized to perform: s3:ListBucket
```

**Root Cause:** Missing `s3:ListBucket` permission

**Solution:**

```bash
# Check current IAM policy
aws iam get-policy-version \
  --policy-arn arn:aws:iam::536580886816:policy/github-actions-policy-dev \
  --version-id v1 \
  --query 'PolicyVersion.Document' \
  --profile AWSAdministratorAccess-536580886816

# Verify it includes:
# {
#   "Action": [
#     "s3:ListBucket",    <-- CRITICAL: Must be present
#     "s3:GetObject",
#     "s3:PutObject",
#     "s3:DeleteObject"
#   ],
#   "Resource": [
#     "arn:aws:s3:::bbws-terraform-state-dev",      <-- Bucket ARN for ListBucket
#     "arn:aws:s3:::bbws-terraform-state-dev/*"     <-- Object ARN for other actions
#   ]
# }

# If missing, add the permission and create new policy version
# (See Phase 3: IAM Permissions Policy for complete policy)
```

**⚠️ Common Mistake:**

```json
❌ Wrong - Missing ListBucket on bucket ARN:
{
  "Action": ["s3:GetObject", "s3:PutObject"],
  "Resource": ["arn:aws:s3:::bbws-terraform-state-dev/*"]
}

✅ Correct - ListBucket on bucket, other actions on objects:
{
  "Action": ["s3:ListBucket"],
  "Resource": ["arn:aws:s3:::bbws-terraform-state-dev"]
},
{
  "Action": ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"],
  "Resource": ["arn:aws:s3:::bbws-terraform-state-dev/*"]
}
```

### Error: "AccessDenied" on DynamoDB State Lock

**Symptom:**
```
Error: Error acquiring the state lock: AccessDeniedException: User is not authorized to perform:
dynamodb:PutItem on resource: arn:aws:dynamodb:eu-west-1:536580886816:table/terraform-state-lock-dev
```

**Root Cause:** Missing DynamoDB permissions for state locking

**Solution:**

```bash
# Verify DynamoDB table exists
aws dynamodb describe-table \
  --table-name terraform-state-lock-dev \
  --region eu-west-1 \
  --profile AWSAdministratorAccess-536580886816

# Check IAM policy includes DynamoDB permissions
# Required actions:
# - dynamodb:GetItem
# - dynamodb:PutItem
# - dynamodb:DeleteItem
# - dynamodb:DescribeTable

# Add to policy if missing (see Phase 3)
```

### Error: Terraform Init Fails with Backend Config

**Symptom:**
```
Error: Backend configuration changed
A change in the backend configuration has been detected
```

**Root Cause:** Hardcoded backend in `main.tf` conflicts with `-backend-config` flags

**Solution:**

```hcl
# Remove hardcoded backend configuration from main.tf

❌ Remove this:
terraform {
  backend "s3" {
    bucket         = "bbws-terraform-state-dev"
    key            = "dynamodb/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "terraform-state-lock-dev"
    encrypt        = true
  }
}

✅ Replace with:
terraform {
  # Backend configuration provided via -backend-config flags in CI/CD
  backend "s3" {}
}
```

### Error: Wrong Region Selected

**Symptom:**
Resources not found or deployment fails in wrong region

**Verification:**

```bash
# Check environment-region mapping (from aws_region_specification.skill.md)
DEV:  eu-west-1 (Ireland)
SIT:  eu-west-1 (Ireland)
PROD: af-south-1 (Cape Town)

# Verify workflow sets correct region
case "${{ inputs.environment }}" in
  dev|sit)
    echo "region=eu-west-1" >> $GITHUB_OUTPUT
    ;;
  prod)
    echo "region=af-south-1" >> $GITHUB_OUTPUT
    ;;
esac
```

### Error: Resource ARN Mismatch

**Symptom:**
```
AccessDenied: User is not authorized to perform action on resource "arn:aws:s3:::incorrect-bucket-name"
```

**Root Cause:** IAM policy references wrong resource name

**Solution:**

```bash
# Verify actual resource names in AWS
aws s3 ls --profile AWSAdministratorAccess-536580886816
aws dynamodb list-tables --region eu-west-1 --profile AWSAdministratorAccess-536580886816

# Common mistakes:
❌ "arn:aws:s3:::2-1-bbws-tf-terraform-state-dev"
✅ "arn:aws:s3:::bbws-terraform-state-dev"

❌ "arn:aws:dynamodb:*:536580886816:table/2-1-bbws-tf-terraform-locks-dev"
✅ "arn:aws:dynamodb:*:536580886816:table/terraform-state-lock-dev"

# Update IAM policy with correct resource ARNs
aws iam create-policy-version \
  --policy-arn arn:aws:iam::536580886816:policy/github-actions-policy-dev \
  --policy-document file://corrected-policy.json \
  --set-as-default \
  --profile AWSAdministratorAccess-536580886816
```

---

## Multi-Environment Strategy & Promotion Workflow

### Three Environments

| Environment | AWS Account | Primary Region | Purpose |
|-------------|-------------|----------------|---------|
| **DEV** | 536580886816 | eu-west-1 | Development and testing |
| **SIT** | 815856636111 | eu-west-1 | Staging/integration testing |
| **PROD** | 093646564004 | af-south-1 | Production with DR in eu-west-1 |

### Promotion Workflow (CRITICAL)

```
┌─────────────────────────────────────────────────────────────┐
│                  PROMOTION WORKFLOW                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. DEV: Fix defects and develop features                  │
│     ↓                                                       │
│  2. DEV: Test and validate                                 │
│     ↓                                                       │
│  3. Promote to SIT (REQUIRED)                              │
│     ↓                                                       │
│  4. SIT: Integration testing                               │
│     ↓                                                       │
│  5. Promote to PROD (Only after SIT validation)            │
│     ↓                                                       │
│  6. PROD: Read-only validation                             │
│                                                             │
│  ❌ NEVER deploy directly to PROD without SIT testing      │
└─────────────────────────────────────────────────────────────┘
```

### Region Mapping

From `aws_region_specification.skill.md`:

```bash
# Helper function for region selection
get_region_for_env() {
  case "$1" in
    dev|DEV)
      echo "eu-west-1"
      ;;
    sit|SIT)
      echo "eu-west-1"
      ;;
    prod|PROD)
      echo "af-south-1"
      ;;
    *)
      echo "ERROR: Unknown environment: $1" >&2
      return 1
      ;;
  esac
}

# Usage in workflow
REGION=$(get_region_for_env ${{ inputs.environment }})
```

### Parameterized Workflow for Multi-Environment

```yaml
name: Multi-Environment Deploy

on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Target environment'
        type: choice
        required: true
        options:
          - dev
          - sit
          - prod

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: ${{ inputs.environment }}  # Uses GitHub environment protection rules

    steps:
      - name: Set environment config
        id: config
        run: |
          case "${{ inputs.environment }}" in
            dev)
              echo "region=eu-west-1" >> $GITHUB_OUTPUT
              echo "account=536580886816" >> $GITHUB_OUTPUT
              echo "role_secret=AWS_ROLE_DEV" >> $GITHUB_OUTPUT
              ;;
            sit)
              echo "region=eu-west-1" >> $GITHUB_OUTPUT
              echo "account=815856636111" >> $GITHUB_OUTPUT
              echo "role_secret=AWS_ROLE_SIT" >> $GITHUB_OUTPUT
              ;;
            prod)
              echo "region=af-south-1" >> $GITHUB_OUTPUT
              echo "account=093646564004" >> $GITHUB_OUTPUT
              echo "role_secret=AWS_ROLE_PROD" >> $GITHUB_OUTPUT
              ;;
          esac

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets[steps.config.outputs.role_secret] }}
          aws-region: ${{ steps.config.outputs.region }}

      - name: Deploy
        run: |
          terraform init \
            -backend-config="bucket=bbws-terraform-state-${{ inputs.environment }}" \
            -backend-config="region=${{ steps.config.outputs.region }}"
          terraform apply -var-file=environments/${{ inputs.environment }}.tfvars -auto-approve
```

### Backend State Isolation

Each environment has isolated Terraform state:

```
DEV:
  S3: s3://bbws-terraform-state-dev/repo-name/component/terraform.tfstate
  DynamoDB: terraform-state-lock-dev
  Region: eu-west-1

SIT:
  S3: s3://bbws-terraform-state-sit/repo-name/component/terraform.tfstate
  DynamoDB: terraform-state-lock-sit
  Region: eu-west-1

PROD:
  S3: s3://bbws-terraform-state-prod/repo-name/component/terraform.tfstate
  DynamoDB: terraform-state-lock-prod
  Region: af-south-1
```

---

## Quick Reference Card

```
┌────────────────────────────────────────────────────────────────┐
│           GITHUB OIDC SETUP CHECKLIST                          │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  ☐ 1. Verify/Create OIDC provider in AWS                      │
│       aws iam list-open-id-connect-providers                  │
│                                                                │
│  ☐ 2. Create IAM role with trust policy                       │
│       - Organization name must match exactly                  │
│       - Use BigBeardWebSolutions (not tsekatm)                │
│                                                                │
│  ☐ 3. Create and attach permissions policy                    │
│       - S3 backend: ListBucket + object permissions           │
│       - DynamoDB state lock: GetItem, PutItem, DeleteItem     │
│       - Service permissions: DynamoDB, S3, Lambda, ECS, etc.  │
│                                                                │
│  ☐ 4. Set GitHub secrets                                      │
│       gh secret set AWS_ROLE_DEV --body "arn:..."             │
│       gh secret set AWS_ROLE_SIT --body "arn:..."             │
│       gh secret set AWS_ROLE_PROD --body "arn:..."            │
│                                                                │
│  ☐ 5. Configure workflow OIDC permissions                     │
│       permissions:                                            │
│         id-token: write                                       │
│         contents: read                                        │
│                                                                │
│  ☐ 6. Parameterize Terraform backend                          │
│       terraform { backend "s3" {} }                           │
│       Use -backend-config flags in workflow                   │
│                                                                │
│  ☐ 7. Test workflow deployment                                │
│       gh workflow run "Deploy" --field environment=dev        │
│                                                                │
│  ☐ 8. Validate resources created                              │
│       Compare before/after AWS CLI queries                    │
│                                                                │
└────────────────────────────────────────────────────────────────┘

ENVIRONMENT-REGION MAPPING:
  DEV  (536580886816): eu-west-1 (Ireland)
  SIT  (815856636111): eu-west-1 (Ireland)
  PROD (093646564004): af-south-1 (Cape Town) + eu-west-1 (DR)

COMMON COMMANDS:
  # Check OIDC provider
  aws iam list-open-id-connect-providers

  # Get role trust policy
  aws iam get-role --role-name ROLE_NAME --query 'Role.AssumeRolePolicyDocument'

  # Update trust policy
  aws iam update-assume-role-policy --role-name ROLE --policy-document file://trust.json

  # Create policy version
  aws iam create-policy-version --policy-arn ARN --policy-document file://policy.json --set-as-default

  # Set GitHub secret
  gh secret set SECRET_NAME --body "value"

  # Run workflow
  gh workflow run "workflow-name" --field key=value

  # Watch workflow
  gh run watch RUN_ID

CRITICAL MISTAKES TO AVOID:
  ❌ Wrong organization name in trust policy
  ❌ Missing s3:ListBucket permission
  ❌ Hardcoded backend in main.tf
  ❌ Resource ARN mismatch in IAM policy
  ❌ Deploying to PROD without SIT validation
```

---

## Helper Commands

### OIDC Provider Management

```bash
# List OIDC providers
aws iam list-open-id-connect-providers

# Get OIDC provider details
aws iam get-open-id-connect-provider \
  --open-id-connect-provider-arn arn:aws:iam::ACCOUNT:oidc-provider/token.actions.githubusercontent.com

# Delete OIDC provider (if needed)
aws iam delete-open-id-connect-provider \
  --open-id-connect-provider-arn arn:aws:iam::ACCOUNT:oidc-provider/token.actions.githubusercontent.com
```

### IAM Role Management

```bash
# Get role details
aws iam get-role --role-name github-actions-role-dev

# Get role trust policy
aws iam get-role \
  --role-name github-actions-role-dev \
  --query 'Role.AssumeRolePolicyDocument'

# Update trust policy
aws iam update-assume-role-policy \
  --role-name github-actions-role-dev \
  --policy-document file://trust-policy.json

# List attached policies
aws iam list-attached-role-policies --role-name github-actions-role-dev

# List inline policies
aws iam list-role-policies --role-name github-actions-role-dev
```

### IAM Policy Management

```bash
# Get policy details
aws iam get-policy --policy-arn arn:aws:iam::ACCOUNT:policy/github-actions-policy-dev

# Get policy version
aws iam get-policy-version \
  --policy-arn arn:aws:iam::ACCOUNT:policy/github-actions-policy-dev \
  --version-id v1

# Create new policy version
aws iam create-policy-version \
  --policy-arn arn:aws:iam::ACCOUNT:policy/github-actions-policy-dev \
  --policy-document file://updated-policy.json \
  --set-as-default

# List policy versions
aws iam list-policy-versions \
  --policy-arn arn:aws:iam::ACCOUNT:policy/github-actions-policy-dev
```

### GitHub Secrets Management

```bash
# List all secrets
gh secret list

# Set a secret
gh secret set AWS_ROLE_DEV --body "arn:aws:iam::536580886816:role/github-actions-role-dev"

# Delete a secret
gh secret delete AWS_ROLE_DEV
```

### GitHub Workflow Management

```bash
# List workflows
gh workflow list

# Run workflow
gh workflow run deploy-infrastructure.yml \
  --field environment=dev \
  --field component=dynamodb

# List recent runs
gh run list --workflow=deploy-infrastructure.yml --limit 5

# Watch a running workflow
gh run watch RUN_ID

# View workflow logs
gh run view RUN_ID --log

# View failed workflow logs only
gh run view RUN_ID --log-failed
```

---

## Security Best Practices

### Principle of Least Privilege

1. **Separate Roles per Environment**
   - DEV: `github-actions-role-dev`
   - SIT: `github-actions-role-sit`
   - PROD: `github-actions-role-prod`

2. **Granular Permissions**
   - Only grant permissions needed for deployment
   - Avoid wildcard `*` in Resource ARNs when possible
   - Use specific action lists instead of `*`

3. **Trust Policy Scoping**
   - Specific repositories: `repo:ORG/REPO:*`
   - All repos in org: `repo:ORG/*`
   - Never: `repo:*/*` (too broad)

### Audit and Monitoring

```bash
# Check who last modified IAM role
aws iam get-role --role-name github-actions-role-dev

# View CloudTrail events for role usage
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=ResourceName,AttributeValue=github-actions-role-dev \
  --max-results 10

# Monitor GitHub Actions usage
gh api /repos/ORG/REPO/actions/runs | jq '.workflow_runs[] | {id: .id, status: .status, conclusion: .conclusion}'
```

### Secret Rotation

```bash
# Rotate IAM role regularly
# 1. Create new role
aws iam create-role --role-name github-actions-role-dev-v2 --assume-role-policy-document file://trust-policy.json

# 2. Attach policies
aws iam attach-role-policy \
  --role-name github-actions-role-dev-v2 \
  --policy-arn arn:aws:iam::ACCOUNT:policy/github-actions-policy-dev

# 3. Update GitHub secret
gh secret set AWS_ROLE_DEV --body "$(aws iam get-role --role-name github-actions-role-dev-v2 --query 'Role.Arn' --output text)"

# 4. Test deployment
# 5. Delete old role (after confirming new role works)
aws iam delete-role --role-name github-actions-role-dev
```

---

## Related Skills

- **aws_region_specification.skill.md**: Environment-region mapping and multi-region DR strategy
- **HLD_LLD_Naming_Convention.skill.md**: Infrastructure and resource naming standards
- **Development_Best_Practices.skill.md**: Code quality and testing standards
- **multi_repo_tbt_init.skill.md**: Turn-by-turn workflow initialization across repositories

---

## Version History

- **v1.0** (2025-12-26): Initial skill created from OIDC troubleshooting session
  - Complete OIDC setup guide
  - IAM role and policy configuration
  - Multi-service deployment patterns (S3, Lambda, ECS, CloudFront, Route53, DynamoDB)
  - Query-based validation approach
  - Multi-environment promotion workflow (DEV→SIT→PROD)
  - Comprehensive troubleshooting guide
  - All errors from troubleshooting session documented with solutions

---

**Last Updated**: 2025-12-26
**Maintained By**: DevOps Engineer Agent
**Skill Type**: Infrastructure / CI/CD / OIDC Authentication
