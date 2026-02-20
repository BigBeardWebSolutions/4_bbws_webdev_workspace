# Worker 4 Output: Cognito Integration Terraform Module

**Worker ID**: worker-4-cognito-integration-module
**Stage**: Stage 2 - Infrastructure Terraform
**Project**: project-plan-2-access-management
**Status**: COMPLETE
**Date**: 2026-01-23

---

## Executive Summary

This document provides the complete Terraform module for the Cognito Lambda Authorizer integration with API Gateway. The module creates a Lambda authorizer function that validates Cognito JWTs, resolves user permissions and team memberships, and returns IAM policies for API Gateway authorization. The design follows fail-closed security principles and supports multi-environment deployment (DEV, SIT, PROD).

---

## Module Structure

```
terraform/modules/cognito-authorizer/
├── main.tf           # API Gateway authorizer configuration
├── lambda.tf         # Authorizer Lambda function definition
├── iam.tf            # IAM roles for Lambda and API Gateway invocation
├── variables.tf      # Input variables (Cognito, DynamoDB, environment)
└── outputs.tf        # Module outputs (authorizer ID, Lambda ARN)
```

---

## 1. main.tf - API Gateway Authorizer Configuration

```hcl
################################################################################
# API Gateway Lambda Authorizer Configuration
# Purpose: TOKEN-based authorizer for JWT validation with Cognito integration
################################################################################

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

#------------------------------------------------------------------------------
# API Gateway Authorizer
# Type: TOKEN (validates Authorization header)
# TTL: 300 seconds (5 minutes cache)
#------------------------------------------------------------------------------
resource "aws_api_gateway_authorizer" "access_management" {
  name                             = "bbws-access-${var.environment}-authorizer"
  rest_api_id                      = var.api_gateway_id
  authorizer_uri                   = aws_lambda_function.authorizer.invoke_arn
  authorizer_credentials           = aws_iam_role.api_gateway_authorizer_invocation.arn
  type                             = "TOKEN"
  identity_source                  = "method.request.header.Authorization"
  authorizer_result_ttl_in_seconds = var.authorizer_cache_ttl

  # Validation regex for Bearer tokens
  identity_validation_expression = "^Bearer [-0-9a-zA-Z._]+$"
}

#------------------------------------------------------------------------------
# Lambda Permission for API Gateway
# Allows API Gateway to invoke the authorizer Lambda function
#------------------------------------------------------------------------------
resource "aws_lambda_permission" "api_gateway_invoke_authorizer" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.authorizer.function_name
  principal     = "apigateway.amazonaws.com"

  # Restrict to specific API Gateway source
  source_arn = "${var.api_gateway_execution_arn}/authorizers/${aws_api_gateway_authorizer.access_management.id}"
}

#------------------------------------------------------------------------------
# CloudWatch Log Group for Authorizer
# Separate log group for authorizer-specific logs
#------------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "authorizer" {
  name              = "/aws/lambda/${local.lambda_function_name}"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name        = "${local.lambda_function_name}-logs"
    Service     = "authorizer"
    Environment = var.environment
  })
}

#------------------------------------------------------------------------------
# Local Variables
#------------------------------------------------------------------------------
locals {
  lambda_function_name = "bbws-access-${var.environment}-lambda-authorizer"

  # JWKS URL pattern for Cognito
  jwks_url = "https://cognito-idp.${var.cognito_region}.amazonaws.com/${var.cognito_user_pool_id}/.well-known/jwks.json"

  # Issuer URL for token validation
  issuer_url = "https://cognito-idp.${var.cognito_region}.amazonaws.com/${var.cognito_user_pool_id}"

  # Common tags for all resources
  common_tags = merge(var.tags, {
    Module      = "cognito-authorizer"
    ManagedBy   = "terraform"
    Environment = var.environment
    Service     = "access-management"
  })
}
```

---

## 2. lambda.tf - Authorizer Lambda Function Definition

