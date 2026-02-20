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
**Project**: project-plan-1
```

### 2. Task Description
Clear, concise description of what needs to be accomplished.

### 3. Inputs
List of required input files, documents, or data from:
- Previous stage outputs
- Specification documents
- HLD/LLD documents
- Other workers in the same stage

### 4. Deliverables
Specific outputs expected, typically:
- `output.md` with defined sections
- Code files (for infrastructure workers)
- Diagrams (for diagram workers)
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

### Analysis Workers (Stage 1)
**Purpose**: Extract information from documents
**Outputs**: Structured summaries, checklists, matrices
**Example**: worker-1-hld-analysis

### Documentation Workers (Stage 2)
**Purpose**: Write LLD sections
**Outputs**: LLD document sections, diagrams
**Example**: worker-4-architecture-diagrams

### Code Workers (Stage 3)
**Purpose**: Create infrastructure code
**Outputs**: Terraform modules, JSON schemas, HTML templates
**Example**: worker-2-terraform-dynamodb-module

### Pipeline Workers (Stage 4)
**Purpose**: Create CI/CD workflows
**Outputs**: GitHub Actions YAML files, test scripts
**Example**: worker-3-deployment-workflows

### Runbook Workers (Stage 5)
**Purpose**: Create operational documentation
**Outputs**: Runbook markdown files
**Example**: worker-1-deployment-runbook

---

## Template Variables

When creating instructions.md from this template, replace:

| Variable | Description | Example |
|----------|-------------|---------|
| `{N}` | Worker number | 1, 2, 3, etc. |
| `{task-name}` | Task identifier | hld-analysis, terraform-design |
| `{Task Name}` | Human-readable task | HLD Analysis, Terraform Design |
| `{Stage Name}` | Stage full name | Requirements & Analysis |
| `{inputs}` | Specific input files | `/path/to/HLD.md` |
| `{deliverables}` | Specific outputs | `entity_summary.md` |

---

## Quality Standards

All worker instructions must:
- [ ] Clearly define the task
- [ ] List all required inputs
- [ ] Specify exact deliverables
- [ ] Provide output format template
- [ ] Include measurable success criteria
- [ ] Provide step-by-step execution guide

---

## Examples Created

✅ **worker-1-hld-analysis/instructions.md**
- Comprehensive HLD analysis task
- 5 deliverable sections
- Detailed extraction requirements

✅ **worker-4-architecture-diagrams/instructions.md**
- 4 Mermaid diagrams to create
- Specific diagram requirements
- Output format examples

---

## Remaining Workers

The following workers need instructions.md created (23 total):

**Stage 1** (3 remaining):
- worker-2-requirements-validation
- worker-3-naming-convention-analysis
- worker-4-environment-configuration-analysis

**Stage 2** (4 remaining):
- worker-1-lld-structure-introduction
- worker-2-dynamodb-design-section
- worker-3-s3-design-section
- worker-5-terraform-design-section
- worker-6-cicd-pipeline-design-section

**Stage 3** (6 remaining):
- worker-1-dynamodb-json-schemas
- worker-2-terraform-dynamodb-module
- worker-3-terraform-s3-module
- worker-4-html-email-templates
- worker-5-environment-configurations
- worker-6-validation-scripts

**Stage 4** (5 remaining):
- worker-1-validation-workflows
- worker-2-terraform-plan-workflow
- worker-3-deployment-workflows
- worker-4-rollback-workflow
- worker-5-test-scripts

**Stage 5** (4 remaining):
- worker-1-deployment-runbook
- worker-2-promotion-runbook
- worker-3-troubleshooting-runbook
- worker-4-rollback-runbook

---

## Generation Approach

**Option 1: Generate All Upfront**
- Create all 23 instructions.md files before starting Stage 1
- Ensures complete planning before execution
- More upfront work

**Option 2: Just-In-Time Generation**
- Create instructions.md for each stage when that stage begins
- Stage 1 workers: Create now (4 files)
- Stage 2+ workers: Create when reaching that stage
- More agile, less upfront work

**Recommended**: Option 2 (Just-In-Time) for this project, as:
- Stage outputs may refine later stage requirements
- Reduces risk of rework
- Maintains agility

---

**Template Version**: 1.0
**Created**: 2025-12-25
