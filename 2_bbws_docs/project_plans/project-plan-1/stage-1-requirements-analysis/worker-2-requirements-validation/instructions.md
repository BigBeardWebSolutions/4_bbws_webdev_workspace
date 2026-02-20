# Worker Instructions: Requirements Validation

**Worker ID**: worker-2-requirements-validation
**Stage**: Stage 1 - Requirements & Analysis
**Project**: project-plan-1

---

## Task

Validate all requirements from the questions.md answers and refined specification document to ensure completeness, consistency, and no conflicts exist.

---

## Inputs

**Primary Inputs**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/specs/questions.md` (with answers)
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/specs/2.1.8_LLD_S3_and_DynamoDB_Spec.md`

**Supporting Inputs**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/CLAUDE.md` (LLD standards)

---

## Deliverables

Create `output.md` with the following sections:

### 1. Requirements Validation Checklist

**Repository Requirements**:
- [ ] Repository names validated: `2_1_bbws_dynamodb_schemas`, `2_1_bbws_s3_schemas`
- [ ] Single repo per resource type confirmed
- [ ] Repository structure defined

**DynamoDB Requirements**:
- [ ] Tables identified: Tenants, Products, Campaigns
- [ ] Table schemas specified for all 3 tables
- [ ] GSI requirements documented
- [ ] Capacity mode: On-demand (confirmed)
- [ ] PITR enabled requirement confirmed
- [ ] Backup strategy: Hourly backups (confirmed)

**S3 Requirements**:
- [ ] Bucket naming: `bbws-templates-{env}` (confirmed)
- [ ] HTML templates: All 12 templates identified
- [ ] Template categories: receipts, notifications, invoices (confirmed)
- [ ] Versioning enabled requirement confirmed
- [ ] Public access blocked requirement confirmed

**Terraform Requirements**:
- [ ] Separate modules per component (confirmed)
- [ ] State per component: S3 sub-folders (confirmed)
- [ ] Environment configs: .tfvars files per env (confirmed)

**CI/CD Pipeline Requirements**:
- [ ] Validation stages defined
- [ ] Approval gates: Plan + Environment promotion (confirmed)
- [ ] Rollback: Terraform state rollback (confirmed)
- [ ] Environments: DEV, SIT, PROD (confirmed)

**Disaster Recovery**:
- [ ] PITR, scheduled backups, cross-region replication (confirmed)
- [ ] DR region: eu-west-1 (PROD only) (confirmed)
- [ ] Multi-region deployment: Separate pipeline (confirmed - out of scope)

### 2. Requirement Conflicts Analysis

Identify any conflicting requirements:
- Cross-reference questions.md answers with spec document
- Note any inconsistencies between user answers and spec
- Flag any ambiguous requirements

**Format**:
```
| Requirement | Source 1 | Source 2 | Conflict? | Resolution |
|-------------|----------|----------|-----------|------------|
| ... | ... | ... | Yes/No | ... |
```

### 3. Missing Requirements

Identify any gaps:
- Required information not provided
- Assumptions that need validation
- Dependencies not documented

### 4. Clarifications Needed

List questions that remain unanswered:
- Ambiguous requirements
- Implementation details needed
- Decision points requiring user input

### 5. Assumptions Log

Document all assumptions made:
- Implicit requirements
- Default behaviors
- Technical decisions

---

## Expected Output Format

```markdown
# Requirements Validation Output

## Requirements Validation Checklist

### Repository Requirements
- [x] Repository names validated: `2_1_bbws_dynamodb_schemas`, `2_1_bbws_s3_schemas`
- [x] Single repo per resource type confirmed
...

### DynamoDB Requirements
- [x] Tables identified: Tenants, Products, Campaigns
...

## Requirement Conflicts Analysis

| Requirement | Source 1 | Source 2 | Conflict? | Resolution |
|-------------|----------|----------|-----------|------------|
| Bucket naming | questions.md: bbws-{purpose}-{env} | spec.md: bbws-templates-{env} | No | Consistent |
...

## Missing Requirements

1. **Lambda IAM Permissions** - Out of scope, handled in Lambda LLDs
2. **Terraform backend buckets** - Pre-requisite, assumed to exist
...

## Clarifications Needed

None - all requirements sufficiently detailed.

## Assumptions Log

1. AWS accounts (DEV/SIT/PROD) already exist
2. Terraform state buckets already provisioned
3. GitHub org access available
...
```

---

## Success Criteria

- [ ] All requirement categories validated
- [ ] Checklist 100% complete
- [ ] Conflicts identified and documented
- [ ] Missing requirements listed
- [ ] Clarifications documented
- [ ] Assumptions logged
- [ ] No blocking issues

---

## Execution Steps

1. Read questions.md with user answers
2. Read refined specification document
3. Read LLD standards from CLAUDE.md
4. Create validation checklist for each category
5. Cross-reference requirements for conflicts
6. Identify missing requirements
7. Document clarifications needed
8. Log all assumptions
9. Create output.md with all sections
10. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2025-12-25
