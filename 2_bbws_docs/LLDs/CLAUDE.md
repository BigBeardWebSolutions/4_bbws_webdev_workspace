# BBWS Low-Level Design (LLD) Documents - Project Instructions

## Directory Purpose

This directory contains Low-Level Design (LLD) documents for the BBWS Multi-Tenant WordPress Hosting Platform. LLDs provide detailed component specifications, API contracts, database schemas, security implementations, and deployment procedures.

---

## TBT Workflow Integration

This directory follows the **Turn-by-Turn (TBT) mechanism** with the following structure:

```
LLDs/
├── .claude/
│   ├── logs/
│   │   └── history.log          ← Command logging
│   ├── plans/
│   │   └── plan_X.md            ← High-level approval plans
│   ├── snapshots/               ← File snapshots before modifications
│   ├── staging/                 ← Temporary staging files
│   │   └── staging_X/
│   └── state/
│       └── state.md             ← TBT state tracking
├── specs/
│   └── questions.md             ← Requirements clarification
└── [LLD documents]
```

### TBT Workflow Phases

**Phase 1: Planning** (Manual - User Approval Required)
1. Log command to `.claude/logs/history.log`
2. Create high-level plan in `.claude/plans/plan_X.md`
3. Display plan for user review
4. **WAIT for explicit user approval** ("go"/"approved"/"continue")

**Phase 2: Execution** (After Approval)
1. Snapshot any files that will be modified
2. Execute planned work turn-by-turn
3. Update state.md with progress
4. Stage artifacts for review

**Phase 3: Review and Finalize**
1. Present completed work from staging
2. Gather user feedback
3. Refine as needed
4. Move approved artifacts to final location

---

## LLD Document Standards

### Structure Requirements
All LLDs must follow the standardized template and include:

1. **Document Metadata**
   - Version number
   - Related HLD reference
   - Author and date
   - Approval status

2. **Component Specifications**
   - Detailed component architecture
   - Class diagrams and sequence diagrams
   - Interface definitions
   - API contracts (OpenAPI/Swagger)

3. **Database Design**
   - Table schemas (DynamoDB single-table design)
   - Indexes (GSI, LSI)
   - Access patterns
   - Data migration strategy

4. **Security Implementation**
   - Authentication mechanisms
   - Authorization patterns
   - Encryption (at-rest, in-transit)
   - Security controls

5. **Deployment Procedures**
   - Infrastructure as Code (Terraform)
   - CI/CD pipeline configuration
   - Environment-specific configurations
   - Rollback procedures

6. **Testing Strategy**
   - Unit tests (TDD)
   - Integration tests
   - End-to-end tests
   - Performance tests

---

## Naming Convention

LLDs follow the hierarchical naming pattern from their parent HLD:

| HLD | LLD Pattern | Example |
|-----|-------------|---------|
| 2.1_BBWS_Customer_Portal_Public_HLD.md | 2.1.X_LLD_[Component].md | 2.1.1_LLD_Tenant_Lambda.md |
| 2.2_BBWS_Customer_Portal_Private_HLD.md | 2.2.X_LLD_[Component].md | 2.2.1_LLD_Admin_API.md |
| 2.3_BBWS_Admin_App_HLD.md | 2.3.X_LLD_[Component].md | 2.3.1_LLD_Mobile_Backend.md |

**Pattern**: `{HLD_Number}.{Sequence}_LLD_{Component_Name}.md`

---

## Development Standards

### Architecture Patterns
- **Microservices**: Each service has dedicated LLD
- **Serverless-First**: Lambda functions, API Gateway, DynamoDB
- **Single-Table Design**: DynamoDB patterns for optimal performance
- **HATEOAS**: RESTful APIs with hypermedia links reflecting entity relationships

