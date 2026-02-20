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
**Project**: project-plan-campaigns-frontend
```

### 2. Task Description
Clear, concise description of what needs to be accomplished.

### 3. Inputs
List of required input files, documents, or data from:
- LLD document
- Existing source code
- Previous stage outputs
- Other workers in the same stage

### 4. Deliverables
Specific outputs expected, typically:
- `output.md` with defined sections
- React components (for component workers)
- API services (for integration workers)
- Test files (for testing workers)

### 5. Expected Output Format
Template or example showing exactly what the output should contain.

### 6. Success Criteria
Checklist of requirements that must be met for the worker to be considered complete.

### 7. Execution Steps
Step-by-step guide for completing the task:
1. Read inputs
2. Analyze existing code
3. Implement/Create deliverables
4. Validate outputs
5. Create output.md
6. Update work.state to COMPLETE

---

## Worker Categories

### Analysis Workers (Stage 1)
**Purpose**: Extract information from LLD and existing code
**Outputs**: Structured summaries, gap analysis, requirements validation
**Example**: worker-1-lld-api-analysis

### Configuration Workers (Stage 2)
**Purpose**: Setup and configure project infrastructure
**Outputs**: Vite config, TypeScript config, routing setup
**Example**: worker-1-vite-config

### Component Workers (Stage 3)
**Purpose**: Create React components
**Outputs**: React components with TypeScript, inline styles
**Example**: worker-1-layout-components

### Integration Workers (Stage 4)
**Purpose**: API integration and error handling
**Outputs**: API services, type definitions, error handlers
**Example**: worker-1-campaign-api-service

### Feature Workers (Stage 5)
**Purpose**: Implement checkout flow features
**Outputs**: Checkout page, payment pages, form handling
**Example**: worker-1-checkout-page

### Quality Workers (Stage 6)
**Purpose**: Create tests and documentation
**Outputs**: Unit tests, integration tests, README
**Example**: worker-1-unit-tests

---

## Template Variables

When creating instructions.md from this template, replace:

| Variable | Description | Example |
|----------|-------------|---------|
| `{N}` | Worker number | 1, 2, 3, etc. |
| `{task-name}` | Task identifier | lld-api-analysis, vite-config |
| `{Task Name}` | Human-readable task | LLD API Analysis, Vite Configuration |
| `{Stage Name}` | Stage full name | Requirements Validation |
| `{inputs}` | Specific input files | `/path/to/LLD.md` |
| `{deliverables}` | Specific outputs | `campaignApi.ts` |

---

## Quality Standards

All worker instructions must:
- [ ] Clearly define the task
- [ ] List all required inputs
- [ ] Specify exact deliverables
- [ ] Provide output format template
- [ ] Include measurable success criteria
- [ ] Provide step-by-step execution guide
- [ ] Reference existing code patterns where applicable

---

## Frontend-Specific Guidelines

### Component Development
- Use React 18 functional components with hooks
- Use TypeScript for type safety
- Use inline styles (no CSS frameworks)
- Follow existing code patterns in `campaigns/src/`

### API Integration
- Use environment-based configuration
- Implement retry logic with exponential backoff
- Provide mock fallback for development
- Follow existing `productApi.ts` patterns

### Testing
- Use Vitest for unit tests
- Use React Testing Library
- Aim for 80%+ code coverage
- Test user interactions and edge cases

### Documentation
- Include JSDoc comments on all exports
- Document component props with TypeScript interfaces
- Provide usage examples in code comments

---

## Examples Created

All 18 workers have instructions.md files created:

**Stage 1** (3 workers):
- worker-1-lld-api-analysis
- worker-2-existing-code-audit
- worker-3-gap-analysis

**Stage 2** (3 workers):
- worker-1-vite-config
- worker-2-typescript-config
- worker-3-routing-config

**Stage 3** (3 workers):
- worker-1-layout-components
- worker-2-pricing-components
- worker-3-campaign-components

**Stage 4** (3 workers):
- worker-1-campaign-api-service
- worker-2-type-definitions
- worker-3-error-handling

**Stage 5** (3 workers):
- worker-1-checkout-page
- worker-2-payment-pages
- worker-3-form-handling

**Stage 6** (3 workers):
- worker-1-unit-tests
- worker-2-integration-tests
- worker-3-documentation

---

**Template Version**: 1.0
**Created**: 2026-01-18
