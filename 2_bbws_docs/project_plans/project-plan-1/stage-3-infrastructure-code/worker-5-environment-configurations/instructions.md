# Worker 3-5: Environment Configurations

**Worker ID**: worker-3-5-environment-configurations
**Stage**: Stage 3 - Infrastructure Code Development
**Status**: PENDING
**Estimated Effort**: Medium
**Dependencies**: Stage 2 Worker 2-5

---

## Objective

Create complete .tfvars files for all 3 environments (DEV, SIT, PROD) for both repositories based on LLD specifications.

---

## Input Documents

1. **Stage 2 Outputs**:
   - `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/project-plan-1/stage-2-lld-document-creation/worker-5-terraform-design-section/output.md` (Section 6.5 - Environment Configuration Files)

---

## Deliverables

Create `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/project-plan-1/stage-3-infrastructure-code/worker-5-environment-configurations/output.md` containing:

### 6 .tfvars Files (3 per repository)

**DynamoDB Repository**:
1. environments/dev.tfvars
2. environments/sit.tfvars
3. environments/prod.tfvars

**S3 Repository**:
1. environments/dev.tfvars
2. environments/sit.tfvars
3. environments/prod.tfvars

Each .tfvars file should include:
- AWS account ID and region
- Environment name
- Backup configuration (enable_backup, backup_retention_days)
- Replication configuration (enable_replication, replica_region)
- Cost budget allocation
- All 7 mandatory tags
- Environment-specific settings

Use the exact values from Stage 2 Worker 2-5 Section 6.5.

---

## Quality Criteria

- [ ] All 6 .tfvars files created
- [ ] Valid HCL syntax
- [ ] All environment-specific values correct
- [ ] DEV: Daily backups, no replication
- [ ] SIT: Daily backups, no replication
- [ ] PROD: Hourly backups, cross-region replication enabled
- [ ] All 7 mandatory tags in each file
- [ ] Account IDs match LLD specifications

---

## Output Format

Write output to `output.md` containing all 6 .tfvars files in code blocks with repository and file path headers.

**Target Length**: 400-500 lines

---

## Special Instructions

1. **Use Exact Values**: Extract from Stage 2 Worker 2-5 Section 6.5.1, 6.5.2, 6.5.3
2. **Account IDs**: DEV=536580886816, SIT=815856636111, PROD=093646564004
3. **Tags**: Include all 7 mandatory tags with correct values per environment
4. **Replication**: Only PROD should have enable_replication=true, replica_region="eu-west-1"

---

**Worker Created**: 2025-12-25
**Execution Mode**: Parallel (with 5 other Stage 3 workers)
