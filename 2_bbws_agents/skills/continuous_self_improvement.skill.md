# Continuous Self Improvement Skill

**Version**: 1.0
**Created**: 2024-12-17
**Type**: Meta-Skill (Agent Self-Enhancement)

---

## Skill Identity

**Name**: Continuous Self Improvement
**Purpose**: Enable agents to reflect on context history and extract reusable workflows as abstract skills, facilitating agent self-improvement without exposing proprietary data.

---

## When to Invoke

### User-Initiated Triggers
- "Extract this workflow as a skill"
- "Save this pattern for reuse"
- "Create a skill from what we just did"
- "Capture this workflow"
- "Document this process as a skill"

### Agent Self-Reflection Triggers
The agent SHOULD offer this skill when:
- Long-running task (>10 turns) completes successfully
- Complex multi-step workflow was executed
- Novel problem-solving pattern emerged
- User expressed satisfaction with approach
- Reusable pattern detected in conversation

**Agent Offer Template**:
```
I noticed we completed a [type] workflow that might be valuable to capture.
Would you like me to extract this as a reusable skill?

This would:
- Chronicle the abstract workflow steps
- Remove any proprietary/customer-specific data
- Create a skill file for future reference

Options:
1. Create standalone skill file
2. Create skill spec for later refinement
3. Skip - not needed
```

---

## Input Requirements

**Primary Input**: Current conversation context

**Context Elements Analyzed**:
- Task description and objectives
- Problem-solving steps taken
- Decision points and rationale
- Tools and techniques used
- Error handling approaches
- Success criteria met
- User feedback received

**User Input Required**:
- Skill name (or agent suggests based on context)
- Output format preference (standalone/spec/embedded)
- Target agent folder (if standalone)
- Confirmation of abstraction approach

---

## Processing Steps

### Step 1: Context Analysis
```
1. Scan conversation history for:
   - Initial problem statement
   - Key decision points
   - Actions taken
   - Outcomes achieved

2. Identify workflow boundaries:
   - Start: When task was defined
   - End: When task was completed/current point

3. Extract structural elements:
   - Inputs received
   - Transformations applied
   - Outputs produced
```

### Step 2: Pattern Extraction
```
1. Identify reusable patterns:
   - Recurring decision logic
   - Standard processing sequences
   - Error handling approaches
   - Validation techniques

2. Generalize specific instances:
   - Replace specific values with placeholders
   - Convert concrete examples to abstract patterns
   - Identify variable vs constant elements
```

### Step 3: Abstraction (Privacy Protection)
```
REMOVE (proprietary/sensitive):
- Customer names, IDs, identifiers
- Specific file paths with user data
- API keys, credentials, secrets
- Business-specific values
- Internal system names
- Personally identifiable information

PRESERVE (workflow logic):
- Abstract process steps
- Decision criteria (generalized)
- Tool usage patterns
- Error handling logic
- Success criteria (generalized)
- Structural patterns
```

### Step 4: Skill Generation

**Option A: Skill Spec File** (`xyz_skill_spec.md`)
```markdown
# [Skill Name] Spec

## 1. Skill Identity and Purpose
[What does this skill do? Why is it valuable?]

## 2. Trigger Conditions
[When should this skill be invoked?]

## 3. Input Requirements
[What inputs does the skill need?]

## 4. Processing Steps (Abstract Workflow)
[Step-by-step workflow, abstracted]

## 5. Output Specifications
[What does the skill produce?]

## 6. Success Criteria
[How do we know it worked?]

## 7. Error Handling
[What can go wrong? How to handle?]

## 8. Usage Examples
[Abstract examples of usage]

## 9. Abstraction Notes
[What was generalized/removed for privacy]

## 10. Improvement Opportunities
[How could this skill be enhanced?]
```

**Option B: Standalone Skill File** (`xyz_skill.md`)
```markdown
# [Skill Name]

**Version**: 1.0
**Created**: [Date]
**Extracted From**: [Session type, abstracted]

---

## Purpose
[Abstract purpose statement]

## Trigger Conditions
[When to use this skill]

## Workflow

### Inputs
[Required inputs, abstracted]

### Process
1. [Step 1]
2. [Step 2]
...

### Outputs
[Expected outputs]

## Decision Logic
[Key decision points and criteria]

## Error Handling
[Error scenarios and responses]

## Success Criteria
[How to verify success]

---

## Abstraction Notes
- [What was generalized]
- [Privacy considerations applied]

## Origin
- **Session Type**: [e.g., "Infrastructure provisioning workflow"]
- **Pattern Category**: [e.g., "Multi-step deployment"]
- **Abstraction Level**: [High/Medium/Low]
```

