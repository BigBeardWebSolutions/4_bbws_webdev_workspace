# BBWS WordPress Platform - Runbooks

Standard Operating Procedures (SOPs) for the BBWS Multi-Tenant WordPress Platform.

## Quick Links

| Runbook | Purpose | Frequency | Duration |
|---------|---------|-----------|----------|
| [01-TENANT-DEPLOYMENT](./01-TENANT-DEPLOYMENT.md) | Deploy new WordPress tenant | Per tenant | 15-30 min |
| [02-CLOUDFRONT-BASIC-AUTH-UPDATE](./02-CLOUDFRONT-BASIC-AUTH-UPDATE.md) | Update CloudFront Basic Auth password | Quarterly | 5-10 min |

## When to Use Which Runbook

### 🆕 Deploying a New Tenant
→ Use **01-TENANT-DEPLOYMENT.md**

This is the main runbook for deploying a new WordPress tenant to DEV, SIT, or PROD environments.

**Prerequisites:**
- Tenant name decided
- ALB priority allocated
- AWS access configured

**Estimated Time:** 15-30 minutes (first time: 30-60 minutes)

### 🔐 Updating CloudFront Password
→ Use **02-CLOUDFRONT-BASIC-AUTH-UPDATE.md**

Use this when:
- Initial deployment shows placeholder password
- Quarterly password rotation
- Password compromise suspected
- HTTP 401 errors after correct credentials

**Estimated Time:** 5-10 minutes

### 🐛 Troubleshooting Deployment Issues
→ See **01-TENANT-DEPLOYMENT.md** Section: "Troubleshooting"

Common issues covered:
- Database connection errors
- HTTP 500 errors
- HTTPS timeouts
- ALB listener rule conflicts
- IAM permission issues

---

## Runbook Standards

All runbooks follow this structure:

1. **Overview** - What this runbook does
2. **Prerequisites** - Required access, tools, knowledge
3. **Procedure** - Step-by-step instructions with commands
4. **Validation** - How to verify success
5. **Troubleshooting** - Common issues and fixes
6. **Rollback** - How to undo changes if needed
7. **Reference** - Supporting information

### Command Format

All commands are provided in copy-paste ready format:

```bash
# Comments explain what each command does
export VARIABLE=value
command --flag value
```

### Placeholders

Replace these placeholders with actual values:

- `${ENVIRONMENT}` - Environment name (dev, sit, prod)
- `${TENANT_NAME}` - Tenant identifier (lowercase, alphanumeric)
- `${AWS_REGION}` - AWS region (eu-west-1 or af-south-1)
- `${AWS_PROFILE}` - AWS CLI profile (Tebogo-dev, Tebogo-sit, Tebogo-prod)
- `[PLACEHOLDER]` - Specific value needed (will be indicated in context)

---

## Emergency Contacts

| Role | Contact | Availability |
|------|---------|--------------|
| DevOps Lead | [Name/Email] | Business hours |
| Platform Team | [Slack: #bbws-platform] | 24/7 |
| On-Call Engineer | [PagerDuty] | 24/7 |
| AWS Support | [Support Portal] | 24/7 (Premium) |

---

## Related Documentation

### Architecture
- `/docs/architecture/` - System architecture diagrams
- `/docs/architecture/request-flow.md` - End-to-end request flow

### Infrastructure
- `2_bbws_ecs_terraform/` - Terraform infrastructure code
- `2_bbws_ecs_terraform/terraform/environments/` - Environment configurations

### Automation
- `2_bbws_agents/utils/` - Deployment automation scripts
- `2_bbws_agents/utils/validate_tenant_deployment.sh` - Automated validation

### Operations
- `2_bbws_ecs_operations/dashboards/` - CloudWatch dashboards
- `2_bbws_ecs_operations/alerts/` - CloudWatch alarms
- `2_bbws_ecs_operations/runbooks/` - Additional operational runbooks

---

## Runbook Changelog

| Date | Runbook | Version | Changes | Author |
|------|---------|---------|---------|--------|
| 2025-12-24 | 01-TENANT-DEPLOYMENT | 1.0 | Initial version based on bbwsmytestingdomain deployment | DevOps Team |
| 2025-12-24 | 02-CLOUDFRONT-BASIC-AUTH-UPDATE | 1.0 | Initial version | DevOps Team |

---

## Contributing

### Creating a New Runbook

1. Copy an existing runbook as template
2. Follow the standard structure (see above)
3. Include actual commands (not pseudocode)
4. Test all commands in a non-production environment
5. Have peer review before merging
6. Update this README with new runbook entry

### Updating Existing Runbooks

1. Increment version number
2. Add entry to Runbook Changelog
3. Update "Last Updated" date in runbook header
4. Document changes in runbook's Changelog section

### Naming Convention

Format: `##-DESCRIPTIVE-NAME.md`

- `##` - Two-digit sequential number
- `DESCRIPTIVE-NAME` - Uppercase with hyphens
- `.md` - Markdown format

Examples:
- `01-TENANT-DEPLOYMENT.md`
- `02-CLOUDFRONT-BASIC-AUTH-UPDATE.md`
- `03-DATABASE-MIGRATION.md`

---

## Feedback

Found an issue or have a suggestion?

1. Create an issue in GitHub repository
2. Tag with `runbook` label
3. Assign to DevOps team
4. Include:
   - Which runbook
   - What section
   - What's wrong/missing
   - Suggested fix

---

**Last Updated:** 2025-12-24
**Maintained By:** DevOps Team
