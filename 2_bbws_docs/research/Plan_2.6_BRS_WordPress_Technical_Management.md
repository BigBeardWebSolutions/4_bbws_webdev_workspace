# Comprehensive Plan for BRS 2.6: WordPress Technical Management

**Version**: 1.4
**Created**: 2026-01-05
**Target Document**: `BRS/2.6_BRS_WordPress_Technical_Management.md`
**Integration Method**: WordPress REST API
**Container Architecture**: One ECS Task per Tenant (WordPress Multisite)
**Status**: Plan Ready for Review

---

## 1. Executive Summary

### 1.1 What is WordPress Technical Management?

**WordPress Technical Management** is the API layer that exposes WordPress functionality to consumers (Customer Portal Private, Admin Portal). It serves as the interface between frontend applications and the underlying WordPress infrastructure managed by the ECS WordPress Hosting Platform.

This BRS covers **four distinct domains**:
1. **Sites API** - WordPress site CRUD operations, configuration, and lifecycle management
2. **Templates API** - WordPress site template management and application
3. **Plugins API** - WordPress plugin marketplace and per-site plugin management
4. **SQS - WP Site Creator** - Asynchronous site creation via event-driven architecture

### 1.2 Key Differentiators from Other APIs

| API | Scope | Primary Consumer |
|-----|-------|------------------|
| **WordPress Technical Management (This BRS)** | Sites, Templates, Plugins, Async Creation | Customer Portal Private, Admin Portal |
| **Tenant Management (BRS 2.5)** | Organisation/Tenant management, User invitations | Customer Portal Private, Admin Portal |
| **WordPress Tenant Mgmt API (BRS 2.7)** | Infrastructure provisioning (ECS, RDS, EFS) | Internal agents, backend orchestration |

### 1.3 Business Value

- **Self-Service Site Management**: Customers create and manage WordPress sites without BBWS staff intervention
- **Template Standardization**: Consistent site creation through approved templates
- **Plugin Ecosystem**: Managed plugin installation with security vetting
- **Scalable Creation**: SQS-based async processing handles high-volume site creation

#### Value-Add Features Beyond Basic ISP Hosting

> **Note:** The following capabilities differentiate BBWS from commodity ISP/WordPress hosting providers and represent significant customer value-add:
>
> | Feature | Value Beyond Basic Hosting |
> |---------|---------------------------|
> | **Site Management API** | Self-service site creation, cloning, promotion between environments (DEV→SIT→PROD) - not available in basic hosting |
> | **Template Marketplace** | Pre-built, vetted templates with one-click application - reduces time-to-launch from days to minutes |
> | **Plugin Management** | Curated plugin marketplace with security scanning, compatibility checking, and managed updates - eliminates plugin security risks |
> | **Domain Parking/Unparking** | Cost-saving feature to stop containers for inactive tenants while preserving data - customers only pay for active usage |
> | **Environment Promotion** | Built-in DEV→SIT→PROD workflow with backups - enterprise-grade deployment pipeline |
> | **Health Monitoring** | Integrated site health checks and alerts - proactive issue detection |
>
> These features transform BBWS from a hosting provider into a **managed WordPress platform**, commanding premium pricing and increasing customer retention through platform lock-in via value, not restriction.

### 1.4 Integration Architecture: WordPress REST API

This module integrates with WordPress instances using the **native WordPress REST API** (`/wp-json/wp/v2/`).

#### Why WordPress REST API?

| Benefit | Description |
|---------|-------------|
| Native to WordPress | Built-in, well-documented, maintained by WordPress core team |
| RESTful Interface | Standard HTTP methods, JSON responses, easy to integrate |
| No Additional Dependencies | No custom plugins or CLI tools required |
| Secure | Supports JWT and Application Passwords authentication |
| Widely Adopted | Industry standard for WordPress integrations |

#### Architecture Overview

**Security: Internal Only - Not Exposed to Outside World**

The WordPress REST API is accessible **only** through internal Lambda functions via the private ALB. It is **never exposed** to the public internet.

```
┌─────────────────────────────────────────────────────────────────┐
│                      Customer Portal                             │
│                   (Public - Internet Facing)                     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ HTTPS (Public API Gateway)
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│              WordPress Technical Management API                  │
│                    (Lambda Functions)                           │
│                      [VPC Connected]                            │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ HTTPS (Private - VPC Only)
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                 Internal ALB (Private Subnets)                   │
│                   [Not Internet Accessible]                      │
└─────────────────────────────────────────────────────────────────┘
                              │
            ┌─────────────────┼─────────────────┐
            │                 │                 │
            ▼                 ▼                 ▼
     ┌───────────┐     ┌───────────┐     ┌───────────┐
     │  Tenant A │     │  Tenant B │     │  Tenant C │
     │ WordPress │     │ WordPress │     │ WordPress │
     │   (ECS)   │     │   (ECS)   │     │   (ECS)   │
     │ /wp-json/ │     │ /wp-json/ │     │ /wp-json/ │
     └───────────┘     └───────────┘     └───────────┘
            │                 │                 │
            └─────────────────┴─────────────────┘
                     Private Subnets Only
```

**Access Path:** `Lambda (VPC) → Internal ALB → ECS → WordPress REST API`

**Security Controls:**
- ALB is in private subnets (no internet gateway)
- Security groups allow only Lambda → ALB → ECS traffic
- WordPress `/wp-json/` endpoint not publicly accessible
- Application Passwords stored in Secrets Manager

#### WordPress REST API Endpoints Used

