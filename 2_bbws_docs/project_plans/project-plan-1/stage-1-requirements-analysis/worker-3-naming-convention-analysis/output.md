# Naming Convention Analysis Output

**Worker**: worker-3-naming-convention-analysis
**Stage**: Stage 1 - Requirements & Analysis
**Project**: project-plan-1
**Date**: 2025-12-25
**Status**: COMPLETE

---

## 1. Repository Naming Matrix

| Repository Type | Pattern | Examples | Notes |
|----------------|---------|----------|-------|
| Frontend | `2_1_bbws_web_public` | `2_1_bbws_web_public` | Single repository for React SPA |
| Lambda Services | `2_1_bbws_{service}_lambda` | `2_1_bbws_product_lambda`, `2_1_bbws_campaign_lambda`, `2_1_bbws_order_lambda` | One repo per microservice |
| DynamoDB Schemas | `2_1_bbws_dynamodb_schemas` | `2_1_bbws_dynamodb_schemas` | Single repository for all table schemas |
| S3 Schemas | `2_1_bbws_s3_schemas` | `2_1_bbws_s3_schemas` | Single repository for bucket configs and templates |
| Operations | `2_1_bbws_operations` | `2_1_bbws_operations` | Single repository for dashboards, alerts, budgets |

**Pattern Rules:**
- Prefix: `2_1_bbws_` (HLD 2.1 → underscore-separated: 2_1)
- Lambda services always end with `_lambda`
- Underscores used as word separators (not hyphens)
- No `svc` suffix in names
- Repository prefix directly maps from HLD prefix (dots → underscores)

**Rationale:**
- Consistent prefix enables easy filtering and searching
- Underscores provide compatibility across systems
- Service type suffix clarifies repository purpose
- Direct mapping from HLD to repo name enables traceability

---

## 2. DynamoDB Table Naming Matrix

| Environment | Table | Full Name | AWS Account | Region | Isolation Method |
|-------------|-------|-----------|-------------|--------|------------------|
| DEV | tenants | `tenants` | 536580886816 | af-south-1 | Separate AWS account |
| DEV | products | `products` | 536580886816 | af-south-1 | Separate AWS account |
| DEV | campaigns | `campaigns` | 536580886816 | af-south-1 | Separate AWS account |
| SIT | tenants | `tenants` | 815856636111 | af-south-1 | Separate AWS account |
| SIT | products | `products` | 815856636111 | af-south-1 | Separate AWS account |
| SIT | campaigns | `campaigns` | 815856636111 | af-south-1 | Separate AWS account |
| PROD | tenants | `tenants` | 093646564004 | af-south-1 | Separate AWS account |
| PROD | products | `products` | 093646564004 | af-south-1 | Separate AWS account |
| PROD | campaigns | `campaigns` | 093646564004 | af-south-1 | Separate AWS account |

**Pattern Rules:**
- Table names: `{domain}` (lowercase, singular or plural as semantically appropriate)
- No environment suffix in table name
- No prefix in table name
- Simple, descriptive domain names

**Rationale:**
- Environment isolation achieved via separate AWS accounts (per CLAUDE.md)
- Simple domain names improve readability
- No environment suffix needed since accounts are separate
- Enables identical code across environments (only AWS account/region changes)
- Follows DynamoDB best practices for naming

**Additional Tables (from HLD):**
- Orders: Stored with PK `TENANT#{tenantId}` SK `ORDER#{orderId}` in multi-tenant pattern
- OrderItems: Stored with PK `TENANT#{tenantId}#ORDER#{orderId}` SK `ITEM#{itemId}`
- Payments: Stored with PK `TENANT#{tenantId}#ORDER#{orderId}` SK `PAYMENT#{paymentId}`
- NewsletterSub: PK `NEWSLETTER#{email}` SK `METADATA`

---

## 3. S3 Bucket Naming Matrix

