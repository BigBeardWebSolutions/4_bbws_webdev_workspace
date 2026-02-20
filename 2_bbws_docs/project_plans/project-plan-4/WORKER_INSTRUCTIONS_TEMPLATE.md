# Worker Instructions Template

This template is used to create `instructions.md` for all workers in project-plan-4 (Marketing Lambda Implementation).

---

## Standard Structure

Each `instructions.md` file contains:

### 1. Header
```markdown
# Worker Instructions: {Task Name}

**Worker ID**: worker-{N}-{task-name}
**Stage**: Stage {N} - {Stage Name}
**Project**: project-plan-4 (Marketing Lambda Implementation)
```

### 2. Task Description
Clear, concise description of what needs to be accomplished.

### 3. Inputs
List of required input files, documents, or data from:
- Previous stage outputs
- Specification documents
- LLD document: 2.1.3_LLD_Marketing_Lambda.md
- HLD document: 2.1_BBWS_Customer_Portal_Public_HLD_V1.1.md
- Other workers in the same stage

### 4. Deliverables
Specific outputs expected, typically:
- `output.md` with defined sections
- Code files (for Lambda implementation workers)
- Terraform files (for infrastructure workers)
- YAML files (for CI/CD workers)
- Markdown files (for runbook workers)

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

### Analysis Workers (Stage 1)
**Purpose**: Extract information from LLD, validate requirements
**Outputs**: Structured summaries, validation matrices, configuration reports
**Workers**: worker-1 through worker-4

### Lambda Implementation Workers (Stage 2)
**Purpose**: Write Python Lambda code following TDD and OOP
**Outputs**: Python code, unit tests, configuration files
**Workers**: worker-1 through worker-6

### Infrastructure Workers (Stage 3)
**Purpose**: Create Terraform modules for Lambda and API Gateway
**Outputs**: Terraform files (.tf, .tfvars), validation scripts
**Workers**: worker-1 through worker-4

### CI/CD Workers (Stage 4)
**Purpose**: Create GitHub Actions workflows
**Outputs**: GitHub Actions YAML files, test scripts
**Workers**: worker-1 through worker-5

### Runbook Workers (Stage 5)
**Purpose**: Create operational documentation
**Outputs**: Runbook markdown files
**Workers**: worker-1 through worker-4

---

## Template Variables

When creating instructions.md from this template, replace:

| Variable | Description | Example |
|----------|-------------|---------|
| `{N}` | Worker number | 1, 2, 3, etc. |
| `{task-name}` | Task identifier | lld-analysis, handler-implementation |
| `{Task Name}` | Human-readable task | LLD Analysis, Handler Implementation |
| `{Stage Name}` | Stage full name | Requirements & Analysis, Lambda Implementation |
| `{inputs}` | Specific input files | `/path/to/2.1.3_LLD_Marketing_Lambda.md` |
| `{deliverables}` | Specific outputs | `lld_analysis_summary.md` |

---

## Quality Standards

All worker instructions must:
- [ ] Clearly define the task
- [ ] List all required inputs
- [ ] Specify exact deliverables
- [ ] Provide output format template
- [ ] Include measurable success criteria
- [ ] Provide step-by-step execution guide
- [ ] Reference LLD sections where applicable
- [ ] Follow TDD for code workers
- [ ] Follow OOP principles for code workers
- [ ] Ensure parameterization for infrastructure workers

---

## Generation Approach

**Recommended**: Just-In-Time (JIT) Generation

- **Stage 1**: Create all 4 worker instructions now
- **Stage 2-5**: Create worker instructions when reaching each stage

**Rationale**:
- Stage outputs may refine later stage requirements
- Reduces risk of rework
- Maintains agility
- LLD already provides detailed specifications

---

## All Workers Summary

**Total Workers**: 23

**Stage 1**: 4 workers (analysis and validation)
**Stage 2**: 6 workers (Lambda code implementation)
**Stage 3**: 4 workers (Terraform infrastructure)
**Stage 4**: 5 workers (CI/CD pipelines)
**Stage 5**: 4 workers (operational runbooks)

---

**Template Version**: 1.0
**Created**: 2025-12-30
**Project**: project-plan-4 (Marketing Lambda Implementation)
