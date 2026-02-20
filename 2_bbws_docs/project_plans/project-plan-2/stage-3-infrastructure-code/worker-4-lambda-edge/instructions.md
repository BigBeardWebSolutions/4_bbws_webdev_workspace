# Worker 3-4: Lambda@Edge Basic Auth

**Worker ID**: worker-4-lambda-edge
**Stage**: Stage 3 - Infrastructure Code Development
**Status**: PENDING
**Agent**: DevOps Engineer Agent
**Repository**: `2_1_bbws_infrastructure`

---

## Objective

Create Lambda@Edge function for Basic Authentication and Terraform module for deployment. Lambda@Edge will intercept viewer requests to CloudFront and require username/password for DEV and SIT environments.

---

## Prerequisites

- ✅ CloudFront distribution created (Worker 3-1)
- ✅ Node.js 18.x runtime supported in Lambda@Edge

---

## IMPORTANT: Region and Replication

- Lambda@Edge functions **MUST be created in us-east-1**
- Lambda@Edge automatically replicates to all CloudFront edge locations (5-10 minutes)
- CloudWatch Logs are created in each region where function executes

---

## Tasks

### 1. Create Lambda Function Code

**Directory**: `lambda/basic-auth/`

#### 1.1 Lambda Function (`index.js`)

```javascript
// lambda/basic-auth/index.js

'use strict';

exports.handler = async (event) => {
  const request = event.Records[0].cf.request;
  const headers = request.headers;

  // Basic Auth credentials (from environment variables or hardcoded)
  const authUser = process.env.BASIC_AUTH_USER || 'admin';
  const authPass = process.env.BASIC_AUTH_PASS || 'changeme';

  // Build expected Authorization header
  const authString = `${authUser}:${authPass}`;
  const encodedAuthString = Buffer.from(authString).toString('base64');
  const expectedAuth = `Basic ${encodedAuthString}`;

  // Check if Authorization header exists
  if (typeof headers.authorization === 'undefined' || headers.authorization[0].value !== expectedAuth) {
    // Return 401 Unauthorized
    return {
      status: '401',
      statusDescription: 'Unauthorized',
      headers: {
        'www-authenticate': [{
          key: 'WWW-Authenticate',
          value: 'Basic realm="Secure Area"'
        }],
        'content-type': [{
          key: 'Content-Type',
          value: 'text/plain; charset=UTF-8'
        }]
      },
      body: '401 Unauthorized - Authentication required'
    };
  }

  // Authentication successful, continue request
  return request;
};
```

#### 1.2 Package Metadata (`package.json`)

```json
{
  "name": "lambda-edge-basic-auth",
  "version": "1.0.0",
  "description": "Lambda@Edge function for Basic Authentication",
  "main": "index.js",
  "author": "DevOps Team",
  "license": "MIT",
  "engines": {
    "node": ">=18.0.0"
  }
}
```

---

### 2. Create Lambda@Edge Terraform Module

**Directory**: `modules/lambda-edge/`

#### 2.1 Main Configuration (`main.tf`)

```hcl
# modules/lambda-edge/main.tf

# IAM Role for Lambda@Edge
resource "aws_iam_role" "lambda_edge" {
  provider = aws.us_east_1

  name               = "${var.environment}-lambda-edge-basic-auth"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = [
            "lambda.amazonaws.com",
            "edgelambda.amazonaws.com"
          ]
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-lambda-edge-basic-auth"
      Environment = var.environment
    }
  )
}

# Attach AWS managed policy for Lambda@Edge execution
resource "aws_iam_role_policy_attachment" "lambda_edge_basic" {
  provider = aws.us_east_1

  role       = aws_iam_role.lambda_edge.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda function code (zip archive)
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../lambda/basic-auth"
  output_path = "${path.module}/lambda_function.zip"
  excludes    = ["lambda_function.zip"]
}

# Lambda@Edge Function
resource "aws_lambda_function" "basic_auth" {
  provider = aws.us_east_1

  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.environment}-basic-auth"
  role             = aws_iam_role.lambda_edge.arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "nodejs18.x"
  timeout          = 5  # Max 30 seconds for viewer-request
  memory_size      = 128
  publish          = true  # REQUIRED for Lambda@Edge

  environment {
    variables = {
      BASIC_AUTH_USER = var.basic_auth_username
      BASIC_AUTH_PASS = var.basic_auth_password
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-basic-auth"
      Environment = var.environment
    }
  )
}

# CloudWatch Log Group (us-east-1)
resource "aws_cloudwatch_log_group" "lambda_edge" {
  provider = aws.us_east_1

  name              = "/aws/lambda/${aws_lambda_function.basic_auth.function_name}"
  retention_in_days = 7

  tags = var.tags
}
```

#### 2.2 Variables (`variables.tf`)

