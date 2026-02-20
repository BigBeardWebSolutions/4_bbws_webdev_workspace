# Stage 1: Repository Setup & Infrastructure Foundation

**Stage ID**: stage-1-repository-setup
**Project**: project-plan-2
**Status**: PENDING
**Workers**: 8 (Worker 1-1 executes first, then 1-2 through 1-8 in parallel)
**Duration**: 2 days

---

## Stage Objective

Create all 8 repository structures and deploy the infrastructure repository to DEV environment. This stage establishes the foundation for all Lambda implementations.

**Critical Path**: Worker 1-1 (Infrastructure) MUST complete and deploy BEFORE any Lambda repos can be functional.

---

## Stage Workers

| Worker | Task | Agent | Priority | Status |
|--------|------|-------|----------|--------|
| worker-1-1-infrastructure-repo | Create & deploy infrastructure repo | DevOps Engineer | CRITICAL | PENDING |
| worker-1-2-list-products-repo | Create list products repo structure | DevOps Engineer | HIGH | PENDING |
| worker-1-3-get-product-repo | Create get product repo structure | DevOps Engineer | HIGH | PENDING |
| worker-1-4-create-product-repo | Create create product repo structure | DevOps Engineer | HIGH | PENDING |
| worker-1-5-update-product-repo | Create update product repo structure | DevOps Engineer | HIGH | PENDING |
| worker-1-6-delete-product-repo | Create delete product repo structure | DevOps Engineer | HIGH | PENDING |
| worker-1-7-product-creator-repo | Create product creator repo structure | DevOps Engineer | HIGH | PENDING |
| worker-1-8-audit-logger-repo | Create audit logger repo structure | DevOps Engineer | HIGH | PENDING |

---

## Execution Order

**Phase 1** (Sequential - MUST complete first):
1. Worker 1-1: Create infrastructure repo → Deploy to DEV → Verify outputs

**Phase 2** (Parallel - After Worker 1-1 completes):
2. Workers 1-2 through 1-8: Create all Lambda repo structures in parallel

**Rationale**: All Lambda repos import infrastructure outputs via `terraform_remote_state`, so infrastructure MUST exist first.

---

## Stage Inputs

- Product Lambda LLD v2.0 (2.1.4_LLD_Product_Lambda.md)
- Microservices Plan (product_lambda_microservices_plan.md)
- Reference Workflow Pattern (`2_1_bbws_dynamodb_schemas/.github/workflows/`)
- User Answers (15 questions answered)

---

## Stage Outputs

### Worker 1-1 Outputs (Infrastructure Repository)

**Repository**: `/Users/tebogotseka/Documents/agentic_work/2_1_bbws_product_infrastructure/`

**Directory Structure**:
```
2_1_bbws_product_infrastructure/
├── terraform/
│   ├── api_gateway.tf        # REST API: bbws-product-api-{env}
│   ├── dynamodb.tf            # Table: bbws-products-{env}
│   ├── sqs.tf                 # Queue: bbws-product-change-{env} + DLQ
│   ├── s3.tf                  # Bucket: bbws-product-audit-logs-{env}
│   ├── sns.tf                 # Topic: bbws-product-alerts-{env}
│   ├── iam.tf                 # Base Lambda execution roles
│   ├── variables.tf
│   ├── outputs.tf             # ⚠️ CRITICAL: Exports for Lambda repos
│   ├── backend.tf             # S3 backend: bbws-terraform-state-dev
│   └── environments/
│       ├── dev.tfvars         # eu-west-1, Account: 536580886816
│       ├── sit.tfvars         # eu-west-1, Account: 815856636111
│       └── prod.tfvars        # af-south-1, Account: 093646564004
├── .github/workflows/
│   ├── deploy-dev.yml         # Manual dispatch, OIDC auth
│   ├── deploy-sit.yml         # Manual dispatch + approval gate
│   └── deploy-prod.yml        # Manual dispatch + confirmation
├── scripts/
│   └── validate_infrastructure.py
├── README.md
├── .gitignore
└── CLAUDE.md                  # Project-specific instructions
```

**AWS Resources Created (DEV)**:
- ✅ API Gateway REST API: `bbws-product-api-dev`
- ✅ DynamoDB Table: `bbws-products-dev` (ON_DEMAND, PITR enabled)
  - PK: `PK` (String)
  - SK: `SK` (String)
  - GSI1: `ProductsByPriceIndex` (GSI1_PK, GSI1_SK)
  - GSI2: `ProductsByNameIndex` (GSI2_PK) - For search without OpenSearch
