# Worker Instructions: HLD Analysis

**Worker ID**: worker-1-hld-analysis
**Stage**: Stage 1 - Requirements & Analysis
**Project**: project-plan-1

---

## Task

Analyze the Customer Portal Public HLD v1.1 document and extract key entities, relationships, constraints, and architectural decisions relevant to DynamoDB tables and S3 buckets.

---

## Inputs

**Primary Input**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/HLDs/2.1_BBWS_Customer_Portal_Public_HLD_V1.1.md`

**Supporting Inputs**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/specs/2.1.8_LLD_S3_and_DynamoDB_Spec.md`

---

## Deliverables

Create `output.md` with the following sections:

### 1. Entity Summary

Extract and document:
- **Tenant Entity**: Attributes, status values, relationships
- **Product Entity**: Attributes, pricing structure, relationships
- **Campaign Entity**: Attributes, discount logic, relationships
- **Order Entity**: How it relates to Tenant (prerequisite check)
- **Payment Entity**: How it relates to Order and Tenant

### 2. Table Relationships

Document:
- Primary Key (PK) patterns
- Sort Key (SK) patterns
- GSI requirements
- Entity hierarchy (Parent → Child)

### 3. S3 Requirements

Extract:
- Required S3 buckets from HLD
- Template requirements
- File paths and naming patterns

### 4. Architectural Constraints

Document:
- Soft delete pattern (active boolean)
- Capacity mode requirements
- PITR requirements
- Cross-region replication (PROD only)
- Tagging requirements

### 5. API Patterns

Extract:
- Hierarchical HATEOAS patterns
- Entity ownership context (e.g., `/v1.0/tenants/{id}/orders`)
- Pagination patterns (pageSize, startAt, moreAvailable)

---

## Expected Output Format

```markdown
# HLD Analysis Output

## Entity Summary

### Tenant
- **PK Pattern**: `TENANT#{tenantId}`
- **SK Pattern**: `METADATA`
- **Attributes**: id, email, status, organizationName, ...
- **Status Values**: UNVALIDATED, VALIDATED, REGISTERED, SUSPENDED

(Continue for each entity...)

## Table Relationships

(Mermaid diagram or textual description)

## S3 Requirements

- Bucket: bbws-templates-{env}
- Templates: receipts/receipt.html, receipts/order.html, ...

## Architectural Constraints

- Soft delete: All entities have `active` boolean
- Capacity: On-demand mode required
- PITR: Enabled for all tables
...

## API Patterns

- Hierarchical URLs reflect entity ownership
- Example: `/v1.0/tenants/{tenantId}/orders/{orderId}`
...
```

---

## Success Criteria

- [ ] All 5 sections completed
- [ ] Entity attributes accurately extracted
- [ ] PK/SK patterns documented
- [ ] S3 requirements identified
- [ ] Constraints clearly listed
- [ ] API patterns documented

---

## Execution Steps

1. Read HLD v1.1 document
2. Extract entities from Section 8 (DynamoDB Schema)
3. Document PK/SK patterns
4. Extract S3 bucket requirements from Section 9 (Infrastructure)
5. Note architectural decisions from Section 1.3 (Key Decisions)
6. Document API patterns from Section 5 (API Endpoints)
7. Create output.md with all sections
8. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2025-12-25
