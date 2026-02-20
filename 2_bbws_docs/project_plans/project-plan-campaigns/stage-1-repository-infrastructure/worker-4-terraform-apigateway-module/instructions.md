# Worker Instructions: Terraform API Gateway Module

**Worker ID**: worker-4-terraform-apigateway-module
**Stage**: Stage 1 - Repository Setup & Infrastructure Code
**Project**: project-plan-campaigns

---

## Task

Create the Terraform API Gateway module (`api_gateway.tf`) for exposing the Campaign Lambda functions as REST API endpoints.

---

## Inputs

**Primary Input**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/2.1.3_LLD_Campaigns_Lambda.md`

**Reference**:
- Section 6: REST API Operations

---

## Deliverables

Create `terraform/api_gateway.tf` with the following API endpoints:

### 1. API Endpoints

| Method | Path | Lambda Function | Auth |
|--------|------|-----------------|------|
| GET | /v1.0/campaigns | list_campaigns | Public |
| GET | /v1.0/campaigns/{code} | get_campaign | Public |
| POST | /v1.0/campaigns | create_campaign | Admin (TBC) |
| PUT | /v1.0/campaigns/{code} | update_campaign | Admin (TBC) |
| DELETE | /v1.0/campaigns/{code} | delete_campaign | Admin (TBC) |

### 2. Configuration

| Attribute | Value |
|-----------|-------|
| API Type | REST API (Regional) |
| Stage | v1.0 |
| CORS | Enabled |
| Throttling | 100 req/s burst, 50 req/s rate |

---

## Expected Output Format

```hcl
# terraform/api_gateway.tf

# REST API
resource "aws_api_gateway_rest_api" "campaigns_api" {
  name        = "${var.project_name}-api-${var.environment}"
  description = "Campaign Management API for ${var.environment}"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = merge(var.common_tags, {
    Component = "CampaignsAPI"
  })
}

# API Resource: /v1.0
resource "aws_api_gateway_resource" "v1" {
  rest_api_id = aws_api_gateway_rest_api.campaigns_api.id
  parent_id   = aws_api_gateway_rest_api.campaigns_api.root_resource_id
  path_part   = "v1.0"
}

# API Resource: /v1.0/campaigns
resource "aws_api_gateway_resource" "campaigns" {
  rest_api_id = aws_api_gateway_rest_api.campaigns_api.id
  parent_id   = aws_api_gateway_resource.v1.id
  path_part   = "campaigns"
}

# API Resource: /v1.0/campaigns/{code}
resource "aws_api_gateway_resource" "campaign_code" {
  rest_api_id = aws_api_gateway_rest_api.campaigns_api.id
  parent_id   = aws_api_gateway_resource.campaigns.id
  path_part   = "{code}"
}

# ====================
# GET /v1.0/campaigns
# ====================
resource "aws_api_gateway_method" "list_campaigns" {
  rest_api_id   = aws_api_gateway_rest_api.campaigns_api.id
  resource_id   = aws_api_gateway_resource.campaigns.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "list_campaigns" {
  rest_api_id             = aws_api_gateway_rest_api.campaigns_api.id
  resource_id             = aws_api_gateway_resource.campaigns.id
  http_method             = aws_api_gateway_method.list_campaigns.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.list_campaigns.invoke_arn
}

# ====================
# GET /v1.0/campaigns/{code}
# ====================
resource "aws_api_gateway_method" "get_campaign" {
  rest_api_id   = aws_api_gateway_rest_api.campaigns_api.id
  resource_id   = aws_api_gateway_resource.campaign_code.id
  http_method   = "GET"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.code" = true
  }
}

resource "aws_api_gateway_integration" "get_campaign" {
  rest_api_id             = aws_api_gateway_rest_api.campaigns_api.id
  resource_id             = aws_api_gateway_resource.campaign_code.id
  http_method             = aws_api_gateway_method.get_campaign.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.get_campaign.invoke_arn
}

# ====================
# POST /v1.0/campaigns
# ====================
resource "aws_api_gateway_method" "create_campaign" {
  rest_api_id   = aws_api_gateway_rest_api.campaigns_api.id
  resource_id   = aws_api_gateway_resource.campaigns.id
  http_method   = "POST"
  authorization = "NONE"  # TODO: Add API key or IAM auth
}

