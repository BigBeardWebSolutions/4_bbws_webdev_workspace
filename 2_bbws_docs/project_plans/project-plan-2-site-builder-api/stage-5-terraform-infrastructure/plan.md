# Stage 5: Terraform Infrastructure

**Stage ID**: stage-5-terraform-infrastructure
**Parent Project**: Site Builder Bedrock Generation API (project-plan-2)
**Status**: PENDING
**Created**: 2026-01-15

---

## Stage Overview

**Objective**: Create Terraform modules for Lambda, API Gateway, DynamoDB, and S3 infrastructure with multi-environment support.

**Dependencies**: Stage 4 complete (Gate 3 approved)

**Deliverables**:
1. Terraform modules (separate per microservice)
2. Environment configurations (DEV, SIT, PROD)
3. IAM roles and policies
4. CloudWatch monitoring and alerting

**Expected Duration**:
- Agentic: 1-2 hours
- Manual: 4-5 days

---

## Workers

| Worker | Name | Status | Description |
|--------|------|--------|-------------|
| 1 | Lambda Module | PENDING | Lambda function Terraform module |
| 2 | API Gateway Module | PENDING | API Gateway Terraform module |
| 3 | DynamoDB Module | PENDING | DynamoDB table Terraform module |
| 4 | S3 Module | PENDING | S3 bucket Terraform module |
| 5 | IAM Module | PENDING | IAM roles and policies module |
| 6 | Monitoring Module | PENDING | CloudWatch monitoring and SNS alerting |

---

## Worker Definitions

### Worker 1: Lambda Module

**Objective**: Create reusable Terraform module for Lambda functions with proper IAM, logging, and environment configuration.

**Input Files**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/3.1.2_LLD_Site_Builder_Bedrock_Generation_API.md`
- `src/lambdas/` (Lambda function code)

**Tasks**:
1. Create Lambda module structure
2. Define variables for all configurable parameters
3. Configure Lambda function resource
4. Configure CloudWatch log group
5. Configure Lambda layers for shared code
6. Configure environment variables
7. Configure VPC (optional)
8. Output Lambda ARN and function name

**Output Requirements**:
- Create: `terraform/modules/lambda/`
  - `main.tf`
  - `variables.tf`
  - `outputs.tf`

**Code Structure**:
```hcl
# terraform/modules/lambda/main.tf

variable "function_name" {
  description = "Lambda function name"
  type        = string
}

variable "runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.12"
}

variable "handler" {
  description = "Lambda handler"
  type        = string
}

variable "memory_size" {
  description = "Lambda memory in MB"
  type        = number
  default     = 512
}

variable "timeout" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 60
}

variable "environment_variables" {
  description = "Environment variables"
  type        = map(string)
  default     = {}
}

variable "environment" {
  description = "Environment name (dev, sit, prod)"
  type        = string
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

resource "aws_lambda_function" "this" {
  function_name = "${var.function_name}-${var.environment}"
  runtime       = var.runtime
  handler       = var.handler
  memory_size   = var.memory_size
  timeout       = var.timeout
  role          = aws_iam_role.lambda_role.arn

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = merge(var.environment_variables, {
      ENVIRONMENT = var.environment
    })
  }

  tags = merge(var.tags, {
    Environment = var.environment
    Service     = "site-builder-generation-api"
  })
}

resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.this.function_name}"
  retention_in_days = var.environment == "prod" ? 90 : 30
}

output "function_arn" {
  value = aws_lambda_function.this.arn
}

output "function_name" {
  value = aws_lambda_function.this.function_name
}

output "invoke_arn" {
  value = aws_lambda_function.this.invoke_arn
}
```

**Success Criteria**:
- Module is reusable for all Lambda functions
- Environment parameterization complete
- No hardcoded values
- Proper tagging

---

### Worker 2: API Gateway Module

**Objective**: Create Terraform module for API Gateway with Cognito authorization and Lambda integration.

**Input Files**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/3.1.2_LLD_Site_Builder_Bedrock_Generation_API.md`
- `openapi/generation-api.yaml`
- `openapi/agents-api.yaml`
- `openapi/validation-api.yaml`

**Tasks**:
1. Create API Gateway REST API resource
2. Configure Cognito authorizer
3. Configure Lambda integrations
4. Configure CORS settings
5. Configure request/response mappings
6. Configure deployment stages
7. Configure custom domain (optional)

**Output Requirements**:
- Create: `terraform/modules/api_gateway/`
  - `main.tf`
  - `variables.tf`
  - `outputs.tf`

