# Stage 7: Infrastructure (Terraform)

**Parent Plan**: [BBWS SDLC Main Plan](./main-plan.md)
**Stage**: 7 of 10
**Status**: ⏳ PENDING
**Last Updated**: 2026-01-01

---

## Objective

Create Infrastructure as Code (IaC) using Terraform to provision Lambda functions, API Gateway, DynamoDB tables, IAM roles, and CloudWatch resources.

---

## Agent & Skill Assignment

| Role | Agent | Skill |
|------|-------|-------|
| **Primary** | DevOps_Engineer_Agent | `github_oidc_cicd.skill.md` |
| **Support** | - | `aws_region_specification.skill.md` |
| **Support** | - | `dns_environment_naming.skill.md` |

**Agent Path**: `agentic_architect/DevOps_Engineer_Agent.md`

---

## Workers

| # | Worker | Task | Status | Output |
|---|--------|------|--------|--------|
| 1 | worker-1-terraform-structure | Create Terraform module structure | ⏳ PENDING | `terraform/` |
| 2 | worker-2-lambda-resources | Define Lambda and API Gateway resources | ⏳ PENDING | `terraform/*.tf` |
| 3 | worker-3-environment-configs | Create environment-specific configurations | ⏳ PENDING | `terraform/environments/` |
| 4 | worker-4-terraform-validation | Validate and test Terraform | ⏳ PENDING | Validation report |

---

## Worker Instructions

### Worker 1: Terraform Structure

**Objective**: Create Terraform module structure following BBWS patterns

**Inputs**:
- LLD document (infrastructure section)
- Existing Terraform modules (reference)

**Deliverables**:
```
terraform/
├── main.tf                 # Provider and backend
├── variables.tf            # Input variables
├── outputs.tf              # Output values
├── backend.tf              # S3 backend config
├── environments/
│   ├── dev.tfvars
│   ├── sit.tfvars
│   └── prod.tfvars
└── README.md
```

**Backend Configuration Pattern**:
```hcl
terraform {
  backend "s3" {
    # Configured via CLI flags
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}
```

**Quality Criteria**:
- [ ] Standard Terraform structure
- [ ] Backend configured for state management
- [ ] Variables properly typed
- [ ] Default tags applied

---

### Worker 2: Lambda & API Gateway Resources

**Objective**: Define all AWS resources for the Lambda service

**Inputs**:
- LLD document
- Handler specifications from Stage 5

**Deliverables**:
```
terraform/
├── lambda.tf              # Lambda functions
├── api_gateway.tf         # REST API definition
├── iam.tf                 # IAM roles and policies
├── cloudwatch.tf          # Log groups and alarms
└── dynamodb.tf            # Table reference (data source)
```

**Lambda Resource Pattern**:
```hcl
resource "aws_lambda_function" "create_product" {
  function_name = "${var.project_prefix}-create-product-${var.environment}"
  handler       = "src.handlers.create_product.handler"
  runtime       = "python3.12"
  memory_size   = var.lambda_memory
  timeout       = var.lambda_timeout

  environment {
    variables = {
      DYNAMODB_TABLE = data.aws_dynamodb_table.products.name
      ENVIRONMENT    = var.environment
      LOG_LEVEL      = var.log_level
    }
  }

  tags = {
    Component = "create-product-handler"
  }
}
```

**API Gateway Pattern**:
```hcl
resource "aws_api_gateway_rest_api" "api" {
  name = "${var.project_prefix}-api-${var.environment}"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "products" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "products"
}
```

**Quality Criteria**:
- [ ] All Lambda handlers defined
- [ ] API Gateway routes complete
- [ ] IAM least privilege
- [ ] CloudWatch log groups created

---

### Worker 3: Environment Configurations

**Objective**: Create environment-specific variable files

**Skill Reference**: Apply `dns_environment_naming.skill.md`

**Deliverables**:
```
terraform/environments/
├── dev.tfvars
├── sit.tfvars
└── prod.tfvars
```

**DEV Configuration**:
```hcl
# dev.tfvars
environment     = "dev"
aws_region      = "eu-west-1"
aws_account_id  = "536580886816"
custom_domain   = "api.dev.kimmyai.io"
log_level       = "DEBUG"
log_retention   = 7
lambda_memory   = 256
lambda_timeout  = 30
```

**SIT Configuration**:
```hcl
# sit.tfvars
environment     = "sit"
aws_region      = "eu-west-1"
aws_account_id  = "815856636111"
custom_domain   = "api.sit.kimmyai.io"
log_level       = "INFO"
log_retention   = 30
```

**PROD Configuration**:
```hcl
# prod.tfvars
environment     = "prod"
aws_region      = "af-south-1"
aws_account_id  = "093646564004"
custom_domain   = "api.kimmyai.io"
log_level       = "INFO"
log_retention   = 90
```

**Quality Criteria**:
- [ ] All environments configured
- [ ] No hardcoded credentials
- [ ] Region-specific settings correct
- [ ] Naming conventions followed

---

### Worker 4: Terraform Validation

**Objective**: Validate Terraform configuration

**Validation Steps**:
```bash
# Initialize (without backend)
terraform init -backend=false

# Validate syntax
terraform validate

# Format check
terraform fmt -check

# Plan (dry run)
terraform plan -var-file=environments/dev.tfvars -out=tfplan
```

**Quality Criteria**:
- [ ] `terraform validate` passes
- [ ] `terraform fmt` clean
- [ ] `terraform plan` succeeds
- [ ] No security warnings

---

## Stage Outputs

| Output | Description | Location |
|--------|-------------|----------|
| Terraform modules | IaC definition | `{repo}/terraform/` |
| Environment configs | Per-env settings | `{repo}/terraform/environments/` |
| Validation report | Plan output | Logged |

---

## Success Criteria

- [ ] All 4 workers completed
- [ ] Terraform validates successfully
- [ ] All environments configured
- [ ] No hardcoded secrets
- [ ] Ready for CI/CD integration

---

## Dependencies

**Depends On**: Stage 6 (API Proxy)
**Blocks**: Stage 8 (CI/CD Pipeline)

---

## Estimated Duration

| Activity | Agentic | Manual |
|----------|---------|--------|
| Structure | 10 min | 30 min |
| Resources | 25 min | 2 hours |
| Env configs | 10 min | 30 min |
| Validation | 10 min | 30 min |
| **Total** | **55 min** | **3.5 hours** |

---

**Navigation**: [← Stage 6](./stage-6-api-proxy.md) | [Main Plan](./main-plan.md) | [Stage 8: CI/CD →](./stage-8-cicd-pipeline.md)
