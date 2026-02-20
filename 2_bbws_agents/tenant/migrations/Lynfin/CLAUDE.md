# Lynfin - WordPress Migration Project

## Project Purpose

WordPress migration project to move the Lynfin website from Xneelo hosting to the BBWS multi-tenant AWS hosting platform.

## Source Data

| Item | Location | Region |
|------|----------|--------|
| S3 Export | s3://wordpress-migration-temp-20250903/Lynfin/ | eu-west-1 |

## Target Environments

| Environment | Domain | Status |
|-------------|--------|--------|
| DEV | lynfin.wpdev.kimmyai.io | Pending |
| SIT | lynfin.wpsit.kimmyai.io | Pending |
| PROD | TBD (custom domain) | Future |

## Project-Specific Instructions

- Use **default AWS CLI profile** for all operations (CRITICAL: Do not specify --profile flags)
- Follow the migration runbook: `../runbooks/wordpress_migration_playbook_automated.md`
- Reference ECS exec alternatives: `../ecs_exec_alternatives_analysis.md`
- Test emails redirect to: `tebogo@bigbeard.co.za`
- Use bastion host for all long-running operations (not ECS exec)

## AWS Configuration

| Setting | Value |
|---------|-------|
| Profile | default (DO NOT change) |
| Region | eu-west-1 |
| S3 Bucket | wordpress-migration-temp-20250903 |

## Current Project Plan

Location: `.claude/plans/project-plan-1/project_plan.md`

## Folder Structure

```
Lynfin/
├── .claude/                    # TBT workflow files
│   ├── logs/history.log        # Command history
│   ├── plans/project-plan-1/   # Migration plans
│   ├── snapshots/              # Pre-change snapshots
│   └── staging/                # Intermediate files
├── site/                       # Placeholder for site-specific artifacts
├── migration-artifacts/        # Downloaded/processed files
└── CLAUDE.md                   # This file
```

## Root Workflow Inheritance

This project inherits TBT mechanism and all workflow standards from the parent CLAUDE.md:

{{include:../../CLAUDE.md}}
