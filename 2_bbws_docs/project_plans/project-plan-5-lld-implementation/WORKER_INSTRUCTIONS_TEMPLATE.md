# Worker Instructions Template

This template is used to create `instructions.md` for all workers in project-plan-5-lld-implementation.

---

## Standard Structure

Each `instructions.md` file contains:

### 1. Header
```markdown
# Worker Instructions: {Task Name}

**Worker ID**: worker-{N}-{task-name}
**Stage**: Stage {N} - {Stage Name}
**Project**: project-plan-5-lld-implementation
```

### 2. Task Description
Clear, concise description of what needs to be accomplished.

### 3. Inputs
List of required input files, documents, or data from:
- LLD documents (2.5, 2.6, 2.7)
- Previous stage outputs
- Specification documents
- Other workers in the same stage

### 4. Deliverables
Specific outputs expected, typically:
- `output.md` with defined sections
- Code files (Lambda handlers, services, DAOs)
- Test files (pytest test cases)
- Terraform files (for infrastructure workers)
- OpenAPI specs (for API workers)

### 5. Expected Output Format
Template or example showing exactly what the output.md should contain.

### 6. Success Criteria
Checklist of requirements that must be met for the worker to be considered complete.

### 7. Execution Steps
Step-by-step guide for completing the task:
1. Read inputs
2. Perform analysis/creation
3. Validate outputs
4. Run tests (if applicable)
5. Create output.md
6. Update work.state to COMPLETE

---

## Worker Categories

### Analysis Workers (Stage 1)
**Purpose**: Extract API endpoints, data models, integration points from LLDs
**Outputs**: API mapping tables, integration matrices, repository structures
**Example**: worker-1-lld-2.5-analysis

### Lambda Handler Workers (Stage 2 & 3)
**Purpose**: Implement Lambda function handlers
**Outputs**: Python handler files, service classes, DAO classes, unit tests
**Example**: worker-5-site-handlers

### CI/CD Workers (Stage 4)
**Purpose**: Create GitHub Actions workflows
**Outputs**: YAML workflow files, shell scripts, configuration files
**Example**: worker-1-tenant-lambda-cicd

### Testing Workers (Stage 5)
**Purpose**: Create integration tests
**Outputs**: pytest integration test files, test fixtures, mock data
**Example**: worker-1-tenant-integration-tests

### Documentation Workers (Stage 6)
**Purpose**: Create runbooks and API documentation
**Outputs**: Markdown runbooks, OpenAPI YAML, architecture diagrams
**Example**: worker-1-tenant-deployment-runbook

---

## Template Variables

When creating instructions.md from this template, replace:

| Variable | Description | Example |
|----------|-------------|---------|
| `{N}` | Worker number | 1, 2, 3, etc. |
| `{task-name}` | Task identifier | tenant-handlers, site-cicd |
| `{Task Name}` | Human-readable task | Tenant Handlers, Site CI/CD |
| `{Stage Name}` | Stage full name | Analysis & API Mapping |
| `{inputs}` | Specific input files | `/path/to/LLD.md` |
| `{deliverables}` | Specific outputs | `handlers/tenant_handler.py` |
| `{lld}` | Source LLD | LLD 2.5, LLD 2.6, LLD 2.7 |

---

## Quality Standards

All worker instructions must:
- [ ] Clearly define the task
- [ ] Reference the source LLD section(s)
- [ ] List all required inputs
- [ ] Specify exact deliverables with file paths
- [ ] Provide TDD approach (tests first)
- [ ] Include measurable success criteria
- [ ] Provide step-by-step execution guide

---

## Lambda Implementation Standards

### Code Structure
```
src/
├── handlers/
│   └── {domain}/
│       └── {handler}_handler.py
├── services/
│   └── {domain}_service.py
├── dao/
│   └── {domain}_dao.py
├── models/
│   ├── {domain}.py
│   ├── requests.py
│   └── responses.py
└── utils/
    ├── exceptions.py
    └── response_builder.py

tests/
├── unit/
│   ├── handlers/
│   ├── services/
│   └── dao/
└── integration/
```

### TDD Workflow
1. Write failing test first
2. Implement minimum code to pass
3. Refactor if needed
4. Repeat

### Required Test Coverage
- Unit tests: 80% minimum
- Mocking: Use moto for AWS services
- Fixtures: Shared test data in conftest.py

---

## LLD Reference Quick Links

| LLD | Key Sections |
|-----|--------------|
| **2.5 Tenant Management** | Section 4 (APIs), Section 5 (Data Model), Section 6 (Lambdas) |
| **2.6 WordPress Site Management** | Section 4 (Sites API), Section 5 (Templates API), Section 6 (Plugins API) |
| **2.7 WordPress Instance Management** | Section 4 (APIs), Section 5 (Infrastructure), Section 6 (EventBridge) |

---

## Generation Approach

**Recommended**: Just-In-Time Generation
- Create instructions.md for each stage when that stage begins
- Stage outputs may refine later stage requirements
- Reduces risk of rework
- Maintains agility

---

**Template Version**: 1.0
**Created**: 2026-01-24