### Code Quality
- **OOP**: Object-oriented design principles
- **SOLID**: Single Responsibility, Open/Closed, Liskov Substitution, Interface Segregation, Dependency Inversion
- **TDD**: Test-Driven Development - write tests first
- **BDD**: Behavior-Driven Development - Gherkin scenarios
- **DDD**: Domain-Driven Design - bounded contexts

### Repository Organization
Each microservice/component should have:
- **Dedicated repository**: `2_{sequence}_bbws_{component_name}`
- **Terraform scripts**: Per-component infrastructure (not monolithic)
- **OpenAPI specs**: Separate YAML files per API
- **Test suite**: Unit, integration, E2E tests

---

## Environment Strategy

All LLDs must support multi-environment deployment:

| Environment | AWS Account | Region | Purpose |
|-------------|-------------|--------|---------|
| **DEV** | 536580886816 | af-south-1 | Development and testing |
| **SIT** | 815856636111 | af-south-1 | System Integration Testing |
| **PROD** | 093646564004 | af-south-1 | Production (read-only via Claude) |

### Deployment Flow
```
DEV (auto-deploy) → [Approval] → SIT (manual promote) → [Approval] → PROD (manual promote)
```

**Critical Rules**:
- ✅ Fix defects in DEV and promote to SIT (maintain consistency)
- ✅ Never hardcode environment credentials - parameterize everything
- ✅ Human approval required for SIT and PROD deployments
- ✅ PROD is read-only for Claude Code operations

---

## Infrastructure Standards

### Terraform Requirements
- **Separate modules**: Each microservice has own terraform script
- **State management**: S3 backend with DynamoDB locking, separate state per environment
- **Capacity mode**: DynamoDB tables must use "on-demand" capacity
- **Public access**: All S3 buckets must block public access
- **Tagging**: Environment, Project, Owner, CostCenter, Managed-by

### DynamoDB Design
- **Single-table design**: Preferred pattern
- **On-demand capacity**: Required for all tables
- **Backup strategy**: PITR enabled, hourly backups
- **Cross-region replication**: PROD only (af-south-1 → eu-west-1)

### S3 Configuration
- **Block public access**: Required for all buckets
- **Versioning**: Enabled for critical buckets
- **Lifecycle policies**: Define retention rules
- **Cross-region replication**: PROD only for DR

---

## CI/CD Pipeline Standards

### GitHub Actions Requirements
All LLDs must specify GitHub Actions pipelines with:

1. **Validation Stage**
   - Terraform fmt/validate
   - Schema validation
   - Security scanning
   - Cost estimation

2. **Approval Gates**
   - After terraform plan (before dev deploy)
   - Before environment promotion (dev→sit, sit→prod)

3. **Deployment Stage**
   - Terraform plan → Human approval → Terraform apply
   - Automated testing post-deployment
   - Rollback capability (terraform state rollback)

4. **Promotion Strategy**
   - Manual trigger with approval
   - Environment-specific .tfvars files
   - No auto-promotion to PROD

---

## Monitoring and Alerting

### CloudWatch Requirements
LLDs must specify monitoring for:
- **Failed transactions**: Lambda errors, API Gateway 5xx
- **Stuck transactions**: State machine timeouts
- **Lost transactions**: Dead-letter queue monitoring
- **Performance**: Lambda duration, DynamoDB throttling

### State Management
- **DynamoDB state table**: Track long-running processes
- **SNS alerts**: Failed/stuck/lost transactions
- **Dead-letter queues**: Enable for all async processes
- **Exponential backoff**: Retry logic for transient failures

---

## Disaster Recovery

### DR Strategy
- **Pattern**: Multi-site Active/Active
- **Primary Region**: af-south-1 (Cape Town)
- **DR Region**: eu-west-1 (Ireland)
- **Failover**: Route 53 health checks

### Backup Requirements
- **DynamoDB**: PITR + hourly snapshots + cross-region replication (PROD only)
- **S3**: Versioning + cross-region replication (PROD only)
- **RTO/RPO**: Define per component in LLD

---

## Tenant Management Architecture

