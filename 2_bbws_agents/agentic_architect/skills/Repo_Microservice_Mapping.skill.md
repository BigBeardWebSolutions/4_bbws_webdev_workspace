# Repository to Microservice Mapping Skill

**Version**: 1.0
**Created**: 2025-12-17
**Type**: Architecture Design Pattern
**Extracted From**: BBWS HLD architecture sessions - repository organization patterns

---

## Purpose

Guide architects to design consistent repository structures that map cleanly to microservices, ensuring:
- Clear naming conventions with project/phase/component hierarchy
- Standard supporting repositories always included
- One microservice = one repository principle
- Each repo contains its own infrastructure (Terraform)

**Problem Solved**: Inconsistent repository naming leads to confusion, orphaned repos, and difficulty understanding project scope. This skill ensures every HLD has a complete, well-organized repository list.

---

## Trigger Conditions

### When to Apply This Skill

Invoke this skill when:
- Designing repository structure for a new project
- Creating HLD Section 10 (Repositories)
- Reviewing microservice-to-repo mapping
- User mentions repositories, naming conventions, or project organization

### Red Flags (Missing Standard Repos)

Watch for HLDs missing these standard repositories:
- No documentation repo (`_docs`)
- No operations repo (`_operations`)
- No agents repo (`_agents`)
- No common/shared repo (`_common`)
- No test framework repo (`_tests`)

---

## Core Concept: Repository Naming Convention

### Naming Pattern

```
[project-name]_[phase]_[component-name]
```

**Components:**
| Element | Description | Example |
|---------|-------------|---------|
| `project-name` | Short project identifier with phase number | `2_bbws` |
| `phase` | Project phase number prefix | `2_` (Phase 2) |
| `component-name` | Descriptive component name | `auth_lambda` |

### Naming Rules

1. **Prefix**: `[phase]_[project]_` (e.g., `2_bbws_`)
2. **Lambda services**: End with `_lambda`
3. **Frontend apps**: Descriptive name (e.g., `web_public`, `web_admin`)
4. **No `svc` prefix**: Avoid redundant prefixes like `svc-` or `service-`
5. **Lowercase with underscores**: Use `_` not `-` for consistency
6. **Each repo has own `/terraform`**: No shared infrastructure repo

---

## Standard Repositories (Always Include)

Every project MUST have these supporting repositories:

### 1. Documentation Repository

```
{prefix}_docs
```

**Purpose**: Centralized documentation hub
**Contents**:
- HLDs (High-Level Designs)
- LLDs (Low-Level Designs)
- Architecture Decision Records (ADRs)
- Runbooks and operational guides
- API documentation
- Onboarding guides

**Structure**:
```
2_bbws_docs/
├── HLDs/
│   ├── BBWS_Customer_Portal_Public_HLD.md
│   ├── BBWS_Customer_Portal_Private_HLD.md
│   └── BBWS_Admin_Portal_HLD.md
├── LLDs/
│   ├── CPP_Auth_Lambda_LLD.md
│   ├── CPP_Cart_Lambda_LLD.md
│   └── ...
├── ADRs/
│   ├── ADR-001_DynamoDB_Single_Table.md
│   └── ADR-002_Soft_Delete_Pattern.md
├── runbooks/
│   ├── deployment_runbook.md
│   └── incident_response_runbook.md
└── README.md
```

### 2. Operations Repository

```
{prefix}_operations
```

**Purpose**: Operational infrastructure and monitoring
**Contents**:
- CloudWatch dashboards
- Alerts and alarms
- Budgets and cost management
- AWS Config rules
- Guardrails and compliance
- WAF rules and firewall configs
- Service Control Policies (SCPs)
- Incident response playbooks

**Structure**:
```
2_bbws_operations/
├── dashboards/
│   ├── overview_dashboard.json
│   └── service_dashboards/
├── alerts/
│   ├── lambda_alerts.tf
│   └── api_gateway_alerts.tf
├── budgets/
│   └── monthly_budget.tf
├── config/
│   └── aws_config_rules.tf
├── guardrails/
│   └── scp_policies.json
├── waf/
│   └── waf_rules.tf
├── terraform/
│   ├── main.tf
│   └── variables.tf
└── README.md
```

### 3. Agents Repository

```
{prefix}_agents
```

**Purpose**: AI agent definitions and automation
**Contents**:
- Agent specifications
- Agent definition files
- Skills for agents
- Automation scripts
- Claude Code configurations

**Structure**:
```
2_bbws_agents/
├── agents/
│   ├── devops_agent.md
│   ├── content_manager_agent.md
│   └── monitoring_agent.md
├── skills/
│   ├── deployment.skill.md
│   └── incident_response.skill.md
├── automation/
│   └── scripts/
└── README.md
```

### 4. Common/Shared Repository

```
{prefix}_common
```

**Purpose**: Shared libraries, utilities, and configurations
**Contents**:
- Shared Python/Node packages
- Common utilities
- Shared data models
- Configuration templates
- Environment variables templates

