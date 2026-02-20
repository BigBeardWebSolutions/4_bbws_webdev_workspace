# BRS Analysis - API Requirements Mapping

**Version**: 1.0
**Date**: 2026-01-15
**Author**: Worker 2 - Requirements Analyst
**Source Documents**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/HLDs/3.0_BBSW_Site_Builder_HLD.md`
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/BRS/3.0_BRS_Site_Builder.md`

---

## 1. User Story to API Mapping

### 1.1 Epic 1: AI Page Generation

| User Story | Description | API Endpoint | Method | Priority | AI Agent |
|------------|-------------|--------------|--------|----------|----------|
| US-001 | Describe landing page requirements in plain language | `/v1/sites/{tenant_id}/generation` | POST | Critical | Site Generator Agent, Outliner, Theme Selector, Layout |
| US-002 | Use existing design components and brand assets | `/v1/sites/{tenant_id}/templates` | GET | Critical | Theme Selector Agent, Logo Creator Agent |

### 1.2 Epic 2: Iterative Refinement

| User Story | Description | API Endpoint | Method | Priority | AI Agent |
|------------|-------------|--------------|--------|----------|----------|
| US-003 | Provide feedback and request changes conversationally | `/v1/sites/{tenant_id}/generation/{id}/advisor` | POST | High | AI Advisor Agent, Layout Agent |
| US-004 | See generation history and rollback to previous versions | `/v1/sites/{tenant_id}/generation/{id}/versions` | GET | High | N/A (CRUD) |
| US-004 | Restore a previous version | `/v1/sites/{tenant_id}/generation/{id}/versions/{version}` | POST | High | N/A (CRUD) |

### 1.3 Epic 3: Quality & Validation

| User Story | Description | API Endpoint | Method | Priority | AI Agent |
|------------|-------------|--------------|--------|----------|----------|
| US-005 | Automatic validation of brand compliance | `/v1/sites/{tenant_id}/generation/{id}/validate/brand` | POST | Critical | Design Scorer Agent |
| US-006 | Scan generated code for vulnerabilities | `/v1/sites/{tenant_id}/generation/{id}/validate/security` | POST | Critical | Security Validator Agent |

### 1.4 Epic 4: Deployment

| User Story | Description | API Endpoint | Method | Priority | AI Agent |
|------------|-------------|--------------|--------|----------|----------|
| US-007 | Deploy pages to staging or production with one click | `/v1/sites/{tenant_id}/deployments` | POST | High | Site Packager, Site Stager Agent, Site Deployer Agent |
| US-007 | List deployments | `/v1/sites/{tenant_id}/deployments` | GET | High | N/A (CRUD) |
| US-007 | Manage DNS for deployed sites | `/v1/sites/{tenant_id}/dns` | GET, PUT | High | DNS Management Lambda |
| US-008 | Automated performance testing before production | `/v1/sites/{tenant_id}/deployments/{id}/performance` | POST | High | Website Validator Agent |

### 1.5 Epic 5: Analytics & Optimization

| User Story | Description | API Endpoint | Method | Priority | AI Agent |
|------------|-------------|--------------|--------|----------|----------|
| US-009 | Track which components perform best | `/v1/sites/{tenant_id}/analytics/components` | GET | High | N/A (CloudWatch) |
| US-010 | See cost and performance metrics for AI generation | `/v1/sites/{tenant_id}/analytics/costs` | GET | High | N/A (CloudWatch) |

### 1.6 Epic 6: Site Designer Agents

| User Story | Description | API Endpoint | Method | Priority | AI Agent |
|------------|-------------|--------------|--------|----------|----------|
| US-011 | Generate professional logos | `/v1/sites/{tenant_id}/agents/logo` | POST | High | Logo Creator Agent (Stable Diffusion XL) |
| US-012 | Generate background images matching page theme | `/v1/sites/{tenant_id}/agents/background` | POST | High | Background Image Creator Agent (Stable Diffusion XL) |
| US-013 | Suggest cohesive color themes | `/v1/sites/{tenant_id}/agents/theme` | POST | High | Theme Selector Agent (Claude Sonnet 4.5) |
| US-014 | Outline page structure before generation | `/v1/sites/{tenant_id}/agents/outline` | POST | High | Outliner Agent (Claude Sonnet 4.5) |
| US-022 | Generate blog posts and articles | `/v1/sites/{tenant_id}/agents/blog` | POST | High | Blogger Agent (Claude Sonnet 4.5) |
| US-023 | Create responsive page layouts | `/v1/sites/{tenant_id}/agents/layout` | POST | High | Layout Agent (Claude Sonnet 4.5) |
| US-024 | Generate newsletter templates and content | `/v1/sites/{tenant_id}/agents/newsletter` | POST | High | Newsletter Agent (Claude Sonnet 4.5 + SES) |

