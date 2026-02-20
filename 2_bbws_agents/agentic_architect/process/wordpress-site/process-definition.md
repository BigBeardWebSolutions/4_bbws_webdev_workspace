# WordPress & Tenant SDLC - Process Definition (Machine-Readable)

**Process Name**: BBWS WordPress Site & Multi-Tenant SDLC
**Version**: 1.0
**Created**: 2026-01-01
**Design Source**: [main-plan.md](./main-plan.md)

---

## Process Metadata

```yaml
process:
  name: "BBWS WordPress Site & Multi-Tenant SDLC"
  version: "1.0"
  type: "wordpress-tenant"
  tracks:
    - name: "WordPress"
      stages: 4
      workers: 13
    - name: "Tenant"
      stages: 3
      workers: 13
  stage_count: 7
  total_workers: 26
  approval_gates: 2
  estimated_duration:
    agentic: "9 hours"
    manual: "38 hours"
  parallelization:
    - "WordPress Track (W1-W4)"
    - "Tenant Track (T1-T3)"
  orchestrator: "Agentic_Project_Manager"
  technology_stack:
    ai_content: "AWS Bedrock - Claude Sonnet 3.5"
    ai_images: "AWS Bedrock - Stable Diffusion XL"
    output: "Static HTML/CSS/JS"
    hosting: "S3 + CloudFront"
    backend: "Python 3.12 + Lambda"
    database: "DynamoDB"
```

---

## WordPress Track Specifications

### Stage W1: WordPress Theme Development

```yaml
stage:
  id: "stage-w1-theme-dev"
  name: "WordPress Theme Development"
  track: "WordPress"
  worker_count: 3
  dependencies: []
  agent: "Web_Developer_Agent"
  skill: "wordpress_theme.skill.md"

workers:
  - id: "worker-1-theme-structure"
    objective: "Create theme base structure"
    outputs:
      - "themes/bbws-starter/"
    success_criteria:
      - "Theme structure follows WordPress standards"
      - "Modular component architecture"
      - "Static export compatible"

  - id: "worker-2-template-system"
    objective: "Build template system for AI"
    outputs:
      - "themes/bbws-starter/templates/"
    success_criteria:
      - "All dynamic content uses placeholders"
      - "Placeholders documented"
      - "AI generation ready"

  - id: "worker-3-style-system"
    objective: "Create configurable style system"
    outputs:
      - "themes/bbws-starter/styles/"
      - "themes/bbws-starter/config/theme.json"
    success_criteria:
      - "CSS variables for all customizable properties"
      - "JSON configuration schema"
      - "Responsive design system"

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
    inputs:
      - "Business information"
      - "Industry context"
    outputs:
      - "generated/content.json"
    success_criteria:
      - "Content generated successfully"
      - "JSON schema validated"
      - "Content appropriate for industry"

  - id: "worker-2-image-generation"
    objective: "Generate images with Stable Diffusion"
    inputs:
      - "Content themes"
      - "Style preferences"
    outputs:
      - "generated/images/"
    success_criteria:
      - "Hero image generated"
      - "Images optimized for web (WebP)"
      - "Consistent style across images"

  - id: "worker-3-static-build"
    objective: "Build static site from templates"
    inputs:
      - "Templates"
      - "Generated content"
      - "Generated images"
    outputs:
      - "dist/"
    success_criteria:
      - "All pages generated"
      - "Assets optimized"
      - "Valid HTML5"

  - id: "worker-4-tenant-association"
    objective: "Associate site with tenant"
    inputs:
      - "Tenant ID"
      - "Site configuration"
    outputs:
      - "DynamoDB site record"
    success_criteria:
      - "Site registered in DynamoDB"
      - "Tenant association correct"
      - "Metadata complete"

validation_gate: null
```

### Stage W3: WordPress Deployment

