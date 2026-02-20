# Design Litmus Test Skill

**Skill ID**: Design_Litmus_Test
**Version**: 1.0
**Created**: 2026-01-05
**Purpose**: Determine correct placement of information across BRS, HLD, and LLD documents

---

## 1. Overview

This skill provides a standardized litmus test for determining where information belongs in the documentation hierarchy. Use this test when uncertain whether content should be placed in a BRS, HLD, or LLD document.

### 1.1 Document Hierarchy

```
┌─────────────────────────────────────────────────────────────┐
│                          BRS                                 │
│              Business Requirements Specification             │
│                    WHAT and WHY                              │
│              Audience: Executives, Business Owners           │
├─────────────────────────────────────────────────────────────┤
│                          HLD                                 │
│                  High-Level Design                           │
│              WHAT (architectural) and WHERE                  │
│              Audience: Architects, Tech Leads                │
├─────────────────────────────────────────────────────────────┤
│                          LLD                                 │
│                   Low-Level Design                           │
│                         HOW                                  │
│              Audience: Developers, DevOps Engineers          │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 How to Use This Test

1. For each piece of content, answer all 10 questions for each document type
2. Count the "YES" answers for each section
3. Apply the voting rules to determine placement
4. If tied, use the tie-breaker rules

---

## 2. BRS Litmus Test (10 Questions)

**Core Principle**: BRS answers WHAT the business needs and WHY it matters.

Answer YES or NO to each question:

| # | Question | YES/NO |
|---|----------|--------|
| **BRS-Q1** | Would a CEO or CFO understand this content without technical explanation? | |
| **BRS-Q2** | Does this content explain a business problem or opportunity? | |
| **BRS-Q3** | Does this content describe business value, ROI, or cost savings? | |
| **BRS-Q4** | Is this content about WHAT capability is needed (not HOW to build it)? | |
| **BRS-Q5** | Could this content be presented in a board meeting or investor pitch? | |
| **BRS-Q6** | Does this content define success in business terms (revenue, time, satisfaction)? | |
| **BRS-Q7** | Is this content free of technology-specific terminology (AWS, Python, API, etc.)? | |
| **BRS-Q8** | Does this content describe user/customer outcomes rather than system behavior? | |
| **BRS-Q9** | Would removing this content leave executives unable to make a go/no-go decision? | |
| **BRS-Q10** | Is this content about business rules/policies rather than implementation rules? | |

### BRS Disqualifiers (Automatic NO)

If ANY of the following are true, the content does NOT belong in BRS:

- [ ] Contains code (Python, Java, JSON, YAML, SQL, etc.)
- [ ] Contains API endpoints or HTTP methods
- [ ] Contains database schemas or table structures
- [ ] Contains AWS/cloud service names (ECS, Lambda, S3, RDS, etc.)
- [ ] Contains configuration values (memory, CPU, timeouts, ports)
- [ ] Contains architectural diagrams with technical components
- [ ] Contains error codes or HTTP status codes
- [ ] Contains IAM roles, security groups, or network configurations
- [ ] Contains message queue configurations or event schemas
- [ ] Contains monitoring metrics or alert thresholds

---

## 3. HLD Litmus Test (10 Questions)

**Core Principle**: HLD answers WHAT the architecture looks like and WHERE components fit.

Answer YES or NO to each question:

| # | Question | YES/NO |
|---|----------|--------|
| **HLD-Q1** | Does this content describe system components and their relationships? | |
| **HLD-Q2** | Does this content explain architectural decisions and their rationale? | |
| **HLD-Q3** | Would a new architect understand the system's structure from this content? | |
| **HLD-Q4** | Does this content show integration points between systems? | |
| **HLD-Q5** | Does this content define non-functional requirements (performance, availability, scalability)? | |
| **HLD-Q6** | Is this content about component responsibilities (not implementation details)? | |
| **HLD-Q7** | Does this content describe data flows at a conceptual level (not message schemas)? | |
| **HLD-Q8** | Does this content explain technology choices without detailed configurations? | |
| **HLD-Q9** | Could this content guide multiple different implementation approaches? | |
| **HLD-Q10** | Is this content about the "shape" of the solution rather than the "code" of the solution? | |

### HLD Disqualifiers (Automatic NO)

If ANY of the following are true, the content does NOT belong in HLD:

- [ ] Contains code samples or pseudocode
- [ ] Contains specific configuration values (512MB, 30 seconds, port 8080)
- [ ] Contains API request/response examples with full payloads
- [ ] Contains database table schemas with column definitions
- [ ] Contains IAM policy JSON or security group rules
- [ ] Contains CloudWatch metric names or alarm configurations
- [ ] Contains Terraform/CloudFormation snippets
- [ ] Contains environment variables or secret names
- [ ] Contains retry policies with specific backoff values
- [ ] Contains step-by-step implementation instructions

---

## 4. LLD Litmus Test (10 Questions)

**Core Principle**: LLD answers HOW to implement the solution.

Answer YES or NO to each question:

| # | Question | YES/NO |
|---|----------|--------|
| **LLD-Q1** | Could a developer implement this feature using only this content? | |
| **LLD-Q2** | Does this content include specific configuration values? | |
| **LLD-Q3** | Does this content contain code samples, schemas, or data structures? | |
| **LLD-Q4** | Does this content specify exact API endpoints, methods, and payloads? | |
| **LLD-Q5** | Does this content define error handling with specific error codes? | |
| **LLD-Q6** | Does this content include monitoring metrics and alert thresholds? | |
| **LLD-Q7** | Does this content specify security implementations (IAM, encryption keys)? | |
| **LLD-Q8** | Does this content include deployment configurations or infrastructure-as-code? | |
| **LLD-Q9** | Does this content define testing scenarios with specific test data? | |
| **LLD-Q10** | Does this content include troubleshooting steps or runbook procedures? | |

### LLD Qualifiers (Should be YES)

If ANY of the following are true, the content SHOULD be in LLD:

- [ ] Contains working code that will be deployed
- [ ] Contains specific AWS resource configurations
- [ ] Contains DynamoDB table schemas with GSI definitions
- [ ] Contains API OpenAPI/Swagger specifications
- [ ] Contains message queue configurations (visibility timeout, retention)
- [ ] Contains Lambda function specifications (memory, timeout, handler)
- [ ] Contains CloudWatch dashboard or alarm definitions
- [ ] Contains Terraform modules or CloudFormation templates
- [ ] Contains CI/CD pipeline configurations
- [ ] Contains security group ingress/egress rules

---

## 5. Voting System

### 5.1 Scoring

For each document type, count the YES answers:

| Document | YES Count | Score |
|----------|-----------|-------|
| BRS | /10 | |
| HLD | /10 | |
| LLD | /10 | |

### 5.2 Placement Rules

**Rule 1: Clear Winner (Difference ≥ 3)**
```
If one document has 3+ more YES answers than others:
  → Place content in that document
