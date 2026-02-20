# HLD Analysis - Site Builder Bedrock Generation API

**Source Document**: `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/HLDs/3.0_BBSW_Site_Builder_HLD.md`
**Analysis Date**: 2026-01-15
**HLD Version**: 2.0
**Analyzed By**: Requirements Analysis Worker (Stage 1)

---

## 1. Lambda Agents Identified

### 1.1 Site Designer Multi-Agent System Overview

The HLD defines a comprehensive multi-agent system organized into functional groups:

| Agent Group | Agents | Count |
|-------------|--------|-------|
| Core Agents | Site Generator Agent, Build Advisor Agent | 2 |
| Themes, Colours and Layouts | Theme Selector, Layout Manager, Templates Selector | 3 |
| Image Creating Agents | Logo Creator, BG Image Creator | 2 |
| Writer Agents | Blogger, Newsletter Writer | 2 |
| Validation Agents | Website Validator, Design Scorer, Security Validator | 3 |
| Packaging and Deployment | Site Packager, Site Deployer, Site Stager | 3 |
| **Total Agents** | | **15** |

### 1.2 Detailed Agent Specifications

#### 1.2.1 Core Agents

| Agent | Lambda Component | Service(s) | User Stories | Purpose |
|-------|------------------|------------|--------------|---------|
| **Site Generator Agent** | `Lambda SiteGenerator` | Lambda, API Gateway, Bedrock | US-001 to US-003 | Orchestrates page generation from natural language prompts |
| **Build Advisor Agent** | `Lambda AdvisorService` | Lambda, Bedrock | US-003 | Provides conversational feedback and iterative refinement guidance |

#### 1.2.2 Themes, Colours and Layouts Agents

| Agent | Lambda Component | Service(s) | User Stories | Purpose | Inputs | Outputs |
|-------|------------------|------------|--------------|---------|--------|---------|
| **Outliner Agent** | `Lambda Agent Outliner` | Lambda, Bedrock Claude | US-014 | Proposes page structure before full generation | User requirements, site context | Page structure outline, section breakdown |
| **Theme Selector Agent** | `Lambda Agent Theme Selector` | Lambda, Bedrock Claude | US-013 | Suggests cohesive color themes for professional design | Brand guidelines, page type | Color palette, theme configuration |
| **Layout Agent** | `Lambda Agent Layout` | Lambda, Bedrock Claude | US-023 | Creates responsive grid-based page layouts | Page purpose, section requirements | Grid layout, responsive breakpoints |
| **Templates Selector Agent** | `Lambda TemplatesService` | Lambda, S3 | US-002 | Selects and assembles pre-approved templates | Brand assets, design requirements | Template configuration, component mapping |

#### 1.2.3 Image Creating Agents

| Agent | Lambda Component | Service(s) | User Stories | Purpose | Inputs | Outputs |
|-------|------------------|------------|--------------|---------|--------|---------|
| **Logo Creator Agent** | `Lambda Agent Logo Creator` | Lambda, Bedrock SD XL | US-011 | Generates professional logos for landing pages | Brand identity, style preferences | Logo images (multiple options) |
| **Background Image Creator Agent** | `Lambda Agent Background Image Creator` | Lambda, Bedrock SD XL | US-012 | Generates background images matching page theme | Image requirements, theme context | Background images via Stable Diffusion XL |

#### 1.2.4 Writer Agents

| Agent | Lambda Component | Service(s) | User Stories | Purpose | Inputs | Outputs |
|-------|------------------|------------|--------------|---------|--------|---------|
| **Blogger Agent** | `Lambda Agent Blogger` | Lambda, Bedrock Claude | US-022 | Generates SEO-optimized blog posts and articles | Topic/brief, keywords, tone | Blog content, meta descriptions |
| **Newsletter Agent** | `Lambda Agent Newsletter` | Lambda, Bedrock Claude, SES | US-024 | Creates email-optimized newsletter templates and content | Newsletter brief, subscriber context | Email-optimized HTML, content |

#### 1.2.5 Validation Agents

| Agent | Lambda Component | Service(s) | User Stories | Purpose | Inputs | Outputs |
|-------|------------------|------------|--------------|---------|--------|---------|
| **Website Validator Agent** | `Lambda WebsiteValidator` | Lambda | US-005, US-006, US-008 | Validates overall website quality and performance | Generated HTML/CSS/JS | Validation report, performance metrics |
| **Design Scorer Agent (Brand Consistency)** | `Lambda BrandConsistencyScorer` | Lambda, Bedrock Claude | US-005 | Scores brand compliance (8/10 minimum threshold) | Generated page, brand guidelines | Score (0-10), detailed feedback |
| **Security Validator Agent** | `Lambda SecurityScanner` | Lambda | US-006 | Scans for XSS, injection attacks, vulnerabilities | Generated code | Security scan results, vulnerability list |

