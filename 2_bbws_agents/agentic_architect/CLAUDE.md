# Agentic Architect - Project Instructions

This repository contains AI agents specialized in software architecture, development, and operations.

## Entry Point

**Agentic_Architect.md** - Abstract orchestrator that can operate in multiple personas.

## Personas (Root Agents)

| Persona | Agent File | Purpose |
|---------|------------|---------|
| HLD Architect | HLD_Architect_Agent.md | High-Level Design document generation |
| LLD Architect | LLD_Architect_Agent.md | Low-Level Design document generation |
| Agent Builder | Agent_Builder_Agent.md | Create new specialized agents |
| DevOps Engineer | DevOps_Engineer_Agent.md | CI/CD, infrastructure, deployments |
| Project Manager | Agentic_Project_Manager.md | Multi-stage project orchestration and coordination |
| Researcher | Researcher_Agent.md | Deep evidence-based research |

## Developer Agents

| Agent | Location | Purpose |
|-------|----------|---------|
| Abstract Developer | Abstract_Developer.md | Base (SOLID, TDD, BDD, DDD) |
| Python AWS Developer | Python_AWS_Developer_Agent.md | Python + Lambda + Powertools |
| Java AWS Developer | Java_AWS_Developer_Agent.md | Java 21 + SnapStart + CRaC |

Developer agents extend Abstract_Developer via `{{include:}}` directive.

## Skills

Shared knowledge modules in `skills/`:

| Skill | Purpose |
|-------|---------|
| HATEOAS_Relational_Design.skill.md | Hierarchical HATEOAS API design |
| HLD_LLD_Naming_Convention.skill.md | HLD-LLD prefix naming convention |
| Repo_Microservice_Mapping.skill.md | Repository naming and organization |
| Development_Best_Practices.skill.md | SOLID, TDD, BDD, DDD, design patterns |
| DynamoDB_Single_Table.skill.md | DynamoDB single table design patterns |
| AWS_Python_Dev.skill.md | Python Lambda, Powertools, boto3 |
| AWS_Java_Dev.skill.md | Java Lambda, SnapStart, SDK v2 |

## Key Conventions

### HLD-LLD Naming
```
HLD: [phase].[sub-phase]_HLD_[Name].md
LLD: [phase].[sub-phase].[lld-number]_LLD_[Name].md
```

### Repository Naming
```
[phase]_[project]_[component]
Example: 2_bbws_auth_lambda
```

### Standard Repos (Always Include)
- `{prefix}_docs` - HLDs, LLDs, ADRs
- `{prefix}_operations` - Dashboards, alerts, SCPs
- `{prefix}_agents` - AI agents, automation
- `{prefix}_common` - Shared libraries
- `{prefix}_tests` - E2E and integration tests

## Workflow Guidelines

### TBT Compliance
1. **Logging**: Log commands in `.claude/logs/history.log`
2. **Planning**: Create plans in `.claude/plans/`
3. **Staging**: Use `.claude/staging/staging_X/` for intermediate artifacts
4. **Versioning**: Stage files with version numbers (v1, v2, v3...)
5. **Review**: Present staged content for user review before finalizing
6. **Never**: Use /tmp or OS temporary directories

### Development Workflow
1. Requirements → BDD scenarios (Gherkin)
2. TDD: Red → Green → Refactor
3. DDD for complex domains
4. Stage for review
5. Deploy to DEV → SIT → PROD

## Persona Selection Guide

| Task | Load Agent |
|------|------------|
| Design new cloud solution | HLD_Architect_Agent.md |
| Detail HLD component | LLD_Architect_Agent.md |
| Create new agent | Agent_Builder_Agent.md |
| Deploy infrastructure | DevOps_Engineer_Agent.md |
| Orchestrate complex project | Agentic_Project_Manager.md |
| Research question | Researcher_Agent.md |
| Python Lambda code | Python_AWS_Developer_Agent.md |
| Java Lambda code | Java_AWS_Developer_Agent.md |

## Core Principles

All agents follow:
- **Patient behavior**: Never eager, wait for user direction
- **Planning-first**: Create plans, await approval
- **Staging**: Intermediate artifacts in `.claude/staging/`
- **Quality**: Completeness, clarity, traceability