| Operation | WP REST Endpoint | HTTP Method |
|-----------|------------------|-------------|
| **Content Management** | | |
| List posts | `/wp-json/wp/v2/posts` | GET |
| Create post | `/wp-json/wp/v2/posts` | POST |
| Update post | `/wp-json/wp/v2/posts/{id}` | PUT |
| Delete post | `/wp-json/wp/v2/posts/{id}` | DELETE |
| List pages | `/wp-json/wp/v2/pages` | GET |
| Create page | `/wp-json/wp/v2/pages` | POST |
| **Media Management** | | |
| List media | `/wp-json/wp/v2/media` | GET |
| Upload media | `/wp-json/wp/v2/media` | POST |
| **User Management** | | |
| List users | `/wp-json/wp/v2/users` | GET |
| Create user | `/wp-json/wp/v2/users` | POST |
| **Site Settings** | | |
| Get settings | `/wp-json/wp/v2/settings` | GET |
| Update settings | `/wp-json/wp/v2/settings` | POST |
| **Plugins** (requires plugin) | | |
| List plugins | `/wp-json/wp/v2/plugins` | GET |
| Install plugin | `/wp-json/wp/v2/plugins` | POST |
| Activate plugin | `/wp-json/wp/v2/plugins/{plugin}` | PUT |
| **Themes** (requires plugin) | | |
| List themes | `/wp-json/wp/v2/themes` | GET |
| Activate theme | `/wp-json/wp/v2/themes/{theme}` | PUT |

#### Authentication Method

**Application Passwords** (WordPress 5.6+):

```http
GET /wp-json/wp/v2/posts
Authorization: Basic base64(username:application_password)
```

| Aspect | Implementation |
|--------|----------------|
| Method | HTTP Basic Auth with Application Passwords |
| Storage | Application password stored in AWS Secrets Manager |
| Per-Tenant | Each tenant WordPress has dedicated application password |
| Rotation | Passwords rotated via Secrets Manager rotation Lambda |
| Scope | Full REST API access for management operations |

#### Required WordPress Plugins

| Plugin | Purpose | Required |
|--------|---------|----------|
| **Application Passwords** | Built into WP 5.6+ | Core |
| **WP REST API Controller** | Extended plugin/theme management | Yes |
| **JWT Authentication** | Alternative auth method | Optional |

#### Limitations & Mitigations

| Limitation | Mitigation |
|------------|------------|
| Plugin install not in core REST API | Install `WP REST API Controller` plugin on all sites |
| Theme switching limited | Use settings endpoint + custom REST extension |
| No direct database access | Use WordPress options API via REST |
| Rate limiting per site | Implement request queuing in Lambda |

### 1.5 Container Architecture: One Task per Tenant

**Decision:** Each **Tenant** (WordPress installation) runs in its own dedicated ECS Fargate task. Sites are managed within WordPress Multisite.

```
┌─────────────────────────────────────────────────────────────┐
│                        Customer A                            │
└─────────────────────────────────────────────────────────────┘
        │                                    │
        ▼                                    ▼
┌─────────────────────┐            ┌─────────────────────┐
│     Tenant 1        │            │     Tenant 2        │
│  (ECS Task 1)       │            │  (ECS Task 2)       │
│  WordPress Instance │            │  WordPress Instance │
│  ┌───────────────┐  │            │  ┌───────────────┐  │
│  │ Site A        │  │            │  │ Site D        │  │
│  │ Site B        │  │            │  │ Site E        │  │
│  │ Site C        │  │            │  └───────────────┘  │
│  └───────────────┘  │            │  (Multisite)        │
│  (Multisite)        │            └─────────────────────┘
└─────────────────────┘
```

#### Entity Relationships

| Entity | Maps To | Cardinality |
|--------|---------|-------------|
| **Customer/Organisation** | Cognito User Pool | 1 customer : many tenants |
| **Tenant** | ECS Task + WordPress Instance | 1:1:1 |
| **Site** | WordPress Multisite Site | 1 tenant : many sites |

#### Why One Task per Tenant?

| Benefit | Description |
|---------|-------------|
| **Tenant Isolation** | Each WordPress instance isolated at container level |
| **Cost Efficiency** | Multiple sites share one container (WordPress Multisite) |
| **Flexible Scaling** | Customers can add tenants for more isolation/resources |
| **Park/Unpark at Tenant Level** | Stop entire WordPress instance to save costs |
| **Resource Allocation** | CPU/memory per tenant based on subscription tier |

#### Cost Implications

| Tier | vCPU | Memory | Sites per Tenant | Est. Cost/Tenant/Month |
|------|------|--------|------------------|------------------------|
| Basic | 0.25 | 0.5 GB | Up to 5 | ~$8-10 |
| Standard | 0.5 | 1 GB | Up to 20 | ~$15-20 |
| Premium | 1.0 | 2 GB | Up to 50 | ~$30-40 |
| Enterprise | 2.0 | 4 GB | Unlimited | ~$60-80 |
| Parked | 0 | 0 | N/A | $0 |

#### ECS Service per Tenant

Each tenant has a dedicated ECS Service:
- Service Name: `bbws-wp-{tenantId}-{env}`
- Desired Count: `1` (active) or `0` (parked/suspended)
- Task Definition: `bbws-wp-task-{tier}`

> **Note:** Parking/unparking operates at the **Tenant level** (managed by BRS 2.5 Tenant Management), not at the individual site level. When a tenant is parked, all sites within that WordPress instance become unavailable.

---

## 2. Scope Definition

### 2.1 In Scope