### 1.7 Epic 7: Tenant Management

| User Story | Description | API Endpoint | Method | Priority | AI Agent |
|------------|-------------|--------------|--------|----------|----------|
| US-015 | Create and manage organisations | `/v1/tenants/{tenant_id}` | GET, POST, PUT, DELETE | High | N/A (CRUD) |
| US-016 | Invite users to organisation | `/v1/user/invitation` | POST | High | N/A (CRUD) |
| US-017 | Manage team membership | `/v1/tenants/{tenant_id}/teams/{team_id}/members` | GET, POST, DELETE | High | N/A (CRUD) |
| US-018 | Belong to multiple teams | `/v1/user/{tenant}/teams` | GET | High | N/A (CRUD) |

### 1.8 Epic 8: Site Migration

| User Story | Description | API Endpoint | Method | Priority | AI Agent |
|------------|-------------|--------------|--------|----------|----------|
| US-019 | Migrate WordPress sites to static HTML | `/v1/migrations/{tenant_id}` | POST | Medium | WordPress Migrator Lambda, HTML Cleaner Lambda |
| US-020 | Migrate static HTML sites from Xneelo to AWS | `/v1/migrations/{tenant_id}` | POST | Medium | Static Migration Service, HTML Cleaner Lambda |
| US-021 | Track migration status | `/v1/migrations/{tenant_id}/{migration_id}` | GET | Medium | N/A (CRUD) |

---

## 2. Acceptance Criteria per Endpoint

### 2.1 Generation Endpoints

#### POST `/v1/sites/{tenant_id}/generation`
**User Story**: US-001

**Request Schema**:
```json
{
  "prompt": "string - Natural language description of page requirements",
  "template_id": "string (optional) - Reference template to use",
  "brand_assets": {
    "logo_id": "string (optional)",
    "color_palette_id": "string (optional)"
  },
  "options": {
    "preview_only": "boolean - Use Claude Haiku for quick preview",
    "sections": ["array of section types to include"]
  }
}
```

**Acceptance Criteria**:
- [ ] Page preview is generated within 15 seconds for standard requests
- [ ] All described sections are present in the generated page
- [ ] Generated HTML is valid and responsive
- [ ] User can immediately see preview without refresh
- [ ] Error messages MUST be clear and actionable
- [ ] System MUST handle AI service failures gracefully with retry
- [ ] Streaming response enabled for real-time generation feedback
- [ ] TTFT (Time To First Token) < 2 seconds
- [ ] TTLT (Time To Last Token) < 60 seconds

**Response Schema**:
```json
{
  "generation_id": "string",
  "status": "in_progress | completed | failed",
  "preview_url": "string",
  "sections": [
    {
      "section_id": "string",
      "type": "hero | features | testimonials | cta | footer",
      "html": "string"
    }
  ],
  "brand_score": "number (0-10)",
  "version": "number",
  "created_at": "ISO 8601 timestamp"
}
```

#### GET `/v1/sites/{tenant_id}/templates`
**User Story**: US-002

**Acceptance Criteria**:
- [ ] Returns all tenant-specific brand assets when available
- [ ] Output matches brand guidelines (colors, fonts, logos)
- [ ] Includes default templates when no tenant assets exist
- [ ] Supports filtering by template type (hero, product, newsletter)
- [ ] Response time < 100ms

**Response Schema**:
```json
{
  "templates": [
    {
      "template_id": "string",
      "name": "string",
      "type": "string",
      "preview_url": "string",
      "brand_compliant": "boolean"
    }
  ],
  "brand_assets": {
    "logo_url": "string",
    "color_palette": {
      "primary": "string",
      "secondary": "string",
      "accent": "string"
    },
    "typography": {
      "heading_font": "string",
      "body_font": "string"
    }
  }
}
```

#### POST `/v1/sites/{tenant_id}/generation/{id}/advisor`
**User Story**: US-003

**Acceptance Criteria**:
- [ ] Feedback is interpreted correctly by AI Advisor
- [ ] Only targeted sections are modified
- [ ] Unchanged sections remain exactly as before
- [ ] Response time for updates is under 10 seconds
- [ ] System MUST handle ambiguous feedback with clarification requests
- [ ] Streaming response for real-time updates

