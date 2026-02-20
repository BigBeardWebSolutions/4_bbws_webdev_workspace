# Project Planning Skill - Multi-Stage Project Planning Methodology

## Skill Purpose

This skill provides comprehensive guidance for planning and structuring multi-stage agentic projects. It defines the methodology, templates, and best practices for decomposing complex projects into hierarchical stages with parallel worker execution.

## When to Use This Skill

Load this skill when:
- Creating a new multi-stage project from scratch
- Need to structure complex work into manageable pieces
- Planning projects with parallel execution requirements
- Defining project with multiple dependent stages
- Creating reusable project templates

## Project Planning Methodology

### Step 1: Requirements Analysis

**Questions to Ask**:
1. What is the ultimate project goal?
2. What are the key deliverables?
3. Who are the stakeholders?
4. What constraints exist (time, resources, dependencies)?
5. What is the scope (in scope / out of scope)?

**Output**: Requirements document defining project objectives, deliverables, constraints

### Step 2: Stage Decomposition

**Decomposition Criteria**:
- **Logical Phases**: Group work by natural project phases
- **Dependencies**: Identify sequential vs. parallel work
- **Deliverables**: Each stage should produce tangible outputs
- **Size**: Aim for 3-5 stages per project

**Common Stage Patterns**:

| Project Type | Stage Pattern |
|--------------|---------------|
| Research | Data Collection → Analysis → Reporting |
| Content Creation | Planning → Production → Review/Publishing |
| Software Development | Design → Implementation → Testing/Deployment |
| Analysis | Data Gathering → Processing → Insights/Recommendations |
| **Full-Stack AWS** | **Requirements → Local Dev → Frontend → Backend → Local Testing → Infrastructure → Cloud Testing → Docs** |

### Local-First Development Pattern (AWS Projects)

For serverless AWS projects, use a **local-first development approach** where all functionality is tested locally before any cloud deployment:

```
┌─────────────────────────────────────────────────────────────────┐
│                  LOCAL-FIRST STAGE PATTERN                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  PHASE 1: LOCAL DEVELOPMENT (No AWS Required)                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Stage 1: Requirements Validation                        │   │
│  │  Stage 2: Local Dev Environment Setup                    │   │
│  │           (LocalStack, SAM Local, MSW, Agent Mocks)      │   │
│  │  Stage 3: Frontend Development (with mocked APIs)        │   │
│  │  Stage 4: Backend Development (with LocalStack)          │   │
│  │  Stage 5: Local Integration Testing                      │   │
│  └─────────────────────────────────────────────────────────┘   │
│                           ↓                                     │
│  PHASE 2: AWS DEPLOYMENT                                        │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Stage 6: Infrastructure Terraform (DEV environment)     │   │
│  │  Stage 7: AgentCore/AI Services                          │   │
│  │  Stage 8: CI/CD Pipeline Setup                           │   │
│  │  Stage 9: AWS Integration Testing                        │   │
│  │  Stage 10: Documentation & Runbooks                      │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**Local Development Stack**:

| Component | Local Tool | AWS Equivalent |
|-----------|-----------|----------------|
| DynamoDB | LocalStack | DynamoDB |
| S3 | LocalStack | S3 |
| Lambda | SAM Local | Lambda |
| API Gateway | SAM Local | API Gateway |
| Cognito | Mock JWT | Cognito |
| AgentCore/AI | Express Mock Server | Bedrock AgentCore |
| Frontend API | MSW (Mock Service Worker) | API Gateway |

**Benefits**:
- No AWS credentials required during development
- Fast iteration with hot reload
- CI/CD can run full test suite locally
- Reduced cloud costs during development
- All user journeys testable before cloud deployment

**Critical Gate**: After Stage 5 (Local Integration Testing), all user journeys must pass locally before proceeding to AWS infrastructure deployment.

**Output**: List of stages with objectives and dependencies

### Step 3: Worker Identification

**For Each Stage**, identify parallel work units:

**Worker Criteria**:
- **Independence**: Can execute autonomously with clear instructions
- **Bounded**: Well-defined scope and outputs
- **Parallel**: Can run simultaneously with other workers
- **Size**: Appropriate for single focused task

**Typical Worker Count**: 2-5 workers per stage

**Output**: List of workers per stage with responsibilities

### Step 4: Dependency Mapping

**Types of Dependencies**:

1. **Stage Dependencies** (Sequential)
   - Stage 2 cannot start until Stage 1 COMPLETE
   - Example: Analysis requires Data Collection complete

2. **Worker Dependencies** (Within Stage)
   - Usually independent (parallel execution)
   - Occasionally one worker needs another's output
   - Document any worker-to-worker dependencies

3. **Cross-Stage Dependencies**
   - Next stage uses previous stage summary
   - Summator consolidates before next stage starts

**Output**: Dependency diagram showing stage and worker relationships

### Step 5: Folder Structure Design

**Template**:
```
project-plan-{number}/
├── project_plan.md              # Master plan
├── work.state.{STATE}           # Project state
├── summary.md                   # Final summary (at end)
│
├── stage-{number}-{name}/
│   ├── plan.md                  # Stage plan
│   ├── work.state.{STATE}       # Stage state
│   ├── summary.md               # Stage summary (at end)
│   │
│   ├── worker-{number}-{name}/
│   │   ├── instructions.md      # Worker task
│   │   ├── work.state.{STATE}   # Worker state
│   │   └── output.md            # Worker results
│   │
│   └── worker-{number}-{name}/
│       └── ...
│
└── stage-{number}-{name}/
    └── ...
