# Plan: Update Agent Definitions to New Repository Structure

**Created**: 2024-12-17
**Status**: STAGED FOR APPROVAL
**Author**: Claude Agent (TBT Mode)

---

## Executive Summary

The agent definitions in `2_bbws_agents/agents/` contain outdated path references that don't align with the actual multi-repository structure. This plan proposes updates to align all agents with the correct cross-repo references.

---

## Current Repository Structure (Actual)

```
agentic_work/
├── 2_bbws_agents/              # THIS REPO - Agent definitions + utility scripts
│   ├── agents/                 # 13 agent definition files
│   ├── scripts/                # Database & Cognito utility scripts
│   └── logs/                   # TBT session logs
│
├── 2_bbws_ecs_terraform/       # Infrastructure as Code
│   └── terraform/              # All *.tf files (vpc, ecs, rds, etc.)
│
├── 2_bbws_tenant_provisioner/  # Tenant management CLI
│   ├── src/                    # Python CLI source
│   └── tests/                  # Unit tests
│
├── 2_bbws_wordpress_container/ # WordPress Docker image
│   ├── docker/                 # Dockerfile, configs
│   └── scripts/                # Container build scripts
│
├── 2_bbws_ecs_operations/      # Operational artifacts
│   ├── alerts/                 # Alert definitions
│   ├── dashboards/             # CloudWatch dashboards
│   ├── monitoring/             # Monitoring configs
│   └── runbooks/               # Operational runbooks
│
├── 2_bbws_ecs_tests/           # Integration tests
│   └── tests/                  # Test suites
│
└── 2_bbws_docs/                # Documentation
    ├── HLDs/                   # High-Level Designs
    ├── LLDs/                   # Low-Level Designs
    ├── specs/                  # Specifications
    └── training/               # Training materials
```

---

## Gap Analysis by Agent

### 1. ECS Cluster Manager (`ecs_cluster_manager.md`)
| Current Reference | Issue | Correct Reference |
|-------------------|-------|-------------------|
| `terraform/*.tf` | Wrong location | `../2_bbws_ecs_terraform/terraform/*.tf` |
| `utils/list_databases.sh` | Wrong path | `scripts/list_databases.sh` |
| `utils/query_database.sh` | Wrong path | `scripts/query_database.sh` |
| `utils/verify_tenant_isolation.sh` | Wrong path | `scripts/verify_tenant_isolation.sh` |

### 2. Tenant Manager (`tenant_manager.md`)
| Current Reference | Issue | Correct Reference |
|-------------------|-------|-------------------|
| `provision_cognito.py` | No path specified | `../2_bbws_tenant_provisioner/src/provision_cognito.py` |
| Cognito scripts | Missing reference | Add `scripts/` references for Cognito operations |

### 3. Content Manager (`content_manager.md`)
| Current Reference | Issue | Correct Reference |
|-------------------|-------|-------------------|
| WordPress Docker paths | Needs context | Add `../2_bbws_wordpress_container/` references |
| No test references | Missing | Add `../2_bbws_ecs_tests/` reference |

### 4. Backup Manager (`backup_manager_agent.md`)
| Current Reference | Issue | Correct Reference |
|-------------------|-------|-------------------|
| `.claude/utils/aws_mgmt/backup_cli.py` | **DOES NOT EXIST** | Create in `scripts/` or remove |
| Runbook references | Missing | `../2_bbws_ecs_operations/runbooks/` |

### 5. DR Manager (`dr_manager_agent.md`)
| Current Reference | Issue | Correct Reference |
|-------------------|-------|-------------------|
| `.claude/utils/aws_mgmt/dr_cli.py` | **DOES NOT EXIST** | Create in `scripts/` or remove |
| Runbook references | Missing | `../2_bbws_ecs_operations/runbooks/` |

### 6. Cost Monitoring Agent (`cost_monitoring_agent.md`)
| Current Reference | Issue | Correct Reference |
|-------------------|-------|-------------------|
| `.claude/utils/aws_mgmt/cost_cli.py` | **DOES NOT EXIST** | Create in `scripts/` or remove |

### 7. Monitoring Agent (`monitoring_agent.md`)
| Current Reference | Issue | Correct Reference |
|-------------------|-------|-------------------|
| `.claude/utils/aws_mgmt/monitoring_cli.py` | **DOES NOT EXIST** | Create in `scripts/` or remove |
| Dashboard references | Missing | `../2_bbws_ecs_operations/dashboards/` |
| Alert references | Missing | `../2_bbws_ecs_operations/alerts/` |

