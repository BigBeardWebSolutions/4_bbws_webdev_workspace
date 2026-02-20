# BBWS SDLC - Process Definition (Machine-Readable)

**Process Name**: BBWS Full-Stack SDLC (API + React + WordPress + Multi-Tenant)
**Version**: 3.0
**Created**: 2026-01-01
**Design Source**: [main-plan.md](./main-plan.md)

---

## Process Metadata

```yaml
process:
  name: "BBWS Full-Stack SDLC"
  version: "3.0"
  tracks:
    - name: "Backend"
      stages: 10
      workers: 35
    - name: "Frontend"
      stages: 6
      workers: 22
    - name: "WordPress"
      stages: 4
      workers: 13
    - name: "Tenant"
      stages: 3
      workers: 13
  stage_count: 23
  total_workers: 74
  approval_gates: 8
  estimated_duration:
    agentic: "20 hours"
    manual: "88 hours"
    wall_clock_parallel: "10 hours"
  parallelization:
    - "Backend Track (stages 4-10)"
    - "Frontend Track (stages F1-F6)"
    - "WordPress Track (stages W1-W4)"
    - "Tenant Track (stages T1-T3)"
  orchestrator: "Agentic_Project_Manager"
```

---

## Stage Specifications

### Stage 1: Requirements & Analysis

```yaml
stage:
  id: "stage-1-requirements"
  name: "Requirements & Analysis"
  worker_count: 4
  dependencies: []
  agent: "Agentic_Project_Manager"
  skill: "project_planning_skill.md"

workers:
  - id: "worker-1-stakeholder-interviews"
    objective: "Gather business requirements through stakeholder interviews"
    inputs:
      - "Business context document"
      - "Existing system documentation"
    outputs:
      - "stakeholder_notes.md"
    success_criteria:
      - "All key stakeholders interviewed"
      - "Requirements prioritized (MoSCoW)"

  - id: "worker-2-user-stories"
    objective: "Transform requirements into user stories"
    inputs:
      - "stakeholder_notes.md"
    outputs:
      - "user_stories.md"
    success_criteria:
      - "INVEST criteria satisfied"
      - "Acceptance criteria testable"

  - id: "worker-3-api-specification"
    objective: "Define API endpoints and data models"
    inputs:
      - "user_stories.md"
    outputs:
      - "api_spec.md"
    success_criteria:
      - "RESTful design principles followed"
      - "All CRUD operations defined"

  - id: "worker-4-requirements-doc"
    objective: "Consolidate into requirements document"
    inputs:
      - "All previous outputs"
    outputs:
      - "requirements.md"
    success_criteria:
      - "Complete and traceable"
      - "Approved by stakeholders"

validation_gate: null
```

### Stage 2: HLD Creation

```yaml
stage:
  id: "stage-2-hld"
  name: "HLD Creation"
  worker_count: 3
  dependencies: ["stage-1-requirements"]
  agent: "HLD_Architect_Agent"
  skill: "hld_architect.skill.md"
  template: "HLD_TEMPLATE.md"

workers:
  - id: "worker-1-hld-structure"
    objective: "Create HLD document structure"
    inputs:
      - "requirements.md"
      - "HLD_TEMPLATE.md"
    outputs:
      - "hld_intro.md"
    success_criteria:
      - "Follows HLD template structure"
      - "Business context articulated"

  - id: "worker-2-architecture-diagrams"
    objective: "Create system architecture diagrams"
    inputs:
      - "requirements.md"
      - "api_spec.md"
    outputs:
      - "architecture_diagrams.md"
    success_criteria:
      - "C4 diagrams complete"
      - "AWS services identified"

  - id: "worker-3-hld-consolidation"
    objective: "Consolidate into complete HLD"
    inputs:
      - "hld_intro.md"
      - "architecture_diagrams.md"
    outputs:
      - "HLD_{{number}}_{{service_name}}.md"
    success_criteria:
      - "All sections complete"
      - "No placeholder content"

validation_gate: null
```

### Stage 3: LLD Creation