```

**Naming Conventions**:
- **Projects**: `project-plan-1`, `project-plan-2`, etc.
- **Stages**: `stage-1-data-collection`, `stage-2-analysis`, etc.
- **Workers**: `worker-1-web-research`, `worker-2-interviews`, etc.

**Output**: Complete folder structure specification

### Step 6: Plan Documentation

**project_plan.md Template** - Use comprehensive template at `agents/Agentic_Architect/templates/project_plan_template.md`

**Enhanced Project Plan Structure** (based on proven patterns):

**Required Sections**:
1. **Project Overview** - Goal, objectives, success criteria
2. **Project Tracking** - Progress dashboard with phase tracking table
3. **High-Level Process Flow** - Visual diagram with all phases
4. **Execution Model** - Primary vs. spawn execution strategy
5. **Project Tracking Table** - Phase-based stage tracking with detailed metadata
6. **Stage-by-Stage Execution Plan** - Detailed stage breakdowns with sub-phases
7. **Validation Gates** - Quality checkpoints (if applicable)
8. **Spawn Testing Protocol** - Test-before-spawn strategy (if using spawns)
9. **Technical Details** - Technology stack, dependencies, constraints
10. **Success Metrics** - Measurable completion criteria
11. **Expected Deliverables** - Folder structure and file outputs

**Key Enhancements from project-plan-4 Pattern**:

**Phase-Based Organization**:
```markdown
## 2.3 Project Tracking Table

| Phase | Step # | Stage | Execution | Parallel/Serial | Status | Progress | Testing Required | Dependencies |
|-------|--------|-------|-----------|-----------------|--------|----------|------------------|--------------|
| **1 - PREPARATION** | 1 | 1️⃣ Stage Name | Primary Direct | Serial | ⏳ PENDING | `[░░░░░░░░░░] 0%` | No | None |
| **1 - PREPARATION** | 2 | 2️⃣ Stage Name | Primary Direct | Serial | ⏳ PENDING | `[░░░░░░░░░░] 0%` | No | Stage 1 |
| **2 - EXECUTE/TRACK** | 3 | 3️⃣ Stage Name | **Spawn KIRO (test 2, then N-2)** | **Parallel** | ⏳ PENDING | `[░░░░░░░░░░] 0%` | **Yes (2 workers)** | Stage 2 |
| **3 - VALIDATE** | 4 | 4️⃣ Validation | Primary Direct | Serial | ⏳ PENDING | `[░░░░░░░░░░] 0%` | No | Stage 3 |
| **4 - SUMMARY** | 5 | 5️⃣ Final Summary | Primary Direct | Serial | ⏳ PENDING | `[░░░░░░░░░░] 0%` | No | Stage 4 |
```

**Variable Derivation Pattern**:
- Identify variables derived at runtime (e.g., N = total items)
- Document derivation in first stage where it occurs
- Use variable notation throughout plan (N, N₁, N₂, ⌈N/3⌉, etc.)
- Provide example values for clarity

**Execution Mode Specification**:
- **Primary Direct**: Primary assistant executes directly (no spawn)
- **Spawn {Runner} (test X, then Y)**: Spawn after testing with specific runner
- **Spawn Batched**: Batched parallel execution for token management
- Document test-before-spawn protocol for all parallel stages

**Stage Descriptions**:
- Add short descriptions to transformation/processing stages
- Example: "Link question.jpg images to TBC files, creating image reference structure"
- Helps understand what happens at each step

**Validation Gates**:
- Define quality checkpoints between major phases
- Specify what gets validated, by whom (usually primary)
- Document gate pass criteria

**Test-Before-Spawn Protocol**:
- Test with 2 workers in serial mode first
- Validate outputs meet quality standards
- Decision point: PASS → full spawn, FAIL → debug and retry
- Document test commands with `--runner` and `--serial` flags

**Project State**
Current: work.state.PENDING
```

