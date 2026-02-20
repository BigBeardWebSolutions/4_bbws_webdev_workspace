# Clarifying Questions for 2.1.8_LLD_S3_and_DynamoDB.md

**Date**: 2025-12-25
**Target LLD**: 2.1.8_LLD_S3_and_DynamoDB.md
**Purpose**: Create comprehensive LLD for S3 and DynamoDB repository infrastructure with CI/CD pipeline

---

## 1. Repository Structure

### Q1.1: Repository Organization
- Are the S3 and DynamoDB repositories separate GitHub repos, or are they part of a monorepo structure?
- Should they be separate repos for each resource type?
- Answer: single repos

### Q1.2: Naming Convention
- What should the repo naming convention be?
  - Example: `2_bbws_s3_schemas`, `2_bbws_dynamodb_schemas`?
  - Or: `2_bbws_customer_portal_infrastructure`?
- Should it follow the existing pattern from other BBWS repos?
- Answer:  `2_1_bbws_s3_schemas`, `2_1_bbws_dynamodb_schemas`

---

## 2. Resource Scope

### Q2.1: DynamoDB Tables Coverage
- Which DynamoDB tables from the HLD should this LLD cover?
  - All Customer Portal tables?
  - Specific tables only (e.g., Orders, Products, Customers)?
  - Or a generic pattern applicable to all tables?
- Answer: Tenants, Products, Campaigns
### Q2.2: S3 Buckets Coverage
- Which S3 buckets should be included?
  - Customer assets bucket?
  - Email templates bucket?
  - Static website hosting bucket?
  - All buckets from the HLD?
- Answers: 
s3://bbws-templates-{env}/receipts/receipt.html
s3://bbws-templates-{env}/receipts/order.html

### Q2.3: HTML Templates
- What HTML templates are needed?
  - Order confirmation emails (internal and customer)?
  - Receipt/Payment confirmation emails (internal and customer)?
  - Customer Site creation and notifications (customer)?
  - Invoice template
  - Receipt template
- Should templates be versioned?
- Answer: All above
---

## 3. GitHub Actions Pipeline

### Q3.1: Pipeline Stages
- Should the pipeline include:
  - ✅ Terraform plan/apply for infrastructure?
  - ✅ Schema validation (DynamoDB schemas)?
  - ✅ Template validation (HTML templates)?
  - ✅ Terraform state management?
  - ✅ Cross-environment promotion (dev → sit → prod)?
  - ✅ Rollback capability?
- Answer: Yest to all
### Q3.2: Validation Requirements
- What validations should run before deployment?
  - Terraform fmt/validate?
  - DynamoDB schema validation (GSI, LSI, attributes)?
  - S3 bucket policy validation?
  - HTML template syntax validation?
- Answer : See above

### Q3.3: State Management
- Where should Terraform state be stored?
  - S3 backend?
  - Separate state per environment?
  - Workspace-based or separate backend configs?
Answer: State per component / Use s3 sub-folders
---

## 4. Approval Gates and Promotion

### Q4.1: Approval Points
- Human approval needed at which stages?
  - Option A: After terraform plan (before dev deploy)?
  - Option B: Before each environment promotion (dev→sit, sit→prod)?
  - Option C: Both terraform plan AND environment promotion?
  - Option D: Only for sit and prod (dev auto-deploys)?
Answer: C 
### Q4.2: Promotion Strategy
- How should promotion work?
  - Manual trigger with approval?
  - Automatic promotion after successful testing in lower env?
  - Git tag-based promotion?
  - Environment-specific branches (dev, sit, prod)?

### Q4.3: Rollback Strategy
- What rollback mechanism is needed?
  - A. Terraform state rollback?
  - B. Previous version redeployment?
  - C. Blue-green deployment?
- Answer: A
---

## 5. Terraform Structure

### Q5.1: Module Organization
- Based on CLAUDE.md: "Each microservice should have its own terraform script"
- Should each table/bucket have:
  - A. Separate terraform modules?
  - B. Grouped by logical domain (e.g., orders, customers)?
  - C. Single module with multiple resources?
