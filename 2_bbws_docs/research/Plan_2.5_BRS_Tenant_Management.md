# Comprehensive Plan for BRS 2.5: Tenant Management

**Version**: 1.1
**Created**: 2026-01-05
**Target Document**: `BRS/2.5_BRS_Tenant_Management.md`
**Codebase**: `/Users/tebogotseka/Documents/agentic_work/2_1_bbws_web_public`
**Status**: Plan Ready for Review

---

## 1. Executive Summary

### 1.1 What is Tenant Management?

The **Tenant Management** module is a core microservice for managing customer tenant organizations in the BBWS platform. It provides RESTful API endpoints for tenant CRUD operations, organization hierarchy management, user assignments, and tenant lifecycle state transitions.

**Key distinction**: Tenant Management handles the **logical tenant entity** (organization, hierarchy, metadata, users) - it does NOT handle WordPress-specific provisioning (which is covered by the WordPress Tenant Management API in BRS 2.7).

### 1.2 Business Value and Purpose

| Value Driver | Description |
|--------------|-------------|
| Self-Service Tenant Creation | Automate tenant onboarding reducing manual effort from 2+ hours to < 5 minutes |
| Organization Hierarchy | Support complex organizational structures (Division -> Group -> Team -> User) |
| Multi-Tenant Isolation | Logical separation of tenants enabling secure, isolated operations |
| Audit Compliance | Audit trail of tenant lifecycle events via DynamoDB streams |
| Platform Scalability | Support initial 5 tenants growing to 20+ without architecture changes |
| Cost Attribution | Enable per-tenant cost tracking and billing |

### 1.3 Key Stakeholders

| Stakeholder | Interest | Responsibility |
|-------------|----------|----------------|
| Platform Operator | Primary user for tenant provisioning | Execute tenant CRUD operations |
| Platform Admin | User-tenant assignments, organization hierarchy | Manage users within tenants |
| System (Automated) | Order processing triggers tenant creation | Automatic tenant provisioning on order completion |
| Business Owner | Cost efficiency, customer onboarding speed | Approve architecture and SLAs |
| DevOps Engineer | Infrastructure supporting the API | Deploy Lambda functions, DynamoDB tables |
| Security Engineer | Tenant isolation | Validate access controls and encryption |

### 1.4 Relationship to Other System Components

```
+-------------------+     +-------------------+     +------------------------+
| Order API         | --> | Tenant API        | --> | WordPress Tenant Mgmt  |
| (Creates tenant   |     | (Manages org,     |     | API (Provisions WP     |
|  on order)        |     |  hierarchy, users)|     |  resources)            |
+-------------------+     +-------------------+     +------------------------+
                               |
                               v
                    +-------------------+
                    | Cognito Service   |
                    | (User Pools,      |
                    |  Authentication)  |
                    +-------------------+
```

---

## 2. Scope Definition

### 2.1 In Scope

| Capability | Description |
|------------|-------------|
| Tenant CRUD Operations | Create, Read, Update, Delete (soft) tenant organizations |
| Organization Hierarchy | Division -> Group -> Team structure management |
| User-Tenant Assignments | Assign users to tenants with roles |
| Tenant Status Lifecycle | PENDING -> ACTIVE -> SUSPENDED -> DEPROVISIONED state machine |
| Tenant Metadata | Contact email, organization name, custom metadata |
| DynamoDB Storage | Single-table design with GSIs for access patterns |
| API Gateway Integration | RESTful API with Lambda handlers |

### 2.2 Out of Scope

| Item | Rationale | Reference |
|------|-----------|-----------|
| WordPress Resource Provisioning | Separate concern - handled by WordPress Tenant Management API | BRS 2.7 |
| Cognito User Pool Management | Authentication layer - handled by Cognito Service | Cognito_Tenant_Pools_LLD.md |
| Site Management | WordPress site lifecycle - separate API | Site_Management_LLD.md |
| Content Management | EFS access points, wp-content - separate API | Content_Management_LLD.md |
| Payment Processing | Order/Payment flow - handled by Order API | BRS 2.1 |
| User Authentication | Login/MFA/Password - handled by Cognito | Cognito_Tenant_Pools_LLD.md |

