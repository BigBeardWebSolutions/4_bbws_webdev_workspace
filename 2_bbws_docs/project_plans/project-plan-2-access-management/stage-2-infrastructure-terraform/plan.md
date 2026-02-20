# Stage 2: Infrastructure Terraform

**Stage ID**: stage-2-infrastructure-terraform
**Project**: project-plan-2-access-management
**Status**: PENDING
**Workers**: 6 (parallel execution)

---

## Stage Objective

Create Terraform modules for all AWS infrastructure required by Access Management services. Each module should be environment-agnostic with parameterized configurations for DEV, SIT, and PROD.

---

## Stage Workers

| Worker | Task | Resources | Status |
|--------|------|-----------|--------|
| worker-1-dynamodb-tables-module | Create DynamoDB table modules | 4 tables, GSIs | PENDING |
| worker-2-lambda-iam-roles-module | Create IAM roles and policies | 6 service roles | PENDING |
| worker-3-api-gateway-module | Create API Gateway configuration | REST API, stages | PENDING |
| worker-4-cognito-integration-module | Configure Cognito authorizer | User pool config | PENDING |
| worker-5-s3-audit-storage-module | Create S3 buckets for audit | Hot/Warm/Cold | PENDING |
| worker-6-cloudwatch-monitoring-module | Configure CloudWatch resources | Alarms, dashboards | PENDING |

---

## Stage Inputs

**From Stage 1**:
- Implementation checklists
- Data model summaries
- Integration points

**LLD References**:
- DynamoDB schemas from all LLDs
- IAM policies from LLDs
- API Gateway configurations
- S3 lifecycle policies from LLD 2.8.6

---

## Stage Outputs

### worker-1-dynamodb-tables-module
```
terraform/modules/dynamodb/
├── main.tf           # Table definitions
├── gsi.tf            # Global Secondary Indexes
├── variables.tf      # Input variables
├── outputs.tf        # Output values
└── pitr.tf           # Point-in-time recovery
```

### worker-2-lambda-iam-roles-module
```
terraform/modules/iam/
├── main.tf           # Role definitions
├── policies.tf       # Policy documents
├── variables.tf
└── outputs.tf
```

### worker-3-api-gateway-module
```
terraform/modules/api-gateway/
├── main.tf           # API definition
├── routes.tf         # Route configurations
├── integrations.tf   # Lambda integrations
├── variables.tf
└── outputs.tf
```

### worker-4-cognito-integration-module
```
terraform/modules/cognito/
├── main.tf           # Authorizer config
├── variables.tf
└── outputs.tf
```

### worker-5-s3-audit-storage-module
```
terraform/modules/s3-audit/
├── main.tf           # Bucket definitions
├── lifecycle.tf      # Hot/Warm/Cold policies
├── replication.tf    # Cross-region (PROD)
├── variables.tf
└── outputs.tf
```

### worker-6-cloudwatch-monitoring-module
```
terraform/modules/cloudwatch/
├── main.tf           # Log groups
├── alarms.tf         # Alarm definitions
├── dashboards.tf     # Dashboard JSON
├── sns.tf            # Alert topics
├── variables.tf
└── outputs.tf
```

---

## Success Criteria

- [ ] All modules pass `terraform validate`
- [ ] All modules pass `terraform plan` (no errors)
- [ ] Variables parameterized for all environments
- [ ] No hardcoded values
- [ ] Follows BBWS naming conventions
- [ ] On-demand capacity for DynamoDB
- [ ] PITR enabled
- [ ] Public access blocked for S3
- [ ] All 6 workers completed
- [ ] Stage summary created

---

## Dependencies

**Depends On**: Stage 1 (LLD Review & Analysis)

**Blocks**: Stage 3 (Lambda Services Development)

---

## Environment Configuration

| Variable | DEV | SIT | PROD |
|----------|-----|-----|------|
| region | eu-west-1 | eu-west-1 | af-south-1 |
| env_name | dev | sit | prod |
| pitr_enabled | true | true | true |
| cross_region_replication | false | false | true |
| failover_region | - | - | eu-west-1 |

---

**Created**: 2026-01-23