#### 1.2.6 Packaging and Deployment Agents

| Agent | Lambda Component | Service(s) | User Stories | Purpose | Inputs | Outputs |
|-------|------------------|------------|--------------|---------|--------|---------|
| **Site Packager Agent** | `Lambda SitePackager` | Lambda, SQS | US-007 | Packages generated site assets for deployment | Generated assets, configuration | Packaged site bundle, GitHub commit |
| **Site Deployer Agent** | `Lambda SiteDeployer` | Lambda, S3, CloudFront | US-007 | Deploys sites to S3 hosting with CDN | Packaged site, deployment config | Deployed site URL, CloudFront distribution |
| **Site Stager Agent** | `Lambda SiteStager` | Lambda, S3 | US-007 | Stages sites in preview environment | Packaged site | Staging URL, preview link |

### 1.3 Supporting Lambda Functions

| Component | Service(s) | User Stories | Purpose |
|-----------|------------|--------------|---------|
| `Lambda TenantManagement` | Lambda, API Gateway | US-015 | Organisation CRUD operations |
| `Lambda UserManagement` | Lambda, API Gateway | US-016 to US-018 | User invitation, roles, team membership |
| `Lambda AdminService` | Lambda, API Gateway | US-015 to US-017 | Back-office administration |
| `Lambda DNSManagement` | Lambda, Route 53 | US-007 | DNS record management |
| `Lambda MigrationService` | Lambda, API Gateway | US-019 to US-021 | Legacy site migration orchestration |
| `Lambda WordPressParser` | Lambda | US-019 | WordPress content extraction |
| `Lambda HTMLCleaner` | Lambda | US-019, US-020 | HTML sanitization and cleanup |
| `Lambda PromptManagement` | Lambda, S3 | US-002 | Prompt library management |
| `Lambda AnalyticsService` | Lambda, CloudWatch | US-009, US-010 | Usage metrics and cost tracking |

---

## 2. AI Model Requirements

### 2.1 Claude Sonnet 4.5 (Text Generation)

| Attribute | Specification |
|-----------|---------------|
| **Provider** | Amazon Bedrock |
| **Model ID** | `anthropic.claude-sonnet-4-5` |
| **Primary Use Cases** | US-001 to US-003, US-005, US-013, US-014, US-022, US-023, US-024 |
| **Token Estimates** | ~5,000 tokens per generation (HLD Section 5.2) |
| **Monthly Volume** | 10,000 generations |
| **Estimated Cost** | R15,000/month |

#### Claude Sonnet 4.5 Use Cases

| Use Case | Agent | Token Estimate | Description |
|----------|-------|----------------|-------------|
| Page Structure Outlining | Outliner Agent | ~1,500 tokens | Generate page structure from requirements |
| Theme Selection | Theme Selector Agent | ~800 tokens | Analyze and suggest color themes |
| Layout Generation | Layout Agent | ~1,200 tokens | Create responsive grid layouts |
| Blog Content Generation | Blogger Agent | ~3,000 tokens | SEO-optimized article creation |
| Newsletter Content | Newsletter Agent | ~2,000 tokens | Email-optimized content |
| Brand Scoring | Design Scorer Agent | ~1,000 tokens | Evaluate brand compliance |
| Conversational Refinement | Advisor Agent | ~1,500 tokens | Iterative feedback processing |
| Full Site Generation | Site Generator Agent | ~5,000 tokens | Complete page generation |

#### Token Limits and Parameters

| Parameter | Recommended Value | Notes |
|-----------|-------------------|-------|
| `max_tokens` | 4,096 - 8,192 | Depends on use case |
| `temperature` | 0.7 (creative) / 0.3 (structured) | Lower for layouts, higher for content |
| `top_p` | 0.9 | Standard sampling |
| `top_k` | 250 | Standard sampling |
| Response Streaming | Enabled | TTLT ~1 minute target |

### 2.2 Claude Haiku (Preview/Draft Generation)

| Attribute | Specification |
|-----------|---------------|
| **Provider** | Amazon Bedrock |
| **Model ID** | `anthropic.claude-haiku` |
| **Primary Use Cases** | US-001 (preview generation) |
| **Token Estimates** | ~2,000 tokens per preview |
| **Monthly Volume** | 20,000 previews |
| **Estimated Cost** | R2,000/month |
| **Use Case** | Quick drafts and previews (10x cheaper than Sonnet) |

### 2.3 Stable Diffusion XL (Image Generation)

