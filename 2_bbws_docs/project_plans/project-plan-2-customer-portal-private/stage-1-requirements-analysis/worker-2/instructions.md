# Worker 2: HLD Architecture Review

**Worker Status**: PENDING
**Task**: High-Level Design Architecture Analysis
**Input**: `2_bbws_docs/HLDs/2.2_BBWS_Customer_Portal_Private_HLD.md`
**Output**: `output.md`

---

## Objective

Review and validate the microservices architecture, bounded contexts, and integration points defined in the HLD.

---

## Task Details

### 1. Bounded Context Analysis
- Review TENANTS, ORDERS, SUPPORT contexts
- Validate entity relationships
- Document context boundaries

### 2. Microservices Architecture
- Validate 15 microservices definitions
- Document service responsibilities
- Identify service dependencies

### 3. Integration Points
- Document API Gateway integration
- Review Lambda authorizer flow
- Validate Cognito integration

### 4. Data Flow Analysis
- Document key user flows
- Identify async processing patterns
- Validate SQS integration points

---

## Output Format

```markdown
# Architecture Analysis

## 1. Bounded Contexts
| Context | Entities | Services |
|---------|----------|----------|

## 2. Microservices Dependency Map
| Service | Depends On | Used By |
|---------|------------|---------|

## 3. Integration Points
| Integration | Type | Protocol |
|-------------|------|----------|

## 4. Key User Flows
### Flow 1: [Name]
[Sequence diagram in mermaid]

## 5. Architecture Observations
- [List any concerns or recommendations]
```

---

## Success Criteria

- [ ] All bounded contexts documented
- [ ] Service dependencies mapped
- [ ] Integration points validated
- [ ] Key flows documented with diagrams
- [ ] Architecture is coherent and scalable

---

**Worker Type**: Analysis
**Created**: 2026-01-18