```hcl
################################################################################
# Lambda Authorizer Function
# Purpose: Validates Cognito JWTs and generates IAM policies for API Gateway
################################################################################

#------------------------------------------------------------------------------
# Lambda Function
# Runtime: Python 3.12 | Architecture: arm64 | Memory: 512MB | Timeout: 10s
#------------------------------------------------------------------------------
resource "aws_lambda_function" "authorizer" {
  function_name = local.lambda_function_name
  description   = "BBWS Access Management Lambda Authorizer - validates Cognito JWTs and resolves permissions"

  # Deployment package source
  s3_bucket = var.lambda_deployment_bucket
  s3_key    = var.lambda_deployment_key

  # Runtime configuration
  runtime       = "python3.12"
  architectures = ["arm64"]
  handler       = "src.handlers.authorizer.handler"

  # Resource allocation
  memory_size = var.lambda_memory_size
  timeout     = var.lambda_timeout

  # Execution role
  role = aws_iam_role.lambda_authorizer.arn

  # Environment variables for runtime configuration
  environment {
    variables = {
      # Cognito configuration
      COGNITO_USER_POOL_ID = var.cognito_user_pool_id
      COGNITO_REGION       = var.cognito_region
      COGNITO_APP_CLIENT_ID = var.cognito_app_client_id

      # DynamoDB configuration
      DYNAMODB_TABLE = var.dynamodb_table_name

      # Cache TTL settings (seconds)
      JWKS_CACHE_TTL       = tostring(var.jwks_cache_ttl)
      PERMISSION_CACHE_TTL = tostring(var.permission_cache_ttl)
      POLICY_CACHE_TTL     = tostring(var.authorizer_cache_ttl)

      # Logging configuration
      LOG_LEVEL   = var.log_level
      ENVIRONMENT = var.environment

      # Audit configuration
      AUDIT_ENABLED = tostring(var.audit_enabled)

      # JWKS URL (pre-computed for efficiency)
      JWKS_URL   = local.jwks_url
      ISSUER_URL = local.issuer_url
    }
  }

  # VPC configuration (optional - only if Lambda needs VPC access)
  dynamic "vpc_config" {
    for_each = var.vpc_config != null ? [var.vpc_config] : []
    content {
      subnet_ids         = vpc_config.value.subnet_ids
      security_group_ids = vpc_config.value.security_group_ids
    }
  }

  # Dead Letter Queue for failed invocations
  dynamic "dead_letter_config" {
    for_each = var.dead_letter_queue_arn != null ? [1] : []
    content {
      target_arn = var.dead_letter_queue_arn
    }
  }

  # X-Ray tracing configuration
  tracing_config {
    mode = var.xray_tracing_enabled ? "Active" : "PassThrough"
  }

  # Reserved concurrent executions (throttling protection)
  reserved_concurrent_executions = var.reserved_concurrency

  # Ensure log group exists before Lambda
  depends_on = [aws_cloudwatch_log_group.authorizer]

  tags = merge(local.common_tags, {
    Name = local.lambda_function_name
  })
}

#------------------------------------------------------------------------------
# Lambda Alias for Stable Deployment
# Blue-green deployment support
#------------------------------------------------------------------------------
resource "aws_lambda_alias" "authorizer_live" {
  name             = "live"
  description      = "Production alias for authorizer Lambda"
  function_name    = aws_lambda_function.authorizer.function_name
  function_version = aws_lambda_function.authorizer.version

  # Routing configuration for canary deployments (optional)
  dynamic "routing_config" {
    for_each = var.canary_deployment_enabled ? [1] : []
    content {
      additional_version_weights = var.canary_weights
    }
  }
}

#------------------------------------------------------------------------------
# Lambda Provisioned Concurrency (Production only)
# Reduces cold start latency for consistent performance
#------------------------------------------------------------------------------
resource "aws_lambda_provisioned_concurrency_config" "authorizer" {
  count = var.provisioned_concurrency > 0 ? 1 : 0

  function_name                     = aws_lambda_function.authorizer.function_name
  provisioned_concurrent_executions = var.provisioned_concurrency
  qualifier                         = aws_lambda_alias.authorizer_live.name
}

#------------------------------------------------------------------------------
# Lambda Layer for Dependencies
# Contains PyJWT, aws-lambda-powertools, and other dependencies
#------------------------------------------------------------------------------
resource "aws_lambda_layer_version" "authorizer_dependencies" {
  count = var.create_lambda_layer ? 1 : 0

  layer_name          = "bbws-access-${var.environment}-authorizer-dependencies"
  description         = "Dependencies for BBWS authorizer Lambda (PyJWT, aws-lambda-powertools)"
  s3_bucket           = var.lambda_deployment_bucket
  s3_key              = var.lambda_layer_key
  compatible_runtimes = ["python3.12"]
  compatible_architectures = ["arm64"]
}
```

