# Worker Instructions: Cognito Integration Module

**Worker ID**: worker-4-cognito-integration-module
**Stage**: Stage 2 - Infrastructure Terraform
**Project**: project-plan-2-access-management

---

## Task

Create Terraform module for Cognito authorizer integration with API Gateway. Configure Lambda authorizer that validates Cognito JWTs.

---

## Inputs

**From Stage 1**:
- worker-5-authorizer-service-review/output.md (Authorizer specs)

**LLD Reference**:
- LLD 2.8.5 Authorizer Service

---

## Deliverables

Create Terraform module in `output.md`:

### 1. Module Structure

```
terraform/modules/cognito-authorizer/
├── main.tf           # Authorizer definition
├── lambda.tf         # Authorizer Lambda config
├── variables.tf
└── outputs.tf
```

### 2. Lambda Authorizer Configuration

**Type**: TOKEN (Authorization header)
**Identity Source**: method.request.header.Authorization
**TTL**: 300 seconds (5 minutes)

### 3. Authorizer Lambda

**Function Name**: `bbws-access-{env}-lambda-authorizer`
**Runtime**: Python 3.12
**Architecture**: arm64
**Memory**: 512 MB
**Timeout**: 10 seconds

**Environment Variables**:
```hcl
COGNITO_USER_POOL_ID     = var.cognito_user_pool_id
COGNITO_REGION           = var.region
DYNAMODB_TABLE           = var.dynamodb_table_name
JWKS_CACHE_TTL           = "3600"
PERMISSION_CACHE_TTL     = "300"
```

### 4. Cognito Configuration

**Variables Required**:
- cognito_user_pool_id
- cognito_app_client_id
- cognito_domain (for JWKS URL)

**JWKS URL Pattern**:
```
https://cognito-idp.{region}.amazonaws.com/{userPoolId}/.well-known/jwks.json
```

### 5. API Gateway Authorizer

```hcl
resource "aws_api_gateway_authorizer" "access_management" {
  name                   = "access-management-authorizer"
  rest_api_id            = var.api_gateway_id
  authorizer_uri         = aws_lambda_function.authorizer.invoke_arn
  authorizer_credentials = aws_iam_role.authorizer_invocation.arn
  type                   = "TOKEN"
  identity_source        = "method.request.header.Authorization"
  authorizer_result_ttl_in_seconds = 300
}
```

### 6. IAM for API Gateway to Invoke Lambda

```hcl
resource "aws_iam_role" "authorizer_invocation" {
  name = "bbws-access-${var.environment}-role-apigw-authorizer"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "apigateway.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}
```

---

## Success Criteria

- [ ] Lambda authorizer configured
- [ ] API Gateway authorizer created
- [ ] Cognito variables parameterized
- [ ] JWKS URL correctly formed
- [ ] Cache TTL configured
- [ ] IAM permissions for invocation
- [ ] Environment variables set
- [ ] Outputs include authorizer ID

---

## Execution Steps

1. Read Authorizer service review output
2. Create Lambda function configuration
3. Create API Gateway authorizer
4. Configure IAM for invocation
5. Set environment variables
6. Create variables for Cognito
7. Create outputs
8. Validate Terraform
9. Create output.md
10. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-23