**Structure**:
```
2_bbws_common/
├── python/
│   ├── bbws_common/
│   │   ├── __init__.py
│   │   ├── models/
│   │   ├── utils/
│   │   └── exceptions/
│   ├── setup.py
│   └── requirements.txt
├── config/
│   ├── env.template
│   └── settings.py
└── README.md
```

### 5. Tests Repository

```
{prefix}_tests
```

**Purpose**: Cross-service testing and E2E tests
**Contents**:
- E2E test suites
- Integration test frameworks
- Performance/load tests
- Contract tests
- Test data generators
- Test utilities

**Structure**:
```
2_bbws_tests/
├── e2e/
│   ├── auth_flow_test.py
│   ├── checkout_flow_test.py
│   └── conftest.py
├── integration/
│   └── api_integration_tests.py
├── performance/
│   └── load_tests/
├── contracts/
│   └── api_contracts/
├── data/
│   └── test_data_generators.py
├── pytest.ini
└── README.md
```

### 6. Infrastructure Repository (Optional)

```
{prefix}_infra
```

**Purpose**: Shared infrastructure components (if needed)
**When to Include**:
- Shared VPC/networking
- Shared databases (DynamoDB tables)
- Shared Cognito user pools
- Cross-cutting AWS resources

**Note**: Prefer per-component `/terraform` folders. Only use shared infra repo for truly cross-cutting resources.

**Structure**:
```
2_bbws_infra/
├── terraform/
│   ├── vpc/
│   ├── dynamodb/
│   ├── cognito/
│   └── shared/
└── README.md
```

---

## Microservice Repository Pattern

### One Microservice = One Repository

Each microservice gets its own repository with embedded infrastructure:

```
{prefix}_{service}_lambda
```

**Structure**:
```
2_bbws_auth_lambda/
├── src/
│   ├── handlers/          # Lambda handlers
│   │   ├── register.py
│   │   ├── login.py
│   │   └── ...
│   ├── services/          # Business logic
│   ├── models/            # Data models
│   └── utils/             # Utilities
├── tests/
│   ├── unit/
│   └── integration/
├── terraform/             # Per-component infrastructure
│   ├── main.tf
│   ├── api_gateway.tf
│   ├── lambda.tf
│   ├── iam.tf
│   ├── cloudfront.tf
│   ├── variables.tf
│   └── outputs.tf
├── requirements.txt
├── pytest.ini
└── README.md
```

### Frontend Repository Pattern

```
{prefix}_web_{portal-name}
```

**Examples**:
- `2_bbws_web_public` - Public customer portal
- `2_bbws_web_private` - Private authenticated portal
- `2_bbws_web_admin` - Admin portal

**Structure**:
```
2_bbws_web_public/
├── src/
│   ├── components/
│   ├── pages/
│   ├── hooks/
│   ├── services/
│   └── utils/
├── public/
├── tests/
├── terraform/
│   ├── s3.tf
│   ├── cloudfront.tf
│   └── route53.tf
├── package.json
└── README.md
```

### Database Schema Repository

```
{prefix}_dynamodb_schemas
```

**Purpose**: DynamoDB table schemas, GSIs, and migrations
**Structure**:
```
2_bbws_dynamodb_schemas/
├── schemas/
│   ├── main_table.json
│   └── gsi_definitions.json
├── migrations/
│   ├── v1_initial.py
│   └── v2_add_gsi.py
├── terraform/
│   ├── main.tf
│   └── tables.tf
└── README.md
```

---

## Complete Example: BBWS Customer Portal

### Repository List

| # | Repository | Type | Description |
|---|------------|------|-------------|
| **Standard Repos** |||
| 1 | `2_bbws_docs` | Documentation | HLDs, LLDs, ADRs, runbooks |
| 2 | `2_bbws_operations` | Operations | Dashboards, alerts, budgets, guardrails |
| 3 | `2_bbws_agents` | Automation | AI agents, skills, automation scripts |
| 4 | `2_bbws_common` | Shared | Shared libraries, utilities, configs |
| 5 | `2_bbws_tests` | Testing | E2E tests, integration tests, load tests |
| **Frontend Repos** |||
| 6 | `2_bbws_web_public` | Frontend | Public customer portal (React SPA) |
| 7 | `2_bbws_web_private` | Frontend | Private authenticated portal |
| 8 | `2_bbws_web_admin` | Frontend | Admin portal |
| **Database Repos** |||
| 9 | `2_bbws_dynamodb_schemas` | Database | DynamoDB schemas, GSIs, migrations |
| **Microservice Repos** |||
| 10 | `2_bbws_auth_lambda` | Backend | Auth service (Python) |
| 11 | `2_bbws_marketing_lambda` | Backend | Marketing/campaign service |
| 12 | `2_bbws_product_lambda` | Backend | Product catalog service |
| 13 | `2_bbws_contact_lambda` | Backend | Contact form service |
| 14 | `2_bbws_invitation_lambda` | Backend | Invitation service |
| 15 | `2_bbws_cart_lambda` | Backend | Shopping cart service |
| 16 | `2_bbws_order_lambda` | Backend | Order management service |
| 17 | `2_bbws_payment_lambda` | Backend | Payment processing service |
| 18 | `2_bbws_newsletter_lambda` | Backend | Newsletter subscription service |