| Attribute | Specification |
|-----------|---------------|
| **Provider** | Amazon Bedrock |
| **Model ID** | `stability.stable-diffusion-xl-v1` |
| **Primary Use Cases** | US-011 (Logo Creator), US-012 (Background Image Creator) |
| **Monthly Volume** | 5,000 image generations |
| **Estimated Cost** | R5,000/month |

#### Image Generation Parameters

| Parameter | Logo Generation | Background Images | Notes |
|-----------|-----------------|-------------------|-------|
| **Image Size** | 512x512, 1024x1024 | 1024x1024, 1024x768, 768x1024 | Multiple aspect ratios |
| **Steps** | 30-50 | 40-60 | Higher for quality |
| **CFG Scale** | 7-10 | 7-9 | Prompt adherence |
| **Style Preset** | `enhance`, `photographic` | `photographic`, `digital-art` | Context-dependent |
| **Negative Prompt** | `blurry, low quality, text` | `text, watermark, low quality` | Quality assurance |
| **Seed** | Variable | Variable | For reproducibility |
| **Sampler** | `K_DPMPP_2M` | `K_DPMPP_2M` | Recommended sampler |

#### Supported Image Dimensions (SD XL)

| Aspect Ratio | Dimensions | Use Case |
|--------------|------------|----------|
| 1:1 | 512x512, 768x768, 1024x1024 | Logos, icons, square backgrounds |
| 16:9 | 1024x576, 1344x768 | Hero backgrounds, banners |
| 9:16 | 576x1024, 768x1344 | Mobile backgrounds |
| 4:3 | 1024x768 | Standard backgrounds |
| 3:4 | 768x1024 | Portrait backgrounds |

---

## 3. DynamoDB Requirements

### 3.1 DynamoDB Tables Summary

| Table Name | Service | User Stories | Purpose |
|------------|---------|--------------|---------|
| `Tenants` | DynamoDB Global Tables | US-015 | Organisation hierarchy (Org/Division/Group/Team) |
| `Users` | DynamoDB Global Tables | US-016 to US-018 | User profiles, roles, team membership |
| `Sites` | DynamoDB Global Tables | US-001, US-002, US-007 | Generated site metadata |
| `Generation` | DynamoDB Global Tables | US-001, US-003, US-004, US-021 | State management for site generation |
| `Prompts` | DynamoDB Global Tables | US-002 | Prompt library and templates |
| `Migrations` | DynamoDB Global Tables | US-019 to US-021 | Migration job tracking |
| `Templates` | DynamoDB Global Tables | US-002, US-011 to US-013 | Design templates metadata |

### 3.2 Detailed Table Schemas

#### 3.2.1 Tenants Table

```
Table Name: bbws-sitebuilder-tenants-{env}
Capacity Mode: On-Demand
Global Tables: Enabled (af-south-1, eu-west-1)

Primary Key:
  - PK: tenant_id (String)
  - SK: entity_type#entity_id (String)

GSI-1:
  - PK: org_id (String)
  - SK: hierarchy_path (String)

Attributes:
  - tenant_id: Unique tenant identifier
  - org_id: Organisation ID
  - entity_type: TENANT | DIVISION | GROUP | TEAM
  - entity_id: Entity unique identifier
  - name: Entity display name
  - hierarchy_path: Full path (org/division/group/team)
  - destination_email: Form submission email (required)
  - created_at: ISO 8601 timestamp
  - updated_at: ISO 8601 timestamp
  - status: ACTIVE | SUSPENDED | DELETED
```

#### 3.2.2 Users Table

```
Table Name: bbws-sitebuilder-users-{env}
Capacity Mode: On-Demand
Global Tables: Enabled (af-south-1, eu-west-1)

Primary Key:
  - PK: user_id (String)
  - SK: tenant_id#team_id (String)

GSI-1 (Email Lookup):
  - PK: email (String)
  - SK: user_id (String)

GSI-2 (Team Members):
  - PK: tenant_id#team_id (String)
  - SK: user_id (String)

Attributes:
  - user_id: Cognito sub
  - email: User email (required, mandatory)
  - tenant_id: Associated tenant
  - team_ids: List of team memberships
  - role: ADMIN | EDITOR | VIEWER
  - cognito_username: Cognito username
  - invited_by: User ID of inviter
  - invitation_status: PENDING | ACCEPTED | EXPIRED
  - created_at: ISO 8601 timestamp
  - last_login: ISO 8601 timestamp
```

#### 3.2.3 Sites Table

