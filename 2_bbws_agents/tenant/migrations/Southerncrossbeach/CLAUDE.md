# Southerncrossbeach - Project Overview

## Project Purpose

WordPress migration project to move the Southerncrossbeach website from Xneelo hosting to the BBWS multi-tenant AWS hosting platform.

## Source Data

| Item | Location | Size |
|------|----------|------|
| Database | s3://wordpress-migration-temp-20250903/Southerncrossbeach/wordpress-db-20260116_093724.sql | ~15MB |
| Files | s3://wordpress-migration-temp-20250903/Southerncrossbeach/wordpress-files-20260116_093724.tar.gz | ~269MB |
| Export Notes | s3://wordpress-migration-temp-20250903/Southerncrossbeach/EXPORT-NOTES-20260116_093724.txt | N/A |
| Checksums | s3://wordpress-migration-temp-20250903/Southerncrossbeach/CHECKSUMS-20260116_093724.txt | N/A |
| Final Package | s3://wordpress-migration-temp-20250903/Southerncrossbeach/exports-Southerncrossbeach-20260116_093724.tar.gz | ~271MB |

## Target Environments

| Environment | Domain | Status |
|-------------|--------|--------|
| DEV | southerncrossbeach.wpdev.kimmyai.io | Pending |
| SIT | southerncrossbeach.wpsit.kimmyai.io | Pending |
| PROD | TBD (custom domain) | Future |

## Project-Specific Instructions

- Use **default AWS CLI profile** for all operations
- Follow the migration runbook: `runbooks/wordpress_migration_playbook_automated.md`
- Review ECS alternatives: `ecs_exec_alternatives_analysis.md`
- Test emails redirect to: `tebogo@bigbeard.co.za`
- Use bastion host for all long-running operations (not ECS exec)

## Current Project Plan

Location: `.claude/plans/project-plan-1/project_plan.md`

## SSH Access (Source Server - Xneelo)

| Property | Value |
|----------|-------|
| Host | 197.221.12.211 |
| Port | 2222 |
| User | southvkzxk |

## Root Workflow Inheritance

This project inherits TBT mechanism and all workflow standards from the parent CLAUDE.md:

{{include:../../CLAUDE.md}}