**Detailed Stage Breakdown Pattern** (from project-plan-4):

**For Primary Direct Stages**:
```markdown
### 3.1 Stage 1: {Stage Name} (PRIMARY ASSISTANT)
**Execution**: Direct (no spawn)
**Workers**: Primary assistant performs all tasks
**Description**: {Short 1-line description of what happens in this stage}

**Tasks**:
1. {Task 1 description}
2. {Task 2 description}
3. {Task 3 description}
4. Update tracking: Stage 1 complete

**Deliverable**: {What gets produced}
**NOTE**: {Any important notes about this stage}
```

**For Spawn Stages with Test-Before-Spawn**:
```markdown
### 3.6 Stage 6: {Stage Name} ⚡ SPAWN {RUNNER} AFTER TESTING
**Execution**: Spawn {Runner} workers (after 2-worker test)
**Spawned Assistant**: {Runner name - Kiro, Claude Code, etc.}
**Description**: {Short 1-line description of transformation/processing}

#### 3.6.1 Phase 6A: Spawn Testing (PRIMARY ASSISTANT)
**Tasks**:
1. Select 2 test items (Item 1, Item 2)
2. Create spawn test structure
3. Execute: `agent-spawn stage-6-spawn-test/ --runner {runner} --serial`
4. Validate outputs: {Expected output description}
5. **Decision**: If test PASSES → proceed to Phase 6B

#### 3.6.2 Phase 6B: Full Spawn (if test passes)
**Tasks**:
1. Create full spawn structure for remaining (N-2) items
2. Execute: `agent-spawn stage-6-{name}/ --runner {runner}` (max 5 concurrent workers)
3. Monitor {Runner} worker execution
4. Validate all N outputs created

**Deliverable**: {What gets produced - N files of type X}
```

**For Validation Gate Stages**:
```markdown
### 3.5 Stage 5: Validate {Artifact} (PRIMARY ASSISTANT) ✓ GATE 1
**Execution**: Direct (no spawn)
**Description**: Quality checkpoint ensuring {what is validated}

**Validation Checks**:
1. File existence: All {N} {file type} files exist
2. Content check: {Specific content requirements}
3. Format check: {Format/structure requirements}
4. Create validation report

**Pass Criteria**: All checks must pass to proceed to next stage
**Deliverable**: Validation report documenting results
```

**plan.md Template** (for each stage):

```markdown
# Stage Plan: {Stage Name}

## Stage Objective
{What this stage accomplishes}

## Dependencies
{Previous stage or prerequisites}

## Workers

### worker-1-{name}
**Task**: {Specific task description}
**Inputs**: {Required inputs}
**Outputs**: output.md with {expected content}
**Success Criteria**: {How to know it's done}

### worker-2-{name}
**Task**: {Specific task description}
**Inputs**: {Required inputs}
**Outputs**: output.md with {expected content}
**Success Criteria**: {How to know it's done}

### worker-3-{name}
**Task**: {Specific task description}
**Inputs**: {Required inputs}
**Outputs**: output.md with {expected content}
**Success Criteria**: {How to know it's done}

## Summation Requirements
Summator agent will:
- Read all worker output.md files
- Consolidate findings into stage summary
- Prepare context for next stage
- Update work.state.COMPLETE

## Stage State
Current: work.state.PENDING
```

**instructions.md Template** (for each worker):

