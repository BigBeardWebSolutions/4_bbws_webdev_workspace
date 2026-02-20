# 2.1.8 Low-Level Design: S3 and DynamoDB Infrastructure

**Document ID**: 2.1.8_LLD_S3_and_DynamoDB
**Version**: 1.0.0
**Date**: 2025-12-25
**Status**: Draft
**Author**: Agentic LLD Architect
**Parent HLD**: 2.1_BBWS_Customer_Portal_Public_HLD_V1.1.md
**Related LLDs**: 2.1.8_LLD_Order_Lambda_Code_Gen_Spec.md

---

## Table of Contents

1. [Document Information](#1-document-information)
2. [Revision History](#2-revision-history)
3. [Executive Summary](#3-executive-summary)
4. [DynamoDB Table Design](#4-dynamodb-table-design)
5. [S3 Bucket Design](#5-s3-bucket-design)
6. [Terraform Module Design](#6-terraform-module-design)
7. [CI/CD Pipeline Design](#7-cicd-pipeline-design)
8. [Appendices](#8-appendices)

---

## 1. Document Information

### 1.1 Document Metadata

| Attribute | Value |
|-----------|-------|
| **Document Title** | 2.1.8 Low-Level Design: S3 and DynamoDB Infrastructure |
| **Document ID** | 2.1.8_LLD_S3_and_DynamoDB |
| **Version** | 1.0.0 |
| **Date** | 2025-12-25 |
| **Status** | Draft |
| **Author** | Agentic LLD Architect |
| **Project** | BBWS Customer Portal (Public) |
| **Phase** | Phase 0 (First to Market) |

### 1.2 Referenced Documents

| Document | Location | Purpose |
|----------|----------|---------|
| **Parent HLD** | `2.1_BBWS_Customer_Portal_Public_HLD_V1.1.md` | Parent architecture document defining system requirements |
| **Related LLD** | `2.1.8_LLD_Order_Lambda_Code_Gen_Spec.md` | Order Lambda code generation specification |
| **Specification** | `2.1.8_LLD_S3_and_DynamoDB_Spec.md` | Detailed specification for this LLD |
| **Stage 1 Analysis** | `stage-1-requirements-analysis/worker-1-hld-analysis/output.md` | Comprehensive HLD analysis |
| **Requirements Validation** | `stage-1-requirements-analysis/worker-2-requirements-validation/output.md` | Requirements validation and quality assurance |
| **Naming Conventions** | `stage-1-requirements-analysis/worker-3-naming-convention-analysis/output.md` | Naming standards and patterns |
| **Environment Configs** | `stage-1-requirements-analysis/worker-4-environment-configuration-analysis/output.md` | Environment-specific configurations |

### 1.3 Document Scope

#### 1.3.1 In Scope

This LLD document covers the following components:

1. **GitHub Repositories**
   - `2_1_bbws_dynamodb_schemas` - DynamoDB table schemas and Terraform modules
   - `2_1_bbws_s3_schemas` - S3 bucket configurations and HTML templates

2. **DynamoDB Tables** (3 tables)
   - Tenants table with 3 GSIs
   - Products table with 2 GSIs
   - Campaigns table with 3 GSIs

3. **S3 Buckets**
   - Templates bucket (`bbws-templates-{env}`)
   - 12 HTML email templates (customer and internal versions)

4. **Terraform Infrastructure**
   - Modular Terraform architecture
   - Separate modules for DynamoDB, S3, GSI, backup, and replication
   - Environment-specific configurations (DEV, SIT, PROD)

5. **CI/CD Pipeline**
   - GitHub Actions workflows with validation stages
   - Human approval gates (after plan, before DEV, before SIT, before PROD)
   - Automated testing and deployment
   - Rollback capabilities

6. **Disaster Recovery**
   - Point-in-Time Recovery (PITR) for all DynamoDB tables
   - Hourly AWS Backup with 90-day retention
   - Cross-region replication (PROD only to eu-west-1)

7. **Documentation**
   - Architecture diagrams (4 diagrams)
   - Deployment runbooks (4 runbooks)
   - Operational procedures

#### 1.3.2 Out of Scope

The following items are explicitly excluded from this LLD:

1. **Lambda Function Code** - Covered in separate Lambda-specific LLDs
2. **Frontend Application Code** - Separate frontend development scope
3. **API Gateway Configurations** - Defined in API Gateway LLD
4. **Cognito User Pool Setup** - Authentication infrastructure LLD
5. **PayFast Payment Integration** - Payment gateway integration LLD
6. **Multi-Region DR Pipeline** - Separate disaster recovery pipeline
7. **Lambda IAM Permissions** - Defined in Lambda-specific LLDs

### 1.4 Audience

| Role | Usage |
|------|-------|
| **Infrastructure Engineers** | Deploy and maintain DynamoDB tables and S3 buckets |
| **DevOps Engineers** | Implement and manage CI/CD pipelines |
| **Backend Developers** | Understand data structures and storage patterns |
| **Solution Architects** | Review architectural decisions and patterns |
| **QA Engineers** | Develop validation and testing strategies |
| **Operations Team** | Use runbooks for deployment and troubleshooting |

### 1.5 Conventions

#### 1.5.1 Naming Conventions

- **AWS Resources**: Follow AWS naming best practices with lowercase and hyphens
- **DynamoDB Tables**: Simple domain names (e.g., `tenants`, `products`, `campaigns`)
- **S3 Buckets**: Pattern `bbws-{purpose}-{env}` (e.g., `bbws-templates-prod`)
- **Terraform Modules**: Lowercase with underscores (e.g., `dynamodb_table`, `s3_bucket`)
- **GitHub Workflows**: Pattern `{action}-{resource}.yml`

#### 1.5.2 Terminology

| Term | Definition |
|------|------------|
| **Environment** | Deployment target: DEV, SIT, or PROD |
| **GSI** | Global Secondary Index for DynamoDB |
| **PITR** | Point-in-Time Recovery for disaster recovery |
| **Soft Delete** | Setting `active=false` instead of physical deletion |
| **Activatable Entity** | Entity with id, dateCreated, dateLastUpdated, lastUpdatedBy, active fields |
| **Progressive Hardening** | Increasing security and durability from DEV to PROD |
| **Human Approval Gate** | Manual approval required before pipeline progression |

---

## 2. Revision History

| Version | Date | Author | Description | Approved By |
|---------|------|--------|-------------|-------------|
| 1.0.0 | 2025-12-25 | Agentic LLD Architect | Initial draft - Complete infrastructure specification for S3 buckets and DynamoDB tables including 2 GitHub repositories, 3 DynamoDB tables with 9 GSIs, 12 HTML email templates, Terraform modules, and CI/CD pipeline with human approval gates | Pending |

---

## 3. Executive Summary

### 3.1 Purpose

This Low-Level Design (LLD) document specifies the foundational infrastructure for the BBWS Customer Portal (Public) system, focusing on the persistent data layer and deployment automation. It provides detailed technical specifications for DynamoDB tables, S3 buckets, HTML email templates, Terraform infrastructure as code, and CI/CD pipelines with comprehensive approval gates.

The infrastructure defined in this document serves as the foundation for the Customer Portal Public application, enabling customer tenant management, product catalog management, marketing campaign management, and transactional email communications. This LLD is a critical prerequisite for all Lambda function deployments and API Gateway configurations.

### 3.2 Scope Overview

This LLD encompasses the complete infrastructure specification for:

**Repository Structure:**
- 2 GitHub repositories for independent infrastructure management
- Separate repos for DynamoDB schemas (`2_1_bbws_dynamodb_schemas`) and S3 schemas (`2_1_bbws_s3_schemas`)
- Modular Terraform architecture with reusable modules

**DynamoDB Tables:**
- 3 core tables: Tenants, Products, Campaigns
- 9 Global Secondary Indexes across all tables for optimized query patterns
- On-demand capacity mode for all tables and GSIs
- Soft delete pattern using `active` boolean field
- Activatable Entity Pattern with comprehensive audit fields

**S3 Infrastructure:**
- Templates bucket (`bbws-templates-{env}`) across all environments
- 12 HTML email templates organized in 3 categories (receipts, notifications, invoices)
- Customer-facing and internal versions for each template type
- Versioning enabled for all templates with 90-day retention

**Terraform Modules:**
- Modular architecture with 8 specialized terraform modules
- DynamoDB modules: `dynamodb_table`, `gsi`, `backup`
- S3 modules: `s3_bucket`, `bucket_policy`, `replication`
- Environment-specific configurations via `.tfvars` files (dev, sit, prod)
- S3 backend with DynamoDB locking for state management

**CI/CD Pipeline:**
- Comprehensive GitHub Actions workflows with 5 stages per repository
- Multi-stage validation: schema validation, template validation, terraform fmt/validate, security scanning (tfsec), cost estimation (infracost)
- 4 human approval gates: after terraform plan, before DEV deployment, before SIT promotion, before PROD promotion
- Automated rollback capabilities using terraform state versioning
- Progressive deployment strategy: DEV → SIT → PROD with increasing approval requirements

### 3.3 Key Components

#### 3.3.1 DynamoDB Tables (3 Tables, 9 GSIs)

**Tenants Table:**
- Stores customer tenant records with email-based lookup
- PK: `TENANT#{tenantId}`, SK: `METADATA`
- GSIs: EmailIndex, TenantStatusIndex, ActiveIndex
- Supports tenant lifecycle: UNVALIDATED → VALIDATED → REGISTERED → SUSPENDED
- Auto-created during anonymous checkout flow

**Products Table:**
- Product catalog with pricing and features
- PK: `PRODUCT#{productId}`, SK: `METADATA`
- GSIs: ProductActiveIndex, ActiveIndex
- Supports soft delete for historical pricing preservation

**Campaigns Table:**
- Marketing campaigns with discount codes
- PK: `CAMPAIGN#{code}`, SK: `METADATA` (uses business key, not UUID)
- GSIs: CampaignActiveIndex, CampaignProductIndex, ActiveIndex
- Date-range validation for campaign validity

#### 3.3.2 S3 Buckets (12 HTML Templates)

**Template Categories:**

1. **Receipts** (4 templates)
   - `receipt.html` / `receipt_internal.html` - Payment receipts
   - `order.html` / `order_internal.html` - Order summaries

2. **Notifications** (6 templates)
   - `order_confirmation_customer.html` / `order_confirmation_internal.html` - Order creation
   - `payment_confirmation_customer.html` / `payment_confirmation_internal.html` - Payment success
   - `site_creation_customer.html` / `site_creation_internal.html` - WordPress site provisioned

3. **Invoices** (2 templates)
   - `invoice.html` / `invoice_internal.html` - Billing invoices

**Template Requirements:**
- Mustache-style `{{variable}}` placeholders for dynamic content
- Responsive email design (mobile-friendly)
- BBWS/KimmyAI branding with logo and color scheme
- Legal footer with unsubscribe link and company address
- Plain text alternative for accessibility

#### 3.3.3 Terraform Modules

**DynamoDB Repository Modules:**
- `modules/dynamodb_table/` - Creates tables with PK/SK, capacity mode, encryption
- `modules/gsi/` - Manages Global Secondary Indexes
- `modules/backup/` - Configures AWS Backup with hourly schedule and 90-day retention

**S3 Repository Modules:**
- `modules/s3_bucket/` - Creates buckets with versioning, encryption, lifecycle policies
- `modules/bucket_policy/` - Manages IAM policies for Lambda access
- `modules/replication/` - Configures cross-region replication (PROD only)

#### 3.3.4 CI/CD Pipeline Design

**Validation Stages:**
1. Schema validation (JSON schemas for DynamoDB)
2. Template validation (HTML Tidy for templates)
3. Terraform format check (`terraform fmt`)
4. Terraform validation (`terraform validate`)
5. Security scanning (`tfsec` for security best practices)
6. Cost estimation (`infracost` for budget monitoring)

**Approval Gates:**
1. **After Terraform Plan** - Review infrastructure changes (any team member)
2. **Before DEV Deploy** - Approve DEV deployment (Lead Developer)
3. **Before SIT Promotion** - Approve SIT promotion (Tech Lead + QA)
4. **Before PROD Promotion** - Approve PROD production (Tech Lead + Product Owner)

**Deployment Flow:**
- Push to main → Validate → Plan → Approve Plan → Deploy DEV → Test DEV → Approve SIT → Deploy SIT → Test SIT → Approve PROD → Deploy PROD → Test PROD

### 3.4 Environments

This infrastructure supports 3 environments with progressive hardening:

| Environment | AWS Account | Region | Purpose | Approval Gates |
|-------------|-------------|--------|---------|----------------|
| **DEV** | 536580886816 | af-south-1 | Development and integration testing | 1 approver (Lead Developer) |
| **SIT** | 815856636111 | af-south-1 | System integration testing and QA validation | 2 approvers (Tech Lead + QA) |
| **PROD** | 093646564004 | af-south-1 (primary) | Production workloads with DR in eu-west-1 | 3 approvers (Tech Lead + Product Owner) |

**Progressive Hardening Strategy:**
- DEV: Basic monitoring, no replication, simplified backup
- SIT: Enhanced monitoring, no replication, standard backup
- PROD: Comprehensive monitoring, cross-region replication, hourly backup, deletion protection

### 3.5 Key Architectural Decisions

#### 3.5.1 On-Demand Capacity for All DynamoDB Tables

**Decision**: Use PAY_PER_REQUEST billing mode for all DynamoDB tables and GSIs across all environments.

**Rationale:**
- Serverless workload with unpredictable traffic patterns (startup phase)
- Cost-effective for low-traffic scenarios with automatic scaling for traffic spikes
- No capacity planning or provisioning overhead
- Eliminates throttling risks during sudden traffic increases
- Aligns with global CLAUDE.md requirement: "DynamoDB table capacity mode must always be on-demand"

**Impact**: Simplified capacity management, predictable costs during low-volume startup phase, seamless scaling as business grows.

#### 3.5.2 Soft Delete Pattern (Active Boolean)

**Decision**: All entities use soft delete with `active` boolean field instead of physical deletion.

**Rationale:**
- Preserves complete audit trail for compliance and troubleshooting
- Enables data recovery from accidental deletions
- Maintains referential integrity (no broken foreign key relationships)
- Supports historical data analysis and reporting
- Aligns with HLD Section 1.3 decision: "Data Deletion: Soft delete (active=false) - Audit trail, recovery, data integrity"

**Implementation:**
- Default `active=true` on entity creation
- UPDATE operation sets `active=false` instead of DELETE
- Query filters exclude `active=false` by default
- Query parameter `includeInactive=true` to view soft-deleted records

**Impact**: No DELETE HTTP operations in API, all state changes via PUT with status updates.

#### 3.5.3 Cross-Region Replication for PROD Only

**Decision**: Enable DynamoDB Global Tables and S3 cross-region replication only for PROD environment (af-south-1 → eu-west-1).

**Rationale:**
- Disaster recovery requirement: "primary region for prod is af-south-1 and failover region is eu-west-1"
- Cost optimization: DEV and SIT do not require DR capabilities
- Compliance: PROD data must be resilient to regional outages
- RTO/RPO: Multisite active/active DR strategy with Route 53 failover

**Implementation:**
- PROD DynamoDB: Global Table with replica in eu-west-1
- PROD S3: Cross-region replication rules for all buckets
- DEV/SIT: Single-region deployment only

**Impact**: Increased PROD cost for replication and storage, reduced RTO/RPO for production workloads.

#### 3.5.4 Human Approval Gates for All Deployments

**Decision**: Require manual human approval at multiple stages: after plan, before DEV, before SIT, before PROD.

**Rationale:**
- Governance requirement: Infrastructure changes require review and approval
- Risk mitigation: Human review prevents accidental or malicious changes
- Compliance: Audit trail of who approved infrastructure changes
- Progressive approvals: Increasing approval requirements as environment criticality increases (1 approver for DEV, 2 for SIT, 3 for PROD)

**Implementation:**
- GitHub Actions workflows use `workflow_dispatch` for manual triggering
- GitHub environments with protection rules and required reviewers
- Terraform plan output reviewed before approval
- Slack notifications for PROD deployments

**Impact**: Slower deployment velocity, higher governance and safety, clear accountability for infrastructure changes.

#### 3.5.5 Separate Terraform State per Component

**Decision**: Use separate Terraform state files for each infrastructure component (tenants table, products table, campaigns table, S3 templates).

**Rationale:**
- Isolation: Changes to one component don't affect others
- Blast radius reduction: Failed apply only impacts single component
- Parallel development: Teams can work on different components independently
- Easier rollback: Rollback single component without affecting others

**State Organization:**
```
s3://bbws-terraform-state-{env}/
├── 2_1_bbws_dynamodb_schemas/
│   ├── tenants/terraform.tfstate
│   ├── products/terraform.tfstate
│   └── campaigns/terraform.tfstate
└── 2_1_bbws_s3_schemas/
    └── templates/terraform.tfstate
```

**Impact**: Increased state management complexity, improved isolation and safety.

#### 3.5.6 Activatable Entity Pattern for All Entities

**Decision**: All entities must include 5 mandatory fields: id, dateCreated, dateLastUpdated, lastUpdatedBy, active.

**Rationale:**
- Consistent audit trail across all entities
- Standardized soft delete mechanism
- Simplified data governance and compliance
- Easier debugging and troubleshooting with consistent timestamps
- Aligns with HLD Section 1.3: "Entity Pattern: Activatable Entity Pattern"

**Mandatory Fields:**
- `id` (String, UUID): Unique identifier
- `dateCreated` (String, ISO 8601): Creation timestamp (auto-generated)
- `dateLastUpdated` (String, ISO 8601): Last update timestamp (auto-updated)
- `lastUpdatedBy` (String, email): User or system who made last update (from auth context)
- `active` (Boolean, default=true): Soft delete flag

**Impact**: Consistent data model, increased storage per entity (minimal), comprehensive audit capability.

### 3.6 Compliance and Standards

#### 3.6.1 AWS Well-Architected Framework Alignment

This infrastructure design aligns with the AWS Well-Architected Framework across all 6 pillars:

**Operational Excellence:**
- Infrastructure as Code (Terraform) for repeatable deployments
- Automated CI/CD pipeline with validation stages
- Comprehensive runbooks for deployment and troubleshooting
- CloudWatch monitoring and alerting (configured separately)

**Security:**
- Encryption at rest (SSE-KMS for DynamoDB, SSE-S3 for S3)
- Block all S3 public access (global CLAUDE.md requirement)
- IAM policies with least privilege
- Deletion protection for PROD tables
- Access logging enabled on S3 buckets

**Reliability:**
- Point-in-Time Recovery (PITR) enabled for all tables
- Hourly AWS Backup with 90-day retention
- Cross-region replication for PROD (af-south-1 → eu-west-1)
- S3 versioning for template history and rollback
- Terraform state versioning for infrastructure rollback

**Performance Efficiency:**
- On-demand capacity mode for automatic scaling
- Global Secondary Indexes for optimized query patterns
- S3 for static content with eventual CloudFront CDN integration
- DynamoDB Streams enabled for event-driven architectures

**Cost Optimization:**
- On-demand pricing for variable workloads (pay only for usage)
- Lifecycle policies for S3 versioning (90-day retention)
- No cross-region replication for DEV/SIT (cost savings)
- Infracost monitoring in CI/CD pipeline

**Sustainability:**
- Serverless architecture reduces idle compute resources
- On-demand scaling minimizes over-provisioning
- Africa region (af-south-1) for primary workloads

#### 3.6.2 Tagging and Cost Allocation

All resources are tagged with 7 mandatory tags for cost tracking, ownership, and compliance:

| Tag Key | Tag Value | Purpose |
|---------|-----------|---------|
| `Environment` | dev / sit / prod | Environment identification |
| `Project` | BBWS WP Containers | Project name for cost allocation |
| `Owner` | Tebogo | Resource ownership and accountability |
| `CostCenter` | AWS | Cost center for billing |
| `ManagedBy` | Terraform | Infrastructure management tool |
| `BackupPolicy` | daily / hourly | Backup schedule (tables only) |
| `Component` | dynamodb / s3 | Component type for organization |

**Cost Budgets:**
- DEV: $500/month with 80% alert threshold
- SIT: $1,000/month with 80% alert threshold
- PROD: $5,000/month with 80% alert threshold

#### 3.6.3 Environment Parameterization

**No Hardcoded Credentials:**
- All environment-specific values parameterized via Terraform variables
- Separate `.tfvars` files per environment (dev.tfvars, sit.tfvars, prod.tfvars)
- GitHub Actions secrets for AWS credentials
- Lambda environment variables reference resource names by naming convention

**Automation:**
- Terraform modules are environment-agnostic
- Same codebase deploys to all environments with different variable files
- No manual configuration or credential management
- CI/CD pipeline handles all deployments

### 3.7 Quality Assurance

This LLD builds upon comprehensive Stage 1 analysis with the following quality metrics:

**Stage 1 Requirements Analysis:**
- 7 entities analyzed with complete PK/SK patterns and relationships
- 9 GSIs identified with access pattern mapping
- 5 S3 bucket types specified with lifecycle and access policies
- 12 email templates categorized by purpose
- 65 requirements validated across 9 categories
- 97.6% overall quality score (Excellent)
- 0 conflicts detected between requirements and specifications
- 0 blocking issues identified
- 10 naming convention matrices delivered
- 10 environment configuration matrices completed

**Validation Results:**
- Repository requirements: 100% validated
- DynamoDB requirements: 100% validated
- S3 requirements: 100% validated
- Terraform requirements: 100% validated
- CI/CD requirements: 100% validated
- Disaster recovery requirements: 100% validated

**Risk Assessment:**
- 0 high-risk items
- 3 medium-risk items with documented mitigations
- 29 low-risk assumptions documented
- All pre-requisites identified and verified

### 3.8 Success Criteria

This LLD is considered complete when the following acceptance criteria are met:

**Infrastructure Deployment:**
- [ ] 3 DynamoDB tables created with correct schemas in all 3 environments (DEV, SIT, PROD)
- [ ] 9 Global Secondary Indexes created and functional across all tables
- [ ] S3 buckets created with correct configurations (versioning, encryption, lifecycle)
- [ ] 12 HTML templates uploaded to S3 in all environments
- [ ] Cross-region replication verified for PROD (af-south-1 → eu-west-1)

**CI/CD Pipeline:**
- [ ] GitHub Actions workflows execute successfully for both repositories
- [ ] All validation stages pass (schema, template, terraform, security, cost)
- [ ] Approval gates function correctly with required reviewers
- [ ] DEV deployment successful via automated pipeline
- [ ] SIT promotion successful with approval gates
- [ ] PROD promotion successful with 3-approver gate (dry-run initially)

**Disaster Recovery:**
- [ ] PITR enabled and verified on all tables
- [ ] Hourly AWS Backup configured with 90-day retention
- [ ] Rollback process validated in DEV environment
- [ ] Cross-region replication tested for PROD failover

**Documentation:**
- [ ] 4 architecture diagrams completed and reviewed
- [ ] 4 operational runbooks created (deployment, promotion, troubleshooting, rollback)
- [ ] Terraform module documentation complete
- [ ] Post-deployment tests pass in all environments

**Quality Gates:**
- [ ] All JSON schemas valid
- [ ] All HTML templates valid (HTML Tidy passes)
- [ ] Terraform format check passes (`terraform fmt -check`)
- [ ] Security scan passes (no high/critical tfsec findings)
- [ ] Cost estimation under budget thresholds (DEV/SIT < $100/month)
- [ ] All resources tagged correctly with 7 mandatory tags
- [ ] Tag compliance verified via AWS Resource Groups

### 3.9 Document Organization

This LLD is organized into 8 main sections for comprehensive coverage:

**Section 1: Document Information** - Metadata, scope, audience, conventions, referenced documents

**Section 2: Revision History** - Version control and change tracking

**Section 3: Executive Summary** - Purpose, scope, key components, architectural decisions, compliance, success criteria

**Section 4: DynamoDB Table Design** - Detailed schemas for Tenants, Products, Campaigns tables with GSIs, access patterns, PK/SK patterns, soft delete implementation

**Section 5: S3 Bucket Design** - Bucket configurations, 12 HTML template specifications, versioning, encryption, lifecycle policies, cross-region replication

**Section 6: Terraform Module Design** - Module architecture, state management, environment configurations, resource naming, tagging strategy

**Section 7: CI/CD Pipeline Design** - GitHub Actions workflows, validation stages, approval gates, deployment strategies, rollback procedures

**Section 8: Appendices** - Architecture diagrams, sequence diagrams, runbook references, glossary, additional resources

---

**End of Sections 1-3**

*Next sections (4-8) will be completed by Workers 2-2 through 2-6 in parallel.*