**Domain 1: Sites API**
- Create WordPress site
- Update WordPress site configuration
- Get site details
- List sites (by tenant/organisation)
- Delete/archive site
- Suspend/activate site
- Clone site
- Site status management (PROVISIONING, ACTIVE, SUSPENDED, DEPROVISIONING, FAILED)
- Park/unpark tenant (stop/start ECS container) - *See BRS 2.5 Tenant Management*
- Environment management (DEV, SIT, PROD)
- Environment promotion workflow

**Domain 2: Templates API**
- List available templates
- Get template details
- Create template (admin only)
- Update template
- Delete template (soft delete)
- Apply template to site
- Preview template

**Domain 3: Plugins API**
- List available plugins (marketplace)
- Install plugin to site
- Uninstall plugin from site
- Configure plugin settings
- Update plugin version
- Enable/disable plugin
- Plugin compatibility checking
- Security vulnerability scanning

**Domain 4: SQS - WP Site Creator**
- Async site creation request submission
- Site creation status polling
- Site creation completion notification
- Dead letter queue handling
- Retry policies with exponential backoff
- Event publishing for downstream consumers

### 2.2 Out of Scope

| Category | Handled By |
|----------|------------|
| Tenant Organisation Management | Tenant API (BRS 2.5) |
| Infrastructure Provisioning | WordPress Tenant Management API (BRS 2.7) |
| User Authentication | Cognito |
| Billing and Payments | Billing Service |

---

## 3. Actors and Personas

| Actor | Description | API Access |
|-------|-------------|------------|
| **Tenant Admin** | Customer with admin role in their organisation | Full CRUD on their sites, apply templates, manage plugins |
| **Site Owner** | Customer who owns specific site(s) | Manage their assigned sites |
| **Team Member** | Customer with user role | Create/edit sites per permissions |
| **Viewer** | Read-only customer | View sites only |
| **Platform Admin** | BBWS staff (Admin Portal) | Cross-tenant site management, template creation |
| **System** | SQS consumers, automated processes | Async site creation, event processing |

### Cognito Groups Mapping

| Cognito Group | Sites API | Templates API | Plugins API | SQS |
|---------------|-----------|---------------|-------------|-----|
| CUSTOMER_SUPER_ADMIN | Full | Read + Apply | Full | Via API |
| CUSTOMER_ADMIN | Full | Read + Apply | Full | Via API |
| CUSTOMER_USER | Create/Edit/Read | Read + Apply | Read/Install | Via API |
| CUSTOMER_VIEWER | Read | Read | Read | N/A |
| super-admin (Staff) | Full Cross-Tenant | Full CRUD | Full | Monitor |

---

## 4. Domain 1: Sites API

### 4.1 Epics and User Stories

#### Epic: Site Lifecycle Management

**US-SITES-001: Create WordPress Site**

**User Story:**
> As a Tenant Admin,
> I want to create a new WordPress site,
> So that I can launch a new website for my business.

**Pre-conditions:**
- User is authenticated with valid JWT
- User has admin or user role in tenant
- Tenant has available site quota
- Active subscription exists

**Positive Scenario:**
1. Customer navigates to Sites page
2. Customer clicks "Create New Site"
3. Customer enters: site name, subdomain, template selection
4. FrontendUI calls Sites API POST `/v1.0/tenants/{tenantId}/sites`
5. Sites API validates request (quota, name uniqueness)
6. Sites API publishes SiteCreationRequest to SQS
7. Sites API returns 202 Accepted with siteId and status=PROVISIONING
8. SQS consumer processes async creation
9. Site status updates to ACTIVE when ready
10. Customer receives notification

**Negative Scenarios:**
- Site quota exceeded: Return 422 with message "Site limit reached for your plan"
- Subdomain taken: Return 409 with message "Subdomain is already in use"
- No active subscription: Return 402 with message "Active subscription required"

**Acceptance Criteria:**
- [ ] Site creation returns 202 Accepted with siteId
- [ ] Site status is initially PROVISIONING
- [ ] Subdomain uniqueness is validated
- [ ] Site quota is enforced per subscription tier
- [ ] SQS message is published for async processing
- [ ] Error messages MUST be clear and actionable

---

**US-SITES-002: Update Site Configuration**

**User Story:**
> As a Site Owner,
> I want to update my site configuration,
> So that I can customize site settings.

**Acceptance Criteria:**
- [ ] Only site owner or tenant admin can update
- [ ] Subdomain changes require DNS propagation warning
- [ ] Configuration changes are audited

---

**US-SITES-003: Get Site Details**

**User Story:**
> As a Customer,
> I want to view my site details,
> So that I can see current configuration and status.

**Response includes:**
- Site ID, name, subdomain
- Status (PROVISIONING/ACTIVE/SUSPENDED/FAILED)
- Environment (DEV/SIT/PROD)
- Template applied
- Plugins installed
- Health status

---

**US-SITES-004: List Sites**

**Acceptance Criteria:**
- [ ] Paginated list with status indicators
- [ ] Filter by status, environment
- [ ] Sort by name, created, updated

---

**US-SITES-005: Delete/Archive Site**

**Business Rules:**
- BR-SITES-001: PROD sites require 24-hour soft-delete before permanent removal
- BR-SITES-002: Backup is created before deletion
- BR-SITES-003: Only tenant admin can delete sites

---

**US-SITES-006: Suspend/Activate Site**

**Acceptance Criteria:**
- [ ] Suspended sites return 503 from CloudFront
- [ ] Site can be reactivated later

---

**US-SITES-007: Clone Site**

**Acceptance Criteria:**
- [ ] Database and files duplicated
- [ ] New site has new identifiers

---