**Request Schema**:
```json
{
  "feedback": "string - Natural language feedback",
  "target_sections": ["array of section_ids (optional)"],
  "action": "refine | regenerate | replace"
}
```

### 2.2 Agent Endpoints

#### POST `/v1/sites/{tenant_id}/agents/logo`
**User Story**: US-011

**Acceptance Criteria**:
- [ ] Multiple logo options generated (4 minimum)
- [ ] Generation completes within 15 seconds
- [ ] Logos match brand guidelines when available
- [ ] User can select and apply preferred option
- [ ] System MUST block inappropriate content
- [ ] Returns variations in multiple formats (SVG, PNG)

**Request Schema**:
```json
{
  "description": "string - Logo requirements",
  "style": "modern | classic | minimal | playful",
  "colors": ["array of hex colors (optional)"],
  "variations": "number (default: 4)"
}
```

**Response Schema**:
```json
{
  "logo_options": [
    {
      "logo_id": "string",
      "preview_url": "string",
      "formats": {
        "svg": "string - S3 URL",
        "png": "string - S3 URL"
      },
      "brand_score": "number"
    }
  ],
  "generation_time_ms": "number"
}
```

#### POST `/v1/sites/{tenant_id}/agents/background`
**User Story**: US-012

**Acceptance Criteria**:
- [ ] Custom background images generated via Stable Diffusion XL
- [ ] Images are web-optimized (compressed, responsive sizes)
- [ ] Multiple variations offered
- [ ] User can apply to specific page sections
- [ ] System MUST provide fallback options on failure
- [ ] Maximum resolution: 1920x1080px for web
- [ ] File size < 500KB per image

#### POST `/v1/sites/{tenant_id}/agents/theme`
**User Story**: US-013

**Acceptance Criteria**:
- [ ] AI suggests multiple cohesive theme options (minimum 3)
- [ ] Themes are visualized with live preview
- [ ] Selected theme applies to all components
- [ ] Brand compliance is maintained
- [ ] System MUST ensure accessibility compliance (WCAG 2.1 AA)
- [ ] Color contrast ratios validated

#### POST `/v1/sites/{tenant_id}/agents/outline`
**User Story**: US-014

**Acceptance Criteria**:
- [ ] AI proposes page structure before full generation
- [ ] Structure is presented in clear, reviewable format
- [ ] User can approve, modify, or reject structure
- [ ] Modifications are incorporated in revised proposal
- [ ] System MUST respect user structure decisions
- [ ] Response time < 5 seconds

#### POST `/v1/sites/{tenant_id}/agents/blog`
**User Story**: US-022

**Acceptance Criteria**:
- [ ] Blog content generated based on topic/brief
- [ ] Content is SEO-optimized (keywords, meta, structure)
- [ ] Content matches brand voice guidelines
- [ ] User can review and edit before publishing
- [ ] System MUST maintain content quality
- [ ] Includes: title, meta description, headings, body, CTA

#### POST `/v1/sites/{tenant_id}/agents/layout`
**User Story**: US-023

**Acceptance Criteria**:
- [ ] Layouts are responsive across desktop/tablet/mobile
- [ ] Grid-based structure is generated
- [ ] User can preview all breakpoints
- [ ] Layouts can be saved as reusable templates
- [ ] System MUST validate mobile experience

#### POST `/v1/sites/{tenant_id}/agents/newsletter`
**User Story**: US-024

**Acceptance Criteria**:
- [ ] Email-optimized HTML is generated
- [ ] Template renders correctly across major email clients (Gmail, Outlook, Apple Mail)
- [ ] Subject line and preview text are included
- [ ] Test sending via SES is available
- [ ] System MUST validate email compatibility

### 2.3 Validation Endpoints

#### POST `/v1/sites/{tenant_id}/generation/{id}/validate/brand`
**User Story**: US-005

**Acceptance Criteria**:
- [ ] All pages are automatically scored for brand consistency
- [ ] Minimum production threshold is 8.0/10
- [ ] Specific feedback is provided for each scoring category (7 categories)
- [ ] Pages 9.0+ are auto-approved
- [ ] Pages 8.0-8.9 are approved with recommendations
- [ ] Pages below 8.0 are blocked with required actions
- [ ] System MUST provide actionable improvement suggestions

