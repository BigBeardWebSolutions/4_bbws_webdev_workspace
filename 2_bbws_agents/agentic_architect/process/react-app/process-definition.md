# React Application SDLC - Process Definition (Machine-Readable)

**Process Name**: BBWS React Application SDLC
**Version**: 1.0
**Created**: 2026-01-01
**Design Source**: [main-plan.md](./main-plan.md)

---

## Process Metadata

```yaml
process:
  name: "BBWS React Application SDLC"
  version: "1.0"
  type: "frontend"
  stage_count: 6
  total_workers: 22
  approval_gates: 2
  estimated_duration:
    agentic: "9.5 hours"
    manual: "66 hours"
  orchestrator: "Agentic_Project_Manager"
  technology_stack:
    framework: "React 18"
    language: "TypeScript"
    build_tool: "Vite"
    styling: "TailwindCSS"
    state: "React Query + Zustand"
    testing: "Vitest + RTL"
    hosting: "S3 + CloudFront"
    cicd: "GitHub Actions"
```

---

## Stage Specifications

### Stage F1: UI/UX Design

```yaml
stage:
  id: "stage-f1-ui-ux-design"
  name: "UI/UX Design"
  worker_count: 4
  dependencies: []
  agent: "UI_UX_Designer"
  skill: "ui_ux_designer.skill.md"

workers:
  - id: "worker-1-user-research"
    objective: "Conduct user research & personas"
    inputs:
      - "Business requirements"
      - "Target audience info"
    outputs:
      - "designs/research/personas.md"
      - "designs/research/journey-maps.md"
    success_criteria:
      - "At least 3 user personas defined"
      - "User journey maps created"

  - id: "worker-2-wireframes"
    objective: "Create wireframes for all screens"
    inputs:
      - "User personas"
      - "Feature requirements"
    outputs:
      - "designs/wireframes/"
    success_criteria:
      - "All primary screens wireframed"
      - "Navigation flows clear"

  - id: "worker-3-design-system"
    objective: "Define design system & components"
    inputs:
      - "Brand guidelines"
    outputs:
      - "designs/system/colors.md"
      - "designs/system/typography.md"
      - "designs/system/components.md"
    success_criteria:
      - "Color palette with accessibility contrast"
      - "Typography hierarchy established"
      - "Component library documented"

  - id: "worker-4-mockups"
    objective: "Create high-fidelity mockups"
    inputs:
      - "Wireframes"
      - "Design system"
    outputs:
      - "designs/mockups/"
    success_criteria:
      - "All screens in high-fidelity"
      - "Responsive variants (desktop, tablet, mobile)"
      - "Component states documented"

validation_gate: null
```

### Stage F2: Prototype & Mockups

```yaml
stage:
  id: "stage-f2-prototype"
  name: "Prototype & Mockups"
  worker_count: 3
  dependencies: ["stage-f1-ui-ux-design"]
  agent: "Web_Developer_Agent"
  skill: "web_design_fundamentals.skill.md"

workers:
  - id: "worker-1-figma-prototype"
    objective: "Create interactive Figma prototype"
    inputs:
      - "High-fidelity mockups"
    outputs:
      - "designs/prototypes/figma-link.md"
    success_criteria:
      - "All primary flows interactive"
      - "Transitions smooth and realistic"

  - id: "worker-2-user-flows"
    objective: "Document complete user flows"
    inputs:
      - "Wireframes"
      - "User personas"
    outputs:
      - "designs/flows/"
    success_criteria:
      - "All critical flows documented"
      - "Decision points identified"

  - id: "worker-3-stakeholder-review"
    objective: "Conduct stakeholder review session"
    inputs:
      - "Figma prototype"
    outputs:
      - "Review feedback document"
    success_criteria:
      - "Feedback documented"
      - "Approval for development obtained"

validation_gate: null
```

### Stage F3: React Implementation with Mock API