```

**Rule 2: Strong Indicator (Highest Score ≥ 7)**
```
If one document has ≥ 7 YES answers:
  → Place content in that document (even if close to others)
```

**Rule 3: Disqualifier Override**
```
If content triggers ANY disqualifier for a document:
  → That document scores 0 regardless of YES count
```

**Rule 4: Qualifier Override**
```
If content triggers ANY LLD qualifier:
  → LLD scores minimum 7 regardless of YES count
```

### 5.3 Tie-Breaker Rules

When two documents have equal or near-equal scores (within 2):

| Tie Scenario | Resolution |
|--------------|------------|
| BRS vs HLD | Ask: "Is this about business outcomes?" → YES = BRS, NO = HLD |
| HLD vs LLD | Ask: "Can this guide multiple implementations?" → YES = HLD, NO = LLD |
| BRS vs LLD | Check disqualifiers - if none triggered, default to BRS |
| Three-way tie | Split content: business context → BRS, architecture → HLD, implementation → LLD |

---

## 6. Decision Matrix

Quick reference for common content types:

| Content Type | BRS | HLD | LLD | Rationale |
|--------------|-----|-----|-----|-----------|
| Business problem statement | ✅ | ❌ | ❌ | Executive-level context |
| ROI/cost analysis | ✅ | ❌ | ❌ | Business value |
| User stories (business context) | ✅ | ❌ | ❌ | What users need |
| Acceptance criteria (technical) | ❌ | ✅ | ❌ | Architectural validation |
| Component diagrams | ❌ | ✅ | ❌ | System structure |
| Sequence diagrams (conceptual) | ❌ | ✅ | ❌ | Flow overview |
| Technology selection rationale | ❌ | ✅ | ❌ | Architecture decisions |
| NFRs (targets) | ❌ | ✅ | ❌ | Architecture constraints |
| API endpoint specifications | ❌ | ❌ | ✅ | Implementation detail |
| Database schemas | ❌ | ❌ | ✅ | Implementation detail |
| Code samples | ❌ | ❌ | ✅ | Implementation |
| Configuration values | ❌ | ❌ | ✅ | Implementation detail |
| Error handling code | ❌ | ❌ | ✅ | Implementation |
| Monitoring/alerting configs | ❌ | ❌ | ✅ | Operational implementation |
| IAM policies | ❌ | ❌ | ✅ | Security implementation |
| Terraform/IaC | ❌ | ❌ | ✅ | Deployment implementation |

---

## 7. Worked Examples

### Example 1: "Customer provisioning takes 2 hours manually"

| Test | Score | Rationale |
|------|-------|-----------|
| BRS | 9/10 | Business problem, executive-readable, no tech |
| HLD | 2/10 | Not about architecture |
| LLD | 0/10 | No implementation details |

**Result**: BRS ✅

---

### Example 2: "ECS Fargate task with 512MB memory and 0.25 vCPU"

| Test | Score | Rationale |
|------|-------|-----------|
| BRS | 0/10 | Disqualifier: AWS service name, config values |
| HLD | 1/10 | Disqualifier: specific configuration |
| LLD | 10/10 | Implementation configuration |

**Result**: LLD ✅

---

### Example 3: "System uses event-driven architecture with async processing"

| Test | Score | Rationale |
|------|-------|-----------|
| BRS | 2/10 | Too technical for executives |
| HLD | 8/10 | Architectural pattern, no specific config |
| LLD | 3/10 | Not implementation-specific |

**Result**: HLD ✅

---

### Example 4: "Site creation must complete within 15 minutes"

| Test | Score | Rationale |
|------|-------|-----------|
| BRS | 6/10 | Business SLA, customer expectation |
| HLD | 7/10 | NFR target, architecture constraint |
| LLD | 4/10 | Not implementation detail |

**Result**: HLD ✅ (or split: BRS for business context, HLD for NFR)

---

### Example 5: Python dataclass definition

```python
@dataclass
class TenantResources:
    tenant_id: str
    ecs_service_arn: Optional[str]
