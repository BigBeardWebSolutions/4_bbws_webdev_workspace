# Sub-Plans Concept (Workflow-Agnostic Pattern)

**Version**: 1.0
**Created**: 2026-01-01
**Purpose**: Define the sub-plans pattern for hierarchical plan management across any workflow or planning methodology

---

## Overview

**Sub-Plans** are self-contained, executable planning units that operate under a parent plan's orchestration. This pattern enables hierarchical project decomposition and parallel execution while maintaining clear parent-child relationships.

**Workflow-Agnostic**: This pattern works with ANY planning methodology (TBT, Agile, Waterfall, Kanban, etc.) and can be applied at any scale (tasks, projects, programs, portfolios).

---

## Core Concept

### What is a Sub-Plan?

A **sub-plan** is:
- ✅ A complete, self-contained plan with its own structure
- ✅ Orchestrated by a parent plan (not micromanaged)
- ✅ Independently executable once authorized
- ✅ Capable of having its own sub-plans (hierarchical nesting)
- ✅ Responsible for reporting status to parent

### What a Sub-Plan is NOT

A sub-plan is not:
- ❌ A task within a plan (tasks are atomic units, sub-plans are complete plans)
- ❌ A dependency (dependencies are relationships, sub-plans are entities)
- ❌ A workflow stage (stages are sequential steps, sub-plans are parallel/independent units)

---

## Sub-Plan Architecture

### Hierarchical Structure

```
Parent Plan (Level 0)
├── Sub-Plan A (Level 1)
│   ├── Sub-Plan A1 (Level 2)
│   ├── Sub-Plan A2 (Level 2)
│   └── Sub-Plan A3 (Level 2)
├── Sub-Plan B (Level 1)
│   ├── Sub-Plan B1 (Level 2)
│   └── Sub-Plan B2 (Level 2)
└── Sub-Plan C (Level 1)
```

**Key Properties**:
- Each level can have multiple sub-plans
- Sub-plans at the same level can execute in parallel (if no dependencies)
- Sub-plans can nest indefinitely (practical limit: 3-4 levels)
- Parent plans orchestrate, sub-plans execute

---

## Sub-Plan Attributes

Every sub-plan must define:

### 1. **Identity**
- **Name**: Descriptive name for the sub-plan
- **Location**: File path or reference to sub-plan document
- **Version**: Sub-plan version (if applicable)

### 2. **Status**
- **State**: Current execution state
  - `PENDING`: Not yet started
  - `IN_PROGRESS`: Currently executing
  - `PAUSED`: Temporarily halted
  - `BLOCKED`: Waiting on dependency/approval
  - `COMPLETED`: Finished successfully
  - `FAILED`: Encountered error
  - `CANCELLED`: Terminated before completion

### 3. **Dependencies**
- **Prerequisites**: Which sub-plans/resources must exist before this can start
- **Blocking**: Which sub-plans are waiting on this one
- **Parent**: Reference to parent plan (if not root)

### 4. **Outputs**
- **Deliverables**: What artifacts the sub-plan produces
- **Success Criteria**: How to determine successful completion
- **Status Reporting**: How status propagates to parent

### 5. **Execution Context**
- **Executor**: Who/what executes the sub-plan (human, agent, automated system)
- **Duration**: Estimated time to complete
- **Resources**: Required resources (files, tools, permissions)

---

## Parent-Sub-Plan Relationship

### Parent Responsibilities

The **parent plan** is responsible for:
- ✅ **Orchestration**: Deciding execution order and dependencies
- ✅ **Authorization**: Approving sub-plan start (approval gates)
- ✅ **Monitoring**: Tracking sub-plan status
- ✅ **Synthesis**: Consolidating sub-plan outputs
- ✅ **Error Handling**: Responding to sub-plan failures
- ✅ **Resource Allocation**: Providing resources to sub-plans

### Sub-Plan Responsibilities

The **sub-plan** is responsible for:
- ✅ **Execution**: Completing its own work
- ✅ **Status Reporting**: Updating status to parent
- ✅ **Output Generation**: Producing defined deliverables
- ✅ **Error Reporting**: Notifying parent of failures
- ✅ **Sub-Orchestration**: Managing its own sub-plans (if any)

