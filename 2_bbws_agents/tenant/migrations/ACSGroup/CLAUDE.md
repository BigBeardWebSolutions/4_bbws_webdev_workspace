# ACSGroup WordPress Migration - Project Overview

## Project Purpose

Migrate the ACSGroup WordPress website from Xneelo hosting to the BBWS multi-tenant AWS hosting platform (DEV environment).

## Tenant Details

| Field | Value |
|-------|-------|
| Tenant Name | ACSGroup |
| Source Platform | Xneelo |
| Target Environment | DEV |
| Target Domain | acsgroup.wpdev.kimmyai.io |
| AWS Account | 536580886816 |
| AWS Region | eu-west-1 |
| Test Email | tebogo@bigbeard.co.za |

## Source Data Location

| Data Type | Location |
|-----------|----------|
| WordPress Files | `./site/acs/` |
| Database Dump | `./database/acs.sql` |
| S3 Staging | s3://wordpress-migration-temp-20250903/ACSGroup |

## Project-Specific Instructions

- Use bastion host for migration operations (not ECS exec)
- Apply S3-staged execution approach for reliability
- All emails must redirect to `tebogo@bigbeard.co.za` in DEV
- Deploy environment indicator MU-plugin
- Follow Pre-Flight Checklist before migration execution

## Key Contacts

- Migration Lead: DevOps Team
- Test Email Redirect: tebogo@bigbeard.co.za

## Root Workflow Inheritance

This project inherits TBT mechanism and all workflow standards from the parent CLAUDE.md:

{{include:../CLAUDE.md}}