```yaml
stage:
  id: "stage-f3-react-mock-api"
  name: "React + Mock API"
  worker_count: 5
  dependencies: ["stage-f2-prototype"]
  agent: "Web_Developer_Agent"
  skill: "react_landing_page.skill.md"
  secondary_skill: "spa_developer.skill.md"

workers:
  - id: "worker-1-project-setup"
    objective: "Initialize React project with tooling"
    inputs:
      - "Technology stack requirements"
    outputs:
      - "package.json"
      - "vite.config.ts"
      - "tsconfig.json"
      - "tailwind.config.js"
    success_criteria:
      - "Project builds successfully"
      - "TypeScript configured strictly"
      - "ESLint and Prettier configured"

  - id: "worker-2-mock-api"
    objective: "Create mock API with realistic data"
    inputs:
      - "API contract/specification"
    outputs:
      - "src/mocks/handlers.ts"
      - "src/mocks/data/"
    success_criteria:
      - "All CRUD endpoints mocked"
      - "Response formats match API spec"
      - "Error scenarios mockable"

  - id: "worker-3-components"
    objective: "Implement reusable components"
    inputs:
      - "Design system"
      - "Mockups"
    outputs:
      - "src/components/"
    success_criteria:
      - "All design system components implemented"
      - "Components match Figma designs"
      - "Accessibility attributes included"

  - id: "worker-4-pages"
    objective: "Build application pages"
    inputs:
      - "Components"
      - "User flows"
    outputs:
      - "src/pages/"
    success_criteria:
      - "All pages functional with mock data"
      - "Routing configured"
      - "Loading and error states implemented"

  - id: "worker-5-state-management"
    objective: "Implement state management"
    inputs:
      - "API contract"
    outputs:
      - "src/store/"
      - "src/hooks/"
    success_criteria:
      - "Server state managed with React Query"
      - "Client state minimal and focused"
      - "Optimistic updates implemented"

validation_gate: null
```

### Stage F4: Frontend Tests

```yaml
stage:
  id: "stage-f4-frontend-tests"
  name: "Frontend Tests"
  worker_count: 4
  dependencies: ["stage-f3-react-mock-api"]
  agent: "SDET_Engineer_Agent"
  skill: "website_testing.skill.md"

workers:
  - id: "worker-1-test-setup"
    objective: "Configure testing framework"
    inputs:
      - "Project structure"
    outputs:
      - "vitest.config.ts"
      - "src/setupTests.ts"
    success_criteria:
      - "Vitest configured and running"
      - "MSW integrated for API mocking"
      - "Coverage thresholds set (70%)"

  - id: "worker-2-unit-tests"
    objective: "Write unit tests for utilities/hooks"
    inputs:
      - "src/utils/"
      - "src/hooks/"
    outputs:
      - "src/__tests__/unit/"
    success_criteria:
      - "All utility functions tested"
      - "All custom hooks tested"
      - "80%+ coverage on utils/hooks"

  - id: "worker-3-component-tests"
    objective: "Write component tests"
    inputs:
      - "src/components/"
    outputs:
      - "src/__tests__/components/"
    success_criteria:
      - "All components have tests"
      - "Props variations tested"
      - "70%+ component coverage"

  - id: "worker-4-integration-tests"
    objective: "Write integration tests"
    inputs:
      - "src/pages/"
      - "User flows"
    outputs:
      - "src/__tests__/integration/"
    success_criteria:
      - "All critical user flows tested"
      - "Success and error paths covered"
      - "Tests are stable (no flaky tests)"

validation_gate:
  id: "gate-f1-code-review"
  approvers: ["Tech Lead", "UX Lead"]
  criteria:
    - "Test coverage >= 70%"
    - "All tests passing"
    - "UI matches approved designs"
    - "No accessibility issues"
```

### Stage F5: API Integration

```yaml
stage:
  id: "stage-f5-api-integration"
  name: "API Integration"
  worker_count: 3
  dependencies: ["stage-f4-frontend-tests"]
  agent: "Web_Developer_Agent"
  skill: "react_landing_page.skill.md"
  external_dependency: "Backend API deployed"

workers:
  - id: "worker-1-api-client"
    objective: "Configure API client for real endpoints"
    inputs:
      - "API base URL"
      - "Authentication method"
    outputs:
      - "src/services/api.ts"
      - "src/services/*Service.ts"
    success_criteria:
      - "API client connects to real endpoints"
      - "Error handling implemented"
      - "TypeScript types match API contracts"

  - id: "worker-2-env-config"
    objective: "Set up environment-specific configuration"
    inputs:
      - "Environment URLs"
    outputs:
      - ".env.development"
      - ".env.staging"
      - ".env.production"
      - "src/config/environment.ts"
    success_criteria:
      - "Environment files created"
      - "Build scripts for each environment"
      - "Secrets not committed to git"

  - id: "worker-3-integration-tests"
    objective: "Write API integration tests"
    inputs:
      - "API endpoints"
    outputs:
      - "tests/integration/"
    success_criteria:
      - "All CRUD operations tested against real API"
      - "Error scenarios tested"
      - "Tests run against DEV environment only"

validation_gate:
  id: "gate-f2-integration"
  approvers: ["Tech Lead", "QA Lead"]
  criteria:
    - "API integration working in DEV"
    - "All integration tests passing"
    - "Performance acceptable (< 3s response)"
```

### Stage F6: Frontend Deployment & Promotion