### Communication Pattern

```
Parent Plan
    ↓ (authorize execution)
Sub-Plan
    ↑ (report status)
Parent Plan
    ↓ (request output)
Sub-Plan
    ↑ (provide deliverable)
Parent Plan
```

---

## Sub-Plan Execution Modes

### Serial Execution
Sub-plans execute one after another (sequential):
```
Sub-Plan A → Sub-Plan B → Sub-Plan C
```
**Use When**: Sub-plans depend on previous outputs

### Parallel Execution
Sub-plans execute simultaneously:
```
Sub-Plan A ┐
Sub-Plan B ├→ All complete
Sub-Plan C ┘
```
**Use When**: Sub-plans are independent, resources allow

### Hybrid Execution
Combination of serial and parallel:
```
Stage 1: Sub-Plan A → Sub-Plan B (serial)
Stage 2: Sub-Plan C ┐
         Sub-Plan D ├→ (parallel)
         Sub-Plan E ┘
Stage 3: Sub-Plan F (serial)
```
**Use When**: Complex dependencies with parallelization opportunities

---

## Sub-Plan File Organization

### Location Patterns

**Pattern 1: Hierarchical Folders**
```
project/
├── plan.md (parent plan)
└── sub-plans/
    ├── sub-plan-A/
    │   ├── plan.md
    │   └── sub-plans/
    │       ├── sub-plan-A1/plan.md
    │       └── sub-plan-A2/plan.md
    ├── sub-plan-B/plan.md
    └── sub-plan-C/plan.md
```

**Pattern 2: Flat with References**
```
project/
├── plans/
│   ├── parent_plan.md
│   ├── sub_plan_A.md
│   ├── sub_plan_B.md
│   └── sub_plan_C.md
```

**Pattern 3: Year/Domain Segregation** (Visual Arts Example)
```
subject/
├── .claude/plans/subject_plan.md (parent)
├── 2020/analysis/.claude/plans/year_plan_2020.md (sub-plan)
├── 2021/analysis/.claude/plans/year_plan_2021.md (sub-plan)
├── 2022/analysis/.claude/plans/year_plan_2022.md (sub-plan)
├── 2023/analysis/.claude/plans/year_plan_2023.md (sub-plan)
└── 2024/analysis/.claude/plans/year_plan_2024.md (sub-plan)
```

---

## Sub-Plan Status Tracking

### Status Propagation

**Bottom-Up Status Flow**:
```
Sub-Plan (Level 2) → Sub-Plan (Level 1) → Parent Plan (Level 0) → User
```

**Status Aggregation Rules**:
- If ANY sub-plan is FAILED → Parent shows BLOCKED or FAILED
- If ALL sub-plans are COMPLETED → Parent can proceed
- If ANY sub-plan is IN_PROGRESS → Parent shows IN_PROGRESS
- If ALL sub-plans are PENDING → Parent shows PENDING

### Status Files

Use `.state` or `work.state.*` files for status tracking:
```
sub-plan/
├── plan.md
├── work.state.PENDING (initial state)
├── work.state.IN_PROGRESS (during execution)
└── work.state.COMPLETED (after completion)
```

---

## Plan of Plans Tracking Tables

### Overview

When managing hierarchical planning structures with multiple sub-plans, **tracking tables** provide at-a-glance visibility into project status, progress, and deliverables across all levels of the hierarchy.

**Purpose**: Enable visual tracking of complex multi-level planning structures without requiring detailed state management at every level.

### Tracking Table Pattern

**Applicable Levels**:
- **Curriculum/Portfolio Level**: Stateless navigation hub with tracking
- **Subject/Program Level**: Multi-year or multi-phase orchestration
- **Year/Phase Level**: Detailed execution tracking

### Core Tracking Table Elements

Every tracking table should include:

1. **Identification**: Sequential number, name/title
2. **Scope**: Time range, components covered
3. **Status**: Visual indicator (✅ COMPLETE, 🔄 IN PROGRESS, ⏳ PENDING/TBC)
4. **Progress**: Visual progress bar with percentage
5. **Structure**: Links to sub-plans or plan existence status
6. **Deliverables**: Expected vs. completed deliverables count