```
Table Name: bbws-sitebuilder-sites-{env}
Capacity Mode: On-Demand
Global Tables: Enabled (af-south-1, eu-west-1)

Primary Key:
  - PK: tenant_id (String)
  - SK: site_id (String)

GSI-1 (By Status):
  - PK: tenant_id (String)
  - SK: status#created_at (String)

Attributes:
  - tenant_id: Owner tenant
  - site_id: Unique site identifier
  - name: Site display name
  - status: DRAFT | STAGING | DEV | SIT | PROD
  - template_id: Base template used
  - generation_id: Associated generation job
  - version: Semantic version
  - s3_staging_uri: Staging bucket path
  - s3_hosting_uri: Production hosting path
  - cloudfront_distribution_id: CDN distribution
  - domain: Custom domain (optional)
  - brand_score: Last validation score (0-10)
  - created_at: ISO 8601 timestamp
  - updated_at: ISO 8601 timestamp
  - created_by: User ID
```

#### 3.2.4 Generation Table (State Management)

```
Table Name: bbws-sitebuilder-generation-{env}
Capacity Mode: On-Demand
Global Tables: Enabled (af-south-1, eu-west-1)

Primary Key:
  - PK: tenant_id (String)
  - SK: generation_id (String)

GSI-1 (Active Jobs):
  - PK: status (String)
  - SK: created_at (String)

Attributes:
  - tenant_id: Owner tenant
  - generation_id: Unique job identifier
  - site_id: Target site
  - status: QUEUED | PROCESSING | VALIDATING | COMPLETED | FAILED | TIMEOUT
  - prompt: Original user prompt
  - refined_prompt: AI-processed prompt
  - agent_states: Map of agent execution states
  - brand_score: Validation result
  - security_scan_result: PASS | FAIL | PENDING
  - error_message: Failure details (if any)
  - retry_count: Number of retries
  - created_at: ISO 8601 timestamp
  - started_at: ISO 8601 timestamp
  - completed_at: ISO 8601 timestamp
  - ttl: Expiration time (for cleanup)
```

#### 3.2.5 Prompts Table

```
Table Name: bbws-sitebuilder-prompts-{env}
Capacity Mode: On-Demand
Global Tables: Enabled (af-south-1, eu-west-1)

Primary Key:
  - PK: tenant_id (String)
  - SK: prompt_id (String)

GSI-1 (System Prompts):
  - PK: category (String)
  - SK: prompt_name (String)

Attributes:
  - tenant_id: SYSTEM | tenant_id
  - prompt_id: Unique identifier
  - prompt_name: Human-readable name
  - category: SYSTEM | TEMPLATE | CUSTOM
  - agent_type: Target agent
  - prompt_template: Prompt text with placeholders
  - variables: List of expected variables
  - version: Prompt version
  - created_at: ISO 8601 timestamp
  - updated_at: ISO 8601 timestamp
```

#### 3.2.6 Migrations Table

```
Table Name: bbws-sitebuilder-migrations-{env}
Capacity Mode: On-Demand
Global Tables: Enabled (af-south-1, eu-west-1)

Primary Key:
  - PK: tenant_id (String)
  - SK: migration_id (String)

Attributes:
  - tenant_id: Owner tenant
  - migration_id: Unique job identifier
  - source_type: WORDPRESS | STATIC_HTML | SQUARESPACE
  - source_url: Original site URL
  - status: QUEUED | EXTRACTING | PROCESSING | DEPLOYING | COMPLETED | FAILED
  - progress_percentage: 0-100
  - extracted_pages: Count of pages found
  - migrated_pages: Count of pages processed
  - error_log: List of errors
  - created_at: ISO 8601 timestamp
  - completed_at: ISO 8601 timestamp
```

#### 3.2.7 Templates Table

```
Table Name: bbws-sitebuilder-templates-{env}
Capacity Mode: On-Demand
Global Tables: Enabled (af-south-1, eu-west-1)

Primary Key:
  - PK: category (String)
  - SK: template_id (String)

GSI-1 (By Tenant):
  - PK: tenant_id (String)
  - SK: template_id (String)

Attributes:
  - template_id: Unique identifier
  - tenant_id: SYSTEM | tenant_id
  - category: LANDING_PAGE | BLOG | NEWSLETTER | COMPONENT
  - name: Template display name
  - description: Template description
  - s3_uri: Template assets location
  - thumbnail_uri: Preview image
  - components: List of component IDs
  - brand_compatible: Boolean
  - created_at: ISO 8601 timestamp
```

### 3.3 DynamoDB Configuration Requirements

| Configuration | Value | Rationale |
|---------------|-------|-----------|
| Capacity Mode | On-Demand | Per CLAUDE.md requirements |
| Point-in-Time Recovery | Enabled | Data protection |
| Encryption | AWS owned key (default) | Cost optimization |
| Global Tables | Enabled | Multi-region DR (af-south-1, eu-west-1) |
| Backup Frequency | Hourly | RPO: 1 hour |
| Stream | Enabled | Cross-region replication, event triggers |
| TTL | Enabled on Generation table | Auto-cleanup of old jobs |

