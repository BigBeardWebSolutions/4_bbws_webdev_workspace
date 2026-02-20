# Project Plan: {Project Name}

**Created**: {YYYY-MM-DD} (Version {X})
**Project Manager**: Agentic Project Manager
**Version**: {X}
**Status**: ⏳ PENDING

---

## 🎯 Project Overview

{Brief description of what this project will accomplish - 2-3 sentences explaining the goal, scope, and value}

### Key Objectives

1. **{Objective 1}**: {Brief description of what will be achieved}
2. **{Objective 2}**: {Brief description of what will be achieved}
3. **{Objective 3}**: {Brief description of what will be achieved}
4. **{Objective 4}**: {Brief description of what will be achieved}
5. **{Objective 5}**: {Brief description of what will be achieved}

### Success Criteria

- ✅ {Measurable criterion 1}
- ✅ {Measurable criterion 2}
- ✅ {Measurable criterion 3}
- ✅ {Measurable criterion 4}
- ✅ {Measurable criterion 5}

---

## 📊 Project Tracking

### Overall Progress: 0% Complete

```
[░░░░░░░░░░░░░░░░░░░░] 0/{N} stages complete
```

### Current Status
- **Active Stage**: None (Project not started)
- **Current Activity**: {Current work being done or "Awaiting approval"}
- **Blockers**: {List blockers or "None"}

### Stage Progress

| # | Stage | Status | Progress | Workers | Agentic Time | Manual Time | Time Saved | Sub-Plan |
|---|-------|--------|----------|---------|--------------|-------------|------------|----------|
| 1 | {Stage Name} | ⏳ PENDING | `[░░░░░░░░░░] 0/{N}` | 0/{N} | {X-Y min/hr} | {X-Y days/wks} | ~{N} days | [View](stage-1-{name}.md) |
| 2 | {Stage Name} | ⏳ PENDING | `[░░░░░░░░░░] 0/{N}` | 0/{N} | {X-Y min/hr} | {X-Y days/wks} | ~{N} days | [View](stage-2-{name}.md) |
| 3 | {Stage Name} | ⏳ PENDING | `[░░░░░░░░░░] 0/{N}` | 0/{N} | {X-Y min/hr} | {X-Y days/wks} | ~{N} days | [View](stage-3-{name}.md) |
| 4 | {Stage Name} | ⏳ PENDING | `[░░░░░░░░░░] 0/{N}` | 0/{N} | {X-Y min/hr} | {X-Y days/wks} | ~{N} days | [View](stage-4-{name}.md) |
| 5 | {Stage Name} | ⏳ PENDING | `[░░░░░░░░░░] 0/{N}` | 0/{N} | {X-Y min/hr} | {X-Y days/wks} | ~{N} days | [View](stage-5-{name}.md) |
| | **TOTAL** | | | **{N} workers** | **~{X-Y} hours** | **~{X-Y} weeks** | **~{N} days** | |

**Folder Structure**:
```
plans/
└── {project-name}/
    ├── main-plan.md              # This file (main project plan)
    ├── stage-1-{name}.md         # Detailed sub-plan for Stage 1
    ├── stage-2-{name}.md         # Detailed sub-plan for Stage 2
    ├── stage-3-{name}.md         # Detailed sub-plan for Stage 3
    ├── stage-4-{name}.md         # Detailed sub-plan for Stage 4
    └── stage-5-{name}.md         # Detailed sub-plan for Stage 5
```

**Legend**: ⏳ PENDING | 🔄 IN_PROGRESS | ✅ COMPLETE | ❌ FAILED | ⏸️ PAUSED

**Progress Bar Guide**:
- Empty: `[░░░░░░░░░░]` (0%)
- 50%: `[█████░░░░░]`
- 100%: `[██████████]`

---

## 🔄 Project Workflow Phases

```mermaid
graph TB
    Start([Project Request]) --> Stage1[Stage 1: {Name}]
    Stage1 --> Stage2[Stage 2: {Name}]
    Stage2 --> Decision{Decision<br/>Point?}
    Decision -->|Yes| Stage1
    Decision -->|No| Stage3[Stage 3: {Name}]
    Stage3 --> Stage4[Stage 4: {Name}]
    Stage4 --> TestPass{Quality<br/>Check?}
    TestPass -->|No| Stage3
    TestPass -->|Yes| Stage5[Stage 5: {Name}]
    Stage5 --> Complete([Project Complete])

    style Stage1 fill:#e1f5ff
    style Stage2 fill:#fff4e1
    style Stage3 fill:#e7f5e1
    style Stage4 fill:#ffe1e1
    style Stage5 fill:#f0e1ff
    style Decision fill:#ffd700
    style TestPass fill:#ffd700
    style Start fill:#90EE90
    style Complete fill:#90EE90
```