resource "aws_api_gateway_integration" "create_campaign" {
  rest_api_id             = aws_api_gateway_rest_api.campaigns_api.id
  resource_id             = aws_api_gateway_resource.campaigns.id
  http_method             = aws_api_gateway_method.create_campaign.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.create_campaign.invoke_arn
}

# ====================
# PUT /v1.0/campaigns/{code}
# ====================
resource "aws_api_gateway_method" "update_campaign" {
  rest_api_id   = aws_api_gateway_rest_api.campaigns_api.id
  resource_id   = aws_api_gateway_resource.campaign_code.id
  http_method   = "PUT"
  authorization = "NONE"  # TODO: Add API key or IAM auth

  request_parameters = {
    "method.request.path.code" = true
  }
}

resource "aws_api_gateway_integration" "update_campaign" {
  rest_api_id             = aws_api_gateway_rest_api.campaigns_api.id
  resource_id             = aws_api_gateway_resource.campaign_code.id
  http_method             = aws_api_gateway_method.update_campaign.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.update_campaign.invoke_arn
}

# ====================
# DELETE /v1.0/campaigns/{code}
# ====================
resource "aws_api_gateway_method" "delete_campaign" {
  rest_api_id   = aws_api_gateway_rest_api.campaigns_api.id
  resource_id   = aws_api_gateway_resource.campaign_code.id
  http_method   = "DELETE"
  authorization = "NONE"  # TODO: Add API key or IAM auth

  request_parameters = {
    "method.request.path.code" = true
  }
}

resource "aws_api_gateway_integration" "delete_campaign" {
  rest_api_id             = aws_api_gateway_rest_api.campaigns_api.id
  resource_id             = aws_api_gateway_resource.campaign_code.id
  http_method             = aws_api_gateway_method.delete_campaign.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.delete_campaign.invoke_arn
}