```markdown
# Worker Instructions: {Worker Name}

## Task Description
{Clear, specific description of what this worker must do}

## Context
{Background information and project context}

## Inputs
- {Input 1}: {Description and location}
- {Input 2}: {Description and location}

## Required Outputs
Create `output.md` containing:
1. {Output element 1}
2. {Output element 2}
3. {Output element 3}

## Output Format
```
{Template or example of expected output format}
```

## Success Criteria
- [ ] All required outputs present
- [ ] Output meets quality standards
- [ ] Edge cases handled
- [ ] work.state.COMPLETE updated

## Constraints
- {Constraint 1}
- {Constraint 2}

## Resources
- {Resource 1}: {Location or description}
- {Resource 2}: {Location or description}
```

**Output**: Complete project_plan.md, all plan.md files, all instructions.md files

## State Management Patterns

### State File Lifecycle

**Project Level**:
1. `work.state.PENDING` - Created by Project Planner
2. `work.state.IN_PROGRESS` - When first stage starts
3. `work.state.COMPLETE` - When all stages complete and project summary exists

**Stage Level**:
1. `work.state.PENDING` - Created by Project Planner
2. `work.state.IN_PROGRESS` - When Work Planner activates stage
3. `work.state.COMPLETE` - When all workers complete and summary exists

**Worker Level**:
1. `work.state.PENDING` - (Optional) Created by Work Planner
2. `work.state.IN_PROGRESS` - When worker starts execution
3. `work.state.AWAITING_INPUT` - Worker needs information/clarification from PM (creates question.md, returns to IN_PROGRESS after answer.md)
4. `work.state.ENCOUNTERED_ERROR` - Worker hit error/blocker (creates error.md, PM resolves or escalates to human, returns to IN_PROGRESS after resolution)
5. `work.state.COMPLETE` - When output.md finished

### State Checking Logic

**Before Starting Stage**:
```
IF previous_stage NOT EXISTS OR previous_stage.state == COMPLETE:
    stage.state = IN_PROGRESS
ELSE:
    WAIT (stage cannot start yet)
```

**Before Completing Stage**:
```
IF all workers.state == COMPLETE AND summary.md EXISTS:
    stage.state = COMPLETE
ELSE:
    WAIT (stage not ready to complete)
```

**Before Completing Project**:
```
IF all stages.state == COMPLETE AND project summary.md EXISTS:
    project.state = COMPLETE
ELSE:
    WAIT (project not ready to complete)
```

### State Transition Flow

**Worker State Machine**:
```
PENDING → IN_PROGRESS → AWAITING_INPUT → IN_PROGRESS → COMPLETE
                              ↑              ↓
                              └─ (answer) ───┘

PENDING → IN_PROGRESS → ENCOUNTERED_ERROR → IN_PROGRESS → COMPLETE
                              ↑                  ↓
                              └─ (resolution) ───┘
```

**Interactive PM-Worker Protocol**:

**AWAITING_INPUT Flow**:
1. Worker encounters question/uncertainty
2. Worker creates `question.md` in worker folder
3. Worker changes state: `IN_PROGRESS` → `AWAITING_INPUT`
4. PM detects `AWAITING_INPUT` state, reads `question.md`
5. PM attempts to answer from context/data/previous work:
   - **Can answer**: PM creates `answer.md`, changes state to `IN_PROGRESS`
   - **Cannot answer**: PM escalates to `project-plan-X/questions.md`, notifies human
6. After human response, PM creates `answer.md`, changes state to `IN_PROGRESS`
7. Worker reads `answer.md`, resumes work in `IN_PROGRESS` state

**ENCOUNTERED_ERROR Flow**:
1. Worker encounters error/blocker
2. Worker creates `error.md` with error details in worker folder
3. Worker changes state: `IN_PROGRESS` → `ENCOUNTERED_ERROR`
4. PM detects `ENCOUNTERED_ERROR` state, reads `error.md`
5. PM analyzes error type:
   - **Resolvable** (config issue, retry needed): PM provides resolution via `resolution.md`, changes state to `IN_PROGRESS`
   - **Unresolvable** (network loss, permanent failure, human intervention): PM escalates to `project-plan-X/errors.md`, notifies human
6. After human intervention/guidance, PM provides resolution via `resolution.md`, changes state to `IN_PROGRESS`
7. Worker reads `resolution.md`, resumes work in `IN_PROGRESS` state

