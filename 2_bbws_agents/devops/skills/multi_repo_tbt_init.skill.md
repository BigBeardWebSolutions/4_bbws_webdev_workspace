# Multi-Repo TBT Initialization Skill

**Version**: 1.0
**Created**: 2024-12-17
**Extracted From**: Multi-repository TBT setup session

---

## Purpose

Initialize Turn-by-Turn (TBT) workflow mechanism across multiple related repositories in a single operation, ensuring consistent project structure and root CLAUDE.md inheritance.

---

## Trigger Conditions

### When to Use
- Setting up TBT workflow across a new multi-repo project
- Standardizing existing repos to TBT compliance
- Onboarding repositories to agentic workflow standards
- Ensuring consistent `.claude/` and `logs/` structure across repos

### User Invocation Examples
- "Initialize TBT across all repos"
- "Set up TBT for all 2_bbws_* repositories"
- "Standardize repos with TBT workflow"

---

## Input Requirements

**Required**:
- List of repository paths to initialize
- Path to root CLAUDE.md (parent directory)

**Optional**:
- Custom CLAUDE.md content per repo
- Additional folders to create beyond standard structure

**Preconditions**:
- All target repos must exist
- Root CLAUDE.md must exist at parent level
- Git access to all repositories

---

## Workflow

### Step 1: Discover Repositories
```
1. List all target repositories
2. Verify each repo exists and is a git repository
3. Check for existing CLAUDE.md files
4. Report discovery results
```

### Step 2: Read Existing CLAUDE.md Files
```
For each repository:
1. Read current CLAUDE.md (if exists)
2. Identify existing content to preserve
3. Check for root reference ({{include:../CLAUDE.md}})
4. Note gaps in TBT structure
```

### Step 3: Plan Updates
```
Create plan showing for each repo:
- CLAUDE.md changes (add root reference if missing)
- Folders to create (.claude/commands/, logs/)
- Files to add (.gitkeep files)

Display plan and WAIT for user approval
```

### Step 4: Update CLAUDE.md Files
```
For each repository:
1. Add/update Related Repositories section
2. Add Root Workflow Inheritance section:

   ## Root Workflow Inheritance

   This project inherits TBT mechanism and all workflow standards
   from the parent CLAUDE.md:

   {{include:../CLAUDE.md}}

3. Preserve existing project-specific content
```

### Step 5: Create TBT Directory Structure
```
For each repository, create:
├── .claude/
│   └── commands/
│       └── .gitkeep
└── logs/
    └── .gitkeep
```

### Step 6: Commit Changes
```
For each repository:
1. Stage all changes (git add -A)
2. Commit with standardized message:

   chore: add TBT mechanism and root CLAUDE.md reference

   - Add root workflow inheritance {{include:../CLAUDE.md}}
   - Add .claude/commands/ directory
   - Add logs/ directory for TBT session tracking
   - Update related repositories list

3. Report commit hash
```

### Step 7: Push (Optional)
```
If user approves:
1. Push each repo to origin/main
2. Report push results
3. Summarize all repos pushed
```

---

## Output Specifications

### Per-Repository Changes
| Item | Description |
|------|-------------|
| CLAUDE.md | Updated with root reference |
| .claude/commands/ | Created for custom slash commands |
| logs/ | Created for TBT session tracking |
| Commit | Standardized commit message |

### Summary Report
```
| Repository | Commit | Changes |
|------------|--------|---------|
| repo_1     | abc123 | CLAUDE.md + .claude/ + logs/ |
| repo_2     | def456 | CLAUDE.md + .claude/ + logs/ |
...
```

---

## Decision Logic

### If CLAUDE.md Already Has Root Reference
- Skip adding root reference
- Still create missing directories
- Update Related Repositories if needed

### If .claude/ Already Exists
- Preserve existing content
- Only add commands/ if missing
- Don't overwrite existing files

### If logs/ Already Exists
- Preserve existing logs
- Don't overwrite

### If Repo Has Uncommitted Changes
- Warn user about existing changes
- Ask whether to proceed or skip repo
- Never force overwrite user work

---

## Error Handling

### Repository Not Found
```
If: Target repo path doesn't exist
Then:
  - Log warning
  - Skip repo
  - Continue with remaining repos
  - Report skipped repos in summary
```

### Git Errors
```
If: Git operation fails
Then:
  - Log error details
  - Report which repo failed
  - Ask user how to proceed (retry/skip/abort)
```

### Permission Denied
```
If: Cannot write to repo
Then:
  - Log permission error
  - Skip repo
  - Suggest checking file permissions
```

---

## Success Criteria

Initialization succeeds when:

1. **All repos updated**: CLAUDE.md has root reference
2. **Structure created**: .claude/commands/ and logs/ exist
3. **Commits made**: Each repo has TBT init commit
4. **No data loss**: Existing content preserved
5. **Summary provided**: Clear report of all changes

---

## Usage Example

### Input
```
Repositories:
- /path/to/2_bbws_docs
- /path/to/2_bbws_ecs_terraform
- /path/to/2_bbws_ecs_operations
- /path/to/2_bbws_tenant_provisioner

Root CLAUDE.md: /path/to/CLAUDE.md
```

### Processing
```
1. Discover: Found 4 repositories
2. Read: 4 have CLAUDE.md, 0 have root reference
3. Plan: Update 4 CLAUDE.md, create 8 directories
4. [User approves]
5. Update: Add root reference to all
6. Create: .claude/commands/ and logs/ in all
7. Commit: 4 commits created
8. [User approves push]
9. Push: 4 repos pushed
```

### Output
```
| Repository              | Commit  | Status |
|-------------------------|---------|--------|
| 2_bbws_docs             | abc123  | ✅ Pushed |
| 2_bbws_ecs_terraform    | def456  | ✅ Pushed |
| 2_bbws_ecs_operations   | ghi789  | ✅ Pushed |
| 2_bbws_tenant_provisioner| jkl012 | ✅ Pushed |

All 4 repositories initialized with TBT workflow.
```

---

## Commit Message Template

```
chore: add TBT mechanism and root CLAUDE.md reference

- Add root workflow inheritance {{include:../CLAUDE.md}}
- Add .claude/commands/ directory for custom slash commands
- Add logs/ directory for TBT session tracking
- Update related repositories list

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
```

---

## Related Skills

- Agent Folder Restructuring
- Continuous Self Improvement
- Repository Management (DevOps Agent)

---

## Version History

- **v1.0** (2024-12-17): Initial skill extracted from multi-repo TBT session