| Environment | Purpose | Bucket Name | Region | Public Access | Versioning | Replication |
|-------------|---------|-------------|--------|---------------|------------|-------------|
| DEV | Templates | `bbws-templates-dev` | af-south-1 | Blocked | Enabled | No |
| SIT | Templates | `bbws-templates-sit` | af-south-1 | Blocked | Enabled | No |
| PROD | Templates | `bbws-templates-prod` | af-south-1 | Blocked | Enabled | Yes (eu-west-1) |
| DEV | Terraform State | `bbws-terraform-state-dev` | af-south-1 | Blocked | Enabled | No |
| SIT | Terraform State | `bbws-terraform-state-sit` | af-south-1 | Blocked | Enabled | No |
| PROD | Terraform State | `bbws-terraform-state-prod` | af-south-1 | Blocked | Enabled | Yes (eu-west-1) |

**Pattern Rules:**
- Pattern: `bbws-{purpose}-{env}`
- Lowercase only
- Hyphens as word separators (S3 convention)
- Environment suffix: `dev`, `sit`, `prod`
- No account ID in name

**Rationale:**
- S3 bucket names must be globally unique across all AWS accounts
- Environment suffix ensures uniqueness
- Hyphen-separated improves readability in S3 console
- Follows AWS S3 naming best practices
- All buckets block public access (per CLAUDE.md security requirement)

---

## 4. S3 Object Key Patterns

| Category | Pattern | Example | Purpose |
|----------|---------|---------|---------|
| Receipts | `receipts/{filename}.html` | `receipts/receipt.html` | Customer payment receipts |
| Receipts (Internal) | `receipts/{filename}_internal.html` | `receipts/receipt_internal.html` | Internal payment receipts |
| Order Receipts | `receipts/{filename}.html` | `receipts/order.html` | Customer order receipts |
| Order Receipts (Internal) | `receipts/{filename}_internal.html` | `receipts/order_internal.html` | Internal order receipts |
| Notifications | `notifications/{filename}.html` | `notifications/order_confirmation_customer.html` | Customer notifications |
| Notifications (Internal) | `notifications/{filename}_internal.html` | `notifications/order_confirmation_internal.html` | Internal notifications |
| Payment Confirmations | `notifications/{filename}.html` | `notifications/payment_confirmation_customer.html` | Payment confirmations |
| Site Creation | `notifications/{filename}.html` | `notifications/site_creation_customer.html` | Site provisioning notifications |
| Invoices | `invoices/{filename}.html` | `invoices/invoice.html` | Customer invoices |
| Invoices (Internal) | `invoices/{filename}_internal.html` | `invoices/invoice_internal.html` | Internal invoices |

**Pattern Rules:**
- Top-level folder indicates template category
- Filename describes template purpose
- Internal templates use `_internal` suffix
- All templates are HTML files (`.html` extension)
- Lowercase with underscores for multi-word names

**Rationale:**
- Folder organization enables easy browsing in S3 console
- Customer/internal distinction clear via suffix
- Descriptive filenames enable self-documentation
- Consistent structure across all template types

---

## 5. GSI Naming Matrix

| GSI Name | Table | PK | SK | Purpose | Pattern |
|----------|-------|----|----|---------|---------|
| EmailIndex | tenants | email | entityType | Find tenant by email | `{Attribute}Index` |
| TenantStatusIndex | tenants | status | dateCreated | List tenants by status | `{Entity}{Attribute}Index` |
| ActiveIndex | tenants | active | dateCreated | Filter by active status (sparse) | `{Attribute}Index` |
| ProductActiveIndex | products | active | dateCreated | List active products | `{Entity}{Attribute}Index` |
| ActiveIndex | products | active | dateCreated | Filter by active status (sparse) | `{Attribute}Index` |
| CampaignActiveIndex | campaigns | active | fromDate | List active campaigns by date | `{Entity}{Attribute}Index` |
| CampaignProductIndex | campaigns | productId | fromDate | List campaigns by product | `{Entity}{ForeignKey}Index` |
| ActiveIndex | campaigns | active | dateCreated | Filter by active status (sparse) | `{Attribute}Index` |
| OrderStatusIndex | orders | status | dateCreated | List orders by status | `{Entity}{Attribute}Index` |
| OrderTenantIndex | orders | tenantId | dateCreated | List orders by tenant | `{Entity}{ForeignKey}Index` |
| PaymentOrderIndex | payments | orderId | dateCreated | List payments by order | `{Entity}{ForeignKey}Index` |