---

## 4. S3 Requirements

### 4.1 S3 Buckets Summary

| Bucket Purpose | Environment Pattern | User Stories | CRR |
|----------------|---------------------|--------------|-----|
| Design Assets | `bbws-design-assets-{env}-{region}` | US-002, US-011, US-012 | Yes |
| Generated Pages | `bbws-generated-pages-{env}-{region}` | US-001, US-004 | Yes |
| Site Hosting | `bbws-site-hosting-{env}-{region}` | US-007 | No (CDN) |
| Staging | `bbws-staging-{env}-{region}` | US-007 | No |
| Prompt Library | `bbws-prompts-{env}-{region}` | US-002 | Yes |
| Projects | `bbws-projects-{env}-{region}` | Site assets | Yes |

### 4.2 Detailed Bucket Specifications

#### 4.2.1 Design Assets Bucket

```
Bucket Name: bbws-design-assets-{env}-{region}
Purpose: Store brand assets, logos, images, design components

Structure:
  /{tenant_id}/
    /logos/
      /{logo_id}.png
    /backgrounds/
      /{image_id}.png
    /brand/
      /colors.json
      /fonts/
      /guidelines.pdf
    /components/
      /{component_id}/

Configuration:
  - Public Access: BLOCKED (per CLAUDE.md)
  - Versioning: Enabled
  - Encryption: SSE-S3
  - Lifecycle: Intelligent-Tiering after 90 days
  - CRR: Enabled to eu-west-1
  - CORS: Restricted to CloudFront
```

#### 4.2.2 Generated Pages Bucket

```
Bucket Name: bbws-generated-pages-{env}-{region}
Purpose: Store generated HTML/CSS/JS before deployment

Structure:
  /{tenant_id}/
    /{site_id}/
      /{version}/
        /index.html
        /assets/
          /css/
          /js/
          /images/
        /manifest.json

Configuration:
  - Public Access: BLOCKED
  - Versioning: Enabled
  - Encryption: SSE-S3
  - Lifecycle: Delete after 30 days (staging)
  - CRR: Enabled to eu-west-1
```

#### 4.2.3 Site Hosting Bucket

```
Bucket Name: bbws-site-hosting-{env}-{region}
Purpose: Production static website hosting via CloudFront

Structure:
  /{tenant_id}/
    /{site_id}/
      /index.html
      /assets/
      /robots.txt
      /sitemap.xml

Configuration:
  - Public Access: BLOCKED (CloudFront OAI only)
  - Versioning: Enabled
  - Encryption: SSE-S3
  - Static Website Hosting: Disabled (CloudFront handles)
  - CloudFront OAI: Required for access
```

#### 4.2.4 Staging Bucket

```
Bucket Name: bbws-staging-{env}-{region}
Purpose: Preview sites before deployment

Structure:
  /{tenant_id}/
    /{site_id}/
      /{generation_id}/
        /index.html
        /assets/

Configuration:
  - Public Access: BLOCKED
  - Versioning: Disabled
  - Encryption: SSE-S3
  - Lifecycle: Delete after 7 days
  - Pre-signed URLs: For preview access
```

#### 4.2.5 Prompt Library Bucket

```
Bucket Name: bbws-prompts-{env}-{region}
Purpose: Store system and custom prompts

Structure:
  /system/
    /agents/
      /outliner.txt
      /logo-creator.txt
      /theme-selector.txt
      /...
  /{tenant_id}/
    /custom/
      /{prompt_id}.txt

Configuration:
  - Public Access: BLOCKED
  - Versioning: Enabled
  - Encryption: SSE-S3
  - CRR: Enabled to eu-west-1
```

### 4.3 S3 Security Requirements

| Requirement | Implementation |
|-------------|----------------|
| Public Access | BLOCKED on ALL buckets (per CLAUDE.md) |
| Encryption at Rest | SSE-S3 |
| Encryption in Transit | TLS 1.2+ |
| Access Control | IAM policies + bucket policies |
| CloudFront Access | Origin Access Identity (OAI) |
| Cross-Region Replication | Enabled for DR buckets |

---

## 5. SQS Requirements

### 5.1 SQS Queues Summary

| Queue | Purpose | User Stories |
|-------|---------|--------------|
| Generation Queue | Site generation job processing | US-001, US-007 |
| Generation DLQ | Failed generation job handling | All |
| Deployment Queue | Site deployment orchestration | US-007 |
| Deployment DLQ | Failed deployment handling | US-007 |
| Staging Queue | Preview site staging | US-007 |
| Staging DLQ | Failed staging handling | US-007 |
| Packager Queue | Site packaging jobs | US-007 |
| Packager DLQ | Failed packaging handling | US-007 |

