# Worker Instructions: Generation API LLD Validation

**Worker ID**: worker-4-lld-api-validation
**Stage**: Stage 1 - Requirements Validation
**Project**: project-plan-site-builder

---

## Task

Validate the Site Builder Generation API LLD v1.3 document for completeness. Ensure all API endpoints, data models, and DynamoDB tables are documented and mapped to user stories.

---

## Inputs

**Primary Input**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/3.1.2_LLD_Site_Builder_Generation_API.md`

**Supporting Inputs**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/BRS/BBWS_Site_Builder_BRS_v1.md`
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/HLDs/BBSW_Site_Builder_HLD_v3.md`

---

## Deliverables

Create `output.md` with the following sections:

### 1. API Endpoint Validation

Validate all endpoints are documented with OpenAPI spec:

**Generation Endpoints**:
| Endpoint | Method | User Story | HATEOAS | Documented |
|----------|--------|------------|---------|------------|
| `/sites/{tenant_id}/generation` | POST | US-001 | Yes/No | Yes/No |
| `/sites/{tenant_id}/generation/{id}/advisor` | POST | US-003 | Yes/No | Yes/No |
| `/sites/{tenant_id}/files` | GET, POST | US-001 | Yes/No | Yes/No |
| `/sites/{tenant_id}/deployments` | GET, POST | US-007 | Yes/No | Yes/No |

**Agent Endpoints**:
| Endpoint | Method | User Story | AI Model | Documented |
|----------|--------|------------|----------|------------|
| `/agents/logo` | POST | US-011 | SD XL | Yes/No |
| `/agents/background` | POST | US-012 | SD XL | Yes/No |
| `/agents/theme` | POST | US-013 | Claude | Yes/No |
| `/agents/layout` | POST | US-023 | Claude | Yes/No |
| `/agents/blog` | POST | US-022 | Claude | Yes/No |
| `/agents/newsletter` | POST | US-024 | Claude | Yes/No |

**Validation Endpoints**:
| Endpoint | Method | User Story | Documented |
|----------|--------|------------|------------|
| `/sites/{id}/validate` | GET | US-005 | Yes/No |
| `/sites/{id}/validate/brand` | GET | US-005 | Yes/No |
| `/sites/{id}/validate/security` | GET | US-006 | Yes/No |
| `/sites/{id}/validate/auto-fix` | POST | US-005 | Yes/No |

**Partner Endpoints**:
| Endpoint | Method | User Story | Documented |
|----------|--------|------------|------------|
| `/partners/{id}` | GET | US-025 | Yes/No |
| `/partners/{id}/branding` | GET, PUT | US-025 | Yes/No |
| `/partners/{id}/domain` | POST | US-025 | Yes/No |
| `/partners/{id}/tenants` | GET, POST | US-026 | Yes/No |
| `/partners/{id}/subscription` | GET, PUT | US-027 | Yes/No |
| `/partners/{id}/billing` | GET | US-028 | Yes/No |

### 2. OpenAPI Schema Validation

Validate all schemas are defined:

| Schema | Properties | Required Fields | Documented |
|--------|------------|-----------------|------------|
| GenerationRequest | prompt, template_id, sections | prompt | Yes/No |
| GenerationResponse | generation_id, status, html, css, brand_score | all | Yes/No |
| AgentRequest | type, prompt, options | type, prompt | Yes/No |
| AgentResponse | agent_id, type, results | all | Yes/No |
| ValidationResult | validation_id, overall_score, issues | all | Yes/No |
| BrandConfig | company_name, colors, fonts | colors | Yes/No |
| PartnerBranding | logo_url, colors, domain | colors | Yes/No |

### 3. DynamoDB Table Validation

Validate all tables are documented:

| Table | PK | SK | GSI | User Stories | Documented |
|-------|----|----|-----|--------------|------------|
| Tenants | TENANT#{id} | METADATA | email-index | US-015 | Yes/No |
| Users | USER#{id} | METADATA | tenant-index, email-index | US-016-018 | Yes/No |
| Sites | SITE#{id} | METADATA | tenant-index | US-001, US-007 | Yes/No |
| Generations | GEN#{id} | METADATA | tenant-index, site-index | US-001-003 | Yes/No |
| Templates | TPL#{id} | METADATA | tenant-index | US-002 | Yes/No |
| Partners | PARTNER#{id} | METADATA | - | US-025-028 | Yes/No |

### 4. S3 Bucket Validation

Validate all S3 buckets are documented:

| Bucket | Purpose | Public Access | User Stories | Documented |
|--------|---------|---------------|--------------|------------|
| bbws-brand-assets-{env} | Logo, images | BLOCKED | US-002 | Yes/No |
| bbws-generated-sites-{env} | Final HTML/CSS | BLOCKED | US-007 | Yes/No |
| bbws-staging-{env} | Pre-deploy staging | BLOCKED | US-007 | Yes/No |
| bbws-agent-personas-{env} | Agent prompts | BLOCKED | US-001 | Yes/No |

### 5. Lambda Function Validation

Validate all Lambda functions are documented:

| Function | Handler | User Stories | Documented |
|----------|---------|--------------|------------|
| generation-handler | generation.handler | US-001, US-003 | Yes/No |
| logo-agent-handler | agents/logo.handler | US-011 | Yes/No |
| background-agent-handler | agents/background.handler | US-012 | Yes/No |
| theme-agent-handler | agents/theme.handler | US-013 | Yes/No |
| layout-agent-handler | agents/layout.handler | US-023 | Yes/No |
| validation-handler | validation.handler | US-005, US-006 | Yes/No |
| deployment-handler | deployment.handler | US-007, US-008 | Yes/No |
| partner-handler | partner.handler | US-025-028 | Yes/No |

### 6. Error Handling Validation

Validate error handling is documented:

| Error Code | HTTP Status | Scenario | Documented |
|------------|-------------|----------|------------|
| INVALID_REQUEST | 400 | Malformed input | Yes/No |
| UNAUTHORIZED | 401 | Missing/invalid JWT | Yes/No |
| FORBIDDEN | 403 | Tenant mismatch | Yes/No |
| NOT_FOUND | 404 | Resource not found | Yes/No |
| RATE_LIMIT | 429 | Too many requests | Yes/No |
| GENERATION_FAILED | 500 | AI service failure | Yes/No |
| BEDROCK_UNAVAILABLE | 503 | Bedrock down | Yes/No |

### 7. Security Validation

Validate security controls are documented:

| Control | Implementation | User Stories | Documented |
|---------|----------------|--------------|------------|
| JWT Authentication | Cognito | All | Yes/No |
| Tenant Isolation | X-Tenant-Id header | All | Yes/No |
| Rate Limiting | API Gateway usage plans | All | Yes/No |
| Input Validation | Pydantic schemas | All | Yes/No |
| Prompt Injection | AgentCore Policy | US-006 | Yes/No |
| Content Moderation | Bedrock Guardrails | US-011, US-012 | Yes/No |

### 8. Gaps and Issues

| ID | Description | Severity | Recommendation |
|----|-------------|----------|----------------|
| GAP-001 | ... | Critical/High/Medium/Low | ... |

---

## Expected Output Format

```markdown
# Generation API LLD Validation Output