---

## 3. iam.tf - IAM Roles and Policies

```hcl
################################################################################
# IAM Roles and Policies for Lambda Authorizer
# Follows principle of least privilege
################################################################################

#------------------------------------------------------------------------------
# Lambda Execution Role
# Role assumed by the authorizer Lambda function
#------------------------------------------------------------------------------
resource "aws_iam_role" "lambda_authorizer" {
  name = "bbws-access-${var.environment}-role-lambda-authorizer"
  description = "Execution role for BBWS Access Management Lambda Authorizer"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
      Condition = {
        StringEquals = {
          "aws:SourceAccount" = data.aws_caller_identity.current.account_id
        }
      }
    }]
  })

  tags = merge(local.common_tags, {
    Name = "bbws-access-${var.environment}-role-lambda-authorizer"
  })
}

#------------------------------------------------------------------------------
# Lambda Basic Execution Policy
# CloudWatch Logs permissions
#------------------------------------------------------------------------------
resource "aws_iam_role_policy" "lambda_authorizer_logging" {
  name = "bbws-access-${var.environment}-policy-authorizer-logging"
  role = aws_iam_role.lambda_authorizer.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudWatchLogging"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "${aws_cloudwatch_log_group.authorizer.arn}:*"
        ]
      }
    ]
  })
}

#------------------------------------------------------------------------------
# DynamoDB Access Policy
# Read permissions for access management table
#------------------------------------------------------------------------------
resource "aws_iam_role_policy" "lambda_authorizer_dynamodb" {
  name = "bbws-access-${var.environment}-policy-authorizer-dynamodb"
  role = aws_iam_role.lambda_authorizer.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowDynamoDBRead"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:BatchGetItem"
        ]
        Resource = [
          var.dynamodb_table_arn,
          "${var.dynamodb_table_arn}/index/*"
        ]
      }
    ]
  })
}

#------------------------------------------------------------------------------
# DynamoDB Audit Write Policy
# Write permissions for audit logging (if enabled)
#------------------------------------------------------------------------------
resource "aws_iam_role_policy" "lambda_authorizer_audit" {
  count = var.audit_enabled ? 1 : 0

  name = "bbws-access-${var.environment}-policy-authorizer-audit"
  role = aws_iam_role.lambda_authorizer.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAuditWrite"
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem"
        ]
        Resource = [
          var.audit_table_arn != null ? var.audit_table_arn : var.dynamodb_table_arn
        ]
        Condition = {
          "ForAllValues:StringLike" = {
            "dynamodb:LeadingKeys" = ["AUDIT#*"]
          }
        }
      }
    ]
  })
}

#------------------------------------------------------------------------------
# X-Ray Tracing Policy (optional)
#------------------------------------------------------------------------------
resource "aws_iam_role_policy" "lambda_authorizer_xray" {
  count = var.xray_tracing_enabled ? 1 : 0

  name = "bbws-access-${var.environment}-policy-authorizer-xray"
  role = aws_iam_role.lambda_authorizer.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowXRayTracing"
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        Resource = ["*"]
      }
    ]
  })
}

#------------------------------------------------------------------------------
# VPC Execution Policy (optional - only if Lambda is in VPC)
#------------------------------------------------------------------------------
resource "aws_iam_role_policy" "lambda_authorizer_vpc" {
  count = var.vpc_config != null ? 1 : 0

  name = "bbws-access-${var.environment}-policy-authorizer-vpc"
  role = aws_iam_role.lambda_authorizer.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowVPCNetworkInterfaces"
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
          "ec2:AssignPrivateIpAddresses",
          "ec2:UnassignPrivateIpAddresses"
        ]
        Resource = ["*"]
      }
    ]
  })
}

#------------------------------------------------------------------------------
# Dead Letter Queue Policy (optional)
#------------------------------------------------------------------------------
resource "aws_iam_role_policy" "lambda_authorizer_dlq" {
  count = var.dead_letter_queue_arn != null ? 1 : 0

  name = "bbws-access-${var.environment}-policy-authorizer-dlq"
  role = aws_iam_role.lambda_authorizer.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowDLQPublish"
        Effect = "Allow"
        Action = [
          "sqs:SendMessage"
        ]
        Resource = [var.dead_letter_queue_arn]
      }
    ]
  })
}

#------------------------------------------------------------------------------
# API Gateway Authorizer Invocation Role
# Role for API Gateway to invoke the Lambda authorizer
#------------------------------------------------------------------------------
resource "aws_iam_role" "api_gateway_authorizer_invocation" {
  name = "bbws-access-${var.environment}-role-apigw-authorizer"
  description = "Role for API Gateway to invoke Lambda authorizer"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "apigateway.amazonaws.com"
      }
      Action = "sts:AssumeRole"
      Condition = {
        ArnLike = {
          "aws:SourceArn" = var.api_gateway_execution_arn
        }
      }
    }]
  })

  tags = merge(local.common_tags, {
    Name = "bbws-access-${var.environment}-role-apigw-authorizer"
  })
}

#------------------------------------------------------------------------------
# API Gateway Lambda Invocation Policy
#------------------------------------------------------------------------------
resource "aws_iam_role_policy" "api_gateway_invoke_lambda" {
  name = "bbws-access-${var.environment}-policy-apigw-invoke-authorizer"
  role = aws_iam_role.api_gateway_authorizer_invocation.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowInvokeLambdaAuthorizer"
      Effect = "Allow"
      Action = "lambda:InvokeFunction"
      Resource = [
        aws_lambda_function.authorizer.arn,
        "${aws_lambda_function.authorizer.arn}:*"  # Include aliases
      ]
    }]
  })
}

#------------------------------------------------------------------------------
# Data Sources
#------------------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
```