**Response Schema**:
```json
{
  "generation_id": "string",
  "brand_score": "number (0-10)",
  "status": "excellent | acceptable | needs_work | rejected",
  "categories": {
    "color_palette_compliance": {
      "score": "number (0-2.0)",
      "feedback": "string"
    },
    "typography_compliance": {
      "score": "number (0-1.5)",
      "feedback": "string"
    },
    "logo_usage": {
      "score": "number (0-1.5)",
      "feedback": "string"
    },
    "layout_spacing": {
      "score": "number (0-1.5)",
      "feedback": "string"
    },
    "component_style_consistency": {
      "score": "number (0-1.5)",
      "feedback": "string"
    },
    "imagery_iconography": {
      "score": "number (0-1.0)",
      "feedback": "string"
    },
    "content_tone_voice": {
      "score": "number (0-1.0)",
      "feedback": "string"
    }
  },
  "recommendations": ["array of improvement suggestions"],
  "deployment_allowed": "boolean"
}
```

#### POST `/v1/sites/{tenant_id}/generation/{id}/validate/security`
**User Story**: US-006

**Acceptance Criteria**:
- [ ] All generated HTML/CSS/JS is scanned for vulnerabilities
- [ ] XSS patterns are detected and blocked
- [ ] Injection attempts are logged and reported
- [ ] Malicious patterns trigger generation rejection
- [ ] Security scan results are recorded for audit
- [ ] System MUST block deployment of vulnerable code

**Response Schema**:
```json
{
  "generation_id": "string",
  "security_status": "passed | failed | warning",
  "vulnerabilities": [
    {
      "type": "xss | injection | unsafe_resource | other",
      "severity": "critical | high | medium | low",
      "location": "string - file/section reference",
      "description": "string",
      "remediation": "string"
    }
  ],
  "blocked_patterns": ["array of detected malicious patterns"],
  "audit_id": "string - for compliance tracking"
}
```

### 2.4 Deployment Endpoints

#### POST `/v1/sites/{tenant_id}/deployments`
**User Story**: US-007

**Acceptance Criteria**:
- [ ] One-click deployment to staging environment
- [ ] One-click promotion from staging to production
- [ ] All prerequisites (brand score >= 8.0, security scan pass) are validated
- [ ] Deployment versions are tracked
- [ ] Preview URLs are generated for staging
- [ ] System MUST handle deployment failures with retry
- [ ] CloudFront invalidation triggered automatically
- [ ] DNS updates via Route 53 when needed

**Request Schema**:
```json
{
  "generation_id": "string",
  "environment": "staging | production",
  "custom_domain": "string (optional)",
  "dns_config": {
    "subdomain": "string (optional)",
    "hosted_zone_id": "string (optional)"
  }
}
```

**Response Schema**:
```json
{
  "deployment_id": "string",
  "status": "queued | in_progress | completed | failed",
  "environment": "staging | production",
  "url": "string",
  "dns_status": "pending | configured | failed",
  "version": "number",
  "created_at": "ISO 8601 timestamp",
  "estimated_completion": "ISO 8601 timestamp (if queued)"
}
```

#### POST `/v1/sites/{tenant_id}/deployments/{id}/performance`
**User Story**: US-008

**Acceptance Criteria**:
- [ ] Automated performance testing on staging deployment
- [ ] Page load time must be under 3 seconds
- [ ] Core Web Vitals are measured and reported (LCP, FID, CLS)
- [ ] Pages below threshold are blocked with suggestions
- [ ] Performance history is tracked over time
- [ ] System MUST provide actionable optimization suggestions

**Response Schema**:
```json
{
  "deployment_id": "string",
  "performance_status": "passed | failed | warning",
  "metrics": {
    "page_load_time_ms": "number",
    "first_contentful_paint_ms": "number",
    "largest_contentful_paint_ms": "number",
    "first_input_delay_ms": "number",
    "cumulative_layout_shift": "number",
    "total_page_size_kb": "number"
  },
  "thresholds": {
    "page_load_time_ms": 3000,
    "largest_contentful_paint_ms": 2500,
    "first_input_delay_ms": 100,
    "cumulative_layout_shift": 0.1
  },
  "recommendations": [
    {
      "issue": "string",
      "impact": "high | medium | low",
      "suggestion": "string"
    }
  ],
  "production_ready": "boolean"
}
```

---

## 3. Non-Functional Requirements

### 3.1 Performance Requirements

| Metric | Target | Source |
|--------|--------|--------|
| Non-generation API response time | < 10ms | BRS 4.1 |
| TTFT (Time To First Token) | < 2 seconds | TBC-002 (Resolved) |
| TTLT (Time To Last Token) streaming | < 60 seconds (1 minute) | TBC-002 (Resolved) |
| Page generation time | 10-15 seconds | BRS 1.1, HLD 1.2 |
| Preview generation (Claude Haiku) | < 5 seconds | BRS 4.1 |
| Iterative refinement response | < 10 seconds | US-003 |
| Logo generation | < 15 seconds | US-011 |
| Template retrieval | < 100ms | Derived |
| Deployment queue wait | < 2 minutes typical | US-007 |