- Answer: A 

### Q5.2: Reusability
- Should terraform modules be:
  - A. Generic and reusable across different tables/buckets?
  - B. Specific per resource with shared variables?
  - C. Use terraform registry modules or custom?
Answer: B
### Q5.3: Environment Configuration
- How should environment-specific config be managed?
  - `.tfvars` files per environment?
  - Environment variables?
  - Parameter store / Secrets manager?
  - All three for different config types?
- Answer: file per environment
---

## 6. Integration with Existing Systems

### Q6.1: Lambda Integration
- Should this LLD reference or integrate with the existing Lambda code generation patterns from `2.1.8_LLD_Order_Lambda_Code_Gen_Spec.md`?
- Should the pipeline trigger Lambda deployments when tables are created?
Answer: No code stuff here jsut schemas and templates

### Q6.2: Schema Management
- How should DynamoDB schemas be defined?
  - A. JSON schema files?
  - B. Terraform HCL?
  - C. Separate schema repository referenced by terraform?
Answer: A

### Q6.3: Dependency Management
- If tables or buckets are dependencies for Lambdas:
  - Should this pipeline run before Lambda pipelines?
  - Should it output ARNs/names for Lambda consumption?
  - How to ensure proper ordering?
Answer: Lamdas will know about these resources by naming convention. Just create them.
---

## 7. Naming Conventions

### Q7.1: Resource Naming
- What naming convention should resources follow?
  - Tables: `{domain}` (e.g., `orders`)? Yes
  - Buckets: `bbws-{purpose}-{env}` (e.g., `bbws-templates-dev`)? Yes
  - Should account ID be included for uniqueness? No

### Q7.2: Tagging Strategy
- What tags should be applied to all resources?
  - Environment yes, Project (BBWS WP Containers), Owner(Tebogo), CostCenter(AWS)?
  - Managed-by (Terraform)? Yes
  - Backup policy tags? Yes

---

## 8. Testing and Validation

### Q8.1: Pre-Deployment Testing
- What tests should run in the pipeline?
  - Terraform plan dry-run?
  - Schema validation tests?
  - Policy validation?

### Q8.2: Post-Deployment Validation
- How to validate successful deployment?
  - Table accessibility tests?
  - Bucket policy verification?
  - Template upload verification?

---

## 9. Documentation Requirements

### Q9.1: Documentation Scope
- Should the LLD include:
  - Architecture diagrams (table relationships, S3 structure)? LLD update. Suggestions accepted
  - Runbook for common operations? Especially for changin, deploying and promotion or these resources S3 and DynamoDB. Give examples. Drop documentation in a folder in 2_bbws_docs/runbooks
  - Troubleshooting guide? make part of runbooks.
Answer: See above.

### Q9.2: Diagram Requirements
- What diagrams are needed?
  - DynamoDB table structure (GSI, LSI)?
  - S3 bucket organization?
  - CI/CD pipeline flow?
  - Environment promotion flow?
Answer: Suggest updates to LLD as part of plan.
---

## 10. Disaster Recovery

### Q10.1: Backup Strategy
- Based on CLAUDE.md: "hourly DynamoDB backups and cross-region replication"
- Should this LLD include:
  - DynamoDB PITR (Point-in-Time Recovery)?
  - Scheduled backup configuration?
  - Cross-region replication setup?
  - S3 versioning and replication?
  Anwer: Yes to all.

### Q10.2: DR Region
- Primary: af-south-1, DR: eu-west-1 (from CLAUDE.md)
- Should terraform deploy to both regions? Prod only
- Should pipeline handle multi-region deployments? No. I will create a DR specific pipeline. Do not complicate this flow with DR.

---

## Next Steps

Once these questions are answered, the project plan will include:
1. **Stage 1**: Requirements analysis and design
2. **Stage 2**: Terraform module development
3. **Stage 3**: GitHub Actions pipeline creation
4. **Stage 4**: Documentation and testing
5. **Stage 5**: Validation and approval

**Status**: Awaiting answers
**Created**: 2025-12-25
**Owner**: Agentic Project Manager
