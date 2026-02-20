# Stage 3: OpenAPI & Tests

**Stage ID**: stage-3-openapi-tests
**Parent Project**: Site Builder Bedrock Generation API (project-plan-2)
**Status**: PENDING
**Created**: 2026-01-15

---

## Stage Overview

**Objective**: Write OpenAPI specifications for all API endpoints and define comprehensive unit test cases following TDD approach.

**Dependencies**: Stage 2 complete (Gate 2 approved)

**Deliverables**:
1. OpenAPI 3.0 YAML specifications (separate files per microservice)
2. Unit test case definitions
3. Mock data for testing
4. Test coverage requirements

**Expected Duration**:
- Agentic: 45-60 minutes
- Manual: 3-4 days

---

## Workers

| Worker | Name | Status | Description |
|--------|------|--------|-------------|
| 1 | OpenAPI Generation | PENDING | OpenAPI spec for generation endpoints |
| 2 | OpenAPI Agents | PENDING | OpenAPI spec for agent endpoints |
| 3 | OpenAPI Validation | PENDING | OpenAPI spec for validation endpoints |
| 4 | Test Cases | PENDING | Define unit test cases for all Lambdas |
| 5 | Mock Data | PENDING | Create mock data and test fixtures |

---

## Worker Definitions

### Worker 1: OpenAPI Generation

**Objective**: Create OpenAPI 3.0 specification for the page generation API endpoints including SSE streaming.

**Input Files**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/3.1.2_LLD_Site_Builder_Bedrock_Generation_API.md`
- `stage-1-requirements-analysis/outputs/api_contracts.md`

**Tasks**:
1. Define OpenAPI 3.0 header (info, servers, security)
2. Define generation endpoint schemas
3. Document SSE response format
4. Define request/response schemas
5. Document error responses
6. Add examples for each endpoint

**Output Requirements**:
- Create: `openapi/generation-api.yaml`
- Structure:
  ```yaml
  openapi: 3.0.3
  info:
    title: Site Builder Generation API
    version: 1.0.0
  servers:
    - url: https://api.dev.kimmyai.io/v1
      description: DEV
    - url: https://api.sit.kimmyai.io/v1
      description: SIT
    - url: https://api.kimmyai.io/v1
      description: PROD
  security:
    - bearerAuth: []
  paths:
    /sites/{tenant_id}/generation:
      post:
        summary: Start page generation with streaming
        ...
  components:
    schemas:
      GenerationRequest:
        ...
    securitySchemes:
      bearerAuth:
        type: http
        scheme: bearer
        bearerFormat: JWT
  ```

**Success Criteria**:
- Valid OpenAPI 3.0 specification
- All generation endpoints documented
- SSE streaming documented
- Request/response schemas complete
- Examples provided

---

### Worker 2: OpenAPI Agents

**Objective**: Create OpenAPI 3.0 specification for all AI agent endpoints (logo, background, theme, layout).

**Input Files**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/3.1.2_LLD_Site_Builder_Bedrock_Generation_API.md`
- `stage-1-requirements-analysis/outputs/api_contracts.md`

**Tasks**:
1. Define logo generation endpoint
2. Define background generation endpoint
3. Define theme suggestion endpoint
4. Define layout generation endpoint
5. Define blog content endpoint
6. Define newsletter endpoint
7. Document all request/response schemas

**Output Requirements**:
- Create: `openapi/agents-api.yaml`
- Endpoints:
  - POST /agents/logo
  - POST /agents/background
  - POST /agents/theme
  - POST /agents/layout
  - POST /agents/blog
  - POST /agents/newsletter

**Success Criteria**:
- All 6 agent endpoints documented
- Request schemas with validation
- Response schemas with image URLs
- Examples for each endpoint

---

### Worker 3: OpenAPI Validation

**Objective**: Create OpenAPI 3.0 specification for brand validation and scoring endpoints.