**Key Rules**:
- Both states are temporary pauses - worker always returns to `IN_PROGRESS`, not a new state
- PM acts as intelligent intermediary between worker and human
- PM resolves when possible, escalates when necessary
- All communication through files: question.md/answer.md, error.md/resolution.md

## Agent Role Specifications

### Project Planner Agent Role

**Inputs**: User requirements, project objectives

**Process**:
1. Analyze requirements
2. Decompose into stages (3-5 typical)
3. Create project folder structure
4. Write project_plan.md
5. Create stage folders with plan.md skeletons
6. Initialize work.state.PENDING

**Outputs**:
- Complete folder structure
- project_plan.md
- Stage folders with plan.md files
- work.state.PENDING

### Work Planner Agent Role

**Inputs**:
- Stage plan.md
- Previous stage summary.md (if applicable)

**Process**:
1. Read stage objectives from plan.md
2. Decompose into parallel workers (2-5 typical)
3. Create worker folders
4. Write detailed instructions.md for each worker
5. Update stage state to IN_PROGRESS

**Outputs**:
- Worker folders
- instructions.md files
- work.state.IN_PROGRESS

### Worker Agent Role

**Inputs**:
- instructions.md
- Any specified input files/data

**Process**:
1. Read and understand instructions.md
2. Execute assigned task autonomously
3. Apply domain expertise
4. Handle questions and errors interactively with PM:
   - **Need information**: Create question.md, change to AWAITING_INPUT, wait for answer.md from PM, return to IN_PROGRESS
   - **Encounter error**: Create error.md with error details, change to ENCOUNTERED_ERROR, wait for resolution.md from PM, return to IN_PROGRESS
   - PM acts as intermediary: resolves directly when possible, escalates to human when necessary
5. Produce results
6. Validate outputs against success criteria

**Outputs**:
- output.md with task results
- work.state.COMPLETE

### Summator Agent Role

**Inputs**:
- All worker output.md files within stage
- Stage plan.md for context

**Process**:
1. Wait for all workers to reach COMPLETE state
2. Read all worker output.md files
3. Synthesize and consolidate information
4. Identify patterns, themes, key findings
5. Create coherent narrative
6. Prepare context for next stage

**Outputs**:
- summary.md (stage or project level)
- work.state.COMPLETE

### Project Summator Agent Role

**Special case of Summator Agent for final project summary**

**Inputs**:
- All stage summary.md files
- project_plan.md for context

**Process**:
1. Wait for all stages to reach COMPLETE state
2. Read all stage summaries
3. Create comprehensive project summary
4. Highlight achievements and key findings
5. Document lessons learned

**Outputs**:
- project-plan-X/summary.md (final deliverable)
- work.state.COMPLETE (project level)

## Data Flow Patterns

### Sequential Stage Pattern

```
Stage 1 Workers → Stage 1 Summator → Stage 1 Summary
                                          ↓
                    Stage 2 Workers ← (uses Stage 1 Summary)
                          ↓
                    Stage 2 Summator → Stage 2 Summary
                                          ↓
                    Stage 3 Workers ← (uses Stage 2 Summary)
```

### Parallel Worker Pattern (within stage)

```
Work Planner
    ├──→ Worker 1 → output.md ──┐
    ├──→ Worker 2 → output.md ──┼──→ Summator → summary.md
    └──→ Worker 3 → output.md ──┘
```

### Full Project Flow

```
User Requirements
    ↓
Project Planner → project_plan.md + folder structure
    ↓
Stage 1: Work Planner → workers → outputs → Summator → summary
    ↓ (summary feeds into next stage)
Stage 2: Work Planner → workers → outputs → Summator → summary
    ↓ (summary feeds into next stage)
Stage 3: Work Planner → workers → outputs → Summator → summary
    ↓ (all summaries feed into final)
Project Summator → project summary.md
    ↓
Project COMPLETE
```

## Best Practices

### Project Planning

✅ **DO**:
- Keep stages logically distinct and sequential
- Maximize parallel workers within stages
- Create clear, specific worker instructions
- Define measurable success criteria
- Document dependencies explicitly

❌ **DON'T**:
- Create too many stages (3-5 is typical)
- Make workers dependent on each other within a stage
- Write vague or ambiguous instructions
- Skip state management
- Forget to plan for summation