**US-SITES-008: Promote Environment**

**Acceptance Criteria:**
- [ ] DEV can promote to SIT only
- [ ] SIT can promote to PROD only
- [ ] PROD cannot be promoted (read-only per CLAUDE.md)
- [ ] Backup created before promotion

---

**US-SITES-009: Park/Unpark Tenant** *(Cross-Reference: BRS 2.5 Tenant Management)*

> **Note:** Parking/unparking operates at the **Tenant level**, not the Site level. Since a Tenant = WordPress Instance = ECS Task, parking stops the entire WordPress container, making all sites within that tenant unavailable. This user story is documented here for context but is **implemented in BRS 2.5 Tenant Management**.

**User Story:**
> As a Tenant Admin,
> I want to park a tenant (WordPress instance) when it's not in use,
> So that I can reduce costs while preserving all sites for future use.

**Pre-conditions:**
- User is authenticated with valid JWT
- User has admin role in organisation
- Tenant exists and is in ACTIVE status (for parking)
- Tenant exists and is in PARKED status (for unparking)

**Park Tenant Flow:**
1. Customer navigates to Tenant details page
2. Customer clicks "Park Tenant"
3. System displays confirmation: "Parking will stop the WordPress instance. ALL sites in this tenant will be unavailable until unparked. Cold start takes 30-90 seconds."
4. Customer confirms
5. Frontend calls PUT `/v1.0/tenants/{tenantId}/park`
6. Tenant API sets tenant status to PARKED
7. Tenant API sets ECS service desiredCount to 0
8. ECS container stops gracefully
9. CloudFront returns static "Tenant Parked" page for all site requests
10. Customer sees success message

**Unpark Tenant Flow:**
1. Customer navigates to Tenant details page
2. Customer clicks "Unpark Tenant"
3. Frontend calls PUT `/v1.0/tenants/{tenantId}/unpark`
4. Tenant API sets ECS service desiredCount to 1
5. Tenant API sets tenant status to STARTING
6. ECS container starts (30-90 seconds)
7. ALB health check passes
8. Tenant API sets tenant status to ACTIVE
9. All sites within tenant become available
10. Customer receives notification when tenant is ready

**Acceptance Criteria:**
- [ ] Park sets ECS desiredCount to 0
- [ ] Unpark sets ECS desiredCount to 1
- [ ] Tenant status transitions: ACTIVE → PARKED → STARTING → ACTIVE
- [ ] CloudFront serves static parked page for all sites in tenant
- [ ] Cold start time < 90 seconds
- [ ] User notified when unparked tenant is ready
- [ ] Parked tenants incur $0 ECS compute cost

**Business Rules:**
- BR-TENANT-PARK-001: Parked tenants retain all data (EFS, database)
- BR-TENANT-PARK-002: All sites within parked tenant return "Tenant Parked" page
- BR-TENANT-PARK-003: Auto-unpark on first request (optional enhancement)

**See:** BRS 2.5 Tenant Management for full implementation details

---

### 4.2 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/v1.0/tenants/{tenantId}/sites` | Create new site |
| GET | `/v1.0/tenants/{tenantId}/sites` | List sites |
| GET | `/v1.0/tenants/{tenantId}/sites/{siteId}` | Get site details |
| PUT | `/v1.0/tenants/{tenantId}/sites/{siteId}` | Update site config |
| DELETE | `/v1.0/tenants/{tenantId}/sites/{siteId}` | Delete site |
| POST | `/v1.0/tenants/{tenantId}/sites/{siteId}/clone` | Clone site |
| PUT | `/v1.0/tenants/{tenantId}/sites/{siteId}/status` | Suspend/activate |
| POST | `/v1.0/tenants/{tenantId}/sites/{siteId}/promote` | Promote environment |
| GET | `/v1.0/tenants/{tenantId}/sites/{siteId}/health` | Get site health |
| POST | `/v1.0/tenants/{tenantId}/sites/{siteId}/backup` | Create backup |
| POST | `/v1.0/tenants/{tenantId}/sites/{siteId}/restore` | Restore from backup |

**Tenant-Level Endpoints (See BRS 2.5):**
| Method | Endpoint | Description |
|--------|----------|-------------|
| PUT | `/v1.0/tenants/{tenantId}/park` | Park tenant (stop container) |
| PUT | `/v1.0/tenants/{tenantId}/unpark` | Unpark tenant (start container) |

---

### 4.3 Site Data Model

```json
{
  "PK": "TENANT#{tenantId}",
  "SK": "SITE#{siteId}",
  "siteId": "uuid",
  "tenantId": "uuid",
  "siteName": "string",
  "subdomain": "string",
  "status": "PROVISIONING|ACTIVE|SUSPENDED|DEPROVISIONING|FAILED",
  "environment": "DEV|SIT|PROD",
  "templateId": "uuid|null",
  "wordpressVersion": "string",
  "phpVersion": "string",
  "createdAt": "ISO8601",
  "updatedAt": "ISO8601",
  "healthStatus": "HEALTHY|DEGRADED|UNHEALTHY|UNKNOWN"
}
```

---

## 5. Domain 2: Templates API

### 5.1 User Stories

**US-TEMP-001: List Available Templates**

**User Story:**
> As a Customer,
> I want to view available templates,
> So that I can choose a design for my new site.

**Response includes:**
- Template name, thumbnail, description
- Category (Business, Portfolio, Blog, E-commerce)
- Rating, usage count
- Preview link

---

**US-TEMP-002: Get Template Details**

**Response includes:**
- Full description, screenshots
- Included plugins
- Supported WordPress version
- Demo URL

