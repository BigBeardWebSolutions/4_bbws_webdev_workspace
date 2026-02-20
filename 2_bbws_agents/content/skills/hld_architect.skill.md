# HLD Architect Skill

## Skill Overview

This skill enables the agent to create comprehensive High-Level Design (HLD) documents using the standardized HLD template. The skill guides architects through the design process, ensuring completeness, consistency, and adherence to best practices.

## Skill Capabilities

### 1. HLD Document Creation
- Generate HLD documents from the standardized template
- Populate all sections with project-specific information
- Ensure compliance with organizational standards
- Add sample JSON payloads for all API endpoints

### 2. Requirements Elicitation
- Conduct guided interviews to gather system requirements
- Ask targeted questions to understand business objectives
- Identify key stakeholders and user personas
- Define scope and boundaries clearly

### 3. Architecture Design
- Design microservices architecture
- Define API endpoints with full CRUD operations
- Design DynamoDB schemas with soft delete patterns
- Plan infrastructure components (Lambda, API Gateway, CloudFront)

### 4. Documentation Standards
- Follow hierarchical naming conventions (HLD_Prefix.X_LLD_Name.md)
- Maintain version control and document history
- Ensure traceability between HLD and LLDs
- Include comprehensive API documentation with JSON payloads

## Template Reference

**Primary Template**: `./HLD_TEMPLATE.md`

This template includes:
- Complete HLD structure with all standard sections
- Sample JSON request/response payloads for all API operations
- Soft delete pattern implementation
- DynamoDB schema design patterns
- Per-component Terraform structure
- Business approval workflow
- UI-first development approach
- Milestone tracking with BO gates

## Usage Pattern

### Step 1: Initialize HLD Document
```bash
# Copy template to target location
cp /Users/tebogotseka/Documents/agentic_work/2_bbws_agents/content/skills/HLD_TEMPLATE.md \
   /Users/tebogotseka/Documents/agentic_work/2_bbws_docs/HLDs/[HLD_Prefix]_HLD_[Name].md
```

### Step 2: Gather Project Information
Ask the user for:
- **Application Name**: What is the name of the application?
- **HLD Prefix**: What is the HLD numbering prefix? (e.g., 2.1, 3.5)
- **Domain**: What is the domain name? (e.g., kimmyai.io)
- **Phase**: What phase is this? (e.g., Phase 0 - First to Market)
- **Target Users**: Who are the target users?
- **Business Objectives**: What are the key business objectives?

### Step 3: Define Architecture Components
Gather details on:
- **Screens**: List all screens with IDs and descriptions
- **Microservices**: List all services and their responsibilities
- **APIs**: Define all endpoints with CRUD operations
- **Entities**: Define data models with all attributes
- **Infrastructure**: AWS services required

### Step 4: Populate Template Sections
Replace all placeholders in the template:
- `[Application Name]` → Actual application name
- `[HLD_Prefix]` → HLD numbering prefix
- `[domain]` → Domain name
- `[YYYY-MM-DD]` → Current date
- `[Entity]` → Actual entity names
- `[Service]` → Actual service names

### Step 5: Add API JSON Payloads
For each API endpoint, ensure:
- Request headers are documented
- Request body schema with example JSON
- Success response (2xx) with example JSON
- Error responses (4xx, 5xx) with example JSON
- Query parameters for GET endpoints
- Pagination patterns where applicable

### Step 6: Validate Completeness
Ensure all sections are complete:
- [ ] Executive Summary with business value
- [ ] Application Overview with URLs
- [ ] All screens documented
- [ ] All microservices defined
- [ ] All API endpoints with JSON payloads
- [ ] DynamoDB schema with all entities
- [ ] Infrastructure components
- [ ] Repository list
- [ ] Implementation milestones
- [ ] LLD references

### Step 7: Create LLD Stubs
Generate LLD file names following the convention:
- `[HLD_Prefix].1_LLD_Frontend_Architecture.md`
- `[HLD_Prefix].2_LLD_[Service]_Lambda.md`
- `[HLD_Prefix].X_OPS_[Operation]_Runbook.md`

## Key Design Patterns

### 1. Activatable Entity Pattern (MANDATORY)

**All entities MUST implement the Activatable Entity Pattern.** This pattern makes entities identifiable, soft delete ready, and self-auditing.