### 8. DevOps Agent (`DevOps_agent.md`)
| Current Reference | Issue | Correct Reference |
|-------------------|-------|-------------------|
| `.claude/utils/devops/repo_cli.py` | **DOES NOT EXIST** | Create in `scripts/devops/` or remove |
| `.claude/utils/devops/lld_parser.py` | **DOES NOT EXIST** | Create or reference `../2_bbws_docs/` |
| `.claude/utils/devops/code_gen.py` | **DOES NOT EXIST** | Create in `scripts/devops/` or remove |
| `.claude/utils/devops/pipeline_cli.py` | **DOES NOT EXIST** | Create in `scripts/devops/` or remove |
| `.claude/utils/devops/terraform_cli.py` | **DOES NOT EXIST** | Create or reference `../2_bbws_ecs_terraform/` |
| `.claude/utils/devops/deploy_cli.py` | **DOES NOT EXIST** | Create in `scripts/devops/` or remove |
| LLD references | Correct concept | `../2_bbws_docs/LLDs/` |

---

## Proposed Changes

### Phase 1: Update Cross-Repo References (Low Risk)
Update all agents to use correct relative paths to sibling repositories.

**Files to modify:**
- `agents/ecs_cluster_manager.md`
- `agents/tenant_manager.md`
- `agents/content_manager.md`
- `agents/backup_manager_agent.md`
- `agents/dr_manager_agent.md`
- `agents/monitoring_agent.md`
- `agents/DevOps_agent.md`

### Phase 2: Fix Internal Path References (Low Risk)
Update references from `utils/` to `scripts/` to match actual structure.

### Phase 3: Add Repository Context Section (Enhancement)
Add a standardized "Related Repositories" section to each agent with correct paths:

```markdown
## Related Repositories

| Repository | Path | Purpose |
|------------|------|---------|
| Infrastructure | `../2_bbws_ecs_terraform/` | Terraform IaC |
| Tenant Provisioner | `../2_bbws_tenant_provisioner/` | CLI tools |
| WordPress Container | `../2_bbws_wordpress_container/` | Docker image |
| Operations | `../2_bbws_ecs_operations/` | Dashboards, alerts, runbooks |
| Tests | `../2_bbws_ecs_tests/` | Integration tests |
| Documentation | `../2_bbws_docs/` | HLDs, LLDs, specs |
```

### Phase 4: Remove/Flag Non-Existent CLI References (Requires Decision)

**CLI utilities referenced but NOT implemented:**
- `backup_cli.py`
- `dr_cli.py`
- `cost_cli.py`
- `monitoring_cli.py`
- `repo_cli.py`
- `lld_parser.py`
- `code_gen.py`
- `pipeline_cli.py`
- `terraform_cli.py`
- `deploy_cli.py`
- `security_cli.py`
- `release_cli.py`

**Options:**
1. **Option A**: Remove references (agents become documentation-only)
2. **Option B**: Mark as "TODO: Implement" in agents
3. **Option C**: Create placeholder scripts with stubs

---

## Risk Assessment

| Phase | Risk Level | Impact | Mitigation |
|-------|------------|--------|------------|
| Phase 1 | Low | Documentation only | Review before commit |
| Phase 2 | Low | Documentation only | Review before commit |
| Phase 3 | Low | Enhancement | Consistent format |
| Phase 4 | Medium | Functionality change | Requires decision |

---

## Implementation Checklist

- [ ] Review and approve this plan
- [ ] Phase 1: Update cross-repo references
- [ ] Phase 2: Fix internal path references
- [ ] Phase 3: Add Related Repositories section
- [ ] Phase 4: Handle non-existent CLI references (pending decision)
- [ ] Update spec files (`*_spec.md`) to match
- [ ] Update README.md with new structure
- [ ] Commit changes with descriptive message

---

## Decision Required

**For Phase 4**, please choose one option:

| Option | Description | Recommendation |
|--------|-------------|----------------|
| **A** | Remove CLI references | Not recommended - loses intent |
| **B** | Mark as "TODO: Implement" | **Recommended** - preserves roadmap |
| **C** | Create stub scripts | More work, but executable |

---

## Approval

**Awaiting your approval to proceed with implementation.**

Please confirm:
1. Approval to proceed with Phases 1-3
2. Decision on Phase 4 (Option A, B, or C)
3. Any additional requirements or modifications