### Example: Curriculum-Level Tracking Table

**Context**: Multi-subject curriculum with 14 subjects, each having 5 years of analysis

```markdown
## Curriculum Tracking Table

**⚠️ UPDATE THIS TABLE AS SUBJECTS PROGRESS**

| # | Subject | Years | Papers | Status | Progress | Subject Plan | Year Plans | Deliverables |
|---|---------|-------|--------|--------|----------|--------------|------------|--------------|
| 1 | Visual Arts | 2020-2024 | P1, P2 | 🔄 IN PROGRESS | `[██░░░░░░░░] 20%` | ✅ EXISTS | 5/5 (2023 active) | 0/55 TBC4 files |
| 2 | History | 2023-2024 | P1, P2 | 🔄 IN PROGRESS | `[██░░░░░░░░] 15%` | ⏳ TBC | 2/5 (2023, 2024 active) | 0/TBD TBC4 files |
| 3 | Mathematics | TBD | TBD | ⏳ TBC | `[░░░░░░░░░░] 0%` | ⏳ TBC | 0/0 | 0/0 |
| 4 | Physical Sciences | TBD | TBD | ⏳ TBC | `[░░░░░░░░░░] 0%` | ⏳ TBC | 0/0 | 0/0 |

**Status Legend**:
- ✅ COMPLETE - Subject fully analyzed (all years, all papers)
- 🟡 PARTIAL - Some years complete, others pending
- 🔄 IN PROGRESS - Currently executing
- ⏳ TBC - To Be Created (placeholder only)

**Metrics**:
- **Total Subjects**: 14
- **Active**: 2 (14%) - Visual Arts, History
- **TBC**: 12 (86%)
- **Total Deliverables Expected**: ~1,400 TBC4 files
- **Deliverables Complete**: 0 (0%)
```

### Example: Subject-Level Tracking Table

**Context**: Single subject with 5 years of analysis (2020-2024)

```markdown
## Subject Tracking Table: Visual Arts

**⚠️ UPDATE THIS TABLE AS YEARS PROGRESS**

| # | Year | Papers | Questions/Tasks | Status | Progress | Year Plan | Deliverables | Duration |
|---|------|--------|-----------------|--------|----------|-----------|--------------|----------|
| 1 | 2023 | P1 (5Q), P2 (6T) | 11 total | 🔄 IN PROGRESS | `[████░░░░░░] 40%` | ✅ EXISTS | 4/11 TBC4 files | ~30h |
| 2 | 2020 | P1 (5Q), P2 (6T) | 11 total | ⏳ PENDING | `[░░░░░░░░░░] 0%` | ✅ EXISTS | 0/11 TBC4 files | ~30h |
| 3 | 2021 | P1 (5Q), P2 (6T) | 11 total | ⏳ PENDING | `[░░░░░░░░░░] 0%` | ✅ EXISTS | 0/11 TBC4 files | ~30h |
| 4 | 2022 | P1 (5Q), P2 (6T) | 11 total | ⏳ PENDING | `[░░░░░░░░░░] 0%` | ✅ EXISTS | 0/11 TBC4 files | ~30h |
| 5 | 2024 | P1 (5Q), P2 (6T) | 11 total | ⏳ PENDING | `[░░░░░░░░░░] 0%` | ✅ EXISTS | 0/11 TBC4 files | ~30h |

**Status Legend**:
- ✅ COMPLETE - Year fully analyzed (all papers, all questions)
- 🟡 PARTIAL - Some papers complete, others pending
- 🔄 IN PROGRESS - Currently executing
- ⏳ PENDING - Year plan created, execution not started

**Metrics**:
- **Total Years**: 5
- **Years Complete**: 0 (0%)
- **Years In Progress**: 1 (20%)
- **Years Pending**: 4 (80%)
- **Total Deliverables Expected**: 55 TBC4 files
- **Deliverables Complete**: 4 (7%)
- **Estimated Total Duration**: ~150 hours
- **Time Spent**: ~12 hours
```