### 3.2 Throughput Requirements

| Metric | Target | Source |
|--------|--------|--------|
| Concurrent users | 500 simultaneous | BRS 4.1, HLD 5.1 |
| Monthly page generations | 10,000 | HLD 5.1 |
| Monthly API calls | 750,000 | HLD 5.1 |
| Average pages per customer | 5 | HLD 5.1 |
| Lambda invocations (monthly) | 10M | HLD 5.2 |

### 3.3 Availability Requirements

| Metric | Target | Source |
|--------|--------|--------|
| Uptime | 99.9% | BRS 4.3 |
| RPO (Recovery Point Objective) | 1 hour | TBC-005 (Resolved) |
| RTO (Recovery Time Objective) | 1 minute | TBC-006 (Resolved) |
| Multi-Region DR | af-south-1 (primary) + eu-west-1 (failover) | HLD 3.2 |
| DynamoDB backup frequency | Hourly | CLAUDE.md DR strategy |

### 3.4 Scalability Requirements

| Requirement | Specification | Source |
|-------------|---------------|--------|
| Auto-scaling | Lambda-based serverless auto-scales | BRS 4.4 |
| DynamoDB capacity | On-demand mode (no provisioning) | CLAUDE.md |
| Queue processing | SQS for async processing with DLQ | HLD 3.2 |
| Edge delivery | CloudFront CDN | BRS 4.4 |
| Design capacity | 10x current load | BRS 4.4 |

---

## 4. Error Handling Requirements

### 4.1 Generation Errors

| Error Code | Description | HTTP Status | Retry | User Message |
|------------|-------------|-------------|-------|--------------|
| GEN-001 | AI service unavailable (Bedrock) | 503 | Yes (exponential backoff) | "AI service temporarily unavailable. Please try again in a few moments." |
| GEN-002 | Request timeout (TTLT exceeded) | 408 | Yes | "Generation is taking longer than expected. You can wait or try again." |
| GEN-003 | Invalid prompt (content policy violation) | 400 | No | "Request blocked due to policy violation" |
| GEN-004 | Ambiguous requirements | 422 | No | "Please provide more details: [clarification questions]" |
| GEN-005 | Template not found | 404 | No | "The specified template does not exist" |
| GEN-006 | Generation quota exceeded | 429 | Yes (after cooldown) | "Generation limit reached. Please try again later." |

### 4.2 Validation Errors

| Error Code | Description | HTTP Status | Retry | User Message |
|------------|-------------|-------------|-------|--------------|
| VAL-001 | Brand score below threshold | 422 | No | "Brand score [X]/10 is below minimum 8.0. [Specific feedback]" |
| VAL-002 | Security vulnerability detected | 422 | No | "Security violation: [vulnerability type] detected" |
| VAL-003 | Inappropriate content generated | 422 | No | "Content blocked by guardrails. Please modify your request." |
| VAL-004 | Brand guidelines not configured | 200 (warning) | No | "Brand guidelines not configured. Using default scoring." |
| VAL-005 | Accessibility violation (WCAG) | 422 | No | "Accessibility issue: [violation details]" |

### 4.3 Deployment Errors

| Error Code | Description | HTTP Status | Retry | User Message |
|------------|-------------|-------------|-------|--------------|
| DEP-001 | Prerequisites not met | 400 | No | "Deployment blocked - [prerequisite] not satisfied" |
| DEP-002 | S3 deployment failed | 500 | Yes | "Deployment failed. Retrying automatically." |
| DEP-003 | CloudFront invalidation failed | 500 | Yes | "CDN update pending. Changes may take a few minutes." |
| DEP-004 | DNS update failed | 500 | Yes | "DNS configuration failed. Please try again." |
| DEP-005 | Performance threshold failed | 422 | No | "Performance below threshold. [Optimization suggestions]" |
| DEP-006 | Queue congestion | 202 | Auto | "Deployment queued - estimated wait: [X] minutes" |

### 4.4 Agent Errors

