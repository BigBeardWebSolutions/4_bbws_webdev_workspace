# Agentic Architect

A collection of AI agents specialized in software architecture documentation, including High-Level Design (HLD) and Low-Level Design (LLD) generation, plus an agent builder for creating new specialized agents.

## Repository Structure

```
agentic_architect/
├── HLD_Architect_Agent.md              # HLD generation agent
├── LLD_Architect_Agent.md              # LLD generation agent
├── Agent_Builder_Agent.md              # Agent creation tool
├── skills/                             # Shared skills
│   ├── hateoas_relational_design.skill.md
│   ├── hld_lld_naming_convention.skill.md
│   └── repo_microservice_mapping.skill.md
├── CLAUDE.md                           # Project instructions
└── README.md                           # This file
```

## Agents

### HLD Architect (`HLD_Architect_Agent.md`)

Specializes in creating High-Level Design documents for cloud-based solutions:
- Guided requirements gathering through structured interviews
- Four-layer architecture patterns (Frontend, Middleware, Backend, Management)
- UML stereotyped components
- AWS/Azure/GCP service selection
- Cost estimation and security considerations

### LLD Architect (`LLD_Architect_Agent.md`)

Specializes in creating Low-Level Design documents from HLDs:
- Detailed component specifications
- API endpoint definitions with request/response schemas
- DynamoDB schema design (PK, SK, GSIs)
- Lambda function specifications
- Sequence diagrams and data flows

### Agent Builder (`Agent_Builder_Agent.md`)

A meta-agent for creating new specialized agents:
- Parses agent specifications (10-question format)
- Generates TBT-compliant agent definition files
- Includes patient behavior and planning-first approach
- Calculates ATSQ (Agentic Time Saving Quotient)

## Skills

Shared skills available to all agents:

| Skill | Purpose |
|-------|---------|
| `hateoas_relational_design.skill.md` | Hierarchical API structures reflecting entity relationships |
| `hld_lld_naming_convention.skill.md` | HLD-LLD prefix naming (3.1 → 3.1.1, 3.1.2, ...) |
| `repo_microservice_mapping.skill.md` | Repository naming and standard repo organization |

## Naming Conventions

### HLD-LLD Naming

```
HLD: [phase].[sub-phase]_HLD_[Name].md
LLD: [phase].[sub-phase].[lld-number]_LLD_[Name].md

Example:
3.1_HLD_Customer_Portal_Public.md
├── 3.1.1_LLD_Frontend_Architecture.md
├── 3.1.2_LLD_Auth_Lambda.md
├── 3.1.3_LLD_Marketing_Lambda.md
└── 3.1.4_LLD_Cart_Lambda.md
```

### Repository Naming

```
[phase]_[project]_[component]

Examples:
2_bbws_auth_lambda
2_bbws_web_public
2_bbws_docs
```

## Usage

### Creating an HLD

1. Load the HLD Architect agent
2. Provide business context and requirements
3. Follow guided interview through 6 phases
4. Review staged artifacts
5. Finalize HLD document

### Creating LLDs from HLD

1. Load the LLD Architect agent
2. Reference parent HLD
3. Generate LLDs for each component
4. Apply HLD-LLD naming convention

### Creating a New Agent

1. Load the Agent Builder
2. Complete the 10-question agent_spec.md template
3. Generate agent definition file
4. Review and refine

## Related Repositories

| Repository | Purpose |
|------------|---------|
| `2_bbws_docs` | Generated HLDs and LLDs |
| `2_bbws_agents` | Operational agents (DevOps, Monitoring, etc.) |

## License

Internal use only - Big Beard Web Solutions
