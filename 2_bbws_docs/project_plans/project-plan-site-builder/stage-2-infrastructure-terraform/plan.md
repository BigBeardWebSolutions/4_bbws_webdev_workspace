# Stage 2: Infrastructure (Terraform)

**Stage ID**: stage-2-infrastructure-terraform
**Project**: project-plan-site-builder
**Status**: PENDING
**Workers**: 8 (parallel execution)

---

## Stage Objective

Create all Terraform modules for AWS infrastructure in af-south-1 (data residency), eu-west-1 (agent processing), and global resources. Ensure modules are parameterized for dev/sit/prod environments.

---

## Stage Workers

| Worker | Task | Region | Status |
|--------|------|--------|--------|
| worker-1-af-south-api-gateway | API Gateway + WAF | af-south-1 | PENDING |
| worker-2-af-south-dynamodb | DynamoDB tables | af-south-1 | PENDING |
| worker-3-af-south-s3 | S3 buckets | af-south-1 | PENDING |
| worker-4-af-south-cognito | Cognito User Pool | af-south-1 | PENDING |
| worker-5-af-south-lambda-scaffold | Lambda scaffolding | af-south-1 | PENDING |
| worker-6-eu-west-agentcore-config | AgentCore configuration | eu-west-1 | PENDING |
| worker-7-cross-region-eventbridge | EventBridge rules | Both | PENDING |
| worker-8-global-route53-waf | Global resources | Global | PENDING |

---

## Stage Inputs

| Input | Source |
|-------|--------|
| HLD v3.1 Architecture | Stage 1 output |
| Component List | HLD Section 6 |
| DynamoDB Schema | API LLD Section 6 |
| S3 Structure | API LLD Section 7 |
| Environment Variables | HLD Section 9 |

---

## Stage Outputs

| Output | Description | Location |
|--------|-------------|----------|
| `modules/af-south-1/api-gateway/` | API Gateway Terraform | bbws-site-builder-infra |
| `modules/af-south-1/dynamodb/` | DynamoDB Terraform | bbws-site-builder-infra |
| `modules/af-south-1/s3/` | S3 Terraform | bbws-site-builder-infra |
| `modules/af-south-1/cognito/` | Cognito Terraform | bbws-site-builder-infra |
| `modules/af-south-1/lambda/` | Lambda scaffolding | bbws-site-builder-infra |
| `modules/eu-west-1/agentcore/` | AgentCore config | bbws-site-builder-infra |
| `modules/eu-west-1/eventbridge/` | EventBridge rules | bbws-site-builder-infra |
| `modules/global/` | Route 53, WAF, IAM | bbws-site-builder-infra |
| `environments/dev/` | DEV variables | bbws-site-builder-infra |
| `environments/sit/` | SIT variables | bbws-site-builder-infra |
| `environments/prod/` | PROD variables | bbws-site-builder-infra |

---

## Success Criteria

- [ ] All modules pass `terraform validate`
- [ ] All modules pass `terraform plan` with no errors
- [ ] No hardcoded credentials or secrets
- [ ] All resources tagged with project, environment, owner
- [ ] DynamoDB tables use on-demand capacity mode
- [ ] S3 buckets have public access blocked
- [ ] PITR enabled for all DynamoDB tables
- [ ] Environment variables parameterized for dev/sit/prod
- [ ] CloudWatch alarms configured for key metrics
- [ ] Dead letter queues configured for all async processing
- [ ] All 8 workers completed
- [ ] Stage summary created

---

## Architecture Constraints

| Constraint | Implementation |
|------------|----------------|
| DynamoDB Capacity | On-demand (pay-per-request) |
| S3 Public Access | Blocked on all buckets |
| PITR | Enabled for all DynamoDB tables |
| Encryption | SSE-S3 for S3, AWS-owned keys for DynamoDB |
| Cross-region | EventBridge for af-south-1 <-> eu-west-1 |
| Cognito | AWS SDK only (no Amplify) |
| Tagging | project, environment, owner, cost-center |

---

## Dependencies

**Depends On**: Stage 1 (Requirements Validation)

**Blocks**:
- Stage 3 (Backend Lambda Development)
- Stage 4 (AgentCore Agent Development)

---

## Approval Gate

**Gate 2: Infrastructure Review**

| Approver | Area | Status |
|----------|------|--------|
| DevOps Lead | Terraform quality | PENDING |
| Security | Security controls | PENDING |
| FinOps | Cost estimation | PENDING |

**Gate Criteria**:
- All modules pass validation
- Security controls in place
- Cost estimate within budget
- DEV environment deployable

---

**Created**: 2026-01-16