| Error Code | Description | HTTP Status | Retry | User Message |
|------------|-------------|-------------|-------|--------------|
| AGT-001 | Stable Diffusion unavailable | 503 | Yes | "Image generation service unavailable. Please try again." |
| AGT-002 | Image generation blocked (content) | 422 | No | "Generated image blocked by content filters. Please modify request." |
| AGT-003 | Newsletter SES integration failed | 500 | Yes | "Email service error. Please try again." |
| AGT-004 | Blog generation off-topic | 422 | No | "Content drifted from topic. Please provide refined brief." |

### 4.5 Tenant/Auth Errors

| Error Code | Description | HTTP Status | Retry | User Message |
|------------|-------------|-------------|-------|--------------|
| AUTH-001 | Invalid/expired JWT | 401 | No | "Session expired. Please log in again." |
| AUTH-002 | Insufficient permissions | 403 | No | "You do not have permission for this action" |
| AUTH-003 | Tenant not found | 404 | No | "Organization not found" |
| AUTH-004 | Cross-tenant access attempt | 403 | No | "You do not have access to this team's resources" |
| AUTH-005 | Invitation expired | 400 | No | "Invitation has expired. Contact your admin for a new invitation." |

---

## 5. Tenant Isolation Requirements

### 5.1 Data Isolation

| Requirement | Implementation | Source |
|-------------|----------------|--------|
| Tenant ID in all requests | `tenant_id` path parameter required on all tenant-scoped endpoints | HLD Appendix F |
| JWT tenant claim | `tenant_id` validated in JWT claims on every request | HLD 6.2 |
| DynamoDB partition | All tenant data partitioned by `tenant_id` | Derived |
| S3 bucket prefix | All assets stored with `tenant_id/` prefix | Derived |
| Cross-tenant access block | Requests to other tenant data return 403 | US-017 |

### 5.2 Knowledge Base Isolation

| Requirement | Implementation | Source |
|-------------|----------------|--------|
| Per-tenant knowledge bases | No cross-contamination between tenant data | HLD 6.5 |
| Brand assets isolation | Each tenant has separate brand asset storage | US-002 |
| Template isolation | Tenant-specific templates separate from defaults | US-002 |
| Generation history isolation | Each tenant sees only their generation history | US-004 |

### 5.3 Organization Hierarchy

| Level | Description | Access Scope |
|-------|-------------|--------------|
| Organisation | Top-level tenant entity | All divisions, groups, teams |
| Division | Business unit within org | All groups, teams in division |
| Group | Functional group | All teams in group |
| Team | Working unit | Team resources only |
| User | Individual | Assigned teams only |

**Access Rules**:
- User can belong to multiple teams (US-018)
- User from Team A cannot access Team B data unless invited (US-017)
- Team leads can add/remove members within their team (US-017)
- Last admin cannot be removed from team (US-017)

### 5.4 Tenant Management Endpoints

| Endpoint | Purpose | Access Level |
|----------|---------|--------------|
| `POST /v1/tenants/{tenant_id}` | Create organization | System Admin |
| `GET /v1/tenants/{tenant_id}` | Get organization details | Org Admin+ |
| `PUT /v1/tenants/{tenant_id}` | Update organization | Org Admin |
| `DELETE /v1/tenants/{tenant_id}` | Delete organization | System Admin |
| `POST /v1/user/invitation` | Invite user to org | Org Admin, Team Lead |
| `GET /v1/tenants/{tenant_id}/teams/{team_id}/members` | List team members | Team Lead+ |
| `POST /v1/tenants/{tenant_id}/teams/{team_id}/members` | Add team member | Team Lead+ |
| `DELETE /v1/tenants/{tenant_id}/teams/{team_id}/members/{user_id}` | Remove team member | Team Lead+ |

---

## 6. Security Requirements

### 6.1 Authentication Requirements

| Requirement | Implementation | Source |
|-------------|----------------|--------|
| Authentication provider | Amazon Cognito User Pools | HLD 6.1 |
| Token type | JWT | HLD 6.2 |
| MFA support | Optional MFA via Cognito | HLD 6.2 |
| Token validation | API Gateway validates JWT | HLD 6.2 |
| Session management | Cognito handles session lifecycle | Derived |
| OTP verification | Required for customer data access | HLD 6.2 |

### 6.2 Authorization Requirements

| Requirement | Implementation | Source |
|-------------|----------------|--------|
| RBAC | Cognito groups + custom claims | HLD 6.2 |
| Tenant isolation | `tenant_id` in JWT claims validated on all requests | HLD 6.2 |
| Role hierarchy | Admin > Team Lead > User | US-015 to US-018 |
| Permission enforcement | IAM role-based access control | HLD 6.1 |
| Audit logging | All customer data interactions logged | HLD 6.6 |
| Delete restrictions | Roles assumed by customers have no delete rights | HLD 6.6 |