# ====================
# CORS Configuration
# ====================
resource "aws_api_gateway_method" "campaigns_options" {
  rest_api_id   = aws_api_gateway_rest_api.campaigns_api.id
  resource_id   = aws_api_gateway_resource.campaigns.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "campaigns_options" {
  rest_api_id = aws_api_gateway_rest_api.campaigns_api.id
  resource_id = aws_api_gateway_resource.campaigns.id
  http_method = aws_api_gateway_method.campaigns_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "campaigns_options_200" {
  rest_api_id = aws_api_gateway_rest_api.campaigns_api.id
  resource_id = aws_api_gateway_resource.campaigns.id
  http_method = aws_api_gateway_method.campaigns_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "campaigns_options" {
  rest_api_id = aws_api_gateway_rest_api.campaigns_api.id
  resource_id = aws_api_gateway_resource.campaigns.id
  http_method = aws_api_gateway_method.campaigns_options.http_method
  status_code = aws_api_gateway_method_response.campaigns_options_200.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization,X-Amz-Date,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,PUT,DELETE,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# CORS for {code} resource
resource "aws_api_gateway_method" "campaign_code_options" {
  rest_api_id   = aws_api_gateway_rest_api.campaigns_api.id
  resource_id   = aws_api_gateway_resource.campaign_code.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "campaign_code_options" {
  rest_api_id = aws_api_gateway_rest_api.campaigns_api.id
  resource_id = aws_api_gateway_resource.campaign_code.id
  http_method = aws_api_gateway_method.campaign_code_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "campaign_code_options_200" {
  rest_api_id = aws_api_gateway_rest_api.campaigns_api.id
  resource_id = aws_api_gateway_resource.campaign_code.id
  http_method = aws_api_gateway_method.campaign_code_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "campaign_code_options" {
  rest_api_id = aws_api_gateway_rest_api.campaigns_api.id
  resource_id = aws_api_gateway_resource.campaign_code.id
  http_method = aws_api_gateway_method.campaign_code_options.http_method
  status_code = aws_api_gateway_method_response.campaign_code_options_200.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization,X-Amz-Date,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,PUT,DELETE,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# ====================
# Lambda Permissions
# ====================
resource "aws_lambda_permission" "list_campaigns" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.list_campaigns.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.campaigns_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "get_campaign" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_campaign.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.campaigns_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "create_campaign" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_campaign.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.campaigns_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "update_campaign" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.update_campaign.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.campaigns_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "delete_campaign" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.delete_campaign.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.campaigns_api.execution_arn}/*/*"
}

# ====================
# API Deployment
# ====================
resource "aws_api_gateway_deployment" "campaigns" {
  depends_on = [
    aws_api_gateway_integration.list_campaigns,
    aws_api_gateway_integration.get_campaign,
    aws_api_gateway_integration.create_campaign,
    aws_api_gateway_integration.update_campaign,
    aws_api_gateway_integration.delete_campaign,
    aws_api_gateway_integration.campaigns_options,
    aws_api_gateway_integration.campaign_code_options,
  ]

  rest_api_id = aws_api_gateway_rest_api.campaigns_api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.campaigns.id,
      aws_api_gateway_resource.campaign_code.id,
      aws_api_gateway_method.list_campaigns.id,
      aws_api_gateway_method.get_campaign.id,
      aws_api_gateway_method.create_campaign.id,
      aws_api_gateway_method.update_campaign.id,
      aws_api_gateway_method.delete_campaign.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "v1" {
  deployment_id = aws_api_gateway_deployment.campaigns.id
  rest_api_id   = aws_api_gateway_rest_api.campaigns_api.id
  stage_name    = "v1"

  tags = merge(var.common_tags, {
    Stage = "v1"
  })
}

# ====================
# Throttling Settings
# ====================
resource "aws_api_gateway_method_settings" "campaigns" {
  rest_api_id = aws_api_gateway_rest_api.campaigns_api.id
  stage_name  = aws_api_gateway_stage.v1.stage_name
  method_path = "*/*"

  settings {
    throttling_burst_limit = var.api_throttle_burst
    throttling_rate_limit  = var.api_throttle_rate
    logging_level          = "INFO"
    metrics_enabled        = true
    data_trace_enabled     = var.environment != "prod"
  }
}
```

---

## Variables Required (add to variables.tf)

```hcl
variable "api_throttle_burst" {
  description = "API Gateway throttle burst limit"
  type        = number
  default     = 100
}

variable "api_throttle_rate" {
  description = "API Gateway throttle rate limit"
  type        = number
  default     = 50
}
```

---

## Outputs Required (add to outputs.tf)

```hcl
output "api_gateway_id" {
  description = "API Gateway REST API ID"
  value       = aws_api_gateway_rest_api.campaigns_api.id
}

output "api_gateway_url" {
  description = "API Gateway base URL"
  value       = aws_api_gateway_stage.v1.invoke_url
}

output "api_endpoints" {
  description = "API endpoint URLs"
  value = {
    list_campaigns   = "${aws_api_gateway_stage.v1.invoke_url}/v1.0/campaigns"
    get_campaign     = "${aws_api_gateway_stage.v1.invoke_url}/v1.0/campaigns/{code}"
    create_campaign  = "${aws_api_gateway_stage.v1.invoke_url}/v1.0/campaigns"
    update_campaign  = "${aws_api_gateway_stage.v1.invoke_url}/v1.0/campaigns/{code}"
    delete_campaign  = "${aws_api_gateway_stage.v1.invoke_url}/v1.0/campaigns/{code}"
  }
}
```

---

## Success Criteria

- [ ] All 5 REST endpoints defined
- [ ] CORS enabled for all endpoints
- [ ] Lambda permissions configured
- [ ] Stage deployed with throttling
- [ ] Regional endpoint type
- [ ] No hardcoded values
- [ ] Terraform validates successfully

---

## Execution Steps

1. Read LLD Section 6 for API specifications
2. Create api_gateway.tf with REST API
3. Define all resources and methods
4. Configure CORS for all endpoints
5. Add Lambda permissions
6. Configure deployment and stage
7. Add throttling settings
8. Add variables and outputs
9. Run `terraform validate`
10. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-15