Every entity must include these five mandatory fields:

```json
{
  "id": "unique-identifier-uuid",
  "dateCreated": "2025-12-19T10:30:00Z",
  "dateLastUpdated": "2025-12-19T10:30:00Z",
  "lastUpdatedBy": "user@example.com",
  "active": true
}
```

#### Field Descriptions

| Field | Type | Purpose | Example Values |
|-------|------|---------|----------------|
| `id` | String (UUID) | **Identifiable**: Unique identifier for the entity | `prod_550e8400-e29b-41d4-a716-446655440000` |
| `dateCreated` | ISO 8601 Timestamp | **Self-Auditing**: When entity was created | `2025-12-19T10:30:00Z` |
| `dateLastUpdated` | ISO 8601 Timestamp | **Self-Auditing**: When entity was last modified | `2025-12-19T14:00:00Z` |
| `lastUpdatedBy` | String (Email/ID) | **Self-Auditing**: Who made the last update | `admin@example.com`, `system`, `user@example.com` |
| `active` | Boolean | **Soft Delete Ready**: Enables soft delete pattern | `true` (active), `false` (soft deleted) |

#### Benefits of Activatable Entity Pattern

1. **Identifiable**: Every entity has a unique `id` field for referencing
2. **Soft Delete Ready**: Use `active` flag instead of hard deletes (preserves audit trail)
3. **Self-Auditing**: Track creation time, last update time, and who made changes

#### Usage in APIs

**All list endpoints must support:**
```
GET /v1.0/entities?include_inactive=true
```

**Soft delete operation:**
```json
PUT /v1.0/entities/{id}
{
  "active": false
}
```

**Response includes audit trail:**
```json
{
  "id": "entity-123",
  "name": "Example Entity",
  "dateCreated": "2025-12-19T10:00:00Z",
  "dateLastUpdated": "2025-12-19T15:00:00Z",
  "lastUpdatedBy": "admin@example.com",
  "active": false
}
```

### 2. CRUD Operations
Every entity must have complete CRUD:
- POST `/v1.0/[entities]` - Create
- GET `/v1.0/[entities]/{id}` - Get by ID
- GET `/v1.0/[entities]` - List all (findAll)
- PUT `/v1.0/[entities]/{id}` - Update
- PUT `/v1.0/[entities]/{id}` - Soft delete (set active=false)

**No DELETE operations** - use PUT to set active=false

### 3. Entity Structure (Activatable Entity Pattern)
Every entity must implement the **Activatable Entity Pattern** with these mandatory fields:
- `id` - Unique identifier (UUID) - Makes entity **Identifiable**
- `dateCreated` - ISO 8601 timestamp - **Self-Auditing** (when created)
- `dateLastUpdated` - ISO 8601 timestamp - **Self-Auditing** (when last modified)
- `lastUpdatedBy` - Email/ID of user - **Self-Auditing** (who made changes)
- `active` - Boolean - **Soft Delete Ready** (true=active, false=deleted)
- Domain-specific fields (additional business fields)

### 4. API Response Format
Standard success response (with Activatable Entity Pattern):
```json
{
  "id": "uuid",
  "field1": "value",
  "dateCreated": "2025-12-19T10:30:00Z",
  "dateLastUpdated": "2025-12-19T14:00:00Z",
  "lastUpdatedBy": "user@example.com",
  "active": true
}
```

Standard error response:
```json
{
  "error": "ErrorType",
  "message": "Human-readable message",
  "details": [
    {
      "field": "fieldName",
      "message": "Field-specific error"
    }
  ]
}
```

### 5. List Response Format
Standard list response with pagination:
```json
{
  "items": [...],
  "startAt": "last_item_id_or_token",
  "moreAvailable": true
}
```

**Pagination Request Parameters:**
- `pageSize` (integer, optional): Number of items to return per page. Default: `50`, Max: `100`
- `startAt` (string, optional): Pagination token to start at a specific position

**Pagination Response Fields:**
- `items`: Array of results
- `startAt`: Token for the next page (ID of last item or continuation token)
- `moreAvailable`: Boolean indicating if more results are available

### 6. Repository Naming Convention
```
[HLD_Prefix]_[project]_[service]_lambda
```

