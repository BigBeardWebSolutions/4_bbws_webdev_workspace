# Worker Instructions: DynamoDB Tables Module

**Worker ID**: worker-1-dynamodb-tables-module
**Stage**: Stage 2 - Infrastructure Terraform
**Project**: project-plan-2-access-management

---

## Task

Create Terraform module for DynamoDB tables supporting the Access Management system. Use single-table design with multiple entity types and GSIs.

---

## Inputs

**From Stage 1**:
- `/stage-1-lld-review-analysis/worker-1-permission-service-review/output.md`
- `/stage-1-lld-review-analysis/worker-2-invitation-service-review/output.md`
- `/stage-1-lld-review-analysis/worker-3-team-service-review/output.md`
- `/stage-1-lld-review-analysis/worker-4-role-service-review/output.md`
- `/stage-1-lld-review-analysis/worker-6-audit-service-review/output.md`

**LLD References**:
- All LLDs in `/2_bbws_docs/LLDs/2.8.*`

---

## Deliverables

Create Terraform module in `output.md` with the following structure:

### 1. Main Table Definition

```
terraform/modules/dynamodb-access-management/
├── main.tf           # Table definition
├── gsi.tf            # Global Secondary Indexes
├── variables.tf      # Input variables
├── outputs.tf        # Output values
└── locals.tf         # Local values
```

### 2. Table Configuration

**Table Name**: `bbws-access-{env}-ddb-access-management`

**Capacity**: On-demand (PAY_PER_REQUEST)

**Primary Key**:
- PK (Partition Key): String
- SK (Sort Key): String

**Attributes**:
- PK, SK, GSI1PK, GSI1SK, GSI2PK, GSI2SK, GSI3PK, GSI3SK

### 3. Global Secondary Indexes (5)

| GSI | PK | SK | Purpose |
|-----|----|----|---------|
| GSI1 | GSI1PK | GSI1SK | Status/expiry queries |
| GSI2 | GSI2PK | GSI2SK | Email lookups |
| GSI3 | GSI3PK | GSI3SK | User team memberships |
| GSI4 | GSI4PK | GSI4SK | Audit by user |
| GSI5 | GSI5PK | GSI5SK | Audit by event type |

### 4. Entity Key Patterns

| Entity | PK | SK |
|--------|----|----|
| Permission | PERMISSION#{id} | METADATA |
| Invitation | ORG#{orgId} | INVITATION#{id} |
| InvitationToken | TOKEN#{token} | METADATA |
| Team | ORG#{orgId} | TEAM#{teamId} |
| TeamRoleDefinition | ORG#{orgId} | TEAM_ROLE#{roleId} |
| TeamMember | TEAM#{teamId} | MEMBER#{userId} |
| PlatformRole | PLATFORM | ROLE#{roleId} |
| OrganisationRole | ORG#{orgId} | ROLE#{roleId} |
| UserRoleAssignment | ORG#{orgId}#USER#{userId} | ROLE#{roleId} |
| AuditEvent | ORG#{orgId}#DATE#{date} | EVENT#{timestamp}#{eventId} |

### 5. Additional Features

- Point-in-time recovery (PITR) enabled
- Server-side encryption (AWS managed)
- TTL attribute for invitation expiry
- Tags for cost allocation

---

## Variables Required

```hcl
variable "environment" {
  type = string
}

variable "project_name" {
  type    = string
  default = "bbws-access"
}

variable "enable_pitr" {
  type    = bool
  default = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
```

---

## Success Criteria

- [ ] Table uses on-demand capacity
- [ ] All 5 GSIs defined
- [ ] PITR enabled
- [ ] TTL configured
- [ ] Encryption enabled
- [ ] No hardcoded values
- [ ] Environment parameterized
- [ ] Follows BBWS naming convention
- [ ] `terraform validate` passes

---

## Execution Steps

1. Read Stage 1 outputs for entity schemas
2. Design single-table structure
3. Create main.tf with table definition
4. Create gsi.tf with all GSIs
5. Create variables.tf
6. Create outputs.tf
7. Create locals.tf
8. Validate Terraform syntax
9. Create output.md with all code
10. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-23