### Worker Design

✅ **DO**:
- Make workers autonomous and independent
- Provide complete context in instructions.md
- Define clear output formats
- Specify success criteria
- Include relevant resources and references
- Handle errors gracefully with ENCOUNTERED_ERROR state
- Ask questions via AWAITING_INPUT when blocked
- Return to IN_PROGRESS after receiving answers/resolutions
- Document error context clearly in error.md (type, details, impact)
- Document questions with full context in question.md
- Trust PM to resolve or escalate appropriately
- Wait for answer.md or resolution.md before resuming

❌ **DON'T**:
- Create workers with unclear scope
- Assume workers have context beyond instructions
- Skip output format specification
- Make workers too large or too small
- Forget edge cases and error handling
- Fail silently without reporting errors
- Guess when information is missing
- Create new states after AWAITING_INPUT/ENCOUNTERED_ERROR
- Skip error documentation
- Proceed without answers when blocked
- Bypass PM by escalating directly to human
- Continue work while in AWAITING_INPUT or ENCOUNTERED_ERROR state

### State Management

✅ **DO**:
- Check states before transitions
- Verify prerequisites before starting stages
- Use simple file-based state (work.state.X)
- Maintain state consistency across hierarchy
- Enable progress visibility

❌ **DON'T**:
- Update states prematurely
- Skip state verification
- Use complex state mechanisms
- Allow inconsistent states
- Hide progress from users

### Summation

✅ **DO**:
- Wait for all workers to complete
- Read all worker outputs thoroughly
- Synthesize, don't just concatenate
- Create coherent narratives
- Prepare context for next stage

❌ **DON'T**:
- Summarize before all workers done
- Miss worker outputs
- Simply concatenate without synthesis
- Create summaries without actionable insights
- Forget to update state to COMPLETE

## Example Projects

### Example 1: Research Report Project

```
project-plan-1/
├── project_plan.md
├── work.state.COMPLETE
├── summary.md
│
├── stage-1-literature-review/
│   ├── plan.md
│   ├── work.state.COMPLETE
│   ├── summary.md
│   ├── worker-1-web-research/
│   │   ├── instructions.md
│   │   ├── output.md
│   │   └── work.state.COMPLETE
│   ├── worker-2-academic-papers/
│   │   └── ... (similar structure)
│   └── worker-3-expert-interviews/
│       └── ... (similar structure)
│
├── stage-2-data-analysis/
│   ├── plan.md
│   ├── work.state.COMPLETE
│   ├── summary.md
│   ├── worker-1-trend-analysis/
│   ├── worker-2-gap-analysis/
│   └── worker-3-synthesis/
│
└── stage-3-report-writing/
    ├── plan.md
    ├── work.state.COMPLETE
    ├── summary.md
    └── worker-1-final-report/
```

### Example 2: Content Creation Project

```
project-plan-2/
├── project_plan.md
├── work.state.COMPLETE
├── summary.md
│
├── stage-1-planning/
│   ├── worker-1-outline/
│   ├── worker-2-research/
│   └── worker-3-style-guide/
│
├── stage-2-content-production/
│   ├── worker-1-chapter-1/
│   ├── worker-2-chapter-2/
│   ├── worker-3-chapter-3/
│   └── worker-4-chapter-4/
│
└── stage-3-finalization/
    ├── worker-1-editing/
    ├── worker-2-formatting/
    └── worker-3-publishing/
```

## Templates Reference

### Available Templates

All templates are available in `agents/Agentic_Architect/templates/`:

1. **project_plan_template.md** - Comprehensive master project plan template
   - Location: `agents/Agentic_Architect/templates/project_plan_template.md`
   - Includes: Project tracking with progress bars, agentic vs manual time estimates, mermaid diagrams, stage breakdown
   - Features:
     - 📊 Visual progress tracking with progress bars
     - ⏱️ Agentic time estimates vs Manual time estimates
     - 💾 Time saved calculations (in days)
     - 🔄 Workflow phase diagrams
     - 📈 Stage dependency visualization
     - ✅ Success metrics and completion criteria

2. **plan.md** - Stage plan template (embedded in this skill)
3. **instructions.md** - Worker instruction template (embedded in this skill)
4. **Folder Structure** - Complete hierarchy pattern (embedded in this skill)
5. **State Management** - State file patterns and logic (embedded in this skill)