---

## 3. Actors and Personas

### 3.1 Platform Operator

| Attribute | Description |
|-----------|-------------|
| Role | Primary operational user |
| Authentication | Cognito with MFA required |
| Cognito Group | `Operators` |
| Permissions | Create tenant, update tenant, list tenants, assign users (to assigned tenants only) |
| Use Cases | Daily tenant provisioning, status updates, user management |

### 3.2 Platform Admin

| Attribute | Description |
|-----------|-------------|
| Role | Super user for tenant management |
| Authentication | Cognito with MFA required |
| Cognito Group | `Admins` |
| Permissions | All Operator permissions + delete tenant, create hierarchy, manage all tenants |
| Use Cases | Tenant deprovisioning, cross-tenant operations, organization setup |

### 3.3 System (Automated Processes)

| Attribute | Description |
|-----------|-------------|
| Role | Backend automation |
| Authentication | IAM role-based (Lambda execution role) |
| Permissions | Create tenant (triggered by Order API), update status |
| Use Cases | Automatic tenant creation on order completion, scheduled status checks |

### 3.4 Viewer

| Attribute | Description |
|-----------|-------------|
| Role | Read-only access |
| Authentication | Cognito |
| Cognito Group | `Viewers` |
| Permissions | List tenants (assigned only), view tenant details |
| Use Cases | Reporting, auditing, support queries |

---

## 4. Epics and User Stories

### Epic 1: Tenant Organization Management

**Epic Description**: Core CRUD operations for tenant organizations

#### US-TEN-001: Create Tenant Organization

**User Story:**
> As a Platform Operator,
> I want to create a tenant organization,
> So that customers are logically grouped and can have resources provisioned.

**Pre-conditions:**
- Operator authenticated with Operator or Admin role
- Valid JWT token with role claim
- Unique organization name provided