### Microservice to Repository Mapping

```
┌─────────────────────────────────────────────────────────────────┐
│           MICROSERVICE TO REPOSITORY MAPPING                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Microservice          Repository                  API Prefix   │
│  ─────────────         ──────────────────────      ──────────   │
│  Auth Service      →   2_bbws_auth_lambda          /v1.0/auth   │
│  Marketing Service →   2_bbws_marketing_lambda     /v1.0/campaigns │
│  Product Service   →   2_bbws_product_lambda       /v1.0/products │
│  Contact Service   →   2_bbws_contact_lambda       /v1.0/contact │
│  Invitation Service→   2_bbws_invitation_lambda    /v1.0/invitations │
│  Cart Service      →   2_bbws_cart_lambda          /v1.0/cart   │
│  Order Service     →   2_bbws_order_lambda         /v1.0/tenants/*/orders │
│  Payment Service   →   2_bbws_payment_lambda       /v1.0/tenants/*/orders/*/payments │
│  Newsletter Service→   2_bbws_newsletter_lambda    /v1.0/newsletter │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Decision Rules

### Rule 1: Standard Repos Are Mandatory

```
EVERY project MUST include:
- {prefix}_docs
- {prefix}_operations
- {prefix}_agents
- {prefix}_common
- {prefix}_tests

Optional (based on need):
- {prefix}_infra (shared infrastructure)
```

### Rule 2: One Service = One Repo

```
IF creating a new microservice
THEN create a new repository: {prefix}_{service}_lambda

DO NOT put multiple services in one repo
DO NOT share Lambda code across repos (use _common for shared code)
```

### Rule 3: Infrastructure Per Component

```
EACH microservice repo MUST have:
└── terraform/
    ├── main.tf
    ├── api_gateway.tf
    ├── lambda.tf
    └── variables.tf

DO NOT create a shared terraform repo for all services
```

### Rule 4: Naming Consistency

```
Pattern: {phase}_{project}_{component}

Examples:
✓ 2_bbws_auth_lambda
✓ 2_bbws_web_public
✓ 2_bbws_docs

✗ bbws-auth-service
✗ auth-lambda
✗ 2-bbws-auth
```

### Rule 5: LLD Documents Go in _docs

```
LLDs are stored in: {prefix}_docs/LLDs/

NOT in individual microservice repos
This keeps documentation centralized and discoverable
```

---

## Workflow: Applying This Skill

### Step 1: Identify Project Prefix

```
1. Determine project phase number
2. Determine project short name
3. Combine: {phase}_{project}_

Example: Phase 2, BBWS project → 2_bbws_
```

### Step 2: List Standard Repositories

```
Always include these 5 repos:
1. {prefix}_docs
2. {prefix}_operations
3. {prefix}_agents
4. {prefix}_common
5. {prefix}_tests
```

### Step 3: Identify Microservices

```
From the HLD Section 4 (Microservices):
1. List each service
2. Create repo name: {prefix}_{service}_lambda
3. Map API prefix to repo
```

### Step 4: Identify Frontend Apps

```
From the HLD Section 3 (Screens):
1. Group screens by portal/app
2. Create repo name: {prefix}_web_{portal}
```

### Step 5: Review for Completeness

```
Check:
- All standard repos present
- All microservices have repos
- All frontends have repos
- Database schema repo if needed
- No orphaned services without repos
```

---

## Success Criteria

This skill has been applied successfully when:

1. **Standard Repos Present**: All 5 standard repos listed
2. **Consistent Naming**: All repos follow `{prefix}_{component}` pattern
3. **Complete Mapping**: Every microservice has a corresponding repo
4. **Clear Ownership**: Each repo has clear purpose and contents
5. **Infrastructure Per Component**: Each service repo has `/terraform` folder

---

## Error Handling

### Missing Standard Repos

```
IF reviewing HLD and standard repos missing
THEN:
  1. Flag the missing repos
  2. Add them to repository list
  3. Document their purpose
```

### Inconsistent Naming

```
IF repo names don't follow pattern
THEN:
  1. Propose corrected names
  2. Update all references in HLD
  3. Document naming convention
```

### Shared Infrastructure Anti-Pattern

```
IF HLD proposes shared terraform repo
THEN:
  1. Question the need
  2. Propose per-component approach
  3. Only allow shared for truly cross-cutting resources
```

---

## Abstraction Notes

**Generalized From**:
- BBWS Customer Portal repository structure
- Multi-phase project organization patterns
- Microservice architecture best practices

**Privacy Applied**:
- Removed specific project details
- Abstracted business-specific naming
- Preserved structural patterns only

**Assumptions**:
- AWS Lambda-based microservices
- Per-component Terraform infrastructure
- Centralized documentation in _docs repo
- AI agent automation via _agents repo

---

## Related Skills

- `hateoas_relational_design.skill.md` - API hierarchy patterns
- `soft_delete_pattern.skill.md` - Data management patterns

---

## Version History

- **v1.0** (2025-12-17): Extracted from BBWS HLD architecture sessions - repository organization patterns