---

## 4. variables.tf - Input Variables

```hcl
################################################################################
# Input Variables for Cognito Authorizer Module
# All variables are parameterized for multi-environment deployment
################################################################################

#------------------------------------------------------------------------------
# Environment Configuration
#------------------------------------------------------------------------------
variable "environment" {
  description = "Environment name (dev, sit, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "sit", "prod"], var.environment)
    error_message = "Environment must be one of: dev, sit, prod."
  }
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

#------------------------------------------------------------------------------
# Cognito Configuration
#------------------------------------------------------------------------------
variable "cognito_user_pool_id" {
  description = "Cognito User Pool ID for JWT validation"
  type        = string

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]+_[A-Za-z0-9]+$", var.cognito_user_pool_id))
    error_message = "Cognito User Pool ID must be in format: region_poolId (e.g., eu-west-1_abc123DEF)."
  }
}

variable "cognito_region" {
  description = "AWS region where Cognito User Pool is deployed"
  type        = string

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]+$", var.cognito_region))
    error_message = "Region must be a valid AWS region format (e.g., eu-west-1, af-south-1)."
  }
}

variable "cognito_app_client_id" {
  description = "Cognito App Client ID for token validation"
  type        = string

  validation {
    condition     = length(var.cognito_app_client_id) > 0
    error_message = "Cognito App Client ID cannot be empty."
  }
}

#------------------------------------------------------------------------------
# DynamoDB Configuration
#------------------------------------------------------------------------------
variable "dynamodb_table_name" {
  description = "DynamoDB table name for access management data"
  type        = string

  validation {
    condition     = length(var.dynamodb_table_name) > 0
    error_message = "DynamoDB table name cannot be empty."
  }
}

variable "dynamodb_table_arn" {
  description = "DynamoDB table ARN for IAM policy"
  type        = string

  validation {
    condition     = can(regex("^arn:aws:dynamodb:", var.dynamodb_table_arn))
    error_message = "Must be a valid DynamoDB table ARN."
  }
}

variable "audit_table_arn" {
  description = "DynamoDB audit table ARN (optional, defaults to main table)"
  type        = string
  default     = null
}

#------------------------------------------------------------------------------
# API Gateway Configuration
#------------------------------------------------------------------------------
variable "api_gateway_id" {
  description = "API Gateway REST API ID"
  type        = string

  validation {
    condition     = length(var.api_gateway_id) > 0
    error_message = "API Gateway ID cannot be empty."
  }
}

variable "api_gateway_execution_arn" {
  description = "API Gateway execution ARN for IAM policy conditions"
  type        = string

  validation {
    condition     = can(regex("^arn:aws:execute-api:", var.api_gateway_execution_arn))
    error_message = "Must be a valid API Gateway execution ARN."
  }
}

#------------------------------------------------------------------------------
# Lambda Configuration
#------------------------------------------------------------------------------
variable "lambda_deployment_bucket" {
  description = "S3 bucket containing Lambda deployment package"
  type        = string
}

variable "lambda_deployment_key" {
  description = "S3 key for Lambda deployment package"
  type        = string
}

variable "lambda_layer_key" {
  description = "S3 key for Lambda layer package"
  type        = string
  default     = null
}

variable "create_lambda_layer" {
  description = "Whether to create a Lambda layer for dependencies"
  type        = bool
  default     = false
}

variable "lambda_memory_size" {
  description = "Lambda function memory size in MB"
  type        = number
  default     = 512

  validation {
    condition     = var.lambda_memory_size >= 128 && var.lambda_memory_size <= 10240
    error_message = "Lambda memory must be between 128 MB and 10240 MB."
  }
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 10

  validation {
    condition     = var.lambda_timeout >= 1 && var.lambda_timeout <= 30
    error_message = "Lambda timeout must be between 1 and 30 seconds for authorizers."
  }
}

variable "reserved_concurrency" {
  description = "Reserved concurrent executions for Lambda (-1 for unreserved)"
  type        = number
  default     = -1
}

variable "provisioned_concurrency" {
  description = "Provisioned concurrency for Lambda (0 for disabled)"
  type        = number
  default     = 0
}

#------------------------------------------------------------------------------
# Cache TTL Configuration
#------------------------------------------------------------------------------
variable "authorizer_cache_ttl" {
  description = "API Gateway authorizer result cache TTL in seconds"
  type        = number
  default     = 300  # 5 minutes

  validation {
    condition     = var.authorizer_cache_ttl >= 0 && var.authorizer_cache_ttl <= 3600
    error_message = "Authorizer cache TTL must be between 0 and 3600 seconds."
  }
}

variable "jwks_cache_ttl" {
  description = "JWKS (public keys) cache TTL in seconds"
  type        = number
  default     = 3600  # 1 hour

  validation {
    condition     = var.jwks_cache_ttl >= 300 && var.jwks_cache_ttl <= 86400
    error_message = "JWKS cache TTL must be between 300 and 86400 seconds."
  }
}

variable "permission_cache_ttl" {
  description = "Permission cache TTL in seconds"
  type        = number
  default     = 300  # 5 minutes
}

#------------------------------------------------------------------------------
# Logging and Monitoring
#------------------------------------------------------------------------------
variable "log_level" {
  description = "Log level for Lambda function"
  type        = string
  default     = "INFO"

  validation {
    condition     = contains(["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"], var.log_level)
    error_message = "Log level must be one of: DEBUG, INFO, WARNING, ERROR, CRITICAL."
  }
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention period in days"
  type        = number
  default     = 30

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "Log retention must be a valid CloudWatch Logs retention value."
  }
}

variable "xray_tracing_enabled" {
  description = "Enable X-Ray tracing for Lambda"
  type        = bool
  default     = true
}

variable "audit_enabled" {
  description = "Enable audit logging to DynamoDB"
  type        = bool
  default     = true
}

#------------------------------------------------------------------------------
# VPC Configuration (Optional)
#------------------------------------------------------------------------------
variable "vpc_config" {
  description = "VPC configuration for Lambda (optional)"
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  default = null
}

#------------------------------------------------------------------------------
# Dead Letter Queue (Optional)
#------------------------------------------------------------------------------
variable "dead_letter_queue_arn" {
  description = "SQS Dead Letter Queue ARN for failed invocations"
  type        = string
  default     = null
}

#------------------------------------------------------------------------------
# Canary Deployment (Optional)
#------------------------------------------------------------------------------
variable "canary_deployment_enabled" {
  description = "Enable canary deployment with weighted aliases"
  type        = bool
  default     = false
}

variable "canary_weights" {
  description = "Traffic weights for canary deployment"
  type        = map(number)
  default     = {}
}
```