**Positive Scenario: Successful Tenant Creation**

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | POST `/v1.0/tenants` with organization details | Request received by API Gateway |
| 2 | Lambda validates JWT token and role | Authorization confirmed |
| 3 | Lambda validates request body schema | Validation passes |
| 4 | Lambda checks organization name uniqueness (GSI1 query) | Name is unique |
| 5 | Lambda generates tenant ID (UUID format) | `tenant-{uuid}` generated |
| 6 | Lambda creates tenant record in DynamoDB (PK=TENANT#{id}, SK=METADATA) | Item created |
| 7 | Lambda creates audit event (PK=TENANT#{id}, SK=EVENT#{timestamp}#{eventId}) | Audit logged |
| 8 | Lambda returns 201 Created with tenant details | Response includes tenantId, status=PENDING |

**Negative Scenario: Duplicate Organization Name**

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | POST `/v1.0/tenants` with existing organization name | Request received |
| 2 | Lambda queries GSI1 (GSI1PK=ORG#{name}) | Existing tenant found |
| 3 | Lambda returns 409 Conflict | Error: "Organization name already exists" |

**Negative Scenario: Invalid Request Body**

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | POST `/v1.0/tenants` with missing required fields | Request received |
| 2 | Lambda validates request body | Validation fails |
| 3 | Lambda returns 400 Bad Request | Error: Field-level validation errors |

**Edge Case: Organization Name with Special Characters**

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | POST with name containing special characters | Request received |
| 2 | Lambda sanitizes and validates name | XSS/SQL injection characters rejected |
| 3 | Lambda returns 400 if invalid | Error: "Organization name contains invalid characters" |

**Post-conditions:**
- Tenant record created in DynamoDB with status PENDING
- TENANT_CREATED audit event logged
- Tenant ID returned for subsequent operations

**Acceptance Criteria:**
- [ ] Tenant ID generated in format `tenant-{uuid}`
- [ ] Organization name validated (2-100 chars, alphanumeric with spaces/hyphens)
- [ ] Contact email validated (RFC 5322 format)
- [ ] Duplicate organization names rejected with 409 Conflict
- [ ] Initial status set to PENDING
- [ ] createdAt timestamp in ISO 8601 format
- [ ] createdBy set to authenticated user's email/ID
- [ ] TENANT_CREATED audit event recorded
- [ ] Response includes HATEOAS links for related operations
- [ ] Idempotency key supported for retry safety

---

#### US-TEN-002: Get Tenant by ID

**User Story:**
> As a Platform Operator,
> I want to retrieve tenant details by ID,
> So that I can view the current state and configuration of a tenant.

**Pre-conditions:**
- Operator authenticated with valid role
- Tenant ID exists in system

**Acceptance Criteria:**
- [ ] Returns complete tenant metadata including hierarchy
- [ ] Returns current status
- [ ] Returns list of assigned users (summary)
- [ ] Returns resource associations (if any)
- [ ] Viewers can only access assigned tenants
- [ ] Operators can access assigned tenants
- [ ] Admins can access all tenants
- [ ] Response includes HATEOAS links

---

#### US-TEN-003: Update Tenant

**User Story:**
> As a Platform Admin,
> I want to update tenant details,
> So that I can maintain accurate tenant information.

**Acceptance Criteria:**
- [ ] Only modifiable fields can be updated (not tenantId, createdAt)
- [ ] Organization name change validates uniqueness
- [ ] Contact email change validates format
- [ ] Metadata can be partially updated (merge)
- [ ] Version/ETag for optimistic locking
- [ ] DEPROVISIONED tenants cannot be updated
- [ ] Audit event records before and after values

---

#### US-TEN-004: List Tenants

**User Story:**
> As a Platform Operator,
> I want to list all tenants with filtering options,
> So that I can see platform utilization and find specific tenants.

**Acceptance Criteria:**
- [ ] Pagination with limit and nextToken
- [ ] Filter by status (PENDING, ACTIVE, SUSPENDED, DEPROVISIONED)
- [ ] Filter by organization name (partial match)
- [ ] Sort by createdAt (ascending/descending)
- [ ] Admins see all tenants
- [ ] Operators see assigned tenants only
- [ ] Viewers see assigned tenants only
- [ ] Response includes total count and pagination metadata

---

#### US-TEN-005: Soft Delete (Deprovision) Tenant

**User Story:**
> As a Platform Admin,
> I want to mark a tenant as deprovisioned,
> So that it is logically removed while preserving audit history.

**Acceptance Criteria:**
- [ ] Only Admins can delete tenants
- [ ] Soft delete (status change, not physical delete)
- [ ] Active resources must be deprovisioned first (unless force=true)
- [ ] force=true requires explicit confirmation
- [ ] Audit trail preserved
- [ ] GSI2 updated to STATUS#DEPROVISIONED
- [ ] User assignments marked as inactive

---

### Epic 2: Organization Hierarchy Management

**Epic Description**: Manage the organizational structure (Division -> Group -> Team)

#### US-TEN-006: Create Organization Hierarchy

**User Story:**
> As a Platform Admin,
> I want to create organization hierarchy levels for a tenant,
> So that users can be organized into divisions, groups, and teams.

**Acceptance Criteria:**
- [ ] Division is required, group and team are optional
- [ ] Hierarchy names validated (2-50 chars, alphanumeric)
- [ ] Duplicate combinations rejected
- [ ] tenantCount initialized to 0
- [ ] GSI1 indexed for hierarchy queries
- [ ] Can retrieve hierarchy by division

---

#### US-TEN-007: Update Organization Hierarchy

**Acceptance Criteria:**
- [ ] Hierarchy names can be renamed
- [ ] Users must be reassigned before hierarchy deletion
- [ ] HIERARCHY_UPDATED audit event logged

---

#### US-TEN-008: Delete Organization Hierarchy

**Acceptance Criteria:**
- [ ] Only empty hierarchies can be deleted
- [ ] Cascading option requires explicit confirmation
- [ ] HIERARCHY_DELETED audit event logged

---

### Epic 3: User-Tenant Assignment Management

**Epic Description**: Manage the relationship between users and tenants

#### US-TEN-009: Assign User to Tenant

**User Story:**
> As a Platform Admin,
> I want to assign a user to a tenant,
> So that the user can access tenant-specific resources.

**Acceptance Criteria:**
- [ ] Valid roles: Admin, Operator, Viewer
- [ ] Email validated (RFC 5322)
- [ ] User validated against Cognito
- [ ] Assignment includes assignedBy, assignedAt
- [ ] GSI1 indexed for user-to-tenant lookups
- [ ] Cognito custom attribute tenant_id updated
- [ ] Multiple tenant assignments require explicit confirmation

---

#### US-TEN-010: List Users in Tenant

**Acceptance Criteria:**
- [ ] Query PK=TENANT#{id}, SK begins_with "USER#"
- [ ] Returns userId, email, role, assignedAt, assignedBy
- [ ] Pagination support for large user lists
- [ ] Filter by role
- [ ] Sort by assignedAt

---

#### US-TEN-011: Remove User from Tenant

**Acceptance Criteria:**
- [ ] Assignment record deleted from DynamoDB
- [ ] Cognito group membership removed
- [ ] USER_REMOVED audit event logged
- [ ] User's next JWT excludes tenant_id claim
- [ ] Cannot remove last Admin from tenant (safety check)

---

#### US-TEN-012: Get User's Tenants

**Acceptance Criteria:**
- [ ] Query GSI1 (GSI1PK=USER#{userId})
- [ ] Returns list of tenants with roles
- [ ] Self-service: users can query their own assignments
- [ ] Admins can query any user's assignments

---

### Epic 4: Tenant Status Lifecycle

**Epic Description**: Manage tenant status transitions

#### US-TEN-013: Update Tenant Status

**Status State Machine:**

```
                 +------------------+
                 |     PENDING      |
                 | (Initial State)  |
                 +--------+---------+
                          |
          provisioning    | complete
                          v
                 +------------------+
      +--------->|     ACTIVE       |<---------+
      |          +--------+---------+          |
      |                   |                    |
reactivate              suspend             reactivate
      |                   v                    |
      |          +------------------+          |
      +----------|    SUSPENDED     |----------+
                 +--------+---------+
                          |
               deprovision|
                          v
                 +------------------+
                 |  DEPROVISIONED   |
                 |  (Terminal State)|
                 +------------------+
```

**Valid Transitions:**

| From | To | Trigger | Authority |
|------|----|---------|-----------|
| PENDING | ACTIVE | Provisioning complete | System/Operator |
| ACTIVE | SUSPENDED | Payment issue, policy violation | Admin |
| SUSPENDED | ACTIVE | Issue resolved | Admin |
| ACTIVE | DEPROVISIONED | Offboarding | Admin |
| SUSPENDED | DEPROVISIONED | Offboarding | Admin |
| PENDING | FAILED | Provisioning failed | System |

**Acceptance Criteria:**
- [ ] Invalid transitions rejected with 422
- [ ] STATUS_CHANGED audit event logged
- [ ] Previous status recorded in audit details
- [ ] GSI2 updated with new status
- [ ] Notification published for status changes
- [ ] DEPROVISIONED is terminal (no transitions allowed)

---

## 5. API Endpoints Specification

### 5.1 Tenant CRUD Endpoints

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/v1.0/tenants` | Create new tenant | JWT (Operator/Admin) |
| GET | `/v1.0/tenants/{tenantId}` | Get tenant details | JWT |
| PUT | `/v1.0/tenants/{tenantId}` | Update tenant | JWT (Admin) |
| DELETE | `/v1.0/tenants/{tenantId}` | Soft delete tenant | JWT (Admin) |
| GET | `/v1.0/tenants` | List tenants | JWT |
| PATCH | `/v1.0/tenants/{tenantId}/status` | Update status | JWT (Admin) |

### 5.2 User Assignment Endpoints

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/v1.0/tenants/{tenantId}/users` | Assign user | JWT (Admin) |
| GET | `/v1.0/tenants/{tenantId}/users` | List users | JWT |
| DELETE | `/v1.0/tenants/{tenantId}/users/{userId}` | Remove user | JWT (Admin) |

---

## 6. Data Models

### 6.1 Tenant Entity

| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| tenantId | String | Yes | Primary identifier (format: tenant-{uuid}) |
| organizationName | String | Yes | Organization name (unique) |
| environment | String | Yes | Environment (dev, sit, prod) |
| status | Enum | Yes | Lifecycle status |
| contactEmail | String | Yes | Primary contact email |
| division | String | No | Organization division |
| group | String | No | Organization group |
| team | String | No | Organization team |
| createdAt | DateTime | Yes | Creation timestamp (ISO 8601) |
| updatedAt | DateTime | No | Last update timestamp |
| createdBy | String | Yes | Email of creator |
| metadata | Map | No | Custom metadata key-value pairs |
| version | Number | Yes | Optimistic locking version |

### 6.2 TenantStatus Enum

| Value | Description | Allowed Transitions |
|-------|-------------|---------------------|
| PENDING | Initial state, awaiting provisioning | ACTIVE, FAILED |
| ACTIVE | Fully provisioned and operational | SUSPENDED, DEPROVISIONED |
| SUSPENDED | Temporarily disabled | ACTIVE, DEPROVISIONED |
| DEPROVISIONED | Terminal state, soft deleted | None |
| FAILED | Provisioning failed | PENDING (retry) |

### 6.3 DynamoDB Table Design

**Table Name:** `{env}-Tenants`

**Capacity Mode:** On-Demand

**Primary Key:**
- PK (Partition Key): String
- SK (Sort Key): String

**Global Secondary Indexes:**

| Index | Partition Key | Sort Key | Purpose |
|-------|---------------|----------|---------|
| GSI1 | GSI1PK | GSI1SK | Organization lookup, user-to-tenant |
| GSI2 | GSI2PK | GSI2SK | Status queries, time-based queries |

**Item Patterns:**

| Entity | PK | SK |
|--------|----|----|
| Tenant Metadata | TENANT#{tenantId} | METADATA |
| Tenant Resource | TENANT#{tenantId} | RESOURCE#{resourceType} |
| User Assignment | TENANT#{tenantId} | USER#{userId} |
| Hierarchy | ORG#{orgName} | HIERARCHY#{div}#{group}#{team} |

---

## 7. Business Rules

### 7.1 Tenant Naming Rules

| Rule ID | Rule |
|---------|------|
| BR-TEN-001 | Organization name must be unique |
| BR-TEN-002 | Organization name: 2-100 characters |
| BR-TEN-003 | Organization name: alphanumeric, spaces, hyphens, apostrophes |
| BR-TEN-004 | Tenant ID format: tenant-{uuid} |
| BR-TEN-005 | Tenant ID is immutable |

### 7.2 User Assignment Rules

| Rule ID | Rule |
|---------|------|
| BR-USER-001 | User must exist in Cognito before assignment |
| BR-USER-002 | User can be assigned to multiple tenants (with warning) |
| BR-USER-003 | Valid roles: Admin, Operator, Viewer |
| BR-USER-004 | Cannot remove last Admin from active tenant |
| BR-USER-005 | Email must be valid RFC 5322 format |

### 7.3 Status Transition Rules

| Rule ID | Rule |
|---------|------|
| BR-STATUS-001 | PENDING -> ACTIVE only when provisioning complete |
| BR-STATUS-002 | ACTIVE -> SUSPENDED requires reason |
| BR-STATUS-003 | DEPROVISIONED is terminal (no transitions) |
| BR-STATUS-004 | SUSPENDED -> ACTIVE requires Admin approval |
| BR-STATUS-005 | Status change must record reason in audit |

---

## 8. Non-Functional Requirements

### 8.1 Performance

| Metric | Target |
|--------|--------|
| Create tenant response time | < 500ms |
| Get tenant response time | < 200ms |
| List tenants response time (20 items) | < 500ms |
| DynamoDB read latency | < 10ms (p99) |
| Lambda cold start | < 3 seconds |

### 8.2 Security

| Aspect | Implementation |
|--------|----------------|
| Authentication | JWT tokens via Cognito |
| Authorization | Role-based (Admin, Operator, Viewer) |
| API Key | Required for all requests (X-Api-Key header) |
| Encryption at rest | DynamoDB encryption with AWS-managed KMS |
| Encryption in transit | TLS 1.2+ |
| Rate limiting | API Gateway throttling (100 req/sec) |

### 8.3 Availability

| Metric | Target |
|--------|--------|
| Uptime | 99.9% |
| RTO | 4 hours (DR failover) |
| RPO | 1 hour (backup frequency) |

---

## 9. Document Sections Outline

```
1. Introduction
   1.1 Purpose
   1.2 Scope (In/Out)
   1.3 System Overview
   1.4 Use Case Diagrams
   1.5 Traceability Matrix

2. Stakeholders
   2.1 Platform Operator
   2.2 Platform Admin
   2.3 System (Automated)
   2.4 Viewer

3. API Definitions
   3.1 Tenant CRUD Endpoints
   3.2 User Assignment Endpoints

4. Epic 1: Tenant Organization Management
   US-TEN-001 to US-TEN-005

5. Epic 2: Organization Hierarchy Management
   US-TEN-006 to US-TEN-008

6. Epic 3: User-Tenant Assignment Management
   US-TEN-009 to US-TEN-012

7. Epic 4: Tenant Status Lifecycle
   US-TEN-013

8. Non-Functional Requirements
   8.1 Performance
   8.2 Scalability
   8.3 Security
   8.4 Availability

9. Constraints

10. Assumptions and Risks

11. Glossary

12. Sign-Off

Appendix A: API Endpoint Reference
Appendix B: DynamoDB Schema Reference
Appendix C: Error Code Reference
```

---

## 10. Effort Estimate

| Section | Estimated Pages |
|---------|-----------------|
| Introduction & Scope | 3-4 pages |
| Stakeholders | 1 page |
| API Definitions | 4-5 pages |
| Business Rules | 3-4 pages |
| Epic 1 (5 user stories) | 10-12 pages |
| Epic 2 (3 user stories) | 6-8 pages |
| Epic 3 (4 user stories) | 8-10 pages |
| Epic 4 (1 user story) | 3-4 pages |
| NFRs | 2-3 pages |
| Appendices | 4-5 pages |
| **Total** | **45-55 pages** |

---

## 11. Open Questions

| ID | Question | Priority |
|----|----------|----------|
| Q-001 | What is the exact Tenant ID format? UUID vs slug-based? | High |
| Q-002 | Should users be allowed in multiple tenants simultaneously? | High |
| Q-003 | Is soft delete sufficient or is hard delete ever needed? | Medium |
| Q-004 | Should status transitions trigger notifications? | Medium |

---

## 12. References

| Document | Path |
|----------|------|
| Tenant_Management_LLD.md | `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/Tenant_Management_LLD.md` |
| Cognito_Tenant_Pools_LLD.md | `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/Cognito_Tenant_Pools_LLD.md` |
| 2.0_BBWS_ECS_WordPress_HLD.md | `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/HLDs/2.0_BBWS_ECS_WordPress_HLD.md` |
| 2.1_BRS_Customer_Portal_Public.md | `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/BRS/2.1_BRS_Customer_Portal_Public.md` |

---

**End of Plan**