**Code Structure**:
```hcl
# terraform/modules/api_gateway/main.tf

variable "api_name" {
  description = "API Gateway name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "cognito_user_pool_arn" {
  description = "Cognito User Pool ARN for authorization"
  type        = string
}

variable "lambda_integrations" {
  description = "Map of path to Lambda ARN"
  type        = map(object({
    lambda_arn    = string
    http_method   = string
    authorization = string
  }))
}

resource "aws_api_gateway_rest_api" "this" {
  name        = "${var.api_name}-${var.environment}"
  description = "Site Builder Generation API - ${var.environment}"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    Environment = var.environment
    Service     = "site-builder-generation-api"
  }
}

resource "aws_api_gateway_authorizer" "cognito" {
  name          = "cognito-authorizer"
  rest_api_id   = aws_api_gateway_rest_api.this.id
  type          = "COGNITO_USER_POOLS"
  provider_arns = [var.cognito_user_pool_arn]
}

# CORS configuration
resource "aws_api_gateway_method" "options" {
  for_each = var.lambda_integrations

  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.paths[each.key].id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

output "api_id" {
  value = aws_api_gateway_rest_api.this.id
}

output "invoke_url" {
  value = aws_api_gateway_stage.this.invoke_url
}
```

**Success Criteria**:
- API Gateway configured with all endpoints
- Cognito authorizer integrated
- CORS enabled
- Stage deployment working

---

### Worker 3: DynamoDB Module

**Objective**: Create Terraform module for DynamoDB tables with on-demand capacity (REQUIRED per CLAUDE.md).

**Input Files**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/3.1.2_LLD_Site_Builder_Bedrock_Generation_API.md`

**Tasks**:
1. Create DynamoDB table resource
2. Configure partition key and sort key
3. Configure Global Secondary Indexes
4. Configure on-demand capacity (MANDATORY)
5. Configure encryption
6. Configure TTL
7. Configure point-in-time recovery
8. Configure global tables for DR (prod only)

**Output Requirements**:
- Create: `terraform/modules/dynamodb/`
  - `main.tf`
  - `variables.tf`
  - `outputs.tf`

**Code Structure**:
```hcl
# terraform/modules/dynamodb/main.tf

variable "table_name" {
  description = "DynamoDB table name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "partition_key" {
  description = "Partition key name"
  type        = string
}

variable "partition_key_type" {
  description = "Partition key type (S, N, B)"
  type        = string
  default     = "S"
}

variable "sort_key" {
  description = "Sort key name"
  type        = string
  default     = null
}

variable "sort_key_type" {
  description = "Sort key type (S, N, B)"
  type        = string
  default     = "S"
}

variable "global_secondary_indexes" {
  description = "GSI configurations"
  type = list(object({
    name               = string
    hash_key           = string
    range_key          = string
    projection_type    = string
  }))
  default = []
}

variable "ttl_attribute" {
  description = "TTL attribute name"
  type        = string
  default     = null
}

variable "enable_global_tables" {
  description = "Enable global tables for DR"
  type        = bool
  default     = false
}

variable "replica_region" {
  description = "Replica region for global tables"
  type        = string
  default     = "eu-west-1"
}