---

## 5. outputs.tf - Module Outputs

```hcl
################################################################################
# Module Outputs
# Exposes key resource identifiers for other modules and deployments
################################################################################

#------------------------------------------------------------------------------
# API Gateway Authorizer Outputs
#------------------------------------------------------------------------------
output "authorizer_id" {
  description = "API Gateway authorizer ID"
  value       = aws_api_gateway_authorizer.access_management.id
}

output "authorizer_name" {
  description = "API Gateway authorizer name"
  value       = aws_api_gateway_authorizer.access_management.name
}

output "authorizer_type" {
  description = "API Gateway authorizer type (TOKEN)"
  value       = aws_api_gateway_authorizer.access_management.type
}

output "authorizer_cache_ttl" {
  description = "Authorizer result cache TTL in seconds"
  value       = aws_api_gateway_authorizer.access_management.authorizer_result_ttl_in_seconds
}

#------------------------------------------------------------------------------
# Lambda Function Outputs
#------------------------------------------------------------------------------
output "lambda_function_arn" {
  description = "Lambda authorizer function ARN"
  value       = aws_lambda_function.authorizer.arn
}

output "lambda_function_name" {
  description = "Lambda authorizer function name"
  value       = aws_lambda_function.authorizer.function_name
}

output "lambda_function_invoke_arn" {
  description = "Lambda authorizer invoke ARN for API Gateway"
  value       = aws_lambda_function.authorizer.invoke_arn
}

output "lambda_function_version" {
  description = "Lambda authorizer function version"
  value       = aws_lambda_function.authorizer.version
}

output "lambda_function_qualified_arn" {
  description = "Lambda authorizer qualified ARN (includes version)"
  value       = aws_lambda_function.authorizer.qualified_arn
}

output "lambda_alias_arn" {
  description = "Lambda authorizer live alias ARN"
  value       = aws_lambda_alias.authorizer_live.arn
}

#------------------------------------------------------------------------------
# IAM Role Outputs
#------------------------------------------------------------------------------
output "lambda_role_arn" {
  description = "Lambda authorizer execution role ARN"
  value       = aws_iam_role.lambda_authorizer.arn
}

output "lambda_role_name" {
  description = "Lambda authorizer execution role name"
  value       = aws_iam_role.lambda_authorizer.name
}

output "api_gateway_invocation_role_arn" {
  description = "API Gateway authorizer invocation role ARN"
  value       = aws_iam_role.api_gateway_authorizer_invocation.arn
}

output "api_gateway_invocation_role_name" {
  description = "API Gateway authorizer invocation role name"
  value       = aws_iam_role.api_gateway_authorizer_invocation.name
}

#------------------------------------------------------------------------------
# CloudWatch Outputs
#------------------------------------------------------------------------------
output "log_group_name" {
  description = "CloudWatch Log Group name for authorizer"
  value       = aws_cloudwatch_log_group.authorizer.name
}

output "log_group_arn" {
  description = "CloudWatch Log Group ARN for authorizer"
  value       = aws_cloudwatch_log_group.authorizer.arn
}

#------------------------------------------------------------------------------
# Configuration Outputs
#------------------------------------------------------------------------------
output "jwks_url" {
  description = "JWKS URL for Cognito token verification"
  value       = local.jwks_url
}

output "issuer_url" {
  description = "JWT issuer URL for token validation"
  value       = local.issuer_url
}

output "identity_source" {
  description = "Identity source for authorizer"
  value       = aws_api_gateway_authorizer.access_management.identity_source
}

#------------------------------------------------------------------------------
# Provisioned Concurrency Output (Conditional)
#------------------------------------------------------------------------------
output "provisioned_concurrency_config" {
  description = "Provisioned concurrency configuration (if enabled)"
  value = var.provisioned_concurrency > 0 ? {
    enabled                      = true
    concurrent_executions        = var.provisioned_concurrency
    allocation_id               = aws_lambda_provisioned_concurrency_config.authorizer[0].id
  } : {
    enabled                      = false
    concurrent_executions        = 0
    allocation_id               = null
  }
}

#------------------------------------------------------------------------------
# Lambda Layer Output (Conditional)
#------------------------------------------------------------------------------
output "lambda_layer_arn" {
  description = "Lambda layer ARN for dependencies (if created)"
  value       = var.create_lambda_layer ? aws_lambda_layer_version.authorizer_dependencies[0].arn : null
}
```

