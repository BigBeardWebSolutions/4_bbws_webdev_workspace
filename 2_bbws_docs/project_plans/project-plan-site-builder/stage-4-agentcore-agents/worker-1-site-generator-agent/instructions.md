# Worker Instructions: Site Generator Agent

**Worker ID**: worker-1-site-generator-agent
**Stage**: Stage 4 - AgentCore Agent Development
**Project**: project-plan-site-builder

---

## Task

Create the Site Generator orchestrator agent that coordinates page generation using sub-agents (Outliner, Theme Selector, Layout) and produces final HTML/CSS output.

---

## Inputs

**Reference Documents**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/HLDs/BBSW_Site_Builder_HLD_v3.md` (Section 7: AI Agents)
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/3.1.2_LLD_Site_Builder_Generation_API.md`

**Dependencies**:
- AgentCore infrastructure from Stage 2
- Agent personas bucket from Stage 2

---

## Deliverables

Create the following files:

### 1. Agent Definition (agent.yaml)

```yaml
name: site-generator
displayName: Site Generator Agent
description: Orchestrates landing page generation using AI
region: eu-west-1

runtime:
  model: anthropic.claude-sonnet-4-5-20251101
  temperature: 0.7
  maxTokens: 4096

instructions: |
  You are the Site Generator agent responsible for creating
  professional landing pages. You coordinate with sub-agents
  to gather structure, theme, and layout information before
  generating the final HTML and CSS.

  Your workflow:
  1. Analyze user requirements
  2. Invoke Outliner for page structure
  3. Invoke Theme Selector for colors/fonts
  4. Invoke Layout for responsive design
  5. Generate final HTML + CSS
  6. Validate output against brand guidelines

tools:
  - name: invoke_outliner
    description: Generate page structure
  - name: invoke_theme_selector
    description: Get theme suggestions
  - name: invoke_layout
    description: Generate responsive layout
  - name: save_to_s3
    description: Save generated content

memory:
  type: session
  ttlMinutes: 30

collaborators:
  - outliner-agent
  - theme-selector-agent
  - layout-agent
```

### 2. Prompt Template (prompts/site-generator.md)

```markdown
# Site Generator Agent Prompt

## Role
You are an expert web designer and developer specializing in
creating high-converting landing pages.

## Context
You have access to the following user information:
- Brand Name: {{brand_name}}
- Industry: {{industry}}
- Primary Color: {{primary_color}}
- Target Audience: {{target_audience}}

## Task
Create a complete landing page based on the user's requirements.

## Requirements
{{user_requirements}}

## Sub-Agent Results
- Page Structure: {{outliner_result}}
- Theme: {{theme_result}}
- Layout: {{layout_result}}

## Output Format
Generate complete, valid HTML5 with inline Tailwind CSS classes.
Include responsive design for desktop, tablet, and mobile.
```

### 3. Tool Definitions (tools/invoke_outliner.py)

```python
from typing import Dict
import boto3

def invoke_outliner(requirements: str) -> Dict:
    """
    Invoke the Outliner agent to generate page structure.

    Args:
        requirements: User requirements text

    Returns:
        Page structure JSON
    """
    bedrock = boto3.client('bedrock-agent-runtime', region_name='eu-west-1')

    response = bedrock.invoke_agent(
        agentId='outliner-agent-id',
        agentAliasId='TSTALIASID',
        sessionId='session-id',
        inputText=requirements
    )

    return parse_response(response)
```

### 4. Cedar Policy (policies/site-generator.cedar)

```cedar
// Allow Site Generator to invoke sub-agents
permit (
    principal == AgentCore::Agent::"site-generator",
    action == Action::"invokeAgent",
    resource in [
        AgentCore::Agent::"outliner-agent",
        AgentCore::Agent::"theme-selector-agent",
        AgentCore::Agent::"layout-agent"
    ]
);

// Tenant isolation for S3 access
permit (
    principal == AgentCore::Agent::"site-generator",
    action == Action::"s3:PutObject",
    resource
)
when {
    resource.key starts_with context.tenantId
};
```

### 5. Evaluation Definition (evaluations/site-generator-eval.yaml)

```yaml
name: site-generator-evaluation
description: Evaluate Site Generator output quality

testCases:
  - name: basic-landing-page
    input: "Create a landing page for a tech startup"
    expectedBehavior:
      - containsHtml: true
      - hasResponsiveDesign: true
      - brandScoreMin: 8.0

  - name: e-commerce-product
    input: "Create a product page for running shoes"
    expectedBehavior:
      - containsHtml: true
      - hasCTA: true
      - hasProductSection: true

metrics:
  - name: generation_time
    threshold: 60s
  - name: brand_score
    threshold: 8.0
  - name: accessibility_score
    threshold: 80
```

### 6. Memory Configuration (memory/config.yaml)

```yaml
memoryType: session
sessionTtl: 30m
maxSessions: 1000
storage:
  type: dynamodb
  table: bbws-agent-sessions-${environment}

contextWindow:
  includeLastN: 10
  maxTokens: 8000
```

---

## Expected Output

```
output/
├── agent.yaml              # Agent definition
├── prompts/
│   └── site-generator.md   # Prompt template
├── tools/
│   ├── invoke_outliner.py
│   ├── invoke_theme.py
│   ├── invoke_layout.py
│   └── save_to_s3.py
├── policies/
│   └── site-generator.cedar
├── evaluations/
│   └── site-generator-eval.yaml
├── memory/
│   └── config.yaml
└── README.md
```

---

## Success Criteria

- [ ] Agent definition created with correct model config
- [ ] Prompt template with all variables
- [ ] Tool definitions for sub-agent invocation
- [ ] Cedar policy for tenant isolation
- [ ] Evaluation test cases defined
- [ ] Memory configuration set
- [ ] Agent deploys successfully to AgentCore
- [ ] Sample generation produces valid HTML/CSS
- [ ] Brand score >= 8.0 on test generations

---

## Execution Steps

1. Read HLD Section 7 for agent requirements
2. Create agent.yaml with model configuration
3. Create prompt template with variables
4. Implement tool functions for sub-agents
5. Create Cedar policy for access control
6. Define evaluation test cases
7. Configure session memory
8. Deploy to AgentCore
9. Run evaluation tests
10. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-16