```

| Test | Score | Rationale |
|------|-------|-----------|
| BRS | 0/10 | Disqualifier: contains code |
| HLD | 0/10 | Disqualifier: contains code |
| LLD | 10/10 | Implementation code |

**Result**: LLD ✅

---

## 8. Edge Cases

### 8.1 Diagrams

| Diagram Type | Placement | Rationale |
|--------------|-----------|-----------|
| Business process flow | BRS | Shows business operations |
| Context diagram (users, systems) | HLD | Shows system boundaries |
| Component diagram | HLD | Shows architecture |
| Sequence diagram (conceptual) | HLD | Shows interactions |
| Sequence diagram (with payloads) | LLD | Implementation detail |
| Network diagram | LLD | Infrastructure implementation |
| Database ERD | LLD | Data implementation |

### 8.2 Tables

| Table Type | Placement | Rationale |
|------------|-----------|-----------|
| Business value metrics | BRS | Business outcomes |
| Stakeholder list | BRS | Business context |
| Technology comparison | HLD | Architecture decision |
| NFR targets | HLD | Architecture constraints |
| API endpoint list | LLD | Implementation spec |
| Error code reference | LLD | Implementation detail |
| Configuration reference | LLD | Implementation detail |

### 8.3 Lists

| List Type | Placement | Rationale |
|-----------|-----------|-----------|
| Business capabilities | BRS | What the system does |
| Business rules (policies) | BRS | Business constraints |
| Components | HLD | Architecture elements |
| Integration points | HLD | Architecture boundaries |
| Environment variables | LLD | Implementation config |
| IAM permissions | LLD | Security implementation |

---

## 9. Validation Checklist

Before finalizing document placement, verify:

### BRS Final Check
- [ ] Executive could approve budget based on this document alone
- [ ] No technical jargon requiring explanation
- [ ] Business value is clearly articulated
- [ ] Success is defined in business terms

### HLD Final Check
- [ ] Architect could design implementation options from this document
- [ ] Technology choices are explained, not detailed
- [ ] Integration points are clear
- [ ] NFRs guide architecture decisions

### LLD Final Check
- [ ] Developer could implement without asking clarifying questions
- [ ] All configurations are specified
- [ ] Error scenarios are covered
- [ ] Deployment process is documented

---

## 10. Quick Reference Card

```
┌─────────────────────────────────────────────────────────────┐
│                  DESIGN LITMUS TEST                          │
│                    Quick Reference                           │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  BRS = WHAT + WHY (Business)                                │
│  ├── Would CEO understand?                                  │
│  ├── Is it about business outcomes?                         │
│  └── Zero code, zero AWS, zero configs                      │
│                                                              │
│  HLD = WHAT + WHERE (Architecture)                          │
│  ├── Would architect understand system?                     │
│  ├── Are decisions explained (not detailed)?                │
│  └── Zero code, zero specific configs                       │
│                                                              │
│  LLD = HOW (Implementation)                                 │
│  ├── Could developer implement from this?                   │
│  ├── Are all configs specified?                             │
│  └── Code, schemas, configs welcome                         │
│                                                              │
├─────────────────────────────────────────────────────────────┤
│  VOTING: Highest YES count wins (≥3 difference = clear)     │
│  OVERRIDE: Disqualifier = 0, Qualifier = min 7              │
│  TIE: Business → BRS, Architecture → HLD, Code → LLD        │
└─────────────────────────────────────────────────────────────┘
```

---

## 11. Usage Instructions

### For BRS Architects
1. Run the BRS Litmus Test on all content
2. If score < 7, consider moving to HLD or LLD
3. Check all disqualifiers - if any triggered, move content out

### For HLD Architects
1. Run the HLD Litmus Test on all content
2. Verify no disqualifiers are triggered
3. If content is too business-focused (BRS score > HLD score), escalate to BRS
4. If content is too detailed (LLD score > HLD score), push to LLD

### For LLD Architects
1. Run the LLD Litmus Test on all content
2. If score < 7, verify content has enough implementation detail
3. Check qualifiers - if any triggered, content belongs here
4. Ensure developer could implement without clarification

---

**End of Skill**