```yaml
stage:
  id: "stage-3-lld"
  name: "LLD Creation"
  worker_count: 4
  dependencies: ["stage-2-hld"]
  agent: "LLD_Architect_Agent"
  skills:
    - "HLD_LLD_Naming_Convention.skill.md"
    - "DynamoDB_Single_Table.skill.md"
    - "HATEOAS_Relational_Design.skill.md"

workers:
  - id: "worker-1-lld-structure"
    objective: "Create LLD document structure"
    outputs: ["lld_structure.md"]

  - id: "worker-2-database-design"
    objective: "Design DynamoDB schema"
    outputs: ["database_design.md"]

  - id: "worker-3-api-contracts"
    objective: "Define detailed API contracts"
    outputs: ["api_contracts.md"]

  - id: "worker-4-lld-consolidation"
    objective: "Create complete LLD document"
    outputs: ["LLD_{{parent_hld}}_{{number}}_{{name}}.md"]

validation_gate:
  id: "gate-1-design-approval"
  approvers: ["Tech Lead", "Solutions Architect"]
  criteria:
    - "HLD and LLD complete"
    - "Architecture sound"
    - "Implementation feasible"
```

### Stage 4: API Tests (TDD)

```yaml
stage:
  id: "stage-4-api-tests"
  name: "API Tests (TDD)"
  worker_count: 4
  dependencies: ["stage-3-lld"]
  agent: "SDET_Engineer_Agent"
  skills:
    - "SDET_unit_test.skill.md"
    - "SDET_mock_test.skill.md"
    - "SDET_integration_test.skill.md"
    - "SDET_persistence_test.skill.md"
  parallelization: true

workers:
  - id: "worker-1-unit-tests"
    objective: "Write unit tests for services and validators"
    outputs: ["tests/unit/"]

  - id: "worker-2-mock-tests"
    objective: "Write mocked AWS tests (moto)"
    outputs: ["tests/unit/"]

  - id: "worker-3-integration-tests"
    objective: "Write integration test stubs"
    outputs: ["tests/integration/"]

  - id: "worker-4-e2e-tests"
    objective: "Write E2E test framework"
    outputs: ["tests/e2e/"]

validation_gate: null
```

### Stage 5: API Implementation

```yaml
stage:
  id: "stage-5-api-implementation"
  name: "API Implementation"
  worker_count: 5
  dependencies: ["stage-4-api-tests"]
  agent: "Python_AWS_Developer_Agent"
  skills:
    - "AWS_Python_Dev.skill.md"
    - "Lambda_Management.skill.md"
    - "Development_Best_Practices.skill.md"
  parallelization: true

workers:
  - id: "worker-1-models"
    objective: "Implement Pydantic models"
    outputs: ["src/models/"]

  - id: "worker-2-repository"
    objective: "Implement DynamoDB repository"
    outputs: ["src/repositories/"]

  - id: "worker-3-service"
    objective: "Implement service layer"
    outputs: ["src/services/"]

  - id: "worker-4-handlers"
    objective: "Implement Lambda handlers"
    outputs: ["src/handlers/"]

  - id: "worker-5-utils"
    objective: "Implement utilities and exceptions"
    outputs: ["src/utils/", "src/exceptions/"]

validation_gate: null
```

### Stage 6: API Proxy

```yaml
stage:
  id: "stage-6-api-proxy"
  name: "API Proxy"
  worker_count: 2
  dependencies: ["stage-5-api-implementation"]
  agent: "Python_AWS_Developer_Agent"
  skill: "AWS_Python_Dev.skill.md"

workers:
  - id: "worker-1-proxy-implementation"
    objective: "Implement API proxy class"
    outputs: ["tests/proxies/"]

  - id: "worker-2-proxy-tests"
    objective: "Write tests for proxy"
    outputs: ["tests/proxies/tests/"]

validation_gate:
  id: "gate-2-code-review"
  approvers: ["Tech Lead", "Developer Lead"]
  criteria:
    - "All tests passing"
    - "Coverage >= 80%"
    - "Code review completed"
```

### Stage 7: Infrastructure