```yaml
stage:
  id: "stage-w3-deployment"
  name: "WordPress Deployment"
  track: "WordPress"
  worker_count: 3
  dependencies: ["stage-w2-ai-generation"]
  agent: "DevOps_Engineer_Agent"
  skill: "github_oidc_cicd.skill.md"

workers:
  - id: "worker-1-s3-setup"
    objective: "Create S3 bucket with tenant isolation"
    outputs:
      - "terraform/s3.tf"
    success_criteria:
      - "S3 bucket created"
      - "Public access blocked"
      - "Tenant prefixes isolated"

  - id: "worker-2-cloudfront"
    objective: "Configure CloudFront distribution"
    outputs:
      - "terraform/cloudfront.tf"
      - "lambda/tenant-router/"
    success_criteria:
      - "CloudFront distribution created"
      - "Lambda@Edge router deployed"
      - "Wildcard SSL configured"

  - id: "worker-3-domain-mapping"
    objective: "Set up tenant domain mapping"
    outputs:
      - "terraform/route53.tf"
    success_criteria:
      - "Wildcard DNS record created"
      - "DNS resolves correctly"
      - "SSL works for all subdomains"

validation_gate: null
```

### Stage W4: WordPress Testing

```yaml
stage:
  id: "stage-w4-testing"
  name: "WordPress Testing"
  track: "WordPress"
  worker_count: 3
  dependencies: ["stage-w3-deployment"]
  agent: "SDET_Engineer_Agent"
  skill: "website_testing.skill.md"

workers:
  - id: "worker-1-functional-tests"
    objective: "Run functional site tests"
    outputs:
      - "reports/functional/"
    success_criteria:
      - "All pages load successfully"
      - "All internal links work"
      - "Mobile responsive works"

  - id: "worker-2-accessibility"
    objective: "Run accessibility audit (WCAG)"
    outputs:
      - "reports/accessibility/"
    success_criteria:
      - "No WCAG 2.1 AA violations"
      - "Accessibility score >= 90"
      - "Screen reader compatible"

  - id: "worker-3-performance"
    objective: "Run performance tests (Lighthouse)"
    outputs:
      - "reports/performance/"
    success_criteria:
      - "Lighthouse performance >= 80"
      - "LCP < 2.5s"
      - "CLS < 0.1"

validation_gate:
  id: "gate-w1-site-review"
  approvers: ["Tech Lead", "Content Lead"]
  criteria:
    - "Sites functional"
    - "Accessibility compliance"
    - "Performance >= 80"
```

---

## Tenant Track Specifications

### Stage T1: Tenant API Implementation

```yaml
stage:
  id: "stage-t1-tenant-api"
  name: "Tenant API Implementation"
  track: "Tenant"
  worker_count: 4
  dependencies: []
  agent: "Python_AWS_Developer_Agent"
  skill: "AWS_Python_Dev.skill.md"

workers:
  - id: "worker-1-tenant-models"
    objective: "Create Pydantic models for tenant"
    outputs:
      - "src/models/tenant.py"
    success_criteria:
      - "All models defined with validation"
      - "Config includes destination_email"
      - "Status enum defined"

  - id: "worker-2-tenant-repository"
    objective: "Implement DynamoDB repository"
    outputs:
      - "src/repositories/tenant_repository.py"
    success_criteria:
      - "CRUD operations implemented"
      - "GSI queries optimized"
      - "Error handling complete"

  - id: "worker-3-tenant-service"
    objective: "Implement tenant service layer"
    outputs:
      - "src/services/tenant_service.py"
    success_criteria:
      - "Business logic encapsulated"
      - "Validation in place"
      - "Error handling complete"

  - id: "worker-4-tenant-handlers"
    objective: "Create Lambda handlers"
    outputs:
      - "src/handlers/tenant_handlers.py"
    success_criteria:
      - "All CRUD endpoints implemented"
      - "Proper HTTP status codes"
      - "Input validation with Pydantic"

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
    outputs:
      - "src/models/hierarchy.py"
    success_criteria:
      - "Division, Group, Team, User models"
      - "Multi-team membership supported"
      - "Validation rules applied"

  - id: "worker-2-hierarchy-repository"
    objective: "Implement DynamoDB for hierarchy"
    outputs:
      - "src/repositories/hierarchy_repository.py"
    success_criteria:
      - "All hierarchy CRUD implemented"
      - "Efficient query patterns"
      - "Multi-team membership working"

  - id: "worker-3-user-service"
    objective: "Implement user management service"
    outputs:
      - "src/services/user_service.py"
    success_criteria:
      - "User CRUD operations"
      - "Multi-team membership management"
      - "Tenant isolation enforced"

  - id: "worker-4-invitation-system"
    objective: "Build invitation system"
    outputs:
      - "src/services/invitation_service.py"
    success_criteria:
      - "Invitation creation working"
      - "Email sending via SES"
      - "Expiration handling"

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
    outputs:
      - "src/models/permissions.py"
    success_criteria:
      - "All permissions defined"
      - "Role hierarchy implemented"
      - "Permission mapping complete"

  - id: "worker-2-auth-service"
    objective: "Implement authorization service"
    outputs:
      - "src/services/auth_service.py"
    success_criteria:
      - "Permission checking works"
      - "Tenant isolation enforced"
      - "Admin bypass functional"

  - id: "worker-3-middleware"
    objective: "Create authorization middleware"
    outputs:
      - "src/middleware/auth_middleware.py"
    success_criteria:
      - "Middleware decorators working"
      - "Permission checking in middleware"
      - "Clean error messages"

  - id: "worker-4-isolation-tests"
    objective: "Write tenant isolation tests"
    outputs:
      - "tests/integration/test_tenant_isolation.py"
    success_criteria:
      - "Cross-tenant access denied"
      - "Cross-team access denied"
      - "Multi-team membership working"

  - id: "worker-5-integration"
    objective: "Integrate RBAC with all APIs"
    outputs:
      - "All handlers updated with decorators"
    success_criteria:
      - "All handlers protected"
      - "Consistent authorization"
      - "Performance acceptable"

validation_gate:
  id: "gate-t1-security-review"
  approvers: ["Tech Lead", "Security Lead"]
  criteria:
    - "RBAC implementation complete"
    - "Tenant isolation verified"
    - "Security review passed"
```