**Pattern Rules:**
- Simple attribute index: `{Attribute}Index` (e.g., `EmailIndex`)
- Entity-scoped index: `{Entity}{Attribute}Index` (e.g., `TenantStatusIndex`)
- Foreign key index: `{Entity}{ForeignKey}Index` (e.g., `CampaignProductIndex`)
- PascalCase naming convention
- Suffix always `Index`

**Rationale:**
- Clear naming indicates purpose and query pattern
- Entity prefix prevents name conflicts across tables
- Consistent `Index` suffix identifies resource type
- PascalCase aligns with AWS GSI naming conventions

---

## 6. Terraform Resource Naming

| Resource Type | Pattern | Example | Notes |
|---------------|---------|---------|-------|
| DynamoDB Table | `aws_dynamodb_table.{table_name}` | `aws_dynamodb_table.tenants` | Lowercase table name |
| DynamoDB GSI | `aws_dynamodb_table.{table_name}` (inline) | N/A | GSIs defined inline in table resource |
| S3 Bucket | `aws_s3_bucket.{purpose}_{env}` | `aws_s3_bucket.templates_dev` | Underscore separator |
| S3 Bucket Policy | `aws_s3_bucket_policy.{purpose}_{env}` | `aws_s3_bucket_policy.templates_dev` | Matches bucket name |
| S3 Bucket Versioning | `aws_s3_bucket_versioning.{purpose}_{env}` | `aws_s3_bucket_versioning.templates_dev` | Matches bucket name |
| IAM Policy | `aws_iam_policy.{service}_{purpose}` | `aws_iam_policy.lambda_dynamodb_access` | Descriptive naming |
| IAM Role | `aws_iam_role.{service}_{purpose}` | `aws_iam_role.lambda_execution` | Descriptive naming |
| CloudWatch Alarm | `aws_cloudwatch_metric_alarm.{service}_{metric}` | `aws_cloudwatch_metric_alarm.product_lambda_errors` | Descriptive naming |
| Backup Vault | `aws_backup_vault.{env}` | `aws_backup_vault.prod` | Environment-specific |
| Backup Plan | `aws_backup_plan.{resource_type}_{env}` | `aws_backup_plan.dynamodb_prod` | Resource type specific |

**Pattern Rules:**
- Lowercase with underscores as separators
- Resource name should be descriptive and unique within terraform
- Match bucket/table names where applicable
- Include environment suffix where needed for clarity

**Rationale:**
- Terraform resource identifiers use underscores by convention
- Descriptive names improve code readability
- Consistent patterns enable code reuse
- Aligns with Terraform best practices

---

## 7. Terraform Module Naming

| Module | Directory | Purpose | Pattern |
|--------|-----------|---------|---------|
| DynamoDB Table | `modules/dynamodb_table/` | Reusable table module with configurable schema | `{resource_type}/` |
| GSI | `modules/gsi/` | GSI configuration module | `{feature}/` |
| Backup | `modules/backup/` | Backup configuration for DynamoDB | `{feature}/` |
| S3 Bucket | `modules/s3_bucket/` | Reusable bucket module | `{resource_type}/` |
| Bucket Policy | `modules/bucket_policy/` | Bucket policy configuration | `{feature}/` |
| Replication | `modules/replication/` | Cross-region replication setup | `{feature}/` |

**Directory Structure Pattern:**
```
terraform/
├── dev/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── dev.tfvars
├── sit/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── sit.tfvars
├── prod/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── prod.tfvars
└── modules/
    ├── dynamodb_table/
    ├── gsi/
    ├── backup/
    ├── s3_bucket/
    ├── bucket_policy/
    └── replication/
```

**Pattern Rules:**
- Module directory names use lowercase with underscores
- Environment-specific directories: `dev/`, `sit/`, `prod/`
- Shared modules in `modules/` directory
- Each module has standard files: `main.tf`, `variables.tf`, `outputs.tf`, `README.md`

**Rationale:**
- Clear separation of environment-specific and reusable code
- Underscores in module names align with Terraform conventions
- Consistent structure enables easy navigation
- Follows Terraform module best practices