```yaml
stage:
  id: "stage-7-infrastructure"
  name: "Infrastructure (Terraform)"
  worker_count: 4
  dependencies: ["stage-6-api-proxy"]
  agent: "DevOps_Engineer_Agent"
  skills:
    - "github_oidc_cicd.skill.md"
    - "aws_region_specification.skill.md"
    - "dns_environment_naming.skill.md"

workers:
  - id: "worker-1-terraform-structure"
    objective: "Create Terraform module structure"
    outputs: ["terraform/"]

  - id: "worker-2-lambda-resources"
    objective: "Define Lambda and API Gateway resources"
    outputs: ["terraform/*.tf"]

  - id: "worker-3-environment-configs"
    objective: "Create environment-specific configurations"
    outputs: ["terraform/environments/"]

  - id: "worker-4-terraform-validation"
    objective: "Validate and test Terraform"
    outputs: ["Validation report"]

validation_gate: null
```

### Stage 8: CI/CD Pipeline

```yaml
stage:
  id: "stage-8-cicd-pipeline"
  name: "CI/CD Pipeline"
  worker_count: 3
  dependencies: ["stage-7-infrastructure"]
  agent: "DevOps_Engineer_Agent"
  skill: "github_oidc_cicd.skill.md"

workers:
  - id: "worker-1-ci-workflow"
    objective: "Create CI workflow (test, lint, build)"
    outputs: [".github/workflows/ci.yml"]

  - id: "worker-2-deploy-workflows"
    objective: "Create deployment workflows"
    outputs:
      - ".github/workflows/deploy-dev.yml"
      - ".github/workflows/deploy-sit.yml"
      - ".github/workflows/deploy-prod.yml"

  - id: "worker-3-reusable-workflows"
    objective: "Create reusable workflow components"
    outputs: [".github/workflows/_*.yml"]

validation_gate: null
```

### Stage 9: Route53/Domain

```yaml
stage:
  id: "stage-9-route53-domain"
  name: "Route53/Custom Domain"
  worker_count: 3
  dependencies: ["stage-8-cicd-pipeline"]
  agent: "DevOps_Engineer_Agent"
  skill: "dns_environment_naming.skill.md"

workers:
  - id: "worker-1-custom-domain-reference"
    objective: "Reference shared custom domain"
    outputs: ["terraform/custom_domain.tf"]

  - id: "worker-2-base-path-mapping"
    objective: "Create API Gateway base path mapping"
    outputs: ["terraform/api_gateway.tf"]

  - id: "worker-3-domain-verification"
    objective: "Verify domain accessibility"
    outputs: ["Verification report"]

validation_gate:
  id: "gate-3-infra-review"
  approvers: ["DevOps Lead", "Tech Lead"]
  criteria:
    - "Infrastructure deployed"
    - "CI/CD working"
    - "Custom domain accessible"
```

### Stage 10: Deploy & Test

```yaml
stage:
  id: "stage-10-deploy-test"
  name: "Deploy & Test"
  worker_count: 3
  dependencies: ["stage-9-route53-domain"]
  agents:
    - "DevOps_Engineer_Agent"
    - "SDET_Engineer_Agent"
  skills:
    - "github_oidc_cicd.skill.md"
    - "SDET_integration_test.skill.md"

workers:
  - id: "worker-1-deploy-dev"
    objective: "Deploy to DEV environment"
    outputs: ["Deployment logs"]

  - id: "worker-2-e2e-validation"
    objective: "Run E2E test suite"
    outputs: ["Test report"]

  - id: "worker-3-runbooks"
    objective: "Create operational runbooks"
    outputs:
      - "deployment-runbook.md"
      - "promotion-runbook.md"
      - "troubleshooting-runbook.md"
      - "rollback-runbook.md"

validation_gate:
  id: "gate-4-production-ready"
  approvers: ["Product Owner", "Operations Lead"]
  criteria:
    - "DEV deployment successful"
    - "All E2E tests passing"
    - "Runbooks reviewed"
    - "Ready for SIT promotion"
```

---

## Validation Gate Definitions