### Example: Year-Level Tracking Table

**Context**: Single year with 12-stage analysis process and 11 questions/tasks

```markdown
## Year Tracking Table: 2023

**⚠️ UPDATE THIS TABLE AS STAGES PROGRESS**

| # | Stage | Description | Status | Progress | Outputs | Duration |
|---|-------|-------------|--------|----------|---------|----------|
| 1-2 | Research & Download | Get PDFs via parallel_gdown | ✅ COMPLETE | `[██████████] 100%` | 4 PDF files | 1h |
| 3-4 | Page Extraction | PDF → JPEGs in `_pages/` folders | ✅ COMPLETE | `[██████████] 100%` | ~40 JPEG pages | 1h |
| 5 | Splitting | Split combined PDFs | ⏸️ SKIPPED | `[░░░░░░░░░░] N/A` | N/A | 0h |
| 6 | Folder Template | Create Q/Task folders | ✅ COMPLETE | `[██████████] 100%` | 11 folders | 0.5h |
| 7-11 | Question Analysis | 12-point breakdown per Q/Task | 🔄 IN PROGRESS | `[████░░░░░░] 36%` | 4/11 TBC4 files | 20h |

**Stage 7-11 Detail** (Question/Task Analysis):

| # | Paper | Q/Task | Topic | Status | TBC Level | Marks | Duration |
|---|-------|--------|-------|--------|-----------|-------|----------|
| 1 | P1 | Q1 | Pre-Colonial Art | ✅ COMPLETE | TBC4 | 20 | 2h |
| 2 | P1 | Q2 | 19th Century | ✅ COMPLETE | TBC4 | 20 | 2h |
| 3 | P1 | Q3 | Modernism | 🔄 IN PROGRESS | TBC2 | 20 | 2h |
| 4 | P1 | Q4 | Contemporary | ⏳ PENDING | TBC | 20 | 2h |
| 5 | P1 | Q5 | South African Art | ⏳ PENDING | TBC | 20 | 2h |
| 6 | P2 | Task 1 | Visual Analysis | ✅ COMPLETE | TBC4 | 15 | 1.5h |
| 7 | P2 | Task 2 | Comparative | ⏳ PENDING | TBC | 15 | 1.5h |
| 8 | P2 | Task 3 | Contextual | ✅ COMPLETE | TBC4 | 15 | 1.5h |
| 9 | P2 | Task 4 | Critical | ⏳ PENDING | TBC | 15 | 1.5h |
| 10 | P2 | Task 5 | Research | ⏳ PENDING | TBC | 20 | 2h |
| 11 | P2 | Task 6 | Essay | ⏳ PENDING | TBC | 20 | 2h |

**Metrics**:
- **Total Questions/Tasks**: 11
- **Complete**: 4 (36%)
- **In Progress**: 1 (9%)
- **Pending**: 6 (55%)
- **Estimated Time Remaining**: ~18 hours
```

### Progress Bar Convention

Use block characters for visual progress representation:

```
0%:   [░░░░░░░░░░]
10%:  [█░░░░░░░░░]
20%:  [██░░░░░░░░]
30%:  [███░░░░░░░]
40%:  [████░░░░░░]
50%:  [█████░░░░░]
60%:  [██████░░░░]
70%:  [███████░░░]
80%:  [████████░░]
90%:  [█████████░]
100%: [██████████]
```

**Characters**:
- `█` (U+2588) - Full block (completed)
- `░` (U+2591) - Light shade (pending)

### Status Icon Convention

Consistent status icons across all tracking levels:

- ✅ **COMPLETE** - All work finished successfully
- 🟡 **PARTIAL** - Some sub-components complete, others pending
- 🔄 **IN PROGRESS** - Currently executing
- ⏳ **PENDING** - Planned but not started
- ⏳ **TBC** - To Be Created (placeholder, not yet planned)
- ⏸️ **PAUSED** - Temporarily halted
- 🚫 **BLOCKED** - Waiting on dependency
- ⏭️ **SKIPPED** - Intentionally skipped (not applicable)
- ❌ **FAILED** - Encountered error