- ✅ SQS Queue: `bbws-product-change-dev` (4-day retention)
- ✅ SQS DLQ: `bbws-product-change-dlq-dev` (max receive count: 3)
- ✅ S3 Bucket: `bbws-product-audit-logs-dev` (Glacier after 1 year)
- ✅ SNS Topic: `bbws-product-alerts-dev`
- ✅ IAM Roles: Base Lambda execution roles

**Critical Terraform Outputs** (Required by Lambda repos):
```hcl
output "api_gateway_id" {
  value = aws_api_gateway_rest_api.product_api.id
}
output "api_gateway_execution_arn" {
  value = aws_api_gateway_rest_api.product_api.execution_arn
}
output "api_gateway_root_resource_id" {
  value = aws_api_gateway_rest_api.product_api.root_resource_id
}
output "dynamodb_table_name" {
  value = aws_dynamodb_table.products.name
}
output "dynamodb_table_arn" {
  value = aws_dynamodb_table.products.arn
}
output "sqs_queue_url" {
  value = aws_sqs_queue.product_change.url
}
output "sqs_queue_arn" {
  value = aws_sqs_queue.product_change.arn
}
output "s3_audit_bucket_name" {
  value = aws_s3_bucket.audit_logs.bucket
}
output "sns_topic_arn" {
  value = aws_sns_topic.alerts.arn
}
```

### Workers 1-2 through 1-8 Outputs (Lambda Repositories)

**Common Directory Structure** (all 7 Lambda repos):
```
2_1_bbws_<lambda_name>/
├── src/
│   ├── handler.py              # Lambda entry point
│   ├── models/
│   │   ├── product.py          # Pydantic Product model
│   │   └── events.py           # SQS event schemas
│   ├── repositories/           # Only for DB-accessing Lambdas
│   │   └── product_repository.py
│   ├── services/
│   │   └── product_service.py
│   └── utils/
│       ├── response_builder.py # API response formatting
│       └── logger.py           # CloudWatch logging
├── tests/
│   ├── unit/
│   │   ├── test_handler.py
│   │   ├── test_service.py
│   │   └── test_repository.py  # If applicable
│   ├── integration/
│   │   └── test_api_integration.py
│   └── conftest.py             # Pytest fixtures
├── terraform/
│   ├── main.tf
│   ├── lambda.tf               # Lambda function definition
│   ├── api_gateway_integration.tf  # For API Lambdas only
│   ├── sqs_event_source.tf    # For event-driven Lambdas only
│   ├── iam.tf                  # Lambda-specific IAM
│   ├── cloudwatch.tf           # Logs & alarms
│   ├── variables.tf
│   ├── outputs.tf
│   ├── data.tf                 # ⚠️ Import infrastructure outputs
│   ├── backend.tf
│   └── environments/
│       ├── dev.tfvars
│       ├── sit.tfvars
│       └── prod.tfvars
├── .github/workflows/          # Created in Stage 3
│   ├── deploy-dev.yml
│   ├── deploy-sit.yml
│   └── deploy-prod.yml
├── requirements.txt            # boto3, pydantic
├── requirements-dev.txt        # pytest, moto, black
├── pytest.ini
├── .gitignore
├── README.md
└── CLAUDE.md
```

**Critical**: All Lambda repos must have `terraform/data.tf`:
```hcl
data "terraform_remote_state" "infrastructure" {
  backend = "s3"
  config = {
    bucket = "bbws-terraform-state-${var.environment}"
    key    = "2_1_bbws_product_infrastructure/terraform.tfstate"
    region = var.aws_region
  }
}

locals {
  api_gateway_id       = data.terraform_remote_state.infrastructure.outputs.api_gateway_id
  dynamodb_table_name  = data.terraform_remote_state.infrastructure.outputs.dynamodb_table_name
  sqs_queue_url        = data.terraform_remote_state.infrastructure.outputs.sqs_queue_url
  s3_audit_bucket      = data.terraform_remote_state.infrastructure.outputs.s3_audit_bucket_name
}
```

---

## Success Criteria