---

**US-TEMP-003: Apply Template to Site**

**Acceptance Criteria:**
- [ ] Template compatibility validated
- [ ] Warning about data replacement
- [ ] Site theme and default content updated

---

**US-TEMP-004: Create Template (Admin Only)**

**Acceptance Criteria:**
- [ ] Admin uploads theme configuration
- [ ] Template saved as DRAFT
- [ ] Admin publishes when ready

---

**US-TEMP-005: Preview Template**

**Acceptance Criteria:**
- [ ] Demo site opens in new tab
- [ ] Demo has clear preview branding

---

### 5.2 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/v1.0/templates` | List templates |
| GET | `/v1.0/templates/{templateId}` | Get template details |
| POST | `/v1.0/tenants/{tenantId}/sites/{siteId}/apply-template` | Apply template |
| GET | `/v1.0/templates/{templateId}/preview` | Get preview URL |

**Admin Endpoints:**
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/admin/templates` | Create template |
| PUT | `/admin/templates/{templateId}` | Update template |
| DELETE | `/admin/templates/{templateId}` | Delete template |
| POST | `/admin/templates/{templateId}/publish` | Publish template |

---

### 5.3 Template Data Model

```json
{
  "PK": "TEMPLATE",
  "SK": "TEMPLATE#{templateId}",
  "templateId": "uuid",
  "name": "string",
  "description": "string",
  "category": "BUSINESS|PORTFOLIO|BLOG|ECOMMERCE|OTHER",
  "version": "string",
  "thumbnailUrl": "string",
  "demoUrl": "string",
  "status": "DRAFT|PUBLISHED|ARCHIVED",
  "minWordPressVersion": "string",
  "includedPlugins": ["pluginId"],
  "usageCount": "number",
  "createdAt": "ISO8601"
}
```

---

## 6. Domain 3: Plugins API

### 6.1 User Stories

**US-PLUG-001: List Available Plugins**

**Response includes:**
- Plugin name, description, icon
- Category (SEO, Security, Performance, Forms)
- Rating, install count
- Pricing (free or premium)
- Compatibility info

---

**US-PLUG-002: Install Plugin to Site**

**Acceptance Criteria:**
- [ ] Site is in ACTIVE status
- [ ] Plugin compatibility validated
- [ ] Security scan runs before install
- [ ] Plugin activated after install

**Negative Scenarios:**
- Plugin has known vulnerability: Return 422
- Incompatible version: Return 422
- Plugin conflicts: Return 409

---

**US-PLUG-003: Uninstall Plugin from Site**

**Acceptance Criteria:**
- [ ] Confirmation with data warning
- [ ] Plugin deactivated and removed

---

**US-PLUG-004: Configure Plugin Settings**

**Acceptance Criteria:**
- [ ] Configuration saved
- [ ] Plugin reconfigured

---

**US-PLUG-005: Update Plugin**

**Acceptance Criteria:**
- [ ] Plugin updated to latest version
- [ ] Site health validated after update

---

**US-PLUG-006: Enable/Disable Plugin**

**Acceptance Criteria:**
- [ ] Plugin activated or deactivated
- [ ] Status change reflected immediately

---

### 6.2 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/v1.0/plugins` | List marketplace |
| GET | `/v1.0/plugins/{pluginId}` | Get plugin details |
| GET | `/v1.0/tenants/{tenantId}/sites/{siteId}/plugins` | List installed |
| POST | `/v1.0/tenants/{tenantId}/sites/{siteId}/plugins` | Install plugin |
| DELETE | `/v1.0/tenants/{tenantId}/sites/{siteId}/plugins/{pluginId}` | Uninstall |
| PUT | `/v1.0/tenants/{tenantId}/sites/{siteId}/plugins/{pluginId}/config` | Configure |
| PUT | `/v1.0/tenants/{tenantId}/sites/{siteId}/plugins/{pluginId}/update` | Update |
| PUT | `/v1.0/tenants/{tenantId}/sites/{siteId}/plugins/{pluginId}/status` | Enable/disable |

---

### 6.3 Plugin Data Model

**Marketplace Plugin:**
```json
{
  "PK": "PLUGIN",
  "SK": "PLUGIN#{pluginId}",
  "pluginId": "uuid",
  "name": "string",
  "category": "SEO|SECURITY|PERFORMANCE|FORMS|ECOMMERCE|OTHER",
  "rating": "number (1-5)",
  "installCount": "number",
  "pricing": "FREE|PREMIUM",
  "isBlocklisted": "boolean",
  "lastSecurityScan": "ISO8601"
}
```

**Installed Plugin:**
```json
{
  "PK": "SITE#{siteId}",
  "SK": "PLUGIN#{pluginId}",
  "installedVersion": "string",
  "isActive": "boolean",
  "configuration": {},
  "installedAt": "ISO8601"
}
```

---

## 7. Domain 4: SQS - Async Site Operations

### 7.1 Architecture