### 6.3 Data Protection Requirements

| Requirement | Implementation | Source |
|-------------|----------------|--------|
| Encryption at rest | S3 SSE-S3, DynamoDB encryption | HLD 6.3 |
| Encryption in transit | TLS 1.2+ for all connections | HLD 6.3 |
| PII masking | Customer data masked in logs | HLD 6.3 |
| Backup encryption | Cross-region backup vault encrypted | HLD 6.3 |
| Secrets management | AWS Secrets Manager for API keys | HLD 6.1 |

### 6.4 API Security Requirements

| Requirement | Implementation | Source |
|-------------|----------------|--------|
| WAF protection | AWS WAF with OWASP Top 10 rules | HLD 6.1, 6.4 |
| Rate limiting | Per-user API rate limits via WAF | HLD 6.4 |
| DDoS protection | AWS Shield | HLD 6.1 |
| IP blocking | WAF IP reputation lists | HLD 6.4 |
| Threat detection | AWS GuardDuty | HLD 6.1 |

### 6.5 GenAI Security Requirements

| Requirement | Implementation | Source |
|-------------|----------------|--------|
| LLM Guardrails | Bedrock Guardrails for input/output validation | HLD 6.5 |
| Prompt injection prevention | Input sanitization, system prompt protection | HLD 6.5 |
| Content moderation | Stable Diffusion output filtering | BRS 4.2 |
| Red team testing | Quarterly adversarial testing | HLD 6.5 |
| Knowledge base isolation | Per-tenant, no cross-contamination | HLD 6.5 |
| Security validator | All generated code scanned for XSS/injection | US-006 |

### 6.6 Compliance Requirements

| Requirement | Implementation | Source |
|-------------|----------------|--------|
| POPIA compliance | Data residency in af-south-1 | BRS 4.5 |
| AI transparency | Usage logged and auditable | BRS 4.5 |
| Penetration testing | Quarterly scheduled | HLD 6.6 |
| Audit trail | All generations logged for compliance | BRS 4.5 |

---

## 7. API Endpoint Summary

### 7.1 Core Generation API

| Endpoint | Method | Description | Priority |
|----------|--------|-------------|----------|
| `/v1/sites/{tenant_id}/generation` | POST | Start page generation | Critical |
| `/v1/sites/{tenant_id}/generation/{id}` | GET | Get generation status | Critical |
| `/v1/sites/{tenant_id}/generation/{id}/advisor` | POST | Conversational refinement | High |
| `/v1/sites/{tenant_id}/generation/{id}/versions` | GET | List version history | High |
| `/v1/sites/{tenant_id}/generation/{id}/versions/{version}` | POST | Restore version | High |

### 7.2 Agent API

| Endpoint | Method | Description | AI Model | Priority |
|----------|--------|-------------|----------|----------|
| `/v1/sites/{tenant_id}/agents/outline` | POST | Page structure outline | Claude Sonnet 4.5 | High |
| `/v1/sites/{tenant_id}/agents/logo` | POST | Logo generation | Stable Diffusion XL | High |
| `/v1/sites/{tenant_id}/agents/background` | POST | Background image generation | Stable Diffusion XL | High |
| `/v1/sites/{tenant_id}/agents/theme` | POST | Color theme suggestions | Claude Sonnet 4.5 | High |
| `/v1/sites/{tenant_id}/agents/blog` | POST | Blog content generation | Claude Sonnet 4.5 | High |
| `/v1/sites/{tenant_id}/agents/layout` | POST | Responsive layout generation | Claude Sonnet 4.5 | High |
| `/v1/sites/{tenant_id}/agents/newsletter` | POST | Newsletter generation | Claude Sonnet 4.5 + SES | High |

### 7.3 Validation API

| Endpoint | Method | Description | Priority |
|----------|--------|-------------|----------|
| `/v1/sites/{tenant_id}/generation/{id}/validate/brand` | POST | Brand compliance scoring | Critical |
| `/v1/sites/{tenant_id}/generation/{id}/validate/security` | POST | Security vulnerability scan | Critical |
| `/v1/sites/{tenant_id}/generation/{id}/validate/performance` | POST | Performance validation | High |

### 7.4 Deployment API