### Infrastructure Repository (Worker 1-1)
- [x] Repository created at correct location
- [x] Git initialized and first commit made
- [x] Terraform files created (api_gateway.tf, dynamodb.tf, sqs.tf, s3.tf, sns.tf, iam.tf)
- [x] Environment-specific tfvars created (dev, sit, prod)
- [x] Backend configured (S3 state bucket, DynamoDB locking)
- [x] GitHub Actions workflows created (deploy-dev.yml, deploy-sit.yml, deploy-prod.yml)
- [x] OIDC authentication configured
- [x] **DEPLOYED TO DEV**: Infrastructure deployed and validated
- [x] **OUTPUTS VERIFIED**: All Terraform outputs available
- [x] DynamoDB table created and accessible
- [x] API Gateway created
- [x] SQS queues created (main + DLQ)
- [x] S3 bucket created with lifecycle policy
- [x] SNS topic created
- [x] CloudWatch alarms configured
- [x] README.md with deployment instructions
- [x] CLAUDE.md with project-specific instructions

### Lambda Repositories (Workers 1-2 through 1-8)
- [x] All 7 repositories created at correct locations
- [x] Git initialized for each repo
- [x] Directory structure matches pattern
- [x] `terraform/data.tf` imports infrastructure outputs
- [x] Backend configured (S3 state, separate key per repo)
- [x] Environment tfvars created (dev, sit, prod)
- [x] requirements.txt created (boto3, pydantic)
- [x] requirements-dev.txt created (pytest, moto, black)
- [x] pytest.ini configured
- [x] README.md with setup instructions
- [x] CLAUDE.md with project-specific instructions
- [x] .gitignore created (Python standard + .env)

**Note**: Code implementation happens in Stage 2. Stage 1 only creates structure.

---

## Dependencies

**Depends On**: None (first stage)

**Blocks**:
- Stage 2 (Lambda Implementation) - Requires repo structures
- Stage 3 (CI/CD Pipeline) - Requires repos and infrastructure outputs

**Critical Dependency**: All Lambda repos depend on infrastructure repo being deployed first (for Terraform outputs)

---

## Validation Steps

**After Worker 1-1 Completes**:
1. Verify infrastructure repo exists at correct path
2. Run `terraform init` in infrastructure repo
3. Run `terraform plan -var-file=environments/dev.tfvars`
4. Run `terraform apply -var-file=environments/dev.tfvars`
5. Verify all AWS resources created:
   ```bash
   # DynamoDB table
   aws dynamodb describe-table --table-name bbws-products-dev --region eu-west-1

   # API Gateway
   aws apigateway get-rest-apis --region eu-west-1 | grep bbws-product-api-dev

   # SQS queues
   aws sqs list-queues --region eu-west-1 | grep bbws-product-change

   # S3 bucket
   aws s3 ls | grep bbws-product-audit-logs-dev

   # SNS topic
   aws sns list-topics --region eu-west-1 | grep bbws-product-alerts
   ```
6. Verify Terraform outputs:
   ```bash
   cd terraform && terraform output
   ```
7. Run validation script:
   ```bash
   python scripts/validate_infrastructure.py
   ```

**After Workers 1-2 through 1-8 Complete**:
1. Verify all 7 Lambda repos created
2. Verify directory structures match pattern
3. Verify Git initialized (`.git/` folder exists)
4. Verify `terraform/data.tf` exists in all repos
5. Verify all repos reference infrastructure state correctly
6. Run smoke test:
   ```bash
   for repo in 2_1_bbws_{list_products,get_product,create_product,update_product,delete_product,product_creator,audit_logger}; do
     echo "Checking $repo..."
     ls -la /Users/tebogotseka/Documents/agentic_work/$repo/
     cat /Users/tebogotseka/Documents/agentic_work/$repo/terraform/data.tf | grep terraform_remote_state
   done
   ```

---

## Stage Summary

**Upon Completion**:
- 8 repositories created and initialized
- 1 infrastructure repository deployed to DEV
- All AWS resources created and validated
- All Terraform outputs available for Lambda repos
- 7 Lambda repository structures ready for implementation
- GitHub Actions workflows created (infrastructure repo)
- Foundation ready for Stage 2 (Lambda Implementation)

---

## Next Stage

**Stage 2**: Lambda Function Implementation
- Implement 7 Lambda functions (Python 3.12)
- TDD approach: Write tests first
- 80%+ code coverage required
- All Lambdas reference infrastructure outputs

**Gate 1 Approval Required Before Proceeding to Stage 2**

---

**Created**: 2025-12-29
**Status**: PENDING (awaiting Gate 0 approval)
