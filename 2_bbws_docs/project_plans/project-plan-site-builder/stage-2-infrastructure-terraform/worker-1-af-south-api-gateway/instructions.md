# Worker Instructions: API Gateway Terraform Module

**Worker ID**: worker-1-af-south-api-gateway
**Stage**: Stage 2 - Infrastructure (Terraform)
**Project**: project-plan-site-builder

---

## Task

Create Terraform module for API Gateway REST API in af-south-1, including WAF integration, usage plans, and CORS configuration.

---

## Inputs

**Reference Documents**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/HLDs/BBSW_Site_Builder_HLD_v3.md` (Section 5: API Design)
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/3.1.2_LLD_Site_Builder_Generation_API.md` (Section 3: OpenAPI)

**Stage 1 Outputs**:
- API endpoint matrix from worker-4-lld-api-validation

---

## Deliverables

Create the following files in `output/`:

### 1. main.tf
```hcl
# API Gateway REST API
resource "aws_api_gateway_rest_api" "site_builder" {
  name        = "bbws-site-builder-api-${var.environment}"
  description = "BBWS Site Builder API"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = var.tags
}

# Resources, methods, integrations for:
# - /v1 (root)
# - /v1/tenants
# - /v1/tenants/{tenant_id}
# - /v1/tenants/{tenant_id}/users
# - /v1/tenants/{tenant_id}/sites
# - /v1/tenants/{tenant_id}/generations
# - /v1/agents/*
# - /v1/partners/*
# - etc.
```

### 2. variables.tf
```hcl
variable "environment" {
  description = "Environment name (dev, sit, prod)"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "af-south-1"
}

variable "lambda_invoke_arn" {
  description = "ARN for Lambda integration"
  type        = string
}

variable "cognito_user_pool_arn" {
  description = "Cognito User Pool ARN for authorization"
  type        = string
}

variable "waf_web_acl_arn" {
  description = "WAF Web ACL ARN"
  type        = string
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
```

### 3. outputs.tf
```hcl
output "api_id" {
  description = "API Gateway REST API ID"
  value       = aws_api_gateway_rest_api.site_builder.id
}

output "api_execution_arn" {
  description = "API Gateway execution ARN"
  value       = aws_api_gateway_rest_api.site_builder.execution_arn
}

output "api_invoke_url" {
  description = "API Gateway invoke URL"
  value       = aws_api_gateway_stage.main.invoke_url
}

output "api_stage_name" {
  description = "API Gateway stage name"
  value       = aws_api_gateway_stage.main.stage_name
}
```

### 4. authorizer.tf
```hcl
# Cognito Authorizer
resource "aws_api_gateway_authorizer" "cognito" {
  name                   = "cognito-authorizer"
  rest_api_id            = aws_api_gateway_rest_api.site_builder.id
  type                   = "COGNITO_USER_POOLS"
  provider_arns          = [var.cognito_user_pool_arn]
  identity_source        = "method.request.header.Authorization"
}
```

### 5. usage_plans.tf
```hcl
# Usage Plans for rate limiting by tier
resource "aws_api_gateway_usage_plan" "free" {
  name = "free-tier-${var.environment}"

  throttle_settings {
    burst_limit = 20
    rate_limit  = 10
  }

  quota_settings {
    limit  = 50
    period = "MONTH"
  }

  api_stages {
    api_id = aws_api_gateway_rest_api.site_builder.id
    stage  = aws_api_gateway_stage.main.stage_name
  }
}

resource "aws_api_gateway_usage_plan" "standard" {
  name = "standard-tier-${var.environment}"
  # ... (50 req/sec, 500/month)
}

resource "aws_api_gateway_usage_plan" "premium" {
  name = "premium-tier-${var.environment}"
  # ... (200 req/sec, 5000/month)
}
```

### 6. cors.tf
```hcl
# CORS configuration for all endpoints
# Enable OPTIONS method with appropriate headers
```

### 7. waf.tf
```hcl
# WAF association with API Gateway
resource "aws_wafv2_web_acl_association" "api_gateway" {
  resource_arn = aws_api_gateway_stage.main.arn
  web_acl_arn  = var.waf_web_acl_arn
}
```

### 8. cloudwatch.tf
```hcl
# CloudWatch Alarms for API Gateway
resource "aws_cloudwatch_metric_alarm" "api_5xx_errors" {
  alarm_name          = "bbws-api-5xx-errors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "5XXError"
  namespace           = "AWS/ApiGateway"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "API Gateway 5XX errors exceeding threshold"

  dimensions = {
    ApiName = aws_api_gateway_rest_api.site_builder.name
    Stage   = aws_api_gateway_stage.main.stage_name
  }
}

resource "aws_cloudwatch_metric_alarm" "api_latency" {
  alarm_name          = "bbws-api-latency-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "Latency"
  namespace           = "AWS/ApiGateway"
  period              = 300
  statistic           = "Average"
  threshold           = 3000
  alarm_description   = "API Gateway latency exceeding 3 seconds"
}
```

---

## Expected Output Format

```
output/
├── main.tf           # REST API, resources, methods
├── variables.tf      # Input variables
├── outputs.tf        # Output values
├── authorizer.tf     # Cognito authorizer
├── usage_plans.tf    # Rate limiting tiers
├── cors.tf           # CORS configuration
├── waf.tf            # WAF association
├── cloudwatch.tf     # Alarms and metrics
└── README.md         # Module documentation
```

---

## Success Criteria

- [ ] REST API created with all endpoints from LLD
- [ ] Cognito authorizer configured
- [ ] Usage plans for all 4 tiers (free, standard, premium, enterprise)
- [ ] CORS enabled for frontend domains
- [ ] WAF associated with API
- [ ] CloudWatch alarms configured
- [ ] All resources tagged
- [ ] `terraform validate` passes
- [ ] `terraform plan` produces no errors

---

## Execution Steps

1. Read HLD Section 5 for API design
2. Read API LLD Section 3 for OpenAPI spec
3. Create main.tf with REST API and resources
4. Create variables.tf with all inputs
5. Create outputs.tf with all outputs
6. Configure Cognito authorizer
7. Create usage plans for all tiers
8. Configure CORS
9. Associate WAF
10. Configure CloudWatch alarms
11. Create README.md
12. Run `terraform validate`
13. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-16