### 5.2 Detailed Queue Specifications

#### 5.2.1 Generation Queue

```
Queue Name: bbws-sitebuilder-generation-{env}
Type: Standard
Purpose: Process site generation requests asynchronously

Configuration:
  - Visibility Timeout: 300 seconds (5 minutes)
  - Message Retention: 4 days
  - Receive Message Wait Time: 20 seconds (long polling)
  - Max Receive Count: 3 (before DLQ)
  - DLQ: bbws-sitebuilder-generation-dlq-{env}

Message Format:
{
  "tenant_id": "string",
  "generation_id": "string",
  "site_id": "string",
  "prompt": "string",
  "template_id": "string",
  "priority": "STANDARD|HIGH",
  "requested_at": "ISO8601",
  "requested_by": "user_id"
}
```

#### 5.2.2 Deployment Queue

```
Queue Name: bbws-sitebuilder-deployment-{env}
Type: Standard
Purpose: Orchestrate site deployments

Configuration:
  - Visibility Timeout: 180 seconds (3 minutes)
  - Message Retention: 4 days
  - Receive Message Wait Time: 20 seconds
  - Max Receive Count: 3
  - DLQ: bbws-sitebuilder-deployment-dlq-{env}

Message Format:
{
  "tenant_id": "string",
  "site_id": "string",
  "version": "string",
  "target_environment": "DEV|SIT|PROD",
  "source_bucket": "string",
  "source_key": "string",
  "requested_at": "ISO8601",
  "requested_by": "user_id"
}
```

#### 5.2.3 Staging Queue

```
Queue Name: bbws-sitebuilder-staging-{env}
Type: Standard
Purpose: Process site staging for preview

Configuration:
  - Visibility Timeout: 120 seconds (2 minutes)
  - Message Retention: 1 day
  - Max Receive Count: 3
  - DLQ: bbws-sitebuilder-staging-dlq-{env}
```

#### 5.2.4 Packager Queue

```
Queue Name: bbws-sitebuilder-packager-{env}
Type: Standard
Purpose: Package site assets for deployment

Configuration:
  - Visibility Timeout: 180 seconds (3 minutes)
  - Message Retention: 4 days
  - Max Receive Count: 3
  - DLQ: bbws-sitebuilder-packager-dlq-{env}
```

### 5.3 Dead Letter Queue Configuration

All DLQs follow consistent configuration:

```
DLQ Pattern: bbws-sitebuilder-{service}-dlq-{env}
Purpose: Capture failed messages for analysis and retry

Configuration:
  - Message Retention: 14 days
  - CloudWatch Alarm: Message count > 0
  - SNS Notification: On message arrival
  - Manual Review: Required before retry

DLQ Processing:
  1. Alert via SNS to operations team
  2. Log to CloudWatch for analysis
  3. Store in DynamoDB for tracking
  4. Manual retry or discard decision
```

### 5.4 SQS Error Handling Strategy

| Scenario | Handling | Retry Strategy |
|----------|----------|----------------|
| Transient Error | Auto-retry | Exponential backoff (per CLAUDE.md) |
| Processing Timeout | Return to queue | Up to max receive count |
| Max Retries Exceeded | Move to DLQ | Manual intervention |
| Invalid Message | Move to DLQ | No auto-retry |
| Bedrock Throttling | Return to queue | Exponential backoff |

---

## 6. API Endpoints (from HLD Appendix F)

### 6.1 Complete API Endpoint List

| Service | Endpoint | Method | Description | Auth Required |
|---------|----------|--------|-------------|---------------|
| **Tenants** | `/v1/tenants/{tenant_id}` | GET | Get tenant details | Yes |
| **Tenants** | `/v1/tenants/{tenant_id}` | PUT | Update tenant | Yes (Admin) |
| **Tenants** | `/v1/tenants/{tenant_id}` | DELETE | Delete tenant | Yes (Admin) |
| **Admin** | `/v1/admin/{tenant_id}` | GET | Get admin data | Yes (Admin) |
| **Admin** | `/v1/admin/{tenant_id}` | POST | Create admin resource | Yes (Admin) |
| **Users** | `/v1/user/registration` | POST | Register new user/org | No |
| **Users** | `/v1/user/forgot/password` | POST | Password reset | No |
| **Users** | `/v1/user/{tenant}` | GET | Get user profile | Yes |
| **Users** | `/v1/user/{tenant}` | PUT | Update user profile | Yes |
| **Users** | `/v1/user/invitation` | POST | Send invitation | Yes (Admin) |
| **Sites** | `/v1/sites/{tenant_id}/templates` | GET | List templates | Yes |
| **Sites** | `/v1/sites/{tenant_id}/generation` | POST | Start generation | Yes |
| **Sites** | `/v1/sites/{tenant_id}/generation/{id}/advisor` | POST | AI advisor | Yes |
| **Sites** | `/v1/sites/{tenant_id}/dns` | GET | Get DNS settings | Yes |
| **Sites** | `/v1/sites/{tenant_id}/dns` | PUT | Update DNS settings | Yes (Admin) |
| **Sites** | `/v1/sites/{tenant_id}/files` | GET | List site files | Yes |
| **Sites** | `/v1/sites/{tenant_id}/files` | POST | Upload site files | Yes |
| **Sites** | `/v1/sites/{tenant_id}/deployments` | GET | List deployments | Yes |
| **Sites** | `/v1/sites/{tenant_id}/deployments` | POST | Create deployment | Yes |
| **Migrations** | `/v1/migrations/{tenant_id}` | GET | List migrations | Yes |
| **Migrations** | `/v1/migrations/{tenant_id}` | POST | Start migration | Yes |
| **Prompts** | `/v1/prompts/{tenant_id}` | GET | List prompts | Yes |
| **Prompts** | `/v1/prompts/{tenant_id}` | POST | Create prompt | Yes |

