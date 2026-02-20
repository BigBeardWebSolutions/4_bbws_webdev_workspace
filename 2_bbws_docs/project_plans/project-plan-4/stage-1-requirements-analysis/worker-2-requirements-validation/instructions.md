# Worker Instructions: Requirements Validation

**Worker ID**: worker-2-requirements-validation
**Stage**: Stage 1 - Requirements & Analysis
**Project**: project-plan-4 (Marketing Lambda Implementation)

---

## Task Description

Validate all functional and technical requirements from the Marketing Lambda LLD against global standards (CLAUDE.md), ensure completeness, identify any gaps, and create a requirements validation matrix.

---

## Inputs

- Worker 1 output: `worker-1-lld-analysis/output.md`
- Marketing Lambda LLD: `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/2.1.3_LLD_Marketing_Lambda.md`
- Global CLAUDE.md: `/Users/tebogotseka/.claude/CLAUDE.md`
- Project CLAUDE.md: `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/CLAUDE.md`

---

## Deliverables

- `output.md` containing:
  1. Functional Requirements Validation
  2. Technical Requirements Validation
  3. Compliance Checklist (against CLAUDE.md standards)
  4. Gap Analysis
  5. Recommendations

---

## Expected Output Format

```markdown
# Requirements Validation Output

## 1. Functional Requirements

| Requirement ID | Description | Source | Status | Notes |
|----------------|-------------|--------|--------|-------|
| FR-001 | Get campaign by code | US-MKT-001 | ✅ Valid | GET /v1.0/campaigns/{code} |
| FR-002 | Return campaign status | US-MKT-002 | ✅ Valid | DRAFT, ACTIVE, EXPIRED |
| FR-003 | Calculate discount price | US-MKT-003 | ✅ Valid | price = listPrice * (1 - discountPercent/100) |

## 2. Technical Requirements

| Requirement ID | Description | LLD Section | Status | Notes |
|----------------|-------------|-------------|--------|-------|
| TR-001 | Python 3.12 runtime | 1.2 | ✅ Valid | Latest supported |
| TR-002 | arm64 architecture | 1.2 | ✅ Valid | Cost-effective |
| TR-003 | 256MB memory | 1.2 | ✅ Valid | Sufficient for task |
| TR-004 | 30s timeout | 1.2 | ✅ Valid | API call |
| TR-005 | OOP design | 3 | ✅ Valid | Service/Repository/Model layers |
| TR-006 | TDD approach | - | ⚠️ Implied | Must be explicit |
| TR-007 | 80%+ test coverage | - | ⚠️ Missing | Add requirement |
| TR-008 | Pydantic models | 5.2 | ✅ Valid | Data validation |
| TR-009 | DynamoDB access | 5.1 | ✅ Valid | Single-table design |

## 3. Compliance Checklist

### Global CLAUDE.md Standards
- [ ] TBT mechanism followed
- [ ] Multi-environment support (DEV, SIT, PROD)
- [ ] Parameterized configurations (no hardcoding)
- [ ] Test-driven development (TDD)
- [ ] Object-oriented programming (OOP)
- [ ] Microservices architecture
- [ ] CloudWatch monitoring
- [ ] DynamoDB on-demand capacity
- [ ] S3 public access blocked
- [ ] Disaster recovery strategy

### Project CLAUDE.md Standards
- [ ] Separate Terraform modules per service
- [ ] OpenAPI 3.0 specification
- [ ] Repository naming: `2_bbws_marketing_lambda`
- [ ] GitHub Actions workflows
- [ ] Deployment flow: DEV→SIT→PROD
- [ ] Human approval for SIT and PROD

## 4. Gap Analysis

| Gap ID | Description | Impact | Recommendation |
|--------|-------------|--------|----------------|
| GAP-001 | No explicit TDD requirement | Medium | Add TDD requirement to implementation |
| GAP-002 | Missing test coverage target | Medium | Specify 80%+ coverage requirement |
| GAP-003 | No integration test specification | Low | Add integration test requirements |
| GAP-004 | No E2E test specification | Low | Add E2E test requirements |
| GAP-005 | No CloudWatch monitoring spec | High | Add monitoring requirements |
| GAP-006 | No SNS alerting spec | High | Add alerting requirements |

## 5. Recommendations

1. **Add Explicit TDD Requirement**: Specify that all code must follow TDD
2. **Define Test Coverage Target**: 80%+ for unit tests
3. **Add Monitoring Requirements**: CloudWatch dashboards and alarms
4. **Add Alerting Requirements**: SNS topics for failed transactions
5. **Add Integration Tests**: Test Lambda + DynamoDB integration
6. **Add E2E Tests**: Test full API Gateway → Lambda → DynamoDB flow

## 6. Validation Summary

- **Functional Requirements**: 3/3 valid (100%)
- **Technical Requirements**: 7/9 valid (78%)
- **Compliance**: 8/16 requirements met (50%)
- **Gaps Identified**: 6
- **Overall Status**: ⚠️ Requires enhancements before implementation
```

---

## Success Criteria

- [ ] All functional requirements from user stories validated
- [ ] All technical requirements from LLD extracted
- [ ] Compliance against global CLAUDE.md checked
- [ ] Compliance against project CLAUDE.md checked
- [ ] All gaps identified and documented
- [ ] Recommendations provided for each gap
- [ ] Validation matrix created
- [ ] Output.md created with all sections

---

## Execution Steps

1. Read worker-1 output for extracted requirements
2. Read Marketing Lambda LLD sections 1-7
3. Review global CLAUDE.md for standards
4. Review project CLAUDE.md for project-specific standards
5. Create functional requirements validation matrix
6. Create technical requirements validation matrix
7. Check compliance against all CLAUDE.md standards
8. Identify gaps and missing requirements
9. Provide recommendations for each gap
10. Create validation summary
11. Create output.md with all findings
12. Update work.state to COMPLETE

---

## Key Standards to Validate

### From Global CLAUDE.md
- TBT mechanism compliance
- Multi-environment support (3 environments)
- No hardcoded credentials
- TDD approach
- OOP principles
- Microservices architecture
- CloudWatch monitoring and alerting
- SNS notifications for failures
- DynamoDB on-demand capacity
- S3 public access blocked

### From Project CLAUDE.md (LLDs/)
- Separate Terraform modules (not monolithic)
- OpenAPI YAML per service
- Repository naming convention
- GitHub Actions workflows
- Approval gates for SIT/PROD
- Test coverage requirements

---

**Created**: 2025-12-30