---

## 6. Example Usage

### 6.1 DEV Environment

```hcl
module "cognito_authorizer" {
  source = "./modules/cognito-authorizer"

  # Environment
  environment = "dev"

  # Cognito configuration
  cognito_user_pool_id  = "eu-west-1_aBcDeFgHi"
  cognito_region        = "eu-west-1"
  cognito_app_client_id = "1234567890abcdefghijklmn"

  # DynamoDB
  dynamodb_table_name = "bbws-aipagebuilder-dev-ddb-access-management"
  dynamodb_table_arn  = "arn:aws:dynamodb:eu-west-1:536580886816:table/bbws-aipagebuilder-dev-ddb-access-management"

  # API Gateway
  api_gateway_id            = module.api_gateway.rest_api_id
  api_gateway_execution_arn = module.api_gateway.execution_arn

  # Lambda deployment
  lambda_deployment_bucket = "bbws-dev-lambda-deployments"
  lambda_deployment_key    = "access-authorizer/v1.0.0/authorizer.zip"

  # Cache settings
  authorizer_cache_ttl = 300  # 5 minutes
  jwks_cache_ttl       = 3600 # 1 hour

  # Logging
  log_level          = "INFO"
  log_retention_days = 30

  # Monitoring
  xray_tracing_enabled = true
  audit_enabled        = true

  tags = {
    Project     = "BBWS"
    System      = "Access-Management"
    Environment = "dev"
    CostCenter  = "Engineering"
  }
}
```