---

## 8. Tag Naming Standards

| Tag Key | Tag Values | Required | Purpose | Example |
|---------|------------|----------|---------|---------|
| Environment | `dev`, `sit`, `prod` | Yes | Environment identification | `Environment=prod` |
| Project | `BBWS WP Containers` | Yes | Project grouping | `Project=BBWS WP Containers` |
| Owner | `Tebogo` | Yes | Ownership | `Owner=Tebogo` |
| CostCenter | `AWS` | Yes | Cost allocation | `CostCenter=AWS` |
| ManagedBy | `Terraform` | Yes | Automation indicator | `ManagedBy=Terraform` |
| BackupPolicy | `daily`, `hourly` | Yes (tables only) | Backup frequency | `BackupPolicy=hourly` |
| Component | `dynamodb`, `s3`, `lambda` | Yes | Component type | `Component=dynamodb` |
| Application | `CustomerPortalPublic` | No | Application identifier | `Application=CustomerPortalPublic` |
| LLD | `2.1.8` | No | Traceability to design doc | `LLD=2.1.8` |

**Tag Pattern Rules:**
- Tag keys use PascalCase
- Tag values use lowercase or PascalCase depending on semantic meaning
- Boolean-like values: lowercase (`true`, `false`)
- Environment values: lowercase (`dev`, `sit`, `prod`)
- Proper names: PascalCase or original case
- All resources must have the 7 required tags

**Rationale:**
- Consistent tagging enables cost tracking and filtering
- Required tags ensure governance and compliance
- Automation tag (`ManagedBy=Terraform`) prevents manual changes
- Component tag enables cross-cutting queries
- Backup policy tag drives automated backup configuration

**Tag Application in Terraform:**
```hcl
tags = {
  Environment  = var.environment
  Project      = "BBWS WP Containers"
  Owner        = "Tebogo"
  CostCenter   = "AWS"
  ManagedBy    = "Terraform"
  BackupPolicy = "hourly"
  Component    = "dynamodb"
}
```

---

## 9. GitHub Workflow Naming

| Workflow | File Name | Trigger | Purpose |
|----------|-----------|---------|---------|
| Schema Validation | `validate-schemas.yml` | Push to main, PR | Validate DynamoDB JSON schemas |
| Template Validation | `validate-templates.yml` | Push to main, PR | Validate HTML templates |
| Terraform Plan | `terraform-plan.yml` | After validation | Generate terraform plans for all environments |
| Deploy DEV | `terraform-apply-dev.yml` | Manual trigger | Deploy to DEV environment |
| Deploy SIT | `terraform-apply-sit.yml` | Manual trigger | Promote to SIT environment |
| Deploy PROD | `terraform-apply-prod.yml` | Manual trigger | Promote to PROD environment |
| Rollback | `terraform-rollback.yml` | Manual trigger | Rollback infrastructure changes |
| Post-Deploy Tests | `post-deploy-tests.yml` | After apply | Validate deployment success |

**Pattern Rules:**
- File names: lowercase with hyphens
- Suffix: `.yml` (not `.yaml`)
- Descriptive verb-noun pattern (`validate-schemas`, `terraform-apply`)
- Environment suffix for deploy workflows (`-dev`, `-sit`, `-prod`)

**Workflow Naming in YAML:**
```yaml
name: Validate DynamoDB Schemas  # Display name (can use spaces and capitals)
```

**Rationale:**
- Lowercase with hyphens is GitHub Actions convention
- Descriptive names clarify workflow purpose
- Environment suffix prevents confusion between deploy jobs
- Display names (in YAML) can be more readable than file names

---

## 10. State File Naming

| State Type | Pattern | Example | Location |
|------------|---------|---------|----------|
| DynamoDB State (per table) | `{component}/terraform.tfstate` | `tenants/terraform.tfstate` | `s3://bbws-terraform-state-{env}/2_1_bbws_dynamodb_schemas/` |
| S3 State | `{component}/terraform.tfstate` | `templates/terraform.tfstate` | `s3://bbws-terraform-state-{env}/2_1_bbws_s3_schemas/` |
| Lock Table | `terraform-state-lock-{env}` | `terraform-state-lock-dev` | DynamoDB table in each environment |

