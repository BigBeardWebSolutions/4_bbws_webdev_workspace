# Stage 2: HLD Creation

**Parent Plan**: [BBWS SDLC Main Plan](./main-plan.md)
**Stage**: 2 of 10
**Status**: ⏳ PENDING
**Last Updated**: 2026-01-01

---

## Objective

Create a High-Level Design (HLD) document that defines the system architecture, component interactions, and technology decisions for the new microservice.

---

## Agent & Skill Assignment

| Role | Agent | Skill |
|------|-------|-------|
| **Primary** | HLD_Architect_Agent | `hld_architect.skill.md` |
| **Template** | - | `HLD_TEMPLATE.md` |

**Agent Path**: `agentic_architect/HLD_Architect_Agent.md`
**Skill Path**: `content/skills/hld_architect.skill.md`
**Template Path**: `content/skills/HLD_TEMPLATE.md`

---

## Workers

| # | Worker | Task | Status | Output |
|---|--------|------|--------|--------|
| 1 | worker-1-hld-structure | Create HLD document structure and introduction | ⏳ PENDING | `hld_intro.md` |
| 2 | worker-2-architecture-diagrams | Create system and component architecture diagrams | ⏳ PENDING | `architecture_diagrams.md` |
| 3 | worker-3-hld-consolidation | Consolidate into complete HLD document | ⏳ PENDING | `HLD_{number}.md` |

---

## Worker Instructions

### Worker 1: HLD Structure & Introduction

**Objective**: Create HLD document structure following template

**Inputs**:
- `requirements.md` from Stage 1
- `HLD_TEMPLATE.md`
- Existing HLDs for reference

**Deliverables**:
- `hld_intro.md` with:
  - Document information (version, dates, authors)
  - Executive summary
  - Business context
  - Scope and objectives
  - Stakeholders and their concerns
  - Constraints and assumptions

**Quality Criteria**:
- [ ] Follows HLD template structure
- [ ] Business context clearly articulated
- [ ] All stakeholders identified
- [ ] Constraints documented

**Skill Reference**: Use `hld_architect.skill.md` for guided interview approach

---

### Worker 2: Architecture Diagrams

**Objective**: Create visual representations of system architecture

**Inputs**:
- `requirements.md` from Stage 1
- `api_spec.md` from Stage 1

**Deliverables**:
- `architecture_diagrams.md` with:
  - System context diagram (C4 Level 1)
  - Container diagram (C4 Level 2)
  - Component diagram (C4 Level 3)
  - Data flow diagrams
  - Integration patterns

**Diagram Format**: Mermaid syntax

**Quality Criteria**:
- [ ] All major components represented
- [ ] Integration points clear
- [ ] Data flows documented
- [ ] AWS services identified

---

### Worker 3: HLD Consolidation

**Objective**: Consolidate all inputs into complete HLD document

**Inputs**:
- `hld_intro.md` from Worker 1
- `architecture_diagrams.md` from Worker 2
- `requirements.md` from Stage 1

**Deliverables**:
- `HLD_{number}_{service_name}.md` with:
  - Full HLD document following template
  - Technology stack decisions
  - Security architecture
  - Scalability considerations
  - Deployment architecture
  - Risk assessment

**Naming Convention**: Follow `HLD_LLD_Naming_Convention.skill.md`
- Example: `3.2_HLD_Product_Lambda.md`

**Quality Criteria**:
- [ ] All HLD template sections complete
- [ ] Architecture decisions justified
- [ ] No placeholder content
- [ ] Ready for LLD decomposition

---

## Stage Outputs

| Output | Description | Location |
|--------|-------------|----------|
| `HLD_{number}_{name}.md` | Complete HLD document | `2_bbws_docs/HLDs/` |
| Architecture diagrams | Mermaid diagrams embedded | Within HLD document |

---

## Success Criteria

- [ ] All 3 workers completed
- [ ] HLD document complete (no placeholders)
- [ ] Architecture diagrams clear and accurate
- [ ] Technology decisions documented
- [ ] Ready for LLD creation

---

## Dependencies

**Depends On**: Stage 1 (Requirements)
**Blocks**: Stage 3 (LLD Creation)

---

## Estimated Duration

| Activity | Agentic | Manual |
|----------|---------|--------|
| HLD structure | 15 min | 1 hour |
| Architecture diagrams | 20 min | 2 hours |
| Consolidation | 15 min | 1 hour |
| **Total** | **50 min** | **4 hours** |

---

**Navigation**: [← Stage 1](./stage-1-requirements.md) | [Main Plan](./main-plan.md) | [Stage 3: LLD →](./stage-3-lld.md)