```
                                    ┌──────────────────────────────┐
                                    │       Customer Portal         │
                                    └──────────────┬───────────────┘
                                                   │
                                                   ▼
                                    ┌──────────────────────────────┐
                                    │          Sites API            │
                                    └──────────────┬───────────────┘
                                                   │
                        ┌──────────────────────────┼──────────────────────────┐
                        │                          │                          │
                        ▼                          ▼                          ▼
          ┌─────────────────────┐    ┌─────────────────────┐    ┌─────────────────────┐
          │  Site Creation Queue │    │  Site Update Queue  │    │  Site Deletion Queue │
          └──────────┬──────────┘    └──────────┬──────────┘    └──────────┬──────────┘
                     │                          │                          │
                     ▼                          ▼                          ▼
          ┌─────────────────────┐    ┌─────────────────────┐    ┌─────────────────────┐
          │  Site Creator Lambda │    │  Site Updater Lambda │    │  Site Deleter Lambda │
          └──────────┬──────────┘    └──────────┬──────────┘    └──────────┬──────────┘
                     │                          │                          │
                     └──────────────────────────┼──────────────────────────┘
                                                │
                                                ▼
                                    ┌──────────────────────────────┐
                                    │     Dead Letter Queue (DLQ)   │
                                    └──────────────┬───────────────┘
                                                   │
                                                   ▼
                                    ┌──────────────────────────────┐
                                    │  CloudWatch Alarm → SNS → Ops │
                                    └──────────────────────────────┘
```

### 7.2 Queue Configuration

**Site Creation Queue:**
- Queue Name: `bbws-wp-site-creation-{env}`
- Visibility Timeout: 900 seconds (15 minutes)
- Message Retention: 4 days

**Site Update Queue:**
- Queue Name: `bbws-wp-site-update-{env}`
- Visibility Timeout: 600 seconds (10 minutes)
- Message Retention: 4 days

**Site Deletion Queue:**
- Queue Name: `bbws-wp-site-deletion-{env}`
- Visibility Timeout: 600 seconds (10 minutes)
- Message Retention: 4 days

**Dead Letter Queue (Shared):**
- Queue Name: `bbws-wp-site-operations-dlq-{env}`
- Max Receive Count: 3
- Message Retention: 14 days

**Retry Policy:**
- Exponential backoff: 1s, 2s, 4s, 8s... (capped at 5 minutes)
- Maximum retries: 3

---

### 7.3 User Stories

**US-SQS-001: Submit Async Site Creation**

**Flow:**
1. Sites API receives POST `/v1.0/tenants/{tenantId}/sites`
2. Sites API creates Site record with status=PROVISIONING
3. Sites API publishes SiteCreationRequest to SQS
4. Sites API returns 202 Accepted
5. Lambda provisions resources
6. Lambda updates Site status to ACTIVE
7. Lambda publishes completion event to SNS

---

**US-SQS-002: Poll Site Creation Status**

**Acceptance Criteria:**
- [ ] Customer polls GET `/v1.0/tenants/{tenantId}/sites/{siteId}`
- [ ] Returns PROVISIONING, ACTIVE, or FAILED

---

**US-SQS-003: Handle Creation Failure**

**Acceptance Criteria:**
- [ ] Retry 3 times with exponential backoff
- [ ] Move to DLQ after 3 failures
- [ ] CloudWatch alarm triggers
- [ ] Site status set to FAILED

---

**US-SQS-004: Receive Completion Notification**

**Acceptance Criteria:**
- [ ] SNS publishes SiteCreationComplete
- [ ] Notification Service emails customer

---

### 7.4 Message Schemas

**SiteCreationRequest:**
```json
{
  "messageType": "SITE_CREATION_REQUEST",
  "correlationId": "uuid",
  "timestamp": "ISO8601",
  "payload": {
    "siteId": "uuid",
    "tenantId": "uuid",
    "siteName": "string",
    "subdomain": "string",
    "templateId": "uuid|null",
    "environment": "DEV",
    "configuration": {
      "wordpressVersion": "6.5",
      "phpVersion": "8.2",
      "plugins": ["pluginId1"]
    }
  }
}
```

**SiteCreationComplete (SNS):**
```json
{
  "eventType": "SITE_CREATION_COMPLETE",
  "payload": {
    "siteId": "uuid",
    "tenantId": "uuid",
    "status": "ACTIVE",
    "siteUrl": "https://subdomain.wpdev.kimmyai.io",
    "provisioningDuration": 180
  }
}
```

---

## 8. Business Rules

### 8.1 Site Business Rules

| Rule ID | Rule |
|---------|------|
| BR-SITE-001 | Subdomain must be unique across all tenants |
| BR-SITE-002 | Subdomain: 3-63 characters, lowercase alphanumeric and hyphens |
| BR-SITE-003 | Site quota enforced per subscription tier |
| BR-SITE-004 | PROD sites require 24-hour soft-delete |
| BR-SITE-005 | Backup created before deletion |
| BR-SITE-006 | Only tenant admin can delete sites |
| BR-SITE-007 | Sites follow DEV -> SIT -> PROD promotion |
| BR-SITE-008 | PROD environment is read-only |

### 8.2 Template Business Rules

| Rule ID | Rule |
|---------|------|
| BR-TEMP-001 | Only PUBLISHED templates visible to customers |
| BR-TEMP-002 | Template cannot be deleted if in use |
| BR-TEMP-003 | Template version must follow semver |
| BR-TEMP-004 | Applying template replaces theme |
| BR-TEMP-005 | Template compatibility must be validated |

### 8.3 Plugin Business Rules

| Rule ID | Rule |
|---------|------|
| BR-PLUG-001 | Blocklisted plugins cannot be installed |
| BR-PLUG-002 | Security scan runs before installation |
| BR-PLUG-003 | Plugin conflicts must be detected |
| BR-PLUG-004 | Plugin updates preserve configuration |
| BR-PLUG-005 | Uninstall warns about data loss |

### 8.4 SQS Business Rules

| Rule ID | Rule |
|---------|------|
| BR-SQS-001 | Maximum 3 retries before DLQ |
| BR-SQS-002 | Exponential backoff between retries |
| BR-SQS-003 | DLQ messages trigger CloudWatch alarm |
| BR-SQS-004 | Site creation must complete within 15 minutes |
| BR-SQS-005 | Idempotency key prevents duplicates |