```yaml
validation_gates:
  - id: "gate-1-design-approval"
    location: "after stage-3-lld"
    approvers: ["Tech Lead", "Solutions Architect"]
    rules:
      - "HLD document complete"
      - "LLD document complete"
      - "Architecture reviewed"
      - "No technical debt"
    pass_action: "proceed to stage-4"
    fail_action: "revise design documents"

  - id: "gate-2-code-review"
    location: "after stage-6-api-proxy"
    approvers: ["Tech Lead", "Developer Lead"]
    rules:
      - "All unit tests pass"
      - "Coverage >= 80%"
      - "Code review completed"
      - "No security issues"
    pass_action: "proceed to stage-7"
    fail_action: "fix code issues"

  - id: "gate-3-infra-review"
    location: "after stage-9-route53-domain"
    approvers: ["DevOps Lead", "Tech Lead"]
    rules:
      - "Terraform validated"
      - "CI/CD pipelines working"
      - "Custom domain accessible"
    pass_action: "proceed to stage-10"
    fail_action: "fix infrastructure"

  - id: "gate-4-production-ready"
    location: "after stage-10-deploy-test"
    approvers: ["Product Owner", "Operations Lead"]
    rules:
      - "DEV deployment successful"
      - "All E2E tests pass (100%)"
      - "Runbooks complete"
      - "No critical issues"
    pass_action: "mark SDLC complete"
    fail_action: "resolve issues"
```

---

## State Management Configuration

```yaml
state_management:
  levels: ["project", "stage", "worker"]
  states: ["PENDING", "IN_PROGRESS", "COMPLETE"]

  file_pattern: "work.state.{{STATUS}}"

  transition_rules:
    project:
      - "Project COMPLETE when all stages COMPLETE"
    stage:
      - "Stage COMPLETE when all workers COMPLETE"
      - "Stage blocked until dependencies COMPLETE"
    worker:
      - "Worker COMPLETE when output exists and criteria met"

  resumption_checkpoints:
    - "After each stage completion"
    - "After each approval gate"
```

---

## Error Handling Rules

```yaml
error_handling:
  - category: "Test Failure"
    detection: "pytest exit code != 0"
    recovery: "Fix failing tests, re-run"
    retry_logic: "3 attempts"
    escalation: "After 3 failures, alert developer"

  - category: "Terraform Failure"
    detection: "terraform apply exit code != 0"
    recovery: "Review plan, fix configuration"
    retry_logic: "2 attempts with plan review"
    escalation: "Alert DevOps lead"

  - category: "Deployment Failure"
    detection: "CI/CD workflow fails"
    recovery: "Check logs, fix issue, retry"
    retry_logic: "Manual retry after fix"
    escalation: "Alert team lead"

  - category: "E2E Test Failure"
    detection: "E2E tests fail post-deployment"
    recovery: "Diagnose, fix, redeploy"
    retry_logic: "Manual after fix"
    escalation: "Block promotion until resolved"
```

---

## Frontend Track Specifications

### Stage F1: UI/UX Design

```yaml
stage:
  id: "stage-f1-ui-ux-design"
  name: "UI/UX Design"
  track: "Frontend"
  worker_count: 4
  dependencies: ["stage-3-lld"]
  agent: "UI_UX_Designer"
  skill: "ui_ux_designer.skill.md"

workers:
  - id: "worker-1-user-research"
    objective: "Conduct user research & personas"
    outputs: ["designs/research/"]

  - id: "worker-2-wireframes"
    objective: "Create wireframes for all screens"
    outputs: ["designs/wireframes/"]

  - id: "worker-3-design-system"
    objective: "Define design system & components"
    outputs: ["designs/system/"]

  - id: "worker-4-mockups"
    objective: "Create high-fidelity mockups"
    outputs: ["designs/mockups/"]

validation_gate: null
```

### Stage F2-F6: (See stage files for full specifications)

---

## WordPress Track Specifications

### Stage W1: WordPress Theme Development

```yaml
stage:
  id: "stage-w1-theme-dev"
  name: "WordPress Theme Development"
  track: "WordPress"
  worker_count: 3
  dependencies: ["stage-3-lld"]
  agent: "Web_Developer_Agent"
  skill: "wordpress_theme.skill.md"

workers:
  - id: "worker-1-theme-structure"
    objective: "Create theme base structure"
    outputs: ["themes/bbws-starter/"]

  - id: "worker-2-template-system"
    objective: "Build template system for AI"
    outputs: ["templates/"]

  - id: "worker-3-style-system"
    objective: "Create configurable style system"
    outputs: ["styles/"]

validation_gate: null
```

### Stage W2: AI Site Generation

