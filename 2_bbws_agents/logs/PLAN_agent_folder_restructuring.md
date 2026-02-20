# Plan: Restructure Agents into Separate Folders

**Created**: 2024-12-17
**Status**: AWAITING APPROVAL
**Principle**: Single Responsibility - Each agent in its own folder

---

## Current Structure

```
2_bbws_agents/
├── agents/                          # All agents mixed together
│   ├── agent_spec.md               # ECS cluster spec
│   ├── aws_management_agents_spec.md
│   ├── backup_manager_agent.md
│   ├── content_manager_agent_spec.md
│   ├── content_manager.md
│   ├── cost_monitoring_agent.md
│   ├── devops_agent_spec.md
│   ├── DevOps_agent.md
│   ├── dr_manager_agent.md
│   ├── ecs_cluster_manager.md
│   ├── monitoring_agent.md
│   ├── tenant_manager_agent_spec.md
│   └── tenant_manager.md
├── utils/
├── logs/
├── CLAUDE.md
└── README.md
```

---

## Proposed Structure

```
2_bbws_agents/
├── ecs_cluster/                     # Agent folder at root
│   ├── README.md
│   ├── agent.md                     # (from agents/ecs_cluster_manager.md)
│   ├── agent_spec.md                # (from agents/agent_spec.md)
│   └── skills/                      # Agent-specific skills
│       └── .gitkeep
│
├── tenant/                          # Agent folder at root
│   ├── README.md
│   ├── agent.md                     # (from agents/tenant_manager.md)
│   ├── agent_spec.md                # (from agents/tenant_manager_agent_spec.md)
│   └── skills/                      # Agent-specific skills
│       └── .gitkeep
│
├── content/                         # Agent folder at root
│   ├── README.md
│   ├── agent.md                     # (from agents/content_manager.md)
│   ├── agent_spec.md                # (from agents/content_manager_agent_spec.md)
│   └── skills/                      # Agent-specific skills
│       └── .gitkeep
│
├── backup/                          # Agent folder at root
│   ├── README.md
│   ├── agent.md                     # (from agents/backup_manager_agent.md)
│   ├── agent_spec.md                # (extracted from aws_management_agents_spec.md)
│   └── skills/                      # Agent-specific skills
│       └── .gitkeep
│
├── dr/                              # Agent folder at root
│   ├── README.md
│   ├── agent.md                     # (from agents/dr_manager_agent.md)
│   ├── agent_spec.md                # (extracted from aws_management_agents_spec.md)
│   └── skills/                      # Agent-specific skills
│       └── .gitkeep
│
├── monitoring/                      # Agent folder at root
│   ├── README.md
│   ├── agent.md                     # (from agents/monitoring_agent.md)
│   ├── agent_spec.md                # (extracted from aws_management_agents_spec.md)
│   └── skills/                      # Agent-specific skills
│       └── .gitkeep
│
├── cost/                            # Agent folder at root
│   ├── README.md
│   ├── agent.md                     # (from agents/cost_monitoring_agent.md)
│   ├── agent_spec.md                # (extracted from aws_management_agents_spec.md)
│   └── skills/                      # Agent-specific skills
│       └── .gitkeep
│
├── devops/                          # Agent folder at root
│   ├── README.md
│   ├── agent.md                     # (from agents/DevOps_agent.md)
│   ├── agent_spec.md                # (from agents/devops_agent_spec.md)
│   └── skills/                      # Agent-specific skills
│       └── .gitkeep
│
├── skills/                          # Shared skills (root level)
│   └── .gitkeep
│
├── utils/                           # Shared utilities (unchanged)
│   ├── list_databases.sh
│   ├── query_database.sh
│   └── ... (other scripts)
│
├── logs/                            # TBT session logs
├── .claude/
│   └── commands/
├── CLAUDE.md
└── README.md                        # Updated with new structure
```

**Note**: The `agents/` folder will be removed after migration.

---

## File Mapping

| Current File | New Location |
|--------------|--------------|
| `agents/ecs_cluster_manager.md` | `ecs_cluster/agent.md` |
| `agents/agent_spec.md` | `ecs_cluster/agent_spec.md` |
| `agents/tenant_manager.md` | `tenant/agent.md` |
| `agents/tenant_manager_agent_spec.md` | `tenant/agent_spec.md` |
| `agents/content_manager.md` | `content/agent.md` |
| `agents/content_manager_agent_spec.md` | `content/agent_spec.md` |
| `agents/backup_manager_agent.md` | `backup/agent.md` |
| `agents/dr_manager_agent.md` | `dr/agent.md` |
| `agents/monitoring_agent.md` | `monitoring/agent.md` |
| `agents/cost_monitoring_agent.md` | `cost/agent.md` |
| `agents/DevOps_agent.md` | `devops/agent.md` |
| `agents/devops_agent_spec.md` | `devops/agent_spec.md` |
| `agents/aws_management_agents_spec.md` | Split into backup/, dr/, monitoring/, cost/ |
| `agents/` folder | **DELETED** after migration |

---

## Each Agent Folder Contents

| File/Folder | Purpose |
|-------------|---------|
| `README.md` | Agent overview, quick reference |
| `agent.md` | Main agent definition (skills, workflows) |
| `agent_spec.md` | Detailed technical specification |
| `skills/` | Agent-specific skill definitions |

## Root Level Folders

| Folder | Purpose |
|--------|---------|
| `skills/` | Shared skills used by multiple agents |
| `utils/` | Shared utility scripts |
| `logs/` | TBT session logs |
| `.claude/commands/` | Custom slash commands |

---

## Implementation Steps

1. Create 8 agent subfolders under `agents/`
2. Move and rename agent files to new locations
3. Create README.md for each agent folder
4. Split `aws_management_agents_spec.md` into 4 separate specs
5. Update main README.md with new structure
6. Commit changes

---

## Approval Checklist

- [ ] Folder structure approved
- [ ] File naming convention approved (agent.md, agent_spec.md)
- [ ] Ready to implement

---

**Awaiting your approval to proceed.**
