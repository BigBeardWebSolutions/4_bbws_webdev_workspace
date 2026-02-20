# Stage 3: LLD Creation

**Parent Plan**: [BBWS SDLC Main Plan](./main-plan.md)
**Stage**: 3 of 10
**Status**: ⏳ PENDING
**Last Updated**: 2026-01-01

---

## Objective

Create a Low-Level Design (LLD) document that provides detailed implementation specifications including class diagrams, sequence diagrams, database schemas, and API contracts.

---

## Agent & Skill Assignment

| Role | Agent | Skill |
|------|-------|-------|
| **Primary** | LLD_Architect_Agent | `HLD_LLD_Naming_Convention.skill.md` |
| **Support** | - | `DynamoDB_Single_Table.skill.md` |
| **Support** | - | `HATEOAS_Relational_Design.skill.md` |

**Agent Path**: `agentic_architect/LLD_Architect_Agent.md`

---

## Workers

| # | Worker | Task | Status | Output |
|---|--------|------|--------|--------|
| 1 | worker-1-lld-structure | Create LLD document structure | ⏳ PENDING | `lld_structure.md` |
| 2 | worker-2-database-design | Design DynamoDB schema and access patterns | ⏳ PENDING | `database_design.md` |
| 3 | worker-3-api-contracts | Define detailed API contracts | ⏳ PENDING | `api_contracts.md` |
| 4 | worker-4-lld-consolidation | Consolidate into complete LLD | ⏳ PENDING | `LLD_{number}.md` |

---

## Worker Instructions

### Worker 1: LLD Structure

**Objective**: Create LLD document structure and introduction sections

**Inputs**:
- `HLD_{number}.md` from Stage 2
- `requirements.md` from Stage 1

**Deliverables**:
- `lld_structure.md` with:
  - Document information
  - Executive summary
  - Reference to parent HLD
  - Scope of implementation
  - Component overview

**Quality Criteria**:
- [ ] Clear traceability to HLD
- [ ] Scope well-defined
- [ ] No ambiguous terms

---

### Worker 2: Database Design

**Objective**: Design DynamoDB tables using single-table design

**Inputs**:
- HLD document
- `api_spec.md` from Stage 1

**Skill Reference**: Apply `DynamoDB_Single_Table.skill.md`

**Deliverables**:
- `database_design.md` with:
  - Table schema (PK, SK patterns)
  - GSI definitions
  - Access patterns
  - Entity relationships
  - Sample data examples

**Quality Criteria**:
- [ ] Single-table design applied
- [ ] All access patterns documented
- [ ] GSI usage justified
- [ ] On-demand billing mode specified

---

### Worker 3: API Contracts

**Objective**: Define detailed API request/response contracts

**Inputs**:
- `api_spec.md` from Stage 1
- HLD document

**Skill Reference**: Apply `HATEOAS_Relational_Design.skill.md`

**Deliverables**:
- `api_contracts.md` with:
  - OpenAPI specification
  - Request schemas (Pydantic models)
  - Response schemas
  - Error response formats
  - Validation rules
  - Example payloads

**Quality Criteria**:
- [ ] All endpoints fully specified
- [ ] Validation rules complete
- [ ] Error codes documented
- [ ] Examples provided

---

### Worker 4: LLD Consolidation

**Objective**: Create complete LLD document

**Inputs**:
- All previous worker outputs

**Deliverables**:
- `LLD_{parent_hld}_{number}_{name}.md` with:
  - Complete LLD following template
  - Class diagrams (Mermaid)
  - Sequence diagrams
  - Component specifications
  - Lambda handler specifications
  - Service layer design
  - Repository pattern design

**Naming Convention**: `2.1.X_LLD_{Service_Name}.md`
- Example: `2.1.5_LLD_Order_Lambda.md`

**Quality Criteria**:
- [ ] All sections complete
- [ ] Diagrams accurate
- [ ] Ready for implementation
- [ ] Testable specifications

---

## Stage Outputs

| Output | Description | Location |
|--------|-------------|----------|
| `LLD_{number}_{name}.md` | Complete LLD document | `2_bbws_docs/LLDs/` |
| OpenAPI spec | API contract definition | Within LLD or separate file |

---

## Approval Gate 1

**Location**: After this stage
**Approvers**: Tech Lead, Solutions Architect
**Criteria**:
- [ ] HLD and LLD complete
- [ ] Architecture sound
- [ ] Implementation feasible
- [ ] No technical debt introduced

---

## Success Criteria

- [ ] All 4 workers completed
- [ ] LLD document complete
- [ ] Database design reviewed
- [ ] API contracts finalized
- [ ] Gate 1 approval obtained

---

## Dependencies

**Depends On**: Stage 2 (HLD)
**Blocks**: Stage 4 (API Tests)

---

## Estimated Duration

| Activity | Agentic | Manual |
|----------|---------|--------|
| LLD structure | 10 min | 30 min |
| Database design | 20 min | 2 hours |
| API contracts | 20 min | 1.5 hours |
| Consolidation | 15 min | 1 hour |
| **Total** | **65 min** | **5 hours** |

---

**Navigation**: [← Stage 2](./stage-2-hld.md) | [Main Plan](./main-plan.md) | [Stage 4: API Tests →](./stage-4-api-tests.md)
