# Manufacturing-Websites - Project Overview

## Project Purpose

WordPress migration project to move the Manufacturing-Websites site from Xneelo hosting to the BBWS multi-tenant AWS hosting platform.

## Source Data

| Item | Location | Size |
|------|----------|------|
| Database | s3://wordpress-migration-temp-20250903/manufacturing/wordpress-db-*.sql | ~51MB |
| Files | s3://wordpress-migration-temp-20250903/manufacturing/wordpress-files-*.tar.gz | ~92MB |
| Export Notes | s3://wordpress-migration-temp-20250903/manufacturing/EXPORT-NOTES-*.txt | ~3.7KB |

## Target Environments

| Environment | Domain | Status |
|-------------|--------|--------|
| DEV | manufacturing.wpdev.kimmyai.io | Pending |
| SIT | manufacturing.wpsit.kimmyai.io | Pending |
| PROD | TBD (custom domain) | Future |

## Project-Specific Instructions

- Use **default AWS CLI profile** for all operations
- Follow the migration runbook: `runbooks/wordpress_migration_playbook_automated.md`
- Test emails redirect to: `tebogo@bigbeard.co.za`
- Use bastion host for all long-running operations (not ECS exec)

## Current Project Plan

Location: `.claude/plans/project-plan-1/project_plan.md`

## Root Workflow Inheritance

This project inherits TBT mechanism and all workflow standards from the parent CLAUDE.md:

{{include:../../CLAUDE.md}}
