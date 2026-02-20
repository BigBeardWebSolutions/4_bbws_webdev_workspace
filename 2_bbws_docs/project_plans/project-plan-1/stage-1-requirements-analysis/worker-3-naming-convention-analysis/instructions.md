# Worker Instructions: Naming Convention Analysis

**Worker ID**: worker-3-naming-convention-analysis
**Stage**: Stage 1 - Requirements & Analysis
**Project**: project-plan-1

---

## Task

Analyze and document all naming conventions for repositories, DynamoDB tables, S3 buckets, Terraform resources, and tags based on HLD, specification, and CLAUDE.md standards.

---

## Inputs

**Primary Inputs**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/HLDs/2.1_BBWS_Customer_Portal_Public_HLD_V1.1.md`
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/specs/2.1.8_LLD_S3_and_DynamoDB_Spec.md`
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/specs/questions.md`

**Supporting Inputs**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/CLAUDE.md`
- `~/.claude/CLAUDE.md` (global naming standards)

---

## Deliverables

Create `output.md` with comprehensive naming convention matrices:

### 1. Repository Naming Matrix

| Repository Type | Pattern | Examples | Notes |
|----------------|---------|----------|-------|
| DynamoDB Schemas | `2_1_bbws_dynamodb_schemas` | Single repo | Underscore separator |
| S3 Schemas | `2_1_bbws_s3_schemas` | Single repo | Underscore separator |
| Lambda Services | `2_1_bbws_{service}_lambda` | `2_1_bbws_product_lambda` | From HLD |

### 2. DynamoDB Table Naming Matrix

| Environment | Table | Full Name | Account | Region |
|-------------|-------|-----------|---------|--------|
| DEV | tenants | `tenants` | 536580886816 | af-south-1 |
| DEV | products | `products` | 536580886816 | af-south-1 |
| DEV | campaigns | `campaigns` | 536580886816 | af-south-1 |
| SIT | tenants | `tenants` | 815856636111 | af-south-1 |
| ... | ... | ... | ... | ... |

**Rationale**: Simple domain names, environment isolation via separate AWS accounts

### 3. S3 Bucket Naming Matrix

| Environment | Purpose | Bucket Name | Region | Replication |
|-------------|---------|-------------|--------|-------------|
| DEV | Templates | `bbws-templates-dev` | af-south-1 | No |
| SIT | Templates | `bbws-templates-sit` | af-south-1 | No |
| PROD | Templates | `bbws-templates-prod` | af-south-1 | Yes (eu-west-1) |

**Rationale**: Global S3 namespace requires unique names across environments

### 4. S3 Object Key Patterns

| Category | Pattern | Example |
|----------|---------|---------|
| Receipts | `receipts/{filename}.html` | `receipts/receipt.html` |
| Notifications | `notifications/{filename}.html` | `notifications/order_confirmation_customer.html` |
| Invoices | `invoices/{filename}.html` | `invoices/invoice.html` |

### 5. GSI Naming Matrix

| GSI Name | Table | Purpose | Pattern |
|----------|-------|---------|---------|
| EmailIndex | tenants | Find tenant by email | `{Attribute}Index` |
| TenantStatusIndex | tenants | List tenants by status | `{Entity}{Attribute}Index` |
| ProductActiveIndex | products | List active products | `{Entity}{Attribute}Index` |
| CampaignActiveIndex | campaigns | List active campaigns | `{Entity}{Attribute}Index` |
| CampaignProductIndex | campaigns | List campaigns by product | `{Entity}{ForeignKey}Index` |

### 6. Terraform Resource Naming

| Resource Type | Pattern | Example | Notes |
|---------------|---------|---------|-------|
| DynamoDB Table | `aws_dynamodb_table.{table_name}` | `aws_dynamodb_table.tenants` | Lowercase |
| S3 Bucket | `aws_s3_bucket.{purpose}_{env}` | `aws_s3_bucket.templates_dev` | Underscore separator |
| IAM Policy | `aws_iam_policy.{service}_{purpose}` | `aws_iam_policy.dynamodb_access` | Descriptive |

### 7. Terraform Module Naming

| Module | Directory | Purpose |
|--------|-----------|---------|
| DynamoDB Table | `modules/dynamodb_table/` | Reusable table module |
| GSI | `modules/gsi/` | GSI configuration |
| Backup | `modules/backup/` | Backup configuration |
| S3 Bucket | `modules/s3_bucket/` | Reusable bucket module |
| Bucket Policy | `modules/bucket_policy/` | Bucket policy configuration |
| Replication | `modules/replication/` | Cross-region replication |

### 8. Tag Naming Standards

| Tag Key | Tag Values | Required | Purpose |
|---------|------------|----------|---------|
| Environment | dev, sit, prod | Yes | Environment identification |
| Project | BBWS WP Containers | Yes | Project grouping |
| Owner | Tebogo | Yes | Ownership |
| CostCenter | AWS | Yes | Cost allocation |
| ManagedBy | Terraform | Yes | Automation indicator |
| BackupPolicy | daily, hourly | Yes (tables) | Backup frequency |
| Component | dynamodb, s3 | Yes | Component type |

### 9. GitHub Workflow Naming

| Workflow | File Name | Trigger |
|----------|-----------|---------|
| Schema Validation | `validate-schemas.yml` | Push to main, PR |
| Template Validation | `validate-templates.yml` | Push to main, PR |
| Terraform Plan | `terraform-plan.yml` | After validation |
| Deploy DEV | `terraform-apply-dev.yml` | Manual trigger |
| Deploy SIT | `terraform-apply-sit.yml` | Manual trigger |
| Deploy PROD | `terraform-apply-prod.yml` | Manual trigger |
| Rollback | `terraform-rollback.yml` | Manual trigger |

### 10. State File Naming

| State Type | Pattern | Example |
|------------|---------|---------|
| DynamoDB State | `{component}/terraform.tfstate` | `tenants/terraform.tfstate` |
| S3 State | `{component}/terraform.tfstate` | `templates/terraform.tfstate` |
| Lock Table | `terraform-state-lock-{env}` | `terraform-state-lock-dev` |

---

## Expected Output Format

```markdown
# Naming Convention Analysis Output

## 1. Repository Naming Matrix

(Table as shown above)

## 2. DynamoDB Table Naming Matrix

(Table as shown above)

...

## 10. State File Naming

(Table as shown above)

## Summary

All naming conventions follow:
- **Consistency**: Same pattern across similar resources
- **Clarity**: Names self-document purpose
- **Environment Separation**: Clear env indicators
- **AWS Standards**: Follow AWS naming best practices
- **No Hardcoding**: Parameterized for flexibility
```

---

## Success Criteria

- [ ] All 10 naming matrices completed
- [ ] Repository naming documented
- [ ] Table naming documented
- [ ] Bucket naming documented
- [ ] Object key patterns documented
- [ ] GSI naming documented
- [ ] Terraform naming documented
- [ ] Tag standards documented
- [ ] Workflow naming documented
- [ ] State file naming documented
- [ ] Consistent patterns identified

---

## Execution Steps

1. Read HLD Section 10 (Repositories)
2. Read specification Section 2 (Repository Structure)
3. Read specification Section 3 (DynamoDB Tables)
4. Read specification Section 4 (S3 Buckets)
5. Read specification Section 5 (Terraform)
6. Read CLAUDE.md for global standards
7. Extract naming patterns for each category
8. Create comprehensive matrices
9. Validate consistency across all naming conventions
10. Create output.md with all matrices
11. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2025-12-25
