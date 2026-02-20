# Plan: Separate Agents into Individual Repositories

**Created**: 2024-12-17
**Status**: AWAITING APPROVAL
**Principle**: Single Responsibility - Each agent in its own repo

---

## Current State

**Repository**: `2_bbws_agents`
**Contains**: 8 agents + 5 spec files + utility scripts

### Current Agent Inventory

| Agent | Files | Purpose |
|-------|-------|---------|
| ECS Cluster Manager | `ecs_cluster_manager.md`, `agent_spec.md` | Infrastructure provisioning |
| Tenant Manager | `tenant_manager.md`, `tenant_manager_agent_spec.md` | Tenant lifecycle |
| Content Manager | `content_manager.md`, `content_manager_agent_spec.md` | WordPress content |
| Backup Manager | `backup_manager_agent.md` | Backup operations |
| DR Manager | `dr_manager_agent.md` | Disaster recovery |
| Monitoring Agent | `monitoring_agent.md` | Infrastructure monitoring |
| Cost Monitoring | `cost_monitoring_agent.md` | Cost tracking |
| DevOps Agent | `DevOps_agent.md`, `devops_agent_spec.md` | CI/CD automation |

**Shared Spec**: `aws_management_agents_spec.md` (covers Backup, DR, Cost, Monitoring)

---

## Proposed New Structure

### New Repositories (8 total)

| New Repo | Agent | Related Spec |
|----------|-------|--------------|
| `2_bbws_agent_ecs_cluster` | ecs_cluster_manager.md | agent_spec.md |
| `2_bbws_agent_tenant` | tenant_manager.md | tenant_manager_agent_spec.md |
| `2_bbws_agent_content` | content_manager.md | content_manager_agent_spec.md |
| `2_bbws_agent_backup` | backup_manager_agent.md | (from aws_management_agents_spec.md) |
| `2_bbws_agent_dr` | dr_manager_agent.md | (from aws_management_agents_spec.md) |
| `2_bbws_agent_monitoring` | monitoring_agent.md | (from aws_management_agents_spec.md) |
| `2_bbws_agent_cost` | cost_monitoring_agent.md | (from aws_management_agents_spec.md) |
| `2_bbws_agent_devops` | DevOps_agent.md | devops_agent_spec.md |

### Standard Repo Structure (each agent)

```
2_bbws_agent_{name}/
├── CLAUDE.md              # Project instructions + root reference
├── README.md              # Agent overview and usage
├── agent.md               # Main agent definition
├── agent_spec.md          # Detailed specification (if applicable)
├── .claude/
│   └── commands/          # Custom slash commands for this agent
├── logs/                  # TBT session logs
└── utils/                 # Agent-specific utilities (if needed)
```

### What Happens to `2_bbws_agents`

**Option A**: Archive/delete the repo (agents moved to new repos)
**Option B**: Keep as an index/orchestrator repo that references all agent repos
**Option C**: Rename to `2_bbws_agent_utils` and keep only shared utilities

**Recommendation**: Option B - Keep as orchestrator with:
- Index of all agent repos
- Shared utility scripts (`utils/`)
- Cross-agent documentation

---

## Utility Scripts Distribution

Current utilities in `2_bbws_agents/utils/`:

| Script | Target Repo(s) |
|--------|----------------|
| `list_databases.sh` | `2_bbws_agent_ecs_cluster`, `2_bbws_agent_tenant` |
| `query_database.sh` | `2_bbws_agent_ecs_cluster`, `2_bbws_agent_tenant` |
| `create_tenant_database.sh` | `2_bbws_agent_tenant` |
| `get_tenant_credentials.sh` | `2_bbws_agent_tenant` |
| `get_tenant_urls.sh` | `2_bbws_agent_tenant` |
| `verify_tenant_isolation.sh` | `2_bbws_agent_tenant`, `2_bbws_ecs_tests` |
| `list_cognito_pools.sh` | `2_bbws_agent_tenant` |
| `get_cognito_credentials.sh` | `2_bbws_agent_tenant` |
| `verify_cognito_setup.sh` | `2_bbws_agent_tenant` |
| `delete_cognito_pool.sh` | `2_bbws_agent_tenant` |

**Decision**: Keep utilities in `2_bbws_agents` (as shared resource) or copy to relevant agent repos?

---

## Implementation Steps

### Phase 1: Create New Repos (GitHub)
1. Create 8 new repositories on GitHub
2. Initialize with standard structure
3. Add CLAUDE.md with root reference

### Phase 2: Migrate Agent Files
1. Copy agent definition to new repo
2. Copy related spec file to new repo
3. Update internal references
4. Add agent-specific utilities

### Phase 3: Update Cross-References
1. Update `2_bbws_agents` to reference new repos
2. Update all sibling repos to include new agent repos in Related Repositories
3. Update documentation

### Phase 4: Cleanup
1. Decide fate of `2_bbws_agents` (archive/orchestrator/utils)
2. Remove migrated files from original repo
3. Update README

---

## Questions for Approval

1. **Repo naming**: `2_bbws_agent_{name}` or `2_bbws_{name}_agent`?
2. **Utilities**: Keep in central repo or distribute to agent repos?
3. **Original repo**: Archive, keep as orchestrator, or rename to utils?
4. **GitHub**: Create repos manually or should I script it?

---

## Risk Assessment

| Risk | Mitigation |
|------|------------|
| Breaking existing references | Update all cross-references before removing old files |
| Lost utility scripts | Keep backup in original repo until migration verified |
| Confusion during transition | Clear documentation and phased approach |

---

## Approval Required

Please confirm:
1. Proceed with 8 new agent repos?
2. Preferred naming convention?
3. Fate of original `2_bbws_agents` repo?
4. Utility script distribution approach?
