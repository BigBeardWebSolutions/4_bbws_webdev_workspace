# Worker Instructions: LLD Analysis

**Worker ID**: worker-1-lld-analysis
**Stage**: Stage 1 - Requirements & Analysis
**Project**: project-plan-4 (Marketing Lambda Implementation)

---

## Task Description

Thoroughly analyze the Marketing Lambda LLD document (2.1.3_LLD_Marketing_Lambda.md) and extract all technical specifications, component diagrams, sequence diagrams, data models, and infrastructure requirements needed for implementation.

---

## Inputs

- Marketing Lambda LLD: `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/2.1.3_LLD_Marketing_Lambda.md`
- Customer Portal Public HLD v1.1: `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/HLDs/2.1_BBWS_Customer_Portal_Public_HLD_V1.1.md`

---

## Deliverables

- `output.md` containing:
  1. Component Overview Summary
  2. Lambda Function Specifications
  3. Component Diagram Analysis
  4. Sequence Diagram Analysis
  5. Data Model Extraction
  6. Infrastructure Requirements
  7. Testing Requirements
  8. Implementation Checklist

---

## Expected Output Format

```markdown
# LLD Analysis Output

## 1. Component Overview

| Attribute | Value |
|-----------|-------|
| Repository | ... |
| Runtime | ... |
| Memory | ... |
| Timeout | ... |
| Architecture | ... |

### Lambda Functions
(Extract from LLD section 1.3)

## 2. User Stories

(Extract from LLD section 2)

## 3. Component Diagram

(Extract class diagram from LLD section 3)

### Classes Identified
- CampaignHandler
- CampaignService
- CampaignRepository
- Campaign (model)
- CampaignStatus (enum)
- Exceptions

## 4. Sequence Diagrams

(Extract from LLD section 4)

### Get Campaign Flow
- Main flow
- Error handling flows

## 5. Data Models

### DynamoDB Schema
(Extract from LLD section 5.1)

### Pydantic Models
(Extract from LLD section 5.2)

## 6. Infrastructure Requirements

### Lambda Configuration
- Runtime: ...
- Memory: ...
- Timeout: ...
- Environment Variables: ...

### DynamoDB Table Reference
- Table name pattern: ...
- Access pattern: ...

## 7. Testing Requirements

### NFRs
(Extract from LLD section 7)

### Test Coverage
- Unit tests
- Integration tests
- E2E tests

## 8. Implementation Checklist

- [ ] Handler layer (get_campaign.py)
- [ ] Service layer (campaign_service.py)
- [ ] Repository layer (campaign_repository.py)
- [ ] Model layer (campaign.py)
- [ ] Exceptions (campaign_exceptions.py)
- [ ] Unit tests
- [ ] Integration tests
- [ ] Terraform modules
- [ ] CI/CD pipelines
```

---

## Success Criteria

- [ ] All component attributes extracted from LLD section 1.2
- [ ] All user stories extracted from LLD section 2
- [ ] Component diagram analyzed with all classes identified
- [ ] Sequence diagram flows documented
- [ ] DynamoDB schema extracted from section 5.1
- [ ] Pydantic models extracted from section 5.2
- [ ] Infrastructure requirements documented
- [ ] NFRs documented from section 7
- [ ] Project structure from LLD section 15 documented
- [ ] Implementation checklist created
- [ ] Output.md created with all sections

---

## Execution Steps

1. Read the Marketing Lambda LLD document thoroughly
2. Extract component overview (section 1)
3. Extract and document user stories (section 2)
4. Analyze component diagram (section 3)
5. Analyze sequence diagrams (section 4)
6. Extract data models (section 5)
7. Document infrastructure requirements
8. Extract NFRs (section 7)
9. Create implementation checklist
10. Create output.md with all findings
11. Update work.state to COMPLETE

---

## Key LLD Sections to Review

- **Section 1**: Introduction and Component Overview
- **Section 2**: User Stories (US-MKT-001, US-MKT-002, US-MKT-003)
- **Section 3**: Component Diagram (Mermaid classDiagram)
- **Section 4**: Sequence Diagrams (Get Campaign Flow)
- **Section 5**: Data Models (DynamoDB schema, Pydantic models)
- **Section 7**: NFRs (latency, cold start, cache hit ratio)
- **Section 15**: Project Structure (Appendices)

---

**Created**: 2025-12-30
