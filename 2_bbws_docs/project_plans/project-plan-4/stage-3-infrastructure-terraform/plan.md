# Stage 3: Infrastructure (Terraform)

**Stage ID**: stage-3-infrastructure-terraform
**Project**: project-plan-4 (Marketing Lambda Implementation)
**Status**: PENDING
**Workers**: 4 (parallel execution)

---

## Stage Objective

Create Terraform infrastructure-as-code for the Marketing Lambda, following microservices architecture with separate modules for Lambda and API Gateway, supporting 3 environments (DEV, SIT, PROD).

---

## Stage Workers

| Worker | Task | Status |
|--------|------|--------|
| worker-1-lambda-terraform-module | Create Lambda Terraform module (separate) | PENDING |
| worker-2-apigateway-terraform-module | Create API Gateway Terraform module (separate) | PENDING |
| worker-3-environment-configs | Create environment configs (DEV, SIT, PROD) | PENDING |
| worker-4-validation-scripts | Create Terraform validation scripts | PENDING |

---

## Stage Inputs

- Stage 2 summary.md
- Lambda code from Stage 2
- LLD specifications (section 1.2: Lambda specifications)
- Environment configurations from worker-1-4

---

## Stage Outputs

- **Lambda Terraform Module**:
  - `terraform/modules/lambda/main.tf`
  - `terraform/modules/lambda/variables.tf`
  - `terraform/modules/lambda/outputs.tf`
- **API Gateway Terraform Module**:
  - `terraform/modules/apigateway/main.tf`
  - `terraform/modules/apigateway/variables.tf`
  - `terraform/modules/apigateway/outputs.tf`
- **Environment Configurations**:
  - `terraform/environments/dev/backend.tf`
  - `terraform/environments/dev/main.tf`
  - `terraform/environments/dev/terraform.tfvars`
  - `terraform/environments/sit/` (same structure)
  - `terraform/environments/prod/` (same structure)
- **Validation Scripts**:
  - `terraform/scripts/validate.sh`
  - `scripts/validate_deployment.sh`
- Stage 3 summary.md

---

## Success Criteria

- [ ] Lambda module is separate from API Gateway module
- [ ] All environment credentials parameterized (no hardcoding)
- [ ] S3 backend configured with DynamoDB locking
- [ ] Separate state file per environment
- [ ] All required tags present (Environment, Project, Component, CostCenter, ManagedBy)
- [ ] IAM roles follow least privilege
- [ ] Environment variables parameterized (DYNAMODB_TABLE_NAME, AWS_REGION, LOG_LEVEL)
- [ ] Terraform fmt/validate passes
- [ ] All 4 workers completed
- [ ] Stage summary created
- [ ] Gate 3 approval obtained

---

## Dependencies

**Depends On**: Stage 2 (Lambda Implementation)

**Blocks**: Stage 4 (CI/CD Pipeline)

---

## Environment Configuration

| Environment | AWS Account | Region | DynamoDB Table | S3 State Bucket |
|-------------|-------------|--------|----------------|-----------------|
| **DEV** | 536580886816 | eu-west-1 | bbws-cpp-dev | bbws-terraform-state-dev |
| **SIT** | 815856636111 | eu-west-1 | bbws-cpp-sit | bbws-terraform-state-sit |
| **PROD** | 093646564004 | af-south-1 | bbws-cpp-prod | bbws-terraform-state-prod |

---

## Technical Standards

### Terraform Modules
- **Separate Modules**: One module per AWS service
- **Parameterization**: All values via variables
- **Outputs**: Expose all necessary attributes
- **Documentation**: Comments for complex logic

### State Management
- **Backend**: S3 with DynamoDB locking
- **Separate State**: One state file per environment
- **Encryption**: S3 server-side encryption enabled
- **Versioning**: S3 versioning enabled

### Tagging
All resources must have these tags:
- Environment: dev/sit/prod
- Project: BBWS
- Component: MarketingLambda
- CostCenter: BBWS-CPP
- ManagedBy: Terraform

---

**Created**: 2025-12-30
