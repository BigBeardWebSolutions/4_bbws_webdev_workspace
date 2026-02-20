# Plan: Create Continuous Self Improvement Skill

**Created**: 2024-12-17
**Status**: AWAITING APPROVAL

---

## Skill Overview

**Name**: Continuous Self Improvement
**Purpose**: Enable agents to reflect on context history and extract reusable workflows as abstract skills

## Key Capabilities

1. **Context Reflection**: Analyze current conversation/task context
2. **Workflow Extraction**: Identify reusable patterns from problem-solving sessions
3. **Abstraction**: Remove proprietary/customer-specific data while preserving workflow logic
4. **Skill Generation**: Create skill_spec.md (≤10 questions) or skill.md files
5. **Skill Placement**: Embed in agent or create standalone in `[agent]/skills/`

## Trigger Conditions

- **User Invoked**: User explicitly requests skill extraction
- **Agent Offered**: Agent self-reflects on long-running task and offers to capture workflow

## Output Formats

### Option A: Standalone Skill File
```
[agent_folder]/skills/xyz_skill.md
```

### Option B: Embedded Skill (within agent.md)
```markdown
## Skills

### xyz_skill
[skill definition]
```

### Option C: Skill Spec (for later generation)
```
[agent_folder]/skills/xyz_skill_spec.md
```

## Skill Spec Template (≤10 Questions)

1. Skill Identity and Purpose
2. Trigger Conditions
3. Input Requirements
4. Processing Steps (Abstract Workflow)
5. Output Specifications
6. Success Criteria
7. Error Handling
8. Usage Examples
9. Abstraction Notes (what was removed for privacy)
10. Improvement Opportunities

## File Location

**Target**: `/Users/tebogotseka/Documents/agentic_work/2_bbws_agents/skills/continuous_self_improvement.skill.md`

---

## Approval Checklist

- [ ] Skill structure approved
- [ ] Trigger conditions approved
- [ ] Output formats approved
- [ ] Ready to implement

**Awaiting your approval to proceed.**