```yaml
stage:
  id: "stage-w2-ai-generation"
  name: "AI Site Generation"
  track: "WordPress"
  worker_count: 4
  dependencies: ["stage-w1-theme-dev"]
  agent: "AI_Website_Generator"
  skill: "aws-ai-website-generator.skill.md"

workers:
  - id: "worker-1-content-generation"
    objective: "Generate site content with Claude"
    outputs: ["generated/content.json"]

  - id: "worker-2-image-generation"
    objective: "Generate images with Stable Diffusion"
    outputs: ["generated/images/"]

  - id: "worker-3-static-build"
    objective: "Build static site from templates"
    outputs: ["dist/"]

  - id: "worker-4-tenant-association"
    objective: "Associate site with tenant"
    outputs: ["DynamoDB record"]

validation_gate: null
```

### Stage W3-W4: (See stage files for full specifications)

---

## Tenant Management Track Specifications

### Stage T1: Tenant API Implementation

```yaml
stage:
  id: "stage-t1-tenant-api"
  name: "Tenant API Implementation"
  track: "Tenant"
  worker_count: 4
  dependencies: ["stage-3-lld"]
  agent: "Python_AWS_Developer_Agent"
  skill: "AWS_Python_Dev.skill.md"

workers:
  - id: "worker-1-tenant-models"
    objective: "Create Pydantic models for tenant"
    outputs: ["src/models/tenant.py"]

  - id: "worker-2-tenant-repository"
    objective: "Implement DynamoDB repository"
    outputs: ["src/repositories/tenant_repository.py"]

  - id: "worker-3-tenant-service"
    objective: "Implement tenant service layer"
    outputs: ["src/services/tenant_service.py"]

  - id: "worker-4-tenant-handlers"
    objective: "Create Lambda handlers"
    outputs: ["src/handlers/tenant_handlers.py"]

validation_gate: null
```

### Stage T2: User Hierarchy System

```yaml
stage:
  id: "stage-t2-user-hierarchy"
  name: "User Hierarchy System"
  track: "Tenant"
  worker_count: 4
  dependencies: ["stage-t1-tenant-api"]
  agent: "Python_AWS_Developer_Agent"
  skill: "AWS_Python_Dev.skill.md"

workers:
  - id: "worker-1-hierarchy-models"
    objective: "Create hierarchy data models"
    outputs: ["src/models/hierarchy.py"]

  - id: "worker-2-hierarchy-repository"
    objective: "Implement DynamoDB for hierarchy"
    outputs: ["src/repositories/hierarchy_repository.py"]

  - id: "worker-3-user-service"
    objective: "Implement user management service"
    outputs: ["src/services/user_service.py"]

  - id: "worker-4-invitation-system"
    objective: "Build invitation system"
    outputs: ["src/services/invitation_service.py"]

validation_gate: null
```

### Stage T3: Access Control & RBAC

```yaml
stage:
  id: "stage-t3-access-control"
  name: "Access Control & RBAC"
  track: "Tenant"
  worker_count: 5
  dependencies: ["stage-t2-user-hierarchy"]
  agent: "Python_AWS_Developer_Agent"
  skill: "AWS_Python_Dev.skill.md"

workers:
  - id: "worker-1-role-models"
    objective: "Define role and permission models"
    outputs: ["src/models/permissions.py"]

  - id: "worker-2-auth-service"
    objective: "Implement authorization service"
    outputs: ["src/services/auth_service.py"]

  - id: "worker-3-middleware"
    objective: "Create authorization middleware"
    outputs: ["src/middleware/auth_middleware.py"]

  - id: "worker-4-isolation-tests"
    objective: "Write tenant isolation tests"
    outputs: ["tests/integration/test_tenant_isolation.py"]

  - id: "worker-5-integration"
    objective: "Integrate RBAC with all APIs"
    outputs: ["All handlers updated"]

validation_gate:
  id: "gate-t1-tenant-review"
  approvers: ["Tech Lead", "Security Lead"]
  criteria:
    - "RBAC implementation complete"
    - "Tenant isolation verified"
    - "Security review passed"
```

---

## Extended Validation Gates