---

## Validation Gates Summary

```yaml
validation_gates:
  - id: "gate-w1-site-review"
    location: "after stage-w4-testing"
    approvers: ["Tech Lead", "Content Lead"]
    criteria:
      - "Sites functional"
      - "Accessibility compliance"
      - "Performance >= 80"

  - id: "gate-t1-security-review"
    location: "after stage-t3-access-control"
    approvers: ["Tech Lead", "Security Lead"]
    criteria:
      - "RBAC complete"
      - "Tenant isolation verified"
      - "Security review passed"
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
```

---

## Template Variables

```yaml
variables:
  # Process-level
  - name: "{{PROCESS_NAME}}"
    value: "BBWS WordPress Site & Multi-Tenant SDLC"

  - name: "{{STAGE_COUNT}}"
    value: 7

  - name: "{{WORKER_COUNT}}"
    value: 26

  # Project-level (set at instantiation)
  - name: "{{TENANT_NAME}}"
    example: "AcmeCorp"

  - name: "{{TENANT_ID}}"
    example: "TEN-ACME123"

  - name: "{{SITE_NAME}}"
    example: "acme-landing"

  - name: "{{DOMAIN_DEV}}"
    example: "acme.sites.dev.kimmyai.io"

  - name: "{{DOMAIN_PROD}}"
    example: "acme.sites.kimmyai.io"

  - name: "{{BUSINESS_INFO}}"
    example: "Restaurant, Italian cuisine, family-owned"
```

---

## Process Instantiation

To instantiate this process for a new WordPress site with tenant:

```bash
# 1. Set variables
TENANT_NAME="AcmeCorp"
SITE_NAME="acme-landing"
WP_REPO="2_bbws_${SITE_NAME}_wordpress"

# 2. Create project folder
mkdir -p ${WP_REPO}
cd ${WP_REPO}

# 3. Copy process plan
mkdir -p .claude/plans
cp -r process/wordpress-site/*.md .claude/plans/

# 4. Initialize work state files
cd .claude/plans
for stage in stage-*.md; do
  touch "${stage%.md}.state.PENDING"
done

# 5. Start PM orchestration
# PM reads main-plan.md and begins execution
```

---

**Ready for Process Manager Generation**: This definition is complete and can be used to generate a Process Manager agent for automated WordPress & Tenant SDLC execution.
