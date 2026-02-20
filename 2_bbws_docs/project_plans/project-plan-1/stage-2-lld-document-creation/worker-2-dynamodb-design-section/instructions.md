# Worker 2-2: DynamoDB Design Section

**Worker ID**: worker-2-2-dynamodb-design-section
**Stage**: Stage 2 - LLD Document Creation
**Status**: PENDING
**Estimated Effort**: High
**Dependencies**: Stage 1 Worker 1-1, Worker 3-3

---

## Objective

Create comprehensive DynamoDB design section (Section 4) of the LLD document with detailed table specifications, GSI designs, access patterns, and capacity planning.

---

## Input Documents

1. **Stage 1 Outputs**:
   - `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/project-plan-1/stage-1-requirements-analysis/worker-1-hld-analysis/output.md` (Entity analysis, PK/SK patterns, GSIs)
   - `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/project-plan-1/stage-1-requirements-analysis/worker-3-naming-convention-analysis/output.md` (Table naming, GSI naming)
   - `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/project-plan-1/stage-1-requirements-analysis/worker-4-environment-configuration-analysis/output.md` (DynamoDB configs per env)

2. **Specification Documents**:
   - `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/specs/2.1.8_LLD_S3_and_DynamoDB_Spec.md` (Section 3: DynamoDB Table Specifications)

3. **Parent HLD**:
   - `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/HLDs/2.1_BBWS_Customer_Portal_Public_HLD_V1.1.md` (DynamoDB section)

---

## Deliverables

Create `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/project-plan-1/stage-2-lld-document-creation/worker-2-dynamodb-design-section/output.md` containing:

### Section 4: DynamoDB Table Design

#### 4.1 Overview
- Purpose of DynamoDB tables in the architecture
- Design philosophy (separate tables vs single-table design - we use separate tables)
- Key patterns used: Soft delete, Activatable entities, Hierarchical ownership

#### 4.2 Table: `tenants`

**4.2.1 Table Schema**
- Table name: `tenants`
- Primary key: `PK` (String), `SK` (String)
- Attributes table with ALL attributes from Worker 1-1 analysis
- Capacity mode: ON_DEMAND
- PITR: Enabled
- Backups: Hourly (PROD only, automated via AWS Backup)

**4.2.2 Primary Key Design**
- PK pattern: `TENANT#{tenantId}`
- SK pattern: `METADATA`
- Justification for design choice

**4.2.3 Global Secondary Indexes**

For each GSI:
- Index name (follow naming from Worker 3-3)
- PK/SK attributes
- Projection type
- Purpose and use case

GSIs to document:
1. `EmailIndex`: email (PK) → tenantId lookup
2. `TenantStatusIndex`: status (PK), dateCreated (SK) → filter tenants by status
3. `ActiveIndex`: active (PK), dateCreated (SK) → list only active tenants

**4.2.4 Access Patterns**
List all access patterns from HLD:
- AP-1: Get tenant by ID
- AP-2: Get tenant by email (EmailIndex)
- AP-3: List all tenants with pagination
- AP-4: List tenants by status (TenantStatusIndex)
- AP-5: Create tenant
- AP-6: Update tenant status
- AP-7: Soft delete tenant (set active=false)

**4.2.5 Business Rules**
- Tenant auto-creation at checkout if email doesn't exist
- Email uniqueness enforcement
- Status lifecycle: UNVALIDATED → VALIDATED → REGISTERED
- Soft delete (no physical DELETE operations)

#### 4.3 Table: `products`

Follow same structure as 4.2:
- Table schema
- Primary key design: `PRODUCT#{productId}`, `METADATA`
- GSIs: `ProductActiveIndex`
- Access patterns (from HLD)
- Business rules (soft delete, price updates, features list)

#### 4.4 Table: `campaigns`

Follow same structure as 4.2:
- Table schema
- Primary key design: `CAMPAIGN#{code}`, `METADATA`
- GSIs: `CampaignActiveIndex`, `CampaignProductIndex`
- Access patterns (from HLD)
- Business rules (date validation, discount calculation, product association)

#### 4.5 Repository Structure

**4.5.1 Repository: `2_1_bbws_dynamodb_schemas`**

Folder structure:
```
2_1_bbws_dynamodb_schemas/
├── schemas/
│   ├── tenants.schema.json
│   ├── products.schema.json
│   └── campaigns.schema.json
├── terraform/
│   ├── modules/
│   │   └── dynamodb_table/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── environments/
│       ├── dev.tfvars
│       ├── sit.tfvars
│       └── prod.tfvars
├── .github/
│   └── workflows/
│       ├── validate-schemas.yml
│       ├── terraform-plan.yml
│       └── terraform-apply.yml
└── README.md
```

**4.5.2 JSON Schema Examples**

Provide example structure for `tenants.schema.json`:
```json
{
  "tableName": "tenants",
  "primaryKey": {
    "partitionKey": "PK",
    "sortKey": "SK"
  },
  "attributes": [
    {"name": "PK", "type": "S"},
    {"name": "SK", "type": "S"},
    ...
  ],
  "globalSecondaryIndexes": [...]
}
```

#### 4.6 Environment Configuration

**4.6.1 DEV Environment**
- Account ID: 536580886816
- Region: af-south-1
- Capacity mode: ON_DEMAND
- PITR: Enabled
- Backups: None
- Tags: Environment=dev, Project=bbws-customer-portal-public, ManagedBy=terraform

**4.6.2 SIT Environment**
(same structure)

**4.6.3 PROD Environment**
- Account ID: 093646564004
- Region: af-south-1
- Capacity mode: ON_DEMAND
- PITR: Enabled
- Backups: Hourly via AWS Backup
- Cross-region replication: eu-west-1 (DR)
- Tags: (7 mandatory tags from Worker 3-3)

#### 4.7 Capacity Planning

- All tables use ON_DEMAND capacity
- Justification: Unpredictable traffic patterns, cost optimization
- Cost estimation per environment (from Worker 4-4)

#### 4.8 Backup and Recovery

- PITR enabled all environments
- Hourly backups PROD only
- Backup retention: 30 days
- Cross-region replication PROD → eu-west-1

---

## Quality Criteria

- [ ] All 3 tables documented comprehensively
- [ ] All GSIs documented with purpose
- [ ] All access patterns listed
- [ ] Repository structure matches spec
- [ ] Environment configs match Stage 1 Worker 4-4 output
- [ ] No inconsistencies with HLD
- [ ] Technical accuracy verified
- [ ] No placeholder text

---

## Output Format

Write output to `output.md` using markdown format with proper headings, code blocks, and tables.

**Target Length**: 1,200-1,500 lines

---

## Special Instructions

1. **Use Exact Naming from Stage 1**:
   - Table names from Worker 3-3: `tenants`, `products`, `campaigns`
   - GSI naming pattern: `{Entity}{Attribute}Index`
   - Repository name: `2_1_bbws_dynamodb_schemas`

2. **Reference Worker 1-1 Entity Analysis**:
   - Copy attribute lists exactly as documented
   - Copy PK/SK patterns exactly
   - Copy business rules and relationships

3. **Cross-Reference Worker 4-4**:
   - Use environment account IDs from Worker 4-4
   - Use capacity/backup configs from Worker 4-4

4. **Technical Depth**:
   - Include detailed explanations of WHY choices were made
   - Explain GSI projections and their cost implications
   - Explain ON_DEMAND capacity choice

---

**Worker Created**: 2025-12-25
**Execution Mode**: Parallel (with 5 other Stage 2 workers)