**Input Files**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/3.1.2_LLD_Site_Builder_Bedrock_Generation_API.md`
- `stage-1-requirements-analysis/outputs/api_contracts.md`

**Tasks**:
1. Define validation endpoint
2. Define brand score endpoint
3. Document scoring categories
4. Define validation issue schema
5. Document threshold values

**Output Requirements**:
- Create: `openapi/validation-api.yaml`
- Endpoints:
  - GET /sites/{id}/validate
  - GET /sites/{id}/brand-score

**Success Criteria**:
- Validation endpoints documented
- Scoring categories defined
- Issue severity levels documented
- Threshold values specified (8/10 minimum)

---

### Worker 4: Test Cases

**Objective**: Define comprehensive unit test cases for all Lambda functions following TDD principles.

**Input Files**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/3.1.2_LLD_Site_Builder_Bedrock_Generation_API.md`
- `openapi/generation-api.yaml`
- `openapi/agents-api.yaml`
- `openapi/validation-api.yaml`

**Tasks**:
1. Define test cases for page generator
   - Valid prompt processing
   - Streaming buffer management
   - Error handling
2. Define test cases for logo creator
   - SD XL request formatting
   - Image processing
   - S3 upload
3. Define test cases for brand validator
   - Scoring algorithm
   - Threshold enforcement
   - Issue categorization
4. Define test cases for generation state
   - DynamoDB operations
   - State transitions
5. Document expected coverage targets

**Output Requirements**:
- Create: `tests/test_cases.md`
- Structure:
  ```markdown
  # Test Cases - Site Builder Bedrock Generation API

  ## Page Generator Tests
  ### TC-PG-001: Valid prompt generates HTML
  **Given**: Valid generation request
  **When**: POST /generation called
  **Then**: SSE stream returns HTML chunks

  ### TC-PG-002: Invalid prompt returns error
  ...

  ## Logo Creator Tests
  ...

  ## Brand Validator Tests
  ...

  ## Coverage Targets
  - Unit: 80% minimum
  - Integration: 70% minimum
  - Critical paths: 100%
  ```

**Success Criteria**:
- Test cases for all Lambda functions
- Positive and negative test scenarios
- Edge cases identified
- Coverage targets defined

---

### Worker 5: Mock Data

**Objective**: Create mock data and test fixtures for unit and integration testing.

**Input Files**:
- `openapi/generation-api.yaml`
- `openapi/agents-api.yaml`
- `openapi/validation-api.yaml`
- `tests/test_cases.md`

**Tasks**:
1. Create mock Bedrock responses (Claude)
2. Create mock Bedrock responses (Stable Diffusion XL)
3. Create mock DynamoDB items
4. Create mock S3 objects
5. Create sample request payloads
6. Create sample response payloads

**Output Requirements**:
- Create: `tests/fixtures/mock_bedrock_responses.py`
- Create: `tests/fixtures/test_data.py`
- Structure:
  ```python
  # mock_bedrock_responses.py
  CLAUDE_GENERATION_RESPONSE = {
      "content": [
          {"type": "text", "text": "<!DOCTYPE html>..."}
      ],
      "usage": {"input_tokens": 100, "output_tokens": 500}
  }

  SD_XL_IMAGE_RESPONSE = {
      "images": [{"base64": "..."}]
  }

  # test_data.py
  VALID_GENERATION_REQUEST = {
      "prompt": "Create a landing page...",
      "templateId": "ecommerce-sale",
      "brandAssets": {...}
  }
  ```

**Success Criteria**:
- Mock responses for all Bedrock calls
- Sample data for all request types
- DynamoDB fixtures for state tests
- S3 fixtures for upload tests

---

## Stage Completion Criteria

The stage is considered **COMPLETE** when:

1. All 5 workers have completed their outputs
2. Three OpenAPI files created:
   - `openapi/generation-api.yaml`
   - `openapi/agents-api.yaml`
   - `openapi/validation-api.yaml`
3. Test cases document complete
4. Mock data files created
5. OpenAPI specs validate against OpenAPI 3.0

---

## Validation

**OpenAPI Validation Command**:
```bash
# Validate OpenAPI specs
npx @redocly/cli lint openapi/generation-api.yaml
npx @redocly/cli lint openapi/agents-api.yaml
npx @redocly/cli lint openapi/validation-api.yaml
```

---

**Stage Owner**: Agentic Project Manager
**Created**: 2026-01-15
**Next Action**: Wait for Stage 2 completion and Gate 2 approval
