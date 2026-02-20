# Worker 1: BRS Analysis

**Worker Status**: PENDING
**Task**: Business Requirements Specification Analysis
**Input**: `2_bbws_docs/BRS/2.2_BRS_Customer_Portal_Private.md`
**Output**: `output.md`

---

## Objective

Extract, categorise, and summarise all business requirements from the BRS document to prepare for LLD creation.

---

## Task Details

### 1. Epic Extraction
- Identify all epics from the BRS
- List user stories per epic
- Document acceptance criteria

### 2. Functional Requirements
- Extract all functional requirements (FR-*)
- Map requirements to screens
- Map requirements to microservices

### 3. Non-Functional Requirements
- Extract NFRs (performance, security, availability)
- Document compliance requirements
- Identify integration requirements

### 4. User Role Matrix
- Document all user roles (super-admin, admin, user, viewer)
- Map permissions per role
- Document role hierarchy

---

## Output Format

```markdown
# Requirements Summary

## 1. Epics Overview
| Epic ID | Name | User Stories | Priority |
|---------|------|--------------|----------|

## 2. Functional Requirements Matrix
| FR ID | Requirement | Screen(s) | Service(s) | Priority |
|-------|-------------|-----------|------------|----------|

## 3. Non-Functional Requirements
| NFR ID | Requirement | Metric | Target |
|--------|-------------|--------|--------|

## 4. User Role Permissions
| Permission | super-admin | admin | user | viewer |
|------------|-------------|-------|------|--------|

## 5. Key Observations
- [List any gaps or concerns]
```

---

## Success Criteria

- [ ] All epics extracted and documented
- [ ] All functional requirements mapped
- [ ] All NFRs documented with metrics
- [ ] Role permissions matrix complete
- [ ] No missing requirements identified

---

**Worker Type**: Analysis
**Created**: 2026-01-18