### Organizational Hierarchy
```
Organization
├── Division (optional)
│   ├── Group (optional)
│   │   ├── Team
│   │   │   └── User
```

### User Access Control
- **Role-based**: Admin, Manager, User
- **Team-based isolation**: Users only access their team's data
- **Multi-team support**: Users can belong to multiple teams
- **Invitation system**: Admins invite and assign roles

### Required Fields
- Organization name (mandatory)
- Destination email for forms (mandatory)
- User email (mandatory)
- Roles/permissions per user

---

## Documentation Requirements

### Diagrams
LLDs must include:
- **Component diagrams**: Service interactions
- **Sequence diagrams**: Request/response flows
- **Class diagrams**: Object models (OOP)
- **Database ERD**: Table relationships and access patterns
- **Infrastructure diagrams**: AWS resources and connections

### Runbooks
Create operational runbooks in `2_bbws_docs/runbooks/` for:
- Deployment procedures
- Promotion workflows (dev→sit→prod)
- Troubleshooting guides
- Rollback procedures
- Common operational tasks

---

## Integration Patterns

### Lambda-to-DynamoDB
- Lambdas reference tables by naming convention
- No hard-coded table names
- Use environment variables for table references
- Follow single-table design patterns

### API Design
- **OpenAPI 3.0**: Separate YAML per microservice
- **HATEOAS**: Hypermedia links reflecting entity relationships
- **Versioning**: URL-based (e.g., `/v1/orders`)
- **Authentication**: Cognito JWT tokens

---

## Quality Assurance

### Test-Driven Development
1. **Write tests first**: Define expected behavior
2. **Implement code**: Make tests pass
3. **Refactor**: Improve code quality
4. **Repeat**: Continuous improvement

### Testing Levels
- **Unit tests**: 80%+ coverage
- **Integration tests**: API contract validation
- **E2E tests**: User journey validation
- **Performance tests**: Load and stress testing

---

## Agentic Architect Integration

This directory works with the **Agentic Architect** persona system:

### Available Personas for LLD Work

| Persona | When to Use |
|---------|-------------|
| **LLD Architect** | Creating new LLD documents |
| **Project Manager** | Multi-stage LLD creation projects |
| **DevOps Engineer** | CI/CD pipeline specifications |
| **Python AWS Developer** | Lambda implementation details |
| **Java AWS Developer** | Java-based microservices |

### Loading Personas
```
Load: agentic_architect/LLD_Architect_Agent.md
Purpose: Create detailed LLD from HLD reference
```

---

## Specs Directory

The `specs/` directory contains:
- **questions.md**: Requirements clarification for new LLDs
- **[component]_spec.md**: Refined specifications before LLD creation
- **[component]_requirements.md**: Detailed requirements documents

Use specs to gather and refine requirements before creating formal LLDs.

---

## Root Workflow Inheritance

This directory inherits all workflow mechanisms from parent CLAUDE.md files:

```
LLDs/CLAUDE.md (this file)
  ↓ inherits from
2_bbws_docs/CLAUDE.md (BBWS Documentation standards)
  ↓ inherits from
agentic_work/CLAUDE.md (Agentic Architect standards)
  ↓ inherits from
~/.claude/CLAUDE.md (Global user preferences and TBT mechanism)
```

---

## Key Principles

1. **Planning-First**: Always create detailed plan before implementation
2. **User Approval**: Wait for explicit approval before proceeding
3. **TBT Compliance**: Log commands, create plans, snapshot files, stage artifacts
4. **Quality Standards**: Completeness, clarity, consistency, traceability, justification
5. **Environment Safety**: Never deploy to PROD without approval, parameterize all configs
6. **Test-Driven**: Write tests first, implement code to pass tests
7. **Microservices**: Each service isolated with dedicated repo and terraform

---

**Status**: TBT workflow initialized and ready
**Last Updated**: 2025-12-25
**Maintained By**: Agentic Architect System