**Flow Explanation:**
- **Stage 1**: {Brief explanation of what happens in this stage}
- **Stage 2**: {Brief explanation of what happens in this stage}
- **Stage 3**: {Brief explanation of what happens in this stage}
- **Stage 4**: {Brief explanation of what happens in this stage}
- **Stage 5**: {Brief explanation of what happens in this stage}

---

## 📊 Stage Breakdown

### Stage 1: {Stage Name}
**Objective**: {Clear statement of what this stage accomplishes}

**Dependencies**: None (or specify prerequisite stages)
**Deliverables**:
- {Deliverable 1 description}
- {Deliverable 2 description}
- {Deliverable 3 description}

**Workers**:
- `worker-1-{name}`: {Brief description of worker responsibility}
- `worker-2-{name}`: {Brief description of worker responsibility}
- `worker-3-{name}`: {Brief description of worker responsibility}
- `worker-4-{name}`: {Brief description of worker responsibility}

**Expected Duration**:
- Agentic: {X-Y} minutes
- Manual: {X-Y} days
**State**: ⏳ PENDING

---

### Stage 2: {Stage Name}
**Objective**: {Clear statement of what this stage accomplishes}

**Dependencies**: Stage 1 complete
**Deliverables**:
- {Deliverable 1 description}
- {Deliverable 2 description}

**Workers**:
- `worker-1-{name}`: {Brief description of worker responsibility}
- `worker-2-{name}`: {Brief description of worker responsibility}
- `worker-3-{name}`: {Brief description of worker responsibility}
- `worker-4-{name}`: {Brief description of worker responsibility}

**Expected Duration**:
- Agentic: {X-Y} minutes
- Manual: {X-Y} days
**State**: ⏳ PENDING

---

### Stage 3: {Stage Name}
**Objective**: {Clear statement of what this stage accomplishes}

**Dependencies**: Stage 2 complete
**Deliverables**:
- {Deliverable 1 description}
- {Deliverable 2 description}

**Sub-Stages** (For large stages with hierarchical breakdown):

#### Stage 3.1: {Sub-stage Name}
**Workers**:
- `worker-1-{name}`: {Brief description}
- `worker-2-{name}`: {Brief description}
- `worker-3-{name}`: {Brief description}

#### Stage 3.2: {Sub-stage Name}
**Workers**:
- `worker-1-{name}`: {Brief description}
- `worker-2-{name}`: {Brief description}
- `worker-3-{name}`: {Brief description}

**Expected Duration**:
- Agentic: {X-Y} hours
- Manual: {X-Y} weeks
**State**: ⏳ PENDING

---

### Stage 4: {Stage Name}
**Objective**: {Clear statement of what this stage accomplishes}

**Dependencies**: Stage 3 complete
**Deliverables**:
- {Deliverable 1 description}
- {Deliverable 2 description}

**Workers**:
- `worker-1-{name}`: {Brief description of worker responsibility}
- `worker-2-{name}`: {Brief description of worker responsibility}
- `worker-3-{name}`: {Brief description of worker responsibility}
- `worker-4-{name}`: {Brief description of worker responsibility}

**Expected Duration**:
- Agentic: {X-Y} minutes
- Manual: {X-Y} days
**State**: ⏳ PENDING

---

### Stage 5: {Stage Name}
**Objective**: {Clear statement of what this stage accomplishes}

**Dependencies**: Stage 4 complete
**Deliverables**:
- {Deliverable 1 description}
- {Deliverable 2 description}

**Workers**:
- `worker-1-{name}`: {Brief description of worker responsibility}
- `worker-2-{name}`: {Brief description of worker responsibility}
- `worker-3-{name}`: {Brief description of worker responsibility}
- `worker-4-{name}`: {Brief description of worker responsibility}

**Expected Duration**:
- Agentic: {X-Y} minutes
- Manual: {X-Y} days
**State**: ⏳ PENDING

---

## 🔧 Technical Stack

### Implementation Language/Tools
**Primary**: {Language/Framework}
**Rationale**:
- {Reason 1}
- {Reason 2}
- {Reason 3}

**Alternative**: {Alternative technology} (future enhancement)
- {Advantage 1}
- {Advantage 2}

### Core Dependencies
- **{Dependency 1}**: {Purpose}
- **{Dependency 2}**: {Purpose}
- **{Dependency 3}**: {Purpose}
- **{Dependency 4}**: {Purpose}

### Integration Points
- **{Integration 1}**: {Description of what/how it integrates}
- **{Integration 2}**: {Description of what/how it integrates}
- **{Integration 3}**: {Description of what/how it integrates}

---

## 📁 Project Folder Structure