| Endpoint | Method | Description | Priority |
|----------|--------|-------------|----------|
| `/v1/sites/{tenant_id}/deployments` | POST | Create deployment | High |
| `/v1/sites/{tenant_id}/deployments` | GET | List deployments | High |
| `/v1/sites/{tenant_id}/deployments/{id}` | GET | Get deployment status | High |
| `/v1/sites/{tenant_id}/deployments/{id}/performance` | POST | Run performance tests | High |
| `/v1/sites/{tenant_id}/dns` | GET, PUT | DNS management | High |
| `/v1/sites/{tenant_id}/files` | GET, POST | File management | Medium |

### 7.5 Analytics API

| Endpoint | Method | Description | Priority |
|----------|--------|-------------|----------|
| `/v1/sites/{tenant_id}/analytics/components` | GET | Component performance | High |
| `/v1/sites/{tenant_id}/analytics/costs` | GET | AI generation costs | High |

### 7.6 Templates API

| Endpoint | Method | Description | Priority |
|----------|--------|-------------|----------|
| `/v1/sites/{tenant_id}/templates` | GET | List templates | Critical |
| `/v1/sites/{tenant_id}/templates/{id}` | GET | Get template details | High |

### 7.7 Migration API

| Endpoint | Method | Description | Priority |
|----------|--------|-------------|----------|
| `/v1/migrations/{tenant_id}` | POST | Start migration | Medium |
| `/v1/migrations/{tenant_id}` | GET | List migrations | Medium |
| `/v1/migrations/{tenant_id}/{migration_id}` | GET | Get migration status | Medium |

### 7.8 Prompt Management API

| Endpoint | Method | Description | Priority |
|----------|--------|-------------|----------|
| `/v1/prompts/{tenant_id}` | GET, POST | Manage prompts | Medium |

---

## 8. Traceability Matrix

| Requirement ID | User Story | API Endpoint | Priority | Status |
|----------------|------------|--------------|----------|--------|
| REQ-GEN-001 | US-001 | POST /generation | Critical | Mapped |
| REQ-GEN-002 | US-002 | GET /templates | Critical | Mapped |
| REQ-REF-001 | US-003 | POST /generation/{id}/advisor | High | Mapped |
| REQ-REF-002 | US-004 | GET /generation/{id}/versions | High | Mapped |
| REQ-VAL-001 | US-005 | POST /validate/brand | Critical | Mapped |
| REQ-VAL-002 | US-006 | POST /validate/security | Critical | Mapped |
| REQ-DEP-001 | US-007 | POST /deployments | High | Mapped |
| REQ-DEP-002 | US-008 | POST /deployments/{id}/performance | High | Mapped |
| REQ-ANL-001 | US-009 | GET /analytics/components | High | Mapped |
| REQ-ANL-002 | US-010 | GET /analytics/costs | High | Mapped |
| REQ-AGT-001 | US-011 | POST /agents/logo | High | Mapped |
| REQ-AGT-002 | US-012 | POST /agents/background | High | Mapped |
| REQ-AGT-003 | US-013 | POST /agents/theme | High | Mapped |
| REQ-AGT-004 | US-014 | POST /agents/outline | High | Mapped |
| REQ-TNT-001 | US-015 | POST /tenants | High | Mapped |
| REQ-TNT-002 | US-016 | POST /user/invitation | High | Mapped |
| REQ-TNT-003 | US-017 | /teams/{id}/members | High | Mapped |
| REQ-TNT-004 | US-018 | GET /user/{tenant}/teams | High | Mapped |
| REQ-MIG-001 | US-019 | POST /migrations | Medium | Mapped |
| REQ-MIG-002 | US-020 | POST /migrations | Medium | Mapped |
| REQ-MIG-003 | US-021 | GET /migrations/{id} | Medium | Mapped |
| REQ-AGT-005 | US-022 | POST /agents/blog | High | Mapped |
| REQ-AGT-006 | US-023 | POST /agents/layout | High | Mapped |
| REQ-AGT-007 | US-024 | POST /agents/newsletter | High | Mapped |

---

## 9. Summary Statistics

| Category | Count |
|----------|-------|
| Total User Stories | 24 |
| Critical Priority | 4 (US-001, US-002, US-005, US-006) |
| High Priority | 17 |
| Medium Priority | 3 (US-019, US-020, US-021) |
| API Endpoints (Generation) | 5 |
| API Endpoints (Agents) | 7 |
| API Endpoints (Validation) | 3 |
| API Endpoints (Deployment) | 6 |
| API Endpoints (Other) | 7 |
| **Total API Endpoints** | **28** |
| Error Codes Defined | 25 |
| NFR Performance Targets | 10 |
| Security Requirements | 20+ |

---

**End of Document**