### 6.2 PROD Environment

```hcl
module "cognito_authorizer" {
  source = "./modules/cognito-authorizer"

  # Environment
  environment = "prod"

  # Cognito configuration (primary region: af-south-1)
  cognito_user_pool_id  = "af-south-1_XyZaBcDe"
  cognito_region        = "af-south-1"
  cognito_app_client_id = "prod1234567890abcdefgh"

  # DynamoDB
  dynamodb_table_name = "bbws-aipagebuilder-prod-ddb-access-management"
  dynamodb_table_arn  = "arn:aws:dynamodb:af-south-1:093646564004:table/bbws-aipagebuilder-prod-ddb-access-management"

  # API Gateway
  api_gateway_id            = module.api_gateway.rest_api_id
  api_gateway_execution_arn = module.api_gateway.execution_arn

  # Lambda deployment
  lambda_deployment_bucket = "bbws-prod-lambda-deployments"
  lambda_deployment_key    = "access-authorizer/v1.0.0/authorizer.zip"

  # Cache settings (same as DEV for consistency)
  authorizer_cache_ttl = 300
  jwks_cache_ttl       = 3600

  # Logging
  log_level          = "INFO"
  log_retention_days = 90  # Longer retention for PROD

  # Performance (PROD-specific)
  lambda_memory_size      = 512
  reserved_concurrency    = 100
  provisioned_concurrency = 5   # Reduce cold starts

  # Dead Letter Queue
  dead_letter_queue_arn = module.sqs.authorizer_dlq_arn

  # Monitoring
  xray_tracing_enabled = true
  audit_enabled        = true

  tags = {
    Project     = "BBWS"
    System      = "Access-Management"
    Environment = "prod"
    CostCenter  = "Engineering"
  }
}
```