## 1. API Endpoint Validation

**Generation Endpoints**: X/X documented
**Agent Endpoints**: X/X documented
**Validation Endpoints**: X/X documented
**Partner Endpoints**: X/X documented

## 2. OpenAPI Schema Validation

**Schemas Defined**: X/X

## 3. DynamoDB Table Validation

**Tables Documented**: X/6

## 4. S3 Bucket Validation

**Buckets Documented**: X/4

## 5. Lambda Function Validation

**Functions Documented**: X/X

## 6. Error Handling Validation

**Error Codes Documented**: X/X

## 7. Security Validation

**Security Controls**: X/X

## 8. Gaps and Issues

| ID | Description | Severity |
|----|-------------|----------|
...

## Summary

- Total Endpoints: XX
- DynamoDB Tables: 6
- S3 Buckets: 4
- Lambda Functions: XX
- HATEOAS Compliant: Yes/No
- Ready for Stage 3: Yes/No
```

---

## Success Criteria

- [ ] All API endpoints documented with OpenAPI
- [ ] All schemas defined
- [ ] All DynamoDB tables documented
- [ ] All S3 buckets documented
- [ ] All Lambda functions documented
- [ ] Error handling documented
- [ ] Security controls documented
- [ ] Gaps documented

---

## Execution Steps

1. Read Generation API LLD v1.3 completely
2. Validate endpoints against Section 3
3. Validate schemas against OpenAPI spec
4. Validate DynamoDB tables against Section 6
5. Validate S3 buckets against Section 7
6. Validate Lambda functions
7. Check error handling against Section 12
8. Validate security controls against Section 11
9. Document gaps
10. Create output.md
11. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-16