resource "aws_dynamodb_table" "this" {
  name = "${var.table_name}-${var.environment}"

  # CRITICAL: On-demand capacity is MANDATORY per CLAUDE.md
  billing_mode = "PAY_PER_REQUEST"

  hash_key  = var.partition_key
  range_key = var.sort_key

  attribute {
    name = var.partition_key
    type = var.partition_key_type
  }

  dynamic "attribute" {
    for_each = var.sort_key != null ? [1] : []
    content {
      name = var.sort_key
      type = var.sort_key_type
    }
  }

  dynamic "global_secondary_index" {
    for_each = var.global_secondary_indexes
    content {
      name            = global_secondary_index.value.name
      hash_key        = global_secondary_index.value.hash_key
      range_key       = global_secondary_index.value.range_key
      projection_type = global_secondary_index.value.projection_type
    }
  }

  dynamic "ttl" {
    for_each = var.ttl_attribute != null ? [1] : []
    content {
      attribute_name = var.ttl_attribute
      enabled        = true
    }
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  # Global tables for DR (prod only)
  dynamic "replica" {
    for_each = var.enable_global_tables ? [1] : []
    content {
      region_name = var.replica_region
    }
  }

  tags = {
    Environment = var.environment
    Service     = "site-builder-generation-api"
  }
}

output "table_name" {
  value = aws_dynamodb_table.this.name
}

output "table_arn" {
  value = aws_dynamodb_table.this.arn
}
```

**Success Criteria**:
- On-demand capacity configured (MANDATORY)
- GSIs configured
- Encryption enabled
- PITR enabled
- Global tables for prod

---

### Worker 4: S3 Module

**Objective**: Create Terraform module for S3 buckets with blocked public access (REQUIRED per CLAUDE.md).

**Input Files**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/3.1.2_LLD_Site_Builder_Bedrock_Generation_API.md`

**Tasks**:
1. Create S3 bucket resource
2. Configure public access block (MANDATORY)
3. Configure bucket policy
4. Configure CORS
5. Configure versioning
6. Configure lifecycle rules
7. Configure cross-region replication (prod only)
8. Configure CloudFront OAC integration

**Output Requirements**:
- Create: `terraform/modules/s3/`
  - `main.tf`
  - `variables.tf`
  - `outputs.tf`

**Code Structure**:
```hcl
# terraform/modules/s3/main.tf

variable "bucket_name" {
  description = "S3 bucket name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "enable_versioning" {
  description = "Enable versioning"
  type        = bool
  default     = true
}

variable "enable_cors" {
  description = "Enable CORS"
  type        = bool
  default     = true
}

variable "cors_allowed_origins" {
  description = "CORS allowed origins"
  type        = list(string)
  default     = ["*"]
}

variable "enable_replication" {
  description = "Enable cross-region replication"
  type        = bool
  default     = false
}

variable "replica_bucket_arn" {
  description = "Replica bucket ARN for CRR"
  type        = string
  default     = null
}

resource "aws_s3_bucket" "this" {
  bucket = "${var.bucket_name}-${var.environment}"

  tags = {
    Environment = var.environment
    Service     = "site-builder-generation-api"
  }
}

# CRITICAL: Block all public access (MANDATORY per CLAUDE.md)
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

dynamic "cors_rule" {
  for_each = var.enable_cors ? [1] : []
  content {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST"]
    allowed_origins = var.cors_allowed_origins
    max_age_seconds = 3000
  }
}

# Cross-region replication for DR
resource "aws_s3_bucket_replication_configuration" "this" {
  count = var.enable_replication ? 1 : 0

  bucket = aws_s3_bucket.this.id
  role   = aws_iam_role.replication[0].arn

  rule {
    id     = "replicate-all"
    status = "Enabled"

    destination {
      bucket        = var.replica_bucket_arn
      storage_class = "STANDARD"
    }
  }
}

output "bucket_name" {
  value = aws_s3_bucket.this.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.this.arn
}

output "bucket_domain_name" {
  value = aws_s3_bucket.this.bucket_domain_name
}
```

**Success Criteria**:
- Public access blocked (MANDATORY)
- Versioning enabled
- Encryption enabled
- CRR configured for prod

---

### Worker 5: IAM Module

**Objective**: Create Terraform module for IAM roles and policies with least-privilege access.

**Input Files**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/3.1.2_LLD_Site_Builder_Bedrock_Generation_API.md`

**Tasks**:
1. Create Lambda execution role
2. Create Bedrock access policy
3. Create DynamoDB access policy
4. Create S3 access policy
5. Create CloudWatch logs policy
6. Create X-Ray tracing policy

**Output Requirements**:
- Create: `terraform/modules/iam/`
  - `main.tf`
  - `variables.tf`
  - `outputs.tf`

**Code Structure**:
```hcl
# terraform/modules/iam/main.tf

variable "role_name" {
  description = "IAM role name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "dynamodb_table_arns" {
  description = "DynamoDB table ARNs to access"
  type        = list(string)
}

variable "s3_bucket_arns" {
  description = "S3 bucket ARNs to access"
  type        = list(string)
}

variable "bedrock_model_ids" {
  description = "Bedrock model IDs to invoke"
  type        = list(string)
  default     = [
    "anthropic.claude-sonnet-4-5-20241022-v2:0",
    "stability.stable-diffusion-xl-v1"
  ]
}

resource "aws_iam_role" "lambda_execution" {
  name = "${var.role_name}-${var.environment}"

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

  tags = {
    Environment = var.environment
    Service     = "site-builder-generation-api"
  }
}

# Bedrock access policy
resource "aws_iam_role_policy" "bedrock_access" {
  name = "bedrock-access"
  role = aws_iam_role.lambda_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "bedrock:InvokeModel",
        "bedrock:InvokeModelWithResponseStream"
      ]
      Resource = [
        for model_id in var.bedrock_model_ids :
        "arn:aws:bedrock:*:*:foundation-model/${model_id}"
      ]
    }]
  })
}

# DynamoDB access policy
resource "aws_iam_role_policy" "dynamodb_access" {
  name = "dynamodb-access"
  role = aws_iam_role.lambda_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:Query",
        "dynamodb:Scan"
      ]
      Resource = var.dynamodb_table_arns
    }]
  })
}

