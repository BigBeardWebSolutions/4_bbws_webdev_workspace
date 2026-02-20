# Worker Instructions: Terraform Lambda Module

**Worker ID**: worker-2-terraform-lambda-module
**Stage**: Stage 1 - Repository Setup & Infrastructure Code
**Project**: project-plan-campaigns

---

## Task

Create the Terraform Lambda module (`lambda.tf`) for deploying 5 Lambda functions with Python 3.12, arm64 architecture.

---

## Inputs

**Primary Input**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/2.1.3_LLD_Campaigns_Lambda.md`

**Reference**:
- Section 1.2: Component Overview
- Section 1.3: Lambda Functions

---

## Deliverables

Create `terraform/lambda.tf` with the following Lambda functions:

### 1. Lambda Functions (5 Total)

| Function Name | Handler | Description |
|---------------|---------|-------------|
| list_campaigns | handlers.list_campaigns.handler | GET /v1.0/campaigns |
| get_campaign | handlers.get_campaign.handler | GET /v1.0/campaigns/{code} |
| create_campaign | handlers.create_campaign.handler | POST /v1.0/campaigns |
| update_campaign | handlers.update_campaign.handler | PUT /v1.0/campaigns/{code} |
| delete_campaign | handlers.delete_campaign.handler | DELETE /v1.0/campaigns/{code} |

### 2. Lambda Configuration

| Attribute | Value |
|-----------|-------|
| Runtime | python3.12 |
| Architecture | arm64 |
| Memory | 256 MB |
| Timeout | 30 seconds |
| Handler | src.handlers.{function_name}.handler |

### 3. Environment Variables

All Lambda functions must include:
```
CAMPAIGNS_TABLE_NAME = var.dynamodb_table_name
ENVIRONMENT = var.environment
LOG_LEVEL = var.log_level
```

---

## Expected Output Format

```hcl
# terraform/lambda.tf

# Lambda function for listing campaigns
resource "aws_lambda_function" "list_campaigns" {
  function_name = "${var.project_name}-list-campaigns-${var.environment}"
  description   = "List all active campaigns"

  runtime       = "python3.12"
  architectures = ["arm64"]
  handler       = "src.handlers.list_campaigns.handler"

  memory_size = var.lambda_memory
  timeout     = var.lambda_timeout

  filename         = var.lambda_zip_path
  source_code_hash = filebase64sha256(var.lambda_zip_path)

  role = aws_iam_role.lambda_execution_role.arn

  environment {
    variables = {
      CAMPAIGNS_TABLE_NAME = var.dynamodb_table_name
      ENVIRONMENT          = var.environment
      LOG_LEVEL            = var.log_level
    }
  }

  tags = merge(var.common_tags, {
    Function = "list-campaigns"
  })
}

# (Repeat for other 4 functions)

# Lambda function for getting campaign by code
resource "aws_lambda_function" "get_campaign" {
  # ...
}

# Lambda function for creating campaign
resource "aws_lambda_function" "create_campaign" {
  # ...
}

# Lambda function for updating campaign
resource "aws_lambda_function" "update_campaign" {
  # ...
}

# Lambda function for deleting campaign (soft delete)
resource "aws_lambda_function" "delete_campaign" {
  # ...
}

# CloudWatch Log Groups for each Lambda
resource "aws_cloudwatch_log_group" "list_campaigns" {
  name              = "/aws/lambda/${aws_lambda_function.list_campaigns.function_name}"
  retention_in_days = var.log_retention_days

  tags = var.common_tags
}

# (Repeat for other 4 log groups)
```

---

## Variables Required (add to variables.tf)

```hcl
variable "project_name" {
  description = "Project name prefix for resources"
  type        = string
  default     = "bbws-campaigns"
}

variable "environment" {
  description = "Deployment environment (dev, sit, prod)"
  type        = string
}

variable "lambda_memory" {
  description = "Lambda memory in MB"
  type        = number
  default     = 256
}

variable "lambda_timeout" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 30
}

variable "lambda_zip_path" {
  description = "Path to Lambda deployment package"
  type        = string
  default     = "../dist/lambda.zip"
}

variable "log_level" {
  description = "Logging level for Lambda functions"
  type        = string
  default     = "INFO"
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 90
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
```

---

## Outputs Required (add to outputs.tf)

```hcl
output "lambda_function_arns" {
  description = "ARNs of all Lambda functions"
  value = {
    list_campaigns   = aws_lambda_function.list_campaigns.arn
    get_campaign     = aws_lambda_function.get_campaign.arn
    create_campaign  = aws_lambda_function.create_campaign.arn
    update_campaign  = aws_lambda_function.update_campaign.arn
    delete_campaign  = aws_lambda_function.delete_campaign.arn
  }
}

output "lambda_function_names" {
  description = "Names of all Lambda functions"
  value = {
    list_campaigns   = aws_lambda_function.list_campaigns.function_name
    get_campaign     = aws_lambda_function.get_campaign.function_name
    create_campaign  = aws_lambda_function.create_campaign.function_name
    update_campaign  = aws_lambda_function.update_campaign.function_name
    delete_campaign  = aws_lambda_function.delete_campaign.function_name
  }
}

output "lambda_invoke_arns" {
  description = "Invoke ARNs for API Gateway integration"
  value = {
    list_campaigns   = aws_lambda_function.list_campaigns.invoke_arn
    get_campaign     = aws_lambda_function.get_campaign.invoke_arn
    create_campaign  = aws_lambda_function.create_campaign.invoke_arn
    update_campaign  = aws_lambda_function.update_campaign.invoke_arn
    delete_campaign  = aws_lambda_function.delete_campaign.invoke_arn
  }
}
```

---

## Success Criteria

- [ ] All 5 Lambda functions defined
- [ ] Runtime is python3.12
- [ ] Architecture is arm64
- [ ] Memory is 256 MB
- [ ] Timeout is 30 seconds
- [ ] Environment variables configured
- [ ] CloudWatch log groups created
- [ ] No hardcoded values (use variables)
- [ ] Terraform validates successfully

---

## Execution Steps

1. Read LLD Section 1.2 and 1.3 for specifications
2. Create lambda.tf with all 5 functions
3. Add required variables to variables.tf
4. Add outputs to outputs.tf
5. Ensure tags include Project, Component, CostCenter
6. Run `terraform validate`
7. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-15
