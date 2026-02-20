# Worker Instructions: HLD Validation

**Worker ID**: worker-1-hld-validation
**Stage**: Stage 1 - Requirements Validation
**Project**: project-plan-site-builder

---

## Task

Validate the BBWS Site Builder HLD v3.1 document for completeness, consistency, and implementation readiness. Ensure all architectural components, data flows, and regional configurations are properly documented.

---

## Inputs

**Primary Input**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/HLDs/BBSW_Site_Builder_HLD_v3.md`

**Supporting Inputs**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/BRS/BBWS_Site_Builder_BRS_v1.md`

---

## Deliverables

Create `output.md` with the following sections:

### 1. Epic Validation

Validate all 9 epics are documented:

| Epic | Name | User Stories | Validated |
|------|------|--------------|-----------|
| 1 | AI Page Generation | US-001, US-002 | Yes/No |
| 2 | Iterative Refinement | US-003, US-004 | Yes/No |
| 3 | Quality & Validation | US-005, US-006 | Yes/No |
| 4 | Deployment | US-007, US-008 | Yes/No |
| 5 | Analytics & Optimization | US-009, US-010 | Yes/No |
| 6 | Site Designer | US-011-014, US-022-024 | Yes/No |
| 7 | Tenant Management | US-015-018 | Yes/No |
| 8 | Site Migration | US-019-021 | Yes/No |
| 9 | White-Label & Marketplace | US-025-028 | Yes/No |

### 2. Architecture Component Validation

Validate all 45 components across regions:

**af-south-1 Components (22)**:
- [ ] API Gateway
- [ ] WAF
- [ ] Cognito User Pool
- [ ] Lambda Request Router
- [ ] Lambda Response Handler
- [ ] Lambda Tenant Service
- [ ] Lambda User Service
- [ ] Lambda Site Service
- [ ] Lambda Deployment Service
- [ ] Lambda Analytics Service
- [ ] DynamoDB Tenants
- [ ] DynamoDB Users
- [ ] DynamoDB Sites
- [ ] DynamoDB Generations
- [ ] DynamoDB Templates
- [ ] S3 Brand Assets
- [ ] S3 Generated Sites
- [ ] S3 Staging
- [ ] CloudFront CDN
- [ ] Route 53
- [ ] EventBridge
- [ ] CloudWatch

**eu-west-1 Components (19)**:
- [ ] AgentCore Runtime
- [ ] AgentCore Gateway
- [ ] AgentCore Identity
- [ ] AgentCore Policy
- [ ] AgentCore Memory
- [ ] AgentCore Observability
- [ ] AgentCore Evaluations
- [ ] Agent Site Generator
- [ ] Agent Outliner
- [ ] Agent Theme Selector
- [ ] Agent Layout
- [ ] Agent Logo Creator
- [ ] Agent Background Image
- [ ] Agent Blogger
- [ ] Agent Validator
- [ ] Bedrock Claude Sonnet 4.5
- [ ] Bedrock Claude Haiku
- [ ] Bedrock SD XL
- [ ] EventBridge

**Global Components (4)**:
- [ ] Route 53 Hosted Zones
- [ ] WAF Web ACL
- [ ] Secrets Manager
- [ ] IAM Roles/Policies

### 3. Data Flow Validation

Validate data residency compliance:

| Data Type | Region | Documented |
|-----------|--------|------------|
| Customer PII | af-south-1 only | Yes/No |
| User credentials | af-south-1 | Yes/No |
| Tenant configurations | af-south-1 | Yes/No |
| Brand assets | af-south-1 | Yes/No |
| Generated sites | af-south-1 | Yes/No |
| Prompts (anonymized) | Traverses to eu-west-1 | Yes/No |
| Generated content | Returns to af-south-1 | Yes/No |

### 4. API Design Validation

Validate HATEOAS compliance:

- [ ] Entry point documented (`/v1/`)
- [ ] Resource hierarchy documented
- [ ] `_links` structure defined
- [ ] Pagination patterns documented
- [ ] Error response format defined

### 5. TBC Review

List all open TBCs:

| TBC ID | Category | Description | Impact | Priority |
|--------|----------|-------------|--------|----------|
| TBC-001 | Legal | POPIA compliance for prompt transit | High | High |
| TBC-003 | Product | Fallback when AgentCore unavailable | Medium | Medium |
| TBC-004 | Security | AgentCore Memory retention policy | Low | Low |
| TBC-005 | Commercial | AWS Marketplace metering dimensions | Medium | Medium |

### 6. Gaps and Issues

Document any gaps or inconsistencies found:

| ID | Description | Severity | Recommendation |
|----|-------------|----------|----------------|
| GAP-001 | ... | Critical/High/Medium/Low | ... |

---

## Expected Output Format

```markdown
# HLD Validation Output

## 1. Epic Validation

| Epic | Name | User Stories | Validated | Notes |
|------|------|--------------|-----------|-------|
| 1 | AI Page Generation | US-001, US-002 | Yes | All scenarios documented |
...

## 2. Architecture Component Validation

### af-south-1 (22/22 validated)
- [x] API Gateway - Documented in Section 3.4
...

### eu-west-1 (19/19 validated)
...

### Global (4/4 validated)
...

## 3. Data Flow Validation

| Data Type | Region | Documented | Notes |
|-----------|--------|------------|-------|
...

## 4. API Design Validation

- [x] Entry point documented
...

## 5. TBC Review

| TBC ID | Category | Description | Impact | Blocker? |
|--------|----------|-------------|--------|----------|
...

## 6. Gaps and Issues

| ID | Description | Severity | Recommendation |
|----|-------------|----------|----------------|
...

## Summary

- Total Components: 45
- Validated: XX/45
- Gaps Found: X
- Blocking Issues: X
- Ready for Stage 2: Yes/No
```

---

## Success Criteria

- [ ] All 9 epics validated
- [ ] All 45 components validated
- [ ] Data flow compliance confirmed
- [ ] HATEOAS design validated
- [ ] All TBCs reviewed and prioritized
- [ ] Gaps documented with recommendations
- [ ] Summary includes Stage 2 readiness assessment

---

## Execution Steps

1. Read HLD v3.1 document completely
2. Validate each epic against Section 2
3. Check all 45 components against Section 6
4. Verify data flow against Section 7
5. Validate API design against Section 5
6. Review TBCs in Appendix A
7. Document any gaps found
8. Create output.md with all sections
9. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-16