```yaml
stage:
  id: "stage-f6-frontend-deploy"
  name: "Frontend Deploy"
  worker_count: 3
  dependencies: ["stage-f5-api-integration"]
  agent: "DevOps_Engineer_Agent"
  skill: "github_oidc_cicd.skill.md"

workers:
  - id: "worker-1-terraform-infra"
    objective: "Create S3/CloudFront infrastructure"
    inputs:
      - "Domain name"
      - "AWS account IDs"
    outputs:
      - "terraform/main.tf"
      - "terraform/variables.tf"
      - "terraform/environments/"
    success_criteria:
      - "S3 bucket created with block public access"
      - "CloudFront distribution working"
      - "Custom domain configured"
      - "SSL certificate valid"

  - id: "worker-2-cicd-workflows"
    objective: "Create GitHub Actions workflows"
    inputs:
      - "Terraform config"
      - "Environment variables"
    outputs:
      - ".github/workflows/deploy-dev.yml"
      - ".github/workflows/deploy-sit.yml"
      - ".github/workflows/deploy-prod.yml"
    success_criteria:
      - "DEV auto-deploys on push to main"
      - "SIT requires manual trigger + confirmation"
      - "PROD requires manual trigger + strict confirmation"
      - "CloudFront invalidation automated"

  - id: "worker-3-deploy-verify"
    objective: "Deploy and verify in DEV"
    inputs:
      - "Infrastructure"
      - "CI/CD workflows"
    outputs:
      - "Deployment logs"
      - "Verification report"
    success_criteria:
      - "Site accessible via custom domain"
      - "SSL certificate valid"
      - "All pages load correctly"
      - "Performance metrics met (LCP < 2.5s)"

validation_gate: null
```

---

## Validation Gates Summary

```yaml
validation_gates:
  - id: "gate-f1-code-review"
    location: "after stage-f4-frontend-tests"
    approvers: ["Tech Lead", "UX Lead"]
    criteria:
      - "Test coverage >= 70%"
      - "All tests passing"
      - "UI matches designs"
      - "No accessibility issues"

  - id: "gate-f2-integration"
    location: "after stage-f5-api-integration"
    approvers: ["Tech Lead", "QA Lead"]
    criteria:
      - "API integration working"
      - "Integration tests passing"
      - "Performance acceptable"
```

---

## State Management

```yaml
state_management:
  state_file_pattern: "stage-{id}.state.{STATUS}"
  statuses:
    - "PENDING"
    - "IN_PROGRESS"
    - "BLOCKED"
    - "COMPLETE"
    - "FAILED"

  transitions:
    stage:
      - "Stage COMPLETE when all workers COMPLETE"
      - "Stage BLOCKED until dependencies COMPLETE"
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
    detection: "vitest exit code != 0"
    recovery: "Fix failing tests, re-run"
    retry_logic: "3 attempts"
    escalation: "After 3 failures, alert developer"

  - category: "Build Failure"
    detection: "vite build exit code != 0"
    recovery: "Check TypeScript errors, fix"
    retry_logic: "2 attempts"
    escalation: "Alert frontend lead"

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
```

---

## Template Variables

```yaml
variables:
  # Process-level
  - name: "{{PROCESS_NAME}}"
    value: "BBWS React Application SDLC"

  - name: "{{STAGE_COUNT}}"
    value: 6

  - name: "{{WORKER_COUNT}}"
    value: 22

  # Project-level (set at instantiation)
  - name: "{{APP_NAME}}"
    example: "ProductAdmin"

  - name: "{{APP_REPO}}"
    example: "2_bbws_product_admin_react"

  - name: "{{DOMAIN_DEV}}"
    example: "product-admin.dev.kimmyai.io"

  - name: "{{DOMAIN_SIT}}"
    example: "product-admin.sit.kimmyai.io"

  - name: "{{DOMAIN_PROD}}"
    example: "product-admin.kimmyai.io"

  - name: "{{API_BASE_URL}}"
    example: "https://api.dev.kimmyai.io"
```

---

## Process Instantiation

To instantiate this process for a new React application:

```bash
# 1. Set variables
APP_NAME="ProductAdmin"
APP_REPO="2_bbws_product_admin_react"

# 2. Create project folder
mkdir -p ${APP_REPO}
cd ${APP_REPO}

# 3. Copy process plan
mkdir -p .claude/plans
cp -r process/react-app/*.md .claude/plans/

# 4. Initialize work state files
cd .claude/plans
for stage in stage-f*.md; do
  touch "${stage%.md}.state.PENDING"
done

# 5. Start PM orchestration
# PM reads main-plan.md and begins execution
```

---

**Ready for Process Manager Generation**: This definition is complete and can be used to generate a Process Manager agent for automated React SDLC execution.