```yaml
validation_gates:
  # Backend Gates (existing)
  - id: "gate-1-design-approval"
    location: "after stage-3-lld"

  - id: "gate-2-code-review"
    location: "after stage-6-api-proxy"

  - id: "gate-3-infra-review"
    location: "after stage-9-route53-domain"

  # Frontend Gates
  - id: "gate-f1-frontend-review"
    location: "after stage-f4-frontend-tests"
    approvers: ["Tech Lead", "UX Lead"]
    criteria:
      - "Test coverage >= 70%"
      - "All tests passing"
      - "UI matches designs"

  - id: "gate-f2-integration"
    location: "after stage-f5-api-integration"
    approvers: ["Tech Lead", "QA Lead"]
    criteria:
      - "API integration working"
      - "Integration tests passing"

  # WordPress Gates
  - id: "gate-w1-wordpress-review"
    location: "after stage-w4-testing"
    approvers: ["Tech Lead", "Content Lead"]
    criteria:
      - "Sites functional"
      - "Accessibility compliance"
      - "Performance >= 80"

  # Tenant Gates
  - id: "gate-t1-tenant-review"
    location: "after stage-t3-access-control"
    approvers: ["Tech Lead", "Security Lead"]
    criteria:
      - "RBAC complete"
      - "Tenant isolation verified"

  # Final Gate
  - id: "gate-4-production-ready"
    location: "after stage-f6-frontend-deploy"
    approvers: ["Product Owner", "Operations Lead"]
    criteria:
      - "All tracks complete"
      - "All E2E tests pass"
      - "Documentation complete"
```

---

## Template Variables

```yaml
variables:
  # Process-level
  - name: "{{PROCESS_NAME}}"
    value: "BBWS Full-Stack SDLC"

  - name: "{{STAGE_COUNT}}"
    value: 23

  - name: "{{WORKER_COUNT}}"
    value: 74

  - name: "{{TRACKS}}"
    value: ["Backend", "Frontend", "WordPress", "Tenant"]

  # Service-level (set at instantiation)
  - name: "{{SERVICE_NAME}}"
    example: "Product"

  - name: "{{SERVICE_REPO}}"
    example: "2_bbws_product_lambda"

  - name: "{{FRONTEND_REPO}}"
    example: "2_bbws_product_react"

  - name: "{{WP_REPO}}"
    example: "2_bbws_sites_wordpress"

  - name: "{{TENANT_ID}}"
    example: "TEN-ACME123"

  - name: "{{HLD_NUMBER}}"
    example: "3.2"

  - name: "{{LLD_NUMBER}}"
    example: "2.1.5"
```

---

## Process Instantiation

To instantiate this process for a new project:

```bash
# 1. Set variables based on project type
PROJECT_TYPE="api"  # Options: api, react, wordpress, landing, newsletter, blog
SERVICE_NAME="Order"
SERVICE_REPO="2_bbws_order_lambda"
HLD_NUMBER="3.3"
LLD_NUMBER="2.1.6"

# 2. Create project folder
mkdir -p 2_bbws_docs/LLDs/project-plan-${LLD_NUMBER}

# 3. Copy appropriate process template
if [ "$PROJECT_TYPE" = "api" ]; then
  cp -r process/bbws-sdlc-v1/stage-{1..10}*.md project-plan-${LLD_NUMBER}/
elif [ "$PROJECT_TYPE" = "react" ]; then
  cp -r process/bbws-sdlc-v1/stage-{1..3}*.md project-plan-${LLD_NUMBER}/
  cp -r process/bbws-sdlc-v1/stage-f*.md project-plan-${LLD_NUMBER}/
elif [ "$PROJECT_TYPE" = "wordpress" ]; then
  cp -r process/bbws-sdlc-v1/stage-1*.md project-plan-${LLD_NUMBER}/
  cp -r process/bbws-sdlc-v1/stage-w*.md project-plan-${LLD_NUMBER}/
fi

# 4. Copy main plan
cp process/bbws-sdlc-v1/main-plan.md project-plan-${LLD_NUMBER}/

# 5. Initialize work state files
cd project-plan-${LLD_NUMBER}
for stage in stage-*.md; do
  touch "${stage%.md}.state.PENDING"
done

# 6. Start PM orchestration
# PM reads main-plan.md and begins execution
```

---

**Ready for Process Manager Generation**: This definition is complete and can be used to generate a Process Manager agent for automated SDLC execution across all tracks.

**Process Type Templates**: See `../api-service/`, `../react-app/`, `../wordpress-site/`, `../landing-page/`, `../newsletter/`, `../blog/` for project-specific process templates.
