# Worker 3-3: Terraform S3 Module

**Worker ID**: worker-3-3-terraform-s3-module
**Stage**: Stage 3 - Infrastructure Code Development
**Status**: PENDING
**Estimated Effort**: High
**Dependencies**: Stage 2 Worker 2-5

---

## Objective

Create complete Terraform module for S3 bucket creation based on the LLD Terraform design from Stage 2.

---

## Input Documents

1. **Stage 2 Outputs**:
   - `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/project-plan-1/stage-2-lld-document-creation/worker-5-terraform-design-section/output.md` (Section 6.3 - s3_bucket module)

---

## Deliverables

Create `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/project-plan-1/stage-3-infrastructure-code/worker-3-terraform-s3-module/output.md` containing:

### Terraform Module Files

**1. modules/s3_bucket/main.tf** - Main resource definitions
**2. modules/s3_bucket/variables.tf** - Input variables
**3. modules/s3_bucket/outputs.tf** - Output values
**4. modules/s3_bucket/README.md** - Module documentation

Include complete, runnable Terraform code for:
- S3 bucket resource
- Versioning configuration
- Server-side encryption (SSE-S3)
- Public access block (block all)
- Access logging configuration
- Lifecycle policies
- Cross-region replication (conditional)
- Bucket policy (Lambda access)
- CloudWatch alarms (replication latency)

---

## Quality Criteria

- [ ] Terraform code is syntactically valid
- [ ] All variables from LLD Section 6.3.3 included
- [ ] All outputs from LLD Section 6.3.4 included
- [ ] Public access blocked
- [ ] Encryption enabled
- [ ] Conditional replication logic
- [ ] Module README complete

---

## Output Format

Write output to `output.md` containing all 4 files in code blocks.

**Target Length**: 500-700 lines

---

## Special Instructions

1. **Use LLD Design**: Extract from Stage 2 Worker 2-5 Section 6.3
2. **Security First**: Ensure public access is blocked, encryption enabled
3. **Replication**: Use conditional logic for cross-region replication

---

**Worker Created**: 2025-12-25
**Execution Mode**: Parallel (with 5 other Stage 3 workers)