# S3 access policy
resource "aws_iam_role_policy" "s3_access" {
  name = "s3-access"
  role = aws_iam_role.lambda_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ]
      Resource = [
        for bucket_arn in var.s3_bucket_arns :
        "${bucket_arn}/*"
      ]
    }]
  })
}

# CloudWatch Logs policy
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# X-Ray tracing policy
resource "aws_iam_role_policy_attachment" "xray_access" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

output "role_arn" {
  value = aws_iam_role.lambda_execution.arn
}

output "role_name" {
  value = aws_iam_role.lambda_execution.name
}
```

**Success Criteria**:
- Least-privilege policies
- Bedrock access configured
- DynamoDB access configured
- S3 access configured
- No hardcoded ARNs

---

### Worker 6: Monitoring Module

**Objective**: Create Terraform module for CloudWatch monitoring, alarms, and SNS alerting.

**Input Files**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/3.1.2_LLD_Site_Builder_Bedrock_Generation_API.md`

**Tasks**:
1. Create CloudWatch dashboard
2. Create Lambda error alarms
3. Create Lambda duration alarms
4. Create DynamoDB throttling alarms
5. Create SNS topic for alerts
6. Create alarm actions

**Output Requirements**:
- Create: `terraform/modules/monitoring/`
  - `main.tf`
  - `variables.tf`
  - `outputs.tf`

**Code Structure**:
```hcl
# terraform/modules/monitoring/main.tf

variable "service_name" {
  description = "Service name for monitoring"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "lambda_function_names" {
  description = "Lambda function names to monitor"
  type        = list(string)
}

variable "dynamodb_table_names" {
  description = "DynamoDB table names to monitor"
  type        = list(string)
}

variable "alert_email" {
  description = "Email for alarm notifications"
  type        = string
}

# SNS topic for alerts
resource "aws_sns_topic" "alerts" {
  name = "${var.service_name}-alerts-${var.environment}"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# Lambda error alarm
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  for_each = toset(var.lambda_function_names)

  alarm_name          = "${each.value}-errors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Lambda errors exceeded threshold"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    FunctionName = each.value
  }
}

# Lambda duration alarm (for generation timeout)
resource "aws_cloudwatch_metric_alarm" "lambda_duration" {
  for_each = toset(var.lambda_function_names)

  alarm_name          = "${each.value}-duration-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Average"
  threshold           = 55000  # 55 seconds (warn before 60s timeout)
  alarm_description   = "Lambda duration approaching timeout"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    FunctionName = each.value
  }
}

# DynamoDB throttling alarm
resource "aws_cloudwatch_metric_alarm" "dynamodb_throttle" {
  for_each = toset(var.dynamodb_table_names)

  alarm_name          = "${each.value}-throttle-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ThrottledRequests"
  namespace           = "AWS/DynamoDB"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "DynamoDB throttling detected"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    TableName = each.value
  }
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.service_name}-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "Lambda Invocations"
          region = data.aws_region.current.name
          metrics = [
            for fn in var.lambda_function_names :
            ["AWS/Lambda", "Invocations", "FunctionName", fn]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "Lambda Errors"
          region = data.aws_region.current.name
          metrics = [
            for fn in var.lambda_function_names :
            ["AWS/Lambda", "Errors", "FunctionName", fn]
          ]
        }
      }
    ]
  })
}

output "sns_topic_arn" {
  value = aws_sns_topic.alerts.arn
}

output "dashboard_name" {
  value = aws_cloudwatch_dashboard.main.dashboard_name
}
```

**Success Criteria**:
- Dashboard created
- Error alarms configured
- Duration alarms configured
- SNS notifications working

---

## Environment Configurations

Create environment-specific configurations:

**Output Requirements**:
- Create: `terraform/environments/dev/`
- Create: `terraform/environments/sit/`
- Create: `terraform/environments/prod/`

Each with:
- `main.tf` - Module instantiation
- `variables.tf` - Variable definitions
- `terraform.tfvars` - Environment values

**Example dev/terraform.tfvars**:
```hcl
environment        = "dev"
region             = "eu-west-1"
alert_email        = "dev-alerts@example.com"

# PROD-specific
# region             = "af-south-1"  # Primary
# replica_region     = "eu-west-1"   # DR
# enable_replication = true
```

---

## Stage Completion Criteria

The stage is considered **COMPLETE** when:

1. All 6 workers have completed their outputs
2. All Terraform modules created and validated
3. Environment configurations complete
4. `terraform validate` passes for all environments
5. `terraform plan` generates valid plan

---

**Stage Owner**: Agentic Project Manager
**Created**: 2026-01-15
**Next Action**: Wait for Stage 4 completion and Gate 3 approval
