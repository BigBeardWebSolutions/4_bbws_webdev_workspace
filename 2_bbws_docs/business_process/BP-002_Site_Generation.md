# BP-002: Site Generation Process

**Version:** 1.0
**Effective Date:** 2026-01-18
**Process Owner:** Product Development
**Last Review:** 2026-01-18

---

## 1. Process Overview

### 1.1 Purpose
This document describes the business process for generating landing pages using AI through the Site Builder platform. The process covers the complete flow from user prompt to validated, deployable HTML/CSS output.

### 1.2 Scope
- User submits generation request via chat interface
- AI processes request using Claude Sonnet 4.5
- HTML/CSS content streamed back to user
- Content validated against brand guidelines
- Version saved for future reference

### 1.3 Process Inputs
| Input | Source | Required |
|-------|--------|----------|
| User Prompt | Chat interface | Yes |
| Tenant ID | JWT token | Yes |
| Site ID | URL parameter | Yes (for refinements) |
| Brand Guidelines | Tenant settings | Optional |
| Previous Context | Conversation history | Optional |

### 1.4 Process Outputs
| Output | Destination | Format |
|--------|-------------|--------|
| Generated HTML | Preview panel | HTML string |
| Generated CSS | Preview panel | CSS string |
| Generation Record | DynamoDB | JSON |
| Brand Score | Validation panel | Decimal (0-10) |

---

## 2. Process Flow Diagram

```
┌──────────────────────────────────────────────────────────────────────────┐
│                       SITE GENERATION PROCESS                             │
│                              BP-002                                       │
└──────────────────────────────────────────────────────────────────────────┘

    ┌─────────────┐
    │   START     │
    │  User       │
    │  Submits    │
    │  Prompt     │
    └──────┬──────┘
           │
           ▼
    ┌─────────────┐     ┌─────────────────────────────────────────────┐
    │  Validate   │     │ Validation Checks:                          │
    │  Request    │────▶│ • JWT token valid                           │
    │             │     │ • Tenant active                             │
    │             │     │ • Generation quota not exceeded             │
    │             │     │ • Prompt length within limits               │
    └──────┬──────┘     └─────────────────────────────────────────────┘
           │
           │ Valid
           ▼
    ┌─────────────┐
    │  Create     │
    │  Generation │
    │  Record     │
    │  (PENDING)  │
    └──────┬──────┘
           │
           ▼
    ┌─────────────┐     ┌─────────────────────────────────────────────┐
    │  Build      │     │ Context Includes:                           │
    │  Prompt     │────▶│ • System prompt (site builder agent)        │
    │  Context    │     │ • Brand guidelines (if configured)          │
    │             │     │ • Previous conversation (refinements)       │
    │             │     │ • User's current prompt                     │
    └──────┬──────┘     └─────────────────────────────────────────────┘
           │
           ▼
    ┌─────────────┐
    │  Update     │
    │  Status     │
    │  (GENERATING)│
    └──────┬──────┘
           │
           ▼
    ┌─────────────────────────────────────────────────────────────────┐
    │                    BEDROCK STREAMING                             │
    │  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐         │
    │  │   Claude    │    │   Stream    │    │   Client    │         │
    │  │   Sonnet    │───▶│   Chunks    │───▶│   (SSE)     │         │
    │  │   4.5       │    │   via API   │    │   Preview   │         │
    │  └─────────────┘    └─────────────┘    └─────────────┘         │
    │                                                                  │
    │  Token-by-token streaming to frontend                           │
    └──────────────────────────────────────────────────────────────────┘
           │
           │ Stream Complete
           ▼
    ┌─────────────┐
    │  Parse      │
    │  HTML/CSS   │
    │  from       │
    │  Response   │
    └──────┬──────┘
           │
           ▼
    ┌─────────────┐     ┌─────────────────────────────────────────────┐
    │  Store      │     │ S3 Storage:                                 │
    │  Assets     │────▶│ s3://bucket/{tenant}/{site}/{version}/      │
    │  in S3      │     │   ├── index.html                            │
    │             │     │   ├── styles.css                            │
    │             │     │   └── metadata.json                         │
    └──────┬──────┘     └─────────────────────────────────────────────┘
           │
           ▼
    ┌─────────────┐
    │  Run        │
    │  Brand      │
    │  Validation │
    └──────┬──────┘
           │
     ┌─────┴─────┐
     │           │
     ▼           ▼
┌─────────┐ ┌─────────┐
│ Score   │ │ Score   │
│ >= 8.0  │ │ < 8.0   │
│ PASS    │ │ WARN    │
└────┬────┘ └────┬────┘
     │           │
     └─────┬─────┘
           │
           ▼
    ┌─────────────┐
    │  Update     │
    │  Generation │
    │  (COMPLETED)│
    └──────┬──────┘
           │
           ▼
    ┌─────────────┐
    │  Increment  │
    │  Usage      │
    │  Counter    │
    └──────┬──────┘
           │
           ▼
    ┌─────────────┐
    │    END      │
    │  Preview    │
    │  Displayed  │
    └─────────────┘
```

---

## 3. Generation States