**Option C: Embedded Skill** (within agent.md)
```markdown
### Skill: [skill_name]

**Purpose**: [Brief purpose]

**Trigger**: [When to use]

**Workflow**:
1. [Step 1]
2. [Step 2]
...

**Outputs**: [What it produces]
```

### Step 5: Placement
```
Standalone/Spec:
  Path: [agent_folder]/skills/[skill_name].skill.md
  Path: [agent_folder]/skills/[skill_name]_spec.md

Embedded:
  Location: [agent_folder]/agent.md
  Section: ## Skills
```

### Step 6: Verification
```
1. Review generated skill for:
   - Completeness of workflow capture
   - Successful abstraction (no proprietary data)
   - Clarity and reusability

2. Confirm with user:
   - Does this capture the workflow accurately?
   - Is the abstraction appropriate?
   - Any refinements needed?
```

---

## Output Specifications

### Primary Outputs

| Output | Format | Location |
|--------|--------|----------|
| Skill Spec | `xyz_skill_spec.md` | `[agent]/skills/` |
| Skill File | `xyz_skill.md` | `[agent]/skills/` |
| Embedded Skill | Markdown section | `[agent]/agent.md` |

### Output Quality Criteria
- **Abstract**: No proprietary/customer data
- **Complete**: Full workflow captured
- **Reusable**: Can be applied to similar problems
- **Clear**: Understandable without original context

---

## Success Criteria

The skill extraction has succeeded when:

1. **Workflow Captured**: All key steps documented
2. **Privacy Protected**: No proprietary data in output
3. **Reusable**: Skill can guide future similar tasks
4. **User Approved**: User confirms accuracy and value
5. **Properly Placed**: File in correct location

---

## Error Handling

### Insufficient Context
```
If: Context too short or unclear for meaningful extraction
Then:
  - Inform user that context may be insufficient
  - Offer to proceed with partial extraction
  - Suggest what additional context would help
```

### Privacy Concerns
```
If: Uncertain if content is proprietary
Then:
  - Flag uncertain elements to user
  - Err on side of caution (remove if unsure)
  - Ask user to confirm abstraction is sufficient
```

### Ambiguous Workflow
```
If: Multiple workflows or unclear boundaries
Then:
  - Present identified workflows to user
  - Ask which to extract
  - Offer to extract multiple as separate skills
```

---

## Usage Examples

### Example 1: Infrastructure Deployment Skill

**Context**: Agent completed multi-step ECS deployment

**User**: "Extract this workflow as a skill"

**Processing**:
1. Analyze: 15-turn deployment conversation
2. Extract: Terraform → ECS → DNS workflow pattern
3. Abstract: Remove specific tenant names, account IDs
4. Generate: `infrastructure_deployment.skill.md`

**Output**:
```markdown
# Infrastructure Deployment Skill

## Purpose
Guide multi-step infrastructure deployment following IaC principles.

## Workflow
1. Validate prerequisites (permissions, state)
2. Plan infrastructure changes
3. Review and approve plan
4. Apply changes incrementally
5. Verify deployment
6. Update documentation

## Decision Logic
- If plan shows destructive changes → require explicit confirmation
- If deployment fails → rollback to last known good state
...
```

### Example 2: Agent Self-Offer

**Context**: Long debugging session (12 turns) completes successfully

**Agent Offers**:
```
I noticed we completed a complex debugging workflow that resolved
a multi-component integration issue.

Would you like me to extract this as a reusable skill?
The abstract pattern could help with similar debugging scenarios.

1. Create standalone skill file
2. Create skill spec for refinement
3. Skip
```

---

## Integration with TBT Workflow

When extracting skills, follow TBT protocol:

1. **Log Intent**: Record skill extraction request
2. **Plan**: Show extraction plan before proceeding
3. **Stage**: Stage skill file for review before finalizing
4. **Verify**: Confirm with user before committing

---

## Skill Spec Template

For creating `xyz_skill_spec.md`:

```markdown
# [Skill Name] Specification

## 1. Skill Identity and Purpose
What does this skill do? What problem does it solve?

## 2. Trigger Conditions
When should this skill be invoked? What signals its need?

## 3. Input Requirements
What inputs are required? What format?

## 4. Processing Steps
Step-by-step abstract workflow (no proprietary details).

## 5. Output Specifications
What does the skill produce? What format?

## 6. Success Criteria
How do we know the skill executed successfully?

## 7. Error Handling
What errors can occur? How should they be handled?

## 8. Usage Examples
Abstract examples showing skill application.

## 9. Abstraction Notes
What was generalized or removed for privacy?
What assumptions were made?

## 10. Improvement Opportunities
How could this skill be enhanced in the future?
What variations might be useful?
```

---

## Version History

- **v1.0** (2024-12-17): Initial skill definition