### 6.2 API Endpoint Categories

| Category | Endpoints | Description |
|----------|-----------|-------------|
| Tenant Management | 3 | Organisation CRUD |
| Admin | 2 | Back-office operations |
| User Management | 5 | Registration, auth, invitations |
| Site Generation | 8 | Templates, generation, deployment |
| Migration | 2 | Legacy site migration |
| Prompts | 2 | Prompt library management |
| **Total** | **22** | |

### 6.3 API Gateway Configuration

| Configuration | Value |
|---------------|-------|
| Protocol | REST (API Gateway REST API) |
| Authentication | Amazon Cognito User Pool |
| Authorization | JWT validation + custom authorizer |
| Throttling | Per-user rate limits via WAF |
| CORS | Restricted to allowed origins |
| Stage Variables | `{env}` for DEV/SIT/PROD |

---

## 7. Brand Scoring Requirements

### 7.1 Scoring Categories (from Appendix D)

| Category | Max Points | Evaluation Criteria |
|----------|------------|---------------------|
| Color Palette Compliance | 2.0 | Match brand colors (primary, secondary, accent) |
| Typography Compliance | 1.5 | Correct fonts, sizes, weights |
| Logo Usage | 1.5 | Presence, placement, clear space |
| Layout & Spacing | 1.5 | Grid consistency, margins, padding |
| Component Style Consistency | 1.5 | Buttons, forms, cards match library |
| Imagery & Iconography | 1.0 | Visual style consistency |
| Content Tone & Voice | 1.0 | Copy matches brand voice |
| **Total** | **10.0** | |

### 7.2 Thresholds and Actions

| Score Range | Status | Automated Action |
|-------------|--------|------------------|
| 9.0 - 10.0 | Excellent | Auto-approve for deployment |
| 8.0 - 8.9 | Acceptable | Approve with recommendations |
| 6.0 - 7.9 | Needs Work | Block deployment, provide feedback |
| 0.0 - 5.9 | Rejected | Regeneration required |

### 7.3 Production Requirements

| Requirement | Value |
|-------------|-------|
| Minimum Production Threshold | **8.0/10** |
| Minimum Staging Threshold | 8.0/10 |
| Re-validation Required | On any content change |
| Feedback Detail Level | Per-category breakdown |

### 7.4 Brand Scoring Implementation

```
Agent: Design Scorer Agent (Lambda BrandConsistencyScorer)
Model: Bedrock Claude Sonnet 4.5
Input:
  - Generated HTML/CSS
  - Brand guidelines document
  - Component library reference
  - Previous site examples (optional)

Output:
{
  "total_score": 8.5,
  "category_scores": {
    "color_palette": 2.0,
    "typography": 1.3,
    "logo_usage": 1.5,
    "layout_spacing": 1.2,
    "component_style": 1.2,
    "imagery": 0.8,
    "content_tone": 0.5
  },
  "status": "ACCEPTABLE",
  "recommendations": [
    "Typography: Consider increasing heading font weight",
    "Content: Tone could be more aligned with brand voice"
  ],
  "blocking_issues": []
}
```

---

## 8. Environment Workflow

### 8.1 Environment Promotion Flow (from Appendix E)

