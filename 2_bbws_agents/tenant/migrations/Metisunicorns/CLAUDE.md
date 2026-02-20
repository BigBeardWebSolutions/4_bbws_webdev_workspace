# Metisunicorns - WordPress Migration

## Project Overview

WordPress migration for docx.metisunicorns.co.za to BBWS multi-tenant AWS hosting platform.

## Site Profile

| Property | Value |
|----------|-------|
| **Tenant Name** | metisunicorns |
| **Production Domain** | `https://docx.metisunicorns.co.za` |
| **Table Prefix** | `wp_` |
| **Database Charset** | utf8mb4 |
| **Total Size** | 1.2GB |
| **wp-content Size** | 742MB |
| **Database Size** | ~40MB |
| **Transfer Method** | S3 staging (>500MB) |

## Source Files

| Type | Location |
|------|----------|
| Original Files | `/Users/sithembisomjoko/Documents/Friday-Migration-30012026/metisunicorns/` |
| Database Backup | `database/metisunicorns-fixed.sql` |
| Site Files | `site/wp-content/` |

## Target Environment

| Environment | Domain |
|-------------|--------|
| DEV | `metisunicorns.wpdev.kimmyai.io` |
| SIT | `metisunicorns.wpsit.kimmyai.io` |

## Special Considerations

1. **Wordfence WAF Present** - Database prepared with `prepare-wordpress-for-migration.sh`
2. **Elementor Site** - Verify template status after migration
3. **S3 Staging Required** - Site exceeds 500MB threshold
4. **Excluded Folders** - `ai1wm-backups/`, `wflogs/`

## Migration Status

- [ ] Phase 1: Pre-Migration Analysis
- [ ] Phase 2: Database Preparation
- [ ] Phase 3: S3 Upload
- [ ] Phase 4: Tenant Provisioning
- [ ] Phase 5: Database Import
- [ ] Phase 6: File Import
- [ ] Phase 7: URL Replacement
- [ ] Phase 8: Validation

## AWS Resources

| Resource | Value |
|----------|-------|
| S3 Bucket | `s3://wordpress-migration-temp-20250903/metisunicorns/` |
| AWS Profile | `dev` (for DEV), `sit` (for SIT) |
| Region | eu-west-1 |

---

## Root Workflow Inheritance

This project inherits TBT mechanism from parent:

{{include:../CLAUDE.md}}