```
┌──────────────────────────────────────────────────────────────────┐
│                    GENERATION STATE MACHINE                       │
└──────────────────────────────────────────────────────────────────┘

  ┌─────────┐     Create      ┌─────────┐
  │         │────────────────▶│ PENDING │
  │  (new)  │                 │         │
  └─────────┘                 └────┬────┘
                                   │
                              Start│Generation
                                   ▼
                            ┌───────────┐
                            │GENERATING │◀────────┐
                            │           │         │
                            └─────┬─────┘         │
                                  │               │
                    ┌─────────────┼───────────────┤
                    │             │               │
                    ▼             ▼               │
              ┌───────────┐ ┌───────────┐        │
              │ COMPLETED │ │  FAILED   │   Retry│
              │           │ │           │────────┘
              └─────┬─────┘ └───────────┘
                    │
              ┌─────┴─────┐
              │           │
              ▼           ▼
        ┌───────────┐ ┌───────────┐
        │VALIDATING │ │ DEPLOYED  │
        │           │ │           │
        └───────────┘ └───────────┘
```

---

## 4. AI Agent Configuration

### 4.1 Primary Agent: Site Generator
| Attribute | Value |
|-----------|-------|
| Model | Claude Sonnet 4.5 (anthropic.claude-sonnet-4-5-20250514-v1:0) |
| Max Tokens | 8,000 |
| Temperature | 0.7 |
| Timeout | 60 seconds |
| Streaming | Enabled (SSE) |

### 4.2 System Prompt Structure
```
You are an expert web developer creating landing pages.

BRAND GUIDELINES:
{tenant_brand_guidelines}

REQUIREMENTS:
- Generate clean, semantic HTML5
- Use modern CSS with flexbox/grid
- Mobile-first responsive design
- Accessible (WCAG 2.1 AA)
- Fast loading (minimal dependencies)

OUTPUT FORMAT:
Return HTML and CSS in clearly marked sections.
```

### 4.3 Supporting Agents
| Agent | Purpose | Model | Timeout |
|-------|---------|-------|---------|
| Theme Selector | Suggest color themes | Claude Sonnet 4.5 | 15s |
| Logo Creator | Generate logos | Stable Diffusion XL | 30s |
| Brand Validator | Score brand compliance | Claude Sonnet 4.5 | 20s |

---

## 5. Quota Management

### 5.1 Generation Limits by Plan
| Plan | Generations/Month | Concurrent | Max Prompt Length |
|------|-------------------|------------|-------------------|
| Basic | 20 | 1 | 1,000 chars |
| Professional | 100 | 3 | 5,000 chars |
| Enterprise | 500 | 10 | 10,000 chars |

### 5.2 Quota Enforcement
```
ON generation_request:
    current_usage = get_tenant_usage(tenant_id, current_month)
    plan_limit = get_plan_limit(tenant_plan)

    IF current_usage >= plan_limit:
        RETURN 429 Too Many Requests
        "Monthly generation limit reached. Upgrade plan or wait until {reset_date}"

    IF concurrent_generations >= plan_concurrent_limit:
        RETURN 429 Too Many Requests
        "Maximum concurrent generations reached. Please wait."
```

---

## 6. Brand Validation

### 6.1 Validation Criteria
| Category | Weight | Checks |
|----------|--------|--------|
| Color Compliance | 30% | Primary/secondary colors match brand |
| Typography | 20% | Font family, sizes consistent |
| Logo Usage | 20% | Logo present, correct placement |
| Tone of Voice | 15% | Content matches brand voice |
| Layout | 15% | Structure follows brand patterns |

### 6.2 Score Interpretation
| Score | Status | Deployment |
|-------|--------|------------|
| 9.0 - 10.0 | Excellent | Auto-approved |
| 8.0 - 8.9 | Good | Approved with suggestions |
| 6.0 - 7.9 | Needs Work | Staging only, warnings shown |
| < 6.0 | Poor | Blocked, must refine |

---

## 7. Error Handling

| Error | Response Code | User Message | Recovery |
|-------|---------------|--------------|----------|
| Quota exceeded | 429 | "Monthly limit reached" | Upgrade or wait |
| Bedrock timeout | 504 | "Generation took too long, retry" | Auto-retry once |
| Invalid prompt | 400 | "Please provide more details" | User corrects |
| Service unavailable | 503 | "Service temporarily unavailable" | Retry with backoff |

---

## 8. Performance Targets

| Metric | Target | P99 |
|--------|--------|-----|
| Time to First Token | < 2s | < 5s |
| Total Generation Time | < 30s | < 60s |
| Brand Validation Time | < 5s | < 10s |
| Preview Render Time | < 500ms | < 1s |

---

## 9. Related Documents

| Document | Type | Location |
|----------|------|----------|
| RB-002 | Runbook | /runbooks/RB-002_Site_Generation_Troubleshooting.md |
| SOP-002 | SOP | /SOPs/SOP-002_Site_Generation_QA.md |
| LLD | Technical | /LLDs/3.1.2_LLD_Site_Builder_Generation_API.md |

---

## 10. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-18 | Product Team | Initial version |
