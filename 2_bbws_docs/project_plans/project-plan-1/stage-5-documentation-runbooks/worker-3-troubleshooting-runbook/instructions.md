# Worker 5-3: Troubleshooting Runbook

**Worker ID**: worker-5-3-troubleshooting-runbook
**Stage**: Stage 5 - Documentation & Runbooks
**Status**: PENDING
**Estimated Effort**: Medium
**Dependencies**: All previous stages

---

## Objective

Create comprehensive troubleshooting runbook covering common issues, diagnostics, and resolutions.

---

## Deliverables

Create: `2.1.8_Troubleshooting_Runbook_S3_DynamoDB.md`

### Required Sections:

1. **Overview** - How to use this runbook
2. **Diagnostic Tools** - AWS CLI commands, console links, CloudWatch queries
3. **Common Issues** - At least 15 common problems with solutions:

**DynamoDB Issues**:
   - Table not found
   - GSI creation failed
   - PITR not enabled
   - Backup plan missing
   - Tags incorrect
   - Permission denied errors

**S3 Issues**:
   - Bucket not created
   - Public access not blocked
   - Versioning not enabled
   - Templates not uploaded
   - Replication failed (PROD)
   - Encryption not configured

**CI/CD Issues**:
   - Workflow validation failures
   - Terraform plan failures
   - Terraform apply failures
   - Approval timeout
   - State lock conflicts

4. **Log Analysis** - How to read GitHub Actions logs, CloudWatch logs
5. **Health Checks** - Commands to verify system health
6. **Escalation Procedures** - When to escalate, who to contact

For each issue include:
- Symptom/Error message
- Root cause
- Step-by-step resolution
- Prevention measures

---

## Quality Criteria

- [ ] At least 15 common issues documented
- [ ] Each issue has clear resolution steps
- [ ] Diagnostic commands provided
- [ ] Real error messages/logs included
- [ ] Escalation criteria clear

---

**Target Length**: 600-700 lines

---

**Worker Created**: 2025-12-25
**Execution Mode**: Parallel