```
{project-folder-name}/
├── {file-or-folder-1}              # Description
├── {file-or-folder-2}              # Description
│   ├── {subfolder-1}/
│   │   ├── {file-1}                # Description
│   │   └── {file-2}                # Description
│   │
│   └── {subfolder-2}/
│       └── {file-3}                # Description
│
├── {folder-3}/                     # Description
│   ├── {subfolder-1}/
│   ├── {subfolder-2}/
│   └── {subfolder-3}/
│
├── {folder-4}/                     # Description
│   ├── {subfolder-1}/
│   └── {subfolder-2}/
│
└── {important-file}.md             # Description
```

---

## 🎯 Key Design Decisions

### Decision 1: {Decision Title}
**Context**: {Why this decision was needed}
**Options Considered**:
- Option A: {Description}
- Option B: {Description}

**Chosen**: {Selected option}
**Rationale**: {Why this option was chosen}

### Decision 2: {Decision Title}
**Context**: {Why this decision was needed}
**Options Considered**:
- Option A: {Description}
- Option B: {Description}

**Chosen**: {Selected option}
**Rationale**: {Why this option was chosen}

---

## 🧪 Testing Strategy

### Unit Tests
- **{Component 1}**: {Test descriptions}
- **{Component 2}**: {Test descriptions}
- **{Component 3}**: {Test descriptions}

### Integration Tests
- **{Integration scenario 1}**: {Test description}
- **{Integration scenario 2}**: {Test description}
- **{Integration scenario 3}**: {Test description}

### Test Coverage Target
- **Minimum**: {X}% code coverage
- **Goal**: {Y}%+ code coverage
- **Critical Paths**: 100% coverage ({list critical components})

---

## 📈 Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| **{Metric 1}** | {Target value} | {How measured} |
| **{Metric 2}** | {Target value} | {How measured} |
| **{Metric 3}** | {Target value} | {How measured} |
| **{Metric 4}** | {Target value} | {How measured} |
| **{Metric 5}** | {Target value} | {How measured} |

---

## 🚀 Usage Examples

### Basic Usage
```bash
# Example command 1
{command with description}

# Example command 2
{command with description}

# Example command 3
{command with description}
```

### Advanced Usage
```{language}
# Example code snippet
{code example showing usage}
```

---

## 🔄 Stage Dependencies

```mermaid
graph LR
    S1[Stage 1:<br/>{Name}] --> S2[Stage 2:<br/>{Name}]
    S2 --> S3[Stage 3:<br/>{Name}]
    S3 --> S4[Stage 4:<br/>{Name}]
    S4 --> S5[Stage 5:<br/>{Name}]

    S3 --> S3.1[Stage 3.1:<br/>{Name}]
    S3 --> S3.2[Stage 3.2:<br/>{Name}]
    S3 --> S3.3[Stage 3.3:<br/>{Name}]

    S3.1 --> S3.2
    S3.2 --> S3.3

    style S1 fill:#e1f5ff
    style S2 fill:#fff4e1
    style S3 fill:#e7f5e1
    style S3.1 fill:#d4f5d4
    style S3.2 fill:#d4f5d4
    style S3.3 fill:#d4f5d4
    style S4 fill:#ffe1e1
    style S5 fill:#f0e1ff
```

---

## 🎓 Lessons from Research

### From {Source 1}
1. ✅ **{Lesson 1}**: {Brief description}
2. ✅ **{Lesson 2}**: {Brief description}
3. ✅ **{Lesson 3}**: {Brief description}

### From {Source 2}
1. ✅ **{Lesson 1}**: {Brief description}
2. ✅ **{Lesson 2}**: {Brief description}
3. ✅ **{Lesson 3}**: {Brief description}

### From {Source 3}
1. ✅ **{Lesson 1}**: {Brief description}
2. ✅ **{Lesson 2}**: {Brief description}
3. ✅ **{Lesson 3}**: {Brief description}

---

## 📝 Notes and Assumptions

### Assumptions
- {Assumption 1}
- {Assumption 2}
- {Assumption 3}
- {Assumption 4}
- {Assumption 5}

### Future Enhancements
- **{Enhancement 1}**: {Description}
- **{Enhancement 2}**: {Description}
- **{Enhancement 3}**: {Description}
- **{Enhancement 4}**: {Description}
- **{Enhancement 5}**: {Description}

---

## 🏁 Project Completion Criteria

The project is considered **COMPLETE** when:

1. ✅ All {N} stages are marked `work.state.COMPLETE`
2. ✅ {Specific completion criterion}
3. ✅ {Specific completion criterion}
4. ✅ {Specific completion criterion}
5. ✅ {Specific completion criterion}
6. ✅ {Specific completion criterion}
7. ✅ {Specific completion criterion}
8. ✅ Project summary document created by Project Summator

---

**Project Manager**: Agentic Project Manager
**Next Action**: {What needs to happen next - e.g., "Await user approval to begin Stage 1"}