---

## 9. Non-Functional Requirements

### 9.1 Performance

| Requirement | Specification |
|-------------|---------------|
| API Response Time | < 500ms for 95th percentile |
| Site Creation Time | < 15 minutes end-to-end |
| Template List Load | < 2 seconds |
| Plugin Marketplace Load | < 2 seconds |
| Concurrent Site Creations | Support 10 simultaneous |

### 9.2 Security

| Aspect | Implementation |
|--------|----------------|
| Authentication | JWT from Cognito |
| Authorization | Tenant-scoped, role-based |
| Plugin Scanning | Automated vulnerability scan |
| Audit Logging | All CRUD operations logged |

### 9.3 Availability

| Metric | Target |
|--------|--------|
| API Availability | 99.9% |
| SQS Availability | 99.999% (AWS SLA) |
| RTO | 4 hours |
| RPO | 1 hour |

---

## 10. Error Handling

### 10.1 API Error Responses

| Status | Error Type |
|--------|------------|
| 400 | Bad Request |
| 401 | Unauthorized |
| 403 | Forbidden |
| 404 | Not Found |
| 409 | Conflict |
| 422 | Unprocessable Entity |
| 429 | Too Many Requests |
| 500 | Internal Server Error |
| 503 | Service Unavailable |

### 10.2 SQS Error Handling

| Error Type | Handling |
|------------|----------|
| Transient Failure | Retry with backoff |
| Permanent Failure | Move to DLQ after 3 attempts |
| Timeout | Extend visibility, retry |
| Malformed Message | Log, move to DLQ |

---

## 11. Document Sections Outline

```
1. Introduction
   1.1 Purpose
   1.2 Scope
   1.3 System Overview
   1.4 Use Case Diagrams
   1.5 Traceability Matrix

2. Stakeholders
   2.1 Actors and Personas
   2.2 Role Permissions Matrix

3. API Definitions
   3.1 Sites API Functions
   3.2 Templates API Functions
   3.3 Plugins API Functions
   3.4 SQS Lambda Functions

4. Epic 1: Site Management
   US-SITES-001 to US-SITES-009

5. Epic 2: Template Management
   US-TEMP-001 to US-TEMP-005

6. Epic 3: Plugin Management
   US-PLUG-001 to US-PLUG-006

7. Epic 4: Async Site Creation (SQS)
   US-SQS-001 to US-SQS-004

8. Business Rules

9. Non-Functional Requirements

10. Constraints

11. Assumptions and Risks

12. Glossary

13. Sign-Off

Appendix A: Screen Reference
Appendix B: API Endpoint Reference
Appendix C: Data Model Reference
Appendix D: Message Schema Reference
```

---

## 12. Effort Estimate (BRS Only)

| Domain | User Stories | Pages (Est.) | Complexity |
|--------|--------------|--------------|------------|
| Sites API | 9 | 18-22 | High |
| Templates API | 5 | 8-10 | Medium |
| Plugins API | 6 | 10-12 | Medium-High |
| SQS Async Site Operations | 4 | 8-10 | High |
| NFRs, Business Rules | - | 5-8 | Medium |
| Appendices | - | 5-8 | Low |
| **Total** | **24** | **54-70** | **High** |

---

## 13. Open Questions

### Sites API
1. Maximum number of sites per tenant per subscription tier?
2. Should site cloning preserve backup history?

### Templates API
1. Who can create templates? Only BBWS staff or customers too?
2. Should templates support versioning and rollback?

### Plugins API
1. Plugin marketplace source: WordPress.org, curated, or both?
2. How are premium plugins licensed?
3. Vulnerability database source?

### SQS
1. Status updates: WebSocket or polling?
2. Maximum queue depth before throttling?

---

## 14. References

| Document | Path |
|----------|------|
| 2.0_BRS_ECS_WordPress.md | `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/BRS/2.0_BRS_ECS_WordPress.md` |
| Site_Management_LLD.md | `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/Site_Management_LLD.md` |
| 2.2_BRS_Customer_Portal_Private.md | `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/BRS/2.2_BRS_Customer_Portal_Private.md` |
| 2.0_BBWS_ECS_WordPress_HLD.md | `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/HLDs/2.0_BBWS_ECS_WordPress_HLD.md` |
| 2.1_BRS_Customer_Portal_Public.md | `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/BRS/2.1_BRS_Customer_Portal_Public.md` |

---

## 15. Sub-Plans: Related Documentation

### 15.1 Sub-Plan A: Update HLD with Tenant-Task Architecture

**Target Document:** `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/HLDs/2.1_BBWS_Customer_Portal_Public_HLD_V1.1.md`

**Objective:** Add technical details about the Tenant = ECS Task architecture to the HLD.

**Sections to Add/Update:**

| Section | Content |
|---------|---------|
| Infrastructure | Add "Container Architecture: One Task per Tenant" diagram |
| Key Decisions | Add decision: "Tenant = WordPress Instance = ECS Task (1:1:1)" |
| Entity Relationships | Add Customer → Tenant → Site hierarchy |
| Cost Model | Add tier-based pricing (Basic/Standard/Premium/Enterprise) |
| Value-Add Features | Reference differentiators from commodity hosting |

**Content to Add:**

