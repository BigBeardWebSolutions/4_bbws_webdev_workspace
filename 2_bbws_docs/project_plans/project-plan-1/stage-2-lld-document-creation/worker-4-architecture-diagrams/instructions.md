# Worker Instructions: Architecture Diagrams

**Worker ID**: worker-4-architecture-diagrams
**Stage**: Stage 2 - LLD Document Creation
**Project**: project-plan-1

---

## Task

Create 4 comprehensive architecture diagrams using Mermaid syntax for inclusion in the LLD document.

---

## Inputs

**From Stage 1**:
- Entity relationship summary (worker-1 output)
- Stage 1 summary

**From Spec**:
- Section 9.1: Documentation Requirements - Diagram Requirements

---

## Deliverables

Create `output.md` with 4 diagrams in Mermaid format:

### Diagram 1: DynamoDB Table Relationship Diagram

Show:
- All 3 tables (Tenants, Products, Campaigns)
- PK/SK patterns for each
- GSIs and their purposes
- Entity relationships
- Access patterns

**Format**: Entity Relationship Diagram (Mermaid ER diagram or flowchart)

### Diagram 2: S3 Bucket Organization Diagram

Show:
- Bucket naming pattern (bbws-templates-{env})
- Folder structure (receipts/, notifications/, invoices/)
- Template files in each folder
- Versioning indication
- Replication flow (PROD → DR region)

**Format**: Hierarchical tree diagram

### Diagram 3: CI/CD Pipeline Flow Diagram

Show:
- Pipeline stages (Validation → Plan → Approval → Deploy → Test)
- Approval gates (human review points)
- Environment flow (DEV → SIT → PROD)
- Rollback paths
- Validation steps

**Format**: Flowchart with decision points

### Diagram 4: Environment Promotion Diagram

Show:
- Three environments (DEV, SIT, PROD)
- Promotion workflow
- Approval requirements at each gate
- Terraform state management
- Success/failure paths

**Format**: Sequence diagram or flowchart

---

## Expected Output Format

```markdown
# Architecture Diagrams

## Diagram 1: DynamoDB Table Relationships

\`\`\`mermaid
erDiagram
    TENANT ||--o{ ORDER : has
    PRODUCT ||--o{ CAMPAIGN : has
    CAMPAIGN }o--|| PRODUCT : references

    TENANT {
        string PK "TENANT#id"
        string SK "METADATA"
        string id
        string email
        string status
        boolean active
    }

    ...
\`\`\`

## Diagram 2: S3 Bucket Organization

\`\`\`mermaid
graph TD
    A[bbws-templates-env] --> B[receipts/]
    A --> C[notifications/]
    A --> D[invoices/]
    B --> E[receipt.html]
    B --> F[order.html]
    ...
\`\`\`

## Diagram 3: CI/CD Pipeline Flow

\`\`\`mermaid
flowchart TD
    A[Code Push] --> B[Validation]
    B --> C{Valid?}
    C -->|Yes| D[Terraform Plan]
    C -->|No| Z[Fix Issues]
    D --> E{Approval}
    E -->|Approved| F[Deploy DEV]
    E -->|Rejected| Z
    ...
\`\`\`

## Diagram 4: Environment Promotion

\`\`\`mermaid
sequenceDiagram
    participant Dev as DEV
    participant SIT as SIT
    participant PROD as PROD
    participant Approver

    Dev->>Dev: Deploy & Test
    Dev->>Approver: Request SIT Promotion
    Approver->>SIT: Approve
    SIT->>SIT: Deploy & Test
    ...
\`\`\`
```

---

## Success Criteria

- [ ] All 4 diagrams created
- [ ] Diagrams use valid Mermaid syntax
- [ ] Diagrams accurately represent system architecture
- [ ] Diagrams are clear and professional
- [ ] All key components included

---

## Execution Steps

1. Read Stage 1 outputs for entity details
2. Review spec Section 9.2 for diagram requirements
3. Create Diagram 1: DynamoDB relationships
4. Create Diagram 2: S3 bucket structure
5. Create Diagram 3: CI/CD pipeline flow
6. Create Diagram 4: Environment promotion
7. Validate Mermaid syntax
8. Create output.md with all diagrams
9. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2025-12-25
