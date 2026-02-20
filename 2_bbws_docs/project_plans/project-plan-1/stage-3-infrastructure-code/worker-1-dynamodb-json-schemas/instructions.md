# Worker 3-1: DynamoDB JSON Schemas

**Worker ID**: worker-3-1-dynamodb-json-schemas
**Stage**: Stage 3 - Infrastructure Code Development
**Status**: PENDING
**Estimated Effort**: Medium
**Dependencies**: Stage 2 Worker 2-2

---

## Objective

Create JSON schema files for all 3 DynamoDB tables (tenants, products, campaigns) based on the LLD specifications from Stage 2.

---

## Input Documents

1. **Stage 2 Outputs**:
   - `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/project-plan-1/stage-2-lld-document-creation/worker-2-dynamodb-design-section/output.md` (Section 4.2, 4.3, 4.4 - table schemas)

---

## Deliverables

Create `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/project-plan-1/stage-3-infrastructure-code/worker-1-dynamodb-json-schemas/output.md` containing:

### 3 JSON Schema Files

**1. tenants.schema.json**
```json
{
  "tableName": "tenants",
  "description": "Tenant entity table for BBWS Customer Portal Public",
  "primaryKey": {
    "partitionKey": {
      "name": "PK",
      "type": "S",
      "description": "Partition key: TENANT#{tenantId}"
    },
    "sortKey": {
      "name": "SK",
      "type": "S",
      "description": "Sort key: METADATA"
    }
  },
  "attributes": [
    {"name": "PK", "type": "S"},
    {"name": "SK", "type": "S"},
    {"name": "id", "type": "S"},
    {"name": "email", "type": "S"},
    {"name": "status", "type": "S"},
    {"name": "active", "type": "BOOL"},
    {"name": "dateCreated", "type": "S"},
    {"name": "dateLastUpdated", "type": "S"},
    {"name": "lastUpdatedBy", "type": "S"}
  ],
  "globalSecondaryIndexes": [
    {
      "indexName": "EmailIndex",
      "partitionKey": {"name": "email", "type": "S"},
      "sortKey": null,
      "projectionType": "ALL",
      "description": "Lookup tenant by email address"
    },
    {
      "indexName": "TenantStatusIndex",
      "partitionKey": {"name": "status", "type": "S"},
      "sortKey": {"name": "dateCreated", "type": "S"},
      "projectionType": "ALL",
      "description": "Query tenants by status with date ordering"
    },
    {
      "indexName": "ActiveIndex",
      "partitionKey": {"name": "active", "type": "BOOL"},
      "sortKey": {"name": "dateCreated", "type": "S"},
      "projectionType": "ALL",
      "description": "List active/inactive tenants with date ordering"
    }
  ],
  "capacityMode": "ON_DEMAND",
  "pointInTimeRecovery": true,
  "streamEnabled": false,
  "ttlEnabled": false,
  "tags": {
    "Environment": "managed-per-environment",
    "Project": "bbws-customer-portal-public",
    "Component": "dynamodb",
    "ManagedBy": "terraform"
  }
}
```

**2. products.schema.json**
Similar structure for products table with:
- PK: PRODUCT#{productId}, SK: METADATA
- Attributes: id, name, description, price, features, billingCycle, active, dateCreated, dateLastUpdated, lastUpdatedBy
- GSIs: ProductActiveIndex, ActiveIndex

**3. campaigns.schema.json**
Similar structure for campaigns table with:
- PK: CAMPAIGN#{code}, SK: METADATA
- Attributes: id, code, description, discountPercentage, productId, termsConditionsLink, fromDate, toDate, active, dateCreated, dateLastUpdated, lastUpdatedBy
- GSIs: CampaignActiveIndex, CampaignProductIndex, ActiveIndex

---

## Quality Criteria

- [ ] All 3 JSON schema files are valid JSON
- [ ] Schema structure matches DynamoDB table structure from LLD
- [ ] All attributes from Stage 2 Worker 2-2 are included
- [ ] All GSIs correctly specified with partition/sort keys
- [ ] Capacity mode set to ON_DEMAND
- [ ] PITR enabled
- [ ] Tags structure included

---

## Output Format

Write output to `output.md` containing all 3 JSON schema files in code blocks.

**Target Length**: 300-400 lines

---

## Special Instructions

1. **Extract from Stage 2**: Use Worker 2-2 output Section 4.2.1, 4.3.1, 4.4.1 for table schemas
2. **JSON Validity**: Ensure all JSON is syntactically valid
3. **Complete Attributes**: Include ALL attributes listed in LLD
4. **GSI Specifications**: Match GSI names and configurations exactly from LLD

---

**Worker Created**: 2025-12-25
**Execution Mode**: Parallel (with 5 other Stage 3 workers)