```hcl
# modules/lambda-edge/variables.tf

variable "environment" {
  description = "Environment name (dev, sit, prod)"
  type        = string
}

variable "basic_auth_username" {
  description = "Basic Auth username"
  type        = string
  default     = "admin"
}

variable "basic_auth_password" {
  description = "Basic Auth password"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
```

#### 2.3 Outputs (`outputs.tf`)

```hcl
# modules/lambda-edge/outputs.tf

output "function_arn" {
  description = "ARN of the Lambda@Edge function (qualified ARN with version)"
  value       = aws_lambda_function.basic_auth.qualified_arn
}

output "function_name" {
  description = "Name of the Lambda@Edge function"
  value       = aws_lambda_function.basic_auth.function_name
}

output "function_version" {
  description = "Version of the Lambda@Edge function"
  value       = aws_lambda_function.basic_auth.version
}

output "iam_role_arn" {
  description = "ARN of the IAM role for Lambda@Edge"
  value       = aws_iam_role.lambda_edge.arn
}
```

---

### 3. Create Module README

**File**: `modules/lambda-edge/README.md`

```markdown
# Lambda@Edge Basic Auth Module

Terraform module for creating Lambda@Edge function for Basic Authentication.

## Features

- Lambda@Edge function in us-east-1
- Basic Authentication (username/password)
- IAM role with least privilege
- CloudWatch Logs (7-day retention)
- Automatic versioning (publish = true)

## Usage

\`\`\`hcl
module "lambda_edge" {
  source = "../../modules/lambda-edge"

  providers = {
    aws.us_east_1 = aws.us_east_1
  }

  environment          = "dev"
  basic_auth_username  = "admin"
  basic_auth_password  = var.basic_auth_password  # From terraform.tfvars

  tags = {
    Project = "Buy Page"
  }
}
\`\`\`

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| environment | Environment | string | yes |
| basic_auth_username | Username | string | no (default: admin) |
| basic_auth_password | Password (sensitive) | string | yes |
| tags | Additional tags | map(string) | no |

## Outputs

| Name | Description |
|------|-------------|
| function_arn | Qualified ARN (with version) |
| function_name | Function name |
| function_version | Function version |
| iam_role_arn | IAM role ARN |

## Important Notes

- **Region**: Must be created in us-east-1
- **Publish**: Must set `publish = true` for Lambda@Edge
- **Version**: Use `qualified_arn` (includes version number)
- **Replication**: Takes 5-10 minutes to replicate globally
- **Logs**: CloudWatch Logs created in every region where function executes

## Security Considerations

- Store password in AWS Secrets Manager (future enhancement)
- Use strong passwords (12+ characters)
- Rotate credentials regularly
- Disable Basic Auth in production (use CloudFront signed URLs instead)

## Testing

\`\`\`bash
# Test locally (Node.js required)
cd lambda/basic-auth
node -e "const handler = require('./index').handler; \
  handler({Records:[{cf:{request:{headers:{}}}}]}).then(console.log)"

# Expected: 401 Unauthorized response

# Test with auth header
node -e "const handler = require('./index').handler; \
  const authHeader = Buffer.from('admin:changeme').toString('base64'); \
  handler({Records:[{cf:{request:{headers:{authorization:[{value:'Basic '+authHeader}]}}}}]}).then(console.log)"

# Expected: Request object returned
\`\`\`
```

---

## Deliverables

### Lambda Function Code
- [x] `lambda/basic-auth/index.js` - Lambda function
- [x] `lambda/basic-auth/package.json` - Package metadata

### Terraform Module
- [x] `modules/lambda-edge/main.tf` - Lambda@Edge resources
- [x] `modules/lambda-edge/variables.tf` - Module variables
- [x] `modules/lambda-edge/outputs.tf` - Module outputs
- [x] `modules/lambda-edge/README.md` - Documentation

---

## Success Criteria

- [ ] Lambda function code created and tested
- [ ] Lambda@Edge module created
- [ ] IAM role configured with least privilege
- [ ] Terraform validates successfully
- [ ] Module README complete
- [ ] output.md created

---

## Testing

```bash
# Validate Terraform
cd modules/lambda-edge
terraform validate
terraform fmt -check

# Test Lambda function locally
cd ../../lambda/basic-auth
npm test  # If tests written

# After deployment, test via browser
# Navigate to https://dev.kimmyai.io
# Expected: Browser prompts for username/password
```

---

## CloudFront Integration

**In CloudFront module** (`modules/cloudfront/main.tf`):

```hcl
default_cache_behavior {
  # ... other settings ...

  lambda_function_association {
    event_type   = "viewer-request"
    lambda_arn   = var.lambda_edge_function_arn  # Qualified ARN
    include_body = false
  }
}
```

---

## Important Notes

- Lambda@Edge has strict limits (128MB memory max for viewer-request)
- Viewer-request timeout is max 5 seconds
- Environment variables work but increase package size
- For production, use CloudFront signed URLs or AWS WAF instead

---

**Created**: 2025-12-30
**Worker**: worker-4-lambda-edge
**Status**: PENDING
