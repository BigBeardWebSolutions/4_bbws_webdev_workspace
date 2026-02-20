# GravitonWealth - WordPress Migration Project

## Project Purpose

Migration of GravitonWealth WordPress website from Xneelo hosting to the BBWS multi-tenant AWS hosting platform.

## Source Data

| Type | File/Folder | Size | Notes |
|------|-------------|------|-------|
| Database | database/gravitonp.sql | 121MB | Primary database |
| Database | database/gravitonwealthmanagement.sql | 24MB | Secondary database |
| Files | site/gravitonwm/ | 1.3GB | Full WordPress installation |

## Target Environment

| Setting | Value |
|---------|-------|
| Environment | DEV |
| Domain | gravitonwealth.wpdev.kimmyai.io |
| AWS Region | eu-west-1 |
| AWS Account | 536580886816 |
| Cluster | dev-cluster |

## Migration Checklist

### Pre-Flight
- [ ] AWS CLI access verified (default profile)
- [ ] S3 bucket accessible (wordpress-migration-temp-20250903)
- [ ] Session Manager plugin installed
- [ ] CloudFront basic auth exclusion added

### Infrastructure
- [ ] EFS access point created (/gravitonwealth/wp-content)
- [ ] IAM inline policy for EFS access
- [ ] Secrets Manager credentials configured
- [ ] Target group created with correct health checks

### Database
- [ ] Database created in RDS
- [ ] SQL imported successfully
- [ ] URL replacement completed
- [ ] Encoding fixes applied

### Files
- [ ] wp-content copied to EFS
- [ ] Permissions set (33:33)
- [ ] Problematic plugins identified/disabled

### Deployment
- [ ] ECS task definition registered
- [ ] Service created and running
- [ ] HTTPS redirect loop verified

### Validation
- [ ] HTTP 200 status check passed
- [ ] Mixed content detection (0 issues)
- [ ] Performance test passed (< 3s load)

## Test Email Redirect

All form submissions redirect to: `tebogo@bigbeard.co.za`

## Project-Specific Notes

- Has Wordfence WAF (wordfence-waf.php) - review for AWS compatibility
- Multiple database files present - determine primary database
- Google site verification file present (googleb6a1af5cd25df12e.html)

## Root Workflow Inheritance

This project inherits TBT mechanism and all workflow standards from the parent CLAUDE.md:

{{include:../CLAUDE.md}}