### Stateless vs. Stateful Tracking

**Stateless Tracking** (Curriculum/Portfolio Level):
- Table shows current status snapshot
- NO work.state files or state management
- Manual updates as sub-plans report progress
- Navigation hub only

**Stateful Tracking** (Subject/Year Level):
- Table shows current status snapshot
- PLUS work.state.* files for execution state
- Automatic or manual updates
- Execution management

### Update Protocol

**When to Update**:
- ✅ After completing a sub-plan
- ✅ After starting a new sub-plan
- ✅ When deliverables are completed
- ✅ When status changes significantly
- ⚠️ At project milestones
- ⚠️ During status reviews

**How to Update**:
1. Identify the row(s) affected
2. Update status icon
3. Recalculate progress percentage
4. Update progress bar
5. Update deliverables count
6. Update metrics section
7. Add timestamp/note (optional)

### Tracking Table Best Practices

✅ **DO**:
- Keep tables up-to-date as work progresses
- Use consistent status icons across all levels
- Include metrics section for aggregates
- Add status legends for clarity
- Update progress bars based on deliverables
- Document when table was last updated

❌ **DON'T**:
- Let tracking tables become stale (>1 week old)
- Use inconsistent status conventions
- Forget to update metrics when rows change
- Over-engineer with too many columns
- Make tables so complex they're hard to maintain
- Duplicate tracking (tables should complement state files, not replace them)

### Integration with Sub-Plans

**Relationship**:
- Tracking tables provide **visibility**
- Sub-plans provide **execution detail**
- work.state files provide **state persistence**

**Workflow**:
```
1. Parent plan has tracking table
2. Sub-plan executes independently
3. Sub-plan updates its work.state file
4. Parent observes state change
5. Parent updates tracking table row
6. User views tracking table for status
```

**No Automatic Sync**: Tracking tables are manually updated based on sub-plan state, NOT automatically synchronized (unless tooling exists).

---

## Sub-Plan Templates

### Minimal Sub-Plan Template

```markdown
# Sub-Plan: [Name]

**Parent Plan**: [Reference to parent]
**Status**: [PENDING/IN_PROGRESS/PAUSED/COMPLETED/etc.]
**Dependencies**: [List of prerequisites]

## Objective
[What this sub-plan accomplishes]

## Outputs
[What deliverables this produces]

## Execution Steps
[How to execute this sub-plan]

## Success Criteria
[How to determine completion]

## Status Reporting
[How status is communicated to parent]
```

### Full Sub-Plan Template

```markdown
# Sub-Plan: [Name]

**Version**: [Version number]
**Created**: [Date]
**Parent Plan**: [Reference to parent plan]
**Status**: [Current state]
**Executor**: [Who/what executes this]
**Duration**: [Estimated time]

---

## Sub-Plan Identity

**Name**: [Descriptive name]
**Type**: [Type of sub-plan]
**Location**: [File path]

## Dependencies

**Prerequisites**:
- [List of things that must exist before this starts]

**Blocking**:
- [List of things waiting on this]

## Objective

[Clear statement of what this sub-plan accomplishes]

## Scope

**In Scope**:
- [What this sub-plan covers]

**Out of Scope**:
- [What this sub-plan doesn't cover]

## Outputs

**Deliverables**:
- [List of artifacts produced]

**Success Criteria**:
- [List of completion conditions]

## Execution

### Steps
[Detailed execution steps or reference to process]

### Resources Required
- [List of required resources]

### Duration
[Estimated time with breakdown]

## Sub-Plans (if any)

[List of sub-plans this plan orchestrates]

## Status Reporting

**Status Updates**:
[How and when status is reported to parent]

**Completion Signal**:
[How parent knows this is complete]

## Error Handling

**Failure Scenarios**:
- [List potential failures]

**Escalation**:
[How errors are escalated to parent]

---

**Next Steps**: [What happens after this completes]
```

---

## Sub-Plan Use Cases

### Use Case 1: Multi-Year Analysis (Visual Arts Example)

