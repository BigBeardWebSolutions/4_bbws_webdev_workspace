# Worker Instructions: Terraform IAM Module

**Worker ID**: worker-5-terraform-iam-module
**Stage**: Stage 1 - Repository Setup & Infrastructure Code
**Project**: project-plan-campaigns

---

## Task

Create the Terraform IAM module (`iam.tf`) for Lambda execution roles and policies with DynamoDB access.

---

## Inputs

**Primary Input**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/2.1.3_LLD_Campaigns_Lambda.md`

**Reference**:
- Section 12: Security

---

## Deliverables

Create `terraform/iam.tf` with the following:

### 1. Lambda Execution Role

Single execution role for all 5 Lambda functions with:
- AssumeRole policy for Lambda service
- CloudWatch Logs write permissions
- DynamoDB read/write permissions for campaigns table

### 2. Required Permissions

| Service | Actions | Resource |
|---------|---------|----------|
| CloudWatch Logs | CreateLogGroup, CreateLogStream, PutLogEvents | Lambda log groups |
| DynamoDB | GetItem, PutItem, UpdateItem, DeleteItem, Scan, Query | Campaigns table |
| DynamoDB | Query | GSI (CampaignsByStatusIndex) |

---

## Expected Output Format

```hcl
# terraform/iam.tf

# Lambda Execution Role
resource "aws_iam_role" "lambda_execution_role" {
  name = "${var.project_name}-lambda-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Component = "CampaignsLambda"
    Role      = "LambdaExecution"
  })
}

# CloudWatch Logs Policy
resource "aws_iam_role_policy" "lambda_logs" {
  name = "${var.project_name}-lambda-logs-${var.environment}"
  role = aws_iam_role.lambda_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.project_name}-*-${var.environment}:*"
        ]
      }
    ]
  })
}

# DynamoDB Policy
resource "aws_iam_role_policy" "lambda_dynamodb" {
  name = "${var.project_name}-lambda-dynamodb-${var.environment}"
  role = aws_iam_role.lambda_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DynamoDBTableAccess"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Scan",
          "dynamodb:Query",
          "dynamodb:ConditionCheckItem"
        ]
        Resource = [
          aws_dynamodb_table.campaigns.arn
        ]
      },
      {
        Sid    = "DynamoDBGSIAccess"
        Effect = "Allow"
        Action = [
          "dynamodb:Query"
        ]
        Resource = [
          "${aws_dynamodb_table.campaigns.arn}/index/*"
        ]
      }
    ]
  })
}

# X-Ray Tracing Policy (optional but recommended)
resource "aws_iam_role_policy" "lambda_xray" {
  name = "${var.project_name}-lambda-xray-${var.environment}"
  role = aws_iam_role.lambda_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
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

# Data source for current AWS account
data "aws_caller_identity" "current" {}
```

---

## Variables Required (add to variables.tf)

```hcl
variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
}
```

---

## Outputs Required (add to outputs.tf)

```hcl
output "lambda_execution_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = aws_iam_role.lambda_execution_role.arn
}

output "lambda_execution_role_name" {
  description = "Name of the Lambda execution role"
  value       = aws_iam_role.lambda_execution_role.name
}
```

---

## Security Best Practices

### Principle of Least Privilege

1. **Specific Resource ARNs**
   - Use exact table ARN, not wildcards
   - Use exact log group patterns

2. **Limited Actions**
   - Only grant required DynamoDB actions
   - No admin permissions

3. **Separated Policies**
   - CloudWatch Logs separate from DynamoDB
   - Easy to audit and modify

### IMPORTANT: No Hardcoded Credentials

From CLAUDE.md:
> "never hardcode environment credentials, parameterise them so that we can deploy to any environment without breaking the system"

All ARNs and resource names must use variables:
- `${var.aws_region}` not `eu-west-1`
- `${var.environment}` not `dev`
- `${data.aws_caller_identity.current.account_id}` not account number

---

## Success Criteria

- [ ] Lambda execution role created
- [ ] CloudWatch Logs permissions granted
- [ ] DynamoDB table and GSI permissions granted
- [ ] X-Ray tracing permissions granted
- [ ] No hardcoded credentials or ARNs
- [ ] Follows least privilege principle
- [ ] Tags include Project, Component
- [ ] Terraform validates successfully

---

## Execution Steps

1. Read LLD Section 12 for security requirements
2. Create iam.tf with execution role
3. Add CloudWatch Logs policy
4. Add DynamoDB policy for table and GSI
5. Add X-Ray policy
6. Add data source for account ID
7. Add variables and outputs
8. Run `terraform validate`
9. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-15
