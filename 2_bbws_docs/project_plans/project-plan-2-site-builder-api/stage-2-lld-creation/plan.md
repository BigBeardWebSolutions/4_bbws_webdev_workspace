# Stage 2: LLD Creation

**Stage ID**: stage-2-lld-creation
**Parent Project**: Site Builder Bedrock Generation API (project-plan-2)
**Status**: PENDING
**Created**: 2026-01-15

---

## Stage Overview

**Objective**: Create comprehensive Low-Level Design document with class diagrams, sequence diagrams, data models, and architecture decisions.

**Dependencies**: Stage 1 complete (Gate 1 approved)

**Deliverables**:
1. 3.1.2_LLD_Site_Builder_Bedrock_Generation_API.md
2. Class diagrams for all Lambda functions
3. Sequence diagrams for all API flows
4. DynamoDB schema designs
5. S3 bucket structure documentation

**Expected Duration**:
- Agentic: 1-2 hours
- Manual: 5-7 days

---

## Workers

| Worker | Name | Status | Description |
|--------|------|--------|-------------|
| 1 | LLD Structure | PENDING | Create LLD document structure and introduction |
| 2 | Class Diagrams | PENDING | Design class diagrams for Lambda functions |
| 3 | Sequence Diagrams | PENDING | Create sequence diagrams for API flows |
| 4 | Data Models | PENDING | Define DynamoDB and S3 data models |
| 5 | Architecture | PENDING | Document architecture decisions and rationale |
| 6 | NFR Security | PENDING | Document NFRs and security requirements |

---

## Worker Definitions

### Worker 1: LLD Structure

**Objective**: Create the LLD document structure with introduction, table of contents, document control, and component overview.

**Input Files**:
- `stage-1-requirements-analysis/outputs/api_contracts.md`
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/HLDs/3.0_BBSW_Site_Builder_HLD.md`
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/3.1.1_LLD_Site_Builder_Frontend.md` (as template reference)

**Tasks**:
1. Create LLD document header with version, author, date, status
2. Write introduction section explaining component purpose
3. Create table of contents with all sections
4. Document component overview (repository, tech stack, AWS services)
5. Define relationship to parent HLD and sibling Frontend LLD
6. Create placeholder sections for other workers

**Output Requirements**:
- Create: `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/3.1.2_LLD_Site_Builder_Bedrock_Generation_API.md`
- Initial structure with placeholders for other workers

**Success Criteria**:
- Document header complete
- Introduction clear and comprehensive
- All section placeholders created
- Consistent formatting with Frontend LLD

---

### Worker 2: Class Diagrams

**Objective**: Design class diagrams for all Lambda functions using OOP principles, showing relationships between handlers, services, and models.

**Input Files**:
- `stage-1-requirements-analysis/outputs/api_contracts.md`
- `stage-1-requirements-analysis/outputs/hld_analysis.md`

**Tasks**:
1. Design PageGenerator class hierarchy (handler, generator, streaming)
2. Design AgentBase abstract class and concrete agents (Logo, Background, Theme, Layout)
3. Design BrandValidator class with scoring components
4. Design shared services (BedrockClient, DynamoDBClient, S3Client)
5. Design Pydantic models for requests/responses
6. Create Mermaid class diagrams for each component

**Output Requirements**:
- Add to LLD Section: "Class Diagrams"
- Mermaid diagrams for:
  - Page Generator classes
  - Agent classes (inheritance hierarchy)
  - Validator classes
  - Shared services
  - Data models

**Success Criteria**:
- All 7 Lambda functions have class diagrams
- OOP principles applied (inheritance, encapsulation)
- Shared code identified and abstracted
- Pydantic models defined

---

### Worker 3: Sequence Diagrams

**Objective**: Create sequence diagrams for all API flows showing interaction between frontend, API Gateway, Lambda, Bedrock, DynamoDB, and S3.

**Input Files**:
- `stage-1-requirements-analysis/outputs/api_contracts.md`
- `stage-1-requirements-analysis/outputs/frontend_integration.md`

**Tasks**:
1. Create page generation sequence (with SSE streaming)
2. Create logo generation sequence (Stable Diffusion XL)
3. Create background generation sequence
4. Create theme selection sequence
5. Create brand validation sequence
6. Create error handling sequence
7. Create state management sequence

**Output Requirements**:
- Add to LLD Section: "Sequence Diagrams"
- Mermaid sequence diagrams for:
  - Page generation (streaming)
  - Image generation (logo, background)
  - Theme/layout suggestion
  - Brand validation
  - Error flows

**Success Criteria**:
- All API flows have sequence diagrams
- SSE streaming protocol shown clearly
- Error handling flows documented
- Async processing shown for image generation