```markdown
### Container Architecture: One Task per Tenant

Each Tenant (WordPress installation) runs in a dedicated ECS Fargate task:

- **Customer/Organisation** → 1:many → **Tenants**
- **Tenant** → 1:1:1 → **ECS Task** + **WordPress Instance**
- **Tenant** → 1:many → **Sites** (WordPress Multisite)

Benefits:
- Tenant isolation at container level
- Cost control via parking/unparking
- Flexible scaling per tenant
- Sites share container resources efficiently
```

**Estimated Effort:** 1-2 hours

---

### 15.2 Sub-Plan B: Tenant Management LLD

**Target Document:** `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/2.5_Tenant_Management_LLD.md`

**Objective:** Create detailed Low-Level Design for Tenant Management API (BRS 2.5).

**LLD Sections:**

| Section | Content |
|---------|---------|
| 1. Overview | Purpose, scope, relation to BRS 2.5 |
| 2. Architecture | Lambda functions, DynamoDB tables, ECS integration |
| 3. API Design | OpenAPI spec for all tenant endpoints |
| 4. Data Model | DynamoDB schema with GSIs for tenant queries |
| 5. Lambda Functions | Function specifications per endpoint |
| 6. ECS Integration | Park/unpark implementation details |
| 7. State Machine | Tenant lifecycle (PENDING→ACTIVE→PARKED→SUSPENDED) |
| 8. Security | IAM roles, Cognito integration, tenant isolation |
| 9. Error Handling | Error codes, retry policies |
| 10. Monitoring | CloudWatch metrics, alarms, dashboards |

**Key Technical Details to Document:**

```
Lambdas:
- bbws-tenant-create-{env}
- bbws-tenant-get-{env}
- bbws-tenant-list-{env}
- bbws-tenant-update-{env}
- bbws-tenant-park-{env}
- bbws-tenant-unpark-{env}
- bbws-tenant-invite-user-{env}

DynamoDB Tables:
- bbws-tenants-{env} (PK: TENANT#{tenantId}, SK: METADATA)
- bbws-tenant-users-{env} (PK: TENANT#{tenantId}, SK: USER#{userId})

ECS Integration:
- AWS SDK calls to update ECS service desiredCount
- CloudWatch Events for status transitions
- SNS notifications for park/unpark completion
```

**Estimated Effort:** 8-12 hours

---

### 15.3 Sub-Plan C: WordPress Technical Management LLD

**Target Document:** `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/2.6_WordPress_Technical_Management_LLD.md`

**Objective:** Create detailed Low-Level Design for WordPress Technical Management (BRS 2.6).

**LLD Sections:**

| Section | Content |
|---------|---------|
| 1. Overview | Purpose, scope, relation to BRS 2.6 |
| 2. Architecture | Lambda functions, SQS queues, WordPress REST API integration |
| 3. Sites API | OpenAPI spec, Lambda implementations |
| 4. Templates API | OpenAPI spec, S3 storage for template assets |
| 5. Plugins API | OpenAPI spec, security scanning integration |
| 6. SQS Async Operations | Queue configurations, Lambda consumers |
| 7. WordPress REST API Integration | Internal ALB routing, authentication |
| 8. Data Model | DynamoDB schema for sites, templates, plugins |
| 9. Security | IAM roles, VPC configuration, Application Passwords |
| 10. Error Handling | Error codes, DLQ processing |
| 11. Monitoring | CloudWatch metrics, site health checks |

**Key Technical Details to Document:**

```
Lambdas - Sites API:
- bbws-site-create-{env}
- bbws-site-get-{env}
- bbws-site-list-{env}
- bbws-site-update-{env}
- bbws-site-delete-{env}
- bbws-site-clone-{env}
- bbws-site-promote-{env}

Lambdas - Templates API:
- bbws-template-list-{env}
- bbws-template-get-{env}
- bbws-template-apply-{env}

Lambdas - Plugins API:
- bbws-plugin-list-{env}
- bbws-plugin-install-{env}
- bbws-plugin-uninstall-{env}
- bbws-plugin-configure-{env}

Lambdas - SQS Consumers:
- bbws-site-creator-{env}
- bbws-site-updater-{env}
- bbws-site-deleter-{env}

SQS Queues:
- bbws-wp-site-creation-{env}
- bbws-wp-site-update-{env}
- bbws-wp-site-deletion-{env}
- bbws-wp-site-operations-dlq-{env}

WordPress REST API:
- Internal ALB: bbws-wp-internal-alb-{env}
- Target Groups per tenant
- Application Passwords in Secrets Manager
```

**Estimated Effort:** 12-16 hours

---

### 15.4 Sub-Plan Summary

| Sub-Plan | Document | Type | Version Prefix | Effort |
|----------|----------|------|----------------|--------|
| A | 2.1_BBWS_Customer_Portal_Public_HLD | HLD Update | 2.1 | 1-2 hrs |
| B | 2.5_Tenant_Management_LLD | New LLD | 2.5 | 8-12 hrs |
| C | 2.6_WordPress_Technical_Management_LLD | New LLD | 2.6 | 12-16 hrs |
| **Total** | | | | **21-30 hrs** |

**Dependencies:**
```
BRS 2.5 (Tenant Management) ──────┐
                                  ├──► LLD 2.5 (Tenant Management)
HLD 2.1 Update ◄──────────────────┘

BRS 2.6 (WP Technical Mgmt) ──────┬──► LLD 2.6 (WP Technical Management)
                                  │
BRS 2.7 (WP Tenant Mgmt) ─────────┘
```

**Recommended Execution Order:**
1. HLD 2.1 Update (foundation for all)
2. LLD 2.5 Tenant Management (tenant is foundation for sites)
3. LLD 2.6 WordPress Technical Management (depends on tenant)

---

**End of Plan**