**State File Organization:**
```
s3://bbws-terraform-state-dev/
├── 2_1_bbws_dynamodb_schemas/
│   ├── tenants/terraform.tfstate
│   ├── products/terraform.tfstate
│   └── campaigns/terraform.tfstate
└── 2_1_bbws_s3_schemas/
    └── templates/terraform.tfstate

s3://bbws-terraform-state-sit/
├── 2_1_bbws_dynamodb_schemas/
│   ├── tenants/terraform.tfstate
│   ├── products/terraform.tfstate
│   └── campaigns/terraform.tfstate
└── 2_1_bbws_s3_schemas/
    └── templates/terraform.tfstate

s3://bbws-terraform-state-prod/
├── 2_1_bbws_dynamodb_schemas/
│   ├── tenants/terraform.tfstate
│   ├── products/terraform.tfstate
│   └── campaigns/terraform.tfstate
└── 2_1_bbws_s3_schemas/
    └── templates/terraform.tfstate
```

**Backend Configuration Example:**
```hcl
terraform {
  backend "s3" {
    bucket         = "bbws-terraform-state-dev"
    key            = "2_1_bbws_dynamodb_schemas/tenants/terraform.tfstate"
    region         = "af-south-1"
    dynamodb_table = "terraform-state-lock-dev"
    encrypt        = true
  }
}
```

**Pattern Rules:**
- State bucket: `bbws-terraform-state-{env}`
- State key: `{repository}/{component}/terraform.tfstate`
- Lock table: `terraform-state-lock-{env}`
- Separate state per component for isolation
- All state encrypted at rest

**Rationale:**
- Separate state files per component reduce blast radius
- Repository prefix in key prevents conflicts
- Component-level state enables independent deployments
- Environment-specific buckets align with AWS account isolation
- Lock table prevents concurrent modifications
- Encryption ensures state security (may contain sensitive data)

---

## Summary

All naming conventions follow consistent patterns across the system:

### Consistency Principles
- **Hierarchical Traceability**: Repository names map directly from HLD (2.1 → 2_1)
- **Environment Isolation**: Via separate AWS accounts for tables, via suffix for global resources (S3)
- **Separation Character**: Underscores for repos/terraform, hyphens for S3 buckets
- **Case Convention**: Lowercase for infrastructure, PascalCase for tags/GSIs
- **Descriptive Naming**: Self-documenting names that clarify purpose

### Clarity and Self-Documentation
- Table names are simple domain names (`tenants`, `products`, `campaigns`)
- Repository names include service type suffix (`_lambda`, `_schemas`)
- S3 keys use folder organization by template category
- GSI names describe query pattern and purpose
- Workflow files use verb-noun descriptive pattern

### Environment Separation Strategy
- **DynamoDB Tables**: Same name across environments, isolated by AWS account
- **S3 Buckets**: Environment suffix in name (global namespace requirement)
- **Terraform State**: Separate buckets and state files per environment
- **Tags**: Environment tag on all resources for filtering

### AWS Standards Compliance
- S3 bucket naming follows AWS guidelines (lowercase, hyphens)
- DynamoDB table naming follows best practices (simple, descriptive)
- Tagging follows AWS recommended standards
- IAM resource naming uses descriptive patterns
- Terraform follows HashiCorp module conventions

### No Hardcoding Philosophy
- All environment-specific values parameterized
- Terraform uses variables and `.tfvars` files
- Lambda code references resources by naming convention
- State management uses consistent patterns
- Enables automated deployment to any environment

### Cost and Governance
- Required tags enable cost tracking by Environment, Project, Owner, CostCenter
- Component tags enable filtering by resource type
- ManagedBy tag prevents manual changes to Terraform-managed resources
- BackupPolicy tag drives automated backup configuration

---

**Document Status**: COMPLETE
**Validation**: All 10 naming matrices documented with patterns, examples, and rationale
**Consistency Check**: All naming conventions align with HLD, specifications, and CLAUDE.md standards