---

## 7. Terraform Validation Commands

```bash
# Navigate to module directory
cd terraform/modules/cognito-authorizer

# Initialize Terraform
terraform init

# Validate configuration syntax
terraform validate

# Format check
terraform fmt -check

# Plan (with variable file)
terraform plan -var-file=environments/dev.tfvars

# Apply (with approval)
terraform apply -var-file=environments/dev.tfvars
```

---

## 8. Security Considerations

### 8.1 IAM Best Practices Applied

| Practice | Implementation |
|----------|---------------|
| Least privilege | Only required permissions granted |
| Resource-based policies | ARN restrictions on all policies |
| Service conditions | Source account/ARN conditions on assume role |
| No wildcards | Specific resource ARNs where possible |
| Separate roles | Lambda and API Gateway have distinct roles |

### 8.2 Token Validation Security

| Security Feature | Implementation |
|------------------|---------------|
| RS256 signature verification | Via Cognito JWKS |
| Issuer validation | Matches Cognito User Pool URL |
| Expiry validation | JWT exp claim checked |
| Token use validation | access/id token type verified |
| Fail-closed design | Deny on any error |

### 8.3 Data Protection

| Protection | Implementation |
|------------|---------------|
| In-transit encryption | HTTPS only for Cognito JWKS |
| CloudWatch Logs | Server-side encryption enabled |
| Environment variables | No secrets (only IDs) |
| DynamoDB access | Read-only for authorizer |

---

## 9. Monitoring and Alerting Recommendations

### 9.1 CloudWatch Metrics

| Metric | Threshold | Action |
|--------|-----------|--------|
| Lambda Errors | > 1% | Alert |
| Lambda Duration p99 | > 5s | Alert |
| Lambda Throttles | > 0 | Alert |
| API Gateway 401 | > 10% | Alert |
| API Gateway 403 | > 5% | Alert |

### 9.2 CloudWatch Alarms (To be created in worker-6)

```hcl
# Reference for CloudWatch module
resource "aws_cloudwatch_metric_alarm" "authorizer_errors" {
  alarm_name          = "bbws-access-${var.environment}-authorizer-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "Authorizer Lambda error rate exceeded"

  dimensions = {
    FunctionName = module.cognito_authorizer.lambda_function_name
  }

  alarm_actions = [var.sns_alert_topic_arn]
}
```

---

## 10. Success Criteria Checklist

| Criteria | Status |
|----------|--------|
| Lambda authorizer configured | COMPLETE |
| API Gateway authorizer created | COMPLETE |
| Cognito variables parameterized | COMPLETE |
| JWKS URL correctly formed | COMPLETE |
| Cache TTL configured (300s) | COMPLETE |
| IAM permissions for invocation | COMPLETE |
| Environment variables set | COMPLETE |
| Outputs include authorizer ID | COMPLETE |
| Multi-environment support | COMPLETE |
| Fail-closed security design | COMPLETE |
| Dead Letter Queue support | COMPLETE |
| X-Ray tracing support | COMPLETE |
| Provisioned concurrency (PROD) | COMPLETE |

---

## References

- **Stage 1 Input**: worker-5-authorizer-service-review/output.md
- **LLD Document**: LLD 2.8.5 Authorizer Service
- **AWS Documentation**: [API Gateway Lambda Authorizers](https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-use-lambda-authorizer.html)
- **Cognito JWT Verification**: [Verifying a JWT](https://docs.aws.amazon.com/cognito/latest/developerguide/amazon-cognito-user-pools-using-tokens-verifying-a-jwt.html)
- **Terraform AWS Provider**: [aws_api_gateway_authorizer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_authorizer)

---

**End of Output Document**