Where dots in HLD_Prefix are replaced with underscores:
- HLD: `2.1` → Repository: `2_1_bbws_product_lambda`
- HLD: `3.5` → Repository: `3_5_bbws_auth_lambda`

### 7. Lambda Configuration Standards
```
Runtime: Python 3.12
Memory: 256MB
Timeout: 30s
Architecture: arm64
```

### 8. Per-Component Terraform
Each Lambda service has:
```
/terraform
  ├── main.tf
  ├── api_gateway.tf
  ├── lambda.tf
  ├── iam.tf
  ├── cloudfront.tf
  ├── variables.tf
  └── outputs.tf
```

## Business Approval Workflow

### Artefacts Requiring BO Sign-off
- All UI screens and layouts
- Email templates
- Customer-facing messaging
- Marketing content
- Legal content

### Approval Process
1. DEV → Technical review
2. SIT → Business Owner review
3. Iterate until BO approval
4. PROD → Deploy only after BO sign-off

## Validation Checklist

Before finalizing HLD:
- [ ] All placeholders replaced with actual values
- [ ] All API endpoints have JSON payload examples
- [ ] **All entities implement Activatable Entity Pattern** (id, dateCreated, dateLastUpdated, lastUpdatedBy, active)
- [ ] Soft delete pattern implemented everywhere (active field)
- [ ] No DELETE operations defined (use PUT with active=false)
- [ ] Repository names follow naming convention
- [ ] LLD file names follow hierarchical pattern
- [ ] Business approval gates documented
- [ ] Version history updated
- [ ] Related documents linked

## Common Mistakes to Avoid

1. **Missing Activatable Entity Pattern**: Every entity MUST include all 5 fields (id, dateCreated, dateLastUpdated, lastUpdatedBy, active)
2. **Missing JSON Payloads**: Every API endpoint MUST have request/response examples
3. **Using created_at/updated_at**: Use standardized field names (dateCreated, dateLastUpdated)
4. **Missing lastUpdatedBy**: All entities MUST track who made the last update
5. **DELETE Operations**: Never use DELETE - always use PUT to set active=false
6. **Inconsistent Naming**: Repository names must match HLD prefix pattern
7. **Missing Pagination**: List endpoints must support pagination with pageSize/startAt parameters and moreAvailable boolean in response
8. **Missing Error Responses**: Document both success and error responses for each API
9. **Missing include_inactive Parameter**: All list endpoints must support filtering inactive records

## Example HLD
See the completed HLD example:
`/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/HLDs/2.1_BBWS_Customer_Portal_Public_HLD.md`

This example demonstrates:
- Complete HLD structure
- Campaign Manager with full CRUD
- Product Manager with full CRUD
- JSON payloads for all endpoints
- Soft delete pattern throughout
- Proper entity design with all required fields

## Operational Configurations

The HLD template includes comprehensive JSON payload examples for operational configurations in Section 9.4:

### Monitoring & Alerting
- **CloudWatch Alarms**: Lambda error rates, DynamoDB throttling, API Gateway 5xx errors
- **CloudWatch Dashboards**: Service performance metrics, resource utilization
- **SNS Topics**: Alert notifications (email, SMS, Lambda)

### Cost Management
- **AWS Budgets**: Monthly cost budgets with actual/forecasted alerts
- **Cost allocation tags**: Project and environment tagging

### Security & Compliance
- **AWS Config Rules**: S3 encryption, IAM password policy, security group rules
- **WAF Web ACLs**: Rate limiting, managed rule sets, IP blocking
- **Guardrails**: Cross-region protections, resource restrictions

### Automation
- **EventBridge Rules**: Scheduled Lambda invocations, event-driven workflows
- **Dead Letter Queues**: Failed Lambda invocation handling with alarms

All operational JSON payloads follow AWS CloudFormation/Terraform structure and can be directly used in infrastructure-as-code.

## Related Skills
- **LLD Architect**: Create Low-Level Design documents
- **API Designer**: Design RESTful APIs
- **Database Architect**: Design DynamoDB schemas
- **DevOps Engineer**: Infrastructure and deployment
- **Operations Engineer**: Monitoring, alerting, cost optimization

---

**Last Updated**: 2025-12-19
**Template Version**: 1.0.2
**Skill Owner**: HLD Architect