**Parent Plan**: Subject-level plan for 2020-2024 Visual Arts analysis
**Sub-Plans**: One per year (5 sub-plans)

**Benefits**:
- Each year is complete, self-contained analysis
- Years can execute independently
- Parent orchestrates execution order
- Cross-year synthesis after all complete

### Use Case 2: Feature Development

**Parent Plan**: Major feature implementation
**Sub-Plans**:
- Design sub-plan
- Backend sub-plan
- Frontend sub-plan
- Testing sub-plan

**Benefits**:
- Backend and frontend can execute in parallel
- Each has own complete planning
- Parent tracks overall feature completion

### Use Case 3: Research Program

**Parent Plan**: Multi-year research program
**Sub-Plans**:
- Year 1 research sub-plan
- Year 2 research sub-plan
- Year 3 research sub-plan
- Publication sub-plan

**Benefits**:
- Each year has own complete research plan
- Parent manages grants and resources
- Publication happens after all years complete

---

## Sub-Plan Best Practices

### DO

✅ **Make sub-plans self-contained**: Each should be independently executable
✅ **Define clear outputs**: Parent must know what to expect
✅ **Use consistent status reporting**: Standardize how status propagates
✅ **Document dependencies explicitly**: Avoid hidden assumptions
✅ **Keep nesting shallow**: 2-3 levels max for manageability
✅ **Provide clear completion criteria**: Parent knows when to proceed

### DON'T

❌ **Micromanage from parent**: Let sub-plans execute autonomously
❌ **Create circular dependencies**: Sub-plan A → B → A (infinite loop)
❌ **Over-nest**: 5+ levels becomes unmanageable
❌ **Tightly couple sub-plans**: Each should be loosely coupled
❌ **Duplicate planning**: Sub-plan should reference, not duplicate, parent context

---

## Integration with Workflows

### TBT Workflow Integration

Sub-plans in TBT (Turn-by-Turn) workflow:
- Parent plan in `.claude/plans/parent_plan.md`
- Sub-plans in `.claude/plans/sub-plan-X/`
- Status tracked via work.state.* files
- Snapshots before each sub-plan starts
- Logs track sub-plan execution

### Agile/Scrum Integration

Sub-plans in Agile:
- Parent plan = Epic
- Sub-plans = Stories
- Each sub-plan has own sprint execution
- Parent tracks epic completion

### Waterfall Integration

Sub-plans in Waterfall:
- Parent plan = Project
- Sub-plans = Phases
- Serial execution with gates
- Each phase is complete plan

---

## Workflow-Agnostic Principles

These principles apply regardless of methodology:

1. **Hierarchy**: Plans can contain plans (nesting)
2. **Autonomy**: Sub-plans execute independently
3. **Orchestration**: Parents coordinate, don't micromanage
4. **Status Propagation**: Bottom-up status flow
5. **Clear Outputs**: Defined deliverables
6. **Loose Coupling**: Minimal dependencies between sub-plans
7. **Self-Containment**: Each sub-plan is complete
8. **Flexible Execution**: Serial, parallel, or hybrid

---

## Summary

**Sub-Plans** provide a universal pattern for hierarchical planning across any workflow:

- **What**: Self-contained executable planning units
- **Why**: Enable hierarchical decomposition and parallel execution
- **How**: Parent orchestrates, sub-plans execute, status propagates up
- **Where**: Any workflow methodology (TBT, Agile, Waterfall, etc.)
- **When**: Complex projects requiring decomposition or parallelization

**Key Benefits**:
- Scales from tasks to enterprise programs
- Works with any planning methodology
- Enables parallel execution
- Maintains clear hierarchy
- Supports autonomous execution
- Facilitates result consolidation

---

## References

**Real-World Example**: Visual Arts Multi-Year Analysis
- **Parent Plan**: `art_theory/.claude/plans/subject_plan.md`
- **Sub-Plans**: `YEAR/analysis/.claude/plans/year_plan_YEAR.md` (5 sub-plans)
- **Pattern**: Year-segregated sub-plans with serial execution

**See Also**:
- Agentic Project Manager skill documentation
- TBT workflow documentation
- Project planning templates