### Using the Project Plan Template

To use the comprehensive project plan template:

1. **Copy the template**:
   ```bash
   cp agents/Agentic_Architect/templates/project_plan_template.md \
      .claude/plans/project-plan-{name}-{number}/project_plan.md
   ```

2. **Replace all placeholders** (indicated by `{...}`):
   - `{Project Name}` - Your project title
   - `{YYYY-MM-DD}` - Creation date
   - `{X}` - Version number
   - `{N}` - Numbers (stage count, worker count, etc.)
   - `{Stage Name}` - Stage names
   - `{Objective X}` - Specific objectives
   - All other `{placeholders}` with actual content

3. **Update tracking section** as project progresses:
   - Change progress bars from `░` to `█` for completed portions
   - Update status icons: ⏳→🔄→✅
   - Update worker counts: `0/4` → `2/4` → `4/4`
   - Update overall progress percentage
   - Update current activity and blockers

4. **Customize mermaid diagrams** to match your specific workflow

### Template Features

The `project_plan_template.md` includes:

✅ **Project Tracking Dashboard**
- Overall progress bar
- Current status (active stage, activity, blockers)
- Stage-by-stage progress table with:
  - Visual progress bars per stage
  - Worker completion counts
  - Agentic time estimates (minutes/hours)
  - Manual time estimates (days/weeks)
  - Time saved calculations (in days)

✅ **Visual Workflow Diagrams**
- Project workflow phases (mermaid)
- Stage dependencies (mermaid)
- Decision points and feedback loops

✅ **Comprehensive Stage Breakdown**
- Stage objectives and dependencies
- Worker descriptions
- Deliverables
- Duration estimates (agentic vs manual)
- State tracking

✅ **Project Metadata**
- Technical stack details
- Folder structure specification
- Key design decisions
- Testing strategy
- Success metrics
- Usage examples

### Template Placeholders Guide

| Placeholder | Example | Description |
|-------------|---------|-------------|
| `{Project Name}` | "Agent Spawner System" | Full project title |
| `{YYYY-MM-DD}` | "2025-12-24" | Creation date |
| `{N}` | 5, 4, 11 | Numeric values (stages, workers) |
| `{Stage Name}` | "Research", "Implementation" | Stage descriptive name |
| `{X-Y min/hr}` | "10-20 min", "1-2 hr" | Agentic time range |
| `{X-Y days/wks}` | "2-3 days", "1-2 weeks" | Manual time range |
| `{Objective X}` | "Agent Spawning" | Specific objective description |
| `{Language/Framework}` | "Python 3.8+" | Technology choice |
| `{Dependency X}` | "subprocess", "pathlib" | Technical dependency |

### Example: Time Estimation Guidelines

**Agentic Time** (parallel execution):
- Research stage (4 workers): 10-20 minutes
- Design stage (4 workers): 15-25 minutes
- Implementation (11 workers, 3 sub-stages): 45-90 minutes
- Testing (4 workers): 20-30 minutes
- Documentation (4 workers): 15-25 minutes

**Manual Time** (human developer):
- Research: 2-3 days
- Design: 2-3 days
- Implementation: 1-2 weeks
- Testing: 3-5 days
- Documentation: 2-3 days

**Time Saved Calculation**:
```
Time Saved = Manual Time - Agentic Time
Example: 2.5 days - 15 min ≈ 2.5 days saved
```

## Integration with TBT Workflow

This skill integrates with TBT (Turn-by-Turn) workflow:

- **Planning**: Create plans before execution (TBT requirement)
- **Staging**: Stage project plans in `.claude/staging/staging_X/` for review
- **Approval**: Get user approval before creating folder structure
- **Snapshots**: Snapshot before creating project structure
- **Logging**: Log project creation in history.log
- **State**: Use work.state files compatible with TBT state tracking

## Summary

This Project Planning Skill provides:
- ✅ Comprehensive project decomposition methodology
- ✅ Hierarchical stage and worker structure
- ✅ State management patterns
- ✅ Agent role specifications
- ✅ Complete templates for all artifacts
- ✅ Best practices and examples
- ✅ Integration with TBT workflow

Use this skill to create well-structured, manageable multi-stage agentic projects with clear responsibilities, dependencies, and state tracking.