---

### Worker 4: Data Models

**Objective**: Define comprehensive DynamoDB table schemas and S3 object structures with access patterns and indexes.

**Input Files**:
- `stage-1-requirements-analysis/outputs/api_contracts.md`
- `stage-1-requirements-analysis/outputs/hld_analysis.md`

**Tasks**:
1. Design Generation DynamoDB table (state management)
   - Partition key, sort key
   - GSIs for query patterns
   - TTL settings
2. Design Templates DynamoDB table
3. Design Prompts DynamoDB table
4. Define S3 bucket structure for generated assets
5. Define S3 bucket structure for generated images
6. Document access patterns for each table

**Output Requirements**:
- Add to LLD Section: "Data Models"
- DynamoDB table definitions:
  ```
  Table: site-builder-generation-{env}
  PK: tenant_id
  SK: generation_id
  GSI1: status-index (status, created_at)
  ...
  ```
- S3 structure:
  ```
  s3://site-builder-assets-{env}/
  ├── {tenant_id}/
  │   ├── generations/
  │   │   └── {generation_id}/
  │   │       ├── html/
  │   │       ├── css/
  │   │       └── assets/
  │   └── images/
  │       ├── logos/
  │       └── backgrounds/
  ```

**Success Criteria**:
- All DynamoDB tables defined with keys and indexes
- Access patterns documented
- S3 structure supports multi-tenant isolation
- On-demand capacity mode specified (per CLAUDE.md)

---

### Worker 5: Architecture

**Objective**: Document architecture decisions, rationale, and alternatives considered for key technical choices.

**Input Files**:
- `stage-1-requirements-analysis/outputs/hld_analysis.md`
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/HLDs/3.0_BBSW_Site_Builder_HLD.md`

**Tasks**:
1. Document SSE streaming decision (vs WebSocket)
2. Document separate Lambda per agent decision
3. Document DynamoDB on-demand decision
4. Document S3 private bucket decision
5. Document brand scoring hybrid approach
6. Document Bedrock model selection
7. Create architecture component diagram

**Output Requirements**:
- Add to LLD Section: "Architecture Decisions"
- Decision records format:
  ```
  ### Decision: SSE Streaming for Page Generation
  **Context**: ...
  **Options Considered**: ...
  **Decision**: ...
  **Rationale**: ...
  **Consequences**: ...
  ```

**Success Criteria**:
- All key decisions documented with rationale
- Alternatives considered and documented
- Trade-offs clearly explained
- Architecture diagram complete

---

### Worker 6: NFR Security

**Objective**: Document non-functional requirements and security controls for the Generation API.

**Input Files**:
- `stage-1-requirements-analysis/outputs/brs_analysis.md`
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/HLDs/3.0_BBSW_Site_Builder_HLD.md` (Section 6: Security)

**Tasks**:
1. Document performance requirements
   - TTFT < 2s, TTLT < 60s for generation
   - < 10ms for non-generation endpoints
   - Image generation < 30s
2. Document availability requirements
   - Multi-region DR (af-south-1, eu-west-1)
   - RPO 1 hour, RTO 1 minute
3. Document security controls
   - JWT authentication
   - Tenant isolation
   - Input validation
   - LLM guardrails
4. Document scalability requirements
5. Document monitoring and alerting requirements

**Output Requirements**:
- Add to LLD Sections: "NFRs" and "Security"
- NFR table:
  | Category | Requirement | Target | Measurement |
  |----------|-------------|--------|-------------|
  | Performance | TTFT | < 2s | X-Ray |

- Security controls table:
  | Control | Implementation | Verification |
  |---------|----------------|--------------|

**Success Criteria**:
- All performance targets documented
- Security controls comprehensive
- Monitoring strategy defined
- DR requirements addressed

---

## Stage Completion Criteria

The stage is considered **COMPLETE** when:

1. All 6 workers have completed their outputs
2. LLD document created at target location
3. All sections populated with content
4. Class diagrams complete for all Lambda functions
5. Sequence diagrams complete for all API flows
6. Data models defined with access patterns
7. Architecture decisions documented
8. NFRs and security controls complete

---

## Approval Gate (Gate 2)

**After this stage**: Gate 2 approval required

**Approvers**:
- Tech Lead
- Solutions Architect

**Approval Criteria**:
- LLD comprehensive and follows template
- Class diagrams apply OOP principles
- Sequence diagrams cover all flows
- Data models support access patterns
- Architecture decisions well-reasoned
- NFRs measurable and achievable

---

**Stage Owner**: Agentic Project Manager
**Created**: 2026-01-15
**Next Action**: Wait for Stage 1 completion and Gate 1 approval
