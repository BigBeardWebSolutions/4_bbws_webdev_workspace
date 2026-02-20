# Worker Instructions Template

This template is used to create `instructions.md` for all workers in the project.

---

## Standard Structure

Each `instructions.md` file contains:

### 1. Header
```markdown
# Worker Instructions: {Task Name}

**Worker ID**: worker-{N}-{task-name}
**Stage**: Stage {N} - {Stage Name}
**Project**: project-plan-2-access-management
```

### 2. Task Description
Clear, concise description of what needs to be accomplished.

### 3. Inputs
List of required input files, documents, or data from:
- LLD documents (2.8.1 - 2.8.6)
- Previous stage outputs
- Other workers in the same stage

### 4. Deliverables
Specific outputs expected, typically:
- `output.md` with defined sections
- Code files (for Lambda/Terraform workers)
- Test files (for testing workers)
- Documentation (for runbook workers)

### 5. Expected Output Format
Template or example showing exactly what the output.md should contain.

### 6. Success Criteria
Checklist of requirements that must be met for the worker to be considered complete.

### 7. Execution Steps
Step-by-step guide for completing the task:
1. Read inputs
2. Perform analysis/creation
3. Validate outputs
4. Create output.md
5. Update work.state to COMPLETE

---

## Worker Categories

### LLD Review Workers (Stage 1)
**Purpose**: Review LLDs for implementation readiness
**Outputs**: Implementation checklist, API contracts, data models
**Example**: worker-1-permission-service-review

### Infrastructure Workers (Stage 2)
**Purpose**: Create Terraform modules
**Outputs**: .tf files, variables, outputs
**Example**: worker-1-dynamodb-tables-module

### Lambda Development Workers (Stage 3)
**Purpose**: Implement Lambda functions with TDD
**Outputs**: Python handlers, models, tests
**Example**: worker-1-permission-service-lambdas

### API Gateway Workers (Stage 4)
**Purpose**: Configure API routes and integrations
**Outputs**: OpenAPI specs, route configs
**Example**: worker-1-permission-api-routes

### Testing Workers (Stage 5)
**Purpose**: Create comprehensive test suites
**Outputs**: Test files, test data, coverage reports
**Example**: worker-1-unit-tests

### CI/CD Workers (Stage 6)
**Purpose**: Create GitHub Actions workflows
**Outputs**: YAML workflow files
**Example**: worker-1-terraform-plan-workflow

### Runbook Workers (Stage 7)
**Purpose**: Create operational documentation
**Outputs**: Runbook markdown files
**Example**: worker-1-deployment-runbook

---

## Template Variables

When creating instructions.md from this template, replace:

| Variable | Description | Example |
|----------|-------------|---------|
| `{N}` | Worker number | 1, 2, 3, etc. |
| `{task-name}` | Task identifier | permission-service-review |
| `{Task Name}` | Human-readable task | Permission Service Review |
| `{Stage Name}` | Stage full name | LLD Review & Analysis |
| `{inputs}` | Specific input files | `/path/to/LLD.md` |
| `{deliverables}` | Specific outputs | `implementation_checklist.md` |

---

## Quality Standards

All worker instructions must:
- [ ] Clearly define the task
- [ ] List all required inputs
- [ ] Specify exact deliverables
- [ ] Provide output format template
- [ ] Include measurable success criteria
- [ ] Provide step-by-step execution guide
- [ ] Reference relevant LLD sections

---

## TDD Approach (Stage 3)

For Lambda development workers:
1. **Write test first** - Define expected behavior
2. **Run test** - Confirm it fails
3. **Implement code** - Make test pass
4. **Refactor** - Clean up code
5. **Repeat** - Next function

---

## Naming Conventions

### Files
- Lambda handlers: `{service}_{action}_handler.py`
- Models: `{service}_models.py`
- Tests: `test_{service}_{action}.py`
- Terraform: `{resource}.tf`

### AWS Resources
- DynamoDB: `bbws-access-{env}-ddb-{table}`
- Lambda: `bbws-access-{env}-lambda-{service}-{action}`
- IAM Role: `bbws-access-{env}-role-{service}`

---

**Template Version**: 1.0
**Created**: 2026-01-23
