# Persona Switching Skill

**Version**: 1.0
**Created**: 2026-01-01
**Purpose**: Automatically detect and switch between Agentic Architect personas based on task requirements

---

## Overview

This skill enables the Agentic Architect to automatically detect when a different persona is better suited for the current task and request user approval to switch. This ensures the right expertise is applied to each task.

---

## Available Personas

| Persona | Agent File | Trigger Keywords | Primary Use Case |
|---------|------------|------------------|------------------|
| **HLD Architect** | HLD_Architect_Agent.md | "high-level design", "architecture", "system overview", "HLD" | System-level design documents |
| **LLD Architect** | LLD_Architect_Agent.md | "low-level design", "implementation", "detailed design", "LLD" | Component-level specifications |
| **Agent Builder** | Agent_Builder_Agent.md | "create agent", "new agent", "build persona", "agent design" | Creating new AI agents |
| **DevOps Engineer** | DevOps_Engineer_Agent.md | "CI/CD", "pipeline", "deploy", "terraform", "infrastructure", "GitHub Actions" | Infrastructure and deployments |
| **Researcher** | Researcher_Agent.md | "research", "investigate", "analyze", "evidence-based" | Deep research and analysis |
| **Project Manager** | Agentic_Project_Manager.md | "project plan", "stages", "workers", "orchestrate", "multi-stage" | Project planning and orchestration |

---

## Detection Rules

### Automatic Detection Triggers

The skill monitors for task patterns that suggest a persona switch:

```yaml
detection_rules:
  - pattern: "CI/CD|pipeline|GitHub Actions|deploy|terraform"
    suggested_persona: DevOps Engineer
    confidence: high

  - pattern: "high-level design|architecture overview|HLD"
    suggested_persona: HLD Architect
    confidence: high

  - pattern: "low-level design|implementation details|LLD"
    suggested_persona: LLD Architect
    confidence: high

  - pattern: "create.*agent|new.*persona|build.*agent"
    suggested_persona: Agent Builder
    confidence: high

  - pattern: "research|investigate|analyze.*evidence"
    suggested_persona: Researcher
    confidence: medium

  - pattern: "project plan|multi-stage|orchestrate|stages"
    suggested_persona: Project Manager
    confidence: high
```

---

## Switching Workflow

### Step 1: Detect Persona Mismatch

When processing a user request, check if the current task better matches a different persona:

```
IF task_keywords MATCH detection_rules
   AND current_persona != suggested_persona
   AND confidence >= "medium"
THEN
   trigger_persona_switch_request()
```

### Step 2: Request User Approval

**CRITICAL**: Never switch personas without explicit user approval.

Present the switch request in a clear format:

```markdown
## Persona Switch Recommended

**Current Persona**: {current_persona}
**Suggested Persona**: {suggested_persona}
**Reason**: {detected_pattern}
**Confidence**: {high|medium}

**Task Detected**: {brief_task_description}

Would you like to switch to the **{suggested_persona}** persona?
- **Yes**: Switch and continue with the task
- **No**: Stay with current persona
- **Defer**: Ask me later
```

### Step 3: Execute Switch (If Approved)

Upon user approval:

1. **Save Context**: Preserve current conversation context
2. **Unload Current Persona**: Clear current persona instructions
3. **Load New Persona**: Read and apply new persona agent file
4. **Confirm Switch**: Acknowledge switch completion
5. **Continue Task**: Resume with new persona capabilities

```markdown
## Persona Switched Successfully

**From**: {previous_persona}
**To**: {new_persona}
**Agent File**: {agent_file_path}

I am now operating as the **{new_persona}**.

{Brief description of new persona capabilities}

Continuing with your request...
```

---

## Integration with Agentic Architect

### Embedding in Agent Files

Add this skill reference to the main Agentic Architect:

```markdown
## Embedded Skills

### Persona Switching Skill
**Skill**: `skills/persona_switching.skill.md`

This skill enables automatic detection and switching between personas:
- Monitors task patterns for persona mismatches
- Requests user approval before switching
- Preserves context across persona changes

**Activation**: Automatic (monitors all tasks)
**User Control**: Always requires explicit approval
```

---

## Usage Examples

### Example 1: Infrastructure Task Detection

**User**: "Create a GitHub Actions pipeline for deploying the Lambda function"

**Assistant Response**:
```
## Persona Switch Recommended

**Current Persona**: HLD Architect
**Suggested Persona**: DevOps Engineer
**Reason**: Detected "GitHub Actions" and "deploy" keywords
**Confidence**: High

**Task Detected**: Create CI/CD pipeline for Lambda deployment

Would you like to switch to the **DevOps Engineer** persona?
- **Yes**: Switch and continue with pipeline creation
- **No**: Stay with HLD Architect
```

### Example 2: Research Task Detection

**User**: "Research best practices for API versioning and provide evidence-based recommendations"

**Assistant Response**:
```
## Persona Switch Recommended

**Current Persona**: Project Manager
**Suggested Persona**: Researcher
**Reason**: Detected "research" and "evidence-based" keywords
**Confidence**: High

**Task Detected**: Evidence-based research on API versioning

Would you like to switch to the **Researcher** persona?
- **Yes**: Switch and begin research
- **No**: Stay with Project Manager
```

---

## Configuration Options

### Skill Configuration

```yaml
# persona_switching_config.yaml

enabled: true

# Require user approval for all switches
require_approval: true

# Minimum confidence level for suggestions
min_confidence: medium  # low | medium | high

# Show switch suggestions even if confidence is low
show_low_confidence: false

# Personas that can trigger automatic detection
detectable_personas:
  - HLD Architect
  - LLD Architect
  - DevOps Engineer
  - Researcher
  - Project Manager
  - Agent Builder

# Cooldown between switch suggestions (prevents spam)
switch_cooldown_minutes: 5
```

---

## Best Practices

1. **Always Request Approval**: Never switch without user consent
2. **Explain the Switch**: Clearly state why the switch is recommended
3. **Preserve Context**: Maintain conversation history across switches
4. **Quick Switches**: Make the switch process seamless
5. **Easy Revert**: Allow users to switch back easily
6. **Track Switches**: Log persona changes for audit trail

---

## Limitations

- Cannot detect complex multi-persona tasks (may require manual selection)
- Keyword-based detection may have false positives
- Context preservation has limits in very long conversations
- Some tasks may benefit from multiple personas sequentially

---

## Related Skills

- **Project Planning Skill**: For multi-stage project orchestration
- **HLD Skill**: For high-level design document creation
- **LLD Skill**: For low-level design document creation

---

**Skill Status**: Active
**Requires User Approval**: Yes (Always)
