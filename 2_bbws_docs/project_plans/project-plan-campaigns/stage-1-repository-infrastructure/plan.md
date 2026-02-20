# Stage 1: Repository Setup & Infrastructure Code

**Stage ID**: stage-1-repository-infrastructure
**Project**: project-plan-campaigns
**Status**: PENDING
**Workers**: 6 (parallel execution)

---

## Stage Objective

Create the GitHub repository structure and all Terraform infrastructure modules for the Campaign Management Lambda service.

---

## Stage Workers

| Worker | Task | Status |
|--------|------|--------|
| worker-1-github-repo-setup | Create GitHub repository structure | PENDING |
| worker-2-terraform-lambda-module | Create Terraform Lambda module | PENDING |
| worker-3-terraform-dynamodb-module | Create Terraform DynamoDB module | PENDING |
| worker-4-terraform-apigateway-module | Create Terraform API Gateway module | PENDING |
| worker-5-terraform-iam-module | Create Terraform IAM module | PENDING |
| worker-6-environment-configs | Create environment .tfvars files | PENDING |

---

## Stage Inputs

- LLD Document: `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/2.1.3_LLD_Campaigns_Lambda.md`
- HLD Document: `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/HLDs/2.1.3_HLD_Campaign_Management.md`

---

## Stage Outputs

### Repository Structure
```
2_bbws_campaigns_lambda/
├── src/
│   ├── handlers/
│   ├── services/
│   ├── repositories/
│   ├── models/
│   ├── validators/
│   ├── exceptions/
│   └── utils/
├── tests/
│   ├── unit/
│   └── integration/
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── lambda.tf
│   ├── dynamodb.tf
│   ├── api_gateway.tf
│   ├── iam.tf
│   ├── cloudwatch.tf
│   └── environments/
│       ├── dev.tfvars
│       ├── sit.tfvars
│       └── prod.tfvars
├── openapi/
├── .github/
│   └── workflows/
├── requirements.txt
├── requirements-dev.txt
├── pytest.ini
├── .gitignore
└── README.md
```

### Terraform Modules
1. Lambda module - 5 functions with arm64, Python 3.12
2. DynamoDB module - Campaigns table with GSI, on-demand
3. API Gateway module - REST API with CORS
4. IAM module - Lambda execution roles and policies
5. CloudWatch module - Log groups, metrics, alarms

### Environment Configurations
- `dev.tfvars` - DEV environment (eu-west-1)
- `sit.tfvars` - SIT environment (eu-west-1)
- `prod.tfvars` - PROD environment (af-south-1)

---

## Success Criteria

- [ ] GitHub repository structure created
- [ ] All Terraform modules pass `terraform validate`
- [ ] All environment tfvars files complete
- [ ] No hardcoded credentials or environment values
- [ ] DynamoDB configured with on-demand capacity
- [ ] All 6 workers completed
- [ ] Stage summary created

---

## Key Requirements

### From LLD
- 5 Lambda functions: list, get, create, update, delete
- DynamoDB table: `campaigns`
- GSI: CampaignsByStatusIndex
- API Gateway endpoints at /v1.0/campaigns

### From CLAUDE.md
- Microservices architecture - separate Terraform per service
- No hardcoded credentials - parameterize everything
- DynamoDB on-demand capacity only
- Enable PITR for DynamoDB

---

## Dependencies

**Depends On**: None (first stage)

**Blocks**: Stage 2 (Lambda Code Development)

---

**Created**: 2026-01-15