```
┌─────────────────────────────────────────────────────────────────┐
│                    ENVIRONMENT PROMOTION                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   [Generation]                                                  │
│       │                                                         │
│       ▼                                                         │
│   [Staging] ──────► Brand Score >= 8.0? ──No──► Regenerate     │
│       │                    │                                    │
│       │                   Yes                                   │
│       ▼                    │                                    │
│   [DEV] ◄─────────────────┘                                    │
│       │                                                         │
│       │   Unit Tests Pass?                                      │
│       │        │                                                │
│       ▼       Yes                                               │
│   [SIT] ◄──────┘                                               │
│       │                                                         │
│       │   Integration Tests Pass?                               │
│       │        │                                                │
│       ▼       Yes                                               │
│   [PROD] ◄─────┘  (Read-Only Deployment)                       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 8.2 Stage Details

| Stage | Trigger | Authority | Validation | Access Mode |
|-------|---------|-----------|------------|-------------|
| Staging | Automated by tool | System | Brand score >= 8.0, Security scan pass | Read-Write |
| DEV | Manual deployment | Developer | Unit tests pass | Read-Write |
| SIT | Manual promotion | Tester | Integration tests pass | Read-Write |
| PROD | Manual promotion | Business Owner | UAT complete, all approvals | **Read-Only** |

### 8.3 Critical Constraints

| Constraint | Description | Source |
|------------|-------------|--------|
| DEV-First Fixes | All defects must be fixed in DEV first | CLAUDE.md |
| Promotion Path | Changes flow DEV → SIT → PROD only | CLAUDE.md |
| PROD Read-Only | Production allows read-only deployments | CLAUDE.md, HLD |
| No Hardcoding | Environment credentials must be parameterized | CLAUDE.md |
| Consistency | Fix in DEV, promote to SIT for consistency | CLAUDE.md |

### 8.4 Environment Configuration Pattern

```
Environment Variables (parameterized per CLAUDE.md):
  - AWS_REGION: af-south-1 (prod), eu-west-1 (DR)
  - ENVIRONMENT: dev | sit | prod
  - BEDROCK_MODEL_ID: anthropic.claude-sonnet-4-5
  - DYNAMODB_TABLE_PREFIX: bbws-sitebuilder-{table}-{env}
  - S3_BUCKET_PREFIX: bbws-{purpose}-{env}-{region}
  - SQS_QUEUE_PREFIX: bbws-sitebuilder-{service}-{env}

Terraform Pattern:
  - Separate scripts per microservice (per CLAUDE.md)
  - Environment passed as variable
  - No hardcoded credentials
```

---

## 9. Additional Requirements Identified

### 9.1 Disaster Recovery Requirements

| Metric | Value | Source |
|--------|-------|--------|
| Primary Region | af-south-1 (South Africa) | CLAUDE.md |
| Failover Region | eu-west-1 (Ireland) | CLAUDE.md |
| DR Strategy | Multisite Active/Active | CLAUDE.md |
| RPO | 1 hour | HLD TBC-005 |
| RTO | 1 minute | HLD TBC-006 |
| DynamoDB Backup | Hourly | CLAUDE.md |
| S3 Replication | Cross-region (CRR) | CLAUDE.md |

### 9.2 Performance Requirements

| Metric | Target | Source |
|--------|--------|--------|
| Page Generation Time | 10-15 seconds | HLD Section 1.2 |
| API Response (non-gen) | 10ms | HLD TBC-002 |
| TTLT (streaming) | 1 minute | HLD TBC-002 |
| Concurrent Users | 500 | HLD Section 5.1 |

### 9.3 Monitoring Requirements (per CLAUDE.md)

| Requirement | Implementation |
|-------------|----------------|
| Failed Transactions | CloudWatch alarms |
| Stuck Transactions | State management monitoring |
| Lost Transactions | DLQ monitoring + SNS alerts |
| Error Notifications | SNS topic |
| Dead Letter Queues | Enabled on all queues |
| Retry Strategy | Exponential backoff |

### 9.4 Multi-Tenant Hierarchy

```
Organisation Hierarchy (from CLAUDE.md, HLD):
  Organisation
    └── Division
        └── Group
            └── Team
                └── User

Access Control:
  - Users can belong to multiple teams
  - Team A user cannot access Team B data unless invited
  - Admin can create, modify, list sites
  - Admin can invite users and allocate roles
  - Required fields: organisation, destination_email, user_email
```

---

## 10. Summary Statistics

| Category | Count |
|----------|-------|
| Total Lambda Agents | 15 |
| Supporting Lambda Functions | 9 |
| DynamoDB Tables | 7 |
| S3 Buckets | 6 |
| SQS Queues (including DLQs) | 8 |
| API Endpoints | 22 |
| AI Models | 3 |
| Environments | 4 (Staging, DEV, SIT, PROD) |

---

**Analysis Complete**

This document serves as the foundation for the LLD development of the Site Builder Bedrock Generation API. All specifications are derived from the HLD v2.0 and supplemented with requirements from the project CLAUDE.md files.
